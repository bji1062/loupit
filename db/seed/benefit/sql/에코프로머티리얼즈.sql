-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 에코프로머티리얼즈 복리후생 데이터 (신규 회사 — 웨이브 10)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.ecopromaterials.com/sub0104
-- badge: est
--
-- 참고:
--   정본은 상장 법인 주식회사 에코프로머티리얼즈(DART 종목명 에코프로머티 · 2023-11 상장)의 자기 도메인
--   www.ecopromaterials.com 회사소개 → 복리후생 페이지(/sub0104)다. 서버 렌더 HTML 에 5구역
--   (금전적 지원 3 · 생활안정 지원 4 · 기타 지원 4 · 여가활동 지원 4 · 건강증진 지원 1) 16줄이 그대로 있다 — 헤드리스 렌더 없음.
--   구역 사진 5장은 글자 없는 사진. 꼬리말 = 주식회사 에코프로머티리얼즈(포항) · Copyright ECOPROMATERIALS.
--   보조 출처:
--     같은 도메인 뉴스와 공지(회사 자기 게시판) 4건 — 2024-12-22 일 생활 균형 우수기업(시차출퇴근 · 플러스 휴가) ·
--     2024-09-06 일자리 으뜸기업(운영직 평가급 · 사무직 학위과정) · 2023-11-08 우리 사주 청약 · 2025-09-12 사내 축구동호회.
--     네 기사 모두 이 법인이 주어인 문단만 썼다.
--     OpenDART 2026 반기보고서(접수 20260814001623) 유연근무제도 사용 현황 · 주식 소유 현황 · 연결 주석(우리사주 담보대출 보증금),
--     2025 사업보고서 기재정정(접수 20260320000475) 재무제표 주석 장기종업원급여. 직원 573명(2026-06 · 1,000인 미만).
--     에코프로 그룹 채용 사이트 ecoprorecruit.co.kr 복지제도 페이지(운영 주체 주식회사 에코프로 · 채용공고 회사명 필터에
--     에코프로머티리얼즈가 있다) — 법인 페이지에 없는 4항목(복지포인트 · 어린이집 · 의료비 · 상담 서비스)만 각주 (그룹 통합 채용 기준).
--     지속가능경영보고서 2023~2025 는 robots 금지 경로(/utility-files)라 받지 않았다.
--   귀속: 형제 에코프로(지주 /sub0502) · 에코프로비엠(/sub0107)과 같은 틀의 목록이다. 이 법인 페이지에 있는 문장만 법인 원문으로 썼다
--     (형제와 갈리는 줄 = 생일 상품권 있음 · 발달장애 특수교육비 · 난임 시술 · 의료비가 법인 목록에 없음).
--     주어가 에코프로인 기사(2026-03-06 여성 존중 경영 · 2022-08-04 공동복지기금사업단)는 이 법인 적용을 밝히지 않아 행 근거로 쓰지 않았다.
--   금액: 원문 원 단위 금액 0 — meal 1행만 식대 식(하루 2끼 576 추정). 평가급 최대 월 20만원은 한도라 NULL. 타사 틀 값 없음.
--   제외: 법정(연차 휴가) · 사우회 운영(내용 미기재) · 임원 보수 칸(명절상여 · 하계휴가비 · 장기근속상금 · 장기근속수당) ·
--     주식매수선택권 · RSU · 그룹 채용 사이트 중 법인 목록과 겹치거나 내용 없는 라벨(주거지원금 · 자녀학자금 · 경조사 · 여가지원 · 동호회 지원 ·
--     건강증진 프로그램 · 기념일 축하) · 공시 선택근무제 · 원격근무제(세 기간 사용자 0 · 활용 여부 칸에 시차출퇴근제만).
--   공고 근거 0행 / 전체 24행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(compensation 10 · perks 20 · family 30 · health 40 · leisure 50),
--     보조 출처에만 있는 flexibility 60 · time_off 70 · growth 80.
-- 검증 · 감사 판정 반영(2026-10-15): 행 조치 없음 · 플러스 휴가 서술의 본인 휴가는 원문 개인연차를 낱말 규칙대로 바꾼 것(뜻 같음 · 회사가 더 주는 3일) · 그룹 채용 사이트 근거 4행의 그룹 통합 채용 기준 각주 유지 · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 24행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('ecopro_materials', '에코프로머티리얼즈',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '배터리소재', 'E', 'https://www.ecopromaterials.com/sub0104');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'ecopro_materials');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.ecopromaterials.com/sub0104'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) — 복리후생 금전적 지원 · 생활안정 지원 · 기타 지원 / 뉴스 · 공시 ──
  (@comp_id, 'bonus', '특별상여 (연간 3회)', NULL, 'compensation',
   'est', NULL, TRUE, '특별상여 연간 3회 (공식 홈페이지 회사소개 복리후생 금전적 지원 항목) — 지급 기준·지급률 미기재', 10),
  (@comp_id, 'incentive', '평가급 (운영직)', NULL, 'compensation',
   'est', NULL, TRUE, '운영직 평가급 지급, 최대 월 20만원 (공식 홈페이지 회사소개 복리후생 금전적 지원 항목), 운영직 평가제도를 개편해 객관화된 정량지표에 따라 평가급 지급 (공식 홈페이지 뉴스 2024-09-06 일자리 으뜸기업 기사 항목) — 실제 지급액 미기재', 11),
  (@comp_id, 'profit_sharing', '성과급 (Profit Sharing)', NULL, 'compensation',
   'est', NULL, TRUE, '성과급 지급, Profit Sharing (공식 홈페이지 회사소개 복리후생 금전적 지원 항목) — 지급 기준·지급률 미기재', 12),
  (@comp_id, 'severance_plus', '퇴직금 누진제도', NULL, 'compensation',
   'est', NULL, TRUE, '퇴직금 누진제도 (공식 홈페이지 회사소개 복리후생 생활안정 지원 항목) — 누진 방식·적용 조건 미기재', 13),
  (@comp_id, 'long_service_bonus', '장기근속자 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속자 포상 (공식 홈페이지 회사소개 복리후생 기타 지원 항목), 장기 근속 임직원에게 장기종업원급여 제공, 주로 10년 이상 근무한 임직원 대상 (2025 사업보고서 재무제표 주석 종업원급여 항목) — 근속 구간·포상 내용 미기재', 14),
  (@comp_id, 'excellence_award', '우수사원 포상', NULL, 'compensation',
   'est', NULL, TRUE, '우수사원 포상 (공식 홈페이지 회사소개 복리후생 기타 지원 항목) — 선정 기준·포상 내용 미기재', 15),
  (@comp_id, 'stock_option', '우리사주조합', NULL, 'compensation',
   'est', NULL, TRUE, '임직원 대상 공모주 청약에서 우리사주조합 몫 배정 물량 청약률 100% (공식 홈페이지 뉴스 2023-11-08 우리 사주 청약 기사 항목), 우리사주 담보대출 보증금 (2026 반기보고서 연결재무제표 주석 사용이 제한된 금융자산 항목) — 가입 조건·회사 출연 여부 미기재', 16),

  -- ── 경제적 부가혜택 (perks) — 복리후생 생활안정 지원 · 기타 지원 · 여가활동 지원 / 그룹 채용 사이트 ──
  (@comp_id, 'relocation', '사택 또는 정착지원금', NULL, 'perks',
   'est', NULL, TRUE, '사택 또는 정착지원금 지급 (공식 홈페이지 회사소개 복리후생 생활안정 지원 항목) — 지급 대상·지원 금액 미기재', 20),
  (@comp_id, 'meal', '구내식당 (중식·석식)', 576, 'perks',
   'est', '구내식당 운영, 중식·석식 제공 (공식 홈페이지 회사소개 복리후생 기타 지원 항목) — 1식 단가·본인 부담 미기재 (하루 2끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 21),
  (@comp_id, 'birthday_gift', '생일 상품권', NULL, 'perks',
   'est', NULL, TRUE, '근로자 생일 상품권 (공식 홈페이지 회사소개 복리후생 기타 지원 항목) — 상품권 금액 미기재', 22),
  (@comp_id, 'discount', '제휴업체 직원 할인', NULL, 'perks',
   'est', NULL, TRUE, '제휴업체 직원 할인 (공식 홈페이지 회사소개 복리후생 여가활동 지원 항목) — 제휴처·할인율 미기재', 23),
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '복지포인트 (에코프로 채용 사이트 복지제도 항목), 공동근로복지기금협의회를 통한 복지포인트 지원 (같은 페이지 공동복지기금사업단 운영 항목) — 연간 배정액 미기재 (그룹 통합 채용 기준)', 24),

  -- ── 가족·돌봄 (family) — 복리후생 생활안정 지원 / 그룹 채용 사이트 ──
  (@comp_id, 'event', '경조사 지원 (장례용품 포함)', NULL, 'family',
   'est', NULL, TRUE, '각종 경조사 지원, 장례용품 포함 (공식 홈페이지 회사소개 복리후생 생활안정 지원 항목) — 경조 종류별 금액·휴가 일수 미기재', 30),
  (@comp_id, 'child_edu', '학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '학자금 지원 (공식 홈페이지 회사소개 복리후생 생활안정 지원 항목) — 지원 대상·학교급·한도 미기재', 31),
  (@comp_id, 'childcare', '어린이집', NULL, 'family',
   'est', NULL, TRUE, '어린이집 (에코프로 채용 사이트 복지제도 항목) — 위치·정원·이용 사업장 미기재 (그룹 통합 채용 기준)', 32),

  -- ── 건강·의료 (health) — 복리후생 기타 지원 · 건강증진 지원 / 그룹 채용 사이트 ──
  (@comp_id, 'fitness', '부대시설 (헬스장·당구장·탁구장)', NULL, 'health',
   'est', NULL, TRUE, '부대시설 운영, 헬스장·당구장·탁구장 등 (공식 홈페이지 회사소개 복리후생 기타 지원 항목) — 위치·이용 조건 미기재', 40),
  (@comp_id, 'health_check', '종합건강검진', NULL, 'health',
   'est', NULL, TRUE, '종합건강 검진 (공식 홈페이지 회사소개 복리후생 건강증진 지원 항목) — 검진 주기·대상·비용 지원 범위 미기재', 41),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '의료비 (에코프로 채용 사이트 복지제도 항목), 공동근로복지기금협의회를 통한 의료비 지원 (같은 페이지 공동복지기금사업단 운영 항목) — 지원 대상·한도 미기재 (그룹 통합 채용 기준)', 42),
  (@comp_id, 'mental', '상담 서비스', NULL, 'health',
   'est', NULL, TRUE, '업무 외에도 신체 및 정신 건강을 위한 상담 서비스 등의 지원 (에코프로 채용 사이트 복지제도 일과 삶의 균형 항목) — 상담 기관·이용 횟수 미기재 (그룹 통합 채용 기준)', 43),

  -- ── 여가·라이프 (leisure) — 복리후생 여가활동 지원 / 뉴스 ──
  (@comp_id, 'resort', '휴양시설', NULL, 'leisure',
   'est', NULL, TRUE, '휴양시설 운영 (공식 홈페이지 회사소개 복리후생 여가활동 지원 항목) — 시설 위치·이용 횟수·비용 부담 미기재', 50),
  (@comp_id, 'club', '사내동호회 운영·지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내동호회 운영·지원 (공식 홈페이지 회사소개 복리후생 여가활동 지원 항목), 직원들로 구성된 사내 축구동호회 에코프로머티FC (공식 홈페이지 뉴스 2025-09-12 축구동호회 기사 항목) — 동호회 수·활동비 금액 미기재', 51),

  -- ── 근무 유연성 (flexibility) — 뉴스 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '시차 출퇴근제를 도입해 유연 근무 활성화 (공식 홈페이지 뉴스 2024-12-22 일·생활 균형 우수기업 기사 항목), 유연근무제 활용 여부 시차출퇴근제 활용 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 출퇴근 시간대·대상 직무 미기재', 60),

  -- ── 휴가 (time_off) — 뉴스 ──
  (@comp_id, 'refresh_leave', '플러스 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '본인 휴가를 100% 사용하면 유급휴가 3일을 추가하는 플러스 휴가 제도 (공식 홈페이지 뉴스 2024-12-22 일·생활 균형 우수기업 기사 항목) — 사용 시기·이월 여부 미기재', 70),

  -- ── 성장·교육 (growth) — 뉴스 ──
  (@comp_id, 'mba', '인재개발 학위과정 (사무직)', NULL, 'growth',
   'est', NULL, TRUE, '사무직 인재개발 학위과정 시행, 직무 관련 학위과정 비용 지원 (공식 홈페이지 뉴스 2024-09-06 일자리 으뜸기업 기사 항목) — 선발 기준·지원 한도 미기재', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
