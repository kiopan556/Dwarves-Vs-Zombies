# M006 — War for the Skies: Act III, the air war, sky hazards, and the animation upgrade

Engine: Godot 4.3-stable (GL Compatibility). Date: 2026-11-01. Version 0.6.0-M006 (Android version code 7).
Everything marked **tested** ran in this build environment: headless, or on a virtual X display with software
OpenGL for screenshots and the benchmark. **The build has not been run on an Android phone.** No on-device frame
rate is claimed. The M001–M005 reports are kept unchanged next to this one.

---

## 1. What was built

### 1.1 Campaign: Act III, stages 061–090
30 authored stages (`tools/act3_data.py`, composed with `tools/stage_kit.py` like Act II) replace the planned
placeholders. Every stage has its own name, environment, enemy mix, tagline, rewards and challenge objective, and
keeps a real ground front: the validator still refuses a stage without both fronts. The act opens with a big sky
battle over a light ground front (061), introduces the first flak belt (062), thermals (063), the floating ruins
(065), armoured gargoyles (066), the lightning storm (067), the first drake and the first escort (068), the first
infected airbarge (069), and builds to the combined-arms exam (089). 15 stages carry a hazard; three carry an
escort objective. Bosses: **Bone Wyrm** (070), **The Hollow Admiral** (080), **Dread Sky Tyrant** (090).
Clearing **075 opens T4 research** (the gate already existed; 075 also carries `open_tier: 4`).

Two new toolkit templates: `flak_belt(...)` (a line of anti-air structures the air arm has to fly through) and
`sky_host(...)` (one track per flyer type for big sky battles). The validator learned the new hazards, the
`escort` data block (t, hp, speed, alt, x0, x1) and the `escort` challenge.

### 1.2 Air-war systems
| System | What it does | Where |
|---|---|---|
| **Altitude bands** | Every flyer has a band (`low` / `mid` / `high`) in its data; every weapon that can shoot at the sky has a `reach`. A weapon hits a flyer only if the flyer's band ≤ its reach. Derived by default: airships, drakes, sky serpents and bosses fly **high**; bats, gargoyles, stalkers and the strafing craft fly **low**; everything else **mid**. Flak, airships, interceptors, AA roles and undead AA structures reach **high**; other aircraft and other sky-capable ground weapons reach **mid**; `ground_lowair` (blunderbusses, stomper vents) stays **low** (only diving flyers, as before). Data may override either field. | `tools/gen_data.py` `apply_bands`, `Weapon.can_hit_domain`, `Battle.acquire / find_nearest / bat_prey` |
| Band altitudes | Flyers cruise inside a window per band (low y 295–380, mid 238–318, high 160–232), so the three bands read apart on screen; thermals move a flyer ±70 px (one band) | `BAND_ALT` in `gen_data.py` |
| **Flak belts** | Lines of `grave_flak_spire`, `soul_turret` (and beacons) across the undead half on 9 stages; spires reach every band | `stage_kit.flak_belt` |
| **Escort objective** | A non-deployable allied airship, `supply_barge` (airship-kit art with slung cargo crates and a pennant), launches at `escort.t`, flies its route and is delivered at `x1`. Undead flyers and AA hunt it. Delivering it is the third-star challenge (`ch("escort")`); losing it is **never** a defeat and never counts as a unit or aircraft loss. Delivered barges are counted in a new `stats.escorts` profile field. | `Battle.spawn_escort / _tick_air_war`, `Unit._escort` |
| **Air budget** | At most **24** undead flyers alive at once, independent of `max_alive`; flyer tracks wait for room, bosses are exempt; effects stay in the existing pooled FX layer | `Battle.AIR_CAP`, `WaveDirector.step` |

### 1.3 Hazards
| Hazard | Behaviour | Visual / audio | Counterplay |
|---|---|---|---|
| `thermals` | Fixed columns (`columns: [[x, ±1], …]`, `width`). A flyer inside an **updraft** rises a band and an aircraft flies 20 % faster; a **downdraft** sinks it a band and slows it 20 %. Applies to both sides; bosses keep their band. A drake sunk by a downdraft comes into reach of mid guns. | Translucent shimmering columns with rising warm (or falling cool) motes and direction chevrons, batched DOT quads; an updraft whoosh | Route aircraft around the columns, or hold them back |
| `lightning_storm` | Every `interval` s (scaled by the storm boost) a strike is telegraphed for **0.8 s** with a flickering fork and ring over its target, then hits the **tallest thing near a random x**: flyers first, then walkers, giants and spires — **both sides**. Spires and other structures take double damage; the bolt arcs 40 % into anything packed close by. | Flicker, bolt polyline, a brief screen flash; a pre-strike crackle and a thunder crack; storm stages also darken the battle sky | Spread aircraft and walkers out; the storm wrecks undead spires too |
| `gale` | Reused unchanged on 5 stages | — | — |

