class_name Weapon
extends RefCounted
## Independent weapon component. Each weapon on a unit owns its own target, range, reload,
## rotation, damage, damage type, projectile, firing arc and timing — so multi-turret
## vehicles, gunships and airships fight on both fronts at once.

var d: Dictionary
var index: int = 0
var cd: float = 0.0
var target = null                  # Unit or null
var retarget_t: float = 0.0
var aim: float = 0.0               # local aim angle (0 = forward, +down)
var anim: float = 0.0              # 1.0 right after firing, decays
var windup_t: float = -1.0
var windup_pos: Vector2 = Vector2.ZERO
var windup_target = null
var burst_left: int = 0
var burst_t: float = 0.0
var shots_fired: int = 0
var last_target = null
var family: String = ""

var range_: float
var min_range: float
var targets: String
var priority: String
var proj: String
var arc_min: float = -999.0
var arc_max: float = 999.0
var horizontal_only := false
var reach: int = 2                 # M006 altitude band reach: 0 low, 1 mid, 2 high (air targets above it are out of reach)
const BANDS := {"low": 0, "mid": 1, "high": 2}


func _init(def: Dictionary, idx: int, rng: RandomNumberGenerator) -> void:
	d = def
	index = idx
	range_ = float(d.get("range", 100))
	min_range = float(d.get("min_range", 0))
	targets = d.get("targets", "ground")
	priority = d.get("priority", "nearest")
	proj = d.get("proj", "bullet")
	if d.has("arc"):
		arc_min = deg_to_rad(float(d.arc[0]))
		arc_max = deg_to_rad(float(d.arc[1]))
	horizontal_only = proj == "bomb"
	reach = int(BANDS.get(String(d.get("reach", "high")), 2))
	family = String(d.get("family", ""))
	cd = rng.randf_range(0.0, float(d.get("reload", 1.0)) * 0.5)
	retarget_t = rng.randf_range(0.0, 0.2)
	aim = deg_to_rad(float(d.get("rest_aim", 0.0)))


func mount_world(u) -> Vector2:
	var m: Array = d.get("mount", [0, -20])
	return u.position + Vector2(float(m[0]) * u.facing, float(m[1]))


func effective_range(u, battle) -> float:
	var r = range_
	if u.cls == "artillery" and u.side == 0 and battle.spotting_active:
		r *= battle.spot_range_mult
	return r


func can_hit_domain(t) -> bool:
	match targets:
		"ground":
			return t.domain == "ground"
		"air":
			return t.domain == "air" and t.band_i() <= reach
		"ground_lowair":
			return t.domain == "ground" or t.position.y > Combat.LOW_AIR_Y
		_:
			return t.domain != "air" or t.band_i() <= reach


func in_arc(u, to: Vector2) -> bool:
	if arc_min < -900.0:
		return true
	var local = atan2(to.y, to.x * u.facing)
	return local >= arc_min and local <= arc_max


func in_range(u, t, battle) -> bool:
	var from = mount_world(u)
	var to: Vector2 = t.aim_point() - from
	var dist: float
	if horizontal_only:
		dist = absf(to.x)
	elif (proj == "melee" or (u.is_mech and proj in ["flame", "cone", "steam"])) and t.domain == "ground" and not t.is_structure:
		# melee reach is measured along the ground: a colossal fist mounted high on the frame still swings down
		dist = absf(to.x) - t.radius * 0.5
	elif t.is_structure:
		dist = maxf(0.0, absf(to.x) - t.radius)
		dist = sqrt(dist * dist + (to.y * to.y if u.domain == "air" else 0.0))
	else:
		dist = to.length() - t.radius * 0.5
	var r = effective_range(u, battle)
	if proj == "melee":
		r += u.radius
	if dist > r or dist < min_range:
		return false
	return in_arc(u, to)


func valid_target(u, t, battle) -> bool:
	return t != null and is_instance_valid(t) and t.alive and t.targetable_by(u.side) and can_hit_domain(t) and in_range(u, t, battle)


