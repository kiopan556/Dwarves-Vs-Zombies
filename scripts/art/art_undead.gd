class_name ArtUndead
extends RefCounted
## Undead: broken, asymmetrical silhouettes, decaying flesh, bone, necromantic glows.
## Drawn facing right in local space; the unit node mirrors them to face the dwarves.

const P = preload("res://scripts/art/painter.gd")


static func draw(ci: CanvasItem, art: String, a) -> void:
	match art:
		"rotter": _zombie(ci, a, {})
		"zombie_miner": _zombie_miner(ci, a)
		"grave_crawler": _crawler(ci, a)
		"plague_runner": _runner(ci, a)
		"skeleton": _skeleton(ci, a, "sword")
		"bone_shield": _skeleton(ci, a, "shield")
		"bone_archer": _skeleton(ci, a, "bow")
		"grave_knight": _grave_knight(ci, a)
		"rot_spitter": _spitter(ci, a)
		"necromancer": _necromancer(ci, a)
		"flesh_hulk": _hulk(ci, a)
		"carrion_bat": _bat(ci, a)
		"plague_shrieker": _shrieker(ci, a)
		"bone_spire": _spire(ci, a)
		"mine_maw": _mine_maw(ci, a)


static func _eye(ci: CanvasItem, at: Vector2, col: Color = P.NECRO, r: float = 1.8) -> void:
	P.glow(ci, at, r * 3.5, Color(col.r, col.g, col.b, 0.6), 2)
	ci.draw_circle(at, r, col)


static func _legs(ci: CanvasItem, a, col: Color, shamble: float = 1.0, bony: bool = false) -> float:
	var moving: bool = P.g(a, "state", "") == "move"
	var w: float = P.g(a, "walk", 0.0)
	var drag = sin(w) * 4.0 * shamble if moving else 0.0
	var bob = absf(sin(w)) * 2.0 if moving else 0.0
	var wdt = 3.0 if bony else 5.0
	# one leg drags behind (asymmetry)
	P.limb(ci, Vector2(-3, -16 + bob), Vector2(-6 + drag, -1), wdt, col.darkened(0.2))
	P.limb(ci, Vector2(3, -16 + bob), Vector2(5 - drag * 0.6, -1), wdt, col)
	P.poly(ci, P.pts([Vector2(-10 + drag, -3), Vector2(-3 + drag, -3), Vector2(-2 + drag, 1), Vector2(-11 + drag, 1)]), col.darkened(0.35), 1.5)
	P.poly(ci, P.pts([Vector2(2 - drag * 0.6, -3), Vector2(10 - drag * 0.6, -3), Vector2(11 - drag * 0.6, 1), Vector2(2 - drag * 0.6, 1)]), col.darkened(0.25), 1.5)
	return bob


static func _zombie(ci: CanvasItem, a, s: Dictionary) -> Dictionary:
	var t: float = P.g(a, "t", 0.0)
	var atk: float = P.g(a, "atk", 0.0)
	var flesh: Color = s.get("flesh", P.FLESH)
	var bob = _legs(ci, a, s.get("pants", Color("3e3a36")))
	var y = -bob
	var lean = 6.0
	# torso hunched forward, torn shirt
	var torso = P.pts([Vector2(-8, -16 + y), Vector2(-9, -28 + y), Vector2(-4 + lean * 0.5, -36 + y), Vector2(6 + lean, -35 + y), Vector2(9 + lean * 0.4, -24 + y), Vector2(7, -16 + y)])
	P.poly(ci, torso, flesh, 2.0)
	P.poly(ci, P.pts([Vector2(-8, -17 + y), Vector2(-9, -26 + y), Vector2(-3, -24 + y), Vector2(1, -30 + y), Vector2(4, -22 + y), Vector2(8, -25 + y), Vector2(7, -17 + y)]), s.get("cloth", P.CLOTH_U), 1.5)
	ci.draw_line(Vector2(0 + lean * 0.4, -33 + y), Vector2(4 + lean * 0.4, -28 + y), P.FLESH_D, 1.5)  # rib gash
	# back arm dangling
	var sway = sin(t * 2.0) * 2.0
	P.limb(ci, Vector2(-2 + lean * 0.4, -32 + y), Vector2(-4 + sway, -18 + y), 4.0, flesh.darkened(0.2))
	# head lolling
	var head = Vector2(8 + lean, -40 + y + sin(t * 1.7) * 1.0)
	P.poly(ci, P.pts([head + Vector2(-6, -6), head + Vector2(3, -8), head + Vector2(8, -3), head + Vector2(7, 4), head + Vector2(2, 7), head + Vector2(-5, 5)]), flesh.lightened(0.05), 2.0)
	if s.has("hat"):
		pass
	else:
		ci.draw_line(head + Vector2(-5, -6), head + Vector2(-1, -8), P.FLESH_D, 2.0)
	_eye(ci, head + Vector2(4, -2), s.get("eye", Color(0.85, 0.95, 0.5)), 1.5)
	# open jaw
	var jaw = 2.0 + atk * 3.0
	P.poly(ci, P.pts([head + Vector2(1, 3), head + Vector2(8, 3), head + Vector2(6, 4 + jaw), head + Vector2(1, 5 + jaw * 0.5)]), Color("2a2420"), 1.2)
	# front arm reaching / clawing
	var reach = lerpf(-0.2, 0.5, clampf(atk, 0.0, 1.0))
	var sh = Vector2(4 + lean * 0.6, -31 + y)
	var hand = sh + Vector2(cos(reach), sin(reach)) * 14.0
	P.limb(ci, sh, hand, 4.5, flesh)
	for i in 3:
		ci.draw_line(hand, hand + Vector2(4, -2 + i * 2), P.OUT, 1.5)
	return {"head": head, "hand": hand, "y": y}


