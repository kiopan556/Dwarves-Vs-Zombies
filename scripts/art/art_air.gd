class_name ArtAir
extends RefCounted
## Dwarven aircraft and airships. Origin = centre of the craft. Facing right.

const P = preload("res://scripts/art/painter.gd")
const D = preload("res://scripts/art/art_dwarves.gd")


static func draw(ci: CanvasItem, art: String, a) -> void:
	match art:
		"flying_machine": _flying_machine(ci, a)
		"scout_gyro": _scout_gyro(ci, a)
		"bombard_gyro": _bombard_gyro(ci, a)
		"ironwing": _ironwing(ci, a)
		"ironcloud": _ironcloud(ci, a)


static func rotor(ci: CanvasItem, hub: Vector2, span: float, t: float, speed: float = 30.0) -> void:
	# spinning blades rendered as a foreshortened blur + a visible blade
	var ph = t * speed
	var k = absf(cos(ph))
	ci.draw_line(hub + Vector2(-span, 0), hub + Vector2(span, 0), Color(0.75, 0.75, 0.75, 0.25), 3.0)
	ci.draw_line(hub - Vector2(span * k, 0), hub + Vector2(span * k, 0), P.OUT, 4.0)
	ci.draw_line(hub - Vector2(span * k, 0), hub + Vector2(span * k, 0), P.WOOD, 2.5)
	P.circ(ci, hub, 3, P.BRASS, 1.5)


static func prop(ci: CanvasItem, hub: Vector2, r: float, t: float) -> void:
	var k = absf(sin(t * 35.0))
	ci.draw_line(hub + Vector2(0, -r), hub + Vector2(0, r), Color(0.8, 0.8, 0.8, 0.3), 3.0)
	ci.draw_line(hub + Vector2(0, -r * k), hub + Vector2(0, r * k), P.WOOD_D, 2.5)
	P.circ(ci, hub, 2.5, P.BRASS, 1.2)


static func pilot(ci: CanvasItem, a, at: Vector2, sc: float, beard: Color) -> void:
	ci.draw_set_transform(at, 0.0, Vector2(sc, sc))
	D.dwarf_head(ci, a, Vector2.ZERO, {"beard": beard, "helmet": "goggle_cap", "helm_col": P.LEATHER})
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _gun(ci: CanvasItem, at: Vector2, aim: float, length: float, w: float, atk: float, flash_size: float = 8.0) -> void:
	P.bar(ci, at, aim, length, w, P.IRON_D, 1.2)
	if atk > 0.6:
		P.muzzle_flash(ci, at + Vector2(cos(aim), sin(aim)) * length, aim, flash_size, (atk - 0.6) * 2.5)


static func _flying_machine(ci: CanvasItem, a) -> void:
	var t: float = P.g(a, "t", 0.0)
	var atk: float = P.g(a, "atk", 0.0)
	# tail boom + tail prop
	P.poly(ci, P.pts([Vector2(-8, -4), Vector2(-34, -6), Vector2(-36, -2), Vector2(-8, 2)]), P.WOOD, 1.5)
	P.poly(ci, P.pts([Vector2(-34, -6), Vector2(-40, -14), Vector2(-36, -14), Vector2(-30, -6)]), P.DEEP_BLUE, 1.5)
	prop(ci, Vector2(-37, -4), 7, t)
	# mast + rotor
	ci.draw_line(Vector2(0, -8), Vector2(0, -20), P.OUT, 4.0)
	ci.draw_line(Vector2(0, -8), Vector2(0, -20), P.IRON, 2.0)
	# gondola (boat hull)
	P.poly(ci, P.pts([Vector2(-14, -6), Vector2(16, -6), Vector2(22, -2), Vector2(14, 8), Vector2(-10, 8), Vector2(-16, 0)]), P.WOOD, 2.0)
	ci.draw_line(Vector2(-14, -1), Vector2(19, -1), P.BRASS, 2.0)
	P.rivets(ci, Vector2(-10, 4), Vector2(12, 4), 4)
	pilot(ci, a, Vector2(2, -10), 0.62, Color("a5532a"))
	# forward MG
	_gun(ci, Vector2(18, 2), P.g(a, "aim0", 0.0), 12, 2.5, atk)
	rotor(ci, Vector2(0, -21), 30, t, 28.0)
	# landing skid
	ci.draw_line(Vector2(-8, 8), Vector2(-10, 13), P.IRON_D, 2.0)
	ci.draw_line(Vector2(8, 8), Vector2(10, 13), P.IRON_D, 2.0)
	ci.draw_line(Vector2(-14, 13), Vector2(14, 13), P.IRON_D, 2.0)


