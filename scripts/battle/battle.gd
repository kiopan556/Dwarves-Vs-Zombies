class_name Battle
extends Node2D
## Central battle controller: owns units, spatial buckets, economy, deployment, damage
## resolution, projectiles, effects, wave director, hazards and victory/defeat.
## Logic runs in step(dt) so the same battle can be simulated headless by the test runner.

signal ended(won: bool)
signal alert(text: String)
signal boss_appeared(unit)
signal deployed(unit_id: String)
signal enemy_first_seen(unit_id: String)    # M005: once per enemy type per battle (first-encounter hints)

const DWARF_CAP := 70
const UNDEAD_CAP := 90
const MINE_COSTS := [120, 200, 300, 420]
const MINE_BONUS := 2.6
const STEAM_MAX := 100.0
const STEAM_RATE := 2.0
const OVERDRIVE_COST := 40.0
const OVERDRIVE_TIME := 8.0
const OVERDRIVE_CD := 25.0
const VENT_COST := 60.0
const VENT_CD := 40.0
const VENT_RADIUS := 360.0
const VENT_DAMAGE := 70.0

var rng := RandomNumberGenerator.new()
var stage: Dictionary = {}
var sandbox := false
var time := 0.0
var over := false
var won := false
var paused := false

var units_node: Node2D
var projectiles: ProjectileLayer
var fx: FxLayer
var bars: BarsLayer
var director: WaveDirector
var background: Node2D

var units: Array = []
var by_side: Array = [[], []]
var buckets: Array = []                 # [side][bucket] -> Array[Unit]
var corpses: Array = []                 # {pos, t}
var dwarf_base: Unit
var enemy_base: Unit
var boss = null
var citadel_sealed := false

# economy
var gold := 150.0
var gold_rate := 9.0
var steam := 20.0
var mine_level := 0
var loadout: Array = []
var cooldowns: Dictionary = {}
var overdrive_cd := 0.0
var vent_cd := 0.0
var infinite_gold := false
var invulnerable_bases := false
var enemy_hp_mult := 1.0

# spotting / hazards
var spotting_active := false
var spot_range_mult := 1.2
var spot_dmg_mult := 1.15
var spotters: Array = []
var gust_x := 0.0
var rockfalls: Array = []

# presentation
var view_rect: Rect2 = Rect2()
var shake_amount := 0.0
var debug_targets := false
var show_all_bars := false
var _serial := 0
var _sound_t: Dictionary = {}
var _base_alert_t := -99.0

# stats
var stats_kills := 0
var stats_losses := 0
var stats_deployed := 0
var stats_repaired := 0.0
var stats_spent_gold := 0.0
var stats_dmg := [0.0, 0.0]
var death_log: Dictionary = {}

# M002 war-frame systems
const ZONE_CAP := 12
const REPAIR_CAP_PER_SEC := 34.0       # max HP/s any single machine can receive from all crews
const WARD_CAP := 8
var mech_doctrine := "standard"      # conserve | standard | overdrive (army-wide Machinery Doctrine)
var zones: Array = []                # bounded burning zones {pos, r, dps, t, side, tick, src}
var wards: Array = []                # projectile wards {owner, x, r, mult, t, side}
var projectile_ctx := false          # true while resolving projectile impacts (wards / shield facing)
var projectile_src_x := 0.0
var _ability_gap := 0.0
var _giant_gap := 0.0
var profiling := false
var prof := {}
var stats_giant_abilities := 0
var stats_summoned := 0
var stats_rallied := 0
var stats_ability_uses := 0
var stats_ability_steam := 0.0
var stats_pellet_shots := 0
var stats_pellet_hits := 0
var stats_pellet_violations := 0
var stats_chain_max := 0
var stats_salvos := 0
var stats_zone_ticks := 0
var stats_ward_blocks := 0

# ---- M005: hazards, delayed strikes, challenge objectives
const MIASMA_CAP := 6
var miasma_clouds: Array = []        # {x, r, dps, t, dur, speed, tick, seed}
var bog_spots: Array = []            # {x, w, slow}
var strikes: Array = []              # telegraphed delayed strikes {x, r, dmg, t, delay, hit_side, slow, look}
var hazard_layer: HazardLayer
var stats_miasma := [0.0, 0.0]       # damage dealt by miasma to [dwarves, undead]
var stats_miasma_hits: Dictionary = {}   # unit id -> ticks taken (tests)
var stats_bog_slowed := 0
var _bog_sound_t := 0.0
var min_base_frac := 1.0
var air_losses := 0
var deploy_types: Dictionary = {}
var structures_total := 0
var structures_killed := 0
var boss_arrive_t := -1.0
var boss_kill_t := -1.0
var _seen: Dictionary = {}

# ---- M006: air war (altitude bands, flyer budget, escort), thermals and lightning
const CORRUPTED_IDS := ["risen_copperback", "gravegun_tank", "cursed_ironclad", "possessed_drillwalker", "haunted_flying_machine", "infected_airbarge", "fallen_titan"]
const AIR_CAP := 24                  # alive undead flyers, independent of the stage's max_alive
var stats_air_capped := 0
var stats_air_peak := 0
var escort_unit = null
var escort_state := "none"           # none | pending | flying | delivered | lost
var thermals: Array = []             # {x, dir, w}
var stats_thermal_ticks := 0
var bolts: Array = []                # lightning: {x, target, t, warn, dmg, r, struck, y}
var lightning_air_bias := 0.0        # Dread Sky Tyrant phase: chance a strike seeks a dwarven aircraft
var stats_lightning := 0
var stats_lightning_hits := [0, 0]   # units struck on [dwarf, undead] side
var stats_lightning_kinds: Dictionary = {}
var flash_t := 0.0
var _fx_rng := RandomNumberGenerator.new()   # M006: cosmetic timing only, so presentation never shifts the gameplay RNG
# ---- M007 Act IV: wreck reclamation and foundry hazards (logic in Foundry)
var wrecks: Array = []               # {unit, x, kind, gold, t, chan, chan_t, sal, sal_t, id, serial}
var sandbox_wrecks_off := false
var vents: Array = []                # furnace vents {x, next, glow}
var vent_def: Dictionary = {}
var eruptions: Array = []            # telegraphed fire bursts {x, r, dmg, t, warn, hit, src}
var slag: Dictionary = {}            # slag flow state
var steam_pipes: Array = []          # steam leaks {x, r, dps, regen, tick, fed}
var heroic := false                  # M007 Heroic difficulty (smarter, not bigger)
var _reclaim_alert_t := -99.0
var stats_wrecks := 0
var stats_reclaimed := 0
var stats_reclaimed_ids: Array = []
var stats_salvaged := 0
var stats_salvage_gold := 0.0
var stats_channels := 0
var stats_wreck_expired := 0
var stats_vent_bursts := 0
var stats_vent_dmg := [0.0, 0.0]
var stats_slag_flows := 0
var stats_slag_dmg := [0.0, 0.0]
var stats_slag_hits := [0, 0]
var stats_steam_dmg := [0.0, 0.0]
var stats_steam_gained := 0.0
var stats_gantries := 0
var stats_corpse_throws := 0
var stats_titan_reclaims := 0
var stats_vent_sweeps := 0
var corpse_throws: Array = []        # Corpse Colossus: {x0, y0, x1, t, dur, dmg}
var stats_corpse_hits := 0


func _ready() -> void:
	pass