static func _zombie_miner(ci: CanvasItem, a) -> void:
	if P.g(a, "state", "") == "burrowed":
		_mound(ci, a, 16.0)
		return
	var r = _zombie(ci, a, {"flesh": Color("8f9478"), "cloth": Color("5a4630"), "eye": P.NECRO})
	var head: Vector2 = r.head
	# dented miner helmet with dead lamp
	P.poly(ci, P.ell_pts(head + Vector2(0, -4), 9, 7, -0.2, 12, PI, TAU), Color("6a6040"), 2.0)
	P.circ(ci, head + Vector2(6, -9), 2.6, Color("3a3426"), 1.2)
	# rusted pick in hand
	var hand: Vector2 = r.hand
	P.bar(ci, hand + Vector2(-2, 6), -1.2, 20, 2.5, P.WOOD_D, 1.2)
	var tip = hand + Vector2(-2, 6) + Vector2(cos(-1.2), sin(-1.2)) * 18
	P.poly(ci, P.pts([tip + Vector2(-8, 2), tip + Vector2(0, -2), tip + Vector2(8, 3), tip + Vector2(0, 1)]), P.RUST, 1.5)


static func _mound(ci: CanvasItem, a, size: float) -> void:
	var t: float = P.g(a, "t", 0.0)
	P.poly(ci, P.ell_pts(Vector2(0, 0), size, size * 0.5, 0.0, 12, PI, TAU), Color("5b4a36"), 2.0)
	for i in 4:
		var ph = fmod(t * 2.0 + i * 0.25, 1.0)
		ci.draw_circle(Vector2(-size + ph * size * 2.0, -size * 0.4 - sin(ph * PI) * 8.0), 2.0, Color("7a6448"))
	_eye(ci, Vector2(size * 0.4, -size * 0.3), P.NECRO, 1.2)


static func _crawler(ci: CanvasItem, a) -> void:
	var t: float = P.g(a, "t", 0.0)
	var w: float = P.g(a, "walk", 0.0)
	var atk: float = P.g(a, "atk", 0.0)
	# entrails trail
	ci.draw_line(Vector2(-14, -2), Vector2(-22, 0), P.BLOOD_U, 3.0)
	P.poly(ci, P.pts([Vector2(-14, 0), Vector2(-15, -8), Vector2(-4, -13), Vector2(8, -12), Vector2(10, -4), Vector2(2, 0)]), P.FLESH_D, 2.0)
	# spine ridge
	for i in 4:
		ci.draw_circle(Vector2(-10 + i * 5, -11 + absf(i - 1.5)), 1.6, P.BONE)
	var head = Vector2(13, -9)
	P.circ(ci, head, 6, P.FLESH, 2.0)
	_eye(ci, head + Vector2(2, -1), Color(0.9, 1.0, 0.5), 1.4)
	P.poly(ci, P.pts([head + Vector2(1, 2), head + Vector2(7, 2), head + Vector2(5, 4 + atk * 3)]), Color("2a2420"), 1.0)
	# clawing arms
	var r1 = sin(w * 1.5) * 0.6
	P.limb(ci, Vector2(6, -9), Vector2(14 + cos(r1) * 6, -1 + sin(r1) * 2), 3.5, P.FLESH)
	P.limb(ci, Vector2(2, -9), Vector2(10 - cos(r1) * 6, 0), 3.5, P.FLESH_D)


