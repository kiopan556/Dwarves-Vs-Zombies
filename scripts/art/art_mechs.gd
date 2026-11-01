class_name ArtMechs
extends RefCounted
## M002 war-frame art: one shared procedural rig (2-bone IK legs with real foot planting,
## telescoping pistons, torso weight transfer, exhaust, armour plates) + 28 frame designs
## expressed as data. Every frame is drawn in ~110 design units, facing right, origin at the
## feet; the unit node scales it to its class height (light ≈2×, medium ≈2.8×, heavy ≈4×,
## colossal ≈5.6× a Rifleman).
##
## Animation inputs (via Painter.g): t, walk, state, atk/atk2/atk3, windup, aim0..2, engage,
## hurt, recoil, spin, ability_anim, brace_t, heat_lock_t, stun_t, hp_frac.

const P = preload("res://scripts/art/painter.gd")
const D = preload("res://scripts/art/art_dwarves.gd")

# palette (spec §2.5)
const IRON := Color("4b5058")
const IRON_D := Color("33373d")
const STEEL := Color("8f979f")
const STEEL_D := Color("666d75")
const BRASS := Color("c9a24a")
const COPPER := Color("b8693a")
const SOOT := Color("26221f")
const LEATHER := Color("6a4426")
const BLUE := Color("2f4f7a")
const FORGE := Color("f08a2a")
const RED := Color("9c2f26")
const YELLOW := Color("e0b52a")
const GUNMETAL := Color("50565c")
const BLUEGRAY := Color("5f7486")
const RUNE_BLUE := Color(0.45, 0.8, 1.0)
const RUNE_AMBER := Color(1.0, 0.72, 0.3)

## M007 "Forge-Knight" redesign: heroic mecha proportions (longer legs, a V-tapered chest over a narrow armoured
## waist, big layered pauldrons, flared shins and sabaton feet, twin boiler thrusters on the back, a horned
## V-crest over twin eye slits) — but forged by dwarves: a braided-beard faceplate grille, rivets and brass trim,
## steam intakes on the chest around a furnace core, runes, smokestacks. Every frame keeps its M002 silhouette
## identity (body type, weapons, back gear); the shared rig carries the new look.
const CLS := {
	"light":    {"thigh": 23.0, "shin": 23.0, "leg_w": 10.5, "foot": 17.0, "torso_h": 38.0, "stride": 10.0, "bob": 2.4},
	"medium":   {"thigh": 25.0, "shin": 25.0, "leg_w": 12.5, "foot": 19.0, "torso_h": 44.0, "stride": 9.0, "bob": 2.0},
	"heavy":    {"thigh": 26.0, "shin": 26.0, "leg_w": 15.0, "foot": 22.0, "torso_h": 48.0, "stride": 8.0, "bob": 1.6},
	"colossal": {"thigh": 27.0, "shin": 26.0, "leg_w": 17.0, "foot": 25.0, "torso_h": 52.0, "stride": 7.0, "bob": 1.3},
}
## enamel for the two-tone panelling (the dwarven take on the white-and-colour mecha scheme)
const ENAMEL := Color("d9d2bf")
const COMBAT_BODIES := ["chest", "lean", "fortress", "tower", "furnace", "boiler"]


## The light panel colour of a frame: its base metal lifted toward forge enamel.
static func panel_col(cfg: Dictionary) -> Color:
	var b: Color = cfg.base
	return b.lerp(ENAMEL, 0.42 if b.get_luminance() < 0.45 else 0.22)

## frame designs: body shape, head, colours, back gear, arm/mount weapons (family + weapon index)
const F := {
	"miner_rig": {"cls": "light", "body": "work", "tw": 26, "sw": 30, "head": "lamp", "base": Color("8a7a4a"), "trim": YELLOW, "acc": COPPER,
		"back": ["boiler"], "front": {"w": "claw", "i": 0}, "back_arm": {"w": "claw", "i": 0, "alt": true}},
	"boiler_stomper": {"cls": "light", "body": "boiler", "tw": 36, "sw": 34, "head": "grille", "base": COPPER, "trim": BRASS, "acc": IRON,
		"back": ["stacks2", "pipes"], "front": {"w": "vent", "i": 1}, "back_arm": {"w": "stub", "i": 0}, "stomp": true},
	"drillwalker": {"cls": "light", "body": "work", "tw": 28, "sw": 32, "head": "visor", "base": COPPER, "trim": YELLOW, "acc": STEEL,
		"back": ["engine"], "front": {"w": "drill", "i": 0}, "back_arm": {"w": "brace", "i": 0}},
	"steam_loader": {"cls": "light", "body": "loader", "tw": 34, "sw": 38, "head": "cabin", "base": Color("7d6a3a"), "trim": YELLOW, "acc": IRON,
		"back": ["stacks1"], "front": {"w": "grabber", "i": 0}, "back_arm": {"w": "grabber", "i": 0, "alt": true}},
	"piston_brawler": {"cls": "light", "body": "chest", "tw": 28, "sw": 38, "head": "helm", "base": IRON, "trim": RED, "acc": STEEL,
		"back": ["stacks1"], "front": {"w": "fist", "i": 0}, "back_arm": {"w": "fist", "i": 0, "alt": true}},
	"copper_sentinel": {"cls": "light", "body": "chest", "tw": 32, "sw": 38, "head": "visor", "base": COPPER, "trim": BRASS, "acc": IRON,
		"back": ["drum"], "front": {"w": "repeater", "i": 0}, "back_arm": {"w": "buckler", "i": 0}},
	"ironclad_walker": {"cls": "medium", "body": "chest", "tw": 36, "sw": 50, "head": "helm", "base": IRON, "trim": BRASS, "acc": BLUE,
		"back": ["stacks2"], "front": {"w": "cannon", "i": 0}, "back_arm": {"w": "fist", "i": 1}},
	"skyguard_walker": {"cls": "medium", "body": "chest", "tw": 34, "sw": 44, "head": "visor", "base": BLUEGRAY, "trim": BRASS, "acc": GUNMETAL,
		"back": ["belts"], "front": {"w": "bracer", "i": 0}, "back_arm": {"w": "bracer", "i": 0},
		"mounts": [{"w": "aa_twin", "i": 0, "at": "shoulder"}, {"w": "aa_twin", "i": 1, "at": "shoulder_b"}]},
	"thundercoil_frame": {"cls": "medium", "body": "chest", "tw": 34, "sw": 46, "head": "grille", "base": GUNMETAL, "trim": BRASS, "acc": RUNE_BLUE,
		"back": ["coil"], "front": {"w": "gauntlet", "i": 0}, "back_arm": {"w": "gauntlet", "i": 0, "alt": true}, "rune": RUNE_BLUE},
	"cannon_strider": {"cls": "medium", "body": "chest", "tw": 30, "sw": 42, "head": "visor", "base": IRON_D, "trim": FORGE, "acc": IRON, "tall": 6.0,
		"back": ["stacks1"], "front": {"w": "brace", "i": 0}, "back_arm": {"w": "stub", "i": 0},
		"mounts": [{"w": "shoulder_cannon", "i": 0, "at": "shoulder"}]},
	"shieldframe": {"cls": "medium", "body": "chest", "tw": 44, "sw": 56, "head": "helm", "base": STEEL_D, "trim": BRASS, "acc": BLUE,
		"back": ["stacks2"], "front": {"w": "tower_shield", "i": 0}, "back_arm": {"w": "fist", "i": 0}},
	"claw_harvester": {"cls": "medium", "body": "lean", "tw": 30, "sw": 44, "head": "lamp", "base": Color("3a3f35"), "trim": RED, "acc": STEEL,
		"back": ["spikes"], "front": {"w": "big_claw", "i": 0}, "back_arm": {"w": "big_claw", "i": 0, "alt": true}},
	"mortar_walker": {"cls": "medium", "body": "platform", "tw": 42, "sw": 40, "head": "cabin", "base": IRON, "trim": FORGE, "acc": LEATHER,
		"back": ["ammo_rack"], "front": {"w": "brace", "i": 0}, "back_arm": {"w": "stub", "i": 0},
		"mounts": [{"w": "mortar", "i": 0, "at": "top"}]},
	"furnace_stalker": {"cls": "medium", "body": "furnace", "tw": 34, "sw": 44, "head": "grille", "base": Color("4a3a32"), "trim": FORGE, "acc": COPPER,
		"back": ["stacks2", "tank"], "front": {"w": "flamer", "i": 0}, "back_arm": {"w": "fist", "i": 0}},
	"anvilbreaker": {"cls": "heavy", "body": "chest", "tw": 44, "sw": 64, "head": "helm", "base": IRON_D, "trim": RED, "acc": STEEL,
		"back": ["stacks2"], "front": {"w": "hammer2", "i": 0}, "two_hand": true},
	"siegebellow": {"cls": "heavy", "body": "chest", "tw": 42, "sw": 56, "head": "visor", "base": IRON_D, "trim": FORGE, "acc": BRASS,
		"back": ["stacks2", "ammo_rack"], "front": {"w": "brace", "i": 0}, "back_arm": {"w": "loader_arm", "i": 0},
		"mounts": [{"w": "siege_cannon", "i": 0, "at": "shoulder"}]},
	"furnace_guardian": {"cls": "heavy", "body": "furnace", "tw": 48, "sw": 62, "head": "grille", "base": Color("4a3a32"), "trim": FORGE, "acc": COPPER,
		"back": ["stacks3"], "front": {"w": "flamer", "i": 0}, "back_arm": {"w": "flamer", "i": 1}},
	"siege_hammer_walker": {"cls": "heavy", "body": "chest", "tw": 42, "sw": 58, "head": "helm", "base": STEEL_D, "trim": YELLOW, "acc": IRON_D,
		"back": ["stacks1", "pipes"], "front": {"w": "piston_hammer", "i": 0}, "back_arm": {"w": "brace", "i": 0}},
	"flak_colossus": {"cls": "heavy", "body": "chest", "tw": 44, "sw": 60, "head": "visor", "base": BLUEGRAY, "trim": BRASS, "acc": GUNMETAL,
		"back": ["ammo_housing"], "front": {"w": "bracer", "i": 0}, "back_arm": {"w": "bracer", "i": 0},
		"mounts": [{"w": "aa_quad", "i": 0, "at": "shoulder"}, {"w": "aa_quad", "i": 1, "at": "shoulder_b"}]},
	"thunderstep_bruiser": {"cls": "heavy", "body": "lean", "tw": 42, "sw": 64, "head": "helm", "base": IRON, "trim": RED, "acc": STEEL,
		"back": ["stacks2"], "front": {"w": "big_fist", "i": 0}, "back_arm": {"w": "big_fist", "i": 0, "alt": true}, "chest_gun": 1},
	"shredder_walker": {"cls": "heavy", "body": "chest", "tw": 44, "sw": 62, "head": "visor", "base": GUNMETAL, "trim": BRASS, "acc": IRON_D,
		"back": ["ammo_housing"], "front": {"w": "rotary", "i": 0}, "back_arm": {"w": "rotary", "i": 1}},
	"riftshield_walker": {"cls": "heavy", "body": "fortress", "tw": 48, "sw": 62, "head": "grille", "base": STEEL_D, "trim": BRASS, "acc": RUNE_BLUE,
		"back": ["emitter"], "front": {"w": "emitter_arm", "i": 0}, "back_arm": {"w": "fist", "i": 0}, "rune": RUNE_BLUE},
	"deepforge_titan": {"cls": "colossal", "body": "fortress", "tw": 52, "sw": 70, "head": "crown_helm", "base": IRON, "trim": BRASS, "acc": BLUE,
		"back": ["stacks3", "furnace_core"], "front": {"w": "titan_cannon", "i": 0}, "back_arm": {"w": "fist", "i": 3},
		"mounts": [{"w": "aa_twin", "i": 1, "at": "shoulder"}, {"w": "aa_twin", "i": 2, "at": "shoulder_b"}]},
	"mountain_colossus": {"cls": "colossal", "body": "fortress", "tw": 60, "sw": 76, "head": "helm", "base": Color("5a5550"), "trim": BRASS, "acc": IRON_D,
		"back": ["stacks3", "battlements"], "front": {"w": "big_fist", "i": 0}, "back_arm": {"w": "big_fist", "i": 0, "alt": true}},
	"kings_anvil": {"cls": "colossal", "body": "chest", "tw": 50, "sw": 72, "head": "crown", "base": Color("3c4a6a"), "trim": BRASS, "acc": RED,
		"back": ["stacks2", "banner"], "front": {"w": "axe2", "i": 0}, "two_hand": true, "rune": RUNE_AMBER},
	"colossal_skybreaker": {"cls": "colossal", "body": "tower", "tw": 46, "sw": 64, "head": "visor", "base": BLUEGRAY, "trim": BRASS, "acc": GUNMETAL,
		"back": ["stabilizers"], "front": {"w": "bracer", "i": 0}, "back_arm": {"w": "bracer", "i": 0},
		"mounts": [{"w": "aa_heavy", "i": 0, "at": "shoulder"}, {"w": "aa_heavy", "i": 1, "at": "top"}, {"w": "aa_heavy", "i": 2, "at": "shoulder_b"}]},
	"hammerfall_goliath": {"cls": "colossal", "body": "chest", "tw": 54, "sw": 74, "head": "helm", "base": STEEL_D, "trim": YELLOW, "acc": IRON_D,
		"back": ["stacks3", "pipes"], "front": {"w": "hammer2", "i": 0}, "two_hand": true, "big_pistons": true},
	"embercore_titan": {"cls": "colossal", "body": "furnace", "tw": 54, "sw": 72, "head": "grille", "base": Color("3e2f28"), "trim": FORGE, "acc": COPPER,
		"back": ["stacks3", "vents"], "front": {"w": "flamer_big", "i": 0}, "back_arm": {"w": "fist", "i": 0},
		"mounts": [{"w": "aa_twin", "i": 1, "at": "shoulder"}, {"w": "aa_twin", "i": 2, "at": "shoulder_b"}], "seams": true},
}


static func has(art: String) -> bool:
	return F.has(art)


static func atk_of(a, i: int) -> float:
	if i <= 0:
		return P.g(a, "atk", 0.0)
	if i == 1:
		return P.g(a, "atk2", 0.0)
	return P.g(a, "atk3", 0.0)


static func aim_of(a, i: int, default: float) -> float:
	var key = "aim%d" % mini(i, 2)
	return P.g(a, key, default)


