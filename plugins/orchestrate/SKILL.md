---
name: orchestrate
description: Orchestrator mode for expensive main models (Fable/Opus).
  Delegate implementation to the implementer subagent; keep planning,
  verification, and commits in the main session. Invoke manually at
  session start.
disable-model-invocation: true
---

# Orchestrator Mode

The main session (expensive model) plans, verifies, judges, and commits.
Implementation is delegated to the `implementer` subagent — sonnet by
default, overridable per unit (see the model escalation rule below).

## Rules

- Work from an approved plan file. The agreement layer is plan mode: the
  overall design — including unit breakdown — is planned and approved via
  ExitPlanMode. The approved plan file (plansDirectory, auto-named) is
  the agreement of record; treat it as read-only for the rest of the
  session. Chat consensus (e.g. a design discussion that ended in
  agreement) is input to plan mode, not a substitute for it. Accepted review findings on a PR are the
  exception: their record lives on the PR and needs no plan-mode pass.
- Enter plan mode yourself (EnterPlanMode) when no approved plan file
  exists — at task intake, when a new task arrives mid-session, or when
  an escalation shows the agreed design must change.
- Delegate one verifiable deliverable at a time (e.g. a component plus
  its test) to `implementer`. The delegation message names both files
  (approved plan + orchestrate document) and the file boundaries;
  anything unusual goes in one line. The agent definition carries the
  protocol; do not repeat it.
- Judge each unit's difficulty at planning time: delegate units you judge
  high-difficulty to opus from the start by passing `model: opus` on the
  Agent call — it takes precedence over the agent definition's frontmatter.
  If a sonnet unit fails to converge after one resume round, re-delegate it
  to a fresh opus agent instead of a second resume (the model is fixed at
  spawn time); that opus attempt counts as the second round toward the
  two-round limit below.
- Verify each result yourself: diff against the plan, run the project's
  standard verification commands (e.g. test, lint, build). For UI units, additionally exercise
  the change in the browser at first delivery when browser tooling
  (e.g. claude-in-chrome) is available, not only after dogfooding.
  Judge gaps in correctness and requirements, not style.
- Read the unit's new and changed comments as someone who has only the
  repository: every reference resolves to a path that exists there, none
  stands on a label the session invented, and no review or process narration
  has leaked in. There is no mechanical check for this — these failures
  leave no fingerprint a grep can find.
- Fixes to the same problem go to the same agent via resume (SendMessage).
  A new unit gets a fresh agent. Iteration rounds driven by fresh user
  input (design exploration with the user in the loop) are new problems,
  not repeated attempts on the same one, and do not count toward the
  two-round limit below.
- Documentation that records judgment (ADR entries, design rationale,
  decision records) stays with the orchestrator — implementer delegation offers no
  token savings when the judgment is already in the orchestrator, and
  the round trip only risks fidelity loss. Purely mechanical doc work
  may be delegated.
- After verification passes, commit. One deliverable ≈ one commit.
- Escalate to the user when: the plan itself needs changing, a unit
  boundary must move, or two rounds on the same problem (resumes or an
  opus re-delegation) fail to converge.
- When spawning Explore, always pass an explicit model
  (haiku by default; sonnet when the sweep needs judgment).

## Delegation document

- The orchestrate document (`.claude/orchestrate/<task-slug>.md`,
  untracked) is the delegation layer, not the agreement layer. Its head
  is a pointer to the approved plan file:
  `Approved design: <absolute plan file path>, approved <YYYY-MM-DD>`.
  Do not copy the plan's contents in — leave the design as one source
  of truth on the plan file, and have the implementer Read both files.
- If the referenced plan file is missing when needed, stop and
  re-establish agreement with the user via plan mode. Do not reconstruct
  the design from memory or from the orchestrate document.
- Below the pointer, the document holds delegation-time material that
  does not belong on the plan file: project rules digest for the
  implementer, verification commands, commit plan, unit-time back-fills
  (e.g. API probing results), and dated ad-hoc addenda. This section
  needs no separate approval; changes to it are recorded as dated
  additions, not silent edits.
- Adding a unit not in the approved plan requires the user's explicit
  OK before delegation. A short chat confirmation is fine — the point
  is the record, not the effort.
