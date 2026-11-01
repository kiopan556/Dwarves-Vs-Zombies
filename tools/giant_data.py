"""M002b — Undead Giants: the undead answer to the Iron Giants.

Twelve giant undead built from planned roster entries (stable IDs kept; nothing removed).
They mirror the four war-frame size classes so a Mountain Colossus has a Plague Colossus to fight:

    brute (light)  ~2.0x Rifleman   abomination (medium) ~2.85x
    behemoth (heavy) ~4.0x          colossus (colossal) ~5.6x

Stats are authored directly on the M001 scale (same scale as the normalised war frames).
Giants use the shared war-frame machinery (ARM%, multi-weapon targeting, staged death, ability
state machine) but their abilities run on necrotic cooldowns instead of Steam.
"""

RIFLEMAN_PX = 52.0
DESIGN_H = 110.0

CLASS = {
    "brute":       dict(rel=2.0,  radius=22, death=1.4, label="Brute"),
    "abomination": dict(rel=2.85, radius=29, death=1.8, label="Abomination"),
    "behemoth":    dict(rel=4.0,  radius=37, death=2.2, label="Behemoth"),
    "colossus":    dict(rel=5.6,  radius=52, death=3.0, label="Colossus"),
}
# size class -> the equivalent war-frame class (for UI / tests)
EQUIV = {"brute": "light", "abomination": "medium", "behemoth": "heavy", "colossus": "colossal"}

W = lambda **k: k

# anchor points on the 110-unit rig (x forward, y up negative)
A = {
    "front":  (34, -62),
    "fist":   (40, -40),
    "mouth":  (30, -88),
    "back":   (-10, -104),
    "top":    (0, -112),
    "horns":  (44, -50),
}


def _w(anchor, **k):
    k["anchor"] = anchor
    return k


