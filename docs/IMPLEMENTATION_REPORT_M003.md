# M003 — The Full Muster: complete roster, Act I second half, forged-brass UI overhaul

Engine: Godot 4.3-stable (GL Compatibility). Date: 2026-11-01. Version 0.3.0-M003 (Android version code 4).

Everything marked **tested** ran in this build environment: headless, or on a virtual X display with software
OpenGL for screenshots. **The build has not been run on an Android phone.** No on-device frame rate is claimed.
The M001, M002 and M002b reports are kept unchanged next to this one.

---

## 1. Complete roster — every entry is now playable

| Roster | Before M003 | M003 | Notes |
|---|---|---|---|
| Dwarven units | 44 / 160 | **160 / 160** | 116 new: all 7 branches, T0–T5 |
| Regular undead | 26 / 110 | **110 / 110** | 84 new: every category, including flyers, siege and corrupted machines |
| Major bosses | 1 / 15 | **15 / 15** | 14 new, each with its own ability set |
| Support structures | — | 3 | Barricade, Gun Turret and Gatling Turret, which engineers deploy |

No roster entry was removed and every ID is unchanged, so old saves still load.

- **Data:** `tools/roster_data.py` defines the new units on shared tier power and cost curves.
  - It uses weapon helpers: rifle, melee, cone, arc, shell, flak, mg, zap and bomb.
  - `tools/gen_data.py` merges them into the JSON registry.
- **Art:** `scripts/art/art_kit.gd` (ArtKit) draws all 217 new arts from a parameter kit. Every unit gets its own silhouette, colours, gear and weapons.
  - **Families:** infantry, engineers, guns, vehicles, aircraft, airships, props, zombies, skeletons, casters, beasts, siege, flyers, corrupted machines, and bosses built on the giant rig.
  - **Performance:** the arts go through the M002b pose cache, so each unit is still one batched quad.
- **New behaviours:**
  - Steam generators and auras (buff, or cleanse that removes debuffs).
  - Engineers that deploy barricades and turrets; mine layers.
  - Air repair craft; carriers that launch fighters.
  - On-hit slow and stun; heal-on-hit; units that spawn others when they die.
  - Corrupted dwarven machines.
- **Bosses:**
  - Each boss carries 2–3 abilities, each on its own cooldown with a 2.5 s gap between casts. Every cast raises an on-screen alert.
  - Each boss has an enrage at 35 % HP and seals the citadel until it dies; some send support waves.
  - Flying bosses (Gravewing Matriarch, Bone Wyrm, Hollow Admiral, Dread Sky Tyrant, Gravewing Sovereign) fight from the air.

### Bugs found and fixed by the new per-unit test
- Shrieker-type flyers hovered out of range of ground targets; their standoff is now limited to weapon reach.
- Carriers only launched fighters against ground enemies; now they launch against any enemy.
- Twin-Flame Gunship and Skyhammer could not hit the ground; their weapons were changed.
- Flame and cone weapons on tall war frames (Embercore Titan) missed ground targets; the range and cone checks were fixed for mechs.
- Flying bosses' abilities were counted as Steam abilities; they now count as necrotic abilities like ground bosses.

## 2. Campaign: stages 016–030 (the rest of Act I)

**A correction:** the question I asked you labelled stages 16–30 as "Act II". In the game's data each act has
30 stages, so **16–30 are the second half of Act I, "Siege of the Mountain Holds".** Act II starts at stage 031.

Each of the 15 new stages has its own name, environment, enemy mix and hazards (rockfall or gale where used), plus Spark rewards and a free blueprint. They introduce the new low-tier undead gradually.

