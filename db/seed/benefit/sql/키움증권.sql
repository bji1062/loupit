-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 키움증권 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-14)
-- URL: https://www3.kiwoom.com/h/ir/recruit/VWelfareView
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 키움증권 자기 도메인(kiwoom.com) 회사개요 섹션의
--       인재채용 > 인사제도 > 복지제도 페이지 한 곳이다. 3자 사이트 인용 0건.
--       귀속: EV 인증서 주체 O=Kiwoom Securities Co. Ltd, serialNumber 107-81-76756 과
--       페이지 푸터 사업자등록번호 107-81-76756 이 일치한다. 그룹 공통 채용사이트는 없다
--       (다우키움 그룹 통합 페이지 미발견) — 그룹 통합 각주 해당 없음.
--       서버렌더 HTML 이라 헤드리스 불필요. 원본 HTML 의 div.box-grid-wrap.welfare 안에
--       카테고리 6개(strong.subject) · 항목 16개(li) 가 텍스트로 있다.
--       ⚠ 원본 title 은 IR 기본값(개요/주주현황 …)이다 — JS 가 나중에 고친다. 페이지 식별은
--         h1.page-title 복지제도 + 메뉴 JSON ucd 003985 + 푸터 사업자등록번호로 할 것.
--       ⚠ head 의 인라인 안티봇 스크립트와 ?evfw= 토큰이 요청마다 바뀐다. 갱신 감지는
--         페이지 전체가 아니라 복지 블록 슬라이스 해시로(evidence 에 기준값).
--       ⚠ hm_url www.kiwoom.com 루트는 JS 리다이렉트 껍데기라 긁으면 0건이다.
--       페이지에 설명 문장·금액·일수·한도가 없다 — 라벨뿐이다(심텍과 같은 유형).
--       → 15행 전부 BENEFIT_AMT NULL · QUAL_YN TRUE. 신규 회사라 승계할 앵커도 없다.
--       16 라벨 → 15행: 콘도시설 제휴 + 하계휴양소 운영이 둘 다 resort 라 한 행(-1).
--       복합 라벨 3개는 같은 코드로 귀결돼 분리하지 않았다
--       (경조 휴가·경조금·장의용품 → event / 생일·결혼기념일 선물 → birthday_gift /
--        공동직장보육시설·수유실 → childcare). 신규 코드 0.
--       법정 제도 미수록: 4대보험·퇴직연금·연차·육아휴직 서술이 페이지에 아예 없다.
--       공동직장보육시설은 직장어린이집 설치 의무 이행분일 수 있으나 계약 규칙 3 열거 밖이고
--       코퍼스가 childcare 를 비교축으로 쓰고 있어 수록했다 — 판단 근거는 evidence.
--       EV 인증서 만료 2026-10-09 — 이후 재수집 시 TLS 검증 실패부터 확인할 것.
--       ⚠ 검증·감사 판정 반영(2026-09-15): 행 조치 없음(15행 그대로). SORT 40 childcare 유지 ·
--       SORT 60 은 근속 연동 리프레시라 long_service_leave 유지.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('kiwoom', '키움증권',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '증권', 'K', 'https://www3.kiwoom.com/h/ir/recruit/VWelfareView');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kiwoom');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www3.kiwoom.com/h/ir/recruit/VWelfareView'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '선택적 복리후생제도', NULL, 'perks',
   'est', NULL, TRUE, '선택적 복리후생제도 운영 (공식 인재채용 복지제도 페이지 자기개발 및 취미활동 지원 항목 — 연간 한도·지급 방식·사용처 미기재)', 10),
  (@comp_id, 'housing_loan', '주택구입·임차 자금 대출', NULL, 'perks',
   'est', NULL, TRUE, '주택구입·임차 자금 대출 지원 (공식 인재채용 복지제도 페이지 주거생활안정 지원 항목 — 대출 한도·금리·자격 요건 미기재)', 11),
  (@comp_id, 'birthday_gift', '생일·결혼기념일 선물', NULL, 'perks',
   'est', NULL, TRUE, '생일, 결혼기념일 선물 지급 (공식 인재채용 복지제도 페이지 경조 및 기념일 지원 항목 — 선물 품목·금액 미기재)', 12),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 운영 (공식 인재채용 복지제도 페이지 자기개발 및 취미활동 지원 항목 — 동호회 수·활동비 지원 여부 미기재)', 20),
  (@comp_id, 'resort', '콘도시설 제휴·하계휴양소', NULL, 'leisure',
   'est', NULL, TRUE, '국내 다양한 콘도시설 제휴, 직원 대상 하계휴양소 운영 (공식 인재채용 복지제도 페이지 임직원 Refresh 및 문화여가생활 지원 항목 — 제휴처 목록·휴양소 위치·이용 조건·이용료 지원 수준 미기재)', 21),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '단체상해보험 가입 (공식 인재채용 복지제도 페이지 건강관리 지원 항목 — 보장 범위·가족 포함 여부·보험료 미기재)', 30),
  (@comp_id, 'health_check', '건강검진', NULL, 'health',
   'est', NULL, TRUE, '연 1회 전 직원 건강검진 실시 (공식 인재채용 복지제도 페이지 건강관리 지원 항목 — 검진 항목·가족 포함 여부·비용 부담 미기재)', 31),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '임직원 의료비 지원제도 운영 (공식 인재채용 복지제도 페이지 건강관리 지원 항목 — 지원 한도·지원 비율·가족 포함 여부 미기재)', 32),
  (@comp_id, 'fitness', '제휴 휘트니스 센터', NULL, 'health',
   'est', NULL, TRUE, '회사 제휴 휘트니스 센터 운영 (공식 인재채용 복지제도 페이지 건강관리 지원 항목 — 제휴처·이용료 지원 수준·이용 조건 미기재)', 33),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'childcare', '공동직장보육시설·수유실', NULL, 'family',
   'est', NULL, TRUE, '공동직장보육시설 및 수유실 운영 (공식 인재채용 복지제도 페이지 주거생활안정 지원 항목 — 시설 위치·정원·대상 연령·보육료 부담 미기재)', 40),
  (@comp_id, 'child_edu', '자녀 학자금', NULL, 'family',
   'est', NULL, TRUE, '임직원 자녀 학자금 지원 (공식 인재채용 복지제도 페이지 주거생활안정 지원 항목 — 대상 학교급·지원 한도·자녀 수 제한 미기재)', 41),
  (@comp_id, 'event', '경조 휴가·경조금·장의용품', NULL, 'family',
   'est', NULL, TRUE, '경조 휴가, 경조금 및 장의용품 지원 (공식 인재채용 복지제도 페이지 경조 및 기념일 지원 항목 — 경조 사유별 휴가 일수·경조금 액수·장의용품 품목 미기재)', 42),

  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'holiday_gift', '명절 선물', NULL, 'compensation',
   'est', NULL, TRUE, '설, 추석 명절 선물 지급 (공식 인재채용 복지제도 페이지 경조 및 기념일 지원 항목 — 선물 품목·금액 미기재)', 50),
  (@comp_id, 'long_service_bonus', '장기근속 포상(10년 단위)', NULL, 'compensation',
   'est', NULL, TRUE, '10년 단위 포상 (공식 인재채용 복지제도 페이지 장기근속자 포상제도 항목 — 포상 내용·금액 미기재)', 51),

  -- ── 휴가 (time_off) ──
  (@comp_id, 'long_service_leave', '장기근속 리프레시 휴가(5년 단위)', NULL, 'time_off',
   'est', NULL, TRUE, '5년 단위 리프레시 휴가 (공식 인재채용 복지제도 페이지 장기근속자 포상제도 항목 — 휴가 일수·유급 여부·휴가비 지급 여부 미기재)', 60)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
