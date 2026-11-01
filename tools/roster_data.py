"""M003 — the rest of the roster.

Every remaining planned dwarf (116), regular undead (84) and boss (14) becomes a functional unit.
Units are built from archetype helpers (stats on the M001 scale, scaled by tech tier) and drawn
by the parametric art kit (scripts/art/art_kit.gd) from the `kit` parameters emitted here.
Stable IDs are the roster IDs; nothing is renamed or removed.

Tier power curve (HP / damage) and cost curve, relative to M001 T0–T1 units:
    tier   0     1     2     3     4     5
    power  1.0   1.1   1.45  2.0   2.7   3.6
    cost   1.0   1.1   1.4   1.9   2.6   3.4
"""

PW = {0: 1.0, 1: 1.1, 2: 1.45, 3: 2.0, 4: 2.7, 5: 3.6}
PC = {0: 1.0, 1: 1.1, 2: 1.4, 3: 1.9, 4: 2.6, 5: 3.4}
W = lambda **k: k

# ---------------------------------------------------------------- palette
BLUE, BLUE_D, RED, GREEN, GREY, BROWN, BLACK, ROYAL, COPPER, OCHRE = ("2f4f7a", "1f3554", "8e3a2e", "4a6a3a", "5d6670", "7a4b2a", "2e2a2a", "5a3f8a", "b8693a", "a07a2a")
IRON, STEEL, BRASS, GUNMETAL = "6f7680", "9aa3ad", "c9a24a", "50565c"


# ================================================================== weapons
def rifle(r=265, d=17, rl=1.7, **k):
    return W(id=k.pop("id", "rifle"), range=r, damage=d, dtype=k.pop("dtype", "pierce"), reload=rl, targets=k.pop("targets", "ground"), priority=k.pop("priority", "threat"), proj=k.pop("proj", "bullet"), mount=k.pop("mount", [24, -24]), **k)

def melee(d, rl=1.1, r=26, **k):
    return W(id=k.pop("id", "melee"), range=r, damage=d, dtype=k.pop("dtype", "melee"), reload=rl, targets=k.pop("targets", "ground"), priority=k.pop("priority", "nearest"), proj="melee", mount=k.pop("mount", [16, -22]), **k)

def cone(d, r=115, rl=2.0, n=5, **k):
    return W(id=k.pop("id", "cone"), range=r, damage=d, dtype=k.pop("dtype", "pierce"), reload=rl, targets=k.pop("targets", "ground_lowair"), priority="swarm", proj=k.pop("proj", "cone"), splash=n, mount=k.pop("mount", [22, -22]), **k)

def arc(d, r=240, rl=3.0, sp=46, **k):
    return W(id=k.pop("id", "arc"), range=r, min_range=k.pop("min_range", 60), damage=d, dtype=k.pop("dtype", "blast"), reload=rl, targets="ground", priority=k.pop("priority", "swarm"), proj=k.pop("proj", "arc"), splash=sp, mount=k.pop("mount", [10, -32]), **k)

def shell(d, r=420, rl=3.4, sp=30, **k):
    return W(id=k.pop("id", "cannon"), range=r, min_range=k.pop("min_range", 60), damage=d, dtype=k.pop("dtype", "blast"), reload=rl, targets="ground", priority=k.pop("priority", "armored"), proj="shell", splash=sp, ap=k.pop("ap", True), mount=k.pop("mount", [30, -18]), **k)

def flak(d, r=430, rl=1.05, sp=42, **k):
    return W(id=k.pop("id", "flak"), range=r, damage=d, dtype="flak", reload=rl, targets="air", priority="air", proj="flak", splash=sp, mount=k.pop("mount", [18, -30]), arc=[-178, 40], **k)

def mg(d, r=225, rl=0.25, **k):
    return W(id=k.pop("id", "mg"), range=r, damage=d, dtype="pierce", reload=rl, targets=k.pop("targets", "ground"), priority=k.pop("priority", "swarm"), proj="bullet", mount=k.pop("mount", [14, -30]), **k)

def zap(d, r=200, rl=1.6, chain=2, **k):
    return W(id=k.pop("id", "arc_lance"), range=r, damage=d, dtype="shock", reload=rl, targets=k.pop("targets", "ground"), priority=k.pop("priority", "armored"), proj="zap", chain=chain, chain_range=70, mount=k.pop("mount", [22, -24]), **k)

def bomb(d, sp=52, **k):
    return W(id=k.pop("id", "bombs"), range=60, damage=d, dtype=k.pop("dtype", "blast"), reload=0.35, targets="ground", priority="swarm", proj="bomb", splash=sp, mount=[0, 16], arc=[60, 120], **k)


def scale_w(ws, k):
    out = []
    for w in ws:
        w = dict(w)
        w["damage"] = round(w["damage"] * k, 1)
        out.append(w)
    return out


# ================================================================== dwarves
def D(uid, tier, cls, behavior, hp, armor, spd, gold, cd, weps, kit, steam=0, radius=None, h=52, desc="", **extra):
    k = PW[tier]
    e = dict(cls=cls, domain="air" if behavior in ("interceptor", "scout", "bomber", "gunship", "airship", "air_repair") else "ground",
             hp=round(hp * k), armor=armor, speed=spd, radius=radius or {"infantry": 11, "engineer": 11, "artillery": 16, "vehicle": 24, "aircraft": 18, "airship": 58}[cls],
             gold=int(round(gold * PC[tier] / 5.0) * 5), steam=steam, cooldown=round(cd * (1 + tier * 0.12), 1), behavior=behavior, art=uid,
             weapons=scale_w(weps, k), desc=desc, blocks=behavior not in ("artillery",) and cls not in ("aircraft", "airship"))
    if behavior in ("ranged", "repair") or cls == "artillery":
        e["hold_behind"] = True
    if cls == "artillery":
        e["blocks"] = False
        e.setdefault("rear_offset", 140)
    e.update(extra)
    kit = dict(kit)
    kit.setdefault("h", h)
    return uid, tier, e, kit


def inf(weapon, coat=BLUE, helmet="kettle", **k):
    p = dict(fam="inf", weapon=weapon, coat=coat, helmet=helmet)
    p.update(k)
    return p


