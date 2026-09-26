"""generator/tests/test_benefit_pages.py — 복지 항목 페이지 `/benefit/{slug}` (SP-BEN).

잡으려는 회귀:
  ① **수집자 메모가 규칙에 걸리는 것**(`core_text`). 원문 칸의 「(공식 … — 대출·이자 … 미기재)」가
     이자 지원으로 잡혔다(가온전선 실측). 회사가 쓴 괄호는 남아야 한다.
  ② **예외가 옛 원문에 조용히 붙는 것.** 해시가 다르면 꺼지고 `stale` 로 드러나야 한다.
  ③ **법정 행이 집계에 섞이는 것**(SP-LEGAL-5). 표에는 남고 N·방식·원문·질문·금액 출처에서는 빠진다.
  ④ **설정 JSON 이 조용히 틀리는 것.** `answered_by` 가 없는 facet 을 가리키면 질문 칸이 거짓
     「없음」을 찍는다. data 디렉터리의 **모든** 설정을 여기서 검사한다(다른 사람이 쓴 설정 포함).
  ⑤ **템플릿이 필러 문장을 내보내는 것.** 완결문장은 사람 글·회사 원문에서만 나와야 한다
     (애드센스 거절 사유 = 「가치가 별로 없는 콘텐츠」, 공식 정의 = 필러).
  ⑥ **항목 페이지가 고아가 되는 것**(GC-30). sitemap 과 `/find` 두 입구가 다 있어야 한다.
"""
from __future__ import annotations

import copy
import glob
import html as html_mod
import io
import json
import os
import re

import pytest

from generator import benefit_rules as br
from generator.checks import _check_benefit_human_text, _check_benefit_reachable, run_generated_checks
from generator.config import CFG
from generator.context import build_context
from generator.pages import benefit, company, find
from generator.pages import sitemap as sitemap_page
from generator.render import make_env
from generator.slug import BuildError
from generator.tests.fixtures import FAKE_BUNDLE

DATA_DIR = os.path.join(os.path.dirname(br.__file__), "data", "benefit_pages")
CFG_FILES = sorted(glob.glob(os.path.join(DATA_DIR, "*.json")))


# ── 픽스처: 회사 N곳에 한 행씩 ────────────────────────────────────────────────


def _b(code, nm, desc=None, note=None, amt=None, qual=True, src="none", ctgr="perks"):
    return {
        "benefit_cd": code, "benefit_nm": nm, "benefit_amt": amt, "benefit_ctgr_cd": ctgr,
        "badge_cd": "official", "amt_source": src, "qual_yn": qual,
        "qual_desc_ctnt": desc, "note_ctnt": note, "verified_dtm": "2026-06-01",
        "expires_dtm": "2099-12-31", "badge_src_cd": "scrape_official", "badge_src_url_ctnt": None,
        "sort_order_no": 0,
    }


def _bundle(rows: list[tuple[str, str, dict]]) -> dict:
    """`[(comp_eng_nm, comp_nm, benefit), …]` → 가짜 번들. 회사 이름 규칙은 실데이터와 같다."""
    b = copy.deepcopy(FAKE_BUNDLE)
    b["companies"] = [
        {"comp_id": 100 + i, "comp_eng_nm": eng, "comp_nm": nm, "comp_tp_cd": "large",
         "industry_nm": "테스트", "logo_nm": nm[:1], "work_style_val": {}, "aliases": [], "benefits": [row]}
        for i, (eng, nm, row) in enumerate(rows)
    ]
    return b


# 주택자금 대출 실원문 표본(2026-09-18 DB). 해시가 housing_loan.json 의 예외와 맞는 두 행을 포함한다.
HOUSING = [
    ("doosan_enerbility", "두산에너빌리티", _b("housing_loan", "주거지원",
        desc="기숙사/사택, 이사비/대출이자 지원, 신용협동조합(주택구입/전세/생활안정 무이자/저금리)")),
    ("pearl_abyss", "펄어비스", _b("housing_loan", "거주비/대출 이자 지원",
        note="회사 인근 거주 시 매월 50만원 거주비, 그 외 지역 대출 이자 실비 지원", amt=600, qual=False, src="stated")),
    ("kt", "KT", _b("housing_loan", "주택자금 대출", desc="저금리 주택자금 대출 지원")),
    ("gaon_cable", "가온전선", _b("housing_loan", "주택자금 지원",
        desc="주택구입자금 및 전세자금 지원 (공식 채용 페이지 복리후생 주거 지원 항목 — 대출·이자 지원 등 지원 방식, 한도, 자격 요건 미기재)")),
    ("cj_cgv", "CJ CGV", _b("housing_loan", "주택자금 대출", desc="무이자 2천만원 주택자금 대출 — 한도는 계열사별로 다름")),
    ("naver", "NAVER", _b("housing_loan", "주택자금 대출이자 지원", desc="대출금액 1.5%를 10년간 지원(최대 2억원)")),
    ("cj_freshway", "CJ프레시웨이", _b("housing_loan", "주택자금 대출", desc="2년 이상 재직자 대상 (한도 미표기)")),
    ("sk_telecom", "SK텔레콤", _b("housing_loan", "사내 대출", desc="사내 대출 1억 한도, 주거 안정 자금 지원")),
    ("sk_hynix", "SK하이닉스", _b("housing_loan", "주택자금 지원",
        desc="주택 임대·구매 시 필요 자금과 결혼 자금 저금리 융자, 자녀 3명 이상 구성원 최대 2억원 특별 주택 융자 (공식 채용 페이지 복지 제도 생활 항목·지속가능경영보고서 2026 — 일반 융자 한도·금리 미기재)",
        amt=500, qual=False, src="estimated")),  # 원문은 2026-09-26 재수집본, 금액만 표본용
]


