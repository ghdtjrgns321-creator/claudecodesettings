# 08. 하네스 (Harness)

## 하네스 구성

| 서브시스템                   | 이벤트                  | 훅                                 | 하는 일                                                   | 상세                              |
| ---------------------------- | ----------------------- | ---------------------------------- | --------------------------------------------------------- | --------------------------------- |
| **A. 완료 계약** (직접 제작) | Stop                    | completion_gate                    | 미체크 [ ] 차단 + VERIFY 명령 직접 실행으로 실체 검증     | [08a](08a-completion-contract.md) |
| **B. 안전 가드**             | PreToolUse:Bash         | guard_bash                         | 위험 명령(rm -rf·force push·시크릿 읽기·글로벌 설치) 차단 | [08b](08b-safety-guard.md)        |
| **C. 무결성**                | PostToolUse:Write\|Edit | post_write_check · md_table_format | 한글 인코딩 하드 차단 + ruff + 표 정렬                    | [08c](08c-integrity.md)           |
| **D. 연속성**                | SessionStart            | session_start_context              | 세션 시작 시 작업 맥락 주입 (1회)                         | [08d](08d-continuity.md)          |

## 이벤트별 배치

```
세션 시작 ── SessionStart ──────── session_start_context     (D: git·작업상태 주입, 1회)
             │
도구 실행 전 ─ PreToolUse:Bash ──── guard_bash                (B: 위험명령 차단)
             │
파일 저장 후 ─ PostToolUse ──────── post_write_check          (C: 인코딩 하드차단+ruff)
             │  (Write|Edit)       md_table_format            (C: 표 정렬)
             │
세션 종료 ── Stop ──────────────── completion_gate            (A: [ ] 차단 + VERIFY 실행)
```

매 프롬프트(UserPromptSubmit) 훅은 두지 않는다.

## 강도별 분류

| 강도          | 훅                                                      | 의미                                          |
| ------------- | ------------------------------------------------------- | --------------------------------------------- |
| **하드 차단** | guard_bash · post_write_check(인코딩) · completion_gate | 조건 위반 시 실행/종료를 막음(exit 2 / block) |
| **자동 처리** | md_table_format · post_write_check(ruff)                | 저장 시 자동 정리                             |
| **주입(1회)** | session_start_context                                   | 세션 시작에만 맥락 주입                       |

## 설계 방식

- **규칙 → 훅.** "매 턴 참이어야 하는 강제"는 CLAUDE.md가 아니라 훅. (매 턴 참 = CLAUDE.md / 가끔 절차 = 스킬 / 자동 스크립트 = 훅)
- **훅의 검사 대상은 실체다.** 파일 바이트(post_write_check), 명령 문자열(guard_bash), exit 코드(completion_gate의 VERIFY). 에이전트가 쓴 문장을 심사하는 훅은 만들지 않는다 — 일이 맞아도 문구가 규격에 안 맞으면 차단되는 왕복을 낳는다.
- 각 훅의 배선은 `settings.json`의 `hooks`에 이벤트별로 등록. 훅 목록 요약은 [05. hooks](05-hooks.md).
