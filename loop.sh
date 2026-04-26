#!/usr/bin/env bash
# Ralph loop driver. Runs iterations until done, blocked, or max count hit.

set -u
MAX_ITERATIONS="${MAX_ITERATIONS:-50}"
PROMPT_FILE="ralph_prompt.md"
PROGRESS_FILE="PROGRESS.md"

if [[ ! -f "$PROMPT_FILE" || ! -f "$PROGRESS_FILE" ]]; then
  echo "ERROR: must run from repo root (missing $PROMPT_FILE or $PROGRESS_FILE)"
  exit 1
fi

for ((i=1; i<=MAX_ITERATIONS; i++)); do
  echo ""
  echo "============================================"
  echo "Iteration $i / $MAX_ITERATIONS — $(date '+%H:%M:%S')"
  echo "============================================"

  # Check for done condition: M10 marked complete
  if grep -qE '^\s*-?\s*\[x\]\s*M10' "$PROGRESS_FILE"; then
    echo "✓ M10 complete. Done."
    break
  fi

  # Check for blocker condition: anything other than "(empty)" under Blockers
  if awk '/^## Blockers/{flag=1; next} /^##/{flag=0} flag && NF && !/^_\(empty\)_$/ && !/^---/' "$PROGRESS_FILE" | grep -q .; then
    echo "✗ Blocker detected in $PROGRESS_FILE. Stopping."
    awk '/^## Blockers/{flag=1; next} /^##/{flag=0} flag' "$PROGRESS_FILE"
    break
  fi

  # Invoke the agent
  # claude -p "$(cat "$PROMPT_FILE")"
  codex exec "$(cat "$PROMPT_FILE")"
  agent_exit=$?

  if [[ $agent_exit -ne 0 ]]; then
    echo "✗ Agent exited non-zero ($agent_exit). Stopping."
    break
  fi

  # Brief pause so you can Ctrl-C if something looks wrong
  sleep 3
done

echo ""
echo "Loop finished. Last 5 commits:"
git log --oneline -5
