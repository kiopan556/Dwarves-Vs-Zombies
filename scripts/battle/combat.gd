class_name Combat
extends RefCounted
## Shared combat rules: battlefield geometry, damage-type vs armor-class tables, helpers.

const WORLD_W := 2600.0
const GROUND_Y := 575.0
const LOW_AIR_Y := 470.0          # flyers below this line can be hit by "ground_lowair" weapons
const DWARF_BASE_X := 120.0
const UNDEAD_BASE_X := 2480.0
const BASE_FACE := 70.0           # distance from base centre to its front face
const BUCKET := 128.0

enum Side { DWARF = 0, UNDEAD = 1 }

## Multipliers: armor class -> damage type -> factor. "ap" weapons treat pierce/blast as 1.0 vs heavy armor.
const ARMOR := {
	"flesh":       {"pierce": 1.0, "blast": 1.0, "fire": 1.25, "flak": 1.0, "melee": 1.0, "acid": 1.0, "necro": 1.0},
	"light":       {"pierce": 0.85, "blast": 1.0, "fire": 1.0, "flak": 1.0, "melee": 0.9, "acid": 1.1, "necro": 1.0},
	"heavy":       {"pierce": 0.5, "blast": 0.9, "fire": 0.7, "flak": 1.0, "melee": 0.7, "acid": 1.6, "necro": 0.9},
	"bone":        {"pierce": 0.6, "blast": 1.3, "fire": 0.8, "flak": 1.0, "melee": 1.05, "acid": 0.8, "necro": 1.0},
	"bone_shield": {"pierce": 0.3, "blast": 1.2, "fire": 0.8, "flak": 1.0, "melee": 0.85, "acid": 0.8, "necro": 1.0},
	"hulk":        {"pierce": 0.65, "blast": 1.0, "fire": 1.2, "flak": 1.0, "melee": 0.85, "acid": 0.7, "necro": 1.0},
	"machine":     {"pierce": 0.55, "blast": 1.0, "fire": 0.6, "flak": 1.0, "melee": 0.75, "acid": 1.6, "necro": 0.9},
	"structure":   {"pierce": 0.35, "blast": 1.3, "fire": 0.8, "flak": 1.0, "melee": 0.6, "acid": 0.9, "necro": 0.8, "drill": 1.3},
	# war frames: physical reduction comes from their per-unit ARM% (see PHYSICAL / ARM_CAP)
	"mech":        {"pierce": 1.0, "blast": 1.0, "fire": 0.8, "flak": 1.0, "melee": 1.0, "acid": 1.4, "necro": 0.9, "shock": 1.2, "drill": 1.0},
}
const PHYSICAL := ["pierce", "blast", "melee", "flak", "drill"]
const ARM_CAP := 0.5
const MIN_DAMAGE_MULT := 0.08
## shock: arc weapons — machines conduct, bone insulates
const SHOCK := {"bone": 0.75, "bone_shield": 0.75, "machine": 1.25, "structure": 0.6}
const ARMORED_CLASSES := ["heavy", "machine", "hulk", "structure", "bone_shield", "mech"]


## Flak is fused for airbursts: full effect on flyers, weak against anything on the ground.
const FLAK_VS_AIR := 1.35
const FLAK_VS_GROUND := 0.3


static func dmg_mult(armor: String, dtype: String, ap: bool) -> float:
	var row: Dictionary = ARMOR.get(armor, ARMOR.flesh)
	var m: float = row.get(dtype, 1.0)
	if dtype == "shock":
		m = SHOCK.get(armor, 1.0)
	elif dtype == "drill":
		m = {"heavy": 0.9, "bone": 1.0, "hulk": 1.0, "structure": 1.3}.get(armor, 1.0)
	if ap and (dtype == "pierce" or dtype == "blast") and m < 1.0:
		m = lerpf(m, 1.0, 0.75)
	return m


static func base_x(side: int) -> float:
	return DWARF_BASE_X if side == Side.DWARF else UNDEAD_BASE_X


static func dir_of(side: int) -> float:
	return 1.0 if side == Side.DWARF else -1.0


static func enemy_of(side: int) -> int:
	return 1 - side
