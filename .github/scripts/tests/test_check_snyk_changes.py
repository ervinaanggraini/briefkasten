import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

SCRIPT_PATH = Path(__file__).resolve().parent.parent / "check-snyk-changes.py"
SPEC = importlib.util.spec_from_file_location("check_snyk_changes", SCRIPT_PATH)
assert SPEC is not None and SPEC.loader is not None
MOD = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MOD)


class CheckSnykDependenciesTests(unittest.TestCase):
    def test_no_new_vulnerabilities_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base_dir = Path(tmp) / "baseline"
            base_file = Path(tmp) / "base.json"
            curr_file = Path(tmp) / "curr.json"

            base_payload = [
                {
                    "displayTargetFile": f"{base_dir}/apps/web/package.json",
                    "vulnerabilities": [
                        {"id": "SNYK-JS-1", "packageName": "foo", "severity": "high", "title": "Old vuln"}
                    ],
                }
            ]
            curr_payload = [
                {
                    "displayTargetFile": "apps/web/package.json",
                    "vulnerabilities": [
                        {"id": "SNYK-JS-1", "packageName": "foo", "severity": "high", "title": "Old vuln"}
                    ],
                }
            ]
            base_file.write_text(json.dumps(base_payload), encoding="utf-8")
            curr_file.write_text(json.dumps(curr_payload), encoding="utf-8")

            self.assertEqual(MOD.check_dependencies(str(base_file), str(base_dir), str(curr_file)), 0)

    def test_new_vulnerability_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base_dir = Path(tmp) / "baseline"
            base_file = Path(tmp) / "base.json"
            curr_file = Path(tmp) / "curr.json"

            base_file.write_text("[]", encoding="utf-8")
            curr_payload = {
                "displayTargetFile": "apps/backend/package.json",
                "vulnerabilities": [
                    {"id": "SNYK-JS-2", "packageName": "bar", "severity": "critical", "title": "New vuln"}
                ],
            }
            curr_file.write_text(json.dumps(curr_payload), encoding="utf-8")

            self.assertEqual(MOD.check_dependencies(str(base_file), str(base_dir), str(curr_file)), 1)

    def test_empty_files_pass(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base_file = Path(tmp) / "base.json"
            curr_file = Path(tmp) / "curr.json"
            base_file.write_text("", encoding="utf-8")
            curr_file.write_text("", encoding="utf-8")

            self.assertEqual(MOD.check_dependencies(str(base_file), tmp, str(curr_file)), 0)


class CheckSnykCodeTests(unittest.TestCase):
    def test_finding_in_changed_file_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            sarif_file = Path(tmp) / "snyk.sarif"
            sarif = {
                "runs": [
                    {
                        "results": [
                            {
                                "ruleId": "javascript/XSS",
                                "message": {"text": "Potential XSS"},
                                "locations": [
                                    {
                                        "physicalLocation": {
                                            "artifactLocation": {"uri": "apps/web/src/routes/login/+page.svelte"},
                                            "region": {"startLine": 42},
                                        }
                                    }
                                ],
                            }
                        ]
                    }
                ]
            }
            sarif_file.write_text(json.dumps(sarif), encoding="utf-8")

            code = MOD.check_code(
                str(sarif_file),
                "HEAD~1",
                changed={"apps/web/src/routes/login/+page.svelte"},
            )
            self.assertEqual(code, 1)

    def test_finding_only_in_untouched_file_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            sarif_file = Path(tmp) / "snyk.sarif"
            sarif = {
                "runs": [
                    {
                        "results": [
                            {
                                "ruleId": "javascript/XSS",
                                "message": {"text": "Old issue"},
                                "locations": [
                                    {
                                        "physicalLocation": {
                                            "artifactLocation": {"uri": "apps/web/src/old.ts"},
                                            "region": {"startLine": 10},
                                        }
                                    }
                                ],
                            }
                        ]
                    }
                ]
            }
            sarif_file.write_text(json.dumps(sarif), encoding="utf-8")

            with mock.patch.object(MOD, "_changed_files", return_value={"apps/web/src/new.ts"}):
                self.assertEqual(MOD.check_code(str(sarif_file), "HEAD~1"), 0)

    def test_main_invalid_args_returns_2(self) -> None:
        self.assertEqual(MOD.main(["unknown"]), 2)


if __name__ == "__main__":
    unittest.main()
