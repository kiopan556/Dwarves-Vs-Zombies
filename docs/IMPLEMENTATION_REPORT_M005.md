# M005 — The Blighted Frontier: Act II, stage toolkit, tutorial and hints, 3-star ratings

Engine: Godot 4.3-stable (GL Compatibility). Date: 2026-11-01. Version 0.5.0-M005 (Android version code 6).
Everything marked **tested** ran in this build environment: headless, or on a virtual X display with software
OpenGL for screenshots and the benchmark. **The build has not been run on an Android phone.** No on-device frame
rate is claimed. The M001–M004 reports are kept unchanged next to this one.

---

## 1. What was built

### 1.1 Campaign: Act II, stages 031–060
30 authored stages replace the planned placeholders. Every stage has its own name, environment, enemy mix,
one-sentence tagline, rewards and challenge objective; 13 of them carry a hazard (stage 050 carries two). They introduce the Act II pool
one or two enemies at a time and then combine them, on both fronts in every stage. Bosses: **Blightroot
Behemoth** (040), **Plague Regent** (050), **Gravewing Matriarch** (060). The per-stage table with the final
tuning results is in §3.

Authoring lives in `tools/act2_data.py`; each stage is composed from `tools/stage_kit.py` templates (opener
horde, shield wall, artillery line, air raid, monster breakthrough, support cluster, boss arena, finale) and then
given its own set pieces, triggers, hazard and rewards.

### 1.2 Stage-authoring toolkit
| Tool | What it does |
|---|---|
| `tools/stage_kit.py` | Encounter templates (each takes enemy pools, an intensity `k` and timing, returns tracks/events/triggers/structures), `make_stage`, the challenge-objective vocabulary, and the **validator**. |
| Validator | Runs inside `gen_data.py` on every data build (the build fails on any problem) and standalone (`python3 tools/stage_kit.py`). Checks: every id exists; every ranged/artillery track has `until`; no static structure used as a track; `max_alive` ≤ 64; difficulty budget inside the act band; both fronts present; boss stages have `boss_spawn`; hazard fields; a valid challenge; a tagline. |
| `tools/batch_sim.py` | Runs a stage range as two parallel Godot processes (stages interleaved so both get early and late stages) and writes a CSV: stage, mode, result, time, stronghold %, citadel %, kills, losses, deployed, peak enemies, ok, wall time. |
| `tools/auto_tune.py` | Optional advisor: reads that CSV and prints suggested interval/`until`/event changes as a readable diff per stage, using the §12.2 rules. It never edits data. |

The runner gained `--only=` (stage list), `--mode=play|idle` and `--every=` (probe interval) for these tools.

### 1.3 Hazards
| Hazard | Behaviour | Visual / audio | Counterplay |
|---|---|---|---|
| `miasma` | Clouds spawn near the citadel every `interval` s and drift right-to-left at `speed` for `duration` s. Every 0.5 s they damage **organic ground units on both sides**: dwarven infantry and crews, undead flesh. Machines (vehicles, walkers), structures, flyers, spectres and bosses are immune; skeletons (bone armour) take half. Max 6 clouds. | Soft green-yellow dot clouds on one batched layer, densest above head height plus a low footprint band; gurgling hiss on spawn | Tanks and walkers hold the poison ground; time infantry deployments |
| `bog` | Fixed mire patches (`spots`, `width`, `slow`) slow every non-static ground unit of both sides standing in them. Air is unaffected. | Dark mire painted once under the units, reeds at the edges only (feet stay visible); squelch, rate-limited | Artillery over the bog, aircraft past it, hold the dry ground |

A stage may now carry **several hazards** (`hazard` can be a list): stage 050 has a bog in front of the palace
plus light miasma, which the Regent's phase thickens. The drawer shows one pill per hazard plus a one-line
description.

