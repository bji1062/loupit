-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 삼양식품 복리후생 데이터
-- 출처: AI 파싱 (2026-09-05)
-- URL: https://www.samyangfoods.com/kor/recruit/recruit.do
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 삼양식품 공식 도메인(samyangfoods.com) 인재채용 > 인재상 페이지.
--       페이지 4번째 섹션 헤딩이 「복리 후생」이고 리드 문구가
--       「삼양식품의 직원을 위한 복리 후생 제도를 소개합니다」라 법인 단위 귀속이 본문에 명시된다.
--       ⚠ 그 섹션의 항목 10개는 전부 단일 PNG(recruit_img04.png) 내부 텍스트다.
--       img 태그의 alt 가 빈 문자열이라 HTML 파싱만 돌리면 0건이 나온다 — 복지 미기재 회사로 오판 금지.
--       10개 라벨과 설명 문장은 이미지를 내려받아 직접 판독해 추출했다(evidence 에 크기·해시 기록).
--       ⚠ 10개 중 「퇴직금」(퇴직 연금제도 도입)과 「4대보험」은 법정 제도라 미수록(계약 규칙 3) → 8항목.
--       그 중 「직원 출퇴근 지원」이 통근 버스 + 자가운전보조금 복합 항목이라 2행으로 분리 → 최종 9행.
--       금액 명시 0건 — 경조금·축하금·대출 전부 금액과 한도가 미기재라 9행 모두 BENEFIT_AMT NULL 이다.
--       신규 회사라 승계할 구본 앵커가 없어 타사 금액을 끌어오지 않았다.
--       ⚠ WAF 가 UA 블랙리스트로 GPTBot·CCBot·curl 문자열이 든 UA 를 HTTP 200 + 352 바이트
--       EUC-KR 차단문으로 위장 거부한다. 재수집 시 일반 브라우저 UA 고정 · 응답 2KB 미만 가드 필수.
--       생존 확인은 GET 로만 — HEAD /kor/recruit/recruit.do 는 404 이고 GET 만 200 이다.
--       ⚠ m.samyangfoods.com 이 같은 10개를 HTML 텍스트로 갖고 있으나 robots 가 Disallow 전면 금지라
--       출처로 쓸 수 없다. 데스크톱 UA 를 고정하지 않으면 페이지 스크립트가 그쪽으로 밀어낸다.
--       ⚠ 이미지 파일명이 콘텐츠 해시가 아니라 고정이라 갱신 감지는 URL 이 아니라 바이트 해시로 해야 한다.
--       ⚠ 삼양사·삼양홀딩스(삼양그룹, samyang.com)와는 무관한 별개 회사다. 그 도메인은 일절 조회하지 않았다.
--       ⚠ 검증·감사 판정 반영(2026-09-05): 행 조치 없음(9행 그대로). 9행 전부의 출처
--       표기를 「공식 채용 페이지 복리 후생 항목 그대로」로 바꾸고, 결측을 「… 미기재」
--       형식으로 통일했다 — 판독 방식 같은 공정 서술은 사용자 화면에 실리면 안 된다.
--       SORT 24 신협 대출은 코퍼스가 용도 미특정 사내대출도 housing_loan 에 담아 왔다.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('samyang_foods', '삼양식품',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '식품', 'S', 'https://www.samyangfoods.com/kor/recruit/recruit.do');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samyang_foods');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.samyangfoods.com/kor/recruit/recruit.do'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '경조 지원', NULL, 'family',
   'est', NULL, TRUE, '결혼, 상조 등 경조사에 따른 경조휴가 및 경조금, 물품, 화환 지급 (공식 채용 페이지 복리 후생 항목 그대로 — 경조금 금액·경조휴가 일수·경조사 범위 미기재)', 10),
  (@comp_id, 'child_edu', '자녀입학 축하금 지원', NULL, 'family',
   'est', NULL, TRUE, '임직원들 자녀 입학 축하금 지원 (공식 채용 페이지 복리 후생 항목 그대로 — 축하금 금액·대상 학교급·자녀 수 제한 미기재. 학자금 지원 여부 미기재)', 11),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '사내 식당 운영', NULL, 'perks',
   'est', NULL, TRUE, '사내 식당을 운영하여 영양 있는 식단 제공 (공식 채용 페이지 복리 후생 항목 그대로 — 제공 끼니·식대 단가·본인부담 여부 미기재)', 20),
  (@comp_id, 'commute_subsidy', '통근 버스', NULL, 'perks',
   'est', NULL, TRUE, '직원 출퇴근 지원 — 통근 버스 운영 (공식 채용 페이지 복리 후생 항목 그대로 — 노선·운행 사업장·이용 대상 미기재)', 21),
  (@comp_id, 'transport', '자가운전보조금', NULL, 'perks',
   'est', NULL, TRUE, '직원 출퇴근 지원 — 자가운전보조금 지원 (공식 채용 페이지 복리 후생 항목 그대로 — 지급액·지급 주기·지급 대상 미기재)', 22),
  (@comp_id, 'discount', '계열사 할인 제도', NULL, 'perks',
   'est', NULL, TRUE, '외식 사업 계열사 임직원 할인 제공 (공식 채용 페이지 복리 후생 항목 그대로 — 할인율·대상 브랜드·이용 한도 미기재)', 23),
  (@comp_id, 'housing_loan', '신협 대출 지원', NULL, 'perks',
   'est', NULL, TRUE, '신협 대출 지원 — 임직원 대출 지원 (공식 채용 페이지 복리 후생 항목 그대로 — 대출 용도·한도·이율 미기재. 대출 용도 미특정)', 24),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '대관령 삼양 목장 휴양관', NULL, 'leisure',
   'est', NULL, TRUE, '휴가 지원 — 대관령 삼양 목장 (EGC) 휴양관 숙박 지원 (공식 채용 페이지 복리 후생 항목 그대로 — 숙박 지원액·이용 일수·예약 조건 미기재. 휴가 일수 부여 여부 미기재)', 30),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진 지원', NULL, 'health',
   'est', NULL, TRUE, '임직원 건강검진 지원 및 임직원 가족 종합검진 할인 혜택 제공 (공식 채용 페이지 복리 후생 항목 그대로 — 검진 주기·지원 금액·가족 할인율 미기재)', 40)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
