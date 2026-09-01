-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- HD현대 복리후생 데이터
-- 출처: AI 파싱 (2026-09-01)
-- URL: https://recruit.hd.com/kr/mainLayout/benefit
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
--
-- 정본은 HD현대 그룹 통합 채용사이트(recruit.hd.com)의 복리후생 페이지다.
-- Vue SPA 라 HTML 셸에는 본문이 없고, 데이터는 정적 청크에 하드코딩되어 있다.
--   /kr HTML → /js/app.deed2f3e.js → 청크맵 → /js/5869.08a09a96.js 의 benefitList 상수.
--   ⚠ 파일명 해시는 재배포마다 바뀐다. 재수집 시 app.js 에서 3단 추적할 것.
--
-- ⚠ 귀속 주의 — 이 페이지는 지주회사 단독 복지가 아니라 그룹 공통 서술이다.
--   페이지 각주 원문: *복리후생은 계열사간 일부 상이할 수 있습니다.
--   사이트의 회사 필터 목록(allCompanyList 19개)에 HD현대(지주) 자체는 없다.
--   따라서 아래 19행은 원문 18항목 중 판교 GRC 본사·전사 공통 성격이 분명한 것만 남긴 것이고,
--   모든 행의 QUAL_DESC 에 (그룹 통합 채용 기준) 과 계열사 간 상이 가능 문구를 동반한다.
--   ⚠ 검증 판정 반영(2026-09-01): 그룹사 패밀리카드를 discount 행에 병합해 20행 → 19행,
--     통근버스 transport → commute_subsidy, 유류비 fuel_support → transport(유한양행 유류대 선례),
--     사내 병원 표기를 사옥 입주 병원 수준으로 완화(4층은 지역 개방 편의시설 층).
--   HD현대(지주) 직원은 GRC(경기 성남 판교, 그룹 대표 사옥) 근무이므로 GRC 태그 항목이 적용된다.
--
-- 제외 3항목(귀속 근거 부족 — 상세 사유는 HD현대.evidence.md):
--   기숙사        = 원문이 수도권 외 사업장 전용이라 명시. 지주 본사는 판교(수도권).
--   직원 휴식 지원 = 원문이 회사별 숙박 포인트 및 콘도라 명시. 지주 해당분 특정 불가.
--   생활안정      = 카테고리 머리글과 동일한 무내용 문구. 구체 급부 없음.
--
-- 금액: 명시값만 수록. 자녀 교육비 1건뿐이며 월 50만원 공식 명시를 연 600만원으로 적었다.
--   워케이션 최대 100만원(승진 1회성)과 유류비 월 15만원 이상(책임급 이상)은
--   연간 정기 급부가 아니거나 직급 게이트가 있어 금액 컬럼에 넣지 않고 서술로만 남긴다.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hd_hyundai', 'HD현대',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '지주회사', 'H', 'https://recruit.hd.com/kr/mainLayout/benefit');

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hd_hyundai');

UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://recruit.hd.com/kr/mainLayout/benefit'
 WHERE COMP_ID = @comp_id;

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 유연근무 (flexibility) ──
  (@comp_id, 'flex_work', '선택근로제', NULL, 'flexibility',
   'est', NULL, TRUE, '근무시간을 자유롭게 설계하는 선택 근로제 운영. 코어타임 10시~15시를 제외한 시간은 근무시간을 자유롭게 선택 (그룹 통합 채용 기준) 계열사 간 일부 상이 가능', 10),
  (@comp_id, 'remote_work', '재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '재택근무를 포함한 유연근무제 활용 가능 (그룹 통합 채용 기준) 계열사 간 일부 상이 가능', 11),
  (@comp_id, 'satellite_office', '거점 오피스', NULL, 'flexibility',
   'est', NULL, TRUE, '거점 오피스를 활용해 자유롭게 근무 가능 (그룹 통합 채용 기준) 계열사 간 일부 상이 가능', 12),
  (@comp_id, 'workation', '워케이션', NULL, 'flexibility',
   'est', NULL, TRUE, '선임 승진자 대상 워케이션 운영. 4박 5일간 전국 원하는 근무지에서 근무 가능하며 최대 100만원 비용 지원 (그룹 통합 채용 기준) 계열사 간 일부 상이 가능', 13),
  -- ── 근무환경 (work_env) ──
  (@comp_id, 'free_seating', '자율좌석제', NULL, 'work_env',
   'est', NULL, TRUE, '개인별 좌석을 지정하지 않고 업무 스케줄 등을 고려해 원하는 자리에 착석 (그룹 통합 채용 기준) 계열사 간 일부 상이 가능', 20),
  (@comp_id, 'office_furniture', '인체공학 사무가구', NULL, 'work_env',
   'est', NULL, TRUE, '인체공학 의자인 허먼밀러 의자와 모션 데스크 지원 (그룹 통합 채용 기준) 계열사 간 일부 상이 가능', 21),
  -- ── 휴가 (time_off) ──
  (@comp_id, 'summer_leave', '하기휴가', NULL, 'time_off',
   'est', NULL, TRUE, '법정 휴가 외 하기휴가를 최대 9일 제공 (그룹 통합 채용 기준) 계열사 간 일부 상이 가능', 30),
  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합검진', NULL, 'health',
   'est', NULL, TRUE, '건강한 삶을 지원하기 위한 종합 검진 지원 (그룹 통합 채용 기준) 계열사 간 일부 상이 가능', 40),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '의료비 지원 (그룹 통합 채용 기준) 계열사 간 일부 상이 가능', 41),
  (@comp_id, 'fitness', '헬스장 (GRC)', NULL, 'health',
   'est', NULL, TRUE, 'GRC 사옥 내 임직원 헬스장 운영 (그룹 통합 채용 기준) 계열사 간 일부 상이 가능', 42),
  (@comp_id, 'mental', '상담실 (GRC)', NULL, 'health',
   'est', NULL, TRUE, 'GRC 사옥 내 상담실 운영 — 몸과 마음의 건강을 위한 시설 (그룹 통합 채용 기준) 계열사 간 일부 상이 가능', 43),
  (@comp_id, 'clinic', '사옥 내 병원·마이밸런스센터(GRC)', NULL, 'health',
   'est', NULL, TRUE, 'GRC 사옥 내 입주 병원 이용 및 마이밸런스센터 운영 — 사내 의무실이 아니라 사옥 입주 의료시설이다 (그룹 통합 채용 기준) 계열사 간 일부 상이 가능', 44),
  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '만 0세~5세 학급으로 구성된 사내 어린이집 운영. 푸르니 표준보육 과정 기본에 체육·음악·영어 등 전문 프로그램 구성 (그룹 통합 채용 기준) 계열사 간 일부 상이 가능', 50),
  (@comp_id, 'child_edu', '자녀 교육비 지원', 600, 'family',
   'est', '만 4세~6세 자녀가 있는 직원에게 교육비 월 50만원 지급(연 600만원) — 그룹 통합 채용 복리후생 페이지 명시값 (그룹 통합 채용 기준) 계열사 간 일부 상이 가능', FALSE, NULL, 51),
  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '아침·점심·저녁 무료 제공', NULL, 'perks',
   'est', NULL, TRUE, '직원 식당에서 아침·점심·저녁을 무료로 제공하며 매일 10개 메뉴(중식 기준) 중 자유 선택. 끼니당 단가 미공개로 금액 미산정 (그룹 통합 채용 기준) 계열사 간 일부 상이 가능', 60),
  (@comp_id, 'snack_bar', '칸틴', NULL, 'perks',
   'est', NULL, TRUE, '전 층 칸틴 운영 — 신선한 원두가 채워진 에스프레소 머신, 각종 음료 및 스낵류 자유 이용 (그룹 통합 채용 기준) 계열사 간 일부 상이 가능', 61),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '수도권 내 다양한 구간의 복수 통근버스 운영 (그룹 통합 채용 기준) 계열사 간 일부 상이 가능', 62),
  (@comp_id, 'transport', '유류비 지원', NULL, 'perks',
   'est', NULL, TRUE, '책임급 이상 대상 매월 15만원 이상의 HD현대오일뱅크 주유 포인트 지급. 직급 게이트가 있어 금액 미산정 (그룹 통합 채용 기준) 계열사 간 일부 상이 가능', 63),
  (@comp_id, 'discount', '범현대 계열사 할인·그룹사 패밀리카드', NULL, 'perks',
   'est', NULL, TRUE, '현대자동차 5% 할인, 현대백화점 10% 할인 제공. 그룹사 패밀리카드 제공 및 연회비 지원 — 주요 혜택은 HD현대오일뱅크 리터당 150원 할인 및 하나머니 10% 적립 등 (그룹 통합 채용 기준) 계열사 간 일부 상이 가능', 64)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
