extends Control
## Stage select (M004): the act is a living cross-section of the realm (RealmMap): drag through
## it, tap a landmark, and the stage dossier slides in on a brass drawer (environment preview,
## known enemy lineup, boss, spoils, army strip, Deploy). Planned stages are shown honestly as
## planned; uncleared stages don't spoil their enemy lineup.

var act := 1
var realm: RealmMap
var detail: VBoxContainer
var act_tabs: TabBar
var selected := ""
var actions: VBoxContainer
var drawer: PanelContainer
var drawer_open := true
var _handle: Button
var _hint: Label
const DRAWER_W := 410.0


func _ready() -> void:
	theme = UiKit.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(Widgets.Backdrop.new())
	var mc = UiKit.root_margin(self, 14)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	mc.add_child(v)
	var bar = UiKit.title_bar(v, "Campaign", func(): GameState.goto("menu"))
	var cleared = 0
	for s in Registry.stages:
		if GameState.is_cleared(s.id):
			cleared += 1
	var n_impl = Registry.stages.filter(func(x): return x.implemented).size()
	var sp = UiKit.pill("star", "%d/%d · %d stars" % [cleared, n_impl, GameState.total_stars()], UiKit.GOOD)
	sp.tooltip_text = "Stages cleared · stars earned (of %d)" % (3 * n_impl)
	bar.add_child(sp)
	bar.add_child(UiKit.pill("spark", str(GameState.profile.sparks), UiKit.FORGE))
	act_tabs = TabBar.new()
	for a in 5:
		var st = Registry.stage_by_index(a * 30 + 1)
		act_tabs.add_tab("Act %s · %s" % ["I II III IV V".split(" ")[a], st.get("act_name", "")])
	v.add_child(act_tabs)
	var map_frame = UiKit.plate("panel", Vector4(8, 8, 8, 8))
	map_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(map_frame)
	var stack = Control.new()
	stack.clip_contents = true
	map_frame.add_child(stack)
	realm = RealmMap.new()
	realm.set_anchors_preset(Control.PRESET_FULL_RECT)
	stack.add_child(realm)
	_hint = UiKit.label("Drag to explore the front  ·  tap a landmark", 15, Color(1, 0.95, 0.85, 0.85))
	_hint.add_theme_constant_override("outline_size", 6)
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_hint.position = Vector2(18, 12)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(_hint)
	# the dossier drawer
	drawer = UiKit.plate("panel", Vector4(18, 16, 18, 14))
	drawer.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	drawer.offset_left = -DRAWER_W
	drawer.offset_right = 0
	stack.add_child(drawer)
	var pv = VBoxContainer.new()
	drawer.add_child(pv)
	var sc = ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pv.add_child(sc)
	actions = VBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	pv.add_child(actions)
	detail = VBoxContainer.new()
	detail.add_theme_constant_override("separation", 8)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(detail)
	_handle = UiKit.button("", _toggle_drawer, Vector2(40, 84))
	_handle.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	stack.add_child(_handle)
	var hg = UiKit.Glyph.new("play", 18, UiKit.BRASS_L)
	hg.name = "G"
	hg.position = Vector2(11, 33)
	_handle.add_child(hg)
	selected = _default_stage()
	act = int(Registry.stage(selected).get("act", 1))
	act_tabs.current_tab = act - 1
	act_tabs.tab_changed.connect(func(i):
		act = i + 1
		Audio.play("ui_click", -1, -8)
		_build_map())
	realm.stage_selected.connect(func(id):
		selected = id
		_show_detail(id)
		if not drawer_open:
			_toggle_drawer())
	stack.resized.connect(_place_drawer)
	call_deferred("_build_map")
	_show_detail(selected)
	Audio.play_music("menu")


