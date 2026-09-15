-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 삼성증권 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-14)
-- URL: https://www.samsungsecurities.co.kr/kor/recruit/benefit.do
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 정본은 자기 도메인 samsungsecurities.co.kr 의 인재채용 > 인사제도 > 복리후생 페이지다.
--       서버렌더 HTML 이라 헤드리스 불필요. 항목 24개가 div.benefit-item 4개 안의 span.bf-desc
--       라벨뿐이고 설명·금액이 없다.
--       ⚠ DART 홈페이지 값 samsungpop.com 은 거래 포털이라 채용·복지가 없다. 자기 도메인의 GNB 는
--          FnMenu.data.js 로 JS 렌더라 링크 크롤로는 복지 페이지에 닿지 않는다 — URL 을 직접 호출할 것.
--       보조 출처 = 삼성 채용사이트의 삼성증권 법인 전용 페이지 samsungcareers.com/subsid/detail/E40
--          (복지 섹션 #a6, 제목 「삼성증권의 근무 환경과 복지 제도」, 23항목 전부 한 줄 설명).
--          귀속 경로: /subsid/ → 금융 → 삼성증권 → /subsid/detail/E40. 같은 페이지에 주소
--          서초대로 74길 11 삼성증권 · 주요 업무 증권중개·자산관리·기업금융·자금운용 ·
--          홈페이지 samsungsecurities.co.kr 이 붙어 있다. 두 출처 모두 이 법인 공식 출처라
--          그룹 통합 채용 기준 각주는 붙이지 않았다(삼성화재와 같은 처리).
--       성장 2행(외국어·자격)의 비용 지원 근거로 자기 도메인 인사제도 > 인재양성 페이지
--          /kor/recruit/development.do 도 인용했다.
--       ⚠ 그룹 공통 /insight/welfare 는 한 건도 섞지 않았다. E40 원본의 samsungwelstory 링크는
--          형제 법인 페이지에도 똑같이 있는 채용공고 팝업 빈 틀이라 출처가 아니다.
--       라벨 수지: 정본 24 − 법정 1 = 23 + E40 전용 6(자기 개발 5 · GWP) − 제외 1(GWP) = 28 라벨.
--          복합 라벨 분해 +2(사택 및 교통비 → dormitory · transport, 장기 근속 휴가 및 휴가비 →
--          long_service_leave · long_service_bonus), 같은 코드 병합 −7(검진 2 → health_check,
--          경조 + 결혼 도움방 → event, 자녀 4 → child_edu, 심리 상담 + 힐링 명상 → mental,
--          금융석사 + 지역전문가 → mba) → 23행.
--       신규 코드 1개: weekend_farm (가족 주말농장 제공 — 어휘 86종에 같은 뜻이 없다. evidence 신규 코드 절).
--       금액: 두 출처 모두 원 단위 금액 0건 → 23행 전부 BENEFIT_AMT NULL · QUAL_YN TRUE.
--          자격 8종·45종은 개수이지 금액이 아니다. 신규 회사라 승계할 앵커도 없다.
--       법정 제도 미수록: 정본의 4대 보험 항목은 행으로 만들지 않았고 다른 행 서술에도 쓰지 않았다.
--       제외: GWP(조직문화 활동 소개 — 혜택 아님), 인재양성 페이지의 사내 교육 커리큘럼
--          (입문·리더십·WM아카데미·데이터 아카데미·사외 직무 교육·Learning Crew 등 — 비용 지원 문구 없음).
--       ⚠ 검증·감사 판정 반영(2026-09-15): 23 → 22행. 신규 코드 weekend_farm 기각 — SORT 74 가족 주말농장을
--       삭제하고 SORT 73 가족 친화 프로그램(company_event) 행에 흡수했다(위 신규 코드 1개·23행은 반영 전 수치).
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('samsung_sec', '삼성증권',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '증권', 'S', 'https://www.samsungsecurities.co.kr/kor/recruit/benefit.do');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_sec');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.samsungsecurities.co.kr/kor/recruit/benefit.do'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'housing_loan', '주택 구입 및 전세 자금 지원', NULL, 'perks',
   'est', NULL, TRUE, '임직원의 주택 구입 및 전세 자금 대출 지원 (공식 복리후생 페이지 생활 안정 지원 항목·삼성 채용사이트 삼성증권 소개 — 대출 한도·이율·대상 미기재)', 10),
  (@comp_id, 'transport', '교통비 지원', NULL, 'perks',
   'est', NULL, TRUE, '사택 및 교통비 지원 (공식 복리후생 페이지 생활 안정 지원 항목명 — 지원 대상·지원 방식·금액 미기재)', 11),
  (@comp_id, 'welfare_point', '선택형 복지 포인트', NULL, 'perks',
   'est', NULL, TRUE, '매년 현금처럼 사용할 수 있는 복지 포인트 지급 (공식 복리후생 페이지 기타/여가 생활 지원 항목·삼성 채용사이트 삼성증권 소개 — 연간 포인트 금액 미기재)', 12),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '사택 지원', NULL, 'work_env',
   'est', NULL, TRUE, '사택 및 교통비 지원 (공식 복리후생 페이지 생활 안정 지원 항목명 — 입주 대상·사택 형태·기간 미기재)', 20),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '경조 휴가·경조금·결혼 도움방', NULL, 'family',
   'est', NULL, TRUE, '경조사 발생 시 경조 휴가 및 경조금 지원, 결혼 도움방으로 사옥 결혼식장 무료 대관 등 지원 (공식 복리후생 페이지 생활 안정 지원·기타/여가 생활 지원 항목·삼성 채용사이트 삼성증권 소개 — 경조별 금액·휴가 일수·대관 이용 조건 미기재)', 30),
  (@comp_id, 'parenting', '출산선물·돌반지 지원', NULL, 'family',
   'est', NULL, TRUE, '출산선물, 돌반지 지원 (공식 복리후생 페이지 자녀 교육 지원 항목명 — 품목·금액 미기재)', 31),
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '직장 어린이집 운영 (공식 복리후생 페이지 자녀 교육 지원 항목·삼성 채용사이트 삼성증권 소개 — 정원·대상 연령·위치 미기재)', 32),
  (@comp_id, 'child_edu', '자녀 학자금·교복비·축하 선물', NULL, 'family',
   'est', NULL, TRUE, '임직원 자녀의 유치원·중/고등학교·대학교 학자금 지원, 중/고등학교 교복비 지원, 취학 축하/수능 격려 선물 제공, 자녀 문화/예술 활동 경험 지원 (공식 복리후생 페이지 자녀 교육 지원 항목·삼성 채용사이트 삼성증권 소개 — 지원 한도·자녀 수 제한·금액 미기재)', 33),

  -- ── 휴가 (time_off) ──
  (@comp_id, 'long_service_leave', '장기 근속 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기 근속 시 휴가 제공 (공식 복리후생 페이지 생활 안정 지원 항목·삼성 채용사이트 삼성증권 소개 — 근속 구간·휴가 일수 미기재)', 40),

  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'long_service_bonus', '장기 근속 휴가비', NULL, 'compensation',
   'est', NULL, TRUE, '장기 근속 시 휴가비 제공 (공식 복리후생 페이지 생활 안정 지원 항목·삼성 채용사이트 삼성증권 소개 — 근속 구간·휴가비 금액 미기재)', 50),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합 건강 검진·생애주기 검진', NULL, 'health',
   'est', NULL, TRUE, '임직원과 배우자 종합 건강 검진 지원, 생애주기 검진(PET-CT) 지원 (공식 복리후생 페이지 건강 지원 항목·삼성 채용사이트 삼성증권 소개 — 검진 주기·대상 연령·비용 한도 미기재)', 60),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '임직원과 가족의 의료비 지원 (공식 복리후생 페이지 건강 지원 항목·삼성 채용사이트 삼성증권 소개 — 지원 한도·가족 범위 미기재)', 61),
  (@comp_id, 'fitness', '휘트니스 센터', NULL, 'health',
   'est', NULL, TRUE, '임직원을 위한 휘트니스 센터 운영 (공식 복리후생 페이지 건강 지원 항목·삼성 채용사이트 삼성증권 소개 — 위치·이용 조건 미기재)', 62),
  (@comp_id, 'mental', '심리 상담 센터·힐링 명상 교육', NULL, 'health',
   'est', NULL, TRUE, '임직원을 위한 심리 상담 센터 운영, 마음 건강을 위한 힐링캠프 등 임직원 힐링 명상 교육 운영 (공식 복리후생 페이지 건강 지원·기타/여가 생활 지원 항목·삼성 채용사이트 삼성증권 소개 — 상담 횟수·가족 포함 여부·프로그램 주기 미기재)', 63),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '전국 리조트 이용 지원', NULL, 'leisure',
   'est', NULL, TRUE, '임직원이 자유롭게 사용할 수 있는 전국 리조트 이용 지원 (공식 복리후생 페이지 기타/여가 생활 지원 항목·삼성 채용사이트 삼성증권 소개 — 제휴처 목록·이용 한도 미기재)', 70),
  (@comp_id, 'leisure_ticket', '캐리비안베이 이용 지원', NULL, 'leisure',
   'est', NULL, TRUE, '매년 캐리비안베이를 자유롭게 이용할 수 있는 이용권 지원 (공식 복리후생 페이지 기타/여가 생활 지원 항목·삼성 채용사이트 삼성증권 소개 — 지급 매수·동반 인원 미기재)', 71),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 운영 및 임직원이 원하는 동호회 활동 지원 (공식 복리후생 페이지 기타/여가 생활 지원 항목·삼성 채용사이트 삼성증권 소개 — 활동비 한도·동호회 수 미기재)', 72),
  (@comp_id, 'company_event', '가족 친화 프로그램·가족 주말농장', NULL, 'leisure',
   'est', NULL, TRUE, '임직원 자녀와 함께하는 가족 친화 프로그램 운영, 임직원이 가족과 함께 이용할 수 있는 주말농장 제공 (공식 복리후생 페이지 기타/여가 생활 지원 항목·삼성 채용사이트 삼성증권 소개 — 프로그램 내용·개최 주기·참가 자격, 주말농장 위치·분양 면적·이용 기간 미기재)', 73),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'lang', '외국어 교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '어학교육 과정 운영, 어학 학습 및 어학 등급 취득 관련 비용 지원 (삼성 채용사이트 삼성증권 소개 자기 개발 지원 항목·공식 인재양성 페이지 — 지원 한도·대상 언어 미기재)', 80),
  (@comp_id, 'edu_support', '자격 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '증권업 관련 자격 취득 교육 과정과 취득 지원금 운영, 금융 및 컴플라이언스 필수 자격 8종과 업무 관련 전문 자격 45종 취득 지원 (삼성 채용사이트 삼성증권 소개 자기 개발 지원 항목·공식 인재양성 페이지 — 지원금 액수 미기재)', 81),
  (@comp_id, 'mba', '금융석사과정·지역전문가', NULL, 'growth',
   'est', NULL, TRUE, '금융전문가 양성을 위해 성균관대학교와 협업한 금융석사 과정 운영, 여러 국가에 파견해 현지 우수 사례와 문화를 학습하는 지역전문가 제도 운영 (삼성 채용사이트 삼성증권 소개 자기 개발 지원 항목 — 선발 인원·학비 지원 범위 미기재)', 82),
  (@comp_id, 'books', '도서 구입 지원', NULL, 'growth',
   'est', NULL, TRUE, '개인 도서 구입비 지원 (삼성 채용사이트 삼성증권 소개 자기 개발 지원 항목 — 연간 지원 금액 미기재)', 83)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
