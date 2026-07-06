# 08. 하네스 (Harness)

## 하네스 구성

| 서브시스템          | 이벤트                                 | 훅                                                            | 하는 일                                                   | 상세                              |
| ------------------- | -------------------------------------- | ------------------------------------------------------------- | --------------------------------------------------------- | --------------------------------- |
| **A. 완료 계약** (자체생성) | UserPromptSubmit · Stop                | completion_discipline · completion_gate · contract_lint       | 증거 없이 완료 못 하게 종료 차단                          | [08a](08a-completion-contract.md) |
| **B. 안전 가드**    | PreToolUse:Bash                        | guard_bash                                                    | 위험 명령(rm -rf·force push·시크릿 읽기·글로벌 설치) 차단 | [08b](08b-safety-guard.md)        |
| **C. 무결성**       | PostToolUse:Write\|Edit                | post_write_check · literal_lint · md_table_format             | 한글 인코딩 하드 차단 + 하드코딩 경고 + 표 정렬           | [08c](08c-integrity.md)           |
| **D. 연속성**       | SessionStart · UserPromptSubmit · Stop | session_start_context · work-summary-start · work-summary-end | 세션 넘어 작업 맥락 이어주기                              | [08d](08d-continuity.md)          |

## 이벤트별 배치 (전체 흐름)

```
세션 시작 ── SessionStart ──────── session_start_context     (D: git·작업상태 주입)
             │
매 프롬프트 ─ UserPromptSubmit ──── work-summary-start        (D: 이전 요약 주입)
             │                     completion_discipline      (A: 계약 규율 주입)
             │
도구 실행 전 ─ PreToolUse:Bash ──── guard_bash                (B: 위험명령 차단)
             │
파일 저장 후 ─ PostToolUse ──────── post_write_check          (C: 인코딩 하드차단+ruff)
             │  (Write|Edit)       literal_lint               (C: 하드코딩 경고)
             │                     md_table_format            (C: 표 정렬)
             │
세션 종료 ── Stop ──────────────── work-summary-end           (D: 요약 기록)
                                   completion_gate            (A: 미검증 완료 차단)
                                     └─ contract_lint         (A: 측정가능성 검사)
```

## 강도별 분류

| 강도           | 훅                                                             | 의미                                          |
| -------------- | -------------------------------------------------------------- | --------------------------------------------- |
| **하드 차단**  | guard_bash · post_write_check(인코딩) · completion_gate        | 조건 위반 시 실행/종료를 막음(exit 2 / block) |
| **경고**       | literal_lint                                                   | 주의만 주입, 막지 않음                        |
| **자동 처리**  | md_table_format · post_write_check(ruff)                       | 저장 시 자동 정리                             |
| **주입(soft)** | session_start_context · work-summary-* · completion_discipline | 컨텍스트에 맥락·규율을 넣어 압박·상기         |

## 설계 방식

- **규칙 → 훅.** "매 턴 참이어야 하는 강제"는 CLAUDE.md가 아니라 훅. (매 턴 참 = CLAUDE.md / 가끔 절차 = 스킬 / 자동 스크립트 = 훅)
- **A(완료 계약)은 직접 생성한 하네스임** — 증거 기반 완료 강제. 깊게 보려면 → [08a](08a-completion-contract.md).
- 각 훅의 배선은 `settings.json`의 `hooks`에 이벤트별로 등록. 훅 목록 요약은 [05. hooks](05-hooks.md).
