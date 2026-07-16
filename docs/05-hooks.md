# 05. Hooks — 훅

> 2026-07-16 재설계: 훅 10 → 5. 매 턴 주입(completion_discipline·work-summary-start)과
> 문장 심사(contract_lint)·저빈도 경고(literal_lint)·요약 기록(work-summary-end)을 퇴역.
> 원칙: **훅은 실체(파일·명령·exit 코드)만 검사한다. 에이전트의 서술은 검사하지 않는다.**

## 훅 (5)

| 훅                       | 이벤트                 | 기능                                                                          | 차단? |
| ------------------------ | ---------------------- | ----------------------------------------------------------------------------- | ----- |
| guard_bash.sh            | PreToolUse:Bash        | 위험 명령 차단(rm -rf /·chmod777·curl\|sh·force push·시크릿 읽기·글로벌 설치) | 하드  |
| post_write_check.py      | PostToolUse:Write/Edit | 한글 깨짐(mojibake) 하드 차단 + .py ruff 자동정리                             | 하드  |
| md_table_format.py       | PostToolUse:Write/Edit | 마크다운 표 자동 정렬                                                         | 자동  |
| session_start_context.sh | SessionStart           | 세션 시작 시 git·디버깅·작업 상태 주입 (1회)                                  | —     |
| completion_gate.sh (v2)  | Stop                   | contract 미체크 [ ] 차단 + `VERIFY: <명령>` 직접 실행, exit≠0이면 차단        | 하드  |

## 이벤트 커버리지

사용 중: PreToolUse · PostToolUse · SessionStart · Stop (4종).
미사용(의도적): **UserPromptSubmit** — 매 턴 주입은 컨텍스트 세금 + 교정 나선 가속으로 확인되어 재설계에서 제거. Notification · SubagentStop · PreCompact도 미사용.

## 완료 계약 게이트

`completion_gate.sh` 단독. 검증 항목은 계약 파일의 `VERIFY:` 실행 명령으로 박고 게이트가 직접 돌린다. 상세 → [08a](08a-completion-contract.md). v1 설계 이력 → [instruction-gate-design.md](instruction-gate-design.md)(레거시).

## 배선

모든 훅은 `settings.json`의 `hooks`에 이벤트별로 등록. 훅 추가 시 스크립트(`hooks/`) + settings 배선을 함께.
추가 전 자문: **"이 훅은 실체를 검사하는가, 문장을 검사하는가?"** 후자면 만들지 않는다.
