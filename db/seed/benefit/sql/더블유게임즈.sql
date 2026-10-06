-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 더블유게임즈 복리후생 데이터
-- 출처: AI 파싱 (2026-09-28)
-- URL: https://www.doubleugames.com/careers/workinghere.html
-- badge: est
--
-- 참고:
--   정본은 자기 도메인 www.doubleugames.com 의 CAREERS > 근무환경 페이지(/careers/workinghere.html) 안
--   복지제도 블록(아이콘 카드 19개 · 제목+설명 텍스트)이다. SSR HTML 이라 헤드리스 렌더 불필요.
--   robots.txt 는 User-agent: * 에 Allow: / 하나뿐이다.
--   같은 페이지의 재택근무 카드(월 중 재택 시행)는 HTML 주석 속 블록이라 싣지 않았다.
--   카드 아래 최상의 업무환경 사진 12장은 설명 문구가 없는 사진이라 행 근거로 쓰지 않았다.
--   보조 출처(같은 회사 공식 페이지): /careers/hr_system.html 인사제도(보상제도 인센티브 · 최고 성과자 포상) ·
--   /eng/careers/workinghere.html 영문 근무환경(헬스키퍼 = massage therapist · 복지포인트 매년 지급).
--   채용공고 게시판 /careers/jobs.html 은 모집중 · 마감 모두 게시물 0건이었다.
--
--   금액: 명시값 0행. 승계 추정치 3행(meal 432 · welfare_point 250 · resort 50 — NOTE 끝에 (추정)).
--     구본 공식 수치(holiday_gift 40 · long_service_leave 1000 · birthday_leave 30)는 공식 원문에 숫자가 없어 NULL.
--   재코딩 4: fitness → massage(헬스키퍼 = 사내 안마사) · long_service_leave → long_service_bonus(원문 장기근속 포상금, 휴가 없음) ·
--     lang → self_development(원문 자기계발비 지원 — 사내 어학 수업은 2026-10-04 규칙 8 개정으로 lang 새 행으로 다시 분리) · housing_loan → welfare_fund_loan(원문 사내 대출, 주택 용도 미기재).
--   제외: 재택근무(주석 블록) · 수면실/리프레쉬존 · 출산 경조금 · 도서/사내 도서관(원문 없음) ·
--     개인 프로필 촬영(대응 어휘 없음 — 신규 코드 후보로 근거표에 기재) · 직무교육 · 사내 세미나(회사 주도 교육).
--   SORT 섹션 순서 = 정본 페이지에서 카테고리가 처음 나온 순서
--     (perks 10 · growth 20 · leisure 30 · time_off 40 · compensation 50 · family 60 · health 70 · flexibility 80).
-- 재수집(2026-09-28): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-09-28, RV-3 레인 3): 18행 전부 원문 재확인, 시드 수정 0 — 운영 표적 DELETE 393 · 394 · 399 · 402(official 이라 시드 DELETE 로 안 지워짐), 재코딩 395 · 398 · 401 · 408 — 최종 18행
-- 후속 정리 2(2026-10-04, R-3): 사용자가 정한 복지 범위 규칙 개정(규칙 8 · 기준 13 · 기준 18 · 기준 20 · 기준 23)과 코퍼스 판정을 반영 — 새 행 1(lang) · 서술 · 이름 수정 1(self_development) — 최종 19행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 2026-10-06 식대 기준 금액 1끼 12,000원(리드 판정 (82)) — meal 행 금액 = 1끼 단가 × 끼니 × 연 240일, 꼬리에 식 공개

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('wgames', '더블유게임즈',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '게임', 'W', 'https://www.doubleugames.com/careers/workinghere.html');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'wgames');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.doubleugames.com/careers/workinghere.html'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '조·중·석식 무상 제공', 864, 'perks',
   'est', '조, 중, 석식 무상 제공 — 삼시세끼 무상 제공 (공식 채용 페이지 근무환경 복지제도 항목 — 식대 단가·제공 방식 미기재) (하루 3끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 10),
  (@comp_id, 'welfare_point', '선택적 복리후생제도 (복지포인트)', 250, 'perks',
   'est', '임직원 대상 복지포인트 매년 지급 (공식 채용 페이지 근무환경 복지제도 항목 — 연간 지급액·사용처 미기재) (추정)', FALSE, NULL, 11),
  (@comp_id, 'birthday_gift', '가족 생일 축하 선물·생일축하금', NULL, 'perks',
   'est', NULL, TRUE, '가족 생일 축하 선물 지급(꽃다발, 케이크 지원), 생일축하금 지급 (공식 채용 페이지 근무환경 복지제도 항목 — 생일축하금 금액 미기재)', 12),
  (@comp_id, 'snack_bar', '간식 무한 제공 (스낵bar)', NULL, 'perks',
   'est', NULL, TRUE, '언제든지 누구나 이용 가능한 스낵bar 제공 (공식 채용 페이지 근무환경 복지제도 항목 — 제공 품목 미기재)', 13),
  (@comp_id, 'welfare_fund_loan', '사내 대출 지원', NULL, 'perks',
   'est', NULL, TRUE, '근속 기간 충족 시 사내 대출 지원 (공식 채용 페이지 근무환경 복지제도 항목 — 대출 용도·한도·이율·근속 기준 미기재)', 14),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'self_development', '자기계발비 지원', NULL, 'growth',
   'est', NULL, TRUE, '구성원들의 자기계발을 위한 교육 지원 (공식 채용 페이지 근무환경 복지제도 항목 — 지원 한도·대상 교육 범위 미기재)', 20),
  (@comp_id, 'lang', '사내 어학 수업', NULL, 'growth',
   'est', NULL, TRUE, '구성원들의 자기계발을 위한 사내 어학 수업 등 교육 지원 (공식 채용 페이지 근무환경 복지제도 자기계발비 지원 항목 — 대상 언어·수업 방식 미기재)', 21),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'company_event', '전사 송년회·체육대회·워크샵', NULL, 'leisure',
   'est', NULL, TRUE, '전사 송년회, 구성원들의 리프레쉬를 위한 전사 체육대회, 전사(국내/외) 워크샵 (공식 채용 페이지 근무환경 복지제도 항목 — 개최 주기·장소 미기재)', 30),
  (@comp_id, 'resort', '콘도 지원', 50, 'leisure',
   'est', '가족, 친구와 함께 즐길 수 있는 콘도 지원 (공식 채용 페이지 근무환경 복지제도 항목 — 이용 횟수·본인 부담 미기재) (추정)', FALSE, NULL, 31),
  (@comp_id, 'club', '동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '활발한 취미활동을 위한 동호회 활동비 지원 (공식 채용 페이지 근무환경 복지제도 항목 — 지원 금액 미기재)', 32),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'leave_general', '연말 유급휴가·이사 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '연말 1일 유급휴가 지원, 자택 이사 시 이사휴가 1일 지원 (공식 채용 페이지 근무환경 복지제도 항목)', 40),
  (@comp_id, 'birthday_leave', '생일 당일 오후 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '생일자 당일 오후 반일 휴가 지원 (공식 채용 페이지 근무환경 복지제도 항목)', 41),

  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', '인센티브 (최대 기본 연봉 30%)', NULL, 'compensation',
   'est', NULL, TRUE, '반기 업적 평가에 따라 고성과자에게 기본 연봉의 최대 30%까지 인센티브 지급 (공식 채용 페이지 인사제도 보상제도 항목 — 지급 대상 비율 미기재)', 50),
  (@comp_id, 'holiday_gift', '명절상여금', NULL, 'compensation',
   'est', NULL, TRUE, '각종 상여금 가운데 명절상여금 지급 (공식 채용 페이지 근무환경 복지제도 항목 — 지급액·지급 횟수 미기재)', 51),
  (@comp_id, 'excellence_award', '우수직원 포상·최고 성과자 포상', NULL, 'compensation',
   'est', NULL, TRUE, '연 1회 우수직원 포상과 우수사원포상금, 연간 최고 성과자를 선정해 리프레시를 위한 여행 및 다양한 혜택 제공 (공식 채용 페이지 근무환경 복지제도 · 인사제도 보상제도 항목 — 포상금액·선정 인원 미기재)', 52),
  (@comp_id, 'long_service_bonus', '장기근속 포상금', NULL, 'compensation',
   'est', NULL, TRUE, '각종 상여금 가운데 장기근속 포상금 지급 (공식 채용 페이지 근무환경 복지제도 항목 — 근속 기준·포상금액 미기재)', 53),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '구성원들의 기쁨과 슬픔을 함께하는 다양한 경조사 지원 (공식 채용 페이지 근무환경 복지제도 항목 — 경조 항목·금액 미기재)', 60),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'massage', '헬스키퍼 운영', NULL, 'health',
   'est', NULL, TRUE, '근무시간 내 에너지 충전을 위한 사내 헬스키퍼(안마 서비스) 운영 (공식 채용 페이지 근무환경 복지제도 항목 — 이용 횟수·시간 미기재)', 70),

  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '유연근로제', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근로제 시행으로 필요한 시간대에 출퇴근 (공식 채용 페이지 근무환경 복지제도 항목 — 제도 유형·핵심 근무시간 미기재)', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
