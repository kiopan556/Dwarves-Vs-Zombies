class_name ArtDwarves
extends RefCounted
## Dwarven infantry: broad torsos, short legs, big beards, chunky firearms.

const P = preload("res://scripts/art/painter.gd")


const KIND := {"militia": "melee", "rifleman": "rifle", "shieldbearer": "shield", "blunderbussier": "blast", "grenadier": "throw", "mechanic": "tool"}


static func draw(ci: CanvasItem, art: String, a) -> void:
	goof_begin(ci, a, KIND.get(art, "rifle"))
	match art:
		"militia": _militia(ci, a)
		"rifleman": _rifleman(ci, a)
		"shieldbearer": _shieldbearer(ci, a)
		"blunderbussier": _blunderbussier(ci, a)
		"grenadier": _grenadier(ci, a)
		"mechanic": _mechanic(ci, a)
	goof_end(ci)


# ================================================================== M004 goofy animation layer
## Dwarven infantry are played for laughs: every shot is a little slapstick. A post-attack
## timeline ("gag", 1 -> 0 over ~0.8 s) drives a whole-body squash / lean-back / damped spring
## recovery, a hat that pops off and flips back onto the head, squeezed eyes, a gaping "O"
## mouth and a blown-back beard. Idle dwarves breathe, blink, bounce and fix their hats;
## walkers waddle. Everything is a pure function of the pose, so it bakes into the pose cache.
##   kick  recoil strength · hat  hat pop height · hop  feet leave the ground
##   buzz  vibrate while firing · swing  melee wind-up stretch + "boing" · lean  throw follow-through
const GAGS := {
	"rifle": {"kick": 0.6, "hat": 1.0},
	"long": {"kick": 0.75, "hat": 1.15},
	"blast": {"kick": 1.0, "hat": 1.35, "hop": 1.0, "mouth": 1.0},
	"heavy": {"kick": 0.9, "hat": 0.9, "hop": 0.45, "mouth": 1.0},
	"spray": {"kick": 0.2, "buzz": 1.0},
	"melee": {"kick": 0.7, "swing": 1.0},
	"shield": {"kick": 0.5, "swing": 0.5, "hat": 0.3},
	"throw": {"kick": 0.45, "lean": 1.0, "hat": 0.4},
	"tool": {"kick": 0.25, "swing": 0.4},
	"crew": {"kick": 0.85, "hat": 1.25, "hop": 0.5, "mouth": 1.0},
}
static var gf := {}   # current gag frame, read by dwarf_head (hat, eyes, mouth, beard)


