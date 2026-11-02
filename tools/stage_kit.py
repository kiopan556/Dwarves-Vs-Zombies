"""M005 stage-authoring toolkit: reusable encounter templates + a stage validator.

Acts II-V are 120 stages. Instead of hand-writing every track, an act module composes each stage
from a few encounter shapes and then adds the details that make the stage its own:

    from stage_kit import *
    parts = compose(
        opener_horde(["shambler"], k=1.1),
        air_raid(["blight_bat"], t=90, n=4),
        monster_breakthrough("carrion_bull", t=200, escort=("shambler", 4)),
    )
    stage = make_stage("Blackbough Verge", "dead_forest", parts, base_hp=5400, ...)

Every template takes enemy pools and an intensity `k` (k > 1 = denser) and returns a dict with
`tracks`, `events`, `triggers` and `structures` lists in the stage schema used by gen_data.py:

    track    R(enemy, start, interval, group, interval_min, ramp, until)
    event    E(t, (enemy, n), ...)
    trigger  T(citadel_hp_fraction, (enemy, n), ...)

Ranged and artillery templates always set `until` (the M003 pile-up lesson). The validator at the
bottom of this file is run by gen_data.py on every build and can also be run on its own:

    python3 tools/stage_kit.py            # validate data/stages.json
"""
import json
import os
import sys

R = lambda e, start, interval, group=1, mn=None, ramp=0.97, until=-1: dict(enemy=e, start=start, interval=interval, group=group, interval_min=mn if mn else round(interval * 0.6, 2), ramp=ramp, until=until)
E = lambda t, *spawns: dict(t=t, spawn=[list(s) for s in spawns])
T = lambda hp, *spawns: dict(hp_below=hp, spawn=[list(s) for s in spawns])


def _part(tracks=(), events=(), triggers=(), structures=()):
    return dict(tracks=list(tracks), events=list(events), triggers=list(triggers), structures=list(structures))


def _iv(base, k):
    return round(base / max(0.2, k), 2)


# ------------------------------------------------------------------ encounter templates
def opener_horde(melee, k=1.0, start=2, group=3, interval=6.0, second_at=10):
    """A steady stream of cheap melee; an optional second melee type joins later."""
    tr = [R(melee[0], start, _iv(interval, k), group, _iv(interval * 0.66, k))]
    if len(melee) > 1:
        tr.append(R(melee[1], second_at, _iv(interval * 1.9, k), max(1, group - 1), _iv(interval * 1.25, k)))
    return _part(tracks=tr)


def shield_wall(front, ranged, k=1.0, start=6, until=600):
    """Armoured or tough front-liners screening a ranged line (ranged track stops at `until`)."""
    return _part(tracks=[R(front, start, _iv(12, k), 2, _iv(8, k)),
                         R(ranged, start + 10, _iv(15, k), 1 if k < 1.15 else 2, _iv(10, k), until=until)])


def artillery_line(guns, guard=None, k=1.0, start=40, until=480, barricade_x=None, guard_x=None):
    """Undead siege pieces lobbing from range behind a guard (and optionally a barricade)."""
    tr = [R(g, start + i * 25, _iv(55 + i * 10, k), 1, _iv(40 + i * 8, k), until=until) for i, g in enumerate(guns)]
    if guard:
        tr.append(R(guard, start - 20, _iv(16, k), 1, _iv(11, k)))
    st = [dict(enemy="cursed_barricade", x=barricade_x)] if barricade_x else []
    return _part(tracks=tr, structures=st)


