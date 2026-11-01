class_name ArtTanks
extends RefCounted
## M006c "Forged Apart": every kit vehicle is its own machine. A design table keyed by art id gives each tank
## its own size, chassis, hull silhouette, turret form and signature fittings; shared parts below build them.
## Visual only: the data parameters (len, ht, coat, turrets, plates, ram, hatch, glow, h) are unchanged and the
## pose keys are the same as M006b (t, walk, state, atk/atk2/atk3, aim0..2, hp_frac).
##
## Coordinates: facing right, ground at y = 0. A hull profile is a list of [xf, yf] with xf in hull half-lengths
## (-1 rear .. +1 front) and yf in hull heights above the hull's base line.

const P = preload("res://scripts/art/painter.gd")
const D = preload("res://scripts/art/art_dwarves.gd")

const HAZARD_Y := Color("d9a91e")
const STONE := Color("6f6a62")
const MOSS := Color("4f6b33")

# gear:  ["wheels", [[xf, r], ...]] | ["tracks", xf0, xf1, th, style] | ["halftrack", wheel_xf, r, xf0, xf1, th]
#        ["rhomboid", th] | ["bogies", n, th]
# turrets: [xf, yf, shape, tw]  (one per data turret, in data order)
const DESIGNS := {
	"coalrunner_scout_tank": {"L": 42, "H": 13, "gear": ["trike", -0.5, 11.0, 0.78, 6.5], "base": 13.0,
		"profile": [[-0.82, 0], [0.5, 0], [0.72, 0.55], [0.62, 1.0], [-0.72, 1.0], [-0.9, 0.5]],
		"turrets": [[0.42, 1.0, "pintle", 13]],
		"feat": [["coal", -0.45, 1.0], ["chimney", -0.72, 1.0, 26.0, 4.5, true], ["driver", 0.12, 1.0], ["fender", 0.78, 6.5],
			["rivets", -0.7, 0.55, 0.5], ["sack", -0.2, 1.0], ["antenna", -0.2, 1.0, 16.0, true], ["headlamp", 0.66, 0.6]]},
	"steamwheel_apc": {"L": 58, "H": 25, "gear": ["wheels", [[-0.62, 8.5], [0.0, 8.5], [0.62, 8.5]]], "base": 12.0,
		"profile": [[-0.95, 0], [0.92, 0], [1.02, 0.35], [0.86, 0.85], [0.6, 1.0], [-0.75, 1.0], [-0.95, 0.8]],
		"turrets": [[0.22, 1.0, "round", 15]],
		"feat": [["guards", [[-0.62, 8.5], [0.0, 8.5], [0.62, 8.5]]], ["drum", -1.0, 0.55, 0.18, 0.32], ["door", -0.18, 0.12, 0.3, 0.68],
			["ports", 0.2, 0.75, 0.55, 2], ["ports", -0.85, -0.45, 0.55, 2], ["hatch_head", -0.45, 1.0], ["rivets", -0.85, 0.85, 0.9],
			["headlamp", 0.95, 0.4], ["chimney", -0.85, 1.0, 9.0, 4.0, false]]},
	"ironrunner_light_tank": {"L": 56, "H": 11, "gear": ["tracks", -1.0, 0.92, 15.0, "big"], "base": 12.0,
		"profile": [[-1.0, 0], [0.8, 0], [1.14, 0.45], [0.55, 1.0], [-0.9, 1.0], [-1.04, 0.55]],
		"turrets": [[0.22, 1.0, "round", 17]],
		"feat": [["exhaust_pipe", -1.0, 0.25, 0.1], ["shovel", -0.7, 0.55], ["antenna", -0.55, 1.0, 14.0, false], ["headlamp", 0.9, 0.5],
			["slit", 0.8, 0.55], ["rivets", -0.85, 0.55, 0.85]]},
	"flamebelcher_medium_tank": {"L": 60, "H": 20, "gear": ["tracks", -0.98, 0.96, 14.0, "small"], "base": 11.0,
		"profile": [[-0.95, 0], [0.9, 0], [1.03, 0.35], [0.88, 0.78], [0.5, 1.0], [-0.5, 1.0], [-0.88, 0.8], [-1.02, 0.38]],
		"turrets": [[0.12, 1.0, "ball", 18]],
		"feat": [["tanks_h", -0.75, 1.0, 1, 0.62, 5.0], ["firebox", 0.72, 0.45], ["chimney", -0.25, 0.98, 10.0, 6.0, true],
			["bands", -0.6, 0.6, 3], ["hazard", -0.9, -0.55, 0.15]]},
	"ironclad_medium_tank": {"L": 68, "H": 18, "gear": ["tracks", -1.02, 1.02, 16.0, "med"], "base": 12.0, "skirt": true,
		"profile": [[-1.0, 0], [0.92, 0], [1.06, 0.5], [0.86, 0.62], [0.62, 1.0], [-0.7, 1.0], [-0.86, 0.62], [-1.03, 0.5]],
		"turrets": [[0.05, 1.0, "box", 22]],
		"feat": [["spare_wheel", -0.8, 0.95], ["sandbags", 0.66, 0.92, 0.62], ["rivets", -0.9, 0.9, 0.35], ["headlamp", 1.0, 0.45],
			["chimney", -0.6, 1.0, 9.0, 4.0, false], ["chimney", -0.45, 1.0, 9.0, 4.0, false], ["antenna", -0.35, 1.0, 16.0, false], ["slit", 0.9, 0.55]]},
	"skyshield_aa_tank": {"L": 62, "H": 12, "gear": ["halftrack", 0.68, 9.0, -1.0, 0.18, 14.0], "base": 12.0,
		"profile": [[-1.0, 0], [0.95, 0], [1.05, 0.6], [0.85, 1.0], [-0.95, 1.0], [-1.05, 0.5]],
		"turrets": [[-0.32, 1.0, "tub", 26]],
		"feat": [["fender", 0.68, 9.0], ["cab", 0.55, 1.0], ["ammo_rack", -0.95, 1.0], ["periscope", 0.75, 1.0], ["rivets", -0.9, 0.9, 0.45]]},
	"thunderback_heavy_tank": {"L": 80, "H": 18, "gear": ["tracks", -1.0, 1.0, 18.0, "med"], "base": 13.0, "skirt": true,
		"profile": [[-1.0, 0], [0.92, 0], [1.06, 0.55], [0.75, 1.0], [-0.92, 1.0], [-1.04, 0.5]],
		"turrets": [[0.35, 1.0, "box", 24]],
		"feat": [["hump", -0.42, 1.0, 0.56, 1.25], ["vents", -0.55, 2.0, 2], ["gauge", -0.15, 1.75], ["emblem", -0.45, 1.55, "bolt", 7.0],
			["rivets", -0.9, 0.9, 0.4], ["headlamp", 1.0, 0.45], ["antenna", 0.1, 1.0, 16.0, false]]},
	"bastion_heavy_tank": {"L": 80, "H": 28, "gear": ["tracks", -1.0, 1.0, 17.0, "med"], "base": 13.0, "skirt": true,
		"profile": [[-0.95, 0], [0.97, 0], [0.9, 1.0], [-0.88, 1.0]],
		"turrets": [[0.08, 1.0, "tower", 24]],
		"feat": [["stone", -0.9, 0.9], ["crenels", -0.88, 0.9, 1.0, 7, 6.0], ["slits", -0.7, 0.7, 0.6, 5], ["gate", 0.62, 0.0, 0.2, 0.62],
			["banner", -0.75, 1.0, 22.0], ["plates", -0.5, 0.2, 0.2, 2]]},
	"siege_sapper_tank": {"L": 72, "H": 20, "gear": ["tracks", -1.0, 0.85, 15.0, "med"], "base": 11.0,
		"profile": [[-1.0, 0], [0.82, 0], [0.95, 0.4], [0.75, 1.0], [-0.9, 1.0], [-1.0, 0.5]],
		"turrets": [[0.12, 1.0, "box", 20]],
		"feat": [["blade", 0.95], ["crane", -0.75, 1.0], ["charges", -0.55, 0.55, 3], ["hazard", 0.2, 0.7, 0.12], ["rivets", -0.9, 0.7, 0.85],
			["chimney", -0.92, 1.0, 9.0, 4.0, false]]},
	"boiler_ram": {"L": 82, "H": 8, "gear": ["tracks", -1.0, 0.82, 16.0, "med"], "base": 11.0,
		"profile": [[-1.0, 0], [0.82, 0], [0.82, 1.0], [-1.0, 1.0]],
		"turrets": [],
		"feat": [["boiler", -0.62, 0.72, 1.0, 13.0], ["cab", -0.85, 1.0], ["stack", 0.6, 26.0], ["steam_dome", 0.05], ["prow", 0.82],
			["flywheel", -0.25, 0.4, 10.0, 0.5], ["bands_boiler", -0.55, 0.65, 4], ["hatch_head_cab", -0.8, 1.0]]},
	"twin_cannon_ironclad": {"L": 86, "H": 14, "gear": ["tracks", -1.0, 0.85, 15.0, "small"], "base": 12.0,
		"profile": [[-0.98, 0], [0.85, 0], [1.14, 0.8], [1.02, 1.0], [-0.95, 1.0], [-1.06, 0.6]],
		"turrets": [[0.05, 1.0, "flat", 30]],
		"feat": [["sponson_box", -0.5, 0.55], ["railing", -0.95, 0.85, 1.0], ["portholes", -0.8, 0.6, 0.55, 4, 0], ["anchor", 1.0, 0.5],
			["mast", -0.75, 1.0, 26.0, false], ["rivets", -0.9, 0.95, 0.3]]},
	"sniper_tank_hunter": {"L": 84, "H": 12, "gear": ["tracks", -1.0, 0.9, 13.0, "small"], "base": 10.0,
		"profile": [[-1.0, 0], [0.9, 0], [1.03, 0.4], [0.4, 1.0], [-0.85, 1.0], [-1.0, 0.6]],
		"turrets": [[0.72, 0.68, "casemate", 22]],
		"feat": [["mantlet_plate", 0.72, 0.68], ["camo", -0.8, 0.35, 1.0], ["scope", -0.05, 1.0], ["hatch_head", -0.45, 1.0], ["rivets", -0.85, 0.8, 0.35]]},
	"steamtread_heavy_carrier": {"L": 92, "H": 30, "gear": ["rhomboid", 15.0], "base": 6.0,
		"profile": [[-0.92, 0], [0.92, 0], [0.92, 0.78], [0.72, 0.96], [0.0, 1.05], [-0.72, 0.96], [-0.92, 0.78]],
		"turrets": [[0.45, 1.0, "round", 15]],
		"feat": [["rhomboid_frame", 15.0], ["portholes", -0.7, 0.6, 0.72, 5, 3], ["ramp", -0.92], ["barrels", -0.55, 1.02, 3], ["chimney", -0.15, 1.04, 10.0, 4.0, false]]},
	"siegecrawler": {"L": 104, "H": 20, "gear": ["bogies", 2, 17.0], "base": 13.0,
		"profile": [[-1.0, 0], [1.0, 0], [1.05, 0.5], [0.88, 0.95], [0.35, 0.95], [0.3, 0.7], [0.18, 0.7], [0.14, 1.25], [-0.95, 1.25], [-1.02, 0.6]],
		"turrets": [[-0.42, 1.25, "tub", 30]],
		"feat": [["windows", 0.45, 0.82, 0.65, 2], ["chimney", -0.88, 1.25, 14.0, 5.0, true], ["chimney", -0.74, 1.25, 11.0, 5.0, true],
			["ladder", 0.1, 0.05, 1.2], ["crates", 0.48, 0.95, 2], ["rivets", -0.9, 0.95, 0.35], ["headlamp", 1.02, 0.45], ["hazard", 0.2, 0.9, 0.12]]},
	"mountainshield_heavy_tank": {"L": 92, "H": 26, "gear": ["tracks", -1.0, 0.92, 18.0, "med"], "base": 13.0, "skirt": true,
		"profile": [[-1.0, 0], [0.88, 0], [0.95, 0.5], [0.7, 1.0], [-0.85, 1.0], [-1.0, 0.6]],
		"turrets": [[-0.12, 1.0, "box", 28]],
		"feat": [["sponson", 0.35, 0.45, 1], ["shield", 0.86, 1.7], ["plates", -0.75, -0.2, 0.25, 3], ["rivets", -0.9, 0.6, 0.85],
			["chimney", -0.88, 1.0, 10.0, 4.5, false], ["antenna", -0.4, 1.0, 18.0, false]]},
	"thunderrail_tank_destroyer": {"L": 92, "H": 12, "gear": ["tracks", -1.0, 0.92, 14.0, "small"], "base": 11.0,
		"profile": [[-1.0, 0], [0.92, 0], [1.06, 0.5], [0.85, 1.0], [-0.9, 1.0], [-1.03, 0.5]],
		"turrets": [[-0.12, 1.0, "flat", 26]],
		"feat": [["capacitors", -0.9, -0.48, 1.0, 3], ["cables", -0.45, -0.25, 1.0], ["runes", -0.85, 0.85, 0.45], ["rivets", -0.9, 0.9, 0.82]]},
	"firestorm_assault_tank": {"L": 90, "H": 24, "gear": ["tracks", -1.0, 1.0, 17.0, "med"], "base": 13.0, "skirt": true,
		"profile": [[-1.0, 0], [0.95, 0], [1.04, 0.45], [0.9, 1.0], [-0.92, 1.0], [-1.03, 0.45]],
		"turrets": [[0.45, 1.0, "ball", 21], [-0.52, 1.0, "ball", 19]],
		"feat": [["radiator", -0.2, 0.18, 1.0, 5], ["tanks_v", -0.98, 1.0, 2], ["fins", -0.85, 0.75, 0.55, 6], ["manifold", -0.95, 0.4], ["scorch", 0.85, 0.6], ["hazard", -0.9, 0.9, 0.1]]},
	"dreadplate_breaker": {"L": 96, "H": 16, "gear": ["tracks", -1.0, 0.78, 17.0, "med"], "base": 13.0,
		"profile": [[-1.0, 0], [0.75, 0], [0.95, 0.45], [0.7, 1.0], [-0.85, 1.0], [-1.0, 0.55]],
		"turrets": [[-0.25, 1.0, "box", 26]],
		"feat": [["scales", -0.9, 0.7], ["drill", 0.92, 0.42, 0.62], ["chimney", -0.85, 1.0, 10.0, 4.5, false]]},
	"mobile_flak_fortress": {"L": 96, "H": 20, "gear": ["tracks", -1.0, 1.0, 18.0, "med"], "base": 13.0, "skirt": true,
		"profile": [[-1.0, 0], [0.95, 0], [1.03, 0.5], [0.85, 1.0], [0.6, 1.0], [0.6, 1.8], [-0.52, 1.8], [-0.52, 1.0], [-0.95, 1.0], [-1.03, 0.5]],
		"turrets": [[0.02, 1.8, "tub", 22], [-0.78, 1.0, "tub", 19]],
		"feat": [["ladder", -0.48, 1.0, 1.8], ["searchlight", 0.58, 1.6], ["rangefinder", 0.35, 1.8], ["windows", -0.3, 0.45, 1.35, 3],
			["crenels", -0.52, 0.6, 1.8, 0, 0.0], ["rivets", -0.9, 0.9, 0.55]]},
	"mountainbreaker": {"L": 118, "H": 22, "gear": ["tracks", -1.0, 1.0, 20.0, "small"], "base": 15.0, "skirt": true,
		"profile": [[-1.0, 0], [0.95, 0], [1.04, 0.4], [0.8, 0.55], [0.6, 0.55], [0.5, 0.8], [0.25, 0.8], [0.15, 1.05], [-0.6, 1.05], [-0.7, 0.8], [-0.95, 0.8], [-1.02, 0.4]],
		"turrets": [[-0.22, 1.05, "flat", 34]],
		"feat": [["emblem", -0.75, 0.42, "peak", 8.0], ["crates", 0.68, 0.55, 2], ["crates", -0.85, 0.8, 1], ["barrels", 0.38, 0.8, 2],
			["plates", 0.1, 0.55, 0.3, 2], ["rivets", -0.9, 0.9, 0.25], ["chimney", -0.9, 0.8, 12.0, 5.0, false], ["antenna", -0.5, 1.05, 20.0, false]]},
	"worldhammer_siege_tank": {"L": 108, "H": 30, "gear": ["tracks", -1.0, 0.72, 19.0, "med"], "base": 14.0,
		"profile": [[-1.0, 0], [0.72, 0], [0.72, 0.45], [1.0, 0.52], [1.12, 0.72], [0.62, 0.8], [0.62, 1.0], [-0.9, 1.0], [-1.0, 0.6]],
		"turrets": [[-0.08, 1.0, "hammer", 0]],
		"feat": [["flywheel", -0.62, 0.48, 12.0, 0.35], ["firebox", 0.25, 0.45], ["chimney", -0.88, 1.0, 24.0, 7.0, true], ["stone", -0.9, 0.55],
			["rivets", -0.9, 0.55, 0.9]]},
	"brass_leviathan": {"L": 128, "H": 28, "gear": ["bogies", 2, 18.0], "base": 14.0,
		"profile": [[-1.0, 0], [0.9, 0], [1.1, 0.8], [1.13, 1.0], [-1.0, 1.0], [-1.06, 0.7]],
		"turrets": [[0.58, 1.0, "box", 30], [-0.62, 1.0, "round", 24]],
		"feat": [["deckhouse", 0.05, 1.0, 0.36, 0.55], ["funnels", -0.22, 1.0, 2, 30.0], ["portholes", -0.85, 0.85, 0.55, 7, 0],
			["mast", 0.15, 1.55, 30.0, false], ["railing", -0.95, 1.0, 1.0], ["bands_hull", -0.9, 0.95], ["anchor", 1.02, 0.6]]},
	"iron_bastion_prime": {"L": 118, "H": 26, "gear": ["bogies", 2, 18.0], "base": 14.0,
		"profile": [[-1.0, 0], [1.0, 0], [0.98, 0.75], [0.42, 0.75], [0.42, 1.65], [-0.45, 1.65], [-0.45, 0.75], [-0.98, 0.75]],
		"turrets": [[-0.02, 1.65, "flat", 30]],
		"feat": [["stone", -0.95, 0.95], ["crenels", 0.42, 0.98, 0.75, 4, 6.0], ["crenels", -0.98, -0.45, 0.75, 4, 6.0], ["crenels", -0.45, 0.42, 1.65, 0, 0.0],
			["gate", 0.68, 0.0, 0.2, 0.58], ["slits", -0.35, 0.35, 1.25, 3], ["banner", -0.9, 0.75, 26.0], ["banner", 0.9, 0.75, 22.0],
			["plates", -0.85, -0.55, 0.25, 2]]},
	"dreadnought_landship": {"L": 146, "H": 24, "gear": ["bogies", 3, 18.0], "base": 14.0,
		"profile": [[-1.0, 0], [0.9, 0], [1.08, 0.75], [1.1, 1.0], [-1.0, 1.0], [-1.05, 0.6]],
		"turrets": [[0.6, 1.0, "box", 30], [-0.58, 1.0, "box", 28], [-0.9, 1.0, "tub", 16]],
		"feat": [["bridge", 0.18, 1.0, 0.2, 1.15], ["funnels", -0.22, 1.0, 2, 26.0], ["portholes", -0.85, 0.85, 0.55, 9, 2],
			["railing", -0.98, 1.05, 1.0], ["bands_hull", -0.9, 0.95], ["anchor", 1.0, 0.6]]},
	"gravegun_tank": {"L": 74, "H": 16, "gear": ["tracks", -1.0, 0.95, 17.0, "med"], "base": 13.0, "skirt": true, "wreck": true,
		"profile": [[-1.0, 0], [0.92, 0], [1.04, 0.5], [0.78, 0.92], [0.5, 1.0], [0.3, 0.86], [0.05, 1.0], [-0.55, 1.0], [-0.7, 0.82], [-0.92, 0.95], [-1.03, 0.5]],
		"turrets": [[0.0, 0.98, "box", 24]],
		"feat": [["holes", -0.7, 0.6, 3], ["moss", -0.9, 0.9, 1.0], ["chimney", -0.82, 0.95, 8.0, 4.5, false]]},
}


