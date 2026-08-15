from __future__ import annotations

import hashlib
import json
import os
import re
import secrets
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

from .models import RepositoryState, RunStatus, ScopeConfig, StepResult, StepStatus


RUN_ID_PATTERN = re.compile(r"^\d{8}T\d{12}Z-[0-9a-f]{12}$")


class ArtifactError(RuntimeError):
    pass


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")


def _run_id() -> str:
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    return f"{timestamp}-{secrets.token_hex(6)}"


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


class ArtifactStore:
    def __init__(self, path: Path, manifest: dict[str, Any], step_indexes: dict[str, int]):
        self.path = path
        self._manifest = manifest
        self._step_indexes = step_indexes
        self._finalized = False

    @classmethod
    def create(
        cls,
        root: Path,
        scope: ScopeConfig,
        config_path: Path,
        config_hash: str,
        repository: RepositoryState,
    ) -> "ArtifactStore":
        scope_root, scope_slug = scope.scope.split("/", 1)
        parent = root / scope_root / scope_slug
        parent.mkdir(parents=True, exist_ok=True)
        for _ in range(100):
            run_id = _run_id()
            path = parent / run_id
            try:
                path.mkdir()
                break
            except FileExistsError:
                continue
        else:
            raise ArtifactError(f"could not allocate unique run directory under {parent}")
        (path / "steps").mkdir()
        started_at = _utc_now()
        steps = [
            {
                "id": step.identifier,
                "kind": step.kind.value,
                "argv": list(step.argv),
                "cwd": step.cwd.as_posix(),
                "status": StepStatus.PENDING.value,
                "exit_code": None,
                "timed_out": False,
            }
            for step in scope.steps
        ]
        manifest: dict[str, Any] = {
            "schema_version": 1,
            "run_id": run_id,
            "scope": scope.scope,
            "workflow_id": scope.workflow_id,
            "config_path": config_path.as_posix(),
            "config_sha256": config_hash,
            "repository": {
                "head": repository.head,
                "dirty": repository.dirty,
                "status_sha256": repository.status_sha256,
            },
            "started_at": started_at,
            "finished_at": None,
            "duration_ms": None,
            "status": RunStatus.RUNNING.value,
            "runner_exit_code": None,
            "steps": steps,
        }
        store = cls(path, manifest, {step.identifier: index for index, step in enumerate(scope.steps)})
        store._write_event("run_started", {"started_at": started_at})
        store._write_manifest()
        return store

    def _ensure_mutable(self) -> None:
        if self._finalized:
            raise ArtifactError(f"run is finalized: {self.path}")

    def _write_manifest(self) -> None:
        temporary = self.path / ".run.json.tmp"
        temporary.write_text(json.dumps(self._manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        os.replace(temporary, self.path / "run.json")

    def _write_event(self, event: str, data: dict[str, Any]) -> None:
        record = {"event": event, "at": _utc_now(), **data}
        with (self.path / "events.jsonl").open("a", encoding="utf-8") as stream:
            stream.write(json.dumps(record, sort_keys=True) + "\n")

    def _step(self, identifier: str) -> tuple[int, dict[str, Any]]:
        try:
            index = self._step_indexes[identifier]
        except KeyError as error:
            raise ArtifactError(f"unknown step {identifier}") from error
        return index, self._manifest["steps"][index]

    def start_step(self, identifier: str) -> tuple[Path, Path]:
        self._ensure_mutable()
        index, step = self._step(identifier)
        if step["status"] != StepStatus.PENDING.value:
            raise ArtifactError(f"step {identifier} is not pending")
        step["status"] = StepStatus.RUNNING.value
        step["started_at"] = _utc_now()
        stem = f"{index + 1:02d}-{identifier}"
        stdout_path = self.path / "steps" / f"{stem}.stdout.log"
        stderr_path = self.path / "steps" / f"{stem}.stderr.log"
        stdout_path.touch(exist_ok=False)
        stderr_path.touch(exist_ok=False)
        step["stdout_log"] = stdout_path.relative_to(self.path).as_posix()
        step["stderr_log"] = stderr_path.relative_to(self.path).as_posix()
        self._write_event("step_started", {"step": identifier})
        self._write_manifest()
        return stdout_path, stderr_path

    def finish_step(self, result: StepResult) -> None:
        self._ensure_mutable()
        _, step = self._step(result.identifier)
        if step["status"] != StepStatus.RUNNING.value:
            raise ArtifactError(f"step {result.identifier} is not running")
        stdout_path = self.path / step["stdout_log"]
        stderr_path = self.path / step["stderr_log"]
        step.update(
            {
                "status": result.status.value,
                "exit_code": result.exit_code,
                "timed_out": result.timed_out,
                "started_at": result.started_at,
                "finished_at": result.finished_at,
                "duration_ms": result.duration_ms,
                "stdout_bytes": result.stdout_bytes,
                "stderr_bytes": result.stderr_bytes,
                "stdout_stored_bytes": stdout_path.stat().st_size,
                "stderr_stored_bytes": stderr_path.stat().st_size,
                "stdout_truncated": result.stdout_truncated,
                "stderr_truncated": result.stderr_truncated,
                "stdout_sha256": _sha256(stdout_path),
                "stderr_sha256": _sha256(stderr_path),
            }
        )
        self._write_event("step_finished", {"step": result.identifier, "status": result.status.value})
        self._write_manifest()

    def skip_steps(self, identifiers: Iterable[str]) -> None:
        self._ensure_mutable()
        for identifier in identifiers:
            _, step = self._step(identifier)
            if step["status"] != StepStatus.PENDING.value:
                raise ArtifactError(f"step {identifier} is not pending")
            step["status"] = StepStatus.SKIPPED.value
        self._write_manifest()

    def finalize(self, status: RunStatus, exit_code: int) -> None:
        self._ensure_mutable()
        finished_at = _utc_now()
        start = datetime.fromisoformat(self._manifest["started_at"].replace("Z", "+00:00"))
        finish = datetime.fromisoformat(finished_at.replace("Z", "+00:00"))
        self._manifest.update(
            {
                "finished_at": finished_at,
                "duration_ms": max(0, int((finish - start).total_seconds() * 1000)),
                "status": status.value,
                "runner_exit_code": exit_code,
            }
        )
        self._write_event("run_finished", {"status": status.value, "runner_exit_code": exit_code})
        self._write_manifest()
        self._finalized = True


def load_manifest(path: Path) -> dict[str, Any]:
    try:
        value = json.loads((path / "run.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ArtifactError(f"cannot read run manifest at {path}: {error}") from error
    if not isinstance(value, dict):
        raise ArtifactError(f"run manifest must be an object: {path}")
    return value


def verify_run(path: Path) -> list[str]:
    errors: list[str] = []
    try:
        manifest = load_manifest(path)
    except ArtifactError as error:
        return [str(error)]
    if manifest.get("schema_version") != 1:
        errors.append("schema_version must be 1")
    run_id = manifest.get("run_id")
    if not isinstance(run_id, str) or not RUN_ID_PATTERN.fullmatch(run_id):
        errors.append("run_id is invalid")
    elif path.name != run_id:
        errors.append("run directory name does not match run_id")
    status = manifest.get("status")
    exit_code = manifest.get("runner_exit_code")
    if status == RunStatus.PASSED.value and exit_code != 0:
        errors.append("passed run must have runner exit code 0")
    if status == RunStatus.FAILED.value and (not isinstance(exit_code, int) or exit_code == 0):
        errors.append("failed run must have a nonzero runner exit code")
    if status not in {RunStatus.PASSED.value, RunStatus.FAILED.value, RunStatus.INTERRUPTED.value}:
        errors.append("run is not finalized")
    steps = manifest.get("steps")
    if not isinstance(steps, list) or not steps:
        errors.append("steps must be a nonempty array")
        return errors
    seen: set[str] = set()
    for step in steps:
        identifier = step.get("id") if isinstance(step, dict) else None
        if not isinstance(identifier, str) or identifier in seen:
            errors.append("step identifiers must be unique strings")
            continue
        seen.add(identifier)
        step_status = step.get("status")
        if step_status in {
            StepStatus.PASSED.value,
            StepStatus.FAILED.value,
            StepStatus.TIMED_OUT.value,
            StepStatus.INTERRUPTED.value,
        }:
            for stream_name in ("stdout", "stderr"):
                relative = step.get(f"{stream_name}_log")
                expected = step.get(f"{stream_name}_sha256")
                if not isinstance(relative, str) or not isinstance(expected, str):
                    errors.append(f"step {identifier} is missing {stream_name} log metadata")
                    continue
                log_path = path / relative
                if not log_path.is_file():
                    errors.append(f"step {identifier} {stream_name} log is missing")
                elif _sha256(log_path) != expected:
                    errors.append(f"step {identifier} {stream_name} hash mismatch")
                if log_path.is_file():
                    stored = step.get(f"{stream_name}_stored_bytes")
                    observed = step.get(f"{stream_name}_bytes")
                    truncated = step.get(f"{stream_name}_truncated")
                    actual = log_path.stat().st_size
                    if stored != actual:
                        errors.append(f"step {identifier} {stream_name} stored byte count mismatch")
                    if not isinstance(observed, int) or observed < actual:
                        errors.append(f"step {identifier} {stream_name} observed byte count is invalid")
                    elif truncated is not (observed > actual):
                        errors.append(f"step {identifier} {stream_name} truncation flag is inconsistent")
        elif step_status != StepStatus.SKIPPED.value:
            errors.append(f"step {identifier} has nonfinal status {step_status}")
        if step_status == StepStatus.SKIPPED.value and step.get("exit_code") is not None:
            errors.append(f"skipped step {identifier} must not have an exit code")
    if status == RunStatus.PASSED.value and any(step.get("status") != StepStatus.PASSED.value for step in steps):
        errors.append("passed run requires every step to pass")

    events_path = path / "events.jsonl"
    events: list[dict[str, Any]] = []
    try:
        for line_number, line in enumerate(events_path.read_text(encoding="utf-8").splitlines(), start=1):
            value = json.loads(line)
            if not isinstance(value, dict) or not isinstance(value.get("event"), str):
                errors.append(f"events line {line_number} is malformed")
                continue
            events.append(value)
    except (OSError, json.JSONDecodeError) as error:
        errors.append(f"events stream is unreadable: {error}")
    expected_events = ["run_started"]
    for step in steps:
        if step.get("status") != StepStatus.SKIPPED.value:
            expected_events.extend(("step_started", "step_finished"))
    expected_events.append("run_finished")
    if [event["event"] for event in events] != expected_events:
        errors.append("events stream is incomplete or out of order")
    return errors
