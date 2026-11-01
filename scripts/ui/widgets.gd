class_name Widgets
extends RefCounted
## Small reusable UI drawing widgets (inner classes so the project stays compact).


## Carved-stone backdrop with brass rivet frame and warm forge glow.
class Backdrop extends Control:
	var t = 0.0
	var glow_at = Vector2(0.5, 1.1)
	var animated = true

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(animated)

	func _process(delta: float) -> void:
		t += delta
		if Engine.get_frames_drawn() % 3 == 0:
			queue_redraw()

	func _draw() -> void:
		var r = get_rect()
		draw_rect(Rect2(Vector2.ZERO, r.size), Color("1b1714"))
		var rows = int(r.size.y / 48.0) + 1
		for i in rows:
			var y = i * 48.0
			draw_line(Vector2(0, y), Vector2(r.size.x, y), Color("241f1b"), 2.0)
			var off = 0.0 if i % 2 == 0 else 60.0
			var x = off
			while x < r.size.x:
				draw_line(Vector2(x, y), Vector2(x, y + 48), Color("241f1b"), 2.0)
				x += 120.0
		var gc = Vector2(r.size.x * glow_at.x, r.size.y * glow_at.y)
		var k = 0.85 + 0.15 * sin(t * 2.3)
		for i in 6:
			var rad = (r.size.x * 0.55) * (1.0 - i * 0.14)
			draw_circle(gc, rad, Color(0.95, 0.45, 0.12, 0.035 * k))
		# brass frame with rivets
		draw_rect(Rect2(Vector2(4, 4), r.size - Vector2(8, 8)), UiKit.BRASS_D, false, 3.0)
		var step = 64.0
		var x2 = 20.0
		while x2 < r.size.x - 10:
			_rivet(Vector2(x2, 10))
			_rivet(Vector2(x2, r.size.y - 10))
			x2 += step
		var y2 = 20.0
		while y2 < r.size.y - 10:
			_rivet(Vector2(10, y2))
			_rivet(Vector2(r.size.x - 10, y2))
			y2 += step

	func _rivet(p: Vector2) -> void:
		draw_circle(p, 3.2, Color("5a4520"))
		draw_circle(p + Vector2(-0.6, -0.6), 2.0, UiKit.BRASS)


## Renders a unit's procedural art scaled into a box. Optional idle/attack animation.
class UnitPreview extends Control:
	var art = ""
	var faction = "dwarf"
	var animate = false
	var planned = false
	var canvas: Node2D
	var anim = {"t": 0.0, "walk": 0.0, "atk": 0.0, "atk2": 0.0, "atk3": 0.0, "reload": 0.0, "state": "idle", "aim0": 0.0, "aim1": 0.0, "aim2": -1.2, "hp_frac": 1.0, "special": 1.0, "windup": 0.0, "ammo": 4, "hurt": 0.0}
	var _cycle = 0.0

	func _init(art_id: String = "", fac: String = "dwarf", anim_on: bool = false) -> void:
		art = art_id
		faction = fac
		animate = anim_on
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_contents = true

	func _ready() -> void:
		canvas = PreviewCanvas.new()
		canvas.owner_preview = self
		add_child(canvas)
		resized.connect(_layout)
		_layout()
		set_process(animate)
		if art == "flak_crew":
			anim.aim0 = -1.0
		if art in ["ironwing", "ironcloud"]:
			anim.aim0 = 1.2
			anim.aim1 = -0.6 if art == "ironwing" else 1.2

	func set_art(a: String, fac: String, is_planned: bool = false) -> void:
		art = a
		faction = fac
		planned = is_planned
		_layout()

	func _layout() -> void:
		if canvas == null:
			return
		var h: float = Painter.art_height(art) if art != "" else 50.0
		var w = h * 1.3
		if art in ["ironcloud"]:
			w = 230.0
		elif art in ["ironwing", "copperback", "brasshound", "bombard_gyro", "flying_machine", "scout_gyro"]:
			w = h * 2.2
		elif art in ["dwarf_hold", "undead_citadel", "mine_maw", "flesh_hulk", "boiler_stomper"]:
			w = h * 1.1
		var sc = minf(size.x / w, size.y / (h * 1.12)) * 0.92
		sc = maxf(sc, 0.05)
		var air = Painter.is_air_art(art)
		canvas.scale = Vector2(sc * (-1.0 if faction == "undead" else 1.0), sc)
		canvas.position = Vector2(size.x * 0.5, size.y * 0.5 if air else size.y * 0.94)
		if art == "ironcloud":
			canvas.position.y = size.y * 0.55
		canvas.queue_redraw()

	func _process(delta: float) -> void:
		anim.t += delta
		_cycle += delta
		if _cycle > 2.4:
			_cycle = 0.0
			anim.atk = 1.0
			anim.atk2 = 1.0
			anim.reload = 1.0
		anim.atk = maxf(0.0, anim.atk - delta * 2.2)
		anim.atk2 = maxf(0.0, anim.atk2 - delta * 2.2)
		anim.reload = maxf(0.0, anim.reload - delta * 0.65)
		anim.walk += delta * 4.0 if anim.state == "move" else 0.0
		canvas.queue_redraw()


