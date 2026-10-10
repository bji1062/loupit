-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 코오롱인더스트리 복리후생 데이터 (신규 회사 — 웨이브 5)
-- 출처: AI 파싱 (2026-10-10)
-- URL: https://www.kolonindustries.com/file/view?fileSeq=7255&fileOrd=2
-- badge: est
--
-- 참고:
--   정본은 코오롱인더스트리 자기 도메인 www.kolonindustries.com 지속가능경영 > ESG경영 > 보고서 목록의
--   2025년 지속가능경영 보고서 국문 PDF(파일명 코오롱인더스트리 FY25 지속가능경영보고서, 138쪽, 2026년 6월 발행)다.
--   주 출처 79쪽 코오롱인더스트리 복리후생 제도 목록(16불릿)과 같은 쪽 자녀양육 지원 · 유연근무제 확대 ·
--   건강보건 지원 제도 본문. 보조 출처는 같은 보고서 75쪽 교육 체계도 · 인재 육성 정책, 76쪽 직무 전문성 프로그램,
--   77쪽 성과급 제도 이원화, 78쪽 신뢰받는 노사관계.
--   두 번째 출처는 같은 법인 패션부문 자체 사이트 www.kolonfnc.com/careers/benefits 복리후생 목록이다.
--   운영 주체 확인: 개인정보 처리방침 첫 문장이 코오롱인더스트리 FnC부문(이하 회사), 푸터가 KOLON INDUSTRIES,
--   보고서 11쪽이 코오롱인더스트리 패션부문(이하 코오롱FnC) — 별도 법인이 아니라 같은 법인의 사업부문이다.
--   그래서 이 사이트에만 있는 제도는 이름 끝 (패션부문) + 서술에 패션부문으로 싣고, 보고서 행과 같은 코드의
--   제도는 보고서 행 서술 뒤에 패션부문은 으로 시작하는 구절로 붙였다(부문 한정을 지우지 않는다).
--   렌더 방식은 PDF 텍스트 레이어(PyMuPDF 추출)와 서버렌더 HTML — 이미지 판독 · 헤드리스 렌더 없음.
--   보고서와 패션부문 페이지는 프로브 사본 재사용, 이번 수집 요청은 처리방침 · 보도자료 목록 · OpenDART 3회.
--   귀속: 79쪽 목록 표제 주어가 코오롱인더스트리 — 그룹 각주 없음. 그룹 채용 사이트 dream.kolon.com(지주 운영)은
--   복리후생 메뉴가 없어 쓰지 않았다. 지주 · 코오롱글로벌 · 코오롱생명과학 등 다른 법인 문장 0.
--   금액: 원문에 임직원 복지 원 단위 금액 0건 — 30행 전부 BENEFIT_AMT NULL(stated 0 · 추정 0).
--   패션부문 할인율 50% · 20% 는 비율이라 서술에만 남겼다.
--   제외: 법정(육아기 근로시간 단축 · 가족돌봄 휴직 · 난임 휴가 · 배우자 출산휴가 분할 · 특수건강검진과 사후관리 ·
--   출산 · 가족돌봄 휴가 · 육아휴직 · 단축근로 · 80쪽 재취업지원서비스 교육 — 국내 직원 4,260명이라 의무) ·
--   업무 교육(리더십 · 승진자 · 입문 · OJT · 사내강사 · DX Academy · 기능직 직책자 · 해외주재원 과정) ·
--   해외출장자 Travel Medical Kit · 패션부문 보건 교육과 유소견자 프로그램 · 자율복장 · 님 호칭 ·
--   복지 만족도 조사 · 생활임금 · 우리사주조합 주식 수 한 칸(97쪽) · 휴가 지원 항목의 유급휴가 지급(일수 · 연차 외 여부 불명).
--   공고 근거 0행 / 전체 30행.
--   SORT 섹션 순서 = 79쪽 텍스트에서 카테고리가 처음 나온 순서
--   (family 10 · flexibility 20 · perks 30 · work_env 40 · health 50 · growth 60 · compensation 70 · leisure 80 · time_off 90).
--   compensation 72 성과급은 77쪽 보조 출처, compensation 73 · perks 35 · perks 36 은 패션부문 페이지 출처다.
-- 검증 · 감사 판정 반영(2026-10-10): 임산부 정기 건강검진 구절(법정 겹침) 제거 · 임원 행 1:1 외국어 코칭을 어학 보조금으로 교체 · 해외출장자 Travel Medical Kit overseas_safety 추가 — 최종 31행
-- 코퍼스 정리(2026-10-10 · 웨이브 5 감사 후속): 경조휴가 행 삭제, event 행에 합침 — 최종 30행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('kolon_industries', '코오롱인더스트리',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '화학', 'K', 'https://www.kolonindustries.com/file/view?fileSeq=7255&fileOrd=2');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kolon_industries');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.kolonindustries.com/file/view?fileSeq=7255&fileOrd=2'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 가족·돌봄 (family) — 2025 지속가능경영보고서 79쪽 ──
  (@comp_id, 'parenting', '임신·출산·자녀 입학 지원', NULL, 'family',
   'est', NULL, TRUE, '모성 보호 제도로 임신 축하 선물, 출산 축하금 지원 (2025 지속가능경영보고서 79쪽 복리후생 제도 항목), 임신기 여성에게 법적 기준보다 4주 확대된 근로시간 단축 제도 적용, 임산부 전용 주차공간 마련, 자녀 입학 시 경조금 지급 (같은 쪽 자녀양육 지원 항목) — 출산 축하금·입학 경조금 금액과 선물 구성 미기재', 10),
  (@comp_id, 'childcare', '사내 어린이집 (마곡)', NULL, 'family',
   'est', NULL, TRUE, '사내 어린이집 운영 (2025 지속가능경영보고서 79쪽 복리후생 제도 항목), 마곡 코오롱 어린이집 운영 (같은 쪽 자녀양육 지원 항목) — 정원·대상 연령·다른 사업장 이용 방법 미기재', 11),
  (@comp_id, 'fertility_support', '난임 시술비 지원', NULL, 'family',
   'est', NULL, TRUE, '난임 시술비 지원 (2025 지속가능경영보고서 79쪽 자녀양육 지원 항목) — 지원 한도·횟수 미기재', 12),
  (@comp_id, 'child_edu', '자녀 학자금', NULL, 'family',
   'est', NULL, TRUE, '자녀 고등학교 학비, 대학교 입학금, 대학교 수업료 지원 (2025 지속가능경영보고서 79쪽 복리후생 제도 자녀 학자금 항목) — 지원 한도·자녀 수 제한 미기재', 13),
  (@comp_id, 'event', '경조금·경조휴가·상조 지원', NULL, 'family',
   'est', NULL, TRUE, '경조금 지급과 경조휴가 (2025 지속가능경영보고서 79쪽 복리후생 제도 경조금 및 경조휴가 항목), 상조지원 서비스로 근조화환·상조물품 제공과 위로금·상조휴가 지급 (같은 목록 상조지원 서비스 항목), 2024년 노사 공동 웰빙TF 논의 결과를 반영해 2025년부터 경조 제도 개선 적용 (78쪽 신뢰받는 노사관계 항목) — 경조 구분별 금액·휴가 일수·유급 여부 미기재', 14),

  -- ── 근무 유연성 (flexibility) — 2025 지속가능경영보고서 79쪽 ──
  (@comp_id, 'flex_work', '선택적 근무시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '본사 사무직을 중심으로 선택적 근무시간제 도입 (2025 지속가능경영보고서 79쪽 유연근무제 확대 항목), 같은 쪽 복리후생 제도 목록의 스마트 워크, 패션부문은 선택적 근로시간 제도로 개개인이 자율적으로 업무시간 관리 (코오롱FnC 공식 채용 페이지 조직문화 항목) — 코어타임·적용 사업장과 직군 범위 미기재', 20),
  (@comp_id, 'remote_work', '업무몰입 재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '매월 1회 시행하는 업무몰입 재택근무, 임신·육아·가족돌봄 등 돌봄 수요가 발생한 직원 대상 재택근무 (2025 지속가능경영보고서 79쪽 유연근무제 확대 항목) — 업무몰입 재택근무의 적용 대상·사업장 미기재', 21),

  -- ── 경제적 부가혜택 (perks) — 2025 지속가능경영보고서 79쪽 · 코오롱FnC 복리후생 ──
  (@comp_id, 'housing_loan', '주택구입·전세자금 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택지원으로 주택구입/전세자금 지원 (2025 지속가능경영보고서 79쪽 복리후생 제도 주택지원 항목) — 대출·이자 지원 등 지원 방식, 한도, 자격 요건 미기재', 30),
  (@comp_id, 'telecom', '통신비 지원', NULL, 'perks',
   'est', NULL, TRUE, '임직원 간 무료통화 및 개인 통신비 지원 (2025 지속가능경영보고서 79쪽 복리후생 제도 통신비 지원 항목) — 지원 금액 미기재', 31),
  (@comp_id, 'welfare_point', '선택적 복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '선택적 복지포인트 (2025 지속가능경영보고서 79쪽 복리후생 제도 항목) — 연간 포인트 금액·사용처 미기재', 32),
  (@comp_id, 'commute_subsidy', '출퇴근 교통비·통근버스', NULL, 'perks',
   'est', NULL, TRUE, '출퇴근 교통비 지원 및 통근버스 운영 (2025 지속가능경영보고서 79쪽 복리후생 제도 출퇴근 지원 항목) — 통근버스 운행 사업장·노선, 교통비 지원 금액 미기재', 33),
  (@comp_id, 'discount', '코오롱 제품 임직원 할인', NULL, 'perks',
   'est', NULL, TRUE, '코오롱 제품 임직원 할인 (2025 지속가능경영보고서 79쪽 복리후생 제도 항목), 패션부문은 자사 제품 50%·편집 브랜드 20% 할인과 임직원 대상 이벤트를 통한 추가 할인 제공 (코오롱FnC 공식 채용 페이지 복리후생 항목) — 패션부문 밖 할인율·대상 제품 미기재', 34),
  (@comp_id, 'welfare_fund_loan', '임직원 대출 (패션부문)', NULL, 'perks',
   'est', NULL, TRUE, '패션부문 임직원 대출 지원 (코오롱FnC 공식 채용 페이지 복리후생 항목) — 대출 용도·한도·이율 미기재', 35),
  (@comp_id, 'birthday_gift', '자사몰 생일 포인트 (패션부문)', NULL, 'perks',
   'est', NULL, TRUE, '패션부문 자사몰 생일 포인트 지급 (코오롱FnC 공식 채용 페이지 복리후생 현금성 복지 항목) — 포인트 금액 미기재', 36),

  -- ── 근무환경 (work_env) — 2025 지속가능경영보고서 79쪽 ──
  (@comp_id, 'dormitory', '기숙사·사택', NULL, 'work_env',
   'est', NULL, TRUE, '주택지원으로 기숙사/사택 운영 (2025 지속가능경영보고서 79쪽 복리후생 제도 주택지원 항목) — 운영 사업장·입주 자격·본인 부담 미기재', 40),

  -- ── 건강·의료 (health) — 2025 지속가능경영보고서 79쪽 · 코오롱FnC 복리후생 ──
  (@comp_id, 'health_check', '본인·배우자 건강검진 (연 1회)', NULL, 'health',
   'est', NULL, TRUE, '전 직원 및 배우자 연 1회 건강검진 지원 (2025 지속가능경영보고서 79쪽 복리후생 제도 건강검진 항목), 패션부문은 서울/경기 등 20여개 제휴병원을 통한 정밀 건강검진과 연 1회 독감 예방 접종 제공 (코오롱FnC 공식 채용 페이지 복리후생 항목) — 검진 항목·비용 지원 한도 미기재', 50),
  (@comp_id, 'clinic', '건강관리실', NULL, 'health',
   'est', NULL, TRUE, '본사 및 8개 사업장 건강관리실에 전담 간호사 배치, 임직원 대상 혈압·혈당 등 기초 건강상태 측정, 건강상담, 응급 처치 및 필요 시 약품 제공 (2025 지속가능경영보고서 79쪽 건강보건 지원 제도 건강관리실 운영 항목), 매년 금연·절주·마음건강 등 건강증진활동 운영 (같은 쪽 건강보건 지원 항목), 패션부문은 월 1회 정기적 방문보건상담 제공 (코오롱FnC 공식 채용 페이지 복리후생 항목) — 건강관리실이 없는 사업장의 이용 방법 미기재', 51),
  (@comp_id, 'mental', '심리상담 지원', NULL, 'health',
   'est', NULL, TRUE, '전국 1,600여 개 전문 상담센터와 협력하여 대면 및 비대면 상담 지원, 2025년 총 260건 상담 진행 (2025 지속가능경영보고서 79쪽 건강보건 지원 제도 대면/비대면 상담 지원 항목), 패션부문은 전문업체를 통한 직원 심리상담 프로그램(EAP) 제공 (코오롱FnC 공식 채용 페이지 복리후생 항목) — 1인당 상담 횟수·비용 부담·가족 이용 여부 미기재', 52),
  (@comp_id, 'overseas_safety', '해외출장자 Travel Medical Kit', NULL, 'health',
   'est', NULL, TRUE, '해외출장자를 대상으로 출장 중 발생할 수 있는 응급상황에 대비할 수 있는 kit 제공 (2025 지속가능경영보고서 79쪽 건강보건 지원 제도 Travel Medical Kit 제공 항목) — kit 구성·대상 국가 미기재', 53),

  -- ── 성장·교육 (growth) — 2025 지속가능경영보고서 75·76·79쪽 · 코오롱FnC 복리후생 ──
  (@comp_id, 'edu_support', '사내외 교육비 지원', NULL, 'growth',
   'est', NULL, TRUE, '자기개발지원으로 사내/외 교육비 지원 (2025 지속가능경영보고서 79쪽 복리후생 제도 자기개발지원 항목), 스마트러닝 플랫폼(KLIP) 운영 (75쪽 교육 체계도 · 76쪽 직무 전문성 프로그램 항목), 패션부문은 직무역량·외국어·OA·인문 과정 등 온라인 교육과 학회·컨퍼런스·세미나 등 사외교육 지원 (코오롱FnC 공식 채용 페이지 복리후생 항목) — 교육비 지원 한도·대상 과정 미기재', 60),
  (@comp_id, 'self_development', '자격증 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '자기개발지원으로 자격증 취득 지원 (2025 지속가능경영보고서 79쪽 복리후생 제도 자기개발지원 항목) — 지원 대상 자격·지원 금액 미기재', 61),
  (@comp_id, 'lang', '전화외국어·어학 보조금', NULL, 'growth',
   'est', NULL, TRUE, '임직원의 자기주도 학습을 지원하기 위해 전화외국어 과정 매월 운영 (2025 지속가능경영보고서 75쪽 인재 육성 정책 항목), 교육 체계도의 어학 보조금 (같은 쪽 교육 체계도) — 대상 언어·보조금 금액·수강 대상 미기재', 62),
  (@comp_id, 'mba', 'MBA·이공계 대학원 파견', NULL, 'growth',
   'est', NULL, TRUE, '교육 체계도의 EMBA/MBA/이공계 대학원(파견)과 온라인 MBA (2025 지속가능경영보고서 75쪽 교육 체계도), 연구원 핵심 인력 대상 이공계 석·박사 과정 지원 (76쪽 직무 전문성 프로그램 항목) — 선발 기준·인원·비용 지원 범위 미기재', 63),

  -- ── 보상·금전 (compensation) — 2025 지속가능경영보고서 77·79쪽 · 코오롱FnC 복리후생 ──
  (@comp_id, 'excellence_award', '성과우수자 포상', NULL, 'compensation',
   'est', NULL, TRUE, '성과우수자 포상 (2025 지속가능경영보고서 79쪽 복리후생 제도 성과우수자 및 장기근속자 포상 항목) — 포상 기준·포상 내용 미기재', 70),
  (@comp_id, 'long_service_bonus', '장기근속자 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속자 포상 (2025 지속가능경영보고서 79쪽 복리후생 제도 성과우수자 및 장기근속자 포상 항목), 2024년 노사 공동 웰빙TF 논의 결과를 반영해 2025년부터 근속 제도 개선 적용 (78쪽 신뢰받는 노사관계 항목) — 근속 연수 기준·포상 내용 미기재', 71),
  (@comp_id, 'incentive', 'PI·PS 성과급', NULL, 'compensation',
   'est', NULL, TRUE, '성과급 제도를 PI(Performance Incentive) 제도와 PS(Profit Sharing) 제도로 이원화하여 운영, PI 는 회사의 연간 경영 목표 달성 여부에 따라 지급되는 성과급이고 PS 는 경영 성과 기준을 초과한 이익의 일정 부분을 임직원과 공유 (2025 지속가능경영보고서 77쪽 주요 보상 제도 성과급 제도 이원화 항목) — 지급률·지급 시기 미기재', 72),
  (@comp_id, 'holiday_gift', '명절·창립기념일 상품권 (패션부문)', NULL, 'compensation',
   'est', NULL, TRUE, '패션부문 명절/창립기념일 상품권 지급 (코오롱FnC 공식 채용 페이지 복리후생 현금성 복지 항목) — 상품권 금액 미기재', 73),

  -- ── 여가·라이프 (leisure) — 2025 지속가능경영보고서 79쪽 · 코오롱FnC 복리후생 ──
  (@comp_id, 'club', '동호회 활동비 지원', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 활동비 지원 (2025 지속가능경영보고서 79쪽 복리후생 제도 동호회 지원 항목) — 동호회당 지원 금액 미기재', 80),
  (@comp_id, 'resort', '레저 시설·콘도 할인', NULL, 'leisure',
   'est', NULL, TRUE, '휴가 지원으로 레저 시설 및 콘도 할인 (2025 지속가능경영보고서 79쪽 복리후생 제도 휴가 지원 항목), 패션부문은 전국 대형 리조트 회원가 예약 및 계열사 운영 휴양소 직원 할인 제공 (코오롱FnC 공식 채용 페이지 복리후생 항목) — 제휴 시설·할인 수준·이용 한도 미기재', 81),
  (@comp_id, 'summer_vacation_subsidy', '휴가비 지급', NULL, 'leisure',
   'est', NULL, TRUE, '휴가 지원으로 휴가비 지급 (2025 지속가능경영보고서 79쪽 복리후생 제도 휴가 지원 항목), 패션부문은 여름 휴가비 지급 (코오롱FnC 공식 채용 페이지 복리후생 항목) — 지급액·지급 시기 미기재', 82)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
