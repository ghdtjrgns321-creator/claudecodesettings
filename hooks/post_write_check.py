# -*- coding: utf-8 -*-
"""PostToolUse hook for Write/Edit.

1. Mojibake guard (hard fail, exit 2) — detects Korean-text encoding damage
   from PowerShell round-trips, cp949↔utf-8 mismatches, etc.
2. Ruff auto-format/fix for .py (soft fail, exit 0 + stderr warning).
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

MAX_BYTES = 5 * 1024 * 1024  # 5 MB

TEXT_EXTS = {
    ".py", ".md", ".json", ".yaml", ".yml", ".toml",
    ".txt", ".ini", ".cfg", ".sh", ".ps1", ".sql",
}
BINARY_EXTS = {
    ".png", ".jpg", ".jpeg", ".gif", ".webp", ".bmp", ".ico",
    ".duckdb", ".parquet", ".xlsx", ".xls", ".pdf",
    ".zip", ".gz", ".tar", ".7z", ".rar",
    ".exe", ".dll", ".so", ".dylib",
    ".db", ".sqlite", ".sqlite3",
}

# cp949 → utf-8 mojibake signatures (common Korean strings reinterpreted)
CP949_MOJI_TOKENS = ["â€", "Ã©", "ì„", "í•˜", "â–", "ë‹ˆ", "êµ¬"]

JAMO_SOLO_RE = re.compile(r"[ㄱ-ㆎ]")        # ㄱ-ㅎ, ㅏ-ㅣ
HANGUL_SYL_RE = re.compile(r"[가-힣]")       # 가-힣


def emit(line: str) -> None:
    sys.stderr.write(line + "\n")


def fail(line: str) -> None:
    emit(line)
    sys.exit(2)


def extract_file_path() -> str:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return ""
    tool_input = payload.get("tool_input") or {}
    return tool_input.get("file_path", "") or ""


def check_mojibake(path: Path) -> None:
    """Read file as strict UTF-8; on failure or mojibake signatures, hard-fail."""
    try:
        text = path.read_bytes().decode("utf-8", errors="strict")
    except UnicodeDecodeError as exc:
        fail(
            f"[mojibake guard] {path}: UTF-8 디코딩 실패 ({exc.reason} @ byte {exc.start}). "
            "PowerShell Set-Content/Out-File 사용 금지."
        )

    # 1. Replacement character — always a smoking gun
    ufffd_count = text.count("�")
    if ufffd_count >= 1:
        fail(
            f"[mojibake guard] {path}: U+FFFD {ufffd_count}개 감지. "
            "인코딩 손상 의심. PowerShell Set-Content/Out-File 사용 금지."
        )

    # 2. cp949→utf-8 mojibake signature tokens
    moji_hits = sum(1 for tok in CP949_MOJI_TOKENS if tok in text)
    if moji_hits >= 2:
        which = [tok for tok in CP949_MOJI_TOKENS if tok in text]
        fail(
            f"[mojibake guard] {path}: cp949→utf-8 깨짐 시그니처 {moji_hits}개 "
            f"({', '.join(which)}). PowerShell 라운드트립 의심."
        )

    # 3. Solo-jamo over-representation (real Korean text is >95% precomposed syllables)
    jamo = len(JAMO_SOLO_RE.findall(text))
    syl = len(HANGUL_SYL_RE.findall(text))
    total = jamo + syl
    if total >= 20 and (jamo / total) > 0.30:
        pct = 100 * jamo / total
        fail(
            f"[mojibake guard] {path}: 한글 자모 단독 비율 {pct:.0f}% "
            f"(자모 {jamo} / 음절 {syl}, 임계 30%). 인코딩 손상 의심."
        )


def invoke_ruff(args: list[str]) -> tuple[int, str, str, str]:
    """Try uv → uvx → python -m. Returns (rc, stdout, stderr, backend_used)."""
    chains = [
        (["uv", "run", "--no-project", "--with", "ruff", "ruff", *args], "uv-run"),
        (["uvx", "ruff", *args], "uvx"),
        (["python", "-m", "ruff", *args], "python-m"),
    ]
    last_err = ""
    for cmd, label in chains:
        try:
            proc = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=15,
                encoding="utf-8",
                errors="replace",
            )
            return proc.returncode, proc.stdout, proc.stderr, label
        except FileNotFoundError:
            last_err = f"binary missing: {cmd[0]}"
        except subprocess.TimeoutExpired:
            last_err = f"timeout: {cmd[0]}"
        except Exception as e:  # pragma: no cover  (defensive)
            last_err = f"{cmd[0]} error: {e}"
    return 127, "", last_err, "none"


def maybe_run_ruff(path: Path) -> None:
    if path.suffix != ".py":
        return

    rc, _out, err, backend = invoke_ruff(["format", "--quiet", str(path)])
    if rc != 0:
        emit(
            f"[ruff format] {path.name}: rc={rc} backend={backend} "
            f"{(err or '').strip()[:240]}"
        )
        return  # do not run check on a file ruff format couldn't process

    # F401(미사용 import) 자동삭제 비활성: import를 먼저 넣고 사용처를 다음 편집에서 넣는 사이에
    # ruff가 "미사용"으로 지워버리는 문제 방지. F401은 경고로는 계속 보고된다(--unfixable).
    rc, out, err, backend = invoke_ruff(
        ["check", "--fix", "--unfixable", "F401", "--quiet", str(path)]
    )
    if rc == 0:
        return
    # rc=1 → unfixable lint errors; surface but don't block
    msg = (out or err or "").strip()[:480]
    emit(f"[ruff check] {path.name}: unfixable issues remain (backend={backend})\n{msg}")


def main() -> None:
    file_path = extract_file_path()
    if not file_path:
        return

    path = Path(file_path)
    if not path.exists() or not path.is_file():
        return

    suffix = path.suffix.lower()
    if suffix in BINARY_EXTS:
        return
    if suffix not in TEXT_EXTS:
        return  # only inspect known text types

    try:
        size = path.stat().st_size
    except OSError:
        return
    if size > MAX_BYTES:
        return

    check_mojibake(path)        # may exit(2)
    maybe_run_ruff(path)        # always best-effort


if __name__ == "__main__":
    main()
