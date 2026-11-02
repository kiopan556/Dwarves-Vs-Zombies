class_name RealmMap
extends Control
## M004 stage select: a side-on cross-section of the realm for one act, explored by dragging.
## Each stage is a painted landmark on (or inside) the mountain: gatehouses, carved stairs, mine
## headframes over deep caverns, chapel ruins, smelters, crag eyries; boss stages are set pieces
## (the Maw, the Belfry, the Ossuary Hall). The road runs from the dwarven hold on the left toward
## the undead on the right. Cleared ground flies dwarven banners and lit windows; past the front
## line, corruption fog rolls over darkened landmarks.
##
## Static art (sky, two parallax ranges, terrain + road + landmarks) is baked once per open into
## three textures, so the screen costs a handful of draw calls; only small live details (clouds,
## mist, smoke, beacon, patrol, selection) are drawn per frame. Headless runs draw live.

signal stage_selected(stage_id: String)

const DH := 540.0            # design height of the world
const STEP := 118.0          # distance between stage landmarks
const X0 := 190.0
const WW := X0 * 2.0 + STEP * 29.0 + 60.0   # world width (design units)

var act := 1
var selected := ""
var scroll := 0.0            # world x (design units) at the view's left edge
var _vel := 0.0
var _target := -1.0
var _drag := false
var _drag_moved := 0.0
var _press_pos := Vector2.ZERO
var _t := 0.0
var stages: Array = []       # 30 stage dicts of this act
var pts: Array = []          # landmark anchor (design units)
var under: Array = []        # landmark is underground
var aloft: Array = []        # M006: landmark floats on an island above the surface
var road: PackedVector2Array
var frontier := 0            # index of the first uncleared stage
var drawer_w := 0.0          # px covered by the detail drawer (for centring)
var _tex := {}               # layer -> Texture2D
var _vps: Array = []
var _baked := false
var _patrol: Array = []
var _rng := RandomNumberGenerator.new()

const PALETTE := {
	1: {"sky0": "1b2236", "sky1": "c88858", "sky_c": "2b2236", "sky_c1": "6a4a6a", "far": "3d4660", "mid": "2d3446", "snow": "d8dde8",
		"ground": "4c4a3c", "grass": "5c6a3c", "rock": "2e2822", "strata": "3c3229", "deep": "16120f", "fog": "6a8a5a"},
	2: {"sky0": "1c241c", "sky1": "8a9a5a", "sky_c": "1e1a22", "sky_c1": "5a6a3a", "far": "3a4436", "mid": "2c3428", "snow": "a8b098",
		"ground": "3e4430", "grass": "4a5a2a", "rock": "29261e", "strata": "353124", "deep": "14120d", "fog": "8aa060"},
	3: {"sky0": "2a5a98", "sky1": "b8d8ec", "sky_c": "2a2a48", "sky_c1": "6a6a8a", "far": "6a86a8", "mid": "4a6280", "snow": "eef4fa",
		"ground": "5a6448", "grass": "6a8a48", "rock": "3a3630", "strata": "48423a", "deep": "1a1814", "fog": "8a9ab0"},
	4: {"sky0": "2a1610", "sky1": "c8682a", "sky_c": "1e1212", "sky_c1": "6a3a2a", "far": "4a3028", "mid": "3a2620", "snow": "8a6a5a",
		"ground": "4a3a2c", "grass": "5a4a2c", "rock": "2a221c", "strata": "3a2e24", "deep": "140f0c", "fog": "9a6a4a"},
	5: {"sky0": "0e0818", "sky1": "5a2a6a", "sky_c": "0a0612", "sky_c1": "3a1a4a", "far": "2a1e3a", "mid": "20182e", "snow": "8a6aa8",
		"ground": "2e2636", "grass": "3a2a4a", "rock": "1e1824", "strata": "2a2232", "deep": "0c0a10", "fog": "8a5ab0"},
	# M008 "rift sealed": after stage 150 the whole Act V map turns to a cold, clean dawn
	6: {"sky0": "1e2440", "sky1": "c8906a", "sky_c": "2a2a48", "sky_c1": "9a7a8a", "far": "3e3a52", "mid": "2e2c40", "snow": "c8c0d8",
		"ground": "3e3a40", "grass": "4a5040", "rock": "26222a", "strata": "322c36", "deep": "100e14", "fog": "b8a8c8"},
}


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(func(): _clamp_scroll(); queue_redraw())


func pal(k: String) -> Color:
	return Color(String(PALETTE[6 if act == 5 and sealed() else act][k]))


## M008: the Black Rift is sealed once the final stage is cleared (the Act V map changes for good).
func sealed() -> bool:
	return GameState.is_cleared("s150")


func view_scale() -> float:
	return maxf(0.2, size.y / DH)


func max_scroll() -> float:
	return maxf(0.0, WW - size.x / view_scale())


# ================================================================== setup
func setup(p_act: int, p_selected: String) -> void:
	act = p_act
	selected = p_selected
	stages = []
	for i in 30:
		stages.append(Registry.stage_by_index((act - 1) * 30 + i + 1))
	frontier = 30
	for i in 30:
		if not GameState.is_cleared(stages[i].id):
			frontier = i
			break
	_layout()
	_free_bake()
	_baked = false
	_spawn_patrol()
	var si = _index_of(selected)
	scroll = clampf(pts[si if si >= 0 else mini(frontier, 29)].x - size.x / view_scale() * 0.4, 0.0, max_scroll())
	_target = -1.0
	queue_redraw()
	if DisplayServer.get_name() != "headless":
		_bake.call_deferred()


func _index_of(id: String) -> int:
	for i in stages.size():
		if stages[i].id == id:
			return i
	return -1


const ENV_BUMP := {"high_ridge": -105.0, "ridge": -55.0, "mountain_pass": -35.0, "mountain_gate": 15.0, "mine_entrance": -10.0,
	"ruined_outpost": -15.0, "foundry_outpost": 10.0, "mine_deep": 5.0, "mine_flooded": 20.0, "broken_ridge": -60.0, "airborne_ruins": -10.0, "open_plains": 12.0,
	"rift_sky": -80.0, "realm_gate": -20.0, "shattered_fort": -30.0, "necro_waste": 14.0, "ruined_citadel": -36.0,
	"plague_marsh": 38.0, "dead_forest": -26.0, "ruined_road": -8.0, "corrupted_mine": 8.0,
	"industrial_city": 6.0, "destroyed_forge": -22.0, "infested_factory": 14.0, "mech_graveyard": 24.0}
const UNDERGROUND := ["mine_deep", "mine_flooded", "corrupted_mine"]
## M006: landmarks drawn "aloft" on a floating island well above the surface, reached by airship route
const ALOFT := ["airborne_ruins", "rift_sky"]
const ALOFT_H := 150.0


func surf_y(x: float) -> float:
	var y = 352.0 + 42.0 * sin(x * 0.0023 + act) + 18.0 * sin(x * 0.0071 + act * 2.0)
	if act == 2:
		y += 9.0 * sin(x * 0.019)   # the lowlands roll
	for i in pts.size():
		var b = float(ENV_BUMP.get(String(stages[i].get("env", "")), 0.0))
		if b != 0.0:
			var d = (x - X0 - i * STEP) / 64.0
			y += b * exp(-d * d)
	return clampf(y, 150.0, 430.0)


func _layout() -> void:
	pts = []
	under = []
	aloft = []
	for i in 30:
		pts.append(Vector2(X0 + i * STEP, 0))   # x first: surf_y reads pts.size()
	for i in 30:
		var env = String(stages[i].get("env", ""))
		var ug = env in UNDERGROUND or (stages[i].get("boss") == "mine_maw")
		var al = env in ALOFT
		under.append(ug)
		aloft.append(al)
		var x = X0 + i * STEP
		pts[i] = Vector2(x, surf_y(x) + (112.0 if ug else 0.0) - (ALOFT_H + 14.0 * float(i % 2) if al else 0.0))
		if al:
			pts[i].y = maxf(pts[i].y, 96.0)
	# road: along the surface, dropping into a shaft for each underground landmark
	road = PackedVector2Array()
	road.append(Vector2(0, surf_y(0)))
	for i in 30:
		var x = pts[i].x
		var x_prev = road[road.size() - 1].x
		var xx = x_prev + 14.0
		while xx < x - (34.0 if under[i] else 0.0):
			road.append(Vector2(xx, surf_y(xx)))
			xx += 14.0
		if under[i]:
			road.append(Vector2(x - 30, surf_y(x - 30)))
			road.append(Vector2(x - 12, pts[i].y + 8))
			road.append(Vector2(x + 12, pts[i].y + 8))
			road.append(Vector2(x + 30, surf_y(x + 30)))
		else:
			road.append(Vector2(x, surf_y(x)))   # aloft landmarks: the road runs on below; an airship route climbs to them
	var xe = road[road.size() - 1].x + 14.0
	while xe < WW:
		road.append(Vector2(xe, surf_y(xe)))
		xe += 14.0


func road_y(x: float) -> float:
	for i in range(1, road.size()):
		if road[i].x >= x:
			var a: Vector2 = road[i - 1]
			var b: Vector2 = road[i]
			return lerpf(a.y, b.y, clampf((x - a.x) / maxf(1.0, b.x - a.x), 0.0, 1.0))
	return surf_y(x)


# ================================================================== baking
class _Layer extends Node2D:
	var map
	var layer = ""
	func _draw() -> void:
		map.paint(self, layer)


func _free_bake() -> void:
	for vp in _vps:
		if is_instance_valid(vp):
			vp.queue_free()
	_vps.clear()
	_tex.clear()


func _bake() -> void:
	if not is_inside_tree():
		return
	var specs = {"far": 0.5, "mid": 0.5, "near": 1.0}
	for layer in specs:
		var k: float = specs[layer]
		var vp = SubViewport.new()
		vp.size = Vector2i(int(WW * k), int(DH * k))
		vp.transparent_bg = layer != "far"
		vp.disable_3d = true
		vp.gui_disable_input = true
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		var n = _Layer.new()
		n.map = self
		n.layer = layer
		n.scale = Vector2(k, k)
		vp.add_child(n)
		add_child(vp)
		_vps.append(vp)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	if _vps.size() == 3:
		_tex = {"far": _vps[0].get_texture(), "mid": _vps[1].get_texture(), "near": _vps[2].get_texture()}
		_baked = true
	queue_redraw()


# ================================================================== static painting
func paint(ci: CanvasItem, layer: String) -> void:
	match layer:
		"far":
			_paint_sky(ci)
			_paint_range(ci, 0.0, 120.0, 200.0, pal("far"), true, 7)
		"mid":
			_paint_range(ci, 60.0, 210.0, 260.0, pal("mid"), false, 13)
		"near":
			_paint_terrain(ci)


func _paint_sky(ci: CanvasItem) -> void:
	# warm dawn over the dwarven hold on the left, a bruised undead sky on the right
	var n = 24
	for i in n:
		var x0 = WW * i / n
		var x1 = WW * (i + 1) / n
		var k0 = smoothstep(0.25, 0.95, float(i) / n)
		var k1 = smoothstep(0.25, 0.95, float(i + 1) / n)
		var top0 = pal("sky0").lerp(pal("sky_c"), k0)
		var top1 = pal("sky0").lerp(pal("sky_c"), k1)
		var bot0 = pal("sky1").lerp(pal("sky_c1"), k0)
		var bot1 = pal("sky1").lerp(pal("sky_c1"), k1)
		ci.draw_polygon(PackedVector2Array([Vector2(x0, 0), Vector2(x1, 0), Vector2(x1, DH), Vector2(x0, DH)]), PackedColorArray([top0, top1, bot1, bot0]))
	_rng.seed = act * 31
	for i in 70:
		var sp = Vector2(_rng.randf() * WW, _rng.randf() * 170.0)
		ci.draw_circle(sp, _rng.randf_range(0.6, 1.5), Color(1, 1, 1, _rng.randf_range(0.1, 0.5) * (0.4 if act == 3 else 1.0)))
	if act == 1 or act == 3:
		ci.draw_circle(Vector2(260, 150), 46, Color(1.0, 0.85, 0.55, 0.18))
		ci.draw_circle(Vector2(260, 150), 26, Color(1.0, 0.9, 0.65, 0.55))
	if act == 4:
		ci.draw_circle(Vector2(WW * 0.82, 120), 60, Color(1, 0.4, 0.15, 0.15))
	if act == 5:
		_black_rift(ci)


