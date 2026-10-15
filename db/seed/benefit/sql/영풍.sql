-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 영풍 복리후생 데이터 (신규 회사 — 웨이브 9)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.ypzinc.co.kr/site/main/content/career_YP
-- badge: est
--
-- 참고:
--   정본 = 법인 자기 도메인 ypzinc.co.kr 인재채용 영풍Career 복리후생 목록(SSR · 라벨 14개 · 설명 없음).
--   HTML 주석 속 옛 항목 2개(구내 식당 및 식대 지원 · 생활 지원 칸 임직원몰 중복)는 게시 내용이 아니라 싣지 않았다.
--   보조 = 같은 도메인 ESG 임직원과 조직문화 페이지(복리후생제도 표 · 일과 삶의 균형 · 교육 · 스트레스 예방교육) ·
--   ESG 안전보건 경영 페이지(임직원 건강관리) · 공식 뉴스룸 보도자료 2건(2025-09 스마트 쉼터 · 2026-05 마음안심버스) ·
--   2026 반기보고서(유연근무제도 사용 현황) · 2025 사업보고서 별도재무제표 주석(장기종업원급여).
--   지속가능경영보고서 PDF 는 robots 가 /uploadfile/ · /site/main/file/ 를 막아 받지 않았다.
--   귀속: 전 문장 주어가 영풍 · 자기 도메인 · 각주 없음. 관계사 고려아연 시드와 겹친 문장 없음.
--   금액: 원문에 숫자 없음 — 19행 전부 정성(NULL).
--   제외: 법정(특수건강검진 · 사후관리 · 법정 안전보건교육 · 휴게시설 설치 기준) · 업무 교육(SP 아카데미 365 · TPS 연수 · 경영 리더십 과정) ·
--   주석 처리된 식당 항목 · 공시 주주 표의 우리사주조합 한 칸.
--   공고 근거 0행 / 전체 19행. SORT 섹션 = work_env · family · health · perks · growth · compensation · leisure · time_off · flexibility.
-- 검증 · 감사 판정 반영(2026-10-15): 행 조치 없음 · 항목 페이지 예외 2(통합 밖 리드 집행) — 최종 19행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('youngpoong', '영풍',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '비철금속', 'Y', 'https://www.ypzinc.co.kr/site/main/content/career_YP');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'youngpoong');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.ypzinc.co.kr/site/main/content/career_YP'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 환경 (work_env) — 채용 페이지 생활 지원 · ESG 복리후생제도 표 · 보도자료 ──
  (@comp_id, 'dormitory', '기숙사·사원아파트', NULL, 'work_env',
   'est', NULL, TRUE, '기숙사 (공식 채용 페이지 복리후생 생활 지원 항목), 사원아파트 무상 입주(관리비 자가부담), 온수 및 난방 무료 제공(일부 동 제외), 대상 석포제련소 (공식 ESG 임직원과 조직문화 페이지 복리후생제도 사원아파트 항목) — 기숙사 입주 조건·대상 사업장 미기재', 10),
  (@comp_id, 'lounge', '스마트 쉼터 (석포제련소)', NULL, 'work_env',
   'est', NULL, TRUE, '생산직 사원들의 근무환경 개선을 위해 스마트 쉼터 개소, 약 70㎡ 규모의 직원 전용 PC 라운지 형태로 24시간 운영, 민원서류 출력·인터넷 뱅킹·회사 인트라넷 접속·팩스 전송 장비 구비 (2025년 9월 공식 뉴스룸 보도자료 석포제련소 스마트 쉼터 항목)', 11),

  -- ── 가족 (family) — 채용 페이지 생활 지원 · 리프레시 · ESG 복리후생제도 표 ──
  (@comp_id, 'child_edu', '학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '학자금 (공식 채용 페이지 복리후생 생활 지원 항목), 학자금 지원 해당 임직원, 대상 전사 (공식 ESG 임직원과 조직문화 페이지 복리후생제도 항목) — 지원 대상·학교 단계·지원 금액 미기재', 20),
  (@comp_id, 'event', '경조사 지원·경조휴가', NULL, 'family',
   'est', NULL, TRUE, '각종 경조사 (공식 채용 페이지 복리후생 생활 지원 항목), 경조 휴가제 (같은 페이지 리프레시 항목) — 경조금 금액·휴가 일수 미기재', 21),

  -- ── 건강 (health) — 채용 페이지 생활 지원 · ESG 복리후생제도 표 · 안전보건 경영 · 보도자료 ──
  (@comp_id, 'health_check', '종합검진 지원', NULL, 'health',
   'est', NULL, TRUE, '종합검진 (공식 채용 페이지 복리후생 생활 지원 항목), 임직원 대상 종합검진 지원, 대상 전사 (공식 ESG 임직원과 조직문화 페이지 복리후생제도 항목) — 검진 주기·비용 지원 범위 미기재', 30),
  (@comp_id, 'clinic', '건강관리실·간호사 상담', NULL, 'health',
   'est', NULL, TRUE, '사내 보건관리자(간호사) 상담 서비스, 대상 석포제련소 (공식 ESG 임직원과 조직문화 페이지 복리후생제도 간호사 상담 항목), 건강관리실에 전담 간호사를 배치하여 응급처치, 건강상담, 혈압·혈당·체지방 측정 등 기본 건강관리 서비스 상시 제공 (공식 ESG 안전보건 경영 페이지 임직원 건강관리 항목) — 운영 시간 미기재', 31),
  (@comp_id, 'mental', '임직원 마음건강 프로그램', NULL, 'health',
   'est', NULL, TRUE, '임직원 마음건강 프로그램 운영, 마음챙김 명상법·무드등 만들기 등 체험형 활동 (공식 ESG 임직원과 조직문화 페이지 스트레스 예방교육 항목), 창작활동을 통한 직무 스트레스 관리 및 번아웃 예방 (같은 페이지 사내러닝컬쳐 항목), 석포제련소 임직원 대상 봉화군 정신건강복지센터 연계 마음안심버스 이동형 상담소 정신건강 검진 (2026년 5월 공식 뉴스룸 보도자료 항목) — 운영 주기·개인 상담 지원 범위 미기재', 32),

  -- ── 생활 (perks) — 채용 페이지 문화 지원 · 동기부여 · ESG 복리후생제도 표 ──
  (@comp_id, 'welfare_point', '임직원몰 운영', NULL, 'perks',
   'est', NULL, TRUE, '임직원몰 운영 (공식 채용 페이지 복리후생 문화 지원 항목) — 포인트 지급 여부·할인 범위 미기재', 40),
  (@comp_id, 'discount', '계열사 할인', NULL, 'perks',
   'est', NULL, TRUE, '계열사 할인 (공식 채용 페이지 복리후생 문화 지원 항목) — 할인 대상 계열사·할인율 미기재', 41),
  (@comp_id, 'birthday_gift', '생일 선물', NULL, 'perks',
   'est', NULL, TRUE, '생일 선물 (공식 채용 페이지 복리후생 동기부여 항목), 생일자 선물 지급, 대상 전사 (공식 ESG 임직원과 조직문화 페이지 복리후생제도 항목) — 선물 품목·금액 미기재', 42),

  -- ── 성장 (growth) — 채용 페이지 문화 지원 · ESG 근로자 교육 프로그램 ──
  (@comp_id, 'edu_support', '자기계발 지원·근로자 교육 프로그램', NULL, 'growth',
   'est', NULL, TRUE, '자기계발 지원 (공식 채용 페이지 복리후생 문화 지원 항목), 자격증 대비, 북러닝, 금융 교육 등 임직원의 자발적 참여 교육 과정 (공식 ESG 임직원과 조직문화 페이지 근로자 교육 프로그램 항목) — 지원 방식·비용 지원 범위 미기재', 50),

  -- ── 보상 (compensation) — 채용 페이지 동기부여 · ESG 복리후생제도 표 · 공시 ──
  (@comp_id, 'holiday_gift', '명절 선물·귀향여비', NULL, 'compensation',
   'est', NULL, TRUE, '명절 선물 및 귀향여비 (공식 채용 페이지 복리후생 동기부여 항목) — 선물 품목·여비 금액 미기재', 60),
  (@comp_id, 'long_service_bonus', '장기근속 선물', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 선물 (공식 채용 페이지 복리후생 동기부여 항목), 근속연수 5년 단위로 선물 지급, 대상 전사 (공식 ESG 임직원과 조직문화 페이지 복리후생제도 장기근속자 선물 지급 항목), 장기 근속 임직원에게 장기종업원급여 제공, 주로 5년 이상 근무한 임직원 대상 (2025 사업보고서 별도재무제표 주석 종업원급여 항목) — 선물 품목·금액 미기재', 61),

  -- ── 여가 (leisure) — 채용 페이지 리프레시 · ESG 복리후생제도 표 ──
  (@comp_id, 'resort', '휴양시설 (법인 리조트)', NULL, 'leisure',
   'est', NULL, TRUE, '휴양시설(리조트 이용 등) (공식 채용 페이지 복리후생 리프레시 항목), 법인 리조트 운영, 직원의 법인 운영 리조트 사용, 대상 전사 (공식 ESG 임직원과 조직문화 페이지 복리후생제도 항목) — 리조트 위치·이용 횟수·비용 지원 미기재', 70),
  (@comp_id, 'summer_vacation_subsidy', '휴가비 지원', NULL, 'leisure',
   'est', NULL, TRUE, '휴가비 지원 (공식 채용 페이지 복리후생 리프레시 항목) — 지급 금액·지급 시기 미기재', 71),
  (@comp_id, 'welcome_kit', '수습해지자 선물', NULL, 'leisure',
   'est', NULL, TRUE, '신입/경력 수습해지자 선물 지급, 대상 전사 (공식 ESG 임직원과 조직문화 페이지 복리후생제도 수습해지자 선물 지급 항목) — 선물 품목·금액 미기재', 72),

  -- ── 휴가 (time_off) — 채용 페이지 리프레시 ──
  (@comp_id, 'summer_leave', '여름휴가', NULL, 'time_off',
   'est', NULL, TRUE, '여름휴가 (공식 채용 페이지 복리후생 리프레시 항목) — 연차 사용일인지·일수·유급 여부 미기재', 80),

  -- ── 유연근무 (flexibility) — ESG 일과 삶의 균형 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '시차출퇴근제·선택근무제·탄력근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '본사 시차출퇴근제 도입으로 업무 특성과 개인 여건에 따라 근무시간 탄력 조정, 석포제련소 관리직 대상 탄력근무제 시행 (공식 ESG 임직원과 조직문화 페이지 일과 삶의 균형 항목), 시차출퇴근제·선택근무제 활용 (2026 반기보고서 유연근무제도 사용 현황 항목) — 선택근무제 적용 직무·사용 조건 미기재', 90),
  (@comp_id, 'remote_work', '원격근무제(재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무 포함) 활용 (2026 반기보고서 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
