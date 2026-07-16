#!/bin/bash
# Stop hook — contract 게이트 v2 (2026-07-16 재설계)
# v1과의 차이:
#   - 검사 대상이 문장이 아니라 실체다. contract_lint(작문 심사) 폐기,
#     대신 contract의 "VERIFY: <명령>" 줄을 직접 실행해 exit 0을 요구한다.
#   - STATE_DIR을 HOME으로 고정. cwd 추종은 세션 중 cd 시 게이트가
#     다른 곳을 보고 조용히 열리는 버그였다(2026-07-16 실측).
#   통과: contract 없음 / 미체크 0 & VERIFY 전부 0 / OVERRIDE / 백스톱 / 음소거.
#   fail-open: 오류 시 통과.
set -uo pipefail
N=3
INPUT=$(cat 2>/dev/null)

SID=""
if [[ "$INPUT" =~ \"session_id\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]]; then
  SID="${BASH_REMATCH[1]}"
fi

STATE_DIR="$HOME/.claude/state"
if [[ -n "$SID" ]]; then
  CONTRACT="$STATE_DIR/contracts/$SID.md"
  COUNTER="$STATE_DIR/contracts/.gate_count.$SID"
  MUTED="$STATE_DIR/contracts/.gate_muted.$SID"
else
  CONTRACT="$STATE_DIR/contract.md"
  COUNTER="$STATE_DIR/.gate_count"
  MUTED="$STATE_DIR/.gate_muted"
fi
OVLOG="$STATE_DIR/.gate_override.log"

[[ -f "$CONTRACT" ]] || exit 0

# --- contract 서명 (음소거·백스톱 키) ---
if command -v sha1sum >/dev/null 2>&1; then
  SIG=$(sha1sum "$CONTRACT" | cut -d' ' -f1)
else
  SIG=$(wc -c < "$CONTRACT" | tr -d ' ')
fi
MSIG=""
if [[ -f "$MUTED" ]]; then
  read -r MSIG < "$MUTED" 2>/dev/null || MSIG=""
  if [[ "$MSIG" != "$SIG" ]]; then rm -f "$MUTED" 2>/dev/null; MSIG=""; fi
fi

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

# --- 백스톱: 같은 SIG로 N회 차단되면 자동통과 + 음소거 (컨텍스트 오염 방지) ---
backstop_or_block(){
  local reason="$1"
  [[ "$MSIG" == "$SIG" ]] && exit 0
  if grep -qE '^[[:space:]]*OVERRIDE:' "$CONTRACT" 2>/dev/null; then
    printf '[gate-override] %s\n' "$(grep -E '^[[:space:]]*OVERRIDE:' "$CONTRACT" | head -1)" >> "$OVLOG" 2>/dev/null
    rm -f "$COUNTER" 2>/dev/null; exit 0
  fi
  local PREV_SIG="" PREV_CNT=0 CNT
  if [[ -f "$COUNTER" ]]; then read -r PREV_SIG PREV_CNT < "$COUNTER" 2>/dev/null || true; fi
  [[ "$PREV_CNT" =~ ^[0-9]+$ ]] || PREV_CNT=0
  if [[ "$SIG" == "$PREV_SIG" ]]; then CNT=$((PREV_CNT + 1)); else CNT=1; fi
  mkdir -p "$(dirname "$COUNTER")" 2>/dev/null
  printf '%s %s\n' "$SIG" "$CNT" > "$COUNTER" 2>/dev/null
  if [[ "$CNT" -ge "$N" ]]; then
    { printf '[gate-backstop] auto-pass:\n%s\n' "$reason"; } >> "$OVLOG" 2>/dev/null
    rm -f "$COUNTER" 2>/dev/null
    printf '%s\n' "$SIG" > "$MUTED" 2>/dev/null
    emit_ctx "게이트 백스톱: ${N}회 무진행으로 자동통과. 미해결 항목을 사용자에게 명시 보고할 것."
    exit 0
  fi
  emit_block "$reason (무진행 ${CNT}/${N}, 도달 시 자동통과)"
  exit 0
}

UNCHECKED=$(grep -cE '^[[:space:]]*- \[ \]' "$CONTRACT" 2>/dev/null); UNCHECKED=${UNCHECKED:-0}
WAITING=$(grep -cE '^[[:space:]]*- \[>\]' "$CONTRACT" 2>/dev/null); WAITING=${WAITING:-0}

# --- 1) 미체크 [ ] 존재 → 차단 (백스톱 포함) ---
if [[ "$UNCHECKED" -gt 0 ]]; then
  UNCHECKED_LIST=$(grep -E '^[[:space:]]*- \[ \]' "$CONTRACT" 2>/dev/null)
  backstop_or_block "종료 차단. 미체크 항목:
${UNCHECKED_LIST}
완료→[x] / 대기중→[>] / 축소→[~]사유 / 포기→OVERRIDE:사유."
fi

rm -f "$COUNTER" 2>/dev/null
if grep -qE '^[[:space:]]*OVERRIDE:' "$CONTRACT" 2>/dev/null; then
  rm -f "$MUTED" 2>/dev/null; exit 0
fi

# --- 2) VERIFY 실행 — 문장 대신 실체를 검사한다 ---
#     contract에 "VERIFY: <명령>" 줄이 있으면 각각 실행, 전부 exit 0이어야 통과.
VFAILS=""
while IFS= read -r vline; do
  vcmd="${vline#*VERIFY:}"
  vcmd="${vcmd# }"
  [[ -z "$vcmd" ]] && continue
  if command -v timeout >/dev/null 2>&1; then
    vout=$(timeout 120 bash -c "$vcmd" 2>&1); vrc=$?
  else
    vout=$(bash -c "$vcmd" 2>&1); vrc=$?
  fi
  if [[ "$vrc" -ne 0 ]]; then
    vtail=$(printf '%s' "$vout" | tail -c 400)
    VFAILS+="✗ ${vcmd} (rc=${vrc})
${vtail}
"
  fi
done < <(grep -E '^[[:space:]]*VERIFY:' "$CONTRACT" 2>/dev/null)

if [[ -n "$VFAILS" ]]; then
  backstop_or_block "종료 차단(VERIFY 실패). 아래 명령이 exit 0이 아니다:
${VFAILS}실체를 고치고 다시 종료하라. 명령이 잘못됐으면 contract의 VERIFY 줄을 수정."
fi

# --- 3) 대기 [>] 상기 (같은 상태당 1회) ---
if [[ "$WAITING" -gt 0 ]]; then
  if [[ "$MSIG" == "$SIG" ]]; then exit 0; fi
  printf '%s\n' "$SIG" > "$MUTED" 2>/dev/null
  emit_ctx "대기 항목 ${WAITING}개([>]) 진행 중 — 차단 안 함. 완료되면 [x]로 바꿀 것."
  exit 0
fi

rm -f "$MUTED" 2>/dev/null
exit 0
