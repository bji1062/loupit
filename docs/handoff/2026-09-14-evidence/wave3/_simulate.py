#!/usr/bin/env python3
"""integration-audit.md §5·§9 조치를 스크래치 사본(_sim/)에 적용해 조치 목록 자체를 검증한다.
리포·원본 스크래치 SQL 은 건드리지 않는다. 사용: python3 _simulate.py
"""
import glob
import os
import re
import shutil
import sys

W3 = "/tmp/claude-0/-home-ubuntu-loupit/723f8817-c77d-4e78-ab10-c256a6b1bdd7/scratchpad/wave3"
SIM = W3 + "/_sim"
sys.path.insert(0, W3)
import _audit as A  # noqa: E402

G = " (그룹 통합 채용 기준)"
# (파일, SORT) → 조치
OPS = {
    "포스코인터내셔널": [
        ("del", 40),
        ("set", 41, dict(nm="출장 Refresh 휴가·심야근무 보상휴가",
                         qual="주말 또는 Overnight 항공편 이용 시 Refresh 휴가 부여, 심야 근무 시 익일/차주 휴가 부여 (공식 홈페이지 복리후생 Work & Life Balance 항목 — 부여 일수·심야 근무 인정 기준 미기재)")),
    ],
    "포스코퓨처엠": [
        ("set", 22, dict(qual="배우자 태아 검진 휴가, 출산 장려금, 아기 첫만남 선물, 육아휴직 자녀당 최대 2년 중 회사지원 추가 1년 (공식 인사제도 페이지 복리후생 임신·출산·육아 항목 — 검진 휴가 일수, 장려금 액수, 선물 내용 미기재)")),
    ],
    "삼성증권": [
        ("del", 74),
        ("set", 73, dict(nm="가족 친화 프로그램·가족 주말농장",
                         qual="임직원 자녀와 함께하는 가족 친화 프로그램 운영, 임직원이 가족과 함께 이용할 수 있는 주말농장 제공 (공식 복리후생 페이지 기타/여가 생활 지원 항목·삼성 채용사이트 삼성증권 소개 — 프로그램 내용·개최 주기·참가 자격, 주말농장 위치·분양 면적·이용 기간 미기재)")),
    ],
    "SK바이오팜": [
        ("del", 42),
        ("set", 41, dict(nm="출근버스·차량 보조금",
                         qual="출근버스 및 차량 보조금 지원 (공식 홈페이지 지속가능경영 복리후생 회사 생활 항목 — 노선·보조금 용도·지급 대상·금액 미기재)")),
        ("ins_after", 70, dict(cd="mba", nm="국내 MBA 과정 지원", amt="NULL", ctg="growth", note=None, qy="TRUE",
                               qual="우수 구성원 선발을 통한 국내 MBA 과정 지원 (공식 홈페이지 지속가능경영 구성원 역량 개발 표 학위 항목 — 선발 기준·인원, 학비 지원 범위, 의무 근속 조건 미기재)", so=71)),
    ],
    "에스티팜": [
        ("del", 41),
        ("set", 43, dict(nm="선택적 복지·복지몰",
                         qual="선택적 복지 (동아쏘시오그룹 채용사이트 에스티팜 페이지 LIFE 항목) · 복지몰 운영 (에스티팜 홈페이지 Careers 페이지 Others 항목) — 연간 포인트 금액·사용처 미기재")),
        ("set", 70, dict(qual="포상 제도, 장기 근속 등 (에스티팜 홈페이지 Careers 페이지 Office 항목) · 장기 근속 포상 (동아쏘시오그룹 채용사이트 에스티팜 페이지 REFRESH 항목) — 근속 연수 기준·포상 내용(금품·휴가 여부)·금액 미기재")),
    ],
    "루닛": [
        ("set", 21, dict(nm="우리사주조합",
                         qual="우리사주조합 운영 (2025 지속가능경영보고서 복리후생 표·합리적인 보상 제도 — 회사 출연 여부·가입 조건 미기재)")),
        ("del", 71),
        ("set", 70, dict(qual="시간과 장소 제약 없이 유연하게 결정하는 유연근무제 운영, 유연근무제와 원격근무로 업무 자율성 보장 (2025 지속가능경영보고서 복리후생 표·본문 — 코어타임·원격근무 허용 일수·적용 직무 미기재)")),
    ],
    "씨젠": [("set", 41, dict(cd="leave_general"))],
    "가온전선": [("set", 60, dict(cd="leave_general"))],
    "더존비즈온": [
        ("set", 10, dict(qual="직원들의 안정된 근무여건 조성을 위한 단체상해보험 가입 지원 (더존ICT그룹 복리후생제도 페이지·채용공고 단체상해보험 항목 — 보장 범위·보험료 부담 미기재)" + G)),
        ("set", 11, dict(qual="정기 건강검진 실시 (더존ICT그룹 복리후생제도 페이지·채용공고 건강관리 항목 — 검진 항목·주기·가족 포함 여부·비용 미기재)" + G)),
        ("set", 12, dict(qual="강촌 본사·을지타워·부산에 사내 헬스케어센터 운영 (더존ICT그룹 채용공고 건강관리 항목 · 복리후생제도 페이지 복리후생시설 항목 헬스케어센터(필라테스) — 이용 조건·프로그램 구성 미기재)" + G)),
        ("set", 20, dict(qual="경조사 발생 시 경조휴가·화환·경조금 지급 (더존ICT그룹 복리후생제도 페이지·채용공고 경조지원 항목 — 경조 구분별 금액·휴가 일수 미기재)" + G)),
        ("set", 21, dict(qual="직원의 일과 가정의 균형을 위해 강촌 본사에 사내 어린이집 운영 (더존ICT그룹 채용공고 사내 어린이집 운영 항목 · 복리후생제도 페이지 복리후생시설 항목 사내어린이집(강촌캠퍼스) — 정원·대상 연령 미기재)" + G)),
        ("set", 30, dict(qual="직원들의 자기계발을 위한 도서구매 지원 (더존ICT그룹 복리후생제도 페이지·채용공고 교육지원 항목 — 지원 한도·구매 방식 미기재)" + G)),
        ("set", 40, dict(qual="직원들의 여가생활 활성화를 위해 사내동호회(축구, 야구, 농구, 헬스 등) 활동 지원 (더존ICT그룹 복리후생제도 페이지·채용공고 동호회 항목 — 활동비 지원액 미기재)" + G)),
        ("set", 60, dict(qual="강촌 본사 및 을지타워에서 무료 사내식당(조·중·석식)과 간식 제공 (더존ICT그룹 채용공고 사내 식사/간식 제공 항목 · 복리후생제도 페이지 복리후생시설 항목 사내식당(조,중,석식 제공) — 그 밖의 사업장 제공 여부 미기재)" + G)),
        ("set", 61, dict(qual="직원 편의를 위해 강촌 본사와 을지타워에 사내 카페 운영 (더존ICT그룹 채용공고 사내 카페 운영 항목 — 무료 여부·이용 한도 미기재)" + G)),
        ("set", 62, dict(qual="강촌 본사와 잠실역·강변역·천호역·구리역·태릉입구역·상봉역·평내호평역·춘천지역 간 통근버스 운행 (더존ICT그룹 채용공고 통근버스 운행 항목 · 복리후생제도 페이지 복리후생시설 항목 — 운행 시간·요금 부담 여부 미기재)" + G)),
        ("set", 63, dict(qual="명절선물 제공 (더존ICT그룹 채용공고 경조지원 항목 — 선물 품목·금액·지급 횟수 미기재)" + G)),
    ],
}


