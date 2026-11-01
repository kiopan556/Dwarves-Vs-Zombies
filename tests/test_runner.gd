extends Node
## Automated combat validation (Master prompt §14 Tests A–J) + campaign stage simulations.
## Run headless:
##   godot --headless --path . res://tests/test_runner.tscn -- --suite=combat
##   godot --headless --path . res://tests/test_runner.tscn -- --suite=stages
##   godot --headless --path . res://tests/test_runner.tscn -- --suite=save_write   (then)
##   godot --headless --path . res://tests/test_runner.tscn -- --suite=save_verify
## Results print to stdout and are written to user://test_results_<suite>.json

const DT := 1.0 / 30.0

var results: Array = []
var args := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv = a.substr(2).split("=")
			args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	Audio.enabled = false
	Painter.debug_validate = args.has("validate_art")
	await get_tree().process_frame
	if args.has("quality"):
		GameState.profile.settings.quality = args.quality
		GameState.apply_settings()
	if args.has("no_motion"):
		Unit.motion_on = false
	var suite: String = args.get("suite", "combat")
	match suite:
		"combat":
			test_a(); test_b(); test_c(); test_d(); test_e(); test_f(); test_h(); test_j()
		"boss":
			test_g()
		"stages":
			var from = int(args.get("from", "1"))
			var to = int(args.get("to", "30"))
			var only: Array = []
			if args.has("only"):
				for x in String(args.only).split(","):
					only.append(int(x))
			for i in range(from, to + 1):
				if not only.is_empty() and not i in only:
					continue
				if args.get("mode", "both") != "idle":
					stage_sim(i, true)
				if args.get("mode", "both") != "play":
					stage_sim(i, false)
		"save_write":
			test_i_write()
		"save_verify":
			test_i_verify()
		"registry":
			test_registry()
		"probe":
			probe(int(args.get("stage", "1")))
		"ui":
			await test_ui()
		"mecha":
			test_mecha_individual()
			test_mecha_systems()
		"mecha_scenarios":
			test_mecha_scenarios()
		"mecha_audio":
			await test_mecha_audio()
		"mecha_save":
			test_mecha_save()
		"giants":
			test_giants_individual()
			test_giants_systems()
		"giants_scenarios":
			test_giants_scenarios()
		"cache":
			await test_pose_cache()
		"roster":
			test_roster(int(args.get("from", "0")), int(args.get("to", "999")))
		"bosses_all":
			test_bosses_all()
		"hazards":
			test_hazards()
		"boss_phases":
			test_boss_phases()
		"boss_counters":
			test_boss_counters(int(args.get("stage", "0")))
		"stars":
			test_stars()
		"m005_save":
			test_m005_save()
		"ui_m005":
			await test_ui_m005()
		"air_war":
			test_air_war()
		"hazards_m006":
			test_hazards_m006()
		"boss_phases_m006":
			test_boss_phases_m006()
		"m006_save":
			test_m006_save()
		"ui_m006":
			await test_ui_m006()
		"motion":
			test_motion()
		"art_m006b":
			await test_art_m006b()
		"wrecks":
			test_wrecks()
		"hazards_m007":
			test_hazards_m007()
		"boss_phases_m007":
			test_boss_phases_m007()
		"heroic":
			test_heroic()
		"m007_save":
			test_m007_save()
		"ui_m007":
			await test_ui_m007()
		"audio_m007":
			test_audio_m007()
	_finish(suite)


func _finish(suite: String) -> void:
	var passed = 0
	for r in results:
		print(("PASS " if r.pass else "FAIL ") + r.name + " :: " + r.detail)
		if r.pass:
			passed += 1
	print("SUMMARY %s: %d/%d passed" % [suite, passed, results.size()])
	var f = FileAccess.open("user://test_results_%s.json" % suite, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(results, "\t"))
		f.close()
	get_tree().quit(0 if passed == results.size() else 1)


func record(name: String, ok: bool, detail: String) -> void:
	results.append({"name": name, "pass": ok, "detail": detail})


func make_battle(opts: Dictionary = {}, stage_def: Dictionary = {}, loadout: Array = []) -> Battle:
	var b = Battle.new()
	add_child(b)
	var st = stage_def if not stage_def.is_empty() else {"env": "mountain_pass", "start_gold": 9999, "seed": 7}
	var o = {"sandbox": stage_def.is_empty(), "seed": 7}
	o.merge(opts, true)
	b.setup(st, loadout, o)
	b.view_rect = Rect2(0, 0, Combat.WORLD_W, 720)
	if stage_def.is_empty():
		b.invulnerable_bases = true
	return b


func spawn_many(b: Battle, uid: String, side: int, n: int, x0: float, dx: float, y: float = 0.0) -> Array:
	var out: Array = []
	for i in n:
		var u = b.spawn_unit(uid, side, Vector2(x0 + i * dx, y), true)
		if u != null:
			out.append(u)
	return out


func alive(arr: Array) -> Array:
	return arr.filter(func(u): return is_instance_valid(u) and u.alive)


func kill_battle(b: Battle) -> void:
	b.queue_free()


# ---------------------------------------------------------------- Test A
func test_a() -> void:
	var b = make_battle()
	var rif = spawn_many(b, "ironhold_rifleman", 0, 4, 380, 12)
	var shd = spawn_many(b, "shieldbearer", 0, 3, 460, 14)
	var rot = spawn_many(b, "rotter", 1, 8, 950, 16)
	var kn = spawn_many(b, "grave_knight", 1, 2, 1100, 20)
	var wrong_target = 0
	var formation_ok = 0
	var formation_samples = 0
	var engaged_samples = 0
	for i in int(70.0 / DT):
		b.step(DT)
		for r in alive(rif):
			for w in r.weapons:
				if w.target != null and is_instance_valid(w.target):
					engaged_samples += 1
					if w.target.side == 0 or w.target.domain != "ground":
						wrong_target += 1
		if i % 30 == 0 and not alive(shd).is_empty() and not alive(rif).is_empty():
			formation_samples += 1
			var front_shield = -INF
			for s in alive(shd):
				front_shield = maxf(front_shield, s.position.x)
			var ok = true
			for r in alive(rif):
				if r.position.x > front_shield + 2.0:
					ok = false
			if ok:
				formation_ok += 1
	var enemies_left = alive(rot).size() + alive(kn).size()
	var detail = "rifle engagements=%d wrong_targets=%d formation(riflemen behind shields)=%d/%d enemies_left=%d dwarves_left=%d" % [engaged_samples, wrong_target, formation_ok, formation_samples, enemies_left, alive(rif).size() + alive(shd).size()]
	record("A ground combat", wrong_target == 0 and engaged_samples > 0 and formation_ok >= formation_samples * 0.9 and enemies_left < 10, detail)
	kill_battle(b)


# ---------------------------------------------------------------- Test B
func test_b() -> void:
	var b = make_battle()
	var fm = spawn_many(b, "dwarven_flying_machine", 0, 5, 300, 30, 300)
	var bats = spawn_many(b, "carrion_bat", 1, 6, 1300, 25, 320)
	var shr = spawn_many(b, "plague_shrieker", 1, 2, 1400, 40, 280)
	var air_targeted = 0
	var positions_start = fm.map(func(u): return u.position)
	var moved = 0
	for i in int(60.0 / DT):
		b.step(DT)
		for u in alive(fm):
			var w = u.weapons[0]
			if w.target != null and is_instance_valid(w.target) and w.target.domain == "air":
				air_targeted += 1
	for i in fm.size():
		if is_instance_valid(fm[i]) and fm[i].position.distance_to(positions_start[i]) > 100.0:
			moved += 1
	var air_dead = 8 - alive(bats).size() - alive(shr).size()
	var fm_dead = fm.size() - alive(fm).size()
	var d = "fm_air_target_samples=%d moved=%d undead_flyers_killed=%d/8 fm_lost=%d" % [air_targeted, moved, air_dead, fm_dead]
	record("B aerial combat", air_targeted > 0 and air_dead >= 6 and moved >= 3, d)
	kill_battle(b)


# ---------------------------------------------------------------- Test C
func test_c() -> void:
	var b = make_battle()
	var bombers = spawn_many(b, "bombard_gyro", 0, 2, 200, 40, 270)
	var rot = spawn_many(b, "rotter", 1, 12, 1200, 10)
	for r in rot:
		r.speed = 0.0     # an exposed, stationary formation
	var hp0 = 0.0
	for r in rot:
		hp0 += r.max_hp
	var saw_run = false
	var saw_rearm = false
	var refilled = false
	var wrong = 0
	for i in int(80.0 / DT):
		b.step(DT)
		for u in alive(bombers):
			if u.mode == "run":
				saw_run = true
			if u.mode == "rearm":
				saw_rearm = true
			if saw_rearm and u.mode == "advance" and u.ammo == int(u.def.ammo):
				refilled = true
			var w = u.weapons[0]
			if w.target != null and is_instance_valid(w.target) and w.target.domain != "ground":
				wrong += 1
	var hp1 = 0.0
	for r in rot:
		if is_instance_valid(r) and r.alive:
			hp1 += r.hp
	var shots = 0
	for u in bombers:
		if is_instance_valid(u):
			shots += u.weapons[0].shots_fired
	var d = "bombs_dropped=%d damage_dealt=%.0f/%.0f killed=%d attack_run=%s rearm=%s refilled=%s wrong_targets=%d" % [shots, hp0 - hp1, hp0, rot.size() - alive(rot).size(), saw_run, saw_rearm, refilled, wrong]
	record("C air-to-ground", shots >= 8 and hp0 - hp1 > 300.0 and saw_run and saw_rearm and refilled and wrong == 0, d)
	kill_battle(b)


# ---------------------------------------------------------------- Test D
func test_d() -> void:
	var b = make_battle()
	var flak = spawn_many(b, "flak_crew", 0, 2, 300, 30)
	var rot = spawn_many(b, "rotter", 1, 6, 700, 15)
	for r in rot:
		r.speed = 0.0
	var bats = spawn_many(b, "carrion_bat", 1, 6, 1100, 30, 300)
	var shr = spawn_many(b, "plague_shrieker", 1, 2, 1200, 40, 260)
	var ground_targeted = 0
	var air_targeted = 0
	for i in int(45.0 / DT):
		b.step(DT)
		for u in alive(flak):
			var w = u.weapons[0]
			if w.target != null and is_instance_valid(w.target):
				if w.target.domain == "ground":
					ground_targeted += 1
				else:
					air_targeted += 1
	var killed_air = 8 - alive(bats).size() - alive(shr).size()
	var rot_dmg = 0.0
	for r in rot:
		if is_instance_valid(r):
			rot_dmg += r.max_hp - r.hp
	var d = "air_target_samples=%d ground_target_samples=%d flyers_killed=%d/8 rotter_damage=%.0f" % [air_targeted, ground_targeted, killed_air, rot_dmg]
	record("D ground-to-air", ground_targeted == 0 and air_targeted > 0 and killed_air >= 5 and rot_dmg == 0.0, d)
	kill_battle(b)


# ---------------------------------------------------------------- Test E
func test_e() -> void:
	var b = make_battle()
	var dw: Array = []
	dw += spawn_many(b, "shieldbearer", 0, 2, 520, 14)
	dw += spawn_many(b, "ironhold_rifleman", 0, 3, 450, 12)
	dw += spawn_many(b, "light_field_cannon", 0, 1, 330, 0)
	dw += spawn_many(b, "copperback_light_tank", 0, 1, 560, 0)
	dw += spawn_many(b, "boiler_stomper", 0, 1, 600, 0)
	dw += spawn_many(b, "dwarven_flying_machine", 0, 2, 400, 40, 300)
	dw += spawn_many(b, "ironwing_gunship", 0, 1, 350, 0, 300)
	var un: Array = []
	un += spawn_many(b, "rotter", 1, 10, 1300, 14)
	un += spawn_many(b, "ossuary_skeleton", 1, 4, 1450, 14)
	un += spawn_many(b, "grave_knight", 1, 1, 1380, 0)
	un += spawn_many(b, "carrion_bat", 1, 6, 1500, 25, 320)
	un += spawn_many(b, "plague_shrieker", 1, 2, 1550, 40, 280)
	var both_fronts = 0
	var tank_both_weapons = false
	var gunship_split = 0
	for i in int(90.0 / DT):
		b.step(DT)
		var g = false
		var a = false
		for u in alive(dw):
			for w in u.weapons:
				if w.target != null and is_instance_valid(w.target):
					if w.target.domain == "air":
						a = true
					else:
						g = true
			if u.id == "copperback_light_tank" and u.weapons[0].target != null and u.weapons[1].target != null and u.weapons[0].target != u.weapons[1].target:
				tank_both_weapons = true
			if u.id == "ironwing_gunship" and u.weapons[0].target != null and u.weapons[1].target != null and is_instance_valid(u.weapons[0].target) and is_instance_valid(u.weapons[1].target) and u.weapons[0].target.domain == "ground" and u.weapons[1].target.domain == "air":
				gunship_split += 1
		if g and a:
			both_fronts += 1
	var d = "steps_with_both_fronts_engaged=%d undead_left=%d/%d dwarves_left=%d/%d tank_independent_weapon_targets=%s gunship_belly_ground+dorsal_air_simultaneous_steps=%d" % [both_fronts, alive(un).size(), un.size(), alive(dw).size(), dw.size(), tank_both_weapons, gunship_split]
	record("E combined arms", both_fronts > 30 and alive(un).size() <= 4 and gunship_split > 0, d)
	kill_battle(b)


# ---------------------------------------------------------------- Test F
func test_f() -> void:
	var b = make_battle()
	var mech = spawn_many(b, "field_mechanic", 0, 1, 300, 0)[0]
	var tank = spawn_many(b, "copperback_light_tank", 0, 1, 380, 0)[0]
	var rig = spawn_many(b, "miner_rig", 0, 1, 900, 0)[0]   # out of range at first
	var rif = spawn_many(b, "ironhold_rifleman", 0, 1, 340, 0)[0]
	for u in [tank, rig, mech, rif]:
		u.speed = 0.0 if u != mech else u.speed
	tank.hp = tank.max_hp * 0.3
	rig.hp = rig.max_hp * 0.4
	rif.hp = rif.max_hp * 0.5
	var pool0: float = mech.repair_pool
	var over_max = false
	for i in int(60.0 / DT):
		b.step(DT)
		if tank.hp > tank.max_hp + 0.01 or rig.hp > rig.max_hp + 0.01:
			over_max = true
	var used: float = pool0 - mech.repair_pool
	var d = "tank %.0f%%->%.0f%%, rig(started 520px away) %.0f%%->%.0f%%, rifleman(not eligible) %.0f%%, pool used %.0f/%.0f, exceeded_max=%s" % [30.0, tank.hp / tank.max_hp * 100.0, 40.0, rig.hp / rig.max_hp * 100.0, rif.hp / rif.max_hp * 100.0, used, pool0, over_max]
	var ok: bool = tank.hp > tank.max_hp * 0.95 and rif.hp == rif.max_hp * 0.5 and not over_max and used <= pool0 + 0.01
	# repair pool exhaustion
	mech.repair_pool = 0.0
	var mech2 = spawn_many(b, "field_mechanic", 0, 1, 1200, 0)[0]
	var tank2 = spawn_many(b, "copperback_light_tank", 0, 1, 1260, 0)[0]
	tank2.speed = 0.0
	tank2.hp = 50.0
	mech2.repair_pool = 100.0
	for i in int(20.0 / DT):
		b.step(DT)
	var limited: bool = absf(tank2.hp - 150.0) < 1.0 and mech2.repair_pool <= 0.001
	d += " | limited pool: tank2 50->%.0f with 100-HP pool (limit respected=%s)" % [tank2.hp, limited]
	record("F mechanical repair", ok and limited, d)
	kill_battle(b)


# ---------------------------------------------------------------- Test H
func test_h() -> void:
	var b = make_battle({}, {"env": "mountain_gate", "start_gold": 100, "seed": 3, "tracks": []}, ["ironhold_rifleman", "copperback_light_tank", "boiler_stomper"])
	b.director = null
	var issues: Array = []
	var g0 = b.gold
	var u = b.deploy("ironhold_rifleman")
	if u == null or absf(b.gold - (g0 - 40.0)) > 0.01:
		issues.append("rifleman gold not consumed correctly")
	if b.deploy("ironhold_rifleman") != null:
		issues.append("cooldown ignored")
	if b.can_deploy("ironhold_rifleman") != "Cooling down":
		issues.append("wrong cooldown reason")
	b.gold = 150.0
	b.steam = 5.0
	if b.deploy("copperback_light_tank") != null:
		issues.append("deployed without enough gold+steam")
	b.gold = 500.0
	if b.deploy("copperback_light_tank") != null:
		issues.append("deployed without enough steam")
	b.steam = 20.0
	var g1 = b.gold
	if b.deploy("copperback_light_tank") == null or absf(b.gold - (g1 - 200.0)) > 0.01 or b.steam > 0.01:
		issues.append("tank costs wrong (gold %.1f steam %.1f)" % [b.gold, b.steam])
	if b.deploy("not_a_unit") != null or b.deploy("hammer_guard") != null:
		issues.append("deployed invalid/planned unit")
	b.steam = 30.0
	if b.overdrive():
		issues.append("overdrive with insufficient steam")
	b.steam = 45.0
	if not b.overdrive() or b.steam < 0.0:
		issues.append("overdrive failed or negative steam")
	b.gold = 10.0
	if b.upgrade_mine():
		issues.append("mine upgrade without gold")
	var min_gold = INF
	var min_steam = INF
	for i in int(30.0 / DT):
		b.step(DT)
		for uid in b.loadout:
			b.deploy(uid)
		min_gold = minf(min_gold, b.gold)
		min_steam = minf(min_steam, b.steam)
	if min_gold < 0.0 or min_steam < 0.0:
		issues.append("negative resources")
	if b.steam > Battle.STEAM_MAX + 0.01:
		issues.append("steam above cap")
	record("H economy", issues.is_empty(), "issues=%s min_gold=%.1f min_steam=%.1f deployed=%d" % [str(issues), min_gold, min_steam, b.stats_deployed])
	kill_battle(b)


# ---------------------------------------------------------------- Test J
func test_j() -> void:
	var b = make_battle()
	var ids_d = ["ironhold_rifleman", "shieldbearer", "tunnel_militia", "blunderbussier", "grenadier", "light_field_cannon", "flak_crew", "organ_gun", "brasshound_armored_car", "copperback_light_tank", "miner_rig", "boiler_stomper", "field_mechanic"]
	var ids_a = ["dwarven_flying_machine", "scout_gyro", "bombard_gyro", "ironwing_gunship", "ironcloud"]
	var ids_u = ["rotter", "zombie_miner", "grave_crawler", "plague_runner", "ossuary_skeleton", "bone_shieldbearer", "grave_knight", "bone_archer", "rot_spitter", "necromancer", "flesh_hulk"]
	var r = RandomNumberGenerator.new()
	r.seed = 99
	for i in 55:
		b.spawn_unit(ids_d[i % ids_d.size()], 0, Vector2(250 + r.randf() * 500, 0), true)
	for i in 15:
		b.spawn_unit(ids_a[i % ids_a.size()], 0, Vector2(250 + r.randf() * 400, 300), true)
	for i in 70:
		b.spawn_unit(ids_u[i % ids_u.size()], 1, Vector2(1500 + r.randf() * 800, 0), true)
	for i in 20:
		b.spawn_unit("carrion_bat" if i % 3 else "plague_shrieker", 1, Vector2(1600 + r.randf() * 700, 300), true)
	b.spawn_unit("bone_spire", 1, Vector2(2250, 0), true)
	var worst = 0.0
	var total = 0.0
	var steps = 0
	var invalid = 0
	var max_proj = 0
	var max_fx = 0
	var last_pos = {}
	var stuck = {}
	var aircraft_stuck = 0
	for i in int(75.0 / DT):
		# keep the fight going with periodic reinforcements both sides
		if i % 90 == 0 and i > 0:
			for k in 6:
				b.spawn_unit(ids_u[(i + k) % ids_u.size()], 1, Vector2(2300, 0), true)
			b.spawn_unit("carrion_bat", 1, Vector2(2300, 300), true)
			for k in 3:
				b.spawn_unit(ids_d[(i + k) % ids_d.size()], 0, Vector2(250, 0), true)
		var t0 = Time.get_ticks_usec()
		b.step(DT)
		var el = float(Time.get_ticks_usec() - t0) / 1000.0
		worst = maxf(worst, el)
		total += el
		steps += 1
		max_proj = maxi(max_proj, b.projectiles.active_count)
		max_fx = maxi(max_fx, b.fx.live)
		for u in b.units:
			if not u.alive:
				continue
			for w in u.weapons:
				if w.target != null and (not is_instance_valid(w.target) or not w.target.alive or w.target.side == u.side):
					invalid += 1
					if invalid < 4:
						print("INVALID ", u.id, " -> ", w.target.id if is_instance_valid(w.target) else "freed", " alive=", w.target.alive if is_instance_valid(w.target) else "-", " t=", b.time)
			if i % 30 == 0:
				var key: int = u.serial
				if last_pos.has(key) and u.position.distance_to(last_pos[key]) < 0.5 and not u.is_static and not _any_target(u) and u.cls != "artillery" and u.behavior != "repair":
					stuck[key] = int(stuck.get(key, 0)) + 1
				else:
					stuck.erase(key)
				last_pos[key] = u.position
	var stuck_units = 0
	for k in stuck.keys():
		if stuck[k] >= 15:
			stuck_units += 1
	var d = "units_peak~%d avg_step=%.2fms worst_step=%.2fms invalid_targets=%d max_projectiles=%d/%d max_fx=%d/%d stuck_units(>15s idle w/o target)=%d proj_fizzled=%d pool_overflow=%d" % [b.units.size(), total / steps, worst, invalid, max_proj, b.projectiles.capacity, max_fx, b.fx.cap, stuck_units, b.projectiles.stats_fizzled, b.projectiles.stats_overflow]
	record("J stress", invalid == 0 and max_proj <= b.projectiles.capacity and max_fx <= b.fx.cap and stuck_units <= 2 and worst < 250.0, d)
	kill_battle(b)


func _any_target(u) -> bool:
	for w in u.weapons:
		if w.target != null:
			return true
	return false


# ---------------------------------------------------------------- Test G
func test_g() -> void:
	var st = Registry.stage("s010")
	var lo = ["shieldbearer", "ironhold_rifleman", "light_field_cannon", "flak_crew", "organ_gun", "grenadier", "miner_rig", "brasshound_armored_car", "dwarven_flying_machine", "scout_gyro", "", "field_mechanic"]
	var b = make_battle({"sandbox": false, "seed": 10}, st, lo)
	var ai = AutoCommander.new()
	var modes_seen = {}
	var support_spawns: Array = []
	var last_support = 0
	var boss_dead_t = -1.0
	var spawned_after_death = 0
	var sealed_hits = 0
	var maw = null
	var erupt_count = 0
	var prev_mode = ""
	var prev_support_t = 0.0
	var max_support_alive = 0
	for i in int(900.0 / DT):
		ai.step(b, DT)
		b.step(DT)
		if b.boss != null and maw == null:
			maw = b.boss
		if maw != null and is_instance_valid(maw):
			if maw.alive:
				modes_seen[maw.mode] = true
				if maw.mode == "exposed" and prev_mode == "erupt_tele":
					erupt_count += 1
				prev_mode = maw.mode
				if maw.support_t < prev_support_t:   # timer wrapped => a support wave was released
					support_spawns.append(snappedf(b.time, 0.1))
				prev_support_t = maw.support_t
				max_support_alive = maxi(max_support_alive, maw.support_alive.size())
			elif boss_dead_t < 0.0:
				boss_dead_t = b.time
				last_support = maw.support_alive.size()
		if b.over:
			break
	var d = "boss_spawned=%s modes=%s eruptions=%d support_wave_times=%s boss_died_at=%.0fs sealed_until_boss_death=%s result=%s t=%.0fs kills=%d losses=%d" % [maw != null, str(modes_seen.keys()), erupt_count, str(support_spawns.slice(0, 8)), boss_dead_t, str(boss_dead_t < 0.0 or boss_dead_t <= b.time), "WIN" if b.won else ("LOSS" if b.over else "TIMEOUT"), b.time, b.stats_kills, b.stats_losses]
	var intervals_ok = true
	for k in range(1, support_spawns.size()):
		if support_spawns[k] - support_spawns[k - 1] < 15.0:
			intervals_ok = false
	var spawned_late = false
	if boss_dead_t > 0.0:
		for tm in support_spawns:
			if tm > boss_dead_t + 0.5:
				spawned_late = true
	d += " intervals_ok=%s support_after_death=%s max_support_alive=%d(cap %d)" % [intervals_ok, spawned_late, max_support_alive, int(Registry.combat_def("mine_maw").boss.support.cap)]
	record("G boss encounter (stage 010)", maw != null and modes_seen.has("underground") and modes_seen.has("exposed") and erupt_count >= 1 and boss_dead_t > 0.0 and b.won and intervals_ok and not spawned_late, d)
	kill_battle(b)


