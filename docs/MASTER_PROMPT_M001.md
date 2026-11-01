# MASTER DEVELOPMENT PROMPT
# DWARVES VS ZOMBIES
## M001 — THE FIRST FLAME: FOUNDATION OF THE GREAT FORGE

**Project:** Dwarves vs Zombies  
**Engine:** Godot 4.x, GDScript  
**Platform:** Android mobile first, desktop-compatible for development  
**Genre:** 2D side-view, real-time, air-and-ground tug-of-war strategy defense  
**Visual style:** Stylized hand-painted fantasy steampunk with gothic undead horror  
**Development milestone:** M001 — Initial game foundation and playable vertical slice

---

# 1. PRIMARY DEVELOPMENT DIRECTIVE

Create a completely new, original Godot game titled **Dwarves vs Zombies**.

The game features one united dwarven kingdom defending its civilization against an ever-expanding undead invasion.

The dwarves use industrial-era firearms, artillery, steam tanks, armored vehicles, mechanical walkers, aircraft, and enormous flying warships.

The undead field overwhelming infantry hordes, skeletal soldiers, necromancers, grotesque monsters, flying creatures, cursed siege engines, and corrupted dwarven war machines.

The game must emphasize **simultaneous land-and-air combined-arms combat**.

The player commands an army, not an individual character.

MANDATORY DESIGN RULES:

1. There are no playable heroes, hero slots, hero abilities, or hero-control systems.
2. There is one unified playable Dwarven Kingdom, not multiple playable national factions.
3. Every dwarven unit belongs to the same permanently unlockable military roster.
4. Land and air battles take place simultaneously on one continuous 2D battlefield.
5. Aircraft, ground units, anti-air weapons, and bosses interact through actual combat mechanics.
6. The game must support a very large, expandable roster through data-driven unit definitions.
7. Every implemented unit must serve a meaningful combat role.
8. The initial build must function as a real game, not merely a collection of menus, concept art, or inactive unit definitions.
9. Build for low-end Android performance from the beginning.
10. Do not remove existing implemented units to solve performance, balance, or architectural problems.

This is a brand-new project. Do not reuse Stick Zombie Warfare's game world, unit designs, characters, assets, progression, or source code by default.

The game must develop its own artistic and mechanical identity.

---

# 2. ART DIRECTION — STYLIZED INDUSTRIAL FANTASY

## 2.1 Overall visual identity

Use a **stylized, semi-cartoon, hand-painted 2D art style** combining lovable dwarven engineering with genuinely threatening gothic undead.

The visual tone must balance three elements:

**DWARVES:** Charming, stout, expressive, stubborn industrial soldiers.

**MACHINES:** Absurdly overengineered, powerful, heavy, noisy, and mechanical.

**UNDEAD:** Disturbing, decaying, ancient, cursed, and relentless.

Reference inspirations for general artistic principles:

- Warcraft III: readable unit silhouettes and recognizable fantasy riflemen.
- Deep Rock Galactic: dwarven industrial personality and exaggerated equipment.
- Torchlight: chunky fantasy shapes and expressive character design.
- Warhammer fantasy dwarven engineering: overbuilt machinery and artillery.
- Iron Harvest: convincing industrial machine weight and movement.
- Diablo and Darkest Dungeon: gothic menace, corruption, and undead atmosphere.

Use these strictly as high-level references. Create original designs. Do not copy copyrighted unit sprites, characters, logos, interfaces, or recognizable proprietary designs.

## 2.2 Dwarven character design

Dwarves must have:

- Broad torsos and short, powerful legs.
- Large beards, eyebrows, and expressive faces.
- Industrial helmets and reinforced boots.
- Leather, cloth, steel, copper, and brass equipment.
- Distinctive chunky weapons.
- Strong silhouettes readable on mobile screens.
- Individual visual differences between combat classes.

The basic ranged infantry must be a **Dwarven Rifleman**, not a crossbowman.

Dwarven military technology uses rifles, blunderbusses, repeating firearms, explosives, flamethrowers, cannons, mechanical weapons, and rune-enhanced machinery.

No playable dwarven crossbow units.

The standard Ironhold Rifleman should have a heavy, wood-and-metal firearm, visible recoil, a recognizable reload animation, and a convincing blackpowder muzzle flash.

## 2.3 Steam machinery

All major war machines must look industrial and mechanically plausible within the fantasy setting.

Common design elements:

- Boilers and smokestacks.
- Exposed pistons.
- Heavy gears.
- Brass pressure gauges.
- Riveted steel plates.
- Rotating mechanical joints.
- Steam exhausts.
- Large artillery barrels.
- Industrial chains and reinforced mechanisms.
- Glowing rune machinery on more advanced equipment.

Tanks must visibly use tracks or wheels.

Walkers must visibly use articulated mechanical legs.

Aircraft must visibly use rotors, propellers, lift systems, or other comprehensible fantasy-flight mechanisms.

Airships must have believable floating hulls, propulsion systems, suspended weapon mounts, and armored gondolas.

Avoid sleek futuristic science-fiction aesthetics.

## 2.4 Undead visual design

Undead must visually contrast with dwarves.

Use:

