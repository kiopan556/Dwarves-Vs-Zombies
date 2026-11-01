class_name ArtMachines
extends RefCounted
## Ground war machines: artillery pieces, armored car, steam tank, mechanical walkers.

const P = preload("res://scripts/art/painter.gd")
const D = preload("res://scripts/art/art_dwarves.gd")


static func draw(ci: CanvasItem, art: String, a) -> void:
	match art:
		"field_cannon": _field_cannon(ci, a)
		"flak_crew": _flak_crew(ci, a)
		"organ_gun": _organ_gun(ci, a)
		"brasshound": _brasshound(ci, a)
		"copperback": _copperback(ci, a)
		"miner_rig": _miner_rig(ci, a)
		"boiler_stomper": _boiler_stomper(ci, a)


static func _spin(a, radius: float) -> float:
	# wheel rotation from distance travelled (walk phase doubles as odometer)
	return P.g(a, "walk", 0.0) * 6.0 / max(radius, 1.0)


static func crew(ci: CanvasItem, a, at: Vector2, coat: Color, helmet: String = "kettle", pose: float = 0.0) -> void:
	P.xf_push(ci, Transform2D(0.0, Vector2(0.82, 0.82), 0.0, at))
	var ca = {"state": "idle", "walk": 0.0, "hurt": P.g(a, "hurt", 0.0), "gag": P.g(a, "gag", 0.0), "atk": 0.0, "t": 0.0}
	D.goof_begin(ci, ca, "crew")
	var s = {"coat": coat, "beard": Color("6b4127"), "helmet": helmet, "helm_col": P.IRON}
	var b = D.body(ci, ca, s)
	D.arm(ci, b.shoulder_f, b.shoulder_f + Vector2(10, 4 + pose * 6), coat.darkened(0.1))
	D.goof_end(ci)
	P.xf_pop(ci)


static func _field_cannon(ci: CanvasItem, a) -> void:
	var atk: float = P.g(a, "atk", 0.0)
	var aim: float = clampf(P.g(a, "aim0", -0.1), -0.6, 0.25)
	var recoil = atk * atk * 7.0
	crew(ci, a, Vector2(-22, 0), P.DEEP_BLUE, "kettle", atk)
	# trail + carriage
	P.poly(ci, P.pts([Vector2(-14, -2), Vector2(4, -16), Vector2(12, -16), Vector2(12, -10), Vector2(-10, 0)]), P.WOOD, 2.0)
	# barrel
	var pivot = Vector2(8 - recoil, -18)
	P.bar(ci, pivot - Vector2(cos(aim), sin(aim)) * 10, aim, 36, 8.0, P.IRON, 2.0)
	var d = Vector2(cos(aim), sin(aim))
	for k in [0.15, 0.55, 0.95]:
		var c = pivot + d * (36.0 * k - 10.0)
		ci.draw_line(c + Vector2(-d.y, d.x) * 5.0, c - Vector2(-d.y, d.x) * 5.0, P.BRASS, 2.5)
	P.circ(ci, pivot - d * 10.0, 4.5, P.IRON_D, 1.5)
	P.muzzle_flash(ci, pivot + d * 26.0, aim, 16.0, D._flash_strength(atk))
	P.wheel(ci, Vector2(8, -10), 11, _spin(a, 11))


static func _flak_crew(ci: CanvasItem, a) -> void:
	var atk: float = P.g(a, "atk", 0.0)
	var aim: float = clampf(P.g(a, "aim0", -1.0), -2.8, -0.2)
	crew(ci, a, Vector2(-20, 0), Color("4e5a3a"), "kettle", atk)
	# ammo crate
	P.rrect(ci, Rect2(14, -10, 14, 10), P.WOOD, 2.0, 1.5)
	ci.draw_line(Vector2(15, -5), Vector2(27, -5), P.BRASS, 1.5)
	# pedestal mount
	P.poly(ci, P.pts([Vector2(-10, 0), Vector2(14, 0), Vector2(8, -12), Vector2(-4, -12)]), P.IRON_D, 2.0)
	P.rect(ci, Rect2(-2, -26, 6, 14), P.IRON, 2.0)
	var pivot = Vector2(1, -28)
	var recoil = atk * atk * 5.0
	var d = Vector2(cos(aim), sin(aim))
	# shield plate
	P.poly(ci, P.pts([pivot + Vector2(-d.y, d.x) * 10 + d * 2, pivot + Vector2(-d.y, d.x) * 10 + d * 10, pivot - Vector2(-d.y, d.x) * 10 + d * 10, pivot - Vector2(-d.y, d.x) * 10 + d * 2]), P.IRON, 2.0)
	P.bar(ci, pivot - d * (6 + recoil), aim, 34, 6.0, P.STEEL, 2.0)
	ci.draw_line(pivot + d * (20 - recoil) + Vector2(-d.y, d.x) * 4, pivot + d * (20 - recoil) - Vector2(-d.y, d.x) * 4, P.BRASS, 2.0)
	P.muzzle_flash(ci, pivot + d * (28 - recoil), aim, 12.0, D._flash_strength(atk))
	P.circ(ci, pivot, 4.5, P.BRASS, 1.5)


