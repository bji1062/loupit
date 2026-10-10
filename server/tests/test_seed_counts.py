"""SP-SEED-11.1 카운트 테스트 (SD-1~SD-7).

근거: SPEC/03 SP-SEED-11.1 · TASK/03 T-03.2.1·T-03.2.2·T-03.3.4·T-03.3.5·T-03.4.1.
`seeded_db`(conftest, load.main(fresh=True))가 스키마→시드→백필 전체를 적용한 뒤
검증한다.
"""

from __future__ import annotations

import pytest

TYPE_CODES_5_NONFREELANCE = {"large", "mid", "public", "startup", "foreign"}


def _scalar(conn, sql, params=()):
    with conn.cursor() as cur:
        cur.execute(sql, params)
        return cur.fetchone()[0]


# ── SD-1: 기업유형 6종 ──
def test_SD1_company_type_count(seeded_db):
    assert _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY_TYPE") == 6


# ── SD-2: 프리셋 28행 ──
def test_SD2_benefit_preset_total_count(seeded_db):
    assert _scalar(seeded_db, "SELECT COUNT(*) FROM TBENEFIT_PRESET") == 28


# ── SD-3: 회사 102 (Tier-0) — 95 + CJ 계열 7개사(2026-07-30) ──
def test_SD3_company_count_is_102(seeded_db):
    """정확 카운트 핀. 회사 추가는 **의도적으로만** 가능해야 한다(시드 유실·중복 조기 발견).
    회사를 늘리거나 줄일 땐 이 값과 SI-8·멱등성 스냅샷을 함께 갱신하라."""
    assert _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY") == 160  # 150 − LG · LS 지주 · HPSP 등록 해제(2026-10-01 · 2026-10-02, 공식 복지 원문 없음) + 확장 웨이브 5 13개사(2026-10-10)


