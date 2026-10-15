-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 로보스타 복리후생 데이터 (신규 회사 — 웨이브 9)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.robostar.com/kr/careers/welfare
-- badge: est
--
-- 참고:
--   정본은 상장 법인 로보스타(주)의 자기 도메인 www.robostar.com Careers > 복리후생 페이지다.
--   DART 홈 주소 robostar.co.kr 은 같은 서버지만 인증서가 robostar.com 이름뿐이라 robostar.com 을 쓴다.
--   SSR 이라 원본 HTML 에 탭 3개(회사생활 · 가족&건강 · 문화생활) 15항목 텍스트가 다 있다. 렌더 · 이미지 판독 불필요.
--   같은 도메인 영문판(/en/careers/welfare)은 2023-10 판 그대로이고 국문판은 2026-05 에 항목 하나를 바꿨다
--   (아이콘 업로드 시각) — 국문판을 따르고 영문판에만 있는 기념일 지원 · Early Home Day 는 싣지 않았다(근거표 판단 요청).
--   공시 보조: OpenDART 2026 반기보고서(접수 20260814002413) 유연근무제도 사용 현황(선택근무제 사용자 수) ·
--   직원 주택자금 대여 거래. 직원 215명. 지속가능경영 · ESG 보고서 없음.
--   귀속: 페이지 주어가 로보스타는 으로 법인 단수 주어이고 그룹 · 계열사 단서가 없다. 각주 없음.
--   지원하기 메뉴는 LG 그룹 채용 포털로 이어지지만 그 문장은 쓰지 않았다. LG 형제 7사 · 로봇 형제 2사와 문장 겹침 없음.
--   금액: 복지포인트 110만 포인트만 금액 행(1포인트 1원 환산 · 추정). 검진 50만원 · 학자금 500만원은 한도라 NULL.
--   제외: 법정(출산전후휴가 · 육아휴직) · 권장휴가(회사가 더 주는 날 없음) · 영문판에만 있는 항목.
--   공고 근거 0행 / 전체 14행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(time_off 10 · flexibility 20 · work_env 30 · compensation 40 ·
--     family 50 · health 60 · perks 70 · leisure 80).
-- 검증 · 감사 판정 반영(2026-10-15): 행 조치 없음 · 항목 페이지 예외 2(통합 밖 리드 집행) — 최종 14행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('robostar', '로보스타',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '로봇', 'R', 'https://www.robostar.com/kr/careers/welfare');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'robostar');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.robostar.com/kr/careers/welfare'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 휴가 (time_off) — 공식 채용 페이지 복리후생 회사생활 · 문화생활 ──
  (@comp_id, 'long_service_leave', '장기근속자 포상', NULL, 'time_off',
   'est', NULL, TRUE, '근속 5년 단위로 유급휴가 및 여행 상품권 지급 (공식 채용 페이지 복리후생 회사생활 장기근속자 포상 항목) — 휴가 일수·상품권 금액 미기재', 10),
  (@comp_id, 'summer_leave', '하계 휴가 (4일)', NULL, 'time_off',
   'est', NULL, TRUE, '임직원들의 일과 휴식을 양립할 수 있도록 하계 휴가 (4일) 시행 (공식 채용 페이지 복리후생 문화생활 다양한 휴가제도 항목) — 연차 사용일인지·유급 여부 미기재', 11),
  (@comp_id, 'refresh_leave', '안식휴가', NULL, 'time_off',
   'est', NULL, TRUE, '안식휴가 시행 (공식 채용 페이지 복리후생 문화생활 다양한 휴가제도 항목) — 휴가 일수·부여 조건 미기재', 12),

  -- ── 근무 유연성 (flexibility) — 공식 채용 페이지 복리후생 회사생활 · 문화생활 + 반기보고서 ──
  (@comp_id, 'flex_work', '선택 근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '사전 협의를 통해 허용 범위 내에서 자유롭게 출퇴근 시간 조정 (공식 채용 페이지 복리후생 회사생활 선택 근무제 항목), 자유롭게 출퇴근할 수 있는 선택근무제 시행 (같은 페이지 문화생활 Work & Life Balance 지원 항목), 선택근무제 사용자 수 153명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 정산 기간·의무 근무시간대 미기재', 20),

  -- ── 근무 환경 (work_env) — 공식 채용 페이지 복리후생 회사생활 ──
  (@comp_id, 'dormitory', '기숙사 운영', NULL, 'work_env',
   'est', NULL, TRUE, '임직원의 안정된 생활을 위해 기숙사 운영 (공식 채용 페이지 복리후생 회사생활 기숙사 운영 항목) — 입주 대상·위치·비용 미기재', 30),

  -- ── 보상 (compensation) — 공식 채용 페이지 복리후생 회사생활 ──
  (@comp_id, 'profit_sharing', '경영성과급', NULL, 'compensation',
   'est', NULL, TRUE, '회사의 경영실적에 따라 성과급을 차등적으로 지급 (공식 채용 페이지 복리후생 회사생활 경영성과급 항목) — 지급 기준·지급률 미기재', 40),
  (@comp_id, 'incentive', '인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '임직원의 업무 동기부여를 위해 비타민제도, 정기인센티브, Retention Incentive 등 다양한 인센티브 제도 운영 (공식 채용 페이지 복리후생 회사생활 인센티브 항목) — 제도별 지급 기준·금액 미기재', 41),

  -- ── 가족 (family) — 공식 채용 페이지 복리후생 가족&건강 ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '사망, 회갑, 결혼 등 집안 내 경조사 발생 시 축하금/위로금 및 휴가 지원, 경조서비스와 조화 지원 (공식 채용 페이지 복리후생 가족&건강 경조사 지원 항목) — 경조금 금액·휴가 일수 미기재', 50),
  (@comp_id, 'child_edu', '자녀 학자금 지급', NULL, 'family',
   'est', NULL, TRUE, '대학생 자녀들을 위해 학자금 지원, 근속 1년 이상의 임직원 대상 학기 당 최대 500만원 (공식 채용 페이지 복리후생 가족&건강 자녀 학자금 지급 항목) — 지원 자녀 수·학기 수 미기재', 51),
  (@comp_id, 'parenting', '자녀 노트북 지급', NULL, 'family',
   'est', NULL, TRUE, '임직원 자녀의 쾌적한 교육을 위해 초/중/고등학교 입학 시 LG gram 노트북 지급, 근속 1년 이상의 임직원 대상 자녀 1인당 1회 (공식 채용 페이지 복리후생 가족&건강 자녀 노트북 지급 항목) — 노트북 사양·가액 미기재', 52),

  -- ── 건강 (health) — 공식 채용 페이지 복리후생 가족&건강 ──
  (@comp_id, 'health_check', '부부 건강검진 지원', NULL, 'health',
   'est', NULL, TRUE, '만 40세 이상 임직원과 배우자를 대상으로 격년에 한번 건강검진비 지원, 근속 1년 이상의 임직원 대상 인당 최대 50만원 (공식 채용 페이지 복리후생 가족&건강 부부 건강검진 지원 항목) — 검진 기관·항목 미기재', 60),

  -- ── 생활 · 금융 (perks) — 공식 채용 페이지 복리후생 가족&건강 · 문화생활 ──
  (@comp_id, 'housing_loan', '주택자금대출 · 결혼 주택 자금 제도', NULL, 'perks',
   'est', NULL, TRUE, '퇴직금 적립 1천만원 이상 인원에 한하여 대출금 최대 1천만원 지원 (공식 채용 페이지 복리후생 가족&건강 주택자금대출 제도 항목), 결혼한 임직원이 주택 임차/매매 시 본인 연소득 범위 내에서 대출금 지원, 근속 1년 이상의 임직원 대상 (같은 페이지 결혼 주택 자금 제도 항목) — 이율·상환 조건 미기재', 70),
  (@comp_id, 'welfare_point', '선택적 복리후생', 110, 'perks',
   'est', '전 임직원에게 LG 복지포인트 110만 포인트 지급 (공식 채용 페이지 복리후생 문화생활 선택적 복리후생 항목) — 지급 주기 미기재, 1포인트 1원 기준 환산', FALSE, NULL, 71),

  -- ── 여가 (leisure) — 공식 채용 페이지 복리후생 문화생활 ──
  (@comp_id, 'resort', '휴양시설 지원', NULL, 'leisure',
   'est', NULL, TRUE, '임직원의 휴양을 위해 한화/대명 리조트의 회원권 운영 (공식 채용 페이지 복리후생 문화생활 휴양시설 지원 항목) — 이용 일수·비용 미기재', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
