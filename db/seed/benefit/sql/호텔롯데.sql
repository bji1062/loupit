-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 호텔롯데 복리후생 데이터 (신규 회사 — 웨이브 14)
-- 출처: AI 파싱 (2026-10-22)
-- URL: https://www.hotellotte.com/ko/careers/hr/hr-management
-- badge: est
--
-- 참고:
--   정본은 자기 도메인 채용정보 > 인사제도 페이지의 복리후생 절(서버렌더 HTML · 6블록 —
--   주택지원 · 여가지원 · 학비지원 · 직장생활지원 · 경조사 지원 · 의료지원). 헤더 메뉴 영문판
--   /en/careers/hr/hr-management 의 Employee Benefits 절로 같은 6블록의 뜻을 받쳤다(직장생활지원 「포함」 = rewards).
--   보조 1: ㈜호텔롯데 자기 발행 2025 지속가능성 보고서(발행 2026년 8월 · 보고 기간 2025-01 ~ 12 ·
--   보고 범위 ㈜호텔롯데 국내 사업장 별도 기준 = 이 법인 단독 · 사업부 = 롯데면세점 · 롯데호텔앤리조트 · 롯데월드).
--   자기 도메인 자료실 첨부(/download/ 경로)는 robots 금지라 받지 않았고, 롯데그룹 보고서 목록
--   www.lotte.co.kr/upload/report/hotel/lottehotell_SR_kor_2026.pdf 사본(표지 2025 SUSTAINABILITY REPORT HOTEL LOTTE)을 썼다.
--   41쪽 교육 · 43쪽 조직문화 · 44쪽 복지 제도 운영 · 45쪽 라이프 사이클 복지 제도(항목마다 공통 · 면세 · 호텔 · 월드 표시).
--   45쪽 표지는 PDF 글자 좌표로 항목과 짝을 지었고 쪽 그림으로 대조했다.
--   보조 2: OpenDART 2026 반기보고서(접수 20260814002783) · 2025 사업보고서(접수 20260331004734)
--   유연근무제도 사용 현황 표(시차출퇴근제 · 선택근무제 · 원격근무제). 직원 4,670명(2026-06-30).
--   귀속: 전 행 이 법인 자기 출처 — 각주 없음. 사업부 한정 항목은 이름 끝 (○○부문) + 서술 「적용 사업부」.
--   금액: 원문 숫자는 난임 치료비 1회당 100만 원 최대 3회(한도)뿐 — 전 행 BENEFIT_AMT NULL.
--   제외: 법정(임신기 · 육아기 근로시간 단축 법정분 · 산전후 휴가 · 육아휴직 · 연장 육아휴직 · 배우자 출산휴가 20일 ·
--     난임치료 휴가 연 6일 · 가족돌봄휴가 및 휴직 · 퇴직 후 진로 설계 지원(1,000인 이상 재취업지원)) ·
--     업무 교육(직무 아카데미 · 리더십 · 멘토링 · 온보딩) · 급여성 수당(가족수당) · 소통 행사(롯데 EATS · 타운홀 · CEO 소통).
--   공고 근거 0행 / 전체 32행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(work_env 10 · perks 20 · leisure 30 · family 40 · compensation 50 · health 60),
--     보고서 · 공시에만 있는 growth 70 · time_off 80 · flexibility 90.
-- 검증 · 감사 판정 반영(2026-10-22): 보고서 44쪽 상자 귀속에 맞춰 임산부 단축근로와 난임 치료비는 롯데호텔앤리조트(호텔) · 종합건강검진 수가 인상과 원격지 발령 유급휴가는 롯데월드(월드) 사업부 표시를 서술과 이름에 더함 · 그룹 목록 PDF 는 자기 도메인 2026-08-14 글과 같은 판 · 항목 페이지 예외 1(통합 밖 리드 집행) · 참고 블록의 44쪽 생애주기 복리후생 상자 이름은 이 판정으로 뒤집힘 — 최종 32행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hotel_lotte', '호텔롯데',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '유통', 'H', 'https://www.hotellotte.com/ko/careers/hr/hr-management');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hotel_lotte');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.hotellotte.com/ko/careers/hr/hr-management'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무환경 (work_env) — 공식 채용 페이지 주택지원 · 2025 지속가능성 보고서 44쪽 ──
  (@comp_id, 'dormitory', '지방 근무자 사택', NULL, 'work_env',
   'est', NULL, TRUE, '지방 근무자 사택제도 (공식 채용 페이지 인사제도 복리후생 주택지원 항목), Company housing for employees posted in the provinces (영문 채용 페이지 Employee Benefits Housing 항목) — 입주 기간·비용 부담 미기재', 10),
  (@comp_id, 'lounge', '휴게공간 (면세부문)', NULL, 'work_env',
   'est', NULL, TRUE, '휴게공간 개선 (2025 지속가능성 보고서 44쪽 롯데면세점 복지 제도 운영 항목, 적용 사업부 면세) — 시설 위치·규모 미기재', 11),

  -- ── 생활 지원 (perks) — 공식 채용 페이지 · 2025 지속가능성 보고서 45쪽 ──
  (@comp_id, 'housing_loan', '주택구입·전세자금 대출 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택구입 및 전세자금 대출 지원제도 (공식 채용 페이지 인사제도 복리후생 주택지원 항목), 주택구입/전세 대출 지원 (2025 지속가능성 보고서 45쪽 라이프 사이클 복지 제도 결혼 항목, 공통) — 대출 한도·이율 미기재', 20),
  (@comp_id, 'transport', '교통비 지원', NULL, 'perks',
   'est', NULL, TRUE, '교통비 (공식 채용 페이지 인사제도 복리후생 직장생활지원 항목), Transport and fuel subsidies (영문 채용 페이지 Employee Benefits Work life support 항목) — 지원 금액·지급 기준 미기재', 21),
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '복지포인트 지급 (2025 지속가능성 보고서 45쪽 라이프 사이클 복지 제도 입사 항목, 공통) — 포인트 금액·사용처 미기재', 22),
  (@comp_id, 'birthday_gift', '생일기념 바우처·선물', NULL, 'perks',
   'est', NULL, TRUE, '본인 생일기념 바우처 및 선물 지급 (2025 지속가능성 보고서 45쪽 라이프 사이클 복지 제도 입사 항목, 공통) — 바우처 금액·선물 품목 미기재', 23),
  (@comp_id, 'discount', '사업장 할인·전사업장 무료 입장 (호텔·월드부문)', NULL, 'perks',
   'est', NULL, TRUE, '사업장 할인 혜택 제공 (적용 사업부 호텔·월드), 직원 본인 전사업장 입장 무료 (적용 사업부 월드) (2025 지속가능성 보고서 45쪽 라이프 사이클 복지 제도 입사 항목) — 할인율·대상 사업장 미기재', 24),

  -- ── 여가 (leisure) — 공식 채용 페이지 여가지원 · 2025 지속가능성 보고서 ──
  (@comp_id, 'resort', '콘도미니엄·하계 휴양소', NULL, 'leisure',
   'est', NULL, TRUE, '콘도미니엄 및 하계 휴양소 운영 (공식 채용 페이지 인사제도 복리후생 여가지원 항목), Hotels and resorts for employees on vacation (영문 채용 페이지 Employee Benefits Leisure support 항목) — 이용 횟수·비용 부담 미기재', 30),
  (@comp_id, 'summer_vacation_subsidy', '휴가비 지급', NULL, 'leisure',
   'est', NULL, TRUE, '휴가비 지급 (공식 채용 페이지 인사제도 복리후생 여가지원 항목), 휴가비용 지급 (2025 지속가능성 보고서 45쪽 라이프 사이클 복지 제도 입사 항목, 공통) — 지급 금액·지급 시기 미기재', 31),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회를 운영 (2025 지속가능성 보고서 40쪽 인재경영 및 조직역량 강화 항목), 동호회 제도, 독서·꽃꽂이·러닝 등 8개 동호회 운영 (같은 보고서 43쪽 롯데면세점 조직문화 프로그램 항목) — 활동비 지원 여부 미기재', 32),
  (@comp_id, 'welcome_kit', '신규입사자 웰컴키트', NULL, 'leisure',
   'est', NULL, TRUE, '신규입사자 웰컴키트 지급 (2025 지속가능성 보고서 45쪽 라이프 사이클 복지 제도 입사 항목, 공통) — 구성품 미기재', 33),
  (@comp_id, 'sports_ticket', '롯데자이언츠 야구 관람 행사 (호텔부문)', NULL, 'leisure',
   'est', NULL, TRUE, '스포츠 관람 행사, 롯데자이언츠 야구 관람 행사, 부서·직급 무관 자율 참여 (2025 지속가능성 보고서 43쪽 롯데호텔앤리조트 조직문화 프로그램 항목, 적용 사업부 호텔) — 개최 횟수·비용 부담 미기재', 34),

  -- ── 가족 (family) — 공식 채용 페이지 학비지원 · 경조사 지원 · 2025 지속가능성 보고서 ──
  (@comp_id, 'child_edu', '자녀 학비 전액 지원', NULL, 'family',
   'est', NULL, TRUE, '초,중,고등학교 및 대학생 자녀에 대한 학비 전액 지원 (공식 채용 페이지 인사제도 복리후생 학비지원 항목), 유치원 보조금 · 학비 지원 · 자녀 대학교 입학금 및 등록금 전액 지원 (2025 지속가능성 보고서 45쪽 라이프 사이클 복지 제도 유치원·초중고·대학생 항목, 공통) — 유치원 보조금 금액 미기재', 40),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조휴가 및 휴가비 지급 (공식 채용 페이지 인사제도 복리후생 경조사 지원 항목), 결혼 경조금 및 화환 지급 · 자녀 결혼 축하금 지급 · 자녀 결혼 휴가 · 화환 배송 · 상조서비스 지원(장제용품, 화환, 문자) (본인, 배우자, 부모, 승중상, 배우자 부모, 자녀) · 경조 휴가 및 경조금 지원 (2025 지속가능성 보고서 45쪽 라이프 사이클 복지 제도 결혼·자녀결혼·상 항목, 공통), 대학 졸업 경조휴가 (같은 쪽 입사 항목, 적용 사업부 면세·호텔) — 경조금 금액·휴가 일수 미기재', 41),
  (@comp_id, 'parenting', '임신·출산·육아 지원', NULL, 'family',
   'est', NULL, TRUE, '임산부 단축근로 확대(임신기 전체) (2025 지속가능성 보고서 44쪽 롯데호텔앤리조트 임신·출산 항목, 적용 사업부 호텔), 자녀 출산 축하금 인상 (같은 쪽 롯데월드 생애 주기별 복지 강화 항목), 출산 축하금 및 분유 지급 · 입학 축하금 · 자녀 입학 돌봄 휴직 (같은 보고서 45쪽 라이프 사이클 복지 제도 출산·초중고 항목, 공통), 유산 위로금 (적용 사업부 호텔), 보육료 매월 지원 (만1세~초등 입학) (적용 사업부 면세), 자녀 수능응원 선물 지급 (적용 사업부 면세·월드) — 축하금 금액·휴직 기간 미기재', 42),
  (@comp_id, 'fertility_support', '난임 치료비 지원', NULL, 'family',
   'est', NULL, TRUE, '난임 치료비 지원 1회당 100만 원 최대 3회 지원 (2025 지속가능성 보고서 44쪽 롯데호텔앤리조트 임신 준비 항목, 적용 사업부 호텔), 난임 치료 지원제도 신설 (같은 쪽 롯데월드 생애 주기별 복지 강화 항목), 난임 치료비 지원 (같은 보고서 45쪽 라이프 사이클 복지 제도 출산 항목, 공통) — 대상 시술 범위·면세·월드 지원 금액 미기재', 43),
  (@comp_id, 'childcare', '롯데 어린이집', NULL, 'family',
   'est', NULL, TRUE, '롯데 어린이집 운영 (2025 지속가능성 보고서 45쪽 라이프 사이클 복지 제도 유치원 항목, 공통) — 위치·정원 미기재', 44),

  -- ── 보상 (compensation) — 공식 채용 페이지 직장생활지원 ──
  (@comp_id, 'holiday_gift', '각종 선물', NULL, 'compensation',
   'est', NULL, TRUE, '각종 선물 (공식 채용 페이지 인사제도 복리후생 직장생활지원 항목), gifts (영문 채용 페이지 Employee Benefits Work life support 항목) — 지급 시기·품목 미기재', 50),
  (@comp_id, 'long_service_bonus', '장기 근속자 포상·여행', NULL, 'compensation',
   'est', NULL, TRUE, '장기 근속자 포함 및 여행실시 (공식 채용 페이지 인사제도 복리후생 직장생활지원 항목), rewards for long-term service, company vacations (영문 채용 페이지 Employee Benefits Work life support 항목) — 근속 기준·포상 내용 미기재', 51),
  (@comp_id, 'excellence_award', '모범사원 해외연수', NULL, 'compensation',
   'est', NULL, TRUE, '모범사원 해외연수 (공식 채용 페이지 인사제도 복리후생 직장생활지원 항목), overseas training opportunities (영문 채용 페이지 Employee Benefits Work life support 항목) — 선발 기준·연수 기간 미기재', 52),

  -- ── 건강 (health) — 공식 채용 페이지 의료지원 · 2025 지속가능성 보고서 44 · 45쪽 ──
  (@comp_id, 'health_check', '본인·가족 건강검진', NULL, 'health',
   'est', NULL, TRUE, '본인 및 피부양 가족에 대한 건강진단 (공식 채용 페이지 인사제도 복리후생 의료지원 항목), 종합건강검진 수가 25% 인상 (2025 지속가능성 보고서 44쪽 롯데월드 생애 주기별 복지 강화 항목), 정기 건강검진 지원 (같은 보고서 45쪽 라이프 사이클 복지 제도 의료지원 항목, 공통) — 검진 주기·지원 금액 미기재', 60),
  (@comp_id, 'mental', '임직원 심리 케어 서비스', NULL, 'health',
   'est', NULL, TRUE, '임직원 심리 케어 서비스 (2025 지속가능성 보고서 45쪽 라이프 사이클 복지 제도 의료지원 항목, 공통), 임직원 심리지원 프로그램 심플(心+) · 커플·부부·자녀 동반 상담 연 2회 이용 가능 · 우울 자가진단·불안 자가진단 검사 무료 제공 (같은 보고서 44쪽 롯데면세점 임직원 심리 건강 항목) — 상담 기관·비용 부담 미기재', 61),
  (@comp_id, 'medical', '본인·가족 의료비·실손 의료보험', NULL, 'health',
   'est', NULL, TRUE, '본인/가족 의료비 지원 · 실손 의료보험 가입 (2025 지속가능성 보고서 45쪽 라이프 사이클 복지 제도 의료지원 항목, 공통) — 지원 한도·보장 범위 미기재', 62),
  (@comp_id, 'insurance', '단체 상해보험', NULL, 'health',
   'est', NULL, TRUE, '단체 상해보험 가입 (2025 지속가능성 보고서 45쪽 라이프 사이클 복지 제도 의료지원 항목, 공통) — 보장 내용 미기재', 63),

  -- ── 성장 (growth) — 2025 지속가능성 보고서 41 · 45쪽 ──
  (@comp_id, 'lang', '어학 교육 (면세부문)', NULL, 'growth',
   'est', NULL, TRUE, '임직원의 글로벌 역량 강화를 위한 외국어 교육, 어학 교육 운영 영어·중국어·일본어·태국어·베트남어 (2025 지속가능성 보고서 41쪽 롯데면세점 교육체계 항목, 적용 사업부 면세) — 수강 대상·비용 부담 미기재', 70),
  (@comp_id, 'self_development', '본인 야간학교 졸업 축하금 (월드부문)', NULL, 'growth',
   'est', NULL, TRUE, '본인 야간학교 졸업 축하금 지원 (2025 지속가능성 보고서 45쪽 라이프 사이클 복지 제도 대학생 항목, 적용 사업부 월드) — 지급 금액 미기재', 71),
  (@comp_id, 'conference', '해외 테마파크 견학 지원 (월드부문)', NULL, 'growth',
   'est', NULL, TRUE, '해외 테마파크 견학 지원 (2025 지속가능성 보고서 45쪽 라이프 사이클 복지 제도 입사 항목, 적용 사업부 월드) — 선발 기준·지원 범위 미기재', 72),
  (@comp_id, 'retirement_support', '정년퇴직 지원금·감사 선물', NULL, 'growth',
   'est', NULL, TRUE, '정년퇴직 지원금 및 감사 선물 지급 (2025 지속가능성 보고서 45쪽 라이프 사이클 복지 제도 정년퇴직 항목, 공통) — 지원금 금액 미기재', 73),

  -- ── 휴가 (time_off) — 2025 지속가능성 보고서 44 · 45쪽 ──
  (@comp_id, 'summer_leave', '하계 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '하계 휴가 (2025 지속가능성 보고서 45쪽 라이프 사이클 복지 제도 입사 항목, 공통) — 연차 사용일인지·일수·유급 여부 미기재', 80),
  (@comp_id, 'leave_general', '원격지 발령 유급휴가 (월드부문)', NULL, 'time_off',
   'est', NULL, TRUE, '원격지 발령 임직원 유급휴가 신설 (2025 지속가능성 보고서 44쪽 롯데월드 생애 주기별 복지 강화 입사·정착 항목, 적용 사업부 월드) — 휴가 일수·사용 기한 미기재', 81),

  -- ── 유연근무 (flexibility) — 2025 지속가능성 보고서 45쪽 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '유연근무제(시차출퇴근제·선택근무제)', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 시행 (2025 지속가능성 보고서 45쪽 라이프 사이클 복지 제도 입사 항목, 공통), 시차출퇴근제 사용자 수 951명 · 선택근무제 사용자 수 2,452명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 적용 직무·근무시간대 미기재', 90),
  (@comp_id, 'remote_work', '원격근무제(재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무 포함) 사용자 수 2026년 상반기 1명 · 2025년 3명 · 2024년 9명 (2026 반기보고서 · 2025 사업보고서 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
