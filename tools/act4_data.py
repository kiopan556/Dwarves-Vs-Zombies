"""M007: Act IV, stages 091-120 — "The Fallen Foundries".

The dwarves march down into the dead foundry-cities of an older dwarven age: soot-black brick canyons,
cold blast furnaces, silent assembly halls crawling with undead workers, and graveyards of colossal war
machines. It is grim and heavy, and it is personal: the enemy now wears dwarven iron. Corrupted dwarven
war machines are the act's signature threat.

Built with tools/stage_kit.py like Acts II and III. New in this act:
  * wreck reclamation  every Act IV stage carries `wrecks: true` (set in gen_data.py): destroyed dwarven
                       vehicles, war frames and aircraft leave a wreck for ~20 s; an undead corruptor
                       (corpse priest, rot channeler, ash hexer) that reaches one raises a corrupted machine,
                       a dwarven salvage unit clears it first and refunds a little Gold (`reclaim_squad`)
  * production lines   timed thrall bursts (`production_line`)
  * corrupted columns  corrupted machines advancing behind an infantry screen (`corrupted_column`)
  * hazards            `furnace_vents`, `slag_flow`, `steam_leak`, and collapsing gantries (a `rockfall`
                       variant with `variant: "gantry"`: bigger damage, smaller radius, longer telegraph)
  * challenge          `no_reclaims` (let the undead reclaim no wreck)
Bosses: The Fallen Titan (100), Ashen Forge Tyrant (110), Corpse Colossus (120). T5 opens at 105.

Blueprints follow the M007 master prompt §8 in order; no unit in the list was awarded earlier, so none is
replaced by Sparks.
"""
from stage_kit import (R, E, T, compose, make_stage, opener_horde, shield_wall, artillery_line, air_raid,
                       monster_breakthrough, support_cluster, boss_arena, finale, trigger_waves, set_pieces, ch,
                       flak_belt, sky_host, reclaim_squad, production_line, corrupted_column)

# hazards ---------------------------------------------------------------------------------
# furnace vents: fixed grates erupt in turn every `interval` s after a 1 s glow (both sides, machines take 50 %)
VENTS = dict(kind="furnace_vents", vents=[760, 1120, 1480, 1840], interval=10, damage=80, radius=40, warn=1.0)
VENTS_HOT = dict(kind="furnace_vents", vents=[640, 920, 1200, 1480, 1760, 2040], interval=9, damage=90, radius=42, warn=1.0)
# slag flow: a molten river creeps from x0 toward x1 for `duration` s, every `interval` s (ground only)
SLAG = dict(kind="slag_flow", x0=1560, x1=1180, interval=42, duration=15, dps=34, slow=0.45, speed=34)
SLAG_STAIR = dict(kind="slag_flow", x0=1900, x1=1250, interval=36, duration=17, dps=36, slow=0.5, speed=42)
# steam leak: a burst pipe; dwarven machines near it refill Steam Pressure (+regen/s), everyone inside is scalded
STEAM = dict(kind="steam_leak", pipes=[1260], radius=80, dps=7, regen=5)
STEAM_TWIN = dict(kind="steam_leak", pipes=[1040, 1620], radius=76, dps=8, regen=5)
# collapsing gantries: girders drop with a long telegraph
GANTRY = dict(kind="rockfall", variant="gantry", interval=13, damage=150, radius=36, warn=2.2)
GANTRY_CITY = dict(kind="rockfall", variant="gantry", interval=11, damage=160, radius=36, warn=2.2)


