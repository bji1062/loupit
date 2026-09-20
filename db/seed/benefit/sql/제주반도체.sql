-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 제주반도체 복리후생 데이터
-- 출처: AI 파싱 (2026-09-19)
-- URL: http://www.jeju-semi.com/kr/About/Welfare
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 제주반도체 자기 도메인(www.jeju-semi.com) 두 페이지다. 3자 사이트 인용 0건.
--       항목 정본 = 채용공고 http://www.jeju-semi.com/kr/About/RecruitDetail?No=25 (2026-08-06 게시)
--         본문이 이미지 1장뿐이다 → /kr/AdminPage/Upload/About/RecruitInfo/
--         2a52067fecb38ec5971c1301a74d121a.jpg · 860x2432 JPEG · 274,878B
--         sha256 bf49df21fb4d7d72295d655e24225e0ab3f2db12a7b4d9f3c06fe650ab35c9e8
--         Last-Modified Thu, 06 Aug 2026 07:39:14 GMT. 세로 4분할 2배 확대로 전 구획을 읽었고
--         복리후생 제도 표 11행 + 근무환경 조직 문화 5줄을 확보했다(구획 좌표는 evidence).
--       보조 = 인사/복지제도 http://www.jeju-semi.com/kr/About/Welfare (인사제도 4 + 복지제도 3, 설명·금액 없음).
--       ⚠ CAREERS_BENEFIT_URL 은 정본 공고가 아니라 인사/복지제도 페이지로 둔다. 공고는
--         모집 기한이 「채용시까지」라 마감되면 RecruitDetail 행과 UUID 이미지 URL 이 통째로 사라진다.
--         항목 출처는 행마다 evidence 에 이미지 URL 로 병기했다. 갱신 감지는 위 sha256 으로.
--       ⚠ 이 사이트는 HTTPS 가 없다 — 443 은 연결 타임아웃이다. URL 을 https 로 승격하는
--         렌더러·링크 감사에 걸린다. apex jeju-semi.com 은 NXDOMAIN 이라 www 가 필수다.
--         유사 도메인 jejusemi.com 은 매물 파킹이라 출처가 아니다.
--       ⚠ 공고가 3장(No=13·22·25)이고 서로 다르다. 최신 No=25 만 썼다. 2025년 장(No=13)의
--         복지포인트/카드 지원·도서문화생활비는 폐기된 문구라 한 줄도 쓰지 않았다.
--       ⚠ /kr/About/Welfare 원본 HTML 에는 문자열 제주반도체 가 0회다(제목도 Welfare - JSC).
--         회사명 문자열로 귀속을 확인하는 가드를 걸면 이 페이지가 걸러진다 — 도메인·푸터 주소로 확인할 것.
--       법정 제도는 수록하지 않았다: 4대 보험제도 운영, 주 5일제 근무 실시, 연차휴가 자체,
--         육아 지원 한 줄에 묶여 있던 출산 휴가·육아 휴직. 이 문구는 QUAL_DESC 에도 쓰지 않았다.
--       분할·병합: 육아 지원 → 출산 축하금·보육 수당만 parenting 1행(법정 2종 제외) ·
--         장기 근속자 리프레시 포상제도 → long_service_leave(휴가) + long_service_bonus(순금) 2행 ·
--         경조사는 공고와 인사/복지제도 페이지가 겹쳐 event 1행으로 합쳤다.
--       제외: 자유로운 복장 착용(자율복장은 원익IPS 반증으로 삭제된 유형) · 워라밸 존중 문구 ·
--         연봉제 적용과 직급 5단계(급여 체계) · 전형절차 3차 건강검진(채용 절차) · 근무조건 문구.
--       금액 5건 중 3건만 AMT 에 넣었다. 명절 상여(설·추석 각 250만원 → 연 500) ·
--         복리후생비(130~220만원 구간 → 상한 220, 코퍼스 표기값은 상한 관례) ·
--         문화생활비(월 2만원 → 연 24) · 주거비(월 50만원 → 연 600, 대상자 한정은 NOTE 에 명시).
--         10만원 상당 명절 선물은 지급 횟수가 없어 합산하지 않았다. 신규 회사라 승계할 앵커가 없어
--         타사 금액은 끌어오지 않았다.
--       ⚠ 판단이 갈리는 3건(복리후생비의 welfare_point 귀속 · 주거비 600 환산 · 문화생활비의
--         leisure_ticket 귀속)은 evidence 의 판단 절에 대안과 함께 적었다.
--       ⚠ 검증·감사 판정 반영(2026-09-19): 17행 그대로. SORT 31 금액 220 → 175(직급별 구간의 중간값) ·
--       SORT 32(600)·SORT 40(500) 은 조건부 급부라 금액을 NULL 로 내리고 QUAL_YN TRUE·QUAL_DESC 로 옮겼다 ·
--       SORT 43 에서 직무발명규정 삭제 · SORT 60 NOTE 교체.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('jeju_semi', '제주반도체',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체', 'J', 'http://www.jeju-semi.com/kr/About/Welfare');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'jeju_semi');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'http://www.jeju-semi.com/kr/About/Welfare'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 유연근무 (flexibility) — 공고 근무환경 조직 문화 ──
  (@comp_id, 'flex_work', '부서별 유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '공식 채용 공고 조직 문화 항목의 부서별 유연근무제 도입 — 적용 부서 범위·근무시간 운영 방식 미기재', 10),

  -- ── 휴가 (time_off) ──
  (@comp_id, 'leave_general', '반차·반반차 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '공식 채용 공고 조직 문화 항목의 반차·반반차 단위 분할 사용, 공식 인사/복지제도 페이지의 탄력적인 휴가제도 운용 — 부여 일수·사용 절차 미기재', 20),
  (@comp_id, 'long_service_leave', '장기 근속자 리프레시 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '공식 채용 공고 복리후생 제도 항목의 5년·10년 장기 근속자 리프레시 휴가 — 휴가 일수 미기재', 21),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'snack_bar', '사내 카페테리아 음료', NULL, 'perks',
   'est', NULL, TRUE, '공식 채용 공고 조직 문화 항목의 사내 카페테리아 음료 무한 제공', 30),
  (@comp_id, 'welfare_point', '복리후생비용 지원', 175, 'perks',
   'est', '공식 채용 공고 복리후생 제도 항목의 직급별 연간 통합복리후생비 130~220만원 지원 — 표기값은 직급별 구간의 중간값이고 실지급액은 직급에 따라 다르다. 포인트 형태·사용처 미기재', FALSE, NULL, 31),
  (@comp_id, 'housing_support', '신입사원 주거비 지원', NULL, 'perks',
   'est', NULL, TRUE, '공식 채용 공고 복리후생 제도 항목의 신입사원 주거비 지원 — 대상자에 한하여 2년간 월 50만원 지급, 대상자 선정 기준 미기재', 32),

  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'holiday_gift', '명절 상여금 및 선물', NULL, 'compensation',
   'est', NULL, TRUE, '공식 채용 공고 복리후생 제도 항목의 명절 상여금 및 선물 지원 — 설·추석 각 250만원 지급과 10만원 상당 명절 선물, 선물 지급 횟수 미기재', 40),
  (@comp_id, 'long_service_bonus', '장기 근속자 순금 포상', NULL, 'compensation',
   'est', NULL, TRUE, '공식 채용 공고 복리후생 제도 항목의 5년·10년 장기 근속자 순금 지원 — 순금 중량·금액 미기재', 41),
  (@comp_id, 'profit_sharing', '부가급여(Profit Sharing System)', NULL, 'compensation',
   'est', NULL, TRUE, '공식 인사/복지제도 페이지 인사제도 항목의 부가급여(Profit Sharing System) — 지급 기준·시기·금액 미기재', 42),
  (@comp_id, 'incentive', 'R&D 프로젝트 인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '공식 인사/복지제도 페이지 인사제도 항목의 R&D 프로젝트 수행에 따른 인센티브 지급 — 지급 기준·금액 미기재', 43),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '공식 채용 공고 복리후생 제도 항목의 결혼·회갑 등 경조사비 및 휴가 지원, 공식 인사/복지제도 페이지의 경조금지원(결혼, 회갑, 사망 등) — 경조금액·경조휴가 일수 미기재', 50),
  (@comp_id, 'parenting', '출산 축하금·보육 수당', NULL, 'family',
   'est', NULL, TRUE, '공식 채용 공고 복리후생 제도 항목 육아 지원의 출산 축하금과 보육 수당 — 지급액·지급 대상 조건 미기재', 51),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'leisure_ticket', '문화생활비 지원', 24, 'leisure',
   'est', '공식 채용 공고 복리후생 제도 항목의 월 2만원 문화생활체육비 지원, 표기값은 월 2만원 × 12개월', FALSE, NULL, 60),
  (@comp_id, 'resort', '소노 호텔&리조트 회원권', NULL, 'leisure',
   'est', NULL, TRUE, '공식 채용 공고 복리후생 제도 항목의 전국 소노 호텔&리조트 회원가 예약 지원 — 이용 한도·예약 조건 미기재', 61),
  (@comp_id, 'company_event', '전 직원 워크샵', NULL, 'leisure',
   'est', NULL, TRUE, '공식 채용 공고 복리후생 제도 항목의 전 직원 연 1~2회 제주도 워크샵과 액티비티 활동 지원 — 참가 대상 조건·지원 금액 미기재', 62),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합건강검진 지원', NULL, 'health',
   'est', NULL, TRUE, '공식 채용 공고 복리후생 제도 항목의 전 직원 종합검진비용 지원 — 검진 주기·검진 항목·금액 미기재', 70),

  -- ── 성장·교육 (growth) ──
  (@comp_id, 'edu_support', '직무·교양 교육비 지원', NULL, 'growth',
   'est', NULL, TRUE, '공식 채용 공고 복리후생 제도 항목의 연간 직무·교양 교육비 지원 — 지원 한도·대상 과정 미기재', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
