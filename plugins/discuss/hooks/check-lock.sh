#!/usr/bin/env bash
SID="$CLAUDE_CODE_SESSION_ID"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
for d in "$CLAUDE_PROJECT_DIR" "$ROOT"; do
  if [ -n "$d" ] && [ -f "$d/.claude/discuss-$SID.lock" ]; then
    echo 'Discussion mode is active — file edits are blocked. Do not remove the lock file for any reason; propose that the user run /discuss end and wait.'
    exit 2
  fi
done
exit 0