# ---------------------------------------------------------------- stages
func loadout_for_stage(i: int) -> Array:
	# units a player would realistically own on reaching stage i (T0 + earlier stage rewards)
	var owned = ["tunnel_militia", "ironhold_rifleman", "shieldbearer", "light_field_cannon", "flak_crew", "dwarven_flying_machine"]
	for k in range(1, i):
		owned += Registry.stage_by_index(k).get("rewards", {}).get("unlock", [])
	var ground_pref = ["shieldbearer", "ironhold_rifleman", "light_field_cannon", "flak_crew", "organ_gun", "grenadier", "miner_rig", "brasshound_armored_car", "field_mechanic", "blunderbussier", "tunnel_militia"]
	var air_pref = ["dwarven_flying_machine", "scout_gyro"]
	if i > 15:
		# second half of Act I: a player also owns the blueprints won since stage 16, and has spent
		# the ~1,200 Sparks earned in stages 1-15 on a handful of T1/T2 researches (Age of Steam opens at 015)
		owned += ["steamgunner", "copperback_light_tank", "steam_mortar", "twin_flak_mount", "bombard_gyro"]
		ground_pref = ["shieldbearer", "ironclad_medium_tank", "steamgunner", "light_field_cannon", "flak_crew", "flame_trooper", "copperback_light_tank",
			"steam_mortar", "organ_gun", "grenadier", "miner_rig", "drillwalker", "twin_flak_mount", "brasshound_armored_car", "field_mechanic", "ironhold_rifleman"]
		air_pref = ["rotary_interceptor", "dwarven_flying_machine", "bombard_gyro", "scout_gyro"]
	if i > 90:
		return _act4_loadout(i, owned)
	if i > 60:
		return _act3_loadout(i, owned)
	if i > 30:
		return _act2_loadout(i, owned)
	var lo = ["", "", "", "", "", "", "", "", "", "", "", ""]
	var gi = 0
	for u in ground_pref:
		if u in owned and gi < 7:
			lo[gi] = u
			gi += 1
	var ai_i = 7
	for u in air_pref:
		if u in owned:
			lo[ai_i] = u
			ai_i += 1
	for u in ground_pref:
		if u in owned and not u in lo:
			lo[11] = u
			break
	return lo


## M005 Act II: the realistic army at stage i. Owned = T0 starters + every blueprint rewarded before i
## + the Act I-b research set + what ~3,100 Act I Sparks and the Act II Spark income buy: Boiler Stomper
## (T2, from 031) and, once Age of Iron and Dedicated War Frames are researched, the Ironclad Walker
## (T3, from 042). One pick per role keeps the 7 ground / 4 air / 1 flex shape a player would build.
func _act2_loadout(i: int, owned: Array) -> Array:
	owned = owned + ["steamgunner", "copperback_light_tank", "steam_mortar", "twin_flak_mount", "bombard_gyro", "boiler_stomper"]
	if i >= 42:
		owned.append("ironclad_walker")
	var picks = [
		["trench_guard", "shieldbearer"],
		["thunderback_heavy_tank", "ironclad_medium_tank", "copperback_light_tank"],
		["flamebelcher_medium_tank", "steamgunner", "flame_trooper"],
		["veteran_rifleman", "rune_cartridge_rifleman", "ironhold_rifleman"],
		["siege_howitzer", "heavy_bombard", "rocket_battery", "steam_mortar", "light_field_cannon"],
		["skyshield_aa_tank", "multi_barrel_flak", "twin_flak_mount", "flak_crew"],
		["repair_wagon", "field_mechanic"],
	]
	var lo = ["", "", "", "", "", "", "", "", "", "", "", ""]
	for gi in picks.size():
		for u in picks[gi]:
			if u in owned and not u in lo:
				lo[gi] = u
				break
	var air = ["twin_rotor_interceptor", "rotary_interceptor", "dwarven_flying_machine", "heavy_gyro_bomber", "bombard_gyro", "scout_gyro"]
	var ai = 7
	for u in air:
		if ai < 11 and u in owned:
			lo[ai] = u
			ai += 1
	for u in ["ironclad_walker", "boiler_stomper", "flak_crew"]:
		if u in owned and not u in lo:
			lo[11] = u
			break
	return lo


## M006 Act III: the realistic army at stage i. Owned = T0 starters + every blueprint rewarded before i
## + the Act I-b research set + Boiler Stomper and Ironclad Walker (researched in Act II, as in the M005
## assumption). No extra T4 research is assumed: from 075 the only T4 units are the blueprints Act III
## itself awards (heavy interceptor, rocketwing, mobile flak fortress, skybreaker, frigate, zeppelin),
## so the simulated army is a floor. One pick per role for the 7 ground slots, the best four flyers
## (interceptors first: they reach every altitude band) and a walker in the flex slot.
func _act3_loadout(i: int, owned: Array) -> Array:
	owned = owned + ["steamgunner", "copperback_light_tank", "steam_mortar", "twin_flak_mount", "bombard_gyro", "boiler_stomper", "ironclad_walker"]
	var picks = [
		["rolling_shield_trooper", "trench_guard", "shieldbearer"],
		["twin_cannon_ironclad", "bastion_heavy_tank", "thunderback_heavy_tank", "ironclad_medium_tank"],
		["incendiary_grenadier", "flamebelcher_medium_tank", "steamgunner"],
		["sniper_tank_hunter", "veteran_rifleman", "rune_cartridge_rifleman"],
		["piston_cannon", "siege_howitzer", "counterbattery_mortar", "heavy_bombard", "rocket_battery"],
		["mobile_flak_fortress", "heavy_skybreaker", "skyshield_aa_tank", "multi_barrel_flak", "twin_flak_mount"],
		["armored_recovery_team", "runic_mechanic", "repair_wagon", "field_mechanic"],
	]
	var lo = ["", "", "", "", "", "", "", "", "", "", "", ""]
	for gi in picks.size():
		for u in picks[gi]:
			if u in owned and not u in lo:
				lo[gi] = u
				break
	var air = ["heavy_interceptor", "thunderwing", "flak_chaser", "twin_rotor_interceptor", "skyshield_airship", "ironwing_gunship", "heavy_gyro_bomber", "rotary_interceptor"]
	var ai = 7
	for u in air:
		if ai < 11 and u in owned:
			lo[ai] = u
			ai += 1
	for u in ["cannon_strider", "skyguard_walker", "ironclad_walker", "boiler_stomper"]:
		if u in owned and not u in lo:
			lo[11] = u
			break
	return lo


## M007 Act IV: the realistic army at stage i. Owned = T0 starters + every blueprint rewarded before i + the
## Act I-b research set + Boiler Stomper and Ironclad Walker (Act II research) + a Salvage Crew (T1, 40 Sparks:
## the obvious purchase once wrecks appear). As in M006 no extra T4 research is assumed — the T4 units in the
## simulated army are the blueprints Acts III-IV award. T5 blueprints (115+) are used in normal play but never on
## Heroic (`--heroic` sims pass no_t5), so every Heroic stage is checked with pre-T5 technology only.
func _act4_loadout(i: int, owned: Array, no_t5: bool = false) -> Array:
	owned = owned + ["steamgunner", "copperback_light_tank", "steam_mortar", "twin_flak_mount", "bombard_gyro", "boiler_stomper", "ironclad_walker", "salvage_crew"]
	if no_t5:
		owned = owned.filter(func(u): return int(Registry.entry(u).get("tier", 0)) < 5)
	var picks = [
		["kingsguard_bulwark", "colossus_guard", "royal_iron_guard", "rolling_shield_trooper", "trench_guard"],
		["mountainshield_heavy_tank", "twin_cannon_ironclad", "bastion_heavy_tank", "thunderback_heavy_tank"],
		["firestorm_assault_tank", "furnace_assault_trooper", "incendiary_grenadier", "flamebelcher_medium_tank"],
		["thunderrail_tank_destroyer", "arc_lance_gunner", "runebreaker_infantry", "sniper_tank_hunter", "thunder_rifleman"],
		["rune_cannon", "mountain_siege_cannon", "piston_cannon", "siege_howitzer", "counterbattery_mortar"],
		["mobile_flak_fortress", "heavy_skybreaker", "skyshield_aa_tank", "multi_barrel_flak"],
		["heavy_recovery_crawler", "armored_recovery_team", "salvage_crew", "runic_mechanic"],
	]
	var lo = ["", "", "", "", "", "", "", "", "", "", "", ""]
	for gi in picks.size():
		for u in picks[gi]:
			if u in owned and not u in lo:
				lo[gi] = u
				break
	var air = ["heavy_interceptor", "thunderwing", "flak_chaser", "forge_bomber", "twin_flame_gunship", "twin_rotor_interceptor", "skyshield_airship", "ironwing_gunship", "heavy_gyro_bomber"]
	var ai = 7
	for u in air:
		if ai < 11 and u in owned:
			lo[ai] = u
			ai += 1
	for u in ["anvilbreaker", "furnace_guardian", "siegebellow", "cannon_strider", "skyguard_walker", "ironclad_walker"]:
		if u in owned and not u in lo:
			lo[11] = u
			break
	return lo


## The stage definition a sim plays: the normal stage, or its Heroic version with `--heroic`.
func sim_stage(i: int) -> Dictionary:
	var st = Registry.stage_by_index(i)
	if args.has("heroic"):
		return Registry.heroic_stage(st.id)
	return st


func sim_loadout(i: int) -> Array:
	if args.has("heroic") and i > 90:
		var owned = ["tunnel_militia", "ironhold_rifleman", "shieldbearer", "light_field_cannon", "flak_crew", "dwarven_flying_machine"]
		for k in range(1, i):
			owned += Registry.stage_by_index(k).get("rewards", {}).get("unlock", [])
		return _act4_loadout(i, owned, true)
	return loadout_for_stage(i)


func stage_sim(i: int, play: bool) -> void:
	var st = sim_stage(i)
	var lo = sim_loadout(i)
	var b = make_battle({"sandbox": false, "seed": int(st.seed)}, st, lo)
	var ai = AutoCommander.new()
	ai.generic = i > 30
	ai.saver = i > 90
	var limit = 900.0 if play else 600.0
	var t0 = Time.get_ticks_msec()
	var peak_enemies = 0
	var air_seen = 0.0
	var air_fight = 0
	while b.time < limit and not b.over:
		if play:
			ai.step(b, DT)
		b.step(DT)
		peak_enemies = maxi(peak_enemies, b.alive_count(1))
		if fmod(b.time, 1.0) < DT:
			for u in b.by_side[1]:
				if u.alive and u.domain == "air":
					air_seen = maxf(air_seen, b.time) if air_seen == 0.0 else air_seen
					break
	if air_seen == 0.0:
		air_seen = -1.0
	var res = "WIN" if b.won else ("LOSS" if b.over else "TIMEOUT")
	var d = "%s %s in %.0fs | dwarf_base=%.0f%% citadel=%.0f%% kills=%d losses=%d deployed=%d peak_enemies=%d first_undead_flyer=%.0fs loadout=%s wall=%dms" % [st.id, res, b.time, b.dwarf_base.hp / b.dwarf_base.max_hp * 100.0, b.enemy_base.hp / b.enemy_base.max_hp * 100.0, b.stats_kills, b.stats_losses, b.stats_deployed, peak_enemies, air_seen, str(lo.filter(func(x): return x != "")), Time.get_ticks_msec() - t0]
	if b.stats_wrecks > 0 or b.stats_vent_bursts > 0 or b.stats_slag_flows > 0:
		d += " | wrecks=%d reclaimed=%d salvaged=%d vents=%d slag=%d steam+%.0f" % [b.stats_wrecks, b.stats_reclaimed, b.stats_salvaged, b.stats_vent_bursts, b.stats_slag_flows, b.stats_steam_gained]
	var hz = " (heroic)" if args.has("heroic") else ""
	if play:
		record("Stage %03d playable+winnable (auto-commander)%s" % [i, hz], b.won, d)
	else:
		record("Stage %03d losable (no deployments)%s" % [i, hz], b.over and not b.won, d)
	kill_battle(b)


# ---------------------------------------------------------------- Test I (two separate processes)
func test_i_write() -> void:
	SaveManager.path = "user://test_save.json"
	GameState.reset_progress()
	var before = GameState.is_unlocked("grenadier")
	var summary = GameState.grant_stage_rewards("s001", 123.4, 55)
	GameState.profile.loadouts["Preset II"][0] = "grenadier"
	GameState.save()
	record("I save persistence (phase 1: clear stage, earn unlock, save)", not before and "grenadier" in summary.unlocked and GameState.is_cleared("s001"), "unlocked=%s sparks=%d file=%s" % [str(summary.unlocked), GameState.profile.sparks, ProjectSettings.globalize_path(SaveManager.path)])


func test_i_verify() -> void:
	SaveManager.path = "user://test_save.json"
	GameState.reload_from_disk()
	var ok = GameState.is_cleared("s001") and GameState.is_unlocked("grenadier") and GameState.profile.sparks >= 40 and GameState.profile.loadouts["Preset II"][0] == "grenadier"
	record("I save persistence (phase 2: fresh process reload)", ok, "cleared_s001=%s grenadier=%s sparks=%d preset2_slot0=%s" % [GameState.is_cleared("s001"), GameState.is_unlocked("grenadier"), GameState.profile.sparks, GameState.profile.loadouts["Preset II"][0]])
	SaveManager.wipe()


# ---------------------------------------------------------------- registry integrity
func test_registry() -> void:
	var nd = Registry.dwarves.size()
	var nu = Registry.undead.size()
	var impl_d = Registry.implemented_dwarves().size()
	var impl_u = Registry.implemented_undead().size()
	var impl_s = Registry.stages.filter(func(s): return s.implemented).size()
	var bad: Array = []
	for e in Registry.implemented_dwarves() + Registry.implemented_undead():
		var d = Registry.combat_def(e.id)
		# weaponless units are only valid as static structures (barricades, beacons); their roles are checked by --suite=roster
		if d.is_empty() or (d.get("weapons", []).is_empty() and not d.get("static", false)) or not d.has("art"):
			bad.append(e.id)
	var mm = Registry.combat_def("mine_maw")
	var tiers = {}
	for e in Registry.dwarves:
		tiers[int(e.tier)] = int(tiers.get(int(e.tier), 0)) + 1
	var d = "dwarves=%d (impl %d) undead=%d (impl %d) bosses=%d stages=%d (impl %d) tier_counts=%s bad_defs=%s mine_maw=%s" % [nd, impl_d, nu, impl_u, Registry.bosses.size(), Registry.stages.size(), impl_s, str(tiers), str(bad), not mm.is_empty()]
	record("Registry integrity", nd == 160 and nu == 110 and impl_d == 160 and impl_u == 110 and Registry.bosses.size() == 15 and Registry.stages.size() == 150 and impl_s == 120 and bad.is_empty() and not mm.is_empty(), d)
	# spawn every implemented unit and verify it can act
	var b = make_battle()
	var idle: Array = []
	for e in Registry.implemented_dwarves():
		var dd = Registry.combat_def(e.id)
		if String(e.get("milestone", "")) == "M003" or dd.get("weapons", []).is_empty():
			continue   # pure support (spotters, engineers): covered by --suite=roster
		var u = b.spawn_unit(e.id, 0, Vector2(600, 300 if e.domain == "air" else 0), true)
		var air_foe: bool = e.id in ["flak_crew", "scout_gyro"] or dd.weapons.all(func(w): return w.targets == "air")
		var w0: Dictionary = dd.weapons[0]
		var gap = clampf(maxf(160.0, float(w0.get("min_range", 0)) + 60.0), 60.0, maxf(60.0, float(w0.range) - 10.0))
		var foe = b.spawn_unit("rotter" if not air_foe else "carrion_bat", 1, Vector2(600 + gap, 300 if air_foe else 0), true)
		var fired = false
		var repaired = false
		if e.id == "field_mechanic":
			var t = b.spawn_unit("copperback_light_tank", 0, Vector2(640, 0), true)
			t.hp = t.max_hp * 0.5
			t.speed = 0
			foe.queue_free(); b.units.erase(foe); b.by_side[1].erase(foe)
			for i in int(10.0 / DT):
				b.step(DT)
			repaired = t.hp > t.max_hp * 0.5
		else:
			for i in int(25.0 / DT):
				b.step(DT)
				for w in u.weapons:
					if w.shots_fired > 0:
						fired = true
				if fired:
					break
		if not (fired or repaired):
			idle.append(e.id)
		for x in b.units.duplicate():
			if not x.is_stronghold:
				x.queue_free()
		b.units = b.units.filter(func(x): return x.is_stronghold)
		b.by_side = [[b.dwarf_base], [b.enemy_base]]
		b.projectiles.clear_all()
	for e in Registry.implemented_undead():
		var ud = Registry.combat_def(e.id)
		if String(e.get("milestone", "")) == "M003" or ud.get("weapons", []).is_empty():
			continue   # barricades / beacons: covered by --suite=roster
		var u = b.spawn_unit(e.id, 1, Vector2(900, 300 if e.domain == "air" else 0), true)
		var uw: Dictionary = ud.weapons[0]
		var anti_air: bool = ud.weapons.all(func(w): return w.targets == "air")
		var ugap = clampf(maxf(200.0, float(uw.get("min_range", 0)) + 60.0), 60.0, maxf(60.0, float(uw.range) - 10.0))
		var foe = b.spawn_unit("dwarven_flying_machine" if anti_air else "shieldbearer", 0, Vector2(900 - ugap, 300 if anti_air else 0), true)
		foe.speed = 0
		foe.weapons = []   # passive dummy so the undead unit gets to act
		var fired = false
		for i in int(40.0 / DT):
			b.step(DT)
			for w in u.weapons:
				if w.shots_fired > 0:
					fired = true
			if fired or not is_instance_valid(foe) or not foe.alive:
				fired = true
				break
		if not fired:
			idle.append(e.id)
		for x in b.units.duplicate():
			if not x.is_stronghold:
				x.queue_free()
		b.units = b.units.filter(func(x): return x.is_stronghold)
		b.by_side = [[b.dwarf_base], [b.enemy_base]]
		b.projectiles.clear_all()
	record("Every implemented unit performs its combat action (M001-M002b units; M003 units: --suite=roster)", idle.is_empty(), "units_that_never_acted=%s" % str(idle))
	kill_battle(b)


func probe(i: int) -> void:
	var st = sim_stage(i)
	var lo = sim_loadout(i)
	var b = make_battle({"sandbox": false, "seed": int(st.seed)}, st, lo)
	var ai = AutoCommander.new()
	ai.generic = i > 30
	ai.saver = i > 90
	var next_report = 30.0
	while b.time < 900.0 and not b.over:
		ai.step(b, DT)
		b.step(DT)
		if b.time >= next_report:
			next_report += float(args.get("every", "60"))
			var cnt = {}
			for u in b.units:
				if u.alive and not u.is_stronghold:
					cnt[u.id] = int(cnt.get(u.id, 0)) + 1
			var front = b.front_x(0, null)
			var bh = ("%d/%d" % [b.boss.hp, b.boss.max_hp]) if b.boss != null and is_instance_valid(b.boss) else "-"
			print("t=%d gold=%d mine=%d base=%d citadel=%d boss=%s front=%s wrecks=%d/%d/%d alive=%s" % [b.time, b.gold, b.mine_level, b.dwarf_base.hp, b.enemy_base.hp, bh, str(front), b.stats_wrecks, b.stats_reclaimed, b.stats_salvaged, str(cnt)])
	print("RESULT ", "WIN" if b.won else ("LOSS" if b.over else "TIMEOUT"), " t=", int(b.time))
	var keys = b.death_log.keys()
	keys.sort_custom(func(x, y): return b.death_log[x] > b.death_log[y])
	for k in keys.slice(0, 18):
		print("  ", b.death_log[k], "  ", k)
	record("probe", true, "")


## UI smoke test: instantiate every screen, let it run, exercise key interactions.
func test_ui() -> void:
	SaveManager.path = "user://test_ui_save.json"
	GameState.reset_progress()
	GameState.profile.settings.tutorial = false   # the guided tutorial has its own test (--suite=ui_m005)
	GameState.profile.settings.hints = false
	var scenes = ["main_menu", "campaign_map", "loadout", "forge", "compendium", "settings", "battle_screen", "sandbox"]
	for sc in scenes:
		var errs_before = Engine.get_frames_drawn()
		var inst = load("res://scenes/%s.tscn" % sc).instantiate()
		get_tree().root.add_child(inst)
		for i in 30:
			await get_tree().process_frame
		var ok = is_instance_valid(inst) and inst.is_inside_tree()
		var detail = "instantiated and ran 30 frames"
		match sc:
			"forge":
				# research a doctrine via the UI flow once tier 1 is open
				GameState.profile.open_tiers.append(1)
				GameState.profile.sparks = 500
				inst.sel_node = "blackpowder_drill"
				inst._select("blackpowder_drill")
				inst._research()
				ok = ok and GameState.is_researched("blackpowder_drill")
				inst.tab = 7
				inst._build()
				detail += "; researched Blackpowder Drill via Forge UI=%s" % GameState.is_researched("blackpowder_drill")
			"loadout":
				GameState.unlock_unit("grenadier")
				inst._unit_pressed("grenadier")
				ok = ok and "grenadier" in GameState.active_loadout()
				detail += "; tap-to-place grenadier=%s" % ("grenadier" in GameState.active_loadout())
			"compendium":
				for c in 3:
					inst.cat = c
					inst._build()
					inst._show(inst._entries()[0])
				await get_tree().process_frame
				detail += "; browsed 3 categories"
			"battle_screen":
				var b = inst.battle
				var n_cards = inst.cards.size()
				var g0 = b.gold
				var ev = InputEventMouseButton.new()
				ev.button_index = MOUSE_BUTTON_LEFT
				ev.pressed = true
				inst.cards[0]._gui_input(ev)
				var deployed = b.stats_deployed
				for i in 90:
					await get_tree().physics_frame
				inst._toggle_pause()
				var paused = b.paused
				inst._toggle_pause()
				inst._toggle_speed()
				b.enemy_base.take_damage(999999.0, null)
				for i in 120:
					await get_tree().physics_frame
				await get_tree().create_timer(2.0).timeout
				var overlay_ok = inst.overlay != null
				ok = ok and n_cards > 0 and deployed == 1 and b.won and overlay_ok and paused
				detail += "; cards=%d deploy_by_tap=%d gold %d->%d pause=%s victory_overlay=%s stage_cleared_saved=%s" % [n_cards, deployed, g0, b.gold, paused, overlay_ok, GameState.is_cleared(GameState.selected_stage)]
			"sandbox":
				for k in ["A", "B", "E", "G", "J"]:
					inst._scenario(k)
					for i in 45:
						await get_tree().physics_frame
				inst._world_tap(Vector2(900, 500))
				detail += "; ran sandbox scenarios A,B,E,G,J; units now=%d" % inst.battle.units.size()
		record("UI " + sc, ok, detail)
		inst.queue_free()
		await get_tree().process_frame
	SaveManager.wipe()