# ================================================================== M006b combat animation
## Arm poses per weapon family as [upper-arm angle, forearm angle] (radians; 0 = forward, +down).
##   relax  travelling / not engaged: weapon carried low
##   guard  combat stance: fists up, gun shouldered, shield forward, claws spread, hammer ready
##   coil   wind-up / anticipation (drawn back or raised overhead)
##   hit    the blow landing (melee) or the shot's muzzle climb (guns, added to the aimed guard)
##   over   follow-through past the impact
## Guns aim: their guard follows aim; hit/over are offsets on top of it.
const ARM_POSE := {
	"claw":          {"relax": [1.3, 0.9], "guard": [0.45, -0.35], "coil": [-0.9, -2.1], "hit": [0.95, 1.25], "over": [1.2, 1.65], "melee": true, "reach": 16.0},
	"big_claw":      {"relax": [1.3, 1.0], "guard": [0.4, -0.45], "coil": [-1.0, -2.2], "hit": [1.0, 1.3], "over": [1.25, 1.7], "melee": true, "reach": 24.0},
	"fist":          {"relax": [1.35, 0.55], "guard": [1.0, -0.95], "coil": [1.75, -1.7], "hit": [0.05, 0.0], "over": [0.12, 0.12], "melee": true, "reach": 8.0},
	"big_fist":      {"relax": [1.35, 0.6], "guard": [1.05, -0.9], "coil": [1.8, -1.75], "hit": [0.1, 0.15], "over": [0.25, 0.4], "melee": true, "reach": 11.0},
	"gauntlet":      {"relax": [1.3, 0.5], "guard": [0.95, -0.8], "coil": [1.7, -1.6], "hit": [-0.05, -0.08], "over": [0.05, 0.0], "melee": true, "reach": 9.0},
	"grabber":       {"relax": [1.3, 0.6], "guard": [0.8, 0.1], "coil": [0.35, -0.7], "hit": [0.3, 0.3], "over": [0.55, 0.6], "melee": true, "reach": 14.0},
	"drill":         {"relax": [1.25, 0.75], "guard": [0.6, 0.05], "coil": [1.15, 0.25], "hit": [0.12, -0.02], "over": [0.18, 0.04], "melee": true, "reach": 34.0},
	"piston_hammer": {"relax": [1.2, 1.0], "guard": [0.35, -0.75], "coil": [-1.05, -2.45], "hit": [0.6, 1.05], "over": [0.8, 1.35], "melee": true, "reach": 30.0},
	"tower_shield":  {"relax": [1.1, 0.05], "guard": [0.8, -0.3], "coil": [1.25, -0.1], "hit": [0.3, -0.3], "over": [0.38, -0.3], "melee": true, "reach": 14.0},
	"buckler":       {"relax": [1.2, 0.25], "guard": [0.9, -0.65], "coil": [1.1, -0.9], "hit": [0.6, -0.5], "over": [0.7, -0.55], "melee": true, "reach": 8.0},
	"emitter_arm":   {"relax": [1.0, -0.15], "guard": [0.7, -0.3], "coil": [0.9, -0.6], "hit": [0.45, -0.4], "over": [0.5, -0.35], "melee": false, "reach": 12.0},
	"vent":          {"relax": [1.2, 0.6], "guard": [0.9, 0.2], "coil": [1.1, 0.5], "hit": [0.7, 0.05], "over": [0.75, 0.1], "melee": false, "reach": 12.0},
	"brace":         {"relax": [1.4, 1.0], "guard": [1.25, 0.45], "coil": [1.3, 0.6], "hit": [1.2, 0.4], "over": [1.25, 0.45], "melee": false, "reach": 4.0},
	"bracer":        {"relax": [1.4, 1.0], "guard": [1.05, -0.25], "coil": [1.1, -0.2], "hit": [1.0, -0.35], "over": [1.05, -0.3], "melee": false, "reach": 4.0},
	"stub":          {"relax": [1.45, 1.1], "guard": [1.3, 0.6], "coil": [1.35, 0.7], "hit": [1.3, 0.55], "over": [1.3, 0.6], "melee": false, "reach": 4.0},
	"loader_arm":    {"relax": [1.4, 1.0], "guard": [1.1, 0.2], "coil": [0.9, -0.5], "hit": [1.15, 0.3], "over": [1.2, 0.4], "melee": false, "reach": 4.0},
}
const GUN_POSE := {"relax": [1.35, 0.9], "hit": [-0.1, -0.3], "over": [-0.04, -0.12], "reach": 30.0}
const MELEE_FAMS := ["claw", "big_claw", "fist", "big_fist", "gauntlet", "grabber", "drill", "piston_hammer", "tower_shield", "buckler", "hammer2", "axe2"]


## The attack timeline of one weapon, from the existing pose keys only:
##   windup > 0       -> "coil" (anticipation)
##   atk 1.0 .. 0.75  -> the blow lands: hit, sliding into the follow-through
##   atk 0.75 .. 0.4  -> follow-through, holding past the impact
##   atk 0.4 .. 0     -> recovery back to the stance (eased)
##   gag (after)      -> a spring overshoot as the arm settles
## Returns [mode, k]: mode 0 stance, 1 coil, 2 hit->over (k 0..1), 3 over->hold (k), 4 hold->stance (k).
static func timeline(atk: float, windup: float) -> Array:
	if windup > 0.0:
		return [1, 1.0]
	if atk >= 0.75:
		return [2, (1.0 - atk) / 0.25]
	if atk >= 0.4:
		return [3, (0.75 - atk) / 0.35]
	if atk > 0.0:
		return [4, smoothstep(0.0, 1.0, (0.4 - atk) / 0.4)]
	return [0, 0.0]


static func _lerp2(p: Array, q: Array, k: float) -> Array:
	return [lerpf(float(p[0]), float(q[0]), k), lerpf(float(p[1]), float(q[1]), k)]


## Arm angles for a family at this moment of its timeline.
static func arm_pose(fam: String, eng: float, atk: float, windup: float, gag: float, aim: float, t: float, heavy: float) -> Array:
	var fp: Dictionary = ARM_POSE.get(fam, {})
	var gun = fp.is_empty()
	var relax: Array = GUN_POSE.relax if gun else fp.relax
	var guard: Array = [0.55 + aim * 0.4, aim] if gun else fp.guard
	var base = _lerp2(relax, guard, eng)
	var coil: Array = (_lerp2(base, [0.75 + aim * 0.4, aim + 0.25], 1.0) if gun else fp.coil)
	var hit: Array = [base[0] + GUN_POSE.hit[0], base[1] + GUN_POSE.hit[1]] if gun else fp.hit
	var over: Array = [base[0] + GUN_POSE.over[0], base[1] + GUN_POSE.over[1]] if gun else fp.over
	var hold = _lerp2(hit, base, 0.4)
	var tl = timeline(atk, windup)
	var out: Array
	match int(tl[0]):
		1:
			# held tension: a slight tremble in the coil, heavier frames tremble less
			out = [float(coil[0]) + sin(t * 37.0) * 0.025 * (1.2 - heavy), float(coil[1])]
		2:
			out = _lerp2(hit, over, float(tl[1]))
		3:
			out = _lerp2(over, hold, float(tl[1]))
		4:
			out = _lerp2(hold, base, float(tl[1]))
		_:
			out = base
			if gag > 0.0:
				# recovery spring: the arm overshoots its guard and settles (slower, heavier on big frames)
				var gph = 1.0 - gag
				var sp = exp(-3.2 * gph) * sin(gph * (9.0 - heavy * 3.0)) * (0.22 if not gun else 0.1)
				out = [float(out[0]) - sp * 0.6, float(out[1]) - sp]
	return out


## Body participation for the front weapon: [lean, crouch, lunge px]. Melee coils back and lunges in;
## guns rock back on the shot.
static func body_from(fam: String, atk: float, windup: float) -> Array:
	var tl = timeline(atk, windup)
	var melee = fam in MELEE_FAMS
	match int(tl[0]):
		1:
			return [-0.12 if melee else 0.03, 3.0 if melee else 1.5, -2.0 if melee else 0.0]
		2:
			return [0.15 if melee else -0.07, 2.5 if melee else 1.0, 7.0 if melee else -2.0] if float(tl[1]) < 0.5 else [0.12 if melee else -0.04, 2.0, 6.0 if melee else -1.0]
		3:
			return [0.08 if melee else -0.02, 1.5, 4.0 if melee else 0.0]
		4:
			return [0.03 if melee else 0.0, 0.5, 1.5 if melee else 0.0]
	return [0.0, 0.0, 0.0]


## Motion smear for a melee blow: a fading crescent swept from the coil to the impact (strike frames only).
static func smear(ci: CanvasItem, pivot: Vector2, a0: float, a1: float, r_out: float, r_in: float, alpha: float, col: Color = Color(1, 1, 1)) -> void:
	if alpha <= 0.02:
		return
	var n = 9
	var outer = PackedVector2Array()
	var inner = PackedVector2Array()
	for k in n + 1:
		var f = float(k) / float(n)
		var ang = lerpf(a0, a1, f)
		outer.append(pivot + Vector2.from_angle(ang) * r_out)
		inner.append(pivot + Vector2.from_angle(ang) * lerpf(r_out - 2.0, r_in, f))
	inner.reverse()
	var poly = outer + inner
	ci.draw_colored_polygon(poly, Color(col.r, col.g, col.b, alpha))


## Ground impact: a dust burst and flying chips where a heavy blow lands.
static func impact_dust(ci: CanvasItem, at: Vector2, size: float, k: float) -> void:
	if k <= 0.0:
		return
	for i in 5:
		var ox = (float(i) - 2.0) * size * 0.55 * (0.6 + k * 0.6)
		ci.draw_circle(Vector2(at.x + ox, -size * 0.25 - absf(ox) * 0.15 * k), size * (0.35 + 0.15 * float(i % 2)) * (0.6 + k * 0.5), Color(0.58, 0.5, 0.4, 0.5 * k))
	for i in 4:
		var d = Vector2.from_angle(-PI * (0.2 + 0.2 * float(i))) * size * (0.8 + k)
		ci.draw_line(Vector2(at.x, -2) + d * 0.5, Vector2(at.x, -2) + d, Color(0.35, 0.3, 0.25, 0.8 * k), 2.0)


# ================================================================== rig
static func ik_knee(hip: Vector2, foot: Vector2, l1: float, l2: float, forward: float) -> Vector2:
	var dv = foot - hip
	var dist = clampf(dv.length(), absf(l1 - l2) + 0.1, l1 + l2 - 0.05)
	var base = dv.angle()
	var c = clampf((l1 * l1 + dist * dist - l2 * l2) / (2.0 * l1 * dist), -1.0, 1.0)
	var off = acos(c)
	var k1 = hip + Vector2.from_angle(base - off) * l1
	var k2 = hip + Vector2.from_angle(base + off) * l1
	return k1 if (k1.x - k2.x) * forward > 0.0 else k2


## Foot target for one leg: planted (moves backwards with the body) during stance, lifted arc
## forward during swing. Returns [foot, lift].
## M006: also returns the foot's roll (radians, + = toe down): the heel peels up at push-off, the toe
## hangs during the swing and the foot lands heel-first, flattening as the weight comes onto it.
static func foot_pos(phase: float, stride: float, lift_h: float, moving: bool, side_off: float) -> Array:
	if not moving:
		return [Vector2(side_off, 0.0), 0.0, 0.0]
	var u = fposmod(phase, TAU) / TAU
	var x: float
	var lift = 0.0
	var roll = 0.0
	if u < 0.5:
		x = lerpf(stride, -stride, u * 2.0)
		# heel strike at the start of stance (toe up), push-off at the end (heel peels up)
		roll = -0.22 * maxf(0.0, 1.0 - u * 10.0) + 0.32 * smoothstep(0.34, 0.5, u)
	else:
		var k = (u - 0.5) * 2.0
		x = lerpf(-stride, stride, k * k * (3.0 - 2.0 * k))
		# a high, heavy swing: the foot lifts fast, hangs, then drops onto the heel
		lift = sin(pow(k, 0.8) * PI) * lift_h
		roll = 0.38 * sin(k * PI * 0.9) - 0.2 * smoothstep(0.8, 1.0, k)
	return [Vector2(x + side_off * 0.3, -lift), lift, roll]