### 1.4 Battle environments
`open_plains` (towering cumulus, windmills, burnt farmsteads with smoke, tall grass, standing stones, cart ruts),
`broken_ridge` (split spires with a lit face and a shadow face, rope bridges, cairns, scree), `airborne_ruins`
(floating islands with ruined towers, waterfalls into cloud, chains between near islands, distant islets over the
cloud sea; the battle lane is a paved causeway on a floating rock with the cloud sea beneath it) and
`shattered_fort` (light shafts through an overcast deck, collapsed bastions, leaning towers with tattered
banners, broken gun emplacements). Drifting cumulus sit on a separate **parallax layer** (one batched draw, moved
by transform, never redrawn). Lightning stages render the same environments in **storm lighting** (slate and
violet sky, dark storm clouds). Undead flyers read against the bright skies by their dark outlines; no extra rim
pass was needed (checked by eye on the screenshots).

### 1.5 Realm Map (Act III)
- **Aloft placement**: `airborne_ruins` landmarks float ~150 units above the surface on an island (lit top, shaded
  underside, grass lip), hung with chains to the ground; a **dashed airship route** climbs from the road to the
  island and back down, with a mooring mast and gasbag at its foot. The road itself runs on below.
- **Landmarks**: a windmill farmstead (plains), a rope-bridge outpost between two crags (ridge), a ruined tower on
  its island (airborne ruins), a broken bastion (shattered fort).
- **Boss set pieces**: a skeletal wyrm coiled through a split ridge (070); the Hollow Admiral's ghost flagship moored
  in cloud (080); a storm throne of black clouds and lightning (090).
- **Live layer** (cheap): whiter drifting clouds for Act III, little dwarven gasbags plying the routes to cleared
  islands, and a lightning flicker with dark cloud puffs over every storm stage.

### 1.6 Bosses
Each boss keeps its M003 kit and gains a telegraphed 50 % phase (`scripts/battle/boss_phases.gd`); the M005
arrival pan and sting apply to all three.

| Boss | Phase (tested) | Intended counters |
|---|---|---|
| Bone Wyrm (070) | Every 22 s it **dives into the chasm** (untargetable, unseen), a telegraphed eruption circle appears under the densest dwarven ground cluster, it **erupts** there (120 damage) and lies on the ground for **6 s**, ground-targetable, then takes off | Flak and interceptors in the air, artillery and heavy guns when it surfaces |
| The Hollow Admiral (080) | **Two infected airbarges** arrive as escorts and the Admiral is **shielded** (a ghostly ward bubble; hits spark off it) until one escort falls | Airships, gunships and AA artillery on the escorts; ground troops for the boarders |
| Dread Sky Tyrant (090) | At 50 % the storm intensifies (strikes ×1.8 as often, 70 % of strikes seek a dwarven aircraft); at **25 %** it **lands** just ahead of the dwarven front for 8 s and breathes on the line, ground-targetable | Spread air units, own flak, superiority craft, ground AA |

### 1.7 Animation upgrade (requested on top of the master prompt)
**Motion layer** (`Unit._motion`, all units). The pose cache draws units as baked atlas sprites whose poses step at
~8–12 fps. M006 adds smooth secondary motion as the unit node's own transform — scale, skew (a lean pivoting at the
feet) and rotation — driven by two damped springs per unit (vertical compression and lean/kick) plus per-class
rhythm. It costs a few float operations per unit, no draw calls and no extra atlas cells, and it moves every frame
on every quality preset:
- **Dwarven infantry**: stride hop and squash on the planted foot, a jaunty forward lean, idle breathing (goofy, as
  the tone rule asks). **Undead infantry**: a heavy forward lurch with a dragging, irregular sway — never bouncy.
- **Tanks and vehicles**: engine shiver at idle, suspension pitch on the move, a rearing kick when the gun fires.
- **War frames and giants**: every footfall drops the frame onto the planted foot and rolls its weight across;
  mass-scaled recoil with an under-damped spring that wobbles as it settles (light frames snap back, colossi
  heave); boiler breathing at idle; giants lumber with more sway.
- **Artillery**: the whole piece rears back on firing and settles.
- **Aircraft**: a wobble when badly damaged and a kick on firing on top of the existing bank. **Airships**: a slow
  pitch, a roll away from their own broadsides, and a list when below half health.
- **Flyers**: wingbeat squash-and-stretch (slow and heavy for drakes, wyrms and bosses).
- Hits jolt every body (bigger hits and lighter bodies jolt more).
The layer is **presentation only**: it never moves the node (an early version did nudge ground units vertically,
which leaked into aim points and changed a stage result — caught by the full sweep, fixed, and now covered by a
test that plays stage 040 with motion on and off and requires identical results). Settings gained a
**"Unit motion"** switch (reduced motion).

