-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 제주항공 복리후생 데이터 (신규 회사 — 웨이브 12)
-- 출처: AI 파싱 (2026-10-18)
-- URL: https://static.jejuair.net/hpgg/resources/pdf/esg_st_20.pdf
-- badge: est
--
-- 참고:
--   정본은 상장 법인 (주)제주항공이 직접 발행한 2026년 지속가능경영보고서 국문 PDF(자기 도메인 static.jejuair.net ·
--     122쪽 · PDF 생성 2026-08-04 · 보고 기간 2025년)다 — 홈 꼬리말 ESG 경영 메뉴(www.jejuair.net/ko/about/esg/page.do)의
--     지속가능경영보고서 목록 2026 국문 PDF 단추가 이 파일을 건다(목록 링크에는 ?v= 캐시 꼬리가 붙는다). ESG 경영 페이지는
--     점검기 UA 에 403 이라 정본으로 쓰지 않고 보조 출처로만 썼다(직원 건강 증진 표 · 보상 절 · 교육 체계도 PDF).
--   근거 쪽: 61쪽 인적자원 관리 · 62쪽 임직원 복리후생과 주요 복리후생 제도 표 · 63쪽 심리 케어 및 건강증진 ·
--     64쪽 자기주도 학습 지원 · 66쪽 조직문화 활성화 · 104쪽 Data Pack 유연근무제 · 111쪽 UN SDGs 성과 및 주요활동.
--     보조: ESG 경영 페이지 임직원 역량 개발 지원 PDF(esg_s_12.pdf · 교육 체계도) · OpenDART 2025 사업보고서
--     (접수 20260318001439) 유연근무제도 사용 현황 표. 2025 지속가능경영보고서는 2026 판에 이름만 남은
--     장기근속 항목의 뜻(장기근속 포상휴가)을 받치는 데만 썼다.
--   채용 사이트 jejuair.recruiter.co.kr/career/welfare 는 본문이 robots 전면 금지 호스트 api-recruiter.recruiter.co.kr
--     에서만 와서 읽지 않았다(렌더 안 함 · 붙여넣기 보강 후보).
--   귀속: 보고서 · 페이지 모두 제주항공 단독 발행 · 제주항공 주어 — 각주 없음. 62쪽 표의 애경 그룹 임직원 혜택
--     (골프장 · 테르메덴 등)도 제주항공 보고서가 자기 복리후생 제도로 적은 문장이라 그대로 썼다(형제 대조는 근거표).
--   금액: 원문에 원 단위 금액 0건 — 전 행 BENEFIT_AMT NULL(식권 제공도 끼니 · 단가 없음).
--   제외: 법정(특수건강진단 · 배치 전후 건강진단 · 출산 육아 가족돌봄 휴직 · 육아기 단축 근로 · 산업안전 보건 교육) ·
--     업무 교육(직무역량 교육 · 리더십 · 온보딩 · 데이터 리터러시 · 주재원 교육) · 임원 보수 칸(자녀학자금 한도 실비) ·
--     옛 판에만 있는 항목(2025 보고서 반반차 · 주거 이전 휴가 · 부임 이사 휴가 · 주재원 부귀임 휴가 · 복지 포인트) ·
--     뜻 미상(모두락 헬스케어) · 원격근무(공시 사용자 수 줄 「-」 · 회사 자기 출처 문장 없음).
--   공고 근거 0행 / 전체 26행.
--   SORT 섹션 순서 = 정본 보고서 등장 순(growth 10 · perks 20 · family 30 · health 40 · leisure 50 · flexibility 60 ·
--     time_off 70 · compensation 80 · work_env 90).
-- 검증 · 감사 판정 반영(2026-10-18): 그룹 인문교육을 edu_support 에 · 모두락 헬스케어를 clinic 에 병합하고 clinic 서술에서 심리 몫 걷기 · flex_work 공시 출처를 2026 반기보고서로 · 임직원몰을 welfare_point 에서 discount 임직원 항공권 행으로 옮겨 병합하고 welfare_point 행 삭제(감사 · 웨이브 11 임직원몰 잣대) · 애경 그룹 임직원 혜택 resort 는 단독 보고서의 자기 제도라 각주 없음 · 참고 블록 제외 줄의 모두락 헬스케어와 보조 출처 줄은 이 판정으로 뒤집힘 — 최종 25행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('jeju_air', '제주항공',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '항공', 'J', 'https://static.jejuair.net/hpgg/resources/pdf/esg_st_20.pdf');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'jeju_air');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://static.jejuair.net/hpgg/resources/pdf/esg_st_20.pdf'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 성장 (growth) — 보고서 61 · 63 · 64쪽 · ESG 경영 페이지 임직원 역량 개발 지원 체계도 ──
  (@comp_id, 'career', '사내공모제도', NULL, 'growth',
   'est', NULL, TRUE, '내부 인재의 경력 개발과 직무 확장을 위해 사내공모제도 운영 (2026 지속가능경영보고서 61쪽 인적자원 관리 항목) — 공모 주기·지원 자격 미기재', 10),
  (@comp_id, 'edu_support', '러닝포인트·명사 초청 특강·그룹 인문교육', NULL, 'growth',
   'est', NULL, TRUE, '러닝포인트 제도로 자격 취득 등 학습 기회를 선택적으로 활용, 러닝포인트는 온·오프라인 교육과정·외부 교육 등 역량 개발 활동에 활용 (2026 지속가능경영보고서 64쪽 자기주도 학습 지원 항목), 명사 초청 특강, 부서원 대상 그룹 인문교육 (공식 ESG 경영 페이지 임직원 역량 개발 지원 교육 체계도 항목) — 연간 포인트 금액 미기재', 11),
  (@comp_id, 'lang', '어학 지원 제도', NULL, 'growth',
   'est', NULL, TRUE, '어학 및 자기개발 지원 (2026 지속가능경영보고서 63쪽 교육 및 역량 개발 체계 항목), 러닝포인트 제도로 어학 학습 (같은 보고서 64쪽 자기주도 학습 지원 항목), 어학 지원 제도 (공식 ESG 경영 페이지 임직원 역량 개발 지원 교육 체계도 항목) — 지원 금액·지원 방식 미기재', 12),
  (@comp_id, 'books', '북러닝포인트', NULL, 'growth',
   'est', NULL, TRUE, '독서를 통한 자기개발과 지식 습득을 지원하는 북러닝포인트 제도 (2026 지속가능경영보고서 64쪽 자기주도 학습 지원 항목) — 연간 포인트 금액·사용처 미기재', 13),
  -- ── 경제적 부가혜택 (perks) — 보고서 62쪽 ──
  (@comp_id, 'discount', '임직원 항공권 (FOC)·임직원몰', NULL, 'perks',
   'est', NULL, TRUE, '항공사 고유의 복리후생 제도인 임직원 항공권 지원 제도 운영, 2025년 FOC 제도 개선으로 임직원 항공권 이용 편의성과 제도 활용성 제고, 임직원몰 (2026 지속가능경영보고서 62쪽 임직원 복리후생 항목), 임직원 항공권(FOC) (같은 쪽 주요 복리후생 제도 여가·가족 지원 항목) — 할인율·연간 이용 매수·가족 적용 범위, 임직원몰 이용 혜택 미기재', 20),
  (@comp_id, 'meal', '식권 제공', NULL, 'perks',
   'est', NULL, TRUE, '식권 제공 (2026 지속가능경영보고서 62쪽 주요 복리후생 제도 조직활력 지원 항목) — 식권 매수·1식 단가 미기재', 21),
  (@comp_id, 'snack_bar', '사내 카페 (모두락)·하계/동계 간식 지원', NULL, 'perks',
   'est', NULL, TRUE, '모두락 사내 카페, 하계/동계 간식 지원 (2026 지속가능경영보고서 62쪽 주요 복리후생 제도 조직활력 지원 항목) — 이용 비용·간식 제공 대상 미기재', 23),
  -- ── 가족 (family) — 보고서 62 · 111쪽 ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원 (2026 지속가능경영보고서 62쪽 주요 복리후생 제도 생활 안정 지원 항목) — 경조금 금액·경조휴가 일수 미기재', 30),
  (@comp_id, 'child_edu', '자녀학자금 (유아·초중고·대학교)', NULL, 'family',
   'est', NULL, TRUE, '자녀학자금(유아, 초/중/고/대학교) (2026 지속가능경영보고서 62쪽 주요 복리후생 제도 생활 안정 지원 항목) — 지원 한도·자녀 수 제한 미기재', 31),
  (@comp_id, 'parenting', '어린이집 위탁보육료·승무원 임신 휴직', NULL, 'family',
   'est', NULL, TRUE, '어린이집 위탁보육료 (2026 지속가능경영보고서 62쪽 주요 복리후생 제도 생활 안정 지원 항목), 임신한 승무원 대상 출산휴가 이전 별도의 휴직 제도 운영, 육아휴직 후 복직 임직원 대상 소통 프로그램 진행 (같은 보고서 111쪽 UN SDGs 성과 및 주요활동 항목) — 위탁보육료 금액·휴직 기간·유급 여부 미기재', 32),
  -- ── 건강 (health) — ESG 경영 페이지 직원 건강 증진 · 보고서 62 · 63 · 111쪽 ──
  (@comp_id, 'health_check', '종합건강검진·독감 예방접종', NULL, 'health',
   'est', NULL, TRUE, '건강검진 시행 중 종합건강진단, 임직원 독감 예방접종 실시 (공식 ESG 경영 페이지 직원 건강 증진 항목), 전 임직원 대상 종합건강검진 제공 (2026 지속가능경영보고서 111쪽 UN SDGs 성과 및 주요활동 항목) — 검진 항목·가족 적용 여부 미기재', 40),
  (@comp_id, 'insurance', '단체보험', NULL, 'health',
   'est', NULL, TRUE, '단체 보험 (2026 지속가능경영보고서 62쪽 주요 복리후생 제도 생활 안정 지원 항목) — 보장 내용·가입 대상 미기재', 41),
  (@comp_id, 'mental', '심리 케어·EAP 상담·감성 코칭', NULL, 'health',
   'est', NULL, TRUE, '맞춤형 심리 케어 프로그램, 트라우마 교육·상담, Safe-Reboarding 상담채널 운영, 마음챙김 심신이완, 감정 소진 완화, 마음안심버스 운영, EAP 연계 상담, 사내 건강증진실 상담, 정신건강 마음레터 발행 (2026 지속가능경영보고서 63쪽 임직원 심리 케어 및 건강증진 지원 항목), 감성 코칭 (같은 보고서 62쪽 주요 복리후생 제도 생활 안정 지원 항목) — 상담 횟수 한도·가족 이용 여부 미기재', 42),
  (@comp_id, 'clinic', '사내 건강증진실·모두락 헬스케어', NULL, 'health',
   'est', NULL, TRUE, '사내 건강증진실 상담실 운영, 건강상담 (2026 지속가능경영보고서 63쪽 임직원 심리 케어 및 건강증진 지원 항목), 모두락 헬스케어 (같은 보고서 62쪽 주요 복리후생 제도 조직활력 지원 항목) — 운영 시간·상주 인력·헬스케어 내용 미기재', 43),
  (@comp_id, 'smoking_cessation', '금연 클리닉', NULL, 'health',
   'est', NULL, TRUE, '금연 클리닉 및 근로자의 건강증진을 위한 각종 캠페인 시행 (공식 ESG 경영 페이지 직원 건강 증진 항목), 금연 클리닉과 「Smoke-Free High Five」 챌린지를 통한 참여자 중심의 맞춤형 금연 지원 (2026 지속가능경영보고서 63쪽 임직원 심리 케어 및 건강증진 지원 항목) — 금연 성공 보상 미기재', 44),
  (@comp_id, 'massage', '네일아트 (모두락)', NULL, 'health',
   'est', NULL, TRUE, '모두락 네일아트 (2026 지속가능경영보고서 62쪽 주요 복리후생 제도 조직활력 지원 항목) — 이용 비용·이용 횟수 미기재', 45),
  -- ── 여가 (leisure) — 보고서 62 · 66쪽 ──
  (@comp_id, 'resort', '호텔·제주 힐리우스·애경 그룹 시설 이용혜택', NULL, 'leisure',
   'est', NULL, TRUE, '호텔 및 제주 힐리우스 이용혜택, 애경 그룹 임직원 혜택(골프장, 테르메덴 등) (2026 지속가능경영보고서 62쪽 주요 복리후생 제도 여가·가족 지원 항목) — 혜택 내용·이용 조건 미기재', 50),
  (@comp_id, 'club', '사내 동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 지원 (2026 지속가능경영보고서 62쪽 주요 복리후생 제도 조직활력 지원 항목), 사내 동호회 및 조직활력 활동 운영 (같은 보고서 66쪽 조직문화 활성화 항목) — 지원 금액·동호회 종류 미기재', 51),
  (@comp_id, 'company_event', 'FUN DAY', NULL, 'leisure',
   'est', NULL, TRUE, 'FUN DAY 등 구성원이 서로 소통하고 교류할 수 있는 활동 (2026 지속가능경영보고서 66쪽 조직문화 활성화 항목) — 행사 내용·개최 주기 미기재', 52),
  -- ── 근무 유연성 (flexibility) — 보고서 62 · 104쪽 · 2025 사업보고서 ──
  (@comp_id, 'flex_work', '시차출퇴근제·탄력근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '시차출퇴근제 (2026 지속가능경영보고서 62쪽 주요 복리후생 제도 근무환경 개선 항목), 시차근무제(시차출퇴근제)·탄력근무제 (같은 보고서 104쪽 ESG Data Pack 유연근무제 항목), 유연근무제 활용, 시차출퇴근제 (2026 반기보고서 유연근무제도 사용 현황 항목) — 출퇴근 시간대·대상 직무 미기재', 60),
  (@comp_id, 'pc_off', 'PC-OFF 시스템', NULL, 'flexibility',
   'est', NULL, TRUE, 'PC-OFF 시스템 (2026 지속가능경영보고서 62쪽 주요 복리후생 제도 근무환경 개선 항목) — 적용 시각·예외 기준 미기재', 61),
  -- ── 휴가 (time_off) — 보고서 62쪽 · 2025 보고서 48쪽 ──
  (@comp_id, 'long_service_leave', '장기근속 포상휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 (2026 지속가능경영보고서 62쪽 주요 복리후생 제도 조직활력 지원 항목), 장기근속 포상휴가 (2025 지속가능경영보고서 48쪽 주요 복리후생 프로그램 항목) — 근속 기준·휴가 일수·포상 내용 미기재', 70),
  -- ── 보상 (compensation) — ESG 경영 페이지 보상 · 보고서 62쪽 ──
  (@comp_id, 'profit_sharing', '경영 성과 반영 성과급', NULL, 'compensation',
   'est', NULL, TRUE, '경영 성과를 반영한 변동급(성과급) (공식 ESG 경영 페이지 보상 항목) — 지급 기준·지급률 미기재', 80),
  (@comp_id, 'excellence_award', '우수사원 포상', NULL, 'compensation',
   'est', NULL, TRUE, '우수사원 포상 (2026 지속가능경영보고서 62쪽 주요 복리후생 제도 조직활력 지원 항목) — 포상 기준·포상 내용 미기재', 81),
  -- ── 근무 환경 (work_env) — 보고서 66쪽 ──
  (@comp_id, 'smart_office', '스마트오피스', NULL, 'work_env',
   'est', NULL, TRUE, '스마트오피스 등 구성원이 서로 소통하고 교류할 수 있는 활동 (2026 지속가능경영보고서 66쪽 조직문화 활성화 항목) — 공간 구성·적용 사업장 미기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
