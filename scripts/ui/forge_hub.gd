extends Control
## The Heart of the Great Forge — animated hub at the roots of the mountain (opened by PLAY on
## the title screen). A wide, drag-scrollable cavern: the molten Forge Heart in rotating brass
## rings, the anvil hammer, lava falls, mine carts, a mech assembly bay with a frame being
## welded, the war room, the armory gate and the hall of records. Every station is a menu.

const WORLD_W := 2600.0

var world: HubWorld
var plaques: Control
var scroll := 0.0
var target_scroll := 0.0
var drag := false
var dragged := 0.0
var intro := 1.0
var sprites: Array = []

const STATIONS := [
	{"key": "campaign", "name": "War Table", "sub": "Campaign", "x": 250.0, "y": 300.0},
	{"key": "loadout", "name": "Armory Gate", "sub": "Army Loadout", "x": 700.0, "y": 250.0},
	{"key": "forge", "name": "The Forge Heart", "sub": "Great Forge Research", "x": 1300.0, "y": 120.0},
	{"key": "sandbox", "name": "Assembly Bay", "sub": "Proving Grounds (Test Sandbox)", "x": 1860.0, "y": 150.0},
	{"key": "compendium", "name": "Hall of Records", "sub": "Unit Compendium", "x": 2280.0, "y": 260.0},
	{"key": "settings", "name": "Pressure Valves", "sub": "Settings", "x": 2500.0, "y": 470.0},
	{"key": "last_stand", "name": "The Last Stand", "sub": "Endless Mode", "x": 1580.0, "y": 400.0},   # M008 (after 060)
]


func _ready() -> void:
	theme = UiKit.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	world = HubWorld.new()
	add_child(world)
	_spawn_life()
	plaques = Control.new()
	plaques.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plaques.size = Vector2(WORLD_W, 720)
	add_child(plaques)
	for st in STATIONS:
		if st.key == "last_stand" and not GameState.last_stand_unlocked():
			continue
		plaques.add_child(_plaque(st))
	_top_bar()
	_nav_bar()
	scroll = 1300.0 - get_viewport_rect().size.x * 0.5
	target_scroll = scroll
	Audio.play_music("menu")
	Audio.play_ambience("foundry")


func _spawn_life() -> void:
	# dwarves at work, a frame on the gantry, the anvil hammer crew
	var defs = [
		["shieldbearer", Vector2(150, 600), 1.6, false], ["rifleman", Vector2(330, 600), 1.6, false], ["mechanic", Vector2(1150, 610), 1.5, false],
		["militia", Vector2(1450, 610), 1.5, true], ["rifleman", Vector2(760, 610), 1.5, false],
		["ironclad_walker", Vector2(1880, 560), 2.4, false], ["drillwalker", Vector2(2060, 600), 1.3, false],
		["mechanic", Vector2(1760, 500), 1.2, false], ["flying_machine", Vector2(1000, 210), 1.3, false],
	]
	for dd in defs:
		var sp = Widgets.ArtSprite.new(dd[0], dd[1], dd[2], dd[3])
		sp.set_meta("home", dd[1])
		world.add_child(sp)
		sprites.append(sp)
	sprites[5].anim.engage = 1.0
	sprites[5].modulate = Color(0.95, 0.9, 0.85)
	sprites[6].anim.state = "move"
	sprites[3].anim.state = "move"
	sprites[4].anim.state = "move"


const STATION_GLYPH := {"campaign": "map", "loadout": "shield", "forge": "hammer", "sandbox": "gear", "compendium": "book", "settings": "valve", "last_stand": "sword"}


