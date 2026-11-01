class_name MechAbility
extends RefCounted
## Shared special-ability state machine for every war frame (M002 §10.1).
## Abilities draw on the shared kingdom Steam Pressure pool and are triggered automatically
## under the army-wide Machinery Doctrine (conserve / standard / overdrive). The battle
## arbitrates requests deterministically (serial order, global spacing) so several frames
## can never drain the pool in the same instant. If the owner dies during the wind-up the
## ability is cancelled.
##
## kinds: strike · aoe · buff · shot · chain · zone · ward · charge · salvo

const GLOBAL_GAP := 0.5


static func ready_to_request(u) -> bool:
	return u.alive and not u.ability.is_empty() and u.ability_cd <= 0.0 and u.ability_wind < 0.0 and u.stun_t <= 0.0


## Does this frame currently have a sensible use for its ability?
static func wants(u, b, doctrine: String) -> bool:
	var a: Dictionary = u.ability
	var relaxed = doctrine == "overdrive"
	match String(a.kind):
		"strike":
			var w = u.weapons[0]
			return w.target != null and w.in_range(u, w.target, b)
		"aoe":
			var n = _count_front(u, b, float(a.radius), bool(a.get("cone", false)))
			var need: int = 1 if relaxed else int(a.get("min_targets", 2))
			return n >= need or (n >= 1 and _heavy_near(u, b, float(a.radius)))
		"buff":
			match String(a.get("cond", "target")):
				"air":
					return _any_weapon_target(u, "air")
				"armored_target":
					var t = u.weapons[0].target
					return t != null and is_instance_valid(t) and (t.armor in Combat.ARMORED_CLASSES or t.max_hp > 400.0)
				"threatened":
					return _any_weapon_target(u, "") and (u.hp < u.max_hp * 0.85 or relaxed)
				_:
					return _any_weapon_target(u, "")
		"shot":
			var w2 = u.weapons[int(a.get("weapon", 0))]
			return w2.target != null and is_instance_valid(w2.target) and w2.target.alive
		"chain":
			var t2 = u.weapons[0].target
			if t2 == null or not is_instance_valid(t2):
				return false
			return relaxed or b.query(t2.position, float(a.jump), Combat.enemy_of(u.side), "any").size() >= 2
		"zone":
			var c = _zone_center(u, a)
			var n2: int = b.query(c, float(a.radius), Combat.enemy_of(u.side), "ground").size()
			return n2 >= (1 if relaxed else 3)
		"ward":
			# enemy shooters nearby, or several allies to protect
			var shooters = 0
			for e in b.query(u.position, 460.0, Combat.enemy_of(u.side), "any"):
				for w3 in e.weapons:
					if w3.proj != "melee":
						shooters += 1
						break
			return shooters >= (1 if relaxed else 2)
		"charge":
			var tgt = b.nearest_enemy_ground(u, float(a.dist) + 90.0)
			if tgt == null or tgt.is_stronghold:
				return false
			var dx: float = (tgt.position.x - u.position.x) * u.dir
			return dx > float(a.radius) * 0.6 and dx < float(a.dist) + 80.0
		"salvo":
			return _any_weapon_target(u, "air")
		"summon":
			return b.nearest_enemy_ground(u, 420.0) != null
		"rally":
			var allies = 0
			for e in b.query(u.position, float(a.radius), u.side, "any"):
				if e != u and e.alive and not e.is_static:
					allies += 1
			return allies >= (2 if relaxed else 4) and _any_weapon_target(u, "")
	return false


