-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 이랜드월드 복리후생 데이터 (신규 회사 — 웨이브 14)
-- 출처: AI 파싱 (2026-10-22)
-- URL: https://www.eland.co.kr/%EC%9D%B4%EB%9E%9C%EB%93%9C%EC%9B%94%EB%93%9C_ESG%EB%B3%B4%EA%B3%A0%EC%84%9C_%EA%B5%AD%EB%AC%B8.pdf
-- badge: est
--
-- 참고:
--   정본 = 이랜드월드 자기 발행 2023 지속가능경영보고서(국문 · 2024년 12월 발간 · 보고 기간 2023.1 ~ 12 · 보고 범위 이랜드월드 패션사업부 국내 사업장)
--     · DART 홈 주소 www.eland.co.kr 의 ESG 메뉴(/about/esg)가 링크한 PDF(파일 이름에 연도 없음) · 43쪽 복리후생 정책 표 · 19 · 41 · 42 · 44 · 49 · 60쪽.
--   보조 = 이랜드월드 채용 공고 3건(careers.eland.co.kr · 제목 꼬리표 [이랜드월드] · 본문 이미지 판독) 복리후생 블록 — 세 공고가 브랜드 줄만 다르고 같은 블록.
--     이랜드리테일 공고 블록과 문장 · 모양이 달라 그룹 템플릿 아님 → 법인 전용 공고로 각주 없음.
--   귀속: 보고서 · 공고 모두 이랜드월드가 주어 · 채용 주체 → 각주 없음. 2026 반기보고서 직원 2,659명 전원 패션 부문 → 부문 꼬리 없음.
--   금액: 금액 행 0(원문에 연 금액 없음 · 인재추천 보상금은 제외).
--   제외: 사내추천 인재 보상금 · 업무 교육(EBG · 점장 · 온라인 사관학교 · MD스쿨 · 생산스쿨) · 조직문화 TFT 논의 안건(리프레시 휴가 등 논의만) ·
--     휴가 등록 시스템 · 공통 휴가 자율화(본인 법정 휴가) · 사내근로복지기금 출연 이사회 안건 · 인하우스 스튜디오 · 의류 샘플(업무 시설) · 임원 복리후생(공시).
--   공고 근거 2행 / 전체 20행(edu_support · meal) — 나머지 공고 인용 행은 보고서가 함께 받친다.
--   SORT 섹션 = leisure 10 · health 20 · growth 30 · family 40 · perks 50 · compensation 60 · flexibility 70(보고서에 처음 나온 순서).
-- 검증 · 감사 판정 반영(2026-10-22): 행 조치 없음 · 국문 영문 보고서 모두 2023 판(2024-12 발간)이 자기 도메인 최신 판 · 공고 단독 2행은 사용자 결정 10-22 대로 유지 · 이랜드리테일 공고와 블록이 달라 그룹 템플릿 아님 · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 20행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('eland_world', '이랜드월드',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '패션', 'E', 'https://www.eland.co.kr/%EC%9D%B4%EB%9E%9C%EB%93%9C%EC%9B%94%EB%93%9C_ESG%EB%B3%B4%EA%B3%A0%EC%84%9C_%EA%B5%AD%EB%AC%B8.pdf');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'eland_world');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.eland.co.kr/%EC%9D%B4%EB%9E%9C%EB%93%9C%EC%9B%94%EB%93%9C_ESG%EB%B3%B4%EA%B3%A0%EC%84%9C_%EA%B5%AD%EB%AC%B8.pdf'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 여가 (leisure) — 보고서 19 · 41 · 43 · 44쪽 ──
  (@comp_id, 'club', '사내 동아리(CREW)', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동아리(CREW) 활동 참여 (2023 지속가능경영보고서 19쪽 이해관계자 소통 임직원 주요 활동 항목), 사내 동아리 등 다채로운 문화 행사 (같은 보고서 44쪽 임직원 소통 항목) — 동아리 지원 내용·금액 미기재', 10),
  (@comp_id, 'company_event', '문화행사·체육대회·송페스티벌', NULL, 'leisure',
   'est', NULL, TRUE, '문화행사 (2023 지속가능경영보고서 43쪽 복리후생 정책 기타 항목), 체육대회, 송페스티벌 등과 같은 다채로운 문화 행사 (같은 보고서 44쪽 임직원 소통 항목), 송페스티발, 전 가족수련회, 전 직원 체육대회, 김밥 송년회 등 다양한 문화활동 (같은 보고서 41쪽 인재 확보 항목) — 행사 주기·지원 내용 미기재', 11),
  (@comp_id, 'resort', '리조트 할인', NULL, 'leisure',
   'est', NULL, TRUE, '여가활동을 위한 리조트 할인 (2023 지속가능경영보고서 43쪽 복리후생 정책 기타 항목) — 이용 리조트·할인율·이용 횟수 미기재', 12),
  -- ── 건강 (health) — 보고서 19 · 43 · 49쪽 · 공고 Health 항목 ──
  (@comp_id, 'health_check', '종합건강검진 (배우자 포함)', NULL, 'health',
   'est', NULL, TRUE, '종합건강검진 (2023 지속가능경영보고서 43쪽 복리후생 정책 건강 항목), 정기(년1회) 건강검진(배우자 동반) (같은 보고서 19쪽 임직원 주요 활동 항목), 매년 종합건강검진 결과를 바탕으로 전문의 상담 제공 (같은 보고서 49쪽 임직원 건강증진 활동 항목), 종합건강검진 제공 (입사 1년 후 이용 가능, 배우자 포함 지원) (이랜드월드 채용 공고 복리후생 Health 항목) — 검진 비용 지원 범위 미기재', 20),
  (@comp_id, 'insurance', '단체상해보험 (배우자·자녀 포함)', NULL, 'health',
   'est', NULL, TRUE, '단체상해보험 (2023 지속가능경영보고서 43쪽 복리후생 정책 건강 항목), 단체상해보험 지원 (배우자, 자녀 포함 지원) (이랜드월드 채용 공고 복리후생 Health 항목) — 보장 내용·보험료 지원 범위 미기재', 21),
  (@comp_id, 'smoking_cessation', '금연 클리닉', NULL, 'health',
   'est', NULL, TRUE, '금연 클리닉 등 신체적 건강증진 프로그램 운영 (2023 지속가능경영보고서 49쪽 임직원 건강증진 활동 항목) — 프로그램 내용·대상 미기재', 22),
  (@comp_id, 'mental', '직무 스트레스 및 우울증 관리', NULL, 'health',
   'est', NULL, TRUE, '직무 스트레스 및 우울증 관리와 같은 정신적 건강증진 프로그램 운영 (2023 지속가능경영보고서 49쪽 임직원 건강증진 활동 항목) — 상담 방식·이용 횟수 미기재', 23),
  -- ── 성장 (growth) — 보고서 19 · 41 · 42 · 43쪽 · 공고 Benefit 항목 ──
  (@comp_id, 'career', '사내공모 제도', NULL, 'growth',
   'est', NULL, TRUE, '사내 공모 (비공개) 지원 (2023 지속가능경영보고서 19쪽 임직원 주요 활동 항목), 사내공모 제도를 통해 패션, 유통, 호텔레저, 외식, IT, 건설 등 다양한 비즈니스뿐 아니라 복지재단 등 다양한 산업과 직무의 기회 (같은 보고서 41쪽 인재 확보 항목) — 지원 자격·이동 조건 미기재', 30),
  (@comp_id, 'lang', '어학 프로그램', NULL, 'growth',
   'est', NULL, TRUE, '글로벌 인재 육성을 위한 어학 프로그램 (2023 지속가능경영보고서 42쪽 직무역량 교육 항목) — 대상·과정 내용·비용 지원 범위 미기재', 31),
  (@comp_id, 'retirement_support', '퇴직자 지원 제도 (45세 이상 재직자)', NULL, 'growth',
   'est', NULL, TRUE, '중년 재직자(45세 이상)가 새로운 미래를 성공적으로 준비할 수 있도록 퇴직 프로세스를 통해 경력을 전환하는 퇴직자 지원 제도 (2023 지속가능경영보고서 43쪽 퇴직자 지원 항목) — 지원 프로그램 내용·기간 미기재', 32),
  (@comp_id, 'edu_support', '학습 공동체 운영 지원 (월 1회)', NULL, 'growth',
   'est', NULL, TRUE, '월 1회 학습 공동체 운영 지원 (직무 개발, 스포츠 활동 등) (이랜드월드 채용 공고 복리후생 Benefit 항목) — 지원 금액·운영 방식 미기재', 33),
  -- ── 가족 (family) — 보고서 43쪽 · 공고 Health 항목 ──
  (@comp_id, 'event', '경조금 및 경조휴가', NULL, 'family',
   'est', NULL, TRUE, '경조금 및 경조휴가 (2023 지속가능경영보고서 43쪽 복리후생 정책 가족 항목), 경조휴가, 화환, 물품, 경조금 지급 (이랜드월드 채용 공고 복리후생 Health 항목) — 경조 사유별 금액·휴가 일수 미기재', 40),
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '사내 어린이집 운영 (2023 지속가능경영보고서 43쪽 복리후생 정책 가족 항목), 사내 어린이집 운영 (마곡한솔어린이집) (이랜드월드 채용 공고 복리후생 Health 항목) — 정원·이용 조건 미기재', 41),
  -- ── 생활 · 금융 (perks) — 보고서 43 · 60쪽 · 공고 Benefit · Office life 항목 ──
  (@comp_id, 'welfare_fund_loan', '임직원 예금·대출', NULL, 'perks',
   'est', NULL, TRUE, '임직원의 재정적 안정을 위한 예금·대출 지원 (2023 지속가능경영보고서 43쪽 복리후생 정책 주거/생활 항목) — 대출 용도·한도·이율 미기재', 50),
  (@comp_id, 'discount', '계열사·자사 브랜드 할인', NULL, 'perks',
   'est', NULL, TRUE, '계열사 할인 (2023 지속가능경영보고서 43쪽 복리후생 정책 기타 항목), 브랜드 할인 혜택 (로엠, 미쏘, 클라비스, 에블린, 스파오, 스파오 키즈, 후아유 등) · 이랜드 그룹 계열사 할인 혜택 (애슐리 퀸즈, 켄싱턴 호텔/리조트 등) (이랜드월드 채용 공고 복리후생 Benefit 항목) — 할인율 미기재', 51),
  (@comp_id, 'welfare_point', '복지포인트 (이랜드몰)', NULL, 'perks',
   'est', NULL, TRUE, '복지포인트 (2023 지속가능경영보고서 43쪽 복리후생 정책 기타 항목), 이랜드몰 복지 포인트 제공 (입사 1년 후 이용 가능, 반기별 지급) (이랜드월드 채용 공고 복리후생 Benefit 항목) — 포인트 금액 미기재', 52),
  (@comp_id, 'meal', '임직원 전용 사내식당', NULL, 'perks',
   'est', NULL, TRUE, '임직원 전용 사내식당 운영 (이랜드월드 채용 공고 복리후생 Office life 항목) — 제공 끼니·식대 지원 범위 미기재', 53),
  (@comp_id, 'snack_bar', '카페테리아·사내 카페', NULL, 'perks',
   'est', NULL, TRUE, '임직원 전용 카페테리아 운영 (이랜드월드 채용 공고 복리후생 Office life 항목), 이랜드월드 사내 카페 위닝라운지 (2023 지속가능경영보고서 60쪽 기부 및 선물 나눔 항목) — 무료 여부·이용 조건 미기재', 54),
  -- ── 보상 (compensation) — 보고서 44쪽 · 공고 Reward 항목 ──
  (@comp_id, 'incentive', '성과급 (반기별)', NULL, 'compensation',
   'est', NULL, TRUE, '반기별 성과에 따른 성과급 지급 (이랜드월드 채용 공고 복리후생 Reward 항목), 성과 중심의 보상 체계에 따른 성과급 지급 · 개인성과급 (2023 지속가능경영보고서 44쪽 평가 및 보상 항목) — 지급 기준·지급률 미기재', 60),
  -- ── 근무 유연성 (flexibility) — 보고서 49쪽 ──
  (@comp_id, 'remote_work', '재택근무 제도 (조건부)', NULL, 'flexibility',
   'est', NULL, TRUE, '질병과 관련해 재택근무 제도와 방역 등으로 임직원의 건강한 근무 환경 조성 (2023 지속가능경영보고서 49쪽 임직원 건강증진 활동 항목) — 대상 직무·사용 조건 미기재', 70)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
