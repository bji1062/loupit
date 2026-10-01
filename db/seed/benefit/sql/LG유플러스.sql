-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LG유플러스 복리후생 데이터
-- 출처: AI 파싱 (2026-10-01)
-- URL: https://www.lguplus.com/about/ko/career/human-resources
-- badge: est
--
-- 참고:
--   정본은 법인 자기 도메인 www.lguplus.com 의 회사소개 > 인재채용 > 인사제도 페이지(/about/ko/career/human-resources).
--   탭 3개(인재육성 · 평가 및 보상 · 복리후생)이고 복리후생 탭은 7개 묶음 표(휴가 제도 · 무과금 휴대폰 · 주거 및 생활 지원 ·
--   건강 및 의료 지원 · 멀티포인트 제도 · 자기계발 및 여가활동 지원 · 그룹사 제품 할인 및 구매 혜택)다.
--   Next.js 앱 라우터 페이지라 탭 본문이 서버 응답의 RSC 데이터(self.__next_f)에 실려 있고, 헤드리스 렌더 1회로
--   복리후생 탭을 눌러 화면에 같은 표가 그려지는 것을 확인했다(같은 출처 요청만 허용, 23요청).
--   보조 출처(같은 도메인): 인재채용 > Culture 페이지(/about/ko/career/workplace-culture) — 스마트워킹데이 · PC OFF ·
--   강릉 워케이션 · 마음 건강 지원. SSR 본문.
--   robots: www.lguplus.com/robots.txt 에 User-agent: * 묶음이 없다(일반 UA 는 규칙 없음 = 허용). Claude 계열 봇 묶음도
--   Allow: / 이고 /about/ 을 막지 않는다. 꼬리말 법인명은 ㈜엘지유플러스 — 법인 전용 페이지라 그룹 각주를 달지 않았다.
--   LG 그룹 통합 채용 careers.lg.com 과 다른 LG 계열사 페이지는 보지 않았다.
--
--   금액: 원문 연액 1(welfare_point 연 300만 포인트, 1포인트 1원 기준 환산이라 추정치).
--     승계 추정치 5행(incentive 500 · child_edu 200 · health_check 100 · medical 100 · resort 50 — NOTE 끝에 (추정)).
--     구본 공식 수치 welfare_point 250 · telecom 180 은 원문에 그 숫자가 없어 승계하지 않았다(welfare_point 는 원문 300).
--     구본 추정치 event 50(경조금 1회성) · parenting 50(출산축하금 1회성)은 NULL.
--   구본에서 뺀 행: holiday_gift(명절 상여금) · lang(외국어 학습비) — 공식 원문 근거 없음.
--   재코딩: 없음.
--   제외: 법정 제도(연차 · 임신 중 검진 휴가 · 출산 전후 휴가 · 육아휴직 · 배우자 출산 휴가 · 육아기 근로시간 단축 —
--     복리후생 휴가 제도 육아지원 줄, 중장년 생애 설계 교육 · 정년 퇴직 예정자 교육 — 재취업지원서비스 의무 대상) ·
--     사내 교육 과정(온보딩 · 직무 · AX · 리더십 · 코칭 · LG 인화원 과정 · 어학 과정 · 학습데이 · 학습 플랫폼 · 커리어 워크숍) ·
--     사내 파트너스 센터 운영(내용 미기재) · CEO 타운홀 미팅 · 사내 소셜 플랫폼(혜택 아님) · 기본연봉.
--   SORT 섹션 순서 = 정본 페이지에서 카테고리가 처음 나온 순서
--     (growth 10 · compensation 20 · time_off 30 · family 40 · perks 50 · health 60 · leisure 70 · flexibility 80 — Culture 페이지).
-- 재수집(2026-10-01): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-01, RV-3-2): incentive 승계 금액 500 을 걷어 정성 행으로(원문이 인센티브와 경영성과급을 나눠 묶음 추정치가 맞지 않음) · edu_support 서술에서 사외 교육 기회 문장 제거(비용 지원 아님) — 최종 23행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('lg_uplus', 'LG유플러스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '통신', 'L', 'https://www.lguplus.com/about/ko/career/human-resources');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lg_uplus');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.lguplus.com/about/ko/career/human-resources'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 성장·커리어 (growth) — 인재육성 탭 · 복리후생 자기계발 ──
  (@comp_id, 'mba', '국내외 대학원 학위 과정', NULL, 'growth',
   'est', NULL, TRUE, '국내외 대학원 학위 과정 교육 기회 제공 (공식 인사제도 페이지 인재육성 사외 교육 항목 — 선발 기준·인원·비용 부담 범위 미기재)', 10),
  (@comp_id, 'edu_support', '학습비 지원', NULL, 'growth',
   'est', NULL, TRUE, '학습비 지원 (공식 인사제도 페이지 복리후생 자기계발 및 여가활동 지원 항목 — 지원 대상 교육·한도·비용 부담 범위 미기재)', 11),
  (@comp_id, 'career', '사내공모', NULL, 'growth',
   'est', NULL, TRUE, '정기·수시 사내공모 진행과 대상자 이동 전후 Care (공식 인사제도 페이지 인재육성 경력 개발 프로그램 이동/확장 단계 — 지원 자격·공모 주기 미기재)', 12),

  -- ── 보상·금전 (compensation) — 평가 및 보상 탭 ──
  (@comp_id, 'incentive', '인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '성과 기반 보상 제도 중 인센티브 (공식 인사제도 페이지 평가 및 보상 항목 — 지급 기준·지급률 미기재)', 20),
  (@comp_id, 'profit_sharing', '경영성과급', NULL, 'compensation',
   'est', NULL, TRUE, '성과 기반 보상 제도 중 경영성과급 (공식 인사제도 페이지 평가 및 보상 항목 — 지급 기준·지급률 미기재)', 21),

  -- ── 시간·휴가 (time_off) — 복리후생 휴가 제도 ──
  (@comp_id, 'refresh_leave', '리프레시 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '「리프레시 휴가」 제도 운영 (공식 인사제도 페이지 복리후생 휴가 제도 항목 — 부여 조건·휴가 일수 미기재)', 30),

  -- ── 가족·돌봄 (family) — 복리후생 휴가 제도 · 주거 및 생활 지원 ──
  (@comp_id, 'event', '경조금 및 경조 휴가', NULL, 'family',
   'est', NULL, TRUE, '경조금 및 경조 휴가 지원 (공식 인사제도 페이지 복리후생 휴가 제도 항목 — 경조 종류별 금액·휴가 일수 미기재)', 40),
  (@comp_id, 'child_edu', '자녀 학자금 지원', 200, 'family',
   'est', '자녀 학자금 지원 (공식 인사제도 페이지 복리후생 주거 및 생활 지원 항목 — 지원 학교급·한도·자녀 수 미기재) (추정)', FALSE, NULL, 41),
  (@comp_id, 'parenting', '입학자녀·자녀출산 축하 프로그램', NULL, 'family',
   'est', NULL, TRUE, '입학자녀 축하 프로그램과 자녀출산 축하 프로그램 운영 (공식 인사제도 페이지 복리후생 주거 및 생활 지원 항목 — 축하 내용·금액 미기재)', 42),
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '사내 어린이집 운영 (공식 인사제도 페이지 복리후생 주거 및 생활 지원 항목 — 설치 사업장·정원 미기재)', 43),

  -- ── 경제적 부가혜택 (perks) — 무과금 휴대폰 · 주거 · 멀티포인트 · 그룹사 할인 ──
  (@comp_id, 'telecom', '무과금 휴대폰 (통신비 지원)', NULL, 'perks',
   'est', NULL, TRUE, '무과금 휴대폰, 매월 통신비 지원 (공식 인사제도 페이지 복리후생 무과금 휴대폰 항목 — 월 지원 금액·단말 지원 범위 미기재)', 50),
  (@comp_id, 'housing_loan', '주택자금 대출 이자지원', NULL, 'perks',
   'est', NULL, TRUE, '주택자금 대출 이자지원 (공식 인사제도 페이지 복리후생 주거 및 생활 지원 항목 — 대출 한도·이자 지원율 미기재)', 51),
  (@comp_id, 'welfare_point', '멀티포인트', 300, 'perks',
   'est', '멀티포인트 제도 운영, 연 300만 포인트 지급 (공식 인사제도 페이지 복리후생 멀티포인트 제도 항목 — 사용처 미기재, 1포인트 1원 기준 환산)', FALSE, NULL, 52),
  (@comp_id, 'discount', '패밀리카드·임직원몰', NULL, 'perks',
   'est', NULL, TRUE, 'LG계열사 제품을 할인 받을 수 있는 패밀리카드 지원과 임직원몰 운영 (공식 인사제도 페이지 복리후생 그룹사 제품 할인 및 구매 혜택 항목 — 할인율·구매 한도 미기재)', 53),

  -- ── 건강·의료 (health) — 복리후생 건강 및 의료 지원 · Culture 마음 건강 지원 ──
  (@comp_id, 'health_check', '종합건강검진', 100, 'health',
   'est', '종합건강검진 지원 (공식 인사제도 페이지 복리후생 건강 및 의료 지원 항목 — 검진 주기·가족 포함 여부 미기재) (추정)', FALSE, NULL, 60),
  (@comp_id, 'mental', '심리상담실·마음 건강 지원', NULL, 'health',
   'est', NULL, TRUE, '심리상담실 운영 (공식 인사제도 페이지 복리후생 건강 및 의료 지원 항목), 전국 50여개 상담센터와 전문 심리 상담가가 상주하는 마음의 숲, 온라인 명상 프로그램, 번아웃 예방 힐링 프로그램 (공식 Culture 페이지 마음 건강 지원 항목) — 상담 횟수 한도 미기재', 61),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '의료비 지원 (공식 인사제도 페이지 복리후생 건강 및 의료 지원 항목 — 지원 한도·가족 범위 미기재) (추정)', FALSE, NULL, 62),

  -- ── 여가·라이프 (leisure) — 복리후생 자기계발 및 여가활동 지원 ──
  (@comp_id, 'sports_ticket', '야구·축구 경기 입장권', NULL, 'leisure',
   'est', NULL, TRUE, '야구 및 축구 경기 입장권 지원 (공식 인사제도 페이지 복리후생 자기계발 및 여가활동 지원 항목 — 구단·제공 매수 미기재)', 70),
  (@comp_id, 'resort', '휴양시설 이용 및 할인', 50, 'leisure',
   'est', '휴양시설 이용 및 할인 (공식 인사제도 페이지 복리후생 자기계발 및 여가활동 지원 항목 — 시설명·할인율·이용 횟수 미기재) (추정)', FALSE, NULL, 71),
  (@comp_id, 'club', '사내 동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 지원 (공식 인사제도 페이지 복리후생 자기계발 및 여가활동 지원 항목 — 지원 금액·동호회 수 미기재)', 72),

  -- ── 근무유연성 (flexibility) — Culture 스마트한 업무 환경 ──
  (@comp_id, 'family_day', '스마트워킹데이 (1시간 조기 퇴근)', NULL, 'flexibility',
   'est', NULL, TRUE, '매월 둘째·셋째 주 수요일은 평소보다 1시간 일찍 퇴근하는 스마트워킹데이 (공식 Culture 페이지 스마트한 업무 환경 항목)', 80),
  (@comp_id, 'pc_off', 'PC OFF 제도', NULL, 'flexibility',
   'est', NULL, TRUE, '주 52시간 근무 시간을 초과하면 PC가 자동으로 꺼지는 PC OFF 제도 (공식 Culture 페이지 스마트한 업무 환경 항목)', 81),
  (@comp_id, 'workation', '강릉 워케이션', NULL, 'flexibility',
   'est', NULL, TRUE, '팀의 업무 효율과 협업을 위한 강릉 워케이션(Work+Vacation) 공간 조성 (공식 Culture 페이지 스마트한 업무 환경 항목 — 이용 주기·기간·비용 부담 미기재)', 82)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
