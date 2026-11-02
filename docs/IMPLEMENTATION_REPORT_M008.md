# M008 — The Black Rift: Act V, the ending, Last Stand, the full-campaign balance pass, and the "Titanforge" war-frame overhaul

Engine: Godot 4.3-stable (GL Compatibility). Date: 2026-11-02. Version 0.8.0-M008 (Android version code 11).
Everything marked **tested** ran in this build environment: headless, or on a virtual X display with software
OpenGL for screenshots and the benchmark. **The build has not been run on an Android phone.** No on-device frame
rate is claimed. The M001–M007 reports are kept unchanged next to this one.

Built from `MASTER_PROMPT_M008.md`, plus one request made in the session: "another visual overhaul for the
mechas … especially the wide T5 mechas, they look so bad" (§8). After this milestone the game is content-complete:
all 160 units, 110 enemies, 15 bosses and **150 stages** are playable.

---

## 1. What was built

### 1.1 Campaign: Act V, stages 121–150
30 authored stages (`tools/act5_data.py`, composed with `tools/stage_kit.py` like Acts II–IV, wired into
`tools/gen_data.py`) replace the planned placeholders, in four new environments. The act opens on riftbound
legionaries (121), then introduces rift tears (122), ossuary champions behind callers (123), the eclipse (124),
necrotic sky serpents among floating shards (125), the obelisk ward (126), a siege of tiered walls (127) and the soul
storm (128), and walks the Throne Road to the Hollow King (130). The second third brings Riftfall (131, a relief stage
of fast tears), the first plague colossus (132), a shard bridge under a heavy sky (133), a legionary phalanx behind
obelisks (134), the rift maw (135), the Sovereign's heralds (136), an eclipse siege (137), an obelisk belt (138) and
the holding battle "Last Light of Stonehelm" (139: big waves, 900 starting Gold, +6 Gold/s). The last third opens
with a relief stage (141: soul storm + tears, light waves), then every elite (142), a barge fleet (143), the ossuary of
kings (144), a fortified obelisk bastion (145), the heavy soul storm (146), two colossi together (147), the
combined-arms threshold (148), the Final Muster (149) and the Rift Lich (150).

New toolkit templates: `obelisk_belt(xs, beacons)` and `honour_guard(elites)`. The validator knows the three new
hazards and the `no_spills` challenge. Every Act V stage has a challenge objective and a generated Heroic block.

### 1.2 Hazards (`scripts/battle/rift.gd`, drawn by `HazardLayer.RiftPaint` and `_draw_rift_over`)
| Hazard | Behaviour | Visual / audio |
|---|---|---|
| `rift_tears` | Every `interval` s a tear opens at an x drawn from the battle's own **seeded** `rift_rng` (same stage → same places). It cracks for `warn` (2 s, 1.5 s on Riftfall), then becomes a portal **unit with HP** (`hp`, not scaled by the stage multiplier) that stays open `open` s and **spills** `spill` undead from the stage's `pool` when it closes — unless the dwarves destroy it first. Tears are aux entries flagged `transient`: they are targetable, give a small bounty, but never count as support structures, as kills toward challenges, or as encountered enemies. | A jagged violet crack flickering faster as it splits; a tall violet lens with motes swirling in and a pink spill-progress ring; a crack zap, an opening choir-boom, a soft close, a spill roar |
| `eclipse` | Every `interval` s the dead sun goes out for `duration`. **Ranged** weapons on **both sides** lose 25 % range (`range_mult`), except units that are **lit**: units with a spotter range or a light (scouts, spotter balloons, rune-sight scouts, the mortar spotter, surveyors), undead with a reveal aura (night seers), and anything standing inside such a unit's light radius on its own side (re-evaluated every 0.25 s). Melee and strongholds are unaffected. | The battlefield sinks into violet-black (1.2 s fade); warm light pools rise from the ground under every light source (green for the undead), with a faint cone under flying scouts and an arc marking the light radius, so range readability stays clear; a low choir at dusk, a shimmer at dawn |
| `soul_storm` | Every `interval` s `wisps` soul wisps drift in from the rift side at low altitude (mid band, so rifles cannot hit them but flak, AA and aircraft can). Each heals undead it passes (`heal`/s; never bosses or structures) and burns dwarves under it (`damage`/s). Wisps have `hp` and are aux `transient` units like the tears. | A pale green-white flame with a hollow face (unit art), a trailing glow and its reach faintly on the ground |
| Obelisk ward | Rift obelisks power the line: undead (ground) within 200 px of a live obelisk take **15 % less damage** (`Unit.aura_dr`). Breaking the obelisk ends it. | Faint violet threads from each obelisk to the units it shields |

Each hazard has a drawer pill and description, a first-encounter hint, sounds, and a dedicated test (§4).

### 1.3 Bosses
| Boss | Kit (existing) | M008 phase (tested) | Intended counters |
|---|---|---|---|
| **The Hollow King** (130) | Royal Summons, Hollow Crown, King's Doom | At 50 % he **crowns an elite** of his court (the healthiest champion, knight, executioner or legionary near him; he summons a champion if none is near). The crowned one gets +50 % HP; while it lives the King takes **half damage** and the undead within 200 px of the crowned one are warded (−25 %). Kill it to break the ward; he crowns another after 20 s. A gold crown floats over the crowned elite with a thread to the King. | Focused fire on elites (anti-armour, artillery on the court), heavy armour at the front |
| **Gravewing Sovereign** (140) | Sovereign's Brood, Wing Storm | At 50 % the **storm eye closes**: every 13 s gales sweep the sky for 4.5 s, pushing dwarven aircraft back (95 px/s) and buffeting them. At 25 % she **drags dwarven aircraft toward her** every 11 s (3 s, 85 px/s, crushing damage). Wind streaks and a contracting vortex show both. | Flak arrays, superiority craft, airships; ground AA under the eye |
| **The Rift Lich** (150) | Rift Legion, Rift Storm, Annihilate, Lich Ward | **Two-front finale.** Phase 1 on the ground with its legion. At 66 % it **rises into the rift** (shielded for 2.4 s, then airborne in the high band: only flak, AA artillery, interceptors and airships reach it) while its legion storms the stronghold through a rift opened 360 px ahead of the dwarven front every 18 s. At 33 % it **returns to the ground with the rift's full storm**: soul wisps pour out (×1.8), and its casts come 40 % faster. The player has to win both fronts. | Everything: colossal machines, flying fortresses, flak, artillery |

Fixed HP: Hollow King 12,000, Gravewing Sovereign 26,000, Rift Lich 16,000 (not the prompt's 28,000 / 30,000 / 34,000;
see §7.1). All three get the M005 arrival pan and boss sting; the Rift Lich has **its own music** (`music_lich`) and a 2.6× longer
arrival hold with a caption.

### 1.4 Battle environments (`BattleBackground`)
| Env | What is in it |
|---|---|
| `necro_waste` | Ash-grey sky with an eclipsed dead sun; long pale bone dunes with ash streaks; three ribcage arches of something enormous; skull mounds and leaning grave markers behind the lane; ash ground with half-buried skulls in front; pale ash storms on the parallax cloud layer |
| `rift_sky` | A violet sky cracked by glowing rifts; streaks of the rift's pull; floating shards with violet underglow and violet light spilling off their edges; a broken shard causeway over nothing with rift light pouring up from below and loose shards drifting under it; violet rift-cloud drifting |
| `ruined_citadel` | Bruised dusk; three tiers of black citadel wall climbing toward the right (far tiers hazy, near tiers black) with buttresses, pointed arches, corpse-light windows and spires rim-lit by the dusk; broken courtyard walls; toppled statues of crowned undead kings behind the lane; cracked flagstones in front |
| `realm_gate` | **The Rift** itself: a vast vertical tear with a violet halo over the battlefield; far ranges in silhouette; the gate of bone and black iron (bone pillars with skulls, a rib arch, a half-raised portcullis); sigil stones; ritual circles glowing on the ground in front |

