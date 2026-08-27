"""재무 표현·경계 가드 — FN-6 (SP-FIN, DEC-B, T-15.2.4).

두 가지를 코드로 못박는다.

  1. **표현 규약(DEC-B)**: 생성물 전 페이지에 등급·전망·평가 어휘(성장성·등급·전망·우수·양호)가
     없다. "성장성 우수" 류는 투자자문 오인 위험이고, 2026-07-20 에 폐기한 가짜 지표와 같은
     범주로 읽힌다. 유일한 예외는 고지문 자체("…평가나 전망이 아닙니다")이며, 그 문장을 **정확히
     그 형태로만** 걷어낸 뒤 검사한다 — 예외가 다른 문장을 숨기지 못하게.
  2. **번들 단일 소스 무변경(함정 (55))**: 재무는 생성기 전용 로더로 싣는다. `build_reference_bundle`
     ·`ReferenceBundle`(런타임 API `reference/all`)은 TCORP 를 모른다. 여기에 손대면 600KB 번들·
     Pydantic 화이트리스트·클라이언트 정규화까지 같이 움직여야 한다.
"""
from __future__ import annotations

import inspect
import re
from pathlib import Path

from generator import bundle as bundle_module
from generator.config import CFG
from generator.context import build_context
from generator.pages import combo, company, company_index, policy
from generator.render import make_env
from generator.tests.fixtures import make_sibling_fixture

REPO = Path(__file__).resolve().parents[2]
FORBIDDEN = ("성장성", "등급", "전망", "우수", "양호")
NOTICE = "공시 수치이며 평가나 전망이 아닙니다"
_TAG_RE = re.compile(r"<[^>]+>")


def _all_pages(bundle, finance, now):
    env = make_env()
    ctx = build_context(bundle, now=now, finance=finance)
    pairs = combo.load_pairs(ctx)
    return (
        company.render_all(env, ctx, combo_pairs=pairs)
        + [company_index.render(env, ctx, CFG)]
        + combo.render_all(env, ctx, CFG, pairs=pairs)
        + policy.render_all(env, ctx)
    )


def test_FN6_no_rating_or_outlook_vocabulary_anywhere(fake_now, fake_combinations_path):
    bundle, finance = make_sibling_fixture()  # 일반·금융·없음·형제 전부 포함된 가장 넓은 표본
    pages = _all_pages(bundle, finance, fake_now)
    assert any("<table" in p.html and 'class="finance"' in p.html for p in pages), "재무 표가 렌더되지 않았다 — 가드가 공회전한다"
    offenders = []
    for p in pages:
        text = _TAG_RE.sub(" ", p.html).replace(NOTICE, " ")
        for word in FORBIDDEN:
            if word in text:
                offenders.append((p.path, word))
    assert not offenders, f"금지 어휘(DEC-B): {offenders}"


def test_FN6_notice_exception_is_exact_sentence_only(fake_bundle, fake_finance, fake_now):
    """예외 문장은 고지문 하나뿐이고, 그 문장이 실제로 페이지에 있다(예외가 공회전하지 않는다)."""
    env = make_env()
    ctx = build_context(fake_bundle, now=fake_now, finance=fake_finance)
    html = {p.path: p.html for p in company.render_all(env, ctx)}["company/samsung-elec.html"]
    assert NOTICE in html
    assert html.count("전망") == 1, "고지문 밖에 '전망' 이 또 있다"


def test_FN6_reference_bundle_single_source_untouched():
    """`services/reference.py`·`models/reference.py` 는 TCORP·재무를 모른다."""
    for rel in ("server/services/reference.py", "server/models/reference.py"):
        text = (REPO / rel).read_text(encoding="utf-8")
        assert "TCORP" not in text and "finance" not in text.lower(), f"{rel} 에 재무가 스며들었다"
    src = inspect.getsource(bundle_module)
    assert "from server.services.reference import build_reference_bundle" in src, "번들 단일 소스 import 가 사라졌다"


def test_FN6_bundle_dict_stays_three_keys_and_finance_travels_beside_it(fake_bundle):
    """재무는 `bundle["finance"]` 처럼 번들 안으로 들어가지 않는다 — `build_context(bundle, finance=…)` 인자다."""
    assert set(fake_bundle) == {"company_types", "benefit_presets", "companies"}
    ctx = build_context(fake_bundle)
    assert ctx.finance == {} and ctx.finance_loaded is False
    assert "finance" in inspect.signature(build_context).parameters
    assert hasattr(bundle_module, "load_bundle") and hasattr(bundle_module, "load_bundle_with_finance")
    assert hasattr(bundle_module, "load_finance_json")