static func goof_begin(ci: CanvasItem, a, kind: String) -> void:
	var prof: Dictionary = GAGS.get(kind, GAGS.rifle)
	var gag: float = P.g(a, "gag", 0.0)
	var atk: float = P.g(a, "atk", 0.0)
	var t: float = P.g(a, "t", 0.0)
	var hurt: float = P.g(a, "hurt", 0.0)
	var wind: float = P.g(a, "windup", 0.0)
	var moving: bool = P.g(a, "state", "idle") == "move"
	var walk: float = P.g(a, "walk", 0.0)
	var kick: float = float(prof.get("kick", 0.5))
	var ph = 1.0 - gag                      # 0 at the shot -> 1 settled
	var on = gag > 0.0
	var spring = exp(-3.4 * ph) * cos(ph * 9.4) if on else 0.0
	var rot = 0.0
	var sx = 1.0
	var sy = 1.0
	var off = Vector2.ZERO
	var g = {"hat_off": Vector2.ZERO, "hat_rot": 0.0, "blink": false, "look_up": 0.0, "mouth": 0.0, "beard": Vector2.ZERO, "dizzy": false}
	if on:
		var lean_dir = 1.0 if prof.has("lean") else -1.0
		rot = 0.24 * kick * spring * lean_dir
		sx = 1.0 + 0.15 * kick * spring
		sy = 1.0 - 0.15 * kick * spring
		off.x = -5.5 * kick * exp(-2.6 * ph) * (0.0 if prof.has("lean") else 1.0)
		if prof.has("hop"):
			off.y = -sin(clampf(ph * 2.4, 0.0, 1.0) * PI) * 8.0 * float(prof.hop)
		if prof.has("swing"):
			# the "boing": a hammer that lands too hard rattles its owner
			var steps = int(round(gag * 8.0))
			off.x += (1.0 if steps % 2 == 0 else -1.0) * 2.2 * gag * float(prof.swing)
			g.dizzy = ph > 0.3 and ph < 0.8 and float(prof.swing) >= 1.0
		var hat_k = float(prof.get("hat", 0.0))
		if hat_k > 0.0:
			var arc = sin(ph * PI)
			g.hat_off = Vector2(-7.0 * arc * hat_k, -(14.0 + 14.0 * kick) * arc * hat_k)
			g.hat_rot = -ph * TAU if hat_k >= 0.6 else sin(ph * TAU * 2.0) * 0.3
			g.look_up = arc
		g.blink = ph < 0.3
		g.mouth = float(prof.get("mouth", 0.0)) * clampf(1.0 - ph * 2.2, 0.0, 1.0)
		g.beard = Vector2(-7.0, -2.0) * kick * exp(-3.0 * ph) * (1.0 if prof.has("hop") or kind == "long" else 0.4)
	if prof.has("buzz") and atk > 0.05:
		var st = int(round(atk * 8.0))
		off.x += (1.4 if st % 2 == 0 else -1.4)
		sy *= 1.03 if st % 2 == 0 else 0.98
		g.blink = true
	if prof.has("swing") and wind > 0.0:
		sy *= 1.09
		sx *= 0.93
		rot += -0.1
	if hurt > 0.5:
		sx *= 1.12
		sy *= 0.86
		rot += -0.14
		g.hat_off += Vector2(-2, -6)
		g.hat_rot += -0.4
	if moving:
		# bouncy waddle (M007: a stompier march — squash on each footfall, stretch between, a forward
		# lean into the step; the beard trails and swings, the helmet bobs a beat behind the head)
		var plant = absf(cos(walk))            # 1 at each footfall
		sy *= 1.0 + 0.06 * (0.5 - plant)
		sx *= 1.0 - 0.04 * (0.5 - plant)
		rot += 0.06 * sin(walk) - 0.05
		g.beard += Vector2(-2.5 - 1.5 * absf(sin(walk)), -0.6 + 1.2 * sin(walk * 2.0))
		g.hat_off += Vector2(-0.5, -1.4 * (1.0 - plant))
		g.hat_rot += 0.06 * sin(walk + 0.8)
	elif P.g(a, "state", "idle") == "dead":
		# M007: a dwarf goes down like a sack of coal — hat knocked off, X eyes, mouth agape
		g.hat_off = Vector2(-11.0, -9.0)
		g.hat_rot = -1.1
		g.mouth = 1.0
		g.dizzy = true
		g.beard = Vector2(-3.0, -3.0)
		sy *= 0.92
		sx *= 1.06
	elif not on and atk <= 0.0 and hurt <= 0.5:
		var lt = fposmod(t, 4.8)
		sy *= 1.0 + 0.025 * sin(lt / 1.2 * TAU)            # breathing
		rot += 0.025 * sin(lt / 2.4 * TAU)                 # M007: weight shifting from foot to foot
		g.beard += Vector2(0.6 * sin(lt / 1.2 * TAU), 0.0)  # the beard rises and falls with the breath
		if lt >= 0.6 and lt < 1.4:
			g.look_up = -0.6 * sin((lt - 0.6) / 0.8 * PI)   # glances down at the boots
		if lt >= 1.6 and lt < 2.0:
			g.blink = true
		if lt >= 3.0 and lt < 4.0:                         # impatient bounce on the toes
			off.y = -absf(sin((lt - 3.0) * TAU)) * 2.5
		if lt >= 4.2 and lt < 4.8:                         # pushes the helmet back into place
			g.hat_off = Vector2(1.0, -3.0) * sin((lt - 4.2) / 0.6 * PI)
			g.hat_rot = 0.15 * sin((lt - 4.2) / 0.6 * PI)
	gf = g
	P.xf_push(ci, P.xf_about(Vector2.ZERO, rot, Vector2(sx, sy), off))


