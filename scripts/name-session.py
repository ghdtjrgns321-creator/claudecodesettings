#!/usr/bin/env python3
"""
대화 중에 호출하여 현재 세션에 이름을 부여하는 스크립트.
사용법: python3 name-session.py <session_id> <이름>
"""
import json
import sys
import os

NAMES_FILE = os.path.expanduser("~/.claude/session-names.json")

def main():
    if len(sys.argv) < 3:
        print("Usage: name-session.py <session_id> <name>")
        sys.exit(1)

    session_id = sys.argv[1]
    name = " ".join(sys.argv[2:])  # 공백 포함 이름 지원

    # 기존 매핑 읽기
    try:
        with open(NAMES_FILE, "r", encoding="utf-8") as f:
            names = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        names = {}

    names[session_id] = name

    with open(NAMES_FILE, "w", encoding="utf-8") as f:
        json.dump(names, f, ensure_ascii=False, indent=2)

    print(f"Session '{session_id[:8]}...' named → {name}")

if __name__ == "__main__":
    main()
