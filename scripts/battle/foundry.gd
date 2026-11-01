class_name Foundry
extends RefCounted
## M007 Act IV systems, run by Battle every step (static helpers over the battle's state so battle.gd stays lean):
##   wrecks          destroyed dwarven vehicles, war frames and aircraft leave a wreck for WRECK_LIFE s. An undead
##                   corruptor (def.reclaims) that reaches one channels for CHANNEL_TIME s and raises a corrupted
##                   machine of the matching class; a dwarven salvage unit (def.salvages) clears it in SALVAGE_TIME s
##                   and refunds a little Gold. Never more than WRECK_CAP at once (oldest crumble first).
##   furnace vents   fixed grates erupt in turn after a 1 s glow (ground units, both sides; machines take 50 %)
##   slag flow       a molten river creeps across a stretch of the lane, damaging and slowing ground units
##   steam leak      a burst pipe: dwarven machines near it refill Steam Pressure; everyone inside is scalded
##   eruptions       the shared telegraphed fire-burst used by the vents and the Ashen Forge Tyrant's sequence
## All visuals go through HazardLayer.FoundryPaint (batched DOT quads) and the pooled FxLayer.

const WRECK_CAP := 6
const WRECK_LIFE := 20.0
const CHANNEL_TIME := 4.0
const SALVAGE_TIME := 3.0
const CHANNEL_RANGE := 70.0
const SALVAGE_RANGE := 64.0
const SEEK_RANGE := 460.0
const REFUND := 0.15          # share of the machine's Gold cost refunded by salvage
const REFUND_CAP := 160.0
const ERUPT_TIME := 0.8       # flame pillar duration after the telegraph
const MACHINE_CLASSES := ["vehicle", "walker", "aircraft", "airship"]


# ================================================================== wrecks
## Which corrupted machine a wreck of this dwarven unit becomes.
static func reclaim_unit(kind: String, gold: float, rng: RandomNumberGenerator) -> String:
	match kind:
		"walker":
			return "possessed_drillwalker" if gold < 900.0 or rng.randf() < 0.6 else "cursed_ironclad"
		"air":
			return "haunted_flying_machine"
	if gold < 260.0:
		return "risen_copperback"
	if gold < 700.0:
		return "gravegun_tank" if rng.randf() < 0.6 else "risen_copperback"
	return "cursed_ironclad" if rng.randf() < 0.35 else "gravegun_tank"


static func wreck_kind(u) -> String:
	if u.cls == "walker" or u.is_mech:
		return "walker"
	if u.domain == "air" or u.cls in ["aircraft", "airship"]:
		return "air"
	return "tank"


static func leaves_wreck(b, u) -> bool:
	if not bool(b.stage.get("wrecks", false)) or b.sandbox_wrecks_off:
		return false
	if u.side != 0 or u.is_stronghold or u == b.escort_unit or u.summoner != null:
		return false
	return u.cls in MACHINE_CLASSES


static func add_wreck(b, u) -> void:
	while b.wrecks.size() >= WRECK_CAP:
		_release(b, b.wrecks[0], "crumble")
	var w = {"unit": u, "x": u.position.x, "kind": wreck_kind(u), "gold": float(u.def.get("gold", 0)), "t": 0.0,
		"chan": null, "chan_t": 0.0, "sal": null, "sal_t": 0.0, "id": u.id, "serial": u.serial}
	u.wreck_hold = true
	b.wrecks.append(w)
	b.stats_wrecks += 1


static func _release(b, w: Dictionary, why: String) -> void:
	var u = w.unit
	if is_instance_valid(u):
		u.wreck_hold = false
		u.dying_t = u.death_time * 0.82 if u.is_mech else 0.5
	if w.chan != null and is_instance_valid(w.chan):
		w.chan.channel_wreck = null
	if w.sal != null and is_instance_valid(w.sal):
		w.sal.salvage_wreck = null
	b.wrecks.erase(w)
	match why:
		"crumble", "expire":
			b.stats_wreck_expired += 1
			b.fx.dust(Vector2(w.x, Combat.GROUND_Y), 1.2)


static func wreck_near(b, x: float, r: float, need_free: bool = false):
	var best = null
	var bd = r
	for w in b.wrecks:
		var d = absf(float(w.x) - x)
		if d <= bd and (not need_free or w.chan == null):
			bd = d
			best = w
	return best


