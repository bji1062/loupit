"""구글 태그 관리자(애널리틱스) 설치 계약 (2026-10-14, SP-ADS-12).

고정하는 것: (1) 생성 정적 페이지 전부 head 에 스니펫 1회 + `<body>` 바로 뒤 noscript 1회, ID = 설정 값
(2) 공개 수기 셸(compare·community)도 같고 ID 가 설정 값과 같다 (3) 회원·인증·관리 셸은 GTM 글자 0
(4) 처리방침이 분석 도구를 고지한다 — 코드가 문안보다 먼저 가면 그 순간부터 허위 기재다.
"""
from __future__ import annotations

import re

from generator.config import CFG, GenConfig
from generator.content.policy import build_policy_docs
from generator.tests.test_gnb_tabs import SHELLS, _all_pages

PUBLIC_SHELLS = ("compare/index.html", "community/index.html")
MEMBER_SHELLS = ("login.html", "mypage.html", "verify.html", "edit.html", "edits.html")
GTM_ID_RE = re.compile(r"GTM-[A-Z0-9]+")


def _check_one(html: str, name: str):
    cid = CFG.gtm_container_id
    assert html.count("googletagmanager.com/gtm.js") == 1, f"{name}: head 스니펫이 정확히 1개여야 한다"
    assert html.count("googletagmanager.com/ns.html") == 1, f"{name}: noscript 가 정확히 1개여야 한다"
    assert set(GTM_ID_RE.findall(html)) == {cid}, f"{name}: 컨테이너 ID 가 설정 값({cid})과 다르다"
    head = html[: html.index("</head>")]
    assert head.index("<meta charset") < head.index("Google Tag Manager"), f"{name}: charset 앞에 스니펫"
    assert head.index("Google Tag Manager") < head.index("<title"), f"{name}: 스니펫은 head 최대한 위"
    m = re.search(r"<body[^>]*>\s*", html)
    assert html[m.end():].startswith("<!-- Google Tag Manager (noscript) -->"), f"{name}: noscript 는 body 바로 뒤"


def test_container_id_default():
    assert CFG.gtm_container_id == "GTM-M7WP4QZ2"


def test_every_generated_page_has_gtm(fake_bundle, fake_now):
    pages = _all_pages(fake_bundle, fake_now)
    assert len(pages) > 20
    for p in pages:
        _check_one(p.html, p.path)


def test_404_has_gtm(fake_bundle, fake_now):
    from generator.pages import policy
    from generator.context import build_context
    from generator.render import make_env
    pages = policy.render_all(make_env(), build_context(fake_bundle, now=fake_now))
    p404 = [p for p in pages if "404" in p.path]
    assert p404, "404 페이지가 렌더 목록에 없다"
    for p in p404:
        _check_one(p.html, p.path)


def test_public_handwritten_shells_have_gtm():
    for n in PUBLIC_SHELLS:
        _check_one(SHELLS[n].read_text(encoding="utf-8"), n)


def test_member_and_admin_shells_have_no_gtm():
    for n in MEMBER_SHELLS:
        html = SHELLS[n].read_text(encoding="utf-8")
        assert "googletagmanager" not in html and "GTM-" not in html, f"{n}: 회원·인증 화면에 분석 태그"
    assert set(PUBLIC_SHELLS) | set(MEMBER_SHELLS) == set(SHELLS), "새 수기 셸 — 설치 여부를 정해 목록에 넣을 것"


def test_policy_discloses_analytics():
    privacy = build_policy_docs(GenConfig())[0]
    p11 = next(s for s in privacy.sections if s.req_id == "P11")
    text = " ".join(p11.paragraphs)
    assert "Google 애널리틱스" in text and "14개월" in text and "Google LLC" in text
    assert "https://tools.google.com/dlpage/gaoptout" in [u for _, u in p11.external_links]
    assert "회원·인증·관리 화면" in text
