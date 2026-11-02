class_name UiKit
extends RefCounted
## Forged brass & iron UI kit (M003 overhaul). Riveted iron plates, bevelled brass frames,
## engraved banners, forge-lit primary buttons, valve gauges and vector glyph icons.
## Styles are generated nine-patch textures (UiArt) so panels batch cheaply on phones.

const BRASS := Color("c9a24a")
const BRASS_L := Color("f0d27a")
const BRASS_D := Color("8f6f2a")
const STONE := Color("2b2622")
const STONE_L := Color("3a332d")
const IRON := Color("4a5058")
const TEXT := Color("f0e2bf")
const TEXT_DIM := Color("b5a682")
const FORGE := Color("f08a2a")
const GOOD := Color("7fcf6a")
const BAD := Color("e0604a")
const STEAM := Color("bfe3ef")
const UNDEAD := Color("9fd88a")
const BOSS := Color("d08ad0")
const AIR := Color("a8c8e0")

static var _theme: Theme
static var _bold: FontVariation


static func bold() -> Font:
	if _bold == null:
		_bold = FontVariation.new()
		_bold.base_font = ThemeDB.fallback_font
		_bold.variation_embolden = 0.65
		_bold.spacing_glyph = 1
	return _bold


## Legacy flat box (kept for small dynamic highlights; prefer UiArt styles).
static func box(bg: Color, border: Color, bw: int = 2, radius: int = 6, margin: float = 8.0) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = margin + 2.0
	s.content_margin_right = margin + 2.0
	s.content_margin_top = margin * 0.6
	s.content_margin_bottom = margin * 0.6
	s.anti_aliasing = false
	return s


static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t = Theme.new()
	t.default_font_size = 18
	var bc = Vector4(16, 10, 16, 10)
	t.set_stylebox("normal", "Button", UiArt.style("btn", 12, bc))
	t.set_stylebox("hover", "Button", UiArt.style("btn_hover", 12, bc))
	t.set_stylebox("pressed", "Button", UiArt.style("btn_pressed", 12, bc))
	t.set_stylebox("disabled", "Button", UiArt.style("btn_disabled", 12, bc))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_font("font", "Button", bold())
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color("fff6dc"))
	t.set_color("font_pressed_color", "Button", FORGE)
	t.set_color("font_disabled_color", "Button", Color("7a7064"))
	t.set_color("font_outline_color", "Button", Color(0, 0, 0, 0.75))
	t.set_constant("outline_size", "Button", 3)
	t.set_font_size("font_size", "Button", 20)
	t.set_stylebox("panel", "Panel", UiArt.style("panel", 16, Vector4(18, 16, 18, 16)))
	t.set_stylebox("panel", "PanelContainer", UiArt.style("panel", 16, Vector4(20, 18, 20, 18)))
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.0))
	t.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.6))
	t.set_constant("outline_size", "Label", 3)
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_font_size("normal_font_size", "RichTextLabel", 17)
	t.set_font_size("bold_font_size", "RichTextLabel", 18)
	t.set_font("bold_font", "RichTextLabel", bold())
	t.set_stylebox("tab_selected", "TabBar", UiArt.style("tab_sel", 10, Vector4(18, 8, 18, 8)))
	t.set_stylebox("tab_unselected", "TabBar", UiArt.style("tab", 10, Vector4(18, 8, 18, 8)))
	t.set_stylebox("tab_hovered", "TabBar", UiArt.style("btn_hover", 10, Vector4(18, 8, 18, 8)))
	t.set_stylebox("tab_disabled", "TabBar", UiArt.style("btn_disabled", 10, Vector4(18, 8, 18, 8)))
	t.set_font("font", "TabBar", bold())
	t.set_color("font_selected_color", "TabBar", BRASS_L)
	t.set_color("font_unselected_color", "TabBar", TEXT_DIM)
	t.set_color("font_hovered_color", "TabBar", TEXT)
	t.set_font_size("font_size", "TabBar", 17)
	t.set_constant("h_separation", "TabBar", 6)
	t.set_stylebox("slider", "HSlider", box(Color("141210"), BRASS_D, 1, 4, 3))
	t.set_stylebox("grabber_area", "HSlider", box(FORGE.darkened(0.2), BRASS_D, 0, 4, 3))
	t.set_stylebox("grabber_area_highlight", "HSlider", box(FORGE, BRASS_D, 0, 4, 3))
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	for st in ["normal", "hover", "pressed", "disabled"]:
		t.set_stylebox(st, "OptionButton", t.get_stylebox(st, "Button"))
	t.set_stylebox("panel", "PopupMenu", UiArt.style("panel_dark", 10, Vector4(10, 8, 10, 8)))
	t.set_color("font_color", "OptionButton", TEXT)
	t.set_color("font_color", "CheckButton", TEXT)
	t.set_color("font_color", "CheckBox", TEXT)
	t.set_font_size("font_size", "CheckButton", 17)
	t.set_constant("separation", "VBoxContainer", 8)
	t.set_constant("separation", "HBoxContainer", 10)
	_theme = t
	return t


