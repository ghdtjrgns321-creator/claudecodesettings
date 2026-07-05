# claudecodesettings — Claude Code 전역 설정

Claude Code(`~/.claude`)의 전역 설정을 **"작업 방식 하네스"** 로 슬림하게 관리하는 저장소.
규칙은 CLAUDE.md, 방법론은 스킬, 강제는 훅, 도메인 지식은 각 프로젝트 — **한 내용은 한 곳(SSOT)** 에만 둔다.

## 핵심 원칙 (5줄)

1. **CLAUDE.md엔 원칙만.** "무엇을·왜"만 두고 "어떻게"는 스킬로 링크. (5k 토큰 이하 유지)
2. **강제는 훅.** non-negotiable(시크릿·인코딩·완료검증)은 지시가 아니라 훅으로 100% 결정적 차단.
3. **하네스는 플러그인.** TDD·디버깅·검증 등은 superpowers 플러그인(유지보수판)에 위임.
4. **도메인은 프로젝트로.** 회계·스택 스킬은 전역이 아니라 각 프로젝트 `.claude/`.
5. **목차로 운영.** 스킬·에이전트 추가·삭제 시 README 목차를 같은 작업에서 갱신.

## 문서 (docs/)

| #   | 문서                                                | 내용                                      |
| --- | --------------------------------------------------- | ----------------------------------------- |
| 1   | [overview](docs/01-overview.md)                     | 전체 생태계 구조 + ASCII 다이어그램       |
| 2   | [claude-md](docs/02-claude-md.md)                   | CLAUDE.md 구성 방식 (카파티 4원칙·§0~§10) |
| 3   | [skills](docs/03-skills.md)                         | 스킬 전수 + 트리거 방식                   |
| 4   | [agents](docs/04-agents.md)                         | 에이전트 + 대체 수단                      |
| 5   | [hooks](docs/05-hooks.md)                           | 훅 10개 + 이벤트                          |
| 6   | [commands](docs/06-commands.md)                     | 슬래시 커맨드                             |
| 7   | [triggers-and-index](docs/07-triggers-and-index.md) | 트리거·목차 운영·git 관리                 |

> 결정 과정의 상세 분석 로그(`전역설정-체계.md`)는 로컬 전용(비공개)으로 관리한다.

## 현재 규모 (2026-07-05)

| 항목                 | 수                                          |
| -------------------- | ------------------------------------------- |
| CLAUDE.md            | 84줄 (~2.1k 토큰)                           |
| 전역 스킬            | 13 (고유 2 + 도구 6 + 외부 5)               |
| superpowers 플러그인 | 14 스킬                                     |
| 에이전트             | 2 (code-reviewer · documentation-architect) |
| 훅                   | 10                                          |
| 커맨드               | 3                                           |

## 디렉토리 (버전관리 대상)

```
~/.claude/
├─ CLAUDE.md              전역 규칙 (§0~§10)
├─ README.md              (이 파일)
├─ 전역설정-체계.md        결정 기록
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

> 시크릿·캐시·세션 기록은 `.gitignore`로 제외 (docs/07 참조).
