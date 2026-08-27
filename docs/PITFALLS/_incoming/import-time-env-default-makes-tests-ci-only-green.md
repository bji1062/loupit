# 임포트 시점에 굳는 env 기본값 — 그 위에 세운 단정은 CI 에서만 초록이다

**발견**: 2026-08-27 릴리스 `[2/5] 정적 생성물·정책` (generator 234 pass / **2 fail**)
**직전 상태**: 같은 커밋이 CI 에서 **236 pass**. 리포는 초록, 서버는 빨강.

```
FAILED test_pc12_policy_contact_env_unset_yields_real_email_default
  AssertionError: assert 'jobchocontact@gmail.com' == 'bji1062@gmail.com'
FAILED test_pc12_default_policy_values_leave_no_placeholder_braces
  assert 'bji1062@gmail.com' in '<!doctype html>...'
```

## 무엇이 잘못됐나

```python
@dataclass(frozen=True)
class GenConfig:
    policy_contact: str = os.environ.get("POLICY_CONTACT", "bji1062@gmail.com")
```

`os.environ.get(...)` 은 **클래스 본문에서 한 번 평가**된다 — 즉 모듈 임포트 시점에
값이 굳는다. 그런데 테스트는 이렇게 쓰여 있었다:

```python
def test_..._env_unset_yields_real_email_default(monkeypatch):
    monkeypatch.delenv("POLICY_CONTACT", raising=False)   # ← 아무 효과 없다
    cfg = GenConfig()
    assert cfg.policy_contact == "bji1062@gmail.com"
```

`delenv` 는 이미 굳은 기본값을 되돌리지 못한다. 그래서 이 테스트는 이름과 달리
**"임포트 시점의 env 가 비어 있었는가"** 를 검사한다. 그건 테스트가 아니라 환경 질문이다.

- CI: `POLICY_CONTACT` 미설정 → 폴백이 굳음 → 초록
- 배포 호스트: `server.env` 에 `POLICY_CONTACT=jobchocontact@gmail.com` → 그게 굳음 → 빨강

**주의**: `GenConfig` 의 docstring 은 이 사실을 이미 정확히 적어 두고 있었다
("필드 기본값은 모듈 임포트 시점의 환경변수를 읽어 고정된다"). 문서가 맞았고 테스트가
틀렸다. 문서를 읽고도 그 함의를 테스트에 적용하지 않으면 문서는 아무것도 막지 못한다.

## 왜 CI 가 못 잡았나 — 이게 핵심이다

CI 러너는 **env 가 비어 있는 상태 하나만** 재현한다. 배포 호스트는 `server.env` 를
주입한다. 두 조건이 다른데 **한쪽만 돌렸다.** 그래서 CI 초록은 "배포에서도 초록"을
뜻하지 않았다.

> 설정이 env 로 들어오는 코드는, env 가 빈 상태와 채워진 상태 **둘 다** 돌려야
> CI 가 배포를 대변한다.

## 고친 것

1. 폴백을 상수로 뽑았다 — `POLICY_CONTACT_FALLBACK` / `POLICY_LAST_MODIFIED_FALLBACK`.
   폴백 계약은 이 상수로 검증한다(env 로 오염될 수 없는 유일한 지점).
2. 렌더 단정은 특정 주소 리터럴이 아니라 **실효 설정값**(`CFG.policy_contact`)을 본다.
   운영자가 연락처를 바꾸면 테스트가 깨지는 결합을 끊는다.
3. 미치환 플레이스홀더를 일반 패턴 `\{[가-힣][^{}]*\}` 으로 검출한다 — 알려진 두 개만
   막으면 새로 생긴 플레이스홀더는 그대로 라이브로 나간다.
4. **CI 에 env 주입 실행을 한 번 더 추가**했다. 같은 스위트를 `POLICY_CONTACT` ·
   `POLICY_LAST_MODIFIED` · `SITE_ORIGIN` 을 넣고 다시 돌린다. 값이 실운영값일 필요는
   없다 — "기본값과 다르다"는 사실만으로 리터럴 결합이 드러난다.

검증 4갈래: env 없음 236 pass · env 주입 236 pass · **구판을 env 주입으로 돌리면 2 fail**
(서버 증상 재현) · 폴백을 `{운영자 연락처}` 로 뮤테이션하면 2 fail(가드가 문다).

## 함정 0075 와 같은 뿌리

0075 는 "격리 계약을 피호출자만 검증해서 호출자가 무효화했다".
이건 "폴백 계약을 env 오염 지점에서 검증해서 환경이 무효화했다".
**둘 다 검증 지점을 계약이 깨지는 곳이 아닌 편한 곳에 뒀다.** 그리고 둘 다 같은 날,
같은 릴리스에서, 연속된 단계에서 터졌다.

## 교훈

1. `os.environ.get` 을 클래스 본문·모듈 상수에 쓰면 그 값은 **임포트 시점에 굳는다**.
   `monkeypatch.delenv`·`setenv` 는 그 뒤로 무력하다.
2. 테스트가 특정 리터럴(주소·URL·날짜)을 박으면, 운영자가 그 값을 바꾸는 날 깨진다.
   **계약을 검사하라, 값을 검사하지 말고.**
3. CI 가 배포와 다른 env 로 돈다면, CI 초록은 배포 초록을 보증하지 않는다.
   차이나는 축을 최소 두 값으로 돌려라.
