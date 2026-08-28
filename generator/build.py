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

from generator.bundle import (
    load_bundle_json,
    load_bundle_with_metrics,
    load_employ_json,
    load_finance_json,
)
from generator.employ import coverage as employ_coverage
from generator.employ import is_loaded as employ_is_loaded
from generator.config import CFG
from generator.context import build_context
from generator.pages import combo, company, company_index, heatmap, policy
from generator.pages import sitemap as sitemap_page
from generator.release import stage_and_swap, write_manifest
from generator.render import make_env


def _today_iso() -> str:
    return date.today().isoformat()


def run(
    out_dir: str,
    bundle: dict,
    *,
    finance: dict | None = None,
    employ: dict | None = None,
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
    ctx = build_context(bundle, finance=finance, employ=employ)  # 인덱스·slug 충돌 검증(BuildError, SP-GEN-3)
    # 조합 쌍은 한 번만 로드해 양쪽에 전달한다 — 회사 페이지의 /vs/ 링크와 실제
    # 생성되는 조합 페이지가 같은 목록에서 나와야 죽은 링크가 생기지 않는다(GC-20).
    combo_pairs = combo.load_pairs(ctx)
    pages = []
    pages += company.render_all(env, ctx, combo_pairs=combo_pairs)  # 회사 ~95 (SP-GEN-5·6)
    pages.append(company_index.render(env, ctx, CFG))  # 회사 인덱스 진입문 (SP-GEN-5.3)
    pages.append(heatmap.render(env, ctx, CFG))  # 복지·실적 히트맵 (SP-HEAT, 2026-08-27)
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
    pages.append(sitemap_page.render_ads_txt(CFG))  # /ads.txt (AdSense, 2026-07-21)
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
    ap.add_argument("--finance-json", help="재무 사전 덤프 JSON(--bundle-json 의 짝, SP-FIN-4). 없으면 실적 섹션 미렌더")
    ap.add_argument("--employ-json", help="직원 현황 사전 덤프 JSON(--bundle-json 의 짝, SP-MET-8). 없으면 직원 카드 미렌더")
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
    for flag, val in (("--finance-json", a.finance_json), ("--employ-json", a.employ_json)):
        if val and not a.bundle_json:
            print(f"generator build refused: {flag} 은 --bundle-json 과 짝이다(DB 경로는 셋을 함께 읽는다)", file=sys.stderr)
            return 2
    if a.bundle_json:
        bundle = load_bundle_json(a.bundle_json)
        finance = load_finance_json(a.finance_json) if a.finance_json else None
        employ = load_employ_json(a.employ_json) if a.employ_json else None
    else:
        bundle, finance, employ = load_bundle_with_metrics()
    # 미적재를 조용히 넘기지 않는다 — 섹션이 통째로 빠지는 것은 에러를 남기지 않는 소멸이다(함정 (57)).
    if not (finance and any(v.get("years") for v in finance.values())):
        print("generator build: finance 미주입(--finance-json 없음 또는 TCORP_FINANCE 0건) — 실적 섹션 없이 렌더한다", file=sys.stderr)
    if not employ_is_loaded(employ):
        print("generator build: employ 미주입(--employ-json 없음 또는 TCORP_EMPLOY 0건) — 직원 카드 없이 렌더한다", file=sys.stderr)
    else:
        # 결측은 **세어서** 찍는다(SP-MET-8 `coverage`). 0 으로 채우면 화면에 거짓이 나가고,
        # 세지 않고 비우면 언제부터 비었는지 아무도 모른다 — 이 프로젝트가 반복해서 밟은 함정이다.
        cov = employ_coverage(employ)
        print(
            f"generator build: employ 회사 {cov['companies']} · 회사×연도 {cov['years']} · "
            f"결측 연봉 {cov['salary']} · 근속 {cov['tenure']} · 인원 {cov['head']}",
            file=sys.stderr,
        )
    lastmod = a.lastmod or _today_iso()
    try:
        return run(
            a.out,
            bundle,
            finance=finance,
            employ=employ,
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
