-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ISC 복리후생 데이터 (신규 회사 — 웨이브 5)
-- 출처: AI 파싱 (2026-10-10)
-- URL: https://www.isc21.kr/careers/i-gle-life
-- badge: est
--
-- 참고:
--   정본은 KOSDAQ 095340 (주)아이에스시 자기 도메인 www.isc21.kr 의 GNB Careers > i-Gle LIFE 페이지다.
--   귀속: 홈 IR 카드가 네이버 금융 code=095340 을 링크하고 전 페이지 푸터가 (주)아이에스시 · ISC INC. 다.
--   동명 도메인 isc.co.kr · isc.kr · isc21.com 은 주차 · 매물 도메인이라 쓰지 않았다(웨이브 4 프로브).
--   Next.js 서버렌더 — 원본 HTML section.benefitSection 안 li.benefitItem 12블록 38라벨. 헤드리스 렌더 없음.
--   2번 블록의 자율휴가 설명(추가 휴일 5일)은 물음표 아이콘 호버 툴팁 p.guideText 에만 있다 — 원본 HTML 에서 읽었다.
--   보조 출처: 같은 페이지 보상체계 이미지 img_compensation.320815ed.png 판독(incentive · excellence_award 서술 보강).
--   귀속 판단: 이 법인 자기 도메인 자기 채용 페이지 문장만 썼다. 계열 · 모회사 각주 없음.
--     ESG Reporting Center 의 보고서 2건은 모회사 발행 SKC Sustainability Report 라 쓰지 않았다.
--     GNB 의 SKC Family 채용 외부 링크(skc.kr)도 다른 법인이라 쓰지 않았다.
--   금액: 원문에 원 · 만원 숫자 0건. 금액 행 1 = meal 864(아침 · 점심 · 저녁 3끼 × 1끼 12,000원 × 240일 추정).
--     stated 0 · 추정 1 · 나머지 16행 정성.
--   제외: 법정(4대 보험 4라벨 · 자유로운 연차사용 · 반차제도 · 산전/산후휴가 · 육아휴직 · 생리휴가 · 퇴직연금 DB/DC) ·
--     업무 교육(OJT · 온보딩) · 급여성 수당(직책수당) · 혜택 미기재 그룹 제휴카드(SK 패밀리 카드) ·
--     슬로건 블록(8번 좋은 동료들) · 보상체계 이미지의 Base Salary 수준 지향 문구.
--   병합: 경조휴가 + 권장휴가 → leave_general 한 행.
--   공고 근거 0행 / 전체 17행. 신규 코드 0.
--   SORT 섹션 순서 = 정본 첫 등장 순: time_off 10 · compensation 20 · perks 30 · leisure 40 · growth 50 · family 60.
-- 검증 · 감사 판정 반영(2026-10-10): 경조휴가 행에서 권장휴가(회사가 더 주는 날 없음) 걷기 — 최종 17행
-- 코퍼스 정리(2026-10-10 · 웨이브 5 감사 후속): 경조휴가 행 삭제, event 행에 합침 — 최종 16행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('isc', 'ISC',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체장비', 'I', 'https://www.isc21.kr/careers/i-gle-life');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'isc');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.isc21.kr/careers/i-gle-life'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 휴가 (time_off) — 정본 2번 블록 ──
  (@comp_id, 'birthday_leave', '생일휴가', NULL, 'time_off',
   'est', NULL, TRUE, '생일휴가 (공식 채용 페이지 i-Gle LIFE 복리후생 「휴가는 눈치보지 말아요」 항목) — 휴가 일수·유급 여부 미기재', 11),
  (@comp_id, 'refresh_leave', '자율휴가 (추가 휴일 5일)', NULL, 'time_off',
   'est', NULL, TRUE, '자율휴가, 법정 연차 외에 구성원들의 워라벨과 휴식을 지원하기 위해 마련된 추가 휴일 5일 (공식 채용 페이지 i-Gle LIFE 복리후생 「휴가는 눈치보지 말아요」 항목 안내 문구) — 부여 주기·유급 여부·사용 조건 미기재', 12),

  -- ── 보상 (compensation) — 정본 3번 블록 · 보상체계 이미지 ──
  (@comp_id, 'incentive', '인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '인센티브 (공식 채용 페이지 i-Gle LIFE 복리후생 「성과는 모두 함께 나눠요」 항목), Incentive Bonus 회사 실적 및 개인·팀 성과를 반영한 보상 (같은 페이지 보상체계 항목) — 지급 기준·지급률 미기재', 20),
  (@comp_id, 'excellence_award', '포상제도', NULL, 'compensation',
   'est', NULL, TRUE, '포상제도 (공식 채용 페이지 i-Gle LIFE 복리후생 「성과는 모두 함께 나눠요」 항목), Recognition & Awards 성공 사례 또는 우수 구성원에 대한 각종 포상 (같은 페이지 보상체계 항목) — 포상 종류·포상 내용 미기재', 21),

  -- ── 경제적 부가혜택 (perks) — 정본 4 · 6 · 10 · 11번 블록 ──
  (@comp_id, 'meal', '아침·점심·저녁 식사 제공', 864, 'perks',
   'est', '아침, 점심, 저녁 식사 제공 (공식 채용 페이지 i-Gle LIFE 복리후생 「우리 굶지 말아요」 항목) — 1끼 단가·제공 사업장 미기재 (하루 3끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 30),
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '복지포인트 (공식 채용 페이지 i-Gle LIFE 복리후생 「구성원의 일상도 챙깁니다」 항목) — 포인트 금액·지급 주기 미기재', 31),
  (@comp_id, 'team_dinner', '팀빌딩·조직운영비·워크샵', NULL, 'perks',
   'est', NULL, TRUE, '팀빌딩, 조직운영비, 워크샵 (공식 채용 페이지 i-Gle LIFE 복리후생 「우리는 팀이에요」 항목) — 지원 금액·지원 주기 미기재', 32),
  (@comp_id, 'housing_loan', '주택대출이자 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택대출이자 지원 (공식 채용 페이지 i-Gle LIFE 복리후생 「집 걱정, 회사가 함께 덜어드려요」 항목) — 지원 대상·대출 한도·이자 지원율 미기재', 33),

  -- ── 여가 (leisure) — 정본 7 · 12번 블록 ──
  (@comp_id, 'resort', '리조트 회원권 지원 (전국 34개)', NULL, 'leisure',
   'est', NULL, TRUE, '전국 34개 리조트 회원권 지원 등 다양한 휴식 권장 복지 제공 (공식 채용 페이지 i-Gle LIFE 복리후생 「구성원의 온전한 쉼을 지원해요」 항목) — 이용 조건·숙박비 지원 범위 미기재', 40),
  (@comp_id, 'company_event', '정기행사', NULL, 'leisure',
   'est', NULL, TRUE, '정기행사 (공식 채용 페이지 i-Gle LIFE 복리후생 「슬픔과 기쁨은 함께 나눠요」 항목) — 행사 종류·개최 주기 미기재', 41),
  (@comp_id, 'club', '동호회비', NULL, 'leisure',
   'est', NULL, TRUE, '동호회비 (공식 채용 페이지 i-Gle LIFE 복리후생 「슬픔과 기쁨은 함께 나눠요」 항목) — 지원 금액·지원 방식 미기재', 42),

  -- ── 성장 (growth) — 정본 9번 블록 ──
  (@comp_id, 'edu_support', '교육비·온라인 그룹교육 플랫폼', NULL, 'growth',
   'est', NULL, TRUE, '교육비, 온라인 그룹교육 플랫폼 (공식 채용 페이지 i-Gle LIFE 복리후생 「구성원의 성장을 위해 지원해요」 항목) — 교육비 지원 대상 과정·한도, 플랫폼 이용 범위 미기재', 50),
  (@comp_id, 'lang', '어학교육', NULL, 'growth',
   'est', NULL, TRUE, '어학교육 (공식 채용 페이지 i-Gle LIFE 복리후생 「구성원의 성장을 위해 지원해요」 항목) — 교육 방식·비용 지원 범위 미기재', 51),
  (@comp_id, 'conference', '사외 직무 교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '사외 직무 교육 지원 (공식 채용 페이지 i-Gle LIFE 복리후생 「구성원의 성장을 위해 지원해요」 항목) — 지원 한도·대상 과정 미기재', 52),

  -- ── 가족 (family) — 정본 12번 블록 ──
  (@comp_id, 'event', '경조사·경조휴가', NULL, 'family',
   'est', NULL, TRUE, '경조사 (공식 채용 페이지 i-Gle LIFE 복리후생 「슬픔과 기쁨은 함께 나눠요」 항목), 경조휴가 (같은 페이지 「휴가는 눈치보지 말아요」 항목) — 경조 사유별 지원 내용·금액·휴가 일수·유급 여부 미기재', 60),
  (@comp_id, 'child_edu', '자녀 대학학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 대학학자금 지원 (공식 채용 페이지 i-Gle LIFE 복리후생 「슬픔과 기쁨은 함께 나눠요」 항목) — 지원 한도·자녀 수 제한 미기재', 61)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
