class_name HazardLayer
extends Node2D
## M005 environmental hazards drawn cheaply:
##  - bog patches: static mire painted once on a child item that sits under the units;
##  - miasma: each drifting cloud is a handful of soft dots from the shared DOT texture, so all
##    clouds batch into one draw call. Clouds sit over the units but stay translucent and keep their
##    densest part above head height, so the undead remain readable inside them.

var battle
var bog_item: BogPaint


func setup(b) -> void:
	battle = b
	z_index = 240
	bog_item = BogPaint.new()
	bog_item.battle = b
	bog_item.z_as_relative = false
	bog_item.z_index = -60
	add_child(bog_item)
	foundry_item = FoundryPaint.new()
	foundry_item.battle = b
	foundry_item.z_as_relative = false
	foundry_item.z_index = -58
	add_child(foundry_item)
	shadow_item = ShadowPaint.new()
	shadow_item.battle = b
	shadow_item.z_as_relative = false
	shadow_item.z_index = -55
	add_child(shadow_item)


## M006 readability: low flyers cast a soft shadow on the lane (one batched layer under the units),
## so low / mid / high read apart at a glance: shadowed, plain, hazed.
class ShadowPaint extends Node2D:
	var battle

	func _draw() -> void:
		if battle == null:
			return
		var vr: Rect2 = battle.view_rect
		for s in 2:
			for u in battle.by_side[s]:
				if not u.alive or u.domain != "air" or u.band_i() != 0:
					continue
				var x: float = u.position.x
				if vr.size != Vector2.ZERO and (x < vr.position.x - 60.0 or x > vr.end.x + 60.0):
					continue
				var k = clampf((u.position.y - 200.0) / 250.0, 0.2, 1.0)
				var w = 26.0 * k + 8.0
				draw_texture_rect(FxLayer.DOT, Rect2(x - w, Combat.GROUND_Y - 4.0, w * 2.0, 9.0), false, Color(0, 0, 0, 0.32 * k))


var shadow_item: ShadowPaint
var foundry_item: FoundryPaint


