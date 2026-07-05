#!/usr/bin/env bash
# 사용법: set-session-name.sh <session_id> <name>
# Claude Code 세션에 커스텀 이름을 부여하는 헬퍼

NAMES_FILE="$HOME/.claude/session-names.json"
SESSION_ID="$1"
NAME="$2"

if [ -z "$SESSION_ID" ] || [ -z "$NAME" ]; then
    echo "Usage: set-session-name.sh <session_id> <name>"
    exit 1
fi

# 파일이 없으면 생성
if [ ! -f "$NAMES_FILE" ]; then
    echo "{}" > "$NAMES_FILE"
fi

# python으로 JSON 업데이트 (jq 없이도 동작)
python3 -c "
import json, sys
with open('$NAMES_FILE', 'r') as f:
    data = json.load(f)
data['$SESSION_ID'] = '$NAME'
with open('$NAMES_FILE', 'w') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
print(f'Session named: $NAME')
"
