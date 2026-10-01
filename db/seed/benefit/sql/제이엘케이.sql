-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 제이엘케이 복리후생 데이터
-- 출처: AI 파싱 (2026-10-01)
-- URL: https://www.jlkgroup.com/careers/
-- badge: est
--
-- 참고:
--   정본은 법인 자기 도메인 jlkgroup.com 의 헤더 메뉴 인재채용 > JLK People 페이지(/careers/)의
--   FRINGE BENEFITS 문화 & 복지제도 블록이다. 서버 렌더 정적 HTML 이라 원본 응답에 항목 본문이 그대로 있다 — 헤드리스 렌더 없음.
--   robots.txt 는 404(제한 없음). 같은 헤더의 ENG(/en/careers/) · JPN(/jp/careers/) 판도 렌더 항목 5개가 같다.
--   렌더된 항목 5개: 사내 카페 운영 · 도서구입비 지원 · 직무관련 교육/논문/특허 지원 · 회식 없음 · 성과 인센티브 제공.
--   식사 지원 · 자율출퇴근제 · 동호회비 지원 3개는 세 언어판 모두 HTML 주석 안에만 있어 화면에 나오지 않는다 — 근거로 쓰지 않았다.
--   귀속: 법인 단독 도메인이라 그룹 각주를 달지 않았다. 사이트에 복지 보도자료 · 뉴스 절은 없다(IR 공고 게시판만).
--   금액: 월액 환산 1(snack_bar 매달 20만 포인트 → 240) · 구본 추정 승계 1(incentive 100 — 틀 값, NOTE 끝에 (추정)).
--     구본 공식 수치 snack_bar 60(월 5만 포인트)은 지금 원문 숫자가 20만이라 승계하지 않았다. 구본 추정치 books 10 은 승계하지 않았다.
--   구본에서 뺀 행: flex_work · club · meal (원문이 주석 처리돼 화면에 없다).
--   재코딩: 없음. 회식 없음 항목은 맞는 코드가 없어 싣지 않았다.
--   SORT 섹션 순서 = 정본 페이지에서 카테고리가 처음 나온 순서 (perks 10 · work_env 20 · growth 30 · compensation 40).
-- 재수집(2026-10-01): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-01, RV-3-3): 5행 전부 렌더 원문 확인 · snack_bar NOTE 에 1포인트 1원 기준 명시 · 주석 속 3칸(식사 · 자율출퇴근 · 동호회비)은 세 언어판 모두 주석이라 근거 아님 — 최종 5행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('jlk', '제이엘케이',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        'AI/의료', 'J', 'https://www.jlkgroup.com/careers/');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'jlk');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.jlkgroup.com/careers/'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) — 사내 카페 운영 ──
  (@comp_id, 'snack_bar', '사내 카페 (Hello Cafe) 포인트', 240, 'perks',
   'est', '사내 카페 Hello Cafe 에서 커피와 간식에 쓰는 포인트 매달 20만 포인트 지급 (공식 채용 페이지 JLK People 문화 & 복지제도 사내 카페 운영 항목) — 1포인트 1원 기준 월 20만 포인트 × 12 환산', FALSE, NULL, 10),

  -- ── 근무환경 (work_env) — 사내 카페 운영 ──
  (@comp_id, 'lounge', '고급 안마의자', NULL, 'work_env',
   'est', NULL, TRUE, '사내 카페 Hello Cafe 와 함께 고급 안마의자 이용 (공식 채용 페이지 JLK People 문화 & 복지제도 사내 카페 운영 항목) — 설치 대수·사업장 범위 미기재', 20),

  -- ── 성장·커리어 (growth) — 도서구입비 지원 · 직무관련 교육/논문/특허 지원 ──
  (@comp_id, 'books', '도서구입비 지원', NULL, 'growth',
   'est', NULL, TRUE, '업무에 필요한 도서 구입비 회사 지원 (공식 채용 페이지 JLK People 문화 & 복지제도 도서구입비 지원 항목) — 지원 한도 미기재', 30),
  (@comp_id, 'edu_support', '직무관련 교육/논문/특허 지원', NULL, 'growth',
   'est', NULL, TRUE, '업무를 위한 교육 지원과 특허 공동 출원 지원 (공식 채용 페이지 JLK People 문화 & 복지제도 직무관련 교육/논문/특허 지원 항목) — 지원 방식·비용 범위 미기재', 31),

  -- ── 보상·금전 (compensation) — 성과 인센티브 제공 ──
  (@comp_id, 'incentive', '성과 인센티브', 100, 'compensation',
   'est', '업무 성과에 따른 인센티브 제공 (공식 채용 페이지 JLK People 문화 & 복지제도 성과 인센티브 제공 항목) — 지급 기준·규모 미기재 (추정)', FALSE, NULL, 40)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
