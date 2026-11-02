#!/usr/bin/env python3
"""Dwarves vs Zombies — content registry generator.

Emits the master data registries in ../data/*.json:
  dwarf_roster.json   160 playable dwarven unit types (18 implemented in M001)
  undead_roster.json  110 regular undead types (14 implemented in M001)
  bosses.json         15 major bosses (Mine Maw implemented in M001)
  stages.json         150 campaign stages (001-015 implemented in M001)
  tech.json           Great Forge doctrines + per-unit research nodes

Stable IDs are derived from names and must never be renamed once shipped.
Planned entries carry provisional roles and NO invented combat statistics:
their stats are null until balanced in the milestone listed in `milestone`.

Run:  python3 tools/gen_data.py
"""
import json, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mech_data
import giant_data
import roster_data
import act1b_data
import act2_data
import act3_data
import act4_data
import act5_data
import stage_kit
from stage_kit import ch

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data")
os.makedirs(OUT, exist_ok=True)


def sid(name):
    s = name.lower().replace("'", "")
    s = re.sub(r"[^a-z0-9]+", "_", s).strip("_")
    return s


# --------------------------------------------------------------------------------------
# DWARVEN ROSTER (names / branches / tiers exactly as in the M001 master prompt)
# --------------------------------------------------------------------------------------
BRANCHES = [
    ("A", "infantry", "Infantry & Firearms", "M002", {
        0: ["Tunnel Militia", "Ironhold Rifleman", "Shieldbearer"],
        1: ["Blunderbussier", "Grenadier", "Hammer Guard", "Sapper", "Longrifle Scout", "Bayonet Fusilier", "Shotgun Breacher", "Powder Loader"],
        2: ["Flame Trooper", "Steamgunner", "Rune Cartridge Rifleman", "Trench Guard", "Repeater Fusilier", "Bombardier", "Armor Piercer"],
        3: ["Veteran Rifleman", "Heavy Hammerer", "Skyguard Marksman", "Rolling-Shield Trooper", "Incendiary Grenadier", "Mortar Spotter"],
        4: ["Royal Iron Guard", "Thunder Rifleman", "Furnace Assault Trooper", "Runebreaker Infantry", "Heavy Gatling Dwarf"],
        5: ["Colossus Guard", "Arc Lance Gunner", "Kingsguard Bulwark"]}),
    ("B", "engineers", "Engineers & Fieldworks", "M002", {
        1: ["Field Mechanic", "Ammunition Porter", "Boiler Tender", "Salvage Crew"],
        2: ["Repair Wagon", "Steam Sapper", "Field Barricade Crew", "Mine Layer", "Spotter Balloon Crew"],
        3: ["Armored Recovery Team", "Turret Engineer", "Pressure Regulator", "Runic Mechanic", "Battlefield Surveyors"],
        4: ["Heavy Recovery Crawler", "Mobile Forge Crew", "Counter-Curse Technician", "Automated Turret Crew"],
        5: ["Master Fabricator Team", "Titan Maintenance Crew"]}),
    ("C", "artillery", "Artillery & Anti-Air", "M002", {
        0: ["Light Field Cannon", "Flak Crew"],
        1: ["Organ Gun", "Portable Mortar", "Grapeshot Culverin", "Skyhook Rocket Rack"],
        2: ["Steam Mortar", "Heavy Bombard", "Rocket Battery", "Shrapnel Howitzer", "Twin Flak Mount"],
        3: ["Siege Howitzer", "Piston Cannon", "Counterbattery Mortar", "Multi-Barrel Flak"],
        4: ["Heavy Skybreaker", "Rune Cannon", "Thunder Rocket Battery"],
        5: ["Mountain Siege Cannon", "Celestial Flak Array"]}),
    ("D", "vehicles", "Armored Vehicles & Tanks", "M003", {
        1: ["Brasshound Armored Car", "Coalrunner Scout Tank", "Steamwheel APC"],
        2: ["Copperback Light Tank", "Ironrunner Light Tank", "Flamebelcher Medium Tank", "Ironclad Medium Tank", "Skyshield AA Tank"],
        3: ["Thunderback Heavy Tank", "Bastion Heavy Tank", "Siege Sapper Tank", "Boiler Ram", "Twin-Cannon Ironclad", "Sniper Tank Hunter", "Steamtread Heavy Carrier"],
        4: ["Siegecrawler", "Mountainshield Heavy Tank", "Thunderrail Tank Destroyer", "Firestorm Assault Tank", "Dreadplate Breaker", "Mobile Flak Fortress"],
        5: ["Mountainbreaker", "Worldhammer Siege Tank", "Brass Leviathan", "Iron Bastion Prime", "Dreadnought Landship"]}),
    ("E", "walkers", "Mechanical Walkers & Mechs", "M004", {
        1: ["Miner Rig"],
        2: ["Boiler Stomper", "Drillwalker", "Steam Loader", "Piston Brawler", "Copper Sentinel"],
        3: ["Ironclad Walker", "Skyguard Walker", "Thundercoil Frame", "Cannon Strider", "Shieldframe", "Claw Harvester", "Mortar Walker", "Furnace Stalker"],
        4: ["Anvilbreaker", "Siegebellow", "Furnace Guardian", "Siege Hammer Walker", "Flak Colossus", "Thunderstep Bruiser", "Shredder Walker", "Riftshield Walker"],
        5: ["Deepforge Titan", "Mountain Colossus", "King's Anvil", "Colossal Skybreaker", "Hammerfall Goliath", "Embercore Titan"]}),
    ("F", "aeronautics", "Flying Machines & Aircraft", "M005", {
        0: ["Dwarven Flying Machine"],
        1: ["Scout Gyro", "Rotary Interceptor"],
        2: ["Bombard Gyro", "Twin-Rotor Interceptor", "Skyspotter Scout", "Coalwing Strafing Craft"],
        3: ["Ironwing Gunship", "Thunderwing", "Sky Mender", "Heavy Gyro Bomber", "Flak Chaser", "Rune-Sight Scout"],
        4: ["Forge Bomber", "Twin-Flame Gunship", "Heavy Interceptor", "Rocketwing", "Siege Breaker Bomber"],
        5: ["Stormforge Bomber", "Royal Skyguard", "Skyhammer Assault Craft", "Arcwing Superiority Craft"]}),
    ("G", "airships", "Airships & Flying Fortresses", "M006", {
        2: ["Scout Blimp"],
        3: ["Ironcloud", "Skyshield Airship"],
        4: ["Bombard Zeppelin", "Thunderbarge", "Ironhold Carrier", "Forgewatch Frigate"],
        5: ["Skyforge Dreadnought", "Mountain Ark", "Skyhammer Battleship", "Rune Citadel Airship", "Grand Forge Carrier"]}),
]

BRANCH_CLASS = {"A": "infantry", "B": "engineer", "C": "artillery", "D": "vehicle",
                "E": "walker", "F": "aircraft", "G": "airship"}


def provisional_role(name, branch):
    n = name.lower()
    rules = [
        (["carrier"], "aerial_carrier" if branch in "FG" else "transport"),
        (["flak", "skyguard", "skyshield", "skybreaker", "skyhook"], "anti_air"),
        (["mortar", "howitzer", "bombard", "rocket"], "indirect_artillery"),
        (["mechanic", "repair", "recovery", "maintenance", "mender", "fabricator", "forge crew", "regulator", "tender"], "repair_support"),
        (["porter", "loader", "surveyor", "spotter", "scout", "balloon"], "support_utility"),
        (["gunship", "assault craft"], "multirole_gunship"),
        (["bomber"], "tactical_bomber"),
        (["interceptor", "superiority", "royal skyguard", "chaser", "rotary"], "aerial_interceptor"),
        (["shield", "guard", "bulwark", "bastion", "barricade", "sentinel", "trench"], "frontline_defender"),
        (["flame", "furnace", "incendiary", "firestorm", "organ", "grape", "shotgun", "blunderbuss", "gatling", "shredder", "repeater"], "anti_swarm"),
        (["piercer", "hunter", "destroyer", "breaker", "rail", "runebreaker", "lance"], "anti_armor"),
        (["hammer", "brawler", "bruiser", "anvil", "ram", "claw", "militia"], "melee_damage"),
        (["siege", "cannon", "mountain", "worldhammer", "leviathan", "landship", "dreadnought", "titan", "colossus", "goliath", "ark", "battleship", "citadel"], "large_siege"),
        (["sapper", "mine layer", "turret"], "engineering_fieldworks"),
    ]
    for keys, role in rules:
        if any(k in n for k in keys):
            return role
    return {"A": "rifle_infantry", "B": "engineering_fieldworks", "C": "ranged_artillery",
            "D": "armored_vehicle", "E": "mechanical_walker", "F": "aerial_interceptor",
            "G": "airship_artillery"}[branch]


