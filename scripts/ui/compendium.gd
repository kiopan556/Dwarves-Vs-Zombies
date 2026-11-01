extends Control
## Unit Compendium — the complete master roster (160 dwarves, 110 undead, 15 bosses) as a codex
## of portrait tiles grouped by branch / category / act, with a full dossier plate.
## Undead and bosses stay sealed ("???") until the player has met them in battle.

var cat := 0
var group := ""
var list_box: GridContainer
var group_tabs: TabBar
var preview: Widgets.UnitPreview
var info: RichTextLabel
var name_l: Label
var sub_l: Label
var count_l: Label
var filter_impl := false
var _groups: Array = []
const CATS := ["Dwarven Army", "Undead", "Bosses"]


func _ready() -> void:
	theme = UiKit.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(Widgets.Backdrop.new())
	var mc = UiKit.root_margin(self, 14)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	mc.add_child(v)
	var bar = UiKit.title_bar(v, "Unit Compendium", func(): GameState.goto("menu"))
	var known_pill = UiKit.pill("book", "", UiKit.BRASS_L)
	var vl = known_pill.find_child("Value", true, false)
	vl.text = "%d foes recorded" % GameState.profile.encountered.size()
	bar.add_child(known_pill)
	# M005 star reward (cosmetic): the commendation earned from campaign stars
	var stars = GameState.total_stars()
	var rank = "Recruit"
	for r in [[30, "Bronze Hammer"], [90, "Silver Anvil"], [150, "Golden Crown of the Holds"]]:
		if stars >= int(r[0]):
			rank = String(r[1])
	var com = UiKit.pill("star", "Commendation: %s (%d ★)" % [rank, stars], UiKit.FORGE)
	com.tooltip_text = "Earn stars in the campaign: Bronze Hammer at 30, Silver Anvil at 90, Golden Crown of the Holds at 150."
	bar.add_child(com)
	var tr = HBoxContainer.new()
	tr.add_theme_constant_override("separation", 12)
	v.add_child(tr)
	var tabs = TabBar.new()
	for c in CATS:
		tabs.add_tab(c)
	tabs.tab_changed.connect(func(i):
		cat = i
		group = ""
		Audio.play("ui_click", -1, -8)
		_build())
	tr.add_child(tabs)
	group_tabs = TabBar.new()
	group_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	group_tabs.clip_tabs = true
	group_tabs.tab_changed.connect(func(i):
		if i < _groups.size() and _groups[i] != group:
			group = _groups[i]
			Audio.play("ui_click", -1, -8)
			_fill())
	tr.add_child(group_tabs)

	var h = HBoxContainer.new()
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)
	var lp = UiKit.plate("panel_dark", Vector4(12, 10, 12, 10))
	lp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(lp)
	var lv = VBoxContainer.new()
	lv.add_theme_constant_override("separation", 6)
	lp.add_child(lv)
	count_l = UiKit.label("", 14, UiKit.TEXT_DIM)
	lv.add_child(count_l)
	var sc = ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lv.add_child(sc)
	list_box = GridContainer.new()
	list_box.columns = 6
	list_box.add_theme_constant_override("h_separation", 6)
	list_box.add_theme_constant_override("v_separation", 6)
	sc.add_child(list_box)

	var pc = UiKit.plate("panel", Vector4(16, 14, 16, 14))
	pc.custom_minimum_size = Vector2(420, 0)
	h.add_child(pc)
	var pv = VBoxContainer.new()
	pv.add_theme_constant_override("separation", 6)
	pc.add_child(pv)
	var frame = PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiArt.style("slot", 8, Vector4(4, 4, 4, 4)))
	frame.custom_minimum_size = Vector2(0, 190)
	pv.add_child(frame)
	preview = Widgets.UnitPreview.new("", "dwarf", true)
	frame.add_child(preview)
	name_l = UiKit.label("Select an entry", 22, UiKit.BRASS_L)
	name_l.add_theme_font_override("font", UiKit.bold())
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pv.add_child(name_l)
	sub_l = UiKit.label("", 14, UiKit.TEXT_DIM)
	sub_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pv.add_child(sub_l)
	info = RichTextLabel.new()
	info.bbcode_enabled = true
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info.add_theme_font_size_override("normal_font_size", 15)
	pv.add_child(info)
	_build()


