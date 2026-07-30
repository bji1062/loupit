-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CJ올리브영 복리후생 데이터
-- 출처: AI 파싱 (2026-07-30)
-- URL: https://career.oliveyoung.com/ko/benefit
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- 참고: 근거는 전부 **CJ 소유 도메인**(3자 사이트 배제). CJ 는 그룹이 복지를 중앙에서
--       정하고 계열사가 얇은 층을 얹는 구조라, 아래 항목의 8~9할은 CJ 계열 공통이다.
--       계열사별로 실제 갈리는 축은 ①금액·한도 ②부문/계열사 전용 제도 두 가지뿐이다.
-- 자사 채용 Benefit 페이지 기준.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('cj_oliveyoung', 'CJ올리브영',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '화장품유통', 'C', 'https://career.oliveyoung.com/ko/benefit');

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'cj_oliveyoung');

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '탄력적·선택적 근무시간제, 시차출퇴근', 10),
  (@comp_id, 'satellite_office', 'CJ Work On 거점오피스', NULL, 'flexibility',
   'est', NULL, TRUE, '전국 거점 공유오피스 — 거점 목록은 계열사·시점별로 다름', 11),
  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'long_service_leave', 'CREATIVE WEEK(창의휴가)', NULL, 'time_off',
   'est', NULL, TRUE, '근속 3·5·7·10년(이후 5년마다) 2주 유급휴가, 연차 결합 시 최대 4주', 20),
  (@comp_id, 'leave_general', '시간 연차', NULL, 'time_off',
   'est', NULL, TRUE, '1시간 단위 연차 사용', 23),
  -- ── 보상 (compensation) ──
  (@comp_id, 'excellence_award', '인재추천포상금', 500, 'compensation',
   'est', '인재 추천 포상금 300~500만원. 표기값은 상한', FALSE, NULL, 81),
  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', NULL, 'health',
   'est', NULL, TRUE, '본인 및 배우자 건강검진 지원', 30),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '서울대학교병원 진료협약 Fast track 예약', 31),
  (@comp_id, 'mental', '마음디톡스 심리상담', NULL, 'health',
   'est', NULL, TRUE, '상담 비용 지원', 32),
  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'parenting', '임신·출산·육아', NULL, 'family',
   'est', NULL, TRUE, '육아휴직 최대 2년, 가족돌봄 연 최대 10일 + 최대 90일, 수험생 자녀 선물', 40),
  (@comp_id, 'childcare', 'CJ키즈빌(직장 어린이집)', NULL, 'family',
   'est', NULL, TRUE, '사내 어린이집 CJ키즈빌 운영', 41),
  (@comp_id, 'child_edu', '자녀 학자금', NULL, 'family',
   'est', NULL, TRUE, '유치원~대학생, 자녀 수 제한 없음', 42),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조금·경조휴가, 인재원 웨딩홀·웨딩카 지원', 43),
  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'lang', '어학시험 응시료', NULL, 'growth',
   'est', NULL, TRUE, '연 2회 응시료 지원', 50),
  (@comp_id, 'edu_support', '자기계발 지원', NULL, 'growth',
   'est', NULL, TRUE, '사내외 교육, K-Culture Voyage(KCON·MAMA 티켓·항공권 지원)', 51),
  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '숙박·여가 지원', NULL, 'leisure',
   'est', NULL, TRUE, '해외여행 경비 지원, 국내 숙소·제주 렌터카 할인, 나인브릿지 숙박 및 식음료 50% 할인', 60),
  (@comp_id, 'leisure_ticket', '여가 포인트', NULL, 'leisure',
   'est', NULL, TRUE, 'TVING 프리미엄 연간권·CGV 영화관람권·건강검진 — Life & Healthcare 25만원 상당', 61),
  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '카페테리아 포인트', 75, 'perks',
   'est', '카페테리아 포인트 연 75만원 상당(여행·자기계발·문화·운동) + Life & Healthcare 포인트 25만원 상당 별도', FALSE, NULL, 70),
  (@comp_id, 'discount', '올리브영·CJ 계열사 할인', NULL, 'perks',
   'est', NULL, TRUE, '올리브영 온·오프라인 전 제품 40% 할인 + 3·6·9·12월 올영세일 추가 할인 쿠폰, CJ 멤버스카드로 CJ 계열사 최대 40%', 71),
  (@comp_id, 'housing_loan', '주택자금 대출', 2000, 'perks',
   'est', '무이자 2천만원 주택자금 대출 (한도는 계열사별로 다름)', FALSE, NULL, 72),
  (@comp_id, 'commute_subsidy', '출퇴근 지원', NULL, 'perks',
   'est', NULL, TRUE, '출근 셔틀버스, 야근 택시비 지원', 73),
  (@comp_id, 'birthday_gift', '임직원 트렌드 쿠폰', 36, 'perks',
   'est', '매월 3만원 정액 쿠폰 (연 36만원)', FALSE, NULL, 75),
  -- ── 근무환경 (work_env) ──
  (@comp_id, 'work_tools', '업무 장비 선택', NULL, 'work_env',
   'est', NULL, TRUE, '입사 전 IT 장비 리스트에서 직접 선택', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
