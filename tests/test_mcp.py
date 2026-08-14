#!/usr/bin/env python3
"""Protocol and safety tests for the optional stdio MCP server."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parent.parent
SERVER = ROOT / "scripts/ubs_mcp.py"


class McpServerTests(unittest.TestCase):
    def run_server(self, workspace: Path, messages: list, allow_build: bool = False) -> list:
        environment = {
            **os.environ,
            "UBS_MCP_ROOT": str(workspace),
            "UBS_MCP_ALLOW_BUILD": str(allow_build).lower(),
        }
        payload = "".join(json.dumps(message, separators=(",", ":")) + "\n" for message in messages)
        result = subprocess.run(
            [sys.executable, str(SERVER)], input=payload, text=True,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=environment,
            cwd=workspace, check=True,
        )
        self.assertEqual(result.stderr, "")
        return [json.loads(line) for line in result.stdout.splitlines()]

    def test_initialize_list_detect_and_scope_guard(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            workspace = Path(temporary).resolve()
            app = workspace / "app"
            app.mkdir()
            (app / "package.json").write_text(
                '{"name":"demo","scripts":{"build":"node build.js"}}', encoding="utf-8",
            )
            messages = [
                {"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {
                    "protocolVersion": "2025-11-25", "capabilities": {},
                    "clientInfo": {"name": "test", "version": "1"},
                }},
                {"jsonrpc": "2.0", "method": "notifications/initialized"},
                {"jsonrpc": "2.0", "id": 2, "method": "tools/list"},
                {"jsonrpc": "2.0", "id": 3, "method": "tools/call", "params": {
                    "name": "ubs_detect", "arguments": {"path": "."},
                }},
                {"jsonrpc": "2.0", "id": 4, "method": "tools/call", "params": {
                    "name": "ubs_graph", "arguments": {"path": ".", "all": True},
                }},
                {"jsonrpc": "2.0", "id": 5, "method": "tools/call", "params": {
                    "name": "ubs_detect", "arguments": {"path": "../"},
                }},
            ]
            responses = self.run_server(workspace, messages)
            self.assertEqual(len(responses), 5)
            self.assertEqual(responses[0]["result"]["protocolVersion"], "2025-11-25")
            names = [item["name"] for item in responses[1]["result"]["tools"]]
            self.assertEqual(names, sorted(names, key=[
                "ubs_detect", "ubs_audit", "ubs_plan", "ubs_graph", "ubs_update_check"
            ].index))
            self.assertNotIn("ubs_build", names)
            detected = responses[2]["result"]["structuredContent"]
            self.assertEqual(detected[0]["type"], "node")
            self.assertEqual(len(responses[3]["result"]["structuredContent"]["nodes"]), 1)
            self.assertTrue(responses[4]["result"]["isError"])

    def test_build_tool_is_opt_in(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            responses = self.run_server(
                Path(temporary),
                [{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}],
                allow_build=True,
            )
            names = [item["name"] for item in responses[0]["result"]["tools"]]
            self.assertIn("ubs_build", names)


if __name__ == "__main__":
    unittest.main()
