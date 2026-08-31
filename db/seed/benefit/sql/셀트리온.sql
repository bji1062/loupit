-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 셀트리온 복리후생 데이터
-- 출처: AI 파싱 (2026-08-31)
-- URL: https://www.celltrion.com/ko-kr/careers/recruit/welfare
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- 참고: 근거는 전부 **셀트리온 공식 도메인**(celltrion.com) 채용 복지제도 페이지.
--       페이지는 금액을 일절 공개하지 않는다 — 금액이 있는 7행은 구본(2026-07)의
--       앵커 추정치를 유지한 것(금액정책 (a), 2026-08-31 결정: 서술·출처는 새 페이지,
--       금액은 기존 앵커 보존 → note 의 "추정" 표기로 DG-2 가 estimated 로 도출).
--       페이지 섹션 3개(의료 지원 / 사내 문화 및 편의, 자기 개발 / 가족 및 소득 지원) 기준.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('celltrion', '셀트리온',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '바이오/제약', 'C', 'https://www.celltrion.com/ko-kr/careers/recruit/welfare');

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'celltrion');

-- 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본은 NULL — INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.celltrion.com/ko-kr/careers/recruit/welfare'
 WHERE COMP_ID = @comp_id;

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강·의료 (health) ──
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '상해·질병에 대한 의료비 지원 (연 100만원 추정)', FALSE, NULL, 10),
  (@comp_id, 'insurance', '단체상해보험', 30, 'health',
   'est', '단체상해보험 가입 (연 30만원 추정)', FALSE, NULL, 11),
  (@comp_id, 'clinic', '건강관리실', NULL, 'health',
   'est', NULL, TRUE, '사내 건강관리실 운영', 12),
  (@comp_id, 'mental', '심리상담 지원', NULL, 'health',
   'est', NULL, TRUE, '심리상담 지원', 13),
  (@comp_id, 'health_check', '종합 건강검진', 100, 'health',
   'est', '종합 건강검진 지원(예방접종 포함) (연 100만원 추정)', FALSE, NULL, 14),
  (@comp_id, 'fitness', '사내 체육시설', NULL, 'health',
   'est', NULL, TRUE, '사내 야외 체육시설 이용 가능', 15),
  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '기숙사 지원', NULL, 'work_env',
   'est', NULL, TRUE, '기숙사(스튜디오실) 지원', 20),
  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'childcare', '임직원 어린이집', NULL, 'family',
   'est', NULL, TRUE, '임직원 자녀 대상 어린이집 운영', 30),
  (@comp_id, 'child_edu', '자녀 학자금/특수교육', NULL, 'family',
   'est', NULL, TRUE, '자녀학자금(미취학~고등학교) 및 장애 자녀 특수교육비 지원', 31),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '가족 및 본인 경조사 지원', 32),
  (@comp_id, 'homecoming', 'Home-coming 제도', NULL, 'family',
   'est', NULL, TRUE, 'Home-coming 제도 운영(가족 및 소득 지원 항목 — 세부 조건 미공개)', 33),
  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'lang', '어학교육비 지원', NULL, 'growth',
   'est', NULL, TRUE, '어학교육비 지원', 40),
  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '제휴 리조트', 50, 'leisure',
   'est', '주요 관광지 제휴 리조트 이용 (연 50만원 추정)', FALSE, NULL, 50),
  (@comp_id, 'club', '사내 동호회/문화체험', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 운영 및 지원, 사내 문화체험 클래스 운영', 51),
  (@comp_id, 'library', '전자 도서관', NULL, 'leisure',
   'est', NULL, TRUE, '전자 도서관 운영', 52),
  (@comp_id, 'guest_house', '영빈관', NULL, 'leisure',
   'est', NULL, TRUE, '영빈관 운영(연 1회 가족행사 이용 가능)', 53),
  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'commute_subsidy', '셔틀버스/콜택시', 120, 'perks',
   'est', '출퇴근 셔틀버스, 심야 퇴근 콜택시 지원 (연 120만원 추정)', FALSE, NULL, 60),
  (@comp_id, 'meal', '삼시세끼 식사 지원', 432, 'perks',
   'est', '아침·점심·저녁 식사 지원(서울사무소는 식대 지원) (연 432만원 환산 추정)', FALSE, NULL, 61),
  (@comp_id, 'welfare_point', '복지포인트', 200, 'perks',
   'est', '복지포인트 지급 (연 200만원 추정)', FALSE, NULL, 62),
  (@comp_id, 'birthday_gift', '생일포인트', NULL, 'perks',
   'est', NULL, TRUE, '생일포인트 지급', 63)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
