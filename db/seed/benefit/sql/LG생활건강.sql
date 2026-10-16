-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LG생활건강 복리후생 데이터 (신규 회사 — 웨이브 11)
-- 출처: AI 파싱 (2026-10-16)
-- URL: https://www.lghnh.com/recruit/system/welfare.jsp
-- badge: est
--
-- 참고:
--   정본 = 자기 도메인 인재채용 인사제도 복리후생 페이지(www.lghnh.com/recruit/system/welfare.jsp).
--   robots 가 User-agent * 에 Disallow / 라 본문은 요청하지 않았다 — 사용자가 브라우저로 연 화면을 붙여 넣은 사본
--   (W/lg_hnh/user_paste_welfare.txt · sha256 fc829729…ced8)으로 수집. 정본 주소는 검색 결과 제목
--   채용정보 > 인사제도 > 복리후생 으로 확인(본문 미요청) · 점검기는 robots(점검 안 함).
--   보조 = OpenDART 2026 반기보고서(접수 20260814002412) 직원 등 현황 유연근무제도 사용 현황 표(웨이브 7 사본).
--   렌더 = 사용자 붙여넣기(탭 이름 줄 아래 항목이 순서대로 놓인 화면 — 탭과 항목을 순서로 짝지음).
--   귀속 = 자기 도메인 페이지 · 주어 그룹 아님 → 각주 없음. LG Family카드 · LG라이프케어 포털은 LG 계열 공통 수단일 수 있으나
--   이 법인 페이지의 그룹제품구입지원 항목으로 실린 문장이라 그대로 싣는다(형제 7사 정본 문장과 글자 일치 없음).
--   금액 행 0(원문에 금액 없음 · 식대 끼니 미기재).
--   제외 = 정기건강진단(사무직 2년 1회 · 기타직 년 1회 — 법정 주기) · 임신기 단축근무 · 육아휴직 · 육아기 단축 근무(법정) ·
--   각종 휴가제도 운영(이름 없음) · 공시 선택근무제 · 원격근무제 사용자 수(4개 기간 모두 -).
--   공고 근거 0행 / 전체 24행 · SORT 섹션 순서 = perks · family · health · compensation · growth · flexibility · time_off · leisure
-- 검증 · 감사 판정 반영(2026-10-16): 그룹제품구입지원 discount 서술 앞에 화면 탭 이름 그룹제품구입지원을 살림(새 낱말 0) · 참고 블록의 형제 7사 정본 문장과 글자 일치 없음은 이 판정으로 뒤집힘(LG에너지솔루션 시드와 같은 구절 3 — 자기 도메인 원문이라 각주 없음) · 항목 페이지 예외 3(통합 밖 리드 집행) — 최종 24행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('lg_hnh', 'LG생활건강',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '화장품', 'L', 'https://www.lghnh.com/recruit/system/welfare.jsp');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lg_hnh');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.lghnh.com/recruit/system/welfare.jsp'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 생활 · 금융 · 주거 (perks) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'housing_loan', '주택구입자금·전세자금 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택구입자금 및 전세자금 지원 (공식 채용 페이지 복리후생 주거 지원 항목) — 지원 방식·한도·대상 미기재', 10),
  (@comp_id, 'housing_support', '지방영업근무자 임차 보증금 지원', NULL, 'perks',
   'est', NULL, TRUE, '지방영업근무자 임차 보증금 지원 (공식 채용 페이지 복리후생 주거 지원 항목) — 지원 방식·금액 미기재', 11),
  (@comp_id, 'discount', '그룹제품구입지원 (LG Family카드·임직원몰)', NULL, 'perks',
   'est', NULL, TRUE, '그룹제품구입지원, LG Family카드로 자매사 제품 구입시 할인지원, LG라이프케어 포털 이용, LG생활건강 임직원몰 이용 (공식 채용 페이지 복리후생 항목) — 할인율·구매 한도 미기재', 12),
  (@comp_id, 'welfare_point', '선택적 복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '선택적 복지포인트 지급 (공식 채용 페이지 복리후생 복지포인트 지급 항목) — 지급 금액·사용처 미기재', 13),
  (@comp_id, 'meal', '사내식당 운영·식대 지원', NULL, 'perks',
   'est', NULL, TRUE, '각 사업장 별 사내식당 운영 및 식대 지원 (공식 채용 페이지 복리후생 사내식당운영 항목) — 제공 끼니·식대 금액 미기재', 14),
  (@comp_id, 'transport', '영업사원 차량운영비 지급', NULL, 'perks',
   'est', NULL, TRUE, '영업사원 차량운영비 지급 (공식 채용 페이지 복리후생 교통비지원 항목) — 지급 금액·기준 미기재', 15),
  (@comp_id, 'telecom', '영업사원 통신비 지급', NULL, 'perks',
   'est', NULL, TRUE, '영업사원 통신비 지급 (공식 채용 페이지 복리후생 교통비지원 항목) — 지급 금액·기준 미기재', 16),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '사업장별 통근버스 운행 (공식 채용 페이지 복리후생 교통비지원 항목) — 운행 사업장·노선 미기재', 17),
  -- ── 가족 (family) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'event', '경조금·경조휴가', NULL, 'family',
   'est', NULL, TRUE, '본인/가족 각종 경조사 시 경조금 및 경조 휴가 부여, 화환 및 장례용품 지원 (공식 채용 페이지 복리후생 경조금 지원 항목) — 경조금 금액·휴가 일수 미기재', 20),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '고등학교, 대학교 취학자녀 학자금 지원, 자녀 수 제한 없음 (공식 채용 페이지 복리후생 학자금 지원 항목) — 지원 한도·범위 미기재', 21),
  (@comp_id, 'parenting', '자녀 입학 축하·임신 관련 질병 휴직/휴가', NULL, 'family',
   'est', NULL, TRUE, '입학축하선물, 초/중/고 입학시 입학축하 노트북 지원, 유치원 입학시 입학축하금 지원 (공식 채용 페이지 복리후생 학자금 지원 항목), 임신 관련 질병 휴직/휴가 지원 (공식 채용 페이지 복리후생 임신/육아 지원 항목) — 축하금 금액·휴직 기간·유급 여부 미기재', 22),
  (@comp_id, 'fertility_support', '난임치료 지원', NULL, 'family',
   'est', NULL, TRUE, '난임치료 지원 (공식 채용 페이지 복리후생 임신/육아 지원 항목) — 지원 내용·휴가 일수·금액 미기재', 23),
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '직장 어린이집 운영 (공식 채용 페이지 복리후생 임신/육아 지원 항목) — 운영 사업장·정원 미기재', 24),
  -- ── 건강 (health) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'medical', '단체 실손 보험 (본인·배우자·자녀)', NULL, 'health',
   'est', NULL, TRUE, '단체 실손 보험 지원, 본인, 배우자 및 자녀 포함 (공식 채용 페이지 복리후생 의료비 지원 항목) — 보장 한도·자기부담 미기재', 30),
  (@comp_id, 'health_check', '종합건강진단 (만 35세 이상 또는 근속 5년 이상)', NULL, 'health',
   'est', NULL, TRUE, '종합건강진단 지원, 만 35세 이상 또는 근속 5년 이상 (공식 채용 페이지 복리후생 종합건강진단 지원 항목) — 검진 주기·비용 지원 범위 미기재', 31),
  (@comp_id, 'insurance', '단체정기 보험', NULL, 'health',
   'est', NULL, TRUE, '단체정기 보험 지원, 사고, 질병 발생시 보장 (공식 채용 페이지 복리후생 단체정기 보험 지원 항목) — 보장 금액·가입 대상 미기재', 32),
  (@comp_id, 'fitness', '체력단련시설·스포츠센터 제휴', NULL, 'health',
   'est', NULL, TRUE, '체력단련시설 및 스포츠센터 제휴 (공식 채용 페이지 복리후생 개인여가활동 지원 항목) — 시설 위치·이용 조건 미기재', 33),
  -- ── 보상 (compensation) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'long_service_bonus', '장기근속자 포상·여행 지원', NULL, 'compensation',
   'est', NULL, TRUE, '장기 근속자 포상 및 여행 지원, 20년 장기근속 시 부부동반 해외여행 (공식 채용 페이지 복리후생 장기근속자 포상 항목) — 포상 근속 기준·포상 내용 미기재', 40),
  -- ── 성장 (growth) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'retirement_support', '정년 시 부부동반 해외여행', NULL, 'growth',
   'est', NULL, TRUE, '정년 시 부부동반 해외여행 (공식 채용 페이지 복리후생 장기근속자 포상 항목) — 여행 기간·지원 범위 미기재', 50),
  -- ── 근무 유연성 (flexibility) — 공식 채용 페이지 복리후생 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', 'Flexible Time제', NULL, 'flexibility',
   'est', NULL, TRUE, 'Flexible Time제 운영, 출/퇴근시간 자율 선택제 (공식 채용 페이지 복리후생 휴가제도 항목), 시차출퇴근제 사용자 2,499명 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 적용 대상·코어타임 미기재', 60),
  -- ── 휴가 (time_off) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'leave_general', '반반일 휴가제', NULL, 'time_off',
   'est', NULL, TRUE, '반반일 휴가제 실시 (공식 채용 페이지 복리후생 휴가제도 항목) — 사용 단위 시간·사용 조건 미기재', 70),
  (@comp_id, 'summer_leave', '하계휴가 5일', NULL, 'time_off',
   'est', NULL, TRUE, '하계휴가(5일) 운영 (공식 채용 페이지 복리후생 휴가제도 항목) — 본인 휴가 사용일인지·유급 여부 미기재', 71),
  -- ── 여가 (leisure) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'resort', '휴양시설 지원', NULL, 'leisure',
   'est', NULL, TRUE, '휴양시설지원, LG생활연수원·엘리시안 강촌·곤지암 리조트 (공식 채용 페이지 복리후생 개인여가활동 지원 항목) — 이용 횟수·비용 지원 범위 미기재', 80),
  (@comp_id, 'sports_ticket', 'LG트윈스·FC서울 관람권', NULL, 'leisure',
   'est', NULL, TRUE, '서울 연고 LG트윈스, FC서울 관람권 지원 (공식 채용 페이지 복리후생 개인여가활동 지원 항목) — 지원 매수·신청 방식 미기재', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
