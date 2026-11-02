class_name Unit
extends Node2D
## Shared, data-driven battlefield entity. One script serves every implemented unit, enemy,
## boss and stronghold; differences come from the registry definition (stats, weapons,
## behavior key, art id). Behaviors are small state machines selected by `behavior`.

var battle                          # Battle
var def: Dictionary
var id: String
var side: int = 0
var dir: float = 1.0
var facing: float = 1.0
var domain: String = "ground"
var cls: String = "infantry"
var behavior: String = "melee"
var art: String = ""
var armor: String = "flesh"
var hp: float = 100.0
var max_hp: float = 100.0
var radius: float = 10.0
var speed: float = 30.0
var alive := true
var dying_t: float = -1.0
var weapons: Array = []
var velocity: Vector2 = Vector2.ZERO
var lane: float = 0.0
var serial: int = 0

var is_structure := false
var is_stronghold := false
var is_static := false
var blocks := true
var frontline := false
var hold_behind := false
var taunt := false
var low_profile := false
var burrowed := false
var spotted := false

# animation interface for Painter
var t: float = 0.0
var walk: float = 0.0
var atk: float = 0.0
var atk2: float = 0.0
var atk3: float = 0.0
var reload: float = 0.0
var hurt: float = 0.0
var gag: float = 0.0       # M004: post-attack recovery timeline (1 -> 0 over ~0.8 s): hat pops, springs, settles
var state: String = "idle"
var special: float = 0.0
var windup: float = 0.0
var aim0: float = 0.0
var aim1: float = 0.0
var aim2: float = 0.0
var hp_frac: float = 1.0
var ammo: int = 0
var bank: float = 0.0

# behavior state
var mode: String = "advance"
var mode_t: float = 0.0
var alt_target: float = 300.0
var home_x: float = 0.0
var overdrive_t: float = 0.0
var repair_pool: float = 0.0
var raised: Array = []
var raised_by = null
var last_damaged_t: float = -99.0
var kills: int = 0
var exposed := false
var support_alive: Array = []
var support_t: float = 0.0
var stuck_t: float = 0.0
var last_x: float = 0.0
var hit_flash: float = 0.0
var last_hit_by := ""

# M002 war-frame state (shared by every mech; behaviour comes from data)
var art_scale: float = 1.0
var is_mech := false
var is_giant := false
var summoner = null
var is_boss := false
var _acds := {}              # boss: per-ability cooldowns
var _boss_gap := 0.0
var _enraged := false
var phase_on := false          # M005: boss 50 % phase active
var phase_t := 0.0
var perch_t := 0.0             # Gravewing Matriarch: seconds left perched on the nest (ground-targetable)
var phase_heralds: Array = []
# ---- M006 air war
var band: int = 1                  # altitude band: 0 low, 1 mid, 2 high (flyers only)
var band_shift: int = 0            # thermals push a flyer up (+1) or down (-1) a band while inside a column
var thermal: float = 0.0           # -1 downdraft .. +1 updraft (set by Battle each step)
var _reach_max: int = -1
var shielded := false              # Hollow Admiral: immune while its escorts hold
var escort_def: Dictionary = {}    # supply barge route (stage data)
var delivered := false
var dive_t: float = 0.0            # Bone Wyrm: seconds left under the chasm
var land_t: float = 0.0            # Bone Wyrm / Dread Sky Tyrant: seconds left on the ground
# ---- M006 motion layer: smooth node-level secondary motion over the (stepped) pose-cache sprites
var mo_y: float = 0.0              # spring: vertical compression (+ = squashed)
var mo_vy: float = 0.0
var mo_k: float = 0.0              # spring: lean / kick (skew, + = leaning back from the facing)
var mo_vk: float = 0.0
var mo_roll: float = 0.0           # airships: roll spring (broadsides, hits)
var mo_vroll: float = 0.0
var _mo_step := 0.0
var _xt := 0.0               # extras timer (auras)
var _deploy_t := 0.0
var _mine_t := 0.0
var _deployed: Array = []
var has_extras := false
var _seek = null
var _seek_t := 0.0      # giant that spawned this unit (summon caps)   # M002b undead giants share the war-frame rig/state machine
var mech_class := ""
var death_time: float = 1.2
var ability: Dictionary = {}
var ability_cd: float = 0.0
var ability_wind: float = -1.0       # >= 0 while an ability winds up
var ability_anim: float = 0.0        # 1 on activation, decays (art)
var ability_name := ""
var buffs: Array = []                # {mods: Dictionary, t: float}
var slow_t: float = 0.0
var slow_mult: float = 1.0
var stun_t: float = 0.0
var wlock: Dictionary = {}           # weapon index -> seconds locked (cooling)
var heat_after: float = 0.0
var heat_after_at: float = 0.0
var heat_lock_t: float = 0.0
var brace_t: float = 0.0
var charge_left: float = 0.0
var charge_hit := false
var turn_t: float = 0.0
var engage: float = 0.0              # 0..1 target-acquisition pose
var front_guard: float = 0.0
var spin: float = 0.0                # drill / rotary barrel rotation
var recoil: float = 0.0              # whole-frame recoil (boomsticks, cannons)
var _step_phase: float = 0.0
var _death_fx_done: int = 0
var has_w1 := false
var repair_window_t := -1.0
var repair_this_step := 0.0
var has_w2 := false
# ---- M007 wreck reclamation
var wreck_hold := false            # dead machine kept on the field as a wreck (Foundry)
var channel_wreck = null           # corruptor: the wreck it is walking to / channelling
var salvage_wreck = null           # salvage unit: the wreck it is clearing
var _wreck_seek_t := 0.0
var raised_from_wreck := false
var is_reclaimer := false
var is_salvager := false
var lit := false                   # M008 eclipse: carries light or stands in a light source's radius
var aura_dr := 0.0                 # M008: damage reduction from an aura (obelisk ward, Hollow King's crown)
var aura_dr_t := -1.0              # battle time the aura expires
var aloft := false                 # M008 Rift Lich: risen into the rift (fights from the air, no ground movement)
var weak_core_t := 0.0             # Fallen Titan: plates torn away, core exposed (+25 % damage taken)


