"""P3-② — `verify_mail.py` 의 호스트별 메일 모드 계약 (MV-1~MV-5).

**왜 이 파일이 있나**: 구 검증기는 `server/.env` 만 읽고 `mailer_mode != 'smtp'` 를 실패로 봤다.
그래서 "베타는 실발송하면 **안 된다**"라는 반대 방향 불변식을 표현할 수조차 없었고, 베타가 prod
자격증명을 상속해 prod 발신 도메인·무료 티어 쿼터를 쓰는 동안에도 검증기는 초록이었다.
**표현할 수 없는 계약은 지켜지지 않는다.**

MV-4 가 핵심이다 — 결함을 심어 검증기가 실제로 빨개지는지 확인한다(함정 ㉔: 통과만 보는
어서션은 통과하는 이유를 구분하지 못한다).
"""

from __future__ import annotations

import importlib.util
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
VERIFY_MAIL = ROOT / "infra" / "deploy" / "verify_mail.py"
ENV_BETA = ROOT / "server" / ".env.beta"


@pytest.fixture(scope="module")
def vm():
    spec = importlib.util.spec_from_file_location("verify_mail", VERIFY_MAIL)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


# ── MV-1: EnvironmentFile 해석이 systemd 와 같아야 한다 ────────────────────
def test_MV1_environment_file_parsing(vm, tmp_path):
    p = tmp_path / "x.env"
    p.write_text(
        "# 주석\n"
        "\n"
        "MAILER_MODE=console\n"
        "  SPACED = value  \n"
        "QUOTED='q'\n"
        'DQUOTED="d"\n'
        "# MAILER_MODE=smtp   ← 주석 처리된 값은 무시돼야 한다\n"
        "WITH_EQ=a=b\n",
        encoding="utf-8",
    )
    got = vm.load_environment_file(p)
    assert got["MAILER_MODE"] == "console"
    assert got["SPACED"] == "value"
    assert got["QUOTED"] == "q"
    assert got["DQUOTED"] == "d"
    assert got["WITH_EQ"] == "a=b", "값 안의 '=' 를 잘라먹으면 자격증명이 조용히 망가진다"
    assert len(got) == 5, f"주석·빈 줄이 섞여 들어왔다: {sorted(got)}"


# ── MV-2: 호스트별 기대값이 선언돼 있다(정책 핀) ───────────────────────────
def test_MV2_host_policy_is_declared(vm):
    """prod 는 실발송, beta 는 실발송 금지. 이 표가 정책 자체다.

    누군가 beta 를 smtp 로 되돌리면 이 테스트가 빨개져 **의도를 밝히도록 강제**한다
    (prod 발신 도메인·무료 티어 쿼터 공유가 그때 함께 돌아온다).
    """
    assert vm.HOSTS["prod"]["expect"] == "smtp"
    assert vm.HOSTS["beta"]["expect"] == "console"
    assert vm.HOSTS["prod"]["env_file"] is None, "prod 는 오버레이 없이 server/.env 그대로다"
    assert vm.HOSTS["beta"]["env_file"].name == ".env.beta"


# ── MV-3: 알 수 없는 호스트는 거부 ────────────────────────────────────────
def test_MV3_unknown_host_rejected(vm, monkeypatch, capsys):
    monkeypatch.setattr(vm.sys, "argv", ["verify_mail.py", "--host", "staging"])
    assert vm.main() == 2
    assert "--host" in capsys.readouterr().out