func update(u, dt: float, battle) -> void:
	var rate: float = u.fire_rate_mult()
	if targets == "air":
		rate *= u.buff("fire_air")
	cd -= dt * rate
	anim = maxf(0.0, anim - dt * 2.5)
	retarget_t -= dt
	# finishing a telegraphed attack
	if windup_t >= 0.0:
		windup_t -= dt
		if windup_t < 0.0:
			_release(u, battle)
		return
	if burst_left > 0:
		if not u.can_fire(self):
			burst_left = 0
			return
		burst_t -= dt
		if burst_t <= 0.0:
			burst_left -= 1
			burst_t = float(d.get("burst_gap", 0.08))
			if target != null and is_instance_valid(target) and target.alive:
				_fire_projectile(u, battle, target, target.aim_point())
		return
	# keep current target while valid (no jittery switching); structures are fallback only
	if target != null and not valid_target(u, target, battle):
		target = null
	if target != null and target.is_stronghold and retarget_t <= 0.0 and priority != "structure":
		retarget_t = 0.6
		var better = battle.acquire(u, self, true)
		if better != null:
			target = better
	if target == null and retarget_t <= 0.0:
		retarget_t = 0.22 + battle.rng.randf() * 0.12
		target = battle.acquire(u, self, false)
	if target != null and target != last_target:
		# drills spin up (and heavy guns re-lay) whenever they take on a new target
		if d.has("spinup"):
			cd = maxf(cd, float(d.spinup))
		last_target = target
	if target != null:
		var to: Vector2 = target.aim_point() - mount_world(u)
		var want = atan2(to.y, to.x * u.facing)
		var track = 10.0 if not family.begins_with("aa") else 7.0 * u.buff("fire_air")
		if family in ["siege", "cannon", "mortar"]:
			track = 4.0
		aim = lerp_angle(aim, want, clampf(dt * track, 0.0, 1.0))
		if not u.can_fire(self):
			return
		if cd <= 0.0:
			if proj == "bomb" and not u.bomb_weapon_allowed():
				return
			_start_attack(u, battle)


func _start_attack(u, battle) -> void:
	cd = float(d.get("reload", 1.0))
	var w = float(d.get("windup", 0.0))
	if w > 0.0:
		windup_t = w
		windup_pos = target.position
		windup_target = target
		u.on_windup(self, w)
		return
	_fire(u, battle)


func _release(u, battle) -> void:
	windup_t = -1.0
	u.windup = 0.0
	if not u.alive:
		return
	_fire(u, battle)


func _fire(u, battle) -> void:
	anim = 1.0
	shots_fired += 1
	if proj == "bomb":
		u.ammo -= 1
	u.on_fire(self)
	var dmg = float(d.get("damage", 1)) * u.damage_mult(self, battle)
	var dtype: String = d.get("dtype", "pierce")
	var ap: bool = d.get("ap", false)
	var splash = float(d.get("splash", 0))
	var bonus: Dictionary = pen_bonus(u)
	match proj:
		"melee":
			if windup_target != null:
				# telegraphed slam lands where the target WAS — it can be dodged/escaped
				if splash > 0.0:
					battle.splash(windup_pos, splash, dmg, dtype, u.side, "ground", ap, u, bonus)
				elif is_instance_valid(windup_target) and windup_target.alive and windup_target.position.distance_to(windup_pos) < 30.0:
					battle.damage(windup_target, dmg, dtype, u, ap, bonus)
				windup_target = null
			elif target != null and is_instance_valid(target) and target.alive:
				var tgt = target   # damage can kill this unit (death bursts) and clear `target`
				var hit_at: Vector2 = tgt.aim_point()
				if splash > 0.0:
					battle.splash(tgt.position, splash, dmg, dtype, u.side, "ground", ap, u, bonus)
				else:
					battle.damage(tgt, dmg, dtype, u, ap, bonus)
				battle.fx.hit(hit_at, dtype)
				if family == "drill":
					battle.fx.sparks(hit_at, 5)
				elif u.is_mech:
					battle.fx.impact(hit_at, 0.4 + u.art_scale * 0.25)
		"cone", "steam", "flame":
			_cone(u, battle, dmg, dtype, ap, int(splash) if splash > 0 else 5)
		"boom":
			_boomstick(u, battle, dmg, dtype, bonus)
		"zap":
			_zap(u, battle, dmg, dtype)
		_:
			var b = int(d.get("burst", 1))
			if b > 1:
				burst_left = b - 1
				burst_t = float(d.get("burst_gap", 0.08))
			if target != null and is_instance_valid(target):
				_fire_projectile(u, battle, target, target.aim_point())
	battle.weapon_sound(u, self)


func _fire_projectile(u, battle, t, at: Vector2) -> void:
	var dmg = float(d.get("damage", 1)) * u.damage_mult(self, battle)
	var from = mount_world(u)
	var lead = Vector2.ZERO
	if t.domain == "air" or t.speed > 40.0:
		var travel = from.distance_to(at) / battle.projectiles.speed_of(proj)
		lead = t.velocity * travel * 0.8
	var gm = 1.0
	if t.domain == "ground" and u.domain == "air" and d.has("ground_mult"):
		gm = float(d.ground_mult)
	var sp = float(d.get("spread", 0.0))
	if sp > 0.0:
		sp *= u.buff("spread")
		lead += Vector2(battle.rng.randf_range(-sp, sp), battle.rng.randf_range(-sp, sp))
	battle.projectiles.fire(proj, from, at + lead, t, dmg * gm, d.get("dtype", "pierce"), float(d.get("splash", 0)), u.side, targets, d.get("ap", false), u, pen_bonus(u), {})
	if proj in ["shell", "bullet", "flak"]:
		battle.fx.muzzle(from, (at - from).normalized(), proj)
		if d.get("eject", false) and (proj != "bullet" or battle.rng.randf() < 0.35):
			battle.fx.casing(from, u.facing, proj == "shell")


