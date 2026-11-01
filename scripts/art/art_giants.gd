class_name ArtGiants
extends RefCounted
## M002b undead giants: one shared organic rig (IK legs that plant their feet, hunched weight,
## tapered flesh/bone limbs) + 12 giant designs expressed as data. Drawn ~110 design units
## tall, facing right, origin at the feet — the same convention as the war frames, so a giant
## and the frame of its size class stand eye to eye.
##
## Animation inputs (via Painter.g): t, walk, state, atk, atk2, windup, ability_anim, hurt,
## hp_frac, stun_t, engage.

const P = preload("res://scripts/art/painter.gd")
const M = preload("res://scripts/art/art_mechs.gd")

const ROT := Color("6f7a5c")
const ROT_D := Color("4c563f")
const ROT_L := Color("94a07c")
const SICK := Color("c9c45c")
const GORE := Color("5a2a2a")
const GORE_D := Color("3a1a1c")
const BONE := Color("e2dac0")
const BONE_D := Color("aa9f80")
const BONE_DD := Color("7d7460")
const ROBE := Color("2e2a33")
const ROBE_D := Color("1d1a21")
const BARK := Color("3e3428")
const BARK_D := Color("2a231b")
const STONE := Color("6d6a66")
const STONE_D := Color("4a4845")
const RUSTI := Color("6e4a34")
const VIOL := Color(0.62, 0.35, 0.95)
const NEC := Color(0.43, 1.0, 0.55)
const SPORE := Color(0.85, 0.95, 0.35)

## body: hulk · stitched · bone · bloat · mound · lanky · robe · tree · carrier · maw · quad
const G := {
	"carrion_bull":          {"body": "quad", "skin": Color("6b4a3e"), "skin_d": Color("47302a"), "head": "bull", "back": "spikes", "glow": SICK, "arm": ""},
	"bone_golem":            {"body": "bone", "skin": BONE, "skin_d": BONE_D, "head": "skull", "back": "spikes", "glow": NEC, "arm": "club", "arm_far": "club", "leg_w": 11.0},
	"plague_beast":          {"body": "bloat", "skin": Color("8b955f"), "skin_d": Color("5f6a3f"), "head": "snout", "back": "pustules", "glow": SICK, "arm": "claws", "short": true},
	"stitchback_giant":      {"body": "stitched", "skin": Color("a0927e"), "skin_d": Color("6e6352"), "head": "sack", "back": "hooks", "glow": Color(1.0, 0.45, 0.3), "arm": "cleaver", "arm_far": "cleaver"},
	"ossuary_juggernaut":    {"body": "bone_armor", "skin": BONE_D, "skin_d": BONE_DD, "head": "helm_skull", "back": "spikes", "glow": NEC, "arm": "maul", "arm_far": "coffin", "leg_w": 12.0},
	"corpse_mound":          {"body": "mound", "skin": ROT, "skin_d": ROT_D, "head": "none", "back": "corpses", "glow": NEC, "arm": "fist", "short": true},
	"ghoul_matriarch":       {"body": "lanky", "skin": Color("8c8a92"), "skin_d": Color("5d5b66"), "head": "ghoul", "back": "crown", "glow": Color(0.95, 0.35, 0.45), "arm": "claws", "arm_far": "claws", "digit": true, "tall": 8.0},
	"cathedral_ghast":       {"body": "robe", "skin": ROBE, "skin_d": ROBE_D, "head": "hood", "back": "bell_tower", "glow": Color(0.55, 0.85, 1.0), "arm": "bell", "arm_far": ""},
	"blackroot_abomination": {"body": "tree", "skin": BARK, "skin_d": BARK_D, "head": "knot", "back": "branches", "glow": Color(0.95, 0.55, 0.2), "arm": "roots", "arm_far": "roots", "roots": true},
	"walking_crypt":         {"body": "carrier", "skin": Color("7c8070"), "skin_d": Color("555a4b"), "head": "skull_big", "back": "crypt", "glow": NEC, "arm": "slab", "arm_far": "fist"},
	"plague_colossus":       {"body": "bloat_big", "skin": Color("7f8a55"), "skin_d": Color("56603a"), "head": "mask", "back": "spores", "glow": SPORE, "arm": "fist", "arm_far": "fist", "leg_w": 17.0},
	"rift_maw":              {"body": "maw", "skin": Color("4a3f5a"), "skin_d": Color("2f2740"), "head": "horns", "back": "rift", "glow": VIOL, "arm": "talons", "arm_far": "talons", "leg_w": 17.0},
}


static func has(art: String) -> bool:
	return G.has(art)


# ================================================================== primitives
## Tapered limb (flesh / bone), outlined, with rounded joints.
static func tl(ci: CanvasItem, a: Vector2, b: Vector2, w0: float, w1: float, col: Color, ow: float = 2.0) -> void:
	var d = (b - a)
	if d.length() < 0.01:
		return
	var n = d.normalized().orthogonal()
	P.poly(ci, P.pts([a + n * w0 * 0.5, b + n * w1 * 0.5, b - n * w1 * 0.5, a - n * w0 * 0.5]), col, ow)
	P.circ(ci, a, w0 * 0.5, col, ow)
	P.circ(ci, b, w1 * 0.5, col, ow)


static func eye(ci: CanvasItem, at: Vector2, col: Color, r: float) -> void:
	ci.draw_circle(at, r * 2.6, Color(col.r, col.g, col.b, 0.25))
	ci.draw_circle(at, r, col)


static func arm_angle(a, idx: int, rest: float, t: float, walk: float, moving: bool) -> float:
	var atk: float = P.g(a, "atk" if idx == 0 else "atk2", 0.0)
	var wind: float = P.g(a, "windup", 0.0) if idx == 0 else 0.0
	if wind > 0.0:
		return lerpf(rest, -2.3, clampf(wind * 2.0, 0.0, 1.0))
	if atk > 0.0:
		return lerpf(rest + 0.25, -2.3, clampf(atk * atk, 0.0, 1.0))
	var swing = sin(walk + (0.0 if idx == 0 else PI)) * 0.25 if moving else sin(t * 1.3 + idx) * 0.05
	return rest + swing


