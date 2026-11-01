# MASTER DEVELOPMENT PROMPT
# DWARVES VS ZOMBIES
## M006c — FORGED APART: EVERY TANK ITS OWN MACHINE

Version 0.6.2-M006c (Android version code 9). A visual-only patch on top of M006b (0.6.1).

---

# 0. HOW TO USE THIS PROMPT
Read §1–§3 before touching code. §4 is the design bible: one entry per vehicle, each a different machine, not a
recolour. Build the shared parts library (§5) first, then the 24 designs plus the corrupted Gravegun, then verify
(§7) and deliver (§9). Every claim in the report must come from something that was run or looked at.

# 1. WHY THIS PATCH
M006b gave every tank shaded plates, a real running gear, a commander and firing animation — but all 24 kit vehicles
still come out of **one hull painter**: the same lower hull, the same casemate, the same skirt, the same sloped turret,
scaled by length and repainted. Lined up, they read as one tank in 24 coats. Players pick units by silhouette on a
small phone screen; a tank must be recognisable from its outline alone, at thumbnail size, in a crowd.

Goal: **24 visually unique vehicles** (plus the corrupted Gravegun) whose hull shape, proportions, running gear,
turret form and signature fittings differ, with a clear **size ladder** from a buggy you could park in a mine
cart to a land-battleship — and every one of them unmistakably **dwarven**.

# 2. INVIOLABLE RULES
1. **Visual only.** No unit id, stat, weapon, behaviour, radius, aim height (`h`), hit box or data parameter changes.
   `data/art_kit.json` is not edited; designs live in a new art-side table keyed by art id. A stage-sim sample must
   give identical results to M006b.
2. **Keep the animation language of M006b**: running gear driven by `walk`, firing by `atk/atk2/atk3` (barrel
   slide, turret rock, flash, smoke, case), commander who ducks, exhaust, dirt, antenna, damage states at 50 % / 25 %.
   **No new pose keys.** The pose-cache budget (3 damage states) stays.
3. **Re-measure bounds** for every vehicle after the change (`tests/bounds.tscn -- --machines`).
4. **Original designs.** No copying of real-world tank models or other games' vehicles; draw inspiration from
   dwarven craft (forges, boilers, mine carts, anvils, halls, battlements, runes), not from any franchise.
5. **Readable at phone size**: the silhouette carries identity; detail is secondary.
6. **Performance**: Low/Balanced frame time within +10 % of M006b on the machines bench; High within +10 % of
   M006b; per-art live-draw cost ≤ 2× M006b's (the M006b painter is already rich).
7. **Honest reporting**: limits stated plainly; nothing run on a phone is claimed.

# 3. WHAT MAKES A TANK DWARVEN (shared language)
- **Built, not stamped**: riveted plate seams, bolted bands, brass trim against dark iron, copper pipes.
- **Steam and fire**: boilers, domes, chimneys and stacks with flared brass caps, pressure gauges, firebox glow.
- **Hold architecture**: battlements, arched hatches, stone-grey plates on the fortress machines, tower turrets.
- **Craft motifs**: anvil, hammer, mountain peak and rune bands (glowing on rune-tech machines) — used as emblems,
  never as text.
- **Crew**: bearded heads in hatches, gunners at open mounts, a driver behind a vision slit, passengers peeking.
- **Stowage**: barrels of ale (yes), tool racks, spare wheels and track links, crates, coal sacks.
- **Proportions**: low and wide, heavy at the bottom, short and stubborn rather than long and sleek — except the
  two hunter designs, which are deliberately long and low.

# 4. THE DESIGN BIBLE — 24 + 1 MACHINES
Size = visual hull length in art units (the M006b hull used the data `len`). The ladder runs 42 → 146. Weight
class drives track height and detail density. Running gear types: **wheels** (spoked, traction-engine style),
**halftrack**, **tracks** (with a road-wheel style), **rhomboid** (tracks running round the whole hull),
**bogies** (two or three separate track units under an articulated hull).

