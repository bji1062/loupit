-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 신세계푸드 복리후생 데이터 (신규 회사 — 웨이브 14)
-- 출처: AI 파싱 (2026-10-22)
-- URL: https://www.shinsegaefood.com/csr/esgInfo_detail.sf?newsId=1460&pagging=1
-- badge: est
--
-- 참고:
--   정본 = 법인 자기 도메인 ESG 정보 게시판의 「주요 복지제도 현황」 게시물(2026.06.19 게시 · SSR 페이지 ·
--     본문은 이미지 1장 780x1050 · 7구분 표). 이미지를 원본 해상도로 판독(사본 image_transcript.txt).
--   보조 1 = 신세계그룹 채용 사이트 job.shinsegae.com 의 (주)신세계푸드 공고(회사 코드 EF0) 5건 복리후생 블록 —
--     5건 글자까지 같은 4줄 · 형제 법인 공고(신세계아이앤씨 5257 · 이마트 5401)의 블록과 다르다(그룹 템플릿 아님).
--     게시 중 공고 5404 · 5405 · 5406 · 5408(마감 2026-10-29 · 10-31) · 5222(상시 · 마감 2026-12-31).
--   보조 2 = 2026 반기보고서(20260814003217) 유연근무제도 사용 현황 표 · 재무제표 주석 기타장기종업원급여 문장
--     (2025 사업보고서 20260318000936 표와 대조).
--   렌더 없음(이미지 판독 · 공고는 키 없이 열리는 GET JSON). 사이트 키 사용 없음.
--   귀속: 정본 · 공고 모두 이 법인 자기 자료라 각주 없음. 비상장(옛 종목코드 031440 상장폐지) · 최대주주 이마트.
--   금액: 금액 행 0 — 명절 · 생일 상품권(각 5~15만원)은 구간 기준 미기재라 NULL(판단 요청) ·
--     의료비 · 학자금 · 생활보장은 한도 · 조건부 · 1회성 성격이라 NULL.
--   제외: 법정(임신기 단축의 법정 시간 · 급여 보전 · 육아기 근로시간 단축 주20시간 · 난임 유급휴가 제도 운영 ·
--     만 55세 이상 재취업 및 창업 아카데미 = 1,000인 이상 재취업지원) · 조직문화(직급 간소화 · 자율 복장제 · 컨설팅) ·
--     노사협의회 안건(결과 낱말 없음) · 원격근무(공시 세 기간 모두 사용자 없음 · 자기 출처 문장 없음).
--   공고 근거 1행 / 전체 17행(SORT 61).
--   SORT 섹션 순서 = family 10 · work_env 20 · flexibility 30 · time_off 40 · perks 50 · compensation 60 · health 70 · leisure 80.
-- 검증 · 감사 판정 반영(2026-10-22): 노사협의회 운영현황 게시물 3분기 성과급 지급 안내를 incentive 로(리드 판정 171) · 1분기 동호회 기준 완화를 club 으로 추가 · 사내복지기금 확대 안건은 싣지 않음(판정 164) · 이미지 판독 23줄 글자 일치 · 항목 페이지 예외 2(통합 밖 리드 집행) · 참고 블록의 공고 근거 1행 / 전체 17행과 제외 줄의 노사협의회 안건은 이 판정으로 뒤집힘(19행) — 최종 19행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('shinsegae_food', '신세계푸드',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '식품', 'S', 'https://www.shinsegaefood.com/csr/esgInfo_detail.sf?newsId=1460&pagging=1');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'shinsegae_food');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.shinsegaefood.com/csr/esgInfo_detail.sf?newsId=1460&pagging=1'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 가족 (family) — ESG 정보 주요 복지제도 현황 · 공고 ──
  (@comp_id, 'parenting', '임신·육아기 근로자 배려', NULL, 'family',
   'est', NULL, TRUE, '임신 근로자 단축근무 의무 적용, 법정 육아휴직 외 출산휴직(임신사실 확인 시 즉시 사용가능), 희망휴직 추가사용 가능(최대 1년), 임신 축하선물 지급, 초등자녀 입학 시 자녀 입학 · 돌봄 휴직 사용가능(1개월) (공식 ESG 정보 주요 복지제도 현황 페이지 임신/육아기 근로자 배려 항목) — 출산휴직 기간 · 휴직 중 급여 · 축하선물 품목 미기재', 10),
  (@comp_id, 'event', '경조휴가 및 경조금 지원', NULL, 'family',
   'est', NULL, TRUE, '경조휴가 및 경조금 지원 (공식 ESG 정보 주요 복지제도 현황 페이지 휴가제도 항목) — 경조 사유별 휴가 일수 · 경조금 금액 미기재', 11),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '학자금 지원(유치원-연 120만원, 고등학교-전액지원, 대학생-연 1천만원 학자금 지원) (공식 ESG 정보 주요 복지제도 현황 페이지 복리후생 항목), 자녀 학자금 제도 (공식 채용 공고 복리후생 항목) — 지원 자녀 수 · 근속 요건 미기재', 12),
  -- ── 근무환경 (work_env) — ESG 정보 주요 복지제도 현황 ──
  (@comp_id, 'nap_room', '임산부 휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '임산부 휴게실 별도 설치 운영 (공식 ESG 정보 주요 복지제도 현황 페이지 임신/육아기 근로자 배려 항목) — 설치 사업장 미기재', 20),
  -- ── 유연근무 (flexibility) — ESG 정보 주요 복지제도 현황 · 반기보고서 ──
  (@comp_id, 'flex_work', '탄력 출퇴근제 · 시차 출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '탄력 출퇴근제도(임직원의 업무상황에 따라 근무시간을 유연하게 운영하는 제도), 시차 출퇴근제도(임직원의 생활패턴에 따라 출근 시간을 조정하는 제도) (공식 ESG 정보 주요 복지제도 현황 페이지 근로시간 단축/유연화 항목), 시차출퇴근제 · 선택근무제 (2026 반기보고서 유연근무제도 사용 현황 항목) — 대상 직무 · 사용 조건 미기재', 30),
  -- ── 휴가 (time_off) — ESG 정보 주요 복지제도 현황 · 공고 · 반기보고서 ──
  (@comp_id, 'refresh_leave', '연중휴가', NULL, 'time_off',
   'est', NULL, TRUE, '법정휴가 외 유급 연중휴가 (공식 ESG 정보 주요 복지제도 현황 페이지 휴가제도 항목), 연중휴가 (공식 채용 공고 복리후생 항목) — 휴가 일수 · 부여 조건 미기재', 40),
  (@comp_id, 'long_service_leave', '장기근속 포상 휴가 및 휴가비 지원', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 포상 휴가 및 휴가비 지원 제도 (공식 ESG 정보 주요 복지제도 현황 페이지 휴가제도 항목), 장기근속종업원에게 근속기간에 따라 지급하는 장기유급휴가비 (2026 반기보고서 재무제표 주석 기타장기종업원급여 항목) — 근속 기준 · 휴가 일수 · 휴가비 금액 미기재', 41),
  -- ── 생활 지원 (perks) — ESG 정보 주요 복지제도 현황 · 공고 ──
  (@comp_id, 'discount', '그룹사 사원증 할인', NULL, 'perks',
   'est', NULL, TRUE, '그룹사 사원증 할인 (공식 ESG 정보 주요 복지제도 현황 페이지 복리후생 항목), 신세계 그룹사 할인 (공식 채용 공고 복리후생 항목) — 할인 대상 계열사 · 할인율 미기재', 50),
  (@comp_id, 'birthday_gift', '본인 생일 축하 상품권', NULL, 'perks',
   'est', NULL, TRUE, '본인생일 축하 상품권 지급(5~15만원) (공식 ESG 정보 주요 복지제도 현황 페이지 복리후생 항목), 생일 선물 지급 (공식 채용 공고 복리후생 항목) — 금액 구간 기준 미기재', 51),
  (@comp_id, 'housing_loan', '주택구매·전세 저리 대출 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택구매/전세 지원 주택구매 및 임차 시 저리(연 2%) 대출 지원 (공식 ESG 정보 주요 복지제도 현황 페이지 복리후생 항목) — 대출 한도 · 근속 요건 미기재', 52),
  -- ── 보상 (compensation) — ESG 정보 주요 복지제도 현황 · 공고 ──
  (@comp_id, 'holiday_gift', '명절 축하 상품권', NULL, 'compensation',
   'est', NULL, TRUE, '명절(설, 추석) 축하 상품권 지급(각 5~15만원) (공식 ESG 정보 주요 복지제도 현황 페이지 복리후생 항목), 명절 선물 지급 (공식 채용 공고 복리후생 항목) — 금액 구간 기준 미기재', 60),
  (@comp_id, 'long_service_bonus', '장기근속자 선물', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속자 선물 지급 (공식 채용 공고 복리후생 항목) — 근속 기준 · 선물 품목 미기재', 61),
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '25년 상반기 성과급 지급 안내 (공식 ESG 정보 25년 정기 노사협의회 운영현황 페이지 3분기 협의사항 항목) — 지급 대상 · 지급 기준·지급률 미기재', 62),
  -- ── 건강 (health) — ESG 정보 주요 복지제도 현황 · 공고 ──
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '의료비 지원(본인, 배우자, 자녀 대상 / 연 500~1000만원 실비 지원) (공식 ESG 정보 주요 복지제도 현황 페이지 복리후생 항목), 의료비 지원(본인, 배우자, 자녀) (공식 채용 공고 복리후생 항목) — 대상별 한도 구분 미기재', 70),
  (@comp_id, 'health_check', '건강검진', NULL, 'health',
   'est', NULL, TRUE, '건강검진 (공식 ESG 정보 주요 복지제도 현황 페이지 복리후생 항목) — 검진 주기·비용 지원 범위 미기재', 71),
  (@comp_id, 'insurance', '생활보장 지원', NULL, 'health',
   'est', NULL, TRUE, '생활보장 지원(재해/질병 사망, 장애, 암, 뇌졸중, 심근경색 등 발생 시 최대 1.5억 지원) (공식 ESG 정보 주요 복지제도 현황 페이지 복리후생 항목) — 보장 방식 · 가족 포함 여부 미기재', 72),
  (@comp_id, 'mental', 'EAP 제도 운영', NULL, 'health',
   'est', NULL, TRUE, 'EAP 제도 운영, 전문가를 통한 직원 스트레스 관리 프로그램 운영(Employee Assistance Program) (공식 ESG 정보 주요 복지제도 현황 페이지 EAP 제도 운영 항목) — 이용 횟수 · 가족 이용 여부 미기재', 73),
  -- ── 여가 (leisure) — ESG 정보 주요 복지제도 현황 · 공고 ──
  (@comp_id, 'resort', '휴양시설 지원', NULL, 'leisure',
   'est', NULL, TRUE, '휴양시설 지원(5성 호텔 및 유명 리조트 무료 숙박 및 식음지원) (공식 ESG 정보 주요 복지제도 현황 페이지 복리후생 항목), 호텔패키지 제공 · 콘도 회원가 이용 (공식 채용 공고 복리후생 항목) — 연간 이용 횟수 · 이용 시설 목록 미기재', 80),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '제도 개선 - 동호회 기준 완화 (공식 ESG 정보 25년 정기 노사협의회 운영현황 페이지 1분기 협의사항 항목) — 동호회 종류 · 지원 내용 미기재', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
