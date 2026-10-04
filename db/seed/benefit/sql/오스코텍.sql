-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 오스코텍 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://oscotec.co.kr/notice/11153
-- badge: est
--
-- 참고:
--   정본은 법인 자기 도메인(oscotec.co.kr, Rhymix 서버 렌더) 헤더 메뉴 회사소개 > 공지사항의
--     2025 ESG FACT Book 발간 게시글(2026-09-28, 작성 전략기획팀)이다. 행 근거는 그 글의 첨부
--     오스코텍 ESG FactBook_2025_260930-2.pdf(27쪽, 회사 자기 발행 보고서) 15쪽 · 20쪽 · 22쪽.
--   인재채용 상시 페이지(/Careers)는 연구원 모집 공고 표뿐이고 복리후생 문구가 없다. 외부 ATS 없음(지원은 자기 도메인 게시판).
--   보조: OpenDART 2025 사업보고서(접수 20260319001005) · 2026 반기보고서(접수 20260814003016)
--     직원 등 현황 57명 · 유연근무제 활용 · 시차출퇴근제 사용자 수 — flex_work 보조 근거.
--   귀속: Fact Book 인력 지표 경계는 오스코텍 국내 법인 소속 직원(임원 제외)이다.
--     연결종속회사 제노스코(Genosco Inc. 등 미국 법인 포함) 복지 문구는 쓰지 않았다. 그룹 각주 없음.
--   법정 제도: 반일 단위 휴가 제도 · 일반 및 특수 건강검진(산업안전보건법) · 배우자 출산휴가 · 가족돌봄휴가 · 육아휴직은 싣지 않았다.
--     직원 57명 — 재취업지원 의무 대상 아님(원문에 해당 문구도 없음).
--   금액: 원문 금액 0. 구본 추정 승계 0(event 20 은 경조금 1회성, health_check 100 은 행 없음).
--   구본에서 뺀 행: excellence_award · health_check · medical · meal. 재코딩 0. 신규 코드 0.
--   SORT 섹션 순서 = Fact Book 쪽 순서(15쪽 일 생활 균형 flexibility 10 · 가족친화 제도 family 20 ·
--     15쪽 주석 time_off 30 · 20쪽 역량개발 growth 40).
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-7): Fact Book 22쪽 사내 임직원 추석 명절 선물로 holiday_gift 행 추가 · 지급 실적 0명 지표만 있는 출산축하금 · 난임시술비 · 자녀학자금 3행 삭제 — 최종 5행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('oscotec', '오스코텍',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '바이오/제약', 'O', 'https://oscotec.co.kr/notice/11153');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'oscotec');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://oscotec.co.kr/notice/11153'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — Fact Book 15쪽 일 생활 균형 · 사업보고서 ──
  (@comp_id, 'flex_work', '시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '시차출퇴근제 등 유연근무 방식 운영 (2025 ESG Fact Book 일·생활 균형 항목 · 2025 사업보고서 유연근무제도 사용 현황 항목) — 출퇴근 시간대·적용 조건 미기재', 10),

  -- ── 가족·돌봄 (family) — Fact Book 15쪽 일 생활 균형 · 가족친화 제도 ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조금 지원, 경조휴가 (2025 ESG Fact Book 가족친화 제도·일·생활 균형 항목) — 경조금 금액·휴가 일수·경조 범위 미기재', 20),

  -- ── 휴가 (time_off) — Fact Book 15쪽 주석 ──
  (@comp_id, 'long_service_leave', '장기근속 포상휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 포상휴가 (2025 ESG Fact Book 일·생활 균형 및 가족친화 제도 주석) — 근속 기준 연수·휴가 일수 미기재', 30),

  -- ── 성장·교육 (growth) — Fact Book 20쪽 임직원 역량개발 프로그램 ──
  (@comp_id, 'conference', '외부교육·학회 참가 지원', NULL, 'growth',
   'est', NULL, TRUE, '직무 관련 외부교육 및 전문연수 참여 지원, 연구직 중심 국내외 전문학회 및 세미나 참여 지원 (2025 ESG Fact Book 임직원 역량개발 프로그램 항목) — 지원 비용 범위·횟수 미기재', 40),

  -- ── 보상 (compensation) — Fact Book 22쪽 협력사 경영지원 활동 ──
  (@comp_id, 'holiday_gift', '추석 명절 선물', NULL, 'compensation',
   'est', NULL, TRUE, '사내 임직원 외 협력사 임직원에게 추석 명절 선물을 지급(2026년) (2025 ESG Fact Book 협력사 경영지원 활동 항목) — 사내 지급은 문맥상 · 상시 여부·품목·금액 미기재', 50)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
