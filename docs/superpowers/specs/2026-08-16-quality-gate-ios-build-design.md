# Quality Gate iOS Build Design

## Goal

Make the automatic workflow prove that the MakeCampaign iOS app compiles for its supported Debug device target.

## Design

Add a narrowly scoped `xcodebuild` command policy and an `ios-build` build step to the existing `core/development-workflow-harness-redesign` scope. The command builds the `MakeCampaign` scheme in Debug for `generic/platform=iOS`, which avoids simulator availability while exercising package resolution, compilation, linking, signing, and app validation.

The step runs after the Python workflow tests and before the existing diff check. The repository workflow test will assert the parsed step order and complete build command, preventing a future edit from silently removing the build from the gate.

## Constraints

- Retain all existing Python tests and the diff check.
- Do not alter user-owned working-tree files.
- Run the final workflow with the Xcode environment permitted to access its SwiftPM and compiler caches.