# ---- Implemented M001 dwarves: full statistics (provisional M001 balance, tuned by sim) ----
# weapon fields: id, range, min_range, damage, dtype, reload, targets(ground|air|both|ground_lowair),
#   priority(nearest|air|armored|swarm|structure|support|threat), proj(bullet|shell|arc|flak|bomb|melee|cone|spit|bolt|shard|volley|steam),
#   splash, mount[x,y], arc[min_deg,max_deg] relative to facing (0=fwd,-90=up,+90=down), windup, burst, burst_gap, ap
W = lambda **k: k
IMPL_DWARVES = {
    "tunnel_militia": dict(cls="infantry", domain="ground", role="melee_damage", role2="frontline_defender",
        hp=95, armor="light", speed=44, radius=11, gold=25, steam=0, cooldown=2.5, bounty=0,
        behavior="melee", art="militia", blocks=True,
        weapons=[W(id="mining_pick", range=24, damage=10, dtype="melee", reload=0.9, targets="ground", priority="nearest", proj="melee", mount=[14, -20])],
        desc="Cheap miners handed a pick and pointed at the dead. Fill gaps, soak early pressure, chew through Rotters."),
    "ironhold_rifleman": dict(cls="infantry", domain="ground", role="rifle_infantry",
        hp=70, armor="flesh", speed=38, radius=10, gold=40, steam=0, cooldown=3.2,
        behavior="ranged", art="rifleman", hold_behind=True, blocks=True,
        weapons=[W(id="ironhold_rifle", range=265, damage=17, dtype="pierce", reload=1.7, targets="ground", priority="threat", proj="bullet", mount=[24, -24], reload_anim=True)],
        desc="The backbone of the Holds. Heavy blackpowder rifle, steady aim, terrible jokes. Ground targets only."),
    "shieldbearer": dict(cls="infantry", domain="ground", role="frontline_defender",
        hp=290, armor="heavy", speed=32, radius=13, gold=60, steam=0, cooldown=6, taunt=True,
        behavior="melee", art="shieldbearer", blocks=True, frontline=True,
        weapons=[W(id="shield_bash", range=26, damage=11, dtype="melee", reload=1.2, targets="ground", priority="nearest", proj="melee", mount=[16, -22])],
        desc="A riveted tower shield and a refusal to step back. Draws undead attacks and anchors the line."),
    "blunderbussier": dict(cls="infantry", domain="ground", role="anti_swarm",
        hp=105, armor="light", speed=36, radius=11, gold=55, steam=0, cooldown=5,
        behavior="ranged", art="blunderbussier", hold_behind=True, blocks=True,
        weapons=[W(id="blunderbuss", range=115, damage=13, dtype="pierce", reload=2.1, targets="ground_lowair", priority="swarm", proj="cone", splash=5, mount=[22, -22])],
        desc="Point-blank scattershot hits up to five undead in a cone — and low-diving bats. Short ranged."),
    "grenadier": dict(cls="infantry", domain="ground", role="anti_swarm", role2="indirect_artillery",
        hp=80, armor="flesh", speed=36, radius=10, gold=65, steam=0, cooldown=6,
        behavior="ranged", art="grenadier", hold_behind=True, blocks=True,
        weapons=[W(id="powder_grenade", range=235, min_range=50, damage=34, dtype="blast", reload=3.0, targets="ground", priority="swarm", proj="arc", splash=46, mount=[8, -34], windup=0.35)],
        desc="Lobbed blackpowder bombs shatter skeletons and clumped hordes behind shields."),
    "field_mechanic": dict(cls="engineer", domain="ground", role="repair_support",
        hp=85, armor="light", speed=40, radius=10, gold=50, steam=0, cooldown=8,
        behavior="repair", art="mechanic", hold_behind=True, blocks=True,
        repair=dict(rate=26, range=150, pool=900, classes=["vehicle", "walker", "artillery", "stronghold"]),
        weapons=[W(id="wrench", range=22, damage=6, dtype="melee", reload=1.0, targets="ground", priority="nearest", proj="melee", mount=[12, -20])],
        desc="Repairs damaged vehicles, walkers and artillery within range. Carries a finite crate of parts (900 HP of repairs)."),
    "light_field_cannon": dict(cls="artillery", domain="ground", role="ranged_artillery", role2="anti_armor",
        hp=170, armor="light", speed=26, radius=16, gold=90, steam=0, cooldown=9,
        behavior="artillery", art="field_cannon", hold_behind=True, blocks=False, rear_offset=170,
        weapons=[W(id="field_gun", range=490, min_range=80, damage=48, dtype="blast", reload=3.4, targets="ground", priority="armored", proj="shell", splash=30, mount=[30, -18], ap=True)],
        desc="Direct-fire cannon. Out-ranges every early undead, punches armor and structures. Helpless if reached."),
    "flak_crew": dict(cls="artillery", domain="ground", role="anti_air",
        hp=130, armor="light", speed=28, radius=14, gold=70, steam=0, cooldown=7,
        behavior="artillery", art="flak_crew", hold_behind=True, blocks=False, rear_offset=120,
        weapons=[W(id="flak_gun", range=430, damage=19, dtype="flak", reload=1.05, targets="air", priority="air", proj="flak", splash=42, mount=[18, -30], arc=[-170, -10])],
        desc="Upward-firing flak cannon. Bursts shred bats and shriekers. Cannot engage ground targets at all."),
    "organ_gun": dict(cls="artillery", domain="ground", role="anti_swarm",
        hp=150, armor="light", speed=26, radius=15, gold=110, steam=0, cooldown=10,
        behavior="artillery", art="organ_gun", hold_behind=True, blocks=False, rear_offset=110,
        weapons=[W(id="organ_volley", range=290, damage=10, dtype="pierce", reload=4.4, targets="ground", priority="swarm", proj="bullet", burst=7, burst_gap=0.08, mount=[26, -16])],
        desc="Seven barrels fired in a rippling volley. Devastating against packed hordes, poor against armor."),
    "brasshound_armored_car": dict(cls="vehicle", domain="ground", role="armored_vehicle", role2="anti_swarm",
        hp=420, armor="machine", speed=72, radius=20, gold=120, steam=0, cooldown=12,
        behavior="vehicle", art="brasshound", blocks=True,
        weapons=[W(id="brass_mg", range=225, damage=6, dtype="pierce", reload=0.24, targets="ground", priority="swarm", proj="bullet", mount=[10, -34])],
        desc="Fast wheeled car with a turret machine-gun. Rushes to plug holes and mows down runners."),
    "copperback_light_tank": dict(cls="vehicle", domain="ground", role="armored_vehicle", role2="anti_armor",
        hp=780, armor="machine", speed=36, radius=26, gold=200, steam=20, cooldown=18,
        behavior="vehicle", art="copperback", blocks=True,
        weapons=[W(id="copperback_cannon", range=345, min_range=40, damage=72, dtype="blast", reload=3.8, targets="ground", priority="armored", proj="shell", splash=26, mount=[44, -40], ap=True),
                 W(id="coax_mg", range=220, damage=5, dtype="pierce", reload=0.3, targets="ground", priority="swarm", proj="bullet", mount=[38, -36])],
        desc="Steam light tank with independent main cannon (armor priority) and coaxial MG (swarm priority)."),
    "miner_rig": dict(cls="walker", domain="ground", role="mechanical_walker", role2="melee_damage",
        hp=560, armor="machine", speed=30, radius=22, gold=150, steam=10, cooldown=15,
        behavior="walker", art="miner_rig", blocks=True, prospect=1.6,
        weapons=[W(id="rig_drill", range=34, damage=24, dtype="melee", reload=0.7, targets="ground", priority="armored", proj="melee", mount=[36, -30], bonus={"bone": 1.5, "structure": 1.6})],
        desc="Two-legged mining walker. Drill shreds bone and stone; while it stands it prospects +1.6 Gold/s."),
    "boiler_stomper": dict(cls="walker", domain="ground", role="mechanical_walker", role2="frontline_defender",
        hp=950, armor="machine", speed=28, radius=26, gold=240, steam=30, cooldown=20,
        behavior="walker", art="boiler_stomper", blocks=True, frontline=True,
        weapons=[W(id="stomp", range=58, damage=42, dtype="blast", reload=2.3, targets="ground", priority="swarm", proj="melee", splash=64, mount=[30, 0], windup=0.45),
                 W(id="steam_vent", range=95, damage=7, dtype="fire", reload=0.45, targets="ground_lowair", priority="nearest", proj="steam", splash=3, mount=[34, -60])],
        desc="A walking boiler. Ground-shaking stomps scatter hordes while vents scald anything close — even diving bats."),
    "dwarven_flying_machine": dict(cls="aircraft", domain="air", role="aerial_interceptor",
        hp=150, armor="light", speed=125, radius=16, gold=70, steam=0, cooldown=7,
        behavior="interceptor", art="flying_machine", altitude=[230, 330],
        weapons=[W(id="gyro_mg", range=205, damage=7, dtype="pierce", reload=0.28, targets="both", priority="air", proj="bullet", mount=[22, 4], ground_mult=0.5)],
        desc="Rotor gyrocopter with a forward MG. Hunts enemy flyers first; strafes the ground when the sky is clear."),
    "scout_gyro": dict(cls="aircraft", domain="air", role="support_utility", role2="aerial_interceptor",
        hp=95, armor="light", speed=165, radius=13, gold=55, steam=0, cooldown=8,
        behavior="scout", art="scout_gyro", altitude=[180, 240], spotter=dict(range=260, art_range=1.2, art_dmg=1.15),
        weapons=[W(id="scout_carbine", range=160, damage=4, dtype="pierce", reload=0.35, targets="both", priority="air", proj="bullet", mount=[16, 4])],
        desc="Fast spotter. While aloft, artillery gains +20% range, +15% damage, and burrowed enemies near it are revealed."),
    "bombard_gyro": dict(cls="aircraft", domain="air", role="tactical_bomber",
        hp=230, armor="light", speed=100, radius=18, gold=140, steam=0, cooldown=14,
        behavior="bomber", art="bombard_gyro", altitude=[250, 290], ammo=4, rearm=4.0,
        weapons=[W(id="gyro_bombs", range=60, damage=52, dtype="blast", reload=0.35, targets="ground", priority="swarm", proj="bomb", splash=52, mount=[0, 16], arc=[60, 120])],
        desc="Attack runs with four bombs, then returns to the stronghold to rearm. Ground targets only."),
    "ironwing_gunship": dict(cls="aircraft", domain="air", role="multirole_gunship",
        hp=680, armor="machine", speed=70, radius=28, gold=260, steam=25, cooldown=22,
        behavior="gunship", art="ironwing", altitude=[280, 320], standoff=230,
        weapons=[W(id="belly_cannon", range=310, damage=56, dtype="blast", reload=3.0, targets="ground", priority="armored", proj="shell", splash=34, mount=[10, 22], arc=[10, 160], ap=True),
                 W(id="dorsal_turret", range=245, damage=8, dtype="pierce", reload=0.25, targets="air", priority="air", proj="bullet", mount=[-6, -20], arc=[-180, 180])],
        desc="Heavy twin-rotor gunship. Belly cannon pounds the ground while a dorsal turret independently fights flyers."),
    "ironcloud": dict(cls="airship", domain="air", role="airship_artillery",
        hp=2400, armor="machine", speed=18, radius=60, gold=450, steam=60, cooldown=40,
        behavior="airship", art="ironcloud", altitude=[175, 185], hold_range=380,
        weapons=[W(id="fore_broadside", range=430, damage=62, dtype="blast", reload=3.2, targets="ground", priority="structure", proj="shell", splash=32, mount=[38, 44], arc=[0, 170], ap=True),
                 W(id="aft_broadside", range=430, damage=62, dtype="blast", reload=3.7, targets="ground", priority="armored", proj="shell", splash=32, mount=[-30, 44], arc=[0, 170], ap=True),
                 W(id="swivel_flak", range=310, damage=11, dtype="flak", reload=0.32, targets="air", priority="air", proj="flak", splash=24, mount=[0, -62], arc=[-180, 180])],
        desc="Armored airship. Two broadside cannons and a swivel flak mount each pick and track their own targets."),
}

# M002: the full 28-frame mecha branch replaces the M001 Miner Rig / Boiler Stomper entries
# (same stable IDs, improved and re-balanced — see tools/mech_data.py)
MECHS = mech_data.build_mechs()
for _uid, (_tier, _e) in MECHS.items():
    IMPL_DWARVES[_uid] = _e

# Dwarven stronghold (not a roster unit)
STRONGHOLDS = {
    "dwarf_stronghold": dict(cls="stronghold", domain="ground", hp=3200, armor="structure", radius=60, art="dwarf_hold",
        weapons=[W(id="bastion_gun", range=300, damage=11, dtype="pierce", reload=1.2, targets="both", priority="nearest", proj="bullet", mount=[50, -194])]),
    "undead_citadel": dict(cls="stronghold", domain="ground", hp=2500, armor="structure", radius=60, art="undead_citadel",
        weapons=[W(id="bone_ballista", range=280, damage=12, dtype="pierce", reload=1.5, targets="both", priority="nearest", proj="shard", mount=[40, -180])]),
}