func _place_drawer() -> void:
	var w = drawer.get_parent().size.x
	drawer.offset_left = -DRAWER_W if drawer_open else 0.0
	drawer.offset_right = 0.0 if drawer_open else DRAWER_W
	_handle.position = Vector2(w - (DRAWER_W if drawer_open else 0.0) - 44.0, drawer.get_parent().size.y * 0.5 - 42.0)
	realm.drawer_w = DRAWER_W if drawer_open else 0.0
	var g = _handle.get_node_or_null("G")
	if g:
		g.kind = "play" if drawer_open else "back"
		g.queue_redraw()


func _toggle_drawer() -> void:
	drawer_open = not drawer_open
	Audio.play("ui_click", -1, -8)
	var w = drawer.get_parent().size.x
	var tw = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(drawer, "offset_left", -DRAWER_W if drawer_open else 0.0, 0.28)
	tw.tween_property(drawer, "offset_right", 0.0 if drawer_open else DRAWER_W, 0.28)
	tw.tween_property(_handle, "position:x", w - (DRAWER_W if drawer_open else 0.0) - 44.0, 0.28)
	realm.drawer_w = DRAWER_W if drawer_open else 0.0
	var g = _handle.get_node_or_null("G")
	if g:
		g.kind = "play" if drawer_open else "back"
		g.queue_redraw()


func _default_stage() -> String:
	if GameState.selected_stage != "" and Registry.stage(GameState.selected_stage).get("implemented", false) and GameState.stage_available(Registry.stage(GameState.selected_stage)) and not GameState.is_cleared(GameState.selected_stage):
		return GameState.selected_stage
	for s in Registry.stages:
		if s.implemented and GameState.stage_available(s) and not GameState.is_cleared(s.id):
			return s.id
	return "s001"


func _build_map() -> void:
	_place_drawer()
	var sel = selected if int(Registry.stage(selected).get("act", 1)) == act else ""
	realm.setup(act, sel)
	if sel != "":
		var i = realm._index_of(sel)
		if i >= 0:
			realm.focus(i)
	# entrance: the map rises in
	realm.modulate.a = 0.0
	create_tween().tween_property(realm, "modulate:a", 1.0, 0.35)
	_maybe_reveal_act()
	if _hint:
		_hint.modulate.a = 1.0
		create_tween().tween_property(_hint, "modulate:a", 0.0, 1.2).set_delay(4.0)


