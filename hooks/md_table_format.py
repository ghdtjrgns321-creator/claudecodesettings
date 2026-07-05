# -*- coding: utf-8 -*-
"""PostToolUse 훅: GFM 마크다운 표 컬럼 폭 자동 정렬 (.md 전용).

- 한글/전각 문자 폭을 2칸으로 반영해 소스에서 `|` 위치를 정렬(CLAUDE.md §6).
- 코드펜스(``` 또는 ~~~) 내부 표는 건드리지 않는다.
- 셀 수가 부족한 행은 빈칸으로 패딩(데이터 손실 0). 정렬 마커(:)는 보존.
- utf-8 strict로만 read/write 하고, 디코딩 실패 시 파일을 건드리지 않는다
  (한글 인코딩 라운드트립 손상 방지 — CLAUDE.md §4).
"""

from __future__ import annotations

import json
import re
import sys
import unicodedata
from pathlib import Path

MAX_BYTES = 5 * 1024 * 1024  # 5 MB
FENCE_RE = re.compile(r"^\s*(```|~~~)")
SEP_CELL_RE = re.compile(r"^\s*:?-{1,}:?\s*$")  # 구분선 셀: ---, :--:, ---: 등


def cell_width(text: str) -> int:
    """전각(한글·CJK·이모지)은 2칸, 그 외 1칸으로 표시 폭 계산."""
    width = 0
    for ch in text:
        width += 2 if unicodedata.east_asian_width(ch) in ("W", "F") else 1
    return width


def split_row(line: str) -> list[str]:
    """행을 셀로 분리. 앞뒤 `|` 제거 후 이스케이프되지 않은 `|`로 split."""
    s = line.strip()
    if s.startswith("|"):
        s = s[1:]
    if s.endswith("|"):
        s = s[:-1]
    return [p.strip() for p in re.split(r"(?<!\\)\|", s)]


def is_table_row(line: str) -> bool:
    # 거짓양성 방지: `|`로 시작하는 행만 표로 간주
    return "|" in line and line.lstrip().startswith("|")


def is_sep_row(line: str) -> bool:
    cells = split_row(line)
    return len(cells) >= 1 and all(SEP_CELL_RE.match(c) for c in cells)


def parse_align(cell: str) -> str:
    c = cell.strip()
    left, right = c.startswith(":"), c.endswith(":")
    if left and right:
        return "center"
    if right:
        return "right"
    if left:
        return "left"
    return "none"


def build_sep(width: int, align: str) -> str:
    width = max(width, 3)
    if align == "center":
        return ":" + "-" * (width - 2) + ":"
    if align == "right":
        return "-" * (width - 1) + ":"
    if align == "left":
        return ":" + "-" * (width - 1)
    return "-" * width


def pad(text: str, width: int, align: str) -> str:
    diff = width - cell_width(text)
    if diff <= 0:
        return text
    if align == "right":
        return " " * diff + text
    if align == "center":
        left = diff // 2
        return " " * left + text + " " * (diff - left)
    return text + " " * diff  # left / none


def format_table(block: list[str], indent: str) -> list[str]:
    grid = [split_row(line) for line in block]
    ncol = max(len(r) for r in grid)
    for r in grid:
        r.extend([""] * (ncol - len(r)))

    sep_idx = 1
    aligns = [parse_align(c) for c in grid[sep_idx]]
    aligns.extend(["none"] * (ncol - len(aligns)))

    widths = [3] * ncol
    for i, r in enumerate(grid):
        if i == sep_idx:
            continue
        for j, c in enumerate(r):
            widths[j] = max(widths[j], cell_width(c))

    out = []
    for i, r in enumerate(grid):
        if i == sep_idx:
            cells = [build_sep(widths[j], aligns[j]) for j in range(ncol)]
        else:
            cells = [pad(r[j], widths[j], aligns[j]) for j in range(ncol)]
        out.append(indent + "| " + " | ".join(cells) + " |")
    return out


def process(text: str) -> tuple[str, bool]:
    lines = text.split("\n")
    out: list[str] = []
    in_fence = False
    changed = False
    i, n = 0, len(lines)

    while i < n:
        line = lines[i]
        if FENCE_RE.match(line):
            in_fence = not in_fence
            out.append(line)
            i += 1
            continue
        if not in_fence and is_table_row(line):
            j = i
            block = []
            while j < n and is_table_row(lines[j]) and not FENCE_RE.match(lines[j]):
                block.append(lines[j])
                j += 1
            # 유효 GFM 표: 2행 이상 + 2번째 행이 구분선
            if len(block) >= 2 and is_sep_row(block[1]):
                indent = block[0][: len(block[0]) - len(block[0].lstrip())]
                formatted = format_table(block, indent)
                if formatted != block:
                    changed = True
                out.extend(formatted)
            else:
                out.extend(block)
            i = j
            continue
        out.append(line)
        i += 1

    return "\n".join(out), changed


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return
    file_path = (payload.get("tool_input") or {}).get("file_path", "") or ""
    if not file_path:
        return

    path = Path(file_path)
    if path.suffix.lower() != ".md" or not path.is_file():
        return
    try:
        if path.stat().st_size > MAX_BYTES:
            return
    except OSError:
        return

    try:
        raw = path.read_bytes().decode("utf-8", errors="strict")
    except UnicodeDecodeError:
        return  # 인코딩 손상 의심 — 건드리지 않음

    crlf = raw.count("\r\n")
    nl = "\r\n" if crlf >= (raw.count("\n") - crlf) else "\n"
    normalized = raw.replace("\r\n", "\n")

    new_body, changed = process(normalized)
    if not changed:
        return

    final = new_body.replace("\n", nl)
    path.write_bytes(final.encode("utf-8"))
    sys.stderr.write(f"[md-table] {path.name}: 표 컬럼 폭 자동 정렬 적용\n")


if __name__ == "__main__":
    main()
