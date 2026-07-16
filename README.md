# claudecodesettings

Claude Code(`~/.claude`)의 전역 설정을 관리하는 저장소

## 핵심 원칙

1. **컨텍스트 최소화**
   - CLAUDE.md에는 판단 규칙만 간결하게
   - 구체적인 실행 절차는 스킬로 필요할 때만 로드하여 동작
2. **통제 수준의 분리**
   - 상황에 따른 판단이 필요한 안내 사항은 스킬로 제공
   - 반드시 지켜야 하는 필수 규칙은 훅으로 강제
3. **작업 완료 검증**
   - 완료 조건을 실행 명령으로 적어두면 끝날 때마다 훅이 그 명령을 직접 실행
   - 전수 작업: 목록을 스크립트로 뽑아 파일로 고정 → 작업 → 스크립트가 대조해 누락 지목
4. **설정의 모듈화**
   - 전역 설정(`~/.claude`)에는 상황에 종속되지 않는 범용 환경과 안전장치만 배치
   - 특정 기술 스택 및 도메인 지식은 개별 프로젝트 환경 내에 독립적으로 구성

## 문서 (docs/)

| #   | 문서                                                | 내용                        |
| --- | --------------------------------------------------- | --------------------------- |
| 1   | [overview](docs/01-overview.md)                     | 전체 구조                   |
| 2   | [claude-md](docs/02-claude-md.md)                   | CLAUDE.md 구성 방식         |
| 3   | [skills](docs/03-skills.md)                         | 스킬 설명 + 트리거 방식     |
| 4   | [agents](docs/04-agents.md)                         | 에이전트 설명               |
| 5   | [hooks](docs/05-hooks.md)                           | 훅 설명                     |
| 6   | [commands](docs/06-commands.md)                     | 슬래시 커맨드 관리          |
| 7   | [triggers-and-index](docs/07-triggers-and-index.md) | 트리거,목차 운영,git 관리   |
| 8   | [harness](docs/08-harness.md)                       | 하네스 관리                 |
| 9   | [plugins](docs/09-plugins.md)                       | 플러그인 관리               |
| —   | [2026-07-16-redesign](docs/2026-07-16-redesign.md)  | 재설계 근거 데이터·복원경로 |

## 현재 규모 (2026-07-16)

| 항목      | 수                          |
| --------- | --------------------------- |
| CLAUDE.md | 43줄 (~1.1k 토큰)           |
| 전역 스킬 | 19 (직접 제작 9 + 외부 10)  |
| 플러그인  | 5 설치 (superpowers 비활성) |
| 에이전트  | 2                           |
| 훅        | 5                           |
| 커맨드    | 3                           |

## 디렉토리 (버전관리 대상)

```
~/.claude/
├─ CLAUDE.md              전역 규칙 (판단 규칙만, 43줄)
├─ README.md              (이 파일)
├─ settings.json          훅·권한·플러그인 배선
├─ docs/                  시스템 문서 (하네스 설명 포함)
├─ agents/                에이전트
├─ skills/                스킬 (census 포함)
├─ hooks/                 훅 스크립트 5개 (*.sh *.py)
├─ commands/              슬래시 커맨드
├─ rules/
├─ output-styles/
└─ scripts/
```
