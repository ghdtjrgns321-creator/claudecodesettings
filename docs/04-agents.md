# 04. Agents — 에이전트

에이전트 = 여러 단계를 자율 수행하는 부하 일꾼(Task 도구로 파견, 독립 컨텍스트).
**원칙: 역할이 겹치면 Claude가 어느 걸 쓸지 못 정해 위임이 불안정(flaky)해진다 → 최소로 유지.**

## 유지 에이전트 (2)

| 에이전트                    | 역할                                      | 언제                          | 실사용      |
| --------------------------- | ----------------------------------------- | ----------------------------- | ----------- |
| **code-reviewer**           | 한국어 코드 리뷰(품질·보안·성능·아키텍처) | 기능/버그/리팩터 완료 후 자동 | 21회 (주력) |
| **documentation-architect** | 개발 문서 작성·검증·다이어그램            | 문서 작성·대량 수정 시        | 3회         |

## 다른 역할은 빌트인·플러그인으로 (전역 에이전트 안 만듦)

| 역할              | 대체 수단                                        |
| ----------------- | ------------------------------------------------ |
| 계획 수립         | 빌트인 `Plan` · `superpowers:writing-plans`      |
| 탐색·리서치       | 빌트인 `Explore` · `deep-research` · `WebSearch` |
| 디버깅            | `superpowers:systematic-debugging`               |
| 리팩토링          | 빌트인 `simplify`                                |
| 보안 검토         | 빌트인 `/security-review` 커맨드                 |
| 서브에이전트 실행 | `superpowers:subagent-driven-development`        |

## 정리 이력 (6 → 2)

삭제(2026-07-05, 백업 `backups/pre-agent-cleanup-2026-07-05.tar`):

| 삭제                    | 이유                                  |
| ----------------------- | ------------------------------------- |
| code-refactor-master    | 미등록 + 0회 + `simplify` 중복        |
| web-research-specialist | 미등록 + 0회 + `Explore` 중복         |
| planner                 | 빌트인 Plan + superpowers 3중 중복    |
| error-resolver          | superpowers:systematic-debugging 중복 |

## 운영 규칙

- 에이전트 추가·삭제 시 `agents/README.md` 목차를 같은 작업에서 갱신.
- 새 에이전트 만들기 전 위 "대체 수단"과 역할 겹침 확인 — 겹치면 만들지 않는다.
- 3~5개 focused 에이전트가 권장 상한(그 이상은 결과 병합 비용이 이득을 넘음).
