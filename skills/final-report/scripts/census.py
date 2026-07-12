#!/usr/bin/env python3
"""FINAL-REPORT 전수 센서스 — 인벤토리 추출과 커버리지 검증.

사용법:
  python census.py inventory <project_root> [--out inventory.json] [--exclude DIR ...]
  python census.py verify    <project_root> <coverage_md> [--exclude DIR ...]

inventory: 보고서가 정독해야 할 파일 전수 목록(분모 N)을 기계적으로 고정한다.
verify   : 커버리지 부록(md)의 백틱 경로가 인벤토리 N개를 전부 담는지 대조. 누락 시 exit 1.
"""

import argparse
import fnmatch
import json
import re
import subprocess
import sys
from pathlib import Path

# 정독 분모 N에 들어가는 확장자 (kind별)
READ_EXTS = {
    "code": {
        ".py",
        ".js",
        ".ts",
        ".tsx",
        ".jsx",
        ".mjs",
        ".cjs",
        ".java",
        ".go",
        ".rs",
        ".c",
        ".cc",
        ".cpp",
        ".h",
        ".hpp",
        ".cs",
        ".rb",
        ".php",
        ".swift",
        ".kt",
        ".sh",
        ".ps1",
        ".bat",
        ".sql",
        ".r",
        ".lua",
    },
    "doc": {".md", ".rst"},
    "text": {".txt"},  # 데이터성 텍스트 — config 수치 왜곡 방지 위해 분리
    "config": {
        ".json",
        ".yaml",
        ".yml",
        ".toml",
        ".ini",
        ".cfg",
        ".html",
        ".css",
    },
}
# 확장자로 못 잡는 정독 대상 파일명
READ_NAMES = {
    "dockerfile",
    "makefile",
    "procfile",
    ".gitignore",
    ".dockerignore",
    ".env.example",
}
# 목록만 남기고 정독은 면제 (데이터·바이너리·잠금)
LIST_ONLY_EXTS = {
    ".csv",
    ".tsv",
    ".jsonl",
    ".parquet",
    ".pkl",
    ".db",
    ".sqlite",
    ".png",
    ".jpg",
    ".jpeg",
    ".gif",
    ".svg",
    ".ico",
    ".pdf",
    ".xlsx",
    ".woff",
    ".woff2",
    ".ttf",
    ".mp4",
    ".zip",
    ".lock",
    ".pyc",
}
LIST_ONLY_NAMES = {
    "package-lock.json",
    "yarn.lock",
    "uv.lock",
    "poetry.lock",
    "cargo.lock",
}
# 순회 자체를 건너뛰는 디렉토리 (FINAL-REPORT는 산출물이므로 자기 자신 제외)
EXCLUDE_DIRS = {
    ".git",
    ".hg",
    ".svn",
    "node_modules",
    ".venv",
    "venv",
    "__pycache__",
    ".pytest_cache",
    ".mypy_cache",
    ".ruff_cache",
    ".tox",
    ".cache",
    "dist",
    "build",
    ".next",
    ".nuxt",
    "target",
    "htmlcov",
    ".idea",
    ".vscode",
    ".claude",
    ".codex",
    ".superpowers",
    "final-report",
}
EXCLUDE_FILES = {".env"}  # 시크릿 — 목록에도 올리지 않는다
LARGE_BYTES = 200_000  # 이 크기 초과는 large=True (구조 정독 허용 표시)


def classify(p: Path) -> str | None:
    """파일을 read-kind("code"|"doc"|"text"|"config") / "list_only" / None(완전 제외)으로 분류."""
    name = p.name.lower()
    if name in EXCLUDE_FILES:
        return None
    if name in LIST_ONLY_NAMES or p.suffix.lower() in LIST_ONLY_EXTS:
        return "list_only"
    if name in READ_NAMES:
        return "config"
    for kind, exts in READ_EXTS.items():
        if p.suffix.lower() in exts:
            return kind
    return "list_only"  # 미분류 확장자도 목록에는 남긴다 (조용한 누락 금지)


def git_candidates(root: Path) -> list[Path] | None:
    """git 저장소면 추적+미추적(gitignore 제외) 파일 목록을 반환. 아니면 None."""
    if not (root / ".git").exists():
        return None
    try:
        out = subprocess.run(
            [
                "git",
                "-C",
                str(root),
                "ls-files",
                "--cached",
                "--others",
                "--exclude-standard",
            ],
            capture_output=True,
            text=True,
            encoding="utf-8",
            check=True,
        )
    except (OSError, subprocess.CalledProcessError):
        return None
    return [root / line for line in out.stdout.splitlines() if line.strip()]