DWARVES = [
    # ---------------- A · infantry
    D("hammer_guard", 1, "infantry", "melee", 230, "heavy", 32, 55, 5, [melee(16, 1.3, id="war_hammer", dtype="blast", splash=18)], inf("hammer", RED, "great", plate=1), taunt=True, frontline=True,
      desc="Guards with long-hafted war hammers. Hold the line and crack bone."),
    D("sapper", 1, "engineer", "ranged", 90, "light", 38, 60, 7, [arc(40, 170, 3.6, 40, id="satchel_charge", bonus={"structure": 2.2, "heavy": 1.3})], inf("satchel", BROWN, "miner", back="pack"),
      desc="Throws satchel charges that tear apart barricades, spires and armored dead."),
    D("longrifle_scout", 1, "infantry", "ranged", 60, "flesh", 40, 55, 5, [rifle(360, 26, 2.6, id="longrifle", priority="support")], inf("longrifle", GREEN, "cap"),
      desc="Long-barrelled rifle out-ranges every early undead shooter; picks off casters and archers."),
    D("bayonet_fusilier", 1, "infantry", "ranged", 110, "light", 38, 50, 4, [rifle(220, 15, 1.8, id="fusil"), melee(14, 1.0, id="bayonet")], inf("bayonet", BLUE, "kettle"),
      desc="Rifle at range, bayonet up close. Doesn't panic when the front arrives."),
    D("shotgun_breacher", 1, "infantry", "ranged", 120, "light", 38, 55, 5, [cone(15, 105, 1.9, 5, id="breaching_gun")], inf("shotgun", BROWN, "kettle"),
      desc="Short double-barrel scatterguns: five pellets of grapeshot into the horde (and low-diving bats)."),
    D("powder_loader", 1, "engineer", "melee", 85, "light", 40, 45, 8, [melee(6, 1.0, id="ramrod")], inf("crate", OCHRE, "cap", back="ammo"),
      aura=dict(radius=170, mods={"fire": 1.18}, dur=1.5, classes=["infantry", "artillery"]), hold_behind=True,
      desc="Runs powder and shot along the line: nearby infantry and artillery fire 18% faster."),
    D("flame_trooper", 2, "infantry", "ranged", 120, "light", 36, 70, 6, [cone(9, 95, 0.55, 4, id="flame_projector", dtype="fire", proj="flame", targets="ground")], inf("flamer", RED, "great", back="tank"),
      desc="Pressurised oil-flamer. Melts packed Rotters and fungal hosts. Very short reach."),
    D("steamgunner", 2, "infantry", "ranged", 95, "light", 36, 65, 5, [mg(5, 210, 0.22, id="steam_repeater", priority="threat", mount=[24, -24])], inf("steamgun", BLUE_D, "goggle_cap", back="boiler"),
      desc="Steam-driven repeater. Sprays bolts into anything in reach."),
    D("rune_cartridge_rifleman", 2, "infantry", "ranged", 80, "light", 38, 70, 5, [rifle(285, 22, 1.8, id="rune_rifle", ap=True, pen=0.15, bonus={"bone": 1.3, "bone_shield": 1.6})], inf("rune_rifle", ROYAL, "kettle", glow="7ad0ff"),
      desc="Rune-etched cartridges pierce shields and bone where normal shot rattles off."),
    D("trench_guard", 2, "infantry", "melee", 320, "heavy", 30, 75, 7, [melee(13, 1.2, id="trench_spade")], inf("spade", GREY, "great", shield="tower", plate=1), taunt=True, frontline=True, front_guard=0.25,
      desc="Tower shield and trench spade. Frontal shots splinter on the shield (-25%)."),
    D("repeater_fusilier", 2, "infantry", "ranged", 85, "light", 38, 70, 5, [rifle(250, 11, 2.2, id="repeater", burst=3, burst_gap=0.12)], inf("repeater", BLUE, "kettle"),
      desc="Lever repeaters fire three-round bursts."),
    D("bombardier", 2, "infantry", "ranged", 90, "light", 34, 80, 7, [arc(46, 270, 3.4, 54, id="bomb_launcher", min_range=70)], inf("mortar_tube", OCHRE, "miner", back="ammo"),
      desc="Shoulder bomb-launcher with a long arc. Breaks up shield walls and archers behind them."),
    D("armor_piercer", 2, "infantry", "ranged", 85, "light", 36, 80, 6, [rifle(300, 38, 3.0, id="ap_rifle", ap=True, pen=0.25, priority="armored", bonus={"heavy": 1.4, "hulk": 1.3, "machine": 1.3})], inf("heavy_rifle", GREEN, "goggle_cap"),
      desc="Heavy single-shot rifle built to punch armor, hulks and corrupted machines."),
    D("veteran_rifleman", 3, "infantry", "ranged", 85, "light", 40, 75, 5, [rifle(290, 18, 1.4, id="veteran_rifle", ap=True)], inf("rifle", BLUE_D, "kettle", plate=1, medal=True),
      desc="Old hands of the Holds: faster, longer, armor-piercing fire."),
    D("heavy_hammerer", 3, "infantry", "melee", 260, "heavy", 30, 90, 7, [melee(30, 1.8, id="great_hammer", dtype="blast", splash=30, windup=0.3, bonus={"bone": 1.4, "structure": 1.5})], inf("greathammer", GREY, "great", plate=2, scale=1.1), frontline=True,
      desc="Two-handed forge hammers that shatter skeletons by the rank."),
    D("skyguard_marksman", 3, "infantry", "ranged", 75, "light", 38, 85, 6, [rifle(380, 26, 1.6, id="sky_rifle", targets="air", priority="air", mount=[20, -30], arc=[-178, 10])], inf("aa_rifle", GREEN, "goggle_cap", aim_up=True),
      desc="Long rifles on swivel rests, trained on the sky. Infantry that finally hits flyers."),
    D("rolling_shield_trooper", 3, "infantry", "ranged", 300, "heavy", 30, 95, 8, [rifle(220, 15, 1.7, id="slit_rifle")], inf("rifle", GREY, "great", shield="rolling", plate=1), front_guard=0.4, taunt=True, frontline=True, hold_behind=False,
      desc="A wheeled steel mantlet with a firing slit: advances at the front, shots splinter off (-40%)."),
    D("incendiary_grenadier", 3, "infantry", "ranged", 90, "light", 36, 95, 7, [arc(30, 245, 3.2, 44, id="fire_grenade", dtype="fire")], inf("grenade", RED, "miner"),
      ability=dict(id="firebomb", name="Firebomb", kind="zone", steam=0, cooldown=14, windup=0.3, radius=55, dps=24, dur=5, offset=170, dtype="fire", look="fire"),
      desc="Fire grenades, and every few seconds a firebomb that leaves a burning patch."),
    D("mortar_spotter", 3, "infantry", "ranged", 80, "light", 38, 85, 7, [rifle(240, 10, 1.8, id="carbine")], inf("scope", GREEN, "cap", back="flag"),
      spotter=dict(range=280, art_range=1.15, art_dmg=1.1), desc="Signals for the guns: artillery shoots farther and harder while a spotter lives."),
    D("royal_iron_guard", 4, "infantry", "melee", 330, "heavy", 30, 120, 8, [melee(22, 1.2, id="royal_halberd", splash=20, r=34)], inf("halberd", ROYAL, "great", helm_col=BRASS, plate=2, scale=1.12, shield="tower"), taunt=True, frontline=True, front_guard=0.3,
      desc="The king's household guard in gilded plate. Halberd sweeps and a heavy shield."),
    D("thunder_rifleman", 4, "infantry", "ranged", 90, "light", 38, 120, 7, [zap(22, 260, 2.0, 2, id="thunder_rifle", targets="ground", priority="threat")], inf("thunder_rifle", BLUE_D, "goggle_cap", glow="9ad8ff"),
      desc="Capacitor rifles whose bolts arc to a second target."),
    D("furnace_assault_trooper", 4, "infantry", "ranged", 260, "heavy", 32, 130, 8, [cone(14, 105, 0.6, 5, id="furnace_flamer", dtype="fire", proj="flame", targets="ground")], inf("flamer", COPPER, "great", back="furnace", plate=2), frontline=True, hold_behind=False,
      desc="Armored stormtroopers with furnace-fed flamers. They walk into the horde."),
    D("runebreaker_infantry", 4, "infantry", "ranged", 110, "light", 36, 135, 8, [rifle(300, 70, 3.4, id="rune_lance", proj="shell", ap=True, pen=0.3, priority="armored", bonus={"hulk": 1.4, "heavy": 1.4, "mech": 1.3})], inf("lance", ROYAL, "kettle", glow="c08aff"),
      desc="Rune lances that crack hulks, giants and corrupted war machines."),
    D("heavy_gatling_dwarf", 4, "infantry", "ranged", 190, "heavy", 30, 130, 8, [mg(6, 230, 0.12, id="hand_gatling", priority="swarm", mount=[22, -22], spinup=0.6)], inf("gatling", GREY, "great", back="ammo", plate=1, scale=1.1),
      desc="A rotary gun carried by one very stubborn dwarf."),
    D("colossus_guard", 5, "infantry", "melee", 420, "heavy", 28, 170, 10, [melee(28, 1.4, id="colossus_maul", dtype="blast", splash=30)], inf("greathammer", GREY, "great", shield="bulwark", plate=2, scale=1.25), taunt=True, frontline=True, front_guard=0.35,
      desc="Walls of plate and shield. Nothing gets past a Colossus Guard."),
    D("arc_lance_gunner", 5, "infantry", "ranged", 120, "light", 36, 170, 9, [zap(30, 280, 1.8, 4, id="arc_lance", priority="swarm")], inf("thunder_rifle", BLUE_D, "goggle_cap", back="coil", glow="9ad8ff", scale=1.1),
      desc="Backpack coils feed a lance whose lightning jumps through four undead."),
    D("kingsguard_bulwark", 5, "infantry", "melee", 460, "heavy", 28, 180, 10, [melee(20, 1.2, id="bulwark_blade")], inf("sword", ROYAL, "great", helm_col=BRASS, shield="bulwark", plate=2, scale=1.25), taunt=True, frontline=True, front_guard=0.35,
      ability=dict(id="kings_ward", name="King's Ward", kind="ward", steam=0, cooldown=24, windup=0.4, radius=140, mult=0.5, dur=6),
      desc="Raises a rune ward that halves incoming projectile damage to everyone behind it."),
    # ---------------- B · engineers & fieldworks
    D("ammunition_porter", 1, "engineer", "melee", 85, "light", 42, 45, 8, [melee(5, 1.0, id="crowbar")], dict(fam="eng", tool="crate", coat=OCHRE, helmet="cap", cart="barrow"),
      aura=dict(radius=180, mods={"fire": 1.12}, dur=1.5, classes=["infantry", "artillery", "vehicle"]), hold_behind=True, desc="Barrows of shot and powder: +12% fire rate to nearby infantry, guns and vehicles."),
    D("boiler_tender", 1, "engineer", "repair", 85, "light", 40, 55, 8, [melee(5, 1.0, id="spanner")], dict(fam="eng", tool="wrench", coat=GREY, helmet="goggle_cap", back="boiler"),
      repair=dict(rate=14, range=140, pool=500, classes=["vehicle", "walker", "artillery"]), steam_gen=0.6, desc="Keeps boilers stoked: +0.6 Steam/s while alive, and patches machines."),
    D("salvage_crew", 1, "engineer", "repair", 90, "light", 40, 50, 8, [melee(6, 1.0, id="salvage_hook")], dict(fam="eng", tool="hook", coat=BROWN, helmet="miner", back="pack"),
      repair=dict(rate=12, range=140, pool=400, classes=["vehicle", "walker", "artillery"]), prospect=1.0, desc="Strips wrecks for parts: +1 Gold/s and light repairs."),
    D("repair_wagon", 2, "vehicle", "repair", 260, "machine", 34, 90, 10, [melee(6, 1.0, id="tow_hook")], dict(fam="eng", tool="wrench", coat=BROWN, helmet="cap", cart="wagon", h=56),
      repair=dict(rate=32, range=170, pool=1600, classes=["vehicle", "walker", "artillery", "stronghold"]), radius=20, desc="A rolling workshop with a big parts store."),
    D("steam_sapper", 2, "engineer", "ranged", 120, "light", 36, 80, 8, [arc(60, 190, 4.0, 46, id="steam_charge", bonus={"structure": 2.4, "heavy": 1.3, "machine": 1.4})], inf("satchel", GREY, "goggle_cap", back="boiler"),
      desc="Pressure charges that blow apart siege engines and corrupted machinery."),
    D("field_barricade_crew", 2, "engineer", "melee", 110, "light", 38, 70, 9, [melee(6, 1.0, id="mallet")], dict(fam="eng", tool="hammer", coat=BROWN, helmet="kettle", back="planks"),
      deploys=dict(unit="dwarf_barricade", interval=14, cap=2, ahead=40), hold_behind=True, desc="Raises timber-and-iron barricades in front of the line (max 2)."),
    D("mine_layer", 2, "engineer", "melee", 95, "light", 40, 75, 9, [melee(6, 1.0, id="trowel")], dict(fam="eng", tool="mine", coat=GREEN, helmet="miner", back="pack"),
      mines=dict(interval=9, dps=36, radius=50, dur=10, ahead=150, look="mine"), hold_behind=True, desc="Plants blast mines ahead of the line; anything walking over them burns."),
    D("spotter_balloon_crew", 2, "engineer", "melee", 100, "light", 32, 70, 9, [melee(5, 1.0, id="tether_knife")], dict(fam="eng", tool="scope", coat=OCHRE, helmet="cap", cart="balloon", h=110),
      spotter=dict(range=320, art_range=1.22, art_dmg=1.15), hold_behind=True, desc="A tethered observation balloon. Artillery gains range and damage."),
    D("armored_recovery_team", 3, "vehicle", "repair", 380, "machine", 32, 110, 11, [mg(4, 200, 0.3, id="recovery_mg")], dict(fam="eng", tool="wrench", coat=GREY, helmet="great", cart="crawler", h=60),
      repair=dict(rate=40, range=170, pool=2200, classes=["vehicle", "walker", "artillery"]), radius=22, desc="Armored crawler that drags machines back into the fight."),
    D("turret_engineer", 3, "engineer", "melee", 110, "light", 38, 100, 10, [melee(7, 1.0, id="welder")], dict(fam="eng", tool="welder", coat=BLUE_D, helmet="goggle_cap", back="pack"),
      deploys=dict(unit="dwarf_gun_turret", interval=16, cap=2, ahead=-20), hold_behind=True, desc="Builds rifle turrets behind the line (max 2)."),
    D("pressure_regulator", 3, "engineer", "melee", 110, "light", 38, 100, 10, [melee(6, 1.0, id="valve_key")], dict(fam="eng", tool="gauge", coat=GREY, helmet="goggle_cap", back="boiler"),
      steam_gen=1.0, aura=dict(radius=200, mods={"fire": 1.15, "speed": 1.1}, dur=1.5, classes=["vehicle", "walker"]), hold_behind=True,
      desc="+1 Steam/s; nearby machines fire 15% faster and move 10% faster."),
    D("runic_mechanic", 3, "engineer", "repair", 100, "light", 40, 100, 10, [melee(7, 1.0, id="rune_wrench")], dict(fam="eng", tool="rune", coat=ROYAL, helmet="kettle", glow="7ad0ff"),
      repair=dict(rate=24, range=160, pool=1400, classes=["vehicle", "walker", "artillery", "infantry", "engineer"]), desc="Rune-mending works on flesh and iron alike."),
    D("battlefield_surveyors", 3, "engineer", "melee", 90, "light", 40, 85, 9, [melee(5, 1.0, id="survey_staff")], dict(fam="eng", tool="scope", coat=GREEN, helmet="cap", back="tripod"),
      spotter=dict(range=300, art_range=1.25, art_dmg=1.1), hold_behind=True, desc="Range-finding instruments: artillery +25% range."),
    D("heavy_recovery_crawler", 4, "vehicle", "repair", 520, "machine", 28, 150, 13, [mg(5, 210, 0.3, id="crawler_mg")], dict(fam="eng", tool="crane", coat=GREY, helmet="great", cart="crawler", h=70),
      repair=dict(rate=60, range=190, pool=3200, classes=["vehicle", "walker", "artillery", "stronghold"]), radius=26, desc="Crane crawler that rebuilds heavy machines in the field."),
    D("mobile_forge_crew", 4, "vehicle", "repair", 420, "machine", 28, 160, 13, [melee(10, 1.0, id="forge_hammer")], dict(fam="eng", tool="hammer", coat=COPPER, helmet="great", cart="forge", h=64),
      repair=dict(rate=45, range=180, pool=2600, classes=["vehicle", "walker", "artillery"]), aura=dict(radius=180, mods={"dr": 0.9}, dur=1.5, classes=["vehicle", "walker"]), radius=24,
      desc="A forge on tracks: repairs, and reinforces nearby machines (-10% damage taken)."),
    D("counter_curse_technician", 4, "engineer", "melee", 110, "light", 38, 120, 10, [melee(7, 1.0, id="ward_rod")], dict(fam="eng", tool="rune", coat=ROYAL, helmet="goggle_cap", back="coil", glow="c08aff"),
      aura=dict(radius=220, mods={"dr": 0.92}, dur=1.5, cleanse=True), hold_behind=True, desc="Breaks hexes: allies nearby shrug off slows and stuns, and take 8% less damage."),
    D("automated_turret_crew", 4, "engineer", "melee", 120, "light", 38, 140, 11, [melee(7, 1.0, id="welder")], dict(fam="eng", tool="welder", coat=GREY, helmet="great", back="pack"),
      deploys=dict(unit="dwarf_gatling_turret", interval=16, cap=2, ahead=-10), hold_behind=True, desc="Deploys automated gatling turrets (max 2)."),
    D("master_fabricator_team", 5, "engineer", "repair", 140, "light", 38, 180, 12, [melee(8, 1.0, id="fabricator_arm")], dict(fam="eng", tool="crane", coat=COPPER, helmet="great", back="boiler", cart="wagon", h=60),
      repair=dict(rate=40, range=190, pool=3000, classes=["vehicle", "walker", "artillery", "stronghold"]), deploys=dict(unit="dwarf_gatling_turret", interval=22, cap=1, ahead=-10), radius=18,
      desc="Builds turrets and repairs anything with gears."),
    D("titan_maintenance_crew", 5, "engineer", "repair", 150, "light", 36, 170, 12, [melee(8, 1.0, id="titan_spanner")], dict(fam="eng", tool="crane", coat=GREY, helmet="great", back="boiler"),
      repair=dict(rate=70, range=210, pool=5000, classes=["walker", "vehicle"]), desc="Specialist crews for war frames: the fastest walker repairs in the Holds (still capped per machine)."),
    # ---------------- C · artillery & AA
    D("portable_mortar", 1, "artillery", "artillery", 120, "light", 30, 80, 8, [arc(36, 360, 3.6, 46, id="light_mortar", min_range=120)], dict(fam="gun", barrel="mortar", crew=1, coat=BROWN)),
    D("grapeshot_culverin", 1, "artillery", "artillery", 160, "light", 26, 85, 8, [cone(11, 160, 2.4, 6, id="grapeshot", targets="ground")], dict(fam="gun", barrel="culverin", crew=1, coat=RED), rear_offset=70),
    D("skyhook_rocket_rack", 1, "artillery", "artillery", 120, "light", 28, 85, 8, [W(id="sky_rockets", range=400, damage=16, dtype="flak", reload=2.6, targets="air", priority="air", proj="flak", splash=34, burst=3, burst_gap=0.15, mount=[16, -28], arc=[-178, 20])], dict(fam="gun", barrel="rocket_rack", crew=1, coat=GREEN, aim_up=True)),
    D("steam_mortar", 2, "artillery", "artillery", 170, "light", 26, 110, 10, [arc(44, 420, 3.4, 52, id="steam_mortar", min_range=130)], dict(fam="gun", barrel="mortar_big", crew=1, coat=GREY, boiler=True), steam=10),
    D("heavy_bombard", 2, "artillery", "artillery", 220, "light", 22, 130, 11, [shell(70, 470, 4.6, 46, id="bombard", priority="structure", bonus={"structure": 1.6})], dict(fam="gun", barrel="bombard", crew=2, coat=BROWN)),
    D("rocket_battery", 2, "artillery", "artillery", 160, "light", 26, 120, 10, [W(id="rocket_salvo", range=460, min_range=100, damage=22, dtype="blast", reload=5.0, targets="ground", priority="swarm", proj="arc", splash=36, burst=6, burst_gap=0.12, mount=[16, -26])], dict(fam="gun", barrel="rocket_rack", crew=1, coat=RED)),
    D("shrapnel_howitzer", 2, "artillery", "artillery", 200, "light", 24, 125, 11, [arc(40, 440, 3.6, 70, id="shrapnel_shell", min_range=120, proj="arc")], dict(fam="gun", barrel="howitzer", crew=2, coat=GREEN)),
    D("twin_flak_mount", 2, "artillery", "artillery", 160, "light", 26, 100, 9, [flak(15, 440, 0.9, 40, id="twin_flak_l"), flak(15, 440, 0.9, 40, id="twin_flak_r", mount=[10, -32])], dict(fam="gun", barrel="flak2", crew=1, coat=BLUE_D, aim_up=True), rear_offset=110),
    D("siege_howitzer", 3, "artillery", "artillery", 260, "light", 20, 160, 13, [arc(80, 520, 5.0, 64, id="siege_howitzer", min_range=160, ap=True)], dict(fam="gun", barrel="howitzer_big", crew=2, coat=GREY), steam=10),
    D("piston_cannon", 3, "artillery", "artillery", 280, "machine", 22, 170, 13, [shell(95, 480, 4.2, 40, id="piston_cannon", pen=0.25, bonus={"structure": 1.5})], dict(fam="gun", barrel="piston", crew=1, coat=COPPER, boiler=True), steam=15),
    D("counterbattery_mortar", 3, "artillery", "artillery", 220, "light", 24, 150, 12, [arc(60, 540, 4.0, 46, id="counter_mortar", min_range=140, priority="structure", bonus={"structure": 2.0})], dict(fam="gun", barrel="mortar_big", crew=2, coat=GREEN)),
    D("multi_barrel_flak", 3, "artillery", "artillery", 200, "light", 24, 150, 11, [flak(13, 470, 0.5, 38, id="quad_flak")], dict(fam="gun", barrel="flak4", crew=1, coat=BLUE_D, aim_up=True), rear_offset=110),
    D("heavy_skybreaker", 4, "artillery", "artillery", 280, "machine", 20, 200, 14, [flak(40, 520, 1.6, 54, id="skybreaker_gun")], dict(fam="gun", barrel="flak_heavy", crew=2, coat=GREY, aim_up=True), steam=15, rear_offset=120),
    D("rune_cannon", 4, "artillery", "artillery", 300, "machine", 20, 220, 15, [shell(85, 520, 3.8, 34, id="rune_cannon", dtype="shock", pen=0.3, chain=0)], dict(fam="gun", barrel="rune", crew=1, coat=ROYAL, glow="9ad8ff"), steam=20),
    D("thunder_rocket_battery", 4, "artillery", "artillery", 260, "light", 22, 210, 14, [W(id="thunder_rockets", range=520, min_range=120, damage=30, dtype="blast", reload=5.5, targets="ground", priority="swarm", proj="arc", splash=42, burst=8, burst_gap=0.1, mount=[16, -28])], dict(fam="gun", barrel="rocket_big", crew=2, coat=RED)),
    D("mountain_siege_cannon", 5, "artillery", "artillery", 420, "machine", 16, 300, 18, [shell(160, 620, 6.0, 70, id="mountain_gun", pen=0.35, priority="structure", bonus={"structure": 1.8}, windup=0.5)], dict(fam="gun", barrel="siege", crew=3, coat=GREY, h=70), steam=30, radius=24),
    D("celestial_flak_array", 5, "artillery", "artillery", 380, "machine", 18, 280, 16, [flak(26, 560, 0.45, 46, id="array_l"), flak(26, 560, 0.45, 46, id="array_r", mount=[8, -36])], dict(fam="gun", barrel="array", crew=2, coat=BLUE_D, aim_up=True, glow="9ad8ff", h=64), steam=25, radius=22, rear_offset=120),
    # ---------------- D · vehicles
    D("coalrunner_scout_tank", 1, "vehicle", "vehicle", 320, "machine", 66, 100, 10, [mg(5, 230, 0.26, id="scout_mg")], dict(fam="veh", hull="wheeled", len=46, ht=30, coat=GREEN, turrets=["mg"]), spotter=dict(range=240, art_range=1.1, art_dmg=1.05)),
    D("steamwheel_apc", 1, "vehicle", "vehicle", 480, "machine", 46, 120, 12, [mg(4, 210, 0.3, id="apc_mg")], dict(fam="veh", hull="wheeled", len=56, ht=36, coat=BROWN, turrets=["mg"], hatch=True),
      deploys=dict(unit="tunnel_militia", interval=12, cap=4, ahead=20), desc="Armored transport that keeps unloading Tunnel Militia at the front (up to 4)."),
    D("ironrunner_light_tank", 2, "vehicle", "vehicle", 560, "machine", 46, 170, 14, [shell(50, 330, 3.0, 22, id="light_gun", mount=[40, -36]), mg(4, 210, 0.3, id="hull_mg", mount=[34, -22])], dict(fam="veh", hull="tracked", len=60, ht=40, coat=GREEN, turrets=["cannon"]), steam=10),
    D("flamebelcher_medium_tank", 2, "vehicle", "vehicle", 700, "machine", 34, 200, 15, [cone(12, 120, 0.5, 5, id="flame_turret", dtype="fire", proj="flame", targets="ground", mount=[44, -34])], dict(fam="veh", hull="tracked", len=66, ht=44, coat=RED, turrets=["flame"]), steam=15),
    D("ironclad_medium_tank", 2, "vehicle", "vehicle", 760, "machine", 34, 210, 16, [shell(66, 350, 3.4, 26, id="medium_gun", mount=[46, -40]), mg(4, 210, 0.3, id="coax", mount=[40, -36])], dict(fam="veh", hull="tracked", len=68, ht=46, coat=GREY, turrets=["cannon"]), steam=15),
    D("skyshield_aa_tank", 2, "vehicle", "vehicle", 600, "machine", 36, 190, 15, [flak(14, 430, 0.6, 36, id="aa_twin", mount=[30, -46])], dict(fam="veh", hull="tracked", len=62, ht=42, coat=BLUE_D, turrets=["aa"]), steam=15, hold_behind=True, rear_offset=60),
    D("thunderback_heavy_tank", 3, "vehicle", "vehicle", 950, "machine", 28, 280, 18, [shell(90, 380, 3.8, 30, id="heavy_gun", mount=[52, -46]), mg(5, 220, 0.28, id="coax", mount=[44, -42])], dict(fam="veh", hull="tracked", len=78, ht=52, coat=GREY, turrets=["heavy"]), steam=20, radius=30),
    D("bastion_heavy_tank", 3, "vehicle", "vehicle", 1250, "machine", 24, 280, 19, [shell(60, 330, 3.6, 26, id="bastion_gun", mount=[50, -46]), mg(5, 210, 0.28, id="hull_mg", mount=[46, -30])], dict(fam="veh", hull="tracked", len=80, ht=54, coat=BROWN, turrets=["cannon"], plates=2), steam=20, radius=30, taunt=True, frontline=True, front_guard=0.2),
    D("siege_sapper_tank", 3, "vehicle", "vehicle", 900, "machine", 26, 290, 19, [shell(120, 300, 5.0, 50, id="demolition_gun", priority="structure", bonus={"structure": 2.2}, mount=[48, -38])], dict(fam="veh", hull="tracked", len=74, ht=48, coat=OCHRE, turrets=["mortar"]), steam=20, radius=28),
    D("boiler_ram", 3, "vehicle", "vehicle", 1000, "machine", 34, 260, 17, [melee(60, 1.6, id="ram_prow", dtype="blast", splash=30, r=40, mount=[44, -14], bonus={"structure": 1.5})], dict(fam="veh", hull="tracked", len=72, ht=46, coat=COPPER, turrets=[], ram=True), steam=15, radius=28, frontline=True,
      ability=dict(id="ram_charge", name="Ram Charge", kind="charge", steam=0, cooldown=16, windup=0.5, dist=200, radius=50, damage=120, dtype="blast", knock=40)),
    D("twin_cannon_ironclad", 3, "vehicle", "vehicle", 1000, "machine", 26, 300, 19, [shell(70, 380, 3.6, 26, id="left_gun", mount=[50, -46]), shell(70, 380, 3.6, 26, id="right_gun", mount=[46, -40], priority="swarm")], dict(fam="veh", hull="tracked", len=80, ht=52, coat=GREY, turrets=["twin"]), steam=20, radius=30),
    D("sniper_tank_hunter", 3, "vehicle", "vehicle", 720, "machine", 32, 270, 18, [shell(130, 520, 5.2, 10, id="long_gun", pen=0.35, priority="armored", bonus={"machine": 1.4, "hulk": 1.3, "mech": 1.3}, mount=[56, -36])], dict(fam="veh", hull="tracked", len=74, ht=40, coat=GREEN, turrets=["long"]), steam=20, hold_behind=True, rear_offset=80),
    D("steamtread_heavy_carrier", 3, "vehicle", "vehicle", 1000, "machine", 30, 260, 18, [mg(5, 220, 0.28, id="carrier_mg")], dict(fam="veh", hull="tracked", len=84, ht=50, coat=BROWN, turrets=["mg"], hatch=True),
      deploys=dict(unit="ironhold_rifleman", interval=11, cap=4, ahead=20), radius=30, desc="Tracked carrier that unloads Ironhold Riflemen at the front (up to 4)."),
    D("siegecrawler", 4, "vehicle", "vehicle", 1500, "machine", 20, 380, 22, [shell(150, 480, 5.5, 60, id="siege_mortar", priority="structure", bonus={"structure": 2.0}, mount=[40, -60])], dict(fam="veh", hull="crawler", len=96, ht=62, coat=GREY, turrets=["mortar"]), steam=30, radius=36),
    D("mountainshield_heavy_tank", 4, "vehicle", "vehicle", 1800, "machine", 22, 380, 22, [shell(80, 360, 3.6, 30, id="shield_gun", mount=[54, -50]), mg(6, 220, 0.25, id="sponson_mg", mount=[48, -30])], dict(fam="veh", hull="tracked", len=90, ht=58, coat=BROWN, turrets=["heavy"], plates=3), steam=30, radius=34, taunt=True, frontline=True, front_guard=0.25),
    D("thunderrail_tank_destroyer", 4, "vehicle", "vehicle", 1100, "machine", 30, 380, 22, [W(id="thunder_rail", range=560, damage=210, dtype="shock", reload=5.5, targets="ground", priority="armored", proj="shell", splash=8, ap=True, pen=0.4, windup=0.4, mount=[60, -38], bonus={"machine": 1.4, "mech": 1.4, "hulk": 1.2})], dict(fam="veh", hull="tracked", len=84, ht=46, coat=BLUE_D, turrets=["rail"], glow="9ad8ff"), steam=30, radius=32, hold_behind=True, rear_offset=90),
    D("firestorm_assault_tank", 4, "vehicle", "vehicle", 1400, "machine", 26, 360, 21, [cone(18, 130, 0.5, 6, id="firestorm_l", dtype="fire", proj="flame", targets="ground", mount=[50, -40]), cone(18, 130, 0.5, 6, id="firestorm_r", dtype="fire", proj="flame", targets="ground", mount=[46, -30])], dict(fam="veh", hull="tracked", len=86, ht=54, coat=RED, turrets=["flame", "flame"]), steam=30, radius=34),
    D("dreadplate_breaker", 4, "vehicle", "vehicle", 1500, "machine", 26, 390, 22, [shell(120, 380, 4.2, 34, id="breaker_gun", pen=0.35, mount=[56, -48]), melee(50, 1.6, id="breaker_drill", r=40, mount=[50, -18], bonus={"heavy": 1.4, "structure": 1.5})], dict(fam="veh", hull="tracked", len=88, ht=56, coat=GREY, turrets=["heavy"], ram=True), steam=30, radius=34),
    D("mobile_flak_fortress", 4, "vehicle", "vehicle", 1400, "machine", 22, 380, 22, [flak(22, 480, 0.55, 42, id="fortress_flak_l", mount=[30, -60]), flak(22, 480, 0.55, 42, id="fortress_flak_r", mount=[-10, -60])], dict(fam="veh", hull="tracked", len=92, ht=58, coat=BLUE_D, turrets=["aa", "aa"]), steam=30, radius=34, hold_behind=True, rear_offset=70),
    D("mountainbreaker", 5, "vehicle", "vehicle", 2000, "machine", 22, 480, 26, [shell(200, 460, 5.0, 50, id="mountainbreaker_gun", pen=0.45, mount=[64, -56], bonus={"structure": 1.5, "mech": 1.3})], dict(fam="veh", hull="tracked", len=104, ht=64, coat=GREY, turrets=["long"], plates=2, h=70), steam=40, radius=40),
    D("worldhammer_siege_tank", 5, "vehicle", "vehicle", 2400, "machine", 20, 500, 27, [melee(150, 3.0, id="worldhammer", dtype="blast", splash=80, r=50, windup=0.7, mount=[60, -30], bonus={"structure": 2.0})], dict(fam="veh", hull="tracked", len=100, ht=66, coat=COPPER, turrets=["hammer"], h=86), steam=40, radius=40, frontline=True),
    D("brass_leviathan", 5, "vehicle", "vehicle", 2600, "machine", 18, 520, 28, [shell(110, 420, 3.8, 34, id="leviathan_main", mount=[64, -64]), shell(70, 380, 3.2, 26, id="leviathan_aft", mount=[0, -60], priority="swarm"), mg(7, 240, 0.22, id="leviathan_mg", mount=[40, -36])], dict(fam="veh", hull="crawler", len=118, ht=72, coat=COPPER, turrets=["heavy", "cannon"], h=86), steam=45, radius=44),
    D("iron_bastion_prime", 5, "vehicle", "vehicle", 3200, "machine", 16, 520, 28, [shell(90, 380, 3.6, 30, id="prime_gun", mount=[60, -60]), mg(7, 230, 0.22, id="prime_mg", mount=[54, -34])], dict(fam="veh", hull="crawler", len=110, ht=72, coat=BROWN, turrets=["heavy"], plates=3, h=86), steam=45, radius=44, taunt=True, frontline=True, front_guard=0.3),
    D("dreadnought_landship", 5, "vehicle", "vehicle", 3000, "machine", 14, 560, 30, [shell(120, 480, 4.2, 40, id="fore_battery", mount=[70, -70]), shell(120, 480, 4.6, 40, id="aft_battery", mount=[-20, -70], priority="structure"), flak(20, 440, 0.6, 36, id="landship_flak", mount=[20, -84])], dict(fam="veh", hull="crawler", len=136, ht=80, coat=GREY, turrets=["heavy", "heavy", "aa"], h=100), steam=50, radius=50),
    # ---------------- F · aircraft
    D("rotary_interceptor", 1, "aircraft", "interceptor", 160, "light", 135, 80, 7, [mg(7, 210, 0.24, id="rotary_mg", targets="both", priority="air", mount=[22, 4], ground_mult=0.5)], dict(fam="air", frame="rotary", len=44, coat=OCHRE, guns=["mg"]), altitude=[230, 330]),
    D("twin_rotor_interceptor", 2, "aircraft", "interceptor", 190, "light", 130, 110, 9, [mg(7, 220, 0.2, id="twin_mg_l", targets="both", priority="air", mount=[22, 4], ground_mult=0.5), mg(7, 220, 0.2, id="twin_mg_r", targets="air", priority="air", mount=[18, 8])], dict(fam="air", frame="twin_rotor", len=52, coat=GREEN, guns=["mg", "mg"]), altitude=[230, 330]),
    D("skyspotter_scout", 2, "aircraft", "scout", 110, "light", 170, 75, 9, [mg(4, 160, 0.35, id="scout_mg", targets="both", priority="air", mount=[16, 4])], dict(fam="air", frame="rotary", len=38, coat=BLUE, guns=["mg"], scope=True), altitude=[180, 240], spotter=dict(range=300, art_range=1.22, art_dmg=1.15)),
    D("coalwing_strafing_craft", 2, "aircraft", "interceptor", 210, "light", 120, 120, 10, [mg(8, 220, 0.2, id="strafe_guns", targets="both", priority="swarm", mount=[22, 6], ground_mult=1.0)], dict(fam="air", frame="winged", len=56, coat=BLACK, guns=["mg", "mg"]), altitude=[220, 300]),
    D("thunderwing", 3, "aircraft", "interceptor", 280, "light", 140, 160, 11, [zap(14, 230, 1.0, 2, id="thunder_coil", targets="both", priority="air", mount=[24, 4])], dict(fam="air", frame="winged", len=60, coat=BLUE_D, guns=["coil"], glow="9ad8ff"), altitude=[230, 330]),
    D("sky_mender", 3, "aircraft", "air_repair", 220, "light", 110, 130, 11, [mg(4, 160, 0.35, id="mender_mg", targets="air", priority="air", mount=[16, 4])], dict(fam="air", frame="twin_rotor", len=50, coat=OCHRE, guns=["mg"], crane=True), altitude=[200, 260],
      repair=dict(rate=30, range=160, pool=2000, classes=["aircraft", "airship", "vehicle", "walker"]), desc="Flying repair rig: patches aircraft and machines below."),
    D("heavy_gyro_bomber", 3, "aircraft", "bomber", 380, "machine", 90, 200, 14, [bomb(70, 60, id="heavy_bombs")], dict(fam="air", frame="bomber", len=70, coat=GREY, bombs=True), altitude=[250, 290], ammo=6, rearm=4.5),
    D("flak_chaser", 3, "aircraft", "interceptor", 240, "light", 140, 150, 11, [W(id="air_flak", range=260, damage=16, dtype="flak", reload=0.8, targets="air", priority="air", proj="flak", splash=30, mount=[22, 2])], dict(fam="air", frame="winged", len=54, coat=BLUE, guns=["flak"]), altitude=[240, 330]),
    D("rune_sight_scout", 3, "aircraft", "scout", 150, "light", 170, 120, 10, [zap(8, 180, 1.4, 1, id="rune_sight", targets="both", priority="air", mount=[16, 4])], dict(fam="air", frame="rotary", len=40, coat=ROYAL, guns=["coil"], glow="c08aff", scope=True), altitude=[180, 240], spotter=dict(range=340, art_range=1.28, art_dmg=1.2)),
    D("forge_bomber", 4, "aircraft", "bomber", 520, "machine", 85, 270, 16, [bomb(80, 66, id="forge_bombs", dtype="fire")], dict(fam="air", frame="bomber", len=78, coat=COPPER, bombs=True), altitude=[250, 290], ammo=6, rearm=4.5),
    D("twin_flame_gunship", 4, "aircraft", "gunship", 760, "machine", 70, 300, 18, [W(id="belly_firebombs", range=300, damage=26, dtype="fire", reload=1.1, targets="ground", priority="swarm", proj="spit", splash=42, mount=[10, 22], arc=[10, 170]), mg(8, 240, 0.22, id="dorsal_mg", targets="air", priority="air", mount=[-6, -18])], dict(fam="air", frame="gunship", len=74, coat=RED, guns=["flame", "mg"]), altitude=[250, 290], standoff=150),
    D("heavy_interceptor", 4, "aircraft", "interceptor", 420, "machine", 130, 240, 15, [shell(30, 260, 1.4, 18, id="air_cannon", priority="air", mount=[26, 4]), mg(8, 230, 0.2, id="wing_guns", targets="both", priority="air", mount=[20, 6], ground_mult=0.6)], dict(fam="air", frame="winged", len=68, coat=GREY, guns=["cannon", "mg"]), altitude=[230, 330]),
    D("rocketwing", 4, "aircraft", "gunship", 520, "machine", 90, 280, 17, [W(id="wing_rockets", range=360, damage=28, dtype="blast", reload=4.0, targets="ground", priority="swarm", proj="arc", splash=38, burst=6, burst_gap=0.1, mount=[14, 14], arc=[0, 170])], dict(fam="air", frame="winged", len=66, coat=OCHRE, guns=["rockets"]), altitude=[250, 300], standoff=220),
    D("siege_breaker_bomber", 4, "aircraft", "bomber", 600, "machine", 75, 320, 18, [bomb(140, 70, id="siege_bombs", bonus={"structure": 2.0})], dict(fam="air", frame="bomber", len=86, coat=GREY, bombs=True), altitude=[250, 290], ammo=4, rearm=5.0),
    D("stormforge_bomber", 5, "aircraft", "bomber", 820, "machine", 80, 420, 22, [bomb(120, 72, id="storm_bombs", dtype="shock")], dict(fam="air", frame="bomber", len=92, coat=BLUE_D, bombs=True, glow="9ad8ff"), altitude=[250, 290], ammo=8, rearm=5.0),
    D("royal_skyguard", 5, "aircraft", "interceptor", 560, "machine", 140, 380, 18, [W(id="royal_flak", range=300, damage=26, dtype="flak", reload=0.6, targets="air", priority="air", proj="flak", splash=36, mount=[24, 2]), mg(9, 240, 0.18, id="royal_mg", targets="both", priority="air", mount=[20, 6], ground_mult=0.6)], dict(fam="air", frame="winged", len=72, coat=ROYAL, guns=["flak", "mg"]), altitude=[230, 330]),
    D("skyhammer_assault_craft", 5, "aircraft", "gunship", 1100, "machine", 70, 440, 22, [shell(110, 340, 3.2, 40, id="skyhammer_cannon", mount=[10, 22], arc=[10, 170]), mg(10, 250, 0.2, id="skyhammer_turret", targets="air", priority="air", mount=[-6, -20])], dict(fam="air", frame="gunship", len=88, coat=GREY, guns=["cannon", "mg"]), altitude=[260, 300], standoff=230),
    D("arcwing_superiority_craft", 5, "aircraft", "interceptor", 620, "machine", 150, 420, 20, [zap(30, 260, 0.9, 3, id="arcwing_coils", targets="both", priority="air", mount=[24, 4])], dict(fam="air", frame="winged", len=74, coat=BLUE_D, guns=["coil", "coil"], glow="9ad8ff"), altitude=[230, 330]),
    # ---------------- G · airships
    D("scout_blimp", 2, "airship", "airship", 700, "light", 30, 160, 16, [mg(5, 220, 0.3, id="blimp_mg", targets="both", priority="air", mount=[0, 30], arc=[-180, 180])], dict(fam="ship", len=120, coat=OCHRE, guns=1, h=60), altitude=[170, 190], hold_range=520,
      spotter=dict(range=360, art_range=1.2, art_dmg=1.12), radius=44),
    D("skyshield_airship", 3, "airship", "airship", 1500, "machine", 20, 300, 24, [flak(18, 440, 0.45, 40, id="skyshield_flak_f", mount=[30, -40]), flak(18, 440, 0.45, 40, id="skyshield_flak_a", mount=[-30, -40])], dict(fam="ship", len=150, coat=BLUE_D, guns=2, flak=True, h=80), altitude=[175, 185], hold_range=480, radius=54),
    D("bombard_zeppelin", 4, "airship", "airship", 2200, "machine", 18, 420, 30, [W(id="drop_battery", range=380, damage=80, dtype="blast", reload=3.0, targets="ground", priority="swarm", proj="shell", splash=48, mount=[0, 48], arc=[30, 150])], dict(fam="ship", len=170, coat=BROWN, guns=2, bombs=True, h=88), altitude=[175, 185], hold_range=360, radius=58),
    D("thunderbarge", 4, "airship", "airship", 2400, "machine", 18, 440, 32, [zap(60, 420, 2.4, 4, id="barge_coils", targets="both", priority="swarm", mount=[0, 40], arc=[-180, 180])], dict(fam="ship", len=170, coat=BLUE_D, guns=2, coils=True, h=88, glow="9ad8ff"), altitude=[175, 185], hold_range=400, radius=58),
    D("ironhold_carrier", 4, "airship", "airship", 2600, "machine", 16, 460, 34, [mg(8, 240, 0.22, id="carrier_turret", targets="air", priority="air", mount=[0, -50], arc=[-180, 180])], dict(fam="ship", len=190, coat=GREY, guns=1, deck=True, h=92), altitude=[170, 180], hold_range=560,
      deploys=dict(unit="rotary_interceptor", interval=10, cap=4, ahead=20), radius=62, desc="Flying carrier: launches Rotary Interceptors (up to 4 aloft)."),
    D("forgewatch_frigate", 4, "airship", "airship", 2300, "machine", 22, 430, 30, [shell(70, 440, 3.0, 30, id="frigate_fore", mount=[40, 44], arc=[0, 170]), shell(70, 440, 3.4, 30, id="frigate_aft", mount=[-34, 44], arc=[0, 170], priority="swarm"), flak(14, 380, 0.5, 30, id="frigate_flak", mount=[0, -60])], dict(fam="ship", len=168, coat=COPPER, guns=3, h=88), altitude=[175, 185], hold_range=400, radius=58),
    D("skyforge_dreadnought", 5, "airship", "airship", 3800, "machine", 14, 620, 40, [shell(120, 500, 3.6, 40, id="dread_fore", mount=[50, 50], arc=[0, 170]), shell(120, 500, 3.8, 40, id="dread_aft", mount=[-50, 50], arc=[0, 170]), flak(22, 440, 0.4, 40, id="dread_flak", mount=[0, -70])], dict(fam="ship", len=220, coat=GREY, guns=4, h=108), altitude=[165, 175], hold_range=420, radius=70),
    D("mountain_ark", 5, "airship", "airship", 4600, "machine", 12, 640, 42, [shell(100, 460, 3.6, 36, id="ark_battery", mount=[30, 56], arc=[0, 170]), mg(10, 260, 0.2, id="ark_turrets", targets="air", priority="air", mount=[0, -74], arc=[-180, 180])], dict(fam="ship", len=240, coat=BROWN, guns=3, deck=True, h=118), altitude=[160, 170], hold_range=520, radius=74,
      deploys=dict(unit="tunnel_militia", interval=14, cap=4, ahead=60, ground=True), aura=dict(radius=400, mods={"dr": 0.9}, dur=1.5, classes=["infantry", "engineer"])),
    D("skyhammer_battleship", 5, "airship", "airship", 4200, "machine", 16, 660, 42, [W(id="sky_ram_hammer", range=460, damage=260, dtype="blast", reload=4.0, targets="ground", priority="armored", proj="shell", splash=70, mount=[0, 60], arc=[30, 150], windup=0.5), flak(22, 420, 0.45, 40, id="battleship_flak", mount=[0, -70])], dict(fam="ship", len=220, coat=GREY, guns=2, hammer=True, h=110), altitude=[175, 185], hold_range=220, radius=70),
    D("rune_citadel_airship", 5, "airship", "airship", 4400, "machine", 12, 680, 44, [zap(70, 460, 2.0, 5, id="citadel_lightning", targets="both", priority="swarm", mount=[0, 50], arc=[-180, 180]), shell(110, 480, 3.6, 36, id="citadel_battery", mount=[40, 50], arc=[0, 170])], dict(fam="ship", len=230, coat=ROYAL, guns=3, coils=True, h=120, glow="c08aff"), altitude=[165, 175], hold_range=420, radius=72,
      aura=dict(radius=420, mods={"dr": 0.88}, dur=1.5)),
    D("grand_forge_carrier", 5, "airship", "airship", 4800, "machine", 12, 700, 46, [mg(10, 260, 0.2, id="grand_turrets", targets="air", priority="air", mount=[0, -74], arc=[-180, 180]), flak(20, 420, 0.5, 38, id="grand_flak", mount=[40, -60])], dict(fam="ship", len=250, coat=COPPER, guns=2, deck=True, h=120), altitude=[160, 170], hold_range=560, radius=76,
      deploys=dict(unit="twin_rotor_interceptor", interval=9, cap=5, ahead=20)),
]

