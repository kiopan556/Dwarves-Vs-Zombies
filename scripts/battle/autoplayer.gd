class_name AutoCommander
extends RefCounted
## Heuristic commander used by the automated test runner (and the sandbox "Auto-commander"
## toggle) to play stages end-to-end. It only uses the loadout it is given, pays normal costs,
## saves gold for the unit it needs most, and counters air, armor, swarms and bosses.

var think_t = 0.0
var verbose = false
var events: Array = []


func _has(b: Battle, uid: String) -> bool:
	return uid in b.loadout


# M005: role-based fallbacks so the commander also fields units it has no hand-written rule for
# (every blueprint from Act I-b onward). M001 ids keep their hand-tuned rules and come first.
const KNOWN := ["shieldbearer", "tunnel_militia", "miner_rig", "copperback_light_tank", "brasshound_armored_car", "boiler_stomper",
	"flak_crew", "dwarven_flying_machine", "ironwing_gunship", "ironcloud", "light_field_cannon", "organ_gun", "ironhold_rifleman",
	"grenadier", "blunderbussier", "field_mechanic", "scout_gyro", "bombard_gyro"]
const G_FRONT := ["frontline_defender", "melee_damage", "armored_vehicle", "mechanical_walker"]
const G_AA := ["anti_air", "mobile_anti_air", "aerial_interceptor", "multirole_gunship"]
const G_ART := ["anti_armor", "large_siege", "indirect_artillery", "ranged_artillery", "armored_vehicle"]
const G_RNG := ["rifle_infantry", "anti_swarm", "indirect_artillery", "tactical_bomber", "multirole_gunship", "airship_artillery"]
var _gen_cache: Dictionary = {}
## Role-based fallbacks on/off. The stage sims switch them on from Act II: Act I keeps the exact
## commander it was tuned with in M001-M004, so its results stay comparable across milestones.
var generic := true
## M007: Act IV armies are built around 500-1,100 Gold war machines. A "saver" commander (Act IV sims) holds
## its Gold for a heavy machine every so often instead of spending everything on the cheapest unit in reach,
## as a real player would. Off for Acts I-III, so their sims are unchanged.
var saver := false
var _last_heavy_t := 0.0


func _generic(b: Battle, roles: Array, desc: bool = false) -> Array:
	if not generic:
		return []
	var key = ",".join(roles) + ("+" if desc else "-")
	if _gen_cache.has(key):
		return _gen_cache[key]
	var out: Array = []
	for uid in b.loadout:
		if uid in KNOWN:
			continue
		var e = Registry.entry(uid)
		var r2 = e.get("role2")
		if String(e.get("role", "")) in roles or (r2 != null and String(r2) in roles):
			out.append(uid)
	# cheaper first (so saving gold never starves the line), or stronger first when gold is plentiful
	out.sort_custom(func(x, y):
		var gx = float(Registry.combat_def(x).get("gold", 0))
		var gy = float(Registry.combat_def(y).get("gold", 0))
		return gx > gy if desc else gx < gy)
	_gen_cache[key] = out
	return out


## Power contribution of a unit the hand-written rules don't know: [front, aa, rng, art].
func _gen_power(u) -> Array:
	var role = String(Registry.entry(u.id).get("role", ""))
	var hpk: float = u.hp / u.max_hp
	var heavy = u.cls in ["vehicle", "walker"]
	match role:
		"frontline_defender", "melee_damage":
			return [(4.0 if heavy else 2.0) * hpk, 0.0, 0.0, 0.0]
		"armored_vehicle", "mechanical_walker":
			return [4.0 * hpk, 0.0, 1.0, 1.0]
		"anti_swarm":
			return [3.0 * hpk if heavy else 0.0, 0.0, 2.0 if heavy else 1.5, 0.0]
		"rifle_infantry":
			return [0.0, 0.0, 1.2, 0.0]
		"indirect_artillery", "ranged_artillery", "large_siege":
			return [0.0, 0.0, 1.5, 1.0]
		"anti_armor":
			return [0.0, 0.0, 1.0, 1.5]
		"anti_air", "mobile_anti_air":
			return [0.0, 2.5, 0.0, 0.0]
		"aerial_interceptor":
			return [0.0, 1.5 * hpk, 0.0, 0.0]
		"multirole_gunship", "airship_artillery":
			return [0.0, 2.0, 3.0, 0.5]
		"tactical_bomber":
			return [0.0, 0.0, 2.0, 0.5]
	return [0.0, 0.0, 0.0, 0.0]


