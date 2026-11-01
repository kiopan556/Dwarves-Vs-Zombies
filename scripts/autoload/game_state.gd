extends Node
## Persistent player profile, Great Forge research rules, loadouts, rewards and screen navigation.

signal profile_changed

const SCENES := {
	"title": "res://scenes/main_menu.tscn",
	"menu": "res://scenes/forge_hub.tscn",      # the Heart of the Great Forge hub (M002)
	"campaign": "res://scenes/campaign_map.tscn",
	"loadout": "res://scenes/loadout.tscn",
	"forge": "res://scenes/forge.tscn",
	"compendium": "res://scenes/compendium.tscn",
	"settings": "res://scenes/settings.tscn",
	"battle": "res://scenes/battle_screen.tscn",
	"sandbox": "res://scenes/sandbox.tscn",
}
const GROUND_SLOTS := 7
const AIR_SLOTS := 4
const SLOT_COUNT := 12   # 7 ground + 4 air + 1 flexible. No hero slot.

var profile: Dictionary = {}
var selected_stage: String = "s001"
var selected_heroic := false     # M007: the next battle is the Heroic version of selected_stage
var last_result: Dictionary = {}


func _ready() -> void:
	profile = SaveManager.load_profile()
	_sanitize()
	apply_settings()
	UiKit.ensure_glyph_atlas(self)   # bake HUD/UI icons into one batched atlas (M003)


func save() -> void:
	SaveManager.save_profile(profile)


func reset_progress() -> void:
	SaveManager.wipe()
	profile = SaveManager.default_profile()
	save()
	profile_changed.emit()


func reload_from_disk() -> void:
	profile = SaveManager.load_profile()
	_sanitize()


func _sanitize() -> void:
	# Drop ids that no longer exist in the registry (never crash on stale saves).
	profile.unlocked_units = profile.unlocked_units.filter(func(u): return Registry.has_unit(u))
	for name in profile.loadouts.keys():
		var arr: Array = profile.loadouts[name]
		for i in arr.size():
			if arr[i] != "" and not is_unlocked(arr[i]):
				arr[i] = ""


