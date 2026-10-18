-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 신세계인터내셔날 복리후생 데이터 (신규 회사 — 웨이브 12)
-- 출처: AI 파싱 (2026-10-18)
-- URL: https://img.sikorea.co.kr/files/upload2/esgPdf/202606/%EC%82%AC%ED%9A%8C05_%ED%99%88%ED%8E%98%EC%9D%B4%EC%A7%80_1782569482776.pdf
-- badge: est
--
-- 참고:
--   정본 = 법인 자기 도메인 ESG 정보공시 사회05 가족친화적 근로환경 PDF(2026-06-27 게시, img.sikorea.co.kr).
--     www.sikorea.co.kr 는 쿠키 없이 https-http 리다이렉트가 돌아 점검기가 리다이렉트 5회 초과 error —
--     그래서 목록 페이지(ESG경영) 대신 목록이 가리키는 PDF 를 정본으로 둠(근거표 판단 요청).
--   같은 목록의 사회10 임직원 역량개발 · 사회23 인권경영 관리활동 PDF 도 근거.
--     PDF 는 텍스트 층이 없어 원본 이미지를 추출해 판독(사본 image_transcript.txt).
--   보조 = OpenDART 2026 반기보고서(20260814003714) · 2025 사업보고서(20260316001380) 유연근무제도 사용 현황 표 ·
--     2025 별도 감사보고서 주석(장기근속 종업원 급여채무),
--     신세계그룹 통합 채용 포털 job.shinsegae.com 홈 복리후생 4항목(법인 구분 없음 · 주어 신세계 그룹의 임직원 ·
--     계열사별 상이 단서 없음 · 자기 도메인 채용 페이지의 지원하기 버튼이 이 포털로 연결) —
--     자기 자료에 없는 항목만 각주 (그룹 통합 채용 기준) 를 달아 실음(10행 · 그중 1행은 자기 공시와 병합).
--   지속가능경영보고서(2024 SR 국문, 2026-02 게시)는 Microsoft AIP 보호 문서라 읽지 못함.
--   금액 행 0 — 외국어 지원 제도 월 15만원은 한도인지 정액인지 원문에 없어 NULL(근거표 판단 요청).
--   제외 = 법정(법정필수교육 · 성희롱 괴롭힘 예방 · 모성보호 상회 문구만 있고 내용 없음) · 업무 교육(온보딩 · 리더십 ·
--     직무 스쿨 · 직무특화 외부교육) · 임원 전용(AMP · SERI CEO · 1:1 외국어 수업 · 임원 명절 상여 · 성과급).
--   공고 근거 0행 / 전체 17행 · SORT 섹션 = flexibility 10 · family 20 · growth 30 · health 40 ·
--     compensation 50 · perks 60 · time_off 70 · leisure 80
-- 검증 · 감사 판정 반영(2026-10-18): Mini MBA·Junior MBA mba 서술에 교육체계도 BAND 직급 · 장기근속 long_service_bonus 각주를 (그룹 통합 채용 기준) 꼴로 · ESG 정보공시 사회13 감정노동자 멘탈관리 프로그램을 심리 상담 mental 에 병합 · 그룹 통합 채용 포털 근거 9행 각주 유지 — 최종 17행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('shinsegae_intl', '신세계인터내셔날',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '패션', 'S', 'https://img.sikorea.co.kr/files/upload2/esgPdf/202606/%EC%82%AC%ED%9A%8C05_%ED%99%88%ED%8E%98%EC%9D%B4%EC%A7%80_1782569482776.pdf');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'shinsegae_intl');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://img.sikorea.co.kr/files/upload2/esgPdf/202606/%EC%82%AC%ED%9A%8C05_%ED%99%88%ED%8E%98%EC%9D%B4%EC%A7%80_1782569482776.pdf'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — ESG 정보공시 사회05 · 반기보고서 ──
  (@comp_id, 'flex_work', '주 35시간 근무제·시차출퇴근·선택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '주 35시간 근무제(일 7시간) 전사 도입, 시차 출근제와 유연 근무 제도 제공 (2026 ESG 정보공시 가족친화적 근로환경 항목), 시차출퇴근제 사용자 2026년 상반기 68명 · 2025년 83명, 선택근무제 사용자 2026년 상반기 218명 · 2025년 325명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 코어타임·신청 절차·적용 직군 미기재', 10),
  (@comp_id, 'remote_work', '원격근무제(재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무포함) 사용자 2026년 상반기 6명 · 2025년 35명 · 2024년 37명 (2026 반기보고서 · 2025 사업보고서 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 11),

  -- ── 가족·돌봄 (family) — ESG 정보공시 사회05 · 그룹 채용 포털 ──
  (@comp_id, 'parenting', '임신 초기 마더박스', NULL, 'family',
   'est', NULL, TRUE, '임신 초기 임직원을 위한 마더박스 지급 정례화 (2026 ESG 정보공시 가족친화적 근로환경 항목) — 마더박스 구성·금액 미기재', 20),
  (@comp_id, 'child_edu', '교육비 지원 (유치원~대학)', NULL, 'family',
   'est', NULL, TRUE, '근속년수에 따라 유치원부터 대학까지 교육비를 회사에서 지원 (신세계그룹 공식 채용 포털 복리후생 교육 및 경조사 지원 항목) — 근속 기준·지원 한도·대상 범위 미기재 (그룹 통합 채용 기준)', 21),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원 (신세계그룹 공식 채용 포털 복리후생 교육 및 경조사 지원 항목) — 경조금 액수·경조휴가 일수 미기재 (그룹 통합 채용 기준)', 22),

  -- ── 성장·커리어 (growth) — ESG 정보공시 사회10 ──
  (@comp_id, 'lang', '외국어 지원 제도·어학 자격 포상', NULL, 'growth',
   'est', NULL, TRUE, '외국어 지원 제도 월 15만원, 자격 포상 (2026 ESG 정보공시 임직원 역량개발 교육체계 외국어 항목), 매월 제공되는 외국어 학습 지원 제도는 수강 개시 1년 경과 시 공인 평가 시험 기준 의무 적용 (같은 공시 어학 의무화 항목) — 지원 방식(한도·정액)·포상 기준 미기재', 30),
  (@comp_id, 'edu_support', 'SSG EDU·BOOK LEARNING·전사 특강', NULL, 'growth',
   'est', NULL, TRUE, 'SSG EDU · BOOK LEARNING, 디지털 · 고객 · 트렌드 전사 특강 (2026 ESG 정보공시 임직원 역량개발 교육체계 교양 공통 교육 항목) — 수강 방식·과정 구성 미기재', 31),
  (@comp_id, 'mba', '서울대 Mini MBA·KAIST Junior MBA', NULL, 'growth',
   'est', NULL, TRUE, '서울대 Mini MBA(BAND1 · BAND2), S-아카데미 KAIST Junior MBA(BAND3 · BAND4) (2026 ESG 정보공시 임직원 역량개발 교육체계 Retention 항목, 百부문 통합 운영) — 선발 기준·비용 지원 범위·학위 과정 여부 미기재', 32),

  -- ── 건강·의료 (health) — ESG 정보공시 사회23 · 그룹 채용 포털 ──
  (@comp_id, 'mental', '심리 상담 · 감정노동자 멘탈관리 프로그램', NULL, 'health',
   'est', NULL, TRUE, '임직원 대상 인권 리스크 완화 활동 중 심리 상담 (2026 ESG 정보공시 인권경영 관리활동 임직원 항목), 감정노동자 멘탈관리 프로그램 운영 (2026 ESG 정보공시 안전보건경영 중장기 로드맵 항목) — 상담 방식·횟수·외부 기관 연계 여부 미기재', 40),
  (@comp_id, 'health_check', '건강검진 (매년)', NULL, 'health',
   'est', NULL, TRUE, '건강검진 매년 실시 (신세계그룹 공식 채용 포털 복리후생 건강한 생활 지원 항목) — 검진 항목·가족 포함 여부·지원 금액 미기재 (그룹 통합 채용 기준)', 41),
  (@comp_id, 'medical', '의료비 지원 (본인·배우자·자녀)', NULL, 'health',
   'est', NULL, TRUE, '본인은 물론 배우자, 자녀까지 의료비 지원 (신세계그룹 공식 채용 포털 복리후생 건강한 생활 지원 항목) — 지원 범위·연간 한도 미기재 (그룹 통합 채용 기준)', 42),

  -- ── 보상·금전 (compensation) — 감사보고서 주석 · 그룹 채용 포털 ──
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 종업원에게 지급될 미래 경제적 효익 관련 종업원급여채무 (2025 사업보고서 감사보고서 주석 항목), 장기근속에 따른 포상제도 (신세계그룹 공식 채용 포털 복리후생 교육 및 경조사 지원 항목) — 근속 기준·급부 형태·금액 미기재 (그룹 통합 채용 기준)', 50),
  (@comp_id, 'holiday_gift', '명절 선물', NULL, 'compensation',
   'est', NULL, TRUE, '명절에 선물 지급 (신세계그룹 공식 채용 포털 복리후생 교육 및 경조사 지원 항목) — 선물 품목·금액 미기재 (그룹 통합 채용 기준)', 51),

  -- ── 경제적 부가혜택 (perks) — 그룹 채용 포털 ──
  (@comp_id, 'discount', '신세계그룹 계열사 할인', NULL, 'perks',
   'est', NULL, TRUE, '신세계 그룹의 임직원에게 다양한 계열사에서 할인혜택 제공 (신세계그룹 공식 채용 포털 복리후생 계열사 할인 혜택 항목) — 할인율·대상 계열사·연간 한도 미기재 (그룹 통합 채용 기준)', 60),
  (@comp_id, 'birthday_gift', '생일 선물', NULL, 'perks',
   'est', NULL, TRUE, '생일에 선물 지급 (신세계그룹 공식 채용 포털 복리후생 교육 및 경조사 지원 항목) — 선물 품목·금액 미기재 (그룹 통합 채용 기준)', 61),

  -- ── 휴가·휴직 (time_off) — 그룹 채용 포털 ──
  (@comp_id, 'refresh_leave', '연중휴가 5일', NULL, 'time_off',
   'est', NULL, TRUE, '기본적인 연차와 별도로 연중휴가 5일 제공 (신세계그룹 공식 채용 포털 복리후생 여가활동 지원 항목) — 사용 단위·이월 여부 미기재 (그룹 통합 채용 기준)', 70),

  -- ── 여가·라이프 (leisure) — 그룹 채용 포털 ──
  (@comp_id, 'resort', '신세계그룹 휴양시설·리조트 법인회원', NULL, 'leisure',
   'est', NULL, TRUE, '신세계 그룹 휴양시설 무료숙박 및 할인혜택 제공, 전국 리조트 및 휴양시설 법인회원혜택 지원 (신세계그룹 공식 채용 포털 복리후생 여가활동 지원 항목) — 연간 이용 한도·성수기 조건 미기재 (그룹 통합 채용 기준)', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