**War frames (pose art, `ArtMechs`)**: heel-toe **foot roll** (heel strike, flat stance, heel peel at push-off,
toe hanging through the swing), a higher and heavier step (lift 8–11 instead of 5–7), **pelvis roll** (the hip
over the swinging leg drops), **arm counter-swing** against the legs, toe claws on heavy and colossal feet, and a
**12-step walk cycle** on Balanced/High (8 on Performance, so the Performance atlas budget is unchanged). Undead
giants share the rig's improved foot path.

**Tanks (pose art, `ArtKit._veh`)**: road wheels visibly turn (spokes), both runs of the track move, dirt is thrown
up behind moving tracks, exhausts belch harder under way and after a shot, and cannon turrets leave a drifting
**muzzle smoke ring** after each shot.

### 1.8 UI
- **Battle HUD**: a sky-threat indicator next to the minimap (one row per band — high, mid, low — with a pip per
  hostile flyer); the escort barge's health as a thin bar under the stronghold gauge (gold when delivered, red when
  lost), shown only while an escort is in play.
- **Stage drawer**: the escort objective with an airship icon and its launch time; for cleared stages, the altitude
  bands its known flyers use ("Sky bands: low ×2 · high ×1", tooltip explains who can hit each band); hazard
  descriptions for thermals and lightning.
- **Compendium**: an "Altitude band · can hit" line on every dossier, and each sky-capable weapon lists its reach.
- **Hints**: new first-encounter lines for high flyers, thermals and lightning.

### 1.9 Audio
Synthesized like the rest (cache version `m006-1`, so the first launch after updating re-synthesizes once):
lightning `crackle` and `thunder`, `updraft` whoosh, `wyvern_roar`, thumping drake `wingbeat`, `serpent_hiss`,
`ghost_bell` and `timber_creak` for the ghost fleet, the barge's `airship_horn`; four ambience loops (plains: high
wind and a snapping flag; high ridge: creaking rope bridges and distant thunder; cloud sea: hush and a far ghost
bell; fort: tattered banners and loose stones). Sky monsters near the camera voice themselves now and then.

### 1.10 Progression and rewards
Blueprints follow §7 of the master prompt in order (boss stages give two). Sparks 140–200 per regular stage
(075 gives 200), 320 / 350 / 380 for the bosses; Act III pays 5,546 Sparks (12,941 cumulative before star
bonuses), so Age of War Machines (180) and early T4 units are affordable well before 085. T5 stays gated at 105.

### 1.11 Save compatibility
New fields: `settings.motion` (default on) and `stats.escorts` (default 0), both filled by `SaveManager.migrate()`.
An M005 save loads with all progress, opens Act III at 061, and opens T4 on clearing 075 (tested).

---
## 2. Tuning method and assumptions
- **Loadout assumption** (`_act3_loadout` in the test runner): T0 starters + every blueprint rewarded before the
  stage + the Act I-b research set + Boiler Stomper and Ironclad Walker (researched in Act II, the M005
  assumption). **No extra T4 research is assumed**: from 075 the only T4 units in the simulated army are the
  blueprints Act III itself awards. One pick per role for the 7 ground slots (shield, heavy tank, anti-swarm,
  anti-armour/rifles, artillery, ground AA, repair), four flyers (interceptors first, because they reach every
  band) and a walker in the flex slot. The commander is the M005 generic one, unchanged; it knows nothing about
  bands, thermals or escorts, so the results are a floor.
- **Process**: `batch_sim.py` (two processes) → `--suite=probe --stage=N` for failures → edits in
  `act3_data.py` → re-run; three Act III rounds, then three full 001–090 sweeps (see §6 for what the full sweeps
  caught). Main Act III changes along the way: the Tyrant's HP and weapons (§5), lighter openers on 078, 082,
  085 and 089 (heavy-armoured legionary/vanguard hordes plus aura carriers swamped the line), one rot launcher on
  074, fewer structures on 082, a slower storm on 088, earlier `until`s and a lower citadel on 071.

## 3. Act III stages and final results
Final sweep (`build/sims_final.csv`, **all 90 stages, both modes: 180/180 runs pass**). "Auto-commander" must win;
"Idle loss" is the same stage with no deployments, which must lose. Budget = threat-weighted spawns per minute
from tracks (boss stages exclude the boss). Sparks are cumulative from stage 001, before star bonuses.

