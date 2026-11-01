"""M002 — Operation Iron Giants: the 28-frame Dwarven Mecha Branch (Branch E).

Spec values (M002 §6–§9) are written exactly as given, on the spec's reference scale
(Rifleman ≈ 100 HP), then normalised ONCE here onto the M001 scale so every value has a
single authoritative source:

    HP ×0.75   damage ×0.75   Gold ×0.45   speed ×0.72   deploy cooldown ×0.75
    range ×1.0 (M001 world units already match)   ARM% kept (capped at 50%)

Steam costs/cooldowns of abilities are kept as specified (Steam capacity is 100 in both).
Stable unit IDs are the M001 IDs (e.g. `miner_rig`); the spec's `mech_*` names are kept as
`mech_id` aliases so saves made with M001 stay valid.
"""

HP_K, DMG_K, GOLD_K, SPD_K, CD_K = 0.75, 0.75, 0.45, 0.72, 0.75

# visual height multipliers vs a 52 px Rifleman (spec §3), and collision radius per class
CLASS = {
    "light":    dict(rel=2.05, radius=22, death=1.3, tier_min=1),
    "medium":   dict(rel=2.85, radius=29, death=1.7, tier_min=3),
    "heavy":    dict(rel=4.0,  radius=37, death=2.1, tier_min=4),
    "colossal": dict(rel=5.6,  radius=52, death=2.9, tier_min=5),
}
RIFLEMAN_PX = 52.0
DESIGN_H = 110.0   # every mech rig is drawn ~110 design units tall; art_scale maps it to pixels

W = lambda **k: k

# name, class, tier, HP, ARM, SPD, RNG, Gold, CD, targets, frame art key
SPEC = [
    ("miner_rig", "Miner Rig", "light", 1, 620, .10, 48, 28, 340, 10, "G"),
    ("boiler_stomper", "Boiler Stomper", "light", 2, 800, .15, 41, 38, 500, 14, "G"),
    ("drillwalker", "Drillwalker", "light", 2, 900, .20, 43, 30, 610, 16, "G"),
    ("steam_loader", "Steam Loader", "light", 2, 1100, .25, 34, 32, 650, 18, "G"),
    ("piston_brawler", "Piston Brawler", "light", 2, 780, .15, 55, 30, 620, 17, "G"),
    ("copper_sentinel", "Copper Sentinel", "light", 2, 1040, .25, 32, 175, 760, 20, "G"),
    ("ironclad_walker", "Ironclad Walker", "medium", 3, 1480, .30, 36, 205, 1000, 27, "G"),
    ("skyguard_walker", "Skyguard Walker", "medium", 3, 1250, .20, 40, 270, 1050, 29, "A"),
    ("thundercoil_frame", "Thundercoil Frame", "medium", 3, 1380, .25, 38, 145, 1150, 30, "G/A"),
    ("cannon_strider", "Cannon Strider", "medium", 3, 1350, .25, 30, 320, 1200, 33, "G"),
    ("shieldframe", "Shieldframe", "medium", 3, 2100, .40, 27, 34, 1120, 36, "G"),
    ("claw_harvester", "Claw Harvester", "medium", 3, 1230, .20, 46, 42, 1050, 26, "G"),
    ("mortar_walker", "Mortar Walker", "medium", 3, 1150, .20, 28, 370, 1180, 35, "G"),
    ("furnace_stalker", "Furnace Stalker", "medium", 3, 1500, .25, 37, 115, 1320, 34, "G"),
    ("anvilbreaker", "Anvilbreaker", "heavy", 4, 2700, .38, 28, 42, 2200, 65, "G"),
    ("siegebellow", "Siegebellow", "heavy", 4, 2450, .30, 23, 440, 2400, 70, "G"),
    ("furnace_guardian", "Furnace Guardian", "heavy", 4, 3000, .40, 25, 125, 2300, 68, "G"),
    ("siege_hammer_walker", "Siege Hammer Walker", "heavy", 4, 2650, .35, 30, 38, 2250, 64, "G"),
    ("flak_colossus", "Flak Colossus", "heavy", 4, 2750, .35, 25, 345, 2450, 72, "A"),
    ("thunderstep_bruiser", "Thunderstep Bruiser", "heavy", 4, 2900, .38, 37, 40, 2420, 62, "G"),
    ("shredder_walker", "Shredder Walker", "heavy", 4, 2350, .30, 35, 205, 2350, 61, "G"),
    ("riftshield_walker", "Riftshield Walker", "heavy", 4, 3300, .44, 22, 36, 2500, 78, "G"),
    ("deepforge_titan", "Deepforge Titan", "colossal", 5, 6800, .45, 18, 370, 5000, 145, "G/A"),
    ("mountain_colossus", "Mountain Colossus", "colossal", 5, 8500, .48, 14, 46, 5500, 160, "G"),
    ("kings_anvil", "King's Anvil", "colossal", 5, 7400, .48, 18, 44, 5100, 155, "G"),
    ("colossal_skybreaker", "Colossal Skybreaker", "colossal", 5, 6400, .42, 17, 450, 5300, 150, "A"),
    ("hammerfall_goliath", "Hammerfall Goliath", "colossal", 5, 7800, .46, 19, 48, 5550, 164, "G"),
    ("embercore_titan", "Embercore Titan", "colossal", 5, 7000, .42, 20, 155, 5200, 158, "G/A"),
]

