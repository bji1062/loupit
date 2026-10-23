-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 도화엔지니어링 복리후생 데이터 (신규 회사 — 웨이브 15)
-- 출처: AI 파싱 (2026-10-23)
-- URL: https://www.dohwa.co.kr/recruit/benefit
-- badge: est
--
-- 참고:
--   정본 = 법인 자기 도메인 공식 채용 페이지 복리후생(SSR · 원본 HTML 에 22항목 · robots.txt 404 = 규칙 없음).
--   보조 = OpenDART 2026 반기보고서(20260813001545) · 2025 사업보고서(20260316001627) — 유연근무제도 사용 현황 표 ·
--     연결재무제표 주석 기타장기종업원급여부채(장기근속 장려 사내 복지 제도).
--   귀속 = 법인 단독 페이지 · 법인 단독 공시 — 각주 없음 · 기등록 형제 없음.
--   금액 = 금액 행 0(동호회 연간 최대 500만원 = 한도 · 금연수당 월 5만원 = 비흡연자 한정 조건부 · 구내식당 = 운영만 적혀 끼니 안 셈).
--   제외 = 자격수당(급여성) · 반차(법정) · 캐주얼 데이(복장 — 대응 코드 없음) · 우리사주조합(주주 표 한 칸) ·
--     임원 보수 칸 복리후생 · 이사회 안건 제목 임직원 성과급 지급(판단 요청) · 희망나눔기금 매칭(사회공헌 기부).
--   공고 근거 0행 / 전체 20행.
--   SORT 섹션 순서 = compensation 10 · health 20 · flexibility 30 · time_off 40 · leisure 50 · perks 60 · growth 70 ·
--     family 80 · work_env 90(정본 페이지 첫 등장 순).
-- 검증 · 감사 판정 반영(2026-10-23): 금연수당 비흡연자 월 5만원을 연 60만원 환산 추정 금액 행으로(리드 판정 183) · 종합건강검진 · 계열사 골프장 할인 라벨을 서술 앞에 · 업종을 새 값 건설엔지니어링 대신 기존 값 건설로(감사 — 계약 2-4 · 삼성E&A 선례) · 참고 블록의 금액 줄(금액 행 0 · 금연수당 조건부)과 업종 줄은 이 판정으로 뒤집힘 — 최종 20행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('dohwa', '도화엔지니어링',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '건설', 'D', 'https://www.dohwa.co.kr/recruit/benefit');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'dohwa');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.dohwa.co.kr/recruit/benefit'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상 (compensation) — 공식 채용 페이지 복리후생 · 반기보고서 주석 ──
  (@comp_id, 'youth_savings', '도화 희망채움적금', NULL, 'compensation',
   'est', NULL, TRUE, '공채 신입사원 대상으로 직원과 회사가 공동으로 운용하는 적립금 제도 운영 (공식 채용 페이지 복리후생 도화 희망채움적금 항목) — 회사 적립 비율·적립 기간 미기재', 10),
  (@comp_id, 'long_service_bonus', '장기 근속자 포상', NULL, 'compensation',
   'est', NULL, TRUE, '근속 연수별 포상금 지급 (공식 채용 페이지 복리후생 장기 근속자 포상 항목), 종업원의 사기 진작 및 장기근속 장려를 위한 사내 복지 제도 운영 (2026 반기보고서 재무제표 주석 기타장기종업원급여부채 항목) — 근속 기준·포상금액 미기재', 11),
  (@comp_id, 'holiday_gift', '창립기념일 기념선물', NULL, 'compensation',
   'est', NULL, TRUE, '창립기념 기념선물 제공 (공식 채용 페이지 복리후생 창립기념일 항목) — 선물 품목·금액 미기재', 12),
  -- ── 건강 (health) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'smoking_cessation', '금연수당', 60, 'health',
   'est', '비흡연자인 직원에 한하여 월 5만원 지급 (공식 채용 페이지 복리후생 금연수당 항목) — 비흡연 확인 방법 미기재, 월 5만원을 연 60만원으로 환산', FALSE, NULL, 20),
  (@comp_id, 'health_check', '종합건강검진', NULL, 'health',
   'est', NULL, TRUE, '종합건강검진, 매 2년마다 건강검진 지원 (공식 채용 페이지 복리후생 종합건강검진 항목) — 검진 항목·비용 지원 범위 미기재', 21),
  (@comp_id, 'mental', '마인드 힐링 서비스', NULL, 'health',
   'est', NULL, TRUE, '매주 금요일 임직원의 멘탈케어를 위한 상담 서비스 제공 (공식 채용 페이지 복리후생 마인드 힐링 서비스 항목) — 상담 방식·이용 횟수 미기재', 22),
  -- ── 근무 유연성 (flexibility) — 공식 채용 페이지 복리후생 · 반기 · 사업보고서 ──
  (@comp_id, 'flex_work', '선택적 근로 제도', NULL, 'flexibility',
   'est', NULL, TRUE, '10:00~17:00 코어타임, 그 외 시간에는 선택적 근로 가능 (공식 채용 페이지 복리후생 선택적 근로 제도 항목), 선택근무제 사용자 수 65기 6월말 1,786명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 정산 기간·적용 제외 직무 미기재', 30),
  (@comp_id, 'remote_work', '원격근무제 (재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무 포함) 사용자 수 65기 6월말 127명 · 64기 126명 · 63기 130명 (2026 반기보고서 · 2025 사업보고서 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 31),
  -- ── 휴가 (time_off) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'leave_general', '2시간 단위 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '휴가를 2시간 단위로 분할 사용 가능 (공식 채용 페이지 복리후생 항목) — 사용 한도 미기재', 40),
  (@comp_id, 'foundation_day_leave', '창립기념일 휴무', NULL, 'time_off',
   'est', NULL, TRUE, '창립기념 휴일 (공식 채용 페이지 복리후생 창립기념일 항목) — 휴무 일자 미기재', 41),
  -- ── 여가 (leisure) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'resort', '휴양시설 지원', NULL, 'leisure',
   'est', NULL, TRUE, '전국 10개 유명콘도 체인, 33개 시설 이용 가능 (공식 채용 페이지 복리후생 휴양시설 지원 항목) — 이용 비용 지원 범위 미기재', 50),
  (@comp_id, 'sports_ticket', '스포츠 시즌권', NULL, 'leisure',
   'est', NULL, TRUE, '프로야구 잠실구장 시즌권 신청자 대상으로 제공, FC서울 스카이박스 시즌권 부문별 제공 (공식 채용 페이지 복리후생 스포츠 시즌권 항목) — 제공 매수·배정 기준 미기재', 51),
  (@comp_id, 'club', '사내 동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '동호회별 연간 최대 500만원 지급 (공식 채용 페이지 복리후생 사내 동호회 지원 항목) — 동호회 종류·지원 기준 미기재', 52),
  -- ── 생활 · 편의 (perks) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'meal', '구내식당 운영', NULL, 'perks',
   'est', NULL, TRUE, '구내식당 운영, 조식, 중식, 석식 운영 (공식 채용 페이지 복리후생 항목) — 식대 부담 방식 미기재', 60),
  (@comp_id, 'discount', '계열사 골프장 할인', NULL, 'perks',
   'est', NULL, TRUE, '계열사 골프장 할인, 아리지 컨트리 클럽 할인 혜택 제공 (공식 채용 페이지 복리후생 계열사 골프장 할인 항목) — 할인율·이용 대상 미기재', 61),
  -- ── 성장 (growth) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'lang', '외국어 교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '영어, 중국어, 일본어, 독일어 등 온라인 외국어 교육 지원, 원어민과의 전화영어 및 화상영어 수업 제공 (공식 채용 페이지 복리후생 외국어 교육 지원 항목) — 수강료 지원 범위 미기재', 70),
  -- ── 가족 (family) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '분기별 자녀수에 관계없이 학자금 지원, 미취학 아동, 유치원, 초 · 중 · 고등학교, 대학교 등록금 지원 (공식 채용 페이지 복리후생 자녀 학자금 지원 항목) — 지원 한도 미기재', 80),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조금, 경조화환, 경조용품 지원 (공식 채용 페이지 복리후생 경조사 지원 항목) — 경조 종류별 지원 금액 미기재', 81),
  (@comp_id, 'parenting', '출산지원금 · 영유아 돌봄휴가 · 초등학교 입학 선물', NULL, 'family',
   'est', NULL, TRUE, '자녀 출산에 따른 출산지원금 및 선물 지급 (공식 채용 페이지 복리후생 출산지원금 항목), 만 5세이하 자녀 병원 방문 시 특별휴가 부여 (같은 페이지 영유아 돌봄휴가 항목), 초등학교 입학 자녀 선물 지급 (같은 페이지 초등학교 입학 선물 항목) — 출산지원금액·휴가 일수 미기재', 82),
  -- ── 근무 환경 (work_env) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'nap_room', '임산부 휴게실 (수유실 포함)', NULL, 'work_env',
   'est', NULL, TRUE, '수유실이 포함된 임산부 전용 휴게시설 제공 (공식 채용 페이지 복리후생 임산부 휴게실 운영 항목) — 설치 사업장 미기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
