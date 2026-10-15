-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 신영증권 복리후생 데이터 (신규 회사 — 웨이브 8)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://shinrecruit.shinyoung.com/PRS/recuPRSCmpsValuation
-- badge: est
--
-- 참고:
--   정본은 상장 법인 신영증권(주)의 자기 도메인 채용 사이트 shinrecruit.shinyoung.com 회사소개 > 인사제도 페이지다
--   (채용 사이트 메인 /COM/MainForm 헤더 메뉴 회사소개 > 인사제도 링크). robots.txt 404 = 규칙 없음.
--   SSR 이라 원본 HTML 에 보상 및 평가 · 교육제도 · 복리 후생 제도(15항목) · 휴가제도(4항목) 텍스트가 다 있다.
--   헤드리스 렌더 · 이미지 판독 불필요. www.shinyoung.com 은 robots 가 모든 UA 에 Disallow / 라 받지 않았다.
--   공시 보조: OpenDART 사업보고서(2026.03 · 제72기 · 접수 20260611000685) 직원 등 현황 유연근무제도 사용현황 표
--   (선택근무제 · 원격근무제(재택근무 포함) 사용자 수) — flexibility 2행.
--   귀속: 법인 자기 도메인 채용 사이트 · 법인 단독 공시라 각주 없음. 코퍼스 · 대기 폴더에 신영 계열 형제 없음.
--   금액: 원문 숫자는 한도(의료비 1,000만원 · 치과비 50만원) · 1회성 근속 급부(안식휴가비 100 · 200 · 400만원)뿐 —
--     전 행 BENEFIT_AMT NULL.
--   제외: 법정(법정휴가 연차휴가 · 공가 · 법정의무교육) · 업무 교육(직무 · 직급 · 자격관리 · ADVANCED 사내교육,
--     금융투자교육원 등 사외교육 과정 목록) · 연봉제 · 평가제도 · 임원 성과급 · 성과보상 대상자 자기주식 교부(공시).
--   공고 근거 0행 / 전체 19행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(compensation 10 · family 20 · health 30 · leisure 40 · perks 50 ·
--     growth 60 · time_off 70), 공시에만 있는 flexibility 80.
-- 검증 · 감사 판정 반영(2026-10-15): 정기휴가를 leave_general 에서 refresh_leave 로 재코딩 · 명절 행에서 가을행사 기념품을 company_event 로 분리 추가 — 최종 20행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('shinyoung_sec', '신영증권',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '증권', 'S', 'https://shinrecruit.shinyoung.com/PRS/recuPRSCmpsValuation');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'shinyoung_sec');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://shinrecruit.shinyoung.com/PRS/recuPRSCmpsValuation'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상 (compensation) — 정본 보상 및 평가 · 복리 후생 제도 ──
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '직원 개개인의 종합평가 결과에 근거한 성과급 지급 (공식 채용 사이트 인사제도 보상제도 항목) — 지급 기준·지급률 미기재', 10),
  (@comp_id, 'long_service_bonus', '안식휴가비·장기근속자 포상', NULL, 'compensation',
   'est', NULL, TRUE, '안식휴가비 5년 근속시 100만원, 10년 근속시 200만원, 15년 이상 근속시 매 5년마다 400만원 지원 (공식 채용 사이트 인사제도 복리 후생 제도 안식휴가비 항목), 장기근속자 포상 지원 (같은 표 기타 복리후생 항목) — 장기근속자 포상 기준·포상 내용 미기재', 11),
  (@comp_id, 'holiday_gift', '명절 선물·경로효친비', NULL, 'compensation',
   'est', NULL, TRUE, '명절 경로효친비 및 명절 선물 지원 (공식 채용 사이트 인사제도 복리 후생 제도 명절 항목) — 금액·품목 미기재', 12),

  -- ── 가족 (family) — 정본 복리 후생 제도 · 휴가제도 ──
  (@comp_id, 'event', '경조사 지원·경조휴가', NULL, 'family',
   'est', NULL, TRUE, '경조금(결혼 및 출산, 사망, 본인 및 배우자 부모 칠순 등) 및 화환, 조화 등 지원 (공식 채용 사이트 인사제도 복리 후생 제도 경조사 항목), 각종 경조휴가 (같은 페이지 휴가제도 항목) — 경조금 금액·휴가 일수 미기재', 20),
  (@comp_id, 'child_edu', '학자금 (유치원·대학교)', NULL, 'family',
   'est', NULL, TRUE, '유치원 및 대학교 학자금 지급 (공식 채용 사이트 인사제도 복리 후생 제도 학자금 항목) — 지급 대상·금액·한도 미기재', 21),

  -- ── 건강 (health) — 정본 복리 후생 제도 ──
  (@comp_id, 'medical', '의료비·치과비 지원', NULL, 'health',
   'est', NULL, TRUE, '의료비 본인 및 건강보험증에 등재된 가족에게 연간 1,000만원 한도 지원, 치과비 본인이 사용한 치과진료비를 연간 50만원 한도 지원 (공식 채용 사이트 인사제도 복리 후생 제도 의료비·치과비 항목) — 본인 부담 기준·지원 비율 미기재', 30),
  (@comp_id, 'health_check', '종합건강검진', NULL, 'health',
   'est', NULL, TRUE, '격년 주기로 종합건강검진 실시 (공식 채용 사이트 인사제도 복리 후생 제도 건강검진 항목) — 검진 대상·비용 지원 범위 미기재', 31),
  (@comp_id, 'massage', '힐링라운지 운영 (헬스키퍼 마사지·세라젬)', NULL, 'health',
   'est', NULL, TRUE, '힐링라운지 운영, 헬스키퍼 마사지·세라젬 사전 예약을 통해 이용 가능 (공식 채용 사이트 인사제도 복리 후생 제도 힐링라운지 운영 항목) — 이용 횟수·운영 시간 미기재', 32),
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '단체상해보험 가입 지원 (공식 채용 사이트 인사제도 복리 후생 제도 항목) — 보장 범위·가입 대상 미기재', 33),

  -- ── 여가 (leisure) — 정본 복리 후생 제도 ──
  (@comp_id, 'club', '동호회비 지원', NULL, 'leisure',
   'est', NULL, TRUE, '세무동호회, 축구동호회, 독서동호회 등 사내 동호회 활동에 대한 경비 지원 (공식 채용 사이트 인사제도 복리 후생 제도 동호회비 항목) — 지원 금액·한도 미기재', 40),
  (@comp_id, 'resort', '콘도 이용 지원', NULL, 'leisure',
   'est', NULL, TRUE, '전국 각지의 회사 보유 콘도 이용 지원 (공식 채용 사이트 인사제도 복리 후생 제도 콘도이용 항목) — 이용 횟수·비용 부담 미기재', 41),
  (@comp_id, 'company_event', '가을행사 기념품', NULL, 'leisure',
   'est', NULL, TRUE, '가을행사 기념품 지원 (공식 채용 사이트 인사제도 복리 후생 제도 기타 복리후생 항목) — 행사 내용·기념품 품목 미기재', 42),

  -- ── 생활·금융 (perks) — 정본 복리 후생 제도 ──
  (@comp_id, 'housing_loan', '주택자금대출', NULL, 'perks',
   'est', NULL, TRUE, '직원의 전세자금 및 주택 구입자금 대출 지원 (공식 채용 사이트 인사제도 복리 후생 제도 주택자금대출 항목) — 대출 한도·이율·자격 요건 미기재', 50),
  (@comp_id, 'welfare_point', '선택적 복리후생제도', NULL, 'perks',
   'est', NULL, TRUE, '개인별 부여 포인트 내에서 여가활동 등을 위해 사용한 비용 지원 (공식 채용 사이트 인사제도 복리 후생 제도 선택적 복리후생제도 항목) — 포인트 규모 미기재', 51),

  -- ── 성장 (growth) — 정본 복리 후생 제도 ──
  (@comp_id, 'self_development', '자격증 취득 경비 지원', NULL, 'growth',
   'est', NULL, TRUE, '자격증 취득 시 소요 경비 지원 (공식 채용 사이트 인사제도 복리 후생 제도 교육비 지원 항목) — 대상 자격증·지원 한도 미기재', 60),
  (@comp_id, 'edu_support', '직무관련 교육비 지원', NULL, 'growth',
   'est', NULL, TRUE, '교육비 지원, 직무관련 교육 이수 시 소요 경비 지원 (공식 채용 사이트 인사제도 복리 후생 제도 교육비 지원 항목) — 대상 교육·지원 한도 미기재', 61),

  -- ── 휴가 (time_off) — 정본 휴가제도 ──
  (@comp_id, 'refresh_leave', '정기휴가 (유급 연 5일)', NULL, 'time_off',
   'est', NULL, TRUE, '정기휴가 유급휴가 연 5일 (공식 채용 사이트 인사제도 휴가제도 정기휴가 항목) — 사용 시기·사용 조건 미기재', 70),
  (@comp_id, 'long_service_leave', '안식휴가', NULL, 'time_off',
   'est', NULL, TRUE, '안식휴가 5년근속시 4일, 10년근속시 7일, 15년이상 근속시 매 5년마다 10일 (공식 채용 사이트 인사제도 휴가제도 안식휴가 항목) — 유급 여부·사용 기한 미기재', 71),

  -- ── 근무 유연성 (flexibility) — 공시 ──
  (@comp_id, 'flex_work', '선택근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 활용, 선택근무제 사용자 수 제72기 586명·제71기 528명·제70기 511명, 선택근무제 사용자는 출퇴근 시간 변경 가능 (2026.03 사업보고서 직원 등 현황 유연근무제도 사용현황 항목) — 대상 직무·의무 근로 시간대 미기재', 80),
  (@comp_id, 'remote_work', '원격근무제(재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무 포함) 사용자 수 제72기 199명·제71기 141명·제70기 175명 (2026.03 사업보고서 직원 등 현황 유연근무제도 사용현황 항목) — 대상 직무·사용 조건 미기재', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