# auxiliary units (not roster entries): deployables
AUX = {
    "dwarf_barricade": dict(cls="structure", domain="ground", hp=420, armor="structure", speed=0, radius=14, behavior="structure", art="dwarf_barricade",
                            blocks=True, static=True, weapons=[], taunt=True, name="Barricade", kit=dict(fam="prop", kind="barricade", h=40)),
    "dwarf_gun_turret": dict(cls="structure", domain="ground", hp=320, armor="structure", speed=0, radius=12, behavior="structure", art="dwarf_gun_turret",
                             blocks=False, static=True, name="Rifle Turret", weapons=[rifle(300, 14, 1.0, id="turret_rifle", targets="ground", mount=[10, -30])], kit=dict(fam="prop", kind="gun_turret", h=44)),
    "dwarf_gatling_turret": dict(cls="structure", domain="ground", hp=420, armor="structure", speed=0, radius=13, behavior="structure", art="dwarf_gatling_turret",
                                 blocks=False, static=True, name="Gatling Turret", weapons=[mg(5, 260, 0.12, id="turret_gatling", targets="both", priority="swarm", mount=[10, -32], ground_mult=1.0)], kit=dict(fam="prop", kind="gatling_turret", h=48)),
    # M006: the escorted supply airship (non-deployable ally; its HP, speed, altitude and route come from the stage's `escort`)
    "supply_barge": dict(cls="airship", domain="air", hp=2600, armor="machine", speed=20, radius=48, behavior="escort", art="supply_barge",
                         blocks=False, weapons=[], name="Supply Barge", band="mid", altitude=[210, 220],
                         kit=dict(fam="ship", len=150, coat="6e5a3e", guns=0, cargo=True, h=86)),
}