## M007 foundry hazards under the units: vent grates (glowing when about to erupt), the slag river, burst
## steam pipes and wreck markers. Everything is rects, short polylines and DOT quads (batched).
class FoundryPaint extends Node2D:
	var battle

	func _draw() -> void:
		if battle == null:
			return
		var vr: Rect2 = battle.view_rect
		var gy = Combat.GROUND_Y
		var tm: float = battle.time
		# slag river
		var sl: Dictionary = battle.slag
		if not sl.is_empty():
			var x0 = float(sl.def.x0)
			if sl.active or float(sl.cool) > 0.0:
				var fr = float(sl.front)
				var lo = minf(x0, fr)
				var hi = maxf(x0, fr)
				var heat = 1.0 if sl.active else clampf(float(sl.cool) / 2.5, 0.0, 1.0)
				draw_rect(Rect2(lo, gy - 10.0, hi - lo, 22.0), Color(0.16, 0.07, 0.04, 0.9))
				var n = int((hi - lo) / 14.0) + 1
				for k in n:
					var xx = lo + k * 14.0
					var w = 16.0 + 6.0 * sin(tm * 2.0 + k * 1.3)
					var col = Color(1.0, 0.45 + 0.2 * sin(tm * 3.0 + k), 0.08, 0.75 * heat)
					draw_texture_rect(FxLayer.DOT, Rect2(xx - w * 0.5, gy - 9.0, w, 16.0), false, col)
					if k % 3 == 0:
						draw_texture_rect(FxLayer.DOT, Rect2(xx - 5.0, gy - 4.0, 10.0, 6.0), false, Color(0.2, 0.1, 0.06, 0.8))
				# the advancing lip glows brightest
				if sl.active:
					draw_texture_rect(FxLayer.DOT, Rect2(fr - 18.0, gy - 22.0, 36.0, 34.0), false, Color(1.0, 0.8, 0.3, 0.55))
			elif float(sl.warn) > 0.0 and int(tm * 8.0) % 2 == 0:
				draw_line(Vector2(x0 - 26.0, gy - 2.0), Vector2(x0 + 26.0, gy + 3.0), Color(1.0, 0.55, 0.15, 0.9), 3.0)
				draw_texture_rect(FxLayer.DOT, Rect2(x0 - 30.0, gy - 16.0, 60.0, 24.0), false, Color(1.0, 0.5, 0.1, 0.35))
		# furnace vent grates
		for v in battle.vents:
			var x: float = v.x
			if vr.size != Vector2.ZERO and (x < vr.position.x - 60.0 or x > vr.end.x + 60.0):
				continue
			var hot = clampf(float(v.glow) - Foundry.ERUPT_TIME, 0.0, 1.0)
			draw_rect(Rect2(x - 26.0, gy - 6.0, 52.0, 10.0), Color(0.12, 0.1, 0.09))
			draw_rect(Rect2(x - 22.0, gy - 4.0, 44.0, 6.0), Color(0.35 + 0.65 * hot, 0.12 + 0.3 * hot, 0.05, 1.0))
			for k in 5:
				draw_line(Vector2(x - 20.0 + k * 10.0, gy - 5.0), Vector2(x - 20.0 + k * 10.0, gy + 3.0), Color(0.18, 0.16, 0.15), 2.0)
			if hot > 0.0:
				draw_texture_rect(FxLayer.DOT, Rect2(x - 40.0, gy - 26.0, 80.0, 36.0), false, Color(1.0, 0.5, 0.15, 0.5 * hot))
		# burst steam pipes: a broken iron main with a jet of steam
		for p in battle.steam_pipes:
			var px: float = p.x
			if vr.size != Vector2.ZERO and (px < vr.position.x - 100.0 or px > vr.end.x + 100.0):
				continue
			draw_rect(Rect2(px - 60.0, gy - 26.0, 52.0, 14.0), Color(0.24, 0.22, 0.21))
			draw_rect(Rect2(px - 60.0, gy - 26.0, 52.0, 4.0), Color(0.4, 0.37, 0.33))
			draw_colored_polygon(PackedVector2Array([Vector2(px - 8.0, gy - 26.0), Vector2(px + 2.0, gy - 30.0), Vector2(px - 2.0, gy - 18.0), Vector2(px + 4.0, gy - 12.0), Vector2(px - 8.0, gy - 12.0)]), Color(0.3, 0.27, 0.25))
			draw_rect(Rect2(px - 44.0, gy - 12.0, 8.0, 14.0), Color(0.2, 0.18, 0.17))
			var fed = bool(p.fed)
			for k in 6:
				var ph = fposmod(tm * 0.9 + k / 6.0, 1.0)
				var rr = 10.0 + ph * 34.0
				draw_texture_rect(FxLayer.DOT, Rect2(px + ph * 30.0 - rr, gy - 26.0 - ph * 90.0 - rr, rr * 2.0, rr * 2.0), false, Color(1, 1, 1, (0.28 if fed else 0.2) * (1.0 - ph)))
			# the reach of the leak, faint on the ground
			draw_texture_rect(FxLayer.DOT, Rect2(px - float(p.r), gy - 8.0, float(p.r) * 2.0, 16.0), false, Color(0.85, 0.95, 1.0, 0.12 if not fed else 0.2))
		# wrecks: a smoking cog marker; a reclaim channel pulses green, salvage glows brass
		for w in battle.wrecks:
			var wx: float = w.x
			if vr.size != Vector2.ZERO and (wx < vr.position.x - 60.0 or wx > vr.end.x + 60.0):
				continue
			var life = 1.0 - clampf(float(w.t) / Foundry.WRECK_LIFE, 0.0, 1.0)
			draw_texture_rect(FxLayer.DOT, Rect2(wx - 34.0, gy - 6.0, 68.0, 14.0), false, Color(0, 0, 0, 0.35))
			if w.chan != null:
				var k2 = float(w.chan_t) / Foundry.CHANNEL_TIME
				var pul = 0.5 + 0.5 * sin(tm * 10.0)
				draw_texture_rect(FxLayer.DOT, Rect2(wx - 46.0, gy - 40.0, 92.0, 56.0), false, Color(0.43, 1.0, 0.55, 0.18 + 0.2 * pul))
				draw_arc(Vector2(wx, gy - 2.0), 30.0 + 6.0 * pul, PI, TAU, 16, Color(0.43, 1.0, 0.55, 0.8), 2.5)
				draw_arc(Vector2(wx, gy - 60.0), 11.0, -PI * 0.5, -PI * 0.5 + TAU * k2, 18, Color(0.55, 1.0, 0.6, 0.95), 3.0)
				if is_instance_valid(w.chan):
					var cp: Vector2 = w.chan.position + Vector2(0, -22)
					var mid = (cp + Vector2(wx, gy - 20.0)) * 0.5 + Vector2(0, -18.0 + 6.0 * sin(tm * 14.0))
					draw_polyline(PackedVector2Array([cp, mid, Vector2(wx, gy - 20.0)]), Color(0.5, 1.0, 0.55, 0.7), 2.0)
			elif w.sal != null:
				var k3 = float(w.sal_t) / Foundry.SALVAGE_TIME
				draw_arc(Vector2(wx, gy - 60.0), 11.0, -PI * 0.5, -PI * 0.5 + TAU * k3, 18, Color(1.0, 0.82, 0.4, 0.95), 3.0)
			# cog marker fading with the wreck's remaining life
			Painter.cog(self, Vector2(wx, gy - 60.0), 7.0, Color(0.85, 0.7, 0.45, 0.35 + 0.45 * life))


