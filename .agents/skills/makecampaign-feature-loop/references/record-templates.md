# Workflow Record Templates

Use one ignored directory: `docs/<category>/<scope-name>/`. Preserve history by appending corrections and deviations rather than rewriting evidence that explains an executed decision.

## `00-codebase-research.md`

```markdown
# <Title> — Codebase Research

## Source explanation
<All user-provided goals, examples, constraints, acceptance criteria, and exclusions>

## Scope
- Workflow scope: `<category>/<name>`
- Starting branch/commit: ...
- Pre-existing working-tree changes preserved: ...

## Decisions
- ...

## Open questions
- None | question, significance, recommendation, answer/status

## Existing implementation
- Flow and architecture: ...
- Relevant files/tests: ...
- Reusable components/patterns: ...

## Findings and risks
- Evidence: ...
- Plan/test implication: ...

## Gates
- Initial challenge complete: yes/no
- Research challenge complete: yes/no
```

## `01-refactoring-plan.md`

```markdown
# <Title> — Refactoring Plan

## Goal and preserved behavior
## Existing constraints
## File-level changes
## Interfaces and dependencies
## Migration/compatibility
## Risks and controls
## Acceptance criteria
```

## `02-implementation-plan.md`

```markdown
# <Title> — Implementation Plan

## Goal, architecture, and scope boundaries
## Requirement-to-task coverage
### Task N: <independently testable result>
- Files: create/modify/test exact paths
- Inputs/outputs and dependencies
- Failing test and expected failure
- Minimal implementation
- Focused and integration verification
- [ ] Completed
```

## `03-test-plan.md`

```markdown
# <Title> — Test Plan

## Unit tests
## Integration tests
## Simulator/UI tests
## Negative and edge cases
## Manual verification
## Failure-derived updates
- None | date/run, failure, new regression coverage
```

## `plan-deviations.md`

```markdown
# <Title> — Plan Deviations

None.

## <Timestamp or sequence> — <summary>
- Trigger/evidence: ...
- Original plan: ...
- Actual change and files: ...
- Risk: ...
- Test-plan update: ...
```

Replace `None` with the first deviation; never erase earlier entries.

## `04-completion-handoff.md`

Use [handoff-template.md](handoff-template.md). It is written only after a fresh successful workflow run.