# design-space weapon anchor points (x forward, y up negative), scaled by art_scale
A = {"front": (40, -62), "back": (34, -60), "shoulder": (14, -102), "shoulder_b": (-6, -104),
     "chest": (24, -78), "low": (36, -40), "foot": (30, 0), "top": (0, -112), "head": (16, -96)}


def d(x):
    return round(x * DMG_K, 1)


# spec weapon definitions: (weapon fields in spec scale; damage scaled by d())
def weapons_for(uid, rng):
    melee = lambda wid, dmg, rel, **k: W(id=wid, range=k.pop("range", rng), damage=d(dmg), reload=rel, targets="ground", priority=k.pop("priority", "nearest"),
                                          proj="melee", dtype=k.pop("dtype", "melee"), anchor=k.pop("anchor", "front"), **k)
    if uid == "miner_rig":
        return [melee("mining_claws", 44, 0.9, family="claw", bonus={"bone": 1.35, "structure": 1.4})]
    if uid == "boiler_stomper":
        return [melee("stomp", 100, 2.5, dtype="blast", splash=62, windup=0.5, family="stomp", priority="swarm", anchor="foot"),
                W(id="pressure_vents", range=90, damage=d(9), reload=0.5, targets="ground_lowair", priority="nearest", proj="steam", dtype="fire", splash=3, anchor="chest", family="steam")]
    if uid == "drillwalker":
        return [melee("rotary_drill", 42, 0.5, dtype="drill", priority="armored", family="drill", spinup=0.7, pen=0.30,
                      bonus={"heavy": 1.45, "hulk": 1.45, "structure": 1.6, "bone_shield": 1.3})]
    if uid == "steam_loader":
        return [melee("loader_grabbers", 70, 1.4, family="grabber", priority="nearest")]
    if uid == "piston_brawler":
        return [melee("piston_fists", 85, 1.2, family="fist")]
    if uid == "copper_sentinel":
        return [W(id="repeater_cannon", range=rng, damage=d(65), reload=1.8, targets="ground", priority="threat", proj="shell", dtype="blast", splash=14, anchor="front", family="repeater", burst=2, burst_gap=0.18, eject=True)]
    if uid == "ironclad_walker":
        return [W(id="arm_cannon", range=rng, damage=d(120), reload=2.4, targets="ground", priority="armored", proj="shell", dtype="blast", splash=24, ap=True, anchor="front", family="cannon", eject=True),
                melee("defensive_fist", 50, 1.6, family="fist", anchor="back", range=46)]
    if uid == "skyguard_walker":
        return [W(id="sky_gun_left", range=rng, damage=d(18), reload=1.2, targets="air", priority="air", proj="bullet", dtype="pierce", burst=3, burst_gap=0.07, spread=10, anchor="shoulder", family="aa_mg", arc=[-178, 40], eject=True),
                W(id="sky_gun_right", range=rng, damage=d(18), reload=1.2, targets="air", priority="air", proj="bullet", dtype="pierce", burst=2, burst_gap=0.07, spread=10, anchor="shoulder_b", family="aa_mg", arc=[-178, 40], eject=True)]
    if uid == "thundercoil_frame":
        return [W(id="arc_projector", range=rng, damage=d(78), reload=1.5, targets="both", priority="swarm", proj="zap", dtype="shock", chain=2, chain_range=70, anchor="front", family="coil")]
    if uid == "cannon_strider":
        return [W(id="shoulder_cannon", range=rng, damage=d(230), reload=4.5, targets="ground", priority="armored", proj="shell", dtype="blast", splash=22, ap=True, pen=0.15, windup=0.45, anchor="shoulder", family="cannon", eject=True)]
    if uid == "shieldframe":
        return [melee("hydraulic_fist", 56, 1.8, family="fist", anchor="back")]
    if uid == "claw_harvester":
        return [melee("dual_claws", 98, 1.2, family="claw", splash=34, priority="swarm")]
    if uid == "mortar_walker":
        return [W(id="mortar_tube", range=rng, min_range=90, damage=d(155), reload=4.0, targets="ground", priority="swarm", proj="arc", dtype="blast", splash=50, anchor="top", family="mortar", windup=0.3)]
    if uid == "furnace_stalker":
        return [W(id="furnace_flamer", range=rng, damage=d(26), reload=0.25, targets="ground", priority="nearest", proj="flame", dtype="fire", splash=4, anchor="front", family="flamer")]
    if uid == "anvilbreaker":
        return [melee("anvil_hammer", 340, 3.2, dtype="blast", splash=58, windup=0.75, family="hammer2", priority="swarm")]
    if uid == "siegebellow":
        return [W(id="siege_cannon", range=rng, damage=d(570), reload=7.0, targets="ground", priority="structure", proj="shell", dtype="blast", splash=44, ap=True, pen=0.2, windup=0.6, anchor="shoulder", family="siege", bonus={"structure": 1.3, "hulk": 1.15}, eject=True)]
    if uid == "furnace_guardian":
        return [W(id="flamer_left", range=rng, damage=d(40), reload=0.3, targets="ground", priority="nearest", proj="flame", dtype="fire", splash=3, anchor="front", family="flamer"),
                W(id="flamer_right", range=rng, damage=d(40), reload=0.3, targets="ground", priority="swarm", proj="flame", dtype="fire", splash=3, anchor="back", family="flamer")]
    if uid == "siege_hammer_walker":
        return [melee("siege_hammer", 390, 4.2, windup=0.85, family="hammer", priority="armored", pen=0.25, bonus={"structure": 1.8, "heavy": 1.3, "hulk": 1.2})]
    if uid == "flak_colossus":
        return [W(id="quad_flak_left", range=rng, damage=d(90), reload=3.0, targets="air", priority="air", proj="flak", dtype="flak", splash=36, burst=2, burst_gap=0.2, anchor="shoulder", family="aa_quad", arc=[-178, 40]),
                W(id="quad_flak_right", range=rng, damage=d(90), reload=3.0, targets="air", priority="air", proj="flak", dtype="flak", splash=36, burst=2, burst_gap=0.2, anchor="shoulder_b", family="aa_quad", arc=[-178, 40])]
    if uid == "thunderstep_bruiser":
        return [melee("crushing_gauntlets", 270, 2.6, windup=0.35, family="fist2", splash=30)]
    if uid == "shredder_walker":
        return [W(id="rotary_gun_left", range=rng, damage=d(28), reload=0.95, targets="ground", priority="swarm", proj="bullet", dtype="pierce", burst=3, burst_gap=0.06, spread=14, anchor="front", family="rotary", eject=True),
                W(id="rotary_gun_right", range=rng, damage=d(28), reload=0.95, targets="ground", priority="nearest", proj="bullet", dtype="pierce", burst=3, burst_gap=0.06, spread=14, anchor="back", family="rotary", eject=True)]
    if uid == "riftshield_walker":
        return [melee("crushing_arm", 75, 1.9, family="fist", anchor="back")]
    if uid == "deepforge_titan":
        return [W(id="titan_cannon", range=rng, damage=d(650), reload=6.5, targets="ground", priority="armored", proj="shell", dtype="blast", splash=50, ap=True, pen=0.2, windup=0.6, anchor="front", family="siege", eject=True),
                W(id="aa_mount_left", range=290, damage=d(40), reload=2.0, targets="air", priority="air", proj="bullet", dtype="pierce", burst=4, burst_gap=0.08, spread=8, anchor="shoulder", family="aa_mg", arc=[-178, 40]),
                W(id="aa_mount_right", range=290, damage=d(40), reload=2.0, targets="air", priority="air", proj="bullet", dtype="pierce", burst=4, burst_gap=0.08, spread=8, anchor="shoulder_b", family="aa_mg", arc=[-178, 40]),
                melee("emergency_crushing_arm", 200, 3.0, family="fist", anchor="back", range=60)]
    if uid == "mountain_colossus":
        return [melee("colossal_fists", 850, 5.5, dtype="blast", splash=72, windup=0.9, family="fist2", priority="swarm")]
    if uid == "kings_anvil":
        return [melee("royal_war_axe", 720, 4.8, windup=0.8, splash=62, family="axe2", priority="armored", pen=0.15, bonus={"heavy": 1.3, "hulk": 1.3})]
    if uid == "colossal_skybreaker":
        return [W(id=f"skybreaker_gun_{i + 1}", range=rng, damage=d(260), reload=5.5, targets="air", priority=["air", "threat", "nearest"][i], proj="flak", dtype="flak", splash=40, windup=0.2,
                  anchor=["shoulder", "top", "shoulder_b"][i], family="aa_heavy", arc=[-178, 40]) for i in range(3)]
    if uid == "hammerfall_goliath":
        return [melee("impact_hammer", 900, 5.8, windup=1.0, dtype="blast", splash=50, family="hammer2", priority="structure", bonus={"structure": 1.6})]
    if uid == "embercore_titan":
        return [W(id="furnace_projector", range=rng, damage=d(66), reload=0.28, targets="ground", priority="swarm", proj="flame", dtype="fire", splash=5, anchor="front", family="flamer_big"),
                W(id="aa_repeater_left", range=255, damage=d(28), reload=1.3, targets="air", priority="air", proj="bullet", dtype="pierce", burst=3, burst_gap=0.07, spread=8, anchor="shoulder", family="aa_mg", arc=[-178, 40]),
                W(id="aa_repeater_right", range=255, damage=d(28), reload=1.3, targets="air", priority="air", proj="bullet", dtype="pierce", burst=3, burst_gap=0.07, spread=8, anchor="shoulder_b", family="aa_mg", arc=[-178, 40])]
    raise KeyError(uid)