# ------------------------------------------------------------------ builders
static func label(text: String, size: int = 18, col: Color = TEXT, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = align
	if size >= 24:
		l.add_theme_font_override("font", bold())
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		l.add_theme_constant_override("outline_size", 4)
	return l


static func button(text: String, cb: Callable, min_size: Vector2 = Vector2(0, 56), font: int = 20) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", font)
	b.pressed.connect(func():
		Audio.play("ui_click", -1.0, -6.0)
		cb.call())
	return b


## Forge-lit call-to-action button.
static func primary(text: String, cb: Callable, min_size: Vector2 = Vector2(0, 64), font: int = 22) -> Button:
	var b = button(text, cb, min_size, font)
	var bc = Vector4(18, 10, 18, 10)
	b.add_theme_stylebox_override("normal", UiArt.style("btn_primary", 12, bc))
	b.add_theme_stylebox_override("hover", UiArt.style("btn_primary_hover", 12, bc))
	b.add_theme_color_override("font_color", Color("fff3d6"))
	return b


static func danger(text: String, cb: Callable, min_size: Vector2 = Vector2(0, 56), font: int = 20) -> Button:
	var b = button(text, cb, min_size, font)
	b.add_theme_stylebox_override("normal", UiArt.style("btn_danger", 12, Vector4(16, 10, 16, 10)))
	return b


## A riveted iron plate (PanelContainer) in one of the generated styles.
static func plate(kind: String = "panel", pad: Vector4 = Vector4(20, 18, 20, 18)) -> PanelContainer:
	var pc = PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UiArt.style(kind, 12, pad))
	return pc


## Engraved brass banner with a title.
static func banner(text: String, size: int = 30, min_w: float = 0.0) -> PanelContainer:
	var pc = PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UiArt.style("banner", 22, Vector4(34, 6, 34, 8)))
	var l = label(text, size, BRASS_L, HORIZONTAL_ALIGNMENT_CENTER)
	pc.add_child(l)
	pc.custom_minimum_size = Vector2(min_w, 0)
	return pc


## Section heading: small engraved caps with a brass rule.
static func heading(text: String, col: Color = BRASS) -> VBoxContainer:
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	var l = label(text.to_upper(), 15, col)
	l.add_theme_font_override("font", bold())
	v.add_child(l)
	var rule = ColorRect.new()
	rule.color = Color(col.r, col.g, col.b, 0.45)
	rule.custom_minimum_size = Vector2(0, 2)
	v.add_child(rule)
	return v


static func title_bar(parent: Control, title: String, back: Callable) -> HBoxContainer:
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	var bk = button("", back, Vector2(120, 56))
	var row = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var g = Glyph.new("back", 22, BRASS_L)
	row.add_child(g)
	var bl = label("Forge", 19, TEXT)
	bl.add_theme_font_override("font", bold())
	row.add_child(bl)
	bk.add_child(row)
	h.add_child(bk)
	var bn = banner(title, 28)
	bn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(bn)
	parent.add_child(h)
	return h


static func root_margin(root: Control, m: int = 18) -> MarginContainer:
	var mc = MarginContainer.new()
	mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		mc.add_theme_constant_override("margin_" + side, m)
	root.add_child(mc)
	return mc


