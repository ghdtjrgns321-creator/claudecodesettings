---
name: final-report
description: "Use when the user asks for a comprehensive project-wide FINAL REPORT distilled from the entire codebase and docs, or wants to regenerate/update an existing FINAL-REPORT directory. 트리거: 'FINAL REPORT 만들어/써줘', '최종 보고서', '파이널 리포트', '프로젝트 전체 보고서', '프로젝트 정리 보고서', 'PPT·README 초석 보고서'."
---

# Final Report (전수 기반 최종 보고서)

## 핵심 원칙

**표본이 아니라 전수(全數).** 분모 N은 `scripts/census.py`가 기계로 고정하고, 커버리지 부록이 N/N을 증명해야 완료다. 산출물은 추후 PPT·README(readme-maker)로 가공되는 원료 — 요약하지 말고 세부(수치·설정·코드 인용)를 눌러 담는다.

## 산출물

`<project_root>/FINAL-REPORT/` 디렉토리. 장 구성·장별 필수 요소·시각화(ASCII+Mermaid+배지) 규격은 **references/report-skeleton.md**를 따른다. 문서 스타일(팩트시트 선행·다이어그램 우선·M/N·현재/과거 분리)은 diagram-driven-docs 스킬 계약을 그대로 적용한다.

## 절차

### 1. 센서스 — 분모 N 고정
```bash
python <이 스킬 경로>/scripts/census.py inventory <project_root> --out <scratchpad>/inventory.json
```
git 저장소면 git ls-files 기준(생성 데이터는 gitignore로 걸러짐), 아니면 전체 순회. 하네스·빌드 디렉토리 기본 제외(목록은 스크립트 상단 상수). `large=true` 파일과 균일 데이터 디렉토리는 "구조 정독"(스키마·대표 표본) 대상으로 표시해 둔다.

### 2. 분산 정독 — 1묶음 1서브에이전트
인벤토리를 디렉토리·도메인 묶음(15~30파일)으로 나눠 팬아웃. 프롬프트는 work-prompt-authoring 스킬로 작성하고, **묶음의 파일 목록을 프롬프트에 명시**해 에이전트가 임의 표본화하지 못하게 한다. 각 에이전트 반환 노트(파일별): 경로 / 역할 1~2줄 / 핵심 수치·상수(출처 라인) / 관계(호출·참조) / 보고서 인용 후보. 총 30파일 이하 소규모면 팬아웃 없이 직접 정독해도 된다.

### 3. 팩트시트 — 수치의 단일 출처
노트를 통합해 정본 팩트시트를 scratchpad에 작성. 이후 본문의 모든 수치는 팩트시트에서만 가져온다.

### 4. 집필 — 전체→세세
report-skeleton.md 순서대로: 표지(0) → 개요(1) → **전체 파이프라인(2)** → **부분별 상세(3..K)** → **차별점·특장점** → 검증·ADR → 여정 → 커버리지.

### 5. 검증 — verify exit 0까지
```bash
python <이 스킬 경로>/scripts/census.py verify <project_root> <FINAL-REPORT/마지막 번호의 *_COVERAGE.md>
```
누락 파일이 나오면 그 파일을 정독·반영하고 재실행 — exit 0이 될 때까지 루프. 마지막으로 핵심 수치 3개 이상을 원본에서 재확인(스팟체크)한 뒤 완료를 선언한다.

## Quick Reference

| 단계      | 도구                | 완료 기준                       |
| --------- | ------------------- | ------------------------------- |
| 센서스    | census.py inventory | N 고정 + inventory.json 저장    |
| 분산 정독 | 서브에이전트 팬아웃 | 모든 묶음 노트 수신 (묶음 M/M)  |
| 팩트시트  | scratchpad 통합     | 본문 수치 출처 100% 팩트시트    |
| 집필      | report-skeleton.md  | 고정 장 + 상세 장 + 커버리지 장 |
| 검증      | census.py verify    | exit 0 (N/N) + 수치 스팟체크 ≥3 |

## 흔한 실패

- **표본 몇 개 읽고 "전수" 주장** → verify exit 0 없이는 완료 선언 금지 (hollow-PASS).
- **분모에서 조용히 제외** → `--exclude` 사용 시 커버리지 장에 제외 표(디렉토리·건수·사유) 필수, verify도 동일 `--exclude`로 실행.
- **요약 기억으로 수치 기입** → 팩트시트 먼저, 본문은 팩트시트만 인용.
- **기존 FINAL-REPORT 갱신 요청** → 기존 장 구성을 존중하되 센서스부터 다시(N 변동 반영).
- **대형 파일 전문 정독 시도** → `large=true`는 구조 정독(스키마+대표 표본)으로 대체하고 커버리지 비고에 표기.