def build_dwarves():
    out, kits = {}, {}
    for uid, tier, e, kit in DWARVES:
        kits[uid] = kit
        if "scale" in kit:
            e["art_scale"] = kit["scale"]
        out[uid] = (tier, e)
    return out, kits


# ================================================================== undead
def U(uid, cls, behavior, hp, armor, spd, bounty, threat, weps, kit, h=52, radius=None, domain="ground", desc="", counter="", **extra):
    e = dict(cls=cls, domain=domain, hp=hp, armor=armor, speed=spd, radius=radius or 11, bounty=bounty, threat=threat, behavior=behavior, art=uid,
             weapons=weps, blocks=domain == "ground" and behavior != "crawler", desc=desc, counter=counter)
    if behavior in ("ranged", "repair") or extra.get("hold_behind"):
        e["hold_behind"] = True
    e.update(extra)
    kit = dict(kit)
    kit.setdefault("h", h)
    return uid, e, kit


def z(weapon="claw", flesh="8d9b7a", **k):
    p = dict(fam="zom", weapon=weapon, flesh=flesh)
    p.update(k)
    return p


def sk(weapon="sword", **k):
    p = dict(fam="skel", weapon=weapon)
    p.update(k)
    return p


def um(d, rl=1.0, r=24, **k):
    mnt = k.pop("mount", [14, -22])
    w = melee(d, rl, r, **k)
    w["mount"] = mnt
    return w


