from __future__ import annotations

import hashlib
import subprocess
from pathlib import Path

from .models import RepositoryState


class RepositoryError(ValueError):
    pass


def _git(repo: Path, *arguments: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *arguments],
        cwd=repo,
        text=True,
        capture_output=True,
        check=False,
        stdin=subprocess.DEVNULL,
    )


def discover_repository(start: Path) -> Path:
    result = _git(start, "rev-parse", "--show-toplevel")
    if result.returncode != 0:
        raise RepositoryError(f"cannot discover repository from {start}: {result.stderr.strip()}")
    return Path(result.stdout.strip()).resolve()


def resolve_confined(repo: Path, value: str | Path) -> Path:
    raw = Path(value)
    if raw.is_absolute() or ".." in raw.parts:
        raise RepositoryError(f"path must remain inside repository: {value}")
    resolved = (repo / raw).resolve(strict=False)
    try:
        resolved.relative_to(repo.resolve())
    except ValueError as error:
        raise RepositoryError(f"path escapes repository: {value}") from error
    return resolved


def require_clean_tracked_config(repo: Path, config: Path) -> None:
    resolved = config.resolve()
    try:
        relative = resolved.relative_to(repo.resolve())
    except ValueError as error:
        raise RepositoryError(f"configuration must be inside repository: {config}") from error
    if not resolved.is_file() or resolved.is_symlink():
        raise RepositoryError(f"configuration must be a regular file: {config}")
    tracked = _git(repo, "ls-files", "--error-unmatch", "--", relative.as_posix())
    if tracked.returncode != 0:
        raise RepositoryError(f"configuration must be tracked: {relative}")
    clean = _git(repo, "diff", "--quiet", "HEAD", "--", relative.as_posix())
    if clean.returncode != 0:
        raise RepositoryError(f"configuration must be clean relative to HEAD: {relative}")


def read_repository_state(repo: Path) -> RepositoryState:
    head_result = _git(repo, "rev-parse", "HEAD")
    if head_result.returncode != 0:
        raise RepositoryError(f"cannot read repository HEAD: {head_result.stderr.strip()}")
    status_result = _git(repo, "status", "--porcelain=v1", "--untracked-files=all")
    if status_result.returncode != 0:
        raise RepositoryError(f"cannot read repository status: {status_result.stderr.strip()}")
    status = status_result.stdout
    return RepositoryState(
        head=head_result.stdout.strip(),
        dirty=bool(status),
        status=status,
        status_sha256=hashlib.sha256(status.encode("utf-8")).hexdigest(),
    )
