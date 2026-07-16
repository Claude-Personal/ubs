#!/usr/bin/env python3
"""Cross-platform tests for the Python-only orchestration contract."""

from concurrent.futures import ThreadPoolExecutor
import importlib.util
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parent.parent
SPEC = importlib.util.spec_from_file_location("ubs_core_test", ROOT / "scripts/ubs.py")
assert SPEC and SPEC.loader
ubs = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = ubs
SPEC.loader.exec_module(ubs)


class PythonCoreTests(unittest.TestCase):
    def test_windows_gradle_arguments_preserve_backslashes(self) -> None:
        value = r'-PstoreFile=C:\Users\me\release.jks "-Pcache=C:\build cache"'
        self.assertEqual(
            ubs.split_cli_arguments(value, windows=True),
            [r"-PstoreFile=C:\Users\me\release.jks", r"-Pcache=C:\build cache"],
        )

    def test_workspace_root_and_conflict_group(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            child = root / "apps/a"
            child.mkdir(parents=True)
            (root / "package.json").write_text(
                '{"packageManager":"pnpm@9","workspaces":["apps/*"],"scripts":{"build":"pnpm -r build"}}',
                encoding="utf-8",
            )
            (root / "pnpm-lock.yaml").write_text("lockfileVersion: 9\n", encoding="utf-8")
            (child / "package.json").write_text('{"scripts":{"build":"true"}}', encoding="utf-8")
            ubs.node_workspace_root.cache_clear()
            self.assertEqual(ubs.node_workspace_root(child), root)
            projects = [ubs.Project("node", root), ubs.Project("node", child)]
            groups = ubs.project_groups(projects)
            self.assertEqual(len(groups), 1)
            self.assertEqual(len(groups[0]), 2)

    def test_dependency_digest_includes_manager_config(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "package.json").write_text('{"scripts":{"build":"true"}}', encoding="utf-8")
            environment = {**os.environ, "PATH": ""}
            before = ubs.dependency_digest(root, "npm", environment)
            (root / ".npmrc").write_text("legacy-peer-deps=true\n", encoding="utf-8")
            after = ubs.dependency_digest(root, "npm", environment)
            self.assertNotEqual(before, after)

    def test_parallel_report_writes_valid_json(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            report_path = root / "report.json"
            report = ubs.BuildReport(report_path)
            projects = [ubs.Project("node", root / f"app-{index}") for index in range(8)]
            with ThreadPoolExecutor(max_workers=4) as executor:
                list(executor.map(lambda project: report.append(project, 0, True), projects))
            data = json.loads(report_path.read_text(encoding="utf-8"))
            self.assertEqual(len(data["results"]), len(projects))
            self.assertEqual(data["schema_version"], 1)


if __name__ == "__main__":
    unittest.main()