def _housing_cfg():
    return br.load_pages()["housing_loan"]


def _render(rows, configs, min_companies=1, now=None):
    env = make_env()
    ctx = build_context(_bundle(rows), now=now)
    log = io.StringIO()
    pages = benefit.render_all(env, ctx, CFG, configs=configs, min_companies=min_companies, log=log)
    return pages, ctx, env, log.getvalue()


# ── ① core_text — 실제 원문 케이스 ──────────────────────────────────────────


@pytest.mark.parametrize("raw, core", [
    # 가온전선: 괄호 안이 수집자 메모 — 그 안의 「대출·이자」가 이자 지원으로 잡히던 행
    ("주택구입자금 및 전세자금 지원 (공식 채용 페이지 복리후생 주거 지원 항목 — 대출·이자 지원 등 지원 방식, 한도, 자격 요건 미기재)",
     "주택구입자금 및 전세자금 지원"),
    ("2년 이상 재직자 대상 (한도 미표기)", "2년 이상 재직자 대상"),  # CJ프레시웨이
    ("무이자 2천만원 주택자금 대출 — 한도는 계열사별로 다름", "무이자 2천만원 주택자금 대출"),  # CJ CGV 꼬리 메모
    ("주택자금 대출(유·무이자)", "주택자금 대출(유·무이자)"),  # 회사가 쓴 괄호는 남는다
    ("대출금액 1.5%를 10년간 지원(최대 2억원)", "대출금액 1.5%를 10년간 지원(최대 2억원)"),
    # 「미공개」도 메모 낱말이다 — 괄호와 꼬리 둘 다
    ("주택자금 대출 (한도 미공개)", "주택자금 대출"),
    ("저리 대출 — 금리 미공개", "저리 대출"),
    # 겹괄호: 안쪽부터 걷어 바깥 메모가 통째로 걷힌다
    ("주택자금 대출 (공식 페이지 (채용) 항목 — 한도 미기재)", "주택자금 대출"),
    # 메모 안에 회사 괄호가 끼어 있어도 바깥 메모는 걷힌다(안쪽 회사 괄호에 막히지 않는다)
    ("사내 대출 (공식 페이지 (유·무이자) 항목 — 한도 미기재)", "사내 대출"),
    # 메모 낱말이 없는 겹괄호는 회사가 쓴 것 — 그대로
    ("대출 지원(최대 2억원(연 1회))", "대출 지원(최대 2억원(연 1회))"),
    ("괄호가 (닫히지 않은 원문", "괄호가 (닫히지 않은 원문"),
])
def test_core_text_strips_collector_memo_and_keeps_company_parens(raw, core):
    assert br.core_text(raw) == core


def test_memo_no_longer_turns_gaon_into_interest_support():
    cfg = _housing_cfg()
    gaon = next(r for r in HOUSING if r[0] == "gaon_cable")[2]
    out = br.classify(cfg, [{"comp": "gaon_cable", "desc": gaon["qual_desc_ctnt"], "note": None}])
    assert out["rows"][0]["mode"] == "unknown", "메모의 「대출·이자」가 방식 규칙에 걸렸다"
    assert out["rows"][0]["facets"] == {"buy", "lease"}


# ── ② 예외(override) — 원문 해시에 묶인다 ────────────────────────────────────