static func goof_end(ci: CanvasItem) -> void:
	P.xf_pop(ci)
	gf = {}


## Shared body. Returns anchor points: {shoulder_f, shoulder_b, head, chest, bob}.
## style keys: coat, coat_d, belt, beard, helmet ("miner","kettle","great","cap","goggle_cap"), helm_col, pauldron, scale
static func body(ci: CanvasItem, a, s: Dictionary, draw_head: bool = true) -> Dictionary:
	var moving: bool = P.g(a, "state", "idle") == "move"
	var w: float = P.g(a, "walk", 0.0)
	# M007 march: a longer stomping stride. Each foot swings forward lifted (toe up), lands heel-first and
	# rolls flat; the leg is a slanted quad from the hip to the boot, so the stride reads at a glance; the
	# body drops onto every footfall.
	var bob: float = (1.0 - absf(cos(w))) * 2.2 if moving else 0.0
	var coat: Color = s.get("coat", P.DEEP_BLUE)
	var coat_d: Color = s.get("coat_d", coat.darkened(0.3))
	var y = -bob
	# legs + boots (back leg first)
	for li in 2:
		var ph = w + (PI if li == 0 else 0.0)
		var hip_x = -4.0 if li == 0 else 4.0
		var fx = hip_x + (6.0 * sin(ph) if moving else 0.0)
		var lift = maxf(0.0, cos(ph)) * 4.2 if moving else 0.0
		var toe = (-0.28 * maxf(0.0, cos(ph)) + 0.12 * maxf(0.0, -cos(ph)) * maxf(0.0, -sin(ph))) if moving else 0.0
		var col: Color = coat_d.darkened(0.15) if li == 0 else coat_d
		var hip = Vector2(hip_x, -15.0 + y * 0.6)
		var ft = Vector2(fx, -6.0 - lift)
		P.poly(ci, P.pts([hip + Vector2(-4.5, 0), hip + Vector2(4.5, 0), ft + Vector2(4.2, 0), ft + Vector2(-4.2, 0)]), col, 2.0)
		var boot = [Vector2(-6, 0), Vector2(7, 0), Vector2(9, 5), Vector2(8, 7), Vector2(-6, 7)]
		var bp: Array = []
		for q in boot:
			bp.append(ft + Vector2(q.x, q.y).rotated(toe))
		P.poly(ci, P.pts(bp), P.LEATHER_D, 2.0)
		ci.draw_line(ft + Vector2(-6, 3).rotated(toe), ft + Vector2(8, 3).rotated(toe), P.IRON_D, 1.5)
	# torso — broad barrel shape
	var torso = P.pts([Vector2(-12, -14 + y), Vector2(-14, -24 + y), Vector2(-11, -34 + y), Vector2(-4, -37 + y), Vector2(6, -37 + y), Vector2(12, -33 + y), Vector2(14, -23 + y), Vector2(12, -14 + y)])
	P.poly(ci, torso, coat, 2.0)
	ci.draw_line(Vector2(-10, -25 + y), Vector2(-12, -16 + y), coat_d, 3.0)
	# belt + buckle
	P.rect(ci, Rect2(-13, -18 + y, 26, 5), s.get("belt", P.LEATHER_D), 1.5)
	P.rect(ci, Rect2(-2, -19 + y, 6, 7), P.BRASS, 1.5)
	if s.get("pauldron", false):
		P.ell(ci, Vector2(-2, -33 + y), 9, 5, s.get("helm_col", P.IRON), 2.0)
		P.rivets(ci, Vector2(-9, -34 + y), Vector2(5, -34 + y), 3)
	var head = Vector2(3, -42 + y)
	if draw_head:
		dwarf_head(ci, a, head, s)
	return {"shoulder_f": Vector2(8, -31 + y), "shoulder_b": Vector2(-7, -31 + y), "head": head, "y": y}


