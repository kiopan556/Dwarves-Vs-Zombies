class_name BattleBackground
extends Node2D
## Painted environment per stage (sky gradient, layered mountains / mine caverns / ruins,
## ground strip). Static: drawn once and cached by the canvas until the environment changes.

var env := "mountain_gate"

const ENVS := {
	"mountain_gate":   {"sky": ["2b3550", "8a7f86", "d9a77a"], "far": "4c5468", "mid": "3a3f4c", "ground": "5a4c3e", "kind": "mountain"},
	"mountain_pass":   {"sky": ["24304a", "6b7a90", "c9b2a0"], "far": "56607a", "mid": "414858", "ground": "5c5044", "kind": "mountain"},
	"mine_entrance":   {"sky": ["1d2030", "4a4a58", "8a6f5a"], "far": "3a3a46", "mid": "2c2b33", "ground": "4a3d30", "kind": "mine_mouth"},
	"mine_deep":       {"sky": ["0f0d10", "1f1a1c", "2e2420"], "far": "2a2220", "mid": "1d1716", "ground": "3d3026", "kind": "cavern"},
	"ridge":           {"sky": ["30425e", "8fa0b0", "e0d0b0"], "far": "6a7488", "mid": "4a5262", "ground": "6a5a46", "kind": "ridge"},
	"ruined_outpost":  {"sky": ["231f2e", "5e5266", "b07a62"], "far": "3c3644", "mid": "2e2a34", "ground": "4e4238", "kind": "ruins"},
	"foundry_outpost": {"sky": ["2a1e1a", "6a3a28", "d8783a"], "far": "3e2c26", "mid": "2c201c", "ground": "4a3a2e", "kind": "foundry"},
	"high_ridge":      {"sky": ["3a5274", "a8bccc", "eef0f0"], "far": "8090a4", "mid": "5c687a", "ground": "707070", "kind": "ridge"},
	"mine_flooded":    {"sky": ["0e1214", "1a2226", "26302c"], "far": "1e2626", "mid": "161c1c", "ground": "2e3a34", "kind": "cavern_water"},
	# M005 Act II — The Blighted Frontier
	"dead_forest":     {"sky": ["262c2a", "66705e", "b4ac86"], "far": "424a42", "mid": "2c322c", "ground": "3d3a2c", "kind": "dead_forest"},
	"plague_marsh":    {"sky": ["262c1a", "7c8638", "c6c26a"], "far": "4a5236", "mid": "323a24", "ground": "35361f", "kind": "marsh"},
	"ruined_road":     {"sky": ["241c38", "6e4a66", "d0885a"], "far": "4a3a52", "mid": "33283a", "ground": "4a4038", "kind": "road"},
	"corrupted_mine":  {"sky": ["0c0e0c", "18201a", "24301e"], "far": "1e2a1c", "mid": "161e14", "ground": "2e3426", "kind": "fungal_mine"},
	# M006 Act III — War for the Skies (bright cerulean and white; storm slate and violet)
	"open_plains":     {"sky": ["3f78c4", "9cc8ee", "eef4f2"], "far": "8aa8b4", "mid": "6f8f58", "ground": "6a7a3e", "kind": "plains"},
	"broken_ridge":    {"sky": ["3a6cb4", "8cbce4", "f2e6c8"], "far": "8a8f9c", "mid": "5e5a5c", "ground": "6c6258", "kind": "broken_ridge"},
	"airborne_ruins":  {"sky": ["356ab8", "8ec0ea", "f4f6f8"], "far": "a4aeb8", "mid": "7a7466", "ground": "8a8478", "kind": "airborne"},
	"shattered_fort":  {"sky": ["434b5e", "8a92a2", "cec8b8"], "far": "6e7280", "mid": "4e4e56", "ground": "625a50", "kind": "shattered_fort"},
	# M007 Act IV — the fallen foundries: smog orange and rust, coal black, molten slag glow, green corruption in the seams
	"industrial_city": {"sky": ["2a1a16", "8a4a26", "d88a46"], "far": "4a3428", "mid": "2e221c", "ground": "4a4038", "kind": "industrial_city"},
	"destroyed_forge": {"sky": ["160c0a", "4a1a12", "8a3418"], "far": "3a221c", "mid": "261814", "ground": "3a2e28", "kind": "destroyed_forge"},
	"infested_factory": {"sky": ["141412", "2a2a26", "4a4a40"], "far": "2e2c28", "mid": "22201c", "ground": "38342c", "kind": "infested_factory"},
	"mech_graveyard":  {"sky": ["3a2c22", "8a6a4a", "c8a272"], "far": "6a5444", "mid": "4a3a30", "ground": "3a3028", "kind": "mech_graveyard"},
	# M008 Act V — the Black Rift: void black, rift violet, corpse-light green and bone white
	"necro_waste":     {"sky": ["26252a", "59555a", "958c84"], "far": "8a8276", "mid": "4a4644", "ground": "4a4642", "kind": "necro_waste"},
	"rift_sky":        {"sky": ["0e0820", "3a2264", "8a52aa"], "far": "3a2c48", "mid": "2a2034", "ground": "4a4252", "kind": "rift_sky"},
	"ruined_citadel":  {"sky": ["1a1226", "4e3254", "a8645a"], "far": "1e1a24", "mid": "141218", "ground": "3a3638", "kind": "ruined_citadel"},
	"realm_gate":      {"sky": ["06040c", "1c1030", "3a2050"], "far": "1a1424", "mid": "120e18", "ground": "2a2430", "kind": "realm_gate"},
}
## Storm variant (stages with a lightning storm): the same sky pushed toward slate and violet.
const STORM_SKY := ["1e2034", "4a4a6a", "8a86a0"]

var storm := false
var sky_layer: CloudLayer = null


func _ready() -> void:
	z_index = -100
	queue_redraw()
	var e: Dictionary = ENVS.get(env, {})
	if String(e.get("kind", "")) in ["plains", "broken_ridge", "airborne", "shattered_fort", "industrial_city", "destroyed_forge", "mech_graveyard",
			"necro_waste", "rift_sky"]:
		# M006: drifting cumulus on its own parallax layer (one batched draw; moving it costs nothing)
		sky_layer = CloudLayer.new()
		sky_layer.storm = storm
		sky_layer.dense = String(e.kind) == "airborne"
		sky_layer.overcast = String(e.kind) == "shattered_fort"
		sky_layer.smog = String(e.kind) in ["industrial_city", "destroyed_forge", "mech_graveyard"]   # M007: drifting smoke
		sky_layer.ash = String(e.kind) == "necro_waste"     # M008: ash storms over the bone dunes
		sky_layer.rift = String(e.kind) == "rift_sky"       # M008: violet rift-cloud drifting toward the rift
		add_child(sky_layer)
		set_process(true)
	else:
		set_process(false)


func _process(delta: float) -> void:
	if sky_layer == null:
		return
	var ct = get_viewport().get_canvas_transform()
	var sc = maxf(ct.get_scale().x, 0.01)
	var cam_left = -ct.origin.x / sc
	sky_layer.drift = fposmod(sky_layer.drift + delta * (14.0 if storm else 6.0), 1600.0)
	sky_layer.position.x = cam_left * 0.55 - sky_layer.drift


func _layer(seed_v: int, base_y: float, amp: float, step: float, col: Color, jag: float = 0.4) -> void:
	var r = RandomNumberGenerator.new()
	r.seed = seed_v
	var p = PackedVector2Array()
	p.append(Vector2(-200, Combat.GROUND_Y + 200))
	var x = -200.0
	var y = base_y
	while x <= Combat.WORLD_W + 200.0:
		y = clampf(y + r.randf_range(-amp, amp), base_y - amp * 2.5, base_y + amp)
		p.append(Vector2(x, y))
		x += step * r.randf_range(1.0 - jag, 1.0 + jag)
	p.append(Vector2(Combat.WORLD_W + 200, Combat.GROUND_Y + 200))
	draw_colored_polygon(p, col)