func step(b: Battle, dt: float) -> void:
	think_t -= dt
	if think_t > 0.0 or b.over:
		return
	think_t = 0.4
	var e_air = 0.0
	var e_ground = 0.0
	var e_armor = 0
	var e_struct = 0
	var e_bone = 0
	var near_base = 0
	for e in b.by_side[1]:
		if not e.alive or e.is_stronghold:
			continue
		var w = float(e.def.get("threat", 1.0))
		if e.domain == "air":
			e_air += w
		else:
			if e.is_structure:
				e_struct += 1
				continue
			e_ground += w
			if e.armor in Combat.ARMORED_CLASSES:
				e_armor += 1
			if e.armor == "bone" or e.armor == "bone_shield":
				e_bone += 1
			if e.position.x < Combat.DWARF_BASE_X + 420.0:
				near_base += 1
	var cnt = {}
	var power_front = 0.0
	var power_aa = 0.0
	var power_rng = 0.0
	var power_art = 0.0
	var machines = 0
	for u in b.by_side[0]:
		if not u.alive or u.is_stronghold:
			continue
		cnt[u.id] = int(cnt.get(u.id, 0)) + 1
		if u.cls in ["vehicle", "walker", "airship"]:
			machines += 1
		var hpk: float = u.hp / u.max_hp
		match u.id:
			"shieldbearer", "tunnel_militia":
				power_front += (2.0 if u.id == "shieldbearer" else 1.0) * hpk
			"miner_rig", "copperback_light_tank", "brasshound_armored_car":
				power_front += 3.0 * hpk
				power_art += 1.0 if u.id == "copperback_light_tank" else 0.0
			"boiler_stomper":
				power_front += 5.0 * hpk
			"flak_crew":
				power_aa += 2.5
			"dwarven_flying_machine":
				power_aa += 1.5 * hpk
			"ironwing_gunship", "ironcloud":
				power_aa += 2.0
				power_rng += 3.0
			"light_field_cannon":
				power_art += 1.0
				power_rng += 1.0
			"organ_gun":
				power_rng += 2.5
			"ironhold_rifleman", "grenadier", "blunderbussier":
				power_rng += 1.0
			_:
				if generic and not u.id in KNOWN:
					var gp = _gen_power(u)
					power_front += gp[0]
					power_aa += gp[1]
					power_rng += gp[2]
					power_art += gp[3]
	# economy: early mine levels, more when the line is stable
	var mc = b.mine_upgrade_cost()
	if mc > 0 and near_base <= 2:
		if (b.mine_level < 2 and b.gold >= mc) or (b.gold >= mc + 60 and power_front >= 3.0 and near_base == 0):
			b.upgrade_mine()
			return
	# M005: the fallback options deploy whatever is affordable, so explicitly save for the first two
	# mine levels while the line is quiet (the old rules got there by accident, by saving for big units)
	if generic and mc > 0 and b.mine_level < 2 and near_base == 0 and power_front >= 2.0 and b.time > 15.0:
		return
	if near_base >= 4 and b.can_vent():
		b.steam_vent()
	if b.can_overdrive() and machines >= 2 and e_ground > 8:
		b.overdrive()
	var boss_up: bool = b.boss != null and is_instance_valid(b.boss) and b.boss.alive
	if saver:
		var urgent = near_base >= 3 or b.dwarf_base.hp < b.dwarf_base.max_hp * 0.6 or power_front < 2.0 or (e_air > 8.0 and power_aa < 1.5)
		var heavy: Array = []
		for uid in b.loadout:
			var d = Registry.combat_def(uid)
			if float(d.get("gold", 0)) >= 450.0 and d.get("domain", "ground") == "ground" and not d.get("salvages", false):
				heavy.append(uid)
		heavy.sort_custom(func(x, y): return int(cnt.get(x, 0)) < int(cnt.get(y, 0)))
		for uid in heavy:
			if b.can_deploy(uid) == "":
				b.deploy(uid)
				_last_heavy_t = b.time
				return
		if not heavy.is_empty() and not urgent and b.time - _last_heavy_t > 20.0 and b.time > 40.0:
			return   # saving up for the next war machine
	var wants: Array = []
	if near_base >= 3 and power_front < 2.0:
		wants.append(["tunnel_militia", "shieldbearer"] + _generic(b, ["frontline_defender"]))
	var n_air_units = int(cnt.get("dwarven_flying_machine", 0)) + int(cnt.get("ironwing_gunship", 0))
	var n_flak = int(cnt.get("flak_crew", 0))
	# M005: generic anti-air and interceptors count toward the same quotas as the M001 ones
	for uid in _generic(b, ["anti_air", "mobile_anti_air"]):
		n_flak += int(cnt.get(uid, 0))
	for uid2 in _generic(b, ["aerial_interceptor", "multirole_gunship"]):
		n_air_units += int(cnt.get(uid2, 0))
	if e_air > 0.0 and power_aa < minf(e_air * 0.6 + 1.0, 18.0):
		if n_flak < 2:
			wants.append(["flak_crew"] + _generic(b, ["anti_air", "mobile_anti_air"]))
		elif n_air_units < 8:
			wants.append(["dwarven_flying_machine", "flak_crew", "ironwing_gunship"] + _generic(b, G_AA))
		elif n_flak < 4:
			wants.append(["flak_crew"] + _generic(b, ["anti_air", "mobile_anti_air"]))
	if power_front < maxf(2.0, e_ground * 0.35):
		wants.append((["boiler_stomper", "miner_rig"] + _generic(b, G_FRONT, true) + ["shieldbearer"]) if b.gold > 200 else (["shieldbearer", "tunnel_militia"] + _generic(b, ["frontline_defender"])))
	if boss_up and int(cnt.get("scout_gyro", 0)) < 1:
		wants.append(["scout_gyro"])
	if generic and boss_up and b.boss.domain == "ground" and b.gold > 150.0 and power_art < 6.0:
		# M005: against a boss, field the heaviest guns owned rather than feeding the front into it
		wants.append(_generic(b, ["anti_armor", "large_siege", "indirect_artillery", "armored_vehicle"], true))
	if (e_armor + e_struct) > power_art or (boss_up and power_art < 3.0):
		wants.append(["copperback_light_tank", "light_field_cannon"] + _generic(b, G_ART))
	if power_rng < maxf(3.0, e_ground * 0.45):
		if e_bone >= 3:
			wants.append(["grenadier", "light_field_cannon"] + _generic(b, ["indirect_artillery", "anti_swarm"]) + ["ironhold_rifleman"])
		elif e_ground >= 10:
			wants.append(["organ_gun", "grenadier"] + _generic(b, ["anti_swarm", "indirect_artillery"]) + ["ironhold_rifleman"])
		else:
			wants.append(["ironhold_rifleman", "grenadier"] + _generic(b, ["rifle_infantry", "anti_swarm"]))
	# M007: wrecks on the field and nobody to clear them -> send a salvage unit (Act IV only: no wrecks elsewhere)
	if not b.wrecks.is_empty():
		var salv = 0
		for u2 in b.by_side[0]:
			if u2.alive and u2.is_salvager:
				salv += 1
		if salv < 1 + int(b.wrecks.size() >= 3):
			var sl: Array = []
			for uid3 in b.loadout:
				if Registry.combat_def(uid3).get("salvages", false):
					sl.append(uid3)
			sl.sort_custom(func(x, y): return float(Registry.combat_def(x).get("gold", 0)) < float(Registry.combat_def(y).get("gold", 0)))
			# a player who sees the priests closing on a wreck sends the recovery crew first
			if b.wrecks.any(func(w): return w.chan != null) or b.wrecks.size() >= 2:
				wants.push_front(sl)
			else:
				wants.append(sl)
	if int(cnt.get("field_mechanic", 0)) < 1 and machines + int(cnt.get("light_field_cannon", 0)) >= 3:
		wants.append(["field_mechanic"] + _generic(b, ["repair_support"]))
	if b.gold > 260:
		wants.append(["ironcloud", "ironwing_gunship"] + _generic(b, G_FRONT + G_RNG, true) + ["boiler_stomper", "copperback_light_tank", "bombard_gyro", "miner_rig", "organ_gun", "light_field_cannon", "brasshound_armored_car", "shieldbearer", "ironhold_rifleman"])
	for opts in wants:
		for uid in opts:
			if not _has(b, uid):
				continue
			var why = b.can_deploy(uid)
			if why == "":
				b.deploy(uid)
				if verbose:
					events.append("%.0fs deploy %s" % [b.time, uid])
				return
			if why == "Cooling down" or why.ends_with("Steam") or why == "Army at capacity":
				continue
			# M005: only save for a unit that is affordable within a few seconds; otherwise fall through
			# to the next option instead of starving the line while gold trickles in
			var need = float(Registry.combat_def(b._deploy_def_id(uid)).get("gold", 0)) - b.gold
			if generic and need > (b.gold_rate + Battle.MINE_BONUS * b.mine_level) * 6.0:
				continue
			# affordable soon: save gold for the unit we need most
			return
