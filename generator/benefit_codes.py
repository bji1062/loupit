"""generator/benefit_codes.py — 복지 코드 사전(대표 이름 · 별칭 · 최빈 카테고리) 파생 규칙 (2026-10-21).

`generator/pages/find.py`(정적 /find 표 · 항목 페이지)가 쓰던 순수 함수를 가벼운 모듈로 옮겼다 —
서버(`GET /api/v1/benefit-codes`, 승인 큐의 94종 고르기)가 같은 규칙으로 이름을 부르도록, 규칙을
세 번째로 복사하지 않고 여기 하나만 둔다. 표준 라이브러리 + `generator.marks` 만 쓴다
(jinja · 템플릿 · 설정에 의존하지 않는다 — 서버 프로세스가 가볍게 import 한다).

JS 쪽 사본(`web/assets/js/find.js::deriveCodes`)은 그대로이고, `generator/tests/test_find_page.py` 와
`web/assets/js/find.test.js` 가 같은 픽스처로 둘을 맞춘다. `find.py` 는 이 이름들을 그대로 다시 내보낸다.
"""
from __future__ import annotations

from collections import Counter

from generator import marks

# 손으로 못 박는 표시명. **`web/assets/js/find.js::LABEL_OVERRIDE` 와 같은 줄이어야 한다**
# (표는 여기서, 칩은 거기서 이름을 얻는다). test_find_page.py 가 강제한다. 세 갈래다:
#   ① 같은 대표 이름을 쓰는 코드를 갈라 준다(앞 네 줄 — 통근버스·장기근속 뭉치).
#   ② 빈도 1순위가 **한 그룹·한 회사의 표기**라 항목 전체의 이름이 되는 코드를 일반명으로 못 박는다
#      (뒤 다섯 줄, 2026-09-18). CJ 7개사가 같은 문구를 쓰니 「CJ 계열사 할인」이 할인 45곳 전체의 이름이
#      됐다. `leisure_ticket` 은 일반명 뒤에 대표 예시를 괄호로 둔다(사용자 지정 문자열).
#      생일 두 코드는 뜻으로 가른다 — `birthday_leave` 는 휴가·반차·조기퇴근, `birthday_gift` 는 생일·기념일
#      선물(선물만 있던 행 4개를 2026-09-18 에 birthday_gift 로 재코딩했다).
LABEL_OVERRIDE = {
    "transport": "교통비·유류비 지원",
    "commute_subsidy": "통근버스·출퇴근 지원",
    "long_service_leave": "장기근속 휴가",
    "long_service_bonus": "장기근속 포상금",
    "discount": "계열사·제휴 할인",
    "satellite_office": "거점·공유 오피스",
    "leisure_ticket": "여가·문화 이용권(티빙·CGV 이용권)",
    "birthday_leave": "생일 휴가·조기퇴근",
    "birthday_gift": "생일·기념일 선물",
    # 2026-10-04 R-3 후속 정리 2: 용도 미기재 사내 대출도 싣게 되어 이름이 흩어져 최다 이름이 생활안정자금 대출 한 가지로 쏠렸다 — 사내 대출 전체를 덮는 일반명으로 못 박는다.
    "welfare_fund_loan": "사내 대출·생활안정자금 지원",
    # 2026-09-26: 6행 이름이 전부 달라(빈도 1 동률) 최단 이름이 대표가 된다 — 법정 문구 정리로 항목명 2개가 길어지자
    #   LIG 한 회사 표기 「정년 퇴임식·기념품」이 6곳의 이름이 됐다. 6행을 모두 참으로 덮는 일반명으로 못 박는다.
    "retirement_support": "정년퇴직·퇴직 준비 지원",
    # ③ 2026-09-27 표본 재생성(generator/tests/data/make_find_label_cases.py)과 그 검토가 드러낸 같은 결함 —
    #   이름이 전부 1회거나 동률이라 길이 규칙으로 **한 회사의 서비스명·브랜드·건물명**이 항목 전체의 이름이
    #   됐거나(해피쉐어카·허먼밀러 의자·릴렉스룸·복지동·휴양프로그램·컬쳐데이·국내외 학술연수), **옆 코드와
    #   구분이 안 됐다**(자기계발 지원 ↔ self_development · 경조휴가 ↔ event · 우리사주제도 ↔ 스톡옵션 혼재 ·
    #   생활안정자금 지원 ↔ welfare_fund_loan). 복지 항목 페이지(generator/data/benefit_pages)가 있는 코드는
    #   그 제목에 맞춘다. mental 은 6:6 같은 길이의 코드포인트 동전 던지기라 행 하나에 뒤집히지 않게 박는다.
    "car_rental": "차량 대여 지원",
    "office_furniture": "사무용 가구·의자 지원",
    #   2026-10-05: edu_support 항목 페이지 제목을 「교육·학습 지원」으로 바꿔(업무 교육을 내세우던 이름) 여기도 맞춘다.
    "edu_support": "교육·학습 지원",
    "mba": "MBA·대학원 학위 지원",
    "leave_general": "휴가 제도",
    "stock_option": "우리사주·스톡옵션",
    # 2026-10-11 코퍼스 정리: 수면실은 lounge 로 모으고 nap_room 은 수유·모성 공간 전용 — 표시명도 맞춘다.
    "nap_room": "수유실·모성보호실",
    "leisure_room": "사내 여가·오락 시설",
    "travel_support": "여행비 지원",
    "culture_day": "문화의 날",
    "welfare_fund": "사내근로복지기금",
    "library": "전자도서관·북카페",
    "mental": "심리상담 지원",
    # ④ 2026-09-28 재수집 R-3 묶음 1 표본 재생성 — 2회 나온 한 표기 「외부 교육 및 연수」가 conference 의 이름이 돼
    #   옆 코드 edu_support(직무 교육·교육비 지원)와 구분이 안 됐고, stock_grant 는 동률 최단 규칙으로 한 회사의
    #   프로그램 이름(자사주 지급 프로그램)이 대표가 됐다. 두 코드 모두 일반명으로 못 박는다.
    "conference": "컨퍼런스·세미나 참가 지원",
    "stock_grant": "자사주 지급",
    # ⑤ 2026-10-01 재수집 R-3 묶음 2 표본 재생성 — self_development 는 「자격증 취득 지원」(6)이 「자기계발비 지원」(4)을
    #   앞질러 자기계발비 항목 전체가 자격증 이름으로 좁아졌다(항목 페이지 제목에 맞춘다). company_event 는 2회 나온
    #   「가족친화 프로그램」이 사내 행사 전체의 이름이 돼 가족 카테고리 항목과 헷갈린다. 둘 다 일반명으로 못 박는다.
    "self_development": "자기계발비·자격증 지원",
    "company_event": "사내 행사·가족 초청",
    # 2026-10-14 웨이브 6: 현금형(금연수당)과 프로그램형(HJ중공업 금연클리닉)을 함께 담는 이름.
    "smoking_cessation": "금연 지원",
    # 2026-10-14 웨이브 6: 「포상제도」 · 「우수사원 포상」 5:5 동률이 행 하나에 뒤집혀 항목 페이지 제목으로 고정.
    "excellence_award": "사내 포상 제도",
    # ⑥ 2026-10-01 재수집 R-3 묶음 3 표본 재생성 — relocation 은 2회 나온 「부임이사 지원」이 대표가 됐는데 발령 이사에 좁아
    #   정착금 행을 덮지 못한다. promotion_gift 는 2행 동률 최단 규칙으로 한 회사 표기 「승진자 식사 바우처」가 대표가 됐다.
    #   둘 다 일반명으로 못 박는다.
    "relocation": "이사·정착 지원",
    "promotion_gift": "승진 축하 선물",
    # meal 은 「구내식당」 · 「사내식당」이 7:7 같은 길이라 코드포인트로 갈린다 — 행 하나에 뒤집히지 않게 항목 페이지 제목으로 박는다(mental 선례).
    "meal": "구내식당·식대 지원",
    # 2026-10-01 묶음 3 검토 — career 2:2 · 6:6 코드포인트 동률(「멘토링 제도」 · 「사내공모제도」 — 행 하나에 이름이 뒤집힌다)
    "career": "경력개발·사내공모",
    # 2026-10-02 R-3 묶음 5 — 동률 · 1회 이름이 한 회사 표기로 대표가 된 코드(housing_support · disability_family_support)와 항목 페이지가 있는 코드(childcare · fitness · clinic)를 일반명 · 페이지 제목에 못 박는다.
    "housing_support": "주거·숙소 지원금",
    "disability_family_support": "장애 가족 지원",
    "childcare": "사내 어린이집",
    "fitness": "피트니스센터·운동 지원",
    "clinic": "사내 부속의원·건강관리실",
    # 2026-10-02 R-3 묶음 6-A — lounge 는 2:2 동률이라 항목 페이지 제목에, work_tools 는 1회 이름뿐이라 일반명에 못 박는다.
    "lounge": "직원 휴게실·휴식 공간",
    "work_tools": "업무 장비·도구 지원",
    # 2026-10-04 R-3 묶음 7 — uniform 은 11행 이름이 전부 1회라 길이 규칙으로 「유니폼지급」(한 회사 표기)이 대표가 된다 → 일반명으로 못 박는다.
    "uniform": "근무복·유니폼 지원",
    # 2026-10-10 웨이브 5: 「패밀리데이」가 사내 행사 가족 초청(company_event)과 같은 낱말이라 조기 퇴근 축 이름으로 고정.
    "family_day": "가정의 날",
    # 2026-10-14 웨이브 7: 「어학시험 응시료」 · 「어학 교육」 7:7 동률이 길이로 「어학 교육」이 됐다 — 응시료만 뜻하는 이름으로 되돌아가지 않게 고정.
    "lang": "어학 교육",
    # 2026-10-24 웨이브 8: 「하계휴가」 · 「하기휴가」 7:7 같은 길이 동률이 코드포인트로만 갈린다 — 행 하나에 뒤집히지 않게 고정(meal 선례).
    "summer_leave": "하계휴가",
    # 2026-10-31 웨이브 9: parent_care 3행 이름이 전부 1회라 길이 규칙으로 한 회사 표기 「가족 돌봄휴직 지원금」(법정 휴직 낱말)이 대표가 된다 — 일반명으로 고정.
    "parent_care": "가족 돌봄·간병 지원",
    # 2026-10-31 웨이브 9: massage 대표가 「헬스키퍼 운영」(2회)으로 바뀌어 네일케어 · 에스테틱 행까지 헬스키퍼로 부른다 — 일반명으로 고정.
    "massage": "안마·마사지 지원",
    # 2026-10-31 웨이브 9: home_security 에 롯데쇼핑 1인가구 홈 안심 서비스가 들어와 현대백화점 표기 「여직원 무인경비 지원」이 두 회사를 부른다 — 일반명으로 고정.
    "home_security": "1인 가구 홈 보안 지원",
    # 2026-10-18 웨이브 12: remote_work 공시 표 이름 「원격근무제(재택근무 포함)」가 20:19 한 줄 차로 대표가 된다 — 항목 페이지 제목(재택근무)에 맞춰 고정.
    "remote_work": "재택근무",
    # 2026-10-18 웨이브 12: overseas_safety 8행 이름이 전부 1회라 길이 규칙으로 한 회사 표기 「해외 주재원 보험」이 대표가 된다 — 일반명으로 고정.
    "overseas_safety": "해외 출장·근무자 지원",
}