static func hp_color(f: float) -> Color:
	return BAD.lerp(GOOD, clampf(f, 0.0, 1.0))


## Small icon + value pill (e.g. Sparks counter).
static func pill(glyph: String, text: String, col: Color = BRASS_L) -> PanelContainer:
	var pc = plate("panel_dark", Vector4(12, 6, 14, 6))
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.add_child(Glyph.new(glyph, 22, col))
	var l = label(text, 19, col)
	l.add_theme_font_override("font", bold())
	l.name = "Value"
	h.add_child(l)
	pc.add_child(h)
	return pc


# ================================================================== glyph icons
## Vector icons drawn from code (coin, steam, gear, skull, crown, star, lock, sword, wing,
## shield, hammer, flame, play, pause, back, book, valve, spark, map, fast).
class Glyph extends Control:
	var kind = "gear"
	var col = Color("f0d27a")
	var px = 24.0

	func _init(k: String = "gear", size_px: float = 24.0, c: Color = Color("f0d27a")) -> void:
		kind = k
		px = size_px
		col = c
		custom_minimum_size = Vector2(size_px, size_px)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size_flags_vertical = Control.SIZE_SHRINK_CENTER

	func _ready() -> void:
		set_process(not UiKit.glyph_ready())

	func _process(_d: float) -> void:
		if UiKit._gstate != 1:
			set_process(false)
			queue_redraw()

	func _draw() -> void:
		var c = size * 0.5
		var r = minf(size.x, size.y) * 0.5
		var o = Color(0, 0, 0, 0.75)
		UiKit.draw_glyph(self, kind, c, r, col, o)


# ------------------------------------------------------------------ glyph atlas
## Every glyph is baked once (white fill, dark outline) into one atlas texture at startup, then
## drawn as a single tinted rect. Rects from one texture batch together, whereas the vector
## path costs one draw call per circle/polygon/arc in the GL Compatibility renderer.
const GLYPH_KINDS := ["coin", "steam", "gear", "valve", "skull", "crown", "star", "lock", "sword", "wing", "shield",
	"hammer", "flame", "play", "pause", "fast", "back", "book", "spark", "map", "mine", "disc", "ring"]
const GCELL := 64
const GRAD := 24.0
static var glyph_atlas: Texture2D = null
static var _gstate := 0   # 0 not started · 1 baking · 2 ready · -1 unavailable (headless): vector fallback


static func ensure_glyph_atlas(n: Node) -> void:
	if _gstate != 0 or n == null or not n.is_inside_tree():
		return
	if DisplayServer.get_name() == "headless":
		_gstate = -1
		return
	_gstate = 1
	var vp = SubViewport.new()
	vp.transparent_bg = true
	vp.size = Vector2i(GCELL * 8, GCELL * int(ceil(GLYPH_KINDS.size() / 8.0)))
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var painter = _GlyphBaker.new()
	vp.add_child(painter)
	n.get_tree().root.add_child.call_deferred(vp)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img = vp.get_texture().get_image() if is_instance_valid(vp) else null
	if img != null and not img.is_empty():
		glyph_atlas = ImageTexture.create_from_image(img)
		_gstate = 2
	else:
		_gstate = -1
	if is_instance_valid(vp):
		vp.queue_free()


class _GlyphBaker extends Node2D:
	func _draw() -> void:
		for i in UiKit.GLYPH_KINDS.size():
			var c = Vector2((i % 8) * UiKit.GCELL + UiKit.GCELL * 0.5, (i / 8) * UiKit.GCELL + UiKit.GCELL * 0.5)
			UiKit._glyph_vec(self, UiKit.GLYPH_KINDS[i], c, UiKit.GRAD, Color.WHITE, Color(0, 0, 0, 0.8))


static func glyph_ready() -> bool:
	return _gstate == 2


