"""가이드 C편 「복지처럼 보이지만 법으로 정해진 제도」 `/guide/legal-baseline` 계약 (SP-GUIDE-11, 2026-10-14, 리드 판정 (94)).

① 표 행 17 · 묶음 셋 · 칸 글자 = guide 칸 · 5명 미만 칸 = small_ok ② 자리표시 숫자 = JSON · ctx 값 ③ 문안에 숫자 · 수량어 없음
④ 인용 대조(바꾸면 BuildError) ⑤ 직원 수 최솟값 < 기준이면 BuildError · 법정 행 0 이면 단락 빠짐 ⑥ small_ok false 이름 목록은 JSON 에서 만든다
⑦ 좋은 예 링크 앵커가 회사 페이지에 실제 있음 ⑧ 탭 · sitemap · 무광고 · canonical · /guide 카드 순서 C → B → A → D ⑨ 빌드 시각 무관
⑩ next_change 를 지우면 「이미 정해진 변경」 줄 · 난임 작은 글 · Q6 꼬리가 빠진다.
인용 예 · 직원 수 대조는 운영 빌드에서만 켜진다(conftest 가 fake 번들용으로 끈다) — 이 파일은 `strict` 픽스처로 다시 켜고, 예시 JSON 에 맞춘 합성 번들로 구동한다.
"""
from __future__ import annotations

import ast
import copy
import json
import re
from datetime import datetime
from pathlib import Path

import pytest

from generator import legal, marks
from generator.config import CFG
from generator.content import guide_legal as T
from generator.content import guides as G
from generator.context import build_context
from generator.pages import company, guide_index, guide_legal as P
from generator.render import make_env
from generator.slug import BuildError
from generator.tests.test_about_data import _QUANTIFIERS

REPO_ROOT = Path(__file__).resolve().parents[2]


@pytest.fixture(autouse=True)
def strict(monkeypatch):
    monkeypatch.setattr(P, "STRICT_DATA", True)


def _ex() -> dict:
    return P.load_examples()


def _row(cd, nm, desc):
    return {"benefit_cd": cd, "benefit_nm": nm, "benefit_amt": None, "benefit_ctgr_cd": "family", "badge_cd": "est",
            "amt_source": "none", "qual_yn": True, "qual_desc_ctnt": desc, "note_ctnt": None, "verified_dtm": "2026-10-01",
            "expires_dtm": "2099-12-31", "badge_src_cd": "scrape_official", "badge_src_url_ctnt": "https://ex.com/src", "sort_order_no": 0}


def make_ctx(fake_bundle, fake_now, ex=None, head=500, drop_employ=False, extra_legal=True):
    """예시 JSON 이 가리키는 회사 · 행을 가진 합성 번들 — 인용 대조가 통과하는 기준 데이터."""
    ex = ex or _ex()
    rows: dict[str, list] = {}
    for r in ex["legal_rows"]:
        rows.setdefault(r["comp_eng_nm"], []).append(_row(r["benefit_cd"], r["benefit_nm"], r["quote"]))
    if extra_legal:  # 등록표의 셋째 법정 행(silicon2) — 인용 목록은 둘이지만 표시 행은 셋이다
        rows.setdefault("silicon2", []).append(_row("parenting", "출산휴가/육아휴직", "출산 휴가, 육아 휴직 제도"))
    for g in ex["good"]:
        rows.setdefault(g["comp_eng_nm"], []).append(_row(g["benefit_cd"], g["benefit_nm"], g["quote"] + " (공식 채용 사이트 복리후생 항목)"))
    b = copy.deepcopy(fake_bundle)
    base = b["companies"][0]
    names = {"yuhan": "유한양행", "hanwha_systems": "한화시스템", "hyundai_motor": "현대자동차", "gs_enc": "GS건설", "kia": "기아"}
    b["companies"] = [dict(base, comp_id=i + 1, comp_eng_nm=eng, comp_nm=names.get(eng, eng), aliases=[eng], benefits=bs,
                           careers_benefit_url="https://ex.com/c")
                      for i, (eng, bs) in enumerate(rows.items())]
    employ = None if drop_employ else {c["comp_id"]: {2025: {"salary": 5000, "tenure": 5.0, "head": head}} for c in b["companies"]}
    return build_context(b, now=fake_now, employ=employ)


@pytest.fixture
def ctx(fake_bundle, fake_now):
    return make_ctx(fake_bundle, fake_now)


