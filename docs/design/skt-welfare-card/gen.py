# -*- coding: utf-8 -*-
"""SK텔레콤 복지 카드 — 다크(Main) / 라이트(Light) 카드 2장 + 상세 원장(Detail / DetailLens) 2장을 같은 데이터로 생성."""
import math, html

OUT = __import__("os").path.dirname(__import__("os").path.abspath(__file__))

CATS = [("compensation","보상"),("flexibility","유연성"),("work_env","근무환경"),
        ("time_off","휴가"),("health","건강"),("family","가족"),
        ("growth","성장"),("leisure","여가"),("perks","복리후생")]
# (표시명, 연간 환산 만원, 금액 출처) — 출처는 라이브 히트맵 카테고리 모드 라벨 기준(stated=회사 공식 수치, est=추정치)
BENEFITS = {
 "compensation":[("사내 공모전 포상",None,None)],
 "flexibility":[("자율 재택근무",None,None),("자율 근무제",None,None),("거점오피스",None,None)],
 "work_env":[("IT 장비 지원",50,"est"),("라운지/휴게공간",None,None)],
 "time_off":[("체력단련 휴가",None,None),("장기근속 휴가/포상",None,None)],
 "health":[("건강검진",100,"est"),("의료비 지원",200,"est"),("심리상담실",None,None),("사내 헬스센터",None,None)],
 "family":[("출산/육아 지원",None,None),("사내 어린이집",None,None),("자녀학자금",300,"est"),("경조사/생일 지원",50,"est")],
 "growth":[("직무교육 프로그램",None,None),("석사과정 지원",None,None),("사내 도서관",None,None)],
 "leisure":[("휴양시설",50,"est"),("소모임 지원",24,"stated")],
 "perks":[("선택적 복리후생비",400,"stated"),("구내식당",432,"est"),("통신비 지원",290,"stated"),
          ("사내 대출/주거지원",None,None),("사내 카페/베이커리",50,"est"),("자사 서비스 할인",None,None)],
}
COUNTS = [len(BENEFITS[c]) for c,_ in CATS]                 # [1,3,2,2,4,4,3,2,6]
AVG    = [0.98,0.83,0.61,1.19,2.66,2.39,1.53,1.73,3.61]      # 등록 113개사 평균 항목 수
RMAX   = 8                                                   # 전체 최댓값(복리후생 8)
TOTAL_N = sum(COUNTS); TOTAL_AMT = sum(a for v in BENEFITS.values() for _,a,_ in v if a)
QUAL_N = sum(1 for v in BENEFITS.values() for _,a,_ in v if a is None)
EST_N  = sum(1 for v in BENEFITS.values() for *_,src in v if src == "est")
assert TOTAL_N == 27 and TOTAL_AMT == 1946 and QUAL_N == 16 and EST_N == 8
RATIO = [(lab, c, a, c/a) for (_,lab), c, a in zip(CATS, COUNTS, AVG)]
assert all(r > 1 for *_, r in RATIO)            # 9개 모두 평균 이상 — 카드 문구의 근거
TOP3 = sorted(RATIO, key=lambda t: -t[3])[:3]

COLS = [["compensation","flexibility","work_env","time_off"],["health","family"],["growth","leisure","perks"]]

PALETTES = {
 "dark": dict(
   canvas="#1d2620", panel="#243029", panel2="#2a352d", head="#151c17",
   line="rgba(255,255,255,0.09)", line2="rgba(255,255,255,0.16)",
   t1="#f4f6f4", t2="#d5dbd6", t3="#9aa39c", t4="#8f998f",
   accent="#8bc34a", accent2="#2f7d43", tint="rgba(139,195,74,0.14)", band="rgba(139,195,74,0.09)",
   hi="#c5ea86", mid="#8bc34a", lo="#f4f6f4", qual="#9aa39c",
   fill="rgba(139,195,74,0.28)", stroke="#8bc34a", avg="#9aa39c", ring="rgba(255,255,255,0.10)", axis="rgba(255,255,255,0.14)",
   pos="#8bc34a", neg="#ff7a90", badge_fg="#c5ea86", badge_bg="rgba(139,195,74,0.16)",
   tab_active="#f4f6f4", tab_bar="#8bc34a", btn_bg="#8bc34a", btn_fg="#15200f",
   logo_bg="#151c17", logo_fg="#c5ea86", pill_bg="rgba(139,195,74,0.12)", pill_fg="#c5ea86",
   nav_fg="#d5dbd6", brand_fg="#f4f6f4",
 ),
 "light": dict(
   canvas="#f6f7f8", panel="#ffffff", panel2="#eef0f2", head="#2f7d43",
   line="#e1e4e8", line2="#cfd4d9",
   t1="#1f2328", t2="#3b3f45", t3="#5f646b", t4="#6b7178",
   accent="#2f7d43", accent2="#8bc34a", tint="#e9f4ec", band="#eef6ef",
   hi="#266336", mid="#2f7d43", lo="#1f2328", qual="#5f646b",
   fill="rgba(47,125,67,0.20)", stroke="#2f7d43", avg="#878c93", ring="#e1e4e8", axis="#cfd4d9",
   pos="#2f7d43", neg="#c02626", badge_fg="#046a4e", badge_bg="#e6f6ee",
   tab_active="#1f2328", tab_bar="#2f7d43", btn_bg="#2f7d43", btn_fg="#ffffff",
   logo_bg="#e9f4ec", logo_fg="#2f7d43", pill_bg="#e9f4ec", pill_fg="#266336",
   nav_fg="#ffffff", brand_fg="#ffffff",
 ),
}

SANS = "'Noto Sans KR','Pretendard',system-ui,-apple-system,'Apple SD Gothic Neo','Malgun Gothic',sans-serif"
SERIF = "'Noto Serif KR',Georgia,'Nanum Myeongjo','Apple SD Gothic Neo',serif"

def esc(s): return html.escape(s, quote=True)

