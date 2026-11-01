extends Node
## Master content registry. Loads the data-driven rosters (data/*.json) and exposes
## lookups by stable ID. Shared behaviour lives in scripts/battle; this file only serves data.

const DATA_DIR := "res://data/"

var dwarves: Array = []          # all 160 roster entries (implemented + planned)
var undead: Array = []           # all 110 regular undead entries
var bosses: Array = []           # all 15 bosses
var stages: Array = []           # all 150 stages
var tech: Dictionary = {}        # doctrines + unit research nodes
var strongholds: Dictionary = {}
var aux: Dictionary = {}       # deployables (barricades, turrets): not roster entries

var _by_id: Dictionary = {}      # id -> entry (dwarves, undead, bosses)
var _stage_by_id: Dictionary = {}
var _tech_by_id: Dictionary = {}
var load_errors: PackedStringArray = []


func _ready() -> void:
	load_all()


func load_all() -> void:
	_by_id.clear()
	var d = _load_json("dwarf_roster.json")
	dwarves = d.get("units", [])
	strongholds = d.get("strongholds", {})
	aux = d.get("aux", {})
	undead = _load_json("undead_roster.json").get("units", [])
	bosses = _load_json("bosses.json").get("bosses", [])
	stages = _load_json("stages.json").get("stages", [])
	tech = _load_json("tech.json")
	for e in dwarves:
		_by_id[e.id] = e
	for e in undead:
		_by_id[e.id] = e
	for e in bosses:
		_by_id[e.id] = e
	for s in stages:
		_stage_by_id[s.id] = s
	for n in tech.get("doctrines", []):
		_tech_by_id[n.id] = n
	for n in tech.get("units", []):
		_tech_by_id[n.id] = n


func _load_json(file: String) -> Dictionary:
	var path = DATA_DIR + file
	if not FileAccess.file_exists(path):
		load_errors.append("missing " + path)
		push_error("Registry: missing " + path)
		return {}
	var txt = FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		load_errors.append("bad json " + path)
		push_error("Registry: bad json " + path)
		return {}
	return parsed


func entry(id: String) -> Dictionary:
	return _by_id.get(id, {})


func has_unit(id: String) -> bool:
	return _by_id.has(id)


func is_implemented(id: String) -> bool:
	return bool(_by_id.get(id, {}).get("implemented", false))


## Returns a flattened combat definition (stats + identity) for an implemented unit,
## enemy, boss or stronghold. Empty dictionary if the entry is planned-only.
func combat_def(id: String) -> Dictionary:
	if strongholds.has(id):
		var s: Dictionary = strongholds[id].duplicate(true)
		s["id"] = id
		s["name"] = "Dwarven Stronghold" if id == "dwarf_stronghold" else "Undead Citadel"
		s["faction"] = "dwarf" if id == "dwarf_stronghold" else "undead"
		s["behavior"] = "stronghold"
		s["speed"] = 0
		return s
	if aux.has(id):
		var ax: Dictionary = aux[id].duplicate(true)
		ax["id"] = id
		ax["faction"] = "dwarf"
		return ax
	var variant = ""
	if "@" in id:
		variant = id.get_slice("@", 1)
		id = id.get_slice("@", 0)
	var e: Dictionary = _by_id.get(id, {})
	if e.is_empty() or e.get("stats") == null:
		return {}
	var d: Dictionary = (e.stats as Dictionary).duplicate(true)
	if variant != "":
		for v in d.get("variants", []):
			if v.id == variant:
				# alternate armament: replaces the primary weapon(s) or adds an attachment
				d.weapons = (d.weapons + v.weapons) if v.get("add", false) else (v.weapons + d.weapons.slice(v.weapons.size()))
				d["variant"] = variant
				d["variant_name"] = v.name
	d["id"] = id
	d["name"] = e.get("name", id)
	d["faction"] = "undead" if e.get("faction", "undead") != "dwarf" else "dwarf"
	d["role"] = e.get("role", "")
	d["role2"] = e.get("role2", null)
	d["domain"] = e.get("domain", d.get("domain", "ground"))
	if e.has("cls") and not d.has("cls"):
		d["cls"] = e.cls
	if not d.has("cls"):
		d["cls"] = "infantry"
	return d


func stage(id: String) -> Dictionary:
	return _stage_by_id.get(id, {})


## M007 Heroic difficulty: the stage's own data with its `heroic` block applied — one extra authored event,
## track intervals x0.85, one more support structure, abilities ready earlier and a little more enemy HP (<= +15 %).
## Same seed and layout; the result is a new dictionary (the registry copy is never modified).
func heroic_stage(id: String) -> Dictionary:
	var base: Dictionary = stage(id)
	if base.is_empty() or not base.has("heroic"):
		return base
	var hb: Dictionary = base.heroic
	var st: Dictionary = base.duplicate(true)
	var k = float(hb.get("interval_mult", 0.85))
	for tr in st.tracks:
		tr.interval = float(tr.interval) * k
		tr.interval_min = float(tr.interval_min) * k
	if hb.has("event"):
		st.events.append(hb.event.duplicate(true))
	if hb.has("structure"):
		st.structures.append(hb.structure.duplicate(true))
	st.enemy_hp_mult = float(st.get("enemy_hp_mult", 1.0)) * minf(1.15, float(hb.get("hp_mult", 1.12)))
	st["heroic_mode"] = true
	st["heroic_ability_lead"] = float(hb.get("ability_lead", 0.45))
	return st


func stage_by_index(i: int) -> Dictionary:
	if i < 1 or i > stages.size():
		return {}
	return stages[i - 1]


func tech_node(id: String) -> Dictionary:
	return _tech_by_id.get(id, {})


func implemented_dwarves() -> Array:
	return dwarves.filter(func(e): return e.implemented)


func implemented_undead() -> Array:
	return undead.filter(func(e): return e.implemented)


func boss_for_stage(index: int) -> Dictionary:
	for b in bosses:
		if int(b.stage) == index:
			return b
	return {}


const BRANCH_ORDER := ["A", "B", "C", "D", "E", "F", "G"]
const BRANCH_NAMES := {
	"A": "Infantry & Firearms", "B": "Engineers & Fieldworks", "C": "Artillery & Anti-Air",
	"D": "Armored Vehicles", "E": "Mechanical Walkers", "F": "Aeronautics", "G": "Airship Engineering"}
const TIER_NAMES := ["Foundations", "Age of Blackpowder", "Age of Steam", "Age of Iron", "Age of War Machines", "Age of Colossi"]


func pretty_role(role) -> String:
	if role == null:
		return ""
	return String(role).replace("_", " ").capitalize()