func setup(b, unit_def: Dictionary, s: int, pos: Vector2) -> void:
	battle = b
	def = unit_def
	id = def.id
	side = s
	dir = Combat.dir_of(s)
	facing = dir
	domain = def.get("domain", "ground")
	cls = def.get("cls", "infantry")
	behavior = def.get("behavior", "melee")
	art = def.get("art", id)
	armor = def.get("armor", "flesh")
	max_hp = float(def.get("hp", 100)) * (b.enemy_hp_mult if s == 1 and cls != "stronghold" and not def.get("fixed_hp", false) else 1.0)
	hp = max_hp
	radius = float(def.get("radius", 10))
	speed = float(def.get("speed", 30))
	blocks = def.get("blocks", true)
	frontline = def.get("frontline", false)
	hold_behind = def.get("hold_behind", false)
	taunt = def.get("taunt", false)
	low_profile = def.get("low_profile", false)
	is_static = def.get("static", false) or cls == "stronghold" or cls == "structure"
	is_structure = cls == "structure" or cls == "stronghold"
	is_stronghold = cls == "stronghold"
	ammo = int(def.get("ammo", 0))
	repair_pool = float(def.get("repair", {}).get("pool", 0))
	art_scale = float(def.get("art_scale", 1.0))
	is_mech = behavior == "mech" or behavior == "giant" or behavior == "boss"
	is_giant = behavior == "giant" or behavior == "boss"
	is_boss = behavior == "boss" or behavior == "boss_air"
	has_extras = def.has("aura") or def.has("steam_gen") or def.has("deploys") or def.has("mines") or is_boss
	_deploy_t = float(def.get("deploys", {}).get("interval", 10.0)) * 0.5
	_mine_t = float(def.get("mines", {}).get("interval", 8.0)) * 0.5
	var tint = def.get("tint", ArtKit.params(String(def.get("art", ""))).get("tint", ""))
	if String(tint) != "":
		modulate = Color(String(tint))
	has_w1 = def.get("weapons", []).size() > 1
	has_w2 = def.get("weapons", []).size() > 2
	mech_class = String(def.get("mech_class", ""))
	death_time = float(def.get("death_time", 1.2))
	front_guard = float(def.get("front_guard", 0.0))
	ability = def.get("ability", {}) if def.get("ability") != null else {}
	ability_cd = float(ability.get("cooldown", 0)) * 0.35 if not ability.is_empty() else 0.0
	if s == 1 and b.heroic:
		# M007 Heroic: enemy abilities come ready earlier
		ability_cd *= float(b.stage.get("heroic_ability_lead", 0.45))
	is_reclaimer = s == 1 and def.get("reclaims", false)
	is_salvager = s == 0 and def.get("salvages", false)
	position = pos
	home_x = Combat.base_x(s)
	last_x = pos.x
	t = b.rng.randf() * 10.0
	special = b.rng.randf() * TAU if art == "carrion_bat" else 0.0
	var i = 0
	for wd in def.get("weapons", []):
		weapons.append(Weapon.new(wd, i, b.rng))
		i += 1
	band = int({"low": 0, "mid": 1, "high": 2}.get(String(def.get("band", "mid")), 1))
	if domain == "air" and band == 2 and cls != "boss":
		modulate = modulate * Color(0.86, 0.9, 1.0)   # M006 readability: high flyers sit in a faint sky haze
	if domain == "air":
		var alt: Array = def.get("altitude", [260, 320])
		alt_target = b.rng.randf_range(float(alt[0]), float(alt[1]))
	else:
		lane = 0.0 if is_static else b.rng.randf_range(-18.0, 18.0)
		position.y = Combat.GROUND_Y + lane
	if behavior == "burrower":
		burrowed = true
		state = "burrowed"
	if behavior == "boss_mine_maw":
		mode = "surface"
		special = 0.0
	scale = Vector2(facing * art_scale, art_scale)
	z_index = _z()


func _z() -> int:
	if domain == "air":
		return 150 if cls == "airship" else 200
	if is_stronghold:
		return -20
	if is_mech:
		# big frames stand behind smaller units so infantry stays readable
		return 8 - int(art_scale * 3.0) + int(position.y - Combat.GROUND_Y)
	return 10 + int(position.y - Combat.GROUND_Y) + (5 if cls == "vehicle" or cls == "walker" else 0)


var _aim_off := Vector2(INF, 0)


## Point other weapons aim at. The offset is fixed per unit, so it is computed once (this is
## called inside every spatial query — the old per-call art lookup was a measurable hot spot).
func aim_point() -> Vector2:
	if _aim_off.x == INF:
		if domain == "air":
			_aim_off = Vector2.ZERO
		elif is_stronghold:
			_aim_off = Vector2(0, -90)
		elif is_mech:
			_aim_off = Vector2(0, -Painter.art_height(art) * art_scale * 0.5)
		else:
			_aim_off = Vector2(0, -minf(Painter.art_height(art) * 0.45, 40.0))
	return position + _aim_off


## M006: current altitude band (thermals shift it while a flyer is inside a column).
func band_i() -> int:
	return clampi(band + band_shift, 0, 2)


## Highest band any of this unit's sky-capable weapons can reach (-1: none).
func max_reach() -> int:
	if _reach_max < 0:
		_reach_max = 0
		for w in weapons:
			if w.targets != "ground":
				_reach_max = maxi(_reach_max, w.reach)
	return _reach_max


func targetable_by(_attacker_side: int) -> bool:
	if not alive:
		return false
	if burrowed and not spotted:
		return false
	return true


func fire_rate_mult() -> float:
	var m = 1.0
	if overdrive_t > 0.0:
		m *= 1.5
	return m * buff("fire")


func buff(k: String) -> float:
	var m = 1.0
	for bf in buffs:
		if bf.mods.has(k):
			m *= float(bf.mods[k])
	return m


func buff_add(k: String) -> float:
	var v = 0.0
	for bf in buffs:
		if bf.mods.has(k):
			v += float(bf.mods[k])
	return v


func add_buff(mods: Dictionary, dur: float) -> void:
	buffs.append({"mods": mods, "t": dur})


func apply_slow(mult: float, dur: float) -> void:
	if is_static or cls == "boss":
		return
	slow_mult = minf(slow_mult if slow_t > 0.0 else 1.0, mult)
	slow_t = maxf(slow_t, dur)


func can_fire(w) -> bool:
	if stun_t > 0.0 or heat_lock_t > 0.0:
		return false
	return float(wlock.get(w.index, 0.0)) <= 0.0


func damage_mult(w: Weapon, b) -> float:
	var m = 1.0
	if cls == "artillery" and side == 0 and b.spotting_active:
		m *= b.spot_dmg_mult
	if overdrive_t > 0.0:
		m *= 1.1
	return m * buff("dmg")


func move_speed() -> float:
	var s = speed
	if overdrive_t > 0.0:
		s *= 1.3
	if slow_t > 0.0:
		s *= slow_mult
	return s * buff("speed")


func on_windup(_w: Weapon, dur: float) -> void:
	windup = 1.0
	mode_t = 0.0
	if is_mech and float(_w.d.get("splash", 0)) >= 40.0:
		battle.fx.telegraph(_w.windup_pos, float(_w.d.get("splash", 40)), dur, Color(1, 0.7, 0.3))
	if art == "flesh_hulk" or art == "mine_maw":
		battle.fx.telegraph(_w.windup_pos, float(_w.d.get("splash", 40)), dur, Color(1, 0.4, 0.2))


func on_fire(w: Weapon) -> void:
	if is_mech and w.family in ["cannon", "siege", "mortar", "repeater"]:
		recoil = 1.0
	_motion_kick(w)
	if w.index == 0 or is_mech:
		gag = 1.0
	match w.index:
		0: atk = 1.0
		1: atk2 = 1.0
		_: atk3 = 1.0
	if w.d.get("reload_anim", false):
		reload = 1.0


# =============================================================== main step
func step(dt: float) -> void:
	t += dt
	if not alive:
		dying_t += dt
		if is_mech:
			_mech_death(dt)
			if wreck_hold:
				_wreck_look(dt)
			_request_redraw()
			return
		if wreck_hold:
			_wreck_look(dt)
			_request_redraw()
			return
		modulate.a = clampf(1.0 - (dying_t - 0.5) / 0.6, 0.0, 1.0)
		if domain == "air":
			position.y = minf(Combat.GROUND_Y - 10.0, position.y + dt * (160.0 + dying_t * 300.0))
			rotation += dt * 2.5 * facing
		elif side == 0 and cls in ["infantry", "engineer"]:
			# M007: dwarves flop over backwards like a felled log, with a little bounce when they land
			var k = clampf(dying_t / 0.42, 0.0, 1.0)
			var flop = k * k * (3.0 - 2.0 * k)
			var bounce = sin(clampf((dying_t - 0.42) / 0.3, 0.0, 1.0) * PI) * 0.12
			rotation = -facing * (1.35 * flop - bounce)
		else:
			rotation = lerpf(rotation, -0.9 * facing if not is_structure else 0.0, dt * 4.0)
		_request_redraw()
		return
	atk = maxf(0.0, atk - dt * 2.2)
	atk2 = maxf(0.0, atk2 - dt * 2.2)
	atk3 = maxf(0.0, atk3 - dt * 2.2)
	reload = maxf(0.0, reload - dt * 0.65)
	hurt = maxf(0.0, hurt - dt * 3.0)
	gag = maxf(0.0, gag - dt * (1.05 if is_mech else 1.25))
	hit_flash = maxf(0.0, hit_flash - dt * 6.0)
	overdrive_t = maxf(0.0, overdrive_t - dt)
	if is_mech or is_boss or not buffs.is_empty() or slow_t > 0.0 or stun_t > 0.0:
		_tick_mech_timers(dt)
	if has_extras:
		_extras(dt)
	if windup > 0.0:
		windup = maxf(0.01, windup)
	var prev = position
	var prev_facing = facing
	var _b0 = Time.get_ticks_usec() if battle.profiling else 0
	var busy = is_reclaimer and not battle.wrecks.is_empty() and Foundry.corruptor_step(self, battle, dt)
	if busy:
		pass   # M007: walking to / channelling a wreck (no attacks meanwhile)
	else:
		_behave(dt)
	if battle.profiling:
		var _bd = Time.get_ticks_usec() - _b0
		battle.prof.behavior = battle.prof.get("behavior", 0) + _bd
		battle.prof["b_" + behavior] = battle.prof.get("b_" + behavior, 0) + _bd
	if not burrowed and not busy:
		var _w0 = Time.get_ticks_usec() if battle.profiling else 0
		for w in weapons:
			w.update(self, dt, battle)
		if battle.profiling:
			battle.prof.weapons = battle.prof.get("weapons", 0) + Time.get_ticks_usec() - _w0
	_after_step(prev, prev_facing, dt)


