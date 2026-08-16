import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]


class WorkflowCLITests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.repo = Path(self.temporary.name).resolve()
        scripts = self.repo / "Scripts"
        scripts.mkdir()
        shutil.copy2(REPOSITORY_ROOT / "Scripts/workflow.py", scripts / "workflow.py")
        shutil.copytree(REPOSITORY_ROOT / "Scripts/workflow_runner", scripts / "workflow_runner")
        self.write_config()
        self.git("init", "-q")
        self.git("config", "user.email", "workflow@example.test")
        self.git("config", "user.name", "Workflow Test")
        self.git("add", "workflow.config.json")
        self.git("commit", "-qm", "configuration")

    def tearDown(self):
        self.temporary.cleanup()

    def write_config(self) -> None:
        value = {
            "schema_version": 1,
            "artifact_root": ".workflow-runs",
            "default_timeout_seconds": 30,
            "max_output_bytes_per_stream": 4096,
            "command_policies": [{"id": "python", "argv_prefix": ["python3"]}],
            "scopes": {
                "core/passing": {
                    "workflow_id": "passing-v1",
                    "steps": [
                        {
                            "id": "first",
                            "kind": "unit",
                            "policy": "python",
                            "argv": ["python3", "-c", "print('first')"],
                            "cwd": ".",
                            "timeout_seconds": 5,
                            "env_from": [],
                        },
                        {
                            "id": "second",
                            "kind": "integration",
                            "policy": "python",
                            "argv": ["python3", "-c", "print('second')"],
                            "cwd": ".",
                            "timeout_seconds": 5,
                            "env_from": [],
                        },
                    ],
                },
                "core/failing": {
                    "workflow_id": "failing-v1",
                    "steps": [
                        {
                            "id": "failure",
                            "kind": "unit",
                            "policy": "python",
                            "argv": ["python3", "-c", "raise SystemExit(9)"],
                            "cwd": ".",
                            "timeout_seconds": 5,
                            "env_from": [],
                        }
                    ],
                },
            },
        }
        (self.repo / "workflow.config.json").write_text(json.dumps(value), encoding="utf-8")

    def git(self, *arguments: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["git", *arguments], cwd=self.repo, text=True, capture_output=True, check=True
        )

    def cli(self, *arguments: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["python3", "Scripts/workflow.py", *arguments],
            cwd=self.repo,
            text=True,
            capture_output=True,
            check=False,
        )

    def artifact_from(self, result: subprocess.CompletedProcess[str]) -> Path:
        values = dict(line.split("=", 1) for line in result.stdout.splitlines() if "=" in line)
        return self.repo / values["artifact"]

    def test_validate_run_status_and_verify_are_noninteractive(self):
        validation = self.cli("validate-config")
        self.assertEqual(0, validation.returncode, validation.stderr)

        result = self.cli("run", "core/passing")
        self.assertEqual(0, result.returncode, result.stderr)
        artifact = self.artifact_from(result)
        self.assertTrue(artifact.is_dir())

        status = self.cli("status", "core/passing", "--run", "latest", "--json")
        self.assertEqual(0, status.returncode, status.stderr)
        manifest = json.loads(status.stdout)
        self.assertEqual("passed", manifest["status"])
        self.assertEqual(["passed", "passed"], [step["status"] for step in manifest["steps"]])

        verification = self.cli("verify-run", str(artifact.relative_to(self.repo)))
        self.assertEqual(0, verification.returncode, verification.stderr)

    def test_failed_run_is_recorded_and_reruns_are_immutable(self):
        failure = self.cli("run", "core/failing")
        self.assertEqual(3, failure.returncode)
        failed_artifact = self.artifact_from(failure)
        failed_before = {path.relative_to(failed_artifact): path.read_bytes() for path in failed_artifact.rglob("*") if path.is_file()}

        first = self.cli("run", "core/passing")
        second = self.cli("run", "core/passing")
        self.assertEqual(0, first.returncode, first.stderr)
        self.assertEqual(0, second.returncode, second.stderr)
        self.assertNotEqual(self.artifact_from(first), self.artifact_from(second))
        failed_after = {path.relative_to(failed_artifact): path.read_bytes() for path in failed_artifact.rglob("*") if path.is_file()}
        self.assertEqual(failed_before, failed_after)

    def test_preflight_and_legacy_fail_without_creating_runs(self):
        legacy = self.cli("check", "core/passing", "--stage", "review")
        self.assertEqual(2, legacy.returncode)
        self.assertIn("legacy workflow command removed", legacy.stderr)

        config = self.repo / "workflow.config.json"
        config.write_text(config.read_text(encoding="utf-8") + "\n", encoding="utf-8")
        result = self.cli("run", "core/passing")
        self.assertEqual(2, result.returncode)
        self.assertIn("clean", result.stderr)
        self.assertFalse((self.repo / ".workflow-runs").exists())


if __name__ == "__main__":
    unittest.main()