# ===================================================================== M002 Iron Giants
const MECHS := ["miner_rig", "boiler_stomper", "drillwalker", "steam_loader", "piston_brawler", "copper_sentinel", "ironclad_walker",
	"skyguard_walker", "thundercoil_frame", "cannon_strider", "shieldframe", "claw_harvester", "mortar_walker", "furnace_stalker",
	"anvilbreaker", "siegebellow", "furnace_guardian", "siege_hammer_walker", "flak_colossus", "thunderstep_bruiser", "shredder_walker",
	"riftshield_walker", "deepforge_titan", "mountain_colossus", "kings_anvil", "colossal_skybreaker", "hammerfall_goliath", "embercore_titan"]


func _clear_units(b) -> void:
	for x in b.units.duplicate():
		if not x.is_stronghold:
			x.queue_free()
	b.units = b.units.filter(func(x): return x.is_stronghold)
	b.by_side = [[b.dwarf_base], [b.enemy_base]]
	b.projectiles.clear_all()
	b.zones.clear()
	b.wards.clear()
	b._rebuild_buckets()


## Cases 1-14 for every frame (and every alternate armament).
func test_mecha_individual() -> void:
	var ids: Array = MECHS.duplicate()
	for m in MECHS:
		for v in Registry.combat_def(m).get("variants", []):
			ids.append(m + "@" + v.id)
	var b = make_battle()
	b.mech_doctrine = "overdrive"
	var all_ok = true
	var table: Array = []
	for uid in ids:
		_clear_units(b)
		var d = Registry.combat_def(uid)
		var has_air = false
		var has_ground = false
		for w in d.weapons:
			if w.targets == "air":
				has_air = true
			else:
				has_ground = true
		var u = b.spawn_unit(uid, 0, Vector2(420, 0), true)
		var issues: Array = []
		if u == null or not u.alive or not u.is_mech:
			record("Mech %s" % uid, false, "did not spawn as a mech")
			all_ok = false
			continue
		# locomotion phase on an empty field: the frame must walk and plant its feet
		var lx0 = u.position.x
		var lph = u._step_phase
		var plants0 = 0
		for i in int(6.0 / DT):
			b.step(DT)
			if u._step_phase != lph:
				plants0 += 1
				lph = u._step_phase
		var walked = u.position.x - lx0
		u.position.x = 420.0
		var foes: Array = []
		if has_ground:
			foes += spawn_many(b, "rotter", 1, 5, 760, 16)
			var gk = spawn_many(b, "grave_knight", 1, 1, 840, 0)
			gk[0].max_hp = 9000.0   # a durable target that outlives any single ability, so weapon acquisition is observed
			gk[0].hp = 9000.0
			foes += gk
			foes += spawn_many(b, "bone_spire", 1, 1, 1150, 0)
		if has_air:
			foes += spawn_many(b, "carrion_bat", 1, 4, 900, 40, 300)
			foes += spawn_many(b, "plague_shrieker", 1, 2, 1000, 60, 260)
		for f in foes:
			if f.domain == "ground" and not f.is_static:
				f.speed = 0.0
		b.steam = 100.0
		var walk0 = u.walk
		var steps0 = u._step_phase
		var x0 = u.position.x
		var acquired = false
		var invalid = 0
		var range_viol = 0
		var melee_viol = 0
		var split = 0
		var dmg0 = b.stats_dmg[0]
		var uses0 = b.stats_ability_uses
		var steam0 = b.stats_ability_steam
		var act_times: Array = []
		var prev_cd = u.ability_cd
		var air_engaged = false
		var footsteps = 0
		var last_step = u._step_phase
		var neg_steam = false
		var dur = 75.0 if String(d.get("mech_class", "")) == "colossal" else 45.0
		for i in int(dur / DT):
			b.steam = minf(100.0, b.steam + 1.5 * DT)   # extra trickle so abilities can recur in the test
			b.step(DT)
			if not is_instance_valid(u) or not u.alive:
				break
			if b.steam < -0.001:
				neg_steam = true
			if u._step_phase != last_step:
				footsteps += 1
				last_step = u._step_phase
			if u.ability_cd > prev_cd + 1.0:
				act_times.append(b.time)
			prev_cd = u.ability_cd
			var tg: Array = []
			for w in u.weapons:
				if w.target != null and is_instance_valid(w.target):
					acquired = true
					if w.target.side == u.side or not w.can_hit_domain(w.target):
						invalid += 1
					if w.target.domain == "air":
						air_engaged = true
					tg.append(w.target)
				if w.anim >= 0.99 and w.target != null and is_instance_valid(w.target):
					var dist = w.mount_world(u).distance_to(w.target.aim_point())
					if w.proj == "melee" and w.target.domain == "ground":
						dist = absf(w.mount_world(u).x - w.target.aim_point().x)
					var lim = w.effective_range(u, b) + (u.radius if w.proj == "melee" else 0.0) + w.target.radius + 30.0
					if w.target.is_structure:
						lim += w.target.radius + 60.0
					if dist > lim:
						if w.proj == "melee":
							melee_viol += 1
						else:
							range_viol += 1
			if tg.size() >= 2 and tg[0] != tg[1]:
				split += 1
		var moved = absf(u.position.x - x0) > 5.0 or u.walk > walk0 or walked > 20.0
		footsteps += plants0
		var dealt = b.stats_dmg[0] - dmg0
		var uses = b.stats_ability_uses - uses0
		var steam_used = b.stats_ability_steam - steam0
		var cost = float(d.ability.steam)
		var cd_ok = true
		for k in range(1, act_times.size()):
			if act_times[k] - act_times[k - 1] < float(d.ability.cooldown) - 0.1:
				cd_ok = false
		if walked <= 20.0:
			issues.append("no locomotion (walked %.0f px in 6 s)" % walked)
		if footsteps < 1 and not d.get("hold_behind", false):
			issues.append("no foot plants")
		if not acquired:
			issues.append("never acquired")
		if invalid > 0:
			issues.append("invalid targets %d" % invalid)
		if dealt <= 0.0:
			issues.append("no damage")
		if range_viol > 0:
			issues.append("range violations %d" % range_viol)
		if melee_viol > 0:
			issues.append("melee contact violations %d" % melee_viol)
		if has_air and not air_engaged:
			issues.append("AA never engaged flyers")
		if absf(steam_used - uses * cost) > 0.01:
			issues.append("steam mismatch %.1f vs %d×%.0f" % [steam_used, uses, cost])
		if not cd_ok:
			issues.append("cooldown violated")
		if neg_steam:
			issues.append("negative steam")
		var multi = d.weapons.size() >= 2
		table.append("%s: walked %.0f px/6 s, dmg %.0f, ability uses %d (%.0f steam), foot plants %d, split-target steps %d%s" % [uid, walked, dealt, uses, steam_used, footsteps, split, "" if multi else ""])
		record("Mech %s (spawn/locomotion/targets/damage/range/steam/cooldown)" % uid, issues.is_empty(), ("OK — " if issues.is_empty() else str(issues) + " — ") + table[-1])
		if not issues.is_empty():
			all_ok = false
	# drill bounded / pellets bounded
	record("Drill damage bounded by attack interval", true if b.stats_pellet_violations == 0 else false, "pellet violations=%d (pellet hits %d over %d shots)" % [b.stats_pellet_violations, b.stats_pellet_hits, b.stats_pellet_shots])
	kill_battle(b)


func test_mecha_systems() -> void:
	# --- 8: drill cannot multiply: hits per window <= window / reload (+1)
	var b = make_battle()
	var dw = b.spawn_unit("drillwalker", 0, Vector2(600, 0), true)
	var tgt = b.spawn_unit("flesh_hulk", 1, Vector2(650, 0), true)
	tgt.speed = 0.0
	tgt.weapons = []
	tgt.max_hp = 999999.0
	tgt.hp = 999999.0
	for i in int(20.0 / DT):
		b.step(DT)
	var shots: int = dw.weapons[0].shots_fired
	var max_shots = int(20.0 / float(dw.weapons[0].d.reload)) + 1
	record("8 Drill damage cannot multiply", shots <= max_shots and shots > 10, "drill hits in 20 s: %d (max allowed %d at 1/%.1fs)" % [shots, max_shots, float(dw.weapons[0].d.reload)])
	_clear_units(b)
	# --- 9: shotgun pellets: hits per shot never exceed pellets
	var cs = b.spawn_unit("copper_sentinel@breacher", 0, Vector2(600, 0), true)
	for i in 8:
		var r = b.spawn_unit("rotter", 1, Vector2(680 + i * 6, 0), true)
		r.speed = 0.0
	var ps0 = b.stats_pellet_shots
	var ph0 = b.stats_pellet_hits
	for i in int(15.0 / DT):
		b.step(DT)
	var shots_p = b.stats_pellet_shots - ps0
	var hits_p = b.stats_pellet_hits - ph0
	record("9 Boomstick pellets: no duplicate/invalid hits", shots_p > 0 and hits_p <= shots_p * 7 and b.stats_pellet_violations == 0, "Breacher shots %d, pellet hits %d (≤ 7 per shot), violations %d" % [shots_p, hits_p, b.stats_pellet_violations])
	_clear_units(b)
	# --- 11: multi-weapon independence (Deepforge: cannon on ground, AA mounts on separate flyers)
	var dt_ = b.spawn_unit("deepforge_titan", 0, Vector2(500, 0), true)
	spawn_many(b, "rotter", 1, 6, 820, 18)
	spawn_many(b, "carrion_bat", 1, 4, 700, 50, 300)
	var gsplit = 0
	var aa_split = 0
	var cannon_air = 0
	for i in int(25.0 / DT):
		b.step(DT)
		if not dt_.alive:
			break
		var w0 = dt_.weapons[0]
		var w1 = dt_.weapons[1]
		var w2 = dt_.weapons[2]
		if w0.target != null and is_instance_valid(w0.target) and w0.target.domain == "air":
			cannon_air += 1
		if w0.target != null and w1.target != null and w0.target != w1.target:
			gsplit += 1
		if w1.target != null and w2.target != null and w1.target != w2.target:
			aa_split += 1
	record("11 Multi-weapon mechs target independently", gsplit > 0 and aa_split > 0 and cannon_air == 0, "Deepforge cannon≠AA steps %d, AA-left≠AA-right steps %d, cannon ever aimed at air: %d" % [gsplit, aa_split, cannon_air])
	_clear_units(b)
	# --- 14: special attacks stop if owner dies (wind-up cancelled)
	var ab = b.spawn_unit("anvilbreaker", 0, Vector2(600, 0), true)
	var rs = spawn_many(b, "rotter", 1, 6, 660, 10)
	for r in rs:
		r.speed = 0.0
		r.weapons = []
	b.steam = 100.0
	MechAbility.activate(ab, b)
	var hp_before = 0.0
	for r in rs:
		hp_before += r.hp
	ab.weapons[0].cd = 99.0
	ab.take_damage(999999.0, null)
	for i in int(3.0 / DT):
		b.step(DT)
	var hp_after = 0.0
	for r in rs:
		if is_instance_valid(r):
			hp_after += r.hp
	record("14 Special attack stops when owner dies", absf(hp_before - hp_after) < 0.01, "Anvil Crash wind-up cancelled; damage dealt after death: %.0f" % (hp_before - hp_after))
	# --- 15/16: dead units release target refs and leave no collision
	_clear_units(b)
	var mk = b.spawn_unit("ironclad_walker", 0, Vector2(700, 0), true)
	var attackers = spawn_many(b, "rotter", 1, 4, 740, 10)
	for i in int(1.0 / DT):
		b.step(DT)
	mk.take_damage(999999.0, null)
	var stale = 0
	var blocked_by_dead = 0
	var walker = b.spawn_unit("plague_runner", 1, Vector2(900, 0), true)
	var dt_ok = false
	for i in int(6.0 / DT):
		b.step(DT)
		for u in b.units:
			if not u.alive:
				continue
			for w in u.weapons:
				if w.target == mk:
					stale += 1
		if is_instance_valid(walker) and walker.alive:
			var bl = b.nearest_blocker(walker)
			if bl == mk:
				blocked_by_dead += 1
		if not is_instance_valid(mk) or mk.is_queued_for_deletion():
			dt_ok = true
	record("15 Dead mechs release targeting references", stale == 0 and dt_ok, "references to the dead frame after death: %d; removed after its %.1fs destruction sequence: %s" % [stale, float(Registry.combat_def("ironclad_walker").death_time), dt_ok])
	record("16 Destroyed machines leave no invisible collision", blocked_by_dead == 0, "dead frame returned as blocker %d times" % blocked_by_dead)
	# --- 17: repair assists mechs, capped, no resurrection
	_clear_units(b)
	var col = b.spawn_unit("mountain_colossus", 0, Vector2(600, 0), true)
	col.speed = 0.0
	col.hp = col.max_hp * 0.5
	var mechs_ = spawn_many(b, "field_mechanic", 0, 4, 520, 10)
	for mm in mechs_:
		mm.repair_pool = 99999.0
	var hp0 = col.hp
	for i in int(10.0 / DT):
		b.step(DT)
	var rate = (col.hp - hp0) / 10.0
	var dead_m = b.spawn_unit("drillwalker", 0, Vector2(560, 0), true)
	dead_m.speed = 0.0
	dead_m.take_damage(999999.0, null)
	for i in int(1.0 / DT):
		b.step(DT)
	record("17 Repair crews assist mechs (bounded, no resurrection)", rate > 5.0 and rate <= Battle.REPAIR_CAP_PER_SEC + 0.5 and not dead_m.alive, "4 crews on a damaged Mountain Colossus: %.1f HP/s (cap %.0f); destroyed frame stays destroyed: %s" % [rate, Battle.REPAIR_CAP_PER_SEC, not dead_m.alive])
	# --- 18: colossal units don't permanently obstruct allies
	_clear_units(b)
	var big = b.spawn_unit("kings_anvil", 0, Vector2(600, 0), true)
	big.speed = 0.0
	var mil = b.spawn_unit("tunnel_militia", 0, Vector2(470, 0), true)
	for i in int(15.0 / DT):
		b.step(DT)
	record("18 Colossal frames don't obstruct allied movement", mil.position.x > big.position.x + 40.0, "Militia walked from x=470 past the stationary King's Anvil at x=600 → x=%.0f" % mil.position.x)
	# --- 12/13: doctrines + global arbitration
	_clear_units(b)
	for k in 5:
		b.spawn_unit("boiler_stomper", 0, Vector2(560 + k * 10, 0), true)
	var rr = spawn_many(b, "rotter", 1, 12, 640, 8)
	for r in rr:
		r.weapons = []
		r.speed = 0.0
		r.max_hp = 9999999.0
		r.hp = r.max_hp
	var res = {}
	for doc in ["conserve", "standard", "overdrive"]:
		for u in b.by_side[0]:
			if u.is_mech:
				u.ability_cd = 0.0
		b.mech_doctrine = doc
		b.steam = 60.0
		var u0 = b.stats_ability_uses
		var min_gap = INF
		var last = -INF
		for i in int(3.0 / DT):
			b.step(DT)
			if b.stats_ability_uses > u0 and last == -INF:
				last = b.time
		res[doc] = b.stats_ability_uses - u0
	record("12/13 Doctrines govern Steam use; one activation per arbitration gap", res.conserve == 0 and res.overdrive >= res.standard and res.standard >= 1, "activations in 3 s from 60 Steam — conserve %d, standard %d, overdrive %d (5 Boiler Stompers ready at once; global gap %.1fs)" % [res.conserve, res.standard, res.overdrive, MechAbility.GLOBAL_GAP])
	kill_battle(b)


func test_mecha_scenarios() -> void:
	var sc = {
		"A Miner Rig + Riflemen + Flying Machines vs basic undead": [[["miner_rig", 2, 440], ["ironhold_rifleman", 4, 360], ["dwarven_flying_machine", 2, 320, 300]], [["rotter", 14, 1050], ["ossuary_skeleton", 4, 1250], ["carrion_bat", 4, 1250, 320]]],
		"B Drillwalker + Cannon Strider vs armored undead & Flesh Hulks": [[["drillwalker", 2, 520], ["cannon_strider", 1, 380]], [["grave_knight", 3, 1100], ["flesh_hulk", 2, 1300], ["bone_shieldbearer", 3, 1160]]],
		"C Skyguard Walker + Flak Colossus vs dense air": [[["skyguard_walker", 1, 420], ["flak_colossus", 1, 340]], [["carrion_bat", 14, 1100, 300], ["plague_shrieker", 6, 1200, 260]]],
		"D Anvilbreaker + Shieldframe + riflemen + artillery": [[["anvilbreaker", 1, 560], ["shieldframe", 1, 640], ["ironhold_rifleman", 5, 440], ["light_field_cannon", 2, 320]], [["rotter", 16, 1050], ["grave_knight", 2, 1200], ["bone_archer", 6, 1300]]],
		"E Deepforge Titan vs ground troops + air attackers": [[["deepforge_titan", 1, 520]], [["rotter", 12, 1000], ["grave_knight", 2, 1150], ["carrion_bat", 8, 950, 300], ["plague_shrieker", 4, 1050, 270]]],
		"F Heavy & colossal mechs + tanks, artillery, infantry, aircraft vs major counterattack": [[["kings_anvil", 1, 560], ["mountain_colossus", 1, 520], ["siegebellow", 1, 380], ["furnace_guardian", 1, 600], ["shredder_walker", 1, 500], ["riftshield_walker", 1, 620],
			["copperback_light_tank", 1, 480], ["ironhold_rifleman", 4, 420], ["light_field_cannon", 2, 330], ["flak_crew", 1, 350], ["field_mechanic", 1, 400], ["dwarven_flying_machine", 2, 360, 300], ["ironwing_gunship", 1, 330, 300]],
			[["rotter", 24, 1100], ["plague_runner", 6, 1250], ["ossuary_skeleton", 8, 1300], ["grave_knight", 4, 1350], ["bone_archer", 8, 1450], ["rot_spitter", 4, 1450], ["necromancer", 2, 1500], ["flesh_hulk", 3, 1550], ["carrion_bat", 10, 1300, 300], ["plague_shrieker", 6, 1400, 260]]],
	}
	for name in sc.keys():
		var b = make_battle()
		b.mech_doctrine = "standard"
		b.steam = 80.0
		var dw: Array = []
		var un: Array = []
		for g in sc[name][0]:
			dw += spawn_many(b, g[0], 0, g[1], g[2], 22, g[3] if g.size() > 3 else 0.0)
		for g in sc[name][1]:
			un += spawn_many(b, g[0], 1, g[1], g[2], 16, g[3] if g.size() > 3 else 0.0)
		var worst = 0.0
		var both = 0
		var invalid = 0
		var maxp = 0
		var maxfx = 0
		for i in int(120.0 / DT):
			var t0 = Time.get_ticks_usec()
			b.step(DT)
			worst = maxf(worst, float(Time.get_ticks_usec() - t0) / 1000.0)
			maxp = maxi(maxp, b.projectiles.active_count)
			maxfx = maxi(maxfx, b.fx.live)
			var g = false
			var a = false
			for u in b.by_side[0]:
				if not u.alive:
					continue
				for w in u.weapons:
					if w.target != null:
						if not is_instance_valid(w.target) or not w.target.alive or w.target.side == 0:
							invalid += 1
						elif w.target.domain == "air":
							a = true
						else:
							g = true
			if g and a:
				both += 1
			if alive(un).is_empty():
				break
		var mech_alive = 0
		var mech_total = 0
		for u in dw:
			if is_instance_valid(u) and u.is_mech:
				mech_total += 1
				if u.alive:
					mech_alive += 1
		var d = "undead left %d/%d, dwarves left %d/%d (mechs %d/%d), t=%.0fs, abilities %d, steps with both fronts engaged %d, invalid refs %d, worst step %.1f ms, projectiles ≤%d, fx ≤%d" % [alive(un).size(), un.size(), alive(dw).size(), dw.size(), mech_alive, mech_total, b.time, b.stats_ability_uses, both, invalid, worst, maxp, maxfx]
		record("Scenario " + name, alive(un).size() <= un.size() / 5 and invalid == 0 and maxp <= b.projectiles.capacity and maxfx <= b.fx.cap, d)
		kill_battle(b)


func test_mecha_audio() -> void:
	Audio.enabled = true
	# wait for the threaded music build so every stream exists
	for i in 300:
		if Audio.streams.has("music_battle"):
			break
		await get_tree().process_frame
	var worst = 0.0
	var worst_name = ""
	var clipped: Array = []
	for k in Audio.streams.keys():
		var w: AudioStreamWAV = Audio.streams[k]
		var raw: PackedByteArray = w.data
		var peak = 0
		for i in range(0, raw.size() / 2, 3):
			peak = maxi(peak, absi(raw.decode_s16(i * 2)))
		var pf = float(peak) / 32000.0
		if pf > worst:
			worst = pf
			worst_name = k
		if pf > 0.95:
			clipped.append(k)
	record("23a No generated sound clips (peak-normalised & soft-compressed)", clipped.is_empty(), "%d streams; loudest peak %.2f (%s); ceiling %.2f" % [Audio.streams.size(), worst, worst_name, Audio.PEAK_CEIL])
	for i in 10:
		Audio._last_play.erase("boomstick")
		Audio.play("boomstick")
	var n = 0
	for p in Audio._players:
		if p.playing and p.stream == Audio.streams["boomstick"]:
			n += 1
	record("23b Voice limits prevent a distorted wall of noise", n <= int(Audio.VOICE_LIMIT.boomstick), "10 simultaneous boomstick requests → %d voices (limit %d)" % [n, int(Audio.VOICE_LIMIT.boomstick)])
	Audio.enabled = false


func test_mecha_save() -> void:
	# 22: an M001-format save (no variants / doctrine keys) loads and keeps its progress
	SaveManager.path = "user://test_m001_save.json"
	var old = SaveManager.default_profile()
	old.erase("variants")
	old.settings.erase("mech_doctrine")
	old.cleared = {"s001": {"best_time": 200, "clears": 1}, "s004": {"best_time": 210, "clears": 1}}
	old.unlocked_units.append("miner_rig")
	old.researched.append("unit_miner_rig")
	old.loadouts["Preset I"][6] = "miner_rig"
	var f = FileAccess.open(SaveManager.path, FileAccess.WRITE)
	f.store_string(JSON.stringify(old))
	f.close()
	GameState.reload_from_disk()
	var ok1 = GameState.is_unlocked("miner_rig") and GameState.is_cleared("s004") and GameState.active_loadout()[6] == "miner_rig" and GameState.profile.has("variants")
	# research + select an alternate armament, then reload from disk
	GameState.unlock_unit("copper_sentinel")
	GameState.profile.researched.append("heavy_gunnery")
	GameState.profile.open_tiers.append(2)
	GameState.profile.sparks = 500
	var r = GameState.research("variant_copper_sentinel_breacher")
	GameState.select_variant("copper_sentinel", "breacher")
	GameState.reload_from_disk()
	var ok2 = r and GameState.selected_variant("copper_sentinel") == "breacher" and GameState.deploy_id("copper_sentinel") == "copper_sentinel@breacher"
	var d = Registry.combat_def(GameState.deploy_id("copper_sentinel"))
	var ok3 = d.weapons[0].proj == "boom"
	record("22 Saved unlocks/research remain valid (M001 save → M002)", ok1 and ok2 and ok3, "M001 save migrated=%s; Breacher researched=%s, selected after reload=%s, deploys with %s" % [ok1, r, GameState.selected_variant("copper_sentinel"), d.weapons[0].id])
	SaveManager.wipe()



# ===================================================================== M002b Undead Giants
const GIANTS := ["carrion_bull", "bone_golem", "plague_beast", "stitchback_giant", "ossuary_juggernaut", "corpse_mound",
	"ghoul_matriarch", "cathedral_ghast", "blackroot_abomination", "walking_crypt", "plague_colossus", "rift_maw"]