AB = lambda **k: k
ABILITIES = {
    "miner_rig": AB(id="piston_lunge", name="Piston Lunge", kind="strike", steam=12, cooldown=16, windup=0.35, mult=1.8, hits=1, knock=38,
                    desc="Short forward impact: bonus damage and displaces one light enemy."),
    "boiler_stomper": AB(id="pressure_stomp", name="Pressure Stomp", kind="aoe", steam=18, cooldown=22, windup=0.55, radius=105, damage=d(110), dtype="blast", knock=26, min_targets=3,
                         desc="Vents stored steam through a short-range shockwave."),
    "drillwalker": AB(id="deep_bore", name="Deep Bore", kind="buff", steam=22, cooldown=25, windup=0.3, dur=6, mods={"pen": 0.3, "dmg": 1.3}, cond="armored_target",
                      desc="Raises armor penetration against its current ground target."),
    "steam_loader": AB(id="industrial_shove", name="Industrial Shove", kind="aoe", steam=20, cooldown=24, windup=0.4, radius=80, damage=d(30), dtype="melee", knock=70, cone=True, min_targets=2,
                       then={"dr": 0.3, "dur": 5}, desc="Pushes back light enemies, then braces (+30% damage resistance)."),
    "piston_brawler": AB(id="double_piston_strike", name="Double Piston Strike", kind="strike", steam=20, cooldown=20, windup=0.3, mult=1.3, hits=2, knock=45,
                         desc="Two rapid punches; the second knocks back."),
    "copper_sentinel": AB(id="braced_fire", name="Braced Fire", kind="buff", steam=18, cooldown=23, windup=0.3, dur=7, mods={"speed": 0.3, "dmg": 1.3, "fire": 1.2}, cond="target",
                          desc="Trades speed for accuracy and firing stability."),
    "ironclad_walker": AB(id="iron_brace", name="Iron Brace", kind="buff", steam=25, cooldown=30, windup=0.35, dur=8, mods={"dr": 0.35, "fire": 0.7}, cond="threatened",
                          desc="Raises frontal armor while firing at a reduced rate."),
    "skyguard_walker": AB(id="sky_suppression", name="Sky Suppression", kind="buff", steam=25, cooldown=28, windup=0.25, dur=6, mods={"fire_air": 1.6}, cond="air",
                          desc="Faster tracking and firing against airborne targets."),
    "thundercoil_frame": AB(id="chain_discharge", name="Chain Discharge", kind="chain", steam=30, cooldown=32, windup=0.6, targets_max=5, jump=90, damage=d(70), dtype="shock", slow=0.5, slow_dur=3,
                            desc="Arcs between a limited number of nearby eligible targets, slowing them."),
    "cannon_strider": AB(id="braced_piercing_shot", name="Braced Piercing Shot", kind="shot", steam=28, cooldown=34, windup=0.8, weapon=0, damage=d(330), dtype="blast", pen=0.45, pierce=2, splash=18,
                         desc="Stops to fire a high-penetration round that punches through."),
    "shieldframe": AB(id="bulwark_formation", name="Bulwark Formation", kind="ward", steam=30, cooldown=36, windup=0.4, radius=130, mult=0.5, dur=8,
                      desc="Reduces frontal projectile damage for itself and a limited area behind it."),
    "claw_harvester": AB(id="rending_sweep", name="Rending Sweep", kind="aoe", steam=24, cooldown=25, windup=0.35, radius=95, damage=d(120), dtype="melee", pen=0.2, cone=True, min_targets=2,
                         desc="Multi-target claw strike with limited armor penetration."),
    "mortar_walker": AB(id="cluster_shell", name="Cluster Shell", kind="shot", steam=32, cooldown=38, windup=0.5, weapon=0, proj="arc", damage=d(90), dtype="blast", splash=40, cluster=5, cluster_damage=d(55), cluster_radius=34,
                        desc="Special round that splits into a limited number of smaller explosions."),
    "furnace_stalker": AB(id="furnace_purge", name="Furnace Purge", kind="zone", steam=30, cooldown=33, windup=0.5, radius=105, offset=80, dps=d(48), dur=4,
                          desc="Wider forward flame burst with bounded burning ticks."),
    "anvilbreaker": AB(id="anvil_crash", name="Anvil Crash", kind="aoe", steam=40, cooldown=38, windup=0.8, radius=130, damage=d(260), dtype="blast", knock=40, telegraph=True, min_targets=3,
                       desc="Ground impact: short-range area damage and disruption of light enemies."),
    "siegebellow": AB(id="siege_round", name="Siege Round", kind="shot", steam=45, cooldown=42, windup=0.9, weapon=0, damage=d(760), dtype="blast", pen=0.4, splash=50, bonus={"structure": 2.0},
                      desc="High-penetration projectile with enhanced structure damage."),
    "furnace_guardian": AB(id="inferno_vent", name="Inferno Vent", kind="zone", steam=42, cooldown=40, windup=0.7, radius=140, offset=95, dps=d(66), dur=5,
                           desc="Temporary forward burning zone with controlled duration."),
    "siege_hammer_walker": AB(id="foundation_breaker", name="Foundation Breaker", kind="strike", steam=38, cooldown=36, windup=0.5, mult=2.2, hits=1, pen=0.35, bonus={"structure": 2.0},
                              desc="Enhanced armor penetration and structure damage."),
    "flak_colossus": AB(id="barrage_lock", name="Barrage Lock", kind="buff", steam=42, cooldown=40, windup=0.3, dur=7, mods={"fire_air": 1.5, "dmg": 1.2}, cond="air",
                        desc="Locks trackers: sustained, more accurate anti-air fire."),
    "thunderstep_bruiser": AB(id="thunder_rush", name="Thunder Rush", kind="charge", steam=38, cooldown=34, windup=0.6, dist=150, radius=80, damage=d(220), dtype="blast", knock=50,
                              desc="Telegraphed short charge and impact with bounded knockback."),
    "shredder_walker": AB(id="full_barrage", name="Full Barrage", kind="buff", steam=40, cooldown=38, windup=0.3, dur=5, mods={"fire": 1.8, "spread": 1.8}, cond="target", heat_lock=3.0,
                          desc="Raises firing rate while worsening accuracy; barrels overheat afterwards."),
    "riftshield_walker": AB(id="rift_bulwark", name="Rift Bulwark", kind="ward", steam=48, cooldown=45, windup=0.6, radius=180, mult=0.35, dur=9,
                            desc="Covers a limited forward area, reducing eligible projectiles."),
    "deepforge_titan": AB(id="great_forge_overdrive", name="Great Forge Overdrive", kind="buff", steam=60, cooldown=48, windup=0.5, dur=8, mods={"fire": 1.5, "fire_air": 1.0}, cond="target",
                          desc="Temporarily improves the cycling of every weapon."),
    "mountain_colossus": AB(id="mountainfall", name="Mountainfall", kind="aoe", steam=65, cooldown=50, windup=1.3, radius=175, damage=d(420), dtype="blast", knock=46, telegraph=True, min_targets=3,
                            desc="Heavily telegraphed area stomp that damages and disrupts ground enemies."),
    "kings_anvil": AB(id="royal_cleave", name="Royal Cleave", kind="aoe", steam=58, cooldown=45, windup=0.9, radius=150, damage=d(600), dtype="melee", pen=0.25, cone=True, min_targets=2,
                      bonus={"heavy": 1.6, "hulk": 1.6}, telegraph=True, desc="Massive cleave with extra effect against armored monsters."),
    "colossal_skybreaker": AB(id="skybreaker_salvo", name="Skybreaker Salvo", kind="salvo", steam=65, cooldown=52, windup=0.6, mult=1.6,
                              desc="All guns fire one coordinated salvo at the biggest air threat, then resume independent targeting."),
    "hammerfall_goliath": AB(id="hammerfall_impact", name="Hammerfall Impact", kind="aoe", steam=68, cooldown=55, windup=1.2, radius=120, damage=d(700), dtype="blast", knock=30, telegraph=True, min_targets=1,
                             bonus={"structure": 2.5}, self_stun=3.0, desc="Devastating localized strike with bonus structure damage, then a long recovery."),
    "embercore_titan": AB(id="embercore_eruption", name="Embercore Eruption", kind="zone", steam=62, cooldown=50, windup=0.8, radius=190, offset=110, dps=d(90), dur=4, cool_lock=4.0,
                          desc="Powerful bounded flame surge followed by forced cooling."),
}

