-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LG CNS 복리후생 데이터
-- 출처: AI 파싱 (2026-09-01)
-- URL: https://www.lgcns.com/kr/careers/benefits
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 LG CNS 공식 도메인(www.lgcns.com) 채용 복지 페이지 1건.
--       페이지는 금액을 일절 공개하지 않는다 — 전 행 무금액(QUAL_YN TRUE).
--       신규 회사라 금액 앵커가 없어 추정 금액을 넣지 않았다(계약 규칙 4).
--       원본 9개 대분류 32항목을 같은 코드 후보끼리 병합해 정리했고, 검증 판정에 따라
--       임신 축하 선물(fertility_support)과 명절 포인트(holiday_gift)를 다시 분리해 27행.
--       병합·분리 근거와 행별 원문 인용은 LGCNS.evidence.md 참조.
--       그룹 포털 careers.lg.com 은 ClaudeBot 차단 + SPA 라 미사용.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('lg_cns', 'LG CNS',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        'IT서비스', 'L', 'https://www.lgcns.com/kr/careers/benefits');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lg_cns');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (재실행 시 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.lgcns.com/kr/careers/benefits'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상 (compensation) ──
  (@comp_id, 'holiday_gift', '명절 복지 포인트', NULL, 'compensation',
   'est', NULL, TRUE, '설·추석 연 2회 명절 복지 포인트 제공', 10),

  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '자율책임근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '자율적 출퇴근 운영', 20),
  (@comp_id, 'satellite_office', '공유오피스 제공', NULL, 'flexibility',
   'est', NULL, TRUE, '패스트파이브·위워크 등 다양한 공유 오피스 지원', 21),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'refresh_leave', '안식휴가', NULL, 'time_off',
   'est', NULL, TRUE, '일정 근속 기준연한에 따라 유급휴가 및 휴가비 지급', 30),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합건강검진', NULL, 'health',
   'est', NULL, TRUE, '직원 및 배우자 종합건강검진 지원', 40),
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '상해·후유장해·3대 중대질병 진단·사망 보장 단체보험 가입 지원', 41),
  (@comp_id, 'medical', '중대 의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '중대한 질병·상해 의료비 지원', 42),
  (@comp_id, 'fitness', '사내 피트니스 센터', NULL, 'health',
   'est', NULL, TRUE, '사내 피트니스 시설 운영(마곡 사이언스파크)', 43),
  (@comp_id, 'mental', '사내 심리상담소·헬스테라피', NULL, 'health',
   'est', NULL, TRUE, '사내 심리상담소 및 헬스 테라피 운영', 44),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '사내 어린이집 운영(마곡/여의도/상암)', 50),
  (@comp_id, 'child_edu', '자녀 학자금·선물 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 성장 단계별 학업 비용 지원, 초등학교 입학 선물 및 대학수학능력시험 응시 자녀 응원 선물 지원', 51),
  (@comp_id, 'event', '경조사·결혼 축하 선물', NULL, 'family',
   'est', NULL, TRUE, '가족 경조사 경조비 및 물품 지원, 결혼 시 축하 선물 제공', 52),
  (@comp_id, 'fertility_support', '임신 축하 선물', NULL, 'family',
   'est', NULL, TRUE, '임신 시 축하 선물 제공', 53),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '학자금 이자 지원', NULL, 'growth',
   'est', NULL, TRUE, '학자금 대출 이자비용 지원', 60),
  (@comp_id, 'career', '자격증 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '응시전형료·협회비 등 자격증 취득 비용 지원', 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '프리미엄 콘도·골프 지원', NULL, 'leisure',
   'est', NULL, TRUE, '아난티·파라스파라(안토)·리솜·롯데·메리어트 및 곤지암 리조트 지원, 주중 임직원 골프 라운딩 지원', 70),
  (@comp_id, 'club', '사내 동아리', NULL, 'leisure',
   'est', NULL, TRUE, '다양한 인포멀(동아리) 활동 지원', 71),
  (@comp_id, 'sports_ticket', '프로 스포츠 관람 지원', NULL, 'leisure',
   'est', NULL, TRUE, '야구(LG 트윈스)·축구(FC서울) 티켓 지원', 72),
  (@comp_id, 'library', '전자도서관', NULL, 'leisure',
   'est', NULL, TRUE, '전자도서관 무료 이용(월 2권)', 73),
  (@comp_id, 'company_event', '사내 행사·참여 프로그램', NULL, 'leisure',
   'est', NULL, TRUE, '5월 가정의 달 가족친화 Family 프로그램, 프로젝트 현장 소통 프로그램(CEO 현장방문·PM DAY), 프로젝트 현장 방문 팀 빌딩 Care 프로그램(Party on Site), 디지털 코딩농활 사회공헌 프로그램', 74),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '매년 현금성 복지포인트 지급', 80),
  (@comp_id, 'pension_support', '과학기술인공제회 지원', NULL, 'perks',
   'est', NULL, TRUE, '과학기술인공제회 가입·이용 지원', 81),
  (@comp_id, 'commute_subsidy', '출퇴근 통근버스', NULL, 'perks',
   'est', NULL, TRUE, '약 220여개의 통근버스 노선 운행', 82),
  (@comp_id, 'discount', 'LG전자 가전 할인', NULL, 'perks',
   'est', NULL, TRUE, 'LG전자 제품 구매 시 임직원 할인', 83),
  (@comp_id, 'snack_bar', '사내 카페 행복마루', NULL, 'perks',
   'est', NULL, TRUE, '사내 카페 행복마루 운영, 저렴한 금액의 F&B 이용 가능', 84),
  (@comp_id, 'car_rental', '무료 전기차 대여', NULL, 'perks',
   'est', NULL, TRUE, '주말 무료 전기차 대여 지원', 85),
  (@comp_id, 'promotion_gift', '호칭 변경 기념 선물', NULL, 'perks',
   'est', NULL, TRUE, '선임 호칭 변경 시 고급 IT 기기 제공', 86)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