static func activate(u, b) -> void:
	var a: Dictionary = u.ability
	if u.is_giant or u.is_boss:
		b.stats_giant_abilities += 1   # necrotic: no Steam, cooldown only
	else:
		b.steam = maxf(0.0, b.steam - float(a.steam))
		b.stats_ability_uses += 1
		b.stats_ability_steam += float(a.steam)
	u.ability_cd = float(a.cooldown)
	u.ability_wind = 0.0
	u.ability_anim = 1.0
	u.ability_name = String(a.name)
	if String(a.kind) == "aoe" and a.get("telegraph", false):
		b.fx.telegraph(_aoe_center(u, a), float(a.radius), float(a.windup), Color(1.0, 0.6, 0.25))
	elif String(a.kind) == "zone":
		b.fx.telegraph(_zone_center(u, a), float(a.radius), float(a.windup), Color(1.0, 0.45, 0.1))
	elif String(a.kind) == "charge":
		b.fx.telegraph(u.position + Vector2(u.dir * float(a.dist), 0), float(a.radius), float(a.windup), Color(1.0, 0.55, 0.3))
	elif String(a.kind) == "summon":
		b.fx.telegraph(u.position + Vector2(u.dir * 30.0, 0), 50.0, float(a.windup), Color(0.45, 1.0, 0.55))
	if String(a.kind) in ["shot", "charge"]:
		u.brace_t = float(a.windup) + 0.3
	if u.is_giant or u.is_boss:
		b.fx.raise(u.aim_point())
		Audio.play("giant_roar", u.position.x, -3.0, 0.1)
	else:
		b.fx.steam_burst(u.aim_point(), 0.8 + u.art_scale * 0.3)
		Audio.play("steam", u.position.x, -6.0)


## Advances the wind-up; resolves the effect when it completes. Returns nothing.
static func step(u, b, dt: float) -> void:
	if u.ability_wind < 0.0:
		return
	if not u.alive:
		u.ability_wind = -1.0
		return
	u.ability_wind += dt
	var a: Dictionary = u.ability
	if String(a.kind) == "charge" and u.ability_wind < float(a.windup):
		pass
	if u.ability_wind >= float(a.windup):
		u.ability_wind = -1.0
		_resolve(u, b, a)