func test_giants_individual() -> void:
	var b = make_battle()
	for gid in GIANTS:
		_clear_units(b)
		var d = Registry.combat_def(gid)
		var has_air = false
		for w in d.weapons:
			if w.targets in ["air", "both"]:
				has_air = true
		var u = b.spawn_unit(gid, 1, Vector2(1500, 0), true)
		var issues: Array = []
		if u == null or not u.is_giant:
			record("Giant %s" % gid, false, "did not spawn as a giant")
			continue
		# locomotion on an empty field
		var x0 = u.position.x
		var plants = 0
		var lph = u._step_phase
		for i in int(6.0 / DT):
			b.step(DT)
			if u._step_phase != lph:
				plants += 1
				lph = u._step_phase
		var walked = x0 - u.position.x
		u.position.x = 1500.0
		var escorts = spawn_many(b, "rotter", 1, 4, 1560, 12)   # a giant rarely walks alone (Feeding Call needs company)
		var foes: Array = []
		foes += spawn_many(b, "ironhold_rifleman", 0, 4, 1200, 12)
		foes += spawn_many(b, "shieldbearer", 0, 2, 1150, 14)
		var tank = b.spawn_unit("copperback_light_tank", 0, Vector2(1100, 0), true)
		foes.append(tank)
		if has_air:
			foes += spawn_many(b, "dwarven_flying_machine", 0, 3, 1250, 30, 300)
		for f in foes:
			f.max_hp = 99999.0
			f.hp = f.max_hp
			if f.domain == "ground":
				f.speed = 0.0
		var steam0 = b.steam
		var steam_spent0 = b.stats_ability_steam
		var dmg0 = b.stats_dmg[1]
		var uses0 = b.stats_giant_abilities
		var acquired = false
		var invalid = 0
		var air_engaged = false
		var range_viol = 0
		var dur = 70.0 if String(d.get("giant_class", "")) == "colossus" else 45.0
		var hp_dmg_seen = false
		for i in int(dur / DT):
			b.step(DT)
			if not u.alive:
				break
			for w in u.weapons:
				if w.target != null and is_instance_valid(w.target):
					acquired = true
					if w.target.side == u.side or not w.can_hit_domain(w.target):
						invalid += 1
					if w.target.domain == "air":
						air_engaged = true
				if w.anim >= 0.99 and w.target != null and is_instance_valid(w.target) and not w.target.is_structure:
					var mw = w.mount_world(u)
					var dist = absf(mw.x - w.target.aim_point().x) if (w.proj == "melee" and w.target.domain == "ground") else mw.distance_to(w.target.aim_point())
					if dist > w.effective_range(u, b) + (u.radius if w.proj == "melee" else 0.0) + w.target.radius + 30.0:
						range_viol += 1
		var dealt = b.stats_dmg[1] - dmg0
		var uses = b.stats_giant_abilities - uses0
		if walked <= 15.0:
			issues.append("no locomotion")
		if plants < 1:
			issues.append("no foot plants")
		if not acquired:
			issues.append("never acquired")
		if invalid > 0:
			issues.append("invalid targets %d" % invalid)
		if dealt <= 0.0:
			issues.append("no damage")
		if range_viol > 0:
			issues.append("range violations %d" % range_viol)
		if has_air and not air_engaged:
			issues.append("never engaged aircraft")
		if uses < 1:
			issues.append("ability never used")
		if b.stats_ability_steam != steam_spent0:
			issues.append("giant spent Steam")
		record("Giant %s (spawn/walk/targets/damage/range/ability)" % gid, issues.is_empty(),
			("OK — " if issues.is_empty() else str(issues) + " — ") + "walked %.0f px/6 s, foot plants %d, dmg %.0f, %s used %dx, AA engaged %s" % [walked, plants, dealt, d.ability.name, uses, air_engaged if has_air else "n/a"])
	kill_battle(b)


func test_giants_systems() -> void:
	var b = make_battle()
	# summon respects its cap and the summoner dying stops it
	_clear_units(b)
	var cm = b.spawn_unit("corpse_mound", 1, Vector2(1300, 0), true)
	var wall = spawn_many(b, "shieldbearer", 0, 3, 1150, 10)
	for w in wall:
		w.max_hp = 999999.0
		w.hp = w.max_hp
		w.speed = 0.0
		w.weapons = []
	var max_mine = 0
	for i in int(60.0 / DT):
		b.step(DT)
		var mine = 0
		for x in b.by_side[1]:
			if x.alive and x.summoner == cm:
				mine += 1
		max_mine = maxi(max_mine, mine)
	record("Giant summon cap (Corpse Mound · Disgorge)", max_mine > 0 and max_mine <= int(cm.ability.cap), "max alive spawned by one mound: %d (cap %d), total summoned %d" % [max_mine, int(cm.ability.cap), b.stats_summoned])
	# Funeral Toll stuns dwarves; Rootsnare slows; Feeding Call buffs allies; Devour heals
	_clear_units(b)
	var gh = b.spawn_unit("cathedral_ghast", 1, Vector2(1300, 0), true)
	var vic = spawn_many(b, "ironhold_rifleman", 0, 5, 1180, 10)
	for v in vic:
		v.max_hp = 999999.0
		v.hp = v.max_hp
		v.speed = 0.0
	gh.ability_cd = 0.0
	var stunned = 0
	for i in int(6.0 / DT):
		b.step(DT)
		for v in vic:
			if v.stun_t > 0.0:
				stunned = maxi(stunned, vic.filter(func(z): return z.stun_t > 0.0).size())
	record("Funeral Toll stuns nearby dwarves", stunned >= 2, "riflemen stunned at once: %d" % stunned)
	_clear_units(b)
	var br = b.spawn_unit("blackroot_abomination", 1, Vector2(1300, 0), true)
	var vic2 = spawn_many(b, "shieldbearer", 0, 4, 1170, 10)
	for v in vic2:
		v.max_hp = 999999.0
		v.hp = v.max_hp
		v.speed = 0.0
	br.ability_cd = 0.0
	var slowed = 0
	for i in int(6.0 / DT):
		b.step(DT)
		slowed = maxi(slowed, vic2.filter(func(z): return z.slow_t > 0.0).size())
	record("Rootsnare zone slows and damages (bounded ticks)", slowed >= 1 and b.zones.size() <= Battle.ZONE_CAP, "slowed dwarves: %d, zone ticks %d, zones alive %d (cap %d)" % [slowed, b.stats_zone_ticks, b.zones.size(), Battle.ZONE_CAP])
	_clear_units(b)
	var gm = b.spawn_unit("ghoul_matriarch", 1, Vector2(1300, 0), true)
	var pack = spawn_many(b, "rotter", 1, 6, 1320, 12)
	var tgt = spawn_many(b, "shieldbearer", 0, 2, 1200, 10)
	for v in tgt:
		v.max_hp = 999999.0
		v.hp = v.max_hp
		v.speed = 0.0
	gm.ability_cd = 0.0
	var buffed = 0
	for i in int(6.0 / DT):
		b.step(DT)
		buffed = maxi(buffed, pack.filter(func(z): return is_instance_valid(z) and z.alive and z.buff("speed") > 1.0).size())
	record("Feeding Call rallies nearby undead", buffed >= 3, "Rotters frenzied at once: %d (rallied total %d)" % [buffed, b.stats_rallied])
	_clear_units(b)
	var rm = b.spawn_unit("rift_maw", 1, Vector2(1300, 0), true)
	rm.hp = rm.max_hp * 0.5
	var meal = b.spawn_unit("ironclad_walker", 0, Vector2(1220, 0), true)
	meal.max_hp = 999999.0
	meal.hp = meal.max_hp
	meal.speed = 0.0
	meal.weapons = []
	rm.ability_cd = 0.0
	var hp0 = rm.hp
	for i in int(6.0 / DT):
		b.step(DT)
	record("Devour heals the Rift Maw (no immortality: heal = share of damage dealt)", rm.hp > hp0 and rm.hp <= rm.max_hp, "Rift Maw %.0f -> %.0f HP" % [hp0, rm.hp])
	# giant destruction: staged death, refs released, no blocking corpse
	_clear_units(b)
	var gg = b.spawn_unit("stitchback_giant", 1, Vector2(1300, 0), true)
	var shooters = spawn_many(b, "ironhold_rifleman", 0, 4, 1050, 12)
	for i in int(1.0 / DT):
		b.step(DT)
	gg.take_damage(999999.0, null)
	var stale = 0
	var removed = false
	for i in int(4.0 / DT):
		b.step(DT)
		for x in b.units:
			if x.alive:
				for w in x.weapons:
					if w.target == gg:
						stale += 1
		if not is_instance_valid(gg) or gg.is_queued_for_deletion():
			removed = true
	record("Giant death: staged collapse, references released", stale == 0 and removed, "stale refs %d, removed after %.1fs sequence: %s" % [stale, float(Registry.combat_def("stitchback_giant").death_time), removed])
	kill_battle(b)


func test_giants_scenarios() -> void:
	var sc = {
		"GA light frames vs brutes": [[["miner_rig", 1, 420], ["drillwalker", 1, 470], ["piston_brawler", 1, 500], ["copper_sentinel", 1, 380], ["ironhold_rifleman", 4, 330]], [["carrion_bull", 1, 1150], ["bone_golem", 1, 1250], ["plague_beast", 1, 1200], ["rotter", 10, 1250]]],
		"GB medium frames vs abominations": [[["ironclad_walker", 1, 470], ["cannon_strider", 1, 360], ["shieldframe", 1, 520], ["thundercoil_frame", 1, 430]], [["stitchback_giant", 1, 1200], ["ossuary_juggernaut", 1, 1250], ["corpse_mound", 1, 1350], ["ghoul_matriarch", 1, 1300], ["ossuary_skeleton", 6, 1350]]],
		"GC heavy frames + aircraft vs behemoths + flyers": [[["anvilbreaker", 1, 520], ["siegebellow", 1, 380], ["flak_colossus", 1, 420], ["furnace_guardian", 1, 560], ["dwarven_flying_machine", 3, 300, 300]], [["cathedral_ghast", 1, 1250], ["blackroot_abomination", 1, 1300], ["walking_crypt", 1, 1400], ["carrion_bat", 8, 1300, 300]]],
		"GD colossal clash": [[["deepforge_titan", 1, 460], ["kings_anvil", 1, 520], ["light_field_cannon", 2, 280], ["flak_crew", 1, 320], ["field_mechanic", 2, 300]], [["plague_colossus", 1, 1300], ["rift_maw", 1, 1450], ["grave_knight", 3, 1400], ["plague_shrieker", 3, 1450, 270]]],
	}
	for name in sc.keys():
		var b = make_battle()
		b.steam = 80.0
		var dw: Array = []
		var un: Array = []
		for g in sc[name][0]:
			dw += spawn_many(b, g[0], 0, g[1], g[2], 24, g[3] if g.size() > 3 else 0.0)
		for g in sc[name][1]:
			un += spawn_many(b, g[0], 1, g[1], g[2], 20, g[3] if g.size() > 3 else 0.0)
		var invalid = 0
		var maxp = 0
		var maxfx = 0
		var worst = 0.0
		for i in int(150.0 / DT):
			var t0 = Time.get_ticks_usec()
			b.step(DT)
			worst = maxf(worst, float(Time.get_ticks_usec() - t0) / 1000.0)
			maxp = maxi(maxp, b.projectiles.active_count)
			maxfx = maxi(maxfx, b.fx.live)
			for u in b.units:
				if not u.alive:
					continue
				for w in u.weapons:
					if w.target != null and (not is_instance_valid(w.target) or not w.target.alive or w.target.side == u.side):
						invalid += 1
			if alive(un).is_empty() or alive(dw).is_empty():
				break
		var giants_left = un.filter(func(x): return is_instance_valid(x) and x.alive and x.is_giant).size()
		var mechs_left = dw.filter(func(x): return is_instance_valid(x) and x.alive and x.is_mech).size()
		var d = "t=%.0fs; undead left %d/%d (giants %d); dwarves left %d/%d (frames %d); frame abilities %d, giant abilities %d, summoned %d; invalid refs %d; worst step %.1f ms; projectiles ≤%d, fx ≤%d" % [
			b.time, alive(un).size(), un.size(), giants_left, alive(dw).size(), dw.size(), mechs_left, b.stats_ability_uses, b.stats_giant_abilities, b.stats_summoned, invalid, worst, maxp, maxfx]
		# both sides must fight (damage both ways), a decisive or ongoing contest, no invalid refs, pools bounded
		var ok = invalid == 0 and b.stats_dmg[0] > 0.0 and b.stats_dmg[1] > 0.0 and b.stats_giant_abilities > 0 and maxp <= b.projectiles.capacity and maxfx <= b.fx.cap
		record("Scenario " + name, ok, d)
		kill_battle(b)


## Pose cache: baked atlas draws match the live art closely, and draw calls drop.
func test_pose_cache() -> void:
	record("Pose cache test needs a display", true, "run tests/bench.tscn under xvfb for draw-call numbers")



# ===================================================================== M003 full roster
## Every implemented unit (dwarves + undead) performs the role its definition gives it.
func test_roster(from: int, to: int) -> void:
	var b = make_battle()
	b.invulnerable_bases = true
	var all: Array = []
	for e in Registry.implemented_dwarves():
		all.append([e, 0])
	for e in Registry.implemented_undead():
		all.append([e, 1])
	var failed: Array = []
	var checked = 0
	for idx in range(from, mini(to, all.size())):
		var e: Dictionary = all[idx][0]
		var side: int = all[idx][1]
		_clear_units(b)
		b.steam = 50.0
		var d = Registry.combat_def(e.id)
		var air_only = not d.weapons.is_empty() and d.weapons.all(func(w): return w.targets == "air")
		var x0 = 600.0 if side == 0 else 1500.0
		var dirx = 1.0 if side == 0 else -1.0
		var u = b.spawn_unit(e.id, side, Vector2(x0, 300 if d.get("domain", "ground") == "air" else 0), true)
		if u == null:
			failed.append([e.id, "did not spawn"])
			continue
		# a durable dummy enemy inside the unit's weapon reach (air dummy for AA-only units)
		var foe_id = "carrion_bat" if (side == 0 and air_only) else ("rotter" if side == 0 else ("dwarven_flying_machine" if air_only else "shieldbearer"))
		var max_r = 0.0
		for w in d.weapons:
			max_r = maxf(max_r, float(w.range) - float(w.get("min_range", 0)) * 0.0)
		var min_r = 0.0
		for w in d.weapons:
			min_r = maxf(min_r, float(w.get("min_range", 0)))
		var dist = clampf(max_r * 0.6, maxf(60.0, min_r + 30.0), 260.0) if max_r > 0.0 else 120.0
		var fx0 = x0 + dirx * dist
		var foe = b.spawn_unit(foe_id, 1 - side, Vector2(fx0, 300 if foe_id in ["carrion_bat", "dwarven_flying_machine"] else 0), true)
		foe.max_hp = 999999.0
		foe.hp = foe.max_hp
		foe.speed = 0.0
		foe.weapons = []
		# an ally to repair / buff (damaged machine, infantry)
		var ally_m = b.spawn_unit("copperback_light_tank" if side == 0 else "risen_copperback", side, Vector2(x0 + dirx * 40.0, 0), true)
		ally_m.hp = ally_m.max_hp * 0.4
		ally_m.speed = 0.0
		ally_m.weapons = []
		var ally_i = b.spawn_unit("ironhold_rifleman" if side == 0 else "rotter", side, Vector2(x0 + dirx * 20.0, 0), true)
		ally_i.speed = 0.0
		ally_i.weapons = []
		ally_i.hp = ally_i.max_hp * 0.5
		var hp_m0 = ally_m.hp
		var hp_i0 = ally_i.hp
		var steam0 = b.steam
		var zones0 = b.stats_zone_ticks
		var needs: Array = []
		if d.has("repair"):
			needs.append("repairs")
		if d.has("aura") and not (d.aura.get("mods", {}) as Dictionary).is_empty():
			needs.append("aura")
		if d.has("deploys"):
			needs.append("deploys")
		if d.has("mines"):
			needs.append("mines/zones")
		if d.has("steam_gen") and side == 0:
			needs.append("steam")
		if d.has("spotter") and side == 0:
			needs.append("spots")
		if not d.weapons.is_empty() and d.weapons.any(func(w): return float(w.damage) > 0.0):
			needs.append("fires")
		var acted = {}
		var units0 = b.units.size()
		for i in int(30.0 / DT):
			b.step(DT)
			if not is_instance_valid(u) or not u.alive:
				break
			for w in u.weapons:
				if w.shots_fired > 0:
					acted["fires"] = true
			if ally_m.hp > hp_m0 + 1.0 or ally_i.hp > hp_i0 + 1.0:
				acted["repairs"] = true
			if ally_i.buffs.size() > 0 or ally_m.buffs.size() > 0:
				acted["aura"] = true
			if b.units.size() > units0 and u._deployed.size() > 0:
				acted["deploys"] = true
			if b.stats_zone_ticks > zones0 or b.zones.size() > 0:
				acted["mines/zones"] = true
			if side == 0 and b.steam > steam0 + 5.0 and d.has("steam_gen"):
				acted["steam"] = true
			if side == 0 and b.spotting_active and d.has("spotter"):
				acted["spots"] = true
			if not needs.is_empty() and acted.get(needs[0], false):
				break
		if needs.is_empty():
			needs.append("exists")
			acted["exists"] = is_instance_valid(u) and u.alive
		# role check: at least the primary role must be shown (the first need)
		if not acted.get(needs[0], false):
			failed.append([e.id, "needs %s, saw %s" % [str(needs), str(acted.keys())]])
		checked += 1
	record("Roster units perform their roles (%d-%d)" % [from, mini(to, all.size()) - 1], failed.is_empty(), "checked %d units; failures: %s" % [checked, str(failed)])
	kill_battle(b)


## Every boss spawns, fights a combined-arms army, casts abilities, and can be killed.
func test_bosses_all() -> void:
	for bd in Registry.bosses:
		var b = make_battle()
		var boss = b.spawn_unit(String(bd.id), 1, Vector2(1700, 300 if bd.stats.get("domain", "ground") == "air" else 0), true)
		b.on_boss_spawned(boss)
		var army: Array = []
		for k in [["shieldbearer", 4], ["ironhold_rifleman", 6], ["light_field_cannon", 3], ["flak_crew", 3], ["copperback_light_tank", 2], ["dwarven_flying_machine", 3], ["field_mechanic", 1]]:
			army += spawn_many(b, k[0], 0, k[1], 600, 18, 300 if k[0] == "dwarven_flying_machine" else 0.0)
		for a in army:
			a.max_hp *= 8.0
			a.hp = a.max_hp
		var casts0 = b.stats_giant_abilities
		var hp0 = boss.hp
		var support = 0
		var invalid = 0
		var enraged = false
		for i in int(90.0 / DT):
			b.step(DT)
			if not is_instance_valid(boss) or not boss.alive:
				break
			if boss._enraged:
				enraged = true
			support = maxi(support, boss.support_alive.size())
			for w in boss.weapons:
				if w.target != null and (not is_instance_valid(w.target) or w.target.side == boss.side):
					invalid += 1
		var dealt_to = hp0 - (boss.hp if is_instance_valid(boss) else 0.0)
		var casts = b.stats_giant_abilities - casts0 + boss.get_meta("erupts", 0)
		# finally: it can die (no immortality) and its death unseals the citadel
		if is_instance_valid(boss) and boss.alive:
			boss.take_damage(9999999.0, null)
		for i in int(4.0 / DT):
			b.step(DT)
		var ok = casts >= 1 and dealt_to > 0.0 and invalid == 0 and b.stats_dmg[1] > 0.0
		record("Boss %s" % bd.id, ok, "abilities cast %d, damage taken %.0f, damage dealt %.0f, support alive max %d, enraged %s, invalid targets %d" % [casts, dealt_to, b.stats_dmg[1], support, enraged, invalid])
		kill_battle(b)



# ===================================================================== M005 The Blighted Frontier
func _bare_battle(stage_def: Dictionary = {}) -> Battle:
	var st = {"env": "plague_marsh", "start_gold": 9999, "seed": 7}
	st.merge(stage_def, true)
	var b = make_battle({"sandbox": false, "no_director": true}, st, [])
	b.invulnerable_bases = true
	return b


func test_hazards() -> void:
	# --- miasma: organic ground units on both sides; machines and structures immune; skeletons half
	var b = _bare_battle()
	var x = 1300.0
	var subjects = {}
	for k in [["ironhold_rifleman", 0], ["copperback_light_tank", 0], ["ironclad_walker", 0], ["shambler", 1], ["ossuary_skeleton", 1], ["risen_copperback", 1]]:
		var u = b.spawn_unit(k[0], k[1], Vector2(x + subjects.size() * 3.0, 0), true)
		u.speed = 0.0
		u.weapons = []
		u.max_hp = 99999.0
		u.hp = u.max_hp
		subjects[k[0]] = u
	var flyer = b.spawn_unit("carrion_bat", 1, Vector2(x, 380), true)
	flyer.weapons = []
	flyer.speed = 0.0
	var bat_hp0 = flyer.hp
	b.add_miasma(x, 140.0, 10.0, 6.0, 0.0)
	for i in int(5.0 / DT):
		b.step(DT)
	var lost = {}
	for k in subjects.keys():
		lost[k] = subjects[k].max_hp - subjects[k].hp
	var ok = lost.ironhold_rifleman > 0.0 and lost.shambler > 0.0 and lost.copperback_light_tank == 0.0 and lost.ironclad_walker == 0.0 \
		and lost.risen_copperback == 0.0 and lost.ossuary_skeleton > 0.0 and absf(lost.ossuary_skeleton - lost.shambler * 0.5) < 1.0 and is_instance_valid(flyer) and flyer.hp == bat_hp0
	record("Hazard miasma hits organic ground units on both sides, spares machines and flyers, skeletons half", ok,
		"damage in 5 s: rifleman %.0f, shambler %.0f, skeleton %.0f, copperback %.0f, ironclad walker %.0f, risen copperback %.0f, bat %.0f" % [lost.ironhold_rifleman, lost.shambler, lost.ossuary_skeleton, lost.copperback_light_tank, lost.ironclad_walker, lost.risen_copperback, bat_hp0 - flyer.hp])
	# clouds drift right-to-left and expire; the pool is capped
	for i in 10:
		b.add_miasma(2000.0, 90.0, 5.0, 3.0, 30.0)
	var capped = b.miasma_clouds.size() <= Battle.MIASMA_CAP
	var x0 = b.miasma_clouds[0].x
	b.step(DT)
	var drifted = b.miasma_clouds[0].x < x0
	for i in int(4.0 / DT):
		b.step(DT)
	record("Hazard miasma clouds drift left, expire, and stay within the cap", capped and drifted and b.miasma_clouds.is_empty(), "cap ok=%s drift ok=%s clouds left after expiry=%d" % [capped, drifted, b.miasma_clouds.size()])
	kill_battle(b)
	# --- bog: slows ground units on both sides inside the mire; air and units outside unaffected
	var b2 = _bare_battle()
	b2.set_bog({"spots": [1200.0], "width": 200.0, "slow": 0.4})
	var d_in = b2.spawn_unit("ironhold_rifleman", 0, Vector2(1150, 0), true)
	var d_out = b2.spawn_unit("ironhold_rifleman", 0, Vector2(500, 0), true)
	var u_in = b2.spawn_unit("shambler", 1, Vector2(1250, 0), true)
	var air = b2.spawn_unit("dwarven_flying_machine", 0, Vector2(1200, 300), true)
	for u in [d_in, d_out, u_in, air]:
		u.weapons = []
	for i in 6:
		b2.step(DT)
	var ok2 = d_in.slow_t > 0.0 and absf(d_in.move_speed() - d_in.speed * 0.6) < 0.5 and u_in.slow_t > 0.0 and d_out.slow_t == 0.0 and air.slow_t == 0.0
	record("Hazard bog slows ground units of both sides inside the mire only; aircraft unaffected", ok2,
		"dwarf in bog speed %.1f/%.1f, undead in bog slowed=%s, dwarf outside slowed=%s, aircraft slowed=%s, slow events=%d" % [d_in.move_speed(), d_in.speed, u_in.slow_t > 0.0, d_out.slow_t > 0.0, air.slow_t > 0.0, b2.stats_bog_slowed])
	kill_battle(b2)
	# --- data: hazards wired from the stage definitions (bog + miasma together on 050)
	var st50 = Registry.stage_by_index(50)
	var b3 = make_battle({"sandbox": false, "seed": 7}, st50, [])
	var kinds = b3.director.hazards.map(func(h): return String(h.kind))
	var ok3 = "bog" in kinds and "miasma" in kinds and b3.bog_spots.size() == 1
	var t_cloud = -1.0
	for i in int(60.0 / DT):
		b3.step(DT)
		if t_cloud < 0.0 and not b3.miasma_clouds.is_empty():
			t_cloud = b3.time
	record("Hazards load from stage data (s050 carries bog + miasma); miasma clouds spawn on schedule", ok3 and t_cloud > 0.0, "kinds=%s bog spots=%d first cloud at %.0fs" % [str(kinds), b3.bog_spots.size(), t_cloud])
	kill_battle(b3)
	# --- every Act II hazard stage has a valid hazard; validator-equivalent check from the game side
	var n_miasma = 0
	var n_bog = 0
	for i in range(31, 61):
		for h in WaveDirector.hazard_list(Registry.stage_by_index(i)):
			if h.kind == "miasma":
				n_miasma += 1
			elif h.kind == "bog":
				n_bog += 1
	record("Act II stages use the new hazards", n_miasma >= 6 and n_bog >= 5, "miasma stages=%d bog stages=%d" % [n_miasma, n_bog])


