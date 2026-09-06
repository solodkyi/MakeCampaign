---
name: makecampaign-feature-loop
description: Use when the user explicitly invokes the complete MakeCampaign workflow for a core, reusable component, or feature change.
---

# MakeCampaign Feature Loop

## Purpose

Drive one MakeCampaign change from the user's complete explanation to a verified implementation and actionable handoff. This skill is explicit-only. Treat `$makecampaign-feature-loop` as authorization to run the loop, not as permission to commit, push, delete, publish, or change unrelated work.

## Non-negotiable rules

- Read repository `AGENTS.md` first and obey it throughout.
- Preserve all pre-existing working-tree changes. Record the initial status and never reinterpret another owner's edits as part of this scope.
- Work in the current branch unless the user explicitly asks otherwise.
- Use a lowercase kebab-case scope configured in `workflow.config.json`.
- Store narrative records under ignored `docs/core/<name>/`, `docs/components/<name>/`, or `docs/features/<name>/`.
- Keep `.workflow-runs/` immutable. Never edit, reuse, or repair a finalized run.
- Ask only about choices that materially affect product behavior, architecture, risk, scope, or required authority. Resolve discoverable facts through research.
- Ask one focused question at a time, explain why it matters, and recommend a default.
- Do not implement while either challenge gate has an unresolved material question.
- Use the applicable project and SwiftUI skills required by `AGENTS.md`.
- Never claim completion unless `python3 Scripts/workflow.py run <scope>` exits `0` in a fresh workflow run.

Read [references/record-templates.md](references/record-templates.md) before creating workflow records. Read [references/handoff-template.md](references/handoff-template.md) before the completion handoff.

## 1. Intake and scope

1. Parse everything following the skill invocation as the source explanation. Preserve all stated goals, examples, constraints, acceptance criteria, exclusions, and uncertainties in the research record; do not silently narrow them.
2. Identify the change category (`core`, `components`, or `features`) and propose a stable lowercase kebab-case name. The resulting scope is `<category>/<name>`.
3. Inspect `git status`, recent relevant history, `AGENTS.md`, `workflow.config.json`, and existing local records before changing files.
4. If a compatible scope exists, use it. If not, include the required configuration change in the plans. Because the runner requires a tracked clean configuration, stop for explicit authority if satisfying that invariant would require a commit or another action not already authorized.
5. Create the scope record directory and start `00-codebase-research.md` with the source explanation, known decisions, assumptions, open questions, and repository provenance.

## 2. Initial challenge gate

Challenge the explanation before deep implementation research. Check at least:

- user outcome, entry points, success state, cancellation, retry, and destructive behavior;
- included and excluded flows, empty/loading/error/offline states, and data lifetime;
- design source of truth, platform/OS behavior, accessibility, localization, privacy, and permissions;
- compatibility, migration, analytics, performance, and observability where relevant;
- testable acceptance criteria and manual-verification expectations.

Resolve answers already present in the explanation or repository. For each remaining material decision:

1. Record it under `Open questions`.
2. Ask one concise question with the evidence, consequences, and recommended answer.
3. Pause. On the next user reply, record the answer and continue this gate.

Record `Initial challenge complete` only when no material question remains. Do not implement or write final plans before this gate closes.

## 3. Existing-code research

Research before planning:

1. Map the current feature flow, TCA domains, dependencies, navigation, SwiftUI views/components, persistence/network boundaries, and relevant tests.
2. Inspect the supplied design artifacts and existing component library when UI is in scope.
3. Find conventions and adjacent implementations to reuse.
4. Identify code that must be refactored before the new behavior can fit cleanly; do not turn unrelated cleanup into scope.
5. Confirm build schemes, destinations, deployment targets, and configured unit/integration/simulator commands.
6. Update `00-codebase-research.md` with evidence, file paths, risks, reuse opportunities, and plan implications.

## 4. Research challenge gate

Compare research findings with every accepted requirement and assumption. A significant point includes a contradiction, missing product rule, data migration, public API change, security/privacy consequence, unsupported platform behavior, destructive action, or a choice that materially changes UX or effort.

For each significant unresolved point, use the same one-question checkpoint as the initial challenge gate and update the research record. If none exist, record `Research challenge complete: no new material questions` and continue automatically.

Do not implement until this gate closes.

## 5. Planning gates

Write these records in order using the templates:

1. `01-refactoring-plan.md` — how existing code changes so the feature fits, with explicit boundaries and preserved behavior.
2. `02-implementation-plan.md` — exact file-level, test-first tasks, dependencies, acceptance criteria, and integration order.
3. `03-test-plan.md` — unit, integration, configured simulator/UI, and manual coverage, including negative and edge cases.
4. `plan-deviations.md` — initialize with `None`; append rather than erase when execution diverges.

Cross-check all requirements against a plan task and all risks against a test or explicit manual check. Continue automatically after the plans are internally consistent; do not add a separate approval or review gate unless a material unanswered decision appears.

## 6. Implementation and tests

Execute the plans in order:

1. Use test-driven development for behavior changes: add the focused failing test, observe the expected failure, implement minimally, and make it pass.
2. Keep edits inside the chosen scope and preserve user-owned changes.
3. Run focused tests after each coherent change, then the broader affected suite.
4. Update plan checkboxes and evidence as work completes.
5. When implementation must depart from a filed plan, append the reason, affected files, risk, and changed test coverage to `plan-deviations.md`; update `03-test-plan.md` before continuing.
6. Do not commit, push, publish, or alter external state unless explicitly authorized.

## 7. Automatic verification and repair loop

1. Confirm `workflow.config.json` contains the exact scope and required build, unit, integration, and simulator/UI steps. Confirm it is tracked and clean relative to `HEAD`.
2. Run exactly:

   ```sh
   python3 Scripts/workflow.py run <scope>
   ```

3. If the run fails, times out, is interrupted, malformed, or cannot be verified:
   - preserve the failed artifact unchanged;
   - diagnose the root cause using systematic debugging;
   - append the deviation and evidence to `plan-deviations.md`;
   - review and update `03-test-plan.md` for the discovered failure mode;
   - implement the repair and its regression test;
   - rerun focused checks, then start a fresh workflow run.
4. Repeat until a fresh workflow run exits `0`. Ask the user only if progress requires a material product decision, unavailable external input, or new authority.
5. Record the successful run path/identifier and step results in `04-completion-handoff.md`.

## 8. Completion handoff

Create `04-completion-handoff.md`, then give the user a self-contained final response containing:

- the delivered behavior and scope;
- a full changes list, file by file, including tests and records;
- accepted decisions and every plan deviation;
- automated verification commands, outcomes, and successful immutable run reference;
- a manual verification checklist with prerequisites, exact actions, and expected results;
- known limitations or nonblocking follow-ups;
- an explicit statement that pre-existing unrelated changes were preserved.

Do not describe work as complete if any required automated check is missing or failing. If blocked, report the exact blocker, completed work, preserved evidence, and the single user action needed to resume.
