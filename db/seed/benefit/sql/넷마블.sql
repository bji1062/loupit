-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 넷마블 복리후생 데이터
-- 출처: AI 파싱 (2026-09-05)
-- URL: https://company.netmarble.com/hr/system
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
--
-- 참고:
--   정본은 상장 법인 넷마블(주)의 기업 사이트 company.netmarble.com 의 인사제도 페이지다.
--   같은 도메인이 이 법인의 IR(공시·재무정보·주주총회)을 호스팅하고, 복지 본문 주어도
--   「넷마블은 다양한 복지제도를 통해」로 법인 단수라 귀속이 확정된다.
--   정적 SSR HTML 이라 헤드리스가 필요 없다. 항목 15개가 dl/dt/dd 로 최초 HTML 에 들어 있다.
--   ⚠ 복리후생 탭 div.hr_cnt2 에는 display:block 이 없다 — 헤드리스로 보이는 텍스트만 긁으면
--     15개가 통째로 사라진다. 원본 HTML 파싱이 정답이다. HEAD 는 405 를 주니 GET 으로 확인할 것.
--   ⚠ 정본은 라벨만 있고 설명·금액이 없다. 설명과 금액 2건은 보조 출처
--     career.netmarble.com/inside/wellness 에서 가져왔는데, 이 사이트는 「넷마블컴퍼니 채용」이라
--     넷마블네오·엔투·넥서스 등 별개 법인을 포괄한다(개인정보처리방침의 법인별 책임자 목록이 근거).
--     그래서 보조 출처가 닿은 전 행의 QUAL_DESC/NOTE 말미에 「(넷마블컴퍼니 공통 채용 기준)」
--     각주를 달았다 — 이 각주는 귀속의 전제라 절대 떨구지 않는다. 23행 중 17행이 해당한다.
--   병합 3건: 상조 물품 지원 → event(경조사) · 헬스케어실 → clinic(사내 힐링센터) ·
--     리프레쉬 휴가와 휴가비 → long_service_leave/long_service_bonus(장기근속 휴가 및 포상금).
--     BENEFIT_CD 가 회사당 UNIQUE 라 같은 코드로 귀결되는 항목은 한 행에 담고 QUAL_DESC 에 양쪽을 적었다.
--   신규 코드 0개. 23행 전부 기존 어휘 85종 안에서 해결했다.
--   금액 2건만 명시값이다: 복지포인트 연 250만원(원문이 연액), 점심식대 월 20만원 → 연 240만원(SI-B2).
--     명절 현금 20만원은 연간 지급 횟수가 원문에 없어 연환산하지 않고 서술로만 남겼다.
--   제외: 개별연봉제·다면평가(임금·평가 체계라 복지 아님), ㅋㅋ프렌즈스토어 할인(HTML 주석 속 죽은 항목),
--     보조 출처 Pride 섹션(제목·이미지뿐 항목 0개).
--   SORT 섹션 순서는 정본 페이지에서 그 카테고리가 처음 나온 순서를 따랐다
--     (perks 10 · growth 20 · leisure 30 · compensation 40 · family 50 · health 60 ·
--      time_off 70 · flexibility 80 · work_env 90).
--       ⚠ 검증·감사 판정 반영(2026-09-05): SORT 90 사옥 옥외 휴게공간(lounge) 삭제 —
--       작은 공원·생태 연못은 사옥 조경 소개이지 제도가 아니고, 코퍼스 lounge 18행은
--       전부 실내 휴게·문화 공간이다. 23 → 22행. SORT 60 은 힐링센터·헬스케어실 병기로
--       고쳤고, 사용자 노출 3필드의 편집 주석을 전부 걷어냈다.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('netmarble', '넷마블',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '게임', 'N', 'https://company.netmarble.com/hr/system');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'netmarble');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://company.netmarble.com/hr/system'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지포인트', 250, 'perks',
   'est', '공식 인사제도 페이지 항목명은 카페테리아식 복리후생(복지 포인트 제공). 넷마블컴퍼니 채용 웰니스 페이지 명시값 연간 250만원 — 자기개발·여가·취미 활동에 사용 (넷마블컴퍼니 공통 채용 기준)', FALSE, NULL, 10),
  (@comp_id, 'discount', '임직원 복지몰', NULL, 'perks',
   'est', NULL, TRUE, '임직원 복지몰 운영 (공식 인사제도 페이지 문화·여가활동 항목명 그대로 — 입점 상품·할인율·이용 한도 미기재)', 11),
  (@comp_id, 'transport', '퇴근 교통비 지원', NULL, 'perks',
   'est', NULL, TRUE, '퇴근 교통비 지원. 넷마블컴퍼니 채용 웰니스 페이지는 업무로 인한 심야근무 시 안전한 귀가를 위해 택시비를 실비 지원한다고 기재 — 한도·정산 기준 미기재 (넷마블컴퍼니 공통 채용 기준)', 12),
  (@comp_id, 'snack_bar', '임직원 전용 카페 (ㅋㅋ 다방)', NULL, 'perks',
   'est', NULL, TRUE, '임직원 전용 카페 운영. 넷마블컴퍼니 채용 웰니스 페이지는 넓은 실내공간과 야외정원을 갖춘 ㅋㅋ 다방으로 소개 — 무료 여부·이용 한도 미기재 (넷마블컴퍼니 공통 채용 기준)', 13),
  (@comp_id, 'meal', '중식 및 석식 지원', 240, 'perks',
   'est', '넷마블컴퍼니 채용 웰니스 페이지 명시값 점심식대 월 20만원을 연 240만원으로 환산한 값. 석식은 8시 이후 근무 시 별도 제공이라 금액에 포함하지 않았다 (넷마블컴퍼니 공통 채용 기준)', FALSE, NULL, 14),
  (@comp_id, 'commute_subsidy', '셔틀버스', NULL, 'perks',
   'est', NULL, TRUE, '구로디지털단지역·가산디지털단지역에서 사옥까지 셔틀버스 운영. 공식 인사제도 페이지에는 없고 넷마블컴퍼니 채용 웰니스 페이지에만 기재 (넷마블컴퍼니 공통 채용 기준)', 15),

  -- ── 성장·교육 (growth) ──
  (@comp_id, 'books', '사내 도서관', NULL, 'growth',
   'est', NULL, TRUE, '사내 도서관 운영 (공식 인사제도 페이지 문화·여가활동 항목명 그대로 — 장서 규모·도서 구입비 지원 여부 미기재)', 20),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '콘도 및 숙박시설 이용 지원', NULL, 'leisure',
   'est', NULL, TRUE, '콘도 및 숙박시설 이용 지원 (공식 인사제도 페이지 문화·여가활동 항목명 그대로 — 제휴처·이용 조건·지원 한도 미기재)', 30),

  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'holiday_gift', '명절 효도비', NULL, 'compensation',
   'est', NULL, TRUE, '명절 효도비 지급. 넷마블컴퍼니 채용 웰니스 페이지는 명절 선물로 현금 20만원씩 지급한다고 기재 — 연간 지급 횟수 미기재 (넷마블컴퍼니 공통 채용 기준)', 40),
  (@comp_id, 'long_service_bonus', '장기근속 포상금', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 포상금 지급. 넷마블컴퍼니 채용 웰니스 페이지는 리프레쉬 휴가와 함께 5년마다 소정의 휴가비를 지급한다고 기재 — 포상금 금액 미기재 (넷마블컴퍼니 공통 채용 기준)', 41),
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '게임 사업 특성에 적합한 고성과 지향의 인센티브 운영 (공식 인사제도 페이지 평가 및 보상 탭 — 지급 기준·주기·금액 미기재)', 42),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 특별 휴가 및 경조금 지급, 상조 물품 지원 (공식 인사제도 페이지 생활안정·편의 항목 — 경조 구분별 휴가 일수·경조금액 미기재)', 50),
  (@comp_id, 'parenting', '모성보호 지원', NULL, 'family',
   'est', NULL, TRUE, '임신 전 기간 단축 근로와 임신·출산 선물, 기준에 따른 출산 병원비 지원. 공식 인사제도 페이지에는 없고 넷마블컴퍼니 채용 웰니스 페이지에만 기재 (넷마블컴퍼니 공통 채용 기준)', 51),
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '연면적 약 550평 규모로 지하 1층부터 지상 4층까지 단독건물로 조성된 어린이집 운영. 공식 인사제도 페이지에는 없고 넷마블컴퍼니 채용 웰니스 페이지에만 기재 (넷마블컴퍼니 공통 채용 기준)', 52),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'clinic', '사내 힐링센터·헬스케어실', NULL, 'health',
   'est', NULL, TRUE, '임직원 건강을 위한 사내 힐링센터 운영. 넷마블컴퍼니 채용 웰니스 페이지는 같은 사옥의 헬스케어실을 소개하며 일반의약품 제공과 건강상담을 든다 — 두 시설의 관계는 미기재 (넷마블컴퍼니 공통 채용 기준)', 60),
  (@comp_id, 'health_check', '종합 건강검진 (배우자 포함)', NULL, 'health',
   'est', NULL, TRUE, '전 임직원 및 배우자 종합 검진 제공. 넷마블컴퍼니 채용 웰니스 페이지는 매년 지원하며 종합검진과 일반검진을 교차 지원하고 검진 휴가도 준다고 기재 — 검진 비용 미기재 (넷마블컴퍼니 공통 채용 기준)', 61),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '의료비 지원. 넷마블컴퍼니 채용 웰니스 페이지는 기준에 따라 실비로 지원한다고 기재 — 한도·대상 범위 미기재 (넷마블컴퍼니 공통 채용 기준)', 62),
  (@comp_id, 'insurance', '단체 상해보험', NULL, 'health',
   'est', NULL, TRUE, '단체 상해보험 지원 (공식 인사제도 페이지 헬스케어지원 항목명 그대로 — 보장 범위·보험료 부담 비율 미기재)', 63),
  (@comp_id, 'fitness', '사내 피트니스센터 (지핏)', NULL, 'health',
   'est', NULL, TRUE, '사옥 내 500평 규모 피트니스 센터를 상주 전문 트레이너와 함께 운영. 공식 인사제도 페이지에는 없고 넷마블컴퍼니 채용 웰니스 페이지에만 기재 (넷마블컴퍼니 공통 채용 기준)', 64),
  (@comp_id, 'mental', '심리상담센터', NULL, 'health',
   'est', NULL, TRUE, '전문 심리상담사가 상주하는 심리상담실을 운영하며 상담 프로그램 제공. 공식 인사제도 페이지에는 없고 넷마블컴퍼니 채용 웰니스 페이지에만 기재 (넷마블컴퍼니 공통 채용 기준)', 65),

  -- ── 휴가 (time_off) ──
  (@comp_id, 'long_service_leave', '장기근속 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 휴가 제공. 넷마블컴퍼니 채용 웰니스 페이지는 5년마다 리프레쉬 휴가를 준다고 기재 — 휴가 일수 미기재 (넷마블컴퍼니 공통 채용 기준)', 70),

  -- ── 유연근무 (flexibility) ──
  (@comp_id, 'flex_work', '선택적 근로시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '선택적 근로시간제 운영으로 업무 시간 관리의 자율성 부여. 공식 인사제도 페이지에는 없고 넷마블컴퍼니 채용 웰니스 페이지에만 기재 (넷마블컴퍼니 공통 채용 기준)', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
