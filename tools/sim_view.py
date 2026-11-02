#!/usr/bin/env python3
"""Print a compact per-stage view of a batch_sim CSV (and the hazard/boss detail from its job logs)."""
import csv, re, sys, glob
path = sys.argv[1]
rows = list(csv.DictReader(open(path)))
by = {}
for r in rows:
    by.setdefault(int(r["stage"]), {})[r["mode"]] = r
det = {}
for log in glob.glob(path + ".job*.log"):
    for line in open(log, errors="replace"):
        m = re.search(r"Stage (\d+) playable.*?\| (tears=.*)$", line)
        if m:
            det[int(m.group(1))] = m.group(2)[:150]
for s in sorted(by):
    p = by[s].get("play", {}); i = by[s].get("idle", {})
    print("%03d %-7s %4ss base%3s%% cit%3s%% k%-4s l%-3s | idle %-5s %4ss  %s" % (s, p.get("result"), p.get("time_s"), p.get("stronghold_pct"), p.get("citadel_pct"), p.get("kills"), p.get("losses"), i.get("result"), i.get("time_s"), det.get(s, "")))