func _show_detail(stage_id: String) -> void:
	for c in detail.get_children():
		c.queue_free()
	for c2 in actions.get_children():
		c2.queue_free()
	var st = Registry.stage(stage_id)
	if st.is_empty():
		return
	var head = HBoxContainer.new()
	detail.add_child(head)
	var hv = VBoxContainer.new()
	hv.add_theme_constant_override("separation", 0)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hv)
	hv.add_child(UiKit.label("STAGE %03d  ·  ACT %d" % [int(st.index), int(st.act)], 14, UiKit.TEXT_DIM))
	var name_l = UiKit.label(st.get("name", "?"), 26, UiKit.BRASS_L)
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hv.add_child(name_l)
	if GameState.is_cleared(st.id):
		head.add_child(UiKit.Glyph.new("star", 34, UiKit.GOOD))
	if st.get("boss") != null and not GameState.is_cleared(st.id):
		head.add_child(UiKit.Glyph.new("crown", 34, UiKit.BOSS))
	var prev = EnvPreview.new()
	prev.env = String(st.get("env", "mountain_gate"))
	prev.custom_minimum_size = Vector2(0, 70)
	prev.boss = st.get("boss") != null
	detail.add_child(prev)
	if not st.implemented:
		detail.add_child(UiKit.label("PLANNED — scheduled for %s" % st.get("milestone", "a later milestone"), 16, UiKit.BAD))
		var info = UiKit.label("Environment: %s\nTheme: %s\nTech tier: %s" % [_pretty(st.env), _pretty(st.theme), st.tech_tier], 15, UiKit.TEXT_DIM)
		detail.add_child(info)
		return
	var tag = UiKit.label(String(st.get("tagline", "")), 15, UiKit.TEXT)
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag.custom_minimum_size = Vector2(340, 0)
	detail.add_child(tag)
	# M005 stars: victory · stronghold held above 50 % · challenge objective
	var srow = HBoxContainer.new()
	srow.add_theme_constant_override("separation", 8)
	var sv: Array = GameState.stars_for(st.id)
	var stars = StarRow.new()
	stars.lit = sv
	stars.custom_minimum_size = Vector2(78, 26)
	srow.add_child(stars)
	var ch: Dictionary = st.get("challenge", {}) if st.get("challenge") != null else {}
	var cl = UiKit.label(String(ch.get("text", "—")), 14, UiKit.GOOD if bool(sv[2]) else UiKit.TEXT_DIM)
	srow.tooltip_text = "Stars: win · keep the stronghold above 50% · challenge: " + String(ch.get("text", ""))
	cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	srow.add_child(cl)
	detail.add_child(srow)
	# M007 Heroic difficulty: every cleared stage unlocks a Heroic version (smarter, not bigger)
	if not GameState.heroic_available(st.id) and GameState.selected_heroic and GameState.selected_stage == st.id:
		GameState.selected_heroic = false
	if GameState.heroic_available(st.id):
		var hrow = HBoxContainer.new()
		hrow.add_theme_constant_override("separation", 8)
		var tog = HeroicToggle.new()
		tog.on = GameState.selected_heroic and GameState.selected_stage == st.id
		tog.custom_minimum_size = Vector2(150, 40)
		tog.tooltip_text = "Heroic: the same stage, played smarter — an extra set piece, tighter waves, one more support structure, enemy abilities ready sooner, at most +15% enemy HP. Separate stars; a modest Spark payout on the first Heroic clear."
		tog.toggled.connect(func(on):
			GameState.selected_stage = st.id
			GameState.selected_heroic = on
			_show_detail(st.id))
		hrow.add_child(tog)
		var hs = StarRow.new()
		hs.lit = GameState.heroic_stars(st.id)
		hs.heroic = true
		hs.custom_minimum_size = Vector2(78, 26)
		hs.tooltip_text = "Heroic stars (tracked separately)"
		hrow.add_child(hs)
		detail.add_child(hrow)
		if tog.on:
			var hb: Dictionary = st.get("heroic", {})
			var mods: Array = ["one extra set piece at %d:%02d" % [int(hb.get("event", {}).get("t", 0)) / 60, int(hb.get("event", {}).get("t", 0)) % 60],
				"waves come %d%% faster" % int(round((1.0 / float(hb.get("interval_mult", 0.85)) - 1.0) * 100.0)),
				"+1 %s" % Registry.entry(String(hb.get("structure", {}).get("enemy", ""))).get("name", "support structure"),
				"enemy abilities ready sooner", "+%d%% enemy HP" % int(round((float(hb.get("hp_mult", 1.12)) - 1.0) * 100.0))]
			var first = not GameState.heroic_cleared(st.id)
			mods.append(("first Heroic clear: +%d Sparks" % int(hb.get("spark_bonus", 0))) if first else "cleared on Heroic ×%d" % int(GameState.profile.heroic[st.id].get("clears", 1)))
			var ml = UiKit.label("Heroic: " + " · ".join(mods), 13, Color("e8a070"))
			ml.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			ml.custom_minimum_size = Vector2(340, 0)
			detail.add_child(ml)
	var facts = HBoxContainer.new()
	facts.add_child(UiKit.pill("skull", "Citadel %d" % int(st.enemy_base_hp), Color("c0a0d8")))
	var hz: Array = WaveDirector.hazard_list(st)
	for h in hz:
		facts.add_child(UiKit.pill("flame", Hints.hazard_name(h), UiKit.FORGE))
	detail.add_child(facts)
	if not hz.is_empty():
		var lines: Array = []
		for h2 in hz:
			lines.append("%s: %s" % [Hints.hazard_name(h2), Hints.hazard_desc(h2)])
		var hl = UiKit.label("\n".join(lines), 13, UiKit.TEXT_DIM)
		hl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hl.custom_minimum_size = Vector2(340, 0)
		detail.add_child(hl)
	var known = GameState.is_cleared(st.id)
	# M006: the escort objective, with an airship icon
	if st.get("escort") != null:
		var eh = HBoxContainer.new()
		eh.add_theme_constant_override("separation", 6)
		eh.add_child(UiKit.Glyph.new("airship", 22, Color("e8cf8a")))
		var esc: Dictionary = st.escort
		var el = UiKit.label("Escort: a supply barge sets out at %d:%02d — bring it across for the third star" % [int(esc.t) / 60, int(esc.t) % 60], 13, Color("e8cf8a"))
		el.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		el.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		eh.add_child(el)
		detail.add_child(eh)
	# M006: the altitude bands its known flyers use (cleared stages only)
	if known:
		var bands = {}
		for e0 in st.get("enemy_roster", []):
			var b0 = Hints.band_of(Registry.combat_def(String(e0)))
			if b0 != "":
				bands[b0] = int(bands.get(b0, 0)) + 1
		if st.get("boss") != null:
			var bb = Hints.band_of(Registry.combat_def(String(st.boss)))
			if bb != "":
				bands[bb] = int(bands.get(bb, 0)) + 1
		if not bands.is_empty():
			var parts: Array = []
			for bn in Hints.BAND_NAMES:
				if bands.has(bn):
					parts.append("%s ×%d" % [bn, int(bands[bn])])
			var bl = UiKit.label("Sky bands: " + " · ".join(parts), 13, Color("9fc8ec"))
			bl.tooltip_text = "Low: rifles and flak reach them · Mid: flak, AA and aircraft · High: only flak, AA guns, interceptors and airships"
			bl.mouse_filter = Control.MOUSE_FILTER_PASS
			detail.add_child(bl)
	detail.add_child(UiKit.heading("Enemy lineup", UiKit.UNDEAD))
	var grid = GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	detail.add_child(grid)
	var roster: Array = st.get("enemy_roster", [])
	for e in roster.slice(0, 12):
		var cell = UiKit.plate("slot", Vector4(3, 3, 3, 3))
		cell.custom_minimum_size = Vector2(56, 56)
		if known or e in GameState.profile.get("encountered", []):
			var pv = Widgets.UnitPreview.new(Registry.combat_def(e).get("art", e), "undead")
			pv.custom_minimum_size = Vector2(48, 48)
			pv.tooltip_text = Registry.entry(e).get("name", e)
			cell.add_child(pv)
		else:
			var q = UiKit.label("?", 26, Color("6a6058"), HORIZONTAL_ALIGNMENT_CENTER)
			q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			cell.add_child(q)
		grid.add_child(cell)
	if not known:
		grid.tooltip_text = "Lineup revealed once cleared (or encountered)."
	else:
		# recommended counters: cleared stages only, so nothing is spoiled
		var rec: Array = Hints.stage_counters(st, 3)
		if not rec.is_empty():
			detail.add_child(UiKit.heading("Recommended counters", UiKit.GOOD))
			var rl = UiKit.label("\n".join(rec.map(func(r): return "• " + String(r))), 14, UiKit.TEXT)
			rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			rl.custom_minimum_size = Vector2(340, 0)
			detail.add_child(rl)
	if st.get("boss") != null:
		var bh = HBoxContainer.new()
		bh.add_child(UiKit.Glyph.new("crown", 22, UiKit.BOSS))
		bh.add_child(UiKit.label("Boss: %s" % (Registry.entry(st.boss).get("name", st.boss) if known else "Something vast waits"), 17, UiKit.BOSS))
		detail.add_child(bh)
	detail.add_child(UiKit.heading("First-clear spoils", UiKit.FORGE))
	var rw: Dictionary = st.get("rewards", {})
	var rh = HBoxContainer.new()
	rh.add_child(UiKit.pill("spark", "%d Sparks" % int(rw.get("sparks", 0)), UiKit.FORGE))
	for u in rw.get("unlock", []):
		var pv2 = Widgets.UnitPreview.new(Registry.combat_def(u).get("art", u), "dwarf")
		pv2.custom_minimum_size = Vector2(44, 44)
		pv2.tooltip_text = "Blueprint: " + Registry.entry(u).get("name", u)
		rh.add_child(pv2)
	detail.add_child(rh)
	if rw.has("open_tier"):
		detail.add_child(UiKit.label("Opens research: %s" % Registry.TIER_NAMES[int(rw.open_tier)], 15, UiKit.BRASS_L))
	if GameState.is_cleared(st.id):
		var c: Dictionary = GameState.profile.cleared[st.id]
		detail.add_child(UiKit.label("Cleared ×%d  ·  best %d:%02d" % [int(c.get("clears", 1)), int(c.get("best_time", 0)) / 60, int(c.get("best_time", 0)) % 60], 15, UiKit.GOOD))
	detail.add_child(UiKit.heading("Army: " + String(GameState.profile.active_preset)))
	var lo_row = HBoxContainer.new()
	lo_row.add_theme_constant_override("separation", 2)
	var lo = GameState.active_loadout()
	for u2 in lo:
		var cell2 = UiKit.plate("slot", Vector4(2, 2, 2, 2))
		cell2.custom_minimum_size = Vector2(28, 30)
		if u2 != "":
			var pv3 = Widgets.UnitPreview.new(Registry.combat_def(u2).get("art", u2), "dwarf")
			pv3.custom_minimum_size = Vector2(24, 26)
			cell2.add_child(pv3)
		lo_row.add_child(cell2)
	detail.add_child(lo_row)
	var avail = GameState.stage_available(st)
	var lo_count = lo.filter(func(x): return x != "").size()
	var heroic_on = GameState.selected_heroic and GameState.selected_stage == st.id and GameState.heroic_available(st.id)
	var start = UiKit.primary(("Deploy — Heroic" if heroic_on else "Deploy the Army") if avail else "Locked — clear the previous stage", func():
		GameState.selected_stage = st.id
		GameState.selected_heroic = heroic_on
		GameState.goto("battle"), Vector2(0, 64), 22)
	start.disabled = not avail or lo_count == 0
	actions.add_child(start)
	if lo_count == 0:
		actions.add_child(UiKit.label("Your loadout is empty.", 15, UiKit.BAD))
	actions.add_child(UiKit.button("Edit Loadout", func(): GameState.goto("loadout"), Vector2(0, 46), 18))


