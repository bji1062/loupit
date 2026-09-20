-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 현대백화점 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-19)
-- URL: https://recruit.ehyundai.com/company-introduction/view.nhd?coCd=HDEHR
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 현대백화점그룹 통합 채용사이트의 **(주)현대백화점 법인 전용 회사소개 페이지**
--       한 곳뿐이다(coCd=HDEHR). 복리후생 탭은 같은 페이지 안의 div.for-flex.benefit-box 이고
--       Oracle WebLogic/JSP 서버렌더라 최초 HTML 에 항목 텍스트가 전량 들어 있다(헤드리스 불필요).
--       귀속 경로: 법인 자기 도메인 www.ehyundai.com → 그룹 포털 인재경영 > 인재채용 →
--       recruit.ehyundai.com → GNB 회사소개 → 채용중 현대백화점 → coCd=HDEHR.
--       같은 페이지가 법인을 직접 명시한다(h3 현대백화점 · 소재지 서울 강남구 테헤란로 98길 12 ·
--       설립일 1971년 6월 15일 · 사업영역 백화점, 아울렛, 복합쇼핑몰 · 홈페이지 www.ehyundai.com).
--       TLS 인증서 주체도 O=HYUNDAI DEPARTMENT STORE CO.,LTD / CN=*.ehyundai.com 라
--       채용 호스트가 법인 소유 도메인 위에 있다.
--       법인 전용 페이지라 「그룹 통합 채용 기준」 각주는 붙이지 않았다(삼성화재 선례와 동일).
--       형제 법인 3사 복리후생 블록을 이번 세션에서 직접 받아 대조한 결과, 카드 제목 뼈대만
--       공유하고 설명문(실제 제도)이 법인마다 달랐다 — 그룹 템플릿 공고 규칙에 해당하지 않는다.
--       (현대그린푸드 = 배우자 건강검진 확대·년 3회 귀향여비·10년 이상 5년마다 포상휴가 /
--        현대홈쇼핑 = 자녀학자금·사내 어린이집·사외위탁교육 / 한섬 = 카드 제목부터 전혀 다름.
--        셋 다 현대백화점 페이지에는 없는 항목이고, 현대백화점의 난임 수술 지원·초등학교 입학
--        자녀 선물·가사도우미·3주년 선물은 형제 3사 어디에도 없다. 블록 해시는 evidence 참조.)
--       ⚠ 그룹 공통 문서(채용 메인 「현대백화점그룹 복리후생」·그룹포털 GWP)의 복지포인트·
--          자녀 학자금·주택자금·휴가비·계열사 임직원 할인·기업대학·출산 전후 휴가 100일은
--          한 건도 섞지 않았다. 그 문서 스스로 「일부 복리후생 제도는 회사별로 상이할 수
--          있습니다」라고 면책을 달아 두었으므로 법인 카드로 옮기면 없는 제도를 만든다.
--          형제 법인 페이지의 학자금·어린이집·귀향여비도 같은 이유로 제외했다.
--       ⚠ 항목이 카드 제목이 아니라 설명문 속 나열이다. 카드 5장(가족/건강/Refresh/능력/여성)의
--          테마 문구는 제도명이 아니므로 설명문을 쉼표·등 기준으로 쪼개 제도 16개를 뽑았고,
--          한정어(만 8세 이하 자녀 · 한달 · 3주년 · 5, 10, 15, 20년)를 전부 보존했다.
--       16개 중 육아휴직 1건은 법정이라 수록하지 않았고 다른 행의 서술에도 쓰지 않았다
--          (원문이 법정 상회분을 밝히지 않는다 — 그냥 육아휴직 및 임산부 케어 프로그램 운영).
--          난임 항목은 난임휴가가 아니라 수술 비용 지원이라 회사 제도로 수록했다.
--       병합 1건: 초등학교 입학 자녀 선물과 임산부 케어 프로그램이 같은 parenting 으로 귀결돼
--          한 행에 담고 서술에 양쪽을 적었다(BENEFIT_CD 는 회사당 UNIQUE).
--          3주년 선물과 5, 10, 15, 20년 근속 포상도 같은 근속 연동 포상이라 long_service_bonus
--          한 행이다. 16개 - 법정 1 - 병합 2 = **15행**.
--       ⚠ 신규 코드 2개(housekeeping · home_security) — 어휘표 87종에 대응 어휘가 없다.
--          사유와 대안은 evidence 의 「신규 코드」 절 참조.
--       금액: 페이지에 원 단위 금액이 0건이다. 정량 표현은 만 8세 이하·한달·3주년·
--          5, 10, 15, 20년뿐이고 이는 금액이 아니다. → 15행 전부 BENEFIT_AMT NULL ·
--          QUAL_YN TRUE. 신규 회사라 승계할 앵커도 없어 타사 금액을 끌어오지 않았다.
--       ⚠ 재수집 시 변경 감지는 페이지 전체 해시로 하면 안 된다 — CSRF 토큰 1줄과 JS
--          캐시버스터 타임스탬프 때문에 매 요청 달라진다. div.for-flex.benefit-box 블록만
--          잘라 해시할 것(실측 4,015B, 2회 요청 SHA-256 동일).
--       ⚠ 없는 coCd 는 HTTP 200 + 461B soft-404 다(본문이 alert 한 줄). 상태코드로 성공을
--          판정하면 안 되고, h3.f80b.tit 값이 현대백화점인지로 법인 검증을 넣을 것.
--       ⚠ recruit.ehyundai.com robots 의 금지 경로는 /job-introduction/cntn.nhd 하나다.
--          복리후생은 AJAX 를 쓰지 않으므로 coCd 직접 호출만 하고 링크 추종은 끌 것.
--       ⚠ INDUSTRY_NM 유통 은 이번 웨이브 신규 값이다(코퍼스 기존 값은 화장품유통 2 ·
--          커머스/홈쇼핑 1 · 식품/유통/엔터 1 뿐이고 백화점·종합유통 축이 없다).
--          리드 지시로 이마트와 같은 값을 쓴다 — 다른 표기를 만들지 말 것.
--       ⚠ 검증·감사 판정 반영(2026-09-19): 15 → 14행. SORT 22 가사도우미(housekeeping 제안)를 SORT 21
--       parenting 에 병합했다 — 대상이 만 8세 이하 자녀를 둔 근로자라 대응 어휘가 이미 있다.
--       SORT 80 home_security 는 신규 코드로 채택되어 카테고리 perks 그대로 둔다.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hyundai_dept', '현대백화점',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '유통', 'H', 'https://recruit.ehyundai.com/company-introduction/view.nhd?coCd=HDEHR');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_dept');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://recruit.ehyundai.com/company-introduction/view.nhd?coCd=HDEHR'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) ── 카드1 가족까지 행복한 회사
  (@comp_id, 'pc_off', 'PC OFF 제도', NULL, 'flexibility',
   'est', NULL, TRUE, '유통업계 최초 pc off 제도 도입 (공식 채용 페이지 복리후생 「가족까지 행복한 회사」 항목 — 차단 시각·적용 대상 미기재)', 10),

  -- ── 가족·돌봄 (family) ── 카드1 가족까지 행복한 회사 / 카드5 여성이 근무하기 좋은 회사
  (@comp_id, 'fertility_support', '난임 수술 지원', NULL, 'family',
   'est', NULL, TRUE, '난임 직원 수술 지원 (공식 채용 페이지 복리후생 「가족까지 행복한 회사」 항목 — 지원 항목·한도·횟수 미기재)', 20),
  (@comp_id, 'parenting', '입학 자녀 선물·임산부 케어', NULL, 'family',
   'est', NULL, TRUE, '초등학교 입학 자녀 선물 등 가족 care 제도와 임산부 케어 프로그램 운영, 만 8세 이하 자녀를 둔 근로자 대상 가사도우미 지원 (공식 채용 페이지 복리후생 항목 — 선물 품목·금액·케어 프로그램 내용·가사도우미 이용 횟수·시간·본인 부담 미기재)', 21),

  -- ── 건강·의료 (health) ── 카드2 직원들의 건강을 책임지는 회사
  (@comp_id, 'mental', 'EAP 종합 컨설팅', NULL, 'health',
   'est', NULL, TRUE, '스트레스 관리, 재무 설계, 법적 상담 등 다양한 이슈에 대한 종합 컨설팅 서비스 EAP 운영 (공식 채용 페이지 복리후생 「직원들의 건강을 책임지는 회사」 항목 — 상담 횟수·가족 이용 가능 여부 미기재)', 30),
  (@comp_id, 'insurance', '단체보험', NULL, 'health',
   'est', NULL, TRUE, '단체보험 시행 (공식 채용 페이지 복리후생 「직원들의 건강을 책임지는 회사」 항목 — 보장 범위·보험료 부담 미기재)', 31),
  (@comp_id, 'health_check', '건강검진', NULL, 'health',
   'est', NULL, TRUE, '건강검진 시행 (공식 채용 페이지 복리후생 「직원들의 건강을 책임지는 회사」 항목 — 주기·검진 항목·가족 확대 여부 미기재)', 32),

  -- ── 여가·라이프 (leisure) ── 카드3 Refresh / 카드4 능력
  (@comp_id, 'resort', '숙박시설 할인 제공', NULL, 'leisure',
   'est', NULL, TRUE, '해외 및 전국의 유명 숙박시설을 저렴한 가격으로 제공 (공식 채용 페이지 복리후생 「Refresh를 지원하는 회사」 항목 — 제휴처·이용 요금·연간 이용 횟수 미기재)', 40),
  (@comp_id, 'club', '동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 활동 등 취미 개발 지원 (공식 채용 페이지 복리후생 「능력을 키워주는 회사」 항목 — 활동비 한도·동호회 수 미기재)', 41),

  -- ── 휴가·휴직 (time_off) ── 카드3 Refresh를 지원하는 회사
  (@comp_id, 'refresh_leave', '안식월', NULL, 'time_off',
   'est', NULL, TRUE, '한달 간 휴가를 부여하여 재충전할 수 있는 안식월 제도 (공식 채용 페이지 복리후생 「Refresh를 지원하는 회사」 항목 — 부여 조건·사용 시기 미기재)', 50),

  -- ── 성장·교육 (growth) ── 카드4 능력을 키워주는 회사
  (@comp_id, 'self_development', '자격증 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '자격증 등 역량 개발 지원 (공식 채용 페이지 복리후생 「능력을 키워주는 회사」 항목 — 대상 자격증 범위·지원 한도 미기재)', 60),
  (@comp_id, 'lang', '어학 지원', NULL, 'growth',
   'est', NULL, TRUE, '어학 등 역량 개발 지원 (공식 채용 페이지 복리후생 「능력을 키워주는 회사」 항목 — 대상 과정·응시료 포함 여부 미기재)', 61),
  (@comp_id, 'conference', '교육·세미나 참석 지원', NULL, 'growth',
   'est', NULL, TRUE, '교육/세미나 참석 지원 (공식 채용 페이지 복리후생 「능력을 키워주는 회사」 항목 — 비용 한도·연간 횟수 미기재)', 62),

  -- ── 보상·금전 (compensation) ── 카드4 능력을 키워주는 회사
  (@comp_id, 'long_service_bonus', '근속 포상·3주년 선물', NULL, 'compensation',
   'est', NULL, TRUE, '사기진작을 위한 3주년 선물 및 5, 10, 15, 20년 근속 포상 (공식 채용 페이지 복리후생 「능력을 키워주는 회사」 항목 — 포상 형태·금액 미기재)', 70),

  -- ── 경제적 부가혜택 (perks) ── 카드5 여성이 근무하기 좋은 회사
  (@comp_id, 'home_security', '여직원 무인경비 지원', NULL, 'perks',
   'est', NULL, TRUE, '혼자 사는 여직원 대상 무인경비시스템 지원, 감시센서를 통한 침입 실시간 감지 및 긴급상황 통보 (공식 채용 페이지 복리후생 「여성이 근무하기 좋은 회사」 항목 — 비용 부담·제휴 업체 미기재)', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
