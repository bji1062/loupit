-- ══════════════════════════════════════════════════════════════════════
-- 법정 재취업지원서비스 문구 정리 — 코퍼스 4행 UPDATE (삭제 0 · 행 수 불변)
-- 사용자 결정: 2026-09-26 (재취업지원서비스 3곳이랑 검사기 보강 진행해)
-- 선례: db/migrations/20260920_remove_statutory_phrases.sql (같은 방식 — 가드는 코드 · 옛 항목명 · 옛 설명 전체 · 배지)
--
-- 왜 필요한가: 복지는 법이 시킨 것 위에 더 얹은 것이다(SP-LEGAL). 고령자고용법 제21조의3 ② 와
--   시행령 제14조의2~4 는 피보험자 평균 1,000명 이상 사업주에게 50세 이상 비자발적 이직예정자
--   (정년퇴직 등)에게 재취업지원서비스(경력 진단과 진로설계 · 취업 알선 · 재취업 또는 창업 교육)를
--   이직예정일 전 3년 안에 주도록 의무로 지운다. 9개사 재수집 감사(RA-1 §2-3, 법령 원문 확인)가
--   이 판정으로 9사 문안을 정리했고, 같은 제도를 복지로 적은 코퍼스 행을 후속으로 남겼다.
--   4사 모두 1,000인 이상이다(DART 2025 직원 수: 한화시스템 4,855 · 효성중공업 3,567 ·
--   한국항공우주산업 5,241 · 풍산 3,754).
--
-- 무엇을 바꾸나: BENEFIT_NM · QUAL_DESC_CTNT 두 사용자 노출 필드뿐이다. 코드 · 카테고리 · 금액 ·
--   SORT · 배지는 그대로이고 행도 지우지 않는다. 법 위에 얹은 부분만 남긴다(감사 판정선:
--   대상 확대 · 유급 휴가 · 퇴직 후 혜택 · 기념품 · 행사).
--   · 풍산 retirement_support — 50세 이상 퇴직 예정자 재취업 지원 서비스를 걷고 장기근속자 공로여행만
--   · 효성중공업 retirement_support — 정년퇴직 예정자 재취업지원 제도 문장을 걷고,
--     대상이 넓은(만 50세 이상 임직원) 영역 선택 진로설계교육만. 내용은 법정 진로설계와 같고, 남긴 근거는
--     대상 하나다 — 법정 대상은 이직예정일 전 3년 안(정년 60 기준 대략 57세부터)인데 효성은 50세 이상 재직자
--     전체다(감사 현대차 판정 재직 중 상시와 같은 선. 원문 = 효성중공업 채용 인사제도 페이지 퇴직자 지원 제도).
--   · 한국항공우주산업 retirement_support — 창업 · 재취업 · 재무 · 귀농을 걷고 정년퇴임 행사 · 여행 지원만.
--     재무 · 귀농은 같은 프로그램의 한 분야이고 상회 조건이 원문에 없다(감사 SK이노 판정과 같은 규칙 — 귀농은
--     농업 창업 · 전직 진로라 법의 재취업 또는 창업 교육 범위). 여행은 서비스 분야가 아니라 급부라 남긴다.
--   · 한화시스템 career — 재취업 교육 지원을 걷는다(감사 목록 밖, 리드 전수 검색으로 찾음)
--
-- 적용 (운영 LOUPIT 만, 사용자 ! — 베타 DB 에는 적용하지 않는다):
--   mysql -vv 로 적용한다. -vv 를 붙여야 문마다 Rows matched 가 찍힌다.
--   맨 앞 0단계 SELECT 는 읽기 전용이다 — 4행이 옛 문안 그대로인지, EDIT_LOGS 가 0 인지 보여준다.
-- 기대 영향 행 수: UPDATE 4문 각각 Rows matched 1 Changed 1. 적으면 멈추고 확인하라 —
--   문안이 이미 다르거나 BADGE_CD 가 official 이 아니면 가드가 일부러 건너뛴 것이다.
-- 멱등: 모든 WHERE 가 옛 항목명과 옛 설명 전체를 본다 — 두 번째 실행은 전부 0행이다.
-- 가드: BADGE_CD = official — 재직자가 고친 행은 덮지 않는다.
-- 시드: 같은 4행을 db/seed/benefit/sql 의 4파일에서 같은 종착 상태로 고쳤다.
-- 순서: 정적 재생성(release)보다 먼저. 적재(load.py)는 필요 없다(코드 · 파생값 변화 없음).
-- 행 수: 삭제 · 추가가 없으므로 SD-4 핀 2503 은 그대로다.
-- ══════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;

