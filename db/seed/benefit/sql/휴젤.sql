-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 휴젤 복리후생 데이터
-- 출처: AI 파싱 (2026-10-01)
-- URL: https://hugel.career.greetinghr.com/ko/culture
-- badge: est
--
-- 참고:
--   정본은 휴젤 공식 홈페이지(www.hugel-inc.com/kr/careers)의 한국 채용 사이트 바로가기가 가리키는 브랜드 ATS
--   hugel.career.greetinghr.com 의 휴젤 라이프 페이지(/ko/culture)다. P+US한 휴젤 라이프 3블록 19줄.
--   Next.js 서버 렌더라 원본 HTML 에 항목 본문이 그대로 있다 — 헤드리스 렌더 없음. robots 는 /ko/culture 허용.
--   보조 출처: 같은 ATS 채용 공고(/ko/o/239047 · /ko/o/237972)의 누릴 수 있습니다 블록,
--   공식 홈페이지 INVESTORS 자료실의 Annual Report 2025 국문 PDF 40~42쪽(가족친화적 기업문화 · 다양한 복리후생 ·
--   노사협의회) · 44쪽(전자도서관) · 52쪽(휴카페). 연간 리포트에만 있는 행은 서술에 그 출처를 적었다.
--   자기 도메인 hugel-inc.com 에는 복지 절이 있는 HTML 페이지가 없다(careers 는 ATS 링크만, ESG Social 은 노사협의회 한 줄).
--   귀속: 법인 자기 홈에서 링크된 법인 단독 ATS 라 그룹 각주를 달지 않았다.
--   금액: 원문 연액 2(health_check 연 1회 20만원 · birthday_gift 5만원권) · 월액 환산 1(club 월 인당 1.5만원 → 18) ·
--     구본 추정 승계 4(child_edu 200 · insurance 30 · resort 50 · snack_bar 50 — 전부 틀 값, NOTE 끝에 (추정)).
--     welfare_point 는 원문이 연간 최대 120만이라 배정액인지 드러나지 않아 금액을 비웠다(근거표 판단 요청).
--     구본 추정치 health_check 100 · parenting 120 · meal 144 · transport 30 은 승계하지 않았다.
--   구본에서 뺀 행: lang 은 2026-10-04 규칙 8 개정으로 되살렸다(어학교육 지원, SORT 71).
--   재코딩: 없음.
--   SORT 섹션 순서 = 정본 페이지에서 카테고리가 처음 나온 순서, 정본에 없는 카테고리는 연간 리포트 순서
--     (flexibility 10 · perks 20 · family 30 · time_off 40 · health 50 · leisure 60 · growth 70 · work_env 80).
-- 재수집(2026-10-01): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-01, RV-3-2): 24행 전부 원문 확인 · 조치 없음 · welfare_point 연간 최대 120만은 지급액이 사람마다 다를 수 있는 상한이라 금액 비움 유지 — 최종 24행
-- 후속 정리 2(2026-10-04, R-3): 사용자가 정한 복지 범위 규칙 개정(규칙 8 · 기준 13 · 기준 18 · 기준 20 · 기준 23)과 코퍼스 판정을 반영 — 새 행 1(lang) — 최종 25행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hugel', '휴젤',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '바이오/제약', 'H', 'https://hugel.career.greetinghr.com/ko/culture');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hugel');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://hugel.career.greetinghr.com/ko/culture'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무유연성 (flexibility) — 업무와 삶에 몰입할 수 있도록 · 오래오래 함께할 수 있도록 ──
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '자율출퇴근·시차출퇴근 유연근무제 운영 (공식 채용 사이트 휴젤 라이프 업무와 삶에 몰입할 수 있도록 항목), 시차출퇴근제·선택근무제 등으로 한 달 평균 일 8시간 근무 원칙 아래 근무 시간 자율 선택 (2025 연간 리포트 유연한 업무 환경 조성 항목)', 10),
  (@comp_id, 'remote_work', '원격근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '상황에 따라 필요시 원격근무제 운영 (공식 채용 사이트 휴젤 라이프 업무와 삶에 몰입할 수 있도록 항목), 스마트워크로 원격 근무·모바일 오피스 지원과 VPN 을 이용한 필요시 재택근무 (2025 연간 리포트 유연한 업무 환경 조성 항목) — 월 사용 한도 미기재', 11),
  (@comp_id, 'family_day', 'Family Day', NULL, 'flexibility',
   'est', NULL, TRUE, '매월 셋째 주 금요일 반일 근무 (공식 채용 사이트 휴젤 라이프 오래오래 함께할 수 있도록 항목), 오전 4시간 근무 후 퇴근 (2025 연간 리포트 Work & Life Balance 항목)', 12),

  -- ── 경제적 부가혜택 (perks) — 업무와 삶에 몰입할 수 있도록 · 연간 리포트 Working Environment · Life Care ──
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '연간 최대 120만 복지포인트 지급 (공식 채용 사이트 휴젤 라이프 업무와 삶에 몰입할 수 있도록 항목 · 2025 연간 리포트 선택적 복리후생 프로그램 항목), 의료비를 포함한 교육·건강 등 오프라인 사용처 (2025 연간 리포트 노사협의회 개선사항) — 개인별 지급 기준 미기재', 20),
  (@comp_id, 'snack_bar', '사내 카페 (휴카페)', 50, 'perks',
   'est', '커피·차·베이커리가 있는 사내 카페 운영 (공식 채용 사이트 휴젤 라이프 항목 · 채용 공고 누릴 수 있습니다 항목), 서울사무소와 춘천 본사의 사내 복지카페 휴카페 (2025 연간 리포트 사회공헌 발달장애인 고용 창출 항목) — 이용 요금 미기재 (추정)', FALSE, NULL, 21),
  (@comp_id, 'meal', '조식 제공', NULL, 'perks',
   'est', NULL, TRUE, '조식 제공 (공식 채용 사이트 휴젤 라이프 업무와 삶에 몰입할 수 있도록 항목 · 2025 연간 리포트 Working Environment 항목) — 제공 사업장·중식 제공 여부 미기재', 22),
  (@comp_id, 'transport', '야근 교통비', NULL, 'perks',
   'est', NULL, TRUE, '야근 교통비 지원 (공식 채용 사이트 휴젤 라이프 업무와 삶에 몰입할 수 있도록 항목) — 야근 기준 시간·지원 한도 미기재', 23),
  (@comp_id, 'birthday_gift', '생일 축하 상품권', 5, 'perks',
   'est', '생일 축하 5만원권 모바일 상품권 지급 (2025 연간 리포트 Life Care 항목)', FALSE, NULL, 24),
  (@comp_id, 'team_dinner', '회식비 지원', NULL, 'perks',
   'est', NULL, TRUE, '회식비 월 5만원 지원 (2025 연간 리포트 Working Environment 항목) — 1인당인지 부서당인지 미기재', 25),

  -- ── 가족·돌봄 (family) — 업무와 삶에 몰입할 수 있도록 · 연간 리포트 Family Care ──
  (@comp_id, 'parenting', '육아지원금', NULL, 'family',
   'est', NULL, TRUE, '미취학 아동 육아지원금 지급 (공식 채용 사이트 휴젤 라이프 업무와 삶에 몰입할 수 있도록 항목 · 2025 연간 리포트 가족친화적 기업문화 항목) — 지급액·지급 기간 미기재', 30),
  (@comp_id, 'child_edu', '자녀 학자금 지원', 200, 'family',
   'est', '고교, 대학 학자금 지원 (공식 채용 사이트 휴젤 라이프 업무와 삶에 몰입할 수 있도록 항목), 고등학생 및 대학생 자녀가 있는 직원에게 학자금 지원 (2025 연간 리포트 가족친화적 기업문화 항목) — 지원 한도·자녀 수 제한 미기재 (추정)', FALSE, NULL, 31),
  (@comp_id, 'event', '경조사비 지원', NULL, 'family',
   'est', NULL, TRUE, '본인 및 가족 결혼, 수연 및 고희 등 주요 경조사비 지원 (2025 연간 리포트 Family Care 항목) — 경조 종류별 금액 미기재', 32),

  -- ── 시간·휴가 (time_off) — 오래오래 함께할 수 있도록 · 연간 리포트 노사협의회 ──
  (@comp_id, 'refresh_leave', 'Refresh 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '연중 사용 가능한 Refresh 휴가 3일 지원 (공식 채용 사이트 휴젤 라이프 오래오래 함께할 수 있도록 항목 · 2025 연간 리포트 Work & Life Balance 항목)', 40),
  (@comp_id, 'foundation_day_leave', '창립기념일 대체 휴무', NULL, 'time_off',
   'est', NULL, TRUE, '창립기념일 대체 휴무 (공식 채용 사이트 휴젤 라이프 오래오래 함께할 수 있도록 항목) — 휴무 일자 미기재', 41),
  (@comp_id, 'long_service_leave', '장기근속 포상', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 포상제도 운영 (공식 채용 사이트 휴젤 라이프 오래오래 함께할 수 있도록 항목), 5·10·20년 장기근속 시 50·100·200만원 지급 및 휴가 제공 (2025 연간 리포트 Life Care 항목) — 휴가 일수 미기재', 42),
  (@comp_id, 'leave_general', '병가', NULL, 'time_off',
   'est', NULL, TRUE, '필요한 경우 다른 휴가를 먼저 소진하지 않고 쓰는 병가 (2025 연간 리포트 노사협의회 개선사항) — 부여 일수·유급 여부 미기재', 43),

  -- ── 건강·의료 (health) — 오래오래 함께할 수 있도록 · 연간 리포트 Health Care ──
  (@comp_id, 'health_check', '종합건강검진', 20, 'health',
   'est', '연 1회 재직자 대상 20만원 종합건강검진 지원, 임직원 가족 건강검진 비용 할인 (2025 연간 리포트 Health Care 항목), 검진일 휴가 — 공식 채용 사이트 휴젤 라이프 항목은 당일 반일 휴가 지원, 2025 연간 리포트 노사협의회 개선사항은 지역과 거리에 관계없이 1일 공가', FALSE, NULL, 50),
  (@comp_id, 'insurance', '단체상해보험', 30, 'health',
   'est', '전 임직원 대상 단체상해보험 가입 (공식 채용 사이트 휴젤 라이프 오래오래 함께할 수 있도록 항목 · 2025 연간 리포트 Health Care 항목) — 보장 내용 미기재 (추정)', FALSE, NULL, 51),

  -- ── 여가·라이프 (leisure) — 오래오래 함께할 수 있도록 · 연간 리포트 Working Environment · 인재경영 ──
  (@comp_id, 'resort', '콘도/리조트 회원권', 50, 'leisure',
   'est', '콘도/리조트 회원권 운영 (공식 채용 사이트 휴젤 라이프 오래오래 함께할 수 있도록 항목), 법인 콘도 회원권을 이용한 임직원 숙박 할인 (2025 연간 리포트 Life Care 항목) — 이용 횟수·할인율 미기재 (추정)', FALSE, NULL, 60),
  (@comp_id, 'club', '동호회 지원', 18, 'leisure',
   'est', '임직원 동호회 활동 지원 월 인당 1.5만원 (2025 연간 리포트 Working Environment 항목) — 월액을 12개월로 환산', FALSE, NULL, 61),
  (@comp_id, 'library', '전자도서관', NULL, 'leisure',
   'est', NULL, TRUE, '업무에 필요한 정보를 얻을 수 있는 전자도서관 운영 (2025 연간 리포트 인재경영 개인의 성장 환경 조성 항목) — 이용 범위 미기재', 62),

  -- ── 성장·커리어 (growth) — 같이 성장할 수 있도록 ──
  (@comp_id, 'edu_support', '개인 희망 교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '직무와 연계된 개인 희망 교육 지원 (공식 채용 사이트 휴젤 라이프 같이 성장할 수 있도록 항목) — 지원 한도·대상 과정 미기재', 70),
  (@comp_id, 'lang', '어학교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '어학교육 지원 (2025 연간 리포트 41쪽 Working Environment 항목) — 지원 방식·대상 미기재', 71),

  -- ── 근무환경 (work_env) — 연간 리포트 Working Environment ──
  (@comp_id, 'dormitory', '기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '타지 거주자에 한한 기숙사 운영 (2025 연간 리포트 Working Environment 항목) — 위치·비용 부담 미기재', 80),
  (@comp_id, 'nap_room', '여성 휴게실·수유실', NULL, 'work_env',
   'est', NULL, TRUE, '전 사업장 여성 휴게실과 수유실 운영 (2025 연간 리포트 가족친화적 기업문화 · Working Environment 항목)', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
