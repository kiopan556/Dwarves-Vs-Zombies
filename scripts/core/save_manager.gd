class_name SaveManager
extends RefCounted
## Versioned JSON save with backup + forward migration. Stable IDs only.

const SAVE_VERSION := 1
const DEFAULT_PATH := "user://dvz_save.json"

static var path: String = DEFAULT_PATH


static func default_profile() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"cleared": {},            # stage_id -> {best_time, clears}
		"researched": [],         # tech node ids (doctrines + unit_* nodes)
		"unlocked_units": ["tunnel_militia", "ironhold_rifleman", "shieldbearer", "light_field_cannon", "flak_crew", "dwarven_flying_machine"],
		"open_tiers": [0],        # tiers whose stage gate has been met (T1 opens at Stage 002)
		"sparks": 0,              # Forge Sparks — research currency
		"encountered": [],        # undead ids seen in battle (compendium spoiler control)
		"loadouts": {
			"Preset I": ["shieldbearer", "ironhold_rifleman", "tunnel_militia", "light_field_cannon", "flak_crew", "", "", "dwarven_flying_machine", "", "", "", ""],
			"Preset II": ["", "", "", "", "", "", "", "", "", "", "", ""],
			"Preset III": ["", "", "", "", "", "", "", "", "", "", "", ""],
		},
		"active_preset": "Preset I",
		"variants": {},           # unit_id -> selected alternate armament id (M002)
		"stars": {},              # M005: stage_id -> [victory, stronghold held >50 %, challenge met] (best ever, per star)
		"hints_seen": [],         # M005: first-encounter hint tags already shown
		"tutorial_done": [],      # M005: guided stages (s001-s003) whose tutorial has finished
		"acts_revealed": [1],     # M005: acts whose title cartouche has played on the Realm Map
		"heroic": {},             # M007: stage_id -> {stars: [3 bools], clears, best_time} for Heroic clears (separate stars)
		"last_stand": {},         # M008: arena_id -> {best_wave, best_score, best_kills, runs}
		"cosmetics": {"banners": [], "titles": [], "banner": "", "title": ""},   # M008: cosmetic rewards only (never power)
		"units_used": [],         # M008: dwarven unit ids ever deployed in a campaign battle (completion page)
		"ending_seen": false,     # M008: the ending sequence has played at least once
		"last_stand_day": {"day": "", "sparks": 0},   # M008: Last Stand gives no Sparks; kept so a future cap has a home
		"settings": {"master": 0.8, "music": 0.6, "sfx": 0.8, "quality": "low" if OS.has_feature("mobile") else "high", "perf_patch": 1, "shake": true, "speed": 1.0, "mech_doctrine": "standard",
			"tutorial": true, "hints": true, "motion": true,   # M006: motion = the unit motion layer (off = reduced motion)
			"ui_sounds": false},   # M007: button tap sounds (off by default — the tap "cling" was removed)
		"stats": {"battles": 0, "victories": 0, "defeats": 0, "kills": 0, "escorts": 0,   # M006: escorts = supply barges delivered
			"salvaged": 0, "reclaimed": 0, "heroic_clears": 0,   # M007: wrecks salvaged / lost to reclamation, Heroic clears
			"tears_closed": 0, "wisps_shot": 0, "last_stand_runs": 0},   # M008
	}


static func load_profile() -> Dictionary:
	var p = _read(path)
	if p.is_empty():
		p = _read(path + ".bak")
	if p.is_empty():
		return default_profile()
	return migrate(p)


static func save_profile(p: Dictionary) -> bool:
	if FileAccess.file_exists(path):
		var old = FileAccess.get_file_as_string(path)
		var b = FileAccess.open(path + ".bak", FileAccess.WRITE)
		if b:
			b.store_string(old)
			b.close()
	var f = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: cannot write " + path)
		return false
	f.store_string(JSON.stringify(p, "\t"))
	f.close()
	return true


static func _read(file: String) -> Dictionary:
	if not FileAccess.file_exists(file):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(file))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


## Fills any keys missing from older saves without discarding progress.
static func migrate(p: Dictionary) -> Dictionary:
	# M002b: phones that saved "high" before the performance patch existed start on the fast preset once
	if p.has("settings") and p.settings is Dictionary and not p.settings.has("perf_patch"):
		p.settings["perf_patch"] = 1
		if OS.has_feature("mobile") or OS.has_feature("android"):
			p.settings["quality"] = "low"
	# M005: the guided tutorial is on by default for new saves only — a player who already has a
	# save from an earlier milestone has played those stages, so it starts switched off for them.
	if not p.has("stars") and p.has("settings") and p.settings is Dictionary and not p.settings.has("tutorial"):
		p.settings["tutorial"] = false
	var d = default_profile()
	for k in d.keys():
		if not p.has(k):
			p[k] = d[k]
	for k in d.settings.keys():
		if not p.settings.has(k):
			p.settings[k] = d.settings[k]
	for k in d.stats.keys():
		if not p.stats.has(k):
			p.stats[k] = d.stats[k]
	# JSON numbers come back as floats; normalise ints we compare against
	p.sparks = int(p.sparks)
	var tiers: Array = []
	for t in p.open_tiers:
		tiers.append(int(t))
	p.open_tiers = tiers
	var acts: Array = []
	for a in p.acts_revealed:
		acts.append(int(a))
	p.acts_revealed = acts
	for k in p.stars.keys():
		var arr = p.stars[k]
		if not (arr is Array) or arr.size() != 3:
			p.stars[k] = [true, false, false]
	# M007 Heroic records: keep only well-formed entries
	if not (p.heroic is Dictionary):
		p.heroic = {}
	for hk in p.heroic.keys():
		var he = p.heroic[hk]
		if not (he is Dictionary) or not (he.get("stars") is Array) or he.stars.size() != 3:
			p.heroic[hk] = {"stars": [true, false, false], "clears": 1, "best_time": 0.0}
		else:
			he["clears"] = int(he.get("clears", 1))
	# M008: Last Stand records, cosmetics and the completion data (repair malformed entries)
	if not (p.last_stand is Dictionary):
		p.last_stand = {}
	for ak in p.last_stand.keys():
		var r = p.last_stand[ak]
		if not (r is Dictionary):
			p.last_stand[ak] = {"best_wave": 0, "best_score": 0, "best_kills": 0, "runs": 0}
		else:
			for f in ["best_wave", "best_score", "best_kills", "runs"]:
				r[f] = int(r.get(f, 0))
	if not (p.cosmetics is Dictionary):
		p.cosmetics = d.cosmetics.duplicate(true)
	for ck in d.cosmetics.keys():
		if not p.cosmetics.has(ck):
			p.cosmetics[ck] = d.cosmetics[ck]
	if not (p.units_used is Array):
		p.units_used = []
	p.ending_seen = bool(p.ending_seen)
	for name in p.loadouts.keys():
		var arr: Array = p.loadouts[name]
		while arr.size() < 12:
			arr.append("")
		p.loadouts[name] = arr.slice(0, 12)
	p.version = SAVE_VERSION
	return p


static func wipe() -> void:
	for f in [path, path + ".bak"]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
