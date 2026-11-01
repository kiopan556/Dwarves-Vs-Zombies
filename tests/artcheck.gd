extends Node
## M006b visual acceptance (needs a display: xvfb-run). For every war frame, vehicle, aircraft, airship and
## corrupted machine it renders poses and checks:
##   - the drawing stays inside the measured bounds in data/art_bounds.json (the pose cache cell),
##   - running gear / propellers change between walk or t samples (something moves),
##   - war frames: the pixels differ between stance, wind-up, strike and recovery,
## and reports the live-draw cost (GDScript time per draw_unit) per art.
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tests/artcheck.tscn [-- --cost_only]

const SZ := 1000
const ORIGIN := Vector2(500, 700)


class Probe extends Node2D:
	var art = ""
	var pose = {}
	var us = 0
	func _draw() -> void:
		var t0 = Time.get_ticks_usec()
		Painter.draw_unit(self, art, pose)
		us = Time.get_ticks_usec() - t0


func _machine_arts() -> Array:
	var arts: Array = []
	for e in Registry.implemented_dwarves() + Registry.implemented_undead() + Registry.bosses:
		var a = String(Registry.combat_def(e.id).get("art", ""))
		if a == "" or a in arts:
			continue
		var fam = String(ArtKit.params(a).get("fam", "")) if ArtKit.has(a) else ""
		if ArtMechs.has(a) or fam in ["veh", "air", "ship", "corrupt"] or a in ["copperback", "brasshound"]:
			arts.append(a)
	return arts


func _ready() -> void:
	Audio.enabled = false
	var cost_only = "--cost_only" in OS.get_cmdline_user_args()
	var bounds: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/art_bounds.json"))
	var vp = SubViewport.new()
	vp.size = Vector2i(SZ, SZ)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var pr = Probe.new()
	pr.position = ORIGIN
	vp.add_child(pr)
	var out_of_bounds: Array = []
	var still: Array = []
	var flat_mech: Array = []
	var costs: Array = []
	for art in _machine_arts():
		var mech = ArtMechs.has(art)
		var fam = "mech" if mech else (String(ArtKit.params(art).get("fam", "")) if ArtKit.has(art) else "legacy")
		var samples: Dictionary = {}
		var poses = {
			"walk_a": {"state": "move", "walk": 0.0, "t": 0.0}, "walk_b": {"state": "move", "walk": TAU / 4.0, "t": 0.16},
			"stance": {"state": "idle", "t": 0.3, "engage": 0.0}, "windup": {"state": "idle", "t": 0.3, "engage": 1.0, "windup": 1.0},
			"strike": {"state": "idle", "t": 0.3, "engage": 1.0, "atk": 1.0, "gag": 1.0}, "recover": {"state": "idle", "t": 0.3, "engage": 1.0, "atk": 0.25, "gag": 0.45},
			"damaged": {"state": "move", "walk": 1.0, "t": 0.48, "hp_frac": 0.2, "atk": 0.6},
		}
		var us_total = 0
		for k in poses:
			pr.art = art
			pr.pose = poses[k]
			pr.queue_redraw()
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			us_total += pr.us
			if cost_only:
				continue
			var img: Image = vp.get_texture().get_image()
			samples[k] = img
			var used: Rect2i = img.get_used_rect()
			if bounds.has(art) and used.size.x > 0:
				var b: Array = bounds[art]
				var cell = Rect2(float(b[0]), float(b[1]), float(b[2]), float(b[3])).grow(2.0)
				var rr = Rect2(Vector2(used.position) - ORIGIN, Vector2(used.size))
				if not cell.encloses(rr):
					out_of_bounds.append("%s/%s %s vs %s" % [art, k, str(rr), str(cell)])
		costs.append([us_total / float(poses.size()), art])
		if cost_only:
			continue
		if samples.walk_a.get_data() == samples.walk_b.get_data():
			still.append(art)
		if mech:
			var seq = ["stance", "windup", "strike", "recover"]
			for i in seq.size() - 1:
				if samples[seq[i]].get_data() == samples[seq[i + 1]].get_data():
					flat_mech.append("%s:%s>%s" % [art, seq[i], seq[i + 1]])
	costs.sort()
	costs.reverse()
	var total = 0.0
	for c in costs:
		total += c[0]
	print("ARTCHECK arts=%d" % costs.size())
	print("ARTCHECK cost mean %.1f us; slowest: %s" % [total / maxf(1.0, costs.size()), str(costs.slice(0, 8))])
	for c in costs:
		print("COST %s %.1f" % [c[1], c[0]])
	if not cost_only:
		print("ARTCHECK %s inside measured bounds: out=%s" % ["PASS" if out_of_bounds.is_empty() else "FAIL", str(out_of_bounds.slice(0, 6))])
		print("ARTCHECK %s running gear / props move between walk and t samples: still=%s" % ["PASS" if still.is_empty() else "FAIL", str(still)])
		print("ARTCHECK %s war frames differ stance > wind-up > strike > recovery: flat=%s" % ["PASS" if flat_mech.is_empty() else "FAIL", str(flat_mech)])
	get_tree().quit()