static func _scout_gyro(ci: CanvasItem, a) -> void:
	var t: float = P.g(a, "t", 0.0)
	var atk: float = P.g(a, "atk", 0.0)
	# long slim tail with pennant
	P.poly(ci, P.pts([Vector2(-6, -3), Vector2(-38, -3), Vector2(-38, 0), Vector2(-6, 2)]), P.IRON, 1.5)
	var fl = sin(t * 8.0) * 2.0
	P.poly(ci, P.pts([Vector2(-38, -3), Vector2(-50, -6 + fl), Vector2(-46, -1 + fl), Vector2(-50, 3 + fl), Vector2(-38, 0)]), Color("2f4f7a"), 1.2)
	ci.draw_line(Vector2(0, -6), Vector2(0, -16), P.IRON, 2.0)
	P.ell(ci, Vector2(2, 0), 12, 7, P.BRASS, 2.0)
	P.poly(ci, P.pts([Vector2(4, -6), Vector2(12, -5), Vector2(10, -1), Vector2(4, -1)]), Color(0.6, 0.85, 0.95, 0.8), 1.2)
	pilot(ci, a, Vector2(-2, -8), 0.55, Color("c9a050"))
	# spyglass
	P.bar(ci, Vector2(4, -10), -0.15, 10, 2.5, P.BRASS, 1.0)
	_gun(ci, Vector2(12, 3), P.g(a, "aim0", 0.0), 9, 2.0, atk, 6.0)
	rotor(ci, Vector2(0, -17), 24, t, 34.0)


static func _bombard_gyro(ci: CanvasItem, a) -> void:
	var t: float = P.g(a, "t", 0.0)
	var ammo: int = int(P.g(a, "ammo", 4))
	P.poly(ci, P.pts([Vector2(-10, -4), Vector2(-40, -8), Vector2(-42, -2), Vector2(-10, 3)]), P.WOOD, 1.5)
	P.poly(ci, P.pts([Vector2(-38, -8), Vector2(-44, -18), Vector2(-40, -18), Vector2(-34, -8)]), P.CLOTH_RED, 1.5)
	prop(ci, Vector2(-42, -4), 8, t)
	for mx in [-12.0, 12.0]:
		ci.draw_line(Vector2(mx, -8), Vector2(mx, -22), P.OUT, 4.0)
		ci.draw_line(Vector2(mx, -8), Vector2(mx, -22), P.IRON, 2.0)
	# chunky hull
	P.poly(ci, P.pts([Vector2(-20, -8), Vector2(20, -8), Vector2(26, -2), Vector2(20, 10), Vector2(-16, 10), Vector2(-22, 0)]), Color("6e5a3a"), 2.0)
	ci.draw_line(Vector2(-20, -2), Vector2(24, -2), P.BRASS, 2.0)
	P.rivets(ci, Vector2(-16, 6), Vector2(18, 6), 6)
	pilot(ci, a, Vector2(8, -12), 0.6, Color("6b4127"))
	# bomb rack showing remaining bombs
	P.rect(ci, Rect2(-14, 10, 28, 3), P.IRON_D, 1.5)
	for i in 4:
		if i < ammo:
			P.ell(ci, Vector2(-10 + i * 7, 17), 3.2, 4.5, P.COAL, 1.5)
			ci.draw_line(Vector2(-10 + i * 7, 20), Vector2(-10 + i * 7, 23), P.BRASS, 2.0)
	rotor(ci, Vector2(-12, -23), 22, t, 27.0)
	rotor(ci, Vector2(12, -23), 22, t + 0.3, 27.0)


