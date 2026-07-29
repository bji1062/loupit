"""generator/format.py — 표시 포맷·파생 헬퍼 (SP-GEN-4.3).

`krw_manwon`(FR-04)·`badge_state`(FR-54·05, INV-5)·`jsonld_dumps`(NFR21·8)·
`iso_date`·`work_style_label`. Jinja 필터로 등록된다(`render.py::make_env`).
"""
from __future__ import annotations

import json
from datetime import date, datetime


def krw_manwon(amt) -> str:
    """만원 정수 → 한국어 "N억 M,MMM만원"/"N억원"/"M,MMM만원" (FR-04).

    `amt`는 만원(10000원) 단위 정수. None → 빈 문자열(정성 항목·미상).
    """
    if amt is None:
        return ""
    amt = int(amt)
    eok, man = divmod(amt, 10000)
    if eok and man:
        return f"{eok}억 {man:,}만원"
    if eok:
        return f"{eok}억원"
    return f"{man:,}만원"


def _to_dt(v) -> datetime:
    """문자열/`date`/`datetime` → `datetime`(비교 가능한 형태로 정규화)."""
    if isinstance(v, datetime):
        return v
    if isinstance(v, date):
        return datetime(v.year, v.month, v.day)
    # 문자열: ISO 날짜(YYYY-MM-DD) 또는 ISO datetime
    s = str(v)[:10]
    return datetime.strptime(s, "%Y-%m-%d")


# 사람이 공식 페이지에서 직접 확인한 항목만 이 값을 가진다. 그 외(`ai_parse` 등)는
# 출처가 공식이어도 **추출은 기계가 한 것**이라 확인 강도가 다르다.
_SRC_VERIFIED = "scrape_official"


def badge_state(benefit: dict, now: datetime) -> dict:
    """공식 확인/공식 페이지 기반/추정/만료 4파생 배지 (FR-54·FR-05).

    `expires_dtm < now` → stale(최우선). 그다음 `badge_cd=="official"` 안에서
    **출처 확인 강도**로 한 번 더 갈린다.

    왜 갈랐는가(2026-07-29): DEC-2 로 96개 전량을 `official` 로 승격한 결과 화면의
    복지 1,317건 **전부**가 "공식 확인"으로 표시되고 있었다. 그런데 그중 1,246건은
    `badge_src_cd='ai_parse'` — 공식 페이지 텍스트를 자동 파싱한 산출물이고, 독자가
    확인할 출처 링크를 가진 행은 71건뿐이었다(`docs/HANDOFF-2026-07-19.md` §G-3).
    "공식 확인"이라 단언하면서 확인 수단을 주지 않는 상태였다.

    §G-3 이 제시한 "싼 대안"이 이것이다 — 데이터 확충(Track D)과 독립적으로, 문구만
    갈라서 과잉 주장을 즉시 없앤다. 배지 코드가 둘 다 `official*` 인 것은 의도다:
    출처의 권위는 같고(둘 다 회사 공식 페이지) 갈리는 것은 추출 방식뿐이다.

    **밴드 계수(DEC-2)는 산출하지 않는다**(SP-CALC 소유, INV-5).
    `now`는 인자로 주입해 결정성을 보장한다.
    """
    exp = benefit.get("expires_dtm")
    if exp and _to_dt(exp) < now:
        return {"code": "stale", "label": "만료·재확인 필요"}
    if benefit.get("badge_cd") == "official":
        if benefit.get("badge_src_cd") == _SRC_VERIFIED:
            return {"code": "official", "label": "공식 확인"}
        # 출처 방식이 비었거나 자동 파싱이면 확인 강도를 낮춰 말한다. 모름을
        # '확인함'으로 올려 말하는 것이 정확히 §G-3 이 지적한 과잉 주장이다.
        return {"code": "official-derived", "label": "공식 페이지 기반"}
    return {"code": "est", "label": "추정"}


def jsonld_dumps(obj) -> str:
    """`<script>` 삽입에 안전한 JSON 직렬화 (NFR21·NFR8).

    `<`·`>`·`&`를 유니코드 이스케이프해 script breakout·HTML 파싱 오염을
    차단한다. 템플릿에서 `{{ jsonld | jsonld | safe }}`로 사용하는 유일한
    `| safe` 예외 경로.
    """
    s = json.dumps(obj, ensure_ascii=False, separators=(",", ":"))
    return s.replace("<", "\\u003c").replace(">", "\\u003e").replace("&", "\\u0026")


def iso_date(v) -> str:
    """None → "" · 문자열/`date`/`datetime` → `YYYY-MM-DD`(10자)."""
    if v is None:
        return ""
    if isinstance(v, str):
        return v[:10]
    return v.isoformat()[:10]


WS_LABELS = {
    "remote": "재택근무",
    "flex": "유연근무",
    "unlimitedPTO": "무제한 휴가",
    "refreshLeave": "리프레시 휴가",
    "overtime": "야근 있음(고지)",
}


def work_style_label(key: str) -> str:
    """근무형태 키 → 한국어 라벨. 미상 키는 원문 그대로 반환."""
    return WS_LABELS.get(key, key)