# ── 9각형 레이더 (SVG, 정적) ──────────────────────────────────────────────
def radar(P):
    cx, cy, R = 153, 150, 94
    def pt(i, v):
        a = -math.pi/2 + 2*math.pi*i/9
        r = R * (v / RMAX)
        return (cx + r*math.cos(a), cy + r*math.sin(a))
    def poly(vals):
        return " ".join(f"{x:.1f},{y:.1f}" for x,y in (pt(i,v) for i,v in enumerate(vals)))
    rings = "".join(f'<polygon points="{poly([k]*9)}" fill="none" stroke="{P["ring"]}" stroke-width="1"></polygon>' for k in (2,4,6,8))
    axes = "".join(f'<line x1="{cx}" y1="{cy}" x2="{pt(i,RMAX)[0]:.1f}" y2="{pt(i,RMAX)[1]:.1f}" stroke="{P["axis"]}" stroke-width="1"></line>' for i in range(9))
    labels = ""
    for i,(_,lab) in enumerate(CATS):
        a = -math.pi/2 + 2*math.pi*i/9
        lx, ly = cx + (R+18)*math.cos(a), cy + (R+18)*math.sin(a)
        anchor = "middle" if abs(math.cos(a)) < 0.25 else ("start" if math.cos(a) > 0 else "end")
        dy = 4 if abs(math.sin(a)) < 0.3 else (10 if math.sin(a) > 0 else -1)
        labels += f'<text x="{lx:.1f}" y="{ly+dy:.1f}" text-anchor="{anchor}" font-size="12" font-weight="500" fill="{P["t2"]}">{esc(lab)}</text>'
    dots = "".join(f'<circle cx="{pt(i,v)[0]:.1f}" cy="{pt(i,v)[1]:.1f}" r="3.5" fill="{P["stroke"]}" stroke="{P["panel"]}" stroke-width="2"></circle>' for i,v in enumerate(COUNTS))
    return (f'<svg width="306" height="300" viewBox="0 0 306 300" role="img" aria-label="카테고리별 복지 항목 수 9각형" style="display:block;overflow:visible;font-family:{SANS}">'
            f'{rings}{axes}'
            f'<polygon points="{poly(AVG)}" fill="none" stroke="{P["avg"]}" stroke-width="1.5" stroke-dasharray="4 3"></polygon>'
            f'<polygon points="{poly(COUNTS)}" fill="{P["fill"]}" stroke="{P["stroke"]}" stroke-width="2" stroke-linejoin="round"></polygon>'
            f'{dots}{labels}</svg>')

def radar_big(P):
    """로고 없는 좌측 패널용 9각형 — 400 폭, R 130, 눈금 숫자(2·4·6·8) 표기. viewBox 를 라벨 범위로 잘라 여백을 줄인다."""
    cx, cy, R = 200, 200, 130
    def pt(i, v):
        a = -math.pi/2 + 2*math.pi*i/9
        r = R * (v / RMAX)
        return (cx + r*math.cos(a), cy + r*math.sin(a))
    def poly(vals):
        return " ".join(f"{x:.1f},{y:.1f}" for x,y in (pt(i,v) for i,v in enumerate(vals)))
    rings = "".join(f'<polygon points="{poly([k]*9)}" fill="none" stroke="{P["ring"]}" stroke-width="1"></polygon>' for k in (2,4,6,8))
    ticks = "".join(f'<text x="{cx+6}" y="{cy - R*k/RMAX + 4:.1f}" font-size="10" fill="{P["t4"]}">{k}</text>' for k in (2,4,6,8))
    axes = "".join(f'<line x1="{cx}" y1="{cy}" x2="{pt(i,RMAX)[0]:.1f}" y2="{pt(i,RMAX)[1]:.1f}" stroke="{P["axis"]}" stroke-width="1"></line>' for i in range(9))
    labels = ""
    for i,(_,lab) in enumerate(CATS):
        a = -math.pi/2 + 2*math.pi*i/9
        lx, ly = cx + (R+22)*math.cos(a), cy + (R+22)*math.sin(a)
        anchor = "middle" if abs(math.cos(a)) < 0.25 else ("start" if math.cos(a) > 0 else "end")
        dy = 5 if abs(math.sin(a)) < 0.3 else (11 if math.sin(a) > 0 else -1)
        labels += f'<text x="{lx:.1f}" y="{ly+dy:.1f}" text-anchor="{anchor}" font-size="13" font-weight="500" fill="{P["t2"]}">{esc(lab)}</text>'
    dots = "".join(f'<circle cx="{pt(i,v)[0]:.1f}" cy="{pt(i,v)[1]:.1f}" r="4" fill="{P["stroke"]}" stroke="{P["panel"]}" stroke-width="2"></circle>' for i,v in enumerate(COUNTS))
    return (f'<svg width="400" height="330" viewBox="0 34 400 330" role="img" aria-label="카테고리별 복지 항목 수 9각형" style="display:block;overflow:visible;font-family:{SANS}">'
            f'{rings}{axes}{ticks}'
            f'<polygon points="{poly(AVG)}" fill="none" stroke="{P["avg"]}" stroke-width="1.5" stroke-dasharray="4 3"></polygon>'
            f'<polygon points="{poly(COUNTS)}" fill="{P["fill"]}" stroke="{P["stroke"]}" stroke-width="2.5" stroke-linejoin="round"></polygon>'
            f'{dots}{labels}</svg>')

def left_panel(P):
    """좌측 패널 — 로고 타일 없이 9각형을 크게(사용자 결정 2026-09-03), 그 아래 소속 필·지표·요약 상자."""
    return (f'<div style="display:flex;flex-direction:column;background:{P["panel"]};border:1px solid {P["line"]};border-radius:12px;padding:16px 20px 12px 20px">'
            f'<div style="display:flex;justify-content:center">{radar_big(P)}</div>'
            f'<div style="display:flex;justify-content:center;gap:16px;font-size:11px;color:{P["t3"]};margin-top:6px">'
            f'<span style="display:flex;align-items:center;gap:6px"><span style="width:10px;height:10px;border-radius:2px;background:{P["fill"]};border:1.5px solid {P["stroke"]};display:inline-block"></span>SK텔레콤 카테고리별 항목 수</span>'
            f'<span style="display:flex;align-items:center;gap:6px"><span style="width:14px;height:0;border-top:1.5px dashed {P["avg"]};display:inline-block"></span>등록 113개사 평균</span></div>'
            f'<div style="display:flex;justify-content:center;margin:14px 0 6px 0">'
            f'<span style="display:inline-flex;align-items:center;height:28px;padding:0 14px;border-radius:999px;background:{P["pill_bg"]};color:{P["pill_fg"]};font-size:13px;font-weight:600">통신 · 대기업</span></div>'
            f'<div style="display:grid;grid-template-columns:repeat(2, minmax(0, 1fr));column-gap:20px">'
            f'{info(P,"직원수","5,316","명","전년 대비 -3.2%")}{info(P,"평균연봉","16,296","만원","전년 대비 +0.8%")}'
            f'{info(P,"평균근속","13.7","년","전년 대비 +4.7%")}{info(P,"복지 출처","공식 27","항목","확인일 2026-04-15 · 만료 2027-10-15")}</div>'
            f'<span style="font-size:11px;color:{P["t4"]};padding:6px 0 10px 0;border-top:1px solid {P["line"]}">직원수·평균연봉·평균근속 = DART 2025 사업보고서(법인 1벌)</span>'
            f'<div style="display:flex;flex-direction:column;gap:6px;padding:12px 14px;border-radius:8px;background:{P["panel2"]};border:1px solid {P["line"]}">'
            f'<div style="display:flex;justify-content:space-between;font-size:13px"><span style="color:{P["t2"]}">등록 복지 항목</span><span style="font-weight:700;color:{P["t1"]};font-variant-numeric:tabular-nums">27 <span style="font-weight:500;color:{P["t3"]}">· 113개사 중 공동 2번째</span></span></div>'
            f'<div style="display:flex;justify-content:space-between;font-size:13px"><span style="color:{P["t2"]}">금액 합계(연, 추정 포함)</span><span style="font-weight:700;color:{P["t1"]};font-variant-numeric:tabular-nums">1,946만원 <span style="font-weight:500;color:{P["t3"]}">· 11번째</span></span></div>'
            f'</div></div>')