## Draw a glyph: one tinted atlas rect when the atlas is baked, vectors otherwise.
static func draw_glyph(ci: CanvasItem, kind: String, c: Vector2, r: float, col: Color, o: Color) -> void:
	if _gstate == 2:
		var i = GLYPH_KINDS.find(kind)
		if i >= 0:
			var h = r * (GCELL * 0.5) / GRAD
			ci.draw_texture_rect_region(glyph_atlas, Rect2(c - Vector2(h, h), Vector2(h, h) * 2.0), Rect2((i % 8) * GCELL, (i / 8) * GCELL, GCELL, GCELL), col)
			return
	_glyph_vec(ci, kind, c, r, col, o)


## Filled disc / ring through the atlas (batched), vector fallback.
static func disc(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	if _gstate == 2:
		draw_glyph(ci, "disc", c, r, col, col)
	else:
		ci.draw_circle(c, r, col)


static func ring(ci: CanvasItem, c: Vector2, r: float, col: Color, w: float = 1.5) -> void:
	if _gstate == 2:
		draw_glyph(ci, "ring", c, r, col, col)
	else:
		ci.draw_arc(c, r, 0, TAU, 20, col, w)


static func _glyph_vec(ci: CanvasItem, kind: String, c: Vector2, r: float, col: Color, o: Color) -> void:
	match kind:
		"disc":
			ci.draw_circle(c, r, col)
		"ring":
			ci.draw_arc(c, r * 0.94, 0, TAU, 32, col, maxf(1.5, r * 0.12))
		"coin":
			ci.draw_circle(c, r * 0.9, o)
			ci.draw_circle(c, r * 0.78, col.darkened(0.15))
			ci.draw_circle(c, r * 0.58, col)
			ci.draw_line(c + Vector2(0, -r * 0.35), c + Vector2(0, r * 0.35), col.darkened(0.4), maxf(1.5, r * 0.14))
		"steam":
			for i in 3:
				var x = c.x - r * 0.5 + i * r * 0.5
				var pts = PackedVector2Array()
				for k in 6:
					pts.append(Vector2(x + sin(k * 1.2) * r * 0.16, c.y + r * 0.7 - k * r * 0.28))
				ci.draw_polyline(pts, o, maxf(3.0, r * 0.26))
				ci.draw_polyline(pts, col, maxf(1.6, r * 0.14))
		"gear", "valve":
			var n = 8 if kind == "gear" else 6
			var pts2 = PackedVector2Array()
			for i in n * 2:
				var a = TAU * i / (n * 2.0)
				var rr = r * (0.88 if i % 2 == 0 else 0.68)
				pts2.append(c + Vector2.from_angle(a) * rr)
			ci.draw_colored_polygon(pts2, col)
			ci.draw_circle(c, r * 0.3, o)
			if kind == "valve":
				for i in 3:
					ci.draw_line(c, c + Vector2.from_angle(TAU * i / 3.0 + 0.5) * r * 0.65, o, maxf(1.5, r * 0.12))
		"skull":
			ci.draw_circle(c + Vector2(0, -r * 0.12), r * 0.72, o)
			ci.draw_circle(c + Vector2(0, -r * 0.12), r * 0.62, col)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.35, r * 0.25), Vector2(r * 0.7, r * 0.45)), col)
			ci.draw_circle(c + Vector2(-r * 0.25, -r * 0.12), r * 0.17, o)
			ci.draw_circle(c + Vector2(r * 0.25, -r * 0.12), r * 0.17, o)
			for i in 3:
				ci.draw_line(c + Vector2(-r * 0.2 + i * r * 0.2, r * 0.3), c + Vector2(-r * 0.2 + i * r * 0.2, r * 0.66), o, maxf(1.0, r * 0.08))
		"crown":
			var pts3 = PackedVector2Array([c + Vector2(-r * 0.8, r * 0.5), c + Vector2(-r * 0.8, -r * 0.4), c + Vector2(-r * 0.4, 0), c + Vector2(0, -r * 0.7), c + Vector2(r * 0.4, 0), c + Vector2(r * 0.8, -r * 0.4), c + Vector2(r * 0.8, r * 0.5)])
			ci.draw_colored_polygon(pts3, col)
			pts3.append(pts3[0])
			ci.draw_polyline(pts3, o, maxf(1.2, r * 0.1))
		"star":
			var pts4 = PackedVector2Array()
			for i in 10:
				pts4.append(c + Vector2.from_angle(-PI / 2 + TAU * i / 10.0) * r * (0.9 if i % 2 == 0 else 0.4))
			ci.draw_colored_polygon(pts4, col)
			pts4.append(pts4[0])
			ci.draw_polyline(pts4, o, maxf(1.0, r * 0.08))
		"lock":
			ci.draw_arc(c + Vector2(0, -r * 0.15), r * 0.38, PI, TAU, 10, col, maxf(2.0, r * 0.16))
			ci.draw_rect(Rect2(c + Vector2(-r * 0.6, -r * 0.1), Vector2(r * 1.2, r * 0.85)), col)
			ci.draw_circle(c + Vector2(0, r * 0.3), r * 0.13, o)
		"sword":
			ci.draw_line(c + Vector2(-r * 0.7, r * 0.7), c + Vector2(r * 0.75, -r * 0.75), o, maxf(3.0, r * 0.3))
			ci.draw_line(c + Vector2(-r * 0.6, r * 0.6), c + Vector2(r * 0.7, -r * 0.7), col, maxf(1.6, r * 0.16))
			ci.draw_line(c + Vector2(-r * 0.5, r * 0.1), c + Vector2(-r * 0.1, r * 0.5), col.darkened(0.2), maxf(2.0, r * 0.2))
		"wing":
			var pts5 = PackedVector2Array([c + Vector2(-r * 0.8, r * 0.3), c + Vector2(-r * 0.2, -r * 0.6), c + Vector2(r * 0.85, -r * 0.7), c + Vector2(r * 0.4, -r * 0.2), c + Vector2(r * 0.6, 0.0), c + Vector2(r * 0.1, r * 0.1), c + Vector2(r * 0.3, r * 0.35)])
			ci.draw_colored_polygon(pts5, col)
		"shield":
			var pts6 = PackedVector2Array([c + Vector2(-r * 0.7, -r * 0.7), c + Vector2(r * 0.7, -r * 0.7), c + Vector2(r * 0.6, r * 0.2), c + Vector2(0, r * 0.85), c + Vector2(-r * 0.6, r * 0.2)])
			ci.draw_colored_polygon(pts6, col)
			pts6.append(pts6[0])
			ci.draw_polyline(pts6, o, maxf(1.2, r * 0.1))
		"hammer":
			ci.draw_line(c + Vector2(-r * 0.5, r * 0.75), c + Vector2(r * 0.3, -r * 0.1), o, maxf(3.0, r * 0.28))
			ci.draw_line(c + Vector2(-r * 0.5, r * 0.75), c + Vector2(r * 0.3, -r * 0.1), col.darkened(0.3), maxf(1.6, r * 0.14))
			ci.draw_set_transform(c + Vector2(r * 0.3, -r * 0.35), -0.8, Vector2.ONE)
			ci.draw_rect(Rect2(Vector2(-r * 0.5, -r * 0.22), Vector2(r * 1.0, r * 0.44)), col)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"airship":
			ci.draw_colored_polygon(Painter.ell_pts(c + Vector2(0, -r * 0.2), r * 0.85, r * 0.42, 0.0, 16), col)
			ci.draw_polyline(Painter.ell_pts(c + Vector2(0, -r * 0.2), r * 0.85, r * 0.42, 0.0, 16) + PackedVector2Array([c + Vector2(r * 0.85, -r * 0.2)]), o, maxf(1.2, r * 0.1))
			ci.draw_rect(Rect2(c + Vector2(-r * 0.35, r * 0.3), Vector2(r * 0.7, r * 0.28)), col.darkened(0.35))
			ci.draw_line(c + Vector2(-r * 0.3, r * 0.15), c + Vector2(-r * 0.25, r * 0.3), o, 1.2)
			ci.draw_line(c + Vector2(r * 0.3, r * 0.15), c + Vector2(r * 0.25, r * 0.3), o, 1.2)
		"flame":
			var pts7 = PackedVector2Array([c + Vector2(0, -r * 0.85), c + Vector2(r * 0.55, 0), c + Vector2(r * 0.4, r * 0.6), c + Vector2(0, r * 0.8), c + Vector2(-r * 0.45, r * 0.6), c + Vector2(-r * 0.55, 0), c + Vector2(-r * 0.15, -r * 0.3)])
			ci.draw_colored_polygon(pts7, col)
			ci.draw_circle(c + Vector2(0, r * 0.35), r * 0.28, Color(1.0, 0.95, 0.7))
		"play":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.45, -r * 0.65), c + Vector2(r * 0.7, 0), c + Vector2(-r * 0.45, r * 0.65)]), col)
		"pause":
			ci.draw_rect(Rect2(c + Vector2(-r * 0.55, -r * 0.6), Vector2(r * 0.38, r * 1.2)), col)
			ci.draw_rect(Rect2(c + Vector2(r * 0.17, -r * 0.6), Vector2(r * 0.38, r * 1.2)), col)
		"fast":
			for i in 2:
				var off = Vector2(-r * 0.5 + i * r * 0.55, 0)
				ci.draw_colored_polygon(PackedVector2Array([c + off + Vector2(-r * 0.3, -r * 0.55), c + off + Vector2(r * 0.35, 0), c + off + Vector2(-r * 0.3, r * 0.55)]), col)
		"back":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.5, -r * 0.65), c + Vector2(-r * 0.55, 0), c + Vector2(r * 0.5, r * 0.65)]), col)
		"book":
			ci.draw_rect(Rect2(c + Vector2(-r * 0.75, -r * 0.6), Vector2(r * 1.5, r * 1.2)), col.darkened(0.25))
			ci.draw_rect(Rect2(c + Vector2(-r * 0.68, -r * 0.52), Vector2(r * 0.62, r * 1.04)), col)
			ci.draw_rect(Rect2(c + Vector2(r * 0.06, -r * 0.52), Vector2(r * 0.62, r * 1.04)), col)
		"spark":
			for i in 4:
				var a = i * PI / 4.0
				ci.draw_line(c - Vector2.from_angle(a) * r * 0.85, c + Vector2.from_angle(a) * r * 0.85, col, maxf(1.5, r * 0.14 if i % 2 == 0 else r * 0.08))
			ci.draw_circle(c, r * 0.25, Color(1, 0.97, 0.85))
		"map":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.8, -r * 0.55), c + Vector2(-r * 0.25, -r * 0.7), c + Vector2(r * 0.25, -r * 0.55), c + Vector2(r * 0.8, -r * 0.7), c + Vector2(r * 0.8, r * 0.6), c + Vector2(r * 0.25, r * 0.75), c + Vector2(-r * 0.25, r * 0.6), c + Vector2(-r * 0.8, r * 0.75)]), col)
			ci.draw_line(c + Vector2(-r * 0.25, -r * 0.7), c + Vector2(-r * 0.25, r * 0.6), o, 1.2)
			ci.draw_line(c + Vector2(r * 0.25, -r * 0.55), c + Vector2(r * 0.25, r * 0.75), o, 1.2)
		"mine":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.8, r * 0.7), c + Vector2(0, -r * 0.7), c + Vector2(r * 0.8, r * 0.7)]), col.darkened(0.3))
			ci.draw_circle(c + Vector2(0, r * 0.35), r * 0.3, o)
			ci.draw_circle(c + Vector2(0, r * 0.35), r * 0.18, Color(1.0, 0.8, 0.4))


