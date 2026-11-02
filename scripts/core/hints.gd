class_name Hints
extends RefCounted
## M005 first-encounter hints: one short, dismissible line naming a counter the first time a kind of
## threat or a hazard appears. The same lines are reused as "Counter:" notes in the Compendium and as
## "recommended counters" in the stage drawer for cleared stages. Text is deliberately brief.

const TEXT := {
	"flyer": "Flak shreds flyers — deploy a Flak Crew.",
	"shrieker": "Ranged flyers hang back — interceptors chase them down.",
	"bone": "Bone shrugs off bullets — blast it with grenades and cannons.",
	"armored": "Heavy hides turn bullets — bring cannons and armour-piercers.",
	"giant": "Giants hit hard — hold them with shields, kill them with cannons.",
	"burrower": "Burrowers strike from below — Scout Gyros reveal them.",
	"corrupted": "Corrupted machines are still dwarven iron — cannons and AP rounds break them.",
	"healer": "Priests mend the dead — kill them first.",
	"aura": "Heralds and bell keepers empower the dead — target them early.",
	"beacon": "Kill the beacon to stop the buffs.",
	"anti_air": "Anti-air guards their sky — break it from the ground before you fly in.",
	"siege": "Siege engines lob from behind the line — artillery and bombers reach them.",
	"barricade": "Barricades stall your push — cannons and sappers knock them down.",
	"exploder": "Some dead burst when they fall — keep the line spread.",
	"haz_miasma": "Machines ignore miasma — tanks and walkers hold the poison ground.",
	"haz_bog": "The bog slows everyone — artillery fires over it, aircraft fly past it.",
	"haz_rockfall": "Watch the dust — rocks fall where it gathers.",
	"haz_gale": "Gales push aircraft back — lean on ground fire while it blows.",
	"high_flyer": "High flyers only fear flak, AA guns, interceptors and airships.",
	"haz_thermals": "Thermals lift or sink flyers a band — fly around the shimmering columns.",
	"haz_lightning_storm": "Lightning hits the tallest thing nearby — spread out your aircraft and walkers.",
	# M007 Act IV
	"reclaimer": "Corruptors raise your wrecks as their machines — kill them, or send salvage crews to clear the wrecks first.",
	"haz_furnace_vents": "Vents glow before they erupt — machines shrug off half the fire; step between the bursts.",
	"haz_slag_flow": "Slag creeps across the lane — it burns and slows the ground; aircraft fly over it.",
	"haz_steam_leak": "A burst pipe refills your Steam while a machine stands in it — but it scalds everyone inside.",
	"haz_rockfall_gantry": "Girders groan before they fall — clear the shadow on the lane.",
	# M008 Act V
	"haz_rift_tears": "A tear spills the dead when it closes — shoot it shut first; artillery reaches it anywhere.",
	"haz_eclipse": "In the eclipse only lit units see far — scouts and spotters carry light for the units around them.",
	"haz_soul_storm": "Soul wisps heal the dead and burn your line — flak and anti-air shoot them down.",
	"obelisk": "Rift obelisks shield the dead around them — break the obelisks to break the ward.",
	"colossus": "A colossus can take a whole army's fire — hold it with heavy armour while every gun focuses it.",
}

const BAND_NAMES := ["low", "mid", "high"]


## M006: a unit's altitude band name ("" for ground units) and the bands its weapons can hit.
static func band_of(st: Dictionary) -> String:
	if String(st.get("domain", "ground")) != "air":
		return ""
	return String(st.get("band", "mid"))


static func can_hit(st: Dictionary) -> String:
	var reach = -1
	var ground = false
	for w in st.get("weapons", []):
		var tg = String(w.get("targets", "ground"))
		if tg != "air":
			ground = true
		if tg != "ground":
			reach = maxi(reach, int({"low": 0, "mid": 1, "high": 2}.get(String(w.get("reach", "high")), 2)))
	var parts: Array = []
	if ground:
		parts.append("ground")
	for i in reach + 1:
		parts.append(BAND_NAMES[i])
	return ", ".join(parts) if not parts.is_empty() else "nothing"