-- 0) 점검(읽기 전용) — 대상 4행이 옛 문안 그대로인지 + 편집 이력 참조 수
SELECT c.COMP_ENG_NM, b.BENEFIT_ID, b.BENEFIT_CD, b.BENEFIT_NM, b.BADGE_CD,
       (SELECT COUNT(*) FROM TBENEFIT_EDIT_LOG l WHERE l.BENEFIT_ID = b.BENEFIT_ID) AS EDIT_LOGS
  FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE (c.COMP_ENG_NM, b.BENEFIT_CD) IN (
        ('poongsan', 'retirement_support'), ('hyosung_heavy', 'retirement_support'),
        ('kai', 'retirement_support'), ('hanwha_systems', 'career'))
 ORDER BY c.COMP_ENG_NM;

START TRANSACTION;

-- 풍산 retirement_support — 공로여행만
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'poongsan');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_NM = '정년 앞둔 장기근속자 공로여행',
       QUAL_DESC_CTNT = '정년 앞둔 장기근속자 공로여행(유급휴가·여행 경비 지원) (2025 지속가능경영보고서 66쪽 복리후생 제도 표, 2025년 기준 · 공식 채용정보 복지제도 페이지 회사생활 항목 — 휴가 일수·여행 경비 한도 미기재)'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'retirement_support' AND BADGE_CD = 'official'
   AND BENEFIT_NM = '퇴직자 재취업 지원'
   AND QUAL_DESC_CTNT = '퇴직 예정인 만 50세 이상 근로자 재취업 지원 서비스와 정년 앞둔 장기근속자 공로여행(유급휴가·여행 경비 지원) (2025 지속가능경영보고서 66쪽 복리후생 제도 표, 2025년 기준 · 공식 채용정보 복지제도 페이지 회사생활 항목 — 서비스 내용·기간·휴가 일수·여행 경비 한도 미기재)';

-- 효성중공업 retirement_support — 만 50세 이상 임직원 영역 선택 진로설계교육만
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyosung_heavy');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_NM = '만 50세 이상 진로설계교육',
       QUAL_DESC_CTNT = '만 50세 이상 임직원 대상 진로설계교육 실시. 관계&네트워크/건강/재무/주거&여가 영역 중 필요 영역 개별 신청 가능'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'retirement_support' AND BADGE_CD = 'official'
   AND BENEFIT_NM = '퇴직자 지원 제도'
   AND QUAL_DESC_CTNT = '정년퇴직 예정자 재취업지원 제도 제공. 만 50세 이상 임직원 대상 진로설계교육 실시. 관계&네트워크/건강/재무/주거&여가 영역 중 필요 영역 개별 신청 가능';

-- 한국항공우주산업 retirement_support — 정년퇴임 행사 · 여행 지원만
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kai');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '정년퇴직자 지원 (복리후생제도 페이지 동기부여 항목, 정년퇴임 행사 사진 게재). 인사제도 페이지의 퇴직예정자 지원 제도 중 여행 지원 — 지원 금액·기간 미기재'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'retirement_support' AND BADGE_CD = 'official'
   AND BENEFIT_NM = '정년퇴직자·퇴직예정자 지원'
   AND QUAL_DESC_CTNT = '정년퇴직자 지원 (복리후생제도 페이지 동기부여 항목, 정년퇴임 행사 사진 게재). 인사제도 페이지가 정년퇴직지원 및 퇴직예정자 지원 제도(창업, 재취업, 여행, 귀농, 재무 등)로 설명 — 지원 금액·기간 미기재';

-- 한화시스템 career — 재취업 교육 지원을 걷는다
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hanwha_systems');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '해외법인 파견(미국/독일/중국/일본 등 1~2년 주재), 직무역량 강화(MOIM, 온라인콘텐츠)'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'career' AND BADGE_CD = 'official'
   AND BENEFIT_NM = '글로벌 리더 양성'
   AND QUAL_DESC_CTNT = '해외법인 파견(미국/독일/중국/일본 등 1~2년 주재), 직무역량 강화(MOIM, 온라인콘텐츠), 재취업 교육 지원';

COMMIT;