func _draw() -> void:
	var e: Dictionary = ENVS.get(env, ENVS.mountain_gate)
	var sky: Array = e.sky if not (storm and String(e.kind) in ["plains", "broken_ridge", "airborne", "shattered_fort"]) else STORM_SKY
	var top = Color(sky[0])
	var mid = Color(sky[1])
	var low = Color(sky[2])
	var W = Combat.WORLD_W + 400.0
	# sky gradient
	draw_polygon(PackedVector2Array([Vector2(-200, -60), Vector2(W, -60), Vector2(W, 300), Vector2(-200, 300)]),
		PackedColorArray([top, top, mid, mid]))
	draw_polygon(PackedVector2Array([Vector2(-200, 300), Vector2(W, 300), Vector2(W, Combat.GROUND_Y), Vector2(-200, Combat.GROUND_Y)]),
		PackedColorArray([mid, mid, low, low]))
	var kind: String = e.kind
	var far = Color(e.far)
	var midc = Color(e.mid)
	match kind:
		"mountain", "ridge":
			# distant peaks with snow caps
			var r = RandomNumberGenerator.new()
			r.seed = hash(env)
			var x = -150.0
			while x < W:
				var w = r.randf_range(180, 340)
				var h = r.randf_range(160, 300) if kind == "mountain" else r.randf_range(90, 180)
				var base = Combat.GROUND_Y - 120.0
				var pk = Vector2(x + w * 0.5, base - h)
				draw_colored_polygon(PackedVector2Array([Vector2(x, base + 40), pk, Vector2(x + w, base + 40)]), far)
				draw_colored_polygon(PackedVector2Array([pk, pk + Vector2(-w * 0.12, h * 0.18), pk + Vector2(-w * 0.03, h * 0.14), pk + Vector2(w * 0.05, h * 0.2), pk + Vector2(w * 0.12, h * 0.16)]), Color(0.92, 0.93, 0.96, 0.85))
				x += w * 0.7
			_layer(hash(env) + 3, Combat.GROUND_Y - 110.0, 22.0, 70.0, midc)
			_holds(far.darkened(0.2))
		"mine_mouth":
			_layer(hash(env) + 1, Combat.GROUND_Y - 220.0, 30.0, 80.0, far)
			_layer(hash(env) + 2, Combat.GROUND_Y - 120.0, 20.0, 60.0, midc)
			for mx in [900.0, 1700.0]:
				draw_colored_polygon(Painter.ell_pts(Vector2(mx, Combat.GROUND_Y - 60), 90, 80, 0.0, 16, PI, TAU), Color(0.05, 0.04, 0.04))
				for bx in [-90.0, 80.0]:
					draw_rect(Rect2(mx + bx, Combat.GROUND_Y - 140, 12, 140), Color("5e3b1e"))
				draw_rect(Rect2(mx - 96, Combat.GROUND_Y - 146, 196, 12), Color("5e3b1e"))
				Painter.glow(self, Vector2(mx, Combat.GROUND_Y - 120), 30, Color(1, 0.75, 0.3, 0.6))
		"cavern", "cavern_water":
			# cave ceiling with stalactites
			var r2 = RandomNumberGenerator.new()
			r2.seed = hash(env)
			var cp = PackedVector2Array([Vector2(-200, -60), Vector2(W, -60)])
			var x2 = W
			while x2 > -200.0:
				cp.append(Vector2(x2, r2.randf_range(70, 120)))
				if r2.randf() < 0.4:
					cp.append(Vector2(x2 - 15, r2.randf_range(150, 230)))
				x2 -= r2.randf_range(40, 90)
			cp.append(Vector2(-200, 90))
			draw_colored_polygon(cp, far.darkened(0.3))
			_layer(hash(env) + 5, Combat.GROUND_Y - 160.0, 25.0, 60.0, far)
			_layer(hash(env) + 6, Combat.GROUND_Y - 80.0, 15.0, 50.0, midc)
			# support beams + hanging lanterns
			var bx = 300.0
			while bx < W:
				draw_rect(Rect2(bx, 150, 14, Combat.GROUND_Y - 150), Color("4a2e18"))
				draw_rect(Rect2(bx - 40, 150, 94, 12), Color("4a2e18"))
				draw_line(Vector2(bx + 7, 162), Vector2(bx + 7, 190), Color(0.2, 0.2, 0.2), 1.5)
				Painter.glow(self, Vector2(bx + 7, 196), 26, Color(1, 0.7, 0.3, 0.7))
				draw_circle(Vector2(bx + 7, 196), 4, Color(1, 0.85, 0.5))
				bx += 420.0
			if kind == "cavern_water":
				draw_rect(Rect2(-200, Combat.GROUND_Y - 12, W + 200, 30), Color(0.12, 0.2, 0.2, 0.7))
		"ruins":
			_layer(hash(env) + 1, Combat.GROUND_Y - 200.0, 25.0, 90.0, far)
			var r3 = RandomNumberGenerator.new()
			r3.seed = 99
			var x3 = 200.0
			while x3 < W:
				var h3 = r3.randf_range(80, 200)
				draw_rect(Rect2(x3, Combat.GROUND_Y - 60 - h3, 40, h3 + 60), midc)
				draw_colored_polygon(PackedVector2Array([Vector2(x3, Combat.GROUND_Y - 60 - h3), Vector2(x3 + 18, Combat.GROUND_Y - 80 - h3), Vector2(x3 + 40, Combat.GROUND_Y - 50 - h3)]), midc)
				draw_rect(Rect2(x3 + 12, Combat.GROUND_Y - 30 - h3, 14, 22), Color(0.43, 1.0, 0.55, 0.12))
				x3 += r3.randf_range(260, 420)
			_layer(hash(env) + 4, Combat.GROUND_Y - 70.0, 12.0, 60.0, midc.darkened(0.2))
		"foundry":
			_layer(hash(env) + 1, Combat.GROUND_Y - 180.0, 20.0, 80.0, far)
			var x4 = 150.0
			while x4 < W:
				draw_rect(Rect2(x4, Combat.GROUND_Y - 300, 30, 300), midc)
				draw_rect(Rect2(x4 - 5, Combat.GROUND_Y - 306, 40, 10), midc.lightened(0.1))
				Painter.glow(self, Vector2(x4 + 15, Combat.GROUND_Y - 300), 30, Color(1, 0.5, 0.2, 0.4))
				draw_rect(Rect2(x4 + 40, Combat.GROUND_Y - 140, 140, 140), midc.darkened(0.15))
				for wi in 3:
					draw_rect(Rect2(x4 + 55 + wi * 40, Combat.GROUND_Y - 110, 20, 26), Color(1, 0.55, 0.2, 0.45))
				x4 += 520.0
		"dead_forest":
			_dead_forest(W, far, midc)
		"marsh":
			_marsh(W, far, midc)
		"road":
			_road(W, far, midc)
		"fungal_mine":
			_fungal_mine(W, far, midc)
		"plains":
			_plains(W, far, midc)
		"broken_ridge":
			_broken_ridge(W, far, midc)
		"airborne":
			_airborne(W, far, midc)
		"shattered_fort":
			_shattered_fort(W, far, midc)
		"industrial_city":
			_industrial_city(W, far, midc)
		"destroyed_forge":
			_destroyed_forge(W, far, midc)
		"infested_factory":
			_infested_factory(W, far, midc)
		"mech_graveyard":
			_mech_graveyard(W, far, midc)
		"necro_waste":
			_necro_waste(W, far, midc)
		"rift_sky":
			_rift_sky(W, far, midc)
		"ruined_citadel":
			_ruined_citadel(W, far, midc)
		"realm_gate":
			_realm_gate(W, far, midc)
	if storm and kind in ["plains", "broken_ridge", "airborne", "shattered_fort"]:
		# storm light: everything behind the lane sinks into slate
		draw_rect(Rect2(-200, -60, W + 200, Combat.GROUND_Y + 40), Color(0.12, 0.1, 0.22, 0.32))
	# ground strip
	var gc = Color(e.ground)
	if kind == "airborne":
		_causeway(W, gc)
		return
	if kind == "rift_sky":
		_shard_causeway(W, gc)
		return
	draw_rect(Rect2(-200, Combat.GROUND_Y - 22, W + 200, 300), gc)
	draw_rect(Rect2(-200, Combat.GROUND_Y - 24, W + 200, 4), gc.lightened(0.15))
	var rr = RandomNumberGenerator.new()
	rr.seed = 7
	for i in 160:
		var gx = rr.randf_range(-100, W)
		var gy = rr.randf_range(Combat.GROUND_Y - 18, Combat.GROUND_Y + 140)
		var pr = rr.randf_range(1.5, 4.5)
		# textured dots batch into one draw call (160 circles were 160 draw calls)
		draw_texture_rect(FxLayer.DOT, Rect2(gx - pr, gy - pr, pr * 2.0, pr * 2.0), false, gc.darkened(rr.randf_range(0.1, 0.35)))
	match kind:
		"marsh":
			# standing pools well below the battle lane (feet stay readable)
			var rp = RandomNumberGenerator.new()
			rp.seed = 31
			for i in 9:
				var px = rp.randf_range(0, W)
				draw_colored_polygon(Painter.ell_pts(Vector2(px, Combat.GROUND_Y + 70 + rp.randf_range(0, 50)), rp.randf_range(60, 140), 10, 0.0, 16), Color(0.14, 0.17, 0.08, 0.85))
				draw_line(Vector2(px - 30, Combat.GROUND_Y + 66), Vector2(px + 20, Combat.GROUND_Y + 66), Color(0.6, 0.7, 0.35, 0.18), 2.0)
		"road":
			# worn cobbles in front of the lane, with gaps
			var rc = RandomNumberGenerator.new()
			rc.seed = 53
			var cx = -200.0
			while cx < W:
				for row in 3:
					if rc.randf() < 0.18:
						continue
					var cy = Combat.GROUND_Y + 30 + row * 16
					draw_rect(Rect2(cx + (row % 2) * 9, cy, 16, 9), gc.lightened(rc.randf_range(0.04, 0.12)))
				cx += 20.0
		"plains":
			# cart ruts and wild flowers in front of the lane
			draw_multiline(PackedVector2Array([Vector2(-200, Combat.GROUND_Y + 34), Vector2(W, Combat.GROUND_Y + 36), Vector2(-200, Combat.GROUND_Y + 52), Vector2(W, Combat.GROUND_Y + 50)]), gc.darkened(0.3), 3.0)
			var rf = RandomNumberGenerator.new()
			rf.seed = 61
			for i in 70:
				var fp = Vector2(rf.randf_range(-100, W), rf.randf_range(Combat.GROUND_Y + 60, Combat.GROUND_Y + 140))
				draw_texture_rect(FxLayer.DOT, Rect2(fp - Vector2(2, 2), Vector2(4, 4)), false, [Color(0.95, 0.85, 0.4), Color(0.9, 0.95, 1.0), Color(0.85, 0.5, 0.6)][i % 3])
		"broken_ridge", "shattered_fort":
			# scree and rubble spilling in front of the lane
			var rs = RandomNumberGenerator.new()
			rs.seed = 67
			for i in 90:
				var sp = Vector2(rs.randf_range(-100, W), rs.randf_range(Combat.GROUND_Y + 20, Combat.GROUND_Y + 130))
				var sr = rs.randf_range(2.5, 7.0)
				draw_texture_rect(FxLayer.DOT, Rect2(sp - Vector2(sr, sr * 0.7), Vector2(sr * 2.0, sr * 1.4)), false, gc.lightened(rs.randf_range(0.0, 0.25)) if i % 2 == 0 else gc.darkened(rs.randf_range(0.15, 0.4)))
		"dead_forest":
			# roots cracking the earth below the lane
			var rr2 = RandomNumberGenerator.new()
			rr2.seed = 41
			for i in 14:
				var rx = rr2.randf_range(0, W)
				var p0 = Vector2(rx, Combat.GROUND_Y + 26)
				draw_polyline(PackedVector2Array([p0, p0 + Vector2(30, 14), p0 + Vector2(64, 10), p0 + Vector2(90, 26)]), gc.darkened(0.35), 3.0)
	if kind in ["industrial_city", "destroyed_forge", "infested_factory", "mech_graveyard"]:
		_foundry_ground(W, gc, kind)
	if kind in ["necro_waste", "ruined_citadel", "realm_gate"]:
		_rift_ground(W, gc, kind)
	if kind in ["cavern", "mine_mouth", "cavern_water", "fungal_mine"]:
		draw_line(Vector2(-200, Combat.GROUND_Y + 30), Vector2(W, Combat.GROUND_Y + 30), Color(0.35, 0.33, 0.32), 3.0)
		draw_line(Vector2(-200, Combat.GROUND_Y + 40), Vector2(W, Combat.GROUND_Y + 40), Color(0.35, 0.33, 0.32), 3.0)
		var sx = -200.0
		while sx < W:
			draw_rect(Rect2(sx, Combat.GROUND_Y + 27, 6, 18), Color("4a2e18"))
			sx += 26.0
	# corruption creeping in from the undead side
	draw_polygon(PackedVector2Array([Vector2(Combat.WORLD_W * 0.62, Combat.GROUND_Y - 22), Vector2(W, Combat.GROUND_Y - 22), Vector2(W, Combat.GROUND_Y + 200), Vector2(Combat.WORLD_W * 0.62, Combat.GROUND_Y + 200)]),
		PackedColorArray([Color(0.3, 0.5, 0.25, 0.0), Color(0.3, 0.5, 0.25, 0.35), Color(0.3, 0.5, 0.25, 0.35), Color(0.3, 0.5, 0.25, 0.0)]))


func _holds(col: Color) -> void:
	# distant dwarven hold windows carved into the left mountains
	draw_colored_polygon(PackedVector2Array([Vector2(-200, Combat.GROUND_Y), Vector2(-200, Combat.GROUND_Y - 330), Vector2(120, Combat.GROUND_Y - 260), Vector2(340, Combat.GROUND_Y - 120), Vector2(380, Combat.GROUND_Y)]), Color(col.r, col.g, col.b, 0.55))
	for i in 6:
		var p = Vector2(20 + i * 40, Combat.GROUND_Y - 200 - (i % 3) * 30 + i * 12)
		draw_rect(Rect2(p, Vector2(10, 16)), Color(1, 0.7, 0.3, 0.55))


# =============================================================== M005 Act II environments
func _tree(base: Vector2, h: float, col: Color, w: float, seed_v: int) -> void:
	var r = RandomNumberGenerator.new()
	r.seed = seed_v
	var top = base + Vector2(r.randf_range(-8, 8), -h)
	draw_colored_polygon(PackedVector2Array([base + Vector2(-w, 0), top + Vector2(-w * 0.25, 0), top + Vector2(w * 0.25, 0), base + Vector2(w, 0)]), col)
	# branches go into shared line batches (one draw call per batch, not two per branch)
	var thick: PackedVector2Array = _lines.get("t", PackedVector2Array())
	var thin: PackedVector2Array = _lines.get("f", PackedVector2Array())
	for k in 5:
		var at = base.lerp(top, 0.35 + k * 0.13)
		var sgn = -1.0 if k % 2 == 0 else 1.0
		var tip = at + Vector2(sgn * r.randf_range(h * 0.15, h * 0.3), -r.randf_range(h * 0.08, h * 0.2))
		thick.append_array([at, tip])
		thin.append_array([tip, tip + Vector2(sgn * h * 0.06, -h * 0.07)])
	_lines["t"] = thick
	_lines["f"] = thin
	_line_col = col


var _lines: Dictionary = {}
var _line_col := Color.BLACK


func _flush_lines(wt: float) -> void:
	if _lines.get("t", PackedVector2Array()).size() > 0:
		draw_multiline(_lines.t, _line_col, wt)
	if _lines.get("f", PackedVector2Array()).size() > 0:
		draw_multiline(_lines.f, _line_col, 1.5)
	_lines = {}


func _dead_forest(W: float, far: Color, midc: Color) -> void:
	_layer(hash(env) + 1, Combat.GROUND_Y - 170.0, 18.0, 90.0, far.darkened(0.1))
	var r = RandomNumberGenerator.new()
	r.seed = 11
	var x = -150.0
	while x < W:   # far leafless tree line
		_tree(Vector2(x, Combat.GROUND_Y - 150), r.randf_range(90, 160), far, 4.0, r.randi())
		x += r.randf_range(40, 80)
	_flush_lines(2.0)
	# ruined watchtower on the far ridge
	var wx = 1500.0
	draw_rect(Rect2(wx, Combat.GROUND_Y - 300, 34, 150), far.darkened(0.15))
	draw_colored_polygon(PackedVector2Array([Vector2(wx - 4, Combat.GROUND_Y - 300), Vector2(wx + 10, Combat.GROUND_Y - 322), Vector2(wx + 20, Combat.GROUND_Y - 306), Vector2(wx + 38, Combat.GROUND_Y - 300)]), far.darkened(0.15))
	draw_rect(Rect2(wx + 12, Combat.GROUND_Y - 270, 8, 14), Color(0.45, 0.9, 0.4, 0.25))
	_layer(hash(env) + 4, Combat.GROUND_Y - 80.0, 12.0, 60.0, midc)
	x = -100.0
	var moss = PackedVector2Array()
	while x < W:   # nearer trunks with hanging moss and crow perches
		var h = r.randf_range(160, 250)
		_tree(Vector2(x, Combat.GROUND_Y - 40), h, midc.darkened(0.25), 9.0, r.randi())
		_flush_lines(3.5)
		for m in 3:
			var mx = x + r.randf_range(-30, 30)
			var my = Combat.GROUND_Y - 40 - h * r.randf_range(0.45, 0.8)
			moss.append_array([Vector2(mx, my), Vector2(mx + 2, my + r.randf_range(18, 34))])
		if r.randf() < 0.5:
			var cp = Vector2(x + 18, Combat.GROUND_Y - 40 - h * 0.62)
			draw_colored_polygon(PackedVector2Array([cp + Vector2(-6, 0), cp + Vector2(0, -7), cp + Vector2(5, -5), cp + Vector2(9, -3), cp + Vector2(4, 2)]), Color(0.06, 0.06, 0.07))
		x += r.randf_range(260, 420)
	draw_multiline(moss, Color(0.42, 0.48, 0.3, 0.75), 2.0)
	# fallen trunks lie behind the lane, not on it
	for fx in [700.0, 1900.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(fx, Combat.GROUND_Y - 30), Vector2(fx + 150, Combat.GROUND_Y - 44), Vector2(fx + 154, Combat.GROUND_Y - 30), Vector2(fx + 4, Combat.GROUND_Y - 22)]), midc.darkened(0.35))
		draw_circle(Vector2(fx + 152, Combat.GROUND_Y - 37), 7.0, Color(0.42, 0.36, 0.26))
	# low sickly sun haze
	Painter.glow(self, Vector2(W * 0.66, Combat.GROUND_Y - 260), 160, Color(0.85, 0.85, 0.55, 0.18))


