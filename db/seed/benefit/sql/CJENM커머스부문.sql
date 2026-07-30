-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CJ ENM 커머스부문 복리후생 데이터
-- 출처: AI 파싱 (2026-07-30)
-- URL: https://cjnews.cj.net/cj-enm-%EC%BB%A4%EB%A8%B8%EC%8A%A4-%EB%B6%80%EB%AC%B8-2023-%ED%95%98%EB%B0%98%EA%B8%B0-%EC%B1%84%EC%9A%A9-%EC%A7%81%EB%AC%B4-%EC%86%8C%EA%B0%9C/
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- 참고: 근거는 전부 **CJ 소유 도메인**(3자 사이트 배제). CJ 는 그룹이 복지를 중앙에서
--       정하고 계열사가 얇은 층을 얹는 구조라, 아래 항목의 8~9할은 CJ 계열 공통이다.
--       계열사별로 실제 갈리는 축은 ①금액·한도 ②부문/계열사 전용 제도 두 가지뿐이다.
-- CJ뉴스룸 커머스부문 채용 기사 + CJ ENM ESG REPORT 기준. CJ온스타일 운영 부문.
-- ⚠ 요청자가 제시한 cjonstylerecruit.ninehire.site 는 CJ 소유 도메인에서 링크되지
--    않아(전수 확인) 단독 근거로 쓰지 않았다. 그 페이지에만 있는 통신비 월 5만원 등의
--    금액은 **미기재**로 두고, 재직 인증 직원의 편집으로 채워지도록 남긴다.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('cj_enm_com', 'CJ ENM 커머스부문',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '커머스/홈쇼핑', 'C', 'https://cjnews.cj.net/cj-enm-%EC%BB%A4%EB%A8%B8%EC%8A%A4-%EB%B6%80%EB%AC%B8-2023-%ED%95%98%EB%B0%98%EA%B8%B0-%EC%B1%84%EC%9A%A9-%EC%A7%81%EB%AC%B4-%EC%86%8C%EA%B0%9C/');

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'cj_enm_com');

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
  (@comp_id, 'refresh_leave', '''쉴랜다'' 리프레시 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '커머스부문 전용 — 공휴일 없는 달·징검다리 휴일이 있는 달·연말 마지막 주 리프레시 휴가 사용 권장', 21),
  -- ── 보상 (compensation) ──
  (@comp_id, 'excellence_award', 'ONSTYLE Awards', NULL, 'compensation',
   'est', NULL, TRUE, '커머스부문 성과 포상 제도', 81),
  (@comp_id, 'long_service_bonus', '근속포상금', 500, 'compensation',
   'est', 'CREATIVE WEEK 근속포상 — 3·5·7년 근속 시 300~500만원 (2주 유급휴가 동반). 표기값은 상한', FALSE, NULL, 82),
  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', NULL, 'health',
   'est', NULL, TRUE, '만 35세 이상 종합검진, 배우자 격년 종합검진', 30),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '급여항목 본인부담금 10만원 이상 전액 지원', 31),
  (@comp_id, 'mental', 'EAP 심리상담', NULL, 'health',
   'est', NULL, TRUE, '위험도 1~5단계 진단, 4~5단계 집중케어', 32),
  (@comp_id, 'clinic', '사내 부속의원', NULL, 'health',
   'est', NULL, TRUE, '사옥 내 부속의원 운영', 33),
  (@comp_id, 'fitness', '사내 피트니스', NULL, 'health',
   'est', NULL, TRUE, '사옥 내 피트니스 운영', 34),
  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'parenting', '임신·출산·육아', NULL, 'family',
   'est', NULL, TRUE, '육아휴직 최대 2년 6개월(법정 1년 6개월 + 추가 1년), 자녀 초등 입학 선물, 산모 교실 연 2회(상·하반기), 배우자 출산휴가 법정 외 최대 14일 추가, 난임휴직', 40),
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '직장 어린이집 3개소 운영, 만5~6세 자녀 보육수당 별도', 41),
  (@comp_id, 'child_edu', '자녀 학자금', NULL, 'family',
   'est', NULL, TRUE, '유치원~대학교 학자금 지원', 42),
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
  (@comp_id, 'leisure_ticket', '티빙·CGV 이용권', NULL, 'leisure',
   'est', NULL, TRUE, '임직원 전용 티빙 프리미엄 이용권, CGV 영화관람권 및 특별관(IMAX·4DX·SCREENX) 40% 할인', 61),
  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '카페테리아 포인트', 100, 'perks',
   'est', '年 1,000p(100만원 상당) 지급, 개인별 needs 에 맞추어 사용', FALSE, NULL, 70),
  (@comp_id, 'discount', 'CJ 계열사 할인', NULL, 'perks',
   'est', NULL, TRUE, 'CJ온스타일 15% 할인(연 1,000만원 한도) + 추가 2,000만원 한도 내 8%, CJ 계열사 40% 할인, 티빙 프리미엄 이용권', 71),
  (@comp_id, 'housing_loan', '주택자금 대출', 10000, 'perks',
   'est', '주택자금 최대 1억원 대출 지원 (그룹 정본 2천만원 대비 상향)', FALSE, NULL, 72),
  (@comp_id, 'commute_subsidy', '출퇴근 지원', NULL, 'perks',
   'est', NULL, TRUE, '출근 셔틀버스, 야근 택시비 지원', 73),
  (@comp_id, 'telecom', '통신비 지원', NULL, 'perks',
   'est', NULL, TRUE, '통신비 지원 — 금액은 CJ 공식 출처에서 확인되지 않아 미기재', 74)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
