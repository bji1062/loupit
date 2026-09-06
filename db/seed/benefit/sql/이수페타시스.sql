-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 이수페타시스 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-05)
-- URL: https://www.petasys.com/kor/recruit/recruit02.jsp
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 이수페타시스 법인 자기 도메인(www.petasys.com) 채용정보 > 복리후생 페이지.
--       JSP 서버렌더라 최초 HTML 에 항목이 그대로 있다(sha256 62be8ad6…0bea6, 38,237 B).
--       페이지 카테고리 4개(Leisure & Activity 6 · Life Balance 7 · Happy Workplace 8 ·
--       Motivation 4) 아래 항목 25개 — 전부 li 태그 라벨뿐이고 설명 문장·금액·조건·대상이
--       하나도 없다. 따라서 심텍 방식으로 전 행 BENEFIT_AMT NULL · QUAL_YN TRUE 이며,
--       신규 회사라 승계할 앵커도 없어 타사 금액을 끌어오지 않았다(금액 stated 0건).
--       25 라벨 → 24행: 복합 라벨 2개를 분리(+2), 같은 코드로 귀결되는 3쌍을 병합(−3).
--         분리 = 정기검진 및 상담실 운영 → health_check + clinic,
--                장기근속자 포상 및 휴가 → long_service_bonus + long_service_leave(어휘 함정 5).
--         병합 = 정기검진 + 직위·연령별 건강검진 지원 → health_check,
--                각종 경조금 지원 + 경조휴가 지원 → event(KB·현대건설 선례),
--                자녀 학자금 지원 + 수능대상자 자녀 격려품 지급 → child_edu(심텍 검증 판정 선례).
--       ⚠ 법정 제도 미수록(규칙 3): 창립기념일, 노동절 휴무 라벨 중 노동절(근로자의 날)은
--         법정 유급휴일이라 빼고 회사 재량인 창립기념일 휴무만 수록했다.
--       ⚠ 제외 1건: 형제 페이지 recruit01.jsp(인재상)는 순수 이수그룹 콘텐츠(복지 항목 0건),
--         recruit03.jsp(채용공고)는 진행 공고 0건이라 근거 없음.
--       ⚠ 신규 코드 1건: disability_veteran(장애인 및 보훈대상자 혜택) — evidence 참조.
--       ⚠ apex 도메인 petasys.com 은 NXDOMAIN 이다 — 반드시 www 를 붙인다.
--         DART hm_url 후보 isupetasys.com 은 웹이 죽은 호스트라 URL 로 쓰면 안 된다
--         (다만 메일 도메인으로는 살아 있다 — evidence 이메일 절 참조).
--       ⚠ 이 사이트의 sitemap.xml 은 그룹(isu.co.kr) 것이 잘못 배포되어 petasys URL 이 0건이다.
--         발견 로직이 sitemap 을 따르면 이수건설 등 타 법인으로 샌다 — 경로 하드코딩할 것.
--       ⚠ 페이지 리드 문장이 「이수그룹은 …」 그룹 화법이라 본문에 넣지 않았다. 귀속은
--         법인 도메인·법인 푸터·그룹 페이지와 다른 항목 집합(그룹 11 vs 법인 25)·
--         타 계열사 동일 경로 404 로 확정했다(evidence 1절).
--       ⚠ 검증·감사 판정 반영(2026-09-05): 24 → 21행. SORT 21 사이버 연수원(edu_support)
--       삭제 — 학습 플랫폼 운영이라 비용 지원이 아니다 · SORT 41 상담실(clinic) 삭제 —
--       「정기검진 및 상담실 운영」 한 라벨의 뒷조각이고 SORT 40 이 라벨을 통째로 갖고
--       있다 · SORT 51 장애인·보훈대상자 혜택(disability_veteran) 삭제 — 혜택 내용이
--       0자라 무엇을 비교하는지 정의가 없다. SORT 70 은 법정 휴일인 노동절 문구를 뺐다.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('isu_petasys', '이수페타시스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        'PCB', 'I', 'https://www.petasys.com/kor/recruit/recruit02.jsp');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'isu_petasys');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.petasys.com/kor/recruit/recruit02.jsp'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 여가·라이프 (leisure) — 원문 Leisure & Activity ──
  (@comp_id, 'resort', '리조트 회원권', NULL, 'leisure',
   'est', NULL, TRUE, '리조트 회원권 운영 (공식 페이지 Leisure & Activity 항목명 그대로 — 제휴 리조트·이용 조건·회원권 수 미기재)', 10),
  (@comp_id, 'club', '써클(동아리) 지원', NULL, 'leisure',
   'est', NULL, TRUE, '써클(동아리) 운영 및 지원 (공식 페이지 Leisure & Activity 항목명 그대로 — 활동비 지원 규모·동호회 수 미기재)', 11),
  (@comp_id, 'leisure_ticket', '문화생활 지원(영화티켓 등)', NULL, 'leisure',
   'est', NULL, TRUE, '문화생활 지원(영화티켓 등) (공식 페이지 Leisure & Activity 항목명 그대로 — 지원 횟수·금액 미기재)', 12),

  -- ── 성장·커리어 (growth) — 원문 Leisure & Activity ──
  (@comp_id, 'lang', '사내 외국어 강좌', NULL, 'growth',
   'est', NULL, TRUE, '사내 외국어 강좌 (공식 페이지 Leisure & Activity 항목명 그대로 — 개설 언어·수강 대상·비용 부담 미기재)', 20),
  (@comp_id, 'career', '멘토링 제도', NULL, 'growth',
   'est', NULL, TRUE, '멘토링 제도 (공식 페이지 Leisure & Activity 항목명 그대로 — 대상·운영 기간 미기재)', 22),

  -- ── 가족·돌봄 (family) — 원문 Life Balance + Happy Workplace ──
  (@comp_id, 'child_edu', '자녀 학자금·수능 격려품', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원, 수능대상자 자녀 격려품 지급 (공식 페이지 Life Balance·Happy Workplace 항목명 그대로 — 지원 학교급·한도·금액 미기재)', 30),
  (@comp_id, 'event', '경조금·경조휴가 지원', NULL, 'family',
   'est', NULL, TRUE, '각종 경조금 지원, 경조휴가 지원 (공식 페이지 Life Balance·Happy Workplace 항목명 그대로 — 경조 사유별 금액·휴가 일수 미기재)', 31),

  -- ── 건강·의료 (health) — 원문 Life Balance ──
  (@comp_id, 'health_check', '건강검진', NULL, 'health',
   'est', NULL, TRUE, '정기검진 및 상담실 운영, 직위·연령별 건강검진 지원 (공식 페이지 Life Balance 항목명 그대로 — 검진 주기·직위 구간·검진 항목·비용 미기재)', 40),
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '임직원 단체상해보험 (공식 페이지 Life Balance 항목명 그대로 — 보장 범위·가족 포함 여부·보험료 미기재)', 42),

  -- ── 경제적 부가혜택 (perks) — 원문 Life Balance + Happy Workplace ──
  (@comp_id, 'housing_loan', '주택자금대출', NULL, 'perks',
   'est', NULL, TRUE, '주택자금대출 (공식 페이지 Life Balance 항목명 그대로 — 대출 한도·이율·근속 요건 미기재)', 50),
  (@comp_id, 'meal', '구내식당', NULL, 'perks',
   'est', NULL, TRUE, '구내식당 운영 (공식 페이지 Happy Workplace 항목명 그대로 — 제공 끼니·식대·본인 부담 미기재)', 52),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '통근버스 운행 (공식 페이지 Happy Workplace 항목명 그대로 — 노선·운행 지역·이용 대상 미기재)', 53),
  (@comp_id, 'telecom', '통신비 지원', NULL, 'perks',
   'est', NULL, TRUE, '통신비 지원 (공식 페이지 Happy Workplace 항목명 그대로 — 지원액·대상 직군 미기재)', 54),

  -- ── 근무환경 (work_env) — 원문 Happy Workplace ──
  (@comp_id, 'dormitory', '기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '기숙사 제공 (공식 페이지 Happy Workplace 항목명 그대로 — 소재지·입주 자격·본인 부담 미기재)', 60),
  (@comp_id, 'lounge', '휴게실·샤워실·회의실', NULL, 'work_env',
   'est', NULL, TRUE, '휴게실, 샤워실, 회의실 운영 (공식 페이지 Happy Workplace 항목명 그대로 — 사업장별 설치 현황 미기재)', 61),

  -- ── 휴가 (time_off) — 원문 Happy Workplace + Motivation ──
  (@comp_id, 'foundation_day_leave', '창립기념일 휴무', NULL, 'time_off',
   'est', NULL, TRUE, '창립기념일 휴무 (공식 페이지 Happy Workplace 항목명 기준 — 휴무 일수 미기재)', 70),
  (@comp_id, 'long_service_leave', '장기근속자 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속자 포상 및 휴가 (공식 페이지 Motivation 항목명 그대로 — 근속 연차 구간·휴가 일수 미기재)', 71),
  (@comp_id, 'refresh_leave', 'Refresh 휴가', NULL, 'time_off',
   'est', NULL, TRUE, 'Refresh 휴가 (공식 페이지 Motivation 항목명 그대로 — 사용 주기·일수·근속 요건 미기재)', 72),

  -- ── 보상·금전 (compensation) — 원문 Motivation ──
  (@comp_id, 'long_service_bonus', '장기근속자 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속자 포상 및 휴가 (공식 페이지 Motivation 항목명 그대로 — 근속 연차 구간·포상 금액 미기재)', 80),
  (@comp_id, 'excellence_award', '우수사원 표창', NULL, 'compensation',
   'est', NULL, TRUE, '우수사원 표창 (공식 페이지 Motivation 항목명 그대로 — 선발 기준·포상 규모 미기재)', 81),
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '성과급 지급 (공식 페이지 Motivation 항목명 그대로 — 지급 기준·지급률·지급 시기 미기재)', 82)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