GIANTS = {
    # ------------------------------------------------------------------ brutes
    "carrion_bull": dict(cls="brute", hp=820, arm=0.10, armor="hulk", speed=34, bounty=40, threat=10,
        weapons=[_w("horns", id="gore_horns", range=40, damage=48, reload=1.6, targets="ground", priority="nearest", proj="melee", dtype="melee", splash=30, windup=0.3, family="horns")],
        ability=dict(id="stampede", name="Stampede", kind="charge", cooldown=14, windup=0.6, dist=230, radius=50, damage=110, dtype="blast", knock=40),
        desc="A rotting bull the size of a war frame, crowned with grave-iron horns. It lowers its head and stampedes through a firing line.",
        weakness="Charges in straight lines; once it stops it is slow to turn. Shieldbearers and armor absorb the hit.",
        counter="Light Field Cannons and Copperbacks; keep infantry spread when it scrapes the ground."),
    "bone_golem": dict(cls="brute", hp=950, arm=0.25, armor="bone", speed=22, bounty=45, threat=11,
        weapons=[_w("fist", id="ossuary_clubs", range=40, damage=58, reload=2.0, targets="ground", priority="swarm", proj="melee", dtype="blast", splash=40, windup=0.45, family="club")],
        ability=dict(id="bonequake", name="Bonequake", kind="aoe", cooldown=16, windup=0.7, radius=110, damage=75, dtype="blast", knock=24, telegraph=True, min_targets=2),
        desc="Thousands of bones fused around a necrotic core. Bullets rattle through it; hammers and shells break it apart.",
        weakness="Bone frame: weak to blasts, drills and hammers.",
        counter="Grenadiers, Drillwalkers, field cannons."),
    "plague_beast": dict(cls="brute", hp=880, arm=0.10, armor="hulk", speed=24, bounty=42, threat=10,
        weapons=[_w("mouth", id="bile_spew", range=115, damage=10, reload=0.5, targets="ground", priority="swarm", proj="cone", dtype="acid", splash=5, family="spew"),
                 _w("fist", id="plague_claws", range=36, damage=30, reload=1.3, targets="ground", priority="nearest", proj="melee", dtype="melee", family="claws")],
        ability=dict(id="plague_pool", name="Plague Pool", kind="zone", cooldown=15, windup=0.5, radius=80, dps=30, dur=6, offset=125, dtype="acid", look="plague"),
        desc="A swollen beast that vomits corrosive bile in a wide cone and leaves boiling plague pools behind.",
        weakness="Short reach; dies fast to concentrated rifle and cannon fire before it closes.",
        counter="Range: Riflemen, Organ Guns, Cannon Striders. Keep machines out of its pools."),
    # ------------------------------------------------------------------ abominations
    "stitchback_giant": dict(cls="abomination", hp=1600, arm=0.20, armor="hulk", speed=22, bounty=70, threat=16,
        weapons=[_w("fist", id="butcher_cleavers", range=48, damage=70, reload=2.0, targets="ground", priority="armored", proj="melee", dtype="melee", splash=36, windup=0.4, family="cleaver")],
        ability=dict(id="butchers_flurry", name="Butcher's Flurry", kind="strike", cooldown=14, windup=0.5, mult=1.1, hits=3),
        desc="A giant sewn together from the fallen of three wars, swinging a pair of slaughterhouse cleavers.",
        weakness="Pure melee: artillery and frames with reach wear it down before it arrives.",
        counter="Mortar Walkers, Cannon Striders, Anvilbreaker."),
    "ossuary_juggernaut": dict(cls="abomination", hp=1900, arm=0.35, armor="bone", speed=20, bounty=80, threat=18, taunt=True, front_guard=0.3,
        weapons=[_w("fist", id="bone_maul", range=46, damage=66, reload=2.2, targets="ground", priority="nearest", proj="melee", dtype="blast", splash=40, windup=0.5, family="maul")],
        ability=dict(id="coffin_rush", name="Coffin Rush", kind="charge", cooldown=18, windup=0.6, dist=200, radius=55, damage=130, dtype="blast", knock=50),
        desc="A skeletal knight-giant behind a coffin-lid shield. Frontal shots splinter on the lid; it draws your fire and then rushes.",
        weakness="The shield only covers its front. Mortars, bombers and drills get around it.",
        counter="Mortar Walkers, Bombard Gyros, Drillwalkers."),
    "corpse_mound": dict(cls="abomination", hp=2100, arm=0.10, armor="hulk", speed=14, bounty=75, threat=16,
        weapons=[_w("fist", id="corpse_slam", range=50, damage=60, reload=2.6, targets="ground", priority="swarm", proj="melee", dtype="blast", splash=55, windup=0.7, family="slam")],
        ability=dict(id="disgorge", name="Disgorge", kind="summon", cooldown=12, windup=0.8, enemy="rotter", count=3, cap=9),
        desc="A walking heap of the dead. Every few seconds it heaves and fresh Rotters crawl out of it.",
        weakness="Very slow. Kill it quickly or the Rotters it spawns keep piling up.",
        counter="Focus fire: cannons, Thundercoil arcs, flame frames."),
    "ghoul_matriarch": dict(cls="abomination", hp=1350, arm=0.15, armor="hulk", speed=30, bounty=70, threat=16,
        weapons=[_w("fist", id="matriarch_claws", range=46, damage=44, reload=1.1, targets="ground", priority="nearest", proj="melee", dtype="melee", family="claws"),
                 _w("mouth", id="carrion_shriek", range=190, damage=22, reload=1.8, targets="both", priority="air", proj="spit", dtype="necro", splash=16, family="shriek")],
        ability=dict(id="feeding_call", name="Feeding Call", kind="rally", cooldown=20, windup=0.6, radius=240, dur=7, mods={"fire": 1.35, "speed": 1.3}),
        desc="A long-limbed ghoul queen. Her shriek knocks aircraft out of the sky and whips the undead around her into a frenzy.",
        weakness="Lightly armored for her size; her rally is strongest in a crowd, so thin the horde first.",
        counter="Organ Guns and Flak against her escorts; Ironclad Walkers to pin her."),
    # ------------------------------------------------------------------ behemoths
    "cathedral_ghast": dict(cls="behemoth", hp=2600, arm=0.30, armor="bone", speed=17, bounty=120, threat=24,
        weapons=[_w("fist", id="bell_flail", range=70, damage=110, reload=3.0, targets="ground", priority="swarm", proj="melee", dtype="blast", splash=60, windup=0.8, family="flail"),
                 _w("back", id="dirge", range=300, damage=38, reload=1.6, targets="air", priority="air", proj="bolt", dtype="necro", splash=30, family="dirge")],
        ability=dict(id="funeral_toll", name="Funeral Toll", kind="aoe", cooldown=22, windup=1.1, radius=170, damage=80, dtype="necro", stun=1.6, telegraph=True, min_targets=3),
        desc="A robed horror carrying the bell tower of a fallen cathedral. Its dirge blasts aircraft; when the bell tolls, everything near it freezes.",
        weakness="Slow wind-up on the Toll. Pull your infantry back when the ground glows.",
        counter="Cannon Striders and Siegebellows from range; Skyguard escorts for your aircraft."),
    "blackroot_abomination": dict(cls="behemoth", hp=2900, arm=0.25, armor="hulk", speed=15, bounty=125, threat=24,
        weapons=[_w("fist", id="root_lash", range=95, damage=85, reload=2.4, targets="ground", priority="armored", proj="melee", dtype="melee", splash=45, windup=0.6, family="roots"),
                 _w("back", id="thorn_volley", range=260, damage=18, reload=1.4, targets="both", priority="threat", proj="shard", dtype="pierce", burst=3, burst_gap=0.12, family="thorns")],
        ability=dict(id="rootsnare", name="Rootsnare", kind="zone", cooldown=18, windup=0.9, radius=95, dps=40, dur=7, offset=130, dtype="necro", slow=0.5, look="roots"),
        desc="A corrupted forest grown through a giant's corpse. Root lashes reach past your front line and thorn volleys hit air and ground alike.",
        weakness="Fire. Its roots burn and it cannot outrun anything.",
        counter="Furnace Stalkers, Embercore Titan, Grenadiers; fight it outside the snare."),
    "walking_crypt": dict(cls="behemoth", hp=2700, arm=0.35, armor="bone", speed=14, bounty=120, threat=24,
        weapons=[_w("fist", id="crypt_lid", range=60, damage=95, reload=2.8, targets="ground", priority="nearest", proj="melee", dtype="blast", splash=55, windup=0.7, family="slab"),
                 _w("back", id="bone_catapult", range=340, min_range=120, damage=70, reload=4.5, targets="ground", priority="swarm", proj="arc", dtype="blast", splash=45, family="catapult")],
        ability=dict(id="open_the_crypt", name="Open the Crypt", kind="summon", cooldown=16, windup=1.0, enemy="ossuary_skeleton", count=3, cap=9),
        desc="A hunched giant hauling a family crypt. The catapult on top lobs bone; the doors open to let skeletons out.",
        weakness="Its catapult can't hit anything close. Get under it with heavy frames.",
        counter="Anvilbreaker, Siege Hammer Walker, bombers."),
    # ------------------------------------------------------------------ colossi
    "plague_colossus": dict(cls="colossus", hp=6200, arm=0.30, armor="hulk", speed=11, bounty=300, threat=45,
        weapons=[_w("fist", id="colossal_fist", range=60, damage=280, reload=4.5, targets="ground", priority="armored", proj="melee", dtype="blast", splash=75, windup=0.9, family="fist"),
                 _w("back", id="spore_geyser", range=320, damage=60, reload=2.2, targets="air", priority="air", proj="spit", dtype="acid", splash=40, family="geyser"),
                 _w("mouth", id="bile_mortar", range=380, min_range=140, damage=90, reload=5.0, targets="ground", priority="swarm", proj="spit", dtype="acid", splash=55, family="mortar")],
        ability=dict(id="plague_nova", name="Plague Nova", kind="aoe", cooldown=30, windup=1.4, radius=200, damage=160, dtype="acid", telegraph=True, min_targets=3, pool=dict(dps=35, dur=6)),
        desc="A mountain of plague. Spore geysers on its back hunt aircraft, its belly lobs bile at range and its nova melts frames.",
        weakness="Acid-proof hide but very slow. Shock and fire hurt it; its geysers fire up, not down.",
        counter="Thundercoil Frames, Embercore Titan, massed artillery."),
    "rift_maw": dict(cls="colossus", hp=6800, arm=0.35, armor="hulk", speed=12, bounty=320, threat=48,
        weapons=[_w("fist", id="maw_bite", range=64, damage=320, reload=4.0, targets="ground", priority="armored", proj="melee", dtype="melee", splash=60, windup=0.8, family="maw"),
                 _w("top", id="rift_bolt", range=340, damage=75, reload=2.4, targets="both", priority="threat", proj="bolt", dtype="necro", family="rift")],
        ability=dict(id="devour", name="Devour", kind="strike", cooldown=22, windup=0.7, mult=2.5, heal=0.6),
        desc="A colossus whose torso is one enormous mouth. Rift bolts hit anything in reach, and when it devours a frame it heals.",
        weakness="Devour needs a target in reach. Keep big frames out of its mouth and hit it from range.",
        counter="Siegebellow, Cannon Striders, Deepforge Titan."),
}


