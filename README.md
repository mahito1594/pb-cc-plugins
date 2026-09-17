# pb-cc-plugins

A Claude Code plugin marketplace distributing three workflow plugins: `discuss`, `orchestrate`, and `session-residue`.

## Add the marketplace

```
/plugin marketplace add mahito1594/pb-cc-plugins
```

## Install a plugin

```
/plugin install discuss@pb-cc-plugins
/plugin install orchestrate@pb-cc-plugins
/plugin install session-residue@pb-cc-plugins
```

## Plugins

- **discuss**: Design discussion mode that blocks file edits via a lock file and a bundled `PreToolUse` hook until you end the discussion.
- **orchestrate**: Orchestrator mode that keeps planning, verification, and commits in the main session and delegates implementation to a bundled subagent.
- **session-residue**: Keeps session residue — sentences that only someone who was in the writing session can resolve ("the spec", "as requested", "findings 3 and 8") — out of deliverables. See [session-residue](#session-residue).

## session-residue

The plugin bundles a skill with the writing rules (`/session-residue`) and a subagent, `session-residue:residue-check`, that reads finished files with no session context and lists every reference it cannot resolve through files tracked by git or public URLs.

The work is split on purpose. The agent can tell whether a reference resolves, because it has no context; it cannot tell what the writer meant. A single run misses some residue and flags some sound references, so the calling session treats its report as a signal, verifies each finding, and makes the fixes. Pass the agent file paths only: any session context in the prompt defeats the check.

The agent definition sets `model: haiku`. A per-invocation `model` parameter takes precedence over the definition's frontmatter ([Choose a model](https://code.claude.com/docs/en/sub-agents#choose-a-model)), so to trade cost for precision, tell Claude in your prompt or your `CLAUDE.md` to run `session-residue:residue-check` with `sonnet`.

## License

MIT. See [LICENSE](./LICENSE).
