-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SK쉴더스 복리후생 데이터 (신규 회사 — 웨이브 14)
-- 출처: AI 파싱 (2026-10-22)
-- URL: https://www.skshieldusapply.com/ko/culture
-- badge: est
--
-- 참고:
--   정본: 법인 자기 채용 도메인 www.skshieldusapply.com(그리팅 회사 계정 skshieldus.career.greetinghr.com 이
--     이 주소로 넘긴다) 근무환경 페이지 Education · Welfare 블록. SSR(원본 HTML 에 항목 글 · __NEXT_DATA__ 와 같은 판 하나).
--   귀속: 꼬리말 「에스케이쉴더스주식회사」 · 사업자등록번호 120-86-07747 = OpenDART company.json bizr_no 일치 ·
--     회사소개 페이지가 www.skshieldus.com 공식 홈으로 링크. 자기 홈 www.skshieldus.com 은 robots 부터 Akamai 403(호스트 전체 차단).
--   보조: OpenDART 2025 사업보고서(접수 20260331002340) 유연근무제도 사용 현황 표 · 이사회 내 위원회 활동내역 ·
--     연결재무제표 주석 19 종업원급여. 2026 반기보고서는 공시 목록에 없음 · 2026.03 분기보고서(20260515001241)에는 유연근무 표 없음.
--   그룹: 2023-08-02 SK 기업집단 계열제외(사업보고서 사채 절 · 특수관계자 주석) — SK 형제 대조 · 그룹 각주 없음.
--   금액: stated 0 · 추정 0 — 원문 원화 금액 0건, 14행 전부 NULL.
--   제외: 직무 교육(전문 교육 프로그램 · BP Job-Model 직무역량강화 · 공통 역량 위탁 · 입문 교육 · 직무전환 과정) ·
--     자격증 수당(급여성 수당) · 영업사원 계약 실적 성과급(계약원가 주석 · 급여 구성) · 육아휴직 · 배우자 출산휴가 통계(법정) ·
--     임원 · 경영진 보수 칸 · 주주 표 우리사주조합 칸(주식 없음).
--   공고 근거 0행 / 전체 14행.
--   SORT 섹션 순서: growth 10 · time_off 20 · compensation 30 · family 40 · health 50 · perks 60 · flexibility 70(공시만).
-- 검증 · 감사 판정 반영(2026-10-22): 특별휴가를 refresh_leave 에서 leave_general 로 재코딩(리드 판정 173 · 사유 휴가 묶음) · 장기근속자 포상 서술에서 연결재무제표 주석 계정 이름(장기근속수당) 구절을 뺌 · SK 기업집단 계열제외라 SK 그룹 메일 줄 없음 · 항목 페이지 예외 1(통합 밖 리드 집행) · 참고 블록의 보조 연결재무제표 주석 19 종업원급여 구절은 이 판정으로 뒤집힘 — 최종 14행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('sk_shieldus', 'SK쉴더스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '보안서비스', 'S', 'https://www.skshieldusapply.com/ko/culture');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'sk_shieldus');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.skshieldusapply.com/ko/culture'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 성장 · 교육 (growth) — 채용 사이트 근무환경 Education · Welfare ──
  (@comp_id, 'self_development', '자격증 취득·갱신 학습 지원', NULL, 'growth',
   'est', NULL, TRUE, '업무 유관 자격증 취득/갱신 학습 지원 제도 운영 (공식 채용 사이트 근무환경 페이지 Education 학습 지원 제도 항목) — 지원 금액·대상 자격증 범위 미기재', 10),
  (@comp_id, 'edu_support', '교육비 지원', NULL, 'growth',
   'est', NULL, TRUE, '사내외 교육비 지원 (공식 채용 사이트 근무환경 페이지 Welfare 교육비 지원 항목), 사외 교육 학습 지원 제도 운영 (같은 페이지 Education 학습 지원 제도 항목) — 지원 한도·대상 과정 미기재', 11),
  -- ── 휴가 (time_off) — 채용 사이트 근무환경 Welfare ──
  (@comp_id, 'leave_general', '특별휴가', NULL, 'time_off',
   'est', NULL, TRUE, '연/월차 외 특별휴가 지급 (공식 채용 사이트 근무환경 페이지 Welfare 특별휴가 항목) — 휴가 일수·부여 조건 미기재', 20),
  -- ── 보상 · 포상 (compensation) — 채용 사이트 근무환경 Welfare · 2025 사업보고서 ──
  (@comp_id, 'excellence_award', '우수사원 표창', NULL, 'compensation',
   'est', NULL, TRUE, '우수사원 표창, 연간 실적 우수 구성원 선정 및 일급 표창 수여 (공식 채용 사이트 근무환경 페이지 Welfare 우수사원 표창 항목) — 포상 내용·선정 인원 미기재', 30),
  (@comp_id, 'long_service_bonus', '장기근속자 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 구성원에 대한 감사와 격려 차원의 포상 지급 (공식 채용 사이트 근무환경 페이지 Welfare 장기근속자 포상 항목) — 근속 기준·포상 금액 미기재', 31),
  (@comp_id, 'incentive', '임직원 AIP 지급', NULL, 'compensation',
   'est', NULL, TRUE, '’24년 임직원 AIP 지급결과 보고, ’25년 임직원 AIP 지급 계획 가결 (2025 사업보고서 이사회 내 위원회 People & Culture 위원회 활동내역 항목) — 지급 기준·지급률 미기재', 32),
  -- ── 가족 (family) — 채용 사이트 근무환경 Welfare ──
  (@comp_id, 'event', '경조사비 지원', NULL, 'family',
   'est', NULL, TRUE, '본인, 가족의 결혼, 출산, 사망 시 경조금 지원 (공식 채용 사이트 근무환경 페이지 Welfare 경조사비 지원 항목) — 경조금 금액·경조휴가 미기재', 40),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '미취학 아동, 중고생 및 대학생 자녀 학자금 지원 (공식 채용 사이트 근무환경 페이지 Welfare 학자금 지원 항목) — 지원 금액·자녀 수 한도 미기재', 41),
  -- ── 건강 (health) — 채용 사이트 근무환경 Welfare ──
  (@comp_id, 'health_check', '종합 건강검진', NULL, 'health',
   'est', NULL, TRUE, '종합 건강검진 시행 및 지원 (공식 채용 사이트 근무환경 페이지 Welfare 건강검진 지원 항목) — 검진 주기·가족 포함 여부 미기재', 50),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '본인/가족 질병 의료비 지원 (공식 채용 사이트 근무환경 페이지 Welfare 의료비 지원 항목) — 지원 한도·가족 범위 미기재', 51),
  (@comp_id, 'mental', '심리상담', NULL, 'health',
   'est', NULL, TRUE, '온라인 앱을 통한 심리 상담 프로그램 지원 (공식 채용 사이트 근무환경 페이지 Welfare 심리상담 항목) — 이용 횟수·비용 지원 범위 미기재', 52),
  -- ── 생활 (perks) — 채용 사이트 근무환경 Welfare ──
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '복지몰 운영 및 현금 포인트 지급 (공식 채용 사이트 근무환경 페이지 Welfare 복지포인트 항목) — 포인트 금액·지급 시기 미기재', 60),
  -- ── 근무 유연성 (flexibility) — 2025 사업보고서 ──
  (@comp_id, 'flex_work', '시차출퇴근제·선택근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '시차 출퇴근제 사용자 2025년 493명·2024년 413명·2023년 361명, 선택근무제 사용자 2025년 190명·2024년 119명·2023년 6명 (2025 사업보고서 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 70),
  (@comp_id, 'remote_work', '원격근무제(재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무 포함) 사용자 2025년 191명·2024년 168명·2023년 316명 (2025 사업보고서 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 71)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
