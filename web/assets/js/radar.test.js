// web/assets/js/radar.test.js — 렌더러 둘의 **바이트 일치** 골든 테스트 (SP-CMP-4·10).
//
// `generator/tests/test_radar.py` 가 만든 픽스처를 읽어, 같은 입력에서 JS 산출물이 Python 산출물과
// 글자 하나까지 같은지 본다. 조각(points)만 걸지 않고 **SVG 문자열 전체**를 거는 이유는 순서·공백·
// 속성 표기가 새는 것도 드리프트이기 때문이다 — 그림은 멀쩡해 보이고 diff 만 커진다.
//
// 픽스처가 없거나 낡았으면 Python 쪽에서 다시 뽑는다(그쪽 파일 머리 참조). 여기서 기대값을
// 고치지 마라 — 그 순간 이 테스트는 "JS 가 옳다"를 자기 자신에게 확인하는 것이 된다.
import test, { describe } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

import {
  radarPairSvg, poly, pt, sector, fmt, readout, f1, esc,
  VIEWBOX_PAIR, BAND_DEFAULT, RINGS, CX, CY, R,
} from './radar.js';

const GOLDEN = JSON.parse(readFileSync(
  new URL('../../../generator/tests/data/radar_pair_cases.json', import.meta.url), 'utf8'));

describe('SP-CMP-4 골든 — Python 과 바이트 일치', () => {
  test('픽스처가 다섯 함정을 다 싣고 있다(케이스를 줄이면 잡던 것이 안 잡힌다)', () => {
    assert.deepEqual(GOLDEN.cases.map((c) => c.name),
      ['naver_kakao', 'all_zero', 'all_tie', 'quarter_rounding', 'escape']);
  });

  test('기본 판독 띠 문구가 두 언어에서 같다', () => {
    assert.equal(BAND_DEFAULT, GOLDEN.band_default);
  });

  for (const c of GOLDEN.cases) {
    test(`${c.name}: SVG 문자열 전체가 같다 — ${c.why}`, () => {
      const out = radarPairSvg(c.counts_a, c.counts_b, c.avgs, c.labels, c.rmax, c.a_nm, c.b_nm);
      assert.equal(out, c.svg);
    });

    test(`${c.name}: points 문자열(도형·평균·고리·축·부채꼴)이 같다`, () => {
      const rmax = c.rmax_effective;
      const n = c.labels.length;
      assert.equal(poly(c.counts_a, rmax), c.points.a, 'A 도형');
      assert.equal(poly(c.counts_b, rmax), c.points.b, 'B 도형');
      assert.equal(poly(c.avgs, rmax), c.points.avg, '평균 점선');
      assert.deepEqual(
        RINGS.filter((k) => k <= rmax).map((k) => poly(Array(n).fill(k), rmax)),
        c.points.rings, '눈금 고리',
      );
      assert.deepEqual(
        Array.from({ length: n }, (_, i) => pt(i, rmax, n, rmax).map(f1)),
        c.points.axes, '축 끝점',
      );
      assert.deepEqual(
        Array.from({ length: n }, (_, i) => sector(i, n)),
        c.points.sectors, '히트 부채꼴',
      );
    });

    test(`${c.name}: 축별 판독문이 같다`, () => {
      const lines = c.labels.map((lb, i) => readout(
        lb, c.counts_a[i], c.counts_b[i], c.avgs[i], c.a_nm, c.b_nm));
      assert.deepEqual(lines, c.readouts);
    });
  }
});

// ── 갈리는 두 지점을 따로 못 박는다 ─────────────────────────────────────────
//
// 골든이 이미 잡지만, 깨졌을 때 **어디가 왜** 깨졌는지 이 두 묶음이 말해 준다.

describe('SP-CMP-4 f1 — .1f 는 파이썬 규칙을 따른다', () => {
  test('정확히 x.25 면 내린다 — toFixed 는 여기서 올려 버린다', () => {
    assert.equal(f1(151.25), '151.2');
    assert.equal((151.25).toFixed(1), '151.3'); // 왜 손으로 맞춰야 했는지의 증거
    assert.equal(f1(1.25), '1.2');
    assert.equal(f1(0.25), '0.2');
  });

  test('정확히 x.75 면 두 방식이 같은 답을 준다(짝수 쪽 = 올림)', () => {
    assert.equal(f1(183.75), '183.8');
    assert.equal(f1(0.75), '0.8');
  });

  test('이진수로 안 떨어지는 값은 손대지 않는다 — 이미 한쪽으로 기울어 있다', () => {
    assert.equal(f1(1.05), (1.05).toFixed(1));
    assert.equal(f1(2.15), (2.15).toFixed(1));
    assert.equal(f1(187.5525), '187.6');
  });

  test('정수·한 자리 소수는 .0 을 붙인다(파이썬과 같은 폭)', () => {
    assert.equal(f1(74), '74.0');
    assert.equal(f1(139), '139.0');
  });
});