def _main_text(html: str) -> str:
    main = html[html.index("<main"):html.index("</main>")]
    return re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", main))


def _page(ctx):
    return P.render(make_env(), ctx)


# ── ① 표 ─────────────────────────────────────────────────────────────────────


def test_table_has_every_item_in_three_groups_with_guide_text(ctx):
    html = _page(ctx).html
    table = html[html.index("<table"):html.index("</table>")]
    assert table.count('<th scope="row">') == len(legal.items()) == 17
    assert table.count('<th scope="rowgroup"') == 3
    for name, _ in T.GROUPS:
        assert f'>{name}</th>' in table
    for it in legal.items():
        assert f'<th scope="row">{it["name"]}</th>' in table
        assert f'<td>{it["guide"]["basis"]}</td>' in table and f'<td>{it["guide"]["pay"]}</td>' in table
        row = table[table.index(f'<th scope="row">{it["name"]}</th>'):]
        row = row[:row.index("</tr>")]
        assert row.endswith(f"<td>{T.SMALL_YES if it['small_ok'] else T.SMALL_NO}</td>\n        ") or f"<td>{T.SMALL_YES if it['small_ok'] else T.SMALL_NO}</td>" in row


def test_groups_cover_the_items_exactly_once():
    keys = [k for _, ks in T.GROUPS for k in ks]
    assert len(keys) == len(set(keys)) and set(keys) == {it["key"] for it in legal.items()}


def test_group_mismatch_stops_the_build(ctx, monkeypatch):
    monkeypatch.setattr(T, "GROUPS", T.GROUPS[:2])
    with pytest.raises(BuildError, match="묶음"):
        P.build_view(ctx)


def test_law_cell_rules():
    by = {it["key"]: it for it in legal.items()}
    assert P._law_cell(by["labor_day"]) == "노동절 제정에 관한 법률"  # 「단일조」는 표시하지 않는다
    assert P._law_cell(by["social_insurance"]) == "국민연금법 등 4개 법"
    assert P._law_cell(by["annual_leave"]) == "근로기준법 제60조"
    assert P._law_cell(by["spouse_birth_leave"]) == "남녀고용평등법 제18조의2"


# ── ② 자리표시 숫자 ──────────────────────────────────────────────────────────


def test_placeholders_equal_their_sources(ctx):
    v = P.values(ctx, True)
    by = {it["key"]: it for it in legal.items()}
    assert v["small_cut"] == legal.raw()["small_workplace"]["cut"] == 5
    assert v["mat_paid"] == by["maternity_leave"]["employer_paid_days"] == 60
    assert (v["spouse_days"], v["spouse_prev"]) == (by["spouse_birth_leave"]["baseline"]["value"], by["spouse_birth_leave"]["prev"]["value"]) == (20, 10)
    assert (v["infert_days"], v["infert_paid"], v["infert_paid_next"]) == (6, 2, 4) and v["infert_next_from"] == "2026년 11월 27일"
    assert v["lb_reviewed"] == "2026년 10월 13일" and v["lbl_legal"] == marks.KINDS["legal"]["label"] == "법정"
    assert (v["legal_rows"], v["legal_comps"]) == (3, 3)


def test_rendered_sentences_carry_the_values(ctx):
    t = _main_text(_page(ctx).html)
    for s in ("법정 기준선 검토일 2026년 10월 13일", "처음 60일을 회사가 주고", "상시 근로자 5명 이상인 사업장에만", "상시 5명 미만 사업장",
              "법이 정한 제도만 적힌 3건(3곳)은 지우지 않고 「법정」 표시를 달아 둡니다",
              "배우자 출산휴가의 법정 기간이 10일에서 20일로 늘어난 뒤", "「법정기간 10일에 추가로 10일 사용 가능」",
              "2026년 11월 27일부터 난임치료휴가의 유급 일수가 2일에서 4일로", "법은 연 6일 가운데 처음 2일을 유급으로 정합니다. 2026년 11월 27일부터는 처음 4일입니다.",
              "이미 정해진 변경: 2026년 11월 27일부터 난임치료휴가 — 처음 4일 유급(법률 제21700호).",
              "이미 정해진 변경: 2027년 6월 10일부터 연차유급휴가 — 근로자가 대통령령이 정하는 범위에서 시간 단위로 나눠 청구할 수 있음(법률 제21784호).",
              "표는 국가법령정보센터의 현행 원문과 2026년 10월 13일에 대조했습니다"):
        assert s in t, s
    assert t.index("2026년 11월 27일부터 난임치료휴가 —") < t.index("2027년 6월 10일부터 연차유급휴가 —")  # from 순


