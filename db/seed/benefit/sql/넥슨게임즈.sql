-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 넥슨게임즈 복리후생 데이터 (신규 회사 — 웨이브 9)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.nexongames.co.kr/adopt/hire.php
-- badge: est
--
-- 참고:
--   정본 = 자기 도메인 인재채용 복지 페이지(SSR · 원본 HTML 에 항목 22개 · 렌더 없음 · HTML 주석 속 옛 블록은 쓰지 않음).
--   보조 = 자기 도메인 보도자료 2025-12-08 가족친화인증(출산 지원금 · 초등학교 입학 선물) ·
--          OpenDART 2026 반기보고서(접수 20260813001154) — 유연근무제도 사용 현황 표 · 별도 재무제표 주석 장기종업원급여.
--   귀속 = 법인 자기 도메인 · 자기 공시뿐 · 각주 없음(넥슨 공용 채용 사이트 문장은 쓰지 않음 · 코퍼스에 넥슨 계열 형제 없음).
--   금액 = 금액 행 1(식대 288 추정 — 중식 1끼 × 12,000원 × 240일, 야근 석식비 제외). 사내대출 5,000만원은 원금 한도 ·
--          리프레시 휴가 지원금 500만원은 근속 3년 단위 1회성이라 NULL.
--   제외 = 법정(출산전후 휴가 일수 · 육아휴직 법정 1년 · 난임치료 휴가 · 육아기 근로시간 단축 · 가족돌봄휴직 자체) ·
--          3자 뉴스 게시판 기사 · 피플 게시판 인터뷰 · 노사협의회 건의 안건 · 대표이사 스톡그랜트 · 임원 보수 칸.
--   공고 근거 0행 / 전체 20행 · SORT 섹션 순서 = flexibility · perks · compensation · health · time_off · leisure ·
--          work_env · growth · family(정본 순).
-- 검증 · 감사 판정 반영(2026-10-15): 재무제표 주석 근속 행 이름을 장기근속 급부로 · 가족 돌봄 행은 지원금 몫만 · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 20행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('nexon_games', '넥슨게임즈',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '게임', 'N', 'https://www.nexongames.co.kr/adopt/hire.php');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'nexon_games');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.nexongames.co.kr/adopt/hire.php'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — 공식 채용 페이지 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '선택적 근로시간제도', NULL, 'flexibility',
   'est', NULL, TRUE, '월 근로시간만 채우면 자율적으로 근로시간을 조정하여 근무할 수 있는 선택적 근로시간제도 (공식 채용 페이지 복지 선택적 근로시간제도 항목), 선택근무제 사용자 1,677명 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 의무 근로시간대 미기재', 10),
  (@comp_id, 'remote_work', '원격근무제 (재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 활용, 원격근무제(재택근무 포함) 사용자 11명 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목, 2026년 6월말 기준) — 대상 직무·사용 조건 미기재', 11),
  -- ── 생활 · 금융 (perks) — 공식 채용 페이지 ──
  (@comp_id, 'housing_loan', '사내대출 (주택마련·결혼·학자금 대출 상환)', NULL, 'perks',
   'est', NULL, TRUE, '주택마련, 결혼, 학자금 대출 상환 등 목돈마련이 필요한 시기에 맞추어 5,000만원까지 생활안정을 위한 대출 지원 (공식 채용 페이지 복지 사내대출 항목) — 이율·상환 조건 미기재', 20),
  (@comp_id, 'welfare_point', '복지포인트 (분기별 지급)', NULL, 'perks',
   'est', NULL, TRUE, '자기계발, 취미생활, 여가활동 등 모든 곳에 자유롭게 사용할 수 있는 현금성 복지 포인트 분기별 지급 (공식 채용 페이지 복지 복지포인트 항목) — 포인트 금액 미기재', 21),
  (@comp_id, 'meal', '중식 및 야근석식비 지원', 288, 'perks',
   'est', '중식 기본 지원, 야근 시 석식비 지원 (공식 채용 페이지 복지 중식 및 야근석식비 지원 항목) — 1끼 단가 미기재 (하루 1끼 × 1끼 12,000원 × 연 240일 추정, 야근 석식비 제외)', FALSE, NULL, 22),
  -- ── 보상 (compensation) — 공식 채용 페이지 · 2026 반기보고서 ──
  (@comp_id, 'holiday_gift', '명절선물 (명절포인트)', NULL, 'compensation',
   'est', NULL, TRUE, '설과 추석에 선물을 구매할 수 있는 명절포인트 제공 (공식 채용 페이지 복지 명절선물 항목) — 포인트 금액 미기재', 30),
  (@comp_id, 'long_service_bonus', '장기근속 급부', NULL, 'compensation',
   'est', NULL, TRUE, '장기 근속 임직원에게 장기종업원급여 제공, 일정 기간 이상 장기간 근무한 임직원 대상 (2026 반기보고서 재무제표 주석 종업원급여 항목) — 근속 기준·급부 형태·금액 미기재', 31),
  -- ── 건강 (health) — 공식 채용 페이지 ──
  (@comp_id, 'health_check', '종합건강검진 (건강검진 휴가 포함)', NULL, 'health',
   'est', NULL, TRUE, '매년 건강검진 휴가와 종합건강검진 제공 (공식 채용 페이지 복지 종합건강검진 항목) — 검진 항목·비용 지원 범위·휴가 일수 미기재', 40),
  (@comp_id, 'insurance', '단체 상해보험 (가족 포함)', NULL, 'health',
   'est', NULL, TRUE, '본인과 배우자, 자녀, 양가 부모님, 형제 등 가족들의 단체상해보험 지원, 만일의 사고와 질병 보장 (공식 채용 페이지 복지 단체 상해보험 항목) — 보장 범위·보험료 부담 미기재', 41),
  (@comp_id, 'mental', '내마음 읽기 (심리 프로그램)', NULL, 'health',
   'est', NULL, TRUE, '구성원의 건강한 마음을 위해 심리 전문가를 통해 마음의 상태를 진단하고 스트레스를 케어할 수 있는 프로그램 지원 (공식 채용 페이지 복지 내마음 읽기 항목) — 이용 횟수·비용 지원 범위 미기재', 42),
  -- ── 휴가 (time_off) — 공식 채용 페이지 ──
  (@comp_id, 'long_service_leave', '리프레시 휴가 (근속 3년 단위)', NULL, 'time_off',
   'est', NULL, TRUE, '근속 3년 단위로 재충전을 위한 휴가 15일과 휴가 지원금 500만원 지원 (공식 채용 페이지 복지 리프레시 휴가 항목) — 휴가 유급 여부 미기재', 50),
  -- ── 여가 (leisure) — 공식 채용 페이지 ──
  (@comp_id, 'resort', '콘도·리조트 지원', NULL, 'leisure',
   'est', NULL, TRUE, '가족, 지인들과 함께 이용할 수 있도록 전국 각지의 콘도와 리조트 지원 (공식 채용 페이지 복지 콘도 항목) — 이용 횟수·비용 지원 범위 미기재', 60),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '다양한 취미활동을 장려하며 지원금 제공 (공식 채용 페이지 복지 사내 동호회 항목) — 지원금 금액 미기재', 61),
  (@comp_id, 'leisure_ticket', '넥슨캐시 지원', NULL, 'leisure',
   'est', NULL, TRUE, '넥슨게임을 자유롭게 플레이하도록 넥슨캐시 지원 (공식 채용 페이지 복지 넥슨캐시 항목) — 지원 금액·지급 주기 미기재', 62),
  -- ── 근무 환경 (work_env) — 공식 채용 페이지 ──
  (@comp_id, 'lounge', '휴게실 (안마의자)', NULL, 'work_env',
   'est', NULL, TRUE, '업무 중 자유롭게 휴식할 수 있도록 안마의자와 휴게실 마련 (공식 채용 페이지 복지 휴게실 항목) — 위치·규모 미기재', 70),
  -- ── 성장 (growth) — 공식 채용 페이지 ──
  (@comp_id, 'edu_support', '사내 스터디 · 사내외 교육', NULL, 'growth',
   'est', NULL, TRUE, '공통/직무/어학 등 사내 구성원 간 자율적인 학습 독려 및 활동비 지원 (공식 채용 페이지 복지 사내 스터디 항목), 업무 스킬을 향상할 수 있는 사내외 교육 지원 (공식 채용 페이지 복지 사내외 교육 항목) — 활동비 금액·교육비 지원 범위 미기재', 80),
  -- ── 가족 (family) — 공식 채용 페이지 · 2025 보도자료 ──
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '만 1세반부터 만 5세반까지 보육 환경을 제공하는 사내 어린이집 운영 (공식 채용 페이지 복지 사내 어린이집 항목) — 정원·이용 조건 미기재', 90),
  (@comp_id, 'parenting', 'Happy Mom · 육아휴직 최대 2년 · 출산 지원', NULL, 'family',
   'est', NULL, TRUE, 'Happy Mom 임신한 직원들의 안전하고 건강한 회사생활과 원활한 출산·복귀 지원, 육아휴직 최대 2년(법정 1년에 1년 추가), 출산전후 휴가 기간 급여 100% 지급 (공식 채용 페이지 복지 Happy Mom · 육아휴직 최대2년 · 출산전후 휴가 급여지급 항목), 출산 지원금 · 초등학교 입학 선물 (2025년 12월 공식 보도자료 항목) — 출산 지원금 금액·입학 선물 내용 미기재', 91),
  (@comp_id, 'event', '가족 경조사 지원 · 상조 지원', NULL, 'family',
   'est', NULL, TRUE, '본인과 가족들의 결혼, 사망, 출산 등 경조사 발생 시 휴가와 경조화환, 물품, 경조금 지원 (공식 채용 페이지 복지 가족 경조사 지원 항목), 본인과 가족들의 중대조사 발생 시 장례지도사 및 인력/물품 지원 (공식 채용 페이지 복지 상조 지원 항목) — 경조 휴가 일수·경조금 금액 미기재', 92),
  (@comp_id, 'parent_care', '가족 돌봄휴직 지원금', NULL, 'family',
   'est', NULL, TRUE, '가족 중 중대 질환으로 통원치료 및 간호가 필요할 경우 가족돌봄휴직 지원금 지원 (공식 채용 페이지 복지 가족 돌봄휴직 항목) — 지원금 금액·지급 기간 미기재', 93)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
