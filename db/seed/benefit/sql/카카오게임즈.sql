-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 카카오게임즈 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('kakao_games', '카카오게임즈',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '게임', 'K', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kakao_games');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '격주 4일제', NULL, 'flexibility',
   'est', NULL, TRUE, '월요일 10시반 출근/금요일 5시반 퇴근, 격주(월 2회) 주4일제(놀금)', 10),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합건강검진', 100, 'health',
   'est', '격해 배우자/부모님 양도 가능 (추정)', FALSE, NULL, 40),
  (@comp_id, 'insurance', '단체상해보험', 30, 'health',
   'est', '본인/배우자/자녀/양가부모 진단비+실손, 치과보험 포함, 본인 사망시 유가족 2억원 (추정)', FALSE, NULL, 41),
  (@comp_id, 'mental', '심리상담', NULL, 'health',
   'est', NULL, TRUE, '심리상담 연 8회 지원', 42),
  (@comp_id, 'fitness', '피트니스센터(건강해 GYM)', NULL, 'health',
   'est', NULL, TRUE, '전문 트레이너 상주, 헬스시설 및 다양한 GX 프로그램', 43),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'parenting', '슈퍼맘 서포트', NULL, 'family',
   'est', NULL, TRUE, '임신/출산 선물, 근무시간 변경, 임산부 정기검진 유급휴가, 난임휴가, 육아휴직', 50),
  (@comp_id, 'childcare', '어린이집(2개소)', NULL, 'family',
   'est', NULL, TRUE, '늘예솔 어린이집 및 오리뜰 2곳 지원', 51),
  (@comp_id, 'event', '경조사/생일/명절 지원', NULL, 'family',
   'est', NULL, TRUE, '생일 선물, 결혼 축의금, 조의금/장례서비스, 명절선물(카카오페이머니), 자녀입학 선물', 52),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'self_development', '자기계발비', 360, 'growth',
   'est', '연 360만원 자기계발비', FALSE, NULL, 60),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '제주 전용 휴양시설/리조트', 50, 'leisure',
   'est', '제주 섭지코지 프라이빗 숙소 1박+특별휴가, 롯데속초/대명/한화 리조트 회원가 (추정)', FALSE, NULL, 70),
  (@comp_id, 'massage', '마사지(사이다룸)', NULL, 'leisure',
   'est', NULL, TRUE, '전문 헬스키퍼 마사지, 안마의자/수면실', 71),
  (@comp_id, 'club', '동호회/캠핑 지원', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 활동 지원(등산/골프/필라테스), 캠핑카/캠핑용품 무상 대여', 72),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '점심 식대', 240, 'perks',
   'est', '월 20만원 점심 식대(점심시간 12:30~14:00)', FALSE, NULL, 80),
  (@comp_id, 'commute_subsidy', '통근버스', 120, 'perks',
   'est', '(추정)', FALSE, NULL, 81),
  (@comp_id, 'snack_bar', '모닝간식/카페/맥주', 144, 'perks',
   'est', '샌드위치/김밥/과일 모닝간식, 시리얼/라면/차/커피머신, 드래프트 맥주, 사내카페 (추정)', FALSE, NULL, 82),
  (@comp_id, 'discount', '카카오 서비스 지원', NULL, 'perks',
   'est', NULL, TRUE, '멜론스트리밍, 카카오 이모티콘플러스, 카카오페이지 캐시, 카카오프렌즈샵 20% 할인', 83),
  (@comp_id, 'housing_loan', '대출이자 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택구입/임차/생활안정금 대출이자 지원', 84)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
