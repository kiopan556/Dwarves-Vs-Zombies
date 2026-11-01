class_name Guide
extends Control
## M005 battle guidance layer:
##  - the guided tutorial for stages 001-003 (opt-out in Settings; on for new saves only);
##  - first-encounter hints: one dismissible brass line naming a counter, never repeated.
## Plates are small brass speech plates near what they explain, with an arrow. Only the first three
## tutorial plates pause the battle; every plate goes away with a single tap, and hints fade by
## themselves. This is the one allowed exception to "show, don't tell", so text stays short.

var screen          # BattleScreen
var stage_id := ""
var tut_steps: Array = []
var tut_on := false
var _queue: Array = []        # {text, anchor, pause, kind}
var _plate: PanelContainer
var _arrow: Arrow
var _cur: Dictionary = {}
var _cur_t := 0.0
var _paused_by_me := false
var _paused_count := 0
var _flags := {}
var _t := 0.0
const PAUSE_LIMIT := 3
const HINT_TIME := 7.0

# trigger kinds: "t" seconds into the battle, "deploy" after the first deployment, "air" when the first
# undead flyer appears, "after" n seconds after the previous step was dismissed
const STEPS := {
	"s001": [
		{"on": "t", "v": 0.6, "text": "Tap a card to deploy a unit. Each one costs Gold.", "anchor": "cards", "pause": true},
		{"on": "deploy", "text": "Gold flows in all battle long. Upgrade the Mine to earn it faster.", "anchor": "gold", "pause": true},
		{"on": "air", "text": "Two fronts! Bats attack from the sky — send a Flying Machine after them.", "anchor": "air_card", "pause": true},
		{"on": "after", "v": 8.0, "text": "Drag the battlefield to look ahead. Destroy the citadel to win.", "anchor": "minimap", "pause": false},
	],
	"s002": [
		{"on": "t", "v": 1.0, "text": "Cannons hold back and fire over your line. Keep shields in front.", "anchor": "cards", "pause": false},
		{"on": "after", "v": 10.0, "text": "Riflemen shoot best from behind a Shieldbearer.", "anchor": "cards", "pause": false},
		{"on": "after", "v": 12.0, "text": "Need a breath? Pause any time.", "anchor": "pause", "pause": false},
	],
	"s003": [
		{"on": "t", "v": 1.0, "text": "Steam Pressure builds over time. It powers your machines' abilities.", "anchor": "steam", "pause": false},
		{"on": "after", "v": 10.0, "text": "Overdrive speeds up machines; Vent scalds anything at your gate.", "anchor": "abilities", "pause": false},
		{"on": "after", "v": 14.0, "text": "Between battles, choose your army in the Loadout: 7 ground, 4 air, 1 flex.", "anchor": "", "pause": false},
	],
}


func setup(p_screen, p_stage_id: String) -> void:
	screen = p_screen
	stage_id = p_stage_id
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	tut_on = GameState.tutorial_wanted(stage_id)
	if tut_on:
		tut_steps = STEPS.get(stage_id, []).duplicate(true)
	screen.battle.enemy_first_seen.connect(_on_first_seen)
	screen.battle.deployed.connect(func(_u): _flags["deploy"] = true)
	# hazards are announced once, as soon as the battle starts
	for h in WaveDirector.hazard_list(screen.stage):
		_hint(Hints.hazard_tag(h))


func _on_first_seen(uid: String) -> void:
	if Registry.entry(uid).get("domain", "ground") == "air":
		_flags["air"] = true
	if tut_on:
		return   # during the guided stages the tutorial speaks; hints wait for later stages
	_hint(Hints.tag_for(uid))


func _hint(tag: String) -> void:
	if not GameState.hint_wanted(tag) or not Hints.TEXT.has(tag):
		return
	GameState.mark_hint(tag)
	_queue.append({"text": Hints.TEXT[tag], "anchor": "", "pause": false, "kind": "hint"})