def icon_check(color):
    return (f'<svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="{color}" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" style="flex:none">'
            f'<path d="M3 8.5l3 3 7-7"></path></svg>')
def icon_arrow(color, up):
    d = "M8 13V3M4 7l4-4 4 4" if up else "M8 3v10M4 9l4 4 4-4"
    return (f'<svg width="12" height="12" viewBox="0 0 16 16" fill="none" stroke="{color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="flex:none">'
            f'<path d="{d}"></path></svg>')

# ── 복지 열 ────────────────────────────────────────────────────────────────
def amount_cell(P, amt, src):
    if amt is None:
        return f'<span style="font-size:11px;letter-spacing:0.04em;color:{P["qual"]};font-weight:500">정성</span>'
    if amt >= 300:   col, w = P["hi"], 700
    elif amt >= 100: col, w = P["mid"], 700
    else:            col, w = P["lo"], 500
    est = f'<span style="font-size:10px;color:{P["t3"]};font-weight:500;letter-spacing:0.04em">추정</span>' if src == "est" else ''
    return (f'<span style="display:inline-flex;align-items:baseline;gap:4px">{est}'
            f'<span style="font-size:14px;font-weight:{w};color:{col};font-variant-numeric:tabular-nums">{amt:,}</span></span>')

def category_block(P, code):
    label = dict(CATS)[code]; items = BENEFITS[code]
    sub = sum(a for _,a,_ in items if a)
    sub_txt = f'{sub:,}만원' if sub else '금액 없음'
    head = (f'<div style="display:flex;justify-content:space-between;align-items:baseline;padding:0 8px 6px 8px;border-bottom:1px solid {P["line2"]};margin-bottom:4px">'
            f'<span style="font-size:12px;font-weight:700;letter-spacing:0.02em;color:{P["accent"]}">{esc(label)}</span>'
            f'<span style="font-size:11px;color:{P["t3"]}">{len(items)}항목 · {sub_txt}</span></div>')
    rows = ""
    for nm, amt, src in items:
        bg = P["band"] if amt is not None else "transparent"
        rows += (f'<div style="display:flex;justify-content:space-between;align-items:center;height:30px;padding:0 8px;border-radius:4px;background:{bg}">'
                 f'<span style="font-size:14px;color:{P["t1"]};white-space:nowrap;overflow:hidden;text-overflow:ellipsis">{esc(nm)}</span>'
                 f'{amount_cell(P, amt, src)}</div>')
    return f'<div style="display:flex;flex-direction:column;gap:2px">{head}{rows}</div>'

def column(P, codes):
    return f'<div style="display:flex;flex-direction:column;gap:18px;min-width:0">{"".join(category_block(P,c) for c in codes)}</div>'

# ── 기본 정보 셀 ───────────────────────────────────────────────────────────
def info(P, label, value, unit="", note=""):
    return (f'<div style="display:flex;flex-direction:column;gap:2px;padding:10px 0;border-top:1px solid {P["line"]}">'
            f'<span style="font-size:11px;color:{P["t3"]};letter-spacing:0.02em">{esc(label)}</span>'
            f'<span style="display:flex;align-items:baseline;gap:4px"><span style="font-size:20px;font-weight:700;color:{P["t1"]};font-variant-numeric:tabular-nums;letter-spacing:-0.01em">{esc(value)}</span>'
            f'<span style="font-size:12px;color:{P["t3"]}">{esc(unit)}</span></span>'
            + (f'<span style="font-size:11px;color:{P["t4"]}">{esc(note)}</span>' if note else '') + '</div>')

def fin_cell(P, label, value, yoy, up):
    col = P["pos"] if up else P["neg"]
    return (f'<div style="display:flex;flex-direction:column;gap:6px;padding:16px 20px;flex:1 1 0;min-width:0">'
            f'<span style="font-size:11px;color:{P["t3"]};letter-spacing:0.02em">{esc(label)}</span>'
            f'<span style="display:flex;align-items:baseline;gap:6px"><span style="font-size:24px;font-weight:700;color:{P["t1"]};font-variant-numeric:tabular-nums;letter-spacing:-0.01em">{esc(value)}</span><span style="font-size:12px;color:{P["t3"]}">억원</span></span>'
            f'<span style="display:flex;align-items:center;gap:4px;font-size:12px;color:{col};font-weight:600">{icon_arrow(col, up)}<span>{esc(yoy)}</span><span style="color:{P["t4"]};font-weight:400">전년 대비</span></span></div>')

def chips(P):
    return "".join(
        f'<span style="height:24px;padding:0 10px;border-radius:999px;background:{P["tint"]};color:{P["t1"]};font-size:12px;display:inline-flex;align-items:center;gap:4px">'
        f'<span>{esc(lab)} {c}</span><span style="color:{P["t2"]}">/ {a:.1f}</span></span>'
        for lab, c, a, _ in TOP3)

CARD_H = 1100  # 측정 후 확정