## M005: the first time an act is unlocked, a title cartouche rises over the map (once per act).
func _maybe_reveal_act() -> void:
	if act <= 1 or act in GameState.profile.acts_revealed:
		return
	var first = Registry.stage_by_index((act - 1) * 30 + 1)
	if first.is_empty() or not GameState.stage_available(first):
		return
	GameState.profile.acts_revealed.append(act)
	GameState.save()
	var cart = UiKit.banner("ACT %s  ·  %s" % ["I II III IV V".split(" ")[act - 1], String(first.get("act_name", ""))], 30, 520)
	cart.set_anchors_preset(Control.PRESET_CENTER)
	cart.grow_horizontal = Control.GROW_DIRECTION_BOTH
	cart.grow_vertical = Control.GROW_DIRECTION_BOTH
	cart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	realm.get_parent().add_child(cart)
	cart.pivot_offset = cart.get_combined_minimum_size() * 0.5
	cart.modulate.a = 0.0
	cart.scale = Vector2(0.8, 0.8)
	var tw = create_tween()
	tw.tween_interval(0.4)
	tw.tween_callback(func(): Audio.play("boss_sting", -1, -6.0, 0.0))
	tw.tween_property(cart, "modulate:a", 1.0, 0.5)
	tw.parallel().tween_property(cart, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.2)
	tw.tween_property(cart, "modulate:a", 0.0, 0.7)
	tw.tween_callback(cart.queue_free)