def _ov_cfg():
    return {
        "code": "x", "slug": "x", "title": "x", "intro": ["가."], "questions": [],
        "modes": {"rules": [{"key": "a", "label": "A", "pattern": "가"}], "extra": [{"key": "both", "label": "둘 다"}],
                  "fallback": {"key": "none", "label": "없음"}},
        "facets": [{"key": "f", "label": "F", "pattern": "나"}],
        "overrides": [{"comp": "c1", "h": br.text_hash("가나", None), "mode": "both", "facets_remove": ["f"], "why": "테스트"}],
    }


def test_override_applies_only_when_hash_matches():
    out = br.classify(_ov_cfg(), [{"comp": "c1", "desc": "가나", "note": None}])
    assert out["rows"][0]["mode"] == "both" and out["rows"][0]["facets"] == set()
    assert out["stale"] == []


def test_override_on_changed_text_is_disabled_and_reported():
    out = br.classify(_ov_cfg(), [{"comp": "c1", "desc": "가나다", "note": None}])
    assert out["rows"][0]["mode"] == "a", "원문이 바뀌었는데 예외가 그대로 붙었다"
    assert out["rows"][0]["facets"] == {"f"}
    assert len(out["stale"]) == 1 and "원문이 바뀌어" in out["stale"][0]


def test_override_without_row_is_reported():
    out = br.classify(_ov_cfg(), [{"comp": "c2", "desc": "가", "note": None}])
    assert len(out["stale"]) == 1 and "행이 없어" in out["stale"][0]


def _ex_cfg(h):
    cfg = _ov_cfg()
    cfg["overrides"] = [{"comp": "c1", "h": h, "exclude": True, "why": "이 코드가 아닌 행"}]
    return cfg


def test_exclude_override_removes_the_row_from_rows_and_counts():
    out = br.classify(_ex_cfg(br.text_hash("가나", None)),
                      [{"comp": "c1", "desc": "가나", "note": None}, {"comp": "c2", "desc": "가", "note": None}])
    assert [r["comp"] for r in out["rows"]] == ["c2"]
    assert out["modes"]["a"] == 1 and out["facets"]["f"] == 0, "뺀 행이 개수에 남았다"
    assert [x["comp"] for x in out["excluded"]] == ["c1"] and out["stale"] == []


def test_exclude_on_changed_text_is_disabled_and_the_row_comes_back():
    out = br.classify(_ex_cfg(br.text_hash("가나", None)), [{"comp": "c1", "desc": "가나다", "note": None}])
    assert [r["comp"] for r in out["rows"]] == ["c1"], "원문이 바뀌었는데 행이 계속 빠져 있다"
    assert out["excluded"] == [] and len(out["stale"]) == 1


def test_real_housing_overrides_match_the_real_text():
    """housing_loan.json 의 예외가 표본 원문과 해시로 맞물린다(예외가 공회전하지 않는다).

    표본에 없는 회사의 예외는 「행이 없어」로 보고되는 게 정상이라 빼고 본다 — 여기서 잡을 것은
    **표본에 있는데 원문이 달라 꺼진 예외**다(실데이터 해시는 실제 빌드 로그의 stale 0 이 지킨다)."""
    cfg = _housing_cfg()
    rows = [{"comp": e, "desc": b["qual_desc_ctnt"], "note": b["note_ctnt"]} for e, _, b in HOUSING]
    out = br.classify(cfg, rows)
    by = {r["comp"]: r for r in out["rows"]}
    assert [s for s in out["stale"] if "원문이 바뀌어" in s] == []
    assert "no_home" not in by["sk_hynix"]["facets"], "재수집 원문에는 무주택 조건이 없다 — 예외 없이 규칙만으로 맞아야 한다"
    assert by["doosan_enerbility"]["mode"] == "both"
    assert "limit" not in by["pearl_abyss"]["facets"], "「매월 50만원」 거주비가 대출 한도로 잡혔다"


def test_stale_override_is_printed_to_build_log_not_raised():
    rows = [r for r in HOUSING if r[0] != "pearl_abyss"]  # 예외 대상 행이 사라진 빌드
    _, _, _, log = _render(rows, {"housing_loan": _housing_cfg()})
    assert "pearl_abyss" in log and "예외 경고" in log


# ── ③ 집계 — 방식 합 = N · 법정 행 제외 · 20곳 문턱 ─────────────────────────


def test_modes_sum_to_company_count():
    ctx = build_context(_bundle(HOUSING))
    view = benefit.build_view(ctx, _housing_cfg())
    assert view["count"] == len(HOUSING)
    assert sum(m["count"] for m in view["modes"]) == view["count"]
    # 표도 같은 N 줄이다(법정 행이 없는 항목)
    assert len(view["rows_first"]) + len(view["rows_rest"]) == view["count"]


