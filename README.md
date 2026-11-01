# Dwarves vs Zombies — M007 "The Fallen Foundries" (on M006c, M006b, M006, M005, M004, M003, M002b, M002 and M001)

2D side-view, real-time, air-and-ground tug-of-war strategy defense.
Godot 4.3 (GL Compatibility renderer) · GDScript · Android-first, desktop for development.

**One Kingdom. One Great Forge. Two Fronts. No Heroes.**

## Opening the project

1. Install Godot **4.3** (standard, not .NET).
2. *Import* → select `project.godot`. First import builds the class cache (a few seconds).
3. Press **F5**. Main scene: `scenes/main_menu.tscn` (title) → **PLAY** descends into the animated Great Forge hub (`scenes/forge_hub.tscn`).

Desktop controls: click/tap cards to deploy, drag the battlefield (or A/D, ←/→, mouse wheel) to pan,
Space/P/Esc to pause. On Android, touch does the same (touch drag pans; cards are 88×104 px).

## What is new in M007 (0.7.0)

| Area | Status |
|---|---|
| Campaign | **Act IV, stages 091–120** ("The Fallen Foundries"): 30 authored stages in four new environments (`industrial_city`, `destroyed_forge`, `infested_factory`, `mech_graveyard`); bosses **The Fallen Titan** (100), **Ashen Forge Tyrant** (110), **Corpse Colossus** (120); **T5 research opens at 105** |
| Wreck reclamation | Destroyed dwarven vehicles, war frames and aircraft leave a **wreck** for 20 s (max 6). Undead corruptors (corpse priest, rot channeler, ash hexer) walk to a wreck, channel 4 s and raise a corrupted machine of the matching class; dwarven salvage units clear a wreck in 3 s and refund Gold. Channel telegraph, rise effect, cogs on the minimap |
| Hazards | `furnace_vents` (1 s glow, fire on both sides, machines take half), `slag_flow` (a creeping molten river, ground only), `steam_leak` (refills your Steam while a machine stands in it, scalds everyone inside), collapsing **gantries** (a rockfall variant) |
| Bosses | Titan reclaims wrecks as escorts and exposes its core (+25 % damage); the Tyrant fires the arena's vents in a telegraphed sweep; the Colossus hurls corpses at your stronghold and disgorges corrupted machines |
| Heroic difficulty | Every cleared stage (Acts I–IV) unlocks a **Heroic** version: one extra set piece, waves ×0.85 apart, one more support structure, enemy abilities ready sooner, ≤ +15 % HP. Separate red-gold stars, a one-time Spark payout, a red-gold banner on the Realm Map. `--suite=stages --heroic` |
| War frames | **"Forge-Knight" redesign** of all 28 frames: heroic mecha proportions (longer legs, V-tapered chest, boxy layered pauldrons, flared shins, sabaton feet, twin boiler thrusters, horned V-crest over twin eye slits) — forged by dwarves (braided-beard faceplate grilles, steam intakes round a furnace core, rivets, brass, runes) |
| Dwarf animation | A real stomping march for every dwarf (slanted legs, heel-toe boots, footfall squash, trailing beard, bobbing helmet), idle weight-shifting, and a comic flop-over death |
| Sound | The metallic "cling" on every tap is gone: button taps are silent by default (Settings → Button sounds gives a soft felted tick); deploy and mine-upgrade sounds are muffled thumps. New foundry ambiences and hazard / reclamation cues; a cache bug that dropped the Act III ambiences after the first launch is fixed |

See `docs/IMPLEMENTATION_REPORT_M007.md`.

## What is new in M006c (0.6.2, visual only — no gameplay change)

Every tank is its own machine. The 24 kit vehicles (and the corrupted Gravegun) no longer share one hull painter:
`scripts/art/art_tanks.gd` holds a design per vehicle — its own size (42 → 146 units), chassis (spoked wheels, a
three-wheeled trike, a halftrack, tracks with large / medium / small road wheels, rhomboid tracks round the hull,
two or three articulated bogies), hull silhouette, turret form (box, round, tower, open tub, flat, casemate, ball,
pintle) and signature fittings: the coal-cart scout with its chimney, the castle-walled Bastion and Iron Bastion
Prime, the locomotive Boiler Ram, the turtle-domed Thunderback, the dozer-bladed Sapper, the drill-nosed
Dreadplate, the river-monitor Twin-Cannon Ironclad, the rhomboid troop carrier, the brass warship Leviathan, the
land-battleship with its bridge tower, and more. New `tests/silhouettes.tscn` measures how alike the outlines are.
See `docs/IMPLEMENTATION_REPORT_M006c.md`.