static func _organ_gun(ci: CanvasItem, a) -> void:
	var atk: float = P.g(a, "atk", 0.0)
	var t: float = P.g(a, "t", 0.0)
	crew(ci, a, Vector2(-24, 0), Color("6e3b2a"), "cap", sin(t * 10.0) * 0.5 if atk > 0 else 0.0)
	P.poly(ci, P.pts([Vector2(-16, -2), Vector2(2, -14), Vector2(14, -14), Vector2(14, -8), Vector2(-12, 0)]), P.WOOD, 2.0)
	# block of seven barrels
	var base = Vector2(-2, -32)
	P.rrect(ci, Rect2(base.x - 4, base.y - 2, 10, 22), P.WOOD_D, 2.0, 2.0)
	for i in 7:
		var y = base.y + i * 3.0
		var fired = atk > 0.0 and i <= int((1.0 - atk) * 9.0)
		P.bar(ci, Vector2(base.x + 2, y + 1), 0.0, 30, 2.6, P.IRON if not fired else P.IRON_D, 1.0)
		if fired and atk > 0.25 and i == int((1.0 - atk) * 9.0):
			P.muzzle_flash(ci, Vector2(base.x + 32, y + 1), 0.0, 9.0, 1.0)
	ci.draw_line(Vector2(base.x + 14, base.y - 1), Vector2(base.x + 14, base.y + 21), P.BRASS, 2.5)
	# crank
	var ca = t * (12.0 if atk > 0.0 else 0.0)
	ci.draw_line(Vector2(base.x - 6, base.y + 10), Vector2(base.x - 6, base.y + 10) + Vector2(cos(ca), sin(ca)) * 6, P.STEEL, 2.0)
	P.wheel(ci, Vector2(8, -10), 11, _spin(a, 11))


static func _brasshound(ci: CanvasItem, a) -> void:
	var t: float = P.g(a, "t", 0.0)
	var atk: float = P.g(a, "atk", 0.0)
	var moving: bool = P.g(a, "state", "") == "move"
	var shake = sin(t * 40.0) * 0.6 if moving else 0.0
	var spin = _spin(a, 10)
	# chassis
	P.poly(ci, P.pts([Vector2(-34, -12 + shake), Vector2(-30, -30 + shake), Vector2(-10, -36 + shake), Vector2(22, -36 + shake), Vector2(34, -26 + shake), Vector2(36, -12 + shake)]), P.BRASS, 2.0)
	P.poly(ci, P.pts([Vector2(-30, -28 + shake), Vector2(-10, -34 + shake), Vector2(20, -34 + shake), Vector2(26, -30 + shake), Vector2(-28, -24 + shake)]), P.BRASS.lightened(0.2), 0.0)
	P.rivets(ci, Vector2(-30, -16 + shake), Vector2(34, -16 + shake), 9, P.COPPER)
	P.rect(ci, Rect2(14, -30 + shake, 10, 5), P.COAL, 1.5)  # vision slit
	# exhaust
	P.bar(ci, Vector2(-32, -20 + shake), PI + 0.2, 8, 4, P.IRON_D, 1.5)
	if moving:
		P.smoke_puff(ci, Vector2(-42, -20), t, 3)
	# turret
	var tp = Vector2(2, -40 + shake)
	P.poly(ci, P.ell_pts(tp, 12, 8, 0.0, 12, PI, TAU), P.COPPER, 2.0)
	P.rect(ci, Rect2(tp.x - 12, tp.y - 1, 24, 4), P.COPPER_D, 1.5)
	var aim: float = clampf(P.g(a, "aim0", 0.0), -0.4, 0.4)
	P.bar(ci, tp + Vector2(6, -3), aim, 22, 3.0, P.IRON_D, 1.5)
	if atk > 0.6:
		P.muzzle_flash(ci, tp + Vector2(6, -3) + Vector2(cos(aim), sin(aim)) * 22, aim, 8.0, (atk - 0.6) * 2.5)
	# commander head
	ci.draw_set_transform(tp + Vector2(-5, -6), 0.0, Vector2(0.6, 0.6))
	D.dwarf_head(ci, a, Vector2.ZERO, {"beard": Color("a5532a"), "helmet": "goggle_cap", "helm_col": P.LEATHER})
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# wheels
	P.wheel(ci, Vector2(-20, -10), 10, spin, P.COAL, P.BRASS, 5)
	P.wheel(ci, Vector2(22, -10), 10, spin, P.COAL, P.BRASS, 5)


