-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 한올바이오파마 복리후생 데이터 (신규 회사 — 웨이브 10)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://hanall.com/kr/data/%ED%95%9C%EC%98%AC%EB%B0%94%EC%9D%B4%EC%98%A4%ED%8C%8C%EB%A7%88%202025%20%EC%A7%80%EC%86%8D%EA%B0%80%EB%8A%A5%EA%B2%BD%EC%98%81%EB%B3%B4%EA%B3%A0%EC%84%9C.pdf
-- badge: est
--
-- 참고:
--   정본 = 한올바이오파마 자기 도메인(hanall.com · DART 홈 www.hanall.co.kr 이 이리로 넘김) ESG 메뉴에 올린
--     2025 지속가능경영보고서 PDF(첫 발간 · 발행 2026-06-30 · 보고 기간 2025-01-01~12-31 · 보고 범위 = 한올바이오파마 본사 및 대전 공장).
--     23쪽 맞춤형 성장 지원 프로그램 표 · 24쪽 근로환경 제도 표 · 41쪽 성과연계 보상 체계. 법인 단독 보고서라 각주 없음.
--     PDF 텍스트 추출(pypdf) + 23 · 24쪽 표는 쪽 이미지로 짝 확인. 헤드리스 렌더 없음.
--   보조 = 자기 도메인 ESG 사회 페이지(SSR) m42.php tabNum=1 조직문화 · tabNum=3 인재육성 ·
--     같은 ESG 메뉴의 2024 EHS 경영 보고서 PDF 19쪽(건강검진 행만) ·
--     공시 = 2025 사업보고서(접수 20260318001637) · 2026 반기보고서(접수 20260814003675) 직원 등 현황 유연근무제도 사용 현황 표.
--   귀속: 대웅 계열(최대주주 대웅제약)이지만 대웅 그룹 채용 사이트 · 대웅제약 발행 3사 범위 보고서는 쓰지 않았다(계약 1-9).
--     모든 행이 한올바이오파마 자기 도메인 · 자기 발행 보고서 · 자기 공시 문장. 그룹 각주 없음.
--   금액 행 0(stated 0 · 추정 0). 원문에 원 단위 금액 없음. 식대 원문 없음.
--   제외: 육아휴직 · 출산전후휴가 · 법정 건강진단(일반 · 특수 · 배치전) · 법정 의무교육(법정) ·
--     직무 전문성 강화 · 거현량 · 월례 학습 · 소통 세션 · 육성형 피드백 · AI · 빅데이터 아카데미 · 교육지원 중 AI 활용 ·
--     Onboarding · 리더십 · CP · 산업안전보건 교육 · 산업 및 직무 특화 교육(업무 교육) ·
--     글로벌 리더 양성 해외 연수(발행일 없는 조직문화 페이지에만 · 더 새 보고서 표에서 빠짐) ·
--     주식매수선택권 · RSU(경영진 재량 부여) · 임원 보수지급기준 칸의 건강검진 · 상해보험 · 자녀학자금(임원 전용) ·
--     사내고충신고 · 익명 게시판(복지 아님).
--   공고 근거 0행 / 전체 11행.
--   SORT 섹션 순서(정본 23 · 24쪽에 처음 나온 순서): compensation 10 · growth 20 · flexibility 30 · family 40 ·
--     leisure 50 · 보조 출처에만 있는 health 60.
-- 검증 · 감사 판정 반영(2026-10-15): 스톡그랜트 stock_grant 행 삭제(개인 연봉계약 · 이사회 결의 재량 부여 · 공시 개인별 부여는 등기임원 · 대표이사 몫) · 참고 블록의 공고 근거 0행 / 전체 11행은 전체 10행 · 항목 페이지 예외 2(통합 밖 리드 집행) — 최종 10행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hanall_biopharma', '한올바이오파마',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '제약', 'H', 'https://hanall.com/kr/data/%ED%95%9C%EC%98%AC%EB%B0%94%EC%9D%B4%EC%98%A4%ED%8C%8C%EB%A7%88%202025%20%EC%A7%80%EC%86%8D%EA%B0%80%EB%8A%A5%EA%B2%BD%EC%98%81%EB%B3%B4%EA%B3%A0%EC%84%9C.pdf');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hanall_biopharma');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://hanall.com/kr/data/%ED%95%9C%EC%98%AC%EB%B0%94%EC%9D%B4%EC%98%A4%ED%8C%8C%EB%A7%88%202025%20%EC%A7%80%EC%86%8D%EA%B0%80%EB%8A%A5%EA%B2%BD%EC%98%81%EB%B3%B4%EA%B3%A0%EC%84%9C.pdf'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상 (compensation) — 보고서 23 · 41쪽 + ESG 사회 조직문화 페이지 + 2025 사업보고서 ──
  (@comp_id, 'excellence_award', '우수인재 정기 포상', NULL, 'compensation',
   'est', NULL, TRUE, '우수인재 대상 정기 포상, 사내 발표회 (2025 지속가능경영보고서 23쪽 맞춤형 성장 지원 프로그램 성과 공유·포상 항목), 우수 인재에 대한 정기 포상 및 사내 발표회를 통해 노력과 성장을 인정 (ESG 사회 조직문화 페이지 성과 공유와 동기 부여 항목) — 포상 기준·포상 내용 미기재', 10),

  -- ── 성장·교육 (growth) — 보고서 23 · 24쪽 + ESG 사회 인재육성 페이지 ──
  (@comp_id, 'edu_support', '교육지원·사이버교육·사내학습조직', NULL, 'growth',
   'est', NULL, TRUE, '교육지원(사내/외) 도입 (2025 지속가능경영보고서 24쪽 근로환경 제도 항목), 전 직원 대상 사이버교육, 사내학습조직(SOP) (23쪽 맞춤형 성장 지원 프로그램 자기개발 지원 항목), 개인별 관심 분야에 대한 온라인 학습 지원, 사내 학습조직 운영 (ESG 사회 인재육성 페이지 Self Learning 항목), 외부 전문 교육지원 (같은 페이지 직무 기술 항목) — 사외 교육비 한도·신청 절차 미기재', 20),
  (@comp_id, 'books', '도서지원', NULL, 'growth',
   'est', NULL, TRUE, '전 직원 대상 도서지원 (2025 지속가능경영보고서 23쪽 맞춤형 성장 지원 프로그램 자기개발 지원 항목), 교육지원(도서) 도입 (24쪽 근로환경 제도 항목), 도서지원 (ESG 사회 인재육성 페이지 Self Learning 항목) — 지원 한도·지원 방식 미기재', 21),
  (@comp_id, 'career', 'CDP', NULL, 'growth',
   'est', NULL, TRUE, 'CDP, 자율적으로 직무를 탐색하고 다양한 유관 직무를 경험하며 전체 맥락을 이해하는 전문가로 성장할 수 있도록 지원 (ESG 사회 인재육성 페이지 인재육성 프로그램 항목) — 대상·직무 이동 신청 방식 미기재', 22),

  -- ── 근무 유연성 (flexibility) — 보고서 24쪽 + 2025 사업보고서 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '유연근무제 (조건부)', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 활용 (2025 지속가능경영보고서 24쪽 근로환경 제도 항목), 시차출퇴근제를 직무특성, 질환, 주거 여건, 임신 및 출산 등 내부 기준에 따른 특별 사유로 활용 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 코어타임·신청 절차 미기재', 30),
  (@comp_id, 'remote_work', '재택근무 (조건부)', NULL, 'flexibility',
   'est', NULL, TRUE, '재택근무 도입 (2025 지속가능경영보고서 24쪽 근로환경 제도 항목), 원격근무제(재택근무 포함)를 직무특성, 질환, 주거 여건, 임신 및 출산 등 내부 기준에 따른 특별 사유로 활용 (2025 사업보고서·2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 재택근무 횟수·신청 절차 미기재', 31),

  -- ── 가족 (family) — 보고서 24쪽 ──
  (@comp_id, 'child_edu', '자녀 학자금 지원 (유치원 입학 지원금)', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원(유치원 입학 지원금) 도입 (2025 지속가능경영보고서 24쪽 근로환경 제도 항목) — 지원 학교 급·지원 금액 미기재', 40),
  (@comp_id, 'parenting', '출산 축하금', NULL, 'family',
   'est', NULL, TRUE, '출산 축하금 도입 (2025 지속가능경영보고서 24쪽 근로환경 제도 항목) — 지급 금액·지급 조건 미기재', 41),

  -- ── 여가 (leisure) — 보고서 24쪽 ──
  (@comp_id, 'resort', '그룹사 콘도', NULL, 'leisure',
   'est', NULL, TRUE, '그룹사 콘도 도입 (2025 지속가능경영보고서 24쪽 근로환경 제도 항목) — 이용 시설·이용 횟수·비용 부담 미기재', 50),

  -- ── 건강 (health) — 2024 EHS 경영 보고서 19쪽 ──
  (@comp_id, 'health_check', '개인 맞춤검진·종합건강관리', NULL, 'health',
   'est', NULL, TRUE, '임직원들에게 1:1 맞춤 건강관리 플랫폼을 기반으로 개인 맞춤검진과 검진 결과에 따른 지속적인 건강관리 솔루션을 포함한 종합건강관리 제공 (2024 EHS 경영 보고서 19쪽 임직원 건강증진 및 질병예방 활동 성과 항목) — 검진 주기·비용 지원 범위·가족 범위 미기재', 60)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