func _marsh(W: float, far: Color, midc: Color) -> void:
	Painter.glow(self, Vector2(W * 0.4, 170), 140, Color(0.92, 0.95, 0.5, 0.28))
	_layer(hash(env) + 1, Combat.GROUND_Y - 130.0, 10.0, 120.0, far)
	var r = RandomNumberGenerator.new()
	r.seed = 23
	# distant plague pyres
	for px in [600.0, 1450.0, 2250.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(px - 20, Combat.GROUND_Y - 120), Vector2(px, Combat.GROUND_Y - 150), Vector2(px + 20, Combat.GROUND_Y - 120)]), far.darkened(0.3))
		Painter.glow(self, Vector2(px, Combat.GROUND_Y - 156), 40, Color(0.6, 1.0, 0.3, 0.35))
		draw_line(Vector2(px, Combat.GROUND_Y - 160), Vector2(px + 30, Combat.GROUND_Y - 260), Color(0.5, 0.55, 0.3, 0.25), 10.0)
	# half-sunk huts on stilts
	for hx in [350.0, 1150.0, 1980.0]:
		var base = Combat.GROUND_Y - 70.0
		for k in 3:
			draw_line(Vector2(hx + k * 24, base), Vector2(hx + k * 24 + 3, base + 40), Color(0.22, 0.18, 0.12), 3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(hx - 10, base), Vector2(hx + 60, base + 8), Vector2(hx + 58, base - 30), Vector2(hx - 6, base - 34)]), midc.darkened(0.2))
		draw_colored_polygon(PackedVector2Array([Vector2(hx - 16, base - 32), Vector2(hx + 24, base - 60), Vector2(hx + 66, base - 26)]), Color(0.3, 0.26, 0.16))
		draw_rect(Rect2(hx + 18, base - 22, 9, 10), Color(1.0, 0.7, 0.3, 0.5))
	_layer(hash(env) + 4, Combat.GROUND_Y - 50.0, 6.0, 80.0, midc)
	# reed beds behind the lane
	var x = -150.0
	var reeds = PackedVector2Array()
	var heads = PackedVector2Array()
	while x < W:
		for k in 6:
			var rx = x + k * 6 + r.randf_range(-2, 2)
			var h = r.randf_range(24, 46)
			reeds.append_array([Vector2(rx, Combat.GROUND_Y - 22), Vector2(rx + r.randf_range(-4, 4), Combat.GROUND_Y - 22 - h)])
			if k % 2 == 0:
				heads.append_array([Vector2(rx + 1, Combat.GROUND_Y - 22 - h - 6), Vector2(rx + 1, Combat.GROUND_Y - 22 - h + 2)])
		x += r.randf_range(90, 200)
	draw_multiline(reeds, Color(0.38, 0.42, 0.2), 2.0)
	draw_multiline(heads, Color(0.34, 0.24, 0.12), 4.0)
	# yellow-green fog bank
	draw_polygon(PackedVector2Array([Vector2(-200, Combat.GROUND_Y - 120), Vector2(W, Combat.GROUND_Y - 120), Vector2(W, Combat.GROUND_Y - 20), Vector2(-200, Combat.GROUND_Y - 20)]),
		PackedColorArray([Color(0.7, 0.75, 0.35, 0.0), Color(0.7, 0.75, 0.35, 0.0), Color(0.7, 0.75, 0.35, 0.22), Color(0.7, 0.75, 0.35, 0.22)]))


func _road(W: float, far: Color, midc: Color) -> void:
	_layer(hash(env) + 1, Combat.GROUND_Y - 190.0, 24.0, 100.0, far)
	# broken aqueduct
	var ax = 300.0
	var top = Combat.GROUND_Y - 250.0
	draw_rect(Rect2(ax, top, 900, 22), far.darkened(0.15))
	for k in 7:
		var px = ax + k * 130.0
		if k == 4:
			continue   # the collapsed span
		draw_rect(Rect2(px, top + 22, 26, 150), far.darkened(0.15))
		draw_arc(Vector2(px + 78, top + 22), 52.0, 0.0, PI, 12, far.darkened(0.15), 8.0)
	draw_rect(Rect2(ax + 4 * 130 - 30, top - 6, 80, 40), Color(0, 0, 0, 0))
	# gibbets on the ridge
	for gx in [1500.0, 1700.0, 2050.0]:
		var gy = Combat.GROUND_Y - 170.0
		draw_line(Vector2(gx, gy), Vector2(gx, gy - 60), Color(0.12, 0.1, 0.1), 3.0)
		draw_line(Vector2(gx, gy - 60), Vector2(gx + 26, gy - 60), Color(0.12, 0.1, 0.1), 3.0)
		draw_line(Vector2(gx + 24, gy - 60), Vector2(gx + 24, gy - 46), Color(0.12, 0.1, 0.1), 1.0)
		draw_rect(Rect2(gx + 19, gy - 46, 10, 16), Color(0.12, 0.1, 0.1))
	_layer(hash(env) + 4, Combat.GROUND_Y - 70.0, 10.0, 70.0, midc)
	# overturned wagons and milestones behind the lane
	for wx in [520.0, 1720.0]:
		var wy = Combat.GROUND_Y - 30.0
		draw_colored_polygon(PackedVector2Array([Vector2(wx, wy), Vector2(wx + 90, wy - 6), Vector2(wx + 84, wy - 40), Vector2(wx + 4, wy - 34)]), Color(0.3, 0.22, 0.14))
		Painter.wheel(self, Vector2(wx + 20, wy - 46), 14.0, 0.3, Color(0.25, 0.18, 0.1), Color(0.4, 0.3, 0.18), 8)
	for mx in [260.0, 1180.0, 2300.0]:
		draw_rect(Rect2(mx, Combat.GROUND_Y - 46, 16, 26), midc.lightened(0.15))
		draw_circle(Vector2(mx + 8, Combat.GROUND_Y - 46), 8.0, midc.lightened(0.15))


func _fungal_mine(W: float, far: Color, midc: Color) -> void:
	var r2 = RandomNumberGenerator.new()
	r2.seed = hash(env)
	var cp = PackedVector2Array([Vector2(-200, -60), Vector2(W, -60)])
	var x2 = W
	while x2 > -200.0:
		cp.append(Vector2(x2, r2.randf_range(70, 120)))
		if r2.randf() < 0.4:
			cp.append(Vector2(x2 - 15, r2.randf_range(150, 220)))
		x2 -= r2.randf_range(40, 90)
	cp.append(Vector2(-200, 90))
	draw_colored_polygon(cp, far.darkened(0.3))
	_layer(hash(env) + 5, Combat.GROUND_Y - 160.0, 25.0, 60.0, far)
	# glowing fungus on the walls
	for i in 40:   # textured dots batch into one draw call (40 glows were ~160 calls)
		var fp = Vector2(r2.randf_range(-100, W), r2.randf_range(160, Combat.GROUND_Y - 100))
		var gr = r2.randf_range(10, 22)
		draw_texture_rect(FxLayer.DOT, Rect2(fp - Vector2(gr, gr), Vector2(gr, gr) * 2.0), false, Color(0.5, 1.0, 0.45, 0.16))
		var cr = r2.randf_range(2, 4)
		draw_texture_rect(FxLayer.DOT, Rect2(fp - Vector2(cr, cr), Vector2(cr, cr) * 2.0), false, Color(0.75, 1.0, 0.6, 0.9))
	_layer(hash(env) + 6, Combat.GROUND_Y - 80.0, 15.0, 50.0, midc)
	# timbered galleries
	var bx = 260.0
	while bx < W:
		draw_rect(Rect2(bx, 150, 14, Combat.GROUND_Y - 150), Color("3a2a16"))
		draw_rect(Rect2(bx - 40, 150, 94, 12), Color("3a2a16"))
		# fungus creeping up the post
		for k in 3:
			draw_colored_polygon(Painter.ell_pts(Vector2(bx + 14, Combat.GROUND_Y - 120 - k * 60), 9, 4, 0.0, 10, -PI * 0.5, PI * 0.5), Color(0.55, 0.75, 0.35))
		bx += 380.0
	# spore stalks and ore carts behind the lane
	for sx in [450.0, 1250.0, 2050.0]:
		draw_line(Vector2(sx, Combat.GROUND_Y - 22), Vector2(sx + 6, Combat.GROUND_Y - 110), Color(0.4, 0.45, 0.3), 4.0)
		draw_colored_polygon(Painter.ell_pts(Vector2(sx + 6, Combat.GROUND_Y - 116), 16, 9, 0.0, 12), Color(0.55, 0.8, 0.35))
		Painter.glow(self, Vector2(sx + 6, Combat.GROUND_Y - 116), 28, Color(0.6, 1.0, 0.4, 0.3))
	for cx in [800.0, 1650.0]:
		Painter.rrect(self, Rect2(cx, Combat.GROUND_Y - 50, 50, 26), Color("3a3430"), 2.0, 2.0)
		draw_circle(Vector2(cx + 12, Combat.GROUND_Y - 22), 6.0, Color("2a2622"))
		draw_circle(Vector2(cx + 38, Combat.GROUND_Y - 22), 6.0, Color("2a2622"))
	# dripping water glints
	var drips = PackedVector2Array()
	for i in 12:
		var dx = r2.randf_range(0, W)
		drips.append_array([Vector2(dx, 120 + r2.randf_range(0, 60)), Vector2(dx, 130 + r2.randf_range(60, 120))])
	draw_multiline(drips, Color(0.6, 0.8, 0.8, 0.2), 1.0)



# =============================================================== M006 Act III environments
func _cumulus(c: Vector2, w: float, h: float, col: Color, seed_v: int) -> void:
	# a towering cloud from a handful of DOT puffs (one batched draw for the whole bank)
	var r = RandomNumberGenerator.new()
	r.seed = seed_v
	for k in 9:
		var px = c.x + r.randf_range(-w * 0.5, w * 0.5)
		var py = c.y - absf(r.randf_range(0.0, h)) * (1.0 - absf(px - c.x) / w)
		var pr = r.randf_range(w * 0.18, w * 0.32)
		draw_texture_rect(FxLayer.DOT, Rect2(px - pr, py - pr * 0.8, pr * 2.0, pr * 1.6), false, col)
	draw_texture_rect(FxLayer.DOT, Rect2(c.x - w * 0.6, c.y - h * 0.15, w * 1.2, h * 0.4), false, col.darkened(0.06))


func _windmill(p: Vector2, s: float, col: Color, ang: float) -> void:
	draw_colored_polygon(PackedVector2Array([p + Vector2(-8, 0) * s, p + Vector2(-5, -46) * s, p + Vector2(5, -46) * s, p + Vector2(8, 0) * s]), col)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-7, -46) * s, p + Vector2(0, -56) * s, p + Vector2(7, -46) * s]), col.darkened(0.2))
	var hub = p + Vector2(0, -48) * s
	var blades = PackedVector2Array()
	for k in 4:
		var a = ang + k * PI * 0.5
		blades.append_array([hub, hub + Vector2(cos(a), sin(a)) * 34.0 * s])
	draw_multiline(blades, col.darkened(0.3), 3.0 * s)


func _plains(W: float, far: Color, midc: Color) -> void:
	# towering cumulus on the horizon (the parallax layer carries the drifting ones)
	for i in 6:
		_cumulus(Vector2(-100 + i * 520 + (i % 2) * 140, Combat.GROUND_Y - 200 - (i % 3) * 30), 220, 170, Color(1, 1, 1, 0.75), 300 + i)
	_layer(hash(env) + 1, Combat.GROUND_Y - 150.0, 10.0, 160.0, far)
	# distant windmills and burnt farmsteads with smoke
	for wx in [380.0, 1260.0, 2160.0]:
		_windmill(Vector2(wx, Combat.GROUND_Y - 140), 0.9, far.darkened(0.25), wx * 0.01)
	for fx in [820.0, 1700.0]:
		var fy = Combat.GROUND_Y - 120.0
		draw_colored_polygon(PackedVector2Array([Vector2(fx, fy), Vector2(fx, fy - 26), Vector2(fx + 24, fy - 44), Vector2(fx + 50, fy - 30), Vector2(fx + 54, fy - 12), Vector2(fx + 62, fy)]), Color(0.18, 0.16, 0.16))
		for k in 5:
			var sp = Vector2(fx + 30 + k * 12, fy - 60 - k * 34)
			var sr = 16.0 + k * 9.0
			draw_texture_rect(FxLayer.DOT, Rect2(sp - Vector2(sr, sr), Vector2(sr, sr) * 2.0), false, Color(0.35, 0.33, 0.35, 0.22 - k * 0.03))
	_layer(hash(env) + 4, Combat.GROUND_Y - 70.0, 8.0, 120.0, midc)
	# tall grass behind the lane and standing stones
	var r = RandomNumberGenerator.new()
	r.seed = 17
	var grass = PackedVector2Array()
	var x = -150.0
	while x < W:
		var gx = x + r.randf_range(0, 14)
		var h = r.randf_range(14, 30)
		grass.append_array([Vector2(gx, Combat.GROUND_Y - 22), Vector2(gx + r.randf_range(-6, 6), Combat.GROUND_Y - 22 - h)])
		x += r.randf_range(5, 12)
	draw_multiline(grass, midc.lightened(0.12), 2.0)
	for sx in [600.0, 1500.0, 2280.0]:
		for k in 3:
			var stx = sx + k * 22
			var sh = 34.0 + (k % 2) * 16.0
			draw_colored_polygon(PackedVector2Array([Vector2(stx, Combat.GROUND_Y - 22), Vector2(stx + 2, Combat.GROUND_Y - 22 - sh), Vector2(stx + 12, Combat.GROUND_Y - 26 - sh), Vector2(stx + 15, Combat.GROUND_Y - 22)]), Color(0.52, 0.52, 0.5))
	Painter.glow(self, Vector2(W * 0.25, 120), 160, Color(1.0, 0.98, 0.85, 0.35))