def q(s):
    return "NULL" if s is None else "'" + s.replace("'", "''") + "'"


def tuple_text(d):
    return (f"(@comp_id, '{d['cd']}', {q(d['nm'])}, {d['amt']}, '{d['ctg']}',\n"
            f"   'est', {q(d['note'] or None)}, {d['qy']}, {q(d['qual'] or None)}, {d['so']})")


def apply(name, text, ops):
    for op in ops:
        rows = [(m, A.fields(m.groups())) for m in A.ROW.finditer(text)]
        by = {d["so"]: (m, d) for m, d in rows}
        kind, so = op[0], op[1]
        m, d = by[so]
        if kind == "del":
            ls = text.rfind("\n", 0, m.start()) + 1
            end = m.end()
            assert text[end] == ",", f"{name} {so}: 마지막 행 삭제는 이 시뮬레이터 범위 밖"
            nl = text.find("\n", end)
            # 행 앞 빈 줄·섹션 주석은 남긴다
            text = text[:ls] + text[nl + 1:]
        elif kind == "set":
            nd = dict(d)
            nd["amt"] = d["amt"]
            nd.update(op[2])
            text = text[:m.start()] + tuple_text(nd) + text[m.end():]
        elif kind == "ins_after":
            end = m.end()
            assert text[end] == ","
            nl = text.find("\n", end)
            text = text[:nl + 1] + "  " + tuple_text(op[2]) + ",\n" + text[nl + 1:]
    return text


