-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 피에스케이 복리후생 데이터
-- 출처: AI 파싱 (2026-09-19)
-- URL: https://www.pskinc.com/esg/society_executives.php?lang=ko_KR
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
--
-- 참고:
--   정본은 상장 법인 피에스케이(KOSDAQ 319660) 자기 도메인 www.pskinc.com 의 국문 페이지 둘이다.
--     ① https://www.pskinc.com/esg/society_executives.php?lang=ko_KR
--        (GNB ESG > 사회 > 임직원 → 조직문화 「일과 삶의 균형」 21항목 5카테고리 + 인재양성·교육 프로그램 현황)
--     ② https://www.pskinc.com/career/career.php?lang=ko_KR
--        (GNB 채용 → 카드 What PSK Group offers 「복지」 VIEW MORE → 모달 careerModal3, 7카드 16불릿)
--   CAREERS_BENEFIT_URL 은 ①로 둔다 — 행 26개 중 21개의 1차 근거가 ①이라 이 칸의 쓰임(복지가 실제로
--   적힌 페이지)에 맞다. ②는 GNB 채용 진입점이며 5행의 근거다(사용자 결정 2026-09-20).
--   robots 는 www.pskinc.com 전면 허용(User-agent: * / Allow: / · 23B). 서버렌더 PHP 라 헤드리스 불필요.
--
--   🚨 귀속 — 전 행 QUAL_DESC 말미에 「(그룹 통합 채용 기준)」 각주를 달았다. 절대 떨구지 말 것.
--     페이지 자체는 법인별로 갈라져 있다: 노동/인권 방침 주어가 「피에스케이는」(지주는 「피에스케이홀딩스는」),
--     다양성 표 총근로자수 2025년 349명(지주 139명), 자발적 이직률 24명 7%(지주 3명 2%),
--     각주 「(*PSK㈜ 국내 HQ 기준)」, 푸터 info@pskinc.com · 저작권 PSK Inc.
--     그런데 복지 블록만 지주 pskholding.com 과 바이트 단위로 동일하다 — 이번 세션에서 두 사이트의
--     같은 국문 페이지를 각각 받아 직접 대조했고 모달 careerModal3 와 조직문화 「일과 삶의 균형」 블록,
--     그리고 인재양성·교육 프로그램 현황 블록까지 sha256 이 일치했다(evidence 에 해시 기록).
--     페이지 화법도 그룹 단위다(What PSK Group offers · 피에스케이그룹은…). 따라서 계약 규칙 6 의
--     그룹 통합 표기로 보고 전 행에 각주를 단다. 형제 법인 피에스케이홀딩스(031980)는 코퍼스 미등록이고
--     로스터에서 지주로 규칙 제외돼 있다 — 나중에 후보로 올라와도 이 회사 행을 복제하지 말 것.
--
--   ⚠ 함정 3개를 피했다.
--     1) ①은 데스크톱 section-container 와 모바일 section-container-mobile 에 같은 목록이 두 벌이다
--        (culture-section 블록 21+21). 라벨도 「주거 생활」/「주거생활」로 공백이 달라 그대로 세면 42로 부푼다.
--        데스크톱 한 벌만 채택했다.
--     2) ②는 Bootstrap 모달 안이라 가시 텍스트 추출기가 놓친다. 원본 HTML 에서 careerModal3 를 직접 파싱했다.
--     3) 국문/영문 값이 어긋난다(정착지원금 국문 편도 30km ↔ 영문 internal guidelines,
--        자기주도학습 국문 60시간 ↔ 영문 80시간). 전부 국문 ?lang=ko_KR 값으로 고정했다.
--        국문 페이지에 영문 그대로 남아 있던 자녀 학자금 항목은 「자녀 학자금 지원」으로 재코딩했다.
--
--   ⚠ ATS 2곳은 쓰지 않았다(리드 결정 2026-09-20 — 벤더 호스트 robots 도 지킨다).
--     psk.recruiter.co.kr 은 Disallow: /app* 이라 착지점 /appsite/company/index 가 금지,
--     pskinc.recruiter.co.kr 은 Disallow: / 전면 금지. 두 호스트 본문은 이번 세션에서도 요청하지 않았다.
--
--   금액: 명시값 0건. 26행 전부 BENEFIT_AMT NULL · QUAL_YN TRUE 다. 정량 표현은 전부 조건이라
--     서술에만 남겼다(편도 30km 이상 · 근속 1년 이상 · 신입 4년/경력 2년 · 연 1회 검진).
--     정착지원금은 보증금·월세 「일부」 지원이라 금액 칸을 비웠다.
--
--   병합·분리:
--     - 월세 지원(①) + 정착지원금 제도(②) → relocation 1행. ②가 ①의 조건 상세판이라 따로 세면 이중 등록이 된다.
--     - 주택 융자금·생활안정자금 지원(①) + 임직원 대출 제도(②) → housing_loan 1행(②가 한 카드로 묶고 있다).
--     - 종합·정기 건강검진(①건강) + 배우자 건강검진 지원(①가족) + 정기검진 연1회(②) → health_check 1행
--       (BENEFIT_CD 가 회사당 UNIQUE 다).
--     - 사내식당·중석식(①) + 식비 지원 중식/석식(②) → meal 1행 · 콘도/휴양시설(①) + 계약 리조트(②) → resort 1행
--     - 사내 동아리(①) + 동호회 지원(②) → club 1행 · 사내 어학강좌(①) + 어학 시험 응시료 지원 제도(①교육표)
--       + 사내 어학강좌 영어·중국어(②) → lang 1행 · 사외교육비 지원(①) + 사회학습 비용 지원 제도(①교육표) → edu_support 1행
--     - 장기근속 및 우수사원 포상(②) → long_service_bonus + excellence_award 2행(심텍 선례).
--
--   신규 코드 1개: nonsmoking_bonus(health) ← ②「금연수당 지급」. 어휘 87종에 금연·건강증진 수당 코드가 없다.
--     코퍼스 선례 테크윙은 금연수당을 clinic(건강관리실) 행 서술에 흡수했는데 피에스케이에는 clinic 행이 없어
--     흡수할 자리가 없다. fitness(피트니스센터)에 넣으면 뜻이 어긋난다.
--
--   제외: 육아휴직·육아기 근로시간 단축·유급휴가(①②, 법정 제도라 다른 행 서술에도 쓰지 않았다) ·
--     사내 강사료 지급(①개발 — 사내 강사 활동의 대가라 급여성, 사내 교육 운영의 일부) ·
--     연간 학습시간 관리제도 60시간(①, 학습 의무시간이지 혜택이 아니다) ·
--     역량 Level 제도·Champion 제도·지식 공유회·학습관리시스템 HRDS·교육 체계도·신입 입문교육·
--     계층/리더십 교육·직무 교육 과정들(①, 사내 커리큘럼) · SERICEO 정기구독·독서경영(②, 리더 한정) ·
--     인재상 3종·역량레벨테이블·성과관리시스템·직급 4단계 호칭 통일(평가·임금·호칭 체계) ·
--     가족친화인증·일생활 균형 캠페인 참여(인증·캠페인) · 법정교육 6종 · 다양성/이직률 지표표 ·
--     Culture_Deck_kr.png(Mission/Vision/Core Value 가치관 이미지 — 제도 항목 0) ·
--     esg/safety.php 의 「매월 보건대행 협력 병원 간호사 방문 건강상담」(정본 두 페이지 밖 + 안전보건 관리체계 서술).
--
--   SORT 섹션 순서는 ① 페이지에서 그 카테고리가 처음 나온 순서다
--     (work_env 10 · perks 20 · family 30 · leisure 40 · health 50 · growth 60 ·
--      compensation 70 · time_off 80 · flexibility 90).
--       ⚠ 검증·감사 판정 반영(2026-09-19): 26행 그대로. SORT 53 nonsmoking_bonus → smoking_cessation 재코딩 ·
--       SORT 30 QUAL_DESC 에서 페이지 표기 방식 서술을 걷어냈다. 각주 「(그룹 통합 채용 기준)」은 26/26 유지.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('psk', '피에스케이',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체장비', 'P', 'https://www.pskinc.com/esg/society_executives.php?lang=ko_KR');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'psk');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.pskinc.com/esg/society_executives.php?lang=ko_KR'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '기숙사 지원 (공식 ESG 임직원 페이지 조직문화 주거 생활 항목 — 입주 자격·본인 부담 비용 미기재) (그룹 통합 채용 기준)', 10),
  (@comp_id, 'lounge', '여성 휴게실·여성물품 제공', NULL, 'work_env',
   'est', NULL, TRUE, '여성휴게실, 여성물품 제공 (공식 ESG 임직원 페이지 조직문화 가족 항목 — 설치 사업장·제공 품목 미기재) (그룹 통합 채용 기준)', 11),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'relocation', '정착지원금 (보증금·월세 지원)', NULL, 'perks',
   'est', NULL, TRUE, '정착지원금 제도. 원거리 거주자(편도 30km 이상) 대상으로 보증금 및 월세 일부를 지원하고 지원기간은 신입 4년·경력 2년 (공식 채용 페이지 복지 항목. 공식 ESG 임직원 페이지 조직문화 주거 생활 항목에는 월세 지원으로 기재 — 지원 금액·한도 미기재) (그룹 통합 채용 기준)', 20),
  (@comp_id, 'housing_loan', '임직원 대출 (주택 융자금·생활안정자금)', NULL, 'perks',
   'est', NULL, TRUE, '임직원 대출 제도. 근속 1년 이상 근로자 중 가계 생활의 안정을 위하여 경제적 지원이 필요한 자가 대상이고 대출금액은 근속기간에 따라 차등지급 (공식 채용 페이지 복지 항목. 공식 ESG 임직원 페이지 조직문화 주거 생활 항목에는 주택 융자금, 생활안정자금 지원으로 기재 — 한도·이율 미기재) (그룹 통합 채용 기준)', 21),
  (@comp_id, 'meal', '사내식당 (중식·석식)', NULL, 'perks',
   'est', NULL, TRUE, '사내식당 운영, 중석식 제공 (공식 ESG 임직원 페이지 조직문화 주거 생활 항목·공식 채용 페이지 복지 항목 식비 지원 — 식대 단가·본인 부담 여부 미기재) (그룹 통합 채용 기준)', 22),
  (@comp_id, 'welfare_point', '복지몰·복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '복지몰 운영(복지포인트 지급) (공식 ESG 임직원 페이지 조직문화 복지 항목 — 연간 포인트 금액·사용처 미기재) (그룹 통합 채용 기준)', 23),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀 학자금·장학금', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금, 장학금 지원 (공식 ESG 임직원 페이지 조직문화 가족 항목. 공식 채용 페이지 복지 항목 동호회 및 기타 지원제도 항목에도 기재 — 대상 학교급·지원 한도 미기재) (그룹 통합 채용 기준)', 30),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 장례 도우미, 물품 지원 (공식 ESG 임직원 페이지 조직문화 가족 항목). 공식 채용 페이지 복지 항목 휴가 제도에는 경조휴가 기재 — 경조금 지급 여부·휴가 일수 미기재 (그룹 통합 채용 기준)', 31),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'company_event', '가족 행복캠프·자녀그림 공모전', NULL, 'leisure',
   'est', NULL, TRUE, '가족 행복캠프, 자녀그림 공모전 운영 (공식 ESG 임직원 페이지 조직문화 가족 항목 — 개최 주기·참가 대상 미기재) (그룹 통합 채용 기준)', 40),
  (@comp_id, 'resort', '콘도·휴양시설', NULL, 'leisure',
   'est', NULL, TRUE, '콘도/휴양시설 지원 (공식 ESG 임직원 페이지 조직문화 복지 항목). 공식 채용 페이지 복지 항목 휴가 제도에는 회사와 계약되어 있는 다수 리조트 보유로 기재 — 제휴처·이용 요금 미기재 (그룹 통합 채용 기준)', 41),
  (@comp_id, 'club', '사내 동아리·동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동아리 운영 지원 (공식 ESG 임직원 페이지 조직문화 복지 항목). 공식 채용 페이지 복지 항목에는 축구·야구·탁구·배드민턴·자전거·꽃꽂이 동호회 지원으로 기재 — 지원 금액 미기재 (그룹 통합 채용 기준)', 42),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합·정기 건강검진 (배우자 포함)', NULL, 'health',
   'est', NULL, TRUE, '종합, 정기 건강검진 실시와 배우자 건강검진 지원 (공식 ESG 임직원 페이지 조직문화 건강·가족 항목). 공식 채용 페이지 복지 항목에는 연 1회 전 임직원 대상 건강검진 시행으로 기재 — 검진 항목·비용 한도 미기재 (그룹 통합 채용 기준)', 50),
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '단체상해보험 가입 (공식 ESG 임직원 페이지 조직문화 건강 항목). 공식 채용 페이지 복지 항목에는 업무상 재해방지를 위하여 전 임직원 대상 단체보험 가입 및 운영으로 기재 — 보장 범위·보험료 부담 주체 미기재 (그룹 통합 채용 기준)', 51),
  (@comp_id, 'fitness', '사내 피트니스센터', NULL, 'health',
   'est', NULL, TRUE, '사내 피트니스센터 운영 (공식 ESG 임직원 페이지 조직문화 건강 항목 — 이용 시간·이용료 미기재) (그룹 통합 채용 기준)', 52),
  (@comp_id, 'smoking_cessation', '금연수당', NULL, 'health',
   'est', NULL, TRUE, '금연수당 지급 (공식 채용 페이지 복지 항목 동호회 및 기타 지원제도 — 지급액·지급 조건 미기재) (그룹 통합 채용 기준)', 53),

  -- ── 성장·교육 (growth) ──
  (@comp_id, 'edu_support', '사외교육비 지원', NULL, 'growth',
   'est', NULL, TRUE, '사외교육비 지원 (공식 ESG 임직원 페이지 조직문화 개발 항목). 같은 페이지 교육 프로그램 현황 직무 교육 칸에는 사회학습 비용 지원 제도로 기재 — 지원 한도·대상 과정 미기재 (그룹 통합 채용 기준)', 60),
  (@comp_id, 'lang', '사내 어학강좌·어학시험 응시료 지원', NULL, 'growth',
   'est', NULL, TRUE, '사내 어학강좌 운영 (공식 ESG 임직원 페이지 조직문화 개발 항목), 어학 시험 응시료 지원 제도 (같은 페이지 교육 프로그램 현황 어학 교육 칸). 강좌 언어는 공식 채용 페이지 복지 항목이 영어·중국어, 공식 ESG 임직원 페이지 인재양성 항목이 영어·중국어·일본어로 기재 — 응시료 한도·지원 횟수 미기재 (그룹 통합 채용 기준)', 61),
  (@comp_id, 'books', '도서구입비 지원', NULL, 'growth',
   'est', NULL, TRUE, '도서구입비 지원 (공식 ESG 임직원 페이지 조직문화 개발 항목 — 연간 한도·대상 도서 미기재) (그룹 통합 채용 기준)', 62),
  (@comp_id, 'self_development', '자격증 응시료 지원', NULL, 'growth',
   'est', NULL, TRUE, '자격증 응시료 지원 제도 (공식 ESG 임직원 페이지 교육 프로그램 현황 직무 교육 칸 — 대상 자격증·지원 한도·지원 횟수 미기재) (그룹 통합 채용 기준)', 63),
  (@comp_id, 'mba', '국내외 학술연수', NULL, 'growth',
   'est', NULL, TRUE, '국내외 학술연수. 우수인재를 선발하여 학술연수를 통해 학위취득 및 개인역량을 개발할 수 있는 기회 제공 (공식 채용 페이지 복지 항목. 공식 ESG 임직원 페이지 인재양성 항목에는 학술연수 제도로 기재 — 선발 인원·연수 기간·비용 부담 범위 미기재) (그룹 통합 채용 기준)', 64),

  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'stock_option', '우리사주제도', NULL, 'compensation',
   'est', NULL, TRUE, '우리사주제도 운영 (공식 ESG 임직원 페이지 조직문화 복지 항목 — 배정 조건·회사 지원 여부 미기재) (그룹 통합 채용 기준)', 70),
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 및 우수사원 포상 (공식 채용 페이지 복지 항목 동호회 및 기타 지원제도 — 근속 연수 기준·포상 금액 미기재) (그룹 통합 채용 기준)', 71),
  (@comp_id, 'excellence_award', '우수사원 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 및 우수사원 포상 (공식 채용 페이지 복지 항목 동호회 및 기타 지원제도 — 선정 기준·포상 금액 미기재) (그룹 통합 채용 기준)', 72),

  -- ── 휴가·휴직 (time_off) ──
  (@comp_id, 'leave_general', '병가', NULL, 'time_off',
   'est', NULL, TRUE, '병가 (공식 채용 페이지 복지 항목 휴가 제도 — 부여 일수·유급 여부 미기재) (그룹 통합 채용 기준)', 80),

  -- ── 유연근무 (flexibility) ──
  (@comp_id, 'flex_work', '선택적 근로시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '선택적 근로시간제 도입 (공식 ESG 임직원 페이지 조직문화 유연 근무와 업무효율 제고 서술 — 정산 기간·적용 대상 미기재) (그룹 통합 채용 기준)', 90),
  (@comp_id, 'remote_work', '재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '재택근무 활성화 (공식 ESG 임직원 페이지 조직문화 유연 근무와 업무효율 제고 서술 — 허용 일수·신청 조건 미기재) (그룹 통합 채용 기준)', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