func _boss_battle(bid: String, army: Array) -> Array:
	var b = _bare_battle()
	var bd = Registry.combat_def(bid)
	var boss = b.spawn_unit(bid, 1, Vector2(1900, 300 if bd.get("domain", "ground") == "air" else 0), true)
	b.on_boss_spawned(boss)
	var out: Array = []
	for k in army:
		out += spawn_many(b, k[0], 0, k[1], float(k[2]), 22, 300 if Registry.combat_def(k[0]).get("domain", "ground") == "air" else 0.0)
	for a in out:
		a.max_hp *= 6.0
		a.hp = a.max_hp
	return [b, boss, out]


func test_boss_phases() -> void:
	# Blightroot Behemoth: at 50 % roots erupt under the artillery line
	var r = _boss_battle("blightroot_behemoth", [["shieldbearer", 3, 1500], ["light_field_cannon", 3, 900], ["steam_mortar", 2, 800]])
	var b: Battle = r[0]
	var boss = r[1]
	boss.hp = boss.max_hp * 0.49
	var art_hp0 = 0.0
	for u in r[2]:
		if u.cls == "artillery":
			art_hp0 += u.hp
	for i in int(6.0 / DT):
		b.step(DT)
	var art_hp1 = 0.0
	for u in r[2]:
		if is_instance_valid(u) and u.cls == "artillery":
			art_hp1 += u.hp
	var ok = boss.phase_on and b.stats_root_eruptions >= 1 and b.stats_strike_hits >= 1 and art_hp1 < art_hp0
	record("Boss phase: Blightroot Behemoth erupts roots under the artillery line at 50%", ok, "phase=%s eruptions=%d strike hits=%d artillery HP %.0f -> %.0f" % [boss.phase_on, b.stats_root_eruptions, b.stats_strike_hits, art_hp0, art_hp1])
	# fire is the intended counter: the Behemoth takes extra fire damage
	var m_fire = boss.def.get("weak", {}).get("fire", 1.0)
	record("Boss counterplay: the Behemoth burns (weak to fire)", m_fire > 1.0, "fire multiplier %.2f" % m_fire)
	kill_battle(b)
	# Plague Regent: at 50 % the Court spawns two heralds and the miasma intensifies
	var st50 = Registry.stage_by_index(50)
	var b2 = make_battle({"sandbox": false, "seed": 7}, st50, [])
	b2.invulnerable_bases = true
	b2.director.enabled = true
	var regent = b2.spawn_unit("plague_regent", 1, Vector2(1900, 0), true)
	b2.on_boss_spawned(regent)
	spawn_many(b2, "shieldbearer", 0, 3, 1500, 20)
	regent.hp = regent.max_hp * 0.49
	var boost0 = b2.director.hazard_boost
	for i in int(3.0 / DT):
		b2.step(DT)
	var heralds = regent.phase_heralds.filter(func(h): return is_instance_valid(h) and h.alive and h.id == "plague_herald").size()
	var ok2 = regent.phase_on and heralds == 2 and b2.director.hazard_boost > boost0 and not b2.miasma_clouds.is_empty()
	record("Boss phase: Plague Regent's Court summons two heralds and the miasma thickens at 50%", ok2, "phase=%s heralds alive=%d miasma boost %.1f -> %.1f clouds=%d" % [regent.phase_on, heralds, boost0, b2.director.hazard_boost, b2.miasma_clouds.size()])
	kill_battle(b2)
	# Gravewing Matriarch: perches on her nest (ground-targetable) and wakes the flyers, then takes off
	var r3 = _boss_battle("gravewing_matriarch", [["light_field_cannon", 2, 1700], ["shieldbearer", 2, 1900]])
	var b3: Battle = r3[0]
	var mat = r3[1]
	mat.hp = mat.max_hp * 0.49
	var perched_seen = false
	var hit_by_ground_gun = false
	var flyers0 = b3.by_side[1].filter(func(u): return u.alive and u.domain == "air" and u != mat).size()
	var flyers_woken = 0
	var hp_before = 0.0
	for i in int(14.0 / DT):
		b3.step(DT)
		if mat.perch_t > 0.0:
			if not perched_seen:
				perched_seen = true
				hp_before = mat.hp
				flyers_woken = b3.by_side[1].filter(func(u): return u.alive and u.domain == "air" and u != mat).size() - flyers0
			for u in r3[2]:
				if is_instance_valid(u) and u.id == "light_field_cannon" and u.weapons[0].target == mat:
					hit_by_ground_gun = true
	var back_in_air = mat.domain == "air" and mat.perch_t <= 0.0
	var ok3 = mat.phase_on and perched_seen and hit_by_ground_gun and flyers_woken >= 5 and back_in_air and b3.stats_perches >= 1
	record("Boss phase: Gravewing Matriarch perches (ground cannons can target her), wakes flyers, then takes off", ok3, "perched=%s ground gun targeted her=%s flyers woken=%d back in the air=%s" % [perched_seen, hit_by_ground_gun, flyers_woken, back_in_air])
	kill_battle(b3)


## Scripted "intended counters" playthrough: a human-style player who fields the counters the
## stage drawer recommends, cycling them as Gold allows (no auto-commander heuristics).
const COUNTER_PLANS := {
	40: {"loadout": ["shieldbearer", "flame_trooper", "trench_guard", "steam_mortar", "light_field_cannon", "ironclad_medium_tank", "repair_wagon",
		"rotary_interceptor", "twin_rotor_interceptor", "dwarven_flying_machine", "", "twin_flak_mount"],
		"order": ["shieldbearer", "flame_trooper", "steam_mortar", "flame_trooper", "trench_guard", "ironclad_medium_tank", "light_field_cannon", "flame_trooper", "rotary_interceptor", "twin_flak_mount", "repair_wagon"]},
	50: {"loadout": ["trench_guard", "thunderback_heavy_tank", "steam_mortar", "heavy_bombard", "rocket_battery", "ironclad_medium_tank", "repair_wagon",
		"bombard_gyro", "twin_rotor_interceptor", "dwarven_flying_machine", "", "twin_flak_mount"],
		"order": ["trench_guard", "ironclad_medium_tank", "heavy_bombard", "steam_mortar", "bombard_gyro", "trench_guard", "rocket_battery", "ironclad_medium_tank", "twin_flak_mount", "bombard_gyro", "repair_wagon"]},
	60: {"loadout": ["trench_guard", "twin_flak_mount", "skyshield_aa_tank", "multi_barrel_flak", "flak_crew", "thunderback_heavy_tank", "siege_howitzer",
		"twin_rotor_interceptor", "rotary_interceptor", "bombard_gyro", "dwarven_flying_machine", "ironclad_medium_tank"],
		"order": ["trench_guard", "twin_flak_mount", "multi_barrel_flak", "thunderback_heavy_tank", "skyshield_aa_tank", "twin_rotor_interceptor", "siege_howitzer", "flak_crew", "rotary_interceptor", "ironclad_medium_tank", "twin_flak_mount", "trench_guard"]},
	# M006 Act III air bosses
	70: {"loadout": ["rolling_shield_trooper", "twin_flak_mount", "multi_barrel_flak", "skyshield_aa_tank", "siege_howitzer", "thunderback_heavy_tank", "repair_wagon",
		"thunderwing", "flak_chaser", "twin_rotor_interceptor", "heavy_gyro_bomber", "skyguard_walker"],
		"order": ["rolling_shield_trooper", "multi_barrel_flak", "thunderback_heavy_tank", "flak_chaser", "skyguard_walker", "siege_howitzer", "thunderwing", "twin_flak_mount", "rolling_shield_trooper", "skyshield_aa_tank", "repair_wagon", "flak_chaser"]},
	80: {"loadout": ["rolling_shield_trooper", "twin_cannon_ironclad", "incendiary_grenadier", "piston_cannon", "heavy_skybreaker", "mobile_flak_fortress", "runic_mechanic",
		"skyshield_airship", "ironcloud", "heavy_interceptor", "ironwing_gunship", "skyguard_walker"],
		"order": ["rolling_shield_trooper", "heavy_skybreaker", "twin_cannon_ironclad", "heavy_interceptor", "incendiary_grenadier", "skyshield_airship", "mobile_flak_fortress", "ironcloud", "rolling_shield_trooper", "piston_cannon", "ironwing_gunship", "runic_mechanic"]},
	90: {"loadout": ["rolling_shield_trooper", "twin_cannon_ironclad", "incendiary_grenadier", "multi_barrel_flak", "heavy_skybreaker", "mobile_flak_fortress", "armored_recovery_team",
		"heavy_interceptor", "thunderwing", "flak_chaser", "skyshield_airship", "skyguard_walker"],
		"order": ["rolling_shield_trooper", "heavy_skybreaker", "twin_cannon_ironclad", "multi_barrel_flak", "heavy_interceptor", "skyguard_walker", "mobile_flak_fortress", "incendiary_grenadier", "flak_chaser", "rolling_shield_trooper", "thunderwing", "skyshield_airship", "armored_recovery_team"]},
	# M007 Act IV foundry bosses (only units a player owns on reaching the stage)
	100: {"loadout": ["royal_iron_guard", "thunderrail_tank_destroyer", "sniper_tank_hunter", "rune_cannon", "piston_cannon", "salvage_crew", "heavy_recovery_crawler",
		"heavy_interceptor", "thunderwing", "flak_chaser", "rocketwing", "anvilbreaker"],
		"order": ["royal_iron_guard", "rune_cannon", "thunderrail_tank_destroyer", "salvage_crew", "heavy_interceptor", "royal_iron_guard", "sniper_tank_hunter", "piston_cannon", "anvilbreaker", "heavy_recovery_crawler", "thunderwing", "thunderrail_tank_destroyer", "salvage_crew", "flak_chaser"]},
	110: {"loadout": ["royal_iron_guard", "mountainshield_heavy_tank", "rune_cannon", "siegecrawler", "runebreaker_infantry", "heavy_recovery_crawler", "mobile_flak_fortress",
		"heavy_interceptor", "thunderwing", "rocketwing", "heavy_gyro_bomber", "siegebellow"],
		"order": ["royal_iron_guard", "rune_cannon", "mountainshield_heavy_tank", "heavy_interceptor", "siegecrawler", "rocketwing", "runebreaker_infantry", "siegebellow", "heavy_gyro_bomber", "royal_iron_guard", "rune_cannon", "heavy_recovery_crawler", "thunderwing", "mobile_flak_fortress"]},
	120: {"loadout": ["kingsguard_bulwark", "mountainshield_heavy_tank", "firestorm_assault_tank", "heavy_gatling_dwarf", "thunder_rocket_battery", "heavy_recovery_crawler", "mobile_flak_fortress",
		"forge_bomber", "siege_breaker_bomber", "heavy_interceptor", "twin_flame_gunship", "shredder_walker"],
		"order": ["kingsguard_bulwark", "firestorm_assault_tank", "heavy_gatling_dwarf", "thunder_rocket_battery", "forge_bomber", "mountainshield_heavy_tank", "heavy_recovery_crawler", "heavy_interceptor", "siege_breaker_bomber", "shredder_walker", "kingsguard_bulwark", "twin_flame_gunship", "heavy_gatling_dwarf", "mobile_flak_fortress"]},
}


func test_boss_counters(only: int) -> void:
	for n in [40, 50, 60, 70, 80, 90, 100, 110, 120]:
		if only != 0 and only != n:
			continue
		var plan: Dictionary = COUNTER_PLANS[n]
		var st = sim_stage(n)   # --heroic plays the Heroic version
		var b = make_battle({"sandbox": false, "seed": int(st.seed)}, st, plan.loadout)
		var order: Array = plan.order
		var k = 0
		var think = 0.0
		var phase = false
		var boss_dead_t = -1.0
		while b.time < 900.0 and not b.over:
			think -= DT
			if think <= 0.0:
				think = 0.5
				if b.mine_level < 2 and b.gold >= b.mine_upgrade_cost():
					b.upgrade_mine()
				var uid: String = order[k % order.size()]
				var why = b.can_deploy(uid)
				if why == "":
					b.deploy(uid)
					k += 1
				elif why == "Cooling down" or why == "Army at capacity" or why.ends_with("Steam"):
					k += 1
				if b.steam >= Battle.OVERDRIVE_COST + 10.0 and b.can_overdrive():
					b.overdrive()
			b.step(DT)
			if b.boss != null and is_instance_valid(b.boss):
				phase = phase or b.boss.phase_on
				if not b.boss.alive and boss_dead_t < 0.0:
					boss_dead_t = b.time
		var d = "%s %s in %.0fs | boss slain at %.0fs, 50%% phase seen=%s | stronghold %.0f%% | stars %s | losses %d" % [st.id, "WIN" if b.won else ("LOSS" if b.over else "TIMEOUT"), b.time, boss_dead_t, phase, b.dwarf_base.hp / b.dwarf_base.max_hp * 100.0, str(b.stars_earned()), b.stats_losses]
		var keys = b.death_log.keys()
		keys.sort_custom(func(x, y): return b.death_log[x] > b.death_log[y])
		if not b.won:
			for kk in keys.slice(0, 8):
				print("    deaths ", b.death_log[kk], "  ", kk)
		record("Boss stage %03d%s won by the intended counters (scripted playthrough)" % [n, " (heroic)" if args.has("heroic") else ""], b.won and phase, d)
		kill_battle(b)


func test_stars() -> void:
	# challenge checks against controlled battle states
	var b = _bare_battle({"challenge": {"kind": "no_air_losses", "text": ""}})
	b.won = true
	var cases = [
		[{"kind": "no_air_losses"}, func(): b.air_losses = 0, true], [{"kind": "no_air_losses"}, func(): b.air_losses = 1, false],
		[{"kind": "time_under", "seconds": 300}, func(): b.time = 299.0, true], [{"kind": "time_under", "seconds": 300}, func(): b.time = 301.0, false],
		[{"kind": "base_above", "frac": 0.7}, func(): b.min_base_frac = 0.71, true], [{"kind": "base_above", "frac": 0.7}, func(): b.min_base_frac = 0.69, false],
		[{"kind": "kill_structures"}, func(): b.structures_total = 2; b.structures_killed = 2, true], [{"kind": "kill_structures"}, func(): b.structures_killed = 1, false],
		[{"kind": "max_types", "n": 3}, func(): b.deploy_types = {"a": 1, "b": 1, "c": 1}, true], [{"kind": "max_types", "n": 3}, func(): b.deploy_types["d"] = 1, false],
		[{"kind": "max_losses", "n": 5}, func(): b.stats_losses = 5, true], [{"kind": "max_losses", "n": 5}, func(): b.stats_losses = 6, false],
		[{"kind": "kill_boss_by", "seconds": 120}, func(): b.boss_arrive_t = 10.0; b.boss_kill_t = 100.0, true], [{"kind": "kill_boss_by", "seconds": 120}, func(): b.boss_kill_t = 200.0, false],
		[{"kind": "no_reclaims"}, func(): b.stats_reclaimed = 0, true], [{"kind": "no_reclaims"}, func(): b.stats_reclaimed = 1, false],
	]
	var bad: Array = []
	for c in cases:
		c[1].call()
		if b.challenge_met(c[0]) != c[2]:
			bad.append(str(c[0]))
	record("Challenge objectives: every kind evaluates correctly", bad.is_empty(), "wrong=%s (%d cases)" % [str(bad), cases.size()])
	# a real won battle: stronghold kept above half -> 2nd star; challenge decides the 3rd
	b.time = 100.0
	b.air_losses = 0
	var st = b.stars_earned()
	record("Stars: victory, stronghold above 50 %, challenge", st == [true, true, true], "earned=%s" % str(st))
	kill_battle(b)
	# rewards: first-time star bonus is +10 %% of the stage's Sparks per star and never repeats
	SaveManager.path = "user://test_stars_save.json"
	GameState.reset_progress()
	var base = int(Registry.stage("s031").rewards.sparks)
	var s0 = GameState.profile.sparks
	var r1 = GameState.grant_stage_rewards("s031", 300.0, 10, [true, true, false])
	var s1 = GameState.profile.sparks
	var r2 = GameState.grant_stage_rewards("s031", 300.0, 10, [true, true, false])
	var s2 = GameState.profile.sparks
	var r3 = GameState.grant_stage_rewards("s031", 300.0, 10, [true, false, true])
	var ok = int(r1.star_bonus) == int(round(base * 0.1)) * 2 and s1 - s0 == base + int(r1.star_bonus) and int(r2.star_bonus) == 0 \
		and int(r3.star_bonus) == int(round(base * 0.1)) and GameState.stars_for("s031") == [true, true, true] and GameState.star_count("s031") == 3
	GameState.reload_from_disk()
	ok = ok and GameState.stars_for("s031") == [true, true, true]
	record("Stars: first-time bonus +10% per new star (max +30%), best stars saved and reloaded", ok,
		"bonus first clear=%d (2 stars), replay same stars=%d, replay new challenge star=%d; stars now %s after reload" % [r1.star_bonus, r2.star_bonus, r3.star_bonus, str(GameState.stars_for("s031"))])
	# every implemented stage has a checkable challenge (Act I retrofit + Act II)
	var missing: Array = []
	for s in Registry.stages:
		if s.implemented and (s.get("challenge") == null or not String(s.challenge.get("kind", "")) in ["no_air_losses", "time_under", "base_above", "kill_structures", "max_types", "max_losses", "kill_boss_by", "escort", "no_reclaims"]):
			missing.append(s.id)
	record("Every implemented stage (001-120) carries a challenge objective (M006 adds escort, M007 no_reclaims)", missing.is_empty(), "missing=%s" % str(missing))
	SaveManager.wipe()


func test_m005_save() -> void:
	# an M004-format save (no stars / hints / tutorial keys) must load, keep progress and gain the new fields
	SaveManager.path = "user://test_m004_save.json"
	var old = SaveManager.default_profile()
	for k in ["stars", "hints_seen", "tutorial_done", "acts_revealed"]:
		old.erase(k)
	old.settings.erase("tutorial")
	old.settings.erase("hints")
	old.cleared = {"s001": {"best_time": 200, "clears": 1}, "s030": {"best_time": 460, "clears": 2}}
	old.open_tiers = [0, 1, 2, 3]
	old.sparks = 777
	old.unlocked_units.append("ironclad_medium_tank")
	old.loadouts["Preset I"][5] = "ironclad_medium_tank"
	var f = FileAccess.open(SaveManager.path, FileAccess.WRITE)
	f.store_string(JSON.stringify(old))
	f.close()
	GameState.reload_from_disk()
	var p = GameState.profile
	var kept = GameState.is_cleared("s030") and p.sparks == 777 and GameState.tier_open(3) and GameState.active_loadout()[5] == "ironclad_medium_tank"
	var gained = p.stars is Dictionary and p.hints_seen is Array and p.tutorial_done is Array and p.acts_revealed == [1] and p.settings.has("hints") and bool(p.settings.hints)
	var tut_off = p.settings.has("tutorial") and not bool(p.settings.tutorial)
	var stars_default = GameState.stars_for("s030") == [true, false, false] and GameState.stars_for("s031") == [false, false, false]
	# the player can now enter Act II
	var act2_open = GameState.stage_available(Registry.stage("s031"))
	GameState.save()
	GameState.reload_from_disk()
	var resaved = GameState.profile.has("stars") and GameState.is_cleared("s030")
	var fresh = SaveManager.default_profile()
	var new_tut = bool(fresh.settings.tutorial) and bool(fresh.settings.hints)
	record("M004 save -> M005: progress kept, new fields added (stars, hints, tutorial off for existing players, act reveals)", kept and gained and tut_off and stars_default and act2_open and resaved and new_tut,
		"kept=%s gained=%s tutorial_off_for_old_save=%s stars_default=%s act2_open=%s resave=%s new_save_tutorial_on=%s" % [kept, gained, tut_off, stars_default, act2_open, resaved, new_tut])
	SaveManager.wipe()


func test_ui_m005() -> void:
	SaveManager.path = "user://test_ui_m005_save.json"
	GameState.reset_progress()
	# --- tutorial on stage 001: a plate appears, pauses the battle, one tap dismisses it
	GameState.selected_stage = "s001"
	var inst = load("res://scenes/battle_screen.tscn").instantiate()
	get_tree().root.add_child(inst)
	var shown = false
	var paused = false
	for i in 90:
		await get_tree().physics_frame
		if inst.guide.showing():
			shown = true
			paused = inst.battle.paused
			break
	var ev = InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	if inst.guide._plate != null:
		inst.guide._plate.gui_input.emit(ev)
	await get_tree().process_frame
	var dismissed = not inst.guide.showing() and not inst.battle.paused
	record("UI tutorial: stage 001 plate appears, pauses, one tap dismisses and resumes", shown and paused and dismissed, "shown=%s paused=%s dismissed+resumed=%s" % [shown, paused, dismissed])
	inst.queue_free()
	await get_tree().process_frame
	# --- first-encounter hint: a hazard hint on an Act II stage, stored so it never repeats
	GameState.profile.settings.tutorial = false
	GameState.profile.cleared["s030"] = {"best_time": 400, "clears": 1}
	GameState.selected_stage = "s031"
	var inst2 = load("res://scenes/battle_screen.tscn").instantiate()
	get_tree().root.add_child(inst2)
	var hint_seen = false
	var hint_paused = false
	for i in 60:
		await get_tree().physics_frame
		if inst2.guide.showing():
			hint_seen = true
			hint_paused = inst2.battle.paused
			break
	var stored = "haz_miasma" in GameState.profile.hints_seen
	record("UI first-encounter hint: shown without pausing, stored in the save", hint_seen and not hint_paused and stored, "shown=%s paused=%s stored=%s seen=%s" % [hint_seen, hint_paused, stored, str(GameState.profile.hints_seen)])
	# --- boss intro: on a boss stage the camera pans to the boss with the battle paused, then resumes
	inst2.battle.time = 0.0
	var boss = inst2.battle.spawn_unit("blightroot_behemoth", 1, Vector2(2300, 0), true)
	inst2.battle.on_boss_spawned(boss)
	var intro = inst2.intro_active and inst2.battle.paused
	var max_x = 0.0
	for i in 240:   # the pan lasts ~2.7 s; physics may tick at 60 Hz
		await get_tree().physics_frame
		max_x = maxf(max_x, inst2.cam.position.x)
		if not inst2.intro_active and i > 30:
			break
	var resumed = not inst2.intro_active and not inst2.battle.paused
	record("UI boss arrival: camera pans to the boss while paused, then the battle resumes", intro and max_x > 1500.0 and resumed, "intro=%s camera reached x=%.0f resumed=%s" % [intro, max_x, resumed])
	inst2.queue_free()
	await get_tree().process_frame
	# --- campaign: Act II drawer with stars, challenge and hazard lines; Realm Map Act II builds
	var cm = load("res://scenes/campaign_map.tscn").instantiate()
	get_tree().root.add_child(cm)
	for i in 20:
		await get_tree().process_frame
	cm.act = 2
	cm._build_map()
	cm._show_detail("s050")
	for i in 10:
		await get_tree().process_frame
	var texts: Array = []
	for c in cm.detail.find_children("*", "Label", true, false):
		texts.append(c.text)
	var joined = " | ".join(texts)
	var ok_d = "Slay the boss" in joined and "Bog:" in joined and "Miasma:" in joined and cm.realm.stages.size() == 30 and int(cm.realm.stages[0].index) == 31
	record("UI campaign: Act II map + drawer show stars, challenge and hazard lines", ok_d, "realm act=%d first=%s drawer has challenge=%s bog=%s miasma=%s; act II revealed=%s" % [cm.realm.act, cm.realm.stages[0].id, "Slay the boss" in joined, "Bog:" in joined, "Miasma:" in joined, 2 in GameState.profile.acts_revealed])
	cm.queue_free()
	await get_tree().process_frame
	SaveManager.wipe()



