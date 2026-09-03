"""generator/pages/company.py — 회사 상세 페이지 본문·SEO 렌더 (SP-GEN-5·6).

FR-52(기업정보·근무형태)·FR-53(복지표)·FR-54(배지·출처·만료·면책)·FR-57(CTA)·
FR-55(SEO head·JSON-LD). 등록 회사는 실복지 ≥1(INV-6) — 프리셋 폴백 없음.
"""
from __future__ import annotations

import re

from generator import charts, corpus as corpus_mod
from generator.config import CFG
from generator.content.policy import POLICY_FOOTER_LINKS
from generator.context import Page
from generator.employ import company_metrics
from generator.finance import DART_VIEWER
from generator.finance import company_view as finance_view
from generator.format import badge_state, iso_date, krw_manwon
from generator.radar import radar_svg
from generator.slug import combo_slug

# 관련 회사 링크 개수 상한 (FR-63 확장, 2026-07-19 고아 페이지 해소).
RELATED_COMPANY_MAX = 6

# 9카테고리 정본 순서·라벨 (D1.7). 복지표·조합 대조가 공통 소비한다.
CATEGORY_ORDER = [
    "compensation",
    "flexibility",
    "work_env",
    "time_off",
    "health",
    "family",
    "growth",
    "leisure",
    "perks",
]
CATEGORY_LABEL = {
    "compensation": "보상",
    "flexibility": "유연성",
    "work_env": "근무환경",
    "time_off": "휴가",
    "health": "건강",
    "family": "가족",
    "growth": "성장",
    "leisure": "여가",
    "perks": "복리후생",
}

_ALLOWED_URL_SCHEMES = ("http://", "https://")


def _safe_http(url):
    """출처 URL 스킴 제한 (FR-54 R3, NFR21) — http/https만 링크 허용."""
    if not url:
        return None
    return url if url.startswith(_ALLOWED_URL_SCHEMES) else None


def _truncate(text: str, max_len: int) -> str:
    """meta description 절단 — 상한 초과 시 자연스러운 말줄임(회사명은 앞부분 보존)."""
    if len(text) <= max_len:
        return text
    return text[: max_len - 1].rstrip() + "…"


def benefit_anchor(cd, name: str = "") -> str:
    """복지 한 건의 페이지 내 주소 `b-{코드}` (SP-GEN-5.4).

    **이 함수가 앵커 규칙의 유일한 자리다.** 회사 페이지(원장 행 id·카드 행 링크)와 히트맵 타일
    링크가 같은 문자열을 만들어야 타일에서 그 행으로 정확히 떨어진다 — 규칙이 두 곳에 있으면
    언젠가 한쪽만 고쳐지고, 그때 링크는 에러 없이 **페이지 맨 위**로 간다.

    `BENEFIT_CD` 는 NOT NULL 이고 회사 안에서 UNIQUE(`uq_comp_benefit`)라 그대로 쓰면 충돌이 없다.
    """
    return "b-" + (re.sub(r"[^a-z0-9_-]+", "-", str(cd or name).strip().lower()).strip("-") or "b")


def _anchor(cd, name: str, seen: set) -> str:
    """`benefit_anchor` + 한 페이지 안의 중복 방지. 코드가 없는 구(舊) 데이터끼리 이름이 겹치면
    번호를 붙인다 — 같은 id 가 둘이면 앵커가 조용히 첫 행으로만 간다(에러 없이 틀린 동작)."""
    base = benefit_anchor(cd, name)
    key = base
    n = 2
    while key in seen:
        key, n = f"{base}-{n}", n + 1
    seen.add(key)
    return key


def _amount_kind(b: dict) -> str:
    """금액 신뢰도 축(`AMT_SOURCE_CD`) — 배지(출처 계보)와 **독립**이다(DEC-2, SP-DB-5).

    ⚠ 배지가 '공식'이어도 금액은 추정치일 수 있다(SK텔레콤 실측: 금액 11건 중 8건이 추정).
    화면이 이 둘을 한 축으로 합치면 추정 상수가 회사 공식 수치인 것처럼 읽힌다.
    """
    if b.get("qual_yn") or b.get("benefit_amt") is None:
        return "none"
    return "stated" if b.get("amt_source") == "stated" else "estimated"


