-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 효성중공업 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://www.hyosungheavyindustries.com/kr/company/recruitment/personnel-system
-- badge: est
--
-- 참고:
--   정본은 법인 자기 도메인 www.hyosungheavyindustries.com 헤더 메뉴 Company → 인재채용 → 인사제도
--   (/kr/company/recruitment/personnel-system)다. 서버 렌더 정적 HTML, robots.txt 전체 허용.
--   보상체계 절(기본급 · 수당 · 성과급)과 일과 삶의 균형 절(탭 5개 · 항목 25개)이 있다. 주석 속 블록 · 숨김 블록에 복지 문장 없음.
--   보조 출처: 같은 사이트 Sustainability → 보고서의 2025 효성중공업 지속가능경영보고서 국문 PDF(2026년 6월 발간,
--     /resources/files/sustainability/report/SR_2025_kr.pdf) 87쪽 복리후생 · 88쪽 임직원 마음건강 관리 · 가족친화 정책 표.
--     보고서 근거 구절은 서술 괄호에 보고서 이름과 쪽을 적어 구분했다.
--   귀속: 인사제도 페이지 머리 문장 주어가 효성중공업이고 보고서도 이 법인 단독 보고서라 그룹 각주 없음.
--     효성티앤씨 인사제도 페이지가 같은 틀이지만 주어와 항목이 달라 형제 법인 문장은 옮기지 않았다.
--   부문: 중공업 · 건설 부문으로 복지 제도를 가르는 문장이 두 출처 모두 없다. 원문이 밝힌 사업장(마포 · 창원 어린이집,
--     지방 사업장 교통비)만 서술에 적었다.
--   금액: 원문 명시 연 금액 없음. 출산축하금 1인당 500만원은 1회성이라 금액 칸에 넣지 않았다.
--     구본 추정치 3(event 50 · discount 30 · birthday_gift 20)은 승계하지 않았다(경조금 · 회사 고유값인데 원문에 전제 없음).
--   제외: 리프레쉬 휴가(5일 연속 본인 휴가 사용 보장) · 지정 휴무일(징검다리 휴일 본인 휴가 사용) · 시간 외 근로수당 ·
--     정년퇴직 예정자 재취업지원과 만 50세 이상 진로 설계교육(보고서 88쪽 퇴직 예정인 만 50세 이상 — 1,000인 이상 법정) ·
--     금연 프로그램(보고서 45쪽 산업보건 활동) · 법정 모성보호 · 가족돌봄 제도 · HR 상담센터(고충 처리) · 소통 게시판 ·
--     입문교육 · OJT · 유소견자 사후관리 · 해외 안전관리 서비스. 어학 프로그램 · 온라인 자기계발 프로그램은 2026-10-04 규칙 8 개정으로 lang · edu_support 에 되살렸다.
--   재코딩: bonus → incentive(성과 연동 성과급) · career → excellence_award(자랑스러운 효성인상 시상) ·
--     long_service → long_service_leave(근속 포상 휴가).
--   SORT 섹션 순서 = 인사제도 페이지에서 카테고리가 처음 나온 순서, 보고서 근거 행은 해당 섹션 끝
--     (compensation 10 · time_off 20 · family 30 · perks 40 · flexibility 50 · growth 60 · leisure 70 · health 80).
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-7): 만 50세 이상 진로설계교육(퇴직 예정자 대상 법정) · 금연 프로그램 행을 빼고 창립기념품을 holiday_gift 로 가름 — 최종 20행
-- 후속 정리 2(2026-10-04, R-3): 사용자가 정한 복지 범위 규칙 개정(규칙 8 · 기준 13 · 기준 18 · 기준 20 · 기준 23)과 코퍼스 판정을 반영 — 새 행 1(lang) · 서술 · 이름 수정 1(edu_support) — 최종 21행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hyosung_heavy', '효성중공업',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '전력/중공업', '효', 'https://www.hyosungheavyindustries.com/kr/company/recruitment/personnel-system');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyosung_heavy');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.hyosungheavyindustries.com/kr/company/recruitment/personnel-system'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) — 인사제도 보상체계 · 업무 몰입 지원 ──
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '사업부(Performance Unit) 평가와 연계하여 성과극대화 도모, 연초 조직이 설정한 목표 대비 달성도에 따른 차별적 보상 (공식 홈페이지 인재채용 인사제도 보상체계 성과급 항목) — 지급 기준·지급률 미기재', 10),
  (@comp_id, 'excellence_award', '자랑스러운 효성인상 시상', NULL, 'compensation',
   'est', NULL, TRUE, '마케팅, 기술, 연구, 지원 4개 부문별로 분기 및 연간 단위로 회사의 성과와 발전을 위해 노력한 임직원을 선발하여 시상, 수상자에게 포상금 및 인사 혜택 부여 (공식 홈페이지 인재채용 인사제도 업무 몰입 지원 · 조직문화 활동 확대 항목) — 포상금 액수 미기재', 11),
  (@comp_id, 'holiday_gift', '창립기념품', NULL, 'compensation',
   'est', NULL, TRUE, '창립기념일에 모든 임직원에게 창립기념품 지급 (공식 홈페이지 인재채용 인사제도 기념일 선물 항목) — 기념품 종류·가액 미기재', 12),

  -- ── 시간·휴가 (time_off) — 생활 균형 지원 ──
  (@comp_id, 'long_service_leave', '장기근속자 포상 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '10년/20년 근속자에게 포상 휴가 지급 (공식 홈페이지 인재채용 인사제도 장기근속자 포상 항목), 5·10·15·20·30년 장기 근속 임직원 포상 제도 운영 (2025 지속가능경영보고서 88쪽) — 휴가 일수·포상 내용 미기재', 20),

  -- ── 가족·돌봄 (family) — 생활 균형 지원 · 가족 안정 지원 / 2025 보고서 88쪽 ──
  (@comp_id, 'event', '경조금 및 경조 휴가', NULL, 'family',
   'est', NULL, TRUE, '임직원의 경조 및 재해에 관한 경조금 및 휴가 부여 (공식 홈페이지 인재채용 인사제도 경조금 및 경조 휴가 항목) — 경조 유형별 금액·휴가 일수 미기재', 30),
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '마포, 창원 사업장에 어린이집 운영, 전문 위탁업체 교사를 통한 보육 서비스와 정기적인 환경 유해 요소 검출 검사 (공식 홈페이지 인재채용 인사제도 사내 어린이집 항목) — 정원·입소 조건 미기재', 31),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '국내 정규 고등학교 및 4년제 정규대학·전문대학에 진학하거나 재학 중인 자녀의 입학금 및 등록금 전액 지원, 외국 고등학교 및 대학교 재학 시에도 지원금 제공 (공식 홈페이지 인재채용 인사제도 자녀 학자금 지원 항목) — 자녀 수 제한·해외 지원금 액수 미기재', 32),
  (@comp_id, 'parenting', '출산축하금 · 업무 분담자 보상', NULL, 'family',
   'est', NULL, TRUE, '임직원 자녀 출생 시 자녀 수 제한 없이 1인당 500만원 지급, 자녀 양육 휴직자 발생 팀 내 업무 분담자에게 보상금 지급, 수유실 운영 (2025 지속가능경영보고서 88쪽 가족친화 정책 표 · 공식 홈페이지 인재채용 인사제도 가족 안정 지원 항목) — 업무 분담 보상금 액수 미기재', 33),

  -- ── 경제적 부가혜택 (perks) — 생활 균형 지원 / 2025 보고서 88쪽 ──
  (@comp_id, 'birthday_gift', '생일 선물 (본인·지정 1인)', NULL, 'perks',
   'est', NULL, TRUE, '임직원 본인 및 임직원이 지정하는 1인의 생일 시 선물 지급 (공식 홈페이지 인재채용 인사제도 기념일 선물 항목) — 선물 가액 미기재', 40),
  (@comp_id, 'discount', '임직원 제휴 할인', NULL, 'perks',
   'est', NULL, TRUE, '효성그룹 제휴 복지몰 이용 가능, 세빛섬 임직원 할인가격 이용 (공식 홈페이지 인재채용 인사제도 임직원 제휴 할인 항목) — 할인율 미기재', 41),
  (@comp_id, 'transport', '지방사업장 교통비 지원', NULL, 'perks',
   'est', NULL, TRUE, '지방 사업장에 근무하는 수도권 연고지 임직원에게 사업장에서 연고지까지의 왕복 교통비를 월 2회 실비 지원, 연고지 기준은 기혼자 배우자·자녀 거주지 · 미혼자 부모 거주지, 2025년 10월 1일 시행 (2025 지속가능경영보고서 88쪽 가족친화 정책 표) — 1회 지원 한도 미기재', 42),

  -- ── 근무유연성 (flexibility) — 생활 균형 지원 ──
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '업무 생산성을 높이기 위한 유연근무제 시행, 선택적 근로시간제와 탄력적 근로시간제 운영, 임직원 개인별 업무량에 따라 근로시간을 적절히 배분하고 근로자 선택에 맡기는 운영 (공식 홈페이지 인재채용 인사제도 유연근무제 실시 항목) — 적용 직무·코어타임 미기재', 50),

  -- ── 성장·커리어 (growth) — 업무 몰입 지원 ──
  (@comp_id, 'mba', '학위과정 지원', NULL, 'growth',
   'est', NULL, TRUE, '국내외 학술연수자 학위과정 지원 (공식 홈페이지 인재채용 인사제도 학위과정 지원 항목) — 선발 기준·지원 범위 미기재', 61),
  (@comp_id, 'edu_support', '역량개발 사외교육·온라인 자기계발 지원', NULL, 'growth',
   'est', NULL, TRUE, '임직원의 역량 개발을 위해 본인이 수강하는 직무, 외국어 등 사외 교육과정 비용 지원 (공식 홈페이지 인재채용 인사제도 역량개발 사외교육 지원 항목), 온라인 플랫폼을 통한 문화 체험·명상 등 프로그램과 시간과 공간의 제약 없이 학습 및 미디어 콘텐츠를 이용하는 온디맨드(On-demand) 오디오 서비스 (2025 지속가능경영보고서 85쪽 온라인 자기계발 지원 프로그램) — 지원 한도 미기재', 62),
  (@comp_id, 'lang', '어학 프로그램 지원 (온/오프라인)', NULL, 'growth',
   'est', NULL, TRUE, '해외 근무자 및 희망자 온/오프라인 어학프로그램 지원 (공식 홈페이지 인재채용 인사제도 어학 프로그램 지원 항목) — 대상 언어·비용 부담·운영 방식 미기재', 63),

  -- ── 여가·라이프 (leisure) — 휴식 지원 ──
  (@comp_id, 'summer_vacation_subsidy', '하기 휴가비', NULL, 'leisure',
   'est', NULL, TRUE, '모든 임직원에게 연중에 연속으로 사용할 수 있는 하기 휴가 및 휴가비 지급 (공식 홈페이지 인재채용 인사제도 하기 휴가 및 휴가비 항목) — 휴가비 액수·휴가 일수 미기재', 70),
  (@comp_id, 'club', '동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '임직원 동호회 활동 비용 지급 (공식 홈페이지 인재채용 인사제도 여가 활동 지원 항목) — 지원 금액 미기재', 71),
  (@comp_id, 'resort', '콘도 지원', NULL, 'leisure',
   'est', NULL, TRUE, '임직원 및 직계 가족이 사용 가능한 콘도 지원, 임직원 및 직계가족의 콘도 회원권 이용 지원 (공식 홈페이지 인재채용 인사제도 여가 활동 지원 · 콘도 회원권 이용 항목) — 이용 횟수·본인 부담 미기재', 72),

  -- ── 건강·의료 (health) — 건강 증진 지원 / 2025 보고서 88쪽 ──
  (@comp_id, 'health_check', '종합 건강검진', NULL, 'health',
   'est', NULL, TRUE, '모든 임직원 대상 종합 검진 제공, 만 40세 이상 임직원의 배우자 대상 종합 검진 제공 (공식 홈페이지 인재채용 인사제도 건강 검진 제공 항목) — 검진 주기·항목 미기재', 80),
  (@comp_id, 'insurance', '단체 상해보험', NULL, 'health',
   'est', NULL, TRUE, '모든 임직원 단체상해보험(실비) 제공 (공식 홈페이지 인재채용 인사제도 단체 상해보험 제공 항목) — 보장 한도 미기재', 81),
  (@comp_id, 'mental', '심리 상담 (연 5회)', NULL, 'health',
   'est', NULL, TRUE, '외부 전문 기관과 연계한 심리 상담 프로그램, 직무 스트레스·개인 심리정서·가족 관계·법률·세무 분야 상담, 임직원 1인당 연 5회 상담 기회, 2025년 10월 1일 시행 (2025 지속가능경영보고서 88쪽 임직원 마음건강 관리) — 가족 이용 여부 미기재', 82)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