static func _runner(ci: CanvasItem, a) -> void:
	var t: float = P.g(a, "t", 0.0)
	var moving: bool = P.g(a, "state", "") == "move"
	var w: float = P.g(a, "walk", 0.0) * 1.4
	var bob = absf(sin(w)) * 3.0 if moving else 0.0
	var y = -bob
	# sprinting legs
	var s1 = sin(w) * 7.0 if moving else 0.0
	P.limb(ci, Vector2(-2, -18 + y), Vector2(-4 - s1, -1), 4.0, P.FLESH_D)
	P.limb(ci, Vector2(2, -18 + y), Vector2(4 + s1, -1), 4.0, P.FLESH)
	# bloated belly, leaning forward
	P.ell(ci, Vector2(4, -26 + y), 11, 10, Color("9aa86a"), 2.0, 0.3)
	for b in [Vector2(6, -22), Vector2(0, -28), Vector2(10, -29)]:
		var pulse = 1.6 + sin(t * 5.0 + b.x) * 0.5
		P.circ(ci, b + Vector2(0, y), pulse + 1.0, P.SICKLY, 1.2)
	var head = Vector2(16, -36 + y)
	P.circ(ci, head, 6.5, P.FLESH_L, 2.0)
	_eye(ci, head + Vector2(3, -1), Color(1, 0.9, 0.3), 1.6)
	P.poly(ci, P.pts([head + Vector2(1, 2), head + Vector2(8, 2), head + Vector2(6, 6)]), Color("2a2420"), 1.0)
	P.limb(ci, Vector2(8, -32 + y), Vector2(18 - s1 * 0.5, -22 + y), 3.5, P.FLESH)
	P.limb(ci, Vector2(0, -32 + y), Vector2(-8 + s1 * 0.5, -24 + y), 3.5, P.FLESH_D)


static func _bone(ci: CanvasItem, a: Vector2, b: Vector2, w: float = 3.0) -> void:
	ci.draw_line(a, b, P.OUT, w + 2.5)
	ci.draw_line(a, b, P.BONE, w)
	ci.draw_circle(a, w * 0.7, P.BONE_D)
	ci.draw_circle(b, w * 0.7, P.BONE_D)


static func _skull(ci: CanvasItem, at: Vector2, atk: float, helm: Color = Color(0, 0, 0, 0)) -> void:
	P.poly(ci, P.pts([at + Vector2(-6, -6), at + Vector2(3, -8), at + Vector2(8, -3), at + Vector2(7, 3), at + Vector2(2, 4), at + Vector2(-5, 3)]), P.BONE, 2.0)
	ci.draw_circle(at + Vector2(3, -2), 2.4, P.OUT)
	_eye(ci, at + Vector2(3, -2), P.NECRO, 1.0)
	ci.draw_line(at + Vector2(6, 1), at + Vector2(7, 3), P.OUT, 1.5)
	# jaw
	P.poly(ci, P.pts([at + Vector2(-1, 4), at + Vector2(7, 4 + atk * 2), at + Vector2(6, 7 + atk * 3), at + Vector2(0, 7)]), P.BONE_D, 1.5)
	if helm.a > 0:
		P.poly(ci, P.ell_pts(at + Vector2(0, -3), 8, 7, -0.15, 10, PI, TAU), helm, 2.0)


