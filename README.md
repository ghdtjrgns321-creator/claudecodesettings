# claudecodesettings

Claude Code(`~/.claude`)의 전역 설정을 관리하는 저장소.

## 핵심 원칙

1. **CLAUDE.md 슬림 유지** - 원칙(무엇을,왜)만 남기고 방법(어떻게)은 스킬·플러그인으로 링크. 목차운영을 통해 토큰을 5K 이하로 관리.
2. **원칙은 훅으로 강제** - 훅은 100% 차단 가능. 완료 검증,위험 명령등은 훅을 통하여 관리.
3. **완료 계약은 하네스로 관리** - 하네스가 집합·다건 주장에 대해 M/N 분모와 대조 산출물을 요구, 충족 실패시 Stop 게이트가 종료를 차단.
4. **전역설정과 프로젝트설정 구분** - `~/.claude`엔 하네스·안전장치만. 도메인 지식은 각 프로젝트로 관리.

## 문서 (docs/)

| #   | 문서                                                | 내용                                 |
| --- | --------------------------------------------------- | ------------------------------------ |
| 1   | [overview](docs/01-overview.md)                     | 전체 구조                             |
| 2   | [claude-md](docs/02-claude-md.md)                   | CLAUDE.md 구성 방식                  |
| 3   | [skills](docs/03-skills.md)                         | 스킬 설명 + 트리거 방식              |
| 4   | [agents](docs/04-agents.md)                         | 에이전트 설명                        |
| 5   | [hooks](docs/05-hooks.md)                           | 훅 설명                              |
| 6   | [commands](docs/06-commands.md)                     | 슬래시 커맨드 관리                   |
| 7   | [triggers-and-index](docs/07-triggers-and-index.md) | 트리거,목차 운영,git 관리            |
| 8   | [harness](docs/08-harness.md)                       | 하네스 관리                          |
| 9   | [plugins](docs/09-plugins.md)                       | 플러그인 관리                        |

## 현재 규모 (2026-07-05)

| 항목      | 수                            |
| --------- | ----------------------------- |
| CLAUDE.md | 84줄 (~2.1k 토큰)             |
| 전역 스킬 | 12 (고유 2 + 도구 5 + 외부 5) |
| 플러그인  | 4                             |
| 에이전트  | 2                             |
| 훅        | 10                            |
| 커맨드    | 3                             |

## 디렉토리 (버전관리 대상)

```
~/.claude/
├─ CLAUDE.md              전역 규칙 (§0~§10)
├─ README.md              (이 파일)
├─ settings.json          훅·권한·플러그인 배선
├─ docs/                  시스템 문서 (하네스 설명 포함)
├─ agents/                에이전트
├─ skills/                스킬
├─ hooks/                 훅 스크립트 (*.sh *.py)
├─ commands/              슬래시 커맨드
├─ rules/                
├─ output-styles/
└─ scripts/               
```