static func has(art: String) -> bool:
	return DESIGNS.has(art)


## Draws the design for `art`. `p` is the unit's data parameters (turret kinds, coat, glow, plates).
static func draw(ci: CanvasItem, a, art: String, p: Dictionary) -> void:
	var d: Dictionary = DESIGNS[art]
	var c = {}
	c.ci = ci
	c.t = float(P.g(a, "t", 0.0))
	c.walk = float(P.g(a, "walk", 0.0))
	c.moving = P.g(a, "state", "") == "move"
	c.atk = float(P.g(a, "atk", 0.0))
	c.atk2 = float(P.g(a, "atk2", 0.0))
	c.hp = float(P.g(a, "hp_frac", 1.0))
	c.L = float(d.L)
	c.hl = c.L * 0.5
	c.H = float(d.H)
	c.base = -float(d.base)
	c.coat = ArtKit.col(p, "coat", "5d6670")
	c.glow = ArtKit.col(p, "glow", "9ad8ff")
	c.wc = 3 if c.L >= 104.0 else (2 if c.L >= 84.0 else (1 if c.L >= 64.0 else 0))
	var gear: Array = d.gear
	# ---- running gear (rhomboid frames are drawn over the hull, below)
	_gear(c, gear)
	# ---- hull
	var prof = _prof(c, d.profile)
	_hull(c, prof, d.get("wreck", false))
	if d.get("skirt", false) and gear[0] == "tracks":
		_skirt(c, float(gear[1]), float(gear[2]), float(gear[3]))
	# ---- fittings
	for f in d.feat:
		_feat(c, f)
	# ---- turrets
	var kinds: Array = p.get("turrets", [])
	var aims = [P.g(a, "aim0", 0.0), P.g(a, "aim1", 0.0), P.g(a, "aim2", -0.8)]
	var atks = [c.atk, c.atk2, P.g(a, "atk3", 0.0)]
	var tdefs: Array = d.turrets
	for i in mini(kinds.size(), tdefs.size()):
		var td: Array = tdefs[i]
		var at = _pt(c, td[0], td[1]) + Vector2(0, 1)
		var kind = String(kinds[i])
		var shape = String(td[2])
		if shape == "pintle":
			_pintle(c, a, at, kind, aims[i], atks[i], float(td[3]))
		elif shape == "hammer" or kind == "hammer":
			ArtKit._turret(ci, at, "hammer", aims[i], atks[i], c.coat, c.glow, c.t, 100.0)
		else:
			ArtKit._turret2(ci, a, at, kind, aims[i], atks[i], c.coat, c.glow, c.t, c.L, i == 0 and not d.get("wreck", false), c.wc, shape, float(td[3]))
	# ---- life: thrown dirt, damage
	if c.moving:
		var dk = fposmod(c.walk, 1.0)
		for i in 3:
			ci.draw_circle(Vector2(-c.hl - 4.0 - dk * 8.0 - i * 4.0, -4.0 - dk * 6.0 - i * 2.0), 2.5 + dk * 2.5, Color(0.5, 0.42, 0.32, 0.45 * (1.0 - dk)))
	_damage(c)


# ------------------------------------------------------------------ geometry helpers
static func _pt(c: Dictionary, xf, yf) -> Vector2:
	return Vector2(float(xf) * c.hl, c.base - float(yf) * c.H)


static func _prof(c: Dictionary, prof: Array) -> PackedVector2Array:
	var out = PackedVector2Array()
	for q in prof:
		out.append(_pt(c, q[0], q[1]))
	return out


