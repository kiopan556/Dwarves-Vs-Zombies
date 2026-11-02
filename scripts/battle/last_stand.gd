class_name LastStand
extends WaveDirector
## M008 Last Stand: an endless survival mode. The undead citadel is sealed for good; the battle ends only when the
## dwarven stronghold falls. Waves are composed from the stage toolkit's encounter shapes (a melee screen, a ranged
## line that always stops, a sky raid, a monster breakthrough, siege pieces) out of the arena's act roster, with a
## rising threat budget; every 10th wave brings a boss the player has already defeated. Gold income scales with the
## wave, Steam is as normal. Same `max_alive` and flyer caps as the campaign.
## Score = 100 per wave survived + 1 per undead destroyed; the best per arena is kept locally. Rewards are cosmetic
## banners and titles at wave milestones - never Sparks (no farming exploit).

const ARENAS := [
	{"id": "stonehelm_gate", "name": "Stonehelm Gate", "env": "mountain_gate", "act": 1, "needs": "s060",
		"tag": "The old gate road. The first place the dead ever came, and the last place they will be allowed through."},
	{"id": "blighted_verge", "name": "The Blighted Verge", "env": "dead_forest", "act": 2, "needs": "s060",
		"tag": "Dead oaks and plague fog. Hold the forest edge against everything the marshes send."},
	{"id": "cloudbreak", "name": "Cloudbreak Plains", "env": "open_plains", "act": 3, "needs": "s060",
		"tag": "Open grass under an open sky: the dead come by land and by air, and there is nowhere to hide."},
	{"id": "cinder_canal", "name": "Cinder Canal", "env": "industrial_city", "act": 4, "needs": "s090",
		"tag": "A foundry canal in the dead city. Corrupted iron rolls down the cobbles toward your guns."},
]
const MILESTONES := [
	{"wave": 10, "kind": "banners", "id": "last_stand_bronze"},
	{"wave": 20, "kind": "banners", "id": "last_stand_silver"},
	{"wave": 30, "kind": "banners", "id": "last_stand_gold"},
	{"wave": 40, "kind": "titles", "id": "the_unbroken"},
	{"wave": 50, "kind": "titles", "id": "warden_of_the_last_light"},
]
const WAVE_SPAWN := 34.0     # seconds over which a wave's set pieces arrive
const WAVE_GAP := 14.0       # breather after a wave is cleared (or the longest wait)
const WAVE_MAX_WAIT := 70.0

var wave := 0
var wave_t := 0.0
var state := "gap"          # gap | spawning | fighting
var queue: Array = []       # [t, enemy, n] for the current wave
var pools: Dictionary = {}  # role -> [enemy ids]
var bosses: Array = []
var wave_units: Array = []
var stats_bosses := 0


static func arena(id: String) -> Dictionary:
	for a in ARENAS:
		if a.id == id:
			return a
	return ARENAS[0]


static func arena_open(a: Dictionary) -> bool:
	return GameState.is_cleared(String(a.needs)) or GameState.rift_sealed()


## The battle stage definition for an arena (the director builds the waves itself).
static func stage_def(id: String) -> Dictionary:
	var a = arena(id)
	return {"id": "ls_" + String(a.id), "index": 0, "act": int(a.act), "name": "Last Stand · " + String(a.name), "env": String(a.env),
		"tagline": String(a.tag), "start_gold": 420, "gold_rate": 11.0, "enemy_base_hp": 99999, "enemy_hp_mult": 1.0,
		"max_alive": 56, "seed": 8080 + hash(String(a.id)) % 1000, "tracks": [], "events": [], "triggers": [], "structures": [],
		"last_stand": String(a.id), "implemented": true, "challenge": {}, "rewards": {}}


func setup(b, stage_def: Dictionary) -> void:
	battle = b
	st = stage_def
	rng.seed = int(st.get("seed", 1))
	battle.citadel_sealed = true   # the citadel cannot fall: survive
	battle.enemy_base.special = 1.0
	battle.last_stand = {"arena": String(st.get("last_stand", "")), "wave": 0, "score": 0}
	_build_pools(int(st.get("act", 1)))
	wave_t = 6.0


## Enemy pools by role from every enemy the arena's act fields (plus earlier acts' staples).
func _build_pools(act: int) -> void:
	pools = {"melee": [], "ranged": [], "air": [], "monster": [], "siege": []}
	for s in Registry.stages:
		if not s.get("implemented", false) or int(s.get("act", 1)) > act or int(s.get("act", 1)) < act - 1:
			continue
		for e in s.get("enemy_roster", []):
			var d = Registry.combat_def(e)
			if d.is_empty() or d.get("static", false) or d.get("cls", "") == "structure":
				continue
			var role = "melee"
			if d.get("domain", "ground") == "air":
				role = "air" if d.get("cls", "") != "airship" else "monster"
			elif d.get("behavior", "") in ["giant"] or float(d.get("threat", 1)) >= 9.0:
				role = "monster"
			elif d.get("behavior", "") == "artillery":
				role = "siege"
			elif d.get("hold_behind", false) or d.get("behavior", "") in ["ranged", "necromancer", "repair"]:
				role = "ranged"
			if d.get("reclaims", false):
				continue   # corruptors need wrecks (Act IV only)
			if not e in pools[role]:
				pools[role].append(e)
	for k in pools.keys():
		pools[k].sort()
		if pools[k].is_empty():
			pools[k] = pools.melee.duplicate() if k != "air" else ["carrion_bat"]
	# bosses the player has defeated (cleared boss stages), in campaign order
	bosses.clear()
	for s2 in Registry.stages:
		if s2.get("boss") != null and GameState.is_cleared(String(s2.id)):
			bosses.append(String(s2.boss))
	if bosses.is_empty():
		bosses = ["mine_maw"]


