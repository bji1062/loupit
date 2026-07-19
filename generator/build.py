"""generator/build.py — 엔트리 CLI: 번들→렌더→검증→web/dist (SP-GEN-1.4).

SP-INFRA `release.sh`가 호출: `python -m generator.build --out web/dist`.
종료 코드 0=성공(검증 통과·스왑 완료), 비0=렌더/검증/스왑 실패(이전 산출물
유지, SP-ARCH-9).
"""
from __future__ import annotations

import argparse
import os
import sys
from datetime import date

from generator.bundle import load_bundle, load_bundle_json
from generator.config import CFG
from generator.context import build_context
from generator.pages import combo, company, policy
from generator.pages import sitemap as sitemap_page
from generator.release import stage_and_swap, write_manifest
from generator.render import make_env


def _today_iso() -> str:
    return date.today().isoformat()


def run(
    out_dir: str,
    bundle: dict,
    *,
    incremental: bool = False,
    only: list[str] | None = None,
    lastmod: str | None = None,
    gzip: bool = True,
) -> int:
    """번들 → 렌더(회사·조합·정책·404) → sitemap/robots → 검증·원자 스왑.

    성공 시 0 반환. 실패(렌더/검증/스왑)는 `BuildError` 등 예외로 전파되며
    `{out_dir}`는 변경되지 않는다(`main()`이 비0 종료코드로 표면화).
    """
    env = make_env()
    ctx = build_context(bundle)  # 인덱스·slug 충돌 검증(BuildError, SP-GEN-3)
    # 조합 쌍은 한 번만 로드해 양쪽에 전달한다 — 회사 페이지의 /vs/ 링크와 실제
    # 생성되는 조합 페이지가 같은 목록에서 나와야 죽은 링크가 생기지 않는다(GC-20).
    combo_pairs = combo.load_pairs(ctx)
    pages = []
    pages += company.render_all(env, ctx, combo_pairs=combo_pairs)  # 회사 ~95 (SP-GEN-5·6)
    pages += combo.render_all(env, ctx, CFG, pairs=combo_pairs)  # 조합 N (SP-GEN-7)
    pages += policy.render_all(env, ctx)  # 정책 4 + 404 (SP-POL 문안)
    if only:  # 개발용 경로 접두 필터
        pages = [p for p in pages if any(p.path.startswith(o) for o in only)]
    resolved_lastmod = lastmod or _today_iso()
    site_urls = [p.url for p in pages if p.in_sitemap] + [
        CFG.site_origin + path for path in CFG.extra_sitemap_paths
    ]
    pages.append(sitemap_page.render_sitemap(env, site_urls, resolved_lastmod, CFG))
    pages.append(sitemap_page.render_robots(CFG))
    manifest = stage_and_swap(out_dir, pages, incremental=incremental, gzip=gzip)
    write_manifest(out_dir, manifest)
    return 0


def _reject_only_prod_swap(out: str, only, force: bool) -> str | None:
    """--only + 프로덕션 out 결합 사고 방지(발견 #9).

    --only 는 경로 접두로 페이지를 걸러 부분 렌더하는 dev 필터인데, 원자 스왑은
    out_dir 를 부분집합으로 통째 교체한다(release.py `_reset_dir`→`_atomic_swap`).
    따라서 --only 를 서빙 dist(CFG.out_dir, 기본 web/dist)로 스왑하면 라이브 사이트의
    나머지 ~100페이지·sitemap·404 가 한 번에 소실된다. 검증 게이트(GC-2)는 회사
    1페이지만 있어도 통과해 이를 못 잡는다. 그래서 --only 가 프로덕션 out 을 겨냥하면
    거부하고, 굳이 필요하면 --force-prod-out 로 의도를 명시하게 한다.

    거부 시 에러 문자열을, 통과 시 None 을 반환한다(테스트 가능·DB 무접촉).
    """
    if not only or force:
        return None
    if os.path.normpath(out) != os.path.normpath(CFG.out_dir):
        return None
    return (
        f"거부: --only 는 부분 렌더인데 --out 이 서빙 프로덕션 dist({out})다. "
        f"부분집합 스왑으로 라이브 나머지 페이지가 전량 소실된다.\n"
        f"  안전 대안: 별도 out 으로 확인 → `--only {' '.join(only)} --out web/dist-dev`\n"
        f"  의도적 부분 배포가 정말 필요하면 `--force-prod-out` 를 명시하라(위험)."
    )


def main(argv=None) -> int:
    ap = argparse.ArgumentParser("loupit static generator")
    ap.add_argument("--out", default=CFG.out_dir)
    ap.add_argument("--bundle-json", help="DB 없이 렌더(사전 덤프 JSON)")
    ap.add_argument("--incremental", action="store_true", help="변경분만 기록(SP-GEN-10)")
    ap.add_argument("--only", nargs="*", help="경로 접두 필터(dev)")
    ap.add_argument(
        "--force-prod-out",
        action="store_true",
        help="--only 를 프로덕션 out(web/dist)으로 스왑하는 것을 명시 허용(위험, 발견 #9)",
    )
    ap.add_argument("--lastmod", help="기본 = 오늘(로컬 date)")
    ap.add_argument("--no-gzip", dest="gzip", action="store_false")
    ap.set_defaults(gzip=True)
    a = ap.parse_args(argv)
    reject = _reject_only_prod_swap(a.out, a.only, a.force_prod_out)
    if reject:
        print(f"generator build refused: {reject}", file=sys.stderr)
        return 2
    bundle = load_bundle_json(a.bundle_json) if a.bundle_json else load_bundle()
    lastmod = a.lastmod or _today_iso()
    try:
        return run(
            a.out,
            bundle,
            incremental=a.incremental,
            only=a.only,
            lastmod=lastmod,
            gzip=a.gzip,
        )
    except Exception as exc:  # noqa: BLE001 — CLI 표면: 실패 시 비0 종료, 이전 산출물 유지(SP-ARCH-9)
        print(f"generator build failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
