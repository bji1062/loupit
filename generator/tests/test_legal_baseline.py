"""법정 기준선 테이블 + 조회 (SP-LEGAL-1, 2026-09-16).

복지는 「회사가 주는 것」이 아니라 「법이 시킨 것 위에 더 얹은 것」이다. 그 기준선을
`generator/data/legal_baseline.json` 하나가 갖고, 이 모듈이 읽는다.

사용자 결정(2026-09-16):
  · 금액 환산은 **이직 계산기에서만**. 회사 상세·복지 비교는 배지(일수·사실)까지.
  · 환산 단가는 **사용자가 입력한 연봉**. 회사 평균연봉(DART)을 쓰지 않는다.
  · 환산 대상은 **연차 하나**. 2025 개정분 4건은 법 확인 전이라 잠가 둔다.
"""
from __future__ import annotations

import pytest

from generator import legal


# ── 표 자체의 계약 ──────────────────────────────────────────────────────────


def test_table_loads_and_every_item_has_the_required_fields():
    items = legal.items()
    assert len(items) >= 14
    for it in items:
        for f in ("key", "name", "law", "article", "identify", "convert", "baseline",
                  "paid", "confidence", "note"):
            assert f in it, f"{it.get('key')} 에 {f} 없음"


def test_keys_are_unique():
    keys = [it["key"] for it in legal.items()]
    assert len(keys) == len(set(keys))


def test_only_annual_leave_is_convertible():
    """환산은 연차 하나뿐(사용자 결정). 여기가 늘면 화면에 나가는 금액이 늘어난다 — 의도적으로만 늘릴 것."""
    assert legal.convertible_keys() == ["annual_leave"]


def test_every_item_is_identifiable():
    """식별은 전부 — 법정 제도를 복지 항목 수에서 빼려면 전부 알아야 한다."""
    assert all(it["identify"] for it in legal.items())


def test_fixed_baseline_extra_keys_are_all_rendered():
    """`fixed` 기준의 덧붙임 키(미숙아·다태아·요건 충족 시·최대)는 화면 렌더러가 아는 키여야 한다.

    렌더러(`pages/benefit.py::_baseline_text`)가 모르는 키를 표에만 넣으면 화면에서 **조용히 빠진다**
    (2026-09-28 대조 때 `premature_birth` 등을 넣으며 드러난 함정 — 옛 렌더러는 `multiple_birth` 만 읽었다).
    """
    from generator.pages.benefit import FIXED_EXTRA_KEYS
    known = {"type", "value", "unit"} | {k for k, _ in FIXED_EXTRA_KEYS}
    for it in legal.items():
        bl = it["baseline"]
        if bl.get("type") == "fixed":
            assert set(bl) <= known, f"{it['key']} 의 {set(bl) - known} 를 렌더러가 모른다"


def test_revised_baselines_match_the_law_as_checked_2026_09_28():
    """법제처 현행 원문 대조(2026-09-28)로 바로잡은 값 — 옛 값으로 되돌아가면 화면이 법과 어긋난다.

    육아휴직 18개월 한 값은 과대(기본 1년, 요건 충족 시 18개월) · 육아기 단축 24개월은 개정 전 구조(최대 3년) ·
    출산전후휴가 미숙아 100일 누락 · 근로자의 날 → 노동절(법률 제21134호).
    """
    assert legal.by_key("parental_leave")["baseline"] == {"type": "fixed", "value": 12, "unit": "개월", "extended": 18}
    assert legal.by_key("parental_work_reduction")["baseline"]["max"] == 36
    assert legal.by_key("maternity_leave")["baseline"]["premature_birth"] == 100
    assert legal.by_key("labor_day")["law"] == "노동절 제정에 관한 법률"
    assert not [it["key"] for it in legal.items() if it["confidence"] == "확인필요"]


def test_unconfirmed_items_are_locked_out_of_conversion():
    """2025 개정분은 법제처 확인 전이다. 확인 전에 금액이 나가면 그대로 틀린 숫자다."""
    for it in legal.items():
        if it["confidence"] == "확인필요":
            assert it["convert"] is False, f"{it['key']} 가 확인 전인데 환산 대상이다"


