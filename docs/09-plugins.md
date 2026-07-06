# 09. Plugins — 플러그인

> 플러그인 = **스킬·에이전트·훅·LSP를 묶은 외부 배포판.** `/plugin`으로 설치하면 그 안의 기능이 통째로 딸려 온다.

## 스킬·에이전트·훅과 뭐가 다른가

|                        | 만드는 주체 | 사는 곳                      | repo 포함 | 유지보수                          |
| ---------------------- | ----------- | ---------------------------- | --------- | --------------------------------- |
| 스킬/에이전트/훅(고유) | 내가 작성   | `skills/`·`agents/`·`hooks/` | ✅        | 내가                              |
| **플러그인**           | **제3자**   | `plugins/cache/`             | ❌(캐시)  | **제작자가 원격서 자동 업데이트** |

즉 플러그인은 "설치만 하면 되는 남의 패키지". 내 저장소엔 **설정(`settings.json`의 활성화 여부)만** 담기고, 실제 파일은 `plugins/cache/`에 캐시되어 커밋되지 않는다. 클론한 사람은 `/plugin install`로 각자 받는다.

## 설치된 플러그인

출처 마켓플레이스: `claude-plugins-official`(Anthropic 공식) + `context-mode`(추가만).

| 플러그인              | 종류      | 역할                                            | 상태                |
| --------------------- | --------- | ----------------------------------------------- | ------------------- |
| **superpowers**       | 스킬 14개 | 작업 방식 하네스(TDD·디버깅·검증·계획·리뷰…) ⭐ | 설치·활성           |
| **pyright-lsp**       | LSP       | Python 코드 인텔리전스(타입체크·정의 이동·심볼) | 설치·활성           |
| **rust-analyzer-lsp** | LSP       | Rust 코드 인텔리전스                            | 설치·활성           |
| context-mode          | (마켓)    | 세션 컨텍스트 연장                              | 마켓만 추가, 미설치 |
| harness-marketplace   | (마켓)    | 하네스 관련 플러그인                            | 마켓만 추가, 미설치 |

> LSP 플러그인은 Claude가 그 언어의 코드를 더 정확히 이해하게 돕는 언어 서버 연동(스킬 아님).

## superpowers 14개 스킬 (전 과정 "일하는 방식")

Jesse Vincent(obra) 제작. 설치하면 `superpowers:*` 스킬 14개가 딸려 온다.

| 단계   | 스킬                             | 역할                                         |
| ------ | -------------------------------- | -------------------------------------------- |
| 설계   | `brainstorming`                  | 만들기 전 의도·요구·설계 탐색 (창작 전 필수) |
| 설계   | `writing-plans`                  | 다단계 작업을 코드 전 계획서로               |
| 설계   | `using-git-worktrees`            | 격리 작업공간(worktree) 확보                 |
| 구현   | `test-driven-development`        | 테스트부터 (RED-GREEN-REFACTOR)              |
| 구현   | `executing-plans`                | 계획을 리뷰 체크포인트와 실행                |
| 구현   | `subagent-driven-development`    | 독립 작업을 서브에이전트로                   |
| 구현   | `dispatching-parallel-agents`    | 의존 없는 2+ 작업 병렬 분산                  |
| 검증   | `systematic-debugging`           | 버그 근본원인 체계 진단                      |
| 검증   | `verification-before-completion` | "완료" 전 검증 명령·출력 확인                |
| 리뷰   | `requesting-code-review`         | 머지 전 요구충족 리뷰 요청                   |
| 리뷰   | `receiving-code-review`          | 피드백 맹목수용 말고 검증 후 반영            |
| 마무리 | `finishing-a-development-branch` | 머지/PR/정리 결정                            |
| 메타   | `using-superpowers`              | 대화 시작 시 스킬 사용법 확립                |
| 메타   | `writing-skills`                 | 새 스킬 작성·검증                            |

## 어떻게 쓰나 — 자동인가?

**반자동(설명 매칭 기반).** 훅처럼 무조건 도는 게 아니라, 각 스킬의 `description`을 Claude가 보고 상황이 맞으면 **스스로 호출**한다.

- superpowers 설명은 "You MUST use before any creative work"(brainstorming), "before ANY response"(using-superpowers)처럼 **강하게** 써 있어 잘 튀어나온다.
- 단 모델 판단이라 **100% 결정적이진 않다**(훅과의 결정적 차이). 필요하면 사용자가 명시로 부를 수도 있다.
- 우리 옛 복사본(tdd·systematic-debugging 등)은 이 플러그인과 겹쳐 **삭제**하고 유지보수판을 쓴다.

## 관계 한 줄

**훅**(100% 강제) > **플러그인/스킬**(설명 매칭 자동) > **커맨드**(수동 `/이름`). 강제할수록 훅, 상황 판단이면 스킬, 손수 부르면 커맨드.
