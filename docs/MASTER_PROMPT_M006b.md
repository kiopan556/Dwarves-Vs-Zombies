# MASTER DEVELOPMENT PROMPT
# DWARVES VS ZOMBIES
## M006b — IRON & SKY: THE MACHINE VISUAL OVERHAUL

**Project:** Dwarves vs Zombies
**Engine:** Godot 4.3, GDScript, GL Compatibility renderer
**Platform:** Android first; desktop for development
**Milestone:** M006b — a visual-only patch between M006 (War for the Skies) and M007 (The Fallen Foundries)
**Builds on:** the M006 project (0.6.0-M006)

---

# 0. HOW TO USE THIS PROMPT

Work on the M006 project. Before changing art:

1. Read `scripts/art/painter.gd` (core helpers, `xf_push`/`xf_pop`), `scripts/art/art_kit.gd` (`_veh`, `_air`,
   `_ship`, `_corrupt`), `scripts/art/art_machines.gd`, `scripts/art/art_air.gd`, `scripts/art/art_mechs.gd`, and the
   pose cache (`scripts/core/pose_cache.gd`, `Unit.make_pose`).
2. Render the "before" art sheets (`tests/artsheet.tscn`, §9) for tanks, aircraft, airships and all 28 war frames in
   every pose listed in §6, and keep them for the report.
3. Run the test suites once for a green baseline.

Work through the patch without stopping for approval. Keep a task list; finish with an honest report.

---

# 1. WHY THIS PATCH

M006 gave every unit a smooth motion layer and gave war frames a heel-toe gait. Rendering the machine roster side by
side shows what is still missing:

- **Tanks** (24 kit vehicles) are one sloped box, a small dome turret and a plain track band. Light, medium, heavy and
  super-heavy tanks differ mostly in length and colour.
- **Aircraft** (18 kit aircraft) are a flat fuselage polygon, a stick propeller and a pilot head.
- **Airships** (11 kit airships) all share the same cream gas bag and gondola: a scout blimp and a dreadnought look
  alike except for size.
- **War frames** (28) walk well now, but their combat animation is thin: stance barely changes when engaged, melee
  swings are a straight interpolation that plays *after* the hit, guns have no muzzle climb, and recovery after a blow
  is mostly a whole-body spring.

The design pillars say dwarven machinery "must feel heavy, powerful, and distinctly mechanical", and the art "must
remain clear and readable even during large battles on small mobile screens". This patch delivers that for every
machine on the dwarven side.

---

# 2. INVIOLABLE RULES (unchanged from M006, restated where they bite)

1. **Visual only.** No stat, behaviour, targeting, timing or stage change. Art must never feed gameplay: unit height for
   aim points comes from data (`h`), not from drawn geometry. Prove it: the stage sims for a sample of stages must
   produce the same results as M006 and the `motion` determinism test must still pass.
2. **Never remove or rename** a unit, art id or kit parameter. Existing kit parameters keep their meaning; new optional
   parameters get defaults so data that does not set them still draws.
3. **Low-end Android first.** Everything still goes through the pose cache: one textured quad per unit on Balanced and
   Performance. Keep the set of pose keys each art reads small — a new animation must reuse existing quantized keys
   (`t`, `walk`, `state`, `atk*`, `windup`, `aim*`, `recoil`, `gag`, `engage`, `hp_frac`, `ability_anim`,
   `stun_t`, `brace_t`, `spin`) rather than invent per-frame inputs. No new shaders, no per-unit viewports.
4. **Bounds.** Re-measure `data/art_bounds.json` after the art changes; no pose may be clipped by its atlas cell.
5. **Tone.** Machines are heavy and serious (the slapstick layer stays with infantry). Undead stay frightening:
   corrupted dwarven machines inherit the new detail but keep their rusted, ghost-lit corruption treatment.
6. **Original art only.** No real-world vehicle copied plate for plate; dwarven industrial fantasy throughout.
7. **Honest reporting.** No device claims; before/after sheets and numbers in the report.

---

# 3. SHARED RENDERING LANGUAGE (all machines)

- **Form shading**: every major hull, envelope, fuselage and torso plate gets a lit top band and a shadowed lower band
  (two extra polygons, not gradients), panel seams and rivet rows. Light comes from the upper left of the screen,
  mirrored automatically with facing.
- **Readable silhouettes by weight class**: light machines are slim and tall-wheeled; medium are boxy; heavy are wide
  with skirt armour; super-heavy/colossal are multi-tiered with secondary turrets. A player must tell a light from a
  heavy tank at phone size by silhouette alone.
