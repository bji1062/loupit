-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 유한양행 복리후생 데이터
-- 출처: AI 파싱 (2026-10-01)
-- URL: https://yuhan.recruiter.co.kr/career/welfare
-- badge: est
--
-- 참고:
--   정본은 유한양행 브랜드 채용 사이트(마이다스 잡플렉스 ATS) 복리후생 페이지 /career/welfare 다.
--   제목 「유한양행 채용사이트 | 복리후생」 · JSON-LD publisher 유한양행. 본문은 robots 전면 금지 API 에서만 와서
--   자동 수집기가 읽지 못한다. 원문 = 사이트 운영자가 2026-10-01 브라우저로 페이지를 열어 붙여 넣은 화면 본문
--   (사본 yuhan/user_paste_welfare_2026-10-01.txt · sha256 fd9ff0f3…4d16). WORK · LIFE · FAMILY 3구역 20항목.
--   같은 ATS 교육 페이지 /career/train 도 같은 방식으로 받았다(같은 날 사용자 붙여넣기 ·
--     사본 yuhan/user_paste_train_2026-10-01.txt · sha256 bd45850f…a6d3). 전문역량 · 공통역량 · 교육 방법 3구역.
--     이 페이지 근거 행 3(mba · self_development · library)은 서술 괄호를 교육 페이지 ○○ 항목으로 적어 구분했다.
--   보조 출처: OpenDART 사업보고서 2025.12 (접수 20260312001236) — 유연근무제도 사용 현황 · 임원 개인별 보수
--     산정기준 칸 가운데 전직원 동일 지급률 · 직원과 동일 기준 문장만 썼다. 임원 개인 금액 · 산정 조직은 쓰지 않았다.
--   귀속: 법인 단독 ATS 라 그룹 각주 없음. 관계사 유한킴벌리 · 유한크로락스 문구는 쓰지 않았다.
--   금액: 원문 명시 1(health_check 1인당 30만 원 상당 · 본인 1인 기준) · 구본 추정 승계 4(holiday_gift 20 ·
--     resort 50 · club 10 · commute_subsidy 120 — 전부 틀 값, NOTE 끝에 (추정)). child_edu 200 은 원문이
--     입학 시 지급으로 적어 승계하지 않았다. 출산지원금 1,000만원은 1회성이라 금액 칸에 넣지 않았다.
--   구본에서 뺀 행: edu_support · lang (교육 페이지에 회사가 여는 교육 과정만 있고 비용 지원 문장 없음) ·
--     housing_loan (사내대출 용도 미기재). mba 는 교육 페이지 학위파견으로 유지했다.
--   제외 항목: 리뉴얼 데이 (내용 미기재) · 사내대출제도 (용도 미기재) · 교육 페이지의 회사 주도 교육 과정
--     (기본 어학과정 · 국내/해외 전문기관 어학연수 · 직무공통 · 전문과정 · 유한 아카데미 · 사외 전문교육과정 ·
--     신입입문 · Jump-up · 승진자 워크숍 · 직책/직급별 리더십 · 유한특강 · 건강강좌 · 팀 단위 교육 ·
--     필수/선택역량 과정 · 의무 교육) · 교육 방법 구역 (제목과 영문 번역뿐).
--   재코딩: transport → commute_subsidy (통근버스) · leave_general → refresh_leave (조건 없는 추가 휴가 7일) ·
--     books → library (도서 구매 지원은 없고 회사 전용 전자도서관만 있음).
--   SORT 섹션 순서 = 원문에서 카테고리가 처음 나온 순서(복리후생 페이지 → 교육 페이지), 보조 출처 ·
--     교육 페이지 근거 행은 해당 섹션 끝 (perks 10 · work_env 20 · flexibility 30 · compensation 40 ·
--     time_off 50 · health 60 · family 70 · leisure 80 · growth 90).
-- 재수집(2026-10-01): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-01, RV-3-3 재투입): refresh_leave 서술에 원문 낱말 추가를 되살림 · incentive 서술에서 대표이사 전용 산정기준(전사 조직목표 · 연 1회 평가)을 걷고 전 직원 공통 문장만 남김 — 최종 22행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('yuhan', '유한양행',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '제약', 'Y', 'https://yuhan.recruiter.co.kr/career/welfare');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'yuhan');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://yuhan.recruiter.co.kr/career/welfare'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) — WORK 임직원 식당 · 통근버스 · 이사 비용 / FAMILY 기념품, 복지포인트 ──
  (@comp_id, 'meal', '임직원 식당', NULL, 'perks',
   'est', NULL, TRUE, '사업장 내 임직원 식당 운영, 본사·공장·연구소 (공식 채용 사이트 복리후생 임직원 식당 운영 항목) — 제공 끼니·식대 부담 미기재', 10),
  (@comp_id, 'commute_subsidy', '통근버스', 120, 'perks',
   'est', '용이한 출퇴근을 위한 통근버스 운영, 공장·연구소 (공식 채용 사이트 복리후생 통근버스 운영 항목) — 노선·본인 부담 미기재 (추정)', FALSE, NULL, 11),
  (@comp_id, 'relocation', '전근 이사 비용', NULL, 'perks',
   'est', NULL, TRUE, '전근 사원 이사 비용 지급 (공식 채용 사이트 복리후생 이사 비용 지급 항목) — 지급 기준·한도 미기재', 12),
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '회사 창립기념일·근로자의 날 기념품과 복지포인트 지급 (공식 채용 사이트 복리후생 기념품, 복지포인트 지급 항목) — 포인트 금액·연간 배정액 미기재', 13),

  -- ── 근무환경 (work_env) — WORK 합숙소 ──
  (@comp_id, 'dormitory', '지방 지점 합숙소', NULL, 'work_env',
   'est', NULL, TRUE, '지방 지점 합숙소 운영 (공식 채용 사이트 복리후생 합숙소 운영 항목)', 20),

  -- ── 근무 유연성 (flexibility) — WORK 유연근무제도 · 사업보고서 유연근무제도 사용 현황 ──
  (@comp_id, 'flex_work', '유연근무제도', NULL, 'flexibility',
   'est', NULL, TRUE, '업무의 시작 및 종료시각을 직원이 자율적으로 결정 (공식 채용 사이트 복리후생 유연근무제도 항목), 시차출퇴근제·선택근무제 활용 (2025 사업보고서 유연근무제도 사용 현황)', 30),

  -- ── 보상·금전 (compensation) — WORK 장기근속 장려 / FAMILY 기념품 / 사업보고서 상여 ──
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '근속표창·기념품·상금·자사 주식 부여 (공식 채용 사이트 복리후생 장기근속 장려 항목) — 근속 구간·상금 금액·주식 수량 미기재', 40),
  (@comp_id, 'holiday_gift', '기념일 기념품', 20, 'compensation',
   'est', '회사 창립기념일·근로자의 날 기념품 지급 (공식 채용 사이트 복리후생 기념품, 복지포인트 지급 항목) — 기념품 내용·금액 미기재 (추정)', FALSE, NULL, 41),
  (@comp_id, 'incentive', '성과상여', NULL, 'compensation',
   'est', NULL, TRUE, '회사 경영성과에 따른 상여와 목표달성 등급에 따른 성과상여, 전 직원과 같은 지급률·기준 적용 (2025 사업보고서 보수 산정기준 항목) — 지급률 미기재', 42),

  -- ── 시간·휴가 (time_off) — WORK 장기근속 장려 / LIFE 휴가 ──
  (@comp_id, 'long_service_leave', '장기근속 특별휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 장려 제도로 특별휴가 부여 (공식 채용 사이트 복리후생 장기근속 장려 항목) — 근속 구간·휴가 일수 미기재', 50),
  (@comp_id, 'refresh_leave', '추가 휴가 7일 (최대 32일)', NULL, 'time_off',
   'est', NULL, TRUE, '법정 기준보다 7일 추가 휴가 부여, 최대 32일 (공식 채용 사이트 복리후생 휴가 항목)', 51),

  -- ── 건강·의료 (health) — LIFE 종합건강검진 · 독감백신 · 헬스장 ──
  (@comp_id, 'health_check', '본인·배우자 종합건강검진·독감백신', 30, 'health',
   'est', '본인 및 배우자 종합건강검진 매년 1회, 1인당 30만 원 상당, 초음파·내시경·암검사 등 포함 (공식 채용 사이트 복리후생 종합건강검진 실시 항목), 독감 백신 접종 지원 (같은 페이지 독감백신 항목) — 금액은 본인 1인 기준', FALSE, NULL, 60),
  (@comp_id, 'fitness', '실내 헬스장', NULL, 'health',
   'est', NULL, TRUE, '실내 헬스장 운영, 본사·공장·연구소 (공식 채용 사이트 복리후생 헬스장 항목)', 61),

  -- ── 가족·돌봄 (family) — LIFE 경조사 / FAMILY 자녀 학자금 · 출산지원금 · 직장어린이집 · 입학 축하금 ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 시 경조금 및 경조휴가, 부의용품, 화환 등 지원 (공식 채용 사이트 복리후생 경조사 항목) — 경조 종류별 금액·휴가 일수 미기재', 70),
  (@comp_id, 'child_edu', '자녀 학자금', NULL, 'family',
   'est', NULL, TRUE, '자녀 중·고·대학교 입학 시 학자금 지원 (공식 채용 사이트 복리후생 자녀 학자금 항목) — 지원 금액·지원 기간·자녀 수 제한 미기재', 71),
  (@comp_id, 'parenting', '출산지원금·입학 축하금', NULL, 'family',
   'est', NULL, TRUE, '임직원 출산 시 자녀 수와 관계없이 인당 1,000만원 지급 (공식 채용 사이트 복리후생 출산지원금 항목), 자녀 초·중·고등학교 입학 시 축하금 지급 (같은 페이지 입학 축하금 항목) — 입학 축하금 금액 미기재', 72),
  (@comp_id, 'childcare', '직장어린이집', NULL, 'family',
   'est', NULL, TRUE, '전문 위탁업체를 통해 사내어린이집 운영 (공식 채용 사이트 복리후생 직장어린이집 항목) — 위치·정원 미기재', 73),

  -- ── 여가·라이프 (leisure) — LIFE 콘도·휴양소 · 사내동호회 / 교육 페이지 버들전자도서관 ──
  (@comp_id, 'resort', '콘도·휴양소', 50, 'leisure',
   'est', '전국 유명 호텔·리조트 중심의 휴양소 운영 (공식 채용 사이트 복리후생 콘도·휴양소 운영 항목) — 이용 일수·비용 부담 미기재 (추정)', FALSE, NULL, 80),
  (@comp_id, 'club', '사내동호회', 10, 'leisure',
   'est', '다양한 사내동호회 운영 및 소정 활동비 지원 (공식 채용 사이트 복리후생 사내동호회 항목) — 활동비 금액 미기재 (추정)', FALSE, NULL, 81),
  (@comp_id, 'library', '버들전자도서관', NULL, 'leisure',
   'est', NULL, TRUE, '회사 전용 전자도서관 버들전자도서관, 상시 독서제도 운영 (공식 채용 사이트 교육 페이지 상시 독서제도 운영 항목) — 장서 규모·이용 방식 미기재', 82),

  -- ── 성장·교육 (growth) — 교육 페이지 직무 전문성 강화 ──
  (@comp_id, 'mba', '단기 MBA·석박사 학위파견', NULL, 'growth',
   'est', NULL, TRUE, '단기 MBA 과정, 석·박사 학위파견 (공식 채용 사이트 교육 페이지 직무 전문성 강화 항목) — 대상·선정 방식·지원 범위 미기재', 90),
  (@comp_id, 'self_development', '자격증 취득 지원제도', NULL, 'growth',
   'est', NULL, TRUE, '자격증 취득 지원제도 운영 (공식 채용 사이트 교육 페이지 직무 전문성 강화 항목) — 대상 자격증·지원 내용 미기재', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