def test_unpaid_and_insurance_items_are_never_convertible():
    """무급·고용보험 부담은 회사 지출이 아니다 — 일당을 곱하면 없는 돈을 만든다."""
    for it in legal.items():
        if it["paid"] in ("unpaid", "insurance"):
            assert it["convert"] is False, f"{it['key']} 는 회사 지출이 아닌데 환산 대상이다"


def test_working_hour_constants_are_not_duplicated_here():
    """근로시간 상수의 정본은 calc.js 다. 여기 복제하면 두 값이 조용히 갈라진다."""
    raw = legal.raw()
    assert "MONTHLY_STD_HRS" not in str(raw.get("items")), "근로시간 상수를 items 에 복제하지 마라"
    assert raw["wage"]["monthly_std_hours_owner"].endswith("MONTHLY_STD_HRS")


def test_wage_source_is_user_input_not_company_average():
    """회사 평균연봉을 단가로 쓰면 회사마다 기준이 달라지고 수집 오류가 금액으로 증폭된다."""
    assert legal.raw()["wage"]["source"] == "user_input"


# ── 연차 법정 기준선(근속 함수) — 근로기준법 60조 ──────────────────────────


@pytest.mark.parametrize("years,expected", [
    (0, 11),    # 1년 미만: 1개월 개근 1일씩, 최대 11일
    (0.5, 11),
    (1, 15),    # 1년 이상 80% 출근: 15일
    (2, 15),
    (3, 16),    # 3년 이상부터 2년마다 +1
    (4, 16),
    (5, 17),
    (7, 18),
    (21, 25),   # 한도 25일
    (30, 25),
])
def test_annual_leave_baseline_by_tenure(years, expected):
    assert legal.annual_leave_days(years) == expected


def test_annual_leave_default_tenure_is_first_year():
    """맥락(근속)이 없으면 입사 1년차로 본다 — 이직 계산기의 기본 상황."""
    assert legal.annual_leave_days(None) == 15


# ── 초과분 ──────────────────────────────────────────────────────────────────


def test_surplus_is_company_days_minus_baseline():
    assert legal.annual_leave_surplus(22, tenure_years=1) == 7
    assert legal.annual_leave_surplus(15, tenure_years=1) == 0


def test_surplus_shrinks_for_long_tenure():
    """같은 22일도 10년차에겐 법정이 19일이라 초과가 3일뿐이다 — 15일 고정으로 보면 부풀려진다."""
    assert legal.annual_leave_days(10) == 19
    assert legal.annual_leave_surplus(22, tenure_years=10) == 3


def test_surplus_can_be_negative_and_is_not_clamped():
    """법정 미달은 숨기지 않는다 — 우리 데이터가 낡았다는 신호이기 때문이다(배우자 출산휴가 10일 사례)."""
    assert legal.annual_leave_surplus(12, tenure_years=1) == -3


def test_unknown_days_is_none_not_zero():
    """일수를 모르는 것과 초과분이 0인 것은 다르다. 섞으면 멀쩡한 회사를 0원으로 깎는다."""
    assert legal.annual_leave_surplus(None, tenure_years=1) is None


# ── 일당 — calc.js 통상임금 공식과 같은 값이어야 한다 ───────────────────────


def test_daily_wage_uses_ordinary_wage_formula():
    """통상임금 1일분 = 연봉 ÷ 12 ÷ 209 × 8. 209는 주휴시간을 포함하므로 근무일 21로 나누면 과대계상된다."""
    got = legal.daily_wage_manwon(10000)
    assert round(got, 2) == round(10000 / 12 / 209 * 8, 2)
    assert 31 < got < 33            # 연봉 1억 → 하루 약 31.9만원
    assert got < 10000 / 12 / 21    # ÷21 로 계산한 값보다 작아야 한다


def test_daily_wage_of_zero_or_missing_salary_is_none():
    assert legal.daily_wage_manwon(None) is None
    assert legal.daily_wage_manwon(0) is None