func _paint_range(ci: CanvasItem, y_off: float, peak: float, base_y: float, col: Color, snow: bool, seed: int) -> void:
	_rng.seed = act * 100 + seed
	var poly = PackedVector2Array([Vector2(0, DH)])
	var caps: Array = []
	var x = -40.0
	while x < WW + 80.0:
		var h = _rng.randf_range(0.35, 1.0)
		var px = x + _rng.randf_range(40, 90)
		var py = base_y + y_off - peak * h
		poly.append(Vector2(px, py))
		caps.append(Vector2(px, py))
		x = px + _rng.randf_range(40, 100)
		poly.append(Vector2(x, base_y + y_off - peak * h * _rng.randf_range(0.2, 0.5)))
	poly.append(Vector2(WW + 80, DH))
	ci.draw_colored_polygon(poly, col)
	if snow:
		for c in caps:
			var cc: Vector2 = c
			if cc.y < base_y + y_off - 60.0:
				ci.draw_colored_polygon(PackedVector2Array([cc, cc + Vector2(16, 18), cc + Vector2(6, 14), cc + Vector2(-2, 20), cc + Vector2(-9, 13), cc + Vector2(-16, 18)]), Color(pal("snow"), 0.75))
	# haze at the foot of the range
	ci.draw_polygon(PackedVector2Array([Vector2(0, base_y + y_off - 40), Vector2(WW, base_y + y_off - 40), Vector2(WW, DH), Vector2(0, DH)]),
		PackedColorArray([Color(pal("sky1"), 0.0), Color(pal("sky_c1"), 0.0), Color(pal("sky_c1"), 0.35), Color(pal("sky1"), 0.35)]))


func _paint_terrain(ci: CanvasItem) -> void:
	# mountain body in cross-section: surface crust, rock strata, the deep dark
	var surf = PackedVector2Array()
	var x = 0.0
	while x <= WW:
		surf.append(Vector2(x, surf_y(x)))
		x += 10.0
	var body = surf.duplicate()
	body.append(Vector2(WW, DH))
	body.append(Vector2(0, DH))
	ci.draw_colored_polygon(body, pal("rock"))
	for k in 4:
		var line = PackedVector2Array()
		for p in surf:
			line.append(p + Vector2(0, 34.0 + k * 34.0 + sin(p.x * 0.01 + k) * 6.0))
		ci.draw_polyline(line, pal("strata"), 3.0)
	ci.draw_polygon(PackedVector2Array([Vector2(0, DH - 70), Vector2(WW, DH - 70), Vector2(WW, DH), Vector2(0, DH)]),
		PackedColorArray([Color(pal("deep"), 0.0), Color(pal("deep"), 0.0), pal("deep"), pal("deep")]))
	# crust + grass lip
	ci.draw_polyline(surf, pal("ground"), 10.0)
	var lip = PackedVector2Array()
	for p in surf:
		lip.append(p + Vector2(0, -3))
	ci.draw_polyline(lip, pal("grass"), 4.0)
	# ore glints and buried bones in the rock
	_rng.seed = act * 77
	for i in 60:
		var bx = _rng.randf() * WW
		var by = surf_y(bx) + _rng.randf_range(40, 170)
		if by < DH - 10:
			if _rng.randf() < 0.6:
				ci.draw_circle(Vector2(bx, by), _rng.randf_range(1.5, 3.0), Color(1.0, 0.75, 0.35, 0.55) if act != 5 else Color(0.7, 0.4, 1.0, 0.6))
			else:
				ci.draw_line(Vector2(bx - 4, by), Vector2(bx + 4, by + 1), Color(0.85, 0.82, 0.72, 0.35), 2.0)
	# the dwarven hold at the start of the road
	_hold(ci, Vector2(70, surf_y(70)))
	# underground galleries (cut-away caverns) behind the road
	for i in 30:
		if under[i]:
			_cavern(ci, i)
	# the road
	var dark = PackedVector2Array()
	for p in road:
		dark.append(p + Vector2(0, 2))
	ci.draw_polyline(dark, Color(0, 0, 0, 0.5), 9.0)
	ci.draw_polyline(road, Color("7a5a38"), 5.0)
	for i in range(0, road.size() - 1, 2):
		ci.draw_line(road[i] + Vector2(0, -1), road[i].lerp(road[i + 1], 0.5) + Vector2(0, -1), Color("a88454"), 1.5)
	# scenery between landmarks
	_rng.seed = act * 11
	for i in 90:
		var sx = _rng.randf() * WW
		var near_lm = false
		for p in pts:
			if absf(p.x - sx) < 40.0:
				near_lm = true
				break
		if near_lm:
			continue
		_scenery(ci, Vector2(sx, surf_y(sx)), _rng.randf())
	# M006 floating islands with chains to the ground and dashed airship routes from the road
	for i in 30:
		if aloft[i]:
			_isle(ci, i)
	# landmarks
	for i in 30:
		_landmark(ci, i)


func _state(i: int) -> String:
	var st: Dictionary = stages[i]
	if not st.get("implemented", false):
		return "planned"
	if GameState.is_cleared(st.id):
		return "cleared"
	if GameState.stage_available(st):
		return "next"
	return "locked"


func _scenery(ci: CanvasItem, p: Vector2, r: float) -> void:
	var corrupt = p.x > (pts[mini(frontier, 29)].x - 40.0)
	match act:
		1, 3:
			if r < 0.55:
				var h = 18.0 + r * 30.0
				var c = Color("2c3a2a") if not corrupt else Color("2a2a26")
				ci.draw_line(p, p + Vector2(0, -h * 0.3), Color("3a2a1a"), 3.0)
				for k in 3:
					var w = (3 - k) * 5.0
					var yy = p.y - h * 0.25 - k * h * 0.25
					ci.draw_colored_polygon(PackedVector2Array([Vector2(p.x - w, yy), Vector2(p.x, yy - h * 0.4), Vector2(p.x + w, yy)]), c.lightened(k * 0.04))
			else:
				ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-9, 2), p + Vector2(-6, -7), p + Vector2(3, -9), p + Vector2(9, 2)]), pal("strata").lightened(0.1))
		2, 5:
			ci.draw_line(p, p + Vector2(r * 6.0, -24 - r * 20.0), Color("2a2420"), 3.0)
			ci.draw_line(p + Vector2(r * 3.0, -16), p + Vector2(r * 3.0 - 10, -26), Color("2a2420"), 2.0)
			ci.draw_line(p + Vector2(r * 4.0, -22), p + Vector2(r * 4.0 + 9, -30), Color("2a2420"), 2.0)
		4:
			ci.draw_rect(Rect2(p.x - 4, p.y - 20 - r * 20, 8, 20 + r * 20), Color("2a221c"))
			ci.draw_rect(Rect2(p.x - 6, p.y - 22 - r * 20, 12, 4), Color("3a2e24"))


func _hold(ci: CanvasItem, p: Vector2) -> void:
	# Stonehelm: the dwarven hold carved into the cliff where the road begins
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-70, 0), p + Vector2(-70, -150), p + Vector2(-20, -190), p + Vector2(40, -120), p + Vector2(60, 0)]), Color("3a332c"))
	Painter.rrect(ci, Rect2(p.x - 30, p.y - 70, 60, 70), Color("5a5048"), 2.0, 3.0)
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-14, 0), p + Vector2(-14, -34), p + Vector2(0, -46), p + Vector2(14, -34), p + Vector2(14, 0)]), Color("1a1410"))
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-10, 0), p + Vector2(-10, -30), p + Vector2(0, -40), p + Vector2(10, -30), p + Vector2(10, 0)]), Color(1.0, 0.6, 0.25, 0.75))
	for k in 3:
		ci.draw_rect(Rect2(p.x - 26 + k * 20, p.y - 64, 8, 10), Color(1.0, 0.75, 0.35, 0.8))
	ci.draw_line(p + Vector2(-34, -70), p + Vector2(-34, -110), Painter.WOOD_D, 3.0)
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-34, -110), p + Vector2(-8, -104), p + Vector2(-34, -96)]), Color("2a4a8a"))


func _cavern(ci: CanvasItem, i: int) -> void:
	var c: Vector2 = pts[i]
	var cav = Painter.ell_pts(c + Vector2(0, -12), 58, 40, 0.0, 22)
	ci.draw_colored_polygon(cav, pal("deep").lightened(0.04))
	ci.draw_polyline(cav + PackedVector2Array([cav[0]]), pal("strata").lightened(0.15), 3.0)
	# timber-lined shaft from the surface
	var top = surf_y(c.x)
	ci.draw_rect(Rect2(c.x - 34, top, 22, c.y - top - 4), pal("deep"))
	for k in int((c.y - top) / 18.0):
		ci.draw_line(Vector2(c.x - 36, top + 8 + k * 18), Vector2(c.x - 10, top + 8 + k * 18), Painter.WOOD_D, 3.0)
	ci.draw_line(Vector2(c.x - 36, top), Vector2(c.x - 36, c.y), Painter.WOOD, 3.0)
	ci.draw_line(Vector2(c.x - 10, top), Vector2(c.x - 10, c.y), Painter.WOOD, 3.0)
	# crystals / ore in the gallery walls
	for k in 5:
		var a = PI + 0.3 + k * 0.6
		var q = c + Vector2(0, -12) + Vector2.from_angle(a) * Vector2(52, 34)
		var glow = Color(0.6, 0.9, 1.0, 0.8) if act != 5 else Color(0.8, 0.5, 1.0, 0.8)
		ci.draw_colored_polygon(PackedVector2Array([q, q + Vector2(-3, 6), q + Vector2(3, 6)]), glow)


