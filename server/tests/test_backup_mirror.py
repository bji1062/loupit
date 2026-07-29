"""SP-INFRA-10.2 — backup.sh 2차 사본(미러) 계약 (BK-1~BK-5).

`/db`(별도 블록 디바이스)에 두는 두 번째 사본을 검사한다. 노리는 위험은 **디바이스 단위
장애**다 — 루트 디스크가 죽으면 미러로, `/db` 볼륨이 죽으면 1차로 복구한다.
(⚠ 머신 손실은 둘 다 잃는다. 서버 밖 사본은 별개 과제로 남아 있다.)

`mysqldump` 는 스텁으로 갈음한다 — **여기서 검증 대상은 셸 스크립트의 파일 수명주기**이지
덤프 자체가 아니다(덤프 정합은 restore 실증이 따로 담당). 스텁이 가리는 영역을 분명히
해두는 이유는 함정 ㉒(스텁이 실드라이버를 검증하지 않아 거짓 초록을 냈다) 때문이다.
"""

from __future__ import annotations

import gzip
import os
import subprocess
import time
from pathlib import Path

import pytest

BACKUP_SH = Path(__file__).resolve().parents[2] / "infra" / "deploy" / "backup.sh"

# mysqldump 가 내는 것과 같은 꼬리(트레일러)를 가진 최소 덤프 — 스크립트의 무결성 검증 2를 통과해야 한다.
_FAKE_DUMP_BODY = "-- fake dump\nCREATE TABLE t(i INT);\n-- Dump completed on 2026-07-29\n"


@pytest.fixture
def fake_mysqldump(tmp_path: Path) -> Path:
    p = tmp_path / "fake-mysqldump"
    # 히어독으로 낸다 — printf 로 넘기면 개행이 리터럴 '\n' 두 글자로 들어가 스텁이 조용히 망가진다.
    p.write_text(f"#!/usr/bin/env bash\ncat <<'DUMP'\n{_FAKE_DUMP_BODY}DUMP\n", encoding="utf-8")
    p.chmod(0o755)
    return p


def _run(fake_mysqldump: Path, backup_dir: Path, **env_extra: str):
    env = {
        **os.environ,
        "DB_PASSWORD": "unused-by-stub",
        "BACKUP_DIR": str(backup_dir),
        "MYSQLDUMP": str(fake_mysqldump),
        **env_extra,
    }
    return subprocess.run(
        ["bash", str(BACKUP_SH)], env=env, capture_output=True, text=True, timeout=60
    )


def _dumps(d: Path) -> list[Path]:
    return sorted(d.glob("loupit-*.sql.gz"))


def _backdate(p: Path, days: int) -> None:
    old = time.time() - days * 86400
    os.utime(p, (old, old))


# ── BK-1: 미러 미설정 → 기존 동작 그대로 ──────────────────────────────────
def test_BK1_no_mirror_configured_keeps_old_behaviour(fake_mysqldump, tmp_path):
    primary = tmp_path / "primary"
    r = _run(fake_mysqldump, primary)
    assert r.returncode == 0, r.stderr
    assert len(_dumps(primary)) == 1
    assert "mirrored" not in r.stdout


# ── BK-2: 미러 설정 → 두 사본, 내용 동일 ──────────────────────────────────
def test_BK2_mirror_copy_is_written_and_identical(fake_mysqldump, tmp_path):
    primary, mirror = tmp_path / "primary", tmp_path / "mirror"
    r = _run(fake_mysqldump, primary, MIRROR_DIR=str(mirror))
    assert r.returncode == 0, r.stderr

    (p,), (m,) = _dumps(primary), _dumps(mirror)
    assert p.name == m.name, "미러 사본은 같은 파일명을 써야 한다(복원 절차가 이름으로 짝짓는다)"
    assert gzip.decompress(p.read_bytes()) == gzip.decompress(m.read_bytes())
    assert "Dump completed" in gzip.decompress(m.read_bytes()).decode()
    assert "mirrored" in r.stdout


# ── BK-3: 미러 보관 주기는 1차와 독립 ─────────────────────────────────────
def test_BK3_mirror_retention_is_independent(fake_mysqldump, tmp_path):
    primary, mirror = tmp_path / "primary", tmp_path / "mirror"
    primary.mkdir(), mirror.mkdir()

    # 10일 된 사본을 양쪽에 심는다 — 1차(14일)는 살고, 미러(7일)는 지워져야 한다.
    for d in (primary, mirror):
        old = d / "loupit-20260101.sql.gz"
        old.write_bytes(gzip.compress(b"old"))
        _backdate(old, 10)

    r = _run(fake_mysqldump, primary, MIRROR_DIR=str(mirror), MIRROR_RETENTION_DAYS="7")
    assert r.returncode == 0, r.stderr
    assert (primary / "loupit-20260101.sql.gz").exists(), "1차 14일 보관이 미러 설정에 영향받았다"
    assert not (mirror / "loupit-20260101.sql.gz").exists(), "미러 7일 로테이션이 동작하지 않았다"


# ── BK-4: 미러 실패가 1차 백업을 파괴하지 않는다 ────────────────────────────
def test_BK4_mirror_failure_never_destroys_primary(fake_mysqldump, tmp_path):
    """미러 경로를 만들 수 없게 막는다 → 비0 종료로 알리되 1차는 온전해야 한다.

    이 순서가 핵심이다: 미러는 1차가 **확정된 뒤에만** 손댄다. 반대로 짜면
    2차 사본을 늘리려다 1차까지 잃는다.
    """
    primary = tmp_path / "primary"
    blocker = tmp_path / "blocker"
    blocker.write_text("파일이라 하위 디렉터리를 만들 수 없다", encoding="utf-8")

    r = _run(fake_mysqldump, primary, MIRROR_DIR=str(blocker / "nested"))
    assert r.returncode != 0, "미러 실패가 조용히 성공으로 보고됐다"
    assert len(_dumps(primary)) == 1, "미러 실패가 1차 백업을 앗아갔다"
    # 남은 1차가 '있기만' 한 게 아니라 **복원 가능**해야 의미가 있다.
    assert "Dump completed" in gzip.decompress(_dumps(primary)[0].read_bytes()).decode()
    assert not list(primary.glob("*.partial.*")), "1차 부분 파일이 남았다"


# ── BK-5: 미러의 부분 파일 잔여물도 청소된다 ────────────────────────────────
def test_BK5_mirror_stale_partials_are_cleaned(fake_mysqldump, tmp_path):
    primary, mirror = tmp_path / "primary", tmp_path / "mirror"
    primary.mkdir(), mirror.mkdir()
    stale = mirror / "loupit-20260101.sql.gz.partial.999"
    stale.write_bytes(b"truncated")
    _backdate(stale, 3)
    fresh = mirror / "loupit-20260102.sql.gz.partial.998"
    fresh.write_bytes(b"in-flight")

    r = _run(fake_mysqldump, primary, MIRROR_DIR=str(mirror))
    assert r.returncode == 0, r.stderr
    assert not stale.exists(), "1일 지난 미러 부분 파일이 남았다"
    assert fresh.exists(), "진행 중일 수 있는 당일 부분 파일을 지웠다"