def test_annual_leave_value_end_to_end():
    """유한양행 연차 22일 · 사용자 연봉 1억 · 입사 1년차 → 7일 × 31.9만원."""
    v = legal.annual_leave_value(company_days=22, annual_salary_manwon=10000, tenure_years=1)
    assert v["surplus_days"] == 7
    assert v["baseline_days"] == 15
    assert 220 < v["value_manwon"] < 226


def test_value_is_none_when_days_unknown():
    v = legal.annual_leave_value(company_days=None, annual_salary_manwon=10000, tenure_years=1)
    assert v["surplus_days"] is None and v["value_manwon"] is None


def test_value_is_none_without_user_salary():
    """단가가 없으면 금액을 만들지 않는다 — 회사 평균연봉으로 대체하지 않는다."""
    v = legal.annual_leave_value(company_days=22, annual_salary_manwon=None, tenure_years=1)
    assert v["surplus_days"] == 7 and v["value_manwon"] is None


# ── 교차 언어 계약: calc.js 와 값이 갈리지 않는가 ───────────────────────────


def test_monthly_std_hours_matches_calc_js():
    """근로시간 상수의 정본은 `calc.js` 다. 파이썬 쪽 기본값이 그 값과 갈리면 같은 연차가
    화면(JS)과 생성기(파이썬)에서 다른 금액이 된다 — 이 저장소가 배지 계보로 이미 밟은 함정이다."""
    import re
    from pathlib import Path

    src = (Path(__file__).resolve().parents[2] / "web" / "assets" / "js" / "calc.js").read_text(encoding="utf-8")
    m = re.search(r"MONTHLY_STD_HRS\s*=\s*(\d+)", src)
    assert m, "calc.js 에서 MONTHLY_STD_HRS 를 못 찾았다 — 정본이 옮겨졌는지 확인하라"
    assert legal.DEFAULT_MONTHLY_STD_HRS == int(m.group(1))


def test_benefit_cd_lookup_flags_statutory_codes():
    """`leave_general`·`parenting` 은 법정 제도가 섞여 들어오는 코드다(2026-09-16 감사 80행)."""
    assert legal.benefit_cd_is_legal("leave_general")
    assert legal.benefit_cd_is_legal("parenting")
    assert not legal.benefit_cd_is_legal("meal")


# ── 법정 행 — 표시는 남기고 집계에서만 뺀다 (SP-LEGAL-5) ────────────────────


def test_legal_rows_lookup_is_by_company_code_and_name():
    """같은 코드(`parenting`·`leave_general`)에 법정 행과 진짜 복지 행이 섞여 있다.
    코드만 보고 판정하면 멀쩡한 복지가 통째로 빠진다."""
    assert legal.is_legal_row("kt", "parenting", "출산/육아 지원")
    assert not legal.is_legal_row("yuhan", "leave_general", "연차휴가 (법정 상회)")
    assert not legal.is_legal_row("kt", "parenting", "다른 이름")


def test_legal_rows_all_exist_in_seed_sql():
    """참조 파일이 낡으면 빌드를 깨뜨린다.

    이 목록은 시드 SQL 이 아니라 생성기 참조 파일이다(`company_registrations.json` 선례).
    시드에서 행이 사라지거나 항목명이 바뀌면 판정이 조용히 False 가 되어 법정 행이 다시
    복지로 세어진다 — 그 침묵을 여기서 막는다.
    """
    from pathlib import Path

    import re

    seed_dir = Path(__file__).resolve().parents[2] / "db" / "seed" / "benefit" / "sql"
    # 회사 파일 단위로 좁힌다. 시드 전체를 한 덩어리로 이어 붙여 이름만 찾으면
    # 다른 회사가 같은 이름을 들고 있는 행은 자기 시드에서 사라져도 통과한다
    # (2026-09-21 실측: 등록 13행 중 4행이 그 상태였다 — 「출산/육아 지원」 7사 공유 등).
    by_slug = {}
    for path in seed_dir.glob("*.sql"):
        src = path.read_text(encoding="utf-8")
        m = re.search(r"COMP_ENG_NM\s*=\s*'([A-Za-z0-9_]+)'", src)
        if m:
            by_slug[m.group(1)] = src
    missing = [f"{r['comp_eng_nm']}/{r['benefit_nm']}" for r in legal.legal_rows()
               if f"'{r['benefit_nm']}'" not in by_slug.get(r["comp_eng_nm"], "")]
    assert not missing, f"시드에서 사라진 법정 행: {missing}"


