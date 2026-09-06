-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 삼성중공업 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-05)
-- URL: https://www.samsungshi.com/Ko/Welfare.aspx
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 삼성중공업 자기 도메인(samsungshi.com) 복리후생 페이지 하나다.
--       ASP.NET 서버렌더라 최초 HTML 에 항목 30개가 전부 들어 있다(18,474 B).
--       ⚠ 항목 설명문은 화면 텍스트가 아니라 li 의 data-tip 속성 안에 있다.
--       태그 제거 후 텍스트만 취하면 라벨 30개만 남고 설명 30개를 통째로 잃는다.
--       파서는 ul.welfare_list > li 에서 (텍스트, @data-tip) 쌍으로 뽑아야 한다.
--       ⚠ 이 도메인은 HEAD 요청에 HTTP 400 을 준다(GET 은 200). 링크 감사·생존 확인을
--       HEAD 로 짜면 이 URL 이 전부 죽은 것으로 오판한다 — 반드시 GET.
--       ⚠ robots.txt·sitemap.xml 은 HTTP 200 이지만 내용이 BOM 붙은 HTML 오류 페이지다
--       (두 파일 바이트 동일). robots 지시자 0줄 = 명시적 금지 없음.
--       페이지 항목 30개 → 26행. 카테고리 3개(가족·의료 및 소득 지원 11 / 자기 개발 지원 10 /
--       사내 문화 및 편의 9). 복합 라벨 「근속휴가 및 선물」을 2행으로 분리하고
--       「국내/외 학술연수」+「지역전문가」를 career 1행으로 병합, 규칙 8(회사 주도 교육
--       커리큘럼은 복지 아님)로 4개 항목을 제외했다(evidence 제외 목록 참조).
--       금액 명시 0건 — 30개 설명문 어디에도 원·만원·% 수치가 없다. 전 행 BENEFIT_AMT NULL·
--       QUAL_YN TRUE 이며 신규 회사라 승계할 앵커도 없어 타사 금액을 끌어오지 않았다.
--       특히 「주택자금 지원」은 대출 이자액 일부 지원이라 원금 한도조차 없다(정성 항목).
--       그룹 채용사이트 samsungcareers.com/subsid/detail/D60 은 법인 귀속이 명확하지만
--       항목이 27개로 3개 적고 기숙사 설명이 다른 구버전이라 채택하지 않았다(폴백 메모).
--       영문판 En/Welfare.aspx 로 30개 라벨·설명을 1:1 교차검증했다.
--       ⚠ 검증·감사 판정 반영(2026-09-05): SORT 21 모성보호제도 서술에서 「시차 출근」을
--       뺐다 — 임신 중 근로자의 근무시각 변경은 근로기준법이 이미 의무화한 사항이라,
--       원문이 그 이상을 밝히지 않는 한 회사 재량 급부로 실을 수 없다. 행 수 26 그대로.
--       SORT 60 의 학술연수·지역전문가는 career 에, SORT 63 은 MBA·EMBA 전용으로 둔다.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('samsung_heavy', '삼성중공업',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '조선', 'S', 'https://www.samsungshi.com/Ko/Welfare.aspx');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_heavy');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.samsungshi.com/Ko/Welfare.aspx'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강·의료 (health) ──
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '본인·배우자 및 자녀 의료비 지원 (지원 한도·항목·금액 미기재)', 10),
  (@comp_id, 'mental', '심리상담센터', NULL, 'health',
   'est', NULL, TRUE, '전문 심리상담사를 활용한 임직원 마음건강 관리 (상담 횟수·가족 포함 여부 미기재)', 11),
  (@comp_id, 'health_check', '건강검진', NULL, 'health',
   'est', NULL, TRUE, '기준에 따라 일반·특수검진, 종합검진 제공 (주기·대상 기준·가족 포함 여부 미기재)', 12),
  (@comp_id, 'fitness', '스포츠 시설', NULL, 'health',
   'est', NULL, TRUE, '사내 수영장·볼링장·테니스장·축구장·야구장·농구장·피트니스 센터 등 운영 (이용료·운영 사업장 미기재)', 13),
  (@comp_id, 'clinic', '사내병원', NULL, 'health',
   'est', NULL, TRUE, '전문의가 상주해 임직원 건강 관리 및 응급상황 대처 (진료 과목·운영 사업장 미기재)', 14),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '3살 이상 자녀 지원 가능하며 초등학교 입학 전까지 등원 가능 (정원·보육료 부담 미기재)', 20),
  (@comp_id, 'parenting', '모성보호제도', NULL, 'family',
   'est', NULL, TRUE, '임산부 휴식공간 제공 등 모성보호제도 운영 (적용 기간·대상 범위 미기재)', 21),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀의 미취학 학자금부터 대학 학자금까지 지원 (지원 한도·자녀 수 제한·금액 미기재)', 22),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '사내 기준에 따라 경조사비 지급 및 휴가 지원 (경조 종류별 금액·휴가 일수 미기재)', 23),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '선택적 복리후생을 위한 복지포인트 제공, 항공권·숙소 등에 사용 (연간 포인트 금액 미기재)', 30),
  (@comp_id, 'pension_support', '개인연금 지원', NULL, 'perks',
   'est', NULL, TRUE, '노후자금 마련 지원을 위해 개인연금 가입액 일부 지원 (지원 비율·상한 미기재)', 31),
  (@comp_id, 'housing_loan', '주택자금 지원', NULL, 'perks',
   'est', NULL, TRUE, '주거생활 안정을 위한 주택 구입·전세 계약 대출 이자액 일부 지원 (대출 한도·이자 지원율 미기재)', 32),
  (@comp_id, 'commute_subsidy', '출퇴근 셔틀', NULL, 'perks',
   'est', NULL, TRUE, '거제·통영 전지역 셔틀 버스를 운행해 출퇴근 지원 (노선 수·이용료 미기재)', 33),
  (@comp_id, 'transport', '주말 귀향버스', NULL, 'perks',
   'est', NULL, TRUE, '서울·부산 등 주요 도시별 귀향버스 운영 (운행 주기·이용료 미기재)', 34),

  -- ── 휴가 (time_off) ──
  (@comp_id, 'long_service_leave', '근속휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기 근속 시 리텐션을 위한 휴가 지급 (근속 연차 기준·휴가 일수 미기재)', 40),

  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'long_service_bonus', '장기근속 선물', NULL, 'compensation',
   'est', NULL, TRUE, '장기 근속 시 리텐션을 위한 선물 지급 (근속 연차 기준·선물 종류·금액 미기재)', 50),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'career', '국내외 학술연수·지역전문가', NULL, 'growth',
   'est', NULL, TRUE, '전문가 양성을 위한 해외 학술 연수 실시, 현지화된 글로벌 핵심인력 양성을 위한 지역전문가 파견 (선발 기준·파견 기간·지원 범위 미기재)', 60),
  (@comp_id, 'edu_support', '온라인 교육비 지원', NULL, 'growth',
   'est', NULL, TRUE, '전문지식·외국어 등 본인이 수강한 온라인 교육비 지원 (지원 한도·대상 과정 미기재)', 61),
  (@comp_id, 'self_development', '자격증 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '업무에 필요한 자격증 취득 비용 지원 (대상 자격증·지원 한도 미기재)', 62),
  (@comp_id, 'mba', 'MBA·EMBA 지원', NULL, 'growth',
   'est', NULL, TRUE, '전문 경영인 양성을 위한 MBA·EMBA 교육 지원 (선발 기준·학비 지원 범위 미기재)', 63),
  (@comp_id, 'lang', '회화시험 응시료 지원', NULL, 'growth',
   'est', NULL, TRUE, 'Opic 응시료 지원 (연간 응시 횟수·지원 한도 미기재)', 64),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'lounge', '엔지니어 라운지', NULL, 'work_env',
   'est', NULL, TRUE, '임직원 휴식공간 테크리움·스마트가든 제공 (운영 사업장·이용 조건 미기재)', 70),
  (@comp_id, 'dormitory', '기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '거주기한 제한 없는 기숙사 제공, 부대시설로 헬스장·독서실·편의점 운영 (입주 자격·비용 부담 미기재)', 71),

  -- ── 근무 유연성 (flexibility) ──
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '자기주도적 시간 관리를 위한 유연근무제 실시 (정산 단위·적용 직군 미기재)', 80),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'club', '사내동호회', NULL, 'leisure',
   'est', NULL, TRUE, '요리·음악·풋살 등 다양한 동호회 활동을 통한 여가 시간 활용 (활동비 지원 여부 미기재)', 90),
  (@comp_id, 'resort', '휴양소 지원', NULL, 'leisure',
   'est', NULL, TRUE, '콘도 또는 숙소비 지원 (제휴처·이용 일수·지원 금액 미기재)', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
