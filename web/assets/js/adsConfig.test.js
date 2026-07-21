// web/assets/js/adsConfig.test.js — SP-ADS-2 설정 단일 진실 단위 테스트.
// 근거: SPEC/08-광고-제휴-통합.md §SP-ADS-2, TASK/08-광고제휴.md T-08.2.1·2.2.
// 순수 상수·순수 판별 함수만 다룬다(import 0 모듈) — 브라우저 스텁 불필요.
import test, { describe } from 'node:test';
import assert from 'node:assert/strict';

import {
  adsConfig, isPlaceholder, AD_SLOT_PLACEHOLDER, AD_CLIENT_PLACEHOLDER,
  SLOT_ID_MAP, SLOT_RESERVE, AD_LABEL_TEXT,
} from './adsConfig.js';

// ── T-08.1.1: 공개 심볼 존재(구조 스모크) ───────────────────────────────────
describe('T-08.1.1 adsConfig 모듈 골격 스모크', () => {
  test('공개 심볼 전량 export', () => {
    assert.equal(typeof adsConfig, 'object');
    assert.equal(typeof isPlaceholder, 'function');
    assert.equal(typeof AD_SLOT_PLACEHOLDER, 'string');
    assert.equal(typeof AD_CLIENT_PLACEHOLDER, 'string');
    assert.equal(typeof SLOT_ID_MAP, 'object');
    assert.equal(typeof SLOT_RESERVE, 'object');
    assert.equal(typeof AD_LABEL_TEXT, 'string');
  });
});

// ── T-08.2.1: adsConfig 상수 블록·SLOT_ID_MAP·SLOT_RESERVE·AD_LABEL_TEXT ────
describe('T-08.2.1 adsConfig 설정 구조 스모크', () => {
  test('AD_CLIENT는 실 게시자 ID(2026-07-21 애드센스 활성화, isPlaceholder=false)', () => {
    // 2026-07-21 pub-id 발급으로 플레이스홀더 → 실값 치환(§B-3 단계 2). 공개값이라 리포 노출 무방.
    // 슬롯은 여전히 플레이스홀더(승인 후 발급) — 그래서 수동 슬롯은 아직 억제된다(ads.js 가드).
    assert.notEqual(adsConfig.AD_CLIENT, AD_CLIENT_PLACEHOLDER);
    assert.equal(isPlaceholder(adsConfig.AD_CLIENT), false, '실값이면 로더 주입 경로 활성');
    assert.match(adsConfig.AD_CLIENT, /^ca-pub-\d{16}$/, 'ca-pub- + 16자리 형식');
  });

  test('AUTO_ADS=true, DENY_FALLBACK=nonpersonalized(기본값)', () => {
    assert.equal(adsConfig.AUTO_ADS, true);
    assert.equal(adsConfig.DENY_FALLBACK, 'nonpersonalized');
  });

  test('AD_SLOT 6키 전부 초기 플레이스홀더', () => {
    assert.deepEqual(Object.keys(adsConfig.AD_SLOT).sort(), [
      'combo_bottom', 'combo_mid', 'company_bottom', 'company_mid', 'landing_bottom', 'result_bottom',
    ]);
    for (const v of Object.values(adsConfig.AD_SLOT)) assert.equal(v, AD_SLOT_PLACEHOLDER);
  });

  test('SLOT_ID_MAP의 각 위치값이 adsConfig.AD_SLOT 키에 존재(정합)', () => {
    for (const positions of Object.values(SLOT_ID_MAP)) {
      for (const slotKey of Object.values(positions)) {
        assert.ok(Object.prototype.hasOwnProperty.call(adsConfig.AD_SLOT, slotKey),
          `SLOT_ID_MAP이 참조하는 슬롯 키 '${slotKey}'가 adsConfig.AD_SLOT에 없음`);
      }
    }
  });

  test('SLOT_ID_MAP 배치 표 1:1(FRD 09 정본) — 위치·키 창작 금지', () => {
    assert.deepEqual(SLOT_ID_MAP, {
      landing: { content_bottom: 'landing_bottom' },
      company: { content_mid: 'company_mid', content_bottom: 'company_bottom' },
      combo:   { content_mid: 'combo_mid',   content_bottom: 'combo_bottom' },
      result:  { report_bottom: 'result_bottom' },
    });
  });

  test('SLOT_RESERVE에 content_mid/content_bottom/report_bottom 3키', () => {
    assert.deepEqual(Object.keys(SLOT_RESERVE).sort(), ['content_bottom', 'content_mid', 'report_bottom']);
    assert.deepEqual(SLOT_RESERVE.content_mid, { mobile: 280, desktop: 280 });
    assert.deepEqual(SLOT_RESERVE.content_bottom, { mobile: 250, desktop: 250 });
    assert.deepEqual(SLOT_RESERVE.report_bottom, { mobile: 250, desktop: 250 });
  });

  test('AD_LABEL_TEXT === "광고"(공정위 표기)', () => {
    assert.equal(AD_LABEL_TEXT, '광고');
  });
});

// ── T-08.2.2: isPlaceholder 승인 전 판별 (UT-ADS-PH-1) ──────────────────────
describe('T-08.2.2 isPlaceholder (UT-ADS-PH-1)', () => {
  test('UT-ADS-PH-1: 플레이스홀더 client id → true / 실 client id → false', () => {
    assert.equal(isPlaceholder('ca-pub-XXXXXXXXXXXXXXXX'), true);
    assert.equal(isPlaceholder('ca-pub-1234567890123456'), false);
  });

  test('isPlaceholder: 빈 값·null·undefined → true(미승인 취급)', () => {
    assert.equal(isPlaceholder(''), true);
    assert.equal(isPlaceholder(null), true);
    assert.equal(isPlaceholder(undefined), true);
  });

  test('isPlaceholder: 슬롯 id 플레이스홀더(X 4자 미만은 실값 취급 — 실제 슬롯 id는 숫자 10자리)', () => {
    assert.equal(isPlaceholder('XXXXXXXXXX'), true);   // AD_SLOT_PLACEHOLDER 자체(X 10자)
    assert.equal(isPlaceholder('1234567890'), false);
  });
});
