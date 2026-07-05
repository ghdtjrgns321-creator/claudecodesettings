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

핵심 작업 규율은 **superpowers 플러그인**(Jesse Vincent, `superpowers:*`)에 위임:
brainstorming · test-driven-development · systematic-debugging · verification-before-completion ·
subagent-driven-development · writing-skills · writing-plans · executing-plans · using-git-worktrees 등 14개.

## 운영 규칙

- 스킬 추가·삭제·이동 시 `skills/README.md` 목차를 같은 작업에서 갱신.
- 새 스킬을 전역에 두기 전 역할 겹침 확인 — 겹치면 전역에 두지 않는다.

