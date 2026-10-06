-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 네패스 복리후생 데이터
-- 출처: AI 파싱 (2026-10-01)
-- URL: https://www.nepes.co.kr/kr/recruit/welfare.php
-- badge: est
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 참고:
--   정본 = 네패스 공식 홈페이지 CAREERS > 인사제도 > 복리후생 (www.nepes.co.kr, 법인 자기 도메인 · GNB 메뉴).
--     서버 렌더 PHP 본문에 3개 묶음(즐거운 회사생활 8 · 안정된 가정생활 5 · 신나는 여가생활 4) 카드 17개가 있다(헤드리스 불필요).
--     복지 본문 구간에 HTML 주석 없음. 배너 사진 3장은 글자 없는 사진이다. robots.txt = /gsadmin/ · /lib/ · /webeditor/ 만 금지(2026-10-01 확인).
--   보조 = 같은 도메인 채용 FAQ 회사생활 항목(기숙사 · 통근버스 · 식사) · GNB 링크 ESG 리포트 2025-26 PDF(보고 범위 네패스 별도 · 국내 주요 사업장) p17 · p19 · p22.
--   귀속: 네패스아크 · 네패스야하드 · 네패스라웨 등 계열 법인은 자기 도메인이 따로 있다. 이 페이지와 리포트는 네패스 법인 기준이라 각주 없음.
--   법정 제도: 4대 보험 · 휴직 · 주 52시간 · 육아휴직 · 가족돌봄휴직 · 근로시간 단축은 싣지 않았다. 2시간 단위 휴가는 복지로 수록.
--     재취업지원 의무 대상(직원 1,200)이나 원문에 재취업지원 문구 없음.
--   금액: 원문 금액 0 · 구본 추정 승계 5(health_check 100 · child_edu 200 · resort 50 · commute_subsidy 120 · holiday_gift 20) ·
--     미승계(welfare_point 40 은 원문에 숫자 없음 · meal 432 는 원문 중식·석식 두 끼 · event 50 은 경조금).
--   재코딩 0 · 신규 코드 0. 구본에서 뺀 행 3(nap_room · fitness · edu_support — edu_support 는 2026-10-04 규칙 8 개정으로 E-learning · 독서 토론 · 교양 강좌 행으로 되살림). 구 leave_general 의 휴가 사용 촉진 제도는 빼고 같은 코드를 2시간 단위 휴가로 쓴다.
-- 재수집(2026-10-01): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-01, RV-3-2): 23행 전부 원문 확인 · 시드 조치 없음 · 법정 등록 2행 해제(birthday_leave 는 회사가 주는 반일 유급 휴가 · leave_general 은 휴가 사용 촉진 제도가 원문에 없고 같은 코드가 2시간 단위 휴가로 바뀜) — 최종 23행
-- 후속 정리 2(2026-10-04, R-3): 사용자가 정한 복지 범위 규칙 개정(규칙 8 · 기준 13 · 기준 18 · 기준 20 · 기준 23)과 코퍼스 판정을 반영 — 새 행 1(edu_support) · 서술 · 이름 수정 1(lang) — 최종 24행
-- 2026-10-06 식대 기준 금액 1끼 12,000원(리드 판정 (82)) — meal 행 금액 = 1끼 단가 × 끼니 × 연 240일, 꼬리에 식 공개