# ── ③ 문안 규율 ──────────────────────────────────────────────────────────────


def _content_strings() -> list[str]:
    tree = ast.parse((REPO_ROOT / "generator" / "content" / "guide_legal.py").read_text(encoding="utf-8"))
    return [n.value for n in ast.walk(tree) if isinstance(n, ast.Constant) and isinstance(n.value, str)]


def test_human_sentences_carry_no_numbers_or_quantifiers():
    strings = [s for s in _content_strings() if not s.startswith("generator/")]
    assert len(strings) > 40
    for s in strings:
        stripped = re.sub(r"\{[^}]*\}", "", s)  # 자리표시는 숫자 칸이다
        assert not re.search(r"\d", stripped), f"사람 문장에 숫자가 박혔다: {s!r}"
        for q in _QUANTIFIERS:
            assert not re.search(q + r"(?!지)", s), f"수량어: {s!r}"


def test_rendered_page_has_no_quantifiers(ctx):
    t = _main_text(_page(ctx).html)
    for q in _QUANTIFIERS:
        assert not re.search(q + r"(?!지)", t), q


def test_template_source_carries_no_numbers_or_quantifiers():
    src = (REPO_ROOT / "generator" / "templates" / "guide_legal.html").read_text(encoding="utf-8")
    text = re.sub(r"\{#.*?#\}|\{\{.*?\}\}|\{%.*?%\}", "", src, flags=re.S)
    text = re.sub(r"<[^>]+>", "", text)
    assert not re.search(r"\d", text), f"템플릿에 숫자가 박혔다: {text.strip()[:80]!r}"
    assert not any(q in text for q in _QUANTIFIERS)


# ── ④ 인용 대조 — 바꾸면 BuildError ──────────────────────────────────────────


def test_unmodified_examples_pass(ctx):
    P.build_view(ctx)


def _bad(fn):
    ex = copy.deepcopy(_ex())
    fn(ex)
    return ex


@pytest.mark.parametrize("mutate", [
    lambda e: e["legal_rows"][0].update(quote=e["legal_rows"][0]["quote"] + "요"),  # 법정 행 — 한 글자 달라도 멈춘다(같아야 한다)
    lambda e: e["legal_rows"][1].update(benefit_nm="없는 항목"),
    lambda e: e["legal_rows"][0].update(comp_eng_nm="없는회사"),
    lambda e: e["good"][0].update(quote="법정 기준보다 8일 추가 휴가 부여"),  # 좋은 예 — 화면 글자에 들어 있지 않다
    lambda e: e["good"][1].update(comp_eng_nm="없는회사"),
    lambda e: e["good"][0]["checks"][0].update(equals=24),  # 연차 한도가 바뀐 경우
    lambda e: e["good"][1]["checks"][0].update(equals=10),
    lambda e: e["good"][2]["checks"][0].update(equals=40),
    lambda e: e["good"][4]["checks"][0].update(equals="employer"),  # 생리휴가가 유급이 된 경우
    lambda e: e["good"][3]["checks"][0].update(what="모르는검사"),
    lambda e: e["old_law"]["checks"][0].update(equals=9),
    lambda e: e["old_law"].update(quote="법정기간 10일에 추가로 11일 사용 가능"),  # 합이 지금 값(20)보다 크면 더 주는 날이 생긴 것
])
def test_changed_example_stops_the_build(ctx, mutate):
    with pytest.raises(BuildError):
        P.build_view(ctx, examples=_bad(mutate))


@pytest.mark.parametrize("mutate", [
    lambda e: e["good"][0]["checks"][0].update(shown="최대 24일"),  # 풀이 글에 없는 법 숫자 글자
    lambda e: e["good"][2]["checks"][1].update(shown="처음 61일"),
    lambda e: e["good"][3]["checks"][1].update(equals=24),  # 육아휴직 요건 충족 시 18개월 → 24 (extended 사전)
    lambda e: e["good"][2]["checks"][1].update(equals=59),  # 사업주 유급 60일 (employer_paid_days 사전)
    lambda e: e["good"][0].pop("why"),
    lambda e: e["good"][0].update(why="법이 정한 연차는 최대 25일입니다."),  # 다른 check 의 shown 이 사라진 경우는 아래 별도
])
def test_good_example_why_and_shown_checks(ctx, mutate):
    ex = _bad(mutate)
    if ex["good"][0].get("why") == "법이 정한 연차는 최대 25일입니다.":
        P.build_view(ctx, examples=ex)  # shown 이 풀이에 있으면 통과
        return
    with pytest.raises(BuildError):
        P.build_view(ctx, examples=ex)


