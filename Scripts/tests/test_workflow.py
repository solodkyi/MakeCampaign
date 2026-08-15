import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]


class WorkflowContractTests(unittest.TestCase):
    def test_repository_contract(self):
        contract = (REPOSITORY_ROOT / "AGENTS.md").read_text(encoding="utf-8")

        self.assertIn("python3 Scripts/workflow.py", contract)
        for scope_root in ("core/", "components/", "features/"):
            self.assertIn(scope_root, contract)

        lifecycle_records = (
            "00-codebase-research",
            "01-refactoring-plan",
            "02-implementation-plan",
            "03-test-plan",
            "04-execution-cycle-N",
            "05-verification-cycle-N",
            "06-review-cycle-N",
            "07-review-decision-cycle-N",
            "08-remediation-plan-cycle-N",
            "09-remediation-test-plan-cycle-N",
        )
        for record in lifecycle_records:
            self.assertIn(record, contract)

        self.assertRegex(contract, r"P0/P1.{0,120}(block|attention|open)")
        self.assertRegex(contract, r"P2/P3.{0,120}(technical debt|debt)")
        self.assertIn("gpt-5.6-sol", contract)
        self.assertIn("gpt-5.6-luna", contract)

        for required_skill in (
            "swiftui-liquid-glass",
            "swiftui-ui-patterns",
            "pfw-composable-architecture",
            "pfw-testing",
            "ios-debugger-agent",
        ):
            self.assertIn(required_skill, contract)


if __name__ == "__main__":
    unittest.main()