static func draw_leg(ci: CanvasItem, hip: Vector2, foot: Vector2, c: Dictionary, col: Color, far: bool, cfg: Dictionary, roll: float = 0.0) -> void:
	var l1: float = c.thigh
	var l2: float = c.shin
	var w: float = c.leg_w
	var knee = ik_knee(hip, foot, l1, l2, 1.0)
	var lc = col.darkened(0.3) if far else col
	var pan = panel_col(cfg).darkened(0.32) if far else panel_col(cfg)
	var trim: Color = Color(cfg.trim).darkened(0.35) if far else Color(cfg.trim)
	# thigh: an armoured plate with a light enamel panel down its front
	var td = (knee - hip).normalized()
	var tn = td.orthogonal()
	P.poly(ci, P.pts([hip + tn * w * 0.62, knee + tn * w * 0.48, knee - tn * w * 0.52, hip - tn * w * 0.6]), lc, 2.0)
	P.poly(ci, P.pts([hip.lerp(knee, 0.12) + tn * w * 0.5, knee.lerp(hip, 0.2) + tn * w * 0.42, knee.lerp(hip, 0.2) + tn * w * 0.05, hip.lerp(knee, 0.12) + tn * w * 0.08]), pan, 0.0)
	# shin: flared toward the ankle (heroic), with a vented front panel and a calf thruster
	var sd = (foot - knee).normalized()
	var sn = sd.orthogonal()
	var ankle = foot + Vector2(0, -w * 0.4)
	var shin_pts = [knee + sn * w * 0.5, ankle + sn * w * 0.66, ankle - sn * w * 0.6, knee - sn * w * 0.48]
	P.poly(ci, P.pts(shin_pts), lc.darkened(0.08), 2.0)
	P.poly(ci, P.pts([knee.lerp(ankle, 0.3) + sn * w * 0.44, ankle.lerp(knee, 0.12) + sn * w * 0.6, ankle.lerp(knee, 0.12) + sn * w * 0.28, knee.lerp(ankle, 0.3) + sn * w * 0.22]), pan.darkened(0.06), 0.0)
	# steam slats on the shin front (forge vents)
	for k in 3:
		var vp = knee.lerp(ankle, 0.45 + k * 0.12)
		ci.draw_line(vp + sn * w * 0.18, vp + sn * w * 0.5, SOOT if not far else P.OUT, 1.6)
	# calf thruster: a brass bell nozzle on the back of the shin
	var cb = knee.lerp(ankle, 0.55) - sn * w * 0.55
	P.poly(ci, P.pts([cb + sd * -3.0, cb + sd * 4.0, cb + sd * 6.0 - sn * w * 0.32, cb + sd * -5.0 - sn * w * 0.32]), BRASS.darkened(0.35 if far else 0.05), 1.2)
	# hydraulic piston from thigh to shin (telescopes as the knee bends)
	var pa = hip.lerp(knee, 0.3) - tn * w * 0.7 * (1.0 if not far else -1.0)
	var pb = knee.lerp(ankle, 0.45) - sn * w * 0.55 * (1.0 if not far else -1.0)
	var mid = pa.lerp(pb, 0.5)
	ci.draw_line(pa, mid, P.OUT, w * 0.36 + 2.0)
	ci.draw_line(pa, mid, (STEEL_D if far else STEEL).darkened(0.1), w * 0.36)
	ci.draw_line(mid, pb, P.OUT, w * 0.2 + 2.0)
	ci.draw_line(mid, pb, (STEEL if not far else STEEL_D).lightened(0.25), w * 0.2)
	if cfg.get("big_pistons", false):
		ci.draw_line(hip + Vector2(-w * 0.4, 2), ankle + Vector2(-w * 0.6, 0), P.OUT, w * 0.35)
		ci.draw_line(hip + Vector2(-w * 0.4, 2), ankle + Vector2(-w * 0.6, 0), BRASS, w * 0.25)
	# knee guard: a pointed armour cap with a brass rim and a rune stud
	var kf = knee + sn * w * 0.25
	var kup = -sd
	P.poly(ci, P.pts([kf + kup * w * 0.62 - sn * w * 0.1, kf + kup * w * 0.4 + sn * w * 0.45, kf + sd * w * 0.3 + sn * w * 0.52, kf + sd * w * 0.62, kf + sd * w * 0.1 - sn * w * 0.3]), lc.lightened(0.06), 2.0)
	ci.draw_line(kf + kup * w * 0.4 + sn * w * 0.45, kf + sd * w * 0.3 + sn * w * 0.52, trim, 1.6)
	ci.draw_circle(kf + sn * w * 0.2, w * 0.12, (FORGE if not far else FORGE.darkened(0.5)) if not cfg.has("rune") else Color(cfg.rune, 0.9 if not far else 0.4))
	# sabaton: a big armoured foot with a toe cap and heel spur, rolled about the ankle (heel-toe walk)
	var f: float = c.foot
	var piv = foot + Vector2(0, -w * 0.3)
	var rx = Transform2D(roll, Vector2.ZERO)
	var fp: Array = [Vector2(-f * 0.56, 0), Vector2(-f * 0.6, -w * 0.32), Vector2(-f * 0.38, -w * 0.66), Vector2(f * 0.22, -w * 0.72), Vector2(f * 0.62, -w * 0.3), Vector2(f * 0.78, 0)]
	var fpts: Array = []
	for q in fp:
		fpts.append(piv + rx * (q + Vector2(0, w * 0.3)))
	P.poly(ci, P.pts(fpts), (IRON_D if not far else SOOT), 2.0)
	# toe cap (enamel) and ankle guard
	P.poly(ci, P.pts([piv + rx * Vector2(f * 0.2, w * 0.3 - w * 0.62), piv + rx * Vector2(f * 0.58, w * 0.3 - w * 0.3), piv + rx * Vector2(f * 0.74, w * 0.3 - 1.0), piv + rx * Vector2(f * 0.3, w * 0.3 - 1.0)]), pan.darkened(0.12), 1.2)
	P.circ(ci, piv + rx * Vector2(-f * 0.08, -w * 0.12), w * 0.3, BRASS.darkened(0.25 if not far else 0.55), 1.2)
	ci.draw_line(piv + rx * Vector2(-f * 0.5, w * 0.3 - 1.5), piv + rx * Vector2(f * 0.7, w * 0.3 - 1.5), BRASS.darkened(0.2 if not far else 0.5), 1.5)
	# toe claws on the heavier frames
	if String(cfg.get("cls", "")) in ["heavy", "colossal"]:
		for k in 2:
			var tc = piv + rx * Vector2(f * (0.62 + k * 0.14), w * 0.3 - 1.0)
			P.poly(ci, P.pts([tc, tc + rx * Vector2(5.0, 0.0), tc + rx * Vector2(1.0, -4.0)]), STEEL_D if not far else SOOT, 1.0)


static func draw(ci: CanvasItem, art: String, a) -> void:
	var cfg: Dictionary = F[art]
	var c: Dictionary = CLS[cfg.cls]
	var t: float = P.g(a, "t", 0.0)
	var moving: bool = P.g(a, "state", "idle") == "move"
	var walk: float = P.g(a, "walk", 0.0)
	var hurt: float = P.g(a, "hurt", 0.0)
	var recoil: float = P.g(a, "recoil", 0.0)
	var windup: float = P.g(a, "windup", 0.0)
	var brace: float = 1.0 if P.g(a, "brace_t", 0.0) > 0.0 else 0.0
	var abil: float = P.g(a, "ability_anim", 0.0)
	var hpf: float = P.g(a, "hp_frac", 1.0)
	var stun: bool = P.g(a, "stun_t", 0.0) > 0.0
	var tall: float = cfg.get("tall", 0.0)
	# M004: heavy recovery spring after every shot (tons of iron absorbing the kick, then settling)
	var gag: float = P.g(a, "gag", 0.0)
	var gph: float = 1.0 - gag
	var mass: float = {"light": 1.0, "medium": 0.85, "heavy": 0.7, "colossal": 0.55}.get(String(cfg.cls), 0.8)
	var spring: float = exp(-3.0 * gph) * cos(gph * 7.2) * mass if gag > 0.0 else 0.0
	# body motion: bob at foot-plant, weight transfer, recoil / hit jolt, crouch on wind-up
	var bob: float = (1.0 - absf(sin(walk))) * c.bob if moving else sin(t * 1.6) * 0.6
	var sway: float = sin(walk) * 1.6 if moving else 0.0
	# M006b: the front weapon drives the whole body (coil back, lunge in, rock back on a shot), and the
	# combat stance (engage) lowers and widens the frame; stunned frames slump forward
	var eng: float = P.g(a, "engage", 0.0)
	var front: Dictionary = cfg.get("front", {})
	var ffam: String = String(front.get("w", ""))
	var fatk: float = atk_of(a, int(front.get("i", 0)))
	var bodyp: Array = body_from(ffam, fatk, windup)
	var heavy_k: float = {"light": 0.0, "medium": 0.3, "heavy": 0.6, "colossal": 0.9}.get(String(cfg.cls), 0.3)
	var crouch: float = brace * 3.0 + (4.0 if stun else 0.0) + maxf(0.0, spring) * 3.5 + eng * (2.0 + heavy_k * 1.5) + float(bodyp[1])
	var jolt: float = -recoil * 4.0 - hurt * 2.0 - spring * 5.0
	var lean: float = recoil * -0.07 + hurt * -0.04 + (0.06 if cfg.body == "lean" else 0.0) + sin(walk) * 0.02 * float(moving) - spring * 0.06 \
		+ eng * 0.04 + float(bodyp[0]) * (1.0 - heavy_k * 0.35) + (0.18 if stun else 0.0)
	if not moving and gag <= 0.0:
		crouch += sin(t * TAU / 1.2) * 0.8     # idle: boiler breathing
	var hip_h: float = (c.thigh + c.shin) * 0.9 + tall * 0.4
	var hip = Vector2(sway + jolt * 0.4, -hip_h + bob + crouch)
	# M006: pelvis roll - the hip over the swinging leg drops a little, the planted side rides high
	var roll_h: float = sin(walk) * c.bob * 0.45 if moving else 0.0
	var stance: float = 6.0 + brace * 4.0 + eng * (3.0 + heavy_k * 3.0)
	var lift_h: float = {"light": 11.0, "medium": 10.0, "heavy": 9.0, "colossal": 8.0}.get(String(cfg.cls), 9.0)   # M006: a higher, heavier step
	var cl: Dictionary = {"thigh": c.thigh + tall * 0.2, "shin": c.shin + tall * 0.2, "leg_w": c.leg_w, "foot": c.foot}
	var f_far: Array = foot_pos(walk + PI, c.stride, lift_h, moving, -stance)
	var f_near: Array = foot_pos(walk, c.stride, lift_h, moving, stance)
	if not moving:
		# lunge: the front foot slides into the blow, the back foot braces
		f_near[0] = Vector2(f_near[0].x + float(bodyp[2]), f_near[0].y)
		f_far[0] = Vector2(f_far[0].x - float(bodyp[2]) * 0.3, f_far[0].y)
	var base: Color = cfg.base
	var trim: Color = cfg.trim
	var acc: Color = cfg.acc
	var th: float = c.torso_h + tall * 0.6
	var top = hip + Vector2(lean * th, -th)
	# M006: arms counter-swing against the legs while marching; shoulders dip with the weight
	var swing_a: float = sin(walk) * (2.6 if cfg.cls in ["light", "medium"] else 1.8) if moving else 0.0
	var sh_near = top + Vector2(4.0 - swing_a, 8.0 + absf(swing_a) * 0.3)
	var sh_far = top + Vector2(-5.0 + swing_a * 0.8, 7.0 + absf(swing_a) * 0.25)
	# --- far side: back gear, far leg, far arm
	_thrusters(ci, cfg, top, t, abil, moving, eng)
	_back_gear(ci, cfg, hip, top, t, abil, hpf, moving)
	draw_leg(ci, hip + Vector2(-4, -roll_h), f_far[0], cl, base, true, cfg, f_far[2])
	if cfg.has("back_arm") and not cfg.get("two_hand", false):
		_arm(ci, a, cfg, cfg.back_arm, sh_far, true, c)
	# --- torso & head
	_torso(ci, cfg, hip, top, th, t, abil, hpf)
	_head(ci, a, cfg, top, t, abil)
	for m in cfg.get("mounts", []):
		_mount(ci, a, cfg, m, top, sh_near, sh_far)
	if cfg.has("chest_gun"):
		_chest_gun(ci, a, cfg, top, int(cfg.chest_gun))
	# --- near leg & near arm
	draw_leg(ci, hip + Vector2(4, roll_h), f_near[0], cl, base, false, cfg, f_near[2])
	if cfg.get("two_hand", false):
		_two_hand(ci, a, cfg, sh_near, sh_far, c)
	elif cfg.has("front"):
		_arm(ci, a, cfg, cfg.front, sh_near, false, c)
	# M007: the near pauldron sits over the arm root (the arm hangs out from under the armour)
	_pauldron(ci, cfg, top, true, t, abil)
	_damage_fx(ci, hpf, top, hip, t)
	_kick_fx(ci, cfg, gag, gph, top, sh_near, th)
	if moving:
		_stomp_dust(ci, f_near, f_far, cfg)
	if P.g(a, "heat_lock_t", 0.0) > 0.0:
		P.smoke_puff(ci, sh_near + Vector2(26, -2), t * 2.0, 3, Color(1, 1, 1, 0.5))


## Shot aftermath: a spent brass casing tumbles out of the breech, the back vents dump steam,
## and a heat shimmer rises off the shoulders while the frame settles.
static func _kick_fx(ci: CanvasItem, cfg: Dictionary, gag: float, gph: float, top: Vector2, sh: Vector2, th: float) -> void:
	if gag <= 0.0:
		return
	var tw: float = cfg.tw
	var melee_w = ["hammer2", "claw", "big_claw", "drill", "fist", "big_fist", "bracer", "brace", "stub", "loader_arm", "grabber", "gauntlet",
		"tower_shield", "piston_hammer", "buckler", "axe2", "flamer", "flamer_big", "emitter_arm", "vent"]
	var gun = not cfg.get("mounts", []).is_empty() or not String(cfg.get("front", {}).get("w", "")) in melee_w
	if gun and gph < 0.85:
		var arc = sin(minf(gph * 1.3, 1.0) * PI)
		var cp = sh + Vector2(-8.0 - 34.0 * gph, -10.0 - 30.0 * arc + gph * gph * 30.0)
		var ca = gph * TAU * 1.5
		var d = Vector2.from_angle(ca)
		var n = d.orthogonal()
		P.poly(ci, P.pts([cp - d * 4.5 - n * 2.0, cp + d * 4.5 - n * 2.0, cp + d * 4.5 + n * 2.0, cp - d * 4.5 + n * 2.0]), BRASS, 1.2)
		ci.draw_line(cp + d * 4.5 - n * 2.0, cp + d * 4.5 + n * 2.0, COPPER, 1.5)
	if gph < 0.7:
		var k = 1.0 - gph / 0.7
		for i in 3:
			var vp = top + Vector2(-tw * 0.55 - i * 6.0 - gph * 18.0, 2.0 - i * 9.0 - gph * 26.0)
			ci.draw_circle(vp, 5.0 + i * 2.5 + gph * 10.0, Color(0.92, 0.92, 0.95, 0.5 * k))
	if gph > 0.15 and gph < 0.9:
		var hk = sin((gph - 0.15) / 0.75 * PI)
		for i in 2:
			var hx = top.x + tw * (0.1 + i * 0.3)
			ci.draw_line(Vector2(hx, top.y - 2), Vector2(hx + 2.0, top.y - 10.0 - th * 0.15), Color(1.0, 0.7, 0.35, 0.25 * hk), 2.0)


## Footfall dust where a foot has just planted.
static func _stomp_dust(ci: CanvasItem, f_near: Array, f_far: Array, cfg: Dictionary) -> void:
	var big = 1.6 if String(cfg.cls) == "colossal" else (1.25 if String(cfg.cls) == "heavy" else 1.0)
	for f in [f_near, f_far]:
		var lift: float = f[1]
		var fp: Vector2 = f[0]
		if lift < 0.6:
			for i in 2:
				var side = -1.0 if i == 0 else 1.0
				ci.draw_circle(Vector2(fp.x + side * 12.0 * big, -2.0), 4.0 * big, Color(0.55, 0.47, 0.38, 0.35))
				ci.draw_circle(Vector2(fp.x + side * 18.0 * big, -4.0), 2.6 * big, Color(0.55, 0.47, 0.38, 0.22))