def page(P, mode):
    tabs = [("복지", True), ("실적", False), ("연도별 추이", False), ("비교", False)]
    tab_html = "".join(
        f'<a href="#" style="display:flex;align-items:center;height:40px;padding:0 4px;font-size:14px;font-weight:{700 if act else 500};color:{P["tab_active"] if act else P["t3"]};border-bottom:2px solid {P["tab_bar"] if act else "transparent"};text-decoration:none">{esc(t)}</a>'
        for t, act in tabs)
    nav = "".join(f'<a href="#" style="font-size:14px;color:{P["nav_fg"]};text-decoration:none;font-weight:{700 if t=="회사정보" else 500}">{t}</a>' for t in ("홈","커뮤니티","회사정보","히트맵"))
    body_bg = P["canvas"]

    return f'''<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;600;700&amp;family=Noto+Serif+KR:wght@600&amp;display=swap">
  <style>
    body {{ margin: 0; background: {body_bg}; font-family: {SANS}; color: {P["t1"]}; -webkit-font-smoothing: antialiased; }}
    a {{ color: {P["accent"]}; }} a:hover {{ color: {P["accent2"]}; }}
    * {{ box-sizing: border-box; }}
  </style>
</helmet>
<div style="width:1440px;min-height:{CARD_H}px;background:{body_bg};display:flex;flex-direction:column">

  <!-- GNB -->
  <div style="display:flex;align-items:center;justify-content:space-between;height:52px;padding:0 32px;background:{P["head"]};border-bottom:1px solid {P["line"]}">
    <div style="display:flex;align-items:center;gap:28px">
      <span style="font-family:{SERIF};font-size:20px;font-weight:600;color:{P["brand_fg"]};letter-spacing:-0.01em">jobcho<span style="color:{P["accent"] if mode=="dark" else "#8bc34a"}">.</span>wiki</span>
      <nav style="display:flex;gap:20px">{nav}</nav>
    </div>
    <a href="#" style="font-size:14px;color:{P["nav_fg"]};text-decoration:none;font-weight:500">로그인</a>
  </div>

  <!-- 회사 헤더 + 탭 -->
  <div style="display:flex;flex-direction:column;padding:0 32px;background:{P["panel"]};border-bottom:1px solid {P["line"]}">
    <div style="display:flex;align-items:flex-end;justify-content:space-between;padding:18px 0 10px 0">
      <div style="display:flex;flex-direction:column;gap:4px">
        <h1 style="margin:0;font-family:{SERIF};font-size:30px;font-weight:600;line-height:1.1;letter-spacing:-0.02em;color:{P["t1"]}">SK텔레콤</h1>
        <span style="font-size:13px;color:{P["t3"]}">통신 · 대기업 · 복지 27항목 · 금액 합계 연 1,946만원(추정 포함)</span>
      </div>
      <a href="#" style="display:inline-flex;align-items:center;height:40px;padding:0 20px;border-radius:8px;background:{P["btn_bg"]};color:{P["btn_fg"]};font-size:14px;font-weight:700;text-decoration:none">이 회사로 비교하기</a>
    </div>
    <div style="display:flex;gap:24px">{tab_html}</div>
  </div>

  <!-- 본문 -->
  <div style="display:grid;grid-template-columns:440px minmax(0, 1fr);gap:20px;padding:20px 32px 0 32px;flex:1 1 auto;align-items:start">

    {left_panel(P)}

    <!-- 우: 카테고리별 복지 + 사이드 패널 -->
    <div style="display:grid;grid-template-columns:minmax(0, 1fr) 232px;gap:20px;min-width:0;align-items:start">
      <div style="display:flex;flex-direction:column;background:{P["panel"]};border:1px solid {P["line"]};border-radius:12px;padding:18px 20px 16px 20px;min-width:0">
        <div style="display:flex;flex-direction:column;gap:4px;margin-bottom:14px">
          <h2 style="margin:0;font-family:{SANS};font-size:15px;font-weight:700;color:{P["t1"]};letter-spacing:-0.01em">복지 항목 <span style="font-weight:500;color:{P["t3"]}">— 9개 카테고리</span></h2>
          <span style="font-size:11px;color:{P["t3"]}">숫자 = 연간 환산 금액(만원) · 색 = 금액 구간(300↑ / 100↑ / 그 미만) · 추정 = 추정치(회사 공식 수치 아님) · 정성 = 금액 환산 없음</span>
        </div>
        <div style="display:grid;grid-template-columns:repeat(3, minmax(0, 1fr));gap:24px">
          {column(P, COLS[0])}{column(P, COLS[1])}{column(P, COLS[2])}
        </div>
      </div>

      <div style="display:flex;flex-direction:column;gap:18px;background:{P["panel"]};border:1px solid {P["line"]};border-radius:12px;padding:18px 18px 16px 18px">
        <div style="display:flex;flex-direction:column;gap:8px">
          <span style="font-size:11px;color:{P["t3"]};letter-spacing:0.02em">근무형태</span>
          <div style="display:flex;flex-direction:column;gap:8px">
            <span style="display:flex;align-items:center;gap:8px;font-size:14px;color:{P["t1"]}">{icon_check(P["accent"])}재택근무 제공</span>
            <span style="display:flex;align-items:center;gap:8px;font-size:14px;color:{P["t1"]}">{icon_check(P["accent"])}유연근무 제공</span>
            <span style="display:flex;align-items:center;gap:8px;font-size:14px;color:{P["t1"]}">{icon_check(P["accent"])}리프레시 휴가 제공</span>
          </div>
        </div>
        <div style="height:1px;background:{P["line"]}"></div>
        <div style="display:flex;flex-direction:column;gap:8px">
          <span style="font-size:11px;color:{P["t3"]};letter-spacing:0.02em">항목 구성</span>
          <div style="display:flex;justify-content:space-between;font-size:14px"><span style="color:{P["t2"]}">금액 환산</span><span style="font-weight:700;color:{P["t1"]}">11</span></div>
          <div style="display:flex;justify-content:space-between;font-size:13px;padding-left:12px"><span style="color:{P["t3"]}">회사 공식 수치 / 추정치</span><span style="font-weight:600;color:{P["t2"]}">3 / 8</span></div>
          <div style="display:flex;justify-content:space-between;font-size:14px"><span style="color:{P["t2"]}">정성 항목</span><span style="font-weight:700;color:{P["t1"]}">16</span></div>
          <div style="display:flex;justify-content:space-between;font-size:14px"><span style="color:{P["t2"]}">카테고리</span><span style="font-weight:700;color:{P["t1"]}">9 / 9</span></div>
        </div>
        <div style="height:1px;background:{P["line"]}"></div>
        <div style="display:flex;flex-direction:column;gap:8px">
          <span style="font-size:11px;color:{P["t3"]};letter-spacing:0.02em">출처 계보</span>
          <span style="display:inline-flex;align-self:flex-start;align-items:center;height:22px;padding:0 8px;border-radius:4px;background:{P["badge_bg"]};color:{P["badge_fg"]};font-size:12px;font-weight:700">공식 · 27항목</span>
          <span style="font-size:12px;color:{P["t3"]};line-height:1.5">공식 = 회사 안내 기준 등록 · 재직자 편집 이력 없음<br>확인일 2026-04-15 · 만료 2027-10-15</span>
        </div>
        <div style="height:1px;background:{P["line"]}"></div>
        <div style="display:flex;flex-direction:column;gap:8px">
          <span style="font-size:11px;color:{P["t3"]};letter-spacing:0.02em">평균 대비 배율 상위 3개 카테고리</span>
          <div style="display:flex;flex-wrap:wrap;gap:6px">
            {chips(P)}
          </div>
          <span style="font-size:12px;color:{P["t3"]}">9개 카테고리 모두 113개사 평균 이상 · 항목 수 / 평균</span>
        </div>
      </div>
    </div>
  </div>

  <!-- 하단: 실적 -->
  <div style="display:grid;grid-template-columns:440px minmax(0, 1fr);gap:20px;padding:20px 32px 24px 32px">
    <div style="display:flex;flex-direction:column;justify-content:center;gap:4px;padding:0 4px;font-size:12px;color:{P["t3"]};line-height:1.5">
      <span style="font-size:14px;font-weight:700;color:{P["t1"]}">실적 2025 <span style="font-size:12px;font-weight:500;color:{P["t3"]}">연결 기준</span></span>
      <span>출처 금융감독원 전자공시(DART) 사업보고서 · 공시 수치이며 평가가 아닙니다</span>
    </div>
    <div style="display:flex;background:{P["panel"]};border:1px solid {P["line"]};border-radius:12px;overflow:hidden">
      {fin_cell(P,"매출","170,992","-4.7%",False)}
      <div style="width:1px;background:{P["line"]}"></div>
      {fin_cell(P,"영업이익","10,732","-41.1%",False)}
      <div style="width:1px;background:{P["line"]}"></div>
      {fin_cell(P,"순이익","3,751","-73.0%",False)}
    </div>
  </div>

</div>
</x-dc>
</body>
</html>
'''

for mode, fname in (("dark","Main.dc.html"),("light","Light.dc.html")):
    with open(f"{OUT}/{fname}","w",encoding="utf-8") as f:
        f.write(page(PALETTES[mode], mode))
    print("wrote", fname)