func _behave(dt: float) -> void:
	match behavior:
		"melee", "ranged", "vehicle", "walker", "artillery", "burrower", "crawler":
			_ground(dt)
		"repair":
			_repair(dt)
		"necromancer":
			_necromancer(dt)
		"structure", "stronghold":
			pass
		"interceptor", "scout":
			_interceptor(dt)
		"bomber":
			_bomber(dt)
		"gunship":
			_gunship(dt)
		"airship":
			_airship(dt)
		"bat":
			_bat(dt)
		"shrieker":
			_shrieker(dt)
		"boss_mine_maw":
			BossMineMaw.step(self, dt)
		"mech", "giant", "boss":
			_mech(dt)
		"boss_air":
			if dive_t <= 0.0:
				MechAbility.step(self, battle, dt)
			if stun_t <= 0.0 and perch_t <= 0.0 and dive_t <= 0.0:
				_shrieker(dt)
		"air_repair":
			_air_repair(dt)
		"escort":
			_escort(dt)


func _after_step(prev: Vector2, prev_facing: float, dt: float) -> void:
	velocity = (position - prev) / maxf(dt, 0.0001)
	if domain == "ground":
		var moved = absf(position.x - prev.x)
		if moved > 0.05:
			walk += moved * 0.16
			if state != "burrowed" and state != "exposed":
				state = "move"
		elif state == "move":
			state = "idle"
		# turn to face current target (fixed mounts excluded)
		if not is_static and weapons.size() > 0 and weapons[0].target != null and is_instance_valid(weapons[0].target):
			var tx: float = weapons[0].target.position.x - position.x
			if absf(tx) > 4.0:
				facing = signf(tx)
		elif moved > 0.05:
			facing = signf(position.x - prev.x)
	else:
		walk += dt * 6.0
		if absf(velocity.x) > 8.0:
			facing = signf(velocity.x)
		elif weapons.size() > 0 and weapons[0].target != null and is_instance_valid(weapons[0].target):
			facing = signf(weapons[0].target.position.x - position.x) if absf(weapons[0].target.position.x - position.x) > 4.0 else facing
		bank = lerpf(bank, clampf(velocity.y * 0.004, -0.3, 0.3) * facing, dt * 5.0)
		rotation = bank if cls != "airship" else 0.0
	if weapons.size() > 0:
		aim0 = weapons[0].aim
	if weapons.size() > 1:
		aim1 = weapons[1].aim
	if weapons.size() > 2:
		aim2 = weapons[2].aim
	hp_frac = hp / max_hp
	if is_mech and facing != prev_facing:
		turn_t = {"light": 0.2, "medium": 0.35, "heavy": 0.5, "colossal": 0.7}.get(mech_class, 0.3)   # mechanical pause on turning
	scale = Vector2(facing * art_scale, art_scale)
	if domain == "ground" and not is_static:
		position.y = Combat.GROUND_Y + lane
	_motion(dt)
	z_index = _z()
	var _r0 = Time.get_ticks_usec() if battle.profiling else 0
	_request_redraw()
	if battle.profiling:
		battle.prof.redraw_req = battle.prof.get("redraw_req", 0) + Time.get_ticks_usec() - _r0


# =============================================================== M006 motion layer
## Smooth secondary motion applied as the node's own transform (scale, skew, rotation, a small bob),
## on top of the art's pose. It costs a few float operations per unit and no draw calls, and it moves
## every frame even when the pose-cache sprite itself is stepped (~8-12 fps), so walk cycles, recoil,
## footfalls and hits read as weighty and continuous on every quality preset.
##   infantry  stride hop + squash on the planted foot, forward lean, breathing idle; dwarves bounce
##             (goofy), the undead lurch and sway (never bouncy)
##   vehicles  engine idle shiver, suspension pitch over the ground, a rearing kick when the gun fires
##   walkers   each footfall drops the frame onto the planted foot and rolls its weight across;
##             mass-scaled recoil with a slow spring settle; boiler breathing at idle
##   artillery the whole piece rears back on firing and settles
##   aircraft  a damaged wobble on top of the existing bank; airships pitch slowly, roll away from
##             their own broadsides and list when badly hurt
##   flyers    wingbeat squash-and-stretch (slow and heavy for drakes and wyrms)
static var motion_on := true


var _mass_c := -1.0


func _mo_mass() -> float:
	if _mass_c < 0.0:
		_mass_c = _mo_mass_calc()
	return _mass_c


func _mo_mass_calc() -> float:
	if is_mech:
		return {"light": 1.4, "medium": 1.9, "heavy": 2.6, "colossal": 3.4}.get(mech_class, 1.8)
	match cls:
		"vehicle":
			return 1.8
		"artillery":
			return 1.5
		"airship":
			return 3.0
		"structure", "stronghold":
			return 6.0
	return 1.0


func _motion_kick(w: Weapon) -> void:
	if not motion_on:
		return
	var dmg = float(w.d.get("damage", 10)) * float(w.d.get("pellets", 1))
	var heavy_gun = w.family in ["cannon", "siege", "mortar"] or w.proj in ["shell", "arc", "mortar"] or dmg >= 45.0
	var m = _mo_mass()
	if cls == "airship":
		mo_vroll -= (0.55 if heavy_gun else 0.12) / m * 3.0
		return
	if domain == "air":
		mo_vroll -= 0.25 if heavy_gun else 0.05
		return
	var k = (16.0 if heavy_gun else 5.0) * clampf(0.6 + dmg / 80.0, 0.6, 2.0) / m
	if w.proj == "melee":
		k = -6.0 / m        # melee lunges forward instead of rearing back
	mo_vk -= k
	mo_vy += absf(k) * 0.9