| # | Vehicle | Size | Chassis | Hull silhouette | Turret / weapon form | Signature fittings |
|---|---|---|---|---|---|---|
| 1 | Coalrunner Scout Tank | 42 | 3 wheels: big rear pair, small front steering wheel | Open coal-cart tub on a frame | Pintle MG on a post, gunner exposed | Tall flared chimney, goggled driver, coal sack, pennant whip |
| 2 | Steamwheel APC | 58 | 6 spoked wheels with mudguards | Tall riveted box with sloped roof edges and an arched side door | Small round MG cupola | Firing ports with rifle barrels, roof hatch with a passenger, rear boiler drum |
| 3 | Ironrunner Light Tank | 56 | Tracks, 4 large road wheels | Low **wedge** with a sharp beak | Small round dome turret set forward | Side exhaust pipe along the fender, shovel, short antenna |
| 4 | Flamebelcher Medium Tank | 60 | Tracks, small wheels | **Bulbous furnace body**, rounded like a stove | Squat ball-mantlet flame turret | Two fuel cylinders on the back with hazard bands, glowing firebox grate in the nose |
| 5 | Ironclad Medium Tank | 68 | Tracks, 5 road wheels | Classic **stepped casemate**, sloped sides | Sloped box turret | Spare wheel, sandbag line, rivet bands — the "standard" dwarven tank |
| 6 | Skyshield AA Tank | 62 | **Halftrack**: front spoked wheel pair + rear track | Low chassis with an **open gun tub** ringed by railing | Twin AA guns on a pedestal, exposed loader | Ammo racks, ring sight, spotter's periscope |
| 7 | Thunderback Heavy Tank | 80 | Tracks, 6 wheels, skirts | **Humped turtle back**: big boiler dome over the rear | Heavy turret forward of the hump | Two steam vents on the dome, pressure gauge, lightning-bolt rune |
| 8 | Bastion Heavy Tank | 80 | Tracks, skirts | **Castle wall**: vertical sides, crenellated parapet | **Tower turret** with battlements | Arrow-slit vision ports, applique plates, a banner |
| 9 | Siege Sapper Tank | 72 | Tracks | Engineer hull with a **dozer blade** in front | Short fat petard mortar in a boxy casemate | Crane jib with a hook, demolition charge rack, hazard stripes |
| 10 | Boiler Ram | 82 | Tracks + big drive flywheel | **Horizontal locomotive boiler** laid on the tracks | No turret | Front smokestack, steam dome, spiked ram prow, connecting rod turning a flywheel |
| 11 | Twin-Cannon Ironclad | 86 | Tracks, long and low | **River-monitor hull** with a flat deck and pointed bow | Wide flat turret with twin barrels | Side sponson, deck railing, anchor-shaped tow hook |
| 12 | Sniper Tank Hunter | 84 | Tracks, low, many small wheels | **Turretless low casemate**, very long and flat | Long gun fixed in the front plate | Camo netting tufts, scope housing, barrel travel lock |
| 13 | Steamtread Heavy Carrier | 92 | **Rhomboid** tracks around the hull | Tall carriage box with an arched roof | Small MG cupola | Row of portholes with passengers peeking, rear ramp door, barrels on the roof |
| 14 | Siegecrawler | 104 | **Two bogies**, articulated | Two-section hull: a front cab and a rear **mortar kiln** | Big mortar in an open pit | Twin chimneys, ladder, shell crates |
| 15 | Mountainshield Heavy Tank | 94 | Tracks, skirts | Heavy hull behind a **giant tower-shield plate** with an anvil emblem | Heavy turret behind the shield | MG sponson, shield rivets in a ring |
| 16 | Thunderrail Tank Destroyer | 92 | Tracks, low | **Long low capacitor deck** | Rail gun on a centre-line mount, coil rings along the barrel | Glowing capacitor spheres, cable runs, rune band |
| 17 | Firestorm Assault Tank | 90 | Tracks, skirts | **Broad armoured box** with heat-shield fins on the sides | Two flame turrets, fore and aft | Four fuel tanks, exhaust manifold, scorched glacis |
| 18 | Dreadplate Breaker | 94 | Tracks | **Wedge of overlapping scale plates** | Heavy turret | Huge **rotating drill cone** on the nose |
| 19 | Mobile Flak Fortress | 96 | Tracks, skirts | **Tall stepped fortress** with two raised gun decks | Two AA mounts on the decks, fore and aft | Ladders, searchlight, rangefinder bar |
| 20 | Mountainbreaker | 118 | Tracks, 3 bogie groups | **Terraced super-heavy** stepped like a mountainside | Very long gun on a low wide turret | Mountain-peak emblem, stowage on each terrace |
| 21 | Worldhammer Siege Tank | 108 | Tracks + flywheel | **Forge hull** with an anvil front | The great hammer arm (M006 hammer turret) | Piston flywheel, forge glow window, chimney |
| 22 | Brass Leviathan | 128 | **Two bogies** | **Brass warship hull** on tracks: bow, portholes, deckhouse | Two turrets (heavy fore, cannon aft) | Two banded funnels, mast with flag |
| 23 | Iron Bastion Prime | 118 | **Two bogies** | **Two-tier castle**: gatehouse, wall, keep | Heavy turret on top of the keep | Battlements on both tiers, two banners, gate |
| 24 | Dreadnought Landship | 146 | **Three bogies** | **Land battleship**: long hull with a bridge tower | Three turrets (two heavy, one AA) | Bridge with windows and crew, two funnels, mast with crow's nest |
| C | Gravegun Tank (corrupted) | 80 | Tracks, broken skirts | A **wrecked, overgrown dwarven heavy** with torn plates | Heavy turret | (corruption overlay from `_corrupt` stays) |

