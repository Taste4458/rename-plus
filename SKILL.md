---
name: rename-plus
description: "Route Codex and Claude session rename requests to their runtime skills; rename a plain tmux terminal when explicitly requested."
---

# rename-plus

**Codex:** Follow `/Users/samstull/.agents/skills/source-command-rename/SKILL.md` for the saved task title and exact thread-bound tab. Do not run `rename-plus.sh` in Codex.

**Claude Code:** Follow `/Users/samstull/.agents/skills/rename/SKILL.md` for its hook-owned tab title.

**Plain tmux:** For an explicit terminal session/window rename, run `bash rename-plus.sh "<name>"` and read back `#S` and `#W`. This helper does not change any chat task title.

## Plain tmux details

Use the supplied name; if it is descriptive rather than literal, derive a short title from the current work. The helper sanitizes the tmux session slug and sets `automatic-rename off`.

The helper is for a plain terminal only. If a Codex thread binding is missing or non-unique, leave terminal titles untouched and report that condition.

- The script derives a **conservative tmux-safe slug** for the tmux tiers (`feat.2:api` → `feat-2-api`), since tmux session targets choke on `.`/`:`.
- **Input guard:** the tmux label is reduced to a single line of printable ASCII; controls and non-ASCII characters are dropped.
- Plain tmux names are live labels; a fresh terminal session starts auto-named again.
- `automatic-rename off` is set so the shell/running program can't overwrite the window name back.
