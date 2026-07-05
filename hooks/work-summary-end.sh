#!/bin/bash
# Claude Code Stop 훅 - 트랜스크립트를 직접 파싱하여 요약 파일 작성
#
# 기존 방식(exit 2)의 문제:
#   - exit 2로 Claude에게 Write 요청 → Write 도구가 allow 목록에 없어 승인 필요
#   - 세션 종료 타이밍에 사용자가 없으면 파일 작성 실패
#
# 새 방식:
#   - Python으로 transcript JSONL 직접 파싱 → 변경 파일 목록 추출
#   - bash 스크립트가 직접 파일을 작성 (Claude 의존 없음)
#   - 기존 요약이 있으면 '현재 작업 내용' 섹션만 갱신, 나머지는 보존

INPUT=$(cat)

# stop_hook_active가 True면 이미 처리 완료 → 즉시 종료 (안전 장치)
STOP_ACTIVE=$(echo "$INPUT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('stop_hook_active', False))
" 2>/dev/null || echo "False")

if [ "$STOP_ACTIVE" = "True" ]; then
    exit 0
fi

# stdin JSON에서 필요한 값 추출
CWD=$(echo "$INPUT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('cwd', ''))
" 2>/dev/null || echo "")

TRANSCRIPT_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('transcript_path', ''))
" 2>/dev/null || echo "")

PROJECT=$(basename "$CWD")

# 프로젝트명이 없으면 조용히 종료
if [ -z "$PROJECT" ] || [ "$PROJECT" = "." ]; then
    exit 0
fi

SUMMARY_DIR="/c/Users/ghdtj/.claude/work-summaries"
SUMMARY_FILE="${SUMMARY_DIR}/${PROJECT}.md"

mkdir -p "$SUMMARY_DIR"

# Python으로 트랜스크립트 파싱 + 요약 파일 직접 작성
python3 << PYEOF
import json, os, re, sys
from datetime import datetime
from pathlib import Path

project       = """$PROJECT"""
cwd           = """$CWD"""
transcript    = """$TRANSCRIPT_PATH"""
summary_file  = """$SUMMARY_FILE"""
today         = datetime.now().strftime("%Y-%m-%d %H:%M")

# ── 트랜스크립트에서 변경 파일 목록 추출 ───────────────────────────────
modified_files = []

if transcript and os.path.exists(transcript):
    try:
        with open(transcript, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    entry = json.loads(line)
                    # 중첩 구조 처리 (message 키가 있는 경우)
                    msg     = entry.get("message", entry)
                    content = msg.get("content", [])

                    if not isinstance(content, list):
                        continue

                    for block in content:
                        if not isinstance(block, dict):
                            continue
                        # Write/Edit 도구 사용 → 파일 경로 수집
                        if block.get("type") == "tool_use" and block.get("name") in ("Write", "Edit"):
                            fp = block.get("input", {}).get("file_path", "")
                            if fp and fp not in modified_files:
                                modified_files.append(fp)
                except Exception:
                    continue
    except Exception:
        pass

# ── 기존 요약 읽기 ──────────────────────────────────────────────────────
existing = ""
if os.path.exists(summary_file):
    with open(summary_file, "r", encoding="utf-8") as f:
        existing = f.read()

# ── 현재 작업 내용 섹션 구성 ────────────────────────────────────────────
if modified_files:
    files_list = "\n".join(f"- \`{f}\`" for f in modified_files[:15])
    current_section = f"""## 현재 작업 내용
*(세션 종료 시 자동 기록 — {today})*

수정/생성된 파일:
{files_list}"""
else:
    current_section = f"""## 현재 작업 내용
*(세션 종료 시 자동 기록 — {today})*

파일 변경 없음"""

# ── 기존 요약 업데이트 or 신규 작성 ────────────────────────────────────
if existing:
    # 최종 업데이트 날짜 갱신
    updated = re.sub(r"> 최종 업데이트:.*", f"> 최종 업데이트: {today}", existing)

    # '현재 작업 내용' 섹션 교체 (섹션이 없으면 파일 끝에 추가)
    if "## 현재 작업 내용" in updated:
        updated = re.sub(
            r"## 현재 작업 내용.*?(?=\n## |\Z)",
            current_section + "\n\n",
            updated,
            flags=re.DOTALL,
        )
    else:
        updated = updated.rstrip() + "\n\n" + current_section + "\n"

    result = updated
else:
    # 요약 파일이 없는 첫 세션 — 최소 골격 생성
    result = f"""# 프로젝트 요약: {project}

> 최종 업데이트: {today}

## 프로젝트 목적
(다음 세션에서 Claude가 업데이트)

## 완료된 작업
- (다음 세션에서 Claude가 업데이트)

{current_section}

## 다음 할 일
- [ ] (다음 세션에서 Claude가 업데이트)

## 중요 메모
- 자동 생성된 파일입니다. 다음 세션에서 Claude가 내용을 보완합니다.
"""

with open(summary_file, "w", encoding="utf-8") as f:
    f.write(result)

print(f"[work-summary] saved → {summary_file}")
if modified_files:
    print(f"[work-summary] files: {', '.join(Path(p).name for p in modified_files[:5])}")
PYEOF

exit 0
