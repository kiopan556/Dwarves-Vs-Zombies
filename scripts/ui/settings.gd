extends Control
## Settings: audio volumes, graphics quality (60 FPS / 30 FPS performance mode), screen shake,
## default battle speed, progress reset.

var confirm_reset := false
var reset_btn: Button


func _ready() -> void:
	theme = UiKit.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(Widgets.Backdrop.new())
	var mc = UiKit.root_margin(self, 24)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	mc.add_child(v)
	UiKit.title_bar(v, "Settings", func(): GameState.goto("menu"))
	var pc = UiKit.plate("panel", Vector4(30, 22, 30, 24))
	pc.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pc.custom_minimum_size = Vector2(780, 0)
	v.add_child(pc)
	var pv = VBoxContainer.new()
	pv.add_theme_constant_override("separation", 10)
	pc.add_child(pv)
	pv.add_child(UiKit.heading("Sound"))
	var g = GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 24)
	g.add_theme_constant_override("v_separation", 14)
	pv.add_child(g)
	for k in [["master", "Master volume"], ["music", "Music"], ["sfx", "Sound effects"]]:
		g.add_child(UiKit.label(k[1], 20))
		var s = HSlider.new()
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.05
		s.value = float(GameState.setting(k[0]))
		s.custom_minimum_size = Vector2(360, 40)
		var key: String = k[0]
		s.value_changed.connect(func(val): GameState.set_setting(key, val))
		g.add_child(s)
	pv.add_child(UiKit.heading("Graphics & Battle"))
	g = GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 24)
	g.add_theme_constant_override("v_separation", 14)
	pv.add_child(g)
	g.add_child(UiKit.label("Graphics quality", 20))
	var q = OptionButton.new()
	q.add_item("High — live animation, 60 FPS (desktop / strong phones)")
	q.add_item("Balanced — baked sprites, 60 FPS cap")
	q.add_item("Performance — baked sprites, 30 FPS, fewer particles (low-end phones)")
	q.selected = ["high", "balanced", "low"].find(GameState.quality())
	q.custom_minimum_size = Vector2(360, 52)
	q.item_selected.connect(func(i): GameState.set_setting("quality", ["high", "balanced", "low"][i]))
	g.add_child(q)
	g.add_child(UiKit.label("Screen shake", 20))
	var sh = CheckButton.new()
	sh.button_pressed = bool(GameState.setting("shake"))
	sh.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	sh.toggled.connect(func(on): GameState.set_setting("shake", on))
	g.add_child(sh)
	g.add_child(UiKit.label("Default battle speed", 20))
	var sp = OptionButton.new()
	sp.add_item("1×")
	sp.add_item("2×")
	sp.selected = 1 if float(GameState.setting("speed")) > 1.5 else 0
	sp.custom_minimum_size = Vector2(160, 52)
	sp.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	sp.item_selected.connect(func(i): GameState.set_setting("speed", 2.0 if i == 1 else 1.0))
	g.add_child(sp)
	g.add_child(UiKit.label("Guided tutorial (stages 1–3)", 20))
	var tu = CheckButton.new()
	tu.button_pressed = bool(GameState.setting("tutorial"))
	tu.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	tu.toggled.connect(func(on):
		GameState.set_setting("tutorial", on)
		if on:
			GameState.profile.tutorial_done = []   # switching it back on replays the guidance
			GameState.save())
	g.add_child(tu)
	g.add_child(UiKit.label("First-encounter hints", 20))
	var hi = CheckButton.new()
	hi.button_pressed = bool(GameState.setting("hints"))
	hi.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	hi.toggled.connect(func(on): GameState.set_setting("hints", on))
	g.add_child(hi)
	g.add_child(UiKit.label("Unit motion (lean, recoil, sway)", 20))
	var mo = CheckButton.new()
	mo.button_pressed = bool(GameState.setting("motion"))
	mo.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	mo.tooltip_text = "Switch off for reduced motion: units keep their animations but stop leaning, bouncing and swaying."
	mo.toggled.connect(func(on):
		GameState.set_setting("motion", on)
		GameState.apply_settings())
	g.add_child(mo)
	g.add_child(UiKit.label("Button sounds", 20))
	var bs = CheckButton.new()
	bs.button_pressed = bool(GameState.setting("ui_sounds"))
	bs.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bs.tooltip_text = "Off by default: tapping buttons and cards is silent. On: a soft felted tick (never the old metallic clink)."
	bs.toggled.connect(func(on): GameState.set_setting("ui_sounds", on))
	g.add_child(bs)
	pv.add_child(UiKit.heading("Progress", UiKit.BAD))
	g = GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 24)
	pv.add_child(g)
	g.add_child(UiKit.label("Reset campaign", 20))
	var prow = HBoxContainer.new()
	prow.add_theme_constant_override("separation", 10)
	reset_btn = UiKit.danger("Reset all progress", _reset, Vector2(240, 52), 18)
	prow.add_child(reset_btn)
	# M008: replay the ending (and credits) once the Black Rift has been sealed
	var rp = UiKit.button("Replay ending" if GameState.rift_sealed() else "Replay ending (seal the Rift first)", func():
		GameState.ending_credits_only = false
		GameState.goto("ending"), Vector2(240, 52), 16)
	rp.disabled = not GameState.rift_sealed()
	prow.add_child(rp)
	g.add_child(prow)
	var stats: Dictionary = GameState.profile.stats
	v.add_child(UiKit.label("Victories %d · Defeats %d · Undead destroyed %d · Save: %s" % [int(stats.victories), int(stats.defeats), int(stats.kills), ProjectSettings.globalize_path(SaveManager.path)], 14, UiKit.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UiKit.label("Dwarves vs Zombies %s · Godot %s" % [ProjectSettings.get_setting("application/config/version"), Engine.get_version_info().string], 14, UiKit.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))


func _reset() -> void:
	if not confirm_reset:
		confirm_reset = true
		reset_btn.text = "Tap again to confirm reset"
		return
	GameState.reset_progress()
	reset_btn.text = "Progress reset"
	confirm_reset = false