-- 1) 회사 등록 (기존 회사 — no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('nepes', '네패스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체패키징', 'N', 'https://www.nepes.co.kr/kr/recruit/welfare.php');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'nepes');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.nepes.co.kr/kr/recruit/welfare.php'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무유연성 (flexibility) ── 즐거운 회사생활 카드 1
  (@comp_id, 'flex_work', '시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '시차출퇴근제 운영 (공식 채용 페이지 복리후생 유연근무제 운영 항목)', 10),
  (@comp_id, 'remote_work', '재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '재택근무 운영 (공식 채용 페이지 복리후생 유연근무제 운영 항목) — 대상·일수 미기재', 11),

  -- ── 여가·라이프 (leisure) ── 즐거운 회사생활 카드 2·3 · 신나는 여가생활 휴양시설
  (@comp_id, 'club', '사내동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '음악·체육·종교 등 사내 동호회 지원 — 지원 금액 미기재', 20),
  (@comp_id, 'leisure_ticket', '음악관람 지원 (음악의 생활화)', NULL, 'leisure',
   'est', NULL, TRUE, '음악관람 지원, 음악교실 운영과 사내 음악 이벤트 행사 실시 (공식 채용 페이지 복리후생 음악의 생활화 항목) — 관람 지원 방식·횟수 미기재', 21),
  (@comp_id, 'resort', '휴양시설 숙박 지원', 50, 'leisure',
   'est', '호텔·콘도 및 휴양지 숙박 지원, 사내 연수원(호텔 웨스트오브가나안)과 리조트 (공식 채용 페이지 복리후생 휴양시설 항목 · ESG 리포트 2025-26 — 이용 횟수·지원 금액 미기재) (추정)', FALSE, NULL, 22),

  -- ── 경제적 부가혜택 (perks) ── 즐거운 회사생활 카드 6·7 · 기숙사 지원 카드 · ESG 리포트 생활 지원
  (@comp_id, 'commute_subsidy', '통근버스', 120, 'perks',
   'est', '청주·오창·증평·괴산 청안 등 통근버스 운행 (공식 채용 페이지 복리후생 출퇴근 지원 항목 — 노선 수·이용료 미기재) (추정)', FALSE, NULL, 30),
  (@comp_id, 'meal', '사내식당 중식·석식', 576, 'perks',
   'est', '사내식당에서 중식·석식 제공, 서울 근무자와 공장 외 근무자는 식비 별도 지급 — 식비 금액 미기재 (하루 2끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 31),
  (@comp_id, 'housing_support', '주거보조금', NULL, 'perks',
   'est', NULL, TRUE, '기숙사 또는 주거보조금 제공(서울·청주시 거주자 제외), 주거지원금 부분 지원 — 주거보조금 금액 미기재', 32),
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '복지포인트 제도 운영과 네패스 복지몰 (ESG 리포트 2025-26 복리후생 제도 항목) — 지급 금액 미기재', 33),
  (@comp_id, 'snack_bar', '사내 편의점·카페', NULL, 'perks',
   'est', NULL, TRUE, '사내 편의점과 사내 카페 운영 (ESG 리포트 2025-26 복리후생 제도 생활 지원 항목)', 34),

  -- ── 보상·금전 (compensation) ── 즐거운 회사생활 카드 8 · 신나는 여가생활 명절 선물
  (@comp_id, 'long_service_bonus', '장기근속자 포상', NULL, 'compensation',
   'est', NULL, TRUE, '근속 10년·20년·30년 장기근속자 포상 — 포상 내용 미기재', 40),
  (@comp_id, 'holiday_gift', '명절 선물', 20, 'compensation',
   'est', '설·추석 명절선물 지급 (공식 채용 페이지 복리후생 명절 선물 항목 — 선물 내용·금액 미기재) (추정)', FALSE, NULL, 41),

  -- ── 근무환경 (work_env) ── 안정된 가정생활 기숙사 지원 · 채용 FAQ 회사생활
  (@comp_id, 'dormitory', '기숙사 지원', NULL, 'work_env',
   'est', NULL, TRUE, '청주 외 지역 거주자에게 기숙사 제공, 원룸 2인 1실·아파트 1인 1실(거실·주방 공동), 서울·청주시 거주자 제외', 50),

  -- ── 가족·돌봄 (family) ── 안정된 가정생활 경조금 · 자녀 학자금 · ESG 리포트 생활 지원
  (@comp_id, 'event', '경조금 지원', NULL, 'family',
   'est', NULL, TRUE, '본인·가족 결혼, 회갑, 출산 등 각종 경조사 시 경조금, 화환과 경조휴가 제공 — 금액 미기재', 60),
  (@comp_id, 'child_edu', '자녀 학자금 지원', 200, 'family',
   'est', '중·고·대학생 자녀 학자금 지원 (공식 채용 페이지 복리후생 자녀 학자금 지원 항목 — 지원 한도·자녀 수 미기재) (추정)', FALSE, NULL, 61),
  (@comp_id, 'parenting', '자녀 입학 축하금', NULL, 'family',
   'est', NULL, TRUE, '자녀 초·중·고 입학 시 축하금 지급 — 금액 미기재', 62),
  (@comp_id, 'childcare', '직장어린이집', NULL, 'family',
   'est', NULL, TRUE, '직장어린이집 운영 (ESG 리포트 2025-26 복리후생 제도 생활 지원 항목) — 위치·정원 미기재', 63),

  -- ── 건강·의료 (health) ── 안정된 가정생활 건강검진 · ESG 리포트 의료 지원 · 임직원 심신 건강 프로그램
  (@comp_id, 'health_check', '종합건강검진', 100, 'health',
   'est', '1년 이상 근속자 매년 종합건강검진 지원, 만 35세 미만 기본검진과 선택검사, 만 35세 이상 기본검진과 정밀검진 (공식 채용 페이지 복리후생 임직원 건강검진 지원 항목 — 검진 비용 미기재) (추정)', FALSE, NULL, 70),
  (@comp_id, 'clinic', '사내 보건실', NULL, 'health',
   'est', NULL, TRUE, '사업장 내 보건실에서 일상 건강상담과 기초 건강관리 지원, 체성분측정기기 등 자가 건강점검 설비 (ESG 리포트 2025-26 임직원 심신 건강 프로그램 항목)', 71),
  (@comp_id, 'mental', '심리 상담 (사내 공감 부서)', NULL, 'health',
   'est', NULL, TRUE, '사내 공감 부서에서 스트레스·번아웃·심리적 어려움 상담과 케어 제공 (ESG 리포트 2025-26 마음건강 증진 항목)', 72),

  -- ── 성장·커리어 (growth) ── 신나는 여가생활 자기개발 지원
  (@comp_id, 'lang', '어학 수강료 지원·어학강좌', NULL, 'growth',
   'est', NULL, TRUE, '사외 어학 수강료 지원 (공식 채용 페이지 복리후생 자기개발 지원 항목), 어학강좌와 해외어학 연수 (복리후생 교육 지원 Global 인재 육성 항목), 사내어학집합교육 · 전화외국어/화상영어 · 국내/외 영어캠프 (공식 채용 페이지 인재양성 글로벌 인재 육성 교육 항목) — 지원 한도·참여 대상 미기재', 80),
  (@comp_id, 'edu_support', 'E-learning 교육·교양 강좌', NULL, 'growth',
   'est', NULL, TRUE, 'E-learning 교육 제공 (공식 채용 페이지 복리후생 자기개발 지원 항목), 독서몰입캠프 · 쉼 캠프와 미혼 직원 결혼예비학교 · 자녀를 둔 부모 대상 아버지학교 (공식 채용 페이지 인재양성 nepes way 교육 항목 · ESG 리포트 2025-26 20쪽) — 과정 분야·참여 대상 미기재', 81),

  -- ── 시간·휴가 (time_off) ── 신나는 여가생활 생일 휴가 · ESG 리포트 기타 제도
  (@comp_id, 'birthday_leave', '생일 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '생일자에게 반일 유급 휴가 제공', 90),
  (@comp_id, 'leave_general', '2시간 단위 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '2시간 단위 휴가 제도 운영 (ESG 리포트 2025-26 복리후생 제도 기타 제도 항목)', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