func _broken_ridge(W: float, far: Color, midc: Color) -> void:
	Painter.glow(self, Vector2(W * 0.75, 100), 150, Color(1.0, 0.95, 0.75, 0.4))
	# jagged split ridges: a lit face and a deep-shadow face each
	var r = RandomNumberGenerator.new()
	r.seed = 29
	var x = -180.0
	var spires: Array = []
	while x < W:
		var w = r.randf_range(120, 220)
		var h = r.randf_range(200, 330)
		var base = Combat.GROUND_Y - 60.0
		var pk = Vector2(x + w * r.randf_range(0.35, 0.6), base - h)
		draw_colored_polygon(PackedVector2Array([Vector2(x, base), pk, Vector2(pk.x, base)]), far.lightened(0.1))
		draw_colored_polygon(PackedVector2Array([Vector2(pk.x, base), pk, Vector2(pk.x + 12, pk.y + 30), Vector2(x + w, base)]), far.darkened(0.3))
		# the split: a dark crack down the spire
		draw_line(pk + Vector2(2, 10), Vector2(pk.x - 6, base - h * 0.3), far.darkened(0.55), 4.0)
		spires.append(pk)
		x += w * 0.85
	# rope bridges between neighbouring spires (planks in one batch)
	var planks = PackedVector2Array()
	for i in range(0, spires.size() - 1, 2):
		var a: Vector2 = spires[i] + Vector2(10, 70)
		var b: Vector2 = spires[i + 1] + Vector2(-10, 70)
		var pts = PackedVector2Array()
		for k in 11:
			var f = float(k) / 10.0
			var p = a.lerp(b, f) + Vector2(0, sin(f * PI) * 26.0)
			pts.append(p)
			planks.append_array([p + Vector2(0, -2), p + Vector2(0, 5)])
		draw_polyline(pts, Color(0.3, 0.24, 0.16), 2.0)
	draw_multiline(planks, Color(0.42, 0.32, 0.2), 3.0)
	_layer(hash(env) + 4, Combat.GROUND_Y - 70.0, 16.0, 60.0, midc, 0.6)
	# cairns on the rocky shelf behind the lane
	for cx in [480.0, 1340.0, 2140.0]:
		for k in 4:
			var cr = 11.0 - k * 2.0
			draw_texture_rect(FxLayer.DOT, Rect2(cx - cr, Combat.GROUND_Y - 26 - k * 12 - cr, cr * 2.0, cr * 1.5), false, Color(0.62, 0.6, 0.56))


func _island(c: Vector2, w: float, top_col: Color, rock: Color, tower: bool, seed_v: int, fall: Color = Color(0.85, 0.95, 1.0, 0.4)) -> void:
	var r = RandomNumberGenerator.new()
	r.seed = seed_v
	# the rock: a lit upper band and a shadowed, tapering underside with jagged drips
	var pts = PackedVector2Array([c + Vector2(-w * 0.5, 0)])
	for k in 8:
		var f = float(k + 1) / 9.0
		pts.append(c + Vector2(-w * 0.5 + w * f, w * 0.62 * pow(sin(f * PI), 1.4) + r.randf_range(-4, 14)))
	pts.append(c + Vector2(w * 0.5, 0))
	draw_colored_polygon(pts, rock.darkened(0.25))
	draw_colored_polygon(PackedVector2Array([c + Vector2(-w * 0.5, 0), c + Vector2(-w * 0.38, w * 0.16), c + Vector2(w * 0.1, w * 0.2), c + Vector2(w * 0.42, w * 0.12), c + Vector2(w * 0.5, 0)]), rock)
	var strata = PackedVector2Array()
	for k in 3:
		var yy = c.y + w * (0.07 + k * 0.08)
		var half = w * (0.44 - k * 0.09)
		strata.append_array([Vector2(c.x - half, yy), Vector2(c.x + half * 0.8, yy + 3)])
	draw_multiline(strata, rock.darkened(0.4), 2.0)
	# grass lip with tufts, and roots hanging below
	draw_colored_polygon(PackedVector2Array([c + Vector2(-w * 0.53, 3), c + Vector2(-w * 0.46, -9), c + Vector2(w * 0.46, -9), c + Vector2(w * 0.53, 3), c + Vector2(w * 0.3, 7), c + Vector2(-w * 0.2, 6)]), top_col)
	var tufts = PackedVector2Array()
	for k in int(w / 14.0):
		var tx0 = c.x - w * 0.44 + k * 14.0 + r.randf_range(-3, 3)
		tufts.append_array([Vector2(tx0, c.y - 8), Vector2(tx0 + 2, c.y - 15)])
	for k in 4:
		var rx = c.x + r.randf_range(-w * 0.3, w * 0.3)
		var ry = c.y + w * 0.25 + r.randf_range(0, w * 0.15)
		tufts.append_array([Vector2(rx, ry), Vector2(rx + r.randf_range(-6, 6), ry + r.randf_range(14, 30))])
	draw_multiline(tufts, top_col.darkened(0.35), 2.0)
	if tower:
		var tx = c.x + r.randf_range(-w * 0.2, w * 0.1)
		var th = w * 0.6
		draw_rect(Rect2(tx, c.y - 8 - th, w * 0.14, th), rock.lightened(0.15))
		draw_rect(Rect2(tx + w * 0.09, c.y - 8 - th, w * 0.05, th), rock.darkened(0.1))
		draw_colored_polygon(PackedVector2Array([Vector2(tx - 2, c.y - 8 - th), Vector2(tx + w * 0.05, c.y - 18 - th), Vector2(tx + w * 0.09, c.y - 10 - th), Vector2(tx + w * 0.16, c.y - 8 - th)]), rock.lightened(0.1))
		draw_rect(Rect2(tx + w * 0.04, c.y - th * 0.7, w * 0.05, w * 0.07), Color(0.43, 1.0, 0.55, 0.3))
		draw_rect(Rect2(tx + w * 0.04, c.y - th * 0.35, w * 0.05, w * 0.07), Color(0.05, 0.05, 0.08, 0.8))
	# a waterfall spilling off the edge into the cloud
	var wx = c.x + w * 0.3
	draw_line(Vector2(wx, c.y + 2), Vector2(wx + 3, c.y + w * 1.1), fall, 5.0)
	draw_line(Vector2(wx + 1, c.y + 2), Vector2(wx + 3, c.y + w * 0.9), Color(fall.lightened(0.4), minf(1.0, fall.a * 1.5)), 2.0)


func _airborne(W: float, far: Color, midc: Color) -> void:
	# the cloud sea below everything, with far islands floating above it
	draw_polygon(PackedVector2Array([Vector2(-200, 330), Vector2(W, 330), Vector2(W, Combat.GROUND_Y + 300), Vector2(-200, Combat.GROUND_Y + 300)]),
		PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0), Color(0.96, 0.97, 1.0, 1.0), Color(0.96, 0.97, 1.0, 1.0)]))
	# tiny distant islets (silhouettes) for depth
	var rr = RandomNumberGenerator.new()
	rr.seed = 88
	for i in 10:
		var dc = Vector2(rr.randf_range(-100, W), rr.randf_range(300, 360))
		var dw = rr.randf_range(30, 60)
		draw_colored_polygon(PackedVector2Array([dc + Vector2(-dw * 0.5, 0), dc + Vector2(0, dw * 0.5), dc + Vector2(dw * 0.5, 0)]), Color(0.62, 0.7, 0.8, 0.7))
	for i in 9:
		_cumulus(Vector2(-150 + i * 330, 420 + (i % 2) * 20), 200, 60, Color(1, 1, 1, 0.85), 400 + i)
	var chains = PackedVector2Array()
	var isles = [[Vector2(220, 250), 160.0, true], [Vector2(560, 205), 90.0, false], [Vector2(1180, 240), 190.0, true], [Vector2(1560, 180), 100.0, false], [Vector2(2080, 230), 150.0, true], [Vector2(2420, 285), 110.0, false]]
	for i in isles.size():
		_island(isles[i][0], isles[i][1], Color(0.52, 0.66, 0.4), far.darkened(0.12), isles[i][2], 500 + i)
	# chains only between near neighbours, slung from rock to rock
	for pair in [[0, 1], [2, 3], [4, 5]]:
		var ia = isles[pair[0]]
		var ib = isles[pair[1]]
		var a: Vector2 = ia[0] + Vector2(ia[1] * 0.42, 10)
		var b: Vector2 = ib[0] - Vector2(ib[1] * 0.42, -10)
		if a.x > b.x:
			a = ia[0] - Vector2(ia[1] * 0.42, -10)
			b = ib[0] + Vector2(ib[1] * 0.42, 10)
		for k in 10:
			var f0 = float(k) / 10.0
			var f1 = float(k + 1) / 10.0
			chains.append_array([a.lerp(b, f0) + Vector2(0, sin(f0 * PI) * 22.0), a.lerp(b, f1) + Vector2(0, sin(f1 * PI) * 22.0)])
	draw_multiline(chains, Color(0.22, 0.22, 0.26, 0.85), 3.0)


## The battle lane on a floating rock: a paved stone causeway, the rock's underside tapering away
## below it, and the cloud sea far beneath (nothing is drawn on the lane itself).
func _causeway(W: float, gc: Color) -> void:
	var rock = Color(0.36, 0.33, 0.3)
	var under = PackedVector2Array([Vector2(-200, Combat.GROUND_Y - 22)])
	var r = RandomNumberGenerator.new()
	r.seed = 71
	var x = -200.0
	while x <= W:
		under.append(Vector2(x, Combat.GROUND_Y + 40 + r.randf_range(10, 70) + 40.0 * absf(sin(x * 0.004))))
		x += 60.0
	under.append(Vector2(W, Combat.GROUND_Y - 22))
	draw_colored_polygon(under, rock)
	draw_rect(Rect2(-200, Combat.GROUND_Y - 22, W + 200, 34), gc)
	draw_rect(Rect2(-200, Combat.GROUND_Y - 24, W + 200, 4), gc.lightened(0.2))
	var joints = PackedVector2Array()
	var px = -200.0
	while px < W:
		joints.append_array([Vector2(px, Combat.GROUND_Y - 20), Vector2(px, Combat.GROUND_Y + 12)])
		px += 46.0
	joints.append_array([Vector2(-200, Combat.GROUND_Y - 4), Vector2(W, Combat.GROUND_Y - 4)])
	draw_multiline(joints, gc.darkened(0.3), 2.0)
	# parapet stubs and hanging chains along the causeway edge
	var stubs = PackedVector2Array()
	px = -160.0
	while px < W:
		draw_rect(Rect2(px, Combat.GROUND_Y + 12, 18, 12), gc.darkened(0.15))
		stubs.append_array([Vector2(px + 9, Combat.GROUND_Y + 24), Vector2(px + 9, Combat.GROUND_Y + 60 + float(int(px) % 3) * 12.0)])
		px += 240.0
	draw_multiline(stubs, Color(0.2, 0.2, 0.22), 2.0)
	# wisps of cloud under the rock
	for i in 12:
		var cp = Vector2(-150 + i * 230, Combat.GROUND_Y + 130 + (i % 3) * 18)
		draw_texture_rect(FxLayer.DOT, Rect2(cp - Vector2(110, 26), Vector2(220, 52)), false, Color(1, 1, 1, 0.7))
	# corruption creeping in from the undead end of the causeway
	draw_polygon(PackedVector2Array([Vector2(Combat.WORLD_W * 0.62, Combat.GROUND_Y - 22), Vector2(W, Combat.GROUND_Y - 22), Vector2(W, Combat.GROUND_Y + 12), Vector2(Combat.WORLD_W * 0.62, Combat.GROUND_Y + 12)]),
		PackedColorArray([Color(0.3, 0.5, 0.25, 0.0), Color(0.3, 0.5, 0.25, 0.35), Color(0.3, 0.5, 0.25, 0.35), Color(0.3, 0.5, 0.25, 0.0)]))


