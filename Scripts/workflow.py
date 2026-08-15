#!/usr/bin/env python3
"""Noninteractive, configuration-driven MakeCampaign workflow runner."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
from pathlib import Path

from workflow_runner.artifacts import ArtifactError, ArtifactStore, load_manifest, verify_run
from workflow_runner.config import ConfigError, load_config, validate_scope
from workflow_runner.executor import execute_workflow
from workflow_runner.repository import (
    RepositoryError,
    discover_repository,
    read_repository_state,
    require_clean_tracked_config,
    resolve_confined,
)


LEGACY_COMMANDS = {"init", "check", "review"}


def _config_argument(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--config", default="workflow.config.json")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="workflow.py", description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)

    validate = commands.add_parser("validate-config", help="validate the tracked runner configuration")
    _config_argument(validate)

    run = commands.add_parser("run", help="execute every required step for a scope")
    run.add_argument("scope")
    _config_argument(run)

    status = commands.add_parser("status", help="read finalized automatic-run artifacts")
    status.add_argument("scope", nargs="?")
    status.add_argument("--run", default="latest")
    status.add_argument("--json", action="store_true")

    verify = commands.add_parser("verify-run", help="verify an immutable run directory")
    verify.add_argument("run_directory")
    return parser


def _load_validated_config(repo: Path, value: str):
    config_path = resolve_confined(repo, value)
    require_clean_tracked_config(repo, config_path)
    return load_config(config_path, repo)


def command_validate(repo: Path, config_value: str) -> int:
    config = _load_validated_config(repo, config_value)
    print(f"PASS: configuration schema {config.schema_version}; {len(config.scopes)} scope(s)")
    return 0


def command_run(repo: Path, scope_value: str, config_value: str) -> int:
    scope_name = validate_scope(scope_value)
    config = _load_validated_config(repo, config_value)
    scope = config.scopes.get(scope_name)
    if scope is None:
        raise ConfigError(f"scope is not configured: {scope_name}")
    config_bytes = config.source_path.read_bytes()
    config_hash = hashlib.sha256(config_bytes).hexdigest()
    repository = read_repository_state(repo)
    artifact_root = resolve_confined(repo, config.artifact_root)
    store = ArtifactStore.create(
        artifact_root,
        scope,
        config.source_path.relative_to(repo),
        config_hash,
        repository,
    )
    exit_code = execute_workflow(config, scope, store, os.environ)
    manifest = load_manifest(store.path)
    failed_step = next(
        (
            step["id"]
            for step in manifest["steps"]
            if step["status"] in {"failed", "timed_out", "interrupted"}
        ),
        None,
    )
    print(f"run_id={manifest['run_id']}")
    print(f"status={manifest['status']}")
    if failed_step is not None:
        print(f"failed_step={failed_step}")
    print(f"artifact={store.path.relative_to(repo).as_posix()}")
    return exit_code


def _scope_run_parent(repo: Path, scope: str) -> Path:
    validate_scope(scope)
    root, slug = scope.split("/", 1)
    return resolve_confined(repo, Path(".workflow-runs") / root / slug)


def _latest_run(parent: Path) -> Path:
    candidates = sorted(
        (path for path in parent.iterdir() if path.is_dir() and (path / "run.json").is_file()),
        key=lambda path: path.name,
    ) if parent.is_dir() else []
    if not candidates:
        raise ArtifactError(f"no automatic runs found under {parent}")
    return candidates[-1]


def _selected_run(repo: Path, scope: str, run_value: str) -> Path:
    parent = _scope_run_parent(repo, scope)
    if run_value == "latest":
        return _latest_run(parent)
    selected = resolve_confined(repo, parent.relative_to(repo) / run_value)
    if selected.parent != parent or not selected.is_dir():
        raise ArtifactError(f"run does not exist: {run_value}")
    return selected


def command_status(repo: Path, scope: str | None, run_value: str, as_json: bool) -> int:
    if scope is not None:
        manifest = load_manifest(_selected_run(repo, scope, run_value))
        if as_json:
            print(json.dumps(manifest, indent=2, sort_keys=True))
        else:
            print(f"{scope}: {manifest['status']} ({manifest['run_id']})")
        return 0

    artifact_root = repo / ".workflow-runs"
    manifests: list[dict[str, object]] = []
    if artifact_root.is_dir():
        for scope_root in sorted(path for path in artifact_root.iterdir() if path.is_dir()):
            for scope_slug in sorted(path for path in scope_root.iterdir() if path.is_dir()):
                try:
                    manifests.append(load_manifest(_latest_run(scope_slug)))
                except ArtifactError:
                    continue
    if as_json:
        print(json.dumps(manifests, indent=2, sort_keys=True))
    elif manifests:
        for manifest in manifests:
            print(f"{manifest['scope']}: {manifest['status']} ({manifest['run_id']})")
    else:
        print("no automatic runs")
    return 0


def command_verify(repo: Path, run_directory: str) -> int:
    path = resolve_confined(repo, run_directory)
    errors = verify_run(path)
    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 2
    print(f"PASS: verified run {path.relative_to(repo)}")
    return 0


def main(argv: list[str] | None = None) -> int:
    arguments = list(sys.argv[1:] if argv is None else argv)
    if arguments and arguments[0] in LEGACY_COMMANDS:
        print(
            "legacy workflow command removed; use validate-config, run, status, or verify-run",
            file=sys.stderr,
        )
        return 2
    try:
        args = build_parser().parse_args(arguments)
        repo = discover_repository(Path.cwd())
        if args.command == "validate-config":
            return command_validate(repo, args.config)
        if args.command == "run":
            return command_run(repo, args.scope, args.config)
        if args.command == "status":
            return command_status(repo, args.scope, args.run, args.json)
        if args.command == "verify-run":
            return command_verify(repo, args.run_directory)
    except (ConfigError, RepositoryError) as error:
        print(error, file=sys.stderr)
        return 2
    except ArtifactError as error:
        print(error, file=sys.stderr)
        return 5
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
