extends Node
## Battle screen: world + camera + restrained command-console HUD (stronghold bars, Gold,
## Steam gauge, 12 deploy cards with cooldowns, steam abilities, minimap, pause/speed),
## plus Victory / Defeat / Pause overlays. Touch: tap cards, drag the battlefield to pan.

var battle: Battle
var cam: Camera2D
var hud: CanvasLayer
var root: Control
var cards: Array = []
var gold_l: Label
var steam_bar: UiKit.Dial
var my_bar: UiKit.GaugeBar
var foe_bar: UiKit.GaugeBar
var boss_bar: UiKit.GaugeBar
var boss_box: Control
var time_l: Label
var alert_box: Control
var alert_l: Label
var alert_t := 0.0
var speed := 1.0
var speed_btn: Button
var pause_btn: Button
var mine_btn: ValveButton
var od_btn: ValveButton
var vent_btn: ValveButton
var doc_btn: ValveButton
var minimap: Minimap
var sky_threat: SkyThreat
var escort_bar: EscortBar
var overlay: Control
var dragging := false
var drag_moved := 0.0
var stage: Dictionary
var is_sandbox := false
var shake_on := true
var _hud_t := 0.0
var _result_shown := false
var guide: Guide
var intro_active := false        # M005 boss arrival: short camera pan to the boss (battle paused, tap to skip)
var _intro_t := 0.0
var _intro_from := 0.0
var _intro_to := 0.0
const INTRO_GO := 0.7
const INTRO_HOLD := 1.4
const INTRO_BACK := 0.6


func _ready() -> void:
	stage = _stage_def()
	shake_on = bool(GameState.setting("shake"))
	speed = float(GameState.setting("speed"))
	var world = Node2D.new()
	world.name = "World"
	add_child(world)
	battle = Battle.new()
	world.add_child(battle)
	battle.setup(stage, _loadout(), _battle_opts())
	battle.ended.connect(_on_end)
	battle.alert.connect(_alert)
	battle.boss_appeared.connect(func(b):
		boss_box.visible = true
		_boss_intro(b))
	cam = Camera2D.new()
	cam.position = Vector2(640, 360)
	world.add_child(cam)
	cam.make_current()
	_build_hud()
	_layer_hud(root)
	_after_setup()
	if not is_sandbox:
		guide = Guide.new()
		root.add_child(guide)
		guide.setup(self, String(stage.get("id", "")))
	Audio.play_music("battle")
	var amb = "mountain"
	var env_id = String(stage.get("env", ""))
	if env_id in ["dead_forest", "plague_marsh", "ruined_road", "corrupted_mine", "open_plains", "broken_ridge", "airborne_ruins", "shattered_fort",
			"industrial_city", "destroyed_forge", "infested_factory", "mech_graveyard"]:
		amb = {"dead_forest": "forest", "plague_marsh": "marsh", "ruined_road": "road", "corrupted_mine": "fungal",
			"open_plains": "plains", "broken_ridge": "highridge", "airborne_ruins": "cloudsea", "shattered_fort": "fort",
			"industrial_city": "city", "destroyed_forge": "dead_forge", "infested_factory": "factory", "mech_graveyard": "graveyard"}[env_id]
	elif "mine" in env_id:
		amb = "mine"
	elif "foundry" in env_id:
		amb = "foundry"
	elif "ridge" in env_id:
		amb = "ridge"
	Audio.play_ambience(amb)
	if not is_sandbox:
		GameState.profile.stats.battles += 1


# overridable hooks (sandbox)
func _stage_def() -> Dictionary:
	if GameState.selected_heroic and GameState.heroic_available(GameState.selected_stage):
		return Registry.heroic_stage(GameState.selected_stage)   # M007 Heroic difficulty
	return Registry.stage(GameState.selected_stage)


func _loadout() -> Array:
	return GameState.active_loadout()


func _battle_opts() -> Dictionary:
	return {"low": GameState.is_low_quality()}


func _after_setup() -> void:
	pass


# =============================================================== loop
func _physics_process(delta: float) -> void:
	if battle == null:
		return
	if intro_active:
		_step_intro(delta)
		_update_camera(delta)
		# the battle is paused, so units only redraw on request: refresh those the pan brings into view
		for u in battle.units:
			if is_instance_valid(u):
				u._request_redraw()
		return
	var steps = 2 if speed > 1.5 else 1
	for i in steps:
		battle.step(delta)
	_update_camera(delta)


func _process(delta: float) -> void:
	_hud_t -= delta
	if _hud_t <= 0.0:
		_hud_t = 0.1
		_update_hud()
	if alert_t > 0.0:
		alert_t -= delta
		alert_box.modulate.a = clampf(alert_t * 1.5, 0.0, 1.0)
		alert_box.visible = alert_t > 0.0


