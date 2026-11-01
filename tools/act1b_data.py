"""M003: Act I, stages 16-30 ("Siege of the Mountain Holds", second half).

Introduces the new T0-T2 undead from the full roster, the Bellringer (stage 20) and the
Ossuary Matron (stage 30). Same schema as AUTHORED in gen_data.py.
"""

R = lambda e, start, interval, group=1, mn=None, ramp=0.97, until=-1: dict(enemy=e, start=start, interval=interval, group=group, interval_min=mn if mn else interval * 0.6, ramp=ramp, until=until)
E = lambda t, *spawns: dict(t=t, spawn=[list(s) for s in spawns])
T = lambda hp, *spawns: dict(hp_below=hp, spawn=[list(s) for s in spawns])

ACT1B = [
    # 16
    dict(name="Cragwatch", env="ridge", theme="new_dead", base_hp=4300, start_gold=250, max_alive=42,
         tracks=[R("shambler", 2, 6, 3, 4), R("bone_pikeman", 10, 13, 2, 8), R("grave_slinger", 18, 16, 2, 10, until=600), R("carrion_wasp", 25, 16, 3, 10), R("rot_hound", 40, 22, 2, 14)],
         events=[E(100, ("rot_hound", 4), ("bone_pikeman", 3)), E(170, ("bone_golem", 1))],
         triggers=[T(0.5, ("bone_pikeman", 3), ("grave_slinger", 3), ("carrion_wasp", 4))], structures=[dict(enemy="cursed_barricade", x=2120)],
         rewards=dict(sparks=95, unlock=["sapper"]), tag="Pikes and slings hold the watchtower crag. Rot hounds run the flanks."),
    # 17
    dict(name="Old Bellows Road", env="mountain_pass", theme="climbers", base_hp=4400, start_gold=250, max_alive=44,
         tracks=[R("wretched_climber", 6, 11, 2, 7), R("barrow_spearman", 3, 8, 2, 5.5), R("grave_dart_thrower", 15, 13, 2, 8), R("blight_bat", 20, 15, 3, 10), R("plague_shrieker", 45, 26, 1, 17)],
         events=[E(90, ("wretched_climber", 5)), E(160, ("carrion_bull", 1), ("barrow_spearman", 4))],
         triggers=[T(0.5, ("wretched_climber", 4), ("blight_bat", 5))], structures=[],
         rewards=dict(sparks=100, unlock=["longrifle_scout"]), tag="Climbers scale the old bellows road faster than a dwarf can reload."),
    # 18
    dict(name="Tallowmere", env="mine_flooded", theme="fungal_marsh", base_hp=4500, start_gold=255, max_alive=44,
         tracks=[R("fungal_host", 8, 15, 2, 10), R("shambler", 2, 6, 3, 4), R("grave_moth", 18, 16, 3, 10), R("rot_spitter", 22, 16, 1, 10), R("necromancer", 50, 44, 1, 32)],
         events=[E(110, ("fungal_host", 4), ("grave_moth", 4)), E(180, ("plague_beast", 1))],
         triggers=[T(0.5, ("necromancer", 1), ("fungal_host", 3))], structures=[],
         rewards=dict(sparks=100, unlock=["hammer_guard"]), tag="Fungal hosts wade the tallow lake; spore moths drift over the water."),
    # 19
    dict(name="Blackpick Galleries", env="mine_deep", theme="tunnelers_ii", base_hp=4600, start_gold=260, max_alive=46, hazard=dict(kind="rockfall", interval=16, damage=40, radius=55),
         tracks=[R("zombie_miner", 4, 9, 2, 6), R("ossuary_axeman", 12, 14, 2, 9), R("grave_crawler", 20, 14, 3, 9), R("tomb_stalker", 35, 22, 1, 14), R("rift_crow", 25, 16, 3, 10)],
         events=[E(100, ("tomb_stalker", 3), ("zombie_miner", 4)), E(175, ("bone_golem", 1), ("ossuary_axeman", 3))],
         triggers=[T(0.5, ("ossuary_axeman", 3), ("tomb_stalker", 2))], structures=[dict(enemy="bone_spire", x=2220)],
         rewards=dict(sparks=105, unlock=["portable_mortar"]), tag="Axemen and tomb stalkers haunt the blackpick seams. The roof still falls."),
    # 20 — boss: The Bellringer
    dict(name="Belfry of Frostfang", env="high_ridge", theme="boss_bellringer", base_hp=4800, start_gold=280, max_alive=46, boss=dict(id="bellringer", t=40),
         hazard=dict(kind="gale", interval=26, duration=6, strength=40),
         tracks=[R("shambler", 3, 8, 2, 5.5), R("barrow_spearman", 14, 16, 2, 10), R("blight_bat", 22, 20, 2, 13)],
         events=[], triggers=[T(0.4, ("bone_pikeman", 4), ("blight_bat", 5))], structures=[],
         rewards=dict(sparks=200, unlock=["flame_trooper"]), tag="A dead bell tolls on Frostfang. Every peal raises the fallen."),
    # 21
    dict(name="The Coal Stair", env="foundry_outpost", theme="marauders", base_hp=4900, start_gold=265, max_alive=46,
         tracks=[R("blight_marauder", 8, 14, 2, 9), R("pestilent_soldier", 3, 9, 2, 6), R("plague_sprayer", 20, 17, 1, 11), R("skeletal_vulture", 25, 17, 2, 11), R("grave_knight", 50, 34, 1, 24)],
         events=[E(110, ("blight_marauder", 4), ("plague_sprayer", 2)), E(190, ("stitchback_giant", 1))],
         triggers=[T(0.5, ("grave_knight", 1), ("pestilent_soldier", 4))], structures=[dict(enemy="cursed_barricade", x=2150)],
         rewards=dict(sparks=110, unlock=["rotary_interceptor"]), tag="Plague soldiers march up the coal stair behind spraying censers."),
    # 22
    dict(name="Hammerfall Vale", env="ridge", theme="berserkers", base_hp=5000, start_gold=270, max_alive=48,
         tracks=[R("rotting_berserker", 10, 15, 2, 10), R("bone_vanguard", 6, 12, 2, 8), R("bone_lancer", 18, 16, 2, 10), R("rotwing", 25, 22, 2, 14), R("shambler", 2, 6, 3, 4)],
         events=[E(100, ("rotting_berserker", 4)), E(180, ("carrion_bull", 1), ("bone_vanguard", 4))],
         triggers=[T(0.5, ("rotting_berserker", 3), ("rotwing", 3))], structures=[dict(enemy="bone_spire", x=2240)],
         rewards=dict(sparks=115, unlock=["coalrunner_scout_tank"]), tag="Berserkers charge down the vale where the old hammers fell."),
    # 23
    dict(name="Rustgate", env="mountain_gate", theme="legion", base_hp=5100, start_gold=275, max_alive=48,
         tracks=[R("rusted_legionary", 6, 11, 2, 7.5), R("black_rot_infantry", 4, 10, 2, 6.5), R("crypt_hexer", 22, 22, 1, 15), R("spectral_wraith", 20, 18, 2, 12), R("bone_catapult", 50, 60, 1, 42, until=480)],
         events=[E(110, ("rusted_legionary", 4), ("crypt_hexer", 1)), E(200, ("ossuary_juggernaut", 1))],
         triggers=[T(0.5, ("black_rot_infantry", 4), ("spectral_wraith", 3))], structures=[],
         rewards=dict(sparks=120, unlock=["steamgunner"]), tag="A rusted legion and its hexers besiege the iron gate. Catapults lob bone over the wall."),
    # 24
    dict(name="Kettle Rock", env="high_ridge", theme="air_raid_ii", base_hp=3400, start_gold=310, max_alive=46, hazard=dict(kind="gale", interval=24, duration=6, strength=45),
         tracks=[R("plague_harpy", 14, 20, 1, 14, until=600), R("carrion_wasp", 6, 12, 2, 8), R("wraith_swarm", 35, 36, 1, 26, until=500), R("plague_shrieker", 20, 22, 1, 15), R("pestilent_soldier", 3, 9, 2, 6)],
         events=[E(80, ("plague_harpy", 4), ("carrion_wasp", 5)), E(160, ("plague_harpy", 4), ("wraith_swarm", 2))],
         triggers=[T(0.5, ("plague_shrieker", 3), ("plague_harpy", 3))], structures=[dict(enemy="grave_flak_spire", x=2180)],
         rewards=dict(sparks=125, unlock=["skyhook_rocket_rack"]), tag="Harpies and wraith swarms boil out of the kettle. A flak spire guards them."),
    # 25
    dict(name="Grimvent", env="mine_entrance", theme="bombers", base_hp=5200, start_gold=285, max_alive=50,
         tracks=[R("risen_bomb_carrier", 15, 16, 1, 10), R("carcass_devourer", 8, 15, 2, 10), R("grave_slinger", 10, 12, 2, 8), R("blight_bat", 20, 15, 3, 10), R("corpse_lobber", 55, 60, 1, 42, until=480)],
         events=[E(100, ("risen_bomb_carrier", 4), ("carcass_devourer", 3)), E(190, ("plague_beast", 1), ("risen_bomb_carrier", 3))],
         triggers=[T(0.5, ("risen_bomb_carrier", 3), ("blight_bat", 5))], structures=[dict(enemy="cursed_barricade", x=2140)],
         rewards=dict(sparks=130, unlock=["steam_mortar"]), tag="Bomb carriers stagger out of the vent with lit fuses. Keep them off the line."),
    # 26
    dict(name="Emberdeep", env="foundry_outpost", theme="thralls", base_hp=5300, start_gold=290, max_alive=50,
         tracks=[R("cursed_dwarf_thrall", 6, 12, 2, 8), R("crypt_halberdier", 10, 14, 2, 9), R("cinder_wraith", 20, 20, 1, 13), R("gravewing_stalker", 30, 24, 1, 15), R("rusted_legionary", 3, 10, 2, 7)],
         events=[E(110, ("cursed_dwarf_thrall", 5)), E(200, ("haunted_flying_machine", 2), ("crypt_halberdier", 3))],
         triggers=[T(0.5, ("cinder_wraith", 2), ("gravewing_stalker", 2))], structures=[dict(enemy="bone_spire", x=2200)],
         rewards=dict(sparks=135, unlock=["twin_flak_mount"]), tag="Fallen dwarves of Emberdeep march for the dead — and a haunted flying machine with them."),
    # 27
    dict(name="Stonehelm Keep", env="mountain_gate", theme="siege_line", base_hp=5100, start_gold=310, max_alive=52,
         tracks=[R("bone_ram", 40, 50, 1, 34), R("hollow_guard", 10, 19, 1, 13), R("grave_mortar", 60, 70, 1, 50, until=480), R("bone_archer", 10, 12, 2, 8), R("skeletal_vulture", 20, 16, 2, 10), R("shambler", 2, 6, 3, 4)],
         events=[E(120, ("bone_ram", 1), ("hollow_guard", 3)), E(210, ("bone_golem", 1), ("hollow_guard", 2))],
         triggers=[T(0.5, ("grave_mortar", 1), ("hollow_guard", 2), ("skeletal_vulture", 4))], structures=[dict(enemy="cursed_barricade", x=2100), dict(enemy="bone_spire", x=2280)],
         rewards=dict(sparks=140, unlock=["copperback_light_tank"]), tag="Rams and mortars batter the keep. The dead brought a walking crypt."),
    # 28
    dict(name="The Long Shaft", env="mine_deep", theme="burrowers", base_hp=5600, start_gold=300, max_alive=52, hazard=dict(kind="rockfall", interval=18, damage=40, radius=55),
         tracks=[R("corpse_burrower", 40, 40, 1, 28), R("grave_spider", 25, 28, 1, 18), R("zombie_miner", 3, 8, 2, 5.5), R("tomb_stalker", 22, 22, 1, 14), R("rift_crow", 20, 17, 2, 11), R("corpse_priest", 50, 46, 1, 32)],
         events=[E(110, ("grave_spider", 2), ("corpse_burrower", 1)), E(200, ("tomb_centipede", 1), ("zombie_miner", 5))],
         triggers=[T(0.5, ("corpse_burrower", 1), ("tomb_stalker", 3))], structures=[],
         rewards=dict(sparks=145, unlock=["drillwalker"]), tag="Burrowers and grave spiders come up the long shaft from the dark below."),
    # 29
    dict(name="Wardens' Ridge", env="ridge", theme="combined_pressure_ii", base_hp=5300, start_gold=320, max_alive=54,
         tracks=[R("grave_warden", 10, 16, 1, 11), R("plague_mauler", 40, 34, 1, 24), R("spirit_binder", 45, 46, 1, 32), R("tomb_gargoyle", 30, 32, 1, 21), R("bone_lancer", 14, 22, 1, 14, until=520), R("pestilent_soldier", 2, 8, 2, 5.5), R("carrion_wasp", 15, 16, 2, 10)],
         events=[E(120, ("plague_mauler", 2), ("grave_warden", 2)), E(220, ("carrion_bull", 1), ("tomb_gargoyle", 2))],
         triggers=[T(0.6, ("spirit_binder", 1), ("grave_warden", 2)), T(0.3, ("plague_mauler", 2), ("tomb_gargoyle", 2))], structures=[dict(enemy="grave_flak_spire", x=2160), dict(enemy="bone_spire", x=2300)],
         rewards=dict(sparks=150, unlock=["repair_wagon"]), tag="Wardens, maulers and gargoyles hold the last ridge before the ossuary."),
    # 30 — boss: Ossuary Matron (Act I finale)
    dict(name="Ossuary Hall", env="ruined_outpost", theme="boss_ossuary_matron", base_hp=6200, start_gold=320, max_alive=54, boss=dict(id="ossuary_matron", t=18),
         tracks=[R("ossuary_skeleton", 3, 7, 3, 4.6), R("bone_vanguard", 12, 15, 2, 10), R("ossuary_flier", 25, 26, 1, 17), R("bone_archer", 15, 14, 2, 9), R("crypt_hexer", 40, 34, 1, 24)],
         events=[], triggers=[T(0.6, ("ossuary_axeman", 4), ("ossuary_flier", 2)), T(0.3, ("bone_golem", 1), ("skeletal_vulture", 4))], structures=[dict(enemy="bone_spire", x=2260)],
         rewards=dict(sparks=260, unlock=["ironclad_medium_tank"], open_tier=3), tag="The Matron knits armies from the hall's bones. Break her, then break the citadel."),
]
