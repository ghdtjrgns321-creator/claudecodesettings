#!/usr/bin/env python
# PostToolUse(Write|Edit) hook — 소스에 박힌 연도/긴ID/거대상수를 경고(차단 안 함). §3.
# 설계: ~/.claude/docs/instruction-gate-design.md §5
import sys
import json
import re
import os

EXTS = (
    ".py",
    ".js",
    ".ts",
    ".tsx",
    ".jsx",
    ".go",
    ".rs",
    ".java",
    ".rb",
    ".php",
    ".c",
    ".cpp",
    ".sh",
)
SKIP = (
    "/test",
    "/tests",
    "/__tests__",
    "/.claude",
    "/config",
    "/migrations",
    "/fixtures",
)

PAT_YEAR = re.compile(r"\b(?:19|20)\d{2}\b")
PAT_ID = re.compile(r"\b\d{6,}\b")  # 긴 식별자 / 6자리+ 상수
PAT_EXP = re.compile(r"\b\d+(?:_\d+)*e\d+\b", re.I)  # 1e8 등 지수 표기


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        return 0
    ti = data.get("tool_input", {}) or {}
    path = ti.get("file_path") or ti.get("path") or ""
    text = ti.get("content")
    if text is None:
        text = ti.get("new_string") or ""
    if not path or not text:
        return 0

    p = path.replace("\\", "/")
    low = p.lower()

    # .nolint 스위치 (거대숫자가 정상인 프로젝트는 끔)
    cwd = (data.get("cwd") or "").replace("\\", "/")
    for base in (cwd, os.path.dirname(p)):
        if base and os.path.isfile(os.path.join(base, ".claude", "state", ".nolint")):
            return 0

    if not low.endswith(EXTS):
        return 0
    if any(s in low for s in SKIP):
        return 0

    hits = []
    for i, line in enumerate(text.splitlines(), 1):
        code = line.split("#", 1)[0].split("//", 1)[0]  # 주석 제거
        if not code.strip():
            continue
        found = {}
        for m in PAT_YEAR.findall(code):
            found[m] = "연도"
        for m in PAT_ID.findall(code):
            found.setdefault(m, "긴ID/거대상수")
        for m in PAT_EXP.findall(code):
            found[m] = "거대상수"
        for val, kind in found.items():
            hits.append((i, val, kind))

    if not hits:
        return 0

    lines = [f"  L{i}: {val} ({kind})" for i, val, kind in hits[:12]]
    extra = "" if len(hits) <= 12 else f"\n  ... 외 {len(hits) - 12}건"
    msg = (
        "⚠ 리터럴 점검(§3): "
        + p
        + "\n"
        + "\n".join(lines)
        + extra
        + "\n이 값이 계산을 구동(분기·임계·대상선정)하면 데이터·인자·config로 빼라. 단순 상수면 무시."
    )
    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "PostToolUse",
                    "additionalContext": msg,
                }
            }
        )
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
