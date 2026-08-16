# Quality Gate iOS Build Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Require a successful Debug iOS build in the automatic workflow gate.

**Architecture:** The declarative workflow configuration gains one allowlisted Xcode command and one build step. The existing repository-level workflow test verifies the loaded configuration contract, and the workflow runner executes the command.

**Tech Stack:** Python 3 unittest, JSON workflow configuration, Xcode `xcodebuild`.

## Global Constraints

- The scope is `core/development-workflow-harness-redesign`.
- The build command is `xcodebuild -project MakeCampaign.xcodeproj -scheme MakeCampaign -configuration Debug -destination generic/platform=iOS build`.
- The final validation is `python3 Scripts/workflow.py run core/development-workflow-harness-redesign` with Xcode cache access.

---

### Task 1: Require the iOS build in the workflow scope

**Files:**
- Modify: `Scripts/tests/test_workflow.py`
- Modify: `workflow.config.json`

**Interfaces:**
- Consumes: `load_config(path, repo) -> RunnerConfig`.
- Produces: the `ios-build` configured `StepConfig` in the existing scope.

- [ ] **Step 1: Write the failing test**

Extend `test_repository_configuration_defines_fully_automatic_harness_scope` to expect the step IDs `("python-tests", "ios-build", "diff-check")` and the literal Xcode argv tuple.

- [ ] **Step 2: Run test to verify it fails**

Run: `python3 -m unittest Scripts.tests.test_workflow.RepositoryWorkflowTests.test_repository_configuration_defines_fully_automatic_harness_scope -v`

Expected: FAIL because `ios-build` is absent from the loaded configuration.

- [ ] **Step 3: Write minimal implementation**

Add the `xcodebuild` command policy and configure `ios-build` with the stated Debug generic-iOS command, a 1,200-second timeout, and no additional environment variables.

- [ ] **Step 4: Run test to verify it passes**

Run: `python3 -m unittest Scripts.tests.test_workflow.RepositoryWorkflowTests.test_repository_configuration_defines_fully_automatic_harness_scope -v`

Expected: PASS.

- [ ] **Step 5: Run the full quality gate**

Run: `python3 Scripts/workflow.py run core/development-workflow-harness-redesign`

Expected: every step, including `ios-build`, exits 0.
