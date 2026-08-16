from __future__ import annotations

import json
import os
import re
from pathlib import Path
from typing import Any

from .models import CommandPolicy, RunnerConfig, ScopeConfig, StepConfig, StepKind


SCOPE_PATTERN = re.compile(r"^(?:core|components|features)/[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$")
IDENTIFIER_PATTERN = re.compile(r"^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$")
ROOT_KEYS = {
    "schema_version",
    "artifact_root",
    "default_timeout_seconds",
    "max_output_bytes_per_stream",
    "command_policies",
    "scopes",
}
POLICY_KEYS = {"id", "argv_prefix"}
SCOPE_KEYS = {"workflow_id", "steps"}
STEP_REQUIRED_KEYS = {"id", "kind", "policy", "argv", "cwd", "timeout_seconds", "env_from"}
STEP_OPTIONAL_KEYS = {"required_artifacts"}
SAFE_GIT_SUBCOMMANDS = {"diff", "status", "show", "rev-parse", "ls-files"}


class ConfigError(ValueError):
    pass


def _object(value: Any, label: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ConfigError(f"{label} must be an object")
    return value


def _exact_keys(value: dict[str, Any], required: set[str], optional: set[str], label: str) -> None:
    unknown = set(value) - required - optional
    missing = required - set(value)
    if unknown:
        raise ConfigError(f"{label}: unknown key(s): {', '.join(sorted(unknown))}")
    if missing:
        raise ConfigError(f"{label}: missing key(s): {', '.join(sorted(missing))}")


def _positive_integer(value: Any, label: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
        raise ConfigError(f"{label} must be a positive integer")
    return value


def _string(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value:
        raise ConfigError(f"{label} must be a nonempty string")
    return value


def _string_tuple(value: Any, label: str, *, allow_empty: bool = False) -> tuple[str, ...]:
    if not isinstance(value, list) or (not value and not allow_empty):
        raise ConfigError(f"{label} must be {'a' if allow_empty else 'a nonempty'} string array")
    result = tuple(_string(item, label) for item in value)
    return result


def _confined_relative(repo: Path, value: Any, label: str) -> Path:
    raw = Path(_string(value, label))
    if raw.is_absolute() or ".." in raw.parts:
        raise ConfigError(f"{label} must be a confined repository-relative path")
    resolved = (repo / raw).resolve(strict=False)
    try:
        resolved.relative_to(repo.resolve())
    except ValueError as error:
        raise ConfigError(f"{label} escapes the repository") from error
    return raw


def validate_scope(value: str) -> str:
    if not isinstance(value, str) or not SCOPE_PATTERN.fullmatch(value):
        raise ConfigError(f"invalid scope {value!r}")
    return value


def _identifier(value: Any, label: str) -> str:
    result = _string(value, label)
    if not IDENTIFIER_PATTERN.fullmatch(result):
        raise ConfigError(f"{label} must be lowercase kebab-case")
    return result


def load_config(path: Path, repo: Path) -> RunnerConfig:
    try:
        root = _object(json.loads(path.read_text(encoding="utf-8")), "configuration")
    except (OSError, json.JSONDecodeError) as error:
        raise ConfigError(f"cannot read configuration {path}: {error}") from error
    _exact_keys(root, ROOT_KEYS, set(), "configuration")
    if root["schema_version"] != 1:
        raise ConfigError("schema_version must be 1")

    artifact_root = _confined_relative(repo, root["artifact_root"], "artifact_root")
    default_timeout = _positive_integer(root["default_timeout_seconds"], "default_timeout_seconds")
    output_limit = _positive_integer(root["max_output_bytes_per_stream"], "max_output_bytes_per_stream")

    policy_values = root["command_policies"]
    if not isinstance(policy_values, list) or not policy_values:
        raise ConfigError("command_policies must be a nonempty array")
    policies: list[CommandPolicy] = []
    policy_map: dict[str, CommandPolicy] = {}
    for index, raw_policy in enumerate(policy_values, start=1):
        policy = _object(raw_policy, f"command_policies[{index}]")
        _exact_keys(policy, POLICY_KEYS, set(), f"command_policies[{index}]")
        identifier = _identifier(policy["id"], f"command_policies[{index}].id")
        if identifier in policy_map:
            raise ConfigError(f"duplicate command policy id {identifier}")
        argv_prefix = _string_tuple(policy["argv_prefix"], f"policy {identifier} argv_prefix")
        if argv_prefix[0] == "git" and (
            len(argv_prefix) < 2 or argv_prefix[1] not in SAFE_GIT_SUBCOMMANDS
        ):
            raise ConfigError(f"unsafe Git policy {identifier}: authorize one read-only subcommand explicitly")
        parsed = CommandPolicy(identifier, argv_prefix)
        policy_map[identifier] = parsed
        policies.append(parsed)

    scope_values = _object(root["scopes"], "scopes")
    if not scope_values:
        raise ConfigError("scopes must not be empty")
    scopes: dict[str, ScopeConfig] = {}
    for scope_name, raw_scope in scope_values.items():
        scope_name = validate_scope(scope_name)
        scope = _object(raw_scope, f"scope {scope_name}")
        _exact_keys(scope, SCOPE_KEYS, set(), f"scope {scope_name}")
        workflow_id = _identifier(scope["workflow_id"], f"scope {scope_name} workflow_id")
        raw_steps = scope["steps"]
        if not isinstance(raw_steps, list) or not raw_steps:
            raise ConfigError(f"scope {scope_name} steps must be a nonempty array")
        steps: list[StepConfig] = []
        seen_steps: set[str] = set()
        for index, raw_step in enumerate(raw_steps, start=1):
            label = f"scope {scope_name} step {index}"
            step = _object(raw_step, label)
            _exact_keys(step, STEP_REQUIRED_KEYS, STEP_OPTIONAL_KEYS, label)
            identifier = _identifier(step["id"], f"{label} id")
            if identifier in seen_steps:
                raise ConfigError(f"duplicate step id {identifier} in scope {scope_name}")
            seen_steps.add(identifier)
            try:
                kind = StepKind(_string(step["kind"], f"{label} kind"))
            except ValueError as error:
                raise ConfigError(f"{label} kind is invalid") from error
            policy_id = _identifier(step["policy"], f"{label} policy")
            policy = policy_map.get(policy_id)
            if policy is None:
                raise ConfigError(f"{label} references absent policy {policy_id}")
            argv = _string_tuple(step["argv"], f"{label} argv")
            if argv[: len(policy.argv_prefix)] != policy.argv_prefix:
                raise ConfigError(f"{label} argv does not match policy {policy_id}")
            env_from = _string_tuple(step["env_from"], f"{label} env_from", allow_empty=True)
            missing_environment = [name for name in env_from if name not in os.environ]
            if missing_environment:
                raise ConfigError(f"{label} missing environment variable(s): {', '.join(missing_environment)}")
            required_artifacts = tuple(
                _confined_relative(repo, item, f"{label} required_artifacts")
                for item in step.get("required_artifacts", [])
            )
            steps.append(
                StepConfig(
                    identifier=identifier,
                    kind=kind,
                    policy=policy_id,
                    argv=argv,
                    cwd=_confined_relative(repo, step["cwd"], f"{label} cwd"),
                    timeout_seconds=_positive_integer(step["timeout_seconds"], f"{label} timeout_seconds"),
                    env_from=env_from,
                    required_artifacts=required_artifacts,
                )
            )
        scopes[scope_name] = ScopeConfig(scope_name, workflow_id, tuple(steps))

    return RunnerConfig(
        schema_version=1,
        source_path=path.resolve(),
        repository_root=repo.resolve(),
        artifact_root=artifact_root,
        default_timeout_seconds=default_timeout,
        max_output_bytes_per_stream=output_limit,
        command_policies=tuple(policies),
        scopes=scopes,
    )