func _shattered_fort(W: float, far: Color, midc: Color) -> void:
	# overcast with breaks of light: shafts through the cloud deck
	for lx in [500.0, 1300.0, 2100.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(lx, 60), Vector2(lx + 80, 60), Vector2(lx + 260, Combat.GROUND_Y - 60), Vector2(lx + 90, Combat.GROUND_Y - 60)]), Color(1.0, 0.95, 0.8, 0.1))
	for i in 7:
		_cumulus(Vector2(-120 + i * 420, 90 + (i % 2) * 30), 260, 60, Color(0.62, 0.64, 0.7, 0.8), 600 + i)
	_layer(hash(env) + 1, Combat.GROUND_Y - 160.0, 14.0, 110.0, far)
	# collapsed bastions and leaning towers
	var r = RandomNumberGenerator.new()
	r.seed = 37
	for bx in [240.0, 1040.0, 1820.0]:
		var by = Combat.GROUND_Y - 70.0
		var pts = PackedVector2Array([Vector2(bx, by), Vector2(bx, by - 120)])
		var cx = bx
		while cx < bx + 300:
			cx += r.randf_range(18, 40)
			pts.append(Vector2(cx, by - r.randf_range(60, 130)))
		pts.append(Vector2(bx + 320, by))
		draw_colored_polygon(pts, midc.lightened(0.05))
		for k in 3:
			draw_rect(Rect2(bx + 40 + k * 80, by - 50, 14, 20), Color(0.08, 0.08, 0.1))
	for tx in [720.0, 1560.0, 2380.0]:
		var base = Vector2(tx, Combat.GROUND_Y - 70)
		var ang = r.randf_range(-0.22, 0.22)
		var up = Vector2(sin(ang), -cos(ang))
		var rt = Vector2(cos(ang), sin(ang))
		draw_colored_polygon(PackedVector2Array([base - rt * 22, base - rt * 22 + up * 200, base + rt * 22 + up * 210, base + rt * 22]), far.darkened(0.2))
		draw_colored_polygon(PackedVector2Array([base - rt * 26 + up * 200, base + up * 236, base + rt * 26 + up * 210]), far.darkened(0.35))
		# a tattered banner
		var fp = base + up * 190 + rt * 22
		draw_colored_polygon(PackedVector2Array([fp, fp + Vector2(30, 6), fp + Vector2(22, 14), fp + Vector2(30, 24), fp + Vector2(0, 26)]), Color(0.35, 0.12, 0.14))
	_layer(hash(env) + 4, Combat.GROUND_Y - 70.0, 10.0, 70.0, midc.darkened(0.1))
	# broken gun emplacements behind the lane
	for gx in [560.0, 1420.0, 2200.0]:
		var gy = Combat.GROUND_Y - 26.0
		draw_colored_polygon(Painter.ell_pts(Vector2(gx, gy), 40, 16, 0.0, 14, PI, TAU), Color(0.4, 0.38, 0.36))
		draw_line(Vector2(gx, gy - 12), Vector2(gx + 46, gy - 30), Color(0.2, 0.2, 0.22), 7.0)
		draw_line(Vector2(gx + 46, gy - 30), Vector2(gx + 58, gy - 26), Color(0.2, 0.2, 0.22), 6.0)


# =============================================================== M007 Act IV environments
## A chimney with a soot cap; `lit` puts a dim ember glow at its mouth.
func _chimney(x: float, base_y: float, w: float, h: float, col: Color, lit: bool) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(x - w * 0.5, base_y), Vector2(x - w * 0.42, base_y - h), Vector2(x + w * 0.42, base_y - h), Vector2(x + w * 0.5, base_y)]), col)
	draw_rect(Rect2(x - w * 0.55, base_y - h - 6.0, w * 1.1, 7.0), col.darkened(0.25))
	for k in 3:
		draw_rect(Rect2(x - w * 0.46, base_y - h * (0.3 + 0.22 * k), w * 0.92, 2.0), col.darkened(0.3))
	if lit:
		Painter.glow(self, Vector2(x, base_y - h - 4.0), w * 1.2, Color(1.0, 0.45, 0.15, 0.25))


## A column of black smoke rising from (x, y) and leaning with the wind (DOT quads, batched).
func _smoke_column(x: float, y: float, n: int, col: Color, lean: float) -> void:
	for k in n:
		var f = float(k) / float(maxi(1, n - 1))
		var sr = 14.0 + f * 46.0
		var p = Vector2(x + lean * f * 180.0 + sin(f * 5.0 + x) * 10.0, y - f * 330.0)
		draw_texture_rect(FxLayer.DOT, Rect2(p - Vector2(sr, sr * 0.8), Vector2(sr, sr * 0.8) * 2.0), false, Color(col.r, col.g, col.b, col.a * (1.0 - f * 0.6)))


## A gantry crane: two legs, a boom and a hanging hook.
func _gantry_crane(x: float, base_y: float, h: float, col: Color) -> void:
	var lines = PackedVector2Array([Vector2(x - 30, base_y), Vector2(x - 18, base_y - h), Vector2(x + 30, base_y), Vector2(x + 18, base_y - h),
		Vector2(x - 70, base_y - h), Vector2(x + 140, base_y - h), Vector2(x - 70, base_y - h + 10), Vector2(x + 140, base_y - h + 10)])
	for k in 6:
		var yy = base_y - h * (float(k) / 6.0)
		lines.append_array([Vector2(x - 28 + k * 1.6, yy), Vector2(x + 28 - k * 1.6, yy - h / 6.0)])
	for k in 8:
		var xx = x - 70 + k * 26
		lines.append_array([Vector2(xx, base_y - h), Vector2(xx + 13, base_y - h + 10)])
	draw_multiline(lines, col, 3.0)
	draw_line(Vector2(x + 110, base_y - h + 10), Vector2(x + 110, base_y - h + 90), col.darkened(0.2), 1.5)
	draw_rect(Rect2(x + 104, base_y - h + 90, 12, 10), col)


func _industrial_city(W: float, far: Color, midc: Color) -> void:
	# a smog-orange sky, black smoke columns leaning off a forest of chimneys
	Painter.glow(self, Vector2(W * 0.3, 160), 260, Color(1.0, 0.6, 0.25, 0.28))
	var r = RandomNumberGenerator.new()
	r.seed = 4101
	var base_far = Combat.GROUND_Y - 150.0
	# far skyline: blocky foundry halls and a chimney forest
	var x = -160.0
	while x < W:
		var bw = r.randf_range(90, 170)
		var bh = r.randf_range(70, 150)
		draw_rect(Rect2(x, base_far - bh, bw, bh + 160), far)
		# sawtooth roof on some halls
		if r.randf() < 0.5:
			var teeth = PackedVector2Array([Vector2(x, base_far - bh)])
			for k in 4:
				teeth.append(Vector2(x + bw * (k + 0.75) / 4.0, base_far - bh - 18.0))
				teeth.append(Vector2(x + bw * (k + 1.0) / 4.0, base_far - bh))
			teeth.append(Vector2(x + bw, base_far - bh + 6))
			teeth.append(Vector2(x, base_far - bh + 6))
			draw_colored_polygon(teeth, far)
		for k in int(bw / 34.0):
			if r.randf() < 0.35:
				draw_rect(Rect2(x + 10 + k * 34, base_far - bh + 20, 10, 14), Color(1.0, 0.55, 0.2, 0.25))
		x += bw + r.randf_range(-10, 30)
	var stacks: Array = []
	for i in 14:
		var cx = 60.0 + i * 190.0 + r.randf_range(-40, 40)
		var ch = r.randf_range(160, 300)
		_chimney(cx, base_far + 30.0, r.randf_range(16, 26), ch, far.darkened(0.15), r.randf() < 0.4)
		stacks.append(Vector2(cx, base_far + 30.0 - ch))
	for i in stacks.size():
		if i % 3 != 1:
			_smoke_column(stacks[i].x, stacks[i].y - 8.0, 9, Color(0.08, 0.07, 0.07, 0.42), 0.6)
	# mid: gantry cranes and a rail viaduct on brick arches
	_gantry_crane(520.0, Combat.GROUND_Y - 60.0, 230.0, midc.lightened(0.08))
	_gantry_crane(1760.0, Combat.GROUND_Y - 60.0, 260.0, midc.lightened(0.08))
	var vy = Combat.GROUND_Y - 150.0
	draw_rect(Rect2(-200, vy, W + 200, 18), midc)
	draw_rect(Rect2(-200, vy - 6, W + 200, 6), midc.darkened(0.2))
	var arch_x = -180.0
	while arch_x < W:
		draw_rect(Rect2(arch_x, vy + 18, 26, Combat.GROUND_Y - 60.0 - vy - 18), midc)
		draw_colored_polygon(Painter.ell_pts(Vector2(arch_x + 26 + 47, vy + 18), 47, 30, 0.0, 12, 0.0, PI), midc)
		arch_x += 120.0
	# rail ties on the viaduct (one batch)
	var ties = PackedVector2Array()
	var tx = -190.0
	while tx < W:
		ties.append_array([Vector2(tx, vy - 6), Vector2(tx, vy - 1)])
		tx += 14.0
	draw_multiline(ties, midc.darkened(0.35), 3.0)
	_layer(hash(env) + 4, Combat.GROUND_Y - 62.0, 6.0, 90.0, midc.darkened(0.12), 0.2)
	# fallen signs and crates behind the lane
	for sx in [380.0, 1180.0, 2020.0]:
		var sy = Combat.GROUND_Y - 30.0
		draw_colored_polygon(PackedVector2Array([Vector2(sx, sy), Vector2(sx + 64, sy - 26), Vector2(sx + 70, sy - 12), Vector2(sx + 6, sy + 12)]), Color("5a3a22"))
		draw_line(Vector2(sx + 10, sy - 2), Vector2(sx + 58, sy - 22), Painter.BRASS.darkened(0.3), 2.0)
		draw_rect(Rect2(sx + 90, sy - 20, 26, 22), Color("4a3a28"))
		draw_rect(Rect2(sx + 114, sy - 14, 20, 16), Color("3e3020"))
	# green corruption seeping through brass seams
	for gx in [1400.0, 1900.0, 2300.0]:
		draw_line(Vector2(gx, Combat.GROUND_Y - 150), Vector2(gx + 40, Combat.GROUND_Y - 70), Color(0.45, 0.95, 0.4, 0.3), 3.0)


func _destroyed_forge(W: float, far: Color, midc: Color) -> void:
	# dim red glow under a lid of smoke; cold blast furnaces and broken crucibles
	draw_rect(Rect2(-200, -60, W + 200, 150), Color(0.06, 0.03, 0.03, 0.6))
	Painter.glow(self, Vector2(W * 0.5, Combat.GROUND_Y - 120.0), 520, Color(0.9, 0.25, 0.08, 0.18))
	var r = RandomNumberGenerator.new()
	r.seed = 4202
	_layer(hash(env) + 1, Combat.GROUND_Y - 190.0, 16.0, 120.0, far)
	for i in 5:
		var fx0 = 120.0 + i * 560.0 + r.randf_range(-40, 40)
		var by = Combat.GROUND_Y - 70.0
		# blast furnace: a tapering stack with iron bands, a cold tuyere ring and a dead tap hole
		var bw = 110.0
		var bh = r.randf_range(240, 320)
		draw_colored_polygon(PackedVector2Array([Vector2(fx0 - bw * 0.5, by), Vector2(fx0 - bw * 0.32, by - bh), Vector2(fx0 + bw * 0.32, by - bh), Vector2(fx0 + bw * 0.5, by)]), far.darkened(0.1))
		for k in 5:
			var yy = by - bh * (0.15 + k * 0.17)
			var hw = lerpf(bw * 0.5, bw * 0.32, (by - yy) / bh) + 3.0
			draw_rect(Rect2(fx0 - hw, yy, hw * 2.0, 5.0), far.darkened(0.35))
		draw_rect(Rect2(fx0 - 16, by - bh - 40, 32, 40), far.darkened(0.2))
		var hole = Painter.ell_pts(Vector2(fx0, by - 30), 16, 14, 0.0, 12)
		draw_colored_polygon(hole, Color(0.08, 0.04, 0.03))
		Painter.glow(self, Vector2(fx0, by - 30), 30, Color(1.0, 0.3, 0.08, 0.3 if i % 2 == 0 else 0.12))
		_smoke_column(fx0, by - bh - 44.0, 8, Color(0.05, 0.04, 0.04, 0.5), 0.3)
	_layer(hash(env) + 4, Combat.GROUND_Y - 66.0, 10.0, 80.0, midc)
	# broken crucibles tipped on their sides, slag frozen mid-pour
	for cx in [420.0, 1250.0, 2080.0]:
		var cy = Combat.GROUND_Y - 44.0
		draw_colored_polygon(PackedVector2Array([Vector2(cx - 40, cy + 20), Vector2(cx - 46, cy - 14), Vector2(cx + 18, cy - 30), Vector2(cx + 34, cy + 4)]), midc.lightened(0.1))
		draw_colored_polygon(Painter.ell_pts(Vector2(cx - 44, cy + 2), 8, 18, 0.2, 10), Color(0.08, 0.04, 0.03))
		draw_colored_polygon(PackedVector2Array([Vector2(cx - 52, cy + 4), Vector2(cx - 90, cy + 22), Vector2(cx - 44, cy + 22)]), Color(0.55, 0.2, 0.06))
		draw_line(Vector2(cx - 50, cy + 8), Vector2(cx - 80, cy + 20), Color(1.0, 0.5, 0.15, 0.5), 2.0)
	# anvils on the shelf
	for ax in [760.0, 1640.0, 2340.0]:
		var ay = Combat.GROUND_Y - 26.0
		draw_colored_polygon(PackedVector2Array([Vector2(ax - 22, ay - 16), Vector2(ax + 24, ay - 16), Vector2(ax + 36, ay - 20), Vector2(ax + 24, ay - 11), Vector2(ax + 10, ay - 10), Vector2(ax + 8, ay), Vector2(ax - 8, ay), Vector2(ax - 10, ay - 10)]), Color(0.2, 0.18, 0.17))