UNDEAD = [
    # ---------------- melee
    U("shambler", "infantry", "melee", 95, "flesh", 18, 4, 1, [um(9, 1.2, id="shamble_claw")], z("claw", "7f8b6a", cloth="4b4541"), desc="Slow, sturdy corpse. Takes a lot of shot to drop.", counter="Anything with volume."),
    U("rusted_legionary", "infantry", "melee", 180, "heavy", 24, 8, 3, [um(14, 1.1, id="rusted_gladius")], sk("sword", helm="5a5a52", armor="rust", shield="round"), desc="Skeletal legionary in rusted mail and shield.", counter="Blast and hammers; AP rifles."),
    U("bone_pikeman", "infantry", "melee", 110, "bone", 26, 6, 2, [um(13, 1.3, r=40, id="bone_pike")], sk("pike"), desc="Long pikes strike before swords can reply.", counter="Grenades and cannons."),
    U("ossuary_axeman", "infantry", "melee", 130, "bone", 28, 7, 2.5, [um(18, 1.4, id="ossuary_axe", splash=16)], sk("axe"), desc="Cleaving axes that bite into shield walls.", counter="Out-range it."),
    U("barrow_spearman", "infantry", "ranged", 90, "bone", 28, 6, 2, [W(id="thrown_spear", range=160, damage=14, dtype="pierce", reload=2.4, targets="ground", priority="nearest", proj="arrow", mount=[16, -28])], sk("spear"), desc="Hurls barrow-spears from behind the front.", counter="Shotguns and grenades."),
    U("blight_marauder", "infantry", "melee", 140, "flesh", 34, 7, 2.5, [um(15, 0.9, id="blight_cleaver", bonus={"flesh": 1.2})], z("cleaver", "6f7a4f", cloth="5a3a2a"), desc="Fast raider swinging a blighted cleaver.", counter="Shieldbearers and rifles."),
    U("rotting_berserker", "infantry", "melee", 170, "flesh", 40, 8, 3, [um(20, 0.8, id="frenzy_claws")], z("twin_claws", "8a6a5a", cloth="3a2a2a", hunch=True), death_burst=dict(damage=14, radius=40, dtype="acid"), desc="Frenzied runner that keeps swinging until it bursts.", counter="Kill it at range."),
    U("fungal_host", "infantry", "melee", 160, "flesh", 18, 7, 2.5, [um(10, 1.2, id="spore_grasp")], z("claw", "8a8f5a", fungus=True), death_spawn=dict(unit="rotter", count=2), desc="Riddled with fungus; two Rotters burst from it when it falls.", counter="Fire and blast."),
    U("pestilent_soldier", "infantry", "melee", 150, "light", 24, 7, 2.5, [um(13, 1.1, id="pestilent_blade")], z("sword", "7f8b6a", helmet=True, cloth="4a4a3a"), death_burst=dict(damage=16, radius=46, dtype="acid"), desc="Plague-soaked soldier; bursts in a toxic cloud.", counter="Range."),
    U("crypt_halberdier", "infantry", "melee", 200, "heavy", 22, 9, 3.5, [um(22, 1.6, r=40, id="crypt_halberd", splash=22, windup=0.3)], sk("halberd", helm="5a5a52", armor="rust"), desc="Armored skeleton sweeping a long halberd.", counter="AP rounds, hammers."),
    U("tomb_stalker", "infantry", "crawler", 110, "flesh", 44, 7, 3, [um(16, 0.7, id="stalker_claws", priority="support")], z("twin_claws", "5f5f6a", hunch=True, cloth="2a2a33"), low_profile=True, desc="Slips under the front line to tear at crews and casters.", counter="Escort artillery with infantry."),
    U("hollow_guard", "infantry", "melee", 260, "heavy", 22, 10, 4, [um(14, 1.2, id="hollow_mace")], sk("mace", helm="3a3a40", armor="black", shield="tower"), taunt=True, frontline=True, desc="Black-armored shield bearer that draws fire.", counter="Arcing fire behind it."),
    U("risen_bomb_carrier", "infantry", "melee", 70, "flesh", 46, 6, 3, [um(4, 1.0, id="bomb_claw")], z("bomb", "7f8b6a"), death_burst=dict(damage=70, radius=70, dtype="blast"), desc="Carries a lit powder keg. Kill it before it reaches you.", counter="Long-range rifles."),
    U("wretched_climber", "infantry", "crawler", 80, "flesh", 40, 5, 2, [um(11, 0.7, id="climber_claws", priority="support")], z("twin_claws", "9a9a88", hunch=True), low_profile=True, desc="Scrambles past the front to reach artillery.", counter="Militia guarding the guns."),
    U("carcass_devourer", "infantry", "melee", 190, "flesh", 26, 8, 3, [um(16, 1.0, id="devour_bite")], z("maw", "8a6a5a", bloat=True), heal_on_hit=0.5, desc="Eats as it fights, healing from every bite.", counter="Burst damage."),
    U("bone_vanguard", "infantry", "melee", 160, "bone_shield", 26, 8, 3, [um(13, 1.1, id="vanguard_blade")], sk("sword", shield="kite", helm="5a5a52"), frontline=True, desc="Bone shield and blade at the very front.", counter="Grenades, cannons."),
    U("grave_warden", "infantry", "melee", 230, "heavy", 22, 10, 4, [um(20, 1.4, id="warden_lantern_mace", splash=18)], sk("mace", helm="3a3a40", armor="black", lantern=True), aura=dict(radius=140, mods={"dr": 0.85}, dur=1.5), desc="Its lantern hardens nearby undead (-15% damage taken).", counter="Kill the Warden first."),
    U("black_rot_infantry", "infantry", "melee", 180, "light", 26, 8, 3, [um(15, 1.0, id="black_rot_blade", bonus={"flesh": 1.3, "light": 1.2})], z("sword", "4a4a3a", helmet=True, cloth="2a2a2a"), desc="Rot-black soldiers whose blades fester.", counter="Rifles, flame."),
    U("cursed_dwarf_thrall", "infantry", "ranged", 160, "light", 30, 9, 3.5, [W(id="cursed_rifle", range=240, damage=16, dtype="pierce", reload=1.9, targets="ground", priority="threat", proj="bullet", mount=[20, -24])], z("rifle", "7a8a7a", helmet=True, dwarf=True, cloth="2f3f4a"), desc="A fallen dwarf, still holding his rifle. The undead turned our own.", counter="Out-range and out-gun."),
    U("plague_mauler", "infantry", "melee", 280, "light", 24, 11, 4, [um(26, 1.6, id="mauler_fists", dtype="blast", splash=24, windup=0.3)], z("fists", "7f8a55", bloat=True, cloth="3a3a2a"), radius=14, desc="Bloated bruiser with fists like barrels.", counter="AP and cannons."),
    U("dread_executioner", "infantry", "melee", 320, "heavy", 22, 14, 5, [um(40, 2.2, id="executioner_axe", splash=24, windup=0.5, priority="armored")], sk("greataxe", helm="2a2a2a", armor="black", hood=True), radius=14, frontline=True, desc="Executioner's axe; picks the toughest target.", counter="Kill it at range."),
    U("ossuary_champion", "infantry", "melee", 420, "heavy", 26, 18, 6, [um(30, 1.3, id="champion_blade", splash=24)], sk("greatsword", helm="9a8a4a", armor="gild", shield="kite", scale=1.15), radius=15, frontline=True, art_scale=1.15, desc="Champion of the ossuaries in gilded bone plate.", counter="Concentrated AP fire."),
    U("riftbound_legionary", "infantry", "melee", 300, "heavy", 30, 14, 5, [um(24, 1.0, id="rift_blade", dtype="necro")], sk("sword", helm="3a2a4a", armor="rift", shield="round", glow="a070ff"), desc="Legionary bound to the rift; violet blade ignores some armor.", counter="Shock weapons."),
    # ---------------- ranged / casters
    U("grave_slinger", "infantry", "ranged", 70, "bone", 26, 5, 2, [W(id="bone_sling", range=210, damage=10, dtype="blast", reload=1.6, targets="ground", priority="nearest", proj="arc", splash=16, mount=[14, -30])], sk("sling"), desc="Slings bone fragments over the front.", counter="Rifles."),
    U("plague_sprayer", "infantry", "ranged", 110, "flesh", 22, 7, 3, [cone(6, 100, 0.5, 4, id="plague_spray", dtype="acid", proj="flame", targets="ground")], z("sprayer", "8a955f", tank=True), desc="Sprays acid in a short cone. Machines hate it.", counter="Range."),
    U("crypt_hexer", "infantry", "ranged", 100, "flesh", 22, 9, 3.5, [W(id="hex_bolt", range=240, damage=10, dtype="necro", reload=2.0, targets="ground", priority="threat", proj="bolt", mount=[16, -40], bonus={"_slow": [0.6, 2.5]})], dict(fam="cast", robe="3a2a4a", staff="hex", glow="a070ff"), desc="Hexes slow their victims to a crawl.", counter="Counter-Curse Technicians; kill fast."),
    U("corpse_priest", "infantry", "repair", 120, "flesh", 22, 12, 4, [W(id="grave_bolt", range=200, damage=8, dtype="necro", reload=2.0, targets="ground", priority="nearest", proj="bolt", mount=[16, -40])], dict(fam="cast", robe="4a3a2a", staff="censer", glow="43ff8c"),
      repair=dict(rate=16, range=160, pool=1200, classes=["infantry", "monster"]), desc="Mends the dead around it.", counter="Priority target."),
    U("ossuary_caller", "infantry", "necromancer", 140, "flesh", 22, 18, 5, [W(id="caller_bolt", range=220, damage=10, dtype="necro", reload=2.2, targets="both", priority="threat", proj="bolt", mount=[16, -40])], dict(fam="cast", robe="5a5a52", staff="skull", glow="e6dfc6"),
      raise_dead=dict(interval=8.0, count=2, range=230, cap=6, windup=1.0, enemy="ossuary_skeleton"), desc="Calls skeletons up out of the corpses.", counter="Kill it first."),
    U("cinder_wraith", "infantry", "ranged", 110, "light", 30, 9, 3.5, [W(id="cinder_bolt", range=230, damage=14, dtype="fire", reload=1.6, targets="both", priority="threat", proj="bolt", splash=18, mount=[16, -36])], dict(fam="cast", robe="2a1a1a", staff="none", glow="ff8a3a", wraith=True), desc="Burning ghost hurling cinders at air and ground.", counter="Flak, rifles."),
    U("spirit_binder", "infantry", "ranged", 120, "flesh", 22, 11, 4, [W(id="binding_chain", range=200, damage=8, dtype="necro", reload=2.4, targets="both", priority="threat", proj="bolt", mount=[16, -40], bonus={"_stun": 1.0})], dict(fam="cast", robe="2a3a4a", staff="chain", glow="7ad0ff"), desc="Spirit chains stun what they hit.", counter="Kill quickly; cleanse."),
    U("plague_herald", "infantry", "ranged", 130, "flesh", 24, 12, 4, [W(id="herald_spit", range=220, damage=12, dtype="acid", reload=2.0, targets="ground", priority="armored", proj="spit", splash=20, mount=[14, -32])], dict(fam="cast", robe="4a5a2a", staff="horn", glow="c9c45c"),
      aura=dict(radius=180, mods={"speed": 1.2, "fire": 1.15}, dur=1.5), desc="Its horn drives the horde: +20% speed, +15% attack rate nearby.", counter="Kill the Herald."),
    U("bone_lancer", "infantry", "ranged", 100, "bone", 26, 8, 3, [W(id="bone_lance", range=260, damage=26, dtype="pierce", reload=2.6, targets="both", priority="air", proj="shard", mount=[16, -34])], sk("javelin"), desc="Hurls bone lances that can spear aircraft.", counter="Grenades, cannons."),
    U("grave_dart_thrower", "infantry", "ranged", 70, "flesh", 30, 5, 2, [W(id="grave_darts", range=200, damage=6, dtype="acid", reload=0.9, targets="ground", priority="support", proj="arrow", mount=[14, -28])], z("darts", "9a9a88", hunch=True), desc="Poison darts aimed at crews and support.", counter="Rifles."),
    U("funeral_bell_keeper", "infantry", "ranged", 160, "light", 20, 14, 5, [W(id="dirge_wave", range=180, damage=10, dtype="necro", reload=2.6, targets="ground", priority="nearest", proj="bolt", splash=30, mount=[12, -40])], dict(fam="cast", robe="2a2a2a", staff="bell", glow="7ad0ff"),
      aura=dict(radius=200, mods={"dr": 0.85, "fire": 1.1}, dur=1.5), desc="Tolls a funeral bell: undead nearby take less damage and strike faster.", counter="Kill the keeper."),
    U("rot_channeler", "infantry", "ranged", 120, "flesh", 22, 11, 4, [W(id="rot_beam", range=220, damage=5, dtype="acid", reload=0.35, targets="ground", priority="armored", proj="bolt", mount=[16, -40], bonus={"machine": 1.5})], dict(fam="cast", robe="3a4a2a", staff="orb", glow="9adf3a"), desc="Channels a rot beam that eats machinery.", counter="Keep tanks back; kill it with infantry."),
    U("ash_hexer", "infantry", "ranged", 110, "flesh", 24, 10, 4, [W(id="ash_hex", range=250, damage=14, dtype="fire", reload=2.2, targets="ground", priority="threat", proj="bolt", splash=24, mount=[16, -40], bonus={"_slow": [0.7, 2.0]})], dict(fam="cast", robe="3a3030", staff="hex", glow="ff6a2a"), desc="Burning hexes that slow and scorch.", counter="Cleanse, range."),
    U("night_seer", "infantry", "ranged", 110, "flesh", 24, 12, 4.5, [W(id="seer_bolt", range=320, damage=16, dtype="necro", reload=2.4, targets="both", priority="support", proj="bolt", mount=[16, -42])], dict(fam="cast", robe="1a1a2a", staff="eye", glow="9a8aff"), reveal_aura=True, desc="Sees far: snipes support units and aircraft.", counter="Fast aircraft, artillery."),
    U("rift_conjurer", "infantry", "necromancer", 150, "flesh", 22, 18, 6, [W(id="rift_bolt_small", range=260, damage=18, dtype="necro", reload=2.2, targets="both", priority="threat", proj="bolt", mount=[16, -42])], dict(fam="cast", robe="2a1a3a", staff="rift", glow="a070ff"),
      raise_dead=dict(interval=9.0, count=2, range=260, cap=6, windup=1.2, enemy="riftbound_legionary"), desc="Opens small rifts that spit out Riftbound Legionaries.", counter="Kill it before the rift opens."),
    # ---------------- monsters
    U("burrow_horror", "monster", "burrower", 520, "hulk", 30, 30, 9, [um(34, 1.4, r=40, id="horror_mandibles", splash=24)], dict(fam="beast", kind="burrower", skin="6a5a4a"), radius=20, h=60, burrow_until=0.5, desc="Tunnels beneath the line and erupts among the guns.", counter="Scout Gyros reveal it; militia by the artillery."),
    U("rot_hound", "monster", "melee", 120, "flesh", 62, 5, 2, [um(12, 0.6, id="hound_bite")], dict(fam="beast", kind="hound", skin="7a6a5a"), radius=12, h=36, desc="Fast packs of rotting hounds.", counter="Shotguns, MGs."),
    U("grave_spider", "monster", "melee", 260, "light", 34, 14, 4, [um(16, 0.9, r=34, id="spider_fangs", bonus={"_slow": [0.6, 2.0]})], dict(fam="beast", kind="spider", skin="3a3a40"), radius=16, h=40, desc="Webs and venom slow its prey.", counter="Flame, MGs."),
    U("tomb_centipede", "monster", "melee", 420, "heavy", 30, 22, 6, [um(22, 1.0, r=36, id="centipede_mandibles", splash=20)], dict(fam="beast", kind="centipede", skin="5a4a3a"), radius=20, h=34, desc="Armored segments and crushing mandibles.", counter="AP, blast."),
    U("flesh_charger", "monster", "melee", 600, "hulk", 40, 30, 8, [um(30, 1.4, r=40, id="charger_horns", dtype="blast", splash=24)], dict(fam="beast", kind="charger", skin="8a6a5a"), radius=22, h=60,
      ability=dict(id="flesh_charge", name="Charge", kind="charge", steam=0, cooldown=12, windup=0.6, dist=200, radius=46, damage=70, dtype="blast", knock=30), behavior_override="giant",
      desc="A stitched charger that bowls through infantry.", counter="Shields and cannons."),
    U("bone_devourer", "monster", "melee", 800, "bone", 24, 34, 9, [um(40, 1.6, r=44, id="devourer_jaws", splash=30)], dict(fam="beast", kind="devourer", skin="e2dac0"), radius=24, h=70, heal_on_hit=0.4, desc="A walking ossuary that grinds bodies and heals from them.", counter="Blast, hammers."),
    U("oozing_horror", "monster", "melee", 700, "hulk", 18, 26, 7, [um(22, 1.2, r=36, id="ooze_slam", dtype="acid", splash=30)], dict(fam="beast", kind="ooze", skin="7a9a4a"), radius=22, h=50, death_spawn=dict(unit="rotter", count=3), desc="A heaving mass of rot. Splits into Rotters when it dies.", counter="Fire and blast."),
    U("corpse_burrower", "monster", "burrower", 360, "flesh", 34, 20, 6, [um(24, 1.0, id="burrower_claws", priority="support")], dict(fam="beast", kind="burrower", skin="7f8b6a"), radius=16, h=48, burrow_until=0.6, desc="Tunnels to the guns and digs in.", counter="Scouts, militia."),
    # ---------------- siege
    U("bone_catapult", "artillery", "artillery", 300, "structure", 16, 20, 5, [arc(40, 420, 4.2, 44, id="bone_shot", min_range=120)], dict(fam="siege", kind="catapult"), radius=18, h=50, rear_offset=140, blocks=False, desc="Lobs bundles of bone over the battle.", counter="Bombers, cannons."),
    U("corpse_lobber", "artillery", "artillery", 280, "structure", 16, 18, 5, [arc(30, 380, 4.0, 40, id="corpse_shot", min_range=100, dtype="acid")], dict(fam="siege", kind="lobber"), radius=18, h=50, rear_offset=140, blocks=False, desc="Hurls diseased corpses that splash acid.", counter="Bombers."),
    U("grave_mortar", "artillery", "artillery", 260, "structure", 16, 18, 5, [arc(46, 460, 4.4, 50, id="grave_mortar_shell", min_range=140)], dict(fam="siege", kind="mortar"), radius=16, h=44, rear_offset=150, blocks=False, desc="Bone-tube mortar.", counter="Counterbattery, bombers."),
    U("grave_flak_spire", "structure", "structure", 520, "structure", 0, 25, 5, [W(id="spire_flak", range=420, damage=16, dtype="flak", reload=1.1, targets="air", priority="air", proj="flak", splash=40, mount=[0, -90])], dict(fam="siege", kind="flak_spire"), radius=18, h=110, static=True, blocks=False, desc="Bursts of bone shrapnel aimed at aircraft.", counter="Artillery."),
    U("necrotic_beacon", "structure", "structure", 400, "structure", 0, 30, 6, [], dict(fam="siege", kind="beacon", glow="43ff8c"), radius=16, h=100, static=True, blocks=False, aura=dict(radius=320, mods={"dr": 0.85, "speed": 1.15}, dur=1.5), desc="Empowers all undead nearby.", counter="Destroy it with artillery."),
    U("cursed_barricade", "structure", "structure", 700, "structure", 0, 15, 3, [], dict(fam="siege", kind="barricade"), radius=16, h=40, static=True, blocks=True, taunt=True, desc="Bone and iron barricade that soaks fire.", counter="Sappers, blast."),
    U("plague_cauldron", "artillery", "artillery", 300, "structure", 14, 20, 5, [arc(20, 340, 4.0, 60, id="cauldron_splash", dtype="acid", min_range=80)], dict(fam="siege", kind="cauldron", glow="c9c45c"), radius=18, h=50, rear_offset=120, blocks=False,
      ability=dict(id="boil_over", name="Boil Over", kind="zone", steam=0, cooldown=18, windup=0.8, radius=70, dps=26, dur=6, offset=200, dtype="acid", look="plague"), desc="Splashes boiling plague and leaves pools.", counter="Bombers."),
    U("bone_bolt_thrower", "artillery", "artillery", 260, "structure", 16, 18, 5, [W(id="bolt_thrower", range=440, damage=44, dtype="pierce", reload=3.2, targets="both", priority="armored", proj="shard", mount=[16, -26], bonus={"machine": 1.3})], dict(fam="siege", kind="ballista"), radius=16, h=44, rear_offset=140, blocks=False, desc="A ballista that hits aircraft and vehicles.", counter="Artillery."),
    U("bone_ram", "monster", "melee", 700, "structure", 22, 24, 6, [um(60, 2.4, r=40, id="ram_head", dtype="blast", bonus={"structure": 2.5, "machine": 1.4})], dict(fam="siege", kind="ram"), radius=22, h=50, frontline=True, desc="Battering ram that wrecks barricades and the stronghold gate.", counter="Kill it before it reaches the wall."),
    U("flesh_trebuchet", "artillery", "artillery", 380, "structure", 12, 26, 6, [arc(80, 540, 5.5, 60, id="trebuchet_load", min_range=180, priority="structure", bonus={"structure": 1.5})], dict(fam="siege", kind="trebuchet"), radius=22, h=80, rear_offset=170, blocks=False, desc="Long-range engine that hammers the stronghold.", counter="Bombers, counterbattery."),
    U("grave_howitzer", "artillery", "artillery", 420, "structure", 12, 28, 7, [arc(70, 500, 4.8, 56, id="grave_howitzer_shell", min_range=150)], dict(fam="siege", kind="howitzer"), radius=20, h=54, rear_offset=160, blocks=False, desc="Heavy bone-cast howitzer.", counter="Bombers."),
    U("plague_spore_cannon", "artillery", "artillery", 340, "structure", 14, 24, 6, [W(id="spore_shell", range=440, damage=14, dtype="acid", reload=3.6, targets="both", priority="air", proj="flak", splash=60, mount=[16, -30])], dict(fam="siege", kind="spore_cannon", glow="c9c45c"), radius=18, h=50, rear_offset=140, blocks=False, desc="Spore clouds that choke aircraft and crews.", counter="Artillery."),
    U("rot_launcher", "artillery", "artillery", 300, "structure", 16, 22, 6, [W(id="rot_rockets", range=420, min_range=100, damage=18, dtype="acid", reload=4.5, targets="ground", priority="swarm", proj="arc", splash=34, burst=5, burst_gap=0.14, mount=[16, -28])], dict(fam="siege", kind="launcher"), radius=18, h=46, rear_offset=150, blocks=False, desc="Fires salvos of rot-filled bone rockets.", counter="Bombers."),
    U("soul_turret", "structure", "structure", 600, "structure", 0, 30, 7, [W(id="soul_beam", range=360, damage=18, dtype="necro", reload=0.9, targets="both", priority="threat", proj="bolt", mount=[0, -60])], dict(fam="siege", kind="soul_turret", glow="7ad0ff"), radius=16, h=80, static=True, blocks=False, desc="A bound soul that lashes out at everything in range.", counter="Siege guns."),
    U("rift_obelisk", "structure", "structure", 800, "structure", 0, 40, 8, [zap(30, 340, 2.2, 3, id="rift_arc", targets="both", priority="swarm", mount=[0, -100])], dict(fam="siege", kind="obelisk", glow="a070ff"), radius=18, h=120, static=True, blocks=False, desc="Rift lightning that leaps between your units.", counter="Out-range it."),
    U("wraith_beacon", "structure", "structure", 500, "structure", 0, 30, 7, [], dict(fam="siege", kind="beacon", glow="9ad8ff"), radius=16, h=100, static=True, blocks=False,
      deploys=dict(unit="spectral_wraith", interval=12, cap=3, ahead=-40, air=True), desc="Summons spectral wraiths into the sky.", counter="Destroy it fast."),
    # ---------------- flying
    U("blight_bat", "flyer", "bat", 60, "flesh", 115, 5, 2, [um(8, 0.7, r=20, id="blight_bite", mount=[8, 4], targets="both")], dict(fam="fly", kind="bat", skin="5a6a3a", span=1.0), domain="air", radius=10, h=30, altitude=[260, 380], death_burst=dict(damage=10, radius=36, dtype="acid"), desc="Plague bat that bursts when shot down.", counter="Flak."),
    U("grave_moth", "flyer", "shrieker", 70, "flesh", 90, 5, 2, [W(id="moth_dust", range=150, damage=6, dtype="acid", reload=1.0, targets="both", priority="support", proj="spit", splash=24, mount=[10, 4])], dict(fam="fly", kind="moth", skin="8a8a9a"), domain="air", radius=12, h=34, altitude=[230, 320], standoff=120, desc="Choking dust from above.", counter="Flak."),
    U("bone_wyvern", "flyer", "shrieker", 420, "bone", 80, 24, 7, [W(id="wyvern_shards", range=230, damage=20, dtype="pierce", reload=1.6, targets="both", priority="air", proj="shard", mount=[20, 0])], dict(fam="fly", kind="wyvern", skin="e2dac0", span=1.2), domain="air", radius=20, h=60, altitude=[230, 320], standoff=170, desc="Skeletal wyvern that duels aircraft.", counter="Flak, interceptors."),
    U("skeletal_vulture", "flyer", "bat", 90, "bone", 100, 6, 2.5, [um(11, 0.8, r=20, id="vulture_beak", mount=[8, 4], priority="support", targets="both")], dict(fam="fly", kind="vulture", skin="e2dac0"), domain="air", radius=12, h=34, altitude=[260, 360], desc="Dives on crews and the wounded.", counter="Flak."),
    U("rotwing", "flyer", "bat", 140, "flesh", 95, 8, 3, [um(14, 0.8, r=22, id="rotwing_claws", mount=[8, 4], targets="both")], dict(fam="fly", kind="bat", skin="6a4a4a", span=1.4), domain="air", radius=14, h=40, altitude=[240, 360], desc="Large rotting wing-beast.", counter="Flak."),
    U("tomb_gargoyle", "flyer", "bat", 320, "structure", 70, 14, 5, [um(22, 1.2, r=24, id="gargoyle_claws", mount=[8, 4], targets="both")], dict(fam="fly", kind="gargoyle", skin="6a6a6a"), domain="air", radius=16, h=46, altitude=[230, 320], desc="Stone gargoyle; shrugs off bullets.", counter="Flak, cannons."),
    U("carrion_wasp", "flyer", "bat", 45, "flesh", 140, 4, 1.5, [um(7, 0.5, r=18, id="wasp_sting", mount=[8, 4], targets="both", bonus={"_slow": [0.7, 1.5]})], dict(fam="fly", kind="wasp", skin="9a7a2a"), domain="air", radius=9, h=26, altitude=[240, 360], desc="Fast stinging swarm.", counter="Flak, MGs."),
    U("spectral_wraith", "flyer", "shrieker", 120, "light", 90, 8, 3, [W(id="wraith_wail", range=170, damage=12, dtype="necro", reload=1.4, targets="both", priority="support", proj="bolt", mount=[10, 0])], dict(fam="fly", kind="wraith", glow="9ad8ff"), domain="air", radius=12, h=44, altitude=[220, 300], standoff=120, desc="A drifting ghost that wails at the living.", counter="Flak, shock."),
    U("bone_drake", "flyer", "shrieker", 900, "bone", 60, 40, 10, [W(id="drake_breath", range=240, damage=10, dtype="necro", reload=0.4, targets="both", priority="swarm", proj="bolt", splash=20, mount=[30, 6])], dict(fam="fly", kind="drake", skin="d8d0b0", span=1.6), domain="air", radius=26, h=70, altitude=[220, 300], standoff=150, desc="A bone drake breathing grave-fire on everything below.", counter="Heavy flak, interceptors."),
    U("plague_harpy", "flyer", "shrieker", 160, "flesh", 95, 9, 3, [W(id="harpy_spit", range=200, damage=14, dtype="acid", reload=1.5, targets="both", priority="air", proj="spit", splash=18, mount=[14, 0])], dict(fam="fly", kind="harpy", skin="8a955f"), domain="air", radius=13, h=44, altitude=[220, 310], standoff=160, desc="Shrieking harpy that hunts aircraft.", counter="Flak."),
    U("gravewing_stalker", "flyer", "bat", 200, "flesh", 120, 10, 3.5, [um(18, 0.7, r=22, id="stalker_talons", mount=[8, 4], priority="support", targets="both")], dict(fam="fly", kind="bat", skin="3a3a4a", span=1.3), domain="air", radius=14, h=40, altitude=[250, 360], desc="Silent dive-hunter that targets crews.", counter="Flak."),
    U("rift_crow", "flyer", "bat", 60, "light", 150, 5, 2, [um(9, 0.6, r=18, id="crow_peck", mount=[8, 4], targets="both", dtype="necro")], dict(fam="fly", kind="crow", skin="2a1a3a", glow="a070ff"), domain="air", radius=9, h=26, altitude=[240, 360], desc="Rift-touched crows in flocks.", counter="Flak, MGs."),
    U("ossuary_flier", "flyer", "shrieker", 220, "bone", 85, 10, 3.5, [W(id="bone_darts", range=220, damage=12, dtype="pierce", reload=1.1, targets="both", priority="air", proj="shard", mount=[12, 0])], dict(fam="fly", kind="bonebird", skin="e2dac0"), domain="air", radius=14, h=40, altitude=[230, 320], standoff=150, desc="Bone construct that peppers aircraft with darts.", counter="Flak."),
    U("banshee_wing", "flyer", "shrieker", 260, "light", 90, 14, 5, [W(id="banshee_scream", range=200, damage=14, dtype="necro", reload=2.2, targets="both", priority="swarm", proj="bolt", splash=40, mount=[12, 0], bonus={"_stun": 0.6})], dict(fam="fly", kind="wraith", glow="dff0ff", wings=True), domain="air", radius=15, h=50, altitude=[220, 300], standoff=140, desc="Its scream stuns crews and pilots.", counter="Kill it at range."),
    U("wraith_swarm", "flyer", "bat", 180, "light", 110, 8, 3, [um(6, 0.3, r=24, id="swarm_chill", mount=[0, 0], targets="both", dtype="necro", splash=20)], dict(fam="fly", kind="swarm", glow="9ad8ff"), domain="air", radius=16, h=40, altitude=[240, 340], desc="A shrieking cloud of lesser spirits.", counter="Flak bursts."),
    U("necrotic_sky_serpent", "flyer", "shrieker", 1400, "hulk", 55, 60, 12, [W(id="serpent_breath", range=280, damage=36, dtype="necro", reload=1.2, targets="both", priority="air", proj="bolt", splash=34, mount=[40, 0]), um(40, 1.6, r=40, id="serpent_coils", mount=[0, 10], targets="both")], dict(fam="fly", kind="serpent", skin="4a5a3a", glow="43ff8c", span=2.4), domain="air", radius=30, h=60, altitude=[200, 280], standoff=170, desc="A vast serpent coiling through the sky.", counter="Massed flak and interceptors."),
    # ---------------- corrupted machines
    U("risen_copperback", "vehicle", "vehicle", 900, "machine", 32, 40, 8, [shell(64, 330, 4.0, 26, id="risen_cannon", mount=[44, -40]), mg(5, 220, 0.3, id="risen_mg", mount=[38, -36])], dict(fam="corrupt", base="copperback"), radius=26, h=72, tint="b8d0a8", desc="A dwarven light tank possessed by the dead.", counter="AP, Sniper Tank Hunters."),
    U("cursed_ironclad", "walker", "giant", 1700, "mech", 22, 70, 14, [melee(60, 2.4, 44, id="cursed_hammer", dtype="blast", splash=40, windup=0.5, mount=[26, -60]), mg(8, 230, 0.25, id="cursed_mg", mount=[40, -80])], dict(fam="corrupt", base="ironclad_walker"), radius=29, h=110, art_scale=1.347, arm=0.3, mech_class="medium", death_time=1.7, tint="b0c8a0",
      ability=dict(id="cursed_slam", name="Cursed Slam", kind="aoe", steam=0, cooldown=16, windup=0.7, radius=110, damage=80, dtype="blast", knock=24, min_targets=2, telegraph=True), desc="An Ironclad Walker possessed by a bound spirit.", counter="Shock, AP."),
    U("possessed_drillwalker", "walker", "giant", 1050, "mech", 30, 50, 10, [melee(30, 0.5, 36, id="possessed_drill", dtype="drill", mount=[22, -44], bonus={"structure": 1.6})], dict(fam="corrupt", base="drillwalker"), radius=22, h=110, art_scale=0.945, arm=0.2, mech_class="light", death_time=1.3, tint="b0c8a0",
      ability=dict(id="possessed_bore", name="Frenzied Bore", kind="strike", steam=0, cooldown=12, windup=0.4, mult=2.5, hits=2), desc="A drillwalker whose crew never left.", counter="Range and shock."),
    U("gravegun_tank", "vehicle", "vehicle", 1300, "machine", 26, 60, 11, [shell(100, 400, 4.4, 34, id="gravegun", dtype="necro", mount=[50, -46]), mg(6, 220, 0.28, id="grave_mg", mount=[44, -38])], dict(fam="corrupt", base="kit:gravegun_hull"), radius=30, h=70, tint="c0d8b8", desc="Heavy tank rebuilt from bone and salvaged iron.", counter="AP, rail guns."),
    U("haunted_flying_machine", "flyer", "interceptor", 200, "light", 120, 10, 3.5, [mg(7, 210, 0.28, id="haunted_mg", targets="both", priority="air", mount=[22, 4], ground_mult=0.5)], dict(fam="corrupt", base="flying_machine"), domain="air", radius=16, h=40, altitude=[230, 330], tint="a8c8a0", desc="A crashed gyro still flying, crewed by the dead.", counter="Flak."),
    U("infected_airbarge", "airship", "airship", 2800, "machine", 16, 120, 16, [shell(60, 420, 3.4, 30, id="barge_battery", dtype="acid", mount=[38, 44], arc=[0, 170]), W(id="barge_spores", range=320, damage=12, dtype="acid", reload=1.2, targets="air", priority="air", proj="flak", splash=36, mount=[0, -62], arc=[-180, 180])], dict(fam="corrupt", base="ironcloud"), domain="air", radius=60, h=92, altitude=[175, 185], hold_range=380, tint="a0c890", desc="A captured airship overgrown with plague.", counter="Flak batteries, gunships."),
]