func _pretty(s) -> String:
	return String(s).replace("_", " ").capitalize()


# ================================================================== widgets
## Small painted preview of a stage's environment.
class EnvPreview extends Control:
	var env = "mountain_gate"
	var boss = false

	func _draw() -> void:
		var e: Dictionary = BattleBackground.ENVS.get(env, BattleBackground.ENVS.mountain_gate)
		var sky: Array = e.sky
		var w = size.x
		var h = size.y
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h * 0.75), Vector2(0, h * 0.75)]),
			PackedColorArray([Color(sky[0]), Color(sky[0]), Color(sky[2]), Color(sky[2])]))
		var rng = RandomNumberGenerator.new()
		rng.seed = hash(env)
		var far = Color(e.far)
		var mid = Color(e.mid)
		var pts = PackedVector2Array([Vector2(0, h)])
		var x = 0.0
		while x <= w:
			pts.append(Vector2(x, h * rng.randf_range(0.3, 0.55)))
			x += rng.randf_range(30, 60)
		pts.append(Vector2(w, h))
		draw_colored_polygon(pts, far)
		var pts2 = PackedVector2Array([Vector2(0, h)])
		x = 0.0
		while x <= w:
			pts2.append(Vector2(x, h * rng.randf_range(0.55, 0.7)))
			x += rng.randf_range(24, 44)
		pts2.append(Vector2(w, h))
		draw_colored_polygon(pts2, mid)
		draw_rect(Rect2(0, h * 0.78, w, h * 0.22), Color(e.ground))
		if boss:
			draw_circle(Vector2(w * 0.78, h * 0.42), h * 0.22, Color(0.6, 0.2, 0.5, 0.35))
			UiKit.draw_glyph(self, "skull", Vector2(w * 0.78, h * 0.42), h * 0.16, Color(0.9, 0.8, 0.95), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(Vector2.ZERO, size), Color("120e0b"), false, 3.0)
		draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), UiKit.BRASS_D, false, 1.5)