func _infested_factory(W: float, far: Color, midc: Color) -> void:
	# interior: a sooted roof truss, shafts of grey light through broken skylights
	var roof_y = 70.0
	draw_rect(Rect2(-200, -60, W + 200, roof_y + 60), Color(0.07, 0.07, 0.06))
	var truss = PackedVector2Array()
	var bx = -200.0
	while bx < W:
		truss.append_array([Vector2(bx, roof_y), Vector2(bx + 80, roof_y + 40), Vector2(bx + 80, roof_y + 40), Vector2(bx + 160, roof_y)])
		bx += 160.0
	draw_multiline(truss, Color(0.16, 0.15, 0.13), 4.0)
	draw_rect(Rect2(-200, roof_y - 4, W + 200, 8), Color(0.18, 0.17, 0.15))
	var shafts: Array = [300.0, 980.0, 1620.0, 2260.0]
	# far wall: tall arched windows, mostly dark
	var wy = Combat.GROUND_Y - 80.0
	draw_rect(Rect2(-200, roof_y + 4, W + 200, wy - roof_y), far)
	var wx = -160.0
	while wx < W:
		draw_rect(Rect2(wx, roof_y + 60, 50, 140), far.darkened(0.35))
		draw_colored_polygon(Painter.ell_pts(Vector2(wx + 25, roof_y + 60), 25, 18, 0.0, 10, PI, TAU), far.darkened(0.35))
		draw_line(Vector2(wx + 25, roof_y + 46), Vector2(wx + 25, roof_y + 200), far.darkened(0.15), 2.0)
		wx += 150.0
	# steam mains along the wall, with valves and a giant idle flywheel
	for py in [roof_y + 222.0, roof_y + 240.0]:
		draw_rect(Rect2(-200, py, W + 200, 10), far.lightened(0.12))
		draw_rect(Rect2(-200, py, W + 200, 3), far.lightened(0.25))
	for vx in [420.0, 1180.0, 1900.0]:
		draw_rect(Rect2(vx, roof_y + 214, 14, 44), far.lightened(0.18))
		Painter.cog(self, Vector2(vx + 7, roof_y + 206), 9.0, Color(0.55, 0.4, 0.22), 6)
	for fwx in [640.0, 2080.0]:
		var fc = Vector2(fwx, Combat.GROUND_Y - 190.0)
		draw_arc(fc, 92.0, 0, TAU, 40, midc.lightened(0.18), 14.0)
		for k in 6:
			draw_line(fc, fc + Vector2.from_angle(k * TAU / 6.0 + 0.3) * 88.0, midc.lightened(0.12), 7.0)
		draw_circle(fc, 16.0, midc.lightened(0.25))
	# shafts of grey light through the broken skylights, over the wall
	for lx in shafts:
		draw_colored_polygon(PackedVector2Array([Vector2(lx, roof_y), Vector2(lx + 70, roof_y), Vector2(lx + 230, Combat.GROUND_Y - 30), Vector2(lx + 120, Combat.GROUND_Y - 30)]), Color(0.85, 0.88, 0.82, 0.11))
		draw_rect(Rect2(lx, roof_y - 10, 70, 12), Color(0.75, 0.78, 0.72, 0.5))
	# hanging chains and hooks (one batch)
	var chains = PackedVector2Array()
	var r = RandomNumberGenerator.new()
	r.seed = 4303
	var hooks: Array = []
	for i in 22:
		var cx = r.randf_range(-100, W)
		var cl = r.randf_range(60, 220)
		chains.append_array([Vector2(cx, roof_y + 30), Vector2(cx, roof_y + 30 + cl)])
		hooks.append(Vector2(cx, roof_y + 30 + cl))
	draw_multiline(chains, Color(0.36, 0.33, 0.3), 2.5)
	for hk in hooks:
		draw_arc(hk + Vector2(0, 6), 6.0, 0.0, PI * 1.3, 8, Color(0.36, 0.33, 0.3), 2.5)
	# assembly lines: long machine beds with half-built frames, crusted with fungus
	for ax in [80.0, 900.0, 1720.0]:
		var ay = Combat.GROUND_Y - 70.0
		draw_rect(Rect2(ax, ay - 34, 640, 34), midc.lightened(0.06))
		draw_rect(Rect2(ax, ay - 40, 640, 6), midc.lightened(0.15))
		for k in 5:
			var fx1 = ax + 50 + k * 120
			draw_colored_polygon(PackedVector2Array([Vector2(fx1, ay - 40), Vector2(fx1 + 8, ay - 110), Vector2(fx1 + 46, ay - 120), Vector2(fx1 + 56, ay - 40)]), midc)
			draw_circle(Vector2(fx1 + 28, ay - 96), 9.0, midc.darkened(0.3))
			# fungal growth on the machinery
			for j in 3:
				draw_texture_rect(FxLayer.DOT, Rect2(fx1 + j * 16 - 4, ay - 50 - j * 12, 16, 10), false, Color(0.5, 0.65, 0.3, 0.55))
		# a pale green light leaking from a fungal mass
		Painter.glow(self, Vector2(ax + 420, ay - 60), 50, Color(0.5, 0.95, 0.45, 0.18))
	_layer(hash(env) + 4, Combat.GROUND_Y - 58.0, 4.0, 80.0, midc.darkened(0.15), 0.2)


func _mech_graveyard(W: float, far: Color, midc: Color) -> void:
	# a dusty brown haze; rusted colossi half-buried, broken walkers, giant gears
	Painter.glow(self, Vector2(W * 0.7, 140), 280, Color(1.0, 0.8, 0.5, 0.25))
	_layer(hash(env) + 1, Combat.GROUND_Y - 150.0, 14.0, 130.0, far)
	var rust = far.darkened(0.15)
	# a fallen colossus head, half sunk, with a dead eye
	for hx in [460.0, 1980.0]:
		var hy = Combat.GROUND_Y - 120.0
		draw_colored_polygon(PackedVector2Array([Vector2(hx - 110, hy + 70), Vector2(hx - 100, hy - 50), Vector2(hx - 40, hy - 110), Vector2(hx + 60, hy - 100), Vector2(hx + 110, hy - 30), Vector2(hx + 120, hy + 70)]), rust)
		draw_rect(Rect2(hx - 70, hy - 54, 120, 22), rust.darkened(0.35))
		draw_circle(Vector2(hx - 30, hy - 43), 9.0, Color(0.1, 0.08, 0.07))
		draw_circle(Vector2(hx + 20, hy - 43), 9.0, Color(0.1, 0.08, 0.07))
		draw_circle(Vector2(hx + 20, hy - 43), 3.5, Color(0.45, 0.95, 0.4, 0.4))
		for k in 5:
			draw_line(Vector2(hx - 50 + k * 22, hy - 10), Vector2(hx - 50 + k * 22, hy + 20), rust.darkened(0.3), 4.0)
		# the crest: a broken horn
		draw_colored_polygon(PackedVector2Array([Vector2(hx - 20, hy - 104), Vector2(hx - 4, hy - 160), Vector2(hx + 8, hy - 102)]), rust.lightened(0.05))
	# a fallen war-frame colossus on its back, one arm still raised to the sky
	var tx = 860.0
	var ty = Combat.GROUND_Y - 80.0
	draw_colored_polygon(PackedVector2Array([Vector2(tx - 150, ty + 20), Vector2(tx - 130, ty - 40), Vector2(tx + 60, ty - 56), Vector2(tx + 140, ty - 20), Vector2(tx + 150, ty + 20)]), rust.darkened(0.05))
	for k in 6:
		draw_line(Vector2(tx - 110 + k * 40, ty - 40), Vector2(tx - 106 + k * 40, ty + 10), rust.darkened(0.3), 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(tx + 70, ty - 50), Vector2(tx + 92, ty - 190), Vector2(tx + 120, ty - 186), Vector2(tx + 104, ty - 46)]), rust.lightened(0.04))
	draw_circle(Vector2(tx + 106, ty - 190), 18.0, rust.darkened(0.15))
	for k in 3:
		draw_line(Vector2(tx + 100 + k * 6, ty - 204), Vector2(tx + 96 + k * 9, ty - 236), rust.darkened(0.1), 6.0)
	draw_circle(Vector2(tx - 60, ty - 30), 12.0, Color(0.45, 0.95, 0.4, 0.25))
	# a broken walker leg and a toppled torso
	var lx = 1240.0
	var ly = Combat.GROUND_Y - 70.0
	draw_colored_polygon(PackedVector2Array([Vector2(lx - 30, ly), Vector2(lx - 18, ly - 150), Vector2(lx + 10, ly - 150), Vector2(lx + 18, ly)]), rust.lightened(0.04))
	draw_circle(Vector2(lx - 4, ly - 150), 16.0, rust.darkened(0.2))
	draw_colored_polygon(PackedVector2Array([Vector2(lx + 30, ly), Vector2(lx + 60, ly - 70), Vector2(lx + 170, ly - 60), Vector2(lx + 190, ly)]), rust)
	# giant gears leaning in the scrap
	for gx in [880.0, 1560.0, 2380.0]:
		Painter.cog(self, Vector2(gx, Combat.GROUND_Y - 80.0), 52.0, rust.darkened(0.1), 12)
		draw_circle(Vector2(gx, Combat.GROUND_Y - 80.0), 20.0, rust.darkened(0.3))
	_layer(hash(env) + 4, Combat.GROUND_Y - 60.0, 12.0, 60.0, midc, 0.6)
	# scrap heaps on the shelf behind the lane
	var r = RandomNumberGenerator.new()
	r.seed = 4404
	for i in 26:
		var sx = r.randf_range(-100, W)
		var sw = r.randf_range(10, 30)
		draw_colored_polygon(PackedVector2Array([Vector2(sx, Combat.GROUND_Y - 22), Vector2(sx + sw * 0.3, Combat.GROUND_Y - 22 - sw * 0.7), Vector2(sx + sw, Combat.GROUND_Y - 22)]), midc.lightened(r.randf_range(0.0, 0.12)))


## Act IV ground: cobbles and rail lines (city), slag crust and cooling channels (forge), conveyor tracks and
## oil pools (factory), oil-black earth with scrap and gear teeth (graveyard) — all in front of the lane.
func _foundry_ground(W: float, gc: Color, kind: String) -> void:
	var r = RandomNumberGenerator.new()
	r.seed = 4505
	match kind:
		"industrial_city":
			var cx = -200.0
			while cx < W:
				for row in 3:
					if r.randf() < 0.12:
						continue
					draw_rect(Rect2(cx + (row % 2) * 10, Combat.GROUND_Y + 22 + row * 15, 18, 10), gc.lightened(r.randf_range(0.03, 0.1)))
				cx += 22.0
			draw_multiline(PackedVector2Array([Vector2(-200, Combat.GROUND_Y + 78), Vector2(W, Combat.GROUND_Y + 78), Vector2(-200, Combat.GROUND_Y + 96), Vector2(W, Combat.GROUND_Y + 96)]), Color(0.45, 0.42, 0.4), 3.0)
			var ties = PackedVector2Array()
			var tx = -200.0
			while tx < W:
				ties.append_array([Vector2(tx, Combat.GROUND_Y + 74), Vector2(tx, Combat.GROUND_Y + 100)])
				tx += 16.0
			draw_multiline(ties, Color(0.25, 0.2, 0.16), 4.0)
		"destroyed_forge":
			for i in 50:
				var sp = Vector2(r.randf_range(-100, W), r.randf_range(Combat.GROUND_Y + 16, Combat.GROUND_Y + 130))
				draw_texture_rect(FxLayer.DOT, Rect2(sp - Vector2(10, 4), Vector2(20, 8)), false, Color(0.12, 0.07, 0.05, 0.7))
			for k in 2:
				var yy = Combat.GROUND_Y + 50 + k * 46
				draw_line(Vector2(-200, yy), Vector2(W, yy), Color(0.14, 0.09, 0.07), 8.0)
				draw_line(Vector2(-200, yy), Vector2(W, yy), Color(0.8, 0.3, 0.08, 0.18), 2.0)
		"infested_factory":
			draw_rect(Rect2(-200, Combat.GROUND_Y + 30, W + 200, 22), Color(0.16, 0.15, 0.13))
			var rollers = PackedVector2Array()
			var rx = -200.0
			while rx < W:
				rollers.append_array([Vector2(rx, Combat.GROUND_Y + 30), Vector2(rx, Combat.GROUND_Y + 52)])
				rx += 18.0
			draw_multiline(rollers, Color(0.28, 0.26, 0.23), 3.0)
			for i in 8:
				var px = r.randf_range(0, W)
				draw_colored_polygon(Painter.ell_pts(Vector2(px, Combat.GROUND_Y + 92 + r.randf_range(0, 30)), r.randf_range(40, 90), 9, 0.0, 14), Color(0.05, 0.05, 0.06, 0.8))
				draw_line(Vector2(px - 20, Combat.GROUND_Y + 88), Vector2(px + 14, Combat.GROUND_Y + 88), Color(0.5, 0.4, 0.6, 0.25), 2.0)
		"mech_graveyard":
			for i in 70:
				var sp2 = Vector2(r.randf_range(-100, W), r.randf_range(Combat.GROUND_Y + 18, Combat.GROUND_Y + 140))
				var sr = r.randf_range(3.0, 8.0)
				draw_texture_rect(FxLayer.DOT, Rect2(sp2 - Vector2(sr, sr * 0.6), Vector2(sr * 2.0, sr * 1.2)), false, Color(0.08, 0.07, 0.06, 0.7) if i % 2 == 0 else gc.lightened(0.18))
			for gx2 in [300.0, 1100.0, 1900.0]:
				Painter.cog(self, Vector2(gx2, Combat.GROUND_Y + 110), 30.0, Color(0.32, 0.24, 0.18), 10)