func _view_w() -> float:
	return get_viewport().get_visible_rect().size.x / cam.zoom.x


func _update_camera(_delta: float) -> void:
	var vw = _view_w()
	cam.position.x = clampf(cam.position.x, vw * 0.5 - 40.0, Combat.WORLD_W - vw * 0.5 + 40.0)
	cam.position.y = 360.0
	battle.view_rect = Rect2(cam.position.x - vw * 0.5, 0, vw, 720)
	Audio.listener_x = cam.position.x
	if shake_on and battle.shake_amount > 0.1:
		cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * battle.shake_amount
	else:
		cam.offset = Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if intro_active and ((event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed) or (event is InputEventKey and event.pressed)):
		_end_intro()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			if event.pressed:
				drag_moved = 0.0
			elif drag_moved < 8.0:
				_world_tap(cam.get_global_mouse_position())
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			cam.position.x -= 120.0
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cam.position.x += 120.0
	elif event is InputEventMouseMotion and dragging:
		cam.position.x -= event.relative.x / cam.zoom.x
		drag_moved += absf(event.relative.x)
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT, KEY_A: cam.position.x -= 160.0
			KEY_RIGHT, KEY_D: cam.position.x += 160.0
			KEY_SPACE, KEY_P: _toggle_pause()
			KEY_ESCAPE: _toggle_pause()


func _world_tap(_p: Vector2) -> void:
	pass


# =============================================================== HUD (M003 forged-brass console)
func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	root = Control.new()
	root.theme = UiKit.theme()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(root)
	# --- top console: riveted iron strip
	var top = PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 64
	top.offset_left = -6
	top.offset_right = 6
	top.offset_top = -6
	top.add_theme_stylebox_override("panel", UiArt.style("panel", 16, Vector4(18, 12, 18, 6)))
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)
	var th = HBoxContainer.new()
	th.add_theme_constant_override("separation", 10)
	top.add_child(th)
	var my_v = VBoxContainer.new()
	my_v.add_theme_constant_override("separation", 1)
	th.add_child(my_v)
	my_bar = UiKit.GaugeBar.new()
	my_bar.glyph = "shield"
	my_bar.custom_minimum_size = Vector2(250, 38)
	my_v.add_child(my_bar)
	# M006: the escorted supply barge's health, a thin bar under the stronghold gauge (only when present)
	escort_bar = EscortBar.new()
	escort_bar.battle = battle
	escort_bar.custom_minimum_size = Vector2(250, 6)
	escort_bar.visible = false
	my_v.add_child(escort_bar)
	var gold_box = UiKit.pill("coin", "0", Color("ffd76a"))
	gold_box.custom_minimum_size = Vector2(120, 38)
	gold_l = gold_box.find_child("Value", true, false)
	gold_l.add_theme_font_size_override("font_size", 22)
	th.add_child(gold_box)
	var dial_holder = Control.new()
	dial_holder.custom_minimum_size = Vector2(66, 40)
	th.add_child(dial_holder)
	steam_bar = UiKit.Dial.new()
	steam_bar.position = Vector2(-4, -8)
	steam_bar.size = Vector2(74, 74)
	dial_holder.add_child(steam_bar)
	var sp1 = Control.new()
	sp1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	th.add_child(sp1)
	var mm_v = VBoxContainer.new()
	mm_v.add_theme_constant_override("separation", 0)
	th.add_child(mm_v)
	var mm_frame = UiKit.plate("panel_dark", Vector4(6, 4, 6, 4))
	mm_v.add_child(mm_frame)
	minimap = Minimap.new()
	minimap.battle = battle
	minimap.screen = self
	minimap.custom_minimum_size = Vector2(280, 28)
	var mm_h = HBoxContainer.new()
	mm_h.add_theme_constant_override("separation", 4)
	mm_frame.add_child(mm_h)
	mm_h.add_child(minimap)
	# M006: sky-threat indicator — hostile flyers by altitude band (high / mid / low)
	sky_threat = SkyThreat.new()
	sky_threat.battle = battle
	sky_threat.custom_minimum_size = Vector2(34, 28)
	sky_threat.tooltip_text = "Hostile flyers by altitude band: high · mid · low"
	mm_h.add_child(sky_threat)
	time_l = UiKit.label("", 13, UiKit.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	mm_v.add_child(time_l)
	var sp2 = Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	th.add_child(sp2)
	foe_bar = UiKit.GaugeBar.new()
	foe_bar.glyph = "skull"
	foe_bar.align_right = true
	foe_bar.col = Color("8a5aa0")
	foe_bar.custom_minimum_size = Vector2(250, 38)
	th.add_child(foe_bar)
	speed_btn = _round_button("fast", _toggle_speed)
	th.add_child(speed_btn)
	pause_btn = _round_button("pause", _toggle_pause)
	th.add_child(pause_btn)
	# --- boss banner + bar
	boss_box = VBoxContainer.new()
	boss_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_box.offset_left = -250
	boss_box.offset_right = 250
	boss_box.offset_top = 66
	boss_box.add_theme_constant_override("separation", -6)
	boss_box.visible = false
	boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(boss_box)
	boss_bar = UiKit.GaugeBar.new()
	boss_bar.glyph = "crown"
	boss_bar.col = Color("b8404a")
	boss_bar.custom_minimum_size = Vector2(500, 34)
	boss_box.add_child(boss_bar)
	# --- alert banner
	alert_box = UiKit.banner("", 20, 360)
	alert_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	alert_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	alert_box.offset_top = 112
	alert_box.visible = false
	alert_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(alert_box)
	alert_l = alert_box.get_child(0)
	alert_l.add_theme_color_override("font_color", Color("ffcf8a"))
	_build_cards()
	_build_abilities()


## Draw-call batching for the HUD: panels stay on z 0, icon glyphs (one shared atlas) go to z 2
## and labels (one font) to z 3, so each kind is drawn together instead of alternating per widget.
## HUD widgets never overlap each other; the end/pause overlays sit at z 10.
func _layer_hud(n: Node) -> void:
	for c in n.get_children():
		if c is Label:
			c.z_index = 3
		elif c is UiKit.Glyph:
			c.z_index = 2
		elif c is CanvasItem and c.z_index == 0:
			_layer_hud(c)


func _round_button(glyph: String, cb: Callable) -> Button:
	var b = UiKit.button("", cb, Vector2(48, 40))
	var cc = CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(cc)
	var g = UiKit.Glyph.new(glyph, 22, UiKit.BRASS_L)
	cc.add_child(g)
	b.set_meta("glyph", g)
	return b


func _build_cards() -> void:
	var tray = PanelContainer.new()
	tray.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	tray.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tray.offset_top = -124
	tray.offset_bottom = 4
	tray.add_theme_stylebox_override("panel", UiArt.style("panel", 16, Vector4(12, 10, 12, 10)))
	tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(tray)
	var bottom = HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 5)
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	tray.add_child(bottom)
	var lo: Array = _loadout()
	for i in lo.size():
		if i == GameState.GROUND_SLOTS or i == GameState.GROUND_SLOTS + GameState.AIR_SLOTS:
			var sep = ColorRect.new()
			sep.color = Color(UiKit.BRASS_D, 0.6)
			sep.custom_minimum_size = Vector2(3, 0)
			bottom.add_child(sep)
		var uid: String = lo[i]
		if uid == "" or not Registry.is_implemented(uid):
			var empty = Panel.new()
			empty.add_theme_stylebox_override("panel", UiArt.style("slot", 10))
			empty.custom_minimum_size = Vector2(84, 104)
			empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bottom.add_child(empty)
			continue
		var c = DeployCard.new()
		c.unit_id = uid
		c.screen = self
		c.custom_minimum_size = Vector2(84, 104)
		bottom.add_child(c)
		cards.append(c)


