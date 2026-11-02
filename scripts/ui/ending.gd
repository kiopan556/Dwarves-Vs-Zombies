extends Control
## M008 ending: an in-engine, skippable sequence of about 80 s, then the epilogue card and the credits.
##   1. the Black Rift collapses (the gate of the undead realm, the tear shrinking to a scar, shards sucked in)
##   2. the dwarven army's banners are planted on the gate
##   3. the army marches home along the Realm Map road through all five acts, now clean (a pan over the baked
##      Realm Map layers, Act V back to Act I, a column of dwarves on the road)
##   4. a goofy coda at Stonehelm: a celebration volley knocks a rifleman's hat off, and it lands on a bewildered
##      rescued dwarf
## Then one line of epilogue per act, and the credits as scrolling forged-brass plates over the Great Forge hub.
## Tap or press any key: skip the current part (sequence -> epilogue -> credits -> back to the War Table).

const T_RIFT := 14.0
const T_BANNER := 10.0
const T_ACT := 9.0
const T_CODA := 11.0
const EPILOGUE := [
	"The mountain holds stand open again. Stonehelm's gate road carries carts, not corpses.",
	"In the Blighted Frontier the marsh fog lifts, and green comes back to the dead oaks.",
	"Over the cloud sea the eyries are rebuilt, and the sky belongs to the dwarves' little gasbags.",
	"The fallen foundries are lit again. The first new iron poured is a memorial to the machines that fell.",
	"Where the Black Rift was, there is a scar in the sky and a gate nobody guards. Nobody needs to.",
]
const CREDITS := [
	["DWARVES VS ZOMBIES", ""],
	["Game design & direction", "The project's creator"],
	["Development, art, audio & tools", "Built with Claude (Anthropic), milestones M001 – M008"],
	["Engine", "Godot Engine 4.3 (MIT licence) · GL Compatibility renderer"],
	["Type", "Godot's built-in default font"],
	["Art", "Every unit, building and land drawn in code: original designs only"],
	["Sound", "Every sound and every tune synthesized in code"],
	["The Dwarven Kingdom", "160 units in seven branches of the Great Forge"],
	["The Undead", "110 enemies and 15 lords of the dead"],
	["The Campaign", "150 stages in five acts"],
	["Special thanks", "Every rifleman who lost his hat in the line of duty"],
	["", "Thank you for playing."],
]

var t := 0.0
var part := "rift"         # rift | banner | march | coda | epilogue | credits | done
var world: EndingWorld
var realm: RealmMap
var march_act := 5
var fade: ColorRect
var caption: Label
var skip_btn: Button
var epi: VBoxContainer
var credits_box: Control
var credits_scroll := 0.0
var hub_bg: Node2D
var column: Array = []
var stage_bg: Node2D          # the coda's painted Stonehelm (a BattleBackground)
var actors: Array = []        # real unit sprites in the banner scene and the coda


func _ready() -> void:
	theme = UiKit.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	world = EndingWorld.new()
	world.host = self
	add_child(world)
	caption = UiKit.label("", 26, Color("ffe7b0"), HORIZONTAL_ALIGNMENT_CENTER)
	caption.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	caption.offset_top = -120
	caption.offset_bottom = -70
	caption.offset_left = -560
	caption.offset_right = 560
	caption.add_theme_constant_override("outline_size", 8)
	caption.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	add_child(caption)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	skip_btn = UiKit.button("Skip ▶", _skip, Vector2(120, 46), 16)
	skip_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	skip_btn.offset_left = -140
	skip_btn.offset_top = 16
	skip_btn.offset_right = -20
	add_child(skip_btn)
	Audio.stop_ambience()
	Audio.play_music("ending")
	if GameState.ending_credits_only:
		_go("credits")
	else:
		_go("rift")
	if not GameState.profile.is_empty():
		GameState.profile.ending_seen = true
		GameState.save()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and part in ["epilogue", "credits"]:
		_skip()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.pressed:
		_skip()


func _skip() -> void:
	match part:
		"rift", "banner", "march", "coda":
			_go("epilogue")
		"epilogue":
			_go("credits")
		_:
			_finish()


