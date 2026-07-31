#!/usr/bin/env python3
"""infra/tools/make_favicon.py — 파비콘 래스터 산출물 생성(수동 실행).

    python3 infra/tools/make_favicon.py

산출: `web/favicon.ico`(16·32 PNG-in-ICO) · `web/assets/img/apple-touch-icon.png`(180).

## 왜 스크립트인가

이 호스트에는 Pillow·ImageMagick·rsvg 가 **하나도 없다**(2026-07-31 확인). 그래서 SVG 를
래스터로 변환할 수 없고, 표준 라이브러리(`zlib`·`struct`)만으로 직접 그린다.

⚠ **`web/assets/img/favicon.svg` 와 같은 도형을 두 번 정의한다**(벡터 1회, 래스터 1회).
   원리적으로 어긋날 수 있는 구조다. 둘을 한 파일로 합칠 방법이 없으니(SVG 파서를 새로
   쓰지 않는 한), 대신 **도형 수치를 아래 한 곳에 모아** 두고 SVG 를 고칠 땐 여기도 함께
   고치도록 주석으로 못박는다. 산출물은 커밋되므로 재생성은 디자인이 바뀔 때만 한다.

## 왜 PNG-in-ICO 인가

ICO 컨테이너는 BMP 또는 PNG 를 담을 수 있다. PNG 쪽이 알파를 그대로 쓰고 크기도 작으며
현대 브라우저가 전부 지원한다(Vista/IE11 이후). BMP 는 마스크 비트맵을 따로 만들어야 한다.
"""
from __future__ import annotations

import math
import pathlib
import struct
import zlib

ROOT = pathlib.Path(__file__).resolve().parents[2]

# ── 도형 정의 (32 단위 좌표계) — `web/assets/img/favicon.svg` 와 **같은 값**이어야 한다 ──
TILE_RADIUS = 7.0
TILE_RGB = (0x2F, 0x7D, 0x43)  # --brand 진초록
#   (cx, cy, rx, ry, 회전도, 위쪽색, 아래쪽색)  — 그리는 순서 = 뒤에 오는 것이 위에 얹힌다
LEAVES = [
    (9.2, 18.6, 2.9, 7.4, -24.0, (0xBF, 0xE2, 0x73), (0x7A, 0xB6, 0x3F)),
    (22.8, 18.6, 2.9, 7.4, 24.0, (0xBF, 0xE2, 0x73), (0x7A, 0xB6, 0x3F)),
    (16.0, 15.2, 3.6, 9.6, 0.0, (0xD3, 0xEF, 0x93), (0x8B, 0xC3, 0x4A)),
]

SS = 4  # 서브샘플 배율(변당). 16px 아이콘은 계단이 그대로 보이므로 안티에일리어싱이 필수다.


def _lerp(a: int, b: int, t: float) -> int:
    return round(a + (b - a) * max(0.0, min(1.0, t)))


def _sample(x: float, y: float) -> tuple[int, int, int, int] | None:
    """단위 좌표(0~32)의 한 점 색. 타일 밖이면 None(투명)."""
    # 둥근 사각 타일
    r = TILE_RADIUS
    cx = min(max(x, r), 32 - r)
    cy = min(max(y, r), 32 - r)
    if (x - cx) ** 2 + (y - cy) ** 2 > r * r:
        return None
    color = TILE_RGB
    # 잎(회전 타원) — 뒤 항목이 위에 얹히도록 순서대로 덮어쓴다
    for lx, ly, rx, ry, deg, top, bot in LEAVES:
        a = math.radians(-deg)  # 화면 좌표를 잎의 로컬 좌표로 되돌린다
        dx, dy = x - lx, y - ly
        ux = dx * math.cos(a) - dy * math.sin(a)
        uy = dx * math.sin(a) + dy * math.cos(a)
        if (ux / rx) ** 2 + (uy / ry) ** 2 <= 1.0:
            t = (uy + ry) / (2 * ry)  # 로컬 세로 그라디언트(SVG 의 transform 과 같은 순서)
            color = tuple(_lerp(top[i], bot[i], t) for i in range(3))
    return (*color, 255)


def render(size: int) -> bytes:
    """size×size RGBA 바이트열."""
    out = bytearray()
    step = 32.0 / (size * SS)
    for py in range(size):
        for px in range(size):
            acc = [0, 0, 0, 0]
            for sy in range(SS):
                for sx in range(SS):
                    x = (px * SS + sx + 0.5) * step
                    y = (py * SS + sy + 0.5) * step
                    s = _sample(x, y)
                    if s:
                        for i in range(4):
                            acc[i] += s[i]
            n = SS * SS
            alpha = acc[3] // n
            if alpha == 0:
                out += b"\x00\x00\x00\x00"
                continue
            # 커버된 서브픽셀의 평균색(투명 서브픽셀이 색을 어둡게 끌어내리지 않게 alpha 로 나눈다)
            cov = acc[3] // 255
            out += bytes([acc[0] // cov, acc[1] // cov, acc[2] // cov, alpha])
    return bytes(out)


def png(size: int, rgba: bytes) -> bytes:
    def chunk(tag: bytes, data: bytes) -> bytes:
        return (struct.pack(">I", len(data)) + tag + data
                + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF))

    raw = b"".join(b"\x00" + rgba[y * size * 4:(y + 1) * size * 4] for y in range(size))
    return (b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw, 9))
            + chunk(b"IEND", b""))


def ico(sizes: list[int]) -> bytes:
    """PNG-in-ICO. 항목 폭/높이 0 은 256 을 뜻한다(우린 16·32 라 해당 없음)."""
    images = [png(s, render(s)) for s in sizes]
    header = struct.pack("<HHH", 0, 1, len(images))
    offset = len(header) + 16 * len(images)
    entries, blobs = b"", b""
    for s, img in zip(sizes, images):
        entries += struct.pack("<BBBBHHII", s, s, 0, 0, 1, 32, len(img), offset)
        offset += len(img)
        blobs += img
    return header + entries + blobs


def main() -> int:
    icon = ROOT / "web" / "favicon.ico"
    icon.write_bytes(ico([16, 32]))
    touch = ROOT / "web" / "assets" / "img" / "apple-touch-icon.png"
    touch.write_bytes(png(180, render(180)))
    print(f"  {icon.relative_to(ROOT)}  {icon.stat().st_size}B (16·32)")
    print(f"  {touch.relative_to(ROOT)}  {touch.stat().st_size}B (180)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
