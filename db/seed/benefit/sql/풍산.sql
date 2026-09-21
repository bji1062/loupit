-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 풍산 복리후생 데이터
-- 출처: AI 파싱 (2026-09-19)
-- URL: https://www.poongsan.co.kr/recruit/welfare
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
--
-- 참고:
--   정본은 상장 법인 (주)풍산의 자기 도메인 www.poongsan.co.kr 채용정보 > 복지제도 페이지다.
--   페이지 리드 문장 주어가 「풍산은 … 다양한 복지제도를 운영하고 있습니다」로 법인 단수라
--   귀속이 확정된다. 그룹 통합 채용사이트·외부 ATS 는 전 페이지 링크에 없다(각주 불필요).
--   SSR(Apache+PHP) 이라 15항목이 최초 HTML 의 section.welfare 안 table 텍스트로 들어 있다.
--   헤드리스 렌더·이미지 판독 불필요. apex 와 http 대신 https://www. 로 고정한다.
--
--   출처 2개를 행마다 분리해 적었다.
--     (a) 웹 정본 /recruit/welfare — 회사생활 6 · 가족·건강 5 · 여가 4 = 15항목
--     (b) 같은 도메인이 호스팅하는 법인 단독 발행 2025 지속가능경영보고서 PDF
--         66쪽 복리후생 제도 표 9행 + 65쪽 모성보호제도 + 67쪽 임직원 교육.
--         보고 기간이 2025-01-01~2025-12-31 이라 이 출처의 행은 2025년 기준 시점을 남겼다.
--     (c) 학위 파견형 1행은 웹 /recruit/talent 인재육성 Expert 항목이 원문이다.
--   웹에만 있는 것: 출퇴근 버스·사내식당·하계휴양비·휴양시설·자녀 학자금 등.
--   보고서에만 있는 것: 유연근무 3종·단체보험 4종·본인/배우자 종합건강검진·통신비·
--     복지기금 대출·입학축하금·퇴직자 재취업(만 50세 이상)·임신 축하 선물·수유실,
--     그리고 유일한 수치인 사택 1,109세대·동아리 약 50개.
--
--   ⚠ 금액 명시 0건 — 24행 전부 BENEFIT_AMT NULL 이다. 보고서에서 원 단위 금액이 나오는
--     유일한 대목인 62~63쪽 「약 100억 원 규모의 지원」은 동반성장 협약에 따른 **협력사**
--     대상이라 임직원 복지가 아니다. 끌어오면 허위다. 신규 회사라 승계할 앵커도 없고
--     타사 금액을 끌어오지 않았다.
--
--   원문 표현을 그대로 쓰면 뜻이 서지 않는 2곳을 설명문 쪽으로 살렸다.
--     ① 여가 「하계휴양비(체력단련비) 지급」은 설명이 항목명을 그대로 되풀이한다
--        → 항목명은 하계휴양비(체력단련비), 서술은 전 직원 지급 조건으로 풀었다.
--     ② 회사생활 「자금 지원」은 실체가 사내 근로복지기금이고 보고서 기타 지원 항목이
--        복지기금 대출로 특정한다 → welfare_fund_loan, 항목명 사내 근로복지기금 대출.
--   분리 2건: 휴가제도(하기휴가+자기계발휴가) → summer_leave + refresh_leave.
--   병합 2건: 수유실 → childcare · 장기근속 표창(보고서) → long_service_bonus.
--   신규 코드 0개. 24행 전부 기존 87종 안에서 해결했다.
--
--   제외: 협력사 교육·복리후생 지원과 채용 격려금(협력사 대상) · 66쪽 조직문화 프로그램 6종
--     (타운홀·조직문화 진단·크로스 런치·칭찬 앱·문화의 날·업무 효율화 프로젝트 — 소통·협업
--     프로그램이라 제도로 보지 않았다) · 67쪽 교육 체계표의 사내 어학·독서통신·계층교육
--     (회사 주도 커리큘럼) · 인재상·다양성·양성평등 보상 서술 · 지주 풍산홀딩스와 관계사
--     6곳 자산 전부.
--   SORT 섹션 순서는 정본 페이지에서 그 카테고리가 처음 나온 순서를 따랐다
--     (perks 10 · compensation 20 · leisure 30 · family 40 · work_env 50 ·
--      time_off 60 · flexibility 70 · health 80 · growth 90).
--       ⚠ 검증·감사 판정 반영(2026-09-19): 24행 그대로(병합 2 · 추가 2). SORT 30 공로여행을 SORT 91
--       retirement_support 에 병합 · SORT 43 임신 축하 선물을 SORT 42 parenting 에 병합하며 모성보호제도
--       구절 삭제 · SORT 61 refresh_leave → leave_general 재코딩 · SORT 34 culture_day · SORT 82 mental 추가.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ⚠ 데이터 정리 2차(2026-09-21): SORT 13·14·60·61·70·71·80·81·91 문안 교체. db/migrations/20260921_data_cleanup_2.sql 동봉.
-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('poongsan', '풍산',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '비철금속', 'P', 'https://www.poongsan.co.kr/recruit/welfare');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'poongsan');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.poongsan.co.kr/recruit/welfare'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'commute_subsidy', '출퇴근 버스', NULL, 'perks',
   'est', NULL, TRUE, '임직원 통근 편의를 위해 사업장별 특성과 교통편을 고려한 통근버스 운행 (공식 채용정보 복지제도 페이지 회사생활 항목) — 노선·운행 사업장·이용료 미기재', 10),
  (@comp_id, 'meal', '사내식당', NULL, 'perks',
   'est', NULL, TRUE, '임직원 영양을 고려한 건강 식단을 제공하는 사내식당 운영 (공식 채용정보 복지제도 페이지 회사생활 항목) — 제공 끼니·식대 단가·본인 부담 미기재', 11),
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '매년 지급되는 복지포인트를 개인 취향에 따라 사용 (공식 채용정보 복지제도 페이지 회사생활 항목). 2025 지속가능경영보고서 66쪽 복리후생 제도 표에도 복지포인트 지급 기재 — 연간 포인트 금액 미기재', 12),
  (@comp_id, 'welfare_fund_loan', '사내 근로복지기금 대출', NULL, 'perks',
   'est', NULL, TRUE, '사내 근로복지기금 대출 (공식 채용정보 복지제도 페이지 회사생활 항목은 「자금 지원」으로, 2025 지속가능경영보고서 66쪽 기타 지원 항목은 「복지기금 대출」로 기재 — 대출 한도·이율·대상 미기재)', 13),
  (@comp_id, 'telecom', '통신비 지원', NULL, 'perks',
   'est', NULL, TRUE, '통신비 지원 (2025 지속가능경영보고서 66쪽 복리후생 제도 표 기타 지원 항목, 2025년 기준 — 지원 금액·대상 직군 미기재)', 14),

  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '10년 이상 장기근속자에게 근속 포상과 배우자 동반 해외 여행 제공 (공식 채용정보 복지제도 페이지 회사생활 항목). 2025 지속가능경영보고서 66쪽 기타 지원 항목에도 장기근속 표창 기재 — 포상 금액·여행 지원 한도 미기재', 20),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'summer_vacation_subsidy', '하계휴양비(체력단련비)', NULL, 'leisure',
   'est', NULL, TRUE, '전 직원에게 하계휴양비 지급. 공식 채용정보 복지제도 페이지 여가 항목명은 하계휴양비(체력단련비) 지급 — 지급액·지급 시기 미기재', 31),
  (@comp_id, 'resort', '휴양시설', NULL, 'leisure',
   'est', NULL, TRUE, '전국에 위치한 콘도를 회원가로 이용하고 7~8월에는 각 사업장별 별도의 휴양소를 설치·운영 (공식 채용정보 복지제도 페이지 여가 항목) — 제휴 콘도·회원가 수준·이용 한도 미기재', 32),
  (@comp_id, 'club', '동호회 활동', NULL, 'leisure',
   'est', NULL, TRUE, '수십여개의 다양한 동호회를 운영하고 동호회 지원금과 행사대관비 지원 (공식 채용정보 복지제도 페이지 여가 항목). 2025 지속가능경영보고서 66쪽 기준 전사 약 50개 동아리 활동 지원 — 동호회당 지원금 미기재', 33),
  (@comp_id, 'culture_day', '문화의 날', NULL, 'leisure',
   'est', NULL, TRUE, '반기마다 문화의 날을 운영해 다양한 문화활동 지원 (2025 지속가능경영보고서 66쪽 조직문화 프로그램, 2025년 기준) — 활동 내용·지원 방식 미기재', 34),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '경조금 지원', NULL, 'family',
   'est', NULL, TRUE, '임직원 본인 및 가족의 경조사 발생 시 축하금·위로금 및 경조 물품 지원 (공식 채용정보 복지제도 페이지 가족·건강 항목). 2025 지속가능경영보고서 66쪽 휴가 제도 항목에 경조휴가 기재 — 경조 구분별 금액·휴가 일수 미기재', 40),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '임직원 취학 자녀의 고교·대학교 학자금 지원 (공식 채용정보 복지제도 페이지 가족·건강 항목) — 지원 한도·자녀 수 제한·금액 미기재', 41),
  (@comp_id, 'parenting', '출산·양육 지원', NULL, 'family',
   'est', NULL, TRUE, '임직원 자녀 출산 시 장려금 지급 (공식 채용정보 복지제도 페이지 가족·건강 항목). 2025 지속가능경영보고서 65~66쪽 기준 출산 축하금과 자녀 입학축하금 지급, 복직자 적응을 돕는 맘토링·웰컴 프로그램 운영, 2025 지속가능경영보고서 65쪽 기준 임신 축하 선물과 임산부의 날 도시락 제공 (2025년 기준) — 지급액·선물 구성·금액 미기재', 42),
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '일가정 양립을 위해 울산·안강 사업장 사택 내 어린이집 운영 (공식 채용정보 복지제도 페이지 가족·건강 항목). 2025 지속가능경영보고서 65~66쪽 기준 사내 수유실도 함께 운영 — 정원·대상 연령·보육료 부담 미기재', 44),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '주거안정 지원', NULL, 'work_env',
   'est', NULL, TRUE, '사원아파트 및 독신자 숙소 제공 (공식 채용정보 복지제도 페이지 가족·건강 항목). 2025 지속가능경영보고서 66쪽 기준 전사 1,109세대 사택 제공 — 입주 자격·본인 부담 미기재', 50),

  -- ── 휴가 (time_off) ──
  (@comp_id, 'summer_leave', '하기휴가', NULL, 'time_off',
   'est', NULL, TRUE, '하기휴가 (공식 채용정보 복지제도 페이지 여가 항목 휴가제도 · 2025 지속가능경영보고서 66쪽 휴가 제도 항목에도 하계휴가 기재 — 휴가 일수·사용 시기 미기재)', 60),
  (@comp_id, 'leave_general', '자기계발휴가', NULL, 'time_off',
   'est', NULL, TRUE, '자기계발휴가 (공식 채용정보 복지제도 페이지 여가 항목 휴가제도 · 2025 지속가능경영보고서 66쪽 휴가 제도 항목에도 자기계발 휴가 기재 — 부여 일수·사용 조건 미기재)', 61),

  -- ── 유연근무 (flexibility) ──
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '시차출퇴근제와 선택적근로시간제 운영 (2025 지속가능경영보고서 66쪽 복리후생 제도 표 유연근무제 운영 항목, 2025년 기준 — 신청 대상·운영 단위 미기재)', 70),
  (@comp_id, 'remote_work', '재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '재택근무 운영 (2025 지속가능경영보고서 66쪽 유연근무제 운영 항목, 2025년 기준 — 가능 일수·대상 직무 미기재)', 71),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합건강검진 (본인·배우자)', NULL, 'health',
   'est', NULL, TRUE, '본인·배우자 종합건강검진 지원 (2025 지속가능경영보고서 66쪽 건강관리 지원 항목, 2025년 기준 — 검진 주기·검진 비용 미기재)', 80),
  (@comp_id, 'insurance', '단체보험', NULL, 'health',
   'est', NULL, TRUE, '전 임직원 대상 상해장애·상해사망·산재사망·질병사망 보험금 지급 (2025 지속가능경영보고서 66쪽 건강관리 지원 항목, 2025년 기준 — 보장 한도·보험료 부담 미기재)', 81),
  (@comp_id, 'mental', '심리상담 지원 프로그램(EAP)', NULL, 'health',
   'est', NULL, TRUE, '임직원의 심리적 부담 완화를 위한 전문가 상담 및 코칭 프로그램 운영 (2025 지속가능경영보고서 50쪽 임직원 건강증진 프로그램, 2025년 기준) — 상담 횟수·비용 부담 미기재', 82),

  -- ── 성장·교육 (growth) ──
  (@comp_id, 'mba', 'MBA·석박사 과정 지원', NULL, 'growth',
   'est', NULL, TRUE, '미래 경영후보군 양성을 위한 국내·외 MBA 연수 지원과 핵심 기술분야 전문 인력 양성을 위한 석·박사 과정 지원 (공식 채용정보 인재육성 페이지 Expert 항목). 2025 지속가능경영보고서 67쪽에도 MBA 및 석·박사 학위 과정 지원 기재 — 선발 인원·지원 범위 미기재', 90),
  (@comp_id, 'retirement_support', '퇴직자 재취업 지원', NULL, 'growth',
   'est', NULL, TRUE, '퇴직 예정인 만 50세 이상 근로자 재취업 지원 서비스와 정년 앞둔 장기근속자 공로여행(유급휴가·여행 경비 지원) (2025 지속가능경영보고서 66쪽 복리후생 제도 표, 2025년 기준 · 공식 채용정보 복지제도 페이지 회사생활 항목 — 서비스 내용·기간·휴가 일수·여행 경비 한도 미기재)', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