def test_good_example_company_without_a_source_url_stops_the_build(fake_bundle, fake_now):
    c = make_ctx(fake_bundle, fake_now)
    c.by_eng["kia"]["careers_benefit_url"] = None
    with pytest.raises(BuildError, match="근거 주소"):
        P.build_view(c)


def test_good_example_that_is_a_marked_row_stops_the_build(fake_bundle, fake_now):
    ex = _bad(lambda e: e["good"].__setitem__(0, dict(e["good"][0], comp_eng_nm="kt", benefit_cd="parenting", benefit_nm="출산/육아 지원", quote="출산휴가")))
    c = make_ctx(fake_bundle, fake_now)
    with pytest.raises(BuildError, match="인용이 지금 데이터와 다르다"):
        P.build_view(c, examples=ex)


def test_changed_legal_baseline_value_stops_the_build(ctx, monkeypatch):
    """법정 값이 바뀌어 인용 예의 전제(배우자 출산휴가 20일 · 출산전후휴가 90−60)가 깨지면 멈춘다."""
    raw = copy.deepcopy(legal.raw())
    for it in raw["items"]:
        if it["key"] == "spouse_birth_leave":
            it["baseline"]["value"] = 25
    monkeypatch.setattr(legal, "raw", lambda: raw)
    with pytest.raises(BuildError):
        P.build_view(ctx)


def test_money_sentence_premise_change_stops_the_build(ctx, monkeypatch):
    raw = copy.deepcopy(legal.raw())
    for it in raw["items"]:
        if it["key"] == "menstrual_leave":
            it["paid"] = "employer"
    monkeypatch.setattr(legal, "raw", lambda: raw)
    with pytest.raises(BuildError, match="돈은 누가 내나"):
        P.build_view(ctx)


def test_examples_data_shape():
    ex = _ex()
    good = ex["good"]
    assert len(good) == 5 and len({g["comp_eng_nm"] for g in good}) == 5 and len({g["label"] for g in good}) == 5
    assert len(ex["legal_rows"]) == 2
    for g in good:
        assert g["why"] and all(c.get("shown") is None or c["shown"] in g["why"] for c in g["checks"])  # 풀이에 나올 법 숫자 글자


def _seed_fields(src: str, cd: str, nm: str) -> list[str] | None:
    """시드 VALUES 튜플 `(@comp_id, 'cd', 'nm', …)` 의 최상위 필드들(문자열은 따옴표를 벗긴다). 없으면 None."""
    head = f"(@comp_id, '{cd}', '{nm}',"
    i = src.find(head)
    if i < 0:
        return None
    fields, buf, depth, q, j = [], [], 0, False, i
    while j < len(src):
        c = src[j]
        if q:
            if c == "\\" and j + 1 < len(src):
                buf.append(src[j + 1]); j += 2; continue
            if c == "'":
                if src[j + 1:j + 2] == "'":
                    buf.append("'"); j += 2; continue
                q = False
            else:
                buf.append(c)
        elif c == "'":
            q = True
        elif c == "(":
            depth += 1
            if depth > 1:
                buf.append(c)
        elif c == ")":
            depth -= 1
            if depth == 0:
                fields.append("".join(buf).strip()); return fields
            buf.append(c)
        elif c == "," and depth == 1:
            fields.append("".join(buf).strip()); buf = []
        else:
            buf.append(c)
        j += 1
    return None


def _seed_screen_text(src: str, r: dict) -> str | None:
    """시드 행 → 회사 페이지가 쓰는 화면 글자(`format.benefit_desc`). 칸 순서 = INSERT 열 목록(COMP_ID … SORT_ORDER_NO)."""
    from generator.format import benefit_desc
    f = _seed_fields(src, r["benefit_cd"], r["benefit_nm"])
    if f is None:
        return None
    desc = f[8]  # QUAL_DESC_CTNT
    return benefit_desc(desc, "none" if f[3] == "NULL" else "estimated")


