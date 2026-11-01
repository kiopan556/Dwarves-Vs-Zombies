class_name ArtStructures
extends RefCounted
## Strongholds. Both drawn facing right in local space (undead citadel is mirrored by its node).

const P = preload("res://scripts/art/painter.gd")


static func draw(ci: CanvasItem, art: String, a) -> void:
	match art:
		"dwarf_hold": _dwarf_hold(ci, a)
		"undead_citadel": _citadel(ci, a)


static func _stone_block(ci: CanvasItem, r: Rect2, col: Color) -> void:
	P.rect(ci, r, col, 2.0)
	var rows = int(r.size.y / 14.0)
	for i in rows:
		var yy = r.position.y + (i + 1) * 14.0
		ci.draw_line(Vector2(r.position.x + 2, yy), Vector2(r.end.x - 2, yy), col.darkened(0.25), 1.0)
		var off = 0.0 if i % 2 == 0 else 12.0
		var x = r.position.x + off + 12.0
		while x < r.end.x - 4:
			ci.draw_line(Vector2(x, yy - 14), Vector2(x, yy), col.darkened(0.25), 1.0)
			x += 24.0


static func _dwarf_hold(ci: CanvasItem, a) -> void:
	var t: float = P.g(a, "t", 0.0)
	var hp: float = P.g(a, "hp_frac", 1.0)
	var atk: float = P.g(a, "atk", 0.0)
	var stone = Color("7d776e")
	# back mountain-face keep
	_stone_block(ci, Rect2(-110, -230, 120, 230), stone.darkened(0.12))
	# chimneys with forge smoke
	for cx in [-96.0, -60.0]:
		P.rect(ci, Rect2(cx, -290, 18, 64), Color("5b5550"), 2.0)
		P.rect(ci, Rect2(cx - 3, -296, 24, 8), P.BRASS, 2.0)
		P.smoke_puff(ci, Vector2(cx + 9, -304), t * 0.6 + cx, 4, Color(0.35, 0.33, 0.32, 0.55))
		P.glow(ci, Vector2(cx + 9, -296), 10, Color(1, 0.6, 0.2, 0.5))
	# main gatehouse
	_stone_block(ci, Rect2(-40, -170, 110, 170), stone)
	# battlement
	for i in 5:
		P.rect(ci, Rect2(-40 + i * 23, -186, 15, 16), stone, 2.0)
	# great brass gate with rune
	P.poly(ci, P.pts([Vector2(-6, 0), Vector2(-6, -80), Vector2(20, -100), Vector2(46, -80), Vector2(46, 0)]), Color("3a2f26"), 2.5)
	P.poly(ci, P.pts([Vector2(-2, 0), Vector2(-2, -76), Vector2(20, -94), Vector2(42, -76), Vector2(42, 0)]), P.BRASS_D, 2.0)
	ci.draw_line(Vector2(20, -92), Vector2(20, 0), Color("3a2f26"), 2.5)
	for yy in [-60.0, -30.0]:
		ci.draw_line(Vector2(-2, yy), Vector2(42, yy), P.BRASS, 3.0)
	P.circ(ci, Vector2(20, -62), 9, P.BRASS, 2.0)
	ci.draw_line(Vector2(15, -66), Vector2(25, -58), P.FORGE, 2.0)
	ci.draw_line(Vector2(25, -66), Vector2(15, -58), P.FORGE, 2.0)
	# steam pipes
	for py in [-140.0, -120.0]:
		P.rect(ci, Rect2(60, py, 22, 8), P.COPPER, 1.5)
	P.smoke_puff(ci, Vector2(84, -138), t * 1.4, 3, Color(1, 1, 1, 0.35))
	# banners
	for bx in [-30.0, 54.0]:
		var wave = sin(t * 2.0 + bx) * 3.0
		P.poly(ci, P.pts([Vector2(bx, -166), Vector2(bx + 14, -166), Vector2(bx + 14 + wave, -120), Vector2(bx + 7 + wave, -128), Vector2(bx + wave, -120)]), P.DEEP_BLUE, 1.5)
		P.circ(ci, Vector2(bx + 7 + wave * 0.5, -148), 3.5, P.BRASS, 1.0)
	# rampart gun (stronghold weapon)
	var aim: float = clampf(P.g(a, "aim0", 0.0), -1.2, 0.6)
	var gp = Vector2(50, -194)
	P.rect(ci, Rect2(gp.x - 12, gp.y, 24, 10), P.IRON_D, 2.0)
	P.bar(ci, gp, aim, 26, 5.0, P.IRON, 1.5)
	P.muzzle_flash(ci, gp + Vector2(cos(aim), sin(aim)) * 26, aim, 10.0, clampf((atk - 0.7) / 0.3, 0.0, 1.0))
	# damage states
	if hp < 0.66:
		ci.draw_line(Vector2(-30, -150), Vector2(-10, -110), P.OUT, 2.5)
		ci.draw_line(Vector2(-10, -110), Vector2(-20, -80), P.OUT, 2.5)
	if hp < 0.4:
		P.glow(ci, Vector2(-80, -200), 22, Color(1, 0.45, 0.1, 0.7))
		P.smoke_puff(ci, Vector2(-80, -210), t, 4, Color(0.15, 0.13, 0.12, 0.7))
		ci.draw_line(Vector2(50, -170), Vector2(36, -130), P.OUT, 2.5)
	if hp < 0.2:
		P.glow(ci, Vector2(30, -170), 26, Color(1, 0.4, 0.1, 0.8))


