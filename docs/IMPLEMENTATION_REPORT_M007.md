# M007 — The Fallen Foundries: Act IV, wreck reclamation, foundry hazards, Heroic difficulty

Engine: Godot 4.3-stable (GL Compatibility). Date: 2026-11-02. Version 0.7.0-M007 (Android version code 10).
Everything marked **tested** ran in this build environment: headless, or on a virtual X display with software
OpenGL for screenshots and the benchmark. **The build has not been run on an Android phone.** No on-device frame
rate is claimed. The M001–M006c reports are kept unchanged next to this one.

Built from `MASTER_PROMPT_M007.md`, plus three requests made in the session: better animation for all dwarves, a
war-frame redesign "more inspired by Gundam, but more dwarven and more steampunk", and removing the "cling" on every
tap (§8).

---

## 1. What was built

### 1.1 Campaign: Act IV, stages 091–120
30 authored stages (`tools/act4_data.py`, composed with `tools/stage_kit.py` like Acts II–III) replace the planned
placeholders, in four new environments. The act opens on a gravegun tank behind a thrall column (091). It then
introduces possessed drillwalkers (092), furnace vents (093), **wreck reclamation** (094), howitzers in a flak-spire
chimney forest (095), timed "production line" thrall bursts (096), the slag flow (097), a massed-gravegun
anti-armour exam (098) and the first cursed ironclad (099). The second half brings steam leaks (102), burrowers from
below (103), heavy reclamation pressure (104), collapsing gantries (107, 118) and carrier barges (111). It builds to
the combined-arms exam at 119. 10 stages carry a hazard; 18 field at least one corruptor; every stage has `wrecks: true`.

Bosses: **The Fallen Titan** (100), **Ashen Forge Tyrant** (110), **Corpse Colossus** (120). Clearing **105 opens T5**
(the gate already existed in `tech.json`; 105 also carries `open_tier: 5`).

New toolkit templates: `reclaim_squad(...)` (corruptor tracks, always with `until`), `production_line(...)` (thrall
bursts on a strict cadence as timed events) and `corrupted_column(...)` (corrupted machines behind an infantry
screen). The validator learned the new hazards and the `no_reclaims` challenge. `stage_kit.heroic_block()`
generates every stage's Heroic block (§1.6).

### 1.2 Wreck reclamation (the act's signature mechanic) — `scripts/battle/foundry.gd`
| Rule | Value |
|---|---|
| Who leaves a wreck | A dwarven `vehicle`, war frame (`walker`), `aircraft` or `airship` destroyed on a stage with `wrecks: true` (all of Act IV). Escort barges and deployables (turrets) never do. |
| How it looks | The dead machine stays on the field: its own art, darkened, settled on its belly (aircraft fall to the ground first), with scorch marks, a torn plate, embers and smoke on top; a brass cog marker above it fades with its remaining life; a cog on the minimap |
| Lifetime / cap | 20 s; never more than **6** wrecks (the oldest crumbles first) |
| Corruptors | `corpse_priest`, `rot_channeler`, `ash_hexer` (data flag `reclaims: true`). Each looks for the nearest free wreck ahead of it (460 px). It walks there, but only through gaps: the dwarven line blocks it. Within 70 px it **channels for 4 s**, and stops attacking meanwhile. Death, stun or being pushed away breaks the channel. |
| Telegraph | A pulsing green glow and arc on the wreck, a beam from the corruptor, a progress ring, a choir sound; the minimap cog pulses green. A raise emits green spirit bursts, a necrotic blast, shake and an alert line. |
| Raised machine | By class: war frame → `possessed_drillwalker` (frames over 900 Gold: 40 % `cursed_ironclad`); aircraft → `haunted_flying_machine`; tank by cost → `risen_copperback` (< 260 Gold), `gravegun_tank` / copperback (< 700), `gravegun_tank` / `cursed_ironclad` (heavier) |
| Salvage | `salvage_crew`, `armored_recovery_team`, `heavy_recovery_crawler`, `field_mechanic` (`salvages: true`). Unless a machine in range is below 40 % HP, they head for the nearest wreck (420 px; channelled wrecks first) and clear it in **3 s**. That refunds 15 % of the machine's Gold cost (max 160). Salvage wins any race it starts first. |
| Stats | `stats.salvaged` / `stats.reclaimed` in the profile; `no_reclaims` challenge ("Let the undead reclaim no wreck") on 094, 104, 108, 116 |

### 1.3 Hazards
| Hazard | Behaviour | Visual / audio |
|---|---|---|
| `furnace_vents` | Fixed grates (`vents: [x…]`) erupt **in turn** across the `interval` (so the lane always has a gap). Each glows for 1 s (`warn`), then a pillar of fire hits ground units of **both sides** within `radius` for `damage`. Machines (vehicles, walkers, artillery, mechs, machine armour) take **50 %**; bosses and structures are immune. | Grates under the units glow orange, a warning arc, a flame pillar of batched DOT quads; a low rumble at the warning and a vent roar |
| `slag_flow` | Every `interval`, a molten river creeps from `x0` toward `x1` at `speed` for `duration` s. Ground units inside take `dps` (machines 70 %) and are slowed (`slow`). Air and burrowed units are unaffected. A 1.6 s warning comes first. | A glowing crack at the source, the river as a dark crust with pulsing orange DOT quads and a bright advancing lip, cooling over 2.5 s; a slag hiss |
| `steam_leak` | A burst pipe at each x in `pipes`. While a dwarven machine stands within `radius`, the player's Steam rises by `regen`/s (+5/s per pipe). Everyone inside (both sides) takes `dps` scald damage. | An iron main with a broken end, a steam plume (thicker while it feeds you), a faint reach circle on the ground; the pipe coughs now and then |
| Collapsing gantries | A `rockfall` variant (`variant: "gantry"`, `warn: 2.2`): bigger damage (150–160), smaller radius (36), longer telegraph | A girder sways on its last chain, sheds rivet sparks, then drops in the final 0.35 s onto a darkening shadow; girder groan and crash |

