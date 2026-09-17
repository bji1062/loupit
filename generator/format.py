"""generator/format.py — 표시 포맷·파생 헬퍼 (SP-GEN-4.3).

`krw_manwon`(FR-04)·`badge_state`(FR-54·05, INV-5)·`jsonld_dumps`(NFR21·8)·
`iso_date`·`work_style_label`. Jinja 필터로 등록된다(`render.py::make_env`).
"""
from __future__ import annotations

import json
import re
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


# ── 복지 설명 표기 정리 (SP-GEN-4.4, A안 3단계 2026-09-16) ───────────────────
#
# **저장하지 않는다.** 정본은 시드 SQL 원문이고 여기서 만드는 문장은 빌드마다 파생된다 —
# 원문이 바뀌면 다음 빌드에 새 문장이 나오므로 둘이 갈라질 수가 없다(갱신 배치 없음).
# 규칙을 끄면 원래 문구로 돌아오고 데이터는 한 글자도 변하지 않는다.

_EST_TAIL = re.compile(r"\s*\(추정\)\s*$")

# 이미 서술어가 있는 문구만 어미를 맞춘다. 서술어가 **없는** 문구에 「제공합니다」를 붙이는 일은
# 하지 않는다 — 그 동사는 회사가 한 말이 아니라 우리가 고르는 말이라, 실제로는 「제휴」인데
# 「제공」이라 쓰면 과장이 된다(2026-09-16 결정).
_PREDICATES = ("지원", "제공", "운영", "지급", "부여", "실시", "보장", "운용", "지향")
# 서술어 앞 부사 — 조사는 그 **앞 명사**에 붙는다(`성과급 별도 지급` → `성과급을 별도 지급합니다`).
_ADVERBS = ("별도", "무료", "무상", "전액", "일부", "추가", "전원", "상시")
# 꼬리가 구두점·괄호면 손대지 않는다. 규칙 기반 한국어 변환은 조용히 틀리므로 건너뛰는 쪽이 안전하다.
_RISKY_TAIL = re.compile(r"[,·/]\s*$|[)\]」』]$")


def _josa_eul_reul(word: str) -> str:
    ch = word[-1]
    if not ("가" <= ch <= "힣"):
        return "를"
    return "를" if (ord(ch) - 0xAC00) % 28 == 0 else "을"


def benefit_desc(text: str | None, amt_source: str | None = None) -> str:
    """복지 설명을 화면에 실을 형태로 정리한다.

    1. 꼬리 `(추정)` 제거 — **금액 축이 이미 말한다.** 원장의 `추정치 · 밴드 ±20%`, 금액 점선,
       「추정치」 렌즈 통, 비교 리포트 밴드까지 네 곳이다. 본문은 다섯 번째로 같은 말을 한다.
       ⚠ 전수 확인(2026-09-16): `(추정)` 이 든 481행 중 금액이 `stated` 인 행은 **0개**였다.
    2. 서술어로 끝나면 완결문장으로 — 구글이 요구하는 조항이 「완전한 문장이나 구문」이다
       (`answer/81904`). 어미만 맞추고 내용은 더하지 않는다.

    🚨 **`amt_source == "none"` 인데 `(추정)` 이 붙은 행은 통째로 건드리지 않는다.**
       금액이 없으니 「금액이 추정」일 수가 없고, 수집자가 「이 복지가 있다는 것 자체가
       불확실하다」는 뜻으로 적은 것이다(DB손해보험 9행). 배지는 `official` 이라 화면과 어긋나 있는데,
       걷어내면 그 유일한 표시가 사라지고 두면 모순이 남는다 — **원문 재확인이 먼저다.**
    """
    t = (text or "").strip()
    if not t:
        return t
    if amt_source == "none" and "(추정)" in t:
        return t                                   # 보류 — 손대지 않는다
    t = _EST_TAIL.sub("", t).strip()
    if not t:
        return t
    return _to_sentence(t) or t


def _to_sentence(text: str) -> str | None:
    """서술어로 끝나는 명사구 → 완결문장. 만들 수 없으면 `None`(호출자가 원문을 그대로 쓴다)."""
    t = text.rstrip(".")
    for v in _PREDICATES:
        if not (t.endswith(" " + v) or (t.endswith(v) and len(t) > len(v))):
            continue
        head = t[: -len(v)].rstrip()
        if not head:
            return None
        adv = ""
        for a in _ADVERBS:
            if head.endswith(a):
                adv, head = a, head[: -len(a)].rstrip()
                break
        if not head or len(head) < 2 or _RISKY_TAIL.search(head):
            return None
        tail = f"{adv} {v}합니다." if adv else f"{v}합니다."
        return f"{head}{_josa_eul_reul(head)} {tail}"
    return None