func _build_abilities() -> void:
	var v = VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	v.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	v.grow_vertical = Control.GROW_DIRECTION_BEGIN
	v.offset_right = -8
	v.offset_bottom = -128
	v.add_theme_constant_override("separation", 2)
	root.add_child(v)
	doc_btn = ValveButton.new("gear", "Machinery", func():
		var dname = battle.cycle_doctrine()
		GameState.set_setting("mech_doctrine", dname)
		_alert("Machinery doctrine: " + dname.capitalize()))
	mine_btn = ValveButton.new("mine", "Mine", func(): battle.upgrade_mine())
	od_btn = ValveButton.new("flame", "Overdrive", func(): battle.overdrive())
	vent_btn = ValveButton.new("steam", "Vent", func(): battle.steam_vent())
	for b in [doc_btn, mine_btn, od_btn, vent_btn]:
		v.add_child(b)


func _update_hud() -> void:
	if battle == null:
		return
	var mf = battle.dwarf_base.hp / battle.dwarf_base.max_hp
	my_bar.col = UiKit.hp_color(mf)
	my_bar.set_value(mf, "Stronghold  %d" % int(battle.dwarf_base.hp))
	foe_bar.set_value(battle.enemy_base.hp / battle.enemy_base.max_hp, ("Sealed  %d" if battle.citadel_sealed else "Citadel  %d") % int(battle.enemy_base.hp))
	gold_l.text = "%d" % int(battle.gold) if not battle.infinite_gold else "∞"
	steam_bar.set_value(battle.steam / Battle.STEAM_MAX)
	time_l.text = "%d:%02d  ·  %d slain  ·  %s" % [int(battle.time) / 60, int(battle.time) % 60, battle.stats_kills, String(stage.get("name", "Sandbox"))]
	var mc = battle.mine_upgrade_cost()
	mine_btn.setup_state("Lv%d" % battle.mine_level, ("%dg" % mc) if mc > 0 else "MAX", not (mc < 0 or battle.gold < mc), 0.0)
	od_btn.setup_state("Overdrive", "%d steam" % int(Battle.OVERDRIVE_COST) if battle.overdrive_cd <= 0.0 else "%ds" % int(ceil(battle.overdrive_cd)), battle.can_overdrive(), battle.overdrive_cd / Battle.OVERDRIVE_CD)
	vent_btn.setup_state("Vent", "%d steam" % int(Battle.VENT_COST) if battle.vent_cd <= 0.0 else "%ds" % int(ceil(battle.vent_cd)), battle.can_vent(), battle.vent_cd / Battle.VENT_CD)
	doc_btn.setup_state("Machinery", battle.mech_doctrine.capitalize(), true, 0.0)
	if battle.boss != null and is_instance_valid(battle.boss):
		boss_box.visible = battle.boss.alive
		boss_bar.set_value(battle.boss.hp / battle.boss.max_hp, String(battle.boss.def.get("name", "Boss")) + ("  · ENRAGED" if battle.boss._enraged else ""))
	for c in cards:
		c.queue_redraw()
	minimap.queue_redraw()
	var ef = battle.escort_frac()
	escort_bar.visible = ef >= 0.0 and battle.escort_state != "pending"
	if escort_bar.visible:
		escort_bar.queue_redraw()
	sky_threat.queue_redraw()