func _motion(dt: float) -> void:
	if not motion_on or is_stronghold or not alive or is_static:
		skew = 0.0
		return
	if battle.view_rect.size != Vector2.ZERO and not visible_on_screen():
		return   # off screen: nothing to animate (springs resume when it scrolls back in)
	var m = _mo_mass()
	var stiff = 260.0 / m
	var damp = 2.0 * sqrt(stiff) * (0.42 if is_mech else 0.55)   # under-damped: mechs wobble as they settle
	mo_vy += (-stiff * mo_y - damp * mo_vy) * dt
	mo_y += mo_vy * dt
	mo_vk += (-stiff * mo_k - damp * mo_vk) * dt
	mo_k += mo_vk * dt
	mo_y = clampf(mo_y, -3.0, 3.0)
	mo_k = clampf(mo_k, -3.0, 3.0)
	var sy = 1.0 - mo_y * 0.035
	var lean = 0.0
	var bob = 0.0
	var moving = state == "move"
	if domain == "ground":
		if is_static:
			lean = mo_k * 0.02
		elif is_mech:
			# boiler breathing at idle; a slow sway on the march (giants lumber, frames sway on their hips)
			if not moving:
				sy *= 1.0 + 0.012 * sin(t * (1.7 if not is_giant else 1.1))
			else:
				lean += 0.035 * sin(walk) * (1.6 if is_giant else 1.0)
			lean += mo_k * 0.05
			bob = mo_y * 1.6
		elif cls == "vehicle":
			# engine shiver at idle, suspension pitch on the move, rearing kick on firing
			bob = sin(t * 41.0) * 0.45 + (absf(sin(walk * 1.7)) * 1.2 if moving else 0.0)
			lean = (0.018 * sin(walk * 1.3) if moving else 0.0) + mo_k * 0.045
		elif cls == "artillery":
			lean = mo_k * 0.06
			bob = maxf(0.0, mo_y) * 1.2
		else:
			var stride = absf(sin(walk))
			if side == 0:
				# dwarves: springy, a little ridiculous
				if moving:
					sy *= 0.95 + 0.09 * stride
					bob = -stride * 2.6
					lean = 0.075
				else:
					sy *= 1.0 + 0.02 * sin(t * 2.6 + float(serial % 5))
			else:
				# the undead: a heavy forward lurch with a dragging sway
				if moving:
					sy *= 0.98 + 0.03 * stride
					lean = 0.11 + 0.05 * sin(walk * 0.5 + float(serial % 7))
				else:
					lean = 0.04 * sin(t * 0.9 + float(serial % 7))
			lean += mo_k * 0.06
		# the motion layer is purely visual: it never moves the node (positions feed ranges and aim
		# points), so a hop/drop is expressed as stretch/squash about the feet instead
		sy *= 1.0 - bob * 0.012
		scale = Vector2(scale.x * (1.0 + (1.0 - sy) * 0.6), scale.y * sy)
		skew = clampf(facing * lean, -0.4, 0.4)
	else:
		skew = 0.0
		mo_vroll += (-stiff * 0.6 * mo_roll - 2.0 * sqrt(stiff * 0.6) * 0.35 * mo_vroll) * dt
		mo_roll = clampf(mo_roll + mo_vroll * dt, -0.6, 0.6)
		if cls == "airship":
			var list = 0.07 * clampf((0.5 - hp_frac) * 2.0, 0.0, 1.0)
			rotation = 0.028 * sin(t * 0.45 + float(serial % 9)) + (mo_roll * 0.12 + list) * facing
		else:
			var wob = 0.06 * sin(t * 9.0) if hp_frac < 0.35 and cls == "aircraft" else 0.0
			rotation += wob + mo_roll * 0.15 * facing
			if cls == "flyer" or cls == "boss":
				var big = radius > 30.0
				var flap = sin(t * (5.0 if big else 11.0) + float(serial % 5))
				scale = Vector2(scale.x * (1.0 - flap * 0.025), scale.y * (1.0 + flap * (0.04 if big else 0.06)))


# =============================================================== ground behaviors
func _primary_engaged() -> bool:
	if is_giant:
		# giants keep marching while their secondary guns fire; only the main weapon halts them
		return weapons.size() > 0 and weapons[0].target != null and weapons[0].targets != "air"
	for w in weapons:
		if w.target != null and w.targets != "air":
			return true
	return false


func _any_engaged() -> bool:
	for w in weapons:
		if w.target != null:
			return true
	return false


func _ground(dt: float) -> void:
	if behavior == "burrower" and burrowed:
		_burrow_move(dt)
		return
	if is_static or stun_t > 0.0:
		return
	# air-only weapons (flak) never halt the advance; ground-capable weapons do
	if _primary_engaged():
		return
	var limit = _advance_limit()
	var step_x = move_speed() * dt * dir
	var nx = position.x + step_x
	if dir > 0.0:
		nx = minf(nx, limit)
		nx = maxf(nx, position.x - move_speed() * dt)  # may step back a little to restore spacing
	else:
		nx = maxf(nx, limit)
		nx = minf(nx, position.x + move_speed() * dt)
	position.x = nx


## Furthest x this unit may advance to, considering blockers, base faces and formation.
func _advance_limit() -> float:
	var enemy = Combat.enemy_of(side)
	var lim: float = Combat.base_x(enemy) - dir * (Combat.BASE_FACE + radius)
	if behavior != "crawler":
		var blk = battle.nearest_blocker(self)
		if blk != null:
			var bl: float = blk.position.x - dir * (blk.radius + radius - 4.0)
			lim = minf(lim, bl) if dir > 0.0 else maxf(lim, bl)
	if hold_behind or cls == "artillery":
		var front = battle.front_x(side, self)
		if front != null:
			var offset: float = float(def.get("rear_offset", 45))
			var fl: float = float(front) - dir * offset
			lim = minf(lim, fl) if dir > 0.0 else maxf(lim, fl)
		elif cls == "artillery" and weapons.size() > 0 and weapons[0].targets == "air":
			var cap: float = home_x + dir * 420.0
			lim = minf(lim, cap) if dir > 0.0 else maxf(lim, cap)
	return lim


func _burrow_move(dt: float) -> void:
	position.x += move_speed() * 1.35 * dt * dir
	spotted = battle.is_spotted(position)
	var emerge_x: float = lerpf(Combat.UNDEAD_BASE_X, Combat.DWARF_BASE_X, float(def.get("burrow_until", 0.55)))
	var near = battle.nearest_enemy_ground(self, 70.0)
	if near != null or (dir < 0.0 and position.x <= emerge_x) or (dir > 0.0 and position.x >= emerge_x):
		burrowed = false
		spotted = false
		state = "idle"
		battle.fx.dirt_burst(position, 1.0)
		Audio.play("undead_snarl", position.x, -6.0)


## M007: a dead machine held on the field as a wreck: darkened, settled on its belly, smoking (Foundry).
func _wreck_look(dt: float) -> void:
	if domain == "air":
		position.y = minf(Combat.GROUND_Y - 8.0, position.y + dt * (160.0 + dying_t * 300.0))
		rotation = lerpf(rotation, 0.32 * facing, dt * 3.0)
	elif not is_mech:
		rotation = lerpf(rotation, -0.08 * facing, dt * 4.0)
	modulate = Color(0.44, 0.41, 0.39, 1.0)


func _repair(dt: float) -> void:
	var r: Dictionary = def.get("repair", {})
	var rng = float(r.get("range", 140))
	special = maxf(0.0, special - dt * 2.0)
	var patient = null
	if repair_pool > 0.0:
		patient = battle.most_damaged_machine(self, 500.0, r.get("classes", []))
	# M007: salvage units clear wrecks before the undead can reclaim them (unless a machine is badly hurt)
	if is_salvager and not battle.wrecks.is_empty() and (patient == null or patient.hp > patient.max_hp * 0.4):
		if Foundry.salvage_step(self, battle, dt):
			return
	if patient != null:
		var dx: float = patient.position.x - position.x
		var dist = position.distance_to(patient.position)
		if dist > rng * 0.8:
			var front = battle.front_x(side, self)
			var target_x: float = patient.position.x - dir * 30.0
			if front != null:
				target_x = minf(target_x, float(front) - 30.0) if dir > 0.0 else maxf(target_x, float(front) + 30.0)
			var mv = clampf(target_x - position.x, -move_speed() * dt, move_speed() * dt)
			position.x += mv
		if dist <= rng:
			var amt = minf(float(r.get("rate", 20)) * dt, repair_pool)
			amt = minf(amt, patient.max_hp - patient.hp)
			# per-machine repair cap: several crews cannot make a frame effectively immortal
			if patient.repair_window_t != battle.time:
				patient.repair_window_t = battle.time
				patient.repair_this_step = 0.0
			amt = minf(amt, maxf(0.0, battle.REPAIR_CAP_PER_SEC * dt - patient.repair_this_step))
			patient.repair_this_step += amt
			if amt > 0.0:
				patient.hp += amt
				repair_pool -= amt
				battle.stats_repaired += amt
				special = 1.0
				facing = signf(dx) if absf(dx) > 2.0 else facing
				if battle.rng.randf() < dt * 6.0:
					battle.fx.sparks(patient.aim_point(), 3)
		return
	_ground(dt)