# ── MV-4: 베타가 실발송 모드면 반드시 빨개진다(뮤테이션) ───────────────────
def test_MV4_beta_in_send_mode_is_caught(vm, monkeypatch, tmp_path, capsys):
    """베타의 유효 설정이 `smtp` 로 합성되면 검증기가 잡아야 한다.

    운영에서 이 상태에 이르는 경로는 `.env.beta` 에 `MAILER_MODE` 가 **없어서 prod 의
    `server/.env` 를 상속**하는 것이다. 다만 pytest 안에서는 conftest 가 실메일을 막으려고
    `MAILER_MODE=console` 을 강제하므로 그 상속 자체를 재현할 수 없다 — 그래서 **결과 상태를
    직접 심어** 판정을 검사한다. 어떤 경로로 왔든 "베타 = 실발송"은 실패여야 한다.

    ⚠ `monkeypatch.setenv` 를 먼저 걸어두는 이유: `main()` 이 `os.environ.update()` 로 값을
    덮는데, monkeypatch 가 원래 값을 기억해 두면 그 뒤 어떻게 바뀌든 teardown 에서 되돌린다.
    안 그러면 이 테스트가 뒤따르는 테스트의 메일 모드를 오염시킨다.
    """
    monkeypatch.setenv("MAILER_MODE", "console")  # 원복 지점 확보(값 자체는 아래에서 덮인다)

    inherited = tmp_path / "beta-inherited.env"
    inherited.write_text("DB_NAME=loupit_beta\nM9_ENABLED=1\nMAILER_MODE=smtp\n", encoding="utf-8")
    monkeypatch.setitem(vm.HOSTS["beta"], "env_file", inherited)
    monkeypatch.setattr(vm.sys, "argv", ["verify_mail.py", "--host", "beta"])

    assert vm.main() == 1, "베타가 실발송 모드인데 초록으로 지나쳤다 — 가드가 무의미하다"
    out = capsys.readouterr().out
    assert "console" in out, "기대값이 무엇인지 밝혀야 고칠 수 있다"
    assert "쿼터" in out or "상속" in out, "실패 이유가 원인을 지목해야 한다"


# ── MV-4b: 발송 대상을 준 것 자체가 모순이다 ───────────────────────────────
def test_MV4b_send_target_on_nonsending_host_is_rejected(vm, monkeypatch, tmp_path, capsys):
    """`--host beta you@example.com` 은 조용히 무시하면 안 된다 — 의도가 어긋난 것이다."""
    monkeypatch.setenv("MAILER_MODE", "console")
    beta = tmp_path / "beta.env"
    beta.write_text("MAILER_MODE=console\n", encoding="utf-8")
    monkeypatch.setitem(vm.HOSTS["beta"], "env_file", beta)
    monkeypatch.setattr(vm.sys, "argv", ["verify_mail.py", "--host", "beta", "you@example.com"])

    assert vm.main() == 1
    assert "모순" in capsys.readouterr().out


# ── MV-5: 라이브 `.env.beta` 가 자기 메일 모드를 소유한다 ──────────────────
def test_MV5_live_beta_owns_its_mailer_mode():
    """`.env.beta` 는 미커밋 파일이라 이 검사는 **운영 머신에서만** 성립한다.

    파일이 없거나(다른 체크아웃) 읽을 수 없으면(root 소유 600) 건너뛴다 — 그 경우
    "베타 없음"이지 "계약 위반"이 아니다.
    """
    if not ENV_BETA.exists():
        pytest.skip(".env.beta 없음 — 이 체크아웃엔 beta 배치가 없다")
    try:
        text = ENV_BETA.read_text(encoding="utf-8")
    except PermissionError:
        pytest.skip(".env.beta 를 읽을 권한이 없다(root 600) — sudo 로 실행해야 검사된다")

    declared = [
        ln for ln in text.splitlines()
        if ln.strip().startswith("MAILER_MODE") and "=" in ln
    ]
    assert declared, (
        "`.env.beta` 에 MAILER_MODE 가 없다 — prod 의 server/.env 를 상속해 "
        "prod 발신 도메인·무료 티어 쿼터를 나눠 쓰게 된다(P3-②)."
    )
    assert declared[0].split("=", 1)[1].strip() == "console", (
        f"베타가 실발송 모드다: {declared[0]!r}. 의도한 변경이면 MV-2 도 함께 고쳐라."
    )
