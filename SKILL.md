---
name: rename-plus
description: >-
  Use when the operator wants to rename "this session" / "this terminal" / "this pane/window/tab" to match what you're working on. Syncs the tmux session and window to one coherent label, and reports whether the active runtime exposes a separate task-title control. Triggers: "rename this session", "rename this to match what we're doing", "rename everything", "/rename", "name this pane", "the tmux session is still called claude-<timestamp>".
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
2. **Let the event handler perform the complete rename.** The UserPromptSubmit handler receives the current thread ID, calls the supported local `thread/name/set` app-server method, then sets the tmux/Ghostty label. It is runtime-independent and runs before this skill. Never use Computer Use or a desktop-only title tool to inspect or rename Codex/Ghostty.
3. **Report the handler result.** Do not run a duplicate helper. If the persisted-title update fails, report that title as unchanged rather than claiming terminal output was a complete rename.

## Notes

- The script derives a **conservative tmux-safe slug** for the tmux tiers (`feat.2:api` → `feat-2-api`), since tmux session targets choke on `.`/`:`.
- **Input guard:** the tmux label is reduced to a single line of printable ASCII; controls and non-ASCII characters are dropped.
- Names are **live labels, not persistent** — a fresh tmux/Codex session starts auto-named again. This skill re-labels the current session; it does not change how future sessions are auto-named.
- `automatic-rename off` is set so the shell/running program can't overwrite the window name back.