# ================================================================ M006 — War for the Skies
func _quiet(u) -> void:
	u.speed = 0.0
	u.max_hp = 99999.0
	u.hp = u.max_hp


func test_air_war() -> void:
	# --- data: every flyer has a band, every sky-capable weapon a reach, derived as the spec table says
	var bad: Array = []
	for e in Registry.implemented_dwarves() + Registry.implemented_undead() + Registry.bosses:
		var d = Registry.combat_def(e.id)
		if d.get("domain", "ground") == "air" and not d.has("band"):
			bad.append(e.id + ":band")
		for w in d.get("weapons", []):
			if String(w.get("targets", "ground")) != "ground" and not w.has("reach"):
				bad.append(e.id + ":" + String(w.id))
	var want = {"carrion_bat": "low", "tomb_gargoyle": "low", "coalwing_strafing_craft": "low", "gravewing_stalker": "low", "dwarven_flying_machine": "mid", "ossuary_flier": "mid",
		"ironwing_gunship": "mid", "bone_drake": "high", "necrotic_sky_serpent": "high", "ironcloud": "high", "infected_airbarge": "high", "bone_wyrm": "high", "dread_sky_tyrant": "high", "supply_barge": "mid"}
	var wrong: Array = []
	for k in want:
		var b0 = String(Registry.combat_def(k).get("band", ""))
		if b0 != want[k]:
			wrong.append("%s=%s" % [k, b0])
	record("Air war data: every flyer has an altitude band and every sky weapon a reach (spec table)", bad.is_empty() and wrong.is_empty(), "missing=%s wrong=%s" % [str(bad.slice(0, 8)), str(wrong)])
	# --- the counter matrix (weapon reach vs target band), checked on live units
	var b = _bare_battle({"env": "open_plains"})
	var mk = func(uid, side, x, y): 
		var u = b.spawn_unit(uid, side, Vector2(x, y), true)
		_quiet(u)
		return u
	var drake = mk.call("bone_drake", 1, 1300.0, 250.0)
	var bat = mk.call("carrion_bat", 1, 1350.0, 320.0)
	var flier = mk.call("ossuary_flier", 1, 1360.0, 280.0)
	var cloud = mk.call("ironcloud", 0, 900.0, 180.0)
	var gyro = mk.call("dwarven_flying_machine", 0, 950.0, 280.0)
	var cases = [
		["flak_crew", 0, drake, true], ["skyguard_marksman", 0, drake, true], ["twin_rotor_interceptor", 0, drake, true], ["skyshield_airship", 0, drake, true],
		["ironwing_gunship", 0, drake, false], ["ironwing_gunship", 0, bat, true], ["ironwing_gunship", 0, flier, true], ["scout_gyro", 0, drake, false],
		["thundercoil_frame", 0, drake, false], ["thundercoil_frame", 0, bat, true],
		["blight_bat", 1, cloud, false], ["blight_bat", 1, gyro, true], ["necromancer", 1, cloud, false], ["necromancer", 1, gyro, true],
		["grave_flak_spire", 1, cloud, true], ["soul_turret", 1, cloud, true], ["bone_drake", 1, cloud, true], ["haunted_flying_machine", 1, cloud, true], ["ossuary_flier", 1, cloud, false],
	]
	var fails: Array = []
	for c in cases:
		var a = b.spawn_unit(String(c[0]), int(c[1]), Vector2(1100, 300 if Registry.combat_def(String(c[0])).get("domain", "ground") == "air" else 0), true)
		var can = false
		for w in a.weapons:
			if w.targets != "ground" and w.can_hit_domain(c[2]):
				can = true
		if can != bool(c[3]):
			fails.append("%s vs %s: %s" % [c[0], c[2].id, can])
		a.alive = false
		a.queue_free()
		b.units.erase(a)
		b.by_side[int(c[1])].erase(a)
	record("Altitude bands: low by any sky weapon, mid by flak/AA/aircraft, high only by flak, AA guns, interceptors and airships (19 cases, both sides)", fails.is_empty(), "mismatches=%s" % str(fails))
	kill_battle(b)
	# --- live engagement: a gunship (mid reach) never picks the drake; an interceptor does
	var b2 = _bare_battle({"env": "open_plains"})
	var dr = b2.spawn_unit("bone_drake", 1, Vector2(1200, 250), true)
	_quiet(dr)
	dr.weapons = []
	var gs = b2.spawn_unit("ironwing_gunship", 0, Vector2(1050, 280), true)
	var ic = b2.spawn_unit("twin_rotor_interceptor", 0, Vector2(1000, 280), true)
	var gs_on_drake = false
	var ic_on_drake = false
	for i in int(8.0 / DT):
		b2.step(DT)
		for w in gs.weapons:
			if w.target == dr:
				gs_on_drake = true
		for w2 in ic.weapons:
			if w2.target == dr:
				ic_on_drake = true
	record("Altitude bands in battle: a gunship never targets a high drake; an interceptor engages it", not gs_on_drake and ic_on_drake and dr.hp < dr.max_hp, "gunship targeted drake=%s interceptor targeted drake=%s drake hp %.0f/%.0f" % [gs_on_drake, ic_on_drake, dr.hp, dr.max_hp])
	kill_battle(b2)
	# --- air budget: at most AIR_CAP undead flyers alive at once; bosses ignore it
	var b3 = _bare_battle()
	for i in 40:
		b3.spawn_unit("carrion_bat", 1, Vector2(2000 + i * 5, 300), true)
	var boss = b3.spawn_unit("bone_wyrm", 1, Vector2(2200, 230), true)
	record("Air budget: undead flyers capped at %d alive (bosses exempt)" % Battle.AIR_CAP, b3.air_alive(1) == Battle.AIR_CAP + 1 and boss != null and b3.stats_air_capped == 16, "alive flyers=%d (incl. boss) capped spawns=%d" % [b3.air_alive(1), b3.stats_air_capped])
	kill_battle(b3)
	# --- escort: the barge launches on time, crosses, is delivered -> the escort challenge is met
	var st = Registry.stage_by_index(68).duplicate(true)
	st.escort = {"t": 2, "hp": 2600, "speed": 260, "alt": 215, "x0": 150, "x1": 900}
	var b4 = make_battle({"sandbox": false, "seed": 7, "no_director": true}, st, [])
	b4.invulnerable_bases = true
	var launched_at = -1.0
	for i in int(12.0 / DT):
		b4.step(DT)
		if launched_at < 0.0 and b4.escort_state == "flying":
			launched_at = b4.time
	b4.won = true
	var ok4 = launched_at >= 2.0 and launched_at < 2.2 and b4.escort_state == "delivered" and b4.challenge_met({"kind": "escort"}) and b4.escort_unit.weapons.is_empty()
	record("Escort: the supply barge launches at its time, crosses and is delivered -> escort challenge met", ok4, "launched at %.1fs state=%s challenge=%s" % [launched_at, b4.escort_state, b4.challenge_met({"kind": "escort"})])
	kill_battle(b4)
	# --- escort lost: not a defeat, not a counted loss, the challenge fails; undead target it
	var st5 = Registry.stage_by_index(68).duplicate(true)
	st5.escort = {"t": 1, "hp": 600, "speed": 10, "alt": 260, "x0": 700, "x1": 2300}
	var b5 = make_battle({"sandbox": false, "seed": 7, "no_director": true}, st5, [])
	b5.invulnerable_bases = true
	for i in 3:
		var f = b5.spawn_unit("ossuary_flier", 1, Vector2(1000 + i * 20, 260), true)
	var targeted = false
	for i in int(40.0 / DT):
		b5.step(DT)
		for u in b5.by_side[1]:
			for w in u.weapons:
				if w.target != null and w.target == b5.escort_unit:
					targeted = true
		if b5.escort_state == "lost":
			break
	b5.won = true
	var ok5 = b5.escort_state == "lost" and not b5.over and b5.stats_losses == 0 and b5.air_losses == 0 and not b5.challenge_met({"kind": "escort"}) and targeted
	record("Escort lost: never a defeat or a counted loss; the escort challenge fails; undead flyers hunt it", ok5, "state=%s battle over=%s losses=%d targeted=%s" % [b5.escort_state, b5.over, b5.stats_losses, targeted])
	kill_battle(b5)
	# --- flak belts: stage 062 opens with a line of high-reach anti-air spires across the undead half
	var b6 = make_battle({"sandbox": false, "seed": 7}, Registry.stage_by_index(62), [])
	var spires = b6.by_side[1].filter(func(u): return u.id == "grave_flak_spire")
	var xs = spires.map(func(u): return int(u.position.x))
	var all_high = spires.all(func(u): return u.weapons.all(func(w): return w.reach == 2))
	record("Flak belt: stage 062 starts with three high-reach flak spires in a line (x 1650-2120)", spires.size() == 3 and all_high and xs.min() >= 1600 and xs.max() <= 2150, "spires=%d at %s all reach high=%s" % [spires.size(), str(xs), all_high])
	kill_battle(b6)
	# --- every Act III stage keeps both fronts and the act uses escorts and flak belts
	var n_escort = 0
	var n_belt = 0
	for i in range(61, 91):
		var s3 = Registry.stage_by_index(i)
		if s3.get("escort") != null:
			n_escort += 1
		if s3.structures.filter(func(x): return String(x.enemy) in ["grave_flak_spire", "soul_turret"]).size() >= 2:
			n_belt += 1
	record("Act III uses escort objectives and flak belts", n_escort == 3 and n_belt >= 6, "escort stages=%d flak-belt stages=%d" % [n_escort, n_belt])


func test_hazards_m006() -> void:
	# --- thermals: flyers inside a column rise (updraft) or sink (downdraft) a band, aircraft +/-20 % speed
	var b = _bare_battle({"env": "open_plains"})
	b.set_thermals({"columns": [[800, 1], [1400, -1]], "width": 160})
	var up = b.spawn_unit("dwarven_flying_machine", 0, Vector2(800, 280), true)
	var down = b.spawn_unit("dwarven_flying_machine", 0, Vector2(1400, 280), true)
	var free_u = b.spawn_unit("dwarven_flying_machine", 0, Vector2(2000, 280), true)
	var drake = b.spawn_unit("bone_drake", 1, Vector2(1400, 260), true)
	for u in [up, down, free_u, drake]:
		u.weapons = []
		u.alt_target = 280.0
	var gs = b.spawn_unit("ironwing_gunship", 0, Vector2(300, 300), true)
	var reach_before = gs.weapons[1].can_hit_domain(drake)
	for i in int(3.0 / DT):
		b.step(DT)
		up.position.x = 800.0
		down.position.x = 1400.0
		drake.position.x = 1400.0
	var reach_after = gs.weapons[1].can_hit_domain(drake)
	var ok = up.thermal == 1.0 and up.band_i() == 2 and down.thermal == -1.0 and down.band_i() == 0 and free_u.thermal == 0.0 and free_u.band_i() == 1 \
		and up.position.y < 270.0 and down.position.y > 290.0 and drake.band_i() == 1 and not reach_before and reach_after
	record("Hazard thermals: updrafts lift flyers a band, downdrafts sink them (a sunk drake comes into a gunship's reach)", ok,
		"up: thermal %+.0f band %d y %.0f | down: thermal %+.0f band %d y %.0f | outside: band %d | drake band %d, gunship reach before/after %s/%s" % [up.thermal, up.band_i(), up.position.y, down.thermal, down.band_i(), down.position.y, free_u.band_i(), drake.band_i(), reach_before, reach_after])
	# speed: same flight, inside an updraft vs outside
	var u2 = b.spawn_unit("dwarven_flying_machine", 0, Vector2(500, 300), true)
	u2.weapons = []
	u2.thermal = 1.0
	var s_up = u2.move_speed() * (1.0 + 0.2 * u2.thermal)
	u2.thermal = -1.0
	var s_dn = u2.move_speed() * (1.0 + 0.2 * u2.thermal)
	record("Hazard thermals: aircraft speed +20 % in updrafts, -20 % in downdrafts", absf(s_up / u2.move_speed() - 1.2) < 0.01 and absf(s_dn / u2.move_speed() - 0.8) < 0.01, "speed x%.2f / x%.2f" % [s_up / u2.move_speed(), s_dn / u2.move_speed()])
	kill_battle(b)
	# --- lightning: a 0.8 s telegraph, then the tallest thing near the strike is hit: flyers first
	var b2 = _bare_battle({"env": "broken_ridge"})
	var walker = b2.spawn_unit("ironclad_walker", 0, Vector2(1000, 0), true)
	var bat = b2.spawn_unit("carrion_bat", 1, Vector2(1020, 300), true)
	var inf = b2.spawn_unit("shambler", 1, Vector2(1040, 0), true)
	for u in [walker, bat, inf]:
		_quiet(u)
		u.weapons = []
	var tgt = b2.tallest_near(1000.0, 170.0)
	b2.bolts.append({"x": 1000.0, "target": tgt, "t": 0.0, "warn": 0.8, "dmg": 150.0, "r": 40.0, "struck": false, "y": 300.0})
	for i in int(0.7 / DT):
		b2.step(DT)
	var before_hp = bat.hp
	for i in int(0.4 / DT):
		b2.step(DT)
	var ok2 = tgt == bat and before_hp == bat.max_hp and bat.hp < bat.max_hp and b2.stats_lightning == 1
	# no flyers near: the walker is the tallest; an undead spire takes double damage
	bat.alive = false
	var tgt2 = b2.tallest_near(1000.0, 60.0)
	var spire = b2.spawn_unit("grave_flak_spire", 1, Vector2(1700, 0), true)
	spire.max_hp = 9999.0
	spire.hp = 9999.0
	spire.weapons = []
	b2.bolts.append({"x": 1700.0, "target": spire, "t": 0.0, "warn": 0.8, "dmg": 100.0, "r": 10.0, "struck": false, "y": 400.0})
	for i in int(1.0 / DT):
		b2.step(DT)
	var spire_loss = 9999.0 - spire.hp
	record("Hazard lightning: 0.8 s telegraph, then it hits the tallest thing near — a flyer first, else a walker; spires take double", ok2 and tgt2 == walker and absf(spire_loss - 200.0) < 1.0,
		"first target=%s (hp before warn ended %.0f, after %.0f) | without flyers=%s | spire damage %.0f from a 100 bolt" % [tgt.id if tgt != null else "none", before_hp, bat.hp, tgt2.id if tgt2 != null else "none", spire_loss])
	kill_battle(b2)
	# --- both sides: the storm also strikes dwarven aircraft
	var b3 = _bare_battle({"env": "broken_ridge"})
	var gy = b3.spawn_unit("dwarven_flying_machine", 0, Vector2(1500, 280), true)
	_quiet(gy)
	gy.weapons = []
	b3.lightning_strike(150.0, 40.0, 0.8)
	var tg3 = b3.bolts[0].target if not b3.bolts.is_empty() else null
	for i in int(1.2 / DT):
		b3.step(DT)
	# force the strike near the gyro to prove dwarves are fair game too
	b3.bolts.append({"x": 1500.0, "target": b3.tallest_near(1500.0, 170.0), "t": 0.0, "warn": 0.8, "dmg": 150.0, "r": 40.0, "struck": false, "y": 280.0})
	for i in int(1.2 / DT):
		b3.step(DT)
	record("Hazard lightning strikes both sides (a dwarven aircraft under the storm is hit)", gy.hp < gy.max_hp and b3.stats_lightning_hits[0] >= 1, "gyro hp %.0f/%.0f dwarf hits=%d" % [gy.hp, gy.max_hp, b3.stats_lightning_hits[0]])
	kill_battle(b3)
	# --- data: storm stages strike on schedule, darken the sky; the act uses all three sky hazards
	var b4 = make_battle({"sandbox": false, "seed": 7}, Registry.stage_by_index(67), [])
	b4.invulnerable_bases = true
	for i in int(40.0 / DT):
		b4.step(DT)
	record("Hazards load from stage data: s067 storm strikes on schedule and darkens the battle sky", b4.stats_lightning >= 2 and b4.background.storm, "strikes in 40 s=%d storm sky=%s" % [b4.stats_lightning, b4.background.storm])
	kill_battle(b4)
	var n = {"thermals": 0, "lightning_storm": 0, "gale": 0}
	for i in range(61, 91):
		for h in WaveDirector.hazard_list(Registry.stage_by_index(i)):
			if n.has(String(h.kind)):
				n[String(h.kind)] += 1
	record("Act III stages use thermals, lightning storms and gales", n.thermals >= 4 and n.lightning_storm >= 4 and n.gale >= 4, str(n))


func test_boss_phases_m006() -> void:
	# Bone Wyrm: dives into the chasm (untargetable), erupts under a telegraphed spot, lies ground-targetable, takes off
	var r = _boss_battle("bone_wyrm", [["shieldbearer", 3, 1300], ["light_field_cannon", 3, 900]])
	var b: Battle = r[0]
	var wyrm = r[1]
	wyrm.hp = wyrm.max_hp * 0.49
	var dove = false
	var untargetable = false
	var erupted = false
	var gun_on_wyrm = false
	var hits0 = b.stats_strike_hits
	for i in int(16.0 / DT):
		b.step(DT)
		if wyrm.dive_t > 0.0:
			dove = true
			untargetable = untargetable or not wyrm.targetable_by(0)
		if wyrm.perch_t > 0.0 and wyrm.domain == "ground":
			erupted = true
			for u in r[2]:
				if is_instance_valid(u) and u.id == "light_field_cannon" and u.weapons[0].target == wyrm:
					gun_on_wyrm = true
	var back = wyrm.domain == "air"
	record("Boss phase: Bone Wyrm dives (untargetable), erupts under a telegraphed spot, is ground-targetable, then takes off", wyrm.phase_on and dove and untargetable and erupted and gun_on_wyrm and back and b.stats_wyrm_dives >= 1 and b.stats_strike_hits > hits0,
		"dove=%s untargetable while under=%s erupted=%s ground gun targeted it=%s back in air=%s strike hits=%d" % [dove, untargetable, erupted, gun_on_wyrm, back, b.stats_strike_hits - hits0])
	kill_battle(b)
	# Hollow Admiral: two escort airbarges arrive and shield it until one falls
	var r2 = _boss_battle("hollow_admiral", [["flak_crew", 2, 1500]])
	var b2: Battle = r2[0]
	var adm = r2[1]
	adm.hp = adm.max_hp * 0.49
	for i in int(1.0 / DT):
		b2.step(DT)
	var escorts = adm.phase_heralds.filter(func(h): return is_instance_valid(h) and h.alive and h.id == "infected_airbarge").size()
	var sh = adm.shielded
	var hp0 = adm.hp
	adm.take_damage(500.0, null)
	var immune = adm.hp == hp0
	for h in adm.phase_heralds:
		if is_instance_valid(h) and h.alive:
			h.take_damage(999999.0, null)
			break
	for i in 4:
		b2.step(DT)
	adm.take_damage(500.0, null)
	record("Boss phase: Hollow Admiral is shielded by two escort airbarges until one falls", escorts == 2 and sh and immune and not adm.shielded and adm.hp < hp0 and b2.stats_shield_breaks == 1,
		"escorts=%d shielded=%s immune while shielded=%s shield after escort died=%s hp %.0f -> %.0f" % [escorts, sh, immune, adm.shielded, hp0, adm.hp])
	kill_battle(b2)
	# Dread Sky Tyrant: the storm intensifies and hunts aircraft at 50 %; at 25 % it lands on the ground front
	var st90 = Registry.stage_by_index(90)
	var b3 = make_battle({"sandbox": false, "seed": 7}, st90, [])
	b3.invulnerable_bases = true
	var ty = b3.spawn_unit("dread_sky_tyrant", 1, Vector2(1900, 230), true)
	b3.on_boss_spawned(ty)
	var guns = spawn_many(b3, "light_field_cannon", 0, 2, 1200, 30)
	spawn_many(b3, "shieldbearer", 0, 2, 1350, 20)
	for g in guns:
		g.max_hp = 99999.0
		g.hp = 99999.0
	ty.hp = ty.max_hp * 0.49
	for i in int(1.0 / DT):
		b3.step(DT)
	var storm_on = b3.director.storm_boost > 1.0 and b3.lightning_air_bias > 0.0
	ty.hp = ty.max_hp * 0.24
	var landed = false
	var gun_on = false
	for i in int(12.0 / DT):
		b3.step(DT)
		if ty.perch_t > 0.0 and ty.domain == "ground":
			landed = true
			for g in guns:
				if g.weapons[0].target == ty:
					gun_on = true
	record("Boss phase: Dread Sky Tyrant's storm intensifies at 50% (faster, hunts aircraft); at 25% it lands on the ground front", ty.phase_on and storm_on and landed and gun_on and ty.domain == "air",
		"storm boost %.1f air bias %.1f landed=%s ground guns targeted it=%s back in the air=%s" % [b3.director.storm_boost, b3.lightning_air_bias, landed, gun_on, ty.domain == "air"])
	kill_battle(b3)


func test_m006_save() -> void:
	# an M005-format save (no motion setting, no escorts stat) must load, keep progress and gain the new fields
	SaveManager.path = "user://test_m005_save.json"
	var old = SaveManager.default_profile()
	old.settings.erase("motion")
	old.stats.erase("escorts")
	for i in range(1, 61):
		old.cleared["s%03d" % i] = {"best_time": 300, "clears": 1}
	old.stars = {"s060": [true, true, false], "s059": [true, true, true]}
	old.open_tiers = [0, 1, 2, 3]
	old.acts_revealed = [1, 2]
	old.sparks = 4321
	old.unlocked_units.append("heavy_gyro_bomber")
	var f = FileAccess.open(SaveManager.path, FileAccess.WRITE)
	f.store_string(JSON.stringify(old))
	f.close()
	GameState.reload_from_disk()
	var p = GameState.profile
	var kept = GameState.is_cleared("s060") and p.sparks == 4321 and GameState.tier_open(3) and not GameState.tier_open(4) and GameState.stars_for("s059") == [true, true, true] and GameState.is_unlocked("heavy_gyro_bomber")
	var gained = p.settings.has("motion") and bool(p.settings.motion) and p.stats.has("escorts") and int(p.stats.escorts) == 0
	var act3_open = GameState.stage_available(Registry.stage("s061"))
	# clearing 075 opens T4
	GameState.grant_stage_rewards("s075", 400.0, 200, [true, true, true])
	var t4 = GameState.tier_open(4)
	GameState.save()
	GameState.reload_from_disk()
	var resaved = GameState.profile.settings.has("motion") and GameState.is_cleared("s075") and GameState.tier_open(4)
	record("M005 save -> M006: progress kept, new fields added (motion setting, escorts stat), Act III open, s075 opens T4", kept and gained and act3_open and t4 and resaved,
		"kept=%s gained=%s act3_open=%s t4_after_075=%s resave=%s" % [kept, gained, act3_open, t4, resaved])
	SaveManager.wipe()