ROLES = {
    "miner_rig": ("mechanical_walker", "melee_damage"), "boiler_stomper": ("anti_swarm", "frontline_defender"),
    "drillwalker": ("anti_armor", "mechanical_walker"), "steam_loader": ("frontline_defender", None), "piston_brawler": ("melee_damage", None),
    "copper_sentinel": ("rifle_infantry", "frontline_defender"), "ironclad_walker": ("armored_vehicle", "anti_armor"), "skyguard_walker": ("mobile_anti_air", None),
    "thundercoil_frame": ("anti_swarm", "mobile_anti_air"), "cannon_strider": ("anti_armor", "ranged_artillery"), "shieldframe": ("frontline_defender", None),
    "claw_harvester": ("anti_swarm", "melee_damage"), "mortar_walker": ("indirect_artillery", None), "furnace_stalker": ("anti_swarm", None),
    "anvilbreaker": ("melee_damage", "anti_swarm"), "siegebellow": ("large_siege", "anti_armor"), "furnace_guardian": ("anti_swarm", "frontline_defender"),
    "siege_hammer_walker": ("large_siege", "anti_armor"), "flak_colossus": ("mobile_anti_air", None), "thunderstep_bruiser": ("melee_damage", None),
    "shredder_walker": ("anti_swarm", None), "riftshield_walker": ("frontline_defender", "repair_support"), "deepforge_titan": ("large_siege", "mobile_anti_air"),
    "mountain_colossus": ("frontline_defender", "anti_swarm"), "kings_anvil": ("anti_armor", "melee_damage"), "colossal_skybreaker": ("mobile_anti_air", None),
    "hammerfall_goliath": ("large_siege", None), "embercore_titan": ("anti_swarm", "mobile_anti_air"),
}