static func _copperback(ci: CanvasItem, a) -> void:
	var t: float = P.g(a, "t", 0.0)
	var atk: float = P.g(a, "atk", 0.0)
	var atk2: float = P.g(a, "atk2", 0.0)
	var moving: bool = P.g(a, "state", "") == "move"
	var shake = sin(t * 34.0) * 0.7 if moving else 0.0
	var spin = _spin(a, 7)
	# track belt
	P.rrect(ci, Rect2(-46, -20, 92, 20), P.COAL, 2.0, 9.0)
	for i in 7:
		P.wheel(ci, Vector2(-36 + i * 12, -10), 7, spin, P.IRON_D, P.BRASS, 4)
	var off = fmod(P.g(a, "walk", 0.0) * 3.0, 6.0)
	for i in 15:
		var x = -44.0 + i * 6.0 + off
		if x < 44.0:
			ci.draw_line(Vector2(x, -20), Vector2(x, -18), P.IRON, 2.0)
			ci.draw_line(Vector2(x, 0), Vector2(x, -2), P.IRON, 2.0)
	# hull
	var y = -2.0 + shake
	P.poly(ci, P.pts([Vector2(-48, -18 + y), Vector2(-42, -38 + y), Vector2(28, -40 + y), Vector2(50, -26 + y), Vector2(50, -18 + y)]), P.COPPER, 2.0)
	P.poly(ci, P.pts([Vector2(-42, -36 + y), Vector2(26, -38 + y), Vector2(34, -33 + y), Vector2(-40, -31 + y)]), P.COPPER.lightened(0.18), 0.0)
	P.rivets(ci, Vector2(-44, -22 + y), Vector2(48, -22 + y), 12, P.BRASS)
	# smokestack
	P.rect(ci, Rect2(-38, -54 + y, 8, 16), P.IRON_D, 2.0)
	P.rect(ci, Rect2(-40, -57 + y, 12, 4), P.BRASS, 1.5)
	P.smoke_puff(ci, Vector2(-34, -60 + y), t, 4 if moving else 2, Color(0.3, 0.28, 0.27, 0.6))
	# turret with main cannon (weapon 0) and coax MG (weapon 1)
	var tp = Vector2(6, -46 + y)
	P.poly(ci, P.pts([tp + Vector2(-20, 8), tp + Vector2(-16, -8), tp + Vector2(12, -9), tp + Vector2(20, 0), tp + Vector2(18, 8)]), P.COPPER_D.lightened(0.15), 2.0)
	P.rivets(ci, tp + Vector2(-16, -5), tp + Vector2(12, -6), 5)
	var aim: float = clampf(P.g(a, "aim0", 0.0), -0.35, 0.3)
	var recoil = atk * atk * 8.0
	var piv = tp + Vector2(16, 0)
	P.bar(ci, piv - Vector2(cos(aim), sin(aim)) * recoil, aim, 36, 6.0, P.IRON, 2.0)
	ci.draw_line(piv + Vector2(cos(aim), sin(aim)) * (34 - recoil) + Vector2(0, -4), piv + Vector2(cos(aim), sin(aim)) * (34 - recoil) + Vector2(0, 4), P.BRASS, 3.0)
	P.muzzle_flash(ci, piv + Vector2(cos(aim), sin(aim)) * (37 - recoil), aim, 18.0, D._flash_strength(atk))
	var aim2: float = clampf(P.g(a, "aim1", 0.0), -0.4, 0.4)
	P.bar(ci, tp + Vector2(14, 5), aim2, 16, 2.4, P.IRON_D, 1.2)
	if atk2 > 0.6:
		P.muzzle_flash(ci, tp + Vector2(14, 5) + Vector2(cos(aim2), sin(aim2)) * 16, aim2, 7.0, (atk2 - 0.6) * 2.5)
	# commander in hatch
	ci.draw_set_transform(tp + Vector2(-6, -13), 0.0, Vector2(0.6, 0.6))
	D.dwarf_head(ci, a, Vector2.ZERO, {"beard": Color("c9a050"), "helmet": "kettle", "helm_col": P.IRON})
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	P.rect(ci, Rect2(tp.x - 13, tp.y - 9, 14, 3), P.IRON_D, 1.5)


