-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 현대자동차 복리후생 데이터
-- 출처: AI 파싱 (2026-09-26)
-- URL: https://talent.hyundai.com/culture/benefit.hc
-- badge: est
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 참고:
--   정본 = 현대자동차 인재채용 Benefit (talent.hyundai.com/culture/benefit.hc). 법인 귀속은 페이지 제목
--     「현대자동차 인재채용」, 인라인 문안 「현대자동차는 다양한 혜택을 제공합니다」, 푸터 HYUNDAI MOTOR COMPANY.
--     원본 HTML 의 카드는 비어 있고 인라인 스크립트(LANG_CD 가 K 인 분기)가 jQuery html() 로 채운다 —
--     스크립트 문자열을 직접 읽었다(헤드리스 불필요). HTML 주석 안 구본 블록은 쓰지 않았다.
--     robots.txt = User-agent: * / Allow: / (2026-09-26 확인). 본문 sha256 7dcb04b7…a39a4 (09-25·09-26 동일).
--   보조 = 2026 현대자동차 지속가능성 보고서(발간 2026-06, 보고 기간 2025년) p.93·97·99·100·102·103
--     www.hyundai.com/content/hyundai/ww/data/csr/data/0000000054/attach/korean/hmc-2026-sustainability-report-ko.pdf
--     sha256 d0003444…9de9. 우리사주·경영성과금·심리상담·퇴직 예정자 지원·난임·유아교육비·바우처는 이 보고서에만 있다.
--   계열사(기아·현대모비스 등) 복지는 섞지 않았다. 그룹 통합 채용 페이지가 아니라 법인 자기 채용 사이트라 각주 없음.
--   법정 제도 제외: 채용 페이지의 출산휴가(여성 90일·남성 10일)·난임 연 3일은 2025-02 개정 전 법정 문안이라 행이 아니다.
--     배우자 출산휴가 20일·임신기 단축·태아 검진·육아시간·가족돌봄 휴직/휴가·육아기 단축도 법정 수준이라 뺐다.
--     회사 상회분(육아휴직 무급 1년 추가·출산휴가 잔여 30일 차액 보전·난임휴가 유급 5일·난임시술비)만 수록.
--   금액: 원문 명시 금액 0건. 구본 추정치 7행은 금액 정책 (a)로 (추정) 승계, 경조사 50은 1회성·휴가 근거라 승계 안 함.
--   구본 22개 코드 전부 유지(재코딩 0) · 기존 어휘 코드 8개 추가 · 신규 코드 0.
-- 재수집(2026-09-26): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다 — 대조 보고서 2026-09-25-official-compare
-- 감사(RA-1 2026-09-26) 반영: Hyundai Icon 수시 포상제도 추가 · 책임 진급 휴가 문안에서 별도 부여 단정 제거 · 퇴직 예정자 지원을 상시 경력 전환 프로그램으로 좁힘(법정 재취업지원 제외)

