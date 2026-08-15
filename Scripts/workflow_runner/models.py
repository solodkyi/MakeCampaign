from __future__ import annotations

from dataclasses import dataclass
from enum import StrEnum
from pathlib import Path
from typing import Mapping


class StepKind(StrEnum):
    BUILD = "build"
    UNIT = "unit"
    INTEGRATION = "integration"
    SIMULATOR = "simulator"
    OTHER = "other"


class StepStatus(StrEnum):
    PENDING = "pending"
    RUNNING = "running"
    PASSED = "passed"
    FAILED = "failed"
    TIMED_OUT = "timed_out"
    SKIPPED = "skipped"
    INTERRUPTED = "interrupted"


class RunStatus(StrEnum):
    RUNNING = "running"
    PASSED = "passed"
    FAILED = "failed"
    INTERRUPTED = "interrupted"


@dataclass(frozen=True)
class CommandPolicy:
    identifier: str
    argv_prefix: tuple[str, ...]


@dataclass(frozen=True)
class StepConfig:
    identifier: str
    kind: StepKind
    policy: str
    argv: tuple[str, ...]
    cwd: Path
    timeout_seconds: int
    env_from: tuple[str, ...]
    required_artifacts: tuple[Path, ...]


@dataclass(frozen=True)
class ScopeConfig:
    scope: str
    workflow_id: str
    steps: tuple[StepConfig, ...]


@dataclass(frozen=True)
class RunnerConfig:
    schema_version: int
    source_path: Path
    repository_root: Path
    artifact_root: Path
    default_timeout_seconds: int
    max_output_bytes_per_stream: int
    command_policies: tuple[CommandPolicy, ...]
    scopes: Mapping[str, ScopeConfig]


@dataclass(frozen=True)
class RepositoryState:
    head: str
    dirty: bool
    status: str
    status_sha256: str


@dataclass(frozen=True)
class StepResult:
    identifier: str
    status: StepStatus
    exit_code: int | None
    timed_out: bool
    started_at: str
    finished_at: str
    duration_ms: int
    stdout_bytes: int
    stderr_bytes: int
    stdout_truncated: bool
    stderr_truncated: bool
