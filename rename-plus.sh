#!/usr/bin/env bash
# rename-plus.sh — align the tmux session and window labels for the current terminal.
# The chat/task title belongs to the active application runtime; this helper never edits a
# Claude or Codex session registry and never claims that runtime-owned title changed.
#
# Usage:   rename-plus.sh "<desired name>"
# Example: rename-plus.sh "tmux-setup"
set -euo pipefail

RAW="${1:-}"
if [[ -z "$RAW" ]]; then
  echo "usage: rename-plus.sh \"<desired name>\"" >&2
  exit 2
fi

# --- safe name for terminal labels ---
# Reduce the input to one line of printable ASCII:
#   1. LC_ALL=C -> bytes, never "illegal byte sequence"; 2. C0 whitespace -> space;
#   3. delete every byte outside 0x20-0x7e (all C0/C1 controls, DEL, and every multibyte code
#      point incl. NEL U+0085 / LS U+2028 / PS U+2029, whose bytes are all >= 0x80).
# Result: guaranteed single line, printable ASCII only. Non-ASCII letters are dropped by design.
NAME="$(printf '%s' "$RAW" | LC_ALL=C tr '\011-\015' ' ' | LC_ALL=C tr -cd '\040-\176' | sed -E 's/  +/ /g; s/^ +| +$//g')"
[[ -z "$NAME" ]] && NAME="session"

# --- sanitize for tmux: a conservative tmux-safe slug (session targets choke on '.'/':'). ---
# Keep [A-Za-z0-9_-]; turn everything else into '-'; collapse/trim dashes.
SAFE="$(printf '%s' "$NAME" | LC_ALL=C tr -c 'A-Za-z0-9_-' '-' | sed -E 's/-+/-/g; s/^-|-$//g')"
[[ -z "$SAFE" ]] && SAFE="session"

echo "== rename-plus =="
echo "requested name : $NAME"
[[ "$NAME" != "$RAW" ]] && echo "note           : reduced name to a single line of printable ASCII"
[[ "$SAFE" != "$NAME" ]] && echo "tmux-safe slug : $SAFE"
echo

# --- tmux session + window. Non-fatal so the title limitation is still reported. ---
if [[ -n "${TMUX:-}" ]] && command -v tmux >/dev/null 2>&1; then
  if before_s="$(tmux display-message -p '#S' 2>/dev/null)" \
     && before_w="$(tmux display-message -p '#W' 2>/dev/null)" \
     && tmux rename-session "$SAFE" 2>/dev/null \
     && tmux set-window-option automatic-rename off 2>/dev/null \
     && tmux rename-window "$SAFE" 2>/dev/null \
     && after_s="$(tmux display-message -p '#S' 2>/dev/null)" \
     && after_w="$(tmux display-message -p '#W' 2>/dev/null)"; then
    echo "[tmux] session : $before_s -> $after_s"
    echo "[tmux] window  : $before_w -> $after_w  (automatic-rename: off)"
    if [[ "$after_s" == "$SAFE" && "$after_w" == "$SAFE" ]]; then
      echo "[tmux] verified OK"
    else
      echo "[tmux] WARNING: readback did not match '$SAFE'"
    fi
  else
    echo "[tmux] tmux present but a query/rename failed (stale \$TMUX, unreachable server, or name clash) — skipped."
  fi
else
  echo "[tmux] not inside a tmux session (\$TMUX unset) — skipping tmux rename."
fi
echo

echo
echo "[task] The chat/task title is owned by the active runtime and was not changed by this helper."
echo "Done. tmux tiers synced where possible."
