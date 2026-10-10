-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 한국콜마 복리후생 데이터 (신규 회사 — 웨이브 5)
-- 출처: AI 파싱 (2026-10-10)
-- URL: https://www.kolmar.co.kr/img/esg/2025_sustainability_report_kor_2.pdf
-- badge: est
--
-- 참고:
--   정본 = 한국콜마(주) 자기 도메인 2025 지속가능경영보고서 PDF(리드 판정 W5-8). 참고 = 콜마그룹 통합 채용사이트 복리후생 페이지(kolmar.recruiter.co.kr/career/benefits, 콜마홀딩스 운영, 제목 복리후생 | 콜마그룹 채용) — 그룹 각주 19행의 근거.
--   본문은 벤더 데이터 호스트에서만 내려와(api-recruiter.recruiter.co.kr robots 전면 금지) 직접 받지 않았다.
--   사용자가 2026-10-10 브라우저로 열어 붙여 넣은 본문 사본이 근거다
--   (W5/kolmar/user_paste_2026-10-10.txt, sha256 cc3abe01…dcac4). 이 페이지 · 벤더 호스트 요청 0회.
--   귀속(리드 판정 W5-2 · 웨이브 4 프로브): 운영 주체 콜마홀딩스(주) · 법인 구분 없는 그룹 통합 채용 페이지 ·
--   기등록 콜마 계열 0 → 이 페이지를 근거로 쓴 행은 서술 끝에 (그룹 통합 채용 기준) 각주(19행).
--   보조 출처 = 한국콜마(주) 자기 도메인 발행 2025 지속가능경영보고서(2026-06-30 발행,
--   www.kolmar.co.kr/img/esg/2025_sustainability_report_kor_2.pdf) 38 · 97 · 98 · 99 · 100쪽.
--   보고 범위 = 별도 법인 기준 한국콜마 전 사업장(2쪽) → 법인 원문. 보고서에만 있는 8행은 그룹 각주를 달지 않았다
--   (계약 C-13 각주 쓰임 — 그룹 채용 사이트 근거에만). 리드 프롬프트의 전 행 각주와 다르다 — 근거표 판단 요청 1.
--   금액: 원문 원 단위 숫자는 출산 장려(첫째 1000만 · 둘째 1000만 · 셋째 2000만) 하나 — 1회성이라 금액 미등록.
--   구내식당은 끼니가 적히지 않아 NULL. 금액 행 0(stated 0 · 추정 0).
--   제외: 연차 · 반차(법정) · 비즈니스 캐주얼(대응 코드 없음 — 자율복장 선례) · 임신기 근로시간 단축 · 태아 검진 시간(법정) ·
--     생애설계 교육(재취업지원서비스 — 국내 임직원 1,384명) · 리더십 · AI · 입문 · 승진자 교육(업무 교육) ·
--     열린협의회 의안(시행 여부 미기재) · 장애인 체육대회 입상자 포상(1회성 격려) · 복직대상자 교육.
--   공고 근거 0행 / 전체 27행.
--   SORT 섹션 순서(정본에 처음 나온 순서): flexibility 10 · time_off 20 · leisure 30 · growth 40 · family 50 ·
--     health 60 · perks 70 · work_env 80 · compensation 90. 섹션 안은 정본 행 뒤에 보고서 전용 행.
-- 검증 · 감사 판정 반영(2026-10-10): 정본 URL 을 한국콜마 2025 지속가능경영보고서 PDF 로 교체(그룹 채용 페이지는 참고) · 품질 분임조 포상 excellence_award 추가 — 최종 28행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('kolmar_korea', '한국콜마',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '화장품', 'K', 'https://www.kolmar.co.kr/img/esg/2025_sustainability_report_kor_2.pdf');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kolmar_korea');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.kolmar.co.kr/img/esg/2025_sustainability_report_kor_2.pdf'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — 정본 PC-OFF시스템 · 시차출퇴근제 + 보고서 99쪽 ──
  (@comp_id, 'pc_off', 'PC-OFF시스템', NULL, 'flexibility',
   'est', NULL, TRUE, '정해진 근무시간을 준수하는 PC-OFF시스템 (콜마그룹 채용사이트 복리후생 PC-OFF시스템 항목), PC OFF 시스템 운영 (한국콜마 2025 지속가능경영보고서 99쪽 근무 환경 항목) — 차단 시각·예외 절차 미기재 (그룹 통합 채용 기준)', 10),
  (@comp_id, 'flex_work', '시차출퇴근제·선택근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '내가 원하는 시간에 출근하는 시차출퇴근제 (콜마그룹 채용사이트 복리후생 시차출퇴근제 항목), 시차출퇴근제·선택근무제 등 유연근무제 운영 (한국콜마 2025 지속가능경영보고서 99쪽 조직문화 관리 체계) — 출근 시간대 범위·적용 대상 미기재 (그룹 통합 채용 기준)', 11),

  -- ── 휴가 (time_off) — 정본 휴가 항목 + 보고서 100쪽 ──
  (@comp_id, 'leave_general', '2시간 단위 휴가·육아동료업무지원 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '2시간 단위 휴가를 눈치 보지 않고 자유롭게 사용 (콜마그룹 채용사이트 복리후생 휴가 항목), 휴직자로 인한 업무 공백을 분담하는 직원에게 육아동료업무지원 휴가 및 복지포인트 지급 (한국콜마 2025 지속가능경영보고서 100쪽 콜마육아동료업무지원제) — 휴가 일수·포인트 금액 미기재 (그룹 통합 채용 기준)', 20),

  -- ── 여가 (leisure) — 정본 사내 도서관 · 사내 동호회 지원 · 축하 선물 + 보고서 99 · 100쪽 ──
  (@comp_id, 'library', '사내 도서관·전자도서관·북카페', NULL, 'leisure',
   'est', NULL, TRUE, '전 사업장 도서관과 전자도서관 운영 (콜마그룹 채용사이트 복리후생 사내 도서관 항목), 사내 북카페 운영 (한국콜마 2025 지속가능경영보고서 99쪽 근무 환경 항목) — 보유 도서 규모·이용 시간 미기재 (그룹 통합 채용 기준)', 30),
  (@comp_id, 'club', '사내 동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '동료들과 함께 즐기는 사내 동호회 지원 (콜마그룹 채용사이트 복리후생 사내 동호회 지원 항목), 여성 풋살 동호회(KWFC) 사내 활동 지원 (한국콜마 2025 지속가능경영보고서 100쪽 다양성 강화 활동) — 활동비 금액·지원 기준 미기재 (그룹 통합 채용 기준)', 31),
  (@comp_id, 'welcome_kit', '웰컴키트', NULL, 'leisure',
   'est', NULL, TRUE, '웰컴키트 선물 (콜마그룹 채용사이트 복리후생 축하 선물 항목) — 구성 품목 미기재 (그룹 통합 채용 기준)', 32),
  (@comp_id, 'company_event', '패밀리데이', NULL, 'leisure',
   'est', NULL, TRUE, '임직원 가족을 초청하는 패밀리데이 개최, 사업장 투어·가족 운동회 등 체험 프로그램 운영 (한국콜마 2025 지속가능경영보고서 100쪽 패밀리데이 개최) — 개최 주기·참가 대상 미기재', 33),

  -- ── 성장·교육 (growth) — 정본 교육 지원 + 보고서 97 · 98쪽 ──
  (@comp_id, 'lang', '외국어 교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '본인 외국어 교육 지원 (콜마그룹 채용사이트 복리후생 교육 지원 항목), 수준별 비즈니스 영어 회화 과정 제공, AI 어학 구독 지원 (한국콜마 2025 지속가능경영보고서 97쪽 글로벌 역량 강화 교육) — 지원 한도·수강 대상 미기재 (그룹 통합 채용 기준)', 40),
  (@comp_id, 'edu_support', '온라인 교육 프로그램 HK E-Academy', NULL, 'growth',
   'est', NULL, TRUE, '외국어, 인문학, 교양 등 다양한 콘텐츠를 제공하는 온라인 교육 프로그램 E-아카데미(HK E-Academy) 운영 (한국콜마 2025 지속가능경영보고서 97쪽) — 수강 한도·비용 부담 미기재', 41),
  (@comp_id, 'mba', '석·박사 학위 지원금', NULL, 'growth',
   'est', NULL, TRUE, '석·박사 학위 지원 제도 운영, 2025년 임직원 12명을 선정하여 학위 취득을 위한 지원금 지급 (한국콜마 2025 지속가능경영보고서 98쪽 석박사 학위 지원금) — 선정 기준·지원 금액 미기재', 42),

  -- ── 가족·돌봄 (family) — 정본 교육 지원 · 경조사 지원 · 출산 장려 + 보고서 99 · 100쪽 ──
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 교육비 (유치원, 대학) 지원 (콜마그룹 채용사이트 복리후생 교육 지원 항목), 미취학자녀 학자금 지원, 고등학교/대학교 자녀 장학금 지원 (한국콜마 2025 지속가능경영보고서 99쪽 학자금 지원 항목) — 지원 한도·자녀 수 제한 미기재 (그룹 통합 채용 기준)', 50),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '임직원 본인과 가족 경조사에 경조금, 휴가, 용품 지원 (콜마그룹 채용사이트 복리후생 경조사 지원 항목), 결혼, 칠순, 장례 경조금 및 경조휴가 지원, 2025년 장례 휴가 대상 확대 (한국콜마 2025 지속가능경영보고서 99쪽 경조사 지원 항목) — 경조 구분별 금액·휴가 일수 미기재 (그룹 통합 채용 기준)', 51),
  (@comp_id, 'parenting', '출산 장려금·육아휴직 생활지원금', NULL, 'family',
   'est', NULL, TRUE, '출산 시 특별금 지급 (첫째 1000만, 둘째 1000만, 셋째 2000만) (콜마그룹 채용사이트 복리후생 출산 장려 항목), 첫째 자녀 1,000만 원, 둘째 자녀 1,000만 원, 셋째 자녀 2,000만 원 출산 장려금 (한국콜마 2025 지속가능경영보고서 99쪽), 출산휴가 100% 사용 후 5일 이내 육아휴직 개시 시 육아휴직 생활지원금 지급, 임산부 맞춤형 근무복 지원 (100쪽) — 생활지원금 금액·지급 기간 미기재 (그룹 통합 채용 기준)', 52),
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '사내 직장 어린이집 운영 (한국콜마 2025 지속가능경영보고서 99쪽 직장 어린이집 항목), 2025년 3월 직장 내 어린이집 개원 (100쪽) — 설치 사업장·정원·대상 연령 미기재', 53),

  -- ── 건강·의료 (health) — 정본 건강 관리 · 멘탈 케어 · 사내 복지공간 + 보고서 38 · 99쪽 ──
  (@comp_id, 'health_check', '건강검진', NULL, 'health',
   'est', NULL, TRUE, '매년 건강검진 지원 (콜마그룹 채용사이트 복리후생 건강 관리 항목), 연령과 생애주기에 맞춘 종합건강검진 추가 지원, 혈액 종합검진 제공 (한국콜마 2025 지속가능경영보고서 38쪽 임직원 건강검진 지원), 과장 이상 연 1회 종합건강검진 지원 (99쪽 건강검진 항목) — 검진 비용 지원 범위·가족 포함 여부 미기재 (그룹 통합 채용 기준)', 60),
  (@comp_id, 'mental', '비대면 심리상담', NULL, 'health',
   'est', NULL, TRUE, '비대면 심리상담 지원 (콜마그룹 채용사이트 복리후생 멘탈 케어 항목), 전문 상담사와의 비대면 상담이 가능한 멘탈케어 서비스 Trost 무료 제공 (한국콜마 2025 지속가능경영보고서 38쪽), 심리상담서비스 2026년 3분기 재도입 결정 (99쪽) — 연간 이용 횟수·가족 이용 여부 미기재 (그룹 통합 채용 기준)', 61),
  (@comp_id, 'fitness', '사내 피트니스', NULL, 'health',
   'est', NULL, TRUE, '사내 피트니스 운영 (콜마그룹 채용사이트 복리후생 사내 복지공간 항목), 사내 헬스장 무료 운영, 출퇴근 전후나 휴식 시간에 자유롭게 이용 (한국콜마 2025 지속가능경영보고서 38쪽 사내 헬스장 운영) — 설치 사업장 미기재 (그룹 통합 채용 기준)', 62),
  (@comp_id, 'clinic', '건강관리실', NULL, 'health',
   'est', NULL, TRUE, '사업장 내 건강관리실 운영, 구급 의약품 지원·휴식 공간·건강 상담과 응급조치 (한국콜마 2025 지속가능경영보고서 38쪽 건강 증진 프로그램 및 건강관리실 운영) — 운영 사업장·상주 의료 인력 미기재', 63),

  -- ── 생활·편의 (perks) — 정본 사내 복지공간 · 셔틀버스 · 임직원 할인판매 · 구내식당 + 보고서 99쪽 ──
  (@comp_id, 'snack_bar', '사내 카페', NULL, 'perks',
   'est', NULL, TRUE, '사내 카페 운영 (콜마그룹 채용사이트 복리후생 사내 복지공간 항목) — 운영 사업장·이용 요금 미기재 (그룹 통합 채용 기준)', 70),
  (@comp_id, 'commute_subsidy', '출근 셔틀버스 (일부 사업장)', NULL, 'perks',
   'est', NULL, TRUE, '출근 통근버스 운행, 일부 사업장에 한함 (콜마그룹 채용사이트 복리후생 셔틀버스 항목) — 운행 사업장·노선 미기재 (그룹 통합 채용 기준)', 71),
  (@comp_id, 'discount', '임직원 할인판매', NULL, 'perks',
   'est', NULL, TRUE, '화장품, 건강기능식품 할인판매 (콜마그룹 채용사이트 복리후생 임직원 할인판매 제공 항목) — 할인율·구매 한도 미기재 (그룹 통합 채용 기준)', 72),
  (@comp_id, 'meal', '구내식당', NULL, 'perks',
   'est', NULL, TRUE, '전 사업장 구내식당 운영 (콜마그룹 채용사이트 복리후생 구내식당 항목) — 제공 끼니·본인 부담 여부 미기재 (그룹 통합 채용 기준)', 73),
  (@comp_id, 'relocation', '이동·해외 발령자 주택자금 지원', NULL, 'perks',
   'est', NULL, TRUE, '이동 발령자 대상 주택자금, 해외 발령자 주택자금 지원 (한국콜마 2025 지속가능경영보고서 99쪽 주거 항목) — 지원 방식·금액 미기재', 74),
  (@comp_id, 'birthday_gift', '생일자 복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '생일자 복지포인트 지원 (한국콜마 2025 지속가능경영보고서 99쪽 여가 지원 복지포인트 지원 항목) — 포인트 금액 미기재', 75),

  -- ── 근무환경 (work_env) — 정본 사내 복지공간 + 보고서 99쪽 ──
  (@comp_id, 'lounge', '여성휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '여성휴게실 운영 (콜마그룹 채용사이트 복리후생 사내 복지공간 항목), 여성직원휴게실 운영 (한국콜마 2025 지속가능경영보고서 99쪽 근무 환경 항목) — 설치 사업장·이용 시간 미기재 (그룹 통합 채용 기준)', 80),

  -- ── 보상 (compensation) — 정본 축하 선물 + 보고서 99쪽 ──
  (@comp_id, 'holiday_gift', '창립기념 축하 선물', NULL, 'compensation',
   'est', NULL, TRUE, '창립기념축하 선물 (콜마그룹 채용사이트 복리후생 축하 선물 항목) — 선물 품목·금액 미기재 (그룹 통합 채용 기준)', 90),
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속자 시상 (한국콜마 2025 지속가능경영보고서 99쪽 기타 복지 지원 장기근속 포상 항목) — 근속 기준 연수·포상 내용 미기재', 91),
  (@comp_id, 'excellence_award', '품질 분임조 포상', NULL, 'compensation',
   'est', NULL, TRUE, '매년 품질 분임조 대회를 개최하여 공정 개선 우수 사례 발굴, 성과에 따른 포상 제도 연계 (한국콜마 2025 지속가능경영보고서 106쪽 품질 분임조 활동) — 포상 기준·포상 내용 미기재', 92)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
