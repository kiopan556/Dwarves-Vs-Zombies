class_name Painter
extends RefCounted
## Procedural layered-polygon art toolkit + dispatcher.
## All unit art is original and drawn from code: outlined chunky shapes in a stylized,
## semi-cartoon look. `a` is any object/dictionary exposing the animation fields:
##   t, walk, atk, atk2, reload, hurt, state, aims(Array), hp_frac, special, bank, ammo

const OUT := Color(0.09, 0.07, 0.07)

# Dwarven palette
const IRON := Color("6f7680")
const IRON_D := Color("4a5058")
const STEEL := Color("9aa3ad")
const BRASS := Color("c9a24a")
const BRASS_D := Color("8f6f2a")
const COPPER := Color("b8693a")
const COPPER_D := Color("7d4424")
const LEATHER := Color("7a4b2a")
const LEATHER_D := Color("553219")
const COAL := Color("2a2626")
const DEEP_BLUE := Color("2f4f7a")
const DEEP_BLUE_D := Color("1f3554")
const FORGE := Color("f08a2a")
const SKIN := Color("e3a985")
const SKIN_D := Color("c07f5e")
const WOOD := Color("8a5a32")
const WOOD_D := Color("5e3b1e")
const CLOTH_RED := Color("8e3a2e")
const GLOW_FIRE := Color(1.0, 0.72, 0.25)

# Undead palette
const FLESH := Color("8d9b7a")
const FLESH_D := Color("5f6d53")
const FLESH_L := Color("aab796")
const BONE := Color("e6dfc6")
const BONE_D := Color("b3a98c")
const VIOLET := Color("6b3f8a")
const VIOLET_D := Color("43265a")
const SICKLY := Color("c9c45c")
const NECRO := Color(0.43, 1.0, 0.55)
const CLOTH_U := Color("4b4541")
const RUST := Color("7c4b31")
const BLOOD_U := Color("3d5a2c")


## art -> {key: true}: which animation fields each art actually reads (feeds the pose cache key)
static var used_keys := {}


static func g(a, key: String, default = 0.0):
	var uk = used_keys.get(current_art)
	if uk == null:
		uk = {}
		used_keys[current_art] = uk
	if not uk.has(key):
		uk[key] = true
	if a is Dictionary:
		return a.get(key, default)
	var v = a.get(key)
	return default if v == null else v


# ------------------------------------------------------------------ primitives
static var debug_validate := false
static var current_art := ""


static func poly(ci: CanvasItem, pts: PackedVector2Array, fill: Color, ow: float = 2.0) -> void:
	if pts.size() < 3:
		return
	if debug_validate and Geometry2D.triangulate_polygon(pts).is_empty():
		print("BAD POLY art=", current_art, " pts=", pts)
		return
	ci.draw_colored_polygon(pts, fill)
	if ow > 0.0:
		var c = pts.duplicate()
		c.append(pts[0])
		ci.draw_polyline(c, OUT, ow)


static func pts(arr: Array) -> PackedVector2Array:
	var p = PackedVector2Array()
	for v in arr:
		p.append(v)
	return p


static func circ(ci: CanvasItem, c: Vector2, r: float, fill: Color, ow: float = 2.0) -> void:
	if ow > 0.0:
		ci.draw_circle(c, r + ow * 0.5, OUT)
	ci.draw_circle(c, max(0.5, r - ow * 0.5), fill)


static func ell_pts(c: Vector2, rx: float, ry: float, rot: float = 0.0, n: int = 18, a0: float = 0.0, a1: float = TAU) -> PackedVector2Array:
	var p = PackedVector2Array()
	var full = absf(a1 - a0) >= TAU - 0.001
	var count = n if full else n + 1
	for i in count:
		var ang = a0 + (a1 - a0) * float(i) / float(n)
		p.append(c + Vector2(cos(ang) * rx, sin(ang) * ry).rotated(rot))
	return p


## M007: a small toothed cog (wreck markers on the battlefield and the minimap).
static func cog(ci: CanvasItem, c: Vector2, r: float, col: Color, teeth: int = 8) -> void:
	var p = PackedVector2Array()
	for i in teeth * 2:
		var a0 = TAU * float(i) / float(teeth * 2)
		var rr = r if i % 2 == 0 else r * 0.72
		p.append(c + Vector2.from_angle(a0 - 0.14) * rr)
		p.append(c + Vector2.from_angle(a0 + 0.14) * rr)
	ci.draw_colored_polygon(p, col)
	ci.draw_circle(c, r * 0.3, Color(0.08, 0.07, 0.06, col.a))


static func ell(ci: CanvasItem, c: Vector2, rx: float, ry: float, fill: Color, ow: float = 2.0, rot: float = 0.0) -> void:
	poly(ci, ell_pts(c, rx, ry, rot), fill, ow)


