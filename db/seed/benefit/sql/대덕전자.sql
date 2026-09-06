-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 대덕전자 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-05)
-- URL: https://www.daeduck.com/ko/content/welfaresystem.do
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 대덕전자 공식 도메인(www.daeduck.com) RECRUIT 섹션 두 페이지다.
--       정본 = 복지제도(welfaresystem.do) — 5카테고리 18항목이 전부 SSR HTML 텍스트라
--       이미지 판독·헤드리스 렌더가 필요 없다(같은 업종 심텍과 정반대).
--       보조 = 인사제도(personnelsystem.do) 「교육 지원 제도」 5항목 중 규칙 8(명시적 비용
--       지원만 growth 행)을 통과한 「외국어 교육 지원」 1항목만 채택. 나머지 4항목은 회사 주도
--       커리큘럼이거나 임원 한정·채용 연계 프로그램이라 미수록(evidence 제외 목록 참조).
--       ⚠ 호스트는 반드시 www 를 붙일 것. apex(daeduck.com)는 연결 타임아웃, daeduck.co.kr 은
--         버려진 빈 frameset(223 B), recruit.daeduck.com 은 전 경로 404 인 죽은 호스트다.
--       ⚠ 본문 카피가 「대덕은 …」 이라 지주 ㈜대덕(daeduckholdings.com)으로 오인하기 쉽다.
--         귀속 근거는 푸터 「본사주소 … 대덕전자(주)」 + Copyright DAEDUCK ELECTRONICS Co.,Ltd.
--         이며, 지주 사이트에는 채용·복지 메뉴 자체가 없다. 보조 페이지는 본문에서
--         「대덕전자는 다양한 복리후생 프로그램을 운영하고 있습니다」 라고 법인명을 직접 쓴다.
--       두 페이지 어디에도 금액·한도·조건 수치가 없다 → 18행 전부 BENEFIT_AMT NULL ·
--       QUAL_YN TRUE. 신규 회사라 승계할 앵커도 없어 타사 금액을 끌어오지 않았다(stated 0건).
--       ⚠ 대출 2건(주택 구입자금·생활 안정자금)은 한도 표기 자체가 없다. 설령 있었더라도
--         대출 원금 한도는 연간 환산 금액이 아니다(CJ 5개사 선례 #38).
--       행 산정: 18항목 − 1(퇴직연금(IRP) 지원 = 법정 제도, 규칙 3 미수록)
--       − 1(대출 2건을 housing_loan 한 행으로 병합 — 삼성카드 선례 「주택·생활안정자금 대출」)
--       + 1(「주거 지원 운영 (사택, 기숙사)」 복합 라벨을 housing_support + dormitory 로 분리 —
--         심텍 복합 라벨 선례, 원익IPS 는 두 코드를 실제로 함께 보유)
--       + 1(보조 출처 lang) = 18행.
--       신규 BENEFIT_CD 0건 — 18행 전부 어휘표(85종)에 있는 기존 코드다.
--       ⚠ 검증·감사 판정 반영(2026-09-05): SORT 11 사택(housing_support)을 SORT 20
--       기숙사에 병합해 18 → 17행. 원문이 「주거 지원 운영 (사택, 기숙사)」 한 라벨인데
--       두 코드로 갈렸고 housing_support 는 코퍼스에서 주거비 현금 축이다. 사택·기숙사
--       같은 주거 시설은 dormitory 로 모은다. 편집 주석도 함께 걷어냈다.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('daeduck', '대덕전자',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        'PCB', 'D', 'https://www.daeduck.com/ko/content/welfaresystem.do');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'daeduck');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.daeduck.com/ko/content/welfaresystem.do'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) ── 원문 섹션 1 주거 지원 · 4 워라밸 · 5 기타
  (@comp_id, 'housing_loan', '주택 구입자금·생활 안정자금 대출', NULL, 'perks',
   'est', NULL, TRUE, '주택 구입자금 대출, 생활 안정자금 대출 (공식 복지제도 페이지 주거 지원 항목명 그대로 — 두 대출 모두 한도·이율·대상 조건 미기재)', 10),
  (@comp_id, 'welfare_point', '복지 포인트', NULL, 'perks',
   'est', NULL, TRUE, '복지 포인트 지급 (공식 복지제도 페이지 워라밸 항목명 그대로 — 연간 포인트 금액·사용처 미기재)', 12),
  (@comp_id, 'birthday_gift', '기념일 선물', NULL, 'perks',
   'est', NULL, TRUE, '기념일 선물 지급 (공식 복지제도 페이지 기타 항목명 그대로 — 대상 기념일·선물 금액 미기재)', 13),
  (@comp_id, 'meal', '사내식당', NULL, 'perks',
   'est', NULL, TRUE, '사내식당 운영 (공식 복지제도 페이지 기타 항목명 그대로 — 제공 끼니·식대 미기재)', 14),

  -- ── 근무환경 (work_env) ── 원문 섹션 1 주거 지원
  (@comp_id, 'dormitory', '사택·기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '주거 지원 운영 (사택, 기숙사) (공식 복지제도 페이지 주거 지원 항목명 그대로 — 대상·지역·운영 사업장·입주 조건 미기재)', 20),

  -- ── 건강·의료 (health) ── 원문 섹션 2 건강관리
  (@comp_id, 'health_check', '종합건강검진', NULL, 'health',
   'est', NULL, TRUE, '종합건강검진(배우자포함) (공식 복지제도 페이지 건강관리 항목명 그대로 — 배우자 포함은 명시, 주기·검진 항목·비용 지원액 미기재)', 30),
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '단체상해 보험 (공식 복지제도 페이지 건강관리 항목명 그대로 — 보장 범위·가입 대상·보험료 미기재)', 31),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '의료비 지원 (공식 복지제도 페이지 건강관리 항목명 그대로 — 지원 한도·대상 질병·가족 포함 여부 미기재)', 32),

  -- ── 가족·돌봄 (family) ── 원문 섹션 3 교육비(학자금) 지원 · 5 기타
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원 (공식 복지제도 페이지 교육비(학자금) 지원 항목명 그대로 — 대상 학교급·자녀 수·지원 한도 미기재)', 40),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원 (공식 복지제도 페이지 기타 항목명 그대로 — 경조금·경조휴가·화환 구분 미기재)', 41),

  -- ── 성장·커리어 (growth) ── 원문 섹션 3 교육비(학자금) 지원 + 보조 출처 인사제도 페이지
  (@comp_id, 'self_development', '자기 계발비 지원', NULL, 'growth',
   'est', NULL, TRUE, '자기 계발비 지원 (공식 복지제도 페이지 교육비(학자금) 지원 항목명 그대로 — 연간 한도·사용 범위 미기재)', 50),
  (@comp_id, 'lang', '외국어 교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '온라인 강좌, 전화 영어, 스마트 러닝 등 다양한 방식의 교육 진행으로 임직원들에게 교육 기회를 제공 (공식 인사제도 페이지 교육 지원 제도 — 지원 한도·본인 부담 비율 미기재)', 51),

  -- ── 근무 유연성 (flexibility) ── 원문 섹션 4 워라밸
  (@comp_id, 'flex_work', '자율출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '자율출퇴근제 운영 (공식 복지제도 페이지 워라밸 항목명 그대로 — 코어타임·정산 기간·적용 직군 미기재)', 60),

  -- ── 시간·휴가 (time_off) ── 원문 섹션 4 워라밸
  (@comp_id, 'leave_general', '연중휴가·휴가비 지원', NULL, 'time_off',
   'est', NULL, TRUE, '연중휴가 및 휴가비 지원 (공식 복지제도 페이지 워라밸 항목명 그대로 — 연중 사용 휴가 운영과 휴가비 지원을 한 항목으로 표기. 법정 연차 상회 일수·휴가비 지급액 미기재)', 70),

  -- ── 여가·라이프 (leisure) ── 원문 섹션 4 워라밸
  (@comp_id, 'club', '동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 지원 (공식 복지제도 페이지 워라밸 항목명 그대로 — 지원 금액·동호회 수 미기재)', 80),
  (@comp_id, 'resort', '콘도 지원', NULL, 'leisure',
   'est', NULL, TRUE, '콘도 지원 (공식 복지제도 페이지 워라밸 항목명 그대로 — 제휴 콘도·이용 조건·지원액 미기재)', 81),

  -- ── 보상·금전 (compensation) ── 원문 섹션 5 기타
  (@comp_id, 'long_service_bonus', '장기근속자 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속자 포상 (공식 복지제도 페이지 기타 항목명 그대로 — 근속 연차 기준·포상금·부상 미기재)', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
