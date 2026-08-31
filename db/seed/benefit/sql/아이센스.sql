-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 아이센스 복리후생 데이터
-- 출처: AI 파싱 (2026-08-31)
-- URL: https://recruit.i-sens.com/talent
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- 참고: 공식 채용사이트(recruit.i-sens.com, Ninehire 빌더)의 __NEXT_DATA__ SSR JSON에서 추출.
--       복리후생(/benefits)·인사제도(/hrm)·인재육성(/development)·FAQ(/faq) 페이지 전문 +
--       채용공고 2건(생산직)에서 하계휴가 복지포인트 60만원·추석 귀성여비 150만원 금액 확인.
--       구본(아이센스에프앤비 자회사 txt 기반 5행)은 전면 교체 — 유연근무제는 FAQ가
--       "09:00~18:00 근무"라 명시하여 이번 출처에서 확인 불가, 제외.
--       구본 앵커 금액(meal 432·snack_bar 30·discount 30)은 **오염 데이터(타사 기반)라
--       승계하지 않음** — 금액정책 (a) "기존 앵커 유지"의 예외(2026-08-31 결정).
--       금액 2건(150·60)은 공고 명시값 → note 에 추정 표기 없음 = DG-2 가 stated 도출.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('isens', '아이센스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '의료기기', 'I', 'https://recruit.i-sens.com/talent');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'isens');

-- 2-1) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본은 NULL — INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://recruit.i-sens.com/talent'
 WHERE COMP_ID = @comp_id;

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상 (compensation) ──
  (@comp_id, 'holiday_gift', '명절 귀성여비', 150, 'compensation',
   'est', '추석 귀성여비 150만원 — 2026-08 생산직 채용공고에 금액 명시(입사 시점에 따라 내규 기준, 지급 시점 재직자 한함). 인사제도 페이지의 고정상여 항목', FALSE, NULL, 10),
  (@comp_id, 'profit_sharing', '경영성과금', NULL, 'compensation',
   'est', NULL, TRUE, '회사 경영실적에 따라 전 임직원 대상 경영성과금 지급 가능(이익배분형) — 지급 여부·규모는 회사 성과에 따라 결정', 11),
  (@comp_id, 'excellence_award', '포상제도', NULL, 'compensation',
   'est', NULL, TRUE, '우수사원·직무발명자·우수제안자 포상제도 운영', 12),
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속자 포상제도 운영', 13),
  -- ── 근무환경 (work_env) ──
  (@comp_id, 'lounge', '직원 휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '안마의자, 운동기구 등 구비', 20),
  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'summer_leave', '하계휴가(유급)', 60, 'time_off',
   'est', '하계 유급휴가 + 하계휴가 복지포인트 60만원 — 2026-08 생산직 채용공고에 금액 명시(입사 시점에 따라 내규 기준)', FALSE, NULL, 30),
  (@comp_id, 'long_service_leave', 'Refresh 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 임직원 대상 유급휴가 및 복지포인트 지급', 31),
  (@comp_id, 'foundation_day_leave', '창립기념일 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '창립기념일 유급 휴가 및 복지포인트 지급', 32),
  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '단체 건강검진', NULL, 'health',
   'est', NULL, TRUE, '정기 건강검진 및 직원종합검진 지원', 40),
  (@comp_id, 'insurance', '단체 상해보험', NULL, 'health',
   'est', NULL, TRUE, '직무에 따른 단체상해보험 지원', 41),
  (@comp_id, 'mental', '직원 상담 프로그램', NULL, 'health',
   'est', NULL, TRUE, '상담 프로그램 지원을 통한 직무 스트레스 관리 지원', 42),
  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 발생 시 경조휴가, 경조금, 상조용품 지급', 50),
  (@comp_id, 'childcare', '보육수당', NULL, 'family',
   'est', NULL, TRUE, '미취학 자녀 보육수당 지급', 51),
  (@comp_id, 'child_edu', '자녀 입학축하금', NULL, 'family',
   'est', NULL, TRUE, '초/중/고/대학교 입학축하금 지급', 52),
  (@comp_id, 'parenting', '모성보호', NULL, 'family',
   'est', NULL, TRUE, '임신 축하 복지포인트·출산 축하금, 육아용품·당뇨관리 용품 지원, 아동 심리상담 지원 등', 53),
  (@comp_id, 'fertility_support', '난임 지원', NULL, 'family',
   'est', NULL, TRUE, '난임 지원 복지포인트 및 난임 휴가 유급 지원', 54),
  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'lang', '어학교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '전사 차원 외국어 교육 지원 제도 — 직무 무관 본인 희망 외국어 교육 프로그램 선택 학습', 60),
  (@comp_id, 'edu_support', '교육 프로그램', NULL, 'growth',
   'est', NULL, TRUE, '직무·역할별 교육 체계 운영 — 입문·Remind-Up·승진자·직책자 리더십 교육, 자기주도 직무교육, 특별·가치교육', 61),
  (@comp_id, 'books', '도서 지원', NULL, 'growth',
   'est', NULL, TRUE, '업무도서 구입비 지원, 사내도서관 운영(서초, 송도, 원주)', 62),
  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'welcome_kit', '신규입사자 웰컴패키지', NULL, 'leisure',
   'est', NULL, TRUE, '입사 시 아이센스의 핵심가치를 담은 웰컴패키지 지급', 70),
  (@comp_id, 'resort', '휴양시설 지원', NULL, 'leisure',
   'est', NULL, TRUE, '법인 콘도 운영', 71),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 운영 및 활동비 지급, 우수 동호회 포상', 72),
  (@comp_id, 'culture_day', '컬쳐데이', NULL, 'leisure',
   'est', NULL, TRUE, '연 1회 임직원 대상 컬쳐데이 실시(경영정보공유, 영화감상, 특강 등)', 73),
  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '중식 지원', NULL, 'perks',
   'est', NULL, TRUE, '중식비 포인트 지급(서울), 구내식당 운영(송도, 원주)', 80),
  (@comp_id, 'snack_bar', '사내 카페테리아', NULL, 'perks',
   'est', NULL, TRUE, '커피, 음료, 쿠키 등 구비', 81),
  (@comp_id, 'transport', '업무용 교통비 지원', NULL, 'perks',
   'est', NULL, TRUE, '업무상 주차비, 통행료, 유류비 지원', 82),
  (@comp_id, 'commute_subsidy', '셔틀버스', NULL, 'perks',
   'est', NULL, TRUE, '출퇴근 셔틀버스 운영(송도, 원주)', 83),
  (@comp_id, 'welfare_point', '선택적 복지제도', NULL, 'perks',
   'est', NULL, TRUE, '복지몰 운영 및 연간 복지포인트 지급(금액 미표기)', 84),
  (@comp_id, 'discount', '사내 제품 할인판매', NULL, 'perks',
   'est', NULL, TRUE, '혈당측정기 직원할인가 판매', 85)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