# --------------------------------------------------------------------------------------
# UNDEAD ROSTER
# --------------------------------------------------------------------------------------
UNDEAD = [
    ("melee", "Undead Melee Infantry", ["Rotter", "Zombie Miner", "Shambler", "Grave Crawler", "Plague Runner", "Ossuary Skeleton", "Rusted Legionary", "Bone Shieldbearer", "Bone Pikeman", "Ossuary Axeman", "Grave Knight", "Barrow Spearman", "Blight Marauder", "Rotting Berserker", "Fungal Host", "Pestilent Soldier", "Crypt Halberdier", "Tomb Stalker", "Hollow Guard", "Risen Bomb Carrier", "Wretched Climber", "Carcass Devourer", "Bone Vanguard", "Grave Warden", "Black Rot Infantry", "Cursed Dwarf Thrall", "Plague Mauler", "Dread Executioner", "Ossuary Champion", "Riftbound Legionary"]),
    ("ranged", "Undead Ranged Units & Necromancers", ["Bone Archer", "Grave Slinger", "Rot Spitter", "Plague Sprayer", "Crypt Hexer", "Corpse Priest", "Necromancer", "Ossuary Caller", "Cinder Wraith", "Spirit Binder", "Plague Herald", "Bone Lancer", "Grave Dart Thrower", "Funeral Bell Keeper", "Rot Channeler", "Ash Hexer", "Night Seer", "Rift Conjurer"]),
    ("monster", "Undead Monsters & Abominations", ["Flesh Hulk", "Bone Golem", "Plague Beast", "Burrow Horror", "Corpse Mound", "Rot Hound", "Grave Spider", "Tomb Centipede", "Flesh Charger", "Bone Devourer", "Stitchback Giant", "Carrion Bull", "Ghoul Matriarch", "Oozing Horror", "Ossuary Juggernaut", "Cathedral Ghast", "Plague Colossus", "Blackroot Abomination", "Corpse Burrower", "Rift Maw"]),
    ("siege", "Undead Siege & Structures", ["Bone Catapult", "Corpse Lobber", "Grave Mortar", "Bone Spire", "Grave Flak Spire", "Necrotic Beacon", "Cursed Barricade", "Plague Cauldron", "Bone Bolt Thrower", "Walking Crypt", "Bone Ram", "Flesh Trebuchet", "Grave Howitzer", "Plague Spore Cannon", "Rot Launcher", "Soul Turret", "Rift Obelisk", "Wraith Beacon"]),
    ("flying", "Flying Undead", ["Carrion Bat", "Blight Bat", "Grave Moth", "Plague Shrieker", "Bone Wyvern", "Skeletal Vulture", "Rotwing", "Tomb Gargoyle", "Carrion Wasp", "Spectral Wraith", "Bone Drake", "Plague Harpy", "Gravewing Stalker", "Rift Crow", "Ossuary Flier", "Banshee Wing", "Wraith Swarm", "Necrotic Sky Serpent"]),
    ("corrupted", "Corrupted Dwarven Machines", ["Risen Copperback", "Cursed Ironclad", "Possessed Drillwalker", "Gravegun Tank", "Haunted Flying Machine", "Infected Airbarge"]),
]
UNDEAD_ROLE = {"melee": "melee_infantry", "ranged": "ranged_support", "monster": "monster", "siege": "siege_structure", "flying": "air_creature", "corrupted": "corrupted_machine"}

IMPL_UNDEAD = {
    "rotter": dict(cls="infantry", domain="ground", role="horde_fodder", hp=72, armor="flesh", speed=22, radius=10, bounty=4, threat=1,
        behavior="melee", art="rotter", blocks=True,
        weapons=[W(id="claw", range=22, damage=7, dtype="melee", reload=1.1, targets="ground", priority="nearest", proj="melee", mount=[-12, -22])],
        desc="Miserable shambling corpse. Alone, pitiful. In hundreds, an avalanche.", counter="Anything. Riflemen, Militia, Organ Guns."),
    "zombie_miner": dict(cls="infantry", domain="ground", role="burrower", hp=115, armor="light", speed=24, radius=11, bounty=7, threat=2,
        behavior="burrower", art="zombie_miner", blocks=True, burrow_until=0.55,
        weapons=[W(id="rusted_pick", range=24, damage=11, dtype="melee", reload=1.0, targets="ground", priority="nearest", proj="melee", mount=[-14, -24])],
        desc="Dead miners who still dig. They tunnel under the front and erupt near your line.", counter="Keep militia and blunderbusses near the rear line; Scout Gyros reveal tunnels."),
    "grave_crawler": dict(cls="infantry", domain="ground", role="flanker", hp=48, armor="flesh", speed=36, radius=8, bounty=5, threat=1.5,
        behavior="crawler", art="grave_crawler", blocks=False, low_profile=True,
        weapons=[W(id="crawler_bite", range=18, damage=7, dtype="melee", reload=0.6, targets="ground", priority="support", proj="melee", mount=[-10, -6])],
        desc="Legless horror that slips beneath the battle line to gnaw on crews and mechanics. Halved blast damage.", counter="Riflemen and militia guarding artillery; brass MG fire."),
    "plague_runner": dict(cls="infantry", domain="ground", role="suicide_rusher", hp=55, armor="flesh", speed=62, radius=9, bounty=5, threat=1.5,
        behavior="melee", art="plague_runner", blocks=True, death_burst=dict(damage=20, radius=55, dtype="acid"),
        weapons=[W(id="runner_claw", range=20, damage=6, dtype="melee", reload=0.7, targets="ground", priority="nearest", proj="melee", mount=[-12, -22])],
        desc="Bloated sprinter. Bursts in a plague cloud when killed — kill it before it reaches your line.", counter="Long-range rifles and cannons; don't let it die in your formation."),
    "ossuary_skeleton": dict(cls="infantry", domain="ground", role="melee_infantry", hp=90, armor="bone", speed=30, radius=10, bounty=6, threat=2,
        behavior="melee", art="skeleton", blocks=True,
        weapons=[W(id="rusted_blade", range=24, damage=10, dtype="melee", reload=0.9, targets="ground", priority="nearest", proj="melee", mount=[-14, -26])],
        desc="Rattling bone soldier. Bullets pass through the gaps; blasts and hammers shatter it.", counter="Grenadiers, cannons, Miner Rig drills."),
    "bone_shieldbearer": dict(cls="infantry", domain="ground", role="shield_wall", hp=210, armor="bone_shield", speed=24, radius=13, bounty=9, threat=3, taunt=True,
        behavior="melee", art="bone_shield", blocks=True, frontline=True,
        weapons=[W(id="shield_edge", range=24, damage=9, dtype="melee", reload=1.2, targets="ground", priority="nearest", proj="melee", mount=[-14, -24])],
        desc="Coffin-lid shield turns aside rifle fire (-70% pierce). Screens archers behind it.", counter="Arcing grenades, cannon shells, bombs."),
    "grave_knight": dict(cls="infantry", domain="ground", role="elite_melee", hp=440, armor="heavy", speed=26, radius=14, bounty=18, threat=5,
        behavior="melee", art="grave_knight", blocks=True, frontline=True,
        weapons=[W(id="grave_greatsword", range=30, damage=26, dtype="melee", reload=1.5, targets="ground", priority="nearest", proj="melee", splash=28, mount=[-18, -30], windup=0.3)],
        desc="Armored revenant with a cleaving greatsword. Shrugs off bullets.", counter="Armor-piercing cannons, tank shells, Miner Rig."),
    "bone_archer": dict(cls="infantry", domain="ground", role="ranged_infantry", hp=60, armor="bone", speed=26, radius=9, bounty=6, threat=2,
        behavior="ranged", art="bone_archer", hold_behind=True, blocks=True,
        weapons=[W(id="bone_bow", range=245, damage=10, dtype="pierce", reload=1.8, targets="ground", priority="threat", proj="arrow", mount=[-18, -28])],
        desc="Skeletal archer behind the shield wall. Fragile, but picks off riflemen.", counter="Grenadiers, aircraft strafing, cannons."),
    "rot_spitter": dict(cls="infantry", domain="ground", role="anti_armor", hp=95, armor="flesh", speed=24, radius=10, bounty=8, threat=3,
        behavior="ranged", art="rot_spitter", hold_behind=True, blocks=True,
        weapons=[W(id="acid_spit", range=220, min_range=40, damage=15, dtype="acid", reload=2.4, targets="ground", priority="armored", proj="spit", splash=26, mount=[-14, -30])],
        desc="Swollen corpse that arcs corrosive bile. Acid eats through dwarven armor plate.", counter="Kill it before tanks close in — rifles, organ guns, bombers."),
    "necromancer": dict(cls="infantry", domain="ground", role="summoner", hp=150, armor="flesh", speed=22, radius=11, bounty=25, threat=6,
        behavior="necromancer", art="necromancer", hold_behind=True, blocks=True,
        raise_dead=dict(interval=7.0, count=2, range=220, cap=6, windup=1.1, enemy="rotter"),
        weapons=[W(id="necro_bolt", range=235, damage=12, dtype="necro", reload=2.0, targets="both", priority="threat", proj="bolt", mount=[-16, -40])],
        desc="Raises fresh Rotters from nearby corpses every few seconds (glowing green telegraph). Bolts hit air and ground.", counter="Priority target: cannons, bombers, gunships. Fewer corpses = fewer risen."),
    "flesh_hulk": dict(cls="monster", domain="ground", role="breakthrough_monster", hp=1450, armor="hulk", speed=16, radius=26, bounty=45, threat=12,
        behavior="melee", art="flesh_hulk", blocks=True, frontline=True,
        weapons=[W(id="hulk_slam", range=50, damage=62, dtype="blast", reload=2.7, targets="ground", priority="nearest", proj="melee", splash=50, mount=[-34, -10], windup=0.85)],
        desc="Stitched mountain of flesh. Slow, telegraphed ground slams crush whole squads. Bullets sink in.", counter="Armor-piercing shells, tanks, Miner Rig; spread infantry when it rears back."),
    "carrion_bat": dict(cls="flyer", domain="air", role="swarm_flyer", hp=42, armor="flesh", speed=110, radius=9, bounty=4, threat=1.5,
        behavior="bat", art="carrion_bat", altitude=[260, 380],
        weapons=[W(id="bat_bite", range=20, damage=6, dtype="melee", reload=0.7, targets="both", priority="support", proj="melee", mount=[-8, 4])],
        desc="Rotting giant bat. Packs dive on crews and aircraft. Infantry rifles cannot hit it.", counter="Flak Crews, Flying Machines, Blunderbussiers when they dive low."),
    "plague_shrieker": dict(cls="flyer", domain="air", role="anti_aircraft_flyer", hp=135, armor="flesh", speed=70, radius=14, bounty=10, threat=4,
        behavior="shrieker", art="plague_shrieker", altitude=[220, 320], standoff=170,
        weapons=[W(id="shriek_spit", range=205, damage=14, dtype="acid", reload=1.6, targets="both", priority="air", proj="spit", splash=18, mount=[-16, 0])],
        desc="Screaming winged corpse that hunts aircraft with acid. Hovers out of rifle reach.", counter="Flak Crews; massed Flying Machines."),
    "bone_spire": dict(cls="structure", domain="ground", role="defensive_structure", hp=650, armor="structure", speed=0, radius=18, bounty=30, threat=6,
        behavior="structure", art="bone_spire", blocks=False, static=True,
        weapons=[W(id="bone_shard", range=330, damage=14, dtype="pierce", reload=1.25, targets="both", priority="air", proj="shard", mount=[0, -86])],
        desc="Rooted bone tower near undead ground. Flings shards at aircraft first, then infantry.", counter="Field cannons and bombers outrange it."),
}

# M002b: undead giants (same stable roster IDs; see tools/giant_data.py)
GIANTS = giant_data.build_giants()
IMPL_UNDEAD.update(GIANTS)
# M003: the rest of the roster (see tools/roster_data.py)
RD, RD_KITS = roster_data.build_dwarves()
RU, RU_KITS = roster_data.build_undead()
RB, RB_KITS = roster_data.build_bosses()
IMPL_UNDEAD.update(RU)

ROLE_TEXT = {"frontline_defender": "Holds the front line.", "rifle_infantry": "Line infantry.", "anti_swarm": "Cuts down packed hordes.",
             "anti_armor": "Breaks armor and monsters.", "anti_air": "Shoots down flyers.", "indirect_artillery": "Long-range indirect fire.",
             "large_siege": "Heavy siege firepower.", "armored_vehicle": "Armored fighting vehicle.", "repair_support": "Repairs machines.",
             "engineering_fieldworks": "Battlefield engineering.", "support_utility": "Support and scouting.", "aerial_interceptor": "Fights for the sky.",
             "tactical_bomber": "Bombs ground targets, then rearms.", "multirole_gunship": "Hits ground and air at once.", "airship_artillery": "Flying artillery platform.",
             "aerial_carrier": "Launches aircraft.", "melee_damage": "Close-quarters bruiser.", "transport": "Carries troops to the front."}

