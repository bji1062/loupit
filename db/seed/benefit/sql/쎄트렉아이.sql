-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 쎄트렉아이 복리후생 데이터 (신규 회사 — 웨이브 11)
-- 출처: AI 파싱 (2026-10-16)
-- URL: https://satreci.careerlink.kr/welfare
-- badge: est
--
-- 참고:
--   정본: 회사 채용 사이트 satreci.careerlink.kr 의 Benefit 페이지 /welfare(자기 도메인 www.satreci.com 헤더 인재채용이 링크).
--   robots 가 User-agent * 로 /welfare 를 막아 웨이브 8 에서 불가 — 이번에는 사용자가 브라우저로 연 화면 본문 사본
--   (user_paste_welfare.txt · 2026-10-16 UTC)으로 수집했다. 페이지는 다시 받지 않았다. 점검기는 robots(점검 안 함).
--   보조: OpenDART 2026 반기보고서(접수 20260813001317) 유연근무제도 사용 현황 표와 주석(2025 사업보고서 정정본
--   20260406004277 에도 같은 표 · 같은 주석) — flex_work 서술 보강 · remote_work 행.
--   귀속: 페이지 주어 = 쎄트렉아이. 최대주주 한화에어로스페이스 · 코퍼스 한화 계열 6사와 문장 겹침 없음. 각주 없음.
--   금액: welfare_point 연 160만 포인트(1포인트 1원 환산 추정) · meal 하루 3끼(1끼 12,000원 × 연 240일 추정) 2행.
--   신규입사자 월세 월 30만원은 대상 한정이라 금액 NULL.
--   제외: 여직원 보건휴가 월 1일(법정 생리휴가 · 유급 미기재) · 육아휴직 최대 1년(법정과 같음) · 동등한 님 문화(호칭 문화) ·
--   시차출퇴근제(공시 활용하지 않음). 공고 근거 0행 / 전체 19행.
--   SORT 섹션 순서 = flexibility 10 · time_off 20 · family 30 · leisure 40 · health 50 · perks 60 · growth 70 · compensation 80.
-- 검증 · 감사 판정 반영(2026-10-16): 명절 귀향비 holiday_gift 에 2026 반기보고서 이사 보수지급기준의 명절상여 전 임직원 동일 기준 정액 지급 구절 병합 · 이름 명절 귀향비·명절상여 · 2025 사업보고서 별도재무제표 주석 기타장기종업원급여 근거 장기근속 급부 long_service_bonus 추가(compensation 섹션 머리에 공시 두 출처) · 참고 블록의 공고 근거 0행 / 전체 19행은 전체 20행 · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 20행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('satrec_i', '쎄트렉아이',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '항공/방산', 'S', 'https://satreci.careerlink.kr/welfare');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'satrec_i');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://satreci.careerlink.kr/welfare'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — 채용 사이트 Benefit 선택적 근로시간제 / 2026 반기보고서 유연근무제도 사용 현황 ──
  (@comp_id, 'flex_work', '선택적 근로시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '코어타임을 제외하고는 내 출퇴근을 자유롭게 (공식 채용 사이트 Benefit 선택적 근로시간제 항목), 선택근무제(자율출퇴근제) 도입 및 활용, 1주 이내 정산기간에 대하여 근무 시작·종료시각 및 근무시간을 일 최소 근무시간을 준수하는 범위 내에서 조정 (2026 반기보고서 유연근무제도 사용 현황 항목)', 10),
  (@comp_id, 'remote_work', '원격근무제(재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무 포함) (2026 반기보고서 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 11),
  -- ── 휴가 (time_off) — 채용 사이트 Benefit 안식년 휴가 ──
  (@comp_id, 'long_service_leave', '안식년 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '안식년 휴가 5년 근속 시 15일, 10년 근속 시 30일 (공식 채용 사이트 Benefit 안식년 휴가 항목) — 유급 여부·사용 기한 미기재', 20),
  -- ── 가족 (family) — 채용 사이트 Benefit 경조 휴가 · 상조물품 지원 · 자녀 학자금 지원 · 영유아 보육수당 ──
  (@comp_id, 'event', '경조휴가·경조비·상조물품 지원', NULL, 'family',
   'est', NULL, TRUE, '기쁜일, 슬픈일 모두 경조휴가, 경조비 지원 (공식 채용 사이트 Benefit 경조 휴가 항목), 가족의 조사 발생 시 상조물품 및 근조화환 지원 (같은 페이지 상조물품 지원 항목) — 경조금 금액·휴가 일수 미기재', 30),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '국내 대학생 자녀 학자금 지원 (공식 채용 사이트 Benefit 자녀 학자금 지원 항목) — 지원 한도·자녀 수 제한 미기재', 31),
  (@comp_id, 'parenting', '영유아 보육수당', NULL, 'family',
   'est', NULL, TRUE, '4~6세 자녀의 보육수당 지원 (공식 채용 사이트 Benefit 영유아 보육수당 항목) — 지급 금액·지급 주기 미기재', 32),
  -- ── 여가 (leisure) — 채용 사이트 Benefit 콘도 이용 · Meet-up Day · 사내 동호회 활동 지원 ──
  (@comp_id, 'resort', '콘도 이용', NULL, 'leisure',
   'est', NULL, TRUE, '콘도 이용, 전국의 대명, 한화, 호반, 비체팰리스 등 회원가 이용 가능 (공식 채용 사이트 Benefit 콘도 이용 항목) — 이용 횟수·숙박비 지원 여부 미기재', 40),
  (@comp_id, 'culture_day', 'Meet-up Day', NULL, 'leisure',
   'est', NULL, TRUE, '매달 1회 다양한 주제로 다른 부서원들과 함께하는 취미생활을 회사가 지원 (공식 채용 사이트 Benefit Meet-up Day 항목) — 지원 방식·비용 범위 미기재', 41),
  (@comp_id, 'club', '사내 동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '축구, 야구, 등산, 밴드 등 사내 동호회 활동 지원 (공식 채용 사이트 Benefit 사내 동호회 활동 지원 항목) — 활동비 지원 금액 미기재', 42),
  -- ── 건강 (health) — 채용 사이트 Benefit 건강검진·검진휴가 · 단체보험 · 임직원 건강 관리 · 심리상담 ──
  (@comp_id, 'health_check', '건강검진·검진휴가 지원', NULL, 'health',
   'est', NULL, TRUE, '매년 1회 본인과 배우자 또는 가족 1명의 건강검진과 검진휴가 지원 (공식 채용 사이트 Benefit 건강검진&검진휴가 지원 항목) — 검진 비용 지원 범위·검진휴가 일수 미기재', 50),
  (@comp_id, 'insurance', '단체보험 가입', NULL, 'health',
   'est', NULL, TRUE, '임직원 및 가족 보험 가입 (공식 채용 사이트 Benefit 단체보험 가입 항목) — 보장 내용·가족 범위 미기재', 51),
  (@comp_id, 'clinic', '임직원 건강 관리 (의사·간호사 방문)', NULL, 'health',
   'est', NULL, TRUE, '매월 의사 및 간호사 방문 검진 (공식 채용 사이트 Benefit 임직원 건강 관리 항목) — 검진 항목·상담 범위 미기재', 52),
  (@comp_id, 'mental', '심리상담 지원', NULL, 'health',
   'est', NULL, TRUE, '지치고 힘든 마음을 털어놓을 심리상담 지원 (공식 채용 사이트 Benefit 심리상담 지원 항목) — 상담 횟수·운영 방식 미기재', 53),
  -- ── 경제적 부가혜택 (perks) — 채용 사이트 Benefit 복지포인트 지급 · 신규입사자 주거안정지원 · 사내 식당 운영 ──
  (@comp_id, 'welfare_point', '복지포인트', 160, 'perks',
   'est', '연 160만 + α 복지포인트 지급 (공식 채용 사이트 Benefit 복지포인트 지급 항목) — 추가분(α) 기준·사용처 미기재, 1포인트 1원 기준 환산', FALSE, NULL, 60),
  (@comp_id, 'housing_support', '신규입사자 주거안정지원', NULL, 'perks',
   'est', NULL, TRUE, '신규입사자 월 30만원 월세 지원 (공식 채용 사이트 Benefit 신규입사자 주거안정지원 항목) — 지원 기간·대상 요건 미기재', 61),
  (@comp_id, 'meal', '사내 식당 (조·중·석식)', 864, 'perks',
   'est', '사내 식당 운영, 조·중·석식 제공, 점심 샐러드, 아침/저녁 Pick-UP 식사 포함 (공식 채용 사이트 Benefit 사내 식당 운영 항목) — 식대 단가·본인 부담 여부 미기재 (하루 3끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 62),
  -- ── 성장 (growth) — 채용 사이트 Benefit 자기개발 기회 제공 ──
  (@comp_id, 'conference', '국내·외 학회 참여·교육', NULL, 'growth',
   'est', NULL, TRUE, '국내·외 학회 참여, 교육 장려 (공식 채용 사이트 Benefit 자기개발 기회 제공 항목) — 비용 지원 범위·대상 미기재', 70),
  (@comp_id, 'mba', '대학원 수학 장려', NULL, 'growth',
   'est', NULL, TRUE, '대학원 수학 장려 (공식 채용 사이트 Benefit 자기개발 기회 제공 항목) — 학비 지원 여부·선발 기준 미기재', 71),
  -- ── 보상·금전 (compensation) — 채용 사이트 Benefit 명절 귀향비 지원 · 2026 반기보고서 · 2025 사업보고서 ──
  (@comp_id, 'holiday_gift', '명절 귀향비·명절상여', NULL, 'compensation',
   'est', NULL, TRUE, '명절 귀향비 지원, 명절을 위한 설, 추석 휴가비 지원 (공식 채용 사이트 Benefit 항목), 명절상여 전 임직원 동일 기준에 따라 정액 지급 (2026 반기보고서 이사 보수지급기준 항목) — 지급 금액 미기재', 80),
  (@comp_id, 'long_service_bonus', '장기근속 급부', NULL, 'compensation',
   'est', NULL, TRUE, '장기 근속 임직원에게 장기종업원급여 제공, 주로 5년 이상 장기간 근무한 임직원 대상 (2025 사업보고서 재무제표 주석 기타장기종업원급여 항목) — 급부 형태·금액 미기재', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
