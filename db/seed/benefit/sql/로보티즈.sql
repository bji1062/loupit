-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 로보티즈 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-14)
-- URL: https://robotisrecruiter.ninehire.site/welfare
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 로보티즈 전용 나인하이어 ATS 서브도메인의 Welfare 페이지 한 곳이다.
--       귀속 경로: 공식 도메인 www.robotis.com/ko/ GNB 「채용정보」 → /ko/recruit.php
--       → 302 → robotisrecruiter.ninehire.site/jobs → 헤더 메뉴 Welfare → /welfare.
--       페이지 제목 「로보티즈만의 특별함 / Welfare」, companyName 로보티즈, 복지 아이콘 경로가
--       이 회사 companyId(beb507d0-…) 아래라 샘플 템플릿이 아니다. 자기 도메인엔 복지 페이지가 없다.
--       단일 법인 페이지라 「그룹 통합 채용 기준」 각주는 붙이지 않았다.
--       렌더: Next.js SSR. 원본 HTML 가시 텍스트와 __NEXT_DATA__ 양쪽에 항목이 있어 헤드리스 불필요.
--       ⚠ __NEXT_DATA__ 에 페이지 8개(초안 About 복사본·FAQ 복사본·개인정보처리방침 샘플 포함)가
--         통째로 실린다 — homepage.pages 중 pageUrl=welfare 한 페이지만 읽었다.
--       ⚠ 항목명 「출산·육아·가족돌봄 지원」 은 가운뎃점 HTML 엔티티가 이중 이스케이프돼
--         화면에도 엔티티 이름(앰퍼샌드+middot)이 글자로 보인다. 원문 표기는 evidence 에 그대로 두었다.
--       ⚠ 생활지원 마지막 카드 「what is NEXT...?」 는 예고 카드라 항목이 아니다.
--       원문 10항목(업무지원 4 · 생활지원 6) → 1항목 제외 → **9행**. 병합·분해 0. 신규 코드 0.
--       제외: 「출산·육아·가족돌봄 지원」 — 원문이 「다양한 제도를 지원합니다」 뿐이고
--         세부 제도명도 법정 수준을 넘는 조건도 밝히지 않는다. 출산·육아·가족돌봄 휴가·휴직은
--         법정 제도라 상회 조건 없이는 행으로 만들지 않았다(판단 상세는 evidence).
--       금액: 원 단위 명시는 식대 1건(일 18,000원 · 연장근로 시 10,000원 추가)뿐인데
--         일액이라 연 환산에 근무일수 가정이 필요하다 → BENEFIT_AMT NULL, 조건은 서술로 남겼다.
--         → 9행 전부 BENEFIT_AMT NULL · QUAL_YN TRUE. 신규 회사라 승계할 앵커도 없다.
--       SORT 섹션 순서는 원문 카드 순서에서 각 카테고리가 처음 나온 순서
--         (perks 10 · flexibility 20 · work_env 30 · family 40 · leisure 50 · time_off 60).
--       ⚠ 사이트 개설 2026-02-26 · 최종 수정 2026-09-09 — 편집 중인 사이트라 항목이 자주 바뀔 수 있다.
--       ⚠ 검증·감사 판정 반영(2026-09-15): 행 조치 없음(9행 그대로). SORT 10 식대 AMT NULL · SORT 30 work_tools 유지.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('robotis', '로보티즈',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '로봇', 'R', 'https://robotisrecruiter.ninehire.site/welfare');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'robotis');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://robotisrecruiter.ninehire.site/welfare'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) — 원문 업무지원·생활지원 ──
  (@comp_id, 'meal', '식대지원', NULL, 'perks',
   'est', NULL, TRUE, '식대 지원 일 18,000원, 연장근로 시 10,000원 추가 (공식 채용 페이지 업무지원 항목 — 월·연 단위 지급액과 지급 방식 미기재)', 10),
  (@comp_id, 'team_dinner', '회식비 지원', NULL, 'perks',
   'est', NULL, TRUE, '회식비 지원 — 팀 구성원의 선호를 반영한 자율적 회식 (공식 채용 페이지 업무지원 항목 — 지원 한도·주기 미기재)', 11),
  (@comp_id, 'relocation', '이사비용 지원', NULL, 'perks',
   'est', NULL, TRUE, '안정적인 정착을 돕기 위한 이사비용 지원 (공식 채용 페이지 생활지원 항목 — 지원 대상·한도 미기재)', 12),
  (@comp_id, 'birthday_gift', '생일자 쿠폰 지급', NULL, 'perks',
   'est', NULL, TRUE, '생일을 맞은 구성원에게 축하 쿠폰 지급 (공식 채용 페이지 생활지원 항목 — 쿠폰 종류·금액 미기재)', 13),

  -- ── 근무 유연성 (flexibility) — 원문 업무지원 ──
  (@comp_id, 'flex_work', '효율근무제(시차출퇴근제)', NULL, 'flexibility',
   'est', NULL, TRUE, '자율적인 출퇴근으로 업무 효율을 높이는 시차출퇴근제 운영 (07:00~10:00) (공식 채용 페이지 업무지원 항목 효율근무제 — 코어타임·적용 대상 미기재)', 20),

  -- ── 근무환경 (work_env) — 원문 업무지원 ──
  (@comp_id, 'work_tools', 'AI Tool 지원', NULL, 'work_env',
   'est', NULL, TRUE, '더 빠르고 효율적인 업무 수행을 위해 필요한 AI Tool 활용 지원 (공식 채용 페이지 업무지원 항목 — 지원 도구 종류·비용 한도 미기재)', 30),

  -- ── 가족·돌봄 (family) — 원문 생활지원 ──
  (@comp_id, 'event', '경조사', NULL, 'family',
   'est', NULL, TRUE, '구성원의 중요한 순간에 함께하는 경조휴가와 경조금 지원 (공식 채용 페이지 생활지원 항목 — 경조 구분별 휴가 일수·경조금액 미기재)', 40),

  -- ── 여가·라이프 (leisure) — 원문 생활지원 ──
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '문화·운동·자기계발 등 다양한 사내 동호회 활동 지원 (공식 채용 페이지 생활지원 항목 — 활동비 지원액 미기재)', 50),

  -- ── 휴가 (time_off) — 원문 생활지원 ──
  (@comp_id, 'summer_leave', '하계휴가', NULL, 'time_off',
   'est', NULL, TRUE, '충분한 재충전을 위한 유급 하계휴가 3일, 연차와 별도 제공 (공식 채용 페이지 생활지원 항목 — 사용 시기·휴가비 지급 여부 미기재)', 60)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
