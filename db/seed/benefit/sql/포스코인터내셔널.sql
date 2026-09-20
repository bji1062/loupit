-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 포스코인터내셔널 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-14)
-- URL: https://www.poscointl.com/welfare
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 법인 자기 도메인 www.poscointl.com 의 GNB 「채용 > HR 제도 > 복리후생」
--       한 페이지다. 본문 주어가 「포스코인터내셔널은 …」이고 계열사별 상이 같은 면책 문구가 0건이라
--       그룹 공통 복지가 아니다 — 「그룹 통합 채용 기준」 각주는 붙이지 않았다.
--       JSP 서버렌더라 원본 HTML 에 24항목(3카테고리 article.hr_char)이 그대로 있다. 헤드리스 불필요.
--       robots.txt 는 404(기본 허용). 그룹 채용사이트 recruit.posco.com 과 잡플렉스 ATS
--       poscointl.recruiter.co.kr 은 robots 전면 차단이라 요청하지 않았다.
--       ⚠ 첫 항목 「자율근무제」 제목·설명에 U+200B 5개가 박혀 있다 — 제거 후 매칭했다.
--       ⚠ 페이지에 canonical·고유 title 이 없어 갱신 감지는 article.hr_char 3개 바이트 해시로(evidence).
--       ⚠ TLS 인증서 만료 2026-10-17 — 그 이후 재수집이면 갱신 여부부터 확인.
--       원문 24항목 → 제외 1(육아기 근로시간 단축 — 원문이 상회 조건을 밝히지 않는 법정 제도) →
--       같은 코드 병합 1(육아휴직 항목의 일반휴직 1년을 출산장려금과 같은 parenting 행에) → **22행**.
--       법정 제도 문구는 사용자 노출 필드에 쓰지 않았다: 육아휴직은 원문이 법정/일반을 나눠 밝힌
--       일반휴직 1년만, 난임치료휴가/치료비 항목은 치료비만 수록(휴가 일수는 법정분·회사분 구분이 없어 뺐다).
--       금액: 휴양시설의 숙박 플랫폼 포인트 격년 40만원 → 연 20만원(유일한 AMT).
--       출산장려금 첫째 300만원·둘째 이상 500만원은 출산 시 1회성, 난임 치료비 회당 100만원은 한도라
--       AMT 가 아니다 — 서술로만 남겼다. 신규 코드 0.
--       INDUSTRY_NM 종합상사: 기존 값 중 무역을 담은 것은 건설/무역(삼성물산) 하나뿐인데 이 법인은
--       건설업이 아니고, 폴백 쌍은 문자열 완전 일치로 묶여 부분 합류가 불가능하다 — 짧은 새 값.
--       ⚠ 검증·감사 판정 반영(2026-09-15): 22 → 21행. SORT 40 출장 Refresh 휴가는 출장이라는 근무 사건에 붙는
--       보상 휴가라 refresh_leave 에서 leave_general 로 옮겨 SORT 41 심야근무 보상휴가와 병합했다.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ⚠ 법정 제도 문구 정리(2026-09-20): SORT 73 문안 교체 — 법정 제도 서술을 걷고 회사 상회분만 남겼다. 행 수 변동 없음.

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('posco_intl', '포스코인터내셔널',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '종합상사', 'P', 'https://www.poscointl.com/welfare');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'posco_intl');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.poscointl.com/welfare'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — 원문 Work & Life Balance ──
  (@comp_id, 'flex_work', '자율근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '2주 단위 근로시간 자율 운영(Core Time 있음), 격주 금요일은 Core Time 해제로 주 4일 근무 설정 가능 (공식 홈페이지 복리후생 Work & Life Balance 항목 — Core Time 시간대·적용 대상 미기재)', 10),
  (@comp_id, 'satellite_office', '거점오피스', NULL, 'flexibility',
   'est', NULL, TRUE, '서울역·역삼·여의도 등 5개 거점오피스/셔틀 운영 (공식 홈페이지 복리후생 Work & Life Balance 항목 — 나머지 거점 위치·이용 조건 미기재)', 11),

  -- ── 경제적 부가혜택 (perks) — 원문 Work & Life Balance · Individual Care ──
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '주요 수도권 40여 개 노선 통근버스 운영 (공식 홈페이지 복리후생 Work & Life Balance 항목 — 요금 부담 여부·운행 사업장 미기재)', 20),
  (@comp_id, 'housing_loan', '사내근로복지기금 주택·생활자금 대부', NULL, 'perks',
   'est', NULL, TRUE, '사내근로복지기금의 주택구매/임차, 생활자금 저리 대부 (공식 홈페이지 복리후생 Individual Care 항목 — 대부 한도·금리·자격 요건 미기재)', 21),
  (@comp_id, 'welfare_point', '선택적 복리후생', NULL, 'perks',
   'est', NULL, TRUE, '연 단위 복지포인트 부여 (공식 홈페이지 복리후생 Individual Care 항목 — 연간 포인트 금액 미기재)', 22),
  (@comp_id, 'pension_support', '개인연금 지원', NULL, 'perks',
   'est', NULL, TRUE, '매월 개인연금상품 납입액 지원 (공식 홈페이지 복리후생 Individual Care 항목 — 지원 비율·월 지원 한도 미기재)', 23),

  -- ── 건강·의료 (health) — 원문 Work & Life Balance · Individual Care · Family Care ──
  (@comp_id, 'fitness', 'Fitness Center', NULL, 'health',
   'est', NULL, TRUE, '사옥 내 270평 규모 Fitness Center (공식 홈페이지 복리후생 Work & Life Balance 항목 — 이용료·운영 시간 미기재)', 30),
  (@comp_id, 'insurance', '직원 단체보험', NULL, 'health',
   'est', NULL, TRUE, '질병/상해/진단금/실손 등 단체보험 가입 (공식 홈페이지 복리후생 Individual Care 항목 — 보장 한도·가족 포함 여부 미기재)', 31),
  (@comp_id, 'health_check', '건강검진', NULL, 'health',
   'est', NULL, TRUE, '본인 및 배우자 검진 프로그램 제공 (공식 홈페이지 복리후생 Individual Care 항목 — 검진 주기·지원 금액 미기재)', 32),
  (@comp_id, 'clinic', '건강관리실', NULL, 'health',
   'est', NULL, TRUE, '건강관리실 운영 — 건강상담, 안정실 및 의약품 제공 (공식 홈페이지 복리후생 Individual Care 항목 — 상주 인력·운영 시간 미기재)', 33),
  (@comp_id, 'mental', '심리상담센터', NULL, 'health',
   'est', NULL, TRUE, '심리상담센터 운영 — 직원 및 직원가족 심리상담, 부서단위 프로그램 지원 (공식 홈페이지 복리후생 Individual Care 항목 — 상담 횟수·비용 부담 미기재)', 34),
  (@comp_id, 'medical', '가족 의료비 보조', NULL, 'health',
   'est', NULL, TRUE, '가족 입원의료비 지원 (공식 홈페이지 복리후생 Family Care 항목 — 지원 한도·가족 범위 미기재)', 35),

  -- ── 휴가 (time_off) — 원문 Work & Life Balance ──
  (@comp_id, 'leave_general', '출장 Refresh 휴가·심야근무 보상휴가', NULL, 'time_off',
   'est', NULL, TRUE, '주말 또는 Overnight 항공편 이용 시 Refresh 휴가 부여, 심야 근무 시 익일/차주 휴가 부여 (공식 홈페이지 복리후생 Work & Life Balance 항목 — 부여 일수·심야 근무 인정 기준 미기재)', 41),

  -- ── 여가·라이프 (leisure) — 원문 Work & Life Balance ──
  (@comp_id, 'club', '사내동호회', NULL, 'leisure',
   'est', NULL, TRUE, '취미/레저/학습 등 동호회 운영 지원 (공식 홈페이지 복리후생 Work & Life Balance 항목 — 활동비 지원액 미기재)', 50),
  (@comp_id, 'resort', '휴양시설', 20, 'leisure',
   'est', '공식 홈페이지 복리후생 Work & Life Balance 휴양시설 항목 명시값 숙박 플랫폼 포인트 격년 40만원 지급을 연 20만원으로 환산한 값. 같은 항목의 전국 제휴콘도·그룹사 휴양시설 공동 이용은 금액에 포함하지 않았다', FALSE, NULL, 51),

  -- ── 근무환경 (work_env) — 원문 Work & Life Balance ──
  (@comp_id, 'dormitory', '신입사원 기숙사 지원', NULL, 'work_env',
   'est', NULL, TRUE, '입사 후 3년간 송도본사 인근 기숙사 지원, 단 인천시 거주자는 기숙사 지원 불가 (공식 홈페이지 복리후생 Work & Life Balance 항목 — 자부담·입주 형태 미기재)', 60),

  -- ── 가족·돌봄 (family) — 원문 Individual Care · Family Care ──
  (@comp_id, 'event', '경조휴가/경조금', NULL, 'family',
   'est', NULL, TRUE, '경조 사유별 경조휴가 및 경조금 지급 (공식 홈페이지 복리후생 Individual Care 항목 — 사유별 휴가 일수·경조금액 미기재)', 70),
  (@comp_id, 'childcare', '직장어린이집', NULL, 'family',
   'est', NULL, TRUE, '육아부담 완화 목적 사옥 내 어린이집 2개소 운영 (공식 홈페이지 복리후생 Family Care 항목 — 정원·대상 연령 미기재)', 71),
  (@comp_id, 'child_edu', '자녀 학자금 보조', NULL, 'family',
   'est', NULL, TRUE, '유치원, 초/중/고/대학교 학자금 지원 (공식 홈페이지 복리후생 Family Care 항목 — 지원 한도·자녀 수 제한 미기재)', 72),
  (@comp_id, 'parenting', '출산장려금·육아 일반휴직', NULL, 'family',
   'est', NULL, TRUE, '출산장려금 첫째 300만원, 둘째 이상 500만원 및 선물 지급, 육아 목적 일반휴직 1년 추가 사용 가능 (공식 홈페이지 복리후생 Family Care 항목 — 선물 내용·일반휴직 기간 급여 미기재)', 73),
  (@comp_id, 'fertility_support', '난임 치료비 지원', NULL, 'family',
   'est', NULL, TRUE, '난임 치료비 회당 100만원 한도 내 실비 지원 (공식 홈페이지 복리후생 Family Care 항목 — 연간 지원 횟수 미기재)', 74)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