func _go(p: String) -> void:
	part = p
	t = 0.0
	caption.text = ""
	match p:
		"rift":
			world.mode = "rift"
		"banner":
			world.mode = "banner"
			caption.text = "The banners of the Great Forge stand on the gate of the dead."
			_cast(["shieldbearer", "rifleman", "grenadier", "rifleman", "militia", "shieldbearer", "rifleman", "mechanic", "rifleman", "grenadier"], size.y * 0.82 + 30.0, 1.5, false)
		"march":
			world.visible = false
			_clear_actors()
			_march_act(5)
		"coda":
			_clear_realm()
			_clear_actors()
			stage_bg = BattleBackground.new()
			stage_bg.env = "mountain_gate"
			add_child(stage_bg)
			move_child(stage_bg, 0)
			stage_bg.position = Vector2(0, size.y - Combat.GROUND_Y - 175.0)
			world.visible = true
			world.mode = "coda"
			caption.text = "Home. The volley is for the fallen; the hat is for whoever needs it most."
			var gy = stage_bg.position.y + Combat.GROUND_Y
			for j in 6:
				var sp = Widgets.ArtSprite.new("rifleman", Vector2(470.0 + j * 72.0, gy), 1.7, false)
				sp.anim.aim0 = -1.1
				add_child(sp)
				move_child(sp, 1)
				actors.append(sp)
			var rescued = Widgets.ArtSprite.new("militia", Vector2(1010.0, gy), 1.7, true)
			add_child(rescued)
			move_child(rescued, 1)
			actors.append(rescued)
			world.coda_ground = gy
		"epilogue":
			_clear_realm()
			_clear_actors()
			world.visible = false
			_show_epilogue()
		"credits":
			_clear_realm()
			world.visible = false
			if epi != null:
				epi.queue_free()
				epi = null
			_show_credits()


func _process(delta: float) -> void:
	t += delta
	match part:
		"rift":
			fade.color.a = clampf(1.0 - t * 1.5, 0.0, 1.0) + clampf((t - (T_RIFT - 0.6)) / 0.6, 0.0, 1.0)
			if t > T_RIFT * 0.55 and caption.text == "":
				caption.text = "The Black Rift collapses."
			if t >= T_RIFT:
				_go("banner")
		"banner":
			fade.color.a = clampf(1.0 - t * 2.0, 0.0, 1.0) + clampf((t - (T_BANNER - 0.6)) / 0.6, 0.0, 1.0)
			if t >= T_BANNER:
				_go("march")
		"march":
			_step_march(delta)
		"coda":
			fade.color.a = clampf(1.0 - t * 2.0, 0.0, 1.0) + clampf((t - (T_CODA - 0.8)) / 0.8, 0.0, 1.0)
			# the celebration volley every 3 s
			if fposmod(t, 3.0) < delta and actors.size() >= 6:
				for j in 6:
					actors[j].anim.atk = 1.0
			if t >= T_CODA:
				_go("epilogue")
		"epilogue":
			fade.color.a = clampf(1.0 - t * 2.0, 0.0, 1.0)
			if epi != null:
				for i in epi.get_child_count():
					epi.get_child(i).modulate.a = clampf((t - 0.8 - i * 1.6) / 1.0, 0.0, 1.0)
			if t > 0.8 + EPILOGUE.size() * 1.6 + 4.0:
				_go("credits")
		"credits":
			fade.color.a = clampf(1.0 - t * 1.5, 0.0, 1.0)
			credits_scroll += delta * 52.0
			if credits_box != null:
				credits_box.position.y = size.y - credits_scroll
				if credits_box.position.y + credits_box.size.y < size.y * 0.35:
					_finish()
	world.t = t
	world.queue_redraw()


# ------------------------------------------------------------------ the march home over the Realm Map
func _march_act(a: int) -> void:
	_clear_realm()
	march_act = a
	t = 0.0
	realm = RealmMap.new()
	realm.set_anchors_preset(Control.PRESET_FULL_RECT)
	realm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(realm)
	move_child(realm, 1)
	realm.setup(a, "")
	realm.size = size
	realm.scroll = realm.max_scroll()
	realm._target = -1.0
	realm._vel = 0.0
	var names = ["Siege of the Mountain Holds", "The Blighted Frontier", "War for the Skies", "The Fallen Foundries", "The Black Rift"]
	caption.text = "Act %s · %s" % [["I", "II", "III", "IV", "V"][a - 1], names[a - 1]]
	# the column marching home along the road (right to left)
	var arts = ["shieldbearer", "rifleman", "rifleman", "grenadier", "militia", "rifleman", "shieldbearer", "mechanic"]
	for i in arts.size():
		var sp = Widgets.ArtSprite.new(arts[i], Vector2.ZERO, 0.5, true)
		sp.anim.state = "move"
		realm.add_child(sp)
		column.append(sp)


