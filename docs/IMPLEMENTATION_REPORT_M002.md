# M002 "Operation Iron Giants" — Implementation Report

Engine: Godot 4.3-stable (GL Compatibility). Language: GDScript (~19,000 lines incl. tests). Date: 2026-11-01.
Everything marked **tested** was executed headless (or under a virtual X display for screenshots) in this build
environment. **Nothing was run on an Android device, and no mobile frame-rate figure is claimed.**
The M001 report is kept unchanged in `docs/IMPLEMENTATION_REPORT.md`.

---

## 1. Completed

### 1.1 Branch E — all 28 war frames are functional units
| Class | Scale vs Rifleman | Frames (tier) |
|---|---|---|
| Light (6) | 2.05× | Miner Rig (T1) · Boiler Stomper · Drillwalker · Steam Loader · Piston Brawler · Copper Sentinel (T2) |
| Medium (8) | 2.85× | Ironclad Walker · Skyguard Walker · Thundercoil Frame · Cannon Strider · Shieldframe · Claw Harvester · Mortar Walker · Furnace Stalker (T3) |
| Heavy (8) | 4.0× | Anvilbreaker · Siegebellow · Furnace Guardian · Siege Hammer Walker · Flak Colossus · Thunderstep Bruiser · Shredder Walker · Riftshield Walker (T4) |
| Colossal (6) | 5.6× | Deepforge Titan · Mountain Colossus · King's Anvil · Colossal Skybreaker · Hammerfall Goliath · Embercore Titan (T5) |

All scales fall inside the M002 bands (light 1.8–2.3, medium 2.5–3.2, heavy 3.5–4.5, colossal 5–6.5). No roster entry was removed;
the registry still holds 160 dwarves / 110 undead / 15 bosses / 150 stages, now with **44 implemented dwarves** (18 from M001 + 26 new frames;
Miner Rig and Boiler Stomper were rebuilt as full M002 frames).

Each frame is data-driven from `tools/mech_data.py` (no per-unit scripts) and has:
- **Original procedural art** on one shared articulated rig (`scripts/art/art_mechs.gd`): IK knees, pistons, hip skirt, nine torso types,
  seven head types, back gear, per-family arm weapons and shoulder mounts. Each frame has its own silhouette, paint and equipment.
- **Animation states**: idle sway, walk (stance/swing feet, body bob, foot plants with dust and footstep sounds), target tracking per weapon,
  attack wind-up, primary and secondary attacks, reload/spin-down, hit flash, ability telegraph, and **staged destruction** that differs by class
  (sparks → smoke → collapse, longer for heavy/colossal).
- **Weapon families**: axes, hammers, fists, drills, claws, boomsticks, machine guns, rotary guns, cannons, siege cannons, mortars, flamers,
  arc/coil weapons, steam vents, AA twin/quad/heavy mounts. Pellet weapons (boomsticks) distribute pellets round-robin and can never hit
  more targets than pellets. Drills hit once per attack interval and cannot multiply.
- **Independent multi-weapon targeting**: every mount has its own target, arc, range and reload. A sibling-weapon penalty in scoring spreads fire
  when good alternatives exist.
- **ARM% damage reduction** applies to physical damage (pierce/blast/melee/flak/drill), is **capped at 50 %**, and is reduced by penetration
  (`pen`, +0.2 for AP shells). Shock and fire ignore ARM; a damage floor of 8 % always applies.
- **A Steam special ability** for every frame (strike, AoE, buff, shot, chain, zone, ward, charge or salvo), with cooldown, wind-up and telegraph.
  The ability is cancelled if the frame dies during the wind-up.
- **Repair compatibility**: Field Mechanics repair frames, but a per-machine cap of **34 HP/s** applies however many crews work on it,
  and destroyed frames are never revived.

### 1.2 Machinery Doctrine (army-wide)
A battle HUD button and a Settings value (saved) cycle **Conserve / Standard / Overdrive**:

| Doctrine | Steam kept in reserve |
|---|---|
| Conserve | 90 − cost, so only near-full pools are spent |
| Standard | 10 |
| Overdrive | 0, and AoE abilities trigger on a single target |

The battle arbitrates requests one at a time with a 0.5 s global gap, so several frames can never drain the pool in the same instant.

### 1.3 Alternate armaments (three variants, no new unit IDs)
| Variant | Change |
|---|---|
| Copper Sentinel — **Breacher** | Boomstick replaces the machine gun |
| Furnace Stalker — **Thunderjaw** | Boomstick replaces the flamer |
| Thunderstep Bruiser — **Breach Cannon** | Adds a chest boomstick |

