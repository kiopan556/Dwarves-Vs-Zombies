class_name UiArt
extends RefCounted
## Procedurally generated "forged brass & iron" UI textures (no image assets): riveted iron
## plates with bevelled brass frames, buttons in four states, forge-lit primary buttons, tabs,
## deploy-card frames, sockets and engraved banners. Each is a small nine-patch texture used by
## StyleBoxTexture, so a whole panel is one batched quad on the GPU.

static var _cache := {}

const OUT := Color("120e0b")
const BRASS := Color("c9a24a")
const BRASS_L := Color("f0d27a")
const BRASS_D := Color("6e5320")
const IRON_T := Color("3a342e")
const IRON_B := Color("221e1a")


static func tex(name: String) -> Texture2D:
	if _cache.has(name):
		return _cache[name]
	var t: Texture2D
	match name:
		"panel":
			t = _frame(56, 56, 10, 4, BRASS, IRON_T, IRON_B, true, 0.05)
		"panel_dark":
			t = _frame(40, 40, 7, 2, BRASS_D.lightened(0.15), Color("1d1a17"), Color("141210"), false, 0.04)
		"panel_glass":
			t = _frame(40, 40, 7, 2, BRASS_D.lightened(0.2), Color(0.12, 0.1, 0.09, 0.82), Color(0.08, 0.07, 0.06, 0.82), false, 0.0)
		"btn":
			t = _frame(48, 48, 9, 3, BRASS, Color("4e4238"), Color("2c241e"), false, 0.04, true)
		"btn_hover":
			t = _frame(48, 48, 9, 3, BRASS_L, Color("62513f"), Color("3a2e24"), false, 0.04, true)
		"btn_pressed":
			t = _frame(48, 48, 9, 3, Color("f08a2a"), Color("231b15"), Color("3a2a1c"), false, 0.04)
		"btn_disabled":
			t = _frame(48, 48, 9, 3, Color("5a524a"), Color("2c2825"), Color("201d1b"), false, 0.03)
		"btn_primary":
			t = _frame(48, 48, 9, 3, BRASS_L, Color("d2702a"), Color("7a3212"), false, 0.04, true)
		"btn_primary_hover":
			t = _frame(48, 48, 9, 3, Color("fff0b0"), Color("ec8a3a"), Color("8e3c16"), false, 0.04, true)
		"btn_danger":
			t = _frame(48, 48, 9, 3, BRASS, Color("8e3a2e"), Color("4a1a14"), false, 0.04, true)
		"tab":
			t = _frame(40, 40, 8, 2, BRASS_D.lightened(0.1), Color("2c2620"), Color("1e1a16"), false, 0.03)
		"tab_sel":
			t = _frame(40, 40, 8, 3, BRASS_L, Color("5a4632"), Color("3a2c20"), false, 0.04, true)
		"card":
			t = _frame(48, 64, 9, 3, BRASS, Color("4a3a2c"), Color("221a14"), true, 0.05)
		"card_air":
			t = _frame(48, 64, 9, 3, Color("a8c0d0"), Color("34465a"), Color("18222c"), true, 0.05)
		"card_ready":
			t = _frame(48, 64, 9, 3, Color("ffb050"), Color("5a422c"), Color("2a1e14"), true, 0.05)
		"slot":
			t = _frame(40, 40, 8, 2, Color("4a4038"), Color("141210"), Color("1c1916"), false, 0.02)
		"banner":
			t = _banner(96, 40)
		"plaque":
			t = _frame(56, 40, 8, 3, BRASS_L, Color("8a6a2a"), Color("5a421a"), true, 0.06, true)
		"node":
			t = _frame(40, 40, 18, 3, BRASS, Color("4a3a2c"), Color("221a14"), false, 0.03, true)
	_cache[name] = t
	return t


## Nine-patch style from a generated texture.
static func style(name: String, margin: float = 10.0, content: Vector4 = Vector4(14, 10, 14, 10)) -> StyleBoxTexture:
	var s = StyleBoxTexture.new()
	s.texture = tex(name)
	var m = margin
	if name in ["panel", "card", "card_air", "card_ready"]:
		m = 16.0
	elif name == "banner":
		m = 22.0
	elif name == "node":
		m = 19.0
	s.texture_margin_left = m
	s.texture_margin_right = m
	s.texture_margin_top = m
	s.texture_margin_bottom = m
	s.content_margin_left = content.x
	s.content_margin_top = content.y
	s.content_margin_right = content.z
	s.content_margin_bottom = content.w
	return s


