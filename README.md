# rename-plus

A [Claude Code](https://claude.com/claude-code) / [Codex](https://openai.com/codex/) skill: synchronizes the two directly-controllable tmux tiers (session name + window name) for the current terminal to one coherent label. The chat/task title — the Claude Code session name or the Codex thread title — is a separate, runtime-owned surface, set automatically by a `UserPromptSubmit` handler before this skill runs; this script never edits that registry directly.

See [`SKILL.md`](SKILL.md) for the actual behaviour and [`rename-plus.sh`](rename-plus.sh) for the tmux helper.

## The title tiers

| Tier | What sets it | Can this skill do it? |
|---|---|---|
| 🪟 **tmux session** | `tmux rename-session` | ✅ directly — the script does it |
| 🗂️ **tmux window** | `tmux rename-window` (+ `automatic-rename off`) | ✅ directly — the script does it |
| 🤖 **Chat/task title** (Claude Code session name or Codex thread title) | Runtime-native handler (`UserPromptSubmit` → `thread/name/set` app-server method, every Codex runtime) | ⚙️ runtime-owned — set automatically before this skill runs, not by this script |

## Why the chat/task title is handled separately

Earlier versions of this skill tried to *propose* a `/rename <name>` command for the operator to paste, because the Claude Code session name lives in a registry (`~/.claude/sessions/<pid>.json`) that the live `claude` process owns and rewrites on every status change — a hand-edit gets clobbered within seconds, and `/rename` is an interactive REPL command the agent can't type into its own prompt.

That's now handled differently: a `UserPromptSubmit` event handler runs before this skill, receives the current thread ID, and calls the runtime's own `thread/name/set` app-server method to set the persisted task title directly — no registry hand-edits, no pasted command. This skill never claims to have set that tier itself; it reports the handler's result and moves on to the tmux tiers, which it renames and verifies directly.

## Usage

```bash
~/.claude/skills/rename-plus/rename-plus.sh "my-work"
```

- Renames the tmux session + window, sets `automatic-rename off`, and reads them back to confirm.
- Not inside tmux (`$TMUX` unset)? It skips the tmux tiers and reports that.
- Does not touch the chat/task title — that's the handler's job, already done before this script runs. Never run a duplicate helper for it, and never use Computer Use or a desktop-only title tool to inspect or rename Codex/Ghostty.

## Verification

For the Codex chat/task title specifically, verify both surfaces after the handler runs: the persisted task title, and the live window's `@codex_session_name`. If only the terminal-multiplexer display (TokScale) is stale, use `~/.cache/ghostty-tmux/socket` and target only the window whose `@codex_thread_id` exactly matches the current thread — never infer identity from an existing session/window name or the requested label; zero or multiple matches must fail closed.

## Safety

- **Input guard.** The name is reduced to a single line of printable ASCII — all C0/C1 controls, DEL, and multibyte line-breakers (NEL, LS, PS) are dropped under `LC_ALL=C` — so a name containing any line break can never expand into a second pastable command. Non-ASCII letters are dropped by design.
- **tmux-safe slug.** tmux session targets choke on `.`/`:`; the script derives a conservative slug (`feat.2:api` → `feat-2-api`) for the tmux tiers.
- **No persistence claims.** These are live labels on the running session, not a change to how future sessions are auto-named.

## License

MIT © 2026 Evan Chan