- Broken and asymmetrical silhouettes.
- Diseased gray-green flesh.
- Bone-white skeletal structures.
- Torn clothing and corroded armor.
- Necromantic green and violet glows.
- Unnatural body proportions.
- Visible corruption.
- Unsettling movement and attack animations.

Basic zombies should appear miserable, grotesque, and expendable.

Elite undead should look dangerous and intimidating.

Large bosses must have imposing silhouettes recognizable even when viewed at reduced mobile resolution.

## 2.5 Recommended palette

Dwarves: iron gray, warm brass, copper, leather brown, coal black, deep blue, forge orange.

Undead: desaturated green, cold gray, bone white, dark violet, sickly yellow, necromantic green.

Environments: a balance of warm industrial architecture and cold corrupted wilderness.

Maintain strong contrast between units and backgrounds.

## 2.6 Sprite rendering and animation

The game uses side-view 2D sprites, layered sprites, or carefully constructed procedural 2D artwork.

All units require recognizable movement and attack presentation appropriate to their role.

Animation requirements include:

- Infantry walking, firing, reloading, attacking, taking damage, and dying.
- Firearms with visible recoil, muzzle flashes, and projectiles where appropriate.
- Artillery crew operation and heavy cannon recoil.
- Tank track or wheel animation.
- Mechanical walker leg movement, piston activity, and weapon recoil.
- Aircraft propeller rotation, banking, firing, and destruction.
- Airship slow movement, independent turret activity, and damage effects.
- Undead shambling, lunging, collapsing, crawling, and monstrous attack windups.

Do not use static colored rectangles as final character art.

If external sprite generation is unavailable, produce recognizable original procedural silhouettes using Godot's 2D drawing and layered polygon systems. Prioritize clarity and consistency over pretending unfinished art is final.

---

# 3. CORE BATTLEFIELD SYSTEM

The battlefield is one continuous horizontal 2D environment containing two simultaneously active combat fronts.

**GROUND FRONT:** Dwarven infantry, tanks, artillery, engineers, mechanical walkers, undead infantry, monsters, and siege machines.

**AIR FRONT:** Dwarven Flying Machines, bombers, gunships, airships, undead flyers, spectral creatures, and aerial bosses.

Both fronts must remain visible and active during gameplay.

The player deploys units from the dwarven stronghold on the left.

The undead advance from their citadel, nest, portal, or stage-specific stronghold on the right.

The primary victory condition is the destruction of the enemy stronghold.

The defeat condition is the destruction of the dwarven stronghold.

Air units may attack eligible ground targets and structures. Ground-based anti-air units may target aircraft. Certain special units can engage both fronts.

Air superiority is earned through actual combat, not an arbitrary automatic-win meter.

## 3.1 Unit combat roles

Implement and support these tactical roles:

- Frontline defenders.
- Melee damage dealers.
- Rifle infantry.
- Anti-swarm specialists.
- Anti-armor specialists.
- Ranged artillery.
- Indirect artillery.
- Anti-air artillery.
- Mobile anti-air.
- Repair and engineering support.
- Armored vehicles.
- Heavy assault tanks.
- Mechanical walkers.
- Dedicated aerial interceptors.
- Tactical bombers.
- Multirole gunships.
- Airship artillery.
- Aerial carriers.
- Large siege units.

Each unit must have valid targets, effective range, a combat role, strengths, weaknesses, and costs.

## 3.2 Targeting and combat behavior

Required targeting classes:

- Ground only.
- Air only.
- Ground and air.
- Structures prioritized.
- Armored targets prioritized.
- Swarm targets prioritized.
- Support targets prioritized.
- Repair/support targeting.

Targeting priorities must consider threat, distance, weapon range, firing arc, and attack readiness.

Units should not constantly switch targets without reason.

Do not allow ordinary riflemen to shoot flying enemies unless they are a designated anti-air variant.

Flak Cannons prioritize airborne threats.

Dedicated bombers prioritize ground targets.

Flying Machines prioritize aerial interception.

Gunships can engage both fronts where their weapons permit.

## 3.3 Multi-weapon vehicles

Multi-turret tanks, large mechs, and airships require independent weapons.

Each weapon can have its own:

- Target.
- Range.
- Reload duration.
- Rotation.
- Damage.
- Damage type.
- Projectile.
- Firing arc.
- Attack timing.

A Skyforge Dreadnought must be capable of firing ground bombardment cannons while independently operating its anti-air guns.

Do not implement all turrets as a single synchronized weapon.

## 3.4 Aircraft movement

Flying Machines should patrol, intercept, and disengage according to their tactical role.

Bombers perform attack runs and return to rearm.

Gunships move into effective engagement positions.

Large airships advance slowly and use their multiple weapons within effective range.

Aircraft must not simply fly offscreen and disappear permanently after one attack unless explicitly designed as expendable single-use units.

Use lightweight movement and altitude systems suitable for Godot mobile optimization.

## 3.5 Ground movement and blocking

Ground units move toward the enemy stronghold.

Melee units engage enemies at appropriate distances.

Defensive units form the primary frontline.

Ranged infantry attempt to remain behind friendly frontline units where possible.

Artillery fires from the rear and should be vulnerable if enemies reach it.

Tanks and walkers occupy physical ground space, but avoid excessive collision stacking and permanent movement deadlocks.