static func _resolve(u, b, a: Dictionary) -> void:
	var enemy: int = Combat.enemy_of(u.side)
	match String(a.kind):
		"strike":
			var w = u.weapons[0]
			var t = w.target
			if t == null or not is_instance_valid(t) or not t.alive:
				return
			var base = float(w.d.get("damage", 10)) * float(a.mult)
			var bonus: Dictionary = (a.get("bonus", {}) as Dictionary).duplicate()
			bonus.merge(w.d.get("bonus", {}))
			bonus["_pen"] = float(a.get("pen", w.d.get("pen", 0.0)))
			for i in int(a.get("hits", 1)):
				if is_instance_valid(t) and t.alive:
					var hp0: float = t.hp
					b.damage(t, base, String(w.d.get("dtype", "melee")), u, bool(w.d.get("ap", false)), bonus)
					b.fx.impact(t.aim_point(), 0.7 + u.art_scale * 0.2)
					if float(a.get("heal", 0)) > 0.0:
						u.hp = minf(u.max_hp, u.hp + maxf(0.0, hp0 - t.hp) * float(a.heal))
						b.fx.raise(u.aim_point())
			if is_instance_valid(t) and t.alive and float(a.get("knock", 0)) > 0.0:
				b.knock(t, u.dir * float(a.knock))
			u.atk = 1.0
			Audio.play("hammer_impact", u.position.x, -2.0)
		"aoe":
			var c = _aoe_center(u, a)
			var bonus2: Dictionary = (a.get("bonus", {}) as Dictionary).duplicate()
			bonus2["_pen"] = float(a.get("pen", 0.0))
			for e in b.query(c, float(a.radius), enemy, "ground"):
				if a.get("cone", false) and (e.position.x - u.position.x) * u.dir < -10.0:
					continue
				b.damage(e, float(a.damage), String(a.dtype), u, false, bonus2)
				if float(a.get("stun", 0)) > 0.0 and e.alive and not e.is_static and e.cls != "boss":
					e.stun_t = maxf(e.stun_t, float(a.stun))
				if float(a.get("knock", 0)) > 0.0 and e.alive:
					b.knock(e, signf(e.position.x - u.position.x + u.dir * 0.01) * float(a.knock))
			if a.has("pool"):
				b.add_zone(c, float(a.radius) * 0.6, float(a.pool.dps), float(a.pool.dur), u.side, u, String(a.dtype), "plague", 0.0)
			b.fx.explosion(c, 0.8 + float(a.radius) / 120.0, "dirt" if not u.is_giant else "necro")
			b.fx.shockwave(c, float(a.radius))
			b.shake(3.0 + u.art_scale * 2.0)
			Audio.play("hammer_impact", u.position.x, 0.0)
			if a.has("then"):
				u.add_buff({"dr": float(a.then.dr)}, float(a.then.dur))
			if float(a.get("self_stun", 0)) > 0.0:
				u.stun_t = float(a.self_stun)
			u.atk = 1.0
		"buff":
			u.add_buff(a.get("mods", {}), float(a.dur))
			if float(a.get("heat_lock", 0)) > 0.0:
				u.heat_after = float(a.heat_lock)
				u.heat_after_at = float(a.dur)
		"shot":
			var w4 = u.weapons[int(a.get("weapon", 0))]
			var t4 = w4.target
			if t4 == null or not is_instance_valid(t4) or not t4.alive:
				return
			var bonus4: Dictionary = (a.get("bonus", {}) as Dictionary).duplicate()
			bonus4["_pen"] = float(a.get("pen", 0.0))
			var extra = {"pierce": int(a.get("pierce", 0)), "cluster": int(a.get("cluster", 0)), "cluster_damage": float(a.get("cluster_damage", 0)), "cluster_radius": float(a.get("cluster_radius", 30)), "dir": u.dir}
			b.projectiles.fire(String(a.get("proj", "shell")), w4.mount_world(u), t4.aim_point(), t4, float(a.damage), String(a.dtype), float(a.get("splash", 0)), u.side, w4.targets, true, u, bonus4, extra)
			b.fx.muzzle(w4.mount_world(u), (t4.aim_point() - w4.mount_world(u)).normalized(), "shell")
			b.fx.explosion(w4.mount_world(u), 0.6, "fire")
			w4.anim = 1.0
			u.on_fire(w4)
			b.shake(4.0)
			Audio.play("cannon_heavy", u.position.x, 0.0)
		"chain":
			var t5 = u.weapons[0].target
			if t5 == null or not is_instance_valid(t5) or not t5.alive:
				return
			var hit: Array = [t5]
			var cur = t5
			var allowed: String = u.weapons[0].targets
			while hit.size() < int(a.targets_max):
				var best = null
				var bd = INF
				for e in b.query(cur.aim_point(), float(a.jump), enemy, allowed):
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
			var prev: Vector2 = u.weapons[0].mount_world(u)
			for e in hit:
				b.fx.bolt(prev, e.aim_point())
				prev = e.aim_point()
				b.damage(e, float(a.damage), String(a.dtype), u, false, {})
				if e.alive:
					e.apply_slow(float(a.slow), float(a.slow_dur))
			b.stats_chain_max = maxi(b.stats_chain_max, hit.size())
			Audio.play("electric", u.position.x, -2.0)
		"zone":
			b.add_zone(_zone_center(u, a), float(a.radius), float(a.dps), float(a.dur), u.side, u, String(a.get("dtype", "fire")), String(a.get("look", "fire")), float(a.get("slow", 0.0)))
			if float(a.get("cool_lock", 0)) > 0.0:
				u.wlock[0] = float(a.dur) + float(a.cool_lock)
			Audio.play("flame", u.position.x, 0.0)
		"ward":
			b.add_ward(u, float(a.radius), float(a.mult), float(a.dur))
			Audio.play("electric", u.position.x, -6.0)
		"charge":
			u.charge_left = float(a.dist)
			u.charge_hit = false
		"summon":
			var mine = 0
			for x in b.by_side[u.side]:
				if x.alive and x.summoner == u:
					mine += 1
			var n = mini(int(a.count), int(a.cap) - mine)
			for i in n:
				var p = Vector2(u.position.x + u.dir * b.rng.randf_range(10.0, 50.0), u.position.y if a.get("air", false) else 0.0)
				var s2 = b.spawn_unit(String(a.enemy), u.side, p, true)
				if s2 != null:
					s2.summoner = u
					b.fx.raise(s2.position + Vector2(0, -10))
				b.stats_summoned += 1
			Audio.play("necro_magic", u.position.x, -2.0)
		"rally":
			var n2 = 0
			for e in b.query(u.position, float(a.radius), u.side, "any"):
				if e.alive and not e.is_stronghold and not e.is_static:
					e.add_buff(a.get("mods", {}), float(a.dur))
					n2 += 1
			b.stats_rallied += n2
			b.fx.shockwave(u.position + Vector2(0, -10), float(a.radius))
			Audio.play("giant_roar", u.position.x, 0.0)
		"salvo":
			var best_air = null
			var bh = -1.0
			for w6 in u.weapons:
				if w6.targets != "air":
					continue
				for e in b.query(w6.mount_world(u), w6.range_ + 40.0, enemy, "air"):
					if e.max_hp > bh:
						bh = e.max_hp
						best_air = e
			if best_air == null:
				return
			for w7 in u.weapons:
				if w7.targets == "air" and w7.in_range(u, best_air, b):
					w7.target = best_air
					var dmg = float(w7.d.get("damage", 10)) * float(a.mult)
					b.projectiles.fire(w7.proj, w7.mount_world(u), best_air.aim_point(), best_air, dmg, String(w7.d.get("dtype", "flak")), float(w7.d.get("splash", 0)), u.side, "air", false, u, {}, {})
					w7.cd = float(w7.d.get("reload", 1.0))
					w7.anim = 1.0
					u.on_fire(w7)
			b.stats_salvos += 1
			Audio.play("flak", u.position.x, 0.0)