# ── 대비 점검(텍스트 색 vs 패널 배경) ──
def lum(hexs):
    h=hexs.lstrip('#'); r,g,b=(int(h[i:i+2],16)/255 for i in (0,2,4))
    f=lambda c: c/12.92 if c<=0.03928 else ((c+0.055)/1.055)**2.4
    return 0.2126*f(r)+0.7152*f(g)+0.0722*f(b)
def cr(a,b):
    la,lb=lum(a),lum(b); hi,lo=max(la,lb),min(la,lb); return (hi+0.05)/(lo+0.05)
for mode in ("dark","light"):
    P=PALETTES[mode]
    for k in ("t1","t2","t3","t4","hi","mid","lo","qual","accent","neg","pos"):
        print(mode, k, P[k], f"{cr(P[k],P['panel']):.2f}")


# ══════════════════════════════════════════════════════════════════════
# 상세 원장 아트보드 (2026-09-03) — 아이디어 패널 추천 조합의 시연.
#   카드 = 목차(행 = <a href="#b-{cd}">) · 카드 아래 원장(tr:target 밴드) · 추정 점선 + 신뢰도 원장
#   · 출처 렌즈(라디오 :checked ~ 밴드·감쇠, 숨기지 않음) · 상태별 편집 질문(/edit?comp=&benefit=).
#   Main/Light 산출물은 건드리지 않는다(바이트 동일 유지). 다크 팔레트만.
#   state = "all"(기본, target 행이 :target 상태) | "est"(렌즈 '추정치' 선택 상태)
# ══════════════════════════════════════════════════════════════════════
DETAIL = {  # 표시명 → (BENEFIT_CD, 설명/환산 근거). NOTE 끝 '(추정)' 꼬리는 strip — 출처 문장이 대신 말한다.
 "사내 공모전 포상": ("excellence_award", "IDEATHON 우승 시 상금 지급"),
 "자율 재택근무": ("remote_work", "사무실/집/거점오피스 자율 선택"),
 "자율 근무제": ("flex_work", "2주/4주 단위 80h/160h 자율 설정, 10분 단위 조절, 매달 둘째·넷째주 4일 근무"),
 "거점오피스": ("satellite_office", "거점오피스 운영"),
 "IT 장비 지원": ("work_tools", "매년 IT기기 구매비 지원, 3년마다 최신형 노트북(개발자 맥북프로), 허먼밀러 의자"),
 "라운지/휴게공간": ("lounge", "Refresh zone(리클라이너/안마의자/헬스키퍼 상주), The Lounge 31층(바리스타 커피/간식)"),
 "체력단련 휴가": ("refresh_leave", "연차 외 체력단련 휴가 5일, 본인 승인 휴가제"),
 "장기근속 휴가/포상": ("long_service_leave", "5년마다 휴가30일+200만 또는 휴가10일+1000만 선택, 10년/20년 45일 유급 리프레시, 15년 추가 10일"),
 "건강검진": ("health_check", "최고 수준 건강검진 전액 지원"),
 "의료비 지원": ("medical", "본인 100% + 가족(부모/배우자/자녀/배우자부모) 의료비"),
 "심리상담실": ("mental", "심리상담실 상시 운영, 강북삼성병원 24시간 핫라인, 의무실 상시 운영"),
 "사내 헬스센터": ("fitness", "액티움(Actium) 300평, 월1만원, 농구장, KPGA/KLPGA 프로 골프레슨, 스크린골프"),
 "출산/육아 지원": ("parenting", "출산휴가 90일(배우자10일), 육아휴직 남녀2년(2회 분할), 초등입학시 3개월 휴직"),
 "사내 어린이집": ("childcare", "푸르니 재단 행복날개 어린이집 사내 운영"),
 "자녀학자금": ("child_edu", "유치원~대학교 학자금 전액 지원"),
 "경조사/생일 지원": ("event", "결혼/조사 지원, 생일 SK pay 포인트, 부모님 회갑~구순 축하금, 자녀 첫생일 축하금"),
 "직무교육 프로그램": ("edu_support", "Up-skilling Program: AI개발/서비스기획/네트워크/마케팅 등 직무별 전문가 육성"),
 "석사과정 지원": ("mba", "온라인 해외 석사학위(Data Science/Computer Engineering/MBA) 입사 1년차부터 가능"),
 "사내 도서관": ("books", "T타워 18층 무인도서관, 3만권 이상, E-book 이용 가능"),
 "휴양시설": ("resort", "쏠비치 양양, 소노펠리체 비발디파크 등 230개 시설 임직원 할인"),
 "소모임 지원": ("club", "매달 1인 2만원 지원"),
 "선택적 복리후생비": ("welfare_point", "매년 400만 포인트(가족검진40만+귀성비20만 등), 학원/여행/공연 등 사용"),
 "구내식당": ("meal", "The Table 한식/아시안/양식/샐러드, 일 18,000원 × 240일"),
 "통신비 지원": ("telecom", "매달 24만2천원까지 지원 (연 290만)"),
 "사내 대출/주거지원": ("housing_loan", "사내 대출 1억 한도, 주거 안정 자금 지원"),
 "사내 카페/베이커리": ("snack_bar", "Café & Bakery 앱 주문/결제, 장보기포인트 매월 5만원"),
 "자사 서비스 할인": ("discount", "SK나이츠 농구티켓, 해피셰어카(업무용 차량 개인이용)"),
}
assert set(DETAIL) == {nm for v in BENEFITS.values() for nm,_,_ in v}
LENSES = [("all","전체",27),("stated","회사 공식 수치",3),("est","추정치",8),("qual","정성",16),("edited","재직자 등록·수정",0),("expired","만료",0)]
SRC_LINE = {"stated": "회사 공식 수치 · 밴드 ±5%", "est": "추정치 · 밴드 ±20%", None: "금액 환산 없음"}
ASK = {"stated": "수정 →", "est": "실제 금액을 아세요? 재직 인증 후 수정 →", None: "연간 환산 금액을 아시면 재직 인증 후 추가 →"}
LEDGER_COLS = [["compensation","flexibility","work_env","time_off","health"],["family","growth","leisure","perks"]]
PD = dict(PALETTES["dark"], band2="rgba(139,195,74,0.20)")

def _hit(src, state): return state == "est" and src == "est"
def _dim(src, state): return state == "est" and src != "est"

def amount_cell2(P, amt, src):
    """카드 셀 — 추정 숫자에 점선 밑줄(원장·렌즈까지 살아남는 인코딩). '추정' 글자는 유지(범례가 설명)."""
    if amt is None:
        return f'<span style="font-size:11px;letter-spacing:0.04em;color:{P["qual"]};font-weight:500">정성</span>'
    if amt >= 300:   col, w = P["hi"], 700
    elif amt >= 100: col, w = P["mid"], 700
    else:            col, w = P["lo"], 500
    dotted = f'border-bottom:1px dotted {P["t3"]};padding-bottom:1px;' if src == "est" else ''
    est = f'<span style="font-size:10px;color:{P["t3"]};font-weight:500;letter-spacing:0.04em">추정</span>' if src == "est" else ''
    return (f'<span style="display:inline-flex;align-items:baseline;gap:4px">{est}'
            f'<span style="font-size:14px;font-weight:{w};color:{col};font-variant-numeric:tabular-nums;{dotted}">{amt:,}</span></span>')