# ================================================================== main
static func draw(ci: CanvasItem, art: String, a) -> void:
	var cfg: Dictionary = G[art]
	if cfg.body == "quad":
		_quad(ci, cfg, a)
		return
	var t: float = P.g(a, "t", 0.0)
	var moving: bool = P.g(a, "state", "idle") == "move"
	var walk: float = P.g(a, "walk", 0.0)
	var hurt: float = P.g(a, "hurt", 0.0)
	var windup: float = P.g(a, "windup", 0.0)
	var abil: float = P.g(a, "ability_anim", 0.0)
	var hpf: float = P.g(a, "hp_frac", 1.0)
	var stun: bool = P.g(a, "stun_t", 0.0) > 0.0
	var short: bool = cfg.get("short", false)
	var tall: float = cfg.get("tall", 0.0)
	var leg_w: float = cfg.get("leg_w", 14.0)
	var thigh: float = (16.0 if short else 21.0) + tall * 0.5
	var shin: float = (15.0 if short else 21.0) + tall * 0.5
	var bob: float = (1.0 - absf(sin(walk))) * 3.0 if moving else sin(t * 1.4) * 0.8
	var sway: float = sin(walk) * 2.0 if moving else 0.0
	var crouch: float = windup * 5.0 + (3.0 if stun else 0.0) + abil * 2.0
	var hip = Vector2(sway - hurt * 2.0, -(thigh + shin) * 0.88 + bob + crouch)
	var digit: bool = cfg.get("digit", false)
	# ---- far leg
	var ff: Array = M.foot_pos(walk + PI, 10.0, 7.0, moving, -6.0)
	var fn: Array = M.foot_pos(walk, 10.0, 7.0, moving, 6.0)
	var skin: Color = cfg.skin
	var skin_d: Color = cfg.skin_d
	if cfg.body == "robe":
		_robe_feet(ci, ff[0], fn[0], skin_d)
	else:
		_leg(ci, hip + Vector2(-5, 0), ff[0], thigh, shin, leg_w, skin_d, digit, cfg.get("roots", false), cfg.body.begins_with("bone"))
	# ---- torso frame (returns anchors)
	var lean: float = 0.12 + windup * 0.08 + hurt * -0.05 + (sin(walk) * 0.03 if moving else 0.0)
	var anc: Dictionary = _anchors(cfg, hip, lean)
	# far arm behind the body
	if String(cfg.get("arm_far", "")) != "":
		_arm(ci, cfg, a, anc.sh_far, 1, String(cfg.arm_far), skin_d, t, walk, moving)
	_back(ci, cfg, a, anc, t)
	_torso(ci, cfg, a, anc, hip, t, hpf)
	_head(ci, cfg, a, anc.head, t, abil)
	# ---- near leg
	if cfg.body != "robe":
		_leg(ci, hip + Vector2(5, 0), fn[0], thigh, shin, leg_w, skin, digit, cfg.get("roots", false), cfg.body.begins_with("bone"))
	# ---- near arm (primary weapon)
	if String(cfg.arm) != "":
		_arm(ci, cfg, a, anc.sh, 0, String(cfg.arm), skin, t, walk, moving)
	# ability aura / necrotic surge
	if abil > 0.05:
		var gc: Color = cfg.glow
		ci.draw_circle(anc.chest, 26.0 + abil * 10.0, Color(gc.r, gc.g, gc.b, 0.16 * abil))
		ci.draw_circle(anc.chest, 14.0 + abil * 6.0, Color(gc.r, gc.g, gc.b, 0.22 * abil))
	if stun:
		for i in 3:
			var ang = t * 3.0 + TAU * i / 3.0
			ci.draw_circle(anc.head + Vector2(cos(ang) * 12.0, -14 + sin(ang) * 4.0), 2.0, Color(0.9, 0.9, 1.0, 0.8))


static func _anchors(cfg: Dictionary, hip: Vector2, lean: float) -> Dictionary:
	var up = Vector2(sin(lean), -cos(lean))
	var fw = Vector2(cos(lean), sin(lean))
	var h = 58.0 + float(cfg.get("tall", 0.0))
	var body: String = cfg.body
	var sh_y = 0.82
	var head_k = 1.0
	var head_fw = 10.0
	match body:
		"bloat", "bloat_big":
			head_fw = 14.0
			head_k = 0.92
		"carrier":
			head_fw = 26.0
			head_k = 0.78
			sh_y = 0.7
		"maw":
			head_k = 1.02
			head_fw = 4.0
		"mound":
			head_k = 0.9
		"robe":
			head_fw = 8.0
	return {
		"chest": hip + up * h * 0.5 + fw * 6.0,
		"sh": hip + up * h * sh_y + fw * 16.0,
		"sh_far": hip + up * h * sh_y - fw * 10.0,
		"head": hip + up * h * head_k + fw * head_fw,
		"back": hip + up * h * 0.86 - fw * 16.0,
		"up": up, "fw": fw, "h": h, "hip": hip,
	}


static func _leg(ci: CanvasItem, hip: Vector2, foot: Vector2, l1: float, l2: float, w: float, col: Color, digit: bool, roots: bool, bony: bool) -> void:
	var knee = M.ik_knee(hip, foot, l1, l2, -1.0 if digit else 1.0)
	if bony:
		tl(ci, hip, knee, w * 0.55, w * 0.45, col)
		tl(ci, knee, foot + Vector2(0, -3), w * 0.45, w * 0.4, col)
		P.circ(ci, knee, w * 0.42, col.darkened(0.15), 2.0)
	else:
		tl(ci, hip, knee, w * 1.15, w * 0.85, col)
		tl(ci, knee, foot + Vector2(0, -3), w * 0.85, w * 0.7, col)
	if roots:
		for i in 3:
			var d = Vector2(-10 + i * 10, 0)
			P.poly(ci, P.pts([foot + Vector2(-3, -4), foot + d + Vector2(4, 1), foot + d + Vector2(-2, 2)]), col.darkened(0.2), 1.5)
	else:
		P.poly(ci, P.pts([foot + Vector2(-w * 0.55, -5), foot + Vector2(w * 0.9, -5), foot + Vector2(w * 1.05, 0), foot + Vector2(-w * 0.6, 0)]), col.darkened(0.25), 2.0)
		if not bony:
			for i in 3:
				ci.draw_line(foot + Vector2(w * 0.6 + i * 2.0, -1), foot + Vector2(w * 1.15 + i * 2.0, 1), BONE_D, 2.0)


static func _robe_feet(ci: CanvasItem, f1: Vector2, f2: Vector2, col: Color) -> void:
	for f in [f1, f2]:
		P.poly(ci, P.pts([f + Vector2(-6, -6), f + Vector2(10, -5), f + Vector2(13, 0), f + Vector2(-7, 0)]), BONE_D, 1.5)