class PreviewCanvas extends Node2D:
	var owner_preview

	func _draw() -> void:
		var p = owner_preview
		if p == null or p.art == "":
			return
		if p.planned:
			# honest placeholder: planned units have no final art yet
			draw_circle(Vector2(0, -30), 26, Color(0.3, 0.27, 0.24))
			draw_arc(Vector2(0, -30), 26, 0, TAU, 24, UiKit.BRASS_D, 2.0)
			return
		Widgets.draw_cached(self, p.art, p.anim)


## Horizontal health bar with label.
class Bar extends Control:
	var value = 1.0
	var col = UiKit.GOOD
	var text = ""
	var align_right = false

	func _draw() -> void:
		var r = Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(0.05, 0.04, 0.04, 0.85))
		var w = size.x * clampf(value, 0.0, 1.0)
		var fr = Rect2(Vector2(size.x - w, 0) if align_right else Vector2.ZERO, Vector2(w, size.y))
		draw_rect(fr.grow(-2), col)
		draw_rect(r, UiKit.BRASS_D, false, 2.0)
		if text != "":
			var f = get_theme_default_font()
			var fs = 15
			var tw = f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			draw_string(f, Vector2((size.x - tw) * 0.5 + 1, size.y * 0.5 + 6), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, 0.8))
			draw_string(f, Vector2((size.x - tw) * 0.5, size.y * 0.5 + 5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiKit.TEXT)


## Free-standing procedural art node (position/scale on the node; Painter sub-transforms stay correct).
class ArtSprite extends Node2D:
	var art = ""
	var anim = {"t": 0.0, "walk": 0.0, "atk": 0.0, "atk2": 0.0, "reload": 0.0, "state": "idle", "aim0": -0.15, "aim1": 0.0, "aim2": -1.0, "hurt": 0.0, "special": 1.0, "hp_frac": 1.0, "windup": 0.0, "ammo": 4}

	func _init(a: String = "", pos: Vector2 = Vector2.ZERO, sc: float = 1.0, flip: bool = false) -> void:
		art = a
		position = pos
		scale = Vector2(sc * (-1.0 if flip else 1.0), sc)

	func _process(delta: float) -> void:
		anim.t += delta
		anim.atk = maxf(0.0, anim.atk - delta * 2.0)
		anim.atk2 = maxf(0.0, anim.atk2 - delta * 2.0)
		anim.reload = maxf(0.0, anim.reload - delta * 0.65)
		if anim.state == "move":
			anim.walk += delta * 5.0
		queue_redraw()

	func _draw() -> void:
		Widgets.draw_cached(self, art, anim)


## Draws an art through the pose cache when it is on (one batched quad), live otherwise.
## On a cache miss the canvas asks to be redrawn next frame so it picks up the baked pose.
static func draw_cached(ci: CanvasItem, art: String, anim: Dictionary) -> void:
	if not PoseCache.enabled:
		if ci.material == PoseCache.premult:
			ci.material = null
		Painter.draw_unit(ci, art, anim)
		return
	ci.material = PoseCache.premult
	var uk: Dictionary = Painter.used_keys.get(art, {})
	var pose = {}
	for k in uk:
		var v = anim.get(k)
		if v == null:
			continue
		match k:
			"t":
				pose.t = snappedf(fposmod(float(v), 1.2), 0.15)
			"walk":
				pose.walk = snappedf(fposmod(float(v), TAU), TAU / 8.0)
			"state", "ammo":
				pose[k] = v
			_:
				pose[k] = snappedf(float(v), 0.25) if (v is float or v is int) else v
	var e: Dictionary = PoseCache.request(art, pose, PoseCache.screen_scale(ci))
	if e.is_empty():
		Painter.draw_unit(ci, art, anim)
		if not ci.get_tree().process_frame.is_connected(ci.queue_redraw):
			ci.get_tree().process_frame.connect(ci.queue_redraw, CONNECT_ONE_SHOT)
		return
	ci.draw_texture_rect_region(e.tex, e.dst, e.src)