# ================================================================== bars & gauges
## Framed horizontal gauge with a label (stronghold / citadel / boss / stat bars).
class GaugeBar extends Control:
	var value = 1.0
	var shown = 1.0
	var col = Color("7fcf6a")
	var text = ""
	var glyph = ""
	var align_right = false
	var font_size = 16

	func _process(delta: float) -> void:
		var ns = move_toward(shown, value, delta * 0.8)
		if absf(ns - shown) > 0.0005:
			shown = ns
			queue_redraw()

	func set_value(v: float, t: String = "") -> void:
		if absf(v - value) > 0.0005 or t != text:
			value = clampf(v, 0.0, 1.0)
			text = t
			queue_redraw()

	func _draw() -> void:
		var r = Rect2(Vector2.ZERO, size)
		var ins = r.grow(-4.0)
		draw_style_box(UiArt.style("panel_dark", 8), r)
		var w = ins.size.x * shown
		var fill = Rect2(ins.position.x + (ins.size.x - ins.size.x * value if align_right else 0.0), ins.position.y, ins.size.x * value, ins.size.y)
		if shown > value:
			var trail = Rect2(ins.position.x + (ins.size.x - w if align_right else 0.0), ins.position.y, w, ins.size.y)
			draw_rect(trail, Color(1.0, 0.85, 0.5, 0.55))
		draw_rect(fill, col)
		draw_rect(Rect2(fill.position, Vector2(fill.size.x, fill.size.y * 0.38)), Color(1, 1, 1, 0.16))
		for i in range(1, 10):
			var x = ins.position.x + ins.size.x * i / 10.0
			draw_line(Vector2(x, ins.position.y + ins.size.y * 0.62), Vector2(x, ins.end.y), Color(0, 0, 0, 0.3), 1.0)
		var f = UiKit.bold()
		var tx = text
		var gx = 0.0
		if glyph != "":
			var gr = size.y * 0.32
			var gc = Vector2(ins.end.x - gr - 4.0, size.y * 0.5) if align_right else Vector2(ins.position.x + gr + 4.0, size.y * 0.5)
			UiKit.draw_glyph(self, glyph, gc, gr, Color(1, 1, 1, 0.92), Color(0, 0, 0, 0.7))
			gx = gr * 2.0 + 6.0
		var ty = size.y * 0.5 + font_size * 0.36
		var x0 = ins.position.x + 8.0 + (0.0 if align_right else gx)
		var w0 = ins.size.x - 16.0 - gx
		draw_string_outline(f, Vector2(x0, ty), tx, HORIZONTAL_ALIGNMENT_RIGHT if align_right else HORIZONTAL_ALIGNMENT_LEFT, w0, font_size, 4, Color(0, 0, 0, 0.85))
		draw_string(f, Vector2(x0, ty), tx, HORIZONTAL_ALIGNMENT_RIGHT if align_right else HORIZONTAL_ALIGNMENT_LEFT, w0, font_size, Color(1, 0.97, 0.88))