# ------------------------------------------------------------------ landmarks
func _landmark(ci: CanvasItem, i: int) -> void:
	var st: Dictionary = stages[i]
	var p: Vector2 = pts[i]
	var s = _state(i)
	var env = String(st.get("env", ""))
	var boss = st.get("boss")
	var lit = Color(1.0, 0.78, 0.38) if s == "cleared" or s == "next" else (Color(0.55, 1.0, 0.5) if s == "locked" else Color(0.3, 0.3, 0.32))
	var stone = Color("6a625a") if s != "planned" else Color("3a3836")
	if s == "locked":
		stone = stone.lerp(Color("4a5a4a"), 0.35).darkened(0.15)
	if boss != null:
		_boss_landmark(ci, p, String(boss), s, lit, stone)
	elif env in ["dead_forest", "plague_marsh", "ruined_road", "corrupted_mine"]:
		_act2_landmark(ci, p, env, s, lit, stone)
	elif env in ["open_plains", "broken_ridge", "airborne_ruins", "shattered_fort"]:
		_act3_landmark(ci, p, env, s, lit, stone)
	elif env in ["industrial_city", "destroyed_forge", "infested_factory", "mech_graveyard"]:
		_act4_landmark(ci, p, env, s, lit, stone)
	elif env in ["necro_waste", "rift_sky", "ruined_citadel", "realm_gate"]:
		_act5_landmark(ci, p, env, s, lit, stone)
	else:
		match env:
			"mountain_gate", "realm_gate", "shattered_fort", "ruined_citadel":
				_gate(ci, p, stone, lit, env != "mountain_gate")
			"mountain_pass", "ruined_road":
				_stairs(ci, p, stone, lit)
			"mine_entrance", "corrupted_mine":
				_mine_mouth(ci, p, stone, lit)
			"mine_deep", "mine_flooded":
				_gallery(ci, p, lit, env == "mine_flooded")
			"ridge", "broken_ridge", "open_plains":
				_watchtower(ci, p, stone, lit)
			"high_ridge", "airborne_ruins", "rift_sky":
				_eyrie(ci, p, stone, lit)
			"ruined_outpost", "dead_forest", "plague_marsh":
				_chapel(ci, p, stone, lit)
			"foundry_outpost", "industrial_city", "destroyed_forge", "infested_factory", "mech_graveyard", "necro_waste":
				_smelter(ci, p, stone, lit)
			_:
				_watchtower(ci, p, stone, lit)
	# headframe over underground landmarks
	if under[i]:
		_headframe(ci, Vector2(p.x - 23, surf_y(p.x - 23)), stone)
	# banner of ownership
	var flag_at = p + Vector2(-26, -2) if not under[i] else Vector2(p.x - 23, surf_y(p.x - 23)) + Vector2(14, -2)
	if s == "cleared":
		# M005 star reward (cosmetic): a three-star stage flies a gold-trimmed banner
		# M007 Heroic reward (cosmetic): a stage cleared on Heroic flies a red-gold banner with a gold crest
		var three = GameState.star_count(String(st.id)) >= 3
		if GameState.heroic_cleared(String(st.id)):
			_banner(ci, flag_at, Color("8a1a1e"), Color("ffcf5a"))
			ci.draw_line(flag_at + Vector2(0, -34), flag_at + Vector2(16, -31), Color("ffcf5a"), 1.5)
			ci.draw_line(flag_at + Vector2(0, -22), flag_at + Vector2(16, -21), Color("ffcf5a"), 1.5)
		else:
			_banner(ci, flag_at, Color("8a6a1a") if three else Color("2a4a8a"), Color("ffe08a") if three else Painter.BRASS)
	elif s == "locked" and st.get("implemented", false):
		_banner(ci, flag_at, Color("3a2a40"), Color(0.55, 1.0, 0.5))
	# signpost with the stage number
	var sign_at = p + Vector2(26, 0)
	ci.draw_line(sign_at, sign_at + Vector2(0, -18), Painter.WOOD_D, 2.5)
	var disc = sign_at + Vector2(0, -24)
	ci.draw_circle(disc, 10.5, Color("120e0b"))
	ci.draw_circle(disc, 9.0, Painter.BRASS if s != "planned" else Color("4a443e"))
	ci.draw_circle(disc, 7.0, Color("3a2a1a") if s != "cleared" else Color("2a3a22"))
	var f = UiKit.bold()
	var num = str(int(st.index))
	var fs = 11 if num.length() < 3 else 9
	ci.draw_string(f, disc + Vector2(-10, 4), num, HORIZONTAL_ALIGNMENT_CENTER, 20, fs, UiKit.TEXT if s != "planned" else Color("6a6258"))
	# M005: brass stars above the signpost for cleared stages
	if s == "cleared":
		var sv: Array = GameState.stars_for(String(st.id))
		for k in 3:
			var sp = disc + Vector2(-9 + k * 9, -16)
			_star(ci, sp, 3.6, Color("ffcf5a") if bool(sv[k]) else Color(0.25, 0.22, 0.2))


func _banner(ci: CanvasItem, at: Vector2, cloth: Color, emblem: Color) -> void:
	ci.draw_line(at, at + Vector2(0, -34), Painter.WOOD_D, 2.5)
	ci.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -34), at + Vector2(16, -31), at + Vector2(13, -26), at + Vector2(16, -21), at + Vector2(0, -22)]), cloth)
	ci.draw_circle(at + Vector2(7, -28), 2.5, emblem)


func _windows(ci: CanvasItem, rects: Array, lit: Color) -> void:
	for r in rects:
		ci.draw_rect(r, Color(0.08, 0.06, 0.05))
		ci.draw_rect(Rect2(r.position + Vector2(1, 1), r.size - Vector2(2, 2)), Color(lit, 0.85))


func _gate(ci: CanvasItem, p: Vector2, stone: Color, lit: Color, ruined: bool) -> void:
	for side in [-1.0, 1.0]:
		var tx = p.x + side * 20.0
		var h = 52.0 if not ruined else (40.0 if side < 0 else 30.0)
		Painter.rect(ci, Rect2(tx - 9, p.y - h, 18, h), stone, 2.0)
		for k in 3:
			ci.draw_rect(Rect2(tx - 9 + k * 7, p.y - h - 5, 4, 5), stone)
		_windows(ci, [Rect2(tx - 3, p.y - h + 12, 6, 8)], lit)
	Painter.rect(ci, Rect2(p.x - 13, p.y - 34, 26, 34), stone.darkened(0.1), 2.0)
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-8, 0), p + Vector2(-8, -18), p + Vector2(0, -25), p + Vector2(8, -18), p + Vector2(8, 0)]), Color("120e0b"))
	for k in 4:
		ci.draw_line(p + Vector2(-6 + k * 4, -20), p + Vector2(-6 + k * 4, 0), Painter.IRON_D, 1.5)


func _stairs(ci: CanvasItem, p: Vector2, stone: Color, lit: Color) -> void:
	for k in 6:
		ci.draw_rect(Rect2(p.x - 30 + k * 7, p.y - 4 - k * 6, 20, 6), stone.lightened(k * 0.02))
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(4, -36), p + Vector2(4, -60), p + Vector2(16, -70), p + Vector2(28, -60), p + Vector2(28, -36)]), stone.darkened(0.1))
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(9, -36), p + Vector2(9, -56), p + Vector2(16, -62), p + Vector2(23, -56), p + Vector2(23, -36)]), Color("120e0b"))
	ci.draw_circle(p + Vector2(16, -50), 3.0, Color(lit, 0.8))


func _mine_mouth(ci: CanvasItem, p: Vector2, stone: Color, lit: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-34, 0), p + Vector2(-30, -48), p + Vector2(-6, -64), p + Vector2(24, -52), p + Vector2(34, 0)]), stone.darkened(0.25))
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-14, 0), p + Vector2(-14, -28), p + Vector2(14, -28), p + Vector2(14, 0)]), Color("0e0b09"))
	Painter.bar(ci, p + Vector2(-17, 0), -PI / 2.0, 32, 4.0, Painter.WOOD, 1.5)
	Painter.bar(ci, p + Vector2(17, 0), -PI / 2.0, 32, 4.0, Painter.WOOD, 1.5)
	Painter.bar(ci, p + Vector2(-20, -30), 0.0, 40, 4.0, Painter.WOOD, 1.5)
	ci.draw_line(p + Vector2(-10, -2), p + Vector2(10, -2), Painter.IRON, 1.5)
	ci.draw_circle(p + Vector2(18, -24), 3.0, Color(lit, 0.9))
	Painter.rrect(ci, Rect2(p.x + 20, p.y - 10, 14, 8), Painter.IRON_D, 1.5, 1.0)


func _gallery(ci: CanvasItem, p: Vector2, lit: Color, flooded: bool) -> void:
	if flooded:
		ci.draw_colored_polygon(Painter.ell_pts(p + Vector2(4, 4), 40, 9, 0.0, 16), Color(0.06, 0.1, 0.12, 0.95))
		ci.draw_line(p + Vector2(-20, 2), p + Vector2(4, 2), Color(0.5, 0.7, 0.8, 0.4), 1.5)
		Painter.rrect(ci, Rect2(p.x + 4, p.y - 10, 16, 10), Painter.IRON_D, 1.5, 1.0)
	else:
		Painter.bar(ci, p + Vector2(-22, 0), -PI / 2.0, 30, 4.0, Painter.WOOD, 1.5)
		Painter.bar(ci, p + Vector2(18, 0), -PI / 2.0, 30, 4.0, Painter.WOOD, 1.5)
		Painter.bar(ci, p + Vector2(-26, -30), 0.0, 48, 4.0, Painter.WOOD, 1.5)
		Painter.rrect(ci, Rect2(p.x - 10, p.y - 12, 18, 11), Painter.IRON_D, 1.5, 1.0)
		ci.draw_circle(p + Vector2(-6, -16), 3.0, Color(1.0, 0.7, 0.3))
	ci.draw_circle(p + Vector2(-16, -22), 2.5, Color(lit, 0.9))


func _headframe(ci: CanvasItem, p: Vector2, stone: Color) -> void:
	ci.draw_line(p + Vector2(-12, 0), p + Vector2(0, -44), Painter.WOOD_D, 3.0)
	ci.draw_line(p + Vector2(12, 0), p + Vector2(0, -44), Painter.WOOD_D, 3.0)
	ci.draw_line(p + Vector2(-7, -20), p + Vector2(7, -20), Painter.WOOD_D, 2.0)
	Painter.wheel(ci, p + Vector2(0, -44), 8.0, 0.4, Painter.IRON_D, Painter.BRASS, 6)
	ci.draw_line(p + Vector2(0, -44), p + Vector2(0, 0), Color(0.3, 0.3, 0.3), 1.0)


func _watchtower(ci: CanvasItem, p: Vector2, stone: Color, lit: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-30, 0), p + Vector2(-22, -14), p + Vector2(18, -18), p + Vector2(30, 0)]), stone.darkened(0.2))
	Painter.rect(ci, Rect2(p.x - 9, p.y - 56, 18, 42), stone, 2.0)
	Painter.rect(ci, Rect2(p.x - 13, p.y - 62, 26, 8), stone.darkened(0.08), 2.0)
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-14, -62), p + Vector2(0, -78), p + Vector2(14, -62)]), Color("5a3a2a"))
	_windows(ci, [Rect2(p.x - 3, p.y - 48, 6, 8), Rect2(p.x - 3, p.y - 32, 6, 8)], lit)


func _eyrie(ci: CanvasItem, p: Vector2, stone: Color, lit: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-26, 0), p + Vector2(-16, -48), p + Vector2(-4, -70), p + Vector2(10, -62), p + Vector2(22, -30), p + Vector2(28, 0)]), stone.darkened(0.15))
	Painter.rect(ci, Rect2(p.x - 18, p.y - 74, 34, 6), Painter.WOOD, 1.5)
	Painter.rrect(ci, Rect2(p.x - 8, p.y - 90, 16, 16), stone, 2.0, 2.0)
	_windows(ci, [Rect2(p.x - 3, p.y - 86, 6, 7)], lit)
	ci.draw_line(p + Vector2(14, -74), p + Vector2(14, -98), Painter.WOOD_D, 2.0)
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(14, -98), p + Vector2(30, -94), p + Vector2(14, -90)]), Color("c86a2a"))
	for k in 3:
		ci.draw_line(p + Vector2(-40 + k * 6, -60 - k * 9), p + Vector2(-20 + k * 6, -62 - k * 9), Color(1, 1, 1, 0.35), 1.5)


func _chapel(ci: CanvasItem, p: Vector2, stone: Color, lit: Color) -> void:
	Painter.rect(ci, Rect2(p.x - 26, p.y - 30, 34, 30), stone, 2.0)
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-28, -30), p + Vector2(-9, -46), p + Vector2(10, -30)]), stone.darkened(0.2))
	Painter.rect(ci, Rect2(p.x + 8, p.y - 58, 14, 58), stone.lightened(0.05), 2.0)
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(6, -58), p + Vector2(15, -72), p + Vector2(24, -58)]), stone.darkened(0.25))
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(11, -52), p + Vector2(19, -52), p + Vector2(18, -44), p + Vector2(12, -44)]), Painter.BRASS.darkened(0.3))
	_windows(ci, [Rect2(p.x - 18, p.y - 22, 6, 12), Rect2(p.x - 6, p.y - 22, 6, 12)], lit)
	ci.draw_line(p + Vector2(-30, 0), p + Vector2(-34, -10), stone, 3.0)


func _smelter(ci: CanvasItem, p: Vector2, stone: Color, lit: Color) -> void:
	Painter.rect(ci, Rect2(p.x - 28, p.y - 30, 44, 30), stone.darkened(0.1), 2.0)
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-30, -30), p + Vector2(18, -30), p + Vector2(10, -40), p + Vector2(-22, -40)]), Color("4a3a2e"))
	for k in 2:
		Painter.rect(ci, Rect2(p.x - 20 + k * 18, p.y - 66 + k * 8, 9, 30 - k * 8), Painter.IRON_D, 1.5)
		ci.draw_rect(Rect2(p.x - 21 + k * 18, p.y - 68 + k * 8, 11, 3), Painter.BRASS.darkened(0.2))
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-8, 0), p + Vector2(-8, -14), p + Vector2(4, -14), p + Vector2(4, 0)]), Color(lit.lerp(Color(1, 0.4, 0.1), 0.5), 0.9))