# =============================================================== M005 boss arrival
func _boss_intro(b) -> void:
	Audio.play("boss_sting", -1, 0.0, 0.0)
	_alert("%s approaches!" % String(b.def.get("name", "The boss")) if b != null and is_instance_valid(b) else "Something vast approaches!")
	if is_sandbox or b == null or not is_instance_valid(b) or battle.over:
		return
	intro_active = true
	_intro_t = 0.0
	_intro_from = cam.position.x
	_intro_to = b.position.x
	battle.paused = true


func _step_intro(delta: float) -> void:
	_intro_t += delta
	var t = _intro_t
	if t < INTRO_GO:
		cam.position.x = lerpf(_intro_from, _intro_to, ease(t / INTRO_GO, -2.0))
	elif t < INTRO_GO + INTRO_HOLD:
		cam.position.x = _intro_to
	elif t < INTRO_GO + INTRO_HOLD + INTRO_BACK:
		cam.position.x = lerpf(_intro_to, _intro_from, ease((t - INTRO_GO - INTRO_HOLD) / INTRO_BACK, -2.0))
	else:
		_end_intro()


func _end_intro() -> void:
	if not intro_active:
		return
	intro_active = false
	cam.position.x = _intro_from
	if overlay == null and (guide == null or not guide._paused_by_me):
		battle.paused = false


func _alert(text: String) -> void:
	alert_l.text = text
	alert_t = 3.0
	alert_box.visible = true
	alert_box.modulate.a = 1.0


func _toggle_speed() -> void:
	speed = 1.0 if speed > 1.5 else 2.0
	var g = speed_btn.get_meta("glyph")
	g.kind = "fast" if speed < 1.5 else "play"
	g.col = UiKit.BRASS_L if speed < 1.5 else UiKit.FORGE
	g.queue_redraw()


func _toggle_pause() -> void:
	if battle.over or intro_active:
		return
	if guide != null and guide._paused_by_me:
		guide.dismiss()
		return
	battle.paused = not battle.paused
	if battle.paused:
		_show_pause()
	elif overlay != null:
		overlay.queue_free()
		overlay = null


# =============================================================== overlays
func _overlay_panel(title: String, col: Color) -> VBoxContainer:
	if overlay != null:
		overlay.queue_free()
	overlay = ColorRect.new()
	overlay.z_index = 10   # above the deploy tray's layered card parts
	overlay.color = Color(0.03, 0.02, 0.02, 0.62)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var outer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", -14)
	center.add_child(outer)
	var bn = UiKit.banner(title, 40, 420)
	bn.get_child(0).add_theme_color_override("font_color", col)
	bn.z_index = 1
	outer.add_child(bn)
	var pc = UiKit.plate("panel", Vector4(28, 30, 28, 22))
	pc.custom_minimum_size = Vector2(560, 0)
	outer.add_child(pc)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	pc.add_child(v)
	overlay.modulate.a = 0.0
	var tw = overlay.create_tween()
	tw.tween_property(overlay, "modulate:a", 1.0, 0.25)
	return v


