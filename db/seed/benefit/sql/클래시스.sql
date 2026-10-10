-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 클래시스 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://classyshr.career.greetinghr.com/ko/benefits
-- badge: est
--
-- 참고:
--   정본은 공식 홈(classys.co.kr) 헤더 메뉴 인재채용 링크가 가리키는 브랜드 채용 사이트(그리팅, 꼬리말 (주)클래시스 ·
--   사업자 등록번호 107-88-39288 · 본사 테헤란로 208)의 헤더 메뉴 복리 후생 페이지다. Next.js 서버 렌더라 원본 HTML 에
--   본문이 있다 — 헤드리스 렌더 없음. 채용 공고 167534 의 복지 및 혜택 절은 사람인 CDN 이미지(robots 금지)라 쓰지 않았다(㊱).
--   보조 1 = 자기 도메인 ESG 페이지 /company/esg/ Social 절(다양성 존중 및 친화적 근로 환경 목록).
--   보조 2 = 같은 ESG 페이지에 링크된 2025 지속가능경영보고서 국문 PDF(2026-06 발행 · 보고범위 본사 · 문정공장 · 안양공장)
--     p.29 학비 지원 · p.30 보상 · p.31 건강 및 웰빙 · 일과 삶의 균형 · p.32 복리후생 프로그램 표.
--   귀속: 법인 단독 채용 사이트 · 법인 자기 도메인 · 법인 발행 보고서 — 그룹 각주 없음. 이루다는 2024-10 흡수합병돼
--     같은 법인(안양공장)이다 — 옛 이루다 자료는 쓰지 않았다. 자회사(일본 · 브라질 등) 복지 문구 없음.
--   직원 528명(DART 2025) — 1,000인 미만.
--   법정 제도: 출산전후휴가 90일 · 최초 60일 통상임금 · 배우자 출산휴가 20영업일 · 육아휴직 1년 · 복귀 보장 ·
--     임산부 단축근무 · 퇴직연금(DC) · 휴가 사용 자체는 싣지 않았다. 법정 등록 행 parenting 은 상회분(출산 축하금)만 남겨
--     이름이 바뀌었다.
--   금액: 원문 금액 0(자기개발비 연 최대 100만원은 한도). 구본 추정 승계 4(incentive 100 · health_check 100 · resort 50 ·
--     snack_bar 20 — 모두 틀 값, NOTE 끝에 (추정)).
--   구본에서 뺀 행: work_tools(노트북/사무용품 — 원문 없음).
--   재코딩 0. 신규 코드 0.
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-6): 보고서의 대학·대학원 학위 과정 학비 지원을 self_development 서술에서 떼어 mba 행으로 세움 · transport 서술에서 외근 복귀 교통비(업무 경비)를 뺌 · leave_general 서술에서 휴가 사용 보장 구절을 뺌 — 최종 23행
-- 후속 정리 2(2026-10-04, R-3): 사용자가 정한 복지 범위 규칙 개정(규칙 8 · 기준 13 · 기준 18 · 기준 20 · 기준 23)과 코퍼스 판정을 반영 — 서술 · 이름 수정 1(mba) — 최종 23행
-- 코퍼스 정리(2026-10-10 · 웨이브 5 감사 후속): 경조 특별휴가를 event 행으로 옮기고 휴가 행은 2시간 단위 휴가만 — 최종 23행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 2026-10-06 식대 기준 금액 1끼 12,000원(리드 판정 (82)) — meal 행 금액 = 1끼 단가 × 끼니 × 연 240일, 꼬리에 식 공개

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('classys', '클래시스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '의료기기', 'C', 'https://classyshr.career.greetinghr.com/ko/benefits');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'classys');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://classyshr.career.greetinghr.com/ko/benefits'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) — 복리 후생 업무 몰입 · 조직문화 · 근무 환경 / 보고서 ──
  (@comp_id, 'meal', '중식·석식 식비 지원', 576, 'perks',
   'est', '중식 지원, 식대 걱정 없이 든든하게 먹고 일함, 개인 법인카드로 중식 결제, 중식과 석식 식비 지원 (2025 지속가능경영보고서 경제적 안정 항목 · 공식 홈페이지 ESG Social 중식/석식 지원 항목) — 1식 단가·제공 방식 미기재 (하루 2끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 10),
  (@comp_id, 'transport', '야간 교통비(택시비) 지원', NULL, 'perks',
   'est', NULL, TRUE, '늦은 시간까지 일한 구성원이 안전하게 귀가하도록 택시비 지원 (공식 채용 사이트 복리 후생 야간 교통비 지원 항목), 야근 후 귀가 시 교통비 실비 지원 (2025 지속가능경영보고서 경제적 안정 항목) — 지원 시간 기준·한도 미기재', 11),
  (@comp_id, 'team_dinner', '팀 활동비 지원', NULL, 'perks',
   'est', NULL, TRUE, '팀워크를 위한 팀 활동비 지원(티타임·회식 등 팀워크를 위한 비용) (공식 채용 사이트 복리 후생 조직문화 팀활동비 지원 항목), 부서별 팀 빌딩(회식 및 활동비) 비용 정기 지원 (2025 지속가능경영보고서 성장 및 조직문화 항목) — 1인당 금액 미기재', 12),
  (@comp_id, 'snack_bar', '사내 카페테리아 (커피 무제한)', 20, 'perks',
   'est', '바리스타 커피 무제한 (공식 채용 사이트 복리 후생 휴게실·카페테리아 운영 항목), 커피와 다양한 음료 무료 제공 (2025 지속가능경영보고서) — 운영 비용 미기재 (추정)', FALSE, NULL, 13),
  (@comp_id, 'birthday_gift', '생일 축하 선물', NULL, 'perks',
   'est', NULL, TRUE, '생일 축하 선물 제공 (2025 지속가능경영보고서 경조사 및 라이프이벤트 지원 항목) — 선물 종류·금액 미기재', 14),

  -- ── 유연근무 (flexibility) — 복리 후생 업무 몰입 ──
  (@comp_id, 'flex_work', '시차출퇴근제 (오전 8~10시 출근)', NULL, 'flexibility',
   'est', NULL, TRUE, '업무와 삶의 균형을 위한 시차출퇴근제 시행(오전 8시~10시 사이 자유롭게 출근) (공식 채용 사이트 복리 후생 시차출퇴근제 항목 · 공식 홈페이지 ESG Social 자율 시차출근제 항목), 시차출근제 전면 도입 (2025 지속가능경영보고서 근무환경 및 일·삶의 균형 항목) — 코어타임 미기재', 20),

  -- ── 보상·금전 (compensation) — 복리 후생 클래시스 베네핏 / 보고서 ──
  (@comp_id, 'incentive', '인센티브 (연 1회)', 100, 'compensation',
   'est', '연 1회 성과를 나누는 인센티브 지급 (공식 채용 사이트 복리 후생 인센티브 지급 항목), 전 임직원 대상 성과 기반 단기 현금 인센티브 (2025 지속가능경영보고서) — 지급률 미기재 (추정)', FALSE, NULL, 30),
  (@comp_id, 'holiday_gift', '명절 상여금 (설·추석)', NULL, 'compensation',
   'est', NULL, TRUE, '명절 상여금 지급(참치캔 대신 상여금) (공식 채용 사이트 복리 후생 명절 상여금 항목), 구정 및 추석 명절 상여금 지급 (2025 지속가능경영보고서 경제적 안정 항목 · 공식 홈페이지 ESG Social 명절 상여금 항목) — 지급 금액·기준 미기재', 31),
  (@comp_id, 'excellence_award', '우수직원 표창', NULL, 'compensation',
   'est', NULL, TRUE, '리더십 인정 및 우수직원 표창 운영 (2025 지속가능경영보고서 성과 기반 변동 보상 제도 항목) — 선정 기준·포상 내용 미기재', 32),

  -- ── 성장·커리어 (growth) — 복리 후생 클래시스 베네핏 / 보고서 ──
  (@comp_id, 'self_development', '자기개발비 지원 (연 최대 100만원)', NULL, 'growth',
   'est', NULL, TRUE, '개인 성장을 위한 자기개발비 연 최대 100만원 지원 (공식 채용 사이트 복리 후생 자기개발비 지원 항목 · 공식 홈페이지 ESG Social 자기 개발비 지원 항목). 학위 취득·역량 강화 교육·세미나 및 워크숍 참가 등 자기 주도적 학습과 운동 시설 회원권 등 건강 관리 프로그램에 사용 (2025 지속가능경영보고서 성장 및 조직문화 · 건강 및 웰빙 지원 항목) — 한도 금액이며 1인 지급액 미기재', 40),
  (@comp_id, 'mba', '대학·대학원 학위 과정 학비 지원', NULL, 'growth',
   'est', NULL, TRUE, '대학 및 대학원 학위 과정에 대한 학비 지원 제도 운영 (2025 지속가능경영보고서 내부 이동 및 학위·자격증 취득 지원 항목) — 지원 한도·대상 조건·자기개발비(연 최대 100만원)와 같은 예산인지 미기재', 41),

  -- ── 여가·라이프 (leisure) — 복리 후생 클래시스 베네핏 · 조직문화 · 리프레시 ──
  (@comp_id, 'welcome_kit', '웰컴키트', NULL, 'leisure',
   'est', NULL, TRUE, '신규입사자 환대 선물로 웰컴키트 지급 (공식 채용 사이트 복리 후생 웰컴키트 지급 항목), 신규 입사자 웰컴 패키지 (2025 지속가능경영보고서 경조사 및 라이프이벤트 지원 항목) — 구성품 미기재', 50),
  (@comp_id, 'club', '동호회비 지원', NULL, 'leisure',
   'est', NULL, TRUE, '동호회비 지원 (공식 채용 사이트 복리 후생 동호회비 지원 항목 · 공식 홈페이지 ESG Social 동호회 지원 항목), 사내 동호회(스포츠·문화 등) 활동비 정기 지원, 2025년 풋살·당구·경제·독서 등 동호회에 206명 참여 (2025 지속가능경영보고서 성장 및 조직문화 항목) — 1인 지원 금액 미기재', 51),
  (@comp_id, 'company_event', '이어엔드 파티', NULL, 'leisure',
   'est', NULL, TRUE, '상반기 타운홀·하반기 이어엔드 파티에서 성과를 공유하고 서로를 격려하는 행사 (공식 채용 사이트 복리 후생 조직문화 타운홀 / 이어엔드 파티 항목) — 행사 내용·비용 미기재', 52),
  (@comp_id, 'summer_vacation_subsidy', '하계 휴가비', NULL, 'leisure',
   'est', NULL, TRUE, '즐거운 하계 휴가를 위한 하계휴가비 지급 (공식 채용 사이트 복리 후생 리프레시 하계 휴가비 항목 · 공식 홈페이지 ESG Social 여름휴가비 지원 항목), 하계 유급휴가와 함께 휴가비 별도 지원 (2025 지속가능경영보고서) — 지급 금액 미기재', 53),
  (@comp_id, 'resort', '제휴 휴양시설', 50, 'leisure',
   'est', '제휴된 국내 휴양시설 이용 가능 (공식 채용 사이트 복리 후생 제휴 휴양시설 항목), 가족 단위 휴식을 위한 휴양시설 이용 지원 (2025 지속가능경영보고서) — 이용 일수·지원 방식 미기재 (추정)', FALSE, NULL, 54),

  -- ── 가족·돌봄 (family) — 복리 후생 클래시스 베네핏 / 보고서 ──
  (@comp_id, 'event', '경조사 지원 (경조 물품·경조금·특별휴가)', NULL, 'family',
   'est', NULL, TRUE, '기쁨과 슬픔을 함께 나누는 경조사 지원 (공식 채용 사이트 복리 후생 경조사 지원 항목 · 공식 홈페이지 ESG Social 경조사 지원 항목), 본인 및 가족의 경조사 발생 시 경조 물품·경조금과 특별 휴가 제공 (2025 지속가능경영보고서 경조사 및 라이프이벤트 지원 항목) — 경조 종류별 금액·휴가 일수 미기재', 60),
  (@comp_id, 'parenting', '출산 축하금', NULL, 'family',
   'est', NULL, TRUE, '출산 축하금 지급 (2025 지속가능경영보고서 근무환경 및 일·삶의 균형 복리후생 프로그램 항목) — 지급 금액·지급 대상 미기재', 61),

  -- ── 건강·의료 (health) — 복리 후생 클래시스 베네핏 / 보고서 ──
  (@comp_id, 'health_check', '건강검진 지원', 100, 'health',
   'est', '30세 이상 건강검진 지원 (공식 채용 사이트 복리 후생 건강검진 지원 항목), 매년 전 구성원 종합 건강검진 비용 지원 (2025 지속가능경영보고서) — 검진 금액 미기재 (추정)', FALSE, NULL, 70),

  -- ── 근무환경 (work_env) — 복리 후생 근무 환경 / 보고서 ──
  (@comp_id, 'lounge', '사내 휴게실 (안마의자·체성분 측정기)', NULL, 'work_env',
   'est', NULL, TRUE, '휴게실 운영 (공식 채용 사이트 복리 후생 근무 환경 휴게실·카페테리아 운영 항목 · 공식 홈페이지 ESG Social 카페테리아 및 직원 휴게실 지원 항목), 안마의자와 체성분 측정기를 비치한 사내 휴게실 (2025 지속가능경영보고서 건강 및 웰빙 지원 항목) — 운영 시간 미기재', 80),

  -- ── 시간·휴가 (time_off) — 복리 후생 리프레시 / 보고서 ──
  (@comp_id, 'summer_leave', '하계 휴가 3일 (추가)', NULL, 'time_off',
   'est', NULL, TRUE, '열심히 일한 구성원의 충분한 휴식을 위해 기본 휴가 외 추가 3일의 여름 휴가 제공 (공식 채용 사이트 복리 후생 리프레시 하계 휴가 3일 항목), 기본 휴가 외 하계 유급휴가 별도 지원 (2025 지속가능경영보고서 · 공식 홈페이지 ESG Social 하계유급휴가 항목) — 사용 시기 미기재', 90),
  (@comp_id, 'leave_general', '2시간 단위 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '휴가를 2시간 단위로 나누어 쓰는 방식 지원 (2025 지속가능경영보고서 충분한 휴식 및 휴양 지원 항목)', 91),
  (@comp_id, 'long_service_leave', '장기근속 포상 휴가·포상금 (10년)', NULL, 'time_off',
   'est', NULL, TRUE, '장기 근속한 구성원(10년)에게 추가 포상 휴가와 포상금 지급 (2025 지속가능경영보고서 장기근속자 포상 항목 · 공식 홈페이지 ESG Social 장기 근속자 포상 항목) — 휴가 일수·포상금 금액 미기재', 92)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