static func dwarf_head(ci: CanvasItem, a, head: Vector2, s: Dictionary) -> void:
	var beard: Color = s.get("beard", Color("8a4a24"))
	var hurt: float = P.g(a, "hurt", 0.0)
	var bo: Vector2 = gf.get("beard", Vector2.ZERO)
	# face
	P.circ(ci, head, 8.5, P.SKIN, 2.0)
	# beard: big wedge flowing down over the chest (its tip blows back on a big shot)
	var bp = P.pts([head + Vector2(-8, -1), head + Vector2(-3, 3), head + Vector2(3, 4), head + Vector2(10, 0),
		head + Vector2(9, 9) + bo * 0.4, head + Vector2(6, 17) + bo * 0.8, head + Vector2(1, 21) + bo, head + Vector2(-4, 16) + bo * 0.8, head + Vector2(-8, 8) + bo * 0.3])
	P.poly(ci, bp, beard, 2.0)
	ci.draw_line(head + Vector2(1, 7), head + Vector2(2, 17) + bo * 0.8, beard.darkened(0.3), 1.5)
	ci.draw_line(head + Vector2(5, 6), head + Vector2(6, 13) + bo * 0.6, beard.darkened(0.3), 1.5)
	var mouth: float = gf.get("mouth", 0.0)
	if mouth > 0.05:
		P.ell(ci, head + Vector2(5, 6.5), 2.6 * mouth + 1.0, 3.2 * mouth + 1.0, Color("3a1410"), 1.2)
	# moustache
	P.poly(ci, P.pts([head + Vector2(-1, 2), head + Vector2(5, 0), head + Vector2(12, 3), head + Vector2(10, 5), head + Vector2(4, 3), head + Vector2(0, 5)]), beard.lightened(0.15), 1.5)
	# nose
	P.circ(ci, head + Vector2(8, -1), 3.4, P.SKIN_D, 1.5)
	# eye + brow
	var eye = head + Vector2(5, -4)
	if hurt > 0.5 or gf.get("dizzy", false):
		# cartoon X eyes
		ci.draw_line(eye + Vector2(-2, -2), eye + Vector2(2, 2), P.OUT, 1.5)
		ci.draw_line(eye + Vector2(-2, 2), eye + Vector2(2, -2), P.OUT, 1.5)
	elif gf.get("blink", false):
		ci.draw_line(eye + Vector2(-2.2, 0.5), eye + Vector2(2.2, -0.3), P.OUT, 1.6)
	else:
		ci.draw_circle(eye, 2.2, Color(1, 1, 1))
		ci.draw_circle(eye + Vector2(0.6, -1.2 * float(gf.get("look_up", 0.0))), 1.3, P.OUT)
	var brow_up = -2.0 * float(gf.get("look_up", 0.0))
	ci.draw_line(head + Vector2(1, -7 + brow_up), head + Vector2(9, -6.5 + brow_up + (1.5 if hurt > 0.5 else 0.0)), beard.darkened(0.2), 3.0)
	var ho: Vector2 = gf.get("hat_off", Vector2.ZERO)
	var hr: float = gf.get("hat_rot", 0.0)
	if s.get("helmet", "kettle") == "great":
		ho *= 0.3      # a great helm only rattles
		hr *= 0.2
	if ho != Vector2.ZERO or hr != 0.0:
		if ho.y < -10.0:
			# bald pate + a couple of startled hairs while the hat is airborne
			P.poly(ci, P.ell_pts(head + Vector2(0, -4), 8.6, 7.0, 0.0, 12, PI, TAU), P.SKIN, 1.5)
			ci.draw_line(head + Vector2(-1, -11), head + Vector2(-3, -15), P.OUT, 1.2)
			ci.draw_line(head + Vector2(2, -11), head + Vector2(3, -16), P.OUT, 1.2)
		P.xf_push(ci, P.xf_about(head + Vector2(0, -6), hr, Vector2.ONE, ho))
		_helmet(ci, a, head, s)
		P.xf_pop(ci)
	else:
		_helmet(ci, a, head, s)


