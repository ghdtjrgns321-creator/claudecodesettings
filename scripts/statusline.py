#!/usr/bin/env python3
# Claude Code 상태표시줄 스크립트 (Python 버전)
# /rename으로 설정한 session_name을 stdin JSON에서 직접 읽어 표시

import io
import json
import subprocess
import sys

# Windows 환경에서 stdout UTF-8 강제 설정
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")


def get_git_branch(cwd):
    """현재 디렉토리의 git 브랜치를 반환 (실패하면 빈 문자열)"""
    try:
        result = subprocess.run(
            ["git", "--no-optional-locks", "branch", "--show-current"],
            capture_output=True,
            text=True,
            cwd=cwd,
            timeout=3,
        )
        return result.stdout.strip()
    except Exception:
        return ""


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    cwd = data.get("workspace", {}).get("current_dir", "")
    model = data.get("model", {}).get("display_name", "Claude")
    used_pct = data.get("context_window", {}).get("used_percentage") or 0
    used_rounded = int(round(float(used_pct)))

    # 세션 사용량 (5시간 한도 대비 %, /usage와 동일 지표)
    rate_limits = data.get("rate_limits", {})
    session_pct = rate_limits.get("five_hour", {}).get("used_percentage") or 0
    session_rounded = int(round(float(session_pct)))
    weekly_pct = rate_limits.get("seven_day", {}).get("used_percentage") or 0
    weekly_rounded = int(round(float(weekly_pct)))

    # /rename 명령으로 설정한 세션 이름은 stdin JSON의 session_name 필드에 직접 제공됨
    session_name = data.get("session_name", "")

    # ANSI 색상 코드
    CYAN = "\033[36m"
    PURPLE = "\033[35m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    WHITE = "\033[97m"
    RED = "\033[31m"
    RESET = "\033[0m"

    # 세션 이름 있으면 우선 표시, 없으면 전체 경로
    if session_name:
        display_name = f"{WHITE}{session_name}{RESET}"
    else:
        display_name = f"{CYAN}{cwd}{RESET}"

    # Git 브랜치
    git_info = ""
    if cwd:
        branch = get_git_branch(cwd)
        if branch:
            git_info = f" on {PURPLE}{branch}{RESET}"

    # 컨텍스트 사용량
    ctx_info = f" {YELLOW}[ctx: {used_rounded}%]{RESET}"

    # 세션 사용률 (5시간 한도 / 7일 한도)
    usage_info = f" {RED}[session: {session_rounded}% | week: {weekly_rounded}%]{RESET}"

    output = f"{display_name}{git_info} {GREEN}[{model}]{RESET}{ctx_info}{usage_info}"
    sys.stdout.write(output)
    sys.stdout.flush()


if __name__ == "__main__":
    main()