def build_undead():
    out, kits = {}, {}
    for uid, e, kit in UNDEAD:
        if e.get("behavior_override"):
            e["behavior"] = e.pop("behavior_override")
            e["mech_class"] = "light"
            e["death_time"] = 1.4
        kits[uid] = kit
        out[uid] = e
    return out, kits


# ================================================================== bosses
# Generic boss: several abilities on their own cooldowns, support waves, enrage, staged death.
def B(bid, behavior, hp, armor, spd, radius, weps, abilities, kit, rel, support=None, seals=True, arm=0.3, domain="ground", altitude=None, desc="", counter="", **extra):
    art_scale = round(rel * 52.0 / 110.0, 3)
    e = dict(cls="boss", domain=domain, role="boss", hp=hp, armor=armor, speed=spd, radius=radius, bounty=250, threat=40, behavior=behavior, art=bid,
             art_scale=art_scale, arm=arm, blocks=domain == "ground", frontline=True, weapons=weps, abilities=abilities, mech_class="colossal", death_time=3.2,
             boss=dict(seals_citadel=seals, support=support or {}, enrage_below=0.35, enrage_mult=1.35), desc=desc, counter=counter)
    if altitude:
        e["altitude"] = altitude
    e.update(extra)
    kit = dict(kit)
    kit.setdefault("h", 110)
    return bid, e, kit


