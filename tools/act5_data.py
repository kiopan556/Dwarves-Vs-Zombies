"""M008: Act V, stages 121-150 — "The Black Rift".

At the edge of the world the land is ash and bone. The sky tears open in violet wounds, the ruined citadels
of the undead kings stand in tiers, and at the end of the road is the gate into the undead realm itself.
The darkest, grandest act: the dwarves bring everything they have, the undead throw their kings and
colossi at them.

Built with tools/stage_kit.py like Acts II-IV. New in this act:
  * hazards      `rift_tears`  portals open at seeded x positions with a 2 s telegraph and spill a small
                               group from the stage's pool; a tear has HP, and destroying it early closes it
                 `eclipse`     periodic darkness: unit ranges drop 25 % on both sides, except units that
                               carry light or spotting (scouts, spotter balloons, rune-sight scouts) and
                               anything standing in their light
                 `soul_storm`  drifting soul wisps that heal undead and burn dwarves they pass; flak and
                               anti-air can shoot them down
  * obelisk ward rift obelisks power the undead line: undead near an obelisk take 15 % less damage
                 (`Rift.OBELISK_*`), so artillery that breaks the obelisk belt pays off
  * challenge    `no_spills`   (close every rift tear before it spills)
Bosses: The Hollow King (130), Gravewing Sovereign (140), The Rift Lich (150, the two-front finale).

Blueprints follow the M008 master prompt §9 in order (none was awarded before, so none becomes Sparks):
121-129 one T5 war machine each, 130 the Skyforge Dreadnought and King's Anvil, 131-139 the last nine,
141-149 Sparks only (every unit is reachable by then), 140 and 150 Sparks plus a cosmetic banner.
"""
from stage_kit import (R, E, T, compose, make_stage, opener_horde, shield_wall, artillery_line, air_raid,
                       monster_breakthrough, support_cluster, boss_arena, finale, trigger_waves, set_pieces, ch,
                       flak_belt, sky_host, corrupted_column, obelisk_belt, honour_guard)

# hazards ---------------------------------------------------------------------------------
# rift tears: every `interval` s a tear opens at a seeded x (2 s telegraph), then stays open `open` s and spills
# `spill` undead from `pool` unless destroyed first (it has `hp`)
TEARS = dict(kind="rift_tears", interval=30, warn=2.0, open=6.0, hp=380, spill=3, x0=900, x1=2000,
             pool=["riftbound_legionary", "black_rot_infantry", "night_seer"])
TEARS_FAST = dict(TEARS, interval=17, warn=1.5, open=5.0, spill=2, hp=340)
TEARS_EDGE = dict(TEARS, interval=26, spill=3, pool=["riftbound_legionary", "grave_knight", "spirit_binder"])
# eclipse: darkness for `duration` s every `interval` s; ranges x `range_mult` unless lit
ECLIPSE = dict(kind="eclipse", interval=58, duration=16, first=45, range_mult=0.75)
ECLIPSE_LONG = dict(ECLIPSE, interval=52, duration=20, first=40)
# soul storm: every `interval` s, `wisps` soul wisps drift in from the rift side at low altitude; each heals undead
# (`heal` HP/s) and burns dwarves (`damage`/s) within `radius`; wisps have `hp` and fly in the mid band (flak/AA)
SOULS = dict(kind="soul_storm", interval=11, wisps=2, radius=58, heal=16, damage=12, speed=44, hp=90)
SOULS_HEAVY = dict(SOULS, interval=8, wisps=2, heal=15, damage=11)


