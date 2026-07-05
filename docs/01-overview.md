# 01. Overview — 전체 생태계

Claude Code 설정은 **세 저장소 + 플러그인 + 프로젝트**로 나뉜다. 각자 역할이 다르다.

## 생태계 구조

```
┌─────────────────────────────────────────────────────────────────────┐
│  ~/.claude/   (이 저장소 = claudecodesettings)                        │
│  "작업 방식 하네스" — 언어·도메인 무관 전역 규칙                      │
│                                                                       │
│   CLAUDE.md ──── 규칙(무엇을·왜)  §0~§10, 카파티 4원칙               │
│   hooks/ ─────── 강제(어떻게 100%) 시크릿·인코딩·완료게이트          │
│   skills/ ────── 방법론·도구 (고유 2 + 도구 6 + 외부링크 5)          │
│   agents/ ────── 자율 일꾼 (code-reviewer · documentation-architect) │
│   commands/ ──── 슬래시 명령 (brainstorm · dev-docs · dev-docs-update)│
│   settings.json ─ 위 전부의 배선(훅·권한·플러그인)                   │
└───────────────┬─────────────────────────────┬───────────────────────┘
                │ 심링크(5)                    │ 플러그인 설치
                ▼                              ▼
┌──────────────────────────┐    ┌──────────────────────────────────────┐
│ ~/.agents/skills/         │    │ superpowers 플러그인 (Jesse Vincent) │
│ 공유 스킬 라이브러리      │    │ 핵심 하네스 14개 (유지보수판):        │
│ grill·playwright 등       │    │ brainstorming·TDD·debugging·          │
│ (원본, repo 제외)         │    │ verification·subagent·writing-skills… │
└──────────────────────────┘    └──────────────────────────────────────┘

                프로젝트에서 작업할 때 (예: workspace/portfolio/*)
                ▼
┌─────────────────────────────────────────────────────────────────────┐
│  각 프로젝트/.claude/   (독립 git 저장소)                             │
│  도메인·스택 스킬이 여기 산다 (전역 아님):                           │
│   fs-multi-analyzer  ← streamlit·pandera·pytest·accounting           │
│   k-ifrs-1115        ← +fastapi·docker·langgraph-rag                  │
│   local-ai-assist    ← +imbalanced-ml·docker·pandera                 │
└─────────────────────────────────────────────────────────────────────┘
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
