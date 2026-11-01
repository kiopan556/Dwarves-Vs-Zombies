#!/usr/bin/env python3
"""M007 helper: prints the markdown stage table for a stage range from batch_sim CSVs (normal + heroic).

    python3 tools/report_tables.py build/sims_final.csv build/sims_h_final.csv 91 120
"""
import csv
import json
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))


def load(path):
    out = {}
    if path and os.path.exists(path):
        for r in csv.DictReader(open(path)):
            out[(int(r["stage"]), r["mode"])] = r
    return out


def mmss(s):
    s = int(s)
    return "%d:%02d" % (s // 60, s % 60)


def main():
    norm = load(sys.argv[1])
    her = load(sys.argv[2]) if len(sys.argv) > 2 else {}
    a, b = int(sys.argv[3]), int(sys.argv[4])
    stages = json.load(open(os.path.join(ROOT, "data", "stages.json")))["stages"]
    cum = 0
    for s in stages[:a - 1]:
        cum += s["rewards"]["sparks"]
    print("| Stage | Name | Env | Hazard | Budget | Auto-commander | Idle loss | Heroic (commander / idle) | Blueprint(s) | Sparks (cum.) | Challenge |")
    print("|---|---|---|---|---|---|---|---|---|---|---|")
    for s in stages[a - 1:b]:
        i = s["index"]
        cum += s["rewards"]["sparks"]
        hz = s.get("hazard")
        hz = hz if isinstance(hz, list) else ([hz] if hz else [])
        hzs = " + ".join(("gantries" if h.get("variant") == "gantry" else h["kind"]) for h in hz) or "—"
        p = norm.get((i, "play"))
        d = norm.get((i, "idle"))
        hp = her.get((i, "play"))
        hd = her.get((i, "idle"))
        pc = "%s %s (stronghold %s%%)" % (p["result"], mmss(p["time_s"]), p["stronghold_pct"]) if p else "—"
        dc = "%s %ss" % (d["result"], d["time_s"]) if d else "—"
        hc = ("%s %s / %s %ss" % (hp["result"], mmss(hp["time_s"]), hd["result"], hd["time_s"])) if hp and hd else "—"
        name = ("**%s**" % s["name"]) if s.get("boss") else s["name"]
        print("| %03d | %s | %s | %s | %s | %s | %s | %s | %s | %d (%d) | %s |" % (
            i, name, s["env"], hzs, s["difficulty_budget"], pc, dc, hc, ", ".join(s["rewards"].get("unlock", [])),
            s["rewards"]["sparks"], cum, s["challenge"]["text"]))


if __name__ == "__main__":
    main()