describe('SP-CMP-4 esc — 파이썬 html.escape 와 같은 치환', () => {
  test("작은따옴표는 &#x27; 다 — dom.js 의 &#39; 가 아니다", () => {
    assert.equal(esc(`a'b`), 'a&#x27;b');
  });

  test('회사명의 & 와 태그가 새지 않는다(삼성E&A 가 실제로 있다)', () => {
    assert.equal(esc('삼성E&A'), '삼성E&amp;A');
    assert.equal(esc('<b>"x"</b>'), '&lt;b&gt;&quot;x&quot;&lt;/b&gt;');
  });

  test('그려진 SVG 안에 날 태그가 남지 않는다', () => {
    const svg = radarPairSvg([1, 1, 1], [1, 1, 1], [1, 1, 1], ['가', '나', '다'], 8,
      '<script>alert(1)</script>', '삼성E&A');
    assert.ok(!svg.includes('<script>'), '회사명이 태그로 빠져나갔다');
    assert.ok(svg.includes('&lt;script&gt;'));
    assert.ok(svg.includes('삼성E&amp;A'));
  });
});

// ── 계약(값이 아니라 규칙) ──────────────────────────────────────────────────

describe('SP-CMP-3 결측 표기 — 0 은 어디서나 「등록 없음」', () => {
  test('fmt 는 숫자 0 을 화면에 내보내지 않는다', () => {
    assert.equal(fmt(0), '등록 없음');
    assert.equal(fmt(null), '등록 없음');
    assert.equal(fmt(undefined), '등록 없음');
    assert.equal(fmt(7), '7항목');
  });

  test('양쪽 0 인 축은 「등록 없음」을 두 번 말하지 않는다', () => {
    assert.equal(readout('근무환경', 0, 0, 0.65, '가', '나'), '근무환경 — 양쪽 등록 없음 · 평균 0.7');
  });

  test('그림 어디에도 「0항목」이 없다', () => {
    const svg = radarPairSvg([0, 0, 0], [0, 1, 0], [0, 0, 0], ['가', '나', '다'], 8, 'A', 'B');
    assert.ok(!svg.includes('0항목'));
    assert.ok(svg.includes('등록 없음'));
  });
});

describe('SP-CMP-4 기하·구조', () => {
  test('기하 상수가 Python 과 같다 — 하나만 어긋나도 같은 회사가 두 화면에서 다른 모양이 된다', () => {
    assert.deepEqual([CX, CY, R, RINGS], [200, 200, 130, [2, 4, 6, 8]]);
    assert.equal(VIEWBOX_PAIR, '0 34 416 356');
  });

  test('축 아홉 개가 탭으로 닿고 각자 이름을 갖는다', () => {
    const svg = radarPairSvg(
      [1, 2, 3, 4, 5, 6, 7, 8, 9], Array(9).fill(1), Array(9).fill(1),
      ['가', '나', '다', '라', '마', '바', '사', '아', '자'], 9, 'A', 'B');
    const hits = svg.match(/class="rdp-hit" tabindex="0" role="img" aria-label="/g) || [];
    assert.equal(hits.length, 9);
  });

  test('동값 축은 A 원이 속 빈 링이다 — 꽉 찬 원은 B 네모를 통째로 덮는다', () => {
    const svg = radarPairSvg([2, 3, 2], [2, 1, 2], [1, 1, 1], ['가', '나', '다'], 8, 'A', 'B');
    assert.equal((svg.match(/class="rdp-da rdp-tie"/g) || []).length, 2);
    assert.equal((svg.match(/class="rdp-da"/g) || []).length, 1);
  });

  test('rmax 가 0 이어도 죽지 않는다(고리·눈금이 빠지고 도형은 중심에 모인다)', () => {
    const svg = radarPairSvg([0, 0, 0], [0, 0, 0], [0, 0, 0], ['가', '나', '다'], 0, 'A', 'B');
    assert.ok(!svg.includes('rdp-ring') && !svg.includes('rdp-tick'));
    assert.equal((svg.match(/class="rdp-ax"/g) || []).length, 3);
  });

  test('길이가 어긋나면 그리지 않고 던진다 — 조용히 틀린 그림이 이 프로젝트의 반복 함정이다', () => {
    assert.throws(() => radarPairSvg([1, 2, 3], [1, 2], [1, 1, 1], ['가', '나', '다'], 8));
    assert.throws(() => radarPairSvg([1, 2], [1, 2], [1, 1], ['가', '나'], 8)); // 축 3 미만
  });

  test('그림 넓이를 점수로 바꾸는 어휘가 없다(D-6)', () => {
    const svg = radarPairSvg([8, 8, 8], [0, 0, 0], [1, 1, 1], ['가', '나', '다'], 8, 'A', 'B');
    for (const banned of ['우세', '더 낫다', '이김', '점수']) assert.ok(!svg.includes(banned), banned);
  });
});
