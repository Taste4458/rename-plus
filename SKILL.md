---
name: rename-plus
description: Use when the operator wants to rename "this session" / "this terminal" / "this pane/window/tab" to match what you're working on — and there is more than one name tier in play. Syncs the tmux session name AND the tmux window name to one coherent label, and surfaces the exact `/rename <name>` command for the operator to run (the Claude Code session name cannot be scripted). Triggers: "rename this session", "rename this to match what we're doing", "rename everything", "/rename", "name this pane", "the tmux session is still called claude-<timestamp>".
---

# rename-plus — one label across every name tier

## Overview

A terminal running Claude Code has **three** independently-named tiers that drift apart. This skill renames the two an agent can change directly (tmux session + window) and surfaces a one-line `/rename` proposal for the one only a human can (Claude) — so all three converge on one coherent label.

| Tier | What sets it | Can the agent do it? |
|---|---|---|
| **tmux session** | `tmux rename-session` | ✅ directly |
| **tmux window** | `tmux rename-window` (+ `automatic-rename off`) | ✅ directly |
| **Claude Code session** | `/rename <name>` | ❌ **propose only** — see below |

## The load-bearing fact (why the Claude tier is propose-only)

`/rename` writes the `name` field in `~/.claude/sessions/<pid>.json`, a registry the **live `claude` process owns and rewrites on every status change** (auto-derived names visibly drift, e.g. `alice-2f` → `alice-e9` between two commands). A hand-edit is clobbered within seconds, and `/rename` is an interactive REPL command the agent cannot type into its own prompt. So the agent **never edits that JSON and never claims to have renamed the Claude session** — it emits the `/rename <name>` line and asks the operator to run it.

## Usage

1. **Pick the name.** If the operator gave one, use it. Otherwise derive a short kebab-case slug from what this session is *doing* (`tmux-setup`, `nicegui-pr-4821`), not from the machine.
2. **Run the helper** — it renames both tmux tiers, verifies by readback, and prints the proposal:
   ```bash
   ~/.claude/skills/rename-plus/rename-plus.sh "<name>"
   ```
   Not inside tmux (`$TMUX` unset)? It skips the tmux tiers and still prints the `/rename` line.
3. **Surface the `/rename <name>` line to the operator** as an action for them to paste. Do not present the Claude tier as done.
4. **(Optional) close the loop:** after they run it, read `~/.claude/sessions/<pid>.json` and confirm `name` changed and `nameSource` is no longer `derived`.

## Notes

- The script derives a **conservative tmux-safe slug** for the tmux tiers (`feat.2:api` → `feat-2-api`), since tmux session targets choke on `.`/`:`; the `/rename` proposal keeps the fuller name.
- **Prompt-injection guard:** the name emitted in the `/rename` line is reduced to a **single line of printable ASCII** (all C0/C1 controls, DEL, and multibyte line-breakers like NEL/LS/PS are dropped under `LC_ALL=C`), so a name containing any line break can never expand into a second pastable prompt command. Non-ASCII letters are dropped by design. Don't defeat this by hand-assembling the `/rename` line from raw input.
- Names are **live labels, not persistent** — a fresh tmux/Claude session starts auto-named again. This skill re-labels the current session; it does not change how future sessions are auto-named.
- `automatic-rename off` is set so the shell/running program can't overwrite the window name back.