WEAKNESS = {
    "miner_rig": "Light armor, short reach, no anti-air.", "boiler_stomper": "Limited range; vulnerable to sustained ranged attacks.",
    "drillwalker": "Poor swarm clearing, no anti-air, needs contact.", "steam_loader": "Limited damage; poor against siege threats.",
    "piston_brawler": "Fragile versus heavier mechs; cannot attack flyers.", "copper_sentinel": "Slow when braced; modest anti-heavy damage.",
    "ironclad_walker": "Average mobility, no dedicated AA.", "skyguard_walker": "Poor against heavy ground enemies; primary guns are air-only.",
    "thundercoil_frame": "Short range; weaker against shock-resistant bone.", "cannon_strider": "Slow reload, weak against fast swarms.",
    "shieldframe": "Low damage, slow, exposed to attacks from unprotected angles.", "claw_harvester": "Less durable; suffers under ranged bombardment.",
    "mortar_walker": "Minimum range 90, slow, poor melee defense, no AA.", "furnace_stalker": "Short range; inefficient against fire-resistant bone and machines.",
    "anvilbreaker": "Slow windup, little AA, susceptible to concentrated ranged fire.", "siegebellow": "Slow firing, limited close defense.",
    "furnace_guardian": "Short range; vulnerable to ranged anti-heavy attacks.", "siege_hammer_walker": "Low attack frequency; vulnerable when surrounded.",
    "flak_colossus": "Primary weapons cannot target ground; needs escorts.", "thunderstep_bruiser": "Short range, little AA, struggles approaching ranged threats.",
    "shredder_walker": "Overheats; poor armor penetration.", "riftshield_walker": "Low offense, very slow, shield-bypassing melee damage.",
    "deepforge_titan": "Enormous cost, slow, dependent on escorts.", "mountain_colossus": "Extremely slow, short-ranged, vulnerable to air bombardment.",
    "kings_anvil": "Costly, slow to recover from committed strikes, vulnerable to distant flyers.", "colossal_skybreaker": "Huge cost, almost no ground offense.",
    "hammerfall_goliath": "Slow attacks, limited reach, long recovery.", "embercore_titan": "Cooling downtime; fire-resistant enemies; limited primary range.",
}