def row_link(P, nm, amt, src, state, target):
    cd, _ = DETAIL[nm]
    is_target = state == "all" and cd == target
    if is_target:            bg, extra = P["band2"], f'box-shadow:inset 0 0 0 1px {P["accent"]};'
    elif _hit(src, state):   bg, extra = P["band2"], ''
    elif state == "all" and amt is not None: bg, extra = P["band"], ''
    else:                    bg, extra = "transparent", ''
    op = "0.45" if _dim(src, state) else "1"
    default_bg = P["band2"] if _hit(src, state) else (P["band"] if state == "all" and amt is not None else "transparent")
    return (f'<a href="#b-{cd}" data-go="{cd}" data-b="{cd}" data-role="card" data-bg="{default_bg}" data-op="{op}" style="display:flex;justify-content:space-between;align-items:center;height:30px;padding:0 8px;border-radius:4px;background:{bg};{extra}opacity:{op};text-decoration:none">'
            f'<span style="font-size:14px;color:{P["t1"]};white-space:nowrap;overflow:hidden;text-overflow:ellipsis">{esc(nm)}</span>{amount_cell2(P, amt, src)}</a>')

def category_block2(P, code, state, target):
    label = dict(CATS)[code]; items = BENEFITS[code]
    sub = sum(a for _,a,_ in items if a); sub_txt = f'{sub:,}만원' if sub else '금액 없음'
    head = (f'<div style="display:flex;justify-content:space-between;align-items:baseline;padding:0 8px 6px 8px;border-bottom:1px solid {P["line2"]};margin-bottom:4px">'
            f'<a href="#cat-{code}" style="font-size:12px;font-weight:700;letter-spacing:0.02em;color:{P["accent"]};text-decoration:none">{esc(label)}</a>'
            f'<span style="font-size:11px;color:{P["t3"]}">{len(items)}항목 · {sub_txt}</span></div>')
    rows = "".join(row_link(P, nm, amt, src, state, target) for nm, amt, src in items)
    return f'<div style="display:flex;flex-direction:column;gap:2px">{head}{rows}</div>'

def column2(P, codes, state, target):
    return f'<div style="display:flex;flex-direction:column;gap:18px;min-width:0">{"".join(category_block2(P,c,state,target) for c in codes)}</div>'

def lens_chips(P, state):
    out = []
    for key, label, n in LENSES:
        active = key == state
        bg = P["accent"] if active else P["panel2"]; fg = P["btn_fg"] if active else P["t2"]; bd = P["accent"] if active else P["line2"]
        out.append(f'<span role="radio" aria-checked="{"true" if active else "false"}" style="display:inline-flex;align-items:center;gap:6px;height:26px;padding:0 10px;border-radius:999px;background:{bg};color:{fg};border:1px solid {bd};font-size:12px;font-weight:{700 if active else 500}">'
                   f'<span style="width:8px;height:8px;border-radius:50%;background:{fg if active else "transparent"};border:1.5px solid {fg};display:inline-block"></span>{esc(label)} {n}</span>')
    return f'<div role="radiogroup" aria-label="출처 렌즈" style="display:flex;flex-wrap:wrap;gap:6px">{"".join(out)}</div>'

def lens_bar(P, state):
    if state != "est":
        return (f'<div style="display:flex;justify-content:space-between;align-items:center;font-size:12px;color:{P["t3"]}">'
                f'<span>행을 누르면 아래 <a href="#ledger" style="color:{P["accent"]};text-decoration:none">원장</a>의 해당 항목으로 · 설명·환산 근거·출처 전문은 원장에 있습니다</span>'
                f'</div>')
    return (f'<div style="display:flex;justify-content:space-between;align-items:center;gap:12px;padding:8px 12px;border-radius:6px;background:{P["band2"]};font-size:12px;color:{P["t1"]}">'
            f'<span><span style="font-weight:700">추정치 8항목</span> — 비교 리포트 밴드 ±20% · 카드와 원장에서 띠로 표시, 나머지는 흐리게</span>'
            f'<a href="#" style="white-space:nowrap;font-weight:700;color:{P["accent"]};text-decoration:none">실제 금액을 아세요? 재직 인증 후 수정 →</a></div>')

def trust_ledger(P, state):
    def r(label, n, note, key, indent=False):
        hit = state == key
        return (f'<div style="display:flex;justify-content:space-between;align-items:baseline;gap:8px;padding:4px 6px 4px {18 if indent else 6}px;margin:0 -6px;border-radius:4px;background:{P["band2"] if hit else "transparent"}">'
                f'<span style="font-size:{13 if indent else 14}px;color:{P["t3"] if indent else P["t2"]}">{esc(label)}'
                + (f'<span style="font-size:11px;color:{P["t4"]};margin-left:6px">{esc(note)}</span>' if note else '') + '</span>'
                f'<span style="font-size:14px;font-weight:700;color:{P["t1"]};font-variant-numeric:tabular-nums">{n}</span></div>')
    rows = (r("금액 환산", 11, "", "-") + r("회사 공식 수치", 3, "밴드 ±5%", "stated", True) + r("추정치", 8, "밴드 ±20%", "est", True)
            + r("정성 항목", 16, "금액 환산 없음", "qual") + r("재직자 등록·수정", 0, "", "edited") + r("만료·재확인 필요", 0, "밴드 +15%", "expired"))
    return (f'<div style="display:flex;flex-direction:column;gap:6px"><span style="font-size:11px;color:{P["t3"]};letter-spacing:0.02em">신뢰도 원장</span>'
            f'<div style="display:flex;flex-direction:column;gap:2px">{rows}</div>'
            f'<span style="font-size:11px;color:{P["t4"]};line-height:1.5">밴드 = 비교 리포트가 금액에 두는 불확실성 폭. 배지(출처 계보)와 금액 신뢰도는 별개 축.</span></div>')