static func _ironwing(ci: CanvasItem, a) -> void:
	var t: float = P.g(a, "t", 0.0)
	var atk: float = P.g(a, "atk", 0.0)
	var atk2: float = P.g(a, "atk2", 0.0)
	# armored tail
	P.poly(ci, P.pts([Vector2(-26, -8), Vector2(-60, -12), Vector2(-62, -4), Vector2(-26, 4)]), P.IRON, 2.0)
	P.poly(ci, P.pts([Vector2(-56, -12), Vector2(-64, -26), Vector2(-58, -26), Vector2(-50, -12)]), P.IRON_D, 1.5)
	prop(ci, Vector2(-62, -8), 10, t)
	for mx in [-18.0, 22.0]:
		P.rect(ci, Rect2(mx - 2, -30, 4, 18), P.IRON_D, 1.5)
	# hull
	P.poly(ci, P.pts([Vector2(-30, -14), Vector2(28, -16), Vector2(40, -6), Vector2(36, 10), Vector2(-24, 12), Vector2(-32, 0)]), P.IRON, 2.5)
	P.poly(ci, P.pts([Vector2(-28, -12), Vector2(26, -14), Vector2(32, -9), Vector2(-28, -6)]), P.STEEL, 0.0)
	P.rivets(ci, Vector2(-26, 6), Vector2(32, 6), 9)
	P.rect(ci, Rect2(20, -10, 12, 6), Color(0.6, 0.85, 0.95, 0.85), 1.5)
	ci.draw_line(Vector2(-28, -2), Vector2(36, -2), P.BRASS, 2.0)
	pilot(ci, a, Vector2(24, -14), 0.5, Color("9a9a9a"))
	# belly cannon (weapon 0)
	var b_aim: float = clampf(P.g(a, "aim0", 1.2), 0.1, 2.9)
	var bp = Vector2(6, 12)
	P.circ(ci, bp, 7, P.IRON_D, 2.0)
	var rec = atk * atk * 5.0
	P.bar(ci, bp - Vector2(cos(b_aim), sin(b_aim)) * rec, b_aim, 20, 5.0, P.IRON, 1.5)
	P.muzzle_flash(ci, bp + Vector2(cos(b_aim), sin(b_aim)) * (20 - rec), b_aim, 13.0, D._flash_strength(atk))
	# dorsal turret (weapon 1)
	var d_aim: float = P.g(a, "aim1", -0.5)
	var dp = Vector2(-6, -18)
	P.poly(ci, P.ell_pts(dp, 9, 7, 0.0, 10, PI, TAU), P.BRASS, 2.0)
	_gun(ci, dp + Vector2(0, -3), d_aim, 14, 2.6, atk2)
	rotor(ci, Vector2(-18, -31), 30, t, 24.0)
	rotor(ci, Vector2(22, -31), 30, t + 0.5, 24.0)


