#!/usr/bin/env bash
# PreToolUse guard for the Bash tool.
# Reads the hook JSON from stdin, extracts tool_input.command + cwd, and blocks
# destructive patterns (exit 2 = block, stderr is shown to Claude).
set -euo pipefail
shopt -s nocasematch   # PowerShell commands are case-insensitive

PAYLOAD="$(cat)"

extract() {
  # $1 = dotted JSON path, e.g. tool_input.command
  PAYLOAD_ENV="$PAYLOAD" FIELD="$1" python -c '
import json, os, sys
raw = os.environ.get("PAYLOAD_ENV", "")
try:
    data = json.loads(raw)
    for k in os.environ["FIELD"].split("."):
        data = data.get(k, "") if isinstance(data, dict) else ""
    sys.stdout.write(data if isinstance(data, str) else "")
except Exception:
    sys.stdout.write("")
'
}

CMD="$(extract tool_input.command)"
CWD="$(extract cwd)"

if [[ -z "$CMD" ]]; then
  exit 0
fi

block() {
  printf 'guard_bash: blocked — %s\nCommand: %s\n' "$1" "$CMD" >&2
  exit 2
}

# ═══════════════════════════════════════════════════════════════════════════
# Stage 1 patterns (preserved verbatim)
# ═══════════════════════════════════════════════════════════════════════════

# 1. rm -rf / or rm -rf ~  (root / home wipe)
if [[ "$CMD" =~ rm[[:space:]]+-[rR]?[fF][rR]?[[:space:]]+(/|~)([[:space:]]|$) ]]; then
  block "destructive rm against / or ~"
fi

# 2. chmod 777
if [[ "$CMD" =~ chmod[[:space:]]+777 ]]; then
  block "chmod 777 (insecure permissions)"
fi

# 3. curl … | sh|bash  (remote pipe-to-shell)
if [[ "$CMD" =~ curl[[:space:]]+[^\|]*\|[[:space:]]*(sh|bash)([[:space:]]|$) ]]; then
  block "curl piped to shell (untrusted remote execution)"
fi

# 4. git push --force … main/master/develop
if [[ "$CMD" =~ git[[:space:]]+push.*--force.*(main|master|develop) ]]; then
  block "force push to protected branch (main/master/develop)"
fi

# 5. git reset --hard origin/{main,master,develop}
if [[ "$CMD" =~ git[[:space:]]+reset[[:space:]]+--hard[[:space:]]+origin/(main|master|develop) ]]; then
  block "git reset --hard against protected upstream"
fi

# ═══════════════════════════════════════════════════════════════════════════
# Stage 8 additions — sensitive access + PS destructives + global installs + secret echo
# ═══════════════════════════════════════════════════════════════════════════

# (a) Sensitive file access via Bash/PowerShell readers
#     terminator group (\s|$|;|&|\|) so cat .env.example passes
if [[ "$CMD" =~ (cat|less|more|head|tail)[[:space:]]+[^\|\;\&]*\.env([[:space:]]|$|\;|\&|\|) ]]; then
  block "reading .env via shell (use Read tool — Read deny already blocks)"
fi
if [[ "$CMD" =~ (cat|less|more|head|tail)[[:space:]]+[^\|\;\&]*credentials\.json ]]; then
  block "reading credentials.json via shell"
fi
if [[ "$CMD" =~ (cat|less|more|head|tail)[[:space:]]+[^\|\;\&]*\.ssh/ ]]; then
  block "reading .ssh/* via shell"
fi
if [[ "$CMD" =~ (cat|less|more|head|tail)[[:space:]]+[^\|\;\&]*\.netrc ]]; then
  block "reading .netrc via shell"
fi
if [[ "$CMD" =~ (Get-Content|gc|type)[[:space:]]+[^\|\;\&]*\.env([[:space:]]|$|\;|\&|\|) ]]; then
  block "reading .env via PowerShell"
fi
if [[ "$CMD" =~ (Get-Content|gc|type)[[:space:]]+[^\|\;\&]*credentials\.json ]]; then
  block "reading credentials.json via PowerShell"
fi
if [[ "$CMD" =~ (Get-Content|gc|type)[[:space:]]+[^\|\;\&]*\.ssh/ ]]; then
  block "reading .ssh/* via PowerShell"
fi

# (b) Destructive — PowerShell + cmd.exe variants
if [[ "$CMD" =~ Remove-Item[[:space:]]+.*-Recurse.*-Force ]]; then
  block "PowerShell Remove-Item -Recurse -Force"
fi
if [[ "$CMD" =~ Remove-Item[[:space:]]+.*-Force.*-Recurse ]]; then
  block "PowerShell Remove-Item -Force -Recurse"
fi
if [[ "$CMD" =~ (^|[[:space:]\;\&\|])ri[[:space:]]+.*-r.*-fo ]]; then
  block "PowerShell Remove-Item alias (ri -r -fo)"
fi
if [[ "$CMD" =~ rmdir[[:space:]]+/[sS][[:space:]]+/[qQ] ]]; then
  block "cmd.exe rmdir /s /q (silent recursive)"
fi

# (c) Global / privileged installs (require explicit user terminal action)
if [[ "$CMD" =~ npm[[:space:]]+install[[:space:]]+.*(-g|--global) ]]; then
  block "npm install -g (global install — run in terminal, not via agent)"
fi
if [[ "$CMD" =~ npm[[:space:]]+i[[:space:]]+.*(-g|--global) ]]; then
  block "npm i -g (global install)"
fi
if [[ "$CMD" =~ pip[[:space:]]+install[[:space:]]+--user ]]; then
  block "pip install --user (user-site install)"
fi
if [[ "$CMD" =~ pip[[:space:]]+install[[:space:]]+--break-system-packages ]]; then
  block "pip install --break-system-packages"
fi
if [[ "$CMD" =~ cargo[[:space:]]+install[[:space:]]+.*--git ]]; then
  block "cargo install --git (install from arbitrary remote)"
fi
if [[ "$CMD" =~ uv[[:space:]]+tool[[:space:]]+install ]]; then
  block "uv tool install (system-wide tool install — run in terminal)"
fi

# (d) Secret echo / printf
if [[ "$CMD" =~ (echo|printf|Write-Output|Write-Host)[[:space:]]+.*\$\{?(API_KEY|SECRET|TOKEN|PASSWORD|AWS_SECRET|OPENAI_API_KEY) ]]; then
  block "echo of secret-looking variable (\$API_KEY/\$SECRET/\$TOKEN/...)"
fi
if [[ "$CMD" =~ (echo|printf)[[:space:]]+.*\$env:.*(KEY|SECRET|TOKEN|PASSWORD) ]]; then
  block "echo of PowerShell \$env: secret variable"
fi

# (e) 백그라운드 작업 폴링 루프 금지 — harness가 완료 시 자동 재호출하므로 폴링은 헛돈다.
#     until/while 루프가 grep/test로 마커(EXIT 등)를 검사하며 sleep 하는 형태를 차단.
if [[ "$CMD" =~ (until|while)[[:space:]]+.*(grep|test|\[\[?)[^\;]*\;?[[:space:]]*do[[:space:]]+.*sleep ]]; then
  block "백그라운드 폴링 루프 금지 — run_in_background로 띄우고 완료 알림을 기다려라(폴링 X). 즉시 확인이 필요하면 작업 후 결과 파일만 1회 Read."
fi
if [[ "$CMD" =~ (until|while)[[:space:]]+.*sleep[^\;]*\;?[[:space:]]*do ]]; then
  block "백그라운드 폴링 루프 금지(sleep-loop) — 완료 알림을 기다려라."
fi

exit 0
