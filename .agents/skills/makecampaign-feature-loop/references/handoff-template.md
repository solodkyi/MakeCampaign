# Completion Handoff Template

```markdown
# <Title> — Completion Handoff

## Delivered outcome
- Scope: `<category>/<name>`
- User-visible behavior: ...
- Preserved/non-goals: ...

## Full changes list
- `<path>` — exact behavior or responsibility changed
- `<test path>` — regression/acceptance behavior covered
- `<record path>` — decision or evidence captured

## Decisions and deviations
- Accepted decisions: ...
- Plan deviations: None | summary and link to `plan-deviations.md`

## Automated verification
- Focused checks: command — result
- Full configured scope: `python3 Scripts/workflow.py run <scope>` — exit 0
- Successful immutable run: `<.workflow-runs/...>`
- Configured step results: build/unit/integration/simulator

## Manual verification checklist

Prerequisites: device/simulator, OS, account/data state, permissions.

- [ ] Action: ...
  Expected: ...
- [ ] Action: ...
  Expected: ...
- [ ] Accessibility/localization/appearance check: ...
  Expected: ...

## Known limitations and follow-ups
- None | nonblocking item, impact, suggested follow-up

## Workspace preservation
- Pre-existing unrelated changes observed at start: ...
- Confirmation they were not reset, overwritten, staged, committed, or included as this scope's work: ...
```

The user-facing response must contain the same outcome, Full changes list, automated evidence, and Manual verification checklist. Do not make the user open this record to understand whether the work is complete.
