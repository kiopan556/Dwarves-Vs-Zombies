extends Control
## Army Loadout — "war rack": 12 riveted sockets (7 ground, 4 air, 1 flexible), a filterable
## armoury of every dwarven unit (160), and a dossier plate for the selected unit.
## No hero slot. Three saved presets. Touch flow: tap a unit to auto-place it, or tap a unit
## then a socket; tap a filled socket to clear it.

var slots_box: HBoxContainer
var roster_grid: GridContainer
var info: RichTextLabel
var picked := ""
var preset_tabs: TabBar
var branch_tabs: TabBar
var only_unlocked := false
var branch := ""
var count_pill: PanelContainer
var portrait: Widgets.UnitPreview
var name_l: Label
var sub_l: Label
var stat_grid: GridContainer
var variant_box: HBoxContainer
var _cards := {}          # unit id -> card Button
var _shown := ""          # unit id in the dossier

const BRANCHES := ["", "A", "B", "C", "D", "E", "F", "G"]
const BRANCH_SHORT := {"": "All", "A": "Infantry", "B": "Engineers", "C": "Artillery", "D": "Armour", "E": "Walkers", "F": "Aircraft", "G": "Airships"}


func _ready() -> void:
	theme = UiKit.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(Widgets.Backdrop.new())
	var mc = UiKit.root_margin(self, 14)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	mc.add_child(v)
	var bar = UiKit.title_bar(v, "Army Loadout", func(): GameState.goto("menu"))
	count_pill = UiKit.pill("shield", "", UiKit.BRASS_L)
	bar.add_child(count_pill)
	var go = UiKit.primary("Campaign", func(): GameState.goto("campaign"), Vector2(170, 56), 20)
	bar.add_child(go)

	# ---- war rack: presets + sockets
	var rack = UiKit.plate("panel", Vector4(16, 10, 16, 12))
	v.add_child(rack)
	var rv = VBoxContainer.new()
	rv.add_theme_constant_override("separation", 6)
	rack.add_child(rv)
	var top = HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	rv.add_child(top)
	var ph = UiKit.label("PRESET", 14, UiKit.BRASS)
	ph.add_theme_font_override("font", UiKit.bold())
	top.add_child(ph)
	preset_tabs = TabBar.new()
	preset_tabs.clip_tabs = false
	var names: Array = GameState.profile.loadouts.keys()
	for n in names:
		preset_tabs.add_tab(n)
	preset_tabs.current_tab = maxi(0, names.find(GameState.profile.active_preset))
	preset_tabs.tab_changed.connect(func(i):
		GameState.profile.active_preset = names[i]
		GameState.save()
		Audio.play("ui_click", -1, -6)
		_refresh())
	top.add_child(preset_tabs)
	var sp = Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	top.add_child(UiKit.label("No hero slot — you command the army.", 14, UiKit.TEXT_DIM))
	var tog = CheckButton.new()
	tog.text = "Unlocked only"
	tog.add_theme_font_size_override("font_size", 15)
	tog.toggled.connect(func(on):
		only_unlocked = on
		_build_roster())
	top.add_child(tog)
	slots_box = HBoxContainer.new()
	slots_box.add_theme_constant_override("separation", 6)
	slots_box.alignment = BoxContainer.ALIGNMENT_CENTER
	rv.add_child(slots_box)

	# ---- armoury + dossier
	var h = HBoxContainer.new()
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)
	var armoury = UiKit.plate("panel_dark", Vector4(12, 10, 12, 10))
	armoury.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(armoury)
	var av = VBoxContainer.new()
	av.add_theme_constant_override("separation", 8)
	armoury.add_child(av)
	var fr = HBoxContainer.new()
	fr.add_theme_constant_override("separation", 10)
	av.add_child(fr)
	branch_tabs = TabBar.new()
	branch_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	branch_tabs.clip_tabs = false
	for b in BRANCHES:
		branch_tabs.add_tab(BRANCH_SHORT[b])
	branch_tabs.tab_changed.connect(func(i):
		branch = BRANCHES[i]
		Audio.play("ui_click", -1, -8)
		_build_roster())
	branch_tabs.add_theme_font_size_override("font_size", 15)
	fr.add_child(branch_tabs)
	var sc = ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	av.add_child(sc)
	roster_grid = GridContainer.new()
	roster_grid.columns = 7
	roster_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roster_grid.add_theme_constant_override("h_separation", 6)
	roster_grid.add_theme_constant_override("v_separation", 6)
	sc.add_child(roster_grid)

	var pc = UiKit.plate("panel", Vector4(16, 14, 16, 14))
	pc.custom_minimum_size = Vector2(360, 0)
	h.add_child(pc)
	var ib = VBoxContainer.new()
	ib.add_theme_constant_override("separation", 6)
	pc.add_child(ib)
	var frame = PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiArt.style("slot", 8, Vector4(4, 4, 4, 4)))
	frame.custom_minimum_size = Vector2(0, 118)
	ib.add_child(frame)
	portrait = Widgets.UnitPreview.new("", "dwarf", true)
	frame.add_child(portrait)
	name_l = UiKit.label("Select a unit", 22, UiKit.BRASS_L)
	name_l.add_theme_font_override("font", UiKit.bold())
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ib.add_child(name_l)
	sub_l = UiKit.label("Tap a unit to place it in the first fitting socket. Tap a filled socket to clear it.", 14, UiKit.TEXT_DIM)
	sub_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ib.add_child(sub_l)
	stat_grid = GridContainer.new()
	stat_grid.columns = 4
	stat_grid.add_theme_constant_override("h_separation", 10)
	ib.add_child(stat_grid)
	info = RichTextLabel.new()
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info.bbcode_enabled = true
	info.add_theme_font_size_override("normal_font_size", 15)
	ib.add_child(info)
	variant_box = HBoxContainer.new()
	variant_box.add_theme_constant_override("separation", 6)
	ib.add_child(variant_box)
	_build_roster()
	_refresh()