# ================================================================== torso & head
static func _torso(ci: CanvasItem, cfg: Dictionary, hip: Vector2, top: Vector2, th: float, t: float, abil: float, hpf: float) -> void:
	var tw: float = cfg.tw
	var sw: float = cfg.sw
	var base: Color = cfg.base
	var trim: Color = cfg.trim
	var acc: Color = cfg.acc
	var pan = panel_col(cfg)
	# M007 armoured skirt: a side tasset, a front V of two hanging plates over the leg roots and a forge-mark buckle
	P.poly(ci, P.pts([hip + Vector2(-tw * 0.5, -6), hip + Vector2(-tw * 0.18, -6), hip + Vector2(-tw * 0.2, 12), hip + Vector2(-tw * 0.52, 9)]), Color(cfg.base).darkened(0.25), 2.0)
	P.poly(ci, P.pts([hip + Vector2(-tw * 0.3, -7), hip + Vector2(tw * 0.5, -7), hip + Vector2(tw * 0.52, 2)]), Color(cfg.base).darkened(0.18), 2.0)
	for sx in [-0.05, 0.27]:
		P.poly(ci, P.pts([hip + Vector2(tw * sx - tw * 0.15, -4), hip + Vector2(tw * sx + tw * 0.15, -4), hip + Vector2(tw * sx + tw * 0.11, 13), hip + Vector2(tw * sx, 17), hip + Vector2(tw * sx - tw * 0.11, 13)]), pan.darkened(0.08), 1.8)
		ci.draw_line(hip + Vector2(tw * sx - tw * 0.11, 12), hip + Vector2(tw * sx, 16), Color(cfg.trim), 1.4)
		ci.draw_line(hip + Vector2(tw * sx + tw * 0.11, 12), hip + Vector2(tw * sx, 16), Color(cfg.trim), 1.4)
	P.rivets(ci, hip + Vector2(-tw * 0.36, -2), hip + Vector2(tw * 0.42, -2), 5)
	_pauldron(ci, cfg, top, false, t, abil)
	# waist gear assembly (exposed, rotates with motion)
	P.circ(ci, hip + Vector2(0, -2), tw * 0.22, IRON_D, 2.0)
	for i in 6:
		var ang = t * 1.5 + TAU * i / 6.0
		ci.draw_line(hip + Vector2(0, -2), hip + Vector2(0, -2) + Vector2.from_angle(ang) * tw * 0.2, BRASS.darkened(0.3), 1.5)
	match String(cfg.body):
		"boiler":
			var cc = hip.lerp(top, 0.55)
			P.ell(ci, cc, tw * 0.58, th * 0.62, base, 2.5)
			P.poly(ci, P.ell_pts(cc + Vector2(-3, -5), tw * 0.42, th * 0.45, 0.0, 14, PI * 1.05, PI * 1.6), base.lightened(0.2), 0.0)
			for k in 3:
				ci.draw_arc(cc, tw * 0.58, -1.2 + k * 0.9, -0.9 + k * 0.9, 6, trim, 3.0)
			P.rivets(ci, cc + Vector2(-tw * 0.5, th * 0.2), cc + Vector2(tw * 0.5, th * 0.2), 8)
			_gauge(ci, cc + Vector2(tw * 0.25, -th * 0.18), 6.0, t)
			_furnace_window(ci, cc + Vector2(-tw * 0.18, th * 0.12), 13.0, 9.0, t, abil)
		"work":
			# open cage frame with braces and a small boxy cab
			P.rrect(ci, Rect2(hip.x - tw * 0.5, top.y + 4, tw, hip.y - top.y - 2), base.darkened(0.15), 2.0, 3.0)
			ci.draw_line(Vector2(hip.x - tw * 0.45, top.y + 6), Vector2(hip.x + tw * 0.45, hip.y - 4), IRON_D, 2.5)
			ci.draw_line(Vector2(hip.x + tw * 0.45, top.y + 6), Vector2(hip.x - tw * 0.45, hip.y - 4), IRON_D, 2.5)
			P.rrect(ci, Rect2(top.x - tw * 0.42, top.y, tw * 0.84, th * 0.48), base, 2.0, 4.0)
			ci.draw_line(Vector2(top.x - tw * 0.4, top.y + th * 0.3), Vector2(top.x + tw * 0.4, top.y + th * 0.3), trim, 3.0)
			for k in 4:
				ci.draw_line(Vector2(top.x - tw * 0.36 + k * 3.0, top.y + th * 0.33), Vector2(top.x - tw * 0.36 + k * 3.0 + 3.0, top.y + th * 0.33), SOOT, 2.0)
			P.rivets(ci, Vector2(top.x - tw * 0.38, top.y + 3), Vector2(top.x + tw * 0.38, top.y + 3), 5)
		"loader":
			P.rrect(ci, Rect2(hip.x - tw * 0.5, top.y + 2, tw, hip.y - top.y), base, 2.5, 4.0)
			# frontal loading plate with hazard stripes
			P.poly(ci, P.pts([Vector2(hip.x + tw * 0.38, top.y + 6), Vector2(hip.x + tw * 0.62, top.y + 10), Vector2(hip.x + tw * 0.62, hip.y - 4), Vector2(hip.x + tw * 0.38, hip.y)]), IRON_D, 2.0)
			for k in 4:
				var yy = top.y + 12.0 + k * (hip.y - top.y - 14.0) / 4.0
				ci.draw_line(Vector2(hip.x + tw * 0.4, yy), Vector2(hip.x + tw * 0.6, yy + 5), YELLOW, 2.5)
			P.rivets(ci, Vector2(hip.x - tw * 0.42, top.y + 8), Vector2(hip.x + tw * 0.3, top.y + 8), 5)
		"platform":
			P.poly(ci, P.pts([Vector2(hip.x - tw * 0.62, hip.y + 2), Vector2(hip.x - tw * 0.5, top.y + th * 0.35), Vector2(hip.x + tw * 0.55, top.y + th * 0.35), Vector2(hip.x + tw * 0.66, hip.y + 2)]), base, 2.5)
			P.rrect(ci, Rect2(top.x - tw * 0.3, top.y, tw * 0.6, th * 0.42), base.lightened(0.1), 2.0, 3.0)
			P.rivets(ci, Vector2(hip.x - tw * 0.5, hip.y - 4), Vector2(hip.x + tw * 0.55, hip.y - 4), 8)
			ci.draw_line(Vector2(hip.x - tw * 0.5, top.y + th * 0.5), Vector2(hip.x + tw * 0.55, top.y + th * 0.5), trim, 2.5)
		"tower":
			P.poly(ci, P.pts([Vector2(hip.x - tw * 0.45, hip.y), Vector2(top.x - tw * 0.35, top.y + 2), Vector2(top.x + tw * 0.35, top.y + 2), Vector2(hip.x + tw * 0.45, hip.y)]), base, 2.5)
			for k in 4:
				var yy2 = lerpf(top.y + 8.0, hip.y - 6.0, float(k) / 3.0)
				ci.draw_line(Vector2(hip.x - tw * 0.4, yy2), Vector2(hip.x + tw * 0.4, yy2), base.darkened(0.25), 2.0)
			P.rivets(ci, Vector2(top.x - tw * 0.3, top.y + 6), Vector2(top.x + tw * 0.3, top.y + 6), 6)
			P.rrect(ci, Rect2(top.x - sw * 0.5, top.y + 4, sw, 9), IRON_D, 2.0, 3.0)
		"fortress":
			P.poly(ci, P.pts([Vector2(hip.x - tw * 0.55, hip.y + 2), Vector2(top.x - tw * 0.6, top.y + 4), Vector2(top.x + tw * 0.6, top.y + 4), Vector2(hip.x + tw * 0.55, hip.y + 2)]), base, 3.0)
			# M007: enamel breastplate wings over the battlement chest
			P.poly(ci, P.pts([Vector2(top.x - tw * 0.6, top.y + 4), Vector2(top.x - tw * 0.1, top.y + 4), Vector2(top.x - tw * 0.24, top.y + th * 0.3), Vector2(top.x - tw * 0.55, top.y + th * 0.22)]), pan, 1.5)
			P.poly(ci, P.pts([Vector2(top.x + tw * 0.6, top.y + 4), Vector2(top.x + tw * 0.15, top.y + 4), Vector2(top.x + tw * 0.28, top.y + th * 0.3), Vector2(top.x + tw * 0.56, top.y + th * 0.22)]), pan, 1.5)
			P.poly(ci, P.pts([Vector2(top.x - tw * 0.55, top.y + 8), Vector2(top.x + tw * 0.5, top.y + 8), Vector2(top.x + tw * 0.45, top.y + th * 0.35), Vector2(top.x - tw * 0.5, top.y + th * 0.35)]), base.lightened(0.12), 0.0)
			for k in 3:
				var yy3 = top.y + th * (0.42 + k * 0.17)
				ci.draw_line(Vector2(hip.x - tw * 0.52, yy3), Vector2(hip.x + tw * 0.52, yy3), base.darkened(0.3), 2.0)
				P.rivets(ci, Vector2(hip.x - tw * 0.48, yy3 + 3), Vector2(hip.x + tw * 0.48, yy3 + 3), 7)
			_insignia(ci, top + Vector2(tw * 0.1, th * 0.28), 7.0, cfg)
			if cfg.has("rune"):
				var rk = 0.6 + 0.4 * sin(t * 3.0) + abil * 0.6
				ci.draw_line(top + Vector2(-tw * 0.2, th * 0.5), top + Vector2(tw * 0.25, th * 0.5), Color(cfg.rune, 0.8 * minf(1.0, rk)), 2.5)
		"furnace":
			P.poly(ci, P.pts([Vector2(hip.x - tw * 0.5, hip.y), Vector2(top.x - tw * 0.55, top.y + 6), Vector2(top.x + tw * 0.5, top.y + 4), Vector2(hip.x + tw * 0.55, hip.y)]), base, 2.5)
			_furnace_window(ci, hip.lerp(top, 0.5) + Vector2(tw * 0.05, 0), tw * 0.45, th * 0.3, t, abil)
			for k in 3:
				ci.draw_line(Vector2(top.x - tw * 0.45, top.y + 10 + k * 5), Vector2(top.x + tw * 0.4, top.y + 10 + k * 5), SOOT, 2.0)
			if cfg.get("seams", false):
				var sk = 0.55 + 0.45 * sin(t * 4.0) + abil
				for s2 in [[-0.4, 0.2, -0.1, 0.9], [0.3, 0.15, 0.35, 0.8]]:
					ci.draw_line(Vector2(hip.x + tw * s2[0], top.y + th * s2[1]), Vector2(hip.x + tw * s2[2], top.y + th * s2[3]), Color(1.0, 0.55, 0.15, minf(1.0, sk)), 2.5)
			P.rivets(ci, Vector2(hip.x - tw * 0.45, hip.y - 4), Vector2(hip.x + tw * 0.48, hip.y - 4), 7)
		_:   # "chest" and "lean": M007 V-tapered heroic chest over a segmented, narrow waist
			var lean_off = 6.0 if String(cfg.body) == "lean" else 0.0
			# abdomen: stacked segment plates (the narrow waist)
			for k in 3:
				var ay = hip.y - 4.0 - k * th * 0.11
				var aw = tw * (0.26 + k * 0.03)
				var ax = lerpf(hip.x, top.x, 0.15 + k * 0.1)
				P.rrect(ci, Rect2(ax - aw, ay - th * 0.11, aw * 2.0, th * 0.12), base.darkened(0.3 - k * 0.05), 1.5, 2.0)
			# the chest block: broad at the shoulders, tapering hard to the waist
			P.poly(ci, P.pts([Vector2(top.x - tw * 0.3, top.y + th * 0.62), Vector2(top.x - tw * 0.58, top.y + th * 0.18), Vector2(top.x - tw * 0.48, top.y + 2), Vector2(top.x - tw * 0.2, top.y - 3),
				Vector2(top.x + tw * 0.4 + lean_off, top.y - 2), Vector2(top.x + tw * 0.62 + lean_off, top.y + th * 0.16), Vector2(top.x + tw * 0.4 + lean_off * 0.5, top.y + th * 0.6), Vector2(top.x + tw * 0.05, top.y + th * 0.68)]), base, 2.5)
			_chest_front(ci, cfg, top, th, t, abil, lean_off)
	# (the far pauldron is drawn before the chest; the near one over the near arm in draw())


## M007 chest front: enamel breast panels with twin steam intakes either side of a round furnace-core hatch,
## a brass collar, and the forge mark on the belly plate.
static func _chest_front(ci: CanvasItem, cfg: Dictionary, top: Vector2, th: float, t: float, abil: float, lean_off: float) -> void:
	var tw: float = cfg.tw
	var base: Color = cfg.base
	var trim: Color = cfg.trim
	var pan = panel_col(cfg)
	# breast panels (two-tone blocking)
	P.poly(ci, P.pts([Vector2(top.x - tw * 0.46, top.y + 4), Vector2(top.x - tw * 0.04, top.y + 2), Vector2(top.x - tw * 0.06, top.y + th * 0.36), Vector2(top.x - tw * 0.4, top.y + th * 0.3)]), pan, 1.5)
	P.poly(ci, P.pts([Vector2(top.x + tw * 0.5 + lean_off, top.y + 4), Vector2(top.x + tw * 0.1, top.y + 2), Vector2(top.x + tw * 0.12, top.y + th * 0.36), Vector2(top.x + tw * 0.46 + lean_off * 0.6, top.y + th * 0.3)]), pan, 1.5)
	# steam intakes: angled slat grilles on each breast
	for sx in [-0.26, 0.31]:
		var ic = Vector2(top.x + tw * sx + (lean_off * 0.4 if sx > 0.0 else 0.0), top.y + th * 0.17)
		P.rrect(ci, Rect2(ic.x - tw * 0.12, ic.y - th * 0.075, tw * 0.24, th * 0.15), SOOT, 1.2, 1.5)
		for k in 3:
			var yy = ic.y - th * 0.05 + k * th * 0.05
			ci.draw_line(Vector2(ic.x - tw * 0.1, yy + 1.5), Vector2(ic.x + tw * 0.1, yy - 1.5), Color(trim, 0.85), 1.4)
	# the furnace core hatch: a riveted porthole between the intakes, glowing (brighter on abilities)
	var cc = Vector2(top.x + tw * 0.03 + lean_off * 0.3, top.y + th * 0.3)
	var cr = tw * 0.13 + 1.5
	P.circ(ci, cc, cr + 2.0, BRASS, 1.5)
	var fl = 0.6 + 0.3 * sin(t * 7.0) + abil * 0.7
	ci.draw_circle(cc, cr * 0.72, Color(1.0, clampf(0.42 + 0.22 * fl, 0.0, 1.0), 0.1) if not cfg.has("rune") else Color(cfg.rune, 0.9))
	ci.draw_line(cc + Vector2(-cr * 0.7, 0), cc + Vector2(cr * 0.7, 0), SOOT, 1.2)
	ci.draw_line(cc + Vector2(0, -cr * 0.7), cc + Vector2(0, cr * 0.7), SOOT, 1.2)
	if abil > 0.0:
		P.glow(ci, cc, cr * 3.0, Color(1.0, 0.6, 0.2, 0.6 * abil) if not cfg.has("rune") else Color(cfg.rune, 0.6 * abil))
	# brass collar under the head and the forge mark on the belly plate
	ci.draw_line(Vector2(top.x - tw * 0.32, top.y + 1), Vector2(top.x + tw * 0.36 + lean_off, top.y + 1), trim, 3.0)
	P.rivets(ci, Vector2(top.x - tw * 0.36, top.y + th * 0.42), Vector2(top.x + tw * 0.36, top.y + th * 0.42), 6)
	ci.draw_line(Vector2(top.x - tw * 0.3, top.y + th * 0.46), Vector2(top.x + tw * 0.34, top.y + th * 0.46), trim, 2.0)
	_insignia(ci, top + Vector2(tw * 0.04, th * 0.56), 3.5 + tw * 0.05, cfg)


