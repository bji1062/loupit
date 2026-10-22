-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 코오롱글로벌 복리후생 데이터 (신규 회사 — 웨이브 14)
-- 출처: AI 파싱 (2026-10-22)
-- URL: https://www.kolonglobal.com/sub/personnel03.php
-- badge: est
--
-- 참고:
--   정본은 코오롱글로벌 자기 도메인 www.kolonglobal.com 인재채용 > 복리후생 페이지(서버렌더 HTML, 12개 항목 카드)다.
--   보조 출처 1: 같은 도메인 인재채용 > 인재육성 페이지(personnel02.php) 개인역량 개발 · 차세대 리더 양성 칸.
--   보조 출처 2: 같은 도메인 지속가능경영 > 보고서 목록의 2026 지속가능경영보고서 PDF(99쪽, 2026년 6월 작성 ·
--   보고 기간 2025년, 보고 범위 코오롱글로벌 단독) 52쪽 임직원 역량 개발 · 54쪽 인권 고충 처리 · 55쪽 기업문화
--   (유연근무제도 · 가족친화제도 · 복리후생 카드 11개).
--   보조 출처 3: OpenDART 2026 반기보고서(20260814003744) 유연근무제도 사용 현황 표 · 2025 사업보고서(20260323001556)
--   별도 재무제표 주석 기타장기종업원급여부채.
--   렌더 방식: 원본 HTML 텍스트 · PDF 텍스트 레이어(PyMuPDF) · DART 원문 XML — 헤드리스 렌더 · 이미지 판독 없음.
--   귀속: 정본 · 보고서 모두 주어가 코오롱글로벌인 법인 자기 도메인 자료 — 그룹 각주 없음. 그룹 채용 사이트
--   dream.kolon.com 은 지원서 접수 창구로만 링크되어 쓰지 않았다. 기등록 형제 코오롱인더스트리와 문장이 다르다.
--   금액: 원문에 임직원 복지 원 단위 금액 0건 — 25행 전부 BENEFIT_AMT NULL(stated 0 · 추정 0).
--   제외 요약: 법정(반차 · 출산휴가와 육아휴직 법정 기준 보장 · 임신 여성 직원 본인의 태아 검진 · 연차사용 촉진 ·
--   법정 의무교육) · 업무 교육(채용연계형 인턴십 · 멘토링 · 입문교육 · 승진자 · 팀장 육성 · 사내 직무교육 · 공종별
--   아카데미 · BIM) · 장애인 스포츠단 우수선수 포상 · 노사협의회 창립기념일 행사 공지 · 임원 보수지급기준 칸.
--   공고 근거 0행 / 전체 25행.
--   SORT 섹션 순서 = 정본 페이지에서 카테고리가 처음 나온 순서(family 10 · perks 20 · time_off 30 · flexibility 40 ·
--   health 50 · compensation 60 · leisure 70), 보조 출처에만 있는 카테고리는 끝(work_env 80 · growth 90).
-- 검증 · 감사 판정 반영(2026-10-22): 휴가철 현물 지원을 summer_vacation_subsidy 에서 holiday_gift 창립기념일 현물 행으로 병합하고 SORT 70 삭제(현금 휴가비 아님) · 기타장기종업원급여 행 서술에 원문 주어 당사 내 일부 기업들은 한정을 살림 · 가족 행 서술 어순을 배우자 태아 검진 휴가로(항목 페이지 spouse 면) · 정본 HTML 주석 속 옛 카드 유입 0 · 참고 블록의 SORT 섹션 설명 leisure 70 은 이 판정으로 뒤집힘 — 최종 24행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('kolon_global', '코오롱글로벌',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '건설', 'K', 'https://www.kolonglobal.com/sub/personnel03.php');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kolon_global');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.kolonglobal.com/sub/personnel03.php'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 가족·돌봄 (family) — 공식 채용 페이지 복리후생 · 2026 지속가능경영보고서 55쪽 ──
  (@comp_id, 'parenting', '임신·출산·자녀 입학 지원', NULL, 'family',
   'est', NULL, TRUE, '임신축하선물, 배우자 태아검진 지원 (공식 채용 페이지 복리후생 일 가정 양립지원 항목), 배우자가 임신한 남성 직원 대상 배우자 태아 검진 휴가 지급, 자녀 입학 돌봄 휴직 제도 운영 (2026 지속가능경영보고서 55쪽 가족친화제도 항목), 임신기 단축 근무를 법정 기준보다 2주 추가 지급 (같은 쪽 유연근무제도 항목) — 임신축하선물 구성·태아 검진 휴가 일수·자녀 입학 돌봄 휴직 기간과 유급 여부 미기재', 10),
  (@comp_id, 'fertility_support', '난임 시술비·난임 무급 휴직', NULL, 'family',
   'est', NULL, TRUE, '난임지원 (공식 채용 페이지 복리후생 일 가정 양립지원 항목), 남녀직원 모두에게 난임 시술비 지원, 여성직원은 본인의 희망에 따라 난임 무급 휴직 지원 (2026 지속가능경영보고서 55쪽 가족친화제도 항목) — 시술비 지원 한도·횟수와 휴직 기간 미기재', 11),
  (@comp_id, 'childcare', '직장어린이집 운영', NULL, 'family',
   'est', NULL, TRUE, '직장어린이집 운영 (공식 채용 페이지 복리후생 일 가정 양립지원 항목), 직장 어린이집 지원 (2026 지속가능경영보고서 55쪽 복리후생 항목) — 어린이집 위치·정원·대상 연령 미기재', 12),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '고등학생, 대학생 자녀를 둔 임직원 대상 교육비, 등록금 지원 (공식 채용 페이지 복리후생 자녀 학자금 지원 항목) — 지원 한도·자녀 수 제한 미기재', 13),
  (@comp_id, 'event', '경조금·화환·장례 지원', NULL, 'family',
   'est', NULL, TRUE, '경조금 및 화환 지원, 임직원 직계가족 사망 시 장례지도사 및 장례 물품 지원 (공식 채용 페이지 복리후생 경조사 지원 항목) — 경조 구분별 금액 미기재', 14),

  -- ── 경제적 부가혜택 (perks) — 공식 채용 페이지 복리후생 · 2026 지속가능경영보고서 55쪽 ──
  (@comp_id, 'housing_loan', '사내 전세자금 대출', NULL, 'perks',
   'est', NULL, TRUE, '주거 안정을 위한 분기별 사내 전세자금 대출 (공식 채용 페이지 복리후생 전세자금 대출 지원 항목) — 대출 한도·이율·자격 요건 미기재', 20),
  (@comp_id, 'discount', '코오롱 제품 임직원 할인', NULL, 'perks',
   'est', NULL, TRUE, '코오롱브랜드 상품 임직원 할인 지원 (공식 채용 페이지 복리후생 코오롱 제품 임직원 할인 항목), 코오롱 그룹 패션 계열 상품 임직원 할인가 제공 (2026 지속가능경영보고서 55쪽 임직원 할인가 지원 항목) — 할인율·대상 브랜드 미기재', 21),

  -- ── 휴가 (time_off) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'leave_general', '2시간 단위 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '2시간 단위 휴가 제도 운영 (공식 채용 페이지 복리후생 유연한 근무환경 지원 항목) — 사용 한도·신청 절차 미기재', 30),
  (@comp_id, 'birthday_leave', '생일 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '본인 생일이 속한 월에 1일 유급휴가 지원 (공식 채용 페이지 복리후생 생일 휴가 항목)', 31),
  (@comp_id, 'foundation_day_leave', '창립기념일 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '창립기념일 휴가 (공식 채용 페이지 복리후생 창립기념 현물지원 항목) — 휴가 일수 미기재', 32),

  -- ── 근무 유연성 (flexibility) — 공식 채용 페이지 복리후생 · 2026 지속가능경영보고서 54쪽 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '시차출퇴근제 (조건부)', NULL, 'flexibility',
   'est', NULL, TRUE, '시차출퇴근 본사 운영 (공식 채용 페이지 복리후생 유연한 근무환경 지원 항목), 2026년 상반기부터 30분 단위 시차출퇴근제 추가 도입 (2026 지속가능경영보고서 54쪽 인권 고충 처리 항목), 2025년 3월부터 시차출퇴근제 운영, 시차출퇴근제 사용자 수 2025년 180명·2026년 상반기 213명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 본사 밖 사업장 적용 여부 미기재', 40),

  -- ── 건강·의료 (health) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'health_check', '본인·배우자 건강검진', NULL, 'health',
   'est', NULL, TRUE, '임직원 본인 및 배우자 무료 건강검진 제공 (공식 채용 페이지 복리후생 건강검진 지원 항목) — 검진 주기·검진 항목 미기재', 50),
  (@comp_id, 'mental', '사내 심리상담 「상담 포유」', NULL, 'health',
   'est', NULL, TRUE, '사내 무료 심리상담 제도 「상담 포유」 운영 (공식 채용 페이지 복리후생 심리상담 지원 항목) — 상담 횟수·가족 이용 여부 미기재', 51),
  (@comp_id, 'insurance', '단체 상해보험', NULL, 'health',
   'est', NULL, TRUE, '전체 임직원 대상 단체 상해보험 비용 전액 지원 (공식 채용 페이지 복리후생 단체 상해보험 지원 항목) — 보장 범위·가족 가입 여부 미기재', 52),

  -- ── 보상·금전 (compensation) — 공식 채용 페이지 복리후생 · 2025 사업보고서 ──
  (@comp_id, 'holiday_gift', '창립기념일 · 휴가철 현물 지원', NULL, 'compensation',
   'est', NULL, TRUE, '창립기념일 현물 지원 (공식 채용 페이지 복리후생 창립기념 현물지원 항목, 2026 지속가능경영보고서 55쪽 창립기념일 현물지원 항목), 휴가철 현물 지원 (공식 채용 페이지 복리후생 휴가철 지원 항목), 임직원 대상 휴가철 현물 지원 (2026 지속가능경영보고서 55쪽 휴가철 지원 항목) — 현물 품목·금액·지급 시기 미기재', 60),
  (@comp_id, 'long_service_bonus', '장기 근속 임직원 장기종업원급여', NULL, 'compensation',
   'est', NULL, TRUE, '당사 내 일부 기업들은 장기 근속 임직원에게 장기종업원급여를 제공, 이 급여를 받을 수 있는 권리는 주로 10년 이상의 장기간 근무한 임직원에게만 부여 (2025 사업보고서 별도 재무제표 주석 기타장기종업원급여부채 항목) — 적용 범위·급부 형태·금액 미기재', 61),

  -- ── 여가·라이프 (leisure) — 공식 채용 페이지 복리후생 · 인재육성 · 2026 지속가능경영보고서 52·55쪽 ──
  (@comp_id, 'resort', '휴양지 제휴 할인', NULL, 'leisure',
   'est', NULL, TRUE, '유명 휴양지 제휴 할인가 제공 (공식 채용 페이지 복리후생 휴가철 지원 항목), 임직원 휴가철 전국 유명 휴양지 제휴 할인가 제공 (2026 지속가능경영보고서 55쪽 휴양지 이용 지원 항목) — 제휴 휴양지·할인 수준 미기재', 71),
  (@comp_id, 'library', '전자도서관', NULL, 'leisure',
   'est', NULL, TRUE, '지식과 정보에 자유롭게 접근할 수 있도록 전자도서관 제공 (공식 채용 페이지 인재육성 전자도서관 항목), 임직원들의 독서를 장려하기 위해 온라인 전자도서관 플랫폼 개설 (2026 지속가능경영보고서 52쪽 임직원 자기주도 학습 지원 항목) — 이용 가능 도서 범위 미기재', 72),

  -- ── 근무환경 (work_env) — 2026 지속가능경영보고서 55쪽 ──
  (@comp_id, 'nap_room', '임산부·수유 여성 휴식 공간 (Women’s Lounge)', NULL, 'work_env',
   'est', NULL, TRUE, '사내 Women’s Lounge 운영을 통해 임신 중이거나 수유가 필요한 여성 직원의 휴식 공간 제공 (2026 지속가능경영보고서 55쪽 가족친화제도 항목) — 설치 사업장 미기재', 80),

  -- ── 성장·교육 (growth) — 공식 채용 페이지 인재육성 · 2026 지속가능경영보고서 52쪽 ──
  (@comp_id, 'edu_support', '온라인 상시 교육 플랫폼 K-Learning', NULL, 'growth',
   'est', NULL, TRUE, '언제 어디서나 원하는 콘텐츠를 학습할 수 있도록 스마트러닝 플랫폼 운영 (공식 채용 페이지 인재육성 상시학습 프로그램 항목), 직원 개인의 관심사에 따른 자기주도 학습을 지원하기 위해 온라인 상시 교육 플랫폼 K-Learning 운영, 인문학, 경영학, 회계학, 자기계발 등 교육 콘텐츠 제공, 수료 시 교육비 전액 회사 지원 (2026 지속가능경영보고서 52쪽 임직원 자기주도 학습 지원 항목) — 연간 수강 한도 미기재', 90),
  (@comp_id, 'lang', '전화·온라인 어학교육', NULL, 'growth',
   'est', NULL, TRUE, '전화 및 온라인 교육을 통해 임직원의 어학 역량 강화 지원 (공식 채용 페이지 인재육성 어학교육 항목) — 대상 언어·본인 부담 여부 미기재', 91),
  (@comp_id, 'conference', '외부교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '직무 전문성 향상을 위한 외부 전문교육 참여 지원 (공식 채용 페이지 인재육성 외부교육 지원 항목) — 지원 한도·대상 과정 미기재', 92),
  (@comp_id, 'self_development', '세종사이버대학교 입학 특전', NULL, 'growth',
   'est', NULL, TRUE, '사내 만학도들을 지원하고자 세종사이버대학교와 업무 협약을 체결하여 학위 과정을 보다 저렴하게 이용할 수 있도록 지원 (2026 지속가능경영보고서 52쪽 임직원 자기주도 학습 지원 항목) — 할인 수준·신청 자격 미기재', 93),
  (@comp_id, 'mba', '석사과정·글로벌ESG건설학과 선발 교육', NULL, 'growth',
   'est', NULL, TRUE, '차세대 리더의 역량 강화를 위해 우수 대학과 연계하여 석사과정 교육기회 제공 (공식 채용 페이지 인재육성 차세대 리더 양성 항목), 중앙대학교와 협업하여 글로벌ESG건설학과를 설립·운영, 2023년 1학기부터 매년 회사의 우수 사원 6명을 선발하여 참여 (2026 지속가능경영보고서 52쪽 직무 전문성 향상 항목) — 선발 기준·비용 지원 범위 미기재', 94)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