static func _skeleton(ci: CanvasItem, a, kind: String) -> void:
	var t: float = P.g(a, "t", 0.0)
	var atk: float = P.g(a, "atk", 0.0)
	var bob = _legs(ci, a, P.BONE, 0.6, true)
	var y = -bob
	# pelvis + spine + ribs
	P.poly(ci, P.pts([Vector2(-5, -17 + y), Vector2(5, -17 + y), Vector2(3, -13 + y), Vector2(-3, -13 + y)]), P.BONE_D, 1.5)
	_bone(ci, Vector2(0, -16 + y), Vector2(2, -34 + y), 2.5)
	for i in 4:
		var ry = -31.0 + i * 3.6 + y
		ci.draw_arc(Vector2(2, ry + 2), 7.0 - i * 0.6, PI * 1.05, PI * 1.95, 6, P.OUT, 3.5)
		ci.draw_arc(Vector2(2, ry + 2), 7.0 - i * 0.6, PI * 1.05, PI * 1.95, 6, P.BONE, 2.0)
	# tattered belt cloth
	P.poly(ci, P.pts([Vector2(-6, -18 + y), Vector2(6, -18 + y), Vector2(4, -10 + y), Vector2(1, -13 + y), Vector2(-3, -9 + y)]), Color("4a3a5a"), 1.5)
	var helm = Color(0, 0, 0, 0)
	if kind == "shield":
		helm = Color("5a5a52")
	var head = Vector2(4, -41 + y)
	_skull(ci, head, atk, helm)
	var sh = Vector2(4, -32 + y)
	match kind:
		"sword":
			_bone(ci, Vector2(-1, -32 + y), Vector2(-3 + sin(t * 2.0), -21 + y), 2.2)
			var ang = lerpf(0.4, -1.8, clampf(atk * 1.3, 0.0, 1.0)) if atk > 0.0 else 0.3
			var hand = sh + Vector2(cos(ang), sin(ang)) * 10
			_bone(ci, sh, hand, 2.2)
			var sa = ang - 0.9
			P.bar(ci, hand, sa, 18, 3.0, P.RUST, 1.2)
			ci.draw_line(hand + Vector2(cos(sa + PI / 2), sin(sa + PI / 2)) * 4, hand - Vector2(cos(sa + PI / 2), sin(sa + PI / 2)) * 4, P.BONE_D, 2.0)
		"shield":
			var push = sin(clampf(atk, 0.0, 1.0) * PI) * 4.0
			_bone(ci, Vector2(-1, -32 + y), Vector2(-5, -22 + y), 2.2)
			# coffin-lid shield with violet rune
			var sx = 10.0 + push
			P.poly(ci, P.pts([Vector2(sx, -48 + y), Vector2(sx + 7, -50 + y), Vector2(sx + 11, -36 + y), Vector2(sx + 9, -6 + y), Vector2(sx + 2, -4 + y), Vector2(sx - 2, -36 + y)]), Color("3e3029"), 2.0)
			ci.draw_line(Vector2(sx + 4, -40 + y), Vector2(sx + 5, -16 + y), P.VIOLET.lightened(0.3), 2.0)
			ci.draw_line(Vector2(sx, -30 + y), Vector2(sx + 9, -30 + y), P.VIOLET.lightened(0.3), 2.0)
			_bone(ci, sh, Vector2(sx, -28 + y), 2.2)
		"bow":
			var draw_k = 1.0 - clampf(atk, 0.0, 1.0)
			var bow_c = sh + Vector2(14, 0)
			ci.draw_arc(bow_c, 14, -1.3, 1.3, 10, P.OUT, 4.0)
			ci.draw_arc(bow_c, 14, -1.3, 1.3, 10, P.WOOD_D, 2.5)
			var top = bow_c + Vector2(cos(-1.3), sin(-1.3)) * 14
			var bot = bow_c + Vector2(cos(1.3), sin(1.3)) * 14
			var pull = bow_c + Vector2(-4 - draw_k * 9, 0)
			ci.draw_line(top, pull, Color(0.85, 0.85, 0.8), 1.0)
			ci.draw_line(pull, bot, Color(0.85, 0.85, 0.8), 1.0)
			_bone(ci, sh, bow_c + Vector2(2, 0), 2.2)
			_bone(ci, Vector2(-1, -32 + y), pull, 2.2)
			if draw_k > 0.3:
				ci.draw_line(pull, pull + Vector2(22, 0), P.BONE_D, 1.5)


static func _grave_knight(ci: CanvasItem, a) -> void:
	var atk: float = P.g(a, "atk", 0.0)
	var wind: float = P.g(a, "windup", 0.0)
	var bob = _legs(ci, a, Color("4a4d50"), 0.4)
	var y = -bob
	# corroded plate body
	P.poly(ci, P.pts([Vector2(-11, -16 + y), Vector2(-13, -32 + y), Vector2(-8, -42 + y), Vector2(8, -43 + y), Vector2(13, -33 + y), Vector2(11, -16 + y)]), Color("5a5e5a"), 2.0)
	P.poly(ci, P.pts([Vector2(-9, -38 + y), Vector2(8, -39 + y), Vector2(10, -33 + y), Vector2(-10, -32 + y)]), Color("6e7468"), 0.0)
	for p in [Vector2(-6, -28), Vector2(5, -22), Vector2(0, -35)]:
		ci.draw_circle(p + Vector2(0, y), 2.5, P.RUST)
	# tattered cape
	P.poly(ci, P.pts([Vector2(-8, -42 + y), Vector2(-16, -26 + y), Vector2(-14, -8 + y), Vector2(-10, -14 + y), Vector2(-8, -6 + y), Vector2(-5, -20 + y)]), P.VIOLET_D, 1.5)
	# horned helm
	var head = Vector2(3, -49 + y)
	P.poly(ci, P.pts([head + Vector2(-8, 6), head + Vector2(-9, -5), head + Vector2(-3, -10), head + Vector2(6, -10), head + Vector2(10, -3), head + Vector2(9, 6)]), Color("4a4d50"), 2.0)
	P.poly(ci, P.pts([head + Vector2(-6, -7), head + Vector2(-14, -16), head + Vector2(-4, -10)]), P.BONE_D, 1.5)
	P.poly(ci, P.pts([head + Vector2(5, -8), head + Vector2(12, -18), head + Vector2(8, -7)]), P.BONE_D, 1.5)
	P.rect(ci, Rect2(head.x - 1, head.y - 3, 10, 2.5), P.COAL, 0.0)
	_eye(ci, head + Vector2(6, -2), P.NECRO, 1.4)
	# greatsword: raised during windup, swung down on attack
	var ang = -2.4 if wind > 0.0 else (lerpf(0.5, -2.4, clampf(atk, 0.0, 1.0)) if atk > 0.0 else 0.6)
	var sh = Vector2(6, -38 + y)
	var hand = sh + Vector2(cos(ang + 0.6), sin(ang + 0.6)) * 10
	P.limb(ci, sh, hand, 6, Color("4a4d50"))
	P.bar(ci, hand, ang, 34, 5.0, Color("8d948d"), 2.0)
	ci.draw_line(hand + Vector2(cos(ang), sin(ang)) * 4 + Vector2(-sin(ang), cos(ang)) * 6, hand + Vector2(cos(ang), sin(ang)) * 4 - Vector2(-sin(ang), cos(ang)) * 6, P.RUST, 3.0)
	if wind > 0.0:
		P.glow(ci, hand + Vector2(cos(ang), sin(ang)) * 30, 10, Color(0.5, 1.0, 0.6, 0.6 * wind))