static func _helmet(ci: CanvasItem, a, head: Vector2, s: Dictionary) -> void:
	var col: Color = s.get("helm_col", P.IRON)
	match s.get("helmet", "kettle"):
		"miner":
			P.poly(ci, P.ell_pts(head + Vector2(0, -3), 10, 9, 0.0, 14, PI, TAU), col, 2.0)
			P.rect(ci, Rect2(head.x - 11, head.y - 4, 22, 3), col.darkened(0.25), 1.5)
			P.circ(ci, head + Vector2(6, -9), 3.2, P.BRASS, 1.5)
			ci.draw_circle(head + Vector2(6.5, -9), 1.8, Color(1, 0.95, 0.6))
			P.glow(ci, head + Vector2(9, -9), 9, Color(1, 0.9, 0.5, 0.5))
		"kettle":
			P.poly(ci, P.ell_pts(head + Vector2(0, -4), 9.5, 9, 0.0, 14, PI, TAU), col, 2.0)
			P.poly(ci, P.pts([head + Vector2(-14, -3), head + Vector2(14, -3), head + Vector2(12, -1), head + Vector2(-12, -1)]), P.BRASS, 1.5)
			P.rivets(ci, head + Vector2(-7, -8), head + Vector2(7, -8), 3, P.BRASS)
			ci.draw_line(head + Vector2(0, -13), head + Vector2(0, -16), P.BRASS, 3.0)
		"great":
			P.poly(ci, P.pts([head + Vector2(-10, 4), head + Vector2(-11, -6), head + Vector2(-6, -13), head + Vector2(6, -13), head + Vector2(11, -6), head + Vector2(12, 3), head + Vector2(8, 4)]), col, 2.0)
			P.rect(ci, Rect2(head.x + 1, head.y - 6, 10, 2.5), P.COAL, 0.0)
			ci.draw_line(head + Vector2(-10, -1), head + Vector2(12, -1), P.BRASS, 2.0)
			P.rivets(ci, head + Vector2(-8, -10), head + Vector2(8, -10), 4, P.BRASS)
			P.poly(ci, P.pts([head + Vector2(-2, -13), head + Vector2(2, -13), head + Vector2(0, -19)]), P.BRASS, 1.5)
		"cap":
			P.poly(ci, P.ell_pts(head + Vector2(-1, -4), 9.5, 7, 0.0, 12, PI, TAU), col, 2.0)
			P.poly(ci, P.pts([head + Vector2(4, -4), head + Vector2(15, -3), head + Vector2(14, -1), head + Vector2(4, -2)]), col.darkened(0.3), 1.5)
		"goggle_cap":
			P.poly(ci, P.ell_pts(head + Vector2(-1, -4), 9.5, 7.5, 0.0, 12, PI, TAU), col, 2.0)
			ci.draw_line(head + Vector2(-9, -6), head + Vector2(9, -6), P.LEATHER_D, 3.0)
			P.circ(ci, head + Vector2(2, -7), 3.0, P.BRASS, 1.5)
			P.circ(ci, head + Vector2(7, -7), 3.0, P.BRASS, 1.5)
			ci.draw_circle(head + Vector2(2, -7), 1.7, Color(0.6, 0.85, 0.95))
			ci.draw_circle(head + Vector2(7, -7), 1.7, Color(0.6, 0.85, 0.95))


static func arm(ci: CanvasItem, from: Vector2, to: Vector2, col: Color) -> void:
	P.limb(ci, from, to, 6.0, col)
	P.circ(ci, to, 3.4, P.SKIN, 1.5)


