import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
SKILL_ROOT = REPOSITORY_ROOT / ".agents" / "skills" / "makecampaign-feature-loop"


class FeatureLoopSkillTests(unittest.TestCase):
    def test_skill_defines_the_complete_gated_loop(self):
        skill = (SKILL_ROOT / "SKILL.md").read_text(encoding="utf-8")

        ordered_markers = [
            "## 1. Intake and scope",
            "## 2. Initial challenge gate",
            "## 3. Existing-code research",
            "## 4. Research challenge gate",
            "## 5. Planning gates",
            "## 6. Implementation and tests",
            "## 7. Automatic verification and repair loop",
            "## 8. Completion handoff",
        ]
        positions = [skill.index(marker) for marker in ordered_markers]
        self.assertEqual(sorted(positions), positions)

        for required in (
            "python3 Scripts/workflow.py run <scope>",
            "plan-deviations.md",
            "full changes list",
            "manual verification checklist",
            "Do not implement",
            "fresh workflow run",
        ):
            self.assertIn(required, skill)

    def test_skill_is_explicit_only_and_discoverable(self):
        skill = (SKILL_ROOT / "SKILL.md").read_text(encoding="utf-8")
        metadata = (SKILL_ROOT / "agents" / "openai.yaml").read_text(encoding="utf-8")

        self.assertIn("name: makecampaign-feature-loop", skill)
        self.assertIn("allow_implicit_invocation: false", metadata)
        self.assertIn("$makecampaign-feature-loop", metadata)

    def test_skill_provides_record_and_handoff_templates(self):
        records = (SKILL_ROOT / "references" / "record-templates.md").read_text(
            encoding="utf-8"
        )
        handoff = (SKILL_ROOT / "references" / "handoff-template.md").read_text(
            encoding="utf-8"
        )

        for filename in (
            "00-codebase-research.md",
            "01-refactoring-plan.md",
            "02-implementation-plan.md",
            "03-test-plan.md",
            "plan-deviations.md",
            "04-completion-handoff.md",
        ):
            self.assertIn(filename, records)
        self.assertIn("Full changes list", handoff)
        self.assertIn("Manual verification checklist", handoff)

    def test_repository_protocol_exposes_skill_and_keeps_runner_gate(self):
        protocol = (REPOSITORY_ROOT / "AGENTS.md").read_text(encoding="utf-8")

        self.assertIn("$makecampaign-feature-loop", protocol)
        self.assertIn("python3 Scripts/workflow.py run <scope>", protocol)


if __name__ == "__main__":
    unittest.main()