def test_mode_colors_follow_display_order_not_rule_order():
    """housing_loan 은 규칙이 [이자, 직접] 순(매칭 우선순위)이고 화면은 [직접, 이자] 순이다 —
    막대 맨 앞 칸이 첫째 색(`--brand`)이어야 한다(시안: 직접 = 초록, 이자 = 파랑)."""
    ctx = build_context(_bundle(HOUSING))
    view = benefit.build_view(ctx, _housing_cfg())
    assert [(m["key"], m["cls"]) for m in view["modes"]] == [
        ("direct", "bn-m1"), ("interest", "bn-m2"), ("both", "bn-mx"), ("unknown", "bn-m0")]


# 법정 행 표본 — `legal_rows.json` 에 실제로 있는 (회사, 코드, 이름) 이다. 코드만 같은 다른 행은 복지다.
_PARENTING_CFG = {
    "code": "parenting", "slug": "parenting", "title": "육아 지원", "intro": ["육아 지원은 회사마다 다릅니다."],
    "facets": [{"key": "leave", "label": "휴직", "pattern": "휴직"}],
    "questions": [{"text": "휴직 중 급여가 있나요?", "answered_by": ["facet:leave"]}],
}
PARENTING = [
    ("classys", "클래시스", _b("parenting", "산전후휴가/육아휴직", desc="산전후 휴가, 남성출산휴가, 육아휴직", ctgr="family")),
    ("a_co", "가회사", _b("parenting", "육아휴직 확대", desc="육아휴직 2년 보장", ctgr="family")),
    ("b_co", "나회사", _b("parenting", "출산 축하금", desc="출산 축하금 지급", amt=100, qual=False, src="stated", ctgr="family")),
]


def test_legal_rows_stay_in_table_but_leave_every_aggregate():
    ctx = build_context(_bundle(PARENTING))
    view = benefit.build_view(ctx, _PARENTING_CFG)
    assert view["count"] == 2, "법정 행이 보유 회사 수에 섞였다"
    assert view["legal_rows"] == 1
    assert view["facets"][0]["count"] == 1, "법정 행의 「육아휴직」이 원문 항목 개수에 섞였다"
    assert view["questions"][0]["count"] == 1
    assert sum(s["count"] for s in view["amount_sources"] if s["key"] in ("stated", "est", "qual", "blank")) == 2
    assert "산전후휴가/육아휴직" not in view["names"]["shown"], "법정 행 이름이 「부르는 이름」에 섞였다"
    table = view["rows_first"] + view["rows_rest"]
    assert [r["comp_nm"] for r in table][-1] == "클래시스" and table[-1]["legal"], "법정 행은 표 맨 끝에 남는다"


def test_legal_row_renders_the_same_badge_as_the_company_page():
    pages, *_ = _render(PARENTING, {"parenting": _PARENTING_CFG})
    html = pages[0].html
    assert 'class="benefit-legal"' in html and ">법정</span>" in html
    assert "+ 법정 제도만 적은 회사 1곳" in html


def test_threshold_skips_thin_pages_and_counts_without_legal_rows():
    # 법정 행 포함 3행이지만 센 회사는 2곳 → 문턱 3이면 만들지 않는다
    pages, _, _, log = _render(PARENTING, {"parenting": _PARENTING_CFG}, min_companies=3)
    assert pages == [] and "parenting 건너뜀" in log and "보유 회사 2곳" in log


def _parenting_with_exclude():
    cfg = copy.deepcopy(_PARENTING_CFG)
    b = PARENTING[2][2]  # 나회사 「출산 축하금」 — 이 코드로 잘못 분류됐다고 치는 행
    cfg["overrides"] = [{"comp": "b_co", "h": br.text_hash(b["qual_desc_ctnt"], b["note_ctnt"]),
                         "exclude": True, "why": "테스트 — 잘못 분류된 행"}]
    return cfg


def test_excluded_row_leaves_table_and_every_aggregate():
    ctx = build_context(_bundle(PARENTING))
    view = benefit.build_view(ctx, _parenting_with_exclude())
    assert view["count"] == 1, "예외로 뺀 행이 N 에 남았다(법정 행 1 + 예외 1 을 빼면 1)"
    table = view["rows_first"] + view["rows_rest"]
    assert "나회사" not in [r["comp_nm"] for r in table], "예외로 뺀 행이 표에 남았다(법정 행과 달리 표에도 없어야 한다)"
    assert "출산 축하금" not in view["names"]["shown"]
    assert sum(s["count"] for s in view["amount_sources"]) == 1
    assert view["excluded"] == [{"comp": "b_co", "why": "테스트 — 잘못 분류된 행"}]


