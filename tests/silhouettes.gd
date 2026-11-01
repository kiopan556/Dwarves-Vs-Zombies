extends Node
## M006c silhouette uniqueness (needs a display: xvfb-run). Renders every kit vehicle's idle silhouette at one
## common scale, aligned on its ground centre, and reports the pairwise overlap (IoU) of the filled outlines.
## Also saves a black-silhouette contact sheet.
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tests/silhouettes.tscn -- --out=/tmp/sil.png

const SZ := Vector2i(420, 300)
const ORIGIN := Vector2(210, 260)


class Probe extends Node2D:
	var art = ""
	var pose = {}
	func _draw() -> void:
		Painter.draw_unit(self, art, pose)


func _vehicles() -> Array:
	var arts: Array = []
	for e in Registry.implemented_dwarves():
		var a = String(Registry.combat_def(e.id).get("art", ""))
		if ArtKit.has(a) and String(ArtKit.params(a).get("fam", "")) == "veh" and not a in arts:
			arts.append(a)
	arts.append("gravegun_tank")
	return arts


func _ready() -> void:
	Audio.enabled = false
	var args = {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv = a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var vp = SubViewport.new()
	vp.size = SZ
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var pr = Probe.new()
	pr.position = ORIGIN
	vp.add_child(pr)
	var arts = _vehicles()
	var masks = {}
	for art in arts:
		pr.art = art
		pr.pose = {"state": "idle", "t": 0.0, "walk": 0.0, "atk": 0.0, "hp_frac": 1.0}
		pr.queue_redraw()
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img: Image = vp.get_texture().get_image()
		img.resize(SZ.x / 3, SZ.y / 3, Image.INTERPOLATE_BILINEAR)
		var m = PackedByteArray()
		m.resize(img.get_width() * img.get_height())
		for y in img.get_height():
			for x in img.get_width():
				m[y * img.get_width() + x] = 1 if img.get_pixel(x, y).a > 0.4 else 0
		masks[art] = m
	var ious: Array = []
	var worst: Array = []
	for i in arts.size():
		for j in range(i + 1, arts.size()):
			var a: PackedByteArray = masks[arts[i]]
			var b: PackedByteArray = masks[arts[j]]
			var inter = 0
			var uni = 0
			for k in a.size():
				if a[k] == 1 or b[k] == 1:
					uni += 1
					if a[k] == 1 and b[k] == 1:
						inter += 1
			var iou = float(inter) / maxf(1.0, float(uni))
			ious.append(iou)
			worst.append([iou, arts[i], arts[j]])
	worst.sort()
	worst.reverse()
	var sorted_i = ious.duplicate()
	sorted_i.sort()
	var med = sorted_i[sorted_i.size() / 2]
	var over = 0
	for v in ious:
		if v > 0.8:
			over += 1
	print("SIL arts=%d pairs=%d median_iou=%.3f max_iou=%.3f pairs_over_0.80=%d" % [arts.size(), ious.size(), med, sorted_i[-1], over])
	for w in worst.slice(0, 8):
		print("SIL worst %.3f %s ~ %s" % [w[0], w[1], w[2]])
	# contact sheet: black silhouettes in a grid, all at the same scale, labelled
	if args.has("out"):
		var cols = 5
		var cw = 250
		var chh = 170
		var rows = int(ceil(arts.size() / float(cols)))
		var sv = SubViewport.new()
		sv.size = Vector2i(cols * cw, rows * chh)
		sv.transparent_bg = false
		sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(sv)
		var bg = ColorRect.new()
		bg.color = Color(0.93, 0.91, 0.86)
		bg.size = Vector2(sv.size)
		sv.add_child(bg)
		var sc = float(args.get("scale", "0.9"))
		for i in arts.size():
			var p2 = Probe.new()
			p2.art = arts[i]
			p2.pose = {"state": "idle", "t": 0.0, "walk": 0.0, "atk": 0.0, "hp_frac": 1.0}
			p2.position = Vector2((i % cols) * cw + cw * 0.5, (i / cols) * chh + chh - 30)
			p2.scale = Vector2(sc, sc)
			if not args.has("color"):
				p2.modulate = Color(0.08, 0.07, 0.07)
			sv.add_child(p2)
			var lb = Label.new()
			lb.text = arts[i]
			lb.position = Vector2((i % cols) * cw + 6, (i / cols) * chh + chh - 24)
			lb.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1))
			lb.add_theme_font_size_override("font_size", 12)
			sv.add_child(lb)
		for k in 4:
			await RenderingServer.frame_post_draw
		sv.get_texture().get_image().save_png(args.out)
		print("SIL sheet ", args.out)
	get_tree().quit()
