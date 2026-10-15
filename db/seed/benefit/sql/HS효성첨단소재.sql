-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- HS효성첨단소재 복리후생 데이터 (신규 회사 — 웨이브 9)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.hshyosungadvancedmaterials.com/kr/recruitment/personnel-system
-- badge: est
--
-- 참고:
--   정본은 법인 자기 도메인 www.hshyosungadvancedmaterials.com 헤더 메뉴 인재채용 → 인사제도 페이지다(서버 렌더 정적 HTML,
--   robots.txt 전체 허용). 일과 삶의 균형 절에 복지 항목이 이름으로 나열돼 있다. 옛 도메인 hyosungadvancedmaterials.com 은 인증서 만료.
--   보조 출처: 지속가능경영 사이트(sustainability.hshyosungadvancedmaterials.com) 보고서 목록의 2025 HS효성첨단소재 지속가능경영보고서
--     국문 PDF(2026년 5월 발행 · 보고 기간 2025-01-01~12-31 · 비재무 범위 HS효성첨단소재와 해외 사업장) 42~46 · 51쪽,
--     같은 사이트 인재경영 페이지(/kr/human/resource), OpenDART 2026 반기보고서(접수 20260814003921) 유연근무제도 사용 현황 표.
--   귀속: 인사제도 페이지의 주어는 HS효성이고 일과 삶의 균형 절이 지주 도메인 www.hshyosung.com 인사제도 페이지와 같은 글이다.
--     계열사별 상이 단서가 없어 그룹 공통 제도로 보고, 그 페이지에만 근거한 구절의 출처 괄호에 HS효성그룹 공통 문구 각주를 달았다.
--     보고서 · 인재경영 페이지는 주어가 HS효성첨단소재인 법인 단독 자료라 각주 없음.
--   금액: 원문에 연 금액이 없어 전 행 정성(금액 NULL).
--   제외: 법정 모성보호 · 출산 · 배우자 출산 · 유사산 · 난임 치료 · 육아휴직 · 육아기 단축 · 가족돌봄 · 수유 시간 · 은퇴 준비 단축 근로 ·
--     리프레시 휴가와 전사 지정 휴무일(본인 연차를 이어 쓰는 제도) · 휴가 사용 촉진 · 시간 외 근로수당 · 자격 수당(급여성) · 자율 복장 ·
--     입문 · OJT · 리더십 · 승격자 교육 · 주재원 · 현지 채용 인력 교육 · 노사협의회 안건(논의만) · 지주사 주관 올해의 HS효성인상.
--   SORT 섹션 순서 = 인사제도 페이지에서 카테고리가 처음 나온 순서, 보조 출처에만 있는 행은 해당 섹션 끝
--     (compensation 10 · flexibility 20 · family 30 · perks 40 · leisure 50 · work_env 60 · growth 70 · health 80 · time_off 90).
-- 검증 · 감사 판정 반영(2026-10-15): 제휴 할인 행에서 복지몰을 welfare_point 로 분리 · 하기 휴가 및 휴가비를 summer_leave · summer_vacation_subsidy 두 행으로 분리 · 45쪽 유급 출산 휴가 최대 6개월 parenting 추가(참고 블록 제외 줄의 출산은 이 판정으로 상회분만 뒤집힘) — 최종 36행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hs_hyosung_advanced', 'HS효성첨단소재',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '화학', 'H', 'https://www.hshyosungadvancedmaterials.com/kr/recruitment/personnel-system');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hs_hyosung_advanced');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.hshyosungadvancedmaterials.com/kr/recruitment/personnel-system'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) — 2025 보고서 44쪽 · 인사제도 기념일 선물 ──
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '성과급은 경영 실적과 조직 및 개인의 성과를 종합적으로 반영하여 차등 지급 (2025 지속가능경영보고서 44쪽 합리적인 보상제도 항목) — 지급 기준·지급률 미기재', 10),
  (@comp_id, 'excellence_award', 'HS효성첨단소재인상 · PU 우수사원상', NULL, 'compensation',
   'est', NULL, TRUE, '반기별 성과에 따라 HS효성첨단소재인상과 PU 우수사원상을 팀과 개인에게 수여 (2025 지속가능경영보고서 44쪽 동기 부여를 위한 포상 항목), 각 사업장에서 회사 성과에 기여한 직원들에게 공장장 명의의 상 수여 (공식 지속가능경영 사이트 인재경영 성과 평가 및 보상 항목) — 포상 내용 미기재', 11),
  (@comp_id, 'holiday_gift', '창립기념품', NULL, 'compensation',
   'est', NULL, TRUE, '창립기념일에 모든 임직원에게 창립기념품 지급 (공식 홈페이지 인재채용 인사제도 기념일 선물 항목, HS효성그룹 공통 문구) — 기념품 종류·가액 미기재', 12),
  -- ── 근무유연성 (flexibility) — 2026 반기보고서 ──
  (@comp_id, 'flex_work', '유연근무제 (시차출퇴근제)', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 활용 시행중, 시차출퇴근제 운영 (2026 반기보고서 유연근무제도 사용 현황 항목) — 출퇴근 시간 범위·적용 대상 미기재', 20),
  -- ── 가족·돌봄 (family) — 인사제도 · 2025 보고서 45쪽 ──
  (@comp_id, 'event', '경조사 지원 (경조금·경조휴가)', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원, 결혼축하금, 재해위로금 지원 (2025 지속가능경영보고서 45쪽 HS효성첨단소재 복리후생 · 생애주기 맞춤형 지원 항목), 임직원의 경조 및 재해에 관한 경조금 및 휴가 부여 (공식 홈페이지 인재채용 인사제도 경조금 및 경조휴가 항목, HS효성그룹 공통 문구) — 경조 유형별 금액·휴가 일수 미기재', 30),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원, 대학등록금 지원 (2025 지속가능경영보고서 45쪽 HS효성첨단소재 복리후생 · 생애주기 맞춤형 지원 항목), 국내 정규 고등학교 및 4년제 정규대학/전문대학에 진학하거나 재학 중인 자녀의 입학금 및 등록금 전액 지원, 외국 고등학교 및 대학교 재학 시에도 지원금 제공 (공식 홈페이지 인재채용 인사제도 자녀학자금 지원 항목, HS효성그룹 공통 문구) — 자녀 수 제한·해외 지원금 액수 미기재', 31),
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '임직원이 자녀를 믿고 맡길 수 있는 사내 어린이집 운영 (2025 지속가능경영보고서 45쪽 가족친화적 조직문화 항목), 마포 사업장에 어린이집 운영, 전문 위탁업체 교사를 통한 보육 서비스와 정기적인 환경 유해 요소 검출 검사 (공식 홈페이지 인재채용 인사제도 사내어린이집 운영 항목, HS효성그룹 공통 문구) — 정원·입소 조건 미기재', 32),
  (@comp_id, 'parenting', '유급 출산 휴가 최대 6개월', NULL, 'family',
   'est', NULL, TRUE, '유급 출산 휴가 최소 3개월~최대 6개월 (2025 지속가능경영보고서 45쪽 생애주기 맞춤형 지원 출산 항목) — 최대 기간 적용 조건 미기재', 33),
  -- ── 경제적 부가혜택 (perks) — 인사제도 · 2025 보고서 45쪽 ──
  (@comp_id, 'discount', '임직원 제휴 할인', NULL, 'perks',
   'est', NULL, TRUE, '세빛섬 임직원 할인가격 이용 (공식 홈페이지 인재채용 인사제도 임직원 제휴 할인 항목, HS효성그룹 공통 문구) — 할인율 미기재', 40),
  (@comp_id, 'birthday_gift', '생일 선물 (본인·지정 1인)', NULL, 'perks',
   'est', NULL, TRUE, '임직원 본인 및 임직원이 지정하는 1인의 생일 시 선물 지급 (공식 홈페이지 인재채용 인사제도 기념일 선물 항목, HS효성그룹 공통 문구) — 선물 가액 미기재', 41),
  (@comp_id, 'housing_loan', '주택 융자금 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택 융자금 지원 (2025 지속가능경영보고서 45쪽 HS효성첨단소재 복리후생 주거 및 생활 항목) — 융자 한도·이율·대상 미기재', 42),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '통근버스 지원 (2025 지속가능경영보고서 45쪽 HS효성첨단소재 복리후생 근무 항목) — 운행 사업장·노선 미기재', 43),
  (@comp_id, 'welfare_point', '제휴 복지몰', NULL, 'perks',
   'est', NULL, TRUE, '제휴 복지몰 이용 가능 (공식 홈페이지 인재채용 인사제도 임직원 제휴 할인 항목, HS효성그룹 공통 문구) — 포인트 지급 여부·지급액 미기재', 44),
  -- ── 여가·라이프 (leisure) — 인사제도 · 2025 보고서 45~46쪽 ──
  (@comp_id, 'summer_vacation_subsidy', '하기 휴가비', NULL, 'leisure',
   'est', NULL, TRUE, '모든 임직원에게 하기 휴가비 지급 (공식 홈페이지 인재채용 인사제도 하기 휴가 및 휴가비 항목, HS효성그룹 공통 문구) — 휴가비 액수 미기재', 50),
  (@comp_id, 'club', '사내 동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내동아리 운영 (2025 지속가능경영보고서 45쪽 HS효성첨단소재 복리후생 근무 항목), 임직원 동호회 활동 비용 지급 (공식 홈페이지 인재채용 인사제도 동호회 활동 지원 항목, HS효성그룹 공통 문구) — 지원 금액 미기재', 51),
  (@comp_id, 'resort', '휴양시설 · 콘도 회원권 이용', NULL, 'leisure',
   'est', NULL, TRUE, '휴양시설 지원 (2025 지속가능경영보고서 45쪽 HS효성첨단소재 복리후생 근무 항목), 임직원 및 직계가족의 콘도 회원권 이용 지원 (공식 홈페이지 인재채용 인사제도 콘도 회원권 이용 항목, HS효성그룹 공통 문구) — 이용 횟수·본인 부담 미기재', 52),
  (@comp_id, 'company_event', 'Family Day 가족 초청 프로그램', NULL, 'leisure',
   'est', NULL, TRUE, '가족 친화적 기업 문화 조성을 위해 가족 초청 프로그램인 Family Day 운영, 임직원 가족을 사옥으로 초청해 사무공간 등 업무환경 소개, 자녀 대상 체험 프로그램과 오찬 (2025 지속가능경영보고서 45쪽 Family Day 실시 항목) — 운영 주기·참여 대상 미기재', 53),
  (@comp_id, 'culture_day', 'Culture Together 문화 체험 프로그램', NULL, 'leisure',
   'est', NULL, TRUE, '임직원의 일과 삶의 균형을 지원하고 창의적인 조직문화를 확산하기 위한 문화 체험 프로그램 Culture Together 운영, 2025년 클래식, 발레, 대중음악 콘서트 등 장르를 다변화하고 전용 상영관 대관을 통한 영화 관람 행사 병행 (2025 지속가능경영보고서 46쪽 Culture Together 항목) — 운영 주기·비용 지원 범위 미기재', 54),
  -- ── 근무환경 (work_env) — 인사제도 모성보호제도 · 2025 보고서 45쪽 ──
  (@comp_id, 'nap_room', '수유실', NULL, 'work_env',
   'est', NULL, TRUE, '수유 공간 설치 (2025 지속가능경영보고서 45쪽 생애주기 맞춤형 지원 출산 항목), 수유실 운영 (공식 홈페이지 인재채용 인사제도 모성보호제도 항목, HS효성그룹 공통 문구) — 설치 사업장·규모 미기재', 60),
  (@comp_id, 'lounge', '여성 휴게시설', NULL, 'work_env',
   'est', NULL, TRUE, '여성 휴게시설 설치 (2025 지속가능경영보고서 45쪽 생애주기 맞춤형 지원 출산 항목) — 설치 사업장·규모 미기재', 61),
  (@comp_id, 'dormitory', '기숙사 · 사택', NULL, 'work_env',
   'est', NULL, TRUE, '기숙사 및 사택지원 (2025 지속가능경영보고서 45쪽 HS효성첨단소재 복리후생 주거 및 생활 항목) — 입주 자격·운영 사업장 미기재', 62),
  -- ── 성장·커리어 (growth) — 인사제도 · 2025 보고서 42~45쪽 · 지속가능경영 사이트 인재경영 ──
  (@comp_id, 'retirement_support', '퇴직자 지원 제도 (진로 설계교육·재취업 컨설팅)', NULL, 'growth',
   'est', NULL, TRUE, '정년퇴직 예정자에게 재취업지원 제도를 제공하고 만 50세 이상 임직원에게 제 2의 삶을 사전에 준비할 수 있도록 지원하는 진로 설계교육 실시, 만 50세 이상 임직원에게 진단을 통해 관계, 네트워크, 건강, 재무, 주거, 여가 영역 중 필요한 영역을 개별 신청하여 퇴직 후 제 2의 삶을 사전에 준비할 수 있도록 지원 (공식 홈페이지 인재채용 인사제도 퇴직자 지원 제도 항목, HS효성그룹 공통 문구), 퇴직 후 제2의 삶 준비 지원 교육 및 역량 개발 프로그램(재취업서비스 컨설팅, 온·오프 직무 교육) (2025 지속가능경영보고서 45쪽 생애주기 맞춤형 지원 은퇴 항목) — 지원 기간·비용 부담 미기재', 70),
  (@comp_id, 'mba', '학위과정 지원 (학술연수)', NULL, 'growth',
   'est', NULL, TRUE, '국내외 학술연수자 학위과정 지원 (공식 홈페이지 인재채용 인사제도 학위과정 지원 항목, HS효성그룹 공통 문구), 학술지원제도를 통한 핵심 인재의 성장 지원 (2025 지속가능경영보고서 43쪽 우수인재 육성 항목) — 선발 기준·지원 범위 미기재', 71),
  (@comp_id, 'lang', '어학 교육 프로그램', NULL, 'growth',
   'est', NULL, TRUE, '영어, 일본어, 중국어, 베트남어 등 주요 해외 거점 언어를 포함한 교육 프로그램 운영 (2025 지속가능경영보고서 43쪽 글로벌역량 강화 항목), 교육 플랫폼 HOLiC을 통한 글로벌 역량 강화 어학 프로그램 제공 (공식 지속가능경영 사이트 인재경영 자기주도적 역량 강화 교육 지원 항목) — 비용 부담·수강 조건 미기재', 72),
  (@comp_id, 'edu_support', '사내 교육 플랫폼 HOLiC', NULL, 'growth',
   'est', NULL, TRUE, '교육 플랫폼 HOLiC을 통해 업무에 필요한 직무 역량 강의 제공, 구성원 스스로 학습 경력을 설계하는 자기 역량 개발 프로그램(IDP) 운영 (공식 지속가능경영 사이트 인재경영 자기주도적 역량 강화 교육 지원 항목) — 수강 비용·이용 조건 미기재', 73),
  (@comp_id, 'conference', '사외 교육 지원 (컨퍼런스·세미나)', NULL, 'growth',
   'est', NULL, TRUE, '사외 컨퍼런스와 세미나 참석을 지원하여 최신 산업 동향을 학습할 수 있는 기회 제공 (2025 지속가능경영보고서 42쪽 임직원 육성 및 역량 강화 항목), 사외 컨퍼런스, 세미나 등 사외 교육에 참여할 수 있는 사외 교육 신청 프로세스 운영 (공식 지속가능경영 사이트 인재경영 자기주도적 역량 강화 교육 지원 항목) — 비용 지원 범위·신청 조건 미기재', 74),
  (@comp_id, 'self_development', '자격증 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '어학, 위험물 산업기사 등 직무수행에 필요한 자격증 취득에 필요한 교육 지원 및 응시비 지원 (공식 지속가능경영 사이트 인재경영 직무 전문성 강화 항목) — 지원 한도·대상 자격증 범위 미기재', 75),
  (@comp_id, 'career', '경력 개발 프로그램 (CDP)', NULL, 'growth',
   'est', NULL, TRUE, '임직원은 본인의 역량과 경력 목표에 따라 직무 전환, 부서 이동 등 다양한 경력 경로를 모색, 인사평가 과정에서 희망 직무를 공유하면 회사가 필요한 보직 조정과 교육을 지원하는 경력 개발 프로그램 운영 (2025 지속가능경영보고서 43쪽 경력 개발 프로그램 항목) — 이동 주기·선발 기준 미기재', 76),
  -- ── 건강·의료 (health) — 인사제도 건강 관리 · 2025 보고서 45 · 46 · 51쪽 ──
  (@comp_id, 'health_check', '종합 건강검진 (본인·배우자)', NULL, 'health',
   'est', NULL, TRUE, '배우자 종합검진 (2025 지속가능경영보고서 45쪽 HS효성첨단소재 복리후생 가족 항목), 매년 전 임직원을 대상으로 건강검진 실시 (2025 지속가능경영보고서 51쪽 임직원 건강 관리 항목), 모든 임직원 대상 종합 검진 제공, 만 40세 이상 임직원의 배우자 대상 종합 검진 제공 (공식 홈페이지 인재채용 인사제도 건강 관리 항목, HS효성그룹 공통 문구) — 검진 항목·비용 지원 범위 미기재', 80),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '의료비 지원 (2025 지속가능경영보고서 45쪽 HS효성첨단소재 복리후생 건강 항목), 유산이나 사산 시 의료비 지원 (공식 홈페이지 인재채용 인사제도 모성보호제도 항목, HS효성그룹 공통 문구) — 지원 대상·한도 미기재', 81),
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '단체상해보험 지원 (2025 지속가능경영보고서 45쪽 HS효성첨단소재 복리후생 건강 항목), 모든 임직원 단체상해보험(실비) 제공 (공식 홈페이지 인재채용 인사제도 건강 관리 항목, HS효성그룹 공통 문구) — 보장 한도 미기재', 82),
  (@comp_id, 'mental', '심리 케어 프로그램 첨단 HYU(休)', NULL, 'health',
   'est', NULL, TRUE, '스트레스와 심리적 어려움을 완화하고 정서적 안정을 도모하기 위한 심리 케어 프로그램 첨단 HYU(休) 운영, 지원 범위를 배우자까지 확대 (2025 지속가능경영보고서 46쪽 임직원 마음건강 관리 항목), 심리상담 서비스 지원 (2025 지속가능경영보고서 45쪽 HS효성첨단소재 복리후생 건강 항목) — 상담 횟수·운영 방식 미기재', 83),
  (@comp_id, 'clinic', '건강관리실', NULL, 'health',
   'est', NULL, TRUE, '건강관리실 운영 (2025 지속가능경영보고서 45쪽 HS효성첨단소재 복리후생 건강 항목) — 운영 사업장·상주 인력 미기재', 84),
  (@comp_id, 'smoking_cessation', '금연 펀드', NULL, 'health',
   'est', NULL, TRUE, '임직원의 생활습관 개선과 장기적인 건강 증진을 위한 참여 기반의 건강증진 프로그램으로 금연 펀드 운영 (2025 지속가능경영보고서 51쪽 임직원 참여 건강증진 프로그램 항목) — 펀드 운영 방식·지급 조건 미기재', 85),
  -- ── 시간·휴가 (time_off) — 인사제도 장기근속자 포상 · 2025 보고서 45쪽 ──
  (@comp_id, 'long_service_leave', '장기근속 포상 휴가·포상금', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 포상 (2025 지속가능경영보고서 45쪽 HS효성첨단소재 복리후생 근무 항목), 10년/20년/30년 근속자에게 포상금 및 포상 휴가 지급 (공식 홈페이지 인재채용 인사제도 장기근속자 포상 항목, HS효성그룹 공통 문구) — 포상금 액수·휴가 일수 미기재', 90),
  (@comp_id, 'summer_leave', '하기 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '모든 임직원에게 연중에 연속으로 사용할 수 있는 하기 휴가 지급 (공식 홈페이지 인재채용 인사제도 하기 휴가 및 휴가비 항목, HS효성그룹 공통 문구) — 휴가 일수·유급 여부 미기재', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