static func _spitter(ci: CanvasItem, a) -> void:
	var t: float = P.g(a, "t", 0.0)
	var atk: float = P.g(a, "atk", 0.0)
	var bob = _legs(ci, a, Color("3e3a36"))
	var y = -bob
	var swell = 1.0 + sin(t * 3.0) * 0.06 + (0.15 if atk > 0.8 else 0.0)
	P.ell(ci, Vector2(0, -27 + y), 12 * swell, 13 * swell, Color("7f9168"), 2.0)
	for b in [Vector2(-4, -30), Vector2(5, -22), Vector2(-6, -20)]:
		P.circ(ci, b + Vector2(0, y), 2.3, Color("b7c25a"), 1.0)
	# swollen throat sac + head tilted back
	var head = Vector2(10, -42 + y)
	P.ell(ci, head + Vector2(-2, 6), 7 * swell, 6 * swell, Color("a6b46a"), 2.0)
	P.circ(ci, head, 6.5, P.FLESH, 2.0)
	_eye(ci, head + Vector2(2, -3), Color(0.9, 1.0, 0.4), 1.4)
	var open = 2.0 + atk * 5.0
	P.poly(ci, P.pts([head + Vector2(2, 1), head + Vector2(9, -1 - open * 0.5), head + Vector2(9, 3 + open * 0.3)]), Color("2a2420"), 1.0)
	if atk > 0.7:
		ci.draw_circle(head + Vector2(10, 0), 3.0, Color(0.6, 0.95, 0.2, 0.9))
	# drip
	var dk = fmod(t * 1.3, 1.0)
	ci.draw_circle(head + Vector2(6, 4 + dk * 10), 1.4, Color(0.6, 0.9, 0.2, 1.0 - dk))
	P.limb(ci, Vector2(-6, -30 + y), Vector2(-10, -18 + y), 3.5, P.FLESH_D)


static func _necromancer(ci: CanvasItem, a) -> void:
	var t: float = P.g(a, "t", 0.0)
	var atk: float = P.g(a, "atk", 0.0)
	var cast: float = P.g(a, "special", 0.0)
	var moving: bool = P.g(a, "state", "") == "move"
	var sway = sin(P.g(a, "walk", 0.0)) * 2.0 if moving else 0.0
	# ground glyph while raising the dead
	if cast > 0.0:
		ci.draw_arc(Vector2(0, 0), 26, 0, TAU, 24, Color(0.43, 1.0, 0.55, 0.6 * cast), 2.0)
		ci.draw_arc(Vector2(0, 0), 18, t * 2.0, t * 2.0 + TAU * 0.8, 16, Color(0.6, 0.3, 0.9, 0.7 * cast), 2.0)
	# robe (no visible legs) — tall hooded silhouette
	P.poly(ci, P.pts([Vector2(-12 + sway, 0), Vector2(-8, -30), Vector2(-6, -44), Vector2(0, -54), Vector2(8, -50), Vector2(10, -34), Vector2(14 - sway, 0), Vector2(6, -4), Vector2(1, 0), Vector2(-4, -4)]), P.VIOLET_D, 2.0)
	P.poly(ci, P.pts([Vector2(-6, -44), Vector2(0, -54), Vector2(8, -50), Vector2(6, -40), Vector2(-2, -40)]), P.VIOLET, 0.0)
	ci.draw_line(Vector2(2, -38), Vector2(4, -2), Color("2a1838"), 2.0)
	# face in shadow + eyes
	P.poly(ci, P.pts([Vector2(0, -48), Vector2(7, -47), Vector2(6, -40), Vector2(1, -40)]), Color("1a1220"), 0.0)
	_eye(ci, Vector2(5, -45), P.NECRO, 1.3)
	# skull belt
	for i in 3:
		P.circ(ci, Vector2(-4 + i * 5, -22), 2.3, P.BONE, 1.0)
	# staff with skull + green flame
	var raise = 0.0 if cast <= 0.0 else 8.0
	var sp = Vector2(14, -34 - raise)
	P.limb(ci, Vector2(6, -38), sp + Vector2(-2, 4), 4, P.VIOLET_D)
	ci.draw_line(sp + Vector2(0, -16), sp + Vector2(0, 34 + raise), P.OUT, 4.0)
	ci.draw_line(sp + Vector2(0, -16), sp + Vector2(0, 34 + raise), P.WOOD_D, 2.5)
	_skull(ci, sp + Vector2(0, -20), 0.0)
	var f = 4.0 + sin(t * 12.0) * 1.5 + atk * 4.0 + cast * 4.0
	P.glow(ci, sp + Vector2(1, -30), f * 2.5, Color(0.43, 1.0, 0.55, 0.8))
	ci.draw_circle(sp + Vector2(1, -30), f * 0.6, Color(0.8, 1.0, 0.8))


