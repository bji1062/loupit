-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 현대글로비스 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://glovis.recruiter.co.kr/career/benefit
-- badge: est
--
-- 참고:
--   정본은 현대글로비스 채용 사이트(마이다스 잡플렉스 ATS) 복리후생 페이지 /career/benefit 다.
--   제목 「현대글로비스 채용 | 복리후생」 · JSON-LD publisher 현대글로비스 · 회사 DNS recruit.glovis.net 이
--   이 ATS 를 가리킨다. 본문은 robots 전면 금지 API 에서만 와서 자동 수집기가 읽지 못한다.
--   원문 = 사이트 운영자가 2026-10-02 브라우저로 페이지를 열어 붙여 넣은 화면 본문
--   (사본 hyundai_glovis/user_paste_benefit_2026-10-02.txt · sha256 7ca4254c…ad22). 11항목.
--   보조 출처: 제25기(2025) 사업보고서 (공시서류제출일 2026-03-18 · 회사 홈 게시본 sha256 c0f40ec6…7820)
--     직원 등 현황 유연근무제도 사용 현황 표 — flex_work · remote_work 2행만 썼다. 임원 보수 산정기준은 쓰지 않았다.
--   귀속: 법인 단독 ATS 라 그룹 각주 없음. 현대자동차 talent.hyundai.com · 기아 · 현대모비스 · 현대건설 ·
--     현대오토에버 문구는 쓰지 않았다. 차량구입 지원도 이 페이지 문장으로만 적었다.
--   금액: 원문 명시 0 · 구본 추정 승계 4(health_check 100 · medical 100 · child_edu 200 · resort 50 —
--     전부 틀 값, NOTE 끝에 (추정)). welfare_point 는 구본 추정치가 없어 NULL.
--   구본에서 뺀 행: incentive (업적급 · 성과급 — 현행 원문에 없음) · edu_support (교육 프로그램 — 현행 원문에 없음) ·
--     refresh_leave (휴가제도 — 리프레시 휴가 및 장기휴가 지원, 일수 · 대상 · 유급 여부 미기재).
--   주택자금 지원 항목의 지방 근무자 사택은 dormitory 행으로 나눴다.
--   재코딩: 없음.
--   SORT 섹션 순서 = 원문에서 카테고리가 처음 나온 순서, 사업보고서 근거 행은 마지막 섹션
--     (perks 10 · work_env 20 · family 30 · health 40 · leisure 50 · flexibility 60).
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-4): 12행 전부 붙여넣기 원문 · 2025 사업보고서(OpenDART)와 글자 대조 · 휴가제도는 일수·추가 부여 미기재로 미수록 · 최종 12행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hyundai_glovis', '현대글로비스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '물류', 'H', 'https://glovis.recruiter.co.kr/career/benefit');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_glovis');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://glovis.recruiter.co.kr/career/benefit'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) — 복지포인트 · 주택자금 지원 · 차량구입 지원 ──
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '임직원 리프레쉬 지원을 위한 포인트 지급 (공식 채용 사이트 복리후생 복지포인트 항목) — 연간 배정액·사용처 미기재', 10),
  (@comp_id, 'housing_loan', '주택자금 지원 (결혼준비자금 포함)', NULL, 'perks',
   'est', NULL, TRUE, '주택구입(전/월세 포함) 및 결혼준비자금 지원 (공식 채용 사이트 복리후생 주택자금 지원 항목) — 대출·지급 등 지원 방식, 한도, 자격 요건 미기재', 11),
  (@comp_id, 'discount', '차량구입 지원', NULL, 'perks',
   'est', NULL, TRUE, '근속년수에 따라 현대기아차 구입비용 지원 (공식 채용 사이트 복리후생 차량구입 지원 항목) — 근속 구간별 지원 비율·한도 미기재', 12),

  -- ── 근무환경 (work_env) — 주택자금 지원 항목의 사택 ──
  (@comp_id, 'dormitory', '지방 근무자 사택', NULL, 'work_env',
   'est', NULL, TRUE, '지방 근무자에게 사택 지원 (공식 채용 사이트 복리후생 주택자금 지원 항목) — 대상 사업장·입주 조건·비용 부담 미기재', 20),

  -- ── 가족·돌봄 (family) — 자녀학자금 · 어린이집 운영 ──
  (@comp_id, 'child_edu', '자녀학자금', 200, 'family',
   'est', '임직원 자녀 학자금(유아교육, 대학교 등) 지원 (공식 채용 사이트 복리후생 자녀학자금 항목) — 지원 금액·자녀 수 제한 미기재 (추정)', FALSE, NULL, 30),
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '임직원 자녀 대상 직장 어린이집 운영 (공식 채용 사이트 복리후생 어린이집 운영 항목) — 위치·정원 미기재', 31),

  -- ── 건강·의료 (health) — 의료비 지원 · 건강/심리상담 · 건강검진 ──
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '임직원 본인과 직계 가족의 질병 및 상해에 대한 의료비 지원 (공식 채용 사이트 복리후생 의료비 지원 항목) — 지원 범위·한도 미기재 (추정)', FALSE, NULL, 40),
  (@comp_id, 'mental', '건강/심리상담', NULL, 'health',
   'est', NULL, TRUE, '전문 심리 및 전문 의료인 상담을 통해 임직원 스트레스 및 건강관리 지원 (공식 채용 사이트 복리후생 건강/심리상담 항목) — 이용 횟수·가족 이용 여부 미기재', 41),
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '임직원 및 가족의 건강관리를 위해 주기적으로 건강검진 실시 및 지원 (공식 채용 사이트 복리후생 건강검진 항목) — 검진 주기·지원 한도 미기재 (추정)', FALSE, NULL, 42),

  -- ── 여가·라이프 (leisure) — 휴양소 지원 ──
  (@comp_id, 'resort', '휴양소 지원', 50, 'leisure',
   'est', '전국 주요 관광지에 위치한 리조트를 임직원 할인금액으로 이용할 수 있도록 지원 (공식 채용 사이트 복리후생 휴양소 지원 항목) — 할인율·이용 일수 미기재 (추정)', FALSE, NULL, 50),

  -- ── 근무 유연성 (flexibility) — 사업보고서 유연근무제도 사용 현황 ──
  (@comp_id, 'flex_work', '시차출퇴근제·선택근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '시차출퇴근제·선택근무제 활용 (2025 사업보고서 직원 등 현황 유연근무제도 사용 현황) — 코어시간·대상 직무 미기재', 60),
  (@comp_id, 'remote_work', '원격근무제 (재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무 포함) 활용 (2025 사업보고서 직원 등 현황 유연근무제도 사용 현황) — 대상 직무·사용 조건 미기재', 61)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