## Steam-pressure dial: brass bezel, red zone, sweeping needle.
class Dial extends Control:
	var value = 0.0
	var label_text = "STEAM"
	var col = Color("bfe3ef")

	func set_value(v: float) -> void:
		if absf(v - value) > 0.004:
			value = clampf(v, 0.0, 1.0)
			queue_redraw()

	func _draw() -> void:
		var c = size * 0.5 + Vector2(0, size.y * 0.08)
		var r = minf(size.x, size.y * 1.3) * 0.46
		UiKit.disc(self, c, r + 3.0, Color("120e0b"))
		UiKit.disc(self, c, r, UiKit.BRASS.darkened(0.2))
		UiKit.disc(self, c, r - 4.0, Color("efe6cf"))
		var a0 = PI * 0.8
		var a1 = PI * 2.2
		draw_arc(c, r - 9.0, a0 + (a1 - a0) * 0.8, a1, 10, Color(0.85, 0.2, 0.15, 0.8), 5.0)
		draw_arc(c, r - 9.0, a0, a0 + (a1 - a0) * value, 24, Color(col.r * 0.6, col.g * 0.8, col.b, 0.9), 5.0)
		for i in 11:
			var a = lerpf(a0, a1, i / 10.0)
			draw_line(c + Vector2.from_angle(a) * (r - 4.0), c + Vector2.from_angle(a) * (r - (9.0 if i % 5 == 0 else 6.5)), Color(0.15, 0.12, 0.1), 1.5)
		var na = lerpf(a0, a1, value)
		draw_line(c, c + Vector2.from_angle(na) * (r - 8.0), Color(0.6, 0.1, 0.08), 3.0)
		UiKit.disc(self, c, 4.0, UiKit.BRASS)
		var f = UiKit.bold()
		draw_string(f, Vector2(c.x - 40, c.y + r * 0.62), "%d" % int(round(value * 100.0)), HORIZONTAL_ALIGNMENT_CENTER, 80, 15, Color(0.15, 0.12, 0.1))
