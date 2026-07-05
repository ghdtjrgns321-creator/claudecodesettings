# 01. Overview — 전체 생태계

Claude Code 설정은 **세 저장소 + 플러그인 + 프로젝트**로 나뉜다. 각자 역할이 다르다.

## 생태계 구조

```
~/.claude/   ← 전역 = 작업 규율 하네스 (모든 프로젝트 공통)
│
├─ ◆ 핵심 규칙
│   ├─ CLAUDE.md          … §0~§10, 카파티 4원칙 (84줄 슬림)
│   ├─ rules/             … plan-mode-brainstorming.md
│   └─ output-styles/     … teacher.md
│
├─ ◆ 고유 하네스 스킬 (2)   ripple-search · work-prompt-authoring
│                          (핵심 하네스는 superpowers 플러그인이 제공 ↓)
│
├─ ◆ 범용 도구 스킬 (6)     find-skills · docx · pdf · mermaid
│                          frontend-design · web-design-guidelines
│
├─ ◆ 에이전트 (2)          code-reviewer · documentation-architect
│                          (plan·explore·debug·security = 빌트인·superpowers)
│
├─ ◆ 훅 + 완료 게이트 (10)  guard_bash · post_write_check · literal_lint · md_table_format
│                          session_start_context · work-summary-{start,end}
│                          completion_{discipline,gate} · contract_lint
│
├─ ◆ 인프라              settings.json · scripts/statusline.py · commands/(3) · docs/(7)
│
└─ ↩ skills/*@ (5)        grill×3 · playwright×2 → ~/.agents/skills/  [외부, repo 제외]

  ◆ superpowers 플러그인 (14, Jesse Vincent) — 핵심 하네스 유지보수판
     brainstorming · TDD · debugging · verification · subagent · writing-skills · git-worktrees …

  ▼ 도메인·스택 스킬 (8) → 각 프로젝트 .claude/skills/ (독립 git 저장소)
     회계·감사    accounting · pandera · imbalanced-ml
     백엔드       fastapi · pytest        인프라   docker-compose
     대시보드     streamlit               AI·RAG   langgraph-rag
     (배치: fs-multi · k-ifrs · local-ai)
```

## 로딩 순서 (스킬이 뜨는 범위)

Claude Code는 작업 위치 기준으로 **현재 프로젝트 루트 → 유저(~/.claude) + 플러그인**의 스킬을 모두 본다.
- 각 프로젝트가 자기 `.git`을 가진 독립 저장소라, **부모(workspace)의 스킬은 안 읽힌다** → 도메인 스킬은 각 프로젝트에 복사해 둔다.

## 세 층의 역할 분담 (SSOT)

| 층            | 담당                      | 예                                         |
| ------------- | ------------------------- | ------------------------------------------ |
| **CLAUDE.md** | 원칙(무엇을·왜)           | "완료는 증거로"                            |
| **훅**        | 강제(어떻게, 100% 결정적) | completion_gate가 미검증 완료 차단         |
| **스킬**      | 방법론(상세 절차)         | superpowers:verification-before-completion |

같은 내용을 두 곳에 두지 않는다 — 이것이 이 저장소 정리의 핵심 원칙.

## 관련 문서

- CLAUDE.md 구성 → [02](02-claude-md.md)
- 스킬 전수 → [03](03-skills.md) / 에이전트 → [04](04-agents.md) / 훅 → [05](05-hooks.md) / 커맨드 → [06](06-commands.md)
- 트리거·목차·git → [07](07-triggers-and-index.md)
