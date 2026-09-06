-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LG이노텍 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-05)
-- URL: https://www.lginnotek.com/recruit/worklife.lgit
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 LG이노텍 자기 도메인(www.lginnotek.com) 인재채용 > 회사생활 >
--       Work & Life 페이지 하나. 그룹 공통 사이트(careers.lg.com)를 경유하지 않는 법인
--       전용 페이지라 그룹 귀속 각주가 필요 없다.
--       ⚠ www 필수 — apex lginnotek.com 은 NXDOMAIN 이고 DART hm_url 의 .co.kr 은
--       TLS 핸드셰이크 실패 + HTTP 403 으로 죽었다. .co.kr 을 기본 도메인으로 두면 조용히 0건이 된다.
--       ⚠ HTML 주석 유령 4건: 페이지 안에 옛 Life 블록이 주석으로 남아 있고 그 안 문구는
--       현행과 다르다(종합건강검진에 연 1회, 의료비에 단체보험·실손). 주석을 걷어낸 뒤 파싱했고
--       현행 문구만 채택했다 — 그래서 insurance 행이 없다(단체보험은 주석 안에만 있다).
--       주석 제거 후 h3 20개 = 복지 항목 20개, 카테고리는 직전 h2(Work 6 / Life 14).
--       원문 20항목 → 20행: 병합 2건(선택적 근로시간제+시차출퇴근제 → flex_work,
--       경조지원+재해경조금 → event), 분리 2건(건강관리실/심리상담실 → clinic+mental,
--       주택융자 → housing_loan+dormitory).
--       ⚠ promote_system.lgit 의 「복리후생」 헤딩은 연구위원/전문위원 전용 처우라 미수록.
--       금액 명시 0건 — 페이지 전체에 원·만원 표현이 없다(수치는 전부 시간·기간 단위).
--       20행 전부 BENEFIT_AMT NULL · QUAL_YN TRUE 이며 신규 회사라 승계할 앵커도 없다.
--       법정 제도(4대보험·퇴직연금·연차·육아휴직)는 페이지에도 없고 수록하지 않았다.
--       ⚠ 검증·감사 판정 반영(2026-09-05): SORT 30 Smart Working Zone 을 lounge 에서
--       신규 코드 smart_office(work_env)로 재코딩했다 — 코퍼스 lounge 18행은 전부
--       휴게·문화 공간이라 업무 공간이 들어가면 없는 주장이 선다. 행 수는 20 그대로다.
--       사용자 노출 3필드(QUAL_DESC·NOTE·BENEFIT_NM)의 편집 주석도 함께 걷어냈다.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('lg_innotek', 'LG이노텍',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '전자부품', 'L', 'https://www.lginnotek.com/recruit/worklife.lgit');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lg_innotek');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.lginnotek.com/recruit/worklife.lgit'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — 원문 Work 섹션 ──
  (@comp_id, 'flex_work', '선택적 근로시간제(주4.5일제)/시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '주 평균 40시간을 초과하지 않는 범위에서 근무시간을 조정 (1일 4~12시간, 주4.5일제). 시차출퇴근제로 출근시간 선택 가능 (06:30~13:00) — 공식 Work & Life 페이지 Work 섹션 (신청 절차·적용 대상 미기재)', 10),
  (@comp_id, 'remote_work', '재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '업무의 효율성 및 생산성 관점에서 자율과 책임 기반의 재택근무제도 운영 (대상 직무·주당 일수 미기재)', 11),
  (@comp_id, 'satellite_office', '거점오피스', NULL, 'flexibility',
   'est', NULL, TRUE, '이동을 최소화 하고 효율적인 업무를 위해 구성원 누구나 거점오피스 이용 가능 (거점 위치·개수 미기재)', 12),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'commute_subsidy', '출/퇴근 셔틀버스', NULL, 'perks',
   'est', NULL, TRUE, '안전하고 편안한 출퇴근을 위해 본사 및 사업장별 셔틀버스 운영 (노선·이용료 미기재)', 20),
  (@comp_id, 'welfare_point', '선택적 복리후생', NULL, 'perks',
   'est', NULL, TRUE, '임직원에게 지급되는 연간 복지 포인트를 원하는 분야에 자율적으로 사용 (연간 포인트 금액 미기재)', 21),
  (@comp_id, 'housing_loan', '주택융자', NULL, 'perks',
   'est', NULL, TRUE, '주택구입 및 전세자금을 지원 (공식 Work & Life 페이지 Life 섹션 주택융자 항목 — 융자 한도·이율·자격 미기재)', 22),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'smart_office', 'Smart Working Zone', NULL, 'work_env',
   'est', NULL, TRUE, '업무 상황에 따라 최적의 공간을 선택할 수 있도록 포커스 존, 스탠딩 회의실 등의 공간 마련 (운영 사업장 미기재)', 30),
  (@comp_id, 'dormitory', '사택/기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '사업장 근무자를 위한 사택 및 기숙사 운영 (공식 Work & Life 페이지 Life 섹션 주택융자 항목 — 입주 자격·비용 미기재)', 31),

  -- ── 건강·의료 (health) — 원문 Life 섹션 ──
  (@comp_id, 'health_check', '종합건강검진', NULL, 'health',
   'est', NULL, TRUE, '임직원 본인과 배우자의 정기 건강검진을 지원 (검진 주기·항목·금액 미기재)', 40),
  (@comp_id, 'medical', '본인/가족 의료비', NULL, 'health',
   'est', NULL, TRUE, '본인, 직계가족과 배우자, 배우자 부모님의 의료비가 지원됨 (한도·대상 범위·금액 미기재)', 41),
  (@comp_id, 'clinic', '건강관리실', NULL, 'health',
   'est', NULL, TRUE, '각 사업장의 건강관리실을 통해 언제든 진료를 받을 수 있음 (공식 Work & Life 페이지 Life 섹션 건강관리실/심리상담실 항목 — 운영 시간·상주 인력 미기재)', 42),
  (@comp_id, 'mental', '심리상담실', NULL, 'health',
   'est', NULL, TRUE, '각 사업장의 심리상담실을 통해 언제든 상담을 받을 수 있음 (공식 Work & Life 페이지 Life 섹션 건강관리실/심리상담실 항목 — 상담 횟수·가족 포함 여부 미기재)', 43),
  (@comp_id, 'fitness', '사내 스포츠 시설', NULL, 'health',
   'est', NULL, TRUE, '휘트니스센터, 축구장, 농구장, 탁구장 등 사내 다양한 스포츠 시설을 이용할 수 있음 (운영 사업장·이용료 미기재)', 44),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '콘도/생활연수원', NULL, 'leisure',
   'est', NULL, TRUE, '회사와 제휴된 콘도 및 생활연수원을 다양한 할인 혜택을 통해 이용 (제휴처·할인율 미기재)', 50),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '스포츠, 문화/예술 등 다양한 사내 동호회 활동을 적극 지원 (활동비 지원액 미기재)', 51),

  -- ── 휴가 (time_off) ──
  (@comp_id, 'long_service_leave', '채움휴가', NULL, 'time_off',
   'est', NULL, TRUE, '충분히 재충전할 수 있도록 매 5년 근속 시마다 2~4주간의 채움휴가 제도 운영 (근속 구간별 주수 배분 미기재)', 60),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '경조지원·재해경조금', NULL, 'family',
   'est', NULL, TRUE, '경조휴가, 경조금, 경조화환과 함께 조사의 경우 상조인력 및 장례용품을 지원. 본인 및 직계가족이 자연재해로 피해를 입는 경우 재해경조금을 지원 (공식 Work & Life 페이지 Life 섹션 — 경조금·재해경조금 금액 미기재)', 70),
  (@comp_id, 'parenting', '출산/입학자녀 축하', NULL, 'family',
   'est', NULL, TRUE, '임직원 출산 또는 자녀 입학 시 축하선물을 전달 (선물 내역·금액 미기재)', 71),
  (@comp_id, 'childcare', '보육시설', NULL, 'family',
   'est', NULL, TRUE, '영유아 자녀를 둔 임직원을 위해 서울, 파주, 구미, 광주, 평택 사업장에서 어린이집을 운영 (정원·대상 연령 미기재)', 72),
  (@comp_id, 'child_edu', '자녀학자금', NULL, 'family',
   'est', NULL, TRUE, '임직원 자녀의 중·고등학교 및 대학교 학자금을 지원 (지원 한도·자녀 수 제한·금액 미기재)', 73)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
