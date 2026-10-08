"""generator/content/guide_report_editions.py — A편 **판별 문안** (SP-GUIDE-7, 2026-10-08, 리드 판정 (87) M-4).

판마다 다른 사실에 기대는 문장만 판 키로 묶는다. 공통 문장은 `content/guide_report.py`. 규칙은 거기와 같다 — 숫자는 `{자리표시}`,
수량어 금지. **새 판을 낼 때**: 이 dict 에 새 판 키를 더하고, 그 판 스냅숏의 gap 항목을 보고 `gap_codes` · 묘사 · 상자 · 자녀 학자금 문장을 새로 판정한다.
옛 판 항목은 건드리지 않는다(옛 판 페이지가 바뀌면 안 된다).

`gap_codes` 는 이 판의 묘사가 **어느 항목을 보고 쓴 것인지**다. 스냅숏의 gap 항목이 이것과 다르면 빌드가 멈춘다(조용히 틀린 묘사를 싣지 않는다).
"""
from __future__ import annotations

EDITIONS: dict[str, dict] = {
    "2026-10": {
        "gap_codes": {
            "mid_more": ("meal", "snack_bar", "holiday_gift", "excellence_award", "lounge"),
            "large_more": ("childcare", "mental", "medical", "housing_loan", "parenting"),
        },
        # 숫자 카드 4 — (이름, 값, 보조)
        "cards": (
            ("가장 흔한 복지", "{top1_label}", "{N}곳 중 {top1_n}곳({top1_pct}%)"),
            ("금액이 회사 공식 수치인 복지", "{st_pct}%", "{counted}건 중 {st_n}건"),
            ("등록된 금액이 하나도 없는 회사", "{zero_amt}곳", "{N}곳 중"),
            ("절반 넘는 회사가 공개한 복지", "{half}가지", ""),
        ),
        "half_edu": (
            "이직 후보 두 곳이 모두 이 목록의 복지를 적어 두었다면, 차이는 이름이 아니라 금액과 조건에서 납니다. "
            "같은 「자녀 학자금」이라도 유치원부터 대학교까지 지원한다고 밝힌 곳이 있고, 대학교 학자금만 적은 곳이 있습니다."
        ),
        "gap_read": (
            "중견기업은 {mid_labels}처럼 회사에서 날마다 누리거나 명절·포상 때 받는 복지를 더 자주 공개했습니다. "
            "대기업은 {large_labels}처럼 아이를 낳아 키울 때, 몸이나 마음이 아플 때, 집을 마련할 때 받쳐 주는 복지를 더 자주 공개했습니다. "
            "공개한 복지 수는 대기업이 중앙값 {med_large}개, 중견기업이 {med_mid}개입니다. "
            "중견기업은 더 적게 공개하면서도 중견기업 쪽 다섯 항목은 대기업보다 더 자주 적었습니다."
        ),
        "gap_box": (
            "이 차이는 「공개한 목록」의 차이입니다. 예를 들어 식대를 공개한 대기업이 {meal_large_pct}%라고 해서 "
            "나머지 대기업이 식대를 주지 않는다는 뜻은 아닙니다. 왜 이렇게 갈리는지는 이 데이터만으로 알 수 없습니다. "
            "사내 어린이집처럼 일정 규모 이상 사업장에 설치 의무가 있는 제도도 있어, 이 차이를 공개 성향만으로 읽기는 어렵습니다."
        ),
    },
}


def for_edition(edition: str) -> dict:
    """판별 문안 — 없으면 빌드가 멈춘다(문안 없는 판을 조용히 다른 판 문장으로 그리지 않는다)."""
    try:
        return EDITIONS[edition]
    except KeyError:
        raise KeyError(f"A편 판별 문안이 없는 판: {edition} — content/guide_report_editions.py 에 판 키를 더해라") from None
