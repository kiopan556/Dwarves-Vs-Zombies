"""M005: Act II, stages 031-060 — "The Blighted Frontier".

The dwarves push out of the mountains into the rotted lowlands: dead forests, plague marshes, the
gibbet-lined trade road and the fungus-choked lowland mines. Built with tools/stage_kit.py: each
stage is composed from encounter templates, then given its own set pieces, hazard, rewards,
tagline and challenge objective. Bosses: Blightroot Behemoth (040), Plague Regent (050),
Gravewing Matriarch (060).

Blueprint order follows the M005 master prompt §8. Its lists hold 8 units for the 9 regular stages
of blocks 041-049 and 051-059, so two never-awarded T2 units fill the gaps (Boiler Stomper at 047,
Bombard Gyro at 057). This is noted in the milestone report.
"""
from stage_kit import (R, E, T, compose, make_stage, opener_horde, shield_wall, artillery_line, air_raid,
                       monster_breakthrough, support_cluster, boss_arena, finale, trigger_waves, set_pieces, ch)

# hazards
MIASMA_LIGHT = dict(kind="miasma", interval=34, duration=20, dps=5.0, radius=85, speed=20)
MIASMA = dict(kind="miasma", interval=26, duration=22, dps=7.0, radius=100, speed=22)
MIASMA_DENSE = dict(kind="miasma", interval=17, duration=24, dps=9.0, radius=110, speed=18)
BOG = dict(kind="bog", spots=[1180, 1680], width=170, slow=0.4)
BOG_WIDE = dict(kind="bog", spots=[900, 1350, 1800], width=180, slow=0.45)
BOG_COURT = dict(kind="bog", spots=[1850], width=230, slow=0.4)


