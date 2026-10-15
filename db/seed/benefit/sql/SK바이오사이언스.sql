-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SK바이오사이언스 복리후생 데이터 (신규 회사 — 웨이브 7)
-- 출처: AI 파싱 (2026-10-14)
-- URL: https://www.skbioscience.com/kr/careers/welfare_02
-- badge: est
--
-- 참고:
--   정본은 상장 법인 SK바이오사이언스(주)의 자기 도메인 Careers > 인사/복지제도 > 복리후생 페이지다.
--   푸터 주소 인천광역시 연수구 연구단지로 38 SK바이오사이언스(주) · Copyright SK bioscience 가 본 법인이다.
--   SSR 이라 원본 HTML 에 항목 이름이 텍스트로 있다(사진 alt 문구 포함). 렌더 없음 · 이미지 판독 없음.
--   보조 출처:
--     (a) 같은 사이트 인사/복지제도 > 인사제도 페이지 휴가제도 표(휴가 이름 나열)
--     (b) 같은 사이트 인사/복지제도 > 자기개발 페이지 SKBS Academy 체계 표 공통 칸
--     (c) 자기 도메인 보도자료 2026.06.29 2026 ESG 보고서 발간 · 2026.06.01 송도 신사옥 가족 초청 행사
--     (d) OpenDART 2026 반기보고서(접수 20260813001292) 유연근무제도 사용 현황 표 · 재무제표 주석 사용제한 금융자산
--   2026 ESG 보고서 웹판(esg.skbioscience.com)은 본문 API 가 권한 없음(401)으로 막혀 읽지 못했다 — 근거표 확인하지 못한 것.
--   귀속: 모든 근거가 이 법인 자기 도메인 · 이 법인 공시다. 그룹 주어 문장 0건. skcareers 그룹 문구는 쓰지 않았다.
--     SK케미칼 보고서의 3사 공동 가족 초청 행사(2025)는 쓰지 않았고, 이 법인 보도자료의 2026 단독 행사만 근거로 했다. 그룹 각주 없음.
--   금액: 원화 금액 명시 0건 — 18행 전부 BENEFIT_AMT NULL. 식당은 끼니가 적히지 않아 NULL.
--   제외: 법정(연차휴가 · 가족돌봄휴가 · 보건휴가 · 산전후휴가 · 난임치료휴가 · 태아검진휴가 · 유/사산휴가) ·
--     업무 교육(SKBS Academy Value · Leadership · 직무 칸, mySUNI 바이오 아카데미 · DX 역량 개발 · GMP 기초 · 법정 필수/윤리경영) ·
--     SK Family Card(혜택이 적히지 않은 그룹 카드 이름) · RSU(재량 부여) · 임원 보수 칸 경영성과급.
--   신규 코드 없음. 공고 근거 0행 / 전체 18행.
--   SORT 섹션 순서는 정본 페이지에서 그 카테고리가 처음 나온 순서
--     (growth 10 · leisure 20 · flexibility 30 · health 40 · time_off 50 · family 60 · perks 70),
--     보조 출처에만 있는 compensation 은 끝(80).
-- 검증 · 감사 판정 반영(2026-10-14): 행 조치 없음 · 항목 페이지 예외 3(통합 밖 리드 집행) — 최종 18행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('sk_bioscience', 'SK바이오사이언스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '바이오', 'S', 'https://www.skbioscience.com/kr/careers/welfare_02');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'sk_bioscience');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.skbioscience.com/kr/careers/welfare_02'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 성장·교육 (growth) — 공식 채용 페이지 복리후생 날마다 좋아지는 배움 + 자기개발 페이지 ──
  (@comp_id, 'edu_support', 'SK 온라인 교육 플랫폼·사외교육 지원', NULL, 'growth',
   'est', NULL, TRUE, 'SK 온라인 교육 플랫폼, 사외교육 지원 (공식 채용 페이지 복리후생 날마다 좋아지는 배움 항목) — 수강 가능 과정·지원 한도 미기재', 10),
  (@comp_id, 'lang', '어학지원비·English Comm. Skill Up', NULL, 'growth',
   'est', NULL, TRUE, '어학지원비 (공식 채용 페이지 복리후생 날마다 좋아지는 배움 항목), English Comm. Skill Up (공식 채용 페이지 자기개발 SKBS Academy 체계 표 공통 항목) — 지원 금액·대상 언어·수강 대상 미기재', 11),

  -- ── 여가·라이프 (leisure) — 공식 채용 페이지 복리후생 + 공식 보도자료 ──
  (@comp_id, 'library', '사내도서관 (E-Book 포함)', NULL, 'leisure',
   'est', NULL, TRUE, '사내도서관 (E-Book 포함) (공식 채용 페이지 복리후생 날마다 좋아지는 배움 항목) — 설치 사업장·이용 시간 미기재', 20),
  (@comp_id, 'resort', '최고급 콘도 지원', NULL, 'leisure',
   'est', NULL, TRUE, '최고급 콘도 지원 (공식 채용 페이지 복리후생 날마다 좋아지는 라이프 항목) — 이용 일수·본인 부담 미기재', 21),
  (@comp_id, 'club', '동호회', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 (공식 채용 페이지 복리후생 날마다 좋아지는 라이프 항목) — 지원 금액·동호회 수 미기재', 22),
  (@comp_id, 'company_event', '가족 초청 행사', NULL, 'leisure',
   'est', NULL, TRUE, '구성원 가족 초청 행사 등 조직 문화 프로그램 운영 (공식 보도자료 2026.06.29 2026 ESG 보고서 발간 항목), 송도 본사에서 구성원 및 가족 450여 명이 참석한 가족 초청 행사 「슼박사네 집들이」 개최 (공식 보도자료 2026.06.01 가족 초청 행사 항목) — 개최 주기·참가 범위 미기재', 23),

  -- ── 유연근무 (flexibility) — 공식 채용 페이지 복리후생 날마다 좋아지는 근무제도 + 2026 반기보고서 ──
  (@comp_id, 'flex_work', '유연근무제 (시차출퇴근제·선택근무제)', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 (공식 채용 페이지 복리후생 날마다 좋아지는 근무제도 항목), 시차출퇴근제·선택근무제 (2026 반기보고서 유연근무제도 사용 현황 항목) — 코어타임·신청 절차 미기재', 30),
  (@comp_id, 'satellite_office', '거점오피스 (종로)', NULL, 'flexibility',
   'est', NULL, TRUE, '거점오피스 (종로) (공식 채용 페이지 복리후생 날마다 좋아지는 근무제도 항목) — 이용 대상·이용 방식 미기재', 31),
  (@comp_id, 'remote_work', '원격근무제(재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무 포함) (2026 반기보고서 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 32),

  -- ── 건강·의료 (health) — 공식 채용 페이지 복리후생 날마다 좋아지는 라이프 · 건강 ──
  (@comp_id, 'mental', '마음백신 (심리상담)', NULL, 'health',
   'est', NULL, TRUE, '마음백신 심리상담 (공식 채용 페이지 복리후생 날마다 좋아지는 라이프 항목) — 상담 횟수·비용 부담 미기재', 40),
  (@comp_id, 'fitness', '사내헬스장', NULL, 'health',
   'est', NULL, TRUE, '사내헬스장 (공식 채용 페이지 복리후생 날마다 좋아지는 건강 항목) — 설치 사업장·이용료 미기재', 41),
  (@comp_id, 'health_check', '종합건강검진·자사 독감백신 무료 접종', NULL, 'health',
   'est', NULL, TRUE, '종합건강검진, 자사 독감백신 무료 접종 (공식 채용 페이지 복리후생 날마다 좋아지는 건강 항목) — 검진 주기·비용 지원 범위 미기재', 42),

  -- ── 휴가 (time_off) — 공식 채용 페이지 복리후생 + 인사제도 휴가제도 표 ──
  (@comp_id, 'summer_leave', '하기 휴가 (6일)', NULL, 'time_off',
   'est', NULL, TRUE, '하기 휴가 (6일) (공식 채용 페이지 복리후생 날마다 좋아지는 라이프 항목), 모든 구성원에게 주어지는 휴가 하기휴가 (공식 채용 페이지 인사제도 휴가제도 항목) — 유급 여부·사용 시기 미기재', 50),
  (@comp_id, 'leave_general', '상병휴가·인정휴가·포상휴가·특별휴가', NULL, 'time_off',
   'est', NULL, TRUE, '특정 사유에 따라 주어지는 휴가 상병휴가·인정휴가, 회사가 특별히 부여하는 휴가 포상휴가·특별휴가 (공식 채용 페이지 인사제도 휴가제도 항목) — 휴가 일수·부여 조건·유급 여부 미기재', 51),

  -- ── 가족·돌봄 (family) — 공식 채용 페이지 복리후생 + 인사제도 휴가제도 표 ──
  (@comp_id, 'childcare', '어린이집', NULL, 'family',
   'est', NULL, TRUE, '어린이집 (공식 채용 페이지 복리후생 날마다 좋아지는 라이프 항목) — 설치 사업장·정원·보육료 부담 미기재', 60),
  (@comp_id, 'event', '경조휴가', NULL, 'family',
   'est', NULL, TRUE, '특정 사유에 따라 주어지는 휴가 경조휴가 (공식 채용 페이지 인사제도 휴가제도 항목) — 경조 구분별 휴가 일수·경조금 여부 미기재', 61),

  -- ── 경제적 부가혜택 (perks) — 공식 채용 페이지 복리후생 날마다 좋아지는 건강 ──
  (@comp_id, 'meal', '사내 식당', NULL, 'perks',
   'est', NULL, TRUE, '사내 식당 (공식 채용 페이지 복리후생 날마다 좋아지는 건강 항목 식당) — 제공 끼니·본인 부담 미기재', 70),

  -- ── 보상·금전 (compensation) — 2026 반기보고서 재무제표 주석 ──
  (@comp_id, 'stock_option', '우리사주조합 대출 담보 제공', NULL, 'compensation',
   'est', NULL, TRUE, '정기예금을 우리사주조합 대출에 대한 담보로 제공 (2026 반기보고서 재무제표 주석 사용이 제한된 금융자산 항목) — 가입 조건·대출 한도·금리 미기재', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
