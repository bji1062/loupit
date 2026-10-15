-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 미래에셋생명 복리후생 데이터 (신규 회사 — 웨이브 8)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://life.miraeasset.com/micro/company/PC-HO-060401-000000.do?year=2025
-- badge: est
--
-- 참고:
--   정본은 상장 법인 미래에셋생명보험(주)의 자기 도메인 life.miraeasset.com 회사소개 > 투자정보(IR) > IR자료실
--   2025 연도 목록이다. 이 목록에 법인 단독 발행 미래에셋생명 지속가능경영보고서 2025 PDF 가 올라 있다
--   (발간 2026-06 · 보고 기간 2025-01-01~2025-12-31 · 비재무 보고 범위 자회사 제외 미래에셋생명 국내 전 사업장).
--   ESG 경영 페이지(PC-HO-060901)의 지속가능경영보고서 버튼이 이 IR자료실로 연결된다. 2026 연도 목록에는 보고서가 없다.
--   행 근거는 보고서 33 · 34 · 36 · 37 · 42쪽. SSR 목록 + PDF 텍스트 추출 — 헤드리스 렌더 · 이미지 판독 불필요.
--   공시 보조: OpenDART 2026 반기보고서 기재정정(접수 20260831001303) 직원 등 현황 유연근무제도 사용 현황(선택근무제 사용자 수).
--   직원 787명(2026-06-30).
--   귀속: 보고서 문장 주어가 미래에셋생명은 이고 법인 단독 발행이라 각주 없음. 그룹 채용 사이트는 읽지 않았다
--   (miraeasset.recruiter.co.kr robots Disallow / · career.miraeasset.com 접속 확인 화면 429). 기등록 미래에셋 형제 없음.
--   금액: 원문에 복지 금액 숫자 0건 — 전 행 BENEFIT_AMT NULL.
--   제외: 법정(임산부 근로시간 단축 · 출산 전후 휴가 90일 · 유산 사산 휴가 · 배우자 출산 휴가 20일 · 육아휴직 1년 ·
--     육아기 근로시간 단축 · 유급 수유시간 · 가족돌봄 휴직 90일 · 퇴직연금 DB/DC · 감정노동자 보호 온라인 교육) ·
--     업무 교육(신입 온보딩 · 커뮤니케이션 데이 · 직무역량 · AI 데이터분석 아카데미 · 리더십 · 승진자) ·
--     성과연봉제 7단계 평가(급여 결정 체계) · 노사협의회 논의 안건(EAP 운영 · 교통비 상향 · 연차보상 확대 — 논의일 뿐 시행 문장 없음) ·
--     임원 보수 칸 통신비 · 체력단련비 · 임직원 성과보수 자기주식 지급(임원 성과보수 이연 체계) · 우리사주조합 주주 표 한 칸.
--   공고 근거 0행 / 전체 10행.
--   SORT 섹션 순서 = 보고서 등장 순(growth 10 · leisure 20 · flexibility 30 · family 40 · health 50).
-- 검증 · 감사 판정 반영(2026-10-15): 행 조치 없음 · 위탁보육료 행 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 10행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('mirae_asset_life', '미래에셋생명',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '보험', 'M', 'https://life.miraeasset.com/micro/company/PC-HO-060401-000000.do?year=2025');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'mirae_asset_life');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://life.miraeasset.com/micro/company/PC-HO-060401-000000.do?year=2025'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 성장 (growth) — 2025 지속가능경영보고서 33 · 34 · 36쪽 ──
  (@comp_id, 'edu_support', '온라인 교육 플랫폼 M-Space·워킹맘 & 워킹대디 행복 찾기 특강', NULL, 'growth',
   'est', NULL, TRUE, '온라인 교육 플랫폼 M-Space를 통해 이러닝, 마이크로 러닝, 콘텐츠 큐레이션 등 교육 환경 제공, 학습 이력 데이터 기반 개인별 맞춤형 콘텐츠 추천 (2025 지속가능경영보고서 34쪽 온라인 교육 플랫폼 항목), 일과 육아를 병행하는 워킹맘과 워킹대디에게 자녀와의 소통 노하우를 제공하고 사전 접수된 고민에 전문가가 맞춤형 솔루션을 제시하는 워킹맘 & 워킹대디 행복 찾기 특강 (2025 지속가능경영보고서 36쪽 조직문화 항목) — 수강 대상·운영 주기 미기재', 10),
  (@comp_id, 'self_development', '전문자격 지원제도', NULL, 'growth',
   'est', NULL, TRUE, '10개 직무 분야별 55개 전문자격 대상 수강료, 교재비, 응시료 등 지원, FSA·CFA 등 국제공인 전문자격과 보험계리사·세무사·감정평가사·손해사정사·법무사·공인노무사, 컴플라이언스 오피서·클라우드 전문 자격증 포함 (2025 지속가능경영보고서 34쪽 전문자격 지원제도 운영 항목) — 지원 한도·지원 조건 미기재', 11),

  -- ── 여가 · 행사 (leisure) — 2025 지속가능경영보고서 33 · 36쪽 ──
  (@comp_id, 'library', '전자도서관', NULL, 'leisure',
   'est', NULL, TRUE, '전자도서관 등 교육 인프라 구축 (2025 지속가능경영보고서 33쪽 인재육성 HR 전략 항목) — 이용 방식·장서 규모 미기재', 20),
  (@comp_id, 'company_event', '게임하고 숙박하계', NULL, 'leisure',
   'est', NULL, TRUE, '여름 휴가 시즌 임직원 재충전을 위한 숙박하계 프로그램, 액티비티 형식의 직원 참여형 게임을 열고 참여 우수자에게 숙박권과 외식 기프티콘 제공 (2025 지속가능경영보고서 36쪽 조직문화 게임하고 숙박하계 항목) — 운영 주기·혜택 선정 기준 미기재', 21),

  -- ── 근무 유연성 (flexibility) — 2025 지속가능경영보고서 37쪽 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '선택적 근로시간제·점심시간선택제', NULL, 'flexibility',
   'est', NULL, TRUE, '선택적 근로시간제를 운영하여 유연한 근무 지원, 2025년 임직원 선호에 따라 점심시간을 선택할 수 있는 점심시간선택제 시행 (2025 지속가능경영보고서 37쪽 맞춤형 복리후생 제도 항목), 선택근무제 사용자 수 563명 적용대상자 기준 (2026 반기보고서 유연근무제도 사용 현황 항목) — 코어타임·근무 가능 시간대 미기재', 30),
  (@comp_id, 'pc_off', 'PC-on/off 제도', NULL, 'flexibility',
   'est', NULL, TRUE, '임직원 근로환경 개선 방안으로 PC-on/off 제도를 도입해 불필요한 연장근로 감축 (2025 지속가능경영보고서 37쪽 맞춤형 복리후생 제도 항목) — 적용 시각·예외 승인 방식 미기재', 31),

  -- ── 가족 (family) — 2025 지속가능경영보고서 37쪽 ──
  (@comp_id, 'parenting', '위탁보육료 제공', NULL, 'family',
   'est', NULL, TRUE, '만 5세 이하 자녀가 다니고 있는 어린이집과 위탁계약을 체결하여 위탁보육료 제공 (2025 지속가능경영보고서 37쪽 지원 제도 표 육아 위탁보육료 제공 항목) — 지원 금액·한도 미기재', 40),

  -- ── 건강 (health) — 2025 지속가능경영보고서 37 · 42쪽 ──
  (@comp_id, 'health_check', '종합건강검진 (직원·배우자)', NULL, 'health',
   'est', NULL, TRUE, '직원 및 배우자 종합건강검진 지원, 직원 매년·배우자 격년, 45세 이상 직원 정밀건강검진 (2025 지속가능경영보고서 37쪽 임직원 건강 항목), 영등포구 보건소 대사증후군 센터와 연계한 건강클리닉에서 혈액검사·혈압·인바디 검사 등 건강 검진과 전문가 상담 제공 (2025 지속가능경영보고서 42쪽 건강관리 프로그램 항목) — 검진 비용 지원 범위 미기재', 50),
  (@comp_id, 'mental', '마음건강관리 지원·힐링 및 스트레스 관리 특강', NULL, 'health',
   'est', NULL, TRUE, '감정노동 직무를 수행하는 임직원 대상 Mental Care 관리 서비스 제공과 직무 스트레스 원인과 결과 탐색 등 개인 맞춤형 프로그램 운영 (2025 지속가능경영보고서 42쪽 마음건강관리 지원 항목), 심리경영 프로그램으로 한국 차 테이스팅, 오감 차명상, 크리스마스 리스 만들기 등 체험형 힐링 특강 운영 (2025 지속가능경영보고서 42쪽 힐링 및 스트레스 관리 특강 항목) — 이용 방식·운영 주기 미기재', 51),
  (@comp_id, 'fitness', '건강관리 챌린지·걷기챌린지', NULL, 'health',
   'est', NULL, TRUE, '여의도 본사 피트니스 센터에서 인바디 장비로 체지방률을 측정하는 8주 건강관리 챌린지 등 맞춤형 건강 증진 프로그램 운영, M-LIFE 앱으로 참여하는 4주 걷기챌린지 프로그램 스텝토피아 운영 (2025 지속가능경영보고서 42쪽 건강관리 프로그램·걷기챌린지 항목) — 피트니스 센터 이용 조건·운영 주기 미기재', 52)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