def _stage(n, name, env, parts, theme, tag, unlock, sparks, challenge, hazard=None, boss=None, base_hp=None, gold=None, max_alive=None, open_tier=None):
    local = n - 31
    rw = dict(sparks=sparks, unlock=unlock)
    if open_tier is not None:
        rw["open_tier"] = open_tier
    return make_stage(name, env, parts,
                      base_hp=base_hp if base_hp else 5400 + local * 70,
                      start_gold=gold if gold else 300 + local * 2,
                      max_alive=max_alive if max_alive else min(60, 50 + local // 3),
                      theme=theme, tag=tag, rewards=rw, challenge=challenge, hazard=hazard, boss=boss)


ACT2 = [
    # 031 — act opener: shambler hordes and blight bats; the first, light miasma
    _stage(31, "Blackbough Verge", "dead_forest", compose(
        opener_horde(["shambler", "blight_marauder"], k=1.12),
        air_raid(["blight_bat"], k=0.95, t=95, n=5),
        monster_breakthrough("plague_beast", 210, escort=("shambler", 5)),
        trigger_waves(T(0.5, ("blight_marauder", 3), ("blight_bat", 4)))),
        "plague_tide", "The forest died standing. Something in the grey boughs is breathing for it.",
        ["rune_cartridge_rifleman"], 105, ch("base_above", frac=0.6), hazard=MIASMA_LIGHT),
    # 032 — fungal hosts soak fire while rot hounds rush the flanks
    _stage(32, "Rotwood Crossing", "dead_forest", compose(
        opener_horde(["shambler"], k=1.0),
        dict(tracks=[R("fungal_host", 8, 14, 2, 9), R("rot_hound", 25, 18, 3, 11)], events=[], triggers=[], structures=[]),
        air_raid(["grave_moth"], k=0.9, start=30, t=150, n=4),
        set_pieces(E(110, ("rot_hound", 6)), E(220, ("bone_golem", 1), ("fungal_host", 3))),
        trigger_waves(T(0.5, ("fungal_host", 4), ("rot_hound", 4)))),
        "plague_tide", "Fungal hosts burst into spores when they fall. The hounds come in the fog behind them.",
        ["trench_guard"], 108, ch("max_losses", n=30)),
    # 033 — bog introduced; plague sprayers behind the mire
    _stage(33, "Weeping Fens", "plague_marsh", compose(
        opener_horde(["shambler", "pestilent_soldier"], k=1.0),
        shield_wall("black_rot_infantry", "plague_sprayer", k=1.0, start=12, until=560),
        air_raid(["blight_bat", "grave_moth"], k=0.9, start=24, t=170, n=4),
        set_pieces(E(120, ("plague_sprayer", 3), ("black_rot_infantry", 2))),
        trigger_waves(T(0.5, ("pestilent_soldier", 4), ("plague_sprayer", 2)))),
        "marsh_ambush", "The fens weep black water. Anything that stands in it stands still.",
        ["repeater_fusilier"], 110, ch("time_under", seconds=600), hazard=BOG),
    # 034 — spore cannons lob from range; grave moths swarm
    _stage(34, "Sporefall Hollow", "plague_marsh", compose(
        opener_horde(["shambler", "fungal_host"], k=1.0),
        artillery_line(["plague_spore_cannon"], guard="black_rot_infantry", k=1.0, start=45, until=480, barricade_x=2140),
        air_raid(["grave_moth", "blight_bat"], k=1.0, start=18, t=130, n=6),
        set_pieces(E(200, ("carrion_bull", 1), ("fungal_host", 3)), E(300, ("plague_beast", 1), ("grave_moth", 4))),
        trigger_waves(T(0.5, ("grave_moth", 5), ("fungal_host", 3)), T(0.25, ("fungal_host", 5), ("carrion_bull", 1)))),
        "marsh_ambush", "Spore cannons cough rot over the hollow. The moths follow the clouds down.",
        ["skyspotter_scout"], 112, ch("no_air_losses")),
    # 035 — a marching column: marauders + pestilent soldiers; corpse lobbers
    _stage(35, "The Gallows Road", "ruined_road", compose(
        dict(tracks=[R("blight_marauder", 4, 9, 2, 6), R("pestilent_soldier", 8, 10, 2, 6.5)], events=[], triggers=[], structures=[]),
        artillery_line(["corpse_lobber"], k=1.0, start=50, until=470),
        air_raid(["skeletal_vulture"], k=0.9, start=26),
        set_pieces(E(100, ("blight_marauder", 5), ("pestilent_soldier", 4)), E(210, ("stitchback_giant", 1))),
        trigger_waves(T(0.5, ("blight_marauder", 4), ("corpse_lobber", 1)))),
        "early_armor_duel", "The dead march the old trade road in step, under the gibbets of the living.",
        ["bombardier"], 115, ch("max_types", n=7)),
    # 036 — vultures and rotwings strafe; the first Act II flak spire
    _stage(36, "Carrion Toll", "ruined_road", compose(
        opener_horde(["shambler", "black_rot_infantry"], k=1.0),
        air_raid(["skeletal_vulture", "rotwing"], k=1.1, start=14, t=120, n=6, spire_x=2160),
        set_pieces(E(200, ("rotwing", 4), ("skeletal_vulture", 4)), E(290, ("bone_golem", 1), ("black_rot_infantry", 4))),
        trigger_waves(T(0.85, ("stitchback_giant", 1), ("black_rot_infantry", 4), ("skeletal_vulture", 4)), T(0.5, ("rotwing", 3), ("black_rot_infantry", 4)), T(0.25, ("rotwing", 4), ("blight_marauder", 4))),
        support_cluster([("cursed_barricade", 2230)])),
        "bomber_escort", "The toll here is paid in flesh. Vultures collect it; a flak spire keeps the sky theirs.",
        ["twin_rotor_interceptor"], 118, ch("kill_structures"), base_hp=6700),
    # 037 — corpse burrowers; the first risen copperback (a corrupted dwarven tank)
    _stage(37, "Blightvein Adit", "corrupted_mine", compose(
        opener_horde(["shambler", "pestilent_soldier"], k=1.0),
        dict(tracks=[R("corpse_burrower", 40, 38, 1, 26), R("rift_crow", 22, 17, 2, 11)], events=[], triggers=[], structures=[]),
        set_pieces(E(150, ("risen_copperback", 1), ("black_rot_infantry", 3)), E(260, ("corpse_burrower", 2), ("rift_crow", 4))),
        trigger_waves(T(0.5, ("risen_copperback", 1)))),
        "corruption_spread", "A copperback came back up the adit with its crew still aboard. They are not dwarves any more.",
        ["armor_piercer"], 120, ch("base_above", frac=0.7)),
    # 038 — plague cauldron + necrotic beacon: kill the support structures first
    _stage(38, "Mirewatch", "plague_marsh", compose(
        opener_horde(["pestilent_soldier", "fungal_host"], k=1.0, group=2, interval=7),
        support_cluster([("necrotic_beacon", 2050), ("plague_cauldron", 2250)]),
        shield_wall("black_rot_infantry", "rot_channeler", k=0.85, start=20, until=420),
        air_raid(["grave_moth"], k=0.9, start=20, t=160, n=5),
        trigger_waves(T(0.5, ("plague_sprayer", 2), ("fungal_host", 4)))),
        "spire_belt", "A beacon on the watch-mound feeds the dead. Its cauldron feeds the marsh.",
        ["steam_sapper"], 122, ch("kill_structures"), hazard=BOG),
    # 039 — oozing horrors and grave spiders; dense miasma
    _stage(39, "Hangman's Thicket", "dead_forest", compose(
        opener_horde(["shambler", "blight_marauder"], k=1.0),
        dict(tracks=[R("grave_spider", 28, 26, 1, 17), R("oozing_horror", 70, 55, 1, 38), R("blight_bat", 20, 17, 2, 11)], events=[], triggers=[], structures=[]),
        set_pieces(E(130, ("grave_spider", 3)), E(230, ("oozing_horror", 2), ("blight_marauder", 3)), E(320, ("stitchback_giant", 1), ("grave_spider", 2))),
        trigger_waves(T(0.85, ("corpse_mound", 1), ("grave_spider", 3)), T(0.5, ("grave_spider", 2), ("blight_bat", 5)), T(0.25, ("oozing_horror", 2), ("blight_marauder", 4))),
        support_cluster([("cursed_barricade", 2230)])),
        "plague_tide", "Ropes still hang from every branch. Some of them twitch.",
        ["field_barricade_crew"], 125, ch("max_losses", n=28), hazard=MIASMA_DENSE, base_hp=7600),
    # 040 — BOSS: Blightroot Behemoth
    _stage(40, "The Rotting Heart", "dead_forest", compose(
        boss_arena([("shambler", 15, 2), ("fungal_host", 34, 1), ("blight_bat", 30, 2)], k=1.0),
        trigger_waves(T(0.6, ("rot_hound", 5), ("grave_moth", 3)), T(0.3, ("fungal_host", 4), ("blight_bat", 4)))),
        "boss_blightroot", "At the forest's heart a tree has learned to walk. Its roots are full of the dead.",
        ["heavy_bombard", "mine_layer"], 240, ch("kill_boss_by", seconds=420), boss=dict(id="blightroot_behemoth", t=60),
        base_hp=6200, gold=520),
    # 041 — rot launchers and a bone ram pushing up the road
    _stage(41, "Ashen Mile", "ruined_road", compose(
        opener_horde(["blight_marauder", "black_rot_infantry"], k=1.0, group=2, interval=6.5),
        artillery_line(["rot_launcher"], guard="pestilent_soldier", k=1.0, start=45, until=480),
        dict(tracks=[R("bone_ram", 60, 60, 1, 42), R("skeletal_vulture", 22, 17, 2, 11)], events=[], triggers=[], structures=[]),
        set_pieces(E(190, ("bone_ram", 1), ("black_rot_infantry", 4))),
        trigger_waves(T(0.5, ("rot_launcher", 1), ("skeletal_vulture", 4)))),
        "early_armor_duel", "A ram of fused bones grinds up the ash-grey mile toward your guns.",
        ["spotter_balloon_crew"], 120, ch("base_above", frac=0.65)),
    # 042 — plague heralds and corpse priests buff and heal the line
    _stage(42, "Sickbed Abbey", "ruined_road", compose(
        opener_horde(["pestilent_soldier", "carcass_devourer"], k=1.0, group=2, interval=6.5),
        shield_wall("black_rot_infantry", "plague_herald", k=1.0, start=20, until=540),
        dict(tracks=[R("corpse_priest", 50, 40, 1, 28, until=540), R("rift_crow", 18, 16, 2, 10)], events=[], triggers=[], structures=[]),
        set_pieces(E(220, ("stitchback_giant", 1), ("plague_herald", 1))),
        trigger_waves(T(0.5, ("corpse_priest", 1), ("carcass_devourer", 4)))),
        "corruption_spread", "The abbey still tends its sick. Its priests stitch them back into the line.",
        ["rocket_battery"], 123, ch("time_under", seconds=630)),
    # 043 — fungal host swarms in heavy miasma: armour shines
    _stage(43, "Fungal Deeps", "corrupted_mine", compose(
        opener_horde(["fungal_host", "shambler"], k=1.05, group=2, interval=6),
        dict(tracks=[R("grave_moth", 16, 15, 2, 10), R("corpse_burrower", 60, 45, 1, 32)], events=[], triggers=[], structures=[]),
        set_pieces(E(120, ("fungal_host", 6)), E(240, ("plague_beast", 1), ("fungal_host", 4)), E(330, ("corpse_mound", 1), ("grave_moth", 4))),
        trigger_waves(T(0.85, ("corpse_mound", 1), ("fungal_host", 5)), T(0.5, ("fungal_host", 5), ("grave_moth", 4)), T(0.25, ("plague_beast", 1), ("corpse_burrower", 2))),
        support_cluster([("cursed_barricade", 2230)])),
        "corruption_spread", "The lowland seams are furred with spore. The miners grew into the walls.",
        ["coalwing_strafing_craft"], 125, ch("max_losses", n=26), hazard=MIASMA_DENSE, base_hp=7800),
    # 044 — bog everywhere; haunted flying machines over the mire
    _stage(44, "Drowned Wagons", "plague_marsh", compose(
        opener_horde(["shambler", "pestilent_soldier"], k=1.05),
        dict(tracks=[R("haunted_flying_machine", 30, 26, 1, 17), R("blight_bat", 14, 16, 2, 10)], events=[], triggers=[], structures=[]),
        shield_wall("black_rot_infantry", "plague_sprayer", k=0.9, start=24, until=520),
        set_pieces(E(160, ("haunted_flying_machine", 2), ("blight_bat", 4)), E(250, ("carrion_bull", 1)), E(330, ("haunted_flying_machine", 2), ("plague_beast", 1))),
        trigger_waves(T(0.5, ("haunted_flying_machine", 2), ("pestilent_soldier", 4)), T(0.25, ("black_rot_infantry", 5), ("blight_bat", 4)))),
        "marsh_ambush", "A supply column sank here. Its flying escort did not stay down.",
        ["shrapnel_howitzer"], 126, ch("no_air_losses"), hazard=BOG_WIDE, base_hp=7000),
    # 045 — cursed barricades and bone bolt throwers (anti-air) guard the forest
    _stage(45, "Thornwall", "dead_forest", compose(
        opener_horde(["blight_marauder", "rotting_berserker"], k=1.0, group=2, interval=7),
        support_cluster([("cursed_barricade", 1980), ("cursed_barricade", 2180)]),
        artillery_line(["bone_bolt_thrower"], guard="black_rot_infantry", k=1.1, start=30, until=500),
        air_raid(["rotwing"], k=0.9, start=24, t=170, n=4),
        set_pieces(E(260, ("carrion_bull", 1), ("rotting_berserker", 3)), E(340, ("rotwing", 4), ("black_rot_infantry", 4))),
        trigger_waves(T(0.85, ("carrion_bull", 1), ("rotting_berserker", 4)), T(0.5, ("rotting_berserker", 4), ("bone_bolt_thrower", 1)), T(0.25, ("stitchback_giant", 1), ("rotwing", 3)))),
        "spire_belt", "A wall of thorn and bone. Bolt throwers on the ramparts watch the sky.",
        ["ironrunner_light_tank"], 128, ch("kill_structures"), base_hp=7900),
    # 046 — two risen copperbacks with a carrion bull
    _stage(46, "Rust Cart Ravine", "corrupted_mine", compose(
        opener_horde(["pestilent_soldier", "black_rot_infantry"], k=1.0, group=2, interval=6.5),
        dict(tracks=[R("rift_crow", 18, 16, 2, 10), R("corpse_burrower", 50, 46, 1, 32)], events=[], triggers=[], structures=[]),
        set_pieces(E(110, ("risen_copperback", 1)), E(170, ("carrion_bull", 1), ("black_rot_infantry", 3)), E(240, ("risen_copperback", 1), ("rift_crow", 4))),
        set_pieces(E(330, ("risen_copperback", 1), ("carrion_bull", 1))),
        trigger_waves(T(0.85, ("risen_copperback", 1), ("carrion_bull", 1), ("black_rot_infantry", 3)), T(0.5, ("risen_copperback", 1), ("pestilent_soldier", 3)), T(0.25, ("black_rot_infantry", 5), ("rift_crow", 4))),
        support_cluster([("cursed_barricade", 2230)])),
        "early_armor_duel", "Rust carts still run the ravine rails, pushed by the dead. So do two copperbacks.",
        ["flamebelcher_medium_tank"], 130, ch("base_above", frac=0.6), base_hp=7800),
    # 047 — a chokepoint bridge; flesh chargers break the line
    _stage(47, "The Leper Bridge", "ruined_road", compose(
        opener_horde(["shambler", "blight_marauder"], k=1.1),
        dict(tracks=[R("flesh_charger", 50, 42, 1, 28), R("skeletal_vulture", 20, 16, 2, 10), R("plague_sprayer", 30, 22, 1, 14, until=520)], events=[], triggers=[], structures=[]),
        set_pieces(E(140, ("flesh_charger", 2)), E(230, ("flesh_charger", 2), ("blight_marauder", 4))),
        trigger_waves(T(0.5, ("flesh_charger", 1), ("skeletal_vulture", 4)), T(0.25, ("flesh_charger", 2), ("rotting_berserker", 3)))),
        "early_armor_duel", "One span, no rails, and the lepers' dead still crossing it at a run.",
        ["boiler_stomper"], 132, ch("max_types", n=7), base_hp=7000),
    # 048 — harpies and wraith swarms ride miasma winds
    _stage(48, "Pestwind Downs", "plague_marsh", compose(
        opener_horde(["pestilent_soldier", "fungal_host"], k=1.0, group=2, interval=6.5),
        air_raid(["plague_harpy", "wraith_swarm"], k=1.05, start=16, t=140, n=4, until=600),
        dict(tracks=[R("blight_bat", 12, 15, 2, 10)], events=[], triggers=[], structures=[]),
        set_pieces(E(240, ("plague_harpy", 3), ("wraith_swarm", 2)), E(320, ("plague_beast", 1), ("pestilent_soldier", 4))),
        trigger_waves(T(0.5, ("plague_harpy", 3), ("fungal_host", 4)), T(0.25, ("wraith_swarm", 2), ("fungal_host", 5)))),
        "bomber_escort", "On the downs the plague wind never stops. The harpies ride it in.",
        ["skyshield_aa_tank"], 134, ch("no_air_losses"), hazard=MIASMA, base_hp=7100),
    # 049 — ghoul matriarch (abomination) leads crawler packs
    _stage(49, "Ghoul Warren", "corrupted_mine", compose(
        dict(tracks=[R("grave_crawler", 3, 7, 3, 4.6), R("black_rot_infantry", 10, 12, 2, 8), R("rift_crow", 20, 16, 2, 10)], events=[], triggers=[], structures=[]),
        set_pieces(E(120, ("ghoul_matriarch", 1), ("grave_crawler", 6)), E(250, ("grave_spider", 3), ("grave_crawler", 6))),
        set_pieces(E(330, ("grave_crawler", 8), ("rift_crow", 4))),
        trigger_waves(T(0.5, ("ghoul_matriarch", 1), ("rift_crow", 4)), T(0.25, ("grave_spider", 3), ("grave_crawler", 6)))),
        "corruption_spread", "The warren's mother calls; her crawling brood answers from every crack.",
        ["steam_loader"], 136, ch("base_above", frac=0.6), base_hp=7100),
    # 050 — BOSS: Plague Regent
    _stage(50, "Court of Pestilence", "plague_marsh", compose(
        boss_arena([("blight_marauder", 13, 1), ("plague_sprayer", 42, 1), ("grave_moth", 30, 2)], k=1.0, until=620),
        trigger_waves(T(0.6, ("black_rot_infantry", 4), ("blight_bat", 4)), T(0.3, ("fungal_host", 4), ("grave_moth", 4)))),
        "boss_plague_regent", "The Regent holds court in a palace of censers. The marsh is his carpet.",
        ["piston_brawler", "copper_sentinel"], 270, ch("kill_boss_by", seconds=480),
        hazard=[BOG_COURT, dict(MIASMA_LIGHT)], boss=dict(id="plague_regent", t=60), base_hp=7000, gold=520),
    # 051 — rot channelers and carcass devourers
    _stage(51, "Burnt Orchard", "dead_forest", compose(
        opener_horde(["carcass_devourer", "blight_marauder"], k=1.0, group=2, interval=7),
        shield_wall("black_rot_infantry", "rot_channeler", k=1.05, start=16, until=540),
        air_raid(["grave_moth", "blight_bat"], k=0.95, start=18, t=180, n=5),
        set_pieces(E(130, ("carcass_devourer", 5)), E(250, ("stitchback_giant", 1))),
        trigger_waves(T(0.5, ("rot_channeler", 2), ("carcass_devourer", 4)))),
        "plague_tide", "The orchard burned a year ago. The devourers are still eating the harvest.",
        ["scout_blimp"], 130, ch("max_losses", n=30), hazard=MIASMA_LIGHT),
    # 052 — rift crows and banshee wings: fast air pressure
    _stage(52, "Toll of Crows", "ruined_road", compose(
        opener_horde(["blight_marauder", "pestilent_soldier"], k=1.0, group=2, interval=6.5),
        air_raid(["rift_crow", "banshee_wing"], k=1.15, start=12, t=110, n=7, until=620),
        set_pieces(E(200, ("banshee_wing", 2), ("rift_crow", 6)), E(260, ("bone_golem", 1))),
        trigger_waves(T(0.5, ("banshee_wing", 2), ("blight_marauder", 4)))),
        "bomber_escort", "The crows take the toll in eyes. The banshees take the rest.",
        ["veteran_rifleman"], 132, ch("no_air_losses")),
    # 053 — oozing horrors and burrowers from below
    _stage(53, "Seeping Gallery", "corrupted_mine", compose(
        opener_horde(["shambler", "fungal_host"], k=1.1),
        dict(tracks=[R("corpse_burrower", 30, 34, 1, 23), R("oozing_horror", 55, 50, 1, 34), R("grave_moth", 18, 16, 2, 10)], events=[], triggers=[], structures=[]),
        set_pieces(E(150, ("corpse_burrower", 3)), E(260, ("oozing_horror", 2), ("corpse_burrower", 2))),
        trigger_waves(T(0.5, ("oozing_horror", 1), ("corpse_burrower", 2)))),
        "corruption_spread", "The gallery floor seeps. Some of what seeps up has teeth.",
        ["mortar_spotter"], 134, ch("base_above", frac=0.65), hazard=MIASMA),
    # 054 — a line of necrotic beacons and spore cannons
    _stage(54, "Blight Lantern Road", "ruined_road", compose(
        opener_horde(["black_rot_infantry", "pestilent_soldier"], k=1.0, group=2, interval=7),
        support_cluster([("necrotic_beacon", 1950), ("necrotic_beacon", 2200), ("grave_flak_spire", 2300)]),
        artillery_line(["plague_spore_cannon"], guard="rotting_berserker", k=0.85, start=40, until=400),
        air_raid(["skeletal_vulture"], k=1.0, start=20, t=170, n=5),
        trigger_waves(T(0.5, ("rotting_berserker", 3), ("skeletal_vulture", 4)))),
        "spire_belt", "Lanterns of green fire line the road. Every one makes the dead stronger.",
        ["heavy_hammerer"], 136, ch("kill_structures")),
    # 055 — stitchback giant and corpse mound
    _stage(55, "Stitchyard", "dead_forest", compose(
        opener_horde(["shambler", "carcass_devourer"], k=1.1),
        air_raid(["rotwing", "gravewing_stalker"], k=0.95, start=20, t=150, n=3),
        dict(tracks=[R("plague_sprayer", 30, 24, 1, 15, until=520)], events=[], triggers=[], structures=[]),
        set_pieces(E(120, ("stitchback_giant", 1), ("shambler", 5)), E(230, ("corpse_mound", 1), ("carcass_devourer", 3))),
        trigger_waves(T(0.5, ("stitchback_giant", 1), ("rotwing", 3)))),
        "monster_breakthrough", "Here the dead sew new dead from old. Two of their works are walking.",
        ["multi_barrel_flak"], 138, ch("max_losses", n=30)),
    # 056 — bog + funeral bell keepers stunning the line
    _stage(56, "The Sunken Chapel", "plague_marsh", compose(
        opener_horde(["pestilent_soldier", "shambler"], k=1.05),
        shield_wall("black_rot_infantry", "funeral_bell_keeper", k=0.85, start=24, until=420),
        air_raid(["grave_moth", "plague_harpy"], k=1.0, start=18, t=170, n=4, until=600),
        set_pieces(E(250, ("plague_beast", 1), ("funeral_bell_keeper", 1))),
        trigger_waves(T(0.5, ("funeral_bell_keeper", 1), ("pestilent_soldier", 4)))),
        "marsh_ambush", "The chapel sank to its bell-tower. Its bell still rings for every dwarf in the water.",
        ["skyguard_marksman"], 140, ch("time_under", seconds=660), hazard=BOG),
    # 057 — gravewing stalkers: a preview of Act III's sky war
    _stage(57, "Wyrmroost Fringe", "dead_forest", compose(
        opener_horde(["blight_marauder", "rotting_berserker"], k=1.0, group=2, interval=7),
        air_raid(["gravewing_stalker", "rotwing"], k=1.2, start=12, t=120, n=6),
        set_pieces(E(220, ("gravewing_stalker", 6), ("banshee_wing", 1)), E(280, ("bone_golem", 1))),
        trigger_waves(T(0.5, ("gravewing_stalker", 4), ("rotting_berserker", 3)))),
        "bomber_escort", "Past the fringe the sky belongs to the gravewings. They come down to feed.",
        ["bombard_gyro"], 142, ch("no_air_losses")),
    # 058 — haunted flying machines + plague beast + risen copperback
    _stage(58, "Cankerworks", "corrupted_mine", compose(
        opener_horde(["pestilent_soldier", "black_rot_infantry"], k=1.05, group=2, interval=6.5),
        dict(tracks=[R("haunted_flying_machine", 24, 24, 1, 16), R("rift_crow", 16, 16, 2, 10)], events=[], triggers=[], structures=[]),
        set_pieces(E(110, ("plague_beast", 1)), E(180, ("risen_copperback", 1), ("haunted_flying_machine", 2)), E(270, ("risen_copperback", 1), ("plague_beast", 1))),
        trigger_waves(T(0.5, ("risen_copperback", 1), ("haunted_flying_machine", 2)))),
        "corruption_spread", "The old cankerworks build again: dead hands, dwarven engines, both turned against you.",
        ["thunderback_heavy_tank"], 144, ch("base_above", frac=0.6), hazard=MIASMA),
    # 059 — the act's combined-arms exam
    _stage(59, "Last Ford", "plague_marsh", compose(
        finale(["pestilent_soldier", "blight_marauder", "rotting_berserker"], ["plague_sprayer", "rot_channeler"],
               ["skeletal_vulture", "plague_harpy"], k=1.05, until=540),
        support_cluster([("necrotic_beacon", 2200)]),
        set_pieces(E(130, ("risen_copperback", 1), ("black_rot_infantry", 3)), E(210, ("stitchback_giant", 1)), E(290, ("haunted_flying_machine", 3), ("carrion_bull", 1))),
        trigger_waves(T(0.6, ("flesh_charger", 2), ("rotwing", 3)), T(0.3, ("plague_beast", 1), ("wraith_swarm", 2)))),
        "combined_assault", "The last ford before the nest. Everything the marsh has left is waiting in the water.",
        ["siege_howitzer"], 150, ch("max_losses", n=34), hazard=BOG),
    # 060 — BOSS: Gravewing Matriarch (air boss; Act II finale)
    _stage(60, "Nest of the Matriarch", "dead_forest", compose(
        boss_arena([("blight_marauder", 12, 2), ("black_rot_infantry", 22, 2), ("rotting_berserker", 34, 1)], k=1.0, until=620),
        dict(tracks=[R("gravewing_stalker", 30, 34, 1, 22), R("plague_sprayer", 28, 32, 1, 21, until=560)], events=[], triggers=[], structures=[]),
        trigger_waves(T(0.6, ("rotting_berserker", 3), ("skeletal_vulture", 4)), T(0.3, ("carrion_bull", 1), ("gravewing_stalker", 3)))),
        "boss_gravewing_matriarch", "Atop the last dead tree sits a nest the size of a keep. Its mother is awake.",
        ["heavy_gyro_bomber", "ironwing_gunship"], 290, ch("no_air_losses"), boss=dict(id="gravewing_matriarch", t=45),
        base_hp=7400, gold=430),
]

assert len(ACT2) == 30