static func _hulk(ci: CanvasItem, a) -> void:
	var t: float = P.g(a, "t", 0.0)
	var atk: float = P.g(a, "atk", 0.0)
	var wind: float = P.g(a, "windup", 0.0)
	var moving: bool = P.g(a, "state", "") == "move"
	var w: float = P.g(a, "walk", 0.0)
	var bob = absf(sin(w)) * 3.0 if moving else 0.0
	var stp = sin(w) * 6.0 if moving else 0.0
	# stumpy legs
	P.limb(ci, Vector2(-12, -24 - bob), Vector2(-14 - stp, -3), 13, P.FLESH_D)
	P.limb(ci, Vector2(12, -24 - bob), Vector2(12 + stp, -3), 13, P.FLESH)
	var y = -bob
	# mountainous stitched mass
	var body = P.pts([Vector2(-30, -22 + y), Vector2(-36, -50 + y), Vector2(-24, -78 + y), Vector2(-4, -88 + y), Vector2(18, -84 + y), Vector2(32, -64 + y), Vector2(34, -38 + y), Vector2(24, -18 + y)])
	P.poly(ci, body, Color("8a9474"), 2.5)
	P.poly(ci, P.pts([Vector2(-26, -50 + y), Vector2(-18, -74 + y), Vector2(-2, -82 + y), Vector2(8, -70 + y), Vector2(-8, -56 + y)]), Color("9faa86"), 0.0)
	# stitches
	for seam in [[Vector2(-20, -30), Vector2(10, -76)], [Vector2(14, -30), Vector2(26, -60)]]:
		var s0: Vector2 = seam[0] + Vector2(0, y)
		var s1: Vector2 = seam[1] + Vector2(0, y)
		ci.draw_line(s0, s1, Color("4a3a30"), 2.0)
		for i in 7:
			var p = s0.lerp(s1, (i + 0.5) / 7.0)
			var n = (s1 - s0).normalized().orthogonal() * 4.0
			ci.draw_line(p - n, p + n, Color("2a2420"), 1.5)
	# exposed ribs + boils
	for i in 3:
		ci.draw_arc(Vector2(-14, -40 + i * 6 + y), 8, PI * 0.1, PI * 0.9, 6, P.BONE, 2.5)
	for b in [Vector2(20, -46), Vector2(-28, -60), Vector2(6, -30)]:
		P.circ(ci, b + Vector2(0, y), 3.0 + sin(t * 4.0 + b.x) * 0.6, P.SICKLY, 1.2)
	# tiny head
	var head = Vector2(12, -88 + y)
	P.circ(ci, head, 8, P.FLESH_L, 2.0)
	_eye(ci, head + Vector2(3, -1), Color(0.9, 1.0, 0.4), 1.6)
	P.poly(ci, P.pts([head + Vector2(0, 3), head + Vector2(8, 3), head + Vector2(6, 6 + atk * 3)]), Color("2a2420"), 1.0)
	# giant slam arm: rears up during windup (telegraph), crashes down on attack
	var ang = -2.2 if wind > 0.0 else (lerpf(0.9, -2.2, clampf(atk, 0.0, 1.0)) if atk > 0.0 else 0.7)
	var sh = Vector2(26, -66 + y)
	var elbow = sh + Vector2(cos(ang), sin(ang)) * 24
	var fist = elbow + Vector2(cos(ang + 0.5), sin(ang + 0.5)) * 22
	P.limb(ci, sh, elbow, 14, Color("8a9474"))
	P.limb(ci, elbow, fist, 12, Color("7d876a"))
	P.circ(ci, fist, 11, Color("6f7a5e"), 2.0)
	if wind > 0.0:
		P.glow(ci, fist, 20, Color(1.0, 0.5, 0.3, 0.5 * wind))
	# small back arm
	P.limb(ci, Vector2(-26, -60 + y), Vector2(-34, -36 + y), 8, P.FLESH_D)