static func _citadel(ci: CanvasItem, a) -> void:
	var t: float = P.g(a, "t", 0.0)
	var hp: float = P.g(a, "hp_frac", 1.0)
	var sealed: bool = P.g(a, "special", 0.0) > 0.5
	var dark = Color("3a3438")
	var dark2 = Color("4a4248")
	# back cathedral nave
	P.poly(ci, P.pts([Vector2(-120, 0), Vector2(-120, -170), Vector2(-90, -200), Vector2(-60, -170), Vector2(-60, 0)]), dark, 2.0)
	# spires
	for sp in [[-110.0, -260.0, 14.0], [-70.0, -230.0, 12.0], [-20.0, -290.0, 18.0], [40.0, -240.0, 14.0]]:
		var x: float = sp[0]
		var top: float = sp[1]
		var w: float = sp[2]
		P.poly(ci, P.pts([Vector2(x - w, -120), Vector2(x - w * 0.7, top + 50), Vector2(x, top), Vector2(x + w * 0.7, top + 50), Vector2(x + w, -120)]), dark2, 2.0)
		P.poly(ci, P.pts([Vector2(x - 4, top + 40), Vector2(x, top + 26), Vector2(x + 4, top + 40), Vector2(x + 4, top + 56), Vector2(x - 4, top + 56)]), Color(0.3, 0.9, 0.45, 0.7 + 0.3 * sin(t * 2.0 + x)), 1.0)
	# main wall
	P.poly(ci, P.pts([Vector2(-60, 0), Vector2(-60, -150), Vector2(-30, -170), Vector2(40, -170), Vector2(70, -150), Vector2(70, 0)]), dark2, 2.5)
	# ribcage arch gate
	P.poly(ci, P.pts([Vector2(-10, 0), Vector2(-10, -70), Vector2(20, -100), Vector2(50, -70), Vector2(50, 0)]), Color("120d10"), 2.0)
	for i in 5:
		var yy = -14.0 - i * 16.0
		var span = 30.0 - absf(i - 2) * 4.0 - i * 2.0
		ci.draw_arc(Vector2(20, yy), span * 0.6, PI, TAU, 8, P.OUT, 5.0)
		ci.draw_arc(Vector2(20, yy), span * 0.6, PI, TAU, 8, P.BONE, 3.0)
	P.glow(ci, Vector2(20, -40), 30, Color(0.43, 1.0, 0.55, 0.45))
	# skull keystone
	ArtUndead._skull(ci, Vector2(20, -108), 0.0)
	# bone ballista on the parapet
	var aim: float = clampf(P.g(a, "aim0", 0.0), -1.2, 0.6)
	var gp = Vector2(40, -178)
	P.rect(ci, Rect2(gp.x - 10, gp.y, 20, 8), P.BONE_D, 2.0)
	P.bar(ci, gp, aim, 24, 4.0, P.BONE, 1.5)
	ci.draw_line(gp + Vector2(cos(aim + 1.4), sin(aim + 1.4)) * 12, gp + Vector2(cos(aim - 1.4), sin(aim - 1.4)) * 12, P.BONE_D, 2.0)
	# windows
	for wx in [-40.0, 50.0]:
		P.poly(ci, P.pts([Vector2(wx - 6, -110), Vector2(wx, -124), Vector2(wx + 6, -110), Vector2(wx + 6, -92), Vector2(wx - 6, -92)]), Color(0.43, 1.0, 0.55, 0.55 + 0.25 * sin(t * 3.0 + wx)), 1.5)
	if hp < 0.6:
		ci.draw_line(Vector2(-40, -150), Vector2(-20, -100), P.OUT, 2.5)
		P.poly(ci, P.pts([Vector2(40, -170), Vector2(52, -170), Vector2(48, -160)]), Color("120d10"), 0.0)
	if hp < 0.3:
		P.glow(ci, Vector2(-30, -140), 22, Color(1, 0.5, 0.2, 0.6))
	# necrotic seal (while a sealing boss lives)
	if sealed:
		var k = 0.6 + 0.4 * sin(t * 3.0)
		ci.draw_arc(Vector2(-10, -130), 150, -PI * 0.95, PI * 0.15, 40, Color(0.43, 1.0, 0.55, 0.35 * k), 6.0)
		ci.draw_arc(Vector2(-10, -130), 140, -PI * 0.95, PI * 0.15, 40, Color(0.6, 0.35, 0.95, 0.4 * k), 3.0)
		for i in 6:
			var ang = -PI * 0.9 + i * 0.36 + t * 0.2
			var p = Vector2(-10, -130) + Vector2(cos(ang), sin(ang)) * 145
			ci.draw_circle(p, 4, Color(0.6, 1.0, 0.7, 0.7 * k))