func _cast(arts: Array, y: float, sc: float, flip: bool) -> void:
	_clear_actors()
	for i in arts.size():
		var sp = Widgets.ArtSprite.new(String(arts[i]), Vector2(90.0 + i * 112.0, y), sc, flip)
		add_child(sp)
		move_child(sp, 1)
		actors.append(sp)


func _clear_actors() -> void:
	for a in actors:
		if is_instance_valid(a):
			a.queue_free()
	actors.clear()
	if stage_bg != null and is_instance_valid(stage_bg):
		stage_bg.queue_free()
	stage_bg = null


func _clear_realm() -> void:
	for sp in column:
		if is_instance_valid(sp):
			sp.queue_free()
	column.clear()
	if realm != null and is_instance_valid(realm):
		realm.queue_free()
	realm = null


func _step_march(delta: float) -> void:
	if realm == null:
		return
	var k = clampf(t / T_ACT, 0.0, 1.0)
	realm._target = -1.0
	realm._vel = 0.0
	realm.scroll = lerpf(realm.max_scroll(), 0.0, k * k * (3.0 - 2.0 * k))
	var vs = realm.view_scale()
	var lead = realm.scroll + size.x / vs * 0.62
	for i in column.size():
		var sp = column[i]
		var wx = lead + i * 15.0
		sp.position = realm.world_to_view(Vector2(wx, realm.road_y(wx) - 1.0))
		sp.scale = Vector2(-0.5 * vs, 0.5 * vs)
		sp.anim.t = float(sp.anim.get("t", 0.0)) + delta
		sp.anim.walk = float(sp.anim.get("walk", 0.0)) + delta * 9.0
		sp.queue_redraw()
	fade.color.a = clampf(1.0 - t * 2.0, 0.0, 1.0) + clampf((t - (T_ACT - 0.5)) / 0.5, 0.0, 1.0)
	if t >= T_ACT:
		if march_act > 1:
			_march_act(march_act - 1)
		else:
			_go("coda")


# ------------------------------------------------------------------ epilogue and credits
func _show_epilogue() -> void:
	epi = VBoxContainer.new()
	epi.set_anchors_preset(Control.PRESET_FULL_RECT)
	epi.alignment = BoxContainer.ALIGNMENT_CENTER
	epi.add_theme_constant_override("separation", 18)
	epi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(epi)
	move_child(epi, 0)
	var bg = ColorRect.new()
	bg.color = Color("120c0a")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.show_behind_parent = true
	epi.add_child(bg)
	epi.remove_child(bg)
	add_child(bg)
	move_child(bg, 0)
	var names = ["I", "II", "III", "IV", "V"]
	for i in EPILOGUE.size():
		var h = HBoxContainer.new()
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_theme_constant_override("separation", 14)
		var n = UiKit.label("ACT %s" % names[i], 18, UiKit.BRASS)
		n.custom_minimum_size = Vector2(80, 0)
		h.add_child(n)
		var l = UiKit.label(EPILOGUE[i], 21, Color("f2e4c8"))
		l.custom_minimum_size = Vector2(900, 0)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		h.add_child(l)
		h.modulate.a = 0.0
		epi.add_child(h)


