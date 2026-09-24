"""광고 고지의 제휴 문안 스위치 (SP-POL-6 · SP-ADS-6, 2026-09-24).

**왜 있는가**: 애드센스 2차 거절(2026-09-24, 스팸 정책 「빈약한 제휴 페이지」 등) 시점에
`web/assets/data/affiliate.json` 은 `{"version": 1, "items": []}` — 제휴 링크 0개였다. 그런데 모든
페이지 푸터가 「광고·제휴 고지」로 링크했고 `/ads` 는 "Google AdSense 광고와 제휴 링크로 운영되며
… 제휴사로부터 수수료를 받을 수 있습니다"를 선언했다. 없는 수익 관계의 자기 선언이다.

반대 방향도 사고다 — 제휴를 켰는데 A-3(수수료 관계)이 없으면 수수료를 숨긴 표시·광고가 된다.
그래서 M9 문안 스위치(test_policy_m9)와 같이 **양방향**으로 고정한다:
  OFF(active 0개): 제목·meta·본문·푸터 어디에도 「제휴」가 없고 A-3 이 없다.
  ON (active ≥1) : A-3 이 있고 A-1·A-2·A-5·meta 가 제휴를 말한다(구 문안 그대로).
  실파일          : 기본 `CFG` 가 실제 affiliate.json 을 읽고, 렌더된 /ads 의 A-3 유무가 그 파일과 같다.
"""
from __future__ import annotations

import json
import re

import pytest

from generator.config import AFFILIATE_JSON, CFG, GenConfig, affiliate_active_in
from generator.content.policy import (
    POLICY_FOOTER_LINKS,
    build_policy_docs,
    required_items,
)
from generator.context import build_context
from generator.pages import policy as policy_module
from generator.render import make_env

OFF = GenConfig(affiliate_active=False)
ON = GenConfig(affiliate_active=True)

_SCRIPT_RE = re.compile(r"<script\b[^>]*>.*?</script>", re.S | re.I)
_TAG_RE = re.compile(r"<[^>]+>")


def _ads(cfg):
    return next(d for d in build_policy_docs(cfg) if d.key == "ads")


def _doc_text(doc) -> str:
    parts = [doc.title, doc.meta_description]
    for s in doc.sections:
        parts += [s.heading, s.toc_label, *s.paragraphs]
    parts += [label for label, _ in doc.related]
    return "\n".join(parts)


def _rendered(cfg) -> dict[str, str]:
    """정책 4종을 주어진 cfg 로 렌더한 HTML(render_all 은 모듈 CFG 를 쓰므로 한 단계 아래를 부른다)."""
    tpl = make_env().get_template("policy.html")
    return {d.filename: policy_module._render_policy_doc(tpl, d, cfg).html for d in build_policy_docs(cfg)}


def _visible(html: str) -> str:
    """스크립트를 걷어낸 태그 밖 글자(title 포함). meta 속성값은 아래에서 HTML 원문으로 따로 본다."""
    return _TAG_RE.sub(" ", _SCRIPT_RE.sub("", html))


# ── OFF: 제휴가 없으면 제휴를 말하지 않는다 ──────────────────────────────────────


def test_AF_off_ads_doc_has_no_affiliate_claim():
    doc = _ads(OFF)
    assert doc.title == "광고 고지"
    assert "A-3" not in {s.req_id for s in doc.sections}
    assert "제휴" not in _doc_text(doc), "제휴 링크 0개인데 광고 고지가 제휴를 말한다"
    assert "affiliate" not in _doc_text(doc)


def test_AF_off_keeps_remaining_anchors_stable():
    """A-3 만 빠지고 A-4·A-5 앵커는 그대로다 — 밖에서 건 `/ads#a4` 가 깨지지 않게."""
    doc = _ads(OFF)
    assert [(s.req_id, s.anchor) for s in doc.sections] == [
        ("A-1", "a1"), ("A-2", "a2"), ("A-4", "a4"), ("A-5", "a5"),
    ]


def test_AF_off_rendered_policy_pages_show_no_affiliate_text():
    """렌더된 정책 4종(푸터·관련 문서·meta 포함) 어디에도 「제휴」가 보이지 않는다."""
    for fname, html in _rendered(OFF).items():
        assert "제휴" not in _visible(html), f"{fname}: 화면에 「제휴」가 남아 있다"
        assert "제휴" not in html, f"{fname}: HTML 원문(meta description·og 포함)에 「제휴」가 남아 있다"
    ads = _rendered(OFF)["ads.html"]
    assert 'id="a3"' not in ads and 'href="#a3"' not in ads


def test_AF_footer_and_related_labels_say_광고_고지():
    """라벨은 제휴 유무와 무관하게 「광고 고지」 하나다(수기 셸 하드코딩이 빌드 분기를 못 따라간다)."""
    assert ("광고 고지", "/ads") in POLICY_FOOTER_LINKS
    assert all("제휴" not in label for label, _ in POLICY_FOOTER_LINKS)
    for cfg in (OFF, ON):
        privacy = next(d for d in build_policy_docs(cfg) if d.key == "privacy")
        assert ("광고 고지", "/ads") in privacy.related
        assert _ads(cfg).title == "광고 고지"