## Two-segment mechanical leg; returns foot point.
static func mech_leg(ci: CanvasItem, hip: Vector2, phase: float, moving: bool, thigh: float, shin: float, w: float, col: Color, stride: float = 0.55) -> Vector2:
	var sw = sin(phase) * stride if moving else 0.0
	var lift = maxf(0.0, cos(phase)) * 0.5 if moving else 0.0
	var a1 = PI / 2 + sw - lift * 0.4
	var knee = hip + Vector2(cos(a1), sin(a1)) * thigh
	var a2 = PI / 2 + sw * 0.4 + lift * 0.9
	var foot = knee + Vector2(cos(a2), sin(a2)) * shin
	P.limb(ci, hip, knee, w, col)
	# piston alongside thigh
	var mid = hip.lerp(knee, 0.5) + Vector2(4, 0)
	ci.draw_line(hip + Vector2(5, 2), mid, P.STEEL, 2.5)
	P.limb(ci, knee, foot, w * 0.8, col.darkened(0.15))
	P.circ(ci, knee, w * 0.55, P.BRASS, 1.5)
	P.poly(ci, P.pts([foot + Vector2(-9, 2), foot + Vector2(-6, -4), foot + Vector2(8, -4), foot + Vector2(12, 2)]), P.IRON_D, 2.0)
	return foot


static func _miner_rig(ci: CanvasItem, a) -> void:
	var t: float = P.g(a, "t", 0.0)
	var w: float = P.g(a, "walk", 0.0)
	var moving: bool = P.g(a, "state", "") == "move"
	var atk: float = P.g(a, "atk", 0.0)
	var bob = absf(sin(w)) * 3.0 if moving else 0.0
	var hip = Vector2(-2, -42 - bob)
	# far leg then near leg
	mech_leg(ci, hip + Vector2(-6, 0), w + PI, moving, 22, 22, 7, P.IRON_D)
	# boiler on back
	P.rrect(ci, Rect2(-30, -78 - bob, 16, 30), P.COPPER, 2.0, 6.0)
	P.rivets(ci, Vector2(-28, -70 - bob), Vector2(-16, -70 - bob), 3)
	P.rect(ci, Rect2(-27, -88 - bob, 6, 10), P.IRON_D, 1.5)
	P.smoke_puff(ci, Vector2(-24, -92 - bob), t, 3)
	# cockpit cage
	var cp = Vector2(-14, -80 - bob)
	P.rrect(ci, Rect2(cp.x, cp.y, 34, 34), P.IRON, 2.0, 4.0)
	P.rrect(ci, Rect2(cp.x + 4, cp.y + 4, 26, 18), Color(0.22, 0.2, 0.2), 1.5, 3.0)
	ci.draw_set_transform(cp + Vector2(16, 16), 0.0, Vector2(0.65, 0.65))
	D.dwarf_head(ci, a, Vector2.ZERO, {"beard": Color("a5532a"), "helmet": "miner", "helm_col": Color("9a8a52")})
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i in 3:
		ci.draw_line(cp + Vector2(10 + i * 7, 4), cp + Vector2(10 + i * 7, 22), P.IRON_D, 1.5)
	P.rivets(ci, cp + Vector2(2, 31), cp + Vector2(32, 31), 6)
	mech_leg(ci, hip + Vector2(4, 0), w, moving, 22, 22, 8, P.IRON)
	# drill arm
	var thrust = sin(clampf(atk, 0.0, 1.0) * PI) * 8.0
	var sh = cp + Vector2(30, 22)
	P.limb(ci, sh, sh + Vector2(10 + thrust, 4), 7, P.IRON_D)
	var dp = sh + Vector2(12 + thrust, 4)
	var spin = t * (40.0 if atk > 0.0 else 6.0)
	P.poly(ci, P.pts([dp + Vector2(0, -9), dp + Vector2(26, 0), dp + Vector2(0, 9)]), P.STEEL, 2.0)
	for i in 4:
		var k = fmod(spin * 0.15 + i * 0.25, 1.0)
		var x = dp.x + k * 22
		var hgt = 9.0 * (1.0 - k)
		ci.draw_line(Vector2(x, dp.y - hgt), Vector2(x + 4, dp.y + hgt), P.IRON_D, 1.5)
	P.circ(ci, dp, 5, P.BRASS, 1.5)


