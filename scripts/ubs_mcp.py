#!/usr/bin/env python3
"""Dependency-free local MCP stdio server for Universal Build Script.

The server intentionally exposes read-only tools by default. Set
UBS_MCP_ALLOW_BUILD=true and pass confirm=true to permit a non-dry-run build.
All protocol output goes to stdout; diagnostics stay on stderr.
"""

from __future__ import annotations

import json
import os
from pathlib import Path
import subprocess
import sys
from typing import Dict, List, Optional


RUNTIME_ROOT = Path(__file__).resolve().parent.parent
BUILD_SCRIPT = RUNTIME_ROOT / "build.sh"
PROTOCOL_VERSION = "2025-11-25"
SERVER_VERSION = (RUNTIME_ROOT / "VERSION").read_text(encoding="utf-8").strip()
SERVER_ROOT = Path(os.environ.get("UBS_MCP_ROOT", Path.cwd())).expanduser().resolve()
ALLOW_BUILD = os.environ.get("UBS_MCP_ALLOW_BUILD", "false") == "true"


def tool_schema(
    name: str, title: str, description: str, properties: Optional[dict] = None,
) -> dict:
    return {
        "name": name,
        "title": title,
        "description": description,
        "inputSchema": {
            "type": "object",
            "properties": properties or {},
            "additionalProperties": False,
        },
    }


PATH_PROPERTY = {
    "type": "string",
    "description": "Path relative to UBS_MCP_ROOT. Defaults to the root itself.",
}
COMMON_PROPERTIES = {
    "path": PATH_PROPERTY,
    "all": {"type": "boolean", "default": False},
    "type": {"type": "string"},
}


def available_tools() -> List[dict]:
    tools = [
        tool_schema("ubs_detect", "Detect build projects", "Detect supported projects without changing files.", {
            "path": PATH_PROPERTY,
        }),
        tool_schema("ubs_audit", "Audit build optimization", "Audit optimization and obfuscation settings.", COMMON_PROPERTIES),
        tool_schema("ubs_plan", "Plan builds", "Return the resolved, read-only build plan.", {
            **COMMON_PROPERTIES,
            "jobs": {"type": "integer", "minimum": 1, "default": 1},
            "flutter_outputs": {"type": "string", "default": "auto"},
        }),
        tool_schema("ubs_graph", "Inspect dependency graph", "Return inferred dependencies and topological build layers.", COMMON_PROPERTIES),
        tool_schema("ubs_update_check", "Check runtime update", "Check for a runtime update without modifying files."),
    ]
    if ALLOW_BUILD:
        tools.append(tool_schema("ubs_build", "Build projects", "Run a dry-run or an explicitly confirmed local build.", {
            **COMMON_PROPERTIES,
            "project": PATH_PROPERTY,
            "jobs": {"type": "integer", "minimum": 1, "default": 1},
            "dry_run": {"type": "boolean", "default": True},
            "confirm": {"type": "boolean", "default": False},
        }))
    return tools


def resolve_scoped_path(value: object = ".") -> Path:
    if not isinstance(value, str) or not value:
        raise ValueError("path must be a non-empty string")
    candidate = Path(value).expanduser()
    resolved = (SERVER_ROOT / candidate).resolve() if not candidate.is_absolute() else candidate.resolve()
    try:
        resolved.relative_to(SERVER_ROOT)
    except ValueError as error:
        raise ValueError(f"path escapes UBS_MCP_ROOT: {value}") from error
    if not resolved.is_dir():
        raise ValueError(f"directory does not exist: {value}")
    return resolved


def common_arguments(arguments: dict) -> tuple[Path, List[str]]:
    path = resolve_scoped_path(arguments.get("path", "."))
    command: List[str] = []
    if arguments.get("all") is True:
        command.append("--all")
    project_type = arguments.get("type")
    if project_type is not None:
        if not isinstance(project_type, str) or not project_type:
            raise ValueError("type must be a non-empty string")
        command.extend(["--type", project_type])
    return path, command


def run_ubs(arguments: List[str]) -> tuple[int, str, str]:
    result = subprocess.run(
        ["bash", str(BUILD_SCRIPT), *arguments], cwd=SERVER_ROOT,
        text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
    )
    return result.returncode, result.stdout, result.stderr


def tool_result(status: int, stdout: str, stderr: str, structured: object = None) -> dict:
    text = stdout.strip()
    if stderr.strip():
        text = f"{text}\n{stderr.strip()}".strip()
    result = {
        "content": [{"type": "text", "text": text or f"exit status {status}"}],
        "isError": status != 0,
    }
    if structured is not None and status == 0:
        result["structuredContent"] = structured
    return result