def test_threshold_is_judged_after_exclusion_and_logged():
    cfgs = {"parenting": _parenting_with_exclude()}
    pages, _, _, log = _render(PARENTING, cfgs, min_companies=2)
    assert pages == [] and "보유 회사 1곳" in log, "문턱은 법정 행·예외를 뺀 뒤 개수로 판정한다"
    assert "예외로 뺀 행 1곳(b_co)" in log
    pages, _, _, _ = _render(PARENTING, cfgs, min_companies=1)
    assert "나회사" not in pages[0].html


def test_default_threshold_is_twenty():
    assert benefit.MIN_COMPANIES == 20
    pages, _, _, log = _render(HOUSING, {"housing_loan": _housing_cfg()}, min_companies=benefit.MIN_COMPANIES)
    assert pages == [] and "건너뜀" in log


# ── ④ 설정 JSON 전부 — 스키마·사람 글 규칙 ───────────────────────────────────


def test_there_is_at_least_the_example_config():
    assert any(f.endswith("housing_loan.json") for f in CFG_FILES)


@pytest.mark.parametrize("path", CFG_FILES, ids=[os.path.basename(p) for p in CFG_FILES])
def test_every_config_file_is_valid(path):
    with open(path, encoding="utf-8") as f:
        cfg = json.load(f)
    assert cfg.get("code") == os.path.splitext(os.path.basename(path))[0], "파일 이름과 code 가 다르다"
    assert br.validate(cfg) == [], br.validate(cfg)
    assert br.check_no_digits(cfg) == [], "사람 글에 숫자(GC-29)"
    assert br.check_quantifiers(cfg) == [], "사람 글에 수량어 — 데이터가 바뀌면 거짓이 된다"


def test_all_configs_pass_cross_file_checks():
    """설정 전부를 함께 본다 — slug 중복 · **설정 사이의 같은 사람 글 문장**(필러). 빌드도 같은 검사로 멈춘다."""
    assert br.validate_all(br.load_pages()) == []


def _two(text_a, text_b):
    a, b = _valid(), _valid()
    b["code"], b["slug"] = "other", "other"
    a["notes"] = {"money": text_a}
    b["notes"] = {"money": text_b}
    for cfg in (a, b):
        cfg["intro"], cfg["questions"] = [f"{cfg['code']} 해설입니다."], [
            {"text": f"{cfg['code']} 질문인가요?", "answered_by": ["mode:known"]}]
    return {"housing_loan": a, "other": b}


def test_same_human_sentence_in_two_configs_is_rejected():
    errs = br.validate_all(_two("겹치는 문장입니다. 다른 말입니다.", "앞말입니다.  겹치는  문장입니다."))
    assert len(errs) == 1 and "겹치는 문장입니다." in errs[0] and "'housing_loan', 'other'" in errs[0], errs


def test_sentences_split_only_at_sentence_endings():
    """문장 단위 = 종결 「다.」「요.」「?」. 그 밖의 마침표(「등.」「무급.」)에서는 자르지 않는다."""
    assert br.sentences("가 등. 나입니다.  다인가요? 끝이에요.") == ["가 등. 나입니다.", "다인가요?", "끝이에요."]


def test_distinct_sentences_and_repeats_within_one_config_pass():
    assert br.validate_all(_two("가 문장입니다.", "나 문장입니다.")) == []
    cfgs = _two("같은 말입니다. 같은 말입니다.", "나 문장입니다.")  # 한 설정 안의 반복은 한 페이지 안의 일
    assert br.repeated_sentences(cfgs) == []


def _valid():
    return copy.deepcopy(_housing_cfg())


@pytest.mark.parametrize("mutate, needle", [
    (lambda c: c.pop("intro"), "필수 키 intro"),
    (lambda c: c.update(slug="Housing_Loan"), "slug"),
    (lambda c: c["questions"][0].update(answered_by=["facet:nope"]), "answered_by"),
    (lambda c: c["modes"].update(display=["direct", "ghost"]), "display"),
    (lambda c: c["overrides"][0].update(mode="ghost"), "mode 'ghost'"),
    (lambda c: c["overrides"][1].update(facets_remove=["ghost"]), "facet 'ghost'"),
    (lambda c: c["facets"][0].update(pattern="(unclosed"), "정규식"),
    (lambda c: c.update(money_facet="ghost"), "money_facet"),
    (lambda c: c.update(notes={"sidebar": "문장입니다."}), "notes 키"),
    (lambda c: c.pop("modes"), "answered_by"),  # 방식이 없는데 mode:known 을 가리키는 질문
    (lambda c: c["overrides"].append({"comp": "x", "h": "0", "exclude": True}), "comp·h·why"),  # 빼는 예외도 why 필수
    (lambda c: c["overrides"].append({"comp": "x", "h": "0", "exclude": "yes", "why": "w"}), "exclude 는 true"),
    (lambda c: c["overrides"].append({"comp": "x", "h": "0", "exclude": True, "mode": "direct", "why": "w"}), "함께 쓸 수 없다"),
])
def test_validate_catches_silent_config_errors(mutate, needle):
    cfg = _valid()
    mutate(cfg)
    errs = br.validate(cfg)
    assert any(needle in e for e in errs), errs


