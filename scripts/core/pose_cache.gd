extends Node
## PoseCache (autoload) — the mobile performance core.
##
## Unit art is procedural: every polygon/outline/circle is a separate canvas command, which made
## a busy battle ~9,000 GPU draw calls per frame and kept the CPU rebuilding geometry every frame.
## The cache bakes each *quantized* animation pose of each art once into a 2048² atlas page
## (an off-screen SubViewport) and units then draw a single textured quad from the atlas.
## Quads that share a page batch together, so a crowded battle drops to a few dozen draw calls.
##
## * Poses are quantized by the unit (walk phase in 8 steps, attack in quarters, aims in 0.25 rad,
##   idle time in a short loop…), so the animation is a little "stepped" (~8–12 fps), like
##   hand-made sprite sheets, while movement itself stays smooth (node transforms).
## * A pose is baked the first time it is seen (bounded number of bakes per frame); until it is
##   ready the unit draws itself live exactly as before, so nothing ever disappears.
## * Each cell is clipped to the art's measured bounds (data/art_bounds.json) so a pose can
##   never paint into its neighbour.
## * When the page budget is exhausted, the oldest page is cleared and re-used.
## * Atlas pixels are premultiplied (transparent render target), so units drawing from the cache
##   use a premultiplied-alpha material.

const PAGE := 2048
const PAD := 2
const MIN_POSES := 8          # M006b: an art may evict an old page until it owns this many cells

var enabled := false
var max_pages := 4
var max_scale := 2.0          # big frames are baked at most this sharp (then scaled up a little)
var max_bakes_per_frame := 8

var pages: Array = []          # {vp, tex, x, y, row_h, keys, pool, born, busy}
var entries := {}              # key -> {tex, src, dst, ready, page}
var by_art := {}               # "art|scale" -> Array of [pose, key]  (for nearest-pose snapping)
var pending: Array = []        # [job, frame, page]
var bounds := {}
var premult: CanvasItemMaterial
var _bakes_frame := 0
var _born := 0
var stats := {"hits": 0, "misses": 0, "bakes": 0, "recycled": 0, "live": 0, "snapped": 0}
## per-key weights for the nearest-pose search (bigger = more important to match)
const W := {"state": 50.0, "walk": 3.0, "atk": 6.0, "atk2": 4.0, "atk3": 4.0, "windup": 6.0, "ability_anim": 4.0,
	"aim0": 3.0, "aim1": 2.0, "aim2": 2.0, "hp_frac": 2.0, "special": 2.0, "reload": 2.0, "t": 0.6, "spin": 0.4,
	"engage": 1.0, "recoil": 1.0, "stun_t": 3.0, "brace_t": 1.0, "heat_lock_t": 1.0, "ammo": 1.0, "gag": 4.0, "hurt": 2.0}


class BakeJob extends Node2D:
	var art = ""
	var pose = {}
	func _draw() -> void:
		Painter.draw_unit(self, art, pose)


func _ready() -> void:
	premult = CanvasItemMaterial.new()
	premult.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	var f = FileAccess.open("res://data/art_bounds.json", FileAccess.READ)
	if f != null:
		var d = JSON.parse_string(f.get_as_text())
		if d is Dictionary:
			for k in d.keys():
				var v: Array = d[k]
				bounds[k] = Rect2(float(v[0]), float(v[1]), float(v[2]), float(v[3]))
				if v.size() > 4:
					var uk = {}
					for key in v[4]:
						uk[key] = true
					Painter.used_keys[k] = uk
	process_priority = -100


## Turn the cache on/off (quality setting). Turning it off frees the atlas pages.
func set_enabled(on: bool, pages_budget: int = 4, scale_cap: float = 2.0) -> void:
	max_pages = pages_budget
	max_scale = scale_cap
	if on == enabled:
		return
	enabled = on
	if not on:
		for pg in pages:
			pg.vp.queue_free()
		pages.clear()
		entries.clear()
		by_art.clear()
		pending.clear()
	else:
		_new_page()