Each hazard has a drawer pill (gantries show as "Collapsing gantries"), a drawer description, a first-encounter
hint, sounds, and a dedicated test (§4).

### 1.4 Bosses
| Boss | Kit (existing) | M007 phase (tested) | Intended counters |
|---|---|---|---|
| **The Fallen Titan** (100) | Corrupted Overdrive, Titan Stomp | At 50 % it tears a wreck from the ground and raises it as an escort. The first time it uses the graveyard's own wreck (a cursed ironclad); after that, every 18 s it reclaims the nearest dwarven wreck within 700 px, if there is one. Each reclaim strips plates from its core: **+25 % damage taken for 8 s** (a glowing core is drawn). | Tank destroyers, siege artillery, salvage crews to deny wrecks |
| **Ashen Forge Tyrant** (110) | Ash Storm, Forge Fury | At 50 % the arena's 8 vents fire **in sequence** every 16 s, from the furnace (2140) toward the dwarven line (880). Each has its own 1 s glow, 0.55 s apart, so a push can be timed between bursts. The grates are drawn even where the stage hazard has none. | Long-range artillery, air strikes, timing ground pushes between vents |
| **Corpse Colossus** (120) | Disgorge Horde, Siege Slam | At 50 % it hurls a corpse at the **dwarven stronghold** every 11 s: a tumbling body on a long arc with a 1.6 s target telegraph, 260 damage to the stronghold and 30 % splash nearby. At 25 % it disgorges a gravegun tank and a risen copperback, once. | A strong ground front + bombers, anti-swarm, keeping the stronghold repaired |

All three get the M005 arrival pan and boss sting.

### 1.5 Battle environments
| Env | What is in it |
|---|---|
| `industrial_city` | Smog-orange sky with a hazy sun; a far skyline of foundry halls (some sawtooth-roofed, some lit windows) and a chimney forest trailing black smoke; gantry cranes; a brick rail viaduct on arches; fallen signs and crates behind the lane; cobbles and twin rail lines in front; green corruption seeping down seams |
| `destroyed_forge` | A dim red glow under a lid of smoke; cold blast furnaces with iron bands, dead tap holes (some still faintly lit) and smoke; tipped crucibles with frozen slag pours; anvils; slag-crusted floor and two cooling channels in front |
| `infested_factory` | Interior: sooted roof truss, broken skylights with shafts of grey light, tall arched windows, steam mains with valves along the wall, two giant idle flywheels, hanging chains with hooks, assembly lines of half-built frames crusted with green fungus; conveyor rollers and oil pools in front |
| `mech_graveyard` | A dusty brown haze; rusted colossus heads half-buried (one dead eye still faintly green), a fallen war-frame colossus on its back with one arm raised, a broken leg and torso, giant gears; scrap heaps behind the lane; oil-black earth and buried gear teeth in front |

City, forge and graveyard skies get **drifting smog** on the M006 parallax cloud layer (one batched draw, moved
by transform). All props stay behind the lane (above `GROUND_Y − 22`) or below it.

### 1.6 Heroic difficulty
- **Unlock:** every cleared stage (Acts I–IV, 120 stages) unlocks a Heroic version. The brass-and-blood
  **Heroic toggle** in the stage drawer shows red-gold Heroic stars and the modifier list, and turns the button
  into "Deploy — Heroic".
- **Smarter, not bigger** (`Registry.heroic_stage(id)` applies the stage's `heroic` block to a copy; same seed and
  layout):
  - one extra authored event (by default at 3:30, or 2:30 on boss stages): the stage's heaviest ground set-piece
    enemy + 4 of its main melee;
  - track intervals ×0.85;
  - +1 support structure (by act: bone spire / necrotic beacon / flak spire / soul turret);
  - enemy abilities ready sooner (initial cooldown ×0.45);
  - enemy HP ×1.12 (the generator asserts ≤ 1.15).
