-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SK에너지 복리후생 데이터 (신규 회사 — 웨이브 15)
-- 출처: AI 파싱 (2026-10-23)
-- URL: https://www.skenergy.com/career/hr_comp?lng=ko
-- badge: est
--
-- 참고:
--   정본 = SK에너지㈜(DART SK에너지 주식회사 · 비상장 · 최대주주 SK이노베이션 100%) 자기 도메인 www.skenergy.com 의
--     Career > 인사제도 > 평가/보상 페이지(/career/hr_comp, SSR HTML, 보상 절 + 복리후생 6묶음).
--     꼬리말 법인 = SK에너지㈜ 서울특별시 종로구 종로 26 SK빌딩 · 사업자등록번호 101-86-60120. robots = Allow 전체.
--     파라미터 없이 받으면 영문판이 오고 lng=ko 로 국문판이 온다(국문 · 영문 항목 같음) — 국문판을 정본으로 했다.
--   보조 = 같은 도메인 /career/hr_dev(인재육성 — 구성원 Mental Care · Physical Care) ·
--     OpenDART 2025 사업보고서(20260316001108) · 2026 반기보고서(20260814002797) 유연근무제도 사용 현황 표.
--   귀속: 법인 자기 도메인 페이지라 각주 없음. 모회사 SK이노베이션 · 형제 SK온 평가/보상 페이지와 같은 틀이고
--     문장이 거의 같지만 자기 도메인 원문이라 이 법인 출처로 썼다. 금전적 지원 칸은 형제와 다르다
--     (SK에너지 = 퇴직연금 지원 / SK이노베이션 = 행복연금 · SK온 = 개인연금 지원).
--     esg/report 의 보고서는 SK이노베이션 계열 통합 발행본(모회사 발행)이라 쓰지 않았다.
--     그룹 채용 사이트 recruit.skinnovation.com 의 SK에너지 페이지는 403 이라 쓰지 않았다.
--   금액: stated 0 · 추정 1(meal 576 = 하루 2끼 × 1끼 12,000원 × 연 240일). 나머지 금액 NULL(원문 숫자 없음).
--   제외: 법정(출산/육아 휴직 · 퇴직연금 지원) · SK패밀리 카드(혜택이 적히지 않은 그룹 카드 이름) ·
--     임원 보수 칸 선택적 복리후생 · 성과급 · PSU(임원 전용) · 이사회 안건 제목 사내근로복지기금 출연 ·
--     원격근무제 공시 사용자 전 기간 없음 · 리더십 · 공통역량 · 연수 프로그램 등 육성 문구(업무 교육).
--   공고 근거 0행 / 전체 17행.
--   SORT 섹션 순서 = 정본 복리후생 6묶음에서 카테고리가 처음 나온 순서(perks 10 · health 20 · work_env 30 ·
--     family 40 · leisure 50 · compensation 60), 보조 출처에만 있는 카테고리(flexibility 70).
-- 검증 · 감사 판정 반영(2026-10-23): 행 조치 없음 · 자기 도메인 평가 보상 페이지라 SK이노베이션 · SK온 같은 틀이어도 각주 없음 · 퇴직연금 지원과 연수 프로그램 등은 싣지 않음 · 참고 블록 형제 대조 줄의 SK이노베이션 행복연금 표기는 지금 그 페이지 금전적 지원 칸(SK행복카드 · 퇴직연금 지원 · 생활 안정자금 대부)과 다름 — 최종 17행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('sk_energy', 'SK에너지',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '정유/화학', 'S', 'https://www.skenergy.com/career/hr_comp?lng=ko');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'sk_energy');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.skenergy.com/career/hr_comp?lng=ko'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) — 정본 금전적 지원 · 주거 지원 · 기타 ──
  (@comp_id, 'welfare_point', 'SK행복카드', NULL, 'perks',
   'est', NULL, TRUE, 'SK행복카드 (공식 인사제도 평가/보상 페이지 복리후생 금전적 지원 항목) — 카드 용도·연간 지급액 미기재', 10),
  (@comp_id, 'welfare_fund_loan', '생활안정자금 대부', NULL, 'perks',
   'est', NULL, TRUE, '생활 안정자금 대부 (공식 인사제도 평가/보상 페이지 복리후생 금전적 지원 항목) — 대부 한도·이율·신청 요건 미기재', 11),
  (@comp_id, 'housing_loan', '주택 구입·전세 융자', NULL, 'perks',
   'est', NULL, TRUE, '주택 구입 및 전세 융자 (공식 인사제도 평가/보상 페이지 복리후생 주거 지원 항목) — 융자 한도·이율 미기재', 12),
  (@comp_id, 'housing_support', '지방 근무 시 주거비 지원', NULL, 'perks',
   'est', NULL, TRUE, '지방 근무 시 기숙사 또는 주거비 지원 중 주거비 지원 (공식 인사제도 평가/보상 페이지 복리후생 주거 지원 항목) — 지원 금액·지급 방식 미기재', 13),
  (@comp_id, 'meal', '중식·석식 제공', 576, 'perks',
   'est', '중/석식 제공 (공식 인사제도 평가/보상 페이지 복리후생 기타 항목) — 식대 단가·본인 부담 미기재 (하루 2끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 14),

  -- ── 건강·의료 (health) — 정본 건강 관리 · 취미/레저활동 · 기타 · 인재육성 페이지 ──
  (@comp_id, 'health_check', '정기 건강검진', NULL, 'health',
   'est', NULL, TRUE, '정기 건강검진 (공식 인사제도 평가/보상 페이지 복리후생 건강 관리 항목) — 검진 주기·검진 항목·비용 지원 범위 미기재', 20),
  (@comp_id, 'medical', '의료비 지원 (배우자·자녀 포함)', NULL, 'health',
   'est', NULL, TRUE, '의료비 지원, 배우자·자녀 포함 (공식 인사제도 평가/보상 페이지 복리후생 건강 관리 항목) — 지원 한도·지원 범위 미기재', 21),
  (@comp_id, 'fitness', '피트니스 센터', NULL, 'health',
   'est', NULL, TRUE, 'Fitness Center (공식 인사제도 평가/보상 페이지 복리후생 취미/레저활동 항목), 사내 헬스 트레이닝 지원 등 구성원 Physical Care (공식 인사제도 인재육성 페이지 역량 발휘 환경 지원 항목) — 운영 사업장·이용료 미기재', 22),
  (@comp_id, 'mental', '하모니아 상담/코칭', NULL, 'health',
   'est', NULL, TRUE, '하모니아 상담/코칭 (공식 인사제도 평가/보상 페이지 복리후생 기타 항목), 구성원 심리 상담·Newcomer Counseling 등 구성원 Mental Care (공식 인사제도 인재육성 페이지 역량 발휘 환경 지원 항목) — 이용 횟수·비용 부담 미기재', 23),

  -- ── 근무환경 (work_env) — 정본 주거 지원 ──
  (@comp_id, 'dormitory', '지방 근무 시 기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '지방 근무 시 기숙사 또는 주거비 지원 중 기숙사 (공식 인사제도 평가/보상 페이지 복리후생 주거 지원 항목) — 입주 자격·운영 사업장 미기재', 30),

  -- ── 가족·돌봄 (family) — 정본 가정 및 육아 지원 ──
  (@comp_id, 'event', '경조금·경조휴가', NULL, 'family',
   'est', NULL, TRUE, '경조 휴가 및 경조금 (공식 인사제도 평가/보상 페이지 복리후생 가정 및 육아 지원 항목) — 경조 사유별 지급액·휴가 일수 미기재', 40),
  (@comp_id, 'childcare', '어린이집', NULL, 'family',
   'est', NULL, TRUE, '어린이집 (공식 인사제도 평가/보상 페이지 복리후생 가정 및 육아 지원 항목) — 설치 사업장·정원·운영 방식 미기재', 41),
  (@comp_id, 'child_edu', '자녀 학자금', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 (공식 인사제도 평가/보상 페이지 복리후생 가정 및 육아 지원 항목) — 대상 학교급·지원 한도 미기재', 42),

  -- ── 여가·라이프 (leisure) — 정본 취미/레저활동 ──
  (@comp_id, 'resort', '휴양소·콘도', NULL, 'leisure',
   'est', NULL, TRUE, '휴양소 · 콘도 (공식 인사제도 평가/보상 페이지 복리후생 취미/레저활동 항목) — 이용 방식·지원 금액 미기재', 50),
  (@comp_id, 'club', '사내 동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 활동 지원 (공식 인사제도 평가/보상 페이지 복리후생 취미/레저활동 항목) — 지원 금액·동호회 종류 미기재', 51),

  -- ── 보상·금전 (compensation) — 정본 기타 ──
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 포상 (공식 인사제도 평가/보상 페이지 복리후생 기타 항목) — 근속 기준·포상 내용 미기재', 60),

  -- ── 근무유연성 (flexibility) — 2026 반기보고서 · 2025 사업보고서 유연근무제도 사용 현황 표 ──
  (@comp_id, 'flex_work', '시차출퇴근제·선택근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '시차출퇴근제 사용자 2026년 상반기 582명·2025년 635명·2024년 684명·2023년 691명, 선택근무제 사용자 2026년 상반기 922명·2025년 937명·2024년 983명·2023년 1,033명 (2026 반기보고서 · 2025 사업보고서 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 70)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
