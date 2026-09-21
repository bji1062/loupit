-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 대한전선 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-14)
-- URL: https://www.taihan.com/company/talentSystem
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 대한전선 공식 도메인(www.taihan.com) COMPANY > 인재경영 > 인사제도 페이지의
--       「복지제도」 섹션 한 곳이다. 제목 「인사제도ㅣ인재경영 | COMPANY | 대한전선」, 메타 설명
--       「대한전선의 인사제도를 소개합니다.」 — 자기 도메인 + 법인명 명시라 귀속 조건이 붙지 않는다.
--       서버렌더(SSR) HTML 에 항목명(dt)·설명(dd) 8쌍이 텍스트로 있다. 헤드리스·이미지 판독 불필요.
--       ⚠ 채용정보(/company/jobs)는 복지 0건이고 호반그룹 채용사이트(recruit.ihoban.co.kr)로 내보낸다.
--         그 사이트의 「사내 복지」 약 20항목은 주어가 「호반」인 그룹 공통 서술(대한전선 0회)이라
--         한 건도 섞지 않았다. 호반 ATS(hoban.recruiter.co.kr)는 robots 전면 금지라 요청하지 않았다.
--       원문 8항목 → 「선물 지급(생일, 출산, 명절, 창립기념일 등)」 1항목만 코드 기준으로
--         birthday_gift(생일) + holiday_gift(명절·창립기념일) + parenting(출산) 3행으로 나눴다 → 10행.
--         나머지 7항목은 1:1. 같은 코드 병합 0건. 신규 코드 0. 원문 항목이 적어 행을 억지로 늘리지 않았다.
--       금액: 원 단위 표기 0건. 「학자금 전액」은 정성 조건이라 금액이 아니다 → 10행 전부 NULL.
--       법정 제도 서술은 페이지에 없다. 경조사 지원의 「휴가 부여」는 법정 제도가 아니라 event 서술에 남겼다.
--       제외: 같은 페이지 인재육성 4항목(신입사원 육성·직무교육·글로벌 교육·자기 계발 지원)은
--         회사 주도 교육이고 비용 지원 문구가 없어 행이 아니다. 인재상 3종도 행 아님.
--       ⚠ 휴양시설 원문의 「리솜리조트(계열사 혜택)」 단서는 서술에 그대로 보존했다.
--       ⚠ 복지 블록 주석의 수정 표식이 2022-10 에서 멈춰 있다 — 내용이 그 시점 기준일 수 있다.
--       ⚠ www.taihan.com TLS 인증서가 2026-09-29 만료 — 재수집 전 갱신 확인, -k 우회 금지.
--       ⚠ apex(taihan.com)는 301 → www. 항상 www 로 호출.
--       ⚠ 검증·감사 판정 반영(2026-09-15): 행 조치 없음(10행 그대로). 선물 지급 1항목의 3행 분해(SORT 11·20·30)를 유지한다.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ⚠ 데이터 정리 2차(2026-09-21): SORT 31 문안 교체. db/migrations/20260921_data_cleanup_2.sql 동봉.
-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('taihan', '대한전선',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '전선/전력', 'T', 'https://www.taihan.com/company/talentSystem');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'taihan');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.taihan.com/company/talentSystem'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀 학자금', NULL, 'family',
   'est', NULL, TRUE, '중학교, 고등학교, 대학교 자녀 학자금 전액 지급 (공식 인사제도 페이지 복지제도 자녀 학자금 항목 — 자녀 수 제한·지급 대상 요건 미기재)', 10),
  (@comp_id, 'parenting', '출산 선물', NULL, 'family',
   'est', NULL, TRUE, '선물 지급 항목의 출산 선물 (공식 인사제도 페이지 복지제도 — 선물 종류·금액 미기재)', 11),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조금, 경조화환, 장례용품 지급 및 휴가 부여 (공식 인사제도 페이지 복지제도 경조사 지원 항목 — 경조 구분별 금액·휴가 일수 미기재)', 12),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'birthday_gift', '생일 선물', NULL, 'perks',
   'est', NULL, TRUE, '선물 지급 항목의 생일 선물 (공식 인사제도 페이지 복지제도 — 선물 종류·금액 미기재)', 20),
  (@comp_id, 'meal', '사내식당', NULL, 'perks',
   'est', NULL, TRUE, '구내식당 운영 (공식 인사제도 페이지 복지제도 사내식당 항목 — 제공 끼니·식대 부담 여부 미기재)', 21),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '본사 및 공장 출퇴근 버스 운행 (공식 인사제도 페이지 복지제도 통근버스 항목 — 노선·요금 부담 미기재)', 22),

  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'holiday_gift', '명절·창립기념일 선물', NULL, 'compensation',
   'est', NULL, TRUE, '선물 지급 항목의 명절·창립기념일 선물 (공식 인사제도 페이지 복지제도 — 선물 종류·금액·연간 지급 횟수 미기재)', 30),
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 포상 (공식 인사제도 페이지 복지제도 포상 항목 — 근속 연수 기준·포상 내용·금액 미기재)', 31),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '사원숙소', NULL, 'work_env',
   'est', NULL, TRUE, '공장 및 해외 근무자 숙소 제공 (공식 인사제도 페이지 복지제도 사원숙소 항목 — 공장·해외 근무자 대상, 숙소 형태·본인 부담 미기재)', 40),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '휴양시설', NULL, 'leisure',
   'est', NULL, TRUE, '리솜리조트(계열사 혜택), 무주리조트 이용 지원 (공식 인사제도 페이지 복지제도 휴양시설 항목 — 이용 한도·지원 금액 미기재)', 50)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