Commander placement follows the turret form: in the hatch of box/round/tower turrets, at the guns of open mounts,
in a deck hatch of turretless designs.

# 5. SHARED PARTS LIBRARY (`scripts/art/art_tanks.gd`, class `ArtTanks`)
- **Design table** `D` keyed by art id; `draw(ci, a, art, p)` called from `ArtKit._veh` when a design exists
  (falls back to the M006b painter otherwise).
- **Hull** from a normalised profile (points in hull-length/height units) with generic banded shading (shadow /
  base / lit crown) so any silhouette gets form shading.
- **Running gear**: `wheels`, `halftrack`, `tracks` (wheel style: big / medium / small), `rhomboid`, `bogies`.
- **Turret forms**: `box`, `round`, `tower`, `tub` (open), `flat` (wide), `none`/casemate gun, `hammer` (legacy).
- **Fittings**: chimney, dome, vents, fuel tanks, crenels, dozer blade, drill, ram prow, tower shield, sponson,
  portholes with heads, ramp, firing ports, capacitors, coils, searchlight, ladder, banner, spare wheel, barrels,
  crates, camo, emblem (anvil, hammer, peak, bolt, rune), flywheel and rod, funnels, mast, bridge, railings, crane.
- Reuse M006b behaviour: turret weapons (barrels, flash, smoke, case), commander, antenna, dirt, exhaust smoke,
  damage states.

# 6. PERFORMANCE
Bench `--mix=machines` and the default crowd on Low, Balanced and High before (M006b) and after; live-draw cost per
vehicle with `tests/artcheck.tscn -- --cost_only`. Budgets in §2.6.

# 7. TESTS AND ACCEPTANCE
- **Silhouette uniqueness** (new `tests/silhouettes.tscn`): render every vehicle's idle silhouette at a common scale,
  aligned on the ground centre; the pairwise overlap (IoU) of every pair must drop well below M006b's. Target: no pair
  above **0.80**, and the median pair clearly lower than before. Report before/after numbers and a silhouette sheet.
- Every vehicle design exists (24 + Gravegun) and draws in all 18 `art_m006b` states; `artcheck` passes (bounds,
  moving parts).
- All suites pass with 0 script errors; stage sample 010/040/062/070/080/090 identical.
- Before/after tank sheets looked at by eye; one sheet per weight class at a larger scale.

# 8. TOOLS
`tests/artsheet.tscn` (`--group=tanks`), `tests/silhouettes.tscn` (new), `tests/artcheck.tscn`, `tests/bounds.tscn --
--machines`, bench `--mix=machines`, screenshot `--shot=sandbox --machines` for a clip.

# 9. DELIVERY
1. `docs/IMPLEMENTATION_REPORT_M006c.md`: the 25 designs (what makes each unique), before/after sheets, silhouette
   numbers, performance, tests, limits.
2. README "What is new in M006c"; screenshots `docs/screenshots/m006c_*.png`; a short clip.
3. Version 0.6.2-M006c (version code 9); signed debug APK, Linux build smoke test, project ZIP. Save this prompt and
   the report to the project docs.
