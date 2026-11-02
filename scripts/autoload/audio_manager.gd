extends Node
## Audio manager. All sounds are synthesized at startup (original, no external assets):
## separate categories for every weapon family, machines, aircraft, undead and ambience,
## plus a procedural industrial-percussion music loop. Pooled players + per-category rate limits.

const MIX_RATE := 22050
const POOL := 12
const CATEGORIES := [
	"rifle", "blunderbuss", "rapid", "cannon", "mortar", "rocket", "flak", "explosion", "tank_move",
	"walker_step", "steam", "propeller", "airship_engine", "dwarf_voice", "undead_snarl",
	"skeletal_impact", "necro_magic", "boss", "melee", "ui_click", "deploy", "rockfall"]

var streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _last_play: Dictionary = {}
var _music: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _rng := RandomNumberGenerator.new()
var listener_x: float = 640.0
var enabled := true
const VOICE_LIMIT := {"boomstick": 2, "cannon_heavy": 2, "colossal_step": 1, "mech_step": 2, "mg_mech": 2, "rapid": 3, "drill": 2, "flame": 2, "electric": 2, "explosion": 3, "hammer_impact": 2, "giant_step": 2, "giant_roar": 1}
var _music_task: int = -1
var _pending_music := ""
var _pending_amb := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 4242
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	for i in POOL:
		var p = AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	_ambience = AudioStreamPlayer.new()
	_ambience.bus = "Music"
	_ambience.volume_db = -14
	add_child(_ambience)
	var _t0 = Time.get_ticks_msec()
	if not _load_cache():
		_build_all()
		_save_cache(false)
	if "--audio_timing" in OS.get_cmdline_user_args():
		print("AUDIO_SFX_MS ", Time.get_ticks_msec() - _t0)
	apply_volumes()


func apply_volumes() -> void:
	if not is_instance_valid(GameState) or GameState.profile.is_empty():
		return
	var s: Dictionary = GameState.profile.settings
	AudioServer.set_bus_volume_db(0, linear_to_db(max(0.0001, float(s.master))))
	var mi = AudioServer.get_bus_index("Music")
	var si = AudioServer.get_bus_index("SFX")
	if mi >= 0:
		AudioServer.set_bus_volume_db(mi, linear_to_db(max(0.0001, float(s.music))))
	if si >= 0:
		AudioServer.set_bus_volume_db(si, linear_to_db(max(0.0001, float(s.sfx))))


## Plays a category sound. world_x attenuates by distance from the camera centre.
func play(cat: String, world_x: float = -1.0, vol_db: float = 0.0, pitch_var: float = 0.08) -> void:
	if not enabled or not streams.has(cat):
		return
	# M007: button taps are silent unless the player turns "Button sounds" on (Settings); the old metallic
	# "cling" on every tap is gone either way — when on, it is a soft felted tick
	if cat == "ui_click" and not ui_sounds_on():
		return
	var now = Time.get_ticks_msec()
	var min_gap = 45 if cat in ["rapid", "rifle", "melee", "skeletal_impact"] else 70
	if now - int(_last_play.get(cat, -1000)) < min_gap:
		return
	_last_play[cat] = now
	var att = 0.0
	if world_x >= 0.0:
		var d: float = abs(world_x - listener_x)
		if d > 1100.0:
			return
		att = -d / 90.0
	# voice limits: never stack more than a few copies of one category (no wall of noise)
	var same = 0
	for q in _players:
		if q.playing and q.stream == streams[cat]:
			same += 1
	if same >= int(VOICE_LIMIT.get(cat, 3)):
		return
	for p in _players:
		if not p.playing:
			p.stream = streams[cat]
			p.volume_db = vol_db + att
			p.pitch_scale = 1.0 + _rng.randf_range(-pitch_var, pitch_var)
			p.play()
			return


func ui_sounds_on() -> bool:
	if not is_instance_valid(GameState) or GameState.profile.is_empty():
		return false
	return bool(GameState.profile.settings.get("ui_sounds", false))


func play_music(kind: String = "battle") -> void:
	var key = "music_" + kind
	if not streams.has(key):
		_pending_music = kind
		return
	if _music.stream == streams[key] and _music.playing:
		return
	_music.stream = streams[key]
	_music.volume_db = -6
	_music.play()


func play_ambience(kind: String) -> void:
	var key = "amb_" + kind
	if not streams.has("amb_mountain"):
		_pending_amb = kind
		return
	if not streams.has(key):
		key = "amb_mountain"
	if _ambience.stream == streams.get(key) and _ambience.playing:
		return
	_ambience.stream = streams[key]
	_ambience.play()


func stop_ambience() -> void:
	_pending_amb = ""
	_ambience.stop()


func _exit_tree() -> void:
	if _music_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_music_task)


# ------------------------------------------------------------------ disk cache
## Synthesizing every sound in GDScript takes seconds on a low-end phone, so the generated
## streams are saved to user:// after the first launch and loaded directly afterwards.
## Bump CACHE_VER whenever a sound recipe changes.
const CACHE_VER := "m008-1"
const CACHE_DIR := "user://sfx_cache"
# M007: every synthesized loop must be listed here, or it is neither saved to nor restored from the cache
# (the M006 ambiences were missing, so after the first launch Act III fell back to the mountain wind).
const AMB_ENVS := ["mountain", "mine", "ridge", "foundry", "forest", "marsh", "road", "fungal", "plains", "highridge", "cloudsea", "fort",
	"city", "dead_forge", "factory", "graveyard", "waste", "rift", "citadel", "gate"]
