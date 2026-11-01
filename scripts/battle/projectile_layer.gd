class_name ProjectileLayer
extends Node2D
## Pooled projectiles drawn by a single canvas item. Projectiles fly to an aim point fixed at
## launch (plus lead). If the target dies or becomes invalid they do NOT chase it: they land
## at their aim point (splash still resolves) or fizzle. Homing bolts fizzle when orphaned.

class Shot:
	var active = false
	var kind = "bullet"
	var pos = Vector2.ZERO
	var start = Vector2.ZERO
	var end = Vector2.ZERO
	var vel = Vector2.ZERO
	var target = null
	var dmg = 0.0
	var dtype = "pierce"
	var splash = 0.0
	var side = 0
	var targets = "ground"
	var ap = false
	var src = null
	var bonus = {}
	var t = 0.0
	var dur = 0.1
	var arc_h = 0.0
	var spin = 0.0
	var extra = {}
	var src_x = 0.0

const SPEED := {"bullet": 1100.0, "arrow": 560.0, "shard": 650.0, "shell": 780.0, "flak": 760.0,
	"arc": 380.0, "spit": 360.0, "bolt": 340.0, "bomb": 0.0, "volley": 1000.0}

var battle
var pool: Array = []
var active_count := 0
var capacity := 260
var stats_fizzled := 0
var stats_overflow := 0


func setup(b, cap: int) -> void:
	battle = b
	capacity = cap
	for i in capacity:
		pool.append(Shot.new())
	z_index = 300


func speed_of(kind: String) -> float:
	return SPEED.get(kind, 800.0) if kind != "bomb" else 300.0


func fire(kind: String, from: Vector2, to: Vector2, target, dmg: float, dtype: String, splash: float, side: int, targets: String, ap: bool, src, bonus: Dictionary, extra: Dictionary = {}) -> void:
	var s: Shot = null
	for p in pool:
		if not p.active:
			s = p
			break
	if s == null:
		# pool exhausted: resolve instantly rather than lose the shot (no unbounded growth)
		stats_overflow += 1
		battle.projectile_ctx = true
		battle.projectile_src_x = from.x
		_impact_at(to, target, dmg, dtype, splash, side, targets, ap, src, bonus, kind)
		battle.projectile_ctx = false
		return
	s.active = true
	s.kind = kind
	s.pos = from
	s.start = from
	s.end = to
	s.target = target
	s.dmg = dmg
	s.dtype = dtype
	s.splash = splash
	s.side = side
	s.targets = targets
	s.ap = ap
	s.src = src
	s.bonus = bonus
	s.t = 0.0
	s.spin = 0.0
	s.extra = extra
	s.src_x = from.x
	if kind == "spit" and target != null and is_instance_valid(target) and target.domain == "air":
		s.kind = "spit_air"
	var dist = from.distance_to(to)
	s.dur = maxf(0.05, dist / speed_of(kind))
	s.arc_h = 0.0
	if s.kind == "arc" or s.kind == "spit":
		s.arc_h = clampf(dist * 0.35, 40.0, 160.0)
	if kind == "bomb":
		s.vel = Vector2((src.velocity.x if src != null and is_instance_valid(src) else 0.0) * 0.5, 40.0)
		s.end = Vector2(from.x, Combat.GROUND_Y)
		s.dur = 3.0
	active_count += 1


func step(dt: float) -> void:
	for s in pool:
		if not s.active:
			continue
		s.t += dt
		s.spin += dt * 12.0
		match s.kind:
			"bomb":
				s.vel.y += 900.0 * dt
				s.pos += s.vel * dt
				if s.pos.y >= Combat.GROUND_Y - 4.0:
					_land(s, Vector2(s.pos.x, Combat.GROUND_Y - 4.0))
			"bolt":
				if s.target == null or not is_instance_valid(s.target) or not s.target.alive:
					stats_fizzled += 1
					battle.fx.puff(s.pos, Color(0.43, 1.0, 0.55, 0.6))
					_release(s)
					continue
				var to: Vector2 = s.target.aim_point() - s.pos
				if to.length() < 14.0:
					_land(s, s.pos)
					continue
				s.pos += to.normalized() * SPEED.bolt * dt
				if s.t > 4.0:
					_release(s)
			_:
				var k = clampf(s.t / s.dur, 0.0, 1.0)
				s.pos = s.start.lerp(s.end, k)
				if s.arc_h > 0.0:
					s.pos.y -= sin(k * PI) * s.arc_h
				if k >= 1.0:
					_land(s, s.end)
	queue_redraw()


func _release(s: Shot) -> void:
	s.active = false
	s.target = null
	s.src = null
	active_count -= 1


func _land(s: Shot, at: Vector2) -> void:
	battle.projectile_ctx = true
	battle.projectile_src_x = s.src_x
	_impact_at(at, s.target, s.dmg, s.dtype, s.splash, s.side, s.targets, s.ap, s.src, s.bonus, s.kind)
	var ex: Dictionary = s.extra
	if not ex.is_empty():
		var srcv = s.src if s.src != null and is_instance_valid(s.src) else null
		# piercing round: continues through a limited number of ground targets behind the impact
		if int(ex.get("pierce", 0)) > 0:
			var n = 0
			var dirx = float(ex.get("dir", 1.0))
			var cands: Array = battle.query(at + Vector2(dirx * 90.0, 0), 100.0, Combat.enemy_of(s.side), "ground")
			cands.sort_custom(func(a, b): return absf(a.position.x - at.x) < absf(b.position.x - at.x))
			for e in cands:
				if n >= int(ex.pierce) or e == s.target or (e.position.x - at.x) * dirx < 0.0:
					continue
				battle.damage(e, s.dmg * 0.6, s.dtype, srcv, s.ap, s.bonus)
				battle.fx.hit(e.aim_point(), "blast")
				n += 1
			battle.fx.line_flash(at, at + Vector2(dirx * 180.0, 0))
		# cluster shell: a limited number of sub-explosions around the impact
		if int(ex.get("cluster", 0)) > 0:
			for i in int(ex.cluster):
				var off = Vector2((i - (int(ex.cluster) - 1) * 0.5) * 34.0 + battle.rng.randf_range(-8, 8), battle.rng.randf_range(-6, 6))
				var p: Vector2 = Vector2(at.x + off.x, Combat.GROUND_Y - 6.0)
				battle.splash(p, float(ex.get("cluster_radius", 30)), float(ex.get("cluster_damage", 20)), s.dtype, s.side, "ground", false, srcv, {})
				battle.fx.explosion(p, 0.6, "fire")
	battle.projectile_ctx = false
	_release(s)