func _boss_landmark(ci: CanvasItem, p: Vector2, boss: String, s: String, lit: Color, stone: Color) -> void:
	var dread = Color(0.75, 0.3, 0.85) if s != "cleared" else Color(1.0, 0.78, 0.38)
	match boss:
		"mine_maw":
			# a toothed throat opening in the gallery floor
			ci.draw_colored_polygon(Painter.ell_pts(p + Vector2(0, -4), 44, 22, 0.0, 22), Color("2a0e10"))
			ci.draw_colored_polygon(Painter.ell_pts(p + Vector2(0, -2), 30, 12, 0.0, 18), Color("0a0404"))
			for k in 9:
				var a = PI + 0.2 + k * (PI - 0.4) / 8.0
				var q = p + Vector2(0, -4) + Vector2.from_angle(a) * Vector2(40, 19)
				ci.draw_colored_polygon(PackedVector2Array([q + Vector2(-4, 0), q + Vector2(4, 0), (q - p) * 0.0 + q.lerp(p, 0.4)]), Color("e8e0c8"))
		"bellringer":
			Painter.rect(ci, Rect2(p.x - 18, p.y - 96, 36, 96), stone.darkened(0.15), 2.5)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-22, -96), p + Vector2(0, -128), p + Vector2(22, -96)]), stone.darkened(0.35))
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-12, -60), p + Vector2(-10, -84), p + Vector2(0, -90), p + Vector2(10, -84), p + Vector2(12, -60)]), Color("5a4a2a"))
			ci.draw_circle(p + Vector2(0, -58), 3.0, Color("2a2018"))
			for k in 3:
				ci.draw_arc(p + Vector2(0, -74), 26.0 + k * 10.0, -0.6, 0.6, 8, Color(dread, 0.5 - k * 0.12), 2.0)
				ci.draw_arc(p + Vector2(0, -74), 26.0 + k * 10.0, PI - 0.6, PI + 0.6, 8, Color(dread, 0.5 - k * 0.12), 2.0)
		"ossuary_matron":
			Painter.rect(ci, Rect2(p.x - 40, p.y - 52, 80, 52), Color("8a8270") if s != "planned" else stone, 2.5)
			for k in 5:
				var sx = p.x - 36 + k * 18
				var sh = 70.0 + (20.0 if k == 2 else 0.0)
				ci.draw_colored_polygon(PackedVector2Array([Vector2(sx - 6, p.y - 52), Vector2(sx, p.y - sh - 20), Vector2(sx + 6, p.y - 52)]), Color("d8d0b8"))
			ci.draw_circle(p + Vector2(0, -34), 12.0, Color("1a1014"))
			ci.draw_circle(p + Vector2(-4, -36), 3.0, Color(dread, 0.9))
			ci.draw_circle(p + Vector2(4, -36), 3.0, Color(dread, 0.9))
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-8, 0), p + Vector2(-8, -16), p + Vector2(0, -22), p + Vector2(8, -16), p + Vector2(8, 0)]), Color("0e0a0a"))
		"blightroot_behemoth":
			# a colossal rotting tree whose roots grip the road
			var bark = Color("3a2e22") if s != "planned" else stone
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-22, 0), p + Vector2(-14, -70), p + Vector2(-30, -112), p + Vector2(-6, -96), p + Vector2(4, -128), p + Vector2(12, -94), p + Vector2(34, -116), p + Vector2(18, -66), p + Vector2(24, 0)]), bark)
			for k in 4:
				var sgn = -1.0 if k % 2 == 0 else 1.0
				ci.draw_polyline(PackedVector2Array([p + Vector2(sgn * 14, -4), p + Vector2(sgn * (30 + k * 6), 2), p + Vector2(sgn * (46 + k * 8), -2 + k)]), bark.darkened(0.2), 4.0 - k * 0.5)
			ci.draw_circle(p + Vector2(0, -60), 7.0, Color(dread, 0.85))
			for k in 6:
				ci.draw_line(p + Vector2(-26 + k * 10, -100 + (k % 2) * 6), p + Vector2(-26 + k * 10, -84 + (k % 3) * 5), Color(0.45, 0.5, 0.3, 0.8), 1.5)
		"plague_regent":
			# a plague palace with censers
			var pal_c = Color("4a4a32") if s != "planned" else stone
			Painter.rect(ci, Rect2(p.x - 36, p.y - 48, 72, 48), pal_c, 2.0)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-40, -48), p + Vector2(0, -70), p + Vector2(40, -48)]), pal_c.darkened(0.25))
			for sx in [-30.0, 30.0]:
				Painter.rect(ci, Rect2(p.x + sx - 7, p.y - 84, 14, 40), pal_c.lightened(0.05), 2.0)
				ci.draw_colored_polygon(Painter.ell_pts(p + Vector2(sx, -88), 9, 9, 0.0, 12), pal_c.darkened(0.2))
				ci.draw_line(p + Vector2(sx, -97), p + Vector2(sx, -108), Painter.IRON_D, 1.5)
				ci.draw_circle(p + Vector2(sx, -111), 4.0, Color(0.6, 0.9, 0.25, 0.9) if s != "cleared" else Color(1.0, 0.7, 0.3))
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-9, 0), p + Vector2(-9, -20), p + Vector2(0, -28), p + Vector2(9, -20), p + Vector2(9, 0)]), Color("0e0a06"))
			if s != "cleared":
				for k in 3:
					ci.draw_circle(p + Vector2(-30 + k * 3, -118 - k * 9), 4.0 + k * 2.0, Color(0.6, 0.85, 0.25, 0.25 - k * 0.06))
					ci.draw_circle(p + Vector2(30 + k * 3, -118 - k * 9), 4.0 + k * 2.0, Color(0.6, 0.85, 0.25, 0.25 - k * 0.06))
		"gravewing_matriarch":
			# a gigantic carrion nest atop a dead tree
			var wood = Color("3a3024") if s != "planned" else stone
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-10, 0), p + Vector2(-6, -96), p + Vector2(6, -96), p + Vector2(12, 0)]), wood)
			ci.draw_line(p + Vector2(-4, -60), p + Vector2(-30, -82), wood, 4.0)
			ci.draw_line(p + Vector2(6, -70), p + Vector2(28, -88), wood, 4.0)
			var nest = Painter.ell_pts(p + Vector2(0, -104), 42, 14, 0.0, 18)
			ci.draw_colored_polygon(nest, Color("4a3a2a"))
			for k in 9:
				ci.draw_line(p + Vector2(-40 + k * 10, -110 + (k % 2) * 6), p + Vector2(-34 + k * 9, -96 - (k % 3) * 3), Color("6a5a40"), 2.0)
			for k in 3:
				ci.draw_circle(p + Vector2(-12 + k * 12, -116), 3.0, Color("e8e0c8"))
			if s != "cleared":
				for k in 4:
					var wp = p + Vector2(-50 + k * 32, -136 - (k % 2) * 12)
					ci.draw_polyline(PackedVector2Array([wp + Vector2(-7, 2), wp, wp + Vector2(7, 2)]), Color(0.1, 0.08, 0.1), 2.0)
		"bone_wyrm":
			# a skeletal wyrm coiled through a split ridge
			var rk = Color("5a5658") if s != "planned" else stone
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-44, 0), p + Vector2(-30, -110), p + Vector2(-6, -84), p + Vector2(-4, 0)]), rk)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(6, 0), p + Vector2(8, -92), p + Vector2(30, -124), p + Vector2(46, 0)]), rk.darkened(0.25))
			var bone = Color("e2dac0") if s != "planned" else Color("6a665e")
			var spine = PackedVector2Array()
			for k in 15:
				var f = float(k) / 14.0
				spine.append(p + Vector2(-48 + f * 100.0, -30 - sin(f * TAU * 1.2) * 34.0 - f * 30.0))
			ci.draw_polyline(spine, bone, 5.0)
			for k in range(1, 14, 2):
				var q: Vector2 = spine[k]
				ci.draw_line(q + Vector2(0, -7), q + Vector2(0, 7), bone, 2.0)
			var hd: Vector2 = spine[spine.size() - 1]
			ci.draw_colored_polygon(PackedVector2Array([hd + Vector2(-6, -6), hd + Vector2(16, -2), hd + Vector2(18, 4), hd + Vector2(-4, 6)]), bone)
			ci.draw_circle(hd + Vector2(4, -1), 2.5, Color(dread, 0.95))
		"hollow_admiral":
			# the ghost flagship moored in cloud beside its island
			var hull = Color("3a4a44") if s != "planned" else stone
			for k in 5:
				ci.draw_circle(p + Vector2(-46 + k * 22, 6 + (k % 2) * 4), 16.0, Color(1, 1, 1, 0.55))
			ci.draw_colored_polygon(Painter.ell_pts(p + Vector2(0, -58), 46, 16, 0.0, 18), Color("8a9a8a") if s != "planned" else stone.lightened(0.1))
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-34, -36), p + Vector2(34, -36), p + Vector2(26, -18), p + Vector2(-28, -18)]), hull)
			for k in 3:
				ci.draw_circle(p + Vector2(-18 + k * 18, -28), 3.0, Color(dread, 0.85) if s != "cleared" else Color(1.0, 0.75, 0.35))
			ci.draw_line(p + Vector2(0, -74), p + Vector2(0, -98), Painter.IRON_D, 2.0)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -98), p + Vector2(18, -94), p + Vector2(4, -88)]), Color("2a3a30"))
			ci.draw_line(p + Vector2(-34, -30), p + Vector2(-60, 4), Color(0.2, 0.2, 0.22), 1.5)
		"dread_sky_tyrant":
			# a storm throne of black clouds and lightning
			var cl = Color("24202e") if s != "cleared" else Color("6a6a7a")
			for k in 7:
				var a = PI + k * PI / 6.0
				ci.draw_circle(p + Vector2(0, -60) + Vector2.from_angle(a) * Vector2(46, 26), 18.0, cl)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-20, -40), p + Vector2(-16, -96), p + Vector2(-6, -84), p + Vector2(0, -112), p + Vector2(6, -84), p + Vector2(16, -96), p + Vector2(20, -40)]), Color("2a2434") if s != "planned" else stone)
			ci.draw_circle(p + Vector2(0, -70), 6.0, Color(dread, 0.9))
			if s != "cleared":
				ci.draw_polyline(PackedVector2Array([p + Vector2(30, -96), p + Vector2(22, -74), p + Vector2(34, -70), p + Vector2(24, -44)]), Color(0.8, 0.85, 1.0, 0.9), 2.0)
				ci.draw_polyline(PackedVector2Array([p + Vector2(-36, -90), p + Vector2(-28, -70), p + Vector2(-38, -64), p + Vector2(-30, -42)]), Color(0.8, 0.85, 1.0, 0.7), 1.5)
		"fallen_titan":
			# the Fallen Titan standing in a ring of scaffolding
			var iron = Color("4a4038") if s != "planned" else stone
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-16, 0), p + Vector2(-12, -46), p + Vector2(-4, -46), p + Vector2(-2, 0)]), iron.darkened(0.15))
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(4, 0), p + Vector2(6, -46), p + Vector2(14, -46), p + Vector2(18, 0)]), iron.darkened(0.15))
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-22, -46), p + Vector2(-26, -92), p + Vector2(-12, -108), p + Vector2(12, -108), p + Vector2(26, -92), p + Vector2(22, -46)]), iron)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-34, -100), p + Vector2(-22, -112), p + Vector2(-16, -96), p + Vector2(-30, -84)]), iron.lightened(0.08))
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(34, -100), p + Vector2(22, -112), p + Vector2(16, -96), p + Vector2(30, -84)]), iron.lightened(0.08))
			Painter.rect(ci, Rect2(p.x - 8, p.y - 126, 16, 18), iron.lightened(0.04), 1.5)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-5, -126), p + Vector2(0, -144), p + Vector2(5, -126)]), Painter.BRASS.darkened(0.3))
			ci.draw_rect(Rect2(p.x - 6, p.y - 120, 12, 3), Color(dread, 0.95))
			ci.draw_circle(p + Vector2(0, -80), 6.0, Color(dread, 0.85) if s != "cleared" else Color(1.0, 0.7, 0.3))
			# scaffolding ring
			var sc = Painter.WOOD_D
			for sx in [-44.0, -30.0, 30.0, 44.0]:
				ci.draw_line(p + Vector2(sx, 0), p + Vector2(sx, -118), sc, 2.0)
			for k in 4:
				var yy = -28.0 - k * 28.0
				ci.draw_line(p + Vector2(-46, yy), p + Vector2(-28, yy), sc, 2.0)
				ci.draw_line(p + Vector2(28, yy), p + Vector2(46, yy), sc, 2.0)
				ci.draw_line(p + Vector2(-44, yy), p + Vector2(-30, yy - 28), sc, 1.2)
				ci.draw_line(p + Vector2(30, yy), p + Vector2(44, yy - 28), sc, 1.2)
		"ashen_forge_tyrant":
			# an ash throne inside a furnace mouth
			var brick = Color("4a2a22") if s != "planned" else stone
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-50, 0), p + Vector2(-44, -96), p + Vector2(-24, -128), p + Vector2(24, -128), p + Vector2(44, -96), p + Vector2(50, 0)]), brick)
			for k in 4:
				ci.draw_line(p + Vector2(-46 + k * 2, -24 - k * 24), p + Vector2(46 - k * 2, -24 - k * 24), brick.darkened(0.3), 2.0)
			var mouth = Painter.ell_pts(p + Vector2(0, -2), 32, 70, 0.0, 18, PI, TAU)
			ci.draw_colored_polygon(mouth, Color("1a0806"))
			ci.draw_circle(p + Vector2(0, -24), 30.0, Color(1.0, 0.35, 0.1, 0.25 if s != "cleared" else 0.45))
			# the throne of ash
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-16, 0), p + Vector2(-14, -40), p + Vector2(-8, -52), p + Vector2(-2, -44), p + Vector2(2, -54), p + Vector2(8, -44), p + Vector2(14, -52), p + Vector2(16, 0)]), Color("5a5450"))
			ci.draw_rect(Rect2(p.x - 18, p.y - 18, 36, 6), Color("6a6460"))
			ci.draw_circle(p + Vector2(0, -32), 4.0, Color(dread, 0.9))
			Painter.rect(ci, Rect2(p.x - 10, p.y - 158, 20, 30), brick.darkened(0.15), 1.5)
		"corpse_colossus":
			# a mountain of corpses with a stitched siege engine on its back
			var flesh = Color("6a5a48") if s != "planned" else stone
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-58, 0), p + Vector2(-40, -40), p + Vector2(-22, -70), p + Vector2(4, -86), p + Vector2(30, -66), p + Vector2(48, -34), p + Vector2(60, 0)]), flesh)
			for k in 9:
				var lp = p + Vector2(-44 + k * 11, -14 - (k % 3) * 16 - absf(4.0 - k) * -4.0)
				ci.draw_circle(lp, 5.0, flesh.lightened(0.08 if k % 2 == 0 else -0.08))
				ci.draw_line(lp, lp + Vector2(6, -4 + (k % 2) * 8), Color("d8d0b8"), 1.5)
			# stitches
			for k in 5:
				ci.draw_line(p + Vector2(-30 + k * 12, -50 + (k % 2) * 6), p + Vector2(-26 + k * 12, -44 + (k % 2) * 6), Color("2a1a14"), 1.5)
			# the siege engine: a trebuchet arm and frame lashed on top
			ci.draw_line(p + Vector2(-8, -84), p + Vector2(10, -118), Painter.WOOD_D, 3.0)
			ci.draw_line(p + Vector2(18, -84), p + Vector2(10, -118), Painter.WOOD_D, 3.0)
			ci.draw_line(p + Vector2(-26, -132), p + Vector2(34, -104), Painter.WOOD, 3.0)
			ci.draw_circle(p + Vector2(-26, -132), 6.0, flesh.darkened(0.2))
			ci.draw_circle(p + Vector2(6, -60), 5.0, Color(dread, 0.9))
		"hollow_king":
			# the Hollow King's throne hall: a vaulted black hall, its doors open on a throne with an empty crown
			var blk = Color("201a26") if s != "planned" else stone
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-56, 0), p + Vector2(-56, -70), p + Vector2(-40, -96), p + Vector2(0, -124), p + Vector2(40, -96), p + Vector2(56, -70), p + Vector2(56, 0)]), blk)
			for sx in [-56.0, 44.0]:
				ci.draw_rect(Rect2(p.x + sx, p.y - 110, 12, 110), blk.darkened(0.3))
				ci.draw_colored_polygon(PackedVector2Array([p + Vector2(sx - 2, -110), p + Vector2(sx + 6, -140), p + Vector2(sx + 14, -110)]), blk.darkened(0.3))
			var door = PackedVector2Array([p + Vector2(-22, 0), p + Vector2(-22, -48), p + Vector2(0, -70), p + Vector2(22, -48), p + Vector2(22, 0)])
			ci.draw_colored_polygon(door, Color(dread, 0.35) if s != "cleared" else Color(1.0, 0.7, 0.35, 0.55))
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-9, 0), p + Vector2(-9, -30), p + Vector2(0, -40), p + Vector2(9, -30), p + Vector2(9, 0)]), Color("120e14"))
			var cr = p + Vector2(0, -48)
			if s != "cleared":
				ci.draw_colored_polygon(PackedVector2Array([cr + Vector2(-9, 4), cr + Vector2(-9, -3), cr + Vector2(-5, 1), cr + Vector2(0, -7), cr + Vector2(5, 1), cr + Vector2(9, -3), cr + Vector2(9, 4)]), Color("e8c060"))
				ci.draw_circle(cr + Vector2(0, -1), 1.8, Color(dread, 1.0))
			_windows(ci, [Rect2(p.x - 44, p.y - 64, 6, 12), Rect2(p.x + 36, p.y - 64, 6, 12)], lit if s == "cleared" else Color(0.55, 1.0, 0.5))
		"gravewing_sovereign":
			# a storm eye: a spiral of cloud with a colossal wing silhouette in it
			var cl = Color("3a3048") if s != "planned" else stone
			for k in 5:
				var rr = 66.0 - k * 11.0
				ci.draw_arc(p + Vector2(0, -96), rr, k * 0.9, k * 0.9 + PI * 1.4, 22, Color(cl.lightened(k * 0.06), 0.9), 7.0 - k)
			ci.draw_circle(p + Vector2(0, -96), 12.0, Color(dread, 0.25) if s != "cleared" else Color(1.0, 0.85, 0.6, 0.5))
			if s != "cleared":
				ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-4, -96), p + Vector2(-60, -132), p + Vector2(-46, -116), p + Vector2(-70, -110), p + Vector2(-48, -100), p + Vector2(-64, -88), p + Vector2(-10, -90)]), Color("14101a"))
				ci.draw_colored_polygon(PackedVector2Array([p + Vector2(4, -96), p + Vector2(58, -136), p + Vector2(46, -118), p + Vector2(68, -112), p + Vector2(48, -102), p + Vector2(62, -90), p + Vector2(10, -90)]), Color("14101a"))
				ci.draw_circle(p + Vector2(0, -98), 3.0, Color(dread, 1.0))
			ci.draw_polyline(PackedVector2Array([p + Vector2(0, -30), p + Vector2(0, 0)]), Painter.WOOD_D, 2.0)
			Painter.rect(ci, Rect2(p.x - 10, p.y - 30, 20, 30), stone.darkened(0.2), 1.5)
		"rift_lich":
			# the gate of the undead realm: bone pillars and a black iron portcullis under the rift
			var bone = Color("cfc6b0") if s != "planned" else stone
			for sx2 in [-36.0, 26.0]:
				Painter.rect(ci, Rect2(p.x + sx2, p.y - 92, 12, 92), bone.darkened(0.15), 1.5)
				ci.draw_circle(p + Vector2(sx2 + 6, -98), 8.0, bone)
			var arch = PackedVector2Array()
			for j in 11:
				var a2 = PI + PI * float(j) / 10.0
				arch.append(p + Vector2(-4, -92) + Vector2(cos(a2) * 34.0, sin(a2) * 22.0))
			ci.draw_polyline(arch, bone, 5.0)
			for k in 5:
				ci.draw_line(p + Vector2(-20 + k * 8, -90), p + Vector2(-20 + k * 8, -40 if s != "cleared" else -80), Color("100c14"), 3.0)
			ci.draw_circle(p + Vector2(-4, -60), 14.0, Color(dread, 0.3) if s != "cleared" else Color(1.0, 0.75, 0.4, 0.4))
			if s == "cleared":
				# the army's banners planted on the gate
				_banner(ci, p + Vector2(-32, -92), Color("2a4a8a"), Painter.BRASS)
				_banner(ci, p + Vector2(30, -92), Color("8a1a1e"), Color("ffcf5a"))
		_:
			# later acts: a dark spire crowned with the boss's sigil
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-30, 0), p + Vector2(-12, -90), p + Vector2(0, -120), p + Vector2(12, -90), p + Vector2(30, 0)]), stone.darkened(0.4))
			ci.draw_circle(p + Vector2(0, -70), 9.0, Color(dread, 0.6))
	if s != "cleared" and s != "planned":
		ci.draw_circle(p + Vector2(0, -40), 64.0, Color(dread, 0.07))


