-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 에스에프에이 복리후생 데이터 (신규 회사 — 웨이브 8)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://recruit.sfa.co.kr/sfa/welfare
-- badge: est
--
-- 참고:
--   정본: 에스에프에이 채용 사이트 복리후생 페이지 하나(5묶음 17칸 18라벨, 서버 렌더 HTML 텍스트 —
--     헤드리스 렌더 없음). 자기 홈 www.sfa.co.kr 헤더 RECRUIT 버튼이 recruit.sfa.co.kr/sfa/ 로 나간다.
--   보조 출처: 같은 채용 사이트 인사제도 페이지(/sfa/system) 성과급제도 문단 — incentive 1행.
--     OpenDART 2026 반기보고서(첨부추가, 접수 20260812000465) 직원 등 현황 유연근무제도 사용 현황 — flex_work 1행.
--     2025 사업보고서(기재정정, 접수 20260610000400) 별도재무제표 주석 기타장기종업원급여 — long_service_bonus 1행.
--     자기 도메인에 지속가능경영 · ESG 보고서 없음(지속가능경영 메뉴는 방침 문단뿐), 보도 게시판에 복지 글 없음.
--   귀속: 같은 호스트의 /sfasemicon/ 경로는 자회사 SFA반도체 것이라 쓰지 않았다. /sfa/welfare 는 제목 · 로고 ·
--     저작권(SFA) · 채용 메일 도메인(sfa.co.kr)이 이 법인이다. 두 페이지 17칸 중 글자까지 같은 칸은
--     식사제공 · 통근버스 둘뿐이고 나머지 15칸은 구성 · 문장이 달라 템플릿이 아니다. 그룹 · 계열사 문구 0회라 각주 없음.
--   금액: 원문에 원 · 만원 숫자 0건. 금액 행은 식대 1행뿐(조식 · 중식 · 석식 지원 →
--     하루 3끼 × 1끼 12,000원 × 연 240일 = 864, 추정). stated 0행. 개인연금 50퍼센트는 비율이라 NULL.
--   제외: 휴가제도 칸의 법정연차휴가 · 근무형태 칸의 주5일 근무제(법정) · 인사제도 페이지 임금구성의
--     정기상여율(복리후생 블록 밖 임금 구성) · 공시 우리사주조합 주주 표 한 칸 · 공시 원격근무제 사용자 0명 표.
--   기념선물 칸을 명절 · 창립기념일(holiday_gift)과 결혼기념일(birthday_gift)로 갈랐다.
--   경조금 · 명절선물이 경조사 · 기념선물 칸과 사우회 칸 두 곳에 나와 각각 event · holiday_gift 한 행에 합쳤다.
--   공고 근거 0행 / 전체 18행.
--   SORT 섹션: health 10 · leisure 20 · family 30 · work_env 40 · perks 50 · compensation 60
--     (정본 페이지 등장 순) · flexibility 70 (보조 출처).
-- 검증 · 감사 판정 반영(2026-10-15): 재무제표 주석 근속 행 이름을 장기근속 급부로(코퍼스 같은 근거 행과 같게) · 웰빙카드 행 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 18행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('sfa', '에스에프에이',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '산업기계', 'S', 'https://recruit.sfa.co.kr/sfa/welfare');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'sfa');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://recruit.sfa.co.kr/sfa/welfare'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강 (health) — 채용 사이트 복리후생 여가 · 문화생활 · 건강 ──
  (@comp_id, 'fitness', '웰빙카드 (삼성웰빙클럽 멤버십 월회비 지원)', NULL, 'health',
   'est', NULL, TRUE, '삼성웰빙클럽 멤버십 월회비 지원 (공식 채용 페이지 복리후생 여가·문화생활 웰빙카드 항목) — 이용 시설·지원 금액 미기재', 10),
  (@comp_id, 'health_check', '종합건강검진 (만 35세 이상 본인·배우자)', NULL, 'health',
   'est', NULL, TRUE, '만 35세 이상 본인 및 배우자(매년 실시) (공식 채용 페이지 복리후생 건강 종합건강검진 항목) — 검진 항목·비용 지원 범위 미기재', 11),
  (@comp_id, 'insurance', '단체보험', NULL, 'health',
   'est', NULL, TRUE, '단체보험 가입 : 개인질병 상해 보장, 3대 질병 보장 (공식 채용 페이지 복리후생 건강 단체보험 항목) — 보장 금액·가입 대상 범위 미기재', 12),

  -- ── 여가 (leisure) — 채용 사이트 복리후생 여가 · 문화생활 ──
  (@comp_id, 'resort', '휴양콘도 (한화·대명)', NULL, 'leisure',
   'est', NULL, TRUE, '전국 콘도(한화, 대명) 이용 (공식 채용 페이지 복리후생 여가·문화생활 휴양콘도 항목) — 이용 비용 지원·이용 횟수 미기재', 20),
  (@comp_id, 'club', '동호회 활동비 지원', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 활동비 지원 (공식 채용 페이지 복리후생 여가·문화생활 동호회 항목) — 지원 금액·동호회 종류 미기재', 21),

  -- ── 가족 (family) — 채용 사이트 복리후생 여가 · 문화생활 · 생활지원 · 복리후생 기타 ──
  (@comp_id, 'event', '경조사 지원 (경조휴가·경조금·장례비품)', NULL, 'family',
   'est', NULL, TRUE, '경조휴가 운영 (공식 채용 페이지 복리후생 여가·문화생활 휴가제도 항목), 경조휴가 부여, 경조금 지급, 장례비품 지원 (같은 페이지 복리후생 기타 경조사 항목), 사우회 경조금 지급 (같은 페이지 복리후생 기타 사우회 항목) — 경조 구분별 금액·휴가 일수 미기재', 30),
  (@comp_id, 'child_edu', '자녀 학자금 지원 (유치원·중·고·대학생)', NULL, 'family',
   'est', NULL, TRUE, '유치원,중·고·대학생 자녀 학자금 지원 (공식 채용 페이지 복리후생 생활지원 자녀학자금 항목) — 지원 금액·자녀 수 한도 미기재', 31),

  -- ── 근무환경 (work_env) — 채용 사이트 복리후생 회사생활 · 편의 ──
  (@comp_id, 'dormitory', '기숙사 (사외 아파트)', NULL, 'work_env',
   'est', NULL, TRUE, '기숙사, 사외 아파트 운영 (공식 채용 페이지 복리후생 회사생활·편의 기숙사 항목) — 입주 대상·입주 비용 미기재', 40),

  -- ── 생활 편의 (perks) — 채용 사이트 복리후생 회사생활 · 편의 · 생활지원 · 복리후생 기타 ──
  (@comp_id, 'meal', '식사 제공 (조식·중식·석식)', 864, 'perks',
   'est', '식사제공, 조식·중식·석식 지원 (공식 채용 페이지 복리후생 회사생활·편의 식사제공 항목) — 식대 단가·본인 부담 미기재 (하루 3끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 50),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '출퇴근 버스 운영 (공식 채용 페이지 복리후생 회사생활·편의 통근버스 항목) — 운행 노선·이용 비용 미기재', 51),
  (@comp_id, 'pension_support', '개인연금 지원 (50%)', NULL, 'perks',
   'est', NULL, TRUE, '개인연금 50% 지원 (공식 채용 페이지 복리후생 생활지원 개인연금 항목) — 지원 한도·가입 조건 미기재', 52),
  (@comp_id, 'welfare_fund_loan', '직원대출제도 (생활안정자금)', NULL, 'perks',
   'est', NULL, TRUE, '생활안정자금 마련을 위한 직원대출제도 운영 (공식 채용 페이지 복리후생 생활지원 대출제도 항목) — 대출 한도·이율 미기재', 53),
  (@comp_id, 'birthday_gift', '결혼기념일 선물', NULL, 'perks',
   'est', NULL, TRUE, '결혼기념일 선물 지급 (공식 채용 페이지 복리후생 기타 기념선물 항목) — 선물 종류·금액 미기재', 54),

  -- ── 보상 (compensation) — 채용 사이트 복리후생 기타 · 인사제도 · 2025 사업보고서 ──
  (@comp_id, 'excellence_award', '공적포상제도·SFA시상제도', NULL, 'compensation',
   'est', NULL, TRUE, '공적포상제도, SFA시상제도 (공식 채용 페이지 복리후생 기타 항목) — 포상 기준·포상 내용 미기재', 60),
  (@comp_id, 'holiday_gift', '명절·창립기념일 선물', NULL, 'compensation',
   'est', NULL, TRUE, '명절 및 창립기념일 선물 지급 (공식 채용 페이지 복리후생 기타 기념선물 항목), 사우회 명절선물 지급 (같은 페이지 복리후생 기타 사우회 항목) — 선물 종류·금액 미기재', 61),
  (@comp_id, 'incentive', '성과급제도', NULL, 'compensation',
   'est', NULL, TRUE, '경영성과에 근거하여 조직 및 개인 기여도에 따라 정기상여금과 별도로 성과급 지급 (공식 채용 페이지 인사제도 성과급제도 항목) — 지급률·지급 시기 미기재', 62),
  (@comp_id, 'long_service_bonus', '장기근속 급부 (5·10·20·30년 근속)', NULL, 'compensation',
   'est', NULL, TRUE, '장기 근속 임직원에게 장기종업원급여 제공, 장기간 근무(5년, 10년, 20년, 30년)한 임직원 대상 (2025 사업보고서 별도재무제표 주석 기타장기종업원급여 항목) — 급부 형태·금액 미기재', 63),

  -- ── 근무 유연성 (flexibility) — 2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 ──
  (@comp_id, 'flex_work', '선택근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 활용 여부 선택근무제, 선택근무제 사용자 2026년 상반기 616명 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 적용 대상 직무·근무 시간대 미기재', 70)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