static func tick_wrecks(b, dt: float) -> void:
	if b.wrecks.is_empty():
		return
	for w in b.wrecks.duplicate():
		w.t += dt
		# a channelling corruptor must stay alive, close and unstunned
		if w.chan != null:
			var c = w.chan
			if not is_instance_valid(c) or not c.alive or c.stun_t > 0.0 or absf(c.position.x - float(w.x)) > CHANNEL_RANGE + 8.0:
				if is_instance_valid(c):
					c.channel_wreck = null
				w.chan = null
				w.chan_t = 0.0
			else:
				w.chan_t += dt
				if b._fx_rng.randf() < dt * 8.0:
					b.fx.puff(Vector2(float(w.x) + b._fx_rng.randf_range(-20, 20), Combat.GROUND_Y - 14.0), Color(0.43, 1.0, 0.55, 0.45))
				if w.chan_t >= CHANNEL_TIME:
					_reclaim(b, w)
					continue
		if w.sal != null:
			var s = w.sal
			if not is_instance_valid(s) or not s.alive or absf(s.position.x - float(w.x)) > SALVAGE_RANGE + 10.0:
				if is_instance_valid(s):
					s.salvage_wreck = null
				w.sal = null
				w.sal_t = 0.0
			else:
				w.sal_t += dt
				if b._fx_rng.randf() < dt * 7.0:
					b.fx.sparks(Vector2(float(w.x), Combat.GROUND_Y - 16.0), 2)
				if w.sal_t >= SALVAGE_TIME:
					_salvage(b, w)
					continue
		if w.t >= WRECK_LIFE and w.chan == null:
			_release(b, w, "expire")
			continue
		# idle smoke from the wreck (cosmetic RNG)
		if b._fx_rng.randf() < dt * 1.5:
			b.fx.puff(Vector2(float(w.x) + b._fx_rng.randf_range(-14, 14), Combat.GROUND_Y - 30.0), Color(0.16, 0.14, 0.13, 0.5))


static func _reclaim(b, w: Dictionary) -> void:
	var uid = reclaim_unit(String(w.kind), float(w.gold), b.rng)
	var x = clampf(float(w.x), Combat.DWARF_BASE_X + 120.0, Combat.UNDEAD_BASE_X - 80.0)
	var y = 0.0 if w.kind != "air" else Combat.GROUND_Y - 80.0
	var c = w.chan
	_release(b, w, "reclaim")
	var z = b.spawn_unit(uid, 1, Vector2(x, y), true)
	b.stats_reclaimed += 1
	b.stats_reclaimed_ids.append(uid)
	if z != null:
		z.raised_from_wreck = true
		b.fx.raise(z.position + Vector2(0, -30))
		b.fx.raise(z.position + Vector2(-16, -12))
		b.fx.explosion(Vector2(x, Combat.GROUND_Y - 20.0), 0.9, "necro")
	b.shake(2.5)
	Audio.play("reclaim", x, -1.0)
	if is_instance_valid(c):
		c.channel_wreck = null
	if b.time - b._reclaim_alert_t > 15.0:
		b._reclaim_alert_t = b.time
		b.alert.emit("A wreck has been reclaimed — the dead drive your own machine!")


static func _salvage(b, w: Dictionary) -> void:
	var g = minf(REFUND_CAP, float(w.gold) * REFUND)
	if not b.infinite_gold:
		b.gold = minf(9999.0, b.gold + g)
	b.stats_salvaged += 1
	b.stats_salvage_gold += g
	var s = w.sal
	_release(b, w, "salvage")
	b.fx.sparks(Vector2(float(w.x), Combat.GROUND_Y - 16.0), 6)
	b.fx.puff(Vector2(float(w.x), Combat.GROUND_Y - 24.0), Color(1, 0.85, 0.4, 0.5))
	Audio.play("salvage", float(w.x), -4.0)
	if is_instance_valid(s):
		s.salvage_wreck = null


## Corruptor brain hook (Unit.step): returns true while the unit is busy with a wreck (moving or channelling),
## in which case the unit's normal behaviour and weapons are skipped this step.
static func corruptor_step(u, b, dt: float) -> bool:
	if b.wrecks.is_empty() or u.stun_t > 0.0:
		u.channel_wreck = null
		return false
	var w = u.channel_wreck
	if w != null and not b.wrecks.has(w):
		u.channel_wreck = null
		w = null
	if w == null:
		u._wreck_seek_t -= dt
		if u._wreck_seek_t > 0.0:
			return false
		u._wreck_seek_t = 0.5
		# nearest free wreck ahead (the undead walk toward lower x), not deep behind the dwarven front
		var best = null
		var bd = SEEK_RANGE
		for cand in b.wrecks:
			if cand.chan != null:
				continue
			var d = u.position.x - float(cand.x)
			if d > -40.0 and d < bd:
				bd = d
				best = cand
		if best == null:
			return false
		w = best
		u.channel_wreck = w
	var dx = float(w.x) - u.position.x
	if absf(dx) > CHANNEL_RANGE:
		# walk to it, but never through the dwarven line
		var lim = u._advance_limit()
		var nx = u.position.x + signf(dx) * u.move_speed() * dt
		nx = maxf(nx, lim) if dx < 0.0 else nx
		if absf(nx - u.position.x) < 0.01:
			# blocked: fight normally, keep the claim for when the way clears
			return false
		u.position.x = nx
		return true
	if w.chan == null:
		w.chan = u
		w.chan_t = 0.0
		b.stats_channels += 1
		Audio.play("channel", float(w.x), -6.0)
	elif w.chan != u:
		u.channel_wreck = null
		return false
	u.facing = signf(dx) if absf(dx) > 2.0 else u.facing
	u.special = 1.0
	return true


