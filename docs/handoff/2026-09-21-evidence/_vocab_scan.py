#!/usr/bin/env python3
"""_VOCAB.md 표 재생성 — 시드 SQL 전수 파싱.

    python3 _vocab_scan.py            # 표 + 검증 결과를 찍는다
    python3 _vocab_scan.py --table    # 표 본문만 (파일에 붙여넣기용)

행을 흘리면 어휘표가 조용히 틀리므로, 튜플처럼 생겼는데 못 잡은 줄을
따로 세서 0 인 것을 스스로 증명한다. 총행수는 STATE 의 복지 행수와 맞춰볼 것.
"""
import re, sys, glob, os, collections

SEED = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                    "../../../db/seed/benefit/sql")

ROW = re.compile(
    r"^\s*\(\s*@comp_id\s*,\s*'([A-Za-z0-9_]+)'\s*,\s*'((?:[^']|'')*)'\s*,\s*"
    r"(NULL|[0-9]+(?:\.[0-9]+)?)\s*,\s*'([a-z_]+)'\s*,")
ROWISH = re.compile(r"^\s*\(\s*@comp_id\s*,")
COMPID = re.compile(r"SET\s+@comp_id\s*=.*?COMP_ENG_NM\s*=\s*'([A-Za-z0-9_]+)'", re.S)


def scan():
    rows, missed = [], []
    for path in sorted(glob.glob(os.path.join(SEED, "*.sql"))):
        src = open(path, encoding="utf-8").read()
        comps = COMPID.findall(src)
        comp = comps[0] if comps else os.path.basename(path)[:-4]
        for line in src.splitlines():
            if line.lstrip().startswith("--"):      # 주석은 제외
                continue
            m = ROW.match(line)
            if m:
                code, name, amt, ctgr = m.groups()
                rows.append((comp, code, name.replace("''", "'"), amt, ctgr))
            elif ROWISH.match(line):
                missed.append((os.path.basename(path), line.strip()[:160]))
    return rows, missed


def main():
    rows, missed = scan()
    by = collections.defaultdict(lambda: {"comps": set(), "names": collections.Counter(),
                                          "ctgr": collections.Counter()})
    for comp, code, name, amt, ctgr in rows:
        d = by[code]; d["comps"].add(comp); d["names"][name] += 1; d["ctgr"][ctgr] += 1

    # n 내림차순 → 코드명. 대표 명칭도 동률이면 이름순으로 고정한다.
    # 둘 다 고정해야 재현 가능하다 — 안 그러면 내용이 안 바뀌어도 칸이 뒤집혀 가짜 diff 가 난다.
    def top_names(counter, k=3):
        return [n for n, _ in sorted(counter.items(), key=lambda kv: (-kv[1], kv[0]))[:k]]

    ordered = sorted(by.items(), key=lambda kv: (-len(kv[1]["comps"]), kv[0]))
    table = [f"| `{c}` | {len(d['comps'])} | {d['ctgr'].most_common(1)[0][0]}"
             f"{' ⚠' if len(d['ctgr']) > 1 else ''} | "
             f"{' · '.join(top_names(d['names']))} |"
             for c, d in ordered]

    if "--table" in sys.argv:
        print("\n".join(table)); return

    print("\n".join(table))
    print(f"\n── 검증 ──")
    print(f"회사 {len({r[0] for r in rows})} · 복지 {len(rows)}행 · 코드 {len(by)}종")
    print(f"파서가 놓친 줄 {len(missed)}" + ("  ← 0 이 아니면 표를 믿지 마라" if missed else "  (0 = 전수 파싱 증명)"))
    for b, l in missed[:10]:
        print("   MISS", b, l)
    split = {c: dict(d["ctgr"]) for c, d in by.items() if len(d["ctgr"]) > 1}
    print(f"카테고리 분열 {len(split)}종 — 표에 ⚠ 로 표시된다")
    for c, v in sorted(split.items(), key=lambda kv: -sum(kv[1].values())):
        print(f"   {c}: {v}")


if __name__ == "__main__":
    main()
