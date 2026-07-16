# 03. Skills 

## 직접 제작 (9)

| 스킬                  | 역할                                                         | 트리거 예                              |
| --------------------- | ------------------------------------------------------------ | -------------------------------------- |
| ripple-search         | 스키마·설정·리네임 변경 시 구값 전체 검색                    | "전부 업데이트해줘", "이름 바꿔줘"     |
| work-prompt-authoring | 값싼 에이전트용 작업 프롬프트 작성                           | "서브 에이전트로해", "하청으로 진행해" |
| diagram-driven-docs   | 문서 작성 시 데이터흐름에 집중, 다이어그램·팩트시트 삽입     | "문서 작성", "README/아키텍처 정리"    |
| readme-maker          | 정리본 기반 README 인터뷰 생성 + humanize 자동 윤문          | "README 만들어줘", "리드미 생성"       |
| final-report          | 코드·MD 전수 정독 → 프로젝트 FINAL-REPORT 생성(전수 증명)    | "FINAL REPORT 만들어줘", "최종 보고서" |
| census                | 전수 작업을 차집합으로 증명(분모 파일 고정→흔적→census_diff) | "전수", "전부", "모든", "M/N"          |
| brainstorming         | 코드 전 가정 좁히기·접근법 2~3개 비교                        | "만들자", "설계해줘", "어떻게 구현"    |
| systematic-debugging  | 원인 조사 없이 수정 금지·3회 실패 시 구조 의심               | "에러났어", "왜 이래", "두더지잡기"    |
| writing-skills        | 스킬 작성·description 트리거 설계·서브에이전트 시험          | "스킬 만들어줘", "스킬이 안 뜬다"      |

- brainstorming·systematic-debugging·writing-skills는 superpowers 6.1.1에서 발췌해 의례를 덜어내고 재작성

## 외부 (10)

### Anthropic 배포 (5)

| 스킬                  | 역할                  | 트리거 예              |
| --------------------- | --------------------- | ---------------------- |
| pdf                   | PDF 추출·병합·OCR     | "PDF 파싱"             |
| mermaid               | 다이어그램            | "순서도", "다이어그램" |
| find-skills           | 스킬 탐색·설치 안내   | "스킬 찾아줘"          |
| frontend-design       | 고품질 프론트 UI 생성 | "UI 만들어"            |
| web-design-guidelines | UI 접근성·UX 리뷰     | "UI 리뷰해"            |

### 외부제작 스킬 적용 (5)

| 스킬                       | 역할                                   |
| -------------------------- | -------------------------------------- |
| grilling                   | 계획·설계를 집요하게 인터뷰(구멍 찾기) |
| grill-me                   | 설계 인터뷰(심문형)                    |
| grill-with-docs            | 심문 + ADR·용어집 문서 생성            |
| playwright-cli             | 브라우저 자동화(테스트·폼·스크린샷)    |
| playwright-explore-website | Playwright 웹사이트 탐색               |

## 플러그인 스킬

| 플러그인                                                   | 제공 스킬            | 상태                         |
| ---------------------------------------------------------- | -------------------- | ---------------------------- |
| [harness](https://github.com/revfactory/harness)           | 1 (`harness`)        | 활성                         |
| [humanize-korean](https://github.com/epoko77-ai/im-not-ai) | 3 + 에이전트 10      | 활성 — 한글 윤문             |

## 운영 규칙

- 스킬 추가·삭제·이동 시 `skills/README.md` 목차를 같은 작업에서 갱신
- 새 스킬을 전역에 두기 전 기존 스킬·플러그인과 역할 겹침 확인
