# MakeCampaign Agent Protocol

Before code changes, initialize the scope and satisfy research, refactoring, implementation, and test-plan gates. Run `python3 Scripts/workflow.py check <scope> --stage planning` before execution and `python3 Scripts/workflow.py check <scope> --stage review` before declaring completion.

## Scope and lifecycle

Valid scope roots are `core/`, `components/`, and `features/`; each scope is a lowercase, hyphen-separated name beneath one of those roots. Every scope follows these ordered records:

- `00-codebase-research`
- `01-refactoring-plan`
- `02-implementation-plan`
- `03-test-plan`
- `04-execution-cycle-N`
- `05-verification-cycle-N`
- `06-review-cycle-N`
- `07-review-decision-cycle-N`
- `08-remediation-plan-cycle-N`
- `09-remediation-test-plan-cycle-N`

The test plan must cover unit, integration, and manual/simulator tests. Build and test failures block progress; record the fix, any plan deviation, and test-plan updates before repeating verification.

## Model routing and review

Planning and independent review use `gpt-5.6-sol`. Implementation, test execution, and routine checks use `gpt-5.6-luna`; Luna escalates ambiguity or nontrivial failures. The review must be performed independently of the implementation work and must record `author_role: independent-reviewer` and `author_model: gpt-5.6-sol`.

P0/P1 findings block completion and require the user's attention. Use the decision and remediation records to document accepted P0/P1 findings, and do not close a scope while any P0/P1 remains open. P2/P3 findings do not block completion but must be recorded in `docs/technical-debt.md` with their identifiers and status.

## Working-tree protection and applicable skills

Preserve every pre-existing dirty-tree change. Do not reset, overwrite, stage, or reinterpret user-owned changes without explicit instruction. Workflow evidence belongs under the ignored local `docs/` directory; only this protocol and the validator/templates are tracked.

New or redesigned SwiftUI UI must use the applicable `swiftui-liquid-glass`, `swiftui-ui-patterns`, `pfw-composable-architecture`, `pfw-testing`, and `ios-debugger-agent` skills, with the iOS deployment target and simulator evidence recorded in the scope documents when relevant.