static func rifle(ci: CanvasItem, grip: Vector2, ang: float, length: float, flash: float, kind: String = "rifle") -> Vector2:
	var d = Vector2(cos(ang), sin(ang))
	var n = Vector2(-d.y, d.x)
	# stock
	P.poly(ci, P.pts([grip - d * 10 + n * 1, grip - d * 12 + n * 5, grip - d * 2 + n * 3, grip + d * 6 - n * 1.5, grip - d * 10 - n * 2]), P.WOOD, 1.5)
	# wooden body + barrel
	P.bar(ci, grip - d * 2 - n * 0.5, ang, length * 0.55, 4.5, P.WOOD, 1.5)
	var muzzle = grip + d * length
	if kind == "blunderbuss":
		P.bar(ci, grip + d * 6, ang, length - 10, 4.0, P.BRASS, 1.5)
		P.poly(ci, P.pts([muzzle - d * 6 + n * 2.5, muzzle + n * 6.5, muzzle - n * 6.5, muzzle - d * 6 - n * 2.5]), P.BRASS, 1.5)
	else:
		P.bar(ci, grip + d * 4 - n * 1.5, ang, length - 4, 2.8, P.IRON_D, 1.2)
		ci.draw_line(grip + d * (length * 0.3) - n * 1.5, grip + d * (length * 0.3) + n * 2.5, P.BRASS, 2.0)
		ci.draw_line(grip + d * (length * 0.75) - n * 1.5, grip + d * (length * 0.75) + n * 2.0, P.BRASS, 2.0)
	P.muzzle_flash(ci, muzzle, ang, 9.0 if kind != "blunderbuss" else 15.0, flash)
	return muzzle


static func _flash_strength(atk: float) -> float:
	return clampf((atk - 0.7) / 0.3, 0.0, 1.0)


# ------------------------------------------------------------------ units
static func _militia(ci: CanvasItem, a) -> void:
	var s = {"coat": P.LEATHER, "coat_d": P.LEATHER_D, "beard": Color("a5532a"), "helmet": "miner", "helm_col": Color("9a8a52")}
	var b = body(ci, a, s)
	var atk: float = P.g(a, "atk", 0.0)
	# pickaxe swing: raised at windup, struck down as atk decays
	var swing = lerpf(0.9, -2.2, clampf(atk * 1.4 - 0.2, 0.0, 1.0)) if atk > 0.0 else -0.5
	var hand: Vector2 = b.shoulder_f + Vector2(cos(swing), sin(swing)) * 11.0
	arm(ci, b.shoulder_b, b.shoulder_f + Vector2(-2, 9), P.LEATHER_D)
	var shaft_ang = swing - 0.25
	P.bar(ci, hand - Vector2(cos(shaft_ang), sin(shaft_ang)) * 6, shaft_ang, 24, 3.0, P.WOOD, 1.5)
	var tip = hand + Vector2(cos(shaft_ang), sin(shaft_ang)) * 17
	var pn = Vector2(-sin(shaft_ang), cos(shaft_ang))
	P.poly(ci, P.pts([tip - pn * 10, tip + pn * 2 - Vector2(cos(shaft_ang), sin(shaft_ang)) * 2, tip + pn * 9, tip + pn * 2 + Vector2(cos(shaft_ang), sin(shaft_ang)) * 3]), P.STEEL, 1.5)
	arm(ci, b.shoulder_f, hand, P.LEATHER)


static func _rifleman(ci: CanvasItem, a) -> void:
	var s = {"coat": P.DEEP_BLUE, "beard": Color("6b4127"), "helmet": "kettle", "helm_col": P.IRON, "pauldron": true}
	var b = body(ci, a, s)
	var atk: float = P.g(a, "atk", 0.0)
	var rel: float = P.g(a, "reload", 0.0)
	var recoil = atk * atk * 4.0
	if rel > 0.0 and atk < 0.55:
		# reload: rifle tilted up, ramrod driven down the barrel
		var ang = -1.05
		var grip: Vector2 = b.shoulder_f + Vector2(2, 9)
		arm(ci, b.shoulder_b, grip + Vector2(-2, 2), P.DEEP_BLUE_D)
		var muzzle = rifle(ci, grip, ang, 30.0, 0.0)
		var ram = sin(P.g(a, "t", 0.0) * 14.0) * 5.0
		var d = Vector2(cos(ang), sin(ang))
		ci.draw_line(muzzle + d * (6 + ram), muzzle - d * (6 - ram), P.STEEL, 1.5)
		arm(ci, b.shoulder_f, muzzle + d * (5 + ram) + Vector2(-2, 0), P.DEEP_BLUE)
	else:
		var aim: float = P.g(a, "aim0", 0.0)
		var grip2: Vector2 = b.shoulder_f + Vector2(2 - recoil, 7)
		arm(ci, b.shoulder_b, grip2 + Vector2(-2, 1), P.DEEP_BLUE_D)
		rifle(ci, grip2, aim, 32.0, _flash_strength(atk))
		arm(ci, b.shoulder_f, grip2 + Vector2(cos(aim), sin(aim)) * 12, P.DEEP_BLUE)