Stage-select thumbnails got a signature mark per Act V land (ribs, rift cracks, battlements, the tear).

### 1.5 Realm Map (Act V)
- **Landmarks:** a bone-dune ribcage with a dwarven watch-fire once cleared (waste); a broken obelisk on a floating
  shard, placed **aloft** like M006's airborne stages (rift sky); a tiered black keep (citadel); sigil stones round a
  ritual ring (gate).
- **Boss set pieces:** 130 the Hollow King's vaulted throne hall with an empty crown on the throne; 140 a storm eye
  with a colossal wing silhouette; 150 the gate under the rift (banners of the dwarven army on it once cleared).
- **The Black Rift** is painted into the far layer as a huge vertical tear at the right end of the map, with land
  shards being pulled into it.
- **Light pushing into the dark:** cleared Act V ground gets a forge-glow band and a halo per cleared landmark (live
  layer, cheap circles); the rift pulses violet beyond the front.
- **Rift sealed:** once stage 150 is cleared the Act V map switches to a "sealed" palette (a cold, clean dawn) and the
  tear becomes a healed scar.

### 1.6 Ending, epilogue, credits and post-game (`scenes/ending.tscn`, `scripts/ui/ending.gd`)
- **Ending (≈80 s, skippable at any point with a tap, a key or the Skip button):**
  1. *The rift collapses* (14 s): the gate of the undead realm under the tear; the tear narrows to a scar while land
     shards are sucked into it; a white flash as it seals; the sky turns from void to dawn.
  2. *The banners* (10 s): two banners rise on the gate pillars over a line of the army (real unit art).
  3. *The march home* (5 × 9 s): the actual baked Realm Map of each act, panned from Act V back to Act I, now
     clean, with a column of dwarves marching home along the road.
  4. *The coda* (11 s): at Stonehelm (the painted Act I backdrop), a line of riflemen fires a celebration volley;
     the third rifleman's hat flies off, spins across the sky and lands on a rescued dwarf, who looks up — "?", then "!".
- **Epilogue card:** one line per act. **Credits:** scrolling forged-brass plates over the Great Forge hub, with the
  ending theme (`music_ending`, a triumphant dwarven march over industrial percussion). The credits are honest about
  how the game was made (§9).
- **Post-game:** the campaign title bar shows **Rift Sealed**; every stage stays replayable on Normal and Heroic; Last
  Stand is open; a **completion page** (`scenes/completion.tscn`) shows stars, Heroic clears, units fielded (new
  `profile.units_used`), per-act records, Last Stand bests and cosmetics, with a "Replay Ending" button. Settings has
  **Replay ending** too.

### 1.7 Last Stand (`scripts/battle/last_stand.gd`, `scenes/last_stand.tscn`)
- **Unlock:** after stage 060 (or once the Rift is sealed). A new hub station ("The Last Stand") and a button on the
  War Table. Four arenas, one per environment family: Stonehelm Gate (Act I), The Blighted Verge (II), Cloudbreak
  Plains (III) — open at 060 — and Cinder Canal (IV), open at 090.
- **Waves:** `LastStand` extends `WaveDirector`. The citadel is sealed for good; only the stronghold can fall. Each wave
  is composed (deterministically per arena and wave) from the stage toolkit's shapes over the arena's act roster: a melee
  screen, a ranged line, a sky raid on most waves, a monster breakthrough every third wave (more often later), siege
  pieces from wave 5, with a threat budget of `26 + 13n + 0.35n²`. A wave spawns over 34 s; the next starts 14 s after
  it is cleared (or after 70 s). **Every 10th wave a boss the player has already defeated returns** (campaign order,
  60 % of its tuned HP + 12 % per appearance). Enemy HP grows 5 % per wave and Gold income 0.55/s per wave.
- **Score:** 100 per wave held + 1 per undead destroyed; the best wave, score and kills are kept per arena (local only).
- **Rewards:** cosmetic only — banners at waves 10/20/30, titles at 40/50. **No Sparks** (no farming).
- **Performance:** the campaign's `max_alive` and flyer caps apply. A 30-minute soak ran headless (§4.3).

### 1.8 Full-campaign balance pass (§2–3)
- Research prices reworked so Sparks buy every tier but not the whole roster by 150.
- The difficulty curve smoothed: no regular stage more than ~30 % above its neighbours' budget.
- All 150 stages swept on Normal and Heroic; one CSV (`build/campaign_balance.csv`) and a chart
  (`docs/screenshots/m008_balance.png`).
- A 160-unit coverage sweep: every dwarven unit put into a realistic army on a stage where a player owns it.

### 1.9 UI and audio
- UI: Act V uses the existing act title cartouche; the Last Stand screen, completion page, ending and credits, Settings
  → Replay ending, a "Rift Sealed" pill; the HUD shows the wave, score and best during Last Stand; a "THE LINE BREAKS"
  result plate.
- Audio (synthesized like the rest; the cache version is now `m008-1`, so the first launch re-synthesizes once): four
  ambiences — ash wind over bone (waste), the rift's beating hum (rift sky), distant choirs in ruined halls (citadel),
  a slow two-note chant under the rift hum (gate); the Rift Lich theme; the ending march; cues for tears (crack, open,
  close, spill), the eclipse (dusk, dawn), the crown (placed, broken), gales and the Last Stand wave horn.

### 1.10 Progression and rewards
Blueprints follow §9 in order: 121–129 one T5 machine each (Titan Maintenance Crew, Worldhammer, Royal Skyguard, Iron
Bastion Prime, Deepforge Titan, Stormforge Bomber, Skyhammer Assault Craft, Brass Leviathan, Mountain Colossus); 130
Skyforge Dreadnought + King's Anvil; 131–139 the last nine (Arcwing, Dreadnought Landship, Colossal Skybreaker,
Hammerfall Goliath, Mountain Ark, Embercore Titan, Skyhammer Battleship, Rune Citadel Airship, Grand Forge Carrier).
None had been awarded before. 140 and 150 pay Sparks plus a cosmetic banner (`storm_breaker`, `rift_sealer`); 141–149
pay Sparks only (every unit is reachable by then). Sparks: `240 + 2.85·(n−121)` per regular stage (240 → 320), 480 /
540 / 600 for the bosses. Act V pays 9,177 Sparks: 29,228 cumulative by 150 before star bonuses.

### 1.11 Save compatibility
New fields, all filled by `SaveManager.migrate()`: `last_stand` (arena → best wave/score/kills/runs; malformed entries
repaired), `cosmetics` (banners, titles, selected), `units_used`, `ending_seen`, `last_stand_day`, and stats
`tears_closed`, `wisps_shot`, `last_stand_runs`. Tested: an M007 save loads with all progress, opens Act V at 121, and
clearing 150 seals the Rift and grants its banner (§4).

---

