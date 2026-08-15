import json
import tempfile
import unittest
from pathlib import Path

from Scripts.workflow_runner.artifacts import ArtifactError, ArtifactStore, verify_run
from Scripts.workflow_runner.models import (
    RepositoryState,
    RunStatus,
    ScopeConfig,
    StepConfig,
    StepKind,
    StepResult,
    StepStatus,
)


def scope() -> ScopeConfig:
    return ScopeConfig(
        scope="core/example",
        workflow_id="example-v1",
        steps=(
            StepConfig(
                identifier="unit-tests",
                kind=StepKind.UNIT,
                policy="python",
                argv=("python3", "-c", "print('ok')"),
                cwd=Path("."),
                timeout_seconds=5,
                env_from=(),
                required_artifacts=(),
            ),
        ),
    )


class WorkflowArtifactTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.repository = RepositoryState("a" * 40, True, "?? notes.txt\n", "b" * 64)

    def tearDown(self):
        self.temporary.cleanup()

    def create_store(self) -> ArtifactStore:
        return ArtifactStore.create(
            self.root,
            scope(),
            Path("workflow.config.json"),
            "c" * 64,
            self.repository,
        )

    def finalize_success(self) -> ArtifactStore:
        store = self.create_store()
        stdout_path, stderr_path = store.start_step("unit-tests")
        stdout_path.write_bytes(b"ok\n")
        stderr_path.write_bytes(b"")
        store.finish_step(
            StepResult(
                identifier="unit-tests",
                status=StepStatus.PASSED,
                exit_code=0,
                timed_out=False,
                started_at="2026-08-15T10:00:00Z",
                finished_at="2026-08-15T10:00:01Z",
                duration_ms=1000,
                stdout_bytes=3,
                stderr_bytes=0,
                stdout_truncated=False,
                stderr_truncated=False,
            )
        )
        store.finalize(RunStatus.PASSED, 0)
        return store

    def test_finalizes_verifiable_immutable_run(self):
        store = self.finalize_success()

        manifest = json.loads((store.path / "run.json").read_text(encoding="utf-8"))
        self.assertEqual("passed", manifest["status"])
        self.assertEqual("passed", manifest["steps"][0]["status"])
        self.assertEqual(64, len(manifest["steps"][0]["stdout_sha256"]))
        self.assertEqual([], verify_run(store.path))
        self.assertFalse(any(path.suffix == ".tmp" for path in store.path.iterdir()))
        with self.assertRaisesRegex(ArtifactError, "finalized"):
            store.start_step("unit-tests")

    def test_tamper_detection_and_unique_runs(self):
        first = self.create_store()
        first.skip_steps(("unit-tests",))
        first.finalize(RunStatus.FAILED, 3)
        second = self.create_store()
        self.assertNotEqual(first.path, second.path)

        manifest_path = first.path / "run.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        manifest["runner_exit_code"] = 0
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")

        errors = verify_run(first.path)
        self.assertTrue(any("failed run" in error for error in errors), errors)

    def test_verify_rejects_incomplete_event_stream(self):
        store = self.finalize_success()
        (store.path / "events.jsonl").write_text("", encoding="utf-8")

        errors = verify_run(store.path)

        self.assertTrue(any("events" in error for error in errors), errors)

    def test_verify_rejects_incorrect_stored_byte_count(self):
        store = self.finalize_success()
        manifest_path = store.path / "run.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        manifest["steps"][0]["stdout_stored_bytes"] = 999
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")

        errors = verify_run(store.path)

        self.assertTrue(any("stored byte count" in error for error in errors), errors)


if __name__ == "__main__":
    unittest.main()