DESC = {
    "miner_rig": "A mining workframe hastily modified for war: digging claws, miner-lamp faceplate, smoking rear boiler. Still prospects +1.6 Gold/s.",
    "boiler_stomper": "A top-heavy walking boiler with reinforced stomping legs and pressure-release pipes.",
    "drillwalker": "A compact frame whose forearm is an enormous high-torque rotary drill.",
    "steam_loader": "A squat cargo frame with oversized grabbers and a frontal loading plate.",
    "piston_brawler": "An agile frame with massive piston-powered fists.",
    "copper_sentinel": "A copper-plated guard frame with a shielded drum-fed repeater cannon.",
    "ironclad_walker": "The standard dwarven war frame: broad shoulders, arm cannon, crushing fist.",
    "skyguard_walker": "Twin elevated rotary guns that track flyers independently.",
    "thundercoil_frame": "A rune induction coil along its back feeds conductive gauntlets.",
    "cannon_strider": "A tall frame shouldering a cannon whose recoil rocks its whole upper body.",
    "shieldframe": "An enormously broad frame behind a riveted mechanical tower shield.",
    "claw_harvester": "A forward-leaning frame with two oversized cutting claws.",
    "mortar_walker": "A braced walking platform with a high-angle mortar above its shoulders.",
    "furnace_stalker": "A heat-shielded close-range frame with a massive arm flamethrower.",
    "anvilbreaker": "A huge assault frame swinging a two-handed steam hammer.",
    "siegebellow": "Walking artillery: an oversized shoulder siege cannon braced by pistons.",
    "furnace_guardian": "A huge furnace mech with twin flame projectors; its core brightens before it vents.",
    "siege_hammer_walker": "A demolition frame with a piston-driven siege hammer for fortifications.",
    "flak_colossus": "Four elevated autocannon barrels on two independent tracking mounts.",
    "thunderstep_bruiser": "A brutal heavy frame with hydraulic crushing gauntlets that charges.",
    "shredder_walker": "Twin forearm rotary guns with belt feeds and recoil assemblies.",
    "riftshield_walker": "A fortified frame projecting a rune-etched shield over the line.",
    "deepforge_titan": "The kingdom's poster machine: siege cannon, two AA mounts and an emergency crushing arm.",
    "mountain_colossus": "A walking iron fortress with fists that shake the mountain.",
    "kings_anvil": "A regal colossal frame wielding an immense industrial axe. A machine — not a king.",
    "colossal_skybreaker": "Three independent heavy anti-air cannons on a gigantic braced tower frame.",
    "hammerfall_goliath": "A gigantic demolition frame with a colossal impact hammer.",
    "embercore_titan": "A furnace titan with glowing seams, a projector arm and two AA repeaters.",
}