## Hull with generic form shading: upward-facing edges get a lit rim, downward-facing parts a shadow band
## (computed by clipping the profile against shifted copies of itself, so any silhouette is shaded right).
static func _hull(c: Dictionary, prof: PackedVector2Array, wreck: bool) -> void:
	var ci: CanvasItem = c.ci
	var coat: Color = c.coat
	ci.draw_colored_polygon(prof, coat)
	var down = PackedVector2Array()
	var up = PackedVector2Array()
	var sh = maxf(4.0, c.H * 0.22)
	for q in prof:
		down.append(q + Vector2(0, 3.0))
		up.append(q + Vector2(0, -sh))
	for part in Geometry2D.clip_polygons(prof, down):
		if part.size() >= 3:
			ci.draw_colored_polygon(part, coat.lightened(0.26))
	for part in Geometry2D.clip_polygons(prof, up):
		if part.size() >= 3:
			ci.draw_colored_polygon(part, coat.darkened(0.24))
	# panel seams clipped to the hull
	var x0 = prof[0].x
	var x1 = prof[0].x
	var ytop = prof[0].y
	for q in prof:
		x0 = minf(x0, q.x)
		x1 = maxf(x1, q.x)
		ytop = minf(ytop, q.y)
	var n = int((x1 - x0) / 22.0)
	var seams = PackedVector2Array()
	for k in n:
		var sx = lerpf(x0, x1, float(k + 1) / float(n + 1))
		for seg in Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([Vector2(sx, ytop - 2.0), Vector2(sx, c.base + 2.0)]), prof):
			if seg.size() >= 2:
				seams.append_array([seg[0] + Vector2(0, 2.5), seg[seg.size() - 1] - Vector2(0, 2.5)])
	if not seams.is_empty():
		ci.draw_multiline(seams, coat.darkened(0.38), 1.2)
	var outl = prof.duplicate()
	outl.append(prof[0])
	ci.draw_polyline(outl, P.OUT, 2.5)
	if wreck:
		# torn plate edges along the top
		var tears = PackedVector2Array()
		for k in 5:
			var tx = lerpf(x0 + 8.0, x1 - 12.0, k / 4.0)
			tears.append_array([Vector2(tx, ytop + 4.0), Vector2(tx + 4.0, ytop + 9.0), Vector2(tx + 4.0, ytop + 9.0), Vector2(tx + 1.0, ytop + 13.0)])
		ci.draw_multiline(tears, P.OUT, 1.5)


# ------------------------------------------------------------------ running gear
static func _gear(c: Dictionary, g: Array) -> void:
	var ci: CanvasItem = c.ci
	match String(g[0]):
		"wheels":
			var frame = PackedVector2Array()
			for w in g[1]:
				var wc = Vector2(float(w[0]) * c.hl, -float(w[1]))
				frame.append(wc)
			ci.draw_polyline(frame, P.IRON_D, 3.0)
			for w in g[1]:
				_spoked(c, Vector2(float(w[0]) * c.hl, -float(w[1])), float(w[1]))
		"trike":
			var rear = Vector2(float(g[1]) * c.hl, -float(g[2]))
			var front = Vector2(float(g[3]) * c.hl, -float(g[4]))
			ci.draw_line(rear, front + Vector2(0, -3.0), P.IRON_D, 3.0)
			ci.draw_line(front, front + Vector2(-3.0, -12.0), P.IRON_D, 2.5)   # steering fork
			_spoked(c, rear, float(g[2]))
			_spoked(c, front, float(g[4]))
		"tracks":
			_track(c, float(g[1]) * c.hl, float(g[2]) * c.hl, float(g[3]), String(g[4]))
		"halftrack":
			_track(c, float(g[3]) * c.hl, float(g[4]) * c.hl, float(g[5]), "med")
			var wcn = Vector2(float(g[1]) * c.hl, -float(g[2]))
			ci.draw_line(wcn + Vector2(-8.0, -6.0), wcn + Vector2(8.0, -6.0), P.IRON_D, 3.0)   # leaf spring
			_spoked(c, wcn, float(g[2]))
		"rhomboid":
			pass
		"bogies":
			var n = int(g[1])
			var th = float(g[2])
			var span = c.L + 6.0
			var seg = span / n
			for k in n:
				var sx0 = -c.hl - 3.0 + k * seg + 2.0
				_track(c, sx0, sx0 + seg - 4.0, th, "med")
			for k in n - 1:
				var jx = -c.hl - 3.0 + (k + 1) * seg
				P.rrect(ci, Rect2(jx - 5.0, -th - 3.0, 10.0, th * 0.6), P.IRON_D, 1.5, 2.0)   # articulation joint
				ci.draw_circle(Vector2(jx, -th * 0.75), 2.5, P.BRASS)


static func _spoked(c: Dictionary, wc: Vector2, r: float) -> void:
	P.wheel(c.ci, wc, r, c.walk * 2.0 * 10.0 / r, P.COAL, P.BRASS, 6 if r > 7.0 else 4)
	c.ci.draw_circle(wc, r * 0.3, P.IRON_D)
	c.ci.draw_circle(wc, r * 0.15, P.BRASS)


## A track unit. Styles: "big" (four large road wheels, no return rollers), "med" (the M006b gear), "small"
## (many small wheels paired on bogie plates).
static func _track(c: Dictionary, x0: float, x1: float, th: float, style: String) -> void:
	var ci: CanvasItem = c.ci
	var walk: float = c.walk
	if style == "med":
		ArtKit._track_unit(ci, x0, x1, th, walk, int(c.wc))
		return
	var len = x1 - x0
	P.rrect(ci, Rect2(x0, -th, len, th), P.COAL, 2.0, th * 0.5)
	var ph = fposmod(walk * 3.0, 6.0)
	var links = PackedVector2Array()
	for i in int(len / 6.0):
		var tx = x0 + fposmod(i * 6.0 - ph, len)
		var bx = x0 + fposmod(i * 6.0 + ph, len)
		if tx > x0 + th * 0.3 and tx < x1 - th * 0.3:
			links.append_array([Vector2(tx, -th - 0.5), Vector2(tx, -th + 2.5)])
		if bx > x0 + th * 0.3 and bx < x1 - th * 0.3:
			links.append_array([Vector2(bx, -2.5), Vector2(bx, 0.5)])
	ci.draw_multiline(links, P.IRON_D, 2.0)
	var spr = Vector2(x0 + th * 0.5, -th * 0.5)
	var teeth = PackedVector2Array()
	for k in 6:
		var dd = Vector2.from_angle(walk * 2.0 + k * TAU / 6.0)
		teeth.append_array([spr + dd * th * 0.2, spr + dd * th * 0.45])
	P.circ(ci, spr, th * 0.38, P.IRON, 1.5)
	ci.draw_multiline(teeth, P.IRON_D, 2.0)
	P.circ(ci, Vector2(x1 - th * 0.5, -th * 0.5), th * 0.34, P.IRON, 1.5)
	var hubs = PackedVector2Array()
	if style == "big":
		var r = th * 0.42
		for i in 4:
			var wx = lerpf(x0 + th * 1.0, x1 - th * 1.0, float(i) / 3.0)
			var wcn = Vector2(wx, -th * 0.46)
			P.circ(ci, wcn, r, P.IRON, 1.5)
			ci.draw_circle(wcn, r * 0.55, P.IRON_D)
			var hd = Vector2.from_angle(walk * 1.6 + i) * r * 0.5
			hubs.append_array([wcn - hd, wcn + hd, wcn - hd.orthogonal(), wcn + hd.orthogonal()])
	else:
		var np = maxi(2, int((len - th * 2.0) / 18.0))
		for i in np:
			var bx2 = lerpf(x0 + th * 1.2, x1 - th * 1.2, float(i) / float(maxi(1, np - 1)))
			P.rrect(ci, Rect2(bx2 - 7.0, -th * 0.62, 14.0, th * 0.3), P.IRON_D, 1.0, 1.5)   # bogie plate
			for o in [-4.5, 4.5]:
				var wcn2 = Vector2(bx2 + o, -th * 0.3)
				P.circ(ci, wcn2, th * 0.2, P.IRON, 1.0)
				var hd2 = Vector2.from_angle(walk * 2.6 + o) * th * 0.12
				hubs.append_array([wcn2 - hd2, wcn2 + hd2])
	ci.draw_multiline(hubs, P.BRASS.darkened(0.25), 1.5)


static func _skirt(c: Dictionary, xf0: float, xf1: float, th: float) -> void:
	var ci: CanvasItem = c.ci
	var x0 = xf0 * c.hl + th * 0.5
	var x1 = xf1 * c.hl - th * 0.3
	var y0 = -th - 1.0
	var sk = P.pts([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1 - 3.0, y0 + th * 0.5), Vector2(x0 + 3.0, y0 + th * 0.5)])
	P.poly(ci, sk, c.coat.darkened(0.14), 2.0)
	var sl = PackedVector2Array()
	var ns = 3 + int(c.wc)
	for k in ns:
		var x = lerpf(x0, x1, float(k + 1) / float(ns + 1))
		sl.append_array([Vector2(x, y0 + 1.0), Vector2(x, y0 + th * 0.48)])
	ci.draw_multiline(sl, c.coat.darkened(0.4), 1.2)
	P.rivets(ci, Vector2(x0 + 3.0, y0 + 3.0), Vector2(x1 - 3.0, y0 + 3.0), 4 + int(c.wc) * 2)


# ------------------------------------------------------------------ turret extras
## Pintle mount: a post with a machine gun and an exposed gunner behind it.
static func _pintle(c: Dictionary, a, at: Vector2, kind: String, aim: float, atk: float, tw: float) -> void:
	var ci: CanvasItem = c.ci
	var top = at + Vector2(0, -tw * 0.7)
	ci.draw_line(at, top, P.IRON_D, 3.0)
	_head(c, top + Vector2(-7.0, 2.0), P.CLOTH_RED.darkened(0.1), "goggles")
	ArtKit._turret2(ci, a, top, kind, aim, atk, c.coat, c.glow, c.t, c.L, false, 0, "casemate", tw)
	P.rect(ci, Rect2(top.x - 5.0, top.y - 4.0, 6.0, 5.0), P.IRON, 1.0)   # gun shield


## A crew head: helmet or cap, beard, optional goggles.
static func _head(c: Dictionary, hc: Vector2, beard: Color, hat: String = "helm") -> void:
	var ci: CanvasItem = c.ci
	ci.draw_circle(hc, 3.8, P.OUT)
	ci.draw_circle(hc, 3.0, P.SKIN)
	P.poly(ci, P.pts([hc + Vector2(-2.5, 0.5), hc + Vector2(3.5, 0.5), hc + Vector2(1.5, 6.0), hc + Vector2(-1.0, 5.0)]), beard, 0.8)
	if hat == "goggles":
		P.poly(ci, P.pts([hc + Vector2(-3.5, -0.8), hc + Vector2(0, -4.2), hc + Vector2(3.5, -0.8)]), P.LEATHER, 0.8)
		ci.draw_circle(hc + Vector2(2.2, -1.2), 1.4, Color(0.6, 0.85, 1.0))
	else:
		P.poly(ci, P.pts([hc + Vector2(-3.6, -0.5), hc + Vector2(-3.0, -3.2), hc + Vector2(0, -4.4), hc + Vector2(3.0, -3.2), hc + Vector2(3.6, -0.5)]), P.IRON, 0.8)
		ci.draw_line(hc + Vector2(0.5, -1.0), hc + Vector2(3.2, -1.0), P.BRASS, 1.5)