Units should not overlap into unreadable visual piles.

---

# 4. ECONOMY AND DEPLOYMENT

Use a unified economy for both fronts.

## Gold

Gold is the main combat currency.

It generates over time and may be supplemented by limited combat rewards or stage-specific economic mechanics.

All units consume Gold when deployed.

## Steam Pressure

Steam Pressure supports advanced machinery and certain special combat actions.

Examples:

- Mechanical overdrive.
- Emergency pressure release.
- Heavy weapon boosts.
- Specialized mechanical abilities.

Ordinary infantry and basic aircraft should not require Steam Pressure just to function.

Avoid introducing too many resource types during M001.

## Deployment loadouts

Long-term army loadout target: 12 unit slots.

- 7 ground slots.
- 4 air slots.
- 1 flexible slot.

The flexible slot can hold any eligible ground or air unit.

No hero slot.

The player may eventually unlock all 160 playable units, but does not bring all 160 unit types into one battle.

Support saved loadout presets in the architecture.

Include cooldowns, costs, and readable deployment states.

---

# 5. COMPLETE DWARVEN ROSTER MASTER PLAN

**Long-term target: 160 playable unit types.**

These units belong to one shared kingdom.

Seven technology branches exist for research organization, not for restricting army composition.

Every roster entry must eventually have a stable internal ID, unit class, tier, primary role, secondary role if applicable, Gold cost, Steam cost where applicable, health, armor type, speed, range, attack profile, cooldown, valid targets, special behavior, unlock requirements, and asset identifiers.

The following is the named master roster.

Names and category allocations are established in M001. Full final statistics must be balanced through playtesting rather than invented as supposedly validated values.

## BRANCH A — INFANTRY & FIREARMS (32)

T0:
1. Tunnel Militia
2. Ironhold Rifleman
3. Shieldbearer

T1:
4. Blunderbussier
5. Grenadier
6. Hammer Guard
7. Sapper
8. Longrifle Scout
9. Bayonet Fusilier
10. Shotgun Breacher
11. Powder Loader

T2:
12. Flame Trooper
13. Steamgunner
14. Rune Cartridge Rifleman
15. Trench Guard
16. Repeater Fusilier
17. Bombardier
18. Armor Piercer

T3:
19. Veteran Rifleman
20. Heavy Hammerer
21. Skyguard Marksman
22. Rolling-Shield Trooper
23. Incendiary Grenadier
24. Mortar Spotter

T4:
25. Royal Iron Guard
26. Thunder Rifleman
27. Furnace Assault Trooper
28. Runebreaker Infantry
29. Heavy Gatling Dwarf

T5:
30. Colossus Guard
31. Arc Lance Gunner
32. Kingsguard Bulwark

## BRANCH B — ENGINEERS & FIELDWORKS (20)

T1:
1. Field Mechanic
2. Ammunition Porter
3. Boiler Tender
4. Salvage Crew

T2:
5. Repair Wagon
6. Steam Sapper
7. Field Barricade Crew
8. Mine Layer
9. Spotter Balloon Crew

T3:
10. Armored Recovery Team
11. Turret Engineer
12. Pressure Regulator
13. Runic Mechanic
14. Battlefield Surveyors

T4:
15. Heavy Recovery Crawler
16. Mobile Forge Crew
17. Counter-Curse Technician
18. Automated Turret Crew

T5:
19. Master Fabricator Team
20. Titan Maintenance Crew

## BRANCH C — ARTILLERY & ANTI-AIR (20)

T0:
1. Light Field Cannon
2. Flak Crew

T1:
3. Organ Gun
4. Portable Mortar
5. Grapeshot Culverin
6. Skyhook Rocket Rack

T2:
7. Steam Mortar
8. Heavy Bombard
9. Rocket Battery
10. Shrapnel Howitzer
11. Twin Flak Mount

T3:
12. Siege Howitzer
13. Piston Cannon
14. Counterbattery Mortar
15. Multi-Barrel Flak

T4:
16. Heavy Skybreaker
17. Rune Cannon
18. Thunder Rocket Battery

T5:
19. Mountain Siege Cannon
20. Celestial Flak Array

## BRANCH D — ARMORED VEHICLES & TANKS (26)

T1:
1. Brasshound Armored Car
2. Coalrunner Scout Tank
3. Steamwheel APC

T2:
4. Copperback Light Tank
5. Ironrunner Light Tank
6. Flamebelcher Medium Tank
7. Ironclad Medium Tank
8. Skyshield AA Tank

T3:
9. Thunderback Heavy Tank
10. Bastion Heavy Tank
11. Siege Sapper Tank
12. Boiler Ram
13. Twin-Cannon Ironclad
14. Sniper Tank Hunter
15. Steamtread Heavy Carrier

T4:
16. Siegecrawler
17. Mountainshield Heavy Tank
18. Thunderrail Tank Destroyer
19. Firestorm Assault Tank
20. Dreadplate Breaker
21. Mobile Flak Fortress

T5:
22. Mountainbreaker
23. Worldhammer Siege Tank
24. Brass Leviathan
25. Iron Bastion Prime
26. Dreadnought Landship

Maintain tactical distinctions between light, medium, heavy, and super-heavy vehicles.

## BRANCH E — MECHANICAL WALKERS & MECHS (28)