func _impact_at(at: Vector2, target, dmg: float, dtype: String, splash: float, side: int, targets: String, ap: bool, src, bonus: Dictionary, kind: String) -> void:
	var srcv = src if src != null and is_instance_valid(src) else null
	if splash > 0.0 and kind != "cone":
		var dom = "air" if kind == "flak" or kind == "spit_air" else ("ground" if kind in ["shell", "arc", "spit", "bomb"] and at.y > Combat.LOW_AIR_Y else "any")
		if kind == "shell" and target != null and is_instance_valid(target) and target.domain == "air":
			dom = "air"
		battle.splash(at, splash, dmg, dtype, side, dom, ap, srcv, bonus)
		match kind:
			"flak":
				battle.fx.flak_burst(at)
			"spit", "spit_air":
				battle.fx.splat(at)
			_:
				battle.fx.explosion(at, clampf(splash / 40.0, 0.5, 1.6), "fire")
				if splash >= 40.0:
					battle.shake(2.5)
				Audio.play("explosion" if splash >= 40.0 else "mortar", at.x, -8.0)
		return
	# direct hit: only if the original target is still valid and near the impact point
	if target != null and is_instance_valid(target) and target.alive and target.targetable_by(side):
		var tol: float = target.radius + 14.0
		if target.is_structure:
			tol = target.radius + 40.0
		if target.aim_point().distance_to(at) <= tol or target.position.distance_to(at) <= tol:
			battle.damage(target, dmg, dtype, srcv, ap, bonus)
			battle.fx.hit(at, dtype)
			return
	stats_fizzled += 1
	if at.y > Combat.GROUND_Y - 30.0:
		battle.fx.puff(at, Color(0.55, 0.48, 0.38, 0.5))


func clear_all() -> void:
	for s in pool:
		if s.active:
			_release(s)


func _draw() -> void:
	var vr: Rect2 = battle.view_rect if battle != null else Rect2()
	for s in pool:
		if not s.active:
			continue
		if vr.size != Vector2.ZERO and (s.pos.x < vr.position.x - 40.0 or s.pos.x > vr.end.x + 40.0):
			continue
		var dirv: Vector2 = (s.end - s.start).normalized() if s.kind != "bomb" else s.vel.normalized()
		match s.kind:
			"bullet", "volley":
				draw_line(s.pos - dirv * 14.0, s.pos, Color(1.0, 0.9, 0.55, 0.9), 2.0)
			"arrow":
				draw_line(s.pos - dirv * 14.0, s.pos, Color(0.85, 0.8, 0.65), 1.8)
				draw_line(s.pos, s.pos - dirv.rotated(0.5) * 5.0, Color(0.9, 0.9, 0.85), 1.5)
				draw_line(s.pos, s.pos - dirv.rotated(-0.5) * 5.0, Color(0.9, 0.9, 0.85), 1.5)
			"shard":
				draw_line(s.pos - dirv * 10.0, s.pos, Painter.OUT, 4.0)
				draw_line(s.pos - dirv * 10.0, s.pos, Painter.BONE, 2.5)
			"shell":
				draw_line(s.pos - dirv * 18.0, s.pos, Color(1, 0.75, 0.4, 0.35), 3.0)
				draw_circle(s.pos, 3.6, Painter.OUT)
				draw_circle(s.pos, 2.6, Color(0.35, 0.33, 0.32))
			"flak":
				draw_line(s.pos - dirv * 10.0, s.pos, Color(1, 0.85, 0.5, 0.6), 2.0)
				draw_circle(s.pos, 2.5, Color(0.9, 0.8, 0.5))
			"arc":
				draw_circle(s.pos, 4.5, Painter.OUT)
				draw_circle(s.pos, 3.5, Painter.COAL)
				draw_circle(s.pos + Vector2(cos(s.spin), sin(s.spin)) * 5.0, 1.6, Color(1, 0.75, 0.3))
			"spit", "spit_air":
				draw_circle(s.pos, 5.0, Color(0.25, 0.35, 0.1))
				draw_circle(s.pos, 3.8, Color(0.6, 0.9, 0.2))
				draw_line(s.pos, s.pos - dirv * 8.0, Color(0.6, 0.9, 0.2, 0.5), 2.0)
			"bolt":
				Painter.glow(self, s.pos, 12.0, Color(0.43, 1.0, 0.55, 0.9))
				draw_circle(s.pos, 3.5, Color(0.8, 1.0, 0.85))
			"bomb":
				draw_circle(s.pos, 5.0, Painter.OUT)
				draw_circle(s.pos, 4.0, Painter.COAL)
				draw_line(s.pos - dirv * 4.0, s.pos - dirv * 9.0, Painter.BRASS, 3.0)