BOSSES = [
    (10, "Mine Maw", "Burrowing ground monster", 1),
    (20, "The Bellringer", "Undead summoner using terrifying bell attacks", 1),
    (30, "Ossuary Matron", "Necromantic support boss with periodic aerial escorts", 1),
    (40, "Blightroot Behemoth", "Massive corrupted ground monster", 2),
    (50, "Plague Regent", "Elite plague commander", 2),
    (60, "Gravewing Matriarch", "Major flying undead boss", 2),
    (70, "Bone Wyrm", "Flying and burrowing monster", 3),
    (80, "The Hollow Admiral", "Commander of an undead aerial formation", 3),
    (90, "Dread Sky Tyrant", "Colossal aerial boss", 3),
    (100, "The Fallen Titan", "Corrupted colossal dwarven mech", 4),
    (110, "Ashen Forge Tyrant", "Undead industrial warlord", 4),
    (120, "Corpse Colossus", "Enormous ground siege boss", 4),
    (130, "The Hollow King", "Elite undead ruler and summoner", 5),
    (140, "Gravewing Sovereign", "Massive airborne undead creature", 5),
    (150, "The Rift Lich", "Final boss commanding a simultaneous ground and air assault", 5),
]
MINE_MAW = dict(cls="boss", domain="ground", role="boss_burrower", hp=6200, armor="hulk", speed=30, radius=44, bounty=200, threat=40,
    behavior="boss_mine_maw", art="mine_maw", blocks=True, frontline=True,
    weapons=[W(id="maw_bite", range=74, damage=70, dtype="melee", reload=1.7, targets="ground", priority="armored", proj="melee", splash=40, mount=[-60, -40], windup=0.6)],
    boss=dict(surface_time=9.0, burrow_telegraph=1.5, underground_max=6.0, underground_speed=95, erupt_telegraph=1.7,
              erupt_damage=125, erupt_radius=95, exposed_time=5.0, exposed_mult=1.5, enrage_below=0.35,
              support=dict(interval=19.0, cap=10, waves=[["zombie_miner", 2], ["grave_crawler", 2]], erupt_spawn=["rotter", 2]),
              seals_citadel=True),
    desc="A colossal burrowing maw that swallowed Deepvein Mine. It tunnels beneath your army and erupts under the densest formation.",
    counter="Watch for the cracking ground and spread out. Pound it while it is exposed after erupting. Scout Gyros reveal its tunnel; aircraft are safe from eruptions. Its death breaks the citadel's seal.")

# --------------------------------------------------------------------------------------
# STAGES
# --------------------------------------------------------------------------------------
ACTS = {
    1: ("Siege of the Mountain Holds", ["mountain_gate", "mountain_pass", "mine_entrance", "mine_deep", "ridge", "ruined_outpost", "foundry_outpost", "high_ridge", "mine_flooded"], "T0-T1"),
    2: ("The Blighted Frontier", ["dead_forest", "plague_marsh", "ruined_road", "corrupted_mine"], "T2"),
    3: ("War for the Skies", ["open_plains", "broken_ridge", "airborne_ruins", "shattered_fort"], "T3"),
    4: ("The Fallen Foundries", ["industrial_city", "destroyed_forge", "infested_factory", "mech_graveyard"], "T4"),
    5: ("The Black Rift", ["necro_waste", "rift_sky", "ruined_citadel", "realm_gate"], "T5"),
}
ACT_THEMES = {
    1: ["horde_intro", "skeletal_vanguard", "air_harassment", "tunnelers", "shield_wall", "necromancy", "armor_and_acid", "monster_breakthrough", "air_raid"],
    2: ["plague_tide", "marsh_ambush", "early_armor_duel", "bomber_escort", "corruption_spread", "spire_belt"],
    3: ["sky_superiority", "gunship_hunt", "flak_belt", "air_ground_pincer", "wyvern_flights", "convoy_defense"],
    4: ["corrupted_machines", "factory_siege", "carrier_war", "super_heavy_push", "foundry_hazards", "combined_assault"],
    5: ["rift_storm", "colossus_march", "fortress_sky", "endless_dead", "twin_front_siege", "final_gauntlet"],
}

R = lambda e, start, interval, group=1, mn=None, ramp=0.97, until=-1: dict(enemy=e, start=start, interval=interval, group=group, interval_min=mn if mn else interval * 0.6, ramp=ramp, until=until)
E = lambda t, *spawns: dict(t=t, spawn=[list(s) for s in spawns])
T = lambda hp, *spawns: dict(hp_below=hp, spawn=[list(s) for s in spawns])

AUTHORED = [
    dict(name="The Gatepass", env="mountain_gate", theme="horde_intro", base_hp=1700, start_gold=160,
         tracks=[R("rotter", 3, 7, 2, 4.2), R("carrion_bat", 22, 20, 2, 13), R("rotter", 70, 14, 3, 9)],
         events=[E(55, ("rotter", 5)), E(95, ("carrion_bat", 3), ("rotter", 4))],
         triggers=[T(0.5, ("rotter", 6), ("carrion_bat", 3))], structures=[],
         rewards=dict(sparks=40, unlock=["grenadier"]), tag="Rotters climb the gate road while carrion bats circle overhead."),
    dict(name="Cinder Steps", env="mountain_pass", theme="skeletal_vanguard", base_hp=2100, start_gold=160,
         tracks=[R("rotter", 3, 6.5, 2, 4), R("ossuary_skeleton", 14, 12, 1, 7), R("carrion_bat", 28, 19, 3, 12)],
         events=[E(70, ("ossuary_skeleton", 4)), E(120, ("ossuary_skeleton", 3), ("rotter", 5))],
         triggers=[T(0.55, ("ossuary_skeleton", 3), ("rotter", 4)), T(0.25, ("carrion_bat", 4))], structures=[],
         rewards=dict(sparks=45, unlock=["blunderbussier"]), tag="Bone soldiers march down the cinder stairs."),
    dict(name="Lantern Hollow", env="mine_entrance", theme="air_harassment", base_hp=2400, start_gold=170,
         tracks=[R("rotter", 3, 7, 2, 4.5), R("plague_runner", 18, 15, 2, 9), R("bone_archer", 30, 18, 1, 11), R("plague_shrieker", 45, 36, 1, 22), R("grave_crawler", 60, 21, 2, 13)],
         events=[E(100, ("plague_runner", 4), ("carrion_bat", 3))],
         triggers=[T(0.5, ("plague_shrieker", 2), ("bone_archer", 2), ("rotter", 4))], structures=[],
         rewards=dict(sparks=50, unlock=["scout_gyro"]), tag="Runners and shriekers pour out of the old lantern mine."),
    dict(name="Deepvein Shafts", env="mine_deep", theme="tunnelers", base_hp=2600, start_gold=170, hazard=dict(kind="rockfall", interval=17, damage=40, radius=55),
         tracks=[R("rotter", 3, 7, 2, 4.5), R("zombie_miner", 12, 13, 2, 8), R("grave_crawler", 35, 20, 2, 12), R("carrion_bat", 40, 22, 3, 14)],
         events=[E(85, ("zombie_miner", 5))],
         triggers=[T(0.5, ("zombie_miner", 4), ("ossuary_skeleton", 3))], structures=[],
         rewards=dict(sparks=55, unlock=["miner_rig"]), tag="Dead miners tunnel beneath the line. Loose rock falls from the shaft roof."),
    dict(name="Bonefield Ridge", env="ridge", theme="shield_wall", base_hp=2900, start_gold=180,
         tracks=[R("bone_shieldbearer", 8, 16, 1, 10), R("bone_archer", 14, 12, 2, 8), R("ossuary_skeleton", 4, 9, 2, 6), R("plague_shrieker", 50, 30, 1, 20)],
         events=[E(90, ("bone_shieldbearer", 2), ("bone_archer", 3))],
         triggers=[T(0.5, ("bone_shieldbearer", 2), ("ossuary_skeleton", 4))], structures=[dict(enemy="bone_spire", x=2240)],
         rewards=dict(sparks=60, unlock=["organ_gun"]), tag="A wall of coffin-lid shields screens archers on the ridge."),
    dict(name="Hollowbell Chapel", env="ruined_outpost", theme="necromancy", base_hp=3000, start_gold=180,
         tracks=[R("rotter", 2, 5, 3, 3.4), R("necromancer", 25, 40, 1, 30), R("carrion_bat", 20, 17, 3, 11), R("plague_runner", 45, 18, 2, 11)],
         events=[E(110, ("necromancer", 1), ("rotter", 6))],
         triggers=[T(0.5, ("necromancer", 1), ("rotter", 8))], structures=[],
         rewards=dict(sparks=60, unlock=["brasshound_armored_car"]), tag="The chapel bell is silent; its priests now raise the fallen."),
    dict(name="Smelter's Rest", env="foundry_outpost", theme="armor_and_acid", base_hp=3200, start_gold=190,
         tracks=[R("ossuary_skeleton", 3, 8, 2, 5.5), R("rot_spitter", 20, 16, 1, 10), R("grave_knight", 40, 32, 1, 22), R("plague_shrieker", 35, 28, 1, 18)],
         events=[E(100, ("grave_knight", 1), ("rot_spitter", 2))],
         triggers=[T(0.5, ("grave_knight", 2), ("rot_spitter", 2))], structures=[dict(enemy="bone_spire", x=2260)],
         rewards=dict(sparks=65, unlock=["field_mechanic"]), tag="Armored grave knights escort acid-spitting corpses through the old smelter."),
    dict(name="The Rotting Gate", env="mountain_gate", theme="monster_breakthrough", base_hp=3400, start_gold=200,
         tracks=[R("rotter", 2, 5, 3, 3.5), R("plague_runner", 20, 14, 2, 9), R("bone_archer", 25, 15, 2, 10), R("flesh_hulk", 50, 60, 1, 45), R("carrion_bat", 30, 20, 2, 13)],
         events=[E(140, ("flesh_hulk", 1), ("rotter", 6))],
         triggers=[T(0.5, ("plague_runner", 4), ("bone_archer", 3))], structures=[],
         rewards=dict(sparks=70, unlock=[]), tag="Something enormous is being stitched together beyond the gate."),
    dict(name="Skyhook Crag", env="high_ridge", theme="air_raid", base_hp=3300, start_gold=200, hazard=dict(kind="gale", interval=24, duration=7, strength=45),
         tracks=[R("carrion_bat", 5, 10, 3, 6.5), R("plague_shrieker", 18, 18, 1, 11), R("rotter", 3, 7, 2, 4.5), R("ossuary_skeleton", 25, 14, 1, 9)],
         events=[E(60, ("plague_shrieker", 3), ("carrion_bat", 5)), E(130, ("plague_shrieker", 3), ("carrion_bat", 6))],
         triggers=[T(0.5, ("plague_shrieker", 3), ("carrion_bat", 4))], structures=[dict(enemy="bone_spire", x=2200), dict(enemy="bone_spire", x=2330)],
         rewards=dict(sparks=75, unlock=[]), tag="The crag's updrafts carry flocks of rotting wings. Gusts buffet aircraft."),
    dict(name="Maw of Deepvein", env="mine_deep", theme="boss_mine_maw", base_hp=3600, start_gold=230, boss=dict(id="mine_maw", t=14), hazard=dict(kind="rockfall", interval=21, damage=40, radius=55),
         tracks=[R("rotter", 4, 8, 2, 5.5), R("grave_crawler", 30, 24, 2, 15), R("ossuary_skeleton", 40, 18, 1, 12), R("carrion_bat", 45, 34, 2, 26)],
         events=[], triggers=[T(0.4, ("zombie_miner", 3), ("ossuary_skeleton", 3))], structures=[],
         rewards=dict(sparks=140, unlock=[]), tag="The mine's deepest gallery collapses into a living throat."),
    dict(name="Ashen Switchback", env="mountain_pass", theme="combined_pressure", base_hp=3700, start_gold=210,
         tracks=[R("bone_shieldbearer", 10, 18, 1, 12), R("grave_knight", 30, 30, 1, 20), R("necromancer", 40, 45, 1, 34), R("bone_archer", 12, 12, 2, 8), R("rotter", 2, 6, 2, 4), R("carrion_bat", 25, 18, 3, 12)],
         events=[E(120, ("grave_knight", 2), ("bone_archer", 3)), E(170, ("bone_golem", 1))],
         triggers=[T(0.5, ("necromancer", 1), ("bone_shieldbearer", 2))], structures=[],
         rewards=dict(sparks=80, unlock=[]), tag="Knights, shields and a necromancer hold the switchback road."),
    dict(name="Gallows Bridge", env="ruined_outpost", theme="chokepoint", base_hp=3800, start_gold=210, hazard=dict(kind="rockfall", interval=15, damage=35, radius=50),
         tracks=[R("bone_shieldbearer", 6, 15, 1, 10), R("rot_spitter", 15, 13, 1, 8), R("plague_shrieker", 25, 22, 1, 14), R("ossuary_skeleton", 3, 8, 2, 5.5), R("flesh_hulk", 75, 55, 1, 42)],
         events=[E(150, ("flesh_hulk", 1), ("rot_spitter", 3)), E(200, ("plague_beast", 1))],
         triggers=[T(0.5, ("plague_shrieker", 3), ("rot_spitter", 2))], structures=[dict(enemy="bone_spire", x=2250)],
         rewards=dict(sparks=85, unlock=[]), tag="A crumbling bridge funnels the dead into a killing ground — for both sides."),
    dict(name="Blackwater Sump", env="mine_flooded", theme="swarm_and_summon", base_hp=3900, start_gold=220,
         tracks=[R("zombie_miner", 8, 11, 2, 7), R("plague_runner", 12, 11, 2, 7), R("grave_crawler", 20, 14, 3, 9), R("necromancer", 30, 38, 1, 26), R("rotter", 2, 5, 3, 3.2), R("carrion_bat", 45, 28, 2, 18)],
         events=[E(90, ("necromancer", 1), ("zombie_miner", 4)), E(160, ("plague_runner", 8)), E(210, ("carrion_bull", 1))],
         triggers=[T(0.5, ("necromancer", 1), ("grave_crawler", 6))], structures=[],
         rewards=dict(sparks=90, unlock=[]), tag="Flooded tunnels spill crawlers and runners from every side."),
    dict(name="Stormvent Peak", env="high_ridge", theme="air_superiority", base_hp=3800, start_gold=240, max_alive=46, hazard=dict(kind="gale", interval=20, duration=8, strength=55),
         tracks=[R("plague_shrieker", 10, 14, 1, 9.5), R("carrion_bat", 4, 10, 3, 7), R("grave_knight", 35, 32, 1, 24), R("ossuary_skeleton", 3, 8, 2, 6), R("bone_archer", 15, 15, 1, 10)],
         events=[E(80, ("plague_shrieker", 4)), E(150, ("plague_shrieker", 4), ("grave_knight", 2))],
         triggers=[T(0.5, ("plague_shrieker", 3), ("carrion_bat", 6))], structures=[dict(enemy="bone_spire", x=2060)],
         rewards=dict(sparks=95, unlock=[]), tag="Whoever holds the sky above the vents holds the peak."),
    dict(name="Breach of Stonehelm", env="mountain_gate", theme="act_i_finale", base_hp=4400, start_gold=250,
         tracks=[R("rotter", 2, 5, 3, 3.2), R("bone_shieldbearer", 12, 17, 1, 11), R("bone_archer", 14, 13, 2, 9), R("necromancer", 35, 42, 1, 30), R("flesh_hulk", 60, 55, 1, 40), R("plague_shrieker", 20, 20, 1, 13), R("carrion_bat", 10, 15, 3, 10), R("grave_knight", 45, 30, 1, 22), R("rot_spitter", 25, 18, 1, 12)],
         events=[E(120, ("flesh_hulk", 1), ("grave_knight", 2), ("plague_shrieker", 3)), E(230, ("carrion_bull", 1), ("bone_golem", 1))],
         triggers=[T(0.6, ("grave_knight", 2), ("carrion_bat", 5)), T(0.3, ("flesh_hulk", 1), ("necromancer", 1), ("plague_shrieker", 3))],
         structures=[dict(enemy="bone_spire", x=2200), dict(enemy="bone_spire", x=2340)],
         rewards=dict(sparks=120, unlock=[], open_tier=2), tag="The dead throw everything at Stonehelm's outer gate."),
]