def _stage(n, name, env, parts, theme, tag, unlock, sparks, challenge, hazard=None, boss=None, base_hp=None, gold=None,
           max_alive=None, open_tier=None, heroic=None):
    local = n - 91
    rw = dict(sparks=sparks, unlock=unlock)
    if open_tier is not None:
        rw["open_tier"] = open_tier
    st = make_stage(name, env, parts,
                    base_hp=base_hp if base_hp else 8600 + local * 90,
                    start_gold=gold if gold else 380 + local * 3,
                    max_alive=max_alive if max_alive else min(62, 54 + local // 3),
                    theme=theme, tag=tag, rewards=rw, challenge=challenge, hazard=hazard, boss=boss)
    if heroic is not None:
        st["heroic"] = heroic
    return st


def _sp(n):
    """Sparks for a regular Act IV stage: 182 at 091 rising to ~252 at 119."""
    return 180 + int(round((n - 91) * 2.5))


ACT4 = [
    # 091 — act opener: the first gravegun tank behind a thrall column
    _stage(91, "Cinderhaven Gates", "industrial_city", compose(
        opener_horde(["black_rot_infantry", "hollow_guard"], k=0.95, group=2, interval=7),
        dict(tracks=[R("cursed_dwarf_thrall", 16, 14, 2, 9, until=500)], events=[], triggers=[], structures=[]),
        air_raid(["rotwing", "banshee_wing"], k=0.85, start=24, t=170, n=4),
        set_pieces(E(110, ("gravegun_tank", 1), ("cursed_dwarf_thrall", 4)), E(240, ("gravegun_tank", 1), ("hollow_guard", 3)), E(320, ("ossuary_juggernaut", 1))),
        trigger_waves(T(0.6, ("cursed_dwarf_thrall", 4), ("rotwing", 3)), T(0.3, ("gravegun_tank", 1), ("black_rot_infantry", 4)))),
        "corrupted_armor", "The gates of Cinderhaven stand open. Something rolls out of them on dwarven tracks.",
        ["royal_iron_guard"], _sp(91), ch("max_losses", n=36)),
    # 092 — possessed drillwalkers tunnel through the assembly floor
    _stage(92, "Rustworks Row", "infested_factory", compose(
        opener_horde(["black_rot_infantry", "plague_mauler"], k=0.95, group=2, interval=7),
        dict(tracks=[R("possessed_drillwalker", 60, 62, 1, 44), R("burrow_horror", 45, 48, 1, 34)], events=[], triggers=[], structures=[]),
        air_raid(["rotwing", "tomb_gargoyle"], k=0.8, start=22, t=180, n=3),
        set_pieces(E(150, ("possessed_drillwalker", 2), ("black_rot_infantry", 3)), E(290, ("bone_devourer", 1), ("plague_mauler", 3))),
        trigger_waves(T(0.6, ("possessed_drillwalker", 1), ("rotwing", 3)), T(0.3, ("burrow_horror", 2), ("plague_mauler", 3)))),
        "corrupted_armor", "The assembly line still runs. What it builds now digs.",
        ["thunder_rifleman"], _sp(92), ch("base_above", frac=0.6)),
    # 093 — furnace vents introduced
    _stage(93, "The Cold Forge", "destroyed_forge", compose(
        opener_horde(["black_rot_infantry", "hollow_guard"], k=0.95, group=2, interval=7),
        shield_wall("dread_executioner", "cinder_wraith", k=0.85, start=20, until=480),
        air_raid(["banshee_wing", "rotwing"], k=0.85, start=20, t=160, n=4),
        set_pieces(E(200, ("risen_copperback", 2), ("hollow_guard", 3)), E(300, ("ossuary_juggernaut", 1), ("cinder_wraith", 2))),
        trigger_waves(T(0.6, ("dread_executioner", 2), ("banshee_wing", 2)), T(0.3, ("risen_copperback", 1), ("black_rot_infantry", 4)))),
        "furnace_hazard", "The great forge went cold a century ago. Its vents remember how to burn.",
        ["furnace_assault_trooper"], _sp(93), ch("max_types", n=8), hazard=VENTS),
    # 094 — wreck reclamation introduced: corruptors raise fallen machines
    _stage(94, "Boneyard of Engines", "mech_graveyard", compose(
        opener_horde(["black_rot_infantry", "hollow_guard"], k=0.95, group=2, interval=7),
        reclaim_squad(["corpse_priest", "rot_channeler"], k=0.9, start=40, until=520),
        dict(tracks=[R("risen_copperback", 70, 64, 1, 46)], events=[], triggers=[], structures=[]),
        air_raid(["haunted_flying_machine", "rotwing"], k=0.85, start=18, t=170, n=4),
        set_pieces(E(140, ("gravegun_tank", 1), ("corpse_priest", 2)), E(260, ("ossuary_juggernaut", 1), ("rot_channeler", 2))),
        trigger_waves(T(0.6, ("rot_channeler", 2), ("haunted_flying_machine", 3)), T(0.3, ("gravegun_tank", 1), ("hollow_guard", 4)))),
        "wreck_reclaim", "Rusted colossi lie half-buried here. The priests walk among them, singing to the iron.",
        ["heavy_recovery_crawler"], _sp(94), ch("no_reclaims")),
    # 095 — grave howitzers in the chimney forest; flak spires
    _stage(95, "Smokestack Alley", "industrial_city", compose(
        opener_horde(["black_rot_infantry", "plague_mauler"], k=1.0, group=2, interval=7),
        artillery_line(["grave_howitzer"], guard="hollow_guard", k=0.9, start=45, until=460, barricade_x=2160),
        flak_belt([("grave_flak_spire", 1820), ("grave_flak_spire", 2060)]),
        air_raid(["banshee_wing", "tomb_gargoyle"], k=0.85, start=22, t=170, n=3),
        set_pieces(E(210, ("gravegun_tank", 1), ("plague_mauler", 3)), E(300, ("grave_howitzer", 1), ("hollow_guard", 3))),
        trigger_waves(T(0.6, ("grave_howitzer", 1), ("black_rot_infantry", 4)), T(0.3, ("tomb_gargoyle", 3), ("plague_mauler", 3)))),
        "flak_belt", "A forest of chimneys, and howitzers nested in it like crows.",
        ["counter_curse_technician"], _sp(95), ch("kill_structures")),
    # 096 — thrall bursts in timed waves like a production line
    _stage(96, "Assembly Line of the Dead", "infested_factory", compose(
        opener_horde(["black_rot_infantry", "plague_mauler"], k=1.0, group=2, interval=7.5),
        production_line("cursed_dwarf_thrall", start=25, every=40, n=6, until=480),
        dict(tracks=[R("dread_executioner", 50, 34, 1, 24)], events=[], triggers=[], structures=[]),
        air_raid(["rotwing", "haunted_flying_machine"], k=0.85, start=20, t=150, n=4),
        set_pieces(E(230, ("cursed_ironclad", 1)), E(330, ("possessed_drillwalker", 1), ("black_rot_infantry", 4))),
        trigger_waves(T(0.6, ("cursed_dwarf_thrall", 6)), T(0.3, ("cursed_dwarf_thrall", 6), ("dread_executioner", 2)))),
        "production_line", "Every forty seconds the line clanks forward and another batch of thralls steps off it.",
        ["rune_cannon"], _sp(96), ch("max_losses", n=38)),
    # 097 — slag flow introduced
    _stage(97, "Slagrun", "destroyed_forge", compose(
        opener_horde(["black_rot_infantry", "hollow_guard"], k=0.95, group=2, interval=7),
        dict(tracks=[R("flesh_charger", 50, 42, 1, 30), R("ash_hexer", 34, 26, 1, 18, until=480)], events=[], triggers=[], structures=[]),
        air_raid(["banshee_wing", "bone_wyvern"], k=0.8, start=22, t=180, n=3),
        set_pieces(E(160, ("risen_copperback", 2)), E(280, ("ossuary_juggernaut", 1), ("hollow_guard", 3))),
        trigger_waves(T(0.6, ("flesh_charger", 2), ("banshee_wing", 2)), T(0.3, ("risen_copperback", 1), ("black_rot_infantry", 4)))),
        "slag_hazard", "The crucibles cracked when the forge died. The slag still runs when the deep fires stir.",
        ["siegecrawler"], _sp(97), ch("base_above", frac=0.6), hazard=SLAG),
    # 098 — massed gravegun tanks: anti-armour exam
    _stage(98, "Gravegun Yards", "mech_graveyard", compose(
        opener_horde(["black_rot_infantry", "hollow_guard"], k=0.7, group=2, interval=7.5),
        corrupted_column(["gravegun_tank", "risen_copperback"], "hollow_guard", k=0.6, start=100),
        air_raid(["haunted_flying_machine", "tomb_gargoyle"], k=0.8, start=20, t=170, n=3),
        reclaim_squad(["rot_channeler"], k=0.7, start=60, until=420),
        set_pieces(E(200, ("gravegun_tank", 2)), E(310, ("gravegun_tank", 1), ("hollow_guard", 3))),
        trigger_waves(T(0.6, ("gravegun_tank", 1), ("haunted_flying_machine", 3)), T(0.3, ("gravegun_tank", 2)))),
        "anti_armor_exam", "Row on row of grave-guns, parked where they fell. Not all of them stay parked.",
        ["thunderrail_tank_destroyer"], _sp(98), ch("max_losses", n=40),
        heroic=dict(hp_mult=1.05, interval_mult=0.92, structure=dict(enemy="cursed_barricade", x=2150), event=dict(t=240, spawn=[["risen_copperback", 1], ["black_rot_infantry", 3]]))),
    # 099 — the first cursed ironclad
    _stage(99, "Cursed Ironworks", "infested_factory", compose(
        opener_horde(["black_rot_infantry", "plague_mauler"], k=0.85, group=2, interval=7),
        dict(tracks=[R("cinder_wraith", 30, 26, 1, 18, until=440)], events=[], triggers=[], structures=[]),
        air_raid(["rotwing", "banshee_wing"], k=0.8, start=20, t=160, n=4),
        reclaim_squad(["corpse_priest"], k=0.6, start=70, until=420),
        set_pieces(E(150, ("cursed_ironclad", 1), ("black_rot_infantry", 3)), E(290, ("cursed_ironclad", 1), ("plague_mauler", 2)), E(360, ("possessed_drillwalker", 1))),
        trigger_waves(T(0.6, ("cursed_ironclad", 1)), T(0.3, ("possessed_drillwalker", 1), ("rotwing", 4)))),
        "corrupted_armor", "The ironworks made walkers once. One of them still walks, and it remembers the drill.",
        ["anvilbreaker"], _sp(99), ch("time_under", seconds=660)),
    # 100 — BOSS: The Fallen Titan
    _stage(100, "Titanfall Foundry", "mech_graveyard", compose(
        boss_arena([("black_rot_infantry", 13, 2), ("hollow_guard", 28, 1), ("rotwing", 24, 2)], k=1.0, until=660),
        reclaim_squad(["corpse_priest"], k=0.55, start=90, until=480),
        trigger_waves(T(0.6, ("risen_copperback", 1), ("hollow_guard", 3)), T(0.3, ("hollow_guard", 3), ("rotwing", 3)))),
        "boss_fallen_titan", "Scaffolding still rings the Titan where it fell. Something has climbed inside and lit the boiler.",
        ["siegebellow", "furnace_guardian"], 380, ch("kill_boss_by", seconds=540), boss=dict(id="fallen_titan", t=55),
        base_hp=8800, gold=620),
    # 101 — ash hexers and cinder wraiths
    _stage(101, "Ashen Boulevard", "industrial_city", compose(
        opener_horde(["black_rot_infantry", "hollow_guard"], k=0.95, group=2, interval=7),
        dict(tracks=[R("ash_hexer", 30, 28, 1, 19, until=420), R("cinder_wraith", 44, 30, 1, 20, until=420)], events=[], triggers=[], structures=[]),
        air_raid(["banshee_wing", "tomb_gargoyle"], k=0.8, start=20, t=170, n=3),
        set_pieces(E(200, ("gravegun_tank", 1), ("hollow_guard", 3)), E(330, ("cathedral_ghast", 1))),
        trigger_waves(T(0.6, ("ash_hexer", 3), ("banshee_wing", 2)), T(0.3, ("cinder_wraith", 3), ("black_rot_infantry", 4)))),
        "ash_casters", "Ash drifts down the boulevard like grey snow. The hexers walk in it, and so does fire.",
        ["runebreaker_infantry"], _sp(101), ch("max_losses", n=40)),
    # 102 — steam leaks introduced; a risk/reward placement
    _stage(102, "Bellows of Hate", "destroyed_forge", compose(
        opener_horde(["black_rot_infantry", "dread_executioner"], k=0.78, group=2, interval=7.5),
        dict(tracks=[R("risen_copperback", 70, 66, 1, 48, until=480)], events=[], triggers=[], structures=[]),
        air_raid(["rotwing", "bone_wyvern"], k=0.75, start=22, t=170, n=3),
        reclaim_squad(["ash_hexer"], k=0.75, start=60, until=440),
        set_pieces(E(230, ("cursed_ironclad", 1), ("black_rot_infantry", 3)), E(330, ("ossuary_juggernaut", 1), ("dread_executioner", 2))),
        trigger_waves(T(0.6, ("risen_copperback", 1), ("rotwing", 4)), T(0.3, ("dread_executioner", 3), ("bone_wyvern", 2)))),
        "steam_hazard", "The great bellows burst their pipes. Stand in the steam and your engines drink; stand too long and you cook.",
        ["heavy_gatling_dwarf"], _sp(102), ch("base_above", frac=0.6), hazard=STEAM),
    # 103 — burrow horrors + drillwalkers from below
    _stage(103, "Drillbit Depths", "infested_factory", compose(
        opener_horde(["black_rot_infantry", "plague_mauler"], k=0.95, group=2, interval=7),
        dict(tracks=[R("burrow_horror", 30, 32, 1, 22), R("possessed_drillwalker", 70, 58, 1, 42)], events=[], triggers=[], structures=[]),
        air_raid(["tomb_gargoyle", "rotwing"], k=0.8, start=22, t=170, n=3),
        set_pieces(E(140, ("burrow_horror", 3)), E(240, ("possessed_drillwalker", 2), ("burrow_horror", 2)), E(320, ("bone_devourer", 1))),
        trigger_waves(T(0.6, ("burrow_horror", 2), ("plague_mauler", 3)), T(0.3, ("possessed_drillwalker", 1), ("tomb_gargoyle", 3)))),
        "from_below", "The floor of the drill hall is not a floor any more. Listen for it.",
        ["mobile_forge_crew"], _sp(103), ch("max_types", n=8)),
    # 104 — heavy reclamation pressure; salvage crews are vital
    _stage(104, "Wreckers' Field", "mech_graveyard", compose(
        opener_horde(["black_rot_infantry", "hollow_guard"], k=0.86, group=2, interval=7),
        reclaim_squad(["corpse_priest", "rot_channeler"], k=0.72, start=45, until=440),
        dict(tracks=[R("risen_copperback", 70, 64, 1, 46, until=460), R("haunted_flying_machine", 20, 24, 2, 16)], events=[], triggers=[], structures=[]),
        set_pieces(E(170, ("gravegun_tank", 1), ("rot_channeler", 2)), E(270, ("cursed_ironclad", 1), ("corpse_priest", 2))),
        trigger_waves(T(0.6, ("gravegun_tank", 1), ("ash_hexer", 2)), T(0.3, ("cursed_ironclad", 1), ("haunted_flying_machine", 3)))),
        "wreck_reclaim", "Every wreck on this field is a gift to the priests. Leave them nothing.",
        ["automated_turret_crew"], _sp(104), ch("no_reclaims")),
    # 105 — a big combined assault; opens T5 research
    _stage(105, "The Great Smelter", "destroyed_forge", compose(
        finale(["black_rot_infantry", "hollow_guard", "dread_executioner"], ["ash_hexer", "cinder_wraith"],
               ["banshee_wing", "tomb_gargoyle"], k=0.74, until=440),
        flak_belt([("grave_flak_spire", 1980), ("soul_turret", 2200)]),
        set_pieces(E(170, ("gravegun_tank", 1)), E(260, ("ossuary_juggernaut", 1), ("risen_copperback", 1)), E(340, ("infected_airbarge", 1), ("cursed_ironclad", 1))),
        trigger_waves(T(0.6, ("cursed_ironclad", 1), ("hollow_guard", 4)), T(0.3, ("gravegun_tank", 2), ("banshee_wing", 3)))),
        "combined_assault", "The Great Smelter poured the iron of a kingdom. Take it back, and the oldest forge-songs can be sung again.",
        ["mountainshield_heavy_tank", "firestorm_assault_tank"], 260, ch("max_losses", n=46), open_tier=5, hazard=VENTS),
    # 106 — a dense skyline flak belt; gargoyles
    _stage(106, "Chimney Wood", "industrial_city", compose(
        opener_horde(["hollow_guard", "black_rot_infantry"], k=0.95, group=2, interval=7),
        flak_belt([("grave_flak_spire", 1700), ("soul_turret", 1960), ("grave_flak_spire", 2220)]),
        dict(tracks=[R("tomb_gargoyle", 16, 22, 2, 15), R("bone_wyvern", 40, 36, 1, 25)], events=[], triggers=[], structures=[]),
        dict(tracks=[R("grave_howitzer", 60, 64, 1, 46, until=440)], events=[], triggers=[], structures=[]),
        set_pieces(E(200, ("tomb_gargoyle", 5)), E(300, ("gravegun_tank", 1), ("hollow_guard", 3))),
        trigger_waves(T(0.6, ("tomb_gargoyle", 4), ("black_rot_infantry", 4)), T(0.3, ("bone_wyvern", 3), ("hollow_guard", 3)))),
        "flak_belt", "Chimneys stand as thick as trees, and something with stone wings roosts in every one.",
        ["dreadplate_breaker"], _sp(106), ch("kill_structures")),
    # 107 — collapsing gantries; plague maulers
    _stage(107, "Hall of Pistons", "infested_factory", compose(
        opener_horde(["plague_mauler", "black_rot_infantry"], k=1.0, group=2, interval=7),
        dict(tracks=[R("plague_mauler", 30, 18, 2, 12), R("rot_channeler", 40, 30, 1, 20, until=480)], events=[], triggers=[], structures=[]),
        air_raid(["rotwing", "haunted_flying_machine"], k=0.85, start=20, t=160, n=4),
        set_pieces(E(190, ("cursed_ironclad", 1), ("plague_mauler", 3)), E(300, ("bone_devourer", 1), ("plague_mauler", 4))),
        trigger_waves(T(0.6, ("plague_mauler", 5)), T(0.3, ("possessed_drillwalker", 1), ("rotwing", 4)))),
        "gantry_hazard", "Pistons the size of towers still hang from the gantries. The rivets are giving way one by one.",
        ["siege_hammer_walker"], _sp(107), ch("max_losses", n=42), hazard=GANTRY),
    # 108 — a walking crypt among the wrecks
    _stage(108, "Iron Ossuary", "mech_graveyard", compose(
        opener_horde(["hollow_guard", "black_rot_infantry"], k=0.95, group=2, interval=7),
        reclaim_squad(["corpse_priest", "rot_channeler"], k=0.9, start=40, until=500),
        air_raid(["banshee_wing", "bone_wyvern"], k=0.8, start=20, t=170, n=3),
        set_pieces(E(160, ("walking_crypt", 1), ("hollow_guard", 3)), E(280, ("risen_copperback", 2), ("corpse_priest", 1)), E(340, ("walking_crypt", 1))),
        trigger_waves(T(0.6, ("gravegun_tank", 1), ("banshee_wing", 3)), T(0.3, ("walking_crypt", 1)))),
        "monster_siege", "A crypt walks between the dead machines, and the dead machines get up behind it.",
        ["flak_colossus"], _sp(108), ch("no_reclaims")),
    # 109 — vents + slag together
    _stage(109, "Furnace Heart", "destroyed_forge", compose(
        opener_horde(["black_rot_infantry", "dread_executioner"], k=0.9, group=2, interval=7.5),
        dict(tracks=[R("cinder_wraith", 28, 22, 1, 15, until=470), R("flesh_charger", 60, 46, 1, 32)], events=[], triggers=[], structures=[]),
        air_raid(["bone_wyvern", "rotwing"], k=0.8, start=22, t=170, n=3),
        set_pieces(E(200, ("cursed_ironclad", 1), ("dread_executioner", 2)), E(300, ("ossuary_juggernaut", 1), ("risen_copperback", 1))),
        trigger_waves(T(0.6, ("flesh_charger", 2), ("bone_wyvern", 2)), T(0.3, ("risen_copperback", 2), ("black_rot_infantry", 4)))),
        "furnace_hazard", "At the heart of the forge the vents breathe and the slag runs. Cross between the breaths.",
        ["thunderstep_bruiser"], _sp(109), ch("base_above", frac=0.6), hazard=[VENTS, dict(SLAG, x0=1700, x1=1350, interval=46)]),
    # 110 — BOSS: Ashen Forge Tyrant
    _stage(110, "The Ash Throne", "destroyed_forge", compose(
        boss_arena([("black_rot_infantry", 13, 2), ("dread_executioner", 30, 1), ("banshee_wing", 26, 2)], k=1.0, until=660),
        dict(tracks=[R("ash_hexer", 60, 40, 1, 28, until=560)], events=[], triggers=[], structures=[]),
        trigger_waves(T(0.6, ("risen_copperback", 1), ("black_rot_infantry", 4)), T(0.3, ("cinder_wraith", 3), ("banshee_wing", 3)))),
        "boss_ashen_tyrant", "In the mouth of the great furnace sits a throne of ash. The Tyrant wears the forge like armour.",
        ["shredder_walker", "forge_bomber"], 420, ch("kill_boss_by", seconds=540), boss=dict(id="ashen_forge_tyrant", t=55),
        base_hp=9200, gold=660, hazard=dict(VENTS, interval=14)),
    # 111 — infected airbarges launching flyers
    _stage(111, "Carrier Wharf", "industrial_city", compose(
        opener_horde(["black_rot_infantry", "hollow_guard"], k=0.95, group=2, interval=7),
        dict(tracks=[R("haunted_flying_machine", 16, 18, 2, 12), R("dread_executioner", 40, 28, 1, 19)], events=[], triggers=[], structures=[]),
        set_pieces(E(100, ("infected_airbarge", 1)), E(200, ("infected_airbarge", 1), ("gravegun_tank", 1)), E(300, ("infected_airbarge", 1), ("hollow_guard", 4))),
        trigger_waves(T(0.6, ("infected_airbarge", 1), ("black_rot_infantry", 4)), T(0.3, ("haunted_flying_machine", 4), ("gravegun_tank", 1)))),
        "carrier_raid", "The wharf cranes still swing. The barges they load are full of wings.",
        ["thunder_rocket_battery"], _sp(111), ch("no_air_losses")),
    # 112 — bone devourers
    _stage(112, "Rotting Turbines", "infested_factory", compose(
        opener_horde(["plague_mauler", "black_rot_infantry"], k=0.95, group=2, interval=7),
        dict(tracks=[R("bone_devourer", 50, 44, 1, 30)], events=[], triggers=[], structures=[]),
        air_raid(["rotwing", "tomb_gargoyle"], k=0.85, start=20, t=160, n=4),
        reclaim_squad(["rot_channeler"], k=0.8, start=50, until=480),
        set_pieces(E(180, ("bone_devourer", 2), ("plague_mauler", 2)), E(300, ("cursed_ironclad", 1), ("bone_devourer", 1))),
        trigger_waves(T(0.6, ("bone_devourer", 1), ("rotwing", 3)), T(0.3, ("bone_devourer", 2), ("plague_mauler", 3)))),
        "monster_siege", "The turbine hall hums with flies. The devourers have made it a larder.",
        ["twin_flame_gunship"], _sp(112), ch("max_losses", n=44)),
    # 113 — blackroot abomination + cathedral ghast
    _stage(113, "Colossus Tracks", "mech_graveyard", compose(
        opener_horde(["hollow_guard", "black_rot_infantry"], k=0.95, group=2, interval=7),
        air_raid(["banshee_wing", "bone_wyvern"], k=0.85, start=20, t=160, n=3),
        reclaim_squad(["corpse_priest"], k=0.8, start=50, until=480),
        set_pieces(E(150, ("blackroot_abomination", 1), ("hollow_guard", 3)), E(260, ("cathedral_ghast", 1), ("black_rot_infantry", 4)), E(340, ("gravegun_tank", 2))),
        trigger_waves(T(0.6, ("blackroot_abomination", 1)), T(0.3, ("cathedral_ghast", 1), ("banshee_wing", 3)))),
        "monster_siege", "The colossi dragged themselves here to die. Their tracks are a road now, and the monsters use it.",
        ["siege_breaker_bomber"], _sp(113), ch("time_under", seconds=690)),
    # 114 — slag on a climbing lane
    _stage(114, "Molten Stair", "destroyed_forge", compose(
        opener_horde(["black_rot_infantry", "dread_executioner"], k=0.9, group=2, interval=7.5),
        dict(tracks=[R("ash_hexer", 30, 24, 1, 16, until=470), R("risen_copperback", 60, 56, 1, 40)], events=[], triggers=[], structures=[]),
        air_raid(["bone_wyvern", "banshee_wing"], k=0.8, start=22, t=170, n=3),
        set_pieces(E(200, ("cursed_ironclad", 1), ("dread_executioner", 2)), E(310, ("gravegun_tank", 1), ("ossuary_juggernaut", 1))),
        trigger_waves(T(0.6, ("risen_copperback", 1), ("bone_wyvern", 2)), T(0.3, ("dread_executioner", 3), ("ash_hexer", 2)))),
        "slag_hazard", "The stair climbs through the crucible hall. Slag comes down it faster than anything goes up.",
        ["riftshield_walker"], _sp(114), ch("max_losses", n=44), hazard=SLAG_STAIR),
    # 115 — flesh trebuchets and bone rams
    _stage(115, "Siegeworks", "industrial_city", compose(
        opener_horde(["hollow_guard", "black_rot_infantry"], k=0.95, group=2, interval=7),
        artillery_line(["flesh_trebuchet"], guard="dread_executioner", k=0.9, start=45, until=460, barricade_x=2150),
        dict(tracks=[R("bone_ram", 60, 48, 1, 34)], events=[], triggers=[], structures=[]),
        air_raid(["tomb_gargoyle", "rotwing"], k=0.85, start=20, t=170, n=3),
        set_pieces(E(220, ("bone_ram", 2), ("hollow_guard", 3)), E(310, ("flesh_trebuchet", 1), ("gravegun_tank", 1))),
        trigger_waves(T(0.6, ("bone_ram", 1), ("tomb_gargoyle", 3)), T(0.3, ("flesh_trebuchet", 1), ("black_rot_infantry", 4)))),
        "siege_works", "The siegeworks built engines for the old kings. The dead have learned to load them with themselves.",
        ["colossus_guard"], _sp(115), ch("kill_structures")),
    # 116 — spore cannons + reclamation
    _stage(116, "Plague Refinery", "infested_factory", compose(
        opener_horde(["plague_mauler", "black_rot_infantry"], k=0.95, group=2, interval=7),
        artillery_line(["plague_spore_cannon"], guard="hollow_guard", k=0.85, start=40, until=460),
        reclaim_squad(["corpse_priest", "rot_channeler"], k=0.9, start=40, until=500),
        air_raid(["rotwing", "haunted_flying_machine"], k=0.85, start=20, t=160, n=4),
        set_pieces(E(200, ("risen_copperback", 2), ("plague_mauler", 2)), E(300, ("cursed_ironclad", 1), ("corpse_priest", 1))),
        trigger_waves(T(0.6, ("plague_spore_cannon", 1), ("rotwing", 3)), T(0.3, ("gravegun_tank", 1), ("plague_mauler", 3)))),
        "wreck_reclaim", "The refinery brews plague in vats meant for oil. Its priests wait for your engines to fall.",
        ["arc_lance_gunner"], _sp(116), ch("no_reclaims")),
    # 117 — every corrupted machine type
    _stage(117, "The Scrapheap Crown", "mech_graveyard", compose(
        opener_horde(["black_rot_infantry", "hollow_guard"], k=0.78, group=2, interval=7.5),
        corrupted_column(["risen_copperback", "gravegun_tank"], "black_rot_infantry", k=0.7, start=50),
        dict(tracks=[R("haunted_flying_machine", 18, 22, 2, 14)], events=[], triggers=[], structures=[]),
        reclaim_squad(["ash_hexer"], k=0.8, start=50, until=480),
        set_pieces(E(160, ("possessed_drillwalker", 1), ("risen_copperback", 1)), E(250, ("cursed_ironclad", 1), ("infected_airbarge", 1)), E(330, ("gravegun_tank", 1), ("cursed_ironclad", 1))),
        trigger_waves(T(0.6, ("possessed_drillwalker", 1), ("haunted_flying_machine", 3)), T(0.3, ("cursed_ironclad", 1), ("black_rot_infantry", 4)))),
        "corrupted_armor", "On top of the great scrapheap the dead have built a crown of dwarven engines, and every one of them runs.",
        ["kingsguard_bulwark"], _sp(117), ch("max_losses", n=46),
        heroic=dict(hp_mult=1.05, interval_mult=0.92, event=dict(t=300, spawn=[["risen_copperback", 1], ["black_rot_infantry", 3]]))),
    # 118 — collapsing gantries in the city canyon
    _stage(118, "Ironfall Avenue", "industrial_city", compose(
        opener_horde(["hollow_guard", "plague_mauler"], k=0.95, group=2, interval=7),
        shield_wall("dread_executioner", "cinder_wraith", k=0.74, start=20, until=440),
        air_raid(["banshee_wing", "tomb_gargoyle"], k=0.8, start=20, t=170, n=3),
        set_pieces(E(200, ("gravegun_tank", 1), ("cursed_ironclad", 1)), E(310, ("cathedral_ghast", 1), ("hollow_guard", 3))),
        trigger_waves(T(0.6, ("dread_executioner", 3), ("banshee_wing", 2)), T(0.3, ("gravegun_tank", 1), ("plague_mauler", 4)))),
        "gantry_hazard", "Gantry bridges span the avenue between the foundry towers. They are coming down, one girder at a time.",
        ["mountain_siege_cannon"], _sp(118), ch("base_above", frac=0.6), hazard=GANTRY_CITY),
    # 119 — the act's combined-arms exam
    _stage(119, "Forge of Bones", "destroyed_forge", compose(
        finale(["black_rot_infantry", "hollow_guard", "dread_executioner"], ["ash_hexer", "cinder_wraith"],
               ["bone_wyvern", "banshee_wing"], k=0.66, until=440),
        reclaim_squad(["corpse_priest"], k=0.8, start=50, until=460),
        flak_belt([("grave_flak_spire", 2000), ("soul_turret", 2220)]),
        set_pieces(E(160, ("cursed_ironclad", 1), ("gravegun_tank", 1)), E(260, ("walking_crypt", 1), ("risen_copperback", 1)), E(320, ("infected_airbarge", 1), ("ossuary_juggernaut", 1))),
        trigger_waves(T(0.6, ("gravegun_tank", 1), ("bone_wyvern", 3)), T(0.3, ("cursed_ironclad", 1), ("hollow_guard", 4)))),
        "combined_assault", "A forge built of bones, burning in the dark. Everything the dead have learned, they bring here.",
        ["celestial_flak_array"], _sp(119), ch("max_losses", n=48), hazard=VENTS),
    # 120 — BOSS: Corpse Colossus (Act IV finale)
    _stage(120, "The Charnel Engine", "industrial_city", compose(
        boss_arena([("black_rot_infantry", 14, 2), ("hollow_guard", 30, 1), ("plague_mauler", 36, 1)], k=1.0, until=680),
        dict(tracks=[R("rotwing", 30, 28, 2, 18)], events=[], triggers=[], structures=[]),
        trigger_waves(T(0.6, ("risen_copperback", 1), ("hollow_guard", 3)), T(0.3, ("plague_mauler", 4), ("rotwing", 4)))),
        "boss_corpse_colossus", "A mountain of the dead fills the canyon between the foundry towers, and a siege engine is stitched into its back.",
        ["mountainbreaker", "master_fabricator_team"], 460, ch("kill_boss_by", seconds=600), boss=dict(id="corpse_colossus", t=55),
        base_hp=9600, gold=700),
]

assert len(ACT4) == 30