static func _shieldbearer(ci: CanvasItem, a) -> void:
	var s = {"coat": Color("5a6470"), "coat_d": Color("3c434c"), "beard": Color("c9a050"), "helmet": "great", "helm_col": P.STEEL, "pauldron": true}
	var b = body(ci, a, s)
	var atk: float = P.g(a, "atk", 0.0)
	var push = sin(clampf(atk, 0.0, 1.0) * PI) * 6.0
	# hammer behind
	arm(ci, b.shoulder_b, b.shoulder_b + Vector2(-5, 10), Color("3c434c"))
	P.bar(ci, b.shoulder_b + Vector2(-5, 10), -1.9, 16, 2.5, P.WOOD, 1.2)
	P.rect(ci, Rect2(b.shoulder_b.x - 13, b.shoulder_b.y - 9, 8, 6), P.IRON, 1.5)
	# tower shield
	var sx = 12.0 + push
	var y: float = b.y
	var sh = P.pts([Vector2(sx, -46 + y), Vector2(sx + 9, -44 + y), Vector2(sx + 10, -6 + y), Vector2(sx + 5, 1 + y), Vector2(sx - 1, -6 + y)])
	P.poly(ci, sh, P.IRON, 2.0)
	P.poly(ci, P.pts([Vector2(sx + 1, -43 + y), Vector2(sx + 8, -41 + y), Vector2(sx + 8.5, -8 + y), Vector2(sx + 5, -3 + y), Vector2(sx + 1, -8 + y)]), P.STEEL, 0.0)
	P.circ(ci, Vector2(sx + 5, -24 + y), 4.0, P.BRASS, 1.5)
	ci.draw_line(Vector2(sx + 5, -38 + y), Vector2(sx + 5, -30 + y), P.FORGE.darkened(0.2), 1.5)
	ci.draw_line(Vector2(sx + 3, -34 + y), Vector2(sx + 7, -34 + y), P.FORGE.darkened(0.2), 1.5)
	P.rivets(ci, Vector2(sx + 2, -44 + y), Vector2(sx + 2, -6 + y), 6, P.BRASS)
	arm(ci, b.shoulder_f, Vector2(sx, -24 + y), Color("5a6470"))


static func _blunderbussier(ci: CanvasItem, a) -> void:
	var s = {"coat": Color("6e3b2a"), "coat_d": Color("4a271b"), "beard": Color("3a2f2a"), "helmet": "goggle_cap", "helm_col": P.LEATHER}
	var b = body(ci, a, s)
	var atk: float = P.g(a, "atk", 0.0)
	var recoil = atk * atk * 7.0
	var aim: float = P.g(a, "aim0", 0.0) - atk * 0.25
	var grip: Vector2 = b.shoulder_f + Vector2(2 - recoil, 8)
	arm(ci, b.shoulder_b, grip + Vector2(-1, 1), Color("4a271b"))
	rifle(ci, grip, aim, 26.0, _flash_strength(atk), "blunderbuss")
	arm(ci, b.shoulder_f, grip + Vector2(cos(aim), sin(aim)) * 10, Color("6e3b2a"))
	if atk > 0.7:
		var d = Vector2(cos(aim), sin(aim))
		var m = grip + d * 26
		for i in 5:
			var sp = (float(i) - 2.0) * 0.12
			ci.draw_line(m, m + Vector2(cos(aim + sp), sin(aim + sp)) * (20 + i * 3), Color(1, 0.8, 0.4, (atk - 0.7) * 2.5), 1.5)


