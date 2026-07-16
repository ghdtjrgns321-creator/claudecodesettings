#!/usr/bin/env python3
"""census_diff — 전수 작업의 완료를 차집합으로 증명한다.

사용:
  python census_diff.py <population.txt> <done.txt>

population.txt: 대상 전체(분모). 반드시 스크립트/쿼리로 생성할 것 — 손으로 쓰지 않는다.
done.txt:       처리 흔적(분자). 항목당 한 줄.

판정:
  누락 0건 → "PASS M/N" 출력, exit 0
  누락 있음 → 누락 항목을 이름으로 전부 출력, exit 1
  population이 비었으면 exit 2 (분모 없는 전수는 성립 불가)

비교는 공백 트림 후 정확 일치. done에만 있는 항목은 경고로만 출력(차단 안 함).
"""

import sys


def load(path: str) -> list[str]:
    with open(path, encoding="utf-8") as f:
        return [ln.strip() for ln in f if ln.strip() and not ln.strip().startswith("#")]


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    pop = load(sys.argv[1])
    done = set(load(sys.argv[2]))

    if not pop:
        print(f"FAIL: 분모가 비어 있음 ({sys.argv[1]}). 전수 판정 불가.")
        return 2

    missing = [item for item in pop if item not in done]
    extra = sorted(done - set(pop))

    n, m = len(pop), len(pop) - len(missing)
    if extra:
        print(f"경고: 분모 밖 항목 {len(extra)}건 (분모가 낡았거나 done이 오염):")
        for item in extra[:20]:
            print(f"  ? {item}")

    if missing:
        print(f"FAIL {m}/{n} — 누락 {len(missing)}건:")
        for item in missing:
            print(f"  ✗ {item}")
        return 1

    print(f"PASS {m}/{n}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
