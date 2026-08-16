import json
import subprocess
import tempfile
import unittest
from pathlib import Path

from Scripts.workflow_runner.repository import (
    RepositoryError,
    discover_repository,
    read_repository_state,
    require_clean_tracked_config,
    resolve_confined,
)


class WorkflowRepositoryTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.repo = Path(self.temporary.name).resolve()
        self.git("init", "-q")
        self.git("config", "user.email", "workflow@example.test")
        self.git("config", "user.name", "Workflow Test")
        self.config = self.repo / "workflow.config.json"
        self.config.write_text(json.dumps({"schema_version": 1}), encoding="utf-8")
        self.git("add", "workflow.config.json")
        self.git("commit", "-qm", "initial")

    def tearDown(self):
        self.temporary.cleanup()

    def git(self, *arguments: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["git", *arguments], cwd=self.repo, text=True, capture_output=True, check=True
        )

    def test_discovers_repository_and_confines_paths(self):
        nested = self.repo / "nested" / "child"
        nested.mkdir(parents=True)

        self.assertEqual(self.repo, discover_repository(nested))
        self.assertEqual(self.repo / "nested", resolve_confined(self.repo, "nested"))
        with self.assertRaisesRegex(RepositoryError, "repository"):
            resolve_confined(self.repo, "../outside")

        outside = Path(self.temporary.name).parent / f"{self.repo.name}-outside"
        outside.mkdir(exist_ok=True)
        symlink = self.repo / "escape"
        symlink.symlink_to(outside, target_is_directory=True)
        try:
            with self.assertRaisesRegex(RepositoryError, "repository"):
                resolve_confined(self.repo, "escape/file")
        finally:
            symlink.unlink()
            outside.rmdir()

    def test_requires_configuration_to_be_tracked_and_clean(self):
        require_clean_tracked_config(self.repo, self.config)

        self.config.write_text("changed", encoding="utf-8")
        with self.assertRaisesRegex(RepositoryError, "clean"):
            require_clean_tracked_config(self.repo, self.config)

        self.git("restore", "workflow.config.json")
        untracked = self.repo / "other.json"
        untracked.write_text("{}", encoding="utf-8")
        with self.assertRaisesRegex(RepositoryError, "tracked"):
            require_clean_tracked_config(self.repo, untracked)

    def test_records_unrelated_dirty_state_without_changing_it(self):
        dirty = self.repo / "notes.txt"
        dirty.write_text("user work", encoding="utf-8")
        before = self.git("status", "--porcelain=v1").stdout

        state = read_repository_state(self.repo)

        self.assertTrue(state.dirty)
        self.assertEqual(before, state.status)
        self.assertEqual(64, len(state.status_sha256))
        self.assertEqual(before, self.git("status", "--porcelain=v1").stdout)


if __name__ == "__main__":
    unittest.main()