# ================================================================== torso
static func _torso(ci: CanvasItem, cfg: Dictionary, a, anc: Dictionary, hip: Vector2, t: float, hpf: float) -> void:
	var up: Vector2 = anc.up
	var fw: Vector2 = anc.fw
	var h: float = anc.h
	var skin: Color = cfg.skin
	var skin_d: Color = cfg.skin_d
	var gc: Color = cfg.glow
	var at = func(x: float, y: float) -> Vector2: return hip + fw * x + up * y
	match String(cfg.body):
		"hulk", "stitched":
			P.poly(ci, P.pts([at.call(-22, 0), at.call(-30, h * 0.45), at.call(-20, h * 0.9), at.call(4, h * 1.02), at.call(24, h * 0.9), at.call(30, h * 0.5), at.call(20, -2)]), skin, 2.5)
			P.poly(ci, P.pts([at.call(-16, h * 0.55), at.call(-8, h * 0.85), at.call(10, h * 0.9), at.call(2, h * 0.6)]), skin.lightened(0.12), 0.0)
			# seams with cross-stitches
			for seam in [[Vector2(-14, 6), Vector2(8, h * 0.88)], [Vector2(16, 4), Vector2(22, h * 0.7)], [Vector2(-24, h * 0.4), Vector2(18, h * 0.42)]]:
				var s0: Vector2 = at.call(seam[0].x, seam[0].y)
				var s1: Vector2 = at.call(seam[1].x, seam[1].y)
				ci.draw_line(s0, s1, GORE_D, 2.0)
				for i in 6:
					var p = s0.lerp(s1, (i + 0.5) / 6.0)
					var n = (s1 - s0).normalized().orthogonal() * 3.5
					ci.draw_line(p - n, p + n, Color("2a2420"), 1.5)
			# patch of different skin
			P.poly(ci, P.pts([at.call(-20, h * 0.15), at.call(-6, h * 0.12), at.call(-4, h * 0.34), at.call(-22, h * 0.32)]), Color("8a7f9a"), 1.5)
			# belt of chains
			ci.draw_line(at.call(-24, 4), at.call(22, 2), Color("4a4a4e"), 4.0)
		"bone", "bone_armor":
			# necrotic core behind the ribcage
			ci.draw_circle(at.call(0, h * 0.55), 14.0, Color(gc.r, gc.g, gc.b, 0.25))
			P.circ(ci, at.call(0, h * 0.55), 8.0, gc.darkened(0.2), 1.5)
			# spine + pelvis
			tl(ci, at.call(-6, 0), at.call(-4, h * 0.95), 7.0, 6.0, skin_d)
			P.poly(ci, P.pts([at.call(-18, -4), at.call(16, -4), at.call(12, 8), at.call(-14, 8)]), skin, 2.0)
			# ribs
			for i in 5:
				var y = h * (0.45 + i * 0.1)
				var r = 20.0 - absf(i - 2.0) * 3.0
				var c0: Vector2 = at.call(-4, y)
				P.poly(ci, P.pts([c0, c0 + fw * r + up * 3.0, c0 + fw * (r + 4.0) - up * 5.0, c0 - up * 4.0]), skin, 1.8)
			if cfg.body == "bone_armor":
				# skull-plated chest armour
				P.poly(ci, P.pts([at.call(-8, h * 0.4), at.call(26, h * 0.46), at.call(28, h * 0.92), at.call(-6, h * 1.0)]), RUSTI, 2.5)
				for i in 3:
					var sp: Vector2 = at.call(8 + (i % 2) * 8, h * (0.55 + i * 0.13))
					P.circ(ci, sp, 4.5, BONE, 1.5)
					ci.draw_circle(sp + Vector2(1.5, 0), 1.2, Color(0.1, 0.1, 0.1))
				P.poly(ci, P.pts([at.call(-24, h * 0.86), at.call(4, h * 1.04), at.call(-2, h * 0.84)]), RUSTI.darkened(0.2), 2.0)
		"bloat", "bloat_big":
			var big = cfg.body == "bloat_big"
			var bc: Vector2 = at.call(10, h * 0.42)
			P.ell(ci, bc, 32.0 if big else 28.0, 30.0 if big else 25.0, skin, 2.5, 0.2)
			P.ell(ci, at.call(-6, h * 0.78), 24.0, 20.0, skin_d, 2.5)
			P.ell(ci, bc + Vector2(-4, -8), 18.0, 12.0, skin.lightened(0.12), 0.0, 0.2)
			# glowing pustules / belly vents
			for i in (7 if big else 5):
				var ang = -0.4 + i * 0.55
				var pp = bc + Vector2(cos(ang) * 22.0, sin(ang) * 18.0)
				var pulse = 0.5 + 0.5 * sin(t * 3.0 + i * 1.7)
				P.circ(ci, pp, 3.5 + pulse * 1.2, SICK.darkened(0.1), 1.2)
				ci.draw_circle(pp, 1.8, Color(gc.r, gc.g, gc.b, 0.6 + 0.4 * pulse))
			if big:
				# belly furnace of plague (the mortar's maw)
				var bm: Vector2 = bc + Vector2(12, 6)
				var atk2: float = P.g(a, "atk2", 0.0) + P.g(a, "atk3", 0.0)
				P.ell(ci, bm, 9.0, 6.0 + atk2 * 4.0, GORE_D, 2.0)
				ci.draw_circle(bm, 5.0, Color(gc.r, gc.g, gc.b, 0.5 + 0.5 * minf(1.0, atk2)))
		"mound":
			P.poly(ci, P.pts([at.call(-34, -2), at.call(-38, h * 0.4), at.call(-24, h * 0.82), at.call(0, h * 0.95), at.call(24, h * 0.8), at.call(36, h * 0.38), at.call(30, -2)]), skin, 2.5)
			# corpses in the heap: limbs, ribcages, faces
			var r = RandomNumberGenerator.new()
			r.seed = 77
			for i in 9:
				var p0: Vector2 = at.call(r.randf_range(-28, 26), r.randf_range(8, h * 0.8))
				var ang = r.randf_range(-PI, PI) + sin(t * 1.5 + i) * 0.15
				tl(ci, p0, p0 + Vector2(cos(ang), sin(ang)) * r.randf_range(9, 15), 4.5, 3.5, ROT_L if i % 2 == 0 else ROT_D, 1.5)
			for i in 5:
				var fc: Vector2 = at.call(r.randf_range(-22, 22), r.randf_range(14, h * 0.75))
				P.circ(ci, fc, 5.5, ROT_L, 1.5)
				eye(ci, fc + Vector2(2, -1), cfg.glow, 1.1)
				ci.draw_line(fc + Vector2(-2, 2.5), fc + Vector2(3, 2.5), GORE_D, 1.5)
			# heaving belly opening (Disgorge)
			var ab: float = P.g(a, "ability_anim", 0.0)
			if ab > 0.05:
				P.ell(ci, at.call(14, h * 0.3), 10.0 * ab + 2.0, 8.0 * ab + 2.0, GORE_D, 2.0)
				ci.draw_circle(at.call(14, h * 0.3), 6.0 * ab, Color(gc.r, gc.g, gc.b, 0.6))
		"lanky":
			P.poly(ci, P.pts([at.call(-8, -2), at.call(-12, h * 0.5), at.call(-6, h * 0.96), at.call(14, h * 1.0), at.call(18, h * 0.55), at.call(8, -2)]), skin, 2.2)
			for i in 4:
				var y = h * (0.5 + i * 0.1)
				ci.draw_arc(at.call(2, y), 10.0, -0.4, 1.2, 6, skin_d, 2.0)
			# rag sash
			P.poly(ci, P.pts([at.call(-12, h * 0.15), at.call(16, h * 0.25), at.call(14, h * 0.1), at.call(-10, -4)]), Color("4a2e3a"), 1.5)
		"robe":
			var sw = sin(t * 1.4) * 2.0 + (sin(P.g(a, "walk", 0.0)) * 3.0 if P.g(a, "state", "") == "move" else 0.0)
			var robe = PackedVector2Array([at.call(-14, h * 1.0), at.call(18, h * 1.02), at.call(28, h * 0.5)])
			for i in 9:
				var x = lerpf(30.0, -32.0, i / 8.0) + sw * (1.0 - absf(i - 4) / 4.0)
				robe.append(Vector2(hip.x + x, -2.0 - (4.0 if i % 2 == 0 else 0.0)))
			robe.append(at.call(-30, h * 0.45))
			P.poly(ci, robe, skin, 2.5)
			P.poly(ci, P.pts([at.call(-4, h * 0.95), at.call(10, h * 0.98), at.call(12, h * 0.2), at.call(0, h * 0.18)]), skin.lightened(0.08), 0.0)
			# rope belt + hanging censer chains
			ci.draw_line(at.call(-24, h * 0.5), at.call(24, h * 0.52), Color("6a5a3c"), 3.0)
			for i in 3:
				var cp: Vector2 = at.call(-10 + i * 10, h * 0.5)
				ci.draw_line(cp, cp + Vector2(sin(t * 1.5 + i) * 2.0, 12.0), Color("4a4a4e"), 1.5)
				P.circ(ci, cp + Vector2(sin(t * 1.5 + i) * 2.0, 14.0), 2.5, BONE_D, 1.0)
		"tree":
			P.poly(ci, P.pts([at.call(-20, -2), at.call(-26, h * 0.5), at.call(-14, h * 0.95), at.call(10, h * 1.02), at.call(26, h * 0.6), at.call(20, -2)]), skin, 2.5)
			# bark ridges + ember cracks
			for i in 5:
				var x0 = -16.0 + i * 8.0
				ci.draw_line(at.call(x0, 4), at.call(x0 + 4.0, h * 0.9), skin_d, 2.5)
			for crack in [[Vector2(-6, h * 0.3), Vector2(4, h * 0.55)], [Vector2(8, h * 0.6), Vector2(-2, h * 0.82)]]:
				var g0: Vector2 = at.call(crack[0].x, crack[0].y)
				var g1: Vector2 = at.call(crack[1].x, crack[1].y)
				ci.draw_line(g0, g1, Color(cfg.glow.r, cfg.glow.g, cfg.glow.b, 0.5 + 0.3 * sin(t * 2.0)), 3.0)
			# a giant's ribcage swallowed by the trunk
			for i in 3:
				ci.draw_arc(at.call(6, h * (0.4 + i * 0.1)), 9.0, -0.3, 1.4, 6, BONE_D, 2.5)
		"carrier":
			# hunched back under the crypt
			P.poly(ci, P.pts([at.call(-18, -2), at.call(-26, h * 0.5), at.call(-10, h * 0.85), at.call(18, h * 0.82), at.call(30, h * 0.55), at.call(18, -2)]), skin, 2.5)
			for i in 4:
				ci.draw_arc(at.call(4, h * (0.3 + i * 0.12)), 12.0, -0.5, 1.0, 6, skin_d, 2.0)
			# harness straps
			ci.draw_line(at.call(-20, h * 0.8), at.call(24, h * 0.4), RUSTI, 3.5)
			ci.draw_line(at.call(-16, h * 0.4), at.call(20, h * 0.78), RUSTI, 3.5)
		"maw":
			var open: float = clampf(P.g(a, "atk", 0.0) + P.g(a, "windup", 0.0) * 1.5 + P.g(a, "ability_anim", 0.0), 0.0, 1.0)
			P.poly(ci, P.pts([at.call(-26, -2), at.call(-32, h * 0.5), at.call(-18, h * 0.96), at.call(10, h * 1.04), at.call(32, h * 0.7), at.call(34, h * 0.3), at.call(22, -2)]), skin, 2.5)
			# the mouth: torso splits open
			var mc: Vector2 = at.call(18, h * 0.5)
			var mh = 6.0 + open * 16.0
			P.ell(ci, mc, 16.0, mh, GORE_D, 2.5)
			ci.draw_circle(mc, minf(12.0, mh) * 0.7, Color(VIOL.r, VIOL.g, VIOL.b, 0.35 + open * 0.4))
			for i in 7:
				var tx = -12.0 + i * 4.0
				P.poly(ci, P.pts([mc + Vector2(tx, -mh + 1), mc + Vector2(tx + 3.5, -mh + 1), mc + Vector2(tx + 1.7, -mh + 7)]), BONE, 1.0)
				P.poly(ci, P.pts([mc + Vector2(tx, mh - 1), mc + Vector2(tx + 3.5, mh - 1), mc + Vector2(tx + 1.7, mh - 7)]), BONE, 1.0)
			# rift veins
			for i in 4:
				var v0: Vector2 = at.call(-20 + i * 6, h * 0.2)
				ci.draw_line(v0, v0 + up * 26.0 + fw * 4.0, Color(VIOL.r, VIOL.g, VIOL.b, 0.45 + 0.25 * sin(t * 2.5 + i)), 2.0)
	# battle damage
	if hpf < 0.55:
		for i in (2 if hpf > 0.3 else 4):
			var wp: Vector2 = hip + fw * (-12.0 + i * 9.0) + up * h * (0.35 + 0.13 * i)
			P.poly(ci, P.pts([wp + Vector2(-4, -2), wp + Vector2(5, -3), wp + Vector2(3, 3), wp + Vector2(-5, 2)]), GORE_D, 1.0)
			ci.draw_line(wp + Vector2(-2, 0), wp + Vector2(3, -1), BONE, 1.5)
		if hpf < 0.3:
			ci.draw_circle(anc.chest, 6.0, Color(cfg.glow.r, cfg.glow.g, cfg.glow.b, 0.35 + 0.2 * sin(t * 6.0)))