## M007 pauldron: a big layered shoulder guard — three stacked plates swept up and out, enamel top plate,
## trim edge, rivets and a rune stud (light frames get two plates).
static func _pauldron(ci: CanvasItem, cfg: Dictionary, top: Vector2, near: bool, t: float, abil: float) -> void:
	var sw: float = cfg.sw
	var base: Color = cfg.base
	var trim: Color = cfg.trim
	var pan = panel_col(cfg)
	if not near:
		base = base.darkened(0.28)
		trim = trim.darkened(0.35)
		pan = pan.darkened(0.3)
	# a boxy shoulder block over the joint: chamfered, with an enamel top bevel, layered lames below
	var c = top + (Vector2(4.0, 8.0) if near else Vector2(-5.0, 7.0))
	var r: float = sw * (0.17 if near else 0.15)
	var heavy = String(cfg.cls) in ["heavy", "colossal"]
	var lames = 1 if String(cfg.cls) == "light" else 2
	for k in range(lames, 0, -1):
		var ly = c.y + r * (0.55 + 0.32 * k)
		var lx0 = c.x - r * (0.95 - 0.08 * k)
		var lx1 = c.x + r * (1.0 - 0.1 * k)
		P.poly(ci, P.pts([Vector2(lx0, ly - r * 0.3), Vector2(lx1, ly - r * 0.3), Vector2(lx1 + r * 0.06, ly + r * 0.08), Vector2(lx0 + r * 0.1, ly + r * 0.1)]), base.darkened(0.12 * k), 1.6)
	var blk = [c + Vector2(-r * 0.95, r * 0.7), c + Vector2(-r * 1.0, -r * 0.55), c + Vector2(-r * 0.55, -r * 1.05), c + Vector2(r * 0.85, -r * 1.05), c + Vector2(r * 1.12, -r * 0.6), c + Vector2(r * 1.05, r * 0.7)]
	P.poly(ci, P.pts(blk), base, 2.0)
	# enamel top bevel and front face panel (two-tone blocking)
	P.poly(ci, P.pts([c + Vector2(-r * 0.9, -r * 0.55), c + Vector2(-r * 0.5, -r * 0.95), c + Vector2(r * 0.8, -r * 0.95), c + Vector2(r * 1.02, -r * 0.58)]), pan, 1.0)
	P.poly(ci, P.pts([c + Vector2(r * 0.2, -r * 0.42), c + Vector2(r * 0.92, -r * 0.42), c + Vector2(r * 0.9, r * 0.5), c + Vector2(r * 0.25, r * 0.5)]), pan.darkened(0.18), 0.0)
	ci.draw_line(c + Vector2(-r * 0.92, r * 0.62), c + Vector2(r * 1.0, r * 0.62), trim, 2.0)
	P.rivets(ci, c + Vector2(-r * 0.7, -r * 0.2), c + Vector2(-r * 0.7, r * 0.45), 2)
	if heavy:
		# a swept fin on the heavier frames' shoulders
		P.poly(ci, P.pts([c + Vector2(-r * 0.2, -r * 1.0), c + Vector2(-r * 0.75, -r * 1.65), c + Vector2(r * 0.3, -r * 1.05)]), base.lightened(0.05), 1.4)
	if near:
		var rc = c + Vector2(r * 0.57, r * 0.05)
		var rk = 0.55 + 0.35 * sin(t * 3.0) + abil * 0.5
		ci.draw_circle(rc, r * 0.2, P.OUT)
		ci.draw_circle(rc, r * 0.15, Color(cfg.rune, minf(1.0, rk)) if cfg.has("rune") else Color(FORGE, minf(1.0, rk * 0.9)))


## M007 back: twin boiler thrusters behind the shoulders, each ending in a bell nozzle that vents steam
## (harder on the march, a burst on abilities). Utility frames carry a single smaller boiler.
static func _thrusters(ci: CanvasItem, cfg: Dictionary, top: Vector2, t: float, abil: float, moving: bool, eng: float) -> void:
	var tw: float = cfg.tw
	var combat = String(cfg.body) in COMBAT_BODIES
	var n = 2 if combat else 1
	for k in n:
		var bx = top.x - tw * (0.42 + k * 0.2)
		var by = top.y - 2.0 + k * 3.0
		var h = 22.0 + (5.0 if String(cfg.cls) in ["heavy", "colossal"] else 0.0)
		var w = 6.0 + k * 0.5
		P.rrect(ci, Rect2(bx - w, by, w * 2.0, h), IRON.darkened(0.1 + k * 0.15), 2.0, 4.0)
		ci.draw_line(Vector2(bx - w, by + h * 0.3), Vector2(bx + w, by + h * 0.3), BRASS.darkened(0.1 + k * 0.15), 2.0)
		ci.draw_line(Vector2(bx - w, by + h * 0.65), Vector2(bx + w, by + h * 0.65), BRASS.darkened(0.1 + k * 0.15), 2.0)
		# bell nozzle angled down and back
		var nz = Vector2(bx - w * 0.4, by + h)
		P.poly(ci, P.pts([nz + Vector2(-w * 0.5, 0), nz + Vector2(w * 0.5, 0), nz + Vector2(w * 0.3 - 4.0, 7.0), nz + Vector2(-w * 0.9 - 4.0, 9.0)]), IRON_D, 1.5)
		var vent = (1.0 if moving else 0.35) + abil * 2.0 + eng * 0.3
		var ph = fposmod(t * 2.6 + k * 0.5, 1.0)
		ci.draw_circle(nz + Vector2(-6.0 - ph * 10.0, 10.0 + ph * 8.0), (3.0 + ph * 6.0) * minf(1.6, vent), Color(0.95, 0.95, 0.97, 0.45 * (1.0 - ph) * minf(1.0, vent)))
		if abil > 0.3:
			ci.draw_circle(nz + Vector2(-4.0, 6.0), 4.0, Color(1.0, 0.6, 0.2, 0.7 * abil))


static func _insignia(ci: CanvasItem, at: Vector2, r: float, cfg: Dictionary) -> void:
	# Great Forge mark: hammer over anvil in a riveted roundel
	P.circ(ci, at, r, Color(cfg.trim).darkened(0.25), 1.5)
	ci.draw_line(at + Vector2(-r * 0.5, r * 0.35), at + Vector2(r * 0.5, r * 0.35), P.OUT, 2.0)
	ci.draw_line(at + Vector2(0, r * 0.3), at + Vector2(0, -r * 0.55), P.OUT, 1.8)
	ci.draw_line(at + Vector2(-r * 0.35, -r * 0.5), at + Vector2(r * 0.35, -r * 0.5), P.OUT, 2.5)


static func _gauge(ci: CanvasItem, at: Vector2, r: float, t: float) -> void:
	P.circ(ci, at, r, BRASS, 1.5)
	ci.draw_circle(at, r * 0.72, Color("efe6cf"))
	var nd = -2.3 + 1.8 * (0.5 + 0.5 * sin(t * 2.3))
	ci.draw_line(at, at + Vector2.from_angle(nd) * r * 0.6, Color(0.7, 0.1, 0.1), 1.4)


static func _furnace_window(ci: CanvasItem, c: Vector2, w: float, h: float, t: float, abil: float) -> void:
	P.rrect(ci, Rect2(c.x - w * 0.5, c.y - h * 0.5, w, h), SOOT, 2.0, 2.0)
	var fl = 0.6 + 0.4 * sin(t * 9.0) + abil * 0.8
	ci.draw_rect(Rect2(c.x - w * 0.4, c.y - h * 0.32, w * 0.8, h * 0.64), Color(1.0, clampf(0.45 + 0.2 * fl, 0.0, 1.0), 0.1, 0.92))
	for k in 3:
		ci.draw_line(Vector2(c.x - w * 0.4 + k * w * 0.4, c.y - h * 0.32), Vector2(c.x - w * 0.4 + k * w * 0.4, c.y + h * 0.32), SOOT, 1.5)
	if abil > 0.0:
		P.glow(ci, c, w * 1.4, Color(1.0, 0.55, 0.15, 0.7 * abil))


static func _head(ci: CanvasItem, a, cfg: Dictionary, top: Vector2, t: float, abil: float) -> void:
	var eng: float = P.g(a, "engage", 0.0)
	var dead: bool = P.g(a, "state", "") == "dead"
	var hc = top + Vector2(6.0 + eng * 1.5 + sin(t * TAU / 1.2) * 1.2 * (1.0 - eng), -6.0 + (3.0 if P.g(a, "stun_t", 0.0) > 0.0 else 0.0))
	var lamp = Color(1.0, 0.9, 0.5) if not dead else Color(0.2, 0.18, 0.15)
	var bright: float = (0.45 + eng * 0.45 + abil * 0.4) if not dead else 0.0
	var eye = Color(1.0, 0.78, 0.3, 0.55 + bright * 0.45) if not cfg.has("rune") else Color(cfg.rune, 0.55 + bright * 0.45)
	if dead:
		eye = Color(0.15, 0.13, 0.12)
	var trim: Color = cfg.trim
	var pan = panel_col(cfg)
	match String(cfg.head):
		"lamp":
			# utility helm: a rounded mining cowl, a big brass lamp and a stubby antenna
			P.rrect(ci, Rect2(hc.x - 9, hc.y - 10, 19, 15), IRON, 2.0, 5.0)
			P.rrect(ci, Rect2(hc.x - 7, hc.y - 9, 10, 5), pan, 1.2, 2.0)
			P.circ(ci, hc + Vector2(6, -2), 5.0, BRASS, 1.5)
			ci.draw_circle(hc + Vector2(6.5, -2), 3.2, lamp)
			if bright > 0.0:
				P.glow(ci, hc + Vector2(10, -2), 15.0, Color(1, 0.9, 0.5, bright))
			_beard_grille(ci, hc + Vector2(1, 5), 7.0, 5.0, BRASS.darkened(0.2))
			ci.draw_line(hc + Vector2(-6, -10), hc + Vector2(-9, -19), IRON_D, 1.5)
			ci.draw_circle(hc + Vector2(-9, -19), 1.6, FORGE)
		"cabin":
			# open cab with the dwarven driver in goggles, a roll bar and a lamp
			P.rrect(ci, Rect2(hc.x - 10, hc.y - 13, 21, 17), cfg.base, 2.0, 3.0)
			P.rrect(ci, Rect2(hc.x - 6, hc.y - 10, 14, 10), Color(0.55, 0.78, 0.9, 0.85), 1.5, 2.0)
			P.xf_push(ci, Transform2D(0.0, Vector2(0.42, 0.42), 0.0, hc + Vector2(0, -3)))
			D.dwarf_head(ci, a, Vector2.ZERO, {"beard": Color("a5532a"), "helmet": "goggle_cap", "helm_col": P.LEATHER})
			P.xf_pop(ci)
			ci.draw_line(hc + Vector2(-10, -13), hc + Vector2(-6, -18), IRON_D, 2.0)
			ci.draw_line(hc + Vector2(-6, -18), hc + Vector2(8, -18), IRON_D, 2.0)
			ci.draw_line(hc + Vector2(8, -18), hc + Vector2(11, -13), IRON_D, 2.0)
		"grille":
			# forge-mask: a furnace grille for a mouth, twin slit eyes and short ram horns curling back
			P.poly(ci, P.pts([hc + Vector2(-10, 6), hc + Vector2(-11, -6), hc + Vector2(-5, -12), hc + Vector2(7, -12), hc + Vector2(11, -5), hc + Vector2(10, 6)]), IRON_D, 2.0)
			P.poly(ci, P.pts([hc + Vector2(-5, -12), hc + Vector2(7, -12), hc + Vector2(9, -7), hc + Vector2(-4, -7)]), pan, 1.2)
			_eyes(ci, hc + Vector2(2, -4), eye, bright)
			for k in 4:
				ci.draw_line(Vector2(hc.x - 5 + k * 3.5, hc.y + 0), Vector2(hc.x - 5 + k * 3.5, hc.y + 5), Color(1.0, 0.5 + 0.3 * bright, 0.15, 0.4 + bright * 0.6), 2.0)
			for sgn in [-1.0, 1.0]:
				var hb = hc + Vector2(-2 + sgn * 6.0, -11)
				ci.draw_polyline(PackedVector2Array([hb, hb + Vector2(-5, -4), hb + Vector2(-10, -1), hb + Vector2(-9, 4)]), P.OUT, 4.0)
				ci.draw_polyline(PackedVector2Array([hb, hb + Vector2(-5, -4), hb + Vector2(-10, -1), hb + Vector2(-9, 4)]), BRASS.darkened(0.15), 2.4)
			ci.draw_line(hc + Vector2(-10, -12), hc + Vector2(10, -12), trim, 2.0)
		"visor":
			# hunter's helm: a long swept blade crest, twin eye slits under a sloped visor, a beard grille
			P.poly(ci, P.pts([hc + Vector2(-9, 6), hc + Vector2(-10, -6), hc + Vector2(-3, -12), hc + Vector2(9, -10), hc + Vector2(12, -1), hc + Vector2(9, 6)]), cfg.base.lightened(0.06), 2.0)
			P.poly(ci, P.pts([hc + Vector2(-3, -12), hc + Vector2(9, -10), hc + Vector2(11, -5), hc + Vector2(-2, -6)]), pan, 1.2)
			_eyes(ci, hc + Vector2(3, -2), eye, bright)
			_beard_grille(ci, hc + Vector2(3, 5), 7.0, 5.0, BRASS.darkened(0.1))
			P.poly(ci, P.pts([hc + Vector2(-4, -11), hc + Vector2(-16, -22), hc + Vector2(-2, -15), hc + Vector2(2, -11)]), trim, 1.2)
			_crest_gem(ci, hc + Vector2(1, -10), 2.0, eye, bright)
		"crown", "crown_helm":
			# royal war-helm: a broad V-crest of swept brass horns, a forged crown, twin eyes, a long braided beard plate
			P.poly(ci, P.pts([hc + Vector2(-11, 6), hc + Vector2(-11, -7), hc + Vector2(-4, -13), hc + Vector2(8, -13), hc + Vector2(12, -4), hc + Vector2(11, 6)]), IRON, 2.0)
			P.poly(ci, P.pts([hc + Vector2(-4, -13), hc + Vector2(8, -13), hc + Vector2(10, -7), hc + Vector2(-3, -7)]), pan, 1.2)
			_eyes(ci, hc + Vector2(3, -3), eye, bright)
			_beard_grille(ci, hc + Vector2(3, 6), 8.5, 9.0, BRASS)
			_v_crest(ci, hc + Vector2(2, -12), 11.0, BRASS, trim)
			for k in 4:
				var cx = hc.x - 6.0 + k * 4.5
				P.poly(ci, P.pts([Vector2(cx - 1.8, hc.y - 13), Vector2(cx, hc.y - 18 - (2 if k == 1 or k == 2 else 0)), Vector2(cx + 1.8, hc.y - 13)]), BRASS, 1.0)
			_crest_gem(ci, hc + Vector2(2, -12), 2.4, eye, bright)
		_:   # "helm": the standard Forge-Knight helm — horned V-crest, twin eyes, cheek guards, beard grille
			P.poly(ci, P.pts([hc + Vector2(-10, 6), hc + Vector2(-11, -6), hc + Vector2(-4, -12), hc + Vector2(7, -12), hc + Vector2(11, -4), hc + Vector2(10, 6)]), cfg.base.darkened(0.08), 2.0)
			P.poly(ci, P.pts([hc + Vector2(-4, -12), hc + Vector2(7, -12), hc + Vector2(9, -7), hc + Vector2(-3, -7)]), pan, 1.2)
			_eyes(ci, hc + Vector2(3, -3), eye, bright)
			P.poly(ci, P.pts([hc + Vector2(-11, -2), hc + Vector2(-5, -2), hc + Vector2(-4, 6), hc + Vector2(-10, 6)]), cfg.base.darkened(0.25), 1.2)
			_beard_grille(ci, hc + Vector2(3, 5), 7.5, 6.0, BRASS.darkened(0.15))
			_v_crest(ci, hc + Vector2(1, -11), 9.0, BRASS.darkened(0.05), trim)
			_crest_gem(ci, hc + Vector2(1, -11), 2.0, eye, bright)
			P.rivets(ci, hc + Vector2(-8, -9), hc + Vector2(-5, -10), 2)