## Salvage hook (Unit._repair): a salvage unit with no urgent patient heads for the nearest wreck near its front.
static func salvage_step(u, b, dt: float) -> bool:
	if b.wrecks.is_empty():
		u.salvage_wreck = null
		return false
	var w = u.salvage_wreck
	if w != null and not b.wrecks.has(w):
		u.salvage_wreck = null
		w = null
	if w == null:
		var best = null
		var bd = 420.0
		for cand in b.wrecks:
			if cand.sal != null:
				continue
			var d = absf(float(cand.x) - u.position.x)
			# a wreck being channelled is the priority
			if cand.chan != null:
				d *= 0.5
			if d < bd:
				bd = d
				best = cand
		if best == null:
			return false
		w = best
		u.salvage_wreck = w
	var dx = float(w.x) - u.position.x
	if absf(dx) > SALVAGE_RANGE * 0.8:
		var lim = u._advance_limit()
		var nx = u.position.x + signf(dx) * u.move_speed() * dt
		if dx > 0.0:
			nx = minf(nx, lim)
		if absf(nx - u.position.x) < 0.01:
			return false
		u.position.x = nx
		return true
	if w.sal == null:
		w.sal = u
		w.sal_t = 0.0
	elif w.sal != u:
		u.salvage_wreck = null
		return false
	u.special = 1.0
	u.facing = signf(dx) if absf(dx) > 2.0 else u.facing
	return true


# ================================================================== furnace vents & eruptions
static func set_vents(b, h: Dictionary) -> void:
	b.vents.clear()
	var xs: Array = h.get("vents", [])
	var iv = float(h.get("interval", 10.0))
	for i in xs.size():
		# vents erupt in turn, staggered across the interval, so the lane always has a safe gap
		b.vents.append({"x": float(xs[i]), "next": 4.0 + iv * float(i) / float(maxi(1, xs.size())), "glow": 0.0})
	b.vent_def = h


static func erupt(b, x: float, r: float, dmg: float, warn: float, src: String = "vent") -> void:
	if b.eruptions.size() >= 16:
		return
	b.eruptions.append({"x": x, "r": r, "dmg": dmg, "t": 0.0, "warn": warn, "hit": false, "src": src})
	for v in b.vents:
		if absf(float(v.x) - x) < 40.0:
			v.glow = maxf(float(v.glow), warn + ERUPT_TIME)
	Audio.play("vent_rumble", x, -10.0)


static func tick_vents(b, dt: float) -> void:
	if not b.vents.is_empty():
		var iv = float(b.vent_def.get("interval", 10.0))
		for v in b.vents:
			v.next -= dt
			v.glow = maxf(0.0, v.glow - dt)
			if v.next <= 0.0:
				v.next = iv
				v.glow = float(b.vent_def.get("warn", 1.0)) + ERUPT_TIME
				erupt(b, float(v.x), float(b.vent_def.get("radius", 40)), float(b.vent_def.get("damage", 80)), float(b.vent_def.get("warn", 1.0)))
	if b.eruptions.is_empty():
		return
	var keep: Array = []
	for e in b.eruptions:
		e.t += dt
		if not e.hit and e.t >= float(e.warn):
			e.hit = true
			b.stats_vent_bursts += 1
			var p = Vector2(float(e.x), Combat.GROUND_Y - 10.0)
			for s in 2:
				for t in b.query(p, float(e.r), s, "ground"):
					if t.is_static or t.is_boss or t.is_stronghold:
						continue
					var m = 0.5 if is_machine(t) else 1.0
					var dealt = t.take_damage(float(e.dmg) * m, null)
					b.stats_vent_dmg[t.side] += dealt
					if not t.alive:
						t.last_hit_by = "furnace vent"
			b.fx.flames(p, float(e.r), "fire")
			b.fx.explosion(p + Vector2(0, -30), 0.6, "fire")
			Audio.play("vent_roar", float(e.x), -2.0)
		if e.t < float(e.warn) + ERUPT_TIME:
			keep.append(e)
	b.eruptions = keep