## Engraved brass station plaque hanging in the forge: glyph medallion, name and subtitle.
func _plaque(st: Dictionary) -> Control:
	var b = Button.new()
	b.custom_minimum_size = Vector2(250, 70)
	b.position = Vector2(st.x - 125.0, st.y)
	var pad = Vector4(12, 6, 12, 6)
	b.add_theme_stylebox_override("normal", UiArt.style("plaque", 10, pad))
	b.add_theme_stylebox_override("hover", UiArt.style("btn_primary_hover", 10, pad))
	b.add_theme_stylebox_override("pressed", UiArt.style("btn_pressed", 10, pad))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var h = HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 12
	h.offset_right = -10
	h.add_theme_constant_override("separation", 10)
	b.add_child(h)
	var med = PanelContainer.new()
	med.mouse_filter = Control.MOUSE_FILTER_IGNORE
	med.add_theme_stylebox_override("panel", UiArt.style("node", 19, Vector4(8, 8, 8, 8)))
	med.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	med.add_child(UiKit.Glyph.new(STATION_GLYPH.get(st.key, "gear"), 28, UiKit.BRASS_L))
	h.add_child(med)
	var tv = VBoxContainer.new()
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	tv.add_theme_constant_override("separation", -2)
	h.add_child(tv)
	var nl = UiKit.label(String(st.name).to_upper(), 18, Color("2a1a0a"))
	nl.add_theme_font_override("font", UiKit.bold())
	tv.add_child(nl)
	tv.add_child(UiKit.label(String(st.sub).get_slice(" (", 0), 14, Color("3e2a12")))
	var key: String = st.key
	b.pressed.connect(func(): _enter(key))
	return b


func _enter(key: String) -> void:
	Audio.play("ui_click", -1, -4)
	Audio.play("hammer_impact", -1, -12)
	GameState.goto(key)


func _top_bar() -> void:
	var bar = PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = 58
	bar.offset_bottom = 66
	bar.add_theme_stylebox_override("panel", UiArt.style("panel_glass", 10, Vector4(10, 6, 10, 6)))
	add_child(bar)
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	bar.add_child(h)
	h.add_child(UiKit.button("◀ Title", func(): GameState.goto("title"), Vector2(110, 50), 16))
	var bn = UiKit.banner("HEART OF THE GREAT FORGE", 22)
	bn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(bn)
	var n_impl = Registry.stages.filter(func(x): return x.get("implemented", false)).size()
	h.add_child(UiKit.pill("spark", "%d" % int(GameState.profile.sparks), UiKit.FORGE))
	h.add_child(UiKit.pill("map", "%d / %d" % [GameState.profile.cleared.size(), n_impl], UiKit.BRASS_L))
	h.add_child(UiKit.primary("Deploy", func(): GameState.goto("campaign"), Vector2(140, 50), 19))


func _nav_bar() -> void:
	var nav = HBoxContainer.new()
	nav.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	nav.grow_horizontal = Control.GROW_DIRECTION_BOTH
	nav.offset_top = -62
	nav.offset_bottom = -8
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 6)
	add_child(nav)
	for st in STATIONS:
		if st.key == "last_stand" and not GameState.last_stand_unlocked():
			continue
		var x: float = st.x
		var b = UiKit.button("", func(): target_scroll = x - get_viewport_rect().size.x * 0.5, Vector2(150, 50), 15)
		var row = HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.set_anchors_preset(Control.PRESET_FULL_RECT)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 6)
		row.add_child(UiKit.Glyph.new(STATION_GLYPH.get(st.key, "gear"), 18, UiKit.BRASS_L))
		row.add_child(UiKit.label(String(st.sub).get_slice(" (", 0).replace("Great Forge ", "").replace("Unit ", "").replace("Army ", ""), 15, UiKit.TEXT))
		b.add_child(row)
		nav.add_child(b)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		drag = event.pressed
		dragged = 0.0
	elif event is InputEventMouseMotion and drag:
		scroll -= event.relative.x
		target_scroll = scroll
		dragged += absf(event.relative.x)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_scroll -= 160.0
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_scroll += 160.0