T1:
1. Miner Rig

T2:
2. Boiler Stomper
3. Drillwalker
4. Steam Loader
5. Piston Brawler
6. Copper Sentinel

T3:
7. Ironclad Walker
8. Skyguard Walker
9. Thundercoil Frame
10. Cannon Strider
11. Shieldframe
12. Claw Harvester
13. Mortar Walker
14. Furnace Stalker

T4:
15. Anvilbreaker
16. Siegebellow
17. Furnace Guardian
18. Siege Hammer Walker
19. Flak Colossus
20. Thunderstep Bruiser
21. Shredder Walker
22. Riftshield Walker

T5:
23. Deepforge Titan
24. Mountain Colossus
25. King's Anvil
26. Colossal Skybreaker
27. Hammerfall Goliath
28. Embercore Titan

Mechs must have roles beyond simply being tanks with legs.

Their mechanics may involve heavy melee attacks, shields, crowd disruption, multi-weapon loadouts, overdrive, or specialized anti-air equipment.

## BRANCH F — FLYING MACHINES & AIRCRAFT (22)

T0:
1. Dwarven Flying Machine

T1:
2. Scout Gyro
3. Rotary Interceptor

T2:
4. Bombard Gyro
5. Twin-Rotor Interceptor
6. Skyspotter Scout
7. Coalwing Strafing Craft

T3:
8. Ironwing Gunship
9. Thunderwing
10. Sky Mender
11. Heavy Gyro Bomber
12. Flak Chaser
13. Rune-Sight Scout

T4:
14. Forge Bomber
15. Twin-Flame Gunship
16. Heavy Interceptor
17. Rocketwing
18. Siege Breaker Bomber

T5:
19. Stormforge Bomber
20. Royal Skyguard
21. Skyhammer Assault Craft
22. Arcwing Superiority Craft

The Dwarven Flying Machine is the basic aerial unit and must be available at the beginning of the campaign.

Do not turn it into a one-time airstrike ability. It is a persistent aircraft unit with health, combat behavior, and an actual battlefield presence.

## BRANCH G — AIRSHIPS & FLYING FORTRESSES (12)

T2:
1. Scout Blimp

T3:
2. Ironcloud
3. Skyshield Airship

T4:
4. Bombard Zeppelin
5. Thunderbarge
6. Ironhold Carrier
7. Forgewatch Frigate

T5:
8. Skyforge Dreadnought
9. Mountain Ark
10. Skyhammer Battleship
11. Rune Citadel Airship
12. Grand Forge Carrier

Airships must be treated as a separate aerial class with major differences in speed, durability, operating altitude, weapon systems, and deployment cost.

Carrier airships must be able to deploy or service smaller aircraft according to defined capacity and cooldown rules.

Avoid unlimited free aircraft generation.

---

# 6. COMPLETE UNDEAD ROSTER MASTER PLAN

**Long-term target: 110 regular undead types, excluding bosses.**

The undead are not required to mirror dwarven technology one-to-one.

They should rely on asymmetrical advantages including numerical pressure, resurrection, corruption, monstrous breakthroughs, terrifying aerial creatures, and siege capabilities.

All enemies must have defined combat roles and valid counterplay.

## A. UNDEAD MELEE INFANTRY (30)

1. Rotter
2. Zombie Miner
3. Shambler
4. Grave Crawler
5. Plague Runner
6. Ossuary Skeleton
7. Rusted Legionary
8. Bone Shieldbearer
9. Bone Pikeman
10. Ossuary Axeman
11. Grave Knight
12. Barrow Spearman
13. Blight Marauder
14. Rotting Berserker
15. Fungal Host
16. Pestilent Soldier
17. Crypt Halberdier
18. Tomb Stalker
19. Hollow Guard
20. Risen Bomb Carrier
21. Wretched Climber
22. Carcass Devourer
23. Bone Vanguard
24. Grave Warden
25. Black Rot Infantry
26. Cursed Dwarf Thrall
27. Plague Mauler
28. Dread Executioner
29. Ossuary Champion
30. Riftbound Legionary

## B. UNDEAD RANGED UNITS & NECROMANCERS (18)

1. Bone Archer
2. Grave Slinger
3. Rot Spitter
4. Plague Sprayer
5. Crypt Hexer
6. Corpse Priest
7. Necromancer
8. Ossuary Caller
9. Cinder Wraith
10. Spirit Binder
11. Plague Herald
12. Bone Lancer
13. Grave Dart Thrower
14. Funeral Bell Keeper
15. Rot Channeler
16. Ash Hexer
17. Night Seer
18. Rift Conjurer

Support abilities must be readable, counterable, and limited by cooldowns or other constraints.

## C. UNDEAD MONSTERS & ABOMINATIONS (20)

1. Flesh Hulk
2. Bone Golem
3. Plague Beast
4. Burrow Horror
5. Corpse Mound
6. Rot Hound
7. Grave Spider
8. Tomb Centipede
9. Flesh Charger
10. Bone Devourer
11. Stitchback Giant
12. Carrion Bull
13. Ghoul Matriarch
14. Oozing Horror
15. Ossuary Juggernaut
16. Cathedral Ghast
17. Plague Colossus
18. Blackroot Abomination
19. Corpse Burrower
20. Rift Maw