func _necromancer(dt: float) -> void:
	var rd: Dictionary = def.get("raise_dead", {})
	raised = raised.filter(func(z): return is_instance_valid(z) and z.alive)
	mode_t += dt
	if mode == "casting":
		special = clampf(mode_t / float(rd.get("windup", 1.0)), 0.0, 1.0)
		if mode_t >= float(rd.get("windup", 1.0)):
			var n = 0
			var corpses: Array = battle.corpses_near(position, float(rd.get("range", 200)))
			for c in corpses:
				if n >= int(rd.get("count", 2)) or raised.size() >= int(rd.get("cap", 6)) or battle.alive_count(side) >= Battle.RAISE_CAP:
					break
				var z = battle.spawn_unit(rd.get("enemy", "rotter"), side, Vector2(c.pos.x, 0), true)
				if z != null:
					z.raised_by = self
					raised.append(z)
					battle.consume_corpse(c)
					battle.fx.raise(c.pos)
					n += 1
			mode = "advance"
			mode_t = 0.0
			special = 0.0
		return
	if mode_t >= float(rd.get("interval", 7.0)) and raised.size() < int(rd.get("cap", 6)):
		if battle.alive_count(side) >= Battle.RAISE_CAP:
			mode_t = 0.0   # the field is full: wait a full interval before trying again
		elif not battle.corpses_near(position, float(rd.get("range", 200))).is_empty():
			mode = "casting"
			mode_t = 0.0
			Audio.play("necro_magic", position.x, -4.0)
			battle.fx.telegraph(position, 30.0, float(rd.get("windup", 1.0)), Color(0.43, 1.0, 0.55))
			return
	_ground(dt)


# =============================================================== air helpers
func _fly_to(p: Vector2, dt: float, spd: float = -1.0) -> void:
	var s = move_speed() if spd < 0.0 else spd
	var gust: float = battle.gust_x if side == 0 else battle.gust_x * 0.5
	if thermal != 0.0:
		# M006 thermals: an updraft lifts the flyer a band and speeds it up, a downdraft sinks and slows it
		s *= 1.0 + 0.2 * thermal
		p.y -= 70.0 * thermal
	var to = p - position
	var want = to.limit_length(s) if to.length() > 4.0 else Vector2.ZERO
	var v = velocity.lerp(want, clampf(dt * 3.0, 0.0, 1.0))
	position += (v + Vector2(gust, 0.0)) * dt
	position.x = clampf(position.x, 40.0, Combat.WORLD_W - 40.0)
	position.y = clampf(position.y, 110.0, Combat.GROUND_Y - 8.0)


func _patrol_point() -> Vector2:
	var front = battle.front_x(side, null)
	var fx: float = home_x + dir * 380.0 if front == null else float(front) + dir * 160.0
	fx = clampf(fx, Combat.DWARF_BASE_X + 120.0, Combat.UNDEAD_BASE_X - 260.0)
	return Vector2(fx + sin(t * 0.7) * 90.0, alt_target + sin(t * 1.3) * 18.0)


func _return_and_repair(dt: float, rate: float) -> bool:
	# returns true while still retreating / repairing
	var hangar = Vector2(home_x + dir * 90.0, alt_target - 40.0)
	_fly_to(hangar, dt)
	if position.distance_to(hangar) < 60.0:
		hp = minf(max_hp, hp + rate * dt)
		if hp >= max_hp * 0.92:
			mode = "advance"
			return false
	return true


func _interceptor(dt: float) -> void:
	if mode == "return":
		_return_and_repair(dt, max_hp * 0.12)
		return
	if hp < max_hp * 0.3 and behavior == "interceptor":
		mode = "return"
		return
	if behavior == "scout":
		var front = battle.front_x(side, null)
		var fx: float = home_x + dir * 500.0 if front == null else float(front) + dir * 230.0
		fx = clampf(fx, Combat.DWARF_BASE_X + 150.0, Combat.UNDEAD_BASE_X - 300.0)
		var threat = battle.find_nearest(self, 220.0, "air")
		var dodge = Vector2(0, -60) if threat != null else Vector2.ZERO
		_fly_to(Vector2(fx + sin(t * 0.9) * 60.0, alt_target + sin(t * 1.7) * 12.0) + dodge, dt)
		return
	var air = battle.find_nearest(self, 650.0, "air")
	if air != null:
		var off = Vector2(-dir * 110.0, -30.0 + sin(t * 2.3) * 40.0)
		if air.position.y < 200.0:
			off.y = 40.0
		_fly_to(air.position + off, dt)
		return
	var gnd = battle.find_nearest(self, 520.0, "ground")
	if gnd != null and not gnd.is_stronghold:
		# dip into a strafing run: close enough for the forward MG, still above rifle-free low air
		var p: Vector2 = gnd.aim_point() + Vector2(-dir * (95.0 + sin(t * 1.5) * 30.0), -150.0)
		p.y = clampf(p.y, alt_target - 20.0, Combat.LOW_AIR_Y - 30.0)
		_fly_to(p, dt)
		return
	_fly_to(_patrol_point(), dt)


func _bomber(dt: float) -> void:
	match mode:
		"advance", "seek":
			var tgt = battle.best_bomb_target(self)
			if tgt == null:
				_fly_to(_patrol_point(), dt)
				return
			var over: Vector2 = Vector2(tgt.position.x + dir * 20.0, alt_target)
			_fly_to(over, dt)
			if absf(position.x - tgt.position.x) < 70.0:
				mode = "run"
				mode_t = 0.0
		"run":
			mode_t += dt
			# fly straight across the target dropping bombs
			_fly_to(Vector2(position.x + dir * 200.0, alt_target), dt)
			if ammo <= 0 or mode_t > 2.5:
				mode = "rearm" if ammo <= 0 else "advance"
		"rearm":
			var hangar = Vector2(home_x + dir * 80.0, alt_target - 30.0)
			_fly_to(hangar, dt)
			if position.distance_to(hangar) < 50.0:
				mode_t += dt
				hp = minf(max_hp, hp + max_hp * 0.05 * dt)
				if mode_t > float(def.get("rearm", 4.0)):
					ammo = int(def.get("ammo", 4))
					mode = "advance"
					mode_t = 0.0
			else:
				mode_t = 0.0
	if hp < max_hp * 0.25 and mode != "rearm":
		mode = "rearm"
		mode_t = 0.0


func bomb_weapon_allowed() -> bool:
	return behavior != "bomber" or (mode == "run" and ammo > 0)


func _gunship(dt: float) -> void:
	if mode == "return":
		_return_and_repair(dt, max_hp * 0.06)
		return
	if hp < max_hp * 0.25:
		mode = "return"
		return
	# ground-target search is throttled (it scans a 700 px window)
	_seek_t -= dt
	if _seek_t <= 0.0 or (_seek != null and (not is_instance_valid(_seek) or not _seek.alive)):
		_seek_t = 0.3
		_seek = battle.find_nearest(self, 700.0, "ground")
	var gnd = _seek
	if gnd != null:
		var standoff = float(def.get("standoff", 220))
		var p: Vector2 = Vector2(gnd.position.x - dir * standoff * 0.45, alt_target + sin(t) * 10.0)
		_fly_to(p, dt)
		return
	_fly_to(_patrol_point(), dt)


func _airship(dt: float) -> void:
	# slow, steady advance; halts while broadsides have ground targets
	var engaged = false
	for w in weapons:
		if w.target != null and w.targets != "air":
			engaged = true
	var hold_x: float = Combat.base_x(Combat.enemy_of(side)) - dir * float(def.get("hold_range", 380))
	var tx = position.x if engaged else hold_x
	if dir > 0.0:
		tx = minf(tx, hold_x)
	_fly_to(Vector2(tx, alt_target + sin(t * 0.5) * 4.0), dt, move_speed())


