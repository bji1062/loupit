# -*- coding: utf-8 -*-
"""SK텔레콤 복지 카드 — 다크(Main) / 라이트(Light) 두 아트보드를 같은 데이터로 생성."""
import math, html

OUT = "/tmp/claude-0/-home-ubuntu-loupit/919ab74f-5a2d-42e5-99f1-8c593d5f651c/scratchpad/skt-card"

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
<div style="width:1440px;min-height:1000px;background:{body_bg};display:flex;flex-direction:column">

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
  <div style="display:grid;grid-template-columns:440px minmax(0, 1fr);gap:20px;padding:20px 32px 0 32px;flex:1 1 auto">

    <!-- 좌: 로고 + 9각형 + 기본 정보 -->
    <div style="display:flex;flex-direction:column;background:{P["panel"]};border:1px solid {P["line"]};border-radius:12px;padding:20px 20px 12px 20px">
      <div style="display:flex;align-items:flex-start;gap:6px">
        <div style="display:flex;flex-direction:column;gap:10px;align-items:center;flex:none;padding-top:12px">
          <div style="width:88px;height:88px;border-radius:8px;background:{P["logo_bg"]};border:1px solid {P["line2"]};display:flex;align-items:center;justify-content:center">
            <span style="font-family:{SERIF};font-size:48px;font-weight:600;color:{P["logo_fg"]};line-height:1">S</span>
          </div>
        </div>
        <div style="flex:none;margin-top:-10px">{radar(P)}</div>
      </div>
      <div style="display:flex;justify-content:center;gap:16px;font-size:11px;color:{P["t3"]};margin-top:-6px">
        <span style="display:flex;align-items:center;gap:6px"><span style="width:10px;height:10px;border-radius:2px;background:{P["fill"]};border:1.5px solid {P["stroke"]};display:inline-block"></span>SK텔레콤 카테고리별 항목 수</span>
        <span style="display:flex;align-items:center;gap:6px"><span style="width:14px;height:0;border-top:1.5px dashed {P["avg"]};display:inline-block"></span>등록 113개사 평균</span>
      </div>

      <div style="display:flex;justify-content:center;margin:14px 0 6px 0">
        <span style="display:inline-flex;align-items:center;height:28px;padding:0 14px;border-radius:999px;background:{P["pill_bg"]};color:{P["pill_fg"]};font-size:13px;font-weight:600">통신 · 대기업</span>
      </div>

      <div style="display:grid;grid-template-columns:repeat(2, minmax(0, 1fr));column-gap:20px">
        {info(P,"직원수","5,316","명","전년 대비 -3.2%")}
        {info(P,"평균연봉","16,296","만원","전년 대비 +0.8%")}
        {info(P,"평균근속","13.7","년","전년 대비 +4.7%")}
        {info(P,"복지 출처","공식 27","항목","확인일 2026-04-15 · 만료 2027-10-15")}
      </div>

      <span style="font-size:11px;color:{P["t4"]};padding:6px 0 10px 0;border-top:1px solid {P["line"]}">직원수·평균연봉·평균근속 = DART 2025 사업보고서(법인 1벌)</span>
      <div style="display:flex;flex-direction:column;gap:6px;padding:12px 14px;border-radius:8px;background:{P["panel2"]};border:1px solid {P["line"]}">
        <div style="display:flex;justify-content:space-between;font-size:13px"><span style="color:{P["t2"]}">등록 복지 항목</span><span style="font-weight:700;color:{P["t1"]};font-variant-numeric:tabular-nums">27 <span style="font-weight:500;color:{P["t3"]}">· 113개사 중 공동 2번째</span></span></div>
        <div style="display:flex;justify-content:space-between;font-size:13px"><span style="color:{P["t2"]}">금액 합계(연, 추정 포함)</span><span style="font-weight:700;color:{P["t1"]};font-variant-numeric:tabular-nums">1,946만원 <span style="font-weight:500;color:{P["t3"]}">· 11번째</span></span></div>
      </div>
    </div>

    <!-- 우: 카테고리별 복지 + 사이드 패널 -->
    <div style="display:grid;grid-template-columns:minmax(0, 1fr) 232px;gap:20px;min-width:0">
      <div style="display:flex;flex-direction:column;background:{P["panel"]};border:1px solid {P["line"]};border-radius:12px;padding:18px 20px 16px 20px;min-width:0">
        <div style="display:flex;flex-direction:column;gap:4px;margin-bottom:14px">
          <h2 style="margin:0;font-family:{SANS};font-size:15px;font-weight:700;color:{P["t1"]};letter-spacing:-0.01em">복지 항목 <span style="font-weight:500;color:{P["t3"]}">— 9개 카테고리</span></h2>
          <span style="font-size:11px;color:{P["t3"]}">숫자 = 연간 환산 금액(만원) · 색 = 금액 구간(300↑ / 100↑ / 그 미만) · 추정 = 앵커 추정치 · 정성 = 금액 환산 없음</span>
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
