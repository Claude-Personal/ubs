#!/usr/bin/env python3
"""Cross-platform tests for the Python-only orchestration contract."""

from concurrent.futures import ThreadPoolExecutor
import base64
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
            # A signed package supersedes the raw bundle output it was built
            # from — only the final distributable folder should open.
            self.assertEqual(
                ubs.artifact_output_directories(ubs.Project("tauri", root)),
                [package],
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

    def test_unsigned_tauri_build_still_opens_raw_bundle_folder(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            bundle = root / "src-tauri/target/release/bundle/dmg"
            bundle.mkdir(parents=True)
            (bundle / "app.dmg").write_bytes(b"dmg")
            self.assertEqual(
                ubs.artifact_output_directories(ubs.Project("tauri", root)),
                [root / "src-tauri/target/release/bundle"],
            )

    def test_universal_darwin_tauri_build_opens_its_specific_bundle_folder(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            bundle = root / "src-tauri/target/universal-apple-darwin/release/bundle/macos"
            bundle.mkdir(parents=True)
            (bundle / "App.app").mkdir()
            self.assertEqual(
                ubs.discover_artifacts(ubs.Project("tauri", root)),
                [str(bundle / "App.app")],
            )
            # Must NOT collapse to the shared "target" ancestor with the
            # default (non-multi-target) bundle pattern's preferred root.
            self.assertEqual(
                ubs.artifact_output_directories(ubs.Project("tauri", root)),
                [bundle],
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

    def test_terminal_hyperlink_wraps_path_as_clickable_osc8(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary).resolve() / "my folder"
            link = ubs.terminal_hyperlink(path)
            self.assertTrue(link.startswith(f"\033]8;;{path.as_uri()}\033\\"))
            self.assertIn(str(path), link)
            self.assertTrue(link.endswith("\033]8;;\033\\"))

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
            with mock.patch.object(ubs, "sys", self._mock_tty(True)), \
                    mock.patch("builtins.input", side_effect=AssertionError("should not prompt twice")):
                self.assertFalse(ubs.resolve_non_interactive_default(root))

    def test_local_default_prompt_skips_without_a_real_tty(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            with mock.patch.object(ubs, "sys", self._mock_tty(False)), \
                    mock.patch("builtins.input", side_effect=AssertionError("must not prompt without a tty")):
                self.assertTrue(ubs.resolve_non_interactive_default(root))
                self.assertFalse(ubs.resolve_obfuscate_default(root))
            self.assertFalse((root / ".ubs" / "config.json").exists())

    def test_saved_local_defaults_never_affect_non_tty_execution(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            config = root / ".ubs" / "config.json"
            config.parent.mkdir()
            config.write_text(
                '{"non_interactive_default":false,"obfuscate_js_default":true}',
                encoding="utf-8",
            )
            with mock.patch.object(ubs, "sys", self._mock_tty(False)), \
                    mock.patch("builtins.input", side_effect=AssertionError("must not prompt")):
                self.assertTrue(ubs.resolve_non_interactive_default(root))
                self.assertFalse(ubs.resolve_obfuscate_default(root))

    def test_publish_default_is_always_false_without_tty(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            config = root / ".ubs" / "config.json"
            config.parent.mkdir()
            config.write_text('{"publish_default":true}', encoding="utf-8")
            with mock.patch.object(ubs, "sys", self._mock_tty(False)), \
                    mock.patch("builtins.input", side_effect=AssertionError("must not prompt")):
                self.assertFalse(ubs.resolve_publish_default(root))

    def test_publish_apple_rejects_missing_environment_without_subprocess(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            artifact = root / "Demo.ipa"
            artifact.write_bytes(b"ipa")
            with mock.patch.object(ubs.platform, "system", return_value="Darwin"), \
                    mock.patch.object(ubs.subprocess, "run") as process:
                status = ubs.publish_apple(artifact, ubs.Project("ios-xcode", root), {})
            self.assertEqual(status, 1)
            process.assert_not_called()

    def test_publish_apple_uses_exact_altool_arguments(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            artifact = root / "Demo.ipa"
            artifact.write_bytes(b"ipa")
            environment = {
                "ASC_API_KEY_ID": "KEY123",
                "ASC_API_ISSUER_ID": "issuer-123",
                "ASC_APPLE_ID": "123456789",
                "ASC_BUNDLE_ID": "com.example.demo",
                "ASC_BUNDLE_VERSION": "42",
                "ASC_BUNDLE_SHORT_VERSION": "1.2.3",
            }
            result = mock.Mock(returncode=0, stdout="uploaded\n", stderr="")
            with mock.patch.object(ubs.platform, "system", return_value="Darwin"), \
                    mock.patch.object(ubs.subprocess, "run", return_value=result) as process:
                status = ubs.publish_apple(
                    artifact, ubs.Project("ios-xcode", root), environment,
                )
            self.assertEqual(status, 0)
            expected = [
                "xcrun", "altool", "--upload-package", str(artifact),
                "--type", "ios", "--apiKey", "KEY123",
                "--apiIssuer", "issuer-123", "--apple-id", "123456789",
                "--bundle-id", "com.example.demo", "--bundle-version", "42",
                "--bundle-short-version-string", "1.2.3",
            ]
            process.assert_called_once_with(expected, capture_output=True, text=True)
            self.assertNotIn("--wait", expected)

    def test_publish_apple_rejects_non_macos_without_subprocess(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            artifact = root / "Demo.ipa"
            with mock.patch.object(ubs.platform, "system", return_value="Linux"), \
                    mock.patch.object(ubs.subprocess, "run") as process:
                status = ubs.publish_apple(artifact, ubs.Project("ios-xcode", root), {})
            self.assertEqual(status, 1)
            process.assert_not_called()

    def test_google_play_track_publish_replaces_completed_release_not_stacks(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            account_path = root / "service-account.json"
            account_path.write_text(json.dumps({
                "private_key": "fake", "private_key_id": "kid", "client_email": "svc@example.com",
            }), encoding="utf-8")
            artifact = root / "app.aab"
            artifact.write_bytes(b"aab-bytes")

            class FakeResponse:
                def __init__(self, data, headers=None):
                    self._data = data
                    self.headers = headers or {}

                def read(self):
                    return self._data

                def __enter__(self):
                    return self

                def __exit__(self, *exc):
                    return False

            put_bodies = []

            def fake_urlopen(request):
                url, method = request.full_url, request.get_method()
                if "oauth2.googleapis.com/token" in url:
                    return FakeResponse(json.dumps({"access_token": "tok"}).encode())
                if url.endswith("/edits") and method == "POST":
                    return FakeResponse(json.dumps({"id": "edit1"}).encode())
                if "uploadType=resumable" in url:
                    return FakeResponse(b"", {"Location": "https://upload.example/session"})
                if url == "https://upload.example/session":
                    return FakeResponse(json.dumps({"versionCode": 42}).encode())
                if url.endswith("/tracks/internal") and method == "GET":
                    return FakeResponse(json.dumps({
                        "track": "internal",
                        "releases": [
                            {"status": "completed", "versionCodes": ["10"]},
                            {"status": "draft", "versionCodes": ["11"]},
                        ],
                    }).encode())
                if url.endswith("/tracks/internal") and method == "PUT":
                    put_bodies.append(json.loads(request.data))
                    return FakeResponse(b"{}")
                if url.endswith(":validate") or url.endswith(":commit"):
                    return FakeResponse(b"{}")
                raise AssertionError(f"unexpected request: {method} {url}")

            environment = {
                "GOOGLE_PLAY_SERVICE_ACCOUNT_JSON": str(account_path),
                "GOOGLE_PLAY_PACKAGE_NAME": "com.example.app",
            }
            with mock.patch.object(ubs, "build_google_jwt", return_value="fake.jwt.token"), \
                    mock.patch.object(ubs.urllib.request, "urlopen", side_effect=fake_urlopen):
                status = ubs.publish_google_play(artifact, ubs.Project("android", root), environment)
            self.assertEqual(status, 0)
            self.assertEqual(len(put_bodies), 1)
            releases = put_bodies[0]["releases"]
            self.assertEqual(len(releases), 2)
            completed = [item for item in releases if item["status"] == "completed"]
            self.assertEqual(completed, [{"status": "completed", "versionCodes": ["42"]}])
            self.assertEqual([item for item in releases if item["status"] == "draft"],
                              [{"status": "draft", "versionCodes": ["11"]}])

    def test_google_jwt_contains_compact_rs256_header_and_claims(self) -> None:
        account = {
            "private_key": "-----BEGIN PRIVATE KEY-----\nfake\n-----END PRIVATE KEY-----\n",
            "private_key_id": "kid-123",
            "client_email": "publisher@example.iam.gserviceaccount.com",
        }
        result = mock.Mock(returncode=0, stdout=b"fake-signature", stderr=b"")
        with mock.patch.object(ubs.subprocess, "run", return_value=result) as process:
            jwt = ubs.build_google_jwt(account, 1_700_000_000)
        header_part, claims_part, signature_part = jwt.split(".")

        def decode(part):
            return json.loads(base64.urlsafe_b64decode(part + "=" * (-len(part) % 4)))

        self.assertEqual(
            decode(header_part), {"alg": "RS256", "typ": "JWT", "kid": "kid-123"},
        )
        self.assertEqual(decode(claims_part), {
            "iss": account["client_email"],
            "scope": "https://www.googleapis.com/auth/androidpublisher",
            "aud": "https://oauth2.googleapis.com/token",
            "iat": 1_700_000_000,
            "exp": 1_700_003_600,
        })
        self.assertEqual(
            base64.urlsafe_b64decode(signature_part + "=" * (-len(signature_part) % 4)),
            b"fake-signature",
        )
        command = process.call_args.args[0]
        self.assertEqual(command[:4], ["openssl", "dgst", "-sha256", "-sign"])
        self.assertNotIn(b"\n", process.call_args.kwargs["input"])
        self.assertEqual(process.call_args.kwargs["stdout"], ubs.subprocess.PIPE)
        self.assertEqual(process.call_args.kwargs["stderr"], ubs.subprocess.PIPE)

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
