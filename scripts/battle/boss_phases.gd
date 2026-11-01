class_name BossPhases
extends RefCounted
## M005 boss encounters: each Act II boss changes behaviour, with a warning, when it drops to 50 %.
##   root_eruption  Blightroot Behemoth: telegraphed root strikes under the dwarven artillery line, on a cooldown
##   court_heralds  Plague Regent: the Court summons plague heralds (re-summoned if they all fall) and the miasma thickens
##   perch          Gravewing Matriarch: lands on her nest for a few seconds (ground-targetable) and wakes the flyers
##   wyrm_dive      Bone Wyrm (M006): dives into the chasm, erupts under a telegraphed spot, then lies on the
##                  ground (ground-targetable) for a few seconds before taking off again
##   escort_shield  Hollow Admiral (M006): two escort airbarges arrive; the Admiral is shielded until one falls
##   storm_tyrant   Dread Sky Tyrant (M006): the storm intensifies and hunts dwarven aircraft; at 25 % it lands
##                  briefly to breathe on the ground front
##   titan_reclaim  Fallen Titan (M007): tears a wreck from the ground and reclaims it as an escort (the graveyard's
##                  own wreck the first time, then the nearest dwarven wreck if one lies close); each time its plates
##                  fall away and the core is exposed (+25 % damage taken for a few seconds)
##   vent_sequence  Ashen Forge Tyrant (M007): the furnace vents across the arena fire one after another in a
##                  telegraphed sweep toward the dwarven line
##   corpse_throw   Corpse Colossus (M007): hurls corpses at the dwarven stronghold from range; at 25 % it
##                  disgorges corrupted war machines once
## The data lives in the boss definition's "phase" dict (tools/gen_data.py BOSS_PHASES).


static func step(u, b, dt: float) -> void:
	var ph: Dictionary = u.def.get("phase", {})
	if ph.is_empty() or not u.alive:
		return
	if not u.phase_on:
		if u.hp > u.max_hp * float(ph.get("at", 0.5)):
			return
		u.phase_on = true
		u.phase_t = 0.0
		b.stats_phase_changes += 1
		b.alert.emit(String(ph.get("alert", "The boss changes its tactics!")))
		b.fx.raise(u.aim_point())
		Audio.play("giant_roar", u.position.x, 3.0)
		_enter(u, b, ph)
	u.phase_t -= dt
	match String(ph.kind):
		"root_eruption":
			if u.phase_t <= 0.0 and u.stun_t <= 0.0:
				u.phase_t = float(ph.get("interval", 15.0))
				_roots(u, b, ph)
		"court_heralds":
			u.phase_heralds = u.phase_heralds.filter(func(h): return is_instance_valid(h) and h.alive)
			if u.phase_heralds.is_empty() and u.phase_t <= 0.0:
				u.phase_t = float(ph.get("respawn", 40.0))
				_heralds(u, b, ph)
		"perch":
			if u.perch_t > 0.0:
				u.perch_t -= dt
				if u.perch_t <= 0.0:
					_take_off(u, b)
			elif u.phase_t <= 0.0 and u.stun_t <= 0.0 and u.ability_wind < 0.0:
				_land(u, b, ph)
		"wyrm_dive":
			if u.dive_t > 0.0:
				u.dive_t -= dt
				if u.dive_t <= 0.0:
					_erupt(u, b, ph)
			elif u.perch_t > 0.0:
				u.perch_t -= dt
				if u.perch_t <= 0.0:
					_take_off(u, b)
					u.phase_t = float(ph.get("interval", 22.0))
			elif u.phase_t <= 0.0 and u.stun_t <= 0.0 and u.ability_wind < 0.0:
				_dive(u, b, ph)
		"escort_shield":
			if u.shielded:
				u.phase_heralds = u.phase_heralds.filter(func(h): return is_instance_valid(h) and h.alive)
				if u.phase_heralds.size() < int(u.get_meta("escorts", 2)):
					u.shielded = false
					b.stats_shield_breaks += 1
					b.alert.emit("An escort is down — the Admiral's shield breaks!")
					b.fx.raise(u.aim_point())
					Audio.play("thunder", u.position.x, -4.0)
		"titan_reclaim":
			if u.weak_core_t > 0.0:
				u.weak_core_t -= dt
			if u.phase_t <= 0.0 and u.stun_t <= 0.0:
				u.phase_t = float(ph.get("interval", 28.0))
				_titan_reclaim(u, b, ph)
		"vent_sequence":
			if u.phase_t <= 0.0:
				u.phase_t = float(ph.get("interval", 16.0))
				_vent_sweep(u, b, ph)
		"corpse_throw":
			if u.phase_t <= 0.0 and u.stun_t <= 0.0:
				u.phase_t = float(ph.get("interval", 11.0))
				_corpse_throw(u, b, ph)
			if not u.has_meta("disgorged") and u.hp <= u.max_hp * float(ph.get("machine_at", 0.25)):
				u.set_meta("disgorged", true)
				for grp in ph.get("machines", []):
					for i in int(grp[1]):
						var m = b.spawn_unit(String(grp[0]), 1, Vector2(u.position.x - 90.0 - i * 40.0, 0), true)
						if m != null:
							b.fx.raise(m.position + Vector2(0, -30))
							b.fx.splat(m.position + Vector2(0, -20))
							b.stats_phase_spawns += 1
				b.shake(6.0)
				Audio.play("giant_roar", u.position.x, 4.0)
				b.alert.emit(String(ph.get("machine_alert", "The Colossus disgorges a war machine!")))
		"storm_tyrant":
			if u.perch_t > 0.0:
				u.perch_t -= dt
				if u.perch_t <= 0.0:
					_take_off(u, b)
			elif not u.has_meta("landed") and u.hp <= u.max_hp * float(ph.get("land_at", 0.25)) and u.stun_t <= 0.0:
				u.set_meta("landed", true)
				_land_front(u, b, float(ph.get("land_time", 8.0)))
				b.alert.emit(String(ph.get("land_alert", "The Tyrant lands!")))


