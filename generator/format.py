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


def badge_state(benefit: dict, now: datetime) -> dict:
    """배지 파생 (FR-54·FR-05). **밴드 계수(DEC-2)는 산출하지 않는다**(SP-CALC 소유, INV-5).

    두 축을 **선형 우선순위**로 합친다. 격자(2×3)로 만들면 읽는 사람이 조합을 해석해야 하고,
    배지는 한 눈에 읽히지 않으면 없느니만 못하다.

      1. 만료   — `expires_dtm < now`. **신선도가 최우선**이다. 누가 넣었든 오래된 값은
                  오래된 값이고, 그게 사용자에게 가장 급한 정보다.
      2. 재직자 등록 — 편집 이력에 `create`. 원래 데이터에 없던 항목을 재직자가 더한 것.
      3. 공식·재직자 수정 — 편집 이력에 `update`. 공식 값을 재직자가 고친 것.
      4. 공식   — 편집 이력 없음 = 시드 원본(회사 공식 페이지 기준).
      5. 추정   — 그 외.

    ⚠ 2·3 의 '재직자'는 수사가 아니다 — 복지 편집은 `require_employment` 게이트 뒤라
      **그 회사 재직 인증을 통과한 사람만** 쓸 수 있다(2026-07-31 문구 결정).
    ⓘ `edit_origin` 은 `services/reference.py` 가 편집 이력에서 파생한다(별도 컬럼 없음 —
      원장이 유일한 근거여야 어긋날 수가 없다).
    `now`는 인자로 주입해 결정성을 보장한다.
    """
    exp = benefit.get("expires_dtm")
    if exp and _to_dt(exp) < now:
        return {"code": "stale", "label": "만료·재확인 필요"}
    origin = benefit.get("edit_origin")
    if origin == "member":
        return {"code": "member", "label": "재직자 등록"}
    if origin == "edited":
        return {"code": "edited", "label": "공식·재직자 수정"}
    if benefit.get("badge_cd") == "official":
        return {"code": "official", "label": "공식"}
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