# =============================================================== M008 Act V environments
func _necro_waste(W: float, far: Color, midc: Color) -> void:
	# a dead sun behind the ash; bone dunes; ribcage arches of something enormous; skull mounds
	var sun = Vector2(W * 0.38, 150)
	draw_circle(sun, 64, Color(0.85, 0.82, 0.74, 0.12))
	draw_circle(sun, 42, Color(0.8, 0.78, 0.72, 0.4))
	draw_circle(sun, 40, Color(0.36, 0.34, 0.33, 0.85))
	draw_arc(sun, 41, 0, TAU, 40, Color(0.92, 0.9, 0.82, 0.55), 2.0)
	# far bone dunes: long, smooth, pale swells
	var r = RandomNumberGenerator.new()
	r.seed = 5101
	var dunes = PackedVector2Array([Vector2(-200, Combat.GROUND_Y)])
	var x = -200.0
	while x <= W + 60.0:
		dunes.append(Vector2(x, Combat.GROUND_Y - 150.0 - 34.0 * sin(x * 0.0042 + 1.0) - 16.0 * sin(x * 0.011)))
		x += 40.0
	dunes.append(Vector2(W + 60, Combat.GROUND_Y))
	draw_colored_polygon(dunes, far)
	# ash streaks lying in the dune hollows
	var streaks = PackedVector2Array()
	for i in 40:
		var sx = r.randf_range(-100, W)
		var sy = Combat.GROUND_Y - 120.0 - 34.0 * sin(sx * 0.0042 + 1.0) - 16.0 * sin(sx * 0.011) + r.randf_range(0, 50)
		streaks.append_array([Vector2(sx, sy), Vector2(sx + r.randf_range(30, 90), sy + r.randf_range(-3, 3))])
	draw_multiline(streaks, far.lightened(0.12), 2.0)
	# ribcage arches: pairs of huge curved ribs rising out of the dunes, with a spine along the top
	var bone = Color("cfc6b2")
	var bone_d = bone.darkened(0.35)
	for rx in [380.0, 1260.0, 2120.0]:
		var base_y = Combat.GROUND_Y - 70.0
		var spine = PackedVector2Array()
		for k in 7:
			var cx = rx + k * 34.0
			var h = 150.0 + 30.0 * sin(float(k) / 6.0 * PI)
			var rib = PackedVector2Array()
			for j in 10:
				var f = float(j) / 9.0
				rib.append(Vector2(cx - 40.0 * sin(f * PI) * 0.6 + f * 12.0, base_y - h * sin(f * PI * 0.5)))
			draw_polyline(rib, bone_d, 9.0 - k * 0.3)
			draw_polyline(rib, bone, 5.0 - k * 0.2)
			spine.append(rib[rib.size() - 1])
		draw_polyline(spine, bone_d, 10.0)
		draw_polyline(spine, bone.darkened(0.1), 6.0)
		for p in spine:
			_disc(p, 6.0, 6.0, bone)
	_layer(hash(env) + 4, Combat.GROUND_Y - 62.0, 9.0, 80.0, midc, 0.4)
	# skull mounds and grave markers on the shelf behind the lane
	for i in 14:
		var mx = r.randf_range(-80, W)
		var my = Combat.GROUND_Y - 30.0
		_disc(Vector2(mx, my + 6), 34.0, 16.0, midc.lightened(0.06), 14, PI, TAU)
		for k in 3:
			var sp = Vector2(mx - 16 + k * 15, my - 2 - (k % 2) * 7)
			_disc(sp, 6.0, 6.0, bone.darkened(0.15))
			_disc(sp + Vector2(-2, 0), 1.6, 1.6, Color(0.1, 0.09, 0.08), 5)
			_disc(sp + Vector2(2, 0), 1.6, 1.6, Color(0.1, 0.09, 0.08), 5)
	for i in 10:
		var gx = r.randf_range(-80, W)
		var gy = Combat.GROUND_Y - 24.0
		var lean = r.randf_range(-0.25, 0.25)
		var up = Vector2(sin(lean), -cos(lean))
		draw_line(Vector2(gx, gy), Vector2(gx, gy) + up * 30.0, Color(0.28, 0.25, 0.22), 4.0)
		draw_line(Vector2(gx, gy) + up * 22.0 - Vector2(cos(lean), sin(lean)) * 9.0, Vector2(gx, gy) + up * 22.0 + Vector2(cos(lean), sin(lean)) * 9.0, Color(0.28, 0.25, 0.22), 4.0)
	_flush_discs()


func _rift_sky(W: float, far: Color, midc: Color) -> void:
	# a violet sky cracked by glowing rifts; shards of land pulled toward the rift (the right)
	var cracks = PackedVector2Array()
	var glow = PackedVector2Array()
	var r = RandomNumberGenerator.new()
	r.seed = 5202
	for i in 7:
		var p = Vector2(r.randf_range(0, W), r.randf_range(30, 220))
		for k in 6:
			var q = p + Vector2(r.randf_range(30, 70), r.randf_range(-26, 26))
			cracks.append_array([p, q])
			if k % 2 == 0:
				glow.append_array([p, q])
			p = q
	draw_multiline(glow, Color(0.75, 0.45, 1.0, 0.25), 9.0)
	draw_multiline(cracks, Color(0.95, 0.85, 1.0, 0.75), 2.0)
	# the rift's pull: faint streaks all running right
	var streaks = PackedVector2Array()
	for i in 30:
		var sp = Vector2(r.randf_range(-100, W), r.randf_range(240, Combat.GROUND_Y - 120))
		streaks.append_array([sp, sp + Vector2(r.randf_range(60, 140), r.randf_range(-6, 2))])
	draw_multiline(streaks, Color(0.7, 0.5, 0.95, 0.12), 2.0)
	# floating shards (dark rock with a violet underglow), tilted toward the rift
	var isles = [[Vector2(260, 240), 140.0], [Vector2(700, 180), 80.0], [Vector2(1120, 260), 170.0], [Vector2(1580, 200), 90.0], [Vector2(1980, 250), 130.0], [Vector2(2400, 190), 100.0]]
	for i in isles.size():
		var c: Vector2 = isles[i][0]
		var w: float = isles[i][1]
		draw_texture_rect(FxLayer.DOT, Rect2(c.x - w * 0.6, c.y - w * 0.05, w * 1.2, w * 0.8), false, Color(0.7, 0.35, 1.0, 0.22))
		_island(c, w, Color(0.32, 0.26, 0.36), far.darkened(0.1), i % 2 == 0, 5300 + i, Color(0.75, 0.5, 1.0, 0.3))
	_layer(hash(env) + 4, Combat.GROUND_Y + 30.0, 10.0, 90.0, midc.darkened(0.1), 0.5)


## The Act V shard causeway: a broken bridge of dark stone over nothing, rift light pouring up from below.
func _shard_causeway(W: float, gc: Color) -> void:
	draw_polygon(PackedVector2Array([Vector2(-200, Combat.GROUND_Y - 40), Vector2(W, Combat.GROUND_Y - 40), Vector2(W, Combat.GROUND_Y + 300), Vector2(-200, Combat.GROUND_Y + 300)]),
		PackedColorArray([Color(0.5, 0.2, 0.75, 0.0), Color(0.5, 0.2, 0.75, 0.0), Color(0.75, 0.45, 1.0, 0.75), Color(0.75, 0.45, 1.0, 0.75)]))
	var rock = Color(0.2, 0.17, 0.24)
	var under = PackedVector2Array([Vector2(-200, Combat.GROUND_Y - 22)])
	var r = RandomNumberGenerator.new()
	r.seed = 5404
	var x = -200.0
	while x <= W:
		under.append(Vector2(x, Combat.GROUND_Y + 30 + r.randf_range(10, 60) + 30.0 * absf(sin(x * 0.005))))
		x += 50.0
	under.append(Vector2(W, Combat.GROUND_Y - 22))
	draw_colored_polygon(under, rock)
	draw_rect(Rect2(-200, Combat.GROUND_Y - 22, W + 200, 30), gc)
	draw_rect(Rect2(-200, Combat.GROUND_Y - 24, W + 200, 4), gc.lightened(0.2))
	var joints = PackedVector2Array()
	var px = -200.0
	while px < W:
		joints.append_array([Vector2(px, Combat.GROUND_Y - 20), Vector2(px + r.randf_range(-8, 8), Combat.GROUND_Y + 8)])
		px += r.randf_range(30, 60)
	draw_multiline(joints, gc.darkened(0.35), 2.0)
	# glowing fissures in the stone and loose shards floating below the bridge
	for i in 18:
		var fx0 = r.randf_range(-100, W)
		draw_line(Vector2(fx0, Combat.GROUND_Y + 2), Vector2(fx0 + r.randf_range(10, 30), Combat.GROUND_Y + 8), Color(0.85, 0.6, 1.0, 0.6), 2.0)
	for i in 16:
		var sp = Vector2(r.randf_range(-100, W), Combat.GROUND_Y + r.randf_range(110, 240))
		var sw = r.randf_range(10, 28)
		draw_colored_polygon(PackedVector2Array([sp + Vector2(-sw, 0), sp + Vector2(0, -sw * 0.4), sp + Vector2(sw, 0), sp + Vector2(0, sw * 0.9)]), rock.lightened(0.05))
	draw_polygon(PackedVector2Array([Vector2(Combat.WORLD_W * 0.62, Combat.GROUND_Y - 22), Vector2(W, Combat.GROUND_Y - 22), Vector2(W, Combat.GROUND_Y + 8), Vector2(Combat.WORLD_W * 0.62, Combat.GROUND_Y + 8)]),
		PackedColorArray([Color(0.45, 0.25, 0.6, 0.0), Color(0.45, 0.25, 0.6, 0.4), Color(0.45, 0.25, 0.6, 0.4), Color(0.45, 0.25, 0.6, 0.0)]))


func _ruined_citadel(W: float, far: Color, midc: Color) -> void:
	# bruised dusk; tiered black citadel walls climbing toward the right (far tiers hazy, near tiers black), spires,
	# corpse-light windows, and dusk rim light along the battlements
	draw_circle(Vector2(W * 0.2, 250), 90, Color(1.0, 0.55, 0.45, 0.08))
	draw_circle(Vector2(W * 0.2, 250), 40, Color(1.0, 0.65, 0.5, 0.18))
	var green = Color(0.45, 1.0, 0.55, 0.6)
	var rim = Color(1.0, 0.55, 0.42, 0.55)
	var r = RandomNumberGenerator.new()
	r.seed = 5505
	for tier in [2, 1, 0]:
		var y0 = Combat.GROUND_Y - 130.0 - tier * 78.0
		var x0 = 120.0 + tier * 480.0
		var col = far.lerp(Color(0.32, 0.24, 0.36), tier * 0.33)
		var wall = PackedVector2Array([Vector2(x0, Combat.GROUND_Y), Vector2(x0, y0)])
		var cx = x0
		var tops = PackedVector2Array()
		while cx < W + 100.0:
			wall.append(Vector2(cx, y0))
			wall.append(Vector2(cx, y0 - 12))
			wall.append(Vector2(cx + 14, y0 - 12))
			wall.append(Vector2(cx + 14, y0))
			tops.append_array([Vector2(cx, y0 - 12), Vector2(cx + 14, y0 - 12)])
			cx += 28.0
		wall.append(Vector2(W + 100, Combat.GROUND_Y))
		draw_colored_polygon(wall, col)
		draw_multiline(tops, Color(rim, 0.25 + 0.15 * (2 - tier)), 2.0)
		# buttresses with pointed arches between them
		var bx = x0 + 40.0
		while bx < W:
			draw_rect(Rect2(bx, y0 + 6, 18, Combat.GROUND_Y - y0), col.darkened(0.25))
			draw_line(Vector2(bx, y0 + 6), Vector2(bx + 18, y0 + 6), Color(rim, 0.2), 2.0)
			var ax = bx + 70.0
			var ah = 44.0
			draw_colored_polygon(PackedVector2Array([Vector2(ax - 20, y0 + 80), Vector2(ax - 20, y0 + 80 - ah * 0.6), Vector2(ax, y0 + 80 - ah), Vector2(ax + 20, y0 + 80 - ah * 0.6), Vector2(ax + 20, y0 + 80)]), col.darkened(0.45))
			if r.randf() < 0.45:
				draw_rect(Rect2(ax - 4, y0 + 52, 8, 16), green)
			bx += 150.0
		# spires
		for k in 3:
			var sx = x0 + 160 + k * 640 + tier * 90
			if sx > W:
				continue
			var sh = 120.0 + tier * 40.0 + r.randf_range(0, 50)
			draw_rect(Rect2(sx - 12, y0 - sh, 24, sh), col.darkened(0.1))
			draw_line(Vector2(sx - 12, y0 - sh), Vector2(sx - 12, y0), Color(rim, 0.3), 2.0)
			draw_colored_polygon(PackedVector2Array([Vector2(sx - 16, y0 - sh), Vector2(sx, y0 - sh - 70), Vector2(sx + 16, y0 - sh)]), col.darkened(0.2))
			draw_line(Vector2(sx - 16, y0 - sh), Vector2(sx, y0 - sh - 70), Color(rim, 0.4), 2.0)
			draw_rect(Rect2(sx - 3, y0 - sh + 22, 6, 12), green)
	# broken courtyard walls in the middle distance
	var mw = PackedVector2Array([Vector2(-200, Combat.GROUND_Y)])
	var mx = -200.0
	while mx < W + 50.0:
		mw.append(Vector2(mx, Combat.GROUND_Y - 60.0 - r.randf_range(0, 40)))
		mx += r.randf_range(30, 80)
		if r.randf() < 0.25:
			mw.append(Vector2(mx, Combat.GROUND_Y - 30.0))
			mx += r.randf_range(40, 90)
			mw.append(Vector2(mx, Combat.GROUND_Y - 30.0))
	mw.append(Vector2(W + 50, Combat.GROUND_Y))
	draw_colored_polygon(mw, midc)
	# toppled statues of undead kings lying behind the lane: a crowned, robed figure on its side
	var stone = Color(0.24, 0.22, 0.26)
	for sx2 in [520.0, 1500.0, 2280.0]:
		var sy = Combat.GROUND_Y - 38.0
		draw_colored_polygon(PackedVector2Array([Vector2(sx2 - 90, sy + 14), Vector2(sx2 - 80, sy - 10), Vector2(sx2 + 40, sy - 18), Vector2(sx2 + 70, sy - 4), Vector2(sx2 + 60, sy + 14)]), stone)
		draw_circle(Vector2(sx2 + 82, sy - 6), 16.0, stone.lightened(0.04))
		draw_colored_polygon(PackedVector2Array([Vector2(sx2 + 96, sy - 20), Vector2(sx2 + 112, sy - 26), Vector2(sx2 + 104, sy - 14), Vector2(sx2 + 116, sy - 8), Vector2(sx2 + 98, sy + 4)]), Color(0.42, 0.36, 0.22))
		draw_circle(Vector2(sx2 + 88, sy - 10), 2.5, Color(0.45, 1.0, 0.55, 0.6))
		draw_line(Vector2(sx2 - 70, sy), Vector2(sx2 + 30, sy - 8), stone.darkened(0.4), 2.0)
		draw_rect(Rect2(sx2 - 130, sy - 6, 30, 26), stone.darkened(0.1))