# ------------------------------------------------------------------ M005 Act II landmarks
func _star(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var pts = PackedVector2Array()
	for k in 10:
		var a = -PI / 2.0 + k * PI / 5.0
		pts.append(c + Vector2.from_angle(a) * (r if k % 2 == 0 else r * 0.45))
	ci.draw_colored_polygon(pts, col)


func _act2_landmark(ci: CanvasItem, p: Vector2, env: String, s: String, lit: Color, stone: Color) -> void:
	var corrupt = s == "locked"
	match env:
		"dead_forest":
			# a ring of dead oaks around a hunter's lodge
			var oak = Color("3a3226") if not corrupt else Color("33362a")
			for k in 5:
				var ox = p.x - 36 + k * 18
				var h = 46.0 + float((k * 17) % 20)
				ci.draw_line(Vector2(ox, p.y), Vector2(ox + 2, p.y - h), oak, 4.0)
				ci.draw_line(Vector2(ox + 2, p.y - h * 0.7), Vector2(ox - 10, p.y - h * 0.95), oak, 2.0)
				ci.draw_line(Vector2(ox + 2, p.y - h * 0.8), Vector2(ox + 13, p.y - h - 4), oak, 2.0)
			Painter.rect(ci, Rect2(p.x - 14, p.y - 22, 28, 22), Painter.WOOD.darkened(0.25), 1.5)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-18, -22), p + Vector2(0, -36), p + Vector2(18, -22)]), Color("4a3a24"))
			_windows(ci, [Rect2(p.x - 4, p.y - 16, 8, 8)], lit)
			if corrupt:
				ci.draw_circle(p + Vector2(0, -10), 26.0, Color(0.45, 0.7, 0.3, 0.08))
		"plague_marsh":
			# a stilt village over black water
			ci.draw_colored_polygon(Painter.ell_pts(p + Vector2(0, 2), 44, 8, 0.0, 16), Color(0.05, 0.06, 0.04, 0.95))
			for hx in [-22.0, 14.0]:
				for k in 3:
					ci.draw_line(p + Vector2(hx - 8 + k * 8, 4), p + Vector2(hx - 8 + k * 8, -16), Painter.WOOD_D, 2.0)
				Painter.rect(ci, Rect2(p.x + hx - 12, p.y - 34, 24, 18), Painter.WOOD.darkened(0.3), 1.5)
				ci.draw_colored_polygon(PackedVector2Array([p + Vector2(hx - 15, -34), p + Vector2(hx, -46), p + Vector2(hx + 15, -34)]), Color("4a4228"))
				_windows(ci, [Rect2(p.x + hx - 3, p.y - 29, 6, 6)], lit)
			ci.draw_line(p + Vector2(-10, -20), p + Vector2(2, -20), Painter.WOOD_D, 2.0)
			ci.draw_line(p + Vector2(-30, -2), p + Vector2(-4, -2), Color(0.5, 0.65, 0.4, 0.3), 1.5)
		"ruined_road":
			# a gibbeted toll gate with a broken arch
			Painter.rect(ci, Rect2(p.x - 30, p.y - 50, 12, 50), stone, 2.0)
			Painter.rect(ci, Rect2(p.x + 16, p.y - 36, 12, 36), stone, 2.0)
			ci.draw_arc(p + Vector2(-1, -44), 22.0, PI, PI * 1.55, 8, stone, 7.0)
			ci.draw_line(p + Vector2(-14, -2), p + Vector2(12, -14), Color("6a4a2a"), 3.0)
			ci.draw_line(p + Vector2(34, 0), p + Vector2(34, -48), Color(0.12, 0.1, 0.1), 2.5)
			ci.draw_line(p + Vector2(34, -48), p + Vector2(48, -48), Color(0.12, 0.1, 0.1), 2.5)
			ci.draw_line(p + Vector2(46, -48), p + Vector2(46, -40), Color(0.12, 0.1, 0.1), 1.0)
			ci.draw_rect(Rect2(p.x + 42, p.y - 40, 8, 12), Color(0.12, 0.1, 0.1))
			ci.draw_circle(p + Vector2(-24, -40), 3.0, Color(lit, 0.85))
		"corrupted_mine":
			# underground: a fungus-choked gallery with spore stalks
			Painter.bar(ci, p + Vector2(-22, 0), -PI / 2.0, 30, 4.0, Painter.WOOD.darkened(0.2), 1.5)
			Painter.bar(ci, p + Vector2(18, 0), -PI / 2.0, 30, 4.0, Painter.WOOD.darkened(0.2), 1.5)
			Painter.bar(ci, p + Vector2(-26, -30), 0.0, 48, 4.0, Painter.WOOD.darkened(0.2), 1.5)
			for k in 3:
				var sx = p.x - 12 + k * 10
				ci.draw_line(Vector2(sx, p.y), Vector2(sx + 1, p.y - 14 - k * 4), Color(0.45, 0.5, 0.3), 2.0)
				ci.draw_circle(Vector2(sx + 1, p.y - 16 - k * 4), 4.0, Color(0.55, 0.85, 0.35) if s != "cleared" else Color(0.6, 0.6, 0.45))
			for k in 4:
				ci.draw_circle(p + Vector2(-20 + k * 13, -26), 3.0, Color(0.6, 1.0, 0.45, 0.6) if s != "cleared" else Color(1.0, 0.75, 0.35, 0.8))
			ci.draw_circle(p + Vector2(-16, -22), 2.5, Color(lit, 0.9))


