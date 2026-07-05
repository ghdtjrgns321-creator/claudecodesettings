#!/usr/bin/env python3
# contract 항목 "측정 가능 형식" 검출기 (설계 §0 lazy-contract 구멍 보강).
#   완료[x] 선언했지만 수치·비교·실패조건·파일경로가 하나도 없는
#   "검증/분석 동사형 도달 항목"을 hollow-PASS 위험으로 검출한다.
# 사용: python contract_lint.py <contract_path>
#   flagged 있으면 stdout에 항목 출력 + exit 1, 없으면 무출력 exit 0.
# Why: 게이트는 "선언한 걸 했나"만 본다. 항목이 "도달했나" 수준이면
#   배선만 하고 [x] 가능 → 자기참조 self-pass. 형식으로 바닥을 깐다.
import re
import sys

# 측정 불가를 의심케 하는 "과정/판단 동사" (이것만 있고 근거 없으면 위험)
PROCESS_VERBS = re.compile(
    r"대조|통독|검토|점검|확인|분석|매핑|정합|리뷰|검수|파악|조사|살펴|비교|대사|"
    r"review|verify|check|audit"
)

# 면제 토큰: 하나라도 있으면 측정 가능으로 본다 (오차단 방지)
HAS_DIGIT = re.compile(r"\d")
HAS_COMPARE = re.compile(
    r"[≤≥<>=]|차액|차이|건수|개수|합계|일치|불일치|이상|이하|미만|초과|"
    r"funnel|퍼널|건\b|개\b|행\b|±|delta|count"
)
HAS_FAILCOND = re.compile(
    r"FAIL|실패|이면|없으면|아니면|틀리면|어긋나|누락|0건|빈\s|empty|미달|초과하면"
)
# 파일경로/확장자 = 실물 산출물 → 면제
HAS_PATH = re.compile(r"[/\\]|\.\w{1,5}\b")

# 집합 커버리지 단언: 열거 가능한 대상(매핑·항목·룰·표·행·필드·키·케이스)을
#   전수/전부로 "일치·정확·동일·검증"했다고 [x] 한 항목. 분모(M/N)나 산출물 경로가
#   없으면 표본→전체 점프(hollow-PASS) 위험 → 차단 대상.
SET_COVERAGE = re.compile(
    r"(전수|전부|모두|모든|각각|각 ?룰|전체)[^\n]*?"
    r"(매핑|항목|룰|표|행|필드|키|케이스|case|rule|mapping)"
    r"|(매핑|표|목록|리스트)[^\n]*?(일치|정확|동일)"
    r"|일치한다|정확하다"
)
# 분모 명시(M/N, "N개 중 M", "N/N", "M/N 확인") = 표본 아님 → 면제
HAS_DENOM = re.compile(r"\d+\s*/\s*\d+|\d+\s*개?\s*중\s*\d+|\d+\s*분의\s*\d+")
# 실물 산출물 경로(ASCII만): "docs/x.md" 또는 ".py" 같은 확장자.
#   한글 "코드/설정"의 슬래시를 경로로 오인하지 않도록 ASCII로 제한한다.
ARTIFACT_PATH = re.compile(
    r"[A-Za-z0-9_.\-]+[/\\][A-Za-z0-9_.\-]+|\.[A-Za-z0-9]{1,5}\b"
)

CHECKED = re.compile(r"^[ \t]*- \[x\][ \t]+(.*)$", re.IGNORECASE)

