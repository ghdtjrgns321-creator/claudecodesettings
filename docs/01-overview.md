# 01. Overview

## 전체 구조

```
~/.claude/   ← 전역
│
├─ ◆ 핵심 규칙
│   ├─ CLAUDE.md          … 판단 규칙만 (43줄)
│   ├─ rules/             … plan 모드 규칙
│   └─ output-styles/     …
│
├─ ◆ 고유 스킬 (3)         ripple-search · work-prompt-authoring
│                          diagram-driven-docs
│
├─ ◆ 자체생성 스킬 (3)     readme-maker · final-report · census
│
├─ ◆ 설계·디버깅 스킬 (3)  brainstorming · systematic-debugging · writing-skills
│
├─ ◆ 범용 도구 스킬 (5)    find-skills · pdf · mermaid
│                          frontend-design · web-design-guidelines
│
├─ ◆ 에이전트 (2)          code-reviewer · documentation-architect
│
├─ ◆ 훅 (5)                guard_bash · post_write_check · md_table_format
│                          session_start_context · completion_gate(VERIFY 실행)
│
├─ ◆ 인프라                settings.json · scripts/statusline.py · commands/(3) · docs/
│
└─ ↩ skills/*@ (5)         grill×3 · playwright×2 → ~/.agents/skills/  [외부, repo 제외]

  ◆ 플러그인 (5 설치)
     superpowers                … 비활성 (재활성은 settings.json 한 줄)
     harness                    … 에이전트 팀 스캐폴딩
     humanize-korean@im-not-ai  … 한글 윤문 (settings.local.json에서 활성)
     pyright-lsp / rust-analyzer-lsp   LSP   Python·Rust 코드 인텔리전스

  ▼ 도메인·스택 스킬 (8) → 각 프로젝트 .claude/skills/ (독립 git 저장소)
     회계·감사    accounting · pandera · imbalanced-ml
     백엔드       fastapi · pytest        인프라   docker-compose
     대시보드     streamlit               AI·RAG   langgraph-rag
     (배치: fs-multi · k-ifrs · local-ai)
```

## 역할 분담

| 층            | 담당                     | 예                                       |
| ------------- | ------------------------ | ---------------------------------------- |
| **CLAUDE.md** | 판단 규칙(무엇을·왜)     | 소통·착수·Git 원칙                       |
| **훅**        | 강제(실체 검사)          | completion_gate가 VERIFY 명령 직접 실행  |
| **스킬**      | 방법(상세 절차)          | census가 전수 작업 차집합 증명 절차 제공 |
| **에이전트**  | 위임(격리 실행)          | code-reviewer가 한국어 코드리뷰          |
| **플러그인**  | 외부 배포(스킬·LSP 묶음) | harness · humanize-korean · LSP 2        |
| **커맨드**    | 수동 호출(`/이름`)       | `/code-review`                           |

설계 원칙: **훅의 검사 대상은 산출물·명령의 실체다. 에이전트가 쓴 문장을 심사하지 않는다.**

## 관련 문서

- CLAUDE.md 구성 → [02](02-claude-md.md)
- 스킬 → [03](03-skills.md) / 에이전트 → [04](04-agents.md) / 훅 → [05](05-hooks.md) / 커맨드 → [06](06-commands.md)
- 트리거·목차·git → [07](07-triggers-and-index.md)
- 하네스 → [08](08-harness.md)
- 플러그인 → [09](09-plugins.md)
- 재설계 근거 → [2026-07-16-redesign](2026-07-16-redesign.md)
