extends Control
## The Great Forge — unified technology tree. Seven permanently researchable branches plus
## cross-branch doctrines, laid out as tier rails (T0 Foundations → T5 Age of Colossi).
## Selecting a node lights its prerequisites; research is permanent and no branch is ever
## locked out.

var tab := 0
var tabs: TabBar
var grid_box: VBoxContainer
var info: RichTextLabel
var action_btn: Button
var sparks_pill: PanelContainer
var sel_node := ""
var portrait: Widgets.UnitPreview
var portrait_frame: PanelContainer
var name_l: Label
var sub_l: Label
var state_l: Label
var progress_l: Label

const SHORT := {"A": "Infantry", "B": "Engineers", "C": "Artillery", "D": "Armour", "E": "Walkers", "F": "Aircraft", "G": "Airships"}


func _ready() -> void:
	theme = UiKit.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(Widgets.Backdrop.new())
	var mc = UiKit.root_margin(self, 14)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	mc.add_child(v)
	var bar = UiKit.title_bar(v, "The Great Forge", func(): GameState.goto("menu"))
	sparks_pill = UiKit.pill("spark", "", UiKit.FORGE)
	bar.add_child(sparks_pill)
	var tr = HBoxContainer.new()
	tr.add_theme_constant_override("separation", 12)
	v.add_child(tr)
	tabs = TabBar.new()
	for b in Registry.BRANCH_ORDER:
		tabs.add_tab(SHORT.get(b, Registry.BRANCH_NAMES[b]))
	tabs.add_tab("Doctrines")
	tabs.clip_tabs = false
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.tab_changed.connect(func(i):
		tab = i
		Audio.play("ui_click", -1, -8)
		_build())
	tr.add_child(tabs)
	progress_l = UiKit.label("", 15, UiKit.TEXT_DIM)
	tr.add_child(progress_l)
	var h = HBoxContainer.new()
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)
	var tree = UiKit.plate("panel_dark", Vector4(12, 10, 12, 10))
	tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(tree)
	var sc = ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tree.add_child(sc)
	grid_box = VBoxContainer.new()
	grid_box.add_theme_constant_override("separation", 6)
	grid_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(grid_box)

	var pc = UiKit.plate("panel", Vector4(16, 14, 16, 14))
	pc.custom_minimum_size = Vector2(370, 0)
	h.add_child(pc)
	var pv = VBoxContainer.new()
	pv.add_theme_constant_override("separation", 6)
	pc.add_child(pv)
	portrait_frame = PanelContainer.new()
	portrait_frame.add_theme_stylebox_override("panel", UiArt.style("slot", 8, Vector4(4, 4, 4, 4)))
	portrait_frame.custom_minimum_size = Vector2(0, 130)
	pv.add_child(portrait_frame)
	portrait = Widgets.UnitPreview.new("", "dwarf", true)
	portrait_frame.add_child(portrait)
	portrait_frame.visible = false
	var nr = HBoxContainer.new()
	pv.add_child(nr)
	name_l = UiKit.label("Select a technology", 21, UiKit.BRASS_L)
	name_l.add_theme_font_override("font", UiKit.bold())
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nr.add_child(name_l)
	state_l = UiKit.label("", 14, UiKit.TEXT_DIM)
	nr.add_child(state_l)
	sub_l = UiKit.label("Research is permanent and spans every branch — no branch is ever locked out. Earn Forge Sparks by clearing stages.", 14, UiKit.TEXT_DIM)
	sub_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pv.add_child(sub_l)
	info = RichTextLabel.new()
	info.bbcode_enabled = true
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info.add_theme_font_size_override("normal_font_size", 15)
	pv.add_child(info)
	action_btn = UiKit.primary("Research", _research, Vector2(0, 60), 21)
	action_btn.disabled = true
	pv.add_child(action_btn)
	_build()


func _branch_nodes(br: String) -> Array:
	return Registry.tech.units.filter(func(n): return n.branch == br and n.has("unit"))