# ------------------------------------------------------------------ fittings
static func _feat(c: Dictionary, f: Array) -> void:
	var ci: CanvasItem = c.ci
	var coat: Color = c.coat
	var t: float = c.t
	match String(f[0]):
		"chimney":
			var b = _pt(c, f[1], f[2])
			var h = float(f[3])
			var w = float(f[4])
			P.rect(ci, Rect2(b.x - w * 0.5, b.y - h, w, h), P.IRON_D, 1.5)
			ci.draw_line(Vector2(b.x - w * 0.5, b.y - h * 0.4), Vector2(b.x + w * 0.5, b.y - h * 0.4), P.BRASS, 2.0)
			if bool(f[5]):
				P.poly(ci, P.pts([Vector2(b.x - w * 0.5, b.y - h), Vector2(b.x + w * 0.5, b.y - h), Vector2(b.x + w, b.y - h - 4.0), Vector2(b.x - w, b.y - h - 4.0)]), P.BRASS_D, 1.2)
			else:
				ci.draw_line(Vector2(b.x - w * 0.7, b.y - h), Vector2(b.x + w * 0.7, b.y - h), P.COAL, 3.0)
			var dark = c.moving or c.atk > 0.3
			P.smoke_puff(ci, Vector2(b.x, b.y - h - 4.0), t + b.x * 0.01, 3 if dark else 2, Color(0.3, 0.28, 0.28, 0.6) if dark else Color(0.55, 0.53, 0.52, 0.5))
		"stack":
			# locomotive smokestack rising from the front of the boiler, flared brass crown
			var bx = float(f[1]) * c.hl
			var by = c.base - c.H - 11.0
			var top = c.base - c.H - 24.0 - float(f[2]) * 0.6
			P.poly(ci, P.pts([Vector2(bx - 4.0, by), Vector2(bx + 4.0, by), Vector2(bx + 4.5, top + 6.0), Vector2(bx + 8.0, top), Vector2(bx - 8.0, top), Vector2(bx - 4.5, top + 6.0)]), P.IRON_D, 1.5)
			ci.draw_line(Vector2(bx - 8.0, top), Vector2(bx + 8.0, top), P.BRASS, 2.5)
			P.smoke_puff(ci, Vector2(bx, top - 3.0), t, 4 if c.moving else 3, Color(0.25, 0.23, 0.23, 0.65))
		"boiler":
			# horizontal locomotive boiler lying on the frame, with a dark smokebox and its door
			var x0 = float(f[1]) * c.hl
			var x1 = float(f[2]) * c.hl
			var r = float(f[4])
			var cy = c.base - c.H - r + 2.0
			P.rrect(ci, Rect2(x0, cy - r, x1 - x0, r * 2.0), coat, 2.5, r * 0.6)
			ci.draw_colored_polygon(P.pts([Vector2(x0 + 4.0, cy - r + 2.5), Vector2(x1 - 4.0, cy - r + 2.5), Vector2(x1 - 4.0, cy - r * 0.45), Vector2(x0 + 4.0, cy - r * 0.45)]), coat.lightened(0.25))
			ci.draw_colored_polygon(P.pts([Vector2(x0 + 4.0, cy + r * 0.5), Vector2(x1 - 4.0, cy + r * 0.5), Vector2(x1 - 4.0, cy + r - 2.0), Vector2(x0 + 4.0, cy + r - 2.0)]), coat.darkened(0.25))
			P.rrect(ci, Rect2(x1 - 2.0, cy - r + 1.0, 12.0, r * 2.0 - 2.0), P.COAL, 2.0, r * 0.5)   # smokebox
			P.circ(ci, Vector2(x1 + 8.0, cy), r * 0.62, P.IRON_D, 1.5)
			ci.draw_line(Vector2(x1 + 8.0, cy - r * 0.5), Vector2(x1 + 8.0, cy + r * 0.5), P.BRASS, 1.5)
			P.circ(ci, Vector2(x1 + 8.0, cy), 2.0, P.BRASS, 1.0)
		"bands_boiler":
			var by = c.base - c.H - 13.0 + 2.0
			var bl = PackedVector2Array()
			for k in int(f[3]):
				var x = lerpf(float(f[1]) * c.hl, float(f[2]) * c.hl, (k + 0.5) / float(f[3]))
				bl.append_array([Vector2(x, by - 12.0), Vector2(x, by + 12.0)])
			ci.draw_multiline(bl, P.BRASS, 2.5)
		"steam_dome":
			var dc = Vector2(float(f[1]) * c.hl, c.base - c.H - 24.0)
			P.poly(ci, P.ell_pts(dc, 7.0, 7.0, 0.0, 10, PI, TAU), P.BRASS, 1.5)
			ci.draw_line(dc + Vector2(-7, 0), dc + Vector2(7, 0), P.BRASS_D, 2.0)
			ci.draw_line(dc + Vector2(2, -7), dc + Vector2(2, -11), P.IRON_D, 2.0)   # whistle
			if c.moving:
				ci.draw_circle(dc + Vector2(0, -15.0 - fposmod(t, 0.96) * 6.0), 3.0 + fposmod(t, 0.96) * 4.0, Color(0.95, 0.95, 0.95, 0.5))
		"cab":
			var cb = _pt(c, f[1], f[2])
			if c.L > 70.0:
				# locomotive cab (boiler ram): roofed box behind the boiler
				P.rect(ci, Rect2(cb.x - 4.0, cb.y - 30.0, 20.0, 30.0), coat.darkened(0.1), 2.0)
				P.rect(ci, Rect2(cb.x - 7.0, cb.y - 33.0, 26.0, 4.0), P.IRON_D, 1.5)
				ci.draw_colored_polygon(P.pts([Vector2(cb.x + 4.0, cb.y - 25.0), Vector2(cb.x + 13.0, cb.y - 25.0), Vector2(cb.x + 13.0, cb.y - 16.0), Vector2(cb.x + 4.0, cb.y - 16.0)]), Color(1.0, 0.75, 0.35, 0.85))
			else:
				# a small driver's cab with a windscreen (halftrack)
				P.poly(ci, P.pts([cb + Vector2(-8, 0), cb + Vector2(10, 0), cb + Vector2(6, -11), cb + Vector2(-6, -11)]), coat.darkened(0.06), 1.8)
				ci.draw_colored_polygon(P.pts([cb + Vector2(1, -2), cb + Vector2(8, -2), cb + Vector2(5.5, -9), cb + Vector2(1, -9)]), Color(0.6, 0.8, 0.9, 0.6))
				_head(c, cb + Vector2(-2.0, -8.0), P.WOOD_D, "goggles")
		"hatch_head_cab":
			var hb = _pt(c, f[1], f[2])
			_head(c, hb + Vector2(10.0, -21.0), P.CLOTH_RED.darkened(0.15), "goggles")
		"prow":
			var px = float(f[1]) * c.hl + 18.0
			var yb = c.base + 2.0
			var yt = c.base - c.H - 22.0
			P.poly(ci, P.pts([Vector2(px - 6.0, yt), Vector2(px + 4.0, yt + 4.0), Vector2(px + 20.0, (yt + yb) * 0.5), Vector2(px + 4.0, yb), Vector2(px - 6.0, yb)]), P.STEEL, 2.0)
			ci.draw_line(Vector2(px - 4.0, yt + 2.0), Vector2(px + 18.0, (yt + yb) * 0.5), Color(1, 1, 1, 0.45), 1.5)
			for k in 3:
				var sp = Vector2(px + 6.0 + k * 3.0, lerpf(yt + 6.0, yb - 6.0, k / 2.0))
				P.poly(ci, P.pts([sp + Vector2(0, -2.5), sp + Vector2(9.0, 0), sp + Vector2(0, 2.5)]), P.IRON, 1.0)
		"flywheel":
			var fc = _pt(c, f[1], f[2])
			var r = float(f[3])
			var ang = c.walk * 1.5 + (t * 2.0 if not c.moving else 0.0)
			P.circ(ci, fc, r, P.IRON_D, 2.0)
			ci.draw_arc(fc, r - 2.0, 0, TAU, 16, P.BRASS_D, 1.5)
			var sp2 = PackedVector2Array()
			for k in 4:
				var dd = Vector2.from_angle(ang + k * PI * 0.5)
				sp2.append_array([fc, fc + dd * (r - 2.0)])
			ci.draw_multiline(sp2, P.IRON, 2.0)
			# connecting rod to a piston cylinder ahead
			var crank = fc + Vector2.from_angle(ang) * r * 0.6
			var cyl = fc + Vector2(float(f[4]) * c.hl, 0)
			P.rrect(ci, Rect2(cyl.x - 4.0, cyl.y - 4.0, 14.0, 8.0), P.BRASS_D, 1.2, 2.0)
			ci.draw_line(crank, cyl, P.OUT, 4.0)
			ci.draw_line(crank, cyl, P.STEEL, 2.2)
			P.circ(ci, crank, 2.2, P.BRASS, 1.0)
		"coal":
			var cc = _pt(c, f[1], f[2])
			P.poly(ci, P.pts([cc + Vector2(-9, 0), cc + Vector2(-6, -5), cc + Vector2(-1, -7), cc + Vector2(5, -4), cc + Vector2(9, 0)]), P.COAL, 1.2)
			for k in 3:
				ci.draw_circle(cc + Vector2(-5 + k * 5, -4.0), 1.3, Color(0.35, 0.33, 0.33))
		"driver":
			_head(c, _pt(c, f[1], f[2]) + Vector2(0, -5.0), P.WOOD_D, "goggles")
		"sack":
			var sc = _pt(c, f[1], f[2])
			P.poly(ci, P.pts([sc + Vector2(-4, 0), sc + Vector2(4, 0), sc + Vector2(3, -6), sc + Vector2(0, -8), sc + Vector2(-3, -6)]), Color("8a7a5a"), 1.0)
		"fender", "guards":
			var arr = [[f[1], f[2]]] if f[0] == "fender" else f[1]
			for w in arr:
				var wc2 = Vector2(float(w[0]) * c.hl, -float(w[1]))
				ci.draw_arc(wc2, float(w[1]) + 3.0, PI * 1.05, PI * 1.95, 10, P.OUT, 5.0)
				ci.draw_arc(wc2, float(w[1]) + 3.0, PI * 1.05, PI * 1.95, 10, coat.darkened(0.2), 3.0)
		"rivets":
			P.rivets(ci, _pt(c, f[1], f[3]), _pt(c, f[2], f[3]), int((float(f[2]) - float(f[1])) * c.hl / 9.0))
		"headlamp":
			var hp = _pt(c, f[1], f[2])
			P.circ(ci, hp, 3.0, P.BRASS, 1.2)
			ci.draw_circle(hp + Vector2(0.5, 0), 1.7, Color(1.0, 0.92, 0.6))
		"slit":
			var sp3 = _pt(c, f[1], f[2])
			ci.draw_line(sp3 + Vector2(-5, 0), sp3, P.COAL, 2.5)
		"antenna":
			var ab = _pt(c, f[1], f[2])
			var whip = sin(t * 7.0) * 0.06 + (0.18 if c.moving else 0.0) + c.atk * 0.25
			var tip = ab + Vector2.from_angle(-PI * 0.5 - 0.35 - whip) * float(f[3])
			ci.draw_line(ab, tip, P.COAL, 1.2)
			if bool(f[4]) or c.wc >= 2:
				var fl = sin(t * 9.0) * 2.0
				P.poly(ci, P.pts([tip, tip + Vector2(-9, 1 + fl), tip + Vector2(-8, 4 + fl), tip + Vector2(0, 5)]), P.CLOTH_RED, 0.8)
		"drum":
			var dc2 = _pt(c, f[1], f[2])
			var dw = float(f[3]) * c.hl
			var dh = float(f[4]) * c.H * 2.0
			P.rrect(ci, Rect2(dc2.x - dw, dc2.y - dh * 0.5, dw * 1.4, dh), P.COPPER, 1.8, dh * 0.45)
			ci.draw_line(dc2 + Vector2(-dw * 0.5, -dh * 0.5), dc2 + Vector2(-dw * 0.5, dh * 0.5), P.COPPER_D, 1.5)
			ci.draw_line(dc2 + Vector2(-dw * 0.9, -dh * 0.3), dc2 + Vector2(0, -dh * 0.3), Color(1, 1, 1, 0.35), 1.2)
		"door":
			var d0 = _pt(c, f[1], f[2])
			var dw2 = float(f[3]) * c.hl
			var dh2 = float(f[4]) * c.H
			var dpts = P.pts([d0, d0 + Vector2(dw2, 0), d0 + Vector2(dw2, -dh2 * 0.7)])
			for k in 7:
				var aa = PI * float(k) / 6.0
				dpts.append(d0 + Vector2(dw2 * 0.5 + cos(aa) * dw2 * 0.5, -dh2 * 0.7 - sin(aa) * dh2 * 0.3))
			dpts.append(d0 + Vector2(0, -dh2 * 0.7))
			P.poly(ci, dpts, coat.darkened(0.18), 1.5)
			ci.draw_circle(d0 + Vector2(dw2 * 0.8, -dh2 * 0.4), 1.5, P.BRASS)
		"ports":
			var pl = PackedVector2Array()
			var bar = PackedVector2Array()
			for k in int(f[4]):
				var pp = _pt(c, lerpf(float(f[1]), float(f[2]), (k + 0.5) / float(f[4])), f[3])
				pl.append_array([pp + Vector2(-3, 0), pp + Vector2(3, 0)])
				var poke = 6.0 + sin(t * 9.0 + k * 2.0) * 1.0 + c.atk * 2.0
				bar.append_array([pp + Vector2(1, 0), pp + Vector2(1 + poke, -0.6)])
			ci.draw_multiline(pl, P.COAL, 3.0)
			ci.draw_multiline(bar, P.IRON_D, 1.6)
		"hatch_head":
			var hh = _pt(c, f[1], f[2])
			P.rrect(ci, Rect2(hh.x - 5.0, hh.y - 2.5, 10.0, 3.5), coat.darkened(0.2), 1.2, 1.5)
			ci.draw_line(hh + Vector2(-5.0, -1.0), hh + Vector2(-9.0, -7.0), coat.darkened(0.3), 3.0)
			var duck = clampf(c.atk * 1.6 - 0.5, 0.0, 1.0)
			if duck < 0.9:
				_head(c, hh + Vector2(sin(t * 1.3), -5.0 + duck * 6.0), Color("c8c0b0"))
		"exhaust_pipe":
			var e0 = _pt(c, f[1], f[3])
			var e1 = _pt(c, f[2], f[3])
			ci.draw_line(e0, e1, P.OUT, 5.0)
			ci.draw_line(e0, e1, P.IRON, 3.0)
			P.rrect(ci, Rect2(e0.x + 6.0, e0.y - 3.5, 14.0, 7.0), P.IRON_D, 1.2, 3.0)   # muffler
			P.smoke_puff(ci, e0 + Vector2(-2.0, -1.0), t, 2 if not c.moving else 3, Color(0.4, 0.38, 0.37, 0.5))
		"shovel":
			var sb2 = _pt(c, f[1], f[2])
			ci.draw_line(sb2, sb2 + Vector2(22, -1), P.WOOD, 2.0)
			P.poly(ci, P.pts([sb2 + Vector2(22, -4), sb2 + Vector2(29, -1), sb2 + Vector2(22, 2)]), P.IRON, 1.0)
		"tanks_h":
			var tb = _pt(c, f[1], f[2])
			var tl = float(f[4]) * c.hl
			var tr = float(f[5])
			for k in int(f[3]):
				var tp = tb + Vector2(k * (tl + 2.0), -tr - 1.0)
				P.rrect(ci, Rect2(tp.x - tl * 0.5, tp.y - tr, tl, tr * 2.0), Color("8e7a2a"), 1.5, tr)
				_stripes(c, Rect2(tp.x - tl * 0.1, tp.y - tr, tl * 0.25, tr * 2.0))
				ci.draw_line(tp + Vector2(-tl * 0.4, -tr * 0.5), tp + Vector2(tl * 0.35, -tr * 0.5), Color(1, 1, 1, 0.35), 1.2)
		"tanks_v":
			var tv = _pt(c, f[1], f[2])
			for k in int(f[3]):
				var tx = tv.x - 6.0 + k * 11.0
				P.rrect(ci, Rect2(tx - 4.5, tv.y - 18.0, 9.0, 18.0), Color("8e7a2a"), 1.5, 4.0)
				_stripes(c, Rect2(tx - 4.5, tv.y - 11.0, 9.0, 5.0))
				ci.draw_line(Vector2(tx, tv.y - 18.0), Vector2(tx, tv.y - 21.0), P.COPPER, 2.0)
		"firebox":
			var fb = _pt(c, f[1], f[2])
			var fl2 = 0.65 + 0.35 * sin(t * 13.0)
			P.rrect(ci, Rect2(fb.x - 7.0, fb.y - 5.0, 14.0, 10.0), P.COAL, 1.5, 2.0)
			ci.draw_colored_polygon(P.pts([fb + Vector2(-5, -3), fb + Vector2(5, -3), fb + Vector2(5, 3), fb + Vector2(-5, 3)]), Color(1.0, 0.45 + 0.2 * fl2, 0.1, 0.9))
			var grate = PackedVector2Array()
			for k in 4:
				grate.append_array([fb + Vector2(-4 + k * 2.7, -3), fb + Vector2(-4 + k * 2.7, 3)])
			ci.draw_multiline(grate, P.COAL, 1.2)
		"bands":
			var bl2 = PackedVector2Array()
			for k in int(f[3]):
				var x = lerpf(float(f[1]), float(f[2]), (k + 0.5) / float(f[3])) * c.hl
				bl2.append_array([Vector2(x, c.base - 2.0), Vector2(x, c.base - c.H * 0.95)])
			ci.draw_multiline(bl2, P.BRASS_D, 2.5)
		"hazard":
			var h0 = _pt(c, f[1], f[3])
			var h1 = _pt(c, f[2], f[3])
			_stripes(c, Rect2(h0.x, h0.y - 2.5, h1.x - h0.x, 5.0))
		"spare_wheel":
			var sw = _pt(c, f[1], f[2]) + Vector2(0, -6.0)
			P.circ(ci, sw, 6.5, P.COAL, 1.5)
			ci.draw_circle(sw, 3.0, P.IRON_D)
			ci.draw_circle(sw, 1.5, P.BRASS)
		"sandbags":
			var s0 = _pt(c, f[1], f[3])
			var s1 = _pt(c, f[2], f[3])
			for k in 3:
				P.ell(ci, s0.lerp(s1, k / 2.0) + Vector2(0, -3.0), 5.0, 3.0, Color("9a8a62"), 1.2)
		"cab_dummy":
			pass
		"ammo_rack":
			var ar = _pt(c, f[1], f[2])
			P.rect(ci, Rect2(ar.x, ar.y - 8.0, 12.0, 8.0), P.WOOD, 1.5)
			var sh = PackedVector2Array()
			for k in 3:
				sh.append_array([ar + Vector2(2.5 + k * 3.5, -7.0), ar + Vector2(2.5 + k * 3.5, -11.0)])
			ci.draw_multiline(sh, P.BRASS, 2.5)
		"periscope":
			var ps = _pt(c, f[1], f[2])
			ci.draw_line(ps, ps + Vector2(0, -12), P.IRON_D, 2.5)
			P.rect(ci, Rect2(ps.x - 1.0, ps.y - 15.0, 6.0, 4.0), P.IRON, 1.0)
			ci.draw_line(ps + Vector2(4.5, -13.0), ps + Vector2(5.5, -13.0), Color(0.6, 0.85, 1.0), 2.0)
		"hump":
			# the Thunderback's turtle back: a great boiler dome over the rear deck
			var hc2 = _pt(c, f[1], f[2])
			var rx = float(f[3]) * c.hl
			var ry = float(f[4]) * c.H
			P.poly(ci, P.ell_pts(hc2, rx, ry, 0.0, 14, PI, TAU), coat.darkened(0.06), 2.2)
			ci.draw_colored_polygon(P.ell_pts(hc2 + Vector2(-rx * 0.08, -ry * 0.08), rx * 0.8, ry * 0.82, 0.0, 10, PI * 1.12, PI * 1.62), coat.lightened(0.24))
			var rib = PackedVector2Array()
			for k in 3:
				var ax = PI + PI * (k + 1) / 4.0
				rib.append_array([hc2 + Vector2(cos(ax) * rx * 0.98, sin(ax) * ry * 0.98), hc2 + Vector2(cos(ax) * rx * 0.25, 0)])
			ci.draw_multiline(rib, coat.darkened(0.35), 1.2)
			P.rivets(ci, hc2 + Vector2(-rx * 0.85, -2.0), hc2 + Vector2(rx * 0.85, -2.0), 8)
		"vents":
			var vb = _pt(c, f[1], f[2])
			for k in int(f[3]):
				var vp = vb + Vector2(k * 12.0, 0)
				P.rect(ci, Rect2(vp.x - 2.5, vp.y - 6.0, 5.0, 7.0), P.COPPER, 1.2)
				var ph = fposmod(t * 1.1 + k * 0.5, 1.0)
				ci.draw_circle(vp + Vector2(-ph * 6.0, -9.0 - ph * 10.0), 2.5 + ph * 5.0, Color(0.95, 0.95, 0.95, 0.55 * (1.0 - ph)))
		"gauge":
			var gp = _pt(c, f[1], f[2])
			P.circ(ci, gp, 4.0, P.BRASS, 1.2)
			ci.draw_circle(gp, 2.8, Color(0.95, 0.92, 0.82))
			ci.draw_line(gp, gp + Vector2.from_angle(-PI * 0.5 + (0.9 if c.moving else 0.2) + sin(t * 9.0) * 0.1) * 2.6, P.CLOTH_RED, 1.0)
		"emblem":
			_emblem(c, _pt(c, f[1], f[2]), String(f[3]), float(f[4]))
		"stone":
			# masonry coursing on fortress hulls
			var s0b = _pt(c, f[1], 0.0)
			var s1b = _pt(c, f[2], 0.0)
			var lines = PackedVector2Array()
			var rows = int(c.H / 7.0)
			for r in rows:
				var y = c.base - (r + 1) * c.H / float(rows + 1)
				lines.append_array([Vector2(s0b.x + 3.0, y), Vector2(s1b.x - 3.0, y)])
				var off = 6.0 if r % 2 == 0 else 0.0
				var x = s0b.x + off + 4.0
				while x < s1b.x - 6.0:
					lines.append_array([Vector2(x, y), Vector2(x, y + c.H / float(rows + 1) - 1.0)])
					x += 13.0
			ci.draw_multiline(lines, Color(0, 0, 0, 0.22), 1.0)
		"crenels":
			var cy0 = _pt(c, f[1], f[3])
			var cy1 = _pt(c, f[2], f[3])
			var n = int(f[4])
			var mh = float(f[5])
			if n <= 0:
				# keep / deck parapet: auto count
				n = maxi(3, int((cy1.x - cy0.x) / 11.0))
				mh = 5.0
			var mw = (cy1.x - cy0.x) / float(n * 2 - 1)
			for k in n:
				var mx = cy0.x + k * mw * 2.0
				P.rect(ci, Rect2(mx, cy0.y - mh, mw, mh + 1.0), coat, 1.5)
				ci.draw_line(Vector2(mx + 1.0, cy0.y - mh + 1.0), Vector2(mx + mw - 1.0, cy0.y - mh + 1.0), coat.lightened(0.3), 1.2)
		"slits":
			var sl = PackedVector2Array()
			for k in int(f[4]):
				var sp4 = _pt(c, lerpf(float(f[1]), float(f[2]), (k + 0.5) / float(f[4])), f[3])
				sl.append_array([sp4 + Vector2(0, -4.0), sp4 + Vector2(0, 4.0)])
			ci.draw_multiline(sl, P.COAL, 2.5)
		"gate":
			var g0 = _pt(c, f[1], f[2])
			var gw = float(f[3]) * c.hl
			var gh = float(f[4]) * c.H
			var gp2 = P.pts([g0, g0 + Vector2(gw, 0), g0 + Vector2(gw, -gh * 0.65)])
			for k in 7:
				var aa2 = PI * float(k) / 6.0
				gp2.append(g0 + Vector2(gw * 0.5 + cos(aa2) * gw * 0.5, -gh * 0.65 - sin(aa2) * gh * 0.35))
			gp2.append(g0 + Vector2(0, -gh * 0.65))
			P.poly(ci, gp2, Color(0.12, 0.1, 0.09), 2.0)
			var pc = PackedVector2Array()
			for k in 3:
				pc.append_array([g0 + Vector2(gw * (0.25 + k * 0.25), -1.0), g0 + Vector2(gw * (0.25 + k * 0.25), -gh * 0.85)])
			pc.append_array([g0 + Vector2(2, -gh * 0.3), g0 + Vector2(gw - 2, -gh * 0.3), g0 + Vector2(2, -gh * 0.6), g0 + Vector2(gw - 2, -gh * 0.6)])
			ci.draw_multiline(pc, P.IRON, 1.5)   # portcullis
		"banner":
			var bp = _pt(c, f[1], f[2])
			var bh = float(f[3])
			ci.draw_line(bp, bp + Vector2(0, -bh), P.WOOD_D, 2.0)
			ci.draw_circle(bp + Vector2(0, -bh), 1.8, P.BRASS)
			var wv = sin(t * TAU / 0.96 * 2.0) * 1.5
			var bpts = P.pts([bp + Vector2(0, -bh + 2), bp + Vector2(-10.0 + wv, -bh + 2), bp + Vector2(-10.0 + wv * 1.5, -bh + 14), bp + Vector2(-5.0 + wv, -bh + 11), bp + Vector2(0, -bh + 14)])
			P.poly(ci, bpts, P.CLOTH_RED, 1.0)
			_emblem(c, bp + Vector2(-5.0 + wv, -bh + 7.0), "anvil", 3.0)
		"plates":
			var y0 = _pt(c, 0.0, f[3]).y
			var w = (float(f[2]) - float(f[1])) * c.hl / float(f[4])
			for k in int(f[4]):
				var px = float(f[1]) * c.hl + k * w
				P.rect(ci, Rect2(px + 1.0, y0 - 4.0, w - 2.0, 9.0), coat.darkened(0.2), 1.5)
				P.rivets(ci, Vector2(px + 2.0, y0 - 2.0), Vector2(px + w - 2.0, y0 - 2.0), 2)
		"blade":
			var bx2 = float(f[1]) * c.hl
			var yb2 = -2.0
			var yt2 = c.base - c.H * 0.95
			ci.draw_line(Vector2(bx2 - 14.0, c.base - c.H * 0.35), Vector2(bx2 + 6.0, (yb2 + yt2) * 0.5), P.IRON_D, 4.0)   # push arm
			P.poly(ci, P.pts([Vector2(bx2 + 4.0, yt2), Vector2(bx2 + 10.0, yt2 - 2.0), Vector2(bx2 + 14.0, (yt2 + yb2) * 0.5), Vector2(bx2 + 12.0, yb2), Vector2(bx2 + 3.0, yb2)]), HAZARD_Y, 2.0)
			_stripes(c, Rect2(bx2 + 5.0, yt2 + 2.0, 7.0, 5.0))
			ci.draw_line(Vector2(bx2 + 3.0, yb2), Vector2(bx2 + 14.0, yb2), P.STEEL, 2.0)   # cutting edge
		"crane":
			var cb2 = _pt(c, f[1], f[2])
			var tip2 = cb2 + Vector2(-10.0, -30.0)
			ci.draw_line(cb2, tip2, P.OUT, 5.0)
			ci.draw_line(cb2, tip2, HAZARD_Y, 3.0)
			ci.draw_line(cb2 + Vector2(6, 0), tip2, P.IRON_D, 1.2)
			var sw2 = sin(t * TAU / 0.96) * 2.0
			ci.draw_line(tip2, tip2 + Vector2(sw2, 14.0), Color(0.25, 0.25, 0.25), 1.2)
			ci.draw_arc(tip2 + Vector2(sw2, 17.0), 3.0, -PI * 0.3, PI * 1.1, 6, P.IRON, 2.0)
		"charges":
			var ch = _pt(c, f[1], f[2])
			for k in int(f[3]):
				var cp = ch + Vector2(k * 6.0, 0)
				P.rrect(ci, Rect2(cp.x, cp.y - 9.0, 4.5, 9.0), P.CLOTH_RED, 1.0, 1.5)
				ci.draw_line(cp + Vector2(2.2, -9.0), cp + Vector2(3.5, -12.0), P.COAL, 1.0)
		"sponson_box":
			var sb3 = _pt(c, f[1], f[2])
			P.rrect(ci, Rect2(sb3.x - 9.0, sb3.y - 6.0, 18.0, 11.0), c.coat.darkened(0.12), 1.8, 3.0)
			P.bar(ci, sb3 + Vector2(8.0, -1.0), 0.0, 8.0, 2.4, P.IRON_D, 1.0)
		"sponson":
			var sb4 = _pt(c, f[1], f[2])
			P.poly(ci, P.pts([sb4 + Vector2(-10, -7), sb4 + Vector2(6, -7), sb4 + Vector2(10, 0), sb4 + Vector2(6, 7), sb4 + Vector2(-10, 7)]), c.coat.darkened(0.1), 1.8)
			var k2: float = c.atk2
			P.bar(ci, sb4 + Vector2(8.0 - k2 * 1.5, 0), 0.0, 10.0, 2.6, P.IRON_D, 1.0)
			P.muzzle_flash(ci, sb4 + Vector2(18.0, 0), 0.0, 6.0, D._flash_strength(k2))
		"shield":
			# the Mountainshield's tower-shield plate standing before the hull
			var sx = float(f[1]) * c.hl
			var top2 = c.base - float(f[2]) * c.H
			var bot = -3.0
			var w2 = c.hl * 0.21
			var spts = P.pts([Vector2(sx - w2, top2 + 4.0), Vector2(sx, top2), Vector2(sx + w2, top2 + 4.0), Vector2(sx + w2 + 2.0, bot), Vector2(sx - w2 + 2.0, bot)])
			P.poly(ci, spts, c.coat.darkened(0.08), 2.5)
			ci.draw_colored_polygon(P.pts([Vector2(sx - w2 + 2.0, top2 + 5.0), Vector2(sx, top2 + 2.0), Vector2(sx + w2 - 2.0, top2 + 5.0), Vector2(sx + w2 - 2.0, top2 + 9.0), Vector2(sx - w2 + 2.0, top2 + 9.0)]), c.coat.lightened(0.25))
			ci.draw_line(Vector2(sx + w2, top2 + 4.0), Vector2(sx + w2 + 2.0, bot), c.coat.lightened(0.3), 1.5)
			var mid = Vector2(sx + 1.0, (top2 + bot) * 0.5)
			ci.draw_arc(mid, w2 * 0.8, 0, TAU, 14, P.BRASS, 2.0)
			_emblem(c, mid, "anvil", w2 * 0.55)
			P.rivets(ci, Vector2(sx - w2 + 3.0, bot - 4.0), Vector2(sx + w2 - 1.0, bot - 4.0), 4)
		"capacitors":
			var c0 = _pt(c, f[1], f[3])
			var c1 = _pt(c, f[2], f[3])
			for k in int(f[4]):
				var cp2 = c0.lerp(c1, (k + 0.5) / float(f[4]))
				P.rect(ci, Rect2(cp2.x - 3.0, cp2.y - 4.0, 6.0, 4.0), P.COPPER_D, 1.0)
				var pul = 0.6 + 0.4 * sin(t * TAU / 0.96 * 2.0 + k * 2.0)
				ci.draw_circle(cp2 + Vector2(0, -9.0), 6.0, P.OUT)
				ci.draw_circle(cp2 + Vector2(0, -9.0), 5.0, Color(c.glow.r, c.glow.g, c.glow.b, 0.45 + 0.4 * pul))
				ci.draw_circle(cp2 + Vector2(-1.5, -10.5), 1.5, Color(1, 1, 1, 0.8))
			if c.atk > 0.3:
				ci.draw_polyline(PackedVector2Array([c0 + Vector2(0, -9), c0.lerp(c1, 0.3) + Vector2(0, -14), c0.lerp(c1, 0.55) + Vector2(0, -6), c1 + Vector2(0, -9)]), Color(c.glow.r, c.glow.g, c.glow.b, 0.9), 1.5)
		"cables":
			var k0 = _pt(c, f[1], f[3])
			var k1 = _pt(c, f[2], f[3])
			ci.draw_polyline(PackedVector2Array([k0 + Vector2(0, -2), k0.lerp(k1, 0.5) + Vector2(0, 1), k1 + Vector2(0, -3)]), P.COAL, 2.0)
		"runes":
			var r0 = _pt(c, f[1], f[3])
			var r1 = _pt(c, f[2], f[3])
			var rl = PackedVector2Array()
			var nr = int((r1.x - r0.x) / 9.0)
			for k in nr:
				var rp = r0 + Vector2(k * 9.0 + 3.0, 0)
				match k % 3:
					0: rl.append_array([rp + Vector2(0, -3), rp + Vector2(0, 3), rp + Vector2(0, -3), rp + Vector2(3, 0)])
					1: rl.append_array([rp + Vector2(-1, -3), rp + Vector2(2, 3), rp + Vector2(2, -3), rp + Vector2(-1, 3)])
					_: rl.append_array([rp + Vector2(0, 3), rp + Vector2(1.5, -3), rp + Vector2(1.5, -3), rp + Vector2(3, 3)])
			var pul2 = 0.55 + 0.45 * sin(t * TAU / 0.96)
			ci.draw_multiline(rl, Color(c.glow.r, c.glow.g, c.glow.b, 0.5 + 0.4 * pul2), 1.6)
		"fins":
			var fl3 = PackedVector2Array()
			for k in int(f[4]):
				var fp = _pt(c, lerpf(float(f[1]), float(f[2]), (k + 0.5) / float(f[4])), f[3])
				fl3.append_array([fp + Vector2(-3, 5), fp + Vector2(3, -5)])
			ci.draw_multiline(fl3, P.OUT, 4.0)
			ci.draw_multiline(fl3, coat.lightened(0.15), 2.0)
		"radiator":
			# tall heat-shield plates standing on the deck between the flame turrets
			var r0r = _pt(c, f[1], f[3])
			var r1r = _pt(c, f[2], f[3])
			for k in int(f[4]):
				var rx = lerpf(r0r.x, r1r.x, (k + 0.5) / float(f[4]))
				var rh = 14.0 + (k % 2) * 4.0
				P.poly(ci, P.pts([Vector2(rx - 2.5, r0r.y), Vector2(rx + 2.5, r0r.y), Vector2(rx + 1.5, r0r.y - rh), Vector2(rx - 2.5, r0r.y - rh + 2.0)]), coat.darkened(0.2), 1.5)
				ci.draw_line(Vector2(rx - 1.5, r0r.y - rh + 3.0), Vector2(rx - 1.5, r0r.y - 2.0), Color(1.0, 0.55, 0.2, 0.35 + 0.25 * sin(t * 8.0 + k)), 1.2)
		"manifold":
			var mp = _pt(c, f[1], f[2])
			for k in 3:
				ci.draw_line(mp + Vector2(4 + k * 6, 0), mp + Vector2(-2 + k * 6, -12), P.OUT, 4.0)
				ci.draw_line(mp + Vector2(4 + k * 6, 0), mp + Vector2(-2 + k * 6, -12), P.COPPER, 2.2)
			P.smoke_puff(ci, mp + Vector2(4, -14), t, 3, Color(0.3, 0.28, 0.27, 0.6))
		"scorch":
			var scp = _pt(c, f[1], f[2])
			ci.draw_circle(scp, 5.0, Color(0.08, 0.06, 0.05, 0.35))
			ci.draw_circle(scp + Vector2(-6, 4), 3.5, Color(0.08, 0.06, 0.05, 0.3))
		"scales":
			# overlapping scale plates, rows of arcs
			var sx0 = float(f[1]) * c.hl
			var sx1 = float(f[2]) * c.hl
			for r in 3:
				var y = c.base - c.H * (0.25 + r * 0.28)
				var off2 = 0.0 if r % 2 == 0 else 6.0
				var x = sx0 + off2
				while x < sx1 - 4.0:
					ci.draw_arc(Vector2(x + 6.0, y), 6.0, 0.15, PI - 0.15, 6, coat.darkened(0.38), 1.5)
					ci.draw_arc(Vector2(x + 6.0, y - 1.0), 5.0, PI * 0.2, PI * 0.8, 4, coat.lightened(0.25), 1.0)
					x += 12.0
		"drill":
			var dx = float(f[1]) * c.hl
			var dy = c.base - float(f[2]) * c.H
			var dl = float(f[3]) * c.hl
			var dr = c.H * 0.42
			P.rrect(ci, Rect2(dx - 6.0, dy - dr - 2.0, 10.0, dr * 2.0 + 4.0), P.IRON_D, 2.0, 2.0)   # drive housing
			P.poly(ci, P.pts([Vector2(dx + 2.0, dy - dr), Vector2(dx + dl, dy), Vector2(dx + 2.0, dy + dr)]), P.STEEL, 2.0)
			var spin = c.walk * 2.0 + c.atk * 3.0 + t * 6.0
			var sp5 = PackedVector2Array()
			for k in 5:
				var u = fposmod(k / 5.0 + spin / TAU, 1.0)
				var x0d = dx + 2.0 + u * dl * 0.85
				var hh2 = dr * (1.0 - u * 0.9)
				sp5.append_array([Vector2(x0d, dy - hh2), Vector2(x0d + 5.0, dy + hh2)])
			ci.draw_multiline(sp5, P.IRON_D, 2.0)
			ci.draw_line(Vector2(dx + 4.0, dy - dr * 0.6), Vector2(dx + dl * 0.7, dy - dr * 0.15), Color(1, 1, 1, 0.4), 1.5)
			if c.atk > 0.4:
				for k in 3:
					ci.draw_circle(Vector2(dx + dl + 2.0, dy) + Vector2.from_angle(-1.2 + k * 1.2) * (4.0 + c.atk * 6.0), 1.5, Color(1.0, 0.85, 0.4, c.atk))
		"ladder":
			var lx = float(f[1]) * c.hl
			var ly0 = c.base - float(f[2]) * c.H
			var ly1 = c.base - float(f[3]) * c.H
			var ll = PackedVector2Array([Vector2(lx - 2.5, ly0), Vector2(lx - 2.5, ly1), Vector2(lx + 2.5, ly0), Vector2(lx + 2.5, ly1)])
			var y2 = ly0 - 3.0
			while y2 > ly1:
				ll.append_array([Vector2(lx - 2.5, y2), Vector2(lx + 2.5, y2)])
				y2 -= 4.0
			ci.draw_multiline(ll, P.IRON_D, 1.2)
		"searchlight":
			var lp = _pt(c, f[1], f[2])
			var sa = -0.25 + sin(t * TAU / 0.96) * 0.12
			ci.draw_colored_polygon(P.pts([lp, lp + Vector2.from_angle(sa - 0.13) * 46.0, lp + Vector2.from_angle(sa + 0.13) * 46.0]), Color(1.0, 0.95, 0.7, 0.16))
			P.circ(ci, lp, 4.5, P.BRASS, 1.5)
			ci.draw_circle(lp + Vector2(1.5, 0), 2.8, Color(1.0, 0.95, 0.75))
		"rangefinder":
			var rf = _pt(c, f[1], f[2]) + Vector2(0, -6.0)
			ci.draw_line(rf + Vector2(-12, 0), rf + Vector2(12, 0), P.OUT, 5.0)
			ci.draw_line(rf + Vector2(-12, 0), rf + Vector2(12, 0), P.IRON, 3.0)
			ci.draw_circle(rf + Vector2(-12, 0), 2.5, P.BRASS)
			ci.draw_circle(rf + Vector2(12, 0), 2.5, P.BRASS)
			ci.draw_line(rf, rf + Vector2(0, 6), P.IRON_D, 2.0)
		"windows":
			var wl = PackedVector2Array()
			for k in int(f[4]):
				var wp = _pt(c, lerpf(float(f[1]), float(f[2]), (k + 0.5) / float(f[4])), f[3])
				wl.append_array([wp + Vector2(-3, 0), wp + Vector2(3, 0)])
			ci.draw_multiline(wl, P.OUT, 7.0)
			ci.draw_multiline(wl, Color(1.0, 0.8, 0.45, 0.9), 5.0)
		"crates":
			var cr = _pt(c, f[1], f[2])
			for k in int(f[3]):
				P.rect(ci, Rect2(cr.x + k * 9.0, cr.y - 8.0, 8.0, 8.0), P.WOOD, 1.3)
				ci.draw_line(cr + Vector2(k * 9.0 + 1.0, -1.0), cr + Vector2(k * 9.0 + 7.0, -7.0), P.WOOD_D, 1.0)
		"barrels":
			var br = _pt(c, f[1], f[2])
			for k in int(f[3]):
				var bc = br + Vector2(k * 8.0, -5.0)
				P.ell(ci, bc, 3.8, 5.0, P.WOOD, 1.2)
				ci.draw_line(bc + Vector2(-3.6, -2.0), bc + Vector2(3.6, -2.0), P.IRON_D, 1.2)
				ci.draw_line(bc + Vector2(-3.6, 2.0), bc + Vector2(3.6, 2.0), P.IRON_D, 1.2)
		"camo":
			var cm0 = _pt(c, f[1], f[3])
			var cm1 = _pt(c, f[2], f[3])
			var n2 = int((cm1.x - cm0.x) / 7.0)
			for k in n2:
				var cp3 = cm0 + Vector2(k * 7.0, 0)
				ci.draw_circle(cp3 + Vector2(0, -2.0 - (k % 2) * 1.5), 3.5, MOSS.darkened(0.1 * (k % 3)))
			var net = PackedVector2Array()
			for k in n2:
				net.append_array([cm0 + Vector2(k * 7.0, -1), cm0 + Vector2(k * 7.0 + 4.0, -5)])
			ci.draw_multiline(net, Color(0.25, 0.22, 0.15, 0.7), 1.0)
		"scope":
			var scb = _pt(c, f[1], f[2])
			P.rect(ci, Rect2(scb.x - 6.0, scb.y - 6.0, 10.0, 6.0), P.IRON_D, 1.2)
			P.bar(ci, scb + Vector2(-2.0, -8.0), 0.0, 14.0, 3.0, P.BRASS, 1.0)
			ci.draw_circle(scb + Vector2(12.0, -8.0), 1.4, Color(0.6, 0.85, 1.0))
		"mantlet_plate":
			var mpp = _pt(c, f[1], f[2])
			P.poly(ci, P.pts([mpp + Vector2(-5, -8), mpp + Vector2(5, -6), mpp + Vector2(5, 6), mpp + Vector2(-5, 8)]), c.coat.darkened(0.15), 1.8)
			P.circ(ci, mpp + Vector2(2, 0), 3.5, P.IRON_D, 1.2)
		"rhomboid_frame":
			# tracks that run round the whole hull side, with a sponson door in the middle
			var th = float(f[1])
			var hl: float = c.hl
			var rb = P.pts([Vector2(-hl * 1.04, -th * 0.5), Vector2(-hl * 0.92, 0), Vector2(hl * 0.86, 0), Vector2(hl * 1.2, -c.H * 0.42 - th), Vector2(hl * 1.0, -c.H * 0.55 - th), Vector2(-hl * 0.95, -c.H * 0.38 - th)])
			P.poly(ci, rb, P.COAL, 2.5)
			var inner = P.pts([Vector2(-hl * 0.92, -th * 0.65), Vector2(-hl * 0.82, -th * 0.6), Vector2(hl * 0.8, -th * 0.6), Vector2(hl * 1.03, -c.H * 0.42 - th * 0.4), Vector2(hl * 0.93, -c.H * 0.47 - th * 0.55), Vector2(-hl * 0.87, -c.H * 0.32 - th * 0.55)])
			P.poly(ci, inner, coat.darkened(0.1), 1.8)
			ci.draw_colored_polygon(P.pts([inner[5], inner[4], inner[4] + Vector2(0, 4), inner[5] + Vector2(0, 4)]), coat.lightened(0.22))
			# links running round the loop
			var loop = rb.duplicate()
			loop.append(rb[0])
			var total = 0.0
			for i in loop.size() - 1:
				total += loop[i].distance_to(loop[i + 1])
			var ph = fposmod(c.walk * 3.0, 7.0)
			var lk = PackedVector2Array()
			var dpos = ph
			while dpos < total:
				var acc = 0.0
				for i in loop.size() - 1:
					var sl2 = loop[i].distance_to(loop[i + 1])
					if acc + sl2 >= dpos:
						var q = loop[i].lerp(loop[i + 1], (dpos - acc) / sl2)
						var nn = (loop[i + 1] - loop[i]).normalized().orthogonal() * 2.5
						lk.append_array([q - nn, q + nn])
						break
					acc += sl2
				dpos += 7.0
			ci.draw_multiline(lk, P.IRON_D, 2.0)
			var rw = PackedVector2Array()
			for k in 7:
				var wx = lerpf(-hl * 0.78, hl * 0.72, k / 6.0)
				P.circ(ci, Vector2(wx, -th * 0.38), th * 0.22, P.IRON, 1.0)
				var hd = Vector2.from_angle(c.walk * 2.2 + k) * th * 0.14
				rw.append_array([Vector2(wx, -th * 0.38) - hd, Vector2(wx, -th * 0.38) + hd])
			ci.draw_multiline(rw, P.BRASS_D, 1.2)
			P.rivets(ci, Vector2(-hl * 0.8, -c.H * 0.27 - th * 0.4), Vector2(hl * 0.85, -c.H * 0.36 - th * 0.4), 10)
			# side door with a peeking passenger
			var dpo = Vector2(-hl * 0.15, -th * 0.65)
			P.rect(ci, Rect2(dpo.x - 7.0, dpo.y - 13.0, 14.0, 13.0), coat.darkened(0.25), 1.5)
			_head(c, dpo + Vector2(0, -8.0), Color("8a4a24"))
		"portholes":
			var p0 = _pt(c, f[1], f[3])
			var p1 = _pt(c, f[2], f[3])
			var n3 = int(f[4])
			var rims = PackedVector2Array()
			var lights = PackedVector2Array()
			for k in n3:
				var pp2 = p0.lerp(p1, (k + 0.5) / float(n3))
				rims.append_array([pp2 + Vector2(-3.4, 0), pp2 + Vector2(3.4, 0)])
				lights.append_array([pp2 + Vector2(-2.0, 0), pp2 + Vector2(2.0, 0)])
			ci.draw_multiline(rims, P.OUT, 8.2)
			ci.draw_multiline(rims, P.BRASS, 6.2)
			ci.draw_multiline(lights, Color(1.0, 0.8, 0.45, 0.95), 4.0)
			for k in mini(int(f[5]), n3):
				var hp2 = p0.lerp(p1, (k * 2 + 0.5) / float(n3)) if k * 2 < n3 else p0
				ci.draw_circle(hp2 + Vector2(0, 0.5), 1.8, P.SKIN)
				ci.draw_line(hp2 + Vector2(-1.5, 1.5), hp2 + Vector2(1.5, 1.5), P.WOOD_D, 1.5)
		"ramp":
			var rx2 = float(f[1]) * c.hl
			var open = 0.0
			P.poly(ci, P.pts([Vector2(rx2, c.base - 1.0), Vector2(rx2 - 4.0 - open, c.base - 1.0), Vector2(rx2 - 4.0, c.base - c.H * 0.65), Vector2(rx2, c.base - c.H * 0.65)]), coat.darkened(0.2), 1.5)
			ci.draw_line(Vector2(rx2 - 2.0, c.base - c.H * 0.6), Vector2(rx2 - 2.0, c.base - 3.0), P.IRON_D, 1.0)
		"railing":
			var r0b = _pt(c, f[1], f[3]) + Vector2(0, -1.0)
			var r1b = _pt(c, f[2], f[3]) + Vector2(0, -1.0)
			var rl2 = PackedVector2Array([r0b + Vector2(0, -5), r1b + Vector2(0, -5)])
			var x3 = r0b.x
			while x3 <= r1b.x:
				rl2.append_array([Vector2(x3, r0b.y), Vector2(x3, r0b.y - 5)])
				x3 += 9.0
			ci.draw_multiline(rl2, P.IRON_D, 1.0)
		"anchor":
			var an = _pt(c, f[1], f[2])
			ci.draw_line(an, an + Vector2(4, 6), P.IRON_D, 2.0)
			ci.draw_arc(an + Vector2(4, 8), 4.0, 0.2, PI - 0.2, 6, P.IRON_D, 2.0)
		"mast":
			var mb = _pt(c, f[1], f[2])
			var mh2 = float(f[3])
			ci.draw_line(mb, mb + Vector2(0, -mh2), P.WOOD_D, 2.5)
			ci.draw_line(mb + Vector2(-7, -mh2 * 0.7), mb + Vector2(7, -mh2 * 0.7), P.WOOD_D, 1.8)
			if c.wc >= 3:
				P.rect(ci, Rect2(mb.x - 4.0, mb.y - mh2 * 0.85, 8.0, 4.0), P.WOOD, 1.0)   # crow's nest
			var wv2 = sin(t * TAU / 0.96 * 2.0) * 2.0
			P.poly(ci, P.pts([mb + Vector2(0, -mh2), mb + Vector2(-12, -mh2 + 1 + wv2), mb + Vector2(-11, -mh2 + 5 + wv2), mb + Vector2(0, -mh2 + 6)]), P.CLOTH_RED, 0.8)
		"deckhouse":
			var dh0 = _pt(c, f[1], f[2])
			var dw3 = float(f[3]) * c.hl
			var dh3 = float(f[4]) * c.H
			P.poly(ci, P.pts([dh0 + Vector2(-dw3 * 0.5, 0), dh0 + Vector2(dw3 * 0.5, 0), dh0 + Vector2(dw3 * 0.42, -dh3), dh0 + Vector2(-dw3 * 0.45, -dh3)]), coat.darkened(0.06), 2.0)
			ci.draw_colored_polygon(P.pts([dh0 + Vector2(-dw3 * 0.44, -dh3 + 1), dh0 + Vector2(dw3 * 0.41, -dh3 + 1), dh0 + Vector2(dw3 * 0.42, -dh3 + 4), dh0 + Vector2(-dw3 * 0.45, -dh3 + 4)]), coat.lightened(0.25))
			var wl2 = PackedVector2Array()
			for k in 3:
				var wp2 = dh0 + Vector2(-dw3 * 0.3 + k * dw3 * 0.3, -dh3 * 0.55)
				wl2.append_array([wp2 + Vector2(-2.5, 0), wp2 + Vector2(2.5, 0)])
			ci.draw_multiline(wl2, Color(0.6, 0.8, 0.9, 0.85), 4.0)
		"bridge":
			var bb = _pt(c, f[1], f[2])
			var bw = float(f[3]) * c.hl
			var bh2 = float(f[4]) * c.H
			P.poly(ci, P.pts([bb + Vector2(-bw * 0.5, 0), bb + Vector2(bw * 0.5, 0), bb + Vector2(bw * 0.45, -bh2 * 0.65), bb + Vector2(bw * 0.62, -bh2 * 0.72), bb + Vector2(bw * 0.55, -bh2), bb + Vector2(-bw * 0.4, -bh2), bb + Vector2(-bw * 0.45, -bh2 * 0.65)]), coat.darkened(0.04), 2.0)
			ci.draw_colored_polygon(P.pts([bb + Vector2(-bw * 0.38, -bh2 + 1), bb + Vector2(bw * 0.54, -bh2 + 1), bb + Vector2(bw * 0.5, -bh2 + 4), bb + Vector2(-bw * 0.4, -bh2 + 4)]), coat.lightened(0.25))
			var gw2 = PackedVector2Array([bb + Vector2(-bw * 0.3, -bh2 * 0.83), bb + Vector2(bw * 0.5, -bh2 * 0.83)])
			ci.draw_multiline(gw2, P.OUT, 7.0)
			ci.draw_multiline(gw2, Color(0.6, 0.8, 0.9, 0.85), 5.0)
			for k in 2:
				var hc3 = bb + Vector2(-bw * 0.1 + k * bw * 0.35, -bh2 * 0.83)
				ci.draw_circle(hc3, 2.2, P.SKIN)
				ci.draw_line(hc3 + Vector2(-1.6, 1.8), hc3 + Vector2(1.6, 1.8), Color("8a4a24") if k == 0 else Color("c8c0b0"), 1.8)
			var mb2 = bb + Vector2(0, -bh2)
			ci.draw_line(mb2, mb2 + Vector2(0, -22.0), P.IRON_D, 2.0)
			P.rect(ci, Rect2(mb2.x - 4.0, mb2.y - 18.0, 8.0, 4.0), P.IRON, 1.0)   # crow's nest
			ci.draw_line(mb2 + Vector2(-8, -12), mb2 + Vector2(8, -12), P.IRON_D, 1.5)
			var wv3 = sin(t * TAU / 0.96 * 2.0) * 2.0
			P.poly(ci, P.pts([mb2 + Vector2(0, -22), mb2 + Vector2(-12, -21 + wv3), mb2 + Vector2(-11, -17 + wv3), mb2 + Vector2(0, -16)]), P.CLOTH_RED, 0.8)
		"funnels":
			var fb2 = _pt(c, f[1], f[2])
			var fh = float(f[4])
			for k in int(f[3]):
				var fx = fb2.x - k * 12.0
				P.poly(ci, P.pts([Vector2(fx - 4.5, fb2.y), Vector2(fx + 4.5, fb2.y), Vector2(fx + 3.0, fb2.y - fh), Vector2(fx - 6.0, fb2.y - fh)]), coat.darkened(0.15), 1.8)
				ci.draw_line(Vector2(fx - 5.2, fb2.y - fh * 0.7), Vector2(fx + 3.8, fb2.y - fh * 0.7), P.BRASS, 3.0)
				ci.draw_line(Vector2(fx - 6.0, fb2.y - fh), Vector2(fx + 3.0, fb2.y - fh), P.COAL, 2.5)
				P.smoke_puff(ci, Vector2(fx - 1.5, fb2.y - fh - 2.0), t + k * 0.4, 3, Color(0.28, 0.26, 0.26, 0.6) if c.moving else Color(0.5, 0.48, 0.47, 0.5))
		"bands_hull":
			var bh0 = _pt(c, f[1], 0.5)
			var bh1 = _pt(c, f[2], 0.5)
			ci.draw_line(bh0 + Vector2(0, -c.H * 0.3), bh1 + Vector2(0, -c.H * 0.3), P.BRASS_D, 2.5)
			ci.draw_line(bh0 + Vector2(0, c.H * 0.25), bh1 + Vector2(0, c.H * 0.25), P.BRASS_D, 2.0)
		"holes":
			var h0b = _pt(c, f[1], 0.5)
			var h1b = _pt(c, f[2], 0.5)
			for k in int(f[3]):
				var hp3 = h0b.lerp(h1b, (k + 0.5) / float(f[3])) + Vector2(0, (k % 2) * 5.0 - 2.0)
				P.poly(ci, P.pts([hp3 + Vector2(-4, -2), hp3 + Vector2(-1, -4), hp3 + Vector2(4, -3), hp3 + Vector2(3, 2), hp3 + Vector2(-2, 3)]), Color(0.08, 0.07, 0.06), 1.0)
		"moss":
			var m0 = _pt(c, f[1], f[3])
			var m1 = _pt(c, f[2], f[3])
			for k in 5:
				var mp2 = m0.lerp(m1, (k + 0.5) / 5.0) + Vector2(0, -1.0 - (k % 2) * 2.0)
				ci.draw_circle(mp2, 3.0, MOSS)
				ci.draw_line(mp2, mp2 + Vector2((k % 3) - 1, 7.0 + k % 2 * 3.0), MOSS.darkened(0.2), 1.2)


