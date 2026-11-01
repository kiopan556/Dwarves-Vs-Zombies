# M004 — The Living Realm: realm-map stage select, slapstick infantry, heavy mechs, release roadmap

Engine: Godot 4.3-stable (GL Compatibility). Date: 2026-11-01. Version 0.4.0-M004 (Android version code 5).
Everything marked **tested** ran in this build environment (headless, or a virtual X display with software
OpenGL). **The build has not been run on an Android phone.** No on-device frame rate is claimed.

---

## 1. Stage select → the Realm Map

The old screen showed numbered circles joined by lines. It is now a painted, side-on cross-section of the realm
for each act (`scripts/ui/realm_map.gd`). You drag through it with inertia, or use the mouse wheel.

- **Landmarks:** each stage is a landmark drawn for its environment.

  | Environment | Landmark |
  |---|---|
  | Gate | Gatehouse with twin towers and a portcullis |
  | Pass | Carved stairway with an arch |
  | Mine mouth | Timber tunnel mouth with a lantern and a cart |
  | Deep or flooded mine | Cavern cut into the rock below the surface, with a timber shaft and headframe (crystals, or black water) |
  | Ridge | Watchtower |
  | High ridge | Crag eyrie |
  | Outpost | Ruined chapel |
  | Foundry | Smelter with stacks |

- **Boss stages:** the Mine Maw is a toothed throat in the gallery floor, the Bellringer a black belfry with a great bell and toll rings, and the Ossuary Hall a bone cathedral. Later acts' bosses get dark spires.
- **The road and the front:** the road runs from Stonehelm, the dwarven hold at the left, toward the undead.
  - **Cleared stages:** a blue dwarven banner, lit windows and chimney smoke.
  - **Uncleared stages:** past the front line they glow undead green, carrion birds circle and mist rolls along the ground.
  - **Next stage:** a bobbing beacon marks it.
  - **Cleared ground:** a tiny dwarf patrol walks back and forth along the road.
- **Act palettes:** each act has its own sky and terrain (dawn mountains, blighted green, open skies, smog orange, rift violet). The sky shifts from warm over the hold to bruised over the undead lands.
- **Detail drawer:** tapping a landmark glides the map to centre it and slides in a brass drawer. The drawer holds the existing stage dossier and Deploy. Its handle hides it to show the whole map.
- **Performance:** the sky, two parallax mountain ranges and the terrain (road, caverns, scenery, landmarks, signposts) are baked once per open into three textures. Only the clouds, mist, smoke, beacon, selection ring and patrol are drawn each frame. Measured: 32 ms frames and 515 draw calls on the Performance preset, most of them the drawer's portraits. Headless runs draw everything live.

## 2. Animation overhaul

### Goofy infantry (every dwarf with a body: core six, all kit infantry and engineers, gun crews)
A new per-unit timeline, `gag`, runs from 1 to 0 over about 0.8 s after each attack. It is quantized into the pose
cache like every other animation field. It drives a slapstick layer (`ArtDwarves.goof_begin/goof_end`):

| Weapon kind | Gag |
|---|---|
| Rifles | Squash and lean back, damped-spring wobble back to upright; **the hat pops off, flips once and lands back on the head**; bald pate and startled hairs while it is airborne; eyes squeezed shut, then looking up at the hat |
| Long rifles | Same, harder, and the beard blows back |
| Blunderbuss / shotgun | Big kick: **feet leave the ground**, the dwarf skids back, gaping "O" mouth, beard flaps, the hat flies highest |
| Mortars / lances | Heavy kick with a small hop |
| Flamers / steam guns / gatlings | Whole-body buzz while firing, eyes shut |
| Hammers / picks / halberds | Wind-up stretch, then a rattling "boing" after impact with **X eyes** |
| Grenadiers / satchels | Over-committed throw, wobbling forward, then settling |
| Cannon & gun crews | Their hats blow off in the muzzle blast |
| Engineers | Light tool bob |

