class_name BossMineMaw
extends RefCounted
## Mine Maw — Stage 010 boss. Burrowing ground monster.
## Cycle: SURFACE (advances, telegraphed bites) → BURROWING (1.5 s, dust) → UNDERGROUND
## (untargetable unless a Scout Gyro spots it; tunnels to the densest dwarven formation) →
## ERUPT TELEGRAPH (cracking ring) → ERUPTION (AoE, knock-back, spits Rotters) → EXPOSED
## (stunned, +50% damage taken) → SURFACE. Periodic capped support waves while alive.
## Counterplay: spread out when the ground cracks, punish the exposed window, aircraft are
## immune to eruptions, Scout Gyros reveal the tunnel. Its death breaks the citadel seal.


static func step(u, dt: float) -> void:
	var b: Dictionary = u.def.get("boss", {})
	var enraged: bool = u.hp < u.max_hp * float(b.get("enrage_below", 0.35))
	var k = 0.7 if enraged else 1.0
	u.mode_t += dt
	_support(u, dt, b)
	match u.mode:
		"surface":
			u.state = "move" if u.state == "move" else u.state
			u.special = minf(1.0, u.special + dt * 2.0)
			u._ground(dt)
			if u.mode_t > float(b.get("surface_time", 9.0)) * k and u.weapons[0].windup_t < 0.0:
				_enter(u, "burrowing")
				u.battle.fx.dirt_burst(u.position, 1.6)
				Audio.play("boss", u.position.x, 0.0)
		"burrowing":
			u.special = maxf(0.0, 1.0 - u.mode_t / float(b.get("burrow_telegraph", 1.5)))
			_hold_weapons(u)
			if u.battle.rng.randf() < dt * 10.0:
				u.battle.fx.dirt_burst(u.position + Vector2(u.battle.rng.randf_range(-40, 40), 0), 0.6)
			if u.mode_t >= float(b.get("burrow_telegraph", 1.5)):
				_enter(u, "underground")
				u.burrowed = true
				u.blocks = false
				u.state = "burrowed"
				var dest = u.battle.densest_enemy_ground(u)
				u.alt_target = dest.x if dest != null else Combat.DWARF_BASE_X + Combat.BASE_FACE + 60.0
		"underground":
			u.spotted = u.battle.is_spotted(u.position)
			var to: float = u.alt_target - u.position.x
			var mv: float = float(b.get("underground_speed", 95)) * dt
			u.position.x += clampf(to, -mv, mv)
			if u.battle.rng.randf() < dt * 8.0:
				u.battle.fx.dirt_burst(u.position, 0.4)
			if absf(to) < 6.0 or u.mode_t > float(b.get("underground_max", 6.0)):
				_enter(u, "erupt_tele")
				u.battle.fx.telegraph(u.position, float(b.get("erupt_radius", 95)), float(b.get("erupt_telegraph", 1.7)) * k, Color(1.0, 0.55, 0.2))
				Audio.play("rockfall", u.position.x, 0.0)
		"erupt_tele":
			u.spotted = u.battle.is_spotted(u.position)
			if u.mode_t >= float(b.get("erupt_telegraph", 1.7)) * k:
				_erupt(u, b)
				_enter(u, "exposed")
				u.burrowed = false
				u.spotted = false
				u.blocks = true
				u.exposed = true
				u.state = "exposed"
				u.special = 0.2
		"exposed":
			u.special = minf(1.0, u.special + dt * 3.0)
			_hold_weapons(u)
			if u.mode_t >= float(b.get("exposed_time", 5.0)):
				u.exposed = false
				_enter(u, "surface")
				u.state = "idle"


static func _enter(u, m: String) -> void:
	u.mode = m
	u.mode_t = 0.0


static func _hold_weapons(u) -> void:
	for w in u.weapons:
		w.cd = maxf(w.cd, 0.4)
		w.windup_t = -1.0


static func _erupt(u, b: Dictionary) -> void:
	u.set_meta("erupts", int(u.get_meta("erupts", 0)) + 1)
	var bt = u.battle
	var r = float(b.get("erupt_radius", 95))
	bt.splash(u.position, r, float(b.get("erupt_damage", 120)), "blast", u.side, "ground", false, u, {"machine": 0.6})
	for e in bt.query(u.position, r * 1.3, Combat.enemy_of(u.side), "ground"):
		if not e.is_static:
			e.position.x += signf(e.position.x - u.position.x + 0.01) * 36.0
	bt.fx.explosion(u.position + Vector2(0, -20), 1.8, "dirt")
	bt.shake(10.0)
	Audio.play("boss", u.position.x, 2.0)
	var sp: Array = b.get("support", {}).get("erupt_spawn", [])
	if sp.size() == 2:
		for i in int(sp[1]):
			if u.support_alive.size() >= int(b.get("support", {}).get("cap", 10)):
				break
			var z = bt.spawn_unit(sp[0], u.side, Vector2(u.position.x + bt.rng.randf_range(-30, 30), 0), true)
			if z != null:
				u.support_alive.append(z)


static func _support(u, dt: float, b: Dictionary) -> void:
	var s: Dictionary = b.get("support", {})
	if s.is_empty():
		return
	u.support_alive = u.support_alive.filter(func(z): return is_instance_valid(z) and z.alive)
	u.support_t += dt
	if u.support_t < float(s.get("interval", 19.0)):
		return
	u.support_t = 0.0
	var bt = u.battle
	for grp in s.get("waves", []):
		for i in int(grp[1]):
			if u.support_alive.size() >= int(s.get("cap", 10)):
				return
			var z = bt.spawn_unit(grp[0], u.side, Vector2(Combat.UNDEAD_BASE_X - 90.0 - bt.rng.randf() * 40.0, 0), true)
			if z != null:
				u.support_alive.append(z)