static func _stripes(c: Dictionary, r: Rect2) -> void:
	var ci: CanvasItem = c.ci
	ci.draw_colored_polygon(P.pts([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), HAZARD_Y)
	var sl = PackedVector2Array()
	var x = r.position.x - r.size.y
	while x < r.end.x:
		var a0 = Vector2(maxf(x, r.position.x), r.end.y - maxf(0.0, r.position.x - x))
		var b0 = Vector2(minf(x + r.size.y, r.end.x), r.position.y + maxf(0.0, x + r.size.y - r.end.x))
		sl.append_array([a0, b0])
		x += 4.0
	ci.draw_multiline(sl, P.COAL, 1.5)


static func _emblem(c: Dictionary, at: Vector2, kind: String, s: float) -> void:
	var ci: CanvasItem = c.ci
	match kind:
		"anvil":
			var k = s / 6.0
			P.poly(ci, P.pts([at + Vector2(-6, -2) * k, at + Vector2(6, -2) * k, at + Vector2(4, 1) * k, at + Vector2(2, 1) * k, at + Vector2(3, 4) * k, at + Vector2(-3, 4) * k, at + Vector2(-2, 1) * k, at + Vector2(-5, 1) * k]), P.BRASS, 1.0)
		"bolt":
			P.poly(ci, P.pts([at + Vector2(1, -s), at + Vector2(-s * 0.5, s * 0.1), at + Vector2(0, s * 0.1), at + Vector2(-1, s), at + Vector2(s * 0.5, -s * 0.1), at + Vector2(0, -s * 0.1)]), Color(c.glow.r, c.glow.g, c.glow.b, 0.95), 1.0)
		"peak":
			P.poly(ci, P.pts([at + Vector2(-s, s * 0.6), at + Vector2(-s * 0.2, -s * 0.7), at + Vector2(0.1 * s, -s * 0.2), at + Vector2(s * 0.45, -s * 0.8), at + Vector2(s, s * 0.6)]), STONE, 1.2)
			P.poly(ci, P.pts([at + Vector2(-s * 0.42, -s * 0.38), at + Vector2(-s * 0.2, -s * 0.7), at + Vector2(0.0, -s * 0.38)]), Color(0.95, 0.95, 0.97), 0.0)
			P.poly(ci, P.pts([at + Vector2(s * 0.25, -s * 0.5), at + Vector2(s * 0.45, -s * 0.8), at + Vector2(s * 0.65, -s * 0.5)]), Color(0.95, 0.95, 0.97), 0.0)


static func _damage(c: Dictionary) -> void:
	var ci: CanvasItem = c.ci
	var hp: float = c.hp
	if hp >= 0.5:
		return
	var top = Vector2(-c.hl * 0.4, c.base - c.H)
	ci.draw_circle(Vector2(c.hl * 0.25, c.base - c.H * 0.6), 4.0, Color(0.1, 0.09, 0.08, 0.55))
	ci.draw_circle(Vector2(-c.hl * 0.3, c.base - c.H * 0.4), 3.0, Color(0.1, 0.09, 0.08, 0.5))
	P.smoke_puff(ci, top + Vector2(0, -3.0), c.t * 1.3, 3, Color(0.18, 0.17, 0.17, 0.7))
	if hp < 0.25:
		for k in 3:
			var fh = 8.0 + sin(c.t * 17.0 + k * 2.0) * 3.0
			var fx = top.x + k * 7.0
			ci.draw_colored_polygon(P.pts([Vector2(fx - 4, top.y), Vector2(fx, top.y - fh), Vector2(fx + 4, top.y)]), Color(1.0, 0.55 + k * 0.1, 0.15, 0.85))