def _prefer_name(kv) -> tuple:
    """대표 이름 정렬 키 — **빈도 내림차순 → 이름 길이 오름차순 → 코드포인트**.

    ① 길이가 두 번째 키인 이유: 86개 중 **26개는 이름이 전부 1회씩**이라(2026-09-06 · 2026-09-27 표본은 90종 중 20종) 라벨이 tie-break 로만
       정해진다. 빈도만 보고 코드포인트로 가르면 라틴·숫자·괄호가 한글 앞에 서서 「KB 패밀리데이」
       「Global MBA/유학」처럼 **한 회사의 표기가 86종 전체의 이름**이 된다(2026-09-06 실데이터 검증).
       짧은 쪽은 대개 수식어가 없는 일반명이다.
    ② 코드포인트가 마지막 키인 이유: 같은 규칙이 `web/assets/js/find.js::preferName` 에도 있어야
       하는데(표는 여기서, 칩은 거기서 그린다) 로케일 정렬은 두 언어에서 결과가 갈릴 수 있다.
    """
    name, count = kv
    return (-count, len(str(name)), str(name))


def _most_common(counter: Counter):
    """최빈값 — 동률은 `_prefer_name` 규칙(길이 → 코드포인트)으로 가른다."""
    if not counter:
        return None
    return sorted(counter.items(), key=_prefer_name)[0][0]