func bounds_of(art: String) -> Rect2:
	if bounds.has(art):
		return bounds[art]
	var h = Painter.art_height(art)
	return Rect2(-h * 0.9, -h * 1.35, h * 2.0, h * 1.5)


func _process(_delta: float) -> void:
	_bakes_frame = 0
	if pending.is_empty():
		return
	var now = Engine.get_process_frames()
	var keep: Array = []
	for p in pending:
		if int(p[1]) < now:
			var job: BakeJob = p[0]
			job.visible = false
			pages[p[2]].pool.append(job)
			pages[p[2]].busy -= 1
		else:
			keep.append(p)
	pending = keep
	# grow the atlas outside of the draw pass (adding viewports while drawing is unsafe)
	if enabled and pages.size() < max_pages and pages.size() > 0:
		var last = pages[pages.size() - 1]
		if last.y > PAGE * 0.6:
			_new_page()


func _new_page() -> void:
	var vp = SubViewport.new()
	vp.size = Vector2i(PAGE, PAGE)
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.gui_disable_input = true
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	add_child(vp)
	var pg = {"vp": vp, "tex": vp.get_texture(), "y": 0, "rows": {}, "keys": [], "pool": [], "born": _born, "busy": 0}
	_born += 1
	for i in max_bakes_per_frame * 2:
		var j = BakeJob.new()
		j.visible = false
		vp.add_child(j)
		RenderingServer.canvas_item_set_clip(j.get_canvas_item(), true)
		pg.pool.append(j)
	pages.append(pg)


func _alloc(w: int, h: int, allow_recycle: bool = true) -> Array:
	if w > PAGE or h > PAGE:
		return []
	var hc = int(ceil(h / 16.0)) * 16     # rows per height class: little wasted space
	for idx in range(pages.size() - 1, -1, -1):
		var pg = pages[idx]
		if pg.pool.is_empty():
			continue
		var row = pg.rows.get(hc)
		if row != null and row.x + w <= PAGE:
			var pos = Vector2i(row.x, row.y)
			row.x += w
			return [idx, pos]
		if pg.y + hc <= PAGE:
			pg.rows[hc] = {"x": w, "y": pg.y}
			var pos2 = Vector2i(0, pg.y)
			pg.y += hc
			return [idx, pos2]
	# all full: recycle the oldest idle page (M006b: only for an art with fewer than MIN_POSES cells; an art
	# that already has a working set snaps to its nearest pose instead, so a full atlas no longer thrashes)
	if not allow_recycle:
		return []
	var oldest = -1
	for idx in pages.size():
		if pages[idx].busy == 0 and (oldest < 0 or pages[idx].born < pages[oldest].born):
			oldest = idx
	if oldest < 0:
		return []
	var pg2 = pages[oldest]
	for k in pg2.keys:
		var ent = entries.get(k)
		if ent != null:
			var lst: Array = by_art.get(ent.bucket, [])
			for i in range(lst.size() - 1, -1, -1):
				if lst[i][1] == k:
					lst.remove_at(i)
		entries.erase(k)
	pg2.keys.clear()
	pg2.rows = {hc: {"x": w, "y": 0}}
	pg2.y = hc
	pg2.born = _born
	_born += 1
	pg2.vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	stats.recycled += 1
	return [oldest, Vector2i(0, 0)]


## Returns a ready atlas entry for (art, pose, scale) or {} (caller draws live this frame).
var debug_seen := {}
var debug_track := false
var live_by_art := {}           # debug: live draws per art while debug_track is on