# 금액 신뢰도 → 원장 한 줄. 밴드 계수는 정책 D-4(비교 리포트가 금액에 두는 불확실성 폭)와 같은 값이다.
AMOUNT_SOURCE_TEXT = {
    "stated": "회사 공식 수치 · 밴드 ±5%",
    "estimated": "추정치 · 밴드 ±20%",
    "none": "금액 환산 없음",
}
# 출처 상태 → 재직자에게 던지는 **사실 질문**(q) + 행동(a). 모르는 값일수록 물음이 커진다(SC14 유입구).
#
# 🚨 질문은 **본문 텍스트**이고 행동만 링크다. `/edit` 은 M9(로그인 기능) 게이트 뒤이고 prod·beta 가
#    같은 산출물을 서빙하므로(authnav.js 머리말), 링크는 `data-authnav-edit hidden` 슬롯으로 내보내
#    `authnav.js` 의 `/members/me` 프로브가 켜진 호스트에서만 드러낸다. 텍스트를 링크 안에 넣으면
#    M9 가 꺼진 곳에서 그 문장까지 사라진다 — 본문은 JS 와 무관해야 한다(NFR24).
EDIT_ASK = {
    "stale": ("아직 유효한가요?", "재직 인증 후 재확인"),
    "none": ("연간 환산 금액을 아시나요?", "재직 인증 후 추가"),
    "estimated": ("실제 금액을 아세요?", "재직 인증 후 수정"),
    "stated": ("", "수정"),
}
# 카드 금액의 색 구간(만원). 색은 **구간**이지 등급이 아니다 — 문구도 구간으로만 적는다(DEC-B).
AMOUNT_TIERS = ((300, "hi"), (100, "mid"))


def _amount_tier(amt) -> str:
    if amt is None:
        return ""
    for floor, tier in AMOUNT_TIERS:
        if amt >= floor:
            return tier
    return "lo"


def _group_benefits(benefits: list[dict], now, comp_id: int | None = None) -> list[tuple[str, str, list[dict]]]:
    """9카테고리 그룹·정렬·정성/금액·출처 스킴 (FR-53·54).

    비지 않은 카테고리만 `(key, label, items)`로 반환한다. 알 수 없는
    카테고리 코드도 방어적으로 수용(버킷 없으면 무시하지 않고 별도 보관은
    하지 않는다 — 9종 정본 외 카테고리는 CATEGORY_ORDER에 없으므로 UI에
    노출되지 않는다. 데이터 정합은 SP-SEED 소유).

    `comp_id` 를 주면 항목마다 **편집 진입 링크**(`/edit?comp=&benefit=`)를 얹는다. 조합 페이지는
    남의 회사 복지를 나란히 보여 주는 자리라 주지 않는다 — 그 화면에서 '수정'은 누구의 것인지
    모호해진다.
    """
    buckets: dict[str, list[dict]] = {k: [] for k in CATEGORY_ORDER}
    seen: set = set()
    for b in benefits:
        kind = _amount_kind(b)
        badge = badge_state(b, now)
        anchor = _anchor(b.get("benefit_cd"), b["benefit_nm"], seen)
        item = {
            "name": b["benefit_nm"],
            "amount": krw_manwon(b["benefit_amt"]) if not b["qual_yn"] else "",
            "amt": None if b["qual_yn"] else b.get("benefit_amt"),
            "qual": b["qual_yn"],
            "qual_desc": b.get("qual_desc_ctnt"),
            "note": b.get("note_ctnt"),
            "badge": badge,
            "src_cd": b.get("badge_src_cd"),
            "src_url": _safe_http(b.get("badge_src_url_ctnt")),
            "verified": iso_date(b.get("verified_dtm")),
            "expires": iso_date(b.get("expires_dtm")),
            "sort": b.get("sort_order_no") or 0,
            # ── 스탯 카드·원장(SP-GEN-5.4) ──
            "anchor": anchor,
            "amt_kind": kind,
            "est": kind == "estimated",
            "tier": _amount_tier(None if b["qual_yn"] else b.get("benefit_amt")),
            "src_text": AMOUNT_SOURCE_TEXT[kind],
            "ask_q": (EDIT_ASK["stale"] if badge["code"] == "stale" else EDIT_ASK[kind])[0],
            "ask_a": (EDIT_ASK["stale"] if badge["code"] == "stale" else EDIT_ASK[kind])[1],
            "edit_href": (
                f"{CFG.edit_path}?comp={comp_id}&benefit={b['benefit_cd']}"
                if comp_id is not None and b.get("benefit_cd") else None
            ),
        }
        cat = b["benefit_ctgr_cd"]
        if cat in buckets:
            buckets[cat].append(item)
    for k in buckets:
        buckets[k].sort(key=lambda x: x["sort"])
    return [(k, CATEGORY_LABEL[k], buckets[k]) for k in CATEGORY_ORDER if buckets[k]]