# boomstick alternate armaments (spec §17) — do not add unit IDs
VARIANTS = {
    "copper_sentinel": [dict(id="breacher", name="Breacher Configuration", cost=70, requires=["heavy_gunnery"],
                             weapons=[W(id="breacher_boomstick", range=105, damage=d(24), reload=1.7, targets="ground_lowair", priority="swarm", proj="boom", dtype="pierce", pellets=7, anchor="front", family="boomstick", eject=True)],
                             desc="Heavy close-range industrial shotgun: trades range for burst damage.")],
    "furnace_stalker": [dict(id="thunderjaw", name="Thunderjaw Configuration", cost=110, requires=["heavy_gunnery"],
                             weapons=[W(id="thunderjaw_boomstick", range=118, damage=d(30), reload=1.9, targets="ground_lowair", priority="swarm", proj="boom", dtype="pierce", pellets=9, anchor="front", family="boomstick_big", eject=True)],
                             desc="Heavy boomstick replaces the flamethrower: devastating blasts into packed light enemies.")],
    "thunderstep_bruiser": [dict(id="breach_cannon", name="Breach Cannon Configuration", cost=160, requires=["heavy_gunnery"], add=True,
                                 weapons=[W(id="breach_cannon", range=96, damage=d(36), reload=2.9, targets="ground", priority="swarm", proj="boom", dtype="pierce", pellets=7, anchor="chest", family="boomstick_chest", eject=True)],
                                 desc="Massive short-range shotgun attachment fired between gauntlet strikes.")],
}