def derive_codes(companies: list[dict]) -> dict[str, dict]:
    """복지 행 전부 → 코드 사전 `{code: {label, base_label, aliases, ctgr, count, amt_count}}`.

    `count` 는 행이 아니라 **회사 수**다(회사 안에서 코드는 UNIQUE 라 같지만, 뜻이 다르다).
    """
    names: dict[str, Counter] = {}
    ctgrs: dict[str, Counter] = {}
    comps: dict[str, set] = {}
    amts: dict[str, int] = {}
    for c in companies:
        for b in marks.countable(c):  # 표시 행(법정 · 업무 교육)은 칩 수 · 매칭에서 뺀다(SP-MARK)
            code = b.get("benefit_cd")
            if not code:
                continue  # BENEFIT_CD 는 NOT NULL — 없는 행은 검색의 축이 없어 건너뛴다
            names.setdefault(code, Counter())[b.get("benefit_nm")] += 1
            ctgrs.setdefault(code, Counter())[b.get("benefit_ctgr_cd")] += 1
            comps.setdefault(code, set()).add(c["comp_id"])
            amts.setdefault(code, 0)
            if not b.get("qual_yn") and b.get("benefit_amt"):
                amts[code] += 1

    out: dict[str, dict] = {}
    for code, cnt in names.items():
        base = _most_common(cnt) or code
        out[code] = {
            "code": code,
            "base_label": base,
            "label": base,
            "aliases": [nm for nm, _ in sorted(cnt.items(), key=_prefer_name)],
            "ctgr": _most_common(ctgrs[code]) or "",
            "count": len(comps[code]),
            "amt_count": amts[code],
        }
    return _disambiguate(out)


def _disambiguate(codes: dict[str, dict]) -> dict[str, dict]:
    """같은 대표 이름을 쓰는 코드의 표시명을 갈라 준다 — override 우선, 없으면 별칭 병기."""
    groups: dict[str, list] = {}
    for info in codes.values():
        groups.setdefault(info["base_label"], []).append(info)
    for group in groups.values():
        if len(group) < 2:
            continue
        for info in group:
            if info["code"] in LABEL_OVERRIDE:
                continue
            alias = next((a for a in info["aliases"] if a != info["base_label"]), None)
            info["label"] = f"{info['base_label']} · {alias or info['code']}"
    for code, label in LABEL_OVERRIDE.items():
        if code in codes:
            codes[code]["label"] = label
    return codes
