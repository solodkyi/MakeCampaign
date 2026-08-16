import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from Scripts.workflow_runner.config import ConfigError, load_config


def valid_config() -> dict:
    return {
        "schema_version": 1,
        "artifact_root": ".workflow-runs",
        "default_timeout_seconds": 30,
        "max_output_bytes_per_stream": 1024,
        "command_policies": [
            {"id": "python", "argv_prefix": ["python3"]},
        ],
        "scopes": {
            "core/example": {
                "workflow_id": "example-v1",
                "steps": [
                    {
                        "id": "unit-tests",
                        "kind": "unit",
                        "policy": "python",
                        "argv": ["python3", "-c", "print('ok')"],
                        "cwd": ".",
                        "timeout_seconds": 5,
                        "env_from": [],
                    }
                ],
            }
        },
    }


class WorkflowConfigTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.repo = Path(self.temporary.name).resolve()
        self.path = self.repo / "workflow.config.json"

    def tearDown(self):
        self.temporary.cleanup()

    def write(self, value: dict) -> None:
        self.path.write_text(json.dumps(value), encoding="utf-8")

    def test_loads_strict_version_one_configuration(self):
        self.write(valid_config())

        config = load_config(self.path, self.repo)

        self.assertEqual(1, config.schema_version)
        self.assertEqual(("python3",), config.command_policies[0].argv_prefix)
        self.assertEqual("core/example", config.scopes["core/example"].scope)
        self.assertEqual(("python3", "-c", "print('ok')"), config.scopes["core/example"].steps[0].argv)

    def test_rejects_unknown_keys_and_schema_versions(self):
        cases = (
            ("unknown key", lambda value: value.update({"surprise": True})),
            ("schema_version", lambda value: value.update({"schema_version": 2})),
        )
        for expected, mutate in cases:
            value = valid_config()
            mutate(value)
            self.write(value)
            with self.subTest(expected=expected), self.assertRaisesRegex(ConfigError, expected):
                load_config(self.path, self.repo)

    def test_rejects_invalid_scope_duplicate_steps_and_policy_mismatch(self):
        cases = []

        invalid_scope = valid_config()
        invalid_scope["scopes"]["features/Bad Scope"] = invalid_scope["scopes"].pop("core/example")
        cases.append((invalid_scope, "invalid scope"))

        duplicate = valid_config()
        duplicate["scopes"]["core/example"]["steps"].append(
            dict(duplicate["scopes"]["core/example"]["steps"][0])
        )
        cases.append((duplicate, "duplicate step id"))

        mismatch = valid_config()
        mismatch["scopes"]["core/example"]["steps"][0]["argv"] = ["git", "status"]
        cases.append((mismatch, "does not match policy"))

        for value, expected in cases:
            self.write(value)
            with self.subTest(expected=expected), self.assertRaisesRegex(ConfigError, expected):
                load_config(self.path, self.repo)

    def test_rejects_unsafe_paths_invalid_limits_and_missing_environment(self):
        cases = []

        traversal = valid_config()
        traversal["scopes"]["core/example"]["steps"][0]["cwd"] = "../outside"
        cases.append((traversal, "cwd"))

        absolute_artifacts = valid_config()
        absolute_artifacts["artifact_root"] = "/tmp/runs"
        cases.append((absolute_artifacts, "artifact_root"))

        zero_limit = valid_config()
        zero_limit["max_output_bytes_per_stream"] = 0
        cases.append((zero_limit, "max_output_bytes_per_stream"))

        for value, expected in cases:
            self.write(value)
            with self.subTest(expected=expected), self.assertRaisesRegex(ConfigError, expected):
                load_config(self.path, self.repo)

        required_env = valid_config()
        required_env["scopes"]["core/example"]["steps"][0]["env_from"] = ["WORKFLOW_TEST_SECRET"]
        self.write(required_env)
        with patch.dict(os.environ, {}, clear=True):
            with self.assertRaisesRegex(ConfigError, "WORKFLOW_TEST_SECRET"):
                load_config(self.path, self.repo)

    def test_rejects_command_policies_that_authorize_git_mutation(self):
        for prefix in (["git"], ["git", "reset"], ["git", "-C", ".", "status"]):
            value = valid_config()
            value["command_policies"] = [{"id": "unsafe-git", "argv_prefix": prefix}]
            value["scopes"]["core/example"]["steps"][0].update(
                {"policy": "unsafe-git", "argv": prefix}
            )
            self.write(value)
            with self.subTest(prefix=prefix), self.assertRaisesRegex(ConfigError, "unsafe Git policy"):
                load_config(self.path, self.repo)


if __name__ == "__main__":
    unittest.main()