def test_legal_rows_cover_the_audited_companies():
    rows = legal.legal_rows()
    # 2026-09-20: 시간·2시간 단위 휴가 5행을 복지로 되돌려 등록 해제(사용자 결정)
    # 2026-09-22: 한화에어로스페이스 「아빠휴가」 등록(재코딩으로 parenting 에 들어오며 한화시스템과 같은 판정)
    # 2026-09-26: SK이노베이션 「출산/육아 지원」 등록 해제 — 재수집 서술이 회사 제도(출산 전 휴직 1~3개월)뿐
    # 2026-09-28: 카카오뱅크 parenting 등록 해제 — 재수집 서술이 회사 제도(영유아지원금)뿐
    # 2026-10-01: 네패스 생일 휴가 · 2시간 단위 휴가 · 파마리서치 단체 휴가 등록 해제 — R-3 묶음 2 재수집 원문이 회사 복지
    # 2026-10-02: 현대제철 「출산/육아」 등록 해제 — R-3 묶음 4-B 재수집 서술이 회사 제도(육아휴직 최대 2년 등 상회분)뿐
    # 2026-10-02: 한화시스템 · 한화에어로스페이스 parenting 등록 해제 — R-3 묶음 5 재수집 서술이 회사 상회분(배우자 출산휴가 법정 20일 초과분 등)뿐
    # 2026-10-02: 이오테크닉스 「출산/육아 지원」 등록 해제 — R-3 묶음 6 재수집에서 법정 제도만 적힌 항목이라 행을 싣지 않음
    # 2026-10-02: 클래시스 「산전후휴가/육아휴직」 등록 해제 — R-3 묶음 6 재수집 서술이 회사 상회분(출산 축하금)뿐
    # 2026-10-02: 레인보우로보틱스 「육아휴직」 등록 해제 — R-3 묶음 6 재수집에서 법정 제도만 적힌 항목이라 행을 싣지 않음
    assert len(rows) == 3
    assert len({r["comp_eng_nm"] for r in rows}) == 3
    for r in rows:
        assert r["desc_at_review"] and r["why"], f"{r['comp_eng_nm']} 판정 근거가 비었다"


def _fake_company(eng, benefit_names, ctgr="leave_general"):
    return {
        "comp_id": 1, "comp_eng_nm": eng, "comp_nm": eng,
        "benefits": [{"benefit_cd": ctgr, "benefit_nm": nm, "benefit_amt": None,
                      "benefit_ctgr_cd": "time_off", "qual_yn": True,
                      "qual_desc_ctnt": nm, "badge_cd": "est"} for nm in benefit_names],
    }


def test_corpus_excludes_legal_rows_from_item_count():
    """법정 행이 항목 수에 들어가면 근로기준법을 지키는 것만으로 순위가 오른다."""
    from generator import corpus as corpus_mod
    from generator.pages.company import CATEGORY_ORDER

    c = _fake_company("kt", ["출산/육아 지원", "하계휴가"], ctgr="parenting")
    built = corpus_mod.build([c], CATEGORY_ORDER)
    assert built.items[1] == 1, "법정 행 1개가 항목 수에서 빠져야 한다"


def test_corpus_counts_normal_rows_of_the_same_code():
    """같은 코드의 진짜 복지 행까지 빠지면 안 된다."""
    from generator import corpus as corpus_mod
    from generator.pages.company import CATEGORY_ORDER

    c = _fake_company("yuhan", ["연차휴가 (법정 상회)", "하계휴가"])
    assert corpus_mod.build([c], CATEGORY_ORDER).items[1] == 2