static func _wing(ci: CanvasItem, shoulder: Vector2, side: float, span: float, ang: float, col: Color) -> void:
	# membrane built un-flapped, then rotated about the shoulder (always a simple polygon)
	var base = [Vector2(0, 0), Vector2(span * 0.5, -4), Vector2(span, 0), Vector2(span * 0.75, 4), Vector2(span * 0.5, 3), Vector2(span * 0.25, 6), Vector2(0, 5)]
	var p = PackedVector2Array()
	var thick = maxf(1.0, span / 16.0)
	for v in base:
		p.append(shoulder + Vector2(v.x * side, v.y * thick).rotated(ang * side))
	P.poly(ci, p, col, 1.5)


static func _bat(ci: CanvasItem, a) -> void:
	var t: float = P.g(a, "t", 0.0)
	var atk: float = P.g(a, "atk", 0.0)
	var flap = sin(t * 14.0 + P.g(a, "special", 0.0))
	_wing(ci, Vector2(-2, -2), -1.0, 20.0, -flap * 0.7, Color("3d3438"))
	_wing(ci, Vector2(2, -2), 1.0, 20.0, -flap * 0.7, Color("4a3e42"))
	P.ell(ci, Vector2(0, 0), 7, 5, Color("5a4a4a"), 1.5)
	var head = Vector2(7, -1)
	P.circ(ci, head, 4.5, Color("6a5656"), 1.5)
	P.poly(ci, P.pts([head + Vector2(-2, -3), head + Vector2(-1, -8), head + Vector2(1, -3)]), Color("6a5656"), 1.2)
	_eye(ci, head + Vector2(2, -1), Color(1.0, 0.3, 0.2), 1.1)
	if atk > 0.5:
		ci.draw_line(head + Vector2(3, 2), head + Vector2(4, 4), Color.WHITE, 1.0)
	ci.draw_line(Vector2(-3, 4), Vector2(-5, 8), P.BONE_D, 1.5)
	ci.draw_line(Vector2(2, 4), Vector2(1, 8), P.BONE_D, 1.5)


static func _shrieker(ci: CanvasItem, a) -> void:
	var t: float = P.g(a, "t", 0.0)
	var atk: float = P.g(a, "atk", 0.0)
	var flap = sin(t * 7.0)
	var wy = flap * 16.0
	_wing(ci, Vector2(-4, -8), -1.0, 36.0, -flap * 0.55 - 0.35, Color("4e5a46"))
	for i in 3:
		ci.draw_line(Vector2(-6, -8), Vector2(-26 - i * 5, -22 - wy + i * 6), P.BONE_D, 1.2)
	# emaciated body
	P.poly(ci, P.pts([Vector2(-8, -10), Vector2(4, -14), Vector2(10, -6), Vector2(6, 8), Vector2(-2, 14), Vector2(-6, 4)]), P.FLESH, 2.0)
	ci.draw_line(Vector2(-4, 14), Vector2(-8, 22), P.FLESH_D, 3.0)
	ci.draw_line(Vector2(2, 12), Vector2(4, 22), P.FLESH_D, 3.0)
	# near wing
	_wing(ci, Vector2(0, -8), 1.0, 34.0, -flap * 0.55 - 0.35, Color("5f6b55"))
	# screaming head
	var head = Vector2(12, -16)
	P.poly(ci, P.pts([head + Vector2(-6, -4), head + Vector2(2, -9), head + Vector2(8, -6), head + Vector2(9, 2), head + Vector2(2, 7), head + Vector2(-5, 3)]), P.FLESH_L, 2.0)
	ci.draw_line(head + Vector2(-5, -6), head + Vector2(-9, -14), Color("3a3a32"), 2.0)
	ci.draw_line(head + Vector2(-2, -8), head + Vector2(-3, -16), Color("3a3a32"), 2.0)
	_eye(ci, head + Vector2(4, -3), Color(0.95, 1.0, 0.4), 1.4)
	var open = 3.0 + atk * 4.0 + sin(t * 20.0) * 0.6
	P.ell(ci, head + Vector2(5, 3), 2.5, open * 0.6, Color("1a1410"), 1.2)
	if atk > 0.6:
		for i in 3:
			ci.draw_arc(head + Vector2(8, 3), 6 + i * 5, -0.6, 0.6, 6, Color(0.8, 1.0, 0.5, (atk - 0.6) * 1.5), 1.5)