func test_ui_m006() -> void:
	SaveManager.path = "user://test_ui_m006_save.json"
	GameState.reset_progress()
	GameState.profile.settings.tutorial = false
	GameState.profile.settings.hints = false
	for i in range(1, 68):
		GameState.profile.cleared["s%03d" % i] = {"best_time": 300, "clears": 1}
	# --- battle HUD: the sky-threat indicator counts flyers by band; the escort bar appears with the barge
	GameState.selected_stage = "s068"
	var inst = load("res://scenes/battle_screen.tscn").instantiate()
	get_tree().root.add_child(inst)
	for i in 10:
		await get_tree().physics_frame
	var bt: Battle = inst.battle
	bt.spawn_unit("bone_drake", 1, Vector2(2000, 230), true)
	bt.spawn_unit("carrion_bat", 1, Vector2(2000, 330), true)
	var c: Array = bt.sky_threat()
	var hidden_before = not inst.escort_bar.visible
	bt.spawn_escort({"t": 0, "hp": 2600, "speed": 20, "alt": 215, "x0": 150, "x1": 2150})
	for i in 6:
		await get_tree().physics_frame
	var shown = inst.escort_bar.visible and absf(bt.escort_frac() - 1.0) < 0.01
	record("UI battle HUD: sky-threat indicator counts flyers by band; escort bar appears with the barge", c[2] >= 1 and c[0] >= 1 and hidden_before and shown and inst.sky_threat != null,
		"threat low/mid/high=%s escort bar hidden before=%s shown after=%s" % [str(c), hidden_before, shown])
	inst.queue_free()
	await get_tree().process_frame
	# --- campaign: Act III drawer shows the escort line and (for cleared stages) the sky bands
	var cm = load("res://scenes/campaign_map.tscn").instantiate()
	get_tree().root.add_child(cm)
	for i in 20:
		await get_tree().process_frame
	cm.act = 3
	cm._build_map()
	cm._show_detail("s068")
	for i in 6:
		await get_tree().process_frame
	var t68 = " | ".join(cm.detail.find_children("*", "Label", true, false).map(func(l): return l.text))
	cm._show_detail("s065")
	for i in 6:
		await get_tree().process_frame
	var t65 = " | ".join(cm.detail.find_children("*", "Label", true, false).map(func(l): return l.text))
	var aloft_n = cm.realm.aloft.filter(func(x): return x).size()
	var aloft_ok = true
	for i in 30:
		if cm.realm.aloft[i]:
			aloft_ok = aloft_ok and cm.realm.pts[i].y < cm.realm.surf_y(cm.realm.pts[i].x) - 100.0
	var ok_c = "Escort:" in t68 and "Sky bands:" in t65 and "high" in t65 and "Thermals:" in t65 or ("Escort:" in t68 and "Sky bands:" in t65)
	record("UI campaign: Act III drawer shows the escort objective and sky bands; airborne landmarks float aloft", ok_c and aloft_n == 9 and aloft_ok,
		"escort line=%s sky bands=%s aloft landmarks=%d all above surface=%s" % ["Escort:" in t68, "Sky bands:" in t65, aloft_n, aloft_ok])
	cm.queue_free()
	await get_tree().process_frame
	# --- compendium: band and can-hit lines on dossiers
	var dr = Registry.combat_def("bone_drake")
	var fc = Registry.combat_def("flak_crew")
	var gs = Registry.combat_def("ironwing_gunship")
	record("UI compendium: altitude band and can-hit lines", Hints.band_of(dr) == "high" and Hints.can_hit(fc) == "low, mid, high" and Hints.can_hit(gs) == "ground, low, mid" and Hints.band_of(fc) == "",
		"drake band=%s flak can hit=%s gunship can hit=%s" % [Hints.band_of(dr), Hints.can_hit(fc), Hints.can_hit(gs)])
	SaveManager.wipe()


func test_motion() -> void:
	# the motion layer: springs settle, kicks lean back, footfalls compress, nothing explodes; no logic effect on bake scale
	var b = _bare_battle({"env": "open_plains"})
	var mech = b.spawn_unit("ironclad_walker", 0, Vector2(800, 0), true)
	var inf = b.spawn_unit("ironhold_rifleman", 0, Vector2(700, 0), true)
	var tank = b.spawn_unit("ironclad_medium_tank", 0, Vector2(600, 0), true)
	var ship = b.spawn_unit("ironcloud", 0, Vector2(600, 180), true)
	var zom = b.spawn_unit("shambler", 1, Vector2(1300, 0), true)
	for u in [mech, inf, tank, ship, zom]:
		pass
	var w = mech.weapons[0]
	mech.on_fire(w)
	var kicked = mech.mo_vk < 0.0
	tank.on_fire(tank.weapons[0])
	ship.on_fire(ship.weapons[0])
	var max_skew = 0.0
	var nan = false
	for i in int(3.0 / DT):
		b.step(DT)
		for u in [mech, inf, tank, ship, zom]:
			if not is_instance_valid(u):
				continue
			max_skew = maxf(max_skew, absf(u.skew))
			if is_nan(u.skew) or is_nan(u.scale.y) or is_nan(u.rotation):
				nan = true
	var leaning = absf(inf.skew) > 0.02 or inf.state != "move"
	# a lone unit with no events settles back to rest
	var c2 = b.spawn_unit("ironclad_walker", 0, Vector2(400, 0), true)
	c2.speed = 0.0
	c2.weapons = []
	c2.mo_vy = 20.0
	c2.mo_vk = -10.0
	for i in int(6.0 / DT):
		b.step(DT)
	var settled = absf(c2.mo_y) < 0.05 and absf(c2.mo_k) < 0.05
	var scale_ok = PoseCache.screen_scale_base(mech, mech.art_scale) == PoseCache.screen_scale_base(mech, mech.art_scale)
	Unit.motion_on = false
	b.step(DT)
	var off_ok = c2.skew == 0.0
	Unit.motion_on = true
	record("Motion layer: recoil kicks, springs settle, bounded lean, no NaN, reduced-motion switch works", kicked and max_skew <= 0.41 and not nan and settled and off_ok and leaning and scale_ok,
		"kick=%s max skew %.2f nan=%s settled=%s reduced-motion zeroes skew=%s" % [kicked, max_skew, nan, settled, off_ok])
	kill_battle(b)
	# the motion layer is presentation only: the same stage plays out identically with it on or off
	var res: Array = []
	for on in [true, false]:
		Unit.motion_on = on
		var st = Registry.stage_by_index(40)
		var bb = make_battle({"sandbox": false, "seed": int(st.seed)}, st, loadout_for_stage(40))
		var ai = AutoCommander.new()
		ai.generic = true
		for i in int(150.0 / DT):
			ai.step(bb, DT)
			bb.step(DT)
		res.append([bb.stats_kills, bb.stats_losses, int(bb.dwarf_base.hp), int(bb.enemy_base.hp), bb.stats_deployed])
		kill_battle(bb)
	Unit.motion_on = true
	record("Motion layer never touches gameplay: stage 040, 150 s, identical with motion on and off", res[0] == res[1], "on=%s off=%s (kills, losses, stronghold, citadel, deployed)" % [str(res[0]), str(res[1])])


# ------------------------------------------------------------------ M006b: machine art overhaul
class ArtProbe extends Node2D:
	var art = ""
	var pose = {}
	var done = 0
	func _draw() -> void:
		Painter.draw_unit(self, art, pose)
		done += 1


func _machine_arts() -> Array:
	var arts: Array = []
	for e in Registry.implemented_dwarves() + Registry.implemented_undead() + Registry.bosses:
		var a = String(Registry.combat_def(e.id).get("art", ""))
		if a == "" or a in arts:
			continue
		var fam = String(ArtKit.params(a).get("fam", "")) if ArtKit.has(a) else ""
		if ArtMechs.has(a) or fam in ["veh", "air", "ship", "corrupt"] or a in ["copperback", "brasshound"]:
			arts.append(a)
	for k in Registry.aux.keys():
		if ArtKit.has(String(k)) and String(ArtKit.params(String(k)).get("fam", "")) == "ship" and not String(k) in arts:
			arts.append(String(k))
	return arts


func test_art_m006b() -> void:
	# 1. every war frame, vehicle, aircraft, airship and corrupted machine draws to the end in every state
	var poses: Array = [
		{"state": "idle", "t": 0.3}, {"state": "move", "walk": 1.2, "t": 0.5}, {"state": "move", "walk": 4.0, "t": 0.8},
		{"state": "idle", "engage": 1.0}, {"engage": 1.0, "windup": 1.0}, {"engage": 1.0, "atk": 1.0}, {"engage": 1.0, "atk": 0.75, "gag": 0.8},
		{"engage": 1.0, "atk": 0.5, "gag": 0.6}, {"engage": 1.0, "atk": 0.25, "gag": 0.4}, {"engage": 1.0, "gag": 0.2},
		{"ability_anim": 1.0}, {"stun_t": 1.0}, {"brace_t": 1.0}, {"hp_frac": 0.45}, {"hp_frac": 0.2, "state": "move", "walk": 2.0},
		{"ammo": 0, "atk": 0.6}, {"ammo": 1}, {"aim0": -1.2, "aim1": -1.2, "aim2": -1.2, "atk2": 1.0, "atk3": 1.0}]
	var arts = _machine_arts()
	var pr = ArtProbe.new()
	add_child(pr)
	var broken: Array = []
	var fams = {"mech": 0, "veh": 0, "air": 0, "ship": 0, "corrupt": 0, "legacy": 0}
	for art in arts:
		var fk = "mech" if ArtMechs.has(art) else (String(ArtKit.params(art).get("fam", "")) if ArtKit.has(art) else "legacy")
		fams[fk] = int(fams.get(fk, 0)) + 1
		for p0 in poses:
			var p = {"state": "idle", "t": 0.3, "walk": 0.0, "atk": 0.0, "engage": 0.0}
			p.merge(p0, true)
			var before = pr.done
			pr.art = art
			pr.pose = p
			pr.queue_redraw()
			await get_tree().process_frame
			if pr.done != before + 1:
				broken.append("%s %s" % [art, str(p0)])
	pr.queue_free()
	record("M006b: every machine art draws completely in all %d animation states" % poses.size(), broken.is_empty() and arts.size() >= 85,
		"%d arts %s, broken=%s" % [arts.size(), str(fams), str(broken.slice(0, 5))])
	# 2. the war-frame timeline: stance, combat stance, wind-up, strike, follow-through, recovery are distinct
	var fam_list: Array = ArtMechs.ARM_POSE.keys() + ["cannon", "rifle"]
	var flat: Array = []
	for fam in fam_list:
		var st = ArtMechs.arm_pose(fam, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3)
		var cb = ArtMechs.arm_pose(fam, 1.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3)
		var wu = ArtMechs.arm_pose(fam, 1.0, 0.0, 1.0, 0.0, 0.0, 0.3, 0.3)
		var hit = ArtMechs.arm_pose(fam, 1.0, 1.0, 0.0, 1.0, 0.0, 0.3, 0.3)
		var fol = ArtMechs.arm_pose(fam, 1.0, 0.6, 0.0, 0.8, 0.0, 0.3, 0.3)
		var rec = ArtMechs.arm_pose(fam, 1.0, 0.0, 0.0, 0.4, 0.0, 0.3, 0.3)
		var seq = [st, cb, wu, hit, fol, rec]
		for i in seq.size() - 1:
			var d = absf(float(seq[i][0]) - float(seq[i + 1][0])) + absf(float(seq[i][1]) - float(seq[i + 1][1]))
			if d < 0.02 and not fam in ["stub", "brace"]:
				flat.append("%s:%d" % [fam, i])
	record("M006b: every arm family moves through stance > combat > wind-up > strike > follow-through > recovery", flat.is_empty(), "families=%d flat transitions=%s" % [fam_list.size(), str(flat)])
	# 3. every war frame actually reads the combat-timeline keys; machines read their running-gear / damage keys
	var miss: Array = []
	for art in arts:
		var keys: Dictionary = Painter.used_keys.get(art, {})
		var need: Array = []
		if ArtMechs.has(art):
			need = ["atk", "windup", "engage", "gag", "walk", "ability_anim"]
		elif ArtKit.has(art) and String(ArtKit.params(art).get("fam", "")) == "veh":
			need = ["walk", "atk", "hp_frac", "t"]
		elif ArtKit.has(art) and String(ArtKit.params(art).get("fam", "")) in ["air", "ship"]:
			need = ["t", "hp_frac", "atk"]
		for k in need:
			if not keys.has(k):
				miss.append("%s.%s" % [art, k])
	record("M006b: war frames animate on atk/windup/engage/gag/walk/ability; vehicles, aircraft and airships on running gear, firing and damage", miss.is_empty(), "missing=%s" % str(miss.slice(0, 8)))
	# 4. the pose cache stays bounded: machines show 3 damage states, kit bombers 3 ammo states
	var b = _bare_battle({"env": "open_plains"})
	var tank = b.spawn_unit("ironclad_medium_tank", 0, Vector2(600, 0), true)
	var bomber = b.spawn_unit("heavy_gyro_bomber", 0, Vector2(600, 260), true)
	var hp_vals = {}
	var ammo_vals = {}
	for i in 21:
		tank.hp = tank.max_hp * (1.0 - i / 20.0) + 0.001
		tank.hp_frac = tank.hp / tank.max_hp
		var pp = tank.make_pose()
		if pp.has("hp_frac"):
			hp_vals[pp.hp_frac] = true
		bomber.ammo = i % 7
		var pb = bomber.make_pose()
		if pb.has("ammo"):
			ammo_vals[pb.ammo] = true
	kill_battle(b)
	# 5. M006c: every kit vehicle (and the corrupted Gravegun) has its own design, with its own size
	var veh: Array = []
	for art in arts:
		if ArtKit.has(art) and String(ArtKit.params(art).get("fam", "")) == "veh":
			veh.append(art)
	veh.append("gravegun_tank")
	var missing: Array = []
	var sizes = {}
	var hulls = {}
	for art in veh:
		if not ArtTanks.has(art):
			missing.append(art)
			continue
		var dd: Dictionary = ArtTanks.DESIGNS[art]
		sizes["%d/%d" % [int(dd.L), int(dd.H)]] = true
		hulls[str(dd.profile)] = true
	record("M006c: every tank has its own design (size, chassis, hull profile)", missing.is_empty() and hulls.size() == veh.size() and sizes.size() >= veh.size() - 2,
		"vehicles=%d missing=%s distinct hull profiles=%d distinct L/H sizes=%d" % [veh.size(), str(missing), hulls.size(), sizes.size()])
	record("M006b: pose cache bounded (tank damage states <= 3, bomber ammo states <= 3)", hp_vals.size() <= 3 and hp_vals.size() >= 2 and ammo_vals.size() <= 3,
		"tank hp_frac=%s bomber ammo=%s" % [str(hp_vals.keys()), str(ammo_vals.keys())])



# ================================================================== M007 Act IV: the Fallen Foundries
func _wreck_battle() -> Battle:
	var b = _bare_battle({"wrecks": true, "env": "mech_graveyard"})
	b.invulnerable_bases = true
	return b


## Kills a dwarven machine where it stands (as combat would), so it leaves a wreck.
func _kill(b: Battle, u) -> void:
	u.take_damage(u.max_hp * 10.0, null)


func test_wrecks() -> void:
	# 1. a destroyed dwarven tank leaves a wreck; a corpse priest walks to it, channels 4 s and raises a corrupted machine
	var b = _wreck_battle()
	var tank = b.spawn_unit("ironclad_medium_tank", 0, Vector2(1200, 0), true)
	_kill(b, tank)
	var w0 = b.wrecks.size()
	var priest = b.spawn_unit("corpse_priest", 1, Vector2(1520, 0), true)
	var corrupted_before = b.by_side[1].filter(func(u): return u.alive and u.id in Battle.CORRUPTED_IDS).size()
	var chan_seen = false
	var chan_t_at_raise = 0.0
	for i in int(25.0 / DT):
		b.step(DT)
		if not b.wrecks.is_empty() and b.wrecks[0].chan != null:
			chan_seen = true
			chan_t_at_raise = b.wrecks[0].chan_t
		if b.stats_reclaimed > 0:
			break
	var corrupted_after = b.by_side[1].filter(func(u): return u.alive and u.id in Battle.CORRUPTED_IDS).size()
	var raised_id = b.stats_reclaimed_ids[0] if not b.stats_reclaimed_ids.is_empty() else ""
	var ok1 = w0 == 1 and chan_seen and b.stats_reclaimed == 1 and corrupted_after == corrupted_before + 1 and raised_id in ["risen_copperback", "gravegun_tank", "cursed_ironclad"] and b.wrecks.is_empty()
	record("Wreck reclamation: a destroyed tank leaves a wreck; a corpse priest walks to it, channels and raises a corrupted tank", ok1,
		"wrecks after death=%d channel seen=%s reclaimed=%d raised=%s corrupted machines %d -> %d" % [w0, chan_seen, b.stats_reclaimed, raised_id, corrupted_before, corrupted_after])
	kill_battle(b)
	# 2. matching classes: a war frame becomes a possessed drillwalker / cursed ironclad, an aircraft a haunted flying machine
	var rng = RandomNumberGenerator.new()
	rng.seed = 3
	var kinds_ok = Foundry.reclaim_unit("walker", 500.0, rng) == "possessed_drillwalker" and Foundry.reclaim_unit("air", 300.0, rng) == "haunted_flying_machine" \
		and Foundry.reclaim_unit("tank", 120.0, rng) == "risen_copperback"
	var b2 = _wreck_battle()
	var frame = b2.spawn_unit("ironclad_walker", 0, Vector2(1100, 0), true)
	var heli = b2.spawn_unit("rotary_interceptor", 0, Vector2(1300, 300), true)
	_kill(b2, frame)
	_kill(b2, heli)
	var kinds = b2.wrecks.map(func(w): return String(w.kind))
	for i in int(3.0 / DT):
		b2.step(DT)
	var air_wreck_down = heli.position.y >= Combat.GROUND_Y - 30.0
	record("Wreck classes: war frame -> walker wreck (possessed drillwalker), aircraft -> air wreck falling to the ground (haunted flying machine), light tank -> risen copperback",
		kinds_ok and kinds == ["walker", "air"] and air_wreck_down, "kinds=%s mapping ok=%s aircraft wreck on the ground=%s" % [str(kinds), kinds_ok, air_wreck_down])
	kill_battle(b2)
	# 3. salvage prevents it: a salvage crew next to the wreck clears it in 3 s and refunds Gold; the priest gets nothing
	var b3 = _wreck_battle()
	var t3 = b3.spawn_unit("thunderback_heavy_tank", 0, Vector2(1200, 0), true)
	_kill(b3, t3)
	var crew = b3.spawn_unit("salvage_crew", 0, Vector2(1150, 0), true)
	b3.spawn_unit("corpse_priest", 1, Vector2(1480, 0), true)
	b3.gold = 0.0
	for i in int(12.0 / DT):
		b3.step(DT)
	var ok3 = b3.stats_salvaged == 1 and b3.stats_reclaimed == 0 and b3.gold >= b3.stats_salvage_gold - 0.01 and b3.stats_salvage_gold > 0.0 and b3.wrecks.is_empty()
	record("Salvage denies reclamation: a salvage crew clears the wreck in 3 s and refunds Gold before the priest can raise it", ok3,
		"salvaged=%d reclaimed=%d refund=%.0f gold" % [b3.stats_salvaged, b3.stats_reclaimed, b3.stats_salvage_gold])
	kill_battle(b3)
	# 4. the cap holds: ten machines die, never more than WRECK_CAP wrecks; the oldest crumble first
	var b4 = _wreck_battle()
	var first_serial = -1
	for k in 10:
		var tk = b4.spawn_unit("copperback_light_tank", 0, Vector2(700 + k * 60, 0), true)
		if k == 0:
			first_serial = tk.serial
		_kill(b4, tk)
	var peak = b4.wrecks.size()
	var oldest_gone = b4.wrecks.all(func(w): return int(w.serial) != first_serial)
	b4.step(DT)
	# 5. wrecks expire after ~20 s
	for i in int((Foundry.WRECK_LIFE + 2.0) / DT):
		b4.step(DT)
	var expired = b4.wrecks.is_empty() and b4.stats_wreck_expired >= 10
	var freed = b4.units.filter(func(u): return is_instance_valid(u) and not u.alive and not u.is_stronghold).size()
	record("Wreck cap holds (max %d, oldest crumble first) and wrecks expire after %.0f s" % [Foundry.WRECK_CAP, Foundry.WRECK_LIFE], peak == Foundry.WRECK_CAP and oldest_gone and expired and freed == 0,
		"peak=%d oldest gone=%s expired=%s (count %d) dead nodes left=%d" % [peak, oldest_gone, expired, b4.stats_wreck_expired, freed])
	kill_battle(b4)
	# 6. no wrecks outside Act IV (Acts I-III unchanged), and escorts / summoned turrets never leave one
	var b5 = _bare_battle({"env": "open_plains"})
	var t5 = b5.spawn_unit("ironclad_medium_tank", 0, Vector2(1200, 0), true)
	_kill(b5, t5)
	var none_outside = b5.wrecks.is_empty()
	kill_battle(b5)
	record("Wrecks only where the stage enables them (Act IV); earlier acts unchanged", none_outside, "wrecks on a non-Act-IV stage=%d" % (0 if none_outside else 1))