func _show_credits() -> void:
	for c in get_children():
		if c is ColorRect and c != fade:
			c.queue_free()
	hub_bg = load("res://scripts/ui/forge_hub.gd").HubWorld.new()
	add_child(hub_bg)
	move_child(hub_bg, 0)
	hub_bg.position = Vector2(-700, 0)
	var dim = ColorRect.new()
	dim.color = Color(0.04, 0.03, 0.02, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	move_child(dim, 1)
	credits_box = VBoxContainer.new()
	credits_box.add_theme_constant_override("separation", 20)
	credits_box.position = Vector2(size.x * 0.5 - 330, size.y)
	credits_box.custom_minimum_size = Vector2(660, 0)
	credits_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(credits_box)
	move_child(credits_box, 2)
	credits_scroll = 0.0
	for c2 in CREDITS:
		if String(c2[0]) == "DWARVES VS ZOMBIES":
			credits_box.add_child(UiKit.banner("DWARVES VS ZOMBIES", 34, 660))
			continue
		var pl = UiKit.plate("plaque", Vector4(22, 12, 22, 12))
		var cv = VBoxContainer.new()
		cv.alignment = BoxContainer.ALIGNMENT_CENTER
		pl.add_child(cv)
		if String(c2[0]) != "":
			cv.add_child(UiKit.label(String(c2[0]).to_upper(), 16, Color("3e2a12"), HORIZONTAL_ALIGNMENT_CENTER))
		var nl = UiKit.label(String(c2[1]), 21, Color("2a1a0a"), HORIZONTAL_ALIGNMENT_CENTER)
		nl.add_theme_font_override("font", UiKit.bold())
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cv.add_child(nl)
		credits_box.add_child(pl)


func _finish() -> void:
	if part == "done":
		return
	part = "done"
	GameState.ending_credits_only = false
	GameState.goto("campaign")


## The drawn parts of the ending (the gate and the collapsing rift, the banners, the Stonehelm coda).
class EndingWorld extends Node2D:
	var host
	var t = 0.0
	var mode = "rift"
	var coda_ground = 600.0
	const BONE = Color("d6ccb6")

	func _draw() -> void:
		var sz: Vector2 = host.size if host != null else Vector2(1280, 720)
		match mode:
			"rift", "banner":
				_gate_scene(sz)
			"coda":
				_coda(sz)

	func _gate_scene(sz: Vector2) -> void:
		var w = sz.x
		var h = sz.y
		var gy = h * 0.82
		var k = clampf(t / 14.0, 0.0, 1.0) if mode == "rift" else 1.0
		var top = Color("06040c").lerp(Color("1e2440"), k)
		var low = Color("3a2050").lerp(Color("c8906a"), k * k)
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, gy), Vector2(0, gy)]), PackedColorArray([top, top, low, low]))
		# the rift: a vast tear narrowing to a scar; shards sucked into it; a white flash as it seals
		var rx = w * 0.5
		var open = 1.0 - smoothstep(0.15, 0.85, k)
		if open > 0.01:
			for j in 5:
				draw_circle(Vector2(rx, h * 0.38), (260.0 - j * 40.0) * (0.3 + open * 0.7), Color(0.6, 0.3, 0.9, 0.05 + j * 0.02))
			var el = PackedVector2Array()
			var er = PackedVector2Array()
			for j in 18:
				var f = float(j) / 17.0
				var y = lerpf(-10.0, gy - 120.0, f)
				var ww = 90.0 * sin(f * PI) * open * (0.85 + 0.15 * sin(f * 11.0 + t * 6.0))
				el.append(Vector2(rx - ww, y))
				er.append(Vector2(rx + ww * 0.85, y))
			var tear = PackedVector2Array(el)
			var rev = er.duplicate()
			rev.reverse()
			tear.append_array(rev)
			draw_colored_polygon(tear, Color(0.95, 0.88, 1.0))
			var inner = PackedVector2Array()
			for q in tear:
				inner.append(Vector2(rx + (q.x - rx) * 0.5, q.y))
			draw_colored_polygon(inner, Color(0.22, 0.06, 0.3))
			for j in 24:
				var ph = fposmod(t * 0.5 + j * 0.043, 1.0)
				var ang = j * 2.4
				var rr = (1.0 - ph) * 520.0
				var sp = Vector2(rx, h * 0.38) + Vector2(cos(ang) * rr, sin(ang) * rr * 0.55)
				var s = 4.0 + (j % 4) * 3.0
				draw_colored_polygon(PackedVector2Array([sp + Vector2(-s, 0), sp + Vector2(0, -s * 0.5), sp + Vector2(s, 0), sp + Vector2(0, s)]), Color(0.1, 0.07, 0.14, 0.9 * ph))
		else:
			draw_line(Vector2(rx - 3, 20), Vector2(rx + 2, gy - 140), Color(1, 0.95, 0.9, 0.45), 2.0)
		var flash = 1.0 - absf(k - 0.86) / 0.06
		if flash > 0.0:
			draw_rect(Rect2(Vector2.ZERO, sz), Color(1, 1, 1, flash * 0.85))
		# the ground and the gate of bone and black iron
		draw_rect(Rect2(0, gy, w, h - gy), Color("2a2430").lerp(Color("3e3a40"), k))
		var gx0 = rx - 170.0
		var gx1 = rx + 170.0
		for px in [gx0, gx1]:
			draw_rect(Rect2(px - 28, gy - 300, 56, 300), BONE.darkened(0.3))
			draw_rect(Rect2(px - 22, gy - 300, 44, 300), BONE.darkened(0.1))
			draw_circle(Vector2(px, gy - 318), 26.0, BONE)
			var eye = Color(0.45, 1.0, 0.55, 0.9 * (1.0 - k)) if mode == "rift" else Color(0.1, 0.1, 0.1)
			draw_circle(Vector2(px - 9, gy - 320), 5.0, eye)
			draw_circle(Vector2(px + 9, gy - 320), 5.0, eye)
		var arch = PackedVector2Array()
		for j in 17:
			var a = PI + PI * float(j) / 16.0
			arch.append(Vector2(rx + cos(a) * 170.0, gy - 290.0 + sin(a) * 100.0))
		draw_polyline(arch, BONE.darkened(0.35), 18.0)
		draw_polyline(arch, BONE, 11.0)
		if mode == "banner":
			_banners(sz, gx0, gx1, gy)

	func _banners(sz: Vector2, gx0: float, gx1: float, gy: float) -> void:
		# two banners rise on the gate pillars, the army's line below
		var k = clampf((t - 1.0) / 3.0, 0.0, 1.0)
		for i in 2:
			var px = gx0 if i == 0 else gx1
			var pole_top = Vector2(px, gy - 340.0 - 120.0 * k)
			draw_line(Vector2(px, gy - 340.0), pole_top, Color("5a3a1e"), 6.0)
			var wave = sin(t * 4.0 + i) * 6.0
			var cloth = Color("2a4a8a") if i == 0 else Color("8a1a1e")
			var c = pole_top + Vector2(4, 4)
			draw_colored_polygon(PackedVector2Array([c, c + Vector2(90, wave), c + Vector2(80, 30 + wave * 0.5), c + Vector2(90, 60 + wave), c + Vector2(0, 62)]), cloth)
			draw_circle(c + Vector2(40, 30), 12.0, Color("ffcf5a"))
			Painter.cog(self, c + Vector2(40, 30), 9.0, Color("c9a24a"), 8)

	func _coda(sz: Vector2) -> void:
		# the scene itself is the painted Stonehelm backdrop and real dwarf sprites; this draws the muzzle flashes and
		# smoke of the volley, the hat's flight from rifleman #3 to the rescued dwarf, and his "?" then "!"
		var gy: float = coda_ground
		var vt = fposmod(t, 3.0)
		for j in 6:
			var mz = Vector2(470.0 + j * 72.0 + 30.0, gy - 92.0)
			if vt < 0.12:
				draw_circle(mz, 10.0, Color(1.0, 0.85, 0.4, 0.9))
			draw_circle(mz + Vector2(6.0 + vt * 8.0, -vt * 18.0), 6.0 + vt * 7.0, Color(0.92, 0.92, 0.92, 0.45 * (1.0 - vt / 3.0)))
		var hk = clampf((t - 2.0) / 3.5, 0.0, 1.0)
		if t >= 2.0:
			var a0 = Vector2(470.0 + 2 * 72.0, gy - 96.0)
			var a1 = Vector2(1010.0, gy - 82.0)
			var hp = a0.lerp(a1, hk) + Vector2(0, -sin(hk * PI) * 260.0)
			var spin = hk * TAU * 3.0 if hk < 1.0 else 0.0
			draw_set_transform(hp, spin, Vector2(1.7, 1.7))
			draw_colored_polygon(Painter.ell_pts(Vector2(0, 0), 9.0, 7.0, 0.0, 12, PI, TAU), Color("8f979f"))
			draw_rect(Rect2(-11, -1, 22, 3), Color("50565c"))
			draw_circle(Vector2(0, -7), 1.6, Color("c9a24a"))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if hk >= 1.0 and host != null:
			var f = host.caption.get_theme_default_font()
			var qk = clampf((t - 5.6) / 0.4, 0.0, 1.0)
			if f != null:
				draw_string(f, Vector2(1032.0, gy - 120.0 - qk * 10.0), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(1, 1, 1, qk))
				if t > 7.0:
					draw_string(f, Vector2(1052.0, gy - 138.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color("ffcf5a"))