## What is new in M006b (0.6.1, visual only — no gameplay change)

| Area | Status |
|---|---|
| Tanks (24 kit vehicles) | Weight classes read apart (light / medium / heavy / super-heavy); shaded hull planes, superstructure, panel seams, side skirts; **full running gear** (toothed sprocket, idler, road wheels with turning hubs, return rollers, two track runs moving opposite); wheeled hulls get spoked wheels, mudguards and leaf springs; crawlers two track units and a joint; proper **turrets** per kind with mantlet, muzzle brake, bore evacuator, rail coils; a **commander** in the hatch who looks about and ducks when the gun fires; the shot slides the barrel, rocks the turret, flashes, leaves a smoke cloud and ejects a brass case; antenna whip, pennant on heavies; **damage states** (smoke and scorch < 50 %, fire < 25 %), also on the legacy Copperback and Brasshound |
| Aircraft (18 kit aircraft) | Shaded fuselages and pods, glazed canopies, goggled pilots with a **streaming scarf**, rotor and prop **blur discs**, tail rotors, skids, ribbed wings, **biplane upper wing with struts and wires** and a wing engine on bombers, a moving rudder, landing gear, exhaust flames; guns kick and spit casings, coil guns arc, rockets leave the rail with smoke; **bomb racks show full / last bomb / empty**; smoke trail and engine fire when damaged |
| Airships (11 + supply barge) | Shaded envelope with girders, gore seams and a brass nose cap; a coat-coloured band with the **hammer-and-anvil**; fins with moving rudders and a pennant; rigging; **engine pods on outriggers** (2–4 by size); a keel gondola with lit portholes, railings, a glazed bridge and crew; carriers get a flight deck and a parked gyro, the battleship a piston ram, coil ships arcing coils, bombers bomb-bay doors, the largest hulls a second envelope; broadsides recoil and smoke; patched envelopes and fire when damaged |
| War frames (all 28) | A complete combat timeline for every arm family: **stance → combat stance** (lower, wider, guard up) **→ wind-up** (coiled, trembling) **→ strike** (smear and impact dust/sparks/shock rings) **→ follow-through → recovery** (spring overshoot), body lean/crouch/lunge per weapon, ability power pose for melee arms, stun slump; guns climb, kick and smoke; shoulder mounts recoil |
| Tests / tools | New `art_m006b` suite; `tests/artcheck.tscn` (bounds, moving parts, distinct mech states, live-draw cost); `tests/artsheet.tscn` before/after sheets; `bounds.tscn -- --machines`; bench `--mix=machines` |

See `docs/IMPLEMENTATION_REPORT_M006b.md`.

## What is new in M006

| Area | Status |
|---|---|
| Campaign | **Act III, stages 061–090** ("War for the Skies"): 30 authored stages; bosses **Bone Wyrm** (070), **The Hollow Admiral** (080), **Dread Sky Tyrant** (090); T4 research opens at 075 |
| Air war | **Altitude bands** (low / mid / high) for every flyer and a **reach** for every sky weapon; flyers cruise in band windows so the bands read apart; **flak belts**; **escort objectives** (a non-deployable `supply_barge` crosses the sky: third-star challenge, never a fail condition); an **air budget** of 24 alive undead flyers |
| Hazards | `thermals` (updraft/downdraft columns: a flyer rises or sinks a band, aircraft ±20 % speed) and `lightning_storm` (0.8 s telegraph, hits the tallest thing nearby on both sides, spires take double); `gale` reused |
| Environments | `open_plains`, `broken_ridge`, `airborne_ruins` (a causeway on a floating rock over the cloud sea), `shattered_fort`; a drifting cloud parallax layer; storm lighting on lightning stages |
| Realm Map | Act III landmarks (windmill farmstead, rope-bridge outpost, floating tower, broken bastion); airborne stages float **aloft** on islands with chains and dashed airship routes; boss set pieces (wyrm in the split ridge, ghost flagship in cloud, storm throne); lightning flicker over storm stages |
| Animation | **Motion layer** for every unit (smooth secondary motion over the pose-cache sprites): dwarven infantry bounce and lean, the undead lurch, tanks shiver/pitch/rear on firing, war frames drop onto each footfall with mass-scaled recoil springs, artillery rears back, airships pitch, roll off broadsides and list when hurt, flyers flap. **War frames**: heel-toe foot roll, pelvis roll, arm counter-swing, higher steps, 12-step walk cycle on Balanced/High. **Tanks**: turning road wheels, both track runs moving, thrown dirt, muzzle smoke rings. A "Unit motion" switch in Settings (reduced motion) |
| UI | Sky-threat indicator by band next to the minimap; escort health bar under the stronghold gauge; drawer shows the escort objective and sky bands (cleared stages); Compendium shows altitude band and "can hit" on every dossier |
| Tests | `air_war`, `hazards_m006`, `boss_phases_m006`, `boss_counters` (now 040–090), `m006_save`, `ui_m006`, `motion`; `stages --from=1 --to=90` |

