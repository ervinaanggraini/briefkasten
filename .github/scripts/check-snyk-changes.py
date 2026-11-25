#!/usr/bin/env python3
"""Compare Snyk Open Source and Snyk Code findings against a Git baseline."""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any


def _load_json(path: str) -> Any:
    content = Path(path).read_text(encoding="utf-8").strip()
    if not content:
        return []
    return json.loads(content)


def _normalize_project_path(raw_path: str, root_dir: str) -> str:
    if not raw_path:
        return ""
    resolved_root = os.path.normpath(root_dir).replace("\\", "/").rstrip("/")
    normalized = os.path.normpath(raw_path).replace("\\", "/")
    if resolved_root and normalized.startswith(resolved_root + "/"):
        return normalized[len(resolved_root) + 1 :]
    if resolved_root and normalized == resolved_root:
        return "."
    return normalized.lstrip("./")


def _extract_dependency_vulns(data: Any, root_dir: str) -> dict[tuple[str, str, str], dict[str, str]]:
    projects = data if isinstance(data, list) else [data] if isinstance(data, dict) else []
    findings: dict[tuple[str, str, str], dict[str, str]] = {}

    for project in projects:
        if not isinstance(project, dict):
            continue
        raw_target = project.get("displayTargetFile") or project.get("targetFile") or project.get("path") or ""
        target = _normalize_project_path(str(raw_target), root_dir)
        vulns = project.get("vulnerabilities")
        if not isinstance(vulns, list):
            continue
        for vuln in vulns:
            if not isinstance(vuln, dict):
                continue
            vuln_id = str(vuln.get("id") or "")
            pkg = str(vuln.get("packageName") or vuln.get("name") or "")
            if not vuln_id:
                continue
            key = (target, vuln_id, pkg)
            findings[key] = {
                "target": target or "unknown",
                "id": vuln_id,
                "package": pkg or "unknown",
                "severity": str(vuln.get("severity") or "unknown").upper(),
                "title": str(vuln.get("title") or vuln_id),
            }

    return findings


def check_dependencies(base_json_path: str, baseline_dir: str, current_json_path: str) -> int:
    base_data = _load_json(base_json_path)
    current_data = _load_json(current_json_path)

    base_vulns = _extract_dependency_vulns(base_data, baseline_dir)
    current_vulns = _extract_dependency_vulns(current_data, os.getcwd())

    new_keys = sorted(set(current_vulns.keys()) - set(base_vulns.keys()))
    if not new_keys:
        print(f"No new Snyk dependency vulnerabilities introduced ({len(current_vulns)} baseline/total).")
        return 0

    for key in new_keys:
        item = current_vulns[key]
        print(
            f"::error file={item['target']}::New Snyk dependency vulnerability "
            f"[{item['severity']}] {item['id']} in {item['package']}: {item['title']}"
        )
    return 1


def _changed_files(base_sha: str) -> set[str]:
    result = subprocess.run(
        ["git", "diff", "--name-only", "--diff-filter=ACMRT", base_sha, "HEAD"],
        capture_output=True,
        text=True,
        check=True,
    )
    return {line.strip().replace("\\", "/") for line in result.stdout.splitlines() if line.strip()}


def check_code(sarif_path: str, base_sha: str, changed: set[str] | None = None) -> int:
    sarif = _load_json(sarif_path)
    if not isinstance(sarif, dict):
        return 0

    touched_files = changed if changed is not None else _changed_files(base_sha)
    if not touched_files:
        print("No changed files to evaluate for Snyk Code SAST.")
        return 0

    matched: list[tuple[str, int, str, str]] = []
    for run in sarif.get("runs", []):
        if not isinstance(run, dict):
            continue
        for res in run.get("results", []):
            if not isinstance(res, dict):
                continue
            rule_id = str(res.get("ruleId") or "snyk-code")
            message = str((res.get("message") or {}).get("text") or rule_id)
            for loc in res.get("locations", []):
                phys = (loc or {}).get("physicalLocation") or {}
                uri = str((phys.get("artifactLocation") or {}).get("uri") or "")
                rel_path = uri.replace("\\", "/").lstrip("./")
                if rel_path in touched_files:
                    line = int((phys.get("region") or {}).get("startLine") or 1)
                    matched.append((rel_path, line, rule_id, message))

    if not matched:
        print("No Snyk Code SAST issues found in changed files.")
        return 0

    for rel_path, line, rule_id, message in matched:
        print(f"::error file={rel_path},line={line}::Snyk Code [{rule_id}]: {message}")
    return 1


def main(argv: list[str] | None = None) -> int:
    args = argv if argv is not None else sys.argv[1:]
    if len(args) == 4 and args[0] == "dependencies":
        return check_dependencies(args[1], args[2], args[3])
    if len(args) == 3 and args[0] == "code":
        return check_code(args[1], args[2])

    print(
        "Usage:\n"
        "  check-snyk-changes.py dependencies <base.json> <baseline_dir> <current.json>\n"
        "  check-snyk-changes.py code <report.sarif> <base_sha>",
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