def _card_view(c: dict, groups, corpus) -> dict:
    """스탯 카드 뷰모델 (SP-GEN-5.4) — 레이더·카테고리 요약·신뢰도 원장·순위.

    **여기서 새 사실을 만들지 않는다.** 카드가 보여 주는 것은 아래 원장과 같은 27행이고, 카드는
    그 목차다(행을 누르면 `#b-{코드}` 로 원장의 같은 항목으로 간다). 텍스트의 집이 두 곳이면
    같은 설명이 두 번 실리거나 한쪽만 갱신된다.

    비교 기준(평균·축 최댓값·순위)은 `corpus` 하나가 소유한다 — 회사마다 다시 계산하면 페이지마다
    다른 기준이 섞일 수 있다.
    """
    used = {k for k, _, _ in groups}
    cats = []
    for key, label, items in groups:
        stated = sum(i["amt"] for i in items if i["amt"] and i["amt_kind"] == "stated")
        est = sum(i["amt"] for i in items if i["amt"] and i["amt_kind"] == "estimated")
        cats.append({
            "key": key, "label": label, "rows": items, "count": len(items),
            "amount": stated + est, "amount_text": krw_manwon(stated + est) if stated + est else "",
            "stated": stated, "est": est,
        })
    flat = [i for _, _, items in groups for i in items]
    counts = {
        "total": len(flat),
        "amount": sum(1 for i in flat if i["amt_kind"] != "none"),
        "stated": sum(1 for i in flat if i["amt_kind"] == "stated"),
        "est": sum(1 for i in flat if i["amt_kind"] == "estimated"),
        "qual": sum(1 for i in flat if i["amt_kind"] == "none"),
        # 배지 계보 두 종(재직자 등록·공식·재직자 수정)을 한 줄로 센다 — 화면이 묻는 것은
        # "사람 손이 닿았는가"이고, 어느 쪽인지는 행의 배지가 말한다.
        "edited": sum(1 for i in flat if i["badge"]["code"] in ("member", "edited")),
        "expired": sum(1 for i in flat if i["badge"]["code"] == "stale"),
        "categories": len(used),
        "category_total": len(CATEGORY_ORDER),
    }
    # 레이더: 카테고리 정본 순서로 항목 수 / 등록 회사 평균. 빈 카테고리는 0 이다(빼지 않는다 —
    # 없는 축은 "모른다"가 아니라 "없다"이고, 그 사실이 모양의 절반을 만든다).
    per_cat = {k: 0 for k in CATEGORY_ORDER}
    for key, _, items in groups:
        per_cat[key] = len(items)
    counts_list = [per_cat[k] for k in CATEGORY_ORDER]
    avgs = [round(corpus.avgs.get(k, 0.0), 2) for k in CATEGORY_ORDER]
    labels = [CATEGORY_LABEL[k] for k in CATEGORY_ORDER]
    # 평균 대비 배율 상위 3 — "많은 카테고리"가 아니라 **배율이 큰 순서**다. 9개가 전부 평균
    # 이상인 회사도 있어(SK텔레콤 실측) 제목이 곧 거짓이 되기 때문이다.
    ratios = [(labels[i], counts_list[i], avgs[i], (counts_list[i] / avgs[i]) if avgs[i] else 0.0)
              for i in range(len(CATEGORY_ORDER)) if counts_list[i]]
    ratios.sort(key=lambda t: -t[3])
    above = [t for t in ratios if t[3] > 1]
    return {
        "radar": radar_svg(counts_list, avgs, labels, corpus.rmax, c["comp_nm"]),
        "categories": cats,
        "counts": counts,
        "rank": corpus.rank_of(c["comp_id"]),
        "amount_text": krw_manwon(corpus.amounts.get(c["comp_id"], 0)),
        "top_ratio": [{"label": lb, "count": n, "avg": f"{a:.1f}"} for lb, n, a, _ in ratios[:3]],
        "above_all": len(above) == len(ratios) and len(ratios) == len(CATEGORY_ORDER),
        "above_count": len(above),
    }


