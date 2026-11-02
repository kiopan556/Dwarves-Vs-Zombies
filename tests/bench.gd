extends Node
## Performance benchmark (logic + draw cost of a crowded battle on screen).
##   godot --headless --path . res://tests/bench.tscn -- --frames=300 [--quality=low]
## Drives the battle manually (one logic step per rendered frame) so results are comparable.

var args = {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv = a.substr(2).split("=")
			args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	Audio.enabled = false
	SaveManager.path = "user://bench_save.json"
	GameState.reset_progress()
	GameState.profile.settings.quality = args.get("quality", "high")
	GameState.apply_settings()
	Engine.max_fps = 0
	if args.has("scene"):
		var sc = load("res://scenes/%s.tscn" % args.scene).instantiate()
		get_tree().root.add_child.call_deferred(sc)
		for i in 60:
			await get_tree().process_frame
		var t0 = Time.get_ticks_usec()
		var n = 120
		for i in n:
			await get_tree().process_frame
		print("SCENE %s frame %.2f ms draw_calls=%d objects=%d" % [args.scene, (Time.get_ticks_usec() - t0) / 1000.0 / n, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)])
		if args.has("layers"):
			# M008: draw calls saved by hiding each subtree (3 levels deep) - where a screen's budget goes
			var all_dc = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
			var stack: Array = [[sc, 0]]
			while not stack.is_empty():
				var it = stack.pop_back()
				var nd = it[0]
				if nd is CanvasItem and nd.visible and nd != sc:
					nd.visible = false
					await get_tree().process_frame
					await get_tree().process_frame
					var saved = all_dc - Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
					nd.visible = true
					if saved >= 40:
						print("SUBTREE %s%s (%s) saves %d of %d" % ["  ".repeat(int(it[1])), nd.name, nd.get_class(), saved, all_dc])
				if int(it[1]) < 4:
					for c in nd.get_children():
						stack.append([c, int(it[1]) + 1])
		get_tree().quit()
		return
	if args.has("stage"):
		await _bench_stage()
		return
	var inst = load("res://scenes/sandbox.tscn").instantiate()
	get_tree().root.add_child.call_deferred(inst)
	await get_tree().process_frame
	await get_tree().process_frame
	inst.set_physics_process(false)
	inst.set_process(false)
	var b: Battle = inst.battle
	b.invulnerable_bases = true if "invulnerable_bases" in b else false
	var rng = RandomNumberGenerator.new()
	rng.seed = 7
	var dw = ["ironhold_rifleman", "shieldbearer", "grenadier", "light_field_cannon", "copperback_light_tank", "ironclad_walker", "anvilbreaker", "deepforge_titan", "flak_crew", "boiler_stomper"]
	var un = ["rotter", "ossuary_skeleton", "grave_knight", "bone_archer", "flesh_hulk", "necromancer", "rot_spitter", "plague_runner"]
	if args.get("mix", "") == "m003":
		# M003 roster crowd: many distinct new arts at once (worst case for the pose cache)
		dw = ["steamgunner", "trench_guard", "flame_trooper", "steam_mortar", "ironclad_medium_tank", "flamebelcher_medium_tank", "repair_wagon", "twin_flak_mount",
			"veteran_rifleman", "heavy_hammerer", "rocket_battery", "ironrunner_light_tank", "skyshield_aa_tank", "shrapnel_howitzer", "armor_piercer", "bombardier"]
		un = ["shambler", "bone_pikeman", "grave_slinger", "rot_hound", "fungal_host", "ossuary_axeman", "blight_marauder", "rusted_legionary",
			"rotting_berserker", "hollow_guard", "grave_warden", "plague_mauler", "crypt_hexer", "bone_lancer", "tomb_stalker", "pestilent_soldier"]
	if args.get("mix", "") == "act2":
		# M005 Act II crowd: the act's undead (incl. giants and corrupted machines) in a hazard stage
		dw = ["trench_guard", "rune_cartridge_rifleman", "flamebelcher_medium_tank", "heavy_bombard", "ironclad_medium_tank", "twin_flak_mount",
			"repair_wagon", "steamgunner", "thunderback_heavy_tank", "skyshield_aa_tank", "veteran_rifleman", "siege_howitzer"]
		un = ["shambler", "fungal_host", "blight_marauder", "pestilent_soldier", "carcass_devourer", "rotting_berserker", "black_rot_infantry",
			"plague_sprayer", "rot_channeler", "plague_herald", "rot_hound", "grave_spider", "oozing_horror", "stitchback_giant", "risen_copperback"]
	var air_peak = args.get("mix", "") == "airpeak"
	if air_peak:
		# M006 Act III worst case: 24 undead flyers (the air budget) + ~60 ground units + dwarven airships
		dw = ["rolling_shield_trooper", "incendiary_grenadier", "twin_cannon_ironclad", "piston_cannon", "mobile_flak_fortress", "skyguard_walker",
			"armored_recovery_team", "cannon_strider", "sniper_tank_hunter", "heavy_skybreaker"]
		un = ["rusted_legionary", "bone_vanguard", "crypt_halberdier", "hollow_guard", "night_seer", "funeral_bell_keeper", "ossuary_juggernaut", "grave_warden"]
	var machines = args.get("mix", "") == "machines"
	if machines:
		# M006b: tank-, war-frame- and airship-heavy battle (the overhauled machine art at its densest)
		dw = ["ironclad_medium_tank", "thunderback_heavy_tank", "bastion_heavy_tank", "mobile_flak_fortress", "brass_leviathan", "ironrunner_light_tank",
			"cannon_strider", "ironclad_walker", "anvilbreaker", "deepforge_titan", "dreadnought_landship", "siegecrawler"]
	if args.has("env"):
		b.background.env = String(args.env)
		b.background.queue_redraw()
	if args.has("hazards"):
		b.set_bog({"spots": [700.0, 1150.0], "width": 170.0, "slow": 0.4})
		for k in 3:
			b.add_miasma(600.0 + k * 220.0, 100.0, 1.0, 9999.0, 0.0)
	for i in int(args.get("dwarves", "40")):
		b.spawn_unit(dw[i % dw.size()], 0, Vector2(380 + rng.randf() * 360, 0), true)
	var dair = ["dwarven_flying_machine", "ironwing_gunship"] if not air_peak else ["heavy_interceptor", "thunderwing", "flak_chaser", "skyshield_airship", "ironcloud", "forgewatch_frigate"]
	if machines:
		dair = ["skyforge_dreadnought", "heavy_gyro_bomber", "rocketwing", "mountain_ark", "twin_flame_gunship", "thunderbarge"]
	for i in 6:
		b.spawn_unit(dair[i % dair.size()], 0, Vector2(400 + i * 40, 300 if i < 3 or not air_peak else 180), true)
	for i in int(args.get("undead", "80")):
		b.spawn_unit(un[i % un.size()], 1, Vector2(820 + rng.randf() * 500, 0), true)
	var fl = ["carrion_bat", "plague_shrieker"] if args.get("mix", "") != "act2" else ["blight_bat", "plague_harpy", "haunted_flying_machine", "rotwing"]
	if air_peak:
		fl = ["gravewing_stalker", "ossuary_flier", "tomb_gargoyle", "banshee_wing", "bone_wyvern", "bone_drake", "wraith_swarm", "necrotic_sky_serpent", "infected_airbarge", "haunted_flying_machine"]
		b.set_thermals({"columns": [[700, 1], [1000, -1]], "width": 120})
	for i in (14 if not air_peak else 24):
		b.spawn_unit(fl[i % fl.size()], 1, Vector2(900 + i * 25, 280), true)
	for u in b.units:
		if not u.is_stronghold:
			u.max_hp *= 6.0
			u.hp = u.max_hp
	inst.cam.position.x = 520.0
	if "panel" in inst and inst.panel != null:
		inst.panel.visible = false   # dev panel is sandbox-only; measure what a real battle shows
	var frames = int(args.get("frames", "300"))
	var dt = 1.0 / 30.0
	var logic_us = 0
	Unit.draw_usec = 0
	Unit.draw_calls = 0
	# warm-up (lets the pose cache fill, as it would in the first seconds of a battle)
	for i in int(args.get("warm", "20")):
		b.step(dt)
		await get_tree().process_frame
	Unit.draw_usec = 0
	Unit.draw_calls = 0
	for k in PoseCache.stats:
		PoseCache.stats[k] = 0
	PoseCache.debug_track = args.has("track")
	b.profiling = true
	var t_start = Time.get_ticks_usec()
	for i in frames:
		var t0 = Time.get_ticks_usec()
		b.step(dt)
		logic_us += Time.get_ticks_usec() - t0
		await get_tree().process_frame
	var total = Time.get_ticks_usec() - t_start
	if args.has("layers"):
		var cfgs = {"all": [], "no_fx": [b.fx], "no_proj": [b.projectiles], "no_units": b.units, "no_hud": [inst.hud], "no_bg": [b.background]}
		for nm in cfgs:
			var hidden: Array = []
			for n in cfgs[nm]:
				if n != null and n is CanvasItem:
					n.visible = false
					hidden.append(n)
				elif n != null and n.has_method("hide"):
					n.hide()
					hidden.append(n)
			await get_tree().process_frame
			await get_tree().process_frame
			print("LAYER %s draw_calls=%d" % [nm, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])
			for n in hidden:
				n.visible = true
		var base = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		var stack: Array = [inst.hud]
		var items: Array = []
		while not stack.is_empty():
			var n = stack.pop_back()
			for c in n.get_children():
				if c is CanvasItem and c.visible:
					items.append(c)
					if c.get_child_count() > 0 and items.size() < 400:
						stack.append(c)
		var res: Array = []
		for c in items:
			c.visible = false
			await get_tree().process_frame
			await get_tree().process_frame
			var dc = base - Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
			c.visible = true
			if dc >= 3:
				res.append([dc, "%s(%s)" % [c.name, c.get_class()]])
		res.sort_custom(func(x, y): return x[0] > y[0])
		for r in res.slice(0, 25):
			print("HUDITEM %d %s" % r)
	print("RENDER draw_calls=%d objects=%d primitives=%d" % [Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
	var alive = b.units.filter(func(u): return u.alive).size()
	var per_art = {}
	var px_sum = 0.0
	for k in PoseCache.entries:
		var e = PoseCache.entries[k]
		per_art[e.art] = per_art.get(e.art, 0) + 1
		px_sum += e.src.size.x * e.src.size.y
	if PoseCache.debug_track:
		print("LIVE per_art=%s" % str(PoseCache.live_by_art))
	print("CACHE per_art=%s avg_cell_px=%.0f" % [str(per_art), px_sum / maxf(1, PoseCache.entries.size())])
	var sc = {}
	for u in b.units:
		if u.alive:
			sc[u.art] = PoseCache.screen_scale(u)
	print("SCALES %s" % str(sc))
	if args.has("track"):
		for a in PoseCache.debug_seen:
			var ps: Dictionary = PoseCache.debug_seen[a]
			var varying = {}
			var first = ps.values()[0]
			for p in ps.values():
				for k in p:
					if p[k] != first[k]:
						var vs: Dictionary = varying.get(k, {})
						vs[p[k]] = 1
						varying[k] = vs
			var summary = {}
			for k in varying:
				summary[k] = varying[k].size() + 1
			print("POSES %s %d %s" % [a, ps.size(), str(summary)])
	print("CACHE %s entries=%d pages=%d" % [str(PoseCache.stats), PoseCache.entries.size(), PoseCache.pages.size()])
	var pr = {}
	for k in b.prof:
		pr[k] = "%.2f" % (b.prof[k] / 1000.0 / frames)
	print("PROF ms/step %s" % str(pr))
	print("BENCH quality=%s frames=%d units_alive=%d | frame %.2f ms | logic %.2f ms | unit _draw %.2f ms (%d draws/frame) | other %.2f ms" % [
		args.get("quality", "high"), frames, alive, total / 1000.0 / frames, logic_us / 1000.0 / frames,
		Unit.draw_usec / 1000.0 / frames, Unit.draw_calls / frames, (total - logic_us - Unit.draw_usec) / 1000.0 / frames])
	get_tree().quit()



## M005: measure a real campaign stage at its peak. Plays the stage with the auto-commander (Act II
## loadout) until --ff seconds, puts the camera on the busiest stretch of the front, then measures.
func _bench_stage() -> void:
	var i = int(args.stage)
	GameState.profile.settings.tutorial = false
	GameState.profile.settings.hints = false
	GameState.selected_stage = "s%03d" % i
	var tr = load("res://tests/test_runner.gd").new()
	var lo = tr.loadout_for_stage(i)
	tr.free()
	GameState.profile.loadouts["Preset I"] = lo
	var inst = load("res://scenes/battle_screen.tscn").instantiate()
	get_tree().root.add_child.call_deferred(inst)
	await get_tree().process_frame
	await get_tree().process_frame
	inst.set_physics_process(false)
	var b: Battle = inst.battle
	var ai = AutoCommander.new()
	ai.generic = i > 30
	var dt = 1.0 / 30.0
	var peak = 0
	while b.time < float(args.get("ff", "240")) and not b.over:
		if inst.intro_active:
			inst._end_intro()
		ai.step(b, dt)
		b.step(dt)
		peak = maxi(peak, b.alive_count(0) + b.alive_count(1))
	# camera on the densest 1280 px of the field
	var best_x = 640.0
	var best_n = -1
	for cx in range(640, int(Combat.WORLD_W) - 600, 80):
		var n = 0
		for u in b.units:
			if u.alive and absf(u.position.x - cx) < 640.0:
				n += 1
		if n > best_n:
			best_n = n
			best_x = cx
	inst.cam.position.x = best_x
	inst._update_camera(dt)
	for k in 30:
		ai.step(b, dt)
		b.step(dt)
		await get_tree().process_frame
	var frames = int(args.get("frames", "120"))
	var logic_us = 0
	var dc_max = 0
	var dc_sum = 0
	var t_start = Time.get_ticks_usec()
	for k in frames:
		var t0 = Time.get_ticks_usec()
		ai.step(b, dt)
		b.step(dt)
		logic_us += Time.get_ticks_usec() - t0
		inst._update_camera(dt)
		await get_tree().process_frame
		var dc = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		dc_max = maxi(dc_max, dc)
		dc_sum += dc
	var total = Time.get_ticks_usec() - t_start
	print("STAGEBENCH s%03d t=%.0fs units_on_screen=%d alive_now=%d peak_alive=%d | frame %.2f ms | logic %.2f ms | draw calls avg %d max %d" % [i, b.time, best_n,
		b.alive_count(0) + b.alive_count(1), peak, total / 1000.0 / frames, logic_us / 1000.0 / frames, dc_sum / frames, dc_max])
	if args.has("layers"):
		# M008: draw calls with each battle layer hidden in turn (where the budget goes on a real stage)
		await get_tree().process_frame
		var all_dc = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		var cands: Array = b.get_children() + [inst.hud]
		for n in cands:
			if not (n is CanvasItem) or not n.visible:
				continue
			n.visible = false
			await get_tree().process_frame
			await get_tree().process_frame
			print("LAYER -%s (%s) saves %d of %d" % [n.name, n.get_class(), all_dc - Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), all_dc])
			n.visible = true
	get_tree().quit()