def build_giants():
    out = {}
    for uid, g in GIANTS.items():
        c = CLASS[g["cls"]]
        art_scale = round(c["rel"] * RIFLEMAN_PX / DESIGN_H, 3)
        weps = []
        for w in g["weapons"]:
            w = dict(w)
            ax, ay = A[w.pop("anchor")]
            if w["proj"] == "melee":
                w["mount"] = [round(c["radius"] * 0.9, 1), round(ay * art_scale * 0.7, 1)]
            else:
                w["mount"] = [round(ax * art_scale, 1), round(ay * art_scale, 1)]
            if w["targets"] in ("air", "both"):
                w["arc"] = [-178, 40]
            w["range"] = float(w["range"])
            weps.append(w)
        ab = dict(g["ability"])
        ab["steam"] = 0
        e = dict(cls="monster", domain="ground", role="giant_" + g["cls"], hp=g["hp"], arm=min(0.5, g["arm"]), armor=g["armor"],
                 speed=g["speed"], radius=c["radius"], bounty=g["bounty"], threat=g["threat"], behavior="giant", art=uid,
                 art_scale=art_scale, giant_class=g["cls"], mech_class=EQUIV[g["cls"]], death_time=c["death"], blocks=True, frontline=True,
                 weapons=weps, ability=ab, weakness=g["weakness"], desc=g["desc"], counter=g["counter"])
        for k in ("taunt", "front_guard"):
            if k in g:
                e[k] = g[k]
        out[uid] = e
    return out
