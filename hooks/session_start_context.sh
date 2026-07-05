#!/usr/bin/env bash
# SessionStart hook — inject git + debugging + in-progress tasks into context.
# Each section is independent; failures fall through.

set -uo pipefail
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

PAYLOAD="$(cat)"

# Lightweight JSON cwd extraction (avoids python cold-start).
# Matches "cwd": "...value...". Tolerates whitespace and JSON-escaped backslashes.
CWD=""
if [[ "$PAYLOAD" =~ \"cwd\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]]; then
  CWD="${BASH_REMATCH[1]}"
  # Un-escape JSON backslashes (\\ → \) — Windows paths come through as C:\\Users\\...
  CWD="${CWD//\\\\/\\}"
fi

if [[ -z "$CWD" ]]; then
  CWD="$PWD"
fi

cd "$CWD" 2>/dev/null || true

GIT='git -c core.quotepath=false'

BODY="## Session Context"$'\n\n'

# --- Git section -------------------------------------------------------------
if $GIT rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch="$($GIT rev-parse --abbrev-ref HEAD 2>/dev/null)"
  commits="$($GIT --no-pager log -5 --oneline --no-decorate 2>/dev/null)"
  status_raw="$($GIT --no-pager status --short 2>/dev/null || true)"

  BODY+="### Git"$'\n'
  BODY+="- Branch: ${branch:-unknown}"$'\n'

  if [[ -n "$commits" ]]; then
    BODY+="- Last 5 commits:"$'\n'
    while IFS= read -r line; do
      BODY+="    $line"$'\n'
    done <<< "$commits"
  fi

  if [[ -z "$status_raw" ]]; then
    BODY+="- Working tree: clean"$'\n'
  else
    total="$(printf '%s\n' "$status_raw" | grep -c '^' || echo 0)"
    BODY+="- Working tree:"$'\n'
    if [[ "$total" -le 20 ]]; then
      while IFS= read -r line; do
        BODY+="    $line"$'\n'
      done <<< "$status_raw"
    else
      head20="$(printf '%s\n' "$status_raw" | head -20)"
      while IFS= read -r line; do
        BODY+="    $line"$'\n'
      done <<< "$head20"
      BODY+="    ... $((total - 20)) more"$'\n'
    fi
  fi
  BODY+=$'\n'
else
  BODY+="Git 섹션 생략, working dir: ${CWD}"$'\n'
  printf '%s' "$BODY"
  exit 0
fi

# --- Recent debugging --------------------------------------------------------
DEBUG_FILE=""
for cand in docs/debugging.md docs/DEBUGGING.md docs/Debugging.md; do
  if [[ -f "$cand" ]]; then DEBUG_FILE="$cand"; break; fi
done

if [[ -n "$DEBUG_FILE" ]]; then
  tail_30="$(tail -n 30 "$DEBUG_FILE" 2>/dev/null || true)"
  if [[ -n "$tail_30" ]]; then
    BODY+="### Recent debugging (${DEBUG_FILE}, last 30 lines)"$'\n'
    BODY+='```'$'\n'
    BODY+="${tail_30}"$'\n'
    BODY+='```'$'\n\n'
  fi
fi

# --- In-progress tasks -------------------------------------------------------
TASKS_FILE=""
for cand in docs/NEW_TASKS.MD docs/NEW_TASKS.md docs/TASKS.md docs/Tasks.md docs/tasks.md; do
  if [[ -f "$cand" ]]; then TASKS_FILE="$cand"; break; fi
done

if [[ -n "$TASKS_FILE" ]]; then
  # Markers: "진행 중", "in progress" (case-insensitive), 🔄, ⏳
  matches="$(grep -niE '진행 중|in[[:space:]]+progress|🔄|⏳' "$TASKS_FILE" 2>/dev/null | head -15 || true)"
  if [[ -n "$matches" ]]; then
    BODY+="### In-progress tasks (${TASKS_FILE})"$'\n'
    BODY+='```'$'\n'
    BODY+="${matches}"$'\n'
    BODY+='```'$'\n\n'
  fi
fi

# --- 4000-char cap (UTF-8 safe, cut at last newline) -------------------------
# Fast path: ${#BODY} counts bytes here; if bytes < 4000 then chars < 4000 too.
if [[ ${#BODY} -lt 4000 ]]; then
  printf '%s' "$BODY"
else
  printf '%s' "$BODY" | python -c '
import sys
text = sys.stdin.read()
LIMIT = 4000
if len(text) <= LIMIT:
    sys.stdout.write(text)
else:
    head = text[:LIMIT]
    cut = head.rfind("\n")
    if cut < int(LIMIT * 0.85):
        cut = LIMIT
    sys.stdout.write(text[:cut])
    sys.stdout.write("\n\n*(컨텍스트 4000자 캡으로 일부 생략)*\n")
'
fi

exit 0
