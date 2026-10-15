-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- GST 복리후생 데이터 (신규 회사 — 웨이브 10)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.gst-in.com/m62.php
-- badge: est
--
-- 참고:
--   정본은 상장 법인 (주)글로벌스탠다드테크놀로지(DART 이름 GST)의 자기 도메인 www.gst-in.com Careers > 인사정책 페이지다.
--   SSR 이라 원본 HTML 에 복리후생 3블록(가치를 실현하는 일터 · 활기찬 삶 존중 · 함께하는 생활) 13개 항목 이름이 다 있다.
--   항목은 이름뿐(설명 · 금액 없음). 헤드리스 렌더 · 이미지 판독 불필요. 영문판 /en/m62.php 에는 복리후생 블록이 없다.
--   공시 보조: OpenDART 2026 반기보고서(접수 20260814001221) 직원 등 현황 유연근무제도 사용 현황(시차출퇴근 · 원격근무)과
--   자기주식 처분 계획, 2025 사업보고서(접수 20260318001383) 자기주식 취득 및 처분 현황(임직원 대상 우리사주지급). 직원 824명.
--   귀속: 페이지 주어가 법인(GST) 하나이고 그룹 · 계열사 단서가 없다. 기등록 형제 없음. 각주 없음.
--   금액: 원문에 원 단위 숫자 0건 — 식대 1행만 끼니 식(조식 · 중식 2끼 × 12,000원 × 240일 = 576 추정). 나머지 NULL.
--   제외: 법정(육아휴직 · 임신기 육아기 단축근무 · 배우자출산휴가 사용 현황 표) · 임원 보수 칸(PS/PI · 특별격려금 · 복리후생비) ·
--     선택근무제(세 기간 모두 0명 · 반기 · 사업보고서 둘 다) · 사회공헌 1% 나눔(사내 취약계층 지원 · Matching Grant) ·
--     기타장기종업원급여(회계정책 정의 문장과 부채 계정만 — 근거표 판단 요청) · 특수관계자 거래 절 대여금 문장(없다는 형식 문장).
--   공고 근거 0행 / 전체 19행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(growth 10 · health 20 · perks 30 · leisure 40 · work_env 50 · flexibility 60 ·
--     family 70 · time_off 80), 공시에만 있는 compensation 90.
-- 검증 · 감사 판정 반영(2026-10-15): 행 조치 없음 · 효도 지원금 parent_care · 효도휴가 leave_general 두 행 유지 · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 19행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('gst', 'GST',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체장비', 'G', 'https://www.gst-in.com/m62.php');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'gst');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.gst-in.com/m62.php'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 성장 (growth) — 인사정책 복리후생 가치를 실현하는 일터 ──
  (@comp_id, 'lang', '어학 활동 지원', NULL, 'growth',
   'est', NULL, TRUE, '어학 활동 지원 (공식 홈페이지 인사정책 복리후생 가치를 실현하는 일터 항목) — 지원 방식·금액·대상 미기재', 10),
  -- ── 건강 (health) — 가치를 실현하는 일터 · 함께하는 생활 ──
  (@comp_id, 'fitness', '체육 활동 지원', NULL, 'health',
   'est', NULL, TRUE, '체육 활동 지원 (공식 홈페이지 인사정책 복리후생 가치를 실현하는 일터 항목) — 지원 방식·금액·대상 미기재', 20),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '의료비 지원 (공식 홈페이지 인사정책 복리후생 함께하는 생활 항목) — 지원 대상·한도 미기재', 21),
  (@comp_id, 'clinic', '건강관리실 운영', NULL, 'health',
   'est', NULL, TRUE, '건강관리실 운영 (공식 홈페이지 인사정책 복리후생 함께하는 생활 항목) — 상주 인력·운영 시간 미기재', 22),
  -- ── 생활 · 편의 (perks) — 가치를 실현하는 일터 · 함께하는 생활 ──
  (@comp_id, 'meal', '조식·중식 무료 제공', 576, 'perks',
   'est', '조식·중식 무료 제공 (공식 홈페이지 인사정책 복리후생 가치를 실현하는 일터 항목) — 식대 단가 미기재 (하루 2끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 30),
  (@comp_id, 'snack_bar', '사내 카페 운영', NULL, 'perks',
   'est', NULL, TRUE, '사내 카페 운영 (공식 홈페이지 인사정책 복리후생 가치를 실현하는 일터 항목) — 이용 비용·운영 시간 미기재', 31),
  (@comp_id, 'welfare_fund_loan', '임직원 대출 지원', NULL, 'perks',
   'est', NULL, TRUE, '임직원 대출 지원 (공식 홈페이지 인사정책 복리후생 함께하는 생활 항목) — 대출 용도·한도·이율 미기재', 32),
  -- ── 여가 (leisure) — 가치를 실현하는 일터 · 활기찬 삶 존중 ──
  (@comp_id, 'resort', '연수원·콘도 회원권 이용', NULL, 'leisure',
   'est', NULL, TRUE, '연수원·콘도 회원권 이용 (공식 홈페이지 인사정책 복리후생 가치를 실현하는 일터 항목) — 이용 횟수·본인 부담 미기재', 40),
  (@comp_id, 'club', '동호회', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 (공식 홈페이지 인사정책 복리후생 활기찬 삶 존중 항목) — 지원 금액·동호회 종류 미기재', 41),
  -- ── 근무 환경 (work_env) — 가치를 실현하는 일터 ──
  (@comp_id, 'lounge', '휴게실 운영', NULL, 'work_env',
   'est', NULL, TRUE, '휴게실 운영 (공식 홈페이지 인사정책 복리후생 가치를 실현하는 일터 항목) — 시설 규모·구성 미기재', 50),
  -- ── 근무 유연성 (flexibility) — 활기찬 삶 존중 · 2026 반기보고서 ──
  (@comp_id, 'family_day', '금요일 조기퇴근제 (4시 퇴근)', NULL, 'flexibility',
   'est', NULL, TRUE, '금요일 조기퇴근제(4시 퇴근) (공식 홈페이지 인사정책 복리후생 활기찬 삶 존중 항목) — 시행 주기·대상 미기재', 60),
  (@comp_id, 'flex_work', '시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 활용, 시차출퇴근제 사용자 수 2026년 상반기 19명·2025년 18명·2024년 13명 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 61),
  (@comp_id, 'remote_work', '원격근무제(재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무 포함) 사용자 수 2026년 상반기 3명·2025년 3명·2024년 3명 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 62),
  -- ── 가족 (family) — 활기찬 삶 존중 · 함께하는 생활 ──
  (@comp_id, 'parenting', '자녀 양육·출산 축의금', NULL, 'family',
   'est', NULL, TRUE, '자녀 양육 (공식 홈페이지 인사정책 복리후생 활기찬 삶 존중 항목), 출산 축의금 지급 (같은 페이지 함께하는 생활 항목) — 지원 방식·금액 미기재', 70),
  (@comp_id, 'child_edu', '자녀 학자금', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 (공식 홈페이지 인사정책 복리후생 활기찬 삶 존중 항목) — 지원 학교급·금액 미기재', 71),
  (@comp_id, 'parent_care', '효도 지원금', NULL, 'family',
   'est', NULL, TRUE, '효도 지원금 (공식 홈페이지 인사정책 복리후생 활기찬 삶 존중 항목) — 지급 시기·금액·대상 미기재', 72),
  (@comp_id, 'event', '결혼 축의금', NULL, 'family',
   'est', NULL, TRUE, '결혼 축의금 지급 (공식 홈페이지 인사정책 복리후생 함께하는 생활 항목) — 금액·지급 대상 범위 미기재', 73),
  -- ── 휴가 (time_off) — 활기찬 삶 존중 ──
  (@comp_id, 'leave_general', '효도휴가', NULL, 'time_off',
   'est', NULL, TRUE, '효도휴가 (공식 홈페이지 인사정책 복리후생 활기찬 삶 존중 항목) — 휴가 일수·유급 여부·부여 조건 미기재', 80),
  -- ── 보상 (compensation) — 2025 사업보고서 · 2026 반기보고서 ──
  (@comp_id, 'stock_option', '우리사주조합 무상출연', NULL, 'compensation',
   'est', NULL, TRUE, '자기주식 우리사주조합 무상출연(2025년 12월 이사회 가결), 2026년 1월 5일 지급한 임직원 대상 장기근속유도를 위한 우리사주지급 73,484주 (2025 사업보고서 자기주식 취득 및 처분 현황 항목), 자기주식은 임직원 상여금 지급(우리사주조합 무상출연) 등에 활용할 계획 (2026 반기보고서 자기주식 처분 계획 항목) — 1인당 주식 수·지급 기준 미기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
