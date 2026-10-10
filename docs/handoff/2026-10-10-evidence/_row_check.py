#!/usr/bin/env python3
"""웨이브 5 시드 SQL 점검기 — 리포 게이트(적재 뒤 테스트)가 잡을 것을 수집 · 검증 · 감사 · 통합 단계에서 미리 잡는다.

사용:
  python3 /home/ubuntu/loupit-evidence/2026-10-10-wave5/_row_check.py <파일.sql> [...] [--corpus <폴더>]
    --corpus  slug · 표시명 충돌을 볼 기존 시드 폴더(기본 /home/ubuntu/loupit/db/seed/benefit/sql).
              점검하는 파일과 파일명이 같은 것은 자기 자신으로 보고 뺀다(통합 뒤 worktree 에서 돌릴 때).

리포는 읽기만 한다 — 리포 모듈을 import 해 게이트와 같은 함수로 판정한다:
  db/seed/load.py `_split_sql_statements`(분할기) · db/seed/company_meta.py `parse_header_insert` · `ws_conditions`
  db/seed/backfill_dec2.py `derive_amt_source` · `_DATE_RE` · `_URL_RE` · generator/slug.py `slug_of`
  generator/benefit_rules.py `_PAREN` · `_drop_or_keep` · `_TAIL` · `_META_TAIL`(SI-11 과 같은 판정)
행 파서는 /home/ubuntu/loupit-evidence/2026-10-02-recollect-3-7/_len_check.py 의 parse_values 를 그대로 쓴다.
필드 길이는 이 도구가 보지 않는다 — _len_check.py 를 따로 돌린다. 법정 · 편집 낱말은 _legal_scan.py 가 본다.

출력: 파일마다 [오류] · [확인] 줄 + 금액 행의 금액 출처 예측(stated / estimated) + 근무형태 칩 판정 + 요약.
[오류] 가 하나라도 있으면 종료 코드 1. [확인] 은 오류가 아니라 근거표에 판단을 적어야 하는 줄이다.
"""
import importlib.util
import os
import re
import sys

REPO = "/home/ubuntu/loupit"
W5 = "/home/ubuntu/loupit-evidence/2026-10-10-wave5"
VOCAB = os.path.join(W5, "_VOCAB.md")
LEN_CHECK = "/home/ubuntu/loupit-evidence/2026-10-02-recollect-3-7/_len_check.py"
DEFAULT_CORPUS = os.path.join(REPO, "db/seed/benefit/sql")

sys.path.insert(0, REPO)
from db.seed import load  # noqa: E402
from db.seed.backfill_dec2 import _DATE_RE, _URL_RE, derive_amt_source  # noqa: E402
from db.seed.company_meta import _WS_CODE_KEY, parse_header_insert, ws_conditions  # noqa: E402
from generator import benefit_rules as br  # noqa: E402
from generator.slug import slug_of  # noqa: E402

_spec = importlib.util.spec_from_file_location("len_check", LEN_CHECK)
lc = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(lc)

CATEGORIES = {"compensation", "health", "family", "leisure", "perks", "growth", "time_off", "flexibility", "work_env"}
HDR_INSERT = re.compile(
    r"INSERT IGNORE INTO TCOMPANY \(COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL\)\s*"
    r"VALUES \('([^']+)', '([^']+)',\s*\(SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = '([a-z]+)'\),\s*"
    r"'([^']*)', '([^']*)', '([^']*)'\);")