PLANNED_NAMES = {
    1: ["Cragwatch", "Old Bellows Road", "Tallowmere", "Blackpick Galleries", "Frostfang Pass", "The Coal Stair", "Hammerfall Vale", "Rustgate", "Kettle Rock", "Grimvent", "Emberdeep", "Stonehelm Keep", "The Long Shaft", "Wardens' Ridge", "Ossuary Hall"],
}


# M005: one challenge objective per Act I stage (retrofit; Act II carries its own in act2_data)
ACT1_CHALLENGES = [
    ch("base_above", frac=0.75), ch("max_losses", n=12), ch("no_air_losses"), ch("time_under", seconds=420), ch("max_types", n=5),
    ch("base_above", frac=0.7), ch("max_losses", n=16), ch("time_under", seconds=480), ch("no_air_losses"), ch("kill_boss_by", seconds=300),
    ch("max_losses", n=20), ch("base_above", frac=0.7), ch("time_under", seconds=540), ch("kill_structures"), ch("max_losses", n=24),
    ch("kill_structures"), ch("max_types", n=6), ch("base_above", frac=0.7), ch("max_losses", n=22), ch("kill_boss_by", seconds=360),
    ch("time_under", seconds=540), ch("kill_structures"), ch("max_types", n=6), ch("no_air_losses"), ch("base_above", frac=0.65),
    ch("max_losses", n=24), ch("kill_structures"), ch("time_under", seconds=600), ch("max_types", n=7), ch("kill_boss_by", seconds=420),
]
assert len(ACT1_CHALLENGES) == 30

# M005: Act II bosses become encounters - a telegraphed change of behaviour at 50 % HP
BOSS_PHASES = {
    "blightroot_behemoth": dict(at=0.5, kind="root_eruption", interval=20.0, count=3, damage=90, radius=60, delay=1.6, slow=0.5,
                                alert="Roots tear up the ground under your guns!"),
    "plague_regent": dict(at=0.5, kind="court_heralds", spawn=[["plague_herald", 2]], respawn=60.0, miasma_boost=1.5,
                          alert="The Court summons its heralds — the miasma thickens!"),
    # M006: Act III air bosses
    "bone_wyrm": dict(at=0.5, kind="wyrm_dive", interval=22.0, under=2.6, exposed=6.0, damage=120, radius=95,
                      alert="The Wyrm dives into the chasm — watch the ground!"),
    "hollow_admiral": dict(at=0.5, kind="escort_shield", spawn=[["infected_airbarge", 2]], alert="Escort barges close in — the Admiral is shielded until one falls!"),
    "dread_sky_tyrant": dict(at=0.5, kind="storm_tyrant", storm_boost=1.8, air_bias=0.7, land_at=0.25, land_time=8.0,
                             alert="The storm answers its Tyrant — lightning hunts your aircraft!",
                             land_alert="The Tyrant lands to breathe on your line — hit it from the ground!"),
    # M007: Act IV foundry bosses
    "fallen_titan": dict(at=0.5, kind="titan_reclaim", interval=18.0, exposed=8.0, exposed_mult=1.25, escort="cursed_ironclad",
                         alert="The Titan tears a wreck from the ground — its plates fall away from the core!"),
    "ashen_forge_tyrant": dict(at=0.5, kind="vent_sequence", interval=16.0, step=0.55, warn=1.0, damage=110, radius=46,
                               vents=[2140, 1960, 1780, 1600, 1420, 1240, 1060, 880],
                               alert="The furnace answers its Tyrant — the vents fire in sequence!"),
    "corpse_colossus": dict(at=0.5, kind="corpse_throw", interval=11.0, damage=260, warn=1.6, machine_at=0.25,
                            machines=[["gravegun_tank", 1], ["risen_copperback", 1]],
                            alert="The Colossus hurls the dead at your stronghold!",
                            machine_alert="The Colossus disgorges a corrupted war machine!"),
    # M008: Act V bosses
    "hollow_king": dict(at=0.5, kind="crown_elite", elites=["ossuary_champion", "grave_knight", "dread_executioner", "riftbound_legionary"],
                        summon="ossuary_champion", recrown=20.0, king_dr=0.5, aura_dr=0.25, aura_r=200.0,
                        alert="The Hollow King crowns a champion — kill the crowned one to break his ward!",
                        break_alert="The crowned champion falls — the King's ward is broken!"),
    "gravewing_sovereign": dict(at=0.5, kind="storm_eye", gale_interval=13.0, gale_time=4.5, gale_push=95.0, gale_dps=9.0,
                                pull_at=0.25, pull_interval=11.0, pull_time=3.0, pull_speed=85.0, pull_dps=14.0,
                                alert="The storm eye closes — gales sweep the sky!",
                                pull_alert="The Sovereign drags your aircraft into her wings!"),
    "rift_lich": dict(at=0.66, kind="rift_ascend", rise_time=2.4, air_y=130.0, army_interval=18.0,
                      army=[["riftbound_legionary", 2], ["black_rot_infantry", 3], ["grave_knight", 1]], army_cap=14,
                      return_at=0.33, storm_boost=1.8, legion_cd=0.6,
                      alert="The Rift Lich rises into the rift — its legion storms your stronghold!",
                      return_alert="The Lich returns with the rift's full storm — win both fronts!"),
    "gravewing_matriarch": dict(at=0.5, kind="perch", perch_time=8.0, interval=26.0, nest_x=2250,
                                wake=[["blight_bat", 5], ["skeletal_vulture", 2]], alert="The Matriarch lands on her nest — hit her from the ground!"),
}
BOSS_EXTRAS = {
    # dead wood burns: flame troopers and flamebelchers are the intended counter
    "blightroot_behemoth": dict(weak={"fire": 1.3}, fixed_hp=True, hp=7500, arm=0.15, weapon_damage={"behemoth_roots": 0.5, "thorn_storm": 0.4}),
    # Act II bosses keep the HP their encounter is designed around (14,000 / 13,000 / 9,000) instead of
    # also taking the per-stage enemy HP multiplier (x1.6-1.9 by stage 040-060): difficulty comes from the phases
    "plague_regent": dict(fixed_hp=True, hp=5800, arm=0.15, speed=10, weapon_damage={"regent_scepter": 0.55, "plague_volley": 0.5},
                          ability_tune={"plague_court": {"cooldown": 26, "mods": {"fire": 1.25, "speed": 1.15, "dr": 0.9}},
                                        "pestilence": {"damage": 70, "pool": {"dps": 22, "dur": 6}}},
                          boss={"seals_citadel": True, "support": {"interval": 32, "cap": 6, "waves": [["plague_mauler", 1], ["pestilent_soldier", 2]]},
                                "enrage_below": 0.35, "enrage_mult": 1.35}),
    "gravewing_matriarch": dict(fixed_hp=True),
    # M006: Act III bosses ignore the per-stage HP multiplier too (x2.0-2.3 by stage 070-090); tuned with
    # the auto-commander and the scripted intended-counter runs (see the M006 report for before/after)
    "bone_wyrm": dict(fixed_hp=True, hp=9500, arm=0.2),
    "hollow_admiral": dict(fixed_hp=True, hp=9000, arm=0.25),
    "dread_sky_tyrant": dict(fixed_hp=True, hp=10000, arm=0.15, weapon_damage={"tyrant_breath": 0.5, "tyrant_tail": 0.6},
                             ability_tune={"sky_terror": {"damage": 90, "cooldown": 22}}),
    # M007: Act IV bosses ignore the per-stage HP multiplier (x2.4-2.8 by 100-120); tuned with the auto-commander
    # and the scripted intended-counter runs (prompt numbers 26,000 / 24,000 / 30,000; see the M007 report)
    "fallen_titan": dict(fixed_hp=True, hp=11000, arm=0.3, weapon_damage={"fallen_cannon": 0.65}),
    "ashen_forge_tyrant": dict(fixed_hp=True, hp=13000, arm=0.2, weapon_damage={"ashen_hammer": 0.7, "slag_volley": 0.6}),
    "corpse_colossus": dict(fixed_hp=True, hp=15000, arm=0.2, weapon_damage={"colossus_slam": 0.7},
                            ability_tune={"disgorge_horde": {"count": 5, "cap": 14}, "siege_slam": {"damage": 140}}),
    # M008: Act V bosses ignore the per-stage HP multiplier (x2.9-3.2 by 130-150); prompt numbers 28,000 / 30,000 /
    # 34,000 would be 80,000-110,000 in battle. Tuned with the auto-commander and the scripted counter runs (report).
    "hollow_king": dict(fixed_hp=True, hp=12000, arm=0.25, weapon_damage={"hollow_blade": 0.55, "king_bolt": 0.5},
                        ability_tune={"royal_summons": {"cap": 4, "count": 1, "cooldown": 20}, "kings_doom": {"damage": 120}},
                        boss={"seals_citadel": True, "support": {"interval": 34, "cap": 6, "waves": [["hollow_guard", 1], ["dread_executioner", 1]]},
                              "enrage_below": 0.3, "enrage_mult": 1.3}),
    "gravewing_sovereign": dict(fixed_hp=True, hp=26000, arm=0.25, weapon_damage={"sovereign_screech": 0.75},
                                ability_tune={"sovereign_brood": {"cap": 8}, "wing_storm": {"damage": 120}}),
    "rift_lich": dict(fixed_hp=True, hp=16000, arm=0.2, weapon_damage={"lich_rift_beam": 0.65, "lich_lightning": 0.65},
                      ability_tune={"rift_legion": {"cap": 8, "count": 3}, "annihilate": {"damage": 160}},
                      boss={"seals_citadel": True, "support": {"interval": 22, "cap": 10, "waves": [["riftbound_legionary", 1], ["rift_crow", 3]]},
                            "enrage_below": 0.3, "enrage_mult": 1.3}),
}

