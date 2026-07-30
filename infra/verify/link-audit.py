#!/usr/bin/env python3
"""infra/verify/link-audit.py — 사이트 내부 링크 전수 감사(수동 실행)

사용: python3 infra/verify/link-audit.py   # 종료코드 1 = 깨진 링크 있음

원래 목적 — "링크가 가리키는 주소가 실제로 존재하는가".

2026-07-30 편집 이력의 '회사 정보 보기' 가 **한 번도 동작한 적 없는 404 링크**였던 것과
같은 부류를 전부 찾는다. 문자열 모양이 아니라 **실제 응답**으로 판정한다.

⚠ 하네스를 먼저 검증한다(대조군). 봇 방어 403·리밋 429·DNS 문제로 전부 빨개지면 그건
   링크 결함이 아니라 측정 실패다 — 그 둘을 구분하지 못하면 결과가 무의미하다.
"""
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path
from urllib.parse import urljoin, urlsplit

ROOT = Path("/home/ubuntu/loupit")
BASE = "https://jobcho.wiki"
UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) "
      "Chrome/126.0.0.0 Safari/537.36")

SKIP_SCHEMES = ("http://", "https://", "mailto:", "tel:", "javascript:", "data:")

# href/src/action 에서 URL 을 뽑는다. 따옴표 안만 본다(속성값이 아닌 문자열을 줍지 않게).
ATTR_RE = re.compile(r'(?:href|src|action)\s*=\s*"([^"]+)"', re.I)


def internal_links(html: str, page_url_path: str) -> set[str]:
    out: set[str] = set()
    for raw in ATTR_RE.findall(html):
        u = raw.strip()
        if not u or u.startswith("#"):
            continue
        if u.lower().startswith(SKIP_SCHEMES):
            # 같은 호스트를 절대 URL 로 쓴 경우는 내부로 취급한다(canonical·og:url 등).
            if u.startswith(BASE):
                out.add(urlsplit(u).path or "/")
            continue
        if u.startswith("//"):
            continue
        out.add(urlsplit(urljoin(page_url_path, u)).path or "/")
    return out


def dist_url_path(p: Path) -> str:
    """web/dist 파일 → nginx 가 서빙하는 URL 경로(클린 URL 규칙 반영)."""
    rel = p.relative_to(ROOT / "web" / "dist").as_posix()
    if rel == "index.html":
        return "/"
    if rel.endswith("/index.html"):
        return "/" + rel[: -len("index.html")]
    return "/" + rel[: -len(".html")]        # company/cj.html → /company/cj


def probe(path: str) -> int:
    r = subprocess.run(
        ["curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", "-A", UA,
         "--max-time", "15", BASE + path],
        capture_output=True, text=True,
    )
    try:
        return int(r.stdout.strip())
    except ValueError:
        return -1


def main() -> int:
    # ── 0. 하네스 대조군 ────────────────────────────────────────────────────
    good, bad = probe("/"), probe("/__no_such_page_zzz__")
    print(f"대조군: /  → {good}   /__no_such_page_zzz__ → {bad}")
    if good != 200 or bad == 200:
        print("❌ 하네스 실패 — 측정을 신뢰할 수 없다(봇 방어·리밋·DNS 의심). 중단.")
        return 2
    print("✅ 하네스 검증 통과 — 200 과 404 를 구분한다\n")

    # ── 1. 링크 수집 ────────────────────────────────────────────────────────
    sources: dict[str, set[str]] = {}   # 링크 → 그 링크를 담은 페이지들
    dist_files = sorted((ROOT / "web" / "dist").rglob("*.html"))
    hand_files = sorted((ROOT / "web").glob("*.html"))

    for p in dist_files:
        page = dist_url_path(p)
        for link in internal_links(p.read_text(errors="replace"), page):
            sources.setdefault(link, set()).add(f"dist:{page}")
    for p in hand_files:
        page = "/" + p.name
        for link in internal_links(p.read_text(errors="replace"), page):
            sources.setdefault(link, set()).add(f"web/{p.name}")

    # JS 가 런타임에 만드는 **페이지** 이동 대상(정적 추출로는 안 잡힌다).
    # grep 으로 확인한 전체 목록 — API 경로는 페이지가 아니라 제외한다.
    js_targets = {
        "/": "company.js(대문으로)",
        "/login": "authnav.js·edit.js·mypage.js·verify.js",
        "/mypage": "authnav.js",
        "/edit": "mypage.js(?comp=)",
        "/edits": "edit.js·edits.js(?comp=)",
        "/company/cj": "directory.js·edits.js(슬러그 표본)",
        "/assets/v2/data/affiliate.json": "ads.js(fetch)",
    }
    for link, why in js_targets.items():
        sources.setdefault(link, set()).add(f"JS:{why}")

    print(f"수집: 정적 {len(dist_files)}+{len(hand_files)} 파일에서 고유 링크 {len(sources)}개\n")

    # ── 2. 전수 조회 ────────────────────────────────────────────────────────
    broken: list[tuple[str, int, set[str]]] = []
    codes: dict[int, int] = {}
    for i, link in enumerate(sorted(sources), 1):
        code = probe(link)
        codes[code] = codes.get(code, 0) + 1
        if code >= 400 or code < 0:
            broken.append((link, code, sources[link]))
        if i % 40 == 0:
            print(f"  … {i}/{len(sources)}")

    print("\n=== 응답 분포 ===")
    for c in sorted(codes):
        print(f"  {c}: {codes[c]}건")

    print(f"\n=== 깨진 링크 {len(broken)}건 ===")
    for link, code, src in sorted(broken, key=lambda x: -len(x[2])):
        origins = sorted(src)
        head = ", ".join(origins[:3]) + (f" 외 {len(origins) - 3}곳" if len(origins) > 3 else "")
        print(f"  [{code}] {link}\n        ← {head}")
    return 1 if broken else 0


if __name__ == "__main__":
    sys.exit(main())