# ── SD-4: 복지 총행 3463(3472 − 11 + 2 코퍼스 정리 4가지, 2026-10-10 · 3472 = 3179 + 293 확장 웨이브 5 · 3179 = 3097 + 77 R-3 후속 정리 2 + 1 R-3 후속 정리 3 월말휴무 + 11 후속 정리 5 − 7 엘앤에프 출처 이전, 2026-10-05), 하한 1200 방어 ──
def test_SD4_benefit_total_row_count(seeded_db):
    """정확 카운트 핀 — 시드 유실·중복 적재를 조기에 잡는다.

    내역: 원본 1330 − 모비스 중복 13 = 1317 (2026-07 재이식분)
          + CJ 계열 7개사 148행(2026-07-30) = 1465
          엔터 22 · 커머스 24 · 프레시웨이 21 · 올리브영 22 · 대한통운 19 · 제일제당 20 · CGV 20
          ⚠ 주식보상(RSU)은 일회성 부여 공시라 상시 제도가 아니어서 제외했다(-2행, 사용자 결정).
          + 에이전트 재수집 파일럿 +22행(2026-08-31) = 1487
          셀트리온 22→20(근거 없는 8행 제외·신규 6행) · 아이센스 5→29(구본=자회사 오염 전면 교체)
          — handoff/2026-08-31-복지-에이전트수집-파일럿.md
          + 에이전트 재수집 배치 1 +66행(2026-08-31) = 1553
          알테오젠 3→12 · 유진테크 4→12 · 엠씨넥스 5→14 · 엔켐 6→16 · 삼성카드 7→23(구본=에코비트
          오염) · 실리콘투 6→20 · 삼천당제약 7→7 — 리메드·오스코텍·리노공업은 공식 소스 부재로
          무변경. handoff/2026-08-31-복지-배치1.md
          + 확장 웨이브 1 신규 11개사 +202행(2026-09-01) = 1755
          원익IPS 24 · LG CNS 27 · 한국타이어 22 · KB금융 21 · 엘앤에프 20 · HD현대 19 ·
          심텍 17 · 하나마이크론 14 · 현대건설 14 · LS ELECTRIC 12 · 고려아연 12
          — handoff/2026-09-01-회사확장-웨이브1.md
          + 확장 웨이브 2 신규 13개사 +277행(2026-09-05)
          + 확장 웨이브 3 신규 12개사 +203행(2026-09-15) = 2235
          한국항공우주산업 34 · 삼성화재 28 · 삼성E&A 26 · 삼성중공업 26 · 삼성SDS 23 · 넷마블 22 ·
          이수페타시스 21 · LG이노텍 20 · 동진쎄미켐 19 · 대덕전자 17 · 셀트리온제약 17 · 한화생명 15 ·
          삼양식품 9 — 검증(Fable ×7)·감사(Opus) 판정 반영: 삭제 6·병합 4·재코딩 2·편집 주석 69필드 일소
          — handoff/2026-09-05-회사확장-웨이브2.md
          − 데이터 정리 1차 합치기 2행(2026-09-18) = 2233
          아이센스 childcare 「보육수당」·child_edu 「자녀 입학축하금」을 같은 회사 parenting 에 합쳤다
          (재코딩 15행·정성 전환 2행은 행 수 불변) — db/migrations/20260918_recode_misclassified_rows.sql
          + 확장 웨이브 4 신규 12개사 +219행(2026-09-20) = 2452
          피에스케이 26 · GC녹십자 25 · 풍산 24 · HL만도 23 · 이마트 23 · JYP Ent. 20 · 제주반도체 17 ·
          농심 16 · 현대백화점 14 · 티에스이 12 · 파두 10 · 동국제약 9
          — 수집 223 − 삭제·병합 9 + 추가 5. 검증(Fable ×9 · Opus ×3, REFUTED 0)·감사(Opus, BLOCK 5)
          판정 반영 — handoff/2026-09-19-evidence/_ROSTER.md
          − 데이터 정리 2차 삭제 1행(2026-09-21) = 2451
          휴젤 welcome_kit 「온보딩 프로그램」 — 혜택 내용 없이 「운영」만 있는 서술이라 행이
          아니고(상담실 선례), welcome_kit 은 나머지 10사가 전부 입사 선물 물품에 쓰는 코드라
          뜻도 어긋났다(사용자 결정). 카테고리 통일 30행·문안 60행은 행 수 불변
          — db/migrations/20260921_data_cleanup_2.sql
          + 재수집 R-1 9개사 207 → 259행(2026-09-26) = 2503
          NAVER 37 · LIG넥스원 33 · SK텔레콤 32 · 현대자동차 31 · S-Oil 29 · 롯데케미칼 27 · SK하이닉스 25 · SK이노베이션 24 · 카카오페이 21
          — 수집 246 − 삭제·병합 2 + 추가 15. 운영은 표적 삭제 25·재코딩 10 뒤 멱등 적재(db/migrations/20260926_recollect_9_official.sql).
          검증(Fable ×5 레인, 9사)·감사(Opus) — loupit-evidence/2026-09-26-recollect/audit/integration-audit.md
          + 재수집 R-2 2개사 33 → 60행(2026-09-28, 출처 끊김 — 주간 점검 첫 실행) = 2530
          LG전자 15 → 26 · 현대모비스 18 → 34 — 수집 60 − 삭제 1 + 추가 1. 운영은 재코딩 2 뒤 멱등 적재
          (db/migrations/20260928_recollect_2_lg_mobis.sql) — loupit-evidence/2026-09-27-recollect-2/
          + 재수집 R-3 묶음 1 10개사 163 → 242행(2026-09-28, 근거 URL 없던 72곳 중 첫 10) = 2609
          펄어비스 40 · 기아 29 · 엔씨소프트 28 · 크래프톤 27 · 에이피알 25 · 카카오 23 · 카카오뱅크 21 ·
          더블유게임즈 18 · 한미반도체 18 · NH투자증권 13 — 운영은 표적 삭제 21 · 재코딩 13 뒤 멱등 적재
          (db/migrations/20260928_recollect_3_batch1.sql) — loupit-evidence/2026-09-28-recollect-3/
          + 재수집 R-3 묶음 2 9개사 134 → 230행(2026-10-01, 근거 URL 없던 62곳 중 다음 10 — LG 지주는 후속) = 2705
          LG에너지솔루션 30 · LG화학 29 · 카카오게임즈 27 · 삼성생명 26 · 파마리서치 25 · 휴젤 24 ·
          LG유플러스 23 · 하이브 23 · 네패스 23 — 운영은 표적 삭제 17 · 재코딩 5 뒤 멱등 적재
          (db/migrations/20261001_recollect_3_batch2.sql) — loupit-evidence/2026-10-01-recollect-3-2/
          − LG 지주 등록 해제 14행(2026-10-01) = 2691 — 공식 복지 원문이 없고(수집 · 검증 · DART 사업보고서 원문 확인)
          구본은 LG유플러스 옛 자료의 사본이었다. 회사 · 별칭 · 메일 도메인 · DART 연결째 지운다
          (db/migrations/20261001_unregister_lg_holding.sql)
          + 재수집 R-3 묶음 3 8개사 128 → 150행(2026-10-01, 근거 URL 없던 52곳 중 다음 8 — LS 는 같은 날 등록 해제 · 유한양행은 원문 대기)
          2691 − 128 + 150 = 2713
          CJ올리브네트웍스 34 · 컴투스 23 · HMM 22 · 위메이드 18 · 아이패밀리에스씨 18 · 티씨케이 19 · 파크시스템스 11 ·
          제이엘케이 5 — 운영은 표적 삭제 32 · 재코딩 6 뒤 멱등 적재
          (db/migrations/20261001_recollect_3_batch3.sql) — loupit-evidence/2026-10-01-recollect-3-3/
          2713 − 8 = 2705 (LS 지주 등록 해제) — 수집 · 검증이 따로 찾았으나 ㈜LS 자신에게 적용된다고 밝힌 복지 원문이 없고
          (OpenDART 사업보고서에도 복지 서술 없음) 구본 8행은 KLT(Pulsarlube) 데이터였다
          (db/migrations/20261001_unregister_ls_holding.sql)
          + 재수집 R-3 묶음 3 후속 유한양행 17 → 22행(2026-10-01, 사용자가 붙여 넣은 공식 채용 사이트 원문 2쪽)
          2705 − 17 + 22 = 2710 (R-3 묶음 3 유한양행) — 운영은 표적 삭제 3 · 재코딩 3 뒤 멱등 적재
          (db/migrations/20261001_recollect_3_yuhan.sql) — loupit-evidence/2026-10-01-recollect-3-3/
          + 재수집 R-3 묶음 4-A 그룹 계열 7사(현대오토에버 · 현대무벡스 · LG디스플레이 · 삼성전기 · 삼성SDI · 삼성물산 · 삼성바이오로직스) 88 → 210행
          2710 − 88 + 210 = 2832 (R-3 묶음 4-A 7사) — 운영은 표적 삭제 6 · 재코딩 3 뒤 멱등 적재
          (db/migrations/20261002_recollect_3_batch4a.sql) — loupit-evidence/2026-10-02-recollect-3-4/
          + 재수집 R-3 묶음 4-B 현대 3사(현대로템 · 현대제철 · 현대글로비스, 사용자가 붙여 넣은 공식 채용 사이트 원문) 40 → 69행
          2832 − 40 + 69 = 2861 (R-3 묶음 4-B 현대 3사) — 운영은 표적 삭제 6 · 재코딩 2 뒤 멱등 적재
          (db/migrations/20261002_recollect_3_batch4b.sql) — loupit-evidence/2026-10-02-recollect-3-4/
          + 재수집 R-3 묶음 5 10사(한화 · 한화에어로스페이스 · 한화시스템 · 한화오션 · ㈜두산 · 두산에너빌리티 · ㈜에코프로 · 에코프로비엠 · 올릭스 · 솔브레인) 135 → 242행
          2861 − 135 + 242 = 2968 (R-3 묶음 5 10사) — 운영은 표적 삭제 28 · 재코딩 5 뒤 멱등 적재
          (db/migrations/20261002_recollect_3_batch5.sql) — loupit-evidence/2026-10-02-recollect-3-5/
          + 재수집 R-3 묶음 6-A 8사(이오테크닉스 · 주성엔지니어링 · 테크윙 · 덕산네오룩스 · 비에이치 · 지놈앤컴퍼니 · 클래시스 · 레인보우로보틱스) 92 → 127행
            · HPSP 회사 등록 해제(복지 14행 — 공식 복지 원문 없음)
          2968 − 92 − 14 + 127 = 2989 (R-3 묶음 6-A 8사 · HPSP 등록 해제) — 운영은 표적 삭제 17 · 재코딩 2 뒤 멱등 적재
          (db/migrations/20261002_unregister_hpsp.sql · 20261002_recollect_3_batch6a.sql) — loupit-evidence/2026-10-02-recollect-3-6/
          + 재수집 R-3 묶음 7 12사(보로노이 · 오스코텍 · 한미약품 · 케어젠 · 텔레칩스 · 리노공업 · 아모레퍼시픽 · 리메드 · 기업은행 · 효성중공업 · 대한항공 · 네오위즈) 125 → 229행
            · 케어젠 · 리노공업 · 리메드 3사는 공식 출처가 없어 사용자 제공 검색 AI 요약 기준(기준 39)
          2989 − 125 + 229 = 3093 (R-3 묶음 7 12사) — 운영은 표적 삭제 19 · 재코딩 7 뒤 멱등 적재
          (db/migrations/20261004_recollect_3_batch7.sql) — loupit-evidence/2026-10-02-recollect-3-7/
          + 재수집 R-3 묶음 6-B DB손해보험 15 → 19행 (자기 도메인 복리후생 페이지 붙여넣기 원문)
          3093 − 15 + 19 = 3097 (R-3 묶음 6-B DB손해보험) — 운영은 표적 삭제 4 뒤 멱등 적재
          (db/migrations/20261004_recollect_3_batch6b.sql) — loupit-evidence/2026-10-02-recollect-3-6/
          + R-3 후속 정리 2 — 복지 범위 규칙 개정(회사가 여는 어학 강좌도 복지 · 사내 대출은 용도 몰라도 복지 · 리프레시 휴가는 이름만 있어도 연차 외 휴가)으로
            예전에 뺀 행을 저장된 원문 사본으로 되살림 새 행 71 · 서술 합침 50 · 한미약품 연차 총량 분리 1 · 생활안정 대출 분리 2(삼성카드 · 대덕전자)
            · 퇴직금 누진제 새 코드 severance_plus 3(S-Oil · ㈜에코프로 · 에코프로비엠)
          3097 + 71 + 1 + 2 + 3 = 3174 (R-3 후속 정리 2) — 운영은 코드 바꾸기 7 뒤 멱등 적재
          (db/migrations/20261004_r3_followup_2.sql) — loupit-evidence/2026-10-04-r3-followup/
          + R-3 후속 정리 3 — LG에너지솔루션 leave_general 「월말휴무」 1행(사용자 결정 8a, 2026-10-01 검증 삭제를 되돌림 · 새 키 INSERT 라 마이그레이션 없음)
          3174 + 1 = 3175 (R-3 후속 정리 3)
          + R-3 후속 정리 5 — 보류 넣기 · 그림 · 붙여넣기: 새 행 11(기아 1 · 한미 1 · 보로노이 1 · 동진쎄미켐 1 · 심텍 2 · 대한항공 3 · 현대글로비스 2) · 삭제 0 · 마이그레이션 없음
          3175 + 11 = 3186 (R-3 후속 정리 5)
          + R-3 후속 6 — 엘앤에프 출처 이전 20 → 13(−11 + 4) — 운영은 표적 삭제 11 뒤 멱등 적재
          (db/migrations/20261005_landf_recollect.sql) — loupit-evidence/2026-10-05-hold-recollect/
          3186 − 11 + 4 = 3179 (R-3 후속 6)
          3179 (2026-10-05 엘앤에프 출처 이전 뒤)
          3179 + 293 = 3472 (확장 웨이브 5 — 13개사 · 수집 291 − 삭제 4 + 추가 6)
          3472 − 11 + 2 = 3463 (코퍼스 정리 4가지 — 웨이브 5 감사 후속, 2026-10-10 — 지금 핀)
    """
    count = _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY_BENEFIT")
    assert count == 3463, f"복지 총행 불일치: {count} (기대 3463 = 3472 − 11 + 2 코퍼스 정리 4가지; 3472 = 3179 + 293 확장 웨이브 5; 3179 = 3097 + 77 R-3 후속 정리 2 + 1 후속 정리 3 + 11 후속 정리 5 − 11 + 4 엘앤에프 출처 이전)"
    assert count >= 1200