static func rect(ci: CanvasItem, r: Rect2, fill: Color, ow: float = 2.0) -> void:
	poly(ci, pts([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), fill, ow)


static func rrect_pts(r: Rect2, rad: float) -> PackedVector2Array:
	var p = PackedVector2Array()
	rad = min(rad, min(r.size.x, r.size.y) * 0.5)
	var cs = [Vector2(r.end.x - rad, r.position.y + rad), Vector2(r.end.x - rad, r.end.y - rad),
		Vector2(r.position.x + rad, r.end.y - rad), Vector2(r.position.x + rad, r.position.y + rad)]
	var starts = [-PI / 2, 0.0, PI / 2, PI]
	for i in 4:
		for k in 4:
			var ang: float = starts[i] + (PI / 2) * float(k) / 3.0
			p.append(cs[i] + Vector2(cos(ang), sin(ang)) * rad)
	return p


static func rrect(ci: CanvasItem, r: Rect2, fill: Color, ow: float = 2.0, rad: float = 4.0) -> void:
	poly(ci, rrect_pts(r, rad), fill, ow)


## Rotated rectangle around a pivot (start point), length along `ang`.
static func bar(ci: CanvasItem, from: Vector2, ang: float, length: float, width: float, fill: Color, ow: float = 2.0) -> void:
	var d = Vector2(cos(ang), sin(ang))
	var n = Vector2(-d.y, d.x) * width * 0.5
	poly(ci, pts([from + n, from + d * length + n, from + d * length - n, from - n]), fill, ow)


static func limb(ci: CanvasItem, a: Vector2, b: Vector2, w: float, col: Color) -> void:
	ci.draw_line(a, b, OUT, w + 3.0)
	ci.draw_circle(a, w * 0.5 + 1.5, OUT)
	ci.draw_circle(b, w * 0.5 + 1.5, OUT)
	ci.draw_line(a, b, col, w)
	ci.draw_circle(a, w * 0.5, col)
	ci.draw_circle(b, w * 0.5, col)


static func rivets(ci: CanvasItem, from: Vector2, to: Vector2, n: int, col: Color = BRASS) -> void:
	# M006b: a row of rivets is two batched multiline calls (dark head, bright highlight) instead of two
	# 64-segment circles per rivet; at battle scale the 2.6 px dots read the same
	if n <= 0:
		return
	var dark = PackedVector2Array()
	var hi = PackedVector2Array()
	for i in n:
		var p = from.lerp(to, (float(i) + 0.5) / float(n))
		dark.append_array([p + Vector2(-1.3, 0), p + Vector2(1.3, 0)])
		hi.append_array([p + Vector2(-1.1, -0.3), p + Vector2(0.5, -0.3)])
	ci.draw_multiline(dark, col.darkened(0.45), 2.6)
	ci.draw_multiline(hi, col.lightened(0.3), 1.4)


static func glow(ci: CanvasItem, c: Vector2, r: float, col: Color, layers: int = 3) -> void:
	for i in layers:
		var k = 1.0 - float(i) / float(layers)
		ci.draw_circle(c, r * k, Color(col.r, col.g, col.b, col.a * 0.25 * (1.0 - k * 0.5)))


static func muzzle_flash(ci: CanvasItem, at: Vector2, ang: float, size: float, strength: float) -> void:
	if strength <= 0.08:
		return
	var d = Vector2(cos(ang), sin(ang))
	var n = Vector2(-d.y, d.x)
	var s = size * strength
	var p = pts([at, at + n * s * 0.45 + d * s * 0.3, at + d * s * 1.4, at - n * s * 0.45 + d * s * 0.3])
	ci.draw_colored_polygon(p, Color(1.0, 0.86, 0.4, 0.9 * strength))
	ci.draw_circle(at + d * s * 0.35, s * 0.35, Color(1, 1, 0.85, strength))


static func wheel(ci: CanvasItem, c: Vector2, r: float, spin: float, rim: Color = WOOD, hub: Color = BRASS, spokes: int = 6) -> void:
	circ(ci, c, r, rim.darkened(0.2), 2.0)
	ci.draw_circle(c, r * 0.72, rim)
	for i in spokes:
		var ang = spin + TAU * float(i) / float(spokes)
		ci.draw_line(c, c + Vector2(cos(ang), sin(ang)) * r * 0.8, rim.darkened(0.45), 2.0)
	circ(ci, c, r * 0.28, hub, 1.5)


static func smoke_puff(ci: CanvasItem, c: Vector2, t: float, n: int = 3, col: Color = Color(0.55, 0.53, 0.52, 0.55)) -> void:
	for i in n:
		var ph = fmod(t * 0.9 + float(i) / float(n), 1.0)
		var p = c + Vector2(-ph * 10.0, -ph * 22.0)
		ci.draw_circle(p, 3.0 + ph * 6.0, Color(col.r, col.g, col.b, col.a * (1.0 - ph)))


# ------------------------------------------------------------------ dispatcher
# ------------------------------------------------------------------ composable transform stack
## Arts that nest sub-transforms (whole-body squash, then a flying hat) push/pop through here so
## the inner transform composes with the outer one instead of replacing it.
static var _xf := Transform2D.IDENTITY
static var _xf_stack: Array = []


static func xf_push(ci: CanvasItem, m: Transform2D) -> void:
	_xf_stack.append(_xf)
	_xf = _xf * m
	ci.draw_set_transform_matrix(_xf)


static func xf_pop(ci: CanvasItem) -> void:
	_xf = _xf_stack.pop_back() if not _xf_stack.is_empty() else Transform2D.IDENTITY
	ci.draw_set_transform_matrix(_xf)


## Scale about a pivot, rotate about the same pivot, then offset.
static func xf_about(pivot: Vector2, rot: float, sc: Vector2, off: Vector2 = Vector2.ZERO) -> Transform2D:
	return Transform2D(0.0, pivot + off) * Transform2D(rot, sc, 0.0, Vector2.ZERO) * Transform2D(0.0, -pivot)


static func draw_unit(ci: CanvasItem, art: String, a) -> void:
	current_art = art
	_xf = Transform2D.IDENTITY
	_xf_stack.clear()
	_draw_unit(ci, art, a)
	if _xf != Transform2D.IDENTITY or not _xf_stack.is_empty():
		_xf = Transform2D.IDENTITY
		_xf_stack.clear()
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)