def _company_view(c: dict, ctx, now, corpus) -> dict:
    """뷰모델 파생 — 기업정보·유형지표·근무형태·복지·CTA (SP-GEN-5.2)."""
    t = ctx.types_by_cd.get(c["comp_tp_cd"], {})
    groups = _group_benefits(c["benefits"], now, comp_id=c["comp_id"])
    ws = c.get("work_style_val") or {}
    return {
        "card": _card_view(c, groups, corpus),
        "comp_nm": c["comp_nm"],
        "industry_nm": c.get("industry_nm"),
        "comp_tp_nm": t.get("comp_tp_nm"),
        "work_style": [
            (k, ws[k])
            for k in ("remote", "flex", "unlimitedPTO", "refreshLeave", "overtime")
            if ws.get(k)
        ],
        "benefit_groups": groups,
        "compare_href": f"{CFG.compare_path}?a={c['comp_eng_nm']}",
        "finance": _finance_view(c, ctx),
        "metrics": _metrics_view(c, ctx),
    }


def _finance_view(c: dict, ctx) -> dict | None:
    """실적 섹션 뷰모델(SP-FIN-5). 재무가 빌드에 안 실렸으면 None(섹션 없음 = 기존 페이지 그대로).
    실렸으면 이 회사 몫(없을 수도 있다)을 형제 페이지 이름과 함께 뷰로 만든다 — CJ ENM 두 부문은
    같은 법인이라 같은 수치를 받고 그 사실을 한 줄로 말한다(함정 (69))."""
    if not ctx.finance_loaded:
        return None
    fin = ctx.finance.get(c["comp_id"])
    siblings = [ctx.by_id[s]["comp_nm"] for s in (fin or {}).get("siblings", ()) if s in ctx.by_id]
    return finance_view(fin, c["comp_nm"], siblings)


def _metric_fmt(card: dict):
    """카드 → 표시 포맷 함수(천단위 쉼표 + 자릿수). 하이픈은 진짜 마이너스(−)로 바꾼다.

    자릿수를 **단위 문자열이 아니라 카드에서** 받는 이유: 같은 `억원` 이라도 최솟값이 1억 미만이면
    소수 1자리다(`employ._money_scale`). 정수로 자르면 소액 적자가 `0` 이 되어 부호를 잃는다.

    `charts` 는 눈금 라벨에 **float** 를 넘긴다(`line_svg` 가 `float(v)` 로 정규화한 값). 그래서
    `{:,}` 가 아니라 `{:,.Nf}` 여야 억원 카드에 `3,300,000.0` 같은 표기가 새지 않는다.
    마이너스 기호를 살리는 이유는 부호를 **색으로만** 말하지 않기 위해서다 — 색각 이상에서
    빨강·초록이 같아 보이면 남는 단서는 기준선 위아래와 이 기호뿐이다(SP-MET-9,
    `charts._label` 이 같은 치환을 한다).
    """
    decimals = card["decimals"]
    return lambda v: f"{v:,.{decimals}f}".replace("-", "−")


