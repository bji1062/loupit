-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 현대건설 복리후생 데이터
-- 출처: AI 파싱 (2026-09-01)
-- URL: https://www.hdec.kr/kr/career/benefit.aspx
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 현대건설 공식 도메인(hdec.kr) 인사제도·복리후생 페이지.
--       「복리후생」 섹션 12개 항목 + 「교육제도」 섹션에서 회사의 명시적 비용 지원이
--       확인되는 2개 항목(어학교육 지원·외부교육 지원제도) = 14행.
--       같은 페이지의 인사제도 4항목(인력운영·평가·보상체계·승진)과 교육제도의
--       나머지 육성 프로그램은 복지가 아니므로 미수록(evidence 참조).
--       페이지는 금액을 일절 공개하지 않는다 — 14행 전부 정성(QUAL_YN TRUE),
--       BENEFIT_AMT NULL. 신규 회사라 금액 앵커도 없어 추정 금액을 넣지 않았다.
--       법정 제도(4대보험·퇴직연금·연차)는 페이지에도 없고 수록도 하지 않는다.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hyundai_enc', '현대건설',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '건설', 'H', 'https://www.hdec.kr/kr/career/benefit.aspx');

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_enc');

-- 기존 행의 CAREERS_BENEFIT_URL 갱신 (신규 등록이면 무변화, 재실행 시 URL 정정용)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.hdec.kr/kr/career/benefit.aspx'
 WHERE COMP_ID = @comp_id;

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', NULL, 'health',
   'est', NULL, TRUE, '임직원 건강 관리를 위해 연령·직급에 따라 건강검진 비용 지원', 10),
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '본인·배우자·자녀 직장단체보험 가입, 사고·질병 발생 시 의료비 지원', 11),
  (@comp_id, 'overseas_safety', '해외종합안전관리서비스', NULL, 'health',
   'est', NULL, TRUE, '해외 출장자·해외 근무자 대상 전문 의료·보안 정보 제공, 필요시 이송·후송 서비스 제공', 12),
  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '공조금 및 경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '결혼·출생·사망·퇴직 등 경조 발생 시 공조금, 화환 등 제공', 20),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '임직원 자녀 학자금 지원(대학교, 정부 무상교육 미지원 고교, 장애인학교)', 21),
  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'lang', '어학교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '영어 뿐 아니라 각종 제2외국어 등 다양한 어학교육을 지원 — 영어집중교육·영어 PT 스킬 향상 교육 실시, 전화외국어·온라인·모바일 교육과정 제공', 30),
  (@comp_id, 'edu_support', '외부교육 지원제도', NULL, 'growth',
   'est', NULL, TRUE, '개별 직무에 적합한 교육을 회사에서 제공하지 못하는 경우 외부교육에 참석할 수 있으며, 비용은 회사에서 지원', 31),
  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '휴양소 지원', NULL, 'leisure',
   'est', NULL, TRUE, '해비치 호텔&리조트 및 대명·한화 등 리조트 확보, 임직원 재충전 기회 제공', 40),
  (@comp_id, 'travel_support', '해외여행 지원', NULL, 'leisure',
   'est', NULL, TRUE, '2년 해외근무 시 본인 및 배우자 해외여행 지원', 41),
  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지카드', NULL, 'perks',
   'est', NULL, TRUE, '건강증진·레저·교육·문화생활 등에 사용 가능한 포인트 지급', 50),
  (@comp_id, 'discount', '차량구입지원금', NULL, 'perks',
   'est', NULL, TRUE, '임직원 차량 구입 시 직급·근속연수에 따라 할인 혜택 부여', 51),
  (@comp_id, 'welfare_fund_loan', '사내근로복지기금 대출', NULL, 'perks',
   'est', NULL, TRUE, '사내근로복지기금 운영, 복지기금 대출 지원(용도·한도 미공개)', 52),
  (@comp_id, 'relocation', '이사 비용 지원', NULL, 'perks',
   'est', NULL, TRUE, '현장 부임 시 이사 비용 지원', 53),
  (@comp_id, 'transport', '교통비 지원', NULL, 'perks',
   'est', NULL, TRUE, '단신부임 직원의 귀향 교통비 지원', 54)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