def _seed_by_slug() -> dict:
    seed_dir = REPO_ROOT / "db" / "seed" / "benefit" / "sql"
    by_slug = {}
    for path in seed_dir.glob("*.sql"):
        src = path.read_text(encoding="utf-8")
        m = re.search(r"COMP_ENG_NM\s*=\s*'([A-Za-z0-9_]+)'", src)
        if m:
            by_slug[m.group(1)] = src
    return by_slug


def test_example_rows_match_the_seed_sql_at_the_gate():
    """게이트에서 인용 대조(REVIEW-C M-4) — 운영 빌드(`_validate_examples`)와 같은 검사를 시드 VALUES 튜플로 미리 돈다.
    시드의 그 행(benefit_cd · 항목명)을 찾아 서술에 `format.benefit_desc` 를 적용한 글자가 법정 행 인용과 **같고**, 좋은 예 인용을 **품는지**.
    ⚠ 이 7행을 건드리는 데이터 PR 은 `legal-examples.json` 을 함께 고친다 — 안 고치면 여기서 멈춘다(안 잡히면 release [4/7] 에서 멈춘다)."""
    by_slug = _seed_by_slug()
    ex = _ex()
    for r in ex["legal_rows"]:
        got = _seed_screen_text(by_slug.get(r["comp_eng_nm"], ""), r)
        assert got is not None, f"시드에 없다(benefit_cd · 항목명): {r['comp_eng_nm']}/{r['benefit_cd']}/{r['benefit_nm']}"
        assert got == r["quote"], f"{r['comp_eng_nm']} 시드 서술의 화면 글자가 인용과 다르다: {got!r}"
    for g in ex["good"]:
        got = _seed_screen_text(by_slug.get(g["comp_eng_nm"], ""), g)
        assert got is not None, f"시드에 없다(benefit_cd · 항목명): {g['comp_eng_nm']}/{g['benefit_cd']}/{g['benefit_nm']}"
        assert g["quote"] in got, f"{g['comp_eng_nm']} 시드 서술의 화면 글자에 인용이 없다: {got!r}"


def test_seed_check_catches_a_changed_description_or_code():
    """위 게이트 검사가 정말 걸리는지 — 기아 행 서술 · benefit_cd 를 바꾼 시드 사본에서 (스크래치 문자열 변이, 파일은 건드리지 않는다)."""
    src = _seed_by_slug()["kia"]
    g = next(x for x in _ex()["good"] if x["comp_eng_nm"] == "kia")
    assert g["quote"] in _seed_screen_text(src, g)
    assert g["quote"] not in _seed_screen_text(src.replace("여직원 유급 보건휴가 부여", "여직원 보건휴가(무급)"), g)
    assert _seed_screen_text(src.replace("(@comp_id, 'leave_general', '프로드림 휴가·유급 보건휴가'", "(@comp_id, 'health', '프로드림 휴가·유급 보건휴가'"), g) is None


# ── ⑤ 직원 수 · 법정 행 0 ────────────────────────────────────────────────────


def test_company_below_the_small_workplace_cut_stops_the_build(fake_bundle, fake_now):
    c = make_ctx(fake_bundle, fake_now, head=4)
    with pytest.raises(BuildError, match="직원 수 공시가 기준"):
        P.build_view(c)
    P.build_view(make_ctx(fake_bundle, fake_now, head=5))  # 기준 그대로면 통과(≥)


def test_no_employee_disclosure_stops_the_build(fake_bundle, fake_now):
    with pytest.raises(BuildError, match="직원 수 공시 회사가 하나도 없다"):
        P.build_view(make_ctx(fake_bundle, fake_now, drop_employ=True))


def test_zero_legal_rows_drops_the_paragraph(fake_bundle, fake_now, monkeypatch, tmp_path):
    ex = dict(_ex(), legal_rows=[])
    f = tmp_path / "ex.json"
    f.write_text(json.dumps(ex, ensure_ascii=False), encoding="utf-8")
    monkeypatch.setattr(P, "EXAMPLES_PATH", f)
    monkeypatch.setattr(marks, "row_mark", lambda *a: None)  # 등록표가 비었다고 본다
    c = make_ctx(fake_bundle, fake_now, ex=ex, extra_legal=False)
    v = P.build_view(c)
    assert len(v["how"]["paras"]) == 2 and "표시를 달아 둡니다" not in " ".join(v["how"]["paras"])
    assert v["bad"]["quotes"] == []
    html = P.render(make_env(), c).html
    assert "법이 정한 제도만 적은 예" in html and "표시를 달아 둡니다" not in html and T.BAD_INTRO not in html