def _metrics_view(c: dict, ctx) -> dict | None:
    """'실적 · 직원' 카드 6장 섹션 뷰모델 (SP-MET-10). 그릴 것이 없으면 None(섹션 자체가 없다).

    **카드의 데이터는 만들지 않는다.** 그건 `employ.company_metrics` 하나가 만든다(MetricsView) —
    금융 세트의 세 번째 지표가 표와 카드에서 갈라지지 않게 하는 유일한 자리다(SP-MET-2). 여기서
    얹는 것은 페이지 레이어의 **표현**뿐이다: 큰 숫자(`latest_text`)·SVG 두 벌(`bar`·`line`)·
    출처 링크(`rcept_url`).

    포맷 함수를 카드마다 **하나만** 만들어 큰 숫자와 그래프 라벨에 같이 넘긴다. 두 곳에서 따로
    포맷하면 카드는 `15,706` 인데 그래프는 `15706.0` 이 되는 식으로 조용히 갈라진다 — 판정·표기가
    두 곳에 있으면 언젠가 한쪽만 고쳐진다(배지 함정, 2026-07-31).

    재무·직원 **둘 다** 미적재인 빌드는 섹션이 아예 없다(재무 섹션과 같은 경계). 수집 전 릴리스가
    102개사 전부에 "값 없음"을 찍으면 그게 거짓이기 때문이다.
    """
    if not (ctx.finance_loaded or ctx.employ_loaded):
        return None
    view = company_metrics(ctx.finance.get(c["comp_id"]), ctx.employ.get(c["comp_id"]), c["comp_nm"])
    if view is None:
        return None
    for card in view["cards"]:
        if card["empty_text"]:
            # 값이 하나도 없는 카드에는 그래프를 만들지 않는다. `charts` 도 이 경우 빈 문자열을
            # 돌려주지만, 여기서 미리 갈라 두어야 템플릿이 "빈 SVG" 라는 세 번째 상태를 안 만든다.
            card["latest_text"], card["bar"], card["line"] = "", "", ""
            continue
        fmt = _metric_fmt(card)
        uid = "m" + card["key"]  # clipPath id 접두사 — 카드 6장이 겹치면 남의 클립에 면적이 잘린다
        card["latest_text"] = fmt(card["latest"])
        card["bar"] = charts.bar_svg(card["values"], view["years"], fmt, uid)
        card["line"] = charts.line_svg(card["values"], view["years"], fmt, uid)
    # 접수번호는 `company_metrics` 가 이미 숫자인지 검증했다(아니면 None). 링크 조립만 여기서 한다 —
    # 뷰어 URL 은 `finance.DART_VIEWER` 한 곳에 있어야 표와 카드가 다른 곳을 가리키지 않는다.
    view["rcept_url"] = DART_VIEWER + view["rcept_no"] if view["rcept_no"] else None
    return view


def _industry_tokens(industry_nm) -> set[str]:
    """업종 문자열 → 토큰 집합(casefold 정규화). `INDUSTRY_NM`이 자유 텍스트라
    완전일치만으로는 '전자/반도체'와 '반도체', 'IT/포털'과 'it/플랫폼'이 서로
    남남이 된다. 구분자로 쪼개고 대소문자를 접어 비교한다.
    실데이터 구분자는 '/' 뿐이며 나머지는 예방적 수용이다.
    """
    return {
        t.strip().casefold()
        for t in re.split(r"[/·,&]", industry_nm or "")
        if t.strip()
    }