Large monsters must demonstrate physically convincing weight, appropriately telegraphed attacks, and distinct vulnerabilities.

## D. UNDEAD SIEGE & STRUCTURES (18)

1. Bone Catapult
2. Corpse Lobber
3. Grave Mortar
4. Bone Spire
5. Grave Flak Spire
6. Necrotic Beacon
7. Cursed Barricade
8. Plague Cauldron
9. Bone Bolt Thrower
10. Walking Crypt
11. Bone Ram
12. Flesh Trebuchet
13. Grave Howitzer
14. Plague Spore Cannon
15. Rot Launcher
16. Soul Turret
17. Rift Obelisk
18. Wraith Beacon

Some structures provide defensive area denial, while others summon units or support existing undead formations.

## E. FLYING UNDEAD (18)

1. Carrion Bat
2. Blight Bat
3. Grave Moth
4. Plague Shrieker
5. Bone Wyvern
6. Skeletal Vulture
7. Rotwing
8. Tomb Gargoyle
9. Carrion Wasp
10. Spectral Wraith
11. Bone Drake
12. Plague Harpy
13. Gravewing Stalker
14. Rift Crow
15. Ossuary Flier
16. Banshee Wing
17. Wraith Swarm
18. Necrotic Sky Serpent

Flying undead require their own attack behaviors.

Small flyers may attack in swarms.

Larger creatures can perform dives, ranged attacks, breath attacks, or aerial interception.

Aircraft and flying undead must interact with ground-based anti-air systems.

## F. CORRUPTED DWARVEN MACHINES (6)

1. Risen Copperback
2. Cursed Ironclad
3. Possessed Drillwalker
4. Gravegun Tank
5. Haunted Flying Machine
6. Infected Airbarge

These are undead-controlled machines using corrupted mechanical and necromantic technologies.

They must remain visually distinct from their original dwarven counterparts.

---

# 7. THE FIFTEEN MAJOR BOSSES

Create a long-term plan for 15 major bosses.

Every boss must possess a recognizable combat identity, meaningful counterplay, and an appropriate supporting enemy composition.

**ACT I — THE MOUNTAIN HOLDS**

- Stage 10: Mine Maw — Burrowing ground monster.
- Stage 20: The Bellringer — Undead summoner using terrifying bell attacks.
- Stage 30: Ossuary Matron — Necromantic support boss with periodic aerial escorts.

**ACT II — THE BLIGHTED FRONTIER**

- Stage 40: Blightroot Behemoth — Massive corrupted ground monster.
- Stage 50: Plague Regent — Elite plague commander.
- Stage 60: Gravewing Matriarch — Major flying undead boss.

**ACT III — WAR FOR THE SKIES**

- Stage 70: Bone Wyrm — Flying and burrowing monster.
- Stage 80: The Hollow Admiral — Commander of an undead aerial formation.
- Stage 90: Dread Sky Tyrant — Colossal aerial boss.

**ACT IV — THE FALLEN FOUNDRIES**

- Stage 100: The Fallen Titan — Corrupted colossal dwarven mech.
- Stage 110: Ashen Forge Tyrant — Undead industrial warlord.
- Stage 120: Corpse Colossus — Enormous ground siege boss.

**ACT V — THE BLACK RIFT**

- Stage 130: The Hollow King — Elite undead ruler and summoner.
- Stage 140: Gravewing Sovereign — Massive airborne undead creature.
- Stage 150: The Rift Lich — Final boss commanding a simultaneous ground and air assault.

Bosses must not be isolated damage sponges.

They should use supporting enemies and meaningful attack patterns.

Boss support reinforcements may arrive periodically while the boss remains alive, but must have sensible caps, intervals, and counterplay. Reinforcement behavior must stop when the boss is defeated.

Avoid unfair unavoidable attacks.

---

# 8. THE CAMPAIGN — 150 STAGES

The long-term campaign contains exactly 150 main stages divided into five acts of 30 stages each.

## ACT I — SIEGE OF THE MOUNTAIN HOLDS

Stages 001–030.

Environment: Dwarven mountain fortresses, mines, industrial passes, and abandoned outposts.

Primary technology: T0–T1.

Introduce the basic riflemen, artillery, Flying Machines, rudimentary armor, and initial undead threats.

Air combat begins in Stage 001, not midway through the campaign.

Stage 010, 020, and 030 feature major bosses.

Early stages must have real pressure and interesting tactical decisions. They must not be long, empty waiting exercises.

## ACT II — THE BLIGHTED FRONTIER

Stages 031–060.

Environment: Dead forests, plague marshes, ruined roads, and corrupted mines.

Primary technology: T2.

Introduce light and medium steam tanks, early mechs, bombers, and stronger enemy air defenses.

Increase ground-air interaction and environmental hazards.

## ACT III — WAR FOR THE SKIES

Stages 061–090.

Environment: Open plains, broken mountain ridges, airborne ruins, and shattered fortifications.

Primary technology: T3.

Large aerial battles become increasingly prominent.

Introduce heavy interceptors, gunships, combat airships, and advanced anti-air warfare.

Ground armies remain important in every stage.

## ACT IV — THE FALLEN FOUNDRIES

Stages 091–120.

