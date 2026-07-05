# 03. Skills — 스킬 전수 + 트리거

## 트리거는 어떻게 작동하나 (중요)

스킬은 각 `SKILL.md`의 **`description`을 Claude가 보고 자동으로 띄운다**(네이티브 매칭). 별도 배선 파일 없음.

- 과거엔 `skill-rules.json`으로 "키워드→스킬" 배선을 했으나, **이를 읽는 훅이 없어 죽은 파일이라 삭제**했다.
- 따라서 **트리거 품질 = description 품질**. 한국어로 자주 부르는 스킬(docx·pdf 등)은 description에 한글 트리거 키워드를 박아둠 (예: docx → "워드·문서 만들기").
- 스킬이 적을수록 매칭 정확도↑ → 전역은 13개로 슬림 유지.

## 전역 스킬 13개

### 고유 하네스 (2) — superpowers에 없는 우리 것

| 스킬                  | 역할                                      | 트리거 예                  |
| --------------------- | ----------------------------------------- | -------------------------- |
| ripple-search         | 스키마·설정·리네임 변경 시 구값 전체 검색 | "설정 바꿨어", "이름 바꿔" |
| work-prompt-authoring | 값싼 에이전트용 작업 프롬프트 작성        | "작업 프롬프트", "하청"    |

### 범용 도구 (6)

| 스킬                  | 역할                  | 트리거 예              |
| --------------------- | --------------------- | ---------------------- |
| docx                  | Word 생성·편집        | "워드", "docx"         |
| pdf                   | PDF 추출·병합·OCR     | "PDF 합쳐"             |
| mermaid               | 다이어그램            | "순서도", "다이어그램" |
| find-skills           | 스킬 탐색·설치 안내   | "이런 스킬 없나"       |
| frontend-design       | 고품질 프론트 UI 생성 | "UI 만들어", "웹 화면" |
| web-design-guidelines | UI 접근성·UX 리뷰     | "UI 리뷰"              |

### 외부 라이브러리 (5) — `~/.agents/skills` 심링크

| 스킬                       | 역할                                   |
| -------------------------- | -------------------------------------- |
| grilling                   | 계획·설계를 집요하게 인터뷰(구멍 찾기) |
| grill-me                   | 설계 인터뷰(심문형)                    |
| grill-with-docs            | 심문 + ADR·용어집 문서 생성            |
| playwright-cli             | 브라우저 자동화(테스트·폼·스크린샷)    |
| playwright-explore-website | Playwright 웹사이트 탐색               |

> 심링크는 원본이 `~/.agents`에 있어 repo에는 포함하지 않는다(`.gitignore`).

## 하네스는 플러그인이 제공 (superpowers)

핵심 작업 규율은 **superpowers 플러그인**(Jesse Vincent, `superpowers:*`)에 위임:
brainstorming · test-driven-development · systematic-debugging · verification-before-completion ·
subagent-driven-development · writing-skills · writing-plans · executing-plans · using-git-worktrees 등 14개.

→ 예전엔 이걸 우리가 복사(tdd·systematic-debugging 등)해 갖고 있었으나, **플러그인 설치 후 중복 제거**했다. 유지보수는 플러그인이 담당.

## 도메인·스택 스킬은 프로젝트로

전역에서 각 프로젝트 `.claude/skills/`로 이동(복사):

| 프로젝트          | 스킬                                      |
| ----------------- | ----------------------------------------- |
| fs-multi-analyzer | streamlit · pandera · pytest · accounting |
| k-ifrs-1115       | +fastapi · docker · langgraph-rag         |
| local-ai-assist   | +imbalanced-ml · docker · pandera         |

## 운영 규칙

- 스킬 추가·삭제·이동 시 `skills/README.md` 목차를 같은 작업에서 갱신.
- 새 스킬을 전역에 두기 전 superpowers·프로젝트 스킬과 역할 겹침 확인 — 겹치면 전역에 두지 않는다.
- 전역은 "언어·도메인 무관"만.