Variants are researched in the Great Forge ("Alternate Armaments" row; each needs the unit plus Heavy Gunnery). They are chosen per unit in the Army Loadout
and saved in the profile. They deploy as `uid@variant`, which the registry resolves into a combat definition.

### 1.4 Research
- Branch E gates: T3 **Dedicated War Frames**, T4 **Heavy War Frames**, T5 **Colossal Mechanical Frames**, which now requires Heavy War Frames.
- Tier gates are unchanged from M001: T1 opens at Stage 002, T2 at 015, T3 at 045, T4 at 075, T5 at 105.
- The full T5 arsenal is therefore **not** reachable in Act I. In the current campaign (Stages 001–015) the reachable frames are T1–T2
  (Miner Rig, Boiler Stomper, Drillwalker, Steam Loader, Piston Brawler, Copper Sentinel). T3–T5 frames are playable in the **Test Sandbox**.

### 1.5 Audio
- New synthesized categories: boomstick (layered), axe swing, hammer impact, drill, mech MG, heavy cannon, mech step, colossal step, electric arc, flame.
- Every generated stream is **soft-knee compressed and peak-normalized to 0.89**.
- Per-sound voice limits are enforced (for example, boomstick is limited to 2 voices).

### 1.6 The Great Forge hub (new main hub after PLAY)
The title screen's **PLAY** button descends into an animated, scrollable cavern at the mountain's root: the hub world is 2,600 px wide and supports drag, wheel and arrow input.

The heart of the forge sits in the middle: a molten core inside rotating brass rings, lava veins and falls, a working steam hammer with anvil sparks, and bellows.
Around it are six stations:

| Station | Opens |
|---|---|
| War Table | Campaign |
| Armory Gate | Army Loadout |
| Forge Heart | Great Forge research |
| Assembly Bay | Test Sandbox; an Ironclad Walker stands on the gantry |
| Hall of Records | Compendium |
| Pressure Valves | Settings |

Ambient life: animated dwarf workers, an overhead crane and mine carts on rails. The top bar has Title and Deploy; a bottom nav bar mirrors the stations.

### 1.7 Preserved from M001
- All 18 M001 units, the 14 undead, Mine Maw, Stages 001–015 and simultaneous air/ground combat.
- No heroes.
- Saves migrate: an M001-format profile gains `variants` and `mech_doctrine` defaults and keeps its progress.

Two small M001 changes:
- Melee reach is now measured along the ground for ground targets, so tall frames' high-mounted fists can swing down.
- AA mounts may fire up to 40° below horizontal, so shoulder guns on colossal frames can engage flyers at their own height.

---

## 2. Tested (final run in this environment)

### 2.1 M002 suite `--suite=mecha`: 41/41 PASS
**Per-frame checks** run for each of the 28 frames and each of the 3 variants, every one passing:
spawn as a mech · walk on an empty field with foot plants · acquire targets · zero invalid targets (wrong side or wrong domain) · damage dealt ·
ranged attacks only within range · melee only at contact · AA engages flyers when the frame has AA · Steam spent = cost × uses exactly ·
cooldowns honoured · Steam never negative.

The remaining cases:

| # | Case | Result |
|---|---|---|
| 8 | Drill cannot multiply | 36 hits in 20 s (max allowed 41 at one per 0.5 s) |
| 9 | Boomstick pellets | Breacher: 7 shots, 42 pellet hits (≤ 7 per shot), 0 violations |
| 11 | Independent multi-weapon targeting | Deepforge Titan: cannon and AA on different targets 63 steps; left and right AA on different flyers 62 steps; cannon never aimed at air |
| 12/13 | Doctrine and arbitration | from 60 Steam with 5 ready frames, activations in 3 s: Conserve 0 · Standard 3 · Overdrive 3 (0.5 s global gap) |
| 14 | Ability cancelled on death | Anvilbreaker killed mid wind-up: 0 damage dealt afterwards |
| 15 | Dead frames release targeting references | 0 stale references; frame removed after its 1.7 s destruction sequence |
| 16 | No invisible collision | dead frame never returned as a blocker |
| 17 | Repair works but is bounded | 4 crews on a damaged Mountain Colossus = 34.0 HP/s (cap 34); destroyed frame stays destroyed |
| 18 | Colossal frames don't block allies | Militia walked past a stationary King's Anvil (x 470 → 1126) |

