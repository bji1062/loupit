"""P3-④ — nginx logrotate 크기 상한 패치 계약 (LR-1~LR-6).

**왜 이 파일이 있나**: 이 패치는 `/etc/logrotate.d/nginx` 라는 **패키지 conffile** 을
손댄다. 그런 변경은 두 방향으로 조용히 죽는다.

1. 앵커(`daily`)가 사라지면 패치가 **0줄을 끼우고 성공한 척**한다 → 함정 ㉝(오타 slug 가
   에러 없이 0행을 넣는다)과 같은 부류다. LR-3 이 그 침묵을 금지한다.
2. 리포의 패치가 만드는 결과와 **실호스트에 배포된 파일이 어긋나도** 아무도 모른다.
   LR-6 이 실호스트에서만 그 표류를 잡는다.

LR-5 는 자기검증이다 — 패치가 실제로 무언가를 바꾸는지 확인한다. "위반이 없다"만 재는
가드는 파서가 아무것도 못 읽어도 초록이다(함정 ㉙·SED-6).
"""

from __future__ import annotations

import importlib.util
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
PATCHER = ROOT / "infra" / "logrotate" / "patch_nginx_maxsize.py"

DEPLOYED = Path("/etc/logrotate.d/nginx")
ORIGINAL_BACKUP = Path("/var/backups/loupit-config/logrotate.d-nginx.orig")

# nginx-common 의 conffile 을 줄인 형태. 앵커(`daily`)와 탭 들여쓰기가 실물과 같다.
SAMPLE = (
    "/var/log/nginx/*.log {\n"
    "\tdaily\n"
    "\tmissingok\n"
    "\trotate 14\n"
    "\tcompress\n"
    "}\n"
)


@pytest.fixture(scope="module")
def patcher():
    spec = importlib.util.spec_from_file_location("patch_nginx_maxsize", PATCHER)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def test_LR1_maxsize_inserted_right_after_daily(patcher):
    """LR-1: `daily` 바로 다음 줄부터 블록이 들어간다.

    위치가 의미를 만든다 — "하루에 한 번" 옆에 "단, 200M 넘으면 그 전에도"가 붙어야
    읽는 사람이 두 조건의 관계를 안다.
    """
    out = patcher.patch(SAMPLE)
    lines = out.splitlines()
    daily_at = lines.index("\tdaily")
    assert "maxsize 200M" in "\n".join(lines[daily_at + 1 : daily_at + 4])


def test_LR2_idempotent(patcher):
    """LR-2: 두 번 적용해도 한 번 적용한 것과 같다(프로비저닝은 재실행된다)."""
    once = patcher.patch(SAMPLE)
    twice = patcher.patch(once)
    assert twice == once
    assert once.count("maxsize") == 1


def test_LR3_missing_anchor_fails_loudly(patcher):
    """LR-3: 앵커가 없으면 **조용한 no-op 이 아니라 중단**이다.

    패키지가 `daily` → `weekly` 로 바꾸면 패치는 끼울 곳을 잃는다. 그때 원본을 그대로
    돌려주면 프로비저닝은 초록인데 상한은 영영 없다 — 함정 ㉝ 그대로다.
    """
    without_anchor = SAMPLE.replace("\tdaily\n", "\tweekly\n")
    with pytest.raises(SystemExit) as exc:
        patcher.patch(without_anchor)
    assert "앵커" in str(exc.value)


def test_LR4_existing_maxsize_is_respected(patcher):
    """LR-4: 이미 `maxsize` 가 있으면(상류가 넣었든 사람이 넣었든) 건드리지 않는다."""
    already = SAMPLE.replace("\tdaily\n", "\tdaily\n\tmaxsize 50M\n")
    assert patcher.patch(already) == already


def test_LR5_patch_actually_changes_something(patcher):
    """LR-5(자기검증): 패치가 실제로 입력을 바꾸는가.

    LR-1~4 는 전부 "이런 성질이 성립한다" 형태라, `patch` 가 입력을 그대로 돌려주는
    껍데기여도 LR-2·LR-4 는 통과한다. 변화 자체를 재는 축이 따로 있어야 한다.
    """
    out = patcher.patch(SAMPLE)
    assert out != SAMPLE, "패치가 아무것도 바꾸지 않았다 — 나머지 어서션은 무의미하다"
    assert "maxsize" not in SAMPLE, "표본이 이미 오염됐다(테스트 전제 붕괴)"


@pytest.mark.skipif(
    not (DEPLOYED.exists() and ORIGINAL_BACKUP.exists()),
    reason="실호스트 전용 — 배포본 또는 원본 백업이 없다",
)
def test_LR6_repo_patch_matches_deployed_file(patcher):
    """LR-6(실호스트 표류 감지): 리포의 패치가 만드는 결과 == 실제 배포된 파일.

    사람이 서버에서 손으로 고치고 리포에 반영하지 않으면 다음 프로비저닝이 그 손질을
    말없이 되돌린다. 그 어긋남을 여기서 잡는다.
    """
    produced = patcher.patch(ORIGINAL_BACKUP.read_text())
    assert produced == DEPLOYED.read_text(), (
        "리포의 패치 결과와 /etc/logrotate.d/nginx 가 다르다 — "
        "서버에서 손으로 고쳤거나 패키지가 원본을 갱신했다."
    )
