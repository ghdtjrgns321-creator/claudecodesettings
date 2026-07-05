#!/bin/bash
# Stop hook — contract.md 기반 강경 게이트 (산출물 누락 방지).
#   통과: contract 없음 / 미체크 [ ] 없음 / OVERRIDE / 백스톱(무진행 N회) / 음소거(같은 상태 재차단 방지).
#   차단: 미체크 - [ ] 존재, 또는 측정불가 [x] 항목(① contract_lint).
#   대기: - [>] 항목은 차단 안 함(진행중), 같은 상태당 1회만 상기(B).
#   fail-open: 오류·python부재 시 통과.
# 설계: ~/.claude/docs/instruction-gate-design.md §3
set -uo pipefail
N=3
INPUT=$(cat 2>/dev/null)

# --- cwd 추출 (Windows 경로 → /c/... 슬래시) ---
CWD=""
if [[ "$INPUT" =~ \"cwd\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]]; then
  CWD="${BASH_REMATCH[1]}"
  CWD="${CWD//\\\\/\\}"   # JSON \\ -> \
  CWD="${CWD//\\//}"      # \ -> /
fi

# --- session_id 추출 (세션별 contract 격리용) ---
SID=""
if [[ "$INPUT" =~ \"session_id\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]]; then
  SID="${BASH_REMATCH[1]}"
fi

# --- state_dir 결정 (프로젝트별, 홈/비쓰기 시 폴백) ---
if [[ -n "$CWD" && -d "$CWD" && -w "$CWD" && "$CWD" != "$HOME" ]]; then
  STATE_DIR="$CWD/.claude/state"
else
  STATE_DIR="$HOME/.claude/state"
fi
OVLOG="$STATE_DIR/.gate_override.log"
# 세션별 contract 격리: session_id 있으면 contracts/<sid>.md, 없으면 레거시 공유 파일.
if [[ -n "$SID" ]]; then
  CONTRACT="$STATE_DIR/contracts/$SID.md"
  COUNTER="$STATE_DIR/contracts/.gate_count.$SID"
  MUTED="$STATE_DIR/contracts/.gate_muted.$SID"
else
  CONTRACT="$STATE_DIR/contract.md"
  COUNTER="$STATE_DIR/.gate_count"
  MUTED="$STATE_DIR/.gate_muted"
fi

# 활성 계약 없음 → 통과 (미작성=미강제, 설계 §0 한계)
[[ -f "$CONTRACT" ]] || exit 0

# --- contract 서명 (음소거·백스톱 키) ---
if command -v sha1sum >/dev/null 2>&1; then
  SIG=$(sha1sum "$CONTRACT" | cut -d' ' -f1)
elif command -v md5sum >/dev/null 2>&1; then
  SIG=$(md5sum "$CONTRACT" | cut -d' ' -f1)
else
  SIG=$(wc -c < "$CONTRACT" | tr -d ' ')
fi
# 진행(내용변경) 있으면 stale 음소거 제거 → 게이트 재무장
MSIG=""
if [[ -f "$MUTED" ]]; then
  read -r MSIG < "$MUTED" 2>/dev/null || MSIG=""
  if [[ "$MSIG" != "$SIG" ]]; then rm -f "$MUTED" 2>/dev/null; MSIG=""; fi
fi

# --- 출력 헬퍼 (decision:block / additionalContext) ---
emit_block(){
  python - "$1" <<'PY' 2>/dev/null || exit 0
import json,sys
print(json.dumps({"decision":"block","reason":sys.argv[1]}))
PY
}
emit_ctx(){
  python - "$1" <<'PY' 2>/dev/null || exit 0
import json,sys
print(json.dumps({"hookSpecificOutput":{"hookEventName":"Stop","additionalContext":sys.argv[1]}}))
PY
}

# 미체크 항목 수 ([ ]만 — [>]대기·[x]완료·[~]축소는 제외)
UNCHECKED=$(grep -cE '^[[:space:]]*- \[ \]' "$CONTRACT" 2>/dev/null); UNCHECKED=${UNCHECKED:-0}
WAITING=$(grep -cE '^[[:space:]]*- \[>\]' "$CONTRACT" 2>/dev/null); WAITING=${WAITING:-0}

if [[ "$UNCHECKED" -eq 0 ]]; then
  rm -f "$COUNTER" 2>/dev/null
  # OVERRIDE → 전체 강제 통과
  if grep -qE '^[[:space:]]*OVERRIDE:' "$CONTRACT" 2>/dev/null; then
    rm -f "$MUTED" 2>/dev/null; exit 0
  fi
  # ① 측정불가 [x] 항목 차단 (자기참조 self-pass 방지)
  LINT_OUT=$(python "$HOME/.claude/hooks/contract_lint.py" "$CONTRACT" 2>/dev/null)
  if [[ $? -eq 1 && -n "$LINT_OUT" ]]; then
    emit_block "종료 차단(항목 형식 ①). 완료[x]지만 측정 근거 없음:
${LINT_OUT}
→ 수치·실패조건을 문구에 박고 재검증 후 [x]. 수치무관이면 [~]사유."
    exit 0
  fi
  # (B) 대기 [>] 항목은 통과시키되 같은 상태당 1회만 상기
  if [[ "$WAITING" -gt 0 ]]; then
    if [[ "$MSIG" == "$SIG" ]]; then exit 0; fi   # 이미 상기함 → 조용히 통과
    printf '%s\n' "$SIG" > "$MUTED" 2>/dev/null
    emit_ctx "대기 항목 ${WAITING}개([>]) 진행 중 — 차단 안 함. 완료되면 [x]로 바꿀 것. (이 알림은 같은 상태당 1회)"
    exit 0
  fi
  rm -f "$MUTED" 2>/dev/null; exit 0
fi

# --- 미체크 [ ] 존재 ---
# (A) 음소거: 백스톱 이미 발동한 동일 contract면 조용히 통과 (반복 차단=컨텍스트 오염 방지)
if [[ "$MSIG" == "$SIG" ]]; then exit 0; fi

# OVERRIDE 전체 통과
if grep -qE '^[[:space:]]*OVERRIDE:' "$CONTRACT" 2>/dev/null; then
  printf '[gate-override] %s\n' "$(grep -E '^[[:space:]]*OVERRIDE:' "$CONTRACT" | head -1)" >> "$OVLOG" 2>/dev/null
  rm -f "$COUNTER" 2>/dev/null; exit 0
fi

# 백스톱 카운터 (무진행 N회 → 자동통과 + 음소거)
PREV_SIG=""; PREV_CNT=0
if [[ -f "$COUNTER" ]]; then read -r PREV_SIG PREV_CNT < "$COUNTER" 2>/dev/null || true; fi
[[ "$PREV_CNT" =~ ^[0-9]+$ ]] || PREV_CNT=0
if [[ "$SIG" == "$PREV_SIG" ]]; then CNT=$((PREV_CNT + 1)); else CNT=1; fi
mkdir -p "$(dirname "$COUNTER")" 2>/dev/null
printf '%s %s\n' "$SIG" "$CNT" > "$COUNTER" 2>/dev/null

UNCHECKED_LIST=$(grep -E '^[[:space:]]*- \[ \]' "$CONTRACT" 2>/dev/null)

if [[ "$CNT" -ge "$N" ]]; then
  { printf '[gate-backstop] auto-pass, unchecked:\n'; printf '%s\n' "$UNCHECKED_LIST"; } >> "$OVLOG" 2>/dev/null
  rm -f "$COUNTER" 2>/dev/null
  printf '%s\n' "$SIG" > "$MUTED" 2>/dev/null     # 이후 동일 상태는 조용히 통과
  emit_ctx "게이트 백스톱: 미체크 남았지만 ${N}회 무진행으로 자동통과. 같은 상태는 이후 조용히 통과한다. 미완 항목을 사용자에게 명시 보고할 것."
  exit 0
fi

# 차단 (강경, 짧게)
emit_block "종료 차단(강경 게이트). 미체크 항목:
${UNCHECKED_LIST}
완료→[x] / 대기중→[>] / 축소→[~]사유 / 포기→OVERRIDE:사유. (무진행 ${CNT}/${N}, 도달 시 자동통과)"
exit 0