| Stage | Name | Introduces / feature | Reward blueprint |
|---|---|---|---|
| 016 | Cragwatch | Shamblers, bone pikemen, grave slingers, rot hounds, cursed barricade | Sapper |
| 017 | Old Bellows Road | Wretched climbers, barrow spearmen, blight bats | Longrifle Scout |
| 018 | Tallowmere | Fungal hosts, grave moths | Hammer Guard |
| 019 | Blackpick Galleries | Ossuary axemen, tomb stalkers, rift crows; rockfall | Portable Mortar |
| **020** | **Belfry of Frostfang** | **Boss: The Bellringer**; gale | Flame Trooper |
| 021 | The Coal Stair | Blight marauders, pestilent soldiers, plague sprayers, skeletal vultures | Rotary Interceptor |
| 022 | Hammerfall Vale | Rotting berserkers, bone vanguard, bone lancers, rotwings | Coalrunner Scout Tank |
| 023 | Rustgate | Rusted legion, crypt hexers, spectral wraiths, bone catapults | Steamgunner |
| 024 | Kettle Rock | Air raid: plague harpies, wasps, wraith swarms, a flak spire; gale | Skyhook Rocket Rack |
| 025 | Grimvent | Risen bomb carriers, carcass devourers, corpse lobbers | Steam Mortar |
| 026 | Emberdeep | Cursed dwarf thralls, crypt halberdiers, cinder wraiths, haunted flying machines | Twin Flak Mount |
| 027 | Stonehelm Keep | Siege: bone rams, hollow guard, grave mortars | Copperback Light Tank |
| 028 | The Long Shaft | Corpse burrowers, grave spiders, tomb centipede; rockfall | Drillwalker |
| 029 | Wardens' Ridge | Grave wardens, plague maulers, spirit binders, tomb gargoyles | Repair Wagon |
| **030** | **Ossuary Hall** | **Boss: Ossuary Matron** (aerial escorts) | Ironclad Medium Tank |

- **Tier gate:** clearing stage 030 opens T3 research. It was gated at stage 045, which does not exist yet.
  - T4 and T5 units are fully implemented and can be tried in the Proving Grounds sandbox.
  - In the campaign they stay sealed until their acts are built.
- **Tuning:** the stages were tuned with the auto-commander sims. Two systemic problems came out of it.
  - **Ranged pile-up:** enemy artillery and ranged units piled up behind the front until they filled the alive cap. Those tracks now stop after 8–10 minutes (`until`).
  - **Bellringer:** it was too strong for its stage, so its HP went from 7,200 to 6,400, its toll is smaller and stuns for a shorter time, and it summons fewer skeletons. It now arrives at 40 s instead of 16 s.

## 3. UI overhaul — "forged brass & iron"

Screenshots: `docs/screenshots/m003_*.png`.

**Visual kit:** all UI art is generated in code (`scripts/ui/ui_art.gd`, `scripts/ui/ui_kit.gd`), so the APK carries no image assets for it.
- **Panels:** riveted iron plates with bevelled brass rims, engraved banners, plaques and glass panels.
- **Buttons:** four states, a forge-lit primary style and a danger style.
- **Other pieces:** tabs, deploy-card frames and sockets.
- **Icons:** 21 vector glyphs, including coin, steam, gear, valve, skull, crown, star, lock and wing.
- **Gauges:** gauge bars and a pressure dial.
- **Cost:** each panel is one nine-patch texture quad, so it stays cheap on phones.

**Screens:**
- **Battle HUD:**
  - **Top console:** a riveted strip holding both stronghold gauges, a Gold pill, the Steam pressure dial, a framed minimap, the clock, and round speed/pause buttons.
  - **Boss bar and alerts:** a boss health bar, plus an alert banner for boss abilities and enrage.
  - **Deploy tray:** the cards show a radial cooldown, a coin plate, a steam badge and a press animation. Air cards are steel-blue; ready cards glow.
  - **Ability buttons:** valve-style buttons for Doctrine, Mine, Overdrive and Vent.
  - **End screens:** victory and defeat plates with a stat grid.
- **Stage select (War Table):**
  - **Map:** an illustrated war map with a road and compass. Stage nodes pulse when available, show a star when cleared, a lock when locked and a crown for boss stages.
  - **Detail plate:** an environment preview, the tagline, citadel and hazard pills, and portraits of the enemies you have met. It also shows the boss, the rewards (with blueprint portraits) and your current army.
  - **Buttons:** Deploy and Edit Loadout stay pinned at the bottom.
- **Army Loadout:**
  - **War rack:** 12 sockets grouped Ground ×7 / Air ×4 / Flex ×1, with presets.
  - **Armoury:** all 160 units as portrait cards, with branch filters and an "unlocked only" toggle.
  - **Dossier:** an animated portrait, a stat-icon row, weapons, ability and variant buttons.
- **The Great Forge (research):**
  - **Tree:** each branch is laid out as tier rails (T0–T5 plaques, sealed tiers locked). Nodes show their state as Forged, Ready (Spark cost) or Locked.
  - **Selection:** selecting a node lights its prerequisites. The dossier plate has a "Forge it" button.
