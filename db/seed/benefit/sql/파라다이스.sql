-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 파라다이스 복리후생 데이터 (신규 회사 — 웨이브 6)
-- 출처: AI 파싱 (2026-10-14)
-- URL: https://www.paradise.co.kr/images/file/2025_SustainabilityReport_KOR_F_0728.pdf
-- badge: est
--
-- 참고:
--   정본은 상장 법인 주식회사 파라다이스(KOSPI 034230)가 자기 도메인 www.paradise.co.kr 에 직접 올린
--   2025 파라다이스 지속가능경영보고서 PDF(지속가능경영 페이지 /ko/about/sustainability 의 ESG 보고서 블록에서
--   링크 · 발행 2026년 6월 · 보고 기간 2025-01-01~2025-12-31 · 114쪽 · 이 회사가 올린 가장 새 판).
--   본문 행은 50쪽 복리후생 프로그램 표(일·가정 양립 · 출산 및 육아 · 가족 돌봄 지원 · 기타 4칸 16행).
--   보조 쪽: 48쪽 독서경영 프로그램 표 · 49쪽 대학원 학위 취득 지원제도 · 성과 보상 제도 ·
--   52쪽 가족초청행사 · 56쪽 임직원 건강검진 지원 · 57쪽 심리 상담 · 104쪽 지배구조 성과 표.
--   렌더 방식: PDF 텍스트 레이어(pypdf) + 50쪽 표 이미지 대조 · 헤드리스 렌더 0회.
--   보조 공시 확인: OpenDART 2026 반기보고서(접수 20260814002485) — 복지 문장 없음, 행 근거로 쓰지 않음.
--   귀속: 보고서는 주식회사 파라다이스를 파라다이스로 정의하지만 비재무 보고 범위(2쪽)가 본사 · 카지노
--   워커힐 · 부산 · 제주 · 스파 도고 + 파라다이스 호텔 부산 + 파라다이스시티(파라다이스 세가사미) 통합이고
--   50쪽 표에 법인 구분이 없다. 리드 판정 (99)에 따라 전 행 서술 끝에 통합 보고 기준 각주를 단다.
--   자회사 시설(원더박스 · 씨메르) 할인은 이름을 계열 시설 할인으로 하고 시설 이름은 서술에 둔다.
--   파라다이스시티 · 호텔 부산이 주어인 블록(퇴직자 지원 · 촉탁 · 해피민트 · 의무실 · 명절 도시락)은 싣지 않는다.
--   채용 메뉴 /ko/recruit/* 는 봇 차단, recruit.paradise.co.kr 은 robots 전면 금지라 요청하지 않았다.
--   금액: 0행. 유일한 숫자 임차료 월 최대 30만원은 한도 + 거주지 조건이라 NULL.
--   제외: 법정(50쪽 표 출산 및 육아 칸 6행 — 임신기 · 육아기 단축 · 태아검진휴가 · 난임 6일 · 출산휴가 ·
--   육아휴직, 56쪽 공단 · 특수검진, 근골격계 유해요인 조사, 보건관리 상담) · 업무 교육(직무 · 핵심인재 ·
--   온라인 학습 플랫폼) · 다른 법인 주어 블록 · 2025년 1회 행사(명절 간식 · Re:Connect).
--   공고 근거 0행 / 전체 15행.
--   SORT 섹션 순서: 50쪽 표에서 처음 나온 순서(flexibility · health · family · time_off · perks · work_env)
--   뒤에 보조 쪽 카테고리(leisure · growth · compensation).
-- 검증 · 감사 판정 반영(2026-10-14): 온라인 학습 플랫폼 파라人SIGHT 를 독서 소모임 행에 합침(참고 블록 제외 목록의 온라인 학습 플랫폼 줄은 이 판정으로 뒤집힘) · 성과급 서술 교체 — 최종 15행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('paradise', '파라다이스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '카지노/호텔', 'P', 'https://www.paradise.co.kr/images/file/2025_SustainabilityReport_KOR_F_0728.pdf');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'paradise');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.paradise.co.kr/images/file/2025_SustainabilityReport_KOR_F_0728.pdf'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — 50쪽 일·가정 양립 ──
  (@comp_id, 'flex_work', '탄력적 근로시간제·시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '2주 단위~3개월 단위 탄력적 근로시간제 운영, 시차출퇴근제로 개인 사정에 따라 출퇴근 시간 조정 (2025 지속가능경영보고서 50쪽 복리후생 프로그램 일·가정 양립 항목) — 적용 대상 직무·조정 가능 시간대 미기재 (파라다이스 · 파라다이스시티 · 호텔 부산 통합 보고 기준)', 10),

  -- ── 건강 (health) — 50쪽 표 · 56쪽 · 57쪽 ──
  (@comp_id, 'health_check', '건강검진 지원 (본인·가족)', NULL, 'health',
   'est', NULL, TRUE, '매년 직급별로 차등화된 종합검진 비용을 회사가 전액 지원, 배우자·직계가족·빙부모를 포함한 가족 검진 비용도 함께 지원 (2025 지속가능경영보고서 50쪽 가족 건강검진 지원 항목·56쪽 임직원 건강검진 지원) — 가족 검진 지원 비율·한도 미기재 (파라다이스 · 파라다이스시티 · 호텔 부산 통합 보고 기준)', 20),
  (@comp_id, 'fitness', '사내 피트니스', NULL, 'health',
   'est', NULL, TRUE, '무인 피트니스 시설 24시 운영 (2025 지속가능경영보고서 50쪽 복리후생 프로그램 사내 피트니스 항목) — 설치 사업장·이용 비용 미기재 (파라다이스 · 파라다이스시티 · 호텔 부산 통합 보고 기준)', 21),
  (@comp_id, 'mental', '심리 상담 서비스', NULL, 'health',
   'est', NULL, TRUE, '임직원의 스트레스 관리와 정신건강 증진을 지원하는 온·오프라인 심리 상담 서비스 운영, 감정노동 직무 종사자 대상으로 사내 전문 자격(심리상담사 1급) 보유 매니저를 배치한 상시 상담 체계 (2025 지속가능경영보고서 57쪽 임직원 심리 상담 프로그램) — 이용 횟수·가족 이용 여부 미기재 (파라다이스 · 파라다이스시티 · 호텔 부산 통합 보고 기준)', 22),

  -- ── 가족 (family) — 50쪽 표 ──
  (@comp_id, 'parenting', '자녀 보육수당', NULL, 'family',
   'est', NULL, TRUE, '정부보육지원 기준에 의거, 직장어린이집 위수탁계약을 맺은 기관을 통한 50% 보육료 지원 (2025 지속가능경영보고서 50쪽 복리후생 프로그램 자녀 보육수당 항목) — 위탁 기관 위치·대상 자녀 연령 미기재 (파라다이스 · 파라다이스시티 · 호텔 부산 통합 보고 기준)', 30),

  -- ── 휴가 (time_off) — 50쪽 기타 ──
  (@comp_id, 'long_service_leave', '장기근속 포상 및 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '근속기간(5년/10년/15년/20년/25년/30년)별 포상금 차등 지급, Refresh 휴가 부여 (2025 지속가능경영보고서 50쪽 기타 장기근속 포상 및 휴가 항목) — 포상금 액수·휴가 일수 미기재 (파라다이스 · 파라다이스시티 · 호텔 부산 통합 보고 기준)', 40),

  -- ── 생활 편의 (perks) — 50쪽 기타 ──
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '설, 추석 각각 복지포인트 연 2회 지급 (2025 지속가능경영보고서 50쪽 기타 복지포인트 항목) — 지급 포인트 액수·사용처 미기재 (파라다이스 · 파라다이스시티 · 호텔 부산 통합 보고 기준)', 50),
  (@comp_id, 'housing_support', '임차료 지원금', NULL, 'perks',
   'est', NULL, TRUE, '월 최대 30만원 지급(월세 금액의 100% 지원), 네이버 지도 상 「자동차 거리우선」 최단거리 45km 이상 지역 거주자 대상 (2025 지속가능경영보고서 50쪽 기타 임차료 지원금 항목) — 적용 사업장·지원 기간 미기재 (파라다이스 · 파라다이스시티 · 호텔 부산 통합 보고 기준)', 51),
  (@comp_id, 'discount', '계열 시설 할인', NULL, 'perks',
   'est', NULL, TRUE, '임직원 대상 내부시설(객실, F&B, 원더박스, 씨메르 등) 할인 혜택 제공 (2025 지속가능경영보고서 50쪽 기타 내부시설 할인 항목) — 할인율·이용 한도 미기재 (파라다이스 · 파라다이스시티 · 호텔 부산 통합 보고 기준)', 52),

  -- ── 근무 환경 (work_env) — 50쪽 기타 ──
  (@comp_id, 'dormitory', '기숙사 및 관리비 지원', NULL, 'work_env',
   'est', NULL, TRUE, '기숙사 2인 1실 제공, 관리비 일부 지원 (2025 지속가능경영보고서 50쪽 기타 기숙사 및 관리비 지원 항목) — 기숙사 위치·입주 대상 미기재 (파라다이스 · 파라다이스시티 · 호텔 부산 통합 보고 기준)', 60),

  -- ── 여가 (leisure) — 48쪽 · 52쪽 ──
  (@comp_id, 'library', '전자도서관·사내도서관', NULL, 'leisure',
   'est', NULL, TRUE, '독서경영 프로그램의 독서 인프라로 전자도서관 운영(월 평균 390여 권 대출), 사내도서관 운영(월 평균 약 130여 권 대출) (2025 지속가능경영보고서 48쪽 독서경영 프로그램 표) — 사내도서관 위치·이용 대상 미기재 (파라다이스 · 파라다이스시티 · 호텔 부산 통합 보고 기준)', 70),
  (@comp_id, 'company_event', '가족초청행사 Your Paradise', NULL, 'leisure',
   'est', NULL, TRUE, '임직원 가족을 초청하는 Your Paradise 행사 2025년 5월과 6월 총 2회 개최, 파라다이스시티 주요 공간 견학·외국인 전용 카지노 견학·호텔 투숙과 레스토랑 석·조식 제공 (2025 지속가능경영보고서 52쪽 가족초청행사) — 참가 대상 선정 방식·정기 개최 여부 미기재 (파라다이스 · 파라다이스시티 · 호텔 부산 통합 보고 기준)', 71),

  -- ── 성장 (growth) — 48쪽 · 49쪽 ──
  (@comp_id, 'mba', '대학원 학위 취득 지원제도', NULL, 'growth',
   'est', NULL, TRUE, '자사 업무와 연계된 석사과정 학위 취득 지원, 엄격한 심사 과정을 통해 선발된 임직원에게 입학금 및 등록금 등 학업에 필요한 비용 지원 (2025 지속가능경영보고서 49쪽 임직원 학위 및 자격증 취득 지원) — 선발 인원·지원 한도·의무 근무 기간 미기재 (파라다이스 · 파라다이스시티 · 호텔 부산 통합 보고 기준)', 80),
  (@comp_id, 'edu_support', '온라인 학습 플랫폼 파라人SIGHT·독서 소모임 파라북클럽', NULL, 'growth',
   'est', NULL, TRUE, '전 임직원이 시간과 장소의 제약 없이 학습할 수 있는 자기주도형 상시학습 온라인 플랫폼 파라人SIGHT 운영, 사내 콘텐츠 약 320편 제공 (2025 지속가능경영보고서 48쪽 인재 육성 프로그램), 구성원 간 독서 기반 소통 강화 및 토론 역량 향상을 위한 독서 소모임 파라북클럽 운영, 2025년 132명·23개 소모임 (48쪽 독서경영 프로그램 표) — 활동비 지원 여부·참여 조건 미기재 (파라다이스 · 파라다이스시티 · 호텔 부산 통합 보고 기준)', 81),

  -- ── 보상 (compensation) — 49쪽 · 104쪽 ──
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '직원 연봉에 기본급과 함께 성과급 포함 (2025 지속가능경영보고서 99쪽 남성 대비 여성 연봉(기본급+성과급) 비율 표·104쪽 직원 급여(기본급+성과급) 중간값 표), 보상 수준은 경영계획에 기반한 목표 달성도 등을 기준으로 결정, 특히 연초에 설정한 영업이익 목표 대비 달성 성과를 핵심 기준으로 적용, 평가 기반 차등 보상 (49쪽 성과 보상 제도) — 지급률·지급 시기 미기재 (파라다이스 · 파라다이스시티 · 호텔 부산 통합 보고 기준)', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