-- 1) 회사 등록 (기존 회사 — no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hyundai_motor', '현대자동차',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '자동차', 'H', 'https://talent.hyundai.com/culture/benefit.hc');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_motor');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://talent.hyundai.com/culture/benefit.hc'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무유연성 (flexibility) ── 채용 페이지 Work 카드 1~3
  (@comp_id, 'flex_work', '선택적 근로시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '핵심 근무시간(오전 10시~오후 4시) 외 출퇴근 시간을 개인별 상황에 따라 자율 선택, 일반직은 월 소정 근로시간 범위에서 1일 근로시간을 스스로 정하는 선택적 근로시간제 운영', 10),
  (@comp_id, 'satellite_office', '거점오피스(H-Work Station)', NULL, 'flexibility',
   'est', NULL, TRUE, '출퇴근 시간 단축과 유연한 업무를 위해 서울/경인 지역 8개 거점 오피스(H-Work Station) 운영', 11),
  (@comp_id, 'remote_work', '재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '재택근무를 정식 근무형태의 하나로 두고 재택근무에 필요한 사무기기와 인프라 지원', 12),

  -- ── 근무환경 (work_env) ── Work 카드 4 · Life
  (@comp_id, 'lounge', '휴게공간', NULL, 'work_env',
   'est', NULL, TRUE, '업무 중 휴식과 재충전을 위해 안마의자, 수면 등이 가능한 휴게공간 제공', 20),
  (@comp_id, 'dormitory', '사택/기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '임직원 생활 편의를 위한 사택/기숙사 지원', 21),

  -- ── 경제적 부가혜택 (perks) ── Work 카드 5·6 · Refresh · Life
  (@comp_id, 'commute_subsidy', '통근버스', 120, 'perks',
   'est', '사업장별 지역 특성과 교통편을 고려한 통근버스 운영 (추정)', FALSE, NULL, 30),
  (@comp_id, 'meal', '임직원 식당', NULL, 'perks',
   'est', NULL, TRUE, '위생적이고 영양가 높은 식사를 위해 사업장 내 임직원 식당 운영', 31),
  (@comp_id, 'snack_bar', '간식 코너', 50, 'perks',
   'est', '사업장 내 임직원 식당과 함께 간식 코너 지원 (추정)', FALSE, NULL, 32),
  (@comp_id, 'welfare_point', '여가생활 포인트', 200, 'perks',
   'est', '여행, 문화공연, 건강관리, 자기계발 등에 쓰는 여가생활 포인트와 선택적 복지제도, 장기휴가(하이파이브 휴가) 사용 시 복지포인트 지원 (추정)', FALSE, NULL, 33),
  (@comp_id, 'housing_loan', '주거지원금 대출', NULL, 'perks',
   'est', NULL, TRUE, '저리 장기의 주거지원금 대출 지원', 34),
  (@comp_id, 'discount', '차량 구입·수리 할인', NULL, 'perks',
   'est', NULL, TRUE, '본인 명의 차량 구입 시 차량 가격과 수리비용 할인, 차량관리를 위한 자가정비코너 운영', 35),

  -- ── 가족·돌봄 (family) ── Refresh · Life · Family · 보고서 p.100·103
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '최대 10일의 경조사 휴가와 경조금, 상조 서비스 등 경조사 지원', 40),
  (@comp_id, 'child_edu', '자녀 학자금', 200, 'family',
   'est', '자녀 교육비용 부담 완화를 위한 자녀 학자금 운영 (추정)', FALSE, NULL, 41),
  (@comp_id, 'parenting', '임신·출산·육아 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 1명당 육아휴직 최대 2년(무급 1년 추가), 출산 전후 휴가 잔여 30일의 정부 급여와 통상임금 차액 회사 보전, 임신 6개월~출산 2년 내 회사 지정 호텔 숙식(아이행복여행, 최대 2박), 만 4~5세 자녀 유아교육비, 자녀 출생·입학 시 물품 구입 바우처(엄마아빠 바우처) 지원', 42),
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '본사, 강남, 울산/아산/전주공장, 남양연구소 등 6곳에서 전문 위탁업체를 통한 직장 어린이집 운영', 43),
  (@comp_id, 'fertility_support', '난임 지원', NULL, 'family',
   'est', NULL, TRUE, '난임 시술 시 연 6일 난임휴가 중 5일 유급, 본인 및 배우자 난임시술 실비 지원', 44),

  -- ── 시간·휴가 (time_off) ── Refresh
  (@comp_id, 'summer_leave', '하기휴가', NULL, 'time_off',
   'est', NULL, TRUE, '자율적으로 사용 가능한 5일의 하기 휴가 지원', 50),
  (@comp_id, 'leave_general', '책임 진급 3주 휴가', NULL, 'time_off',
   'est', NULL, TRUE, 'Leadership Build-up Break — 책임 진급 시 리더로서의 새로운 준비를 위한 3주간의 유급 휴가 (지속가능성 보고서는 장기휴가 사용을 독려하는 제도로 기재 — 별도 휴가 부여 여부 미기재)', 51),

  -- ── 여가·라이프 (leisure) ── Refresh
  (@comp_id, 'resort', '사계절 휴양소', 50, 'leisure',
   'est', '전국 유명 호텔/리조트 중심의 사계절 휴양소 운영 (추정)', FALSE, NULL, 60),

  -- ── 건강·의료 (health) ── Health & Safety · 보고서 p.93·99·100
  (@comp_id, 'fitness', '짐나지움', NULL, 'health',
   'est', NULL, TRUE, '본사, 울산/아산/전주공장, 남양연구소 내 임직원 전용 피트니스 센터(짐나지움)와 운동 프로그램 운영', 70),
  (@comp_id, 'clinic', '사내 의원/약국', NULL, 'health',
   'est', NULL, TRUE, '사업장 내 의료기관(의원/약국) 운영', 71),
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '정기적 건강검진 지원 (추정)', FALSE, NULL, 72),
  (@comp_id, 'insurance', '단체상해보험', 30, 'health',
   'est', '단체상해보험제도 운영 (추정)', FALSE, NULL, 73),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '직원과 그 가족의 질병 또는 부상으로 발생하는 진료비 지원 (추정)', FALSE, NULL, 74),
  (@comp_id, 'mental', '심리상담·가족챙김 프로그램', NULL, 'health',
   'est', NULL, TRUE, '전사 심리상담센터와 함께 오은영 아카데미 협업 자녀 양육·부부관계·가족관계 테마 1:1 상담·코칭·검사 제공', 75),

  -- ── 성장·커리어 (growth) ── Career · 보고서 p.97
  (@comp_id, 'career', '주재원 기회/사내공모', NULL, 'growth',
   'est', NULL, TRUE, '해외 사업장 주재원 기회를 누구에게나 부여하는 글로벌 커리어 제도와 직무 변경 기회를 위한 사내공모제 운영', 80),
  (@comp_id, 'edu_support', '러닝랩 활동비', NULL, 'growth',
   'est', NULL, TRUE, '팀/부문을 넘어 구성원이 자발적으로 꾸린 학습 모임(러닝랩)의 활동비 지원', 81),
  (@comp_id, 'retirement_support', '상시 경력 전환 프로그램 (만 50세 이상 간부)', NULL, 'growth',
   'est', NULL, TRUE, '만 50세 이상 간부 사원 대상 재직 중 생애 설계·창업·재취업·자격증 취득 교육과 1:1 상담, 퇴직 후 약 1년간 전문 교육·컨설팅과 사후 관리 운영', 82),

  -- ── 보상·금전 (compensation) ── 보고서 p.100
  (@comp_id, 'stock_option', '우리사주제도', NULL, 'compensation',
   'est', NULL, TRUE, '정규 직원 전원을 대상으로 성과급의 일부를 주식으로 지급하는 우리사주제도와 우리사주 매입제도 운영', 90),
  (@comp_id, 'profit_sharing', '경영성과금', NULL, 'compensation',
   'est', NULL, TRUE, '매년 경영 성과에 따른 초과 이익을 모든 임직원에게 성과금으로 배분 — 지급률·금액 미기재', 91),
  (@comp_id, 'excellence_award', '수시 포상제도 Hyundai Icon', NULL, 'compensation',
   'est', NULL, TRUE, '일하는 방식을 HR 제도와 연계하며 신설한 수시 포상제도 Hyundai Icon — 포상 내용·선정 기준 미기재', 92)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