| Stage | Name | Env | Hazard | Budget | Auto-commander | Idle loss | Blueprint(s) | Sparks (cum.) | Challenge |
|---|---|---|---|---|---|---|---|---|---|
| 061 | Windscour Steppe | open_plains | gale | 126.8 | WIN 6:11 (stronghold 100%) | LOSS 62s | rolling_shield_trooper | 140 (7535) | Lose no aircraft |
| 062 | Flakline Rise | broken_ridge | — | 125.1 | WIN 7:09 (stronghold 100%) | LOSS 114s | incendiary_grenadier | 142 (7677) | Destroy every undead support structure |
| 063 | Thermal Fields | open_plains | thermals | 139.3 | WIN 7:59 (stronghold 100%) | LOSS 112s | armored_recovery_team | 144 (7821) | Lose at most 32 units |
| 064 | Shattered Watch | shattered_fort | — | 188.8 | WIN 7:38 (stronghold 100%) | LOSS 90s | turret_engineer | 146 (7967) | Never let the stronghold drop below 60% |
| 065 | Skerry of Bones | airborne_ruins | — | 129.3 | WIN 6:49 (stronghold 100%) | LOSS 106s | flak_chaser | 148 (8115) | Lose no aircraft |
| 066 | Gargoyle Parapets | shattered_fort | — | 127.3 | WIN 7:01 (stronghold 100%) | LOSS 101s | thunderwing | 150 (8265) | Win with at most 8 unit types deployed |
| 067 | Stormbreak Ridge | broken_ridge | lightning_storm | 142.6 | WIN 7:24 (stronghold 100%) | LOSS 104s | skyguard_walker | 152 (8417) | Destroy every undead support structure |
| 068 | Drakefall Meadow | open_plains | — · escort | 124.1 | WIN 6:04 (stronghold 100%) | LOSS 87s | rune_sight_scout | 154 (8571) | Bring the supply barge safely across |
| 069 | The Hanging Keep | airborne_ruins | thermals | 146.0 | WIN 7:40 (stronghold 100%) | LOSS 81s | sky_mender | 156 (8727) | Lose at most 34 units |
| 070 | **Wyrmcoil Chasm** | broken_ridge | — | 62.9 | WIN 6:42 (stronghold 100%) | LOSS 98s | skyshield_airship, ironcloud | 320 (9047) | Slay the boss within 8:00 of its arrival |
| 071 | Banshee Reach | open_plains | — | 124.6 | WIN 12:48 (stronghold 100%) | LOSS 103s | counterbattery_mortar | 158 (9205) | Destroy every undead support structure |
| 072 | Splintered Bastion | shattered_fort | — | 153.6 | WIN 8:21 (stronghold 100%) | LOSS 78s | piston_cannon | 160 (9365) | Never let the stronghold drop below 60% |
| 073 | Cloudmoor | airborne_ruins | thermals | 124.6 | WIN 5:21 (stronghold 100%) | LOSS 85s | bastion_heavy_tank | 162 (9527) | Lose no aircraft |
| 074 | Thunderhead Pass | broken_ridge | lightning_storm | 146.1 | WIN 8:16 (stronghold 100%) | LOSS 84s | sniper_tank_hunter, cannon_strider | 164 (9691) | Win within 11:00 |
| 075 | Highwatch Citadel | shattered_fort | — | 155.1 | WIN 6:54 (stronghold 100%) | LOSS 91s | twin_cannon_ironclad, runic_mechanic | 200 (9891) | Lose at most 40 units |
| 076 | Serpent's Sky | airborne_ruins | thermals | 124.2 | WIN 8:05 (stronghold 100%) | LOSS 109s | heavy_interceptor | 166 (10057) | Lose no aircraft |
| 077 | Ashfall Plains | open_plains | gale | 160.0 | WIN 10:37 (stronghold 97%) | LOSS 76s | rocketwing | 168 (10225) | Never let the stronghold drop below 60% |
| 078 | Broken Crown Ridge | broken_ridge | — | 137.9 | WIN 6:30 (stronghold 100%) | LOSS 90s | mobile_flak_fortress | 170 (10395) | Lose at most 36 units |
| 079 | Phantom Armada | airborne_ruins | — · escort | 103.6 | WIN 7:22 (stronghold 100%) | LOSS 161s | heavy_skybreaker | 172 (10567) | Bring the supply barge safely across |
| 080 | **The Ghost Fleet** | airborne_ruins | — | 62.5 | WIN 6:42 (stronghold 100%) | LOSS 147s | forgewatch_frigate, bombard_zeppelin | 350 (10917) | Slay the boss within 8:30 of its arrival |
| 081 | Wyvern Downs | open_plains | gale | 150.3 | WIN 7:47 (stronghold 99%) | LOSS 88s | pressure_regulator | 174 (11091) | Lose no aircraft |
| 082 | The Fallen Spire | shattered_fort | — | 119.1 | WIN 8:00 (stronghold 100%) | LOSS 115s | battlefield_surveyors | 176 (11267) | Destroy every undead support structure |
| 083 | Galeward Heights | broken_ridge | gale | 142.1 | WIN 7:26 (stronghold 95%) | LOSS 79s | siege_sapper_tank | 178 (11445) | Win with at most 8 unit types deployed |
| 084 | Isles Adrift | airborne_ruins | thermals | 116.0 | WIN 4:59 (stronghold 100%) | LOSS 75s | boiler_ram | 180 (11625) | Never let the stronghold drop below 60% |
| 085 | Dirge Fields | open_plains | — | 127.8 | WIN 8:15 (stronghold 100%) | LOSS 104s | steamtread_heavy_carrier | 182 (11807) | Win within 11:30 |
| 086 | Gravewing Roost | broken_ridge | lightning_storm | 171.7 | WIN 7:14 (stronghold 100%) | LOSS 60s | claw_harvester | 184 (11991) | Lose at most 40 units |
| 087 | Rampart of Wings | shattered_fort | — | 201.5 | WIN 13:00 (stronghold 100%) | LOSS 100s | mortar_walker | 186 (12177) | Never let the stronghold drop below 60% |
| 088 | Stormcrown | airborne_ruins | lightning_storm · escort | 128.4 | WIN 7:16 (stronghold 100%) | LOSS 155s | furnace_stalker | 188 (12365) | Bring the supply barge safely across |
| 089 | The Last Clear Sky | open_plains | gale | 110.4 | WIN 10:21 (stronghold 94%) | LOSS 92s | thundercoil_frame | 196 (12561) | Lose at most 44 units |
| 090 | **Throne of Storms** | airborne_ruins | lightning_storm | 62.0 | WIN 6:40 (stronghold 100%) | LOSS 108s | thunderbarge, ironhold_carrier | 380 (12941) | Slay the boss within 10:00 of its arrival |

