-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 일진전기 복리후생 데이터 (신규 회사 — 웨이브 8)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.iljinelectric.co.kr/esg/esg-data-hub/esg-reporting
-- badge: est
--
-- 참고:
--   정본은 상장 법인 일진전기(주) 자기 도메인 www.iljinelectric.co.kr 지속가능경영 > ESG Data Hub > ESG Reporting
--   보고서 목록 페이지다. 행 근거는 그 목록의 가장 새 판인 2025 일진전기 지속가능경영보고서 국문 PDF
--   (113쪽 · 작성 2026-07-28 · 보고 기간 2025-01-01~2025-12-31 · 일부 2026 상반기 포함 ·
--   보고 범위 일진전기 국내 사업장 중심(마곡이노센터 · 화성 제1 · 제2공장 · 홍성공장 · 안산공장) · 법인 단독 발행).
--   54쪽 복리후생 지원 12항목 표 + 50쪽 보상 체계 · 포상 + 51쪽 인재육성 체계 표 + 52쪽 강의 지원 +
--   60쪽 임직원 건강검진 + 107쪽 UN SDGs 주요활동 표(수유실 및 여성 휴게실 운영 · 임직원 체육시설 운영).
--   렌더: 목록 페이지 SSR(기본 영문 · ?lang=ko 국문) · PDF 텍스트 추출 · 54쪽은 이미지로 띄워 표 칸을 확인했다.
--   귀속: 법인 자기 발행 보고서의 일진전기 주어 문장 · 표 — 각주 없음. 코퍼스 · 대기 시드에 일진 그룹 형제 없음.
--   금액: 원문에 원 단위 숫자 0건 — 전 행 BENEFIT_AMT NULL.
--   제외: 법정(육아휴직 · 육아기 단축근로 · 법정 일반 · 특수 건강검진 · 법정 의무교육 · 직무발명보상 ·
--     보건관리 대행기관 간호사 방문 상담) · 업무 교육(리더십 · 직무기본 · 직무심화 · 승진자 · 특별 교육 · 멘토링 · 학점제) ·
--     지표 표의 제도 이름(선택적 근로시간제 · 시차출퇴근제 · 원격근무제 3년 0명 · 반기보고서 유연근무제 활용 여부 X) ·
--     옛 판에만 있는 자격 · 면허 취득 지원(2024 보고서 — 2025 판은 자기계발 교육 지원으로 바뀜) ·
--     조직문화 감사 캠페인 · 사진 캡션 공장 휴게실 · 공장 탕비실 · 금연클리닉 · 임원 보수 칸 · 우리사주조합 주주 표 한 칸.
--   공고 근거 0행 / 전체 15행.
--   SORT 섹션 순서 = 보고서 등장 순(compensation 10 · growth 20 · work_env 30 · family 40 · perks 50 · health 60 · leisure 70).
-- 검증 · 감사 판정 반영(2026-10-15): 행 조치 없음 · 정본 목록 페이지 유지 — 최종 15행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('iljin_electric', '일진전기',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '전선/전력', 'I', 'https://www.iljinelectric.co.kr/esg/esg-data-hub/esg-reporting');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'iljin_electric');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.iljinelectric.co.kr/esg/esg-data-hub/esg-reporting'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상 (compensation) — 2025 지속가능경영보고서 50쪽 ──
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '성과 평가 결과에 따라 성과급을 차등 지급하는 체계 (2025 지속가능경영보고서 50쪽 보상 체계 항목) — 지급률·지급 시기 미기재', 10),
  (@comp_id, 'excellence_award', '상시 포상 제도 (분기 Best Award · 창립기념일 포상 · STAR Award)', NULL, 'compensation',
   'est', NULL, TRUE, '분기별 Best Award 등 상시 포상 제도 운영, 창립기념일 포상 · 회사 발전에 공로가 인정되는 임직원에 포상, STAR Award · 신규 사업/제품이나 기존 Process 개선을 통한 수익 발생에 따라 그 공로가 인정되는 임직원에 포상 (2025 지속가능경영보고서 50쪽 공정한 성과 평가와 성장 지원 항목) — 포상 금액·선정 인원 미기재', 11),
  -- ── 성장 · 교육 (growth) — 2025 지속가능경영보고서 51 · 52 · 54쪽 ──
  (@comp_id, 'edu_support', '자기계발 교육 지원 · 온라인 강의 지원', NULL, 'growth',
   'est', NULL, TRUE, '자기계발 교육 지원 (2025 지속가능경영보고서 54쪽 복리후생 항목), 임직원의 자기 계발과 역량 강화를 위한 온라인 강의 지원 제도 · 인문학 등 다양한 분야 콘텐츠 자유 선택 (52쪽 직원 역량 강화를 위한 강의 지원 항목), 전직원 대상 선택형 자기주도학습 온라인/독서통신교육 (51쪽 인재육성 체계 항목) — 교육비 지원 범위 미기재', 20),
  (@comp_id, 'lang', '어학 온라인 강의', NULL, 'growth',
   'est', NULL, TRUE, '온라인 강의 지원 제도의 어학 분야 콘텐츠, 임직원 매월 1개 이상 강의 수강 가능 · 자유 선택 (2025 지속가능경영보고서 52쪽 직원 역량 강화를 위한 강의 지원 항목) — 대상 언어·비용 부담 미기재', 21),
  -- ── 근무환경 (work_env) — 2025 지속가능경영보고서 54 · 107쪽 ──
  (@comp_id, 'nap_room', '수유실', NULL, 'work_env',
   'est', NULL, TRUE, '수유실 (2025 지속가능경영보고서 54쪽 복리후생 항목), 수유실 운영 (107쪽 UN SDGs 주요활동 항목) — 설치 사업장·이용 조건 미기재', 30),
  (@comp_id, 'lounge', '여성 휴게실 · 편의시설 제공', NULL, 'work_env',
   'est', NULL, TRUE, '여성 휴게실 운영 (2025 지속가능경영보고서 107쪽 UN SDGs 주요활동 항목), 편의시설 제공 (54쪽 복리후생 항목) — 설치 사업장·편의시설 종류 미기재', 31),
  (@comp_id, 'dormitory', '공장 근무자 기숙사 지원', NULL, 'work_env',
   'est', NULL, TRUE, '공장 근무자 기숙사 지원 (2025 지속가능경영보고서 54쪽 복리후생 항목) — 입주 조건·비용 부담 미기재', 32),
  -- ── 가족 (family) — 2025 지속가능경영보고서 54쪽 ──
  (@comp_id, 'child_edu', '자녀 학자금', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 (2025 지속가능경영보고서 54쪽 복리후생 항목) — 지원 학년·지원 한도 미기재', 40),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 (2025 지속가능경영보고서 54쪽 복리후생 항목) — 경조금·경조휴가 기준 미기재', 41),
  -- ── 생활 · 금융 (perks) — 2025 지속가능경영보고서 54쪽 ──
  (@comp_id, 'housing_loan', '주택마련 자금지원', NULL, 'perks',
   'est', NULL, TRUE, '주택마련 자금지원 (2025 지속가능경영보고서 54쪽 복리후생 항목) — 지원 방식·한도·대상 미기재', 50),
  (@comp_id, 'telecom', '통신비 지원', NULL, 'perks',
   'est', NULL, TRUE, '통신비 지원 (2025 지속가능경영보고서 54쪽 복리후생 항목) — 지원 금액·대상 미기재', 51),
  (@comp_id, 'transport', '자가운전 보조금 지원', NULL, 'perks',
   'est', NULL, TRUE, '자가운전 보조금 지원 (2025 지속가능경영보고서 54쪽 복리후생 항목) — 지급액·지급 대상 미기재', 52),
  -- ── 건강 (health) — 2025 지속가능경영보고서 54 · 60 · 107쪽 ──
  (@comp_id, 'health_check', '종합 건강검진', NULL, 'health',
   'est', NULL, TRUE, '건강검진 (2025 지속가능경영보고서 54쪽 복리후생 항목), 매년 종합 건강검진 실시 · 개인의 연령, 건강 상태, 직무 특성을 고려한 맞춤형 검진 항목 제공 (60쪽 임직원 건강검진 실시 항목) — 검진 비용 지원 범위·가족 검진 여부 미기재', 60),
  (@comp_id, 'fitness', '임직원 체육시설', NULL, 'health',
   'est', NULL, TRUE, '임직원 체육시설 운영 (2025 지속가능경영보고서 107쪽 UN SDGs 주요활동 항목), 마곡이노센터 실내 헬스장 · 홍성공장 야외 체육시설 (54쪽 복리후생 지원 사진 항목) — 이용 시간·비용 미기재', 61),
  -- ── 여가 (leisure) — 2025 지속가능경영보고서 54쪽 ──
  (@comp_id, 'resort', '임직원 휴양시설 리조트 지원', NULL, 'leisure',
   'est', NULL, TRUE, '임직원 휴양시설 리조트 지원 (2025 지속가능경영보고서 54쪽 복리후생 항목) — 이용 횟수·비용 지원 범위 미기재', 70)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
