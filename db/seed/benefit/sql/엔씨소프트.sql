-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 엔씨소프트 복리후생 데이터
-- 출처: AI 파싱 (2026-09-28)
-- URL: https://careers.ncsoft.com/nclife/benefits
-- badge: est
--
-- 참고:
--   정본은 자기 도메인 careers.ncsoft.com 의 엔씨생활 > 복지혜택 페이지(/nclife/benefits)다.
--   메뉴 링크 /apply/benefits 는 302 로 이 주소에 닿는다. SSR HTML 이라 헤드리스 렌더 불필요 —
--   섹션 8개(생활 안정 · 건강 관리 · 여가취미 · 이벤트 · 웰빙 공간 · 편의 시설 · 성장 · NC LIFE)에
--   항목 31개가 sec__content-item 으로 최초 HTML 에 들어 있고 HTML 주석 속 블록이 아니다.
--   robots.txt 는 404(HTML 본문) — 규칙 없음, 허용.
--   이 채용 사이트는 NC Company 채용(메타 키워드 NC AI · NC QA · NC IDS · 엔씨컴퍼니)이라 복지 페이지의
--   적용 법인이 적혀 있지 않다. 그래서 보조 출처로 상장 법인 자신의 지속가능경영보고서
--   NC ESG PLAYBOOK 2025(www.nc.com 지속가능경영 보고서 페이지의 국문 PDF, 88쪽, 2026-07 생성,
--   비재무성과 보고 범위 = 주식회사 엔씨 국내 사업장) 39~42쪽 · 46쪽을 대조했다.
--   보고서가 확인하지 못한 채용 페이지 단독 항목 5행(meal · snack_bar · event · club · conference)은
--   QUAL_DESC 말미에 NC Company 공통 채용 기준 각주를 달았다.
--   상장 법인의 사명은 이제 NC(주식회사 엔씨)다(보고서 표지 설명과 보고 범위의 주식회사 엔씨 표기). 회사 등록 값은 구본 그대로 둔다.
--   금액: 명시값 3행(welfare_point 300 · holiday_gift 60 · birthday_gift 10 — 보고서 복리후생 제도 표).
--     구본 추정치 meal 432 는 승계하지 않았다(원문에 3식 표기 없음 — NULL).
--   재코딩 1: leisure_ticket → sports_ticket(구단 경기 관람 지원).
--   제외: 법정 제도(출산 휴가 · 가족돌봄 휴직/휴가 · 난임치료 휴가 · 유사산 휴가 · 육아기 단축 · 육아 시간 ·
--     퇴직연금) · 회사 주도 교육(온보딩 · 리더십 · 직무 교육 — Learn+ 셀프스터디는 2026-10-04 규칙 8 개정으로 edu_support 행으로 되살림) · 임금 체계(비포괄 임금제 ·
--     시작연봉제 · 핵심인재 처우 · D-PI 조직 한정) · 우편실 · 자전거 미케닉샵(대응 어휘 없음).
--   SORT 섹션 순서 = 정본 페이지에서 카테고리가 처음 나온 순서
--     (perks 10 · family 20 · health 30 · leisure 40 · compensation 50 · time_off 60 · growth 70 ·
--      work_env 80 · flexibility 90).
-- 재수집(2026-09-28): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-09-28, RV-3 레인 3): 28행 전부 원문 재확인, 시드 수정 0 — 운영 표적 DELETE 722 remote_work · 732 transport, 재코딩 728 leisure_ticket → sports_ticket — 최종 28행
-- 후속 정리 2(2026-10-04, R-3): 사용자가 정한 복지 범위 규칙 개정(규칙 8 · 기준 13 · 기준 18 · 기준 20 · 기준 23)과 코퍼스 판정을 반영 — 새 행 1(edu_support) — 최종 29행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('ncsoft', '엔씨소프트(NC)',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '게임', 'N', 'https://careers.ncsoft.com/nclife/benefits');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'ncsoft');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://careers.ncsoft.com/nclife/benefits'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'housing_loan', '주택자금 대출 이자 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택자금대출 이자 지원(1억원까지 2.2% 지원)과 시중 금리보다 낮은 이자율의 생활안정자금 대출(최대 3천만원) (NC ESG PLAYBOOK 2025 복리후생 제도 대출지원 항목 · 공식 채용 페이지 복지혜택 주택 자금 지원 항목)', 10),
  (@comp_id, 'welfare_point', '복지카드 (연 300만원 복지포인트)', 300, 'perks',
   'est', '전 임직원 대상 연 300만원 복지포인트 지급, 자기계발·여행·문화생활 등 원하는 곳에서 쓰는 체크카드 (NC ESG PLAYBOOK 2025 복리후생 제도 복지카드 항목 · 공식 채용 페이지 복지혜택 복지카드 항목)', FALSE, NULL, 11),
  (@comp_id, 'birthday_gift', '생일선물 (상품권 10만원)', 10, 'perks',
   'est', '전 임직원 대상 생일선물 10만원 상품권 지급 (NC ESG PLAYBOOK 2025 복리후생 제도 생일선물 항목 · 공식 채용 페이지 복지혜택 명절/생일 항목)', FALSE, NULL, 12),
  (@comp_id, 'meal', '사내 푸드코트', NULL, 'perks',
   'est', NULL, TRUE, '사내 푸드코트 여섯 가지 코너에서 메뉴 선택 또는 테이크 아웃 메뉴 이용 (공식 채용 페이지 복지혜택 웰빙 공간 푸드코트 항목 — 식대·무료 여부·제공 끼니 미기재) (NC Company 공통 채용 기준)', 13),
  (@comp_id, 'snack_bar', '사내 카페', NULL, 'perks',
   'est', NULL, TRUE, '바리스타가 만든 다양한 음료를 사옥 안에서 이용하는 사내 카페 (공식 채용 페이지 복지혜택 웰빙 공간 카페 항목 — 가격·무료 여부 미기재) (NC Company 공통 채용 기준)', 14),
  (@comp_id, 'commute_subsidy', '출근버스 비용 지원', NULL, 'perks',
   'est', NULL, TRUE, '출근 셔틀버스(출근버스 플랫폼) 비용 일부 지원 (NC ESG PLAYBOOK 2025 복리후생 제도 기타 항목 · 공식 채용 페이지 복지혜택 편의 시설 통근 항목 — 지원 비율·노선 미기재)', 15),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'childcare', '사내 어린이집 웃는땅콩', NULL, 'family',
   'est', NULL, TRUE, '만 1세~5세 자녀를 둔 임직원 대상 사내 어린이집 웃는땅콩 운영, 사옥 내 2개 원에서 약 300명 영유아 보육 (NC ESG PLAYBOOK 2025 일·가정 양립 제도 사내 어린이집 · 공식 채용 페이지 복지혜택 어린이집 항목)', 20),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '결혼·출산과 회갑부터 구순까지 가족 경조사 지원, 장례 상조서비스 지원, 사옥 내 컨벤션홀을 사우 웨딩홀로 대관 (공식 채용 페이지 복지혜택 경조사·웨딩홀 대관 항목 — 경조금 금액·대관 비용 미기재) (NC Company 공통 채용 기준)', 21),
  (@comp_id, 'parenting', '육아휴직 연장·배우자 출산휴가 분할', NULL, 'family',
   'est', NULL, TRUE, '육아휴직 최대 2년 6개월, 배우자 출산휴가를 출산일로부터 1년 이내 1일 단위로 나눠 사용 (NC ESG PLAYBOOK 2025 일·가정 양립 및 모성보호 지원 제도 항목)', 22),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'fitness', '사내 피트니스·스파', NULL, 'health',
   'est', NULL, TRUE, '트레이너 도움을 받는 사내 피트니스, 개인 PT·GX룸·스크린골프장·실내체육관·스파(사우나 및 찜질방) 운영 (NC ESG PLAYBOOK 2025 복지시설 피트니스 항목 · 공식 채용 페이지 복지혜택 피트니스·스파 항목 — 이용료 미기재)', 30),
  (@comp_id, 'clinic', '사내 메디컬센터', NULL, 'health',
   'est', NULL, TRUE, '회사 안에서 간단한 건강관리와 치료, 자율신경기능 검사·스트레스 검사·진료처방·피부분석 등 건강관리 서비스 (NC ESG PLAYBOOK 2025 임직원 건강 증진 및 의료 지원 · 공식 채용 페이지 복지혜택 메디컬 센터 항목)', 31),
  (@comp_id, 'mental', '사내 심리상담실', NULL, 'health',
   'est', NULL, TRUE, '전문 상담사가 상주하는 심리상담실에서 직장생활·가정·개인 생활 고민 상담, 임직원 배우자와 자녀까지 지원 대상, 집단상담 프로그램 운영 (NC ESG PLAYBOOK 2025 심리상담실·집단상담 프로그램 항목 · 공식 채용 페이지 복지혜택 사내 상담실 항목)', 32),
  (@comp_id, 'health_check', '건강검진', NULL, 'health',
   'est', NULL, TRUE, '본인 검진 매년 지원, 검진 비용 가족 이관 지원(2년 주기), 40세 이상 뇌 MRA 검진 지원(5년 주기), 종합 검진 대상 유급 휴가 1일 (NC ESG PLAYBOOK 2025 임직원 건강 증진 및 의료 지원 건강검진 항목 · 공식 채용 페이지 복지혜택 건강검진 항목)', 33),
  (@comp_id, 'medical', '메디컬 플랜 (의료비 지원)', NULL, 'health',
   'est', NULL, TRUE, '임직원 본인과 배우자·자녀·부모의 입원·통원 치료 의료비를 보험으로 지원, 실손형과 정액형 중 보장 방식 선택 (NC ESG PLAYBOOK 2025 메디컬플랜 항목 · 공식 채용 페이지 복지혜택 메디컬 플랜 항목 — 보장 한도 미기재)', 34),
  (@comp_id, 'massage', '네일케어룸', NULL, 'health',
   'est', NULL, TRUE, '사내 네일케어룸에서 네일 기본 케어·젤 케어 서비스 (NC ESG PLAYBOOK 2025 복지시설 네일케어룸 항목 · 공식 채용 페이지 복지혜택 네일케어룸 항목 — 이용료 미기재)', 35),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '스포츠·취미를 공유하는 다양한 사내 동호회 운영 (공식 채용 페이지 복지혜택 여가취미 동호회 항목 — 활동비 지원 여부 미기재) (NC Company 공통 채용 기준)', 40),
  (@comp_id, 'resort', '리조트', NULL, 'leisure',
   'est', NULL, TRUE, '전국 40여곳 법인회원 리조트 객실을 회원 요금으로 예약, 숙박 예약 플랫폼 할인쿠폰 지원 (NC ESG PLAYBOOK 2025 복리후생 제도 휴양소 항목 · 공식 채용 페이지 복지혜택 리조트 항목)', 41),
  -- 재코딩 leisure_ticket → sports_ticket — 구단 경기 관람 지원(어휘표 sports_ticket 대표 명칭)
  (@comp_id, 'sports_ticket', 'NC DINOS 경기 관람 지원', NULL, 'leisure',
   'est', NULL, TRUE, '창원NC파크 NC DINOS 경기 티켓 할인과 SKYBOX 관람 지원 (NC ESG PLAYBOOK 2025 복리후생 제도 기타 항목 · 공식 채용 페이지 복지혜택 NC DINOS 항목 — 할인율 미기재)', 42),

  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'holiday_gift', '명절선물 (설·추석 상품권)', 60, 'compensation',
   'est', '전 임직원 대상 설/추석 각 30만원 상품권 지급 (NC ESG PLAYBOOK 2025 복리후생 제도 명절선물 항목 · 공식 채용 페이지 복지혜택 명절/생일 항목)', FALSE, NULL, 50),
  (@comp_id, 'incentive', 'PI (Performance Incentive)', NULL, 'compensation',
   'est', NULL, TRUE, '조직성과와 개인성과에 연동한 인센티브 연 1회 지급 (NC ESG PLAYBOOK 2025 보상 가변적 보상 제도 PI 항목 — 지급률 미기재)', 51),

  -- ── 휴가·휴식 (time_off) ──
  (@comp_id, 'long_service_leave', '장기근속 포상', NULL, 'time_off',
   'est', NULL, TRUE, '5년·15년·25년 근속 시 복지카드 100만원과 특별휴가 10일, 10년 근속 시 1,000만원 Refresh 카드와 휴가 10일, 20년·30년 근속 시 1,000만원 Refresh 카드·유급 안식월·특별 기념품 중 택 1과 특별휴가 10일 (NC ESG PLAYBOOK 2025 복리후생 제도 장기근속포상 항목 · 공식 채용 페이지 복지혜택 장기근속 항목)', 60),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'books', '라이브러리', NULL, 'growth',
   'est', NULL, TRUE, '전문·교양 서적과 만화책까지 40,000여 종 국내외 도서·정기 간행물·멀티미디어 대여, e-book 지원 (NC ESG PLAYBOOK 2025 복지시설 라이브러리 항목 · 공식 채용 페이지 복지혜택 라이브러리 항목)', 70),
  (@comp_id, 'conference', '외부교육·자격증 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '국내외 온/오프라인 교육·세미나 참석과 자격증 취득 지원 (공식 채용 페이지 복지혜택 성장 외부교육 항목 · NC ESG PLAYBOOK 2025 전문 자격증 지원 — 지원 한도 미기재) (NC Company 공통 채용 기준)', 71),
  (@comp_id, 'career', '사내공모 INCAREER', NULL, 'growth',
   'est', NULL, TRUE, '임직원이 사내공모에 지원해 NC 안에서 새로운 경력 개발과 직무 이동 기회 선택 (NC ESG PLAYBOOK 2025 내부 경력 개발 사내공모 INCAREER · 공식 채용 페이지 복지혜택 INCAREER 항목)', 72),
  (@comp_id, 'self_development', 'Post-Scholarship (학자금 대출 상환 지원)', NULL, 'growth',
   'est', NULL, TRUE, '대학·대학원 학자금 대출 상환을 최대 1,500만원까지 지원, 신입 정규직 입사자 중 경력 2년 미만 대상 (NC ESG PLAYBOOK 2025 복리후생 제도 Post-Scholarship 항목)', 73),
  (@comp_id, 'edu_support', 'Learn+ 셀프스터디', NULL, 'growth',
   'est', NULL, TRUE, '외부 교육 플랫폼과 연계해 임직원이 매월 필요한 역량 개발 과정을 자기주도적으로 선택·학습하는 Learn+ 셀프스터디 (NC ESG PLAYBOOK 2025 39쪽 교육 프로그램 항목 — 과정 범위·이용 한도 미기재)', 74),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'nap_room', '여성 휴게 공간', NULL, 'work_env',
   'est', NULL, TRUE, '모유 및 착유가 가능한 전용 공간을 갖춘 여성 휴게실 (NC ESG PLAYBOOK 2025 일·가정 양립 제도 여성 휴게실 · 공식 채용 페이지 복지혜택 휴게 공간 항목)', 80),
  (@comp_id, 'parking', '주차 지원', NULL, 'work_env',
   'est', NULL, TRUE, '근무지별 주차장과 사옥·인근 주차 지원, 임신 중이거나 사내 어린이집 원아를 둔 임직원 우선·정기 주차 (NC ESG PLAYBOOK 2025 복리후생 제도 기타·일·가정 양립 제도 주차 지원 · 공식 채용 페이지 복지혜택 주차장 항목 — 주차비 부담 미기재)', 81),

  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '선택적 근로시간제 (자율 유연 출퇴근)', NULL, 'flexibility',
   'est', NULL, TRUE, '코어타임과 최소 근로시간 없이 출퇴근하는 선택적 근로시간제(완전 자율 유연 출퇴근제) (NC ESG PLAYBOOK 2025 기준) — 공식 채용 페이지 유연 근무제 항목은 코어타임(10~15시) 운영과 그 외 시간 자율 선택으로 기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