## 2. Balance: how it was tuned
### 2.1 Army assumptions (Act V)
`_act5_loadout(i)` in `tests/test_runner.gd` builds the army a player owns on reaching stage *i*: the T0 starters,
every blueprint rewarded before *i*, the common Act I–IV unlocks and a handful of researched staples (steamgunner,
copperback, steam mortar, twin flak, bombard gyro, boiler stomper, ironclad walker, salvage crew; the rune-sight
scout from 124, when the eclipse arrives). From that it fills seven ground roles (line holder, heavy tank, flame,
armour-piercer, artillery, anti-air, repair), four air slots (a scout on eclipse stages) and one war frame. It never
uses a unit the player cannot own yet. Acts I–IV use their M005–M007 assumptions unchanged. Heroic Acts IV sims still
use no T5 units (M007 rule); Heroic Act V uses the full Act V army.

### 2.2 The commander
- Acts I–III: the generic M006 commander; Act IV: the M007 "saver"; Act V: the saver **plus `rotate`** (new, §7.9).
- The saver no longer counts the Titan Maintenance Crew (a 580 Gold repair unit) as a "heavy" to save for. In round
  1 it saved for the crew instead of fighting and lost every Act V stage.

### 2.3 Act V tuning rounds
| Round | Failures (of 60 runs) | What changed after it |
|---|---|---|
| r1 | 30 (every commander run lost, 116–294 s) | Saver fix (above); a cheap AA flyer (`flak_chaser`) in the Act V air list: the army's only AA flyer was the 950 Gold celestial array, so early sky raids went unanswered |
| r2 | 12 | Riftbound legionary openers replaced by black-rot infantry openers (legionaries arrive as the second track); air-raid `k` ×0.8 across the act; 125 sky host lighter |
| r3 | 8 | `rotate` added to the commander (it never fielded a colossus); 126 bell keepers 50 s apart and gone by 360 s; 129 honour guard lighter |
| r4 | 4 | 130 court lighter (`k` .85, bell keepers 120/70 s until 330 s); 142 elites rebalanced; 148 finale `k` .5 |
| r5 | 2 | 149 finale `k` .5 and three set pieces instead of four; Hollow King's Royal Summons capped at 4, one per cast every 20 s |
| r6 | **0** | — |

After the full-campaign sweep (§3) one more change: in 149 the casters stop at 300 s, and necromancers everywhere stop
raising while 64 units of their side are alive (`Battle.RAISE_CAP`, §2.5). The 10 stages that ever reached 62+ alive
undead were re-simulated on Normal and Heroic afterwards.

### 2.4 Heroic
Every Act V stage gets a generated Heroic block (intervals ×0.85, enemy HP ×1.12, abilities 45 % sooner, a set piece,
a heroic structure). Seven stages failed the first Heroic sweep:
- 050: failed in M007 too. Not changed (see §3).
- 051: timed out after the curve pass eased its normal waves; gentle block (intervals ×0.92, HP ×1.05).
- 130, 149: gentle block.
- 146, 148: gentle block failed too, so they get the minimal block (intervals ×0.95, HP ×1.03).
- 126: lost even with the minimal block (black-rot masses under the obelisk wards). It is now Heroic mostly **by
  design**: intervals only ×0.95 and HP ×1.03, but a third rift obelisk planted in front of the other two (at x 1640,
  so the ward covers more of the line) and two grave knights at 300 s. The commander wins it in 9:55, against 8:46 on
  Normal.