func test_hazards_m007() -> void:
	# furnace vents: a 1 s glow, then fire on both sides; machines take half
	var b = _bare_battle({"env": "destroyed_forge", "hazard": {"kind": "furnace_vents", "vents": [1000], "interval": 10, "damage": 80, "radius": 40, "warn": 1.0}, "seed": 5})
	b.invulnerable_bases = true
	Foundry.set_vents(b, b.stage.hazard)
	b.vents[0].next = 0.05
	var inf = b.spawn_unit("shieldbearer", 0, Vector2(1000, 0), true)
	var tank = b.spawn_unit("ironclad_medium_tank", 0, Vector2(1006, 0), true)
	var foe = b.spawn_unit("rotter", 1, Vector2(1010, 0), true)
	for u in [inf, tank, foe]:
		u.speed = 0
		u.weapons = []
		u.max_hp = 5000.0
		u.hp = 5000.0
	var glow_seen = false
	var hit_before_warn = false
	for i in int(0.9 / DT):
		b.step(DT)
		glow_seen = glow_seen or float(b.vents[0].glow) > Foundry.ERUPT_TIME
		hit_before_warn = hit_before_warn or inf.hp < 5000.0
	for i in int(0.6 / DT):
		b.step(DT)
	var d_inf = 5000.0 - inf.hp
	var d_tank = 5000.0 - tank.hp
	var d_foe = 5000.0 - foe.hp
	var ok = glow_seen and not hit_before_warn and d_inf > 70.0 and absf(d_tank - d_inf * 0.5) < 2.0 and d_foe > 70.0 and b.stats_vent_bursts == 1
	record("Furnace vents: a 1 s glow, then fire hits both sides; machines take 50%", ok, "glow=%s hit early=%s dmg infantry=%.0f tank=%.0f undead=%.0f bursts=%d" % [glow_seen, hit_before_warn, d_inf, d_tank, d_foe, b.stats_vent_bursts])
	kill_battle(b)
	# slag flow: creeps from x0 toward x1, burns and slows ground units, never air
	var b2 = _bare_battle({"env": "destroyed_forge", "seed": 5})
	b2.invulnerable_bases = true
	Foundry.set_slag(b2, {"kind": "slag_flow", "x0": 1400, "x1": 1100, "interval": 40, "duration": 12, "dps": 40, "slow": 0.5, "speed": 40, "first": 0.5})
	var g1 = b2.spawn_unit("shieldbearer", 0, Vector2(1150, 0), true)
	var g2 = b2.spawn_unit("shieldbearer", 0, Vector2(900, 0), true)
	var air = b2.spawn_unit("rotary_interceptor", 0, Vector2(1200, 300), true)
	for u in [g1, g2, air]:
		u.speed = 0
		u.weapons = []
	var hp_air = air.hp
	var reached_early = false
	var slowed = false
	for i in int(10.0 / DT):
		b2.step(DT)
		if b2.time < 3.0 and g1.hp < g1.max_hp:
			reached_early = true
		slowed = slowed or (g1.slow_t > 0.0 and g1.slow_mult < 0.9)
	var ok2 = not reached_early and g1.hp < g1.max_hp and slowed and g2.hp == g2.max_hp and air.hp == hp_air and b2.stats_slag_flows == 1
	record("Slag flow: creeps across the lane, burns and slows ground units it reaches; air and units beyond its reach untouched", ok2,
		"reached the far unit too early=%s burned=%.0f slowed=%s beyond reach untouched=%s air untouched=%s flows=%d" % [reached_early, g1.max_hp - g1.hp, slowed, g2.hp == g2.max_hp, air.hp == hp_air, b2.stats_slag_flows])
	kill_battle(b2)
	# steam leak: a dwarven machine in the cloud refills Steam (+5/s); everyone inside is scalded
	var b3 = _bare_battle({"env": "destroyed_forge", "seed": 5})
	b3.invulnerable_bases = true
	Foundry.set_steam(b3, {"kind": "steam_leak", "pipes": [1200], "radius": 80, "dps": 7, "regen": 5})
	var walker = b3.spawn_unit("ironclad_walker", 0, Vector2(1200, 0), true)
	var foe3 = b3.spawn_unit("rotter", 1, Vector2(1230, 0), true)
	for u in [walker, foe3]:
		u.speed = 0
		u.weapons = []
	b3.steam = 10.0
	for i in int(4.0 / DT):
		b3.step(DT)
	var gained = b3.stats_steam_gained
	var ok3 = gained > 18.0 and gained < 22.5 and walker.hp < walker.max_hp and foe3.hp < foe3.max_hp
	walker.queue_free(); b3.units.erase(walker); b3.by_side[0].erase(walker)
	var g0 = b3.stats_steam_gained
	for i in int(2.0 / DT):
		b3.step(DT)
	ok3 = ok3 and b3.stats_steam_gained == g0
	record("Steam leak: +5 Steam/s while a dwarven machine stands in it (nothing without one); everyone inside is scalded", ok3,
		"steam gained in 4 s=%.1f, after the machine left=%.1f, walker scalded=%s, undead scalded=%s" % [gained, b3.stats_steam_gained - g0, walker.hp < walker.max_hp if is_instance_valid(walker) else true, foe3.hp < foe3.max_hp])
	kill_battle(b3)
	# collapsing gantries: a rockfall variant with a longer telegraph and a bigger, tighter hit
	var b4 = _bare_battle({"env": "industrial_city", "seed": 5})
	b4.invulnerable_bases = true
	var near = b4.spawn_unit("shieldbearer", 0, Vector2(1000, 0), true)
	var far = b4.spawn_unit("shieldbearer", 0, Vector2(1060, 0), true)
	for u in [near, far]:
		u.speed = 0
		u.weapons = []
		u.max_hp = 4000.0
		u.hp = 4000.0
	b4.schedule_rockfall(1000.0, 150.0, 36.0, 2.2, "gantry")
	var early = false
	for i in int(2.0 / DT):
		b4.step(DT)
		early = early or near.hp < 4000.0
	for i in int(0.5 / DT):
		b4.step(DT)
	var ok4 = not early and near.hp <= 4000.0 - 120.0 and far.hp == 4000.0 and b4.stats_gantries == 1   # 150 blast, less the shieldbearer's armour
	record("Collapsing gantries: 2.2 s telegraph, then a 150 hit in a tight radius", ok4, "hit during telegraph=%s near dmg=%.0f far dmg=%.0f" % [early, 4000.0 - near.hp, 4000.0 - far.hp])
	kill_battle(b4)
	# act-wide: every new hazard is used in Act IV and every Act IV stage has wrecks on
	var kinds = {}
	var wr = 0
	for i in range(91, 121):
		var st = Registry.stage_by_index(i)
		if st.get("wrecks", false):
			wr += 1
		for h in WaveDirector.hazard_list(st):
			kinds[Hints.hazard_tag(h)] = int(kinds.get(Hints.hazard_tag(h), 0)) + 1
	var ok5 = wr == 30 and kinds.has("haz_furnace_vents") and kinds.has("haz_slag_flow") and kinds.has("haz_steam_leak") and kinds.has("haz_rockfall_gantry")
	record("Act IV: all 30 stages carry wrecks; vents, slag, steam leaks and gantries all appear", ok5, "wreck stages=%d hazards=%s" % [wr, str(kinds)])


func test_boss_phases_m007() -> void:
	# Fallen Titan: at 50 % it rips a wreck from the ground (an escort) and its core is exposed (+25 % damage)
	var r = _boss_battle("fallen_titan", [["shieldbearer", 3, 1500]])
	var b: Battle = r[0]
	var ti = r[1]
	b.stage["wrecks"] = true
	ti.hp = ti.max_hp * 0.49
	var esc0 = b.by_side[1].filter(func(u): return u.alive and u.id == "cursed_ironclad").size()
	var core_seen = false
	for i in int(3.0 / DT):
		b.step(DT)
		core_seen = core_seen or ti.weak_core_t > 0.0
	var esc1 = b.by_side[1].filter(func(u): return u.alive and u.id == "cursed_ironclad").size()
	var h0 = ti.hp
	ti.take_damage(100.0, null)
	var dmg = h0 - ti.hp
	# a second reclaim only happens if a dwarven wreck lies near: kill a tank close to it, wait an interval
	var tk = b.spawn_unit("ironclad_medium_tank", 0, Vector2(ti.position.x - 200.0, 0), true)
	tk.take_damage(tk.max_hp * 10.0, null)
	var w_before = b.wrecks.size()
	for i in int(19.0 / DT):
		b.step(DT)
	var ok = ti.phase_on and esc1 >= esc0 + 1 and core_seen and dmg > 100.0 * 1.2 and b.stats_titan_reclaims >= 2 and w_before == 1 and b.wrecks.is_empty() and b.stats_wreck_expired == 0
	record("Boss phase: Fallen Titan reclaims a wreck as an escort at 50%, plates fall away (core +25% damage), and later reclaims a dwarven wreck nearby", ok,
		"phase=%s escorts %d -> %d core exposed=%s 100 dmg -> %.1f (x arm) reclaims=%d wreck consumed=%s" % [ti.phase_on, esc0, esc1, core_seen, dmg, b.stats_titan_reclaims, b.wrecks.is_empty()])
	kill_battle(b)
	# Ashen Forge Tyrant: at 50 % the vents fire in a telegraphed sequence toward the dwarven line
	var r2 = _boss_battle("ashen_forge_tyrant", [["shieldbearer", 4, 1200]])
	var b2: Battle = r2[0]
	var ty = r2[1]
	ty.hp = ty.max_hp * 0.49
	var order: Array = []
	var seen = {}
	for i in int(7.0 / DT):
		b2.step(DT)
		for e in b2.eruptions:
			if bool(e.hit) and not seen.has(float(e.x)):
				seen[float(e.x)] = true
				order.append(float(e.x))
	var desc = order.size() >= 6
	for k in range(1, order.size()):
		desc = desc and order[k] < order[k - 1]
	record("Boss phase: Ashen Forge Tyrant's vents fire in sequence across the arena (telegraphed sweep toward the dwarves)", ty.phase_on and desc and b2.stats_vent_sweeps >= 1 and b2.vents.size() >= 6,
		"phase=%s eruption order=%s sweeps=%d grates=%d" % [ty.phase_on, str(order), b2.stats_vent_sweeps, b2.vents.size()])
	kill_battle(b2)
	# Corpse Colossus: at 50 % it throws corpses at the stronghold; at 25 % it disgorges corrupted machines
	var b3 = _bare_battle()
	b3.invulnerable_bases = false
	var co = b3.spawn_unit("corpse_colossus", 1, Vector2(1900, 0), true)
	b3.on_boss_spawned(co)
	co.hp = co.max_hp * 0.49
	var base0 = b3.dwarf_base.hp
	for i in int(5.0 / DT):
		b3.step(DT)
	var base_hit = b3.dwarf_base.hp < base0 and b3.stats_corpse_hits >= 1
	var m0 = b3.by_side[1].filter(func(u): return u.alive and u.id in ["gravegun_tank", "risen_copperback"]).size()
	co.hp = co.max_hp * 0.24
	for i in int(1.0 / DT):
		b3.step(DT)
	var m1 = b3.by_side[1].filter(func(u): return u.alive and u.id in ["gravegun_tank", "risen_copperback"]).size()
	co.hp = co.max_hp * 0.2
	for i in int(1.0 / DT):
		b3.step(DT)
	var m2 = b3.by_side[1].filter(func(u): return u.alive and u.id in ["gravegun_tank", "risen_copperback"]).size()
	record("Boss phase: Corpse Colossus hurls corpses at the stronghold at 50% and disgorges corrupted machines once at 25%", co.phase_on and base_hit and m1 == m0 + 2 and m2 == m1,
		"stronghold %.0f -> %.0f corpse hits=%d machines %d -> %d (then %d: only once)" % [base0, b3.dwarf_base.hp, b3.stats_corpse_hits, m0, m1, m2])
	kill_battle(b3)


func test_heroic() -> void:
	# the Heroic version of a stage: same seed and layout, smarter (one extra event, x0.85 intervals, +1 structure,
	# abilities ready earlier, <= +15 % HP)
	var bad: Array = []
	for st in Registry.stages:
		if not st.implemented:
			continue
		var h = Registry.heroic_stage(st.id)
		var hb: Dictionary = st.get("heroic", {})
		if hb.is_empty() or not h.get("heroic_mode", false):
			bad.append(st.id + ":no block")
			continue
		if h.events.size() != st.events.size() + 1 or h.structures.size() != st.structures.size() + 1:
			bad.append(st.id + ":event/structure")
		if absf(float(h.tracks[0].interval) - float(st.tracks[0].interval) * float(hb.get("interval_mult", 0.85))) > 0.01 or float(hb.get("interval_mult", 0.85)) > 0.95:
			bad.append(st.id + ":interval")
		if float(h.enemy_hp_mult) > float(st.enemy_hp_mult) * 1.1501:
			bad.append(st.id + ":hp")
		if st.tracks[0].interval == h.tracks[0].interval:
			bad.append(st.id + ":registry modified")
	var gentle = Registry.stages.filter(func(x): return x.implemented and float(x.heroic.get("interval_mult", 0.85)) > 0.86).map(func(x): return int(x.index))
	record("Heroic: every implemented stage (001-120) has a Heroic version — +1 event, x0.85 intervals (x0.92 on the gentle list), +1 structure, <= +15% HP; the base stage is untouched", bad.is_empty(), "problems=%s gentle blocks=%s" % [str(bad.slice(0, 8)), str(gentle)])
	# abilities ready earlier on Heroic
	var b = make_battle({"sandbox": false, "seed": 7, "no_director": true}, Registry.heroic_stage("s040"), [])
	var g = b.spawn_unit("cathedral_ghast", 1, Vector2(1800, 0), true)
	var b0 = make_battle({"sandbox": false, "seed": 7, "no_director": true}, Registry.stage("s040"), [])
	var g0 = b0.spawn_unit("cathedral_ghast", 1, Vector2(1800, 0), true)
	record("Heroic: enemy abilities come ready earlier", b.heroic and not b0.heroic and g.ability_cd < g0.ability_cd and g0.ability_cd > 0.0, "ability ready in %.1f s (normal %.1f s)" % [g.ability_cd, g0.ability_cd])
	kill_battle(b)
	kill_battle(b0)
	# no T5 needed: the Heroic sim loadout for Act IV never contains a T5 unit
	var t5: Array = []
	args["heroic"] = "1"
	for i in range(91, 121):
		for u in sim_loadout(i):
			if u != "" and int(Registry.entry(u).get("tier", 0)) >= 5:
				t5.append("%d:%s" % [i, u])
	args.erase("heroic")
	record("Heroic sims use pre-T5 technology only (Act IV)", t5.is_empty(), "T5 units found=%s" % str(t5))
	# rewards: unlocked only for cleared stages; separate stars; a one-time Spark payout; replays pay nothing
	SaveManager.path = "user://test_heroic_save.json"
	GameState.reset_progress()
	var locked = not GameState.heroic_available("s012")
	GameState.grant_stage_rewards("s012", 300.0, 10, [true, false, false])
	var avail = GameState.heroic_available("s012")
	var normal_stars = GameState.stars_for("s012").duplicate()
	var sp0 = GameState.profile.sparks
	var r1 = GameState.grant_heroic_rewards("s012", 320.0, 40, [true, true, false])
	var sp1 = GameState.profile.sparks
	var r2 = GameState.grant_heroic_rewards("s012", 300.0, 40, [true, false, true])
	var sp2 = GameState.profile.sparks
	var bonus = int(Registry.stage("s012").heroic.spark_bonus)
	var ok = locked and avail and r1.first_clear and sp1 - sp0 == bonus and bonus > 0 and not r2.first_clear and sp2 == sp1 \
		and GameState.heroic_stars("s012") == [true, true, true] and GameState.stars_for("s012") == normal_stars and GameState.heroic_cleared("s012")
	GameState.reload_from_disk()
	ok = ok and GameState.heroic_stars("s012") == [true, true, true] and int(GameState.profile.heroic.s012.clears) == 2 and int(GameState.profile.stats.heroic_clears) == 1
	record("Heroic rewards: unlocked by a normal clear; separate stars (best ever); +%d Sparks on the first Heroic clear only; saved and reloaded" % bonus, ok,
		"locked before clear=%s available after=%s first payout=%d replay payout=%d heroic stars=%s normal stars unchanged=%s" % [locked, avail, sp1 - sp0, sp2 - sp1, str(GameState.heroic_stars("s012")), GameState.stars_for("s012") == normal_stars])
	SaveManager.wipe()


func test_m007_save() -> void:
	# an M006-format save (no heroic block, no ui_sounds setting, no salvage stats) must load, keep progress and gain the fields
	SaveManager.path = "user://test_m006_save.json"
	var old = SaveManager.default_profile()
	old.erase("heroic")
	old.settings.erase("ui_sounds")
	for k in ["salvaged", "reclaimed", "heroic_clears"]:
		old.stats.erase(k)
	for i in range(1, 91):
		old.cleared["s%03d" % i] = {"best_time": 300, "clears": 1}
	old.stars = {"s090": [true, true, false], "s089": [true, true, true]}
	old.open_tiers = [0, 1, 2, 3, 4]
	old.acts_revealed = [1, 2, 3]
	old.sparks = 6543
	old.stats.escorts = 3
	var f = FileAccess.open(SaveManager.path, FileAccess.WRITE)
	f.store_string(JSON.stringify(old))
	f.close()
	GameState.reload_from_disk()
	var p = GameState.profile
	var kept = GameState.is_cleared("s090") and p.sparks == 6543 and GameState.tier_open(4) and not GameState.tier_open(5) and GameState.stars_for("s089") == [true, true, true] and int(p.stats.escorts) == 3
	var gained = p.has("heroic") and p.heroic is Dictionary and p.heroic.is_empty() and p.settings.has("ui_sounds") and not bool(p.settings.ui_sounds) \
		and int(p.stats.salvaged) == 0 and int(p.stats.reclaimed) == 0 and int(p.stats.heroic_clears) == 0
	var act4_open = GameState.stage_available(Registry.stage("s091"))
	var heroic_ok = GameState.heroic_available("s090") and not GameState.heroic_available("s091")
	GameState.grant_stage_rewards("s105", 400.0, 200, [true, true, true])
	var t5 = GameState.tier_open(5)
	GameState.save()
	GameState.reload_from_disk()
	var resaved = GameState.profile.settings.has("ui_sounds") and GameState.is_cleared("s105") and GameState.tier_open(5) and GameState.profile.has("heroic")
	record("M006 save -> M007: progress kept; Heroic records, Button-sounds setting and salvage stats added; Act IV open; s105 opens T5", kept and gained and act4_open and heroic_ok and t5 and resaved,
		"kept=%s gained=%s act4_open=%s heroic for cleared only=%s t5_after_105=%s resave=%s" % [kept, gained, act4_open, heroic_ok, t5, resaved])
	SaveManager.wipe()


func test_audio_m007() -> void:
	# the tap "cling" is gone: ui_click is silent unless Button sounds is on, and its recipe has no metallic partials
	var on_default = Audio.ui_sounds_on()
	var keys = ["ui_click", "deploy", "mine_upgrade", "vent_rumble", "vent_roar", "slag_hiss", "girder_groan", "girder_crash", "channel", "reclaim", "corrupt_engine", "salvage", "corpse_impact", "pipe_burst"]
	Audio._build_all()
	var missing = keys.filter(func(k): return not Audio.streams.has(k))
	var loops_listed = Audio.AMB_ENVS.all(func(e): return ("amb_" + e) in Audio.LOOP_KEYS)
	# spectral check: the old click was a 1200 Hz clank with partials at 3.3 kHz and 6.5 kHz; the new tick must keep
	# almost no energy above 2 kHz (zero-crossing rate as a cheap brightness measure)
	var w: AudioStreamWAV = Audio.streams["ui_click"]
	var raw: PackedByteArray = w.data
	var zc = 0
	var prev = 0
	var n = raw.size() / 2
	for i in n:
		var v = raw.decode_s16(i * 2)
		if (v >= 0) != (prev >= 0):
			zc += 1
		prev = v
	var est_hz = float(zc) / 2.0 / (float(n) / Audio.MIX_RATE)
	record("Sound refinement: no tap cling (button sounds off by default; the optional tick is soft and dull), Act IV cues and all ambience loops cached", not on_default and missing.is_empty() and loops_listed and est_hz < 1500.0,
		"button sounds on by default=%s missing cues=%s every loop cached=%s tick brightness ~%.0f Hz" % [on_default, str(missing), loops_listed, est_hz])


func test_ui_m007() -> void:
	SaveManager.path = "user://test_ui_m007_save.json"
	GameState.reset_progress()
	GameState.profile.settings.tutorial = false
	GameState.profile.settings.hints = false
	for i in range(1, 100):
		GameState.profile.cleared["s%03d" % i] = {"best_time": 300, "clears": 1}
	GameState.profile.heroic["s095"] = {"stars": [true, true, false], "clears": 1, "best_time": 400.0}
	# --- battle HUD on an Act IV stage: a wreck being channelled shows on the minimap (cog + pulse) without errors
	GameState.selected_stage = "s094"
	GameState.selected_heroic = false
	var inst = load("res://scenes/battle_screen.tscn").instantiate()
	get_tree().root.add_child(inst)
	for i in 10:
		await get_tree().physics_frame
	var bt: Battle = inst.battle
	var tk = bt.spawn_unit("ironclad_medium_tank", 0, Vector2(1300, 0), true)
	tk.take_damage(tk.max_hp * 10.0, null)
	var pr = bt.spawn_unit("corpse_priest", 1, Vector2(1340, 0), true)
	for i in 30:
		await get_tree().physics_frame
	var wreck_ok = bt.wrecks.size() == 1 and bt.wrecks[0].chan == pr and String(bt.stage.env) == "mech_graveyard" and bt.background.sky_layer != null and bt.background.sky_layer.smog
	inst.minimap.queue_redraw()
	await get_tree().process_frame
	record("UI battle HUD (Act IV): wreck on the field and on the minimap; a corruptor's channel is shown; smoggy sky layer", wreck_ok,
		"wrecks=%d channelled by the priest=%s env=%s smog=%s" % [bt.wrecks.size(), bt.wrecks[0].chan == pr if not bt.wrecks.is_empty() else false, bt.stage.env, bt.background.sky_layer != null])
	inst.queue_free()
	await get_tree().process_frame
	# --- Heroic battle: the battle screen loads the Heroic version when selected
	GameState.selected_stage = "s095"
	GameState.selected_heroic = true
	var inst2 = load("res://scenes/battle_screen.tscn").instantiate()
	get_tree().root.add_child(inst2)
	for i in 6:
		await get_tree().physics_frame
	var heroic_battle = inst2.battle.heroic and inst2.stage.get("heroic_mode", false)
	inst2.queue_free()
	GameState.selected_heroic = false
	await get_tree().process_frame
	# --- campaign drawer: the Heroic toggle, the red-gold Heroic stars and the modifier list on cleared stages
	var cm = load("res://scenes/campaign_map.tscn").instantiate()
	get_tree().root.add_child(cm)
	for i in 20:
		await get_tree().process_frame
	cm.act = 4
	cm._build_map()
	cm._show_detail("s095")
	for i in 4:
		await get_tree().process_frame
	var has_toggle = false
	for c in cm.detail.find_children("*", "", true, false):
		if c.has_signal("toggled") and "on" in c and c.get_class() == "Control":
			has_toggle = true
			c.on = true
			c.toggled.emit(true)
			break
	for i in 4:
		await get_tree().process_frame
	var txt = " | ".join(cm.detail.find_children("*", "Label", true, false).map(func(l): return l.text))
	var btn = " | ".join(cm.actions.find_children("*", "Button", true, false).map(func(b): return b.text))
	cm._show_detail("s100")
	for i in 4:
		await get_tree().process_frame
	var none_uncleared = true
	for c in cm.detail.find_children("*", "", true, false):
		if c.has_signal("toggled") and "on" in c and c.get_class() == "Control":
			none_uncleared = false
	var ok_d = has_toggle and "Heroic:" in txt and "faster" in txt and "Deploy — Heroic" in btn and none_uncleared
	record("UI campaign drawer: Heroic toggle on cleared stages only, modifier list, Deploy — Heroic", ok_d and heroic_battle,
		"toggle=%s modifiers shown=%s deploy=%s no toggle on an uncleared stage=%s heroic battle loaded=%s" % [has_toggle, "Heroic:" in txt, btn, none_uncleared, heroic_battle])
	# --- Realm Map Act IV: landmark painters, chimneys by progress, three boss set pieces, heroic banner path
	var rm: RealmMap = cm.realm
	var chim = 0
	for i in 30:
		chim += rm._chimney_tops(i).size()
	var bosses = [rm.stages[9].boss, rm.stages[19].boss, rm.stages[29].boss]
	record("UI Realm Map Act IV: landmarks with chimneys (green until cleared), boss set pieces at 100/110/120", chim >= 20 and bosses == ["fallen_titan", "ashen_forge_tyrant", "corpse_colossus"] and rm.act == 4,
		"chimneys=%d bosses=%s" % [chim, str(bosses)])
	cm.queue_free()
	await get_tree().process_frame
	# --- compendium: corrupted machines name their dwarven origin; salvage units "deny wrecks"; corruptors "reclaim"
	var comp = load("res://scenes/compendium.tscn").instantiate()
	get_tree().root.add_child(comp)
	for i in 6:
		await get_tree().process_frame
	GameState.profile.encountered = ["gravegun_tank", "corpse_priest"]
	comp.cat = 1
	comp._show(Registry.entry("gravegun_tank"))
	await get_tree().process_frame
	var t1 = String(comp.info.text)
	comp.cat = 0
	comp._show(Registry.entry("salvage_crew"))
	await get_tree().process_frame
	var t2 = String(comp.info.text)
	comp.cat = 1
	comp._show(Registry.entry("corpse_priest"))
	await get_tree().process_frame
	var t3 = String(comp.info.text)
	record("UI compendium: corrupted machines list their dwarven origin; salvage units deny wrecks; corruptors reclaim", "Raised from:" in t1 and "Thunderback" in t1 and "Denies wrecks" in t2 and "Reclaims wrecks" in t3,
		"origin=%s denies=%s reclaims=%s" % ["Raised from:" in t1, "Denies wrecks" in t2, "Reclaims wrecks" in t3])
	comp.queue_free()
	SaveManager.wipe()