# ── ⑥ small_ok false 이름 목록 ───────────────────────────────────────────────


def test_small_workplace_names_are_built_from_the_json(ctx, monkeypatch):
    t = _main_text(_page(ctx).html)
    # 표 순서(GROUPS) · 쉼표 구분(이름 안 「·」와 섞이지 않게)
    assert "연차유급휴가, 관공서 공휴일 유급휴일, 생리휴가, 연장·야간·휴일 가산수당은 상시 근로자 5명 이상인 사업장에만" in t
    raw = copy.deepcopy(legal.raw())
    for it in raw["items"]:
        it["small_ok"] = it["key"] not in ("annual_leave", "severance")
    monkeypatch.setattr(legal, "raw", lambda: raw)
    t2 = _main_text(_page(ctx).html)
    assert "연차유급휴가, 퇴직급여는 상시 근로자 5명 이상인 사업장에만" in t2


def test_insured_note_keeps_the_employers_shortfall_duty(ctx):
    t = _main_text(_page(ctx).html)
    assert ("출산전후휴가 · 배우자 출산전후휴가 · 배우자 유산·사산휴가 · 난임치료휴가는, 고용보험법이 정한 우선지원 대상기업이면 고용보험 급여도 나옵니다(급여에는 상한이 있습니다). "
            "이때도 출산전후휴가 · 배우자 출산전후휴가 · 배우자 유산·사산휴가의 회사 몫은 급여가 나온 만큼만 줄어들고, 모자라는 임금은 회사가 줍니다.") in t
    assert "대신 나옵니다" not in t


def test_good_examples_carry_a_why_line_and_answers_are_body_paragraphs(ctx):
    html = _page(ctx).html
    for g in _ex()["good"]:
        assert f'<p class="gl-why">{g["why"]}</p>' in html
    assert html.count('<li><strong>') == len(T.ASK) and "gl-small\">법은" not in html
    assert "<strong>생리휴가는 유급인가요?</strong><p>법은 유급을 요구하지 않습니다. 유급이면 회사가 더 주는 것입니다.</p>" in html
    assert "권장휴가는 원문에 설명이 없습니다." in html


# ── ⑦ 링크 앵커 ──────────────────────────────────────────────────────────────


def test_good_example_links_point_at_real_anchors_on_company_pages(ctx):
    v = P.build_view(ctx)
    assert len(v["good"]["list"]) == 5
    pages = {p.url.rsplit("/", 1)[1]: p.html for p in company.render_all(make_env(), ctx)}
    for g in v["good"]["list"]:
        path, anchor = g["href"].split("#")
        assert path.startswith("/company/") and anchor.startswith("b-")
        assert f'id="{anchor}"' in pages[path.rsplit("/", 1)[1]], g["href"]
    html = _page(ctx).html
    for g in v["good"]["list"]:
        assert f'<a href="{g["href"]}">{g["company"]}</a>' in html


def test_good_list_shows_company_names_from_ctx(ctx):
    names = [g["company"] for g in P.build_view(ctx)["good"]["list"]]
    assert names == ["유한양행", "한화시스템", "현대자동차", "GS건설", "기아"]


# ── ⑧ 페이지 · /guide 카드 · 탭 · sitemap · 무광고 ───────────────────────────


def test_page_meta_tab_adless_canonical(ctx):
    page = _page(ctx)
    assert page.path == "guide/legal-baseline.html" and page.url == CFG.site_origin + "/guide/legal-baseline" and page.in_sitemap
    assert page.title == f"복지처럼 보이지만 법으로 정해진 제도 | {CFG.site_name}"
    assert page.description == "채용 페이지의 복지 목록에 「육아휴직」이나 「연차」가 적혀 있을 때가 있습니다. 법이 정한 선과 회사가 더 주는 복지를 나눠 보는 법을 적어 둡니다."
    assert len(page.description) <= CFG.desc_max
    assert '<a href="/guide" class="gnb-link" aria-current="page">가이드</a>' in page.html and page.html.count('aria-current="page"') == 1
    assert '<body data-page-type="policy">' in page.html and "data-ad-position" not in page.html
    assert f'<link rel="canonical" href="{page.url}">' in page.html and 'property="og:url"' in page.html and 'content="website"' in page.html
    assert '<p class="guide-crumb"><a href="/guide">가이드</a> › 법정 제도</p>' in page.html
    assert "<h1>복지처럼 보이지만 법으로 정해진 제도</h1>" in page.html
    assert "<script" not in page.html[page.html.index("<main"):page.html.index("</main>")]
    assert 'href="/about/data"' in page.html and "복지 항목 페이지에서 법정 기준 보기" not in page.html


