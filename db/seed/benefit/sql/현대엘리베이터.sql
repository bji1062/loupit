-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 현대엘리베이터 복리후생 데이터 (신규 회사 — 웨이브 7)
-- 출처: AI 파싱 (2026-10-14)
-- URL: https://www.hyundaielevator.co.kr/upload/ESG/2025-26%EB%85%84%20%ED%98%84%EB%8C%80%EC%97%98%EB%A6%AC%EB%B2%A0%EC%9D%B4%ED%84%B0%20ESG%20%EB%B3%B4%EA%B3%A0%EC%84%9C.pdf
-- badge: est
--
-- 참고:
--   정본은 상장 법인 현대엘리베이터(주) 자기 도메인 www.hyundaielevator.co.kr 헤더 메뉴 ESG > 자료실 > ESG 보고서 목록 페이지다.
--   목록 맨 위 판 = 법인 단독 발행 2025-26년 현대엘리베이터 ESG 보고서 PDF(/upload/ESG/ 아래 · 등록 2026-06-30 ·
--   보고 기간 2025-01-01~2025-12-31 일부 2026 상반기 · 비재무 보고 범위 별도 법인 현대엘리베이터 국내 사업장).
--   근거 쪽: 43 · 46(엘리스 카페) · 48(직무 CoP) · 49(MBA) · 51(근무환경 · 가족친화 제도 표 · 가족친화 프로그램) ·
--   52(자녀 학자금 · 출산 장려 · 임직원 근로 복지 프로그램 표 · 건강 의료 · 심리상담) · 53(장기근속 포상 · 리프레쉬 · 개인연금) ·
--   68(종합검진 플랫폼) · 78(유급 봉사휴가).
--   보조: 같은 도메인 ESG > 안전경영 페이지(Angular SPA · 본문은 /static/app/8.chunk.js 템플릿) 건강 관리 · 임직원 건강 증진 문단,
--   OpenDART 2026 반기보고서(접수 20260814003691) 직원 등 현황 유연근무제도 사용 현황 표(원격근무제 재택근무 포함).
--   렌더: 사이트는 Angular SPA. 목록은 키 없는 GET /api/esg/report/top 으로 PDF 경로를 얻었고 PDF 텍스트 추출 + 51 · 52쪽 그림 대조.
--   인사복지제도 메뉴(/ko/company/recruit/welfare)는 앱 라우터가 /ko/index 로 돌려보내 본문이 없다.
--   귀속: 보고서 주어가 현대엘리베이터는 으로 법인 단수 · 자기 발행이라 각주 없음. 현대그룹 채용 사이트(careers.hyundaigroup.com)는
--     직원 인터뷰 · 블로그뿐이라 근거로 쓰지 않았다. 기등록 형제 현대무벡스와 문장 겹침 없음.
--   금액: 전 행 NULL — 원문 숫자는 한도(위탁 보육료 최대 월 27만원) · 1회성(출산 축하금) · 조건부(유치원 비용 월 10만원) · 비율(개인연금 50%)뿐.
--   제외: 법정(출산휴가 90일 · 배우자 출산휴가 20일 · 태아검진휴가 · 유산 사산휴가 · 난임휴가 6일 중 2일 유급 · 가족돌봄휴가 ·
--     임신기 육아기 근로시간 단축 · 연장근로 가산수당 · 휴가 사용 촉진과 미사용 수당 · 퇴직연금 DB DC ·
--     정년 퇴직 예정자 진로설계 재취업 교육 — 직원 2,867명) · 업무 교육(온보딩 · 직무별 교육 · 핵심인재 DC 과정 · 사내강사 · IDP) ·
--     임원 보수 칸 복리후생 기준 · 사내벤처 · 봉사활동비와 시간별 보상 · CSR 표의 사내동호회 친선경기.
--   공고 근거 0행 / 전체 25행.
--   SORT 섹션 순서 = 보고서 등장 순(perks 10 · growth 20 · flexibility 30 · work_env 40 · family 50 · health 60 ·
--     leisure 70 · time_off 80 · compensation 90).
-- 검증 · 감사 판정 반영(2026-10-14): 정본 URL 을 2025-26 ESG 보고서 PDF 직접 주소로 교체(리드 판정 119) · 111쪽 사내 공개 교육 과정을 직무 CoP 행에 병합 — 최종 27행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hyundai_elevator', '현대엘리베이터',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '산업기계', 'H', 'https://www.hyundaielevator.co.kr/upload/ESG/2025-26%EB%85%84%20%ED%98%84%EB%8C%80%EC%97%98%EB%A6%AC%EB%B2%A0%EC%9D%B4%ED%84%B0%20ESG%20%EB%B3%B4%EA%B3%A0%EC%84%9C.pdf');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_elevator');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.hyundaielevator.co.kr/upload/ESG/2025-26%EB%85%84%20%ED%98%84%EB%8C%80%EC%97%98%EB%A6%AC%EB%B2%A0%EC%9D%B4%ED%84%B0%20ESG%20%EB%B3%B4%EA%B3%A0%EC%84%9C.pdf'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 생활 · 금융 · 주거 (perks) — 2025-26 ESG 보고서 43 · 46 · 52 · 53쪽 ──
  (@comp_id, 'snack_bar', '사내 복지 카페 (엘리스 카페)', NULL, 'perks',
   'est', NULL, TRUE, '충주 스마트캠퍼스 내 장애인을 고용한 사내 복지 카페 엘리스 카페 운영 (2025-26 ESG 보고서 43쪽 다양성 및 포용 강화 항목), 2025년 1월 사내 장애인 바리스타 카페 신설 (같은 보고서 46쪽 다양성 및 포용 목표 항목) — 이용 비용·운영 시간 미기재', 10),
  (@comp_id, 'housing_loan', '주택구입·임차자금 대출', NULL, 'perks',
   'est', NULL, TRUE, '사내근로복지기금 주택구입·임차자금 대출 지원 (연 2회 : 5월, 11월), 시중 대비 저금리 지원 (2025-26 ESG 보고서 52쪽 임직원 근로 복지 프로그램 사내근로복지기금 항목) — 대출 한도·이율 미기재', 11),
  (@comp_id, 'welfare_fund', '사내근로복지기금 생활안정자금', NULL, 'perks',
   'est', NULL, TRUE, '사내근로복지기금 생활 안정 지원, 생활안정자금 정기 운영 (짝수달), 시중 대비 저금리 지원 (2025-26 ESG 보고서 52쪽 임직원 근로 복지 프로그램 사내근로복지기금 항목) — 지원 방식·한도 미기재', 12),
  (@comp_id, 'relocation', '임직원 정착지원금', NULL, 'perks',
   'est', NULL, TRUE, '임직원 정착지원금 운영 (2025-26 ESG 보고서 52쪽 임직원 근로 복지 프로그램 생활지원 인프라 운영 항목) — 지급 대상·지급액 미기재', 13),
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '온·오프라인 복지포인트 사용 지원, 문화·여가·자기개발 분야 활용 가능, 복지포인트 지급 확대 및 사용처 다양화 (2025-26 ESG 보고서 52쪽 임직원 근로 복지 프로그램 복지포인트 제도 운영 항목) — 연간 지급액 미기재', 14),
  (@comp_id, 'birthday_gift', '생일 기념 포인트', NULL, 'perks',
   'est', NULL, TRUE, '생일 기념 포인트 지급 (2025-26 ESG 보고서 52쪽 임직원 근로 복지 프로그램 복지포인트 제도 운영 항목) — 지급 포인트 미기재', 15),
  (@comp_id, 'pension_support', '개인연금 지원', NULL, 'perks',
   'est', NULL, TRUE, '당사 연계 개인연금 가입 시 납입액의 50% 보조 (2025-26 ESG 보고서 53쪽 은퇴 전환 지원 및 노후 보장 제도 운영 항목) — 지원 한도 미기재', 16),

  -- ── 성장 · 교육 (growth) — 2025-26 ESG 보고서 48 · 49쪽 ──
  (@comp_id, 'edu_support', '직무 CoP 학습 프로그램·사내 공개 교육 과정', NULL, 'growth',
   'est', NULL, TRUE, '구성원의 자발적 참여를 기반으로 한 팀 기반 학습 프로그램 직무 CoP 운영, 고객경험·미래사업·자유주제 3개 Track, 매월 직무 CoP Day 운영 (2025-26 ESG 보고서 48쪽 직무 CoP를 통한 팀 기반의 학습 프로그램 항목), 임직원의 학습 기회 확대와 공통/직무 역량 강화를 위한 온·오프라인 교육 과정, 공개된 강좌를 자율적으로 입과 신청하는 방식의 사내 공개 교육 (같은 보고서 111쪽 임직원 교육 현황 표 사내 공개 항목) — 활동비 지원 여부·공개 과정 목록 미기재', 20),
  (@comp_id, 'mba', '국내외 MBA 지원 프로그램', NULL, 'growth',
   'est', NULL, TRUE, '핵심인재 육성을 위한 국내외 MBA 지원 프로그램 운영 (2025-26 ESG 보고서 49쪽 핵심인재 육성 항목), 국내/외 학위과정 (같은 보고서 49쪽 인적자원 개발 프로그램 체계 항목) — 선발 기준·지원 범위 미기재', 21),

  -- ── 근무 유연성 (flexibility) — 2025-26 ESG 보고서 51쪽 · 2026 반기보고서 ──
  (@comp_id, 'remote_work', '리모트워크 제도', NULL, 'flexibility',
   'est', NULL, TRUE, '리모트워크 제도 운영, 디지털 협업 환경을 기반으로 장소 제약 없이 업무 수행 (2025-26 ESG 보고서 51쪽 유연근무 기반 스마트워크 항목), 원격근무제(재택근무 포함) 도입, 당기 반기 사용자 1,473명 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 사용 횟수·대상 직무 미기재', 30),
  (@comp_id, 'satellite_office', '거점형 공유오피스', NULL, 'flexibility',
   'est', NULL, TRUE, '리모트워크의 실효성 제고를 위해 2023년부터 거점형 공유오피스 운영, 2025년 수도권과 주요 광역도시로 운영 범위 확대 (2025-26 ESG 보고서 51쪽 거점형 공유오피스 운영 확대 항목) — 이용 조건 미기재', 31),

  -- ── 근무환경 (work_env) — 2025-26 ESG 보고서 51 · 52쪽 ──
  (@comp_id, 'smart_office', '복합 업무 공간 H-HUB', NULL, 'work_env',
   'est', NULL, TRUE, '2025년 하반기 휴게·회의 기능을 결합한 복합 업무 공간 H-HUB 조성 (2025-26 ESG 보고서 51쪽 업무 몰입도 제고를 위한 공간 리뉴얼 항목) — 설치 사업장 미기재', 40),
  (@comp_id, 'nap_room', '모성보호실·모유 수유실', NULL, 'work_env',
   'est', NULL, TRUE, '여성 근로자 대상 모유 수유실 운영, 임신·출산기 임직원의 휴식 및 건강관리를 위한 전용 공간 (2025-26 ESG 보고서 51쪽 가족친화 제도 구성 항목), 여성 임직원을 위한 모성보호실 조성 (같은 보고서 51쪽 업무 몰입도 제고를 위한 공간 리뉴얼 항목) — 설치 사업장 미기재', 41),
  (@comp_id, 'dormitory', '기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '기숙사 운영을 통한 임직원 주거 편의 지원 (2025-26 ESG 보고서 52쪽 임직원 근로 복지 프로그램 생활지원 인프라 운영 항목) — 입주 대상·비용 미기재', 42),

  -- ── 가족 (family) — 2025-26 ESG 보고서 51 · 52쪽 ──
  (@comp_id, 'parenting', '출산 축하금·자녀 입학 축하·위탁 보육료 지원', NULL, 'family',
   'est', NULL, TRUE, '다자녀 출산 시 출산 축하금 첫째 100만원 기준 자녀 수별 100만원씩 증가, 임신 시 축하 포인트 지급, 유치원·초등학교·중학교 입학 선물, 중·고등학교 자녀 입학 시 축하포인트 지급 (2025-26 ESG 보고서 52쪽 자녀 학자금 및 출산 장려 지원 제도 항목), 어린이집 위탁 보육료 지원 제도, 자녀가 있는 충주 근로자 중 만 5세 이하 자녀를 둔 근로자 대상 최대 월 27만원 (같은 보고서 51쪽 가족친화 제도 구성 항목) — 축하 포인트 금액 미기재', 50),
  (@comp_id, 'child_edu', '자녀 학자금', NULL, 'family',
   'est', NULL, TRUE, '미취학 자녀 유치원 비용 취학 2년 전 월 10만원 지원, 중·고등학교 자녀 입학금 수업료 및 학교운영 지원비, 대학생 자녀 입학금 및 등록금 (2025-26 ESG 보고서 52쪽 자녀 학자금 및 출산 장려 지원 제도 항목), 2026년부터 자녀 학자금 지원의 근속 제한 규정 폐지 (같은 보고서 52쪽 자녀 학자금 및 출산 축하금 지원 항목) — 지원 한도·자녀 수 제한 미기재', 51),

  -- ── 건강 (health) — 2025-26 ESG 보고서 51 · 52 · 68쪽 · 공식 홈페이지 ESG 안전경영 ──
  (@comp_id, 'clinic', '사내 의무실', NULL, 'health',
   'est', NULL, TRUE, '전체 근로자 대상 사내 의무실 운영을 통한 근로자 건강관리 지원 (2025-26 ESG 보고서 51쪽 가족친화 제도 구성 항목) — 설치 사업장·상주 인력 미기재', 60),
  (@comp_id, 'mental', '심리상담 프로그램', NULL, 'health',
   'est', NULL, TRUE, '임직원 본인, 배우자 및 직계가족 대상 연간 1인당 최대 7회 상담 지원, 대면/비대면 상담, Keapa 한국EAP협회/서울심리상담센터 등 전문 심리 상담기관 및 지역 심리상담센터 연계 운영 (2025-26 ESG 보고서 52쪽 심리상담 프로그램 운영 항목), 마음챙김 프로그램 운영 (같은 보고서 52쪽 임직원 근로 복지 프로그램 생활지원 인프라 운영 항목) — 상담 비용 부담 방식 미기재', 61),
  (@comp_id, 'fitness', '체력증진 프로그램·헬스장', NULL, 'health',
   'est', NULL, TRUE, '체력증진 프로그램 운영 (2025-26 ESG 보고서 52쪽 임직원 근로 복지 프로그램 생활지원 인프라 운영 항목), 헬스장 운영 (공식 홈페이지 ESG 안전경영 임직원 건강 증진 항목) — 설치 사업장·이용 비용 미기재', 62),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '임직원·배우자 (또는 직계가족 1인)·부양가족 의료비 지원 (2025-26 ESG 보고서 52쪽 건강·의료 지원 프로그램 항목) — 지원 한도·본인 부담률 미기재', 63),
  (@comp_id, 'health_check', '건강검진', NULL, 'health',
   'est', NULL, TRUE, '임직원 및 배우자 (또는 직계가족 1인) 건강검진 지원 (2025-26 ESG 보고서 52쪽 건강·의료 지원 프로그램 항목), 검진기관 13개에서 67개로 확대, 플랫폼 기반 예약 서비스, 검진 후 맞춤형 건강정보 제공 및 사후관리 (같은 보고서 68쪽 종합검진 플랫폼 도입 항목), 건강검진 전용 모바일 플랫폼과 AI 분석 기반 사후관리 서비스 (공식 홈페이지 ESG 안전경영 건강 관리 항목) — 검진 주기·비용 지원 범위 미기재', 64),
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '임직원 대상 단체상해보험 (2025-26 ESG 보고서 52쪽 건강·의료 지원 프로그램 항목) — 보장 내용·보험료 부담 미기재', 65),

  -- ── 여가 · 행사 (leisure) — 2025-26 ESG 보고서 51쪽 ──
  (@comp_id, 'company_event', 'H-Family Day·가족 초청 행사', NULL, 'leisure',
   'est', NULL, TRUE, '임직원과 가족이 함께 소통하고 교류하는 참여형 문화행사 H-Family Day 지속 추진 (2025년 하반기 10월 중 2회), 부모 초청 행사 H-Parents’ Day와 자녀 초청 행사 H-Kids’ Day 각 1회 운영 (2025-26 ESG 보고서 51쪽 가족친화 프로그램 항목) — 참가 대상·비용 지원 미기재', 70),

  -- ── 휴가 (time_off) — 2025-26 ESG 보고서 52 · 53 · 78쪽 ──
  (@comp_id, 'refresh_leave', '리프레쉬 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '리프레쉬휴가 운영 (상·하반기 각 1회, 최대 7일) (2025-26 ESG 보고서 52쪽 임직원 근로 복지 프로그램 재충전 기회 부여 항목), 상·하반기 각 1회 리프레쉬 휴가 (같은 보고서 53쪽 근로시간 관리 및 일·생활 균형 지원 항목) — 유급 여부·부여 조건 미기재', 80),
  (@comp_id, 'leave_general', '2시간 단위 휴가·유급 봉사휴가', NULL, 'time_off',
   'est', NULL, TRUE, '2시간 단위 휴가 제도 전 직원 확대 (2025-26 ESG 보고서 52쪽 임직원 근로 복지 프로그램 재충전 기회 부여 항목), 봉사활동 인센티브 제도의 유급 봉사휴가 제공 (같은 보고서 78쪽 임직원 참여 공헌활동 항목) — 봉사휴가 일수·부여 기준 미기재', 81),
  (@comp_id, 'long_service_leave', '장기근속 포상', NULL, 'time_off',
   'est', NULL, TRUE, '근속 연수 (5년~35년)에 따라 포상금, 순금 메달 (또는 기념품), 유급 휴가 및 휴가비 차등 지급 (2025-26 ESG 보고서 53쪽 장기근속 포상 및 장기 인센티브 제도 항목) — 근속 구간별 휴가 일수·포상금액 미기재', 82),

  -- ── 보상 · 금전 (compensation) — 2025-26 ESG 보고서 52쪽 ──
  (@comp_id, 'holiday_gift', '명절·근로자의 날 기념 포인트', NULL, 'compensation',
   'est', NULL, TRUE, '명절, 근로자의 날 기념 포인트 지급 (2025-26 ESG 보고서 52쪽 임직원 근로 복지 프로그램 복지포인트 제도 운영 항목) — 지급 포인트 미기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