# ------------------------------------------------------------------ sockets
func _refresh() -> void:
	for c in slots_box.get_children():
		c.queue_free()
	var lo = GameState.active_loadout()
	var groups = [["GROUND", 0, GameState.GROUND_SLOTS, "shield"], ["AIR", GameState.GROUND_SLOTS, GameState.AIR_SLOTS, "wing"], ["FLEX", GameState.GROUND_SLOTS + GameState.AIR_SLOTS, GameState.SLOT_COUNT - GameState.GROUND_SLOTS - GameState.AIR_SLOTS, "gear"]]
	var filled = 0
	for g in groups:
		var gv = VBoxContainer.new()
		gv.add_theme_constant_override("separation", 2)
		var gh = HBoxContainer.new()
		gh.add_theme_constant_override("separation", 4)
		gh.add_child(UiKit.Glyph.new(g[3], 14, UiKit.BRASS))
		var gl = UiKit.label(String(g[0]), 13, UiKit.BRASS)
		gl.add_theme_font_override("font", UiKit.bold())
		gh.add_child(gl)
		gv.add_child(gh)
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 5)
		gv.add_child(row)
		for i in range(int(g[1]), int(g[1]) + int(g[2])):
			var uid: String = lo[i]
			if uid != "":
				filled += 1
			row.add_child(_socket(i, uid))
		slots_box.add_child(gv)
		if g != groups[-1]:
			var sep = VSeparator.new()
			sep.custom_minimum_size = Vector2(8, 0)
			slots_box.add_child(sep)
	var vl = count_pill.find_child("Value", true, false)
	if vl:
		vl.text = "%d/%d" % [filled, GameState.SLOT_COUNT]
	_restyle_cards()