## Three brass stars in one control (one batched draw instead of three glyph controls).
class StarRow extends Control:
	var lit: Array = [false, false, false]
	var heroic = false          # M007: Heroic stars are blood-red with a gold rim

	func _draw() -> void:
		for i in 3:
			var on = bool(lit[i])
			var col = (Color("d8323a") if heroic else UiKit.FORGE) if on else Color(0.3, 0.27, 0.24)
			if heroic and on:
				UiKit.draw_glyph(self, "star", Vector2(12 + i * 26, size.y * 0.5), 12.5, UiKit.BRASS_L, Color(0, 0, 0, 0.6))
			UiKit.draw_glyph(self, "star", Vector2(12 + i * 26, size.y * 0.5), 11.0 if not (heroic and on) else 9.5, col, Color(0, 0, 0, 0.6))


## M007: the Heroic switch — brass and blood. Tap to toggle.
class HeroicToggle extends Control:
	signal toggled(on: bool)
	var on = false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			on = not on
			queue_redraw()
			Audio.play("ui_click", -1, -8)
			toggled.emit(on)
			accept_event()

	func _draw() -> void:
		var r = Rect2(Vector2(1, 2), size - Vector2(2, 4))
		var fill = Color("7a1418") if on else Color("2a1c18")
		draw_rect(r, Color("120e0b"))
		draw_rect(r.grow(-2), fill)
		if on:
			draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, r.size.y * 0.4)), Color(1, 0.5, 0.4, 0.12))
		draw_rect(r.grow(-2), UiKit.BRASS if on else UiKit.BRASS_D, false, 2.0)
		# a little pilot light: lit red-gold when on
		var lc = Vector2(18, size.y * 0.5)
		draw_circle(lc, 8.0, Color("120e0b"))
		draw_circle(lc, 6.0, Color("ffcf5a") if on else Color("4a3a2a"))
		if on:
			draw_circle(lc, 3.0, Color("d8323a"))
		var f = UiKit.bold()
		draw_string(f, Vector2(32, size.y * 0.5 + 6), "HEROIC" if on else "Heroic: off", HORIZONTAL_ALIGNMENT_LEFT, size.x - 36, 17, UiKit.BRASS_L if on else UiKit.TEXT_DIM)
