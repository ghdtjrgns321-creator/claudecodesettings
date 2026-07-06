# claudecodesettings

Claude Code(`~/.claude`)의 전역 설정을 관리하는 저장소.

## 핵심 원칙

1. **CLAUDE.md엔 원칙만.** 무엇을, 왜 만 두고, 어떻게? 는 스킬로 링크. (5k 토큰 이하 유지)
2. **강제는 훅.** 완료검증 등은 지시가 아니라 훅으로 100% 차단.
3. **하네스는 플러그인.** 디버깅,검증 등은 superpowers 플러그인에 위임.
4. **목차 운영.** 스킬,에이전트 추가·삭제 시 README 목차를 같은 작업에서 갱신.

## 문서 (docs/)

| #   | 문서                                                   | 내용                                                   |
| --- | ------------------------------------------------------ | ------------------------------------------------------ |
| 1   | [overview](docs/01-overview.md)                        | 전체 생태계 구조 및 ASCII 다이어그램                   |
| 2   | [claude-md](docs/02-claude-md.md)                      | CLAUDE.md 구성 방식                                    |
| 3   | [skills](docs/03-skills.md)                            | 스킬 설명 + 트리거 방식                                |
| 4   | [agents](docs/04-agents.md)                            | 에이전트 설명                                          |
| 5   | [hooks](docs/05-hooks.md)                              | 훅 설명                                                |
| 6   | [commands](docs/06-commands.md)                        | 슬래시 커맨드 관리                                     |
| 7   | [triggers-and-index](docs/07-triggers-and-index.md)    | 트리거,목차 운영,git 관리                              |
| 8   | [harness](docs/08-harness.md)                          | ⭐ 하네스 개요 (4 서브시스템) — 훅으로 강제하는 자동화 |
| 8a  | [completion-contract](docs/08a-completion-contract.md) | 완료 계약 — 증거 없이 완료 못 하게 강제                |
| 8b  | [safety-guard](docs/08b-safety-guard.md)               | 안전 가드 — 위험 명령 차단                             |
| 8c  | [integrity](docs/08c-integrity.md)                     | 무결성 — 인코딩·하드코딩·서식 자동 검사                |
| 8d  | [continuity](docs/08d-continuity.md)                   | 연속성 — 세션 넘어 작업 이어주기                       |
| 9   | [plugins](docs/09-plugins.md)                          | 플러그인 — superpowers 14스킬·LSP·트리거 방식          |

## 현재 규모 (2026-07-05)

| 항목                 | 수                            |
| -------------------- | ----------------------------- |
| CLAUDE.md            | 84줄 (~2.1k 토큰)             |
| 전역 스킬            | 12 (고유 2 + 도구 5 + 외부 5) |
| superpowers 플러그인 | 14 스킬                       |
| 에이전트             | 2                             |
| 훅                   | 10                            |
| 커맨드               | 3                             |

## 디렉토리 (버전관리 대상)

```
~/.claude/
├─ CLAUDE.md              전역 규칙 (§0~§10)
├─ README.md              (이 파일)
├─ settings.json          훅·권한·플러그인 배선
├─ docs/                  시스템 문서 (01~07)
├─ agents/                에이전트 + README(목차)
├─ skills/                전역 스킬 + README(목차)
├─ hooks/                 훅 스크립트 (*.sh *.py)
├─ commands/              슬래시 커맨드
├─ rules/                 plan-mode-brainstorming.md
├─ output-styles/
└─ scripts/               statusline.py
```