| | Act I (001–030) | Act II (031–060) | Act III (061–090) |
|---|---|---|---|
| Auto-commander win time | 3:07 – 14:37, mean 6:21 | 3:49 – 12:32, mean 5:53 | **4:59 – 13:00, mean 7:45** |
| Wins under 4:00 / 4:00–5:00 / over 12:00 | 4 / 6 / 2 | 3 / 13 / 2 | 0 / 1 / 2 |
| Idle loss time | 71 – 259 s | 71 – 222 s | 60 – 161 s |

Act I and Act II results in this sweep are identical to M005's own (same win times, kills and losses where
compared, e.g. 040: 6:28 in M005's report → 6:28 here; 056 plays out unit-for-unit the same in the benchmark),
which is the regression check the prompt asks for.

**Boss stages, scripted "intended counters" playthroughs** (`--suite=boss_counters`, a human-style player
cycling the counters the drawer recommends; no auto-commander heuristics):

| Stage | Army | Result |
|---|---|---|
| 070 Bone Wyrm | Rolling Shield Troopers, multi-barrel and twin flak, Skyshield AA tank, Thunderback, Siege Howitzer, Skyguard Walker, Flak Chasers, Thunderwings, interceptors | Win 5:41, Wyrm slain at 3:00, dive phase seen, 3 stars |
| 080 Hollow Admiral | Rolling Shield Troopers, Twin-Cannon Ironclad, Incendiary Grenadiers, Heavy Skybreaker, Mobile Flak Fortress, Skyshield Airship, Ironcloud, Heavy Interceptor, gunship | Win 5:25, Admiral slain at 3:37, escort shield seen, 3 stars |
| 090 Dread Sky Tyrant | Rolling Shield Troopers, Twin-Cannon Ironclad, multi-barrel flak, Heavy Skybreaker, Mobile Flak Fortress, Skyguard Walker, Heavy Interceptor, Thunderwing, Flak Chaser, Skyshield Airship | Win 4:53, Tyrant slain at 2:35, storm phase seen, 3 stars |

The M005 runs for 040, 050 and 060 still pass with exactly their M005 times (4:31, 4:37, 4:15).

---

## 4. Tests (all run in this environment, final code)