func _process(delta: float) -> void:
	var vw = get_viewport_rect().size.x
	target_scroll = clampf(target_scroll, 0.0, WORLD_W - vw)
	scroll = lerpf(scroll, target_scroll, clampf(delta * 6.0, 0.0, 1.0)) if not drag else clampf(scroll, 0.0, WORLD_W - vw)
	intro = maxf(0.0, intro - delta * 0.8)
	var drop = -260.0 * intro * intro    # arrival: descend from the mountain halls
	world.position = Vector2(-scroll, drop)
	plaques.position = Vector2(-scroll, drop)
	plaques.modulate.a = 1.0 - intro
	world.t += delta
	# life: walkers patrol back and forth, the hammer crew works, the flyer circles
	var t: float = world.t
	for i in sprites.size():
		var sp = sprites[i]
		var home: Vector2 = sp.get_meta("home")
		match i:
			3, 4:
				var span = 180.0
				var ph = fmod(t * 0.12 + i * 0.3, 2.0)
				var k = ph if ph < 1.0 else 2.0 - ph
				sp.position.x = home.x + (k - 0.5) * span
				sp.scale.x = absf(sp.scale.x) * (1.0 if ph < 1.0 else -1.0) * (-1.0 if i == 3 else 1.0)
			6:
				var ph2 = fmod(t * 0.08, 2.0)
				var k2 = ph2 if ph2 < 1.0 else 2.0 - ph2
				sp.position.x = home.x + (k2 - 0.5) * 220.0
				sp.scale.x = absf(sp.scale.x) * (1.0 if ph2 < 1.0 else -1.0)
			8:
				sp.position = home + Vector2(sin(t * 0.35) * 420.0, sin(t * 0.7) * 30.0)
				sp.scale.x = absf(sp.scale.x) * (1.0 if cos(t * 0.35) > 0.0 else -1.0)
				sp.anim.walk += delta * 6.0
			2, 7:
				sp.anim.special = 1.0
		if i == 0 and fmod(t, 5.0) < delta:
			sp.anim.atk = 1.0
		if i == 1 and fmod(t + 2.0, 4.0) < delta:
			sp.anim.atk = 1.0
			sp.anim.reload = 1.0
		if i == 5:
			sp.anim.atk = 1.0 if fmod(t, 6.0) < 0.15 else sp.anim.atk