func setup(stage_def: Dictionary, loadout_ids: Array, opts: Dictionary = {}) -> void:
	stage = stage_def
	sandbox = opts.get("sandbox", false)
	rng.seed = int(opts.get("seed", stage.get("seed", 12345)))
	var low: bool = opts.get("low", false)
	background = BattleBackground.new()
	background.env = stage.get("env", "mountain_gate")
	background.storm = WaveDirector.hazard_list(stage).any(func(h): return String(h.get("kind", "")) == "lightning_storm")
	add_child(background)
	units_node = Node2D.new()
	units_node.name = "Units"
	add_child(units_node)
	projectiles = ProjectileLayer.new()
	add_child(projectiles)
	projectiles.setup(self, 160 if low else 260)
	fx = FxLayer.new()
	add_child(fx)
	fx.setup(self, low)
	bars = BarsLayer.new()
	bars.battle = self
	add_child(bars)
	hazard_layer = HazardLayer.new()
	add_child(hazard_layer)
	hazard_layer.setup(self)
	buckets = [[], []]
	var nb = int(ceil(Combat.WORLD_W / Combat.BUCKET)) + 1
	for s in 2:
		for i in nb:
			buckets[s].append([])
	loadout = loadout_ids.filter(func(x): return x != "" and Registry.is_implemented(x))
	for uid in loadout:
		cooldowns[uid] = 0.0
	enemy_hp_mult = float(stage.get("enemy_hp_mult", 1.0))
	heroic = bool(stage.get("heroic_mode", false))
	gold = float(stage.get("start_gold", 150))
	if is_instance_valid(GameState) and not GameState.profile.is_empty():
		mech_doctrine = String(GameState.profile.settings.get("mech_doctrine", "standard"))
	gold_rate = float(stage.get("gold_rate", 9.0))
	steam = 20.0
	dwarf_base = spawn_unit("dwarf_stronghold", 0, Vector2(Combat.DWARF_BASE_X, 0), true)
	enemy_base = spawn_unit("undead_citadel", 1, Vector2(Combat.UNDEAD_BASE_X, 0), true)
	if stage.has("enemy_base_hp"):
		enemy_base.max_hp = float(stage.enemy_base_hp)
		enemy_base.hp = enemy_base.max_hp
	if not sandbox and not opts.get("no_director", false):
		director = WaveDirector.new()
		director.setup(self, stage)


# =============================================================== spawning & deployment
func spawn_unit(uid: String, side: int, pos: Vector2, free: bool = true) -> Unit:
	var d = Registry.combat_def(uid)
	if d.is_empty():
		push_warning("spawn_unit: no combat definition for " + uid)
		return null
	if not free and by_side[side].size() >= (DWARF_CAP if side == 0 else UNDEAD_CAP):
		return null
	if side == 1 and alive_count(1) >= UNDEAD_CAP and d.get("cls", "") != "stronghold" and d.get("cls", "") != "boss":
		return null
	if side == 1 and d.get("domain", "ground") == "air" and d.get("cls", "") != "boss" and air_alive(1) >= AIR_CAP:
		stats_air_capped += 1
		return null
	var u = Unit.new()
	_serial += 1
	u.serial = _serial
	if pos.y == 0.0:
		pos.y = Combat.GROUND_Y
	u.setup(self, d, side, pos)
	units_node.add_child(u)
	units.append(u)
	by_side[side].append(u)
	if side == 1 and is_instance_valid(GameState) and not sandbox:
		GameState.note_encountered(uid)
	if side == 1 and not u.is_stronghold:
		if u.is_structure or u.is_static:
			structures_total += 1
		if not _seen.has(uid):
			_seen[uid] = true
			enemy_first_seen.emit(uid)
	return u


## Returns "" on success, otherwise the reason deployment failed. Never lets resources go negative.
func can_deploy(uid: String) -> String:
	if over:
		return "Battle over"
	if not uid in loadout:
		return "Not in loadout"
	var d = Registry.combat_def(_deploy_def_id(uid))
	if d.is_empty():
		return "Not implemented"
	if cooldowns.get(uid, 0.0) > 0.0:
		return "Cooling down"
	var g = float(d.get("gold", 0))
	var s = float(d.get("steam", 0))
	if not infinite_gold and gold < g:
		return "Need %d Gold" % int(g)
	if not infinite_gold and steam < s:
		return "Need %d Steam" % int(s)
	if alive_count(0) >= DWARF_CAP:
		return "Army at capacity"
	return ""


func deploy(uid: String) -> Unit:
	if can_deploy(uid) != "":
		return null
	var did = _deploy_def_id(uid)
	var d = Registry.combat_def(did)
	var pos = Vector2(Combat.DWARF_BASE_X + Combat.BASE_FACE + 10.0, 0)
	if d.get("domain", "ground") == "air":
		pos = Vector2(Combat.DWARF_BASE_X + 30.0, 330.0)
	var u = spawn_unit(did, 0, pos, false)
	if u == null:
		return null
	if not infinite_gold:
		gold = maxf(0.0, gold - float(d.get("gold", 0)))
		steam = maxf(0.0, steam - float(d.get("steam", 0)))
	stats_spent_gold += float(d.get("gold", 0))
	cooldowns[uid] = float(d.get("cooldown", 5))
	stats_deployed += 1
	deploy_types[uid] = true
	Audio.play("deploy", pos.x, -4.0)
	if rng.randf() < 0.5:
		Audio.play("dwarf_voice", pos.x, -6.0, 0.2)
	deployed.emit(uid)
	return u


func mine_upgrade_cost() -> int:
	return MINE_COSTS[mine_level] if mine_level < MINE_COSTS.size() else -1


func upgrade_mine() -> bool:
	var c = mine_upgrade_cost()
	if c < 0 or gold < c or over:
		return false
	gold -= c
	mine_level += 1
	Audio.play("mine_upgrade", Combat.DWARF_BASE_X, -4.0)
	return true


func can_overdrive() -> bool:
	return steam >= OVERDRIVE_COST and overdrive_cd <= 0.0 and not over


func overdrive() -> bool:
	if not can_overdrive():
		return false
	steam -= OVERDRIVE_COST
	overdrive_cd = OVERDRIVE_CD
	for u in by_side[0]:
		if u.alive and u.cls in ["vehicle", "walker", "airship", "artillery"]:
			u.overdrive_t = OVERDRIVE_TIME
			fx.puff(u.position + Vector2(0, -40), Color(1, 1, 1, 0.5))
	Audio.play("steam", view_rect.get_center().x, 0.0)
	return true


func can_vent() -> bool:
	return steam >= VENT_COST and vent_cd <= 0.0 and not over


## Emergency Pressure Release: scalding steam blast in front of the stronghold.
func steam_vent() -> bool:
	if not can_vent():
		return false
	steam -= VENT_COST
	vent_cd = VENT_CD
	var p = Vector2(Combat.DWARF_BASE_X + Combat.BASE_FACE, Combat.GROUND_Y - 30.0)
	for e in query(Vector2(p.x + VENT_RADIUS * 0.5, Combat.GROUND_Y), VENT_RADIUS * 0.55, 1, "ground_lowair"):
		damage(e, VENT_DAMAGE, "fire", dwarf_base, false, {})
	fx.steam_vent(p + Vector2(80, 0), VENT_RADIUS)
	Audio.play("steam", p.x, 4.0)
	shake(4.0)
	return true