func refresh_bog() -> void:
	bog_item.queue_redraw()


func _draw() -> void:
	if battle == null:
		return
	var vr: Rect2 = battle.view_rect
	_draw_thermals(vr)
	_draw_bolts(vr)
	_draw_foundry_over(vr)
	for c in battle.miasma_clouds:
		var x: float = c.x
		var r: float = c.r
		if vr.size != Vector2.ZERO and (x + r * 1.6 < vr.position.x or x - r * 1.6 > vr.end.x):
			continue
		var life: float = clampf(minf(c.t, c.dur - c.t) / 2.0, 0.0, 1.0)   # fade in / out
		var seed_v: int = int(c.seed)
		for k in 7:
			var a = float(seed_v % 97 + k * 53)
			var ox = sin(a * 1.7 + battle.time * 0.4 + k) * r * 0.75
			var oy = -40.0 - absf(cos(a * 0.9 + k)) * 70.0 + sin(battle.time * 0.7 + k) * 6.0
			var pr = r * (0.55 + 0.08 * float(k % 3))
			var col = Color(0.62, 0.78, 0.22, 0.12 * life) if k % 2 == 0 else Color(0.78, 0.82, 0.3, 0.09 * life)
			draw_texture_rect(FxLayer.DOT, Rect2(x + ox - pr, Combat.GROUND_Y + oy - pr * 0.7, pr * 2.0, pr * 1.4), false, col)
		# a low, denser ground band so the footprint of the damage area reads clearly
		draw_texture_rect(FxLayer.DOT, Rect2(x - r, Combat.GROUND_Y - 34.0, r * 2.0, 44.0), false, Color(0.55, 0.72, 0.18, 0.16 * life))