def ab(id, name, kind, cd, windup, **k):
    d = dict(id=id, name=name, kind=kind, steam=0, cooldown=cd, windup=windup)
    d.update(k)
    return d


BOSSES = [
    B("bellringer", "boss", 6400, "bone", 18, 46, [melee(90, 2.6, 70, id="great_bell_swing", dtype="blast", splash=70, windup=0.7, mount=[50, -60]), W(id="toll_wave", range=320, damage=30, dtype="necro", reload=2.4, targets="both", priority="air", proj="bolt", splash=40, mount=[30, -180], arc=[-178, 40])],
      [ab("funeral_toll", "Funeral Toll", "aoe", 16, 1.2, radius=180, damage=60, dtype="necro", stun=1.3, telegraph=True, min_targets=3), ab("call_the_dead", "Call the Dead", "summon", 22, 1.0, enemy="ossuary_skeleton", count=3, cap=8)],
      dict(fam="giant_cfg", base="cathedral_ghast", tint="9ab0c0"), 6.2, support=dict(interval=26, cap=8, waves=[["rotter", 3], ["bone_archer", 2]]),
      desc="A towering bell-bearer. Each toll freezes the line; each call raises skeletons.", counter="Spread out when the ground glows; kill the skeletons it calls; pound it with artillery."),
    B("ossuary_matron", "boss", 8000, "bone", 16, 48, [W(id="matron_bolt", range=360, damage=40, dtype="necro", reload=2.0, targets="both", priority="threat", proj="bolt", splash=30, mount=[30, -170])],
      [ab("raise_ossuary", "Raise the Ossuary", "summon", 14, 1.2, enemy="ossuary_skeleton", count=5, cap=12), ab("aerial_escort", "Aerial Escort", "summon", 22, 1.0, enemy="skeletal_vulture", count=4, cap=8, air=True), ab("bone_ward", "Bone Ward", "ward", 26, 0.6, radius=200, mult=0.5, dur=7)],
      dict(fam="giant_cfg", base="ghoul_matriarch", tint="e2dac0", robe=True), 6.0, support=dict(interval=22, cap=10, waves=[["skeletal_vulture", 3], ["ossuary_skeleton", 3]]),
      desc="Necromantic matriarch wrapped in bone. Raises skeletons and sends vultures at your aircraft.", counter="Flak for the escorts; burst her down while the ward is down."),
    B("blightroot_behemoth", "boss", 14000, "hulk", 12, 56, [melee(180, 3.0, 110, id="behemoth_roots", splash=70, windup=0.6, mount=[60, -80]), W(id="thorn_storm", range=320, damage=24, dtype="pierce", reload=1.4, targets="both", priority="threat", proj="shard", burst=4, burst_gap=0.1, mount=[0, -220])],
      [ab("blight_snare", "Blight Snare", "zone", 14, 1.0, radius=130, dps=50, dur=8, offset=160, dtype="necro", slow=0.4, look="roots"), ab("root_quake", "Root Quake", "aoe", 20, 1.3, radius=230, damage=120, dtype="blast", knock=40, telegraph=True, min_targets=2)],
      dict(fam="giant_cfg", base="blackroot_abomination", tint="b0a080"), 7.0, desc="A corrupted forest walking on a giant's bones.", counter="Fire and range; stay out of the snares."),
    B("plague_regent", "boss", 13000, "hulk", 16, 50, [melee(160, 2.4, 80, id="regent_scepter", dtype="acid", splash=60, mount=[50, -80]), W(id="plague_volley", range=360, damage=40, dtype="acid", reload=2.2, targets="both", priority="armored", proj="spit", splash=40, mount=[40, -170])],
      [ab("plague_court", "Plague Court", "rally", 18, 0.8, radius=320, dur=8, mods={"fire": 1.4, "speed": 1.3, "dr": 0.85}), ab("pestilence", "Pestilence", "aoe", 22, 1.2, radius=220, damage=110, dtype="acid", telegraph=True, min_targets=2, pool=dict(dps=40, dur=7))],
      dict(fam="giant_cfg", base="plague_colossus", tint="d0d090", crown=True), 6.4, support=dict(interval=18, cap=12, waves=[["plague_mauler", 2], ["pestilent_soldier", 3]]),
      desc="An elite plague commander whose court fights harder near him.", counter="Shock and fire; kill the court."),
    B("gravewing_matriarch", "boss_air", 9000, "flesh", 70, 50, [W(id="matriarch_screech", range=340, damage=34, dtype="necro", reload=1.6, targets="both", priority="air", proj="bolt", splash=40, mount=[40, 0])],
      [ab("brood", "Brood", "summon", 14, 0.8, enemy="carrion_bat", count=6, cap=14, air=True), ab("screech_dive", "Screech Dive", "aoe", 18, 1.0, radius=180, damage=90, dtype="necro", stun=1.0, telegraph=True, min_targets=1)],
      dict(fam="fly_cfg", kind="bat", skin="3a2a3a", span=3.2, crown=True, h=50), 6.0, domain="air", altitude=[200, 260], standoff=160, arm=0.2,
      desc="A colossal bat-mother that fills the sky with her brood.", counter="Flak, flak, flak."),
    B("bone_wyrm", "boss_air", 15000, "bone", 60, 56, [W(id="wyrm_breath", range=320, damage=16, dtype="necro", reload=0.35, targets="both", priority="swarm", proj="bolt", splash=26, mount=[60, 10])],
      [ab("burrow_strike", "Burrow Strike", "aoe", 16, 1.4, radius=200, damage=150, dtype="blast", knock=40, telegraph=True, min_targets=1), ab("bone_rain", "Bone Rain", "aoe", 22, 1.0, radius=260, damage=80, dtype="pierce", telegraph=True, min_targets=2)],
      dict(fam="fly_cfg", kind="serpent", skin="e2dac0", span=2.6, h=50), 6.6, domain="air", altitude=[200, 260], standoff=140,
      desc="A skeletal wyrm that dives into the earth and erupts beneath your army.", counter="Spread out at the telegraph; heavy flak."),
    B("hollow_admiral", "boss_air", 16000, "machine", 22, 70, [shell(90, 460, 3.0, 40, id="ghost_broadside", mount=[40, 50], arc=[0, 170]), shell(90, 460, 3.4, 40, id="ghost_broadside_aft", mount=[-40, 50], arc=[0, 170]), W(id="ghost_flak", range=360, damage=20, dtype="necro", reload=0.6, targets="air", priority="air", proj="flak", splash=36, mount=[0, -70], arc=[-180, 180])],
      [ab("boarding_party", "Boarding Party", "summon", 18, 1.0, enemy="haunted_flying_machine", count=3, cap=8, air=True), ab("ghost_salvo", "Ghost Salvo", "aoe", 20, 1.2, radius=240, damage=110, dtype="blast", telegraph=True, min_targets=2)],
      dict(fam="corrupt", base="ironcloud", ghost=True), 3.4, domain="air", altitude=[170, 190], hold_range=380,
      desc="A drowned airship admiral and his ghost fleet.", counter="Gunships and flak batteries."),
    B("dread_sky_tyrant", "boss_air", 22000, "bone", 50, 70, [W(id="tyrant_breath", range=360, damage=28, dtype="necro", reload=0.35, targets="both", priority="swarm", proj="bolt", splash=34, mount=[70, 10]), W(id="tyrant_tail", range=200, damage=120, dtype="blast", reload=3.0, targets="air", priority="air", proj="bolt", splash=40, mount=[-60, 0])],
      [ab("sky_terror", "Sky Terror", "aoe", 18, 1.2, radius=260, damage=140, dtype="necro", stun=1.2, telegraph=True, min_targets=2), ab("drake_escort", "Drake Escort", "summon", 26, 1.0, enemy="bone_wyvern", count=2, cap=4, air=True)],
      dict(fam="fly_cfg", kind="drake", skin="cfc6a8", span=3.4, h=50), 7.0, domain="air", altitude=[190, 250], standoff=170,
      desc="A colossal bone tyrant of the skies.", counter="Every flak gun you own."),
    B("fallen_titan", "boss", 26000, "mech", 10, 56, [shell(300, 420, 6.0, 60, id="fallen_cannon", mount=[110, -170]), W(id="fallen_aa", range=300, damage=40, dtype="pierce", reload=1.6, targets="air", priority="air", proj="bullet", burst=4, burst_gap=0.08, mount=[40, -280], arc=[-178, 40])],
      [ab("corrupted_overdrive", "Corrupted Overdrive", "buff", 26, 0.6, dur=8, mods={"fire": 1.6}, cond="target"), ab("titan_stomp", "Titan Stomp", "aoe", 18, 1.2, radius=220, damage=180, dtype="blast", knock=46, telegraph=True, min_targets=2)],
      dict(fam="corrupt", base="deepforge_titan"), 6.4, arm=0.45,
      desc="A Deepforge Titan that fell to the rift and was raised.", counter="Shock, rail guns, and your own colossi."),
    B("ashen_forge_tyrant", "boss", 24000, "hulk", 12, 58, [melee(260, 3.2, 90, id="ashen_hammer", dtype="fire", splash=80, windup=0.8, mount=[60, -80]), W(id="slag_volley", range=380, damage=60, dtype="fire", reload=2.4, targets="both", priority="armored", proj="arc", splash=50, mount=[30, -200])],
      [ab("ash_storm", "Ash Storm", "zone", 14, 1.0, radius=150, dps=60, dur=8, offset=170, dtype="fire", look="fire"), ab("forge_fury", "Forge Fury", "buff", 24, 0.6, dur=8, mods={"fire": 1.5, "dr": 0.8})],
      dict(fam="giant_cfg", base="stitchback_giant", tint="a07060", furnace=True), 6.8, desc="An undead warlord wearing a captured forge.", counter="Shock and cold iron: AP cannons and rail guns."),
    B("corpse_colossus", "boss", 30000, "hulk", 8, 66, [melee(280, 3.4, 100, id="colossus_slam", dtype="blast", splash=100, windup=0.9, mount=[70, -60])],
      [ab("disgorge_horde", "Disgorge Horde", "summon", 12, 1.0, enemy="rotter", count=8, cap=20), ab("siege_slam", "Siege Slam", "aoe", 20, 1.4, radius=260, damage=200, dtype="blast", knock=50, telegraph=True, min_targets=1)],
      dict(fam="giant_cfg", base="corpse_mound", tint="b0a090"), 7.4, support=dict(interval=16, cap=16, waves=[["shambler", 4], ["fungal_host", 2]]),
      desc="A siege-mountain of the dead that spills hordes as it walks.", counter="Massed artillery; flame for the horde."),
    B("hollow_king", "boss", 28000, "heavy", 14, 52, [melee(200, 2.4, 80, id="hollow_blade", dtype="necro", splash=60, mount=[50, -80]), W(id="king_bolt", range=380, damage=50, dtype="necro", reload=1.8, targets="both", priority="threat", proj="bolt", splash=30, mount=[30, -180])],
      [ab("royal_summons", "Royal Summons", "summon", 14, 1.2, enemy="ossuary_champion", count=2, cap=6), ab("hollow_crown", "Hollow Crown", "ward", 22, 0.6, radius=260, mult=0.5, dur=8), ab("kings_doom", "King's Doom", "aoe", 24, 1.4, radius=240, damage=160, dtype="necro", stun=1.5, telegraph=True, min_targets=2)],
      dict(fam="giant_cfg", base="ossuary_juggernaut", tint="c0b070", crown=True), 6.2, support=dict(interval=20, cap=12, waves=[["hollow_guard", 2], ["dread_executioner", 1], ["crypt_hexer", 2]]),
      desc="The undead ruler and summoner, guarded by champions.", counter="Break the champions, then focus the King when the ward falls."),
    B("gravewing_sovereign", "boss_air", 30000, "flesh", 55, 70, [W(id="sovereign_screech", range=380, damage=50, dtype="necro", reload=1.4, targets="both", priority="air", proj="bolt", splash=50, mount=[60, 0])],
      [ab("sovereign_brood", "Sovereign's Brood", "summon", 12, 0.8, enemy="rotwing", count=4, cap=10, air=True), ab("wing_storm", "Wing Storm", "aoe", 16, 1.2, radius=300, damage=150, dtype="necro", stun=1.0, telegraph=True, min_targets=1)],
      dict(fam="fly_cfg", kind="bat", skin="2a2a3a", span=4.0, crown=True, h=50), 7.2, domain="air", altitude=[190, 250], standoff=170,
      desc="A sky-darkening winged sovereign.", counter="Flak arrays and superiority craft."),
    B("rift_lich", "boss", 34000, "light", 14, 56, [W(id="lich_rift_beam", range=420, damage=70, dtype="necro", reload=1.6, targets="both", priority="threat", proj="bolt", splash=40, mount=[40, -200]), zap(40, 360, 2.4, 5, id="lich_lightning", targets="both", priority="swarm", mount=[30, -180])],
      [ab("rift_legion", "Rift Legion", "summon", 12, 1.0, enemy="riftbound_legionary", count=4, cap=12), ab("rift_storm", "Rift Storm", "summon", 16, 1.0, enemy="rift_crow", count=6, cap=14, air=True), ab("annihilate", "Annihilate", "aoe", 22, 1.6, radius=280, damage=220, dtype="necro", telegraph=True, min_targets=2), ab("lich_ward", "Lich Ward", "ward", 28, 0.6, radius=260, mult=0.4, dur=7)],
      dict(fam="giant_cfg", base="rift_maw", tint="b090ff", robe=True, crown=True), 6.8, support=dict(interval=16, cap=16, waves=[["riftbound_legionary", 2], ["rift_crow", 4], ["night_seer", 1]]),
      desc="The final enemy: commands a ground legion and a sky storm at once.", counter="Everything you have, on both fronts."),
]


def build_bosses():
    out, kits = {}, {}
    for bid, e, kit in BOSSES:
        kits[bid] = kit
        out[bid] = e
    return out, kits
