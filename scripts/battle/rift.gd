class_name Rift
extends RefCounted
## M008 Act V systems, run by Battle every step (static helpers over the battle's state, like Foundry):
##   rift tears    every `interval` s a tear opens at a seeded x: a `warn` s telegraph (a crack of violet light), then
##                 a portal with HP stays open for `open` s and spills `spill` undead from the stage's `pool`, unless
##                 the dwarves destroy it first (any weapon that can hit a ground structure can)
##   eclipse       every `interval` s the dead sun goes out for `duration` s: ranged weapons on BOTH sides lose 25 %
##                 range, except units that carry light or spot (scouts, spotter balloons, rune-sight scouts, the
##                 night seers' reveal aura) and anything standing inside such a unit's light radius
##   soul storm    every `interval` s soul wisps drift out of the rift side at low altitude (mid band); each heals the
##                 undead it passes and burns the dwarves under it; flak, AA and aircraft can shoot them down
##   obelisk ward  rift obelisks power the undead line: undead within OBELISK_R of a live obelisk take 15 % less damage
## Tears and wisps are real undead units (aux entries `rift_tear`, `soul_wisp`, flagged `transient`): they can be
## targeted and killed, but they never count as support structures, toward challenges or as encountered enemies.
## All randomness comes from the battle's own seeded `rift_rng` (deterministic per stage); visuals go through
## HazardLayer (batched) and the pooled FxLayer.

const OBELISK_R := 200.0
const OBELISK_DR := 0.15
const TEAR_CAP := 4
const WISP_CAP := 8
const LIGHT_R := 150.0        # light radius of a lamp-carrying unit without a spotter range


# ================================================================== setup (called by WaveDirector)
static func set_tears(b, h: Dictionary) -> void:
	b.tear_def = h
	b.tear_t = float(h.get("first", float(h.get("interval", 30.0)) * 0.6))


static func set_eclipse(b, h: Dictionary) -> void:
	b.eclipse_def = h
	b.eclipse_t = float(h.get("first", 45.0))
	b.eclipse_left = 0.0


static func set_souls(b, h: Dictionary) -> void:
	b.soul_def = h
	b.soul_t = float(h.get("first", float(h.get("interval", 11.0)) * 0.8))


# ================================================================== per-step
static func tick(b, dt: float) -> void:
	if not b.tear_def.is_empty() or not b.tears.is_empty():
		_tick_tears(b, dt)
	if not b.eclipse_def.is_empty():
		_tick_eclipse(b, dt)
	if not b.soul_def.is_empty() or not b.wisps.is_empty():
		_tick_souls(b, dt)
	b._rift_ward_t -= dt
	if b._rift_ward_t <= 0.0:
		b._rift_ward_t = 0.5
		_obelisk_ward(b)
	if b.hazard_layer != null and (not b.tears.is_empty() or b.eclipse_k > 0.0 or not b.wisps.is_empty() or not b.obelisk_links.is_empty() \
			or b.crowned != null or b.sky_gale_t > 0.0 or b.sky_pull_t > 0.0 or b.lich_rift > 0.0):
		b.hazard_layer.queue_redraw()
		b.hazard_layer.rift_item.queue_redraw()


## Remove a hazard entity without a death (no bounty, no kill, no corpse).
static func despawn(u) -> void:
	if u == null or not is_instance_valid(u) or not u.alive:
		return
	u.alive = false
	u.hp = 0.0
	u.dying_t = u.death_time + 1.0
	u.visible = false


# ------------------------------------------------------------------ rift tears
static func _tick_tears(b, dt: float) -> void:
	var h: Dictionary = b.tear_def
	if not h.is_empty():
		b.tear_t -= dt
		if b.tear_t <= 0.0:
			b.tear_t = float(h.get("interval", 30.0))
			if b.tears.size() < TEAR_CAP:
				open_tear(b, -1.0)
	var keep: Array = []
	for tr in b.tears:
		tr.t += dt
		if tr.unit == null:
			if tr.t >= float(tr.warn):
				# the crack splits open: the portal becomes a target
				var u = b.spawn_unit("rift_tear", 1, Vector2(float(tr.x), 0), true)
				if u != null:
					u.max_hp = float(tr.hp)
					u.hp = u.max_hp
					tr.unit = u
					b.fx.raise(Vector2(float(tr.x), Combat.GROUND_Y - 50.0))
					b.fx.explosion(Vector2(float(tr.x), Combat.GROUND_Y - 40.0), 0.6, "necro")
				Audio.play("rift_open", float(tr.x), -4.0)
			keep.append(tr)
			continue
		if not is_instance_valid(tr.unit) or not tr.unit.alive:
			# destroyed before it could spill
			b.stats_tears_closed += 1
			b.fx.explosion(Vector2(float(tr.x), Combat.GROUND_Y - 40.0), 0.8, "necro")
			b.fx.dust(Vector2(float(tr.x), Combat.GROUND_Y), 1.0)
			Audio.play("rift_close", float(tr.x), -4.0)
			continue
		if tr.t >= float(tr.warn) + float(tr.open):
			_spill(b, tr)
			despawn(tr.unit)
			continue
		keep.append(tr)
	b.tears = keep


