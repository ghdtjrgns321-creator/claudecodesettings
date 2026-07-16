# 08d. 연속성 하네스 (세션을 넘어 작업 이어주기)

> 세션이 끊겨도 다음 세션이 작업상황을 알게 한다.
> ← [08. 하네스 개요](08-harness.md)

## ① session_start_context.sh — 시작 시 프로젝트 상태 주입 (SessionStart, 1회)

세션이 시작되면 현재 프로젝트의 상태를 컨텍스트에 넣어준다:

- **Git**: 현재 브랜치 · 최근 5커밋 · working tree 변경 목록
- **최근 디버깅**: `docs/debugging.md` 마지막 30줄(있으면)
- **진행 중 작업**: `docs/TASKS.md` 등에서 "진행 중"·🔄·⏳ 마커 grep
- 4000자 캡(UTF-8 안전 컷)

→ 새 세션을 열자마자 프로젝트 상태를 자동으로 파악. **매 턴이 아니라 1회만** 주입한다.

## ② Claude Code 자동 메모리 (훅 아님)

`~/.claude/projects/<프로젝트>/memory/` — Claude가 세션을 넘어 유지하는 파일 기반 메모리. 프로젝트 결정·사용자 피드백을 Claude가 직접 기록하고 회수한다.

## 흐름

```
세션 시작 ─ session_start_context ─→ git·디버깅·작업 상태 주입 (1회)
세션 중   ─ (주입 없음)
세션 종료 ─ completion_gate ───────→ 계약 잔여·VERIFY 검사 (→ 08a)
```