# ------------------------------------------------------------------ M006 Act III landmarks
func _isle(ci: CanvasItem, i: int) -> void:
	var p: Vector2 = pts[i]
	var gy = surf_y(p.x)
	var rock = pal("rock").lightened(0.12)
	# the floating island (lit top, shaded tapering underside) the landmark stands on
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-50, 2), p + Vector2(-38, 22), p + Vector2(-16, 40), p + Vector2(4, 58), p + Vector2(18, 36), p + Vector2(40, 20), p + Vector2(50, 2)]), rock.darkened(0.2))
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-50, 2), p + Vector2(-40, 12), p + Vector2(40, 12), p + Vector2(50, 2)]), rock)
	ci.draw_polyline(PackedVector2Array([p + Vector2(-52, 3), p + Vector2(52, 3)]), pal("grass"), 4.0)
	# chains down to the ground
	for cx in [-30.0, 28.0]:
		var top = p + Vector2(cx, 14)
		var bot = Vector2(p.x + cx * 1.6, gy)
		var ch = PackedVector2Array()
		for k in 9:
			var f = float(k) / 8.0
			ch.append(top.lerp(bot, f) + Vector2(sin(f * PI) * 8.0, 0))
		ci.draw_polyline(ch, Color(0.15, 0.15, 0.17, 0.75), 1.5)
	# the airship route from the road: a dashed arc up to the island and back down
	var a = Vector2(p.x - 56, surf_y(p.x - 56))
	var b = Vector2(p.x + 56, surf_y(p.x + 56))
	for seg in [[a, p + Vector2(-44, -6)], [p + Vector2(44, -6), b]]:
		var s0: Vector2 = seg[0]
		var s1: Vector2 = seg[1]
		for k in 12:
			if k % 3 == 2:
				continue
			var f0 = float(k) / 12.0
			var f1 = float(k + 1) / 12.0
			var lift0 = sin(f0 * PI) * -22.0
			var lift1 = sin(f1 * PI) * -22.0
			ci.draw_line(s0.lerp(s1, f0) + Vector2(0, lift0), s0.lerp(s1, f1) + Vector2(0, lift1), Color(0.12, 0.1, 0.08, 0.6), 4.0)
			ci.draw_line(s0.lerp(s1, f0) + Vector2(0, lift0), s0.lerp(s1, f1) + Vector2(0, lift1), Color("e8cf8a"), 2.0)
	# a mooring mast with a little dwarven gasbag at the foot of the route
	ci.draw_line(a, a + Vector2(0, -26), Painter.WOOD_D, 2.5)
	ci.draw_colored_polygon(Painter.ell_pts(a + Vector2(8, -34), 11, 5, 0.0, 12), Color("b8a888"))


func _act3_landmark(ci: CanvasItem, p: Vector2, env: String, s: String, lit: Color, stone: Color) -> void:
	var corrupt = s == "locked"
	match env:
		"open_plains":
			# a windmill farmstead
			Painter.rect(ci, Rect2(p.x - 30, p.y - 18, 26, 18), Painter.WOOD.darkened(0.2), 1.5)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-33, -18), p + Vector2(-17, -30), p + Vector2(-1, -18)]), Color("7a4a2a") if not corrupt else Color("4a3a30"))
			_windows(ci, [Rect2(p.x - 20, p.y - 13, 6, 6)], lit)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(4, 0), p + Vector2(8, -52), p + Vector2(18, -52), p + Vector2(22, 0)]), stone.lightened(0.15))
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(5, -52), p + Vector2(13, -62), p + Vector2(21, -52)]), Color("6a3a22"))
			var hub = p + Vector2(13, -54)
			var ang = 0.4 if not corrupt else 0.9
			for k in 4:
				var d = Vector2.from_angle(ang + k * PI * 0.5)
				ci.draw_line(hub, hub + d * 26.0, Painter.WOOD_D, 2.0)
				ci.draw_colored_polygon(PackedVector2Array([hub + d * 8.0, hub + d * 26.0, hub + d * 26.0 + d.orthogonal() * 6.0, hub + d * 8.0 + d.orthogonal() * 5.0]), Color("d8ccb0") if not corrupt else Color("6a6458"))
			ci.draw_circle(hub, 2.5, Painter.IRON_D)
		"broken_ridge":
			# a rope-bridge outpost between two crags
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-40, 0), p + Vector2(-34, -54), p + Vector2(-18, -46), p + Vector2(-14, 0)]), stone.darkened(0.1))
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(14, 0), p + Vector2(18, -40), p + Vector2(36, -50), p + Vector2(42, 0)]), stone.darkened(0.25))
			var br = PackedVector2Array()
			for k in 9:
				var f = float(k) / 8.0
				br.append(p + Vector2(-20 + f * 40.0, -46 + sin(f * PI) * 10.0))
			ci.draw_polyline(br, Color("5a4228"), 2.0)
			for k in range(0, 9, 2):
				ci.draw_line(br[k] + Vector2(0, -2), br[k] + Vector2(0, 3), Color("8a6a40"), 2.0)
			Painter.rect(ci, Rect2(p.x - 36, p.y - 70, 18, 16), Painter.WOOD.darkened(0.15), 1.5)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-39, -70), p + Vector2(-27, -80), p + Vector2(-15, -70)]), Color("4a3a24"))
			_windows(ci, [Rect2(p.x - 30, p.y - 65, 5, 5)], lit)
		"airborne_ruins":
			# a ruined tower on its floating island
			Painter.rect(ci, Rect2(p.x - 12, p.y - 64, 24, 64), stone.lightened(0.05), 2.0)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-15, -64), p + Vector2(-8, -74), p + Vector2(-2, -66), p + Vector2(5, -78), p + Vector2(15, -64)]), stone.darkened(0.2))
			_windows(ci, [Rect2(p.x - 4, p.y - 50, 8, 10), Rect2(p.x - 4, p.y - 26, 8, 10)], lit)
			ci.draw_line(p + Vector2(20, 2), p + Vector2(22, 40), Color(0.85, 0.95, 1.0, 0.55), 3.0)
		"shattered_fort":
			# a broken bastion
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-38, 0), p + Vector2(-38, -40), p + Vector2(-28, -46), p + Vector2(-20, -38), p + Vector2(-8, -50), p + Vector2(4, -34), p + Vector2(14, -44), p + Vector2(22, -30), p + Vector2(34, -36), p + Vector2(38, 0)]), stone)
			for k in 4:
				ci.draw_rect(Rect2(p.x - 30 + k * 16, p.y - 22, 6, 9), Color(0.1, 0.1, 0.12))
			_windows(ci, [Rect2(p.x - 14, p.y - 22, 6, 9)], lit)
			for k in 4:
				ci.draw_circle(p + Vector2(-44 + k * 9, -2 - (k % 2) * 3), 4.0, stone.darkened(0.2))
			ci.draw_line(p + Vector2(26, -36), p + Vector2(46, -48), Painter.IRON_D, 4.0)