static func _enter(u, b, ph: Dictionary) -> void:
	match String(ph.kind):
		"court_heralds":
			_heralds(u, b, ph)
			u.phase_t = float(ph.get("respawn", 40.0))
			if b.director != null:
				b.director.hazard_boost = float(ph.get("miasma_boost", 1.6))
				# the court's breath: an immediate cloud so the change reads at once
				b.add_miasma(u.position.x - 60.0, 120.0, 9.0 * float(ph.get("miasma_boost", 1.6)), 20.0, 18.0)
		"root_eruption":
			u.phase_t = 0.5
		"perch":
			u.phase_t = 0.2
		"wyrm_dive":
			u.phase_t = 0.6
		"escort_shield":
			_heralds(u, b, ph)
			u.set_meta("escorts", u.phase_heralds.size())
			u.shielded = not u.phase_heralds.is_empty()
		"titan_reclaim", "corpse_throw":
			u.phase_t = 0.6
		"vent_sequence":
			u.phase_t = 0.8
			# the arena's vents show their grates even where the stage hazard has none
			for x in ph.get("vents", []):
				var have = false
				for v in b.vents:
					if absf(float(v.x) - float(x)) < 40.0:
						have = true
						break
				if not have:
					b.vents.append({"x": float(x), "next": 1e9, "glow": 0.0})
		"storm_tyrant":
			b.lightning_air_bias = float(ph.get("air_bias", 0.6))
			if b.director != null:
				b.director.storm_boost = float(ph.get("storm_boost", 1.8))
			b.flash_t = 0.3