# M007 Heroic: stages whose default Heroic block the auto-commander could not win (stalemates and early collapses
# in the full Heroic sweep) get a gentler block: intervals x0.92, HP x1.05, a lighter extra event, and a barricade
# as the extra structure. Still harder than Normal; documented in the M007 report.
_GENTLE = lambda t=240: dict(interval_mult=0.92, hp_mult=1.05, structure=dict(enemy="cursed_barricade", x=2150))
HEROIC_GENTLE = {n: _GENTLE() for n in (14, 29, 38, 41, 50, 54, 57, 71, 85, 87, 89)}
# ... and four stages the commander still could not win even so (long Act I sieges, the Plague Regent, Banshee
# Reach) get a minimal block: intervals x0.95, HP x1.03, the barricade at the citadel gate
for _n in (14, 29, 50, 71):
    HEROIC_GENTLE[_n] = dict(interval_mult=0.95, hp_mult=1.03, structure=dict(enemy="cursed_barricade", x=2390))
for _n, _m in ((14, "grave_knight"), (29, "bone_shieldbearer"), (50, "pestilent_soldier")):
    HEROIC_GENTLE[_n]["event"] = dict(t=420, spawn=[[_m, 2]])
HEROIC_GENTLE[50]["ability_lead"] = 0.8
HEROIC_GENTLE[50]["hp_mult"] = 1.0
HEROIC_GENTLE[50]["structure"] = dict(enemy="cursed_barricade", x=2420)
# M008 full-campaign Heroic sweep: 051 (its normal waves were eased by the curve pass, and the Heroic block then
# timed out) and five Act V stages the commander lost on Heroic get the gentle block
for _n in (51, 126, 130, 146, 148, 149):
    HEROIC_GENTLE[_n] = _GENTLE()
# ... and three that still fell with it get the minimal block (like 014/029/071)
for _n in (126, 146, 148):
    HEROIC_GENTLE[_n] = dict(interval_mult=0.95, hp_mult=1.03, ability_lead=0.8, structure=dict(enemy="cursed_barricade", x=2390))
# 126 (black-rot masses under obelisk wards): Heroic mostly by design - waves only x0.95, a third
# rift obelisk planted further forward (the ward covers more of the line) and slightly tougher undead
HEROIC_GENTLE[126] = dict(interval_mult=0.95, hp_mult=1.03, ability_lead=0.6, structure=dict(enemy="rift_obelisk", x=1640),
                          event=dict(t=300, spawn=[["grave_knight", 2]]))

# M007 wreck reclamation: who salvages (dwarves) and who reclaims (undead corruptors)
SALVAGERS = {"salvage_crew", "armored_recovery_team", "heavy_recovery_crawler", "field_mechanic"}
RECLAIMERS = {"corpse_priest", "rot_channeler", "ash_hexer"}
# corrupted machines name the dwarven machine they were raised from (Compendium)
CORRUPT_ORIGIN = {"risen_copperback": "copperback_light_tank", "gravegun_tank": "thunderback_heavy_tank", "cursed_ironclad": "ironclad_walker",
                  "possessed_drillwalker": "drillwalker", "haunted_flying_machine": "dwarven_flying_machine", "infected_airbarge": "ironcloud"}


# M006 altitude bands --------------------------------------------------------------------
# Every flyer flies in a band (low / mid / high); every weapon that can shoot at the sky has a reach.
#   low   strafers, bats, gargoyles        hit by rifles and flak (anything that reaches the sky)
#   mid   most aircraft and flyers         hit by flak, AA and aircraft
#   high  airships, drakes, bosses         hit only by flak, AA artillery, interceptors and airships
# The band is derived from the unit class/behaviour unless the data sets `band`; a weapon's reach is
# derived from its type and its owner unless the data sets `reach`.
BAND_HIGH_IDS = {"bone_drake", "necrotic_sky_serpent"}
BAND_LOW_IDS = {"coalwing_strafing_craft"}
AA_ROLES = {"anti_air", "mobile_anti_air", "anti_aircraft_flyer"}


def apply_bands(uid, st, role="", domain=None, cls=None):
    if not st:
        return
    # roster entries keep domain/cls on the entry, not in stats: work on a view that has both
    view = dict(st)
    if domain is not None:
        view["domain"] = domain
    if cls is not None:
        view["cls"] = cls
    _apply_bands(uid, st, view, role)


# cruise altitude windows (screen y; smaller = higher) so the three bands read apart at a glance
ALT_WINDOWS = False   # M006 tried clamping cruise heights into band windows; it changed shipped Act I/II results (see report), so heights stay as authored
BAND_ALT = {"low": (295, 380), "mid": (238, 318), "high": (160, 232)}


def _apply_bands(uid, st, view, role):
    if view.get("domain", "ground") == "air":
        if "band" not in st:
            if view.get("cls") in ("airship", "boss") or uid in BAND_HIGH_IDS:
                st["band"] = "high"
            elif st.get("behavior") == "bat" or uid in BAND_LOW_IDS:
                st["band"] = "low"
            else:
                st["band"] = "mid"
        alt = st.get("altitude")
        lo, hi = BAND_ALT[st["band"]]
        if ALT_WINDOWS and alt and not st.get("altitude_fixed"):
            w = min(alt[1] - alt[0], hi - lo)
            a0 = min(max(alt[0], lo), hi - w)
            st["altitude"] = [a0, a0 + w]
    for w in st.get("weapons", []):
        tg = w.get("targets", "ground")
        if tg == "ground" or "reach" in w:
            continue
        if tg == "ground_lowair":
            w["reach"] = "low"
        elif w.get("dtype") == "flak" or view.get("cls") in ("airship", "boss"):
            w["reach"] = "high"
        elif view.get("domain") == "air":
            w["reach"] = "high" if (st.get("behavior") == "interceptor" or role in AA_ROLES or st.get("band") == "high") else "mid"
        else:
            w["reach"] = "high" if (tg == "air" or role in AA_ROLES or view.get("cls") in ("structure", "artillery")) else "mid"
    for v in st.get("variants", []):
        for w in v.get("weapons", []):
            if w.get("targets", "ground") != "ground" and "reach" not in w:
                w["reach"] = "low" if w["targets"] == "ground_lowair" else ("high" if w.get("dtype") == "flak" else "mid")


def threat(enemy_id):
    return IMPL_UNDEAD.get(enemy_id, {}).get("threat", 1)


def budget(st):
    b = 0.0
    for tr in st["tracks"]:
        avg_int = (tr["interval"] + tr["interval_min"]) / 2
        b += threat(tr["enemy"]) * tr["group"] * (60.0 / avg_int)
    # M008: rift tears spawn enemies too - their spills count toward the budget (as if no tear were ever closed)
    hz = st.get("hazard")
    for h in (hz if isinstance(hz, list) else [hz] if hz else []):
        if h.get("kind") == "rift_tears":
            pool = h.get("pool", [])
            avg = sum(threat(e) for e in pool) / max(1, len(pool))
            b += avg * float(h["spill"]) * 60.0 / float(h["interval"])
    return round(b, 1)


RESEARCH_COST = [0, 60, 110, 190, 300, 500]
# units no act ever hands out as a blueprint: research-only by design, kept cheap (master prompt §9)
CURVE_FIXES = []
RESEARCH_ONLY = {"ammunition_porter", "bayonet_fusilier", "boiler_tender", "grapeshot_culverin", "powder_loader", "salvage_crew",
                 "shotgun_breacher", "steamwheel_apc", "ironclad_walker", "shieldframe"}


