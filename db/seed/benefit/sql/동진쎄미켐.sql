-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 동진쎄미켐 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-05)
-- URL: https://dongjin.careerlink.kr/welfare
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 정본은 회사 전용 채용 서브도메인 dongjin.careerlink.kr 의 「복지 및 지원」 페이지다.
--       본사 GNB 「채용정보 > 채용 홈페이지」(common/js/link.js 의 link0501) 에서 직접 링크된다.
--       법인 일치 확인: __NEXT_DATA__ 의 coInf.rgno = 137-81-07814 이 본사 푸터 사업자등록번호와
--       일치하고 coNo == grpCoNo (CO202504082484) 라 그룹 계정이 아니라 법인 단독 계정이다.
--       ⚠ Next.js SPA 라 DOM 텍스트에는 복지 문구가 0자다. 내용은 전부 __NEXT_DATA__ JSON 의
--       dsgnInf.dsgnCntn.pages 에서 path==welfare 인 페이지의 sections[1].blocks[].settings 안
--       heading/body(RICHTEXT) 에 있다. 헤드리스 브라우저는 불필요하고 HTML 파싱은 0건이 난다.
--       ⚠ 보조 출처 = 본사 도메인 www.dongjin.com/recruit/hr02.php?pNum=1 (복리후생제도 탭).
--       그 페이지 본문은 JPEG 1장(img_hr02_02.jpg, 1200x1660) 안이라 이미지 판독이 유일한 경로이고,
--       GNB 가 전부 javascript:linkXXXX() 라 경로는 common/js/link.js 를 파싱해야 나온다.
--       ⚠ 두 출처가 충돌한다. 이미지본은 푸터가 COPYRIGHT 2019 이고 통근버스를 「주요 지역」,
--       기숙사를 「주요 사업장마다」라고 하는데, 정본(2025년 개설)은 셔틀버스를 경기 화성 사업장,
--       기숙사를 화성·시화·음성으로 한정한다. 신본인 정본을 채택했고 넓은 쪽 서술은 버렸다.
--       보조 출처에만 있는 항목(사내동호회·휘트니스센터)과 보조 출처가 준 상세는
--       QUAL_DESC 에 「본사 인사제도 페이지 2019」로 출처를 항목 단위 표시했다.
--       ⚠ UA 에 리터럴 CCBot 이 들어가면 본사 도메인이 302 디코이(kuipernet.com)로 흘린다.
--       재수집기가 UA 를 바꾸면 PNG 를 HTML 로 파싱해 조용히 0건이 된다.
--       금액: 정본의 신입 초임(대졸 5,040만원·생산직 4,100만원)은 복지가 아니라 급여라 제외했다.
--       직무발명포상 「최대 1,000만원」은 지급액이 아니라 상한이라 AMT 로 넣지 않고 정성 기재했다.
--       그 결과 20행 전부 BENEFIT_AMT NULL · QUAL_YN TRUE 이며, 신규 회사라 승계 앵커도 없어
--       타사 금액을 끌어오지 않았다(금액 stated 0건 · estimated 0건).
--       법정 제도(4대보험·퇴직연금·주5일·법정 연차·법정 출산육아휴직)는 두 출처 모두 언급이 없고
--       수록도 하지 않았다. 연차 행은 법정 연차가 아니라 반차·반반차 분할 운영이 근거다.
--       신규 코드 1건: degree_allowance (사유는 evidence 참조).
--       ⚠ 검증·감사 판정 반영(2026-09-05): SORT 11 박사 학위자 수당(degree_allowance)
--       삭제로 20 → 19행, 신규 코드 0. 급여성 수당이고 박사 학위자 한정이라 복지 행의
--       대상 요건을 넘는다 — 코퍼스에 수당 코드 선례가 없다. 삭제 뒤 SORT 12·13 은
--       재번호하지 않았다(구멍 허용). 사용자 노출 3필드의 편집 주석도 걷어냈다.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('dongjin_semichem', '동진쎄미켐',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체소재', 'D', 'https://dongjin.careerlink.kr/welfare');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'dongjin_semichem');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다 — 재실행 멱등)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://dongjin.careerlink.kr/welfare'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) — 정본 카드 2 「추가 보상」 + 보조 출처 포상제도 5종 ──
  (@comp_id, 'incentive', '인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '인센티브 별도 지급 (연 2회) — 지급률·산정 기준·금액 미기재', 10),
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 포상제도 운영. 10년 이상 장기근속자에게 포상금 수여 (10년 기준은 본사 인사제도 페이지 2019 기준 — 포상금액 미기재)', 12),
  (@comp_id, 'excellence_award', '신제품 개발·직무발명·원가혁신·우수사원 포상', NULL, 'compensation',
   'est', NULL, TRUE, '각종 포상제도 운영. 신제품 개발 포상(매출기여도·기술성·시장성 평가), 직무발명포상(특허 출원·등록 시 최대 1,000만원 상한), 원가혁신과제 포상, 모범·우수사원 공로포상 (4종 상세는 본사 인사제도 페이지 2019 기준 — 포상금액 미기재)', 13),

  -- ── 휴가 (time_off) — 정본 카드 3 「하계휴가 & 유연한 연차」 ──
  (@comp_id, 'summer_leave', '하계휴가', NULL, 'time_off',
   'est', NULL, TRUE, '하계휴가 별도 운영 — 법정 연차와 별도로 운영한다는 서술만 있고 부여 일수·시기 미기재', 20),
  (@comp_id, 'leave_general', '연차·반차·반반차', NULL, 'time_off',
   'est', NULL, TRUE, '연차, 반차, 반반차 제도 운영 — 분할 한도·사용 조건 미기재', 21),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '휴양시설(콘도)', NULL, 'leisure',
   'est', NULL, TRUE, '휴양시설(콘도) 이용 지원. 전국 주요 관광지 콘도, 대명리조트·한화리조트 등 30여개 지역 (제휴처 목록은 본사 인사제도 페이지 2019 기준 — 이용 조건·지원 한도 미기재)', 30),
  (@comp_id, 'welcome_kit', '입사일 Welcome Box', NULL, 'leisure',
   'est', NULL, TRUE, '입사일 Welcome Box(기초 필요물품) 지급 — 구성품·금액 미기재', 31),
  (@comp_id, 'club', '사내동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내동호회 활동을 권장하며 활동비 지급. 축구·탁구·야구·산악회 등 (본사 인사제도 페이지 2019 기준 — 공식 채용 페이지에는 없는 항목. 활동비 금액 미기재)', 32),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'birthday_gift', '기념일 기프트카드', NULL, 'perks',
   'est', NULL, TRUE, '기념일 기프트카드 지급 (생일, 결혼기념일) — 지급 금액 미기재', 40),
  (@comp_id, 'meal', '사내식당·식대 지원', NULL, 'perks',
   'est', NULL, TRUE, '사내식당 운영 또는 식대 지원. 사업장·연구소 구내식당에서 조식·중식·석식·간식 제공하고 구내식당이 없는 경우 식대 지원 (끼니 구성은 본사 인사제도 페이지 2019 기준 — 식대 단가 미기재라 금액 환산 불가)', 41),
  (@comp_id, 'commute_subsidy', '출퇴근 셔틀버스', NULL, 'perks',
   'est', NULL, TRUE, '출/퇴근 셔틀버스 운영 (경기 화성 사업장 운영) — 사업장 한정 항목이다. 노선·운행 횟수 미기재', 42),
  (@comp_id, 'transport', '출퇴근 유류비·통행료 지원', NULL, 'perks',
   'est', NULL, TRUE, '출/퇴근 유류비 및 통행료 지원 — 지원 한도·대상 범위·금액 미기재', 43),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀학자금', NULL, 'family',
   'est', NULL, TRUE, '고등학생 자녀부터 자녀학자금 지급 — 대상 학교급 하한만 명시되고 지원 한도·자녀 수 제한·금액 미기재', 50),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조금 및 상조 서비스 지원, 사우회 운영. 결혼·출산·상조 등 경조사 발생 시 축하금 및 위로금 지급, 경조휴가 지원 (경조휴가·경조 범위는 본사 인사제도 페이지 2019 기준 — 경조금액·휴가 일수 미기재)', 51),
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '자녀 육아 지원을 위한 직장 어린이집 운영 (경기 화성 사업장 운영) — 사업장 한정 항목이다. 정원·대상 연령 미기재', 52),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '직무 교육비 지원', NULL, 'growth',
   'est', NULL, TRUE, '직무 역량 강화를 위한 교육비 지원 — 지원 한도·대상 과정 미기재', 60),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '기숙사 지원 (경기 화성, 시화, 음성 사업장) — 공식 채용 페이지 기준 3개 사업장 한정. 본사 인사제도 페이지 2019 는 주요 사업장마다로 표기. 부담금·입주 조건 미기재', 70),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', NULL, 'health',
   'est', NULL, TRUE, '본인 건강검진 연 1회 지원 — 본인 한정이고 가족 포함 여부 언급 없음. 검진 항목·비용 미기재', 80),
  (@comp_id, 'fitness', '사내 휘트니스센터', NULL, 'health',
   'est', NULL, TRUE, '사업장 내 휘트니스센터 운영 (본사 인사제도 페이지 2019 기준 — 공식 채용 페이지에는 없는 항목. 운영 사업장·이용 조건 미기재)', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