Environment: Abandoned industrial cities, destroyed forges, infested factories, and enormous mechanical wreckage.

Primary technology: T4.

Introduce corrupted dwarven machines, heavy assault mechs, super-heavy armor, advanced siege machinery, and aircraft carriers.

Include dangerous enemy combined-arms formations.

## ACT V — THE BLACK RIFT

Stages 121–150.

Environment: Necromantic wastelands, unnatural sky formations, ruined citadels, and the entrance to the undead realm.

Primary technology: T5.

Introduce colossal dwarven war machines, major flying fortresses, terrifying undead bosses, and the most demanding combined-arms battles.

The final stage must involve both fronts in a meaningful manner.

## Stage design rules

Every stage requires a stable stage ID, environment definition, enemy roster, spawn schedule, escalation rules, difficulty budget, rewards, and victory condition.

Include variation in:

- Initial enemy pressure.
- Infantry-to-monster ratios.
- Aerial presence.
- Enemy artillery.
- Anti-air defenses.
- Ground chokepoints.
- Environmental hazards.
- Periodic reinforcements.
- Air-ground coordinated attacks.
- Boss support behavior.

Avoid repetitive stages differing only in enemy health multipliers.

Use authored encounter structures supplemented by deterministic variation where appropriate.

Preserve the “show, don't tell” approach during combat.

Do not display intrusive stage-type announcements such as HOLD, SIEGE, ARMOR, HORDE, or AIR RAID.

Enemy activity should communicate threats naturally.

After clearing a stage, the campaign map may reveal its enemy lineup and boss identity. Uncleared stages should not spoil their complete encounters.

---

# 9. TECHNOLOGY TREE AND PROGRESSION

Implement a unified Great Forge technology system.

All seven branches are permanently researchable:

1. Infantry & Firearms.
2. Engineers & Fieldworks.
3. Artillery & Anti-Air.
4. Armored Vehicles.
5. Mechanical Walkers.
6. Aeronautics.
7. Airship Engineering.

The technology tiers are:

- T0 Foundations — 6 playable unit types.
- T1 Age of Blackpowder — 22 additional types.
- T2 Age of Steam — 32 additional types.
- T3 Age of Iron — 38 additional types.
- T4 Age of War Machines — 35 additional types.
- T5 Age of Colossi — 27 additional types.

Total: 160.

Research must allow cross-branch progression.

Examples:

Heavy Artillery + Armored Engineering unlocks advanced siege tanks.

Mechanical Engineering + Anti-Air Technology unlocks Skyguard Walkers.

Aeronautics + Heavy Gunnery unlocks advanced gunships.

Airship Engineering + Aircraft Logistics unlocks carriers.

Advanced Rune Engineering + Colossal Mechanical Frames unlocks the largest titans.

Research unlocks must be permanent within the player's save.

Do not permanently lock the player into one technology branch.

A newly researched heavy unit must not automatically invalidate earlier, cheaper units.

Use persistent research data with stable IDs and version-compatible save structures.

---

# 10. PLAYER INTERFACE

The user interface should feel like a dwarven industrial command console.

Visual materials:

- Brass.
- Steel.
- Carved stone.
- Reinforced wood.
- Gauges.
- Rivets.
- Furnace lighting.

Keep the actual battlefield HUD functional and visually restrained.

Required screens:

1. Main Menu.
2. Campaign Map.
3. Army Loadout.
4. Great Forge Technology Tree.
5. Unit Compendium.
6. Settings.
7. Battle Screen.
8. Victory Screen.
9. Defeat Screen.

Main menu should feature original dwarven industrial styling and an animated or illustrated forge atmosphere.

Battle HUD should display:

- Dwarven stronghold health.
- Enemy stronghold health.
- Gold.
- Steam Pressure.
- Deployment slots.
- Unit cooldowns.
- Pause and speed controls where appropriate.
- Limited, relevant alerts.

Both air and ground fronts must remain readable.

Implement Android touch input with appropriately sized interactive targets.

Avoid enormous decorative HUD elements that obscure combat.

---

# 11. AUDIO DIRECTION

The dwarven army should sound industrial, heavy, and satisfying.

Include separate audio categories for:

- Rifle fire.
- Blunderbuss fire.
- Rapid-fire weapons.
- Cannons.
- Mortars.
- Rockets.
- Tank movement.
- Mechanical walker footsteps.
- Pistons and steam release.
- Aircraft propellers.
- Heavy airship engines.
- Dwarven vocal reactions.
- Undead snarls.
- Skeletal impacts.
- Necromantic magic.
- Boss attacks.
- Environmental ambience.

Music should blend fantasy orchestration with industrial percussion, rather than imitate modern military soundtracks.

Each act should have its own environmental ambience.

Use original or appropriately licensed audio. Do not include copyrighted sound effects extracted from other games.

---

# 12. MOBILE PERFORMANCE AND ENGINE ARCHITECTURE

Use Godot 4.x and GDScript.

The game must be developed for Android first.

Target smooth gameplay at approximately 60 FPS on capable devices, with a stable 30 FPS performance mode for weaker Android hardware.

Do not claim a performance target has been achieved without device profiling.

Recommended architecture:

- Central battle controller.
- Shared unit state machine.
- Data-driven unit registry.
- Weapon component system.
- Target acquisition component.
- Ground movement controller.
- Aircraft movement controller.
- Multi-turret weapon manager.
- Projectile and explosion pooling.
- Enemy wave director.
- Stage configuration loader.
- Research and unlock manager.
- Save manager.
- Battle HUD controller.
- Audio manager.
- Graphics quality manager.

Use stable IDs throughout all game content.

Keep unit definitions separate from shared behaviors.

Avoid creating 160 separately duplicated scripts.

Use reusable combat components and distinct unit configurations.

Performance requirements:

- Avoid unnecessary per-frame full-army target scans.
- Use spatial filtering for potential targets.
- Pool projectiles and frequently reused effects.
- Limit expensive particle effects.
- Use sprite atlases where practical.
- Reduce offscreen rendering and visual effects.
- Optimize artillery explosions and smoke.
- Handle large zombie swarms efficiently.
- Avoid physics-body collision storms.
- Ensure boss attacks do not freeze the game.
- Keep UI responsive during large battles.

Never sacrifice core gameplay mechanics solely to reach an artificial performance number.

Optimize their implementation first.

---

# 13. M001 ACTUAL IMPLEMENTATION SCOPE

IMPORTANT: The complete 160-unit dwarven roster, 110 regular undead enemies, 15 bosses, and 150 stages are long-term production requirements.

**Do not pretend all of them are fully implemented in M001.**

M001 must establish the complete data architecture and master content registries while delivering a tested playable foundation.

## 13.1 Playable dwarven units for M001

Implement these 18 units as functional combat entities:

1. Tunnel Militia.
2. Ironhold Rifleman.
3. Shieldbearer.
4. Blunderbussier.
5. Grenadier.
6. Field Mechanic.
7. Light Field Cannon.
8. Flak Crew.
9. Organ Gun.
10. Brasshound Armored Car.
11. Copperback Light Tank.
12. Miner Rig.
13. Boiler Stomper.
14. Dwarven Flying Machine.
15. Scout Gyro.
16. Bombard Gyro.
17. Ironwing Gunship.
18. Ironcloud Airship.

Every listed unit must have working movement, attacks or support behavior, targeting, health, death, deployment costs, cooldowns, and recognizable artwork.

Advanced units such as Ironwing Gunship and Ironcloud may initially be exposed in a development testing sandbox before becoming available through proper campaign progression.

The primary campaign must still follow its established technology tiers.

## 13.2 Functional undead types for M001

Implement these 14 enemies:

1. Rotter.
2. Zombie Miner.
3. Grave Crawler.
4. Plague Runner.
5. Ossuary Skeleton.
6. Bone Shieldbearer.
7. Grave Knight.
8. Bone Archer.
9. Rot Spitter.
10. Necromancer.
11. Flesh Hulk.
12. Carrion Bat.
13. Plague Shrieker.
14. Bone Spire.

Implement **Mine Maw** as the first functional major boss.

The Mine Maw must have a distinctive attack pattern, supporting undead reinforcements, and sensible counterplay.

## 13.3 Stages for M001

Fully implement and test the first 15 playable stages of Act I.

These stages must contain actual enemy compositions, increasing difficulty, clear unlock progression, and meaningful variation in land and air combat.

Stage 001 must already introduce simultaneous air-ground combat.

Stage 010 contains the first major boss.

Stages 011–015 should introduce more demanding combinations of familiar enemies.

Define the metadata structure for all 150 stages, including act placement, boss assignments, intended enemy themes, and progression requirements.

Future stages must be clearly marked as planned or not yet implemented, rather than falsely presented as complete playable content.

## 13.4 Functional systems required in M001

The following must work:

- Main menu.
- Campaign stage selection.
- Dwarven unit deployment.
- Enemy unit spawning.
- Shared Gold economy.
- Basic Steam Pressure system.
- Ground combat.
- Aerial combat.
- Air-to-ground attacks.
- Ground-to-air attacks.
- Targeting and damage.
- Multi-weapon support architecture.
- Ground and aircraft movement.
- Basic artillery.
- Infantry and vehicle combat.
- At least one functional mech.
- At least one functional airship.
- Functional enemy boss.
- Stronghold health and destruction.
- Victory and defeat.
- Stage rewards.
- Unit unlock persistence.
- Save and load.
- Pause and settings.
- Functional touch controls.
- A development testing scene for unit and combat diagnostics.

The Great Forge technology interface may initially be limited to the implemented units, but the registry and dependency architecture must support the complete planned roster.

---

# 14. MANDATORY COMBAT VALIDATION

Test these scenarios explicitly:

**Test A — Basic ground combat**

Riflemen and Shieldbearers fight Rotters and Grave Knights.

Confirm units engage correct targets and the frontline behaves sensibly.

**Test B — Basic aerial combat**

Dwarven Flying Machines engage Carrion Bats and Plague Shriekers.

Confirm aircraft movement, targeting, damage, and death.

**Test C — Air-to-ground attack**

Bombard Gyro attacks an exposed undead ground formation.

Confirm actual damage, targeting eligibility, bombing behavior, and rearming or recovery.

**Test D — Ground-to-air attack**

Flak Crew engages undead flying units.

Confirm it does not incorrectly target ordinary ground zombies.

