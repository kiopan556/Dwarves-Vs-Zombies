class_name ArtKit
extends RefCounted
## M003 parametric art kit: draws the rest of the roster (116 dwarves, 84 undead, 14 bosses and
## the deployable props) from per-unit parameter sets in data/art_kit.json. Every design is
## original procedural art built from shared, animated parts (dwarf body, weapons, carriages,
## hulls and turrets, airframes, envelopes, zombie and skeleton bodies, robes, beasts, siege
## engines, wings). Units face right, ground units stand on y = 0, air units are centred.

const P = preload("res://scripts/art/painter.gd")
const D = preload("res://scripts/art/art_dwarves.gd")
const AM = preload("res://scripts/art/art_machines.gd")
const AA = preload("res://scripts/art/art_air.gd")
const AU = preload("res://scripts/art/art_undead.gd")
const AG = preload("res://scripts/art/art_giants.gd")

static var K := {}
static var _loaded := false


static func _load() -> void:
	_loaded = true
	var f = FileAccess.open("res://data/art_kit.json", FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		K = d


static func has(art: String) -> bool:
	if not _loaded:
		_load()
	return K.has(art)


static func params(art: String) -> Dictionary:
	if not _loaded:
		_load()
	return K.get(art, {})


static func height(art: String) -> float:
	return float(params(art).get("h", 52.0))


static func col(p: Dictionary, key: String, def: String) -> Color:
	return Color(String(p.get(key, def)))


# ================================================================== dispatch
static func draw(ci: CanvasItem, art: String, a) -> void:
	var p: Dictionary = params(art)
	match String(p.get("fam", "")):
		"inf":
			D.goof_begin(ci, a, _gag_kind(String(p.get("weapon", "rifle"))))
			_inf(ci, a, p)
			D.goof_end(ci)
		"eng":
			var carted = String(p.get("cart", "")) in ["wagon", "forge", "crawler"]
			if not carted:
				D.goof_begin(ci, a, "tool")
			_eng(ci, a, p)
			if not carted:
				D.goof_end(ci)
		"gun": _gun(ci, a, p)
		"veh": _veh(ci, a, p)
		"air": _air(ci, a, p)
		"ship": _ship(ci, a, p)
		"prop": _prop(ci, a, p)
		"zom": _zom(ci, a, p)
		"skel": _skel(ci, a, p)
		"cast": _cast(ci, a, p)
		"beast": _beast(ci, a, p)
		"siege": _siege(ci, a, p)
		"fly": _fly(ci, a, p, 1.0)
		"fly_cfg": _fly(ci, a, p, 2.0)
		"corrupt": _corrupt(ci, art, a, p)
		"giant_cfg": _giant_cfg(ci, art, a, p)


# ================================================================== dwarven infantry
static func _gag_kind(w: String) -> String:
	match w:
		"longrifle", "heavy_rifle", "scope", "thunder_rifle":
			return "long"
		"shotgun":
			return "blast"
		"mortar_tube", "lance":
			return "heavy"
		"flamer", "steamgun", "gatling", "sprayer":
			return "spray"
		"hammer", "greathammer", "spade", "sword", "halberd":
			return "melee"
		"satchel", "grenade", "crate":
			return "throw"
	return "rifle"


static func _style(p: Dictionary) -> Dictionary:
	var coat = col(p, "coat", "2f4f7a")
	return {"coat": coat, "coat_d": coat.darkened(0.3), "beard": col(p, "beard", "7a4a2a"), "helmet": p.get("helmet", "kettle"),
		"helm_col": col(p, "helm_col", "6f7680"), "pauldron": int(p.get("plate", 0)) > 0}


static func _back(ci: CanvasItem, kind: String, y: float, t: float, glow: Color) -> void:
	match kind:
		"tank":
			P.rrect(ci, Rect2(-20, -38 + y, 9, 22), P.COPPER, 2.0, 4.0)
			P.rrect(ci, Rect2(-15, -36 + y, 7, 20), P.COPPER_D, 1.5, 3.0)
		"boiler", "furnace":
			P.rrect(ci, Rect2(-22, -40 + y, 12, 26), P.IRON_D if kind == "boiler" else P.COAL, 2.0, 4.0)
			P.rivets(ci, Vector2(-20, -36 + y), Vector2(-20, -18 + y), 3)
			ci.draw_line(Vector2(-18, -40 + y), Vector2(-18, -48 + y), P.IRON, 3.0)
			if kind == "furnace":
				ci.draw_circle(Vector2(-16, -26 + y), 3.5, Color(1.0, 0.6, 0.2, 0.7 + 0.3 * sin(t * 6.0)))
			P.smoke_puff(ci, Vector2(-18, -50 + y), t, 2)
		"ammo", "pack":
			P.rrect(ci, Rect2(-21, -36 + y, 11, 16), P.LEATHER if kind == "pack" else P.WOOD, 2.0, 2.0)
			ci.draw_line(Vector2(-21, -30 + y), Vector2(-10, -30 + y), P.LEATHER_D, 2.0)
		"coil":
			P.rrect(ci, Rect2(-21, -40 + y, 10, 22), P.IRON_D, 2.0, 3.0)
			for i in 3:
				ci.draw_line(Vector2(-22, -36 + i * 6 + y), Vector2(-10, -36 + i * 6 + y), P.COPPER, 2.0)
			ci.draw_circle(Vector2(-16, -44 + y), 3.0, Color(glow.r, glow.g, glow.b, 0.6 + 0.4 * sin(t * 8.0)))
		"flag":
			ci.draw_line(Vector2(-12, -20 + y), Vector2(-12, -62 + y), P.WOOD_D, 2.0)
			P.poly(ci, P.pts([Vector2(-12, -62 + y), Vector2(4 + sin(t * 3.0) * 2.0, -58 + y), Vector2(-12, -52 + y)]), P.CLOTH_RED, 1.2)
		"planks":
			for i in 3:
				P.bar(ci, Vector2(-22, -24 - i * 5 + y), -1.2, 26, 4.0, P.WOOD, 1.2)
		"tripod":
			ci.draw_line(Vector2(-14, -36 + y), Vector2(-20, -10 + y), P.WOOD_D, 2.0)
			ci.draw_line(Vector2(-14, -36 + y), Vector2(-8, -10 + y), P.WOOD_D, 2.0)
			P.circ(ci, Vector2(-14, -38 + y), 3.0, P.BRASS, 1.2)


static func _inf(ci: CanvasItem, a, p: Dictionary) -> void:
	var t: float = P.g(a, "t", 0.0)
	var atk: float = P.g(a, "atk", 0.0)
	var atk2: float = P.g(a, "atk2", 0.0)
	var wind: float = P.g(a, "windup", 0.0)
	var aim: float = P.g(a, "aim0", -0.6 if p.get("aim_up", false) else 0.0)
	var s = _style(p)
	var glow = col(p, "glow", "9ad8ff")
	var y0 = 0.0
	_back(ci, String(p.get("back", "")), y0, t, glow)
	var b = D.body(ci, a, s)
	var y: float = b.y
	var coat: Color = s.coat
	var shield = String(p.get("shield", ""))
	var plate = int(p.get("plate", 0))
	if plate >= 2:
		P.poly(ci, P.pts([Vector2(-11, -34 + y), Vector2(11, -34 + y), Vector2(13, -20 + y), Vector2(-12, -20 + y)]), s.helm_col, 2.0)
		P.rivets(ci, Vector2(-8, -30 + y), Vector2(9, -30 + y), 4)
	if p.get("medal", false):
		P.circ(ci, Vector2(-4, -28 + y), 2.4, P.BRASS, 1.0)
	var sf: Vector2 = b.shoulder_f
	var sb: Vector2 = b.shoulder_b
	var w = String(p.get("weapon", "rifle"))
	var recoil = atk * atk * 3.0
	match w:
		"rifle", "longrifle", "bayonet", "rune_rifle", "heavy_rifle", "aa_rifle", "repeater", "thunder_rifle", "scope":
			var grip = sf + Vector2(2 - recoil, 7)
			if w == "aa_rifle":
				aim = minf(aim, -0.5)
			D.arm(ci, sb, grip + Vector2(-2, 1), coat.darkened(0.3))
			var length = {"longrifle": 40.0, "heavy_rifle": 38.0, "scope": 22.0, "repeater": 30.0}.get(w, 32.0)
			var muzzle = D.rifle(ci, grip, aim, length, D._flash_strength(atk) if not w in ["thunder_rifle"] else 0.0)
			var dv = Vector2.from_angle(aim)
			match w:
				"bayonet":
					P.poly(ci, P.pts([muzzle, muzzle + dv * 10.0 + dv.orthogonal() * 1.0, muzzle + dv.orthogonal() * 2.0]), P.STEEL, 1.0)
				"longrifle", "scope":
					P.rrect(ci, Rect2(grip.x + 6, grip.y - 6, 10, 3), P.BRASS, 1.0, 1.0)
				"rune_rifle", "thunder_rifle":
					ci.draw_circle(grip + dv * 14.0 + Vector2(0, -2), 2.6, Color(glow.r, glow.g, glow.b, 0.85))
					if w == "thunder_rifle" and atk > 0.6:
						ci.draw_circle(muzzle, 6.0 * atk, Color(glow.r, glow.g, glow.b, 0.6))
				"repeater":
					P.rrect(ci, Rect2(grip.x + 2, grip.y + 1, 6, 6), P.IRON_D, 1.0, 1.0)
				"heavy_rifle":
					P.bar(ci, grip + dv * 16.0, aim, 18, 4.0, P.IRON_D, 1.2)
			D.arm(ci, sf, grip + dv * 12.0, coat)
		"shotgun":
			var grip2 = sf + Vector2(2 - recoil, 8)
			D.arm(ci, sb, grip2 + Vector2(-2, 1), coat.darkened(0.3))
			D.rifle(ci, grip2, aim, 24.0, D._flash_strength(atk), "blunderbuss")
			D.arm(ci, sf, grip2 + Vector2.from_angle(aim) * 10.0, coat)
		"flamer", "steamgun", "gatling", "sprayer":
			var grip3 = sf + Vector2(0, 9)
			D.arm(ci, sb, grip3 + Vector2(-2, 2), coat.darkened(0.3))
			var dv3 = Vector2.from_angle(aim)
			var n3 = dv3.orthogonal()
			var body_c = P.COPPER if w == "flamer" else (P.IRON if w == "gatling" else P.BRASS)
			P.rrect(ci, Rect2(grip3.x - 4, grip3.y - 4, 16, 8), body_c, 1.5, 2.0)
			if w == "gatling":
				var sp = P.g(a, "spin", t * 3.0)
				for i in 3:
					var off = sin(sp * 6.0 + i * 2.1) * 2.5
					P.bar(ci, grip3 + dv3 * 10.0 + n3 * off, aim, 18, 2.2, P.IRON_D, 1.0)
			else:
				P.bar(ci, grip3 + dv3 * 10.0, aim, 16, 3.5, P.IRON_D, 1.2)
			var tip = grip3 + dv3 * 28.0
			if w == "flamer" and atk > 0.05:
				for i in 4:
					var r = 4.0 + i * 3.5
					ci.draw_circle(tip + dv3 * (i * 9.0), r, Color(1.0, 0.55 + i * 0.08, 0.15, 0.7 * atk))
			elif w == "steamgun" and atk > 0.5:
				ci.draw_circle(tip, 5.0, Color(0.9, 0.9, 0.95, 0.6))
			elif atk > 0.6:
				P.muzzle_flash(ci, tip, aim, 8.0, D._flash_strength(atk))
			if w == "flamer":
				ci.draw_line(grip3 + Vector2(-6, 2), Vector2(-14, -30 + y), Color("4a4a4e"), 2.0)
			D.arm(ci, sf, grip3 + dv3 * 6.0, coat)
		"hammer", "greathammer", "spade", "sword", "halberd":
			var swing = lerpf(0.9, -2.2, clampf(atk * 1.4 - 0.2, 0.0, 1.0)) if atk > 0.0 else (-2.0 if wind > 0.0 else -0.4)
			var hand = sf + Vector2.from_angle(swing) * 11.0
			D.arm(ci, sb, sf + Vector2(-2, 9), coat.darkened(0.3))
			var sa = swing - 0.3
			var dv4 = Vector2.from_angle(sa)
			var n4 = dv4.orthogonal()
			var shaft = {"greathammer": 30.0, "halberd": 38.0, "sword": 6.0, "spade": 24.0}.get(w, 24.0)
			P.bar(ci, hand - dv4 * 6.0, sa, shaft + 6.0, 3.0, P.WOOD if w != "sword" else P.LEATHER_D, 1.2)
			var head = hand + dv4 * shaft
			match w:
				"hammer", "greathammer":
					var hs = 8.0 if w == "hammer" else 12.0
					P.poly(ci, P.pts([head - n4 * hs - dv4 * 4, head + n4 * hs - dv4 * 4, head + n4 * hs + dv4 * 5, head - n4 * hs + dv4 * 5]), P.IRON, 1.8)
					P.rivets(ci, head - n4 * (hs - 2), head + n4 * (hs - 2), 2)
				"spade":
					P.poly(ci, P.pts([head - n4 * 5, head + n4 * 5, head + n4 * 4 + dv4 * 9, head + dv4 * 12, head - n4 * 4 + dv4 * 9]), P.STEEL, 1.5)
				"sword":
					P.bar(ci, hand, sa, 26, 3.5, P.STEEL, 1.2)
					ci.draw_line(hand - n4 * 5, hand + n4 * 5, P.BRASS, 2.5)
				"halberd":
					P.poly(ci, P.pts([head - dv4 * 6 - n4 * 2, head + n4 * 9, head + dv4 * 6 + n4 * 4, head + dv4 * 10]), P.STEEL, 1.5)
			D.arm(ci, sf, hand, coat)
		"satchel", "grenade", "mortar_tube", "crate":
			var throw = clampf(atk, 0.0, 1.0)
			var ang5 = lerpf(-0.3, -2.4, throw) if w != "mortar_tube" else -0.8
			var hand5 = sf + Vector2.from_angle(ang5) * 12.0
			D.arm(ci, sb, sf + Vector2(-2, 9), coat.darkened(0.3))
			match w:
				"mortar_tube":
					P.bar(ci, sf + Vector2(-6, 4), -0.8, 26, 6.0, P.IRON_D, 1.5)
					if atk > 0.6:
						ci.draw_circle(sf + Vector2(-6, 4) + Vector2.from_angle(-0.8) * 26.0, 6.0, Color(0.8, 0.8, 0.8, 0.6))
				"crate":
					P.rrect(ci, Rect2(sf.x - 2, sf.y + 2, 12, 9), P.WOOD, 1.5, 1.0)
				"grenade":
					if throw < 0.6:
						P.circ(ci, hand5, 3.5, P.COAL, 1.2)
						ci.draw_circle(hand5 + Vector2(1, -4), 1.6, Color(1.0, 0.6, 0.2))
				"satchel":
					if throw < 0.6:
						P.rrect(ci, Rect2(hand5.x - 4, hand5.y - 3, 8, 6), P.LEATHER, 1.2, 1.0)
			D.arm(ci, sf, hand5, coat)
		"lance":
			var grip6 = sf + Vector2(2 - recoil * 2.0, 8)
			D.arm(ci, sb, grip6 + Vector2(-2, 1), coat.darkened(0.3))
			var dv6 = Vector2.from_angle(aim)
			P.bar(ci, grip6 - dv6 * 6.0, aim, 40, 5.0, P.IRON_D, 1.5)
			for i in 3:
				ci.draw_circle(grip6 + dv6 * (10.0 + i * 8.0), 2.0, Color(glow.r, glow.g, glow.b, 0.8))
			if atk > 0.6:
				ci.draw_circle(grip6 + dv6 * 36.0, 7.0 * atk, Color(glow.r, glow.g, glow.b, 0.6))
			D.arm(ci, sf, grip6 + dv6 * 12.0, coat)
	if shield != "":
		var sx = 13.0 + sin(clampf(atk2, 0.0, 1.0) * PI) * 2.0
		match shield:
			"tower":
				P.poly(ci, P.pts([Vector2(sx, -44 + y), Vector2(sx + 9, -42 + y), Vector2(sx + 10, -6 + y), Vector2(sx, -4 + y), Vector2(sx - 2, -24 + y)]), s.helm_col, 2.0)
				P.rivets(ci, Vector2(sx + 4, -40 + y), Vector2(sx + 4, -10 + y), 4)
			"rolling":
				P.poly(ci, P.pts([Vector2(sx, -48 + y), Vector2(sx + 12, -46 + y), Vector2(sx + 12, -6), Vector2(sx, -6)]), P.IRON, 2.0)
				P.rect(ci, Rect2(sx + 3, -34 + y, 7, 3), P.COAL, 0.0)
				P.wheel(ci, Vector2(sx + 6, -4), 5.0, P.g(a, "walk", 0.0) * 2.0, P.IRON_D, P.BRASS, 4)
			"bulwark":
				P.poly(ci, P.pts([Vector2(sx - 2, -54 + y), Vector2(sx + 12, -50 + y), Vector2(sx + 14, -4 + y), Vector2(sx - 2, -2 + y), Vector2(sx - 4, -28 + y)]), s.helm_col.darkened(0.1), 2.5)
				P.circ(ci, Vector2(sx + 5, -30 + y), 5.0, P.BRASS, 1.5)
				P.rivets(ci, Vector2(sx + 2, -48 + y), Vector2(sx + 2, -8 + y), 5)


static func _eng(ci: CanvasItem, a, p: Dictionary) -> void:
	var t: float = P.g(a, "t", 0.0)
	var walk: float = P.g(a, "walk", 0.0)
	var rep: float = P.g(a, "special", 0.0)
	var cart = String(p.get("cart", ""))
	var glow = col(p, "glow", "9ad8ff")
	var coat = col(p, "coat", "7a4b2a")
	match cart:
		"wagon", "forge":
			# rolling workshop: two wheels, cargo bed, crane or forge
			P.poly(ci, P.pts([Vector2(-34, -30), Vector2(26, -30), Vector2(30, -14), Vector2(-36, -14)]), P.WOOD, 2.0)
			P.rrect(ci, Rect2(-30, -46, 24, 16), P.WOOD_D if cart == "wagon" else P.COAL, 2.0, 2.0)
			if cart == "forge":
				ci.draw_circle(Vector2(-18, -38), 5.0, Color(1.0, 0.55, 0.2, 0.8 + 0.2 * sin(t * 5.0)))
				P.smoke_puff(ci, Vector2(-22, -50), t, 3)
			else:
				for i in 3:
					P.rrect(ci, Rect2(-28 + i * 7, -44, 6, 6), P.IRON, 1.0, 1.0)
			P.wheel(ci, Vector2(-24, -10), 10.0, walk * 2.0, P.WOOD, P.BRASS, 6)
			P.wheel(ci, Vector2(18, -10), 10.0, walk * 2.0, P.WOOD, P.BRASS, 6)
			P.xf_push(ci, Transform2D(0.0, Vector2(0.85, 0.85), 0.0, Vector2(14, -10)))
			D.body(ci, a, _style(p))
			P.xf_pop(ci)
			_tool(ci, Vector2(28, -38), String(p.get("tool", "wrench")), rep, t, glow)
			return
		"crawler":
			AM.crew(ci, a, Vector2(12, -24), coat, String(p.get("helmet", "great")))
			P.poly(ci, P.pts([Vector2(-40, -18), Vector2(34, -18), Vector2(40, -8), Vector2(34, 0), Vector2(-38, 0), Vector2(-44, -8)]), P.IRON_D, 2.0)
			for i in 6:
				P.circ(ci, Vector2(-34 + i * 13, -6), 5.0, P.IRON, 1.5)
			P.poly(ci, P.pts([Vector2(-34, -44), Vector2(8, -44), Vector2(14, -18), Vector2(-38, -18)]), coat.darkened(0.15), 2.0)
			P.rivets(ci, Vector2(-30, -38), Vector2(4, -38), 4)
			# crane arm
			var crane_a = -0.9 + sin(t * 0.8) * 0.1 - rep * 0.3
			var tip = Vector2(-10, -44) + Vector2.from_angle(crane_a) * 40.0
			P.bar(ci, Vector2(-10, -44), crane_a, 40, 4.0, P.BRASS, 1.2)
			ci.draw_line(tip, tip + Vector2(0, 16), Color(0.3, 0.3, 0.3), 1.5)
			P.circ(ci, tip + Vector2(0, 18), 3.0, P.IRON, 1.0)
			return
		"barrow":
			P.poly(ci, P.pts([Vector2(14, -16), Vector2(34, -16), Vector2(30, -6), Vector2(16, -6)]), P.WOOD, 1.5)
			P.wheel(ci, Vector2(32, -5), 5.0, walk * 3.0, P.WOOD, P.BRASS, 4)
			for i in 2:
				P.rrect(ci, Rect2(17 + i * 7, -22, 6, 6), P.WOOD_D, 1.0, 1.0)
		"balloon":
			var bob = sin(t * 1.2) * 3.0
			ci.draw_line(Vector2(0, -40), Vector2(10, -78 + bob), Color(0.3, 0.3, 0.3), 1.2)
			P.ell(ci, Vector2(12, -94 + bob), 16, 13, P.CLOTH_RED.lightened(0.15), 2.0)
			ci.draw_line(Vector2(-3, -94 + bob), Vector2(27, -94 + bob), P.BRASS, 1.5)
			P.rrect(ci, Rect2(6, -80 + bob, 12, 6), P.WOOD, 1.5, 1.0)
	var b = D.body(ci, a, _style(p))
	_back(ci, String(p.get("back", "")), b.y, t, glow)
	var swing = sin(t * 6.0) * 0.6 * rep - 0.3
	var hand = b.shoulder_f + Vector2.from_angle(swing) * 11.0
	D.arm(ci, b.shoulder_b, b.shoulder_f + Vector2(-2, 9), coat.darkened(0.3))
	_tool(ci, hand, String(p.get("tool", "wrench")), rep, t, glow)
	D.arm(ci, b.shoulder_f, hand, coat)


static func _tool(ci: CanvasItem, hand: Vector2, tool: String, rep: float, t: float, glow: Color) -> void:
	match tool:
		"wrench", "hook":
			P.bar(ci, hand, -0.6, 14, 3.0, P.STEEL, 1.2)
			P.circ(ci, hand + Vector2.from_angle(-0.6) * 15.0, 3.0, P.STEEL, 1.2)
		"hammer":
			P.bar(ci, hand, -0.9, 14, 2.5, P.WOOD, 1.0)
			P.rrect(ci, Rect2(hand.x + 4, hand.y - 16, 10, 6), P.IRON, 1.2, 1.0)
		"welder":
			P.bar(ci, hand, -0.2, 12, 3.0, P.BRASS, 1.0)
			if rep > 0.0 or fmod(t, 1.4) < 0.5:
				ci.draw_circle(hand + Vector2(12, -2), 3.0, Color(0.7, 0.9, 1.0, 0.9))
		"rune":
			P.circ(ci, hand + Vector2(4, -4), 4.0, P.BRASS, 1.2)
			ci.draw_circle(hand + Vector2(4, -4), 2.2, Color(glow.r, glow.g, glow.b, 0.7 + 0.3 * sin(t * 5.0)))
		"scope":
			P.bar(ci, hand + Vector2(-2, -6), -0.2, 14, 3.5, P.BRASS, 1.2)
		"gauge":
			P.circ(ci, hand + Vector2(4, -4), 5.0, P.BRASS, 1.2)
			ci.draw_circle(hand + Vector2(4, -4), 3.5, Color("efe6cf"))
			ci.draw_line(hand + Vector2(4, -4), hand + Vector2(4, -4) + Vector2.from_angle(-2.0 + sin(t * 2.0)) * 3.0, Color(0.7, 0.1, 0.1), 1.0)
		"mine":
			P.ell(ci, hand + Vector2(4, 0), 6, 3, P.IRON_D, 1.2)
			ci.draw_circle(hand + Vector2(4, -3), 1.5, Color(1.0, 0.3, 0.2))
		"crane":
			P.bar(ci, hand, -1.0, 18, 3.0, P.BRASS, 1.0)
		"crate":
			P.rrect(ci, Rect2(hand.x - 2, hand.y - 3, 10, 8), P.WOOD, 1.2, 1.0)


# ================================================================== artillery
static func _gun(ci: CanvasItem, a, p: Dictionary) -> void:
	var t: float = P.g(a, "t", 0.0)
	var atk: float = P.g(a, "atk", 0.0)
	var atk2: float = P.g(a, "atk2", 0.0)
	var barrel = String(p.get("barrel", "mortar"))
	var coat = col(p, "coat", "7a4b2a")
	var glow = col(p, "glow", "9ad8ff")
	var aim: float = P.g(a, "aim0", -0.5 if p.get("aim_up", false) else -0.15)
	var big = barrel in ["howitzer_big", "siege", "array", "flak_heavy", "rocket_big", "piston", "rune"]
	var crew = int(p.get("crew", 1))
	for i in crew:
		AM.crew(ci, a, Vector2(-22 - i * 12, 0), coat, "kettle" if i % 2 == 0 else "cap", sin(t * 2.0 + i) * 0.3 + atk)
	# carriage
	var cw = 34.0 if big else 26.0
	P.poly(ci, P.pts([Vector2(-cw, -6), Vector2(cw * 0.6, -18), Vector2(cw * 0.7, -12), Vector2(-cw + 4, 0)]), P.WOOD_D, 2.0)
	if p.get("boiler", false):
		P.rrect(ci, Rect2(-cw + 2, -30, 12, 22), P.IRON_D, 2.0, 3.0)
		P.smoke_puff(ci, Vector2(-cw + 6, -32), t, 2)
	var pivot = Vector2(2, -22 if not big else -28)
	var rec = atk * atk * 5.0
	var dv = Vector2.from_angle(aim)
	match barrel:
		"mortar", "mortar_big":
			var ma = -0.95
			var len_m = 18.0 if barrel == "mortar" else 24.0
			P.bar(ci, pivot - Vector2.from_angle(ma) * (4.0 + rec * 0.5), ma, len_m, 10.0 if barrel == "mortar" else 13.0, P.IRON_D, 2.0)
			if atk > 0.6:
				ci.draw_circle(pivot + Vector2.from_angle(ma) * len_m, 8.0, Color(0.85, 0.85, 0.85, 0.6))
		"bombard", "culverin", "howitzer", "howitzer_big", "siege", "piston", "rune":
			var ln = {"bombard": 30.0, "culverin": 34.0, "howitzer": 30.0, "howitzer_big": 40.0, "siege": 56.0, "piston": 40.0, "rune": 42.0}[barrel]
			var bw = {"bombard": 12.0, "culverin": 7.0, "howitzer": 10.0, "howitzer_big": 13.0, "siege": 16.0, "piston": 11.0, "rune": 11.0}[barrel]
			var ang = minf(aim, -0.25) if barrel.begins_with("howitzer") else aim
			var dv2 = Vector2.from_angle(ang)
			P.bar(ci, pivot - dv2 * (6.0 + rec), ang, ln, bw, P.BRASS if barrel == "culverin" else P.IRON_D, 2.0)
			if barrel == "piston":
				for i in 2:
					P.bar(ci, pivot + dv2.orthogonal() * (bw * 0.8) - dv2 * 4.0, ang, ln * 0.6 - rec * 2.0, 3.0, P.STEEL, 1.0)
			if barrel == "rune":
				for i in 3:
					ci.draw_circle(pivot + dv2 * (10.0 + i * 10.0), 2.5, Color(glow.r, glow.g, glow.b, 0.8))
			if barrel == "siege":
				P.rivets(ci, pivot + dv2 * 8.0, pivot + dv2 * 40.0, 5)
			P.muzzle_flash(ci, pivot + dv2 * (ln - 6.0 - rec), ang, bw + 6.0, D._flash_strength(atk))
		"rocket_rack", "rocket_big":
			var n = 3 if barrel == "rocket_rack" else 4
			var ra = minf(aim, -0.4)
			for i in n:
				var o = Vector2.from_angle(ra).orthogonal() * (i * 5.0 - n * 2.5)
				P.bar(ci, pivot + o, ra, 26, 4.0, P.IRON_D, 1.2)
				if fmod(t * 3.0 + i, 3.0) > 1.0 or atk < 0.2:
					P.poly(ci, P.pts([pivot + o + Vector2.from_angle(ra) * 24, pivot + o + Vector2.from_angle(ra) * 30 + o.normalized() * 0.1, pivot + o + Vector2.from_angle(ra) * 24 + Vector2.from_angle(ra).orthogonal() * 3]), P.CLOTH_RED, 1.0)
			if atk > 0.6:
				ci.draw_circle(pivot - Vector2.from_angle(ra) * 8.0, 8.0, Color(1, 0.7, 0.3, 0.5))
		"flak2", "flak4", "flak_heavy", "array":
			var fa = minf(aim, -0.35)
			var cnt = {"flak2": 2, "flak4": 4, "flak_heavy": 1, "array": 6}[barrel]
			var fl = 34.0 if barrel == "flak_heavy" else 26.0
			for i in cnt:
				var o2 = Vector2.from_angle(fa).orthogonal() * (i * 4.5 - cnt * 2.2)
				var fire = atk if i % 2 == 0 else atk2
				P.bar(ci, pivot + o2 - Vector2.from_angle(fa) * fire * 3.0, fa, fl, 9.0 if barrel == "flak_heavy" else 3.5, P.IRON_D, 1.2)
				P.muzzle_flash(ci, pivot + o2 + Vector2.from_angle(fa) * fl, fa, 6.0, D._flash_strength(fire))
			if barrel == "array":
				ci.draw_circle(pivot, 5.0, Color(glow.r, glow.g, glow.b, 0.6 + 0.3 * sin(t * 4.0)))
	P.wheel(ci, Vector2(-4, -9), 10.0 if big else 9.0, 0.0, P.WOOD, P.BRASS, 6)
	if big:
		P.wheel(ci, Vector2(-26, -9), 10.0, 0.0, P.WOOD, P.BRASS, 6)


# ================================================================== vehicles
static func _veh(ci: CanvasItem, a, p: Dictionary) -> void:
	# M006b overhaul: shaded hull planes, side skirts, a full running gear (sprocket, idler, road wheels,
	# return rollers, a travelling track), proper turrets with mantlets, a commander in the hatch, firing
	# animation (barrel slide, turret rock, flash, smoke ring, spent case) and damage states.
	# M006c: every kit vehicle with a design in ArtTanks is drawn as its own machine.
	if ArtTanks.has(P.current_art):
		ArtTanks.draw(ci, a, P.current_art, p)
		return
	var t: float = P.g(a, "t", 0.0)
	var walk: float = P.g(a, "walk", 0.0)
	var L = float(p.get("len", 64))
	var H = float(p.get("ht", 44))
	var hull = String(p.get("hull", "tracked"))
	var coat = col(p, "coat", "5d6670")
	var glow = col(p, "glow", "9ad8ff")
	var hl = L * 0.5
	var moving: bool = P.g(a, "state", "") == "move"
	var wc: int = 3 if (hull == "crawler" or L >= 104.0) else (2 if L >= 84.0 else (1 if L >= 64.0 else 0))
	var atk0: float = P.g(a, "atk", 0.0)
	var hp: float = P.g(a, "hp_frac", 1.0)
	# ---- running gear
	var th = 14.0 + wc * 2.0
	if hull == "wheeled":
		th = 12.0
		var wr = 9.5 + wc * 1.5
		var wxs = [-hl * 0.62, hl * 0.58] if L < 64.0 else [-hl * 0.66, -hl * 0.05, hl * 0.6]
		for wx in wxs:
			# leaf spring, then the spoked wheel, then the mudguard over it
			ci.draw_line(Vector2(wx - wr * 0.9, -wr - 4.0), Vector2(wx + wr * 0.9, -wr - 4.0), P.IRON_D, 3.0)
			P.wheel(ci, Vector2(wx, -wr), wr, walk * 2.0, P.COAL, P.BRASS, 6)
			ci.draw_circle(Vector2(wx, -wr), wr * 0.3, P.IRON_D)
			ci.draw_arc(Vector2(wx, -wr), wr + 3.0, PI * 1.08, PI * 1.92, 10, coat.darkened(0.3), 4.0)
		th = wr * 2.0 - 2.0
	elif hull == "crawler":
		_track_unit(ci, -hl - 4.0, -hl * 0.04, th, walk, wc)
		_track_unit(ci, hl * 0.04, hl + 4.0, th, walk, wc)
		P.rrect(ci, Rect2(-hl * 0.12, -th - 2.0, hl * 0.24, th * 0.7), P.IRON_D, 1.5, 2.0)   # articulation joint
	else:
		_track_unit(ci, -hl - 4.0, hl + 4.0, th, walk, wc)
	var base = -th + 2.0
	# ---- hull
	var hh = H * 0.42
	var low = P.pts([Vector2(-hl - 2, base), Vector2(hl + 2, base), Vector2(hl + 10, base - hh * 0.62), Vector2(hl - 2, base - hh), Vector2(-hl + 2, base - hh), Vector2(-hl - 6, base - hh * 0.55)])
	P.poly(ci, low, coat, 2.5)
	# form shading: a lit glacis/top band and a shadowed lower band
	ci.draw_colored_polygon(P.pts([Vector2(-hl + 2, base - hh), Vector2(hl - 2, base - hh), Vector2(hl + 3, base - hh * 0.85), Vector2(-hl, base - hh * 0.85)]), coat.lightened(0.18))
	ci.draw_colored_polygon(P.pts([Vector2(hl - 2, base - hh), Vector2(hl + 10, base - hh * 0.62), Vector2(hl + 7, base - hh * 0.5), Vector2(hl - 3, base - hh * 0.84)]), coat.lightened(0.28))
	ci.draw_colored_polygon(P.pts([Vector2(-hl - 1, base - 1), Vector2(hl + 1, base - 1), Vector2(hl + 4, base - hh * 0.22), Vector2(-hl - 3, base - hh * 0.22)]), coat.darkened(0.22))
	# panel seams and rivets
	var seams = PackedVector2Array()
	var nseam = int(L / 20.0)
	for k in nseam:
		var sx = -hl + (k + 1) * L / float(nseam + 1)
		seams.append_array([Vector2(sx, base - hh * 0.86), Vector2(sx, base - hh * 0.25)])
	ci.draw_multiline(seams, coat.darkened(0.35), 1.2)
	P.rivets(ci, Vector2(-hl + 6, base - hh * 0.78), Vector2(hl - 6, base - hh * 0.78), int(L / 10.0))
	# superstructure / casemate on medium and heavier hulls
	var deck = base - hh
	if wc >= 1:
		var sh = H * (0.16 + wc * 0.025)
		var sup = P.pts([Vector2(-hl + 8, deck), Vector2(hl - 12, deck), Vector2(hl - 22, deck - sh), Vector2(-hl + 12, deck - sh)])
		P.poly(ci, sup, coat.darkened(0.06), 2.0)
		ci.draw_colored_polygon(P.pts([Vector2(-hl + 12, deck - sh), Vector2(hl - 22, deck - sh), Vector2(hl - 20, deck - sh + 3), Vector2(-hl + 11, deck - sh + 3)]), coat.lightened(0.2))
		deck -= sh
	# side skirts over the tracks
	if wc >= 1 and hull != "wheeled":
		var sk = P.pts([Vector2(-hl + th * 0.4, base - 1), Vector2(hl - th * 0.2, base - 1), Vector2(hl - th * 0.35, base + th * 0.5), Vector2(-hl + th * 0.55, base + th * 0.5)])
		P.poly(ci, sk, coat.darkened(0.12), 2.0)
		var ns = 3 + wc
		var sl = PackedVector2Array()
		for k in ns:
			var x = lerpf(-hl + th * 0.5, hl - th * 0.3, float(k + 1) / float(ns + 1))
			sl.append_array([Vector2(x, base), Vector2(x, base + th * 0.48)])
		ci.draw_multiline(sl, coat.darkened(0.38), 1.2)
		P.rivets(ci, Vector2(-hl + th * 0.6, base + 2), Vector2(hl - th * 0.4, base + 2), 4 + wc * 2)
	for i in int(p.get("plates", 0)):
		P.rrect(ci, Rect2(-hl + 6 + i * 16, base - hh * 0.72, 14, 10), coat.darkened(0.25), 1.5, 1.0)
	# front details: vision slit, headlamp, tow hook
	ci.draw_line(Vector2(hl + 2, base - hh * 0.72), Vector2(hl - 3, base - hh * 0.8), P.COAL, 2.5)
	P.circ(ci, Vector2(hl + 4, base - hh * 0.4), 3.2, P.BRASS, 1.2)
	ci.draw_circle(Vector2(hl + 4.5, base - hh * 0.4), 1.8, Color(1.0, 0.92, 0.6))
	ci.draw_arc(Vector2(hl + 8, base - 2), 3.0, -PI * 0.5, PI * 0.6, 6, P.IRON_D, 2.0)
	# rear details: engine grille, stowage, exhaust stacks
	var grille = PackedVector2Array()
	for k in 4:
		grille.append_array([Vector2(-hl + 4 + k * 4, deck - 1), Vector2(-hl + 4 + k * 4, deck + 4)])
	ci.draw_multiline(grille, P.COAL, 1.5)
	if wc >= 1:
		for k in 2 + wc:
			P.rect(ci, Rect2(-hl * 0.55 + k * 9, base - hh * 0.5, 7, 5), P.IRON_D, 1.0)   # spare track links
	else:
		ci.draw_line(Vector2(-hl * 0.4, base - hh * 0.55), Vector2(hl * 0.1, base - hh * 0.6), P.WOOD, 2.0)   # shovel
		P.poly(ci, P.pts([Vector2(hl * 0.1, base - hh * 0.66), Vector2(hl * 0.2, base - hh * 0.6), Vector2(hl * 0.1, base - hh * 0.54)]), P.IRON, 1.0)
	if p.get("ram", false):
		P.poly(ci, P.pts([Vector2(hl + 4, base), Vector2(hl + 20, base - 6), Vector2(hl + 6, deck + 8)]), P.STEEL, 2.0)
		ci.draw_line(Vector2(hl + 6, base - 3), Vector2(hl + 16, base - 6), Color(1, 1, 1, 0.5), 1.5)
	if p.get("hatch", false):
		P.rrect(ci, Rect2(-hl + 8, deck - 6, 14, 6), coat.darkened(0.2), 1.5, 2.0)
	var stacks = 1 if wc < 2 else 2
	for k in stacks:
		var ex = -hl + 6 + k * 8
		ci.draw_line(Vector2(ex, deck), Vector2(ex - 1, deck - 10 - wc), P.IRON_D, 4.0)
		ci.draw_line(Vector2(ex - 3, deck - 10 - wc), Vector2(ex + 2, deck - 10 - wc), P.COAL, 3.0)
		P.smoke_puff(ci, Vector2(ex - 1, deck - 12 - wc), t + k * 0.4, 3 if moving or atk0 > 0.3 else 2,
			Color(0.32, 0.3, 0.3, 0.6) if moving else Color(0.55, 0.53, 0.52, 0.5))
	if moving:
		# thrown-up dirt behind the tracks
		var dk = fposmod(walk, 1.0)
		for i in 3:
			ci.draw_circle(Vector2(-hl - 4 - dk * 8.0 - i * 4.0, -4 - dk * 6.0 - i * 2.0), 2.5 + dk * 2.5, Color(0.5, 0.42, 0.32, 0.45 * (1.0 - dk)))
	# ---- turrets (main first; super-heavies carry a secondary turret toward the rear)
	var turrets: Array = p.get("turrets", [])
	var aims = [P.g(a, "aim0", 0.0), P.g(a, "aim1", 0.0), P.g(a, "aim2", -0.8)]
	var atks = [atk0, P.g(a, "atk2", 0.0), P.g(a, "atk3", 0.0)]
	var antenna_at = Vector2(-hl + 14, deck)
	for i in turrets.size():
		var kind = String(turrets[i])
		var tx2 = hl * 0.06 - i * hl * 0.6
		var tpos = Vector2(tx2, deck + 1)
		var main = i == 0
		_turret2(ci, a, tpos, kind, aims[mini(i, 2)], atks[mini(i, 2)], coat, glow, t, L, main, wc)
		if main:
			antenna_at = tpos + Vector2(-clampf(L * 0.34, 15.0, 48.0) * 0.45, -clampf(L * 0.34, 15.0, 48.0) * 0.5)
	# radio antenna whipping with movement and the shot; a pennant on heavy hulls
	var whip = sin(t * 7.0) * 0.06 + (0.18 if moving else 0.0) + atk0 * 0.25
	var ant_tip = antenna_at + Vector2.from_angle(-PI * 0.5 - 0.35 - whip) * (13.0 + wc * 2.0)
	ci.draw_line(antenna_at, ant_tip, P.COAL, 1.2)
	if wc >= 2:
		var fl = sin(t * 9.0) * 2.0
		P.poly(ci, P.pts([ant_tip, ant_tip + Vector2(-9, 1 + fl), ant_tip + Vector2(-8, 4 + fl), ant_tip + Vector2(0, 5)]), P.CLOTH_RED, 0.8)
	# ---- damage states
	if hp < 0.5:
		ci.draw_circle(Vector2(hl * 0.25, base - hh * 0.6), 4.0, Color(0.1, 0.09, 0.08, 0.55))
		ci.draw_circle(Vector2(-hl * 0.3, base - hh * 0.4), 3.0, Color(0.1, 0.09, 0.08, 0.5))
		P.smoke_puff(ci, Vector2(-hl * 0.55, deck - 4), t * 1.3, 3, Color(0.18, 0.17, 0.17, 0.7))
	if hp < 0.25:
		for k in 3:
			var fx = -hl * 0.5 + k * 7.0
			var fh = 8.0 + sin(t * 17.0 + k * 2.0) * 3.0
			ci.draw_colored_polygon(P.pts([Vector2(fx - 4, deck), Vector2(fx, deck - fh), Vector2(fx + 4, deck)]), Color(1.0, 0.55 + k * 0.1, 0.15, 0.85))


## One track unit: track loop with links travelling (top run backwards, bottom run forwards relative to
## the hull), a toothed drive sprocket at the rear, an idler at the front, road wheels with turning hubs and
## return rollers on top.
static func _track_unit(ci: CanvasItem, x0: float, x1: float, th: float, walk: float, wc: int) -> void:
	var len = x1 - x0
	P.rrect(ci, Rect2(x0, -th, len, th), P.COAL, 2.0, th * 0.5)
	ci.draw_line(Vector2(x0 + th * 0.4, -th + 1.5), Vector2(x1 - th * 0.4, -th + 1.5), Color(0.34, 0.31, 0.3), 1.5)
	# track links: two runs moving in opposite directions
	var ph = fposmod(walk * 3.0, 6.0)
	var links = PackedVector2Array()
	var n = int(len / 6.0)
	for i in n:
		var tx = x0 + fposmod(i * 6.0 - ph, len)
		var bx = x0 + fposmod(i * 6.0 + ph, len)
		if tx > x0 + th * 0.3 and tx < x1 - th * 0.3:
			links.append_array([Vector2(tx, -th - 0.5), Vector2(tx, -th + 2.5)])
		if bx > x0 + th * 0.3 and bx < x1 - th * 0.3:
			links.append_array([Vector2(bx, -2.5), Vector2(bx, 0.5)])
	ci.draw_multiline(links, P.IRON_D, 2.0)
	var r_end = th * 0.42
	var sp = Vector2(x0 + th * 0.5, -th * 0.5)
	var idl = Vector2(x1 - th * 0.5, -th * 0.5)
	# drive sprocket with turning teeth
	P.circ(ci, sp, r_end, P.IRON, 1.5)
	var teeth = PackedVector2Array()
	for k in 8:
		var d = Vector2.from_angle(walk * 2.0 + k * TAU / 8.0)
		teeth.append_array([sp + d * r_end * 0.55, sp + d * (r_end + 1.5)])
	ci.draw_multiline(teeth, P.IRON_D, 2.0)
	ci.draw_circle(sp, r_end * 0.35, P.BRASS)
	P.circ(ci, idl, r_end * 0.9, P.IRON, 1.5)
	ci.draw_circle(idl, r_end * 0.3, P.IRON_D)
	# road wheels with turning hubs
	var nw = maxi(3, int(len / 15.0))
	var hubs = PackedVector2Array()
	for i in nw:
		var wx = lerpf(x0 + th * 1.05, x1 - th * 1.05, float(i) / float(maxi(1, nw - 1)))
		var wcn = Vector2(wx, -th * 0.42)
		P.circ(ci, wcn, th * 0.34, P.IRON, 1.2)
		ci.draw_circle(wcn, th * 0.2, P.IRON_D)
		var hd = Vector2.from_angle(walk * 2.2 + i * 0.9) * th * 0.17
		hubs.append_array([wcn - hd, wcn + hd, wcn - hd.orthogonal(), wcn + hd.orthogonal()])
	ci.draw_multiline(hubs, P.BRASS.darkened(0.25), 1.5)
	# return rollers on the top run
	for i in 1 + wc / 2:
		var rx = lerpf(x0 + len * 0.3, x1 - len * 0.3, float(i) / float(maxi(1, wc / 2)))
		ci.draw_circle(Vector2(rx, -th + 2.5), 2.2, P.IRON_D)


## Turret with mantlet and cupola; the commander rides in the main turret's hatch.
static func _turret2(ci: CanvasItem, a, at: Vector2, kind: String, aim: float, atk: float, coat: Color, glow: Color, t: float, L: float, main: bool, wc: int, shape: String = "box", tw_in: float = 0.0) -> void:
	# M006c: `shape` gives each tank design its own turret form (box, round, tower, tub, flat, casemate, ball)
	var tw = tw_in if tw_in > 0.0 else clampf(L * 0.34, 15.0, 48.0) * (1.0 if main else 0.72)
	if kind == "aa":
		aim = minf(aim, -0.45)
	if kind == "hammer":
		_turret(ci, at, kind, aim, atk, coat, glow, t, L)
		return
	# the shot rocks the turret back about its ring
	var rock = -atk * atk * 0.08
	P.xf_push(ci, Transform2D(rock, at))
	var gun_at = Vector2(tw * 0.48, -tw * 0.28)
	var cpos = Vector2(-tw * 0.2, -tw * 0.56)
	match shape:
		"round":
			P.poly(ci, P.ell_pts(Vector2(0, 0), tw * 0.62, tw * 0.55, 0.0, 12, PI, TAU), coat.darkened(0.04), 2.0)
			ci.draw_colored_polygon(P.ell_pts(Vector2(-tw * 0.08, -tw * 0.2), tw * 0.42, tw * 0.3, 0.0, 10, PI * 1.1, TAU * 0.95), coat.lightened(0.22))
			ci.draw_line(Vector2(-tw * 0.6, -1.5), Vector2(tw * 0.6, -1.5), coat.darkened(0.3), 3.0)
			P.rivets(ci, Vector2(-tw * 0.45, -tw * 0.12), Vector2(tw * 0.45, -tw * 0.12), 5)
			gun_at = Vector2(tw * 0.5, -tw * 0.24)
			cpos = Vector2(-tw * 0.12, -tw * 0.55)
		"tower":
			var tb = P.pts([Vector2(-tw * 0.45, 0), Vector2(tw * 0.45, 0), Vector2(tw * 0.45, -tw * 0.85), Vector2(-tw * 0.45, -tw * 0.85)])
			P.poly(ci, tb, coat.darkened(0.04), 2.0)
			ci.draw_colored_polygon(P.pts([Vector2(-tw * 0.43, -tw * 0.83), Vector2(tw * 0.43, -tw * 0.83), Vector2(tw * 0.43, -tw * 0.7), Vector2(-tw * 0.43, -tw * 0.7)]), coat.lightened(0.2))
			ci.draw_colored_polygon(P.pts([Vector2(-tw * 0.43, -1), Vector2(tw * 0.43, -1), Vector2(tw * 0.43, -tw * 0.18), Vector2(-tw * 0.43, -tw * 0.18)]), coat.darkened(0.25))
			for k in 3:
				P.rect(ci, Rect2(-tw * 0.45 + k * tw * 0.36, -tw * 1.02, tw * 0.2, tw * 0.18), coat.darkened(0.04), 1.5)
			var seam = PackedVector2Array()
			for k in 3:
				seam.append_array([Vector2(-tw * 0.43, -tw * (0.25 + k * 0.2)), Vector2(tw * 0.43, -tw * (0.25 + k * 0.2))])
			ci.draw_multiline(seam, coat.darkened(0.35), 1.0)
			ci.draw_line(Vector2(-tw * 0.15, -tw * 0.62), Vector2(-tw * 0.15, -tw * 0.4), P.COAL, 2.5)   # arrow slit
			gun_at = Vector2(tw * 0.42, -tw * 0.5)
			cpos = Vector2(-tw * 0.05, -tw * 0.86)
		"tub":
			ci.draw_line(Vector2(0, -2), Vector2(0, -tw * 0.42), P.IRON_D, 5.0)   # pedestal
			P.poly(ci, P.pts([Vector2(-tw * 0.62, 0), Vector2(tw * 0.62, 0), Vector2(tw * 0.55, -tw * 0.3), Vector2(-tw * 0.55, -tw * 0.3)]), coat.darkened(0.04), 2.0)
			ci.draw_colored_polygon(P.pts([Vector2(-tw * 0.53, -tw * 0.28), Vector2(tw * 0.53, -tw * 0.28), Vector2(tw * 0.55, -tw * 0.2), Vector2(-tw * 0.55, -tw * 0.2)]), coat.lightened(0.25))
			var rail = PackedVector2Array([Vector2(-tw * 0.55, -tw * 0.3), Vector2(-tw * 0.55, -tw * 0.62), Vector2(tw * 0.3, -tw * 0.3), Vector2(tw * 0.3, -tw * 0.62)])
			ci.draw_multiline(rail, P.IRON_D, 1.5)
			ci.draw_line(Vector2(-tw * 0.55, -tw * 0.62), Vector2(tw * 0.3, -tw * 0.62), P.IRON_D, 1.5)
			gun_at = Vector2(tw * 0.05, -tw * 0.5)
			cpos = Vector2(-tw * 0.35, -tw * 0.34)
		"flat":
			P.poly(ci, P.pts([Vector2(-tw * 0.85, 0), Vector2(tw * 0.62, 0), Vector2(tw * 0.78, -tw * 0.18), Vector2(tw * 0.55, -tw * 0.34), Vector2(-tw * 0.7, -tw * 0.34), Vector2(-tw * 0.9, -tw * 0.16)]), coat.darkened(0.04), 2.0)
			ci.draw_colored_polygon(P.pts([Vector2(-tw * 0.7, -tw * 0.32), Vector2(tw * 0.55, -tw * 0.32), Vector2(tw * 0.66, -tw * 0.24), Vector2(-tw * 0.78, -tw * 0.24)]), coat.lightened(0.22))
			P.rivets(ci, Vector2(-tw * 0.7, -tw * 0.12), Vector2(tw * 0.5, -tw * 0.12), 6)
			gun_at = Vector2(tw * 0.6, -tw * 0.17)
			cpos = Vector2(-tw * 0.35, -tw * 0.34)
		"casemate":
			gun_at = Vector2(2.0, 0.0)
		"ball":
			P.poly(ci, P.pts([Vector2(-tw * 0.55, 0), Vector2(tw * 0.4, 0), Vector2(tw * 0.3, -tw * 0.4), Vector2(-tw * 0.45, -tw * 0.42)]), coat.darkened(0.04), 2.0)
			ci.draw_colored_polygon(P.pts([Vector2(-tw * 0.44, -tw * 0.4), Vector2(tw * 0.29, -tw * 0.38), Vector2(tw * 0.32, -tw * 0.3), Vector2(-tw * 0.48, -tw * 0.32)]), coat.lightened(0.22))
			P.circ(ci, Vector2(tw * 0.42, -tw * 0.22), tw * 0.22, P.COPPER, 1.8)   # ball mantlet
			ci.draw_arc(Vector2(tw * 0.42, -tw * 0.22), tw * 0.15, PI * 1.1, PI * 1.6, 5, Color(1, 1, 1, 0.45), 1.5)
			gun_at = Vector2(tw * 0.5, -tw * 0.22)
			cpos = Vector2(-tw * 0.18, -tw * 0.42)
		_:
			var body = P.pts([Vector2(-tw * 0.62, 0), Vector2(tw * 0.5, 0), Vector2(tw * 0.68, -tw * 0.3), Vector2(tw * 0.32, -tw * 0.56), Vector2(-tw * 0.48, -tw * 0.56), Vector2(-tw * 0.7, -tw * 0.26)])
			if kind in ["mg", "flame", "mortar"] and not main:
				body = P.pts([Vector2(-tw * 0.45, 0), Vector2(tw * 0.45, 0), Vector2(tw * 0.35, -tw * 0.42), Vector2(-tw * 0.35, -tw * 0.42)])
			P.poly(ci, body, coat.darkened(0.04), 2.0)
			ci.draw_colored_polygon(P.pts([Vector2(-tw * 0.48, -tw * 0.56), Vector2(tw * 0.32, -tw * 0.56), Vector2(tw * 0.42, -tw * 0.44), Vector2(-tw * 0.56, -tw * 0.44)]), coat.lightened(0.22))
			ci.draw_colored_polygon(P.pts([Vector2(-tw * 0.6, -1), Vector2(tw * 0.5, -1), Vector2(tw * 0.55, -tw * 0.1), Vector2(-tw * 0.64, -tw * 0.1)]), coat.darkened(0.25))
			P.rivets(ci, Vector2(-tw * 0.45, -tw * 0.2), Vector2(tw * 0.4, -tw * 0.2), 4)
	var dv = Vector2.from_angle(aim)
	var nv = dv.orthogonal()
	var rec = atk * atk * tw * 0.32
	var flash = D._flash_strength(atk)
	match kind:
		"cannon", "heavy", "long", "rail", "twin":
			var ln = {"cannon": tw * 1.35, "heavy": tw * 1.45, "long": tw * 2.05, "rail": tw * 1.95, "twin": tw * 1.35}[kind]
			var bw = {"cannon": 4.5, "heavy": 6.5, "long": 4.0, "rail": 5.0, "twin": 4.0}[kind] * (1.0 + wc * 0.08)
			if kind == "twin":
				for o in [-2.6, 2.6]:
					P.bar(ci, gun_at + nv * o - dv * rec, aim, ln, bw, P.IRON_D, 1.2)
			else:
				P.bar(ci, gun_at - dv * rec, aim, ln, bw, P.IRON_D, 1.5)
				ci.draw_line(gun_at - dv * rec + nv * bw * 0.25, gun_at + dv * (ln - rec) + nv * bw * 0.25, Color(1, 1, 1, 0.18), 1.2)
			var tip = gun_at + dv * (ln - rec)
			if kind in ["heavy", "long"]:
				P.ell(ci, gun_at + dv * (ln * 0.55 - rec), bw * 0.9, bw * 0.75, P.IRON_D, 1.2, aim)   # bore evacuator
			if kind != "rail":
				P.bar(ci, tip - dv * 5.0, aim, 6.0, bw + 3.0, P.IRON_D, 1.2)   # muzzle brake
			else:
				for i in 3:
					ci.draw_circle(gun_at + dv * (ln * (0.3 + i * 0.22) - rec), 2.3, Color(glow.r, glow.g, glow.b, 0.65 + 0.35 * atk))
			P.muzzle_flash(ci, tip, aim, bw + 7.0, flash)
			if atk > 0.15 and atk < 0.75:
				var sk = 1.0 - (atk - 0.15) / 0.6
				var mp = tip + dv * (6.0 + sk * 10.0) + Vector2(0, -sk * 6.0)
				ci.draw_circle(mp, 4.0 + sk * 6.0, Color(0.82, 0.8, 0.78, 0.45 * (1.0 - sk)))
				ci.draw_circle(mp + Vector2(-5, -3), 3.0 + sk * 4.0, Color(0.82, 0.8, 0.78, 0.3 * (1.0 - sk)))
			# the spent case kicked out of the turret's rear hatch
			if atk > 0.45 and atk < 0.9:
				var ck = (0.9 - atk) / 0.45
				var cp = Vector2(-tw * 0.55 - ck * 14.0, -tw * 0.5 - sin(ck * PI) * 12.0)
				P.bar(ci, cp, ck * 7.0, 6.0, 3.0, P.BRASS, 0.8)
		"mg":
			P.bar(ci, gun_at - dv * rec * 0.4, aim, tw * 0.95, 2.6, P.IRON_D, 1.0)
			P.circ(ci, gun_at, 3.0, P.IRON, 1.0)
			P.muzzle_flash(ci, gun_at + dv * tw * 0.95, aim + sin(t * 50.0) * 0.05, 6.0, flash)
		"flame":
			P.bar(ci, gun_at, aim, tw * 0.85, 4.5, P.COPPER, 1.2)
			ci.draw_circle(gun_at + dv * tw * 0.88, 2.2, Color(0.4, 0.75, 1.0, 0.85))   # pilot light
			if atk > 0.05:
				for i in 4:
					var fl = tw * 0.85 + 6.0 + i * 9.0
					ci.draw_circle(gun_at + dv * fl + nv * sin(t * 20.0 + i) * 3.0, 4.0 + i * 3.0, Color(1.0, 0.5 + i * 0.1, 0.15, 0.75 * atk * (1.0 - i * 0.15)))
		"aa":
			for o in [-3.2, 3.2]:
				P.bar(ci, gun_at + nv * o - dv * rec * (1.0 if o < 0.0 else 0.5), aim, tw * 1.3, 3.0, P.IRON_D, 1.0)
			ci.draw_arc(gun_at + dv * tw * 0.5 + nv * -7.0, 4.0, 0, TAU, 10, P.BRASS, 1.2)   # ring sight
			P.muzzle_flash(ci, gun_at + dv * tw * 1.3, aim, 9.0, flash)
		"mortar":
			var ma = -1.05
			P.bar(ci, Vector2(0, -tw * 0.45) - Vector2.from_angle(ma) * atk * 4.0, ma, tw * 0.95, 10.0, P.IRON_D, 1.5)
			if atk > 0.3:
				for i in 3:
					ci.draw_circle(Vector2(0, -tw * 0.45) + Vector2.from_angle(ma) * (tw + i * 8.0) + Vector2(0, -(1.0 - atk) * 14.0), 5.0 + i * 3.0, Color(0.8, 0.8, 0.8, 0.5 * atk))
	# mantlet over the gun root
	if kind in ["cannon", "heavy", "long", "rail", "twin"] and shape != "ball":
		P.rrect(ci, Rect2(gun_at.x - 4.0, gun_at.y - tw * 0.16, 8.0, tw * 0.32), coat.darkened(0.15), 1.5, 2.0)
	# cupola and commander (main turret only): looks about at idle, ducks when the gun fires
	if main and shape != "casemate":
		var duck = clampf(atk * 1.6 - 0.5, 0.0, 1.0)
		var look = sin(t * 1.3) * 1.2
		if duck < 0.9:
			var hc = cpos + Vector2(look, -5.0 + duck * 6.0)
			ci.draw_circle(hc, 3.8, P.OUT)
			ci.draw_circle(hc, 3.0, P.SKIN)
			P.poly(ci, P.pts([hc + Vector2(-2.5, 0.5), hc + Vector2(3.5, 0.5), hc + Vector2(1.5, 6.0), hc + Vector2(-1.0, 5.0)]), P.CLOTH_RED.darkened(0.2) if wc % 2 == 0 else P.WOOD_D, 0.8)
			P.poly(ci, P.pts([hc + Vector2(-3.6, -0.5), hc + Vector2(-3.0, -3.2), hc + Vector2(0, -4.4), hc + Vector2(3.0, -3.2), hc + Vector2(3.6, -0.5)]), P.IRON, 0.8)
			ci.draw_line(hc + Vector2(0.5, -1.0), hc + Vector2(3.2, -1.0), P.BRASS, 1.5)
		if shape != "tub":
			P.rrect(ci, Rect2(cpos.x - 5.0, cpos.y - 2.0, 10.0, 4.0), coat.darkened(0.2), 1.2, 1.5)
			# hatch lid, flipped open behind the commander
			ci.draw_line(cpos + Vector2(-5.0, -1.0), cpos + Vector2(-9.0, -7.0), coat.darkened(0.3), 3.0)
	P.xf_pop(ci)


## Legacy turret painter (M006); still used for the hammer turret.
static func _turret(ci: CanvasItem, at: Vector2, kind: String, aim: float, atk: float, coat: Color, glow: Color, t: float, L: float) -> void:
	var tw = clampf(L * 0.28, 14.0, 34.0)
	if kind == "aa":
		aim = minf(aim, -0.4)
	P.poly(ci, P.ell_pts(at, tw * 0.6, tw * 0.35, 0.0, 12, PI, TAU), coat.darkened(0.08), 2.0)
	var dv = Vector2.from_angle(aim)
	var rec = atk * atk * 4.0
	var gun_at = at + Vector2(tw * 0.3, -tw * 0.15)
	match kind:
		"cannon", "heavy", "long", "rail", "twin":
			var ln = {"cannon": tw * 1.3, "heavy": tw * 1.4, "long": tw * 2.0, "rail": tw * 1.9, "twin": tw * 1.3}[kind]
			var bw = {"cannon": 4.5, "heavy": 6.5, "long": 4.0, "rail": 5.0, "twin": 4.0}[kind]
			if kind == "twin":
				for o in [-2.5, 2.5]:
					P.bar(ci, gun_at + dv.orthogonal() * o - dv * rec, aim, ln, bw, P.IRON_D, 1.2)
			else:
				P.bar(ci, gun_at - dv * rec, aim, ln, bw, P.IRON_D, 1.5)
			if kind == "rail":
				for i in 3:
					ci.draw_circle(gun_at + dv * (ln * (0.3 + i * 0.22)), 2.2, Color(glow.r, glow.g, glow.b, 0.85))
			P.muzzle_flash(ci, gun_at + dv * (ln - rec), aim, bw + 6.0, D._flash_strength(atk))
			if atk > 0.15 and atk < 0.75:
				# M006: a lingering muzzle smoke ring drifting off the barrel after the shot
				var sk = 1.0 - (atk - 0.15) / 0.6
				var mp = gun_at + dv * (ln + 6.0 + sk * 10.0) + Vector2(0, -sk * 6.0)
				ci.draw_circle(mp, 4.0 + sk * 6.0, Color(0.82, 0.8, 0.78, 0.45 * (1.0 - sk)))
				ci.draw_circle(mp + Vector2(-5, -3), 3.0 + sk * 4.0, Color(0.82, 0.8, 0.78, 0.3 * (1.0 - sk)))
		"mg":
			P.bar(ci, gun_at, aim, tw * 0.9, 2.5, P.IRON_D, 1.0)
			P.muzzle_flash(ci, gun_at + dv * tw * 0.9, aim, 6.0, D._flash_strength(atk))
		"flame":
			P.bar(ci, gun_at, aim, tw * 0.8, 4.0, P.COPPER, 1.2)
			if atk > 0.05:
				for i in 3:
					ci.draw_circle(gun_at + dv * (tw * 0.8 + i * 9.0), 4.0 + i * 3.0, Color(1.0, 0.55 + i * 0.1, 0.15, 0.7 * atk))
		"aa":
			for o in [-3.0, 3.0]:
				P.bar(ci, gun_at + dv.orthogonal() * o - dv * rec, aim, tw * 1.2, 3.0, P.IRON_D, 1.0)
		"mortar":
			P.bar(ci, at + Vector2(0, -2), -1.0, tw * 0.9, 9.0, P.IRON_D, 1.5)
			if atk > 0.6:
				ci.draw_circle(at + Vector2.from_angle(-1.0) * tw, 7.0, Color(0.85, 0.85, 0.85, 0.6))
		"hammer":
			var sw = lerpf(-0.3, -1.9, clampf(1.0 - atk, 0.0, 1.0)) if atk > 0.0 else -1.6
			P.bar(ci, at, sw, tw * 1.8, 6.0, P.IRON_D, 1.5)
			var hd = at + Vector2.from_angle(sw) * tw * 1.8
			var n = Vector2.from_angle(sw).orthogonal()
			P.poly(ci, P.pts([hd - n * 12, hd + n * 12, hd + n * 12 + Vector2.from_angle(sw) * 12, hd - n * 12 + Vector2.from_angle(sw) * 12]), P.IRON, 2.0)



## M006b: the legacy Copperback and Brasshound keep their M001 art and gain the kit's damage states.
static func legacy_damage(ci: CanvasItem, art: String, a) -> void:
	var hp: float = P.g(a, "hp_frac", 1.0)
	if hp >= 0.5:
		return
	var t: float = P.g(a, "t", 0.0)
	var top = Vector2(-14.0, -44.0) if art == "copperback" else Vector2(-10.0, -34.0)
	ci.draw_circle(top + Vector2(18.0, 14.0), 4.0, Color(0.1, 0.09, 0.08, 0.55))
	ci.draw_circle(top + Vector2(34.0, 22.0), 3.0, Color(0.1, 0.09, 0.08, 0.5))
	P.smoke_puff(ci, top, t * 1.3, 3, Color(0.18, 0.17, 0.17, 0.7))
	if hp < 0.25:
		for k in 3:
			var fh = 8.0 + sin(t * 17.0 + k * 2.0) * 3.0
			var fx = top.x + 4.0 + k * 7.0
			ci.draw_colored_polygon(P.pts([Vector2(fx - 4, top.y + 10.0), Vector2(fx, top.y + 10.0 - fh), Vector2(fx + 4, top.y + 10.0)]), Color(1.0, 0.55 + k * 0.1, 0.15, 0.85))


# ================================================================== aircraft
static func _air(ci: CanvasItem, a, p: Dictionary) -> void:
	# M006b overhaul: shaded fuselages, glazed cockpits with a goggled pilot and a fluttering scarf, a
	# cowling with exhaust flames, prop and rotor blur discs, ribbed wings (biplane struts on bombers),
	# moving rudders, landing gear, weapons that kick and spit casings, bomb racks that empty, damage.
	var t: float = P.g(a, "t", 0.0)
	var w = TAU / 0.96   # the air pose loop is 0.96 s long, so cyclic motion uses whole multiples of w
	var L = float(p.get("len", 50))
	var hl = L * 0.5
	var frame = String(p.get("frame", "rotary"))
	var coat = col(p, "coat", "a07a2a")
	var glow = col(p, "glow", "9ad8ff")
	var lit = coat.lightened(0.24)
	var dark = coat.darkened(0.3)
	var guns: Array = p.get("guns", [])
	var hp: float = P.g(a, "hp_frac", 1.0)
	var gun_spots: Array = []
	var engine_at = Vector2.ZERO
	var glass = Color(0.6, 0.8, 0.9, 0.82)
	if frame in ["rotary", "twin_rotor", "gunship"]:
		var bh = 9.0 + (4.0 if frame == "gunship" else 0.0) + (1.0 if frame == "twin_rotor" else 0.0)
		var tail = Vector2(-hl * 1.18, -5.0)
		# tail boom with ribs, fin, stabiliser and the tail rotor's blur disc
		P.poly(ci, P.pts([Vector2(-hl * 0.3, -bh * 0.75), tail + Vector2(0, -2.5), tail + Vector2(0, 2.5), Vector2(-hl * 0.3, bh * 0.35)]), dark, 1.5)
		var ribs = PackedVector2Array()
		for k in 3:
			var rx = lerpf(-hl * 0.45, tail.x + 6.0, float(k) / 2.0)
			var hh = lerpf(bh * 0.5, 2.5, float(k) / 2.0)
			ribs.append_array([Vector2(rx, -hh - 2.0), Vector2(rx, hh * 0.6)])
		ci.draw_multiline(ribs, coat.darkened(0.5), 1.2)
		P.poly(ci, P.pts([tail + Vector2(5, -2), tail + Vector2(-1, -14), tail + Vector2(-6, -13), tail + Vector2(-3, -1)]), coat, 1.5)
		P.poly(ci, P.pts([tail + Vector2(7, 1), tail + Vector2(-4, 1), tail + Vector2(-6, 4), tail + Vector2(5, 4)]), dark, 1.2)
		var trc = tail + Vector2(-2, -7)
		ci.draw_circle(trc, 7.5, Color(0.88, 0.88, 0.88, 0.2))
		AA.prop(ci, trc, 7, t)
		# landing skids
		var sk_y = bh + 7.0
		for sx in [-hl * 0.25, hl * 0.35]:
			ci.draw_line(Vector2(sx, bh - 2.0), Vector2(sx - 2.0, sk_y), P.IRON_D, 2.2)
		ci.draw_line(Vector2(-hl * 0.5, sk_y), Vector2(hl * 0.55, sk_y), P.OUT, 4.0)
		ci.draw_line(Vector2(-hl * 0.5, sk_y), Vector2(hl * 0.55, sk_y), P.IRON, 2.2)
		ci.draw_arc(Vector2(hl * 0.55, sk_y - 3.0), 3.0, -PI * 0.5, PI * 0.5, 5, P.IRON, 2.2)
		# the pilot sits behind the glazing
		_pilot(ci, a, Vector2(hl * 0.42, -bh * 0.5), 0.5, Color("a5532a"), t * w, false)
		# pod: base, top-light, belly shadow
		var pod = P.pts([Vector2(-hl * 0.5, -bh + 1.0), Vector2(hl * 0.25, -bh), Vector2(hl * 0.32, -bh * 0.2), Vector2(hl * 0.72, bh * 0.05), Vector2(hl * 0.98, bh * 0.2), Vector2(hl * 0.7, bh), Vector2(-hl * 0.35, bh), Vector2(-hl * 0.6, bh * 0.2)])
		P.poly(ci, pod, coat, 2.0)
		ci.draw_colored_polygon(P.pts([Vector2(-hl * 0.46, -bh + 2.5), Vector2(hl * 0.24, -bh + 1.5), Vector2(hl * 0.25, -bh * 0.55), Vector2(-hl * 0.52, -bh * 0.5)]), lit)
		ci.draw_colored_polygon(P.pts([Vector2(-hl * 0.33, bh - 1.0), Vector2(hl * 0.68, bh - 1.0), Vector2(hl * 0.8, bh * 0.55), Vector2(-hl * 0.5, bh * 0.55)]), dark)
		# glazed canopy over the pilot
		var gl = P.pts([Vector2(hl * 0.25, -bh), Vector2(hl * 0.62, -bh * 0.8), Vector2(hl * 0.95, bh * 0.15), Vector2(hl * 0.32, bh * 0.05)])
		ci.draw_colored_polygon(gl, Color(glass.r, glass.g, glass.b, 0.45))
		ci.draw_polyline(P.pts([Vector2(hl * 0.25, -bh), Vector2(hl * 0.62, -bh * 0.8), Vector2(hl * 0.95, bh * 0.15), Vector2(hl * 0.32, bh * 0.05), Vector2(hl * 0.25, -bh)]), P.OUT, 2.0)
		ci.draw_line(Vector2(hl * 0.48, -bh * 0.88), Vector2(hl * 0.62, -bh * 0.1), P.BRASS_D, 1.5)   # canopy frame
		ci.draw_line(Vector2(hl * 0.58, -bh * 0.65), Vector2(hl * 0.74, -bh * 0.25), Color(1, 1, 1, 0.7), 1.5)   # glint
		ci.draw_line(Vector2(-hl * 0.55, bh * 0.15), Vector2(hl * 0.3, bh * 0.1), P.BRASS, 2.0)
		P.rivets(ci, Vector2(-hl * 0.4, bh * 0.38), Vector2(hl * 0.55, bh * 0.38), int(L / 9.0))
		if frame == "gunship":
			for k in 3:
				var pc = Vector2(-hl * 0.32 + k * 8.0, -bh * 0.25)
				P.circ(ci, pc, 2.6, P.BRASS, 1.0)
				ci.draw_circle(pc, 1.5, Color(1.0, 0.8, 0.4, 0.85))
			# stub wing with a rocket pod
			P.poly(ci, P.pts([Vector2(-hl * 0.2, bh * 0.35), Vector2(hl * 0.25, bh * 0.3), Vector2(hl * 0.2, bh * 0.6), Vector2(-hl * 0.25, bh * 0.65)]), dark, 1.5)
			P.rect(ci, Rect2(-hl * 0.15, bh * 0.6, hl * 0.32, 5.0), P.IRON_D, 1.2)
		# exhaust stack with a flickering flame
		engine_at = Vector2(-hl * 0.38, -bh - 1.0)
		P.rect(ci, Rect2(engine_at.x - 3.0, engine_at.y - 4.0, 6.0, 6.0), P.IRON_D, 1.2)
		var fl = 0.6 + 0.4 * sin(t * w * 3.0)
		ci.draw_circle(engine_at + Vector2(-4.0, -3.0), 2.5 * fl + 1.0, Color(1.0, 0.6, 0.2, 0.75))
		# mast, hub and rotor(s): a translucent blur disc plus the visible blades
		var hubs: Array = [[Vector2(0, -bh - 9.0), hl * 1.2]] if frame != "twin_rotor" else [[Vector2(-hl * 0.42, -bh - 9.0), hl * 0.78], [Vector2(hl * 0.4, -bh - 10.0), hl * 0.78]]
		for hb in hubs:
			var hc: Vector2 = hb[0]
			ci.draw_line(Vector2(hc.x, -bh + 1.0), hc, P.OUT, 5.0)
			ci.draw_line(Vector2(hc.x, -bh + 1.0), hc, P.IRON, 3.0)
			ci.draw_colored_polygon(P.ell_pts(hc, hb[1], 2.6, 0.0, 10), Color(0.85, 0.85, 0.85, 0.22))
			AA.rotor(ci, hc, hb[1], t + hc.x, 28.0)
		gun_spots = [[Vector2(hl * 0.85, bh * 0.55), "aim0"], [Vector2(-hl * 0.1, bh * 0.9 if frame == "gunship" else -bh - 2.0), "aim1"]]
	else:
		var bomber = frame == "bomber"
		var fh = 7.0 + (3.5 if bomber else 0.0)
		var nose = Vector2(hl * 0.92, 0)
		var tailx = -hl
		var rud = sin(t * w) * 2.5
		# far lower wing first (seen slightly from above: its tip peeks out behind the fuselage)
		P.poly(ci, P.pts([Vector2(-hl * 0.18, fh * 0.2), Vector2(hl * 0.42, fh * 0.15), Vector2(hl * 0.36, -fh * 0.5), Vector2(-hl * 0.1, -fh * 0.45)]), dark.darkened(0.15), 1.2)
		# tail: fin with a hinged rudder, stabiliser with elevator
		P.poly(ci, P.pts([Vector2(tailx + 10.0, -3.0), Vector2(tailx + 2.0, -fh - 10.0), Vector2(tailx - 2.0, -fh - 10.0), Vector2(tailx + 1.0, -3.0)]), coat, 1.5)
		P.poly(ci, P.pts([Vector2(tailx - 2.0, -fh - 10.0), Vector2(tailx + 1.0, -3.0), Vector2(tailx - 4.0 + rud, -2.0), Vector2(tailx - 6.0 + rud, -fh - 8.0)]), coat.darkened(0.12), 1.2)
		ci.draw_line(Vector2(tailx + 0.5, -fh - 6.0), Vector2(tailx - 4.0 + rud, -fh - 4.0), P.CLOTH_RED, 3.0)
		# landing gear
		var gx = hl * 0.38
		ci.draw_line(Vector2(gx, fh * 0.6), Vector2(gx - 3.0, fh + 9.0), P.IRON_D, 2.2)
		ci.draw_line(Vector2(gx - 8.0, fh * 0.6), Vector2(gx - 3.0, fh + 9.0), P.IRON_D, 1.8)
		P.wheel(ci, Vector2(gx - 3.0, fh + 9.0), 4.5, t * w, P.COAL, P.BRASS, 4)
		P.circ(ci, Vector2(tailx + 6.0, 3.0), 2.0, P.COAL, 1.0)   # tail wheel
		# pilot in the open cockpit, scarf streaming back
		_pilot(ci, a, Vector2(hl * 0.18, -fh - 3.0), 0.5, Color("8a4a24"), t * w, true)
		# fuselage: tapered body, lit spine, shadowed belly
		var body = P.pts([Vector2(hl * 0.78, -fh), nose + Vector2(0, -fh * 0.65), nose + Vector2(0, fh * 0.65), Vector2(hl * 0.78, fh), Vector2(-hl * 0.3, fh * 0.75), Vector2(tailx, 2.0), Vector2(tailx, -4.0), Vector2(-hl * 0.3, -fh)])
		P.poly(ci, body, coat, 2.0)
		ci.draw_colored_polygon(P.pts([Vector2(-hl * 0.3, -fh + 1.5), Vector2(hl * 0.78, -fh + 1.5), Vector2(hl * 0.78, -fh * 0.45), Vector2(-hl * 0.3, -fh * 0.4), Vector2(tailx + 2.0, -2.5)]), lit)
		ci.draw_colored_polygon(P.pts([Vector2(-hl * 0.3, fh * 0.72), Vector2(hl * 0.78, fh - 1.0), Vector2(hl * 0.78, fh * 0.5), Vector2(-hl * 0.3, fh * 0.35), Vector2(tailx + 2.0, 1.5)]), dark)
		# cockpit rim and windscreen
		P.rect(ci, Rect2(hl * 0.05, -fh - 1.5, hl * 0.32, 3.0), P.LEATHER_D, 1.2)
		ci.draw_colored_polygon(P.pts([Vector2(hl * 0.36, -fh), Vector2(hl * 0.44, -fh - 7.0), Vector2(hl * 0.48, -fh)]), Color(glass.r, glass.g, glass.b, 0.6))
		ci.draw_polyline(P.pts([Vector2(hl * 0.36, -fh), Vector2(hl * 0.44, -fh - 7.0), Vector2(hl * 0.48, -fh)]), P.OUT, 1.5)
		# stabiliser over the tail
		P.poly(ci, P.pts([Vector2(tailx + 14.0, -1.0), Vector2(tailx - 4.0, -2.0), Vector2(tailx - 6.0 + rud * 0.5, 1.5), Vector2(tailx + 12.0, 2.0)]), dark, 1.2)
		# fuselage panel lines, roundel-like brass band, rivets
		var pl = PackedVector2Array()
		for k in 3:
			var px = lerpf(-hl * 0.6, hl * 0.55, float(k) / 2.0)
			pl.append_array([Vector2(px, -fh * 0.7), Vector2(px, fh * 0.6)])
		ci.draw_multiline(pl, coat.darkened(0.45), 1.0)
		P.circ(ci, Vector2(-hl * 0.42, 0), fh * 0.45, P.BRASS, 1.2)
		ci.draw_circle(Vector2(-hl * 0.42, 0), fh * 0.22, P.CLOTH_RED)
		P.rivets(ci, Vector2(-hl * 0.2, fh * 0.45), Vector2(hl * 0.7, fh * 0.45), int(L / 10.0))
		# near lower wing: ribbed, seen a little from above
		var wing = P.pts([Vector2(-hl * 0.2, fh * 0.35), Vector2(hl * 0.45, fh * 0.3), Vector2(hl * 0.5, fh * 0.95), Vector2(-hl * 0.15, fh * 1.1)])
		P.poly(ci, wing, coat.darkened(0.12), 1.8)
		var wr = PackedVector2Array()
		for k in 5:
			var rx = lerpf(-hl * 0.12, hl * 0.4, float(k) / 4.0)
			wr.append_array([Vector2(rx, fh * 0.38), Vector2(rx + 2.0, fh * 0.98)])
		ci.draw_multiline(wr, coat.darkened(0.4), 1.0)
		ci.draw_line(Vector2(-hl * 0.18, fh * 0.4), Vector2(hl * 0.46, fh * 0.35), coat.lightened(0.3), 1.2)
		if bomber:
			# strut-braced upper wing with bracing wires
			var uy = -fh - 12.0
			for sx in [-hl * 0.08, hl * 0.32]:
				ci.draw_line(Vector2(sx, -fh + 1.0), Vector2(sx + 2.0, uy + 2.0), P.WOOD_D, 2.2)
			ci.draw_line(Vector2(-hl * 0.08, -fh + 1.0), Vector2(hl * 0.34, uy + 2.0), Color(0.25, 0.25, 0.25, 0.8), 1.0)
			ci.draw_line(Vector2(hl * 0.32, -fh + 1.0), Vector2(-hl * 0.06, uy + 2.0), Color(0.25, 0.25, 0.25, 0.8), 1.0)
			var uw = P.pts([Vector2(-hl * 0.25, uy), Vector2(hl * 0.5, uy - 1.0), Vector2(hl * 0.55, uy + 4.0), Vector2(-hl * 0.22, uy + 4.5)])
			P.poly(ci, uw, coat.lightened(0.05), 1.8)
			ci.draw_line(Vector2(-hl * 0.23, uy + 0.8), Vector2(hl * 0.5, uy), coat.lightened(0.35), 1.2)
			# wing engine nacelle with its own prop
			var nc = Vector2(hl * 0.4, uy + 9.0)
			P.ell(ci, nc, 8.0, 3.8, P.IRON, 1.5)
			ci.draw_circle(nc + Vector2(9.0, 0), 5.5, Color(0.88, 0.88, 0.88, 0.2))
			AA.prop(ci, nc + Vector2(9.0, 0), 6, t + 0.3)
			# bomb rack under the belly: full, last bomb, empty
			var ammo: int = int(P.g(a, "ammo", 2))
			var rack_y = fh + 1.0
			ci.draw_line(Vector2(-hl * 0.32, rack_y), Vector2(hl * 0.12, rack_y), P.IRON_D, 2.0)
			var nb = 3 if ammo >= 2 else ammo
			for k in 3:
				var bx = -hl * 0.26 + k * hl * 0.16
				ci.draw_line(Vector2(bx, rack_y), Vector2(bx, rack_y + 2.5), P.IRON_D, 1.5)
				if k < nb:
					P.ell(ci, Vector2(bx, rack_y + 5.5), 5.0, 3.0, P.COAL, 1.2)
					ci.draw_line(Vector2(bx - 6.0, rack_y + 5.5), Vector2(bx - 8.0, rack_y + 3.5), P.IRON_D, 1.5)
					ci.draw_line(Vector2(bx - 6.0, rack_y + 5.5), Vector2(bx - 8.0, rack_y + 7.5), P.IRON_D, 1.5)
			if bool(p.get("glow", "") != ""):
				ci.draw_line(Vector2(-hl * 0.32, rack_y + 1.0), Vector2(hl * 0.12, rack_y + 1.0), Color(glow.r, glow.g, glow.b, 0.6), 1.0)
		# cowling, exhaust stubs with flame, and the prop's blur disc
		P.ell(ci, nose + Vector2(-2.0, 0), 4.0, fh * 0.75, P.BRASS, 1.5)
		var stubs = PackedVector2Array()
		var flames = PackedVector2Array()
		for k in 3:
			var ep = Vector2(hl * 0.68, -fh * 0.55 + k * fh * 0.5)
			stubs.append_array([ep + Vector2(-2.0, 0.2), ep + Vector2(3.0, 0.2)])
			var fk = 0.5 + 0.5 * sin(t * w * 3.0 + k * 2.0)
			flames.append_array([ep + Vector2(-2.5, 0.5), ep + Vector2(-4.0 - fk * 3.0, 0.5)])
		ci.draw_multiline(stubs, P.OUT, 3.4)
		ci.draw_multiline(flames, Color(1.0, 0.62, 0.2, 0.75), 2.2)
		engine_at = Vector2(hl * 0.62, -fh * 0.2)
		var pc = nose + Vector2(3.0, 0)
		ci.draw_colored_polygon(P.ell_pts(pc, 3.2, fh + 6.0, 0.0, 10), Color(0.88, 0.88, 0.88, 0.25))
		AA.prop(ci, pc, fh + 5.0, t)
		gun_spots = [[Vector2(hl * 0.7, -fh - 1.0), "aim0"], [Vector2(-hl * 0.15, -fh - 1.0) if not bomber else Vector2(-hl * 0.5, -fh * 0.6), "aim1"]]
	# ---- weapons
	for i in mini(guns.size(), 2):
		var g = String(guns[i])
		var at: Vector2 = gun_spots[i][0]
		var ga: float = P.g(a, String(gun_spots[i][1]), 0.0 if i == 0 else -0.6)
		var gk: float = P.g(a, "atk", 0.0) if i == 0 else P.g(a, "atk2", 0.0)
		_air_gun(ci, at, g, ga, gk, t, w, glow, L)
	if p.get("crane", false):
		var sw = sin(t * w) * 3.0
		P.rect(ci, Rect2(-6.0, 9.0, 12.0, 5.0), P.IRON_D, 1.2)   # winch drum
		ci.draw_line(Vector2(0, 14), Vector2(sw, 26.0), Color(0.3, 0.3, 0.3), 1.2)
		ci.draw_arc(Vector2(sw, 29.0), 3.0, -PI * 0.3, PI * 1.1, 6, P.BRASS, 2.0)
		P.rect(ci, Rect2(sw - 5.0, 32.0, 10.0, 7.0), P.WOOD, 1.2)   # a crate of spare parts on the hook
	if p.get("scope", false):
		P.bar(ci, Vector2(hl * 0.1, -14.0), -0.12, 13.0, 3.5, P.BRASS, 1.0)
		ci.draw_circle(Vector2(hl * 0.1, -14.0) + Vector2.from_angle(-0.12) * 13.0, 1.8, Color(0.6, 0.85, 1.0))
	_machine_damage(ci, hp, engine_at, Vector2(-hl * 0.15, -2.0), t * w, L)


## The pilot: goggled dwarf head (drawn through the transform stack) with a scarf streaming back.
static func _pilot(ci: CanvasItem, a, at: Vector2, sc: float, beard: Color, ph: float, scarf: bool) -> void:
	if scarf:
		var s0 = at + Vector2(-2.0, 5.0)
		var pts = PackedVector2Array([s0 + Vector2(1.0, -1.5)])
		for k in 4:
			pts.append(s0 + Vector2(-4.0 - k * 4.0, sin(ph * 2.0 + k * 1.3) * (0.8 + k * 0.7) - 1.0))
		for k in range(3, -1, -1):
			pts.append(s0 + Vector2(-4.0 - k * 4.0, sin(ph * 2.0 + k * 1.3) * (0.8 + k * 0.7) + 1.8))
		pts.append(s0 + Vector2(1.0, 2.0))
		P.poly(ci, pts, P.CLOTH_RED, 1.2)
	P.xf_push(ci, Transform2D(0.0, Vector2(sc, sc), 0.0, at))
	D.dwarf_head(ci, a, Vector2.ZERO, {"beard": beard, "helmet": "goggle_cap", "helm_col": P.LEATHER})
	P.xf_pop(ci)


static func _air_gun(ci: CanvasItem, at: Vector2, g: String, ang: float, k: float, t: float, w: float, glow: Color, L: float) -> void:
	var dv = Vector2.from_angle(ang)
	var nv = dv.orthogonal()
	var fs = D._flash_strength(k)
	match g:
		"mg":
			var kick = k * k * 2.5
			P.circ(ci, at, 2.8, P.IRON, 1.0)
			P.bar(ci, at - dv * kick, ang, 12.0, 2.6, P.IRON_D, 1.0)
			ci.draw_line(at - dv * kick + dv * 3.0 + nv * 1.6, at - dv * kick + dv * 8.0 + nv * 1.6, P.COAL, 1.0)   # cooling jacket
			P.muzzle_flash(ci, at + dv * (12.0 - kick), ang + sin(t * w * 5.0) * 0.08, 6.0, fs)
			if k > 0.3:
				for c in 2:
					var cp = at + Vector2(-2.0 - c * 3.0, 4.0 + c * 5.0 + (1.0 - k) * 6.0)
					P.bar(ci, cp, 1.3 + c, 3.0, 1.6, P.BRASS, 0.5)
		"cannon":
			var kick2 = k * k * 4.0
			P.rect(ci, Rect2(at.x - 4.0, at.y - 3.0, 8.0, 6.0), P.IRON_D, 1.2)
			P.bar(ci, at - dv * kick2, ang, 17.0, 4.2, P.IRON_D, 1.2)
			P.bar(ci, at + dv * (13.0 - kick2), ang, 4.0, 5.5, P.IRON_D, 1.0)
			P.muzzle_flash(ci, at + dv * (17.0 - kick2), ang, 10.0, fs)
			if k > 0.15 and k < 0.75:
				var sk = 1.0 - (k - 0.15) / 0.6
				ci.draw_circle(at + dv * (20.0 + sk * 6.0) + Vector2(-sk * 8.0, 0), 3.0 + sk * 4.0, Color(0.8, 0.8, 0.78, 0.45 * (1.0 - sk)))
		"flak":
			for o in [-2.2, 2.2]:
				var kk = k * k * (3.0 if o < 0.0 else 1.5)
				P.bar(ci, at + nv * o - dv * kk, ang, 15.0, 2.6, P.IRON_D, 1.0)
			P.circ(ci, at, 3.5, P.STEEL, 1.2)
			P.muzzle_flash(ci, at + dv * 15.0, ang, 8.0, fs)
		"coil":
			P.rect(ci, Rect2(at.x - 5.0, at.y - 3.0, 10.0, 6.0), P.COPPER_D, 1.2)
			for c in 3:
				ci.draw_line(at + Vector2(-3.0 + c * 3.0, -3.0), at + Vector2(-3.0 + c * 3.0, 3.0), P.COPPER, 1.5)
			var tip = at + dv * 9.0
			P.circ(ci, tip, 3.2, P.BRASS, 1.0)
			ci.draw_circle(tip, 2.2 + k * 1.5, Color(glow.r, glow.g, glow.b, 0.55 + 0.45 * k))
			if k > 0.4:
				var arc = PackedVector2Array([tip])
				for s in 4:
					arc.append(tip + dv * (6.0 + s * 6.0) + nv * (3.0 if (s + int(t * 10.0)) % 2 == 0 else -3.0))
				ci.draw_polyline(arc, Color(glow.r, glow.g, glow.b, 0.85 * k), 2.0)
				ci.draw_polyline(arc, Color(1, 1, 1, 0.7 * k), 1.0)
		"flame":
			var fa = 1.1
			var fd = Vector2.from_angle(fa)
			var fat = Vector2(0, 10)
			P.bar(ci, fat, fa, 10.0, 3.6, P.COPPER, 1.0)
			ci.draw_circle(fat + fd * 10.5, 1.8, Color(0.4, 0.75, 1.0, 0.9))   # pilot light
			if k > 0.05:
				for s in 4:
					ci.draw_circle(fat + fd * (14.0 + s * 7.0) + fd.orthogonal() * sin(t * w * 4.0 + s) * 2.0, 3.0 + s * 2.5, Color(1.0, 0.5 + s * 0.1, 0.15, 0.75 * k * (1.0 - s * 0.15)))
		"rockets":
			var ry = 8.0
			ci.draw_line(Vector2(-L * 0.12, ry - 2.0), Vector2(L * 0.12, ry - 2.0), P.IRON_D, 2.0)   # launch rail
			for r in 2:
				var gone = k > 0.3 and r == 0
				var rp = Vector2(-L * 0.1 + r * 9.0, ry + r * 2.0)
				if not gone:
					P.bar(ci, rp, 0.0, 11.0, 3.2, P.CLOTH_RED, 1.0)
					P.poly(ci, P.pts([rp + Vector2(11, -1.6), rp + Vector2(14, 0), rp + Vector2(11, 1.6)]), P.IRON, 0.8)
				else:
					for s in 3:
						ci.draw_circle(rp + Vector2(-4.0 - s * 6.0, 0), 2.5 + s * 1.5, Color(0.8, 0.8, 0.78, 0.5 * k))


## Shared machine damage for aircraft and airships: smoke trail from the engine under 50 %, scorch,
## and fire on top under 25 %.
static func _machine_damage(ci: CanvasItem, hp: float, engine_at: Vector2, hull_at: Vector2, ph: float, L: float) -> void:
	if hp >= 0.5:
		return
	ci.draw_circle(hull_at, 3.5, Color(0.1, 0.09, 0.08, 0.55))
	ci.draw_circle(hull_at + Vector2(L * 0.15, 3.0), 2.5, Color(0.1, 0.09, 0.08, 0.5))
	for k in 4:
		var f = fposmod(ph / TAU + k * 0.25, 1.0)
		ci.draw_circle(engine_at + Vector2(-6.0 - f * 26.0, -2.0 - f * 6.0), 3.0 + f * 6.0, Color(0.18, 0.17, 0.16, 0.6 * (1.0 - f)))
	if hp < 0.25:
		for k in 3:
			var fh = 6.0 + sin(ph * 3.0 + k * 2.0) * 2.5
			var fx = engine_at.x - 2.0 + k * 4.0
			ci.draw_colored_polygon(P.pts([Vector2(fx - 3.0, engine_at.y + 1.0), Vector2(fx - 1.0, engine_at.y - fh), Vector2(fx + 3.0, engine_at.y + 1.0)]), Color(1.0, 0.5 + k * 0.12, 0.15, 0.85))


# ================================================================== airships
static func _ship(ci: CanvasItem, a, p: Dictionary) -> void:
	# M006b overhaul: a shaded envelope with girders, gore seams and a brass nose cap; a coat-coloured band
	# with the hammer-and-anvil; fins with a moving rudder; rigging; engine pods on outriggers; a keel
	# gondola with lit portholes, a glazed bridge and crew; size- and role-specific fittings.
	var t: float = P.g(a, "t", 0.0)
	var w = TAU / 0.96
	var L = float(p.get("len", 150))
	var hl = L * 0.5
	var coat = col(p, "coat", "5d6670")
	var glow = col(p, "glow", "9ad8ff")
	var ghost = p.get("ghost", false)
	var env = Color("b8a888") if not ghost else Color("8a9a8a")
	var eh = L * 0.2
	var ec = Vector2(0, -eh * 0.6)
	var hp: float = P.g(a, "hp_frac", 1.0)
	var atk: float = P.g(a, "atk", 0.0)
	var atk2: float = P.g(a, "atk2", 0.0)
	var rud = sin(t * w) * 3.0
	# second, smaller envelope above and behind on the largest hulls
	if L >= 230.0:
		var e2 = ec + Vector2(-hl * 0.15, -eh * 0.85)
		P.ell(ci, e2, hl * 0.62, eh * 0.55, env.darkened(0.18), 2.0)
		ci.draw_line(e2 + Vector2(-hl * 0.2, eh * 0.45), ec + Vector2(-hl * 0.2, -eh * 0.8), P.IRON_D, 2.0)
		ci.draw_line(e2 + Vector2(hl * 0.15, eh * 0.45), ec + Vector2(hl * 0.15, -eh * 0.85), P.IRON_D, 2.0)
	# tail fins: upper and lower with hinged rudders, then the horizontal fin
	var fx = -hl * 0.82
	P.poly(ci, P.pts([ec + Vector2(fx + 18.0, -eh * 0.5), ec + Vector2(fx - 12.0, -eh * 1.15), ec + Vector2(fx - 22.0, -eh * 1.1), ec + Vector2(fx - 16.0, -eh * 0.35)]), coat, 1.8)
	P.poly(ci, P.pts([ec + Vector2(fx - 22.0, -eh * 1.1), ec + Vector2(fx - 16.0, -eh * 0.35), ec + Vector2(fx - 24.0 + rud, -eh * 0.3), ec + Vector2(fx - 30.0 + rud, -eh * 1.0)]), coat.darkened(0.15), 1.5)
	P.poly(ci, P.pts([ec + Vector2(fx + 18.0, eh * 0.5), ec + Vector2(fx - 12.0, eh * 1.15), ec + Vector2(fx - 22.0, eh * 1.1), ec + Vector2(fx - 16.0, eh * 0.35)]), coat, 1.8)
	P.poly(ci, P.pts([ec + Vector2(fx - 22.0, eh * 1.1), ec + Vector2(fx - 16.0, eh * 0.35), ec + Vector2(fx - 24.0 + rud, eh * 0.3), ec + Vector2(fx - 30.0 + rud, eh * 1.0)]), coat.darkened(0.15), 1.5)
	# pennant streaming from the upper fin
	var pt = ec + Vector2(fx - 4.0, -eh * 0.8)
	var wv = sin(t * w * 2.0) * 3.0
	ci.draw_line(pt, pt + Vector2(0, -6.0), P.IRON_D, 1.5)
	P.poly(ci, P.pts([pt + Vector2(0, -6.0), pt + Vector2(-18.0, -4.0 + wv), pt + Vector2(-16.0, -1.0 + wv * 0.6), pt + Vector2(0, -1.0)]), P.CLOTH_RED if not ghost else Color("4a5a4a"), 1.0)
	# envelope: body, top light, belly shadow
	P.ell(ci, ec, hl, eh, env, 2.5)
	var top = PackedVector2Array()
	var bot = PackedVector2Array()
	for k in 9:
		var th = PI + PI * float(k) / 8.0
		top.append(ec + Vector2(cos(th) * hl * 0.94, sin(th) * eh * 0.9))
		bot.append(ec + Vector2(cos(th - PI) * hl * 0.96, sin(th - PI) * eh * 0.93))
	for k in range(8, -1, -1):
		var th2 = PI + PI * float(k) / 8.0
		top.append(ec + Vector2(cos(th2) * hl * 0.8, sin(th2) * eh * 0.45 - eh * 0.2))
		bot.append(ec + Vector2(cos(th2 - PI) * hl * 0.85, sin(th2 - PI) * eh * 0.4 + eh * 0.25))
	ci.draw_colored_polygon(top, env.lightened(0.16))
	ci.draw_colored_polygon(bot, env.darkened(0.18))
	# longitudinal girders and gore seams following the envelope's curve
	var gls = PackedVector2Array()
	for gy in [-0.55, 0.2, 0.62]:
		var prev = Vector2.ZERO
		for k in 7:
			var u = -1.0 + 2.0 * float(k) / 6.0
			var q = ec + Vector2(u * hl * 0.97 * sqrt(maxf(0.0, 1.0 - gy * gy)), gy * eh * sqrt(maxf(0.0, 1.0 - u * u * 0.9)))
			if k > 0:
				gls.append_array([prev, q])
			prev = q
	ci.draw_multiline(gls, env.darkened(0.3), 1.5)
	var ns = 4 + int(L / 70.0)
	var seams = PackedVector2Array()
	for i in ns:
		var u2 = -0.85 + 1.7 * float(i) / float(ns - 1)
		var hh = eh * sqrt(maxf(0.0, 1.0 - u2 * u2))
		var top_s = ec + Vector2(u2 * hl, -hh * 0.97)
		var mid_s = ec + Vector2(u2 * hl + 4.0 * signf(u2), 0)
		var bot_s = ec + Vector2(u2 * hl, hh * 0.97)
		seams.append_array([top_s, mid_s, mid_s, bot_s])
	ci.draw_multiline(seams, Color(env.r * 0.62, env.g * 0.58, env.b * 0.5, 0.75), 1.5)
	# nose cap
	P.poly(ci, P.ell_pts(ec + Vector2(hl * 0.92, 0), hl * 0.1, eh * 0.45), P.BRASS, 1.5)
	P.rivets(ci, ec + Vector2(hl * 0.88, -eh * 0.25), ec + Vector2(hl * 0.88, eh * 0.25), 3)
	# coat band with the hammer-and-anvil emblem
	var bx = -hl * 0.35
	var bh2 = eh * sqrt(1.0 - 0.35 * 0.35)
	ci.draw_colored_polygon(P.pts([ec + Vector2(bx - 9.0, -bh2 * 0.97), ec + Vector2(bx + 9.0, -bh2 * 0.97), ec + Vector2(bx + 13.0, 0), ec + Vector2(bx + 9.0, bh2 * 0.97), ec + Vector2(bx - 9.0, bh2 * 0.97), ec + Vector2(bx - 5.0, 0)]), coat)
	if not p.get("cargo", false):
		var em = ec + Vector2(bx + 3.0, 0)
		var er = minf(eh * 0.38, 15.0)
		P.circ(ci, em, er, coat.darkened(0.25) if not ghost else Color("3a4a3a"), 1.5)
		ci.draw_arc(em, er - 2.0, 0, TAU, 16, P.BRASS, 1.5)
		var s = er / 12.0
		P.poly(ci, P.pts([em + Vector2(-7, 2) * s, em + Vector2(7, 2) * s, em + Vector2(4, 5) * s, em + Vector2(2, 5) * s, em + Vector2(3, 8) * s, em + Vector2(-3, 8) * s, em + Vector2(-2, 5) * s, em + Vector2(-5, 5) * s]), P.BRASS, 1.0)
		ci.draw_line(em + Vector2(-4, -8) * s, em + Vector2(3, 0) * s, P.WOOD, 2.0 * s + 0.5)
		P.rect(ci, Rect2(em + Vector2(-8, -10) * s, Vector2(8, 4) * s), P.IRON, 1.0)
	# rigging down to the gondola
	var gy = eh * 0.45
	var gl2 = hl * (0.55 if L < 200.0 else 0.62)
	var rig = PackedVector2Array()
	for k in 5:
		var rx = lerpf(-gl2 * 0.9, gl2 * 0.9, float(k) / 4.0)
		var ry = ec.y + eh * sqrt(maxf(0.0, 1.0 - (rx / hl) * (rx / hl))) - 2.0
		rig.append_array([Vector2(rx, ry), Vector2(rx * 0.85, gy + 2.0)])
	ci.draw_multiline(rig, Color(0.25, 0.22, 0.18, 0.85), 1.2)
	# keel gondola
	var gb = gy + eh * 0.6
	var gond = P.pts([Vector2(-gl2, gy), Vector2(gl2, gy), Vector2(gl2 + 12.0, gy + 10.0), Vector2(gl2 * 0.75, gb), Vector2(-gl2 * 0.8, gb), Vector2(-gl2 - 10.0, gy + 8.0)])
	P.poly(ci, gond, coat, 2.5)
	ci.draw_colored_polygon(P.pts([Vector2(-gl2 + 2.0, gy + 2.0), Vector2(gl2 - 2.0, gy + 2.0), Vector2(gl2 + 4.0, gy + 6.0), Vector2(-gl2 - 4.0, gy + 6.0)]), coat.lightened(0.2))
	ci.draw_colored_polygon(P.pts([Vector2(-gl2 * 0.8, gb - 1.0), Vector2(gl2 * 0.75, gb - 1.0), Vector2(gl2 * 0.85, gb - eh * 0.18), Vector2(-gl2 * 0.9, gb - eh * 0.18)]), coat.darkened(0.25))
	# engine pods on outriggers (pusher props facing aft)
	var pods: Array = [-0.5, 0.5] if L < 165.0 else ([-0.6, 0.05, 0.6] if L < 225.0 else [-0.68, -0.22, 0.25, 0.68])
	for k in pods.size():
		var px = hl * float(pods[k])
		var pc = Vector2(px + (8.0 if px < 0.0 else -4.0), gy + 4.0 + (k % 2) * 4.0)
		ci.draw_line(Vector2(px * 0.8, gy + 2.0), pc + Vector2(0, -4.0), P.IRON_D, 3.0)
		P.ell(ci, pc, 11.0, 5.0, coat.darkened(0.1), 1.5)
		ci.draw_line(pc + Vector2(-8.0, -2.5), pc + Vector2(8.0, -2.5), coat.lightened(0.25), 1.2)
		ci.draw_colored_polygon(P.ell_pts(pc + Vector2(-13.0, 0), 3.0, 11.0, 0.0, 8), Color(0.88, 0.88, 0.88, 0.22))
		AA.prop(ci, pc + Vector2(-13.0, 0), 10, t + px)
		var fk = 0.5 + 0.5 * sin(t * w * 3.0 + k)
		ci.draw_circle(pc + Vector2(-8.0, 3.5), 1.5 + fk, Color(1.0, 0.6, 0.2, 0.7))
	# railings along the gondola roof
	ci.draw_line(Vector2(-gl2, gy - 5.0), Vector2(gl2 - 8.0, gy - 5.0), P.IRON_D, 1.2)
	var posts = PackedVector2Array()
	for k in int(gl2 / 10.0) * 2:
		var rx2 = -gl2 + 4.0 + k * 10.0
		posts.append_array([Vector2(rx2, gy - 5.0), Vector2(rx2, gy)])
	ci.draw_multiline(posts, P.IRON_D, 1.0)
	P.rivets(ci, Vector2(-gl2 + 6.0, gy + 9.0), Vector2(gl2 - 6.0, gy + 9.0), int(L / 18.0))
	# portholes with warm light (a slow flicker)
	var nport = int(L / 34.0)
	var rims = PackedVector2Array()
	var lights = PackedVector2Array()
	for i in nport:
		var pp = Vector2(lerpf(-gl2 * 0.65, gl2 * 0.35, float(i) / float(maxi(1, nport - 1))), gy + eh * 0.3)
		rims.append_array([pp + Vector2(-3.4, 0), pp + Vector2(3.4, 0)])
		lights.append_array([pp + Vector2(-2.0, 0), pp + Vector2(2.0, 0)])
	ci.draw_multiline(rims, P.OUT, 8.2)
	ci.draw_multiline(rims, P.BRASS, 6.2)
	ci.draw_multiline(lights, Color(1.0, 0.78 + 0.1 * sin(t * w), 0.4, 0.95), 4.0)
	# glazed bridge at the bow with two crew heads
	var br = Vector2(gl2 - 4.0, gy + 3.0)
	for c in 2:
		var hc = br + Vector2(-14.0 + c * 9.0, 4.0)
		ci.draw_circle(hc, 3.6, P.OUT)
		ci.draw_circle(hc, 2.8, P.SKIN)
		P.poly(ci, P.pts([hc + Vector2(-2, 1), hc + Vector2(3, 1), hc + Vector2(1, 6), hc + Vector2(-1, 5)]), Color("8a4a24") if c == 0 else Color("c8c0b0"), 0.6)
		P.poly(ci, P.pts([hc + Vector2(-3.4, -0.5), hc + Vector2(0, -4.2), hc + Vector2(3.4, -0.5)]), P.LEATHER, 0.6)
	ci.draw_colored_polygon(P.pts([br + Vector2(-20.0, 0), br + Vector2(8.0, 0), br + Vector2(15.0, 8.0), br + Vector2(-20.0, 10.0)]), Color(0.6, 0.8, 0.9, 0.4))
	ci.draw_polyline(P.pts([br + Vector2(-20.0, 0), br + Vector2(8.0, 0), br + Vector2(15.0, 8.0), br + Vector2(-20.0, 10.0), br + Vector2(-20.0, 0)]), P.OUT, 1.5)
	ci.draw_line(br + Vector2(-6.0, 0), br + Vector2(-6.0, 10.0), P.BRASS_D, 1.2)
	ci.draw_line(br + Vector2(0, 1.5), br + Vector2(8.0, 6.0), Color(1, 1, 1, 0.6), 1.2)
	# role fittings
	if p.get("deck", false):
		var dk = Rect2(-gl2 - 6.0, gy - 7.0, gl2 * 1.5, 4.0)
		P.rect(ci, dk, P.WOOD, 1.5)
		var dl = PackedVector2Array()
		for k in int(dk.size.x / 12.0):
			dl.append_array([Vector2(dk.position.x + 6.0 + k * 12.0, dk.position.y + 2.0), Vector2(dk.position.x + 11.0 + k * 12.0, dk.position.y + 2.0)])
		ci.draw_multiline(dl, Color(1.0, 0.95, 0.7, 0.8), 1.0)
		# a parked gyro on the deck, rotor idling
		var gp = Vector2(dk.position.x + dk.size.x * 0.3, dk.position.y)
		P.ell(ci, gp + Vector2(0, -5.0), 9.0, 4.5, P.BRASS_D, 1.2)
		ci.draw_line(gp + Vector2(0, -9.0), gp + Vector2(0, -13.0), P.IRON, 2.0)
		var rk = absf(cos(t * w))
		ci.draw_line(gp + Vector2(-12.0 * rk, -13.0), gp + Vector2(12.0 * rk, -13.0), P.WOOD_D, 2.0)
	if p.get("hammer", false):
		var hy = gb + 6.0 + atk * atk * 30.0
		P.rect(ci, Rect2(-7.0, gb - 6.0, 14.0, 10.0), P.IRON_D, 1.5)
		ci.draw_line(Vector2(0, gb), Vector2(0, hy), P.OUT, 8.0)
		ci.draw_line(Vector2(0, gb), Vector2(0, hy), P.STEEL, 5.0)
		P.rect(ci, Rect2(-18.0, hy, 36.0, 20.0), P.IRON, 2.0)
		ci.draw_line(Vector2(-16.0, hy + 3.0), Vector2(16.0, hy + 3.0), Color(1, 1, 1, 0.35), 2.0)
		P.rivets(ci, Vector2(-12.0, hy + 14.0), Vector2(12.0, hy + 14.0), 3)
		if atk > 0.6:
			ci.draw_arc(Vector2(0, hy + 22.0), 14.0 + (1.0 - atk) * 30.0, 0.2, PI - 0.2, 10, Color(1.0, 0.9, 0.6, atk - 0.4), 3.0)
	if p.get("coils", false):
		for i in 3:
			var cp = Vector2(-gl2 * 0.5 + i * gl2 * 0.5, gy - 8.0)
			P.rect(ci, Rect2(cp.x - 4.0, cp.y - 2.0, 8.0, 10.0), P.COPPER_D, 1.2)
			for r in 3:
				ci.draw_line(cp + Vector2(-4.0, r * 3.0), cp + Vector2(4.0, r * 3.0), P.COPPER, 1.5)
			var orb = cp + Vector2(0, -5.0)
			var pul = 0.6 + 0.4 * sin(t * w * 2.0 + i * 2.0)
			ci.draw_circle(orb, 4.5, P.OUT)
			ci.draw_circle(orb, 3.5, Color(glow.r, glow.g, glow.b, 0.5 + 0.5 * pul))
			if i < 2 and (atk > 0.3 or pul > 0.9):
				var nx = Vector2(-gl2 * 0.5 + (i + 1) * gl2 * 0.5, gy - 13.0)
				var arc = PackedVector2Array([orb])
				for s in 3:
					arc.append(orb.lerp(nx, (s + 1) / 4.0) + Vector2(0, -4.0 if (s + i) % 2 == 0 else 3.0))
				arc.append(nx)
				ci.draw_polyline(arc, Color(glow.r, glow.g, glow.b, 0.8), 1.5)
	if p.get("bombs", false):
		var bdx = -gl2 * 0.2
		var open = clampf(atk * 1.5, 0.0, 1.0)
		ci.draw_line(Vector2(bdx - 12.0, gb), Vector2(bdx - 12.0 - open * 4.0, gb + open * 9.0), P.IRON_D, 2.5)
		ci.draw_line(Vector2(bdx + 12.0, gb), Vector2(bdx + 12.0 + open * 4.0, gb + open * 9.0), P.IRON_D, 2.5)
		if atk > 0.3:
			P.ell(ci, Vector2(bdx, gb + 6.0 + (1.0 - atk) * 22.0), 4.0, 6.5, P.COAL, 1.2)
	# broadside guns along the gondola: recoil, flash, a smoke cloud rolling off the side
	var ng = int(p.get("guns", 1))
	for i in ng:
		var gp2 = Vector2(gl2 * 0.45 - i * gl2 * 0.45, gb - eh * 0.12)
		var ga: float = P.g(a, "aim0", 0.8) if i % 2 == 0 else P.g(a, "aim1", 0.8)
		var gk = atk if i % 2 == 0 else atk2
		var dv = Vector2.from_angle(ga)
		var kick = gk * gk * 5.0
		P.circ(ci, gp2, 5.0, coat.darkened(0.3), 1.5)
		P.bar(ci, gp2 - dv * kick, ga, 16.0, 4.5, P.IRON_D, 1.2)
		P.bar(ci, gp2 + dv * (12.0 - kick), ga, 4.0, 6.0, P.IRON_D, 1.0)
		P.muzzle_flash(ci, gp2 + dv * (16.0 - kick), ga, 10.0, D._flash_strength(gk))
		if gk > 0.15 and gk < 0.8:
			var sk = 1.0 - (gk - 0.15) / 0.65
			for s in 2:
				ci.draw_circle(gp2 + dv * (20.0 + sk * 10.0 + s * 6.0) + Vector2(-sk * 10.0, -s * 4.0), 4.0 + sk * 5.0, Color(0.82, 0.8, 0.78, 0.45 * (1.0 - sk)))
	if p.get("flak", false):
		var fp = ec + Vector2(hl * 0.1, -eh * 0.98)
		P.rect(ci, Rect2(fp.x - 9.0, fp.y - 3.0, 18.0, 5.0), P.IRON_D, 1.2)
		var fa = -1.15
		for o in [-2.5, 2.5]:
			var kk = atk * atk * (4.0 if o < 0.0 else 2.0)
			P.bar(ci, fp + Vector2(0, -3.0) + Vector2.from_angle(fa).orthogonal() * o - Vector2.from_angle(fa) * kk, fa, 16.0, 3.0, P.IRON_D, 1.0)
		P.muzzle_flash(ci, fp + Vector2(0, -3.0) + Vector2.from_angle(fa) * 16.0, fa, 9.0, D._flash_strength(atk))
	if p.get("cargo", false):
		# M006 supply barge: crates slung in a net under the gondola, a long dwarven pennant aft
		var cy = gy + eh * 0.62
		for i in 3:
			var cx = -hl * 0.28 + i * hl * 0.28
			ci.draw_line(Vector2(cx - 8, gy + eh * 0.5), Vector2(cx - 10, cy + 4), Color(0.35, 0.3, 0.22), 1.5)
			ci.draw_line(Vector2(cx + 8, gy + eh * 0.5), Vector2(cx + 10, cy + 4), Color(0.35, 0.3, 0.22), 1.5)
			P.rect(ci, Rect2(cx - 11, cy + 4, 22, 16), P.WOOD, 1.5)
			ci.draw_line(Vector2(cx - 11, cy + 12), Vector2(cx + 11, cy + 12), Color(0.3, 0.22, 0.12), 1.5)
			P.rivets(ci, Vector2(cx - 7, cy + 7), Vector2(cx + 7, cy + 7), 2)
		P.circ(ci, ec, eh * 0.35, Color("d8b04a"), 1.5)
		P.poly(ci, P.pts([ec + Vector2(-6, 4), ec + Vector2(0, -7), ec + Vector2(6, 4)]), Color("6e4a20"), 1.0)
	# damage: patched holes and a leaking engine under half, burning envelope under a quarter
	if hp < 0.5:
		for k in 3:
			var hpos = ec + Vector2(-hl * 0.5 + k * hl * 0.45, -eh * 0.3 + (k % 2) * eh * 0.5)
			P.rect(ci, Rect2(hpos.x - 5.0, hpos.y - 4.0, 10.0, 8.0), env.darkened(0.3), 1.2)
			ci.draw_line(hpos + Vector2(-4, -3), hpos + Vector2(4, 3), env.darkened(0.5), 1.0)
	_machine_damage(ci, hp, Vector2(hl * float(pods[0]) + 8.0, gy + 4.0), Vector2(-gl2 * 0.4, gy + 10.0), t * w, L)
	if hp < 0.25:
		var fp2 = ec + Vector2(hl * 0.25, -eh * 0.8)
		for k in 4:
			var fh2 = 9.0 + sin(t * w * 3.0 + k * 1.7) * 4.0
			ci.draw_colored_polygon(P.pts([fp2 + Vector2(k * 6.0 - 4.0, 2.0), fp2 + Vector2(k * 6.0, -fh2), fp2 + Vector2(k * 6.0 + 4.0, 2.0)]), Color(1.0, 0.5 + k * 0.1, 0.15, 0.85))


# ================================================================== props
static func _prop(ci: CanvasItem, a, p: Dictionary) -> void:
	var t: float = P.g(a, "t", 0.0)
	var atk: float = P.g(a, "atk", 0.0)
	match String(p.get("kind", "")):
		"barricade":
			for i in 3:
				P.bar(ci, Vector2(-16 + i * 8, 0), -1.25 + i * 0.2, 40, 6.0, P.WOOD, 1.5)
			P.rect(ci, Rect2(-18, -24, 36, 6), P.IRON_D, 1.5)
			P.rivets(ci, Vector2(-14, -21), Vector2(14, -21), 4)
		"gun_turret", "gatling_turret":
			P.poly(ci, P.pts([Vector2(-14, 0), Vector2(14, 0), Vector2(10, -18), Vector2(-10, -18)]), P.IRON_D, 2.0)
			P.circ(ci, Vector2(0, -24), 9.0, P.IRON, 2.0)
			var aim: float = P.g(a, "aim0", 0.0)
			if p.kind == "gatling_turret":
				var sp = P.g(a, "spin", t)
				for i in 3:
					P.bar(ci, Vector2(4, -26) + Vector2(0, sin(sp * 6.0 + i * 2.1) * 2.0), aim, 18, 2.0, P.IRON_D, 1.0)
			else:
				P.bar(ci, Vector2(4, -26), aim, 20, 3.0, P.IRON_D, 1.2)
			P.muzzle_flash(ci, Vector2(4, -26) + Vector2.from_angle(aim) * 20.0, aim, 7.0, D._flash_strength(atk))
			P.rivets(ci, Vector2(-8, -8), Vector2(8, -8), 3)
		"rift_tear":
			# M008: the torn edges of a rift: two jagged shards of black glass framing the portal (the portal's
			# light and swirl are drawn by the hazard layer under the units), with violet cracks along them
			var hp: float = P.g(a, "hp_frac", 1.0)
			for sgn in [-1.0, 1.0]:
				var sh = P.pts([Vector2(sgn * 8, 0), Vector2(sgn * 26, -22), Vector2(sgn * 18, -48), Vector2(sgn * 30, -74), Vector2(sgn * 14, -96), Vector2(sgn * 6, -70), Vector2(sgn * 14, -44)])
				P.poly(ci, sh, Color("140a1c"), 2.0)
				ci.draw_polyline(P.pts([Vector2(sgn * 12, -8), Vector2(sgn * 20, -30), Vector2(sgn * 16, -50), Vector2(sgn * 22, -72)]), Color(0.85, 0.6, 1.0, 0.5 + 0.5 * hp), 1.5)
			for k in 3:
				ci.draw_circle(Vector2(0, -20 - k * 26), 3.0 - k * 0.6, Color(0.95, 0.85, 1.0, 0.9))
		"soul_wisp":
			# M008: a soul torn out by the rift — a pale green-white flame with a hollow, wailing face
			var fl = sin(t * 7.0) * 2.0
			P.poly(ci, P.pts([Vector2(-10, 4), Vector2(-12, -6), Vector2(-6, -16 + fl), Vector2(0, -24 - fl), Vector2(6, -14), Vector2(13, -6), Vector2(10, 4), Vector2(0, 8)]), Color(0.72, 1.0, 0.88, 0.85), 1.5)
			P.poly(ci, P.pts([Vector2(-6, 2), Vector2(-7, -6), Vector2(0, -14), Vector2(6, -6), Vector2(6, 2), Vector2(0, 5)]), Color(0.92, 1.0, 0.96), 0.0)
			ci.draw_circle(Vector2(-3, -5), 1.8, Color(0.1, 0.2, 0.18))
			ci.draw_circle(Vector2(3, -5), 1.8, Color(0.1, 0.2, 0.18))
			P.ell(ci, Vector2(0, 0), 1.8, 2.8, Color(0.1, 0.2, 0.18), 0.0)


# ================================================================== undead humanoids
static func _uweapon(ci: CanvasItem, hand: Vector2, ang: float, kind: String, atk: float, t: float, glow: Color) -> void:
	var dv = Vector2.from_angle(ang)
	var n = dv.orthogonal()
	match kind:
		"sword", "greatsword", "gladius":
			var ln = 26.0 if kind == "greatsword" else 18.0
			P.bar(ci, hand, ang, ln, 3.0 if kind != "greatsword" else 4.5, P.RUST, 1.2)
			ci.draw_line(hand - n * 4, hand + n * 4, P.BONE_D, 2.0)
		"axe", "greataxe", "cleaver":
			var ln2 = 24.0 if kind == "greataxe" else 16.0
			P.bar(ci, hand - dv * 4.0, ang, ln2, 2.5, P.WOOD_D, 1.0)
			var hd = hand + dv * (ln2 - 4.0)
			var s = 9.0 if kind == "greataxe" else 6.0
			P.poly(ci, P.pts([hd - n * 1, hd + n * s + dv * 3, hd + n * s - dv * 6, hd - dv * 2]), P.RUST if kind != "cleaver" else Color("8a8e92"), 1.2)
		"pike", "spear", "halberd", "javelin":
			var ln3 = {"pike": 44.0, "spear": 32.0, "halberd": 38.0, "javelin": 28.0}[kind]
			P.bar(ci, hand - dv * 10.0, ang, ln3, 2.2, P.WOOD_D, 1.0)
			var tip = hand + dv * (ln3 - 10.0)
			P.poly(ci, P.pts([tip - n * 2.5, tip + dv * 7.0, tip + n * 2.5]), P.BONE_D if kind == "javelin" else P.RUST, 1.0)
			if kind == "halberd":
				P.poly(ci, P.pts([tip - dv * 2, tip + n * 7, tip + n * 6 - dv * 8]), P.RUST, 1.0)
		"mace":
			P.bar(ci, hand, ang, 16, 2.5, P.WOOD_D, 1.0)
			P.circ(ci, hand + dv * 17.0, 4.5, P.IRON_D, 1.2)
		"bomb":
			P.circ(ci, hand + Vector2(0, -4), 6.0, P.COAL, 1.5)
			ci.draw_line(hand + Vector2(2, -10), hand + Vector2(5, -14), P.LEATHER, 1.5)
			ci.draw_circle(hand + Vector2(5, -15), 2.0, Color(1.0, 0.6 + 0.4 * sin(t * 20.0), 0.2))
		"rifle":
			D.rifle(ci, hand, ang, 28.0, D._flash_strength(atk))
		"sprayer", "darts", "sling":
			P.bar(ci, hand, ang, 12, 3.0, P.BONE_D if kind != "sprayer" else P.COPPER, 1.0)
			if atk > 0.5 and kind == "sprayer":
				ci.draw_circle(hand + dv * 18.0, 6.0, Color(0.6, 0.9, 0.2, 0.6))


static func _zom(ci: CanvasItem, a, p: Dictionary) -> void:
	var t: float = P.g(a, "t", 0.0)
	var atk: float = P.g(a, "atk", 0.0)
	var flesh = col(p, "flesh", "8d9b7a")
	var s = {"flesh": flesh, "cloth": col(p, "cloth", "4b4541")}
	if p.get("bloat", false):
		s["pants"] = Color("3a3a2a")
	var r = AU._zombie(ci, a, s)
	var head: Vector2 = r.head
	var hand: Vector2 = r.hand
	var y: float = r.y
	if p.get("bloat", false):
		P.ell(ci, Vector2(4, -24 + y), 11, 9, flesh.lightened(0.05), 2.0)
		P.circ(ci, Vector2(8, -22 + y), 2.5, P.SICKLY, 1.0)
	if p.get("fungus", false):
		for i in 4:
			var fp = Vector2(-6 + i * 4, -36 + y + (i % 2) * 6)
			P.ell(ci, fp, 4, 2.5, Color("c8b07a"), 1.0)
	if p.get("helmet", false):
		P.poly(ci, P.ell_pts(head + Vector2(0, -3), 8, 7, 0.0, 10, PI, TAU), Color("5a5a52") if not p.get("dwarf", false) else Color("4a5058"), 1.8)
	if p.get("dwarf", false):
		# a fallen dwarf: grey beard, rusted kettle helm
		P.poly(ci, P.pts([head + Vector2(-4, 2), head + Vector2(8, 3), head + Vector2(6, 12), head + Vector2(0, 14)]), Color("8a8a80"), 1.5)
	if p.get("tank", false):
		P.rrect(ci, Rect2(-14, -36 + y, 8, 18), P.COPPER_D, 1.5, 3.0)
	var w = String(p.get("weapon", "claw"))
	if not w in ["claw", "twin_claws", "maw", "fists"]:
		var ang = lerpf(0.5, -1.6, clampf(atk * 1.3, 0.0, 1.0)) if atk > 0.0 else 0.2
		_uweapon(ci, hand, ang, w, atk, t, col(p, "glow", "43ff8c"))
	elif w == "fists":
		P.circ(ci, hand, 6.0, flesh.darkened(0.15), 1.8)
	elif w == "maw":
		P.poly(ci, P.pts([head + Vector2(0, 2), head + Vector2(12, 2 + atk * 4.0), head + Vector2(6, 9 + atk * 4.0)]), Color("2a1414"), 1.2)


static func _skel(ci: CanvasItem, a, p: Dictionary) -> void:
	var t: float = P.g(a, "t", 0.0)
	var atk: float = P.g(a, "atk", 0.0)
	var w = String(p.get("weapon", "sword"))
	var base = "sword"
	if w == "sling" or w == "javelin" or w == "spear":
		base = "bow" if false else "sword"
	# body (the M001 skeleton) with its own weapon replaced by ours
	var bob = AU._legs(ci, a, P.BONE, 0.6, true)
	var y = -bob
	P.poly(ci, P.pts([Vector2(-5, -17 + y), Vector2(5, -17 + y), Vector2(3, -13 + y), Vector2(-3, -13 + y)]), P.BONE_D, 1.5)
	AU._bone(ci, Vector2(0, -16 + y), Vector2(2, -34 + y), 2.5)
	for i in 4:
		var ry = -31.0 + i * 3.6 + y
		ci.draw_arc(Vector2(2, ry + 2), 7.0 - i * 0.6, PI * 1.05, PI * 1.95, 6, P.OUT, 3.5)
		ci.draw_arc(Vector2(2, ry + 2), 7.0 - i * 0.6, PI * 1.05, PI * 1.95, 6, P.BONE, 2.0)
	var armor = String(p.get("armor", ""))
	var glow = col(p, "glow", "43ff8c")
	if armor != "":
		var ac = {"rust": P.RUST, "black": Color("2e2e33"), "gild": Color("9a8a4a"), "rift": Color("3a2a4a")}.get(armor, P.RUST)
		P.poly(ci, P.pts([Vector2(-7, -34 + y), Vector2(9, -34 + y), Vector2(8, -18 + y), Vector2(-6, -18 + y)]), ac, 1.8)
		if armor == "rift":
			ci.draw_line(Vector2(0, -30 + y), Vector2(2, -22 + y), Color(glow.r, glow.g, glow.b, 0.8), 2.0)
	P.poly(ci, P.pts([Vector2(-6, -18 + y), Vector2(6, -18 + y), Vector2(4, -10 + y), Vector2(1, -13 + y), Vector2(-3, -9 + y)]), Color("4a3a5a"), 1.5)
	var head = Vector2(4, -41 + y)
	var helm = Color(String(p.get("helm", "00000000"))) if p.has("helm") else Color(0, 0, 0, 0)
	AU._skull(ci, head, atk, helm)
	if p.get("hood", false):
		P.poly(ci, P.pts([head + Vector2(-8, 6), head + Vector2(-8, -6), head + Vector2(0, -12), head + Vector2(8, -6), head + Vector2(6, 2)]), Color("1a1a1a"), 1.5)
		ci.draw_circle(head + Vector2(3, -2), 1.6, Color(1.0, 0.3, 0.2))
	var sh = Vector2(4, -32 + y)
	AU._bone(ci, Vector2(-1, -32 + y), Vector2(-3 + sin(t * 2.0), -21 + y), 2.2)
	var ang = lerpf(0.4, -1.8, clampf(atk * 1.3, 0.0, 1.0)) if atk > 0.0 else 0.3
	if w in ["pike", "spear", "javelin", "sling"]:
		ang = lerpf(0.0, -0.5, clampf(atk, 0.0, 1.0)) - 0.15
	var hand = sh + Vector2.from_angle(ang) * 10.0
	AU._bone(ci, sh, hand, 2.2)
	_uweapon(ci, hand, ang - (0.9 if not w in ["pike", "spear", "javelin", "sling"] else 0.0), w, atk, t, glow)
	if p.get("lantern", false):
		ci.draw_line(Vector2(-3, -21 + y), Vector2(-3, -12 + y), Color(0.3, 0.3, 0.3), 1.2)
		P.circ(ci, Vector2(-3, -10 + y), 3.0, P.BRASS, 1.0)
		ci.draw_circle(Vector2(-3, -10 + y), 6.0, Color(0.43, 1.0, 0.55, 0.3))
	var shield = String(p.get("shield", ""))
	if shield != "":
		var sx = 12.0 + sin(clampf(atk, 0.0, 1.0) * PI) * 3.0
		match shield:
			"round":
				P.circ(ci, Vector2(sx, -28 + y), 9.0, Color("5a4a3a"), 2.0)
				P.circ(ci, Vector2(sx, -28 + y), 3.0, P.RUST, 1.0)
			"kite":
				P.poly(ci, P.pts([Vector2(sx - 2, -42 + y), Vector2(sx + 8, -40 + y), Vector2(sx + 6, -18 + y), Vector2(sx + 1, -10 + y), Vector2(sx - 4, -22 + y)]), P.BONE_D, 2.0)
			"tower":
				P.poly(ci, P.pts([Vector2(sx - 2, -48 + y), Vector2(sx + 9, -46 + y), Vector2(sx + 10, -6 + y), Vector2(sx - 2, -4 + y)]), Color("2e2e33"), 2.0)
				ci.draw_line(Vector2(sx + 4, -40 + y), Vector2(sx + 4, -12 + y), Color(0.43, 1.0, 0.55, 0.5), 2.0)


static func _cast(ci: CanvasItem, a, p: Dictionary) -> void:
	var t: float = P.g(a, "t", 0.0)
	var atk: float = P.g(a, "atk", 0.0)
	var cast: float = P.g(a, "special", 0.0)
	var moving: bool = P.g(a, "state", "") == "move"
	var w: float = P.g(a, "walk", 0.0)
	var robe = col(p, "robe", "3a2a4a")
	var glow = col(p, "glow", "a070ff")
	var wraith = p.get("wraith", false)
	var hover = sin(t * 2.0) * 2.0 if wraith else 0.0
	var sway = sin(w) * 2.0 if moving else sin(t * 1.3) * 0.8
	# robe with a ragged hem
	var hem = PackedVector2Array()
	hem.append(Vector2(-8, -38 + hover))
	hem.append(Vector2(8, -40 + hover))
	hem.append(Vector2(12 + sway, -14 + hover))
	for i in 6:
		hem.append(Vector2(14 - i * 5.0 + sway * (1.0 - i / 6.0), (0.0 if i % 2 == 0 else -4.0) - (6.0 if wraith else 0.0) + hover))
	hem.append(Vector2(-12, -14 + hover))
	P.poly(ci, hem, robe, 2.0)
	if wraith:
		for i in 3:
			ci.draw_circle(Vector2(-6 + i * 6, -4 + hover), 3.0, Color(glow.r, glow.g, glow.b, 0.25))
	ci.draw_line(Vector2(0, -36 + hover), Vector2(2, -10 + hover), robe.darkened(0.3), 2.0)
	# hood + skull face
	var head = Vector2(3, -44 + hover)
	P.poly(ci, P.pts([head + Vector2(-8, 6), head + Vector2(-8, -6), head + Vector2(0, -12), head + Vector2(9, -5), head + Vector2(8, 5)]), robe.darkened(0.15), 2.0)
	P.ell(ci, head + Vector2(3, 0), 4.5, 5.5, Color(0.05, 0.05, 0.07), 0.0)
	AU._eye(ci, head + Vector2(4, -1), glow, 1.4)
	# staff / instrument
	var staff = String(p.get("staff", "none"))
	var hand = Vector2(12, -30 + hover)
	var raise = maxf(atk, cast)
	if staff != "none":
		var top = hand + Vector2(2, -22 - raise * 6.0)
		ci.draw_line(hand + Vector2(-2, 18), top, Color(0.09, 0.07, 0.07), 4.0)
		ci.draw_line(hand + Vector2(-2, 18), top, P.WOOD_D, 2.5)
		match staff:
			"hex", "orb", "eye", "rift":
				P.circ(ci, top, 4.5, robe.lightened(0.2), 1.5)
				ci.draw_circle(top, 3.0 + raise * 3.0, Color(glow.r, glow.g, glow.b, 0.6 + 0.4 * raise))
			"skull":
				AU._skull(ci, top + Vector2(0, 2), 0.0, Color(0, 0, 0, 0))
			"bell":
				P.poly(ci, P.pts([top + Vector2(-5, -2), top + Vector2(5, -2), top + Vector2(8, 8), top + Vector2(-8, 8)]), Color("8a7a4a"), 1.5)
				if raise > 0.2:
					ci.draw_arc(top + Vector2(0, 4), 12.0 + raise * 6.0, 0, TAU, 14, Color(glow.r, glow.g, glow.b, 0.5 * raise), 2.0)
			"censer":
				ci.draw_line(top, top + Vector2(sin(t * 2.0) * 3.0, 10), Color(0.3, 0.3, 0.3), 1.2)
				P.circ(ci, top + Vector2(sin(t * 2.0) * 3.0, 12), 3.5, P.BRASS, 1.0)
				ci.draw_circle(top + Vector2(sin(t * 2.0) * 3.0, 6), 5.0, Color(glow.r, glow.g, glow.b, 0.3))
			"chain":
				for i in 4:
					ci.draw_arc(top + Vector2(i * 3.0, i * 4.0), 2.0, 0, TAU, 6, Color(glow.r, glow.g, glow.b, 0.8), 1.5)
			"horn":
				P.poly(ci, P.pts([top + Vector2(-2, 0), top + Vector2(10, -8), top + Vector2(12, -4), top + Vector2(0, 3)]), P.BONE_D, 1.5)
	P.circ(ci, hand, 3.0, P.BONE, 1.2)
	if raise > 0.3:
		ci.draw_circle(hand + Vector2(4, -20), 10.0 * raise, Color(glow.r, glow.g, glow.b, 0.25))


# ================================================================== beasts
static func _beast(ci: CanvasItem, a, p: Dictionary) -> void:
	var t: float = P.g(a, "t", 0.0)
	var atk: float = P.g(a, "atk", 0.0)
	var walk: float = P.g(a, "walk", 0.0)
	var moving: bool = P.g(a, "state", "") == "move"
	var skin = col(p, "skin", "7a6a5a")
	var kind = String(p.get("kind", "hound"))
	match kind:
		"hound", "charger":
			var big = kind == "charger"
			var sc = 1.6 if big else 1.0
			var by = -16.0 * sc
			for i in 4:
				var ph = walk * 1.4 + (PI if i % 2 else 0.0)
				var lx = (-10.0 + (i / 2) * 20.0) * sc
				var fx = lx + (sin(ph) * 5.0 * sc if moving else 0.0)
				P.limb(ci, Vector2(lx, by + 4), Vector2(fx, -1), 3.5 * sc, skin.darkened(0.2 if i < 2 else 0.0))
			P.poly(ci, P.pts([Vector2(-16 * sc, by + 6), Vector2(-18 * sc, by - 4), Vector2(-4 * sc, by - 10 * sc), Vector2(12 * sc, by - 8), Vector2(16 * sc, by + 2), Vector2(4 * sc, by + 8)]), skin, 2.0)
			for i in 3:
				ci.draw_arc(Vector2(-4 * sc + i * 5.0 * sc, by), 4.0 * sc, 0.4, 2.6, 5, P.BONE_D, 1.5)
			var head = Vector2(18 * sc, by - 4 - atk * 3.0)
			P.poly(ci, P.pts([head + Vector2(-6, -5) * sc, head + Vector2(8, -3) * sc, head + Vector2(12, 2) * sc, head + Vector2(2, 5) * sc + Vector2(0, atk * 4.0), head + Vector2(-6, 3) * sc]), skin.lightened(0.05), 2.0)
			AU._eye(ci, head + Vector2(2, -2) * sc, Color(0.9, 1.0, 0.4), 1.4)
			if big:
				for sgn in [-1.0, 1.0]:
					P.poly(ci, P.pts([head + Vector2(-2, -5) * sc, head + Vector2(-6, -16) * sc + Vector2(0, sgn * 2.0), head + Vector2(2, -6) * sc]), P.BONE_D, 1.5)
		"spider":
			var body = Vector2(0, -16)
			for i in 8:
				var side = -1.0 if i < 4 else 1.0
				var k = i % 4
				var ph2 = walk * 2.0 + k * 1.6
				var root = body + Vector2(-6 + k * 4.0, 0)
				var knee = root + Vector2((k - 1.5) * 9.0, -14 + sin(ph2) * 3.0)
				var foot = Vector2(root.x + (k - 1.5) * 16.0 + (sin(ph2) * 4.0 if moving else 0.0), 0)
				var lc = skin.darkened(0.3 if side < 0 else 0.0)
				P.limb(ci, root, knee, 2.5, lc)
				P.limb(ci, knee, foot, 2.0, lc)
			P.ell(ci, body + Vector2(-10, -4), 14, 11, skin, 2.0)
			P.ell(ci, body + Vector2(8, 0), 8, 7, skin.lightened(0.08), 2.0)
			for i in 4:
				ci.draw_circle(body + Vector2(12 + (i % 2) * 3.0, -3 + (i / 2) * 3.0), 1.4, Color(0.6, 1.0, 0.5))
			ci.draw_line(body + Vector2(14, 4), body + Vector2(18, 8 + atk * 4.0), P.BONE, 2.0)
			ci.draw_arc(body + Vector2(-10, -4), 8.0, 0.2, 2.8, 8, Color(0.85, 0.85, 0.8, 0.5), 1.0)
		"centipede":
			var n = 7
			for i in n:
				var x = 28.0 - i * 9.0
				var yy = -12.0 + sin(walk * 1.5 + i * 0.8) * (2.0 if moving else 0.5)
				for sgn in [-1.0, 1.0]:
					ci.draw_line(Vector2(x, yy + 4), Vector2(x + sgn * 3.0 + sin(walk * 3.0 + i) * 2.0, 0), skin.darkened(0.35), 2.0)
				P.ell(ci, Vector2(x, yy), 7, 7, skin if i % 2 == 0 else skin.darkened(0.1), 2.0)
				P.poly(ci, P.pts([Vector2(x - 5, yy - 6), Vector2(x, yy - 11), Vector2(x + 5, yy - 6)]), P.BONE_D, 1.0)
			var hd = Vector2(36, -12)
			P.circ(ci, hd, 7.0, skin.lightened(0.05), 2.0)
			for sgn in [-1.0, 1.0]:
				P.poly(ci, P.pts([hd + Vector2(4, sgn * 2.0), hd + Vector2(14, sgn * (5.0 - atk * 4.0)), hd + Vector2(6, sgn * 4.0)]), P.BONE, 1.2)
			AU._eye(ci, hd + Vector2(2, -3), Color(0.9, 0.5, 0.3), 1.4)
		"devourer":
			var r = AU._zombie(ci, a, {"flesh": skin, "cloth": Color("3a2a2a")})
			P.ell(ci, Vector2(2, -30 + r.y), 16, 14, skin.darkened(0.1), 2.0)
			for i in 6:
				AU._bone(ci, Vector2(-10 + i * 4, -42 + r.y), Vector2(-12 + i * 5, -52 + r.y - (i % 2) * 4), 2.0)
			P.poly(ci, P.pts([Vector2(8, -32 + r.y), Vector2(20, -34 + r.y + atk * 6.0), Vector2(18, -24 + r.y)]), Color("2a1414"), 1.5)
		"ooze":
			var wob = sin(t * 3.0) * 3.0
			P.poly(ci, P.pts([Vector2(-26, 0), Vector2(-28 - wob, -14), Vector2(-16, -34 + wob), Vector2(2, -42 - wob), Vector2(20, -32 + wob), Vector2(28 + wob, -12), Vector2(24, 0)]), skin, 2.5)
			for i in 6:
				var bp = Vector2(-16 + i * 6.0, -10 - fmod(t * 10.0 + i * 7.0, 28.0))
				ci.draw_circle(bp, 2.5, skin.lightened(0.25))
			for i in 3:
				AU._skull(ci, Vector2(-10 + i * 10.0, -16 - (i % 2) * 8.0), 0.0, Color(0, 0, 0, 0))
			if atk > 0.1:
				P.ell(ci, Vector2(26, -14), 8 * atk, 6 * atk, skin.lightened(0.1), 1.5)
		"burrower":
			var st = String(P.g(a, "state", "move"))
			if st == "burrowed":
				P.ell(ci, Vector2(0, -3), 22, 6, Color("4a3d30"), 2.0)
				for i in 4:
					ci.draw_circle(Vector2(-14 + i * 9, -6 - fmod(t * 20.0 + i * 5.0, 8.0)), 2.0, Color("6a5a48"))
				return
			P.poly(ci, P.pts([Vector2(-22, 0), Vector2(-20, -18), Vector2(-6, -34), Vector2(12, -36), Vector2(24, -20), Vector2(22, 0)]), skin, 2.5)
			for i in 4:
				ci.draw_arc(Vector2(0, -18), 10.0 + i * 4.0, -2.4, -0.7, 6, skin.darkened(0.2), 2.0)
			var mo = 4.0 + atk * 8.0
			for sgn in [-1.0, 1.0]:
				P.poly(ci, P.pts([Vector2(18, -22), Vector2(34, -22 + sgn * mo), Vector2(22, -18 + sgn * 3.0)]), P.BONE, 1.5)
			AU._eye(ci, Vector2(14, -28), Color(1.0, 0.5, 0.3), 1.8)
			AU._eye(ci, Vector2(8, -30), Color(1.0, 0.5, 0.3), 1.4)


# ================================================================== siege engines
static func _siege(ci: CanvasItem, a, p: Dictionary) -> void:
	var t: float = P.g(a, "t", 0.0)
	var atk: float = P.g(a, "atk", 0.0)
	var glow = col(p, "glow", "43ff8c")
	var kind = String(p.get("kind", "catapult"))
	var bone = P.BONE_D
	match kind:
		"catapult", "lobber", "trebuchet":
			var big = kind == "trebuchet"
			var s = 1.6 if big else 1.0
			P.poly(ci, P.pts([Vector2(-26 * s, -8), Vector2(26 * s, -8), Vector2(22 * s, -16 * s), Vector2(-22 * s, -16 * s)]), P.WOOD_D, 2.0)
			for x in [-16.0 * s, 16.0 * s]:
				P.circ(ci, Vector2(x, -6), 7.0 * s, bone, 1.5)
				AU._skull(ci, Vector2(x, -6), 0.0, Color(0, 0, 0, 0))
			ci.draw_line(Vector2(-6 * s, -16 * s), Vector2(0, -40 * s), bone, 5.0)
			ci.draw_line(Vector2(6 * s, -16 * s), Vector2(0, -40 * s), bone, 5.0)
			var arm_a = lerpf(-2.6, -1.1, clampf(atk * 1.6, 0.0, 1.0))
			var piv = Vector2(0, -38 * s)
			var tip = piv + Vector2.from_angle(arm_a) * 34.0 * s
			ci.draw_line(piv - Vector2.from_angle(arm_a) * 12.0 * s, tip, Color(0.09, 0.07, 0.07), 6.0)
			ci.draw_line(piv - Vector2.from_angle(arm_a) * 12.0 * s, tip, P.WOOD, 4.0)
			if atk < 0.3:
				if kind == "lobber":
					P.circ(ci, tip, 6.0 * s, P.FLESH, 1.5)
				else:
					P.circ(ci, tip, 5.0 * s, bone, 1.5)
			P.circ(ci, piv - Vector2.from_angle(arm_a) * 12.0 * s, 7.0 * s, Color("3a3a3a"), 1.5)
		"mortar", "howitzer", "ballista", "launcher", "spore_cannon", "cauldron":
			P.poly(ci, P.pts([Vector2(-22, 0), Vector2(22, 0), Vector2(18, -14), Vector2(-18, -14)]), Color("4a3a30"), 2.0)
			for x in [-12.0, 12.0]:
				P.circ(ci, Vector2(x, -4), 6.0, bone, 1.5)
			match kind:
				"mortar":
					P.bar(ci, Vector2(0, -14), -1.0, 22, 12.0, bone, 2.0)
				"howitzer":
					P.bar(ci, Vector2(-4, -18), -0.5, 38, 11.0, bone, 2.0)
					P.rivets(ci, Vector2(0, -22), Vector2(20, -32), 3, P.RUST)
				"ballista":
					P.bar(ci, Vector2(-14, -22), -0.15, 34, 4.0, P.WOOD_D, 1.5)
					ci.draw_arc(Vector2(4, -24), 14, -1.9, 1.9, 8, bone, 3.0)
					if atk < 0.4:
						P.bar(ci, Vector2(-10, -24), -0.15, 30, 2.0, bone, 1.0)
				"launcher":
					for i in 3:
						P.bar(ci, Vector2(-8, -18 - i * 4), -0.6, 26, 3.5, bone, 1.0)
				"spore_cannon":
					P.bar(ci, Vector2(-4, -20), -0.9, 28, 12.0, Color("6a7040"), 2.0)
					var top = Vector2(-4, -20) + Vector2.from_angle(-0.9) * 28.0
					ci.draw_circle(top, 7.0 + atk * 6.0, Color(glow.r, glow.g, glow.b, 0.35))
				"cauldron":
					P.ell(ci, Vector2(0, -26), 18, 12, Color("2a2a2a"), 2.5)
					P.ell(ci, Vector2(0, -32), 15, 4, Color(glow.r, glow.g, glow.b, 0.9), 1.0)
					for i in 3:
						ci.draw_circle(Vector2(-8 + i * 8, -36 - fmod(t * 14.0 + i * 5.0, 14.0)), 2.5, Color(glow.r, glow.g, glow.b, 0.6))
		"ram":
			P.poly(ci, P.pts([Vector2(-34, -14), Vector2(26, -14), Vector2(30, -40), Vector2(-30, -44)]), Color("4a3a30"), 2.0)
			for i in 4:
				ci.draw_line(Vector2(-30 + i * 18, -14), Vector2(-28 + i * 18, -42), bone, 3.0)
			var push = sin(clampf(atk, 0.0, 1.0) * PI) * 10.0
			P.bar(ci, Vector2(-30 + push, -26), 0.0, 66, 9.0, P.WOOD_D, 1.8)
			AU._skull(ci, Vector2(38 + push, -26), atk, Color("5a5a52"))
			for x in [-22.0, 0.0, 20.0]:
				P.wheel(ci, Vector2(x, -7), 7.0, P.g(a, "walk", 0.0) * 2.0, P.WOOD_D, bone, 5)
		"flak_spire", "obelisk", "soul_turret", "beacon":
			var hgt = {"flak_spire": 100.0, "obelisk": 110.0, "soul_turret": 72.0, "beacon": 90.0}[kind]
			var base_c = Color("3a3440") if kind == "obelisk" else Color("4a4440")
			P.poly(ci, P.pts([Vector2(-16, 0), Vector2(16, 0), Vector2(6, -hgt), Vector2(-6, -hgt)]), base_c if kind != "flak_spire" else bone, 2.5)
			for i in 4:
				ci.draw_line(Vector2(-12 + i * 3.0, -i * hgt / 4.0 - 6.0), Vector2(12 - i * 3.0, -i * hgt / 4.0 - 6.0), base_c.darkened(0.3), 2.0)
			var orb = Vector2(0, -hgt - 8)
			var pulse = 0.6 + 0.4 * sin(t * 3.0)
			if kind == "flak_spire":
				for i in 3:
					P.poly(ci, P.pts([orb + Vector2(-4 + i * 4, 8), orb + Vector2(-2 + i * 4, -8), orb + Vector2(i * 4, 8)]), bone, 1.2)
			else:
				ci.draw_circle(orb, 14.0 * pulse + atk * 6.0, Color(glow.r, glow.g, glow.b, 0.25))
				P.circ(ci, orb, 7.0, glow.darkened(0.2), 1.5)
				if kind == "soul_turret":
					AU._skull(ci, orb, atk, Color(0, 0, 0, 0))
		"barricade":
			for i in 4:
				P.bar(ci, Vector2(-18 + i * 10, 0), -1.3 + i * 0.15, 38, 5.0, Color("4a3a30"), 1.5)
			for i in 3:
				AU._skull(ci, Vector2(-10 + i * 10, -24), 0.0, Color(0, 0, 0, 0))
			ci.draw_line(Vector2(-20, -16), Vector2(20, -18), P.RUST, 3.0)


# ================================================================== undead flyers
static func _fly(ci: CanvasItem, a, p: Dictionary, sc: float) -> void:
	var t: float = P.g(a, "t", 0.0)
	var atk: float = P.g(a, "atk", 0.0)
	var skin = col(p, "skin", "5a4a4a")
	var glow = col(p, "glow", "43ff8c")
	var kind = String(p.get("kind", "bat"))
	var flap = sin(t * (14.0 if sc < 1.5 else 6.0) + P.g(a, "special", 0.0))
	var span = 22.0 * float(p.get("span", 1.0))
	match kind:
		"bat", "vulture", "crow", "harpy", "gargoyle", "bonebird":
			var wing_c = skin.darkened(0.2)
			if kind in ["vulture", "bonebird"]:
				wing_c = P.BONE_D
			AU._wing(ci, Vector2(-2, -2), -1.0, span, flap * 0.7 - 0.2, wing_c.darkened(0.15))
			var bs = span * 0.35
			P.ell(ci, Vector2(0, 0), bs, bs * 0.65, skin, 2.0)
			if kind in ["vulture", "bonebird"]:
				for i in 3:
					ci.draw_arc(Vector2(-bs * 0.3 + i * bs * 0.3, 0), bs * 0.3, 0.3, 2.8, 5, P.BONE, 1.5)
			var head = Vector2(bs * 1.0, -bs * 0.3)
			P.circ(ci, head, bs * 0.5, skin.lightened(0.08) if kind != "vulture" else P.BONE, 1.8)
			if kind == "vulture" or kind == "crow":
				P.poly(ci, P.pts([head + Vector2(bs * 0.3, -2), head + Vector2(bs * 1.0, 2 + atk * 3.0), head + Vector2(bs * 0.3, 3)]), P.BONE_D, 1.2)
			if kind == "harpy":
				ci.draw_line(head, head + Vector2(-bs, bs), Color("2a2630"), 2.0)
			if kind == "gargoyle":
				for sgn in [-1.0, 1.0]:
					P.poly(ci, P.pts([head + Vector2(-2, -bs * 0.4), head + Vector2(-4, -bs * 1.1), head + Vector2(2, -bs * 0.5)]), skin.darkened(0.3), 1.0)
			AU._eye(ci, head + Vector2(bs * 0.2, -1), glow if kind == "crow" else Color(1.0, 0.4, 0.3), 1.3 * maxf(1.0, sc * 0.5))
			AU._wing(ci, Vector2(2, -4), 1.0, span, flap - 0.2, wing_c)
			if p.get("crown", false):
				for i in 4:
					P.poly(ci, P.pts([head + Vector2(-bs * 0.4 + i * bs * 0.25, -bs * 0.45), head + Vector2(-bs * 0.3 + i * bs * 0.25, -bs * 0.9), head + Vector2(-bs * 0.2 + i * bs * 0.25, -bs * 0.45)]), P.BRASS, 1.0)
		"moth", "wasp":
			var c2 = skin
			AU._wing(ci, Vector2(-2, -4), -1.0, span * 0.8, flap * 0.9, Color(c2.r, c2.g, c2.b, 0.7))
			P.ell(ci, Vector2(-6, 2), 8, 5, c2.darkened(0.2), 1.5)
			if kind == "wasp":
				for i in 2:
					ci.draw_line(Vector2(-10 + i * 4, -2), Vector2(-10 + i * 4, 6), Color(0.1, 0.1, 0.1), 2.0)
				P.poly(ci, P.pts([Vector2(-14, 2), Vector2(-20, 4 + atk * 3.0), Vector2(-14, 5)]), P.OUT, 1.0)
			P.circ(ci, Vector2(6, 0), 4.5, c2.lightened(0.1), 1.5)
			AU._eye(ci, Vector2(8, -1), Color(1.0, 0.4, 0.3), 1.2)
			AU._wing(ci, Vector2(2, -6), 1.0, span * 0.8, flap * 0.9, Color(c2.r, c2.g, c2.b, 0.8))
		"wraith", "swarm":
			var n = 1 if kind == "wraith" else 6
			for i in n:
				var off = Vector2.ZERO if n == 1 else Vector2(cos(t * 3.0 + i * 1.1) * 14.0, sin(t * 4.0 + i * 1.7) * 8.0)
				var tail = PackedVector2Array([off + Vector2(-10, -10), off + Vector2(8, -12), off + Vector2(12, 0), off + Vector2(-2, 8), off + Vector2(-22 + sin(t * 5.0 + i) * 4.0, 14), off + Vector2(-14, 2)])
				ci.draw_colored_polygon(tail, Color(glow.r, glow.g, glow.b, 0.35))
				P.circ(ci, off + Vector2(4, -6), 5.0 if n == 1 else 3.0, Color(glow.r * 0.6, glow.g * 0.6, glow.b * 0.6), 1.2)
				ci.draw_circle(off + Vector2(6, -7), 1.4, Color(1, 1, 1))
				if p.get("wings", false):
					AU._wing(ci, off + Vector2(0, -6), 1.0, span, flap * 0.5, Color(glow.r, glow.g, glow.b, 0.4))
		"wyvern", "drake":
			var big = kind == "drake" or sc > 1.5
			var ws = span * (1.4 if big else 1.0)
			AU._wing(ci, Vector2(-4, -6), -1.0, ws, flap * 0.6 - 0.3, skin.darkened(0.25))
			var bl = ws * 0.45
			# body + long neck + tail, skeletal
			P.poly(ci, P.pts([Vector2(-bl, 2), Vector2(-bl * 0.4, -bl * 0.25), Vector2(bl * 0.4, -bl * 0.2), Vector2(bl * 0.5, bl * 0.12), Vector2(-bl * 0.3, bl * 0.22)]), skin, 2.0)
			for i in 4:
				ci.draw_arc(Vector2(-bl * 0.2 + i * bl * 0.15, 0), bl * 0.12, 0.3, 2.8, 5, P.BONE_D, 1.5)
			var neck_end = Vector2(bl * 1.0, -bl * 0.45)
			AU._bone(ci, Vector2(bl * 0.4, -bl * 0.1), neck_end, maxf(2.5, bl * 0.08))
			ci.draw_line(Vector2(-bl, 2), Vector2(-bl * 1.8, bl * 0.2 + sin(t * 2.0) * 4.0), skin.darkened(0.2), maxf(2.0, bl * 0.07))
			var jaw = atk * bl * 0.15
			P.poly(ci, P.pts([neck_end + Vector2(-bl * 0.12, -bl * 0.1), neck_end + Vector2(bl * 0.3, -bl * 0.05), neck_end + Vector2(bl * 0.32, bl * 0.04), neck_end + Vector2(-bl * 0.1, bl * 0.08)]), P.BONE, 1.8)
			P.poly(ci, P.pts([neck_end + Vector2(-bl * 0.05, bl * 0.06), neck_end + Vector2(bl * 0.25, bl * 0.06 + jaw), neck_end + Vector2(-bl * 0.05, bl * 0.12)]), P.BONE_D, 1.2)
			AU._eye(ci, neck_end + Vector2(bl * 0.05, -bl * 0.04), glow, maxf(1.5, bl * 0.05))
			if atk > 0.2 and kind == "drake":
				ci.draw_circle(neck_end + Vector2(bl * 0.45, bl * 0.05), bl * 0.15 * atk, Color(glow.r, glow.g, glow.b, 0.5))
			AU._wing(ci, Vector2(4, -8), 1.0, ws, flap * 0.6 - 0.3, skin.darkened(0.1))
		"serpent":
			var segs = 10
			var len_s = span * 1.6
			var prev = Vector2.ZERO
			for i in segs:
				var x = len_s * 0.5 - i * len_s / segs
				var yy = sin(t * 2.0 + i * 0.7) * span * 0.15
				var r = span * 0.16 * (1.0 - i * 0.06)
				P.circ(ci, Vector2(x, yy), r, skin if i % 2 == 0 else skin.darkened(0.15), 1.8)
				if i % 2 == 0:
					P.poly(ci, P.pts([Vector2(x - r * 0.4, yy - r), Vector2(x, yy - r * 1.8), Vector2(x + r * 0.4, yy - r)]), P.BONE_D, 1.0)
				prev = Vector2(x, yy)
			var hd = Vector2(len_s * 0.5 + span * 0.15, sin(t * 2.0) * span * 0.15)
			P.poly(ci, P.pts([hd + Vector2(-span * 0.15, -span * 0.12), hd + Vector2(span * 0.25, -span * 0.05), hd + Vector2(span * 0.25, span * 0.06 + atk * span * 0.1), hd + Vector2(-span * 0.15, span * 0.12)]), P.BONE, 2.0)
			AU._eye(ci, hd + Vector2(span * 0.02, -span * 0.04), glow, maxf(1.5, span * 0.04))
			if p.get("crown", false) or sc > 1.5:
				for i in 3:
					P.poly(ci, P.pts([hd + Vector2(-span * 0.1 + i * span * 0.06, -span * 0.11), hd + Vector2(-span * 0.12 + i * span * 0.06, -span * 0.3), hd + Vector2(-span * 0.06 + i * span * 0.06, -span * 0.11)]), P.BONE_D, 1.2)


# ================================================================== corrupted + boss configs
static func _corrupt(ci: CanvasItem, art: String, a, p: Dictionary) -> void:
	var t: float = P.g(a, "t", 0.0)
	var base = String(p.get("base", ""))
	if base == "kit:gravegun_hull":
		_veh(ci, a, {"hull": "tracked", "len": 80, "ht": 52, "coat": "4a4a3a", "turrets": ["heavy"], "plates": 2})
	elif base != "":
		Painter.draw_unit(ci, base, a)
		Painter.current_art = art
		var src: Dictionary = Painter.used_keys.get(base, {})
		var dst: Dictionary = Painter.used_keys.get(art, {})
		for k in src:
			dst[k] = true
		Painter.used_keys[art] = dst
	# corruption overlay: bone spurs, necrotic cracks and a sickly glow
	var h = height(art)
	var ground = not Painter.is_air_art(base) and base != "ironcloud"
	var c0 = Vector2(0, -h * 0.5) if ground else Vector2.ZERO
	var g = Color(0.43, 1.0, 0.55)
	for i in 4:
		var ang = -2.4 + i * 0.6
		var root = c0 + Vector2.from_angle(ang) * h * 0.3
		P.poly(ci, P.pts([root - Vector2.from_angle(ang + 1.6) * 3.0, root + Vector2.from_angle(ang) * h * 0.14, root + Vector2.from_angle(ang + 1.6) * 3.0]), P.BONE_D, 1.2)
	for i in 3:
		var cp = c0 + Vector2(-h * 0.2 + i * h * 0.2, (i % 2) * h * 0.1)
		ci.draw_line(cp, cp + Vector2(h * 0.06, h * 0.08), Color(g.r, g.g, g.b, 0.55 + 0.3 * sin(t * 3.0 + i)), 2.0)
	ci.draw_circle(c0, h * 0.12, Color(g.r, g.g, g.b, 0.12 + 0.06 * sin(t * 2.0)))


static func _giant_cfg(ci: CanvasItem, art: String, a, p: Dictionary) -> void:
	var t: float = P.g(a, "t", 0.0)
	var base = String(p.get("base", "stitchback_giant"))
	if p.get("robe", false):
		# a long tattered mantle behind the giant
		P.poly(ci, P.pts([Vector2(-30, -100), Vector2(10, -104), Vector2(24, -10), Vector2(10, -2), Vector2(-4, -8), Vector2(-20, 0), Vector2(-36, -6)]), Color("1d1a21"), 2.5)
	AG.draw(ci, base, a)
	Painter.current_art = art
	var src: Dictionary = Painter.used_keys.get(base, {})
	var dst: Dictionary = Painter.used_keys.get(art, {})
	for k in src:
		dst[k] = true
	Painter.used_keys[art] = dst
	var top = Vector2(12, -118)
	if p.get("crown", false):
		for i in 5:
			P.poly(ci, P.pts([top + Vector2(-12 + i * 6, 6), top + Vector2(-10 + i * 6, -8 - (i % 2) * 6), top + Vector2(-6 + i * 6, 6)]), P.BRASS, 1.5)
		ci.draw_line(top + Vector2(-13, 6), top + Vector2(17, 6), P.BRASS_D, 3.0)
	if p.get("furnace", false):
		var fc = Vector2(-4, -64)
		P.rrect(ci, Rect2(fc.x - 14, fc.y - 12, 28, 24), P.COAL, 2.5, 3.0)
		ci.draw_circle(fc, 8.0, Color(1.0, 0.55, 0.2, 0.8 + 0.2 * sin(t * 5.0)))
		for i in 2:
			ci.draw_line(Vector2(-16 + i * 10, -100), Vector2(-16 + i * 10, -126), P.IRON_D, 5.0)
			P.smoke_puff(ci, Vector2(-16 + i * 10, -128), t + i * 0.4, 3, Color(0.3, 0.28, 0.27, 0.6))