def _stage(n, name, env, parts, theme, tag, unlock, sparks, challenge, hazard=None, boss=None, base_hp=None, gold=None,
           max_alive=None, heroic=None, gold_bonus=None, banner=None):
    local = n - 121
    rw = dict(sparks=sparks, unlock=unlock)
    if banner:
        rw["banner"] = banner
    st = make_stage(name, env, parts,
                    base_hp=base_hp if base_hp else 8800 + local * 60,
                    start_gold=gold if gold else 500 + local * 4,
                    max_alive=max_alive if max_alive else min(62, 56 + local // 4),
                    theme=theme, tag=tag, rewards=rw, challenge=challenge, hazard=hazard, boss=boss)
    if heroic is not None:
        st["heroic"] = heroic
    if gold_bonus:
        st["gold_bonus"] = gold_bonus
    return st


def _sp(n):
    """Sparks for a regular Act V stage: 240 at 121 rising to ~320 at 149 (master prompt §9)."""
    return 240 + int(round((n - 121) * 2.85))


ACT5 = [
    # 121 — act opener: riftbound legionaries march out of the ash
    _stage(121, "The Grey Waste", "necro_waste", compose(
        opener_horde(["black_rot_infantry", "riftbound_legionary"], k=0.92, group=2, interval=7),
        dict(tracks=[R("night_seer", 34, 28, 1, 19, until=470)], events=[], triggers=[], structures=[]),
        air_raid(["banshee_wing", "bone_wyvern"], k=0.66, start=22, t=170, n=4),
        set_pieces(E(130, ("riftbound_legionary", 4), ("dread_executioner", 2)), E(250, ("cathedral_ghast", 1), ("black_rot_infantry", 3)), E(340, ("walking_crypt", 1))),
        trigger_waves(T(0.6, ("riftbound_legionary", 4), ("banshee_wing", 3)), T(0.3, ("cathedral_ghast", 1), ("black_rot_infantry", 4)))),
        "rift_storm", "Ash falls like snow on a land of bone. Out of it march soldiers who were never alive in this world.",
        ["titan_maintenance_crew"], _sp(121), ch("max_losses", n=44)),
    # 122 — rift tears introduced
    _stage(122, "Rift Scar", "rift_sky", compose(
        opener_horde(["black_rot_infantry", "hollow_guard"], k=0.9, group=2, interval=7),
        dict(tracks=[R("riftbound_legionary", 30, 26, 1, 18)], events=[], triggers=[], structures=[]),
        air_raid(["rift_crow", "bone_wyvern"], k=0.68, start=20, t=160, n=5),
        set_pieces(E(200, ("bone_drake", 1), ("rift_crow", 4)), E(300, ("ossuary_juggernaut", 1), ("riftbound_legionary", 3))),
        trigger_waves(T(0.6, ("riftbound_legionary", 3), ("rift_crow", 4)), T(0.3, ("bone_drake", 1), ("hollow_guard", 4)))),
        "rift_storm", "The sky is cracked here, and the cracks are not empty. Close them before they open wide.",
        ["worldhammer_siege_tank"], _sp(122), ch("no_spills"), hazard=TEARS),
    # 123 — ossuary champions with caller support
    _stage(123, "Bonecrown Approach", "ruined_citadel", compose(
        opener_horde(["black_rot_infantry", "hollow_guard"], k=0.9, group=2, interval=7),
        shield_wall("ossuary_champion", "ossuary_caller", k=0.66, start=24, until=440),
        air_raid(["banshee_wing", "tomb_gargoyle"], k=0.66, start=22, t=170, n=3),
        set_pieces(E(180, ("ossuary_champion", 3), ("ossuary_caller", 1)), E(300, ("cathedral_ghast", 1), ("hollow_guard", 3))),
        trigger_waves(T(0.6, ("ossuary_champion", 2), ("banshee_wing", 3)), T(0.3, ("ossuary_caller", 2), ("black_rot_infantry", 4)))),
        "colossus_march", "The approach to the citadel is paved with crowns. The champions who wore them still stand guard.",
        ["royal_skyguard"], _sp(123), ch("base_above", frac=0.6)),
    # 124 — eclipse introduced; scouting matters
    _stage(124, "Ashveil", "necro_waste", compose(
        opener_horde(["black_rot_infantry", "riftbound_legionary"], k=0.88, group=2, interval=7.5),
        dict(tracks=[R("night_seer", 30, 24, 1, 16, until=470), R("spirit_binder", 48, 30, 1, 20, until=470)], events=[], triggers=[], structures=[]),
        air_raid(["banshee_wing", "rift_crow"], k=0.66, start=22, t=170, n=4),
        set_pieces(E(160, ("dread_executioner", 3), ("night_seer", 2)), E(290, ("blackroot_abomination", 1), ("riftbound_legionary", 3))),
        trigger_waves(T(0.6, ("spirit_binder", 2), ("banshee_wing", 3)), T(0.3, ("blackroot_abomination", 1), ("black_rot_infantry", 3)))),
        "endless_dead", "When the dead sun goes out, only the dwarves who carry their own light can see what is coming.",
        ["iron_bastion_prime"], _sp(124), ch("max_types", n=8), hazard=ECLIPSE),
    # 125 — necrotic sky serpents among the floating shards
    _stage(125, "Sky Fracture", "rift_sky", compose(
        opener_horde(["black_rot_infantry", "hollow_guard"], k=0.8, group=2, interval=7),
        sky_host(["rift_crow", "banshee_wing", "necrotic_sky_serpent"], k=0.54, start=14),
        set_pieces(E(150, ("necrotic_sky_serpent", 1), ("bone_wyvern", 2)), E(280, ("necrotic_sky_serpent", 1), ("riftbound_legionary", 4))),
        trigger_waves(T(0.6, ("necrotic_sky_serpent", 1)), T(0.3, ("bone_drake", 1), ("hollow_guard", 4)))),
        "fortress_sky", "Shards of land drift toward the rift, and serpents of rot coil between them.",
        ["deepforge_titan"], _sp(125), ch("no_air_losses")),
    # 126 — rift obelisks powering the undead line
    _stage(126, "Gate of Lanterns", "realm_gate", compose(
        opener_horde(["black_rot_infantry", "riftbound_legionary"], k=0.86, group=2, interval=7),
        obelisk_belt([1900, 2180]),
        dict(tracks=[R("funeral_bell_keeper", 50, 50, 1, 36, until=360)], events=[], triggers=[], structures=[]),
        air_raid(["banshee_wing", "bone_wyvern"], k=0.66, start=22, t=170, n=3),
        set_pieces(E(180, ("grave_knight", 3), ("funeral_bell_keeper", 1)), E(300, ("walking_crypt", 1), ("riftbound_legionary", 3))),
        trigger_waves(T(0.6, ("riftbound_legionary", 4), ("banshee_wing", 2)), T(0.3, ("walking_crypt", 1), ("black_rot_infantry", 3)))),
        "twin_front_siege", "Lanterns of violet fire line the gate road. Every one of them feeds the dead that walk beneath it.",
        ["stormforge_bomber"], _sp(126), ch("kill_structures")),
    # 127 — a siege of tiered walls; howitzers
    _stage(127, "Citadel Outworks", "ruined_citadel", compose(
        opener_horde(["hollow_guard", "black_rot_infantry"], k=0.92, group=2, interval=7),
        artillery_line(["grave_howitzer"], guard="grave_knight", k=0.72, start=45, until=420, barricade_x=2120),
        support_cluster([("cursed_barricade", 1880), ("wraith_beacon", 2260)]),
        air_raid(["tomb_gargoyle", "banshee_wing"], k=0.64, start=22, t=170, n=3),
        set_pieces(E(200, ("grave_howitzer", 1), ("grave_knight", 2)), E(310, ("cathedral_ghast", 1), ("hollow_guard", 3))),
        trigger_waves(T(0.6, ("grave_howitzer", 1), ("black_rot_infantry", 4)), T(0.3, ("grave_knight", 3), ("tomb_gargoyle", 3)))),
        "colossus_march", "Wall above wall, the outworks climb toward the keep. The howitzers on top never stopped firing.",
        ["skyhammer_assault_craft"], _sp(127), ch("kill_structures")),
    # 128 — soul storm introduced
    _stage(128, "Wailing Dunes", "necro_waste", compose(
        opener_horde(["black_rot_infantry", "riftbound_legionary"], k=0.9, group=2, interval=7),
        dict(tracks=[R("spirit_binder", 36, 28, 1, 18, until=460)], events=[], triggers=[], structures=[]),
        air_raid(["banshee_wing", "bone_wyvern"], k=0.64, start=22, t=170, n=3),
        set_pieces(E(170, ("dread_executioner", 3), ("spirit_binder", 1)), E(290, ("blackroot_abomination", 1), ("black_rot_infantry", 3))),
        trigger_waves(T(0.6, ("riftbound_legionary", 3), ("banshee_wing", 3)), T(0.3, ("dread_executioner", 3), ("bone_wyvern", 2)))),
        "rift_storm", "The dunes are made of the dead, and the wind that crosses them is made of their souls.",
        ["brass_leviathan"], _sp(128), ch("base_above", frac=0.6), hazard=SOULS),
    # 129 — the king's honour guard
    _stage(129, "Throne Road", "ruined_citadel", compose(
        opener_horde(["hollow_guard", "black_rot_infantry"], k=0.88, group=2, interval=7),
        honour_guard(["grave_knight", "ossuary_champion", "dread_executioner"], k=0.58, start=40, until=480),
        dict(tracks=[R("funeral_bell_keeper", 60, 50, 1, 36, until=360)], events=[], triggers=[], structures=[]),
        air_raid(["banshee_wing", "tomb_gargoyle"], k=0.64, start=22, t=170, n=3),
        set_pieces(E(200, ("ossuary_champion", 3), ("grave_knight", 2)), E(320, ("cathedral_ghast", 1), ("dread_executioner", 2))),
        trigger_waves(T(0.6, ("grave_knight", 3), ("banshee_wing", 3)), T(0.3, ("ossuary_champion", 3), ("hollow_guard", 3)))),
        "final_gauntlet", "The last road to the Hollow Throne. The king's honour guard lines it, and every knight bows to no one.",
        ["mountain_colossus"], _sp(129), ch("max_losses", n=46)),
    # 130 — BOSS: The Hollow King
    _stage(130, "Hall of the Hollow Crown", "ruined_citadel", compose(
        boss_arena([("black_rot_infantry", 13, 2), ("hollow_guard", 32, 1), ("banshee_wing", 30, 2)], k=0.85, until=680),
        dict(tracks=[R("funeral_bell_keeper", 120, 70, 1, 50, until=330)], events=[], triggers=[], structures=[]),
        trigger_waves(T(0.6, ("grave_knight", 2), ("hollow_guard", 3)), T(0.3, ("ossuary_champion", 2), ("banshee_wing", 3)))),
        "boss_hollow_king", "The throne hall is open to the sky. On the throne sits a crown with nothing under it, and it rises.",
        ["skyforge_dreadnought", "kings_anvil"], 480, ch("kill_boss_by", seconds=600), boss=dict(id="hollow_king", t=55),
        base_hp=10400, gold=720),
    # 131 — relief after the King: many tears, little warning (lighter waves)
    _stage(131, "Riftfall", "rift_sky", compose(
        opener_horde(["black_rot_infantry", "riftbound_legionary"], k=0.78, group=2, interval=7.5),
        air_raid(["rift_crow", "banshee_wing"], k=0.62, start=20, t=170, n=4),
        set_pieces(E(200, ("bone_drake", 1), ("riftbound_legionary", 3)), E(320, ("ossuary_juggernaut", 1), ("black_rot_infantry", 3))),
        trigger_waves(T(0.6, ("riftbound_legionary", 3), ("rift_crow", 4)), T(0.3, ("bone_drake", 1), ("black_rot_infantry", 4)))),
        "rift_storm", "The rift is falling apart, and pieces of it are falling here. Listen for the sky splitting.",
        ["arcwing_superiority_craft"], _sp(131), ch("no_spills"), hazard=TEARS_FAST),
    # 132 — the first plague colossus
    _stage(132, "The Walking Plague", "necro_waste", compose(
        opener_horde(["black_rot_infantry", "plague_mauler"], k=0.88, group=2, interval=7),
        dict(tracks=[R("spirit_binder", 40, 30, 1, 20, until=460)], events=[], triggers=[], structures=[]),
        air_raid(["banshee_wing", "bone_wyvern"], k=0.64, start=22, t=170, n=3),
        set_pieces(E(160, ("plague_colossus", 1), ("plague_mauler", 3)), E(330, ("dread_executioner", 3), ("black_rot_infantry", 3))),
        trigger_waves(T(0.6, ("plague_mauler", 4), ("banshee_wing", 3)), T(0.3, ("riftbound_legionary", 3), ("bone_wyvern", 2)))),
        "colossus_march", "Something the size of a hill is walking out of the ash, and the ground rots where it steps.",
        ["dreadnought_landship"], _sp(132), ch("max_losses", n=46)),
    # 133 — ground on a shard bridge, heavy air above
    _stage(133, "Shattered Sky Bridge", "rift_sky", compose(
        opener_horde(["hollow_guard", "riftbound_legionary"], k=0.84, group=2, interval=7.5),
        sky_host(["rift_crow", "bone_wyvern", "bone_drake", "banshee_wing"], k=0.78, start=12),
        set_pieces(E(180, ("necrotic_sky_serpent", 1), ("bone_drake", 1)), E(300, ("ossuary_juggernaut", 1), ("hollow_guard", 3))),
        trigger_waves(T(0.6, ("bone_drake", 1), ("rift_crow", 4)), T(0.3, ("necrotic_sky_serpent", 1), ("riftbound_legionary", 3)))),
        "fortress_sky", "A bridge of broken land over nothing. The sky above it is thick with wings.",
        ["colossal_skybreaker"], _sp(133), ch("no_air_losses")),
    # 134 — riftbound legionary phalanx + obelisks
    _stage(134, "Gate Wardens", "realm_gate", compose(
        opener_horde(["black_rot_infantry", "riftbound_legionary"], k=0.84, group=2, interval=7),
        obelisk_belt([2000, 2220]),
        dict(tracks=[R("rift_conjurer", 60, 44, 1, 32, until=400)], events=[], triggers=[], structures=[]),
        air_raid(["banshee_wing", "rift_crow"], k=0.64, start=22, t=170, n=4),
        set_pieces(E(170, ("riftbound_legionary", 6)), E(300, ("riftbound_legionary", 5), ("rift_conjurer", 1))),
        trigger_waves(T(0.6, ("riftbound_legionary", 5)), T(0.3, ("riftbound_legionary", 4), ("banshee_wing", 3)))),
        "twin_front_siege", "The wardens of the gate stand shield to shield, and the obelisks behind them hum with power.",
        ["hammerfall_goliath"], _sp(134), ch("kill_structures")),
    # 135 — the rift maw (colossus that devours and heals)
    _stage(135, "Maw Fields", "necro_waste", compose(
        opener_horde(["black_rot_infantry", "hollow_guard"], k=0.88, group=2, interval=7),
        dict(tracks=[R("night_seer", 36, 28, 1, 18, until=460)], events=[], triggers=[], structures=[]),
        air_raid(["banshee_wing", "bone_wyvern"], k=0.64, start=22, t=170, n=3),
        set_pieces(E(170, ("rift_maw", 1), ("hollow_guard", 3)), E(330, ("cathedral_ghast", 1), ("black_rot_infantry", 3))),
        trigger_waves(T(0.6, ("hollow_guard", 4), ("banshee_wing", 3)), T(0.3, ("dread_executioner", 3), ("bone_wyvern", 2)))),
        "colossus_march", "The fields are pocked with craters that breathe. One of them is getting up.",
        ["mountain_ark"], _sp(135), ch("max_losses", n=48)),
    # 136 — drakes and wyverns herald the Sovereign
    _stage(136, "Sovereign's Shadow", "rift_sky", compose(
        opener_horde(["black_rot_infantry", "riftbound_legionary"], k=0.84, group=2, interval=7.5),
        sky_host(["bone_wyvern", "bone_drake", "banshee_wing"], k=0.54, start=12),
        flak_belt([("soul_turret", 2120)]),
        set_pieces(E(160, ("bone_drake", 1)), E(280, ("bone_drake", 1), ("bone_wyvern", 2)), E(360, ("necrotic_sky_serpent", 1))),
        trigger_waves(T(0.6, ("bone_drake", 1), ("bone_wyvern", 2)), T(0.3, ("bone_drake", 2), ("riftbound_legionary", 3)))),
        "fortress_sky", "A shadow crosses the shards, too big for any cloud. Her heralds fly ahead of it.",
        ["embercore_titan"], _sp(136), ch("no_air_losses")),
    # 137 — eclipse + citadel siege
    _stage(137, "The Drowned Crown", "ruined_citadel", compose(
        opener_horde(["hollow_guard", "black_rot_infantry"], k=0.88, group=2, interval=7),
        artillery_line(["grave_howitzer"], guard="ossuary_champion", k=0.8, start=50, until=460, barricade_x=2140),
        dict(tracks=[R("night_seer", 40, 30, 1, 20, until=460)], events=[], triggers=[], structures=[]),
        air_raid(["banshee_wing", "tomb_gargoyle"], k=0.64, start=22, t=170, n=3),
        set_pieces(E(190, ("ossuary_champion", 3), ("night_seer", 2)), E(320, ("cathedral_ghast", 1), ("grave_knight", 2))),
        trigger_waves(T(0.6, ("grave_howitzer", 1), ("hollow_guard", 4)), T(0.3, ("ossuary_champion", 3), ("banshee_wing", 3)))),
        "endless_dead", "The citadel sank into its own moat long ago. In the dark of the eclipse, its guns wake up.",
        ["skyhammer_battleship"], _sp(137), ch("base_above", frac=0.6), hazard=ECLIPSE),
    # 138 — a belt of rift obelisks and wraith beacons
    _stage(138, "Obelisk Line", "realm_gate", compose(
        opener_horde(["riftbound_legionary", "black_rot_infantry"], k=0.86, group=2, interval=7),
        obelisk_belt([1780, 2040, 2260], beacons=[1920, 2160]),
        air_raid(["banshee_wing", "rift_crow"], k=0.62, start=22, t=170, n=4),
        set_pieces(E(190, ("grave_knight", 3), ("rift_conjurer", 1)), E(310, ("walking_crypt", 1), ("riftbound_legionary", 3))),
        trigger_waves(T(0.6, ("riftbound_legionary", 4), ("banshee_wing", 3)), T(0.3, ("walking_crypt", 1), ("grave_knight", 2)))),
        "twin_front_siege", "A line of obelisks and beacons stretches to the horizon. Break it, or the dead never stop coming.",
        ["rune_citadel_airship"], _sp(138), ch("kill_structures")),
    # 139 — a desperate holding battle: big waves, generous Gold, a stronghold under siege
    _stage(139, "Last Light of Stonehelm", "necro_waste", compose(
        finale(["black_rot_infantry", "riftbound_legionary", "dread_executioner"], ["night_seer", "spirit_binder"],
               ["banshee_wing", "bone_wyvern"], k=0.86, until=480),
        set_pieces(E(90, ("riftbound_legionary", 6), ("black_rot_infantry", 4)), E(180, ("cathedral_ghast", 1), ("dread_executioner", 4)),
                   E(270, ("plague_colossus", 1), ("riftbound_legionary", 4)), E(360, ("walking_crypt", 1), ("bone_drake", 1))),
        trigger_waves(T(0.6, ("riftbound_legionary", 5), ("banshee_wing", 3)), T(0.3, ("dread_executioner", 4), ("bone_wyvern", 3)))),
        "endless_dead", "A messenger from Stonehelm: the home hold is besieged. Hold this ground and the siege breaks with you.",
        ["grand_forge_carrier"], _sp(139), ch("base_above", frac=0.5), gold=900, gold_bonus=6.0),
    # 140 — BOSS: Gravewing Sovereign
    _stage(140, "Eye of the Storm", "rift_sky", compose(
        boss_arena([("black_rot_infantry", 13, 2), ("riftbound_legionary", 28, 1), ("hollow_guard", 34, 1)], k=1.0, until=680),
        dict(tracks=[R("bone_wyvern", 40, 34, 1, 22, until=560)], events=[], triggers=[], structures=[]),
        trigger_waves(T(0.6, ("riftbound_legionary", 3), ("bone_wyvern", 2)), T(0.3, ("dread_executioner", 2), ("banshee_wing", 3)))),
        "boss_gravewing_sovereign", "At the centre of the storm the air is still, and in the stillness something vast is circling.",
        [], 540, ch("kill_boss_by", seconds=600), boss=dict(id="gravewing_sovereign", t=55),
        base_hp=10800, gold=760, banner="storm_breaker"),
    # 141 — relief after the Sovereign: soul storm + tears
    _stage(141, "Edge of the Rift", "realm_gate", compose(
        opener_horde(["black_rot_infantry", "riftbound_legionary"], k=0.78, group=2, interval=7.5),
        air_raid(["banshee_wing", "rift_crow"], k=0.61, start=22, t=170, n=4),
        set_pieces(E(200, ("grave_knight", 3)), E(320, ("cathedral_ghast", 1), ("riftbound_legionary", 3))),
        trigger_waves(T(0.6, ("riftbound_legionary", 3), ("banshee_wing", 3)), T(0.3, ("grave_knight", 3), ("rift_crow", 4)))),
        "rift_storm", "At the edge of the rift the world frays: souls blow out of it like smoke, and it tears wherever it likes.",
        [], _sp(141), ch("no_spills"), hazard=[dict(SOULS, interval=13), dict(TEARS_EDGE, interval=32)]),
    # 142 — every elite infantry type
    _stage(142, "The Unmade Legion", "necro_waste", compose(
        opener_horde(["black_rot_infantry", "riftbound_legionary"], k=0.84, group=2, interval=7),
        dict(tracks=[R("dread_executioner", 30, 32, 1, 22), R("ossuary_champion", 46, 40, 1, 28), R("grave_knight", 60, 44, 1, 30), R("rift_conjurer", 70, 50, 1, 36, until=420)], events=[], triggers=[], structures=[]),
        air_raid(["banshee_wing", "bone_wyvern"], k=0.62, start=22, t=170, n=3),
        set_pieces(E(170, ("ossuary_champion", 3), ("dread_executioner", 3)), E(300, ("riftbound_legionary", 5), ("grave_knight", 2))),
        trigger_waves(T(0.6, ("ossuary_champion", 3), ("banshee_wing", 3)), T(0.3, ("riftbound_legionary", 5), ("dread_executioner", 2)))),
        "final_gauntlet", "Legionary, champion, executioner, knight: every soldier the dead ever made, unmade and remade for this.",
        [], _sp(142), ch("max_losses", n=48)),
    # 143 — infected airbarges and serpents vs dwarven flying fortresses
    _stage(143, "Skyfortress Breach", "rift_sky", compose(
        opener_horde(["hollow_guard", "black_rot_infantry"], k=0.88, group=2, interval=7.5),
        dict(tracks=[R("rift_crow", 16, 20, 2, 13), R("banshee_wing", 40, 32, 1, 22), R("necrotic_sky_serpent", 120, 90, 1, 70, until=480)], events=[], triggers=[], structures=[]),
        set_pieces(E(120, ("infected_airbarge", 1)), E(260, ("infected_airbarge", 1), ("hollow_guard", 3)), E(380, ("necrotic_sky_serpent", 1), ("riftbound_legionary", 3))),
        trigger_waves(T(0.6, ("infected_airbarge", 1), ("hollow_guard", 4)), T(0.3, ("necrotic_sky_serpent", 1), ("rift_crow", 4)))),
        "fortress_sky", "A fleet of rotting barges rides the rift winds toward the dwarven line. Meet it in the sky.",
        [], _sp(143), ch("no_air_losses")),
    # 144 — ossuary champions, cathedral ghasts
    _stage(144, "Ossuary of Kings", "ruined_citadel", compose(
        opener_horde(["hollow_guard", "ossuary_champion"], k=0.82, group=2, interval=7),
        dict(tracks=[R("ossuary_caller", 40, 32, 1, 22, until=460)], events=[], triggers=[], structures=[]),
        air_raid(["banshee_wing", "tomb_gargoyle"], k=0.64, start=22, t=170, n=3),
        set_pieces(E(160, ("cathedral_ghast", 1), ("ossuary_champion", 2)), E(300, ("ossuary_champion", 2), ("ossuary_caller", 1)), E(380, ("cathedral_ghast", 1), ("hollow_guard", 3))),
        trigger_waves(T(0.6, ("cathedral_ghast", 1)), T(0.3, ("ossuary_champion", 3), ("banshee_wing", 3)))),
        "colossus_march", "The undead kings are buried here, a thousand deep. Their chapels walk, and their champions answer the bells.",
        [], _sp(144), ch("max_losses", n=48)),
    # 145 — a fortified obelisk position
    _stage(145, "Rift Bastion", "realm_gate", compose(
        opener_horde(["black_rot_infantry", "riftbound_legionary"], k=0.84, group=2, interval=7),
        obelisk_belt([1960, 2200], beacons=[2080]),
        support_cluster([("cursed_barricade", 1820)]),
        dict(tracks=[R("grave_howitzer", 70, 70, 1, 52, until=400)], events=[], triggers=[], structures=[]),
        air_raid(["banshee_wing", "bone_wyvern"], k=0.62, start=22, t=170, n=3),
        set_pieces(E(200, ("grave_knight", 3), ("rift_conjurer", 1)), E(320, ("walking_crypt", 1), ("riftbound_legionary", 3))),
        trigger_waves(T(0.6, ("riftbound_legionary", 4), ("banshee_wing", 2)), T(0.3, ("grave_knight", 3), ("bone_wyvern", 3)))),
        "twin_front_siege", "The dead have fortified the last approach: walls, obelisks, turrets, guns. Take it apart.",
        [], _sp(145), ch("kill_structures")),
    # 146 — a heavy soul storm
    _stage(146, "Storm of Souls", "rift_sky", compose(
        opener_horde(["black_rot_infantry", "riftbound_legionary"], k=0.84, group=2, interval=7.5),
        dict(tracks=[R("spirit_binder", 40, 30, 1, 20, until=460)], events=[], triggers=[], structures=[]),
        air_raid(["banshee_wing", "bone_drake"], k=0.61, start=22, t=170, n=3),
        set_pieces(E(190, ("dread_executioner", 3), ("spirit_binder", 1)), E(310, ("ossuary_juggernaut", 1), ("riftbound_legionary", 3))),
        trigger_waves(T(0.6, ("riftbound_legionary", 4), ("banshee_wing", 3)), T(0.3, ("dread_executioner", 3), ("bone_drake", 1)))),
        "rift_storm", "The rift exhales, and the sky fills with the souls of everyone the dead ever took. Shoot them down.",
        [], _sp(146), ch("base_above", frac=0.6), hazard=SOULS_HEAVY),
    # 147 — plague colossus + rift maw together
    _stage(147, "The Black Steps", "ruined_citadel", compose(
        opener_horde(["hollow_guard", "black_rot_infantry"], k=0.84, group=2, interval=7),
        dict(tracks=[R("ossuary_caller", 44, 34, 1, 24, until=460)], events=[], triggers=[], structures=[]),
        air_raid(["banshee_wing", "tomb_gargoyle"], k=0.62, start=22, t=170, n=3),
        set_pieces(E(160, ("plague_colossus", 1), ("hollow_guard", 3)), E(240, ("rift_maw", 1), ("black_rot_infantry", 3)), E(360, ("cathedral_ghast", 1))),
        trigger_waves(T(0.6, ("ossuary_champion", 3), ("banshee_wing", 3)), T(0.3, ("dread_executioner", 3), ("tomb_gargoyle", 3)))),
        "colossus_march", "Two colossi climb the black steps side by side. Between them there is no room for anything else.",
        [], _sp(147), ch("max_losses", n=50)),
    # 148 — a combined-arms exam on both fronts
    _stage(148, "Threshold", "realm_gate", compose(
        finale(["black_rot_infantry", "riftbound_legionary", "grave_knight"], ["rift_conjurer", "night_seer"],
               ["bone_wyvern", "banshee_wing"], k=0.5, until=400),
        obelisk_belt([2240]),
        set_pieces(E(170, ("cathedral_ghast", 1), ("bone_drake", 1)), E(270, ("necrotic_sky_serpent", 1), ("riftbound_legionary", 4)), E(350, ("rift_maw", 1))),
        trigger_waves(T(0.6, ("grave_knight", 3), ("bone_wyvern", 3)), T(0.3, ("infected_airbarge", 1), ("hollow_guard", 4)))),
        "twin_front_siege", "The threshold of the undead realm. Whatever is on the other side is watching how you cross.",
        [], _sp(148), ch("max_losses", n=50), hazard=dict(TEARS_EDGE, interval=50, x0=1300)),
    # 149 — the last battle before the gate: everything the undead have
    _stage(149, "The Final Muster", "necro_waste", compose(
        finale(["black_rot_infantry", "riftbound_legionary", "ossuary_champion"], ["spirit_binder", "rift_conjurer"],
               ["banshee_wing", "bone_wyvern"], k=0.5, until=300),
        set_pieces(E(150, ("plague_colossus", 1), ("dread_executioner", 2)), E(250, ("necrotic_sky_serpent", 1), ("infected_airbarge", 1)),
                   E(350, ("rift_maw", 1), ("grave_knight", 2))),
        trigger_waves(T(0.6, ("ossuary_champion", 3), ("bone_drake", 1)), T(0.3, ("cursed_ironclad", 1), ("riftbound_legionary", 4)))),
        "final_gauntlet", "Everything the dead have left stands between the army and the gate. Everything the dwarves have stands against it.",
        [], _sp(149), ch("max_losses", n=54), hazard=dict(SOULS, interval=14)),
    # 150 — FINAL BOSS: The Rift Lich (two-front finale)
    _stage(150, "Into the Black Rift", "realm_gate", compose(
        boss_arena([("black_rot_infantry", 13, 2), ("riftbound_legionary", 26, 1), ("rift_crow", 22, 2)], k=1.0, until=720),
        dict(tracks=[R("night_seer", 70, 44, 1, 30, until=580)], events=[], triggers=[], structures=[]),
        trigger_waves(T(0.6, ("grave_knight", 2), ("banshee_wing", 3)), T(0.3, ("ossuary_champion", 2), ("bone_wyvern", 2)))),
        "boss_rift_lich", "The gate stands open on the Black Rift. Its master steps out to meet the last army of the dwarves.",
        [], 600, ch("kill_boss_by", seconds=720), boss=dict(id="rift_lich", t=60),
        base_hp=11200, gold=800, banner="rift_sealer"),
]

assert len(ACT5) == 30
