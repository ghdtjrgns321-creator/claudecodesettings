---
name: census
description: Use when the task claims full coverage — 전수, 전부, 모든, 빠짐없이, M/N, 매핑 일치, 커버리지, exhaustive audit/migration/tagging. 전수·다건 작업의 완료를 문장이 아니라 차집합 스크립트로 증명한다. 분모를 손으로 만들면 안 되는 모든 작업에서 활성화.
---

# Census — 전수는 선언하지 않고 계산한다

전수 작업의 실패는 늘 같은 곳에서 난다: 분모를 LLM이 정한다 → 몇 개 하다 힘 빠지면 분모가 줄어든다 → "전수 완료"라는 문장만 남는다. 이 스킬은 분모를 LLM 손 밖으로 빼서 그 경로를 막는다.

## 절차 (3단계)

1. **분모 고정.** 착수 직후, 대상 전체를 결정론적 도구로 뽑아 파일로 박제한다.
   - 파일이면 `git ls-files '*.py' > population.txt`
   - 데이터면 쿼리/grep 결과를 리다이렉트
   - **손으로 목록을 쓰거나 기억으로 채우면 그 시점에 이미 실패다.**
2. **항목별 흔적.** 항목을 처리할 때마다 `done.txt`에 한 줄 추가(또는 산출물 파일이 항목당 1개 생기게). 흔적 없는 처리는 처리가 아니다.
3. **차집합 판정.** 완료 선언 전에 실행:
   ```
   python ~/.claude/skills/census/scripts/census_diff.py population.txt done.txt
   ```
   - `PASS M/N` + exit 0 → 완료 선언 가능
   - `FAIL` + 누락 이름 목록 → 그 항목들을 마저 처리. "대부분 했다"는 상태는 존재하지 않는다.

## contract 연동

contract를 쓰는 세션이면 VERIFY 줄로 박아 Stop 게이트가 직접 실행하게 한다:

```
- [x] 룰 41건 전수 태깅 (분모: population.txt)
VERIFY: python ~/.claude/skills/census/scripts/census_diff.py population.txt done.txt
```

## 금지

- 분모 파일 없이 "전수 완료" 서술 금지. 검증 불가 주장엔 `미검증` 라벨을 남긴다.
- 분모를 중간에 줄이는 편집 금지. 대상이 실제로 줄었으면 분모 생성 명령을 고치고 재생성한다(사유 1줄 기록).
- population과 done의 항목 표기는 같은 형식(경로면 둘 다 상대경로 등)으로 맞춘다.
