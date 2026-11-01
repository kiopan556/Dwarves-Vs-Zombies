extends "res://scripts/ui/battle_screen.gd"
## Development testing sandbox: spawn any implemented unit/enemy/boss for either side by
## tapping the battlefield, run the §14 validation scenarios visually, and watch live
## diagnostics (frame time, step time, unit counts per front, projectile & effect pools).

var panel: PanelContainer
var diag: Label
var spawn_id := "ironhold_rifleman"
var spawn_side := 0
var sel_label: Label
var auto: AutoCommander
var auto_on := false
var step_ms := 0.0
var _panel_open := true
var pick_group: OptionButton
var pick_grid: GridContainer
var pick_fac := 0


func _stage_def() -> Dictionary:
	return {"id": "sandbox", "name": "Test Sandbox", "env": "mountain_pass", "start_gold": 2000, "gold_rate": 40.0, "seed": 4}


func _loadout() -> Array:
	return ["shieldbearer", "ironhold_rifleman", "light_field_cannon", "flak_crew", "copperback_light_tank", "boiler_stomper", "field_mechanic",
		"dwarven_flying_machine", "bombard_gyro", "ironwing_gunship", "ironcloud", "organ_gun"]


func _battle_opts() -> Dictionary:
	return {"sandbox": true, "low": GameState.is_low_quality(), "seed": 4}


func _after_setup() -> void:
	is_sandbox = true
	battle.invulnerable_bases = true
	auto = AutoCommander.new()
	var toggle = UiKit.button("Dev ◂▸", func():
		_panel_open = not _panel_open
		panel.visible = _panel_open, Vector2(90, 42), 15)
	toggle.position = Vector2(10, 62)
	root.add_child(toggle)
	panel = UiKit.plate("panel_glass", Vector4(10, 8, 6, 8))
	panel.position = Vector2(10, 108)
	panel.custom_minimum_size = Vector2(330, 470)
	panel.size = Vector2(330, 470)
	root.add_child(panel)
	var sc = ScrollContainer.new()
	sc.custom_minimum_size = Vector2(320, 460)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(sc)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	diag = UiKit.label("", 13, UiKit.STEAM)
	v.add_child(diag)
	sel_label = UiKit.label("", 15, UiKit.FORGE)
	v.add_child(sel_label)
	v.add_child(UiKit.label("Tap the battlefield to spawn the selection.", 13, UiKit.TEXT_DIM))
	var tg = GridContainer.new()
	tg.columns = 2
	v.add_child(tg)
	for t in [["Infinite gold", func(on): battle.infinite_gold = on, false], ["Invulnerable bases", func(on): battle.invulnerable_bases = on, true],
			["Target lines", func(on): battle.debug_targets = on, false], ["All health bars", func(on): battle.show_all_bars = on, false],
			["Auto-commander", func(on): auto_on = on, false], ["Undead waves (Stage 015)", _toggle_waves, false]]:
		var c = CheckButton.new()
		c.text = t[0]
		c.button_pressed = t[2]
		c.add_theme_font_size_override("font_size", 13)
		c.toggled.connect(t[1])
		tg.add_child(c)
	v.add_child(UiKit.label("Validation scenarios (§14)", 16, UiKit.BRASS))
	var sg = GridContainer.new()
	sg.columns = 5
	v.add_child(sg)
	for k in ["A", "B", "C", "D", "E", "F", "G", "J", "Clear"]:
		var key: String = k
		sg.add_child(UiKit.button(k, func(): _scenario(key), Vector2(56, 40), 15))
	v.add_child(UiKit.label("Iron Giants scenarios (M002 §18)", 16, UiKit.BRASS))
	var mg = GridContainer.new()
	mg.columns = 6
	v.add_child(mg)
	for k in ["MA", "MB", "MC", "MD", "ME", "MF"]:
		var key2: String = k
		mg.add_child(UiKit.button(k, func(): _scenario(key2), Vector2(46, 40), 14))
	v.add_child(UiKit.label("Undead Giants (M002b): frames vs giants", 16, Color("9fd88a")))
	var gg = GridContainer.new()
	gg.columns = 4
	v.add_child(gg)
	for k in ["GA", "GB", "GC", "GD"]:
		var key3: String = k
		gg.add_child(UiKit.button(k, func(): _scenario(key3), Vector2(60, 40), 14))
	var dopt = OptionButton.new()
	for dn in ["conserve", "standard", "overdrive"]:
		dopt.add_item("Doctrine: " + dn.capitalize())
	dopt.selected = 1
	dopt.item_selected.connect(func(i): battle.mech_doctrine = ["conserve", "standard", "overdrive"][i])
	v.add_child(dopt)
	# spawn picker: faction tabs + group selector, so only one group's buttons exist at a time
	v.add_child(UiKit.heading("Spawn roster"))
	var ft = TabBar.new()
	for f in ["Dwarves", "Undead", "Bosses"]:
		ft.add_tab(f)
	ft.add_theme_font_size_override("font_size", 13)
	v.add_child(ft)
	pick_group = OptionButton.new()
	pick_group.add_theme_font_size_override("font_size", 13)
	v.add_child(pick_group)
	pick_grid = GridContainer.new()
	pick_grid.columns = 2
	v.add_child(pick_grid)
	ft.tab_changed.connect(func(i): _pick_faction(i))
	pick_group.item_selected.connect(func(_i): _pick_fill())
	_pick_faction(0)
	_select("ironhold_rifleman", 0)