def test_ledger_keeps_the_legal_row_but_flags_it(fake_now):
    """행은 남는다 — 「이 회사가 연차를 준다」는 사실은 정보다. 배지만 붙는다."""
    from generator.pages.company import _group_benefits

    c = _fake_company("kt", ["출산/육아 지원", "하계휴가"], ctgr="parenting")
    groups = _group_benefits(c["benefits"], fake_now, comp_eng_nm="kt")
    items = [i for _, _, its in groups for i in its]
    assert len(items) == 2, "원장에서 행을 지우지 않는다"
    assert [bool(i["mark"]) for i in items].count(True) == 1
    assert [i["mark"]["kind"] for i in items if i["mark"]] == ["legal"]


def test_group_benefits_without_company_name_flags_nothing(fake_now):
    """회사 이름이 없으면 판정이 전부 False 가 된다 — 조합 페이지가 eng 를 꼭 넘겨야 하는 이유."""
    from generator.pages.company import _group_benefits

    c = _fake_company("kt", ["출산/육아 지원"], ctgr="parenting")
    groups = _group_benefits(c["benefits"], fake_now)
    assert all(not i["mark"] for _, _, its in groups for i in its)


# ── 글 C편이 읽는 칸 (SP-GUIDE-11, 2026-10-14) ──────────────────────────────
# `guide` 칸(글 표의 사람 글자)은 구조 칸 숫자를 글자로 다시 쓴 것이다. 값만 바꾸고 글자를 안 고치면 여기서 멈춘다.

import datetime
import re

_NEW_ITEM_KEYS = {"small_ok", "small_note", "employer_paid_days", "employer_paid_days_multi", "next_change", "prev", "guide"}
_OLD_ITEM_KEYS = {"key", "name", "law", "article", "identify", "convert", "convert_basis", "baseline", "paid", "paid_note",
                  "effective_from", "confidence", "benefit_cds", "note"}
# 개월 ↔ 년 환산 표 — 글자 기준이 「년」인 항목만 여기 있다(임의 처리 금지: 표에 없는 개월 값이 생기면 실패한다).
_MONTHS_AS_TEXT = {12: "1년", 18: "1년 6개월", 36: "3년"}


def _ints(text: str) -> set[int]:
    return {int(x) for x in re.findall(r"\d+", text)}


def test_every_item_has_guide_and_small_ok_and_header_fields():
    raw = legal.raw()
    assert raw["reviewed"] == "2026-10-13"
    assert raw["small_workplace"]["cut"] == 5 and raw["small_workplace"]["law"] == "근로기준법 제11조"
    for it in legal.items():
        assert isinstance(it.get("small_ok"), bool), it["key"]
        g = it.get("guide") or {}
        assert g.get("basis") and g.get("pay"), it["key"]
    assert [it["key"] for it in legal.items() if not it["small_ok"]] == ["annual_leave", "menstrual_leave", "public_holiday", "overtime_premium"]


def test_item_keys_are_all_known_to_the_renderer():
    """항목 키의 허용 목록 — 모르는 키가 생기면 글(`pages/guide_legal.py`)이 조용히 안 읽는다(FIXED_EXTRA_KEYS 함정과 같은 뜻)."""
    for it in legal.items():
        assert set(it) <= _OLD_ITEM_KEYS | _NEW_ITEM_KEYS, f"{it['key']} 의 {set(it) - _OLD_ITEM_KEYS - _NEW_ITEM_KEYS} 를 렌더러가 모른다"


# formula · set 의 값 글자 ↔ basis 글자가 다르게 쓰인 낱말 — 「1일 2시간」 ↔ 「하루 2시간」(임의 처리 금지: 여기 있는 낱말만 정수로 환산)
_BASIS_ALIAS_INTS = {"하루": 1}
_PAID_WORDS = {"employer": ("회사",), "unpaid": ("무급",), "insurance": ("고용보험",)}  # mixed = 회사 + (무급 또는 고용보험)


def _basis_ints(basis: str) -> set[int]:
    return _ints(basis) | {n for w, n in _BASIS_ALIAS_INTS.items() if w in basis}


