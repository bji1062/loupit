-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LG헬로비전 복리후생 데이터 (신규 회사 — 웨이브 15)
-- 출처: AI 파싱 (2026-10-23)
-- URL: https://corp.lghellovision.net/csv/esgReport.do
-- badge: est
--
-- 참고:
--   정본은 상장 법인 ㈜엘지헬로비전의 기업 사이트 corp.lghellovision.net 지속가능경영 > 지속가능경영보고서 목록(SSR).
--   본문 출처는 그 목록이 거는 법인 단독 발행 LG헬로비전 2025-2026 지속가능경영보고서
--   (/brand/images/sub/welfare/2025_2026_LGHelloVision_SR_KR.pdf · 107쪽 · PDF 생성 2026-07 · 보고 기간 2025-01-01~2025-12-31
--   일부 정성 활동 2026-06 까지 · 보고 범위 LG헬로비전 국내 사업장 전체).
--   48쪽 인재관리 > 일과 삶의 균형을 위한 활동(가족친화기업 · 복리후생 제도 문단 + 임직원 및 협력사를 위한 복리후생 제도 표 4열
--   회사생활 지원 · 가족친화 제도 · 구성원 Care 프로그램 · 리프레시 제도) · 49쪽 기업문화 활동 · 임직원 평가 및 보상 ·
--   50쪽 인재육성 프로그램 · 임직원 교육 플랫폼 · 51쪽 생애 단계 맞춤형 케어 프로그램 · 55쪽 임직원 건강관리 ·
--   14쪽 이해관계자 소통 표(구성원 대응현황 · 소통채널).
--   공시 보조: OpenDART 2026 반기보고서(접수 20260814002200) · 2025 사업보고서(접수 20260316000756)
--   직원 등 현황 유연근무제도 사용 현황 표(시차출퇴근제 사용자 수). 직원 933명(2025-12-31 · 1,000명 미만).
--   렌더: 없음 — 보고서 PDF 텍스트 추출, 48쪽 표는 쪽 그림으로 열 귀속을 대조했다.
--   귀속: 법인 단독 발행 보고서이고 주어가 LG헬로비전 — 각주 없음. LG Careers 그룹 통합 채용(careers.lg.com)은
--     회사 정보가 POST 응답에만 있어 받지 않았고 근거로 쓰지 않았다.
--   금액: 원문에 원 단위 숫자 0건 — 전 행 BENEFIT_AMT NULL. 숫자는 리프레시 휴가 5일 · 장기 근속 10/20/30년뿐.
--   제외: 법정(출산 전후 휴가 등 모성 보호 · 출산 및 육아휴직 제도 · 난임 휴가 일수 미기재 · 배우자 출산 휴가 ·
--     육아기 단축근로 · 특수 건강검진 · 유소견자 사후 관리 · 법정의무 교육 · 퇴직연금 DB/DC · 사회 보험) ·
--     업무 교육(LG Way · 정도경영 · 온보딩 · 멘토링 · 버디 · 직무전문 · 기술교육 · AX · DX · 리더십 · 재난방송 교육 · AI 해커톤) ·
--     사내포털 · 노경협의회 · 고충처리 채널(혜택 아님) · 연봉 인상(급여 조정) · 경력개발 지원제도 · 직무순환(자기 지원 이동 미기재) ·
--     사외이사 · 이사회 경영성과급(임원 보수).
--   공고 근거 0행 / 전체 28행.
--   SORT 섹션 순서 = 48쪽 복리후생 제도 표 등장 순(perks 10 · leisure 20 · flexibility 30 · family 40 · health 50 ·
--     time_off 60 · compensation 70), 표 밖 쪽에만 있는 growth 80 · work_env 90.
-- 검증 · 감사 판정 반영(2026-10-23): 49쪽 관리활동 목록의 스마트 오피스 활성화 smart_office 행과 근무 환경 섹션 삭제(복지 목록 밖 업무 공간 · 판정 154 · 166) · 재택근무 서술에서 유연근무 몫 걷음 · 점검기 keyword 는 PDF 링크 경로 낱말 · 항목 페이지 예외 1(통합 밖 리드 집행) · 참고 블록의 SORT 섹션 줄 work_env 90 과 행 수 28행은 이 판정으로 뒤집힘 — 최종 27행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('lg_hellovision', 'LG헬로비전',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '통신', 'L', 'https://corp.lghellovision.net/csv/esgReport.do');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lg_hellovision');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://corp.lghellovision.net/csv/esgReport.do'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 생활 지원 (perks) — 2025-2026 지속가능경영보고서 48쪽 복리후생 제도 표 ──
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '복지포인트 (2025-2026 지속가능경영보고서 48쪽 복리후생 제도 표 회사생활 지원 항목) — 배정 금액·사용처 미기재', 10),
  (@comp_id, 'telecom', '통신비 지원', NULL, 'perks',
   'est', NULL, TRUE, '통신비 (2025-2026 지속가능경영보고서 48쪽 복리후생 제도 표 회사생활 지원 항목) — 지원 금액·지원 대상 미기재', 11),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '통근버스 (2025-2026 지속가능경영보고서 48쪽 복리후생 제도 표 회사생활 지원 항목) — 운행 노선·운행 사업장 미기재', 12),
  (@comp_id, 'housing_loan', '주택자금 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택자금 지원 (2025-2026 지속가능경영보고서 48쪽 복리후생 제도 표 가족친화 제도 항목) — 지원 방식·한도·대상 미기재', 13),

  -- ── 여가 (leisure) — 보고서 48쪽 표 · 14쪽 · 49쪽 ──
  (@comp_id, 'club', '사내 동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 활동 지원 (2025-2026 지속가능경영보고서 48쪽 복리후생 제도 표 회사생활 지원 항목), 사내동호회 (14쪽 이해관계자 소통 표 구성원 소통채널 항목) — 지원 금액·동호회 종류 미기재', 20),
  (@comp_id, 'resort', '국내외 호텔·콘도 지원', NULL, 'leisure',
   'est', NULL, TRUE, '국내외 호텔/콘도 지원 (2025-2026 지속가능경영보고서 48쪽 복리후생 제도 표 리프레시 제도 항목) — 지원 방식·이용 횟수 미기재', 21),
  (@comp_id, 'company_event', '즐거운직장 이벤트·프로그램', NULL, 'leisure',
   'est', NULL, TRUE, '즐거운직장 이벤트/프로그램 운영 (2025-2026 지속가능경영보고서 49쪽 기업문화 활동 환경경험 관리활동 항목) — 행사 내용·주기 미기재', 22),

  -- ── 근무 유연성 (flexibility) — 보고서 48쪽 표 · 49쪽 · 14쪽 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '출퇴근 유연 제도', NULL, 'flexibility',
   'est', NULL, TRUE, '출퇴근 유연 제도로 근무 시간의 자율성 제고 (2025-2026 지속가능경영보고서 48쪽 복리후생 제도 문단·표 가족친화 제도 항목), 유연근무 활성화 (49쪽 기업문화 활동 환경경험 항목), 시차출퇴근제 사용자 수 2026년 반기 928명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 출퇴근 시간 범위·적용 대상 미기재', 30),
  (@comp_id, 'pc_off', 'PC-OFF 제도', NULL, 'flexibility',
   'est', NULL, TRUE, 'PC-OFF제도 (2025-2026 지속가능경영보고서 48쪽 복리후생 제도 표 가족친화 제도 항목) — 적용 시각·대상 미기재', 31),
  (@comp_id, 'remote_work', '재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '재택근무 운영 (2025-2026 지속가능경영보고서 14쪽 이해관계자 소통 표 구성원 대응현황 항목) — 대상 직무·사용 조건 미기재', 32),

  -- ── 가족 (family) — 보고서 48쪽 표 · 48쪽 가족친화기업 문단 ──
  (@comp_id, 'child_edu', '학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '학자금 지원 (2025-2026 지속가능경영보고서 48쪽 복리후생 제도 표 가족친화 제도 항목) — 지원 대상·학교 과정·한도 미기재', 40),
  (@comp_id, 'disability_family_support', '장애인 자녀 양육비 지원', NULL, 'family',
   'est', NULL, TRUE, '장애인 자녀 양육비 지원 (2025-2026 지속가능경영보고서 48쪽 복리후생 제도 표 가족친화 제도 항목) — 지원 금액·대상 연령 미기재', 41),
  (@comp_id, 'fertility_support', '난임 의료비 지원', NULL, 'family',
   'est', NULL, TRUE, '난임 의료비 지원 (2025-2026 지속가능경영보고서 48쪽 복리후생 제도 표 구성원 Care 프로그램 항목) — 지원 한도·횟수 미기재', 42),
  (@comp_id, 'parenting', '자녀 입학 휴가', NULL, 'family',
   'est', NULL, TRUE, '자녀 입학 휴가 등 가족친화적 제도 운영 (2025-2026 지속가능경영보고서 48쪽 가족친화기업 항목) — 휴가 일수·대상 학년 미기재', 43),

  -- ── 건강 (health) — 보고서 48쪽 표 · 55쪽 임직원 건강관리 ──
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '의료비 지원 (2025-2026 지속가능경영보고서 48쪽 복리후생 제도 표 구성원 Care 프로그램 항목) — 지원 대상·한도 미기재', 50),
  (@comp_id, 'health_check', '종합 건강검진·건강검진 휴가', NULL, 'health',
   'est', NULL, TRUE, '건강검진 제공 (2025-2026 지속가능경영보고서 48쪽 복리후생 제도 표 구성원 Care 프로그램 항목), 건강검진 휴가를 확대해 직원의 건강관리 지원 (48쪽 복리후생 제도 문단 항목), 종합 건강검진 실시 (55쪽 임직원 건강관리 건강증진실 운영 항목) — 검진 항목·비용 지원 범위·휴가 일수 미기재', 51),
  (@comp_id, 'fitness', '사내 피트니스', NULL, 'health',
   'est', NULL, TRUE, '사내 피트니스 운영 (2025-2026 지속가능경영보고서 48쪽 복리후생 제도 표 구성원 Care 프로그램 항목) — 운영 사업장·이용 시간 미기재', 52),
  (@comp_id, 'clinic', '건강증진실', NULL, 'health',
   'est', NULL, TRUE, '건강증진실을 중심으로 체계적인 건강지원 프로그램 운영 (2025-2026 지속가능경영보고서 55쪽 임직원 건강관리 건강증진실 운영 항목) — 운영 사업장·상주 인력 미기재', 53),
  (@comp_id, 'mental', '심리상담 프로그램 마음토닥', NULL, 'health',
   'est', NULL, TRUE, '전문 심리상담 프로그램 「마음토닥」으로 직무 스트레스, 대인관계, 정서 지원 등 폭넓은 상담 서비스 상시 제공 (2025-2026 지속가능경영보고서 55쪽 임직원 건강관리 항목) — 상담 횟수·비용 지원 범위 미기재', 54),
  (@comp_id, 'massage', '안마 서비스 케렌시아', NULL, 'health',
   'est', NULL, TRUE, '국가공인 안마사 자격증을 보유한 시각장애인 헬스키퍼의 안마 서비스 「케렌시아」 운영 (2025-2026 지속가능경영보고서 55쪽 임직원 건강관리 항목) — 이용 횟수·운영 사업장 미기재', 55),

  -- ── 휴가 (time_off) — 보고서 48쪽 표 ──
  (@comp_id, 'refresh_leave', '리프레시 휴가 (5일)', NULL, 'time_off',
   'est', NULL, TRUE, '리프레시 휴가 5일 (2025-2026 지속가능경영보고서 48쪽 복리후생 제도 표 리프레시 제도 항목) — 부여 조건·주기·유급 여부 미기재', 60),

  -- ── 보상 (compensation) — 보고서 48쪽 표 · 49쪽 임직원 평가 및 보상 · 기업문화 활동 ──
  (@comp_id, 'long_service_bonus', '장기 근속 포상 (10·20·30년)', NULL, 'compensation',
   'est', NULL, TRUE, '장기 근속 포상 10/20/30년 (2025-2026 지속가능경영보고서 48쪽 복리후생 제도 표 리프레시 제도 항목), 장기 근속 직원에게 포상금, 선물, 근속 기념패 등 다양한 보상 제공 (49쪽 임직원 평가 및 보상 항목) — 포상 금액·선물 품목 미기재', 70),
  (@comp_id, 'incentive', '경영 성과급', NULL, 'compensation',
   'est', NULL, TRUE, '조직과 개인의 성과 평가 결과에 따른 경영 성과급 지급 (2025-2026 지속가능경영보고서 49쪽 임직원 평가 및 보상 항목) — 지급 기준·지급률 미기재', 71),
  (@comp_id, 'excellence_award', '정기·수시 포상제도', NULL, 'compensation',
   'est', NULL, TRUE, '정기 및 수시 포상제도 운영을 통한 동기부여 활성화 (2025-2026 지속가능경영보고서 49쪽 기업문화 활동 업무경험 항목), 평가 결과에 따른 우수 직원 포상 (49쪽 임직원 평가 및 보상 항목) — 포상 금액·포상 내용 미기재', 72),

  -- ── 성장 (growth) — 보고서 50쪽 인재육성 · 교육 플랫폼 · 51쪽 생애 단계 케어 ──
  (@comp_id, 'self_development', '자격증 지원', NULL, 'growth',
   'est', NULL, TRUE, '자격증 지원 (2025-2026 지속가능경영보고서 50쪽 인재육성 프로그램 직무전문 교육 항목) — 지원 대상 자격·지원 금액 미기재', 80),
  (@comp_id, 'edu_support', 'E-Learning 플랫폼 HelloVision Campus', NULL, 'growth',
   'est', NULL, TRUE, '시간과 공간에 구애 받지 않는 E-Learning 플랫폼 HelloVision Campus 운영, 인문학 등 다양한 콘텐츠로 자기주도적 학습문화 조성 (2025-2026 지속가능경영보고서 50쪽 임직원 교육 플랫폼 운영 항목), 공통역량 교육 OA 과정 (50쪽 인재육성 프로그램 공통기본 교육 항목) — 수강 조건·과정 목록 미기재', 81),
  (@comp_id, 'retirement_support', '미래 설계 교육 프로그램 (임금피크제 대상자)', NULL, 'growth',
   'est', NULL, TRUE, '임금피크제 대상자에게 정년퇴임 전 안정적인 경력전환의 기틀 마련과 평생직업 관점의 경력개발 계획 수립을 지원하는 미래 설계 교육 프로그램 (2025-2026 지속가능경영보고서 51쪽 생애 단계 맞춤형 케어 프로그램 항목) — 교육 기간·교육 내용 미기재', 82)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
