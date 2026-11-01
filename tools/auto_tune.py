#!/usr/bin/env python3
"""M005 auto-tune helper (optional, advisory): reads a batch_sim.py CSV and prints tuning suggestions
for each stage that misses the targets of master-prompt §12.2. It NEVER edits stage data: every
suggestion is printed as a human-readable diff against data/stages.json for an author to apply in
the act module (tools/actN_data.py) and paste into the milestone report.

    python3 tools/auto_tune.py build/sims_act2.csv [--targets 300,720]

Targets: an auto-commander win in 5-12 min (boss stages up to 14), a no-deployment loss in 60-200 s.
"""
import csv
import json
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))


def load(path):
    rows = {}
    for r in csv.DictReader(open(path)):
        rows.setdefault(int(r["stage"]), {})[r["mode"]] = r
    return rows


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)
    rows = load(sys.argv[1])
    stages = {s["index"]: s for s in json.load(open(os.path.join(ROOT, "data", "stages.json")))["stages"]}
    lo_win, hi_win = 300, 720
    if "--targets" in sys.argv:
        lo_win, hi_win = [int(x) for x in sys.argv[sys.argv.index("--targets") + 1].split(",")]
    n_sugg = 0
    for n in sorted(rows):
        st = stages[n]
        boss = st.get("boss") is not None
        hi = 840 if boss else hi_win
        play, idle = rows[n].get("play"), rows[n].get("idle")
        notes = []
        if play:
            res, t = play["result"], int(play["time_s"])
            if res == "TIMEOUT" and int(play["stronghold_pct"]) > 60:
                ranged = [tr for tr in st["tracks"] if float(tr.get("until", -1)) <= 0]
                notes.append("timeout with both strongholds standing -> ranged/artillery pile-up or tracks too dense:")
                for tr in st["tracks"][:3]:
                    notes.append("    track %-24s interval %5.1f -> %5.1f" % (tr["enemy"], tr["interval"], round(tr["interval"] * 1.2, 1)))
                if st.get("max_alive", 0) > 48:
                    notes.append("    max_alive %d -> %d" % (st["max_alive"], st["max_alive"] - 6))
            elif res == "LOSS":
                notes.append("auto-commander lost at %ds -> soften the opening or delay the hard counter:" % t)
                for tr in st["tracks"]:
                    if tr["start"] < 30:
                        notes.append("    track %-24s interval %5.1f -> %5.1f (x1.15)" % (tr["enemy"], tr["interval"], round(tr["interval"] * 1.15, 1)))
                for ev in st["events"]:
                    if ev["t"] < 200:
                        notes.append("    event at %3ds -> %3ds  %s" % (ev["t"], ev["t"] + 40, ev["spawn"]))
            elif res == "WIN" and t < lo_win:
                notes.append("won in %ds (< %ds) -> too easy: add a set piece or a trigger wave, e.g." % (t, lo_win))
                notes.append("    + event at %ds: %s x3" % (max(120, t - 60), st["tracks"][0]["enemy"]))
                notes.append("    first track interval %.1f -> %.1f (x0.9)" % (st["tracks"][0]["interval"], round(st["tracks"][0]["interval"] * 0.9, 1)))
            elif res == "WIN" and t > hi:
                notes.append("won in %ds (> %ds) -> long grind: widen a late track or cap it with 'until'" % (t, hi))
        if idle:
            res, t = idle["result"], int(idle["time_s"])
            if res != "LOSS":
                notes.append("not losable with no deployments -> the undead never reach the stronghold: add an early melee track")
            elif t > 200:
                notes.append("idle loss takes %ds (> 200 s): tighten the opening track" % t)
            elif t < 60:
                notes.append("idle loss in %ds (< 60 s): the opening is brutal; delay it a little" % t)
        if notes:
            n_sugg += 1
            print("s%03d %s" % (n, st["name"]))
            for x in notes:
                print("  " + x)
    print("%d stage(s) with suggestions" % n_sugg)


if __name__ == "__main__":
    main()
