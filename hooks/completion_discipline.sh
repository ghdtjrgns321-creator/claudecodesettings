#!/bin/bash
# UserPromptSubmit hook — 산출물 작업 시 contract.md 작성 규율을 컨텍스트에 주입(짧게).
# stdout이 Claude 컨텍스트에 자동 포함된다. 항상 fail-open(exit 0).
# 설계: ~/.claude/docs/instruction-gate-design.md §4
INPUT=$(cat 2>/dev/null)

CWD=""
if [[ "$INPUT" =~ \"cwd\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]]; then
  CWD="${BASH_REMATCH[1]}"
  CWD="${CWD//\\\\/\\}"   # JSON \\ -> \
  CWD="${CWD//\\//}"      # \ -> /
fi
SID=""
if [[ "$INPUT" =~ \"session_id\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]]; then
  SID="${BASH_REMATCH[1]}"
fi
if [[ -n "$CWD" && -d "$CWD" && -w "$CWD" && "$CWD" != "$HOME" ]]; then
  STATE_DIR="$CWD/.claude/state"
else
  STATE_DIR="$HOME/.claude/state"
fi
# 세션별 contract 격리(게이트와 동일 규칙): 이 세션 전용 파일을 안내한다.
if [[ -n "$SID" ]]; then
  CONTRACT="${STATE_DIR}/contracts/${SID}.md"
else
  CONTRACT="${STATE_DIR}/contract.md"
fi

cat <<TXT

[완료 규율 — 산출물 작업에만. 잡담·자명한 단일수정은 무시.]
산출물 작업이면 착수 전 ${CONTRACT} 에 done을 "- [ ] 셀 수 있는 항목"으로 선언.
각 항목 = 대상 + 수치 + 비교/임계 + 실패조건. "통독·대조·검토·확인" 같은 동사형 도달 항목 금지
(예: ✗"갭 표 대조 작성" → ✓"DART 합계와 material 합계 차액 ≤ 0원, 불일치 시 FAIL").
측정 불가 형식([x]인데 수치·실패조건 없음)은 Stop 게이트가 차단한다.
착수 전 자문: "이 항목이 전부 [x]가 돼도 산출물이 틀릴 수 있나?" YES면 그 항목은 너무 느슨하다 — 다시 써라.
코딩작업이면 "- [ ] 2+ 케이스로 검증(ripple-search)" 항목을 반드시 포함.
집합/표/다건 주장("모두·전부·전수·매핑 일치·각 룰")은 항목에 "M/N 확인(분모 명시) + N행 대조표 산출물 경로"를 박는다. 표본 몇 개로 전체 "일치"라 쓰면 hollow-PASS(존재≠사용: yaml에 키 있음 ≠ 그 룰이 그 키를 읽음). 산출물 경로 없는 집합 커버리지 [x]는 게이트가 차단한다.
비동기 작업(테스트·빌드 등) 대기 중이라 이번 턴에 못 끝내는 항목은 [>]로 표시(차단 안 됨, 완료 시 [x]). 거짓 [x] 금지.
종료는 모든 항목이 [x](완료) 또는 [~]사유(의도적 축소)일 때만 통과(강경 Stop 게이트).
전체 중단은 contract에 "OVERRIDE: 사유" 한 줄. 미완을 조용히 넘기지 말 것.
TXT
exit 0