## Roots erupt under the dwarven artillery line: guns, mortars and anything holding back.
static func _roots(u, b, ph: Dictionary) -> void:
	var cands: Array = []
	for d in b.by_side[0]:
		if d.alive and d.domain == "ground" and not d.is_static and (d.cls == "artillery" or d.hold_behind):
			cands.append(d)
	if cands.is_empty():
		for d2 in b.by_side[0]:
			if d2.alive and d2.domain == "ground" and not d2.is_static:
				cands.append(d2)
	# rear-most first: the roots go for the line behind the fighting
	cands.sort_custom(func(a, c): return a.position.x < c.position.x)
	var placed: Array = []
	for d in cands:
		if placed.size() >= int(ph.get("count", 4)):
			break
		var x: float = d.position.x
		var close = false
		for p in placed:
			if absf(p - x) < float(ph.get("radius", 60)) * 1.2:
				close = true
				break
		if close:
			continue
		placed.append(x)
		b.schedule_strike(x, float(ph.get("radius", 60)), float(ph.get("damage", 150)), float(ph.get("delay", 1.5)), 0, float(ph.get("slow", 0.5)), "roots")
	if not placed.is_empty():
		b.stats_root_eruptions += placed.size()
		Audio.play("rockfall", u.position.x, -2.0)


static func _heralds(u, b, ph: Dictionary) -> void:
	for grp in ph.get("spawn", []):
		for i in int(grp[1]):
			var air = Registry.entry(String(grp[0])).get("domain", "ground") == "air"
			var pos = Vector2(u.position.x + 40.0 + i * 30.0, 0) if not air else Vector2(u.position.x + 120.0 - i * 240.0, u.position.y + 40.0 - i * 20.0)
			var h = b.spawn_unit(String(grp[0]), 1, pos, true)
			if h != null:
				u.phase_heralds.append(h)
				b.fx.raise(h.position + Vector2(0, -20))
				b.stats_phase_spawns += 1


static func _land(u, b, ph: Dictionary) -> void:
	u.perch_t = float(ph.get("perch_time", 8.0))
	u.phase_t = float(ph.get("interval", 26.0)) + u.perch_t
	u.domain = "ground"
	u.lane = -48.0          # perched up on the nest's rim rather than sunk into the ground line
	u.position = Vector2(float(ph.get("nest_x", 2250)), Combat.GROUND_Y)
	b.stats_perches += 1
	b.fx.dust(u.position, 2.0)
	b.shake(5.0)
	Audio.play("giant_roar", u.position.x, 4.0)
	for grp in ph.get("wake", []):
		for i in int(grp[1]):
			var f = b.spawn_unit(String(grp[0]), 1, Vector2(u.position.x - 40.0 - i * 20.0, 260.0 + (i % 3) * 30.0), true)
			if f != null:
				b.stats_phase_spawns += 1


static func _take_off(u, b) -> void:
	u.perch_t = 0.0
	u.domain = "air"
	u.position.y = Combat.GROUND_Y - 120.0
	b.fx.dust(Vector2(u.position.x, Combat.GROUND_Y), 1.6)


# ---------------------------------------------------------------- M006 Act III bosses
## Bone Wyrm: vanishes into the chasm; a telegraphed eruption spot appears under the densest dwarven ground cluster.
static func _dive(u, b, ph: Dictionary) -> void:
	var tgt = b.densest_enemy_ground(u)
	var x: float = clampf(tgt.x, 300.0, 2250.0) if tgt != null else clampf(u.position.x - 200.0, 400.0, 2200.0)
	u.dive_t = float(ph.get("under", 2.6))
	u.burrowed = true
	u.set_meta("dive_x", x)
	b.fx.dust(Vector2(u.position.x, Combat.GROUND_Y), 2.2)
	b.shake(4.0)
	b.schedule_strike(x, float(ph.get("radius", 95)), float(ph.get("damage", 120)), u.dive_t, 0, 0.0, "roots")
	b.stats_wyrm_dives += 1
	Audio.play("giant_roar", u.position.x, 2.0)


static func _erupt(u, b, ph: Dictionary) -> void:
	u.burrowed = false
	u.domain = "ground"
	u.lane = -10.0
	u.position = Vector2(float(u.get_meta("dive_x", u.position.x)), Combat.GROUND_Y + u.lane)
	u.perch_t = float(ph.get("exposed", 6.0))
	b.fx.dust(u.position, 2.6)
	b.fx.bones(u.position + Vector2(0, -40))
	b.shake(7.0)
	Audio.play("rockfall", u.position.x, 2.0)


