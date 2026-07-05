# 05. Hooks — 훅

## 훅 10개

| 훅                       | 이벤트                 | 기능                                                                          | 차단? |
| ------------------------ | ---------------------- | ----------------------------------------------------------------------------- | ----- |
| guard_bash.sh            | PreToolUse:Bash        | 위험 명령 차단(rm -rf /·chmod777·curl\|sh·force push·시크릿 읽기·글로벌 설치) | 하드  |
| post_write_check.py      | PostToolUse:Write/Edit | 한글 깨짐(mojibake) 하드 차단 + .py ruff 자동정리                             | 하드  |
| literal_lint.py          | PostToolUse:Write/Edit | 소스에 박힌 연도·긴숫자·거대상수 경고                                         | 경고  |
| md_table_format.py       | PostToolUse:Write/Edit | 마크다운 표 자동 정렬                                                         | 자동  |
| session_start_context.sh | SessionStart           | 세션 시작 시 컨텍스트 주입                                                    | —     |
| work-summary-start.sh    | UserPromptSubmit       | 이전 작업요약 읽어 주입(세션 연속성)                                          | —     |
| work-summary-end.sh      | Stop                   | 작업요약 파일 작성 요청                                                       | —     |
| completion_discipline.sh | UserPromptSubmit       | "완료 계약 규율" 주입(측정가능 항목·분모·존재≠사용)                           | —     |
| completion_gate.sh       | Stop                   | 계약 미완료·측정불가 [x] 시 종료 차단                                         | 하드  |
| contract_lint.py         | (completion_gate 호출) | 계약 항목의 측정가능성 검사 헬퍼                                              | —     |

## 이벤트 커버리지

사용 중: PreToolUse · PostToolUse · SessionStart · UserPromptSubmit · Stop (5종).
미사용(선택 여지): Notification(유휴·권한 알림) · SubagentStop · PreCompact.

## 설계 문서

완료 게이트 상세: [`instruction-gate-design.md`](instruction-gate-design.md).

## 배선

모든 훅은 `settings.json`의 `hooks`에 이벤트별로 등록. 훅 추가 시 스크립트(`hooks/`) + settings 배선을 함께.