## Open a tear at x (x < 0: a seeded position in the hazard's span, kept off the dwarven stronghold).
static func open_tear(b, x: float, h_over: Dictionary = {}) -> Dictionary:
	var h: Dictionary = b.tear_def.duplicate()
	h.merge(h_over, true)
	if x < 0.0:
		x = b.rift_rng.randf_range(float(h.get("x0", 900.0)), float(h.get("x1", 2000.0)))
	x = clampf(x, Combat.DWARF_BASE_X + 260.0, Combat.UNDEAD_BASE_X - 160.0)
	var tr = {"x": x, "t": 0.0, "warn": float(h.get("warn", 2.0)), "open": float(h.get("open", 6.0)), "hp": float(h.get("hp", 380.0)),
		"spill": int(h.get("spill", 3)), "pool": h.get("pool", ["riftbound_legionary"]), "unit": null, "seed": b.rift_rng.randi() % 997}
	b.tears.append(tr)
	b.stats_tears += 1
	b.fx.telegraph(Vector2(x, Combat.GROUND_Y), 46.0, float(tr.warn), Color(0.72, 0.4, 1.0))
	Audio.play("rift_crack", x, -6.0)
	return tr


static func _spill(b, tr: Dictionary) -> void:
	var pool: Array = tr.pool
	b.stats_tears_spilled += 1
	for i in int(tr.spill):
		var e = String(pool[(i + int(tr.seed)) % pool.size()])
		var air = Registry.entry(e).get("domain", "ground") == "air"
		var pos = Vector2(float(tr.x) + 14.0 - i * 16.0, 0.0 if not air else Combat.GROUND_Y - 160.0)
		var z = b.spawn_unit(e, 1, pos, true)
		if z != null:
			b.stats_tear_spawns += 1
			b.fx.raise(z.position + Vector2(0, -24))
	b.fx.explosion(Vector2(float(tr.x), Combat.GROUND_Y - 40.0), 1.0, "necro")
	b.shake(2.0)
	Audio.play("rift_spill", float(tr.x), -2.0)


# ------------------------------------------------------------------ eclipse
static func _tick_eclipse(b, dt: float) -> void:
	var h: Dictionary = b.eclipse_def
	if b.eclipse_left > 0.0:
		b.eclipse_left -= dt
		if b.eclipse_left <= 0.0:
			b.eclipse_on = false
			b.eclipse_t = float(h.get("interval", 58.0))
			Audio.play("eclipse_end", -1.0, -6.0, 0.0)
	else:
		b.eclipse_t -= dt
		if b.eclipse_t <= 0.0:
			b.eclipse_left = float(h.get("duration", 16.0))
			b.eclipse_on = true
			b.stats_eclipses += 1
			b._light_t = 0.0
			Audio.play("eclipse", -1.0, -2.0, 0.0)
	# the visual fade (presentation only): 1.2 s in, 1.2 s out
	var target = 1.0 if b.eclipse_on else 0.0
	b.eclipse_k = move_toward(b.eclipse_k, target, dt / 1.2)
	if b.eclipse_on:
		b._light_t -= dt
		if b._light_t <= 0.0:
			b._light_t = 0.25
			update_light(b)


## Light sources: dwarven spotters/scouts/lamp units and undead with a reveal aura. A unit is lit if it carries a
## light or stands inside a source's light radius on its own side.
static func light_radius(u) -> float:
	if u.def.has("spotter"):
		return float(u.def.spotter.get("range", 260.0))
	if u.def.get("light", false):
		return LIGHT_R
	if u.def.get("reveal_aura", false):
		return 220.0
	return 0.0


static func update_light(b) -> void:
	b.light_sources.clear()
	for s in 2:
		var srcs: Array = []
		for u in b.by_side[s]:
			if u.alive and not u.is_stronghold:
				var r = light_radius(u)
				if r > 0.0:
					srcs.append([u.position.x, r])
					b.light_sources.append({"x": u.position.x, "y": u.position.y, "r": r, "side": s})
		for u in b.by_side[s]:
			if not u.alive:
				continue
			var lit = u.is_stronghold or light_radius(u) > 0.0
			if not lit:
				for sr in srcs:
					if absf(u.position.x - float(sr[0])) <= float(sr[1]):
						lit = true
						break
			u.lit = lit


