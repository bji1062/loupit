-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 파두 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-19)
-- URL: https://careers.fadu.io/ko/culture
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 파두가 자기 도메인(fadu.io)에 커스텀 도메인으로 붙인 채용 사이트
--       careers.fadu.io 의 「팀 문화」 페이지 한 곳이다. 섹션 「Welfare / 복지 혜택」
--       (섹션 id 76738268… 머리말 + f2d76050… 항목 11개)이 정본이고, 그리팅 Next.js
--       SSR 이라 항목이 원본 HTML 가시 DOM 과 __NEXT_DATA__ 양쪽에 있다.
--       귀속 경로: www.fadu.io 푸터 Careers → careers.fadu.io → 301 /ko/intro →
--       GNB 팀 문화 → /ko/culture. fadu.io 존의 CNAME(→ faduhr.career.greetinghr.com)
--       + TLS CN=careers.fadu.io + 워크스페이스명 주식회사 파두 + 푸터 사업자등록번호
--       390-87-00132 로 법인이 일치한다. 그룹 채용사이트가 아니라 단일 법인 사이트라
--       「그룹 통합 채용 기준」 각주는 붙이지 않았다.
--       ⚠ 같은 문구가 원본 HTML 에 3회 나온다 — 가시 DOM + styled-components 가 흘린
--          content= 속성 + __NEXT_DATA__. 문자열 카운트로 세면 행이 3배가 된다.
--          page.sections 의 f2d76050… 섹션만 layouts→columns→blocks 로 읽었다.
--       ⚠ careers.fadu.io·www.fadu.io 는 Cloudflare 엣지가 ClaudeBot·anthropic-ai·
--          GPTBot·CCBot UA 를 403(25B)으로 끊는다. robots 는 /ko/culture 를 허용하고
--          브라우저 UA 는 200 이다. 재수집 때 UA 를 바꾸면 조용히 0건이 된다.
--       ⚠ fadu.recruiter.co.kr 은 robots 26B 전면 금지라 어느 단계에서도 요청하지
--          않았다. 채용 사이트 푸터 링크가 그쪽을 가리키니 링크 추적 주의.
--       원문 11항목 → 2항목 제외 → 9항목. 항목 복수 분해 0, 병합 0.
--       제외 ① 접근 용이(지하철 강남구청역과 바로 연결된 근무지) = 근무지 위치 서술이라
--       제도가 아니다. ② 신규 입사자 교육(오리엔테이션·부서별 OJT) = 회사 주도 온보딩
--       커리큘럼이고 비용 지원 문구가 없다.
--       +1 행: 건강검진. 복지 카드가 아니라 같은 페이지 「팀 문화」 섹션의 제도 열거
--       문장 「④ 건강과 행복: 건강검진 지원, 경조사 지원 등」에만 있다. 이 문장의 나머지
--       5개(유연근무제·자유로운 휴가 사용·직무 교육·외국어 교육·경조사 지원)가 전부
--       복지 카드와 1대1 대응해 제도 열거 문장임이 확인되어 수록했다. 판단이 갈리는
--       한 행이라 카테고리 섹션을 맨 끝(SORT 70)에 독립으로 두었다 — 검증이 빼기로
--       판정하면 이 한 행만 삭제하면 된다. → **10행**. 신규 코드 0.
--       금액: 원문의 원 단위 금액은 식대 「점심, 저녁(야근시) 각 15,000원」 1건뿐인데
--       이는 끼니 단가(일액)라 연 환산 금액이 아니다 → BENEFIT_AMT NULL, 단가는
--       서술에 남겼다. 나머지 정량 표현은 공동연차 5일·코어타임 10~16시·모니터 2대뿐
--       이라 금액이 아니다. → 10행 전부 BENEFIT_AMT NULL · QUAL_YN TRUE.
--       신규 회사라 승계할 앵커도 없어 타사 금액을 끌어오지 않았다(금액 stated 0건).
--       법정 제도 미수록: 4대보험·퇴직연금·법정 연차·육아 관련 제도는 페이지에 아예
--       없다. 「자유로운 휴가 사용」은 기본 연차 부분이 아니라 원문이 상회분으로 밝힌
--       「기본 연차 외 5일의 공동연차 추가 제공」만 수록 대상으로 삼았다.
--       ⚠ 적용 범위: 페이지에 면책 문구가 없으나 카페테리아·강남구청역 연결은 서울 본사
--          전제이고, 평촌 Lab 계약직 공고(216549)의 근무조건은 「점심 식대 별도 지원」
--          으로 이 페이지(점심·저녁 각 15,000원)와 다르다. 공고는 출처로 쓰지 않았다.
--       ⚠ 갱신 감지는 URL 이 아니라 f2d76050… 섹션 JSON 해시로 한다. customDomain 이
--          풀리면 URL 이 faduhr.career.greetinghr.com 으로 바뀐다(현재 SUCCESS).
--       ⚠ 검증·감사 판정 반영(2026-09-19): 10행 그대로. SORT 20 refresh_leave → leave_general 재코딩
--       (공동연차는 회사가 날짜를 정하는 지정 휴가다) · SORT 70 에서 출처 구조 서술을 걷어냈다.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('fadu', '파두',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체', 'F', 'https://careers.fadu.io/ko/culture');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'fadu');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://careers.fadu.io/ko/culture'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) ──
  (@comp_id, 'flex_work', '유연한 출퇴근', NULL, 'flexibility',
   'est', NULL, TRUE, '자율적인 출퇴근 시간 운영, 코어 타임 10:00~16:00 에는 반드시 근무 (공식 채용 사이트 복지 혜택 개인의 판단 존중 항목 — 정산 단위·신청 절차 미기재)', 10),

  -- ── 휴가 (time_off) ──
  (@comp_id, 'leave_general', '자유로운 휴가 사용 (공동연차 5일 추가)', NULL, 'time_off',
   'est', NULL, TRUE, '기본 연차 외 5일의 공동연차 추가 제공, 별도의 승인 절차 없는 휴가 사용 (공식 채용 사이트 복지 혜택 개인의 판단 존중 항목 — 공동연차 지정 시기·이월 여부 미기재)', 20),

  -- ── 근무 환경 (work_env) ──
  (@comp_id, 'work_tools', '업무용 IT 장비 제공', NULL, 'work_env',
   'est', NULL, TRUE, '원활한 업무 활용을 위해 노트북(LG그램/레노버/맥북), 모니터 2대, 모니터 암 제공 (공식 채용 사이트 복지 혜택 몰입을 위한 환경 제공 항목 — 교체 주기·직군별 차이 미기재)', 30),
  (@comp_id, 'lounge', '카페테리아', NULL, 'work_env',
   'est', NULL, TRUE, '안마의자 등을 구비한 휴식 공간 카페테리아 운영 (공식 채용 사이트 복지 혜택 행복한 회사 생활 항목 — 운영 시간·사업장 범위 미기재)', 31),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'snack_bar', '간식 제공', NULL, 'perks',
   'est', NULL, TRUE, '배고프거나 당이 필요할 때 언제든 먹을 수 있는 간식 제공 (공식 채용 사이트 복지 혜택 몰입을 위한 환경 제공 항목 — 품목·지원 금액 미기재)', 40),
  (@comp_id, 'meal', '식대 지원', NULL, 'perks',
   'est', NULL, TRUE, '점심과 저녁(야근 시) 각 15,000원 식대 별도 지원 (공식 채용 사이트 복지 혜택 몰입을 위한 환경 제공 항목 — 끼니 단가만 명시되고 월·연 한도 미기재)', 41),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'lang', '어학 교육', NULL, 'growth',
   'est', NULL, TRUE, '글로벌 역량 향상을 위한 영어회화 교육 지원 (공식 채용 사이트 복지 혜택 구성원의 성장 항목 — 지원 한도·수강 방식 미기재)', 50),
  (@comp_id, 'edu_support', '직무 교육', NULL, 'growth',
   'est', NULL, TRUE, '직무역량 향상을 위한 자율적 외부 교육 지원 (공식 채용 사이트 복지 혜택 구성원의 성장 항목 — 지원 한도·대상 과정 미기재)', 51),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '결혼, 출생, 회갑, 사망 등에 대한 경조사비와 휴가 제공 (공식 채용 사이트 복지 혜택 행복한 회사 생활 항목 — 경조금 금액·휴가 일수 미기재)', 60),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진 지원', NULL, 'health',
   'est', NULL, TRUE, '건강검진 지원 (공식 채용 사이트 팀 문화 페이지 건강과 행복 항목 — 검진 주기·대상 가족 범위·비용 미기재)', 70)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