func _entries() -> Array:
	match cat:
		0: return Registry.dwarves
		1: return Registry.undead
		_: return Registry.bosses


func _group_of(e: Dictionary) -> String:
	match cat:
		0: return String(e.branch_name)
		1: return String(e.category_name)
		_: return "Act %d" % int(e.act)


## Rebuild the group tabs for the current category, then the tile grid.
func _build() -> void:
	_groups = []
	for e in _entries():
		var g = _group_of(e)
		if not g in _groups:
			_groups.append(g)
	if cat == 2:
		_groups = ["All bosses"]
	if group == "" or not group in _groups:
		group = _groups[0]
	group_tabs.clear_tabs()
	for g in _groups:
		group_tabs.add_tab(g.replace(" & ", "/"))
	group_tabs.current_tab = _groups.find(group)
	_fill()


func _fill() -> void:
	for c in list_box.get_children():
		c.queue_free()
	var all = _entries()
	var n_known = 0
	for e in all:
		if _known(e):
			n_known += 1
	count_l.text = "%d entries · %d recorded · all %d implemented" % [all.size(), n_known, all.filter(func(x): return x.implemented).size()]
	for e in all:
		if cat != 2 and _group_of(e) != group:
			continue
		list_box.add_child(_tile(e))


func _tile(e: Dictionary) -> Button:
	var known = _known(e)
	var b = Button.new()
	b.custom_minimum_size = Vector2(100, 120)
	var kind = "card"
	if cat == 2:
		kind = "btn_danger" if known else "slot"
	elif cat == 1:
		kind = "panel_dark" if known else "slot"
	elif String(e.stats.get("domain", "ground")) == "air":
		kind = "card_air"
	var pad = Vector4(4, 4, 4, 4)
	b.add_theme_stylebox_override("normal", UiArt.style(kind, 10, pad))
	b.add_theme_stylebox_override("hover", UiArt.style("card_ready", 10, pad))
	b.add_theme_stylebox_override("pressed", UiArt.style("btn_pressed", 10, pad))
	var art = _art(e)
	if known and art != "":
		var pv = Widgets.UnitPreview.new(art, "dwarf" if cat == 0 else "undead")
		pv.set_anchors_preset(Control.PRESET_FULL_RECT)
		pv.offset_left = 6
		pv.offset_right = -6
		pv.offset_top = 6
		pv.offset_bottom = -36
		b.add_child(pv)
	else:
		var g = UiKit.Glyph.new("skull" if cat > 0 else "gear", 34, Color(0.45, 0.42, 0.38))
		g.position = Vector2(33, 26)
		g.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(g)
	var l = UiKit.label(String(e.name) if known else "???", 11, UiKit.TEXT if known else UiKit.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	l.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	l.offset_top = -36
	l.offset_bottom = -4
	l.offset_left = 4
	l.offset_right = -4
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.max_lines_visible = 2
	l.add_theme_constant_override("line_spacing", -3)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	b.add_child(l)
	if cat == 0:
		var tl = UiKit.label("T%d" % int(e.tier), 11, UiKit.BRASS)
		tl.position = Vector2(8, 4)
		b.add_child(tl)
	elif cat == 2:
		var sl = UiKit.label("S%03d" % int(e.stage), 11, UiKit.BOSS)
		sl.position = Vector2(8, 4)
		b.add_child(sl)
	var ee: Dictionary = e
	b.pressed.connect(func(): Audio.play("ui_click", -1, -6); _show(ee))
	return b


func _art(e: Dictionary) -> String:
	if e.has("assets") and e.assets.get("art") != null:
		return String(e.assets.art)
	if e.get("stats") != null and e.stats.get("art") != null:
		return String(e.stats.art)
	return ""


func _known(e: Dictionary) -> bool:
	if cat == 0:
		return true
	if cat == 1:
		return not e.implemented or e.id in GameState.profile.encountered
	return int(e.stage) <= GameState.highest_cleared_index() or not e.implemented or e.id in GameState.profile.encountered


func _show(e: Dictionary) -> void:
	var known = _known(e)
	var art = _art(e)
	if e.implemented and art != "" and known:
		preview.set_art(art, "dwarf" if cat == 0 else "undead")
		preview.modulate = Color.WHITE
	else:
		preview.set_art("rotter" if cat > 0 else "rifleman", "undead" if cat > 0 else "dwarf")
		preview.modulate = Color(0.05, 0.05, 0.06)
	if not known:
		name_l.text = "???"
		sub_l.text = _group_of(e)
		info.text = "Meet this foe in battle to record it here."
		return
	name_l.text = e.name
	var t = ""
	match cat:
		0:
			sub_l.text = "%s · T%d %s · %s%s" % [e.branch_name, int(e.tier), Registry.TIER_NAMES[int(e.tier)], Registry.pretty_role(e.role), (" / " + Registry.pretty_role(e.role2)) if e.get("role2") != null else ""]
		1:
			sub_l.text = "%s · %s" % [e.category_name, Registry.pretty_role(e.role)]
		2:
			sub_l.text = "Act %d · Stage %03d · %s" % [int(e.act), int(e.stage), e.identity]
	if not e.implemented:
		t += "[color=#e0604a]Planned — %s.[/color] No final art or statistics yet.\n\n" % e.get("milestone", "later")
	if e.implemented and e.get("stats") != null:
		var st: Dictionary = e.stats
		t += "%s\n\n" % e.get("desc", "")
		t += "[color=#7fcf6a]HP %d[/color] · %s armour · speed %d · %s\n" % [int(st.hp), st.armor, int(st.speed), e.get("domain", st.get("domain", "ground"))]
		# M006 altitude bands: where it flies, and what its guns can reach
		var band_l = Hints.band_of(st)
		t += "[color=#9fc8ec]Altitude band:[/color] %s · [color=#9fc8ec]can hit:[/color] %s\n" % [band_l if band_l != "" else "ground", Hints.can_hit(st)]
		if cat == 0:
			t += "[color=#f0d27a]%d Gold[/color]%s · cooldown %.0fs\n" % [int(st.gold), (" + [color=#bfe3ef]%d Steam[/color]" % int(st.steam)) if float(st.get("steam", 0)) > 0 else "", float(st.cooldown)]
		if st.has("ability"):
			var ab: Dictionary = st.ability
			t += "\n[color=#bfe3ef]Ability — %s[/color]: %s (%d Steam, cooldown %.0fs)\n" % [ab.name, ab.get("desc", ""), int(ab.get("steam", 0)), float(ab.cooldown)]
			if st.get("weakness", "") != "":
				t += "[color=#e0604a]Weakness:[/color] %s\n" % st.get("weakness", "")
			if st.has("mech_class"):
				t += "Frame class: %s · ARM %d%%\n" % [String(st.mech_class).capitalize(), int(float(st.get("arm", 0)) * 100.0)]
			for v in st.get("variants", []):
				t += "[color=#f08a2a]Alt. armament — %s[/color]: %s\n" % [v.name, v.desc]
		for ab2 in st.get("abilities", []):
			t += "\n[color=#d08ad0]%s[/color] — %s, every %.0fs" % [ab2.name, String(ab2.kind), float(ab2.cooldown)]
		# M007 wreck reclamation
		if e.has("origin"):
			t += "[color=#9fd88a]Raised from:[/color] a fallen %s — destroyed dwarven machines can come back like this\n" % Registry.entry(String(e.origin)).get("name", e.origin)
		if st.get("reclaims", false):
			t += "[color=#9fd88a]Reclaims wrecks:[/color] channels over a dwarven wreck for 4 s to raise it as a corrupted machine\n"
		if st.get("salvages", false):
			t += "[color=#f0d27a]Denies wrecks:[/color] clears a wreck in 3 s before the undead can reclaim it, refunding a little Gold\n"
		if e.has("counter"):
			t += "\n\n[color=#9fd88a]Counterplay:[/color] %s\n" % e.counter
		elif cat == 1 and Hints.text_for_unit(e.id) != "":
			t += "\n[color=#9fd88a]Counter:[/color] %s\n" % Hints.text_for_unit(e.id)
		for w in st.weapons:
			t += "\n[color=#f08a2a]%s[/color]: %d %s, range %d, every %.1fs → %s%s" % [String(w.id).replace("_", " ").capitalize(), int(w.damage), w.dtype, int(w.range), float(w.reload), String(w.targets).replace("_", "+") + ((" (to %s)" % String(w.get("reach", "high"))) if String(w.targets) != "ground" else ""), (", splash %d" % int(w.splash)) if float(w.get("splash", 0)) > 0 else ""]
	info.text = t