| Suite | Result |
|---|---|
| Project import + parse | no errors |
| `registry` (expectation updated: 90 implemented stages) | **2/2** |
| `combat` A–J · `boss` (Mine Maw) | **8/8 · 1/1** |
| `ui` · `ui --quality=low` | **8/8 · 8/8** |
| `mecha` · `mecha_scenarios` · `mecha_audio` · `mecha_save` | **41/41 · 6/6 · 2/2 · 1/1** |
| `giants` · `giants_scenarios` | **18/18 · 4/4** |
| `roster --from=0 --to=135` · `--from=135 --to=270` | **pass · pass** |
| `bosses_all` | **15/15** |
| `save_write` → `save_verify` (fresh process) | **1/1 · 1/1** |
| `hazards` · `boss_phases` · `stars` (expectation updated: 001–090, escort kind) · `m005_save` · `ui_m005` | **5/5 · 4/4 · 4/4 · 1/1 · 4/4** |
| `stages --from=1 --to=90` (via `batch_sim.py`) | **180/180** |
| `boss_counters` (040, 050, 060, 070, 080, 090) | **6/6** |
| **New** `air_war`: band/reach data on every flyer and sky weapon, matching the spec table; a 19-case counter matrix on live units (both sides: e.g. a gunship's dorsal gun cannot reach a drake, an interceptor and flak can; undead bats and necromancers cannot reach a dwarven airship, flak spires and soul turrets can); a live gunship never targets a high drake while an interceptor engages it; the 24-flyer budget (bosses exempt); escort launch on time → crossing → delivered → challenge met; escort lost → no defeat, no counted loss, challenge failed, undead flyers hunted it; stage 062's flak belt; Act III has 3 escorts and ≥6 flak-belt stages | **8/8** |
| **New** `hazards_m006`: thermals lift/sink a band (a sunk drake comes into a gunship's reach), ±20 % aircraft speed; lightning 0.8 s telegraph then the tallest target (flyer first, else a walker), spires take double; lightning hits both sides; s067 strikes on schedule with a storm sky; act-wide hazard counts | **6/6** |
| **New** `boss_phases_m006`: Wyrm dive (untargetable) → telegraphed eruption → ground-targetable (a field cannon targets it) → takes off; Admiral's two escort airbarges, immune while shielded, shield breaks when one escort dies; Tyrant storm boost and air bias at 50 %, lands on the front at 25 % (ground guns target it), flies again | **3/3** |
| **New** `m006_save`: an M005 save (no motion setting, no escorts stat, 60 stages cleared, T0–T3) loads, keeps everything, gains the fields, opens 061; clearing 075 opens T4; survives a re-save | **1/1** |
| **New** `ui_m006`: battle HUD sky-threat counts by band and the escort bar appears with the barge; Act III drawer shows the escort line and sky bands; all 9 airborne landmarks float above the surface; Compendium band / can-hit lines | **3/3** |
| **New** `motion`: recoil kicks, springs settle, lean bounded, no NaN, reduced-motion switch zeroes it; **stage 040 played 150 s with motion on and off gives identical kills, losses, stronghold, citadel and deployments** | **2/2** |
| Stage validator (`python3 tools/stage_kit.py`) | 90 stages OK (Act I `until` warnings as in M005) |
| `SCRIPT ERROR` lines in all logs | **0** |

---

## 5. Tuning changes to existing content (before → after)
| Item | Change |
|---|---|
| Bone Wyrm | HP 15,000 × stage multiplier (≈30,000 at 070) → **9,500 fixed**; ARM 0.30 → 0.20 |
| The Hollow Admiral | HP 16,000 × multiplier (≈34,000) → **9,000 fixed**; ARM 0.30 → 0.25 |
| Dread Sky Tyrant | HP 22,000 × multiplier (≈51,000) → **10,000 fixed**; ARM 0.30 → 0.15; breath ×0.5, tail ×0.6; Sky Terror 140 → 90 damage, cooldown 18 → 22 s |
| All flyers / sky weapons | gained `band` / `reach` (data); cruise heights unchanged (see §7.3) |
| `max_alive` for flyers | new independent cap of 24 alive undead flyers |
| Ambient sound timing | moved to its own RNG (§6) — no gameplay effect |

## 6. Problems found and fixed during the milestone
- **The motion layer leaked into gameplay.** Its first version nudged ground units up and down by a few pixels;
  those positions feed aim points and ranges, and stage 040 flipped from a win to a loss in the full sweep. The
  layer now expresses every hop and drop as squash/stretch and never moves the node, and the `motion` suite
  proves a stage plays identically with it on and off.
- **Cosmetic sound timing consumed the gameplay RNG.** The new sky-monster and thermal ambient cues drew their
  timing from the battle's seeded RNG, which shifted every later spawn jitter: stages 050 and 057 (Act II) lost
  in the sweep although nothing about them had changed. They now use a separate presentation RNG; afterwards
  Act I/II replay unit-for-unit as in M005.
- **Altitude windows changed shipped stages.** Clamping every flyer's cruise height into a per-band window (so
  the bands read apart) changed Act I/II results (014 timed out, 020 and 050 lost). The windows are kept in
  `gen_data.py` behind `ALT_WINDOWS = False`; readability now comes from cues instead (§1.2, §7.3).
- The pose-cache bounds tool needs ~20 minutes for 291 arts on this machine; the first two attempts were cut off
  by timeouts and wrote nothing. The third completed; 45 arts changed bounds (tanks are wider for thrown dirt and
  muzzle smoke rings, war frames a pixel taller for the higher step), and `supply_barge` was added.

## 7. Conflicts between the master prompt and the code (code wins on facts, prompt on intent)
1. **Boss HP.** With the per-stage enemy HP multiplier (×2.0–2.3 at 070–090) the listed 15,000 / 16,000 / 22,000 HP
   would have been 30,000–51,000, and the Tyrant at 12,000 fixed still beat both the commander and a scripted army.
   As in M005, Act III bosses use `fixed_hp` and were tuned down (§5); difficulty comes from the phases.
2. **Blueprint lists.** Block 3 (`counterbattery_mortar` … `cannon_strider`) holds five units for the four regular
   stages 071–074, so 074 awards two. Block 7 holds eight units for the nine stages 081–089, so the never-awarded
   T3 **Thundercoil Frame** fills 089.
3. **"Band derived from current altitude ranges by default".** The existing ranges overlap heavily (bats 260–380,
   drakes 220–300, most aircraft 230–330), so a band derived from them would be arbitrary. Bands are derived from
   class and behaviour instead (airships, drakes, serpents, bosses high; bats, gargoyles, stalkers, strafers low;
   the rest mid), and data can override. Cruise heights stay as authored (see §6), so on screen the bands are told
   apart by cues: **high flyers sit in a faint sky haze, low flyers cast a soft shadow on the lane**, mid flyers are
   plain. The thermals still move a flyer ±70 px when they shift its band.
4. **"Low: rifles and flak".** In this codebase rifles are ground-only weapons; only blunderbusses and the
   Boiler Stomper's vents (`ground_lowair`) reach diving flyers, and that is unchanged. Low flyers are hit by any
   weapon that reaches the sky.
5. **Flak belt members.** `bone_bolt_thrower` is a mobile artillery piece in the data, not a static structure, so it
   joins belts as an `until`-limited track; the static belt pieces are `grave_flak_spire`, `soul_turret` and
   beacons.
6. **Escort data fields** are `t, hp, speed, alt, x0, x1` (the validator checks them). The barge's art comes from the
   airship kit (`fam: ship` with a new `cargo` flag).
7. **Altitude readability screenshot "on a phone-sized screenshot"**: checked on 1280×720 captures only.
8. **The animation upgrade** for infantry, tanks, airships and war frames was requested in the session on top of the
   master prompt; it is §1.7.

## 8. Performance (Performance preset, software OpenGL under a virtual display; not a phone)
Same crowded bench as M002b–M005 (`tests/bench.tscn --quality=low --frames=150 --warm=200`, 101 units), both
builds measured alternately three times on the same machine (this machine is slower and noisier than the one in
the M005 report; only side-by-side numbers mean anything):

| | M005 (3 runs) | **M006 (3 runs)** | Median change |
|---|---|---|---|
| Full frame | 113.3 / 106.4 / 100.4 ms | 108.8 / 116.3 / 104.0 ms | **+2 %** (106.4 → 108.8) |
| Game logic per step | 12.95 / 12.32 / 11.41 ms | 13.56 / 14.70 / 12.44 ms | **+10 %** (12.3 → 13.6) |
| GPU draw calls | 637 / 637 / 637 | 394 / 631 / 400 | ≤ M005 |

Real stages at their peak (`bench.tscn --stage=N --ff=200`, auto-commander, camera on the densest stretch):

| Stage | Units on screen / alive | Frame | Logic | Draw calls avg (max) |
|---|---|---|---|---|
| 056 (Act II) — M005 build, 2 runs | 65 / 79 | 94.0 / 87.4 ms | 9.5 / 8.7 ms | 431–434 (1,162) |
| 056 (Act II) — M006 build, 2 runs | 65 / 79 (identical play) | 91.8 / 102.1 ms | 10.4 / 11.9 ms | 436 (1,165) |
| 061 Windscour Steppe (sky battle) | 44 / 64 | 70.9 ms | 5.6 ms | **306** (520) |
| 084 Isles Adrift (mostly air) | 28 / 33 | 89.1 ms | 5.6 ms | **386** (1,109) |
| 087 Rampart of Wings (busiest Act III) | 58 / 83 | 85.8 ms | 8.8 ms | **299** (589) |
| 089 The Last Clear Sky | 43 / 63 | 88.5 ms | 6.4 ms | **351** (1,298) |

**Air-war worst case** (new `--mix=airpeak`: 24 undead flyers of 10 kinds incl. a sky serpent and an airbarge, 30
dwarves + 30 undead on the ground, 3 dwarven airships and 3 aircraft, two thermal columns, `open_plains`):
frame 121–126 ms, logic 13–15 ms; draw calls **326 after a 300-step warm-up, 928 measured after only 200 steps**
while new poses were still being baked (the same bake-spike pattern as the single-frame maxima above). The layer
breakdown at warm-up 300: units ~220 calls, HUD ~400 (label text). Flyers and airships stay inside the pose-cache
budget (snapping is allowed); the cloud layer is one batched draw moved by transform; thermals, lightning and
shadows are batched DOT quads.

**Screens:** campaign map 518 draw calls (M005: 518); main menu 282 (M005: 211 — the longer milestone banner text;
labels cost about a call per character in this renderer).

**Logic cost.** The +10 % logic per step comes from the motion layer (now skipped for off-screen and static
units, mass cached) and the band checks. The full frame stays within the +10 % budget in these measurements, but
the logic figure sits at the edge of it and should be watched on a real device.

## 9. Honest limits
- **Not device-tested.** Nothing in M006 ran on a phone. Timings are software OpenGL on a shared server CPU and
  varied by ±10 % between identical runs. The APK was exported against stub `adb`/`apksigner` and then
  zipaligned and debug-signed with uber-apk-signer (v1/v2/v3 verified); it has not been installed.
- **Balance is a floor.** The commander has no idea about bands, thermals, storms or escorts; it simply fields
  interceptors and flak. It won every Act III stage at 94–100 % stronghold. Two Act III stages run long (071 at
  12:48, 087 at 13:00); none falls under 4:59. Human playtesting is needed — particularly the escort stages,
  where the barge's survival depends on how a player screens it.
- **Act III bosses were cut substantially** from the prompt's numbers (§5).
- **Band readability** relies on haze and shadow cues rather than separated cruise heights (§7.3). Whether low,
  mid and high read apart at a glance on a phone screen is unverified.
- **Boss phases reuse existing art**: the Wyrm's dive hides it and the eruption reuses the strike telegraph and
  dust; the Admiral's shield is a ring and a translucent disc; the Tyrant lands as its flying art at ground level
  — at its 7× scale its wings dominate the lane for 8 s, which reads as dramatic but is not a purpose-made
  landing pose.
- **Motion layer**: it animates every frame while the sprite poses still step at ~8–12 fps on the cached presets,
  so a fast-moving unit's legs can look a touch "stepped" against its smooth sway. Mech walk cycles get 12 steps on
  Balanced/High (8 on Performance). The bounds tool measures walk at 8 phases with a 4 px margin.
- **Escort**: the barge flies a straight route at a fixed height; there is no player control of it and no
  scripted ambush beyond the stage's own waves.
- **First launch after updating** re-synthesizes the sound cache once (version `m006-1`).
- Godot still prints benign "ObjectDB instances leaked at exit" warnings when headless test processes quit.

## 10. Deliverables
- `build/android/DwarvesVsZombies-M006.apk` (0.6.0-M006, version code 7, arm64-v8a + armeabi-v7a, debug-signed,
  v1/v2/v3 verified).
- `build/linux/DwarvesVsZombies.x86_64`, smoke-tested for 300 frames under a virtual display: exit 0, 0 script
  errors (only "no ALSA audio device" from the container).
- Project ZIP (excluding `.godot/`, `build/`, `*.import`).
- Screenshots `docs/screenshots/m006_*.png`: the four environments (bright, storm), thermals, the flak belt, the
  lightning telegraph and strike, the escort barge, the Bone Wyrm erupted, the Admiral's escort shield, the Tyrant
  landed, the Act III Realm Map (islands, airship routes, storm flicker, storm throne), the Compendium band line and
  a war-frame/tank walk-cycle strip. Clips `docs/clips/m006_bone_wyrm.mp4`, `m006_hollow_admiral.mp4`,
  `m006_dread_sky_tyrant.mp4` (each phase from trigger, ~6–8 s).

How to run: `godot --headless --path . res://tests/test_runner.tscn -- --suite=<name>`; new suites `air_war`,
`hazards_m006`, `boss_phases_m006`, `m006_save`, `ui_m006`, `motion`; `boss_counters [--stage=N]` now covers
040–090; `--no_motion` switches the motion layer off for any suite. Sims:
`python3 tools/batch_sim.py --from 61 --to 90 --out build/sims.csv`. Air bench:
`godot --path . res://tests/bench.tscn -- --quality=low --mix=airpeak --dwarves=30 --undead=30 --env=open_plains`.
Walk-cycle strip: `godot --path . res://tests/walkstrip.tscn -- --arts=cannon_strider,hammerfall_goliath --n=8`.