const LOOP_KEYS := ["music_battle", "music_menu", "amb_mountain", "amb_mine", "amb_ridge", "amb_foundry", "amb_forest", "amb_marsh", "amb_road", "amb_fungal",
	"amb_plains", "amb_highridge", "amb_cloudsea", "amb_fort", "amb_city", "amb_dead_forge", "amb_factory", "amb_graveyard",
	"amb_waste", "amb_rift", "amb_citadel", "amb_gate", "music_lich", "music_ending"]


func _load_cache() -> bool:
	if "--no_audio_cache" in OS.get_cmdline_user_args():
		return false
	var f = FileAccess.open(CACHE_DIR + "/index.json", FileAccess.READ)
	if f == null:
		return false
	var idx = JSON.parse_string(f.get_as_text())
	if not (idx is Dictionary) or idx.get("ver", "") != CACHE_VER:
		return false
	var loaded = {}
	for k in idx.get("sfx", []):
		var r = ResourceLoader.load("%s/%s.res" % [CACHE_DIR, k], "AudioStreamWAV", ResourceLoader.CACHE_MODE_IGNORE)
		if r == null:
			return false
		loaded[k] = r
	streams.merge(loaded, true)
	var have_loops = true
	for k in LOOP_KEYS:
		if idx.get("loops", []).has(k):
			var r2 = ResourceLoader.load("%s/%s.res" % [CACHE_DIR, k], "AudioStreamWAV", ResourceLoader.CACHE_MODE_IGNORE)
			if r2 != null:
				streams[k] = r2
				continue
		have_loops = false
	if not have_loops:
		_music_task = WorkerThreadPool.add_task(_build_loops)
	return true