# ================================================================== heads
static func _head(ci: CanvasItem, cfg: Dictionary, a, hp: Vector2, t: float, abil: float) -> void:
	var gc: Color = cfg.glow
	var skin: Color = cfg.skin
	var atk: float = P.g(a, "atk", 0.0)
	var atk2: float = P.g(a, "atk2", 0.0)
	match String(cfg.head):
		"skull":
			P.poly(ci, P.pts([hp + Vector2(-8, -2), hp + Vector2(-6, -14), hp + Vector2(6, -16), hp + Vector2(12, -8), hp + Vector2(10, 2), hp + Vector2(-2, 4)]), BONE, 2.0)
			eye(ci, hp + Vector2(5, -8), gc, 2.0)
			P.poly(ci, P.pts([hp + Vector2(2, 2), hp + Vector2(12, 1 + atk * 4.0), hp + Vector2(10, 6 + atk * 4.0), hp + Vector2(0, 6)]), BONE_D, 1.5)
		"snout":
			var open = clampf(atk + atk2, 0.0, 1.0)
			P.poly(ci, P.pts([hp + Vector2(-10, -4), hp + Vector2(-4, -14), hp + Vector2(12, -12), hp + Vector2(22, -6), hp + Vector2(20, -2), hp + Vector2(-6, 2)]), skin, 2.0)
			P.poly(ci, P.pts([hp + Vector2(-4, 0), hp + Vector2(20, -2), hp + Vector2(18, 2 + open * 7.0), hp + Vector2(-2, 5)]), skin.darkened(0.2), 2.0)
			if open > 0.1:
				ci.draw_circle(hp + Vector2(20, 0 + open * 2.0), 4.0 * open, Color(gc.r, gc.g, gc.b, 0.8))
			eye(ci, hp + Vector2(6, -9), gc, 1.6)
			eye(ci, hp + Vector2(12, -9), gc, 1.2)
		"sack":
			P.poly(ci, P.pts([hp + Vector2(-9, 2), hp + Vector2(-10, -12), hp + Vector2(-2, -19), hp + Vector2(9, -16), hp + Vector2(11, -2), hp + Vector2(4, 4)]), Color("9a8460"), 2.0)
			for i in 4:
				ci.draw_line(hp + Vector2(-6 + i * 4, -17), hp + Vector2(-6 + i * 4, -15), Color("3a2a20"), 1.5)
			ci.draw_line(hp + Vector2(-9, -3), hp + Vector2(10, -4), Color("3a2a20"), 2.0)
			eye(ci, hp + Vector2(4, -9), gc, 2.2)
		"helm_skull":
			P.poly(ci, P.pts([hp + Vector2(-9, 2), hp + Vector2(-10, -12), hp + Vector2(-2, -20), hp + Vector2(10, -16), hp + Vector2(12, -2), hp + Vector2(2, 4)]), RUSTI, 2.2)
			P.poly(ci, P.pts([hp + Vector2(-2, -20), hp + Vector2(2, -28), hp + Vector2(4, -19)]), BONE_D, 1.5)
			ci.draw_line(hp + Vector2(0, -9), hp + Vector2(12, -9), Color(0.08, 0.06, 0.06), 3.0)
			eye(ci, hp + Vector2(7, -9), gc, 1.6)
		"ghoul":
			var open2 = clampf(atk2 * 1.2 + abil, 0.0, 1.0)
			P.poly(ci, P.pts([hp + Vector2(-8, -2), hp + Vector2(-6, -16), hp + Vector2(8, -18), hp + Vector2(18, -10), hp + Vector2(16, -4), hp + Vector2(0, 0)]), skin, 2.0)
			P.poly(ci, P.pts([hp + Vector2(0, 0), hp + Vector2(16, -4), hp + Vector2(16, 0 + open2 * 10.0), hp + Vector2(2, 4 + open2 * 4.0)]), skin.darkened(0.25), 2.0)
			for i in 3:
				P.poly(ci, P.pts([hp + Vector2(6 + i * 3, -3), hp + Vector2(8 + i * 3, -3), hp + Vector2(7 + i * 3, 1)]), BONE, 0.8)
			# hair strands
			for i in 5:
				var hb = hp + Vector2(-6 + i * 3, -16)
				ci.draw_line(hb, hb + Vector2(-10 - i * 2 + sin(t * 2.0 + i) * 2.0, 18 + i * 2), Color("2a2630"), 2.0)
			eye(ci, hp + Vector2(9, -11), gc, 1.6)
			eye(ci, hp + Vector2(4, -12), gc, 1.3)
		"hood":
			P.poly(ci, P.pts([hp + Vector2(-12, 4), hp + Vector2(-12, -14), hp + Vector2(-2, -24), hp + Vector2(10, -18), hp + Vector2(14, -2), hp + Vector2(8, 6)]), skin, 2.2)
			P.ell(ci, hp + Vector2(4, -6), 7.0, 9.0, Color(0.03, 0.03, 0.05), 0.0)
			eye(ci, hp + Vector2(2, -7), gc, 1.6)
			eye(ci, hp + Vector2(7, -7), gc, 1.6)
		"knot":
			P.poly(ci, P.pts([hp + Vector2(-10, 2), hp + Vector2(-8, -14), hp + Vector2(4, -20), hp + Vector2(14, -10), hp + Vector2(10, 4)]), BARK, 2.2)
			ci.draw_arc(hp + Vector2(2, -8), 6.0, 0, TAU, 10, BARK_D, 2.0)
			eye(ci, hp + Vector2(4, -9), gc, 2.0)
			eye(ci, hp + Vector2(-2, -6), gc, 1.3)
		"skull_big":
			P.poly(ci, P.pts([hp + Vector2(-10, 0), hp + Vector2(-8, -16), hp + Vector2(6, -20), hp + Vector2(16, -10), hp + Vector2(14, 2), hp + Vector2(0, 4)]), BONE, 2.2)
			eye(ci, hp + Vector2(8, -10), gc, 2.2)
			eye(ci, hp + Vector2(1, -10), gc, 1.6)
			P.poly(ci, P.pts([hp + Vector2(0, 3), hp + Vector2(14, 1 + atk * 5.0), hp + Vector2(12, 7 + atk * 5.0), hp + Vector2(-2, 7)]), BONE_D, 1.5)
		"mask":
			# swollen head behind a riveted plague beak
			P.circ(ci, hp + Vector2(0, -8), 11.0, skin, 2.2)
			P.poly(ci, P.pts([hp + Vector2(2, -12), hp + Vector2(26, -2), hp + Vector2(4, -2)]), Color("4a3a2c"), 2.0)
			P.rivets(ci, hp + Vector2(6, -8), hp + Vector2(20, -3), 3, Color("8a6a40"))
			P.circ(ci, hp + Vector2(4, -12), 3.5, Color(0.1, 0.1, 0.08), 1.2)
			ci.draw_circle(hp + Vector2(4, -12), 2.0, Color(gc.r, gc.g, gc.b, 0.8))
		"horns":
			P.poly(ci, P.pts([hp + Vector2(-10, 2), hp + Vector2(-8, -10), hp + Vector2(6, -14), hp + Vector2(14, -6), hp + Vector2(10, 4)]), cfg.skin_d, 2.2)
			P.poly(ci, P.pts([hp + Vector2(-6, -10), hp + Vector2(-18, -30), hp + Vector2(-2, -14)]), BONE_D, 1.8)
			P.poly(ci, P.pts([hp + Vector2(4, -13), hp + Vector2(12, -34), hp + Vector2(10, -12)]), BONE_D, 1.8)
			eye(ci, hp + Vector2(6, -6), gc, 2.0)
			eye(ci, hp + Vector2(0, -6), gc, 1.5)
		"none":
			pass