def _check_tenure_table(it: dict, basis: str) -> None:
    """연차 — 값이 글자 속 **자기 자리**에 있는지(같은 숫자가 다른 자리에 있어도 통과하지 못하게 이름표 · 순서로 대조)."""
    rows = it["baseline"]["table"]
    first, mid = rows[0], next(r for r in rows if r.get("from_years") == 1)
    step = next(r for r in rows if r.get("step_years"))
    marks = [f"최대 {first['value']}일", f"{mid['value']}일", f"{step['from_years']}년 이상", f"{step['step_years']}년마다 {step['step_value']}일", f"최대 {step['cap']}일"]
    at = 0  # 앞 낱말 **뒤에서** 다음 낱말을 찾는다 — 같은 숫자가 앞 자리에 있어도(「최대 11일」의 11일) 통과하지 못하게
    for m in marks:
        i = basis.find(m, at)
        assert i >= 0, f"{it['key']}: 「{m}」가 basis 의 제자리(앞 낱말 뒤)에 없다 — 값을 바꿨다면 guide 글자도 고쳐라: {marks}"
        at = i + len(m)


def test_guide_text_contains_the_structured_numbers():
    """값만 바꾸고 글자를 안 고치면 멈춘다 — 숫자는 이름표(미숙아 · 다태아 · 최대 …)와 함께, 연차는 자기 자리에서 대조한다(REVIEW-C M-3)."""
    from generator.pages.benefit import FIXED_EXTRA_KEYS
    labels = dict(FIXED_EXTRA_KEYS)
    for it in legal.items():
        basis, pay, bl = it["guide"]["basis"], it["guide"]["pay"], it["baseline"]
        if bl["type"] == "fixed":
            unit = bl["unit"]
            if unit == "개월":
                assert bl["value"] in _MONTHS_AS_TEXT, f"{it['key']} 의 {bl['value']}개월은 환산 표에 없다 — 표에 더하고 글자를 확인하라"
                base_txt = _MONTHS_AS_TEXT[bl["value"]]
                assert base_txt in basis, f"{it['key']}: {bl['value']}개월 → 「{base_txt}」가 basis 에 없다"
                if bl.get("extended"):  # 「요건 … {년}」 — 요건 문구 뒤에 확대된 기간이 온다
                    assert bl["extended"] in _MONTHS_AS_TEXT, f"{it['key']} 의 {bl['extended']}개월은 환산 표에 없다"
                    ext = _MONTHS_AS_TEXT[bl["extended"]]
                    assert ext in basis and basis.index(ext) > basis.index(base_txt) and "면 " + ext in basis, f"{it['key']}: 요건 충족 시 「{ext}」 자리가 어긋났다"
                if bl.get("max"):
                    assert bl["max"] in _MONTHS_AS_TEXT, f"{it['key']} 의 최대 {bl['max']}개월은 환산 표에 없다"
                    assert f"최대 {_MONTHS_AS_TEXT[bl['max']]}" in basis, f"{it['key']}: 「최대 {_MONTHS_AS_TEXT[bl['max']]}」가 basis 에 없다"
            else:
                head = f"{bl['value']}일" if unit.startswith("일") and unit != "일/주" else None
                assert (head in basis) if head else (bl["value"] in _ints(basis)), f"{it['key']}: 값 {bl['value']}{unit} 가 basis 글자에 없다"
                for k in ("premature_birth", "multiple_birth"):  # 덧붙임은 이름표와 함께
                    if bl.get(k):
                        assert f"{labels[k].strip()} {bl[k]}{unit}" in basis, f"{it['key']}: 「{labels[k].strip()} {bl[k]}{unit}」가 basis 에 없다"
                unknown = [k for k in ("extended", "max") if bl.get(k)]
                assert not unknown, f"{it['key']}: 일 단위 {unknown} 대조 규칙이 없다 — 규칙을 코드로 적어라"
        elif bl["type"] == "tenure_table":
            _check_tenure_table(it, basis)
        elif bl["type"] == "rate":
            assert f"{round(bl['value'] * 100)}% 이상" in basis, f"{it['key']}: 「{round(bl['value'] * 100)}% 이상」이 basis 에 없다"
        elif bl["type"] in ("formula", "set"):
            assert _ints(str(bl.get("value", ""))) <= _basis_ints(basis), f"{it['key']}: value 의 숫자 {sorted(_ints(str(bl['value'])) - _basis_ints(basis))} 가 basis 에 없다"
        # paid ↔ pay 낱말
        if it["paid"] == "mixed":
            assert "회사" in pay and ("무급" in pay or "고용보험" in pay), f"{it['key']}: mixed 인데 pay 글자에 회사 + 무급/고용보험이 없다"
        else:
            assert all(w in pay for w in _PAID_WORDS[it["paid"]]), f"{it['key']}: paid={it['paid']} 인데 pay 글자에 {_PAID_WORDS[it['paid']]} 이 없다"
        pay_nums = _ints(pay)
        for k in ("employer_paid_days", "employer_paid_days_multi"):
            if it.get(k):
                assert it[k] in pay_nums, f"{it['key']}: {k}={it[k]} 가 pay 글자에 없다"
        nc = it.get("next_change") or {}
        if nc.get("employer_paid_days"):
            from generator.pages.home import _korean_date  # C편 페이지가 쓰는 사이트 날짜 포매터
            assert nc["employer_paid_days"] in pay_nums and _korean_date(nc["from"]) in pay, f"{it['key']}: next_change 가 pay 글자에 없다"


