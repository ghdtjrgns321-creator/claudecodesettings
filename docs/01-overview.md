# 01. Overview — 전체 생태계

## 생태계 구조

```
~/.claude/   ← 전역
│
├─ ◆ 핵심 규칙
│   ├─ CLAUDE.md          … §0~§10, (84줄)
│   ├─ rules/             … 
│   └─ output-styles/     … 
│
├─ ◆ 고유 하네스 스킬 (2)   ripple-search · work-prompt-authoring
│                          (핵심 하네스는 superpowers 플러그인이 제공 ↓)
│
├─ ◆ 범용 도구 스킬 (5)     find-skills · pdf · mermaid
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

## 역할 분담

| 층            | 담당                    | 예                                         |
| ------------- | ----------------------- | ------------------------------------------ |
| **CLAUDE.md** | 원칙(무엇을·왜)         | "완료는 증거로"                            |
| **훅**        | 강제(어떻게, 100% 강제) | completion_gate가 미검증 완료 차단         |
| **스킬**      | 방법론(상세 절차)       | superpowers:verification-before-completion |


## 관련 문서

- CLAUDE.md 구성 → [02](02-claude-md.md)
- 스킬 전수 → [03](03-skills.md) / 에이전트 → [04](04-agents.md) / 훅 → [05](05-hooks.md) / 커맨드 → [06](06-commands.md)
- 트리거·목차·git → [07](07-triggers-and-index.md)
- ⭐ 완료 계약 하네스 → [08](08-harness.md)