func goto(scene: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(SCENES[scene])


# ------------------------------------------------------------------ settings
func setting(key: String):
	return profile.settings.get(key)


func set_setting(key: String, value) -> void:
	profile.settings[key] = value
	apply_settings()
	save()


## Graphics quality presets (M002b performance patch):
##   high      live procedural art, 60 FPS, 60 Hz logic (desktop)
##   balanced  baked sprite atlas, 60 FPS cap, 30 Hz logic
##   low       baked sprite atlas, 30 FPS cap, 30 Hz logic, halved particles, smaller atlas
## Every preset caps physics catch-up at 2 steps per frame, so a slow frame makes the game run
## slightly slower instead of spiralling into ever-longer frames.
func apply_settings() -> void:
	var q = quality()
	Engine.max_fps = 30 if q == "low" else 60
	Engine.physics_ticks_per_second = 60 if q == "high" else 30
	Engine.max_physics_steps_per_frame = 2
	Unit.anim_detail = 0 if q == "low" else 1   # M004: fewer distinct poses on the Performance preset
	Unit.motion_on = bool(profile.get("settings", {}).get("motion", true))   # M006: reduced-motion option
	if is_instance_valid(PoseCache):
		PoseCache.set_enabled(q != "high", 3 if q == "low" else 4, 1.5 if q == "low" else 2.0)
	if is_instance_valid(Audio):
		Audio.apply_volumes()


func quality() -> String:
	var q = String(profile.settings.get("quality", default_quality()))
	return q if q in ["high", "balanced", "low"] else default_quality()


static func default_quality() -> String:
	return "low" if OS.has_feature("mobile") or OS.has_feature("android") else "high"


func is_low_quality() -> bool:
	return quality() == "low"


# ------------------------------------------------------------------ units & research
func is_unlocked(unit_id: String) -> bool:
	return unit_id in profile.unlocked_units


func is_researched(node_id: String) -> bool:
	return node_id in profile.researched


func tier_open(tier: int) -> bool:
	return tier in profile.open_tiers


## Returns "" if researchable, otherwise a human reason.
func research_block_reason(node: Dictionary) -> String:
	if node.is_empty():
		return "Unknown"
	if node.has("variant_of"):
		if is_researched(node.id):
			return "Researched"
		if not is_unlocked(node.variant_of):
			return "Requires " + Registry.entry(node.variant_of).get("name", node.variant_of)
	var is_unit: bool = node.has("unit")
	if is_unit and is_unlocked(node.unit):
		return "Researched"
	if not is_unit and is_researched(node.id):
		return "Researched"
	if not node.get("implemented", false):
		var ms: String = Registry.entry(node.unit).get("milestone", "later") if is_unit else "later milestone"
		return "Planned — " + ms
	var tier = int(node.tier)
	if not tier_open(tier):
		var gate: String = Registry.tech.get("tier_stage_gate", {}).get(str(tier), "")
		var st = Registry.stage(gate)
		return "Clear %s to open %s" % [st.get("name", gate), Registry.TIER_NAMES[tier]]
	var missing: Array = []
	for r in node.get("requires", []):
		if not is_researched(r):
			missing.append(Registry.tech_node(r).get("name", r))
	if not missing.is_empty():
		return "Requires " + ", ".join(missing)
	if profile.sparks < int(node.cost):
		return "Need %d Sparks" % int(node.cost)
	return ""


func research(node_id: String) -> bool:
	var node = Registry.tech_node(node_id)
	if research_block_reason(node) != "":
		return false
	profile.sparks -= int(node.cost)
	_mark_researched(node)
	save()
	profile_changed.emit()
	return true


func _mark_researched(node: Dictionary) -> void:
	if not is_researched(node.id):
		profile.researched.append(node.id)
	if node.has("unit") and not is_unlocked(node.unit):
		profile.unlocked_units.append(node.unit)


func unlock_unit(unit_id: String) -> void:
	var node = Registry.tech_node("unit_" + unit_id)
	if not node.is_empty():
		_mark_researched(node)
	elif not is_unlocked(unit_id):
		profile.unlocked_units.append(unit_id)


# ------------------------------------------------------------------ campaign
func is_cleared(stage_id: String) -> bool:
	return profile.cleared.has(stage_id)


func stage_available(st: Dictionary) -> bool:
	if not st.get("implemented", false):
		return false
	var req = st.get("requires")
	return req == null or is_cleared(req)


func highest_cleared_index() -> int:
	var h = 0
	for k in profile.cleared.keys():
		h = max(h, int(String(k).substr(1)))
	return h


## M005 stars: [victory, stronghold held above 50 %, challenge met], best ever per star.
func stars_for(stage_id: String) -> Array:
	var a = profile.get("stars", {}).get(stage_id, null)
	if a is Array and a.size() == 3:
		return a
	return [is_cleared(stage_id), false, false]


func star_count(stage_id: String) -> int:
	var n = 0
	for b in stars_for(stage_id):
		if b:
			n += 1
	return n


func total_stars() -> int:
	var n = 0
	var keys: Dictionary = {}
	for k in profile.get("stars", {}).keys():
		keys[k] = true
	for k2 in profile.cleared.keys():
		keys[k2] = true
	for k3 in keys.keys():
		n += star_count(k3)
	return n


## Records newly earned stars and pays the first-time star bonus: +10 % of the stage's Sparks per
## star, at most +30 % per stage over its lifetime, so stars never become a Spark farm.
func record_stars(stage_id: String, earned: Array, first_clear: bool = false) -> Dictionary:
	var old = [false, false, false] if first_clear else stars_for(stage_id).duplicate()
	var now = [bool(old[0]) or bool(earned[0]), bool(old[1]) or bool(earned[1]), bool(old[2]) or bool(earned[2])]
	var fresh = 0
	for i in 3:
		if now[i] and not old[i] and earned[i]:
			fresh += 1
	if not profile.has("stars"):
		profile["stars"] = {}
	profile.stars[stage_id] = now
	var base = int(Registry.stage(stage_id).get("rewards", {}).get("sparks", 30))
	var bonus = int(round(base * 0.1)) * fresh
	profile.sparks += bonus
	return {"stars": now, "earned": earned, "fresh": fresh, "bonus": bonus}


func hint_wanted(tag: String) -> bool:
	return tag != "" and bool(profile.settings.get("hints", true)) and not tag in profile.get("hints_seen", [])


func mark_hint(tag: String) -> void:
	if not profile.has("hints_seen"):
		profile["hints_seen"] = []
	if not tag in profile.hints_seen:
		profile.hints_seen.append(tag)


func tutorial_wanted(stage_id: String) -> bool:
	return stage_id in ["s001", "s002", "s003"] and bool(profile.settings.get("tutorial", false)) and not stage_id in profile.get("tutorial_done", [])


func mark_tutorial(stage_id: String) -> void:
	if not stage_id in profile.tutorial_done:
		profile.tutorial_done.append(stage_id)
	save()


## Applies first-clear / replay rewards and returns a summary for the Victory screen.
func grant_stage_rewards(stage_id: String, battle_time: float, kills: int, stars: Array = []) -> Dictionary:
	var st = Registry.stage(stage_id)
	var rw: Dictionary = st.get("rewards", {})
	var first = not is_cleared(stage_id)
	var sparks = int(rw.get("sparks", 30))
	if not first:
		sparks = max(8, sparks / 3)
	var summary = {"first_clear": first, "sparks": sparks, "unlocked": [], "tiers": []}
	profile.sparks += sparks
	if first:
		for u in rw.get("unlock", []):
			if not is_unlocked(u):
				unlock_unit(u)
				summary.unlocked.append(u)
		profile.cleared[stage_id] = {"best_time": snappedf(battle_time, 0.1), "clears": 1}
	else:
		var c: Dictionary = profile.cleared[stage_id]
		c.clears = int(c.get("clears", 1)) + 1
		c.best_time = min(float(c.get("best_time", battle_time)), snappedf(battle_time, 0.1))
	# tier gates
	var gates: Dictionary = Registry.tech.get("tier_stage_gate", {})
	for t in gates.keys():
		if gates[t] == stage_id and not tier_open(int(t)):
			profile.open_tiers.append(int(t))
			summary.tiers.append(int(t))
	if rw.has("open_tier") and not tier_open(int(rw.open_tier)):
		profile.open_tiers.append(int(rw.open_tier))
		summary.tiers.append(int(rw.open_tier))
	if stars.size() == 3:
		var sr = record_stars(stage_id, stars, first)
		summary["stars"] = sr.stars
		summary["stars_earned"] = sr.earned
		summary["star_bonus"] = sr.bonus
		summary["sparks"] = int(summary.sparks) + int(sr.bonus)
	elif first:
		profile.stars[stage_id] = stars_for(stage_id)
	profile.stats.victories += 1
	profile.stats.kills += kills
	save()
	profile_changed.emit()
	return summary


# ------------------------------------------------------------------ M007 Heroic difficulty
## Every cleared stage unlocks its Heroic version (Acts I-IV, and Act V once it exists).
func heroic_available(stage_id: String) -> bool:
	var st = Registry.stage(stage_id)
	return st.get("implemented", false) and st.has("heroic") and is_cleared(stage_id)


func heroic_cleared(stage_id: String) -> bool:
	return profile.get("heroic", {}).has(stage_id)


func heroic_stars(stage_id: String) -> Array:
	var h = profile.get("heroic", {}).get(stage_id, null)
	if h is Dictionary and h.get("stars") is Array and h.stars.size() == 3:
		return h.stars
	return [false, false, false]


func heroic_star_count(stage_id: String) -> int:
	var n = 0
	for b in heroic_stars(stage_id):
		if b:
			n += 1
	return n


func total_heroic_stars() -> int:
	var n = 0
	for k in profile.get("heroic", {}).keys():
		n += heroic_star_count(k)
	return n


## Heroic rewards: separate stars (best ever per star), and a modest one-time Spark payout on the first Heroic
## clear. Replays and Heroic stars pay nothing else — the rest of the reward is cosmetic (a red-gold banner).
func grant_heroic_rewards(stage_id: String, battle_time: float, kills: int, stars: Array) -> Dictionary:
	var st = Registry.stage(stage_id)
	if not profile.has("heroic"):
		profile["heroic"] = {}
	var first = not heroic_cleared(stage_id)
	var sparks = int(st.get("heroic", {}).get("spark_bonus", 0)) if first else 0
	var old = heroic_stars(stage_id)
	var now = [bool(old[0]) or bool(stars[0]), bool(old[1]) or bool(stars[1]), bool(old[2]) or bool(stars[2])] if stars.size() == 3 else old
	var rec: Dictionary = profile.heroic.get(stage_id, {"stars": now, "clears": 0, "best_time": snappedf(battle_time, 0.1)})
	rec["stars"] = now
	rec["clears"] = int(rec.get("clears", 0)) + 1
	rec["best_time"] = minf(float(rec.get("best_time", battle_time)), snappedf(battle_time, 0.1))
	profile.heroic[stage_id] = rec
	profile.sparks += sparks
	if first:
		profile.stats["heroic_clears"] = int(profile.stats.get("heroic_clears", 0)) + 1
	profile.stats.victories += 1
	profile.stats.kills += kills
	save()
	profile_changed.emit()
	return {"first_clear": first, "sparks": sparks, "unlocked": [], "tiers": [], "stars": now, "stars_earned": stars, "heroic": true}


func record_defeat(kills: int) -> void:
	profile.stats.defeats += 1
	profile.stats.kills += kills
	save()


func note_encountered(enemy_id: String) -> void:
	if not enemy_id in profile.encountered:
		profile.encountered.append(enemy_id)


# ------------------------------------------------------------------ loadouts
func slot_kind(i: int) -> String:
	if i < GROUND_SLOTS:
		return "ground"
	if i < GROUND_SLOTS + AIR_SLOTS:
		return "air"
	return "flex"


func unit_fits_slot(unit_id: String, i: int) -> bool:
	var kind = slot_kind(i)
	if kind == "flex":
		return true
	return Registry.entry(unit_id).get("domain", "ground") == kind


func active_loadout() -> Array:
	return profile.loadouts[profile.active_preset]


func set_slot(i: int, unit_id: String) -> void:
	var lo = active_loadout()
	if unit_id != "":
		for j in lo.size():
			if lo[j] == unit_id:
				lo[j] = ""
	lo[i] = unit_id
	save()


func auto_place(unit_id: String) -> bool:
	var lo = active_loadout()
	if unit_id in lo:
		return false
	for i in SLOT_COUNT:
		if lo[i] == "" and slot_kind(i) != "flex" and unit_fits_slot(unit_id, i):
			set_slot(i, unit_id)
			return true
	if lo[SLOT_COUNT - 1] == "":
		set_slot(SLOT_COUNT - 1, unit_id)
		return true
	return false


# ------------------------------------------------------------------ M002 alternate armaments
func variants_for(unit_id: String) -> Array:
	var st = Registry.entry(unit_id).get("stats")
	return st.get("variants", []) if st != null else []


func variant_available(unit_id: String, variant_id: String) -> bool:
	return is_researched("variant_%s_%s" % [unit_id, variant_id])


func selected_variant(unit_id: String) -> String:
	var v: String = String(profile.get("variants", {}).get(unit_id, ""))
	return v if v != "" and variant_available(unit_id, v) else ""


func select_variant(unit_id: String, variant_id: String) -> void:
	if not profile.has("variants"):
		profile["variants"] = {}
	if variant_id == "" or variant_available(unit_id, variant_id):
		profile.variants[unit_id] = variant_id
		save()


## Combat id with the player's chosen armament applied (e.g. "copper_sentinel@breacher").
func deploy_id(unit_id: String) -> String:
	var v = selected_variant(unit_id)
	return unit_id + ("@" + v if v != "" else "")