# =============================================================== main loop
func step(dt: float) -> void:
	if paused:
		return
	if over:
		fx.step(dt)
		projectiles.step(dt)
		for u in units:
			if not u.alive:
				u.step(dt)
		_cleanup()
		return
	time += dt
	# economy
	var g = gold_rate + MINE_BONUS * mine_level
	for u in by_side[0]:
		if u.alive and u.def.has("prospect"):
			g += float(u.def.prospect)
	gold = minf(9999.0, gold + g * dt)
	steam = minf(STEAM_MAX, steam + STEAM_RATE * dt)
	for k in cooldowns.keys():
		cooldowns[k] = maxf(0.0, cooldowns[k] - dt)
	overdrive_cd = maxf(0.0, overdrive_cd - dt)
	vent_cd = maxf(0.0, vent_cd - dt)
	# spotting
	spotters.clear()
	for u in by_side[0]:
		if u.alive and u.def.has("spotter"):
			spotters.append(u)
	spotting_active = not spotters.is_empty()
	if spotting_active:
		var sp: Dictionary = spotters[0].def.spotter
		spot_range_mult = float(sp.get("art_range", 1.2))
		spot_dmg_mult = float(sp.get("art_dmg", 1.15))
	var _p0 = Time.get_ticks_usec() if profiling else 0
	_rebuild_buckets()
	if director != null:
		director.step(dt, time)
	_arbitrate_abilities(dt)
	_giant_abilities(dt)
	var _p1 = Time.get_ticks_usec() if profiling else 0
	for i in units.size():
		var u: Unit = units[i]
		u.step(dt)
	var _p2 = Time.get_ticks_usec() if profiling else 0
	_tick_zones(dt)
	_resolve_spacing()
	var _p3 = Time.get_ticks_usec() if profiling else 0
	projectiles.step(dt)
	fx.step(dt)
	bars.queue_redraw()
	if profiling:
		var _p4 = Time.get_ticks_usec()
		prof.pre = prof.get("pre", 0) + _p1 - _p0
		prof.units = prof.get("units", 0) + _p2 - _p1
		prof.spacing = prof.get("spacing", 0) + _p3 - _p2
		prof.proj_fx = prof.get("proj_fx", 0) + _p4 - _p3
	_rockfalls(dt)
	_tick_hazards(dt)
	_tick_strikes(dt)
	_tick_air_war(dt)
	_tick_foundry(dt)
	if dwarf_base != null:
		min_base_frac = minf(min_base_frac, dwarf_base.hp / dwarf_base.max_hp)
	_ambient_sounds(dt)
	var keep: Array = []
	for c in corpses:
		if time - c.t < 25.0:
			keep.append(c)
	corpses = keep
	shake_amount = maxf(0.0, shake_amount - dt * 20.0)
	_cleanup()
	_check_end()


func _cleanup() -> void:
	# drop references to targets that died this step (no aiming at corpses, no stale refs)
	for u in units:
		if u.alive:
			for w in u.weapons:
				if w.target != null and (not is_instance_valid(w.target) or not w.target.alive):
					w.target = null
	var removed = false
	for u in units:
		if not u.alive and u.dying_t > u.death_time and not u.wreck_hold:
			removed = true
	if not removed:
		return
	var keep: Array = []
	for u in units:
		if not u.alive and u.dying_t > u.death_time and not u.is_stronghold and not u.wreck_hold:
			u.queue_free()
		else:
			keep.append(u)
	units = keep
	by_side[0] = by_side[0].filter(func(u): return is_instance_valid(u) and not u.is_queued_for_deletion())
	by_side[1] = by_side[1].filter(func(u): return is_instance_valid(u) and not u.is_queued_for_deletion())


func _check_end() -> void:
	if over:
		return
	if dwarf_base != null and not dwarf_base.alive:
		over = true
		won = false
		ended.emit(false)
	elif enemy_base != null and not enemy_base.alive:
		over = true
		won = true
		if director != null:
			director.enabled = false
		for u in by_side[1]:
			if u.alive and not u.is_stronghold:
				u.take_damage(99999.0, null)
		ended.emit(true)


func _rebuild_buckets() -> void:
	for s in 2:
		for b in buckets[s]:
			b.clear()
		for u in by_side[s]:
			if u.alive:
				var bi = clampi(int(u.position.x / Combat.BUCKET), 0, buckets[s].size() - 1)
				buckets[s][bi].append(u)


## Gentle separation so friendly ground units don't stack into unreadable piles.
func _resolve_spacing() -> void:
	for s in 2:
		for bi in buckets[s].size():
			var arr: Array = buckets[s][bi]
			if arr.size() < 2:
				continue
			for i in arr.size():
				var a: Unit = arr[i]
				if a.domain != "ground" or a.is_static or not a.alive or a.perch_t > 0.0:
					continue
				for j in range(i + 1, mini(arr.size(), i + 8)):
					var b: Unit = arr[j]
					if b.domain != "ground" or b.is_static or not b.alive or b.perch_t > 0.0:
						continue
					var dx = b.position.x - a.position.x
					var min_d = (a.radius + b.radius) * 0.55
					if absf(dx) < min_d and absf(a.lane - b.lane) < 8.0:
						var push = (min_d - absf(dx)) * 0.25
						var sg = signf(dx) if dx != 0.0 else 1.0
						b.lane = clampf(b.lane + sg * 0.8, -18.0, 18.0)
						a.lane = clampf(a.lane - sg * 0.8, -18.0, 18.0)
						# the one further back yields
						if (a.position.x - b.position.x) * a.dir > 0.0:
							b.position.x -= a.dir * push * 0.3
						else:
							a.position.x -= a.dir * push * 0.3


# =============================================================== queries
func alive_count(side: int) -> int:
	var n = 0
	for u in by_side[side]:
		if u.alive and not u.is_stronghold:
			n += 1
	return n


## M006: alive flyers of one side (the undead air budget; the HUD sky-threat counter).
func air_alive(side: int) -> int:
	var n = 0
	for u in by_side[side]:
		if u.alive and u.domain == "air":
			n += 1
	return n


## Hostile flyers by band [low, mid, high] (battle HUD sky-threat indicator).
func sky_threat() -> Array:
	var c = [0, 0, 0]
	for u in by_side[1]:
		if u.alive and u.domain == "air":
			c[u.band_i()] += 1
	return c


func _domain_ok(u, mode: String) -> bool:
	match mode:
		"ground":
			return u.domain == "ground"
		"air":
			return u.domain == "air"
		"ground_lowair":
			return u.domain == "ground" or u.position.y > Combat.LOW_AIR_Y
		_:
			return true


## All alive, targetable units of `side` within r of pos (uses x-buckets as spatial filter).
func query(pos: Vector2, r: float, side: int, mode: String) -> Array:
	var out: Array = []
	var b0 = clampi(int((pos.x - r - 80.0) / Combat.BUCKET), 0, buckets[side].size() - 1)
	var b1 = clampi(int((pos.x + r + 80.0) / Combat.BUCKET), 0, buckets[side].size() - 1)
	var r2 = r * r
	for bi in range(b0, b1 + 1):
		for u in buckets[side][bi]:
			if not u.alive or not u.targetable_by(1 - side) or not _domain_ok(u, mode):
				continue
			var d = u.aim_point()
			var dist2: float
			if u.is_structure:
				var dx = maxf(0.0, absf(d.x - pos.x) - u.radius)
				dist2 = dx * dx + (d.y - pos.y) * (d.y - pos.y) * 0.25
			else:
				dist2 = pos.distance_squared_to(d)
			if dist2 <= r2 + u.radius * u.radius * 2.0:
				out.append(u)
	return out


## Target acquisition: candidates inside the weapon's range/arc scored by its priority class.
func acquire(u: Unit, w: Weapon, exclude_structures: bool) -> Unit:
	var r = w.effective_range(u, self) + (u.radius if w.proj == "melee" else 0.0) + 30.0
	var from = w.mount_world(u)
	var qpos = from
	var qr = r
	if w.horizontal_only:
		qpos = Vector2(from.x, Combat.GROUND_Y)
		qr = r + 10.0
	var cands = query(qpos, qr + (Combat.GROUND_Y - from.y if u.domain == "air" and w.targets != "air" else 0.0), Combat.enemy_of(u.side), w.targets)
	var best: Unit = null
	var best_s = INF
	for c in cands:
		if exclude_structures and c.is_stronghold:
			continue
		if c.domain == "air" and not w.can_hit_domain(c):
			continue
		if not w.in_range(u, c, self):
			continue
		var s = _score(u, w, c, from)
		if s < best_s:
			best_s = s
			best = c
	return best


