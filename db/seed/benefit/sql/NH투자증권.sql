-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- NH투자증권 복리후생 데이터
-- 출처: AI 파싱 (2026-09-28)
-- URL: https://nhqv-recruit2026.com/
-- badge: est
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 참고:
--   정본 = NH투자증권 2026년 상반기 대졸 신입사원 채용 페이지(nhqv-recruit2026.com). 꼬리말
--     COPYRIGHT© NH INVESTMENT & SECURITIES CO.,LTD. · 문의처가 법인 채용 사이트 nhqv.recruiter.co.kr 채용QnA.
--     서버 렌더 정적 HTML 본문의 section.benefitWrap 에 복리후생 9항목(dt/dd)이 그대로 있다(헤드리스 불필요).
--     robots.txt 는 없다(302 → 호스팅 404 페이지 — RFC 9309 상 제한 없음). 본문 sha256 3f0a2b29…c306de69.
--   법인 자기 도메인 www.nhsec.com · www.nhqv.com(→ nhsec.com 307) · m.nhsec.com · ir.nhsec.com 은
--     robots 가 User-agent * 에 Disallow / 라 본문을 요청하지 않았다. 법인 채용 사이트 nhqv.recruiter.co.kr 는
--     허용이지만 사이트맵 7경로(company · vision · procedure · form · job · jobs · home)에 복지 페이지가 없고
--     본문은 빌더 JSON 이라 발견 API(api-recruiter, robots 전면 금지)를 거쳐야 해 쓰지 않았다.
--   ⚠ 정본은 채용 캠페인 도메인이다 — 도메인 등록 2026-03-05 · 만료 2027-03-05(RDAP). 다음 공채 때 사라질 수 있다.
--   그룹(NH농협금융) 공통 페이지가 아니라 법인 단독 채용 페이지라 각주 없음.
--   법정 제도 제외: 퇴직금 · 연차수당(급여 항목 각주) · 재취업지원서비스는 원문에도 없다.
--   금액: 원문 연액 2(welfare_point 연 350만원 · holiday_gift 연 150만원) · 구본 추정 승계 1(resort 50, H1 틀 값).
--     의료비 가족 연 600만원은 한도라 정성 · 장기근속 포상금 150~550만원은 5년 단위 1회성이라 정성.
--   구본 11행 중 leave_general 1행 제외(원문 다양한 휴가 문구에 제도 이름 · 내용이 없음) · 기존 어휘 코드 3개 추가
--     (holiday_gift · long_service_bonus · mental) · 재코딩 0 · 신규 코드 0.
-- 재수집(2026-09-28): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-09-28, RV-3): 13행 전부 원문 확인 · 조치 없음 · 정본 캠페인 도메인 만료(2027-03-05) 전 재수집 후보 — 최종 13행

-- 1) 회사 등록 (기존 회사 — no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('nh_invest', 'NH투자증권',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '증권', 'N', 'https://nhqv-recruit2026.com/');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'nh_invest');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://nhqv-recruit2026.com/'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ── 복리후생 1 업계 최고 급여 · 2 복지카드 및 지원금 · 7 장기근속 포상
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '신입사원 초봉과 별도로 성과급 지급 (공식 채용 페이지 복리후생 업계 최고 급여 항목 — 지급 기준·지급률·금액 미기재)', 10),
  (@comp_id, 'holiday_gift', '명절·가정의 달 지원금', 150, 'compensation',
   'est', '명절과 가정의 달 지원금 연 150만원 (공식 채용 페이지 복리후생 복지카드 및 지원금 항목)', FALSE, NULL, 11),
  (@comp_id, 'long_service_bonus', '장기근속 포상금', NULL, 'compensation',
   'est', NULL, TRUE, '입사 후 매 5년 단위로 장기근속 포상금 150만~550만원 지급 (공식 채용 페이지 복리후생 장기근속 포상 항목 — 근속 연수별 지급액 미기재)', 12),

  -- ── 경제적 부가혜택 (perks) ── 복리후생 2 복지카드 및 지원금
  (@comp_id, 'welfare_point', '복지카드', 350, 'perks',
   'est', '복지카드 연 350만원 (공식 채용 페이지 복리후생 복지카드 및 지원금 항목)', FALSE, NULL, 20),

  -- ── 가족·돌봄 (family) ── 복리후생 3 경조사 지원 · 9 교육비 지원
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '본인과 가족의 경조사에 경조금, 휴가, 물품 제공 (공식 채용 페이지 복리후생 경조사 지원 항목 — 경조금 액수·휴가 일수 미기재)', 30),
  (@comp_id, 'child_edu', '교육비 지원', NULL, 'family',
   'est', NULL, TRUE, '국내·외 자녀 학자금과 PC 지원 (공식 채용 페이지 복리후생 교육비 지원 항목 — 지원 학년·금액·PC 지원 대상 미기재)', 31),

  -- ── 건강·의료 (health) ── 복리후생 4 의료비 지원 · 8 직원 지원 프로그램
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '본인 의료비 무제한, 가족 의료비 연간 600만원 한도 지원 (공식 채용 페이지 복리후생 의료비 지원 항목)', 40),
  (@comp_id, 'mental', '직원 지원 프로그램(EAP)', NULL, 'health',
   'est', NULL, TRUE, '직무, 심리정서, 가족 등 관련 전문가 상담 지원 (공식 채용 페이지 복리후생 직원 지원 프로그램 항목 — 이용 횟수·비용 부담 미기재)', 41),

  -- ── 근무유연성 (flexibility) ── 복리후생 5 Work&Life Balance
  (@comp_id, 'flex_work', '유연근무 제도', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무 제도 운영 (공식 채용 페이지 복리후생 Work&Life Balance 항목 — 제도 형태 미기재)', 50),
  (@comp_id, 'pc_off', 'PC-OFF 제도', NULL, 'flexibility',
   'est', NULL, TRUE, 'PC-OFF 제도 운영 (공식 채용 페이지 복리후생 Work&Life Balance 항목 — 적용 시각 미기재)', 51),

  -- ── 여가·라이프 (leisure) ── 복리후생 6 휴양소, 사내동호회 지원
  (@comp_id, 'resort', '휴양소 지원', 50, 'leisure',
   'est', '전국 50여 개 휴양소 이용 지원 (공식 채용 페이지 복리후생 휴양소, 사내동호회 지원 항목 — 지원 금액 미기재) (추정)', FALSE, NULL, 60),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '20여 개 사내 동호회 활동 지원 (공식 채용 페이지 복리후생 휴양소, 사내동호회 지원 항목 — 지원 금액 미기재)', 61),

  -- ── 시간·휴가 (time_off) ── 복리후생 7 장기근속 포상
  (@comp_id, 'long_service_leave', '안식년휴가', NULL, 'time_off',
   'est', NULL, TRUE, '입사 후 매 5년 단위로 안식년휴가 부여 (공식 채용 페이지 복리후생 장기근속 포상 항목 — 휴가 일수 미기재)', 70)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
