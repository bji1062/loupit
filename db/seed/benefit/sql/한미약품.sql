-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 한미약품 복리후생 데이터
-- 출처: AI 파싱 (2026-10-04)
-- URL: https://sustainability.hanmi.co.kr/2025/ko/esgperformance/social/wellfareculture
-- badge: est
--
-- 참고:
--   정본은 한미약품 공식 홈페이지 www.hanmi.co.kr 의 한미 ESG → S(사회) 페이지(/about/esg/social.hm)가 복지 & 문화로 링크한
--   2025-26 한미약품 ESG Report 웹판(sustainability.hanmi.co.kr — 자기 도메인 하위 호스트) 복지&문화 페이지다(2026-10-02 수집). 서버 렌더 HTML 에
--   기업문화 조성(육아 지원 · 한미약품 근무제도)과 복리후생제도 표(본인주도 선택복지 ~ 장기근속/우수사원)가 있다.
--   보고 범위는 한미약품 본사 및 국내 사업장(같은 보고서 보고 범위 및 검증 페이지) — 종속기업 한미정밀화학 · 북경한미약품은
--     환경 · 임직원 데이터만 포함이라 복지 문구는 이 법인 것으로 봤다.
--   보조 출처 1: 같은 보고서 인적자본 페이지(/2025/ko/esgperformance/social/humancapitalmanagement) — H-MBA · 직무순환 Hanmi CDC ·
--     보상제도(PI · CIQ · SEM · QI · 주식 기반 성과보상) · 자랑스러운 한미인상.
--   보조 출처 2: 한미약품 브랜드 채용 사이트(마이다스 ATS) 복리후생 페이지 hanmi.recruiter.co.kr/career/welfare —
--     본문이 robots 전면 금지 API 에서만 와서 사이트 운영자가 2026-10-04 브라우저로 열어 붙여 넣은 화면 본문을 썼다
--     (사본 hanmi_pharm/user_paste_welfare_2026-10-04.txt · sha256 1e145dd9…9f70). Career · Wellbeing and Family · Work and Life 3구역 21항목.
--     본문 주어가 한미그룹의 복리후생이라 그 페이지 문장은 서술 괄호에 한미그룹 공통 문구로 적었고, 사업장별 상이 단서는 단서까지 적었다.
--   ESG 보고서 문장 가운데 주어가 한미그룹인 것(Hanmi CDC · 주식 기반 성과보상제도 · 자랑스러운 한미인상)도 같은 각주.
--   금액: 원문 명시 1(welfare_point 연 50만원 복지포인트) · 환산 1(parenting 다자녀 양육/교육지원금 분기 30만원 × 4) ·
--     구본 추정 승계 3(health_check 100 · resort 50 · commute_subsidy 120 — 전부 틀 값, NOTE 끝에 (추정)).
--     본인주도 선택복지 연 50만원 이내 실비는 한도, 어양 70% 는 비율, 출산 · 입학 축하 포인트와 골드바는 1회성이라 금액 칸에 넣지 않았다.
--     meal 은 구본 추정치의 전제(일 15,000원)가 원문에 없어 승계하지 않았다.
--   구본에서 뺀 행: edu_support(회사 주도 교육 과정).
--   제외 항목: 퇴직연금 · 재취업지원프로그램(1,000인 이상 법정) · 출산 전후 휴가 · 배우자 출산휴가 · 임신기 단축 · 태아 검진 휴가 ·
--     육아기 단축 · 육아휴직(법정) · Family Day(내용 미기재) · RSU(성과 달성 임직원 선별) · 간주근로제(사업장 밖 근로시간 산정 — 재량근로제 · 탄력근로제는 flex_work 서술에 실었다) · 회사 주도 교육 과정.
--   재코딩: 없음(birthday_gift 는 입사 1주년 축하 선물로 남기고, 기념일 포인트는 welfare_point 새 행으로 옮겼다).
--   SORT 섹션 순서 = 복지&문화 페이지에서 카테고리가 처음 나온 순서, 인적자본 · 채용 사이트에만 있는 행은 해당 섹션 끝,
--     채용 사이트에만 있는 카테고리는 맨 끝
--     (flexibility 10 · family 20 · perks 30 · health 40 · leisure 50 · work_env 60 · growth 70 · compensation 80 · time_off 90).
-- 재수집(2026-10-04): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 붙여넣기 반영(2026-10-04): 채용 사이트 복리후생 본문으로 meal · refresh_leave · leisure_ticket · birthday_gift 4행을 더하고 16행 서술을 보강 — 30행
-- 검증(2026-10-04, RV-3-7): refresh_leave 를 연간 휴가 총 22일만으로(Refresh 휴가 이름 한 줄은 뺌) · career 에 Hanmi CDC 프로세스 그림의 지원 절차 · meal · mba 서술 꼬리 표기 정리 — 최종 30행
-- 후속 정리 2(2026-10-04, R-3): 사용자가 정한 복지 범위 규칙 개정(규칙 8 · 기준 13 · 기준 18 · 기준 20 · 기준 23)과 코퍼스 판정을 반영 — 새 행 1(leave_general) · 서술 · 이름 수정 3(flex_work · remote_work · refresh_leave) — 최종 31행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hanmi_pharm', '한미약품',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '제약', 'H', 'https://sustainability.hanmi.co.kr/2025/ko/esgperformance/social/wellfareculture');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hanmi_pharm');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://sustainability.hanmi.co.kr/2025/ko/esgperformance/social/wellfareculture'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — 기업문화 조성 육아 지원 · 한미약품 근무제도 / 채용 사이트 유연근무제 ──
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '근로자가 출퇴근 시간·근무일을 자유롭게 선택하는 선택근로제, 업무수행 방법을 근로자의 재량에 위임하는 재량근로제, 업무량에 따라 유연하게 근무시간을 조절하는 탄력근로제 등 각 사업장과 개인 생활 특성에 맞춘 근무 제도, 근무 시간 온라인 관리 시스템 운영 (ESG 보고서 복지&문화 한미약품 근무제도 항목), 사업장/직군별 맞춤 유연근무제 (공식 채용 사이트 복리후생 유연근무제 항목, 한미그룹 공통 문구)', 10),
  (@comp_id, 'pc_off', 'PC OFF 제도', NULL, 'flexibility',
   'est', NULL, TRUE, '선택근로제의 일환으로 근로자가 스스로 지정한 근무 시간 종료 시 PC가 자동으로 종료 (ESG 보고서 복지&문화 한미약품 근무제도 항목)', 11),
  (@comp_id, 'remote_work', '육아기 재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '일과 가정이 양립할 수 있도록 운영하는 육아 지원 제도 가운데 재택근무 등 다양한 근무 형태 지원 (ESG 보고서 복지&문화 기업문화 조성 항목) — 대상·사용 기준 미기재', 12),

  -- ── 가족·돌봄 (family) — 기업문화 조성 사내 어린이집 / 복리후생제도 가정·경조사 / 채용 사이트 Wellbeing and Family ──
  (@comp_id, 'childcare', '사내 어린이집 (본사·팔탄사업장)', NULL, 'family',
   'est', NULL, TRUE, '사내 어린이집을 운영해 직원 자녀가 안전하고 편안하게 지낼 수 있는 환경 제공 (ESG 보고서 복지&문화 기업문화 조성 항목), 어린이집 운영 본사·팔탄사업장 (같은 페이지 복리후생제도 가정/경조사 항목) — 정원·이용 조건 미기재', 20),
  (@comp_id, 'event', '경조사 지원·사우회', NULL, 'family',
   'est', NULL, TRUE, '본인 결혼 및 자녀 돌·결혼, 부모(배우자 포함) 환갑 또는 고희·팔순, 조위 시 경조금·경조휴가·화환/조화·조사용품·장례복지사 지원 (ESG 보고서 복지&문화 복리후생제도 가정/경조사 항목), 경조금·화환·휴가 등 지원, 전 임직원 대상 사우회 운영 (공식 채용 사이트 복리후생 경조사 지원 · 사우회 운영 항목, 한미그룹 공통 문구) — 경조 종류별 금액·휴가 일수 미기재', 21),
  (@comp_id, 'parenting', '다자녀 양육/교육지원금·출산 축하 포인트', 120, 'family',
   'est', '다자녀 가정 양육/교육지원금 미성년 둘째 자녀부터 분기 30만원 (연 120만원 환산), 출산 시(배우자 포함) 축하 복지포인트 50만원·자녀 초등학교 입학 시 10만원 (ESG 보고서 복리후생제도 가정/경조사 항목), 출산 축하 지원 전 임직원 자녀 (채용 사이트 복리후생, 한미그룹 공통 문구)', FALSE, NULL, 22),
  (@comp_id, 'child_edu', '자녀 학자금 (자녀 수 무관·전액)', NULL, 'family',
   'est', NULL, TRUE, '자녀 대학 학자금 지원, 자녀 수 상관없이 (ESG 보고서 복지&문화 복리후생제도 가정/경조사 항목), 자녀학자금 자녀수 무관 전액 (공식 채용 사이트 복리후생 자녀학자금 항목, 한미그룹 공통 문구) — 학교급별 지원 범위·학기 수 미기재', 23),

  -- ── 경제적 부가혜택 (perks) — 복리후생제도 본인주도 선택복지 · 생활안정 · 복지 포인트 · 휴양/문화 · 근무환경 / 채용 사이트 ──
  (@comp_id, 'welfare_point', '복지포인트·본인주도 선택복지', 50, 'perks',
   'est', '연 50만원 복지포인트 — 설·추석·생일·근로자의날·창립기념 각 10만원, 복지카드 발급, 본인주도 선택복지 연 50만원 이내 실비(자기계발·취미/여가·가족 의료비), 복지몰 할인 (ESG 보고서 복리후생제도), 기념일 축하 연 5회 포인트 (채용 사이트 복리후생, 한미그룹 공통 문구)', FALSE, NULL, 30),
  (@comp_id, 'housing_loan', '주택자금·생활안정 사내대출', NULL, 'perks',
   'est', NULL, TRUE, '주택자금/생활안정 사내대출 지원 (ESG 보고서 복지&문화 복리후생제도 생활안정 항목), 주택자금을 위한 사내대출 (공식 채용 사이트 복리후생 주택자금 지원 항목, 한미그룹 공통 문구) — 대출 한도·금리 미기재', 31),
  (@comp_id, 'discount', '중식당 어양 70% 할인', NULL, 'perks',
   'est', NULL, TRUE, '고급 중식당 「어양」 70% 할인 (공식 채용 사이트 복리후생 고급 중식당 할인 항목, 한미그룹 공통 문구), 중식당 「어양」 임직원 공휴일 이용 시 회사 지원 (ESG 보고서 복지&문화 복리후생제도 휴양/문화 항목) — 이용 한도 미기재', 32),
  (@comp_id, 'commute_subsidy', '통근셔틀버스·교통비', 120, 'perks',
   'est', '사업장/R&D센터 통근셔틀버스 운영 (ESG 보고서 복리후생제도 근무환경 항목), 셔틀버스·교통비 지원, 사업장별 상이 (채용 사이트 통근/피복 지원 항목, 한미그룹 공통 문구) — 노선·교통비 금액 미기재 (추정)', FALSE, NULL, 33),
  (@comp_id, 'snack_bar', '본사 사내카페 EQUAL GARDEN', NULL, 'perks',
   'est', NULL, TRUE, '본사 사내카페(EQUAL GARDEN) 운영 (ESG 보고서 복지&문화 복리후생제도 근무환경 항목) — 이용 비용 미기재', 34),
  (@comp_id, 'meal', '구내식당 조식·중식·석식 (사업장별 상이)', NULL, 'perks',
   'est', NULL, TRUE, '구내식당 운영, 조식·중식·석식 제공, 사업장별 상이 (공식 채용 사이트 복리후생 구내식당 운영 항목, 한미그룹 공통 문구) — 사업장별 제공 끼니·식대 부담 미기재', 35),
  (@comp_id, 'birthday_gift', '입사 1주년 축하 선물', NULL, 'perks',
   'est', NULL, TRUE, '입사 1주년 축하 선물, 인재 Retention Program (공식 채용 사이트 복리후생 입사 1주년 축하 선물 항목, 한미그룹 공통 문구) — 선물 내용 미기재', 36),

  -- ── 건강·의료 (health) — 복리후생제도 생활안정 · 의료 · 근무환경 / 채용 사이트 건강관리 ──
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '단체상해보험 가입 (ESG 보고서 복지&문화 복리후생제도 생활안정 항목) — 보장 범위·가족 포함 여부 미기재', 40),
  (@comp_id, 'health_check', '연 1회 건강검진', 100, 'health',
   'est', '연 1회 건강검진 지원 및 직원가족 건강검진 비용 할인 (ESG 보고서 복지&문화 복리후생제도 의료 항목), 건강검진 연 1회 (채용 사이트 복리후생 건강관리 항목, 한미그룹 공통 문구) — 검진 항목·지원 한도 미기재 (추정)', FALSE, NULL, 41),
  (@comp_id, 'mental', '심리상담 지원', NULL, 'health',
   'est', NULL, TRUE, '심리상담 지원 (ESG 보고서 복지&문화 복리후생제도 의료 항목) — 상담 방식·횟수 미기재', 42),
  (@comp_id, 'fitness', '본사 체육시설 BALANCE LAB', NULL, 'health',
   'est', NULL, TRUE, '본사 체육시설(BALANCE LAB) 운영 (ESG 보고서 복지&문화 복리후생제도 근무환경 항목) — 이용 시간·비용 미기재', 43),

  -- ── 여가·라이프 (leisure) — 복리후생제도 휴양/문화 · 근무환경 / 채용 사이트 임직원 할인 · 문화생활지원 ──
  (@comp_id, 'resort', '법인 콘도 회원권·호텔 콘도 할인', 50, 'leisure',
   'est', '법인 콘도 회원권으로 임직원 회원가 숙박 이용 (ESG 보고서 복리후생제도 휴양/문화 항목), 전국 유명 호텔·콘도 임직원 할인 (채용 사이트 복리후생 임직원 할인 항목, 한미그룹 공통 문구) — 이용 일수·할인율 미기재 (추정)', FALSE, NULL, 50),
  (@comp_id, 'welcome_kit', '입사자 웰컴선물', NULL, 'leisure',
   'est', NULL, TRUE, '입사자 웰컴선물 지급 (ESG 보고서 복지&문화 복리후생제도 근무환경 항목) — 선물 내용 미기재', 51),
  (@comp_id, 'leisure_ticket', '문화생활 지원 (한미사진미술관·사회공헌 콘서트)', NULL, 'leisure',
   'est', NULL, TRUE, '문화생활 지원(한미사진미술관, 사회공헌 콘서트 등) (공식 채용 사이트 복리후생 문화생활지원 항목, 한미그룹 공통 문구) — 지원 방식·횟수 미기재', 52),

  -- ── 근무환경 (work_env) — 복리후생제도 근무환경 / 채용 사이트 편의시설 운영 · 통근/피복 지원 ──
  (@comp_id, 'lounge', '라운지·직원휴게실·여성휴게실·수유실', NULL, 'work_env',
   'est', NULL, TRUE, '전 사업장 직원휴게실 운영 — 다과 및 휴식 장소 제공, 여성휴게실·수유실 운영 (ESG 보고서 복지&문화 복리후생제도 근무환경 항목), 라운지·휴게실·여성 휴게실·수유실 등 편의시설 운영 (공식 채용 사이트 복리후생 편의시설 운영 항목, 한미그룹 공통 문구)', 60),
  (@comp_id, 'uniform', '직무별 피복 지원', NULL, 'work_env',
   'est', NULL, TRUE, '직무별 피복 지원 (ESG 보고서 복지&문화 복리후생제도 근무환경 항목), 피복지원 사업장별 상이 (공식 채용 사이트 복리후생 통근/피복 지원 항목, 한미그룹 공통 문구) — 지급 품목·주기 미기재', 61),

  -- ── 성장·교육 (growth) — 복리후생제도 자기계발 / 인적자본 인재 육성 · Hanmi CDC / 채용 사이트 Career ──
  (@comp_id, 'self_development', '개인학자금 (핵심인재 상급학교 전액)', NULL, 'growth',
   'est', NULL, TRUE, '대학 학자금 지원, 선정 시 (ESG 보고서 복지&문화 복리후생제도 자기계발 항목), 핵심인재 대상 상급학교 학자금 전액 (공식 채용 사이트 복리후생 개인학자금 항목, 한미그룹 공통 문구) — 핵심인재 선정 기준 미기재', 70),
  (@comp_id, 'mba', 'H-MBA 핵심인재 프로그램', NULL, 'growth',
   'est', NULL, TRUE, '핵심인재 역량 강화를 위한 H-MBA 실시, 매일경제신문·멀티캠퍼스·한미그룹 공동 운영, 우수한 성적으로 수료한 직원에게 임원 추천을 거쳐 상급학교 석박사과정 학비 지원 (ESG 보고서 인적자본 인재 육성 항목), H-MBA 운영 핵심인재 Program (공식 채용 사이트 복리후생 항목, 한미그룹 공통 문구) — 선발 기준·지원 한도 미기재', 71),
  (@comp_id, 'career', '직무순환 잡 포스팅 (Hanmi CDC)', NULL, 'growth',
   'est', NULL, TRUE, '임직원 경력개발을 위한 직무순환 제도 Hanmi CDC, 커리어 마켓에서 희망직무에 지원하거나 전 직원 대상 채용 공지(잡 포스팅)에 지원하면 해당 부서 면접 및 선별을 거쳐 직무 이동 (ESG 보고서 인적자본 직무순환제도 항목·Hanmi CDC 프로세스), 다양한 부서 및 업무 경험으로 커리어 개발 지원 (공식 채용 사이트 복리후생 경력개발 직무순환 항목) — 두 출처 모두 한미그룹 공통 문구, 지원 자격 미기재', 72),

  -- ── 보상·금전 (compensation) — 복리후생제도 장기근속/우수사원 / 인적자본 보상제도 / 채용 사이트 장기근속 ──
  (@comp_id, 'long_service_bonus', '장기근속 골드바 근속기념패', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 시 골드바 근속기념패 지급 — 10년 10g·20년 20g·30년 30g (ESG 보고서 복지&문화 복리후생제도 장기근속/우수사원 항목), 장기근속 골드바 지급 (공식 채용 사이트 복리후생 항목, 한미그룹 공통 문구)', 80),
  (@comp_id, 'excellence_award', '우수사원 포상·자랑스러운 한미인상', NULL, 'compensation',
   'est', NULL, TRUE, '우수사원 포상 (ESG 보고서 복지&문화 복리후생제도 장기근속/우수사원 항목), 임원이 아닌 직원으로 한정해 보이지 않는 곳에서 묵묵히 성과를 창출한 실무자를 발굴해 격려하는 자랑스러운 한미인상 (같은 보고서 인적자본 보상제도 항목, 한미그룹 공통 문구) — 포상 내용 미기재', 81),
  (@comp_id, 'incentive', '경영성과금 PI·CIQ·SEM·QI', NULL, 'compensation',
   'est', NULL, TRUE, '반기별 업무성과를 바탕으로 개인별 성과금 연 2회 차등 지급(경영성과금 PI), 부서별 기간 목표 결과를 보상하는 CIQ, 국내사업부 월별 인센티브 SEM, 국내영업본부 매분기 성과 보상 QI(영업/마케팅) (ESG 보고서 인적자본 보상제도 항목), 반기 평가 결과에 따른 성과인센티브 금액의 50~100%를 자사주로 선택 수령 가능하고 주가 하락 손실은 회사가 보전 (같은 항목 주식 기반 성과보상제도, 한미그룹 공통 문구) — 지급률 미기재', 82),

  -- ── 시간·휴가 (time_off) — 채용 사이트 휴가 및 숙박 지원 ──
  (@comp_id, 'refresh_leave', 'Refresh 휴가 (연말 재충전 휴가)', NULL, 'time_off',
   'est', NULL, TRUE, '연말 재충전 휴가(Refresh 휴가) 제도 (2025-26 ESG 보고서 복지&문화 Refresh 휴가 항목), Refresh (공식 채용 사이트 복리후생 휴가 및 숙박 지원 항목, 한미그룹 공통 문구) — 휴가 일수·부여 조건 미기재', 90),
  (@comp_id, 'leave_general', '연간 휴가 총 22일', NULL, 'time_off',
   'est', NULL, TRUE, '연간 휴가 총 22일 (공식 채용 사이트 복리후생 휴가 및 숙박 지원 항목, 한미그룹 공통 문구) — 근속에 따른 일수 변동·사용 방식 미기재', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
