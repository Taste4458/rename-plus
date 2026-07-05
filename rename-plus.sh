#!/usr/bin/env bash
# rename-plus.sh — align every name tier for the current terminal/session to ONE coherent label
# (renames the two tmux tiers directly; proposes the /rename line for the Claude tier).
#
# Renames the tmux SESSION + WINDOW directly (deterministic, verified here), then prints the
# `/rename <name>` line for the Claude Code session name — which this script CANNOT set, because
# that name lives in a JSON registry the running `claude` process owns and rewrites on every
# status change (a hand-edit gets clobbered within seconds). Only the human can type `/rename`.
#
# Contract: the `/rename <name>` proposal is ALWAYS printed, even if the tmux step is skipped or
# fails — that line is the whole point, so nothing is allowed to abort before it.
#
# Usage:   rename-plus.sh "<desired name>"
# Example: rename-plus.sh "tmux-setup"
set -euo pipefail

RAW="${1:-}"
if [[ -z "$RAW" ]]; then
  echo "usage: rename-plus.sh \"<desired name>\"" >&2
  exit 2
fi

# --- prompt-safe name for the `/rename` proposal ---
# The proposal is pasted verbatim into the Claude REPL, so it MUST be a single line that cannot
# expand into a second prompt command. We reduce the name to one line of printable ASCII:
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
[[ "$NAME" != "$RAW" ]] && echo "note           : reduced name to a single line of printable ASCII (prompt-injection guard)"
[[ "$SAFE" != "$NAME" ]] && echo "tmux-safe slug : $SAFE"
echo

# --- Tier 1 & 2: tmux session + window. NON-FATAL: any failure must not abort (see Contract). ---
# The whole tmux attempt lives in an `if` condition, so under `set -e` a failing command in the
# chain drops to the else branch instead of killing the script before the /rename line prints.
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
    echo "[tmux] the /rename line below still applies."
  fi
else
  echo "[tmux] not inside a tmux session (\$TMUX unset) — skipping tmux rename."
fi
echo

# --- Tier 3: Claude Code session name — propose only, cannot automate. Best-effort readback. ---
# Show the CURRENT Claude session name for this cwd so before/after is visible. Portable (no
# GNU-only flags): plain glob + per-file grep + stat with macOS/Linux fallback. All best-effort.
sess_dir="${HOME:-}/.claude/sessions"
if [[ -n "${HOME:-}" && -d "$sess_dir" ]]; then
  newest=""; newest_t=0
  for f in "$sess_dir"/*.json; do
    [[ -e "$f" ]] || continue
    if LC_ALL=C grep -qF "\"cwd\":\"$PWD\"" "$f" 2>/dev/null; then
      t="$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null || echo 0)"
      if [[ "$t" -ge "$newest_t" ]]; then newest_t="$t"; newest="$f"; fi
    fi
  done
  if [[ -n "$newest" ]]; then
    cur="$(sed -n -E 's/.*"name":"([^"]*)".*/\1/p' "$newest" 2>/dev/null | head -1)"
    src="$(sed -n -E 's/.*"nameSource":"([^"]*)".*/\1/p' "$newest" 2>/dev/null | head -1)"
    echo "[claude] current session name : ${cur:-<none>}  (nameSource: ${src:-?})"
  fi
fi
echo "[claude] cannot be scripted — the live \`claude\` process owns its registry file."
echo "         >>> RUN THIS IN THE CLAUDE PROMPT:   /rename $NAME"
echo
echo "Done. tmux tiers synced where possible; paste the /rename line above to finish the Claude tier."
