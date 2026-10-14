-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 이노션 복리후생 데이터 (신규 회사 — 웨이브 7)
-- 출처: AI 파싱 (2026-10-14)
-- URL: https://www.innocean.com/ww-ko/values/esg
-- badge: est
--
-- 참고:
--   정본은 상장 법인 ㈜이노션 자기 도메인 www.innocean.com 의 ESG 페이지(지속가능경영보고서 목록)다.
--   행 근거는 그 목록에 올라 있는 법인 단독 발행 이노션 지속가능경영보고서 Sustainability Report 2025
--   (PDF 150쪽 · 생성 2026-07 · 보고 기간 2025-01-01~2025-12-31 · 비재무 성과는 이노션 본사 기준)
--   50쪽 모성보호 제도 표 · 가족친화 프로그램, 52쪽 사내공모, 53쪽 보상 · 포상, 54~56쪽 교육,
--   57쪽 임직원 복지제도(근무 제도 · 휴식이 있는 이노션 · 임직원 웰니스), 58쪽 소통 프로그램, 65쪽 건강관리.
--   공시 보조: OpenDART 2026 반기보고서(접수 20260814004031) 유연근무제도 사용 현황 표와 주석
--   (선택근무제 · 원격근무제 전 직원 대상). 2024 보고서는 이름의 뜻을 확인하는 데만 썼다.
--   채용 사이트 innocean.recruiter.co.kr 는 경로는 허용이나 본문이 api-recruiter 호스트(robots 전면 금지)에만 있어 읽지 않았다.
--   렌더: PDF 텍스트 추출(PyMuPDF) · 표 3쪽은 화면 이미지로 짝 확인. 헤드리스 렌더 없음.
--   귀속: 자기 발행 단독 보고서 · 이노션이 주어 — 각주 없음. 현대차그룹 형제와 문장 겹침 없음.
--   금액: 금액 행 0. 유아 교육비 100만원은 1회 한정 · 대상 조건이라 NULL.
--   제외: 법정(야간 휴일 근무 제한 · 시간 외 근무 제한 · 임신기간 근로시간 단축 · 태아검진 시간 ·
--     출산 전후 휴가 · 유산사산 휴가 · 육아 휴직 · 수유시간 · 퇴직연금) · 본인 휴가 사용(Happy INNO Day · Week ·
--     Culture Experience) · 장려 휴가(Leader’s Holiday) · 업무 교육(4-Track 직무 · 리더십 · 입문 · 멘토링 ·
--     주재원 교육 · 직무 특강) · 파트너사 대상 프로그램(79쪽) · 임원 보수 칸 · 판단 요청(임신 안정화 휴직 · 평가 대상 제외 · 힐링캠프).
--   공고 근거 0행 / 전체 23행.
--   SORT 섹션 순서 = 보고서 등장 순(family 10 · leisure 20 · growth 30 · compensation 40 ·
--     flexibility 50 · perks 60 · health 70).
-- 검증 · 감사 판정 반영(2026-10-14): 광고제 참관 conference 삭제(업무 교육 Skill Track) · Culture Experience 해외 출장 연계 휴가 leave_general 추가(time_off SORT 80) · 힐링캠프를 company_event 행에 병합(참고 블록 제외 줄의 Culture Experience · 힐링캠프는 이 판정으로 뒤집힘) — 최종 23행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('innocean', '이노션',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '광고', 'I', 'https://www.innocean.com/ww-ko/values/esg');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'innocean');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.innocean.com/ww-ko/values/esg'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 가족 (family) — 2025 지속가능경영보고서 50쪽 ──
  (@comp_id, 'fertility_support', '아기 맞이 휴직', NULL, 'family',
   'est', NULL, TRUE, '난임치료를 필요로 하는 모든 근로자가 사용 가능한 아기 맞이 휴직 (2025 지속가능경영보고서 50쪽 모성보호 제도 항목) — 휴직 기간·급여 여부 미기재', 10),
  (@comp_id, 'parenting', '순산기원 선물·출산 축하 선물', NULL, 'family',
   'est', NULL, TRUE, '임신한 여직원 및 임신한 배우자가 있는 남직원 전원에게 전자파 차단 Blanket 지급(순산기원 선물), 출산한 여직원 및 임신한 배우자가 있는 남직원 전원에게 아기용품 지급(출산 축하 선물) (2025 지속가능경영보고서 50쪽 모성보호 제도 항목) — 선물 금액 미기재', 11),
  (@comp_id, 'childcare', '푸르니 직영 어린이집', NULL, 'family',
   'est', NULL, TRUE, '임직원의 자녀 중 만 1세에서 취학 전 자녀 대상 푸르니 직영 어린이집 (2025 지속가능경영보고서 50쪽 모성보호 제도 항목), 직장 어린이집 운영 (2025 지속가능경영보고서 57쪽 임직원 웰니스 항목) — 정원·이용 비용 미기재', 12),
  (@comp_id, 'child_edu', '유아 교육비·학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀가 취학 전 만 5세 이상 8세 미만인 전 임직원(직장어린이집 1년 이상 이용 시 제외) 대상 1회 한하여 1년간 1,000,000원 지원(유아 교육비 지원), 고등학교 및 대학교 재학 중 자녀를 둔 임직원 대상 국내학교·특수목적학교·해외유학 기준 다양한 학자금 지원(학자금 지원 제도) (2025 지속가능경영보고서 50쪽 가족친화 프로그램 항목) — 학자금 지원 한도·자녀 수 미기재', 13),
  (@comp_id, 'event', '경조사 및 상조 서비스 지원', NULL, 'family',
   'est', NULL, TRUE, '본인 및 배우자의 형제자매, 부모 등 직계가족을 위한 경조사 및 상조 서비스 지원 (2025 지속가능경영보고서 50쪽 가족친화 프로그램 항목) — 경조금 금액·경조휴가 일수 미기재', 14),
  -- ── 여가 · 행사 (leisure) — 2025 지속가능경영보고서 50 · 57 · 58쪽 ──
  (@comp_id, 'resort', '임직원 휴양소', NULL, 'leisure',
   'est', NULL, TRUE, '임직원 전원 대상 휴양소 제공으로 개인의 건강한 휴식 및 가족 간 유대감 증진 (2025 지속가능경영보고서 50쪽 가족친화 프로그램 항목) — 휴양소 위치·이용 횟수·비용 지원 범위 미기재', 20),
  (@comp_id, 'culture_day', 'Cultural Afternoon', NULL, 'leisure',
   'est', NULL, TRUE, '부서원들과 문화 관람이나 야외 활동을 함께하는 Cultural Afternoon (2025 지속가능경영보고서 57쪽 휴식이 있는 이노션 항목), 상·하반기 1회 오후 시간을 활용한 문화활동 참여와 원데이클래스, 체육대회 등의 활동 (2025 지속가능경영보고서 58쪽 임직원 소통 프로그램 항목) — 비용 지원 범위 미기재', 21),
  (@comp_id, 'library', '사내 도서관', NULL, 'leisure',
   'est', NULL, TRUE, '사옥 내 도서관을 바이오필릭(Biophilic) 콘셉트로 리뉴얼해 정서적 안정감과 창의적 리프레시 환경 제공 (2025 지속가능경영보고서 57쪽 임직원 웰니스 항목) — 장서 규모·운영 시간 미기재', 22),
  (@comp_id, 'club', '동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '구성원의 마음 건강 관리와 조직 내 유대감 강화를 위한 동호회 지원 (2025 지속가능경영보고서 57쪽 임직원 웰니스 항목) — 지원 금액·동호회 수 미기재', 23),
  (@comp_id, 'company_event', '송년행사·창립기념행사·힐링캠프', NULL, 'leisure',
   'est', NULL, TRUE, '연말 송년행사와 창립기념행사 정기 개최, 2025년 송년행사의 위시트리 꾸미기 이벤트와 Christmas Special Meal 특식 제공 (2025 지속가능경영보고서 58쪽 임직원 소통 프로그램 항목), 구성원의 마음 건강 관리와 조직 내 유대감 강화를 위한 힐링캠프 (2025 지속가능경영보고서 57쪽 임직원 웰니스 항목) — 참여 대상·힐링캠프 프로그램 내용 미기재', 24),
  -- ── 성장 · 교육 (growth) — 2025 지속가능경영보고서 52 · 54 · 55 · 56쪽 ──
  (@comp_id, 'career', '사내공모제도', NULL, 'growth',
   'est', NULL, TRUE, '임직원이 개인의 관심 분야와 전문성을 바탕으로 다양한 직무와 프로젝트에 자율적으로 지원할 수 있는 사내공모제도 (2025 지속가능경영보고서 52쪽 사내공모제도 항목) — 지원 자격·공모 주기 미기재', 30),
  (@comp_id, 'lang', '어학 교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '전화 외국어 교육 (2025 지속가능경영보고서 54쪽 근로자 교육 프로그램 항목), 다양한 외부 교육 플랫폼을 활용한 어학 교육 지원과 어학 프로그램 지원 (2025 지속가능경영보고서 55쪽 근로자 디지털 역량 강화 교육 항목) — 비용 지원 범위·대상 미기재', 31),
  (@comp_id, 'edu_support', '교육비 지원 제도', NULL, 'growth',
   'est', NULL, TRUE, '임직원이 개인의 성장 목표에 맞춰 자율적으로 학습할 수 있는 교육비 지원 제도 (2025 지속가능경영보고서 55쪽 근로자 디지털 역량 강화 교육 항목) — 지원 한도·대상 과정 미기재', 33),
  (@comp_id, 'mba', 'MBA 취득 지원 제도', NULL, 'growth',
   'est', NULL, TRUE, '사내 공개 모집을 통한 우수인재 선발, 국내 주요 대학 MBA 과정 학비 및 기타 비용 지원, 해외 연수 프로그램 포함 (2025 지속가능경영보고서 56쪽 학위 지원 프로그램 항목) — 선발 인원·지원 한도 미기재', 34),
  -- ── 보상 (compensation) — 2025 지속가능경영보고서 53쪽 ──
  (@comp_id, 'profit_sharing', '영업이익 공유 변동급', NULL, 'compensation',
   'est', NULL, TRUE, '변동급은 영업이익의 일정 비율을 구성원과 공유하는 방식으로 설계 (2025 지속가능경영보고서 53쪽 공정한 보상과 포상 제도 항목) — 공유 비율·지급 시기 미기재', 40),
  (@comp_id, 'excellence_award', '포상 제도', NULL, 'compensation',
   'est', NULL, TRUE, '연말 포상(베스트 이노시안 선정), 대외 수상 포상(개인별 포상금), 신규 개발 포상(개발 규모에 따른 포상) (2025 지속가능경영보고서 53쪽 포상 제도 항목) — 포상 금액·선정 인원 미기재', 41),
  -- ── 근무 유연성 (flexibility) — 2025 지속가능경영보고서 57쪽 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '유연근무제 (선택적 근로시간제)', NULL, 'flexibility',
   'est', NULL, TRUE, '선택적 근로시간제를 통해 출퇴근 시간 자율 조정 가능 (2025 지속가능경영보고서 57쪽 근무 제도 항목), 선택근무제 전 직원 대상 운영 (2026 반기보고서 유연근무제도 사용 현황 항목) — 의무 근로 시간대 미기재', 50),
  (@comp_id, 'remote_work', '하이브리드 근무제·원격근무제(재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '온·오프라인 근무 병행을 통한 유연한 업무환경 제공, 원격근무 운영으로 공간 제약 완화 및 업무 연속성 확보 (2025 지속가능경영보고서 57쪽 근무 제도 항목), 원격근무제(재택근무 포함) 전 직원 대상 운영 (2026 반기보고서 유연근무제도 사용 현황 항목) — 사용 횟수·사용 조건 미기재', 51),
  -- ── 생활 · 편의 (perks) — 2025 지속가능경영보고서 57쪽 ──
  (@comp_id, 'snack_bar', '사내 카페 (Inno Cafe)', NULL, 'perks',
   'est', NULL, TRUE, '사옥 내 카페를 바이오필릭(Biophilic) 콘셉트로 리뉴얼, 카페 수익금의 일부를 사회공헌 활동 기금으로 환원 (2025 지속가능경영보고서 57쪽 임직원 웰니스 항목) — 무료 여부·운영 시간 미기재', 60),
  -- ── 건강 (health) — 2025 지속가능경영보고서 57 · 65쪽 ──
  (@comp_id, 'mental', 'Happy Counseling 심리상담', NULL, 'health',
   'est', NULL, TRUE, '임직원 뿐 아니라 가족까지 이용할 수 있는 Happy Counseling 프로그램, 대인관계·업무 스트레스·조직 적응·가족 문제·법률 상담 등 연간 최대 8회의 전문 상담, 고위험군 분류 시 상담 횟수 추가 지원, 모든 상담은 철저한 비밀 보장 원칙 (2025 지속가능경영보고서 65쪽 임직원 건강관리 활동 항목) — 상담 방식 미기재', 70),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '임직원이 직무에 몰입할 수 있는 근무 환경을 위한 의료비 지원 (2025 지속가능경영보고서 57쪽 임직원 웰니스 항목) — 지원 대상·범위·한도 미기재', 71),
  (@comp_id, 'health_check', '종합건강검진', NULL, 'health',
   'est', NULL, TRUE, '정기적인 종합건강검진으로 임직원의 건강 상태 사전 점검과 질병의 조기 발견·예방 지원 (2025 지속가능경영보고서 65쪽 임직원 건강관리 활동 항목) — 검진 주기·가족 포함 여부·비용 지원 범위 미기재', 72),
  -- ── 휴가 (time_off) — 2025 지속가능경영보고서 57쪽 ──
  (@comp_id, 'leave_general', 'Culture Experience (해외 출장 연계 휴가)', NULL, 'time_off',
   'est', NULL, TRUE, '해외 출장과 개인 휴가를 연계하는 Culture Experience로 글로벌 현장 경험의 폭 확대, 해외 출장 시 개인 휴가 연계 지원으로 현지 문화 경험 확대 (2025 지속가능경영보고서 57쪽 휴식이 있는 이노션 항목) — 휴가 일수·대상·비용 지원 범위 미기재', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