def build():
    # ---------- dwarves ----------
    dwarves = []
    tier_counts = {}
    for code, key, title, ms, tiers in BRANCHES:
        for tier, names in sorted(tiers.items()):
            for i, name in enumerate(names):
                uid = sid(name)
                tier_counts[tier] = tier_counts.get(tier, 0) + 1
                e = dict(id=uid, name=name, faction="dwarf", branch=code, branch_key=key, branch_name=title, tier=tier,
                         cls=BRANCH_CLASS[code], domain="air" if code in "FG" else "ground",
                         role=provisional_role(name, code), role2=None, implemented=False, milestone=ms,
                         stats=None, unlock=dict(research=f"unit_{uid}"), assets=dict(art=None, icon=None, sfx=None))
                if uid in IMPL_DWARVES:
                    d = IMPL_DWARVES[uid]
                    e.update(implemented=True, milestone="M001", cls=d["cls"], domain=d["domain"], role=d["role"], role2=d.get("role2"))
                    st = {k: v for k, v in d.items() if k not in ("cls", "domain", "role", "role2", "desc")}
                    if uid in MECHS:
                        e["milestone"] = "M002"
                    e["stats"] = st
                    e["desc"] = d["desc"]
                    e["assets"] = dict(art=d["art"], icon=d["art"], sfx=d["weapons"][0]["proj"])
                elif uid in RD:
                    rt, d = RD[uid]
                    assert rt == tier, (uid, rt, tier)
                    e.update(implemented=True, milestone="M003", cls=d["cls"], domain=d["domain"])
                    st = {k: v for k, v in d.items() if k not in ("cls", "domain", "desc")}
                    e["stats"] = st
                    e["desc"] = d.get("desc") or ("%s %s" % (name + ":", ROLE_TEXT.get(e["role"], "")))
                    e["assets"] = dict(art=uid, icon=uid, sfx=d["weapons"][0]["proj"] if d["weapons"] else "melee")
                dwarves.append(e)
    assert len(dwarves) == 160, len(dwarves)
    assert tier_counts == {0: 6, 1: 22, 2: 32, 3: 38, 4: 35, 5: 27}, tier_counts
    ids = [d["id"] for d in dwarves]
    assert len(set(ids)) == 160
    for k in IMPL_DWARVES:
        assert k in ids, k

    # ---------- undead ----------
    undead = []
    for cat, title, names in UNDEAD:
        for name in names:
            uid = sid(name)
            e = dict(id=uid, name=name, faction="undead", category=cat, category_name=title, role=UNDEAD_ROLE[cat],
                     domain="air" if cat == "flying" or name in ("Haunted Flying Machine", "Infected Airbarge") else "ground",
                     implemented=False, milestone="M007" if cat != "corrupted" else "M007", stats=None, assets=dict(art=None))
            if uid in IMPL_UNDEAD:
                d = IMPL_UNDEAD[uid]
                for w in d["weapons"]:   # mounts are local-forward; art is mirrored by the node
                    w["mount"] = [abs(w["mount"][0]), w["mount"][1]]
                e.update(implemented=True, milestone="M002" if uid in GIANTS else ("M003" if uid in RU else "M001"), role=d.get("role", e["role"]), domain=d["domain"])
                e["stats"] = {k: v for k, v in d.items() if k not in ("role", "domain", "desc", "counter")}
                e["desc"] = d["desc"]; e["counter"] = d["counter"]
                e["assets"] = dict(art=d["art"])
            undead.append(e)
    assert len(undead) == 110, len(undead)
    for k in IMPL_UNDEAD:
        assert k in [u["id"] for u in undead], k

    # ---------- bosses ----------
    bosses = []
    for stage, name, ident, act in BOSSES:
        bid = sid(name.replace("The ", ""))
        b = dict(id=bid, name=name, stage=stage, act=act, identity=ident, implemented=False,
                 milestone="M001" if stage == 10 else ("M007" if stage <= 30 else f"M{7 + act:03d}"), stats=None)
        if bid == "mine_maw":
            for w in MINE_MAW["weapons"]:
                w["mount"] = [abs(w["mount"][0]), w["mount"][1]]
            b["implemented"] = True
            b["stats"] = {k: v for k, v in MINE_MAW.items() if k not in ("desc", "counter")}
            b["desc"] = MINE_MAW["desc"]; b["counter"] = MINE_MAW["counter"]
        elif bid in RB:
            d = RB[bid]
            b["implemented"] = True
            b["milestone"] = "M003"
            b["stats"] = {k: v for k, v in d.items() if k not in ("desc", "counter")}
            b["desc"] = d["desc"]; b["counter"] = d["counter"]
        if bid in BOSS_PHASES and b["stats"] is not None:
            b["stats"]["phase"] = BOSS_PHASES[bid]
            ex = dict(BOSS_EXTRAS.get(bid, {}))
            for wid, mult in ex.pop("weapon_damage", {}).items():   # M005 encounter tuning (auto-commander + scripted counter runs)
                for w in b["stats"]["weapons"]:
                    if w["id"] == wid:
                        w["damage"] = round(w["damage"] * mult, 1)
            for aid, tune in ex.pop("ability_tune", {}).items():
                for ab in b["stats"].get("abilities", []):
                    if ab["id"] == aid:
                        ab.update(tune)
            b["stats"].update(ex)
            b["milestone"] = "M005"
        bosses.append(b)

    # ---------- M006 altitude bands ----------
    for e in dwarves + undead:
        apply_bands(e["id"], e.get("stats"), e.get("role", ""), e.get("domain"), (e.get("stats") or {}).get("cls", e.get("cls")))
    for b in bosses:
        apply_bands(b["id"], b.get("stats"), "boss")
    # ---------- M007 wreck reclamation flags ----------
    for e in dwarves:
        if e["id"] in SALVAGERS and e.get("stats"):
            e["stats"]["salvages"] = True
    for e in undead:
        if e["id"] in RECLAIMERS and e.get("stats"):
            e["stats"]["reclaims"] = True
        if e["id"] in CORRUPT_ORIGIN:
            e["origin"] = CORRUPT_ORIGIN[e["id"]]

    # ---------- stages ----------
    stages = []
    boss_by_stage = {b["stage"]: b["id"] for b in bosses}
    for n in range(1, 151):
        act = (n - 1) // 30 + 1
        act_name, envs, tier = ACTS[act]
        local = (n - 1) % 30
        st = dict(id=f"s{n:03d}", index=n, act=act, act_name=act_name, tech_tier=tier,
                  requires=f"s{n - 1:03d}" if n > 1 else None,
                  boss=boss_by_stage.get(n), implemented=False,
                  milestone="M001" if n <= 15 else "M003" if n <= 30 else ("M002" if n <= 30 else f"M{min(8, 2 + act)}+".replace("M", "M00") if False else "M008+"),
                  env=envs[local % len(envs)], theme=ACT_THEMES[act][local % len(ACT_THEMES[act])],
                  victory="destroy_citadel")
        if n <= 150:
            a = AUTHORED[n - 1] if n <= 15 else (act1b_data.ACT1B[n - 16] if n <= 30 else (act2_data.ACT2[n - 31] if n <= 60 else (act3_data.ACT3[n - 61] if n <= 90 else (act4_data.ACT4[n - 91] if n <= 120 else act5_data.ACT5[n - 121]))))
            if 5 <= n <= 30:   # later Act I stages press harder (tuned with the auto-commander sims); Act II is authored at its own pace
                k = 1.0 - 0.012 * (n - 4) if n <= 15 else 0.97   # 016-030 are authored at their own pace
                for tr in a["tracks"]:
                    tr["interval"] = round(tr["interval"] * k, 2)
                    tr["interval_min"] = round(tr["interval_min"] * k, 2)
            st["enemy_hp_mult"] = round(1.0 + 0.015 * (n - 1), 3)
            st.update(implemented=True, name=a["name"], env=a["env"], theme=a["theme"], tagline=a["tag"],
                      enemy_base_hp=a["base_hp"], start_gold=a["start_gold"], gold_rate=9.0 + n * 0.15,
                      tracks=a["tracks"], events=a["events"], triggers=a["triggers"], structures=a["structures"],
                      hazard=a.get("hazard"), boss_spawn=a.get("boss"), rewards=a["rewards"], max_alive=a.get("max_alive", 34 + n * 2),
                      seed=1000 + n * 7919, challenge=a.get("challenge") or ACT1_CHALLENGES[n - 1])
            if n > 30:
                st["milestone"] = "M005" if n <= 60 else ("M006" if n <= 90 else ("M007" if n <= 120 else "M008"))
            if 90 < n <= 120:
                st["wrecks"] = True   # M007: destroyed dwarven machines leave wrecks the undead can reclaim
            if a.get("escort"):
                st["escort"] = a["escort"]
            if a.get("gold_bonus"):
                st["gold_rate"] = round(st["gold_rate"] + float(a["gold_bonus"]), 2)   # M008: holding battles pay more
            if a.get("boss"):
                st["victory"] = "kill_boss_then_destroy_citadel"
            st["difficulty_budget"] = budget(st)
            st["heroic"] = stage_kit.heroic_block(st, a.get("heroic") or HEROIC_GENTLE.get(n), {u["id"]: u for u in undead})
            st["enemy_roster"] = sorted({t["enemy"] for t in a["tracks"]} | {s[0] for ev in a["events"] for s in ev["spawn"]} |
                                         {s[0] for tg in a["triggers"] for s in tg["spawn"]} | {s["enemy"] for s in a["structures"]})
        else:
            if True:
                st["name"] = f"{act_name} — Stage {n:03d}"
                st["milestone"] = ["M003", "M005", "M006", "M008"][min(3, act - 2)] if act < 5 else "M008+"
            st["status"] = "planned"
        stages.append(st)
    assert len(stages) == 150
    # M008 full-campaign difficulty curve: no regular stage more than ~30 % above the mean budget of its two regular
    # neighbours (boss stages and act finales/exams are exempt). A spiking stage's track intervals are stretched
    # just enough to bring it to 1.3x (one pass over the original budgets; each change is printed and reported).
    base_b = [s.get("difficulty_budget", 0.0) for s in stages]
    for i, s in enumerate(stages):
        if not s.get("implemented") or s.get("boss") or i == 0 or any(k in str(s.get("theme", "")) for k in ("finale", "combined_assault", "final_gauntlet")):
            continue
        nb = [base_b[j] for j in (i - 1, i + 1) if 0 <= j < len(stages) and not stages[j].get("boss") and stages[j].get("implemented")]
        if not nb:
            continue
        target = 1.3 * sum(nb) / len(nb)
        if base_b[i] > target * 1.005:
            f = base_b[i] / target
            for tr in s["tracks"]:
                tr["interval"] = round(tr["interval"] * f, 2)
                tr["interval_min"] = round(tr["interval_min"] * f, 2)
            s["difficulty_budget"] = budget(s)
            if i >= 15:
                ov = (act1b_data.ACT1B + act2_data.ACT2 + act3_data.ACT3 + act4_data.ACT4 + act5_data.ACT5)[i - 15].get("heroic") or HEROIC_GENTLE.get(i + 1)
                s["heroic"] = stage_kit.heroic_block(s, ov, {u["id"]: u for u in undead})
            CURVE_FIXES.append((s["index"], round(base_b[i], 1), s["difficulty_budget"], round(f, 3)))
    # ... and a relief stage after every boss: the stage after a boss gets at most 90 % of the budget of the stage
    # before it (never below its act's band floor), by the same interval stretch
    for i, s in enumerate(stages):
        if i < 2 or not s.get("implemented") or s.get("boss") or not stages[i - 1].get("boss"):
            continue
        lo = stage_kit.ACT_BANDS.get(int(s["act"]), (0, 1e9))[0] * 1.02
        target = max(lo, 0.9 * stages[i - 2]["difficulty_budget"])
        before = s["difficulty_budget"]
        if before <= target * 1.005:
            continue
        f_total = 1.0
        for _ in range(4):   # the budget is not exactly linear in the intervals: converge in a few steps
            if s["difficulty_budget"] <= target * 1.005:
                break
            f = s["difficulty_budget"] / target
            f_total *= f
            for tr in s["tracks"]:
                tr["interval"] = round(tr["interval"] * f, 2)
                tr["interval_min"] = round(tr["interval_min"] * f, 2)
            s["difficulty_budget"] = budget(s)
        if i >= 15:
            ov = (act1b_data.ACT1B + act2_data.ACT2 + act3_data.ACT3 + act4_data.ACT4 + act5_data.ACT5)[i - 15].get("heroic") or HEROIC_GENTLE.get(i + 1)
            s["heroic"] = stage_kit.heroic_block(s, ov, {u["id"]: u for u in undead})
        CURVE_FIXES.append((s["index"], round(before, 1), s["difficulty_budget"], round(f_total, 3)))
    # a relief stage can leave the stage after it standing out: one more spike pass on the final budgets
    for i, s in enumerate(stages):
        if not s.get("implemented") or s.get("boss") or i == 0 or not stages[i - 1].get("implemented") or stages[i - 1].get("boss") \
                or not (i >= 2 and stages[i - 2].get("boss")) or any(k in str(s.get("theme", "")) for k in ("finale", "combined_assault", "final_gauntlet")):
            continue
        nb = [stages[j]["difficulty_budget"] for j in (i - 1, i + 1) if 0 <= j < len(stages) and not stages[j].get("boss") and stages[j].get("implemented")]
        target = 1.3 * sum(nb) / len(nb)
        before = s["difficulty_budget"]
        f_total = 1.0
        for _ in range(4):
            if s["difficulty_budget"] <= target * 1.005:
                break
            f = s["difficulty_budget"] / target
            f_total *= f
            for tr in s["tracks"]:
                tr["interval"] = round(tr["interval"] * f, 2)
                tr["interval_min"] = round(tr["interval_min"] * f, 2)
            s["difficulty_budget"] = budget(s)
        if f_total > 1.0:
            if i >= 15:
                ov = (act1b_data.ACT1B + act2_data.ACT2 + act3_data.ACT3 + act4_data.ACT4 + act5_data.ACT5)[i - 15].get("heroic") or HEROIC_GENTLE.get(i + 1)
                s["heroic"] = stage_kit.heroic_block(s, ov, {u["id"]: u for u in undead})
            CURVE_FIXES.append((s["index"], round(before, 1), s["difficulty_budget"], round(f_total, 3)))
    for cf in CURVE_FIXES:
        print("curve: s%03d budget %.1f -> %.1f (track intervals x%.3f)" % cf)
    # M005 stage validator (stage_kit): ids, until on ranged/artillery tracks, alive cap, budget band,
    # both fronts, boss spawn, hazard fields, challenge objective, tagline
    boss_domains = {b["id"]: {"domain": (b.get("stats") or {}).get("domain", "ground")} for b in bosses}
    errs = stage_kit.validate(stages, {u["id"]: u for u in undead}, boss_domains)
    for e in errs:
        print("INVALID", e)
    assert not errs, "%d stage validation problems" % len(errs)

    # ---------- tech ----------
    doctrines = [
        ("blackpowder_drill", "Blackpowder Drill", 1, "A", [], 30, "Standardized powder charges. Opens T1 infantry."),
        ("field_engineering", "Field Engineering", 1, "B", [], 30, "Wrenches, crates and stubbornness. Opens T1 engineers."),
        ("rifled_ordnance", "Rifled Ordnance", 1, "C", [], 35, "Rifled barrels for the artillery corps. Opens T1 artillery."),
        ("coal_engines", "Coal Engines", 1, "D", ["field_engineering"], 45, "Compact coal engines for wheeled vehicles."),
        ("mechanical_frames", "Mechanical Frames", 1, "E", ["field_engineering"], 50, "Articulated walking frames from mining rigs."),
        ("rotor_aeronautics", "Rotor Aeronautics", 1, "F", [], 40, "Reliable rotor hubs. Opens T1 aircraft."),
        ("age_of_steam", "Age of Steam", 2, None, ["blackpowder_drill", "coal_engines"], 80, "High-pressure boilers. Opens T2 across all branches."),
        ("armored_engineering", "Armored Engineering", 2, "D", ["coal_engines", "age_of_steam"], 70, "Riveted plate and tracked running gear."),
        ("heavy_gunnery", "Heavy Gunnery", 2, "C", ["rifled_ordnance", "age_of_steam"], 70, "Larger calibers and recoil systems."),
        ("boiler_walkers", "Boiler Walkers", 2, "E", ["mechanical_frames", "age_of_steam"], 75, "Boiler-driven heavy walking frames."),
        ("aerial_ordnance", "Aerial Ordnance", 2, "F", ["rotor_aeronautics", "age_of_steam"], 70, "Bomb racks and release gear for gyros."),
        ("anti_air_technology", "Anti-Air Technology", 2, "C", ["rifled_ordnance", "rotor_aeronautics"], 60, "Fused flak shells and skyward mounts."),
        ("lift_gas_envelopes", "Lift-Gas Envelopes", 2, "G", ["rotor_aeronautics", "age_of_steam"], 80, "Rigid gas cells for airships."),
        ("age_of_iron", "Age of Iron", 3, None, ["age_of_steam", "armored_engineering"], 120, "Industrial iron. Opens T3."),
        ("heavy_artillery", "Heavy Artillery", 3, "C", ["heavy_gunnery", "age_of_iron"], 100, "Siege-calibre ordnance."),
        ("aircraft_logistics", "Aircraft Logistics", 3, "F", ["aerial_ordnance", "age_of_iron"], 100, "Rearming and recovery of aircraft at scale."),
        ("airship_engineering", "Airship Engineering", 3, "G", ["lift_gas_envelopes", "age_of_iron"], 110, "Armored gondolas and broadside mounts."),
        ("age_of_war_machines", "Age of War Machines", 4, None, ["age_of_iron", "heavy_artillery"], 180, "Opens T4."),
        ("advanced_rune_engineering", "Advanced Rune Engineering", 4, "B", ["age_of_war_machines"], 160, "Runes etched into pressure systems."),
        ("age_of_colossi", "Age of Colossi", 5, None, ["age_of_war_machines", "advanced_rune_engineering"], 260, "Opens T5."),
        ("colossal_mechanical_frames", "Colossal Mechanical Frames", 5, "E", ["heavy_war_frames", "age_of_colossi"], 220, "Frames the size of keeps."),
        ("dedicated_war_frames", "Dedicated War Frames", 3, "E", ["boiler_walkers", "age_of_iron"], 110, "Purpose-built humanoid combat frames (Ironclad Walker pattern)."),
        ("heavy_war_frames", "Heavy War Frames", 4, "E", ["dedicated_war_frames", "age_of_war_machines"], 170, "Massive frames carrying siege-scale weapons."),
    ]
    tier_gate = {0: [], 1: [], 2: ["age_of_steam"], 3: ["age_of_iron"], 4: ["age_of_war_machines"], 5: ["age_of_colossi"]}
    branch_gate = {
        ("A", 1): ["blackpowder_drill"], ("B", 1): ["field_engineering"], ("C", 1): ["rifled_ordnance"],
        ("D", 1): ["coal_engines"], ("E", 1): ["mechanical_frames"], ("F", 1): ["rotor_aeronautics"],
        ("D", 2): ["armored_engineering"], ("C", 2): ["heavy_gunnery"], ("E", 2): ["boiler_walkers"],
        ("F", 2): ["aerial_ordnance"], ("G", 2): ["lift_gas_envelopes"], ("G", 3): ["airship_engineering"],
        ("C", 3): ["heavy_artillery"], ("F", 3): ["aircraft_logistics"],
        ("E", 3): ["dedicated_war_frames"], ("E", 4): ["heavy_war_frames"], ("E", 5): ["colossal_mechanical_frames"],
    }
    # Explicit cross-branch unlock examples from the master prompt
    cross = {
        "siege_sapper_tank": ["heavy_artillery", "armored_engineering"],
        "siegecrawler": ["heavy_artillery", "armored_engineering"],
        "worldhammer_siege_tank": ["heavy_artillery", "armored_engineering"],
        "skyguard_walker": ["mechanical_frames", "anti_air_technology"],
        "flak_colossus": ["boiler_walkers", "anti_air_technology"],
        "colossal_skybreaker": ["colossal_mechanical_frames", "anti_air_technology"],
        "ironwing_gunship": ["rotor_aeronautics", "heavy_gunnery"],
        "twin_flame_gunship": ["aerial_ordnance", "heavy_gunnery"],
        "skyhammer_assault_craft": ["aircraft_logistics", "heavy_artillery"],
        "ironhold_carrier": ["airship_engineering", "aircraft_logistics"],
        "grand_forge_carrier": ["airship_engineering", "aircraft_logistics"],
        "steamtread_heavy_carrier": ["armored_engineering", "aircraft_logistics"],
        "skyshield_aa_tank": ["armored_engineering", "anti_air_technology"],
        "mobile_flak_fortress": ["armored_engineering", "anti_air_technology"],
        "deepforge_titan": ["advanced_rune_engineering", "colossal_mechanical_frames"],
        "kings_anvil": ["advanced_rune_engineering", "colossal_mechanical_frames"],
        "embercore_titan": ["advanced_rune_engineering", "colossal_mechanical_frames"],
        "mountain_colossus": ["advanced_rune_engineering", "colossal_mechanical_frames"],
        "hammerfall_goliath": ["advanced_rune_engineering", "colossal_mechanical_frames"],
        "copperback_light_tank": ["armored_engineering", "coal_engines"],
        "bombard_gyro": ["aerial_ordnance"],
        "ironcloud": ["airship_engineering", "heavy_gunnery"],
        "brasshound_armored_car": ["coal_engines", "rifled_ordnance"],
    }
    unit_nodes = []
    prev_in_branch = {}
    for d in dwarves:
        t = d["tier"]
        prereq = []
        if t == 0:
            cost = 0
        else:
            prereq = list(dict.fromkeys(tier_gate[t] + branch_gate.get((d["branch"], t), []) + cross.get(d["id"], [])))
            # M008 full-campaign balance: blueprints hand out 144 of the 160 units, so at the old prices
            # (40/70/110/160/230) a player could research the whole roster by stage ~125 and Sparks stopped
            # mattering. New prices make Sparks alone buy every tier gate and early access to a chosen part of the
            # roster, but not all of it, by 150 (full-roster research comes from replays and Heroic payouts).
            # Research-only units (never a blueprint) keep their old, cheap prices.
            cost = RESEARCH_COST[t] if d["id"] not in RESEARCH_ONLY else [0, 40, 70, 110, 160, 230][t]
        unit_nodes.append(dict(id=f"unit_{d['id']}", unit=d["id"], tier=t, branch=d["branch"], requires=prereq,
                               cost=cost, implemented=d["implemented"], starting=(t == 0)))
    for uid, (tier, e) in MECHS.items():
        for v in e.get("variants", []):
            unit_nodes.append(dict(id=f"variant_{uid}_{v['id']}", variant_of=uid, variant=v["id"], name=v["name"], tier=tier, branch="E",
                                   requires=[f"unit_{uid}"] + v["requires"], cost=v["cost"], implemented=True, starting=False))
    gates = {"1": "s002", "2": "s015", "3": "s030", "4": "s075", "5": "s105"}
    tech = dict(
        tiers=[dict(tier=0, name="Foundations", count=6), dict(tier=1, name="Age of Blackpowder", count=22),
               dict(tier=2, name="Age of Steam", count=32), dict(tier=3, name="Age of Iron", count=38),
               dict(tier=4, name="Age of War Machines", count=35), dict(tier=5, name="Age of Colossi", count=27)],
        tier_stage_gate=gates,
        doctrines=[dict(id=i, name=n, tier=t, branch=b, requires=r, cost=c, desc=ds,
                        implemented=True) for i, n, t, b, r, c, ds in doctrines],
        units=unit_nodes,
    )
    did = {d[0] for d in doctrines}
    did |= {n["id"] for n in unit_nodes}
    for n in unit_nodes:
        for r in n["requires"]:
            assert r in did, (n["id"], r)
    for d in doctrines:
        for r in d[4]:
            assert r in did, (d[0], r)

    def dump(name, obj):
        with open(os.path.join(OUT, name), "w") as f:
            json.dump(obj, f, indent=1)
    aux = {k: {kk: vv for kk, vv in v.items() if kk != "kit"} for k, v in roster_data.AUX.items()}
    for k, v in aux.items():
        apply_bands(k, v)
    dump("dwarf_roster.json", dict(version=1, count=len(dwarves), units=dwarves, strongholds=STRONGHOLDS, aux=aux))
    kits = {}
    kits.update(RD_KITS); kits.update(RU_KITS); kits.update(RB_KITS)
    for k, v in roster_data.AUX.items():
        kits[k] = v["kit"]
    for b in bosses:
        assert b["implemented"], b["id"]
    dump("art_kit.json", kits)
    dump("undead_roster.json", dict(version=1, count=len(undead), units=undead))
    dump("bosses.json", dict(version=1, count=len(bosses), bosses=bosses))
    dump("stages.json", dict(version=1, count=len(stages), stages=stages))
    dump("tech.json", tech)
    print("dwarves", len(dwarves), "implemented", sum(d["implemented"] for d in dwarves))
    print("undead", len(undead), "implemented", sum(u["implemented"] for u in undead))
    print("bosses", len(bosses), "stages", len(stages), "implemented", sum(s["implemented"] for s in stages))
    for s in stages[:15]:
        print(s["id"], s["name"], s["difficulty_budget"], s["enemy_roster"])


if __name__ == "__main__":
    build()
