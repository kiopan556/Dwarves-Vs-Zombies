# M002b — Undead Giants + Mobile Performance Patch

Engine: Godot 4.3-stable (GL Compatibility). Date: 2026-11-01.
Everything marked **tested** was executed in this build environment (headless, or a virtual X display with
software OpenGL for rendering numbers). **It has not been run on an Infinix Hot 30i or any other Android device**, so
no phone FPS is claimed; the numbers below are relative measurements that show where the cost went.
The M001 and M002 reports are kept unchanged next to this one.

---

## 1. Undead Giants (12 new functional enemies)

Built from existing planned roster entries, so **no new IDs and no roster entries removed**
(undead registry still 110; implemented undead 14 → 26). They mirror the war-frame size classes:

| Class (= frame class) | Scale vs Rifleman | Giants |
|---|---|---|
| Brute (= light) | 2.0× | **Carrion Bull** (quadruped, Stampede charge) · **Bone Golem** (bone clubs, Bonequake) · **Plague Beast** (bile cone, Plague Pool) |
| Abomination (= medium) | 2.85× | **Stitchback Giant** (twin cleavers, Butcher's Flurry) · **Ossuary Juggernaut** (coffin shield 30 % frontal, Coffin Rush) · **Corpse Mound** (Disgorge: spawns Rotters, cap 9) · **Ghoul Matriarch** (anti-air shriek, Feeding Call rally) |
| Behemoth (= heavy) | 4.0× | **Cathedral Ghast** (bell flail + anti-air dirge, Funeral Toll stun) · **Blackroot Abomination** (95-reach root lash + thorn volleys, Rootsnare slowing zone) · **Walking Crypt** (crypt-lid slam + bone catapult, Open the Crypt: skeletons) |
| Colossus (= colossal) | 5.6× | **Plague Colossus** (fist + spore-geyser AA + bile mortar, Plague Nova + acid pool) · **Rift Maw** (torso-maw bite + rift bolts, Devour heals from damage dealt) |

- **Art:** original procedural art on a shared organic rig (`scripts/art/art_giants.gd`).
  - IK legs that plant their feet; a hunched, weighted torso; tapered flesh and bone limbs.
  - Each giant has its own body type, head, weapons and back-piece (belfry, crypt with catapult, fungal stacks, rift crystals, branches, meat hooks).
  - Animation: wind-up telegraphs, ability auras, a stun halo and battle damage.
- **Systems:** giants reuse the war-frame machinery: ARM% (≤ 50 %, penetration), independent multi-weapon targeting, the staged-death sequence and the ability state machine.
- **Abilities** run on necrotic cooldowns (no Steam). There are two new kinds: **summon** (respects a per-giant cap) and **rally** (buffs nearby undead). Zones now carry a damage type, a look and an optional slow.
- **Marching:** giants keep walking while their secondary guns fire; only the main weapon halts them.
- **Death:** giants unravel in gore, bone and necrotic bursts instead of fire. They have their own footstep and roar sounds.
- **Campaign:** brutes now appear sparingly in Act I.

  | Stage | Giant | Time |
  |---|---|---|
  | 011 | Bone Golem | 170 s |
  | 012 | Plague Beast | 200 s |
  | 013 | Carrion Bull | 210 s |
  | 015 | Carrion Bull + Bone Golem | 230 s |

  Bigger giants are sandbox-only, matching the T3–T5 frames that would answer them.
- **Sandbox:** four new scenarios, **GA–GD**: light frames vs brutes, medium vs abominations, heavy plus aircraft vs behemoths, and a colossal clash.

## 2. Performance patch (for low-end phones such as the Infinix Hot 30i)

### What was slow
Measured in a crowded test battle (about 115 units on screen):
- **About 8,900 GPU draw calls per frame.** Every polygon, outline and circle of every procedural unit is its own draw call, and low-end mobile GPUs handle only a few hundred per frame comfortably.
- **10.5 ms of the 15.7 ms frame** (server CPU) went on rebuilding every unit's geometry every frame in GDScript.
- Game logic took 5.5 ms, with some per-call hot spots.
- Physics catch-up could run up to 8 extra logic steps on a slow frame, a spiral that makes a struggling phone slower still.
- About 0.4 s of synchronous sound synthesis ran at every launch.

### What changed
1. **Pose cache: units drawn as baked sprites** (`scripts/core/pose_cache.gd`).
   - **Baking:** each unit's animation pose is quantized and baked once into a 2048² atlas page. The unit then draws one textured quad, and quads from the same page batch together.
   - **What a pose depends on:** the painter records which animation fields each art actually reads, so infantry no longer multiply poses by fields they never draw.
   - **Big frames:** each art has a cell budget scaled by its size. Past the budget, new poses snap to the nearest cached pose instead of filling the atlas.
   - **No gaps:** cells are clipped to measured art bounds (`data/art_bounds.json`). Until a pose is ready the unit draws live as before, so nothing ever pops out.
2. **One layer for bars:** health and ability bars are drawn by one overlay layer, and the hit flash is a tint, so each unit is exactly one quad.
3. **Particles and pebbles:** particles and the 160 ground pebbles are textured dots, which batch into a handful of draw calls instead of hundreds.
4. **HUD and menus:** HUD card previews and menu sprites use the cache. The Great Forge hub bakes its static cavern into two textures and only draws its moving parts live.
5. **Logic hot spots fixed:**
   - The aim point is computed once per unit; it was looked up through an art-name `match` inside every spatial query.
   - The front line is found once per step, keeping the live position.
   - Gunship target search runs at about 3 Hz instead of every step.
   - Pose keys use integer-coded plans.
   - Off-screen units skip pose work.
6. **No more slowdown spiral:** physics catch-up is capped at 2 steps per frame, so a slow frame makes the game run slightly slower instead of compounding.
7. **Audio cache:** generated sounds are saved to `user://sfx_cache` after the first launch.
8. **Three quality presets** in Settings (Graphics quality):

   | Preset | Art | Frame cap | Logic rate | Other |
   |---|---|---|---|---|
   | High | live procedural | 60 FPS | 60 Hz | full effects |
   | Balanced | baked sprites | 60 FPS | 30 Hz | — |
   | Performance | baked sprites | 30 FPS | 30 Hz | halved particles, smaller atlas (3 pages), big frames baked at 1.5× |

   **Phones default to Performance.** A phone that already has a save from the M001/M002 APKs is switched to Performance once on first launch of this build; it can be changed back in Settings.

### Measured effect (same crowded test battle; server CPU, software OpenGL under a virtual display)
About 103 units on screen (dev panel hidden, as in a real battle), 200 warm-up frames, then 150 measured.
"Before" is the same build with the patch disabled; "High" keeps the live art but has the logic fixes.

| | Before patch | High | Balanced | **Performance** |
|---|---|---|---|---|
| GPU draw calls / frame | **8,926** | 8,026 | 242 | **253** |
| Primitives / frame | 335,000 | 298,000 | 11,400 | **11,300** |
| CPU frame (headless: logic + unit drawing) | 15.7 ms | 14.5 ms | 7.0 ms | **6.9 ms** |
| — unit drawing | 10.5 ms | 10.4 ms | 1.7 ms | **1.7 ms** |
| — game logic | 4.7 ms | 3.5 ms | 4.2 ms | **4.1 ms** |
| Full frame incl. software-GL rendering | 153 ms | 128 ms | 38.5 ms | **38.0 ms** |
| Great Forge hub draw calls | 804 | 754 | — | **260** |
| Sound synthesis at launch | 379 ms | 2 ms after the first launch (disk cache) | | |

That is about **35× fewer draw calls** and **about 2.3× less CPU per frame** in a crowded battle.
Software OpenGL here is not a phone GPU, so read the last rows as relative cost, not as phone FPS.
The higher logic figure in Balanced and Performance comes from the 30 Hz logic step: each step covers twice the time, and there are half as many steps per second.

Accepted trade-offs in the baked presets:
- Animation is quantized to about 8–12 poses per second, like hand-made sprite sheets. Movement stays smooth.
- Colossal frames are slightly softer in Performance mode, where they are baked at 1.5× and scaled up.
- The first seconds of a battle bake new poses: up to 8 per frame, drawn live until ready.

## 3. Tested (final run)
| Suite | Result |
|---|---|
| Project import + parse | no errors |
| `giants` — 12 giants individually (spawn, foot-planting gait, targets, damage, range, AA where armed, ability used, **no Steam**) + summon cap 9/9, Toll stuns 5/5, Rootsnare slows 4, Feeding Call frenzies 6, Devour heals 3,400 → 3,736, death releases references | **18/18** |
| `giants_scenarios` GA–GD (frames vs giants, 150 s cap; both sides deal damage, 0 invalid targets, pools bounded) | **4/4** |
| `mecha` (M002 frames + systems) / `mecha_scenarios` A–F / `mecha_audio` / `mecha_save` | **41/41 · 6/6 · 2/2 · 1/1** |
| `registry` (160/110/15/150; 44 dwarves + 26 undead implemented, each acts) | **2/2** |
| M001 `combat` A–J — default and Performance preset | **8/8 · 8/8** |
| `boss` (Mine Maw) | **1/1** |
| `ui` smoke — default and Performance preset (every screen incl. the baked hub) | **8/8 · 8/8** |
| Save write + fresh-process verify | **pass** |
| Stages 001–015 winnable and losable (default) | **30/30** |
| Stages 011–015 again on the Performance preset (giant stages included) | **10/10** |
| `SCRIPT ERROR` lines across all logs | **0** |

Rendering was also checked visually on the Performance preset: battles, the Great Forge hub and the giant gallery
(`docs/screenshots/14_*`–`16_*`). There were no missing units and no broken atlas cells.
A regression the tests caught along the way: an early version of the front-line cache returned the position from the start
of the step, which turned the marginal Stage 014 into a stalemate. It now reads the live position, and Stage 014 wins at 638 s as before.

## 4. Limitations (honest)
- **Not device-tested.** The patch removes the measured bottlenecks (draw calls, per-frame geometry, logic hot spots, physics spiral, startup synthesis), but I could not measure the frame rate on an Infinix Hot 30i. Please report how it runs on Performance, and if needed on Balanced.
- The APK is debug-signed (stub SDK tools at export, then zipaligned and signed with uber-apk-signer), as in earlier builds.
- The atlas uses about 48 MB of video memory in Performance mode (3 × 2048² RGBA pages) and about 64 MB in Balanced (4 pages).
- Giant balance is provisional. In the sandbox matchups, war frames of the same class beat the giants while taking losses.
- Abilities of the bigger giants (behemoth, colossus) are only seen in the sandbox until Acts II–V exist.
- Art and audio remain procedural and synthesized placeholders.
