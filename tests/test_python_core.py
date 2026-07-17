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
from unittest import mock


ROOT = Path(__file__).resolve().parent.parent
SPEC = importlib.util.spec_from_file_location("ubs_core_test", ROOT / "scripts/ubs.py")
assert SPEC and SPEC.loader
ubs = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = ubs
SPEC.loader.exec_module(ubs)


class PythonCoreTests(unittest.TestCase):
    def test_standard_streams_are_configured_for_utf8(self) -> None:
        first = mock.Mock()
        second = mock.Mock()
        ubs.configure_standard_streams(first, second)
        first.reconfigure.assert_called_once_with(
            encoding="utf-8", errors="backslashreplace",
        )
        second.reconfigure.assert_called_once_with(
            encoding="utf-8", errors="backslashreplace",
        )

    def test_flutter_artifacts_open_the_common_build_root(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            output = root / "build/app/outputs/bundle/release"
            output.mkdir(parents=True)
            (output / "app-release.aab").write_bytes(b"bundle")
            web = root / "build/web"
            web.mkdir(parents=True)
            self.assertEqual(
                ubs.artifact_output_directories(ubs.Project("flutter", root)),
                [root / "build"],
            )

    def test_output_directories_cover_tauri_gradle_and_xcode(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            bundle = root / "src-tauri/target/release/bundle/deb"
            package = root / "signing/build"
            bundle.mkdir(parents=True)
            package.mkdir(parents=True)
            (bundle / "app.deb").write_bytes(b"deb")
            (package / "app.pkg").write_bytes(b"pkg")
            self.assertEqual(
                ubs.artifact_output_directories(ubs.Project("tauri", root)),
                [package, root / "src-tauri/target/release/bundle"],
            )

            gradle_output = root / "app/build/outputs/apk/release"
            gradle_output.mkdir(parents=True)
            (gradle_output / "app-release.apk").write_bytes(b"apk")
            self.assertEqual(
                ubs.artifact_output_directories(ubs.Project("android", root)),
                [gradle_output],
            )

            archive = root / "build/ubs/Demo.xcarchive"
            archive.mkdir(parents=True)
            self.assertEqual(
                ubs.artifact_output_directories(ubs.Project("ios-xcode", root)),
                [root / "build/ubs"],
            )

    def test_output_folder_opening_is_cross_platform_and_opt_in_safe(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            (root / "dist").mkdir()
            environment = {**os.environ, "UBS_OPEN_OUTPUT": "true"}
            with mock.patch.object(ubs.platform, "system", return_value="Darwin"), \
                    mock.patch.object(ubs.shutil, "which", return_value="/usr/bin/open"), \
                    mock.patch.object(ubs.subprocess, "Popen") as process:
                opened = ubs.open_artifact_directories(
                    [ubs.Project("node", root)], environment,
                )
            self.assertEqual(opened, [str(root / "dist")])
            process.assert_called_once()
            self.assertEqual(process.call_args.args[0], ["/usr/bin/open", str(root / "dist")])
        self.assertFalse(ubs.should_open_output({"CI": "true"}, interactive=True))
        self.assertFalse(ubs.should_open_output({"UBS_OPEN_OUTPUT": "auto"}, interactive=False))
        self.assertTrue(ubs.should_open_output({"UBS_OPEN_OUTPUT": "true"}, interactive=False))

    def test_single_project_fast_path_still_opens_output_folder(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            (root / "package.json").write_text(
                '{"name":"solo","scripts":{"build":"true"}}', encoding="utf-8",
            )
            ubs.load_package.cache_clear()
            with mock.patch.object(ubs, "run_project", return_value=0), \
                    mock.patch.object(ubs, "open_artifact_directories") as opener:
                status = ubs.main(["build", "--non-interactive", str(root)])
            self.assertEqual(status, 0)
            opener.assert_called_once_with([ubs.Project("node", root)])

    def _mock_tty(self, is_tty: bool) -> mock.Mock:
        mock_sys = mock.Mock(wraps=ubs.sys)
        mock_sys.stdin.isatty.return_value = is_tty
        mock_sys.stdout.isatty.return_value = is_tty
        return mock_sys

    def test_local_default_prompt_persists_choice_and_skips_next_time(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            with mock.patch.object(ubs, "sys", self._mock_tty(True)), \
                    mock.patch("builtins.input", return_value="2"):
                self.assertFalse(ubs.resolve_non_interactive_default(root))
            config = json.loads((root / ".ubs" / "config.json").read_text(encoding="utf-8"))
            self.assertEqual(config["non_interactive_default"], False)
            with mock.patch("builtins.input", side_effect=AssertionError("should not prompt twice")):
                self.assertFalse(ubs.resolve_non_interactive_default(root))

    def test_local_default_prompt_skips_without_a_real_tty(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            with mock.patch.object(ubs, "sys", self._mock_tty(False)), \
                    mock.patch("builtins.input", side_effect=AssertionError("must not prompt without a tty")):
                self.assertTrue(ubs.resolve_non_interactive_default(root))
                self.assertFalse(ubs.resolve_obfuscate_default(root))
            self.assertFalse((root / ".ubs" / "config.json").exists())

    def test_obfuscate_default_prompt_persists_choice(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            with mock.patch.object(ubs, "sys", self._mock_tty(True)), \
                    mock.patch("builtins.input", return_value="2"):
                self.assertTrue(ubs.resolve_obfuscate_default(root))
            config = json.loads((root / ".ubs" / "config.json").read_text(encoding="utf-8"))
            self.assertEqual(config["obfuscate_js_default"], True)

    def test_obfuscate_prompt_only_triggers_for_tauri_projects(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            (root / "package.json").write_text(
                '{"name":"solo","scripts":{"build":"true"}}', encoding="utf-8",
            )
            ubs.load_package.cache_clear()
            with mock.patch.object(ubs, "run_project", return_value=0), \
                    mock.patch.object(ubs, "open_artifact_directories"), \
                    mock.patch.object(ubs, "resolve_obfuscate_default") as obfuscate:
                ubs.main(["build", "--non-interactive", str(root)])
            obfuscate.assert_not_called()

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

    def test_node_dependencies_are_topologically_sorted(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            core = root / "packages/core"
            app = root / "apps/app"
            core.mkdir(parents=True)
            app.mkdir(parents=True)
            (core / "package.json").write_text(
                '{"name":"@demo/core","scripts":{"build":"true"}}', encoding="utf-8",
            )
            (app / "package.json").write_text(
                '{"name":"@demo/app","dependencies":{"@demo/core":"workspace:*"},'
                '"scripts":{"build":"true"}}', encoding="utf-8",
            )
            ubs.load_package.cache_clear()
            projects = [ubs.Project("node", app), ubs.Project("node", core)]
            graph = ubs.build_project_graph(projects, root)
            layers = ubs.topological_layers(graph)
            self.assertEqual(layers, [[ubs.Project("node", core)], [ubs.Project("node", app)]])
            payload = ubs.graph_payload(graph)
            self.assertEqual(payload["edges"], [{"from": str(core), "to": str(app)}])

    def test_explicit_dependency_cycle_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            first, second = root / "a", root / "b"
            first.mkdir()
            second.mkdir()
            (root / "ubs.dependencies.json").write_text(
                '{"schema_version":1,"dependencies":{"a":["b"],"b":["a"]}}',
                encoding="utf-8",
            )
            graph = ubs.build_project_graph(
                [ubs.Project("node", first), ubs.Project("node", second)], root,
            )
            with self.assertRaisesRegex(ValueError, "순환"):
                ubs.topological_layers(graph)

    def test_missing_explicit_dependency_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            app = root / "app"
            app.mkdir()
            (root / "ubs.dependencies.json").write_text(
                '{"schema_version":1,"dependencies":{"app":["missing"]}}', encoding="utf-8",
            )
            with self.assertRaisesRegex(ValueError, "감지되지 않았습니다"):
                ubs.build_project_graph([ubs.Project("node", app)], root)

    def test_flutter_path_and_gradle_composite_dependencies(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            shared, flutter, gradle = root / "shared", root / "mobile", root / "android"
            shared.mkdir()
            flutter.mkdir()
            gradle.mkdir()
            (flutter / "pubspec.yaml").write_text(
                "dependencies:\n  shared:\n    path: ../shared\n", encoding="utf-8",
            )
            (gradle / "settings.gradle").write_text(
                "includeBuild '../shared'\n", encoding="utf-8",
            )
            projects = [
                ubs.Project("flutter", flutter), ubs.Project("gradle", gradle),
                ubs.Project("node", shared),
            ]
            graph = ubs.build_project_graph(projects, root)
            self.assertEqual(graph.dependencies[projects[0]], {projects[2]})
            self.assertEqual(graph.dependencies[projects[1]], {projects[2]})

    def test_xcode_plan_uses_explicit_release_contract(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            (root / "Demo.xcodeproj").mkdir()
            environment = {
                "UBS_XCODE_SCHEME": "DemoRelease",
                "UBS_XCODE_CONFIGURATION": "Release",
                "UBS_XCODE_EXPORT": "true",
                "UBS_XCODE_FLAGS": "-allowProvisioningUpdates",
            }
            plan = ubs.xcode_plan(root, environment)
            self.assertEqual(plan["container_type"], "project")
            self.assertEqual(plan["scheme"], "DemoRelease")
            self.assertEqual(plan["configuration"], "Release")
            self.assertTrue(plan["export"])
            self.assertEqual(plan["flags"], ["-allowProvisioningUpdates"])

    def test_executor_waits_for_dependency_layer(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            core, app = root / "core", root / "app"
            core.mkdir()
            app.mkdir()
            (root / "ubs.dependencies.json").write_text(
                '{"schema_version":1,"dependencies":{"app":["core"]}}', encoding="utf-8",
            )
            projects = [ubs.Project("node", app), ubs.Project("node", core)]
            observed = []

            def record(project, _options, _report):
                observed.append(project.path.name)
                return 0

            options = ubs.Options(root=root, jobs=2)
            with mock.patch.object(ubs, "run_project", side_effect=record), \
                    mock.patch.object(ubs, "open_artifact_directories") as opener:
                status = ubs.execute_projects(projects, options, ubs.BuildReport(None), root)
            self.assertEqual(status, 0)
            self.assertEqual(observed, ["core", "app"])
            opener.assert_called_once_with([
                ubs.Project("node", core), ubs.Project("node", app),
            ])

    def test_xcode_adapter_archives_with_discovered_scheme(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            (root / "Demo.xcodeproj").mkdir()
            commands = []

            def record(command, _directory, _environment):
                commands.append(list(command))
                return 0

            with mock.patch.object(ubs.platform, "system", return_value="Darwin"), \
                    mock.patch.object(ubs.shutil, "which", return_value="/usr/bin/xcodebuild"), \
                    mock.patch.object(ubs, "discover_xcode_scheme", return_value="Demo"), \
                    mock.patch.object(ubs, "run_command", side_effect=record):
                status = ubs.run_xcode_adapter(root, {})
            self.assertEqual(status, 0)
            self.assertEqual(len(commands), 1)
            self.assertIn("-project", commands[0])
            self.assertIn("Demo", commands[0])
            self.assertEqual(commands[0][-1], "archive")

    def test_failed_dependency_does_not_block_independent_branch(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            names = ("failed-core", "blocked-app", "good-core", "good-app")
            paths = {name: root / name for name in names}
            for path in paths.values():
                path.mkdir()
            (root / "ubs.dependencies.json").write_text(
                '{"schema_version":1,"dependencies":{'
                '"blocked-app":["failed-core"],"good-app":["good-core"]}}',
                encoding="utf-8",
            )
            projects = [ubs.Project("node", paths[name]) for name in names]
            observed = []

            def record(project, _options, _report):
                observed.append(project.path.name)
                return 1 if project.path.name == "failed-core" else 0

            with mock.patch.object(ubs, "run_project", side_effect=record):
                status = ubs.execute_projects(
                    projects, ubs.Options(root=root, jobs=2), ubs.BuildReport(None), root,
                )
            self.assertEqual(status, 1)
            self.assertIn("good-app", observed)
            self.assertNotIn("blocked-app", observed)


if __name__ == "__main__":
    unittest.main()