func _score(u: Unit, w: Weapon, c: Unit, from: Vector2) -> float:
	var s = from.distance_to(c.aim_point())
	# independent weapons spread out: avoid piling onto a sibling weapon's target
	if u.weapons.size() > 1:
		for o in u.weapons:
			if o != w and o.target == c:
				s += 170.0
	if c.is_stronghold:
		s += 2000.0 if w.priority != "structure" else -1500.0
	if c.taunt and w.proj == "melee":
		s -= 150.0
	match w.priority:
		"air":
			if c.domain == "air":
				s -= 2000.0
		"armored":
			if c.armor in Combat.ARMORED_CLASSES and not c.is_stronghold:
				s -= 600.0 + c.max_hp * 0.2
		"swarm":
			s -= 90.0 * _neighbors(c, 70.0)
		"structure":
			if c.is_structure:
				s -= 1500.0
		"support":
			if c.cls in ["artillery", "engineer"] or c.hold_behind:
				s -= 700.0
			elif c.domain == "air":
				s -= 200.0
		"threat":
			s -= float(c.def.get("threat", 1.0)) * 35.0
			if c.hold_behind or c.cls in ["artillery"]:
				s -= 120.0
	return s


func _neighbors(c: Unit, r: float) -> int:
	var n = 0
	var bi = clampi(int(c.position.x / Combat.BUCKET), 0, buckets[c.side].size() - 1)
	for b in range(maxi(0, bi - 1), mini(buckets[c.side].size(), bi + 2)):
		for o in buckets[c.side][b]:
			if o != c and o.alive and absf(o.position.x - c.position.x) < r and absf(o.position.y - c.position.y) < r:
				n += 1
	return n


func find_nearest(u: Unit, r: float, mode: String) -> Unit:
	var best: Unit = null
	var bd = INF
	var reach_i: int = u.max_reach() if mode == "air" else 2
	for c in query(u.position, r, Combat.enemy_of(u.side), mode):
		if reach_i < 2 and c.domain == "air" and c.band_i() > reach_i:
			continue
		var d = u.position.distance_squared_to(c.aim_point())
		if c.is_stronghold:
			d += 1.0e7
		if d < bd:
			bd = d
			best = c
	return best


func nearest_enemy_ground(u: Unit, r: float) -> Unit:
	return find_nearest(u, r, "ground")


func nearest_blocker(u: Unit) -> Unit:
	var best: Unit = null
	var bd = INF
	var enemy = Combat.enemy_of(u.side)
	var b0 = clampi(int((u.position.x - 260.0) / Combat.BUCKET), 0, buckets[enemy].size() - 1)
	var b1 = clampi(int((u.position.x + 260.0) / Combat.BUCKET), 0, buckets[enemy].size() - 1)
	for bi in range(b0, b1 + 1):
		for e in buckets[enemy][bi]:
			if not e.alive or e.domain != "ground" or not e.blocks or e.burrowed or e.is_stronghold:
				continue
			var ahead: float = (e.position.x - u.position.x) * u.dir
			if ahead < -e.radius:
				continue
			if ahead < bd:
				bd = ahead
				best = e
	return best


## Most advanced friendly front-line ground unit (melee/vehicle/walker), or null.
var _front_cache := [[-1.0, null, null], [-1.0, null, null]]   # [time, x, unit] per side, once per step


func front_x(side: int, exclude):
	var fc: Array = _front_cache[side]
	if fc[0] == time and fc[2] != exclude and fc[2] != null and is_instance_valid(fc[2]) and _front_eligible(fc[2]):
		return fc[2].position.x       # cached front unit, live position (matches the uncached scan)
	var res = _front_scan(side, exclude)
	if exclude == null or not _front_eligible(exclude):
		fc[0] = time
		fc[1] = res[0]
		fc[2] = res[1]
	return res[0]


func _front_eligible(u) -> bool:
	return u.alive and u.domain == "ground" and not u.is_static and not u.hold_behind and u.cls != "artillery" and not u.burrowed


func _front_scan(side: int, exclude) -> Array:
	var best = null
	var bu = null
	var dir = Combat.dir_of(side)
	for u in by_side[side]:
		if u == exclude or not u.alive or u.domain != "ground" or u.is_static or u.hold_behind or u.cls == "artillery" or u.burrowed:
			continue
		if best == null or (u.position.x - float(best)) * dir > 0.0:
			best = u.position.x
			bu = u
	return [best, bu]


func enemy_ground_near(side: int, x: float, r: float) -> bool:
	return not query(Vector2(x, Combat.GROUND_Y - 20.0), r, Combat.enemy_of(side), "ground").filter(func(e): return not e.is_stronghold).is_empty()


func most_damaged_machine(u: Unit, r: float, classes: Array) -> Unit:
	var best: Unit = null
	var bf = 0.98
	for c in by_side[u.side]:
		if c == u or not c.alive or c.domain != "ground":
			continue
		if not c.cls in classes:
			continue
		if absf(c.position.x - u.position.x) > r:
			continue
		var f: float = c.hp / c.max_hp
		if f < bf:
			bf = f
			best = c
	return best


func densest_enemy_ground(u: Unit):
	var best = null
	var bn = -1
	for c in by_side[Combat.enemy_of(u.side)]:
		if not c.alive or c.domain != "ground" or c.is_static:
			continue
		var n = _neighbors(c, 95.0)
		if n > bn or (n == bn and best != null and absf(c.position.x - u.position.x) < absf(best.x - u.position.x)):
			bn = n
			best = c.position
	return best


func best_bomb_target(u: Unit) -> Unit:
	var best: Unit = null
	var bs = -INF
	for c in by_side[Combat.enemy_of(u.side)]:
		if not c.alive or c.domain != "ground" or c.burrowed:
			continue
		if c.is_stronghold and alive_count(c.side) > 0:
			continue
		var s = float(_neighbors(c, 70.0)) * 10.0 - absf(c.position.x - u.position.x) * 0.01
		if c.is_structure:
			s += 15.0
		if s > bs:
			bs = s
			best = c
	return best


func bat_prey(u: Unit) -> Unit:
	var best: Unit = null
	var bs = INF
	var reach_i: int = u.max_reach()
	for c in query(u.position, 520.0, Combat.enemy_of(u.side), "any"):
		if c.domain == "air" and c.band_i() > reach_i:
			continue
		var s = u.position.distance_to(c.aim_point())
		if c.is_stronghold:
			s += 900.0
		elif c.cls in ["artillery", "engineer"] or c.hold_behind:
			s -= 160.0
		elif c.domain == "air":
			s -= 60.0
		if s < bs:
			bs = s
			best = c
	if best == null and dwarf_base != null and dwarf_base.alive and u.side == 1:
		best = dwarf_base
	return best


func is_spotted(pos: Vector2) -> bool:
	for s in spotters:
		if absf(s.position.x - pos.x) < float(s.def.spotter.get("range", 250)):
			return true
	return false


func corpses_near(pos: Vector2, r: float) -> Array:
	return corpses.filter(func(c): return absf(c.pos.x - pos.x) < r)


func consume_corpse(c) -> void:
	corpses.erase(c)


# =============================================================== damage
func damage(t: Unit, amount: float, dtype: String, src, ap: bool, bonus: Dictionary) -> void:
	if t == null or not is_instance_valid(t) or not t.alive:
		return
	if invulnerable_bases and t.is_stronghold:
		return
	var m = Combat.dmg_mult(t.armor, dtype, ap)
	if dtype == "flak":
		m *= Combat.FLAK_VS_AIR if t.domain == "air" else Combat.FLAK_VS_GROUND
	if bonus.has(t.armor):
		m *= float(bonus[t.armor])
	if bonus.has("structure") and t.is_structure and t.armor != "structure":
		m *= float(bonus.structure)
	if t.is_boss and t.def.has("weak"):
		m *= float(t.def.weak.get(dtype, 1.0))   # M005: e.g. the Blightroot Behemoth burns
	if t.low_profile and dtype == "blast":
		m *= 0.5
	# war-frame ARM: % reduction of physical damage, capped at 50%, reduced by penetration
	var arm = float(t.def.get("arm", 0.0))
	if arm > 0.0 and dtype in Combat.PHYSICAL:
		var pen = float(bonus.get("_pen", 0.0)) + (0.2 if ap else 0.0)
		m *= 1.0 - clampf(arm - pen, 0.0, Combat.ARM_CAP)
	if projectile_ctx:
		# shield facing: frontal projectiles only
		if t.front_guard > 0.0 and (projectile_src_x - t.position.x) * t.facing > 0.0:
			m *= 1.0 - t.front_guard
		for wd in wards:
			if wd.side == t.side and absf(t.position.x - wd.x) <= wd.r:
				m *= float(wd.mult)
				stats_ward_blocks += 1
				break
	m = maxf(m, Combat.MIN_DAMAGE_MULT)   # armor never reduces damage to zero
	var dealt = t.take_damage(amount * m, src)
	stats_dmg[1 - t.side] += dealt
	# M003 on-hit effects carried in the weapon's bonus dict
	if t.alive and not t.is_static and t.cls != "boss":
		if bonus.has("_slow"):
			t.apply_slow(float(bonus._slow[0]), float(bonus._slow[1]))
		if bonus.has("_stun"):
			t.stun_t = maxf(t.stun_t, float(bonus._stun))
	if dealt > 0.0 and src != null and is_instance_valid(src) and src.alive and src.def.has("heal_on_hit"):
		src.hp = minf(src.max_hp, src.hp + dealt * float(src.def.heal_on_hit))
	if t.is_stronghold and t.side == 0 and dealt > 0.0 and time - _base_alert_t > 12.0:
		_base_alert_t = time
		alert.emit("The stronghold is under attack!")
	if dealt > 0.0 and src != null and is_instance_valid(src) and not t.alive:
		src.kills += 1