func _realm_gate(W: float, far: Color, midc: Color) -> void:
	# THE RIFT: a vast vertical tear in the sky over the gate, with the gate of bone and black iron before it
	var rx = 1980.0
	var vio = Color(0.72, 0.4, 1.0)
	for k in 6:
		var ww = 260.0 - k * 38.0
		draw_texture_rect(FxLayer.DOT, Rect2(rx - ww, -40, ww * 2.0, Combat.GROUND_Y - 40), false, Color(vio, 0.1 + k * 0.035))
	var tear = PackedVector2Array()
	var edge_l = PackedVector2Array()
	var edge_r = PackedVector2Array()
	for j in 16:
		var f = float(j) / 15.0
		var y = lerpf(-40.0, Combat.GROUND_Y - 140.0, f)
		var w = 70.0 * sin(f * PI) * (0.75 + 0.25 * sin(f * 9.0))
		edge_l.append(Vector2(rx - w + sin(f * 17.0) * 8.0, y))
		edge_r.append(Vector2(rx + w * 0.8 + sin(f * 13.0) * 8.0, y))
	tear.append_array(edge_l)
	var rev = edge_r.duplicate()
	rev.reverse()
	tear.append_array(rev)
	draw_colored_polygon(tear, Color(0.92, 0.82, 1.0))
	var inner = PackedVector2Array()
	for p in tear:
		inner.append(Vector2(rx + (p.x - rx) * 0.55, p.y))
	draw_colored_polygon(inner, Color(0.2, 0.05, 0.28))
	draw_polyline(edge_l, Color(1, 1, 1, 0.9), 3.0)
	draw_polyline(edge_r, Color(1, 1, 1, 0.9), 3.0)
	# far ranges in silhouette, rim-lit violet toward the rift
	_layer(hash(env) + 1, Combat.GROUND_Y - 150.0, 18.0, 100.0, far)
	# the gate: two bone pillars, an arch of ribs, a black iron portcullis half raised
	var bone = Color("d6ccb6")
	var iron = Color(0.08, 0.07, 0.1)
	var gx0 = rx - 150.0
	var gx1 = rx + 150.0
	var gb = Combat.GROUND_Y - 40.0
	for px in [gx0, gx1]:
		draw_rect(Rect2(px - 26, gb - 260, 52, 260), bone.darkened(0.3))
		draw_rect(Rect2(px - 20, gb - 260, 40, 260), bone.darkened(0.12))
		for k in 7:
			draw_line(Vector2(px - 22, gb - 30 - k * 34), Vector2(px + 22, gb - 36 - k * 34), bone.darkened(0.45), 3.0)
		draw_circle(Vector2(px, gb - 276), 24.0, bone)
		draw_circle(Vector2(px - 8, gb - 278), 5.0, Color(0.45, 1.0, 0.55, 0.9))
		draw_circle(Vector2(px + 8, gb - 278), 5.0, Color(0.45, 1.0, 0.55, 0.9))
	var arch = PackedVector2Array()
	for j in 17:
		var a = PI + PI * float(j) / 16.0
		arch.append(Vector2(rx + cos(a) * 150.0, gb - 250.0 + sin(a) * 90.0))
	draw_polyline(arch, bone.darkened(0.35), 16.0)
	draw_polyline(arch, bone, 10.0)
	for j in range(1, 16, 2):
		draw_line(arch[j], arch[j] + (arch[j] - Vector2(rx, gb - 250.0)).normalized() * 30.0, bone.darkened(0.15), 6.0)
	var bars = PackedVector2Array()
	for k in 9:
		var bx = gx0 + 30 + k * 30.0
		bars.append_array([Vector2(bx, gb - 250), Vector2(bx, gb - 120)])
	bars.append_array([Vector2(gx0 + 26, gb - 180), Vector2(gx1 - 26, gb - 180), Vector2(gx0 + 26, gb - 130), Vector2(gx1 - 26, gb - 130)])
	draw_multiline(bars, iron, 6.0)
	for k in 9:
		var bx2 = gx0 + 30 + k * 30.0
		draw_colored_polygon(PackedVector2Array([Vector2(bx2 - 5, gb - 120), Vector2(bx2, gb - 104), Vector2(bx2 + 5, gb - 120)]), iron)
	_layer(hash(env) + 4, Combat.GROUND_Y - 56.0, 8.0, 80.0, midc, 0.4)
	# sigil stones flanking the ritual ground
	var r = RandomNumberGenerator.new()
	r.seed = 5606
	for i in 9:
		var sx = 150.0 + i * 260.0 + r.randf_range(-30, 30)
		var sy = Combat.GROUND_Y - 24.0
		draw_colored_polygon(PackedVector2Array([Vector2(sx - 12, sy), Vector2(sx - 9, sy - 46), Vector2(sx + 2, sy - 54), Vector2(sx + 11, sy - 42), Vector2(sx + 12, sy)]), Color(0.16, 0.13, 0.2))
		draw_circle(Vector2(sx, sy - 30), 4.0, Color(vio, 0.8))
		draw_texture_rect(FxLayer.DOT, Rect2(sx - 16, sy - 46, 32, 32), false, Color(vio, 0.2))


## Act V ground: ash with half-buried skulls (waste), cracked flagstones (citadel), glowing ritual sigils (gate).
func _rift_ground(W: float, gc: Color, kind: String) -> void:
	var r = RandomNumberGenerator.new()
	r.seed = 5707
	match kind:
		"necro_waste":
			for i in 50:
				var sp = Vector2(r.randf_range(-100, W), r.randf_range(Combat.GROUND_Y + 20, Combat.GROUND_Y + 130))
				draw_texture_rect(FxLayer.DOT, Rect2(sp - Vector2(16, 4), Vector2(32, 8)), false, gc.lightened(0.12))
			for i in 22:
				var skp = Vector2(r.randf_range(-100, W), r.randf_range(Combat.GROUND_Y + 28, Combat.GROUND_Y + 140))
				_disc(skp, 7.0, 5.0, Color(0.8, 0.76, 0.66), 10, PI, TAU)   # half-buried
				_disc(skp + Vector2(-2.5, -1.5), 1.4, 1.4, Color(0.12, 0.1, 0.1), 5)
				_disc(skp + Vector2(2.5, -1.5), 1.4, 1.4, Color(0.12, 0.1, 0.1), 5)
			_flush_discs()
		"ruined_citadel":
			var flags = PackedVector2Array()
			var cx = -200.0
			while cx < W:
				for row in 3:
					var yy = Combat.GROUND_Y + 24 + row * 30
					flags.append_array([Vector2(cx + (row % 2) * 24, yy), Vector2(cx + (row % 2) * 24, yy + 28)])
				cx += 48.0
			for row2 in 4:
				flags.append_array([Vector2(-200, Combat.GROUND_Y + 24 + row2 * 30), Vector2(W, Combat.GROUND_Y + 24 + row2 * 30)])
			draw_multiline(flags, gc.darkened(0.3), 2.0)
			for i in 14:
				var cp = Vector2(r.randf_range(-100, W), r.randf_range(Combat.GROUND_Y + 30, Combat.GROUND_Y + 120))
				draw_polyline(PackedVector2Array([cp, cp + Vector2(10, 6), cp + Vector2(18, 4), cp + Vector2(26, 12)]), gc.darkened(0.45), 1.5)
		"realm_gate":
			var vio = Color(0.72, 0.4, 1.0)
			for i in 7:
				var sc = Vector2(160.0 + i * 360.0 + r.randf_range(-40, 40), Combat.GROUND_Y + 80)
				draw_arc(sc, 46, 0, TAU, 28, Color(vio, 0.45), 2.5)
				draw_arc(sc, 34, 0, TAU, 24, Color(vio, 0.3), 1.5)
				for k in 6:
					var a = TAU * k / 6.0 + i
					draw_line(sc + Vector2.from_angle(a) * 34.0, sc + Vector2.from_angle(a + 2.1) * 34.0, Color(vio, 0.35), 1.5)
				draw_texture_rect(FxLayer.DOT, Rect2(sc - Vector2(60, 24), Vector2(120, 48)), false, Color(vio, 0.12))



## M008 batching: many small discs (skulls, eye sockets, bone knobs) as ONE triangle array. Separate draw_circle
## calls each cost a draw call on the GL Compatibility renderer; one array costs one.
var _discs_pts := PackedVector2Array()
var _discs_cols := PackedColorArray()
var _discs_idx := PackedInt32Array()


func _disc(c: Vector2, rx: float, ry: float, col: Color, seg: int = 8, a0: float = 0.0, a1: float = TAU) -> void:
	var base = _discs_pts.size()
	var full = absf(a1 - a0 - TAU) < 0.001
	var n = seg if full else seg + 1
	_discs_pts.append(c)
	_discs_cols.append(col)
	for k in n:
		var a = a0 + (a1 - a0) * float(k) / float(seg)
		_discs_pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
		_discs_cols.append(col)
	for k in seg:
		_discs_idx.append_array([base, base + 1 + k, base + 1 + ((k + 1) % seg if full else k + 1)])


func _flush_discs() -> void:
	if not _discs_idx.is_empty():
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), _discs_idx, _discs_pts, _discs_cols)
	_discs_pts = PackedVector2Array()
	_discs_cols = PackedColorArray()
	_discs_idx = PackedInt32Array()

## M006: drifting cumulus over the Act III skies on a parallax layer (moved, never redrawn).
class CloudLayer extends Node2D:
	var drift = 0.0
	var storm = false
	var dense = false
	var overcast = false
	var smog = false          # M007: dark smoke drifting over the foundry-cities
	var ash = false           # M008: pale ash storms over the necro waste
	var rift = false          # M008: violet rift-cloud

	func _draw() -> void:
		var r = RandomNumberGenerator.new()
		r.seed = 909
		var n = 16 if dense else 11
		for i in n:
			var cx = -1600.0 + i * (6000.0 / n) + r.randf_range(-80, 80)
			var cy = r.randf_range(60, 250 if not overcast else 160)
			var w = r.randf_range(160, 300)
			var col = Color(1, 1, 1, 0.5) if not storm else Color(0.28, 0.26, 0.38, 0.75)
			if overcast and not storm:
				col = Color(0.7, 0.72, 0.78, 0.6)
			if smog:
				col = Color(0.1, 0.08, 0.07, 0.4)
				cy = r.randf_range(40, 180)
			if ash:
				col = Color(0.72, 0.7, 0.66, 0.28)
				cy = r.randf_range(120, 380)
			if rift:
				col = Color(0.42, 0.22, 0.6, 0.35)
				cy = r.randf_range(50, 230)
			for k in 6:
				var px = cx + r.randf_range(-w * 0.45, w * 0.45)
				var py = cy - r.randf_range(0, w * 0.3) * (1.0 - absf(px - cx) / w)
				var pr = r.randf_range(w * 0.16, w * 0.3)
				draw_texture_rect(FxLayer.DOT, Rect2(px - pr, py - pr * 0.75, pr * 2.0, pr * 1.5), false, col)