def inventory(root: Path, extra_excludes: set[str], no_git: bool = False) -> dict:
    """분모 N 고정. git 저장소는 git ls-files 기준(생성 데이터가 gitignore로 걸러짐),
    비-git만 전체 순회로 폴백."""
    skip = EXCLUDE_DIRS | {d.lower() for d in extra_excludes}
    candidates = None if no_git else git_candidates(root)
    mode = "walk" if candidates is None else "git"
    if candidates is None:
        candidates = sorted(root.rglob("*"))
    read_files, list_only = [], []
    excluded_dirs_hit = {}  # 기본·추가 제외로 걸러진 파일 수 (조용한 제외 방지용 집계)
    for p in candidates:
        if not p.is_file():
            continue
        rel = p.relative_to(root)
        hit = next((part for part in rel.parts[:-1] if part.lower() in skip), None)
        if hit:
            excluded_dirs_hit[hit] = excluded_dirs_hit.get(hit, 0) + 1
            continue
        kind = classify(p)
        if kind is None:
            continue
        size = p.stat().st_size
        entry = {
            "path": rel.as_posix(),
            "kind": kind,
            "bytes": size,
            "large": size > LARGE_BYTES,
        }
        (list_only if kind == "list_only" else read_files).append(entry)
    return {
        "root": str(root),
        "mode": mode,
        "n_read": len(read_files),
        "n_list_only": len(list_only),
        "excluded_dirs": excluded_dirs_hit,
        "read_files": read_files,
        "list_only_files": list_only,
    }


def cmd_inventory(args) -> int:
    inv = inventory(args.root, set(args.exclude), args.no_git)
    by_kind = {}
    for f in inv["read_files"]:
        by_kind[f["kind"]] = by_kind.get(f["kind"], 0) + 1
    print(f"수집 모드 = {inv['mode']}")
    if inv["excluded_dirs"]:
        detail = ", ".join(f"{d} {n}" for d, n in sorted(inv["excluded_dirs"].items()))
        print(
            f"제외 디렉토리로 걸러진 파일 = {sum(inv['excluded_dirs'].values())}  ({detail})"
        )
    print(
        f"정독 분모 N = {inv['n_read']}  ({', '.join(f'{k} {v}' for k, v in sorted(by_kind.items()))})"
    )
    print(f"목록만(정독 면제) = {inv['n_list_only']}")
    if args.out:
        Path(args.out).write_text(
            json.dumps(inv, ensure_ascii=False, indent=1), encoding="utf-8"
        )
        print(f"인벤토리 저장: {args.out}")
    else:
        print(json.dumps(inv, ensure_ascii=False, indent=1))
    return 0


def cmd_verify(args) -> int:
    inv = inventory(args.root, set(args.exclude), args.no_git)
    text = Path(args.coverage_md).read_text(encoding="utf-8")
    # 코드펜스 내부는 경로 파싱에서 제외 — 펜스 백틱이 인라인 백틱 짝을 깨뜨리는 것 방지
    text = re.sub(r"```.*?```", "", text, flags=re.DOTALL)
    tokens = {
        m.replace("\\", "/").lstrip("./").casefold()
        for m in re.findall(r"`([^`]+)`", text)
    }
    globs = {t for t in tokens if "*" in t}  # 디렉토리 단위 커버: `data/**` 표기
    exact = tokens - globs
    required = {f["path"]: f["path"].casefold() for f in inv["read_files"]}
    missing = [
        orig
        for orig, folded in required.items()
        if folded not in exact and not any(fnmatch.fnmatch(folded, g) for g in globs)
    ]
    print(
        f"인벤토리 N = {len(required)}, 커버리지 표 경로 = {len(exact)} + 글롭 {len(globs)}"
    )
    if missing:
        print(f"FAIL — 누락 {len(missing)}/{len(required)}건:")
        for m in missing:
            print(f"  - {m}")
        return 1
    print(f"PASS — 전수 커버리지 {len(required)}/{len(required)}")
    return 0


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")  # Windows cp949 콘솔 대비
    ap = argparse.ArgumentParser(description=__doc__)
    sub = ap.add_subparsers(dest="cmd", required=True)
    p_inv = sub.add_parser("inventory")
    p_inv.add_argument("root", type=Path)
    p_inv.add_argument("--out")
    p_inv.add_argument("--exclude", action="append", default=[])
    p_inv.add_argument(
        "--no-git", action="store_true", help="git 저장소여도 전체 순회로 강제"
    )
    p_ver = sub.add_parser("verify")
    p_ver.add_argument("root", type=Path)
    p_ver.add_argument("coverage_md")
    p_ver.add_argument("--exclude", action="append", default=[])
    p_ver.add_argument(
        "--no-git", action="store_true", help="git 저장소여도 전체 순회로 강제"
    )
    args = ap.parse_args()
    if not args.root.is_dir():
        print(f"에러: 디렉토리 아님 — {args.root}")
        return 2
    return cmd_inventory(args) if args.cmd == "inventory" else cmd_verify(args)


if __name__ == "__main__":
    sys.exit(main())
