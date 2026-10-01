-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 아이패밀리에스씨 복리후생 데이터
-- 출처: AI 파싱 (2026-10-01)
-- URL: https://www.ifamily.co.kr/company/hire
-- badge: est
--
-- 참고:
--   정본은 법인 자기 도메인 회사 소개 사이트(www.ifamily.co.kr/company, 꼬리말 (주)아이패밀리에스씨)의
--   헤더 메뉴 채용 > 채용 안내 페이지의 복지제도 절 8줄이다. 정적 HTML(서버 렌더) — 헤드리스 렌더 없음.
--   robots 는 /company/ 허용(Disallow 는 /member/ 등 4경로뿐). ifamilysc.com 은 ifamily.co.kr 로 301.
--   보조 출처: 정본 페이지가 채용 공고로 링크한 브랜드 ATS ifamilysc.career.greetinghr.com 의
--   HOME(/ko/intro) 복리후생 16항목, 채용 공고 /ko/o/225903 본문 이미지의 복리후생 16항목,
--   공고 /ko/o/197255 의 Benefit 블록, 같은 ATS 스토리 글(근무제 · 사내카페 · 성장장려지원금 · 도서비 ·
--   뷰티데이 · LPT). ATS 는 Next.js 서버 렌더라 원본 HTML 에 본문이 있다.
--   귀속: 법인 단독 채용 사이트(머리말 아이패밀리SC 채용 · 꼬리말 ㈜아이패밀리SC) — 그룹 각주 없음.
--   금액: 월액 환산 2(snack_bar 월 3만 포인트 → 36 · telecom 월 2만 → 24) ·
--     구본 추정 승계 1(resort 50 — 틀 값, NOTE 끝에 (추정)).
--     구본 stated snack_bar 36 은 원문 월액의 환산이라 환산 표기로 바꿨다.
--     self_development 매년 최대 200만원은 한도라 금액을 비웠다(근거표 판단 요청).
--   구본에서 뺀 행: 없음(11행 전부 원문 확인). 재코딩: 없음.
--   SORT 섹션 순서 = 정본 복지제도 절에서 카테고리가 처음 나온 순서, 정본에 없는 카테고리는 ATS 복리후생 순서
--     (time_off 10 · family 20 · perks 30 · work_env 40 · leisure 50 · flexibility 60 · growth 70 · compensation 80).
-- 재수집(2026-10-01): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-01, RV-3-3): 17행 원문 확인 · flex_work · remote_work 서술에 소속·고용 형태 각주 추가 · 연말 송년회·사내 이벤트 company_event 1행 추가 — 최종 18행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('ifamilysc', '아이패밀리에스씨',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '화장품', 'I', 'https://www.ifamily.co.kr/company/hire');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'ifamilysc');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.ifamily.co.kr/company/hire'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 시간·휴가 (time_off) — 정본 복지제도 1~2줄 ──
  (@comp_id, 'long_service_leave', '장기근속 휴가·선물', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속자에게 휴가 및 감사의 선물 제공 (공식 홈페이지 채용 안내 복지제도 항목) — 근속 기준·휴가 일수 미기재', 10),
  (@comp_id, 'birthday_leave', '생일 선물·반일 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '본인 생일에 소정의 상품권 제공 (공식 홈페이지 채용 안내 복지제도 항목), 소정의 생일 선물과 반일 휴가 쿠폰 지급 (공식 채용 사이트 복리후생 항목), 생일 선물과 조기 퇴근 (채용 공고 Benefit 항목)', 11),

  -- ── 가족·돌봄 (family) — 정본 복지제도 3줄 ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '본인과 자녀의 결혼, 가족의 사망 시 소정의 경조금·경조화환 지급 (공식 홈페이지 채용 안내 복지제도 항목), 경조금·유급 휴가 지원과 결혼 시 웨딩 서비스 혜택 (공식 채용 사이트 복리후생 항목), 각종 경조일 휴가와 경조금 지급 (채용 공고 Benefit 항목) — 경조 종류별 금액·휴가 일수 미기재', 20),

  -- ── 경제적 부가혜택 (perks) — 정본 복지제도 4 · 6줄 + ATS 복리후생 ──
  (@comp_id, 'discount', '자사 제품·웨딩 서비스 임직원가', NULL, 'perks',
   'est', NULL, TRUE, '본인 및 가족의 웨딩·메이크업 상품 이용 시 특별 임직원가 (공식 홈페이지 채용 안내 복지제도 항목), 자사 제품 최대 70% 할인 (공식 채용 사이트 복리후생 항목), 정가 대비 70% 자사 제품 할인가 지원 (공식 채용 사이트 스토리 매일이 뷰티데이 글)', 30),
  (@comp_id, 'snack_bar', '사내 카페 (월 3만원 포인트)', 36, 'perks',
   'est', '매월 카페 포인트 3만원 충전·미사용분 이월 (공식 채용 사이트 복리후생 항목 · 스토리 사내카페 글), 사내 카페 저렴한 가격 이용 (공식 홈페이지 복지제도 항목) — 월액을 12개월로 환산', FALSE, NULL, 31),
  (@comp_id, 'telecom', '통신비 지원', 24, 'perks',
   'est', '회사 지정 컬러링 적용 시 매월 통신비 2만원 지원 (공식 채용 사이트 복리후생 항목) — 월액을 12개월로 환산', FALSE, NULL, 32),
  (@comp_id, 'team_dinner', '팀 점심비 지원', NULL, 'perks',
   'est', NULL, TRUE, '팀원들과 매월 1회 팀 점심비 지원 (공식 채용 사이트 복리후생 항목) — 1인당 금액 미기재', 33),
  (@comp_id, 'housing_loan', '무이자 사내대출 (주택자금)', NULL, 'perks',
   'est', NULL, TRUE, '최대 5천만원의 무이자 사내대출(주택자금) 지원 (공식 채용 사이트 복리후생 항목) — 대상 요건·상환 기간 미기재', 34),

  -- ── 근무환경 (work_env) — 정본 복지제도 7줄 ──
  (@comp_id, 'lounge', '사내 휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '사내 휴게실 및 휴식 공간 이용 (공식 홈페이지 채용 안내 복지제도 항목)', 40),

  -- ── 여가·라이프 (leisure) — 정본 복지제도 8줄 + ATS 복리후생 ──
  (@comp_id, 'club', '동아리 운영 (LPT)', NULL, 'leisure',
   'est', NULL, TRUE, '다양한 동호회 활동 지원 (공식 홈페이지 채용 안내 복지제도 항목), 봄·가을마다 동아리 운영 (공식 채용 사이트 복리후생 항목), 반기마다 조장이 주제를 정해 예산 안에서 업무시간에 함께하는 사내 활동 LPT (공식 채용 사이트 스토리 Let’s Play Together 글, 롬앤·누즈 사례) — 1인당 지원 금액 미기재', 50),
  (@comp_id, 'welcome_kit', '웰컴키트', NULL, 'leisure',
   'est', NULL, TRUE, '첫 출근날 15만원 상당의 웰컴키트 제공 (공식 채용 사이트 복리후생 항목), 입사 전에 고른 롬앤·누즈 제품으로 맞춤 구성한 신규입사자 뷰티키트 (공식 채용 사이트 스토리 매일이 뷰티데이 글)', 51),
  (@comp_id, 'resort', '법인 리조트·여기어때 할인', 50, 'leisure',
   'est', '임직원 전용 법인 리조트 이용 (공식 채용 사이트 복리후생 항목), 법인 리조트 및 여기어때 할인가 지원 (채용 공고 Benefit 항목) — 이용 횟수·할인율 미기재 (추정)', FALSE, NULL, 52),
  (@comp_id, 'company_event', '송년회·사내 이벤트', NULL, 'leisure',
   'est', NULL, TRUE, '한 해를 마무리하며 모든 본부 임직원이 함께하는 연말 송년회와 추석·설날·크리스마스 같은 날의 사내 이벤트 (채용 공고 조직문화 송년회·사내 이벤트 항목 · 공식 채용 사이트 스토리 2024 송년회 글) — 행사 내용·비용 부담 미기재', 53),

  -- ── 근무유연성 (flexibility) — ATS 복리후생 ──
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '출근시간 8~10시·코어타임 10~15시 안에서 컨디션에 따라 근무시간 조정 (공식 채용 사이트 복리후생 항목), 월 소정근로시간 안에서 출퇴근시간과 근무시간을 조율하는 선택적 근로시간제 (공식 채용 사이트 스토리 근무제 소개 글, 롬앤·누즈 사례) — 소속·고용 형태에 따라 적용 범위 상이', 60),
  (@comp_id, 'remote_work', '금요일 재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '재택근무제 운영 (공식 채용 사이트 복리후생 항목), 매주 금요일 재택근무 (채용 공고 복리후생 항목 · 공식 채용 사이트 스토리 근무제 소개 글, 롬앤·누즈 사례) — 소속·고용 형태에 따라 적용 범위 상이', 61),

  -- ── 성장·커리어 (growth) — ATS 복리후생 ──
  (@comp_id, 'self_development', '성장 장려 지원금', NULL, 'growth',
   'est', NULL, TRUE, '문화·교육·운동·공연관람·도서 등 자기계발에 쓰는 성장 장려 지원금 매년 최대 200만원 지급 (공식 채용 사이트 복리후생 항목 · 스토리 성장장려지원금 글), 입사 1년 이후 대상 (공식 채용 사이트 스토리 도서비 지원 글) — 개인별 지급 기준 미기재', 70),
  (@comp_id, 'books', '도서 구입비 지원', NULL, 'growth',
   'est', NULL, TRUE, '매월 2권 자유로운 도서 구입 지원 (공식 채용 사이트 복리후생 항목), 입사 1년 미만 직원 대상·도서 분야 제한 없음 (공식 채용 사이트 스토리 도서비 지원 글)', 71),

  -- ── 보상 (compensation) — 채용 공고 ──
  (@comp_id, 'holiday_gift', '명절 선물', NULL, 'compensation',
   'est', NULL, TRUE, '명절 상품권(선물) 지급 (채용 공고 Benefit 항목), 명절 선물 제공 (채용 공고 복리후생 항목) — 금액 미기재', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
