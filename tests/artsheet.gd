extends Node2D
## M006b visual check: a labelled grid of arts in one pose (live drawing, no pose cache).
##   xvfb-run godot --path . res://tests/artsheet.tscn -- --arts=a,b,c --cols=4 --pose=state:move,walk:1.2,atk:1 --out=/tmp/s.png
##   --group=tanks|aircraft|airships|mechs|giants picks the arts from the roster.

var args = {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv = a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	Audio.enabled = false
	var bg = ColorRect.new()
	bg.color = Color(String(args.get("bg", "8a9aac")))
	bg.size = Vector2(1280, 720)
	add_child(bg)
	var arts: Array = []
	if args.has("group"):
		var g = String(args.group)
		for e in Registry.implemented_dwarves() + Registry.implemented_undead():
			var d = Registry.combat_def(e.id)
			var c = String(d.get("cls", ""))
			if (g == "tanks" and c == "vehicle") or (g == "aircraft" and c == "aircraft") or (g == "airships" and c == "airship") \
				or (g == "mechs" and c == "walker") or (g == "corrupted" and String(e.get("category", "")) == "corrupted"):
				if not String(d.art) in arts:
					arts.append(String(d.art))
		if g == "airships":
			arts.append("supply_barge")
		var pg = int(args.get("page", "0"))
		var per = int(args.get("per", "12"))
		arts = arts.slice(pg * per, pg * per + per)
	else:
		arts = String(args.get("arts", "ironclad_walker")).split(",")
	if args.has("poses"):
		await _pose_grid(arts)
		return
	var pose = {"state": "idle", "t": 0.4, "walk": 0.0, "atk": 0.0, "atk2": 0.0, "atk3": 0.0, "aim0": -0.1, "aim1": -0.4, "aim2": -0.9, "engage": 1.0, "hp_frac": 1.0, "ammo": 4, "special": 0.5}
	for kv in String(args.get("pose", "")).split(","):
		if ":" in kv:
			var k = kv.get_slice(":", 0)
			var v = kv.get_slice(":", 1)
			pose[k] = v if k == "state" else float(v)
	var cols = int(args.get("cols", "4"))
	var rows = int(ceil(float(arts.size()) / cols))
	var cw = 1280.0 / cols
	var rh = 700.0 / maxf(rows, 1)
	for i in arts.size():
		var art: String = arts[i]
		var h = Painter.art_height(art)
		var air = Painter.is_air_art(art) or Registry.combat_def(art).get("domain", "") == "air" or art == "supply_barge"
		var sc = minf(float(args.get("maxsc", "2.2")), minf((rh - 30.0) / maxf(h, 10.0), (cw - 20.0) / maxf(h * 1.6, 10.0)))
		var cx = cw * (i % cols) + cw * 0.5
		var cy = rh * (i / cols) + rh - 22.0
		var sp = Probe.new()
		sp.art = art
		sp.pose = pose.duplicate()
		sp.position = Vector2(cx, cy - (h * sc * 0.45 if air else 0.0))
		sp.scale = Vector2(sc, sc)
		add_child(sp)
		var lb = Label.new()
		lb.text = art
		lb.add_theme_font_size_override("font_size", 12)
		lb.add_theme_color_override("font_color", Color(0.05, 0.05, 0.08))
		lb.position = Vector2(cx - cw * 0.45, cy + 2)
		add_child(lb)
	for k in 6:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(args.get("out", "/tmp/sheet.png"))
	get_tree().quit()


## Rows = arts, columns = named poses ("--poses=stance=state:idle;combat=engage:1,...").
func _pose_grid(arts: Array) -> void:
	var cols: Array = String(args.poses).split(";")
	var cw = 1280.0 / cols.size()
	var rh = 700.0 / arts.size()
	for ci in cols.size():
		var name = String(cols[ci]).get_slice("=", 0)
		var lb = Label.new()
		lb.text = name
		lb.add_theme_font_size_override("font_size", 14)
		lb.add_theme_color_override("font_color", Color(0.05, 0.05, 0.08))
		lb.position = Vector2(cw * ci + 6, 2)
		add_child(lb)
	for r in arts.size():
		var art: String = arts[r]
		var h = Painter.art_height(art)
		var air = Painter.is_air_art(art) or Registry.combat_def(art).get("domain", "") == "air" or art == "supply_barge"
		var sc = minf(float(args.get("maxsc", "3.0")), minf((rh - 14.0) / maxf(h, 10.0), (cw - 10.0) / maxf(h * float(args.get("wf", "1.1")), 10.0)))
		var lb2 = Label.new()
		lb2.text = art
		lb2.add_theme_font_size_override("font_size", 11)
		lb2.add_theme_color_override("font_color", Color(0.05, 0.05, 0.08))
		lb2.position = Vector2(4, rh * r + rh - 16)
		add_child(lb2)
		for ci in cols.size():
			var pose = {"state": "idle", "t": 0.4, "walk": 0.0, "atk": 0.0, "atk2": 0.0, "atk3": 0.0, "aim0": -0.1, "aim1": -0.4, "aim2": -0.9, "engage": 0.0, "hp_frac": 1.0, "ammo": 4, "special": 0.5}
			for kv in String(cols[ci]).get_slice("=", 1).split(","):
				if ":" in kv:
					var k = kv.get_slice(":", 0)
					var v = kv.get_slice(":", 1)
					pose[k] = v if k == "state" else float(v)
			var sp = Probe.new()
			sp.art = art
			sp.pose = pose
			sp.position = Vector2(cw * ci + cw * 0.45, rh * r + rh - 4.0 - (h * sc * 0.45 if air else 0.0))
			sp.scale = Vector2(sc, sc)
			add_child(sp)
	for k in 6:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(args.get("out", "/tmp/sheet.png"))
	get_tree().quit()


class Probe extends Node2D:
	var art = ""
	var pose = {}
	func _draw() -> void:
		Painter.draw_unit(self, art, pose)