def call_tool(name: str, arguments: object) -> dict:
    if not isinstance(arguments, dict):
        raise ValueError("arguments must be an object")
    if name in {"ubs_detect", "ubs_audit", "ubs_plan", "ubs_graph"}:
        path, common = common_arguments(arguments)
        if name == "ubs_detect" and any(key in arguments for key in ("all", "type")):
            raise ValueError("ubs_detect accepts only path")
        command_name = name.removeprefix("ubs_")
        command = [command_name, "--json", *common]
        if name == "ubs_plan":
            jobs = arguments.get("jobs", 1)
            if not isinstance(jobs, int) or isinstance(jobs, bool) or jobs < 1:
                raise ValueError("jobs must be an integer greater than zero")
            outputs = arguments.get("flutter_outputs", "auto")
            if not isinstance(outputs, str):
                raise ValueError("flutter_outputs must be a string")
            command.extend(["--jobs", str(jobs), "--flutter-outputs", outputs])
        command.append(str(path))
        status, stdout, stderr = run_ubs(command)
        structured = None
        if status == 0:
            try:
                structured = json.loads(stdout)
            except json.JSONDecodeError:
                status = 1
                stderr = f"{stderr}\nUBS returned invalid JSON".strip()
        return tool_result(status, stdout, stderr, structured)
    if name == "ubs_update_check":
        if arguments:
            raise ValueError("ubs_update_check does not accept arguments")
        status, stdout, stderr = run_ubs(["update", "--check", "--json"])
        structured = json.loads(stdout) if status == 0 and stdout.strip() else None
        return tool_result(status, stdout, stderr, structured)
    if name == "ubs_build" and ALLOW_BUILD:
        path, common = common_arguments(arguments)
        dry_run = arguments.get("dry_run", True)
        confirm = arguments.get("confirm", False)
        if not isinstance(dry_run, bool) or not isinstance(confirm, bool):
            raise ValueError("dry_run and confirm must be booleans")
        if not dry_run and not confirm:
            raise ValueError("non-dry-run builds require confirm=true")
        jobs = arguments.get("jobs", 1)
        if not isinstance(jobs, int) or isinstance(jobs, bool) or jobs < 1:
            raise ValueError("jobs must be an integer greater than zero")
        command = ["build", *common, "--jobs", str(jobs)]
        project = arguments.get("project")
        if project is not None:
            command.extend(["--project", str(resolve_scoped_path(project))])
        if dry_run:
            command.append("--dry-run")
        command.append(str(path))
        status, stdout, stderr = run_ubs(command)
        return tool_result(status, stdout, stderr)
    raise KeyError(name)


def response(identifier: object, result: object = None, error: object = None) -> dict:
    value = {"jsonrpc": "2.0", "id": identifier}
    if error is not None:
        value["error"] = error
    else:
        value["result"] = result
    return value


def handle_message(message: object) -> Optional[dict]:
    if not isinstance(message, dict) or message.get("jsonrpc") != "2.0":
        return response(None, error={"code": -32600, "message": "Invalid Request"})
    method = message.get("method")
    identifier = message.get("id")
    if method == "initialize":
        return response(identifier, {
            "protocolVersion": PROTOCOL_VERSION,
            "capabilities": {"tools": {"listChanged": False}},
            "serverInfo": {"name": "universal-build", "version": SERVER_VERSION},
            "instructions": "Use read-only detect, audit, plan, and graph tools before requesting builds.",
        })
    if method in {"notifications/initialized", "notifications/cancelled"}:
        return None
    if method == "ping":
        return response(identifier, {})
    if method == "tools/list":
        return response(identifier, {"tools": available_tools()})
    if method == "tools/call":
        params = message.get("params")
        if not isinstance(params, dict) or not isinstance(params.get("name"), str):
            return response(identifier, error={"code": -32602, "message": "Invalid tool parameters"})
        try:
            result = call_tool(params["name"], params.get("arguments", {}))
            return response(identifier, result)
        except KeyError:
            return response(identifier, error={"code": -32601, "message": "Unknown tool"})
        except (OSError, ValueError, json.JSONDecodeError) as error:
            return response(identifier, {
                "content": [{"type": "text", "text": str(error)}],
                "isError": True,
            })
    if identifier is None:
        return None
    return response(identifier, error={"code": -32601, "message": "Method not found"})


def serve() -> int:
    for raw in sys.stdin:
        try:
            message = json.loads(raw)
            result = handle_message(message)
        except json.JSONDecodeError as error:
            result = response(None, error={"code": -32700, "message": f"Parse error: {error.msg}"})
        except Exception as error:  # keep the stdio session alive on unexpected tool errors
            print(f"MCP server error: {error}", file=sys.stderr)
            result = response(None, error={"code": -32603, "message": "Internal error"})
        if result is not None:
            sys.stdout.write(json.dumps(result, ensure_ascii=False, separators=(",", ":")) + "\n")
            sys.stdout.flush()
    return 0


if __name__ == "__main__":
    raise SystemExit(serve())