# ------------------------------------------------------------------ M007 Act IV landmarks
func _act4_landmark(ci: CanvasItem, p: Vector2, env: String, s: String, lit: Color, stone: Color) -> void:
	var corrupt = s == "locked" or s == "planned"
	var brick = Color("5a3a2a") if not corrupt else Color("3e3430")
	match env:
		"industrial_city":
			# a smokestack block with a viaduct
			Painter.rect(ci, Rect2(p.x - 30, p.y - 34, 40, 34), brick, 2.0)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-32, -34), p + Vector2(12, -34), p + Vector2(4, -42), p + Vector2(-24, -42)]), brick.darkened(0.25))
			_windows(ci, [Rect2(p.x - 24, p.y - 26, 6, 8), Rect2(p.x - 12, p.y - 26, 6, 8), Rect2(p.x, p.y - 26, 6, 8)], lit)
			for k in 2:
				Painter.rect(ci, Rect2(p.x - 26 + k * 18, p.y - 78 + k * 10, 8, 40 - k * 10), brick.darkened(0.15), 1.5)
				ci.draw_rect(Rect2(p.x - 27 + k * 18, p.y - 80 + k * 10, 10, 3), Painter.IRON_D)
			# the viaduct running off to the right on two arches
			ci.draw_rect(Rect2(p.x + 10, p.y - 26, 40, 6), stone.darkened(0.1))
			for ax in [16.0, 36.0]:
				ci.draw_rect(Rect2(p.x + ax, p.y - 20, 6, 20), stone.darkened(0.1))
		"destroyed_forge":
			# a great furnace with a crucible
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-24, 0), p + Vector2(-16, -62), p + Vector2(10, -62), p + Vector2(18, 0)]), brick)
			for k in 3:
				ci.draw_line(p + Vector2(-22 + k * 2, -16 - k * 16), p + Vector2(16 - k * 2, -16 - k * 16), Painter.IRON_D, 2.0)
			Painter.rect(ci, Rect2(p.x - 8, p.y - 74, 12, 12), brick.darkened(0.2), 1.5)
			ci.draw_colored_polygon(Painter.ell_pts(p + Vector2(-3, -12), 7, 8, 0.0, 10), Color(lit.lerp(Color(1, 0.35, 0.1), 0.6), 0.9) if not corrupt else Color("120a08"))
			# the crucible on its trunnion
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(22, -30), p + Vector2(42, -30), p + Vector2(38, -8), p + Vector2(26, -8)]), Painter.IRON)
			ci.draw_line(p + Vector2(20, -24), p + Vector2(44, -24), Painter.IRON_D, 2.0)
			ci.draw_line(p + Vector2(24, -8), p + Vector2(24, 0), Painter.IRON_D, 2.0)
			ci.draw_line(p + Vector2(40, -8), p + Vector2(40, 0), Painter.IRON_D, 2.0)
		"infested_factory":
			# a sawtooth-roofed hall
			Painter.rect(ci, Rect2(p.x - 38, p.y - 30, 70, 30), brick.lightened(0.04), 2.0)
			var teeth = PackedVector2Array([p + Vector2(-38, -30)])
			for k in 4:
				teeth.append(p + Vector2(-38 + k * 17.5 + 13, -46))
				teeth.append(p + Vector2(-38 + (k + 1) * 17.5, -30))
			ci.draw_colored_polygon(teeth, Color("3a3430") if not corrupt else Color("33302a"))
			for k in 4:
				ci.draw_line(p + Vector2(-38 + k * 17.5 + 13, -46), p + Vector2(-38 + k * 17.5 + 13, -31), Color(lit, 0.6), 1.5)
			_windows(ci, [Rect2(p.x - 30, p.y - 22, 8, 8), Rect2(p.x - 14, p.y - 22, 8, 8), Rect2(p.x + 2, p.y - 22, 8, 8)], lit)
			Painter.rect(ci, Rect2(p.x + 18, p.y - 66, 8, 36), brick.darkened(0.2), 1.5)
			if corrupt:
				for k in 4:
					ci.draw_circle(p + Vector2(-30 + k * 16, -30), 3.0, Color(0.5, 0.75, 0.3, 0.8))
		"mech_graveyard":
			# the rusted head of a fallen colossus, half buried
			var rust = Color("7a4a2e") if not corrupt else Color("4a3a30")
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-36, 0), p + Vector2(-32, -30), p + Vector2(-16, -48), p + Vector2(14, -46), p + Vector2(30, -26), p + Vector2(36, 0)]), rust)
			ci.draw_rect(Rect2(p.x - 22, p.y - 30, 40, 9), rust.darkened(0.4))
			ci.draw_circle(p + Vector2(-10, -26), 4.0, Color(0.1, 0.08, 0.06))
			ci.draw_circle(p + Vector2(8, -26), 4.0, Color(0.1, 0.08, 0.06))
			ci.draw_circle(p + Vector2(8, -26), 2.0, Color(0.45, 0.95, 0.4, 0.8) if corrupt else Color(lit, 0.8))
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-6, -46), p + Vector2(0, -70), p + Vector2(6, -46)]), rust.lightened(0.06))
			for k in 4:
				ci.draw_line(p + Vector2(-16 + k * 10, -14), p + Vector2(-16 + k * 10, -2), rust.darkened(0.3), 2.0)
			Painter.wheel(ci, p + Vector2(32, -10), 9.0, 0.3, Painter.IRON_D, rust, 8)


# ------------------------------------------------------------------ M008 Act V landmarks
func _act5_landmark(ci: CanvasItem, p: Vector2, env: String, s: String, lit: Color, stone: Color) -> void:
	var corrupt = s == "locked" or s == "planned"
	var bone = Color("cfc6b2") if not corrupt else Color("6a6458")
	var vio = Color(0.72, 0.4, 1.0)
	match env:
		"necro_waste":
			# a bone-dune ribcage with a dwarven watch-fire in its shelter once cleared
			ci.draw_colored_polygon(Painter.ell_pts(p + Vector2(0, 2), 44, 14, 0.0, 16, PI, TAU), Color("5a5650") if not corrupt else Color("3e3a38"))
			for k in 5:
				var rx = p.x - 26 + k * 13
				var rib = PackedVector2Array()
				for j in 7:
					var f = float(j) / 6.0
					rib.append(Vector2(rx - 10.0 * sin(f * PI) + f * 6.0, p.y - 4 - (44.0 - absf(k - 2.0) * 6.0) * sin(f * PI * 0.5)))
				ci.draw_polyline(rib, bone.darkened(0.3), 4.0)
				ci.draw_polyline(rib, bone, 2.0)
			if not corrupt:
				ci.draw_circle(p + Vector2(0, -8), 6.0, Color(lit, 0.85))
				ci.draw_circle(p + Vector2(0, -8), 14.0, Color(lit, 0.18))
		"rift_sky":
			# a floating shard (the island is drawn by _isle) with a broken obelisk, violet until cleared
			Painter.rect(ci, Rect2(p.x - 7, p.y - 58, 14, 58), stone.darkened(0.25), 1.5)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-9, -58), p + Vector2(0, -76), p + Vector2(9, -58)]), stone.darkened(0.35))
			ci.draw_circle(p + Vector2(0, -40), 4.0, Color(vio, 0.9) if corrupt else Color(lit, 0.9))
			if corrupt:
				ci.draw_circle(p + Vector2(0, -40), 16.0, Color(vio, 0.2))
		"ruined_citadel":
			# a tiered black keep
			var blk = Color("241e2a") if not corrupt else Color("1a1620")
			for t2 in 3:
				var w2 = 44.0 - t2 * 12.0
				var y2 = -t2 * 26.0
				Painter.rect(ci, Rect2(p.x - w2 * 0.5, p.y + y2 - 26, w2, 26), blk.lightened(t2 * 0.05), 1.5)
				for k in int(w2 / 8.0):
					ci.draw_rect(Rect2(p.x - w2 * 0.5 + k * 8, p.y + y2 - 30, 5, 4), blk.lightened(t2 * 0.05))
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-6, -78), p + Vector2(0, -98), p + Vector2(6, -78)]), blk)
			_windows(ci, [Rect2(p.x - 14, p.y - 18, 5, 8), Rect2(p.x + 9, p.y - 18, 5, 8), Rect2(p.x - 3, p.y - 46, 6, 9)], lit if not corrupt else Color(0.5, 1.0, 0.55))
		"realm_gate":
			# sigil stones round a ritual ring
			ci.draw_arc(p + Vector2(0, -2), 30.0, PI, TAU, 18, Color(vio, 0.6) if corrupt else Color(lit, 0.45), 2.0)
			for k in 3:
				var sx3 = p.x - 26 + k * 26
				var hh = 30.0 + (10.0 if k == 1 else 0.0)
				ci.draw_colored_polygon(PackedVector2Array([Vector2(sx3 - 7, p.y), Vector2(sx3 - 5, p.y - hh), Vector2(sx3 + 1, p.y - hh - 6), Vector2(sx3 + 7, p.y - hh + 2), Vector2(sx3 + 7, p.y)]), stone.darkened(0.3))
				ci.draw_circle(Vector2(sx3, p.y - hh * 0.6), 3.0, Color(vio, 0.9) if corrupt else Color(lit, 0.9))


## M008: the Black Rift - a vast vertical tear dominating the right end of the Act V sky (far layer, baked).
## Once stage 150 is cleared it is a healed scar under a clean dawn.
func _black_rift(ci: CanvasItem) -> void:
	var rx = WW - 260.0
	if sealed():
		ci.draw_circle(Vector2(rx, 120), 90, Color(1.0, 0.8, 0.55, 0.16))
		ci.draw_polyline(PackedVector2Array([Vector2(rx - 6, 20), Vector2(rx + 4, 120), Vector2(rx - 3, 220), Vector2(rx + 2, 300)]), Color(0.95, 0.9, 1.0, 0.35), 3.0)
		return
	for k in 6:
		var ww = 210.0 - k * 30.0
		ci.draw_colored_polygon(Painter.ell_pts(Vector2(rx, 200), ww, 260.0 - k * 10.0, 0.0, 24), Color(0.55, 0.25, 0.85, 0.06 + k * 0.03))
	var el = PackedVector2Array()
	var er = PackedVector2Array()
	for j in 18:
		var f = float(j) / 17.0
		var y = lerpf(-10.0, 420.0, f)
		var w = 64.0 * sin(f * PI) * (0.8 + 0.2 * sin(f * 11.0))
		el.append(Vector2(rx - w + sin(f * 19.0) * 6.0, y))
		er.append(Vector2(rx + w * 0.85 + sin(f * 15.0) * 6.0, y))
	var tear = PackedVector2Array(el)
	var rev = er.duplicate()
	rev.reverse()
	tear.append_array(rev)
	ci.draw_colored_polygon(tear, Color(0.95, 0.88, 1.0))
	var inner = PackedVector2Array()
	for q in tear:
		inner.append(Vector2(rx + (q.x - rx) * 0.5, q.y))
	ci.draw_colored_polygon(inner, Color(0.22, 0.06, 0.3))
	ci.draw_polyline(el, Color(1, 1, 1, 0.95), 2.5)
	ci.draw_polyline(er, Color(1, 1, 1, 0.95), 2.5)
	# shards of land being pulled toward it
	_rng.seed = 151
	for i in 12:
		var sp = Vector2(rx - 120.0 - _rng.randf() * 700.0, 60.0 + _rng.randf() * 220.0)
		var sw = _rng.randf_range(6, 16)
		ci.draw_colored_polygon(PackedVector2Array([sp + Vector2(-sw, 0), sp + Vector2(0, -sw * 0.4), sp + Vector2(sw, 0), sp + Vector2(0, sw * 0.9)]), Color(0.12, 0.09, 0.16))
		ci.draw_line(sp + Vector2(sw, 0), sp + Vector2(sw + 22.0, 2.0), Color(0.7, 0.5, 0.95, 0.25), 1.5)


## M007: where a landmark's chimneys are, for the live smoke (green on uncleared ground, clean grey with
## forge light once cleared).
func _chimney_tops(i: int) -> Array:
	var st: Dictionary = stages[i]
	var p: Vector2 = pts[i]
	if st.get("boss") != null:
		match String(st.boss):
			"ashen_forge_tyrant":
				return [p + Vector2(0, -160)]
			"fallen_titan":
				return [p + Vector2(-14, -112), p + Vector2(14, -112)]
		return []
	match String(st.get("env", "")):
		"industrial_city":
			return [p + Vector2(-22, -80), p + Vector2(-4, -70)]
		"destroyed_forge":
			return [p + Vector2(-2, -76)]
		"infested_factory":
			return [p + Vector2(22, -68)]
	return []


# ================================================================== live drawing
func _process(delta: float) -> void:
	_t += delta
	if not _drag:
		if _target >= 0.0:
			scroll = lerpf(scroll, _target, minf(1.0, delta * 6.0))
			if absf(scroll - _target) < 0.5:
				scroll = _target
				_target = -1.0
		elif absf(_vel) > 1.0:
			scroll += _vel * delta
			_vel *= pow(0.04, delta)
	_clamp_scroll()
	_step_patrol(delta)
	queue_redraw()


func _clamp_scroll() -> void:
	scroll = clampf(scroll, 0.0, max_scroll())


func world_to_view(p: Vector2) -> Vector2:
	return (p - Vector2(scroll, 0)) * view_scale()


func _draw() -> void:
	var k = view_scale()
	if stages.is_empty():
		return
	if _baked:
		var far: Texture2D = _tex.far
		var mid: Texture2D = _tex.mid
		var near: Texture2D = _tex.near
		draw_texture_rect(far, Rect2(Vector2(-scroll * 0.35 * k, 0), Vector2(WW, DH) * k), false)
		draw_texture_rect(mid, Rect2(Vector2(-scroll * 0.65 * k, 0), Vector2(WW, DH) * k), false)
		draw_texture_rect(near, Rect2(Vector2(-scroll * k, 0), Vector2(WW, DH) * k), false)
	else:
		# live fallback (headless tests / before the bake lands)
		draw_set_transform(Vector2(-scroll * 0.35 * k, 0), 0.0, Vector2(k, k))
		paint(self, "far")
		draw_set_transform(Vector2(-scroll * 0.65 * k, 0), 0.0, Vector2(k, k))
		paint(self, "mid")
		draw_set_transform(Vector2(-scroll * k, 0), 0.0, Vector2(k, k))
		paint(self, "near")
	draw_set_transform(Vector2(-scroll * k, 0), 0.0, Vector2(k, k))
	_draw_live()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# edge vignette
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(26, 0), Vector2(26, size.y), Vector2(0, size.y)]),
		PackedColorArray([Color(0, 0, 0, 0.45), Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0.45)]))