def test_validate_accepts_exclude_with_why():
    cfg = _valid()
    cfg["overrides"].append({"comp": "x", "h": "0", "exclude": True, "why": "잘못 분류된 행"})
    assert br.validate(cfg) == []


def test_human_text_rules_catch_digits_and_quantifiers():
    cfg = _valid()
    cfg["intro"] = ["대부분의 회사가 연 3회 지원합니다."]
    assert br.check_no_digits(cfg) and br.check_quantifiers(cfg)


def test_gc29_digits_in_human_text_fail_the_build():
    cfg = _valid()
    cfg["notes"] = {"money": "한도는 1억 원입니다."}
    with pytest.raises(BuildError, match="GC-29"):
        _check_benefit_human_text({"housing_loan": cfg})
    _check_benefit_human_text()  # 실제 설정 전부는 통과해야 한다


def test_invalid_config_stops_the_build(monkeypatch):
    """구조 오류는 경고가 아니라 **빌드 실패**다 — 틀린 설정은 거짓 개수를 찍은 채 초록으로 나간다."""
    cfg = _valid()
    cfg["questions"][0]["answered_by"] = ["facet:nope"]
    monkeypatch.setattr(br, "load_pages", lambda path=None: {"housing_loan": cfg})
    with pytest.raises(BuildError, match="SP-BEN 설정 오류"):
        benefit.load_configs()


# ── 렌더 — 링크·필러·법정 칸·메타 ──────────────────────────────────────────


def test_page_is_generated_at_clean_route_with_find_tab_active():
    pages, *_ = _render(HOUSING, {"housing_loan": _housing_cfg()})
    assert [p.path for p in pages] == ["benefit/housing-loan.html"]
    p = pages[0]
    assert p.url == f"{CFG.site_origin}/benefit/housing-loan" and p.in_sitemap
    assert f'<link rel="canonical" href="{p.url}">' in p.html
    assert 'href="/find" class="gnb-link" aria-current="page"' in p.html
    assert "<h1>주택자금 대출</h1>" in p.html, "h1 은 설정의 title 이다(derive_codes 라벨이 아니다)"
    assert "data-page-type" not in p.html, "항목 페이지는 무광고(page_type 미선언)"
    assert p.title.startswith("주택자금 대출 — ") and "주택자금 대출은 직원이" in p.description


def test_company_links_land_on_the_ledger_row_of_the_company_page():
    pages, ctx, env, _ = _render(HOUSING, {"housing_loan": _housing_cfg()})
    company_html = {p.path: p.html for p in company.render_all(env, ctx)}
    hrefs = re.findall(r'href="(/company/[^"#]+)#([^"]+)"', pages[0].html)
    assert len({h for h, _ in hrefs}) == len(HOUSING)
    for route, anchor in hrefs:
        assert f'id="{anchor}"' in company_html[route.lstrip("/") + ".html"], f"{route}#{anchor} 가 원장 행이 아니다"


def test_money_table_and_note_appear_with_three_or_more_rows():
    pages, *_ = _render(HOUSING, {"housing_loan": _housing_cfg()})
    html = pages[0].html
    assert "금액이 적힌 원문 4곳" in html  # CJ CGV · NAVER · SK텔레콤 · SK하이닉스(재수집 원문 「최대 2억원」) (펄어비스는 예외로 빠진다)
    assert _housing_cfg()["notes"]["money"] in html


def test_zero_answer_question_is_highlighted_with_a_label():
    pages, *_ = _render(HOUSING, {"housing_loan": _housing_cfg()})
    html = pages[0].html
    assert 'class="bn-q bn-q-zero"' in html and "원문에 밝힌 회사 없음" in html


def test_amount_cell_uses_the_company_card_rule():
    pages, *_ = _render(HOUSING, {"housing_loan": _housing_cfg()})
    html = pages[0].html
    assert '<i class="bn-est">추정</i> <span class="bn-amt-v">500만원</span>' in html  # SK하이닉스 추정
    assert '<span class="bn-amt-v">600만원</span>' in html  # 펄어비스 공식
    assert '<span class="bn-amt-none">정성</span>' in html


