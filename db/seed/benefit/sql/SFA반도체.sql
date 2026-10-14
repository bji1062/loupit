-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SFA반도체 복리후생 데이터 (신규 회사 — 웨이브 6)
-- 출처: AI 파싱 (2026-10-14)
-- URL: https://recruit.sfa.co.kr/sfasemicon/welfare
-- badge: est
--
-- 참고:
--   정본: SFA반도체 채용 사이트 복리후생 페이지 하나(5카테고리 15항목, 서버 렌더 HTML 텍스트 —
--     헤드리스 렌더 없음). 원문은 프로브가 2026-10-14 에 받은 사본을 그대로 썼다.
--   귀속: 자기 도메인 www.sfasemicon.com 메인 채용소식 배너와 사이트맵 채용정보가
--     recruit.sfa.co.kr/sfasemicon/ 로 나간다. 호스트는 최대주주 SFA 와 함께 쓰지만
--     /sfasemicon/ 경로는 제목 · 로고 · 저작권(SFA SEMICON) · 지원 메일 도메인이 전부 이 법인이다.
--     같은 호스트의 /sfa/welfare(모회사 SFA)는 항목 구성과 문장이 달라 섞지 않았다
--     (웰빙카드 · 개인연금 50퍼센트 · 대출제도 · 주5일은 SFA 것). 그룹 · 계열사 문구 0회라 그룹 각주 없음.
--   보조 출처: OpenDART 2026 반기보고서(기재정정, 접수 20261013000104) 직원 등 현황
--     유연근무제도 사용 현황 — flex_work 1행. 2025 사업보고서(접수 20260323000826)도 보았다.
--     자기 도메인 보도자료 게시판은 게시물 0, 지속가능경영 · ESG 보고서 없음.
--   금액: 원문에 원 · 만원 숫자 0건. 금액 행은 식대 1행뿐(조식 · 중식 · 석식 지원 →
--     하루 3끼 × 1끼 12,000원 × 연 240일 = 864, 추정). stated 0행.
--   제외: 제휴업체 할인(제휴처 · 영역이 적히지 않은 이름뿐 제휴 할인) · 2025 사업보고서의
--     시차출퇴근제(더 새 반기보고서 표에서 빠짐). 법정 제도는 원문에 없다.
--   경조금이 경조사 항목과 사우회/사내근로복지기금 항목 두 곳에 나와 event 한 행에 합쳤다.
--   공고 근거 0행 / 전체 15행.
--   SORT 섹션: work_env 10 · perks 20 · health 30 · growth 40 · leisure 50 · family 60 ·
--     compensation 70 (정본 페이지 등장 순) · flexibility 80 (보조 출처).
-- 검증 · 감사 판정 반영(2026-10-14): 제휴업체 할인 discount 추가(참고 블록 제외 목록의 제휴업체 할인 줄은 이 판정으로 뒤집힘) · 반기보고서의 직원과 함께 산정하는 개인성과급 incentive 추가 — 최종 17행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('sfa_semicon', 'SFA반도체',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체후공정', 'S', 'https://recruit.sfa.co.kr/sfasemicon/welfare');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'sfa_semicon');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://recruit.sfa.co.kr/sfasemicon/welfare'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무환경 (work_env) — 채용 사이트 복리후생 회사생활 · 편의 ──
  (@comp_id, 'dormitory', '기숙사 (사내·사외)', NULL, 'work_env',
   'est', NULL, TRUE, '사내/사외 기숙사 운영 (공식 채용 페이지 복리후생 회사생활·편의 기숙사 항목) — 입주 대상·입주 비용 미기재', 10),

  -- ── 생활 편의 (perks) — 채용 사이트 복리후생 회사생활 · 편의 ──
  (@comp_id, 'meal', '식사 제공 (조식·중식·석식)', 864, 'perks',
   'est', '조식·중식·석식 지원 (공식 채용 페이지 복리후생 회사생활·편의 식사제공 항목) — 식대 단가·본인 부담 미기재 (하루 3끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 20),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '출퇴근 버스 운영 (공식 채용 페이지 복리후생 회사생활·편의 통근버스 항목) — 운행 노선·이용 비용 미기재', 21),
  (@comp_id, 'discount', '제휴업체 할인', NULL, 'perks',
   'est', NULL, TRUE, '제휴업체 할인 (공식 채용 페이지 복리후생 기타 제휴업체 할인 항목) — 제휴처·할인율 미기재', 22),

  -- ── 건강 (health) — 채용 사이트 복리후생 회사생활 · 편의 · 건강 ──
  (@comp_id, 'fitness', '사내 헬스장', NULL, 'health',
   'est', NULL, TRUE, '사내 헬스장 운영 (공식 채용 페이지 복리후생 회사생활·편의 헬스장 항목) — 운영 시간·이용 비용 미기재', 30),
  (@comp_id, 'health_check', '종합검진 (본인·배우자)', NULL, 'health',
   'est', NULL, TRUE, '종합검진, 만35세 이상 본인(매년)/ 배우자(격년) 실시 (공식 채용 페이지 복리후생 건강 종합검진 항목) — 검진 항목·비용 지원 범위 미기재', 31),
  (@comp_id, 'insurance', '단체보험', NULL, 'health',
   'est', NULL, TRUE, '단체보험 가입, 개인질병 상해보장, 3대 질병보장 (공식 채용 페이지 복리후생 건강 단체보험 가입 항목) — 보장 금액·가입 대상 범위 미기재', 32),

  -- ── 성장 (growth) — 채용 사이트 복리후생 회사생활 · 편의 ──
  (@comp_id, 'edu_support', '사내대학 운영', NULL, 'growth',
   'est', NULL, TRUE, '사내대학 운영 (공식 채용 페이지 복리후생 회사생활·편의 사내대학 운영 항목) — 교육 과정·수강 대상·학위 여부 미기재', 40),

  -- ── 여가 (leisure) — 채용 사이트 복리후생 여가 · 문화생활 ──
  (@comp_id, 'resort', '휴양콘도', NULL, 'leisure',
   'est', NULL, TRUE, '휴양콘도, 휘닉스파크(평창,제주), 한화, 오션캐슬 (공식 채용 페이지 복리후생 여가·문화생활 휴양콘도 항목) — 이용 비용 지원·이용 횟수 미기재', 50),
  (@comp_id, 'club', '동호회 활동비 지원', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 운영, 동호회 활동비 지원 (공식 채용 페이지 복리후생 여가·문화생활 동호회 운영 항목) — 지원 금액·동호회 종류 미기재', 51),

  -- ── 가족 (family) — 채용 사이트 복리후생 생활지원 · 복리후생 기타 ──
  (@comp_id, 'child_edu', '자녀 학자금 지원 (유치원~대학)', NULL, 'family',
   'est', NULL, TRUE, '유치원, 초·중·고·대학생 자녀 학자금 지원 (공식 채용 페이지 복리후생 생활지원 항목) — 지원 금액·자녀 수 한도 미기재', 60),
  (@comp_id, 'event', '경조사 지원 (경조휴가·경조금·장례비품)', NULL, 'family',
   'est', NULL, TRUE, '경조휴가 부여, 경조금 지급 (공식 채용 페이지 복리후생 기타 경조사 항목), 사우회/사내근로복지기금 경조금, 장례비품지원 (같은 페이지 사우회/사내근로복지기금 항목) — 경조 구분별 금액·휴가 일수 미기재', 61),

  -- ── 보상 (compensation) — 채용 사이트 복리후생 기타 ──
  (@comp_id, 'excellence_award', '우수사원 시상제도', NULL, 'compensation',
   'est', NULL, TRUE, '우수사원 시상제도 (공식 채용 페이지 복리후생 기타 우수사원/장기근속 시상제도 항목) — 시상 기준·포상 내용 미기재', 70),
  (@comp_id, 'long_service_bonus', '장기근속 시상제도', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 시상제도 (공식 채용 페이지 복리후생 기타 우수사원/장기근속 시상제도 항목) — 근속 연수 기준·포상 내용 미기재', 71),
  (@comp_id, 'holiday_gift', '명절·창립기념일 선물', NULL, 'compensation',
   'est', NULL, TRUE, '기념일 선물, 명절 및 창립기념일 (공식 채용 페이지 복리후생 기타 기념일 선물 항목) — 선물 종류·금액 미기재', 72),
  (@comp_id, 'incentive', '개인성과급', NULL, 'compensation',
   'est', NULL, TRUE, '「직원과 함께 개인성과급 산정」 (2026 반기보고서 이사·감사의 보수지급기준 등기이사 성과급 항목) — 직원 지급 기준·지급률 미기재', 73),

  -- ── 근무 유연성 (flexibility) — 2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 ──
  (@comp_id, 'flex_work', '선택근무제·탄력근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 활용, 선택근무제·탄력근무제 활용, 선택근무제 사용자 2026년 상반기 29명 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 적용 대상 직무·근무 시간대 미기재', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