- **Crew**: dwarves are visible where it makes sense (tank commanders in hatches, pilots with goggles and scarves,
  airship bridge and deck crews), drawn small and simple so they read as life, not clutter.
- **Mechanical life**: something always moves — tracks and wheels, propellers and rotors (with motion-blur discs),
  pistons, exhaust and steam. Movement is driven only by existing pose keys.
- **Damage states**: below 50 % health a machine smokes and shows scorch/dents; below 25 % it shows fire flicker.
  Uses the existing `hp_frac` bins only.

---

# 4. TANKS AND GROUND VEHICLES (`ArtKit._veh`, 24 kit vehicles)

Hull types `tracked`, `wheeled`, `crawler` keep their parameters (`len`, `ht`, `coat`, `turrets`, `plates`, `ram`,
`hatch`). Deliver:

- **Hull**: upper glacis, superstructure and lower hull as separate shaded planes; side skirt armour over the tracks
  on medium and heavier hulls (weight class from `len`); vision slits, a headlamp, tow hooks, spare track links or tool
  racks, engine deck grille and exhaust stacks.
- **Running gear**: toothed drive sprocket and idler that rotate with `walk`; road wheels with rotating hub bolts;
  return rollers; a track whose top run and bottom run visibly travel in opposite directions; a slight track sag.
  Wheeled hulls get chunky spoked wheels, mudguards and visible leaf springs. Crawlers get two articulated track units
  (front and rear bogies).
- **Turrets** by kind (`cannon`, `heavy`, `long`, `rail`, `twin`, `mg`, `flame`, `aa`, `mortar`, `hammer`): a proper
  sloped turret with mantlet and cupola, barrels with muzzle brakes and bore evacuators where they fit, AA mounts with
  ring sights. Super-heavy hulls carry a secondary turret.
- **Commander**: a dwarf in the cupola hatch who looks about at idle and ducks when the main gun fires.
- **Firing animation** (from `atk`): the barrel slides back into the mantlet, the turret rocks back, muzzle flash then a
  drifting smoke ring, a spent case thrown from the turret; flamers throw a cone that flickers; mortars belch smoke.
  (The motion layer already rocks the whole hull.)
- **Movement**: dirt thrown behind tracks, exhaust belching harder under way.
- **Damage**: smoke from the engine deck below 50 %, flames below 25 %.
- The two legacy M001 vehicles (Copperback, Brasshound) keep their art but gain the shared damage states.

---

# 5. AIRCRAFT (`ArtKit._air`, 18 kit aircraft) AND AIRSHIPS (`ArtKit._ship`, 11 kit airships + supply barge)

## 5.1 Aircraft (frames `rotary`, `twin_rotor`, `gunship`, `winged`, `bomber`)
- Shaded fuselage with a framed open cockpit, cowling, exhaust stacks with flame flicker, a tail with fin and rudder,
  landing skids (rotorcraft) or a tail skid (winged).
- **Pilot** with goggles and a scarf that streams and flutters (`t`).
- **Rotors and propellers**: a translucent motion-blur disc plus two visible blades rotating by `t`, a brass hub.
- **Wings** (winged/bomber): ribbed wings, a strut-braced upper wing on bombers, wing-mounted engines on bombers.
- **Weapons**: guns kick back on firing with muzzle flash and ejected casings; bomb racks show the loaded bombs and empty
  as `ammo` runs down; rocket pods smoke after a launch; flamers flicker.
- **Damage**: a trailing smoke plume below 50 %, flickering engine fire below 25 %.

## 5.2 Airships
Every airship must be recognisable by silhouette. Keep the parameters (`len`, `coat`, `guns`, `deck`, `hammer`,
`coils`, `flak`, `cargo`, `ghost`, `glow`) and derive the class from `len`:
- **Envelope**: shaded gas bag (lit crown, shadowed belly), longitudinal girders and gore seams, a brass nose cap, a
  coloured hull band in the ship's `coat` with a dwarven hammer-and-anvil emblem, tail fins with moving rudder and
  elevators.
- **Rigging** from envelope to gondola; **engine pods** on outriggers with spinning propellers (more pods on bigger
  ships); a pennant streaming from the stern.
- **Gondola/hull**: a ship-like keel with portholes that glow, a bridge with windows, railings, deck crew.
  Carriers (`deck`) get a flight deck with runway markings and a parked gyro; battleships (`hammer`) the great ram
  hammer; rune ships (`coils`) glowing coil arrays; the largest ships (len ≥ 230) carry a second, upper envelope.