## The hint tag for an undead unit (or "" when it needs no special advice).
static func tag_for(uid: String) -> String:
	var e: Dictionary = Registry.entry(uid)
	if e.is_empty() or e.get("faction", "undead") != "undead":
		return ""
	var st: Dictionary = e.get("stats", {}) if e.get("stats") != null else {}
	var cat = String(e.get("category", ""))
	var beh = String(st.get("behavior", ""))
	if cat == "corrupted":
		return "corrupted"
	if st.get("reclaims", false):
		return "reclaimer"
	if uid == "rift_obelisk":
		return "obelisk"
	if st.get("giant_class", "") == "colossus":
		return "colossus"
	if st.get("static", false):
		if st.has("aura"):
			return "beacon"
		if not st.get("weapons", []).is_empty() and st.weapons.all(func(w): return w.get("targets", "") == "air"):
			return "anti_air"
		return "barricade"
	if cat == "siege":
		if not st.get("weapons", []).is_empty() and st.weapons.any(func(w): return w.get("targets", "") in ["air", "both"]) and beh == "artillery":
			return "anti_air"
		return "siege"
	if beh == "burrower":
		return "burrower"
	if beh == "repair":
		return "healer"
	if st.has("aura"):
		return "aura"
	if e.get("domain", "ground") == "air":
		if String(st.get("band", "mid")) == "high":
			return "high_flyer"
		return "shrieker" if beh == "shrieker" else "flyer"
	if beh == "giant":
		return "giant"
	if st.has("death_burst"):
		return "exploder"
	var armor = String(st.get("armor", "flesh"))
	if armor == "bone" or armor == "bone_shield":
		return "bone"
	if armor == "heavy" or armor == "hulk":
		return "armored"
	return ""


static func text_for_unit(uid: String) -> String:
	return String(TEXT.get(tag_for(uid), ""))


## Up to n distinct counter lines for a stage's known lineup and hazards (cleared stages only).
static func stage_counters(st: Dictionary, n: int = 3) -> Array:
	var tags: Array = []
	for h in WaveDirector.hazard_list(st):
		tags.append(hazard_tag(h))
	for e in st.get("enemy_roster", []):
		var t = tag_for(String(e))
		if t != "" and not t in tags:
			tags.append(t)
	var out: Array = []
	for t in tags:
		if TEXT.has(t) and out.size() < n:
			out.append(TEXT[t])
	return out


## The hint tag for a hazard (collapsing gantries are a rockfall variant with their own line).
static func hazard_tag(h: Dictionary) -> String:
	var k = String(h.get("kind", ""))
	if k == "rockfall" and String(h.get("variant", "")) == "gantry":
		return "haz_rockfall_gantry"
	return "haz_" + k


## The drawer name of a hazard.
static func hazard_name(h: Dictionary) -> String:
	if String(h.get("kind", "")) == "rockfall" and String(h.get("variant", "")) == "gantry":
		return "Collapsing gantries"
	return String(h.get("kind", "")).replace("_", " ").capitalize()


static func hazard_desc(h: Dictionary) -> String:
	if String(h.get("kind", "")) == "rockfall" and String(h.get("variant", "")) == "gantry":
		return "Girders groan, swing and drop where their shadow falls — bigger hits, smaller area, a longer warning."
	return String(HAZARD_DESC.get(String(h.get("kind", "")), ""))


const HAZARD_DESC := {
	"rockfall": "Rocks fall from the roof where dust gathers.",
	"gale": "Gales push aircraft back toward your lines.",
	"miasma": "Poison clouds drift over the lane; machines are immune.",
	"bog": "Mire slows every ground unit standing in it.",
	"thermals": "Updraft and downdraft columns lift or sink flyers a band and speed or slow aircraft.",
	"lightning_storm": "Telegraphed lightning hits the tallest thing nearby — flyers first, then walkers and spires — on both sides.",
	"furnace_vents": "Fixed vents glow, then erupt with fire in turn — ground units on both sides; machines take half.",
	"slag_flow": "A molten river creeps across part of the lane from time to time, burning and slowing ground units.",
	"steam_leak": "A burst pipe: your machines standing in it refill Steam Pressure, but everyone inside is scalded.",
	"rift_tears": "Rifts crack open at random along the lane, then spill a handful of the dead — unless you destroy the tear first.",
	"eclipse": "From time to time the dead sun goes out: ranged weapons on both sides lose a quarter of their reach, except near a light.",
	"soul_storm": "Soul wisps drift out of the rift: they heal the undead they pass and burn the dwarves below. Flak brings them down.",
}