# 전수 단언: "전수/전부/전체/모든/빠짐없이" + 완료/커버 동사. 직접 전수명령을 받든
#   스스로 전수라 부르든, 이 [x] 항목이 있으면 모집단을 권위에서 도출했음을
#   증명해야 한다(아래 두 라인). 없으면 wrong-universe(검사-후-모집단) 위험으로 차단.
EXHAUSTIVE_CLAIM = re.compile(
    r"(전수|전부|전체|모든|빠짐없이|남김없이)[^\n]*?"
    r"(완료|마쳤|마침|일치|검증|확인|대조|반영|점검|커버|봤)"
)
# 모집단 등록 라인: 대상 전체를 권위 출처 + 개수 + 증거로 선언했는가.
POPULATION_MARK = re.compile(r"모집단|대상\s*전체|전체\s*대상|population|target\s*set")
POP_EVIDENCE = re.compile(
    r"grep|쿼리|query|registry|레지스트리|REGISTRY|"
    r"[A-Za-z0-9_.\-]+[/\\][A-Za-z0-9_.\-]+|\.[A-Za-z0-9]{1,5}\b"
)
# 음의 공간 증명 라인: 모집단 "밖" 영향원이 0건임을 증명했는가.
NEGATIVE_SPACE = re.compile(
    r"음의\s*공간|모집단\s*밖|밖\s*(영향|항목|경로)|"
    r"(영향원|잔여|residual|외부|누락).*0\s*(건|개)?|"
    r"0\s*(건|개)[^\n]*(밖|외부|누락|잔여)|negative[ -]?space"
)


def is_loose(text: str) -> bool:
    """완료 선언했지만 측정 근거가 전무한 동사형 도달 항목인가."""
    if not PROCESS_VERBS.search(text):
        return False  # 과정 동사 자체가 없으면 대상 아님 (예: "X 생성")
    if HAS_DIGIT.search(text):
        return False
    if HAS_COMPARE.search(text):
        return False
    if HAS_FAILCOND.search(text):
        return False
    if HAS_PATH.search(text):
        return False
    return True


def is_uncovered_setclaim(text: str) -> bool:
    """집합 전수 커버리지를 단언했지만 분모(M/N)도 산출물 경로도 없는 항목."""
    if not SET_COVERAGE.search(text):
        return False
    if HAS_DENOM.search(text):
        return False  # 분모 명시 = 표본 아님
    if ARTIFACT_PATH.search(text):
        return False  # 대조표 등 실물 산출물 경로 있으면 면제
    return True


def main() -> int:
    if len(sys.argv) < 2:
        return 0
    try:
        with open(sys.argv[1], encoding="utf-8") as f:
            lines = f.readlines()
    except OSError:
        return 0  # fail-open

    flagged = []
    setclaims = []
    exhaustive = []
    for raw in lines:
        m = CHECKED.match(raw.rstrip("\n"))
        if not m:
            continue
        text = m.group(1).strip()
        if is_loose(text):
            flagged.append(text)
        elif is_uncovered_setclaim(text):
            setclaims.append(text)
        if EXHAUSTIVE_CLAIM.search(text):
            exhaustive.append(text)

    # 문서 수준: 전수 단언이 하나라도 있으면 모집단 등록 + 음의공간 증명이
    #   contract 어딘가에 반드시 있어야 한다(없으면 wrong-universe 위험).
    unregistered = []
    if exhaustive:
        has_pop = any(
            POPULATION_MARK.search(ln)
            and HAS_DIGIT.search(ln)
            and POP_EVIDENCE.search(ln)
            for ln in lines
        )
        has_neg = any(NEGATIVE_SPACE.search(ln) for ln in lines)
        if not has_pop or not has_neg:
            missing = []
            if not has_pop:
                missing.append("모집단 등록(대상 전체 N+권위출처+증거 grep/경로)")
            if not has_neg:
                missing.append("음의공간 증명(모집단 밖 영향원 0건)")
            unregistered = [(it, missing) for it in exhaustive]

    if not flagged and not setclaims and not unregistered:
        return 0

    if flagged:
        print("측정 불가 항목(수치·비교·실패조건·파일경로 전무 / 검증·분석 동사형):")
        for item in flagged:
            print(f"  - {item}")
    if setclaims:
        print(
            "집합 커버리지 주장인데 분모(M/N)·산출물 경로 없음 (표본→전체 hollow-PASS):"
        )
        for item in setclaims:
            print(f"  - {item}")
    if unregistered:
        miss = unregistered[0][1]
        print(
            "전수 단언인데 모집단 미등록 (wrong-universe 위험 — 검사-후-모집단 날조):"
        )
        for item, _ in unregistered:
            print(f"  - {item}")
        print(f"    누락: {' / '.join(miss)}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