static func _ironcloud(ci: CanvasItem, a) -> void:
	var t: float = P.g(a, "t", 0.0)
	var hp: float = P.g(a, "hp_frac", 1.0)
	# envelope
	var env_c = Vector2(0, -30)
	P.ell(ci, env_c, 96, 34, Color("8c8676"), 2.5)
	P.poly(ci, P.ell_pts(env_c + Vector2(-6, -8), 82, 20, 0.0, 16, PI * 1.08, PI * 1.92), Color("a9a291"), 0.0)
	for i in 7:
		var x = -72.0 + i * 24.0
		var hgt = 34.0 * sqrt(maxf(0.0, 1.0 - pow(x / 96.0, 2)))
		ci.draw_line(Vector2(x, env_c.y - hgt + 2), Vector2(x, env_c.y + hgt - 2), Color("6a6558"), 2.0)
	ci.draw_line(Vector2(-90, -30), Vector2(94, -30), P.BRASS, 2.0)
	# armored nose & tail caps
	P.poly(ci, P.ell_pts(env_c + Vector2(80, 0), 18, 26, 0.0, 12, -PI / 2, PI / 2), P.BRASS, 2.0)
	P.poly(ci, P.pts([Vector2(-92, -36), Vector2(-112, -60), Vector2(-104, -30), Vector2(-112, 0), Vector2(-92, -24)]), P.IRON, 2.0)
	# dorsal swivel flak (weapon 2)
	var fa: float = P.g(a, "aim2", -1.2)
	var fp = Vector2(0, -64)
	P.rect(ci, Rect2(-8, -66, 16, 6), P.IRON_D, 1.5)
	P.circ(ci, fp, 6, P.BRASS, 1.5)
	var atk3: float = P.g(a, "atk3", 0.0)
	_gun(ci, fp, fa, 18, 4.0, atk3, 10.0)
	# rigging
	for x in [-50.0, -20.0, 20.0, 50.0]:
		ci.draw_line(Vector2(x, -2), Vector2(x * 0.7, 20), Color(0.25, 0.2, 0.18), 1.5)
	# gondola
	P.poly(ci, P.pts([Vector2(-64, 18), Vector2(60, 18), Vector2(72, 28), Vector2(60, 48), Vector2(-56, 48), Vector2(-70, 30)]), P.IRON, 2.5)
	P.poly(ci, P.pts([Vector2(-62, 20), Vector2(58, 20), Vector2(66, 27), Vector2(-66, 27)]), P.STEEL, 0.0)
	P.rivets(ci, Vector2(-60, 44), Vector2(62, 44), 14)
	for i in 5:
		P.circ(ci, Vector2(-40 + i * 18, 32), 3.5, Color(1.0, 0.8, 0.4) if fmod(t + i, 3.0) > 0.4 else Color(0.5, 0.4, 0.2), 1.5)
	# broadside cannons (weapons 0 & 1, independently aimed)
	for k in 2:
		var mp = Vector2(38, 44) if k == 0 else Vector2(-30, 44)
		var aim: float = clampf(P.g(a, "aim%d" % k, 1.2), 0.0, 2.9)
		var at: float = P.g(a, "atk" if k == 0 else "atk2", 0.0)
		P.circ(ci, mp, 8, P.IRON_D, 2.0)
		var rec = at * at * 6.0
		P.bar(ci, mp - Vector2(cos(aim), sin(aim)) * rec, aim, 22, 6.0, P.IRON, 1.5)
		ci.draw_line(mp + Vector2(cos(aim), sin(aim)) * (18 - rec) + Vector2(-sin(aim), cos(aim)) * 4, mp + Vector2(cos(aim), sin(aim)) * (18 - rec) - Vector2(-sin(aim), cos(aim)) * 4, P.BRASS, 2.0)
		P.muzzle_flash(ci, mp + Vector2(cos(aim), sin(aim)) * (22 - rec), aim, 16.0, D._flash_strength(at))
	# bridge with captain
	P.rrect(ci, Rect2(40, 4, 22, 16), P.BRASS, 2.0, 3.0)
	P.rect(ci, Rect2(46, 7, 12, 6), Color(0.6, 0.85, 0.95, 0.85), 1.2)
	pilot(ci, a, Vector2(48, 4), 0.55, Color("9a9a9a"))
	# smokestack + engines
	P.rect(ci, Rect2(-50, 4, 8, 16), P.IRON_D, 1.5)
	P.smoke_puff(ci, Vector2(-46, 0), t, 3, Color(0.3, 0.28, 0.27, 0.55))
	for py in [24.0, 40.0]:
		P.rect(ci, Rect2(-82, py - 4, 14, 8), P.IRON_D, 1.5)
		ArtAir.prop(ci, Vector2(-84, py), 11, t + py)
	# hull damage
	if hp < 0.5:
		ci.draw_line(Vector2(-20, -40), Vector2(-4, -22), P.OUT, 2.0)
		ci.draw_line(Vector2(-4, -22), Vector2(6, -34), P.OUT, 2.0)
		P.smoke_puff(ci, Vector2(10, -20), t * 1.3, 3, Color(0.15, 0.13, 0.12, 0.7))
	if hp < 0.25:
		P.glow(ci, Vector2(-30, 36), 12, Color(1, 0.5, 0.1, 0.8))
