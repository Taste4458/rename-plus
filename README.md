# rename-plus

A [Claude Code](https://claude.com/claude-code) skill: when you tell the agent to "rename this session to match what we're doing," a terminal running Claude Code actually has **three** independently-named tiers that drift apart. `rename-plus` renames the two tmux tiers itself and hands you the one-line `/rename` command for the third (which only a human can run) — so all three end up on one label.

See [`SKILL.md`](SKILL.md) for the actual behaviour and [`rename-plus.sh`](rename-plus.sh) for the helper.

## The three name tiers

| Tier | What sets it | Can the agent do it? |
|---|---|---|
| 🪟 **tmux session** | `tmux rename-session` | ✅ directly — the script does it |
| 🗂️ **tmux window** | `tmux rename-window` (+ `automatic-rename off`) | ✅ directly — the script does it |
| 🤖 **Claude Code session** | `/rename <name>` | ❌ **propose only** — the agent hands you the line to paste |

## Why the Claude tier is propose-only (the load-bearing fact)

`/rename` writes the `name` field in `~/.claude/sessions/<pid>.json` — a registry the **live `claude` process owns and rewrites on every status change**. Auto-derived names visibly drift (`alice-2f` → `alice-e9` between two commands), so:

- a hand-edit to that JSON is clobbered within seconds, and
- `/rename` is an interactive REPL command the agent **cannot type into its own prompt**.

So the honest contract is: the agent renames the two tmux tiers itself, **verifies them by readback**, and then *proposes* `/rename <name>` for you — it never edits the registry and never claims the Claude tier is done when only a human can finish it.

## Usage

```bash
~/.claude/skills/rename-plus/rename-plus.sh "my-work"
```

- Renames the tmux session + window, sets `automatic-rename off`, and reads them back to confirm.
- Prints the exact `/rename my-work` line for you to paste into the Claude prompt.
- Not inside tmux? It skips the tmux tiers and still prints the `/rename` line.

## Safety

- **Prompt-injection guard.** The name in the `/rename` proposal is reduced to a single line of printable ASCII — all C0/C1 controls, DEL, and multibyte line-breakers (NEL, LS, PS) are dropped under `LC_ALL=C` — so a name containing any line break can never expand into a second pastable prompt command (e.g. `foo⏎/quit` becomes the inert one-line string `foo /quit`). Non-ASCII letters are dropped by design.
- **tmux-safe slug.** tmux session targets choke on `.`/`:`; the script derives a conservative slug (`feat.2:api` → `feat-2-api`) for the tmux tiers while keeping the fuller name for the `/rename` proposal.
- **Always prints `/rename`.** The `/rename` line is printed even if the tmux step is skipped or fails (stale `$TMUX`, unreachable server, name clash) — that line is the whole point, so nothing aborts before it.
- **No persistence claims.** These are live labels on the running session, not a change to how future sessions are auto-named.

## License

MIT © 2026 Evan Chan
