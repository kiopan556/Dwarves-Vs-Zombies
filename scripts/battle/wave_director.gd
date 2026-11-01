class_name WaveDirector
extends RefCounted
## Enemy wave director: authored spawn tracks (with ramping intervals), timed events,
## citadel-damage triggers, static structures, boss arrival, environmental hazards and
## late-battle escalation. Deterministic per stage (seeded RNG) so stages replay consistently.

var battle
var st: Dictionary
var rng := RandomNumberGenerator.new()
var tracks: Array = []
var events_done: Dictionary = {}
var triggers_done: Dictionary = {}
var boss_spawned := false
var boss = null
var hazard: Dictionary = {}          # first hazard (kept for older callers)
var hazards: Array = []               # M005: a stage may carry several hazards (e.g. bog + miasma)
var hazard_ts: Array = []
var hazard_t := 0.0
var gale_left := 0.0
var hazard_boost := 1.0               # M005: boss phases can intensify hazards (Plague Regent: thicker miasma)
var storm_boost := 1.0                # M006: Dread Sky Tyrant phase: lightning strikes come faster
var spawned_total := 0
var enabled := true


func setup(b, stage_def: Dictionary) -> void:
	battle = b
	st = stage_def
	rng.seed = int(st.get("seed", 1))
	for tr in st.get("tracks", []):
		tracks.append({"d": tr, "next": float(tr.start), "interval": float(tr.interval), "count": 0})
	hazards = hazard_list(st)
	hazard = hazards[0] if not hazards.is_empty() else {}
	for h in hazards:
		hazard_ts.append(float(h.get("interval", 9999)) * 0.7)
		if String(h.get("kind", "")) == "bog":
			battle.set_bog(h)
		if String(h.get("kind", "")) == "thermals":
			battle.set_thermals(h)
		match String(h.get("kind", "")):   # M007 foundry hazards: set up once, run by Foundry every step
			"furnace_vents":
				Foundry.set_vents(battle, h)
			"slag_flow":
				Foundry.set_slag(battle, h)
			"steam_leak":
				Foundry.set_steam(battle, h)
	hazard_t = hazard_ts[0] if not hazard_ts.is_empty() else 0.0
	for s in st.get("structures", []):
		battle.spawn_unit(s.enemy, 1, Vector2(float(s.x), 0), true)


func escalation(time: float) -> float:
	# mild late pressure so a passive player can't stall forever, without locking a pushing army out
	if time > 300.0:
		return 0.85
	if time > 180.0:
		return 0.93
	return 1.0


func step(dt: float, time: float) -> void:
	if not enabled:
		return
	var alive: int = battle.alive_count(1)
	var cap = int(st.get("max_alive", 40))
	var esc = escalation(time)
	for tr in tracks:
		var d: Dictionary = tr.d
		if float(d.get("until", -1)) > 0.0 and time > float(d.until):
			continue
		if time >= tr.next:
			if alive >= cap:
				tr.next = time + 1.5
				continue
			if battle.air_alive(1) >= Battle.AIR_CAP and Registry.entry(String(d.enemy)).get("domain", "ground") == "air":
				tr.next = time + 1.5     # M006 air budget: flyer tracks wait for room in the sky
				continue
			_spawn_group(d.enemy, int(d.group))
			alive += int(d.group)
			tr.count += 1
			tr.interval = maxf(float(d.interval_min), tr.interval * float(d.get("ramp", 0.97)))
			tr.next = time + tr.interval * esc * rng.randf_range(0.85, 1.15)
	var evs: Array = st.get("events", [])
	for i in evs.size():
		if not events_done.has(i) and time >= float(evs[i].t):
			events_done[i] = true
			for grp in evs[i].spawn:
				_spawn_group(grp[0], int(grp[1]))
	var trg: Array = st.get("triggers", [])
	var frac: float = battle.enemy_base.hp / battle.enemy_base.max_hp if battle.enemy_base != null else 1.0
	for i in trg.size():
		if not triggers_done.has(i) and frac <= float(trg[i].hp_below):
			triggers_done[i] = true
			for grp in trg[i].spawn:
				_spawn_group(grp[0], int(grp[1]))
	var bs = st.get("boss_spawn")
	if bs != null and not boss_spawned and time >= float(bs.t):
		boss_spawned = true
		boss = battle.spawn_unit(bs.id, 1, Vector2(Combat.UNDEAD_BASE_X - 140.0, 0), true)
		battle.on_boss_spawned(boss)
	_hazards(dt)


func _spawn_group(enemy: String, n: int) -> void:
	for i in n:
		var x = Combat.UNDEAD_BASE_X - 70.0 - float(i) * 18.0 - rng.randf() * 10.0
		var u = battle.spawn_unit(enemy, 1, Vector2(x, 0), true)
		if u != null:
			spawned_total += 1


## A stage's hazards as a list (the data may hold one dict, a list of dicts, or nothing).
static func hazard_list(stage_def: Dictionary) -> Array:
	var h = stage_def.get("hazard")
	if h == null:
		return []
	if h is Array:
		return h.filter(func(x): return x is Dictionary and not x.is_empty())
	return [h] if (h is Dictionary and not h.is_empty()) else []


func _hazards(dt: float) -> void:
	for i in hazards.size():
		hazard = hazards[i]
		hazard_t = hazard_ts[i]
		_hazard_one(dt)
		hazard_ts[i] = hazard_t
	if not hazards.is_empty():
		hazard = hazards[0]


func _hazard_one(dt: float) -> void:
	var hk = String(hazard.get("kind", ""))
	hazard_t += dt * (hazard_boost if hk == "miasma" else (storm_boost if hk == "lightning_storm" else 1.0))
	match hazard.get("kind", ""):
		"miasma":
			# drifting poison clouds, right to left; Battle ticks their damage (organic ground units, both sides)
			if hazard_t >= float(hazard.interval):
				hazard_t = 0.0
				var x = rng.randf_range(Combat.UNDEAD_BASE_X - 260.0, Combat.UNDEAD_BASE_X - 120.0)
				battle.add_miasma(x, float(hazard.radius) * (1.0 + (hazard_boost - 1.0) * 0.35), float(hazard.dps) * hazard_boost, float(hazard.duration), float(hazard.speed))
		"bog", "thermals", "furnace_vents", "slag_flow", "steam_leak":
			pass   # static mire patches / thermal columns: set up once, applied by Battle every step
		"lightning_storm":
			if hazard_t >= float(hazard.interval):
				hazard_t = 0.0
				battle.lightning_strike(float(hazard.damage), float(hazard.radius), float(hazard.get("warn", 0.8)))
		"rockfall":
			if hazard_t >= float(hazard.interval):
				hazard_t = 0.0
				var x = rng.randf_range(520.0, 2050.0)
				battle.schedule_rockfall(x, float(hazard.get("damage", 40)), float(hazard.get("radius", 55)), float(hazard.get("warn", 1.4)), String(hazard.get("variant", "")))
		"gale":
			if gale_left > 0.0:
				gale_left -= dt
				battle.gust_x = -float(hazard.get("strength", 45)) * clampf(gale_left, 0.0, 1.0)
				if gale_left <= 0.0:
					battle.gust_x = 0.0
			elif hazard_t >= float(hazard.interval):
				hazard_t = 0.0
				gale_left = float(hazard.get("duration", 7))
