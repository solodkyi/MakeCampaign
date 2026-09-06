import subprocess
import unittest
from pathlib import Path

from Scripts.workflow_runner.config import load_config


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]


class RepositoryWorkflowTests(unittest.TestCase):
    def test_repository_xcode_workflows_skip_macro_validation(self):
        config = load_config(REPOSITORY_ROOT / "workflow.config.json", REPOSITORY_ROOT)
        xcode_steps = [
            (scope_name, step)
            for scope_name, scope in config.scopes.items()
            for step in scope.steps
            if step.argv and step.argv[0] == "xcodebuild"
        ]

        self.assertTrue(xcode_steps)
        for scope_name, step in xcode_steps:
            with self.subTest(scope=scope_name, step=step.identifier):
                self.assertIn("-skipMacroValidation", step.argv)

    def test_repository_simulator_workflows_use_required_runtime(self):
        config = load_config(REPOSITORY_ROOT / "workflow.config.json", REPOSITORY_ROOT)
        simulator_destinations = [
            step.argv[step.argv.index("-destination") + 1]
            for scope in config.scopes.values()
            for step in scope.steps
            if "-destination" in step.argv
            and step.argv[step.argv.index("-destination") + 1].startswith(
                "platform=iOS Simulator"
            )
        ]

        self.assertTrue(simulator_destinations)
        self.assertEqual(
            {"platform=iOS Simulator,name=iPhone 17 Pro,OS=26.3.1"},
            set(simulator_destinations),
        )

    def test_repository_configuration_defines_fully_automatic_harness_scope(self):
        config = load_config(REPOSITORY_ROOT / "workflow.config.json", REPOSITORY_ROOT)
        scope = config.scopes["core/development-workflow-harness-redesign"]

        self.assertEqual("automatic-workflow-runner-v1", scope.workflow_id)
        self.assertEqual(("python-tests", "ios-build", "diff-check"), tuple(step.identifier for step in scope.steps))
        self.assertEqual(
            ("python3", "-m", "unittest", "discover", "-s", "Scripts/tests", "-p", "test_*.py", "-v"),
            scope.steps[0].argv,
        )
        self.assertEqual(
            (
                "xcodebuild",
                "-project",
                "MakeCampaign.xcodeproj",
                "-scheme",
                "MakeCampaign",
                "-configuration",
                "Debug",
                "-destination",
                "generic/platform=iOS",
                "build",
                "-skipMacroValidation",
            ),
            scope.steps[1].argv,
        )
        self.assertEqual(("git", "diff", "--check"), scope.steps[2].argv)

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