def _industry_related(tokens: set[str], other: set[str]) -> bool:
    """업종군 일치 판정 — 토큰 완전일치 또는 한쪽이 다른 쪽의 접두.

    접두까지 보는 이유: '반도체장비'(6개사)·'반도체소재'(2)가 '반도체'(3)와
    완전일치로는 영영 안 붙어 업종 이웃 0인 회사가 22개 남았다.
    """
    if tokens & other:
        return True
    return any(a.startswith(b) or b.startswith(a) for a in tokens for b in other)


def _related_companies(c: dict, ctx) -> list[tuple[str, str]]:
    """관련 회사 내부 링크 [(회사명, 라우트)] — 고아 페이지 해소(2026-07-19).

    선정 순서: (1) 업종 토큰이 겹치는 회사, (2) 부족분은 **가나다순 인접**(자기
    위치 앞뒤로 번갈아). 폴백이 필수인 이유: 업종이 단독인 회사가 남아 있어
    업종 매칭만으로는 일부가 링크 0건으로 남는다. 가나다순 인접은 전 회사를
    하나의 링크 체인으로 이어 크롤러가 어디서 시작하든 전량 도달하게 한다.
    정렬·순회가 결정적이라 같은 번들이면 빌드마다 동일 결과다.
    """
    eng = c["comp_eng_nm"]
    ordered = sorted(ctx.companies, key=lambda x: (x["comp_nm"], x["comp_eng_nm"]))
    idx = next(i for i, x in enumerate(ordered) if x["comp_eng_nm"] == eng)
    n = len(ordered)

    # (1) 체인 슬롯 선예약 — 가나다순 앞·뒤 이웃을 **항상** 방출한다(링 구조).
    # 예약이 필수인 이유: 업종 매칭만으로 상한을 채우면 폴백이 실행되지 않아
    # 큰 업종군(게임 8사 등)이 폐쇄 싱크가 되고, 그 안으로 들어온 크롤러가
    # 나머지 전부를 못 본다. 양쪽 이웃을 고정하면 전 회사가 하나의 양방향 링으로
    # 이어져 도달성이 데이터가 아니라 구조로 보장된다(GC-26 회귀 검증).
    chain = []
    for j in ((idx + 1) % n, (idx - 1) % n):
        x = ordered[j]
        if x["comp_eng_nm"] != eng and x not in chain:
            chain.append(x)

    # (2) 남는 슬롯을 업종군으로 채운다(표시 순서는 업종 먼저 — 관련성 우선).
    chain_engs = {x["comp_eng_nm"] for x in chain}
    seen = {eng} | chain_engs
    industry: list[dict] = []
    tokens = _industry_tokens(c.get("industry_nm"))
    if tokens:
        for x in ordered:
            if len(industry) >= RELATED_COMPANY_MAX - len(chain):
                break
            if x["comp_eng_nm"] not in seen and _industry_related(
                tokens, _industry_tokens(x.get("industry_nm"))
            ):
                industry.append(x)
                seen.add(x["comp_eng_nm"])

    picked = industry + chain
    return [(_related_label(x, picked), f"/company/{ctx.slugs[x['comp_eng_nm']]}") for x in picked]


def _related_label(x: dict, picked: list[dict]) -> str:
    """앵커 텍스트 — 동명이사가 함께 뽑히면 업종을 덧붙여 구분한다(현 시드엔 없음)."""
    if sum(1 for y in picked if y["comp_nm"] == x["comp_nm"]) > 1 and x.get("industry_nm"):
        return f"{x['comp_nm']}({x['industry_nm']})"
    return x["comp_nm"]


