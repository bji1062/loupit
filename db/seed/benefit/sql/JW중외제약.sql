-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- JW중외제약 복리후생 데이터 (신규 회사 — 웨이브 15)
-- 출처: AI 파싱 (2026-10-23)
-- URL: https://www.jw-pharma.co.kr/pharma/ko/esg/social.jsp
-- badge: est
--
-- 참고:
--   정본은 상장 법인 JW중외제약(KOSPI 001060) 자기 도메인 www.jw-pharma.co.kr 의 ESG 사회적 지속가능성 페이지.
--   이 페이지의 인재경영 내려받기(/pharma/ko/asset/files/s_02_talent.pdf)가 2025 JW Annual Report 76~85쪽 발췌이고,
--   같은 도메인 Annual Report 페이지에 전문 PDF(/download/2025_JW_Annual_Report_ko_fin.pdf · 110쪽 · 2026년 3월 작성 ·
--   보고 기간 2025-01-01~2025-12-31)가 있다. 행 근거 쪽: 79쪽 가족친화경영 · 80쪽 노사 상생 · 81쪽 자기주도학습 · 66쪽 사회공헌.
--   보조 공시: OpenDART 2026 반기보고서(접수 20260814004216) · 2025 사업보고서(접수 20260318001544) 유연근무제도 사용 현황 표.
--   렌더 방식: SSR HTML + 자기 도메인 PDF 텍스트 레이어 · 헤드리스 렌더 0회.
--   귀속: 보고서는 JW의 연간 통합보고서이고 보고 범위가 JW홀딩스 + 5개 자회사(109쪽)다. 복지 문장 주어가 전부 JW는 이고
--   계열사별 상이 단서가 없어 그룹 공통 제도로 보고, 보고서 문장 근거 구절의 출처 괄호에 JW그룹 공통 문구 각주를 달았다.
--   80쪽 노사협의회 표는 법인별 줄이라 JW중외제약 줄만 쓰고 각주 없음. 공시 문장도 이 법인 원문이라 각주 없음.
--   JW그룹 통합 채용 사이트 jwholdings.recruiter.co.kr 는 본문이 robots 금지 경로(/resources · /app)에서 불러와져 읽지 않았다.
--   금액: 0행(원문에 금액 숫자 없음).
--   제외: 법정(보건휴가 · 출산휴가 90일과 60일 통상임금 · 배우자 출산휴가 20일 · 태아 정기 건강진단 휴가 · 임신기 · 육아기 단축 ·
--   육아휴직 · 가족돌봄휴직 · 법정필수 교육) · 업무 교육(온보딩 · 직무 · 직책자 · 조직문화 워크숍) · 다른 법인 줄(노사협의회 표의
--   JW홀딩스 · JW신약 · JW생명과학 줄 — 동호회 · 스낵바 · 라운지바 · 기숙사) · 집중근무시간(근무 운영) · 우리사주조합(주주 표 한 칸).
--   공고 근거 0행 / 전체 12행.
--   SORT 섹션 순서: 79쪽에서 처음 나온 순서(time_off · flexibility · family) 뒤에 80쪽 perks · 81쪽 growth · 66쪽 compensation.
-- 검증 · 감사 판정 반영(2026-10-23): 2025 JW Annual Report 71쪽 윤리경영 실천 우수자 포상을 excellence_award 로 추가(JW그룹 공통 문구 각주) · 각주 꼴은 JW는 주어 문장이라 그룹 공통 문구 · 항목 페이지 예외 1(통합 밖 리드 집행) · 참고 블록의 공고 근거 0행 / 전체 12행 · compensation 66쪽은 이 판정으로 뒤집힘(13행 · 66 · 71쪽) — 최종 13행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('jw_pharma', 'JW중외제약',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '제약', 'J', 'https://www.jw-pharma.co.kr/pharma/ko/esg/social.jsp');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'jw_pharma');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.jw-pharma.co.kr/pharma/ko/esg/social.jsp'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 휴가 (time_off) — 2025 JW Annual Report 79쪽 ──
  (@comp_id, 'summer_leave', '하계휴가', NULL, 'time_off',
   'est', NULL, TRUE, '임직원들이 가족들과 함께 재충전의 기회를 위해 운영하는 다양한 휴가 제도 중 하계휴가 (2025 JW Annual Report 79쪽 가족친화경영 다양한 휴가제도 항목, JW그룹 공통 문구) — 본인 휴가 사용일인지·일수·유급 여부 미기재', 10),
  (@comp_id, 'foundation_day_leave', '창립기념일 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '다양한 휴가 제도 중 창립기념일 (2025 JW Annual Report 79쪽 가족친화경영 다양한 휴가제도 항목, JW그룹 공통 문구) — 휴무 일수·날짜 미기재', 11),
  -- ── 근무 유연성 (flexibility) — 2025 JW Annual Report 79쪽 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '시차출퇴근제 · 탄력근무제 · 선택근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '출퇴근 시간을 조정하는 시차출퇴근제, 특정 기간 내 업무시간을 조정할 수 있는 탄력근무제 운영 (2025 JW Annual Report 79쪽 가족친화경영 근무형태의 다양화 항목, JW그룹 공통 문구), 시차출퇴근제 사용자 수 133명 · 선택근무제 사용자 수 14명 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 20),
  (@comp_id, 'remote_work', '원격근무제(재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무 포함) 사용자 수 83명 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목), 120명 (2025 사업보고서 같은 항목) — 대상 직무·사용 조건 미기재', 21),
  -- ── 가족 (family) — 2025 JW Annual Report 79쪽 ──
  (@comp_id, 'parenting', '출산지원금 · 자녀 입학 축하 선물', NULL, 'family',
   'est', NULL, TRUE, '출산지원금 (2025 JW Annual Report 79쪽 가족친화경영 임신 및 출산에 따른 복지 항목, JW그룹 공통 문구), 새로운 시작을 응원하는 마음을 담아 입학 축하 선물을 각 가정으로 배송 (같은 쪽 자녀 학자금 지원 항목, JW그룹 공통 문구) — 출산지원금 금액·지급 기준, 선물 품목 미기재', 30),
  (@comp_id, 'child_edu', '자녀 학자금 지원 (고등학교 · 대학교)', NULL, 'family',
   'est', NULL, TRUE, '자녀 교육에 따른 경제적 부담 완화를 위해 임직원 자녀 고등학교, 대학교 입학금과 학자금 지원 (2025 JW Annual Report 79쪽 가족친화경영 자녀 학자금 지원 항목, JW그룹 공통 문구) — 지원 한도·자녀 수 제한 미기재', 31),
  (@comp_id, 'event', '경조휴가 · 부모회갑지원금', NULL, 'family',
   'est', NULL, TRUE, '다양한 휴가 제도 중 경조휴가 (2025 JW Annual Report 79쪽 가족친화경영 다양한 휴가제도 항목, JW그룹 공통 문구), 부모회갑지원금 (같은 쪽 임신 및 출산에 따른 복지 항목, JW그룹 공통 문구) — 경조 유형별 휴가 일수·지원 금액 미기재', 32),
  -- ── 생활 · 금융 · 주거 (perks) — 2025 JW Annual Report 80쪽 ──
  (@comp_id, 'meal', '구내식당 (11층)', NULL, 'perks',
   'est', NULL, TRUE, '11F 구내식당 시설 개선(외부 테라스 시설 개선 및 좌석 증설) (2025 JW Annual Report 80쪽 노사 상생 2025년 노사협의회 진행사항 표 JW중외제약 2분기 항목) — 제공 끼니·식대 지원 여부 미기재', 40),
  -- ── 성장 · 교육 (growth) — 2025 JW Annual Report 81쪽 ──
  (@comp_id, 'edu_support', 'JW Learning Cloud 온라인 학습 플랫폼', NULL, 'growth',
   'est', NULL, TRUE, '온라인 학습 플랫폼 JW Learning Cloud에서 매월 업데이트되는 북클릭(도서학습), 이러닝 등 약 3,200여 개 과정으로 교양 증진 등 자기 개발 실천 (2025 JW Annual Report 81쪽 임직원 역량강화 프로그램 자기주도학습 항목, JW그룹 공통 문구) — 수강 비용 부담·수강 한도 미기재', 50),
  (@comp_id, 'lang', '어학 온라인 과정 (JW Learning Cloud)', NULL, 'growth',
   'est', NULL, TRUE, '온라인 학습 플랫폼 JW Learning Cloud의 어학 과정 (2025 JW Annual Report 81쪽 임직원 역량강화 프로그램 자기주도학습 항목, JW그룹 공통 문구) — 언어 종류·수강 조건 미기재', 51),
  (@comp_id, 'conference', '사외 전문 교육 지원제도', NULL, 'growth',
   'est', NULL, TRUE, '사외 전문 교육 지원제도 운영, 임직원이 자신의 직무 분야에 필요한 외부 교육을 스스로 선택하고 수강 (2025 JW Annual Report 81쪽 임직원 역량강화 프로그램 자기주도학습 항목, JW그룹 공통 문구) — 지원 한도·비용 부담 비율 미기재', 52),
  -- ── 보상 · 금전 (compensation) — 2025 JW Annual Report 66쪽 ──
  (@comp_id, 'holiday_gift', '임직원 명절 선물', NULL, 'compensation',
   'est', NULL, TRUE, '추석 명절에는 자체 임직원 명절 선물 품목에 당진 특산물을 직접 포함 (2025 JW Annual Report 66쪽 사회공헌 특산물 활용 지역 경제 활성화 항목, JW그룹 공통 문구) — 선물 가액·지급 대상 미기재', 60),
  (@comp_id, 'excellence_award', '윤리경영 실천 우수자 포상', NULL, 'compensation',
   'est', NULL, TRUE, '윤리경영평가제도 운영, 윤리경영 실천 우수자 연 1회 시상금 100만 원 내외 수준 지급(각 사별 자율준수관리자 및 담당자 평가) (2025 JW Annual Report 71쪽 준법 및 윤리경영 윤리경영평가제도 항목, JW그룹 공통 문구) — 선정 인원·선정 기준 미기재', 61)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
