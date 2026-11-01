class_name FxLayer
extends Node2D
## Fixed-capacity particle pool + telegraph markers, all drawn by one canvas item.
## Capacity is halved in performance mode; when full, the oldest particles are recycled, so
## effects can never accumulate without bound.

var cap := 520
var px := PackedVector2Array()
var pv := PackedVector2Array()
var plife := PackedFloat32Array()
var pmax := PackedFloat32Array()
var psize := PackedFloat32Array()
var pgrow := PackedFloat32Array()
var pcol: Array[Color] = []
var pkind := PackedByteArray()      # 0 dot, 1 smoke, 2 spark line, 3 ring, 4 flash
var pgrav := PackedFloat32Array()
var cursor := 0
var live := 0
var telegraphs: Array = []          # {pos, r, t, dur, col}
var bolts: Array = []               # electric arcs / piercing flashes {a, b, t, col, w}
const BOLT_CAP := 24
var battle
var low := false
var rng := RandomNumberGenerator.new()
var wind_t := 0.0


static var DOT: ImageTexture = _make_dot(false)
static var RING: ImageTexture = _make_dot(true)


static func _make_dot(ring: bool) -> ImageTexture:
	var n = 32
	var img = Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var d = Vector2(x + 0.5 - n * 0.5, y + 0.5 - n * 0.5).length() / (n * 0.5)
			var a: float
			if ring:
				a = clampf(1.0 - absf(d - 0.88) * 9.0, 0.0, 1.0)
			else:
				a = clampf((1.0 - d) * 6.0, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


func setup(b, low_quality: bool) -> void:
	battle = b
	low = low_quality
	cap = 220 if low else 520
	px.resize(cap); pv.resize(cap); plife.resize(cap); pmax.resize(cap); psize.resize(cap)
	pgrow.resize(cap); pkind.resize(cap); pgrav.resize(cap)
	pcol.resize(cap)
	for i in cap:
		plife[i] = 0.0
	rng.seed = 77
	z_index = 320


func _emit(p: Vector2, v: Vector2, life: float, size: float, grow: float, col: Color, kind: int, grav: float = 0.0) -> void:
	var i = cursor
	cursor = (cursor + 1) % cap
	if plife[i] <= 0.0:
		live += 1
	px[i] = p; pv[i] = v; plife[i] = life; pmax[i] = life; psize[i] = size; pgrow[i] = grow
	pcol[i] = col; pkind[i] = kind; pgrav[i] = grav


func _n(full: int) -> int:
	return maxi(1, full / 2) if low else full


func step(dt: float) -> void:
	live = 0
	for i in cap:
		if plife[i] <= 0.0:
			continue
		plife[i] -= dt
		if plife[i] <= 0.0:
			continue
		live += 1
		pv[i].y += pgrav[i] * dt
		px[i] += pv[i] * dt
		psize[i] += pgrow[i] * dt
	var keep: Array = []
	for tg in telegraphs:
		tg.t += dt
		if tg.t < tg.dur:
			keep.append(tg)
	telegraphs = keep
	wind_t += dt
	var kb: Array = []
	for bo in bolts:
		bo.t -= dt
		if bo.t > 0.0:
			kb.append(bo)
	bolts = kb
	queue_redraw()


# ------------------------------------------------------------------ emitters
func muzzle(p: Vector2, d: Vector2, kind: String) -> void:
	_emit(p + d * 6.0, d * 30.0 + Vector2(0, -20), 0.5 if kind == "shell" else 0.3, 4.0 if kind == "shell" else 2.0, 14.0, Color(0.75, 0.72, 0.68, 0.55), 1)


func hit(p: Vector2, dtype: String) -> void:
	var col = Color(1, 0.85, 0.5)
	match dtype:
		"melee": col = Color(0.95, 0.95, 0.9)
		"acid": col = Color(0.6, 0.95, 0.2)
		"necro": col = Color(0.43, 1.0, 0.55)
		"fire": col = Color(1, 0.6, 0.2)
	for i in _n(3):
		_emit(p, Vector2(rng.randf_range(-80, 80), rng.randf_range(-90, 10)), 0.25, 1.5, 0.0, col, 2, 200.0)


func sparks(p: Vector2, n: int) -> void:
	for i in _n(n):
		_emit(p, Vector2(rng.randf_range(-70, 70), rng.randf_range(-120, -20)), 0.35, 1.5, 0.0, Color(1, 0.9, 0.4), 2, 300.0)


func puff(p: Vector2, col: Color) -> void:
	_emit(p, Vector2(0, -15), 0.5, 3.0, 12.0, col, 1)


func explosion(p: Vector2, size: float, kind: String) -> void:
	_emit(p, Vector2.ZERO, 0.18, 10.0 * size, 120.0 * size, Color(1, 0.95, 0.7, 0.95), 4)
	_emit(p, Vector2.ZERO, 0.35, 6.0 * size, 160.0 * size, Color(1, 0.8, 0.4, 0.5), 3)
	var base = Color(0.25, 0.22, 0.2, 0.6) if kind != "dirt" else Color(0.42, 0.34, 0.24, 0.7)
	if kind == "necro":
		base = Color(0.3, 0.55, 0.35, 0.55)
		_emit(p, Vector2.ZERO, 0.5, 8.0 * size, 150.0 * size, Color(0.43, 1.0, 0.55, 0.5), 3)
	for i in _n(int(5 * size) + 2):
		_emit(p + Vector2(rng.randf_range(-8, 8), rng.randf_range(-8, 4)) * size, Vector2(rng.randf_range(-40, 40), rng.randf_range(-70, -20)) * size, rng.randf_range(0.6, 1.1), 5.0 * size, 18.0 * size, base, 1)
	for i in _n(int(4 * size) + 2):
		_emit(p, Vector2(rng.randf_range(-160, 160), rng.randf_range(-220, -60)) * size, 0.6, 2.0, 0.0, Color(0.3, 0.25, 0.2) if kind == "dirt" else Color(1, 0.7, 0.3), 0, 600.0)


func flak_burst(p: Vector2) -> void:
	_emit(p, Vector2.ZERO, 0.12, 6.0, 140.0, Color(1, 0.9, 0.6, 0.9), 4)
	for i in _n(3):
		_emit(p + Vector2(rng.randf_range(-6, 6), rng.randf_range(-6, 6)), Vector2(rng.randf_range(-15, 15), rng.randf_range(-15, 5)), 0.9, 6.0, 10.0, Color(0.2, 0.2, 0.2, 0.55), 1)


func splat(p: Vector2) -> void:
	for i in _n(6):
		_emit(p, Vector2(rng.randf_range(-90, 90), rng.randf_range(-120, -10)), 0.5, 2.5, 0.0, Color(0.55, 0.85, 0.2), 0, 500.0)
	_emit(p, Vector2(0, -8), 0.8, 6.0, 16.0, Color(0.5, 0.75, 0.2, 0.45), 1)


func dirt_burst(p: Vector2, size: float) -> void:
	for i in _n(int(6 * size) + 1):
		_emit(p + Vector2(rng.randf_range(-12, 12) * size, -2), Vector2(rng.randf_range(-70, 70), rng.randf_range(-200, -60)) * size, 0.7, 2.5, 0.0, Color(0.38, 0.3, 0.22), 0, 600.0)
	_emit(p, Vector2(0, -10), 0.9, 8.0 * size, 20.0, Color(0.45, 0.38, 0.28, 0.5), 1)


func blood(p: Vector2, undead: bool) -> void:
	var col = Color(0.35, 0.5, 0.2) if undead else Color(0.6, 0.15, 0.1)
	for i in _n(4):
		_emit(p, Vector2(rng.randf_range(-60, 60), rng.randf_range(-100, -20)), 0.45, 2.0, 0.0, col, 0, 500.0)


func bones(p: Vector2) -> void:
	for i in _n(6):
		_emit(p, Vector2(rng.randf_range(-90, 90), rng.randf_range(-160, -40)), 0.8, 2.5, 0.0, Painter.BONE, 2, 600.0)


func wreck(p: Vector2, size: float) -> void:
	explosion(p, size, "fire")
	for i in _n(int(4 * size)):
		_emit(p + Vector2(rng.randf_range(-20, 20), 0), Vector2(rng.randf_range(-20, 20), -30), 2.0, 6.0, 10.0, Color(0.15, 0.13, 0.12, 0.6), 1)


func raise(p: Vector2) -> void:
	_emit(p + Vector2(0, -10), Vector2.ZERO, 0.6, 6.0, 60.0, Color(0.43, 1.0, 0.55, 0.6), 3)
	for i in _n(6):
		_emit(p + Vector2(rng.randf_range(-12, 12), 0), Vector2(0, rng.randf_range(-80, -30)), 0.8, 2.5, -2.0, Color(0.43, 1.0, 0.55), 0)


func cone(p: Vector2, facing: float, rng_len: float, kind: String) -> void:
	if kind == "flame":
		for i in _n(5):
			var sp = rng.randf_range(0.6, 1.0)
			_emit(p, Vector2(facing * rng_len * 2.4 * sp, rng.randf_range(-25, 35)), 0.42, rng.randf_range(4, 7), 26.0, Color(1.0, rng.randf_range(0.45, 0.75), 0.15, 0.75), 4, -60.0)
		if rng.randf() < 0.4:
			_emit(p + Vector2(facing * rng_len * 0.7, -10), Vector2(facing * 30, -40), 0.8, 6.0, 18.0, Color(0.2, 0.18, 0.17, 0.45), 1)
		return
	if kind == "steam":
		for i in _n(4):
			_emit(p, Vector2(facing * rng.randf_range(120, 200), rng.randf_range(-10, 60)), 0.45, 5.0, 40.0, Color(1, 1, 1, 0.35), 1)
	else:
		for i in _n(5):
			_emit(p, Vector2(facing * rng.randf_range(250, 400), rng.randf_range(-60, 60)), rng_len / 400.0, 1.5, 0.0, Color(1, 0.85, 0.4), 2)
		_emit(p + Vector2(facing * 10, 0), Vector2(facing * 20, -15), 0.6, 6.0, 20.0, Color(0.7, 0.68, 0.64, 0.5), 1)


func seal_hit(p: Vector2) -> void:
	_emit(p + Vector2(rng.randf_range(-30, 30), rng.randf_range(-60, 20)), Vector2.ZERO, 0.3, 4.0, 40.0, Color(0.43, 1.0, 0.55, 0.6), 3)


func steam_vent(p: Vector2, radius: float) -> void:
	for i in _n(18):
		var a = rng.randf_range(-PI, 0)
		_emit(p, Vector2(cos(a), sin(a)) * rng.randf_range(80, radius * 1.3), 1.0, 8.0, 40.0, Color(1, 1, 1, 0.45), 1)


# ------------------------------------------------------------------ M002 war-frame effects
func impact(p: Vector2, size: float) -> void:
	_emit(p, Vector2.ZERO, 0.14, 5.0 * size, 90.0 * size, Color(1, 0.95, 0.75, 0.85), 4)
	for i in _n(4):
		_emit(p, Vector2(rng.randf_range(-120, 120), rng.randf_range(-150, -20)) * size, 0.4, 2.0, 0.0, Color(0.95, 0.8, 0.5), 2, 500.0)


func shockwave(p: Vector2, r: float) -> void:
	_emit(Vector2(p.x, Combat.GROUND_Y - 4), Vector2.ZERO, 0.45, 8.0, r * 2.2, Color(1, 0.9, 0.7, 0.6), 3)
	for i in _n(6):
		_emit(Vector2(p.x + rng.randf_range(-r, r) * 0.7, Combat.GROUND_Y - 2), Vector2(rng.randf_range(-40, 40), rng.randf_range(-140, -60)), 0.7, 2.5, 0.0, Color(0.42, 0.34, 0.24), 0, 600.0)


func steam_burst(p: Vector2, size: float) -> void:
	for i in _n(int(3 + size * 2)):
		_emit(p + Vector2(rng.randf_range(-10, 10), rng.randf_range(-10, 10)) * size, Vector2(rng.randf_range(-40, 40), rng.randf_range(-70, -20)) * size, 0.9, 5.0 * size, 22.0 * size, Color(1, 1, 1, 0.4), 1)


func dust(p: Vector2, size: float) -> void:
	for i in _n(2 + int(size)):
		_emit(Vector2(p.x + rng.randf_range(-8, 8) * size, Combat.GROUND_Y - 2), Vector2(rng.randf_range(-35, 35) * size, rng.randf_range(-25, -5)), 0.7, 3.0 * size, 14.0 * size, Color(0.45, 0.38, 0.28, 0.45), 1)


func casing(p: Vector2, facing: float, big: bool) -> void:
	_emit(p + Vector2(-facing * 6, -4), Vector2(-facing * rng.randf_range(40, 90), rng.randf_range(-160, -90)), 0.7, 2.6 if big else 1.6, 0.0, Painter.BRASS.lightened(0.2), 0, 700.0)


func boomstick(p: Vector2, facing: float, size: float) -> void:
	# huge muzzle blast + thick smoke bank + pellet streaks
	_emit(p + Vector2(facing * 10 * size, 0), Vector2.ZERO, 0.12, 12.0 * size, 160.0 * size, Color(1, 0.92, 0.6, 0.95), 4)
	for i in _n(6):
		_emit(p, Vector2(facing * rng.randf_range(380, 560), rng.randf_range(-90, 90)), 0.16, 1.6, 0.0, Color(1, 0.85, 0.45), 2)
	for i in _n(5):
		_emit(p + Vector2(facing * rng.randf_range(10, 40), rng.randf_range(-8, 8)) * size, Vector2(facing * rng.randf_range(20, 70), rng.randf_range(-35, 5)), rng.randf_range(0.9, 1.4), 7.0 * size, 26.0 * size, Color(0.32, 0.3, 0.29, 0.6), 1)


func bolt(a: Vector2, b: Vector2) -> void:
	if bolts.size() >= BOLT_CAP:
		bolts.pop_front()
	bolts.append({"a": a, "b": b, "t": 0.22, "col": Color(0.65, 0.85, 1.0), "w": 2.5, "jag": true})


func line_flash(a: Vector2, b: Vector2) -> void:
	if bolts.size() >= BOLT_CAP:
		bolts.pop_front()
	bolts.append({"a": a, "b": b, "t": 0.18, "col": Color(1.0, 0.85, 0.5), "w": 4.0, "jag": false})


func flames(p: Vector2, r: float, look: String = "fire") -> void:
	for i in _n(4):
		var col = Color(1.0, rng.randf_range(0.4, 0.7), 0.12, 0.7)
		match look:
			"plague":
				col = Color(0.65, rng.randf_range(0.85, 1.0), 0.25, 0.6)
			"roots":
				col = Color(0.35, 0.25, 0.15, 0.75)
		_emit(Vector2(p.x + rng.randf_range(-r, r) * 0.8, Combat.GROUND_Y - 4), Vector2(rng.randf_range(-10, 10), rng.randf_range(-90, -40)), 0.55, rng.randf_range(5, 9), 10.0, col, 4, -40.0)


func telegraph(p: Vector2, r: float, dur: float, col: Color) -> void:
	if telegraphs.size() > 24:
		return
	telegraphs.append({"pos": p, "r": r, "t": 0.0, "dur": dur, "col": col})


func clear_all() -> void:
	for i in cap:
		plife[i] = 0.0
	telegraphs.clear()
	bolts.clear()
	live = 0


func _draw() -> void:
	var vr: Rect2 = battle.view_rect if battle != null else Rect2()
	for tg in telegraphs:
		var k: float = tg.t / tg.dur
		var c: Color = tg.col
		var p: Vector2 = Vector2(tg.pos.x, Combat.GROUND_Y + 4.0) if tg.pos.y > Combat.LOW_AIR_Y else tg.pos
		var pts = Painter.ell_pts(p, tg.r, tg.r * 0.28, 0.0, 20)
		draw_colored_polygon(pts, Color(c.r, c.g, c.b, 0.12 + 0.18 * k))
		var outline = pts.duplicate()
		outline.append(pts[0])
		draw_polyline(outline, Color(c.r, c.g, c.b, 0.5 + 0.5 * sin(k * 20.0)), 2.0)
		var inner = Painter.ell_pts(p, tg.r * k, tg.r * 0.28 * k, 0.0, 16)
		if inner.size() >= 3 and k > 0.05:
			inner.append(inner[0])
			draw_polyline(inner, Color(c.r, c.g, c.b, 0.8), 1.5)
		# cracks
		for i in 5:
			var ang = TAU * i / 5.0 + 0.4
			draw_line(p, p + Vector2(cos(ang) * tg.r * k, sin(ang) * tg.r * 0.28 * k), Color(0.15, 0.1, 0.05, 0.8), 2.0)
	for i in cap:
		if plife[i] <= 0.0:
			continue
		var p = px[i]
		if vr.size != Vector2.ZERO and (p.x < vr.position.x - 60.0 or p.x > vr.end.x + 60.0):
			continue
		var k = plife[i] / pmax[i]
		var c: Color = pcol[i]
		# particles are textured quads from one dot texture: they batch into a handful of draw calls
		var sz: float = psize[i]
		match pkind[i]:
			0:
				draw_texture_rect(DOT, Rect2(p.x - sz, p.y - sz, sz * 2.0, sz * 2.0), false, Color(c.r, c.g, c.b, c.a * minf(1.0, k * 2.0)))
			1, 4:
				draw_texture_rect(DOT, Rect2(p.x - sz, p.y - sz, sz * 2.0, sz * 2.0), false, Color(c.r, c.g, c.b, c.a * k))
			2:
				var q = p - pv[i].normalized() * 2.5
				draw_texture_rect(DOT, Rect2(q.x - sz * 1.4, q.y - sz * 1.4, sz * 2.8, sz * 2.8), false, Color(c.r, c.g, c.b, k))
			3:
				draw_texture_rect(RING, Rect2(p.x - sz, p.y - sz, sz * 2.0, sz * 2.0), false, Color(c.r, c.g, c.b, c.a * k))
	# M002: wards, burning zones, arcs
	if battle != null:
		for wd in battle.wards:
			var k: float = clampf(wd.t / wd.dur, 0.0, 1.0)
			var c = Vector2(wd.x, Combat.GROUND_Y)
			var pulse = 0.75 + 0.25 * sin(wind_t * 5.0)
			draw_arc(c, wd.r, PI, TAU, 28, Color(0.55, 0.8, 1.0, 0.55 * pulse * (0.4 + 0.6 * k)), 3.0)
			draw_arc(c, wd.r * 0.96, PI, TAU, 28, Color(0.55, 0.8, 1.0, 0.18 * k), 8.0)
			for i in 6:
				var ang = PI + PI * (float(i) + 0.5) / 6.0
				draw_circle(c + Vector2(cos(ang), sin(ang)) * wd.r, 3.0, Color(0.8, 0.95, 1.0, 0.7 * k))
		for z in battle.zones:
			var zk: float = clampf(z.t / z.dur, 0.0, 1.0)
			var zp = Painter.ell_pts(Vector2(z.pos.x, Combat.GROUND_Y + 2), z.r, z.r * 0.22, 0.0, 18)
			var zc = Color(1.0, 0.4, 0.08)
			match String(z.get("look", "fire")):
				"plague":
					zc = Color(0.6, 0.9, 0.2)
				"roots":
					zc = Color(0.45, 0.3, 0.18)
			draw_colored_polygon(zp, Color(zc.r, zc.g, zc.b, 0.22 * zk))
			var o = zp.duplicate()
			o.append(zp[0])
			draw_polyline(o, Color(zc.r, zc.g, zc.b, 0.6 * zk), 2.0)
	for bo in bolts:
		var a: Vector2 = bo.a
		var b: Vector2 = bo.b
		if bo.jag:
			var pts = PackedVector2Array([a])
			var segs = 6
			var nrm = (b - a).normalized().orthogonal()
			for i in range(1, segs):
				pts.append(a.lerp(b, float(i) / segs) + nrm * rng.randf_range(-9, 9))
			pts.append(b)
			draw_polyline(pts, Color(bo.col, 0.35), bo.w * 3.0)
			draw_polyline(pts, bo.col, bo.w)
		else:
			draw_line(a, b, Color(bo.col, 0.8 * bo.t / 0.18), bo.w)
	# gale streaks
	if battle != null and absf(battle.gust_x) > 1.0:
		for i in 14:
			var x = fmod(wind_t * battle.gust_x * 6.0 + i * 197.0, Combat.WORLD_W)
			if x < 0:
				x += Combat.WORLD_W
			var y = 140.0 + fmod(i * 53.0, 300.0)
			draw_line(Vector2(x, y), Vector2(x - signf(battle.gust_x) * 40.0, y), Color(1, 1, 1, 0.22), 1.5)