def ledger_row(P, nm, amt, src, state, target):
    cd, text = DETAIL[nm]
    is_target = state == "all" and cd == target
    bg = P["band2"] if (is_target or _hit(src, state)) else "transparent"
    op = "0.45" if _dim(src, state) else "1"
    if amt is None:
        amt_html = ''
    else:
        col = P["hi"] if amt >= 300 else P["mid"] if amt >= 100 else P["lo"]
        dotted = f'border-bottom:1px dotted {P["t3"]};' if src == "est" else ''
        amt_html = f'<span style="font-size:15px;font-weight:700;color:{col};font-variant-numeric:tabular-nums"><span style="{dotted}">{amt:,}</span><span style="font-size:12px;font-weight:500;color:{P["t3"]}">만원</span></span>'
    hid = '' if is_target else ' hidden="hidden"'
    up = f'<a href="#top" data-top="1" data-up="1"{hid} style="color:{P["t3"]};text-decoration:none">↑ 카드로</a>'
    default_bg = P["band2"] if _hit(src, state) else "transparent"
    return (f'<div id="b-{cd}" data-b="{cd}" data-role="ledger" data-bg="{default_bg}" data-op="{op}" style="display:flex;flex-direction:column;gap:6px;padding:12px 14px;border-top:1px solid {P["line"]};background:{bg};opacity:{op}">'
            f'<div style="display:flex;justify-content:space-between;align-items:baseline;gap:12px">'
            f'<span style="display:flex;align-items:baseline;gap:10px;min-width:0"><span style="font-size:15px;font-weight:700;color:{P["t1"]}">{esc(nm)}</span>{amt_html}'
            f'<span style="font-size:12px;color:{P["t3"]}">{esc(SRC_LINE[src])}</span></span>'
            f'<span style="display:flex;align-items:center;gap:8px;white-space:nowrap"><span style="display:inline-flex;align-items:center;height:20px;padding:0 7px;border-radius:4px;background:{P["badge_bg"]};color:{P["badge_fg"]};font-size:11px;font-weight:700">공식</span>'
            f'<span style="font-size:11px;color:{P["t3"]}">확인일 2026-04-15 · 만료 2027-10-15</span></span></div>'
            f'<p style="margin:0;font-size:13px;line-height:1.55;color:{P["t2"]}">{esc(text)}</p>'
            f'<div style="display:flex;justify-content:space-between;align-items:center;gap:12px;font-size:12px">'
            f'<a href="#" style="color:{P["accent"]};text-decoration:none;font-weight:600">{esc(ASK[src])}</a>'
            f'<span style="display:flex;gap:14px"><a href="#" style="color:{P["t3"]};text-decoration:none">히트맵에서 이 항목 →</a>{up}</span></div></div>')

def ledger_block(P, code, state, target):
    label = dict(CATS)[code]; items = BENEFITS[code]
    st = sum(a for _,a,s in items if a and s == "stated"); es = sum(a for _,a,s in items if a and s == "est")
    tot = st + es
    sub = f'금액 합 {tot:,}만원 = 공식 {st:,} / 추정 {es:,}' if tot else '금액 환산 항목 없음'
    return (f'<div id="cat-{code}" style="display:flex;flex-direction:column;border:1px solid {P["line"]};border-radius:8px;overflow:hidden;background:{P["panel"]}">'
            f'<div style="display:flex;justify-content:space-between;align-items:baseline;padding:10px 14px;background:{P["panel2"]}">'
            f'<span style="font-size:13px;font-weight:700;color:{P["accent"]}">{esc(label)}</span><span style="font-size:11px;color:{P["t3"]}">{len(items)}항목 · {sub}</span></div>'
            + "".join(ledger_row(P, nm, amt, src, state, target) for nm, amt, src in items) + '</div>')

def ledger(P, state, target):
    cols = "".join(f'<div style="display:flex;flex-direction:column;gap:14px;min-width:0">{"".join(ledger_block(P,c,state,target) for c in codes)}</div>' for codes in LEDGER_COLS)
    return (f'<section id="ledger" style="display:flex;flex-direction:column;gap:14px;padding:24px 32px 24px 32px">'
            f'<div style="display:flex;justify-content:space-between;align-items:baseline">'
            f'<div style="display:flex;flex-direction:column;gap:4px"><h2 style="margin:0;font-family:{SANS};font-size:18px;font-weight:700;color:{P["t1"]};letter-spacing:-0.01em">복지 상세 — 원장</h2>'
            f'<span style="font-size:12px;color:{P["t3"]}">카드의 숫자 뒤에 있는 설명·환산 근거·출처 전문. 27항목 · 회사 공식 수치 3 / 추정치 8 / 정성 16</span></div>'
            f'<a href="#top" data-top="1" style="font-size:12px;color:{P["t3"]};text-decoration:none">↑ 카드로</a></div>'
            f'<div style="display:grid;grid-template-columns:repeat(2, minmax(0, 1fr));gap:20px;align-items:start">{cols}</div></section>')

