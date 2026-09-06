-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 삼성E&A 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-05)
-- URL: https://www.samsungena.com/kr/careers/company-life
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 정본은 자기 도메인(samsungena.com) 인재채용 > 복리후생 페이지다. 서버렌더라
--       일반 브라우저 UA 의 curl 한 번으로 항목 23개가 그대로 나온다(회사 생활 10 · 건강 7 · 가족 6).
--       보조 출처는 삼성 채용사이트의 계열사 상세 D80(samsungcareers.com/subsid/detail/D80) 안
--       「삼성E&A의 근무 환경과 복지 제도」 블록 29개다. 그룹 공통 복지가 아니라 법인 전용 블록이며
--       같은 블록에 삼성E&A 주소(강동구 상일로6길 26 GEC)·채용문의 메일·홈페이지가 붙어 귀속이 명확하다.
--       두 출처의 합집합에서 같은 제도를 정규화해 29행을 만들었다. CAREERS_BENEFIT_URL 은 정본.
--       ⚠ 정본의 가족 지원 6개는 캐러셀 본문과 하단 썸네일 내비에 각각 렌더돼 strong 태그가 12개다.
--         중복 제거 없이 세면 23 이 29 로 부풀어 보조 출처 항목 수와 우연히 같아진다(함정).
--       ⚠ 사이트맵이 낡았다. 사이트맵의 /kr/careers/join-us/company-life 는 404 이고(그것도
--         application/json 404) 정본 경로는 join-us 가 빠진 /kr/careers/company-life 다. GNB 링크를 따라가야 200.
--       ⚠ 페이지 이미지는 전부 alt 가 빈 장식 사진이라 판독 대상이 없다. 라벨은 모두 HTML 텍스트다.
--       금액: 두 출처 어디에도 원·만원 금액이 없다 → 29행 전부 BENEFIT_AMT NULL · QUAL_YN TRUE.
--         정량 서술(식당 1,300석 9개 코너·통근버스 100여대·도서 약 14,000권·동호회 60개 이상)은
--         금액이 아니라 규모라서 서술에만 담고 금액 칸은 비웠다. 신규 회사라 승계할 앵커도 없다.
--       법정 제도(4대보험·퇴직연금·법정 연차·출산전후휴가·육아기 휴직 및 근로시간 단축)는 수록하지 않았다.
--         보조 출처의 「모성보호」에서 법정분을 덜어내고 회사 재량인 난임 치료비 지원만 1행으로 남겼다.
--       제외한 것: 투게더플러스(국문·영문·자사 사이트 검색 어디에도 제도 설명이 없어 코드 매핑이 창작이 된다),
--         자율 복장(원익IPS 선례에서 uniform 반증으로 삭제된 유형), 자기개발 10종 중 비용 지원이
--         명시되지 않은 7종(계약 규칙 8 — 회사 주도 교육 커리큘럼은 복지가 아니다).
--       ⚠ 검증·감사 판정 반영(2026-09-05): 29 → 26행. SORT 21 명상실(lounge)을 SORT 20
--       수면실 휴게공간에 병합 · SORT 84 사옥 결혼식장 대관(wedding)을 SORT 85 경조
--       지원(event)에 병합 — 코퍼스 wedding 은 현금 축하금 1행 축이다 · SORT 44 GWP
--       Change Agent(team_dinner) 삭제(부서 활동비가 아니라 담당자 역할). 지역전문가는
--       행을 새로 만들지 않고 SORT 31 MBA 서술에 흡수했다. SORT 82 의 법정 난임휴가
--       문구를 빼고, 사용자 노출 3필드의 편집 주석도 걷어냈다.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('samsung_ena', '삼성E&A',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '건설', 'S', 'https://www.samsungena.com/kr/careers/company-life');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_ena');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.samsungena.com/kr/careers/company-life'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'club', '사내 동호회 운영 및 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '스포츠·문화·음악·스터디·DIY 등 60개 이상 동호회를 운영하며 취미생활 공유를 위해 활동비 지원', 10),
  (@comp_id, 'leisure_ticket', '테마파크 이용 지원', NULL, 'leisure',
   'est', NULL, TRUE, '국내 유명 놀이공원 우대 혜택 제공 (할인율·연간 이용 횟수 미기재)', 11),
  (@comp_id, 'resort', '전국 리조트 이용 지원', NULL, 'leisure',
   'est', NULL, TRUE, '전국 유명 휴양소를 회원 가격으로 이용하도록 지원 (제휴처 목록·이용 일수 미기재)', 12),
  (@comp_id, 'company_event', '가족 초청 행사', NULL, 'leisure',
   'est', NULL, TRUE, '가족 초청 행사를 통해 임직원과 가족이 회사에 대한 자긍심을 공유하고 추억을 만들 기회 제공 (행사 주기·대상 미기재)', 13),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'nap_room', '수면실을 갖춘 휴게공간·명상실', NULL, 'work_env',
   'est', NULL, TRUE, '수면실을 갖춘 사내 휴게공간과 명상실 운영 (공식 페이지 항목명 기준 — 위치·운영 시간·예약 여부 미기재)', 20),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'books', '사내도서관', NULL, 'growth',
   'est', NULL, TRUE, '리프레시와 자기계발을 위해 약 14,000권의 도서와 컨텐츠를 구비한 사내도서관 운영', 30),
  (@comp_id, 'mba', '기술대학원·MBA 학위 지원', NULL, 'growth',
   'est', NULL, TRUE, '공학계열 대학원 진학 제도의 학비 및 생활비 지원, 국내외 MBA 학위 취득(Full-time) 학비·생활 지원, 지역전문가 해외 현지 언어·문화 습득 파견 (그룹 채용사이트 삼성E&A 상세 기준 — 지원 한도·선발 인원 미기재)', 31),
  (@comp_id, 'lang', '외국어 교육 지원', NULL, 'growth',
   'est', NULL, TRUE, 'OPIc 응시료 지원, 언어별·단계별 교육 프로그램(전화영어·비즈니스 언어·말하기 듣기) 운영 (그룹 채용사이트 삼성E&A 상세 기준)', 32),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '선택형 복지 포인트 지급', NULL, 'perks',
   'est', NULL, TRUE, '여가생활 지원을 위해 원하는 업종에 사용 가능한 현금성 포인트 지급 (연간 포인트 금액 미기재)', 40),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '수도권 전지역에 매일 100여대 규모의 출퇴근 버스 운영', 41),
  (@comp_id, 'meal', '사내식당', NULL, 'perks',
   'est', NULL, TRUE, '본사 내 1,300석 규모 식당에서 한식·중식·일식·양식 등 9개 코너 운영 (제공 끼니·식대 미기재)', 42),
  (@comp_id, 'pension_support', '개인연금', NULL, 'perks',
   'est', NULL, TRUE, '임직원의 안정적 노후를 위한 개인연금 지원 (그룹 채용사이트 삼성E&A 상세 기준 — 회사 부담률·한도 미기재)', 43),

  -- ── 휴가 (time_off) ──
  (@comp_id, 'long_service_leave', '장기 근속 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 기간에 따른 유급휴가 부여 (근속 연차 구간·휴가 일수 미기재)', 50),

  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'long_service_bonus', '장기 근속 포상 및 휴가비', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 기간에 따른 기념품·상품권·휴가비 지급 (금액·근속 연차 구간 미기재)', 60),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'mental', '심리 상담센터', NULL, 'health',
   'est', NULL, TRUE, '임직원과 가족의 마음 건강을 위한 상담과 힐링자료를 제공하는 상담센터 운영', 70),
  (@comp_id, 'clinic', '사내병원 (가정의학과·정신건강의학과)', NULL, 'health',
   'est', NULL, TRUE, '가정의학과·정신건강의학과를 둔 사내병원을 무료로 운영 (공식 페이지 항목명 기준 — 진료 시간·이용 대상 미기재)', 71),
  (@comp_id, 'health_check', '종합 건강 검진 (배우자 포함)', NULL, 'health',
   'est', NULL, TRUE, '본인 및 배우자 종합검진 지원 (주기·검진 항목·금액 미기재)', 72),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '실손의료비를 배우자·자녀까지 포함해 지원 (한도·자기부담 미기재)', 73),
  (@comp_id, 'insurance', '단체보험 (단체/실손)', NULL, 'health',
   'est', NULL, TRUE, '단체보험(진단금) 지원 (공식 페이지 항목명이 단체/실손 보험을 명시 — 보장 범위·보험료 부담 주체 미기재)', 74),
  (@comp_id, 'fitness', '피트니스 센터', NULL, 'health',
   'est', NULL, TRUE, '본사 내 피트니스 센터 운영 (이용료·운영 시간 미기재)', 75),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '만 1~5세 연령별 프로그램을 갖춘 본사 어린이집 운영 (정원·대기 기준 미기재)', 80),
  (@comp_id, 'parenting', '임신/출산 비용 지원', NULL, 'family',
   'est', NULL, TRUE, '임신·출산에 따른 경제적 부담을 덜어 주는 지원 프로그램 운영 (지원 항목·금액 미기재)', 81),
  (@comp_id, 'fertility_support', '난임 치료비 지원', NULL, 'family',
   'est', NULL, TRUE, '난임 치료비 지원 (그룹 채용사이트 삼성E&A 상세 기준 — 지원 한도 미기재)', 82),
  (@comp_id, 'child_edu', '학자금 지원 (유치원~대학교)', NULL, 'family',
   'est', NULL, TRUE, '유치원·고등학교·대학교 학자금을 국내외 모두 지원 (자녀 수 제한·지원 한도 미기재)', 83),
  (@comp_id, 'event', '경조 지원·사옥 결혼식장 대관', NULL, 'family',
   'est', NULL, TRUE, '경조사 발생 시 경조금·휴가·장지용품 등 지원, 사옥 결혼식장 무료 대관 및 하객 주차 공간 제공 (경조별 금액·휴가 일수·대관 이용 자격 미기재)', 85),

  -- ── 근무 유연성 (flexibility) ──
  (@comp_id, 'flex_work', '자율출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '선택적 근로시간제를 운영해 개인 일정에 맞춰 출퇴근 시간을 자유롭게 관리 (정산 기간·코어타임 미기재. 그룹 채용사이트 삼성E&A 상세 기준)', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