func request(art: String, pose: Dictionary, s: float, pose_hash: int = 0) -> Dictionary:
	s = minf(s, max_scale)
	var key = hash(Vector3i(pose_hash if pose_hash != 0 else pose.hash(), art.hash(), int(s * 8.0)))
	if debug_track:
		if not debug_seen.has(art):
			debug_seen[art] = {}
		debug_seen[art][key] = pose
	var e = entries.get(key)
	if e != null and e.art == art:
		if int(e.ready) <= Engine.get_process_frames():
			stats.hits += 1
			return e
		return {}
	stats.misses += 1
	var b: Rect2 = bounds_of(art)
	var w = int(ceil(b.size.x * s)) + PAD * 2
	var h = int(ceil(b.size.y * s)) + PAD * 2
	var bucket = "%s|%s" % [art, s]
	var lst: Array = by_art.get(bucket, [])
	# per-art budget by cell area: big frames get fewer distinct poses, then snap to the nearest
	var cap = clampi(int(PAGE * PAGE * 0.1 / float(w * h)), 14, 160)
	if lst.size() >= cap or (_bakes_frame >= max_bakes_per_frame and not lst.is_empty()):
		var best = _nearest(lst, pose)
		if not best.is_empty():
			stats.snapped += 1
			return best
	if _bakes_frame >= max_bakes_per_frame or pages.is_empty():
		return {}
	var cell: Array = _alloc(w, h, lst.size() < MIN_POSES)
	if cell.is_empty():
		var near = _nearest(lst, pose)
		if not near.is_empty():
			stats.snapped += 1
		return near
	var pg = pages[cell[0]]
	var job: BakeJob = pg.pool.pop_back()
	var origin = Vector2(cell[1]) + Vector2(PAD, PAD)
	job.art = art
	job.pose = pose
	job.position = origin - b.position * s
	job.scale = Vector2(s, s)
	RenderingServer.canvas_item_set_custom_rect(job.get_canvas_item(), true, b)
	job.visible = true
	job.queue_redraw()
	pg.vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	pg.busy += 1
	var frame = Engine.get_process_frames()
	e = {"art": art, "tex": pg.tex, "src": Rect2(origin, b.size * s), "dst": b, "ready": frame + 1, "page": cell[0], "bucket": bucket}
	entries[key] = e
	lst.append([pose, key])
	by_art[bucket] = lst
	pg.keys.append(key)
	pending.append([job, frame, cell[0]])
	_bakes_frame += 1
	stats.bakes += 1
	return {}


func _nearest(lst: Array, pose: Dictionary) -> Dictionary:
	var now = Engine.get_process_frames()
	var best = {}
	var bd = INF
	for it in lst:
		var e = entries.get(it[1])
		if e == null or int(e.ready) > now:
			continue
		var p: Dictionary = it[0]
		var d = 0.0
		for k in pose:
			var a = pose[k]
			var b2 = p.get(k, a)
			if a is String or b2 is String:
				d += 0.0 if a == b2 else float(W.get(k, 1.0))
			elif k == "walk":
				var dw = absf(float(a) - float(b2))
				d += minf(dw, TAU - dw) * float(W.walk)
			else:
				d += absf(float(a) - float(b2)) * float(W.get(k, 1.0))
			if d >= bd:
				break
		if d < bd:
			bd = d
			best = e
	return best


## Pixel scale of a canvas item on screen (art units -> screen pixels), quantized for caching.
static func screen_scale(ci: CanvasItem) -> float:
	var s: float = absf(ci.get_global_transform_with_canvas().get_scale().y)
	var vp = ci.get_viewport()
	if vp != null:
		s *= absf(vp.get_final_transform().get_scale().y)
	return clampf(snappedf(s, 0.125), 0.25, 3.0)


## M006: bake scale from the parent's transform and the art scale only, so the motion layer's small
## squash/stretch on the unit node never changes which atlas cell (bake resolution) a pose uses.
static func screen_scale_base(ci: CanvasItem, art_scale: float) -> float:
	var par = ci.get_parent() as CanvasItem
	var s: float = absf(art_scale) * (absf(par.get_global_transform_with_canvas().get_scale().y) if par != null else 1.0)
	var vp = ci.get_viewport()
	if vp != null:
		s *= absf(vp.get_final_transform().get_scale().y)
	return clampf(snappedf(s, 0.125), 0.25, 3.0)


## Premultiplies a colour for drawing on a premultiplied-alpha canvas item.
static func pm(c: Color) -> Color:
	return Color(c.r * c.a, c.g * c.a, c.b * c.a, c.a)