func budget(n: int) -> float:
	return 26.0 + 13.0 * n + 0.35 * n * n


func step(dt: float, time: float) -> void:
	if not enabled:
		return
	battle.citadel_sealed = true
	match state:
		"gap":
			wave_t -= dt
			if wave_t <= 0.0:
				_start_wave()
		"spawning":
			wave_t += dt
			var keep: Array = []
			for q in queue:
				if wave_t >= float(q[0]):
					_spawn_ls(String(q[1]), int(q[2]))
				else:
					keep.append(q)
			queue = keep
			if queue.is_empty():
				state = "fighting"
				wave_t = 0.0
		"fighting":
			wave_t += dt
			var left = 0
			for u in wave_units:
				if is_instance_valid(u) and u.alive:
					left += 1
			if left <= 2 or wave_t > WAVE_MAX_WAIT:
				_end_wave()
	_hazards(dt)


func _start_wave() -> void:
	wave += 1
	state = "spawning"
	wave_t = 0.0
	wave_units.clear()
	battle.last_stand.wave = wave
	battle.enemy_hp_mult = 1.0 + 0.05 * float(wave - 1)
	battle.gold_rate = float(st.get("gold_rate", 11.0)) + 0.55 * float(wave)
	queue = compose_wave(wave)
	battle.alert.emit("Wave %d" % wave if wave % 10 != 0 else "Wave %d — a lord of the dead comes!" % wave)
	Audio.play("wave_horn", -1.0, -2.0, 0.0)


## The wave's spawn schedule: [[t, enemy, n], ...] - deterministic for (arena seed, wave).
func compose_wave(n: int) -> Array:
	var r = RandomNumberGenerator.new()
	r.seed = int(st.get("seed", 1)) * 131 + n * 7919
	var b = budget(n)
	var out: Array = []
	var mel: Array = pools.melee
	var rng_p: Array = pools.ranged
	var air: Array = pools.air
	var mon: Array = pools.monster
	var sie: Array = pools.siege
	# melee screen: a third of the budget, in groups
	var m1 = String(mel[r.randi() % mel.size()])
	var m2 = String(mel[r.randi() % mel.size()])
	var spent = 0.0
	var t = 0.0
	while spent < b * 0.38:
		var e = m1 if r.randf() < 0.6 else m2
		var g = 2 + (r.randi() % 3)
		out.append([t, e, g])
		spent += _thr(e) * g
		t += r.randf_range(2.5, 5.0)
	# ranged line (always ends with the wave)
	var rg = String(rng_p[r.randi() % rng_p.size()])
	for k in 1 + n / 6:
		out.append([6.0 + k * 7.0, rg, 1 + (1 if n > 8 else 0)])
		spent += _thr(rg) * 2
	# sky raid: most waves
	if n % 3 != 1 or n > 6:
		var a1 = String(air[r.randi() % air.size()])
		out.append([r.randf_range(8.0, 18.0), a1, 2 + n / 5])
		spent += _thr(a1) * (2 + n / 5)
	# monster breakthrough every third wave (and more often later)
	if n % 3 == 0 or (n > 12 and n % 2 == 0):
		var mo = String(mon[r.randi() % mon.size()])
		out.append([r.randf_range(14.0, 26.0), mo, 1 + (1 if n > 20 else 0)])
		spent += _thr(mo)
	# siege pieces from wave 5
	if n >= 5 and n % 2 == 1:
		var sg = String(sie[r.randi() % sie.size()])
		out.append([r.randf_range(10.0, 20.0), sg, 1])
	# fill the rest of the budget with the melee screen
	while spent < b:
		var e2 = m1 if r.randf() < 0.5 else m2
		out.append([r.randf_range(4.0, WAVE_SPAWN), e2, 2])
		spent += _thr(e2) * 2
	if n % 10 == 0:
		out.append([WAVE_SPAWN * 0.5, "@boss", 1])
	out.sort_custom(func(x, y): return float(x[0]) < float(y[0]))
	return out


func _thr(e: String) -> float:
	return maxf(1.0, float(Registry.combat_def(e).get("threat", 2.0)))


func _spawn_ls(enemy: String, n: int) -> void:
	if enemy == "@boss":
		var bid = bosses[(wave / 10 - 1) % bosses.size()]
		var bu = battle.spawn_unit(bid, 1, Vector2(Combat.UNDEAD_BASE_X - 140.0, 0), true)
		if bu != null:
			# a Last Stand lord keeps its tuned campaign HP, growing a little with each appearance
			bu.max_hp = bu.max_hp * (0.6 + 0.12 * float(wave / 10))
			bu.hp = bu.max_hp
			wave_units.append(bu)
			stats_bosses += 1
			battle.on_boss_spawned(bu)
			battle.citadel_sealed = true
		return
	for i in n:
		if battle.alive_count(1) >= int(st.get("max_alive", 56)):
			return
		var x = Combat.UNDEAD_BASE_X - 70.0 - float(i) * 18.0 - rng.randf() * 10.0
		var u = battle.spawn_unit(enemy, 1, Vector2(x, 0), true)
		if u != null:
			spawned_total += 1
			wave_units.append(u)


func _end_wave() -> void:
	state = "gap"
	wave_t = WAVE_GAP
	battle.last_stand.score = score()
	battle.alert.emit("Wave %d held!" % wave)
	# keep the citadel sealed even after a boss falls (Battle.on_boss_died unseals it)
	battle.citadel_sealed = true


## Waves survived count only the waves fully held.
func waves_survived() -> int:
	return maxi(0, wave - (1 if state != "gap" else 0))


func score() -> int:
	return waves_survived() * 100 + int(battle.stats_kills)
