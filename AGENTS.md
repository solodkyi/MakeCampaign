# MakeCampaign Automatic Agent Protocol

## Explicit full-loop invocation

Use `$makecampaign-feature-loop <complete explanation>` when the user explicitly requests the full MakeCampaign delivery loop. The repository skill at `.agents/skills/makecampaign-feature-loop/` owns requirements challenges, existing-code research, research-derived questions, refactoring/implementation/test plans, test-first implementation, automatic repair, and the final full changes list plus manual verification checklist. It is explicit-only and must not start from an ordinary feature question.

The skill may pause for one material clarification at a time and resumes the loop after the answer. It does not grant permission to commit, push, publish, delete, or change unrelated work.

## Automatic completion

Every core, component, or feature change uses a lowercase kebab-case scope configured in `workflow.config.json`. Before declaring a scoped change complete, run:

```sh
python3 Scripts/workflow.py run <scope>
```

The command must exit `0`. The runner executes every configured build, unit, integration, and simulator step directly, without prompts. The runner itself has no independent-review gate, finding lifecycle, technical-debt gate, remediation decision, or user-decision stage; interactive clarification belongs to the explicitly invoked skill before implementation or when a repair requires a material decision.

A failed, timed-out, interrupted, malformed, or tampered run blocks completion. Fix the cause and start a new run; finalized runs under ignored `.workflow-runs/` are immutable and must not be edited or reused. `workflow.config.json` must be tracked and clean relative to `HEAD` before execution.

## Working-tree protection

Preserve every pre-existing dirty-tree change. Do not reset, overwrite, stage, commit, restore, delete, or reinterpret user-owned changes without explicit instruction. The runner records repository provenance but permits unrelated dirty files. Runner output is confined to ignored `.workflow-runs/`.

## Applicable SwiftUI skills

New or redesigned SwiftUI UI must use the applicable `swiftui-liquid-glass`, `swiftui-ui-patterns`, `pfw-composable-architecture`, `pfw-testing`, and `ios-debugger-agent` skills. Configure the scope to execute the relevant build, unit, integration, and simulator/UI-test commands automatically, including the required iOS deployment target and destination.
