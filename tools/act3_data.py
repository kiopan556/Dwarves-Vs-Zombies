"""M006: Act III, stages 061-090 — "War for the Skies".

The dwarven army breaks out onto the high plains and broken ridges beyond the Blighted Frontier. The
sky is huge and open: cloudbanks, storm fronts, and the shattered fortresses of an older age floating
on cursed rock. The undead bring their aerial host: gargoyles, wyverns, drakes, sky serpents and a
ghost fleet of corrupted airships. Every stage keeps a real ground front; the sky war decides how
safe that front is.

Built with tools/stage_kit.py like Act II. New in this act:
  * flak belts       lines of undead anti-air structures the air arm has to fly through (`flak_belt`)
  * escort           a dwarven supply barge crosses the sky (`escort` dict); protecting it is the
                     third-star challenge (`ch("escort")`), never a fail condition
  * hazards          `thermals` (updraft/downdraft columns) and `lightning_storm`; `gale` reused
Bosses: Bone Wyrm (070), The Hollow Admiral (080), Dread Sky Tyrant (090).

Blueprints follow the M006 master prompt §7 in order. Block 3 holds five units for the four regular
stages 071-074 (074 gives two); block 7 holds eight units for the nine stages 081-089, so the
never-awarded T3 Thundercoil Frame fills 089. Both are noted in the milestone report.
"""
from stage_kit import (R, E, T, compose, make_stage, opener_horde, shield_wall, artillery_line, air_raid,
                       monster_breakthrough, support_cluster, boss_arena, finale, trigger_waves, set_pieces, ch,
                       flak_belt, sky_host)

# hazards ---------------------------------------------------------------------------------
GALE = dict(kind="gale", interval=24, duration=7, strength=50)
GALE_HARD = dict(kind="gale", interval=19, duration=8, strength=60)
# thermals: columns at fixed x; +1 = updraft (flyers rise a band, aircraft +20 % speed), -1 = downdraft
THERMALS = dict(kind="thermals", columns=[[900, 1], [1450, -1], [1950, 1]], width=120)
THERMALS_DOWN = dict(kind="thermals", columns=[[820, -1], [1300, -1], [1780, 1], [2120, -1]], width=110)
THERMALS_ISLES = dict(kind="thermals", columns=[[760, 1], [1240, -1], [1700, -1], [2100, 1]], width=115)
STORM = dict(kind="lightning_storm", interval=11, damage=150, radius=55, warn=0.8)
STORM_LIGHT = dict(kind="lightning_storm", interval=15, damage=120, radius=50, warn=0.8)
STORM_HEAVY = dict(kind="lightning_storm", interval=10.5, damage=140, radius=52, warn=0.8)

# escort: the supply barge appears at the dwarven hold at t, flies to x1 at `speed` and is delivered there
ESCORT_068 = dict(t=70, hp=2600, speed=20, alt=215, x0=150, x1=2150)
ESCORT_079 = dict(t=60, hp=3600, speed=19, alt=210, x0=150, x1=2200)
ESCORT_088 = dict(t=55, hp=4200, speed=18, alt=205, x0=150, x1=2200)