func _save_cache(loops: bool) -> void:
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)
	var idx = {"ver": CACHE_VER, "sfx": [], "loops": []}
	var old = FileAccess.open(CACHE_DIR + "/index.json", FileAccess.READ)
	if old != null:
		var o = JSON.parse_string(old.get_as_text())
		if o is Dictionary and o.get("ver", "") == CACHE_VER:
			idx = o
	for k in streams.keys():
		var is_loop = k in LOOP_KEYS
		if is_loop != loops:
			continue
		if ResourceSaver.save(streams[k], "%s/%s.res" % [CACHE_DIR, k]) == OK:
			var lst: Array = idx["loops" if loops else "sfx"]
			if not lst.has(k):
				lst.append(k)
	var f = FileAccess.open(CACHE_DIR + "/index.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(idx))


# ------------------------------------------------------------------ synthesis
func _build_all() -> void:
	streams["rifle"] = _shot(0.32, 900.0, 0.9, 0.03, 120.0)
	streams["blunderbuss"] = _shot(0.45, 500.0, 1.0, 0.06, 80.0)
	streams["rapid"] = _shot(0.09, 1500.0, 0.6, 0.01, 200.0)
	streams["cannon"] = _boom(0.9, 55.0, 1.0)
	streams["mortar"] = _boom(0.7, 80.0, 0.8, 0.15)
	streams["rocket"] = _whoosh(0.6)
	streams["flak"] = _shot(0.35, 650.0, 0.9, 0.02, 160.0, 0.6)
	streams["explosion"] = _boom(1.1, 40.0, 1.0)
	streams["tank_move"] = _rumble(0.6, 38.0)
	streams["walker_step"] = _clank(0.35, 140.0)
	streams["steam"] = _hiss(0.6)
	streams["propeller"] = _prop(0.5, 22.0)
	streams["airship_engine"] = _prop(0.8, 9.0)
	streams["dwarf_voice"] = _voice(0.28, 160.0, false)
	streams["undead_snarl"] = _voice(0.55, 85.0, true)
	streams["skeletal_impact"] = _clank(0.18, 900.0)
	streams["necro_magic"] = _shimmer(0.8)
	streams["boss"] = _voice(1.3, 48.0, true)
	streams["melee"] = _clank(0.12, 420.0)
	# M007 sound refinement: no more metallic "cling" on taps — a soft felted tick (only with Button sounds on),
	# a muffled boot-stamp-and-drum for a deploy, and a low ratchet thunk for the mine upgrade
	streams["ui_click"] = _tick(0.05, 520.0)
	streams["deploy"] = _layer([_boom(0.22, 96.0, 0.7), _brush(0.16)], [1.0, 0.45])
	streams["mine_upgrade"] = _layer([_boom(0.3, 70.0, 0.8), _ratchet(0.32, 9)], [1.0, 0.5])
	streams["rockfall"] = _rumble(0.9, 60.0, true)
	# --- M002 war-frame weapon families (each with its own character)
	streams["boomstick"] = _boomstick_sound()
	streams["axe_swing"] = _whoosh(0.35)
	streams["hammer_impact"] = _layer([_boom(0.8, 45.0, 1.0), _clank(0.5, 210.0)], [1.0, 0.6])
	streams["drill"] = _drill_sound()
	streams["mg_mech"] = _layer([_shot(0.12, 1300.0, 0.7, 0.008, 140.0), _clank(0.08, 900.0)], [1.0, 0.35])
	streams["cannon_heavy"] = _layer([_boom(1.3, 38.0, 1.0, 0.0), _clank(0.6, 160.0), _hiss(0.9)], [1.0, 0.5, 0.25])
	streams["mech_step"] = _layer([_clank(0.3, 95.0), _hiss(0.35)], [1.0, 0.35])
	streams["colossal_step"] = _layer([_boom(0.9, 28.0, 1.0), _clank(0.7, 62.0)], [1.0, 0.7])
	streams["electric"] = _electric_sound()
	streams["flame"] = _flame_sound()
	# M002b undead giants: wet, heavy footfalls and a deep roar
	streams["giant_step"] = _layer([_boom(0.75, 30.0, 1.0), _voice(0.35, 55.0, true)], [1.0, 0.3])
	streams["giant_roar"] = _layer([_voice(1.2, 52.0, true), _rumble(1.0, 34.0)], [1.0, 0.5])
	# M005 hazards, boss stings and the star stamp
	streams["miasma"] = _layer([_hiss(1.1), _gurgle(1.1, 7.0)], [0.6, 1.0])
	streams["squelch"] = _gurgle(0.35, 16.0)
	streams["boss_sting"] = _layer([_boom(1.6, 36.0, 1.0), _voice(1.4, 46.0, true), _shimmer(1.2)], [1.0, 0.7, 0.4])
	streams["star_stamp"] = _layer([_tick(0.12, 260.0), _boom(0.35, 90.0, 0.8)], [0.8, 0.8])
	# M006 sky war: hazard cues, sky monsters, the ghost fleet and the escort's horn
	streams["crackle"] = _electric_sound()
	streams["thunder"] = _layer([_shot(0.18, 2400.0, 1.0, 0.002, 600.0), _boom(1.6, 32.0, 1.0), _rumble(1.4, 24.0)], [0.8, 1.0, 0.6])
	streams["updraft"] = _layer([_whoosh(0.9), _hiss(0.9)], [1.0, 0.4])
	streams["wyvern_roar"] = _layer([_voice(0.9, 70.0, true), _hiss(0.6)], [1.0, 0.35])
	streams["wingbeat"] = _layer([_boom(0.35, 46.0, 0.8), _whoosh(0.3)], [1.0, 0.6])
	streams["serpent_hiss"] = _layer([_hiss(1.0), _voice(0.8, 110.0, true)], [1.0, 0.4])
	streams["ghost_bell"] = _layer([_clank(1.4, 300.0), _shimmer(1.2)], [1.0, 0.6])
	streams["timber_creak"] = _layer([_rumble(0.7, 70.0), _clank(0.4, 180.0)], [0.6, 0.5])
	streams["airship_horn"] = _layer([_voice(1.0, 98.0, false), _rumble(0.9, 49.0)], [1.0, 0.6])
	# M007 Act IV: foundry hazards, wreck reclamation and the corrupted machines' wrong, choir-haunted engines
	streams["vent_rumble"] = _rumble(0.9, 34.0)
	streams["vent_roar"] = _layer([_whoosh(0.8), _boom(0.7, 48.0, 0.8), _hiss(0.7)], [1.0, 0.7, 0.4])
	streams["slag_hiss"] = _layer([_hiss(1.2), _gurgle(1.2, 5.0)], [0.9, 0.7])
	streams["girder_groan"] = _layer([_groan(1.4, 62.0), _clank(0.4, 180.0)], [1.0, 0.3])
	streams["girder_crash"] = _layer([_boom(1.0, 40.0, 1.0), _clank(0.7, 150.0), _rumble(0.8, 55.0, true)], [1.0, 0.6, 0.5])
	streams["channel"] = _layer([_choir(1.4, 98.0), _hiss(1.2)], [1.0, 0.25])
	streams["reclaim"] = _layer([_choir(1.6, 73.0), _wheeze(1.6), _boom(0.9, 44.0, 0.8)], [0.9, 0.7, 0.6])
	streams["corrupt_engine"] = _layer([_rumble(1.0, 36.0), _wheeze(1.0), _choir(1.0, 110.0)], [0.8, 0.7, 0.35])
	streams["salvage"] = _layer([_ratchet(0.5, 14), _tick(0.12, 340.0)], [1.0, 0.5])
	streams["corpse_impact"] = _layer([_boom(0.8, 46.0, 1.0), _gurgle(0.6, 12.0)], [1.0, 0.7])
	streams["pipe_burst"] = _layer([_hiss(0.9), _rumble(0.4, 80.0), _tick(0.1, 200.0)], [1.0, 0.4, 0.5])
	# M008 Act V: rift tears, the eclipse, the Hollow King's crown, the Sovereign's gales, Last Stand wave horns
	streams["rift_crack"] = _layer([_electric_sound(), _shimmer(0.7)], [0.6, 0.8])
	streams["rift_open"] = _layer([_shimmer(1.2), _choir(1.2, 82.0), _boom(0.8, 40.0, 0.7)], [0.8, 0.7, 0.6])
	streams["rift_close"] = _layer([_shimmer(0.6), _boom(0.5, 70.0, 0.6)], [0.8, 0.7])
	streams["rift_spill"] = _layer([_choir(1.0, 65.0), _voice(0.9, 70.0, true), _boom(0.8, 36.0, 0.9)], [0.7, 0.6, 0.8])
	streams["eclipse"] = _layer([_choir(2.0, 55.0), _rumble(1.8, 26.0)], [0.9, 0.6])
	streams["eclipse_end"] = _layer([_shimmer(1.4), _tick(0.2, 300.0)], [0.8, 0.4])
	streams["crown"] = _layer([_clank(1.2, 330.0), _choir(1.2, 98.0)], [0.7, 0.8])
	streams["crown_break"] = _layer([_clank(0.8, 520.0), _boom(0.9, 50.0, 0.8), _shimmer(0.8)], [0.8, 0.8, 0.5])
	streams["gale"] = _layer([_whoosh(1.6), _hiss(1.6), _rumble(1.4, 30.0)], [1.0, 0.6, 0.5])
	streams["wave_horn"] = _layer([_voice(1.4, 73.0, false), _voice(1.4, 110.0, false), _rumble(1.2, 37.0)], [1.0, 0.6, 0.5])
	# Long loops are synthesized off the main thread so startup stays fast on low-end phones.
	_music_task = WorkerThreadPool.add_task(_build_loops)


func _build_loops() -> void:
	var out = {}
	out["music_battle"] = _music_loop(11025, 120.0, [0, 0, 3, -2], false)
	out["music_menu"] = _music_loop(11025, 84.0, [0, -4, -2, -5], true)
	# M008: the Rift Lich's own theme (dark, driving, a falling minor line) and the ending's triumphant march
	out["music_lich"] = _music_loop(11025, 132.0, [0, 1, -2, -1, 0, 1, 3, -1], false)
	out["music_ending"] = _march_loop(11025, 104.0)
	for env in AMB_ENVS:
		out["amb_" + env] = _ambient_loop(env)
	if "--audio_timing" in OS.get_cmdline_user_args():
		print("AUDIO_LOOPS_DONE_MS ", Time.get_ticks_msec())
	call_deferred("_loops_ready", out)


func _loops_ready(out: Dictionary) -> void:
	streams.merge(out)
	_save_cache(true)
	if _pending_music != "":
		play_music(_pending_music)
	if _pending_amb != "":
		play_ambience(_pending_amb)


## Safe-level mastering: soft-knee compression then peak normalisation to PEAK_CEIL, so no
## generated sound can clip (M002 §13: loudness from layering/compression, not amplitude).
const PEAK_CEIL := 0.89
var peaks: Dictionary = {}


func _master(data: PackedFloat32Array, drive: float = 1.0) -> PackedFloat32Array:
	var peak = 0.0
	for i in data.size():
		var x = data[i] * drive
		# soft knee: tanh-style compression of transients
		x = x / (1.0 + absf(x) * 0.6)
		data[i] = x
		peak = maxf(peak, absf(x))
	if peak > 0.0001:
		var g = PEAK_CEIL / peak if peak > PEAK_CEIL else 1.0
		for i in data.size():
			data[i] *= g
	return data


func _wav(data: PackedFloat32Array, rate: int = MIX_RATE, loop: bool = false) -> AudioStreamWAV:
	data = _master(data)
	var bytes = PackedByteArray()
	bytes.resize(data.size() * 2)
	for i in data.size():
		var v = int(clampf(data[i], -1.0, 1.0) * 32000.0)
		bytes.encode_s16(i * 2, v)
	var w = AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = data.size()
	return w


func _noise() -> float:
	return _rng.randf_range(-1.0, 1.0)


func _shot(dur: float, tone: float, amp: float, attack: float, body: float, ring: float = 0.0) -> AudioStreamWAV:
	var n = int(dur * MIX_RATE)
	var d = PackedFloat32Array()
	d.resize(n)
	var lp = 0.0
	for i in n:
		var t = float(i) / MIX_RATE
		var env = exp(-t * 18.0) if t > attack else t / max(attack, 0.001)
		lp += (_noise() - lp) * clampf(tone / MIX_RATE * 6.0, 0.02, 0.9)
		var thump = sin(TAU * body * t) * exp(-t * 25.0)
		var r = sin(TAU * 1800.0 * t) * exp(-t * 30.0) * ring
		d[i] = (lp * 1.6 + thump * 0.7 + r * 0.3) * env * amp
	return _wav(d)


func _boom(dur: float, freq: float, amp: float, whistle: float = 0.0) -> AudioStreamWAV:
	var n = int(dur * MIX_RATE)
	var d = PackedFloat32Array()
	d.resize(n)
	var lp = 0.0
	var ph = 0.0
	for i in n:
		var t = float(i) / MIX_RATE
		var f = freq * (1.0 + 2.0 * exp(-t * 12.0))
		ph += TAU * f / MIX_RATE
		lp += (_noise() - lp) * 0.08
		var env = exp(-t * 4.5)
		var w = sin(TAU * (900.0 - t * 1200.0) * t) * whistle * exp(-t * 8.0)
		d[i] = (sin(ph) * 0.9 + lp * 2.2 + w) * env * amp * 0.8
	return _wav(d)


func _whoosh(dur: float) -> AudioStreamWAV:
	var n = int(dur * MIX_RATE)
	var d = PackedFloat32Array()
	d.resize(n)
	var lp = 0.0
	for i in n:
		var t = float(i) / MIX_RATE
		lp += (_noise() - lp) * (0.05 + 0.3 * t / dur)
		d[i] = lp * sin(PI * t / dur) * 1.8
	return _wav(d)


func _rumble(dur: float, freq: float, rocks: bool = false) -> AudioStreamWAV:
	var n = int(dur * MIX_RATE)
	var d = PackedFloat32Array()
	d.resize(n)
	var lp = 0.0
	for i in n:
		var t = float(i) / MIX_RATE
		lp += (_noise() - lp) * 0.03
		var clack = 0.0
		if rocks and _rng.randf() < 0.002:
			clack = _noise()
		d[i] = (lp * 3.0 + sin(TAU * freq * t) * 0.3 + clack) * sin(PI * t / dur) * 0.7
	return _wav(d)


func _clank(dur: float, freq: float) -> AudioStreamWAV:
	var n = int(dur * MIX_RATE)
	var d = PackedFloat32Array()
	d.resize(n)
	for i in n:
		var t = float(i) / MIX_RATE
		var e = exp(-t * 22.0)
		d[i] = (sin(TAU * freq * t) * 0.5 + sin(TAU * freq * 2.76 * t) * 0.3 + sin(TAU * freq * 5.4 * t) * 0.15 + _noise() * 0.2 * exp(-t * 60.0)) * e
	return _wav(d)


func _hiss(dur: float) -> AudioStreamWAV:
	var n = int(dur * MIX_RATE)
	var d = PackedFloat32Array()
	d.resize(n)
	var prev = 0.0
	for i in n:
		var t = float(i) / MIX_RATE
		var x = _noise()
		var hp = x - prev
		prev = x
		d[i] = hp * 0.5 * min(1.0, t * 20.0) * exp(-t * 3.0)
	return _wav(d)


func _prop(dur: float, rate: float) -> AudioStreamWAV:
	var n = int(dur * MIX_RATE)
	var d = PackedFloat32Array()
	d.resize(n)
	var lp = 0.0
	for i in n:
		var t = float(i) / MIX_RATE
		lp += (_noise() - lp) * 0.1
		var chop = 0.5 + 0.5 * sin(TAU * rate * t)
		d[i] = lp * chop * 1.4 + sin(TAU * 70.0 * t) * 0.15
	return _wav(d, MIX_RATE, true)


func _voice(dur: float, f0: float, undead: bool) -> AudioStreamWAV:
	var n = int(dur * MIX_RATE)
	var d = PackedFloat32Array()
	d.resize(n)
	var ph = 0.0
	var lp = 0.0
	for i in n:
		var t = float(i) / MIX_RATE
		var f = f0 * (1.0 + (0.15 * sin(TAU * 5.0 * t) if undead else 0.25 * (1.0 - t / dur)))
		ph += TAU * f / MIX_RATE
		var saw = fmod(ph / TAU, 1.0) * 2.0 - 1.0
		lp += (saw - lp) * (0.12 if undead else 0.25)
		var rasp = _noise() * (0.45 if undead else 0.08)
		d[i] = (lp + rasp) * sin(PI * t / dur) * 0.7
	return _wav(d)


func _shimmer(dur: float) -> AudioStreamWAV:
	var n = int(dur * MIX_RATE)
	var d = PackedFloat32Array()
	d.resize(n)
	for i in n:
		var t = float(i) / MIX_RATE
		var e = sin(PI * t / dur)
		d[i] = (sin(TAU * 440.0 * t + 3.0 * sin(TAU * 7.0 * t)) * 0.3 + sin(TAU * 659.0 * t) * 0.2 + _noise() * 0.1) * e * 0.6
	return _wav(d)


## Procedural loop: industrial percussion (kick, anvil, steam hats) over a low minor drone.
func _music_loop(rate: int, bpm: float, roots: Array, calm: bool) -> AudioStreamWAV:
	var beat = 60.0 / bpm
	var bars = roots.size()
	var dur = beat * 4.0 * bars
	var n = int(dur * rate)
	var d = PackedFloat32Array()
	d.resize(n)
	var base = 55.0
	var lp = 0.0
	for i in n:
		var t = float(i) / rate
		var bar = int(t / (beat * 4.0)) % bars
		var bt = fmod(t, beat)
		var beat_idx = int(t / beat) % 4
		var root: float = base * pow(2.0, float(roots[bar]) / 12.0)
		var drone = sin(TAU * root * t) * 0.22 + sin(TAU * root * 1.5 * t) * 0.10 + sin(TAU * root * 2.0 * t + sin(TAU * 0.25 * t)) * 0.07
		var kick = sin(TAU * (50.0 + 90.0 * exp(-bt * 30.0)) * bt) * exp(-bt * 9.0) * (0.55 if not calm or beat_idx == 0 else 0.0)
		var anvil = 0.0
		if (beat_idx == 1 or beat_idx == 3) and not calm:
			anvil = (sin(TAU * 1310.0 * bt) * 0.5 + sin(TAU * 2210.0 * bt) * 0.3) * exp(-bt * 14.0) * 0.35
		elif calm and beat_idx == 2:
			anvil = (sin(TAU * 980.0 * bt) * 0.5 + sin(TAU * 1540.0 * bt) * 0.3) * exp(-bt * 6.0) * 0.18
		var half = fmod(t, beat * 0.5)
		lp += (_noise() - lp) * 0.6
		var hat = lp * exp(-half * 60.0) * (0.06 if not calm else 0.0)
		d[i] = (drone + kick + anvil + hat) * 0.7
	return _wav(d, rate, true)


## M008 ending theme: a triumphant dwarven march - a major-key horn line over industrial percussion (kick on every
## beat, anvil on 2 and 4, a snare roll into each phrase).
func _march_loop(rate: int, bpm: float) -> AudioStreamWAV:
	var beat = 60.0 / bpm
	var melody = [0, 4, 7, 12, 11, 7, 9, 7, 5, 4, 2, 4, 7, 4, 0, -5]   # semitones over the root, one per beat
	var dur = beat * melody.size()
	var n = int(dur * rate)
	var d = PackedFloat32Array()
	d.resize(n)
	var base = 110.0
	var lp = 0.0
	for i in n:
		var t = float(i) / rate
		var bi = int(t / beat) % melody.size()
		var bt = fmod(t, beat)
		var f = base * pow(2.0, float(melody[bi]) / 12.0)
		var env = minf(1.0, bt * 30.0) * (0.75 + 0.25 * exp(-bt * 3.0))
		var horn = (sin(TAU * f * t) * 0.5 + sin(TAU * f * 2.0 * t) * 0.22 + sin(TAU * f * 3.0 * t) * 0.1) * env * 0.42
		var drone = sin(TAU * base * 0.5 * t) * 0.16 + sin(TAU * base * 0.75 * t) * 0.07
		var kick = sin(TAU * (48.0 + 90.0 * exp(-bt * 30.0)) * bt) * exp(-bt * 9.0) * 0.55
		var anvil = 0.0
		if bi % 2 == 1:
			anvil = (sin(TAU * 1310.0 * bt) * 0.5 + sin(TAU * 2210.0 * bt) * 0.3) * exp(-bt * 14.0) * 0.3
		lp += (_noise() - lp) * 0.7
		var roll = lp * 0.12 * (1.0 if bi % 8 == 7 else 0.0) * (0.5 + 0.5 * sin(TAU * 12.0 * t))
		d[i] = (horn + drone + kick + anvil + roll) * 0.68
	return _wav(d, rate, true)


func _ambient_loop(env: String) -> AudioStreamWAV:
	var rate = 11025
	var dur = 6.0
	var n = int(dur * rate)
	var d = PackedFloat32Array()
	d.resize(n)
	var lp = 0.0
	for i in n:
		var t = float(i) / rate
		lp += (_noise() - lp) * (0.02 if env == "mountain" or env == "ridge" else 0.05)
		var wind = lp * (0.6 + 0.4 * sin(TAU * t / dur))
		var extra = 0.0
		match env:
			"mine":
				extra = sin(TAU * 1600.0 * t) * exp(-fmod(t, 1.7) * 30.0) * 0.08
			"foundry":
				extra = sin(TAU * 42.0 * t) * 0.2 + sin(TAU * 880.0 * t) * exp(-fmod(t, 2.0) * 12.0) * 0.1
			"forest":
				# wind in dead branches (creak) and a distant crow
				var ct = fmod(t, 3.7)
				extra = sin(TAU * (90.0 + 30.0 * sin(t * 1.3)) * t) * exp(-fmod(t, 2.3) * 3.0) * 0.05 + sin(TAU * 620.0 * ct * (1.0 - ct)) * (exp(-ct * 9.0) * 0.12 if ct < 0.5 else 0.0)
			"marsh":
				# bubbles, wrong-sounding frogs, a buzz
				var bt = fmod(t, 0.83)
				extra = sin(TAU * (180.0 + bt * 400.0) * t) * exp(-bt * 22.0) * 0.12 + sin(TAU * 130.0 * t) * (0.5 + 0.5 * sin(TAU * 9.0 * t)) * exp(-fmod(t, 2.9) * 2.0) * 0.06 + sin(TAU * 240.0 * t) * 0.012
			"road":
				# creaking gibbets, a distant bell
				var gt = fmod(t, 2.5)
				extra = sin(TAU * 70.0 * t + sin(t * 3.0)) * exp(-gt * 4.0) * 0.06 + (sin(TAU * 420.0 * t) + 0.5 * sin(TAU * 1130.0 * t)) * exp(-fmod(t, 6.0) * 1.2) * 0.05
			"fungal":
				# drips and spore puffs
				extra = sin(TAU * 1900.0 * t) * exp(-fmod(t, 1.3) * 40.0) * 0.08 + _noise() * exp(-fmod(t + 0.6, 2.1) * 6.0) * 0.08
			"plains":
				# high wind over grass and a flag snapping
				var ft = fmod(t, 0.9)
				extra = _noise() * exp(-ft * 18.0) * 0.07 * (0.5 + 0.5 * sin(TAU * t / 3.0)) + sin(TAU * 52.0 * t) * exp(-fmod(t + 2.0, 6.0) * 1.5) * 0.04
			"highridge":
				# rope bridges creaking and distant thunder
				var rt = fmod(t, 2.9)
				extra = sin(TAU * (60.0 + rt * 20.0) * t) * exp(-rt * 3.5) * 0.06 + lp * 3.0 * exp(-fmod(t + 3.0, 6.0) * 0.9) * 0.25
			"cloudsea":
				# the hush of the cloud sea, a far ghost bell
				extra = (sin(TAU * 310.0 * t) + 0.4 * sin(TAU * 777.0 * t)) * exp(-fmod(t + 1.0, 6.0) * 1.1) * 0.035
				wind *= 0.6
			"fort":
				# banners in tatters, loose stones
				var bt2 = fmod(t, 1.1)
				extra = _noise() * exp(-bt2 * 14.0) * 0.06 + sin(TAU * 900.0 * t) * exp(-fmod(t, 4.3) * 25.0) * 0.05
			# M007 Act IV: the dead foundries
			"city":
				# wind moaning through chimneys, a far hammer, a chain swinging
				var ht = fmod(t, 1.5)
				extra = sin(TAU * (140.0 + 18.0 * sin(t * 0.7)) * t) * 0.035 + (sin(TAU * 620.0 * ht) + 0.5 * sin(TAU * 1450.0 * ht)) * exp(-ht * 30.0) * 0.05 * (1.0 if int(t / 1.5) % 2 == 0 else 0.0) + sin(TAU * 1900.0 * t) * exp(-fmod(t + 0.4, 2.7) * 40.0) * 0.04
			"dead_forge":
				# the cold foundry's hum, slow distant hammering, oil dripping
				var dt2 = fmod(t, 2.0)
				extra = sin(TAU * 49.0 * t) * 0.16 + sin(TAU * 98.0 * t) * 0.04 + sin(TAU * 410.0 * dt2) * exp(-dt2 * 18.0) * 0.07 + sin(TAU * 1700.0 * t) * exp(-fmod(t + 0.9, 1.7) * 55.0) * 0.06
				wind *= 0.5
			"factory":
				# chains clinking on idle conveyors, a dead machine's hum, drips
				var ct2 = fmod(t, 0.75)
				extra = sin(TAU * 60.0 * t) * 0.1 + (sin(TAU * 1250.0 * ct2) + sin(TAU * 1830.0 * ct2)) * exp(-ct2 * 50.0) * 0.035 * (1.0 if int(t / 0.75) % 3 != 1 else 0.0) + sin(TAU * 1500.0 * t) * exp(-fmod(t, 2.3) * 50.0) * 0.06
				wind *= 0.4
			"graveyard":
				# dusty wind over scrap, rusted plates creaking, a loose chain
				var gt2 = fmod(t, 3.1)
				extra = sin(TAU * (75.0 + gt2 * 14.0) * t) * exp(-gt2 * 2.5) * 0.06 + sin(TAU * 1100.0 * t) * exp(-fmod(t + 1.3, 2.2) * 35.0) * 0.04
			# M008 Act V: the Black Rift
			"waste":
				# ash wind hissing over bone dunes, a dry rattle now and then
				var at2 = fmod(t, 1.9)
				extra = lp * 2.2 * (0.6 + 0.4 * sin(TAU * t / 3.0)) * 0.3 + sin(TAU * 1400.0 * t) * exp(-at2 * 40.0) * 0.03 * (1.0 if int(t / 1.9) % 2 == 0 else 0.0)
			"rift":
				# the rift's hum: a low beating drone with a glassy shimmer
				extra = (sin(TAU * 41.0 * t) + sin(TAU * 43.5 * t)) * 0.08 + sin(TAU * (660.0 + 40.0 * sin(t * 0.9)) * t) * 0.02
				wind *= 0.5
			"citadel":
				# distant choirs in the ruined halls, wind through broken windows
				extra = (sin(TAU * 196.0 * t) + sin(TAU * 233.1 * t) * 0.8 + sin(TAU * 293.7 * t) * 0.6) * (0.5 + 0.5 * sin(TAU * t / 6.0)) * 0.025
			"gate":
				# gate chanting: a slow, low two-note chant pulsing under the rift hum
				var ct3 = fmod(t, 1.5)
				var nn = 98.0 if int(t / 1.5) % 2 == 0 else 87.3
				extra = sin(TAU * nn * t) * (0.6 + 0.4 * sin(PI * ct3 / 1.5)) * 0.07 + (sin(TAU * 41.0 * t) + sin(TAU * 43.0 * t)) * 0.05
				wind *= 0.6
		d[i] = (wind * 2.0 + extra) * 0.5
	return _wav(d, rate, true)



# ------------------------------------------------------------------ M002 sound design
## Mixes pre-built streams sample-by-sample (then re-masters) — used to layer sounds.
func _layer(parts: Array, gains: Array) -> AudioStreamWAV:
	var n = 0
	var bufs: Array = []
	for p in parts:
		var w: AudioStreamWAV = p
		var b = PackedFloat32Array()
		var raw: PackedByteArray = w.data
		b.resize(raw.size() / 2)
		for i in b.size():
			b[i] = float(raw.decode_s16(i * 2)) / 32000.0
		bufs.append(b)
		n = maxi(n, b.size())
	var out = PackedFloat32Array()
	out.resize(n)
	for k in bufs.size():
		var b2: PackedFloat32Array = bufs[k]
		for i in b2.size():
			out[i] += b2[i] * float(gains[k])
	return _wav(out)


## The boomstick: sub-bass thump + wide noise blast + mechanical action clack + shell ring.
func _boomstick_sound() -> AudioStreamWAV:
	var dur = 0.9
	var n = int(dur * MIX_RATE)
	var d = PackedFloat32Array()
	d.resize(n)
	var lp = 0.0
	var lp2 = 0.0
	var ph = 0.0
	for i in n:
		var t = float(i) / MIX_RATE
		var f = 42.0 + 120.0 * exp(-t * 18.0)
		ph += TAU * f / MIX_RATE
		var sub = sin(ph) * exp(-t * 5.5) * 1.1
		lp += (_noise() - lp) * 0.35
		lp2 += (lp - lp2) * 0.08
		var blast = (lp * 0.9 + lp2 * 1.6) * (exp(-t * 14.0) if t > 0.004 else t / 0.004)
		var clack = 0.0
		if t > 0.32 and t < 0.38:
			clack = (sin(TAU * 1700.0 * t) + _noise() * 0.6) * exp(-(t - 0.32) * 60.0) * 0.5
		var ring = 0.0
		if t > 0.45:
			ring = sin(TAU * 2600.0 * t) * exp(-(t - 0.45) * 22.0) * 0.18
		d[i] = sub + blast + clack + ring
	return _wav(_master(d, 1.6))


func _drill_sound() -> AudioStreamWAV:
	var dur = 0.6
	var n = int(dur * MIX_RATE)
	var d = PackedFloat32Array()
	d.resize(n)
	var ph = 0.0
	var lp = 0.0
	for i in n:
		var t = float(i) / MIX_RATE
		var f = 90.0 + 160.0 * minf(1.0, t * 4.0)   # spin-up
		ph += TAU * f / MIX_RATE
		var saw = fmod(ph / TAU, 1.0) * 2.0 - 1.0
		lp += (_noise() - lp) * 0.5
		var grind = lp * (0.5 + 0.5 * sin(TAU * 31.0 * t))
		d[i] = (saw * 0.5 + grind * 0.6) * sin(PI * t / dur)
	return _wav(d)


func _electric_sound() -> AudioStreamWAV:
	var dur = 0.5
	var n = int(dur * MIX_RATE)
	var d = PackedFloat32Array()
	d.resize(n)
	for i in n:
		var t = float(i) / MIX_RATE
		var crack = _noise() * (1.0 if _rng.randf() < 0.25 else 0.2)
		d[i] = (crack + sin(TAU * 120.0 * t) * 0.4 + sin(TAU * 2400.0 * t + _noise()) * 0.15) * exp(-t * 6.0)
	return _wav(d)


func _flame_sound() -> AudioStreamWAV:
	var dur = 0.8
	var n = int(dur * MIX_RATE)
	var d = PackedFloat32Array()
	d.resize(n)
	var lp = 0.0
	for i in n:
		var t = float(i) / MIX_RATE
		lp += (_noise() - lp) * 0.06
		d[i] = (lp * 3.0 + _noise() * 0.08 * (0.5 + 0.5 * sin(TAU * 13.0 * t))) * sin(PI * t / dur)
	return _wav(d)


## M005: wet bubbling (marsh mire, miasma): noise through a wobbling resonance with bubble pops
# ------------------------------------------------------------------ M007 sound design
## A soft, felted tick: one low sine with a very fast decay and no metallic partials (replaces the tap "cling").
func _tick(dur: float, freq: float) -> AudioStreamWAV:
	var n = int(dur * MIX_RATE)
	var d = PackedFloat32Array()
	d.resize(n)
	var lp = 0.0
	for i in n:
		var t = float(i) / MIX_RATE
		lp += (_noise() - lp) * 0.15
		d[i] = (sin(TAU * freq * t * (1.0 - t * 2.0)) * 0.55 + lp * 0.25) * exp(-t * 70.0) * minf(1.0, t * 800.0)
	return _wav(d)


## A brushed, muffled scuff (boots on stone).
func _brush(dur: float) -> AudioStreamWAV:
	var n = int(dur * MIX_RATE)
	var d = PackedFloat32Array()
	d.resize(n)
	var lp = 0.0
	for i in n:
		var t = float(i) / MIX_RATE
		lp += (_noise() - lp) * 0.07
		d[i] = lp * 2.2 * sin(PI * t / dur) * exp(-t * 6.0)
	return _wav(d)


## A gear ratchet: n dull clicks of low-passed noise.
func _ratchet(dur: float, clicks: int) -> AudioStreamWAV:
	var n = int(dur * MIX_RATE)
	var d = PackedFloat32Array()
	d.resize(n)
	var lp = 0.0
	var gap = dur / float(maxi(1, clicks))
	for i in n:
		var t = float(i) / MIX_RATE
		var ct = fmod(t, gap)
		lp += (_noise() - lp) * 0.3
		d[i] = (lp * 1.2 + sin(TAU * 230.0 * ct) * 0.3) * exp(-ct * 90.0) * (1.0 - t / dur * 0.5)
	return _wav(d)


## Bending iron: a low tone sliding and wavering (girders about to give).
func _groan(dur: float, f0: float) -> AudioStreamWAV:
	var n = int(dur * MIX_RATE)
	var d = PackedFloat32Array()
	d.resize(n)
	var ph = 0.0
	var lp = 0.0
	for i in n:
		var t = float(i) / MIX_RATE
		var f = f0 * (1.0 - 0.25 * t / dur) * (1.0 + 0.04 * sin(TAU * 6.5 * t))
		ph += TAU * f / MIX_RATE
		var saw = fmod(ph / TAU, 1.0) * 2.0 - 1.0
		lp += (saw - lp) * 0.06
		d[i] = (lp * 1.4 + sin(ph * 2.01) * 0.15) * sin(PI * t / dur)
	return _wav(d)


## A wrong, wordless choir: detuned voices on a minor triad with slow vowel sweeps (necromantic undertone).
func _choir(dur: float, f0: float) -> AudioStreamWAV:
	var n = int(dur * MIX_RATE)
	var d = PackedFloat32Array()
	d.resize(n)
	var ratios = [1.0, 1.189, 1.498, 0.995, 2.01]
	var ph = [0.0, 0.0, 0.0, 0.0, 0.0]
	var lp = 0.0
	for i in n:
		var t = float(i) / MIX_RATE
		var acc = 0.0
		for k in ratios.size():
			var f = f0 * float(ratios[k]) * (1.0 + 0.006 * sin(TAU * (4.3 + k) * t))
			ph[k] = float(ph[k]) + TAU * f / MIX_RATE
			acc += fmod(float(ph[k]) / TAU, 1.0) * 2.0 - 1.0
		var vow = 0.05 + 0.05 * (0.5 + 0.5 * sin(TAU * 0.6 * t))
		lp += (acc - lp) * vow
		d[i] = lp * 0.35 * sin(PI * t / dur)
	return _wav(d)


## A wheezing, failing engine: chuffs of noise on an uneven, slowing beat.
func _wheeze(dur: float) -> AudioStreamWAV:
	var n = int(dur * MIX_RATE)
	var d = PackedFloat32Array()
	d.resize(n)
	var prev = 0.0
	var ph = 0.0
	for i in n:
		var t = float(i) / MIX_RATE
		ph += (5.0 - 1.5 * t / dur + 0.8 * sin(TAU * 0.9 * t)) / MIX_RATE
		var c = fmod(ph, 1.0)
		var x = _noise()
		var hp = x - prev
		prev = x
		d[i] = hp * 0.7 * exp(-c * 9.0) * sin(PI * t / dur)
	return _wav(d)


func _gurgle(dur: float, pops: float) -> AudioStreamWAV:
	var n = int(dur * MIX_RATE)
	var d = PackedFloat32Array()
	d.resize(n)
	var lp = 0.0
	for i in n:
		var t = float(i) / MIX_RATE
		lp += (_noise() - lp) * 0.08
		var ph = fmod(t * pops, 1.0)
		var pop = sin(TAU * (220.0 + ph * 500.0) * t) * exp(-ph * 14.0)
		var env = minf(1.0, t * 20.0) * exp(-t * 1.6 / dur)
		d[i] = (lp * 1.5 + pop * 0.5) * env
	return _wav(d)