## Twin eye slits (the mecha "eyes"), glowing when engaged.
static func _eyes(ci: CanvasItem, c: Vector2, col: Color, bright: float) -> void:
	P.rect(ci, Rect2(c.x - 6.5, c.y - 2.4, 13.0, 4.0), SOOT, 0.0)
	ci.draw_line(c + Vector2(-5.5, 0), c + Vector2(-1.0, -0.6), col, 2.0)
	ci.draw_line(c + Vector2(1.5, -0.6), c + Vector2(6.0, 0.2), col, 2.0)
	if bright > 0.6:
		P.glow(ci, c + Vector2(4, 0), 8.0, Color(col, (bright - 0.6) * 1.2))


## A swept V-crest of two brass horns rising from the brow.
static func _v_crest(ci: CanvasItem, at: Vector2, h: float, col: Color, trim: Color) -> void:
	P.poly(ci, P.pts([at + Vector2(-1.5, 0), at + Vector2(-h * 0.85, -h * 0.95), at + Vector2(-h * 0.55, -h * 0.98), at + Vector2(1.5, -2.0)]), col, 1.2)
	P.poly(ci, P.pts([at + Vector2(-1.0, 0), at + Vector2(h * 0.9, -h * 1.05), at + Vector2(h * 0.62, -h * 0.72), at + Vector2(1.0, 2.0)]), col.lightened(0.12), 1.2)
	ci.draw_line(at + Vector2(1.0, -1.0), at + Vector2(h * 0.75, -h * 0.9), trim.lightened(0.2), 1.0)


static func _crest_gem(ci: CanvasItem, at: Vector2, r: float, col: Color, bright: float) -> void:
	ci.draw_circle(at, r + 1.0, P.OUT)
	ci.draw_circle(at, r, Color(col, 0.6 + bright * 0.4))


## The beard faceplate: braided brass slats hanging from the jaw (the most dwarven thing about these machines).
static func _beard_grille(ci: CanvasItem, at: Vector2, w: float, h: float, col: Color) -> void:
	P.poly(ci, P.pts([at + Vector2(-w, -1), at + Vector2(w, -1), at + Vector2(w * 0.7, h * 0.6), at + Vector2(0, h), at + Vector2(-w * 0.7, h * 0.6)]), col.darkened(0.3), 1.4)
	for k in 4:
		var x = -w * 0.6 + k * w * 0.4
		ci.draw_line(at + Vector2(x, 0), at + Vector2(x * 0.7, h * (0.55 + 0.1 * float(k % 2))), col.lightened(0.15), 1.5)


# ================================================================== back gear
static func _back_gear(ci: CanvasItem, cfg: Dictionary, hip: Vector2, top: Vector2, t: float, abil: float, hpf: float, moving: bool) -> void:
	var tw: float = cfg.tw
	var puff = 4 if moving or abil > 0.0 else 2
	for g in cfg.get("back", []):
		match String(g):
			"boiler":
				P.rrect(ci, Rect2(top.x - tw * 0.95, top.y + 4, tw * 0.5, 26), COPPER, 2.0, 6.0)
				P.rivets(ci, Vector2(top.x - tw * 0.9, top.y + 12), Vector2(top.x - tw * 0.5, top.y + 12), 3)
				P.rect(ci, Rect2(top.x - tw * 0.85, top.y - 6, 5, 10), IRON_D, 1.5)
				P.smoke_puff(ci, Vector2(top.x - tw * 0.82, top.y - 9), t, puff)
			"stacks1", "stacks2", "stacks3":
				var n = int(String(g).substr(6))
				for k in n:
					var sx = top.x - tw * 0.45 - k * 7.0
					var hh = 16.0 + k * 3.0
					P.rect(ci, Rect2(sx, top.y - hh + 6, 6, hh), IRON_D, 1.5)
					P.rect(ci, Rect2(sx - 1.5, top.y - hh + 3, 9, 4), BRASS, 1.2)
					P.smoke_puff(ci, Vector2(sx + 3, top.y - hh), t + k * 0.37, puff, Color(0.3, 0.28, 0.27, 0.55 if hpf > 0.5 else 0.75))
			"pipes":
				for k in 2:
					ci.draw_line(top + Vector2(-tw * 0.4, 14 + k * 6), top + Vector2(-tw * 0.75, 20 + k * 8), P.OUT, 5.0)
					ci.draw_line(top + Vector2(-tw * 0.4, 14 + k * 6), top + Vector2(-tw * 0.75, 20 + k * 8), COPPER, 3.0)
				if abil > 0.0:
					P.smoke_puff(ci, top + Vector2(-tw * 0.8, 22), t * 3.0, 4, Color(1, 1, 1, 0.5))
			"engine":
				P.rrect(ci, Rect2(top.x - tw * 0.85, top.y + 8, tw * 0.45, 20), IRON_D, 2.0, 3.0)
				for k in 3:
					var ang = t * 8.0 + k * 2.1
					P.circ(ci, top + Vector2(-tw * 0.62, 18), 5.0, BRASS, 1.2)
					ci.draw_line(top + Vector2(-tw * 0.62, 18), top + Vector2(-tw * 0.62, 18) + Vector2.from_angle(ang) * 4.5, SOOT, 1.5)
			"drum":
				P.circ(ci, top + Vector2(-tw * 0.55, 16), 9.0, BRASS, 2.0)
				for k in 6:
					ci.draw_circle(top + Vector2(-tw * 0.55, 16) + Vector2.from_angle(t * 2.0 + k) * 5.5, 1.6, COPPER.darkened(0.3))
			"belts", "ammo_housing":
				P.rrect(ci, Rect2(top.x - tw * 0.95, top.y + 6, tw * 0.55, 24), GUNMETAL, 2.0, 3.0)
				for k in 5:
					ci.draw_line(top + Vector2(-tw * 0.9 + k * 4.5, 8), top + Vector2(-tw * 0.9 + k * 4.5, 28), BRASS.darkened(0.15), 1.5)
			"coil":
				var cc = top + Vector2(-tw * 0.55, 6)
				for k in 6:
					P.ell(ci, cc + Vector2(0, -k * 5.0), 8.0, 2.8, COPPER if k % 2 == 0 else COPPER.darkened(0.2), 1.2)
				var gk = 0.5 + 0.5 * sin(t * 7.0) + abil
				P.glow(ci, cc + Vector2(0, -30), 12.0, Color(RUNE_BLUE, 0.6 * minf(gk, 1.0)))
				ci.draw_circle(cc + Vector2(0, -30), 3.5, Color(0.85, 0.95, 1.0))
			"spikes":
				for k in 3:
					P.poly(ci, P.pts([top + Vector2(-tw * 0.3 - k * 6, 6 + k * 2), top + Vector2(-tw * 0.6 - k * 8, -4 + k * 3), top + Vector2(-tw * 0.3 - k * 6, 12 + k * 2)]), STEEL_D, 1.5)
			"ammo_rack":
				P.rect(ci, Rect2(top.x - tw * 0.9, top.y + 8, tw * 0.45, 20), LEATHER, 2.0)
				for k in 3:
					P.ell(ci, top + Vector2(-tw * 0.8 + k * 6, 13), 2.5, 4.0, SOOT, 1.0)
			"tank":
				P.ell(ci, top + Vector2(-tw * 0.7, 20), 7.0, 14.0, Color("7a5a2a"), 2.0)
				ci.draw_line(top + Vector2(-tw * 0.7, 7), top + Vector2(-tw * 0.7, 33), BRASS, 2.0)
			"emitter":
				var ec = top + Vector2(-tw * 0.55, 0)
				P.rrect(ci, Rect2(ec.x - 7, ec.y - 18, 14, 30), IRON_D, 2.0, 3.0)
				var rk = 0.5 + 0.5 * sin(t * 3.0) + abil
				for k in 3:
					ci.draw_line(ec + Vector2(-4, -14 + k * 9), ec + Vector2(4, -14 + k * 9), Color(RUNE_BLUE, minf(1.0, rk)), 2.5)
			"furnace_core":
				P.circ(ci, top + Vector2(-tw * 0.6, 22), 10.0, IRON_D, 2.0)
				ci.draw_circle(top + Vector2(-tw * 0.6, 22), 6.0, Color(1.0, 0.6 + 0.2 * sin(t * 6.0), 0.15))
			"battlements":
				for k in 4:
					P.rect(ci, Rect2(top.x - tw * 0.55 + k * 9.0, top.y - 6, 6, 7), Color("5a5550").darkened(0.1), 1.5)
			"banner":
				var wv = sin(t * 2.0) * 3.0
				ci.draw_line(top + Vector2(-tw * 0.6, 10), top + Vector2(-tw * 0.6, -26), IRON_D, 2.5)
				P.poly(ci, P.pts([top + Vector2(-tw * 0.6, -24), top + Vector2(-tw * 0.6 - 18 + wv, -22), top + Vector2(-tw * 0.6 - 16 + wv, -4), top + Vector2(-tw * 0.6, -6)]), BLUE, 1.5)
				P.circ(ci, top + Vector2(-tw * 0.6 - 9 + wv * 0.5, -14), 3.0, BRASS, 1.0)
			"stabilizers":
				for sx2 in [-1.0, 1.0]:
					ci.draw_line(hip + Vector2(sx2 * tw * 0.4, -4), hip + Vector2(sx2 * tw * 0.9, 34), P.OUT, 6.0)
					ci.draw_line(hip + Vector2(sx2 * tw * 0.4, -4), hip + Vector2(sx2 * tw * 0.9, 34), STEEL_D, 4.0)
					P.rect(ci, Rect2(hip.x + sx2 * tw * 0.9 - 6, hip.y + 32, 12, 4), IRON_D, 1.5)
			"vents":
				for k in 3:
					var vp = top + Vector2(-tw * 0.4 - k * 5, 10 + k * 7)
					P.rect(ci, Rect2(vp.x - 6, vp.y, 8, 4), SOOT, 1.0)
					if abil > 0.0 or sin(t * 2.0 + k) > 0.6:
						ci.draw_circle(vp + Vector2(-6, 0), 4.0, Color(1.0, 0.5, 0.15, 0.5))