static func _grenadier(ci: CanvasItem, a) -> void:
	var s = {"coat": Color("4e5a3a"), "coat_d": Color("343d26"), "beard": Color("a5532a"), "helmet": "cap", "helm_col": Color("6b5a3a")}
	var b = body(ci, a, s)
	var y: float = b.y
	# bandolier with bombs
	ci.draw_line(Vector2(-11, -33 + y), Vector2(11, -17 + y), P.LEATHER_D, 4.0)
	for i in 3:
		var p = Vector2(-7 + i * 7, -29 + y + i * 5)
		P.circ(ci, p, 3.2, P.COAL, 1.2)
		ci.draw_line(p + Vector2(0, -3), p + Vector2(1, -5), P.BRASS, 1.2)
	var atk: float = P.g(a, "atk", 0.0)
	# throw: arm swings from back (windup) over the top
	var ang = lerpf(-0.6, -2.6, clampf(atk, 0.0, 1.0)) if atk > 0.0 else 0.6
	var hand: Vector2 = b.shoulder_f + Vector2(cos(ang), sin(ang)) * 12.0
	arm(ci, b.shoulder_b, b.shoulder_b + Vector2(3, 10), Color("343d26"))
	arm(ci, b.shoulder_f, hand, Color("4e5a3a"))
	if atk < 0.35:
		P.circ(ci, hand + Vector2(1, -3), 4.0, P.COAL, 1.5)
		var sp: float = P.g(a, "t", 0.0) * 30.0
		ci.draw_circle(hand + Vector2(3, -8), 1.5 + sin(sp) * 0.6, Color(1, 0.75, 0.3))


static func _mechanic(ci: CanvasItem, a) -> void:
	var s = {"coat": Color("b56a2a"), "coat_d": Color("7e4519"), "beard": Color("9a9a9a"), "helmet": "goggle_cap", "helm_col": Color("6a3d1d")}
	# toolbox backpack
	var moving: bool = P.g(a, "state", "") == "move"
	var bob = absf(sin(P.g(a, "walk", 0.0))) * 1.6 if moving else 0.0
	P.rrect(ci, Rect2(-20, -36 - bob, 11, 18), Color("8e3a2e"), 2.0, 2.0)
	ci.draw_line(Vector2(-19, -30 - bob), Vector2(-10, -30 - bob), P.BRASS, 2.0)
	var b = body(ci, a, s)
	var rep: float = P.g(a, "special", 0.0)
	var t: float = P.g(a, "t", 0.0)
	var ang = -0.3 + (sin(t * 16.0) * 0.6 if rep > 0.0 else 0.0)
	var hand: Vector2 = b.shoulder_f + Vector2(cos(ang), sin(ang)) * 12
	arm(ci, b.shoulder_b, b.shoulder_b + Vector2(4, 11), Color("7e4519"))
	# giant wrench
	var d = Vector2(cos(ang - 0.4), sin(ang - 0.4))
	P.bar(ci, hand - d * 3, ang - 0.4, 18, 3.5, P.STEEL, 1.5)
	var head = hand + d * 16
	P.poly(ci, P.pts([head + Vector2(-3, -5), head + Vector2(5, -6), head + Vector2(6, -1), head + Vector2(2, 0), head + Vector2(6, 3), head + Vector2(4, 6), head + Vector2(-3, 4)]), P.STEEL, 1.5)
	arm(ci, b.shoulder_f, hand, Color("b56a2a"))
	if rep > 0.0 and fmod(t * 7.0, 1.0) < 0.5:
		for i in 3:
			var sp = head + Vector2(6 + i * 2, -3 + i * 3)
			ci.draw_line(sp, sp + Vector2(4, -2 + i), Color(1, 0.9, 0.4), 1.2)