## M006 thermals: a translucent shimmering column per thermal; motes rise in an updraft (warm) and
## fall in a downdraft (cool). All motes come from the shared DOT texture, so they batch.
func _draw_thermals(vr: Rect2) -> void:
	for c in battle.thermals:
		var x: float = c.x
		var w: float = c.w
		if vr.size != Vector2.ZERO and (x + w < vr.position.x or x - w > vr.end.x):
			continue
		var up: bool = float(c.dir) > 0.0
		var base = Color(1.0, 0.86, 0.6, 0.06) if up else Color(0.6, 0.78, 1.0, 0.07)
		var top_y = 110.0
		var bot_y = Combat.GROUND_Y - 10.0
		draw_rect(Rect2(x - w * 0.5, top_y, w, bot_y - top_y), base)
		draw_rect(Rect2(x - w * 0.22, top_y, w * 0.44, bot_y - top_y), Color(base.r, base.g, base.b, base.a * 1.1))
		var tm: float = battle.time
		for k in 14:
			var ph = fposmod(tm * (0.22 + 0.03 * float(k % 4)) + float(k) * 0.137, 1.0)
			var yy = lerpf(bot_y, top_y, ph) if up else lerpf(top_y, bot_y, ph)
			var xx = x + sin(tm * 1.7 + k * 2.3) * w * 0.38
			var a = 0.32 * sin(ph * PI)
			var col = Color(1.0, 0.95, 0.8, a) if up else Color(0.8, 0.9, 1.0, a)
			var r = 3.0 + float(k % 3)
			draw_texture_rect(FxLayer.DOT, Rect2(xx - r, yy - r * 2.2, r * 2.0, r * 4.4), false, col)
		# heat-haze chevrons so the direction reads at a glance
		for j in 3:
			var cy = fposmod((tm * 60.0 * (1.0 if up else -1.0)) + j * 140.0, bot_y - top_y) + top_y
			var d = -10.0 if up else 10.0
			var cc = Color(1, 1, 1, 0.16)
			draw_polyline(PackedVector2Array([Vector2(x - 14, cy - d), Vector2(x, cy), Vector2(x + 14, cy - d)]), cc, 2.0)


