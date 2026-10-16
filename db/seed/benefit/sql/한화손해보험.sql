-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 한화손해보험 복리후생 데이터 (신규 회사 — 웨이브 11)
-- 출처: AI 파싱 (2026-10-16)
-- URL: https://www.hwgeneralins.com/intro/talenthall/benefits.do
-- badge: est
--
-- 참고:
--   정본은 상장 법인 한화손해보험(주)의 자기 도메인 www.hwgeneralins.com 인재채용 > 복리후생 페이지다.
--   원본 HTML 은 난독화 스크립트 셸이라 본문이 없고 헤드리스 렌더는 재적재 고리에 빠진다(웨이브 8 렌더 벽).
--   본문은 사용자가 브라우저로 연 화면을 붙여 넣은 사본(2026-10-16 · sha256 14291a45…)으로 읽었다. 다시 받지 않았다.
--   공시 보조: OpenDART 2026 반기보고서 기재정정(접수 20260831001182) · 2025 사업보고서 기재정정(접수 20260331000594)
--     직원 등 현황 유연근무제도 사용 현황(시차출퇴근제 · 원격근무제). 직원 3,730명(2026-06-30).
--   귀속: 자기 도메인 페이지이고 주어가 그룹이 아니다 — 각주 없음. 한화 계열 기등록 형제(한화 · 한화생명 · 한화투자증권 ·
--     한화시스템 · 한화오션 · 한화에어로스페이스)와 출처 도메인이 다르고 문장이 겹치지 않는다.
--   금액: meal 288 하나(중식대 지급 · 1끼 기준 단가 추정). 자녀학자금 400 · 800만원은 한도라 NULL.
--   제외: 법정(주 5일 근무제 · 연차휴가 관련 법령 · 산전산후휴가 최고 100일 — 원문이 법정분과 회사분을 가르지 않음 ·
--     육아휴직 최대 1년 6개월 · 일반검진) · 급여성(성과에 기반한 연봉제도 · 직무수당 · 전문자격증 수당) ·
--     임원 보수 산정 칸(경영성과급 · 복지포인트 · 설차례비 · 장기근속 일회성 보상) · 공시 선택근무제(전 기간 사용자 없음).
--   공고 근거 0행 / 전체 14행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(perks 10 · compensation 20 · time_off 30 · family 40 · health 50 · leisure 60),
--     공시에만 있는 flexibility 70.
-- 검증 · 감사 판정 반영(2026-10-16): 차량유지비 귀성여비 transport 서술에서 주거지원 몫을 걷고 무연고지 근무자 귀성여비만(주거보조비는 housing_support 행 몫) · 그 외 직원 매년 일반검진은 싣지 않음(리드 판정 147) · 산전산후휴가 최고 100일 · 육아휴직 1년 6개월은 법정 범위라 제외 유지 · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 14행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hanwha_general_ins', '한화손해보험',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '보험', 'H', 'https://www.hwgeneralins.com/intro/talenthall/benefits.do');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hanwha_general_ins');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.hwgeneralins.com/intro/talenthall/benefits.do'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 생활 · 금융 (perks) — 복리후생 급여 · 무연고지 근무자 주거지원 ──
  (@comp_id, 'meal', '중식대', 288, 'perks',
   'est', '중식대 지급 (공식 채용 페이지 복리후생 급여 항목) — 1식 단가·지급 방식 미기재 (하루 1끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 10),
  (@comp_id, 'transport', '차량유지비·귀성여비 (귀성여비는 무연고지 근무자)', NULL, 'perks',
   'est', NULL, TRUE, '차량유지비 등 지급 (공식 채용 페이지 복리후생 급여 항목), 무연고지 근무자 귀성여비 지급 (같은 페이지 무연고지 근무자 주거지원 항목) — 차량유지비 지급 대상·지급 금액 미기재', 11),
  (@comp_id, 'housing_support', '주거보조비 (무연고지 근무자)', NULL, 'perks',
   'est', NULL, TRUE, '무연고지 근무자 주거지원, 주거보조비 지급 (공식 채용 페이지 복리후생 무연고지 근무자 주거지원 항목) — 지급 금액·지급 기간 미기재', 12),

  -- ── 보상 · 금전 (compensation) — 복리후생 급여 ──
  (@comp_id, 'incentive', '직무에 따른 인센티브 제도', NULL, 'compensation',
   'est', NULL, TRUE, '직무에 따른 인센티브 제도 운영 (공식 채용 페이지 복리후생 급여 항목) — 지급 기준·지급률 미기재', 20),

  -- ── 휴가 (time_off) — 복리후생 휴가제도 ──
  (@comp_id, 'leave_general', '체력단련휴가 5일', NULL, 'time_off',
   'est', NULL, TRUE, '체력단련휴가: 5일 (공식 채용 페이지 복리후생 휴가제도 항목) — 휴가 부여 조건·유급 여부 미기재', 30),

  -- ── 가족 (family) — 복리후생 휴가제도 · WITH제도 · 자녀학자금 지원 · 사우회 운영 · 기타 복리후생제도 ──
  (@comp_id, 'event', '경조휴가·경조금·사우회 경조금', NULL, 'family',
   'est', NULL, TRUE, '경조사 시 규정에 따라 1-7일의 휴가 부여 (공식 채용 페이지 복리후생 휴가제도 경조휴가 항목), 각종 경조사(결혼, 사망, 회갑 등) 시 경조금 지급 (같은 페이지 기타 복리후생제도 항목), 사우회 운영, 경조사, 본인입원, 자녀출산 시에 회사경조금과는 별도로 경조금 등 지급 (같은 페이지 사우회 운영 항목) — 경조 유형별 금액 미기재', 40),
  (@comp_id, 'parenting', '맘스 패키지 (임신 직원)', NULL, 'family',
   'est', NULL, TRUE, '임신한 여직원의 경우, 맘스 패키지 지원(튼살크림, 손목보호대, 허브티, 전용샴푸, 치약+칫솔 등) (공식 채용 페이지 복리후생 WITH제도 항목) — 지원 시기 미기재', 41),
  (@comp_id, 'child_edu', '자녀학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀의 재학기간 중 학자금 지원, 지원금액: 중/고등학교 년 400만원 한도, 대학교 800만원 한도 (공식 채용 페이지 복리후생 자녀학자금 지원 항목) — 지원 자녀 수·대학교 한도 산정 기간 미기재', 42),

  -- ── 건강 (health) — 복리후생 건강검진 · 기타 복리후생제도 ──
  (@comp_id, 'health_check', '매년 종합검진', NULL, 'health',
   'est', NULL, TRUE, '만 30세 또는 1을 이상 직원: 매년 종합검진 (공식 채용 페이지 복리후생 건강검진 항목) — 「1을 이상」의 뜻·검진 항목·비용 지원 범위 미기재', 50),
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '단체상해보험 가입: 사망/후유장해 3억, 입원 및 통원 의료비, 치과담보 (공식 채용 페이지 복리후생 기타 복리후생제도 항목) — 가입 대상 범위·보험료 부담 미기재', 51),

  -- ── 여가 (leisure) — 복리후생 동호회 운영 · 기타 복리후생제도 ──
  (@comp_id, 'club', '동호회 운영', NULL, 'leisure',
   'est', NULL, TRUE, '직원 상호간 유대감 증대 및 건전한 여가활동 유도, 골프, 테니스, 축구, 스킨스쿠버 등 다양한 동호회 활동 (공식 채용 페이지 복리후생 동호회 운영 항목) — 회사 지원 금액·지원 방식 미기재', 60),
  (@comp_id, 'resort', '상설휴양소 운영', NULL, 'leisure',
   'est', NULL, TRUE, '상설휴양소 운영(전국 유명 관광지 콘도 이용) (공식 채용 페이지 복리후생 기타 복리후생제도 항목) — 이용 횟수·비용 부담 미기재', 61),

  -- ── 근무 유연성 (flexibility) — 2026 반기보고서 · 2025 사업보고서 직원 등 현황 유연근무제도 사용 현황 ──
  (@comp_id, 'flex_work', '시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 활용, 시차출퇴근제 사용자 수 2026년 상반기 1,304명·2025년 1,363명·2024년 982명·2023년 1,072명 (2026 반기보고서 · 2025 사업보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 70),
  (@comp_id, 'remote_work', '원격근무제(재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무 포함) 사용자 수 2026년 상반기 122명·2025년 634명·2024년 1,293명·2023년 1,141명 (2026 반기보고서 · 2025 사업보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 71)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