static func _draw_unit(ci: CanvasItem, art: String, a) -> void:
	if ArtMechs.has(art):
		ArtMechs.draw(ci, art, a)
		return
	if ArtGiants.has(art):
		ArtGiants.draw(ci, art, a)
		return
	if ArtKit.has(art):
		ArtKit.draw(ci, art, a)
		return
	match art:
		"militia", "rifleman", "shieldbearer", "blunderbussier", "grenadier", "mechanic":
			ArtDwarves.draw(ci, art, a)
		"field_cannon", "flak_crew", "organ_gun", "brasshound", "copperback":
			ArtMachines.draw(ci, art, a)
			if art == "brasshound" or art == "copperback":
				ArtKit.legacy_damage(ci, art, a)
		"flying_machine", "scout_gyro", "bombard_gyro", "ironwing", "ironcloud":
			ArtAir.draw(ci, art, a)
		"dwarf_hold", "undead_citadel":
			ArtStructures.draw(ci, art, a)
		_:
			ArtUndead.draw(ci, art, a)


## Approximate visual bounds (for icons / health bar placement): height above origin.
static var _h_cache := {}


static func art_height(art: String) -> float:
	var c = _h_cache.get(art)
	if c != null:
		return c
	var h = _art_height(art)
	_h_cache[art] = h
	return h


static func _art_height(art: String) -> float:
	if ArtMechs.has(art) or ArtGiants.has(art):
		return 110.0
	if ArtKit.has(art):
		return ArtKit.height(art)
	match art:
		"militia", "rifleman", "blunderbussier", "grenadier", "mechanic", "rotter", "zombie_miner", "plague_runner", "skeleton", "bone_archer", "rot_spitter":
			return 52.0
		"shieldbearer", "bone_shield", "necromancer", "grave_knight":
			return 60.0
		"grave_crawler":
			return 22.0
		"field_cannon", "organ_gun":
			return 46.0
		"flak_crew":
			return 56.0
		"brasshound":
			return 56.0
		"copperback":
			return 72.0
		"miner_rig":
			return 92.0
		"boiler_stomper":
			return 112.0
		"flesh_hulk":
			return 96.0
		"bone_spire":
			return 120.0
		"mine_maw":
			return 150.0
		"flying_machine", "scout_gyro", "bombard_gyro", "carrion_bat", "plague_shrieker":
			return 34.0
		"ironwing":
			return 46.0
		"ironcloud":
			return 92.0
		"dwarf_hold", "undead_citadel":
			return 250.0
	return 50.0


static func is_air_art(art: String) -> bool:
	if ArtKit.has(art):
		var f = String(ArtKit.params(art).get("fam", ""))
		if f in ["air", "ship", "fly", "fly_cfg"]:
			return true
		if f == "corrupt":
			return String(ArtKit.params(art).get("base", "")) in ["flying_machine", "ironcloud"]
		return false
	return art in ["flying_machine", "scout_gyro", "bombard_gyro", "ironwing", "ironcloud", "carrion_bat", "plague_shrieker"]
