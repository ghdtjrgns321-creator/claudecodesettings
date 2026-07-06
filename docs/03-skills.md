# 03. Skills — 스킬 설명 + 트리거

## 트리거는 어떻게 작동하나

스킬은 각 `SKILL.md`의 **`description`을 Claude가 보고 자동으로 띄운다**. 별도 배선 파일 없음.

- 한국어로 자주 부르는 스킬(pdf 등)은 description에 한글 트리거 키워드를 박아둠 (예: pdf → PDF 파싱).
- 스킬이 적을수록 매칭 정확도↑ → 전역은 12개로 슬림 유지.

## 전역 스킬 12개

### 고유 하네스 (2) 

| 스킬                  | 역할                                      | 트리거 예                              |
| --------------------- | ----------------------------------------- | -------------------------------------- |
| ripple-search         | 스키마·설정·리네임 변경 시 구값 전체 검색 | "전부 업데이트해줘", "이름 바꿔줘"     |
| work-prompt-authoring | 값싼 에이전트용 작업 프롬프트 작성        | "서브 에이전트로해", "하청으로 진행해" |

### 범용 도구 (5)

| 스킬                  | 역할                  | 트리거 예              |
| --------------------- | --------------------- | ---------------------- |
| pdf                   | PDF 추출·병합·OCR     | "PDF 파싱"             |
| mermaid               | 다이어그램            | "순서도", "다이어그램" |
| find-skills           | 스킬 탐색·설치 안내   | "스킬 찾아줘"          |
| frontend-design       | 고품질 프론트 UI 생성 | "UI 만들어"            |
| web-design-guidelines | UI 접근성·UX 리뷰     | "UI 리뷰해"            |

### 외부 라이브러리 (5) — `~/.agents/skills` 심링크

| 스킬                       | 역할                                   |
| -------------------------- | -------------------------------------- |
| grilling                   | 계획·설계를 집요하게 인터뷰(구멍 찾기) |
| grill-me                   | 설계 인터뷰(심문형)                    |
| grill-with-docs            | 심문 + ADR·용어집 문서 생성            |
| playwright-cli             | 브라우저 자동화(테스트·폼·스크린샷)    |
| playwright-explore-website | Playwright 웹사이트 탐색               |

## 하네스는 플러그인이 제공 (superpowers)

핵심 작업 규율은 **superpowers 플러그인**(Jesse Vincent/obra 제작, 외부 배포판)에 위임한다. 설치하면 `superpowers:*` 스킬 14개가 딸려 오고, 각자 `description`으로 자동 트리거된다. 유지보수는 제작자가 한다(우리가 안 만듦).

**"어떻게 일할지"를 알려주는 14개 스킬:**

| 단계   | 스킬                             | 역할 (언제 뜨나)                                                  |
| ------ | -------------------------------- | ----------------------------------------------------------------- |
| 설계   | `brainstorming`                  | 기능·컴포넌트 만들기 전 의도·요구·설계를 먼저 탐색 (창작 전 필수) |
| 설계   | `writing-plans`                  | 스펙/요구가 있는 다단계 작업을 코드 전에 계획서로                 |
| 설계   | `using-git-worktrees`            | 기능 작업 격리가 필요할 때 worktree로 독립 작업공간 확보          |
| 구현   | `test-driven-development`        | 구현 코드 짜기 전 테스트부터 (RED-GREEN-REFACTOR)                 |
| 구현   | `executing-plans`                | 작성된 계획을 별도 세션에서 리뷰 체크포인트와 함께 실행           |
| 구현   | `subagent-driven-development`    | 독립 작업들을 현재 세션에서 서브에이전트로 실행                   |
| 구현   | `dispatching-parallel-agents`    | 의존 없는 2+ 작업을 병렬 에이전트로 분산                          |
| 검증   | `systematic-debugging`           | 버그·테스트 실패 시 고치기 전에 근본원인 체계적 진단              |
| 검증   | `verification-before-completion` | "완료/통과" 주장 전에 검증 명령 실행·출력 확인 (증거 우선)        |
| 리뷰   | `requesting-code-review`         | 작업 완료·주요 기능·머지 전 요구충족 검증 리뷰 요청               |
| 리뷰   | `receiving-code-review`          | 리뷰 피드백 받을 때 맹목 수용 말고 기술적 검증 후 반영            |
| 마무리 | `finishing-a-development-branch` | 구현·테스트 완료 후 머지/PR/정리 중 통합 방식 결정                |
| 메타   | `using-superpowers`              | 대화 시작 시 스킬을 어떻게 찾아 쓰는지 확립                       |
| 메타   | `writing-skills`                 | 새 스킬 작성·편집·배포 전 검증                                    |

→ 우리가 옛날에 갖고 있던 tdd·systematic-debugging·verification 복사본은 이 플러그인과 겹쳐서 **삭제**했고, 이제 이 유지보수판을 쓴다.

## 운영 규칙

- 스킬 추가·삭제·이동 시 `skills/README.md` 목차를 같은 작업에서 갱신.
- 새 스킬을 전역에 두기 전 역할 겹침 확인 — 겹치면 전역에 두지 않는다.