See `docs/IMPLEMENTATION_REPORT_M006.md`.

## What is new in M005

| Area | Status |
|---|---|
| Campaign | **Act II, stages 031–060** ("The Blighted Frontier"): 30 authored stages with taglines, hazards, blueprints and challenges; bosses **Blightroot Behemoth** (040), **Plague Regent** (050), **Gravewing Matriarch** (060) |
| Environments | `dead_forest`, `plague_marsh`, `ruined_road`, `corrupted_mine` battle backgrounds; matching Realm Map landmarks and three boss set pieces |
| Hazards | `miasma` (drifting poison clouds: organic ground units on both sides, machines immune, skeletons half) and `bog` (slowing mire); a stage may carry several hazards |
| Bosses | Arrival pan with a sting (tap to skip), a telegraphed 50 % phase each (root eruptions under your guns · the Court's heralds and thicker miasma · the Matriarch perches on her nest and is ground-targetable) |
| Stars | 3 stars per stage (win · stronghold above 50 % · challenge objective); every stage 001–060 has a challenge; first-time star Spark bonus (+10 %/star, max +30 %); gold banners on 3-star landmarks |
| Guidance | Guided tutorial for stages 001–003 (on for new saves only) and one-line first-encounter hints; both toggle in Settings |
| Toolkit | `tools/stage_kit.py` (encounter templates + validator, run on every data build), `tools/batch_sim.py` (parallel stage sims → CSV), `tools/auto_tune.py` (suggestions only) |
| Tests | `hazards`, `boss_phases`, `boss_counters`, `stars`, `m005_save`, `ui_m005`; `stages --from=1 --to=60` |

See `docs/IMPLEMENTATION_REPORT_M005.md`.

## What is new in M004

| Area | Status |
|---|---|
| Stage select | **Realm Map**: a painted, draggable cross-section of each act. Every stage is a landmark (gatehouses, mine caverns, chapels, smelters, eyries, boss set pieces), with a front line of corruption, a patrol on the road and a slide-in stage drawer. |
| Infantry animation | Slapstick layer: hats pop off and flip back on, blunderbuss hops, X-eyed hammer "boings", waddles, idle fidgets; gun crews lose their hats too |
| Mech animation | Mass-scaled recoil springs, ejected brass casings, vent steam, heat shimmer, footfall dust, idle boiler breathing |
| Roadmap | Release plan to v1.0 with a cosmetics-only IAP patch (no pay-to-win); see the Road to Release doc |

See `docs/IMPLEMENTATION_REPORT_M004.md`.

## What is new in M003

| Area | Status |
|---|---|
| Roster | **Complete:** 160/160 dwarven units, 110/110 undead, 15/15 bosses — all playable, original procedural art (`scripts/art/art_kit.gd`) |
| Campaign | **30 stages** — stages 016–030 finish Act I, with bosses The Bellringer (020) and Ossuary Matron (030); clearing 030 opens T3 research |
| UI | "Forged brass & iron" overhaul of every screen: battle HUD, War Table stage select, Loadout, Great Forge, Compendium, Settings, title, hub, sandbox |
| Tests | `--suite=roster --from=N --to=M` (every new unit's role), `bosses_all` (all 15 bosses), `stages --from=1 --to=30` |

T4–T5 units are implemented and playable in the Proving Grounds sandbox; their campaign acts are not built yet.
See `docs/IMPLEMENTATION_REPORT_M003.md`.

## What is new in M002b

| Area | Status |
|---|---|
| Undead Giants | **12 implemented** from planned roster entries (3 brutes · 4 abominations · 3 behemoths · 2 colossi), matching the war-frame size classes, with abilities (charge, AoE, stun, slowing zones, summons with caps, rally, devour-heal) |
| Performance | Pose cache (units drawn as baked atlas sprites), batched particles/bars/background, hub static layer baked, logic hot spots fixed, physics catch-up capped, audio disk cache |
| Quality presets | High (live art, 60 Hz) · Balanced (baked, 60 FPS) · Performance (baked, 30 FPS) — phones default to Performance |
| Tests | `--suite=giants`, `giants_scenarios`; `tests/bench.tscn` measures frame/draw-call cost |

See `docs/IMPLEMENTATION_REPORT_M002b.md`.

## What is new in M002

| Area | Status |
|---|---|
| Branch E war frames | **All 28 implemented** (6 light · 8 medium · 8 heavy · 6 colossal) on a shared articulated rig with distinct designs, staged destruction, Steam abilities, ARM% (≤50 %, penetration), independent multi-weapon targeting |
| Machinery Doctrine | Conserve / Standard / Overdrive (battle HUD + saved setting); serial ability arbitration |
| Alternate armaments | Copper Sentinel Breacher · Furnace Stalker Thunderjaw · Thunderstep Bruiser Breach Cannon — researched in the Forge, chosen in the Loadout |
| Great Forge hub | Animated, scrollable cavern at the mountain's root; six stations open every screen |
| Tests | `--suite=mecha` (41), `mecha_scenarios` (A–F), `mecha_audio`, `mecha_save` |

Implemented dwarves: 44 (18 M001 + 26 new frames). T3–T5 frames are sandbox-only until Stages 045/075/105 exist.
See `docs/IMPLEMENTATION_REPORT_M002.md`.

## What is in M001

| Area | Status |
|---|---|
| Dwarven roster registry | 160 entries with stable IDs, branch, tier, provisional role, milestone. **18 implemented** with full stats, art and behavior |
| Undead roster registry | 110 entries. **14 implemented** |
| Bosses | 15 planned with identities. **Mine Maw implemented** (Stage 010) |
| Campaign | 150 stage metadata entries. **Stages 001–015 implemented**; 016–150 marked *Planned* in data and UI |
| Great Forge | 21 doctrines + 160 unit nodes with cross-branch prerequisites; implemented units/doctrines researchable |
| Screens | Main menu, Campaign map, Army Loadout (7 ground / 4 air / 1 flex, 3 presets), Great Forge, Unit Compendium, Settings, Battle, Victory/Defeat, Pause, Test Sandbox |
| Systems | Gold + Steam Pressure economy, mine upgrades, Overdrive & Pressure Vent abilities, independent multi-weapon components, spatial-bucket targeting, pooled projectiles & effects, wave director with hazards (rockfall, gale), versioned save with backup + migration, procedural audio |

See `docs/IMPLEMENTATION_REPORT.md` for exactly what was tested and what remains.

## Project layout

```
project.godot            autoloads: Registry, GameState, Audio
data/*.json              master registries (generated — edit tools/gen_data.py, then run it)
tools/mech_data.py       M002 war-frame definitions (weapons, abilities, variants)
tools/giant_data.py      M002b undead giant definitions
scripts/core/pose_cache.gd  baked sprite atlas (performance presets)
tools/gen_data.py        content generator + integrity asserts (160/110/15/150, tier counts)
scripts/autoload/        registry.gd, game_state.gd (profile, research, rewards, loadouts), audio_manager.gd
scripts/core/            save_manager.gd (versioned JSON save, .bak, migration)
scripts/battle/          battle.gd (controller), unit.gd (shared data-driven unit + behaviors),
                         weapon.gd (independent weapon component), projectile_layer.gd, fx_layer.gd,
                         wave_director.gd, boss_mine_maw.gd, combat.gd (armor tables), battle_background.gd,
                         autoplayer.gd (heuristic commander for tests / sandbox)
scripts/art/             procedural layered-polygon art (painter + dwarves, machines, air, undead, structures)
scripts/ui/              screens + ui_kit.gd (brass/steel console theme) + widgets.gd
scenes/                  one thin .tscn per screen
tests/test_runner.*      headless validation (Tests A–J, stage sims, registry, UI smoke)
tests/screenshot.*       renders screens to PNG (needs a display, e.g. xvfb-run)
docs/                    master spec (preserved verbatim) + implementation report
```

Adding a unit = one entry in `tools/gen_data.py` (stats, weapons, `behavior`, `art`) + an art function.
No per-unit scripts: every unit runs through `unit.gd` / `weapon.gd`.

## Running the tests

```
godot --headless --path . --editor --quit                       # first time: import / class cache
godot --headless --path . res://tests/test_runner.tscn -- --suite=registry
godot --headless --path . res://tests/test_runner.tscn -- --suite=combat     # Tests A,B,C,D,E,F,H,J
godot --headless --path . res://tests/test_runner.tscn -- --suite=boss       # Test G (Stage 010)
godot --headless --path . res://tests/test_runner.tscn -- --suite=mecha            # M002 per-frame + systems cases
godot --headless --path . res://tests/test_runner.tscn -- --suite=mecha_scenarios  # M002 scenarios A–F
godot --headless --path . res://tests/test_runner.tscn -- --suite=mecha_audio
godot --headless --path . res://tests/test_runner.tscn -- --suite=mecha_save
godot --headless --path . res://tests/test_runner.tscn -- --suite=giants           # M002b per-giant + systems
godot --headless --path . res://tests/test_runner.tscn -- --suite=giants_scenarios # frames vs giants GA–GD
xvfb-run -a godot --path . --rendering-driver opengl3 res://tests/bench.tscn -- --quality=low --warm=200   # frame cost / draw calls
xvfb-run -a godot --path . --rendering-driver opengl3 res://tests/bounds.tscn      # re-measure art bounds after art changes
godot --headless --path . res://tests/test_runner.tscn -- --suite=save_write # Test I part 1
godot --headless --path . res://tests/test_runner.tscn -- --suite=save_verify # Test I part 2 (new process)
godot --headless --path . res://tests/test_runner.tscn -- --suite=stages --from=1 --to=15
godot --headless --path . res://tests/test_runner.tscn -- --suite=ui
godot --headless --path . res://tests/test_runner.tscn -- --suite=art_m006b
xvfb-run -a godot --path . --rendering-driver opengl3 res://tests/artcheck.tscn   # M006b machine art acceptance
xvfb-run -a godot --path . --rendering-driver opengl3 res://tests/silhouettes.tscn -- --out=/tmp/sil.png   # M006c tank silhouette overlap
godot --headless --path . res://tests/test_runner.tscn -- --suite=wrecks           # M007 wreck reclamation
godot --headless --path . res://tests/test_runner.tscn -- --suite=hazards_m007     # vents, slag, steam leak, gantries
godot --headless --path . res://tests/test_runner.tscn -- --suite=boss_phases_m007 # Titan, Tyrant, Colossus phases
godot --headless --path . res://tests/test_runner.tscn -- --suite=heroic           # Heroic stages, rewards, no-T5 rule
godot --headless --path . res://tests/test_runner.tscn -- --suite=m007_save        # M006 save -> M007
godot --headless --path . res://tests/test_runner.tscn -- --suite=ui_m007          # drawer toggle, minimap wrecks, Realm Map IV, Compendium
godot --headless --path . res://tests/test_runner.tscn -- --suite=audio_m007       # no tap cling, Act IV cues, loop cache
godot --headless --path . res://tests/test_runner.tscn -- --suite=stages --from=91 --to=120 --heroic   # Heroic winnable/losable
python3 tools/batch_sim.py --from 91 --to 120 --out build/sims.csv [--heroic]
```
Exit code is 0 only if every check in the suite passed.

## Android export

`export_presets.cfg` contains an **Android** preset (arm64-v8a + armeabi-v7a, landscape, immersive,
package `com.dwarvesvszombies.game`). To build a release APK/AAB you need, in Editor Settings → Export → Android:
a real Android SDK (platform-tools + build-tools with `apksigner`) and a JDK 17+, plus your own release keystore.
`build/android/DwarvesVsZombies-M001-debug.apk` in the delivery was produced from the official 4.3 templates and
signed with a debug key (v1/v2/v3 verified) — it has **not** been run on a physical device.