func _pick_entries() -> Array:
	match pick_fac:
		0: return Registry.implemented_dwarves()
		1: return Registry.implemented_undead()
		_: return Registry.bosses


func _pick_key(e: Dictionary) -> String:
	match pick_fac:
		0: return String(e.branch_name)
		1: return String(e.category_name)
		_: return "Act %d" % int(e.act)


func _pick_faction(i: int) -> void:
	pick_fac = i
	pick_group.clear()
	var seen: Array = []
	for e in _pick_entries():
		var k = _pick_key(e)
		if not k in seen:
			seen.append(k)
			pick_group.add_item(k)
	pick_group.selected = 0
	_pick_fill()


func _pick_fill() -> void:
	for c in pick_grid.get_children():
		c.queue_free()
	var key = pick_group.get_item_text(pick_group.selected)
	for e in _pick_entries():
		if _pick_key(e) != key:
			continue
		var id: String = e.id
		var side = 0 if pick_fac == 0 else 1
		pick_grid.add_child(UiKit.button(("T%d " % int(e.tier) if pick_fac == 0 else "") + String(e.name), func(): _select(id, side), Vector2(150, 36), 12))
		if pick_fac == 0:
			for vv in e.stats.get("variants", []):
				var vid: String = id + "@" + vv.id
				pick_grid.add_child(UiKit.button(String(e.name).split(" ")[0] + " · " + String(vv.name).replace(" Configuration", ""), func(): _select(vid, 0), Vector2(150, 36), 11))


func _select(id: String, side: int) -> void:
	spawn_id = id
	spawn_side = side
	sel_label.text = "Selected: %s (%s)" % [Registry.entry(id.get_slice("@", 0)).get("name", id) + ((" — " + id.get_slice("@", 1)) if "@" in id else ""), "dwarf" if side == 0 else "undead"]


func _toggle_waves(on: bool) -> void:
	if on and battle.director == null:
		battle.director = WaveDirector.new()
		battle.director.setup(battle, Registry.stage("s015"))
	elif not on:
		battle.director = null


func _world_tap(p: Vector2) -> void:
	var d = Registry.combat_def(spawn_id)
	if d.is_empty():
		return
	var y = 0.0
	if d.get("domain", "ground") == "air":
		y = clampf(p.y, 160.0, 420.0)
	var u = battle.spawn_unit(spawn_id, spawn_side, Vector2(clampf(p.x, 200, Combat.WORLD_W - 200), y), true)
	if u != null and spawn_side == 1 and u.cls == "boss":
		battle.on_boss_spawned(u)


func _physics_process(delta: float) -> void:
	if auto_on:
		auto.step(battle, delta)
	var t0 = Time.get_ticks_usec()
	super._physics_process(delta)
	step_ms = lerpf(step_ms, float(Time.get_ticks_usec() - t0) / 1000.0, 0.1)


func _update_hud() -> void:
	super._update_hud()
	var c = [[0, 0], [0, 0]]
	for u in battle.units:
		if u.alive and not u.is_stronghold:
			c[u.side][0 if u.domain == "ground" else 1] += 1
	diag.text = "FPS %d · step %.2f ms · speed %.0f×\nDwarves: ground %d · air %d\nUndead: ground %d · air %d\nProjectiles %d/%d · FX %d/%d\nCorpses %d · Spotting %s · Gust %.0f" % [
		Engine.get_frames_per_second(), step_ms, speed, c[0][0], c[0][1], c[1][0], c[1][1],
		battle.projectiles.active_count, battle.projectiles.capacity, battle.fx.live, battle.fx.cap,
		battle.corpses.size(), "on" if battle.spotting_active else "off", battle.gust_x]


func _clear() -> void:
	for u in battle.units:
		if u.alive and not u.is_stronghold:
			u.alive = false
			u.dying_t = 1.0
	battle.projectiles.clear_all()
	battle.boss = null
	battle.citadel_sealed = false
	battle.enemy_base.special = 0.0


func _many(id: String, side: int, n: int, x0: float, dx: float, y: float = 0.0) -> Array:
	var out: Array = []
	for i in n:
		var u = battle.spawn_unit(id, side, Vector2(x0 + i * dx, y), true)
		if u != null:
			out.append(u)
	return out