- **Unit Compendium:** a codex of portrait tiles grouped by branch, category or act, with a full dossier. Undead and bosses stay "???" until you meet them.
- **Settings:** sectioned brass plate covering Sound, Graphics & Battle, and Progress (with a danger-styled reset).
- **Title:** riveted crest, "M003 — The Full Muster" banner, a forge-lit PLAY button that pulses gently.
- **Forge hub:** brass station plaques with glyph medallions, and a glass top bar with Spark and stage pills plus Deploy. The bottom navigation shows glyphs.
- **Proving Grounds sandbox:** glass dev panel. The spawn picker now uses faction tabs and a group selector, covering every dwarf, every undead and all 15 bosses. Only one group's buttons exist at a time.

## 4. Tests (all run in this environment)

All suites pass with 0 script errors:

| Suite | Result |
|---|---|
| `registry` (160/110/15 implemented, 30 stages, valid defs; every pre-M003 unit acts) | **2/2** |
| `roster` (every implemented dwarf and undead performs its role — all 270) | **all pass, 0 failures** |
| `bosses_all` (all 15 bosses: abilities, damage both ways, valid targets, citadel unseal) | **15/15** |
| `stages 1–30` (each stage winnable by the auto-commander and losable with no deployments) | **60/60** |
| `combat` A–J · `boss` (Mine Maw, stage 010) | **8/8 · 1/1** |
| `ui` / `ui --quality=low` (every screen plus its key interactions) | **8/8 · 8/8** |
| `mecha` / `mecha_scenarios` / `mecha_audio` / `mecha_save` | **41/41 · 6/6 · 2/2 · 1/1** |
| `giants` / `giants_scenarios` | **18/18 · 4/4** |
| `save_write` → `save_verify` (fresh-process reload) | **1/1 · 1/1** |

**Fixes from this test round:**
- The Plague Beast's pool is placed further forward to match the bile cone's horizontal reach.
- The legacy "every unit acts" check placed targets inside mortars' minimum range; M003 units are now covered by `roster`.
- The `roster` suite's upper bound is exclusive, so I ran the two boundary indices separately.

### Performance (same crowded bench as M002b: ~111 units, Performance preset, software GL on a virtual display)

| | M002b build | **M003** |
|---|---|---|
| Full frame | 43.4 ms | **42.3 ms** (38.3 ms on another run) |
| Game logic / unit drawing | 5.0 ms / 1.4 ms | 5.3 ms / 1.5 ms |
| GPU draw calls / frame | 417 | **~560** |
| HUD alone (battle start) | ~70 | ~150 |
| Crowd made only of new M003 units | — | 37.1 ms, ~820 draw calls |

The richer HUD costs about 80 more draw calls. Most of the rest comes from the pose cache spreading many more distinct arts over its 4 atlas pages, so units next to each other more often sit on different pages and cannot batch.

**HUD fixes made:**
- Every icon is now baked into one atlas and drawn as one tinted rect.
- Deploy cards draw on separate layers (frames, then sprites, then shapes, then text) so they batch across the tray.
- A clock symbol that pulled in a system fallback font was removed.

**Result:** CPU frame time is level with M002b. Draw calls are up about 35 %, which is still about 16× fewer than before the M002b patch. If the Infinix struggles, the HUD is the next thing to slim down.

How to run: `godot --headless --path . res://tests/test_runner.tscn -- --suite=<name>`.
- **New suites:** `roster --from=N --to=M` checks every new unit's role (fires, spots, repairs, aura, deploys, mines, steam).
  - `bosses_all` checks that all 15 bosses cast abilities, take and deal damage, never target an ally, and unseal the citadel when they die.
- **Stage sims:** `stages --from=1 --to=30` checks that each stage can be won by the auto-commander and is lost with no deployments.

## 5. Honest limits
- **Not phone-tested:** nothing in M003 has been run on a phone.
  - About 200 new arts go through the pose cache, so a first look at a new unit costs a short live-draw frame before its sprite is baked.
  - Please report any stutter on the Infinix.
- **Balance:** stage balance comes from the auto-commander sims, which spam cheap units and use no abilities, so a human player will find different pressure points.
  - The sims assume that by stage 016 a player has also researched a few T1/T2 units with the ~1,200 Sparks earned in stages 1–15.
- **T3–T5 in the campaign:** these units are implemented and balanced against each other in the sandbox, but no campaign stage uses them yet.
- **Bosses beyond stage 030:** the 13 bosses from stage 040 onward work in the sandbox and in their tests, but their stages are still planned.
