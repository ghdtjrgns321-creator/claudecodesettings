#!/bin/bash
# Claude Code SessionStart 훅 - 이전 세션 작업 요약을 컨텍스트에 주입
# stdout 출력 → Claude가 자동으로 컨텍스트에 포함

INPUT=$(cat)

# stdin JSON에서 cwd 파싱 (기존 slack 훅과 동일 패턴)
CWD=$(echo "$INPUT" | python -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('cwd', ''))
" 2>/dev/null || echo "")

# 프로젝트명 추출
PROJECT=$(basename "$CWD")
if [ -z "$PROJECT" ]; then
  exit 0
fi

SUMMARY_FILE="/c/Users/ghdtj/.claude/work-summaries/${PROJECT}.md"

# 요약 파일 없으면 조용히 종료 (첫 세션)
if [ ! -f "$SUMMARY_FILE" ]; then
  exit 0
fi

# stdout으로 출력 → Claude 컨텍스트에 자동 주입
echo ""
echo "=============================="
echo "이전 세션 작업 요약: ${PROJECT}"
echo "=============================="
cat "$SUMMARY_FILE"
echo "=============================="
echo "위 요약을 바탕으로 작업을 이어가세요."
echo ""

exit 0