func _build() -> void:
	var vl = sparks_pill.find_child("Value", true, false)
	if vl:
		vl.text = "%d Sparks" % int(GameState.profile.sparks)
	for c in grid_box.get_children():
		c.queue_free()
	var req_of_sel: Array = Registry.tech_node(sel_node).get("requires", []) if sel_node != "" else []
	if tab < 7:
		var br: String = Registry.BRANCH_ORDER[tab]
		var all = _branch_nodes(br)
		var done = all.filter(func(n): return GameState.is_researched(n.id)).size()
		progress_l.text = "%s · %d/%d forged" % [Registry.BRANCH_NAMES[br], done, all.size()]
		for tier in 6:
			var nodes: Array = all.filter(func(n): return int(n.tier) == tier)
			if nodes.is_empty():
				continue
			_rail(tier, nodes, req_of_sel)
		var vnodes: Array = Registry.tech.units.filter(func(n): return n.branch == br and n.has("variant_of"))
		if not vnodes.is_empty():
			grid_box.add_child(UiKit.heading("Alternate Armaments", UiKit.FORGE))
			var vrow = HFlowContainer.new()
			vrow.add_theme_constant_override("h_separation", 6)
			vrow.add_theme_constant_override("v_separation", 6)
			grid_box.add_child(vrow)
			for n in vnodes:
				vrow.add_child(_card(n, "%s (%s)" % [n.name, Registry.entry(n.variant_of).name], {}, req_of_sel))
	else:
		var dn = Registry.tech.doctrines
		progress_l.text = "Doctrines · %d/%d adopted" % [dn.filter(func(n): return GameState.is_researched(n.id)).size(), dn.size()]
		for tier in range(1, 6):
			var nodes: Array = dn.filter(func(n): return int(n.tier) == tier)
			if not nodes.is_empty():
				_rail(tier, nodes, req_of_sel)