func _show_pause() -> void:
	var v = _overlay_panel("PAUSED", UiKit.BRASS_L)
	v.add_child(UiKit.label(stage.get("name", "Sandbox"), 20, UiKit.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UiKit.primary("Resume", _toggle_pause, Vector2(0, 62)))
	v.add_child(UiKit.button("Restart battle", func(): get_tree().reload_current_scene(), Vector2(0, 54)))
	var row = HBoxContainer.new()
	var sh = CheckButton.new()
	sh.text = "Screen shake"
	sh.button_pressed = shake_on
	sh.toggled.connect(func(on): shake_on = on; GameState.set_setting("shake", on))
	row.add_child(sh)
	row.add_child(UiKit.label("Music", 16, UiKit.TEXT_DIM))
	var mus = HSlider.new()
	mus.min_value = 0; mus.max_value = 1; mus.step = 0.05
	mus.custom_minimum_size = Vector2(160, 30)
	mus.value = float(GameState.setting("music"))
	mus.value_changed.connect(func(x): GameState.set_setting("music", x))
	row.add_child(mus)
	v.add_child(row)
	v.add_child(UiKit.danger("Retreat to campaign" if not is_sandbox else "Exit sandbox", func():
		if not is_sandbox and not battle.over:
			GameState.record_defeat(battle.stats_kills)
		GameState.goto("campaign" if not is_sandbox else "menu"), Vector2(0, 54)))


func _stat(grid: GridContainer, glyph: String, label_text: String, value: String, col: Color = UiKit.TEXT) -> void:
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.add_child(UiKit.Glyph.new(glyph, 20, col))
	h.add_child(UiKit.label(label_text, 15, UiKit.TEXT_DIM))
	grid.add_child(h)
	var l = UiKit.label(value, 19, col, HORIZONTAL_ALIGNMENT_RIGHT)
	l.add_theme_font_override("font", UiKit.bold())
	grid.add_child(l)


func _on_end(won: bool) -> void:
	if _result_shown:
		return
	_result_shown = true
	await get_tree().create_timer(1.6).timeout
	if not is_inside_tree():
		return
	var summary = {}
	if not is_sandbox:
		if won:
			if battle.heroic:
				summary = GameState.grant_heroic_rewards(stage.id, battle.time, battle.stats_kills, battle.stars_earned())
			else:
				summary = GameState.grant_stage_rewards(stage.id, battle.time, battle.stats_kills, battle.stars_earned())
		else:
			GameState.record_defeat(battle.stats_kills)
		GameState.profile.stats["salvaged"] = int(GameState.profile.stats.get("salvaged", 0)) + battle.stats_salvaged
		GameState.profile.stats["reclaimed"] = int(GameState.profile.stats.get("reclaimed", 0)) + battle.stats_reclaimed
	var v = _overlay_panel(("HEROIC VICTORY" if battle.heroic else "VICTORY") if won else "DEFEAT", UiKit.GOOD if won else UiKit.BAD)
	var sub = "The citadel falls. The Holds endure." if won else "The stronghold has fallen. The dead pour into the Holds."
	var sl = UiKit.label(sub, 18, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(sl)
	v.add_child(UiKit.heading("Battle report"))
	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 22)
	v.add_child(grid)
	_stat(grid, "play", "Time", "%d:%02d" % [int(battle.time) / 60, int(battle.time) % 60])
	_stat(grid, "skull", "Undead destroyed", str(battle.stats_kills), UiKit.UNDEAD)
	_stat(grid, "shield", "Dwarves lost", str(battle.stats_losses), UiKit.BAD)
	_stat(grid, "hammer", "Units deployed", str(battle.stats_deployed))
	if won and not is_sandbox:
		_star_stamps(v, summary)
	if won and not summary.is_empty():
		v.add_child(UiKit.heading("Spoils", UiKit.FORGE))
		var rw = HBoxContainer.new()
		rw.alignment = BoxContainer.ALIGNMENT_CENTER
		if summary.get("heroic", false):
			rw.add_child(UiKit.pill("spark", ("+%d Forge Sparks  (first Heroic clear)" % summary.sparks) if summary.first_clear else "Heroic replay — glory only", UiKit.FORGE))
		else:
			rw.add_child(UiKit.pill("spark", "+%d Forge Sparks%s" % [summary.sparks, "" if summary.first_clear else "  (replay)"], UiKit.FORGE))
		if int(summary.get("star_bonus", 0)) > 0:
			rw.add_child(UiKit.pill("star", "incl. +%d first-star bonus" % int(summary.star_bonus), UiKit.GOOD))
		v.add_child(rw)
		for u in summary.unlocked:
			var bp = HBoxContainer.new()
			bp.alignment = BoxContainer.ALIGNMENT_CENTER
			var pv = Widgets.UnitPreview.new(Registry.combat_def(u).get("art", u), "dwarf")
			pv.custom_minimum_size = Vector2(56, 56)
			bp.add_child(pv)
			bp.add_child(UiKit.label("New blueprint: %s" % Registry.entry(u).name, 18, UiKit.GOOD))
			v.add_child(bp)
		for tier in summary.tiers:
			v.add_child(UiKit.label("Research opened: %s" % Registry.TIER_NAMES[tier], 17, UiKit.BRASS_L, HORIZONTAL_ALIGNMENT_CENTER))
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(h)
	if is_sandbox:
		h.add_child(UiKit.primary("Restart", func(): get_tree().reload_current_scene(), Vector2(170, 58)))
		h.add_child(UiKit.button("Menu", func(): GameState.goto("menu"), Vector2(160, 56)))
		return
	h.add_child(UiKit.button("Retry", func(): get_tree().reload_current_scene(), Vector2(140, 56)))
	h.add_child(UiKit.button("Campaign", func(): GameState.goto("campaign"), Vector2(150, 56)))
	if won:
		h.add_child(UiKit.button("Great Forge", func(): GameState.goto("forge"), Vector2(160, 56)))
		var nxt = Registry.stage_by_index(int(stage.index) + 1)
		if not nxt.is_empty() and nxt.implemented:
			h.add_child(UiKit.primary("Next Stage", func():
				GameState.selected_stage = nxt.id
				GameState.selected_heroic = false
				get_tree().reload_current_scene(), Vector2(180, 58)))


## Victory plate: three animated star stamps (victory · stronghold held · challenge) and the challenge result.
func _star_stamps(v: VBoxContainer, summary: Dictionary) -> void:
	var earned: Array = summary.get("stars_earned", battle.stars_earned())
	var best: Array = summary.get("stars", earned)
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 26)
	v.add_child(row)
	var labels = ["Victory", "Stronghold held", "Challenge"]
	for i in 3:
		var col = VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(col)
		var holder = Control.new()
		holder.custom_minimum_size = Vector2(60, 56)
		col.add_child(holder)
		var lit = bool(earned[i])
		var g = UiKit.Glyph.new("star", 46, UiKit.FORGE if lit else (UiKit.BRASS_D if bool(best[i]) else Color(0.25, 0.22, 0.2)))
		g.position = Vector2(7, 5)
		g.pivot_offset = Vector2(23, 23)
		holder.add_child(g)
		col.add_child(UiKit.label(labels[i], 13, UiKit.TEXT if lit else UiKit.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))
		if lit:
			g.scale = Vector2(2.2, 2.2)
			g.modulate.a = 0.0
			var tw = create_tween()
			tw.tween_interval(0.35 + i * 0.45)
			tw.tween_callback(func(): Audio.play("star_stamp", -1, -2.0, 0.05))
			tw.tween_property(g, "modulate:a", 1.0, 0.05)
			tw.parallel().tween_property(g, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var c: Dictionary = stage.get("challenge", {}) if stage.get("challenge") != null else {}
	if not c.is_empty():
		var ok = bool(earned[2])
		v.add_child(UiKit.label("Challenge — %s: %s" % [String(c.get("text", "")), "met" if ok else "not met"], 15, UiKit.GOOD if ok else UiKit.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))


# =============================================================== inner widgets
class DeployCard extends Control:
	var unit_id = ""
	var screen
	var def: Dictionary
	var preview: Widgets.UnitPreview
	var overlay: CardOverlay
	var text_layer: CardText
	var air = false

	func _ready() -> void:
		def = Registry.combat_def(unit_id)
		air = def.get("domain", "ground") == "air"
		preview = Widgets.UnitPreview.new(def.get("art", ""), "dwarf")
		preview.set_anchors_preset(Control.PRESET_FULL_RECT)
		preview.offset_left = 6
		preview.offset_right = -6
		preview.offset_top = 8
		preview.offset_bottom = -26
		# Draw-call batching: every card's frame, sprite, shapes and text sit on their own z layer,
		# so the renderer draws all frames, then all sprites, then all shapes, then all text,
		# instead of switching texture/material several times per card.
		preview.z_index = 1
		add_child(preview)
		overlay = CardOverlay.new()
		overlay.card = self
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.z_index = 2
		add_child(overlay)
		text_layer = CardText.new()
		text_layer.card = self
		text_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		text_layer.z_index = 3
		add_child(text_layer)
		mouse_filter = Control.MOUSE_FILTER_STOP
		tooltip_text = String(Registry.entry(unit_id).get("name", unit_id))

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var b: Battle = screen.battle
			if b.deploy(unit_id) == null:
				Audio.play("ui_click", -1, -14.0, 0.3)
			else:
				var tw = create_tween()
				scale = Vector2(0.92, 0.92)
				pivot_offset = size * 0.5
				tw.tween_property(self, "scale", Vector2.ONE, 0.15)
			accept_event()

	func _draw() -> void:
		var b: Battle = screen.battle
		var ready: bool = b.can_deploy(unit_id) == ""
		var cd: float = b.cooldowns.get(unit_id, 0.0)
		var kind = "card_air" if air else "card"
		if ready:
			kind = "card_ready"
		draw_style_box(UiArt.style(kind, 16), Rect2(Vector2.ZERO, size))
		overlay.queue_redraw()
		text_layer.queue_redraw()
		preview.modulate = Color(1, 1, 1) if ready or cd > 0.0 else Color(0.5, 0.5, 0.5)


class CardOverlay extends Control:
	var card

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	## Untextured shapes only (cooldown sweep, cost plate, coin, steam badge): batch across all cards.
	func _draw() -> void:
		var b: Battle = card.screen.battle
		var d: Dictionary = card.def
		var cd: float = b.cooldowns.get(card.unit_id, 0.0)
		var total = float(d.get("cooldown", 1.0))
		if cd > 0.0:
			var k = clampf(cd / total, 0.0, 1.0)
			var c = Vector2(size.x * 0.5, size.y * 0.42)
			var pts = PackedVector2Array([c])
			var n = 18
			for i in n + 1:
				var a = -PI / 2.0 + TAU * k * i / n
				pts.append(c + Vector2.from_angle(a) * 46.0)
			draw_colored_polygon(pts, Color(0, 0, 0, 0.55))
		var g = int(d.get("gold", 0))
		var st = int(d.get("steam", 0))
		var afford = b.gold >= g or b.infinite_gold
		var plate = Rect2(5, size.y - 25, size.x - 10, 20)
		draw_rect(plate, Color(0.05, 0.04, 0.03, 0.85))
		draw_rect(plate, Color(UiKit.BRASS_D, 0.9), false, 1.0)
		UiKit.draw_glyph(self, "coin", Vector2(15, size.y - 15), 7.0, Color("ffd76a") if afford else UiKit.BAD, Color(0, 0, 0, 0.8))
		if st > 0:
			var sc = UiKit.STEAM if b.steam >= st else UiKit.BAD
			UiKit.disc(self, Vector2(size.x - 14, 15), 11.0, Color(0.05, 0.08, 0.1, 0.9))
			UiKit.ring(self, Vector2(size.x - 14, 15), 11.0, Color(sc, 0.9))


## Card text (font atlas only): cooldown seconds, Gold cost, Steam cost.
class CardText extends Control:
	var card

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var b: Battle = card.screen.battle
		var d: Dictionary = card.def
		var cd: float = b.cooldowns.get(card.unit_id, 0.0)
		var f2 = UiKit.bold()
		if cd > 0.0:
			draw_string_outline(f2, Vector2(0, size.y * 0.5), "%d" % int(ceil(cd)), HORIZONTAL_ALIGNMENT_CENTER, size.x, 24, 5, Color(0, 0, 0, 0.9))
			draw_string(f2, Vector2(0, size.y * 0.5), "%d" % int(ceil(cd)), HORIZONTAL_ALIGNMENT_CENTER, size.x, 24, Color(1, 0.95, 0.85))
		var g = int(d.get("gold", 0))
		var st = int(d.get("steam", 0))
		var afford = b.gold >= g or b.infinite_gold
		draw_string(f2, Vector2(24, size.y - 9), "%d" % g, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffd76a") if afford else UiKit.BAD)
		if st > 0:
			var sc = UiKit.STEAM if b.steam >= st else UiKit.BAD
			draw_string(f2, Vector2(size.x - 25, 20), "%d" % st, HORIZONTAL_ALIGNMENT_CENTER, 22, 13, sc)


## Round brass valve button for the battle abilities (glyph, title, status line, cooldown ring).
class ValveButton extends Control:
	var glyph = "gear"
	var title = ""
	var status = ""
	var enabled = true
	var cd_k = 0.0
	var cb: Callable
	var disabled: bool:
		get:
			return not enabled
	var text: String:
		get:
			return title + "\n" + status

	func _init(g: String = "gear", t: String = "", c: Callable = Callable()) -> void:
		glyph = g
		title = t
		cb = c
		custom_minimum_size = Vector2(150, 50)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func setup_state(t: String, s: String, en: bool, k: float) -> void:
		if t != title or s != status or en != enabled or absf(k - cd_k) > 0.01:
			title = t
			status = s
			enabled = en
			cd_k = k
			queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if enabled and cb.is_valid():
				Audio.play("ui_click", -1.0, -6.0)
				cb.call()
			accept_event()

	func _draw() -> void:
		var r = Rect2(Vector2(20, 4), Vector2(size.x - 20, size.y - 8))
		draw_style_box(UiArt.style("btn" if enabled else "btn_disabled", 10), r)
		var c = Vector2(24, size.y * 0.5)
		var rad = size.y * 0.46
		UiKit.disc(self, c, rad + 2.0, Color("120e0b"))
		UiKit.disc(self, c, rad, UiKit.BRASS.darkened(0.1) if enabled else Color("4a443e"))
		UiKit.disc(self, c, rad - 4.0, Color("2a2018") if enabled else Color("2a2522"))
		if cd_k > 0.0:
			draw_arc(c, rad - 2.0, -PI / 2.0, -PI / 2.0 + TAU * (1.0 - cd_k), 20, UiKit.FORGE, 3.0)
		UiKit.draw_glyph(self, glyph, c, rad * 0.62, UiKit.BRASS_L if enabled else Color("7a7064"), Color(0, 0, 0, 0.8))
		var f = UiKit.bold()
		var tc = UiKit.TEXT if enabled else Color("7a7064")
		draw_string(f, Vector2(52, size.y * 0.45), title, HORIZONTAL_ALIGNMENT_LEFT, size.x - 58, 15, tc)
		draw_string(f, Vector2(52, size.y * 0.45 + 17), status, HORIZONTAL_ALIGNMENT_LEFT, size.x - 58, 14, UiKit.FORGE if enabled else Color("6a6058"))


## M006 sky-threat indicator: three tiny rows (high, mid, low) with a pip per hostile flyer (max 8 drawn).
class SkyThreat extends Control:
	var battle: Battle

	func _draw() -> void:
		if battle == null:
			return
		var c: Array = battle.sky_threat()
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.035, 0.03, 0.9))
		var cols = [Color(0.75, 0.85, 0.6), Color(0.6, 0.85, 1.0), Color(1.0, 0.75, 0.9)]
		for row in 3:
			var band = 2 - row
			var y = 4.0 + row * 8.0
			var n: int = c[band]
			draw_rect(Rect2(1, y, 3, 5), cols[band] if n > 0 else Color(0.25, 0.22, 0.2))
			var pips = mini(n, 8)
			if pips > 0:
				var pts = PackedVector2Array()
				for k in pips:
					pts.append_array([Vector2(7 + k * 3.3, y + 2.5), Vector2(9 + k * 3.3, y + 2.5)])
				draw_multiline(pts, cols[band], 4.0)