# ------------------------------------------------------------------ generators
## Signed inside-distance of (x,y) to a rounded rectangle (positive inside).
static func _sd(x: float, y: float, w: float, h: float, r: float) -> float:
	var qx = absf(x - w * 0.5) - (w * 0.5 - r)
	var qy = absf(y - h * 0.5) - (h * 0.5 - r)
	var outside = Vector2(maxf(qx, 0.0), maxf(qy, 0.0)).length() + minf(maxf(qx, qy), 0.0) - r
	return -outside


static func _frame(w: int, h: int, r: float, bw: int, rim: Color, top: Color, bot: Color, rivets: bool, noise: float, sheen: bool = false) -> ImageTexture:
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng = RandomNumberGenerator.new()
	rng.seed = w * 131 + h * 7 + bw
	for y in h:
		for x in w:
			var px = x + 0.5
			var py = y + 0.5
			var d = _sd(px, py, w, h, r)
			if d <= 0.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var a = clampf(d, 0.0, 1.0)
			var c: Color
			if d < 1.4:
				c = OUT
			elif d < 1.4 + bw:
				# bevelled rim: light from the top-left
				var k = (float(h) - py) / h * 0.6 + (float(w) - px) / w * 0.4
				var band = (d - 1.4) / bw
				c = rim.darkened(0.35).lerp(rim.lightened(0.35), clampf(k * 1.2 - 0.1, 0.0, 1.0))
				if band < 0.3:
					c = c.lightened(0.15)
				elif band > 0.75:
					c = c.darkened(0.25)
			elif d < 2.4 + bw:
				c = OUT.lerp(top, 0.25)
			else:
				var gy = py / h
				c = top.lerp(bot, gy)
				if sheen and gy < 0.42:
					c = c.lightened(0.07 * (1.0 - gy / 0.42))
				if noise > 0.0:
					var n = rng.randf_range(-noise, noise)
					c = Color(clampf(c.r + n, 0, 1), clampf(c.g + n, 0, 1), clampf(c.b + n * 0.8, 0, 1), c.a)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, c.a * a))
	if rivets:
		var ins = bw + 5.0
		for cx in [ins, w - ins]:
			for cy in [ins, h - ins]:
				_rivet(img, cx, cy, 2.4)
	return ImageTexture.create_from_image(img)


static func _rivet(img: Image, cx: float, cy: float, rad: float) -> void:
	for y in range(int(cy - rad - 2), int(cy + rad + 2)):
		for x in range(int(cx - rad - 2), int(cx + rad + 2)):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			var dd = Vector2(x + 0.5 - cx, y + 0.5 - cy).length()
			if dd <= rad + 0.8:
				var k = clampf(1.0 - (Vector2(x + 0.5 - cx + 0.8, y + 0.5 - cy + 0.8).length() / (rad + 0.8)), 0.0, 1.0)
				var c = OUT if dd > rad else BRASS_D.lerp(BRASS_L, k)
				img.set_pixel(x, y, c)


static func _banner(w: int, h: int) -> ImageTexture:
	# engraved brass banner with darker inset and notched ends
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var px = x + 0.5
			var py = y + 0.5
			var notch = absf(py - h * 0.5) * 0.45
			var inside = px > notch and px < w - notch and py > 1.0 and py < h - 1.0
			if not inside:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var edge = minf(minf(px - notch, w - notch - px), minf(py - 1.0, h - 1.0 - py))
			var c: Color
			if edge < 1.4:
				c = OUT
			elif edge < 4.5:
				c = BRASS.darkened(0.3).lerp(BRASS_L, clampf(1.0 - py / h, 0.0, 1.0))
			elif edge < 5.5:
				c = BRASS_D.darkened(0.3)
			else:
				c = Color("3a2a16").lerp(Color("231a0e"), py / h)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)