class HubWorld extends Node2D:
	var t = 0.0
	var rng = RandomNumberGenerator.new()
	var sparks: Array = []
	var carts = [0.0, 0.45]

	func _ready() -> void:
		rng.seed = 11

	func _process(delta: float) -> void:
		# anvil strike cadence → sparks
		var strike = fmod(t, 1.6)
		if strike < delta:
			for i in 16:
				sparks.append([Vector2(1300 + rng.randf_range(-20, 20), 548), Vector2(rng.randf_range(-260, 260), rng.randf_range(-380, -120)), 1.0])
		# welding sparks on the gantry
		if rng.randf() < delta * 10.0:
			sparks.append([Vector2(1840 + rng.randf_range(-40, 60), 430 + rng.randf_range(-80, 80)), Vector2(rng.randf_range(-90, 90), rng.randf_range(-120, 40)), 0.7])
		var keep: Array = []
		for s in sparks:
			s[1].y += 600.0 * delta
			s[0] += s[1] * delta
			s[2] -= delta * 1.3
			if s[2] > 0.0:
				keep.append(s)
		sparks = keep.slice(maxi(0, keep.size() - 160))
		for i in carts.size():
			carts[i] = fmod(carts[i] + delta * 0.05, 1.0)
		queue_redraw()

	# ---------------------------------------------------------------- drawing
	# Static scenery (cavern, alcoves, shelves, floor, rails) is baked once into two textures when
	# the pose cache / performance presets are on; only the moving parts are drawn every frame.
	var baked = false
	var tiles: Array = []

	func _enter_tree() -> void:
		if PoseCache.enabled and not baked:
			for i in 2:
				var vp = SubViewport.new()
				vp.size = Vector2i(1300, 1020)
				vp.disable_3d = true
				vp.gui_disable_input = true
				vp.render_target_update_mode = SubViewport.UPDATE_ONCE
				add_child(vp)
				var sp = StaticPainter.new()
				sp.hub = self
				sp.position = Vector2(-1300.0 * i, 300.0)
				vp.add_child(sp)
				tiles.append([vp.get_texture(), 1300.0 * i])
			baked = true

	func _draw() -> void:
		if baked:
			for tl in tiles:
				draw_texture(tl[0], Vector2(tl[1], -300.0))
		else:
			draw_static(self)
		_draw_dynamic()

	func draw_static(ci: CanvasItem) -> void:
		var W = 2600.0
		ci.draw_polygon(PackedVector2Array([Vector2(0, -300), Vector2(W, -300), Vector2(W, 720), Vector2(0, 720)]),
			PackedColorArray([Color("0c0908"), Color("0c0908"), Color("2a1a12"), Color("2a1a12")]))
		for i in 7:
			var y = 80.0 + i * 70.0
			var pts = PackedVector2Array()
			for k in 27:
				pts.append(Vector2(k * 100.0, y + sin(k * 1.7 + i) * 18.0))
			ci.draw_polyline(pts, Color(0.12, 0.08, 0.06), 6.0)
		var r = RandomNumberGenerator.new()
		r.seed = 3
		var cp = PackedVector2Array([Vector2(0, -300), Vector2(W, -300)])
		var x = W
		while x > 0.0:
			cp.append(Vector2(x, r.randf_range(-20, 20)))
			if r.randf() < 0.45:
				cp.append(Vector2(x - 18, r.randf_range(50, 130)))
			x -= r.randf_range(50, 110)
		cp.append(Vector2(0, 0))
		ci.draw_colored_polygon(cp, Color("120d0b"))
		# war room alcove + map table + lamps
		ci.draw_rect(Rect2(40, 330, 420, 270), Color("1a1310"))
		ci.draw_arc(Vector2(250, 330), 210.0, PI, TAU, 24, Color("3a2c22"), 12.0)
		Painter.poly(ci, Painter.pts([Vector2(140, 560), Vector2(360, 560), Vector2(380, 520), Vector2(120, 520)]), Painter.WOOD, 3.0)
		Painter.poly(ci, Painter.pts([Vector2(132, 522), Vector2(368, 522), Vector2(352, 506), Vector2(148, 506)]), Color("c8b07a"), 2.0)
		for k in 6:
			ci.draw_circle(Vector2(170 + k * 34, 514), 3.5, Color(0.7, 0.2, 0.15) if k % 2 else Color(0.25, 0.45, 0.8))
		ci.draw_rect(Rect2(160, 560, 14, 40), Painter.WOOD_D)
		ci.draw_rect(Rect2(326, 560, 14, 40), Painter.WOOD_D)
		for lx in [110.0, 390.0]:
			ci.draw_line(Vector2(lx, 340), Vector2(lx, 420), Color(0.2, 0.2, 0.2), 2.0)
			Painter.glow(ci, Vector2(lx, 430), 40.0, Color(1, 0.75, 0.35, 0.7))
			ci.draw_circle(Vector2(lx, 430), 6, Color(1, 0.9, 0.6))
		# armory backdrop, gate opening, racks, emblem
		ci.draw_rect(Rect2(560, 300, 300, 300), Color("231a14"))
		Painter.poly(ci, Painter.pts([Vector2(600, 600), Vector2(600, 400), Vector2(710, 330), Vector2(820, 400), Vector2(820, 600)]), Color("0f0b09"), 3.0)
		for side in [0, 1]:
			var rx = 570.0 + side * 270.0
			ci.draw_rect(Rect2(rx, 420, 14, 170), Painter.WOOD_D)
			for k in 4:
				var gy = 440.0 + k * 38.0
				Painter.bar(ci, Vector2(rx - 12 + side * 4, gy), -1.3, 40, 4.0, Painter.WOOD, 1.0)
				Painter.bar(ci, Vector2(rx - 12 + side * 4, gy) + Vector2.from_angle(-1.3) * 18, -1.3, 22, 2.5, Painter.IRON_D, 1.0)
		Painter.circ(ci, Vector2(710, 310), 20, Painter.BRASS, 3.0)
		# the great anvil + glowing ingot
		Painter.poly(ci, Painter.pts([Vector2(1210, 600), Vector2(1390, 600), Vector2(1360, 580), Vector2(1420, 560), Vector2(1420, 540), Vector2(1180, 540), Vector2(1240, 580)]), Painter.IRON_D, 4.0)
		Painter.rrect(ci, Rect2(1270, 528, 60, 12), Color(1.0, 0.6, 0.15), 2.0, 2.0)
		# assembly bay gantry + scaffold + hazard stripes
		ci.draw_rect(Rect2(1640, 220, 16, 380), Painter.IRON_D)
		ci.draw_rect(Rect2(2100, 220, 16, 380), Painter.IRON_D)
		ci.draw_rect(Rect2(1640, 220, 476, 18), Painter.IRON)
		for k in 9:
			ci.draw_line(Vector2(1656 + k * 52, 238), Vector2(1682 + k * 52, 220), Painter.IRON_D, 3.0)
		for k in 4:
			ci.draw_rect(Rect2(1680, 300 + k * 70, 180, 6), Painter.WOOD_D)
		for k in 12:
			ci.draw_line(Vector2(1660 + k * 38, 600), Vector2(1680 + k * 38, 590), Color("d8b02a"), 5.0)
		# hall of records
		ci.draw_rect(Rect2(2170, 300, 230, 300), Color("1d1511"))
		for row in 5:
			var y2 = 320.0 + row * 54.0
			ci.draw_rect(Rect2(2180, y2 + 40, 210, 8), Painter.WOOD_D)
			var bx = 2186.0
			var rr = RandomNumberGenerator.new()
			rr.seed = row * 13
			while bx < 2380.0:
				var bw = rr.randf_range(8, 16)
				var bh = rr.randf_range(26, 38)
				ci.draw_rect(Rect2(bx, y2 + 40 - bh, bw, bh), Color(rr.randf_range(0.3, 0.6), rr.randf_range(0.15, 0.3), 0.1))
				bx += bw + 2.0
		# valve pipes
		ci.draw_rect(Rect2(2440, 380, 30, 220), Painter.COPPER_D)
		ci.draw_rect(Rect2(2550, 340, 30, 260), Painter.COPPER_D)
		# floor, rails and sleepers
		ci.draw_rect(Rect2(0, 600, W, 140), Color("2b211b"))
		ci.draw_rect(Rect2(0, 598, W, 5), Color("4a3a2c"))
		ci.draw_line(Vector2(0, 690), Vector2(W, 690), Color(0.4, 0.38, 0.36), 3.0)
		ci.draw_line(Vector2(0, 704), Vector2(W, 704), Color(0.4, 0.38, 0.36), 3.0)
		var sx = 0.0
		while sx < W:
			ci.draw_rect(Rect2(sx, 686, 8, 22), Color("4a2e18"))
			sx += 34.0

	func _draw_dynamic() -> void:
		var W = 2600.0
		for v in 9:
			var vx = 150.0 + v * 290.0
			var glow = 0.5 + 0.5 * sin(t * 1.3 + v)
			var vp = PackedVector2Array()
			for k in 8:
				vp.append(Vector2(vx + sin(k * 2.3 + v) * 30.0, -60.0 + k * 70.0))
			draw_polyline(vp, Color(1.0, 0.35, 0.05, 0.25 + 0.25 * glow), 4.0)
		for lf in [520.0, 2180.0]:
			for k in 3:
				var fxx = lf + k * 10.0
				draw_line(Vector2(fxx, 40), Vector2(fxx + sin(t * 2.0 + k) * 4.0, 520), Color(1.0, 0.45 + k * 0.1, 0.08, 0.75), 6.0 - k)
			Painter.glow(self, Vector2(lf + 10, 520), 70.0, Color(1, 0.4, 0.1, 0.6))
		# war-room banners
		for bx in [70.0, 410.0]:
			var wv = sin(t * 1.5 + bx) * 4.0
			Painter.poly(self, Painter.pts([Vector2(bx, 350), Vector2(bx + 30, 350), Vector2(bx + 30 + wv, 450), Vector2(bx + 15 + wv, 435), Vector2(bx + wv, 450)]), Painter.DEEP_BLUE, 2.0)
			Painter.circ(self, Vector2(bx + 15 + wv * 0.5, 390), 7, Painter.BRASS, 1.5)
		# portcullis
		var lift = 40.0 + sin(t * 0.5) * 30.0
		for k in 8:
			draw_line(Vector2(612 + k * 28, 330), Vector2(612 + k * 28, 600 - lift), Color("4a4038"), 4.0)
		for k in 6:
			draw_line(Vector2(604, 410 + k * 34 - lift), Vector2(816, 410 + k * 34 - lift), Color("4a4038"), 4.0)
		_forge_heart()
		# gantry crane
		var cx = 1760.0 + sin(t * 0.4) * 160.0
		Painter.rrect(self, Rect2(cx - 22, 236, 44, 22), Color("c9a020"), 2.0, 3.0)
		draw_line(Vector2(cx, 258), Vector2(cx, 340 + sin(t) * 20.0), Color(0.3, 0.3, 0.3), 3.0)
		Painter.rrect(self, Rect2(cx - 14, 340 + sin(t) * 20.0, 28, 20), Painter.IRON, 2.0, 2.0)
		# records lamp
		Painter.glow(self, Vector2(2285, 290), 50, Color(0.5, 0.75, 1.0, 0.5 + 0.2 * sin(t * 2.0)))
		draw_circle(Vector2(2285, 290), 7, Color(0.8, 0.95, 1.0))
		# pressure valves
		var vc = Vector2(2510, 420)
		var ang = t * 0.6
		Painter.circ(self, vc, 34, Painter.IRON_D, 3.0)
		for k in 6:
			draw_line(vc, vc + Vector2.from_angle(ang + k * TAU / 6.0) * 30.0, Color("a0322a"), 5.0)
		Painter.circ(self, vc, 8, Painter.BRASS, 2.0)
		for k in 3:
			var gc = Vector2(2460 + k * 40, 330)
			Painter.circ(self, gc, 14, Painter.BRASS, 2.0)
			draw_circle(gc, 10, Color("efe6cf"))
			draw_line(gc, gc + Vector2.from_angle(-2.0 + 1.5 * (0.5 + 0.5 * sin(t * (1.0 + k)))) * 9.0, Color(0.7, 0.1, 0.1), 2.0)
		Painter.smoke_puff(self, Vector2(2565, 330), t, 4, Color(1, 1, 1, 0.35))
		# lava channel with drifting embers (dot texture: one batch)
		var lc = 0.7 + 0.3 * sin(t * 2.0)
		draw_rect(Rect2(1000, 640, 600, 18), Color(1.0, 0.42, 0.08, lc))
		for k in 20:
			draw_texture_rect(FxLayer.DOT, Rect2(997 + fmod(t * 30.0 + k * 31.0, 600.0), 646, 6, 6), false, Color(1, 0.85, 0.4, 0.8))
		for c in carts:
			var cxx: float = c * (W + 200.0) - 100.0
			Painter.poly(self, Painter.pts([Vector2(cxx - 34, 650), Vector2(cxx + 34, 650), Vector2(cxx + 28, 684), Vector2(cxx - 28, 684)]), Painter.IRON_D, 2.5)
			for k in 4:
				draw_circle(Vector2(cxx - 18 + k * 12, 646), 7.0, Color(0.95, 0.55, 0.15) if k % 2 == 0 else Color(0.5, 0.45, 0.4))
			Painter.wheel(self, Vector2(cxx - 18, 690), 8.0, t * 6.0, Painter.IRON_D, Painter.BRASS, 5)
			Painter.wheel(self, Vector2(cxx + 18, 690), 8.0, t * 6.0, Painter.IRON_D, Painter.BRASS, 5)
		for sp in sparks:
			var q: Vector2 = sp[0]
			draw_texture_rect(FxLayer.DOT, Rect2(q.x - 2.5, q.y - 2.5, 5, 5), false, Color(1, 0.8, 0.35, sp[2]))

	func _forge_heart() -> void:
		var c = Vector2(1300, 330)
		var pulse = 0.85 + 0.15 * sin(t * 2.2) + 0.05 * sin(t * 9.0)
		for i in 9:
			draw_circle(c, 330.0 - i * 32.0, Color(1.0, 0.42, 0.08, 0.045 * pulse))
		for k in 4:
			var ax = c.x - 150.0 + k * 100.0
			var pts = PackedVector2Array()
			for j in 12:
				pts.append(Vector2(ax + sin(j * 0.6 + t + k) * 3.0, -40.0 + j * 22.0))
			draw_polyline(pts, Color("5a5048"), 4.0)
		for ring in 3:
			var ang = t * (0.3 + ring * 0.17) * (1.0 if ring % 2 == 0 else -1.0)
			var rx = 150.0 - ring * 22.0
			var ry = absf(cos(ang)) * rx * 0.9 + 12.0
			var pts2 = Painter.ell_pts(c, rx, ry, ring * 0.6, 32)
			pts2.append(pts2[0])
			draw_polyline(pts2, Painter.OUT, 13.0)
			draw_polyline(pts2, Painter.BRASS.darkened(ring * 0.12), 8.0)
			for j in 8:
				draw_texture_rect(FxLayer.DOT, Rect2(pts2[j * 4] - Vector2(3.5, 3.5), Vector2(7, 7)), false, Painter.BRASS.lightened(0.3))
		draw_circle(c, 92.0 * pulse, Color(1.0, 0.45, 0.08))
		draw_circle(c, 70.0 * pulse, Color(1.0, 0.7, 0.2))
		draw_circle(c, 40.0 * pulse, Color(1.0, 0.95, 0.65))
		for k in 10:
			var a2 = t * 0.8 + k * TAU / 10.0
			draw_texture_rect(FxLayer.DOT, Rect2(c + Vector2.from_angle(a2) * 78.0 * pulse - Vector2(8, 8), Vector2(16, 16)), false, Color(1.0, 0.55, 0.1, 0.8))
		# steam hammer
		var strike = fmod(t, 1.6)
		var hy = 548.0 - (0.0 if strike < 0.12 else minf(1.0, (strike - 0.12) / 1.2) * 120.0)
		draw_line(Vector2(1300, 40), Vector2(1300, hy - 60), Painter.OUT, 18.0)
		draw_line(Vector2(1300, 40), Vector2(1300, hy - 60), Painter.IRON.lightened(0.3), 12.0)
		Painter.rrect(self, Rect2(1260, hy - 70, 80, 64), Painter.IRON, 3.0, 6.0)
		draw_line(Vector2(1262, hy - 38), Vector2(1338, hy - 38), Painter.FORGE, 4.0)
		Painter.rivets(self, Vector2(1266, hy - 62), Vector2(1334, hy - 62), 5)
		if strike < 0.3:
			Painter.glow(self, Vector2(1300, 545), 60, Color(1, 0.7, 0.3, 0.9 * (1.0 - strike / 0.3)))
		for bx in [1080.0, 1520.0]:
			var squash = 0.7 + 0.3 * sin(t * 2.5 + bx)
			Painter.poly(self, Painter.pts([Vector2(bx - 50, 590), Vector2(bx + 50, 590), Vector2(bx + 40, 590 - 80 * squash), Vector2(bx - 40, 590 - 80 * squash)]), Painter.LEATHER, 3.0)
			for k in 3:
				draw_line(Vector2(bx - 44, 590 - 80 * squash * (k + 1) / 4.0), Vector2(bx + 44, 590 - 80 * squash * (k + 1) / 4.0), Painter.LEATHER_D, 3.0)
			draw_line(Vector2(bx, 590 - 80 * squash), Vector2(bx + (1300 - bx) * 0.3, 470), Painter.COPPER, 7.0)


class StaticPainter extends Node2D:
	var hub

	func _draw() -> void:
		hub.draw_static(self)