# =============================================================== undead air
func _bat(dt: float) -> void:
	var tgt = weapons[0].target if weapons.size() > 0 else null
	if tgt == null or not is_instance_valid(tgt) or not tgt.alive:
		tgt = battle.bat_prey(self)
	if tgt == null:
		_fly_to(Vector2(Combat.DWARF_BASE_X + 60.0, alt_target), dt)
		return
	mode_t -= dt
	var aimp: Vector2 = tgt.aim_point()
	if mode == "pullup":
		_fly_to(aimp + Vector2(dir * -40.0, -110.0), dt)
		if mode_t <= 0.0:
			mode = "advance"
		return
	_fly_to(aimp + Vector2(sin(t * 6.0 + special) * 6.0, 0.0), dt)
	if atk > 0.95:
		mode = "pullup"
		mode_t = 0.6


func _shrieker(dt: float) -> void:
	var tgt = battle.find_nearest(self, 560.0, "air")
	if tgt == null:
		tgt = battle.find_nearest(self, 420.0, "ground")
	if tgt == null:
		_fly_to(Vector2(maxf(Combat.DWARF_BASE_X + 200.0, position.x + dir * 120.0), alt_target), dt)
		return
	var so = float(def.get("standoff", 170))
	if tgt.domain == "ground":
		# close in so the ground target sits well inside this flyer's own weapon reach
		var reach = 0.0
		for w in weapons:
			if w.targets != "air":
				reach = maxf(reach, w.range_)
		if reach > 0.0:
			so = minf(so, reach * 0.55)
	var p: Vector2 = tgt.aim_point() + Vector2(-dir * so, -70.0 + sin(t * 1.4) * 30.0)
	p.y = minf(p.y, 420.0)
	_fly_to(p, dt)


# =============================================================== damage
func take_damage(amount: float, _from) -> float:
	if not alive:
		return 0.0
	if is_stronghold and battle.citadel_sealed and side == 1:
		battle.fx.seal_hit(aim_point())
		return 0.0
	if shielded:
		battle.fx.seal_hit(aim_point())
		return 0.0
	if exposed:
		amount *= float(def.get("boss", {}).get("exposed_mult", 1.5))
	if weak_core_t > 0.0:
		amount *= 1.25
	if burrowed and spotted:
		amount *= 0.5
	var dr = buff_add("dr")
	if dr > 0.0:
		amount *= maxf(0.25, 1.0 - dr)
	if aura_dr_t > battle.time:
		amount *= 1.0 - aura_dr
	hp -= amount
	if _from != null and is_instance_valid(_from):
		last_hit_by = _from.id
	if hurt < 0.5:
		# M006 motion layer: a hit jolts the body (bigger hits, lighter bodies jolt more)
		var j = clampf(amount / maxf(max_hp, 1.0) * 26.0, 0.25, 2.2) / _mo_mass()
		mo_vy += j * 6.0
		mo_vk -= j * 4.0
		mo_vroll += j * 0.6 * (1.0 if serial % 2 == 0 else -1.0)
	hurt = 1.0
	hit_flash = 1.0
	last_damaged_t = battle.time
	if hp <= 0.0:
		hp = 0.0
		battle.on_unit_died(self)
	return amount


func die() -> void:
	alive = false
	dying_t = 0.0
	state = "dead"
	ability_wind = -1.0       # special attacks stop if their owner dies
	charge_left = 0.0
	buffs.clear()
	for w in weapons:
		w.target = null
		w.windup_t = -1.0
		w.burst_left = 0


# =============================================================== M003 roster mechanics
## Auras, Steam generation, deployables, mines and boss upkeep (support waves, enrage).
func _extras(dt: float) -> void:
	if def.has("steam_gen") and side == 0:
		battle.steam = minf(Battle.STEAM_MAX, battle.steam + float(def.steam_gen) * dt)
	_xt -= dt
	if _xt <= 0.0 and def.has("aura"):
		_xt = 1.0
		var au: Dictionary = def.aura
		var classes: Array = au.get("classes", [])
		for e in battle.query(position, float(au.radius), side, "any"):
			if e == self or not e.alive or e.is_stronghold:
				continue
			if not classes.is_empty() and not e.cls in classes:
				continue
			if not (au.get("mods", {}) as Dictionary).is_empty():
				e.add_buff(au.mods, float(au.get("dur", 1.5)))
			if au.get("cleanse", false):
				e.slow_t = 0.0
				e.stun_t = 0.0
	if def.has("deploys"):
		_deploy_t -= dt
		if _deploy_t <= 0.0:
			var dp: Dictionary = def.deploys
			_deploy_t = float(dp.interval)
			_deployed = _deployed.filter(func(z): return is_instance_valid(z) and z.alive)
			if _deployed.size() < int(dp.cap) and battle.find_nearest(self, 900.0, "any") != null:
				var x = clampf(position.x + dir * float(dp.get("ahead", 30)), Combat.DWARF_BASE_X + 80.0, Combat.UNDEAD_BASE_X - 80.0)
				var y = position.y if dp.get("air", false) else 0.0
				var z = battle.spawn_unit(String(dp.unit), side, Vector2(x, y), true)
				if z != null:
					z.summoner = self
					_deployed.append(z)
					battle.fx.dust(z.position, 0.8)
	if def.has("mines"):
		_mine_t -= dt
		if _mine_t <= 0.0:
			var mn: Dictionary = def.mines
			_mine_t = float(mn.interval)
			if battle.enemy_ground_near(side, position.x, 520.0):
				var mx = position.x + dir * float(mn.get("ahead", 120))
				battle.add_zone(Vector2(mx, Combat.GROUND_Y - 10.0), float(mn.radius), float(mn.dps), float(mn.dur), side, self, "blast", String(mn.get("look", "mine")), 0.0)
	if is_boss and alive:
		var bd: Dictionary = def.get("boss", {})
		BossMineMaw._support(self, dt, bd)
		BossPhases.step(self, battle, dt)
		if not _enraged and hp < max_hp * float(bd.get("enrage_below", 0.35)):
			_enraged = true
			add_buff({"fire": float(bd.get("enrage_mult", 1.35)), "speed": 1.2}, 9999.0)
			battle.fx.raise(aim_point())
			battle.alert.emit("%s is enraged!" % String(def.get("name", "The boss")))
			Audio.play("giant_roar", position.x, 2.0)


## M006 supply barge: flies its route at a steady pace and is delivered at the far end. Never fights.
func _escort(dt: float) -> void:
	if delivered:
		_fly_to(Vector2(position.x + 60.0, alt_target - 140.0), dt, speed * 1.6)
		modulate.a = maxf(0.0, modulate.a - dt * 0.5)
		return
	var x1 = float(escort_def.get("x1", 2200))
	_fly_to(Vector2(x1 + 40.0, alt_target + sin(t * 0.6) * 5.0), dt, move_speed())
	if position.x >= x1:
		delivered = true
		battle.on_escort_delivered(self)


## Flying repair rig (Sky Mender): flies to the most damaged eligible ally (air or ground) and mends it.
func _air_repair(dt: float) -> void:
	var r: Dictionary = def.get("repair", {})
	special = maxf(0.0, special - dt * 2.0)
	var best = null
	var bf = 0.97
	if repair_pool > 0.0:
		for c in battle.by_side[side]:
			if c == self or not c.alive or not c.cls in r.get("classes", []):
				continue
			var f: float = c.hp / c.max_hp
			if f < bf:
				bf = f
				best = c
	if best == null:
		_fly_to(_patrol_point() - Vector2(dir * 160.0, 0), dt)
		return
	var goal = best.position + Vector2(-dir * 30.0, -60.0 if best.domain == "ground" else -30.0)
	goal.y = clampf(goal.y, 160.0, Combat.GROUND_Y - 120.0)
	_fly_to(goal, dt)
	if position.distance_to(best.position) <= float(r.get("range", 150)):
		var amt = minf(minf(float(r.get("rate", 20)) * dt, repair_pool), best.max_hp - best.hp)
		if best.repair_window_t != battle.time:
			best.repair_window_t = battle.time
			best.repair_this_step = 0.0
		amt = minf(amt, maxf(0.0, battle.REPAIR_CAP_PER_SEC * dt - best.repair_this_step))
		best.repair_this_step += amt
		best.hp += amt
		repair_pool -= amt
		battle.stats_repaired += amt
		special = 1.0