## Dread Sky Tyrant: lands just ahead of the dwarven front and breathes on the line for a few seconds.
static func _land_front(u, b, dur: float) -> void:
	var front = b.front_x(0, null)
	var x = clampf((float(front) if front != null else 900.0) + 150.0, 500.0, 2250.0)
	u.perch_t = dur
	u.domain = "ground"
	u.lane = -20.0
	u.position = Vector2(x, Combat.GROUND_Y + u.lane)
	b.stats_perches += 1
	b.fx.dust(u.position, 2.6)
	b.shake(8.0)
	Audio.play("giant_roar", u.position.x, 5.0)


# ---------------------------------------------------------------- M007 Act IV bosses
## Fallen Titan: rips a wreck out of the ground and raises it as an escort; its own plates tear away (weak core).
static func _titan_reclaim(u, b, ph: Dictionary) -> void:
	var w = Foundry.wreck_near(b, u.position.x, 700.0)
	var first = not u.has_meta("reclaimed_once")
	if w == null and not first:
		return
	u.set_meta("reclaimed_once", true)
	var uid = String(ph.get("escort", "cursed_ironclad"))
	var x = u.position.x - 120.0
	if w != null:
		uid = Foundry.reclaim_unit(String(w.kind), float(w.gold), b.rng)
		x = float(w.x)
		Foundry._release(b, w, "reclaim")
		b.stats_reclaimed += 1
		b.stats_reclaimed_ids.append(uid)
	var z = b.spawn_unit(uid, 1, Vector2(clampf(x, Combat.DWARF_BASE_X + 140.0, Combat.UNDEAD_BASE_X - 80.0), 0), true)
	if z != null:
		u.phase_heralds.append(z)
		z.raised_from_wreck = true
		b.fx.raise(z.position + Vector2(0, -30))
		b.fx.dirt_burst(z.position, 1.6)
		b.stats_phase_spawns += 1
	b.stats_titan_reclaims += 1
	u.weak_core_t = float(ph.get("exposed", 8.0))
	# plates fall away from the core
	for k in 5:
		b.fx.sparks(u.aim_point() + Vector2(b._fx_rng.randf_range(-30, 30), b._fx_rng.randf_range(-40, 20)), 3)
	b.fx.bones(u.aim_point())
	b.shake(5.0)
	Audio.play("reclaim", u.position.x, 2.0)
	if not first:
		b.alert.emit("The Titan reclaims a wreck — its core is exposed!")


## Ashen Forge Tyrant: the arena's vents fire one after another, from the furnace toward the dwarven line.
static func _vent_sweep(u, b, ph: Dictionary) -> void:
	var xs: Array = ph.get("vents", [])
	for i in xs.size():
		Foundry.erupt(b, float(xs[i]), float(ph.get("radius", 46)), float(ph.get("damage", 110)), float(ph.get("warn", 1.0)) + float(i) * float(ph.get("step", 0.55)), "tyrant")
	b.stats_vent_sweeps += 1
	Audio.play("giant_roar", u.position.x, 0.0)


## Corpse Colossus: a corpse flies in a long arc and smashes into the dwarven stronghold.
static func _corpse_throw(u, b, ph: Dictionary) -> void:
	if b.dwarf_base == null or not b.dwarf_base.alive:
		return
	var warn = float(ph.get("warn", 1.6))
	b.corpse_throws.append({"x0": u.position.x - 30.0, "y0": u.position.y - Painter.art_height(u.art) * u.art_scale * 0.8,
		"x1": b.dwarf_base.position.x + 20.0, "t": 0.0, "dur": warn, "dmg": float(ph.get("damage", 260))})
	b.fx.telegraph(Vector2(b.dwarf_base.position.x + 20.0, Combat.GROUND_Y), 70.0, warn, Color(0.6, 0.9, 0.3))
	b.stats_corpse_throws += 1
	Audio.play("giant_roar", u.position.x, -2.0)
