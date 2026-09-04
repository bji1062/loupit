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


def amount_kind(benefit: dict) -> str:
    """금액 신뢰도 축(`AMT_SOURCE_CD`) → `stated` | `estimated` | `none` (DEC-2, SP-DB-5).

    **배지(출처 계보)와 독립축이다.** 배지가 '공식'이어도 금액은 추정치일 수 있다(SK텔레콤 실측:
    금액 11건 중 8건). 화면이 둘을 한 축으로 합치면 추정 상수가 회사 공식 수치인 것처럼 읽힌다.

    🚨 **판정은 여기 하나뿐이다.** 회사 페이지(카드·원장)와 히트맵이 같은 함수를 부른다 — 판정을
    복사하면 같은 복지가 화면마다 다른 분류를 갖는다(배지 함정, 2026-07-31). 특히 **정성이 아닌데
    금액이 비어 있는 행**(`qual_yn=False`·`benefit_amt=None`)이 갈림길이다: 재직자가 금액을 비운 채
    저장하면 서버가 `amt_source='none'` 으로 만들고(`services/benefit_edit.py`), 그 행은 '추정치'가
    아니라 **금액을 모르는 행**이다.
    """
    if benefit.get("qual_yn") or benefit.get("benefit_amt") is None:
        return "none"
    return "stated" if benefit.get("amt_source") == "stated" else "estimated"


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


# ── 재무 표시(SP-FIN-5, 2026-08-27) ──────────────────────────────────────────
# DART 수치는 원 단위 정수(DECIMAL(24,0))로 저장되고 화면은 억원이다. 여기서 하는 일은 단위
# 환산과 증감률 계산뿐이다 — 등급·전망 같은 해석은 만들지 않는다(DEC-B).


def krw_eok(amt, none: str = "—") -> str:
    """원 → 억원 문자열(천단위 쉼표, 사사오입). `None` → `none`(기본 '—').

    None 을 0 으로 그리면 "매출 0원"이라는 거짓 수치가 된다 — 금융업은 매출 계정 자체가 없다.
    단위(억원)는 표 머리글이 말하므로 여기서는 숫자만 돌려준다.
    """
    if amt is None:
        return none
    amt = int(amt)
    sign = -1 if amt < 0 else 1
    eok = (abs(amt) + 50_000_000) // 100_000_000
    return f"{sign * eok:,}"


def pct_delta(prev, cur) -> str | None:
    """전년 대비 증감률 — `+10.0%` 꼴. 전년·당년 중 하나라도 없거나 전년이 0 이면 None.

    분모는 `abs(prev)` 다: 적자가 커지면 음수, 적자에서 흑자로 돌아서면 양수 — 부호가 방향을
    말한다(순수 산술 `(cur-prev)/prev` 는 적자 기준에서 부호가 뒤집혀 읽는 사람을 속인다).
    """
    if prev is None or cur is None:
        return None
    prev, cur = int(prev), int(cur)
    if prev == 0:
        return None
    d = (cur - prev) / abs(prev) * 100
    if abs(d) < 0.05:  # 소수 첫째 자리에서 0 이 되는 값은 '-0.0%' 가 아니라 '+0.0%'
        d = 0.0
    return f"{d:+.1f}%"