static func is_machine(t) -> bool:
	return t.cls in ["vehicle", "walker", "artillery", "aircraft", "airship"] or t.is_mech or t.armor in ["machine", "mech", "structure"]


# ================================================================== slag flow
static func set_slag(b, h: Dictionary) -> void:
	b.slag = {"def": h, "next": float(h.get("first", 30.0)), "active": false, "t": 0.0, "front": float(h.x0), "warn": 0.0, "cool": 0.0, "tick": 0.5}


static func tick_slag(b, dt: float) -> void:
	if b.slag.is_empty():
		return
	var s: Dictionary = b.slag
	var h: Dictionary = s.def
	var x0 = float(h.x0)
	var x1 = float(h.x1)
	var dirn = signf(x1 - x0)
	s.cool = maxf(0.0, float(s.cool) - dt)
	if not s.active:
		s.next = float(s.next) - dt
		if float(s.next) <= 1.6 and float(s.warn) <= 0.0 and float(s.next) > 0.0:
			s.warn = 1.6
			Audio.play("slag_hiss", x0, -6.0)
		s.warn = maxf(0.0, float(s.warn) - dt)
		if float(s.next) <= 0.0:
			s.active = true
			s.t = 0.0
			s.front = x0
			b.stats_slag_flows += 1
			Audio.play("slag_hiss", x0, -2.0)
		return
	s.t = float(s.t) + dt
	var reach = x0 + dirn * float(h.get("speed", 36.0)) * float(s.t)
	s.front = minf(reach, x1) if dirn > 0.0 else maxf(reach, x1)
	s.tick = float(s.tick) - dt
	if float(s.tick) <= 0.0:
		s.tick = 0.5
		var lo = minf(x0, float(s.front))
		var hi = maxf(x0, float(s.front))
		for side in 2:
			for u in b.by_side[side]:
				if not u.alive or u.domain != "ground" or u.is_static or u.is_boss or u.is_stronghold or u.burrowed:
					continue
				if u.position.x < lo - u.radius * 0.5 or u.position.x > hi + u.radius * 0.5:
					continue
				var dealt = u.take_damage(float(h.dps) * 0.5 * (0.7 if is_machine(u) else 1.0), null)
				b.stats_slag_dmg[u.side] += dealt
				b.stats_slag_hits[u.side] += 1
				if not u.alive:
					u.last_hit_by = "slag"
				else:
					u.apply_slow(1.0 - float(h.get("slow", 0.45)), 0.6)
	if float(s.t) >= float(h.duration):
		s.active = false
		s.cool = 2.5
		s.next = float(h.interval)


static func in_slag(b, x: float) -> bool:
	if b.slag.is_empty() or not b.slag.active:
		return false
	var lo = minf(float(b.slag.def.x0), float(b.slag.front))
	var hi = maxf(float(b.slag.def.x0), float(b.slag.front))
	return x >= lo and x <= hi


# ================================================================== steam leaks
static func set_steam(b, h: Dictionary) -> void:
	b.steam_pipes.clear()
	for x in h.get("pipes", []):
		b.steam_pipes.append({"x": float(x), "r": float(h.get("radius", 80)), "dps": float(h.get("dps", 7)), "regen": float(h.get("regen", 5)), "tick": 0.5, "fed": false})


static func tick_steam(b, dt: float) -> void:
	for p in b.steam_pipes:
		p.tick = float(p.tick) - dt
		var fed = false
		var scald = float(p.tick) <= 0.0
		if scald:
			p.tick = 0.5
		for side in 2:
			for u in b.by_side[side]:
				if not u.alive or u.domain != "ground" or u.is_static or u.is_stronghold or u.is_boss:
					continue
				if absf(u.position.x - float(p.x)) > float(p.r):
					continue
				if side == 0 and is_machine(u):
					fed = true
				if scald:
					var dealt = u.take_damage(float(p.dps) * 0.5, null)
					b.stats_steam_dmg[side] += dealt
					if not u.alive:
						u.last_hit_by = "steam leak"
		p.fed = fed
		if fed and not b.over:
			var before = b.steam
			b.steam = minf(Battle.STEAM_MAX, b.steam + float(p.regen) * dt)
			b.stats_steam_gained += b.steam - before
		if b._fx_rng.randf() < dt * (9.0 if fed else 5.0):
			b.fx.steam_burst(Vector2(float(p.x) + b._fx_rng.randf_range(-10, 10), Combat.GROUND_Y - 40.0), 1.0)
		# the burst main coughs now and then (presentation RNG only)
		if b._fx_rng.randf() < dt * 0.2:
			Audio.play("pipe_burst", float(p.x), -8.0)
