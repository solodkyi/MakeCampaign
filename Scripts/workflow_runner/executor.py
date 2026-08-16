from __future__ import annotations

import os
import signal
import subprocess
import threading
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import BinaryIO, Mapping

from .artifacts import ArtifactStore
from .models import RunStatus, RunnerConfig, ScopeConfig, StepResult, StepStatus


BASE_ENVIRONMENT_NAMES = ("PATH", "TMPDIR", "DEVELOPER_DIR", "SDKROOT")


def _now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")


def _drain(pipe: BinaryIO, path: Path, limit: int, stats: dict[str, int | bool]) -> None:
    observed = 0
    stored = 0
    with path.open("wb") as output:
        while True:
            chunk = pipe.read(65536)
            if not chunk:
                break
            observed += len(chunk)
            remaining = max(0, limit - stored)
            if remaining:
                kept = chunk[:remaining]
                output.write(kept)
                stored += len(kept)
    stats["bytes"] = observed
    stats["truncated"] = observed > stored


def _terminate_process_group(process: subprocess.Popen[bytes]) -> None:
    if process.poll() is not None:
        return
    try:
        os.killpg(process.pid, signal.SIGTERM)
        process.wait(timeout=5)
    except (ProcessLookupError, subprocess.TimeoutExpired):
        if process.poll() is None:
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            process.wait()


def _environment(step_env: tuple[str, ...], base: Mapping[str, str]) -> dict[str, str]:
    environment = {name: base[name] for name in BASE_ENVIRONMENT_NAMES if name in base}
    environment["CI"] = "1"
    for name in step_env:
        environment[name] = base[name]
    return environment


def execute_workflow(
    config: RunnerConfig,
    scope: ScopeConfig,
    artifacts: ArtifactStore,
    base_environment: Mapping[str, str],
) -> int:
    for index, step in enumerate(scope.steps):
        stdout_path, stderr_path = artifacts.start_step(step.identifier)
        stdout_stats: dict[str, int | bool] = {"bytes": 0, "truncated": False}
        stderr_stats: dict[str, int | bool] = {"bytes": 0, "truncated": False}
        started_at = _now()
        started_clock = time.monotonic()
        process: subprocess.Popen[bytes] | None = None
        status = StepStatus.FAILED
        timed_out = False
        exit_code: int | None = None
        runner_exit_code = 3
        try:
            process = subprocess.Popen(
                step.argv,
                cwd=config.repository_root / step.cwd,
                env=_environment(step.env_from, base_environment),
                stdin=subprocess.DEVNULL,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                shell=False,
                start_new_session=True,
            )
            assert process.stdout is not None
            assert process.stderr is not None
            readers = (
                threading.Thread(
                    target=_drain,
                    args=(process.stdout, stdout_path, config.max_output_bytes_per_stream, stdout_stats),
                    daemon=True,
                ),
                threading.Thread(
                    target=_drain,
                    args=(process.stderr, stderr_path, config.max_output_bytes_per_stream, stderr_stats),
                    daemon=True,
                ),
            )
            for reader in readers:
                reader.start()
            try:
                process.wait(timeout=step.timeout_seconds)
            except subprocess.TimeoutExpired:
                timed_out = True
                _terminate_process_group(process)
            except KeyboardInterrupt:
                _terminate_process_group(process)
                for reader in readers:
                    reader.join()
                process.stdout.close()
                process.stderr.close()
                finished_at = _now()
                artifacts.finish_step(
                    StepResult(
                        step.identifier,
                        StepStatus.INTERRUPTED,
                        process.returncode,
                        False,
                        started_at,
                        finished_at,
                        int((time.monotonic() - started_clock) * 1000),
                        int(stdout_stats["bytes"]),
                        int(stderr_stats["bytes"]),
                        bool(stdout_stats["truncated"]),
                        bool(stderr_stats["truncated"]),
                    )
                )
                artifacts.skip_steps(item.identifier for item in scope.steps[index + 1 :])
                artifacts.finalize(RunStatus.INTERRUPTED, 130)
                return 130
            for reader in readers:
                reader.join()
            process.stdout.close()
            process.stderr.close()
            exit_code = process.returncode
            if timed_out:
                status = StepStatus.TIMED_OUT
                runner_exit_code = 4
            elif exit_code == 0:
                missing = [
                    path for path in step.required_artifacts if not (config.repository_root / path).exists()
                ]
                if missing:
                    message = (
                        "missing required artifact(s): "
                        + ", ".join(path.as_posix() for path in missing)
                        + "\n"
                    ).encode()
                    remaining = max(
                        0,
                        config.max_output_bytes_per_stream - stderr_path.stat().st_size,
                    )
                    with stderr_path.open("ab") as stream:
                        stream.write(message[:remaining])
                    stderr_stats["bytes"] = int(stderr_stats["bytes"]) + len(message)
                    stderr_stats["truncated"] = bool(stderr_stats["truncated"]) or len(message) > remaining
                    status = StepStatus.FAILED
                else:
                    status = StepStatus.PASSED
                    runner_exit_code = 0
            else:
                status = StepStatus.FAILED
        except (OSError, KeyError) as error:
            message = f"runner could not execute step {step.identifier}: {error}\n".encode()
            stderr_path.write_bytes(message[: config.max_output_bytes_per_stream])
            stderr_stats = {"bytes": len(message), "truncated": len(message) > config.max_output_bytes_per_stream}
            runner_exit_code = 5

        finished_at = _now()
        artifacts.finish_step(
            StepResult(
                identifier=step.identifier,
                status=status,
                exit_code=exit_code,
                timed_out=timed_out,
                started_at=started_at,
                finished_at=finished_at,
                duration_ms=int((time.monotonic() - started_clock) * 1000),
                stdout_bytes=int(stdout_stats["bytes"]),
                stderr_bytes=int(stderr_stats["bytes"]),
                stdout_truncated=bool(stdout_stats["truncated"]),
                stderr_truncated=bool(stderr_stats["truncated"]),
            )
        )
        if status != StepStatus.PASSED:
            artifacts.skip_steps(item.identifier for item in scope.steps[index + 1 :])
            artifacts.finalize(RunStatus.FAILED, runner_exit_code)
            return runner_exit_code

    artifacts.finalize(RunStatus.PASSED, 0)
    return 0