UPD = re.compile(r"UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = '([^']*)'\s*WHERE COMP_ID = @comp_id")
# SI-12(레인 메모 낱말) — server/tests/test_seed_integrity.py test_SI12_no_lane_memo_words_in_user_facing_fields 와 같은 식
MEMO = re.compile(r"전문: |을 합친|를 합친|한 번에 합친|덧붙인|덧붙일|을 빼면|를 빼면|#\d+")
# SI-12(stated 행 서술의 원 · 만원 숫자) — test_SI12_stated_rows_show_a_won_figure_in_their_text 와 같은 식
WON = re.compile(r"\d[\d,.]*\s*(만\s*원|원|만)")
# SI-B2 — test_SI_B2_monthly_amount_annualized 와 같은 식
MONTHLY = re.compile(r"월\s*(\d+)\s*만\s*원")
# SI-9 — 식대 꼬리 식(test_seed_integrity.py 의 _FORMULA_*)
F_DAYS = re.compile(r"\(하루 (\d)끼 × 1끼 ([\d,]+)원 × 연 240일 추정")
F_LUNCH = re.compile(r"\(점심 1끼 ([\d,]+)원 × 연 240일 추정")
F_DAY = re.compile(r"\(하루 ([\d,]+)원 × 연 240일 추정")
TAIL_START = re.compile(r" \((?:하루|점심) [^()]*연 240일 추정")
M_B, M_L, M_D = re.compile(r"조식|아침"), re.compile(r"중식|점심"), re.compile(r"석식|저녁")
M_THREE = re.compile(r"삼시\s*세?끼|세\s*끼|3\s*끼|3\s*식|조\s*[·/,]\s*중\s*[·/,]\s*석")
M_TWO = re.compile(r"1일 2식|하루 두 끼|2\s*끼|2\s*식|중\s*[·/]?\s*석식|중석식")
# SI-13d — 근무형태 행 이름에 한정처럼 보이는 낱말
WS_LOOKS = re.compile(r"육아|자녀|부문|필요\s*시")
# 수집 계약 규칙 3 · 8-3(⚖ C-3): 「연차」·「반차」·「반반차」 낱말 — 「연차 외」·「연차와 별도」·「연차 사용일인지」 꼴만 확인 줄로 남긴다
LEAVE_WORD = re.compile(r"반반차|반차|연차")
LEAVE_SPLIT_OK = re.compile(r"연차\s*외|연차와\s*별도|연차\s*휴가\s*외|연차\s*사용일인지")
DASH_SEP = re.compile(r"\s+[—–]\s+")


def vocab():
    out = {}
    for line in open(VOCAB, encoding="utf-8"):
        m = re.match(r"^\| `([a-z0-9_]+)` \| (\d+) \| ([a-z_]+)", line)
        if m:
            out[m.group(1)] = m.group(3)
    return out


def corpus_index(corpus, skip_names):
    slugs, names = {}, {}
    for f in sorted(os.listdir(corpus)):
        if not f.endswith(".sql") or f in skip_names:
            continue
        t = open(os.path.join(corpus, f), encoding="utf-8").read()
        m = re.search(r"VALUES\s*\('([^']+)',\s*'([^']+)'", t)
        if m:
            slugs[slug_of(m.group(1))] = f
            names[m.group(2)] = f
    return slugs, names


def formula_amount(note):
    m = F_DAYS.search(note or "")
    if m:
        return int(m.group(1)) * int(m.group(2).replace(",", "")) * 240 // 10000
    m = F_LUNCH.search(note or "")
    if m:
        return int(m.group(1).replace(",", "")) * 240 // 10000
    m = F_DAY.search(note or "")
    if m:
        return int(m.group(1).replace(",", "")) * 240 // 10000
    return None


def meals_in_text(name, note):
    m = TAIL_START.search(note)
    body = note[: m.start()] if m else note
    t = f"{name} {body}"
    kinds = sum(1 for p in (M_B, M_L, M_D) if p.search(t))
    if M_THREE.search(t):
        kinds = max(kinds, 3)
    elif M_TWO.search(t):
        kinds = max(kinds, 2)
    return min(kinds, 3)


def dash_tail_breaks(text):
    """SI-11 과 같은 판정: 괄호 메모를 걷은 뒤 첫 「 — 」 꼬리가 메모인데 그 안에 「 — 」가 또 있으면 원문이 걷힌다."""
    s = text
    while True:
        t = br._PAREN.sub(br._drop_or_keep, s)
        if t == s:
            break
        s = t
    m = br._TAIL.search(s)
    return bool(m and br._META_TAIL.search(m.group(1)) and DASH_SEP.search(m.group(1)))