# ================================================================== arms & weapons
static func _arm(ci: CanvasItem, a, cfg: Dictionary, arm: Dictionary, sh: Vector2, far: bool, c: Dictionary) -> void:
	var fam: String = arm.w
	var i: int = int(arm.i)
	var atk = atk_of(a, i)
	var alt: bool = arm.get("alt", false)
	if alt:
		atk = clampf(atk * 1.4 - 0.4, 0.0, 1.0)   # alternating second arm lags the first
	var windup: float = P.g(a, "windup", 0.0)
	if alt or (fam in ["brace", "bracer", "stub", "loader_arm", "buckler"]):
		windup *= 0.5 if fam in MELEE_FAMS else 0.0
	var eng: float = P.g(a, "engage", 0.0)
	var t: float = P.g(a, "t", 0.0)
	var gag: float = P.g(a, "gag", 0.0)
	var abil: float = P.g(a, "ability_anim", 0.0)
	var stun: bool = P.g(a, "stun_t", 0.0) > 0.0
	var col: Color = Color(cfg.base).darkened(0.3) if far else Color(cfg.base)
	var ua: float = 13.0 + (2.0 if cfg.cls == "heavy" else 0.0) + (3.0 if cfg.cls == "colossal" else 0.0)
	var fa: float = ua * 0.95
	var aw: float = c.leg_w * 0.8
	var aim = aim_of(a, i, 0.15)
	var heavy_k: float = {"light": 0.0, "medium": 0.3, "heavy": 0.6, "colossal": 0.9}.get(String(cfg.cls), 0.3)
	var pose: Array = arm_pose(fam, eng, atk, windup, gag, aim, t, heavy_k)
	var upper_ang: float = float(pose[0])
	var fore_ang: float = float(pose[1])
	if stun:
		upper_ang = 1.45
		fore_ang = 1.3
	elif abil > 0.55 and fam in MELEE_FAMS and not fam in ["brace", "bracer", "stub"]:
		# ability: a power pose - the arm flexes up, vents and runes flare (drawn by the torso/head)
		upper_ang = lerpf(upper_ang, 0.6, 0.6)
		fore_ang = lerpf(fore_ang, -1.3, 0.6)
	var elbow = sh + Vector2.from_angle(upper_ang) * ua
	var hand = elbow + Vector2.from_angle(fore_ang) * fa
	var melee = fam in MELEE_FAMS
	var gun = not ARM_POSE.has(fam)
	# guns: the shot slams the forearm back along its own axis, then it slides home
	if gun:
		var kick = (12.0 if fam in ["cannon", "titan_cannon", "flamer_big"] else 6.0) * (1.0 - heavy_k * 0.3)
		hand -= Vector2.from_angle(fore_ang) * (atk * atk * kick if atk >= 0.5 else atk * 2.0 * kick * 0.5)
	# melee: a motion smear swept from the coil to the impact on the strike frames
	if melee and atk >= 0.75 and not far:
		var fp: Dictionary = ARM_POSE[fam]
		var coil_hand = sh + Vector2.from_angle(float(fp.coil[0])) * ua + Vector2.from_angle(float(fp.coil[1])) * fa
		var hit_hand = sh + Vector2.from_angle(float(fp.hit[0])) * ua + Vector2.from_angle(float(fp.hit[1])) * fa
		var a0 = (coil_hand - sh).angle()
		var a1 = (hit_hand - sh).angle()
		if a1 - a0 > PI:
			a1 -= TAU
		elif a0 - a1 > PI:
			a1 += TAU
		var r = (hit_hand - sh).length() + float(fp.reach) * 0.8
		if fam in ["claw", "big_claw", "piston_hammer"]:
			smear(ci, sh, maxf(a0, a1 - 1.9) if a1 > a0 else minf(a0, a1 + 1.9), a1, r, r * 0.74, 0.17 * (atk - 0.7) / 0.3)
		else:
			# thrusts and punches: straight speed streaks from the cocked fist to the impact
			var sd = (hit_hand - coil_hand)
			var nn = sd.normalized().orthogonal()
			var sk = (atk - 0.7) / 0.3
			for j in 3:
				var o = nn * (float(j) - 1.0) * 5.0
				ci.draw_line(coil_hand.lerp(hit_hand, 0.25) + o, hit_hand - sd.normalized() * 6.0 + o, Color(1, 1, 1, 0.3 * sk), 2.5 - absf(float(j) - 1.0))
	# upper arm + actuator
	P.limb(ci, sh, elbow, aw, col)
	P.circ(ci, sh, aw * 0.7, Color(cfg.trim).darkened(0.35 if far else 0.0), 1.5)
	var ad = (elbow - sh).normalized().orthogonal() * aw * 0.6
	# the shoulder actuator piston visibly extends and compresses with the arm
	var pist = clampf(0.5 + (upper_ang - 0.9) * 0.4, 0.15, 0.95)
	ci.draw_line(sh + ad, sh + ad + (elbow - sh) * pist, STEEL_D if far else STEEL, 2.5)
	ci.draw_line(sh + ad + (elbow - sh) * pist, elbow + ad * 0.6, BRASS.darkened(0.2 if far else 0.0), 1.5)
	P.limb(ci, elbow, hand, aw * 0.95, col.darkened(0.08))
	# M007 forearm guard: a flared armour shell, enamel-panelled, wider toward the wrist
	var fd = (hand - elbow).normalized()
	var fn = fd.orthogonal()
	var gp = panel_col(cfg).darkened(0.3 if far else 0.0)
	P.poly(ci, P.pts([elbow + fd * 3.0 + fn * aw * 0.55, hand - fd * 2.0 + fn * aw * 0.78, hand - fd * 2.0 - fn * aw * 0.7, elbow + fd * 3.0 - fn * aw * 0.5]), col.darkened(0.04), 1.6)
	P.poly(ci, P.pts([elbow + fd * 5.0 + fn * aw * 0.4, hand - fd * 4.0 + fn * aw * 0.6, hand - fd * 4.0 + fn * aw * 0.1, elbow + fd * 5.0 + fn * aw * 0.05]), gp, 0.0)
	ci.draw_line(hand - fd * 2.0 + fn * aw * 0.78, hand - fd * 2.0 - fn * aw * 0.7, Color(cfg.trim).darkened(0.35 if far else 0.0), 1.6)
	P.circ(ci, elbow, aw * 0.45, BRASS.darkened(0.3 if far else 0.0), 1.2)
	_weapon(ci, a, cfg, fam, hand, fore_ang, atk, far, c, i)
	# impact effects at the moment the blow lands
	if not far and atk >= 0.7:
		var k = (atk - 0.7) / 0.3
		match fam:
			"fist", "big_fist", "gauntlet", "tower_shield", "buckler":
				var hp = hand + Vector2.from_angle(fore_ang) * 10.0
				for j in 3:
					ci.draw_arc(hp, 6.0 + j * 5.0, fore_ang - 0.9, fore_ang + 0.9, 8, Color(1, 0.95, 0.8, 0.55 * k * (1.0 - j * 0.25)), 2.0)
			"claw", "big_claw", "piston_hammer":
				var tip = hand + Vector2.from_angle(fore_ang) * float(ARM_POSE[fam].reach)
				if tip.y > -18.0 or fam == "piston_hammer":
					impact_dust(ci, Vector2(tip.x, 0), 9.0 + heavy_k * 8.0, k)
				for j in 4:
					var sd = Vector2.from_angle(fore_ang + PI + (float(j) - 1.5) * 0.5)
					ci.draw_line(tip + sd * 3.0, tip + sd * (9.0 + j * 2.0), Color(1, 0.85, 0.4, 0.9 * k), 1.5)
	# guns: smoke drifting off the muzzle through the follow-through
	if gun and atk > 0.2 and atk < 0.8 and not fam in ["flamer", "flamer_big"]:
		var mz = hand + Vector2.from_angle(fore_ang) * (GUN_POSE.reach if fam != "repeater" else 24.0)
		var sk = 1.0 - (atk - 0.2) / 0.6
		ci.draw_circle(mz + Vector2(4.0 + sk * 8.0, -sk * 10.0), 4.0 + sk * 6.0, Color(0.82, 0.8, 0.78, 0.45 * (1.0 - sk)))
		ci.draw_circle(mz + Vector2(-2.0 + sk * 4.0, -4.0 - sk * 14.0), 3.0 + sk * 5.0, Color(0.82, 0.8, 0.78, 0.3 * (1.0 - sk)))
	if stun and not far:
		for j in 2:
			var sp = elbow + Vector2(sin(t * 23.0 + j * 2.0) * 4.0, -3.0 - j * 3.0)
			ci.draw_line(sp, sp + Vector2(3, -4), Color(0.6, 0.85, 1.0, 0.9), 1.5)


static func _two_hand(ci: CanvasItem, a, cfg: Dictionary, sh_n: Vector2, sh_f: Vector2, c: Dictionary) -> void:
	var fam: String = cfg.front.w
	var atk = atk_of(a, 0)
	var windup: float = P.g(a, "windup", 0.0)
	var abil: float = P.g(a, "ability_anim", 0.0)
	var eng: float = P.g(a, "engage", 0.0)
	var gag: float = P.g(a, "gag", 0.0)
	var t: float = P.g(a, "t", 0.0)
	var stun: bool = P.g(a, "stun_t", 0.0) > 0.0
	var heavy_k: float = 0.9 if cfg.cls == "colossal" else 0.6
	# M006b two-handed timeline: carried low -> held at the ready -> heaved overhead -> crushing downswing into
	# the ground -> follow-through -> a slow, heavy lift back to the ready (with a settling wobble)
	var relax = 0.95
	var guard = 0.1
	var coil = -2.65
	var hit = 0.9
	var over = 1.1
	var base = lerpf(relax, guard, eng) + sin(t * 1.2) * 0.04
	var tl = timeline(atk, windup)
	var swing: float
	match int(tl[0]):
		1:
			swing = coil + sin(t * 31.0) * 0.02
		2:
			swing = lerpf(hit, over, float(tl[1]))
		3:
			swing = lerpf(over, lerpf(hit, base, 0.3), float(tl[1]))
		4:
			swing = lerpf(lerpf(hit, base, 0.3), base, float(tl[1]))
		_:
			swing = base
			if gag > 0.0:
				var gph = 1.0 - gag
				swing -= exp(-3.0 * gph) * sin(gph * 6.5) * 0.25
	if abil > 0.6:
		swing = -2.6
	if stun:
		swing = 1.45
	var ua = 15.0 + (4.0 if cfg.cls == "colossal" else 0.0)
	var aw: float = c.leg_w * 0.85
	var grip = sh_n + Vector2.from_angle(swing * 0.5 + 0.6) * ua + Vector2.from_angle(swing) * ua * 0.6
	var hl = (46.0 if cfg.cls != "colossal" else 54.0) if fam == "hammer2" else 56.0
	# the swing's smear: a wide crescent from overhead to the ground on the strike frames
	if int(tl[0]) == 2 and float(tl[1]) < 0.5:
		var coil_grip = sh_n + Vector2.from_angle(coil * 0.5 + 0.6) * ua + Vector2.from_angle(coil) * ua * 0.6
		var a0 = (coil_grip + Vector2.from_angle(coil) * hl - sh_n).angle()
		var a1 = (grip + Vector2.from_angle(swing) * hl - sh_n).angle()
		if a1 < a0:
			a1 += TAU
		a0 = maxf(a0, a1 - 1.9)   # only the business end of the arc: overhead to impact
		var r = (grip + Vector2.from_angle(swing) * (hl - 6.0) - sh_n).length()
		smear(ci, sh_n, a0, a1, r + 4.0, r * 0.78, 0.17 * (1.0 - float(tl[1]) * 2.0))
	P.limb(ci, sh_f, grip, aw * 0.9, Color(cfg.base).darkened(0.3))
	_weapon(ci, a, cfg, fam, grip, swing, atk, false, c, 0)
	P.limb(ci, sh_n, grip, aw, cfg.base)
	P.circ(ci, sh_n, aw * 0.7, cfg.trim, 1.5)
	# the head meets the ground: dust, chips and a shock ring
	if int(tl[0]) == 2 or (int(tl[0]) == 3 and float(tl[1]) < 0.4):
		var head = grip + Vector2.from_angle(swing) * (hl - 10.0)
		var k = 1.0 - (float(tl[1]) * 0.5 if int(tl[0]) == 2 else 0.5 + float(tl[1]))
		impact_dust(ci, Vector2(head.x, 0), 14.0 + heavy_k * 10.0, clampf(k, 0.0, 1.0))
		ci.draw_arc(Vector2(head.x, -2), 18.0 + (1.0 - k) * 30.0, PI * 1.05, PI * 1.95, 12, Color(1, 0.9, 0.7, 0.5 * k), 3.0)


