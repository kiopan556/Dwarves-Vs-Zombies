extends Control
## M008 Last Stand: the arena picker (a War Table tab / hub station). Four arenas, one per environment family; each
## shows its painted preview, its best wave and score, and the cosmetic milestones. Endless waves, a lord of the dead
## every 10th wave, local best scores only.

var selected := ""
var info: VBoxContainer


func _ready() -> void:
	theme = UiKit.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(Widgets.Backdrop.new())
	var mc = UiKit.root_margin(self, 18)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	mc.add_child(v)
	var bar = UiKit.title_bar(v, "The Last Stand", func(): GameState.goto("menu"))
	bar.add_child(UiKit.button("Campaign", func(): GameState.goto("campaign"), Vector2(150, 46), 16))
	var intro = UiKit.label("Endless waves. The citadel cannot fall — only your stronghold can. Every tenth wave a lord of the dead you have already beaten returns. Score: 100 per wave held + 1 per undead destroyed. Rewards are banners and titles only.", 16, UiKit.TEXT_DIM)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(intro)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(row)
	var cards = HBoxContainer.new()
	cards.add_theme_constant_override("separation", 10)
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(cards)
	for a in LastStand.ARENAS:
		cards.add_child(_card(a))
	var side = UiKit.plate("panel", Vector4(16, 14, 16, 14))
	side.custom_minimum_size = Vector2(270, 0)
	row.add_child(side)
	info = VBoxContainer.new()
	info.add_theme_constant_override("separation", 8)
	side.add_child(info)
	for a2 in LastStand.ARENAS:
		if LastStand.arena_open(a2):
			selected = String(a2.id)
			break
	_show(selected)


func _card(a: Dictionary) -> Control:
	var open = LastStand.arena_open(a)
	var pc = UiKit.plate("panel", Vector4(8, 8, 8, 8))
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.custom_minimum_size = Vector2(205, 0)
	var cv = VBoxContainer.new()
	cv.add_theme_constant_override("separation", 6)
	pc.add_child(cv)
	var pv = load("res://scripts/ui/campaign_map.gd").EnvPreview.new()
	pv.env = String(a.env)
	pv.custom_minimum_size = Vector2(0, 130)
	cv.add_child(pv)
	cv.add_child(UiKit.label(String(a.name), 19, UiKit.BRASS_L if open else UiKit.TEXT_DIM))
	cv.add_child(UiKit.label("Act %s lands" % ["I", "II", "III", "IV", "V"][int(a.act) - 1], 14, UiKit.TEXT_DIM))
	var rec: Dictionary = GameState.profile.last_stand.get(String(a.id), {})
	if open:
		cv.add_child(UiKit.pill("shield", "Best wave %d" % int(rec.get("best_wave", 0)), UiKit.BRASS_L))
		cv.add_child(UiKit.pill("star", "Best score %d" % int(rec.get("best_score", 0)), UiKit.FORGE))
	else:
		cv.add_child(UiKit.pill("lock", "Clear stage %03d" % int(String(a.needs).substr(1)), UiKit.TEXT_DIM))
	var id = String(a.id)
	var b = UiKit.button("Select" if open else "Locked", func(): _show(id), Vector2(0, 46), 16)
	b.disabled = not open
	cv.add_child(b)
	return pc


func _show(id: String) -> void:
	selected = id
	for c in info.get_children():
		c.queue_free()
	var a = LastStand.arena(id)
	info.add_child(UiKit.heading(String(a.name)))
	var tl = UiKit.label(String(a.tag), 15, UiKit.TEXT)
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(tl)
	var rec: Dictionary = GameState.profile.last_stand.get(id, {})
	info.add_child(UiKit.label("Runs: %d · Best kills: %d" % [int(rec.get("runs", 0)), int(rec.get("best_kills", 0))], 15, UiKit.TEXT_DIM))
	info.add_child(UiKit.heading("Milestones", UiKit.FORGE))
	var owned: Array = GameState.profile.cosmetics.get("banners", []) + GameState.profile.cosmetics.get("titles", [])
	for m in LastStand.MILESTONES:
		var got = String(m.id) in owned
		info.add_child(UiKit.label(("✓ " if got else "· ") + "Wave %d — %s %s" % [int(m.wave), String(m.id).replace("_", " ").capitalize(), "banner" if m.kind == "banners" else "title"], 14, UiKit.GOOD if got else UiKit.TEXT_DIM))
	var sp = Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info.add_child(sp)
	var lo = GameState.active_loadout().filter(func(x): return x != "")
	var go = UiKit.primary("Make the Stand", func():
		GameState.selected_last_stand = id
		GameState.selected_heroic = false
		GameState.goto("battle"), Vector2(0, 62), 21)
	go.disabled = lo.is_empty() or not LastStand.arena_open(a)
	info.add_child(go)
	info.add_child(UiKit.button("Edit Loadout", func(): GameState.goto("loadout"), Vector2(0, 44), 16))