func _process(delta: float) -> void:
	if screen == null or screen.battle == null:
		return
	if not screen.battle.paused or _paused_by_me:
		_t += delta
	# tutorial triggers
	if tut_on and not tut_steps.is_empty() and _cur.is_empty():
		var s: Dictionary = tut_steps[0]
		var go = false
		match String(s.on):
			"t":
				go = screen.battle.time >= float(s.v)
			"deploy":
				go = _flags.get("deploy", false)
			"air":
				go = _flags.get("air", false) or screen.battle.time > 90.0
			"after":
				go = _t >= float(_flags.get("last_done", 0.0)) + float(s.v)
		if go:
			tut_steps.pop_front()
			_queue.push_front({"text": s.text, "anchor": s.anchor, "pause": s.pause and _paused_count < PAUSE_LIMIT, "kind": "tutorial"})
			if tut_steps.is_empty():
				GameState.mark_tutorial(stage_id)
	if _cur.is_empty() and not _queue.is_empty() and not screen.battle.over and (not screen.battle.paused or screen.intro_active):
		if not screen.intro_active:
			_show(_queue.pop_front())
	if not _cur.is_empty():
		_cur_t += delta
		if not _cur.pause and _cur_t > HINT_TIME:
			dismiss()
		elif _plate != null:
			_plate.modulate.a = minf(1.0, _cur_t * 5.0) * (clampf((HINT_TIME - _cur_t) * 1.5, 0.0, 1.0) if not _cur.pause else 1.0)


func _anchor_rect(name: String) -> Rect2:
	var c: Control = null
	match name:
		"cards":
			c = screen.cards[0] if not screen.cards.is_empty() else null
		"air_card":
			for card in screen.cards:
				if card.air:
					c = card
					break
			if c == null and not screen.cards.is_empty():
				c = screen.cards[0]
		"gold":
			c = screen.gold_l
		"steam":
			c = screen.steam_bar
		"pause":
			c = screen.pause_btn
		"minimap":
			c = screen.minimap
		"abilities":
			c = screen.od_btn
	if c == null or not is_instance_valid(c):
		return Rect2()
	return c.get_global_rect()


func _show(item: Dictionary) -> void:
	_cur = item
	_cur_t = 0.0
	_plate = UiKit.plate("panel", Vector4(16, 10, 16, 10))
	_plate.mouse_filter = Control.MOUSE_FILTER_STOP
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	_plate.add_child(h)
	h.add_child(UiKit.Glyph.new("gear" if item.kind == "tutorial" else "star", 22, UiKit.BRASS_L))
	var l = UiKit.label(String(item.text), 17, UiKit.TEXT)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(300, 0)
	h.add_child(l)
	h.add_child(UiKit.label("tap" if item.pause else "", 12, UiKit.TEXT_DIM))
	_plate.gui_input.connect(func(ev):
		if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed):
			dismiss())
	add_child(_plate)
	_plate.reset_size()
	var vs = get_viewport_rect().size
	var r = _anchor_rect(String(item.anchor))
	var ps = _plate.get_combined_minimum_size()
	var pos: Vector2
	if r.size == Vector2.ZERO:
		pos = Vector2((vs.x - ps.x) * 0.5, 150.0)   # free-standing hints sit under the alert banner
	else:
		var below = r.get_center().y < vs.y * 0.5
		pos = Vector2(clampf(r.get_center().x - ps.x * 0.5, 8.0, vs.x - ps.x - 8.0), (r.end.y + 18.0) if below else (r.position.y - ps.y - 18.0))
		_arrow = Arrow.new()
		_arrow.up = below
		_arrow.size = Vector2(24, 16)
		_arrow.position = Vector2(clampf(r.get_center().x, pos.x + 16.0, pos.x + ps.x - 16.0) - 12.0, (pos.y - 15.0) if below else (pos.y + ps.y - 1.0))
		_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_arrow)
	_plate.position = pos
	_plate.modulate.a = 0.0
	if item.pause:
		_paused_count += 1
		if not screen.battle.paused:
			screen.battle.paused = true
			_paused_by_me = true
	Audio.play("ui_click", -1, -10.0)


func dismiss() -> void:
	if _cur.is_empty():
		return
	if _cur.kind == "tutorial":
		_flags["last_done"] = _t
	if _paused_by_me:
		screen.battle.paused = false
		_paused_by_me = false
	_cur = {}
	if is_instance_valid(_plate):
		_plate.queue_free()
	if is_instance_valid(_arrow):
		_arrow.queue_free()
	_plate = null
	_arrow = null


func showing() -> bool:
	return not _cur.is_empty()


class Arrow extends Control:
	var up = true

	func _draw() -> void:
		var w = size.x
		var h = size.y
		var pts = PackedVector2Array([Vector2(0, h), Vector2(w * 0.5, 0), Vector2(w, h)]) if up else PackedVector2Array([Vector2(0, 0), Vector2(w * 0.5, h), Vector2(w, 0)])
		draw_colored_polygon(pts, UiKit.BRASS)
		draw_polyline(pts, Color("120e0b"), 2.0)
