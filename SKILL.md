---
name: rename-plus
description: "Rename the current terminal, tmux window, and supported runtime task-title surfaces to one verified label."
---

# rename-plus — rename every available title surface

## Overview

A terminal has two directly controllable tmux tiers; the chat/task title is a separate runtime-owned surface. This skill synchronizes the terminal tiers and uses a runtime-native task-title control only when the active runtime exposes one. It never edits a session-registry file.

| Tier | What sets it | Can the agent do it? |
|---|---|---|
| **tmux session** | `tmux rename-session` | ✅ directly |
| **tmux window** | `tmux rename-window` (+ `automatic-rename off`) | ✅ directly |
| **Codex chat/task title** | UserPromptSubmit app-server handler | ✅ for every Codex runtime |

## Usage

1. **Pick the name.** If the operator gave one, use it. Otherwise derive a short kebab-case slug from what this session is *doing* (`tmux-setup`, `nicegui-pr-4821`), not from the machine.
2. **Let the event handler attempt the complete rename.** The UserPromptSubmit handler receives the current thread ID, calls the supported local `thread/name/set` app-server method, then sets the tmux/Ghostty label.
3. **Verify both surfaces.** Read back the persisted task title and the live window's `@codex_session_name`. If only TokScale is stale, use `~/.cache/ghostty-tmux/socket` and target only the window whose `@codex_thread_id` exactly matches the current thread. Never infer identity from an existing session/window name or requested label; zero or multiple matches must fail closed. Set the window option and window name, then verify the option and rendered TokScale text. Never use Computer Use or a desktop-only title tool.

## Notes

- The script derives a **conservative tmux-safe slug** for the tmux tiers (`feat.2:api` → `feat-2-api`), since tmux session targets choke on `.`/`:`.
- **Input guard:** the tmux label is reduced to a single line of printable ASCII; controls and non-ASCII characters are dropped.
- Names are **live labels, not persistent** — a fresh tmux/Codex session starts auto-named again. This skill re-labels the current session; it does not change how future sessions are auto-named.
- `automatic-rename off` is set so the shell/running program can't overwrite the window name back.
