-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 카페24 복리후생 데이터 (신규 회사 — 웨이브 15)
-- 출처: AI 파싱 (2026-10-23)
-- URL: https://www.cafe24corp.com/recruit/welfare
-- badge: est
--
-- 참고:
--   정본 = 법인 자기 도메인 cafe24corp.com 채용정보 > 복리후생 페이지(SSR · 원본 HTML 에 항목 전부 · 렌더 없음).
--   보조 = 같은 도메인 회사소개 > 기업문화 페이지(오프데이 · 복지포인트 · 희망 도서) ·
--          같은 도메인 채용정보 > 채용분야 공고 근무조건 칸(점심 식대 1만원 · 연 220만 복지포인트) ·
--          OpenDART 2026 반기보고서(접수 20260813001736) 직원 등 현황 유연근무제도 사용 현황 표 ·
--          연결재무제표 주석 기타장기종업원급여부채(장기근속종업원 장기유급휴가).
--   귀속 = 이 법인 자기 도메인 · 이 법인 공시만. 그룹 · 형제 없음. 각주 없음.
--   금액 = 추정 2행: welfare_point 220(220만 복지포인트 매년 지급 · 1포인트 1원 기준 환산) ·
--          meal 240(점심 1끼 10,000원 × 연 240일 추정 · 단가는 공고 근무조건 칸). stated 0행.
--   제외 = 연차휴가 · 가족친화휴가(법에 준한 출산전후휴가 · 육아휴직 · 돌봄휴가)는 법정 ·
--          안전보건 페이지의 정기 건강진단 · 휴게시설 운영 문장은 법정 의무 문장 ·
--          자유 복장 · 수평 호칭 · 연봉 제도는 복지 코드 아님 · 우리사주조합은 주주 표 한 칸과 정관 배정 조항뿐.
--   공고 근거 1행 / 전체 11행(meal 단가 1만원만 공고 근거 · 행 자체는 상시 복리후생 페이지).
--   SORT 섹션 순서 = flexibility 10 · time_off 20 · perks 30 · growth 40 · family 50 · health 60.
-- 검증 · 감사 판정 반영(2026-10-23): 복지포인트 금액 220 을 영문 공식 채용 페이지 KRW 2.2 million 원화 연액으로 공식 수치(포인트 환산 표지 걷음) · 검진휴가 leave_general 행을 삭제하고 종합검진 health_check 행에 병합(감사 — 코퍼스 검진휴가 13사 · 같은 웨이브 3사가 검진 행 안) · 항목 페이지 예외 1(통합 밖 리드 집행) · 참고 블록의 금액 줄(추정 2행 · stated 0행)과 기타 휴가제도 세 행 가르기는 이 판정으로 뒤집힘 — 최종 10행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('cafe24', '카페24',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        'IT/플랫폼', 'C', 'https://www.cafe24corp.com/recruit/welfare');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'cafe24');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.cafe24corp.com/recruit/welfare'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — 공식 채용 페이지 복리후생 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '카페24 오프데이 주 4일 근무·시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '주 4일 근무(09시~18시) 시행, 각 조직에서 업무 특성에 맞는 최적의 근무형태(시차출퇴근)를 선택하여 유연한 근무제도 운영 (공식 채용 페이지 복리후생 근무제도 항목), 매주 금요일을 휴가일로 지정하여 주 4일 근무 실현 (같은 페이지 카페24 오프데이 항목), 일과 생활의 균형을 위한 오프데이 제도 (공식 홈페이지 기업문화 항목), 시차출퇴근제 사용자 2026년 반기 528명 · 2025년 560명 · 2024년 581명 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 시차출퇴근 시간대 미기재', 10),
  (@comp_id, 'remote_work', '재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '각 조직에서 업무 특성에 맞는 최적의 근무형태(재택근무)를 선택하여 현장 중심으로 유연한 근무제도 운영 (공식 채용 페이지 복리후생 근무제도 항목), 원격근무제(재택근무 포함) 사용자 2026년 반기 980명 · 2025년 982명 · 2024년 1,035명 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 재택근무 일수·사용 조건 미기재', 11),

  -- ── 휴가 (time_off) — 공식 채용 페이지 복리후생 · 2026 반기보고서 ──
  (@comp_id, 'long_service_leave', '안식(Refresh) 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '카페24의 성장을 함께 해준 구성원들에게 만 7년 근무마다 1개월의 유급 안식휴가 지원 (공식 채용 페이지 복리후생 안식(Refresh) 휴가 항목), 장기근속종업원에게 근속기간에 따라 지급하는 장기유급휴가 (2026 반기보고서 연결재무제표 주석 기타장기종업원급여부채 항목)', 20),
  (@comp_id, 'foundation_day_leave', '창립기념일 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '창립기념일 휴가 (공식 채용 페이지 복리후생 기타 휴가제도 항목) — 휴가 일수 미기재', 21),

  -- ── 생활 · 금융 (perks) — 공식 채용 페이지 복리후생 · 기업문화 · 채용 공고 ──
  (@comp_id, 'welfare_point', '복지포인트 (연 220만 포인트)', 220, 'perks',
   'est', '레저/취미 활동 및 자기계발을 지원하기 위해 자유롭게 사용 가능한 220만 복지포인트를 매년 지급 (공식 채용 페이지 복리후생 복지포인트 항목), 매년 220만원(KRW 2.2 million) 지급 (영문 공식 채용 페이지 Benefit allowance 항목) — 사용 방식·사용 기한 미기재', FALSE, NULL, 30),
  (@comp_id, 'meal', '점심 식대 (모바일 식권)', 240, 'perks',
   'est', '회사 근처 제휴 식당에서 사용할 수 있는 모바일 식권 지원 (공식 채용 페이지 복리후생 점심 식대 항목), 점심 식대 1만원 지급 (공식 채용 공고 근무조건 항목) — 제휴 식당 범위 미기재 (점심 1끼 10,000원 × 연 240일 추정)', FALSE, NULL, 31),

  -- ── 성장 · 교육 (growth) — 공식 채용 페이지 복리후생 · 기업문화 ──
  (@comp_id, 'books', '업무 관련 도서비', NULL, 'growth',
   'est', NULL, TRUE, '업무 관련 도서비 지원, 구성원들의 주도적인 성장과 역량 향상을 위해 업무 관련 도서를 무제한으로 지원 (공식 채용 페이지 복리후생 업무 관련 도서비 항목), 업무 관련 희망 도서 지원 (공식 홈페이지 기업문화 항목) — 신청 방식 미기재', 40),

  -- ── 가족 (family) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'childcare', '카페24 직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '영/유아반으로 구성된 카페24 직장어린이집 운영, 전문적인 보육 및 교육 서비스 제공 (공식 채용 페이지 복리후생 카페24 직장 어린이집 항목) — 정원·위치 미기재', 50),
  (@comp_id, 'event', '경조휴가·경조비 지원', NULL, 'family',
   'est', NULL, TRUE, '경조휴가(경조비 지원) (공식 채용 페이지 복리후생 기타 휴가제도 항목) — 경조 유형별 휴가 일수·경조비 금액 미기재', 51),

  -- ── 건강 (health) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'health_check', '종합검진센터 건강검진 · 검진휴가', NULL, 'health',
   'est', NULL, TRUE, '구성원들의 건강관리를 위해 종합검진센터에서 건강검진 실시 (공식 채용 페이지 복리후생 건강검진 항목), comprehensive health check-ups at affiliated centers (영문 공식 채용 페이지 복리후생 Health check-up 항목), 검진휴가 (공식 채용 페이지 복리후생 기타 휴가제도 항목) — 검진 주기·비용 지원 범위·가족 포함 여부·검진휴가 일수 미기재', 60)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
