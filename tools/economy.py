#!/usr/bin/env python3
"""M008 full-campaign balance report: one CSV row per stage (sims + economy) and a summary chart.

    python3 tools/economy.py --normal build/sims_all.csv --heroic build/sims_all_heroic.csv \
        --csv build/campaign_balance.csv --png docs/screenshots/m008_balance.png

Columns: stage, act, name, boss, budget, budget_vs_neighbours (ratio to the mean of the two neighbours), normal /
heroic auto-commander result + win time + stronghold %, idle loss time, sparks, cumulative sparks (base, and with
every first-time star bonus), blueprints. Then the research economy: cost to open every tier (doctrines + gates),
research-only units, the whole roster at research prices, and the stage where each tier becomes affordable.
"""
import argparse, csv, json, os

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))


def load_sims(path):
    out = {}
    if not path or not os.path.exists(path):
        return out
    for r in csv.DictReader(open(path)):
        out.setdefault(int(r["stage"]), {})[r["mode"]] = r
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--normal", default=os.path.join(ROOT, "build", "sims_all.csv"))
    ap.add_argument("--heroic", default=os.path.join(ROOT, "build", "sims_all_heroic.csv"))
    ap.add_argument("--csv", default=os.path.join(ROOT, "build", "campaign_balance.csv"))
    ap.add_argument("--png", default="")
    a = ap.parse_args()
    data = os.path.join(ROOT, "data")
    st = json.load(open(os.path.join(data, "stages.json")))["stages"]
    tech = json.load(open(os.path.join(data, "tech.json")))
    nrm = load_sims(a.normal)
    her = load_sims(a.heroic)
    rows = []
    cum = 0
    cum_star = 0
    budgets = [float(s.get("difficulty_budget", 0)) for s in st]
    for i, s in enumerate(st):
        sp = int(s["rewards"].get("sparks", 0))
        cum += sp
        cum_star += sp + int(round(sp * 0.3))
        nb = [budgets[j] for j in (i - 1, i + 1) if 0 <= j < len(st) and not st[j].get("boss")]
        ratio = budgets[i] / (sum(nb) / len(nb)) if nb and not s.get("boss") and i > 0 else 0.0
        n = nrm.get(s["index"], {}); h = her.get(s["index"], {})
        rows.append(dict(stage=s["index"], act=s["act"], name=s["name"], boss=s.get("boss") or "", env=s["env"], budget=budgets[i],
                         budget_vs_neighbours=round(ratio, 2),
                         normal=n.get("play", {}).get("result", ""), normal_time_s=n.get("play", {}).get("time_s", ""), normal_stronghold=n.get("play", {}).get("stronghold_pct", ""),
                         idle=n.get("idle", {}).get("result", ""), idle_time_s=n.get("idle", {}).get("time_s", ""),
                         heroic=h.get("play", {}).get("result", ""), heroic_time_s=h.get("play", {}).get("time_s", ""), heroic_idle=h.get("idle", {}).get("result", ""),
                         sparks=sp, sparks_cum=cum, sparks_cum_all_stars=cum_star, blueprints=" ".join(s["rewards"].get("unlock", []))))
    os.makedirs(os.path.dirname(a.csv), exist_ok=True)
    with open(a.csv, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader(); w.writerows(rows)
    # research economy
    docs = {d["id"]: d for d in tech["doctrines"]}
    units = [u for u in tech["units"] if u.get("unit")]
    variants = [u for u in tech["units"] if u.get("variant")]
    bp = {u for s in st for u in s["rewards"].get("unlock", [])}
    research_only = [u for u in units if u["unit"] not in bp and u["tier"] > 0]
    doc_cost = sum(d["cost"] for d in docs.values())
    roster_cost = sum(u["cost"] for u in units)
    var_cost = sum(v["cost"] for v in variants)
    gates = tech["tier_stage_gate"]
    tier_rows = []
    for t in range(1, 6):
        need = sum(d["cost"] for d in docs.values() if d["tier"] <= t) + sum(u["cost"] for u in research_only if u["tier"] <= t)
        gate = int(gates[str(t)][1:])
        cum_at_gate = rows[gate - 1]["sparks_cum"]
        aff = next((r["stage"] for r in rows if r["sparks_cum"] >= need), None)
        tier_rows.append((t, gate, need, cum_at_gate, aff))
    print("stages: %d  ·  sparks by 150: %d base, %d with every first-time star bonus" % (len(rows), cum, cum_star))
    print("cost: every doctrine/tier gate %d, research-only units %d, whole roster at research prices %d, variants %d" % (doc_cost, sum(u['cost'] for u in research_only), roster_cost, var_cost))
    print("everything (doctrines + whole roster + variants) = %d -> affordable from Sparks alone by 150: %s (with all stars: %s)" % (
        doc_cost + roster_cost + var_cost, cum >= doc_cost + roster_cost + var_cost, cum_star >= doc_cost + roster_cost + var_cost))
    for t, gate, need, have, aff in tier_rows:
        print("  T%d opens at %03d: every doctrine + research-only unit up to T%d costs %d; sparks at the gate %d; affordable from stage %s" % (t, gate, t, need, have, aff))
    bad = [r for r in rows if r["budget_vs_neighbours"] > 1.3]
    print("stages more than 30%% above their neighbours' mean budget: %s" % ([(r["stage"], r["budget_vs_neighbours"]) for r in bad] or "none"))
    if a.png:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
        fig, ax = plt.subplots(3, 1, figsize=(13, 10), dpi=100)
        xs = [r["stage"] for r in rows]
        for key, col, lab in (("normal_time_s", "#c9a24a", "Normal (auto-commander)"), ("heroic_time_s", "#b0303a", "Heroic (auto-commander)")):
            ys = [float(r[key]) / 60.0 if r[key] not in ("", None) else None for r in rows]
            ax[0].plot([x for x, y in zip(xs, ys) if y is not None], [y for y in ys if y is not None], ".-", color=col, label=lab, lw=1.2, ms=4)
        for r in rows:
            if r["boss"]:
                for k in range(3):
                    ax[k].axvline(r["stage"], color="#8a5aa0", alpha=0.18, lw=1)
        ax[0].axhspan(5, 12, color="#4a7a4a", alpha=0.08)
        ax[0].set_ylabel("win time (min)"); ax[0].legend(loc="upper left", fontsize=8); ax[0].set_title("Win time per stage (target band 5-12 min shaded; boss stages marked)")
        ax[1].plot(xs, [r["sparks_cum"] for r in rows], color="#f08a2a", label="cumulative Sparks (stage rewards)")
        ax[1].plot(xs, [r["sparks_cum_all_stars"] for r in rows], color="#f08a2a", ls="--", alpha=0.6, label="... with every first-time star bonus")
        ax[1].axhline(doc_cost + roster_cost + var_cost, color="#5f7486", ls=":", label="whole roster + all doctrines at research prices")
        for t, gate, need, have, aff in tier_rows:
            ax[1].plot([gate], [need], "o", color="#2f4f7a")
            ax[1].annotate("T%d" % t, (gate, need), textcoords="offset points", xytext=(4, 6), fontsize=8)
        ax[1].set_ylabel("Sparks"); ax[1].legend(loc="upper left", fontsize=8); ax[1].set_title("Spark economy: tier gates (dots = cost of every doctrine + research-only unit up to that tier)")
        ax[2].bar(xs, [r["budget"] for r in rows], color=["#8a5aa0" if r["boss"] else "#6a6258" for r in rows])
        ax[2].set_ylabel("threat budget"); ax[2].set_xlabel("stage"); ax[2].set_title("Difficulty budget per stage (boss stages purple: the boss carries the fight)")
        plt.tight_layout()
        os.makedirs(os.path.dirname(os.path.abspath(a.png)), exist_ok=True)
        plt.savefig(a.png)
        print("chart ->", a.png)


if __name__ == "__main__":
    main()
