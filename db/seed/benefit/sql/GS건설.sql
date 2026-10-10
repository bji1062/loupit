-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- GS건설 복리후생 데이터 (신규 회사 — 웨이브 5)
-- 출처: AI 파싱 (2026-10-10)
-- URL: https://www.gsenc.com/FileUpload/Bbs_New/2026%20GS%EA%B1%B4%EC%84%A4%20%EC%A7%80%EC%86%8D%EA%B0%80%EB%8A%A5%EA%B2%BD%EC%98%81%EB%B3%B4%EA%B3%A0%EC%84%9C_%EA%B5%AD%EB%AC%B8_2.pdf
-- badge: est
--
-- 참고:
--   정본은 GS건설 자기 도메인 www.gsenc.com 이 IR 목록(투자정보 > Sustainability Report)에 올린
--   2026 GS건설 지속가능경영보고서 국문 PDF(154쪽, 2026년 6월 발간, 보고 기간 2025-01-01~12-31)다.
--   주 출처 90쪽 임직원 복리후생 프로그램 표(5구분 21불릿)와 같은 쪽 본문 3문단.
--   보조 출처는 같은 보고서 84쪽 임직원 육성 프로그램 표 · 86쪽 어학능력 향상 교육과정 · Study with Me ·
--   88쪽 임직원 경험 개선 프로그램 · 89쪽 합리적 보상체계 운영 · 솔직톡톡 · 124쪽 임직원 보수 표.
--   GRI 인덱스 137쪽이 GRI 401-2 정규직 복리후생을 90쪽으로 가리킨다.
--   렌더 방식은 PDF 텍스트 레이어(pypdf 추출) — 이미지 판독 · 헤드리스 렌더 없음. 프로브 사본 재사용.
--   채용 ATS gsenc.recruiter.co.kr 복리후생은 원본 HTML 에 항목 0, 공고 iframe 호스트 recruit.gsenc.com 은
--   robots 전면 금지라 쓰지 않았다.
--   귀속: 문장 주어가 전부 GS건설은 이고 보고 범위가 본사 · 국내외 139개 사업장이다. 그룹 공통 문구가 아니라
--   각주 없음. 72쪽 협력회사 복리후생 · 75쪽 자회사 · 131~133쪽 자이S&D · 자이C&A · GPC 데이터는 끌어오지 않았다.
--   금액: 보고서에 임직원 복지 원 단위 금액 0건 — 21행 전부 BENEFIT_AMT NULL(stated 0 · 추정 0).
--   보육지원비 최대 96개월 · 시차출퇴근 시간대는 기간 · 조건이라 서술에만 남겼다.
--   제외: 법정(임신 · 육아기 단축 근무, 가족 돌봄 휴가 · 휴직, 난임 치료 휴가, 남성 육아휴직 사용 문화 활성화,
--   권장휴가제, 86쪽 전직 지원 프로그램 — 직원 약 5천 명이라 재취업지원 의무) · 업무 교육(84~87쪽 온보딩 ·
--   계층 캠프 · 예비 PD · CM · AI 교육 · 경영 리더 육성 · GS Explore and Create · Recharge 캠프) ·
--   옥외 조경 SKY Garden · 로비 조형물 · 모바일 사원증 · 다른 법인 문장.
--   공고 근거 0행 / 전체 21행.
--   SORT 섹션 순서 = 90쪽에서 카테고리가 처음 나온 순서
--   (flexibility 10 · time_off 20 · work_env 30 · family 40 · perks 50 · health 60),
--   보조 쪽에만 있는 카테고리는 쪽 순서로 끝에 (growth 70 · leisure 80 · compensation 90).
--   perks 52 스낵바는 89쪽 보조 출처지만 perks 섹션이 이미 있어 그 안에 붙였다.
-- 검증 · 감사 판정 반영(2026-10-10): 시차출퇴근제 행에서 휴가 적립 안식휴가 구절을 걷어 leave_general 안식휴가 (휴가 적립형) 행으로 · 성과급을 124쪽 보수 표 관리직 성과급으로 좁힘 · 조직 성과 포상 excellence_award 추가 — 최종 23행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('gs_enc', 'GS건설',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '건설', 'G', 'https://www.gsenc.com/FileUpload/Bbs_New/2026%20GS%EA%B1%B4%EC%84%A4%20%EC%A7%80%EC%86%8D%EA%B0%80%EB%8A%A5%EA%B2%BD%EC%98%81%EB%B3%B4%EA%B3%A0%EC%84%9C_%EA%B5%AD%EB%AC%B8_2.pdf');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'gs_enc');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.gsenc.com/FileUpload/Bbs_New/2026%20GS%EA%B1%B4%EC%84%A4%20%EC%A7%80%EC%86%8D%EA%B0%80%EB%8A%A5%EA%B2%BD%EC%98%81%EB%B3%B4%EA%B3%A0%EC%84%9C_%EA%B5%AD%EB%AC%B8_2.pdf'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — 2026 지속가능경영보고서 90쪽 ──
  (@comp_id, 'flex_work', '시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '시차 출퇴근제 운영(07:30~10:00 / 10분 단위 자율 출퇴근), 육아·업무 등 개인 필요에 따른 출퇴근 시간 자율 조정 (2026 지속가능경영보고서 90쪽 임직원 복리후생 프로그램 표 유연 근무제 운영 항목) — 출퇴근 시간 선택 주기·신청 절차 미기재', 10),
  (@comp_id, 'pc_off', 'PC On·Off 프로그램', NULL, 'flexibility',
   'est', NULL, TRUE, '정시출퇴근 활성화를 위한 PC On·Off 프로그램 운영(퇴근시간 시 PC 자동 종료로 효율적인 근무시간 관리) (2026 지속가능경영보고서 90쪽 임직원 복리후생 프로그램 표 유연 근무제 운영 항목) — 종료 시각·예외 신청 절차 미기재', 11),

  -- ── 휴가 (time_off) — 2026 지속가능경영보고서 90쪽 ──
  (@comp_id, 'summer_leave', '하계휴가 연중 자율 사용', NULL, 'time_off',
   'est', NULL, TRUE, '연차와 별도로 부여되는 하계휴가를 연중 자율적으로 사용 (2026 지속가능경영보고서 90쪽 일하기 좋은 여건 조성 본문, 임직원 복리후생 프로그램 표 휴가 제도 강화 항목) — 휴가 일수·유급 여부 미기재', 20),
  (@comp_id, 'long_service_leave', '장기근속 안식휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속자 대상 안식휴가 추가 지원 (2026 지속가능경영보고서 90쪽 임직원 복리후생 프로그램 표 휴가 제도 강화 항목) — 근속 기준·휴가 일수·유급 여부 미기재', 21),
  (@comp_id, 'leave_general', '안식휴가 (휴가 적립형)', NULL, 'time_off',
   'est', NULL, TRUE, '휴가 적립을 통한 안식휴가제도 운영 (2026 지속가능경영보고서 90쪽 임직원 복리후생 프로그램 표 휴가 제도 강화 항목, 일하기 좋은 여건 조성 본문) — 적립 재원·기간·유급 여부 미기재', 22),

  -- ── 근무 환경 (work_env) — 2026 지속가능경영보고서 90쪽 ──
  (@comp_id, 'lounge', '자이로움 라운지', NULL, 'work_env',
   'est', NULL, TRUE, '사무실 내 임직원 전용 휴게 공간인 자이로움 라운지(티타임과 독서를 즐길 수 있는 공간, 안마의자, 간이 오락 시설) (2026 지속가능경영보고서 90쪽 임직원을 위한 휴식과 소통 공간 조성 본문) — 설치 사업장·이용 시간 미기재', 30),

  -- ── 가족 (family) — 2026 지속가능경영보고서 90쪽 ──
  (@comp_id, 'parenting', '출산·육아 지원 (추가 육아휴직 1년)', NULL, 'family',
   'est', NULL, TRUE, '출산 축하금·축하선물 지원, 산후조리원 비용 지원, 보육지원비 최대 8년(96개월) 지원, 법정 육아휴직 외 최대 1년 추가 육아휴직 제공 (2026 지속가능경영보고서 90쪽 임직원 복리후생 프로그램 표 임신·출산·육아 지원 항목) — 축하금·지원 금액, 보육지원비 대상 연령, 추가 휴직 유급 여부 미기재', 40),
  (@comp_id, 'fertility_support', '난임 시술비·난임 휴직', NULL, 'family',
   'est', NULL, TRUE, '난임 시술비 지원, 난임 휴직 제공 (2026 지속가능경영보고서 90쪽 임직원 복리후생 프로그램 표 임신·출산·육아 지원 항목, 가족친화 복리후생 지원 본문) — 시술비 지원 금액·횟수, 휴직 기간·유급 여부 미기재', 41),
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '직장 어린이집 운영 (2026 지속가능경영보고서 90쪽 임직원 복리후생 프로그램 표 임신·출산·육아 지원 항목) — 설치 사업장·정원·이용 대상 연령 미기재', 42),
  (@comp_id, 'disability_family_support', '장애인 가족 지원제도', NULL, 'family',
   'est', NULL, TRUE, '장애인 가족 지원제도 운영(장애 자녀 교육비·의료비 지원, 보조기기 구입비 지원, 장애가정 구성원 심리 상담 제공) (2026 지속가능경영보고서 90쪽 임직원 복리후생 프로그램 표 가족 돌봄 지원 항목) — 지원 금액·한도·대상 장애 범위 미기재', 43),

  -- ── 경제적 부가혜택 (perks) — 2026 지속가능경영보고서 90쪽 · 89쪽 ──
  (@comp_id, 'relocation', '해외근무 가족 동반 이사비', NULL, 'perks',
   'est', NULL, TRUE, '해외근무 임직원 가족 동반지원 체계 확장(이사비 지원 확대) (2026 지속가능경영보고서 90쪽 임직원 복리후생 프로그램 표 가족 돌봄 지원 항목) — 지원 금액·대상 국가·동반 가족 범위 미기재', 50),
  (@comp_id, 'housing_support', '해외근무 가족 동반 주택 임차 비용', NULL, 'perks',
   'est', NULL, TRUE, '해외근무 임직원 가족 동반지원 체계 확장(주택 임차 비용 지원 확대) (2026 지속가능경영보고서 90쪽 임직원 복리후생 프로그램 표 가족 돌봄 지원 항목) — 지원 금액·한도·대상 국가 미기재', 51),
  (@comp_id, 'snack_bar', '스낵바', NULL, 'perks',
   'est', NULL, TRUE, '임직원 요구사항을 반영한 스낵바 물품 구성 다양화 (2026 지속가능경영보고서 89쪽 임직원의 목소리를 듣는 솔직톡톡 본문) — 운영 사업장·이용 비용 미기재', 52),

  -- ── 건강 (health) — 2026 지속가능경영보고서 90쪽 ──
  (@comp_id, 'health_check', '임직원·배우자 정기 건강검진', NULL, 'health',
   'est', NULL, TRUE, '임직원·배우자 정기 건강검진(비용) 지원, 검진 당일 근무시간 인정 (2026 지속가능경영보고서 90쪽 임직원 복리후생 프로그램 표 구성원 건강 관리 지원 항목) — 검진 주기·지원 금액·검진 항목 미기재', 60),
  (@comp_id, 'medical', '임직원·배우자 실손 보험', NULL, 'health',
   'est', NULL, TRUE, '임직원과 배우자 대상 실손 보험 가입 지원 (2026 지속가능경영보고서 90쪽 임직원 복리후생 프로그램 표 구성원 건강 관리 지원 항목) — 보장 범위·회사 부담 비율 미기재', 61),
  (@comp_id, 'insurance', '임직원 단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '임직원 단체상해보험 지원 (2026 지속가능경영보고서 90쪽 임직원 복리후생 프로그램 표 구성원 건강 관리 지원 항목) — 보장 범위·보험금 미기재', 62),
  (@comp_id, 'mental', 'Stress Zero Program 심리상담', NULL, 'health',
   'est', NULL, TRUE, 'Stress Zero Program 운영(개인 상담, 온라인 마음건강 검사), 임직원 및 직계가족까지 이용 가능, 개인 정서 및 가정·자녀 관련 상담 (2026 지속가능경영보고서 90쪽 임직원 복리후생 프로그램 표 구성원 건강 관리 지원 항목) — 상담 횟수·비용 부담 미기재', 63),

  -- ── 성장 (growth) — 2026 지속가능경영보고서 84쪽 · 86쪽 ──
  (@comp_id, 'lang', '사내 영어 교육·GIC 집중 어학 과정', NULL, 'growth',
   'est', NULL, TRUE, '사내 원어민 강사와 함께하는 영어 교육 과정, 1~2개월간 집중적으로 운영되는 GIC(Global Intensive Course) (2026 지속가능경영보고서 86쪽 어학능력 향상 교육과정 운영) — 수강 대상·선발 여부·교육비 본인 부담 미기재', 70),
  (@comp_id, 'edu_support', '스터디 그룹 지원 (Study with Me)', NULL, 'growth',
   'est', NULL, TRUE, '최소 3인 이상의 임직원이 공통 관심사로 스터디 그룹 구성, 업무 관련 주제부터 개인의 관심 분야까지 학습 주제 선정, 회사가 필요한 비용 지원 (2026 지속가능경영보고서 86쪽 Study with Me 운영, 84쪽 임직원 육성 프로그램 표) — 지원 금액·한도 미기재', 71),
  (@comp_id, 'mba', '대학연계 학위·비학위 과정', NULL, 'growth',
   'est', NULL, TRUE, '해당 분야 전문가로 육성할 학습의지 높은 우수인재 중 선발(연 1회), 전문지식·최신 트렌드 습득 및 해당 분야 전문가 네트워크 구축 지원 (2026 지속가능경영보고서 84쪽 임직원 육성 프로그램 표 전문(직무)역량 항목) — 학비 지원 범위·대상 학위·선발 인원 미기재', 72),

  -- ── 여가 (leisure) — 2026 지속가능경영보고서 86쪽 · 88쪽 · 89쪽 ──
  (@comp_id, 'company_event', '임직원 자녀 영어캠프·가족 참여 행사', NULL, 'leisure',
   'est', NULL, TRUE, '임직원 자녀를 대상으로 영어캠프 운영, 초등학생 대상 4박 5일 과정 (2026 지속가능경영보고서 86쪽 어학능력 향상 교육과정 운영, 89쪽 솔직톡톡 본문), CEO와 함께하는 원데이 스키행사·그랑열린데이로 임직원과 가족이 함께하는 기회 마련 (88쪽 임직원 경험 개선 프로그램) — 개최 주기·참가 비용 부담 미기재', 80),

  -- ── 보상 (compensation) — 2026 지속가능경영보고서 89쪽 · 124쪽 ──
  (@comp_id, 'incentive', '관리직 성과급', NULL, 'compensation',
   'est', NULL, TRUE, '관리직 연 평균 급여 기본급 + 성과급 항목 (2026 지속가능경영보고서 124쪽 임직원 보수 표) — 성과급 지급 기준·지급률·비관리직 지급 여부 미기재', 90),
  (@comp_id, 'excellence_award', '조직 성과 포상', NULL, 'compensation',
   'est', NULL, TRUE, '조직 차원에서 우수한 성과를 달성한 경우 추가적인 포상 실시 (2026 지속가능경영보고서 89쪽 합리적 보상체계 운영) — 포상 기준·포상 내용·주기 미기재', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
