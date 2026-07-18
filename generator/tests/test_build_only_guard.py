"""발견 #9 회귀 — --only 가 프로덕션 out(web/dist)으로 스왑되는 사고를 막는다.

순수 CLI 가드(DB 무접촉): `_reject_only_prod_swap` 단위 + `main()`이 DB 로드
이전에 거부(코드 2)하는지 확인한다. run_tests.sh [2/5] generator 스위트에서
DB 없이 구동된다(conftest는 fake 번들만).
"""
from __future__ import annotations

from generator import build as build_module
from generator.build import _reject_only_prod_swap
from generator.config import CFG


def test_only_into_prod_dist_is_rejected():
    msg = _reject_only_prod_swap(CFG.out_dir, ["company/kakao"], force=False)
    assert msg is not None
    assert "web/dist-dev" in msg  # 안전 대안 제시


def test_only_into_prod_dist_default_out_rejected():
    """--out 미지정(기본=web/dist)도 동일하게 거부돼야 한다."""
    assert _reject_only_prod_swap("web/dist", ["company/kakao"], force=False) is not None
    # 경로 정규화: 후행 슬래시/상대표기도 같은 서빙 dist 로 취급
    assert _reject_only_prod_swap("web/dist/", ["company/kakao"], force=False) is not None


def test_only_into_separate_out_allowed():
    assert _reject_only_prod_swap("web/dist-dev", ["company/kakao"], force=False) is None


def test_full_build_into_prod_dist_allowed():
    """--only 없는 전체 빌드는 프로덕션 out 이어도 허용(정상 릴리스 경로)."""
    assert _reject_only_prod_swap(CFG.out_dir, None, force=False) is None
    assert _reject_only_prod_swap(CFG.out_dir, [], force=False) is None


def test_force_prod_out_overrides_guard():
    assert _reject_only_prod_swap(CFG.out_dir, ["company/kakao"], force=True) is None


def test_main_refuses_only_prod_swap_before_db(capsys):
    """main()은 load_bundle(DB) 이전에 거부하고 종료코드 2를 반환한다."""
    rc = build_module.main(["--only", "company/kakao"])  # --out 기본 = web/dist
    assert rc == 2
    err = capsys.readouterr().err
    assert "refused" in err