- **Broadside guns** recoil and leave smoke when firing.
- Corrupted airships (Infected Airbarge, the Hollow Admiral's flagship) inherit the detail through `_corrupt` with the
  ghost palette.

---

# 6. WAR FRAMES — EVERY ONE, EVERY STATE (`ArtMechs`, 28 frames)

Every frame must have readable, distinct animation for each state below. Use the existing pose keys only.

| State | Key(s) | Required |
|---|---|---|
| **Travel / idle stance** | `state`, `t`, `engage`=0 | relaxed, upright; boiler breathing; head scans slowly; weapon arm carried low/port |
| **Combat stance** | `engage`=1 | feet wider, knees bent, torso leaning into the enemy; arms take the family's guard (fists up, gun shouldered and aimed, shield forward, claws spread, hammer at the ready) |
| **Wind-up / anticipation** | `windup` | a clear coil before heavy blows: arm drawn back or raised overhead, torso twisted back, weight on the back foot |
| **Strike** | `atk` 1.0 → 0.75 | the blow lands in the first quarter of the timeline (not spread over it): fast arc with a motion smear for melee; recoil kick and muzzle climb for guns; flame/steam burst |
| **Follow-through** | `atk` 0.75 → 0.4 | overshoot past the impact and hold; impact dust/sparks |
| **Recovery** | `atk` < 0.4, `gag` | arm springs back to the guard with overshoot, vents dump steam, brass casings tumble, heat shimmer; heavy frames recover slower |
| **Ability** | `ability_anim` | power pose: arms flexed, vents and runes glowing |
| **Stunned** | `stun_t` | slumped: head down, arms hanging, sparks |
| **Bracing** | `brace_t` | wide planted stance (mortar, siege, flak frames) |

Families to cover (every family used by the 28 frames): `claw`, `big_claw`, `fist`, `big_fist`, `gauntlet`, `grabber`,
`drill`, `piston_hammer`, `hammer2`, `axe2`, `tower_shield`, `buckler`, `emitter_arm`, `cannon`, `titan_cannon`,
`repeater`, `rotary`, `flamer`, `flamer_big`, `vent`, support arms (`brace`, `bracer`, `stub`, `loader_arm`), and
mounts (`aa_twin`, `aa_quad`, `aa_heavy`, `shoulder_cannon`, `siege_cannon`, `mortar`) plus chest guns.
Mounts recoil and smoke when they fire, and their crewless barrels track `aim*`.

Corrupted frames (Cursed Ironclad, Possessed Drillwalker) inherit the animation through `_corrupt`.

---

# 7. PERFORMANCE BUDGET
- Pose keys: each art may add at most the keys listed in §2.3; report the key set per family before/after.
- Bench (`tests/bench.tscn --quality=low`) the M006 crowd, a tank-heavy crowd, an air-peak crowd and an
  airship-heavy crowd, before and after. Budget: frame ≤ +10 %, draw calls ≤ 600 at steady state.
- Live-draw cost (High preset, no cache) per art: measure and report the slowest arts; nothing may exceed 3× its
  M006 cost.

# 8. TESTS AND ACCEPTANCE
- All M006 suites pass with 0 script errors (registry, combat, boss, ui ×2, mecha ×4, giants ×2, roster ×2,
  bosses_all, hazards ×2, boss_phases ×2, air_war, motion, stars, saves).
- A stage-sim sample (e.g. 010, 040, 062, 070, 080, 090) gives the same results as M006 (visual-only proof).
- **New `art_m006b` suite**: every machine art draws in every pose of §6 without errors and with geometry inside its
  measured bounds; every war frame's weapon hand position differs between stance, wind-up, strike and recovery (the
  animation actually moves); vehicle running gear and propellers change between `walk`/`t` samples.
- Before/after art sheets for tanks, aircraft, airships and all war frames in every §6 state, looked at by eye.

# 9. TOOLS
- `tests/artsheet.tscn`: labelled grid of arts in one pose (`--group=tanks|aircraft|airships|mechs|corrupted`,
  `--pose=key:value,…`). Use it for every before/after comparison.
- `tests/walkstrip.tscn`: walk cycles.
- `tests/screenshot.tscn` with `--clip=N` for short battle clips.

# 10. DELIVERY
1. `docs/IMPLEMENTATION_REPORT_M006b.md`: what changed per machine class and per mech family, before/after sheets,
   performance before/after, tests, honest limits.
2. README "What is new" section; screenshots `docs/screenshots/m006b_*.png`; a battle clip of the machines in action.
3. Version 0.6.1-M006b (Android version code 8); signed debug APK, Linux build smoke test, project ZIP. Save the
   prompt and the report to the project docs.
