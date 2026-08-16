# MakeCampaign Automatic Agent Protocol

## Automatic completion

Every core, component, or feature change uses a lowercase kebab-case scope configured in `workflow.config.json`. Before declaring a scoped change complete, run:

```sh
python3 Scripts/workflow.py run <scope>
```

The command must exit `0`. The runner executes every configured build, unit, integration, and simulator step directly, without prompts. There is no independent-review gate, finding lifecycle, technical-debt gate, remediation decision, or user-decision stage.

A failed, timed-out, interrupted, malformed, or tampered run blocks completion. Fix the cause and start a new run; finalized runs under ignored `.workflow-runs/` are immutable and must not be edited or reused. `workflow.config.json` must be tracked and clean relative to `HEAD` before execution.

## Working-tree protection

Preserve every pre-existing dirty-tree change. Do not reset, overwrite, stage, commit, restore, delete, or reinterpret user-owned changes without explicit instruction. The runner records repository provenance but permits unrelated dirty files. Runner output is confined to ignored `.workflow-runs/`.

## Applicable SwiftUI skills

New or redesigned SwiftUI UI must use the applicable `swiftui-liquid-glass`, `swiftui-ui-patterns`, `pfw-composable-architecture`, `pfw-testing`, and `ios-debugger-agent` skills. Configure the scope to execute the relevant build, unit, integration, and simulator/UI-test commands automatically, including the required iOS deployment target and destination.
