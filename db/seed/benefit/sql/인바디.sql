-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 인바디 복리후생 데이터 (신규 회사 — 웨이브 8)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.inbodyrecruit.com/content/page/insa
-- badge: est
--
-- 참고:
--   정본 = 공식 홈 inbody.co.kr 이 링크한 회사 채용 사이트 www.inbodyrecruit.com 「인사제도·복리후생」 페이지(SSR · 복리후생 아이콘 목록 + 문답 4개 + 보상제도 문단).
--   보조 = 같은 사이트 「인바디 이야기」 페이지 「직원을 위한 다양한 복리후생 제도」 절(휴양소 · 동호회 · 헬스장) ·
--          OpenDART 2026 반기보고서(접수 20260814003648 — 유연근무제도 사용 현황 표 · 자기주식 처분 현황).
--   귀속 = ㈜인바디 법인 자기 채용 사이트(꼬리말 법인명 · 사업자등록번호) — 그룹 · 형제 없음 · 각주 없음. 해외 법인 문장 없음.
--   HTML 주석 속 옛 복리후생 블록(시설 제공 등)은 공개 원문이 아니라 쓰지 않았다.
--   금액 = welfare_point 100 stated(연 100만원) · meal 864 추정(천안공장 3식 × 12,000원 × 240일) · 나머지 정성.
--   제외 = 육아휴직 · 배우자 출산휴가(법정 · 공시 사용 현황 표) · 과제업무제도 · GBD 프로그램(업무 · 선발형 육성) · 연봉 책정(급여).
--   공고 근거 0행 / 전체 18행.
--   SORT 섹션 = compensation 10 · perks 20 · growth 30 · family 40 · work_env 50 · leisure 60 · time_off 70 · health 80 · flexibility 90(공시만).
-- 검증 · 감사 판정 반영(2026-10-15): 반기보고서 자기주식 임직원 보상 처분 stock_grant 추가(참고 블록 제외 줄의 자기주식 처분은 이 판정으로 뒤집힘) — 최종 19행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('inbody', '인바디',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '의료기기', 'I', 'https://www.inbodyrecruit.com/content/page/insa');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'inbody');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.inbodyrecruit.com/content/page/insa'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상 (compensation) — 채용 사이트 보상제도 · 복리후생 / 반기보고서 자기주식 ──
  (@comp_id, 'incentive', '성과급 (직무별 리그 결과)', NULL, 'compensation',
   'est', NULL, TRUE, '직무별 리그의 결과에 따라 별도 성과급 지급 (공식 채용 사이트 인사제도·복리후생 보상제도 항목) — 지급 시기·지급률 미기재', 10),
  (@comp_id, 'holiday_gift', '명절 선물', NULL, 'compensation',
   'est', NULL, TRUE, '명절 선물 (공식 채용 사이트 인사제도·복리후생 복리후생 항목) — 선물 품목·금액 미기재', 11),
  (@comp_id, 'stock_option', '우리사주조합 무상출연', NULL, 'compensation',
   'est', NULL, TRUE, '임직원 보상제도 운영을 위해 2026년 3월 4일자로 자기주식 3,346주 우리사주조합 무상출연, 임직원 성과보상을 위한 자기주식 처분(처분상대방 ㈜인바디 우리사주조합) (2026 반기보고서 자기주식 취득 및 처분 현황 항목) — 조합원 자격·1인당 배정 수량 미기재', 12),
  (@comp_id, 'stock_grant', '자사주 지급 (임직원 보상)', NULL, 'compensation',
   'est', NULL, TRUE, '임직원 보상제도 운영을 위해 2026년 5월 21일자로 자기주식 5,100주를 임직원 및 우리사주조합에 처분, 처분 목적 우리사주조합 무상출연 및 주식보상 (2026 반기보고서 자기주식 취득 및 처분 현황 항목) — 지급 대상·1인당 주식 수·지급 기준 미기재', 13),

  -- ── 생활 · 편의 (perks) — 채용 사이트 복리후생 ──
  (@comp_id, 'welfare_point', '분기별 복지포인트', 100, 'perks',
   'est', '연 100만원의 복지포인트를 분기별로 지급, 식당·병원·숙박·교통·교육 등 다양한 업종에서 온오프라인 관계 없이 사용 (공식 채용 사이트 인사제도·복리후생 문답 항목) — 직급별 차등 여부 미기재', FALSE, NULL, 20),
  (@comp_id, 'meal', '조식 포인트 (본사) · 3식 제공 (천안공장)', 864, 'perks',
   'est', '조식 포인트 (본사), 3식 제공 (천안공장) (공식 채용 사이트 인사제도·복리후생 복리후생 항목) — 1끼 단가·조식 포인트 금액 미기재 (하루 3끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 21),
  (@comp_id, 'birthday_gift', '생일자 쿠폰', NULL, 'perks',
   'est', NULL, TRUE, '생일자 쿠폰 지급 (공식 채용 사이트 인사제도·복리후생 복리후생 항목) — 쿠폰 종류·금액 미기재', 22),

  -- ── 성장 · 교육 (growth) — 채용 사이트 복리후생 ──
  (@comp_id, 'books', '도서 구매비', NULL, 'growth',
   'est', NULL, TRUE, '도서 구매비 (공식 채용 사이트 인사제도·복리후생 복리후생 항목) — 지원 방식·한도 미기재', 30),
  (@comp_id, 'edu_support', '교육비 지원(직무) · 전문가 초청 강의', NULL, 'growth',
   'est', NULL, TRUE, '교육비 지원(직무), 전문가 초청 강의 (공식 채용 사이트 인사제도·복리후생 복리후생 항목) — 지원 한도·강의 주제·횟수 미기재', 31),
  (@comp_id, 'lang', '어학비 지원(주재원 기회)', NULL, 'growth',
   'est', NULL, TRUE, '어학비 지원(주재원 기회) (공식 채용 사이트 인사제도·복리후생 복리후생 항목) — 지원 대상·한도 미기재', 32),

  -- ── 가족 (family) — 채용 사이트 복리후생 ──
  (@comp_id, 'event', '경조사 지원 · 장례지원 서비스', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원, 장례지원 서비스 (공식 채용 사이트 인사제도·복리후생 복리후생 항목) — 경조 구분별 지원 내용·장례 지원 범위 미기재', 40),

  -- ── 근무 환경 (work_env) — 채용 사이트 복리후생 ──
  (@comp_id, 'dormitory', '기숙사 · 사택 지원 (천안공장)', NULL, 'work_env',
   'est', NULL, TRUE, '기숙사, 사택 지원 (천안공장) (공식 채용 사이트 인사제도·복리후생 복리후생 항목) — 입주 자격·본인 부담 미기재', 50),

  -- ── 여가 (leisure) — 채용 사이트 복리후생 · 문답 / 인바디 이야기 ──
  (@comp_id, 'resort', '휴양소 · 양평 캠핑장', NULL, 'leisure',
   'est', NULL, TRUE, '휴양소 운영(강릉, 부산, 고성, 여수, 태안, 가평), 캠핑장 운영(양평), 1개월 전 사내 시스템 예약·다수 신청 시 미사용자 우선 후 추첨 (공식 채용 사이트 인사제도·복리후생 복리후생·문답 항목), 추첨을 통해 임직원 누구나 무료 이용 (같은 사이트 인바디 이야기 복리후생 제도 항목) — 연간 이용 횟수·숙박 일수 미기재', 60),
  (@comp_id, 'club', '동호회 지원 (활동비 · 4시 퇴근)', NULL, 'leisure',
   'est', NULL, TRUE, '약 40개 동호회 운영, 매월 둘째 주 수요일을 동호회 활동일로 지정해 4시 퇴근제도 시행 및 활동비 지원 (공식 채용 사이트 인사제도·복리후생 복리후생·문답 항목, 같은 사이트 인바디 이야기 복리후생 제도 항목) — 활동비 금액 미기재', 61),

  -- ── 휴가 (time_off) — 채용 사이트 복리후생 · 문답 ──
  (@comp_id, 'long_service_leave', '장기근속사원 포상 및 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '회사 근속 10년 5일의 특별휴가와 금 10돈, 근속 20년 10일의 특별휴가와 금 20돈 지급 (공식 채용 사이트 인사제도·복리후생 문답 항목) — 휴가 유급 여부·사용 기한 미기재', 70),

  -- ── 건강 (health) — 채용 사이트 복리후생 / 인바디 이야기 ──
  (@comp_id, 'health_check', '종합건강검진 · 독감예방접종', NULL, 'health',
   'est', NULL, TRUE, '독감예방접종(전직원), 40세/부장 이상 배우자 동반 종합건강검진 (공식 채용 사이트 인사제도·복리후생 복리후생 항목) — 검진 주기·비용 지원 범위 미기재', 80),
  (@comp_id, 'fitness', '사내 헬스장', NULL, 'health',
   'est', NULL, TRUE, '사내 헬스장 (공식 채용 사이트 인사제도·복리후생 복리후생 항목), 본사와 천안공장에 다양한 운동기구를 갖춘 사내 헬스장 자유 이용 (같은 사이트 인바디 이야기 복리후생 제도 항목) — 운영 시간 미기재', 81),

  -- ── 근무 유연성 (flexibility) — 2026 반기보고서 유연근무제도 사용 현황 ──
  (@comp_id, 'flex_work', '시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '시차출퇴근제 운영, 당반기 사용자 238명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 90),
  (@comp_id, 'remote_work', '원격근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제 사용자 수 당반기 1명, 전기 29명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