## One tier rail: an engraved tier plaque on the left and the tier's nodes flowing beside it.
func _rail(tier: int, nodes: Array, req_of_sel: Array) -> void:
	var open = GameState.tier_open(tier)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	grid_box.add_child(row)
	var plq = UiKit.plate("plaque" if open else "panel_dark", Vector4(8, 6, 8, 6))
	plq.custom_minimum_size = Vector2(96, 0)
	var pv = VBoxContainer.new()
	pv.alignment = BoxContainer.ALIGNMENT_CENTER
	plq.add_child(pv)
	var tl = UiKit.label("T%d" % tier, 26, UiKit.TEXT if open else UiKit.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	tl.add_theme_font_override("font", UiKit.bold())
	pv.add_child(tl)
	var nl = UiKit.label(String(Registry.TIER_NAMES[tier]).replace("Age of ", ""), 12, UiKit.TEXT if open else UiKit.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pv.add_child(nl)
	if not open:
		var lk = HBoxContainer.new()
		lk.alignment = BoxContainer.ALIGNMENT_CENTER
		lk.add_child(UiKit.Glyph.new("lock", 16, UiKit.TEXT_DIM))
		pv.add_child(lk)
	row.add_child(plq)
	var flow = HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	row.add_child(flow)
	for n in nodes:
		var e = Registry.entry(n.unit) if n.has("unit") else {}
		flow.add_child(_card(n, e.name if not e.is_empty() else String(n.name), e, req_of_sel))


func _state(n: Dictionary) -> String:
	var r = GameState.research_block_reason(n)
	if r == "Researched":
		return "done"
	if r.begins_with("Planned"):
		return "planned"
	if r == "":
		return "ready"
	return "locked"


func _card(n: Dictionary, title: String, e: Dictionary, req_of_sel: Array) -> Control:
	var st = _state(n)
	var b = Button.new()
	var has_art = not e.is_empty()
	b.custom_minimum_size = Vector2(118, 128 if has_art else 72)
	var kind = {"done": "card", "ready": "card_ready", "locked": "slot", "planned": "panel_dark"}[st]
	if n.id == sel_node:
		kind = "btn_primary"
	elif n.id in req_of_sel:
		kind = "tab_sel"
	var pad = Vector4(4, 4, 4, 4)
	b.add_theme_stylebox_override("normal", UiArt.style(kind, 10, pad))
	b.add_theme_stylebox_override("hover", UiArt.style("card_ready", 10, pad))
	b.add_theme_stylebox_override("pressed", UiArt.style("btn_pressed", 10, pad))
	if has_art:
		var pv = Widgets.UnitPreview.new(e.assets.art, "dwarf")
		pv.set_anchors_preset(Control.PRESET_FULL_RECT)
		pv.offset_left = 6
		pv.offset_right = -6
		pv.offset_top = 8
		pv.offset_bottom = -44
		if st == "locked" or st == "planned":
			pv.modulate = Color(0.28, 0.28, 0.3)
		b.add_child(pv)
	var l = UiKit.label(title, 11 if has_art else 13, UiKit.TEXT if st != "planned" else Color("7a7268"), HORIZONTAL_ALIGNMENT_CENTER)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.max_lines_visible = 2
	l.add_theme_constant_override("line_spacing", -3)
	l.set_anchors_preset(Control.PRESET_BOTTOM_WIDE if has_art else Control.PRESET_FULL_RECT)
	if has_art:
		l.offset_top = -44
		l.offset_bottom = -19
	else:
		l.offset_bottom = -19
	l.offset_left = 4
	l.offset_right = -4
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	b.add_child(l)
	var foot = HBoxContainer.new()
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	foot.offset_top = -19
	foot.offset_bottom = -4
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.add_theme_constant_override("separation", 3)
	match st:
		"done":
			foot.add_child(UiKit.Glyph.new("star", 13, UiKit.GOOD))
			foot.add_child(UiKit.label("Starting" if n.get("starting", false) else "Forged", 12, UiKit.GOOD))
		"ready":
			foot.add_child(UiKit.Glyph.new("spark", 13, UiKit.FORGE))
			foot.add_child(UiKit.label(str(int(n.cost)), 12, UiKit.FORGE))
		"locked":
			foot.add_child(UiKit.Glyph.new("lock", 13, UiKit.TEXT_DIM))
			foot.add_child(UiKit.label(str(int(n.cost)), 12, UiKit.TEXT_DIM))
		_:
			foot.add_child(UiKit.label("Planned", 12, Color("7a7268")))
	b.add_child(foot)
	var nid: String = n.id
	b.pressed.connect(func():
		Audio.play("ui_click", -1, -6)
		sel_node = nid
		_select(nid)
		_build())
	return b


func _select(nid: String) -> void:
	var n = Registry.tech_node(nid)
	var t = ""
	portrait_frame.visible = false
	if n.has("variant_of"):
		var ve = Registry.entry(n.variant_of)
		var vd: Dictionary = {}
		for v in ve.stats.get("variants", []):
			if v.id == n.variant:
				vd = v
		name_l.text = n.name
		sub_l.text = "Alternate armament for %s" % ve.name
		portrait_frame.visible = true
		portrait.set_art(ve.assets.art, "dwarf")
		t += "%s\n\n" % vd.get("desc", "")
		for w in vd.get("weapons", []):
			t += "[color=#f08a2a]%s[/color]: %d pellets × %d dmg, range %d, every %.1fs\n" % [String(w.id).replace("_", " ").capitalize(), int(w.get("pellets", 1)), int(w.damage), int(w.range), float(w.reload)]
		t += "\nSelect it per unit in the Army Loadout once researched.\n"
	elif n.has("unit"):
		var e = Registry.entry(n.unit)
		name_l.text = e.name
		sub_l.text = "%s · T%d %s · %s" % [Registry.BRANCH_NAMES[e.branch], int(e.tier), Registry.TIER_NAMES[int(e.tier)], Registry.pretty_role(e.role)]
		portrait_frame.visible = true
		portrait.set_art(e.assets.art, "dwarf")
		var st: Dictionary = e.stats
		if e.implemented:
			t += "%s\n\n" % e.get("desc", "")
			t += "[color=#7fcf6a]%d HP[/color] · %s armour · [color=#f0d27a]%d Gold[/color]%s · %.0fs cooldown\n" % [int(st.hp), String(st.armor), int(st.gold), (" + [color=#bfe3ef]%d Steam[/color]" % int(st.steam)) if float(st.get("steam", 0)) > 0 else "", float(st.cooldown)]
		else:
			t += "[color=#e0604a]Planned unit.[/color] Target milestone: %s.\n" % e.milestone
	else:
		name_l.text = n.name
		sub_l.text = "Doctrine · T%d %s" % [int(n.tier), Registry.TIER_NAMES[int(n.tier)]]
		t += "%s\n" % n.get("desc", "")
		if not n.get("implemented", false):
			t += "\n[color=#e0604a]Planned doctrine — research opens in a later milestone.[/color]\n"
	var req: Array = n.get("requires", [])
	if not req.is_empty():
		t += "\n[color=#c9a24a]REQUIRES[/color]\n"
		for r in req:
			var ok = GameState.is_researched(r)
			t += " %s %s\n" % ["[color=#7fcf6a]✔[/color]" if ok else "[color=#e0604a]✖[/color]", Registry.tech_node(r).get("name", r)]
	var reason = GameState.research_block_reason(n)
	if reason != "" and reason != "Researched":
		t += "\n[color=#b5a682]%s[/color]" % reason
	info.text = t
	var s = _state(n)
	state_l.text = {"done": "FORGED", "ready": "READY", "locked": "LOCKED", "planned": "PLANNED"}[s]
	state_l.add_theme_color_override("font_color", {"done": UiKit.GOOD, "ready": UiKit.FORGE, "locked": UiKit.BAD, "planned": UiKit.TEXT_DIM}[s])
	action_btn.disabled = reason != ""
	action_btn.text = "Forge it — %d Sparks" % int(n.cost) if reason == "" else ("Forged" if reason == "Researched" else "Unavailable")


func _research() -> void:
	if GameState.research(sel_node):
		Audio.play("walker_step", -1, 0)
		_select(sel_node)
		_build()