## M006 escort health: a thin airship-coloured bar; red and empty once the barge is lost, gold when delivered.
class EscortBar extends Control:
	var battle: Battle

	func _draw() -> void:
		if battle == null:
			return
		var f = clampf(battle.escort_frac(), 0.0, 1.0)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.035, 0.03, 0.9))
		var col = Color("e8cf8a") if battle.escort_state != "delivered" else Color("ffe08a")
		if battle.escort_state == "lost":
			col = Color(0.8, 0.25, 0.2)
			f = 1.0
		draw_rect(Rect2(1, 1, (size.x - 2) * f, size.y - 2), col)


class Minimap extends Control:
	var battle: Battle
	var screen

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		if (event is InputEventMouseButton and event.pressed) or (event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT):
			screen.cam.position.x = event.position.x / size.x * Combat.WORLD_W
			accept_event()

	func _draw() -> void:
		var r = Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(0.04, 0.035, 0.03, 0.9))
		var sx = size.x / Combat.WORLD_W
		var gy = size.y * 0.78
		draw_line(Vector2(0, gy), Vector2(size.x, gy), Color(0.4, 0.33, 0.25), 1.0)
		for u in battle.units:
			if not u.alive or u.burrowed:
				continue
			var x: float = u.position.x * sx
			var y = gy - 3.0 if u.domain == "ground" else size.y * (0.12 + 0.5 * (u.position.y - 150.0) / 300.0)
			var c = Color(0.45, 0.7, 1.0) if u.side == 0 else Color(0.55, 0.95, 0.45)
			if u.is_boss:
				c = Color(1.0, 0.4, 0.5)
			if u.is_stronghold:
				draw_rect(Rect2(x - 3, gy - 12, 6, 12), c)
			else:
				draw_rect(Rect2(x - 1, y - 1, 3 if u.radius < 20 else 5, 3), c)
		# M007 wrecks: small brass cogs; a wreck being reclaimed pulses green
		for w in battle.wrecks:
			var wx = float(w.x) * sx
			var chan = w.chan != null
			var pul = 0.5 + 0.5 * sin(battle.time * 12.0)
			if chan:
				draw_circle(Vector2(wx, gy - 9.0), 7.0 + 2.0 * pul, Color(0.43, 1.0, 0.55, 0.25 + 0.3 * pul))
			Painter.cog(self, Vector2(wx, gy - 9.0), 4.5, Color(0.5, 1.0, 0.55) if chan else Color(0.9, 0.75, 0.45), 6)
		var vr: Rect2 = battle.view_rect
		draw_rect(Rect2(vr.position.x * sx, 1, vr.size.x * sx, size.y - 2), UiKit.BRASS_L, false, 1.5)