func splash(at: Vector2, r: float, amount: float, dtype: String, side: int, dom: String, ap: bool, src, bonus: Dictionary) -> void:
	var mode = dom if dom != "any" else "any"
	for e in query(at, r, Combat.enemy_of(side), mode):
		var d = at.distance_to(e.aim_point())
		if e.is_structure:
			d = maxf(0.0, absf(at.x - e.position.x) - e.radius)
		var fall = clampf(1.0 - d / (r + e.radius) * 0.5, 0.5, 1.0)
		damage(e, amount * fall, dtype, src, ap, bonus)


func on_unit_died(u: Unit) -> void:
	u.die()
	var key = u.id + " <- " + (u.last_hit_by if u.last_hit_by != "" else "hazard/other")
	death_log[key] = int(death_log.get(key, 0)) + 1
	var undead = u.side == 1
	if u.is_stronghold:
		fx.wreck(u.position + Vector2(0, -100), 3.0)
		shake(14.0)
		Audio.play("explosion", u.position.x, 4.0)
		return
	if undead:
		stats_kills += 1
		gold = minf(9999.0, gold + float(u.def.get("bounty", 0)) * 0.6)
		if u.is_structure or u.is_static:
			structures_killed += 1
	elif u == escort_unit:
		escort_state = "lost"
		alert.emit("The supply barge is down!")
	else:
		stats_losses += 1
		if u.cls in ["aircraft", "airship"]:
			air_losses += 1
		if Foundry.leaves_wreck(self, u):
			Foundry.add_wreck(self, u)
	if u.domain == "ground" and u.cls in ["infantry", "engineer", "monster"] and not u.def.has("death_burst"):
		if corpses.size() < 40:
			corpses.append({"pos": u.position, "t": time})
	if u.def.has("death_spawn"):
		var ds: Dictionary = u.def.death_spawn
		for i in int(ds.get("count", 1)):
			var z = spawn_unit(String(ds.unit), u.side, Vector2(u.position.x + rng.randf_range(-18.0, 18.0), 0), true)
			if z != null:
				fx.raise(z.position + Vector2(0, -10))
	if u.def.has("death_burst"):
		var b: Dictionary = u.def.death_burst
		splash(u.position + Vector2(0, -15), float(b.radius), float(b.damage), b.get("dtype", "acid"), u.side, "ground_lowair", false, null, {})
		fx.splat(u.position + Vector2(0, -15))
		fx.splat(u.position + Vector2(10, -5))
		fx.telegraph(u.position, float(b.radius), 0.6, Color(0.6, 0.9, 0.2))
	match u.cls:
		"vehicle", "walker", "artillery", "airship":
			fx.wreck(u.aim_point(), 1.2 if u.cls != "airship" else 2.2)
			Audio.play("explosion", u.position.x, -2.0)
		"aircraft":
			fx.explosion(u.position, 0.8, "fire")
			Audio.play("explosion", u.position.x, -6.0)
		"boss":
			fx.wreck(u.position + Vector2(0, -60), 3.0)
			shake(16.0)
			Audio.play("boss", u.position.x, 4.0)
			on_boss_died(u)
		"structure":
			fx.bones(u.position + Vector2(0, -60))
			fx.explosion(u.position + Vector2(0, -50), 1.2, "dirt")
			Audio.play("skeletal_impact", u.position.x, 0.0)
		_:
			if u.armor == "bone" or u.armor == "bone_shield":
				fx.bones(u.aim_point())
				Audio.play("skeletal_impact", u.position.x, -6.0)
			else:
				fx.blood(u.aim_point(), undead)
				if undead and rng.randf() < 0.3:
					Audio.play("undead_snarl", u.position.x, -10.0)


func on_boss_spawned(b) -> void:
	boss = b
	boss_arrive_t = time
	if b != null and b.def.get("boss", {}).get("seals_citadel", false):
		citadel_sealed = true
		enemy_base.special = 1.0
	boss_appeared.emit(b)
	Audio.play("boss", b.position.x if b != null else 2000.0, 2.0)


func on_boss_died(_b) -> void:
	boss_kill_t = time
	citadel_sealed = false
	if enemy_base != null:
		enemy_base.special = 0.0
	fx.explosion(enemy_base.position + Vector2(-10, -130), 2.0, "fire")


# =============================================================== hazards & presentation
func schedule_rockfall(x: float, dmg: float, r: float, warn: float = 1.4, variant: String = "") -> void:
	rockfalls.append({"x": x, "t": 0.0, "dmg": dmg, "r": r, "warn": warn, "variant": variant})
	fx.telegraph(Vector2(x, Combat.GROUND_Y), r, warn, Color(0.8, 0.7, 0.5) if variant != "gantry" else Color(1.0, 0.62, 0.25))
	if variant == "gantry":
		stats_gantries += 1
		Audio.play("girder_groan", x, -3.0)
		hazard_layer.queue_redraw()
	else:
		Audio.play("rockfall", x, -4.0)


func _rockfalls(dt: float) -> void:
	var keep: Array = []
	for rf in rockfalls:
		rf.t += dt
		var warn = float(rf.get("warn", 1.4))
		if rf.t < warn:
			if String(rf.get("variant", "")) == "gantry":
				# M007 collapsing gantry: rivets shower down before the girder falls (drawn by HazardLayer)
				if rng.randf() < dt * 6.0:
					fx.sparks(Vector2(rf.x + rng.randf_range(-rf.r, rf.r), 150.0), 1)
			elif rng.randf() < dt * 12.0:
				fx.puff(Vector2(rf.x + rng.randf_range(-rf.r, rf.r), 130.0 + rf.t * 300.0), Color(0.5, 0.45, 0.4, 0.6))
			keep.append(rf)
		else:
			var p = Vector2(rf.x, Combat.GROUND_Y - 10.0)
			for s in 2:
				for e in query(p, rf.r, s, "ground"):
					if not e.is_static:
						damage(e, rf.dmg, "blast", null, false, {})
			fx.explosion(p, 1.0, "dirt")
			if String(rf.get("variant", "")) == "gantry":
				fx.sparks(p + Vector2(0, -10), 8)
				fx.dust(p, 2.0)
				Audio.play("girder_crash", rf.x, 0.0)
			shake(4.0)
	rockfalls = keep


func shake(a: float) -> void:
	shake_amount = maxf(shake_amount, a)