static func _spire(ci: CanvasItem, a) -> void:
	var t: float = P.g(a, "t", 0.0)
	var atk: float = P.g(a, "atk", 0.0)
	var hp: float = P.g(a, "hp_frac", 1.0)
	# base rubble
	P.poly(ci, P.pts([Vector2(-26, 0), Vector2(-20, -12), Vector2(20, -12), Vector2(28, 0)]), Color("4a4440"), 2.0)
	# twisted bone column
	P.poly(ci, P.pts([Vector2(-14, -10), Vector2(-10, -60), Vector2(-4, -92), Vector2(4, -92), Vector2(10, -60), Vector2(14, -10)]), P.BONE, 2.0)
	for i in 6:
		var yy = -18.0 - i * 12.0
		ci.draw_line(Vector2(-11 + i * 0.8, yy), Vector2(11 - i * 0.8, yy - 6), P.BONE_D, 2.0)
	# ribs jutting out
	for s in [-1.0, 1.0]:
		for i in 3:
			var yy = -30.0 - i * 18.0
			P.poly(ci, P.pts([Vector2(s * 9, yy), Vector2(s * 22, yy - 10), Vector2(s * 10, yy - 5)]), P.BONE_D, 1.5)
	# skull crown with glowing violet core
	_skull(ci, Vector2(0, -98), atk)
	var pulse = 0.6 + 0.4 * sin(t * 3.0) + atk * 0.5
	P.glow(ci, Vector2(0, -74), 16 * pulse, Color(0.6, 0.35, 0.95, 0.8))
	ci.draw_circle(Vector2(0, -74), 4.0, Color(0.85, 0.7, 1.0))
	if hp < 0.5:
		ci.draw_line(Vector2(-8, -40), Vector2(4, -56), P.OUT, 2.0)


static func _mine_maw(ci: CanvasItem, a) -> void:
	var t: float = P.g(a, "t", 0.0)
	var st: String = P.g(a, "state", "move")
	var atk: float = P.g(a, "atk", 0.0)
	var wind: float = P.g(a, "windup", 0.0)
	var spec: float = P.g(a, "special", 0.0)   # 0..1 emergence factor
	if st == "burrowed":
		_mound(ci, a, 46.0)
		return
	var rise = clampf(spec, 0.0, 1.0)
	var exposed: bool = st == "exposed"
	# dirt ring where the body breaks the ground
	P.poly(ci, P.ell_pts(Vector2(-10, 0), 62, 14, 0.0, 16, PI, TAU), Color("5b4a36"), 2.0)
	ci.draw_set_transform(Vector2(0, (1.0 - rise) * 120.0), 0.0, Vector2.ONE)
	# segmented worm body arching toward the dwarves (local +x)
	var segs = 6
	var sway = sin(t * 1.6) * 6.0
	for i in segs:
		var k = float(segs - i) / segs
		var c = Vector2(-40 + i * 12 + sway * k, -20 - i * 18)
		var r = 34.0 - i * 1.5
		P.ell(ci, c, r, r * 0.8, Color("6b5848").lerp(Color("8a7058"), float(i) / segs), 2.0)
		# bone plates on the back
		P.poly(ci, P.pts([c + Vector2(-r * 0.6, -r * 0.5), c + Vector2(-r * 0.2, -r * 1.05), c + Vector2(r * 0.2, -r * 0.6)]), P.BONE_D, 1.5)
	# great maw head
	var hc = Vector2(34 + sway * 0.3, -126)
	var gape = 0.35 + atk * 0.5 + wind * 0.4 + (0.3 if exposed else 0.0)
	P.ell(ci, hc, 44, 40, Color("8a7058"), 2.5)
	# armored brow plates
	for i in 4:
		var ang = -2.4 + i * 0.35
		var p = hc + Vector2(cos(ang), sin(ang)) * 38
		P.poly(ci, P.pts([p, p + Vector2(cos(ang - 0.3), sin(ang - 0.3)) * 18, p + Vector2(cos(ang + 0.3), sin(ang + 0.3)) * 10]), P.BONE, 1.5)
	# circular toothed mouth facing forward
	var mc = hc + Vector2(18, 6)
	var mr = 22.0 + gape * 8.0
	P.ell(ci, mc, mr * 0.7, mr, Color("2a0f12"), 2.5)
	P.ell(ci, mc + Vector2(4, 0), mr * 0.45, mr * 0.7, Color("5a1a20"), 0.0)
	for i in 12:
		var ang = TAU * i / 12.0
		var o = mc + Vector2(cos(ang) * mr * 0.7, sin(ang) * mr)
		var inward = (mc - o).normalized()
		var tn = inward.orthogonal()
		P.poly(ci, P.pts([o + tn * 3.5, o + inward * (9 + gape * 4), o - tn * 3.5]), P.BONE, 1.0)
	# eyes clustered above maw
	for e in [Vector2(-10, -22), Vector2(4, -28), Vector2(-20, -10)]:
		var ec: Color = Color(1.0, 0.5, 0.2) if exposed else P.NECRO
		_eye(ci, hc + e, ec, 2.6)
	if exposed:
		var k = 0.5 + 0.5 * sin(t * 10.0)
		ci.draw_arc(hc, 52, 0, TAU, 24, Color(1.0, 0.6, 0.2, 0.5 * k), 3.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
