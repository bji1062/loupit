-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 멀티캠퍼스 복리후생 데이터 (신규 회사 — 웨이브 15)
-- 출처: AI 파싱 (2026-10-23)
-- URL: https://careers.multicampus.com/welfare
-- badge: est
--
-- 참고:
--   정본은 KOSDAQ 상장 법인 (주)멀티캠퍼스의 회사 계정 채용 사이트 careers.multicampus.com(그리팅 ATS · 자기 도메인 서브도메인)
--   팀 문화 페이지 Benefits 절 10항목이다. SSR 이라 원본 HTML 에 항목 텍스트가 다 있다(헤드리스 렌더 없음).
--   같은 페이지 Working Way 절은 이미지 8장(일하는 방식 가치 문구)이라 행 근거로 쓰지 않았다.
--   보조 출처: 같은 사이트 2026년 경력직 상시채용 공고(o/129782 · 2024-10-08 게시 · 마감일 없음)의 복리후생 블록 ·
--     OpenDART 2026 반기보고서(접수 20260814003903) 직원 등 현황 유연근무제도 사용 현황 표 · 재무제표 주석 우발채무와 약정사항 ·
--     2025 사업보고서 정정본(접수 20260316000476) 유연근무제도 사용 현황 표 · 재무제표 주석 종업원 급여(기타장기종업원급여).
--   귀속: 페이지 주어가 멀티캠퍼스는 · 멀티캠퍼스人 으로 법인 단수이고 그룹 · 계열사 단서가 없다. 그룹 각주 없음.
--     최대주주 삼성SDS(기등록 · samsungcareers 법인 페이지 C60)와 라벨 일부가 닮았지만 이 문장은 이 법인 자기 도메인 원문이다.
--   금액: meal 1행만 추정 288(공고 중식비 지원 = 하루 1끼 × 12,000원 × 240일). 나머지 전 행 NULL(원문에 금액 숫자 0건).
--   제외 요약: 법정(4대보험) · 임원 보수 칸(명절귀성여비 · 목표 · 성과인센티브 · 임원 의료지원) · 우리사주조합(주주 표 한 칸) ·
--     호칭 문화(수평적인 소통) · Working Way 가치 문구 이미지 · 고객 교육 상품(회사 소개 페이지 사업 소개).
--   공고 근거 2행(medical · incentive) / 전체 21행 — meal 금액 · 다른 9행 서술 일부도 공고 구절로 보탰다.
--   SORT 섹션 순서 = 정본 Benefits 절 등장 순(flexibility 10 · growth 20 · perks 30 · family 40 · health 50 · leisure 60 ·
--     work_env 70), 보조 출처에만 있는 compensation 80.
-- 검증 · 감사 판정 반영(2026-10-23): 행 조치 없음 · 삼성SDS 와 꼴이 닮은 7행은 멀티캠퍼스는 주어 자기 도메인 원문이라 각주 없음 · 공고 근거 2행은 상시 채용 공고(사본 해시 일치) · OPIc ProDS 응시료 싣기 · 항목 페이지 예외 2(통합 밖 리드 집행) — 최종 21행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('multicampus', '멀티캠퍼스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '교육', 'M', 'https://careers.multicampus.com/welfare');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'multicampus');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://careers.multicampus.com/welfare'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — 채용 사이트 Benefits · 상시채용 공고 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '유연한 출퇴근 (선택적 근로시간제)', NULL, 'flexibility',
   'est', NULL, TRUE, '월 의무근무시간을 준수하는 범위에서 자율적으로 1일 근무시간을 관리 (공식 채용 페이지 복리후생 유연한 출퇴근 항목), 선택적 근로시간제 운영으로 출퇴근 시간을 유연하게 운영 (공식 채용 공고 복리후생 항목), 선택근무제 · 시차출퇴근제 활용 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 코어타임·정산 단위 미기재', 10),
  (@comp_id, 'remote_work', '원격근무제(재택근무포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무포함) 활용 (2026 반기보고서 · 2025 사업보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 11),
  -- ── 성장 · 교육 (growth) — 채용 사이트 Benefits · 상시채용 공고 ──
  (@comp_id, 'edu_support', '온·오프라인 교육 · SERICEO 콘텐츠 상시 학습', NULL, 'growth',
   'est', NULL, TRUE, '온·오프라인 교육, SERICEO 콘텐츠 상시 학습 (공식 채용 페이지 복리후생 다양한 교육기회 제공 항목), 사내 교육과정 무료, 학습 소모임 (공식 채용 공고 복리후생 항목) — 과정 종류·학습 소모임 지원 내용 미기재', 20),
  (@comp_id, 'lang', 'OPIc 응시료 지원', NULL, 'growth',
   'est', NULL, TRUE, 'OPIc 자격 응시료 지원 (공식 채용 페이지 복리후생 다양한 교육기회 제공 항목 · 공식 채용 공고 복리후생 무한성장 지원 항목) — 지원 횟수·지원 범위 미기재', 21),
  (@comp_id, 'self_development', 'ProDS 자격 응시료 지원', NULL, 'growth',
   'est', NULL, TRUE, 'ProDS 자격 응시료 지원 (공식 채용 페이지 복리후생 다양한 교육기회 제공 항목 · 공식 채용 공고 복리후생 무한성장 지원 항목) — 지원 횟수·지원 범위 미기재', 22),
  -- ── 경제적 부가혜택 (perks) — 채용 사이트 Benefits · 상시채용 공고 ──
  (@comp_id, 'meal', '사내식당 운영 · 중식비 지원', 288, 'perks',
   'est', '사내 식당 이용 지원 (공식 채용 페이지 복리후생 사내식당 운영 항목), 중식비 지원 (공식 채용 공고 복리후생 항목) — 1끼 단가 미기재 (하루 1끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 30),
  (@comp_id, 'welfare_point', '선택적 복리후생 지원 (복지포인트)', NULL, 'perks',
   'est', NULL, TRUE, '개인 라이프 스타일에 따라 선택해 사용할 수 있는 복지 포인트 제공 (공식 채용 페이지 복리후생 선택적 복리후생 지원 항목), 복지포인트 지급 (공식 채용 공고 복리후생 여가생활 지원 항목) — 연간 포인트 금액 미기재', 31),
  -- ── 가족 (family) — 채용 사이트 Benefits · 상시채용 공고 ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '임직원 가족의 경조사 발생 시 경조사비/화환/용품 및 휴가 지원 (공식 채용 페이지 복리후생 경조사 지원 항목), 경조사비 (공식 채용 공고 복리후생 항목) — 경조금액·경조휴가 일수 미기재', 40),
  (@comp_id, 'parenting', '출산축하 선물', NULL, 'family',
   'est', NULL, TRUE, '출산축하 선물 지원 (공식 채용 페이지 복리후생 임신/출산/육아 지원 항목) — 선물 품목·금액 미기재', 41),
  (@comp_id, 'child_edu', '자녀 유치원비 · 자녀학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 유치원비 지원 (공식 채용 페이지 복리후생 임신/출산/육아 지원 항목), 자녀학자금 지원 (공식 채용 공고 복리후생 항목) — 지원 학령·지원 금액 미기재', 42),
  -- ── 건강 (health) — 채용 사이트 Benefits · 상시채용 공고 · 2026 반기보고서 ──
  (@comp_id, 'mental', '마음건강센터 · 사내상담실', NULL, 'health',
   'est', NULL, TRUE, '마음건강실 케어를 위해 마음건강센터를 운영하며 상담, 심리검사, 마음건강 프로그램 제공 (공식 채용 페이지 복리후생 마음건강실 항목), 사내상담실 운영 (공식 채용 공고 복리후생 조직문화 지원 항목) — 이용 횟수·가족 포함 여부 미기재', 50),
  (@comp_id, 'health_check', '건강검진 지원', NULL, 'health',
   'est', NULL, TRUE, '질병을 조기 발견하고 치유할 수 있도록 검진비 지원 (공식 채용 페이지 복리후생 건강검진/단체보험 지원 항목), 건강검진 (공식 채용 공고 복리후생 항목) — 검진 주기·대상·비용 지원 범위 미기재', 51),
  (@comp_id, 'insurance', '단체보험 가입 (신종단체상해보험)', NULL, 'health',
   'est', NULL, TRUE, '단체보험 가입 지원 (공식 채용 페이지 복리후생 건강검진/단체보험 지원 항목), 임직원의 상해, 사망에 대비하여 신종단체상해보험 가입 (2026 반기보고서 재무제표 주석 우발채무와 약정사항 항목) — 보장 범위·가족 포함 여부 미기재', 52),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '의료비 지원 (공식 채용 공고 복리후생 혜택가득 지원 항목) — 지원 대상·지원 범위·한도 미기재', 53),
  -- ── 여가 (leisure) — 채용 사이트 Benefits · 상시채용 공고 ──
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '상호간 친목을 도모하고 활기찬 분위기 조성을 위해 다양한 동호회 활동 운영 (공식 채용 페이지 복리후생 사내동호회 및 도란도란day 항목), 사내 동호회 (공식 채용 공고 복리후생 조직문화 지원 항목) — 활동비 지원 여부·동호회 수 미기재', 60),
  (@comp_id, 'company_event', '도란도란day', NULL, 'leisure',
   'est', NULL, TRUE, '상호간 친목을 도모하고 활기찬 분위기 조성을 위해 도란도란day 운영 (공식 채용 페이지 복리후생 사내동호회 및 도란도란day 항목 · 공식 채용 공고 복리후생 조직문화 지원 항목) — 운영 주기·내용 미기재', 61),
  (@comp_id, 'resort', '법인콘도 · 휴양소', NULL, 'leisure',
   'est', NULL, TRUE, '법인콘도 등을 통해 양질의 휴식 및 여가생활 지원 (공식 채용 페이지 복리후생 여가생활 지원 항목), 휴양소 (공식 채용 공고 복리후생 여가생활 지원 항목) — 콘도 지점·이용 한도 미기재', 62),
  (@comp_id, 'leisure_ticket', '캐리비안베이 이용권 (추첨)', NULL, 'leisure',
   'est', NULL, TRUE, '캐리비안베이 이용권(추첨) (공식 채용 페이지 복리후생 여가생활 지원 항목), 워터파크 지원 (공식 채용 공고 복리후생 여가생활 지원 항목) — 매수·추첨 방식 미기재', 63),
  -- ── 근무 환경 (work_env) — 채용 사이트 Benefits ──
  (@comp_id, 'nap_room', '임산부 휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '임산부 휴게실 운영 (공식 채용 페이지 복리후생 임신/출산/육아 지원 항목) — 위치·이용 조건 미기재', 70),
  -- ── 보상 (compensation) — 상시채용 공고 · 2025 사업보고서 ──
  (@comp_id, 'incentive', '변동성 인센티브 (TAI · OPI)', NULL, 'compensation',
   'est', NULL, TRUE, '변동성 인센티브 TAI, OPI 운영 (공식 채용 공고 복리후생 인센티브 제공 항목) — 지급 기준·지급률 미기재', 80),
  (@comp_id, 'long_service_bonus', '장기근속 급부', NULL, 'compensation',
   'est', NULL, TRUE, '장기 근속 임직원에게 장기종업원급여 제공, 주로 10년 이상의 장기간 근무한 임직원 대상 (2025 사업보고서 재무제표 주석 종업원 급여 항목) — 급부 형태·금액 미기재', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