**Test E — Combined-arms battle**

Infantry, artillery, a steam tank, a walker, and Flying Machines fight a mixed ground-air undead force.

Confirm both fronts stay operational simultaneously.

**Test F — Mechanical repair**

Field Mechanic repairs an eligible damaged vehicle or mech.

Confirm repair limits, range, and targeting.

**Test G — Boss encounter**

Stage 010 boss fights with supporting enemies.

Verify support spawn intervals, combat transitions, death, and victory conditions.

**Test H — Economy**

Verify all deployed units correctly consume Gold, Steam Pressure behaves correctly, and resources cannot become invalid or negative through deployment.

**Test I — Save persistence**

Clear a stage, earn an unlock, restart the game, and verify progression remains intact.

**Test J — Stress testing**

Spawn a large combined ground and aerial engagement.

Check for crashes, severe frame stalls, stuck units, invalid targets, projectiles continuing after invalid targets, and excessive effect accumulation.

---

# 15. DEVELOPMENT QUALITY STANDARDS

Every implemented unit must have a genuine role.

Do not make multiple units differ only by name and color.

Do not silently remove units to simplify development.

Do not generate hundreds of fake functional entries whose assets and behavior are nonexistent.

Do not fill stages with randomly selected enemies without considering challenge design.

Do not use copyrighted game sprites or extracted assets from Warcraft, Dota, or other games.

Do not use static primitive placeholders as though they are completed character artwork.

Do not introduce controllable hero systems.

Do not split land and air into separate game modes.

Do not implement separate disconnected economies for each combat front.

Do not make the air war optional background decoration.

Do not add excessive stage announcements or tactical handholding.

Do not claim tests passed unless they were actually executed.

Maintain consistent naming, modular scripts, and working references.

---

# 16. M001 COMPLETION REQUIREMENTS

Before delivering the first build:

1. Confirm that the project loads in Godot without syntax or resource errors.
2. Run available headless scene-loading and script-parsing checks.
3. Verify all M001 units appear correctly and can perform their assigned combat actions.
4. Verify the first 15 stages can be entered, played, won, and lost.
5. Verify simultaneous air-ground combat.
6. Verify playable unit targeting and enemy targeting.
7. Verify progression saves and loads.
8. Verify that main menus and battle interfaces respond correctly.
9. Test representative heavy combat scenes for obvious performance failures.
10. Check for missing textures, invisible units, broken references, bad spawn locations, stuck aircraft, and invalid animations.
11. Provide an accurate implementation report listing completed features, tested features, limitations, and remaining work.
12. Preserve the complete long-term roster, technology, boss, and campaign specifications for later milestones.

If the environment supports packaging, deliver a complete Godot source project ZIP with an intact project.godot file, required scripts, scenes, resources, assets, and necessary documentation.

If Android export tooling is available, generate and test an Android build. Otherwise, provide a valid export configuration and accurately document what remains necessary for APK generation.

Do not claim that an APK or export has been tested if it has not.

---

# 17. LONG-TERM DEVELOPMENT ROADMAP

**M001 — The First Flame:** Original game foundation, art identity, core systems, 18 functional dwarves, 14 functional undead, first boss, 15 stages.

**M002 — The Blackpowder Age:** Expand infantry, basic artillery, and early economic progression.

**M003 — The Iron Road:** Introduce a broader collection of armored vehicles and tanks.

**M004 — Walking Mountains:** Expand mechanical walkers, siege mechs, and their unique combat systems.

**M005 — War Above the Clouds:** Expand aerial warfare with advanced flyers, bombers, and gunships.

**M006 — The Skyforge Armada:** Develop the full airship and flying-fortress systems.

**M007 — The Growing Dead:** Expand undead enemies, boss mechanics, corruption, and cross-front counterplay.

**M008 onward:** Continue toward the complete roster, campaign, final artwork, soundtrack, balancing, performance optimization, and full release.

These milestone names are planning labels, not permission to reduce M001's mandatory functionality.

---

# 18. FINAL DESIGN IDENTITY

Dwarves vs Zombies must feel like an entire civilization unleashing its industrial ingenuity against an endless necromantic invasion.

The dwarves should be charming and absurdly overconfident in their technology.

The undead should remain terrifying and relentless.

Combat must feel powerful, chaotic, readable, and strategically meaningful.

A player's basic Riflemen should still have a tactical purpose even after gigantic Colossi and floating battleships become available.

The sky must be a real battlefield, not merely a backdrop.

Mechs, tanks, infantry, artillery, Flying Machines, and airships must operate together as one integrated army.

The final experience should feel distinct from a conventional ground-only tug-of-war game.

**The defining fantasy:**

A dwarven infantry line desperately holds against thousands of undead as artillery thunders from the rear. Flying Machines intercept skeletal beasts above the battlefield. Steam tanks advance through the horde. Enormous mechanical walkers emerge from the smoke, and an armored dwarven airship appears overhead, unleashing its broadside cannons against the undead stronghold.

All these elements belong to the same continuous battle, driven by the player's unit deployment and strategic decisions.

**One Kingdom. One Great Forge. Two Fronts. No Heroes.**

Begin by creating a maintainable, playable, visually coherent M001 foundation, and accurately distinguish implemented features from the larger planned game.
