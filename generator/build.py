"""generator/build.py — 엔트리 CLI: 번들→렌더→검증→web/dist (SP-GEN-1.4).

SP-INFRA `release.sh`가 호출: `python -m generator.build --out web/dist`.
종료 코드 0=성공(검증 통과·스왑 완료), 비0=렌더/검증/스왑 실패(이전 산출물
유지, SP-ARCH-9).
"""
from __future__ import annotations

import argparse
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
    pages = []
    pages += company.render_all(env, ctx)  # 회사 ~95 (SP-GEN-5·6)
    pages += combo.render_all(env, ctx, CFG)  # 조합 N (SP-GEN-7)
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


def main(argv=None) -> int:
    ap = argparse.ArgumentParser("loupit static generator")
    ap.add_argument("--out", default=CFG.out_dir)
    ap.add_argument("--bundle-json", help="DB 없이 렌더(사전 덤프 JSON)")
    ap.add_argument("--incremental", action="store_true", help="변경분만 기록(SP-GEN-10)")
    ap.add_argument("--only", nargs="*", help="경로 접두 필터(dev)")
    ap.add_argument("--lastmod", help="기본 = 오늘(로컬 date)")
    ap.add_argument("--no-gzip", dest="gzip", action="store_false")
    ap.set_defaults(gzip=True)
    a = ap.parse_args(argv)
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
