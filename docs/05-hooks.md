# 05. Hooks — 훅

## 훅 (5)

| 훅                       | 이벤트                 | 기능                                                                          | 차단? |
| ------------------------ | ---------------------- | ----------------------------------------------------------------------------- | ----- |
| guard_bash.sh            | PreToolUse:Bash        | 위험 명령 차단(rm -rf /·chmod777·curl\|sh·force push·시크릿 읽기·글로벌 설치) | 하드  |
| post_write_check.py      | PostToolUse:Write/Edit | 한글 깨짐(mojibake) 하드 차단 + .py ruff 자동정리                             | 하드  |
| md_table_format.py       | PostToolUse:Write/Edit | 마크다운 표 자동 정렬                                                         | 자동  |
| session_start_context.sh | SessionStart           | 세션 시작 시 git·디버깅·작업 상태 주입 (1회)                                  | —     |
| completion_gate.sh       | Stop                   | contract 미체크 [ ] 차단 + `VERIFY: <명령>` 에이전트가 직접 실행, exit≠0이면 차단        | 하드  |

## 이벤트 커버리지

PreToolUse · PostToolUse · SessionStart · Stop (4종).

## 배선

- 모든 훅은 `settings.json`의 `hooks`에 이벤트별로 등록
- 훅 추가 시 스크립트(`hooks/`) + settings