# ================================================================== arms + weapons
static func _arm(ci: CanvasItem, cfg: Dictionary, a, sh: Vector2, idx: int, kind: String, col: Color, t: float, walk: float, moving: bool) -> void:
	var bony: bool = String(cfg.body).begins_with("bone")
	var w: float = 12.0 if not bony else 7.0
	var len1: float = 22.0
	var len2: float = 22.0
	match kind:
		"claws", "talons":
			len1 = 26.0
			len2 = 26.0
			w = 9.0
		"roots":
			len1 = 26.0
			len2 = 30.0
			w = 10.0
		"fist":
			w = 14.0
	if cfg.body == "bloat_big" or cfg.body == "maw":
		w += 4.0
		len1 += 4.0
		len2 += 4.0
	var rest = 0.9 if kind != "coffin" else 0.25
	var ang: float = arm_angle(a, idx, rest, t, walk, moving)
	if kind == "coffin":
		ang = 0.2 + sin(t * 1.2) * 0.04
	var elbow = sh + Vector2.from_angle(ang) * len1
	var hand = elbow + Vector2.from_angle(ang + 0.55) * len2
	var acol = col if idx == 0 else col.darkened(0.12)
	tl(ci, sh, elbow, w * 1.1, w * 0.85, acol)
	tl(ci, elbow, hand, w * 0.85, w * 0.75, acol)
	var d = (hand - elbow).normalized()
	var n = d.orthogonal()
	var wind: float = P.g(a, "windup", 0.0)
	match kind:
		"club":
			P.poly(ci, P.pts([hand - n * 4.0, hand + d * 30.0 - n * 7.0, hand + d * 34.0 + n * 6.0, hand + n * 4.0]), BONE, 2.0)
			for i in 3:
				P.poly(ci, P.pts([hand + d * (16.0 + i * 6.0) + n * 5.0, hand + d * (18.0 + i * 6.0) + n * 11.0, hand + d * (20.0 + i * 6.0) + n * 5.0]), BONE_D, 1.2)
		"cleaver":
			P.poly(ci, P.pts([hand - n * 3.0, hand + d * 8.0 - n * 3.0, hand + d * 8.0 - n * 16.0, hand + d * 30.0 - n * 18.0, hand + d * 32.0 + n * 3.0, hand + n * 3.0]), Color("8a8e92"), 2.0)
			ci.draw_line(hand + d * 10.0 - n * 16.0, hand + d * 30.0 - n * 17.0, Color("c0c4c8"), 1.5)
			P.poly(ci, P.pts([hand + d * 18.0 - n * 12.0, hand + d * 24.0 - n * 10.0, hand + d * 22.0 - n * 6.0]), GORE, 0.0)
		"maul":
			ci.draw_line(hand - d * 6.0, hand + d * 30.0, BONE_D, 5.0)
			P.poly(ci, P.pts([hand + d * 24.0 - n * 12.0, hand + d * 38.0 - n * 12.0, hand + d * 38.0 + n * 12.0, hand + d * 24.0 + n * 12.0]), BONE, 2.2)
			P.circ(ci, hand + d * 31.0, 4.0, Color(0.1, 0.1, 0.1), 1.0)
		"coffin":
			# coffin-lid shield held across the body
			var c0 = hand + Vector2(10, -8)
			P.poly(ci, P.pts([c0 + Vector2(-4, -34), c0 + Vector2(8, -40), c0 + Vector2(12, 0), c0 + Vector2(8, 30), c0 + Vector2(-4, 34), c0 + Vector2(-8, 0)]), Color("5a4232"), 2.5)
			ci.draw_line(c0 + Vector2(2, -26), c0 + Vector2(2, 20), Color("8a7050"), 3.0)
			ci.draw_line(c0 + Vector2(-4, -12), c0 + Vector2(8, -12), Color("8a7050"), 3.0)
			P.rivets(ci, c0 + Vector2(-5, -30), c0 + Vector2(-5, 30), 5, Color("9a8a6a"))
		"claws", "talons":
			var spread = 0.35 + P.g(a, "atk" if idx == 0 else "atk2", 0.0) * 0.4
			for i in 3:
				var ca = d.angle() + (i - 1) * spread
				var tip = hand + Vector2.from_angle(ca) * (16.0 if kind == "claws" else 22.0)
				P.poly(ci, P.pts([hand + n * 2.0, tip, hand - n * 2.0]), BONE if kind == "claws" else Color("2a2030"), 1.5)
		"bell":
			# chain flail ending in a cracked bell
			var swing = sin(t * 2.0) * 0.3
			var b0 = hand + Vector2.from_angle(ang + 1.2 + swing) * 26.0
			for i in 5:
				var cp = hand.lerp(b0, (i + 0.5) / 5.0)
				ci.draw_arc(cp, 2.4, 0, TAU, 6, Color("5a5a60"), 1.5)
			P.poly(ci, P.pts([b0 + Vector2(-8, -6), b0 + Vector2(8, -6), b0 + Vector2(13, 12), b0 + Vector2(-13, 12)]), Color("8a7a4a"), 2.2)
			ci.draw_line(b0 + Vector2(-4, 0), b0 + Vector2(2, 10), Color("3a3020"), 1.5)
			if wind > 0.0:
				ci.draw_circle(b0 + Vector2(0, 4), 16.0 * wind, Color(cfg.glow.r, cfg.glow.g, cfg.glow.b, 0.25))
		"roots":
			var pts = PackedVector2Array([hand])
			for i in range(1, 6):
				var k = i / 5.0
				pts.append(hand + d * (k * 34.0) + n * sin(k * 5.0 + t * 3.0) * 5.0)
			ci.draw_polyline(pts, Color(0.09, 0.07, 0.07), 7.0)
			ci.draw_polyline(pts, BARK.lightened(0.1), 4.5)
			for i in 3:
				var tp: Vector2 = pts[i + 2]
				ci.draw_line(tp, tp + n * (6.0 if i % 2 == 0 else -6.0) + d * 4.0, BARK_D, 2.0)
		"slab":
			P.poly(ci, P.pts([hand - n * 10.0 - d * 4.0, hand + d * 30.0 - n * 12.0, hand + d * 32.0 + n * 10.0, hand + n * 10.0 - d * 2.0]), STONE, 2.5)
			ci.draw_line(hand + d * 6.0, hand + d * 26.0, STONE_D, 2.0)
			P.circ(ci, hand + d * 16.0 + n * 3.0, 3.0, BONE_D, 1.0)
		"fist":
			P.circ(ci, hand, w * 0.85, acol.darkened(0.1), 2.2)
			for i in 3:
				ci.draw_line(hand + n * (-4.0 + i * 4.0), hand + n * (-4.0 + i * 4.0) + d * 5.0, acol.darkened(0.35), 1.5)
			if wind > 0.0 and idx == 0:
				ci.draw_circle(hand, w * 1.6, Color(cfg.glow.r, cfg.glow.g, cfg.glow.b, 0.3 * wind))