def detail_page(P, state, target="meal", min_h=0):
    tabs = [("복지", True), ("실적", False), ("연도별 추이", False), ("비교", False)]
    tab_html = "".join(
        f'<a href="#" style="display:flex;align-items:center;height:40px;padding:0 4px;font-size:14px;font-weight:{700 if act else 500};color:{P["tab_active"] if act else P["t3"]};border-bottom:2px solid {P["tab_bar"] if act else "transparent"};text-decoration:none">{esc(t)}</a>'
        for t, act in tabs)
    nav = "".join(f'<a href="#" style="font-size:14px;color:{P["nav_fg"]};text-decoration:none;font-weight:{700 if t=="회사정보" else 500}">{t}</a>' for t in ("홈","커뮤니티","회사정보","히트맵"))
    body_bg = P["canvas"]
    return f'''<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;600;700&amp;family=Noto+Serif+KR:wght@600&amp;display=swap">
  <style>
    body {{ margin: 0; background: {body_bg}; font-family: {SANS}; color: {P["t1"]}; -webkit-font-smoothing: antialiased; }}
    a {{ color: {P["accent"]}; }} a:hover {{ color: {P["accent2"]}; }}
    * {{ box-sizing: border-box; }}
  </style>
</helmet>
<div id="top" style="width:1440px;min-height:{min_h}px;background:{body_bg};display:flex;flex-direction:column">

  <div style="display:flex;align-items:center;justify-content:space-between;height:52px;padding:0 32px;background:{P["head"]};border-bottom:1px solid {P["line"]}">
    <div style="display:flex;align-items:center;gap:28px">
      <span style="font-family:{SERIF};font-size:20px;font-weight:600;color:{P["brand_fg"]};letter-spacing:-0.01em">jobcho<span style="color:{P["accent"]}">.</span>wiki</span>
      <nav style="display:flex;gap:20px">{nav}</nav>
    </div>
    <a href="#" style="font-size:14px;color:{P["nav_fg"]};text-decoration:none;font-weight:500">로그인</a>
  </div>

  <div style="display:flex;flex-direction:column;padding:0 32px;background:{P["panel"]};border-bottom:1px solid {P["line"]}">
    <div style="display:flex;align-items:flex-end;justify-content:space-between;padding:18px 0 10px 0">
      <div style="display:flex;flex-direction:column;gap:4px">
        <h1 style="margin:0;font-family:{SERIF};font-size:30px;font-weight:600;line-height:1.1;letter-spacing:-0.02em;color:{P["t1"]}">SK텔레콤</h1>
        <span style="font-size:13px;color:{P["t3"]}">통신 · 대기업 · 복지 27항목 · 금액 합계 연 1,946만원(추정 포함)</span>
      </div>
      <a href="#" style="display:inline-flex;align-items:center;height:40px;padding:0 20px;border-radius:8px;background:{P["btn_bg"]};color:{P["btn_fg"]};font-size:14px;font-weight:700;text-decoration:none">이 회사로 비교하기</a>
    </div>
    <div style="display:flex;gap:24px">{tab_html}</div>
  </div>

  <div style="display:grid;grid-template-columns:440px minmax(0, 1fr);gap:20px;padding:20px 32px 0 32px;align-items:start">

    {left_panel(P)}

    <div style="display:grid;grid-template-columns:minmax(0, 1fr) 232px;gap:20px;min-width:0;align-items:start">
      <div style="display:flex;flex-direction:column;background:{P["panel"]};border:1px solid {P["line"]};border-radius:12px;padding:18px 20px 16px 20px;min-width:0">
        <div style="display:flex;flex-direction:column;gap:10px;margin-bottom:14px">
          <div style="display:flex;flex-direction:column;gap:4px">
            <h2 style="margin:0;font-family:{SANS};font-size:15px;font-weight:700;color:{P["t1"]};letter-spacing:-0.01em">복지 항목 <span style="font-weight:500;color:{P["t3"]}">— 9개 카테고리</span></h2>
            <span style="font-size:11px;color:{P["t3"]}">숫자 = 연간 환산 금액(만원) · 색 = 금액 구간(300↑ / 100↑ / 그 미만) · <span style="border-bottom:1px dotted {P["t3"]}">점선</span> = 추정치 · 정성 = 금액 환산 없음</span>
          </div>
          {lens_chips(P, state)}
          {lens_bar(P, state)}
        </div>
        <div style="display:grid;grid-template-columns:repeat(3, minmax(0, 1fr));gap:24px">
          {column2(P, COLS[0], state, target)}{column2(P, COLS[1], state, target)}{column2(P, COLS[2], state, target)}
        </div>
      </div>

      <div style="display:flex;flex-direction:column;gap:18px;background:{P["panel"]};border:1px solid {P["line"]};border-radius:12px;padding:18px 18px 16px 18px">
        <div style="display:flex;flex-direction:column;gap:8px">
          <span style="font-size:11px;color:{P["t3"]};letter-spacing:0.02em">근무형태</span>
          <div style="display:flex;flex-direction:column;gap:8px">
            <span style="display:flex;align-items:center;gap:8px;font-size:14px;color:{P["t1"]}">{icon_check(P["accent"])}재택근무 제공</span>
            <span style="display:flex;align-items:center;gap:8px;font-size:14px;color:{P["t1"]}">{icon_check(P["accent"])}유연근무 제공</span>
            <span style="display:flex;align-items:center;gap:8px;font-size:14px;color:{P["t1"]}">{icon_check(P["accent"])}리프레시 휴가 제공</span>
          </div>
        </div>
        <div style="height:1px;background:{P["line"]}"></div>
        {trust_ledger(P, state)}
        <div style="height:1px;background:{P["line"]}"></div>
        <div style="display:flex;flex-direction:column;gap:8px">
          <span style="font-size:11px;color:{P["t3"]};letter-spacing:0.02em">출처 계보</span>
          <span style="display:inline-flex;align-self:flex-start;align-items:center;height:22px;padding:0 8px;border-radius:4px;background:{P["badge_bg"]};color:{P["badge_fg"]};font-size:12px;font-weight:700">공식 · 27항목</span>
          <span style="font-size:12px;color:{P["t3"]};line-height:1.5">공식 = 회사 안내 기준 등록 · 재직자 편집 이력 없음<br>확인일 2026-04-15 · 만료 2027-10-15</span>
        </div>
        <div style="height:1px;background:{P["line"]}"></div>
        <div style="display:flex;flex-direction:column;gap:8px">
          <span style="font-size:11px;color:{P["t3"]};letter-spacing:0.02em">평균 대비 배율 상위 3개 카테고리</span>
          <div style="display:flex;flex-wrap:wrap;gap:6px">{chips(P)}</div>
          <span style="font-size:12px;color:{P["t3"]}">9개 카테고리 모두 113개사 평균 이상 · 항목 수 / 평균</span>
        </div>
      </div>
    </div>
  </div>

  <div style="display:grid;grid-template-columns:440px minmax(0, 1fr);gap:20px;padding:20px 32px 0 32px">
    <div style="display:flex;flex-direction:column;justify-content:center;gap:4px;padding:0 4px;font-size:12px;color:{P["t3"]};line-height:1.5">
      <span style="font-size:14px;font-weight:700;color:{P["t1"]}">실적 2025 <span style="font-size:12px;font-weight:500;color:{P["t3"]}">연결 기준</span></span>
      <span>출처 금융감독원 전자공시(DART) 사업보고서 · 공시 수치이며 평가가 아닙니다</span>
    </div>
    <div style="display:flex;background:{P["panel"]};border:1px solid {P["line"]};border-radius:12px;overflow:hidden">
      {fin_cell(P,"매출","170,992","-4.7%",False)}
      <div style="width:1px;background:{P["line"]}"></div>
      {fin_cell(P,"영업이익","10,732","-41.1%",False)}
      <div style="width:1px;background:{P["line"]}"></div>
      {fin_cell(P,"순이익","3,751","-73.0%",False)}
    </div>
  </div>

  {ledger(P, state, target)}


</div>
</x-dc>
<script data-dc-script data-props='{{}}'>
class Component extends DCLogic {{
  // 프로토타입: 카드 행을 누르면 아래 원장의 같은 항목으로 부드럽게 이동하고 두 행에 띠를 옮긴다.
  // 실제 사이트에서는 <a href="#b-{{cd}}"> + :target 만으로 같은 일을 한다(JS 0).
  componentDidMount() {{
    var BAND2 = '{P["band2"]}', ACC = '{P["accent"]}';
    var all = function (sel) {{ return Array.prototype.slice.call(document.querySelectorAll(sel)); }};
    var select = function (cd) {{
      all('[data-b]').forEach(function (el) {{
        el.style.background = el.getAttribute('data-bg') || 'transparent';
        el.style.opacity = el.getAttribute('data-op') || '1';
        el.style.boxShadow = '';
        var up = el.querySelector('[data-up]'); if (up) up.hidden = true;
      }});
      all('[data-b="' + cd + '"]').forEach(function (el) {{
        el.style.background = BAND2;
        el.style.opacity = '1';
        if (el.getAttribute('data-role') === 'card') el.style.boxShadow = 'inset 0 0 0 1px ' + ACC;
        var up = el.querySelector('[data-up]'); if (up) up.hidden = false;
      }});
    }};
    all('a[data-go]').forEach(function (a) {{
      a.addEventListener('click', function (e) {{
        e.preventDefault();
        var cd = a.getAttribute('data-go');
        select(cd);
        var t = document.getElementById('b-' + cd);
        if (t) t.scrollIntoView({{ behavior: 'smooth', block: 'center' }});
      }});
    }});
    all('a[href="#"]').forEach(function (a) {{ a.addEventListener('click', function (e) {{ e.preventDefault(); }}); }});
    all('a[data-top]').forEach(function (a) {{
      a.addEventListener('click', function (e) {{
        e.preventDefault();
        var t = document.getElementById('top');
        if (t) t.scrollIntoView({{ behavior: 'smooth', block: 'start' }});
      }});
    }});
  }}
}}
</script>
</body>
</html>
'''

DETAIL_H = 2880  # 프레임 높이(측정 후 확정). 남는 프레임은 배경색으로 칠해진다.
for state, fname in (("all","Detail.dc.html"),("est","DetailLens.dc.html")):
    with open(f"{OUT}/{fname}","w",encoding="utf-8") as f:
        f.write(detail_page(PD, state, "meal", DETAIL_H))
    print("wrote", fname)