# ── SD-5: 회사별 복지 ≥1 (복지 0개 회사 수 = 0) ──
def test_SD5_every_company_has_benefit(seeded_db):
    bad = _scalar(
        seeded_db,
        """
        SELECT COUNT(*) FROM TCOMPANY c
        LEFT JOIN TCOMPANY_BENEFIT b ON b.COMP_ID = c.COMP_ID
        WHERE b.BENEFIT_ID IS NULL
        """,
    )
    assert bad == 0


# ── SD-6: 회사별 별칭 ≥1 (별칭 0개 회사 수 = 0) ──
def test_SD6_every_company_has_alias(seeded_db):
    bad = _scalar(
        seeded_db,
        """
        SELECT COUNT(*) FROM TCOMPANY c
        LEFT JOIN TCOMPANY_ALIAS a ON a.COMP_ID = c.COMP_ID
        WHERE a.ALIAS_ID IS NULL
        """,
    )
    assert bad == 0


# ── SD-7: 프리셋 유형 커버 (freelance 제외 5유형 ≥1행, freelance=0행) ──
@pytest.mark.parametrize("type_cd", sorted(TYPE_CODES_5_NONFREELANCE))
def test_SD7_preset_covers_non_freelance_types(seeded_db, type_cd):
    count = _scalar(
        seeded_db,
        """
        SELECT COUNT(*) FROM TBENEFIT_PRESET p
        JOIN TCOMPANY_TYPE t ON t.COMP_TP_ID = p.COMP_TP_ID
        WHERE t.COMP_TP_CD = %s
        """,
        (type_cd,),
    )
    assert count >= 1, f"{type_cd} 유형 프리셋 0행"


def test_SD7_freelance_has_zero_presets(seeded_db):
    count = _scalar(
        seeded_db,
        """
        SELECT COUNT(*) FROM TBENEFIT_PRESET p
        JOIN TCOMPANY_TYPE t ON t.COMP_TP_ID = p.COMP_TP_ID
        WHERE t.COMP_TP_CD = 'freelance'
        """,
    )
    assert count == 0