# ── ON: 제휴를 켜면 수수료 관계를 반드시 고지한다 ────────────────────────────────


def test_AF_on_discloses_commission_relationship():
    doc = _ads(ON)
    a3 = next(s for s in doc.sections if s.req_id == "A-3")
    assert a3.anchor == "a3"
    assert "수수료" in "\n".join(a3.paragraphs)
    a1 = next(s for s in doc.sections if s.req_id == "A-1")
    assert "제휴" in a1.paragraphs[0]
    assert "제휴" in doc.meta_description
    assert [s.req_id for s in doc.sections] == ["A-1", "A-2", "A-3", "A-4", "A-5"]
    assert 'id="a3"' in _rendered(ON)["ads.html"]


@pytest.mark.parametrize("cfg,expected", [
    (OFF, {"A-1", "A-2", "A-4", "A-5"}),
    (ON, {"A-1", "A-2", "A-3", "A-4", "A-5"}),
])
def test_AF_required_items_track_affiliate_switch(cfg, expected):
    """PC-2 필수 항목이 스위치를 따라간다 — 정확일치라 "조용히 빠짐/더해짐"을 둘 다 잡는다."""
    assert required_items(cfg)["ads"] == expected
    assert {s.req_id for s in _ads(cfg).sections} >= required_items(cfg)["ads"]


def test_AF_switch_is_independent_of_m9():
    """두 스위치는 서로 다른 사실을 고지한다 — 하나가 다른 하나의 항목을 건드리지 않는다."""
    both = GenConfig(affiliate_active=True, m9_enabled=True)
    assert required_items(both)["ads"] == required_items(ON)["ads"]
    assert required_items(both)["privacy"] == required_items(GenConfig(m9_enabled=True))["privacy"]


# ── 실파일: 기본 CFG 는 실제 affiliate.json 을 따른다 ────────────────────────────


def _independent_active_count() -> int:
    """ads.js `filterAffiliate` 의 첫 관문(`it.active !== true` 제외)만 따로 센다 — 구현을 재사용하지 않는다."""
    data = json.loads(AFFILIATE_JSON.read_text(encoding="utf-8"))
    return sum(1 for it in data.get("items", []) if isinstance(it, dict) and it.get("active") is True)


def test_AF_default_cfg_reads_the_live_affiliate_json():
    """기본 `CFG`(= release 의 정적 재생성)가 실제 파일을 본다. 파일에 active 항목을 넣으면
    다음 재생성에서 A-3 이 켜진다 — 스위치를 사람이 따로 켜는 경로가 없어 잊을 수가 없다."""
    assert AFFILIATE_JSON.is_file(), f"제휴 데이터 정본이 없다: {AFFILIATE_JSON}"
    active = _independent_active_count() > 0
    assert CFG.affiliate_active is active
    assert GenConfig().affiliate_active is active


def test_AF_rendered_ads_page_matches_the_live_affiliate_json(fake_bundle, fake_now):
    """**게이트**: 실제 빌드 경로(`render_all`, 모듈 CFG)로 그린 /ads 의 A-3 유무 == 실파일의 active 유무.
    release.sh [1/7] 테스트 게이트가 이 파일을 [4/7] 재생성 직전에 돌린다."""
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now)
    ads = next(p for p in policy_module.render_all(env, ctx) if p.path == "ads.html").html
    active = _independent_active_count() > 0
    assert ('id="a3"' in ads) is active, "affiliate.json 과 광고 고지 A-3 이 어긋났다"
    if not active:
        assert "제휴" not in ads, "제휴가 0개인데 /ads 에 「제휴」가 남아 있다"


@pytest.mark.parametrize("payload,expected", [
    ({"version": 1, "items": []}, False),
    ({"version": 1, "items": [{"id": "a", "active": False}]}, False),
    ({"version": 1, "items": [{"id": "a", "active": "true"}]}, False),  # JS 는 `!== true` — 문자열은 꺼짐
    ({"version": 1, "items": [{"id": "a", "active": 1}]}, False),
    ({"version": 1, "items": [{"id": "a", "active": False}, {"id": "b", "active": True}]}, True),
    ({"version": 1}, False),
    ([], False),
])
def test_AF_affiliate_active_in_parses_like_ads_js(tmp_path, payload, expected):
    f = tmp_path / "affiliate.json"
    f.write_text(json.dumps(payload), encoding="utf-8")
    assert affiliate_active_in(f) is expected


def test_AF_missing_or_broken_file_means_no_affiliate(tmp_path):
    """ads.js 는 로드 실패·손상 JSON 을 빈 목록으로 폴백한다(AF-7) — 카드가 0개면 고지할 제휴도 없다."""
    assert affiliate_active_in(tmp_path / "nope.json") is False
    broken = tmp_path / "broken.json"
    broken.write_text("{not json", encoding="utf-8")
    assert affiliate_active_in(broken) is False