def test_guide_index_lists_c_then_b_then_a_then_d():
    cards = guide_index.cards()
    assert [c["href"] for c in cards] == ["/guide/legal-baseline", "/guide/total-compensation"] + [G.report_route(e) for e in G.REPORT_EDITIONS] + [G.DATA_ROUTE]
    assert cards[0] == {"href": "/guide/legal-baseline", "title": T.H1, "desc": T.CARD_DESC}
    html = guide_index.render(make_env(), None, CFG).html
    assert html.index("/guide/legal-baseline") < html.index("/guide/total-compensation") < html.index("/guide/report-2026-10") < html.index("/about/data")


def test_pipeline_emits_page_and_sitemap_entry(fake_bundle, fake_combinations_path, tmp_path, monkeypatch):
    from generator import build as build_module
    monkeypatch.setattr(P, "STRICT_DATA", False)  # fake 번들에는 실제 회사 · 직원 수가 없다(운영 빌드는 켜져 있다)
    out = tmp_path / "dist"
    assert build_module.run(str(out), fake_bundle, lastmod="2026-10-14") == 0  # conftest 가 fake 번들용으로 대조를 끈다
    assert (out / "guide" / "legal-baseline.html").is_file()
    assert f"<loc>{CFG.site_origin}/guide/legal-baseline</loc>" in (out / "sitemap.xml").read_text(encoding="utf-8")


# ── ⑨ 빌드 시각 무관 ─────────────────────────────────────────────────────────


def test_output_does_not_depend_on_build_time(fake_bundle, fake_now):
    env = make_env()
    a = P.render(env, make_ctx(fake_bundle, fake_now))
    b = P.render(env, make_ctx(fake_bundle, datetime(2031, 1, 1)))
    assert a.html == b.html


# ── ⑩ next_change 를 지우면 ──────────────────────────────────────────────────


def test_removing_the_infertility_next_change_drops_its_lines(ctx, monkeypatch):
    raw = copy.deepcopy(legal.raw())
    for it in raw["items"]:
        if it["key"] == "infertility_leave":
            del it["next_change"]
    monkeypatch.setattr(legal, "raw", lambda: raw)
    t = _main_text(_page(ctx).html)
    assert "난임치료휴가 — 처음 4일 유급" not in t  # 이미 정해진 변경 줄
    assert "유급 일수가 2일에서 4일로" not in t  # 작은 글
    assert "부터는 처음 4일입니다" not in t  # Q6 꼬리
    assert "법은 연 6일 가운데 처음 2일을 유급으로 정합니다." in t
    assert "2027년 6월 10일부터 연차유급휴가" in t  # 연차 줄은 남는다


def test_removing_every_next_change_leaves_no_changes_line(ctx, monkeypatch):
    raw = copy.deepcopy(legal.raw())
    for it in raw["items"]:
        it.pop("next_change", None)
    monkeypatch.setattr(legal, "raw", lambda: raw)
    assert "이미 정해진 변경" not in _main_text(_page(ctx).html)


# ── 항목 페이지 → C편 링크 ───────────────────────────────────────────────────


def test_benefit_page_links_to_the_article_only_when_it_has_a_legal_table():
    from generator.pages import benefit as B
    assert B._legal_view("parenting")["more_href"] == G.LEGAL_ROUTE
    tpl = (REPO_ROOT / "generator" / "templates" / "benefit.html").read_text(encoding="utf-8")
    assert "/guide/legal-baseline" not in tpl  # 경로 글자를 템플릿에 박지 않는다
    i = tpl.index('class="bn-law-more"')
    assert tpl.index("{% if view.legal.entries %}") < i < tpl.index("{% else %}", i)  # 법정 표가 있을 때만