# ================================================================== back pieces
static func _back(ci: CanvasItem, cfg: Dictionary, a, anc: Dictionary, t: float) -> void:
	var bp: Vector2 = anc.back
	var up: Vector2 = anc.up
	var fw: Vector2 = anc.fw
	var gc: Color = cfg.glow
	var atk2: float = P.g(a, "atk2", 0.0)
	var abil: float = P.g(a, "ability_anim", 0.0)
	match String(cfg.back):
		"spikes":
			for i in 4:
				var s0 = bp + fw * (-6.0 + i * 8.0) - up * (i * 4.0)
				P.poly(ci, P.pts([s0 - fw * 4.0, s0 + up * (14.0 + (i % 2) * 6.0) - fw * 6.0, s0 + fw * 4.0]), BONE_D, 1.5)
		"pustules":
			for i in 3:
				var pp = bp + fw * (-4.0 + i * 9.0) + up * (4.0 + (i % 2) * 4.0)
				P.circ(ci, pp, 6.0 + sin(t * 3.0 + i) * 0.8, SICK, 1.5)
				ci.draw_circle(pp, 2.5, Color(gc.r, gc.g, gc.b, 0.7))
		"hooks":
			for i in 3:
				var h0 = bp + fw * (-8.0 + i * 10.0) + up * 6.0
				ci.draw_line(h0, h0 + up * 14.0, Color("4a4a4e"), 2.0)
				ci.draw_arc(h0 + up * 16.0 + fw * 3.0, 4.0, PI * 0.5, PI * 1.6, 6, Color("8a8e92"), 2.0)
		"corpses":
			for i in 4:
				var c0 = bp + fw * (-14.0 + i * 9.0) + up * (2.0 + (i % 2) * 6.0)
				var ang = -1.2 + i * 0.5 + sin(t * 1.3 + i) * 0.2
				tl(ci, c0, c0 + Vector2.from_angle(ang) * 14.0, 5.0, 3.5, ROT_L, 1.5)
		"crown":
			for i in 5:
				var c0 = anc.head + up * 14.0 + fw * (-8.0 + i * 4.0)
				P.poly(ci, P.pts([c0 - fw * 1.5, c0 + up * (8.0 + (i % 2) * 5.0), c0 + fw * 1.5]), BONE, 1.0)
		"bell_tower":
			# ruined belfry strapped to the back: the bell glows when the dirge fires
			var b0 = bp - fw * 6.0
			P.poly(ci, P.pts([b0 - fw * 14.0, b0 + up * 44.0 - fw * 12.0, b0 + up * 52.0, b0 + up * 44.0 + fw * 12.0, b0 + fw * 14.0]), STONE, 2.5)
			P.poly(ci, P.pts([b0 + up * 30.0 - fw * 8.0, b0 + up * 42.0 - fw * 6.0, b0 + up * 42.0 + fw * 6.0, b0 + up * 30.0 + fw * 8.0]), Color(0.05, 0.05, 0.07), 0.0)
			var bell = b0 + up * 34.0 + fw * sin(t * 2.0) * 1.5
			P.poly(ci, P.pts([bell - fw * 4.0 + up * 4.0, bell + fw * 4.0 + up * 4.0, bell + fw * 6.0 - up * 4.0, bell - fw * 6.0 - up * 4.0]), Color("9a8a4a"), 1.5)
			if atk2 > 0.05 or abil > 0.05:
				var k = maxf(atk2, abil)
				ci.draw_circle(bell, 10.0 + k * 10.0, Color(gc.r, gc.g, gc.b, 0.35 * k))
			# cracks and a broken cross-beam
			ci.draw_line(b0 + up * 10.0 - fw * 10.0, b0 + up * 22.0 - fw * 2.0, STONE_D, 2.0)
			ci.draw_line(b0 + up * 50.0, b0 + up * 62.0 + fw * 2.0, Color("4a4a4e"), 2.5)
			ci.draw_line(b0 + up * 58.0 - fw * 4.0, b0 + up * 58.0 + fw * 7.0, Color("4a4a4e"), 2.5)
		"branches":
			for i in 3:
				var r0 = bp + fw * (-8.0 + i * 8.0)
				var ang = -1.9 + i * 0.4 + sin(t * 0.8 + i) * 0.05
				var tip = r0 + Vector2.from_angle(ang) * (26.0 + i * 4.0)
				tl(ci, r0, tip, 6.0, 2.0, BARK, 1.5)
				tl(ci, r0.lerp(tip, 0.6), r0.lerp(tip, 0.6) + Vector2.from_angle(ang + 0.7) * 10.0, 3.0, 1.0, BARK, 1.0)
				if atk2 > 0.1:
					ci.draw_circle(tip, 3.0, Color(gc.r, gc.g, gc.b, 0.8 * atk2))
		"crypt":
			# sarcophagus on the back + catapult arm (fires on atk2)
			var c0 = bp - fw * 4.0 + up * 4.0
			P.poly(ci, P.pts([c0 - fw * 22.0, c0 - fw * 22.0 + up * 34.0, c0 + fw * 18.0 + up * 38.0, c0 + fw * 20.0]), STONE, 2.5)
			P.poly(ci, P.pts([c0 - fw * 24.0 + up * 34.0, c0 - fw * 2.0 + up * 46.0, c0 + fw * 20.0 + up * 38.0]), STONE_D, 2.0)
			ci.draw_line(c0 - fw * 8.0 + up * 8.0, c0 - fw * 8.0 + up * 28.0, STONE_D, 2.0)
			ci.draw_line(c0 - fw * 16.0 + up * 18.0, c0 + up * 18.0, STONE_D, 2.0)
			# doors crack open when skeletons spill out
			if abil > 0.05:
				P.poly(ci, P.pts([c0 + fw * 2.0 + up * 6.0, c0 + fw * (2.0 + abil * 8.0) + up * 6.0, c0 + fw * (2.0 + abil * 8.0) + up * 30.0, c0 + fw * 2.0 + up * 30.0]), Color(0.05, 0.08, 0.05), 0.0)
				ci.draw_circle(c0 + fw * 6.0 + up * 18.0, 8.0 * abil, Color(gc.r, gc.g, gc.b, 0.4))
			var arm_a = lerpf(-2.6, -1.0, clampf(atk2 * 1.5, 0.0, 1.0))
			var piv = c0 + up * 44.0
			var tip = piv + Vector2.from_angle(arm_a) * 30.0
			ci.draw_line(piv, tip, Color(0.09, 0.07, 0.07), 6.0)
			ci.draw_line(piv, tip, Color("6a5034"), 4.0)
			P.circ(ci, tip, 5.0, BONE, 1.5)
		"spores":
			for i in 3:
				var s0 = bp + fw * (-14.0 + i * 12.0) + up * (6.0 - (i % 2) * 3.0)
				var top = s0 + up * (20.0 + i * 4.0)
				P.poly(ci, P.pts([s0 - fw * 6.0, top - fw * 4.0, top + fw * 4.0, s0 + fw * 6.0]), Color("6a7040"), 2.0)
				P.ell(ci, top, 6.0, 3.0, Color("4a5030"), 1.5)
				var puff = fmod(t * 0.8 + i * 0.33, 1.0)
				ci.draw_circle(top + up * (4.0 + puff * 14.0), 3.0 + puff * 4.0, Color(SPORE.r, SPORE.g, SPORE.b, 0.45 * (1.0 - puff)))
				if atk2 > 0.1:
					ci.draw_circle(top + up * 4.0, 7.0 * atk2, Color(SPORE.r, SPORE.g, SPORE.b, 0.7))
		"rift":
			for i in 4:
				var r0 = bp + fw * (-14.0 + i * 9.0)
				var hgt = 16.0 + (i % 2) * 10.0
				var pulse = 0.55 + 0.45 * sin(t * 2.4 + i * 1.3)
				P.poly(ci, P.pts([r0 - fw * 4.0, r0 + up * hgt, r0 + fw * 4.0, r0 + up * 3.0]), Color(0.36, 0.2, 0.58), 1.5)
				ci.draw_line(r0 + up * 3.0, r0 + up * (hgt - 2.0), Color(VIOL.r, VIOL.g, VIOL.b, 0.7 * pulse), 2.0)
			if atk2 > 0.1:
				ci.draw_circle(anc.head + up * 22.0, 8.0 * atk2, Color(VIOL.r, VIOL.g, VIOL.b, 0.6))


