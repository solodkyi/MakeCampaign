import json
import os
import sys
import tempfile
import unittest
from pathlib import Path

from Scripts.workflow_runner.artifacts import ArtifactStore
from Scripts.workflow_runner.executor import execute_workflow
from Scripts.workflow_runner.models import (
    CommandPolicy,
    RepositoryState,
    RunnerConfig,
    ScopeConfig,
    StepConfig,
    StepKind,
)


class WorkflowExecutorTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.repo = Path(self.temporary.name).resolve()
        self.repository = RepositoryState("a" * 40, False, "", "b" * 64)

    def tearDown(self):
        self.temporary.cleanup()

    def run_steps(self, steps: tuple[StepConfig, ...], *, limit: int = 4096):
        scope = ScopeConfig("core/example", "example-v1", steps)
        config = RunnerConfig(
            schema_version=1,
            source_path=self.repo / "workflow.config.json",
            repository_root=self.repo,
            artifact_root=Path(".workflow-runs"),
            default_timeout_seconds=5,
            max_output_bytes_per_stream=limit,
            command_policies=(CommandPolicy("python", (sys.executable,)),),
            scopes={scope.scope: scope},
        )
        store = ArtifactStore.create(
            self.repo / config.artifact_root,
            scope,
            Path("workflow.config.json"),
            "c" * 64,
            self.repository,
        )
        exit_code = execute_workflow(
            config,
            scope,
            store,
            {**os.environ, "UNDECLARED_WORKFLOW_VALUE": "hidden"},
        )
        manifest = json.loads((store.path / "run.json").read_text(encoding="utf-8"))
        return exit_code, store, manifest

    def step(self, identifier: str, code: str, *arguments: str, timeout: int = 5) -> StepConfig:
        return StepConfig(
            identifier=identifier,
            kind=StepKind.UNIT,
            policy="python",
            argv=(sys.executable, "-c", code, *arguments),
            cwd=Path("."),
            timeout_seconds=timeout,
            env_from=(),
            required_artifacts=(),
        )

    def test_passes_literal_arguments_and_uses_minimal_environment(self):
        literal = "$(touch should-not-exist);*.txt `whoami`"
        code = (
            "import os,sys; "
            "print(sys.argv[1]); "
            "print(os.getenv('UNDECLARED_WORKFLOW_VALUE', 'absent')); "
            "print(os.getenv('CI'))"
        )

        exit_code, store, manifest = self.run_steps((self.step("literal", code, literal),))

        self.assertEqual(0, exit_code)
        self.assertEqual("passed", manifest["status"])
        output = (store.path / manifest["steps"][0]["stdout_log"]).read_text(encoding="utf-8")
        self.assertEqual(f"{literal}\nabsent\n1\n", output)
        self.assertFalse((self.repo / "should-not-exist").exists())

    def test_fails_fast_and_marks_later_steps_skipped(self):
        marker = self.repo / "must-not-run"
        failing = self.step("fails", "raise SystemExit(7)")
        later = self.step("later", "from pathlib import Path; Path('must-not-run').touch()")

        exit_code, _, manifest = self.run_steps((failing, later))

        self.assertEqual(3, exit_code)
        self.assertEqual(["failed", "skipped"], [step["status"] for step in manifest["steps"]])
        self.assertEqual(7, manifest["steps"][0]["exit_code"])
        self.assertFalse(marker.exists())

    def test_times_out_process_and_bounds_both_logs(self):
        timeout_step = self.step("timeout", "import time; time.sleep(10)", timeout=1)
        exit_code, _, manifest = self.run_steps((timeout_step,))
        self.assertEqual(4, exit_code)
        self.assertEqual("timed_out", manifest["steps"][0]["status"])

        noisy = self.step(
            "noisy",
            "import sys; print('o' * 5000); print('e' * 5000, file=sys.stderr)",
        )
        exit_code, store, manifest = self.run_steps((noisy,), limit=100)
        step = manifest["steps"][0]
        self.assertEqual(0, exit_code)
        self.assertGreater(step["stdout_bytes"], 5000)
        self.assertGreater(step["stderr_bytes"], 5000)
        self.assertEqual(100, step["stdout_stored_bytes"])
        self.assertEqual(100, step["stderr_stored_bytes"])
        self.assertTrue(step["stdout_truncated"])
        self.assertTrue(step["stderr_truncated"])
        self.assertEqual(100, (store.path / step["stdout_log"]).stat().st_size)

    def test_missing_required_artifact_fails_without_exceeding_log_limit(self):
        step = StepConfig(
            identifier="artifact",
            kind=StepKind.INTEGRATION,
            policy="python",
            argv=(sys.executable, "-c", "import sys; print('e' * 5000, file=sys.stderr)"),
            cwd=Path("."),
            timeout_seconds=5,
            env_from=(),
            required_artifacts=(Path("missing.result"),),
        )

        exit_code, store, manifest = self.run_steps((step,), limit=100)

        result = manifest["steps"][0]
        self.assertEqual(3, exit_code)
        self.assertEqual("failed", result["status"])
        self.assertLessEqual((store.path / result["stderr_log"]).stat().st_size, 100)
        self.assertTrue(result["stderr_truncated"])


if __name__ == "__main__":
    unittest.main()