def test_next_change_has_not_taken_effect_yet():
    """날짜 장치 — 이미 정해진 변경의 시행일이 지났으면 표의 값을 바꾸고 next_change 를 지워야 한다.
    ⚠ 빌드 HTML 은 날짜를 읽지 않는다(결정적) — 날짜는 이 테스트만 읽는다. 서버 시각대는 UTC 라 한국 날짜(Asia/Seoul)로 잰다 —
    시행일 당일 한국 시각 09:00 이전에 뒤늦게 실패하지 않게."""
    from zoneinfo import ZoneInfo
    today = datetime.datetime.now(ZoneInfo("Asia/Seoul")).date()
    after = {
        "infertility_leave": "legal_baseline.json 값을 바꾸고 next_change 를 지운 뒤, 난임이면 데이터 「(법정 유급 2일에 N일 추가)」 6행 · 수집 계약 · LG디스플레이 행도 고칠 것(리드 판정 (94) D2)",
        "annual_leave": "legal_baseline.json 값을 확인하고 next_change 를 지운 뒤, row_marks.json `_한계` 의 「시간 단위 · 반반차 연차 = 복지」 판단(사용자 결정 2026-09-20)을 다시 볼 것 — 시행령 확인",
    }
    for it in legal.items():
        nc = it.get("next_change")
        if nc:
            assert datetime.date.fromisoformat(nc["from"]) > today, (
                f"법정 기준선 `{it['key']}` 의 이미 정해진 변경({nc['from']}, {nc['law_no']})이 시행됐다 — "
                + after.get(it["key"], "legal_baseline.json 값을 확인하고 next_change 를 지운 뒤 관련 데이터를 확인할 것"))


def test_c_article_additions_to_the_table():
    assert legal.by_key("spouse_birth_leave")["prev"] == {"value": 10, "until": "2025-02-22", "law_no": "법률 제20521호"}
    assert legal.by_key("infertility_leave")["next_change"]["employer_paid_days"] == 4
    assert legal.by_key("annual_leave")["next_change"]["from"] == "2027-06-10"
    assert legal.by_key("maternity_leave")["employer_paid_days"] == 60 and legal.by_key("maternity_leave")["employer_paid_days_multi"] == 75
    for k in ("infertility_leave", "family_care_leave", "family_care_absence"):
        assert legal.by_key(k)["baseline"]["unit"] == "일/년"
    assert legal.by_key("parental_work_reduction")["paid_note"].startswith("줄인 시간만큼 임금이 줄고")
    assert legal.by_key("labor_day")["small_note"].startswith("고용노동부 해석")
    assert "계산기 연결 전" in legal.raw()["_용도"]["convert"]