- **Overrides** (allowed by the toolkit): 098 and 117 needed gentler Heroic blocks (intervals ×0.92, HP ×1.05, a
  lighter event; 098's extra structure is a barricade rather than a soul turret) to stay winnable with pre-T5
  technology (§3.1).
- **No T5 needed:** Heroic sims use the stage's realistic army with every T5 unit removed (`--heroic`), and a
  test checks the Heroic loadouts.
- **Rewards:** separate stars (best ever, per star); a one-time Spark payout on the first Heroic clear (35 % of
  the stage's Sparks); a red-gold banner with a gold crest on the Realm Map. Replays and Heroic stars pay nothing
  else.
- **Data / tools:** `heroic` block per stage in `stages.json`; `--suite=stages --heroic`,
  `--suite=probe --heroic`, `batch_sim.py --heroic`.

### 1.7 Realm Map (Act IV)
- **Landmarks:**
  - city: a smokestack block with a viaduct;
  - forge: a great furnace with a crucible;
  - factory: a sawtooth-roofed hall;
  - graveyard: the rusted head of a fallen colossus, with one eye green while corrupted.
- **Boss set pieces:**
  - **100**: the Fallen Titan in a ring of scaffolding;
  - **110**: an ash throne inside a furnace mouth;
  - **120**: a mountain of corpses with a stitched siege engine.
- **Chimneys** (live layer, cheap circles): uncleared landmarks belch **green** smoke. Cleared ones run **clean grey**
  with a forge glow at the mouth.
- **Heroic-cleared** landmarks fly a **red-gold banner**.

### 1.8 UI
- **Stage drawer:** the Heroic toggle, Heroic stars and modifiers (§1.6); hazard pills and descriptions for the
  new hazards.
- **Battle HUD:** wreck cogs on the minimap; a wreck being channelled pulses green there and on the field.
- **Compendium:**
  - corrupted machines show "Raised from: a fallen <dwarven machine>";
  - corruptors show "Reclaims wrecks";
  - salvage units show "Denies wrecks".
- **Hints:** first-encounter lines for corruptors and the four hazards.
- **Victory plate:** "HEROIC VICTORY" with its own Spark line.
- **Settings:** "Button sounds" (§8.3).

### 1.9 Audio
- **Ambience:** four new loops (synthesized like the rest):
  - city: wind moaning through chimneys, a far hammer, a swinging chain;
  - dead forge: the cold foundry's hum, slow distant hammering, oil dripping;
  - factory: chains clinking on idle conveyors, a dead machine's hum, drips;
  - graveyard: dusty wind, creaking rusted plates, a loose chain.
- **Hazard cues:** vent rumble and roar, slag hiss, pipe burst, girder groan and crash.
- **Reclamation:** a channel choir, a reclaim sting (wrong choir, wheezing engine, boom), a salvage ratchet, and a
  wet corpse impact for the Colossus.
- **Corrupted machines:** "recognisably dwarven engines with a wrong, wheezing, choir-like undertone". A
  rumbling engine layered with a wheezing chuff and a detuned minor-triad choir plays now and then near corrupted
  machines. It uses the presentation RNG, so it never touches gameplay.
- **Cache:** the sound cache version is now `m007-1`, so the first launch after updating re-synthesizes once.

### 1.10 Progression and rewards
Blueprints follow §8 of the master prompt in order; none had been awarded before, so none became Sparks. Sparks
are 180 → 252 per regular stage (`_sp(n) = 180 + 2.5·(n−91)`), 260 at 105, and 380 / 420 / 460 for the bosses.
Act IV pays 7,110 Sparks: 16,126 cumulative by 105 and 18,606 by 115, before star bonuses. Opening T5 (Age of
Colossi, 260) plus a T5 unit (230 each) is affordable the moment it opens, well before 115.

### 1.11 Save compatibility
New fields, all filled by `SaveManager.migrate()`:

- `heroic` (stage → stars, clears, best time);
- `settings.ui_sounds` (default off);
- `stats.salvaged`, `stats.reclaimed`, `stats.heroic_clears`.

Malformed Heroic entries are repaired. Tested: an M006 save loads with all progress, opens Act IV at 091, offers
Heroic for cleared stages only, and opens T5 on clearing 105 (§4).

---

## 2. Balance: how it was tuned
The same method as M004–M006: every stage was played headless to the end by the scripted **AutoCommander** with
a realistic army, plus an **idle** run (no deployments) that must lose. Normal and Heroic were both swept.

- **Army assumptions (Act IV).** `_act4_loadout(i)` in `tests/test_runner.gd` builds the army a player owns on
  reaching stage *i*: the T0 starters, every blueprint rewarded before *i*, and the common Act I–III unlocks.
  From that it fills seven ground roles (line holder, heavy tank, flame, armour-piercer, artillery, anti-air,
  salvage), four air slots and one war frame. It never uses a unit the player cannot own yet.
- **Heroic Act IV sims use no T5 units** (`no_t5`, tested): Heroic must be winnable without the newest tier.
- **The "saver" AutoCommander (Act IV only, new).** Act IV armies are built around 500–1,100 Gold war machines.
  The M006 commander spent every coin on cheap infantry the moment it had it, never fielded a heavy, and lost
  to the Fallen Titan with the Titan untouched. In `saver` mode it keeps spending when the front is urgent (at
  least three enemies near the base, the base below 60%, fewer than two units holding the front, or air
  pressure). Otherwise it saves for a heavy unit (at least 450 Gold, ground, not a salvager) if none has been
  deployed in the last 20 s. Acts I–III use the unchanged M006 commander, so their numbers are identical to
  M006.
- **Rounds.** Act IV took five rounds:
  - r1: 7 losses (the bosses and 3 regular stages);
  - r2–r3: budget and wave tweaks (`k` multipliers on the corrupted columns and openers);
  - r4: 0 losses after the saver commander;
  - r5: pacing fixes for stages that ran long or ended under 5 minutes.
- **Heroic.** The Heroic block is generated from the normal stage (§1.6), then swept. Stages that failed or
  ran far too long got a lighter block. This happened for 13 stages, listed in §7.

## 3. Results

### 3.1 Sweep summary (stages 1–120, normal and Heroic; 480 runs)
| Act | Normal: commander | Normal: idle | Heroic: commander | Heroic: idle |
|---|---|---|---|---|
| I (1–30) | 30/30 WIN · 3:07–14:37 · mean 6:21 | 30/30 LOSS · 71–259 s | 30/30 WIN · 3:09–13:43 · mean 7:08 | 30/30 LOSS · 67–224 s |
| II (31–60) | 30/30 WIN · 3:49–12:32 · mean 5:53 | 30/30 LOSS · 71–222 s | **29/30** WIN · 6:15–14:35 · mean 10:48 (050 lost, see §3.3) | 30/30 LOSS · 70–210 s |
| III (61–90) | 30/30 WIN · 4:59–13:00 · mean 7:45 | 30/30 LOSS · 60–161 s | 30/30 WIN · 6:36–13:12 · mean 9:06 | 30/30 LOSS · 57–150 s |
| **IV (91–120)** | **30/30 WIN · 4:56–12:46 · mean 8:21** (lowest stronghold 68%) | 30/30 LOSS · 101–147 s | **30/30 WIN · 6:23–13:54 · mean 10:27** (lowest stronghold 58%) | 30/30 LOSS · 98–142 s |

Normal: 240/240 as expected (every commander run wins, every idle run loses). Heroic: 239/240. Acts I–III normal
numbers are identical to the M006 report (same data, same commander). The Act IV idle losses (101–147 s) sit in
the same range as earlier acts: a player who does nothing loses in about two minutes.

### 3.2 Act IV stage table (normal + Heroic)
Generated by `python3 tools/report_tables.py build/sims_final.csv build/sims_heroic_merged.csv 91 120`.
"Budget" is the stage_kit difficulty budget, and the Sparks column gives each stage's payout with the running
total in brackets. Boss stages are in bold.

| Stage | Name | Env | Hazard | Budget | Auto-commander | Idle loss | Heroic (commander / idle) | Blueprint(s) | Sparks (cum.) | Challenge |
|---|---|---|---|---|---|---|---|---|---|---|
| 091 | Cinderhaven Gates | industrial_city | — | 152.7 | WIN 7:20 (stronghold 100%) | LOSS 104s | WIN 9:24 / LOSS 102s | royal_iron_guard | 180 (13121) | Lose at most 36 units |
| 092 | Rustworks Row | infested_factory | — | 138.5 | WIN 8:26 (stronghold 100%) | LOSS 103s | WIN 10:31 / LOSS 99s | thunder_rifleman | 182 (13303) | Never let the stronghold drop below 60% |
| 093 | The Cold Forge | destroyed_forge | furnace_vents | 191.9 | WIN 8:18 (stronghold 100%) | LOSS 108s | WIN 9:25 / LOSS 106s | furnace_assault_trooper | 185 (13488) | Win with at most 8 unit types deployed |
| 094 | Boneyard of Engines | mech_graveyard | — | 139.0 | WIN 6:40 (stronghold 100%) | LOSS 124s | WIN 9:46 / LOSS 125s | heavy_recovery_crawler | 188 (13676) | Let the undead reclaim no wreck |
| 095 | Smokestack Alley | industrial_city | — | 160.0 | WIN 9:25 (stronghold 100%) | LOSS 111s | WIN 10:58 / LOSS 111s | counter_curse_technician | 190 (13866) | Destroy every undead support structure |
| 096 | Assembly Line of the Dead | infested_factory | — | 121.2 | WIN 7:11 (stronghold 100%) | LOSS 101s | WIN 11:10 / LOSS 99s | rune_cannon | 192 (14058) | Lose at most 38 units |
| 097 | Slagrun | destroyed_forge | slag_flow | 157.9 | WIN 8:56 (stronghold 100%) | LOSS 113s | WIN 10:20 / LOSS 113s | siegecrawler | 195 (14253) | Never let the stronghold drop below 60% |
| 098 | Gravegun Yards | mech_graveyard | — | 144.0 | WIN 10:37 (stronghold 100%) | LOSS 128s | WIN 12:42 / LOSS 123s | thunderrail_tank_destroyer | 198 (14451) | Lose at most 40 units |
| 099 | Cursed Ironworks | infested_factory | — | 120.9 | WIN 7:08 (stronghold 100%) | LOSS 104s | WIN 11:58 / LOSS 101s | anvilbreaker | 200 (14651) | Win within 11:00 |
| 100 | **Titanfall Foundry** | mech_graveyard | — | 67.0 | WIN 5:46 (stronghold 100%) | LOSS 112s | WIN 7:23 / LOSS 108s | siegebellow, furnace_guardian | 380 (15031) | Slay the boss within 9:00 of its arrival |
| 101 | Ashen Boulevard | industrial_city | — | 147.4 | WIN 5:32 (stronghold 100%) | LOSS 110s | WIN 7:11 / LOSS 110s | runebreaker_infantry | 205 (15236) | Lose at most 40 units |
| 102 | Bellows of Hate | destroyed_forge | steam_leak | 117.4 | WIN 4:56 (stronghold 100%) | LOSS 106s | WIN 6:23 / LOSS 102s | heavy_gatling_dwarf | 208 (15444) | Never let the stronghold drop below 60% |
| 103 | Drillbit Depths | infested_factory | — | 155.9 | WIN 5:56 (stronghold 100%) | LOSS 102s | WIN 7:46 / LOSS 100s | mobile_forge_crew | 210 (15654) | Win with at most 8 unit types deployed |
| 104 | Wreckers' Field | mech_graveyard | — | 114.1 | WIN 5:32 (stronghold 100%) | LOSS 147s | WIN 6:23 / LOSS 138s | automated_turret_crew | 212 (15866) | Let the undead reclaim no wreck |
| 105 | The Great Smelter | destroyed_forge | furnace_vents | 131.8 | WIN 5:37 (stronghold 100%) | LOSS 112s | WIN 9:03 / LOSS 109s | mountainshield_heavy_tank, firestorm_assault_tank | 260 (16126) | Lose at most 46 units |
| 106 | Chimney Wood | industrial_city | — | 147.8 | WIN 10:35 (stronghold 100%) | LOSS 107s | WIN 12:29 / LOSS 104s | dreadplate_breaker | 218 (16344) | Destroy every undead support structure |
| 107 | Hall of Pistons | infested_factory | gantries | 173.2 | WIN 10:11 (stronghold 100%) | LOSS 102s | WIN 12:29 / LOSS 100s | siege_hammer_walker | 220 (16564) | Lose at most 42 units |
| 108 | Iron Ossuary | mech_graveyard | — | 163.6 | WIN 11:34 (stronghold 100%) | LOSS 122s | WIN 13:54 / LOSS 118s | flak_colossus | 222 (16786) | Let the undead reclaim no wreck |
| 109 | Furnace Heart | destroyed_forge | furnace_vents + slag_flow | 157.7 | WIN 9:02 (stronghold 98%) | LOSS 116s | WIN 11:47 / LOSS 112s | thunderstep_bruiser | 225 (17011) | Never let the stronghold drop below 60% |
| 110 | **The Ash Throne** | destroyed_forge | furnace_vents | 80.3 | WIN 6:11 (stronghold 100%) | LOSS 129s | WIN 6:46 / LOSS 124s | shredder_walker, forge_bomber | 420 (17431) | Slay the boss within 9:00 of its arrival |
| 111 | Carrier Wharf | industrial_city | — | 120.3 | WIN 7:51 (stronghold 100%) | LOSS 140s | WIN 12:10 / LOSS 142s | thunder_rocket_battery | 230 (17661) | Lose no aircraft |
| 112 | Rotting Turbines | infested_factory | — | 152.9 | WIN 9:50 (stronghold 100%) | LOSS 101s | WIN 12:41 / LOSS 98s | twin_flame_gunship | 232 (17893) | Lose at most 44 units |
| 113 | Colossus Tracks | mech_graveyard | — | 159.2 | WIN 10:26 (stronghold 100%) | LOSS 120s | WIN 12:09 / LOSS 117s | siege_breaker_bomber | 235 (18128) | Win within 11:30 |
| 114 | Molten Stair | destroyed_forge | slag_flow | 160.9 | WIN 9:05 (stronghold 100%) | LOSS 122s | WIN 11:09 / LOSS 119s | riftshield_walker | 238 (18366) | Lose at most 44 units |
| 115 | Siegeworks | industrial_city | — | 176.7 | WIN 11:05 (stronghold 100%) | LOSS 106s | WIN 12:58 / LOSS 102s | colossus_guard | 240 (18606) | Destroy every undead support structure |
| 116 | Plague Refinery | infested_factory | — | 163.6 | WIN 9:48 (stronghold 100%) | LOSS 101s | WIN 12:58 / LOSS 101s | arc_lance_gunner | 242 (18848) | Let the undead reclaim no wreck |
| 117 | The Scrapheap Crown | mech_graveyard | — | 133.6 | WIN 9:19 (stronghold 100%) | LOSS 133s | WIN 10:39 / LOSS 137s | kingsguard_bulwark | 245 (19093) | Lose at most 46 units |
| 118 | Ironfall Avenue | industrial_city | gantries | 205.2 | WIN 12:46 (stronghold 100%) | LOSS 115s | WIN 13:07 / LOSS 113s | mountain_siege_cannon | 248 (19341) | Never let the stronghold drop below 60% |
| 119 | Forge of Bones | destroyed_forge | furnace_vents | 136.1 | WIN 8:42 (stronghold 100%) | LOSS 120s | WIN 10:20 / LOSS 118s | celestial_flak_array | 250 (19591) | Lose at most 48 units |
| 120 | **The Charnel Engine** | industrial_city | — | 64.3 | WIN 6:56 (stronghold 68%) | LOSS 119s | WIN 7:33 / LOSS 117s | mountainbreaker, master_fabricator_team | 460 (20051) | Slay the boss within 10:00 of its arrival |

### 3.3 Bosses
Scripted counter plans (the `boss_*` tests) play each boss with a fixed sensible army and the AutoCommander;
9/9 pass.

| Boss | Stage | Mechanic | Counter result | Boss slain | Commander sweep |
|---|---|---|---|---|---|
| Fallen Titan | 100 | **Titan reclaim** (from 50% HP): every 18 s the Titan tears the nearest dwarven wreck (within 700 px) from the ground and raises it as a corrupted escort (the first time with no wreck nearby, it raises a cursed ironclad instead); its plates fall away and the core is *exposed* for 8 s (+25% damage taken) | WIN 357 s | 231 s | WIN 5:46 |
| Ashen Forge Tyrant | 110 | **Vent sequence** (from 50% HP): every 16 s a chain of furnace vents erupts from its throne towards your base (0.55 s per step, 1 s warning, 110 damage, radius 46) | WIN 288 s | 199 s | WIN 6:11 |
| Corpse Colossus | 120 | **Corpse throw** (from 50% HP): every 11 s it hurls a corpse ball at the stronghold (260 damage, 1.6 s warning shadow); at 25% HP it disgorges a gravegun and a risen copperback, once | WIN 375 s (stronghold 54%) | 289 s | WIN 6:56 (stronghold 68%) |

Stages 040–090 counter times are unchanged from M006. **Heroic 050** is lost by the auto-commander (it runs out
of front line at 4:24). The scripted counter plan wins it at 261 s, so it is winnable with a planned army, but the
generic commander cannot do it. This is reported as is and not hidden by a further nerf; see §7.

### 3.4 Spark economy
Cumulative Sparks (stage rewards only, no star bonuses): 12,941 at 090 → 16,126 at 105 → 18,606 at 115 → 20,051
at 120. Act IV pays 7,110. T5 opens at 105 and costs 260 plus 230 per T5 unit, so a player can afford it at once.

## 4. Tests
All suites ran in this build with **0 script errors**:
`godot --headless --path . res://tests/test_runner.tscn -- --suite=NAME`.

| Group | Suites (passed/total) |
|---|---|
| Core | registry 2/2 · combat 8/8 · boss 1/1 · save_write 1/1 · save_verify 1/1 · cache 1/1 |
| M002–M003 machines | mecha 41/41 · mecha_scenarios 6/6 · mecha_audio 2/2 · mecha_save 1/1 · giants 18/18 · giants_scenarios 4/4 · bosses_all 15/15 |
| M005 | hazards 5/5 · boss_phases 4/4 · stars 4/4 (now with `no_reclaims`) · m005_save 1/1 |
| M006 | air_war 8/8 · hazards_m006 6/6 · boss_phases_m006 3/3 · m006_save 1/1 · motion 2/2 |
| **M007 (new)** | **wrecks 5/5 · hazards_m007 5/5 · boss_phases_m007 3/3 · heroic 4/4 · m007_save 1/1 · audio_m007 1/1 · ui_m007 4/4** |
| UI | ui 8/8 · ui `--quality=low` 8/8 · ui_m005 4/4 · ui_m006 3/3 |
| Art | roster 0–135 pass · roster 135–270 pass · art_m006b 5/5 · artcheck 3/3 PASS |
| Sweeps | `tools/batch_sim.py` 1–120 normal 240/240 · `--heroic` 239/240 · boss counter plans 9/9 (+ Heroic 050 counter WIN) |

New M007 checks include:

- **Wrecks:** wrecks appear only where the stage enables them (Act IV), with cap, expiry, channel and salvage
  timings. Stun breaks a channel. The refund is capped. The reclaimed class follows the machine's cost.
- **Hazards:** vents warn before they erupt and machines take half damage; slag slows and burns ground units
  but not aircraft; steam refills Steam only while a machine stands in it; gantries fall only after a groan.
- **Bosses:** each boss's set piece fires on schedule.
- **Heroic:**
  - unlocks only after a normal clear;
  - HP ≤ +15%;
  - pre-T5 sims;
  - its own stars and rewards.
- **Save:** an M006 → M007 save migrates.
- **Audio:** see §8.3.

The pose-cache bounds were re-measured after the art changes. 78 of 291 arts changed; the old file is kept at
`build/art_bounds_before.json`.

## 5. Performance
Measured by `tests/bench.tscn` with the **low preset**, 150 frames after 200 warm-up frames, on software OpenGL
(llvmpipe) on a virtual display. These numbers are only for comparing builds against each other; they are not
a phone frame rate. Each scene ran twice on both builds.

| Scene | M006c baseline (run 1 / run 2) | M007 (run 1 / run 2) |
|---|---|---|
| Default crowd: frame | 73.17 / 62.01 ms | 64.68 / 66.60 ms |
| Default crowd: logic | 11.55 / 9.21 ms | 9.84 / 10.19 ms |
| Default crowd: draw calls | 393 / 392 | 403 / 405 |
| Machine crowd: frame | 79.69 / 73.81 ms | 63.16 / 66.20 ms |
| Machine crowd: unit draw | 4.83 / 4.38 ms | 2.44 / 2.52 ms |
| Machine crowd: draw calls | 354 | 356 |
| Stage 087 (Act III, busiest): frame / avg draw calls (max) | 54.43 ms / 331 (820) | 53.48 ms / 329 (820) |
| **Stage 118** (gantries, 69 units on screen) | — | 59.95 ms / 547 (1,351) |
| **Stage 119** (vents) | — | 68.17 ms / 484 (1,558) |

Environment backgrounds (same crowd, draw calls / frame):

| mountain_gate (Act I reference) | industrial_city | destroyed_forge | infested_factory | mech_graveyard |
|---|---|---|---|---|
| 397 / 66.65 ms | 515 / 76.77 ms | 416 / 74.39 ms | 549 / 81.32 ms | 428 / 69.99 ms |

**Reading:**
- **Frame and logic times** are within noise of M006c.
- **The redesigned war frames:** the machine crowd draws faster. That is the pose cache, not simpler art; the
  frames have more parts but bake once.
- **Act IV backgrounds** are the cost. The city and factory backdrops add about 120–150 draw calls (smoke
  stacks, girders, hanging chains). Every environment still averages under the 600 draw-call budget; stage
  peaks of 1,351–1,558 happen during heavy explosion bursts, as in earlier acts.
- **Untested:** the low preset has not been checked on a real low-end phone (see §7).

## 6. How to run the M007 checks
```
godot --headless --path . res://tests/test_runner.tscn -- --suite=wrecks          # also hazards_m007, boss_phases_m007, heroic, m007_save, audio_m007, ui_m007
python3 tools/batch_sim.py 91 120                    # Act IV sweep (commander + idle)
python3 tools/batch_sim.py 1 120 --heroic            # Heroic sweep
python3 tools/report_tables.py build/sims_final.csv build/sims_heroic_merged.csv 91 120
xvfb-run godot --path . res://tests/screenshot.tscn -- --shot=campaign_map --tab=3 --cleared=100 --select=97 --heroic_on --out=/tmp/d.png
```

## 7. Honest limits and deviations from the master prompt
Each item is something this build does differently from the prompt, or does not do:

1. **Boss HP.** The prompt lists 26,000 / 24,000 / 30,000 HP. By stages 100–120 the per-stage enemy HP
   multiplier is about ×2.4–2.8, so those base values would have meant 60,000–80,000 HP in battle. The three
   Act IV bosses therefore **ignore the stage multiplier** (`fixed_hp`). They were tuned with the
   auto-commander and the scripted counter runs to **11,000 / 13,000 / 15,000** HP, with 0.3 / 0.2 / 0.2
   armour and slightly reduced weapon damage. Each boss's set piece already adds effective HP: escorts
   raised from wrecks, vent chains, the disgorge.
2. **Act IV budget band.** The stage_kit floor for Act IV was lowered from 120 to **110** (the toolkit's own band, not a prompt value).
   Some early Act IV stages are meant as breathers after the act opener, and the floor was blocking them.
3. **Gantries** are a **variant of the M005 rockfall hazard** (a groan, a shadow, then girders falling), not a
   separate hazard system. Behaviour and visuals are their own; the code path is shared.
4. **Heroic is lighter on 13 stages.**
   - 11 Act I–III stages get a "gentle" block (interval ×0.92, HP +5%, a barricade): 14, 29, 38, 41, 50, 54, 57,
     71, 85, 87, 89.
   - Four of these get an even lighter "minimal" block (interval ×0.95, HP +3%): 14, 29, 50, 71.
   - Stages 098 and 117 have their own overrides.
   - Every other stage uses the default block (+12% HP, waves 15% faster, an extra set piece, an extra enemy
     structure, abilities ready sooner).
5. **Heroic 050 is lost by the auto-commander.** It is won by the scripted counter plan (261 s), so it is
   beatable. A further nerf would have made it barely different from normal, so it was left as is. A human
   player should find it hard but fair. This needs a playtest.
6. **The saver AutoCommander** is a test tool. It changes how the Act IV numbers were produced (§2), not the game.
7. **Not run on a phone.** The APK is a signed debug build, verified with apksigner (v1, v2 and v3 schemes). It
   was not installed or played on a device. Frame times are from software rendering.
8. **The art is procedural.** The war-frame redesign and the dwarf animation are drawn in code, like all
   earlier art. The "Gundam-inspired" brief was read as heroic-mecha proportions and detailing in an original
   dwarven design. No existing machine is copied.
9. **The Heroic text on the drawer is generated from data.** On some stages it shows the stage's own interval
   (for example "18% faster" on 097), not the default 15%.

## 8. Requests made in the session (on top of the master prompt)

### 8.1 War frames: the "Forge-Knight" redesign (all 28)
The request: "the mecha design is good but it can be better — more inspired by Gundam, but more dwarven, more
steampunk". The designs stay original. They borrow the *language* of heroic mecha (proportion, panelling, a
crested head with twin eyes, a thruster pack), not any existing machine. All of it lives in the shared rig in
`scripts/art/art_mechs.gd`, so every frame changes and keeps its M002 identity (body type, weapons, back gear,
colours):

| Part | Before (M006b) | After (M007) |
|---|---|---|
| Proportions | Short legs under a box torso | Legs 2–3 units longer per segment (a taller, heroic stance), a **V-tapered chest** over a narrow, segmented waist |
| Head | A plain helm/visor/grille box | A **horned V-crest** of swept brass horns with a forge-gem, **twin eye slits** that glow when engaged, cheek guards and a **braided-beard faceplate grille**. Each head type has its own reading: Forge-Knight helm; hunter's helm with a swept blade crest; forge-mask with ram horns and a furnace mouth; royal war-helm with a V-crest, crown and long beard plate; utility cowl with a lamp and antenna; open cab with the goggled driver. |
| Chest | A plain plate and insignia | Two-tone **enamel breast panels**, **steam intake grilles** either side of a riveted **furnace-core porthole** (it flares on abilities; rune-blue on rune frames), a brass collar, and the forge mark on the belly plate |
| Shoulders | Half-dome pauldrons | **Boxy, chamfered shoulder blocks** with an enamel top bevel, a panelled face, trim and rivets, layered lames below, a rune stud, and a swept fin on heavy and colossal frames. The near block is drawn over the arm root. |
| Waist | A single skirt | A side tasset, a front skirt plate, and a V of two hanging enamel plates with trim |
| Legs | Plate thigh, round brass knee | An enamel panel down the thigh; a **pointed knee guard** with a rune stud; a **flared shin** with steam slats and a brass **calf thruster nozzle**; a big **sabaton** with an enamel toe cap and ankle guard (the M006 heel-toe roll is kept) |
| Arms | A bare forearm | A flared, enamel-panelled **forearm guard** with a trim band at the wrist |
| Back | Stacks, boilers, belts | Plus **twin boiler thrusters** with brass bands and bell nozzles that vent steam: harder on the march, a burst with a forge flash on abilities. Utility frames get one. |

The two-tone "enamel" is each frame's own metal lifted toward an ivory forge enamel (`panel_col`). It is the
dwarven take on the white-and-colour mecha scheme, and it keeps the per-frame palettes (copper miners, blue royal
frames, rune-blue coil frames) recognisable.
Before / after sheets: `docs/screenshots/m007_mechs_before_1.png`, `…_2.png` and `m007_mechs_after_1.png`,
`…_2.png`; a close-up in `m007_mech_closeup.png`.

### 8.2 Dwarf animation (every dwarf drawn by the shared infantry body: infantry, engineers, gun crews)
- **March:** a real stride. Each leg is a slanted quad from the hip to the boot. Feet move ±6 (was ±4) and lift
  4.2 (was 2.5) on the forward swing, toe up; they land heel-first and roll flat. The body drops onto every
  footfall. In the slapstick layer the march squashes on each plant and stretches between, leans into the step,
  trails and swings the beard, and lets the helmet bob a beat behind the head.
- **Idle:** weight shifting from foot to foot, the beard rising and falling with each breath, and a glance down at
  the boots. This joins the M004 breathing, blink, bounce and hat fix.
- **Death:** a dwarf now goes down "like a sack of coal". The dead pose knocks his hat off, gives him X eyes and an
  open mouth, and blows his beard back. The node flops over backwards with a little bounce on landing. This is
  presentation only, and only for dwarven infantry and engineers; the undead keep their grim tip-over.
- Everything is a pure function of the pose, so it bakes into the pose cache. No new pose keys were added; walk
  stays at 8 steps per cycle.

Strip: `docs/screenshots/m007_dwarf_march.png`.

### 8.3 Sound refinement: the tap "cling" is gone
The "cling cling" on every tap was `ui_click`: a 1,200 Hz metallic clank with inharmonic partials at about
3.3 kHz and 6.5 kHz. It was played by every button, card tap, tab and drawer handle. Changes:
- **Button taps are silent by default.** A new Settings switch, **Button sounds** (default off), brings back a
  **soft felted tick**: one low sine (520 Hz falling), no metallic partials, about 50 ms. Its measured brightness
  is about 460 Hz (zero-crossing estimate).
- **Deploying** a card was a 300 Hz metallic clank; it is now a muffled boot-stamp and drum thump.
- **Mine upgrade** was the walker-step clank; it is now a low ratchet thunk.
- **Star stamps** on the victory plate lost their metallic ring (a soft tick plus a low thump).
- Gameplay sounds (guns, explosions, machines) are unchanged.
- Old saves get Button sounds off. Tested in `audio_m007`.

**Bug found and fixed on the way:** the sound cache's loop list (`LOOP_KEYS`) did not include the M006 ambience
loops (plains, high ridge, cloud sea, fort). After the first launch they were neither saved nor restored, so Act
III battles fell back to the mountain wind on every later launch. All loops are now listed (and the four new Act
IV ones); a test checks it.

## 9. Deliverables
- `build/android/DwarvesVsZombies-M007.apk` (47 MiB): debug build, exported with a stub SDK (no Gradle), then
  aligned and signed with the debug key by uber-apk-signer. zipalign and the v1/v2/v3 signatures are verified.
  Manifest version: 0.7.0-M007, code 10. SHA-256: `eb852f9615036059c863fdbee41b6544b339faf159172568a6255a45d7297336`.
- `build/linux/DwarvesVsZombies.x86_64`: release export. It ran for 300 frames under xvfb and exited with code 0.
  The only warnings were the missing audio device and the usual ObjectDB-at-exit notice.
- `DwarvesVsZombies_M007_project.zip`: the project without `.godot/`, `build/`, `*.import`, `.git` or
  `__pycache__`.
- This report, the README update ("What is new in M007") and the screenshots above.

### 9.1 Screenshots (all in `docs/screenshots/`)

| File | Shows |
|---|---|
| `m007_env_industrial_city.png` | Act IV environment: industrial city (stage 091) |
| `m007_env_infested_factory.png` | Act IV environment: infested factory (stage 092) |
| `m007_env_destroyed_forge_vents.png` | Act IV environment: destroyed forge, with a vent erupting (stage 093) |
| `m007_env_mech_graveyard.png` | Act IV environment: mech graveyard (stage 094) |
| `m007_hazard_slag.png` | Slag flow hazard |
| `m007_hazard_steam.png` | Steam leak hazard |
| `m007_hazard_gantry.png` | Falling gantry hazard |
| `m007_wreck_reclaimed.png` | The wreck-reclaimed banner, with a raised copperback on the enemy side |
| `m007_boss_fallen_titan.png` | Boss: the Fallen Titan |
| `m007_boss_ashen_forge_tyrant.png` | Boss: the Ashen Forge Tyrant, with its vent ring |
| `m007_boss_corpse_colossus.png` | Boss: the Corpse Colossus |
| `m007_realm_act4_a.png`, `m007_realm_act4_b.png` | Realm Map for Act IV. The landmarks and the boss set pieces at 100, 110 and 120 are visible; stages cleared on Heroic carry red-gold banners. |
| `m007_drawer_heroic.png` | Stage drawer with the Heroic toggle, the modifiers line and "Deploy — Heroic" |
| `m007_mechs_before_*.png`, `m007_mechs_after_*.png`, `m007_mech_closeup.png` | War-frame redesign, before and after |
| `m007_dwarf_march_before.png`, `m007_dwarf_march.png` | Dwarf march, before and after |

Boss clips (about 7 s each, 960 px wide) were sent with the delivery; they are not stored in the repo.