func weapon_sound(u: Unit, w: Weapon) -> void:
	var x = u.position.x
	if u.is_mech:
		match w.family:
			"boomstick", "boomstick_big", "boomstick_chest":
				Audio.play("boomstick", x, -1.0, 0.05)
				return
			"drill":
				Audio.play("drill", x, -6.0)
				return
			"rotary", "aa_mg":
				Audio.play("mg_mech", x, -8.0)
				return
			"cannon", "siege", "aa_heavy":
				Audio.play("cannon_heavy", x, -2.0, 0.04)
				return
			"hammer", "hammer2", "fist2", "stomp":
				Audio.play("hammer_impact", x, -3.0)
				return
			"axe2", "claw":
				Audio.play("axe_swing", x, -4.0)
				Audio.play("melee", x, -6.0)
				return
			"coil":
				Audio.play("electric", x, -5.0)
				return
			"flamer", "flamer_big":
				Audio.play("flame", x, -9.0)
				return
	match w.proj:
		"bullet", "volley":
			Audio.play("rapid" if float(w.d.get("reload", 1.0)) < 0.5 else "rifle", x, -10.0 if float(w.d.get("reload", 1.0)) < 0.5 else -4.0)
		"cone":
			Audio.play("blunderbuss", x, -3.0)
		"shell":
			Audio.play("cannon", x, -3.0)
		"arc":
			Audio.play("mortar", x, -8.0)
		"flak":
			Audio.play("flak", x, -6.0)
		"steam":
			Audio.play("steam", x, -10.0)
		"melee":
			Audio.play("melee", x, -12.0)
		"bolt":
			Audio.play("necro_magic", x, -10.0)
		"shard", "arrow":
			Audio.play("skeletal_impact", x, -12.0)
		"spit":
			Audio.play("undead_snarl", x, -14.0)


func _ambient_sounds(dt: float) -> void:
	var cx = view_rect.get_center().x if view_rect.size != Vector2.ZERO else 640.0
	for k in ["tank", "walker", "air", "airship", "snarl"]:
		_sound_t[k] = float(_sound_t.get(k, 0.0)) - dt
	var veh = false
	var wal = false
	var air = false
	var ship = false
	for u in by_side[0]:
		if not u.alive or absf(u.position.x - cx) > 700.0:
			continue
		match u.cls:
			"vehicle":
				veh = veh or u.state == "move"
			"walker":
				wal = wal or u.state == "move"
			"aircraft":
				air = true
			"airship":
				ship = true
	if veh and _sound_t.tank <= 0.0:
		_sound_t.tank = 0.6
		Audio.play("tank_move", cx, -14.0)
	if wal and _sound_t.walker <= 0.0:
		_sound_t.walker = 0.55
		Audio.play("walker_step", cx, -10.0)
	if air and _sound_t.air <= 0.0:
		_sound_t.air = 0.48
		Audio.play("propeller", cx, -20.0)
	if ship and _sound_t.airship <= 0.0:
		_sound_t.airship = 0.78
		Audio.play("airship_engine", cx, -14.0)
	if _sound_t.snarl <= 0.0 and alive_count(1) > 0:
		_sound_t.snarl = rng.randf_range(2.5, 6.0)
		Audio.play("undead_snarl", cx + rng.randf_range(0, 500), -16.0, 0.25)
	# M006 sky monsters: wyvern roars, thumping drake wingbeats, serpent hiss, the ghost fleet's bells
	_sound_t["sky"] = float(_sound_t.get("sky", 1.0)) - dt
	if _sound_t.sky <= 0.0:
		_sound_t.sky = _fx_rng.randf_range(1.6, 3.4)   # presentation RNG: never consume the gameplay RNG
		for u in by_side[1]:
			if not u.alive or u.domain != "air" or absf(u.position.x - cx) > 650.0:
				continue
			var snd = {"bone_wyvern": "wyvern_roar", "bone_drake": "wingbeat", "dread_sky_tyrant": "wingbeat", "bone_wyrm": "wyvern_roar",
				"necrotic_sky_serpent": "serpent_hiss", "infected_airbarge": "timber_creak", "hollow_admiral": "ghost_bell"}.get(u.id, "")
			if snd != "":
				Audio.play(snd, u.position.x, -10.0, 0.15)
				break
	# M007 corrupted machines: recognisably dwarven engines with a wheezing, choir-like undertone
	_sound_t["corrupt"] = float(_sound_t.get("corrupt", 2.0)) - dt
	if _sound_t.corrupt <= 0.0:
		_sound_t.corrupt = _fx_rng.randf_range(2.2, 4.0)
		for u in by_side[1]:
			if u.alive and u.id in CORRUPTED_IDS and absf(u.position.x - cx) < 650.0:
				Audio.play("corrupt_engine", u.position.x, -9.0, 0.12)
				break
	if not thermals.is_empty():
		_sound_t["thermal"] = float(_sound_t.get("thermal", 3.0)) - dt
		if _sound_t.thermal <= 0.0:
			_sound_t.thermal = _fx_rng.randf_range(4.0, 7.0)
			var c = thermals[_fx_rng.randi() % thermals.size()]
			if absf(float(c.x) - cx) < 700.0:
				Audio.play("updraft", float(c.x), -12.0)


func _physics_process(_delta: float) -> void:
	pass


# =============================================================== M002 war-frame support
## Deterministic ability arbitration: units ask in serial order; at most one activation per
## GLOBAL_GAP; the doctrine decides how much Steam must stay in reserve.
func _arbitrate_abilities(dt: float) -> void:
	_ability_gap = maxf(0.0, _ability_gap - dt)
	if _ability_gap > 0.0 or over:
		return
	for u in by_side[0]:
		if not u.is_mech or not MechAbility.ready_to_request(u):
			continue
		var cost = float(u.ability.steam)
		var reserve = 0.0
		match mech_doctrine:
			"conserve":
				reserve = maxf(0.0, 90.0 - cost)
			"standard":
				reserve = 10.0
			"overdrive":
				reserve = 0.0
		if steam < cost + reserve:
			continue
		if not MechAbility.wants(u, self, mech_doctrine):
			continue
		MechAbility.activate(u, self)
		_ability_gap = MechAbility.GLOBAL_GAP
		return


## Undead giants: necrotic abilities on cooldown (no Steam), one activation per short gap.
func _giant_abilities(dt: float) -> void:
	_giant_gap = maxf(0.0, _giant_gap - dt)
	if _giant_gap > 0.0 or over:
		return
	for u in by_side[1]:
		if u.is_boss:
			if _boss_ability(u):
				_giant_gap = 0.4
				return
			continue
		if not u.is_giant or not MechAbility.ready_to_request(u):
			continue
		if not MechAbility.wants(u, self, "standard"):
			continue
		MechAbility.activate(u, self)
		_giant_gap = 0.4
		return


## Bosses carry several abilities, each on its own cooldown, with a short gap between casts.
func _boss_ability(u) -> bool:
	for k in u._acds.keys():
		u._acds[k] = maxf(0.0, float(u._acds[k]) - 0.0)
	if not u.alive or u.ability_wind >= 0.0 or u.stun_t > 0.0 or time < u._boss_gap:
		return false
	for abd in u.def.get("abilities", []):
		var key = String(abd.id)
		if float(u._acds.get(key, -1.0)) > time:
			continue
		u.ability = abd
		u.ability_cd = 0.0
		if not MechAbility.wants(u, self, "standard"):
			continue
		MechAbility.activate(u, self)
		u.ability_cd = 0.0
		u._acds[key] = time + float(abd.cooldown)
		u._boss_gap = time + 2.5
		alert.emit("%s: %s" % [String(u.def.get("name", "Boss")), String(abd.name)])
		return true
	return false


func knock(e: Unit, dx: float) -> void:
	# bounded displacement: only light, mobile, non-boss ground units
	if e.is_static or e.cls in ["boss", "walker", "vehicle", "monster"] or e.radius >= 20.0 or e.domain != "ground":
		return
	e.position.x = clampf(e.position.x + dx, Combat.DWARF_BASE_X + Combat.BASE_FACE, Combat.UNDEAD_BASE_X - Combat.BASE_FACE)
	e.stun_t = maxf(e.stun_t, 0.35)


