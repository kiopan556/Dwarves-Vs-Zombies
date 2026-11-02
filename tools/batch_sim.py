#!/usr/bin/env python3
"""M005 batch stage simulator: runs the auto-commander stage sims for a stage range in two parallel
Godot processes (a 2-core machine runs at most two) and writes one CSV row per run.

    python3 tools/batch_sim.py --from 31 --to 60 --out build/sims_act2.csv [--godot godot] [--heroic]

Columns: stage, mode (play = auto-commander must WIN, idle = no deployments must LOSE), result,
time_s, stronghold_pct, citadel_pct, kills, losses, deployed, peak_enemies, ok, wall_ms.
Pair it with tools/auto_tune.py, which reads the CSV and suggests (never applies) tuning changes.
"""
import argparse
import csv
import os
import re
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
LINE = re.compile(r"^(PASS|FAIL) Stage (\d+) (playable\+winnable|losable).*?:: s\d+ (WIN|LOSS|TIMEOUT) in (\d+)s \| dwarf_base=(-?\d+)% "
                  r"citadel=(-?\d+)% kills=(\d+) losses=(\d+) deployed=(\d+) peak_enemies=(\d+).*?wall=(\d+)ms")


def run(godot, a, b, extra, log):
    cmd = [godot, "--headless", "--path", ROOT, "res://tests/test_runner.tscn", "--", "--suite=stages", f"--from={a}", f"--to={b}"] + extra
    return subprocess.Popen(cmd, stdout=open(log, "w"), stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--from", dest="a", type=int, required=True)
    ap.add_argument("--to", dest="b", type=int, required=True)
    ap.add_argument("--out", default=os.path.join(ROOT, "build", "sims.csv"))
    ap.add_argument("--godot", default="godot")
    ap.add_argument("--jobs", type=int, default=2)
    ap.add_argument("--quality", default="")
    ap.add_argument("--heroic", action="store_true", help="M007: play the Heroic version of each stage")
    ap.add_argument("--only", default="", help="M008: comma list of stages inside the range (re-runs after a fix)")
    ap.add_argument("--merge", default="", help="M008: CSV to update in place with this run's rows (same stage+mode replaced)")
    args = ap.parse_args()
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    stages = list(range(args.a, args.b + 1))
    if args.only:
        stages = [int(x) for x in args.only.split(",") if x.strip()]
    # split by alternating stages so both processes get early and late (heavier) stages
    chunks = [stages[i::args.jobs] for i in range(args.jobs)]
    procs, logs = [], []
    extra = [f"--quality={args.quality}"] if args.quality else []
    if args.heroic:
        extra.append("--heroic")
    for j, ch in enumerate(chunks):
        if not ch:
            continue
        log = os.path.abspath(args.out) + f".job{j}.log"
        logs.append(log)
        # the runner takes a contiguous range; run each stage of the chunk with its own --only list
        procs.append(run(args.godot, ch[0], ch[-1], extra + ["--only=" + ",".join(str(x) for x in ch)], log))
    for p in procs:
        p.wait()
    rows = []
    for log in logs:
        for line in open(log, encoding="utf-8", errors="replace"):
            m = LINE.search(line)
            if m:
                ok, n, kind, res, t, base, cit, k, l, d, peak, wall = m.groups()
                rows.append(dict(stage=int(n), mode="play" if kind.startswith("playable") else "idle", result=res, time_s=int(t),
                                 stronghold_pct=int(base), citadel_pct=int(cit), kills=int(k), losses=int(l), deployed=int(d),
                                 peak_enemies=int(peak), ok=ok == "PASS", wall_ms=int(wall)))
    rows.sort(key=lambda r: (r["stage"], r["mode"]))
    with open(args.out, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()) if rows else ["stage"])
        w.writeheader()
        w.writerows(rows)
    if args.merge and os.path.exists(args.merge):
        old = list(csv.DictReader(open(args.merge)))
        keys = {(r["stage"], r["mode"]) for r in rows}
        merged = [r for r in old if (int(r["stage"]), r["mode"]) not in keys] + rows
        merged.sort(key=lambda r: (int(r["stage"]), r["mode"]))
        with open(args.merge, "w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
            w.writeheader()
            w.writerows(merged)
        print("merged %d rows into %s" % (len(rows), args.merge))
    bad = [r for r in rows if not r["ok"]]
    print("%d runs, %d failed -> %s" % (len(rows), len(bad), args.out))
    for r in bad:
        print("  FAIL s%03d %s %s %ds" % (r["stage"], r["mode"], r["result"], r["time_s"]))
    sys.exit(1 if bad or len(rows) < 2 * len(stages) else 0)


if __name__ == "__main__":
    main()