- **Also new:**
  - Waddling, bouncy walks.
  - Idle breathing, blinks, a toe-bounce and a helmet adjustment on a 4.8 s loop, offset per unit so a line never moves in sync.
  - Cartoon X eyes and a squash when hit.
- **Composable transforms:** a transform stack (`Painter.xf_push/xf_pop`) lets the whole-body squash wrap the flying hat and the vehicle/crew sub-transforms correctly.
- **Undead:** deliberately untouched. They stay frightening.

### Heavy, serious mechs (all 28 war frames)
- **Recovery spring:** after every shot or swing, the frame absorbs the kick and settles. Torso jolt, lean, suspension compression and a slower, mass-scaled spring (colossi settle slower than light frames).
- **Gun frames:** a spent brass casing tumbles out of the breech; melee frames don't eject one.
- **All frames:** the back vents dump steam after each shot, and a heat shimmer rises.
- **Movement:** footfall dust where a foot plants (bigger for heavy and colossal frames) and idle boiler breathing.

### Pose cache and performance
- **Bounds:** cell bounds were re-measured (`tests/bounds.gd` now samples gag frames and idle fidgets) so flying hats and casings are never clipped.
- **Detail by preset:** detail follows the quality preset (`Unit.anim_detail`).
  - Balanced: attack and gag steps of 1/8 and a 24-frame idle loop.
  - Performance (the phone default): coarser 1/4 steps and an 8-frame idle loop, so crowded battles keep their poses inside the atlas.
  - High: draws everything live and smooth.
- **Measured** on the same crowded bench (~111 units, Performance preset, software GL; the M003 build measured from its ZIP on the identical test):

  | | M003 | **M004** |
  |---|---|---|
  | Full frame | 40.2 / 42.9 ms | **44.0 / 45.4 ms** |
  | Unit drawing | 1.2 ms | 1.8–1.95 ms |
  | GPU draw calls | 562 | **433** |

  The richer animation costs about 2–3 ms of CPU per frame in that worst-case crowd, mostly units drawing live while their new poses bake. Draw calls are lower.

**Clip:** `m004_animations.mp4` / `.gif` were rendered frame by frame on the High preset, so the motion is smooth. On the Performance preset the same motion is stepped like a hand-made sprite sheet.

## 3. Release roadmap
Written as a doc ("Dwarves vs Zombies — Road to Release"):
- Eight milestones from here to v1.0: Acts II–V (M005–M008), audio/art/localization (M009), a hardening beta (M010) and the **Royal Treasury IAP patch (M011)** before launch.
- **Shop design:** cosmetics only. Liveries, the hat-and-beard wardrobe, stronghold skins and battle trims, plus a one-time Supporter Pack and a tip jar.
- **Never sold:** units, Sparks, research skips, boosts, energy, continues or loot boxes. No ads.
- **Also covered:** Google Play's 12-tester / 14-day closed-test rule for new personal accounts, the billing-plugin integration plan, and risks.

## 4. Tests (run in this environment)

| Suite | Result |
|---|---|
| `registry` | 2/2 |
| `combat` A–J | 8/8 |
| `boss` (Mine Maw) | 1/1 |
| `ui` / `ui --quality=low` (includes the new campaign screen) | 8/8 · 8/8 |
| `mecha` | 41/41 |
| `giants` | 18/18 |
| `roster` (all 270 units' roles) | all pass |
| `save_write` → `save_verify` | 1/1 · 1/1 |
| `stages 1–2` sample | 4/4 |

There were 0 script errors. Game logic did not change this milestone, so the full 30-stage simulation sweep was not
re-run beyond the sample. The animation timeline is visual only and does not touch combat.

## 5. Honest limits
- **Not phone-tested:** nothing has run on a phone. The Realm Map's three baked textures (the largest 3,862×540) use about 14 MB of video memory, which should fit a 4 GB phone but is unverified.
- **Undead:** they did not get gag animations, by design.
- **Map art:** the realm landmarks for Acts II–V are generic placeholders until those acts are built.