### 2.5 Global changes (before → after)
| Change | Before (M007) | After (M008) | Why |
|---|---|---|---|
| Research price per tier T0–T5 (units that a stage hands out as a blueprint) | 0 / 40 / 70 / 110 / 160 / 230 | **0 / 60 / 110 / 190 / 300 / 500** | Blueprints hand out 144 of the 160 units. At the old prices a player could research everything by about stage 125, and Sparks stopped mattering |
| Research price, research-only units (10 units no stage hands out) | 0 / 40 / 70 / 110 / 160 / 230 | unchanged | §9: keep them cheap. They cost 540 Sparks in total |
| Curve smoothing: track intervals stretched on 12 stages so none sits more than 30 % above its neighbours' mean budget | — | 008 ×1.033 (budget 107.0 → 103.5), 013 ×1.013 (149.3 → 147.3), 026 ×1.042 (148.8 → 142.8), 042 ×1.082 (153.9 → 142.3), 044 ×1.047 (144.9 → 138.4), 051 ×1.105 (156.9 → 141.9), 056 ×1.173 (187.0 → 159.4), 064 ×1.081 (188.8 → 174.6), 093 ×1.064 (191.9 → 180.4), 103 ×1.036 (155.9 → 150.4), 118 ×1.171 (205.2 → 175.3), 123 ×1.014 (179.3 → 176.9) | §9 difficulty curve. Boss stages and finales/exams are exempt: 015 (Act I finale, 1.59×) and 087 (the combined-assault exam, 1.34×) stay above the line on purpose |
| Relief after every boss: the stage after a boss at ≤ 90 % of the budget of the stage before it (act band floor kept) | — | 011 ×1.403 (108.2 → 77.1), 021 ×1.032 (114.1 → 110.6), 041 ×1.272 (120.4 → 94.6), 051 ×1.546 more (141.9 → 91.8), 061 ×1.084 (126.8 → 117.0), 081 ×1.474 (150.3 → 102.0), 091 ×1.361 (152.7 → 112.2), 101 ×1.314 (147.4 → 112.2), 121 ×1.128 (138.2 → 122.5); then 042 ×1.134 more (142.3 → 125.5), which the relief at 041 had left 47 % above its neighbours | §9 "relief stages after each boss". 031, 071, 111, 131 and 141 were already below the line |
| Necromancer raising | unlimited (each necromancer up to its own cap) | stops while 64 units of its side are alive (`Battle.RAISE_CAP`) | Stage 149 peaked at 80 alive undead (seven rift conjurers raising legionaries). Now 66, 6 of them soul wisps |
| Boss ability cooldowns | — | multiplied by a per-boss `cd_mult` (1.0 everywhere except the Rift Lich's final phase, 0.6) | The Lich's last phase |
| Act V budget band (stage validator) | — | 100–440 | Relief stages after the bosses sit below Act IV's floor (§7.7) |
| Tear spills in `budget()` | — | each spill counted at the pool's threat | A tear left alone adds its spill |
| Heroic blocks | 11 gentle / 4 minimal overrides (M007) | + 051, 130, 149 gentle; 146, 148 minimal; 126 mostly by design | §2.4 |

No enemy HP multiplier, unit cost, cooldown or Gold rate outside Act V was changed. The per-stage enemy HP multiplier
keeps its +1.5 %/stage line (×2.80 at 121 → ×3.235 at 150), and Act V bosses ignore it (fixed HP).


## 3. Results
### 3.1 Sweep summary (stages 1–150, Normal and Heroic; 600 runs)
`build/sims_all.csv` and `build/sims_all_heroic.csv` (merged into `build/campaign_balance.csv`, chart in
`docs/screenshots/m008_balance.png`).

| Act | Normal: commander | Normal: idle | Heroic: commander | Heroic: idle |
|---|---|---|---|---|
| I (1–30) | 30/30 WIN · 3:07–14:37 · mean 6:16 (lowest stronghold 85 %) | 30/30 LOSS · 71–259 s | 30/30 WIN · 3:09–13:43 · mean 7:08 (lowest stronghold 55 %) | 30/30 LOSS · 68–224 s |
| II (31–60) | 30/30 WIN · 3:49–12:32 · mean 5:43 (lowest stronghold 98 %) | 30/30 LOSS · 71–222 s | **29/30** WIN · 4:02–14:35 · mean 10:20 (050 lost) | 30/30 LOSS · 70–210 s |
| III (61–90) | 30/30 WIN · 4:59–13:00 · mean 7:41 (lowest stronghold 94 %) | 30/30 LOSS · 60–161 s | 30/30 WIN · 6:36–13:12 · mean 9:03 (lowest stronghold 92 %) | 30/30 LOSS · 57–150 s |
| IV (91–120) | 30/30 WIN · 4:56–11:34 · mean 8:16 (lowest stronghold 68 %) | 30/30 LOSS · 101–147 s | 30/30 WIN · 6:23–13:54 · mean 10:21 (lowest stronghold 58 %) | 30/30 LOSS · 98–142 s |
| **V (121–150)** | **30/30 WIN · 5:01–10:37 · mean 7:07** (lowest stronghold 100 %) | **30/30 LOSS · 88–130 s** | **30/30 WIN · 6:00–13:08 · mean 8:56** (lowest stronghold 63 %) | 30/30 LOSS · 84–131 s |

Normal: **300/300** as expected. Heroic: **299/300**. The one failure is **Heroic 050**, which the auto-commander
also lost in M007 (the M007 report showed a scripted counter plan winning it); it is reported, not hidden by a
further nerf.

Reading the Act V numbers honestly: on Normal the commander never lost stronghold HP in Act V, while doing nothing
loses in under 2:10. So the act punishes passivity hard, but the commander (now with every T5 machine and the
`rotate` rule) holds the line comfortably. As §12.2 says, these results are a floor, not proof of balance. A human
army without colossi will feel Act V much harder than these numbers suggest; Heroic is where the commander starts
losing stronghold HP (down to 63 %).

### 3.2 Act V stage table
Budget is the stage-kit difficulty budget (boss stages are low because the boss carries the fight). Commander times
are m:ss. Peak = most undead alive at once (soul wisps and tears count).

| # | Stage | Env | Hazard / feature | Budget | Citadel HP | Gold | Sparks | Blueprint(s) | Commander (Normal) | Idle | Heroic (commander / idle) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 121 | The Grey Waste | necro_waste | — | 122 | 8,800 | 500 | 240 | titan_maintenance_crew | WIN 5:41 · base 100 % · peak 44 | LOSS 114 s | WIN 8:50 / LOSS 111 s |
| 122 | Rift Scar | rift_sky | rift_tears | 141 | 8,860 | 504 | 243 | worldhammer_siege_tank | WIN 5:31 · base 100 % · peak 47 | LOSS 94 s | WIN 7:21 / LOSS 91 s |
| 123 | Bonecrown Approach | ruined_citadel | — | 177 | 8,920 | 508 | 246 | royal_skyguard | WIN 7:13 · base 100 % · peak 60 | LOSS 116 s | WIN 8:15 / LOSS 113 s |
| 124 | Ashveil | necro_waste | eclipse | 131 | 8,980 | 512 | 249 | iron_bastion_prime | WIN 5:58 · base 100 % · peak 44 | LOSS 107 s | WIN 7:39 / LOSS 105 s |
| 125 | Sky Fracture | rift_sky | — | 106 | 9,040 | 516 | 251 | deepforge_titan | WIN 7:18 · base 100 % · peak 35 | LOSS 100 s | WIN 8:27 / LOSS 95 s |
| 126 | Gate of Lanterns | realm_gate | obelisks | 128 | 9,100 | 520 | 254 | stormforge_bomber | WIN 8:46 · base 100 % · peak 47 | LOSS 112 s | WIN 9:55 / LOSS 111 s |
| 127 | Citadel Outworks | ruined_citadel | — | 153 | 9,160 | 524 | 257 | skyhammer_assault_craft | WIN 5:55 · base 100 % · peak 45 | LOSS 112 s | WIN 9:59 / LOSS 111 s |
| 128 | Wailing Dunes | necro_waste | soul_storm | 134 | 9,220 | 528 | 260 | brass_leviathan | WIN 5:48 · base 100 % · peak 46 | LOSS 111 s | WIN 8:25 / LOSS 111 s |
| 129 | Throne Road | ruined_citadel | — | 154 | 9,280 | 532 | 263 | mountain_colossus | WIN 9:34 · base 100 % · peak 59 | LOSS 121 s | WIN 13:08 / LOSS 119 s |
| 130 | **Hall of the Hollow Crown** (Hollow King) | ruined_citadel | — | 62 | 10,400 | 720 | 480 | skyforge_dreadnought, kings_anvil | WIN 8:08 · base 100 % · peak 38 | LOSS 130 s | WIN 10:34 / LOSS 131 s |
| 131 | Riftfall | rift_sky | rift_tears | 115 | 9,400 | 540 | 268 | arcwing_superiority_craft | WIN 5:01 · base 100 % · peak 30 | LOSS 94 s | WIN 6:18 / LOSS 91 s |
| 132 | The Walking Plague | necro_waste | — | 127 | 9,460 | 544 | 271 | dreadnought_landship | WIN 7:06 · base 100 % · peak 41 | LOSS 119 s | WIN 9:05 / LOSS 119 s |
| 133 | Shattered Sky Bridge | rift_sky | — | 153 | 9,520 | 548 | 274 | colossal_skybreaker | WIN 6:36 · base 100 % · peak 34 | LOSS 88 s | WIN 7:53 / LOSS 84 s |
| 134 | Gate Wardens | realm_gate | obelisks | 118 | 9,580 | 552 | 277 | hammerfall_goliath | WIN 6:29 · base 100 % · peak 42 | LOSS 107 s | WIN 8:59 / LOSS 106 s |
| 135 | Maw Fields | necro_waste | — | 129 | 9,640 | 556 | 280 | mountain_ark | WIN 6:52 · base 100 % · peak 38 | LOSS 118 s | WIN 8:41 / LOSS 119 s |
| 136 | Sovereign's Shadow | rift_sky | — | 136 | 9,700 | 560 | 283 | embercore_titan | WIN 5:52 · base 100 % · peak 32 | LOSS 104 s | WIN 7:03 / LOSS 102 s |
| 137 | The Drowned Crown | ruined_citadel | eclipse | 166 | 9,760 | 564 | 286 | skyhammer_battleship | WIN 7:36 · base 100 % · peak 60 | LOSS 120 s | WIN 9:20 / LOSS 119 s |
| 138 | Obelisk Line | realm_gate | obelisks | 135 | 9,820 | 568 | 288 | rune_citadel_airship | WIN 8:28 · base 100 % · peak 36 | LOSS 98 s | WIN 10:30 / LOSS 96 s |
| 139 | Last Light of Stonehelm | necro_waste | — | 166 | 9,880 | 900 | 291 | grand_forge_carrier | WIN 8:12 · base 100 % · peak 59 | LOSS 109 s | WIN 9:06 / LOSS 106 s |
| 140 | **Eye of the Storm** (Gravewing Sovereign) | rift_sky | — | 70 | 10,800 | 760 | 540 | — | WIN 6:43 · base 100 % · peak 24 | LOSS 113 s | WIN 6:00 / LOSS 113 s |
| 141 | Edge of the Rift | realm_gate | soul_storm + rift_tears | 123 | 10,000 | 580 | 297 | — | WIN 5:39 · base 100 % · peak 42 | LOSS 105 s | WIN 7:28 / LOSS 103 s |
| 142 | The Unmade Legion | necro_waste | — | 155 | 10,060 | 584 | 300 | — | WIN 6:42 · base 100 % · peak 47 | LOSS 112 s | WIN 10:09 / LOSS 111 s |
| 143 | Skyfortress Breach | rift_sky | — | 116 | 10,120 | 588 | 303 | — | WIN 6:40 · base 100 % · peak 34 | LOSS 101 s | WIN 6:56 / LOSS 96 s |
| 144 | Ossuary of Kings | ruined_citadel | — | 145 | 10,180 | 592 | 306 | — | WIN 7:46 · base 100 % · peak 57 | LOSS 123 s | WIN 9:36 / LOSS 121 s |
| 145 | Rift Bastion | realm_gate | obelisks | 124 | 10,240 | 596 | 308 | — | WIN 7:15 · base 100 % · peak 39 | LOSS 114 s | WIN 9:10 / LOSS 111 s |
| 146 | Storm of Souls | rift_sky | soul_storm | 126 | 10,300 | 600 | 311 | — | WIN 5:59 · base 100 % · peak 42 | LOSS 109 s | WIN 10:06 / LOSS 109 s |
| 147 | The Black Steps | ruined_citadel | — | 132 | 10,360 | 604 | 314 | — | WIN 8:06 · base 100 % · peak 50 | LOSS 121 s | WIN 10:34 / LOSS 118 s |
| 148 | Threshold | realm_gate | rift_tears + obelisks | 122 | 10,420 | 608 | 317 | — | WIN 10:37 · base 100 % · peak 56 | LOSS 112 s | WIN 12:39 / LOSS 111 s |
| 149 | The Final Muster | necro_waste | soul_storm | 101 | 10,480 | 612 | 320 | — | WIN 9:34 · base 100 % · peak 66 | LOSS 115 s | WIN 8:27 / LOSS 114 s |
| 150 | **Into the Black Rift** (Rift Lich) | realm_gate | — | 68 | 11,200 | 800 | 600 | — | WIN 6:39 · base 100 % · peak 40 | LOSS 104 s | WIN 7:50 / LOSS 100 s |

### 3.3 Bosses
Scripted counter plans (`--suite=boss_counters`: a fixed, sensible army deployed in a planned order, with the
commander filling in) play every boss from 040 on; **12/12 win**. Act V:

| Boss | Stage | Counter army (scripted) | Counter result | Boss slain | Commander sweep (Normal / Heroic) |
|---|---|---|---|---|---|
| The Hollow King | 130 | Kingsguard + Iron Bastion Prime in front, Thunderrail destroyers and rune cannons on the court, Stormforge bombers, a Deepforge Titan | WIN 7:19, stronghold 100 % | 4:36 (3:41 after he arrives) | WIN 8:08 / WIN 10:34 |
| Gravewing Sovereign | 140 | Celestial flak arrays, heavy skybreakers and a mobile flak fortress under the eye, Arcwing superiority craft, Royal Skyguard, a Skyforge Dreadnought, a Colossal Skybreaker | WIN 8:50, stronghold 82 % | 2:23 (1:28 after she arrives) | WIN 6:43 / WIN 6:00 |
| The Rift Lich | 150 | Everything: heavy armour, flame, anti-armour, mountain siege cannon, celestial flak, colossi and a flying fortress | WIN 8:27, stronghold 100 % | 6:46 (5:46 after it arrives) | WIN 6:39 / WIN 7:50 |

Phase tests (`boss_phases_m008`, 3/3): the King crowns an elite at 50 % and takes half damage until it dies, then
re-crowns; the Sovereign's gales push dwarven aircraft back from 50 % and the pull drags them in from 25 %; the Lich
rises at 66 % (shielded while rising, then only high-band weapons reach it) while its legion keeps coming through a
rift near the dwarven front, and returns at 33 % with the soul storm and faster casts. The clips in `docs/clips/` show
each phase (§9).

"Boss slain" is battle time; the bosses arrive at 0:55 (King, Sovereign) and 1:00 (Lich).

The Sovereign falls fast to a dedicated anti-air army. At 17,000 HP (the first tuning) the counter army killed her
75 s after she arrived, so she was raised to **26,000 HP**: now 88 s. At the prompt's 30,000 the counter run was lost
on the ground after she died (an all-AA army has little to hold the line with), so 26,000 stays. She is the "bring the
right counter" boss; armies without a full AA set fight her much longer (the commander sweep wins the stage in 6:43).

### 3.4 Unit coverage (all 160 dwarven units)
`--suite=coverage` puts every one of the 160 dwarven units into the realistic army of the stage after its blueprint
(research-only units: the first stage after their tier opens), replacing the slot of the same domain, and plays the
stage for 8 minutes. The unit is deployed whenever it is ready (at most one every `gold/18` s, clamped 6–30 s; the
commander pauses up to 25 s to save for it), the commander runs everything else, and the battle records the unit's
deployments and damage dealt. Raw lines are in `build/cov0.txt` / `build/cov1.txt` (`COVER …`).

- **Every unit appears in a realistic loadout** (160/160) and **158/160 were fielded**. The two that never were are
  the Skyforge Dreadnought and the Skyhammer Battleship: at 2,110 and 2,245 Gold, a 25 s savings window on stages 131/138 never
  reached their price while the commander kept the line alive. They are fielded in the Act V commander sweeps (the
  `rotate` rule) and the Sovereign counter plan uses the Dreadnought.
- **Median damage per Gold by role** (8-minute sample): interceptors 15.1, indirect artillery 14.9, large siege 14.0,
  armoured vehicles 13.0, anti-armour 11.5, rifles 9.8, gunships 9.9, bombers 8.9, anti-swarm 8.4, melee 6.1,
  frontline defenders 3.5, anti-air 2.0 (AA only scores when there are flyers in reach), repair/support/fieldworks
  < 1 (they heal, supply, build or spot; damage does not measure them).
- **Zero or near-zero damage, explained:** carriers (their drones deal the damage under the drone's own id), the
  automated turret crew (likewise its turrets), the bombard zeppelin, the flak colossus, King's Anvil, Mountain Ark and
  Colossal Skybreaker (deployed once or twice, late, on stages that ended before these slow frames reached the
  front). The `roster` suite checks separately that every unit performs its role against a dummy in reach (§4).
- **Buffed through data** (clear outliers against their role, with no other job to explain it):

| Unit | Role | Damage/Gold before | Change |
|---|---|---|---|
| Bayonet Fusilier (research-only, T1) | rifle infantry | 1.73 (role median 9.8) | HP 110 → 130, fusil 15 → 18, bayonet 14 → 16 (design values) |
| Grapeshot Culverin (research-only, T1) | anti-swarm | 2.38 (median 8.4) | grapeshot 11 → 14 per pellet |
| Drillwalker (T2 war frame) | anti-armour | 0.69 (median 11.5) | HP 900 → 1,100, ARM 0.20 → 0.25 (it died walking to the front) |

  None of the three is in any sim army, so the sweep numbers above are unaffected. The coverage sweep was not re-run
  after the buffs.
- **Not buffed:** units that only look weak in this measure (support, repair, spotters, fieldworks, AA on quiet
  skies), and the 35 runs that ended in a loss: replacing a slot of the realistic army with the unit under test, and
  forcing deployments, breaks the army on some stages (the T1 research-only units were tested on stage 020, a boss
  stage). A loss here says nothing about the stage's balance.


### 3.5 Spark economy
- Act V pays 9,177 Sparks; the campaign pays **29,228** by 150 (37,997 with every first-time star bonus), plus
  Heroic first-clear bonuses (35 % of a stage's Sparks).
- Every doctrine and every tier gate (the research that opens a tier) costs 2,265; with the research-only units,
  2,805. A player can afford each tier's gate on reaching it: T1 from stage 10, T2 at 15, T3 at 21, T4 and T5 long
  before they open at 075 and 105.
- Researching **the whole roster** at the new prices plus every doctrine and variant costs **38,345**: more than the
  campaign pays (29,228), and more even with every star (37,997). So Sparks cannot buy everything early.
- What this means in play: by 150 a player **owns every unit** anyway, because blueprints hand out 144 units and the
  other 16 are cheap research (this is what §9 asks: "by then every unit is reachable"). Sparks decide **how early**
  a player gets units ahead of their blueprint. They cover every tier and a chosen part of the roster, not all of it.
  Replays and Heroic first clears fund the rest.

### 3.6 Difficulty curve
The budget chart (bottom panel of `m008_balance.png`) rises from ~50 at 001 to 100–180 through Acts II–V. Every boss
is now followed by a **relief stage** at no more than 90 % of the budget of the stage before the boss (or the act's
band floor): 011 (77), 021 (111), 031 (94), 041 (95), 051 (92), 061 (117), 071 (125), 081 (102), 091 (112), 101 (112),
111 (120), 121 (123), 131 (115), 141 (123). Only 015 (the Act I finale) and 087 (the combined-assault exam) sit more
than 30 % above their neighbours' mean, both by design (§2.5). The relief stages were re-simulated on Normal and Heroic:
all win, in 4:01–8:50.

## 4. Tests
All suites ran headless (`godot --headless --path . res://tests/test_runner.tscn -- --suite=<name>`) on the final
build, every one with **0 script errors**. Logs: `build/gate/*.log`.

| Suite | Result | | Suite | Result |
|---|---|---|---|---|
| registry (expects 150 implemented stages) | 2/2 | | m006_save | 1/1 |
| combat | 8/8 | | ui_m006 | 3/3 |
| boss | 1/1 | | motion | 2/2 |
| mecha | 41/41 | | wrecks | 5/5 |
| mecha_scenarios | 6/6 | | hazards_m007 | 5/5 |
| mecha_audio | 2/2 | | boss_phases_m007 | 3/3 |
| mecha_save | 1/1 | | heroic | 4/4 |
| giants | 18/18 | | m007_save | 1/1 |
| giants_scenarios | 4/4 | | ui_m007 | 4/4 |
| bosses_all (15 bosses) | 15/15 | | audio_m007 | 1/1 |
| hazards | 5/5 | | **hazards_m008** | **6/6** |
| boss_phases | 4/4 | | **boss_phases_m008** | **3/3** |
| stars (incl. `no_spills`) | 4/4 | | **m008_save** | **1/1** |
| m005_save | 1/1 | | **ui_m008** | **3/3** |
| ui_m005 | 4/4 | | **audio_m008** | **1/1** |
| air_war | 8/8 | | **last_stand** (+ 30-min soak) | **5/5** |
| hazards_m006 | 6/6 | | cache | 1/1 |
| boss_phases_m006 | 3/3 | | art_m006b | 5/5 |
| ui / ui --quality=low | 8/8 / 8/8 | | roster 0–135 / 135–270 | 1/1 / 1/1 |
| save_write → save_verify | 1/1 → 1/1 | | **boss_counters** (040–150) | **12/12** |
| `artcheck.tscn` (xvfb) | 3/3 PASS | | **stages 1–150** Normal / Heroic | **300/300 / 299/300** (§3.1) |

**New M008 tests:**
- `hazards_m008` (6): rift tears telegraph for 2 s, open as portals with HP, spill their group when they close, and
  spill nothing if destroyed first; tears are not support structures; tears open at seeded positions (same stage →
  same places); the eclipse cuts unlit ranged reach 25 % on both sides, a rifleman inside a rune-sight scout's light
  keeps full range, melee is unaffected, and it ends after its duration; a soul wisp heals undead (never a boss) and
  burns dwarves it passes, and flak shoots it down; the obelisk ward (−15 %) ends when the obelisk breaks; Act V uses
  all three hazards.
- `boss_phases_m008` (3): the Hollow King's crown (crowned elite, half damage on the King, ward, re-crown after the
  elite dies); the Sovereign's gales push aircraft back and the pull drags them in at 25 %; the Rift Lich rises at
  66 % into the high band (a ground cannon cannot hit it, flak can), its legion spawns, and it returns at 33 % with
  the soul storm.
- `last_stand` (5): deterministic waves, a lord of the dead every 10th wave, rising budgets; the citadel never falls
  and the run continues under the commander with rising Gold; best wave/score kept per arena, cosmetic milestones,
  **no Sparks**; unlock after 060 (Act IV arena after 090); the **30-minute soak** (below).
- `m008_save` (1): an M007 save (no M008 fields, a malformed Last Stand entry) loads with all progress and Sparks,
  gains every new field with defaults, opens 121, and clearing 150 seals the Rift and grants `rift_sealer`.
- `ui_m008` (3): the Last Stand arena picker, completion page, campaign ("Rift Sealed"), Settings (Replay ending)
  and the hub's Last Stand station open; the ending runs rift collapse → (skip) epilogue → credits, the march pans the
  Realm Map with a column on the road, and `ending_seen` is saved; the Act V Realm Map floats the rift-sky landmarks
  aloft and switches to the sealed palette after 150.
- `audio_m008` (1): the Act V ambiences, the Lich theme and the ending march are cached loops; the hazard, boss and
  Last Stand cues exist.
- `boss_counters` gained plans for 130/140/150; `coverage` is new (§3.4).

**Last Stand soak (30 minutes of game time, Cinder Canal, stronghold HP ×40 so the run lasts):** reached wave 21;
objects between 1,848 and 1,942 with no upward trend (1,874 at the end), static memory 46–47 MB; units on the field 11–59; undead alive at most 42 in the 2-minute
samples (cap 56), undead flyers at most 7 (cap 24). The first soak run "failed" with steady object growth: the
test stepped the battle in a tight loop, so dead units queued for deletion were never freed (that only happens at
the end of a rendered frame). The soak now yields one engine frame per simulated second, as the game does 30–60
times a second, and the growth disappears. This was a test artifact, not a leak in the game.

**Screenshots looked at by eye:** every new environment (darkest and brightest), the Act V Realm Map (both halves, the
rift vista and the sealed state), each hazard, each boss phase, every ending part and the credits, the Last Stand
screen and a wave-21 run, the completion page, and the war-frame sheets.


## 5. Performance
Measured by `tests/bench.tscn` on the **Performance preset** (`--quality=low`) on software OpenGL (llvmpipe) on a
virtual display, M007 (the `M007 baseline` commit, checked out separately) against M008 on the same machine in the
same session. Crowd scenes: 150 frames after 200 warm-up frames. Stage scenes: the auto-commander plays the stage to
the given time, the camera moves to the densest 1,280 px, then 120 frames are measured. Each ran twice. These numbers
compare builds; they are not phone frame rates.

| Scene | M007 (run 1 / run 2) | M008 final (run 1 / run 2) |
|---|---|---|
| Default crowd: frame | 80.95 / 86.00 ms | 81.52 / 79.82 ms |
| Default crowd: logic | 10.83 / 11.94 ms | 10.77 / 10.23 ms |
| Default crowd: draw calls | 408 / 405 | **339 / 339** |
| Machine crowd (war frames, tanks, airships): frame | 83.64 / 88.30 ms | 76.54 / 76.71 ms |
| Machine crowd: unit draw | 3.08 / 2.90 ms | 2.68 / 2.82 ms |
| Machine crowd: draw calls | 356 / 356 | **303 / 303** |
| Stage 087 (Act III, busiest): frame · avg draw calls (max) | 63.91 / 59.71 ms · 321 (1,171) | 62.26 / 60.41 ms · 261 (1,111) |
| Stage 118 (Act IV, busiest): frame · avg draw calls (max) | 68.71 / 65.58 ms · 598 (1,186) | 67.97 / 70.15 ms · 555 (1,176) |
| **Stage 149** (Act V, busiest: 63 alive, peak 71) | — | 54.30 / 59.76 ms · **357** (1,068) |
| **Stage 150** (Rift Lich aloft, 305 s) | — | 66.22 / 71.63 ms · 386 (993) |
| **Stage 137** (eclipse, citadel) | — | 70.47 / 75.07 ms · 440 (1,169) |

Screens (draw calls / frame):

| Screen | M007 | M008 first measurement | M008 final |
|---|---|---|---|
| Campaign map (Realm Map) | 520 | 520 | **137** |
| Forge hub | 502 | 502 | **264** |
| Main menu | 209 | 278 | **45** |
| Last Stand (new) | — | **1,322** | 126 |
| Completion page (new) | — | **1,306** | 107 |
| Ending (new) | — | 48 | 48 |

Battle environments (default crowd on each backdrop, draw calls): necro_waste **634 → 358**, ruined_citadel 576 → 527,
realm_gate 436 → 387, rift_sky 420 → 371, mountain_gate (Act I reference) 390 → 341.

**What the first measurement found, and the two fixes:**
1. **Label drop shadows cost one draw call per glyph.** With the theme's Label shadow, the GL Compatibility renderer
   could not batch text, so every character was a draw call. The new text-heavy screens came in at 1,300 draw calls
   (more than twice the budget); one stats line cost 145. The theme now draws Label text with a thin dark outline
   (3 px, 60 % black) instead of the 1×2 px drop shadow, which batches in one pass. Text reads the same on the forged
   plates (checked on screenshots), and every screen and the battle HUD got cheaper. This is a global look change, so
   it is listed here and in §7.
2. **The necro_waste backdrop** drew ~230 small skulls, eye sockets, mounds and bone knobs as separate shapes (one draw
   call each). They are now collected into one triangle array per layer (`BattleBackground._disc` /
   `_flush_discs`). Same picture, ~280 fewer draw calls: stage 149 went from 646 average draw calls (over budget) to
   357.

**Reading:** CPU frame and logic times are within run-to-run noise of M007 everywhere (the budget is +10 %); draw
calls are lower everywhere and every measured battle and screen averages under 600. The "max" column is the single
worst frame in the window (explosion-heavy frames, as in M007), not the average the budget refers to. New hazards use
the existing batched layers (`HazardLayer`, `FxLayer.DOT`); there are no new shaders or SubViewports in battle. The
Last Stand soak (§4) found object count and static memory flat over 30 minutes.

Pose-cache bounds were re-measured after the war-frame changes (`tests/bounds.tscn -- --machines`): 31 arts changed
and 2 were new (the rift tear and the soul wisp) in the first pass, and 6 more changed after the shoulder-mount move.


## 6. How to run the M008 checks
```
godot --headless --path . res://tests/test_runner.tscn -- --suite=hazards_m008     # also boss_phases_m008, m008_save, ui_m008, audio_m008
godot --headless --path . res://tests/test_runner.tscn -- --suite=last_stand --soak=1800   # 30-minute Last Stand soak
godot --headless --path . res://tests/test_runner.tscn -- --suite=boss_counters --stage=150
godot --headless --path . res://tests/test_runner.tscn -- --suite=coverage --from=0 --to=80   # unit coverage (prints COVER lines)
python3 tools/batch_sim.py --from 1 --to 150 --out build/sims_all.csv           # Normal sweep (commander + idle)
python3 tools/batch_sim.py --from 1 --to 150 --heroic --out build/sims_all_heroic.csv
python3 tools/economy.py --normal build/sims_all.csv --heroic build/sims_all_heroic.csv --png docs/screenshots/m008_balance.png
python3 tools/sim_view.py build/sims_all.csv                                    # compact per-stage view
xvfb-run godot --path . res://tests/screenshot.tscn -- --shot=battle --stage=124 --ff=30 --eclipse --scout=760 --out=/tmp/e.png
xvfb-run godot --path . res://tests/screenshot.tscn -- --shot=ending --cleared=150 --ending_part=coda --ending_frames=190 --out=/tmp/c.png
```

## 7. Honest limits and deviations from the master prompt
**Not tested on a phone.** Everything ran headless or under xvfb with software OpenGL. The benchmark numbers in §5
compare builds on the same machine; they are not phone frame rates. The Android APK was built, signed and verified,
but not installed on a device.

Conflicts between the prompt and the code (the code wins on facts, as §0 says):
1. **Boss HP.** The prompt lists 28,000 / 30,000 / 34,000 HP. The bosses tuned in M005–M007 use fixed HP on a much
   lower scale against the same unit damage (Plague Regent 5,800 … Fallen Titan 11,000, Ashen Forge Tyrant 13,000,
   Corpse Colossus 15,000). The Hollow King and the Rift Lich continue that scale: **Hollow King 12,000, Rift Lich
   16,000**; their difficulty comes from the phases (the crown ward halves the King's damage taken; the Lich spends a
   third of its HP aloft, where only anti-air reaches it), in line with rule 6. The prompt's 28,000 and 34,000 were not
   simulated. The **Gravewing Sovereign** is at **26,000**: 17,000 died too fast to a dedicated AA army and the
   prompt's 30,000 was simulated and lost the counter run (§3.3).
2. **Rift tears "at random x".** Tears use their own seeded generator (`rift_rng`, stage seed + 4242), so the places
   are random-looking but the same on every attempt at the same stage, as the prompt's "fixed seed per stage" asks.
3. **Eclipse light sources.** The roster has no "light" flag, so a unit counts as lit if it has a spotter range, an
   explicit `light` value, or a reveal aura. That covers scouts, spotter balloons, rune-sight scouts, the mortar
   spotter and surveyors; undead night seers light the undead line. Melee is unaffected by design (it has no range
   to lose).
4. **Soul wisps "shot down by flak".** Wisps fly low in the mid band, so flak, AA artillery and aircraft hit them,
   and so does anything else with mid-band reach; ground rifles cannot.
5. **Plague colossus "first colossus in the campaign".** Stage 132 is the first stage that fields one; the colossus
   tier (plague colossus, rift maw) appears nowhere before Act V.
6. **Last Stand arenas.** Three arenas (Acts I–III) open at 060 as asked; the fourth (Cinder Canal, Act IV) opens
   at 090, because its roster is Act IV's corrupted machines, which a player at 060 has never met.
7. **Act V difficulty band.** The stage validator's budget band for Act V was set to 100–440 (Act IV's floor is
   higher), because relief stages after the bosses (131, 141) sit below Act IV's floor by design. The budget
   function now counts tear spills (a tear left alone adds its spill to the stage's threat), which it did not before.
8. **Wrecks only in Act IV.** The M007 wreck-reclaiming corruptors and wreck spawns stay limited to Act IV stages
   (91–120); Act V enemies do not reclaim wrecks. This is a scope choice, not a bug.
9. **Auto-commander changed as a test tool.** Act V's sims showed the commander never fielded colossal units (it
   spammed cheap units, as §12.2 warns). A `rotate` flag now makes it save for, and field, the least-used heavy unit
   it can afford within ~25 s of income, from stage 121 on. Acts I–IV sims run without it, as before. The heavy-unit
   "saver" also no longer treats the Titan Maintenance Crew (a repair unit) as a heavy.
10. **Global changes from the balance pass** (§2): research costs per tier, curve smoothing of 12 stages and two
    stages left above the 30 % neighbour line on purpose (015, the Act I finale; 087, the combined-assault exam).
    Each is listed with before/after values in §2.
11. **Procedural art and synthesized audio.** As in every milestone, all art is drawn in code and all audio is
    synthesized at first launch. The Lich theme and the ending march are synthesized loops, not recorded music.
12. **Boss clips.** Short clips were rendered from the screenshot tool (§9); they are recorded on the virtual display at
    a fixed frame step, so motion is smooth but not real-time captured.
13. **Label text style (global).** To fix the draw-call budget (§5), Label text across the game uses a thin dark
    outline instead of a drop shadow. It is a small visual change on every screen, made for performance.
14. **Credits.** The credits credit the project's creator for design and direction and say plainly that the code, art,
    audio and tools were built with Claude (Anthropic). They do not invent studio staff. Edit `CREDITS` in
    `scripts/ui/ending.gd` to add names.

## 8. Request made in the session: the "Titanforge" war-frame overhaul
The complaint was that the walkers, the wide T5 ones above all, looked bad. Looking at the M007 sheets, the problems
were the proportions, not the detail:
- **Too wide, too short:** colossal frames had a torso almost as wide as tall on short, splayed legs, so they read
  as a squat box on stilts, not a giant.
- **Heads sunk into the chest:** the head sat inside the torso outline with no neck, at the same size on every
  class, so the big frames looked headless from a distance.
- **Shoulders and pauldrons in the wrong place:** the shoulder joint sat at the torso corners, pauldrons floated
  above it, and the shoulder weapon mounts were drawn across the face.
- **Legs:** a bent "chicken" crouch on heavy frames, and thighs drawn as flat slabs with oversized knee plates.

What changed (`scripts/art/art_mechs.gd`, one shared painter, so all 28 war frames changed):
- **Proportions by class:** longer, thicker legs (colossal thigh 31, shin 29, leg width 20, foot 30, torso 54),
  narrower colossal torsos and shoulders, straighter legs and a wider stance; heavy frames crouch less.
- **A head on a neck, scaled by class** (light 1.0, medium 1.08, heavy 1.16, colossal 1.3, with a neck 1–4.5 px long)
  and a riveted gorget, so every frame has a readable head and the big ones look big.
- **Shoulders:** the joint is an iron ball at the chest flanks; heavy and colossal pauldrons are flattened, tilted caps
  with two lames, seated on the joint. Shoulder weapon mounts moved beside the head, clear of the face.
- **New torso types for the T5 giants:** a tower torso, a "walking keep" fortress torso with battlements, and a
  furnace torso with a glowing grate; an abdomen section between chest and hips; a commander **bridge window with a
  tiny dwarf** in it on colossal frames; a stone-masonry finish for the Mountain Colossus and a royal mantle for the
  King's Anvil.
- **Legs:** cylinder thighs with a hip ball, smaller knee cops and ankle discs.
- The collision/selection bounds (`data/art_bounds.json`) were re-measured after the change (`tests/bounds.tscn --machines`).

Before/after sheets: `docs/screenshots/m008_mechs_t5_before.png` / `m008_mechs_t5_after.png`, the full walker roster in
`m008_mechs_all_after.png`, and a close-up in `m008_mech_closeup.png`. Gameplay is unchanged: only drawing code and
bounds moved, and the mecha suites (41 + 6 scenarios) pass.

## 9. Deliverables
- `build/android/DwarvesVsZombies-M008.apk` (47.05 MiB): debug build, exported with a stub SDK (no Gradle), then aligned
  and signed with the debug key by uber-apk-signer. zipalign and the **v1/v2/v3 signatures are verified**. Manifest
  version 0.8.0-M008, code 11. SHA-256 `80fa9d01a80322dbf1d8a3e7ec59a8559679f750282caefef8975c59f6aca9b8`.
  **Not installed on a phone.**
- `build/linux/DwarvesVsZombies.x86_64`: release export. It ran for 300 frames under xvfb and exited with code 0, with
  0 script errors; the only warnings were the missing audio device, V-Sync, and the usual ObjectDB-at-exit notice.
- `DwarvesVsZombies_M008_project.zip`: the project without `.godot/`, `build/`, `*.import`, `.git` or `__pycache__`.
- This report, the README update ("What is new in M008"), the screenshots and clips below, and the balance data
  (`build/campaign_balance.csv` is generated; rerun `tools/economy.py` to rebuild it from the sweep CSVs).

### 9.1 Screenshots (`docs/screenshots/`)
| File | Shows |
|---|---|
| `m008_env_waste_bright.png`, `m008_env_waste_dark.png` | necro_waste at its brightest and in the eclipse |
| `m008_env_riftsky.png` | rift_sky: cracked violet sky, floating shards, the causeway |
| `m008_env_citadel_bright.png`, `m008_env_citadel_dark.png` | ruined_citadel, bright and dark |
| `m008_env_gate.png` | realm_gate: the Rift and the gate of bone and iron |
| `m008_hazard_tear.png`, `m008_hazard_souls.png`, `m008_hazard_obelisk.png` | a rift tear opening, soul wisps over the line, obelisk ward threads |
| `m008_boss_hollow_king.png` | the Hollow King with a crowned elite |
| `m008_boss_sovereign_gale.png`, `m008_boss_sovereign_pull.png` | the Sovereign's gales and pull |
| `m008_boss_lich_1.png`, `m008_boss_lich_2_aloft.png`, `m008_boss_lich_3_storm.png` | the Rift Lich's three phases |
| `m008_realm5_a.png`, `m008_realm5_b.png`, `m008_realm5_rift.png`, `m008_realm5_sealed.png` | the Act V Realm Map, the Black Rift vista, the sealed state |
| `m008_ending_rift.png`, `_banners`, `_march`, `_coda`, `_epilogue`, `_credits` | the ending, epilogue and credits |
| `m008_laststand_screen.png`, `m008_laststand_wave21.png` | the Last Stand arena picker and a run at wave 21 |
| `m008_completion.png` | the completion page |
| `m008_balance.png` | the full-campaign balance chart (win times, Spark economy, budgets) |
| `m008_mechs_t5_before.png` / `_after.png` | the six colossal war frames, M007 vs M008 |
| `m008_mechs_heavy_before.png` / `_after.png` | the eight heavy war frames, M007 vs M008 |
| `m008_mechs_all_after.png`, `m008_mech_closeup.png` | all 28 war frames after the overhaul; Deepforge Titan and King's Anvil close up |

### 9.2 Clips (`docs/clips/`, 960 px, rendered frame by frame from the screenshot tool)
`m008_clip_ending.mp4` (the whole ending and the epilogue card, 93 s at real speed), and 5–6 s boss clips:
`m008_clip_king.mp4` (the crown), `m008_clip_gale.mp4` and `m008_clip_pull.mp4` (the Sovereign), `m008_clip_lich1.mp4`,
`m008_clip_lich2.mp4`, `m008_clip_lich3.mp4` (the Lich's three phases). The clips use the screenshot tool's default
army, not the stage army, and a first-encounter hint is on screen in some of them.

