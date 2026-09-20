-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 동국제약 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-19)
-- URL: https://www.dkpharm.co.kr/hr/welfare.php
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 자기 도메인 www.dkpharm.co.kr 의 채용안내 > 인사 및 복리후생 페이지
--       한 곳이다. openresty + PHP 서버렌더 HTML 이라 헤드리스가 필요 없고, 항목은
--       div.contents-wrap.welfare-contents-wrap3 > ul.welfare-ul 안 가시 텍스트다.
--       이 호스트는 robots.txt 자체가 없다(302 → soft-404 오류 페이지) = 규칙 부재 → 허용.
--       ⚠ li 는 7개인데 항목은 8개다. 3번 li 원문이 자녀 학자금 지원 + br + 단체 상해보험
--          가입 이라 br 을 개행으로 치환해 쪼갰다. 안 쪼개면 없는 제도 1행이 생긴다.
--          회사 CSS 가 li:nth-child(1)~(7) 로 아이콘을 7장만 깔아 스스로 7칸으로 그린다.
--       ⚠ 복리후생 목록 밖 급여 블록의 보너스(600%)는 연 상여 비율이지 금액이 아니다.
--          BENEFIT_AMT 에 넣지 않았다. 같은 블록의 근무시간 09:00~18:00 (주5일 근무) 도
--          근무 조건이라 복지 행이 아니다(주5일은 법정). 성과급 α 는 급여 구성이라 제외.
--       ⚠ 채용 ATS dkpharm.recruiter.co.kr 은 통째로 포기했다. /career/welfare 는 법인
--          귀속이 확실하지만 Next.js CSR 이라 원본 HTML 에 항목이 0개이고, 본문을 주는
--          api-builder.recruiter.co.kr · api-recruiter.recruiter.co.kr 이 둘 다
--          User-agent: * / Disallow: / 다. 헤드리스 렌더도 그 API 를 때리므로 금지다.
--          회사 홈 GNB 채용공고가 가리키는 /appsite/* 도 Disallow: /app* 로 금지다.
--          → 이 회사의 합법적 복지 출처는 자기 도메인 8항목이 전부다(리드 확인: 8행이면 8행).
--       원문 8항목 → 8행. 복합 라벨 2개(경조휴가+경조금 · 우수사원 표창+해외연수)는
--       각각 event · excellence_award 한 코드로 귀결돼 분해하지 않고 서술에 양쪽을 담았다.
--       금액: 페이지에 원 단위 금액이 0건 → 8행 전부 BENEFIT_AMT NULL · QUAL_YN TRUE.
--       신규 회사라 승계할 앵커가 없고 타사 금액을 끌어오지 않았다.
--       법정 제도 미수록: 목록에 4대보험·퇴직연금·연차·출산휴가류가 애초에 0건이라
--       걸러낼 행이 없다. 주5일 근무는 위 이유로 행에도 서술에도 넣지 않았다.
--       ⚠ 신규 코드 1개: welfare_fund. 기존 welfare_fund_loan(n=2)은 대출을 뜻하는데
--          원문은 사내 근로복지기금 운영 까지만 말하고 대출을 언급하지 않는다.
--          대출로 쓰면 원문에 없는 내용을 단언하게 된다. 감사가 축 통합을 택하면
--          이 한 줄 코드를 welfare_fund_loan 으로 바꾸면 된다(evidence 신규 코드 절).
--       ⚠ TLS 인증서가 2026-12-03 만료다. 그 이후 재수집 시 체인부터 확인할 것.
--       ⚠ 이 서버는 없는 주소에도 302 → 200 오류 페이지를 준다. 존재 확인은 상태코드가
--          아니라 본문 문자열(요청하신 페이지를 찾을 수 없습니다)로 해야 한다.
--       ⚠ 유사 도메인 전부 출처 아님: dongkook.co.kr(빈 frameset 주차) ·
--          mobile.dkpharm.co.kr(TLS 이름 불일치 + IIS 404, 어디서도 링크 안 됨) ·
--          dkls.co.kr 동국생명과학(별도 상장 법인) · centellian24.com · dkbrand.co.kr ·
--          edkshop.com(브랜드/커머스). ESG SOCIAL 페이지는 본문 이미지 5장이 전부 302 로
--          죽어 지금 빈 화면이라 출처가 못 된다.
--       ⚠ 검증·감사 판정 반영(2026-09-19): 8 → 9행. SORT 51 bonus(보너스 600퍼센트) 추가 — 비율은 금액이
--       아니라 BENEFIT_AMT NULL. SORT 10 welfare_fund 는 신규 코드로 채택됐다(HL만도 SORT 41 이 같이 들어와
--       n=2). 위 ⚠ 의 welfare_fund_loan 전환 가정은 폐기한다.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('dongkook_pharm', '동국제약',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '제약', 'D', 'https://www.dkpharm.co.kr/hr/welfare.php');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'dongkook_pharm');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.dkpharm.co.kr/hr/welfare.php'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_fund', '사내 근로복지기금 운영', NULL, 'perks',
   'est', NULL, TRUE, '공식 채용 페이지 복리후생 항목의 사내 근로복지기금 운영 (기금 지원 내용·대상·한도 미기재)', 10),
  (@comp_id, 'pension_support', '개인연금보험 가입지원', NULL, 'perks',
   'est', NULL, TRUE, '공식 채용 페이지 복리후생 항목의 개인연금보험 가입 지원 (회사 부담 비율·지원 금액 미기재)', 11),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '경조휴가 및 경조금 지원', NULL, 'family',
   'est', NULL, TRUE, '공식 채용 페이지 복리후생 항목의 경조휴가와 경조금 지원 (경조사 범위·휴가 일수·지급액 미기재)', 20),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '공식 채용 페이지 복리후생 항목의 자녀 학자금 지원 (대상 학교급·자녀 수·지원 한도 미기재)', 21),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'insurance', '단체 상해보험 가입', NULL, 'health',
   'est', NULL, TRUE, '공식 채용 페이지 복리후생 항목의 단체 상해보험 가입 (보장 범위·보험료 부담 주체 미기재)', 30),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'club', '사내 동아리활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '공식 채용 페이지 복리후생 항목의 사내 동아리활동 지원 (활동비·동아리 수 미기재)', 40),
  (@comp_id, 'resort', '휴양시설(콘도) 지원', NULL, 'leisure',
   'est', NULL, TRUE, '공식 채용 페이지 복리후생 항목의 휴양시설 콘도 지원 (제휴처·이용 조건·이용료 미기재)', 41),

  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'excellence_award', '우수사원 표창 및 해외연수', NULL, 'compensation',
   'est', NULL, TRUE, '공식 채용 페이지 복리후생 항목의 우수사원 표창과 해외연수 (선발 기준·포상 금액·연수 지역 미기재)', 50),
  (@comp_id, 'bonus', '보너스(600%)', NULL, 'compensation',
   'est', NULL, TRUE, '공식 채용 페이지 급여 항목의 연 보너스 600퍼센트와 성과급 (지급 시기·산정 기준 미기재)', 51)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
