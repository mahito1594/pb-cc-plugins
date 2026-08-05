---
name: discuss
description: "Enter or exit design discussion mode. /discuss starts a focused design conversation that blocks file edits via a lock file (<project root>/.claude/discuss-$CLAUDE_CODE_SESSION_ID.lock). /discuss end removes the lock, summarizes the outcomes, and stops at the junction so the user chooses the next step (plan mode, model switch, orchestrate, handoff, record-only, or park). Trigger on: /discuss, 'start discussion', 'design discussion', /discuss end, 'end discussion', 'exit discussion mode'."
---

# Discussion Mode

State is tracked via a lock file at `<project root>/.claude/discuss-$CLAUDE_CODE_SESSION_ID.lock`, where project root is resolved as `git rev-parse --show-toplevel` falling back to `pwd`. Do NOT place the lock under `$TMPDIR`: sandboxed Bash commands and hook commands resolve `$TMPDIR` to different directories by design, so a TMPDIR-based lock is invisible to the hook. The `PreToolUse` hook bundled with this plugin reads the lock (checking both `$CLAUDE_PROJECT_DIR` and the git-toplevel of its own cwd) and blocks `Edit`/`Write` calls while the file exists. The hook matches only those two tools: file writes through other routes (Bash redirection, `sed -i`, heredocs, NotebookEdit) are not blocked mechanically — avoid them yourself while the lock exists. Code snippets in the conversation are fine for illustration — only file writes are off-limits.

## Lock file discipline

- The lock file is created by `/discuss` and removed by step 2 of `/discuss end`. Nothing justifies removing it anywhere else — not believing the discussion has concluded, not wanting to edit files, not finishing delegated research, and not any reason unlisted here.
- `/discuss end` runs only when the user explicitly invokes it or asks to end the discussion in their own words ("これで議論は終わり", "wrap up the discussion"). A request to implement, apply, or "go ahead with" the design is NOT an end request — the outcome still needs its junction step. In every such case, propose that the user run `/discuss end`, then wait for their answer.

## `/discuss [topic]` — Enter discussion mode

1. If the lock file already exists, discussion mode is already active: keep the running record and treat any new `[topic]` as a topic shift, not a fresh start. Otherwise create the lock file and confirm it exists:

```bash
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
mkdir -p "$ROOT/.claude" && touch "$ROOT/.claude/discuss-$CLAUDE_CODE_SESSION_ID.lock"
if GITDIR="$(git -C "$ROOT" rev-parse --git-common-dir 2>/dev/null)"; then
  case "$GITDIR" in /*) ;; *) GITDIR="$ROOT/$GITDIR" ;; esac
  mkdir -p "$GITDIR/info"
  grep -qxF '.claude/discuss-*.lock' "$GITDIR/info/exclude" 2>/dev/null || echo '.claude/discuss-*.lock' >> "$GITDIR/info/exclude"
fi
test -f "$ROOT/.claude/discuss-$CLAUDE_CODE_SESSION_ID.lock"
```

2. Announce that discussion mode is now active and file edits are blocked. If the lock could not be created, announce instead that the hook protection is NOT active and edits are held off by convention only.
3. If a `[topic]` argument was provided, acknowledge it and open the discussion focused on that topic. If no argument, wait for the user to lead.

## During discussion

- Inline research pollutes the main context: each lookup accelerates compaction and degrades the end-of-discussion summary. Delegate research to subagents (`model: sonnet`, or `haiku` for mechanical extraction) and keep the main thread on synthesis and trade-off judgment. Research includes: doc queries via docs MCP tools (e.g. context7) or WebFetch, probing external APIs with curl, and exploring dependency internals (node_modules, vendored code).
- Quick inline checks of the project's own files (reading 1–2 files, listing a directory) are exempt from the rule above. But when quick checks start chaining — a second consecutive lookup serving the same question — treat the chain as a research theme: stop and delegate the theme, not the individual lookup.
- Example: instead of running `curl https://api.example.com/...` three times to learn a response shape, spawn one subagent: "Investigate this API's response structure and report only the essentials."
- Track outcomes as they emerge: decisions made, alternatives rejected (with reasons), open questions. Whenever the record changes, restate it in the conversation in compact form — one line per item (`Decided: X — reason / Rejected: Y — reason / Open: Z`). Skip the restatement on turns where nothing changed.

## Discussion conduct

- Every option survey ends with your recommendation and its reason. If you have no position, say what evidence would give you one.
- Name the trade-off before recommending: what is gained, what is given up.
- On pushback, judge the argument, not the person's confidence: either defend your position with reasons or concede and state exactly what changed your mind. Never concede merely to agree.
- At most one question per turn, aimed at whatever would most change the decision.

## `/discuss end` — Exit discussion mode

1. If the lock file does not exist, say that no discussion mode is active and stop — do not force a summary onto an ordinary conversation. Otherwise summarize the discussion first: decisions / rejected alternatives (with reasons) / open questions. Flag any decision with lasting consequences as an ADR draft candidate.
2. Remove the lock file (see Lock file discipline — this is the only place it is removed):

```bash
rm -f "$(git rev-parse --show-toplevel 2>/dev/null || pwd)/.claude/discuss-$CLAUDE_CODE_SESSION_ID.lock"
```

3. State the junction and stop. Do NOT call EnterPlanMode yourself: entering plan mode locks the current model in as the planner, and switching models is a user action. Whether to plan and which model plans are independent choices, so lay out the options and let the user pick:
   - **Plan with the current model** — the user asks for plan mode.
   - **Plan with a different model** — the user runs `/model` first; the conversation context survives the switch, so no handoff file is needed.
   - **Handoff** — on request, write the summary (same structure as step 1) plus pointers to relevant files to `.claude/discuss/<YYYY-MM-DD>-<slug>.md` in the project, for continuing the discussion in a fresh session. Take the date from `date +%F`; derive the slug from the topic as 2–4 ASCII kebab-case words. If that path already exists, do NOT overwrite it — report the collision and ask. Record judgments only; facts stay as pointers. After writing, state the full path and tell the user to point the next session at that file — nothing picks it up automatically. Handoff files are not auto-deleted and are not gitignored by default.
   - **Orchestrate** (requires the orchestrate plugin) — the design is settled and implementation will be delegated: the user invokes `/orchestrate`; the summary seeds the plan document (`.claude/orchestrate/<slug>.md`) and implementation goes to the implementer subagent.
   - **Record-only outcome** — on request, write the decision where it belongs (ADR draft, stories, config).
   - **Parked** — the summary's open questions are the record; stop there.

   As a hint for the choice: if the discussion settled the design and only translation into steps remains, a smaller model can plan; if open questions remain, planning with the current model is safer.
