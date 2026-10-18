-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 트리니티항공 복리후생 데이터 (신규 회사 — 웨이브 12)
-- 출처: AI 파싱 (2026-10-18)
-- URL: https://www.trinityairways.com/app/serviceInfo/contents/1476
-- badge: est
--
-- 참고:
--   정본은 상장 법인 (주)트리니티항공(옛 사명 티웨이항공 · 2026-03-31 정기주주총회에서 사명 변경)의
--   자기 도메인 www.trinityairways.com 회사 소개 > 지속가능경영 웹 페이지다(옛 도메인 www.twayair.com 은 새 도메인으로 넘어간다).
--   SSR 이라 원본 HTML 에 임직원 복리후생 6블록(div.contents_benefit_box_1)과 직원건강 증진활동 · 임직원 교육체계가 다 있다. 헤드리스 렌더 · 이미지 판독 불필요. HTML 주석 속 옛 블록은 쓰지 않았다.
--   공식 홈 상단 메뉴 채용안내가 회사 계정 ATS trinityairways.recruiter.co.kr 로 이어지지만 복리후생 본문이
--   원본 HTML 에 없고(클라이언트 요청) 같은 벤더 API 호스트 robots 가 전면 금지라 읽지 않았다 — 붙여넣기 보강 후보.
--   공시 보조: OpenDART 2026 반기보고서(접수 20260813001054) 유연근무제 사용 현황(시차출퇴근제) ·
--   재무제표 주석 우발 및 약정사항(우리사주조합 차입금 연대보증 · 예금 담보) · 2025 사업보고서 정정(접수 20260430001376) 같은 표.
--   귀속: 페이지 주어가 트리니티항공 단수 법인이고 계열사 · 그룹 공통 단서가 없다 — 각주 없음.
--   최대주주 소노인터내셔널(소노트리니티그룹) — 코퍼스에 같은 그룹 법인 없음.
--   금액: 원문에 원 단위 숫자 0건 — 전 행 BENEFIT_AMT NULL. 식권 제공은 끼니 · 단가 미기재라 NULL.
--   제외: 정기 건강검진(같은 페이지가 연령별 맞춤 정기 건강진단(일반/특수)로 법정 검진 이름만 밝힘) ·
--     사내외 직무교육 지원과 계층별 · 직무 전문 교육 과정(업무 교육) · 자율 복장 두발 자유화(대응 코드 없음) ·
--     항공보건 직무 특화 질병 예방 · 온열 한랭질환 예방 물품(산업보건) · 안전 포상 · 근로자 참여형 이벤트 및 포상(안전) ·
--     협력사 우수사원 포상(다른 법인) · 감정노동 대응 사내 심리상담(고객응대근로자 보호조치 표) ·육아 지원 제도 한 줄(내용 없음 · 법정 가능) · 육아휴직 사용 현황(법정) ·
--     원격근무제 · 선택근무제(공시 미운영) · 사업보고서 항공업무 지원사업 회사 복리후생 문장(종속회사 문장).
--   공고 근거 0행 / 전체 21행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(health 10 · perks 20 · family 30 · growth 40 · leisure 50 ·
--     flexibility 60 · compensation 70 · time_off 80).
-- 검증 · 감사 판정 반영(2026-10-18): 행 조치 없음 · 수집본 21행 그대로 · 옛 사명 티웨이항공(2026-03-31 상호 변경 · 같은 법인) · 정본 점검기 blocked(점검기 UA 403 · 브라우저 200) 배포 시 주의 · 정기 건강진단(일반/특수)은 싣지 않음(리드 판정 147) — 최종 21행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('trinity_air', '트리니티항공',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '항공', 'T', 'https://www.trinityairways.com/app/serviceInfo/contents/1476');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'trinity_air');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.trinityairways.com/app/serviceInfo/contents/1476'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강 (health) — 지속가능경영 페이지 직원건강 증진활동 · 임직원 복리후생 건강지원 ──
  (@comp_id, 'clinic', '사내 보건실·독감접종 지원', NULL, 'health',
   'est', NULL, TRUE, '보건실 운영 (지속가능경영 페이지 임직원 복리후생 건강지원 항목), 집단 감염 예방을 위한 독감접종 지원 (같은 페이지 직원건강 증진활동 항목) — 보건실 상주 인력·운영 사업장 미기재', 10),
  (@comp_id, 'mental', '비대면 심리상담 프로그램 [온, 숨]', NULL, 'health',
   'est', NULL, TRUE, '심리·정신 건강 지원 강화, 비대면 심리상담 프로그램 [온, 숨] (지속가능경영 페이지 직원건강 증진활동 항목) — 상담 횟수·이용 대상 범위 미기재', 11),
  (@comp_id, 'smoking_cessation', '금연클리닉', NULL, 'health',
   'est', NULL, TRUE, '금연클리닉 진행 (지속가능경영 페이지 임직원 복리후생 건강지원 항목), 금연 성공률 및 프로그램 효과성 측정하여 내부 인센티브 제도와 연계 (같은 페이지 직원건강 증진활동 항목) — 인센티브 금액·지급 기준 미기재', 12),
  (@comp_id, 'fitness', '걷기 프로그램', NULL, 'health',
   'est', NULL, TRUE, '건강한 생활습관 유도 프로그램 고도화 중 걷기 프로그램 (지속가능경영 페이지 직원건강 증진활동 항목) — 운영 방식·참여 대상·기간 미기재', 13),
  (@comp_id, 'overseas_safety', '해외 주재원 보험', NULL, 'health',
   'est', NULL, TRUE, '해외 주재원 보험 (지속가능경영 페이지 임직원 복리후생 건강지원 항목) — 보장 내용·보험 종류 미기재', 14),

  -- ── 생활 (perks) — 지속가능경영 페이지 임직원 복리후생 항공권 지원 · 가족친화 생활 지원 ──
  (@comp_id, 'discount', '우대항공권 제공', NULL, 'perks',
   'est', NULL, TRUE, '우대항공권 제공 (직원 및 배우자의 직계가족) (지속가능경영 페이지 임직원 복리후생 항공권 지원 항목) — 할인율·연간 매수 미기재', 20),
  (@comp_id, 'meal', '식권 제공', NULL, 'perks',
   'est', NULL, TRUE, '식권 제공 (지속가능경영 페이지 임직원 복리후생 가족친화 생활 지원 항목) — 제공 끼니·금액 미기재', 21),
  (@comp_id, 'snack_bar', '사내 카페 운영', NULL, 'perks',
   'est', NULL, TRUE, '사내 카페 운영 (지속가능경영 페이지 임직원 복리후생 가족친화 생활 지원 항목) — 이용 금액·운영 사업장 미기재', 22),

  -- ── 가족 (family) — 지속가능경영 페이지 임직원 복리후생 항공권 지원 · 가족친화 생활 지원 ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 항공권 지원 (지속가능경영 페이지 임직원 복리후생 항공권 지원 항목), 경조사비, 화환, 휴가, 장례용품 지원 (같은 페이지 가족친화 생활 지원 항목) — 경조 유형별 금액·휴가 일수 미기재', 30),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원 (지속가능경영 페이지 임직원 복리후생 가족친화 생활 지원 항목) — 지원 학교급·금액 미기재', 31),
  (@comp_id, 'parenting', '어린이집 위탁보육료 지원', NULL, 'family',
   'est', NULL, TRUE, '어린이집 위탁보육료 지원 (지속가능경영 페이지 임직원 복리후생 가족친화 생활 지원 항목) — 지원 금액·대상 자녀 연령 미기재', 32),

  -- ── 성장 (growth) — 지속가능경영 페이지 임직원 복리후생 항공권 지원 · 자기개발 지원 · 임직원 교육체계 ──
  (@comp_id, 'retirement_support', '퇴직자 항공권', NULL, 'growth',
   'est', NULL, TRUE, '근속연수 비례 퇴직자 항공권 사용 가능 (지속가능경영 페이지 임직원 복리후생 항공권 지원 항목) — 근속 기준·항공권 매수 미기재', 40),
  (@comp_id, 'edu_support', '사이버 연수원 운영', NULL, 'growth',
   'est', NULL, TRUE, '사이버 연수원 운영 (지속가능경영 페이지 임직원 복리후생 자기개발 지원 항목) — 과정 구성·수강 대상 미기재', 41),
  (@comp_id, 'lang', '외국어 역량 향상 교육', NULL, 'growth',
   'est', NULL, TRUE, '글로벌 역량 향상 과정 중 외국어 역량 향상 교육 (지속가능경영 페이지 임직원 교육체계 항목) — 교육 대상·언어·운영 방식 미기재', 42),

  -- ── 여가 (leisure) — 지속가능경영 페이지 임직원 복리후생 자기개발 지원 · 여가 지원 ──
  (@comp_id, 'library', '사내 도서관 운영', NULL, 'leisure',
   'est', NULL, TRUE, '사내 도서관 운영 (지속가능경영 페이지 임직원 복리후생 자기개발 지원 항목) — 장서 규모·운영 사업장 미기재', 50),
  (@comp_id, 'club', '동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '취미활동(동호회) 지원 (지속가능경영 페이지 임직원 복리후생 여가 지원 항목) — 지원 금액·동호회 수 미기재', 51),
  (@comp_id, 'resort', '국내외 계약 호텔 직원 할인', NULL, 'leisure',
   'est', NULL, TRUE, '국내외 계약 호텔 직원 할인 (지속가능경영 페이지 임직원 복리후생 여가 지원 항목) — 할인율·계약 호텔 미기재', 52),

  -- ── 근무 유연성 (flexibility) — 지속가능경영 페이지 임직원 복리후생 자율성 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '시차 출퇴근제 (지속가능경영 페이지 임직원 복리후생 자율성 항목), 유연근무제 활용 · 시차출퇴근제 사용자 수 230명 (2026 반기보고서 유연근무제 사용 현황 항목, 2026년 6월 30일 기준) — 적용 대상·출퇴근 시간대 미기재', 60),

  -- ── 보상 (compensation) — 지속가능경영 페이지 임직원 복리후생 가족친화 생활 지원 · 2026 반기보고서 주석 ──
  (@comp_id, 'holiday_gift', '명절 선물', NULL, 'compensation',
   'est', NULL, TRUE, '명절 선물 제공 (지속가능경영 페이지 임직원 복리후생 가족친화 생활 지원 항목) — 선물 품목·금액 미기재', 70),
  (@comp_id, 'stock_option', '우리사주 제도', NULL, 'compensation',
   'est', NULL, TRUE, '우리사주 제도 (지속가능경영 페이지 임직원 복리후생 가족친화 생활 지원 항목), 우리사주조합의 우리사주 취득 목적을 위한 차입금과 관련한 회사의 연대보증채무 부담 및 예금 담보 제공 (2026 반기보고서 재무제표 주석 우발 및 약정사항 항목) — 회사 출연 여부·지원 규모 미기재', 71),

  -- ── 휴가 (time_off) — 지속가능경영 페이지 임직원 복리후생 가족친화 생활 지원 ──
  (@comp_id, 'leave_general', '주거 이전 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '주거 이전 휴가 (지속가능경영 페이지 임직원 복리후생 가족친화 생활 지원 항목) — 휴가 일수·유급 여부 미기재', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