# ================================================================== quadruped (Carrion Bull)
static func _quad(ci: CanvasItem, cfg: Dictionary, a) -> void:
	var t: float = P.g(a, "t", 0.0)
	var moving: bool = P.g(a, "state", "idle") == "move"
	var walk: float = P.g(a, "walk", 0.0)
	var atk: float = P.g(a, "atk", 0.0)
	var wind: float = P.g(a, "windup", 0.0)
	var abil: float = P.g(a, "ability_anim", 0.0)
	var hurt: float = P.g(a, "hurt", 0.0)
	var hpf: float = P.g(a, "hp_frac", 1.0)
	var skin: Color = cfg.skin
	var skin_d: Color = cfg.skin_d
	var gc: Color = cfg.glow
	var charge: float = maxf(abil, wind)
	var bob: float = (1.0 - absf(sin(walk * 1.3))) * 3.0 if moving else sin(t * 1.5) * 0.6
	var body_y = -46.0 + bob + charge * 4.0
	var front = Vector2(22, body_y)
	var rear = Vector2(-26, body_y - 2.0)
	# far legs
	for leg in [[rear + Vector2(-2, 6), walk + PI, true], [front + Vector2(2, 8), walk, true]]:
		var f: Array = M.foot_pos(leg[1], 9.0, 6.0, moving, 0.0)
		var hip: Vector2 = leg[0]
		var foot: Vector2 = Vector2(hip.x, 0) + f[0]
		var knee = M.ik_knee(hip, foot, 22.0, 22.0, -1.0 if hip.x < 0 else 1.0)
		tl(ci, hip, knee, 11.0, 8.0, skin_d)
		tl(ci, knee, foot + Vector2(0, -3), 8.0, 6.0, skin_d)
		P.poly(ci, P.pts([foot + Vector2(-5, -5), foot + Vector2(5, -5), foot + Vector2(6, 0), foot + Vector2(-6, 0)]), Color("2a2420"), 1.5)
	# barrel body + hump
	P.poly(ci, P.pts([rear + Vector2(-12, 10), rear + Vector2(-16, -10), rear + Vector2(4, -26), front + Vector2(-6, -36), front + Vector2(14, -22), front + Vector2(18, 4), front + Vector2(0, 18), rear + Vector2(4, 18)]), skin, 2.5)
	P.poly(ci, P.pts([rear + Vector2(4, -22), front + Vector2(-8, -32), front + Vector2(4, -20), rear + Vector2(10, -12)]), skin.lightened(0.1), 0.0)
	# exposed ribs + rot
	for i in 4:
		ci.draw_arc(Vector2(-6 + i * 8, body_y + 4), 9.0, 0.3, 2.6, 6, BONE_D, 2.5)
	P.poly(ci, P.pts([rear + Vector2(-4, 2), rear + Vector2(10, -4), rear + Vector2(14, 10), rear + Vector2(-2, 14)]), GORE, 1.5)
	# spine spikes
	for i in 5:
		var s0 = rear.lerp(front, i / 4.0) + Vector2(0, -24 - absf(i - 2.0) * -2.0)
		P.poly(ci, P.pts([s0 + Vector2(-3, 2), s0 + Vector2(-1, -10 - (i % 2) * 4), s0 + Vector2(3, 2)]), BONE_D, 1.2)
	# tail
	ci.draw_line(rear + Vector2(-14, -4), rear + Vector2(-26, 8 + sin(t * 3.0) * 4.0), Color(0.09, 0.07, 0.07), 4.0)
	ci.draw_line(rear + Vector2(-14, -4), rear + Vector2(-26, 8 + sin(t * 3.0) * 4.0), skin_d, 2.0)
	# head: lowered during the charge wind-up, tossed up on a gore
	var head_ang = 0.35 + charge * 0.45 - atk * 0.8
	var neck = front + Vector2(12, -18)
	var hc = neck + Vector2.from_angle(head_ang) * 18.0
	tl(ci, neck, hc, 16.0, 13.0, skin)
	var fwd = Vector2.from_angle(head_ang)
	var nrm = fwd.orthogonal()
	P.poly(ci, P.pts([hc - nrm * 9.0, hc + fwd * 18.0 - nrm * 5.0, hc + fwd * 20.0 + nrm * 4.0, hc + nrm * 8.0]), BONE, 2.0)
	eye(ci, hc + fwd * 6.0 - nrm * 4.0, gc, 1.8)
	ci.draw_circle(hc + fwd * 18.0 + nrm * 1.0, 1.6, Color(0.1, 0.08, 0.08))
	# grave-iron horns
	for s in [-1.0, 1.0]:
		var hb = hc - nrm * 6.0 * s + fwd * 2.0
		var hpts = P.pts([hb, hb - nrm * 10.0 * s + fwd * 6.0, hb - nrm * 6.0 * s + fwd * 22.0, hb + fwd * 8.0])
		P.poly(ci, hpts, Color("6a6a70") if s > 0 else Color("4a4a50"), 1.8)
	if charge > 0.05:
		ci.draw_circle(hc + fwd * 10.0, 16.0 * charge, Color(gc.r, gc.g, gc.b, 0.2 * charge))
	# near legs
	for leg in [[rear + Vector2(4, 8), walk, false], [front + Vector2(-2, 10), walk + PI, false]]:
		var f2: Array = M.foot_pos(leg[1], 9.0, 6.0, moving, 0.0)
		var hip2: Vector2 = leg[0]
		var foot2: Vector2 = Vector2(hip2.x, 0) + f2[0]
		var knee2 = M.ik_knee(hip2, foot2, 22.0, 22.0, -1.0 if hip2.x < 0 else 1.0)
		tl(ci, hip2, knee2, 12.0, 9.0, skin)
		tl(ci, knee2, foot2 + Vector2(0, -3), 9.0, 7.0, skin)
		P.poly(ci, P.pts([foot2 + Vector2(-5, -5), foot2 + Vector2(5, -5), foot2 + Vector2(6, 0), foot2 + Vector2(-6, 0)]), Color("2a2420"), 1.5)
	if hpf < 0.5:
		P.poly(ci, P.pts([front + Vector2(-4, -6), front + Vector2(6, -10), front + Vector2(4, 0)]), GORE_D, 1.0)
	if hurt > 0.3:
		ci.draw_circle(Vector2(0, body_y), 4.0, Color(1, 1, 1, 0.0))