func _scenario(k: String) -> void:
	_clear()
	match k:
		"A":
			_many("ironhold_rifleman", 0, 4, 380, 12); _many("shieldbearer", 0, 3, 460, 14)
			_many("rotter", 1, 8, 950, 16); _many("grave_knight", 1, 2, 1100, 20)
			cam.position.x = 700
		"B":
			_many("dwarven_flying_machine", 0, 5, 300, 30, 300)
			_many("carrion_bat", 1, 6, 1300, 25, 320); _many("plague_shrieker", 1, 2, 1400, 40, 280)
			cam.position.x = 800
		"C":
			_many("bombard_gyro", 0, 2, 200, 40, 270)
			for r in _many("rotter", 1, 12, 1200, 10):
				r.speed = 0.0
			cam.position.x = 1000
		"D":
			_many("flak_crew", 0, 2, 300, 30)
			for r in _many("rotter", 1, 6, 700, 15):
				r.speed = 0.0
			_many("carrion_bat", 1, 6, 1100, 30, 300); _many("plague_shrieker", 1, 2, 1200, 40, 260)
			cam.position.x = 700
		"E":
			_many("shieldbearer", 0, 2, 520, 14); _many("ironhold_rifleman", 0, 3, 450, 12)
			_many("light_field_cannon", 0, 1, 330, 0); _many("copperback_light_tank", 0, 1, 560, 0)
			_many("boiler_stomper", 0, 1, 600, 0); _many("dwarven_flying_machine", 0, 2, 400, 40, 300)
			_many("ironwing_gunship", 0, 1, 350, 0, 300); _many("ironcloud", 0, 1, 250, 0, 180)
			_many("rotter", 1, 10, 1300, 14); _many("ossuary_skeleton", 1, 4, 1450, 14); _many("grave_knight", 1, 1, 1380, 0)
			_many("carrion_bat", 1, 6, 1500, 25, 320); _many("plague_shrieker", 1, 2, 1550, 40, 280)
			cam.position.x = 900
		"F":
			_many("field_mechanic", 0, 1, 300, 0)
			var t = _many("copperback_light_tank", 0, 1, 380, 0)[0]
			t.hp = t.max_hp * 0.3; t.speed = 0.0
			var r = _many("miner_rig", 0, 1, 520, 0)[0]
			r.hp = r.max_hp * 0.4; r.speed = 0.0
			cam.position.x = 500
		"G":
			var m = battle.spawn_unit("mine_maw", 1, Vector2(1900, 0), true)
			battle.on_boss_spawned(m)
			_many("shieldbearer", 0, 3, 600, 14); _many("ironhold_rifleman", 0, 4, 520, 12)
			_many("light_field_cannon", 0, 2, 400, 30); _many("scout_gyro", 0, 1, 400, 0, 220)
			cam.position.x = 1200
		"MA":
			_many("miner_rig", 0, 2, 420, 40); _many("ironhold_rifleman", 0, 4, 340, 14); _many("dwarven_flying_machine", 0, 2, 300, 40, 300)
			_many("rotter", 1, 14, 1100, 14); _many("ossuary_skeleton", 1, 4, 1300, 16); _many("carrion_bat", 1, 4, 1300, 30, 320)
			cam.position.x = 800
		"MB":
			_many("drillwalker", 0, 2, 520, 50); _many("cannon_strider", 0, 1, 360, 0)
			_many("grave_knight", 1, 3, 1150, 30); _many("flesh_hulk", 1, 2, 1350, 60); _many("bone_shieldbearer", 1, 3, 1200, 20)
			cam.position.x = 900
		"MC":
			_many("skyguard_walker", 0, 1, 420, 0); _many("flak_colossus", 0, 1, 330, 0)
			_many("carrion_bat", 1, 14, 1200, 22, 300); _many("plague_shrieker", 1, 6, 1300, 40, 260)
			cam.position.x = 760
		"MD":
			_many("anvilbreaker", 0, 1, 560, 0); _many("shieldframe", 0, 1, 640, 0); _many("ironhold_rifleman", 0, 5, 420, 14); _many("light_field_cannon", 0, 2, 300, 40)
			_many("rotter", 1, 16, 1100, 12); _many("grave_knight", 1, 2, 1250, 30); _many("bone_archer", 1, 6, 1350, 14)
			cam.position.x = 860
		"ME":
			_many("deepforge_titan", 0, 1, 520, 0)
			_many("rotter", 1, 12, 1100, 14); _many("grave_knight", 1, 2, 1250, 30); _many("carrion_bat", 1, 8, 1000, 30, 300); _many("plague_shrieker", 1, 4, 1100, 40, 270)
			cam.position.x = 800
		"MF":
			for id3 in ["kings_anvil", "mountain_colossus", "siegebellow", "furnace_guardian", "shredder_walker", "riftshield_walker", "copperback_light_tank", "ironhold_rifleman", "ironhold_rifleman", "light_field_cannon", "flak_crew", "field_mechanic"]:
				battle.spawn_unit(id3, 0, Vector2(260 + randf() * 420, 0), true)
			for id4 in ["dwarven_flying_machine", "ironwing_gunship", "bombard_gyro"]:
				battle.spawn_unit(id4, 0, Vector2(260 + randf() * 300, 300), true)
			var ids_u2 = ["rotter", "plague_runner", "ossuary_skeleton", "grave_knight", "bone_archer", "rot_spitter", "necromancer", "flesh_hulk"]
			for i in 60:
				battle.spawn_unit(ids_u2[i % ids_u2.size()], 1, Vector2(1300 + randf() * 900, 0), true)
			for i in 16:
				battle.spawn_unit("carrion_bat" if i % 3 else "plague_shrieker", 1, Vector2(1400 + randf() * 700, 300), true)
			cam.position.x = 900
		"GA":   # light frames vs brutes
			for id5 in ["miner_rig", "drillwalker", "piston_brawler", "copper_sentinel"]:
				battle.spawn_unit(id5, 0, Vector2(380 + randf() * 200, 0), true)
			_many("ironhold_rifleman", 0, 4, 330, 14)
			for id6 in ["carrion_bull", "bone_golem", "plague_beast"]:
				battle.spawn_unit(id6, 1, Vector2(1150 + randf() * 200, 0), true)
			_many("rotter", 1, 10, 1250, 14)
			cam.position.x = 820
		"GB":   # medium frames vs abominations
			for id5 in ["ironclad_walker", "cannon_strider", "shieldframe", "thundercoil_frame"]:
				battle.spawn_unit(id5, 0, Vector2(360 + randf() * 220, 0), true)
			for id6 in ["stitchback_giant", "ossuary_juggernaut", "corpse_mound", "ghoul_matriarch"]:
				battle.spawn_unit(id6, 1, Vector2(1200 + randf() * 260, 0), true)
			_many("ossuary_skeleton", 1, 6, 1350, 14)
			cam.position.x = 880
		"GC":   # heavy frames + aircraft vs behemoths + flyers
			for id5 in ["anvilbreaker", "siegebellow", "flak_colossus", "furnace_guardian"]:
				battle.spawn_unit(id5, 0, Vector2(340 + randf() * 240, 0), true)
			_many("dwarven_flying_machine", 0, 3, 300, 40, 300)
			for id6 in ["cathedral_ghast", "blackroot_abomination", "walking_crypt"]:
				battle.spawn_unit(id6, 1, Vector2(1250 + randf() * 260, 0), true)
			_many("carrion_bat", 1, 8, 1300, 25, 300)
			cam.position.x = 900
		"GD":   # colossal clash
			for id5 in ["deepforge_titan", "kings_anvil"]:
				battle.spawn_unit(id5, 0, Vector2(380 + randf() * 160, 0), true)
			_many("light_field_cannon", 0, 2, 280, 40); _many("flak_crew", 0, 1, 320, 0); _many("field_mechanic", 0, 2, 300, 20)
			for id6 in ["plague_colossus", "rift_maw"]:
				battle.spawn_unit(id6, 1, Vector2(1300 + randf() * 200, 0), true)
			_many("grave_knight", 1, 3, 1400, 30); _many("plague_shrieker", 1, 3, 1450, 40, 270)
			cam.position.x = 900
		"J":
			var ids_d = ["ironhold_rifleman", "shieldbearer", "tunnel_militia", "blunderbussier", "grenadier", "light_field_cannon", "flak_crew", "organ_gun", "brasshound_armored_car", "copperback_light_tank", "miner_rig", "boiler_stomper", "field_mechanic"]
			var ids_u = ["rotter", "zombie_miner", "grave_crawler", "plague_runner", "ossuary_skeleton", "bone_shieldbearer", "grave_knight", "bone_archer", "rot_spitter", "necromancer", "flesh_hulk"]
			for i in 55:
				battle.spawn_unit(ids_d[i % ids_d.size()], 0, Vector2(250 + randf() * 500, 0), true)
			for i in 15:
				battle.spawn_unit(["dwarven_flying_machine", "scout_gyro", "bombard_gyro", "ironwing_gunship", "ironcloud"][i % 5], 0, Vector2(250 + randf() * 400, 300), true)
			for i in 70:
				battle.spawn_unit(ids_u[i % ids_u.size()], 1, Vector2(1500 + randf() * 800, 0), true)
			for i in 20:
				battle.spawn_unit("carrion_bat" if i % 3 else "plague_shrieker", 1, Vector2(1600 + randf() * 700, 300), true)
			cam.position.x = 1100
