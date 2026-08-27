# 2026-08-27 — 레인 B: 터치 기기 롤링 오조준 수정

브랜치 `lane/fe-touch-rolling`. 대상은 HANDOFF-2026-07-31 §3-7 (2026-07-31 신설, 미해소).
(파일명 날짜는 세션 브리프가 지정한 `2026-08-26-lane-b-touch.md` 그대로 뒀다 — 실제 작업일은 08-27.)

## 한 일

**red → green (TDD).** 먼저 실패하는 테스트 8개를 쓰고(7개 red — 나머지 1개는
데스크톱 회귀 가드라 처음부터 green) `trending.js` 를 고쳤다. 697 → 705 green.

- `web/assets/js/trending.js` — `isHoverless()` 추가(`matchMedia('(hover: none)')`),
  `pinnedOpen` 플래그로 롤링 차단 + 처음부터 `.trend-expanded`,
  `pointerdown[pointerType='touch']` 로 하이브리드 기기 런타임 잠금,
  반환값에 `rolling` 추가.
- `web/assets/js/trending.test.js` — 터치 6 + 하이브리드 3 케이스, `setPrimaryInput()`
  헬퍼, `loadDom()` 에 `delete globalThis.matchMedia`(스텁 누수 차단).
- `docs/PITFALLS/_incoming/jsdom-matchmedia-absent-device-branch-untested.md`

## 고른 해법과 이유

핸드오프 §3-7 의 후보 3개 중 **"터치에서는 처음부터 펼친 목록으로 렌더"**.

- **원인과 판정 기준이 같다.** 결함의 성립 조건은 "롤링을 멈출 호버가 없다"이므로
  `(hover: none)` 이 바로 그 조건이다. `(pointer: coarse)` 는 한 다리 건넌 근사다.
- **과녁을 없앤다.** "롤링만 정지"(후보 1)는 접힘 행 1개에 사용자를 가둔다 — 터치에는
  펼칠 수단이 없어 10개 중 9개가 영영 도달 불가다(이게 오조준보다 큰 손실이었다).
- **`pointerdown` 고정(후보 2)은 ㉠을 못 막는다.** 행을 읽고 손가락이 내려가는 반응
  시간 사이의 교체는 pointerdown 보다 먼저 일어난다. 다만 하이브리드(터치 되는 노트북,
  주 입력이 마우스라 `(hover: none)` 에 안 걸림) 보완으로는 정확히 맞아서 그쪽에만 썼다.
- **회귀 위험이 낮다.** 데스크톱 경로는 한 줄도 안 바뀌고, CSS 는 이미 있는
  `.trend-expanded` 를 그대로 쓴다(`styles.css` 무수정 — 핫스팟 미접촉).
  `app.js` 는 반환값을 안 쓴다(핫스팟 미접촉). 추가 필드는 순수 가산.

## 테스트가 재현하는 것

1. **㉠ 읽은 조합 ≠ 탭이 도달한 조합** — `(hover: none)` 에서 `ROTATE_MS * 2` 경과 후
   `.trend-current` 내용이 바뀌면 실패.
2. **㉡ 탭이 통째로 사라진다** — 누르고 있던 노드가 `replaceChildren` 으로 교체되면
   `host.contains(target)` 이 거짓이 되고 그 노드의 click 은 발생하지 않는다.
   (이번 결함은 Playwright 클릭이 같은 이유로 타임아웃 나며 드러났다 — 도구가 먼저 밟았다.)
3. 터치 = 처음부터 10개 전부 탭 가능 · `rolling: false` · 폴백(제안) 모드도 동일.
4. 합성 `mouseleave` 가 잠금을 풀지 않는다(모바일 브라우저가 보내기도 한다).
5. 하이브리드: touch `pointerdown` 이 그 자리에서 잠근다 / mouse `pointerdown` 은 무해.
6. 데스크톱 회귀 가드: `(hover: hover)` 에서 접힘 + 롤링 그대로.

## 알게 된 것

**jsdom 에는 `matchMedia` 가 없다** — 그래서 `prefersReducedMotion()` 은 만들어진
2026-07 이후 **참 쪽 분기가 한 번도 실행된 적이 없다.** 기기 분기는 명시적으로 스텁하지
않으면 "테스트가 있어도 없는 것"이다. 이 결함이 4주간 초록불 아래에서 살아남은 이유다
(→ `PITFALLS/_incoming/jsdom-matchmedia-absent-device-branch-untested.md`).

## 남긴 것 (범위 밖 — 다른 레인/후속)

- `STATE.md` 운영 미결 행의 "터치 롤링 오조준" 삭제 — 핫스팟이라 건드리지 않았다.
  머지 후 누군가 지워야 한다.
- 실기기 검증 없음(서버 접속 금지). jsdom + 미디어 쿼리 스텁까지가 이 레인의 한계다.
- `prefersReducedMotion()` 참 쪽 분기는 여전히 미검증 — 같은 `setPrimaryInput` 관례로
  덮을 수 있다(이번 범위 밖).