func add_zone(pos: Vector2, r: float, dps: float, dur: float, side: int, src, dtype: String = "fire", look: String = "fire", slow: float = 0.0) -> void:
	if zones.size() >= ZONE_CAP:
		zones.pop_front()
	zones.append({"pos": pos, "r": r, "dps": dps, "t": dur, "dur": dur, "side": side, "tick": 0.0, "src": src, "dtype": dtype, "look": look, "slow": slow})


func add_ward(owner: Unit, r: float, mult: float, dur: float) -> void:
	if wards.size() >= WARD_CAP:
		wards.pop_front()
	wards.append({"owner": owner, "x": owner.position.x - owner.dir * r * 0.35, "r": r, "mult": mult, "t": dur, "dur": dur, "side": owner.side})


func _tick_zones(dt: float) -> void:
	var keep: Array = []
	for z in zones:
		z.t -= dt
		z.tick -= dt
		if z.tick <= 0.0:
			z.tick = 0.5   # bounded damage-over-time ticks
			var srcv = z.src if is_instance_valid(z.src) else null
			for e in query(z.pos, z.r, Combat.enemy_of(z.side), "ground"):
				damage(e, z.dps * 0.5, String(z.dtype), srcv, false, {})
				if float(z.slow) > 0.0 and e.alive:
					e.apply_slow(float(z.slow), 0.6)
				stats_zone_ticks += 1
			fx.flames(z.pos, z.r, String(z.look))
		if z.t > 0.0:
			keep.append(z)
	zones = keep
	var keepw: Array = []
	for w in wards:
		w.t -= dt
		if is_instance_valid(w.owner) and w.owner.alive and w.t > 0.0:
			w.x = w.owner.position.x - w.owner.dir * w.r * 0.35
			keepw.append(w)
	wards = keepw


func cycle_doctrine() -> String:
	var order = ["conserve", "standard", "overdrive"]
	mech_doctrine = order[(order.find(mech_doctrine) + 1) % order.size()]
	return mech_doctrine



func _deploy_def_id(uid: String) -> String:
	if sandbox or not is_instance_valid(GameState):
		return uid
	return GameState.deploy_id(uid)


# =============================================================== M005 hazards
func add_miasma(x: float, r: float, dps: float, dur: float, spd: float) -> void:
	if miasma_clouds.size() >= MIASMA_CAP:
		miasma_clouds.pop_front()
	miasma_clouds.append({"x": x, "r": r, "dps": dps, "t": 0.0, "dur": dur, "speed": spd, "tick": 0.5, "seed": rng.randi() % 1000})
	Audio.play("miasma", x, -6.0)


func set_bog(h: Dictionary) -> void:
	bog_spots.clear()
	for x in h.get("spots", []):
		bog_spots.append({"x": float(x), "w": float(h.get("width", 160)), "slow": clampf(float(h.get("slow", 0.4)), 0.0, 0.8)})
	if hazard_layer != null:
		hazard_layer.refresh_bog()


## Miasma affects living things only: machines, structures, spectres and bosses are immune;
## skeletons have no lungs to rot, so they take half.
static func miasma_mult(u) -> float:
	if u.is_static or u.is_structure or u.is_boss or u.cls == "boss" or u.domain != "ground":
		return 0.0
	if u.cls in ["vehicle", "walker", "aircraft", "airship"] or u.armor in ["machine", "mech", "structure"]:
		return 0.0
	if u.armor == "bone" or u.armor == "bone_shield":
		return 0.5
	return 1.0


func in_bog(x: float) -> Dictionary:
	for b in bog_spots:
		if absf(x - float(b.x)) <= float(b.w) * 0.5:
			return b
	return {}


func _tick_hazards(dt: float) -> void:
	if not miasma_clouds.is_empty():
		var keep: Array = []
		for c in miasma_clouds:
			c.t += dt
			c.x -= float(c.speed) * dt
			c.tick -= dt
			if c.tick <= 0.0:
				c.tick = 0.5
				for s in 2:
					for e in query(Vector2(c.x, Combat.GROUND_Y), float(c.r), s, "ground"):
						var m = miasma_mult(e)
						if m <= 0.0:
							continue
						var dealt = e.take_damage(float(c.dps) * 0.5 * m, null)
						stats_miasma[e.side] += dealt
						stats_miasma_hits[e.id] = int(stats_miasma_hits.get(e.id, 0)) + 1
						if not e.alive:
							e.last_hit_by = "miasma"
			if c.t < c.dur and c.x > Combat.DWARF_BASE_X - 60.0:
				keep.append(c)
		miasma_clouds = keep
		hazard_layer.queue_redraw()
	if not bog_spots.is_empty():
		_bog_sound_t -= dt
		for s in 2:
			for u in by_side[s]:
				if not u.alive or u.domain != "ground" or u.is_static:
					continue
				var b = in_bog(u.position.x)
				if b.is_empty():
					continue
				if u.slow_t <= 0.05:
					stats_bog_slowed += 1
					if _bog_sound_t <= 0.0 and absf(u.position.x - view_rect.get_center().x) < 700.0:
						_bog_sound_t = 1.6
						Audio.play("squelch", u.position.x, -10.0)
				u.apply_slow(1.0 - float(b.slow), 0.25)


## Telegraphed delayed strike (boss phase attacks). hit_side: 0 dwarves, 1 undead, -1 both.
func schedule_strike(x: float, r: float, dmg: float, delay: float, hit_side: int, slow: float = 0.0, look: String = "roots") -> void:
	if strikes.size() >= 16:
		return
	strikes.append({"x": x, "r": r, "dmg": dmg, "t": 0.0, "delay": delay, "hit_side": hit_side, "slow": slow, "look": look})
	fx.telegraph(Vector2(x, Combat.GROUND_Y), r, delay, Color(0.75, 0.55, 0.25) if look == "roots" else Color(0.6, 0.9, 0.2))


var stats_strike_hits := 0
var stats_phase_changes := 0
var stats_root_eruptions := 0
var stats_phase_spawns := 0
var stats_perches := 0
var stats_wyrm_dives := 0
var stats_shield_breaks := 0


func _tick_strikes(dt: float) -> void:
	if strikes.is_empty():
		return
	var keep: Array = []
	for sk in strikes:
		sk.t += dt
		if sk.t < sk.delay:
			keep.append(sk)
			continue
		var p = Vector2(sk.x, Combat.GROUND_Y - 10.0)
		for s in 2:
			if int(sk.hit_side) != -1 and int(sk.hit_side) != s:
				continue
			for e in query(p, float(sk.r), s, "ground"):
				if e.is_static:
					continue
				damage(e, float(sk.dmg), "blast", boss if boss != null and is_instance_valid(boss) else null, false, {})
				stats_strike_hits += 1
				if float(sk.slow) > 0.0 and e.alive:
					e.apply_slow(1.0 - float(sk.slow), 3.0)
		fx.flames(p, float(sk.r), String(sk.look))
		fx.explosion(p, 0.8, "dirt")
		shake(3.0)
		Audio.play("rockfall", sk.x, -6.0)
	strikes = keep


# =============================================================== M005 challenge objectives & stars
func challenge_met(c: Dictionary) -> bool:
	if not won:
		return false
	match String(c.get("kind", "")):
		"no_air_losses":
			return air_losses == 0
		"time_under":
			return time <= float(c.get("seconds", 0))
		"base_above":
			return min_base_frac >= float(c.get("frac", 1.0))
		"kill_structures":
			return structures_total > 0 and structures_killed >= structures_total
		"max_types":
			return deploy_types.size() <= int(c.get("n", 0))
		"max_losses":
			return stats_losses <= int(c.get("n", 0))
		"kill_boss_by":
			return boss_kill_t >= 0.0 and boss_kill_t - boss_arrive_t <= float(c.get("seconds", 0))
		"escort":
			return escort_state == "delivered"
		"no_reclaims":
			return stats_reclaimed == 0
	return false