### 2.2 Scenarios A–F (`--suite=mecha_scenarios`, 120 s cap each): 6/6 PASS
All six had **0 invalid target references**.

| Scenario | Undead left | Dwarves left | Time | Notes | Worst step |
|---|---|---|---|---|---|
| A — Miner Rig, Riflemen, Flying Machines | 0/22 | 8/8 | 21 s | both fronts engaged 28 steps | 1.2 ms |
| B — Drillwalker and Cannon Strider vs armored undead and Hulks | 0/8 | 3/3 | 31 s | — | 0.4 ms |
| C — Skyguard and Flak Colossus vs dense air | 0/20 | 2/2 | 10 s | — | 0.7 ms |
| D — Anvilbreaker, Shieldframe, riflemen, artillery | 0/24 | 9/9 | 23 s | — | 1.0 ms |
| E — Deepforge Titan alone | 4/26 | titan survived | 120 s | both fronts 292 steps | 2.9 ms |
| F — 6 heavy/colossal frames plus combined arms vs a 75-unit counterattack | 0/75 | 16/18 | 44 s | all 6 frames survived; both fronts 423 steps; projectiles ≤ 15/260, FX ≤ 139/520 | 2.8 ms |

### 2.3 Audio, save and regression suites
| Area | Result | Measured |
|---|---|---|
| 23 Audio | PASS | 38 streams, loudest peak 0.72 (ceiling 0.89, none clipped); 10 simultaneous boomstick requests → 2 voices |
| 22 Save | PASS | M001-format save migrated with progress, unlock and loadout intact; Breacher researched, selected, reloaded from disk and deployed as `breacher_boomstick` |
| Regression: project import and parse | PASS | no errors |
| Regression: registry | 2/2 PASS | 160/110/15/150; 44 implemented dwarves all act, including the AA-only frames vs flyers |
| Regression: combat A–J (M001) | 8/8 PASS | — |
| Regression: Mine Maw boss | 1/1 PASS | — |
| Regression: UI smoke | 8/8 PASS | — |
| Regression: save write + fresh-process verify | PASS | — |
| Regression: Stages 001–015 winnable / losable | 30/30 PASS | auto-commander wins all 15 (184–639 s) with Miner Rig/Boiler Stomper in reachable loadouts; with no deployments the stronghold falls in 71–259 s |
| Linux desktop export | built + launched | 600 frames under a virtual display; no script errors (only "no ALSA audio device" in the container) |
| Android export | built + signed | `0.2.0-M002`, arm64-v8a + armeabi-v7a, debug-signed, v1/v2/v3 verified. **Not installed or run on a device** |
| Logs | — | 0 `SCRIPT ERROR` lines in all suite logs |

Screenshots (virtual display, software GL) are in `docs/screenshots/`:
- `09_forge_hub.png`, the Great Forge hub
- `10_` and `11_mechs_*.png`, all 28 frames
- `12_mech_scale.png`, the class scale lineup beside a Rifleman
- `13_sandbox_MF.png`, scenario F in battle

---

## 3. Limitations (honest)
- **Not device-tested.** No Android FPS was measured. The step times above are logic-only on a server CPU, and rendering 6 colossal frames on a phone is unknown.
  The APK has the same caveat as M001: stub SDK tools at export, then zipaligned and debug-signed with uber-apk-signer. It has not been installed on a device.
- **Art is procedural vector art drawn in code**, not hand-painted sprites. All 28 frames share one rig with distinct parts, so they read as one family by design.
  Animation is procedural rather than keyframed.
- **Audio is synthesized**, normalized but placeholder quality.
- **T3–T5 frames are not reachable in the current campaign.** Their tiers open at Stages 045, 075 and 105, which are still *planned*, so they are sandbox-only for now,
  as the spec's "do not grant the full T5 arsenal in Act I" requires.
- **Balance is provisional.** Stats follow the M002 table, scaled into the M001 economy (HP and damage ×0.75, Gold ×0.45). In the tests, colossal frames dominate
  mid-sized fights; human playtesting is needed.
- The auto-commander used by stage tests has no special mech logic; it deploys frames like any other unit.
- Abilities are automatic under the doctrine. There is no manual per-frame trigger.
- Godot prints benign "ObjectDB instances leaked at exit" warnings when headless test processes quit.

## 4. Next
Campaign Acts II–V (to open T3–T5 naturally), corrupted undead machines as dedicated anti-mech threats, final sprite art and recorded audio,
on-device profiling and draw-call budgeting for colossal frames, and an optional manual ability button per deployed frame.