func _cone(u, battle, dmg: float, dtype: String, ap: bool, max_hits: int) -> void:
	var from = mount_world(u)
	var hits: Array = battle.query(from, range_ + u.radius, Combat.enemy_of(u.side), targets)
	hits.sort_custom(func(x, y): return from.distance_squared_to(x.position) < from.distance_squared_to(y.position))
	var n = 0
	for h in hits:
		if n >= max_hits:
			break
		var to: Vector2 = h.aim_point() - from
		# tall frames spray down from a high nozzle: measure the cone along the ground from the frame's front
		if (h.position.x - u.position.x) * u.facing < -10.0 or (to.x * u.facing < -10.0 and not u.is_mech):
			continue
		if absf(to.y) > 70.0 + (u.art_scale * 70.0 if u.is_mech else 0.0) and h.domain == "ground":
			continue
		battle.damage(h, dmg, dtype, u, ap, {})
		battle.fx.hit(h.aim_point(), dtype)
		n += 1
	battle.fx.cone(from, u.facing, range_, proj)


## Armor penetration for mech armor: weapon `pen` + ability buffs (e.g. Deep Bore).
func pen_bonus(u) -> Dictionary:
	var b: Dictionary = d.get("bonus", {})
	var pen = float(d.get("pen", 0.0)) + u.buff_add("pen")
	if pen <= 0.0:
		return b
	var out = b.duplicate()
	out["_pen"] = pen
	return out


## Mecha boomstick: a fixed number of pellets distributed over the enemies in a short cone.
## Total hits per shot == pellets (never more), so duplicate/invalid hits are impossible.
func _boomstick(u, battle, dmg: float, dtype: String, bonus: Dictionary) -> void:
	var from = mount_world(u)
	var r = range_ + u.radius * 0.3
	var cands: Array = []
	for h in battle.query(from, r, Combat.enemy_of(u.side), targets):
		var to: Vector2 = h.aim_point() - from
		if to.x * u.facing < -6.0 or h.is_stronghold and cands.size() > 0:
			continue
		if absf(to.y) > 95.0 and h.domain == "ground":
			continue
		cands.append(h)
	if cands.is_empty() and target != null and is_instance_valid(target) and target.alive:
		cands.append(target)
	cands.sort_custom(func(x, y): return from.distance_squared_to(x.position) < from.distance_squared_to(y.position))
	var pellets = int(d.get("pellets", 6))
	var hits = 0
	if not cands.is_empty():
		var n: int = mini(cands.size(), pellets)
		for i in pellets:
			var h = cands[i % n]
			if not is_instance_valid(h) or not h.alive:
				continue
			# pellets lose power with distance
			var fall: float = clampf(1.15 - from.distance_to(h.aim_point()) / maxf(r, 1.0) * 0.5, 0.6, 1.1)
			battle.damage(h, dmg * fall, dtype, u, false, bonus)
			hits += 1
			if i < n:
				battle.fx.hit(h.aim_point(), dtype)
	battle.stats_pellet_shots += 1
	battle.stats_pellet_hits += hits
	if hits > pellets:
		battle.stats_pellet_violations += 1
	battle.fx.boomstick(from, u.facing, 1.0 + u.art_scale * 0.25)
	battle.fx.casing(from, u.facing, true)
	battle.shake(1.5 + u.art_scale)
	u.recoil = 1.0


## Electrical arc: hits the target and jumps to a limited number of neighbours, staying
## inside this weapon's permitted combat layers and jump range.
func _zap(u, battle, dmg: float, dtype: String) -> void:
	if target == null or not is_instance_valid(target) or not target.alive:
		return
	var hit: Array = [target]
	var cur = target
	var jumps = int(d.get("chain", 0))
	var jr = float(d.get("chain_range", 70))
	while hit.size() <= jumps:
		var best = null
		var bd = INF
		for e in battle.query(cur.aim_point(), jr, Combat.enemy_of(u.side), targets):
			if e in hit or e.is_stronghold:
				continue
			var dd: float = cur.aim_point().distance_to(e.aim_point())
			if dd < bd:
				bd = dd
				best = e
		if best == null:
			break
		hit.append(best)
		cur = best
	var prev = mount_world(u)
	var k = 1.0
	for e in hit:
		battle.fx.bolt(prev, e.aim_point())
		prev = e.aim_point()
		battle.damage(e, dmg * k, dtype, u, false, {})
		k *= 0.7
	battle.stats_chain_max = maxi(battle.stats_chain_max, hit.size())