def test_legal_cell_quotes_the_baseline_table_or_says_it_is_absent():
    housing, *_ = _render(HOUSING, {"housing_loan": _housing_cfg()})
    assert "법정 기준선 표에 없는 항목" in housing[0].html
    parenting, *_ = _render(PARENTING, {"parenting": _PARENTING_CFG})
    html = parenting[0].html
    assert "근로기준법 제74조" in html and "90일 (다태아 120일)" in html
    assert "확인필요" in html, "표의 confidence 가 화면에서 사라졌다"
    assert "재수집 대상" not in html, "기준선 표의 내부 메모(note)가 새어 나왔다"


def _visible_text(page_html: str) -> str:
    main = page_html[page_html.index("<main"):page_html.index("</main>")]
    main = re.sub(r"<(script|style)\b.*?</\1>", " ", main, flags=re.S)
    return html_mod.unescape(re.sub(r"<[^>]+>", "\n", main))


def test_template_emits_no_fixed_sentences():
    """⑤ 필러 규칙 — 사람 글·회사 원문·기준선 표 칸을 걷어 낸 나머지에 「…다.」「…요.」 0.

    이 페이지의 고정 글은 제목·라벨·수치뿐이어야 한다. 템플릿이 문장 하나를 내보내는 순간 그 문장은
    항목 페이지 수만큼 반복되는 필러가 된다.
    """
    cases = [(HOUSING, {"housing_loan": _housing_cfg()}), (PARENTING, {"parenting": _PARENTING_CFG})]
    for rows, configs in cases:
        pages, ctx, _, _ = _render(rows, configs)
        cfg = next(iter(configs.values()))
        view = benefit.build_view(ctx, cfg)
        allowed = [t for _, t in br.human_texts(cfg)]
        for r in view["rows_first"] + view["rows_rest"]:
            allowed += [r["desc"], r["note"], r["name"]]
        for e in view["legal"]["entries"]:
            allowed += [e["paid"], e["name"], e["law"]]
        text = _visible_text(pages[0].html)
        for t in sorted((a for a in allowed if a), key=len, reverse=True):
            text = text.replace(t, " ")
        leftovers = [ln.strip() for ln in text.split("\n") if re.search(r"[다요]\.", ln)]
        assert leftovers == [], f"템플릿이 고정 문장을 내보낸다: {leftovers}"


# ── ⑥ 입구 — sitemap · /find (GC-30) ───────────────────────────────────────


def _site(rows, configs, with_links=True):
    pages, ctx, env, _ = _render(rows, configs)
    fp = find.render(env, ctx, CFG, benefit_links=benefit.links(pages, configs) if with_links else None)
    urls = [p.url for p in pages + [fp] if p.in_sitemap]
    sm = sitemap_page.render_sitemap(env, urls, "2026-09-18", CFG)
    return pages, fp, sm


def test_find_table_links_the_item_page_and_keeps_the_tool_entry():
    pages, fp, _ = _site(HOUSING, {"housing_loan": _housing_cfg()})
    assert 'href="/benefit/housing-loan"' in fp.html
    assert 'href="/find?b=housing_loan"' in fp.html, "항목 페이지가 생겨도 도구 입구(/find?b=)는 남는다"
    assert "「거르기」가 붙은 1종" in fp.html


def test_gc30_passes_when_sitemap_and_find_link_every_item_page():
    pages, fp, sm = _site(HOUSING, {"housing_loan": _housing_cfg()})
    assert f"<loc>{CFG.site_origin}/benefit/housing-loan</loc>" in sm.html
    _check_benefit_reachable(pages + [fp, sm])


def test_gc30_fails_when_find_does_not_link_the_page():
    pages, fp, sm = _site(HOUSING, {"housing_loan": _housing_cfg()}, with_links=False)
    with pytest.raises(BuildError, match="GC-30"):
        _check_benefit_reachable(pages + [fp, sm])


def test_gc30_fails_when_sitemap_misses_the_page():
    pages, fp, _ = _site(HOUSING, {"housing_loan": _housing_cfg()})
    env = make_env()
    sm = sitemap_page.render_sitemap(env, [fp.url], "2026-09-18", CFG)
    with pytest.raises(BuildError, match="GC-30"):
        _check_benefit_reachable(pages + [fp, sm])


def test_gc10_covers_item_pages_through_the_release_gate(fake_now):
    """항목 페이지도 비-JS 본문 게이트(GC-10)를 지난다 — 게이트 전체를 실제 페이지 집합으로 돌린다."""
    from generator.pages import home

    pages, fp, sm = _site(HOUSING, {"housing_loan": _housing_cfg()})
    env = make_env()
    ctx = build_context(_bundle(HOUSING), now=fake_now)
    run_generated_checks("unused", company.render_all(env, ctx) + pages + [fp, sm, home.render(env, ctx, CFG, pairs=[])])