## Range multiplier for a weapon during an eclipse (1.0 when lit, melee, or no eclipse).
static func range_mult(b, u, w) -> float:
	if not b.eclipse_on or u.lit or w.proj == "melee" or u.is_stronghold:
		return 1.0
	return float(b.eclipse_def.get("range_mult", 0.75))


# ------------------------------------------------------------------ soul storm
static func _tick_souls(b, dt: float) -> void:
	var h: Dictionary = b.soul_def
	if not h.is_empty():
		b.soul_t -= dt
		if b.soul_t <= 0.0:
			b.soul_t = float(h.get("interval", 11.0)) / maxf(0.5, b.soul_boost)
			for i in int(h.get("wisps", 2)):
				if b.wisps.size() >= WISP_CAP:
					break
				spawn_wisp(b, Combat.UNDEAD_BASE_X - 90.0 - i * 70.0, h)
	var keep: Array = []
	var tick_now = false
	b._wisp_tick -= dt
	if b._wisp_tick <= 0.0:
		b._wisp_tick = 0.5
		tick_now = true
	for w in b.wisps:
		var u = w.unit
		if u == null or not is_instance_valid(u) or not u.alive:
			if u != null and is_instance_valid(u) and u.hp <= 0.0 and w.get("shot", false) == false:
				w.shot = true
				b.stats_wisps_shot += 1
				b.fx.raise(u.position)
			continue
		w.t += dt
		u.position.x -= float(w.speed) * dt
		u.position.y = float(w.y) + sin(w.t * 2.1 + float(w.ph)) * 10.0
		if u.position.x < Combat.DWARF_BASE_X + 30.0:
			despawn(u)
			continue
		if tick_now:
			_wisp_touch(b, u, w)
		keep.append(w)
	b.wisps = keep


static func spawn_wisp(b, x: float, h: Dictionary) -> void:
	var y = Combat.GROUND_Y - b.rift_rng.randf_range(112.0, 128.0)
	var u = b.spawn_unit("soul_wisp", 1, Vector2(x, y), true)
	if u == null:
		return
	u.max_hp = float(h.get("hp", 90.0))
	u.hp = u.max_hp
	u.position = Vector2(x, y)
	b.wisps.append({"unit": u, "t": 0.0, "y": y, "ph": b.rift_rng.randf() * TAU, "speed": float(h.get("speed", 44.0)) * b.rift_rng.randf_range(0.85, 1.15),
		"r": float(h.get("radius", 58.0)), "heal": float(h.get("heal", 16.0)), "dmg": float(h.get("damage", 12.0)), "shot": false})
	b.stats_wisps += 1


static func _wisp_touch(b, u, w: Dictionary) -> void:
	var r: float = w.r
	var x = u.position.x
	# burn the dwarves under (and around) the wisp: ground units within r horizontally, flyers within r
	for d in b.by_side[0]:
		if not d.alive or d.is_stronghold or d.is_static:
			continue
		var near = absf(d.position.x - x) <= r if d.domain == "ground" else d.position.distance_to(u.position) <= r * 1.2
		if near:
			var dealt = d.take_damage(float(w.dmg) * 0.5, u)
			b.stats_wisp_dmg += dealt
			if not d.alive:
				d.last_hit_by = "soul storm"
	# heal the undead it passes (never bosses, structures or other hazard entities)
	for e in b.by_side[1]:
		if not e.alive or e.is_boss or e.is_static or e.hp >= e.max_hp:
			continue
		if absf(e.position.x - x) <= r:
			var before = e.hp
			e.hp = minf(e.max_hp, e.hp + float(w.heal) * 0.5)
			b.stats_wisp_heal += e.hp - before


# ------------------------------------------------------------------ obelisk ward
static func _obelisk_ward(b) -> void:
	b.obelisk_links.clear()
	var obs: Array = []
	for u in b.by_side[1]:
		if u.alive and u.id == "rift_obelisk":
			obs.append(u)
	if obs.is_empty():
		return
	for e in b.by_side[1]:
		if not e.alive or e.is_static or e.is_stronghold or e.domain != "ground":
			continue
		for o in obs:
			if absf(e.position.x - o.position.x) <= OBELISK_R:
				e.aura_dr = maxf(e.aura_dr if e.aura_dr_t > b.time else 0.0, OBELISK_DR)
				e.aura_dr_t = b.time + 0.6
				if b.obelisk_links.size() < 14:
					b.obelisk_links.append([o, e])
				b.stats_ward_ticks += 1
				break