### 1.4 Battle environments and Realm Map
- **Battle backgrounds** (`BattleBackground.ENVS`): `dead_forest` (leafless tree lines, ruined watchtower, mossy
  trunks, crow perches, fallen trunks behind the lane, root cracks in front of it), `plague_marsh` (sickly sun,
  plague pyres, stilt huts, reed beds, fog bank, standing pools below the lane), `ruined_road` (broken aqueduct
  with a collapsed span, gibbets on the ridge, overturned wagons, milestones, cobbles with gaps) and
  `corrupted_mine` (fungal walls, timber galleries with creeping fungus, spore stalks, ore carts, drips, rails).
  All are painted once into the static background; props stay behind or below the lane.
- **Realm Map Act II**: landmark painters for the four environments (a ring of dead oaks around a hunter's lodge,
  a stilt village over black water, a gibbeted toll gate with a broken arch, an underground fungus-choked gallery
  with spore stalks, added to `UNDERGROUND`), and three boss set pieces (a colossal rotting tree whose roots grip
  the road; a plague palace with censers; a carrion nest atop a dead tree). `ENV_BUMP` sets marshes low and
  forests rolling; Act II's surface gets an extra gentle roll. Uncleared landmarks get the corruption look,
  cleared ones banners and lantern light, as in Act I.
- Stars on the signposts of cleared stages; a three-star stage flies a gold-trimmed banner; a one-time
  "ACT II · The Blighted Frontier" cartouche rises the first time the act is unlocked (stored in the save).

