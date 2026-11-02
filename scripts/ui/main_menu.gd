extends Control
## Main menu with an animated forge: glowing furnace, anvil sparks, a dwarven line-up and a
## Flying Machine patrolling the smoke.

var forge: ForgeScene


func _ready() -> void:
	theme = UiKit.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	forge = ForgeScene.new()
	add_child(forge)
	var mc = UiKit.root_margin(self, 28)
	var h = HBoxContainer.new()
	mc.add_child(h)
	var left = VBoxContainer.new()
	left.custom_minimum_size = Vector2(440, 0)
	left.add_theme_constant_override("separation", 12)
	h.add_child(left)
	var crest = UiKit.plate("panel", Vector4(28, 18, 28, 20))
	crest.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left.add_child(crest)
	var cv = VBoxContainer.new()
	cv.add_theme_constant_override("separation", -6)
	crest.add_child(cv)
	var t1 = UiKit.label("DWARVES", 72, UiKit.BRASS_L)
	t1.add_theme_font_override("font", UiKit.bold())
	t1.add_theme_constant_override("outline_size", 10)
	t1.add_theme_color_override("font_outline_color", Color("2a1a0a"))
	cv.add_child(t1)
	var t2 = UiKit.label("vs ZOMBIES", 44, Color("9fd88a"))
	t2.add_theme_font_override("font", UiKit.bold())
	t2.add_theme_constant_override("outline_size", 8)
	t2.add_theme_color_override("font_outline_color", Color("0e1a0a"))
	cv.add_child(t2)
	var sp0 = Control.new()
	sp0.custom_minimum_size = Vector2(0, 12)
	cv.add_child(sp0)
	cv.add_child(UiKit.banner("M008 — The Black Rift", 18))
	var sp = Control.new()
	sp.custom_minimum_size = Vector2(0, 30)
	left.add_child(sp)
	var play = UiKit.primary("PLAY", _play, Vector2(380, 84), 36)
	play.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left.add_child(play)
	play.pivot_offset = Vector2(190, 42)
	var tw = create_tween().set_loops()
	tw.tween_property(play, "scale", Vector2(1.03, 1.03), 0.9).set_trans(Tween.TRANS_SINE)
	tw.tween_property(play, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_SINE)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	left.add_child(row)
	row.add_child(UiKit.button("Settings", func(): GameState.goto("settings"), Vector2(180, 52), 18))
	if not OS.has_feature("mobile") and not OS.has_feature("web"):
		row.add_child(UiKit.button("Quit", func(): get_tree().quit(), Vector2(180, 52), 18))
	var sp2 = Control.new()
	sp2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(sp2)
	left.add_child(UiKit.label("One Kingdom. One Great Forge. Two Fronts. No Heroes.", 15, UiKit.FORGE))
	Audio.play_music("menu")
	Audio.stop_ambience()


func _play() -> void:
	# descend into the roots of the mountain
	Audio.play("hammer_impact", -1, -6)
	var fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fade)
	var tw = create_tween()
	tw.tween_property(forge, "position:y", -260.0, 0.6).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(fade, "color:a", 1.0, 0.6)
	tw.tween_callback(func(): GameState.goto("menu"))