static func charge_step(u, b, dt: float) -> void:
	# executed by the unit while charge_left > 0: fast advance, impact on first contact or at the end
	var a: Dictionary = u.ability
	var mv: float = minf(u.charge_left, 320.0 * dt)
	var blk = b.nearest_blocker(u)
	var stop = false
	if blk != null and (blk.position.x - u.position.x) * u.dir <= blk.radius + u.radius + 6.0:
		stop = true
	if not stop:
		u.position.x += u.dir * mv
		u.charge_left -= mv
		u.walk += mv * 0.12
		b.fx.dust(u.position, 0.6)
	if stop or u.charge_left <= 0.0:
		u.charge_left = 0.0
		var c: Vector2 = u.position + Vector2(u.dir * float(a.radius) * 0.6, -10)
		for e in b.query(c, float(a.radius), Combat.enemy_of(u.side), "ground"):
			b.damage(e, float(a.damage), String(a.dtype), u, false, {})
			if e.alive:
				b.knock(e, u.dir * float(a.get("knock", 40)))
		b.fx.explosion(c, 1.2, "dirt")
		b.fx.shockwave(c, float(a.radius))
		b.shake(5.0)
		u.atk = 1.0
		Audio.play("hammer_impact", u.position.x, 0.0)


static func _aoe_center(u, a: Dictionary) -> Vector2:
	var off = float(a.radius) * (0.55 if a.get("cone", false) else 0.15)
	return Vector2(u.position.x + u.dir * off, Combat.GROUND_Y - 10.0)


static func _zone_center(u, a: Dictionary) -> Vector2:
	return Vector2(u.position.x + u.dir * float(a.get("offset", 80)), Combat.GROUND_Y - 10.0)


static func _count_front(u, b, r: float, cone: bool) -> int:
	var c = _aoe_center(u, {"radius": r, "cone": cone})
	var n = 0
	for e in b.query(c, r, Combat.enemy_of(u.side), "ground"):
		if not e.is_stronghold:
			n += 1
	return n


static func _heavy_near(u, b, r: float) -> bool:
	for e in b.query(u.position, r, Combat.enemy_of(u.side), "ground"):
		if e.max_hp >= 400.0 and not e.is_stronghold:
			return true
	return false


static func _any_weapon_target(u, domain: String) -> bool:
	for w in u.weapons:
		if w.target != null and is_instance_valid(w.target) and (domain == "" or w.target.domain == domain):
			return true
	return false