def build_mechs():
    out = {}
    for uid, name, cls, tier, hp, arm, spd, rng, gold, cd, tgt in SPEC:
        c = CLASS[cls]
        art_scale = round(c["rel"] * RIFLEMAN_PX / DESIGN_H, 3)
        weps = weapons_for(uid, rng)
        for w in weps:
            ax, ay = A[w.pop("anchor")]
            if w["proj"] == "melee":
                w["mount"] = [round(c["radius"] * 0.9, 1), round(ay * art_scale * 0.7, 1)]
            else:
                w["mount"] = [round(ax * art_scale, 1), round(ay * art_scale, 1)]
            w["range"] = float(w["range"])
        e = dict(cls="walker", domain="ground", role=ROLES[uid][0], role2=ROLES[uid][1], mech_id="mech_" + uid,
                 mech_class=cls, hp=round(hp * HP_K), arm=min(0.5, arm), armor="mech", speed=round(spd * SPD_K, 1),
                 radius=c["radius"], gold=int(round(gold * GOLD_K / 5.0) * 5), steam=0, cooldown=round(cd * CD_K, 1),
                 behavior="mech", art=uid, art_scale=art_scale, blocks=True, frontline=cls != "medium" or uid in ("shieldframe", "claw_harvester", "ironclad_walker"),
                 death_time=c["death"], weapons=weps, ability=ABILITIES[uid], weakness=WEAKNESS[uid], targets_spec=tgt,
                 spec_stats=dict(hp=hp, arm=arm, spd=spd, rng=rng, gold=gold, cd=cd), desc=DESC[uid])
        if uid in ("copper_sentinel", "mortar_walker", "cannon_strider", "siegebellow", "skyguard_walker", "flak_colossus", "colossal_skybreaker"):
            e["hold_behind"] = True
            e["frontline"] = False
            e["rear_offset"] = {"copper_sentinel": 40, "skyguard_walker": 70, "flak_colossus": 90, "colossal_skybreaker": 110}.get(uid, 120)
        if uid == "miner_rig":
            e["prospect"] = 1.6
        if uid in ("shieldframe", "steam_loader", "riftshield_walker", "mountain_colossus"):
            e["taunt"] = True
        if uid == "shieldframe":
            e["front_guard"] = 0.35
        if uid == "riftshield_walker":
            e["front_guard"] = 0.25
        if uid in VARIANTS:
            for v in VARIANTS[uid]:
                for w in v["weapons"]:
                    if "anchor" in w:
                        ax, ay = A[w.pop("anchor")]
                        w["mount"] = [round(ax * art_scale, 1), round(ay * art_scale, 1)]
                    w["range"] = float(w["range"])
            e["variants"] = VARIANTS[uid]
        out[uid] = (tier, e)
    return out