func _socket(i: int, uid: String) -> Button:
	var b = Button.new()
	b.custom_minimum_size = Vector2(80, 80)
	var kind = GameState.slot_kind(i)
	var fits: bool = picked != "" and GameState.unit_fits_slot(picked, i)
	var base = "card_air" if kind == "air" else ("card_ready" if fits else "slot")
	if uid != "" and kind != "air" and not fits:
		base = "card"
	b.add_theme_stylebox_override("normal", UiArt.style(base, 10, Vector4(4, 4, 4, 4)))
	b.add_theme_stylebox_override("hover", UiArt.style("card_ready", 10, Vector4(4, 4, 4, 4)))
	b.add_theme_stylebox_override("pressed", UiArt.style("btn_pressed", 10, Vector4(4, 4, 4, 4)))
	if uid != "":
		var e = Registry.entry(uid)
		var pv = Widgets.UnitPreview.new(e.assets.art, "dwarf")
		pv.set_anchors_preset(Control.PRESET_FULL_RECT)
		pv.offset_left = 6
		pv.offset_right = -6
		pv.offset_top = 6
		pv.offset_bottom = -20
		b.add_child(pv)
		var l = UiKit.label(String(e.name).split(" ")[-1], 11, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		l.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		l.offset_top = -20
		l.offset_bottom = -4
		l.clip_text = true
		b.add_child(l)
	else:
		var gl = UiKit.Glyph.new({"ground": "shield", "air": "wing", "flex": "gear"}[kind], 26, Color(UiKit.BRASS_D, 0.8) if not fits else UiKit.FORGE)
		gl.set_anchors_preset(Control.PRESET_CENTER)
		gl.position = Vector2(27, 26)
		gl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(gl)
	var idx = i
	b.pressed.connect(func(): _slot_pressed(idx))
	return b


# ------------------------------------------------------------------ armoury
func _roster_list() -> Array:
	var impl = Registry.implemented_dwarves()
	var out: Array = []
	for e in impl:
		if branch != "" and String(e.branch) != branch:
			continue
		if only_unlocked and not GameState.is_unlocked(e.id):
			continue
		out.append(e)
	out.sort_custom(func(a, b2): return [int(not GameState.is_unlocked(a.id)), int(a.tier), a.branch, a.name] < [int(not GameState.is_unlocked(b2.id)), int(b2.tier), b2.branch, b2.name])
	return out


func _build_roster() -> void:
	for c in roster_grid.get_children():
		c.queue_free()
	_cards.clear()
	for e in _roster_list():
		roster_grid.add_child(_card(e))
	_restyle_cards()


func _card(e: Dictionary) -> Button:
	var unlocked = GameState.is_unlocked(e.id)
	var b = Button.new()
	b.custom_minimum_size = Vector2(100, 118)
	var pv = Widgets.UnitPreview.new(e.assets.art, "dwarf")
	pv.set_anchors_preset(Control.PRESET_FULL_RECT)
	pv.offset_left = 6
	pv.offset_right = -6
	pv.offset_top = 8
	pv.offset_bottom = -44
	if not unlocked:
		pv.modulate = Color(0.22, 0.22, 0.24)
	b.add_child(pv)
	var l = UiKit.label(String(e.name), 11, UiKit.TEXT if unlocked else UiKit.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	l.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	l.offset_top = -45
	l.offset_bottom = -19
	l.offset_left = 4
	l.offset_right = -4
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.max_lines_visible = 2
	l.add_theme_constant_override("line_spacing", -3)
	b.add_child(l)
	var st: Dictionary = e.stats
	var foot = HBoxContainer.new()
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	foot.offset_top = -19
	foot.offset_bottom = -4
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.add_theme_constant_override("separation", 2)
	if unlocked:
		foot.add_child(UiKit.Glyph.new("coin", 13, UiKit.BRASS_L))
		foot.add_child(UiKit.label(str(int(st.gold)), 12, UiKit.BRASS_L))
		if float(st.get("steam", 0)) > 0:
			foot.add_child(UiKit.Glyph.new("steam", 13, UiKit.STEAM))
			foot.add_child(UiKit.label(str(int(st.steam)), 12, UiKit.STEAM))
	else:
		foot.add_child(UiKit.Glyph.new("lock", 13, UiKit.TEXT_DIM))
		foot.add_child(UiKit.label("T%d" % int(e.tier), 12, UiKit.TEXT_DIM))
	b.add_child(foot)
	var uid2: String = e.id
	b.pressed.connect(func(): _unit_pressed(uid2))
	b.set_meta("air", String(st.get("domain", "ground")) == "air")
	b.set_meta("unlocked", unlocked)
	_cards[uid2] = b
	return b


func _restyle_cards() -> void:
	var lo = GameState.active_loadout()
	for uid in _cards:
		var b: Button = _cards[uid]
		if not is_instance_valid(b):
			continue
		var kind = "card_air" if b.get_meta("air") else "card"
		if uid == picked:
			kind = "card_ready"
		elif not b.get_meta("unlocked"):
			kind = "slot"
		b.add_theme_stylebox_override("normal", UiArt.style(kind, 10, Vector4(4, 4, 4, 4)))
		b.add_theme_stylebox_override("hover", UiArt.style("card_ready", 10, Vector4(4, 4, 4, 4)))
		b.add_theme_stylebox_override("pressed", UiArt.style("btn_pressed", 10, Vector4(4, 4, 4, 4)))
		var mark = b.get_node_or_null("InLoadout")
		if uid in lo:
			if mark == null:
				mark = UiKit.Glyph.new("star", 16, UiKit.GOOD)
				mark.name = "InLoadout"
				mark.position = Vector2(76, 6)
				mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
				b.add_child(mark)
		elif mark != null:
			mark.queue_free()


# ------------------------------------------------------------------ interaction
func _unit_pressed(uid: String) -> void:
	Audio.play("ui_click", -1, -6)
	var e = Registry.entry(uid)
	_show_info(e)
	if not GameState.is_unlocked(uid):
		picked = ""
		_refresh()
		return
	if picked == uid:
		picked = ""
	elif uid in GameState.active_loadout():
		picked = ""   # already in the army: just show its dossier
	elif not GameState.auto_place(uid):
		picked = uid   # sockets full — pick, then tap a socket to replace
	else:
		picked = ""
	_refresh()


func _slot_pressed(i: int) -> void:
	Audio.play("ui_click", -1, -6)
	if picked != "":
		if GameState.unit_fits_slot(picked, i):
			GameState.set_slot(i, picked)
			picked = ""
	else:
		var uid: String = GameState.active_loadout()[i]
		if uid != "":
			_show_info(Registry.entry(uid))
		GameState.set_slot(i, "")
	_refresh()


# ------------------------------------------------------------------ dossier
func _stat(icon: String, text: String, col: Color) -> void:
	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 4)
	hb.add_child(UiKit.Glyph.new(icon, 16, col))
	hb.add_child(UiKit.label(text, 14, UiKit.TEXT))
	stat_grid.add_child(hb)


func _show_info(e: Dictionary) -> void:
	_shown = e.id
	var st: Dictionary = e.stats
	var unlocked = GameState.is_unlocked(e.id)
	portrait.set_art(e.assets.art, "dwarf")
	portrait.modulate = Color.WHITE if unlocked else Color(0.3, 0.3, 0.32)
	name_l.text = e.name
	sub_l.text = "%s · T%d %s · %s" % [Registry.BRANCH_NAMES[e.branch], int(e.tier), Registry.TIER_NAMES[int(e.tier)], Registry.pretty_role(e.role)]
	for c in stat_grid.get_children():
		c.queue_free()
	_stat("shield", "%d HP" % int(st.hp), UiKit.GOOD)
	_stat("hammer", String(st.armor).capitalize(), UiKit.TEXT_DIM)
	_stat("coin", "%d" % int(st.gold), UiKit.BRASS_L)
	_stat("valve", "%.0fs" % float(st.cooldown), UiKit.TEXT_DIM)
	if float(st.get("steam", 0)) > 0:
		_stat("steam", "%d" % int(st.steam), UiKit.STEAM)
	_stat("wing" if String(st.get("domain", "ground")) == "air" else "play", "Spd %d" % int(st.speed), UiKit.AIR)
	var t = "%s\n" % e.get("desc", "")
	for w in st.weapons:
		t += "\n[color=#f08a2a]%s[/color]  %s · %d dmg · rng %d · %.1fs · vs %s" % [String(w.id).replace("_", " ").capitalize(), w.dtype, int(w.damage), int(w.range), float(w.reload), String(w.targets).replace("_", "+")]
	if st.has("ability"):
		var ab: Dictionary = st.ability
		t += "\n\n[color=#bfe3ef]Ability — %s[/color] (%d Steam, %.0fs): %s" % [ab.name, int(ab.get("steam", 0)), float(ab.cooldown), ab.get("desc", "")]
	if st.get("weakness", "") != "":
		t += "\n[color=#e0604a]Weakness:[/color] %s" % st.get("weakness", "")
	if not unlocked:
		t += "\n\n[color=#e0604a]Locked:[/color] %s" % GameState.research_block_reason(Registry.tech_node("unit_" + e.id))
	info.text = t
	_variant_buttons(e)


func _variant_buttons(e: Dictionary) -> void:
	for c in variant_box.get_children():
		c.queue_free()
	var vs: Array = GameState.variants_for(e.id)
	if vs.is_empty() or not GameState.is_unlocked(e.id):
		return
	var cur: String = GameState.selected_variant(e.id)
	var uid: String = e.id
	var std = UiKit.button(("● " if cur == "" else "") + "Standard", func(): GameState.select_variant(uid, ""); _show_info(e), Vector2(0, 44), 15)
	variant_box.add_child(std)
	for v in vs:
		var vid: String = v.id
		var ok: bool = GameState.variant_available(e.id, vid)
		var b = UiKit.button(("● " if cur == vid else "") + String(v.name).replace(" Configuration", ""), func(): GameState.select_variant(uid, vid); _show_info(e), Vector2(0, 44), 15)
		b.disabled = not ok
		b.tooltip_text = v.get("desc", "") if ok else "Research it in the Great Forge"
		variant_box.add_child(b)