def air_raid(flyers, k=1.0, start=20, t=None, n=4, until=-1, spire_x=None):
    """Flyers on a track, plus an optional set-piece wave at `t` and a flak spire guarding them."""
    tr = [R(flyers[0], start, _iv(16, k), 2, _iv(10, k), until=until)]
    if len(flyers) > 1:
        tr.append(R(flyers[1], start + 15, _iv(24, k), 1, _iv(15, k), until=until))
    ev = [E(t, *[(f, n if i == 0 else max(1, n // 2)) for i, f in enumerate(flyers)])] if t else []
    st = [dict(enemy="grave_flak_spire", x=spire_x)] if spire_x else []
    return _part(tracks=tr, events=ev, structures=st)


def monster_breakthrough(monster, t, escort=None, n=1):
    """A big monster (or giant) crashes the line at `t`, usually with an escort."""
    sp = [(monster, n)] + ([escort] if escort else [])
    return _part(events=[E(t, *sp)])


def support_cluster(structs):
    """Static undead support buildings (beacons, cauldrons, spires) at fixed x positions."""
    return _part(structures=[dict(enemy=e, x=x) for e, x in structs])


def boss_arena(adds, k=1.0, until=600):
    """Light, steady support for a boss fight: the boss itself brings the pressure."""
    tr = []
    for i, (e, interval, group) in enumerate(adds):
        tr.append(R(e, 3 + i * 10, _iv(interval, k), group, _iv(interval * 0.66, k), until=until if i > 0 else -1))
    return _part(tracks=tr)


def finale(ground, ranged, air, k=1.0, until=560):
    """Combined arms on both fronts: every pool contributes a track."""
    tr = []
    for i, e in enumerate(ground):
        tr.append(R(e, 2 + i * 8, _iv(8 + i * 5, k), 2 if i == 0 else 1, _iv(5.5 + i * 3.5, k)))
    for i, e in enumerate(ranged):
        tr.append(R(e, 20 + i * 15, _iv(18 + i * 6, k), 1, _iv(12 + i * 4, k), until=until))
    for i, e in enumerate(air):
        tr.append(R(e, 18 + i * 12, _iv(18 + i * 6, k), 2 if i == 0 else 1, _iv(11 + i * 4, k)))
    return _part(tracks=tr)


def flak_belt(structs):
    """M006: a line of undead anti-air structures (spires, soul turrets, beacons) the air arm must fly
    through. Ground or artillery play has to break the belt before air power pays off."""
    return _part(structures=[dict(enemy=e, x=x) for e, x in structs])


def sky_host(flyers, k=1.0, start=12, until=-1):
    """M006: a big sky battle - every flyer type gets its own track (the air front leads, the ground
    front stays real through the stage's other parts)."""
    tr = []
    for i, f in enumerate(flyers):
        tr.append(R(f, start + i * 14, _iv(14 + i * 6, k), 2 if i == 0 else 1, _iv(9 + i * 4, k), until=until))
    return _part(tracks=tr)


def reclaim_squad(corruptors, k=1.0, start=40, until=520, guard=None):
    """M007: undead corruptors (corpse priests, rot channelers, ash hexers) that walk to dwarven wrecks and
    raise them as corrupted machines. They hold back behind the line, so their tracks always end."""
    tr = [R(c, start + i * 18, _iv(30 + i * 8, k), 1, _iv(20 + i * 6, k), until=until) for i, c in enumerate(corruptors)]
    if guard:
        tr.append(R(guard, start - 10, _iv(14, k), 2, _iv(9, k)))
    return _part(tracks=tr)


def production_line(melee, k=1.0, start=20, every=45, n=6, until=520):
    """M007: thrall bursts on a strict cadence, like a production line (timed events, not a ramping track)."""
    ev = []
    t = start
    while t <= until:
        ev.append(E(t, (melee, n)))
        t += every
    return _part(events=ev)


def corrupted_column(machines, escort, k=1.0, start=40):
    """M007: corrupted dwarven war machines advancing behind an infantry column."""
    tr = [R(m, start + i * 35, _iv(70 + i * 15, k), 1, _iv(50 + i * 10, k)) for i, m in enumerate(machines)]
    tr.append(R(escort, start - 30, _iv(10, k), 2, _iv(7, k)))
    return _part(tracks=tr)


def obelisk_belt(xs, beacons=()):
    """M008: a belt of rift obelisks (they zap and ward the undead around them: -15 % damage taken) with
    optional wraith beacons; artillery and air strikes that break the belt open the line."""
    return _part(structures=[dict(enemy="rift_obelisk", x=x) for x in xs] + [dict(enemy="wraith_beacon", x=x) for x in beacons])


def honour_guard(elites, k=1.0, start=30, until=-1):
    """M008: a column of elite infantry in strict rotation (one type after another, never a crowd of one kind)."""
    tr = [R(e, start + i * 14, _iv(28 + i * 4, k), 1, _iv(19 + i * 3, k), until=until) for i, e in enumerate(elites)]
    return _part(tracks=tr)


def trigger_waves(*trigs):
    return _part(triggers=list(trigs))


def set_pieces(*events):
    return _part(events=list(events))


def compose(*parts):
    out = _part()
    for p in parts:
        for k in out:
            out[k] += p.get(k, [])
    return out


def make_stage(name, env, parts, base_hp, start_gold, max_alive, theme, tag, rewards, challenge, hazard=None, boss=None):
    st = dict(name=name, env=env, theme=theme, base_hp=base_hp, start_gold=start_gold, max_alive=max_alive,
              tracks=parts["tracks"], events=parts["events"], triggers=parts["triggers"], structures=parts["structures"],
              rewards=rewards, tag=tag, challenge=challenge)
    if hazard is not None:
        st["hazard"] = hazard
    if boss is not None:
        st["boss"] = boss
    return st


# ------------------------------------------------------------------ challenge objectives
# kind -> (fields, one-line text). Checked by Battle.challenge_met() at the end of a won battle.
CHALLENGES = {
    "no_air_losses": ([], "Lose no aircraft"),
    "time_under": (["seconds"], "Win within {mm}"),
    "base_above": (["frac"], "Never let the stronghold drop below {pct}%"),
    "kill_structures": ([], "Destroy every undead support structure"),
    "max_types": (["n"], "Win with at most {n} unit types deployed"),
    "max_losses": (["n"], "Lose at most {n} units"),
    "kill_boss_by": (["seconds"], "Slay the boss within {mm} of its arrival"),
    "escort": ([], "Bring the supply barge safely across"),
    "no_reclaims": ([], "Let the undead reclaim no wreck"),
    "no_spills": ([], "Close every rift tear before it spills"),
}


def challenge_text(c):
    fields, txt = CHALLENGES[c["kind"]]
    mm = ""
    if "seconds" in c:
        mm = "%d:%02d" % (int(c["seconds"]) // 60, int(c["seconds"]) % 60)
    return txt.format(mm=mm, pct=int(round(float(c.get("frac", 0)) * 100)), n=c.get("n", 0))


def ch(kind, **kw):
    c = dict(kind=kind, **kw)
    c["text"] = challenge_text(c)
    return c


# ------------------------------------------------------------------ validator
HAZARD_KINDS = {"furnace_vents": ["vents", "interval", "damage", "radius"], "slag_flow": ["x0", "x1", "interval", "duration", "dps", "slow"],
                "steam_leak": ["pipes", "radius", "dps", "regen"],
                "rockfall": ["interval", "damage", "radius"], "gale": ["interval", "duration", "strength"],
                "miasma": ["interval", "duration", "dps", "radius", "speed"], "bog": ["spots", "width", "slow"],
                "thermals": ["columns", "width"], "lightning_storm": ["interval", "damage", "radius"],
                "rift_tears": ["interval", "warn", "hp", "spill", "pool"], "eclipse": ["interval", "duration"],
                "soul_storm": ["interval", "wisps", "heal", "damage", "hp"]}
ESCORT_FIELDS = ["t", "hp", "speed", "alt", "x0", "x1"]
# difficulty budget band per act (threat-weighted spawns per minute; boss stages are exempt)
ACT_BANDS = {1: (35.0, 200.0), 2: (90.0, 260.0), 3: (100.0, 320.0), 4: (110.0, 380.0), 5: (100.0, 440.0)}


def validate(stages, undead_by_id, boss_ids, max_alive_cap=64, legacy_until_upto=30, warns=None):
    """Returns a list of human-readable problems (empty = valid). Only implemented stages are checked.
    Act I (stages 1-30) shipped before the `until` rule: its missing `until`s are reported as warnings."""
    errs = []
    warns = warns if warns is not None else []
    for st in stages:
        if not st.get("implemented"):
            continue
        sid = st["id"]
        ids = [t["enemy"] for t in st["tracks"]] + [s[0] for ev in st["events"] for s in ev["spawn"]] + \
              [s[0] for tg in st["triggers"] for s in tg["spawn"]] + [s["enemy"] for s in st["structures"]]
        for e in ids:
            if e not in undead_by_id:
                errs.append(f"{sid}: unknown enemy id '{e}'")
        for t in st["tracks"]:
            u = undead_by_id.get(t["enemy"])
            if u is None:
                continue
            stats = u.get("stats") or {}
            if stats.get("static"):
                errs.append(f"{sid}: static structure '{t['enemy']}' must be a structure, not a track")
            holds_back = u["category"] == "ranged" or stats.get("behavior") in ("ranged", "artillery", "repair") or \
                (u["category"] == "siege" and stats.get("behavior") != "melee")
            if holds_back and float(t.get("until", -1)) <= 0:
                msg = f"{sid}: ranged/artillery track '{t['enemy']}' has no 'until'"
                if int(st["index"]) <= legacy_until_upto:
                    warns.append(msg)   # Act I predates the rule and is tuned as shipped
                else:
                    errs.append(msg)
        if int(st.get("max_alive", 99)) > max_alive_cap:
            errs.append(f"{sid}: max_alive {st['max_alive']} > {max_alive_cap}")
        air = any(undead_by_id.get(e, {}).get("domain") == "air" for e in ids)
        ground = any(undead_by_id.get(e, {}).get("domain") == "ground" for e in ids)
        bid = st.get("boss")
        if bid is not None:
            if not st.get("boss_spawn"):
                errs.append(f"{sid}: boss stage without boss_spawn")
            elif st["boss_spawn"]["id"] not in boss_ids:
                errs.append(f"{sid}: boss_spawn id '{st['boss_spawn']['id']}' unknown")
        boss_air = bool(bid) and boss_ids.get(bid, {}).get("domain") == "air"
        if not (air or boss_air) or not ground:
            errs.append(f"{sid}: both fronts must be present (air={air or boss_air}, ground={ground})")
        lo, hi = ACT_BANDS.get(int(st["act"]), (0, 1e9))
        if bid is None and not (lo <= float(st["difficulty_budget"]) <= hi):
            errs.append(f"{sid}: difficulty budget {st['difficulty_budget']} outside act {st['act']} band {lo}-{hi}")
        hz = st.get("hazard")
        for h in (hz if isinstance(hz, list) else [hz] if hz else []):
            need = HAZARD_KINDS.get(h.get("kind"))
            if need is None:
                errs.append(f"{sid}: unknown hazard kind '{h.get('kind')}'")
            else:
                for f in need:
                    if f not in h:
                        errs.append(f"{sid}: hazard '{h['kind']}' missing field '{f}'")
        esc = st.get("escort")
        if esc is not None:
            for f in ESCORT_FIELDS:
                if f not in esc:
                    errs.append(f"{sid}: escort missing field '{f}'")
        c = st.get("challenge")
        if c and c.get("kind") == "escort" and esc is None:
            errs.append(f"{sid}: escort challenge without an escort")
        if not c or c.get("kind") not in CHALLENGES:
            errs.append(f"{sid}: missing or unknown challenge objective")
        elif any(f not in c for f in CHALLENGES[c["kind"]][0]):
            errs.append(f"{sid}: challenge '{c['kind']}' missing fields")
        if not st.get("tagline"):
            errs.append(f"{sid}: missing tagline")
    return errs


# ------------------------------------------------------------------ M007 Heroic difficulty
# Heroic is "smarter, not bigger": one extra authored event, tighter track intervals (x0.85), one more
# support structure, enemy abilities ready earlier, and at most +15 % enemy HP. A stage may override any
# field in its act module (`heroic=dict(...)`); otherwise these defaults are generated from its own roster.
HEROIC_STRUCTURE = {1: "bone_spire", 2: "necrotic_beacon", 3: "grave_flak_spire", 4: "soul_turret", 5: "rift_obelisk"}


def heroic_block(st, override, undead_by_id):
    ov = dict(override or {})
    roster = [t["enemy"] for t in st["tracks"]]
    ground = [e for e in roster if undead_by_id.get(e, {}).get("domain") == "ground" and
              not (undead_by_id[e].get("stats") or {}).get("static") and (undead_by_id[e].get("stats") or {}).get("behavior") == "melee"]
    big = [s[0] for ev in st["events"] for s in ev["spawn"] if undead_by_id.get(s[0], {}).get("domain") == "ground"]
    big.sort(key=lambda e: -float((undead_by_id.get(e, {}).get("stats") or {}).get("threat", 1)))
    melee = ground[0] if ground else (roster[0] if roster else "rotter")
    boss = st.get("boss_spawn")
    t = 150 if boss else 210
    spawn = [[melee, 4]]
    if big and big[0] != melee:
        spawn.insert(0, [big[0], 1])
    x = 2120
    for s in st["structures"]:
        if abs(float(s["x"]) - x) < 70:
            x = min(float(s["x"]) for s in st["structures"]) - 120
    hb = dict(interval_mult=0.85, hp_mult=1.12, ability_lead=0.45,
              event=dict(t=t, spawn=spawn), structure=dict(enemy=HEROIC_STRUCTURE.get(int(st["act"]), "bone_spire"), x=int(max(1500, x))),
              spark_bonus=int(round(float(st["rewards"].get("sparks", 30)) * 0.35)))
    if ov.get("interval_mult", 0.85) >= 0.9 and "event" not in ov:
        hb["event"] = dict(t=t + 30, spawn=[[melee, 3]])   # gentle block: a lighter set piece, a little later
    hb.update(ov)
    assert hb["hp_mult"] <= 1.15 + 1e-9, (st["id"], hb["hp_mult"])
    return hb


def _main():
    root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data")
    stages = json.load(open(os.path.join(root, "stages.json")))["stages"]
    undead = {u["id"]: u for u in json.load(open(os.path.join(root, "undead_roster.json")))["units"]}
    bosses = {b["id"]: (b.get("stats") or {}) for b in json.load(open(os.path.join(root, "bosses.json")))["bosses"]}
    for b in json.load(open(os.path.join(root, "bosses.json")))["bosses"]:
        bosses[b["id"]]["domain"] = (b.get("stats") or {}).get("domain", "ground")
    warns = []
    errs = validate(stages, undead, bosses, warns=warns)
    n = sum(1 for s in stages if s.get("implemented"))
    for w in warns:
        print("WARN", w)
    for e in errs:
        print("INVALID", e)
    print("validated %d implemented stages: %s" % (n, "OK" if not errs else "%d problems" % len(errs)))
    sys.exit(1 if errs else 0)


if __name__ == "__main__":
    _main()
