extends Node
## Visual check tool (needs a display, e.g. xvfb-run). Renders a screen, optionally fast-forwards
## a battle with the auto-commander, and saves a PNG.
##   godot --path . res://tests/screenshot.tscn -- --shot=battle --stage=5 --ff=60 --cam=900 --out=/tmp/x.png

var args = {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv = a.substr(2).split("=")
			args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	Audio.enabled = false
	SaveManager.path = "user://shot_save.json"
	GameState.reset_progress()
	if args.has("quality"):
		GameState.profile.settings.quality = args.quality
		GameState.apply_settings()
	for e in Registry.implemented_dwarves():
		GameState.unlock_unit(e.id)
	GameState.profile.encountered = Registry.implemented_undead().map(func(e): return e.id)
	if args.has("stage_loadout"):
		pass
	GameState.profile.loadouts["Preset I"] = ["shieldbearer", "ironhold_rifleman", "grenadier", "light_field_cannon", "flak_crew", "copperback_light_tank", "boiler_stomper", "dwarven_flying_machine", "bombard_gyro", "ironwing_gunship", "ironcloud", "miner_rig"]
	for i in int(args.get("cleared", "0")):
		GameState.profile.cleared["s%03d" % (i + 1)] = {"best_time": 200, "clears": 1}
	if args.has("revealed"):
		GameState.profile.acts_revealed = [1, 2, 3, 4, 5]
	if args.has("heroic_cleared"):
		for x in String(args.heroic_cleared).split(","):
			GameState.profile.heroic["s%03d" % int(x)] = {"stars": [true, true, true], "clears": 1, "best_time": 300.0}
	var shot: String = args.get("shot", "main_menu")
	var inst
	match shot:
		"kit":
			inst = Node2D.new()
			var bgk = ColorRect.new()
			bgk.color = Color("5d6470")
			bgk.size = Vector2(1280, 720)
			inst.add_child(bgk)
			var keys: Array = []
			for e in Registry.dwarves + Registry.undead + Registry.bosses:
				if ArtKit.has(String(e.id)):
					keys.append(String(e.id))
			var pg = int(args.get("page", "0"))
			var per = 24
			for k in per:
				var idx = pg * per + k
				if idx >= keys.size():
					break
				var aid: String = keys[idx]
				var hh = Painter.art_height(aid)
				var air = Painter.is_air_art(aid)
				var sc = minf(1.6, 150.0 / hh)
				var cx = 80 + (k % 8) * 160
				var cy = 200 + (k / 8) * 235
				var spk = Widgets.ArtSprite.new(aid, Vector2(cx, cy - (hh * sc * 0.5 if air else 0.0)), sc, false)
				spk.anim.state = args.get("state", "idle")
				spk.anim.atk = float(args.get("atk", "0"))
				spk.anim.walk = 1.1
				inst.add_child(spk)
				var lbk = Label.new()
				lbk.text = Registry.entry(aid).name
				lbk.add_theme_font_size_override("font_size", 12)
				lbk.position = Vector2(cx - 70, cy + 6)
				inst.add_child(lbk)
		"anim":
			# M004 clip: a firing line rendered frame by frame (frames saved by the loop below)
			inst = Node2D.new()
			var bga = ColorRect.new()
			bga.color = Color("5f6878")
			bga.size = Vector2(1280, 720)
			inst.add_child(bga)
			var gr = ColorRect.new()
			gr.color = Color("4a4034")
			gr.position = Vector2(0, 540)
			gr.size = Vector2(1280, 180)
			inst.add_child(gr)
			var cast = String(args.get("arts", "rifleman,blunderbussier,grenadier,field_cannon,militia,cannon_strider")).split(",")
			var xs = [110, 300, 470, 650, 860, 1080]
			for k in cast.size():
				var aid2: String = cast[k]
				var sc2 = minf(2.4, 210.0 / Painter.art_height(aid2))
				var u2 = Widgets.ArtSprite.new(aid2, Vector2(xs[k % xs.size()], 540), sc2, false)
				u2.set_process(false)
				u2.set_meta("phase", k * 0.37)
				u2.set_meta("period", 1.6 + (k % 3) * 0.25)
				inst.add_child(u2)
		"gags":
			# M004 filmstrip: each row is one unit, columns step through the post-shot gag timeline
			inst = Node2D.new()
			var bgs = ColorRect.new()
			bgs.color = Color("6d7480")
			bgs.size = Vector2(1280, 720)
			inst.add_child(bgs)
			var rows: Array = String(args.get("arts", "rifleman,blunderbussier,militia,grenadier,field_cannon,steamgunner")).split(",")
			var cols = 9
			for r in rows.size():
				var aid: String = rows[r]
				var hh = Painter.art_height(aid)
				var sc = minf(1.7, 92.0 / hh)
				for c in cols:
					var gg = 1.0 - c / float(cols - 1)
					var tau = 1.0 - gg
					var spk = Widgets.ArtSprite.new(aid, Vector2(80 + c * 140, 110 + r * 112), sc, false)
					spk.set_process(false)
					spk.anim.gag = gg if c > 0 or args.has("include_rest") else 1.0
					spk.anim.atk = maxf(0.0, 1.0 - 1.76 * tau)
					spk.anim.atk2 = spk.anim.atk
					spk.anim.recoil = spk.anim.atk
					spk.anim.state = args.get("state", "idle")
					spk.anim.t = float(args.get("t", "0.4"))
					spk.anim.hurt = float(args.get("hurt", "0"))
					spk.anim.walk = c * TAU / 8.0
					inst.add_child(spk)
		"giants":
			inst = Node2D.new()
			var bgg = ColorRect.new()
			bgg.color = Color("5d6470")
			bgg.size = Vector2(1280, 720)
			inst.add_child(bgg)
			var gids = ["carrion_bull", "bone_golem", "plague_beast", "stitchback_giant", "ossuary_juggernaut", "corpse_mound",
				"ghoul_matriarch", "cathedral_ghast", "blackroot_abomination", "walking_crypt", "plague_colossus", "rift_maw"]
			for k in 12:
				var spg = Widgets.ArtSprite.new(gids[k], Vector2(105 + (k % 6) * 210, 330 + (k / 6) * 340), 2.4, false)
				spg.anim.state = args.get("state", "idle")
				spg.anim.atk = float(args.get("atk", "0"))
				spg.anim.atk2 = float(args.get("atk", "0"))
				spg.anim.windup = float(args.get("windup", "0"))
				spg.anim.ability_anim = float(args.get("abil", "0"))
				spg.anim.hp_frac = float(args.get("hp", "1"))
				spg.anim.walk = 1.1
				inst.add_child(spg)
				var lbg = Label.new()
				lbg.text = Registry.entry(gids[k]).name
				lbg.position = Vector2(30 + (k % 6) * 210, 340 + (k / 6) * 340)
				inst.add_child(lbg)
		"mechs", "mech_scale":
			inst = Node2D.new()
			var bg2 = ColorRect.new()
			bg2.color = Color("5d6470")
			bg2.size = Vector2(1280, 720)
			inst.add_child(bg2)
			var mids = ["miner_rig", "boiler_stomper", "drillwalker", "steam_loader", "piston_brawler", "copper_sentinel", "ironclad_walker",
				"skyguard_walker", "thundercoil_frame", "cannon_strider", "shieldframe", "claw_harvester", "mortar_walker", "furnace_stalker",
				"anvilbreaker", "siegebellow", "furnace_guardian", "siege_hammer_walker", "flak_colossus", "thunderstep_bruiser", "shredder_walker",
				"riftshield_walker", "deepforge_titan", "mountain_colossus", "kings_anvil", "colossal_skybreaker", "hammerfall_goliath", "embercore_titan"]
			if shot == "mechs":
				var page = int(args.get("page", "0"))
				for k in 14:
					var idx = page * 14 + k
					var sp2 = Widgets.ArtSprite.new(mids[idx], Vector2(95 + (k % 7) * 180, 330 + (k / 7) * 340), 2.2, false)
					sp2.anim.state = args.get("state", "idle")
					sp2.anim.atk = float(args.get("atk", "0"))
					sp2.anim.atk2 = float(args.get("atk", "0"))
					sp2.anim.windup = float(args.get("windup", "0"))
					sp2.anim.engage = 1.0
					sp2.anim.walk = 1.1
					sp2.anim.aim0 = 0.0 if not mids[idx] in ["skyguard_walker", "flak_colossus", "colossal_skybreaker"] else -1.0
					sp2.anim.aim1 = -1.0
					sp2.anim.aim2 = -1.2
					inst.add_child(sp2)
					var lb = Label.new()
					lb.text = Registry.entry(mids[idx]).name
					lb.position = Vector2(20 + (k % 7) * 180, 340 + (k / 7) * 340)
					inst.add_child(lb)
			else:
				var x0 = 60.0
				var line = [["rifleman", 1.0], ["miner_rig", 0.0], ["drillwalker", 0.0], ["ironclad_walker", 0.0], ["cannon_strider", 0.0], ["anvilbreaker", 0.0], ["shredder_walker", 0.0], ["deepforge_titan", 0.0], ["kings_anvil", 0.0]]
				for it in line:
					var sc = float(it[1]) if it[1] > 0.0 else float(Registry.combat_def(it[0]).art_scale)
					var sp3 = Widgets.ArtSprite.new(it[0], Vector2(x0, 640), sc, false)
					sp3.anim.engage = 1.0
					inst.add_child(sp3)
					x0 += 40.0 + sc * 55.0
		"gallery":
			inst = Node2D.new()
			var bg = ColorRect.new()
			bg.color = Color("5d6470")
			bg.size = Vector2(1280, 720)
			inst.add_child(bg)
			var arts = ["militia", "rifleman", "shieldbearer", "blunderbussier", "grenadier", "mechanic", "field_cannon", "flak_crew", "organ_gun", "brasshound", "copperback", "miner_rig", "boiler_stomper",
				"flying_machine", "scout_gyro", "bombard_gyro", "ironwing", "ironcloud",
				"rotter", "zombie_miner", "grave_crawler", "plague_runner", "skeleton", "bone_shield", "grave_knight", "bone_archer", "rot_spitter", "necromancer", "flesh_hulk", "carrion_bat", "plague_shrieker", "bone_spire"]
			var x = 60.0
			var y = 150.0
			for a in arts:
				var air = Painter.is_air_art(a)
				var sc = 1.5 if Painter.art_height(a) < 70 else (1.0 if Painter.art_height(a) < 100 else 0.8)
				if a == "ironcloud":
					sc = 0.8
				var sp = Widgets.ArtSprite.new(a, Vector2(x, y - (40 if air else 0)), sc, a in ["rotter", "zombie_miner", "grave_crawler", "plague_runner", "skeleton", "bone_shield", "grave_knight", "bone_archer", "rot_spitter", "necromancer", "flesh_hulk", "carrion_bat", "plague_shrieker", "bone_spire"])
				sp.anim.atk = 0.9 if a in ["rifleman", "copperback", "field_cannon", "flak_crew", "ironwing"] else 0.0
				sp.anim.aim0 = -1.0 if a == "flak_crew" else (1.2 if a in ["ironwing", "ironcloud"] else -0.1)
				sp.anim.aim1 = -0.6 if a == "ironwing" else 1.2
				inst.add_child(sp)
				x += 150.0 if a != "ironcloud" else 230.0
				if x > 1200.0:
					x = 60.0
					y += 180.0
			var m = Widgets.ArtSprite.new("mine_maw", Vector2(1120, 700), 0.75, true)
			inst.add_child(m)
		"battle":
			GameState.selected_stage = "s%03d" % int(args.get("stage", "1"))
			if args.has("last_stand"):
				GameState.selected_last_stand = String(args.last_stand)   # M008 Last Stand screenshots
			if args.has("stage_loadout"):
				GameState.profile.loadouts["Preset I"] = ["shieldbearer", "ironhold_rifleman", "light_field_cannon", "flak_crew", "organ_gun", "grenadier", "miner_rig", "dwarven_flying_machine", "scout_gyro", "", "", "brasshound_armored_car"]
			inst = load("res://scenes/battle_screen.tscn").instantiate()
		"sandbox":
			inst = load("res://scenes/sandbox.tscn").instantiate()
		_:
			inst = load("res://scenes/%s.tscn" % shot).instantiate()
	get_tree().root.add_child.call_deferred(inst)
	await get_tree().process_frame
	await get_tree().process_frame
	if shot in ["battle", "sandbox"]:
		if args.has("scenario"):
			inst._scenario(args.scenario)
		if args.has("tanks"):
			# M006c showcase: a column of distinct tanks rolling into an undead line
			var bt = inst.battle
			var tk = ["coalrunner_scout_tank", "boiler_ram", "bastion_heavy_tank", "dreadplate_breaker", "siegecrawler", "steamtread_heavy_carrier", "thunderback_heavy_tank", "brass_leviathan"]
			for i in tk.size():
				bt.spawn_unit(tk[i], 0, Vector2(250 + i * 70, 0), true)
			for i in 20:
				bt.spawn_unit(["rusted_legionary", "grave_knight", "flesh_hulk", "bone_archer", "rot_hound"][i % 5], 1, Vector2(1000 + i * 20, 0), true)
			for u in bt.units:
				if not u.is_stronghold:
					u.max_hp *= 3.0
					u.hp = u.max_hp
		if args.has("machines"):
			# M006b showcase: tanks, war frames, aircraft and airships against an undead push
			var b = inst.battle
			var dwm = ["bastion_heavy_tank", "ironclad_medium_tank", "cannon_strider", "anvilbreaker", "brass_leviathan", "mobile_flak_fortress", "ironclad_walker", "thunderback_heavy_tank"]
			for i in dwm.size():
				b.spawn_unit(dwm[i], 0, Vector2(420 + i * 55, 0), true)
			for i in 6:
				b.spawn_unit(["heavy_gyro_bomber", "twin_flame_gunship", "skyforge_dreadnought", "rocketwing", "thunderwing", "rune_citadel_airship"][i], 0, Vector2(450 + i * 70, 300 if i % 3 != 2 else 190), true)
			for i in 26:
				b.spawn_unit(["rusted_legionary", "grave_knight", "flesh_hulk", "bone_archer", "hollow_guard", "rot_hound"][i % 6], 1, Vector2(980 + i * 18, 0), true)
			for i in 8:
				b.spawn_unit(["bone_wyvern", "tomb_gargoyle", "carrion_bat", "gravewing_stalker"][i % 4], 1, Vector2(1050 + i * 30, 280), true)
			for u in b.units:
				if not u.is_stronghold:
					u.max_hp *= 3.0
					u.hp = u.max_hp
		var ai = AutoCommander.new()
		var ff = float(args.get("ff", "0"))
		var t = 0.0
		while t < ff and not inst.battle.over:
			if shot == "battle" or args.has("auto"):
				ai.step(inst.battle, 1.0 / 30.0)
			if "intro_active" in inst and inst.intro_active and not args.has("keep_intro"):
				inst._end_intro()
			if "guide" in inst and inst.guide != null and inst.guide._paused_by_me:
				inst.guide.dismiss()
			inst.battle.step(1.0 / 30.0)
			t += 1.0 / 30.0
		# M008 scenario hooks: force an eclipse, open a rift tear, release soul wisps, jump a Last Stand to a wave
		if args.has("ls_wave") and inst.battle.director is LastStand:
			var lsd: LastStand = inst.battle.director
			lsd.wave = int(args.ls_wave) - 1
			lsd.state = "gap"
			lsd.wave_t = 0.0
			inst.battle.stats_kills = int(args.get("ls_kills", "900"))
			for k in int(args.get("ls_after", "900")):
				ai.step(inst.battle, 1.0 / 30.0)
				inst.battle.step(1.0 / 30.0)
		if args.has("eclipse"):
			if inst.battle.eclipse_def.is_empty():
				Rift.set_eclipse(inst.battle, {"interval": 999, "duration": 30, "range_mult": 0.75})
			inst.battle.eclipse_t = 0.0
			if args.has("scout"):
				inst.battle.spawn_unit("rune_sight_scout", 0, Vector2(float(args.scout), 320), true)
			for k in 70:
				inst.battle.step(1.0 / 30.0)
		if args.has("tear_now"):
			if inst.battle.tear_def.is_empty():
				Rift.set_tears(inst.battle, {"interval": 999, "warn": 2.0, "open": 6.0, "hp": 400, "spill": 3, "pool": ["riftbound_legionary"], "first": 999})
			Rift.open_tear(inst.battle, float(args.tear_now))
			for k in int(args.get("tear_steps", "90")):
				inst.battle.step(1.0 / 30.0)
		if args.has("wisps_now"):
			var sd = {"interval": 999, "wisps": 1, "radius": 58, "heal": 16, "damage": 12, "speed": 44, "hp": 90}
			for k in 4:
				Rift.spawn_wisp(inst.battle, float(args.wisps_now) + k * 90.0, sd)
			for k in 20:
				inst.battle.step(1.0 / 30.0)
		# M006 scenario hooks for screenshots / clips
		if args.has("boss_hp") and inst.battle.boss != null and is_instance_valid(inst.battle.boss):
			inst.battle.boss.hp = inst.battle.boss.max_hp * float(args.boss_hp)
			for k in int(args.get("after", "60")):
				inst.battle.step(1.0 / 30.0)
		if args.has("cam_boss") and inst.battle.boss != null and is_instance_valid(inst.battle.boss):
			inst.cam.position.x = clampf(inst.battle.boss.position.x - 100.0, 640.0, Combat.WORLD_W - 640.0)
		if args.has("escort_now"):
			var esc = inst.battle.spawn_escort({"t": 0, "hp": 2600, "speed": 20, "alt": 215, "x0": float(args.escort_now), "x1": 2200})
			for k in 20:
				inst.battle.step(1.0 / 30.0)
		if args.has("strike"):
			var cx = float(args.get("cam", "1100"))
			inst.cam.position.x = cx
			var tg = inst.battle.tallest_near(cx, 500.0)
			inst.battle.bolts.append({"x": cx if tg == null else tg.position.x, "target": tg, "t": 0.0, "warn": 0.8, "dmg": 150.0, "r": 50.0, "struck": false, "y": Combat.GROUND_Y if tg == null else tg.position.y})
			for k in int(args.get("strike_steps", "26")):
				inst.battle.step(1.0 / 30.0)
		if args.has("cam") and not args.has("cam_boss"):
			inst.cam.position.x = float(args.cam)
		if args.has("hide_panel") and "panel" in inst:
			inst.panel.visible = false
		if args.has("pause_overlay"):
			inst._toggle_pause()
	if args.has("tab"):
		var tb = int(args.tab)
		if shot == "forge":
			inst.tab = tb; inst._build()
		elif shot == "compendium":
			inst.cat = tb; inst._build()
			inst._show(inst._entries()[int(args.get("item", "0"))])
		elif shot == "campaign_map":
			inst.act_tabs.current_tab = tb
			if args.has("select"):
				# M007: open the drawer on a chosen stage (e.g. a cleared one, to show the Heroic toggle)
				for i in 3:
					await get_tree().process_frame
				inst.realm.stage_selected.emit("s%03d" % int(args.select))
				if args.has("heroic_on"):
					GameState.selected_heroic = true
					GameState.selected_stage = "s%03d" % int(args.select)
					inst._show_detail(inst.selected)
			if args.has("close_drawer"):
				for i in 5:
					await get_tree().process_frame
				inst._toggle_drawer()
				inst.realm.scroll = float(args.get("scroll", "2000"))
				inst.realm.queue_redraw()
	if shot == "anim":
		var nf = int(args.get("nframes", "90"))
		var outdir: String = args.get("out", "/tmp/anim")
		DirAccess.make_dir_recursive_absolute(outdir)
		for f in nf:
			var tt = f / 30.0
			for c in inst.get_children():
				if c is Widgets.ArtSprite:
					var tau = fposmod(tt + float(c.get_meta("phase")), float(c.get_meta("period")))
					c.anim.t = tt
					c.anim.atk = maxf(0.0, 1.0 - 2.2 * tau)
					c.anim.atk2 = c.anim.atk
					c.anim.recoil = c.anim.atk
					c.anim.gag = maxf(0.0, 1.0 - 1.25 * tau)
					c.anim.reload = 0.0
					c.anim.state = "idle"
					c.queue_redraw()
			await get_tree().process_frame
			await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png("%s/f%03d.png" % [outdir, f])
		print("saved frames ", nf)
		SaveManager.wipe()
		get_tree().quit()
		return
	if shot in ["battle", "sandbox"] and args.has("clip"):
		# M006: a short clip: keep the battle running and save every frame (ffmpeg joins them)
		var outd: String = args.get("clip_out", "/tmp/clip")
		DirAccess.make_dir_recursive_absolute(outd)
		var ai2 = AutoCommander.new()
		for f in int(args.clip):
			if args.has("auto"):
				ai2.step(inst.battle, 1.0 / 30.0)
			inst.battle.step(1.0 / 30.0)
			if args.has("follow_boss") and inst.battle.boss != null and is_instance_valid(inst.battle.boss):
				inst.cam.position.x = lerpf(inst.cam.position.x, clampf(inst.battle.boss.position.x - 120.0, 640.0, Combat.WORLD_W - 640.0), 0.08)
			await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png("%s/f%04d.png" % [outd, f])
		print("saved clip frames ", int(args.clip))
		SaveManager.wipe()
		get_tree().quit()
		return
	if shot == "ending" and args.has("ending_part"):
		inst._go(String(args.ending_part))
		for k in int(args.get("ending_frames", "60")):
			await get_tree().process_frame
	if shot == "loadout" and args.has("item"):
		inst._unit_pressed(args.item)
	for i in int(args.get("frames", "20")):
		await get_tree().process_frame
	var img = get_viewport().get_texture().get_image()
	img.save_png(args.get("out", "/tmp/shot.png"))
	print("saved ", args.get("out", "/tmp/shot.png"))
	SaveManager.wipe()
	get_tree().quit()
