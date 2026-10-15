-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 롯데에너지머티리얼즈 복리후생 데이터 (신규 회사 — 웨이브 9)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.lotte.co.kr/upload/report/energymaterials/lotteenergymaterials_SR_kor_2025.pdf
-- badge: est
--
-- 참고:
--   정본 = 롯데에너지머티리얼즈(주) 발행 2025 지속가능경영보고서(2026-06 발행 · 123쪽 · 보고 기간 2025-01~12 ·
--     비재무 보고 범위 = 롯데에너지머티리얼즈 국내 사업장). 롯데지주 www.lotte.co.kr 그룹 보고서 목록에
--     LOTTE Energy Materials 로 게시된 파일(롯데케미칼 선례와 같은 꼴). 59 · 60 · 61쪽.
--   자기 도메인 www.lotteenergymaterials.com 은 robots.txt · 첫 화면 모두 403(사이트 전체 차단)이라 더 요청하지 않았다.
--   보조 = 2025 사업보고서(OpenDART 20260310002974) 재무제표 주석 기타장기종업원급여 항목 ·
--     2026 반기보고서(OpenDART 20260814000373)는 대조만(유연근무제도 미적용 문장 · 우리사주조합 주주 표 한 칸뿐 — 행 없음).
--   렌더: PDF 텍스트 추출. 귀속: 이 법인 발행 단독 보고서 · 이 법인 공시 — 그룹 각주 없음.
--   일진머티리얼즈(2023 롯데 인수 전 이름) 시절 페이지 · 보고서는 쓰지 않았다(2024 보고서는 뜻 대조에만).
--   롯데 형제(롯데케미칼 · 롯데정밀화학 · 롯데칠성음료 · 롯데렌탈 · 롯데웰푸드 · 롯데쇼핑)와 출처 파일 · 설명 문장 겹침 없음.
--   금액: 금액 행 0(원문에 금액 숫자 없음).
--   제외: 법정(육아휴직 운영 · 법정 필수 교육 · 공장 특수검진) · 업무 교육(입문 · 멘토링 · 리더십 · Grade · AI 활용) ·
--     선발형 핵심인재 과정(롯데 MBA · Hi-Potential Leader · 주재원 후보자 과정) · 위원제도(리텐션) · 워라밸 데이(뜻 미기재 — 근거표 판단 요청) ·
--     해외 법인 제도.
--   공고 근거 0행 / 전체 13행
--   SORT 섹션: growth 10 · compensation 20 · leisure 30 · family 40 · perks 50 · health 60
-- 검증 · 감사 판정 반영(2026-10-15): 재무제표 주석 근속 행 이름을 장기근속 급부로 · 13쪽 워라밸 데이 leave_general 추가(참고 블록 제외 줄의 워라밸 데이는 이 판정으로 뒤집힘) — 최종 14행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('lotte_energy_materials', '롯데에너지머티리얼즈',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '배터리소재', 'L', 'https://www.lotte.co.kr/upload/report/energymaterials/lotteenergymaterials_SR_kor_2025.pdf');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lotte_energy_materials');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.lotte.co.kr/upload/report/energymaterials/lotteenergymaterials_SR_kor_2025.pdf'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 성장 · 교육 (growth) — 2025 지속가능경영보고서 59 · 60쪽 ──
  (@comp_id, 'career', '그룹 내 이직제도 (인커리어)', NULL, 'growth',
   'est', NULL, TRUE, '롯데그룹 내 이직제도(인커리어)를 통한 그룹 내 우수 인재 활용 (2025 지속가능경영보고서 59쪽 인재 채용 항목) — 지원 자격·절차 미기재', 10),
  (@comp_id, 'self_development', '직무 자격증 지원 (안전)', NULL, 'growth',
   'est', NULL, TRUE, '직무 자격증 지원(안전) (2025 지속가능경영보고서 60쪽 인재 육성 프로그램 직무 항목) — 지원 범위·대상 자격증 미기재', 11),
  -- ── 보상 · 금전 (compensation) — 2025 지속가능경영보고서 60쪽 · 2025 사업보고서 ──
  (@comp_id, 'excellence_award', 'LEM Awards · CEO Special Award', NULL, 'compensation',
   'est', NULL, TRUE, '연 1회 창립기념 LEM Awards 시상식(탁월한 업무 성과와 기업가치 제고에 크게 기여한 임직원) · 분기별 CEO Special Award(단기적 업무성과 및 발전적 실패를 경험한 직원), 포상심의위원회 선정 (2025 지속가능경영보고서 60쪽 우수인재 보상 항목) — 포상 내용·금액 미기재', 20),
  (@comp_id, 'long_service_bonus', '장기근속 급부', NULL, 'compensation',
   'est', NULL, TRUE, '장기 근속 임직원에게 장기종업원급여 제공 (2025 사업보고서 재무제표 주석 기타장기종업원급여 항목) — 근속 기준·급부 형태·금액 미기재', 21),
  -- ── 여가 · 행사 (leisure) — 2025 지속가능경영보고서 61쪽 ──
  (@comp_id, 'company_event', '조직문화 활동 LEM DAY', NULL, 'leisure',
   'est', NULL, TRUE, '임직원 조직문화 참여 활동 LEM DAY 매월 테마 활동, 초복 맞이 근무자 전원 중식 시 아이스크림 제공 · 임직원 커피, 도넛 티타임 등 (2025 지속가능경영보고서 61쪽 조직문화 활동 항목) — 행사별 대상·횟수 미기재', 30),
  (@comp_id, 'resort', '콘도 지원', NULL, 'leisure',
   'est', NULL, TRUE, '콘도지원 (2025 지속가능경영보고서 61쪽 주요 복리후생 프로그램 항목) — 이용 횟수·지원 범위 미기재', 31),
  -- ── 가족 (family) — 2025 지속가능경영보고서 61쪽 ──
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀학자금지원 (2025 지속가능경영보고서 61쪽 주요 복리후생 프로그램 항목) — 지원 학령·한도 미기재', 40),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원 (2025 지속가능경영보고서 61쪽 주요 복리후생 프로그램 항목) — 경조금·경조휴가 기준 미기재', 41),
  -- ── 생활 · 금융 · 주거 (perks) — 2025 지속가능경영보고서 61쪽 ──
  (@comp_id, 'housing_loan', '주택자금 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택자금지원 (2025 지속가능경영보고서 61쪽 주요 복리후생 프로그램 항목) — 지원 방식·한도 미기재', 50),
  (@comp_id, 'welfare_point', '복지포인트 지급', NULL, 'perks',
   'est', NULL, TRUE, '복지포인트 지급 (2025 지속가능경영보고서 61쪽 주요 복리후생 프로그램 항목) — 연간 배정액 미기재', 51),
  -- ── 건강 (health) — 2025 지속가능경영보고서 61쪽 ──
  (@comp_id, 'insurance', '임직원 단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '임직원단체상해보험 (2025 지속가능경영보고서 61쪽 주요 복리후생 프로그램 항목) — 보장 범위·가족 포함 여부 미기재', 60),
  (@comp_id, 'health_check', '종합건강검진 지원', NULL, 'health',
   'est', NULL, TRUE, '종합건강검진 지원 (2025 지속가능경영보고서 61쪽 주요 복리후생 프로그램 항목) — 검진 주기·대상 범위 미기재', 61),
  (@comp_id, 'clinic', '건강관리실 (공장)', NULL, 'health',
   'est', NULL, TRUE, '건강관리실(공장) (2025 지속가능경영보고서 61쪽 주요 복리후생 프로그램 항목) — 운영 시간·상주 인력 미기재', 62),
  -- ── 휴가 (time_off) — 2025 지속가능경영보고서 13쪽 ──
  (@comp_id, 'leave_general', '워라밸 데이', NULL, 'time_off',
   'est', NULL, TRUE, '워라밸 데이 진행 (2025 지속가능경영보고서 13쪽 이해관계자 커뮤니케이션 임직원 대응 활동 항목) — 운영 방식·휴무 여부 미기재', 70)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