func _draw_live() -> void:
	var vx0 = scroll - 60.0
	var vx1 = scroll + size.x / view_scale() + 60.0
	# drifting clouds
	for i in 7:
		var cx = fposmod(i * 590.0 + _t * (9.0 + i * 1.7), WW + 300.0) - 150.0
		var cy = 60.0 + (i % 3) * 34.0
		if cx > vx0 - 100 and cx < vx1 + 100:
			var cc = Color(1, 1, 1, 0.07) if act != 5 else Color(0.7, 0.5, 0.9, 0.08)
			if act == 3:
				cc = Color(1, 1, 1, 0.22)
			for b in 5:
				draw_circle(Vector2(cx + b * 16.0, cy + absf(b - 2.0) * 3.0), 12.0 + (2.0 - absf(b - 2.0)) * 5.0, cc)
	# corruption beyond the front line
	if frontier < 30:
		var fx: float = pts[frontier].x - 50.0
		draw_polygon(PackedVector2Array([Vector2(fx, 0), Vector2(WW, 0), Vector2(WW, DH), Vector2(fx, DH)]),
			PackedColorArray([Color(pal("fog"), 0.0), Color(pal("fog"), 0.16), Color(pal("fog"), 0.24), Color(pal("fog"), 0.0)]))
		# low rolling mist hugging the ground of the corrupted lands
		for m in 26:
			var mx = fx + 20.0 + m * 62.0 + sin(_t * 0.5 + m * 1.7) * 22.0
			if mx < vx0 - 60.0 or mx > vx1 + 60.0:
				continue
			var my = surf_y(mx) - 10.0 - (m % 3) * 10.0 + sin(_t * 0.8 + m) * 4.0
			draw_circle(Vector2(mx, my), 26.0 + (m % 4) * 6.0, Color(pal("fog"), 0.09))
		# carrion birds circling the corrupted landmarks
		for b in 5:
			var ci_idx = mini(29, frontier + 1 + b * 3)
			var c: Vector2 = pts[ci_idx] + Vector2(0, -110)
			var a = _t * (0.8 + b * 0.13) + b
			var bp = c + Vector2(cos(a) * 34.0, sin(a) * 12.0)
			if bp.x > vx0 and bp.x < vx1:
				draw_polyline(PackedVector2Array([bp + Vector2(-6, -3), bp, bp + Vector2(6, -3)]), Color(0.08, 0.06, 0.08, 0.8), 1.6)
	# M006 little dwarven gasbags plying the airship routes to cleared islands
	if act == 3:
		for i in 30:
			if not aloft[i] or _state(i) != "cleared":
				continue
			var ip: Vector2 = pts[i]
			if ip.x < vx0 or ip.x > vx1:
				continue
			var f = fposmod(_t * 0.12 + i * 0.31, 1.0)
			var a0 = Vector2(ip.x - 56, surf_y(ip.x - 56))
			var sp = a0.lerp(ip + Vector2(-44, -6), f) + Vector2(0, sin(f * PI) * -22.0 - 8.0)
			draw_colored_polygon(Painter.ell_pts(sp, 9, 4, 0.0, 10), Color("c8b898"))
			draw_rect(Rect2(sp.x - 3, sp.y + 4, 6, 3), Color("6a4a2a"))
	# M006 lightning flicker over storm stages (cheap: a polyline for a few frames now and then)
	if act == 3:
		for i in 30:
			var hz = WaveDirector.hazard_list(stages[i])
			if not hz.any(func(h): return String(h.get("kind", "")) == "lightning_storm"):
				continue
			var lp: Vector2 = pts[i]
			if lp.x < vx0 or lp.x > vx1:
				continue
			var ph2 = fposmod(_t * 0.7 + i * 0.37, 2.6)
			if ph2 < 0.12:
				var top2 = lp + Vector2(-10 + (i % 3) * 10, -150)
				draw_polyline(PackedVector2Array([top2, top2 + Vector2(10, 30), top2 + Vector2(-2, 52), top2 + Vector2(12, 80), top2 + Vector2(4, 110)]), Color(0.9, 0.93, 1.0, 0.9), 2.0)
				draw_circle(top2 + Vector2(0, 20), 60.0, Color(0.8, 0.85, 1.0, 0.08))
			for k in 3:
				draw_circle(lp + Vector2(-30 + k * 30, -140 - (k % 2) * 8), 22.0, Color(0.16, 0.15, 0.22, 0.55))
	# M008 Act V: warm dwarven light pushes into the dark as stages are cleared (a forge-glow band over cleared
	# ground up to the front line); the rift's violet pulse beyond it until the rift is sealed
	if act == 5:
		var lx = pts[mini(frontier, 29)].x - 40.0 if frontier < 30 else WW
		if frontier > 0:
			draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(lx, 0), Vector2(lx, DH), Vector2(0, DH)]),
				PackedColorArray([Color(1.0, 0.62, 0.3, 0.1), Color(1.0, 0.62, 0.3, 0.0), Color(1.0, 0.62, 0.3, 0.0), Color(1.0, 0.62, 0.3, 0.14)]))
			for i in mini(frontier, 30):
				var lp5: Vector2 = pts[i]
				if lp5.x > vx0 and lp5.x < vx1:
					draw_circle(lp5 + Vector2(0, -20), 54.0 + 4.0 * sin(_t * 2.0 + i), Color(1.0, 0.7, 0.35, 0.07))
		if not sealed():
			var pulse = 0.5 + 0.5 * sin(_t * 1.4)
			draw_circle(Vector2(WW - 260.0, 200.0), 150.0 + 12.0 * pulse, Color(0.6, 0.3, 0.9, 0.05 + 0.03 * pulse))
	# M007 Act IV chimneys: green corrupted smoke on uncleared landmarks, clean grey smoke with forge light on cleared
	if act == 4:
		for i in 30:
			var lp4: Vector2 = pts[i]
			if lp4.x < vx0 or lp4.x > vx1:
				continue
			var clean = _state(i) == "cleared"
			for top in _chimney_tops(i):
				var tp: Vector2 = top
				if clean:
					draw_circle(tp + Vector2(0, 2), 6.0, Color(1.0, 0.6, 0.25, 0.35 + 0.15 * sin(_t * 5.0 + i)))
				for k in 4:
					var ph4 = fposmod(_t * 0.3 + k / 4.0 + i * 0.13, 1.0)
					var sc4 = Color(0.72, 0.7, 0.68, 0.3 * (1.0 - ph4)) if clean else Color(0.45, 0.85, 0.35, 0.32 * (1.0 - ph4))
					draw_circle(tp + Vector2(ph4 * 14.0 + sin(ph4 * 6.0 + i) * 3.0, -ph4 * 46.0), 3.5 + ph4 * 9.0, sc4)
	# chimney smoke and hearth light on cleared ground
	for i in 30:
		var p: Vector2 = pts[i]
		if p.x < vx0 or p.x > vx1:
			continue
		var s = _state(i)
		if s == "cleared" and act != 4:
			for k in 3:
				var ph = fposmod(_t * 0.35 + k / 3.0 + i * 0.17, 1.0)
				draw_circle(p + Vector2(-8 + ph * 10.0, -60 - ph * 40.0), 4.0 + ph * 9.0, Color(0.75, 0.72, 0.7, 0.28 * (1.0 - ph)))
		if p.x < vx1 and stages[i].id == selected:
			var r = 46.0 + sin(_t * 4.0) * 3.0
			draw_arc(p + Vector2(0, -24), r, 0, TAU, 40, Color(UiKit.BRASS_L, 0.85), 2.5)
			draw_arc(p + Vector2(0, -24), r + 5.0, 0, TAU, 40, Color(UiKit.BRASS_L, 0.25), 3.0)
	# the beacon over the next stage
	if frontier < 30 and stages[frontier].get("implemented", false):
		var bp2: Vector2 = pts[frontier] + Vector2(0, -92 - absf(sin(_t * 3.0)) * 8.0)
		var fl = 0.75 + 0.25 * sin(_t * 9.0)
		draw_circle(pts[frontier] + Vector2(0, -30), 70.0, Color(1.0, 0.6, 0.2, 0.08 * fl))
		draw_colored_polygon(PackedVector2Array([bp2 + Vector2(-11, -10), bp2 + Vector2(11, -10), bp2 + Vector2(0, 6)]), Color(1.0, 0.7, 0.25))
		draw_polyline(PackedVector2Array([bp2 + Vector2(-11, -10), bp2 + Vector2(11, -10), bp2 + Vector2(0, 6), bp2 + Vector2(-11, -10)]), Color("120e0b"), 2.0)
	# patrol sprites are positioned in _step_patrol


# ================================================================== patrol (tiny dwarves on the road)
func _spawn_patrol() -> void:
	for sp in _patrol:
		if is_instance_valid(sp.node):
			sp.node.queue_free()
	_patrol.clear()
	var reach = pts[mini(frontier, 29)].x - 40.0 if frontier > 0 else 0.0
	if reach < 120.0:
		return
	var arts = ["rifleman", "shieldbearer", "militia", "grenadier"]
	for i in 3:
		var n = Widgets.ArtSprite.new(arts[i], Vector2.ZERO, 0.42, false)
		n.anim.state = "move"
		add_child(n)
		_patrol.append({"node": n, "x": 110.0 + i * 26.0, "dir": 1.0, "speed": 16.0 + i * 2.0, "reach": reach})


func _step_patrol(delta: float) -> void:
	var k = view_scale()
	for sp in _patrol:
		var n: Node2D = sp.node
		if not is_instance_valid(n):
			continue
		sp.x += sp.dir * sp.speed * delta
		if sp.x > sp.reach:
			sp.dir = -1.0
		elif sp.x < 100.0:
			sp.dir = 1.0
		var wp = Vector2(sp.x, road_y(sp.x) - 1.0)
		n.position = world_to_view(wp)
		n.scale = Vector2(0.42 * k * sp.dir, 0.42 * k)


# ================================================================== input
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_drag = true
				_drag_moved = 0.0
				_press_pos = event.position
				_vel = 0.0
				_target = -1.0
			else:
				_drag = false
				if _drag_moved < 12.0:
					_tap(event.position)
			accept_event()
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT]:
			_target = clampf((_target if _target >= 0.0 else scroll) + 160.0, 0.0, max_scroll())
			accept_event()
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT]:
			_target = clampf((_target if _target >= 0.0 else scroll) - 160.0, 0.0, max_scroll())
			accept_event()
	elif event is InputEventMouseMotion and _drag:
		var dx = event.relative.x / view_scale()
		scroll -= dx
		_drag_moved += absf(event.relative.x) + absf(event.relative.y)
		_vel = -dx / maxf(0.001, get_process_delta_time())
		_clamp_scroll()
		accept_event()


func _tap(at: Vector2) -> void:
	var best = -1
	var bd = 1e9
	for i in 30:
		var vp = world_to_view(pts[i] + Vector2(0, -30))
		var d = vp.distance_to(at)
		if d < bd:
			bd = d
			best = i
	if best >= 0 and bd < 62.0 * view_scale():
		select(stages[best].id)


func select(stage_id: String, fly: bool = true) -> void:
	selected = stage_id
	var i = _index_of(stage_id)
	if i >= 0 and fly:
		focus(i)
	Audio.play("ui_click", -1, -6)
	stage_selected.emit(stage_id)


## Glide so landmark i sits in the middle of the area not covered by the drawer.
func focus(i: int) -> void:
	var vis_w = (size.x - drawer_w) / view_scale()
	_target = clampf(pts[i].x - vis_w * 0.5, 0.0, max_scroll())


func landmark_view_pos(stage_id: String) -> Vector2:
	var i = _index_of(stage_id)
	return world_to_view(pts[i]) if i >= 0 else Vector2.ZERO
