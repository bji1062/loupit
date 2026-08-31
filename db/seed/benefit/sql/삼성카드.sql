-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 삼성카드 복리후생 데이터
-- 출처: AI 파싱 (2026-08-31)
-- URL: https://www.samsungcard.com/company/recruit/human/policy/UHPPCI0167M0.jsp
-- 보조 URL: https://www.samsungcareers.com/subsid/detail/E31 (삼성 공식 채용사이트 —
--           「삼성카드의 근무 환경과 복지 제도」 섹션. 삼성카드 전용 서술.)
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- 참고: 근거는 전부 **삼성카드 소유 도메인(samsungcard.com) + 삼성 그룹 공식 채용사이트의
--       삼성카드 전용 페이지(samsungcareers.com/subsid/detail/E31)** 두 곳뿐이다.
--       samsungcareers.com/insight/welfare(그룹 공통 복지: 사내병원·사내식당·사내휘트니스·
--       통근버스·기숙사)는 **그룹 공통**이라 삼성카드 행으로 쓰지 않았다. 그 페이지 스스로
--       "관계사별 복지 제도는 각 회사별 페이지에서 확인 가능합니다"라고 명시한다.
-- ⚠ 금액 전면 삭제(금액정책 (a) — 오염 의심 → 승계 금지):
--       구본(2026-04-15) 헤더가 스스로 『원본 txt 파일 내용이 "에코비트"로 표기됨』이라고
--       적어 두었다. 즉 구본 7행의 서술·금액은 **삼성카드가 아닌 다른 회사 텍스트**에서
--       왔을 가능성이 명시돼 있다. 실제로 구본의 "헬스장 등록비 최대 55% 할인",
--       "창립기념 쌀", "단체보험", "임직원몰"은 삼성카드 공식 문서 어디에도 없다.
--       → 기존 앵커 6건(100/30/30/200/50/200만원)을 **전부 승계하지 않았다**.
--       현재 두 공식 출처 모두 금액을 일절 공개하지 않으므로 23행 전부 정성 항목이다.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('samsung_card', '삼성카드',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '금융/카드', 'S', 'https://www.samsungcard.com/company/recruit/human/policy/UHPPCI0167M0.jsp');

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_card');

-- 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본은 NULL — INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.samsungcard.com/company/recruit/human/policy/UHPPCI0167M0.jsp'
 WHERE COMP_ID = @comp_id;

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '정기 건강검진', NULL, 'health',
   'est', NULL, TRUE, '본인·배우자·부모 등 대상 주기적 건강검진 실시', 10),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '본인·자녀·배우자 의료비 지원', 11),
  (@comp_id, 'mental', '심리상담센터', NULL, 'health',
   'est', NULL, TRUE, '전문 상담사가 상주하는 사내 심리상담센터 운영', 12),
  -- ── 유연근무 (flexibility) ──
  (@comp_id, 'flex_work', '선택적 근무시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '의무근무시간과 선택근무시간을 구분한 탄력 근무 운영', 20),
  -- ── 근무환경 (work_env) ──
  (@comp_id, 'lounge', '사내카페', NULL, 'work_env',
   'est', NULL, TRUE, '임직원 전용 사내 카페 운영', 30),
  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'childcare', '사내어린이집', NULL, 'family',
   'est', NULL, TRUE, '임직원 전용 사내 어린이집 운영', 40),
  (@comp_id, 'child_edu', '자녀 학자금·소양개발비', NULL, 'family',
   'est', NULL, TRUE, '중·고·대학교 학자금 실비지원, 취학 전 아동 자녀소양개발비 지원', 41),
  (@comp_id, 'parenting', '육아휴직·모성보호제도', NULL, 'family',
   'est', NULL, TRUE, '육아휴직제도 및 단축근무 등 모성보호제도 운영', 42),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원 제도 운영', 43),
  (@comp_id, 'company_event', '가족친화 프로그램', NULL, 'leisure',
   'est', NULL, TRUE, '가족이 함께 참여하는 사내 가족친화 프로그램 기획·운영(사내 행사 — 코퍼스 family_day 는 조기퇴근 의미라 회피)', 44),
  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'self_development', '지역전문가 제도', NULL, 'growth',
   'est', NULL, TRUE, '글로벌 금융인재 양성을 위한 해외 파견 지역전문가 제도', 50),
  (@comp_id, 'mba', '삼성 MBA/EMBA·금융석사과정', NULL, 'growth',
   'est', NULL, TRUE, '국내외 MBA/EMBA 파견 및 성균관대 협업 금융석사과정 운영', 51),
  (@comp_id, 'edu_support', '전문 자격 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '데이터분석·마케팅·CFA·CPA·세무사 등 금융/비금융 자격 취득 지원', 52),
  (@comp_id, 'lang', '외국어 학습 지원', NULL, 'growth',
   'est', NULL, TRUE, '어학자격 취득 지원 및 어학교육 과정 운영', 53),
  (@comp_id, 'books', '도서구입 지원', NULL, 'growth',
   'est', NULL, TRUE, '도서구입 지원 및 독서휴가제도 운영', 54),
  (@comp_id, 'career', 'Job master 양성과정', NULL, 'growth',
   'est', NULL, TRUE, '직무별 사내 전문가 선발·양성 과정, 기본·리더십·직무 교육체계 운영', 55),
  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'club', '사내 동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '분야별 사내 동호회 활동 지원', 60),
  (@comp_id, 'resort', '휴양소·콘도 지원', NULL, 'leisure',
   'est', NULL, TRUE, '전국 휴양소 제휴, 콘도·캐리비안 베이 쿠폰 지원', 61),
  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '매년 복지포인트 지급, 복지몰에서 재화·서비스 구매', 70),
  (@comp_id, 'birthday_gift', '기념일 선물 지원', NULL, 'perks',
   'est', NULL, TRUE, '생일·결혼기념일 등 기념일에 임직원이 직접 선택한 선물 지급', 71),
  (@comp_id, 'housing_loan', '주택·생활안정자금 대출', NULL, 'perks',
   'est', NULL, TRUE, '주택구입/전세자금 대출 및 생활안정자금 대출', 72),
  (@comp_id, 'housing_support', '임차사택·주거안정지원', NULL, 'perks',
   'est', NULL, TRUE, '임차사택 제공 및 주거안정자금 지원', 73),
  (@comp_id, 'pension_support', '개인연금 지원', NULL, 'perks',
   'est', NULL, TRUE, '국민연금 외 개인연금 제도 운영 및 회사 지원', 74)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