def main():
    shutil.rmtree(SIM, ignore_errors=True)
    os.makedirs(SIM)
    for p in sorted(glob.glob(W3 + "/*.sql")):
        name = os.path.basename(p)[:-4]
        t = open(p, encoding="utf-8").read()
        t2 = apply(name, t, OPS.get(name, []))
        open(f"{SIM}/{name}.sql", "w", encoding="utf-8").write(t2)
    corpus, codes, _, _ = A.load_corpus()
    slugs = {A.slug_of(e): v["nm"] for e, v in corpus.items()}
    files = [A.audit_file(p, corpus, slugs) for p in sorted(glob.glob(SIM + "/*.sql"))]
    total = 0
    for f in files:
        total += f["n"]
        print(f"{f['file']:22s} rows={f['n']:2d} stmts={f['stmts']} {'OK' if not f['probs'] else f['probs']}")
    print("TOTAL", total, "SD-4", 2032 + total)
    vocab = set(codes)
    new = sorted({r[0] for f in files for r in f["rows"] if r[0] not in vocab})
    print("신규 코드", new)
    print("refresh_leave 잔존", [(f["nm"], A.fields(r)["so"]) for f in files for r in f["rows"] if r[0] == "refresh_leave"])
    dz = [f for f in files if f["nm"] == "더존비즈온"][0]
    print("더존 그룹 각주", sum("(그룹 통합 채용 기준)" in A.fields(r)["qual"] for r in dz["rows"]), "/", dz["n"],
          "· 더존비즈온 채용공고 잔존", sum("더존비즈온 채용공고" in A.fields(r)["qual"] for r in dz["rows"]))
    ln = [f for f in files if f["nm"] == "루닛"][0]
    print("루닛 서울 오피스 한정", sum("서울 오피스" in A.fields(r)["qual"] + A.fields(r)["note"] for r in ln["rows"]))
    print("편집 주석", [(h["company"], h["sort"], h["terms"]) for h in A.scan_terms(files, A.EDIT_TERMS)])
    print("법정", [(h["company"], h["sort"], h["field"], h["terms"]) for h in A.scan_terms(files, A.LEGAL_TERMS)])
    print("태아 검진 잔존", [(f["nm"], A.fields(r)["so"]) for f in files for r in f["rows"] if "본인/배우자 태아" in A.fields(r)["qual"]])
    for f in files:
        for r in f["rows"]:
            d = A.fields(r)
            if len(d["qual"]) > 450 or len(d["nm"]) > 60:
                print("  길이 근접", f["nm"], d["so"], len(d["nm"]), len(d["qual"]))


if __name__ == "__main__":
    main()
