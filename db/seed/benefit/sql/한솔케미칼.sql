-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 한솔케미칼 복리후생 데이터 (신규 회사 — 웨이브 5)
-- 출처: AI 파싱 (2026-10-10)
-- URL: https://hansolchemical.com/hr/
-- badge: est
--
-- 참고:
--   정본은 상장 법인 한솔케미칼의 자기 도메인 hansolchemical.com 인재채용 > 인사제도 페이지다.
--   리드 문장 주어가 「한솔케미칼은」 이라 법인 귀속이 확정된다. 그룹 채용사이트에는 복지 목록이 없고
--   형제 한솔테크닉스 복리후생 블록과 구성이 달라 그룹 템플릿이 아니다(프로브 대조) — 그룹 각주 없음.
--   WordPress 서버렌더 — 원본 HTML 의 ul.rps-ul 4묶음 li 19개에 항목 전문이 있다. 헤드리스 렌더 없음.
--   보조 출처 2개:
--     (a) 같은 사이트 헤더 메뉴 EN > Careers > Benefits 영문판 https://hansolchemical.com/en/hr/ —
--         국문에 없는 telecommuting 1건(remote_work)만 이 출처로 세웠다.
--     (b) 자기 도메인 esg-report 메뉴가 호스팅하는 2026 한솔그룹 지속가능경영보고서 국문 PDF
--         인쇄 94~95쪽(PDF 49쪽) 계열사별 여성 및 가족친화 제도 표의 한솔케미칼 행만(리드 판정 W5-4).
--         같은 표의 한솔제지 · 테이팩스 등 다른 계열사 행은 쓰지 않았다. 행 안의 주어가 법인이라 각주 없음.
--   금액: 원문에 원 · 만원 숫자 0건 — 24행 전부 BENEFIT_AMT NULL(정성). 정량은 Refresh 5일 유급 · 교육 연 4회뿐.
--   행 분할: 유연근무 · 조기퇴근 → flex_work · family_day / Refresh 휴가 · 휴가비 → refresh_leave · summer_vacation_subsidy /
--     기숙사 · 통근버스 → dormitory · commute_subsidy / 경조지원 → event(경조사비 · 장례서비스) · leave_general(경조휴가).
--   병합: 가족초청행사(정본) + 어린이 캠프 · 효도관광(보고서) → company_event 한 행.
--   제외: 법정(가족돌봄 휴가 · 휴직, 출산휴가, 육아휴직, 근로시간 단축, 임신 · 육아기 근로시간 단축 장려) ·
--     업무 교육(직무교육 프로그램의 직무 교육) · 보고서의 여성위원회 · 여직원 간담회(소통 기구) · 다른 계열사 행.
--   공고 근거 0행 / 전체 24행. 신규 코드 0.
--   SORT 섹션 순서 = 정본 첫 등장 순: flexibility 10 · time_off 20 · leisure 30 · perks 40 · health 50 ·
--     family 60 · growth 70 · compensation 80 · work_env 90.
-- 검증 · 감사 판정 반영(2026-10-10): 영문판 단독 재택근무 remote_work 삭제 · 그룹 보고서 주거비 지원 housing_support 를 주택대출이자 행 서술로 병합 — 최종 22행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hansol_chemical', '한솔케미칼',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체소재', 'H', 'https://hansolchemical.com/hr/');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hansol_chemical');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://hansolchemical.com/hr/'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — 정본 Work-Life Balance · 보고서 · 영문판 ──
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무 제도 운영 (공식 인재채용 인사제도 페이지 Work-Life Balance 항목), 유연근무제 운영 (2026 한솔그룹 지속가능경영보고서 94~95쪽 계열사별 여성 및 가족친화 제도 한솔케미칼 행) — 유연근무 유형·적용 대상 미기재', 10),
  (@comp_id, 'family_day', '조기퇴근제도', NULL, 'flexibility',
   'est', NULL, TRUE, '조기퇴근제도 운영 (공식 인재채용 인사제도 페이지 Work-Life Balance 항목) — 조기퇴근 주기·시간 미기재', 11),

  -- ── 휴가 (time_off) — 정본 Work-Life Balance · 더욱 먼 미래 ──
  (@comp_id, 'refresh_leave', 'Refresh 휴가 (5일 유급)', NULL, 'time_off',
   'est', NULL, TRUE, 'Refresh 휴가(5일 유급) (공식 인재채용 인사제도 페이지 Work-Life Balance 항목) — 부여 주기·부여 조건 미기재', 20),
  (@comp_id, 'leave_general', '경조휴가', NULL, 'time_off',
   'est', NULL, TRUE, '경조지원 항목의 경조휴가 (공식 인재채용 인사제도 페이지 더욱 먼 미래를 함께 꿈꾸는 회사 항목) — 경조 사유별 휴가 일수·유급 여부 미기재', 21),

  -- ── 여가 (leisure) — 정본 Work-Life Balance · 보고서 ──
  (@comp_id, 'summer_vacation_subsidy', '휴가비 지원', NULL, 'leisure',
   'est', NULL, TRUE, '휴가비 지원 (공식 인재채용 인사제도 페이지 Work-Life Balance 항목) — 지급 금액·지급 시기 미기재', 30),
  (@comp_id, 'resort', '임직원 휴양소', NULL, 'leisure',
   'est', NULL, TRUE, '임직원 휴양소 운영 (공식 인재채용 인사제도 페이지 Work-Life Balance 항목) — 휴양소 위치·이용 조건 미기재', 31),
  (@comp_id, 'club', '동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 지원 (공식 인재채용 인사제도 페이지 Work-Life Balance 항목) — 지원 금액·지원 방식 미기재', 32),
  (@comp_id, 'company_event', '가족초청행사·어린이 캠프·효도관광', NULL, 'leisure',
   'est', NULL, TRUE, '가족초청행사 (공식 인재채용 인사제도 페이지 Work-Life Balance 항목), 어린이 캠프 운영, 효도관광 운영 (2026 한솔그룹 지속가능경영보고서 94~95쪽 계열사별 여성 및 가족친화 제도 한솔케미칼 행) — 개최 주기·참가 대상·비용 부담 미기재', 33),

  -- ── 경제적 부가혜택 (perks) — 정본 건강하고 풍요로운 생활 · 더욱 먼 미래 · 보고서 ──
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '복지포인트 지급 (공식 인재채용 인사제도 페이지 건강하고 풍요로운 생활을 지원 항목) — 포인트 금액·지급 주기 미기재', 40),
  (@comp_id, 'housing_loan', '주택대출이자 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택대출이자 지원 (공식 인재채용 인사제도 페이지 더욱 먼 미래를 함께 꿈꾸는 회사 항목), 주거비 지원 (2026 한솔그룹 지속가능경영보고서 94~95쪽 계열사별 여성 및 가족친화 제도 한솔케미칼 행) — 지원 대상·한도·이자 지원율·주거비 지원 방식 미기재', 41),
  (@comp_id, 'pension_support', '개인연금 지원', NULL, 'perks',
   'est', NULL, TRUE, '개인연금 지원 (공식 인재채용 인사제도 페이지 더욱 먼 미래를 함께 꿈꾸는 회사 항목) — 회사 부담 비율·금액 미기재', 42),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '통근버스 운영 (공식 인재채용 인사제도 페이지 더욱 먼 미래를 함께 꿈꾸는 회사 항목) — 운행 사업장·노선·이용료 미기재', 43),

  -- ── 건강 (health) — 정본 건강하고 풍요로운 생활 · 보고서 ──
  (@comp_id, 'medical', '의료비 지원 (본인·배우자·자녀)', NULL, 'health',
   'est', NULL, TRUE, '의료비 지원(본인, 배우자 및 자녀, 의료보험 혜택과 별도) (공식 인재채용 인사제도 페이지 건강하고 풍요로운 생활을 지원 항목), 의료비 지원 (2026 한솔그룹 지속가능경영보고서 94~95쪽 계열사별 여성 및 가족친화 제도 한솔케미칼 행) — 지원 한도·본인 부담 비율 미기재', 50),
  (@comp_id, 'health_check', '종합검진 지원 (본인·배우자)', NULL, 'health',
   'est', NULL, TRUE, '종합검진 지원(본인, 배우자) (공식 인재채용 인사제도 페이지 건강하고 풍요로운 생활을 지원 항목), 건강검진 지원 (2026 한솔그룹 지속가능경영보고서 94~95쪽 계열사별 여성 및 가족친화 제도 한솔케미칼 행) — 검진 주기·검진비 지원 범위 미기재', 51),

  -- ── 가족 (family) — 정본 건강하고 풍요로운 생활 · 더욱 먼 미래 ──
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원(유치원, 중, 고, 대학생 자녀) (공식 인재채용 인사제도 페이지 건강하고 풍요로운 생활을 지원 항목) — 지원 한도·자녀 수 제한 미기재', 60),
  (@comp_id, 'event', '경조사비·장례서비스 지원', NULL, 'family',
   'est', NULL, TRUE, '경조지원 항목의 경조사비, 장례서비스 지원 (공식 인재채용 인사제도 페이지 더욱 먼 미래를 함께 꿈꾸는 회사 항목) — 경조 사유별 지급 금액·장례서비스 내용 미기재', 61),

  -- ── 성장 (growth) — 정본 도전과 학습을 통한 지속 성장 ──
  (@comp_id, 'mba', 'MBA·석박사 특별연수', NULL, 'growth',
   'est', NULL, TRUE, 'MBA, 석박사특별연수 통한 전문성 확보 (공식 인재채용 인사제도 페이지 도전과 학습을 통한 지속 성장 항목) — 선발 기준·지원 범위 미기재', 70),
  (@comp_id, 'lang', '어학 교육비 지원', NULL, 'growth',
   'est', NULL, TRUE, '글로벌 경쟁력 확보를 위한 어학 교육비 지원 (공식 인재채용 인사제도 페이지 도전과 학습을 통한 지속 성장 항목) — 지원 한도·대상 과정 미기재', 71),
  (@comp_id, 'conference', '국제 포럼·학회·세미나 참가비 지원', NULL, 'growth',
   'est', NULL, TRUE, '국제 포럼, 학회, 세미나 등 참가비 지원 (공식 인재채용 인사제도 페이지 도전과 학습을 통한 지속 성장 항목) — 지원 한도·대상 행사 기준 미기재', 72),
  (@comp_id, 'edu_support', '자격증·외국어 교육 지원 (연 4회)', NULL, 'growth',
   'est', NULL, TRUE, '직무교육 프로그램 운영 (직무/자격증/외국어 교육 연 4회 지원) 중 자격증·외국어 교육 (공식 인재채용 인사제도 페이지 도전과 학습을 통한 지속 성장 항목) — 과정 범위·비용 지원 범위 미기재', 73),

  -- ── 보상 (compensation) — 정본 더욱 먼 미래 ──
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 포상 (공식 인재채용 인사제도 페이지 더욱 먼 미래를 함께 꿈꾸는 회사 항목) — 근속 연수 기준·포상 내용 미기재', 80),

  -- ── 근무 환경 (work_env) — 정본 더욱 먼 미래 ──
  (@comp_id, 'dormitory', '기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '기숙사 운영 (공식 인재채용 인사제도 페이지 더욱 먼 미래를 함께 꿈꾸는 회사 항목) — 입주 대상·사업장 미기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