static func _weapon(ci: CanvasItem, a, cfg: Dictionary, fam: String, hand: Vector2, ang: float, atk: float, far: bool, c: Dictionary, i: int) -> void:
	var t: float = P.g(a, "t", 0.0)
	var spin: float = P.g(a, "spin", t * 3.0)
	var dv = Vector2.from_angle(ang)
	var nv = dv.orthogonal()
	var flash = clampf((atk - 0.7) / 0.3, 0.0, 1.0)
	var heat: bool = P.g(a, "heat_lock_t", 0.0) > 0.0
	match fam:
		"claw", "big_claw":
			var s = 1.0 if fam == "claw" else 1.45
			P.rrect(ci, Rect2(hand.x - 5 * s, hand.y - 5 * s, 10 * s, 10 * s), IRON_D, 1.5, 2.0)
			for k in 3:
				var base = hand + nv * (k - 1) * 4.0 * s
				var tip = base + dv.rotated(-0.35 + k * 0.1) * 14.0 * s + nv * (k - 1) * 2.0
				P.poly(ci, P.pts([base - nv * 2.0 * s, tip, base + nv * 2.0 * s]), STEEL if not far else STEEL_D, 1.5)
			if fam == "big_claw":
				P.poly(ci, P.pts([hand - dv * 10 - nv * 6, hand - dv * 3 - nv * 12, hand - dv * 2 - nv * 5]), STEEL_D, 1.2)
		"fist", "big_fist", "gauntlet":
			var fs = 6.5 if fam == "fist" else (9.5 if fam == "big_fist" else 7.0)
			fs *= 1.0 + (0.25 if cfg.cls == "colossal" else 0.0)
			P.rrect(ci, Rect2(hand.x - fs * 0.7, hand.y - fs * 0.7, fs * 1.6, fs * 1.4), Color(cfg.base).darkened(0.1 if not far else 0.35), 2.0, 3.0)
			for k in 3:
				ci.draw_line(hand + Vector2(fs * 0.5, -fs * 0.5 + k * fs * 0.5), hand + Vector2(fs * 0.9, -fs * 0.5 + k * fs * 0.5), P.OUT, 2.0)
			if fam == "gauntlet":
				var gk = 0.5 + 0.5 * sin(t * 9.0) + atk
				ci.draw_circle(hand + Vector2(fs * 0.6, 0), 3.0, Color(RUNE_BLUE, minf(1.0, gk)))
				if atk > 0.5:
					P.glow(ci, hand + Vector2(fs, 0), 12.0, Color(RUNE_BLUE, 0.6))
			# piston on the forearm fires with the punch
			var pk = sin(clampf(atk, 0.0, 1.0) * PI)
			ci.draw_line(hand - dv * (10.0 - pk * 6.0) + nv * fs * 0.7, hand + nv * fs * 0.7, BRASS, 2.5)
		"grabber":
			var open = 0.5 - sin(clampf(atk, 0.0, 1.0) * PI) * 0.45
			P.circ(ci, hand, 5.0, IRON_D, 1.5)
			for sgn in [-1.0, 1.0]:
				var j = hand + dv.rotated(sgn * open) * 9.0
				P.limb(ci, hand, j, 4.0, YELLOW.darkened(0.2 if not far else 0.5))
				P.limb(ci, j, j + dv.rotated(-sgn * 0.6) * 7.0, 3.5, IRON_D)
		"drill":
			var dl = 34.0
			var root = hand - dv * 2.0
			P.rrect(ci, Rect2(root.x - 7, root.y - 7, 12, 14), IRON_D, 2.0, 3.0)
			P.poly(ci, P.pts([root + nv * 9.0, root + dv * dl, root - nv * 9.0]), STEEL, 2.0)
			# rotating spiral flutes
			for k in 5:
				var u = fposmod(spin * 0.12 + k * 0.2, 1.0)
				var p = root + dv * (u * dl * 0.9)
				var hw = 9.0 * (1.0 - u)
				ci.draw_line(p + nv * hw, p + dv * 4.0 - nv * hw, YELLOW.darkened(0.3), 2.0)
			P.circ(ci, root, 5.5, BRASS, 1.5)
			if atk > 0.2:
				for k in 3:
					var sp = root + dv * dl + Vector2(randf_range(-4, 4), randf_range(-6, 6))
					ci.draw_line(sp, sp + Vector2(randf_range(-9, 9), randf_range(-12, 2)), Color(1, 0.85, 0.35), 1.5)
		"piston_hammer":
			P.bar(ci, hand - dv * 4.0, ang, 26, 4.0, IRON_D, 1.5)
			var hh = hand + dv * 24.0
			P.poly(ci, P.pts([hh - nv * 11 - dv * 6, hh - nv * 11 + dv * 7, hh + nv * 11 + dv * 7, hh + nv * 11 - dv * 6]), STEEL_D, 2.0)
			ci.draw_line(hh - nv * 10 + dv * 1, hh + nv * 10 + dv * 1, YELLOW, 2.5)
			ci.draw_line(hand + nv * 3.0, hh + nv * 4.0, BRASS, 2.0)
		"hammer2":
			var hl = 46.0 if cfg.cls != "colossal" else 54.0
			P.bar(ci, hand - dv * 10.0, ang, hl, 4.5, Color("5e3b1e"), 1.5)
			var hh2 = hand + dv * (hl - 12.0)
			var hs = 14.0 if cfg.cls != "colossal" else 17.0
			P.poly(ci, P.pts([hh2 - nv * hs - dv * 9, hh2 - nv * hs + dv * 9, hh2 + nv * hs * 0.8 + dv * 9, hh2 + nv * hs * 0.8 - dv * 9]), IRON_D, 2.5)
			P.rivets(ci, hh2 - nv * hs * 0.7, hh2 + nv * hs * 0.6, 4)
			ci.draw_line(hh2 - nv * hs + dv * 2, hh2 + nv * hs * 0.8 + dv * 2, cfg.trim, 3.0)
			# steam-assisted head: vents on the swing
			if atk > 0.6:
				P.smoke_puff(ci, hh2 - dv * 9, t * 4.0, 3, Color(1, 1, 1, 0.45))
		"axe2":
			var al = 56.0
			P.bar(ci, hand - dv * 12.0, ang, al, 4.5, Color("4a2e18"), 1.5)
			var ah = hand + dv * (al - 18.0)
			P.poly(ci, P.pts([ah - nv * 2, ah - nv * 22 - dv * 10, ah - nv * 26 + dv * 6, ah - nv * 18 + dv * 16, ah + dv * 8]), STEEL, 2.5)
			ci.draw_line(ah - nv * 24 - dv * 8, ah - nv * 25 + dv * 8, Color("dfe6ea"), 2.0)
			P.poly(ci, P.pts([ah + nv * 2, ah + nv * 8 - dv * 4, ah + nv * 8 + dv * 6, ah + dv * 6]), BRASS, 1.5)
			if cfg.has("rune"):
				ci.draw_line(ah - nv * 12 - dv * 2, ah - nv * 14 + dv * 6, Color(cfg.rune, 0.85), 2.0)
		"tower_shield":
			var sx = hand.x + 4.0
			var sy0 = hand.y - 36.0
			P.poly(ci, P.pts([Vector2(sx, sy0), Vector2(sx + 13, sy0 + 3), Vector2(sx + 14, sy0 + 62), Vector2(sx + 6, sy0 + 70), Vector2(sx - 2, sy0 + 62)]), STEEL_D, 2.5)
			P.rivets(ci, Vector2(sx + 3, sy0 + 4), Vector2(sx + 3, sy0 + 60), 8, BRASS)
			_insignia(ci, Vector2(sx + 7, sy0 + 28), 6.0, cfg)
			ci.draw_line(Vector2(sx + 1, sy0 + 46), Vector2(sx + 13, sy0 + 46), cfg.trim, 2.5)
		"buckler":
			P.ell(ci, hand + Vector2(3, 0), 6.0, 11.0, COPPER.darkened(0.15), 2.0)
			P.circ(ci, hand + Vector2(4, 0), 2.5, BRASS, 1.0)
		"emitter_arm":
			P.rrect(ci, Rect2(hand.x - 4, hand.y - 12, 12, 24), IRON_D, 2.0, 3.0)
			var rk = 0.55 + 0.45 * sin(t * 4.0) + P.g(a, "ability_anim", 0.0)
			P.glow(ci, hand + Vector2(10, 0), 14.0, Color(RUNE_BLUE, 0.5 * minf(rk, 1.0)))
			ci.draw_line(hand + Vector2(8, -10), hand + Vector2(8, 10), Color(RUNE_BLUE, minf(rk, 1.0)), 3.0)
		"cannon", "titan_cannon":
			var cl = 30.0 if fam == "cannon" else 40.0
			var cw = 8.0 if fam == "cannon" else 11.0
			P.rrect(ci, Rect2(hand.x - cw, hand.y - cw, cw * 1.8, cw * 2.0), Color(cfg.base).darkened(0.2), 2.0, 3.0)
			P.bar(ci, hand, ang, cl, cw, IRON_D, 2.0)
			for k in [0.35, 0.75, 0.97]:
				var bp = hand + dv * cl * k
				ci.draw_line(bp + nv * cw * 0.62, bp - nv * cw * 0.62, BRASS, 2.5)
			P.muzzle_flash(ci, hand + dv * cl, ang, 14.0 + cw, flash)
		"repeater":
			P.bar(ci, hand, ang, 24, 7.0, COPPER.darkened(0.2), 2.0)
			P.circ(ci, hand + nv * 7.0, 6.0, BRASS, 1.5)
			for k in 5:
				ci.draw_circle(hand + nv * 7.0 + Vector2.from_angle(spin + k * 1.25) * 3.6, 1.2, SOOT)
			P.muzzle_flash(ci, hand + dv * 24.0, ang, 12.0, flash)
		"rotary":
			P.rrect(ci, Rect2(hand.x - 8, hand.y - 8, 14, 16), GUNMETAL, 2.0, 3.0)
			# rotating barrel cluster: visible barrels cycle around the axis
			for k in 4:
				var off = sin(spin + k * PI * 0.5) * 4.5
				var dep = cos(spin + k * PI * 0.5)
				if dep < 0.0:
					P.bar(ci, hand + nv * off, ang, 30, 2.6, IRON_D.darkened(0.3), 1.0)
			for k in 4:
				var off2 = sin(spin + k * PI * 0.5) * 4.5
				if cos(spin + k * PI * 0.5) >= 0.0:
					P.bar(ci, hand + nv * off2, ang, 30, 2.8, STEEL_D, 1.0)
			ci.draw_line(hand + dv * 22 + nv * 6, hand + dv * 22 - nv * 6, BRASS, 2.5)
			# belt feed
			ci.draw_line(hand - nv * 6, hand - nv * 14 - dv * 12, BRASS.darkened(0.2), 3.0)
			if heat:
				ci.draw_line(hand + dv * 18, hand + dv * 30, Color(1, 0.35, 0.15, 0.8), 3.0)
			P.muzzle_flash(ci, hand + dv * 31.0, ang + sin(t * 50.0) * 0.08, 10.0, flash)
		"flamer", "flamer_big":
			var fl = 26.0 if fam == "flamer" else 34.0
			P.bar(ci, hand, ang, fl, 8.0 if fam == "flamer" else 11.0, COPPER.darkened(0.15), 2.0)
			P.circ(ci, hand + dv * fl, 5.0, IRON_D, 1.5)
			ci.draw_circle(hand + dv * (fl + 1.0), 2.4, Color(0.4, 0.75, 1.0, 0.8))   # pilot light
			if atk > 0.05 and not heat:
				var tip = hand + dv * (fl + 2.0)
				for k in 4:
					var ln = 16.0 + k * 9.0 + sin(t * 30.0 + k) * 4.0
					ci.draw_line(tip + dv * k * 4.0, tip + dv * ln + nv * sin(t * 20.0 + k) * 5.0, Color(1.0, 0.45 + k * 0.1, 0.1, 0.55 - k * 0.1), 6.0 - k)
		"vent":
			P.bar(ci, hand, ang, 12, 7, IRON, 2.0)
			if atk > 0.2:
				for k in 3:
					ci.draw_circle(hand + dv * (16 + k * 14), 4.0 + k * 4.0, Color(1, 1, 1, 0.35 * atk))
		"brace", "bracer", "stub", "loader_arm":
			P.rrect(ci, Rect2(hand.x - 4, hand.y - 3, 9, 7), IRON_D, 1.5, 2.0)


# ================================================================== shoulder / top mounts
static func _mount(ci: CanvasItem, a, cfg: Dictionary, m: Dictionary, top: Vector2, sh_n: Vector2, sh_f: Vector2) -> void:
	var i = int(m.i)
	var at: Vector2
	match String(m.at):
		"shoulder":
			at = top + Vector2(cfg.sw * 0.24, -2)
		"shoulder_b":
			at = top + Vector2(-cfg.sw * 0.22, -4)
		_:
			at = top + Vector2(-4, -10)
	var aim = aim_of(a, i, -0.9)
	var atk = atk_of(a, i)
	var t: float = P.g(a, "t", 0.0)
	var spin: float = P.g(a, "spin", t * 3.0)
	var flash = clampf((atk - 0.6) / 0.4, 0.0, 1.0)
	var far: bool = String(m.at) == "shoulder_b"
	var dv = Vector2.from_angle(aim)
	var nv = dv.orthogonal()
	# M006b: every mount leaves a smoke wisp at the muzzle through the follow-through
	if atk > 0.2 and atk < 0.8 and String(m.w) != "mortar":
		var ml = {"aa_twin": 27.0, "aa_quad": 35.0, "aa_heavy": 47.0, "shoulder_cannon": 30.0, "siege_cannon": 38.0}.get(String(m.w), 30.0)
		var sk = 1.0 - (atk - 0.2) / 0.6
		ci.draw_circle(at + dv * ml + Vector2(sk * 6.0, -sk * 12.0), 3.0 + sk * 6.0, Color(0.82, 0.8, 0.78, 0.42 * (1.0 - sk)))
	match String(m.w):
		"aa_twin":
			aim = clampf(aim, -2.9, -0.15)
			dv = Vector2.from_angle(aim)
			nv = dv.orthogonal()
			P.rrect(ci, Rect2(at.x - 8, at.y - 6, 16, 10), BLUEGRAY.darkened(0.2 if far else 0.0), 2.0, 3.0)
			for k in 2:
				var o = nv * (k * 5.0 - 2.5) - dv * (atk * atk * 4.0 if k == 0 else atk * 3.0)   # M006b: alternating barrel recoil
				P.bar(ci, at + o, aim, 26, 3.0, GUNMETAL.darkened(0.25 if far else 0.0), 1.2)
				ci.draw_line(at + o + dv * (8.0 + fposmod(spin * 3.0, 6.0)), at + o + dv * (10.0 + fposmod(spin * 3.0, 6.0)), BRASS, 2.0)
			P.muzzle_flash(ci, at + dv * 27.0, aim, 9.0, flash)
			ci.draw_line(at + Vector2(-6, 4), at + Vector2(-12, 12), BRASS.darkened(0.2), 2.5)
		"aa_quad":
			aim = clampf(aim, -2.9, -0.15)
			dv = Vector2.from_angle(aim)
			nv = dv.orthogonal()
			P.rrect(ci, Rect2(at.x - 12, at.y - 8, 24, 13), BLUEGRAY.darkened(0.2 if far else 0.0), 2.0, 3.0)
			for k in 2:
				var o2 = nv * (k * 8.0 - 4.0)
				var rec = atk * atk * 5.0
				P.bar(ci, at + o2 - dv * rec, aim, 34, 4.5, GUNMETAL.darkened(0.25 if far else 0.0), 1.5)
				ci.draw_line(at + o2 + dv * 26 + nv * 3, at + o2 + dv * 26 - nv * 3, BRASS, 2.5)
				P.muzzle_flash(ci, at + o2 + dv * (35.0 - rec), aim, 12.0, flash)
		"aa_heavy":
			aim = clampf(aim, -2.95, -0.1)
			dv = Vector2.from_angle(aim)
			nv = dv.orthogonal()
			P.circ(ci, at, 11.0, BLUEGRAY.darkened(0.2 if far else 0.0), 2.0)
			var rec2 = atk * atk * 8.0
			P.bar(ci, at - dv * rec2, aim, 46, 7.5, IRON_D, 2.0)
			for k in [0.4, 0.8]:
				ci.draw_line(at + dv * 46.0 * k + nv * 5, at + dv * 46.0 * k - nv * 5, BRASS, 2.5)
			P.muzzle_flash(ci, at + dv * (47.0 - rec2), aim, 18.0, flash)
		"mortar":
			if atk > 0.1 and atk < 0.9:
				var ms = 1.0 - (atk - 0.1) / 0.8
				for k in 3:
					ci.draw_circle(at + Vector2(-2.0 + k * 3.0, -34.0 - ms * 30.0 - k * 9.0), 5.0 + ms * 7.0 + k, Color(0.75, 0.73, 0.72, 0.5 * (1.0 - ms)))
			var ma = -1.25 - atk * 0.15
			P.rrect(ci, Rect2(at.x - 10, at.y - 2, 20, 10), IRON_D, 2.0, 2.0)
			P.bar(ci, at + Vector2(0, 2) - Vector2.from_angle(ma) * atk * 5.0, ma, 30, 11.0, IRON, 2.0)
			ci.draw_line(at + Vector2.from_angle(ma) * 28 + Vector2.from_angle(ma).orthogonal() * 7, at + Vector2.from_angle(ma) * 28 - Vector2.from_angle(ma).orthogonal() * 7, FORGE, 3.0)
			P.muzzle_flash(ci, at + Vector2.from_angle(ma) * 32, ma, 14.0, flash)
		"shoulder_cannon", "siege_cannon":
			var big: bool = String(m.w) == "siege_cannon"
			aim = clampf(aim, -0.6, 0.35)
			dv = Vector2.from_angle(aim)
			nv = dv.orthogonal()
			var cl = 44.0 if big else 36.0
			var cw = 12.0 if big else 9.0
			# delayed heavy recoil: barrel slides back, then recovers
			var rec3 = sin(clampf(atk, 0.0, 1.0) * PI * 0.5) * (12.0 if big else 8.0)
			P.rrect(ci, Rect2(at.x - 14, at.y - cw, 22, cw * 1.8), Color(cfg.base).darkened(0.15), 2.0, 3.0)
			P.bar(ci, at - dv * (8.0 + rec3), aim, cl, cw, IRON_D, 2.5)
			for k in [0.25, 0.6, 0.95]:
				var bp = at + dv * (cl * k - 8.0 - rec3)
				ci.draw_line(bp + nv * cw * 0.6, bp - nv * cw * 0.6, FORGE.darkened(0.2) if big else BRASS, 3.0)
			# recoil pistons
			ci.draw_line(at + Vector2(-12, cw * 0.4), at + Vector2(-24, cw * 1.6), STEEL, 3.0)
			P.muzzle_flash(ci, at + dv * (cl - 8.0 - rec3), aim, 22.0 if big else 16.0, flash)
			if atk > 0.4:
				P.smoke_puff(ci, at + dv * (cl - 4.0), t * 2.0, 3, Color(0.35, 0.33, 0.32, 0.6))


static func _chest_gun(ci: CanvasItem, a, cfg: Dictionary, top: Vector2, i: int) -> void:
	# Thunderstep "Breach Cannon": only shown when the variant weapon exists
	if P.g(a, "has_w%d" % i, false) == false:
		return
	var atk = atk_of(a, i)
	var at = top + Vector2(cfg.tw * 0.35, cfg.tw * 0.5)
	P.rrect(ci, Rect2(at.x - 6, at.y - 7, 12, 14), IRON_D, 2.0, 2.0)
	P.bar(ci, at, 0.05, 22, 9.0, SOOT, 2.0)
	P.poly(ci, P.pts([at + Vector2(18, -6), at + Vector2(26, -9), at + Vector2(26, 9), at + Vector2(18, 6)]), BRASS, 1.5)
	P.muzzle_flash(ci, at + Vector2(26, 0), 0.0, 20.0, clampf((atk - 0.6) / 0.4, 0.0, 1.0))


static func _damage_fx(ci: CanvasItem, hpf: float, top: Vector2, hip: Vector2, t: float) -> void:
	if hpf < 0.55:
		P.smoke_puff(ci, top + Vector2(-4, 4), t * 1.3, 3, Color(0.15, 0.13, 0.12, 0.65))
		ci.draw_line(top + Vector2(-8, 16), top + Vector2(2, 26), P.OUT, 2.0)
	if hpf < 0.3:
		P.glow(ci, hip.lerp(top, 0.5) + Vector2(-6, 0), 12.0, Color(1, 0.45, 0.1, 0.7))
		if fmod(t * 5.0, 1.0) < 0.3:
			ci.draw_line(top + Vector2(6, 20), top + Vector2(12, 14), Color(1, 0.9, 0.4), 1.5)