### 1.5 Boss encounters
All three bosses now have an **arrival pan**: the battle pauses, the camera glides to the boss, holds, and returns
(about 2.7 s; any tap or key skips it) with a synthesized boss sting. A bug found by screenshot: while paused,
off-screen units were never redrawn, so the pan showed an empty field; units are now refreshed during the pan.
Each boss gets a telegraphed **50 % phase** (`scripts/battle/boss_phases.gd`, data in the boss's `phase` dict);
the 35 % enrage is kept.

| Boss | 50 % phase (tested) | Intended counters |
|---|---|---|
| Blightroot Behemoth (040) | Every 20 s roots erupt under the dwarven artillery line: up to 3 telegraphed circles (1.6 s warning) under the rear-most artillery / hold-back units, 90 damage and a 50 % slow | Fire (the Behemoth now takes ×1.3 fire damage), long-range artillery, spreading the guns out |
| Plague Regent (050) | The Court summons two plague heralds (re-summoned 60 s after both die), the stage's miasma thickens (×1.5 spawn rate, damage and size) and an immediate cloud rolls out | Bombers and mortars on the court, armour through the acid |
| Gravewing Matriarch (060) | Every ~34 s she lands on her nest for 8 s as a **ground** unit (ground guns can target her) and wakes a flight of 5 blight bats and 2 skeletal vultures | Flak, twin flak mounts, interceptors; ground fire during the perch |

### 1.6 Stars and challenge objectives
- **Stars** (`Battle.stars_earned()`): ★ victory · ★ stronghold above 50 % at the end · ★ the stage's challenge
  objective. Each star is recorded best-ever, independently.
- **Challenge objectives** are data (`challenge` dict, with a display text generated by `stage_kit.ch()`), from a
  checkable vocabulary: `no_air_losses`, `time_under`, `base_above` (never below a fraction), `kill_structures`,
  `max_types` (distinct unit types deployed), `max_losses`, `kill_boss_by` (seconds after arrival). The battle
  tracks the minimum stronghold fraction, aircraft lost, deployed types, structures spawned/destroyed and boss
  arrival/death times. **All 60 implemented stages** carry one (Act I retrofit included).
- **Rewards are never power**: a first-time Spark bonus of +10 % of the stage's Sparks per newly earned star
  (at most +30 % per stage, ever); gold-trimmed Realm Map banners for three-star stages; a Compendium
  commendation (Recruit → Bronze Hammer at 30 ★ → Silver Anvil at 90 ★ → Golden Crown of the Holds at 150 ★).
- **Where they show**: brass stars on the Realm Map signposts, a stars-and-challenge row in the stage drawer, a
  total in the campaign header, and three animated star stamps on the victory plate with the challenge result and
  the bonus.

### 1.7 Tutorial and first-encounter hints
- **Guided stages 001–003** (`scripts/ui/guide.gd`): brass speech plates with an arrow next to what they explain
  (deploy cards, Gold, the air card, the minimap, pause, the Steam dial, the ability valves). Only the first three
  plates pause the battle; every plate goes away with one tap; plates that do not pause fade by themselves.
  On by default for **new saves only**; an existing save from an earlier milestone starts with it off; switching
  it on in Settings replays it.
- **First-encounter hints**: the first time a kind of threat appears (flyers, bone, heavy hides, giants,
  burrowers, corrupted machines, healers, aura-bearers, beacons, anti-air, siege, barricades, exploders) or a
  hazard is present, a one-line dismissible plate names a counter ("Machines ignore miasma — tanks and walkers
  hold the poison ground."). Tags are stored in the save so a hint never repeats; Settings turns hints off.
  During the guided stages the tutorial speaks and hints wait.
- The same lines appear as **"Counter:"** on undead dossiers in the Compendium and as **recommended counters**
  in the drawer of cleared stages only (nothing is spoiled).

### 1.8 Progression and rewards
- Blueprints follow §8 of the master prompt, in order; boss stages give two. The prompt's lists hold 8 units for
  the 9 regular stages of 041–049 and of 051–059, so the two gaps are filled with T2 units that no stage had
  awarded: **Boiler Stomper** (047) and **Bombard Gyro** (057). (Conflict noted in §7.)
- Sparks: 105–150 per regular stage, 240 / 270 / 290 for the bosses; Act II pays 4,235 Sparks (7,395 cumulative
  with Act I) before star bonuses. T3 research (Age of Iron 120 + ~110 per unit) is affordable throughout the act.
- The T4 gate stays at stage 075.

### 1.9 Audio
New synthesized sounds (disk-cached like the rest; cache version bumped to `m005-1`, so the first launch after
updating re-synthesizes once): `miasma` (gurgling hiss), `squelch`, `boss_sting`, `star_stamp`, and four ambience
loops (dead forest: dead-branch creaks and a crow; plague marsh: bubbles, wrong-sounding frogs, a buzz; ruined
road: creaking gibbets and a distant bell; corrupted mine: drips and spore puffs), built off the main thread with
the other loops.

### 1.10 Save compatibility
New profile fields `stars`, `hints_seen`, `tutorial_done`, `acts_revealed`, and settings `tutorial` / `hints`,
all defaulted by `SaveManager.migrate()`. A save without `stars` (any earlier milestone) gets `tutorial = false`.
Stages already cleared in an old save count as one star until replayed.

### 1.11 Auto-commander (test tool) generalised
The commander's hand-written rules only knew the 18 M001 unit ids, so from Act I-b on it ignored most of the
army it was given. It now has role-based fallbacks (front, anti-air, anti-armour, ranged, repair) that use the
registry role of any owned unit, counts generic anti-air and interceptors toward its quotas (before this, an army
without Flak Crews bought anti-air tanks forever), saves gold only for a unit affordable within ~6 s, and against
a ground boss fields its heaviest guns. M001 ids keep their rules and come first. A null-`role2` crash in the
first version was caught by the first Act II sweep (it deployed almost nothing) and fixed.

---

## 2. Tuning method and assumptions
- **Loadout assumption** (`loadout_for_stage`, Act II): T0 starters + every blueprint rewarded before the stage +
  the Act I-b research set (Steamgunner, Copperback, Steam Mortar, Twin Flak Mount, Bombard Gyro) + Boiler Stomper
  (T2, researched from 031) + Ironclad Walker (T3, from 042, once Age of Iron and Dedicated War Frames are bought
  with Act II Sparks). One pick per role (shield, tank, anti-swarm, rifles, artillery, ground AA, repair) for the
  7 ground slots, the best four owned aircraft, and a walker in the flex slot.
- **Commander**: Act I sims keep the M001–M004 commander unchanged; Act II sims use the generalised one (§1.11).
  The first Act II run with the M004 commander lost 25 of 30 stages because it simply never deployed most of
  its army; that was a tool limit, not stage balance.
- **Process**: `batch_sim.py` → `auto_tune.py` suggestions → edits in `act2_data.py` → re-run. Four full Act II
  rounds plus targeted boss runs. Main changes along the way: boss arenas made lighter and bosses arrive later
  (35 s → 45–60 s) with more starting Gold; ten stages under 5 minutes got extra set pieces, late trigger waves,
  higher citadels and a barricade near the citadel; three grinding stages (038, 054, 056) got earlier `until`s and
  thinner ranged tracks; the boss changes in §6.

## 3. Act II stages and final results
Final sweep (`build/sims_final.csv`, all 60 stages, both modes): **120/120 runs pass**. "Auto-commander" must
win; "Idle loss" is the same stage with no deployments, which must lose. Budget = threat-weighted spawns per
minute from tracks (boss stages exclude the boss).

| Stage | Name | Env | Hazard | Budget | Auto-commander | Idle loss | Blueprint(s) | Sparks (cum.) | Challenge |
|---|---|---|---|---|---|---|---|---|---|
| 031 | Blackbough Verge | dead_forest | miasma | 93.5 | WIN 4:22 (stronghold 100%) | LOSS 122s | rune_cartridge_rifleman | 105 (3265) | Never let the stronghold drop below 60% |
| 032 | Rotwood Crossing | dead_forest | — | 103.7 | WIN 4:21 (stronghold 100%) | LOSS 109s | trench_guard | 108 (3373) | Lose at most 30 units |
| 033 | Weeping Fens | plague_marsh | bog | 140.4 | WIN 5:19 (stronghold 100%) | LOSS 170s | repeater_fusilier | 110 (3483) | Win within 10:00 |
| 034 | Sporefall Hollow | plague_marsh | — | 113.4 | WIN 4:52 (stronghold 100%) | LOSS 159s | skyspotter_scout | 112 (3595) | Lose no aircraft |
| 035 | The Gallows Road | ruined_road | — | 103.4 | WIN 5:47 (stronghold 100%) | LOSS 105s | bombardier | 115 (3710) | Win with at most 7 unit types deployed |
| 036 | Carrion Toll | ruined_road | — | 109.8 | WIN 3:56 (stronghold 100%) | LOSS 105s | twin_rotor_interceptor | 118 (3828) | Destroy every undead support structure |
| 037 | Blightvein Adit | corrupted_mine | — | 96.3 | WIN 4:28 (stronghold 100%) | LOSS 144s | armor_piercer | 120 (3948) | Never let the stronghold drop below 70% |
| 038 | Mirewatch | plague_marsh | bog | 128.8 | WIN 12:16 (stronghold 100%) | LOSS 153s | steam_sapper | 122 (4070) | Destroy every undead support structure |
| 039 | Hangman's Thicket | dead_forest | miasma | 105.2 | WIN 3:49 (stronghold 100%) | LOSS 115s | field_barricade_crew | 125 (4195) | Lose at most 28 units |
| 040 | **The Rotting Heart** | dead_forest | — | 24.6 | WIN 6:28 (stronghold 100%) | LOSS 222s | heavy_bombard, mine_layer | 240 (4435) | Slay the boss within 7:00 of its arrival |
| 041 | Ashen Mile | ruined_road | — | 120.4 | WIN 5:25 (stronghold 100%) | LOSS 99s | spotter_balloon_crew | 120 (4555) | Never let the stronghold drop below 65% |
| 042 | Sickbed Abbey | ruined_road | — | 153.9 | WIN 4:52 (stronghold 100%) | LOSS 108s | rocket_battery | 123 (4678) | Win within 10:30 |
| 043 | Fungal Deeps | corrupted_mine | miasma | 98.5 | WIN 4:48 (stronghold 100%) | LOSS 150s | coalwing_strafing_craft | 125 (4803) | Lose at most 26 units |
| 044 | Drowned Wagons | plague_marsh | bog | 144.9 | WIN 4:03 (stronghold 100%) | LOSS 181s | shrapnel_howitzer | 126 (4929) | Lose no aircraft |
| 045 | Thornwall | dead_forest | — | 114.5 | WIN 4:05 (stronghold 100%) | LOSS 93s | ironrunner_light_tank | 128 (5057) | Destroy every undead support structure |
| 046 | Rust Cart Ravine | corrupted_mine | — | 100.9 | WIN 3:56 (stronghold 100%) | LOSS 102s | flamebelcher_medium_tank | 130 (5187) | Never let the stronghold drop below 60% |
| 047 | The Leper Bridge | ruined_road | — | 121.5 | WIN 4:17 (stronghold 100%) | LOSS 103s | boiler_stomper | 132 (5319) | Win with at most 7 unit types deployed |
| 048 | Pestwind Downs | plague_marsh | miasma | 128.2 | WIN 4:23 (stronghold 100%) | LOSS 82s | skyshield_aa_tank | 134 (5453) | Lose no aircraft |
| 049 | Ghoul Warren | corrupted_mine | — | 101.0 | WIN 4:47 (stronghold 100%) | LOSS 90s | steam_loader | 136 (5589) | Never let the stronghold drop below 60% |
| 050 | **Court of Pestilence** | plague_marsh | bog + miasma | 28.7 | WIN 6:53 (stronghold 98%) | LOSS 142s | piston_brawler, copper_sentinel | 270 (5859) | Slay the boss within 8:00 of its arrival |
| 051 | Burnt Orchard | dead_forest | miasma | 156.9 | WIN 7:17 (stronghold 100%) | LOSS 113s | scout_blimp | 130 (5989) | Lose at most 30 units |
| 052 | Toll of Crows | ruined_road | — | 109.2 | WIN 4:28 (stronghold 100%) | LOSS 82s | veteran_rifleman | 132 (6121) | Lose no aircraft |
| 053 | Seeping Gallery | corrupted_mine | miasma | 115.8 | WIN 5:38 (stronghold 100%) | LOSS 176s | mortar_spotter | 134 (6255) | Never let the stronghold drop below 65% |
| 054 | Blight Lantern Road | ruined_road | — | 116.4 | WIN 11:10 (stronghold 100%) | LOSS 99s | heavy_hammerer | 136 (6391) | Destroy every undead support structure |
| 055 | Stitchyard | dead_forest | — | 127.5 | WIN 5:27 (stronghold 100%) | LOSS 101s | multi_barrel_flak | 138 (6529) | Lose at most 30 units |
| 056 | The Sunken Chapel | plague_marsh | bog | 187.0 | WIN 10:10 (stronghold 100%) | LOSS 146s | skyguard_marksman | 140 (6669) | Win within 11:00 |
| 057 | Wyrmroost Fringe | dead_forest | — | 117.8 | WIN 4:16 (stronghold 100%) | LOSS 71s | bombard_gyro | 142 (6811) | Lose no aircraft |
| 058 | Cankerworks | corrupted_mine | miasma | 105.8 | WIN 5:35 (stronghold 100%) | LOSS 101s | thunderback_heavy_tank | 144 (6955) | Never let the stronghold drop below 60% |
| 059 | Last Ford | plague_marsh | bog | 130.0 | WIN 12:32 (stronghold 100%) | LOSS 98s | siege_howitzer | 150 (7105) | Lose at most 34 units |
| 060 | **Nest of the Matriarch** | dead_forest | — | 70.5 | WIN 7:01 (stronghold 98%) | LOSS 96s | heavy_gyro_bomber, ironwing_gunship | 290 (7395) | Lose no aircraft |

| | Act I (001–030) | Act II (031–060) |
|---|---|---|
| Auto-commander win time | 3:07 – 14:37, mean 6:21 | 3:49 – 12:32, mean 5:53 |
| Wins under 4:00 / 4:00–5:00 / over 12:00 | 4 / 6 / 2 | 3 / 13 / 2 |
| Idle loss time | 71 – 259 s | 71 – 222 s |

**Boss stages, scripted "intended counters" playthroughs** (`--suite=boss_counters`; a human-style player cycling
the counters the drawer recommends, no auto-commander heuristics):

| Stage | Army | Result |
|---|---|---|
| 040 Behemoth | Flame troopers, shields, Trench Guard, Steam Mortars, field cannon, Ironclad, repair wagon, interceptors, flak | Win 4:31, Behemoth slain at 3:04, 50 % phase seen, 3 stars |
| 050 Regent | Trench Guard, Ironclad, Heavy Bombard, Steam Mortar, Rocket Battery, Bombard Gyros, flak | Win 4:37, Regent slain at 2:54, phase seen, 3 stars |
| 060 Matriarch | Twin flak, Skyshield AA tank, multi-barrel flak, Flak Crew, Thunderback, Siege Howitzer, interceptors | Win 4:15, Matriarch slain at 2:49, perch seen, 2 stars (lost an aircraft) |

---

## 4. Tests (all run in this environment, final code)

| Suite | Result |
|---|---|
| Project import + parse | no errors |
| `registry` (expectation updated: 60 implemented stages) | **2/2** |
| `combat` A–J · `boss` (Mine Maw) | **8/8 · 1/1** |
| `ui` · `ui --quality=low` | **8/8 · 8/8** |
| `mecha` · `mecha_scenarios` · `mecha_audio` · `mecha_save` | **41/41 · 6/6 · 2/2 · 1/1** |
| `giants` · `giants_scenarios` | **18/18 · 4/4** |
| `roster --from=0 --to=135` · `--from=135 --to=270` | **pass · pass** |
| `bosses_all` | **15/15** |
| `save_write` → `save_verify` (fresh process) | **1/1 · 1/1** |
| `stages --from=1 --to=60` (via `batch_sim.py`) | **120/120** |
| **New** `hazards`: miasma hits organic ground units on both sides, spares machines (copperback, ironclad walker, risen copperback) and flyers, skeletons exactly half; clouds drift, expire and stay capped; bog slows both sides only inside the mire, aircraft untouched; s050 loads bog + miasma; Act II uses 8 miasma and 6 bog hazards | **5/5** |
| **New** `boss_phases`: Behemoth roots erupt under the artillery line and damage it; Behemoth weak to fire; Regent summons 2 heralds and thickens the miasma; Matriarch perches, is targeted by a ground cannon, wakes flyers, takes off | **4/4** |
| **New** `boss_counters` (scripted intended-counter wins for 040, 050, 060) | **3/3** |
| **New** `stars`: all 7 challenge kinds (14 true/false cases), star evaluation, first-time bonus (+10 %/star, no repeat, max +30 %) saved and reloaded, every stage 001–060 has a challenge | **4/4** |
| **New** `m005_save`: an M004-format save loads, keeps clears/Sparks/tiers/loadout, gains stars, hints, tutorial (off for an old save, on for a new one) and act reveals, opens Act II, survives a re-save | **1/1** |
| **New** `ui_m005`: tutorial plate pauses and one tap resumes; a hazard hint shows without pausing and is stored; the boss arrival pans to the boss while paused and resumes; the Act II map and drawer show stars, challenge and hazard lines | **4/4** |
| Stage validator (`python3 tools/stage_kit.py`) | 60 stages OK (Act I `until` warnings, see §7) |
| `SCRIPT ERROR` lines in all logs | **0** |

---

## 5. Performance (Performance preset, software OpenGL under a virtual display; not a phone)
**Same crowded bench as M002b–M004** (`tests/bench.tscn --quality=low --frames=150 --warm=200`, ~101 units),
both builds measured back to back on the same idle machine:

| | M004 | **M005** |
|---|---|---|
| Full frame | 57.4 / 57.2 ms | **60.0 / 58.1 ms** (+1.5 to +4.5 %) |
| Game logic per step | 7.0 / 7.1 ms | **7.2 / 7.2 ms** (+2.5 %) |
| Unit drawing | 2.1 ms | 2.2–2.3 ms |
| GPU draw calls | 637 / 630 | **393 / 402** |

(Absolute times are higher than in the M004 report because this machine is slower; only the side-by-side
comparison is meaningful. The lower M005 draw-call count on this bench was measured twice; I have not isolated
why it dropped.)

**Real stages at their peak** (new `bench.tscn --stage=N --ff=200`: plays the stage with the auto-commander,
puts the camera on the densest stretch of the front, measures 120 frames):

| Stage | Units on screen / alive | Frame | Logic | Draw calls avg (max) |
|---|---|---|---|---|
| 029 (Act I) — M004 build | 49 / 72 | 37.9 ms | 3.6 ms | 370 (1,578) |
| 029 (Act I) — M005 build | 49 / 72 | 37.9 ms | 3.9 ms | 367 (1,672) |
| 038 Mirewatch (bog) | 53 / 52 | 45.4 ms | 3.6 ms | **468** (942) |
| 053 Seeping Gallery (miasma, mine) | 56 / 66 | 39.2 ms | 3.2 ms | **329** (724) |
| 055 Stitchyard (forest) | 63 / 73 | 48.3 ms | 4.1 ms | **510** (1,090) |
| 056 The Sunken Chapel (busiest, bog) | 65 / 79 | 46.3 ms | 5.5 ms | **434** (1,162) |

The first measurement put 038 at 605 and 056 at 573: the new backgrounds drew every reed, branch, drip and
fungus glow as its own call. They now go into a few multiline batches and textured dots, which cut ~140 calls.
The single-frame maxima are frames where the pose cache bakes new poses; they existed before (M004: 1,578 on 029).

**Screens:** campaign map 518 draw calls (M004: 515); main menu 211 (201); Great Forge hub 510 (510). The first
M005 measurement of the campaign map was 692: in this renderer label text costs about a call per character, so
the drawer now draws its three stars in one control, merges the hazard and counter lines into single labels, keeps
the star legend in a tooltip, and the header shows "cleared · stars" in one pill.

**Synthetic worst case** (Act II crowd of ~90 units of mostly distinct arts on one screen, giants included, marsh
background, bog + 3 miasma clouds): 858–1,325 draw calls. This is far denser than any Act II stage reaches (see the
stage table above), so it is reported as a stress figure, not against the 600 budget.

No new unit art was added, so the pose-cache bounds did not need re-measuring.

---

## 6. Tuning changes to existing content (before → after)
| Item | Change |
|---|---|
| Blightroot Behemoth | HP 14,000 × stage multiplier (≈22,190) → 7,500 fixed; ARM 0.30 → 0.15; roots ×0.5; thorn storm ×0.4; fire ×1.3 vulnerability; phase: 3 eruptions of 90 every 20 s |
| Plague Regent | HP 13,000 × multiplier (≈22,555) → 5,800 fixed; ARM 0.30 → 0.15; speed 16 → 10; scepter ×0.55; volley ×0.5; Plague Court cooldown 18 → 26 s, mods fire 1.4/speed 1.3/DR 0.85 → 1.25/1.15/0.9; Pestilence 110 → 70, pool 40 → 22 dps; support every 18 s (2 maulers + 3 soldiers, cap 12) → every 32 s (1 + 2, cap 6) |
| Gravewing Matriarch | HP 9,000 × multiplier (≈16,965) → 9,000 fixed |
| Stage 010 (Act I) | added a light carrion-bat track (both fronts rule) |
| Auto-commander | role-based fallbacks for Act II+ (Act I sims unchanged) |

## 7. Conflicts between the master prompt and the code (code wins on facts, prompt on intent)
1. **Boss HP.** The prompt lists the Behemoth at 14,000 HP, the Regent at 13,000 and the Matriarch at 9,000.
   With the existing per-stage enemy HP multiplier (×1.59 at 040, ×1.74 at 050, ×1.89 at 060) they would have
   had 22,000–22,600 HP, and even at their listed HP neither the auto-commander nor the scripted intended-counter
   army could beat the Behemoth or the Regent. Act II bosses now ignore the per-stage multiplier (`fixed_hp`)
   and were tuned down: Behemoth 7,500 HP (ARM 30 → 15 %, roots ×0.5, thorn storm ×0.4), Regent 5,800 HP
   (ARM 15 %, speed 16 → 10, scepter ×0.55, volley ×0.5, Plague Court every 26 s instead of 18 s with weaker
   mods, Pestilence 110 → 70 with a weaker pool, support waves every 32 s, cap 6), Matriarch 9,000 HP as listed.
   Their sandbox kits are otherwise unchanged and `bosses_all` still passes.
2. **Blueprint lists** hold 8 units for 9 regular stages in two blocks; Boiler Stomper (047) and Bombard Gyro
   (057) fill the gaps (§1.8).
3. **`until` on every ranged/artillery track** is enforced for Act II onward. Act I (shipped in M001/M003) has
   tracks without it (bone archers, necromancers, corpse priests, spirit binders, crypt hexers); the validator
   reports those as warnings instead of retuning stages that already pass.
4. **Two fronts, always.** The validator found that stage 010 (Mine Maw, M001) had no undead flyers at all. A light
   carrion-bat track (2 every 34 s from 0:45) was added; stage 010 still passes both sims.
5. **"Boss stages have `boss_spawn`"**: the data field is `boss_spawn` on generated stages and `boss` in the act
   modules; the validator checks the generated field.
6. **Star 3** reads "win while also meeting the challenge"; stars are recorded independently (victory · stronghold
   held · challenge), so a player can earn the challenge star without the stronghold star. This keeps each star
   a clear, separate goal.
7. **The prompt's tutorial says hints "pause the game only for the first three"**: implemented as the first three
   tutorial plates of a run; first-encounter hints never pause.
8. The prompt calls `tools/act1b_data.py` the pattern for new acts; Act II follows it (`tools/act2_data.py`) but
   composes stages from `stage_kit` templates instead of raw tracks.

---

## 8. Honest limits
- **Not device-tested.** Nothing in M005 ran on a phone, Infinix Hot 30i or otherwise. The timings are from
  software OpenGL on a server CPU. The APK has the same caveat as before: the export validator ran against stub
  `adb`/`apksigner`, and the APK was zipaligned and debug-signed with uber-apk-signer afterwards (v1/v2/v3
  verified). It has not been installed.
- **Balance is a floor, not proof.** The auto-commander wins every Act II stage, but it plays without abilities and
  kept its stronghold at 98–100 % everywhere. Three Act II stages (036, 039, 046) still fall to it in under four
  minutes (3:49–3:56), 13 more in 4–5 minutes, and two take just over 12 (038, 059). Act I has the same spread.
  Human playtesting is needed; a person who doesn't spam counters will find these stages harder.
- **Act II bosses were cut substantially** from the prompt's numbers (§6). They are beatable by the intended
  counters and by the commander, but may now feel light to a strong player.
- **The commander needed real changes** to play Act II at all; its Act I behaviour is kept as shipped so Act I
  results stay comparable. Its Act II rules are heuristics and will need revisiting as later acts add units.
- **Boss phases are behavioural**, not new art: the Matriarch's "perch" is her flying art landed at the nest
  position; there is no separate nest prop in the battle scene. The Behemoth's roots reuse the strike telegraph
  and flame particles.
- **Hints and the tutorial** are text plates; there is no voice-over or animated hand. Hint text appears in
  English only.
- **First launch after updating** re-synthesizes the sound cache once (cache version bump).
- Draw-call spikes of ~1,000–1,700 on single frames come from pose baking and pre-date M005.
- Godot still prints benign "ObjectDB instances leaked at exit" warnings when headless test processes quit.

## 9. Deliverables
- `build/android/DwarvesVsZombies-M005.apk` (0.5.0-M005, version code 6, arm64-v8a + armeabi-v7a, debug-signed,
  v1/v2/v3 verified).
- `build/linux/DwarvesVsZombies.x86_64`, smoke-tested for 300 frames under a virtual display: exit 0, 0 script errors
  (only "no ALSA audio device" from the container).
- Project ZIP (excluding `.godot/`, `build/`, `*.import`).
- Screenshots `docs/screenshots/m005_*.png`: the four environments, miasma, bog, the Behemoth arrival pan, the
  Regent's arena, the Matriarch perched, the tutorial plate, the Act II Realm Map (cartouche, Behemoth tree, carrion
  nest) and the stage drawer.

How to run: `godot --headless --path . res://tests/test_runner.tscn -- --suite=<name>`; new suites `hazards`,
`boss_phases`, `boss_counters [--stage=N]`, `stars`, `m005_save`, `ui_m005`; sims
`python3 tools/batch_sim.py --from 31 --to 60 --out build/sims.csv`, advice `python3 tools/auto_tune.py build/sims.csv`;
stage bench `godot --path . res://tests/bench.tscn -- --quality=low --stage=56 --ff=200`.
