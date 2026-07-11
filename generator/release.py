"""generator/release.py — 릴리스 플로우: 해시·gzip·검증 게이트·원자적 스왑
(SP-GEN-10·11). 실패 시 이전 산출물 유지(무중단 지향, SP-ARCH-9).
"""
from __future__ import annotations

import gzip as gzip_module
import hashlib
import json
import os
import shutil
from datetime import datetime, timezone

from generator.checks import run_generated_checks
from generator.context import Page

_COMPRESSIBLE_EXT = (".html", ".xml", ".txt")
_MANIFEST_NAME = ".manifest.json"


def _is_compressible(path: str) -> bool:
    return path.endswith(_COMPRESSIBLE_EXT)


def _ensure_parent(path: str) -> None:
    parent = os.path.dirname(path)
    if parent:
        os.makedirs(parent, exist_ok=True)


def _reset_dir(path: str) -> None:
    if os.path.exists(path):
        shutil.rmtree(path)
    os.makedirs(path, exist_ok=True)


def _write_bytes(path: str, data: bytes) -> None:
    _ensure_parent(path)
    with open(path, "wb") as f:
        f.write(data)


def _copy(src: str, dst: str) -> None:
    _ensure_parent(dst)
    shutil.copyfile(src, dst)


def _gzip_if_smaller(target: str, data: bytes) -> int | None:
    """`.gz` 사전압축(level 9). 원본보다 크면 생략(gzip_static, §8)."""
    compressed = gzip_module.compress(data, compresslevel=9)
    if len(compressed) >= len(data):
        return None
    with open(target + ".gz", "wb") as f:
        f.write(compressed)
    return len(compressed)


def _load_manifest(out_dir: str) -> dict:
    manifest_path = os.path.join(out_dir, _MANIFEST_NAME)
    if not os.path.exists(manifest_path):
        return {}
    with open(manifest_path, encoding="utf-8") as f:
        return json.load(f).get("files", {})


def _atomic_swap(out_dir: str, next_dir: str) -> None:
    """`os.replace` 2단 디렉토리 rename — prev 백업 → next 승격(SP-ARCH-9)."""
    prev_dir = out_dir + ".prev"
    if os.path.exists(out_dir):
        if os.path.exists(prev_dir):
            shutil.rmtree(prev_dir)
        os.replace(out_dir, prev_dir)
    os.replace(next_dir, out_dir)


def stage_and_swap(out_dir: str, pages: list[Page], *, incremental: bool = False, gzip: bool = True) -> dict:
    """스테이징 → gzip → 해시 매니페스트 → 검증 게이트 → 원자적 스왑 (SP-GEN-11.1).

    검증(`run_generated_checks`) 실패 시 예외가 전파되고 `{out_dir}`는
    변경되지 않는다(스왑 미실행, GC-25).
    """
    nxt = out_dir + ".next"
    _reset_dir(nxt)
    prev_manifest = _load_manifest(out_dir) if incremental else {}
    manifest: dict[str, dict] = {}

    for p in pages:
        target = os.path.join(nxt, p.path)
        data = p.html.encode("utf-8")
        digest = hashlib.sha256(data).hexdigest()
        prev_entry = prev_manifest.get(p.path, {})
        prev_file = os.path.join(out_dir, p.path)
        if incremental and prev_entry.get("sha256") == digest and os.path.exists(prev_file):
            _copy(prev_file, target)  # 변경 없음 → 이전본 복사
        else:
            _write_bytes(target, data)
        gz_size = _gzip_if_smaller(target, data) if gzip and _is_compressible(p.path) else None
        manifest[p.path] = {"sha256": digest, "bytes": len(data), "gz": gz_size}

    run_generated_checks(nxt, pages)  # SP-GEN-12 게이트 — 실패 시 예외 전파, 스왑 중단
    _atomic_swap(out_dir, nxt)
    return manifest


def write_manifest(out_dir: str, manifest: dict) -> None:
    """`.manifest.json` 기록 — 증분·릴리스 검증용(gitignore 대상)."""
    payload = {
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "files": manifest,
    }
    _ensure_parent(os.path.join(out_dir, _MANIFEST_NAME))
    with open(os.path.join(out_dir, _MANIFEST_NAME), "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)