# =============================================================== drawing
static var draw_usec := 0
static var draw_calls := 0


func _draw() -> void:
	var _t0 = Time.get_ticks_usec()
	_draw_body()
	draw_usec += Time.get_ticks_usec() - _t0
	draw_calls += 1


func _draw_body() -> void:
	if burrowed and art != "mine_maw" and art != "zombie_miner":
		return
	if not visible_on_screen():
		_drawn_live = true   # re-check every step until it is on screen again
		return
	var cached = false
	if PoseCache.enabled:
		if _pose.is_empty():
			_pose = make_pose()
		var e: Dictionary = PoseCache.request(art, _pose, PoseCache.screen_scale_base(self, art_scale), _pose_hash)
		if not e.is_empty():
			draw_texture_rect_region(e.tex, e.dst, e.src)
			cached = true
		else:
			PoseCache.stats.live += 1
			if PoseCache.debug_track:
				PoseCache.live_by_art[art] = int(PoseCache.live_by_art.get(art, 0)) + 1
	_drawn_live = not cached
	if not cached:
		Painter.draw_unit(self, art, self)
	var pmul = material != null
	if shielded:
		# M006 Hollow Admiral: a ghostly ward bubble while its escorts hold (one arc + one ring, cheap)
		var sh = Color(0.55, 1.0, 0.75, 0.35 + 0.15 * sin(t * 4.0))
		var rr = radius * 1.5 / maxf(art_scale, 0.1)
		draw_arc(Vector2(0, 0), rr, 0, TAU, 28, PoseCache.pm(sh) if pmul else sh, 3.0)
		var sh2 = Color(0.55, 1.0, 0.75, 0.12)
		draw_circle(Vector2(0, 0), rr * 0.98, PoseCache.pm(sh2) if pmul else sh2)
	if weak_core_t > 0.0:
		# M007 Fallen Titan: the exposed boiler core glows through the torn plates
		var cc = Color(1.0, 0.55, 0.2, 0.45 + 0.25 * sin(t * 9.0))
		var cpos = Vector2(4, -Painter.art_height(art) * 0.55)
		draw_circle(cpos, 15.0, PoseCache.pm(cc) if pmul else cc)
		var cc2 = Color(1.0, 0.9, 0.55, 0.8)
		draw_circle(cpos, 6.0, PoseCache.pm(cc2) if pmul else cc2)
	if spotted and burrowed:
		var sc = Color(1, 0.9, 0.3, 0.8)
		draw_arc(Vector2(0, -10), radius + 10.0, 0, TAU, 20, PoseCache.pm(sc) if pmul else sc, 2.0)
	if battle.debug_targets and alive:
		for w in weapons:
			if w.target != null and is_instance_valid(w.target):
				var to: Vector2 = (w.target.aim_point() - position) / art_scale
				to.x *= facing
				var col = Color(1, 0.5, 0.2, 0.5) if w.targets != "air" else Color(0.3, 0.8, 1, 0.5)
				draw_line(Vector2(w.d.get("mount", [0, 0])[0], w.d.get("mount", [0, 0])[1]) / art_scale, to, PoseCache.pm(col) if pmul else col, 1.0)


# ---------------------------------------------------------------- pose cache support
var _pose := {}
var _pose_hash := 0
var _bar_q := -1
var _drawn_live := true


## Quantized animation state: the key of a baked atlas pose. Only the fields this art actually
## reads are included (Painter records them), so poses that look identical share one atlas cell.
const POSE_CODES := {"t": 1, "walk": 2, "state": 3, "atk": 4, "atk2": 5, "atk3": 6, "windup": 7, "reload": 8,
	"aim0": 9, "aim1": 10, "aim2": 11, "hurt": 12, "hp_frac": 13, "special": 14, "ammo": 15, "spin": 16,
	"engage": 17, "ability_anim": 18, "recoil": 19, "heat_lock_t": 20, "stun_t": 21, "brace_t": 22, "gag": 23}
static var _plan := {}     # art -> [[key, code], ...] rebuilt when the art's key set grows
## 1 = full M004 animation detail (fine attack/gag steps, long idle fidget loop, hurt faces);
## 0 = Performance preset: coarser steps so a crowded battle keeps its poses inside the atlas.
static var anim_detail := 1


static func _pose_plan(a: String) -> Array:
	var uk: Dictionary = Painter.used_keys.get(a, {})
	var pl = _plan.get(a)
	if pl != null and pl.size() == uk.size():
		return pl
	pl = []
	for k in uk:
		pl.append([k, int(POSE_CODES.get(k, 0))])
	_plan[a] = pl
	return pl


func make_pose() -> Dictionary:
	var moving = state == "move"
	# small ground troops get finer animation steps (cheap cells; this is where the goofy gags live)
	var fine = anim_detail > 0 and not is_mech and not is_structure and domain == "ground" and radius < 20.0
	var small = not is_mech and not is_structure and domain == "ground" and radius < 20.0
	var p = {}
	for kc in _pose_plan(art):
		match kc[1]:
			1:
				if domain == "air" or is_structure:
					p.t = snappedf(fposmod(t, 0.96), 0.16)
				elif moving or atk > 0.05 or atk2 > 0.05 or atk3 > 0.05 or windup > 0.0 or reload > 0.05 or gag > 0.0:
					p.t = 0.0 if not is_mech else snappedf(fposmod(t, 0.9), 0.45)
				elif fine:
					p.t = snappedf(fposmod(t + float(get_instance_id() % 7) * 0.7, 4.8), 0.2)   # idle fidget loop, desynced per unit
				elif small:
					p.t = snappedf(fposmod(t + float(get_instance_id() % 7) * 0.7, 4.8), 0.6)   # same fidgets, 8 frames
				else:
					p.t = snappedf(fposmod(t, 1.2), 0.3)
			2:
				# M006: war frames get a 12-step walk cycle on Balanced/High (heel-toe gait), 8 on Performance
				p.walk = snappedf(fposmod(walk, TAU), TAU / (12.0 if is_mech and anim_detail > 0 else 8.0)) if moving else 0.0
			3:
				p.state = state
			4:
				p.atk = snappedf(atk, 0.125 if fine else 0.25)
			5:
				p.atk2 = snappedf(atk2, 0.25)
			6:
				p.atk3 = snappedf(atk3, 0.25)
			7:
				p.windup = snappedf(windup, 0.34)
			8:
				p.reload = snappedf(reload, 0.25)
			9:
				p.aim0 = snappedf(aim0, 0.25)
			10:
				p.aim1 = snappedf(aim1, 0.35)
			11:
				p.aim2 = snappedf(aim2, 0.35)
			12:
				p.hurt = 1.0 if fine and hurt > 0.55 else 0.0
			13:
				var hq = 1.0
				if not (cls == "vehicle" or cls == "aircraft" or cls == "airship"):
					for th in HP_BINS:
						if hp_frac <= th[0]:
							hq = th[1]
				else:
					# M006b: vehicles, aircraft and airships only show two damage states (smoke < 50 %, fire < 25 %)
					hq = 1.0 if hp_frac > 0.5 else (0.45 if hp_frac > 0.25 else 0.2)
				p.hp_frac = hq
			14:
				p.special = snappedf(special, PI / 2.0) if art == "carrion_bat" else snappedf(special, 0.25)
			15:
				p.ammo = ammo if art == "bombard_gyro" else clampi(ammo, 0, 2)   # M006b: kit bombers show full / last bomb / empty
			16:
				p.spin = snappedf(fposmod(spin, TAU), TAU / 4.0)
			17:
				p.engage = 1.0 if engage > 0.5 else 0.0
			18:
				p.ability_anim = snappedf(ability_anim, 0.34)
			19:
				p.recoil = snappedf(recoil, 0.5)
			20:
				p.heat_lock_t = 1.0 if heat_lock_t > 0.0 else 0.0
			21:
				p.stun_t = 1.0 if stun_t > 0.0 else 0.0
			22:
				p.brace_t = 1.0 if brace_t > 0.0 else 0.0
			23:
				p.gag = snappedf(gag, 0.125 if fine else (0.25 if small else (0.2 if anim_detail > 0 else 0.34)))
			_:
				var v = get(kc[0])
				if v != null:
					p[kc[0]] = v
	return p


