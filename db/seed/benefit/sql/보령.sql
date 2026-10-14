-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 보령 복리후생 데이터 (신규 회사 — 웨이브 7)
-- 출처: AI 파싱 (2026-10-14)
-- URL: https://pharm.boryung.co.kr/esg/Csr_CsrReport.do
-- badge: est
--
-- 참고:
--   정본은 상장 법인 ㈜보령의 자기 도메인 pharm.boryung.co.kr ESG 경영 > 지속가능경영 보고서 목록 페이지다(SSR · JSP).
--   행의 원문은 그 목록 맨 위에 올라 있는 법인 단독 발행 2026 보령 지속가능경영보고서 PDF
--   (PDF 생성 2026-06 · 보고 기간 2025-01-01~2025-12-31 · 보고 범위 주식회사 보령 본사 및 국내 사업장
--   안산캠퍼스 · 예산캠퍼스 · 중앙연구소) 56쪽 복리후생 제도 표 + 53쪽 성과평가 및 보상 + 55쪽 건강한 조직문화
--   + 21쪽 임직원 참여형 ESG 활동 표 + 34쪽 종이컵 제로 캠페인.
--   공시 보조: OpenDART 2026 반기보고서(접수 20260814004226) 직원 등의 현황 유연근무제도 사용현황(시차출퇴근제 사용자 수).
--   직원 1,682명(2026-06-30).
--   채용 사이트 recruit.boryung.co.kr(나인하이어 · Vercel)는 robots 부터 429 보안 점검 화면이라 읽지 못했다(우회 안 함).
--   www.boryung.co.kr 은 같은 법인 브랜드 사이트(SPA)로 복지 경로 없음.
--   귀속: 보고서는 ㈜보령 자기 발행 · 법인 단독 보고 범위라 각주 없음. 지주 보령홀딩스 · 형제 법인은 코퍼스 · 대기 폴더에 없다.
--   금액: 원문에 원 단위 숫자 0건 — 전 행 BENEFIT_AMT NULL.
--   제외: 법정(유급연차휴가 · 가족돌봄휴직 90일 · 출산 전후 휴가 · 유사산 휴가 · 1년 이내 육아휴직 · 난임치료휴가 ·
--     배우자 출산휴가 20일 · 임신기 1일 2시간 단축 · 초과근무 수당 · 퇴직연금) · 업무 교육(입문 · 공채 · 직무 전문 ·
--     외부 직무교육 · 세일즈 아카데미 · 리더십 · 컴플라이언스) · 안전 포상 · 우리사주조합(주식 수 표 · 담보 주석뿐) ·
--     임원 · 팀장 ESG 성과지표 연동 인센티브 · 전사 조회 실적 포상(제도 문장 아님 — 근거표 판단 요청).
--   공고 근거 0행 / 전체 19행.
--   SORT 섹션 순서 = 보고서 첫 등장 순(perks 10 · compensation 20 · work_env 30 · leisure 40 · family 50 ·
--     health 60 · time_off 70 · flexibility 80).
-- 검증 · 감사 판정 반영(2026-10-14): 행 조치 없음 · 경조사 행 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 19행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('boryung', '보령',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '제약', 'B', 'https://pharm.boryung.co.kr/esg/Csr_CsrReport.do');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'boryung');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://pharm.boryung.co.kr/esg/Csr_CsrReport.do'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) — 보고서 21 · 34 · 56쪽 ──
  (@comp_id, 'meal', '구내식당 (안산캠퍼스)', NULL, 'perks',
   'est', NULL, TRUE, '구내식당 내 매주 수요일 잔반 없는 날 운영(안산) (2026 지속가능경영보고서 21쪽 임직원 참여형 ESG 활동 표 잔반 없는 날 항목) — 제공 끼니·식대 부담 방식 미기재', 10),
  (@comp_id, 'snack_bar', '사내 카페', NULL, 'perks',
   'est', NULL, TRUE, '사내 카페에서 텀블러 사용 시 할인 혜택 제공 (2026 지속가능경영보고서 34쪽 종이컵 제로 캠페인 항목) — 운영 사업장·이용 요금 미기재', 11),
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '연 2회 복지 포인트 지급 (2026 지속가능경영보고서 56쪽 복리후생 제도 표 복지포인트 항목) — 포인트 배정액·사용처 미기재', 12),
  -- ── 보상 (compensation) — 보고서 53쪽 ──
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '성과평가는 성과급 산정 기준으로 반영 (2026 지속가능경영보고서 53쪽 성과평가 및 보상 항목) — 지급 기준·지급률 미기재', 20),
  -- ── 근무환경 (work_env) — 보고서 55 · 56쪽 ──
  (@comp_id, 'lounge', '휴게공간 (BR Lounge)', NULL, 'work_env',
   'est', NULL, TRUE, '임직원의 회복과 성장을 지원하기 위한 휴게공간을 본사, 안산캠퍼스, 예산캠퍼스, 중앙연구소 등 각 사업장별로 확충, 본사 휴게공간 BR Lounge는 다양한 콘셉트와 기능을 갖춘 웰니스 융·복합공간 (2026 지속가능경영보고서 55쪽 근무환경 개선 항목) — 시설 구성·이용 시간 미기재', 30),
  (@comp_id, 'nap_room', '수유실', NULL, 'work_env',
   'est', NULL, TRUE, '각 사업장별 사내 수유실 운영 (2026 지속가능경영보고서 56쪽 복리후생 제도 표 가족복지제도 수유실 항목) — 시설 구성·이용 시간 미기재', 31),
  -- ── 여가 (leisure) — 보고서 55 · 56쪽 ──
  (@comp_id, 'company_event', 'BR together·팀 단위 액티비티', NULL, 'leisure',
   'est', NULL, TRUE, 'BR together 액티비티 이벤트, 임직원이 참여하는 클레이 사격 · 드래곤 보트 레이싱 등 팀 단위 액티비티, 임직원 정신건강관리를 위한 싱잉볼&요가 체험 (2026 지속가능경영보고서 55쪽 커뮤니케이션 활성화 항목) — 참가 대상·운영 주기·비용 지원 범위 미기재', 40),
  (@comp_id, 'club', '동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '취미 및 교양 함양을 위한 동호회 활동 지원 (2026 지속가능경영보고서 56쪽 복리후생 제도 표 동호회 항목) — 지원 금액·동호회 종류 미기재', 41),
  (@comp_id, 'resort', '콘도 및 펜션 지원', NULL, 'leisure',
   'est', NULL, TRUE, '평창, 제주, 대천 등 콘도 및 펜션 지원 (2026 지속가능경영보고서 56쪽 복리후생 제도 표 콘도 및 펜션 항목) — 지원 방식·이용 횟수·비용 지원 범위 미기재', 42),
  -- ── 가족 (family) — 보고서 56쪽 ──
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '고등학생 및 대학생 자녀 학자금 지원 (2026 지속가능경영보고서 56쪽 복리후생 제도 표 자녀 학자금 항목) — 지원 한도·자녀 수 제한 미기재', 50),
  (@comp_id, 'event', '경조사 지원금·상조용품', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원금 운영, 휴가 및 조사 발생 시 상조용품 지급 (2026 지속가능경영보고서 56쪽 복리후생 제도 표 상조지원 항목) — 경조 종류별 지원 금액·상조용품 품목 미기재', 51),
  (@comp_id, 'parenting', '출산 축하금', NULL, 'family',
   'est', NULL, TRUE, '출산 축하금 제공 (2026 지속가능경영보고서 56쪽 복리후생 제도 표 가족복지제도 출산 축하금 항목) — 지급 금액 미기재', 52),
  -- ── 건강 (health) — 보고서 56쪽 ──
  (@comp_id, 'health_check', '종합건강검진 (본인·배우자)', NULL, 'health',
   'est', NULL, TRUE, '연 1회 종합건강검진 지원, 기혼자의 경우 배우자 포함 (2026 지속가능경영보고서 56쪽 복리후생 제도 표 건강검진 항목) — 검진 항목·지원 금액 미기재', 60),
  (@comp_id, 'insurance', '상해보험', NULL, 'health',
   'est', NULL, TRUE, '전 직원 상해보험 가입 (2026 지속가능경영보고서 56쪽 복리후생 제도 표 상해보험 항목) — 보장 범위·가입 금액 미기재', 61),
  (@comp_id, 'fitness', '사내 헬스장 (안산·예산캠퍼스)', NULL, 'health',
   'est', NULL, TRUE, '안산캠퍼스, 예산캠퍼스 사내 헬스장 운영 (2026 지속가능경영보고서 56쪽 복리후생 제도 표 사내헬스장 항목) — 운영 시간·이용료 미기재', 62),
  -- ── 휴가 (time_off) — 보고서 56쪽 ──
  (@comp_id, 'summer_leave', '하계휴가 (연 5일 유급)', NULL, 'time_off',
   'est', NULL, TRUE, '연 5일 유급하계휴가 부여 (2026 지속가능경영보고서 56쪽 복리후생 제도 표 하계휴가 항목) — 사용 시기·분할 사용 여부 미기재', 70),
  (@comp_id, 'long_service_leave', '장기근속 포상·휴가', NULL, 'time_off',
   'est', NULL, TRUE, '10년, 20년, 30년 장기근속 포상 및 휴가 부여 (2026 지속가능경영보고서 56쪽 복리후생 제도 표 장기근속포상/휴가 항목) — 포상 내용·휴가 일수 미기재', 71),
  (@comp_id, 'leave_general', '연말 Refresh 휴가 (연말 Shut down)·유급 질병휴직', NULL, 'time_off',
   'est', NULL, TRUE, '연말 Refresh 휴가 연말 Shut down (2026 지속가능경영보고서 56쪽 복리후생 제도 표 유연근무제 연말 Refresh 휴가 항목), 질병휴직 유급 휴직 (같은 표 가족복지제도 질병휴직 항목) — 연차 사용일인지·휴무 일수·질병휴직 기간 미기재', 72),
  -- ── 근무 유연성 (flexibility) — 보고서 56쪽 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '유연근무제 (시차출퇴근제)', NULL, 'flexibility',
   'est', NULL, TRUE, '8시, 9시, 10시 중 출근 시간 선택 (2026 지속가능경영보고서 56쪽 복리후생 제도 표 유연근무제 시차출퇴근제 항목), 시차출퇴근제 사용자 수 190명 (2026 반기보고서 유연근무제도 사용현황 항목) — 적용 대상·신청 방식 미기재', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
