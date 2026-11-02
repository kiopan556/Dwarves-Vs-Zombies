extends Control
## M008 campaign completion page (Compendium / War Table): stars, Heroic clears, units used, per-act summary,
## Last Stand bests and the cosmetic banners and titles earned.


func _ready() -> void:
	theme = UiKit.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(Widgets.Backdrop.new())
	var mc = UiKit.root_margin(self, 18)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	mc.add_child(v)
	var bar = UiKit.title_bar(v, "The Rift Sealed" if GameState.rift_sealed() else "Campaign Record", func(): GameState.goto("campaign"))
	if GameState.rift_sealed():
		bar.add_child(UiKit.button("Replay Ending", func():
			GameState.ending_credits_only = false
			GameState.goto("ending"), Vector2(170, 46), 16))
	var top = HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	v.add_child(top)
	var n_impl = Registry.stages.filter(func(x): return x.implemented).size()
	var heroic = GameState.profile.get("heroic", {}).size()
	var used: Array = GameState.profile.get("units_used", [])
	top.add_child(UiKit.pill("map", "%d / %d stages" % [GameState.profile.cleared.size(), n_impl], UiKit.BRASS_L))
	top.add_child(UiKit.pill("star", "%d / %d stars" % [GameState.total_stars(), 3 * n_impl], UiKit.GOOD))
	top.add_child(UiKit.pill("crown", "%d Heroic clears · %d Heroic stars" % [heroic, GameState.total_heroic_stars()], Color("d8323a")))
	top.add_child(UiKit.pill("shield", "%d / %d units fielded" % [used.size(), Registry.implemented_dwarves().size()], UiKit.BRASS_L))
	var acts = GridContainer.new()
	acts.columns = 5
	acts.add_theme_constant_override("h_separation", 10)
	acts.add_theme_constant_override("v_separation", 8)
	v.add_child(acts)
	for a in 5:
		var pc = UiKit.plate("panel", Vector4(12, 10, 12, 10))
		pc.custom_minimum_size = Vector2(232, 0)
		var cv = VBoxContainer.new()
		pc.add_child(cv)
		var first = Registry.stage_by_index(a * 30 + 1)
		cv.add_child(UiKit.label("Act %s" % ["I", "II", "III", "IV", "V"][a], 15, UiKit.TEXT_DIM))
		cv.add_child(UiKit.label(String(first.get("act_name", "")), 17, UiKit.BRASS_L))
		var cl = 0
		var stars = 0
		var hc = 0
		for i in 30:
			var sid = "s%03d" % (a * 30 + i + 1)
			if GameState.is_cleared(sid):
				cl += 1
			stars += GameState.star_count(sid)
			if GameState.heroic_cleared(sid):
				hc += 1
		cv.add_child(UiKit.label("%d / 30 cleared" % cl, 15))
		cv.add_child(UiKit.label("%d / 90 stars" % stars, 15, UiKit.GOOD))
		cv.add_child(UiKit.label("%d Heroic" % hc, 15, Color("e86a6a")))
		acts.add_child(pc)
	var bottom = HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 12)
	bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(bottom)
	var ls = UiKit.plate("panel", Vector4(14, 12, 14, 12))
	ls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(ls)
	var lv = VBoxContainer.new()
	ls.add_child(lv)
	lv.add_child(UiKit.heading("Last Stand"))
	for ar in LastStand.ARENAS:
		var r: Dictionary = GameState.profile.last_stand.get(String(ar.id), {})
		lv.add_child(UiKit.label("%s — best wave %d · best score %d" % [String(ar.name), int(r.get("best_wave", 0)), int(r.get("best_score", 0))], 15))
	var cs = UiKit.plate("panel", Vector4(14, 12, 14, 12))
	cs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(cs)
	var cvv = VBoxContainer.new()
	cs.add_child(cvv)
	cvv.add_child(UiKit.heading("Banners & titles", UiKit.FORGE))
	var cos: Dictionary = GameState.profile.cosmetics
	var all: Array = cos.get("banners", []) + cos.get("titles", [])
	if all.is_empty():
		cvv.add_child(UiKit.label("None yet: the bosses of 140 and 150 and the Last Stand milestones award them.", 15, UiKit.TEXT_DIM))
	for c in all:
		cvv.add_child(UiKit.label("· " + String(c).replace("_", " ").capitalize(), 15, UiKit.BRASS_L))
	var st: Dictionary = GameState.profile.stats
	var sl = UiKit.label("Battles %d · Victories %d · Undead destroyed %d · Rift tears closed %d · Soul wisps shot down %d" % [int(st.battles), int(st.victories), int(st.kills), int(st.get("tears_closed", 0)), int(st.get("wisps_shot", 0))], 14, UiKit.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(sl)