## hp_frac representative values between every threshold the art uses
const HP_BINS := [[0.66, 0.63], [0.6, 0.58], [0.55, 0.52], [0.5, 0.45], [0.4, 0.35], [0.3, 0.28], [0.25, 0.22], [0.2, 0.1]]


## Redraw only when something visible changed (pose, bars, flash) or the last draw was live.
func _request_redraw() -> void:
	if battle != null and not visible_on_screen():
		_drawn_live = true     # off screen: nothing to draw; refresh as soon as it scrolls in
		return
	if not PoseCache.enabled:
		if material != null and material == PoseCache.premult:
			material = null
		var fl0 = 1.0 + 0.9 * hit_flash
		if self_modulate.r != fl0:
			self_modulate = Color(fl0, fl0, fl0, 1.0)
		queue_redraw()
		return
	if material == null:
		material = PoseCache.premult
	_pose = make_pose()
	var hsh = _pose.hash()
	if hsh != _pose_hash or _drawn_live or battle.debug_targets or (spotted and burrowed) or shielded:
		_pose_hash = hsh
		queue_redraw()
	# hit flash + premultiplied fade as a tint (no extra geometry, keeps the unit one quad)
	var fl = (1.0 + 0.9 * hit_flash) * modulate.a
	if self_modulate.r != fl:
		self_modulate = Color(fl, fl, fl, 1.0)


func visible_on_screen() -> bool:
	if battle == null or battle.view_rect.size == Vector2.ZERO:
		return true
	var margin = (160.0 if not is_stronghold else 300.0) + radius * 2.0
	return position.x > battle.view_rect.position.x - margin and position.x < battle.view_rect.end.x + margin


# =============================================================== M002 war frames
func _tick_mech_timers(dt: float) -> void:
	ability_cd = maxf(0.0, ability_cd - dt)
	ability_anim = maxf(0.0, ability_anim - dt * 1.2)
	recoil = maxf(0.0, recoil - dt * 3.0)
	slow_t = maxf(0.0, slow_t - dt)
	stun_t = maxf(0.0, stun_t - dt)
	brace_t = maxf(0.0, brace_t - dt)
	turn_t = maxf(0.0, turn_t - dt)
	if heat_lock_t > 0.0:
		heat_lock_t = maxf(0.0, heat_lock_t - dt)
	for k in wlock.keys():
		wlock[k] = maxf(0.0, float(wlock[k]) - dt)
	if not buffs.is_empty():
		var keep: Array = []
		for bf in buffs:
			bf.t -= dt
			if bf.t > 0.0:
				keep.append(bf)
		buffs = keep
	if heat_after > 0.0:
		heat_after_at -= dt
		if heat_after_at <= 0.0:
			heat_lock_t = heat_after      # barrels overheat after Full Barrage
			heat_after = 0.0
			battle.fx.steam_burst(aim_point(), 1.0)
	var has_t = false
	for w in weapons:
		if w.target != null:
			has_t = true
	engage = move_toward(engage, 1.0 if has_t else 0.0, dt * 3.0)
	var spinning = false
	for w in weapons:
		if w.target != null and String(w.d.get("family", "")) in ["drill", "rotary", "aa_mg", "aa_quad"]:
			spinning = true
	spin += dt * (22.0 if spinning else 3.0)


func _mech(dt: float) -> void:
	MechAbility.step(self, battle, dt)
	if aloft:
		return   # M008: the Rift Lich hangs in the rift and fights from there
	if charge_left > 0.0:
		MechAbility.charge_step(self, battle, dt)
		return
	if stun_t > 0.0 or brace_t > 0.0 or turn_t > 0.0:
		return
	var before = position.x
	_ground(dt)
	var moved = position.x - before
	if absf(moved) > 0.001:
		# gait: power stroke while a foot is planted, pause as the other leg swings through
		var heavy = {"light": 0.35, "medium": 0.5, "heavy": 0.6, "colossal": 0.7}.get(mech_class, 0.4)
		var g: float = (1.0 - heavy) + heavy * 2.0 * absf(sin(walk))
		position.x = before + moved * g
		_footsteps()


func _footsteps() -> void:
	var ph: float = floor(walk / PI)
	if ph != _step_phase:
		_step_phase = ph
		var foot = position + Vector2(facing * radius * 0.35 * (1.0 if int(ph) % 2 == 0 else -1.0), 0)
		battle.fx.dust(foot, 0.4 + art_scale * 0.35)
		# M006 motion layer: the frame drops onto the planted foot and its weight rolls across
		var heavy = {"light": 0.6, "medium": 0.85, "heavy": 1.1, "colossal": 1.35}.get(mech_class, 0.8)
		mo_vy += 9.0 * heavy
		mo_vk += (2.6 if int(ph) % 2 == 0 else -2.6) * heavy
		if is_giant:
			if mech_class == "colossal" or mech_class == "heavy":
				battle.shake(2.0 if mech_class == "colossal" else 0.7)
			Audio.play("giant_step", position.x, -4.0 if mech_class == "colossal" else -9.0)
			return
		match mech_class:
			"colossal":
				battle.shake(2.5)
				Audio.play("colossal_step", position.x, -4.0)
			"heavy":
				battle.shake(0.8)
				Audio.play("mech_step", position.x, -6.0)
			_:
				Audio.play("mech_step", position.x, -12.0)


func _mech_death(dt: float) -> void:
	# staged destruction by frame class (M002 §10.4); unit is already untargetable
	var k: float = dying_t / death_time
	var stages = {"light": [0.05], "medium": [0.05, 0.45], "heavy": [0.05, 0.35, 0.65], "colossal": [0.05, 0.25, 0.45, 0.6, 0.8]}.get(mech_class, [0.05])
	if _death_fx_done < stages.size() and k >= float(stages[_death_fx_done]):
		var off = Vector2(battle.rng.randf_range(-0.4, 0.4) * radius, -Painter.art_height(art) * art_scale * battle.rng.randf_range(0.3, 0.8))
		if is_giant:
			# necrotic unravelling: gore, bone and a burst of the binding spirit
			battle.fx.blood(position + off, true)
			battle.fx.bones(position + off)
			battle.fx.raise(position + off)
			battle.shake(1.5 + art_scale * 1.5)
			Audio.play("giant_roar", position.x, -4.0, 0.15)
		else:
			battle.fx.explosion(position + off, 0.8 + art_scale * 0.35, "fire")
			battle.fx.steam_burst(position + off, 1.0 + art_scale * 0.4)
			battle.shake(2.0 + art_scale * 2.0)
			Audio.play("explosion", position.x, -2.0)
		_death_fx_done += 1
	var fall_start = {"light": 0.0, "medium": 0.15, "heavy": 0.35, "colossal": 0.5}.get(mech_class, 0.0)
	if k > fall_start:
		var fk = clampf((k - fall_start) / (0.75 - fall_start), 0.0, 1.0)
		rotation = -facing * (0.55 if mech_class == "light" else 1.25) * fk * fk
		position.y = Combat.GROUND_Y + lane + fk * 6.0
		if fk >= 1.0 and _death_fx_done <= stages.size():
			battle.fx.dust(position + Vector2(-facing * radius, 0), 1.5 + art_scale)
			battle.shake(3.0 + art_scale * 2.0)
			_death_fx_done = stages.size() + 1
	elif mech_class == "colossal" or mech_class == "heavy":
		position.x += sin(dying_t * 40.0) * 0.6
	modulate.a = clampf(1.0 - (k - 0.8) / 0.2, 0.0, 1.0)
	modulate.r = lerpf(1.0, 0.55, clampf(k * 2.0, 0.0, 1.0))
	modulate.g = modulate.r
	modulate.b = modulate.r
