-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CJ프레시웨이 복리후생 데이터
-- 출처: AI 파싱 (2026-07-30)
-- URL: https://www.cjfreshway.com/career/life/benefits.jsp
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- 참고: 근거는 전부 **CJ 소유 도메인**(3자 사이트 배제). CJ 는 그룹이 복지를 중앙에서
--       정하고 계열사가 얇은 층을 얹는 구조라, 아래 항목의 8~9할은 CJ 계열 공통이다.
--       계열사별로 실제 갈리는 축은 ①금액·한도 ②부문/계열사 전용 제도 두 가지뿐이다.
-- CJ 계열사 중 금액 공개가 가장 상세하다. 자사 채용 복리후생 페이지 기준.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('cj_freshway', 'CJ프레시웨이',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '식자재/급식', 'C', 'https://www.cjfreshway.com/career/life/benefits.jsp');

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'cj_freshway');

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
  -- ── 보상 (compensation) ──
  (@comp_id, 'long_service_bonus', '근속포상금', 1000, 'compensation',
   'est', 'CREATIVE WEEK 2주 유급휴가 + 10년 이상 근속자 50만원~최대 1,000만원. 표기값은 상한', FALSE, NULL, 82),
  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', NULL, 'health',
   'est', NULL, TRUE, '본인 및 배우자 건강검진 지원', 30),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '본인 부담금 10만원 이상 시 전액, 서울대학교병원 진료협약(Fast track 예약)', 31),
  (@comp_id, 'mental', '심리상담 서비스', NULL, 'health',
   'est', NULL, TRUE, '전문 심리상담 지원(브랜드명은 계열사별로 다름)', 32),
  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'parenting', '임신·출산·육아', NULL, 'family',
   'est', NULL, TRUE, '육아휴직 총 2년, 가족돌봄 연 10일 무급휴가 + 최대 90일 무급휴직', 40),
  (@comp_id, 'childcare', 'CJ키즈빌(직장 어린이집)', NULL, 'family',
   'est', NULL, TRUE, '사내 어린이집 CJ키즈빌 운영', 41),
  (@comp_id, 'child_edu', '자녀 학자금', 120, 'family',
   'est', '유치원 월 10만원 (연 120만원), 장애인 자녀 양육비 연 4회 총 720만원 별도', FALSE, NULL, 42),
  (@comp_id, 'event', '경조사 지원', 150, 'family',
   'est', '최대 7일 휴가 + 최대 150만원 경조금, 웨딩홀 대관료 150만원 지원', FALSE, NULL, 43),
  (@comp_id, 'fertility_support', '난임 지원', 680, 'family',
   'est', '난임 휴가 지원금 1년 최대 680만원, 여성 연간 총 6회·최대 42일 휴가', FALSE, NULL, 44),
  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'lang', '어학시험 응시료', NULL, 'growth',
   'est', NULL, TRUE, '연 2회 응시료 지원', 50),
  (@comp_id, 'edu_support', '사내외 교육 지원', 70, 'growth',
   'est', '연간 2회, 총 70만원 한도. 어학 연 2회·전화외국어 월 1회(총 12회) 별도', FALSE, NULL, 51),
  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '숙박·여가 지원', NULL, 'leisure',
   'est', NULL, TRUE, '제주 렌터카 1일 1만원(연 2회, 월 최대 5일), 나인브릿지 식음료 50% 할인', 60),
  (@comp_id, 'leisure_ticket', '티빙·CGV 이용권', NULL, 'leisure',
   'est', NULL, TRUE, '임직원 전용 티빙 프리미엄 이용권, CGV 영화관람권 및 특별관(IMAX·4DX·SCREENX) 40% 할인', 61),
  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '카페테리아 포인트', 75, 'perks',
   'est', '연간 75만원 상당 포인트(자기개발·여가·문화) + LIFE&HEALTHCARE 포인트 25만원 별도', FALSE, NULL, 70),
  (@comp_id, 'discount', 'CJ 계열사 할인', NULL, 'perks',
   'est', NULL, TRUE, 'CJ 계열사 40% 할인(뚜레쥬르·VIPS·올리브영·투썸·차이나팩토리·CJ더마켓 등), CJ온스타일 15% 할인, CJ Mall 임직원 특가', 71),
  (@comp_id, 'housing_loan', '주택자금 대출', NULL, 'perks',
   'est', NULL, TRUE, '2년 이상 재직자 대상 (한도 미표기)', 72),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '통근버스 5개 노선 운영', 73),
  (@comp_id, 'telecom', '통신사 제휴 할인', NULL, 'perks',
   'est', NULL, TRUE, '헬로모바일 40% 할인', 74)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