def _stage(n, name, env, parts, theme, tag, unlock, sparks, challenge, hazard=None, boss=None, base_hp=None, gold=None,
           max_alive=None, open_tier=None, escort=None):
    local = n - 61
    rw = dict(sparks=sparks, unlock=unlock)
    if open_tier is not None:
        rw["open_tier"] = open_tier
    st = make_stage(name, env, parts,
                    base_hp=base_hp if base_hp else 7600 + local * 90,
                    start_gold=gold if gold else 340 + local * 3,
                    max_alive=max_alive if max_alive else min(62, 54 + local // 3),
                    theme=theme, tag=tag, rewards=rw, challenge=challenge, hazard=hazard, boss=boss)
    if escort is not None:
        st["escort"] = escort
    return st


GROUND_A = ["rusted_legionary", "bone_vanguard"]
GROUND_B = ["crypt_halberdier", "hollow_guard"]

ACT3 = [
    # 061 — act opener: a huge sky battle against stalker flocks over a light ground front
    _stage(61, "Windscour Steppe", "open_plains", compose(
        opener_horde(["rusted_legionary", "bone_vanguard"], k=0.95, group=2, interval=7),
        sky_host(["gravewing_stalker", "skeletal_vulture"], k=1.15, start=10),
        set_pieces(E(90, ("gravewing_stalker", 8)), E(200, ("gravewing_stalker", 6), ("rotwing", 4)), E(290, ("stitchback_giant", 1), ("rusted_legionary", 4))),
        trigger_waves(T(0.6, ("gravewing_stalker", 6), ("bone_vanguard", 4)), T(0.3, ("rotwing", 4), ("rusted_legionary", 5)))),
        "sky_superiority", "The steppe runs flat to the edge of the world. The sky above it is black with wings.",
        ["rolling_shield_trooper"], 140, ch("no_air_losses"), hazard=GALE, base_hp=7400),
    # 062 — the first flak belt: break the spires before the air push
    _stage(62, "Flakline Rise", "broken_ridge", compose(
        opener_horde(["rusted_legionary", "bone_vanguard"], k=1.0, group=2, interval=7),
        flak_belt([("grave_flak_spire", 1650), ("grave_flak_spire", 1880), ("grave_flak_spire", 2120)]),
        air_raid(["ossuary_flier", "gravewing_stalker"], k=0.95, start=24, t=150, n=4),
        dict(tracks=[R("bone_bolt_thrower", 50, 60, 1, 42, until=480)], events=[], triggers=[], structures=[]),
        set_pieces(E(220, ("crypt_halberdier", 4), ("gravewing_stalker", 4))),
        trigger_waves(T(0.6, ("bone_vanguard", 4), ("ossuary_flier", 3)), T(0.3, ("crypt_halberdier", 4), ("gravewing_stalker", 4)))),
        "flak_belt", "Three flak spires stand on the rise like teeth. Nothing flies over them for long.",
        ["incendiary_grenadier"], 142, ch("kill_structures")),
    # 063 — thermals introduced; ossuary fliers ride the updrafts
    _stage(63, "Thermal Fields", "open_plains", compose(
        opener_horde(["rusted_legionary", "crypt_halberdier"], k=1.0, group=2, interval=7),
        air_raid(["ossuary_flier", "plague_harpy"], k=1.1, start=16, t=130, n=6),
        dict(tracks=[R("night_seer", 30, 26, 1, 17, until=520)], events=[], triggers=[], structures=[]),
        set_pieces(E(210, ("ossuary_flier", 5), ("bone_vanguard", 4)), E(300, ("stitchback_giant", 1))),
        trigger_waves(T(0.6, ("ossuary_flier", 4), ("rusted_legionary", 4)), T(0.3, ("plague_harpy", 4), ("crypt_halberdier", 3)))),
        "air_ground_pincer", "Hot air boils up off the fields in shimmering columns. The fliers know where they are.",
        ["armored_recovery_team"], 144, ch("max_losses", n=32), hazard=THERMALS),
    # 064 — soul turrets and a hollow guard wall
    _stage(64, "Shattered Watch", "shattered_fort", compose(
        opener_horde(["bone_vanguard", "rusted_legionary"], k=1.0, group=2, interval=7),
        shield_wall("hollow_guard", "night_seer", k=1.0, start=14, until=520),
        flak_belt([("soul_turret", 1820), ("soul_turret", 2140)]),
        air_raid(["gravewing_stalker", "ossuary_flier"], k=0.95, start=20, t=170, n=5),
        set_pieces(E(250, ("hollow_guard", 4), ("ossuary_juggernaut", 1))),
        trigger_waves(T(0.6, ("hollow_guard", 3), ("gravewing_stalker", 4)), T(0.3, ("bone_vanguard", 5), ("ossuary_flier", 3)))),
        "gunship_hunt", "The old watch-fort fell a century ago. Its new garrison never sleeps, and its turrets burn souls.",
        ["turret_engineer"], 146, ch("base_above", frac=0.6)),
    # 065 — first floating-ruin stage: a causeway on the edge of an island; fliers and gargoyles
    _stage(65, "Skerry of Bones", "airborne_ruins", compose(
        opener_horde(["bone_vanguard", "crypt_halberdier"], k=0.95, group=2, interval=7.5),
        sky_host(["ossuary_flier", "tomb_gargoyle"], k=1.05, start=12),
        set_pieces(E(120, ("tomb_gargoyle", 3), ("ossuary_flier", 3)), E(240, ("tomb_gargoyle", 4), ("bone_vanguard", 4)), E(320, ("ossuary_juggernaut", 1))),
        trigger_waves(T(0.6, ("tomb_gargoyle", 3), ("crypt_halberdier", 3)), T(0.3, ("ossuary_flier", 5), ("bone_vanguard", 4)))),
        "sky_superiority", "A skerry of rock adrift above the clouds, and a stone road across it. Bone gulls nest on the towers.",
        ["flak_chaser"], 148, ch("no_air_losses")),
    # 066 — tomb gargoyles: armoured flyers that shrug off bullets
    _stage(66, "Gargoyle Parapets", "shattered_fort", compose(
        opener_horde(["rusted_legionary", "hollow_guard"], k=1.0, group=2, interval=7),
        dict(tracks=[R("tomb_gargoyle", 18, 20, 2, 13), R("wraith_swarm", 40, 30, 1, 20)], events=[], triggers=[], structures=[]),
        support_cluster([("grave_flak_spire", 2160)]),
        set_pieces(E(140, ("tomb_gargoyle", 4)), E(230, ("stitchback_giant", 1), ("tomb_gargoyle", 3)), E(310, ("tomb_gargoyle", 4), ("hollow_guard", 3))),
        trigger_waves(T(0.6, ("tomb_gargoyle", 4), ("rusted_legionary", 4)), T(0.3, ("hollow_guard", 4), ("wraith_swarm", 2)))),
        "wyvern_flights", "The parapets have grown statues. When the light goes, the statues come down for you.",
        ["thunderwing"], 150, ch("max_types", n=8)),
    # 067 — lightning storm introduced on the split ridge
    _stage(67, "Stormbreak Ridge", "broken_ridge", compose(
        opener_horde(["rusted_legionary", "bone_vanguard"], k=1.0, group=2, interval=7),
        air_raid(["banshee_wing", "gravewing_stalker"], k=1.0, start=18, t=140, n=4),
        flak_belt([("grave_flak_spire", 1900), ("soul_turret", 2180)]),
        dict(tracks=[R("rot_launcher", 55, 58, 1, 40, until=470)], events=[], triggers=[], structures=[]),
        set_pieces(E(230, ("ossuary_juggernaut", 1), ("crypt_halberdier", 3)), E(320, ("banshee_wing", 3), ("gravewing_stalker", 4))),
        trigger_waves(T(0.6, ("banshee_wing", 2), ("rusted_legionary", 5)), T(0.3, ("crypt_halberdier", 4), ("gravewing_stalker", 4)))),
        "air_ground_pincer", "The ridge splits the storm in two. Lightning finds whatever stands tallest on it, yours or theirs.",
        ["skyguard_walker"], 152, ch("kill_structures"), hazard=STORM_LIGHT),
    # 068 — the first bone drake; the first escort objective
    _stage(68, "Drakefall Meadow", "open_plains", compose(
        opener_horde(["rusted_legionary", "crypt_halberdier"], k=1.0, group=2, interval=7),
        air_raid(["gravewing_stalker", "ossuary_flier"], k=1.0, start=16, t=120, n=5),
        set_pieces(E(150, ("bone_drake", 1), ("gravewing_stalker", 3)), E(260, ("bone_drake", 1), ("ossuary_flier", 3)), E(330, ("stitchback_giant", 1), ("crypt_halberdier", 3))),
        trigger_waves(T(0.6, ("bone_drake", 1), ("rusted_legionary", 4)), T(0.3, ("crypt_halberdier", 4), ("gravewing_stalker", 5)))),
        "convoy_defense", "A drake fell here once and burned the meadow black. Now three more circle it, and a barge must cross.",
        ["rune_sight_scout"], 154, ch("escort"), escort=ESCORT_068),
    # 069 — the first infected airbarge (a corrupted airship carrying flyers)
    _stage(69, "The Hanging Keep", "airborne_ruins", compose(
        opener_horde(["hollow_guard", "bone_vanguard"], k=1.0, group=2, interval=7.5),
        sky_host(["wraith_swarm", "ossuary_flier"], k=1.0, start=16),
        dict(tracks=[R("spirit_binder", 34, 30, 1, 20, until=500)], events=[], triggers=[], structures=[]),
        set_pieces(E(130, ("infected_airbarge", 1)), E(250, ("infected_airbarge", 1), ("wraith_swarm", 2)), E(320, ("ossuary_juggernaut", 1), ("hollow_guard", 3))),
        trigger_waves(T(0.6, ("infected_airbarge", 1), ("bone_vanguard", 4)), T(0.3, ("hollow_guard", 4), ("ossuary_flier", 4)))),
        "gunship_hunt", "The keep hangs from its island by chains. Its barges come and go full of things that fly.",
        ["sky_mender"], 156, ch("max_losses", n=34), hazard=THERMALS_ISLES),
    # 070 — BOSS: Bone Wyrm
    _stage(70, "Wyrmcoil Chasm", "broken_ridge", compose(
        boss_arena([("rusted_legionary", 13, 2), ("crypt_halberdier", 30, 1), ("gravewing_stalker", 24, 2)], k=1.0, until=640),
        trigger_waves(T(0.6, ("bone_vanguard", 4), ("ossuary_flier", 3)), T(0.3, ("crypt_halberdier", 3), ("gravewing_stalker", 4)))),
        "boss_bone_wyrm", "The chasm is not a chasm. It is where the wyrm sleeps, coiled through the split rock.",
        ["skyshield_airship", "ironcloud"], 320, ch("kill_boss_by", seconds=480), boss=dict(id="bone_wyrm", t=55),
        base_hp=7800, gold=560),
    # 071 — banshee wings and wraith beacons
    _stage(71, "Banshee Reach", "open_plains", compose(
        opener_horde(["rusted_legionary", "grave_warden"], k=0.85, group=2, interval=7.5),
        support_cluster([("wraith_beacon", 2120)]),
        air_raid(["banshee_wing", "wraith_swarm"], k=1.05, start=16, t=140, n=4),
        set_pieces(E(220, ("banshee_wing", 3), ("grave_warden", 2)), E(300, ("stitchback_giant", 1), ("rusted_legionary", 4))),
        trigger_waves(T(0.6, ("banshee_wing", 3), ("rusted_legionary", 4)), T(0.3, ("grave_warden", 3), ("wraith_swarm", 3)))),
        "wyvern_flights", "The banshees hunt along the reach, and a beacon calls the wraiths in after them.",
        ["counterbattery_mortar"], 158, ch("kill_structures"), base_hp=6600),
    # 072 — stitchback + juggernaut push on the ground while the air war rages
    _stage(72, "Splintered Bastion", "shattered_fort", compose(
        opener_horde(["hollow_guard", "rusted_legionary"], k=1.0, group=2, interval=7),
        sky_host(["gravewing_stalker", "banshee_wing"], k=1.0, start=14),
        set_pieces(E(120, ("stitchback_giant", 1), ("hollow_guard", 3)), E(210, ("ossuary_juggernaut", 1), ("rusted_legionary", 4)), E(300, ("stitchback_giant", 1), ("ossuary_juggernaut", 1))),
        trigger_waves(T(0.6, ("ossuary_juggernaut", 1), ("gravewing_stalker", 4)), T(0.3, ("stitchback_giant", 1), ("banshee_wing", 3)))),
        "air_ground_pincer", "The bastion's walls are splinters. What walks through them now is taller than the walls were.",
        ["piston_cannon"], 160, ch("base_above", frac=0.6)),
    # 073 — downdrafts and wraith swarms over the cloud sea
    _stage(73, "Cloudmoor", "airborne_ruins", compose(
        opener_horde(["bone_vanguard", "crypt_halberdier"], k=1.0, group=2, interval=7.5),
        dict(tracks=[R("wraith_swarm", 14, 16, 2, 10), R("ossuary_flier", 30, 26, 1, 17)], events=[], triggers=[], structures=[]),
        dict(tracks=[R("night_seer", 34, 28, 1, 19, until=520)], events=[], triggers=[], structures=[]),
        set_pieces(E(150, ("wraith_swarm", 5)), E(250, ("ossuary_juggernaut", 1), ("wraith_swarm", 3))),
        trigger_waves(T(0.6, ("wraith_swarm", 4), ("crypt_halberdier", 3)), T(0.3, ("bone_vanguard", 5), ("ossuary_flier", 4)))),
        "sky_superiority", "On the moor of cloud the air falls like water. Fly low here and you fly into the sea.",
        ["bastion_heavy_tank"], 162, ch("no_air_losses"), hazard=THERMALS_DOWN),
    # 074 — storm + rot launchers
    _stage(74, "Thunderhead Pass", "broken_ridge", compose(
        opener_horde(["rusted_legionary", "hollow_guard"], k=1.0, group=2, interval=7),
        artillery_line(["rot_launcher"], guard="crypt_halberdier", k=0.9, start=40, until=400),
        air_raid(["gravewing_stalker", "plague_harpy"], k=1.0, start=18, t=160, n=5),
        set_pieces(E(260, ("ossuary_juggernaut", 1), ("hollow_guard", 3))),
        trigger_waves(T(0.6, ("rot_launcher", 1), ("gravewing_stalker", 4)), T(0.3, ("hollow_guard", 4), ("plague_harpy", 3)))),
        "flak_belt", "Rot launchers wait in the pass under a sky full of thunderheads.",
        ["sniper_tank_hunter", "cannon_strider"], 164, ch("time_under", seconds=660), hazard=STORM),
    # 075 — a big combined assault; opens T4 research
    _stage(75, "Highwatch Citadel", "shattered_fort", compose(
        finale(["rusted_legionary", "hollow_guard", "crypt_halberdier"], ["night_seer", "spirit_binder"],
               ["gravewing_stalker", "banshee_wing"], k=0.95, until=520),
        flak_belt([("grave_flak_spire", 1960), ("soul_turret", 2200)]),
        set_pieces(E(150, ("bone_drake", 1), ("tomb_gargoyle", 3)), E(240, ("ossuary_juggernaut", 1)), E(320, ("infected_airbarge", 1), ("stitchback_giant", 1))),
        trigger_waves(T(0.6, ("bone_drake", 1), ("hollow_guard", 4)), T(0.3, ("ossuary_juggernaut", 1), ("gravewing_stalker", 4)))),
        "combined_assault", "Highwatch held the plains for six hundred years. Take it back, and the old war foundries open their doors.",
        ["twin_cannon_ironclad", "runic_mechanic"], 200, ch("max_losses", n=40), open_tier=4),
    # 076 — the first necrotic sky serpent
    _stage(76, "Serpent's Sky", "airborne_ruins", compose(
        opener_horde(["crypt_halberdier", "bone_vanguard"], k=1.0, group=2, interval=7.5),
        air_raid(["ossuary_flier", "wraith_swarm"], k=1.0, start=16, t=130, n=4),
        set_pieces(E(110, ("necrotic_sky_serpent", 1)), E(230, ("necrotic_sky_serpent", 1), ("ossuary_flier", 3)), E(310, ("ossuary_juggernaut", 1), ("crypt_halberdier", 3))),
        trigger_waves(T(0.6, ("necrotic_sky_serpent", 1)), T(0.3, ("bone_vanguard", 5), ("wraith_swarm", 3)))),
        "wyvern_flights", "Something long and green-lit swims through the clouds under the islands.",
        ["heavy_interceptor"], 166, ch("no_air_losses"), hazard=THERMALS_ISLES),
    # 077 — grave howitzers shelling from long range
    _stage(77, "Ashfall Plains", "open_plains", compose(
        opener_horde(["rusted_legionary", "hollow_guard"], k=1.05, group=2, interval=7),
        artillery_line(["grave_howitzer"], guard="crypt_halberdier", k=1.0, start=45, until=480, barricade_x=2160),
        air_raid(["gravewing_stalker", "banshee_wing"], k=1.0, start=16, t=150, n=5),
        set_pieces(E(200, ("grave_howitzer", 1), ("hollow_guard", 3)), E(290, ("stitchback_giant", 1), ("gravewing_stalker", 4))),
        trigger_waves(T(0.6, ("grave_howitzer", 1), ("rusted_legionary", 4)), T(0.3, ("crypt_halberdier", 4), ("banshee_wing", 2)))),
        "air_ground_pincer", "Grey ash falls on the plains like snow. It is coming from the howitzers.",
        ["rocketwing"], 168, ch("base_above", frac=0.6), hazard=GALE),
    # 078 — cathedral ghast stunning the line
    _stage(78, "Broken Crown Ridge", "broken_ridge", compose(
        opener_horde(["rusted_legionary", "bone_vanguard"], k=0.72, group=2, interval=7.5),
        shield_wall("hollow_guard", "night_seer", k=0.7, start=24, until=420),
        air_raid(["gravewing_stalker", "ossuary_flier"], k=0.85, start=18, t=160, n=4),
        set_pieces(E(250, ("cathedral_ghast", 1), ("bone_vanguard", 3)), E(330, ("tomb_gargoyle", 3), ("hollow_guard", 3))),
        trigger_waves(T(0.45, ("funeral_bell_keeper", 1), ("hollow_guard", 3)), T(0.25, ("grave_warden", 2), ("gravewing_stalker", 4)))),
        "gunship_hunt", "On the crown of the ridge a cathedral walks. Its bell strikes and the line stands still.",
        ["mobile_flak_fortress"], 170, ch("max_losses", n=36)),
    # 079 — phantom armada: haunted flying machines and airbarges; escort objective
    _stage(79, "Phantom Armada", "airborne_ruins", compose(
        opener_horde(["rusted_legionary", "crypt_halberdier"], k=1.0, group=2, interval=7.5),
        dict(tracks=[R("haunted_flying_machine", 16, 18, 2, 12)], events=[], triggers=[], structures=[]),
        set_pieces(E(100, ("infected_airbarge", 1), ("haunted_flying_machine", 3)), E(210, ("infected_airbarge", 1)), E(300, ("infected_airbarge", 1), ("ossuary_juggernaut", 1))),
        trigger_waves(T(0.6, ("haunted_flying_machine", 4), ("rusted_legionary", 4)), T(0.3, ("infected_airbarge", 1), ("crypt_halberdier", 4)))),
        "convoy_defense", "Ghost-lit hulls drift out of the clouds in line abreast. Your supply barge is already underway.",
        ["heavy_skybreaker"], 172, ch("escort"), escort=ESCORT_079),
    # 080 — BOSS: The Hollow Admiral
    _stage(80, "The Ghost Fleet", "airborne_ruins", compose(
        boss_arena([("bone_vanguard", 13, 2), ("hollow_guard", 30, 1), ("haunted_flying_machine", 26, 2)], k=1.0, until=660),
        trigger_waves(T(0.6, ("crypt_halberdier", 4), ("haunted_flying_machine", 3)), T(0.3, ("rusted_legionary", 5), ("ossuary_flier", 3)))),
        "boss_hollow_admiral", "Moored in the cloud sea, a drowned flagship waits with its guns run out. Its admiral never left the bridge.",
        ["forgewatch_frigate", "bombard_zeppelin"], 350, ch("kill_boss_by", seconds=510), boss=dict(id="hollow_admiral", t=55),
        base_hp=8200, gold=600),
    # 081 — bone wyvern packs
    _stage(81, "Wyvern Downs", "open_plains", compose(
        opener_horde(["rusted_legionary", "hollow_guard"], k=1.05, group=2, interval=7),
        dict(tracks=[R("bone_wyvern", 20, 26, 2, 17), R("gravewing_stalker", 30, 22, 2, 14)], events=[], triggers=[], structures=[]),
        set_pieces(E(160, ("bone_wyvern", 4)), E(260, ("stitchback_giant", 1), ("bone_wyvern", 3))),
        trigger_waves(T(0.6, ("bone_wyvern", 3), ("hollow_guard", 3)), T(0.3, ("bone_wyvern", 3), ("rusted_legionary", 5)))),
        "wyvern_flights", "The downs roll green to the horizon. Wyvern packs hunt them in threes.",
        ["pressure_regulator"], 174, ch("no_air_losses"), hazard=GALE),
    # 082 — necrotic beacons and soul turrets
    _stage(82, "The Fallen Spire", "shattered_fort", compose(
        opener_horde(["rusted_legionary", "bone_vanguard"], k=0.85, group=2, interval=7.5),
        support_cluster([("necrotic_beacon", 2300)]),
        flak_belt([("soul_turret", 2020), ("grave_flak_spire", 2180)]),
        air_raid(["banshee_wing", "ossuary_flier"], k=1.0, start=20, t=170, n=4),
        set_pieces(E(250, ("ossuary_juggernaut", 1), ("hollow_guard", 3))),
        trigger_waves(T(0.6, ("grave_warden", 3), ("banshee_wing", 2)), T(0.3, ("bone_vanguard", 5), ("ossuary_flier", 3)))),
        "flak_belt", "The spire fell across the fort. Its beacons still burn, and its turrets still turn.",
        ["battlefield_surveyors"], 176, ch("kill_structures")),
    # 083 — gale + flak belt
    _stage(83, "Galeward Heights", "broken_ridge", compose(
        opener_horde(["rusted_legionary", "crypt_halberdier"], k=1.05, group=2, interval=7),
        flak_belt([("grave_flak_spire", 1600), ("grave_flak_spire", 1820), ("soul_turret", 2050), ("grave_flak_spire", 2260)]),
        air_raid(["gravewing_stalker", "bone_wyvern"], k=0.95, start=20, t=160, n=4),
        dict(tracks=[R("bone_bolt_thrower", 50, 60, 1, 42, until=470)], events=[], triggers=[], structures=[]),
        set_pieces(E(260, ("stitchback_giant", 1), ("crypt_halberdier", 3))),
        trigger_waves(T(0.6, ("hollow_guard", 4), ("gravewing_stalker", 4)), T(0.3, ("bone_wyvern", 3), ("rusted_legionary", 4)))),
        "flak_belt", "Wind and flak on the heights: the sky is closed until the guns below it fall.",
        ["siege_sapper_tank"], 178, ch("max_types", n=8), hazard=GALE_HARD),
    # 084 — mostly air over a narrow causeway
    _stage(84, "Isles Adrift", "airborne_ruins", compose(
        opener_horde(["bone_vanguard"], k=0.85, group=2, interval=8),
        sky_host(["wraith_swarm", "ossuary_flier", "bone_wyvern"], k=1.1, start=10),
        set_pieces(E(120, ("necrotic_sky_serpent", 1), ("wraith_swarm", 3)), E(220, ("infected_airbarge", 1), ("bone_wyvern", 2)), E(300, ("ossuary_juggernaut", 1), ("crypt_halberdier", 3))),
        trigger_waves(T(0.6, ("bone_wyvern", 3), ("bone_vanguard", 4)), T(0.3, ("necrotic_sky_serpent", 1), ("crypt_halberdier", 4)))),
        "sky_superiority", "Islands drift apart and together. The only ground is a causeway one cart wide.",
        ["boiler_ram"], 180, ch("base_above", frac=0.6), hazard=THERMALS_ISLES),
    # 085 — funeral bell keepers and ossuary callers
    _stage(85, "Dirge Fields", "open_plains", compose(
        opener_horde(["rusted_legionary", "hollow_guard"], k=0.74, group=2, interval=7.5),
        dict(tracks=[R("funeral_bell_keeper", 50, 52, 1, 36, until=400), R("ossuary_caller", 70, 56, 1, 40, until=420)], events=[], triggers=[], structures=[]),
        air_raid(["banshee_wing", "gravewing_stalker"], k=1.0, start=18, t=160, n=5),
        set_pieces(E(240, ("stitchback_giant", 1), ("rusted_legionary", 3)), E(330, ("bone_devourer", 1))),
        trigger_waves(T(0.6, ("funeral_bell_keeper", 1), ("hollow_guard", 3)), T(0.3, ("bone_devourer", 1), ("banshee_wing", 2)))),
        "air_ground_pincer", "The bells never stop on the dirge fields. Every toll calls more of the buried up.",
        ["steamtread_heavy_carrier"], 182, ch("time_under", seconds=690)),
    # 086 — a gravewing stalker mass
    _stage(86, "Gravewing Roost", "broken_ridge", compose(
        opener_horde(["crypt_halberdier", "bone_vanguard"], k=1.0, group=2, interval=7),
        dict(tracks=[R("gravewing_stalker", 8, 12, 3, 7.5), R("rotwing", 30, 24, 2, 15)], events=[], triggers=[], structures=[]),
        set_pieces(E(100, ("gravewing_stalker", 10)), E(200, ("gravewing_stalker", 10), ("bone_drake", 1)), E(300, ("ossuary_juggernaut", 1), ("gravewing_stalker", 8))),
        trigger_waves(T(0.6, ("gravewing_stalker", 8)), T(0.3, ("gravewing_stalker", 8), ("crypt_halberdier", 4)))),
        "wyvern_flights", "Every ledge of the roost is a nest. When one stalker screams, they all do.",
        ["claw_harvester"], 184, ch("max_losses", n=40), hazard=STORM_LIGHT),
    # 087 — flyers + siege together
    _stage(87, "Rampart of Wings", "shattered_fort", compose(
        opener_horde(["hollow_guard", "rusted_legionary"], k=1.05, group=2, interval=7),
        artillery_line(["grave_howitzer", "rot_launcher"], guard="crypt_halberdier", k=1.0, start=40, until=460, barricade_x=2180),
        sky_host(["tomb_gargoyle", "banshee_wing"], k=0.95, start=16),
        set_pieces(E(200, ("bone_drake", 1), ("tomb_gargoyle", 3)), E(290, ("stitchback_giant", 1), ("ossuary_juggernaut", 1))),
        trigger_waves(T(0.6, ("bone_drake", 1), ("hollow_guard", 4)), T(0.3, ("grave_howitzer", 1), ("banshee_wing", 3)))),
        "combined_assault", "Guns on the rampart, wings over it. Neither front can wait for the other.",
        ["mortar_walker"], 186, ch("base_above", frac=0.6)),
    # 088 — heavy lightning storm, escort objective
    _stage(88, "Stormcrown", "airborne_ruins", compose(
        opener_horde(["bone_vanguard", "crypt_halberdier"], k=0.85, group=2, interval=7.5),
        air_raid(["bone_wyvern", "ossuary_flier"], k=0.85, start=18, t=140, n=3),
        flak_belt([("grave_flak_spire", 2000), ("grave_flak_spire", 2200)]),
        set_pieces(E(170, ("infected_airbarge", 1), ("haunted_flying_machine", 2)), E(330, ("ossuary_juggernaut", 1), ("crypt_halberdier", 3))),
        trigger_waves(T(0.6, ("bone_wyvern", 2), ("bone_vanguard", 3)), T(0.3, ("necrotic_sky_serpent", 1), ("hollow_guard", 3)))),
        "convoy_defense", "The storm wears the island like a crown. The barge has to cross under it all the same.",
        ["furnace_stalker"], 188, ch("escort"), hazard=STORM_HEAVY, escort=ESCORT_088),
    # 089 — the act's combined-arms exam
    _stage(89, "The Last Clear Sky", "open_plains", compose(
        finale(["rusted_legionary", "hollow_guard", "crypt_halberdier"], ["night_seer", "funeral_bell_keeper"],
               ["gravewing_stalker", "bone_wyvern"], k=0.64, until=440),
        flak_belt([("grave_flak_spire", 2000), ("soul_turret", 2220)]),
        set_pieces(E(160, ("bone_drake", 1), ("tomb_gargoyle", 3)), E(280, ("grave_howitzer", 1), ("stitchback_giant", 1)), E(300, ("infected_airbarge", 1), ("necrotic_sky_serpent", 1))),
        trigger_waves(T(0.6, ("ossuary_juggernaut", 1), ("bone_wyvern", 3)), T(0.3, ("stitchback_giant", 1), ("banshee_wing", 3)))),
        "combined_assault", "Past the plains the storms begin and do not end. This is the last clear sky; spend it well.",
        ["thundercoil_frame"], 196, ch("max_losses", n=44), hazard=GALE),
    # 090 — BOSS: Dread Sky Tyrant (Act III finale)
    _stage(90, "Throne of Storms", "airborne_ruins", compose(
        boss_arena([("rusted_legionary", 15, 2), ("hollow_guard", 30, 1), ("crypt_halberdier", 38, 1)], k=1.0, until=680),
        dict(tracks=[R("gravewing_stalker", 30, 30, 2, 20)], events=[], triggers=[], structures=[]),
        trigger_waves(T(0.6, ("hollow_guard", 4), ("bone_wyvern", 2)), T(0.3, ("crypt_halberdier", 4), ("gravewing_stalker", 4)))),
        "boss_dread_sky_tyrant", "A throne of black cloud sits on the storm's eye. The thing on it has been waiting for a dwarven sky.",
        ["thunderbarge", "ironhold_carrier"], 380, ch("kill_boss_by", seconds=600), boss=dict(id="dread_sky_tyrant", t=55),
        hazard=dict(STORM_LIGHT, interval=14), base_hp=8800, gold=640),
]

assert len(ACT3) == 30
