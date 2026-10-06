-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 에코프로비엠 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://www.ecoprobm.com/sub0107
-- badge: est
--
-- 참고:
--   정본은 에코프로비엠 공식 홈페이지 www.ecoprobm.com 헤더 메뉴 회사소개 → 복리후생 페이지(/sub0107)다.
--   서버 렌더 HTML 에 5구역(금전적 지원 · 생활안정 지원 · 기타 지원 · 여가활동 지원 · 건강증진 지원) 20항목이
--   그대로 있다 — 헤드리스 렌더 없음. 구역 사진 5장은 글자 없는 사진이라 판독 대상이 아니다.
--   꼬리말 = 주식회사 에코프로비엠 · Copyright ECOPROBM.
--   보조 출처:
--     에코프로비엠 2022 지속가능경영보고서(같은 사이트 /download/ 경로 · 38~39쪽 에코프로비엠 복지제도 ·
--     자기개발제도 · 여성인재 절). 2023~2025 보고서는 robots 금지 경로라 받지 않았다.
--     에코프로 그룹 채용 사이트 ecoprorecruit.co.kr 복지제도(회사 홈 헤더 Recruit 링크 · 채용공고 회사명에
--     에코프로비엠이 있다) — 그룹 공통이라 해당 행 서술에 그룹 공통 각주.
--     같은 사이트 뉴스와 공지 보도자료(2026-03-06)는 기사 주어가 에코프로라 이 법인 적용을 밝히지 않아 행 · 세부 근거로 쓰지 않았다.
--   귀속: ㈜에코프로(지주) 홈페이지 복리후생 페이지와 항목 문구가 한 줄(정착지원금 · 주거지원금)만 다르고
--     같다 — 이 법인 페이지에 있는 문장만 실었다.
--   금액: 구본 추정 승계 4(health_check 100 · resort 50 · welfare_point 200 · meal 288 — 전부 틀 값,
--     NOTE 끝에 (추정)). 평가급 최대 월 20만원은 한도라 금액 칸에 넣지 않았다.
--   제외 항목: 여가활동 지원의 법정 휴가 항목 · 사우회 운영(혜택 미기재) ·
--     사내 교육 과정(직무 · 리더십 — 사무직 어학강의 · 온라인 교육은 2026-10-04 규칙 8 개정으로 되살림) · 일회성 해외연수 · 주식 보상(부여 완료).
--   구본에서 뺀 행: edu_support(직무 · 리더십 교육 과정 — 사무직 온라인 교육은 2026-10-04 되살림).
--   재코딩: 없음. 구본 profit_sharing 한 행에 묶였던 특별상여 · 평가급을 bonus · incentive 로 나눴다.
--   SORT 섹션 순서 = 복리후생 페이지에서 카테고리가 처음 나온 순서, 보조 출처 항목은 해당 섹션 끝
--     (compensation 10 · perks 20 · family 30 · health 40 · leisure 50 · growth 60).
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-5): 주어가 에코프로인 보도자료 세부(학자금 실비 · 특수교육비 대상 연령과 한도 · 난임 시술 회당 금액)를 걷고 child_edu 는 2022 지속가능경영보고서 에코프로비엠 복지제도로 근거 교체 · 복리후생 페이지의 제휴업체 직원 할인(discount) 복원 · 머리말 주석 정정 — 최종 21행
-- 후속 정리 2(2026-10-04, R-3): 사용자가 정한 복지 범위 규칙 개정(규칙 8 · 기준 13 · 기준 18 · 기준 20 · 기준 23)과 코퍼스 판정을 반영 — 새 행 3(severance_plus · lang · edu_support) — 최종 24행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 2026-10-06 식대 기준 금액 1끼 12,000원(리드 판정 (82)) — meal 행 금액 = 1끼 단가 × 끼니 × 연 240일, 꼬리에 식 공개

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('ecopro_bm', '에코프로비엠',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '배터리소재', 'E', 'https://www.ecoprobm.com/sub0107');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'ecopro_bm');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.ecoprobm.com/sub0107'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) — 금전적 지원 3 · 기타 지원 장기근속자 포상 · 우수사원 포상 ──
  (@comp_id, 'bonus', '특별상여 (연간 3회)', NULL, 'compensation',
   'est', NULL, TRUE, '특별상여 연간 3회 지급 (공식 홈페이지 회사소개 복리후생 금전적 지원 항목) — 지급 기준·지급률 미기재', 10),
  (@comp_id, 'incentive', '평가급 (운영직)', NULL, 'compensation',
   'est', NULL, TRUE, '운영직 대상 평가급 지급, 최대 월 20만원 (공식 홈페이지 회사소개 복리후생 금전적 지원 항목) — 평가 기준·실제 지급액 미기재', 11),
  (@comp_id, 'profit_sharing', '성과급 (Profit Sharing)', NULL, 'compensation',
   'est', NULL, TRUE, '성과급 지급 (Profit Sharing) (공식 홈페이지 회사소개 복리후생 금전적 지원 항목) — 이익 배분 기준·지급률 미기재', 12),
  (@comp_id, 'long_service_bonus', '장기근속자 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속자 포상 (공식 홈페이지 회사소개 복리후생 기타 지원 항목) — 근속 기준·포상 내용 미기재', 13),
  (@comp_id, 'excellence_award', '우수사원 포상', NULL, 'compensation',
   'est', NULL, TRUE, '우수사원 포상 (공식 홈페이지 회사소개 복리후생 기타 지원 항목) — 선정 기준·포상 내용 미기재', 14),
  (@comp_id, 'severance_plus', '퇴직금 누진제도', NULL, 'compensation',
   'est', NULL, TRUE, '퇴직금 누진제도 (공식 홈페이지 회사소개 복리후생 생활안정 지원 항목), 10년 이상 근무한 장기근속자를 위하여 재직기간에 따라 퇴직금의 최대 100% 추가 지급 (2022 지속가능경영보고서 38쪽) — 재직기간별 추가 지급 비율 미기재', 15),

  -- ── 경제적 부가혜택 (perks) — 생활안정 지원 사택 또는 정착지원금 · 기타 지원 구내식당 / 그룹 채용 사이트 복지포인트 / 여가활동 지원 제휴업체 직원 할인 ──
  (@comp_id, 'relocation', '사택 또는 정착지원금', NULL, 'perks',
   'est', NULL, TRUE, '사택 또는 정착지원금 지급 (공식 홈페이지 회사소개 복리후생 생활안정 지원 항목) — 지급 대상·지급액 미기재', 20),
  (@comp_id, 'meal', '구내식당 (중/석식)', 576, 'perks',
   'est', '구내식당 운영, 중식·석식 제공 (공식 홈페이지 회사소개 복리후생 기타 지원 항목) — 식대 단가·본인 부담 미기재 (하루 2끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 21),
  (@comp_id, 'welfare_point', '복지포인트', 200, 'perks',
   'est', '복지포인트 지원 (그룹 채용 사이트 복지제도 항목 · 2022 지속가능경영보고서 에코프로비엠 복지제도 — 그룹 공통) — 연간 배정액 미기재 (추정)', FALSE, NULL, 22),
  (@comp_id, 'discount', '제휴업체 직원 할인', NULL, 'perks',
   'est', NULL, TRUE, '제휴업체 직원 할인 (공식 홈페이지 회사소개 복리후생 여가활동 지원 항목) — 제휴처·할인율 미기재', 23),

  -- ── 가족·돌봄 (family) — 생활안정 지원 경조사 · 학자금 / 건강증진 지원 특수교육비 · 난임 / 2022 보고서 어린이집 ──
  (@comp_id, 'event', '경조사 지원 (장례용품 포함)', NULL, 'family',
   'est', NULL, TRUE, '각종 경조사 지원, 장례용품 포함 (공식 홈페이지 회사소개 복리후생 생활안정 지원 항목) — 경조 종류별 금액·휴가 일수 미기재', 30),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '학자금 지원 (공식 홈페이지 회사소개 복리후생 생활안정 지원 항목), 공동근로복지기금을 통한 자녀학자금 지원 (2022 지속가능경영보고서 에코프로비엠 복지제도) — 지원 학교급·한도 미기재', 31),
  (@comp_id, 'disability_family_support', '발달장애 자녀 특수교육비 지원', NULL, 'family',
   'est', NULL, TRUE, '발달장애 자녀 특수교육비 지원 (공식 홈페이지 회사소개 복리후생 건강증진 지원 항목) — 대상 연령·지원 한도 미기재', 32),
  (@comp_id, 'fertility_support', '난임 시술 지원', NULL, 'family',
   'est', NULL, TRUE, '난임 시술 지원 (공식 홈페이지 회사소개 복리후생 건강증진 지원 항목) — 지원 금액·횟수 미기재', 33),
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '가정과 일의 양립을 위한 직장 어린이집 운영 (2022 지속가능경영보고서 여성인재 육성 절), 어린이집 (그룹 채용 사이트 복지제도 항목 — 그룹 공통) — 위치·정원 미기재', 34),

  -- ── 건강·의료 (health) — 기타 지원 부대시설 / 건강증진 지원 검진 · 의료비 / 그룹 채용 사이트 상담 서비스 ──
  (@comp_id, 'fitness', '부대시설 (헬스장·당구장·탁구장)', NULL, 'health',
   'est', NULL, TRUE, '부대시설 운영, 헬스장·당구장·탁구장 등 (공식 홈페이지 회사소개 복리후생 기타 지원 항목) — 사업장별 시설·이용 시간 미기재', 40),
  (@comp_id, 'health_check', '종합건강검진', 100, 'health',
   'est', '종합건강 검진 (공식 홈페이지 회사소개 복리후생 건강증진 지원 항목) — 검진 주기·가족 포함 여부·지원 한도 미기재 (추정)', FALSE, NULL, 41),
  (@comp_id, 'medical', '임직원 및 가족 의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '임직원 및 가족 의료비 지원 (공식 홈페이지 회사소개 복리후생 건강증진 지원 항목) — 지원 범위·한도 미기재', 42),
  (@comp_id, 'mental', '건강 상담 서비스', NULL, 'health',
   'est', NULL, TRUE, '신체 및 정신 건강을 위한 상담 서비스 지원 (그룹 채용 사이트 복지제도 일과 삶의 균형 · 2022 지속가능경영보고서 에코프로비엠 복지제도 — 그룹 공통) — 상담 기관·이용 횟수 미기재', 43),

  -- ── 여가·라이프 (leisure) — 여가활동 지원 휴양시설 · 사내동호회 ──
  (@comp_id, 'resort', '휴양시설', 50, 'leisure',
   'est', '휴양시설 운영 (공식 홈페이지 회사소개 복리후생 여가활동 지원 항목) — 시설 위치·이용 일수·비용 부담 미기재 (추정)', FALSE, NULL, 50),
  (@comp_id, 'club', '사내동호회 운영/지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내동호회 운영·지원 (공식 홈페이지 회사소개 복리후생 여가활동 지원 항목) — 활동비 금액 미기재', 51),

  -- ── 성장·교육 (growth) — 2022 보고서 자기개발제도 ──
  (@comp_id, 'self_development', '자격증 취득 축하금 (운영직)', NULL, 'growth',
   'est', NULL, TRUE, '운영직 대상 개발·품질, 생산·설비·인프라, 환경안전 등 직무 관련 자격증 취득 시 축하금 지급 (2022 지속가능경영보고서 자기개발제도 프로그램 절) — 축하금 액수 미기재', 60),
  (@comp_id, 'lang', '사내외 어학강의 (사무직)', NULL, 'growth',
   'est', NULL, TRUE, '사무직 대상 사내외 어학강의 등 자기개발 교육 연 20시간 지원, 자기개발 영역 영어/중국어 과정 (2022 지속가능경영보고서 37~38쪽 자기개발제도 프로그램 절) — 비용 부담·수강 방식 미기재', 61),
  (@comp_id, 'edu_support', '온라인 교육 (사무직)', NULL, 'growth',
   'est', NULL, TRUE, '사무직 대상 온라인 교육 등 자기개발 교육 연 20시간 지원 (2022 지속가능경영보고서 38쪽 자기개발제도 프로그램 절) — 과정 분야·비용 부담 미기재', 62)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