## Stars earned in this battle: [victory, stronghold held above 50 %, challenge met].
func stars_earned() -> Array:
	var c: Dictionary = stage.get("challenge", {}) if stage.get("challenge") != null else {}
	var held = won and dwarf_base != null and dwarf_base.hp / dwarf_base.max_hp > 0.5
	return [won, held, won and not c.is_empty() and challenge_met(c)]


# =============================================================== M007 foundry systems
func _tick_foundry(dt: float) -> void:
	var any = false
	if not wrecks.is_empty():
		Foundry.tick_wrecks(self, dt)
		any = true
	if not vents.is_empty() or not eruptions.is_empty():
		Foundry.tick_vents(self, dt)
		any = true
	if not slag.is_empty():
		Foundry.tick_slag(self, dt)
		any = true
	if not steam_pipes.is_empty():
		Foundry.tick_steam(self, dt)
		any = true
	if not corpse_throws.is_empty():
		_tick_corpse_throws(dt)
		any = true
	if any or not rockfalls.is_empty():
		hazard_layer.foundry_item.queue_redraw()
		hazard_layer.queue_redraw()


func _tick_corpse_throws(dt: float) -> void:
	var keep: Array = []
	for c in corpse_throws:
		c.t += dt
		if c.t < c.dur:
			keep.append(c)
			continue
		if dwarf_base != null and dwarf_base.alive:
			var src = boss if boss != null and is_instance_valid(boss) and boss.alive else null
			damage(dwarf_base, float(c.dmg), "blast", src, false, {})
			stats_corpse_hits += 1
			for e in query(Vector2(float(c.x1), Combat.GROUND_Y), 70.0, 0, "ground"):
				if not e.is_static:
					damage(e, float(c.dmg) * 0.3, "blast", src, false, {})
		var p = Vector2(float(c.x1), Combat.GROUND_Y - 30.0)
		fx.splat(p)
		fx.bones(p)
		fx.blood(p + Vector2(10, -10), true)
		fx.explosion(p, 1.0, "dirt")
		shake(6.0)
		Audio.play("corpse_impact", float(c.x1), 2.0)
	corpse_throws = keep


# =============================================================== M006 air war: escort, thermals, lightning
func _tick_air_war(dt: float) -> void:
	var esc = stage.get("escort")
	if esc != null and not sandbox:
		if escort_state == "none":
			escort_state = "pending"
		if escort_state == "pending" and time >= float(esc.t):
			spawn_escort(esc)
	stats_air_peak = maxi(stats_air_peak, air_alive(1))
	if not thermals.is_empty():
		for s in 2:
			for u in by_side[s]:
				if not u.alive or u.domain != "air":
					continue
				var th = 0.0
				for c in thermals:
					if absf(u.position.x - float(c.x)) <= float(c.w) * 0.5:
						th = float(c.dir)
						break
				if th != u.thermal:
					u.thermal = th
					u.band_shift = int(th) if u.cls != "boss" else 0
					if th != 0.0:
						stats_thermal_ticks += 1
	if not bolts.is_empty():
		_tick_bolts(dt)
	flash_t = maxf(0.0, flash_t - dt)
	hazard_layer.shadow_item.queue_redraw()
	if not thermals.is_empty() or not bolts.is_empty() or flash_t > 0.0:
		hazard_layer.queue_redraw()


func spawn_escort(esc: Dictionary):
	var u = spawn_unit("supply_barge", 0, Vector2(float(esc.get("x0", 150)), float(esc.get("alt", 210))), true)
	if u == null:
		return null
	u.max_hp = float(esc.get("hp", 2600))
	u.hp = u.max_hp
	u.speed = float(esc.get("speed", 20))
	u.alt_target = float(esc.get("alt", 210))
	u.escort_def = esc
	escort_unit = u
	escort_state = "flying"
	alert.emit("A supply barge is crossing — keep the sky clear around it!")
	Audio.play("airship_horn", u.position.x, -2.0)
	return u


func on_escort_delivered(_u) -> void:
	if escort_state == "flying":
		escort_state = "delivered"
		if not sandbox and is_instance_valid(GameState) and not GameState.profile.is_empty():
			GameState.profile.stats["escorts"] = int(GameState.profile.stats.get("escorts", 0)) + 1
		alert.emit("Supply barge delivered!")
		Audio.play("star_stamp", _u.position.x, -2.0)


func escort_frac() -> float:
	if escort_unit == null or not is_instance_valid(escort_unit):
		return 0.0 if escort_state == "lost" else -1.0
	return escort_unit.hp / escort_unit.max_hp if escort_unit.alive else 0.0


func set_thermals(h: Dictionary) -> void:
	thermals.clear()
	for c in h.get("columns", []):
		thermals.append({"x": float(c[0]), "dir": signf(float(c[1])), "w": float(h.get("width", 120))})


## Lightning: after a 0.8 s flicker, a bolt hits the tallest thing near x — flyers first, then walkers,
## giants and spires — on either side. Spires and other structures take double damage.
func lightning_strike(dmg: float, r: float, warn: float) -> void:
	if bolts.size() >= 4:
		return
	var tgt = null
	if lightning_air_bias > 0.0 and rng.randf() < lightning_air_bias:
		var air: Array = by_side[0].filter(func(u): return u.alive and u.domain == "air" and u != escort_unit)
		if not air.is_empty():
			tgt = air[rng.randi() % air.size()]
	var x: float = tgt.position.x if tgt != null else rng.randf_range(520.0, 2300.0)
	if tgt == null:
		tgt = tallest_near(x, 170.0)
	var b = {"x": x, "target": tgt, "t": 0.0, "warn": warn, "dmg": dmg, "r": r, "struck": false, "y": Combat.GROUND_Y}
	bolts.append(b)
	Audio.play("crackle", x, -6.0)


func tallest_near(x: float, span: float):
	var best = null
	var best_top = INF
	var best_rank = 9
	for s in 2:
		for u in by_side[s]:
			if not u.alive or u.is_stronghold or u.is_boss or u == escort_unit or absf(u.position.x - x) > span:
				continue
			if u.burrowed:
				continue
			var rank = 9
			var top = 0.0
			if u.domain == "air":
				rank = 0
				top = u.position.y
			elif u.is_mech or u.cls == "walker" or u.is_structure:
				rank = 1
				top = u.position.y - Painter.art_height(u.art) * u.art_scale
			else:
				continue
			if rank < best_rank or (rank == best_rank and top < best_top):
				best_rank = rank
				best_top = top
				best = u
	return best


func _tick_bolts(dt: float) -> void:
	var keep: Array = []
	for b in bolts:
		b.t += dt
		var tg = b.target
		if tg != null and is_instance_valid(tg) and tg.alive:
			b.x = tg.position.x
			b.y = tg.position.y if tg.domain == "air" else tg.position.y - Painter.art_height(tg.art) * tg.art_scale * 0.8
		if not b.struck and b.t >= b.warn:
			b.struck = true
			stats_lightning += 1
			flash_t = 0.12
			var p = Vector2(b.x, b.y)
			if tg != null and is_instance_valid(tg) and tg.alive:
				var m = 2.0 if tg.is_structure else 1.0
				tg.take_damage(float(b.dmg) * m, null)
				if not tg.alive:
					tg.last_hit_by = "lightning"
				stats_lightning_hits[tg.side] += 1
				stats_lightning_kinds[tg.cls] = int(stats_lightning_kinds.get(tg.cls, 0)) + 1
				# the strike arcs into anything packed close by (on both sides)
				for s in 2:
					for e in query(p, float(b.r), s, "any"):
						if e != tg and not e.is_stronghold and not e.is_boss and e != escort_unit:
							e.take_damage(float(b.dmg) * 0.4, null)
			else:
				for s in 2:
					for e in query(Vector2(b.x, Combat.GROUND_Y - 20.0), float(b.r), s, "ground"):
						if not e.is_stronghold:
							e.take_damage(float(b.dmg) * 0.6, null)
			fx.explosion(p, 0.7, "fire")
			shake(2.5)
			Audio.play("thunder", b.x, 0.0)
		if b.t < b.warn + 0.3:
			keep.append(b)
	bolts = keep