## M007 over-unit foundry effects: vent eruptions (warning ring, then a pillar of fire) and falling gantry girders.
func _draw_foundry_over(vr: Rect2) -> void:
	var gy = Combat.GROUND_Y
	# wrecks: the machine's own art, darkened (Unit._wreck_look), with torn, scorched plates and embers on top
	for w in battle.wrecks:
		var u = w.unit
		if not is_instance_valid(u):
			continue
		var wx: float = u.position.x
		if vr.size != Vector2.ZERO and (wx < vr.position.x - 80.0 or wx > vr.end.x + 80.0):
			continue
		var hgt = clampf(Painter.art_height(u.art) * u.art_scale, 30.0, 220.0)
		var top = u.position.y - hgt
		var sd = int(w.serial)
		for k in 3:
			var px = wx + float((sd * 37 + k * 53) % 60) - 30.0
			var py = lerpf(top + hgt * 0.25, u.position.y - 12.0, float((sd * 13 + k * 29) % 100) / 100.0)
			var r = 6.0 + float((sd + k * 7) % 6)
			draw_colored_polygon(PackedVector2Array([Vector2(px - r, py), Vector2(px - r * 0.3, py - r * 0.8), Vector2(px + r * 0.6, py - r * 0.4), Vector2(px + r, py + r * 0.3), Vector2(px - r * 0.2, py + r * 0.7)]), Color(0.06, 0.05, 0.05, 0.75))
		# a torn plate sticking up, and embers in the hull
		var tp = Vector2(wx + float((sd * 11) % 30) - 15.0, top + hgt * 0.35)
		draw_colored_polygon(PackedVector2Array([tp, tp + Vector2(10, -14), tp + Vector2(14, -10), tp + Vector2(6, 2)]), Color(0.32, 0.29, 0.27))
		var fl = 0.5 + 0.5 * sin(battle.time * 9.0 + float(sd))
		draw_texture_rect(FxLayer.DOT, Rect2(wx - 10.0, u.position.y - hgt * 0.45 - 8.0, 20.0, 16.0), false, Color(1.0, 0.45, 0.12, 0.35 + 0.25 * fl))
	for e in battle.eruptions:
		var x: float = e.x
		if vr.size != Vector2.ZERO and (x < vr.position.x - 80.0 or x > vr.end.x + 80.0):
			continue
		var r: float = e.r
		if float(e.t) < float(e.warn):
			var k = float(e.t) / maxf(0.01, float(e.warn))
			draw_arc(Vector2(x, gy - 2.0), r * (0.5 + 0.5 * k), PI, TAU, 16, Color(1.0, 0.55, 0.15, 0.5 + 0.4 * k), 2.5)
			draw_texture_rect(FxLayer.DOT, Rect2(x - r, gy - 14.0 - 10.0 * k, r * 2.0, 24.0 + 10.0 * k), false, Color(1.0, 0.45, 0.1, 0.25 + 0.3 * k))
		else:
			var k2 = 1.0 - (float(e.t) - float(e.warn)) / Foundry.ERUPT_TIME
			var h = 150.0 * clampf(k2 * 1.6, 0.0, 1.0)
			for j in 6:
				var yy = gy - h * (float(j) / 6.0)
				var ww = r * (1.2 - 0.12 * j) + 6.0 * sin(battle.time * 20.0 + j)
				var col = Color(1.0, 0.85 - j * 0.08, 0.35 - j * 0.04, 0.55 * k2) if j < 3 else Color(1.0, 0.5, 0.12, 0.45 * k2)
				draw_texture_rect(FxLayer.DOT, Rect2(x - ww * 0.5, yy - 34.0, ww, 44.0), false, col)
	# Corpse Colossus: a corpse tumbling along its arc toward the stronghold
	for c in battle.corpse_throws:
		var k3 = clampf(float(c.t) / maxf(0.01, float(c.dur)), 0.0, 1.0)
		var cx = lerpf(float(c.x0), float(c.x1), k3)
		var cy = lerpf(float(c.y0), gy - 40.0, k3) - sin(k3 * PI) * 220.0
		var rot = battle.time * 7.0
		var body = PackedVector2Array()
		for j in 7:
			var aa = rot + TAU * float(j) / 7.0
			body.append(Vector2(cx, cy) + Vector2.from_angle(aa) * (12.0 + 4.0 * float(j % 3)))
		draw_colored_polygon(body, Color(0.45, 0.42, 0.32))
		draw_line(Vector2(cx, cy), Vector2(cx, cy) + Vector2.from_angle(rot + 1.0) * 20.0, Color(0.85, 0.82, 0.7), 3.0)
		draw_texture_rect(FxLayer.DOT, Rect2(cx - 18.0, cy - 18.0, 36.0, 36.0), false, Color(0.55, 0.9, 0.3, 0.25))
	for rf in battle.rockfalls:
		if String(rf.get("variant", "")) != "gantry":
			continue
		var x2: float = rf.x
		var warn = float(rf.get("warn", 2.2))
		var t2: float = rf.t
		# the girder sags and swings on its last rivets, then drops in the final 0.35 s
		var drop = clampf((t2 - (warn - 0.35)) / 0.35, 0.0, 1.0)
		var y = lerpf(118.0, gy - 18.0, drop * drop)
		var ang = 0.22 * sin(t2 * 5.0) * (1.0 - drop) + 0.12
		var hl = float(rf.r) * 1.25
		var dv = Vector2(cos(ang), sin(ang))
		var nv = Vector2(-dv.y, dv.x)
		var c = Vector2(x2, y)
		var a = c - dv * hl
		var bpt = c + dv * hl
		var col2 = Color(0.36, 0.3, 0.26)
		draw_colored_polygon(PackedVector2Array([a - nv * 7.0, bpt - nv * 7.0, bpt + nv * 7.0, a + nv * 7.0]), col2)
		var truss = PackedVector2Array()
		for k in 6:
			var p0 = a.lerp(bpt, float(k) / 6.0)
			var p1 = a.lerp(bpt, float(k + 1) / 6.0)
			truss.append_array([p0 - nv * 6.0, p1 + nv * 6.0])
		draw_multiline(truss, Color(0.2, 0.17, 0.15), 2.0)
		draw_line(a - nv * 7.0, bpt - nv * 7.0, Color(0.55, 0.46, 0.38), 2.0)
		if drop <= 0.0:
			# the last chain still holding it
			draw_line(a, Vector2(a.x - 6.0, 40.0), Color(0.25, 0.23, 0.22), 2.0)
		# telegraph shadow on the lane, darker as it falls
		draw_texture_rect(FxLayer.DOT, Rect2(x2 - hl, gy - 8.0, hl * 2.0, 16.0), false, Color(0, 0, 0, 0.2 + 0.4 * clampf(t2 / warn, 0.0, 1.0)))


