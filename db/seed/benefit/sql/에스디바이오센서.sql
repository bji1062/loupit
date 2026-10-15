-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 에스디바이오센서 복리후생 데이터 (신규 회사 — 웨이브 8)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.sdbiosensor.com/company/esg
-- badge: est
--
-- 참고:
--   정본은 상장 법인 에스디바이오센서(주)의 자기 도메인 www.sdbiosensor.com ABOUT US > ESG management 페이지다.
--   SSR 이고 이 페이지가 2026 지속가능경영보고서 국문 PDF(/link/download/2026_ESG.Report_KR.pdf)를 건다.
--   행의 근거는 그 보고서다(법인 단독 발행 · 파일 생성 2026-06-30 · 보고 기간 2025-01-01~2025-12-31 ·
--   보고 범위 별도 법인 에스디바이오센서의 국내 사업장(수원 본사 · 증평공장 · 오송공장 등)) —
--   24쪽 복지 프로그램 표 · 일과 삶의 균형, 25쪽 보상 정책, 26쪽 뱃지 제도 · 내부 이동, 27쪽 교육 체계, 34쪽 건강 증진.
--   공시 보조: OpenDART 2026 반기보고서(접수 20260814002250) 유연근무제도 사용 현황 주석(시차출퇴근제).
--   직원 656명(2025 사업보고서 직원 현황 합계) — 1,000인 미만.
--   귀속: 보고서 문장 주어가 에스디바이오센서 단수이고 보고 범위가 이 법인 하나라 각주 없음.
--   해외 자회사(Meridian Bioscience 등) 문장과 연결 기준 숫자는 쓰지 않았다. 기등록 형제 없음.
--   자기 도메인 /recruit/hmr 채용 페이지에도 보상 복리후생 표가 있으나 헤더 메뉴 링크가 주석 처리돼 있어
--   공개 원문으로 쓰지 않았다(근거표 판단 요청). 채용 ATS 복리후생 페이지는 본문이 벤더 API 호스트에만 있다.
--   금액: stated 1행(복지포인트 연 130만 원) · 추정 2행(식대 하루 3끼 식 864 · 동호회 월 1만 원 환산 12) · 나머지 NULL.
--   제외: 법정(4대보험 · 퇴직연금 · 육아휴직 · 일반 및 특수건강검진 · 연장근무 수당) · 업무 교육(입문 · 세미 OJT ·
--     직무 · 리더십 · 생성형 AI · Tech Class · 사내강사) · 임원 전용(화상영어 · 임원 리더십) · RSU 재량 부여 ·
--     검토 단계(특별 보너스 · 주식매입 기회) · 안전 포상제 · 타운홀미팅.
--   공고 근거 0행 / 전체 18행.
--   SORT 섹션 순서 = 보고서 등장 순(perks 10 · health 20 · family 30 · leisure 40 · flexibility 50 ·
--     compensation 60 · growth 70).
-- 검증 · 감사 판정 반영(2026-10-15): 행 조치 없음 · 항목 페이지 예외 2(통합 밖 리드 집행) — 최종 18행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('sd_biosensor', '에스디바이오센서',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '의료기기', 'S', 'https://www.sdbiosensor.com/company/esg');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'sd_biosensor');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.sdbiosensor.com/company/esg'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 생활 · 금융 · 주거 (perks) — 보고서 24쪽 복지 프로그램 표 ──
  (@comp_id, 'welfare_point', '복지포인트', 130, 'perks',
   'est', '연 130만 원의 Point 지급 (분기별 30만, 생일 10만) (2026 지속가능경영보고서 24쪽 복지 프로그램 표 복지포인트 항목)', FALSE, NULL, 10),
  (@comp_id, 'housing_loan', '사내대출 (주택마련)', NULL, 'perks',
   'est', NULL, TRUE, '사내대출(주택마련) 매매 8천만 원(최대 6년) / 임차 6천만 원(최대 4년), 저금리 지원 (2026 지속가능경영보고서 24쪽 복지 프로그램 표 사내대출(주택마련) 항목) — 이율·대상 요건 미기재', 11),
  (@comp_id, 'relocation', '숙소(월세) 지원 (발령·근무지 변경 시)', NULL, 'perks',
   'est', NULL, TRUE, '인사발령 및 근무지 변경 시 2년간 월세 지원 (직급별 40~70만 원) (2026 지속가능경영보고서 24쪽 복지 프로그램 표 숙소(월세) 지원 항목) — 금액 지급 단위·거리 요건 미기재', 12),
  (@comp_id, 'meal', '식사 지원 (조식·중식·석식)', 864, 'perks',
   'est', '조식·중식·석식 제공 (구내식당, 식권대장, 법인카드 등) (2026 지속가능경영보고서 24쪽 복지 프로그램 표 식사 지원 항목) (하루 3끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 13),
  -- ── 건강 (health) — 보고서 24쪽 복지 프로그램 표 · 34쪽 건강 증진 ──
  (@comp_id, 'health_check', '종합건강검진 지원·독감예방접종 지원', NULL, 'health',
   'est', NULL, TRUE, '연나이 35세 이상 임직원 대상 종합건강검진 지원, 「착한의사」 APP 포인트 지급 (2026 지속가능경영보고서 24쪽 복지 프로그램 표 종합건강검진 지원 항목), 독감예방접종 지원 임직원 전체 대상, 최대 4만 원 지원 (독감예방접종 지원 항목) — 검진 주기·포인트 금액 미기재', 20),
  (@comp_id, 'medical', '헬스케어 지원 (34세 이하)', NULL, 'health',
   'est', NULL, TRUE, '연나이 34세 이하 임직원 대상, 연 10만 원 (운동·치료·검진비) (2026 지속가능경영보고서 24쪽 복지 프로그램 표 헬스케어 지원 항목), 만 34세 이하 임직원에게 연 10만 원 한도의 헬스케어 비용 지원 (34쪽 건강검진 및 건강 증진 프로그램 항목) — 신청 방식 미기재', 21),
  (@comp_id, 'mental', '직무스트레스 측정·상담', NULL, 'health',
   'est', NULL, TRUE, '보건관리대행업체를 통해 직무스트레스를 측정하고 상담 제공 (2026 지속가능경영보고서 34쪽 건강검진 및 건강 증진 프로그램 항목) — 상담 횟수·대상 미기재', 22),
  -- ── 가족 (family) — 보고서 24쪽 복지 프로그램 표 ──
  (@comp_id, 'fertility_support', '난임시술·치료비 지원', NULL, 'family',
   'est', NULL, TRUE, '난임시술/치료비 본인부담 실비 지원, 최대 100만원 (2026 지속가능경영보고서 24쪽 복지 프로그램 표 난임시술/치료비 지원 항목) — 지원 횟수·대상 요건 미기재', 30),
  (@comp_id, 'event', '결혼 축하금·부모 기념연령 축하금·조사 지원', NULL, 'family',
   'est', NULL, TRUE, '결혼 축하금 본인 100만 원 / 자녀 30만 원 / 형제자매 10만 원, 부모 기념연령 축하금 회갑 30만 원 / 칠순·팔순 10만 원, 조사 지원 본인·배우자 100만 원 / 부모·자녀 30만 원 / 형제자매 20만 원 등 (2026 지속가능경영보고서 24쪽 복지 프로그램 표 경조사 지원 항목)', 31),
  (@comp_id, 'parenting', '출산 축하금·자녀돌 축하금·자녀 입학 축하금', NULL, 'family',
   'est', NULL, TRUE, '출산 축하금 첫째 100만 원 / 둘째 이상 150만 원, 자녀돌 축하금 자녀당 1회 20만 원, 자녀 입학 축하금 8세 미만 30만 원 / 초·중·고 각 30만 원 / 대학 100만 원 (2026 지속가능경영보고서 24쪽 복지 프로그램 표 경조사 지원 항목)', 32),
  -- ── 여가 (leisure) — 보고서 24쪽 복지 프로그램 표 ──
  (@comp_id, 'club', '동호회 지원', 12, 'leisure',
   'est', '매월 활동비 지원(1만 원/명), 우수 동호회 분기별 포상 (2026 지속가능경영보고서 24쪽 복지 프로그램 표 동호회 지원 항목) — 월 1만원을 연 12만원으로 환산', FALSE, NULL, 40),
  (@comp_id, 'resort', '휴양숙소 지원', NULL, 'leisure',
   'est', NULL, TRUE, '휴양숙소 연 2박 이용 가능 (성수기 별도) (2026 지속가능경영보고서 24쪽 복지 프로그램 표 휴양숙소 지원 항목) — 숙소 위치·비용 부담 미기재', 41),
  -- ── 근무 유연성 (flexibility) — 보고서 24쪽 일과 삶의 균형 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '시차출퇴근제(8~10시)를 통해 육아, 교육, 치료 등 개인 사정이 있는 임직원이 근무 시간을 유연하게 조정 (2026 지속가능경영보고서 24쪽 일과 삶의 균형 항목), 2025년부터 유연근무제도를 도입하여 임직원이 시차출퇴근제를 활용할 수 있도록 운영 (2026 반기보고서 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 50),
  -- ── 보상 (compensation) — 보고서 25 · 26쪽 ──
  (@comp_id, 'long_service_bonus', '장기근속자 보상', NULL, 'compensation',
   'est', NULL, TRUE, '장기 근속자 보상 프로그램 운영 및 추가 인센티브 지급 (2026 지속가능경영보고서 25쪽 보상 정책 및 운영 방안 항목) — 근속 기준·급부 형태·금액 미기재', 60),
  (@comp_id, 'excellence_award', '뱃지 제도·연말 포상', NULL, 'compensation',
   'est', NULL, TRUE, '협업, 참여, 지식 공유 등 다양한 기여도에 따라 뱃지 부여, 뱃지 적립에 따른 포인트 시스템 운영 및 인센티브 제공, 우수 직원에게 연말 포상 및 특별 혜택 부여 (2026 지속가능경영보고서 26쪽 뱃지 제도 항목) — 포인트 단가·포상 내용 미기재', 61),
  -- ── 성장 · 교육 (growth) — 보고서 26 · 27쪽 ──
  (@comp_id, 'career', '커리어무브 제도', NULL, 'growth',
   'est', NULL, TRUE, '사내 직무 이동 제도인 커리어무브 제도 운영, 커리어무브 포털을 통해 개인의 직무 이동 희망 접수, 이동 인원에게 필요한 교육 지원 및 승진 포인트 가점 부여 (2026 지속가능경영보고서 26쪽 승진 제도 및 내부 이동 지원 항목) — 신청 자격·이동 주기 미기재', 70),
  (@comp_id, 'lang', '전화영어·제2외국어 과정', NULL, 'growth',
   'est', NULL, TRUE, '상시교육 전화영어 과정 (2026 지속가능경영보고서 27쪽 2025 교육 실적 및 인프라 표 상시교육 항목), 글로벌화 과정 전화영어·제2외국어 (27쪽 교육 체계도 Global Leaders College 항목) — 수강 대상·비용 부담 미기재', 71),
  (@comp_id, 'edu_support', '명사 특강·SD Learning Center 이러닝', NULL, 'growth',
   'est', NULL, TRUE, '명사 특강 등 교육 커리큘럼 운영 (2026 지속가능경영보고서 27쪽 교육 체계 항목), 상시교육 SD Learning Center 이러닝 플랫폼 (27쪽 2025 교육 실적 및 인프라 표 상시교육 항목) — 수강 대상·강좌 구성 미기재', 72)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
