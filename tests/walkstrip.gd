extends Node2D
## M006 visual check: one art drawn at N walk phases in a row (state=move), several arts stacked.
##   xvfb-run godot --path . res://tests/walkstrip.tscn -- --arts=ironclad_walker,cannon_strider --n=8 --out=/tmp/w.png

var args = {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv = a.substr(2).split("=")
			args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var bg = ColorRect.new()
	bg.color = Color("8a9aac")
	bg.size = Vector2(1280, 720)
	add_child(bg)
	var arts: Array = String(args.get("arts", "ironclad_walker")).split(",")
	var n = int(args.get("n", "8"))
	var rows = arts.size()
	for r in rows:
		var art: String = arts[r]
		var h = Painter.art_height(art)
		var sc = minf(float(args.get("max_scale", "1.4")), (620.0 / rows - 30.0) / h)
		for i in n:
			var sp = Widgets.ArtSprite.new(art, Vector2(80 + i * (1180.0 / n), 60 + (r + 1) * (640.0 / rows) - 20), sc, false)
			sp.anim.state = String(args.get("state", "move"))
			sp.anim.walk = TAU * float(i) / float(n)
			sp.anim.t = 0.3 * i
			sp.anim.atk = float(args.get("atk", "0"))
			sp.anim.engage = float(args.get("engage", "0"))
			sp.set_process(false)
			add_child(sp)
	for k in 6:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(args.get("out", "/tmp/walk.png"))
	get_tree().quit()