def _related_combos(eng: str, ctx, combo_pairs) -> list[tuple[str, str]]:
    """이 회사가 등장하는 조합 페이지 링크 [(라벨, 라우트)].

    `combo_pairs`는 build.py가 검증한 유효 쌍만 넘긴다(미등록·자기쌍 제외) —
    존재하지 않는 /vs/ 경로를 링크하지 않기 위한 계약(GC-20 정합).
    """
    links: list[tuple[str, str]] = []
    rev = {ctx.slugs[e]: e for e in (ctx.by_eng or {})}
    for a, b in combo_pairs or ():
        if eng not in (a, b):
            continue
        path, first, second = combo_slug(a, b, ctx.slugs)
        # 앵커 텍스트를 조합 페이지의 h1·title과 같은 순서(slug 사전식)로 맞춘다 —
        # 역순 라벨은 클릭 후 제목이 뒤바뀐 것처럼 보인다(2026-07-19 검수).
        label = f"{ctx.by_eng[rev[first]]['comp_nm']} vs {ctx.by_eng[rev[second]]['comp_nm']}"
        links.append((label, f"/vs/{path}"))
    return links


def _company_seo(c: dict, ctx, url: str) -> dict:
    """title·description·OG·canonical·JSON-LD 뷰모델 (SP-GEN-6.1)."""
    t = ctx.types_by_cd.get(c["comp_tp_cd"], {})
    title = f"{c['comp_nm']} 복지·연봉·근무조건 | jobcho.wiki"
    parts = [p for p in (t.get("comp_tp_nm"), c.get("industry_nm")) if p]
    top = ", ".join(b["benefit_nm"] for b in c["benefits"][:3])
    desc = (
        f"{c['comp_nm']}({' · '.join(parts)})의 복지·연봉·근무조건 정보. "
        f"{top} 등 복지 {len(c['benefits'])}개 항목을 확인하고 다른 회사와 비교해 보세요."
    )
    desc = _truncate(desc, CFG.desc_max)
    jsonld = {
        "@context": "https://schema.org",
        "@type": "Organization",
        "name": c["comp_nm"],
        "url": url,
        "alternateName": [c["comp_eng_nm"], *c.get("aliases", [])],
        "industry": c.get("industry_nm"),
    }
    jsonld = {k: v for k, v in jsonld.items() if v}
    return {
        "meta_title": title,
        "meta_desc": desc,
        "canonical": url,
        "og": {
            "title": title,
            "description": desc,
            "type": "website",
            "url": url,
            "image": CFG.site_origin + CFG.default_og_image,
        },
        "jsonld": jsonld,
    }


def render_all(env, ctx, combo_pairs=None) -> list[Page]:
    """회사 ~95 전량 렌더 (SP-GEN-5.1). 회사당 정확히 1 페이지, 폴백 없음.

    `combo_pairs`: build.py가 검증한 유효 조합 쌍(선택). 주입 시 각 회사 페이지가
    자신이 등장하는 /vs/ 조합 페이지로 링크한다(고아 해소, FR-63 확장).
    """
    now = ctx.build_now
    tpl = env.get_template("company.html")
    # 비교 기준은 **빌드당 한 번**만 만든다(SP-GEN-5.4). 회사마다 계산하면 O(n²)이고, 더 나쁘게는
    # 페이지마다 다른 평균이 섞일 여지가 생긴다. ⚠ 회사가 하나 늘면 전 회사 페이지의 평균·순위가
    # 함께 움직인다 — 정적 재생성이 전량인 이유가 여기에도 하나 더 있다.
    corpus = corpus_mod.build(ctx.companies, CATEGORY_ORDER)
    pages: list[Page] = []
    for c in ctx.companies:
        eng = c["comp_eng_nm"]
        slug = ctx.slugs[eng]
        url = f"{CFG.site_origin}/company/{slug}"
        vm = _company_view(c, ctx, now, corpus)
        seo = _company_seo(c, ctx, url)
        html = tpl.render(
            **vm,
            **seo,
            related_companies=_related_companies(c, ctx),
            related_combos=_related_combos(eng, ctx, combo_pairs),
            cfg=CFG,
            footer_links=POLICY_FOOTER_LINKS,
            nav_active="/companies",  # 회사정보 탭 소속(test_gnb_tabs)
        )
        pages.append(
            Page(
                path=f"company/{slug}.html",
                url=url,
                html=html,
                title=seo["meta_title"],
                description=seo["meta_desc"],
            )
        )
    return pages