def check(path, voc, corpus):
    errs, notes, info = [], [], []
    src = open(path, encoding="utf-8").read()
    fname = os.path.basename(path)

    # 1) 분할기 · 다섯 문장
    stmts = load._split_sql_statements(src)
    if len(stmts) != 5:
        errs.append(f"분할기 문장 수 {len(stmts)} (5 이어야 한다)")
    elif not re.sub(r"^(\s*--[^\n]*\n)*\s*", "", stmts[2]).startswith("UPDATE TCOMPANY SET CAREERS_BENEFIT_URL"):
        errs.append("셋째 문장이 UPDATE TCOMPANY SET CAREERS_BENEFIT_URL 이 아니다")

    # 2) 머리말 두 줄(백필 정규식)
    dm, um = _DATE_RE.search(src), _URL_RE.search(src)
    if not dm:
        errs.append("머리말 「-- 출처: AI 파싱 (YYYY-MM-DD)」 줄이 없다(확인일이 2026-07-10 으로 떨어진다 — SB-11)")
    if not um:
        errs.append("머리말 「-- URL: http…」 줄이 없다(전 행이 근거 URL 없음 ai_parse 로 적재된다)")

    # 3) 등록 문장
    try:
        eng, nm, tp = parse_header_insert(src)
    except Exception as e:  # noqa: BLE001
        eng = nm = tp = None
        errs.append(f"parse_header_insert 실패: {e}")
    h = HDR_INSERT.search(src)
    if not h:
        errs.append("INSERT IGNORE INTO TCOMPANY 문장이 본보기 모양과 다르다")
    else:
        h_eng, h_nm, h_tp, h_ind, h_logo, h_url = h.groups()
        if h_tp not in ("large", "mid", "public"):
            errs.append(f"COMP_TP_CD {h_tp} — large / mid / public 중 하나")
        if not re.fullmatch(r"[A-Z0-9]", h_logo):
            errs.append(f"LOGO_NM {h_logo!r} — 영문 이니셜 대문자 1자")
        u = UPD.search(src)
        urls = {h_url, u.group(1) if u else None, um.group(1) if um else None}
        if len(urls) != 1:
            errs.append(f"정본 URL 이 세 곳(머리말 · INSERT · UPDATE)에서 다르다: {sorted(x for x in urls if x)}")
        info.append(f"등록: {h_eng} · {h_nm} · {h_tp} · 업종 {h_ind} · 로고 {h_logo} · {h_url}")
        try:
            sl = slug_of(h_eng)
            if sl in corpus[0]:
                errs.append(f"slug {sl} 가 기존 시드 {corpus[0][sl]} 와 충돌")
        except Exception as e:  # noqa: BLE001
            errs.append(f"slug_of 실패: {e}")
        if h_nm in corpus[1]:
            errs.append(f"표시명 {h_nm} 가 기존 시드 {corpus[1][h_nm]} 와 같다")

    # 4) 따옴표 — 주석 줄 · 문자열 안
    for i, line in enumerate(src.splitlines(), 1):
        if line.lstrip().startswith("--") and ("'" in line or '"' in line):
            errs.append(f"{i}행 주석에 홑·겹따옴표")
    if "''" in src:
        errs.append("문자열 안 홑따옴표('' 이스케이프)가 있다 — 「」 또는 U+2019 ’ 로")
    body_wo_comments = re.sub(r"^\s*--.*$", "", src, flags=re.M)
    if '"' in body_wo_comments:
        errs.append("겹따옴표가 있다")

    # 5) 행
    m = lc.INS.search(src)
    if not m:
        errs.append("INSERT INTO TCOMPANY_BENEFIT 를 못 찾았다")
        return errs, notes, info
    cols = [c.strip().strip("`") for c in m.group(1).replace("\n", " ").split(",")]
    rows = [dict(zip(cols, t)) for t in lc.parse_values(src, m.end())]
    codes, sorts = [], []
    n_amt = amt_sum = 0
    srcs = {"stated": 0, "estimated": 0, "none": 0}
    for r in rows:
        cd, nm_, ctg = r.get("BENEFIT_CD"), r.get("BENEFIT_NM") or "", r.get("BENEFIT_CTGR_CD")
        note, desc, so = r.get("NOTE_CTNT"), r.get("QUAL_DESC_CTNT"), r.get("SORT_ORDER_NO")
        amt = None if r.get("BENEFIT_AMT") is None else float(r["BENEFIT_AMT"])
        qual = r.get("QUAL_YN") == "TRUE"
        tag = f"SORT {so} {cd}"
        codes.append(cd)
        sorts.append(so)
        if r.get("BADGE_CD") != "est":
            errs.append(f"{tag}: BADGE_CD 가 est 가 아니다")
        if ctg not in CATEGORIES:
            errs.append(f"{tag}: 카테고리 {ctg} 는 9칸 밖")
        if cd in voc:
            if voc[cd] != ctg:
                errs.append(f"{tag}: 카테고리 {ctg} ≠ 어휘표 {voc[cd]}")
        else:
            notes.append(f"{tag}: 어휘표에 없는 코드 — 근거표 「신규 코드」 절 필요(규칙 5)")
        # 금액 행 / 정성 행 모양
        if amt is None:
            if not qual:
                errs.append(f"{tag}: 금액 NULL 인데 QUAL_YN FALSE")
            if not desc:
                errs.append(f"{tag}: 정성 행인데 QUAL_DESC 가 비었다")
            if note:
                notes.append(f"{tag}: 정성 행에 NOTE 가 있다(관례는 NOTE NULL · 서술은 QUAL_DESC)")
        else:
            n_amt += 1
            amt_sum += amt
            if qual:
                errs.append(f"{tag}: 금액이 있는데 QUAL_YN TRUE")
            if desc:
                errs.append(f"{tag}: 금액 행에 QUAL_DESC — 금액 행 서술은 NOTE 하나(리드 판정 (83))")
            if not note:
                errs.append(f"{tag}: 금액 행에 NOTE 가 없다 — 근거 없는 금액은 estimated 로 적재된다")
            s = derive_amt_source(amt, qual, note)
            srcs[s] += 1
            info.append(f"금액 {tag} {amt:g} → {s}")
            if s == "stated" and not WON.search(f"{note or ''} {desc or ''}"):
                errs.append(f"{tag}: stated 인데 서술에 원 · 만원 숫자가 없다(SI-12)")
            mm = MONTHLY.search(note or "")
            if mm and int(mm.group(1)) == int(amt):
                errs.append(f"{tag}: 월액을 연으로 바꾸지 않았다(SI-B2 — 월액 × 12)")
            if cd == "meal" and s == "estimated":
                fa = formula_amount(note)
                if fa is None:
                    notes.append(f"{tag}: 식대 추정인데 식 꼬리가 없다 — SI-9 허용 목록(_MEAL_NO_TAIL_OK)에 이 회사를 더해야 적재 게이트를 지난다(규칙 4-5 · ⚖ C-12)")
                else:
                    if fa != int(amt):
                        errs.append(f"{tag}: 금액 {amt:g} ≠ 꼬리 식 {fa}(SI-9)")
                    d = F_DAYS.search(note)
                    if d and int(d.group(2).replace(",", "")) != 12000:
                        errs.append(f"{tag}: 「하루 N끼」 꼬리 단가가 12,000원이 아니다(SI-9)")
                    if d and int(d.group(1)) > meals_in_text(nm_, note):
                        errs.append(f"{tag}: 꼬리 끼니 {d.group(1)} > 이름·본문에서 센 끼니 {meals_in_text(nm_, note)}(SI-9)")
        # 사용자 노출 칸
        for fld, v in (("NM", nm_), ("NOTE", note or ""), ("DESC", desc or "")):
            if not v:
                continue
            if MEMO.search(v):
                errs.append(f"{tag} {fld}: 레인 메모 낱말(SI-12)")
            if fld != "NM" and dash_tail_breaks(v):
                errs.append(f"{tag} {fld}: 「 — 」 꼬리가 둘 이상 — 원문이 매칭 사본에서 걷힌다(SI-11)")
            for lw in LEAVE_WORD.finditer(v):
                ctx = v[max(0, lw.start() - 2): lw.end() + 6]
                if lw.group(0) == "연차" and LEAVE_SPLIT_OK.search(ctx):
                    notes.append(f"{tag} {fld}: 「{ctx}」 — 법정분과 회사분을 가른 꼴(⚖ C-3 권고: 허용)")
                else:
                    errs.append(f"{tag} {fld}: 「{lw.group(0)}」 낱말(규칙 3 · R-3 기준 3)")
        # 근무형태 칩
        if cd in _WS_CODE_KEY:
            cond = ws_conditions(nm_)
            info.append(f"칩 {tag} 「{nm_}」 → {cond or '조건 없음(맨 칩)'}")
            if WS_LOOKS.search(nm_) and not cond:
                errs.append(f"{tag}: 이름에 육아 · 자녀 · 부문 · 필요시가 있는데 조건으로 안 읽힌다(SI-13d · 규칙 13)")
    for c in sorted({c for c in codes if codes.count(c) > 1}):
        errs.append(f"코드 {c} 가 두 행 — 회사당 한 행(UNIQUE)")
    for s_ in sorted({s for s in sorts if sorts.count(s) > 1}):
        errs.append(f"SORT {s_} 가 두 행")
    info.append(f"요약: 행 {len(rows)} · 금액 행 {n_amt}(합 {amt_sum:g}) · stated {srcs['stated']} · estimated {srcs['estimated']}")
    return errs, notes, info


def main(argv):
    corpus_dir = DEFAULT_CORPUS
    files = []
    it = iter(argv)
    for a in it:
        if a == "--corpus":
            corpus_dir = next(it)
        else:
            files.append(a)
    if not files:
        print(__doc__)
        return 2
    voc = vocab()
    corpus = corpus_index(corpus_dir, {os.path.basename(f) for f in files})
    bad = 0
    for f in files:
        errs, notes, info = check(f, voc, corpus)
        print(f"\n=== {f} — 오류 {len(errs)} · 확인 {len(notes)}")
        for x in errs:
            print("  [오류]", x)
        for x in notes:
            print("  [확인]", x)
        for x in info:
            print("  ·", x)
        bad += len(errs)
    print(f"\n총 오류 {bad}" + ("" if bad else " — 통과"))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