# ── 추정 원문·빈 원문 (검증 반영 2026-09-18) ────────────────────────────────


def test_estimated_existence_row_is_not_counted_as_fact():
    """금액 없는 행의 「(추정)」 = 이 복지가 있다는 것 자체가 수집자 추정(`format.benefit_desc` 와 같은
    해석). 그 원문 속 「대출」「저금리」를 사실로 세면 공개 숫자에 추정이 섞인다(DB손해보험 구본)."""
    cfg = _housing_cfg()
    rows = [{"comp": "db_insurance", "desc": "저금리 주택자금 대출 지원 (추정)", "note": None, "unverified": True}]
    r = br.classify(cfg, rows)["rows"][0]
    assert r["facets"] == set() and r["mode"] == cfg["modes"]["fallback"]["key"] and r["blank"]


def test_blank_rows_are_disclosed_with_a_label_not_a_sentence():
    rows = HOUSING + [
        ("db_insurance", "DB손해보험", _b("housing_loan", "주택자금 대출 지원", desc="주택자금 대출 지원 (추정)")),
        ("remed", "리메드", _b("housing_loan", "주택자금 대출", note="(추정)", amt=100, qual=False, src="estimated")),
    ]
    pages, *_ = _render(rows, {"housing_loan": _housing_cfg()})
    html = pages[0].html
    assert '<p class="bn-blank">원문 내용이 없어 세지 않은 회사 2곳</p>' in html


def test_no_blank_label_when_every_row_has_text():
    pages, *_ = _render(HOUSING, {"housing_loan": _housing_cfg()})
    assert "bn-blank" not in pages[0].html


def test_duplicate_override_company_is_rejected():
    cfg = copy.deepcopy(_housing_cfg())
    cfg["overrides"] = cfg["overrides"] + [dict(cfg["overrides"][0])]
    assert any("override 회사가 겹친다" in e for e in br.validate(cfg))


def test_quantifier_in_human_text_fails_the_build_gate_too():
    cfg = copy.deepcopy(_housing_cfg())
    cfg["intro"] = ["대부분의 회사가 빌려줍니다."]
    assert br.validate_all({"housing_loan": cfg}), "수량어가 빌드 게이트(validate_all)를 통과했다"


# ── 회사 원장 → 항목 페이지 링크 (SP-BEN-12, 2026-09-18) ─────────────────────


def _company_html_with_index(rows, configs):
    """항목 페이지를 먼저 그리고, 그 색인으로 회사 페이지를 그린다(build.py 와 같은 순서)."""
    env = make_env()
    ctx = build_context(_bundle(rows))
    bpages = benefit.render_all(env, ctx, CFG, configs=configs, min_companies=1, log=io.StringIO())
    idx = benefit.page_index(ctx, bpages, configs)
    cpages = company.render_all(env, ctx, benefit_index=idx)
    return {p.path: p.html for p in cpages}, idx


def test_ledger_row_links_to_the_item_page_with_the_same_count():
    html, idx = _company_html_with_index(HOUSING, {"housing_loan": _housing_cfg()})
    n = idx["housing_loan"]["count"]
    page = next(h for pth, h in html.items() if "kt" in pth)
    assert f'<a href="/benefit/housing-loan">이 복지가 있는 회사 {n}곳 →</a>' in page
    assert n == len(HOUSING), "링크 숫자가 항목 페이지 머리의 N 과 다르다"


def test_excluded_company_gets_no_item_link():
    """예외로 뺀 회사에 링크를 걸면 도착한 페이지에 그 회사가 없다."""
    cfg = copy.deepcopy(_housing_cfg())
    kt = next(b for e, _, b in HOUSING if e == "kt")
    cfg["overrides"].append({"comp": "kt", "h": br.text_hash(kt["qual_desc_ctnt"], kt["note_ctnt"]),
                             "exclude": True, "why": "테스트"})
    html, idx = _company_html_with_index(HOUSING, {"housing_loan": cfg})
    assert "kt" not in idx["housing_loan"]["members"]
    kt_page = next(h for pth, h in html.items() if pth.endswith("/kt.html"))
    other = next(h for pth, h in html.items() if pth.endswith("/sk-telecom.html"))
    assert 'class="led-more"' not in kt_page
    assert 'href="/benefit/housing-loan"' in other


def test_no_item_link_without_a_generated_page():
    """설정이 없거나 문턱에 걸려 페이지가 안 생긴 항목에는 링크가 없다(죽은 링크 방지)."""
    html, idx = _company_html_with_index(HOUSING, {})
    assert idx == {}
    assert not any('class="led-more"' in h for h in html.values())
