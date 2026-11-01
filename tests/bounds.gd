extends Node
## Measures the visual bounds of every unit art in many poses (needs a display: xvfb-run) and
## writes res://data/art_bounds.json — the pose cache uses them to size its atlas cells.
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tests/bounds.tscn

const SZ := 1400
const ORIGIN := Vector2(700, 1000)


class Probe extends Node2D:
	var art = ""
	var pose = {}
	func _draw() -> void:
		Painter.draw_unit(self, art, pose)


func _ready() -> void:
	Audio.enabled = false
	var arts: Array = ["dwarf_hold", "undead_citadel"]
	for k in Registry.aux.keys():
		arts.append(String(k))
	for e in Registry.implemented_dwarves() + Registry.implemented_undead() + Registry.bosses:
		var a = String(Registry.combat_def(e.id).get("art", ""))
		if a != "" and not a in arts:
			arts.append(a)
	if not "mine_maw" in arts:
		arts.append("mine_maw")
	# M006b: --machines re-measures only war frames, vehicles, aircraft, airships and corrupted machines
	# and merges the result into the existing file
	var machines_only = "--machines" in OS.get_cmdline_user_args()
	var out = {}
	if machines_only:
		var old = JSON.parse_string(FileAccess.get_file_as_string("res://data/art_bounds.json"))
		if old is Dictionary:
			out = old
		var keep: Array = []
		for a0 in arts:
			var fam = String(ArtKit.params(a0).get("fam", "")) if ArtKit.has(a0) else ""
			if ArtMechs.has(a0) or fam in ["veh", "air", "ship", "corrupt"] or a0 in ["copperback", "brasshound"]:
				keep.append(a0)
		arts = keep
		print("BOUNDS machines: %d arts" % arts.size())
	var vp = SubViewport.new()
	vp.size = Vector2i(SZ, SZ)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var pr = Probe.new()
	pr.position = ORIGIN
	vp.add_child(pr)
	var poses: Array = []
	for st in ["idle", "move"]:
		for w in 8:
			for at in [0.0, 1.0]:
				poses.append({"state": st, "walk": w * TAU / 8.0, "t": w * 0.37, "atk": at, "atk2": at, "atk3": at, "windup": 0.0, "engage": 1.0})
	for extra in [{"windup": 1.0}, {"ability_anim": 1.0}, {"aim0": -1.5, "aim1": -1.5, "aim2": -1.5}, {"aim0": 0.6, "aim1": 0.6, "aim2": 0.6},
			{"hp_frac": 0.1}, {"reload": 1.0}, {"special": 1.0}, {"state": "burrowed"}, {"state": "exposed", "special": 1.0}, {"recoil": 1.0}, {"hurt": 1.0},
			{"atk": 0.5, "windup": 0.5}, {"spin": 2.0, "heat_lock_t": 1.0}, {"stun_t": 1.0, "brace_t": 1.0},
			# M004 gag timeline (hats in flight, hops, casings, vent steam) and idle fidgets
			{"gag": 0.875, "atk": 0.78}, {"gag": 0.75, "atk": 0.56}, {"gag": 0.625, "atk": 0.34}, {"gag": 0.5, "atk": 0.12}, {"gag": 0.375}, {"gag": 0.25},
			{"gag": 0.5, "state": "move", "walk": 1.6}, {"hurt": 1.0, "gag": 0.5}, {"t": 3.3}, {"t": 4.5}]:
		var p = {"state": "idle", "t": 0.3, "walk": 0.0, "atk": 0.0, "engage": 1.0}
		p.merge(extra, true)
		poses.append(p)
	for art in arts:
		var r = Rect2()
		var first = true
		for p in poses:
			pr.art = art
			pr.pose = p
			pr.queue_redraw()
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			var img: Image = vp.get_texture().get_image()
			var used: Rect2i = img.get_used_rect()
			if used.size.x <= 0:
				continue
			var rr = Rect2(Vector2(used.position) - ORIGIN, Vector2(used.size))
			r = rr if first else r.merge(rr)
			first = false
		r = r.grow(4.0)
		var keys: Array = Painter.used_keys.get(art, {}).keys()
		keys.sort()
		out[art] = [snappedf(r.position.x, 1.0), snappedf(r.position.y, 1.0), snappedf(r.size.x, 1.0), snappedf(r.size.y, 1.0), keys]
		print("BOUNDS %s %s" % [art, str(out[art])])
	var f = FileAccess.open("res://data/art_bounds.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "  ", true))
	f.close()
	print("BOUNDS_DONE %d arts" % out.size())
	get_tree().quit()