class ForgeScene extends Node2D:
	var t = 0.0
	var sparks: Array = []
	var rng = RandomNumberGenerator.new()
	var sprites = {}

	func _ready() -> void:
		rng.seed = 5
		for k in ["shieldbearer", "rifleman", "militia", "field_cannon", "flying_machine", "rotter"]:
			var s = Widgets.ArtSprite.new(k, Vector2.ZERO, 2.0, k == "rotter")
			add_child(s)
			sprites[k] = s
		sprites.flying_machine.scale = Vector2(1.6, 1.6)
		sprites.rotter.anim.state = "move"
		sprites.rotter.modulate = Color(0.6, 0.65, 0.6, 0.85)

	func _process(delta: float) -> void:
		t += delta
		var vs = get_viewport_rect().size
		var fc = Vector2(maxf(900.0, vs.x * 0.68), vs.y - 150.0)
		sprites.shieldbearer.position = Vector2(fc.x - 250, vs.y - 120)
		sprites.rifleman.position = Vector2(fc.x - 160, vs.y - 120)
		sprites.militia.position = Vector2(fc.x - 40, vs.y - 166)
		sprites.field_cannon.position = Vector2(fc.x + 240, vs.y - 120)
		sprites.flying_machine.position = Vector2(fmod(t * 70.0, vs.x + 400.0) - 200.0, 150 + sin(t * 1.3) * 16.0)
		sprites.rotter.position = Vector2(vs.x - fmod(t * 22.0, 260.0) + 40.0, vs.y - 110)
		if fmod(t, 3.1) < delta:
			sprites.militia.anim.atk = 1.0
			for i in 14:
				sparks.append([Vector2(fc.x + 20, vs.y - 168), Vector2(rng.randf_range(-160, 160), rng.randf_range(-320, -80)), 1.0])
		if fmod(t + 1.4, 4.3) < delta:
			sprites.rifleman.anim.atk = 1.0
			sprites.rifleman.anim.reload = 1.0
		var keep: Array = []
		for s in sparks:
			s[1].y += 500.0 * delta
			s[0] += s[1] * delta
			s[2] -= delta * 1.2
			if s[2] > 0.0:
				keep.append(s)
		sparks = keep
		queue_redraw()

	func _draw() -> void:
		var vs = get_viewport_rect().size
		draw_rect(Rect2(Vector2.ZERO, vs), Color("191513"))
		for i in 12:
			var x = 560.0 + i * 70.0
			draw_line(Vector2(x, 0), Vector2(x, vs.y), Color("221d19"), 3.0)
		var fc = Vector2(maxf(900.0, vs.x * 0.68), vs.y - 150.0)
		draw_circle(fc + Vector2(0, -40), 250.0, Color("231d19"))
		draw_rect(Rect2(fc.x - 250, fc.y - 40, 500, 400), Color("231d19"))
		var k = 0.8 + 0.2 * sin(t * 6.0) + 0.1 * sin(t * 17.0)
		for i in 7:
			draw_circle(fc + Vector2(0, -20), 260.0 - i * 32.0, Color(1.0, 0.45, 0.1, 0.05 * k))
		draw_circle(fc + Vector2(0, -30), 90.0, Color("120e0c"))
		draw_rect(Rect2(fc.x - 90, fc.y - 30, 180, 90), Color("120e0c"))
		draw_circle(fc + Vector2(0, 10), 64.0 * k, Color(1.0, 0.55, 0.15, 0.85))
		draw_circle(fc + Vector2(0, 16), 40.0 * k, Color(1.0, 0.85, 0.45, 0.9))
		for i in 3:
			var px = fc.x + 140.0 + i * 26.0
			draw_rect(Rect2(px, 0, 16, fc.y + 40), Painter.COPPER_D)
			draw_rect(Rect2(px - 4, 120 + i * 90, 24, 10), Painter.BRASS)
		draw_rect(Rect2(0, vs.y - 120, vs.x, 120), Color("2a231e"))
		var an = Vector2(fc.x + 30, vs.y - 120)
		Painter.poly(self, Painter.pts([an + Vector2(-60, 0), an + Vector2(60, 0), an + Vector2(40, -20), an + Vector2(70, -30), an + Vector2(70, -46), an + Vector2(-70, -46), an + Vector2(-40, -20)]), Painter.IRON_D, 3.0)
		for i in 6:
			var ph = fmod(t * 0.15 + i / 6.0, 1.0)
			draw_circle(Vector2(fc.x - 60 + i * 30, fc.y - 140 - ph * 300), 30 + ph * 60, Color(0.2, 0.18, 0.17, 0.25 * (1.0 - ph)))
		for s in sparks:
			draw_line(s[0], s[0] - s[1] * 0.02, Color(1, 0.8, 0.3, s[2]), 2.0)
