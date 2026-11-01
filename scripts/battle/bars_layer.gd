class_name BarsLayer
extends Node2D
## All unit health / ability bars in one canvas item drawn above the units. Keeping bars out of
## each unit's own drawing lets every unit be a single atlas quad, so units batch together.

var battle


func _ready() -> void:
	z_index = 400


func _draw() -> void:
	if battle == null:
		return
	var vr: Rect2 = battle.view_rect
	for u in battle.units:
		if not u.alive or u.burrowed or u.is_stronghold:
			continue
		if not (u.hp < u.max_hp or battle.show_all_bars):
			continue
		if vr.size != Vector2.ZERO and (u.position.x < vr.position.x - 80.0 or u.position.x > vr.end.x + 80.0):
			continue
		var h: float = Painter.art_height(u.art)
		var y: float
		if u.domain == "ground":
			y = u.position.y - h * u.art_scale - 8.0
		else:
			y = u.position.y - (h * 0.6 + 10.0) * u.art_scale
		var w = clampf(u.radius * 2.2, 18.0, 110.0)
		var x0 = u.position.x - w * 0.5
		draw_rect(Rect2(x0 - 1.0, y - 1.0, w + 2.0, 5.0), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(x0, y, w * u.hp_frac, 3.0), Color(0.4, 0.85, 0.35) if u.side == 0 else Color(0.85, 0.3, 0.3))
		if u.is_mech and not u.ability.is_empty():
			var af: float = 1.0 - clampf(u.ability_cd / maxf(1.0, float(u.ability.cooldown)), 0.0, 1.0)
			draw_rect(Rect2(x0, y + 4.0, w * af, 2.0), Color(0.75, 0.9, 1.0, 0.85) if not u.is_giant else Color(0.45, 1.0, 0.55, 0.85))
