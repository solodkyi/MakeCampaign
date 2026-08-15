import subprocess
import unittest
from pathlib import Path

from Scripts.workflow_runner.config import load_config


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]


class RepositoryWorkflowTests(unittest.TestCase):
    def test_repository_configuration_defines_fully_automatic_harness_scope(self):
        config = load_config(REPOSITORY_ROOT / "workflow.config.json", REPOSITORY_ROOT)
        scope = config.scopes["core/development-workflow-harness-redesign"]

        self.assertEqual("automatic-workflow-runner-v1", scope.workflow_id)
        self.assertEqual(("python-tests", "diff-check"), tuple(step.identifier for step in scope.steps))
        self.assertEqual(
            ("python3", "-m", "unittest", "discover", "-s", "Scripts/tests", "-p", "test_*.py", "-v"),
            scope.steps[0].argv,
        )
        self.assertEqual(("git", "diff", "--check"), scope.steps[1].argv)

    def test_generated_runner_artifacts_are_ignored(self):
        for path in (
            ".workflow-runs/core/example/run.json",
            "Scripts/workflow_runner/__pycache__/models.cpython-314.pyc",
        ):
            result = subprocess.run(
                ["git", "check-ignore", "-q", path],
                cwd=REPOSITORY_ROOT,
                check=False,
            )
            with self.subTest(path=path):
                self.assertEqual(0, result.returncode)


if __name__ == "__main__":
    unittest.main()