## M006 lightning: a flickering warning fork over the target, then the bolt and a screen flash.
func _draw_bolts(vr: Rect2) -> void:
	for b in battle.bolts:
		var x: float = b.x
		var y: float = b.y
		if b.t < b.warn:
			# 0.8 s warning flicker: a ring and a crackling spark over the doomed target
			if int(b.t * 14.0) % 2 == 0:
				draw_arc(Vector2(x, y - 6.0), 26.0 + 6.0 * sin(b.t * 30.0), 0, TAU, 18, Color(0.85, 0.9, 1.0, 0.85), 2.5)
				draw_line(Vector2(x, y - 70.0), Vector2(x + 7.0, y - 44.0), Color(0.9, 0.95, 1.0, 0.7), 2.0)
				draw_line(Vector2(x + 7.0, y - 44.0), Vector2(x - 4.0, y - 26.0), Color(0.9, 0.95, 1.0, 0.7), 2.0)
		else:
			var k = 1.0 - (b.t - b.warn) / 0.3
			var pts = PackedVector2Array()
			var yy = 40.0
			var xx = x + 30.0
			var seg = 0
			while yy < y:
				pts.append(Vector2(xx, yy))
				yy += 46.0
				seg += 1
				xx = x + (((seg * 37 + int(x)) % 41) - 20.0) * (1.0 - yy / maxf(y, 1.0))
			pts.append(Vector2(x, y))
			draw_polyline(pts, Color(0.55, 0.65, 1.0, 0.55 * k), 9.0)
			draw_polyline(pts, Color(1, 1, 1, 0.95 * k), 3.0)
	if battle.flash_t > 0.0 and vr.size != Vector2.ZERO:
		draw_rect(vr, Color(0.85, 0.9, 1.0, battle.flash_t * 1.2))


class BogPaint extends Node2D:
	var battle

	func _draw() -> void:
		if battle == null:
			return
		for b in battle.bog_spots:
			var x: float = b.x
			var w: float = b.w
			var y = Combat.GROUND_Y + 6.0
			var pts = Painter.ell_pts(Vector2(x, y), w * 0.5, 26.0, 0.0, 22)
			draw_colored_polygon(pts, Color(0.12, 0.13, 0.07, 0.92))
			var inner = Painter.ell_pts(Vector2(x - w * 0.05, y - 2.0), w * 0.42, 18.0, 0.0, 18)
			draw_colored_polygon(inner, Color(0.2, 0.24, 0.1, 0.9))
			# standing water sheen and reeds at the edges (kept low, so feet stay visible)
			draw_line(Vector2(x - w * 0.3, y - 6.0), Vector2(x + w * 0.1, y - 6.0), Color(0.55, 0.68, 0.45, 0.35), 2.0)
			draw_line(Vector2(x - w * 0.05, y + 4.0), Vector2(x + w * 0.28, y + 4.0), Color(0.55, 0.68, 0.45, 0.25), 1.5)
			for k in 7:
				var rx = x - w * 0.5 + (k * 37) % int(w)
				if absf(rx - x) < w * 0.38:
					continue
				var h = 14.0 + float((k * 13) % 9)
				draw_line(Vector2(rx, y + 2.0), Vector2(rx + 2.0, y - h), Color(0.3, 0.32, 0.14), 2.0)
				draw_rect(Rect2(rx, y - h - 6.0, 4, 7), Color(0.32, 0.22, 0.12))