static func _boiler_stomper(ci: CanvasItem, a) -> void:
	var t: float = P.g(a, "t", 0.0)
	var w: float = P.g(a, "walk", 0.0)
	var moving: bool = P.g(a, "state", "") == "move"
	var atk: float = P.g(a, "atk", 0.0)
	var wind: float = P.g(a, "windup", 0.0)
	var atk2: float = P.g(a, "atk2", 0.0)
	var bob = absf(sin(w)) * 4.0 if moving else 0.0
	var crouch = wind * 6.0 - (atk * 4.0 if atk > 0.5 else 0.0)
	var hip = Vector2(0, -50 - bob + crouch)
	mech_leg(ci, hip + Vector2(-10, 0), w + PI, moving, 26, 26, 10, P.IRON_D, 0.45)
	# boiler body
	var c = Vector2(0, -78 - bob + crouch)
	P.ell(ci, c, 34, 30, P.COPPER, 2.5)
	P.poly(ci, P.ell_pts(c + Vector2(-4, -6), 26, 20, 0.0, 14, PI * 1.05, PI * 1.6), P.COPPER.lightened(0.2), 0.0)
	for i in 3:
		ci.draw_arc(c, 34 - i * 0.5, -1.2 + i * 0.9, -0.9 + i * 0.9, 6, P.BRASS, 3.0)
	P.rivets(ci, c + Vector2(-30, 8), c + Vector2(30, 8), 9)
	# gauge
	P.circ(ci, c + Vector2(14, -10), 7, P.BRASS, 2.0)
	ci.draw_circle(c + Vector2(14, -10), 5, Color("efe6cf"))
	var needle = -2.2 + 2.0 * (0.5 + 0.5 * sin(t * 2.0)) + (1.0 if atk2 > 0 else 0.0)
	ci.draw_line(c + Vector2(14, -10), c + Vector2(14, -10) + Vector2(cos(needle), sin(needle)) * 4.5, Color(0.7, 0.1, 0.1), 1.5)
	# furnace window
	P.rrect(ci, Rect2(c.x - 18, c.y + 2, 14, 10), P.COAL, 2.0, 2.0)
	var fl = 0.6 + 0.4 * sin(t * 9.0)
	ci.draw_rect(Rect2(c.x - 16, c.y + 4, 10, 6), Color(1.0, 0.5 + 0.2 * fl, 0.1, 0.9))
	# smokestacks
	for sx in [-14.0, -2.0]:
		P.rect(ci, Rect2(c.x + sx, c.y - 44, 7, 16), P.IRON_D, 2.0)
		P.smoke_puff(ci, Vector2(c.x + sx + 3, c.y - 48), t + sx, 3, Color(0.35, 0.33, 0.32, 0.6))
	# pilot
	ci.draw_set_transform(c + Vector2(-2, -30), 0.0, Vector2(0.62, 0.62))
	D.dwarf_head(ci, a, Vector2.ZERO, {"beard": Color("3a2f2a"), "helmet": "great", "helm_col": P.IRON})
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# steam vent nozzle (weapon 1)
	var nz = c + Vector2(30, 10)
	P.bar(ci, nz, 0.25, 14, 7, P.IRON, 2.0)
	if atk2 > 0.2:
		for i in 4:
			var k = fmod(t * 3.0 + i * 0.25, 1.0)
			ci.draw_circle(nz + Vector2(16 + k * 60, 4 + k * 12), 4 + k * 10, Color(1, 1, 1, 0.35 * (1.0 - k) * atk2))
	var lift = wind * 18.0
	mech_leg(ci, hip + Vector2(10, -lift), w, moving and wind <= 0.0, 26, 26 - lift * 0.3, 11, P.IRON, 0.45)
	# piston arms
	P.limb(ci, c + Vector2(-30, 4), c + Vector2(-40, 22), 6, P.IRON_D)
	ci.draw_line(c + Vector2(-26, -4), c + Vector2(-38, 18), P.STEEL, 2.0)
