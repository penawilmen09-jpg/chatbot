extends Node
## Música y efectos (todo sintetizado localmente; sin Internet).
## - Buses "Music" y "SFX" con volumen y silencio independientes.
## - Transiciones suaves (crossfade) entre canciones con dos reproductores.

const SFX_DIR := "res://audio/sfx/"
const MUSIC_DIR := "res://audio/music/"
const POLYPHONY := 10
const SILENT_DB := -60.0
const PLAY_DB := -4.0

## Nombre de la canción que suena (o está entrando). Vacío = ninguna.
var current_music: String = ""
## Registro de todas las canciones pedidas (útil para las pruebas).
var music_log: Array = []

var _sfx_players: Array[AudioStreamPlayer] = []
var _music_players: Array[AudioStreamPlayer] = []
var _active: int = 0
var _cache: Dictionary = {}
var _music_cache_order: Array = []
var _next_sfx: int = 0
var _fade_tweens: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus("Music")
	_ensure_bus("SFX")
	for i in range(2):
		var m := AudioStreamPlayer.new()
		m.bus = "Music"
		m.volume_db = SILENT_DB
		add_child(m)
		_music_players.append(m)
	for i in range(POLYPHONY):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		p.volume_db = -3.0
		add_child(p)
		_sfx_players.append(p)
	Game.settings_changed.connect(apply_settings)
	apply_settings()


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


func apply_settings() -> void:
	_apply_bus("Music", bool(Game.settings.get("music", true)), float(Game.settings.get("music_vol", 0.8)))
	_apply_bus("SFX", bool(Game.settings.get("sfx", true)), float(Game.settings.get("sfx_vol", 1.0)))


func _apply_bus(bus_name: String, enabled: bool, vol: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, not enabled or vol <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(vol, 0.001, 1.0)))


func bus_volume_linear(bus_name: String) -> float:
	var idx: int = AudioServer.get_bus_index(bus_name)
	return db_to_linear(AudioServer.get_bus_volume_db(idx)) if idx != -1 else 0.0


func bus_muted(bus_name: String) -> bool:
	var idx: int = AudioServer.get_bus_index(bus_name)
	return AudioServer.is_bus_mute(idx) if idx != -1 else true


func _load(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	if not ResourceLoader.exists(path):
		push_warning("Audio no encontrado: %s" % path)
		return null
	var s: AudioStream = load(path)
	_cache[path] = s
	return s


func play_sfx(sfx_name: String, pitch: float = 1.0) -> void:
	var s := _load(SFX_DIR + sfx_name + ".wav")
	if s == null:
		return
	var p: AudioStreamPlayer = _sfx_players[_next_sfx]
	_next_sfx = (_next_sfx + 1) % _sfx_players.size()
	p.stream = s
	p.pitch_scale = pitch
	p.play()


func play_music(track: String, loop: bool = true, fade: float = 1.2) -> void:
	if current_music == track and _music_players[_active].playing:
		return
	var path: String = MUSIC_DIR + track + ".ogg"
	var s := _load(path)
	if s == null:
		return
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = loop
	music_log.append(track)
	if music_log.size() > 200:
		music_log.pop_front()
	current_music = track
	# crossfade: el reproductor activo baja y el otro sube
	var old: AudioStreamPlayer = _music_players[_active]
	_active = 1 - _active
	var nw: AudioStreamPlayer = _music_players[_active]
	nw.stream = s
	nw.volume_db = SILENT_DB
	nw.play()
	_fade(nw, PLAY_DB, fade, false)
	if old.playing:
		_fade(old, SILENT_DB, fade, true)
	_trim_music_cache(path)


func stop_music(fade: float = 0.8) -> void:
	current_music = ""
	for p in _music_players:
		if p.playing:
			_fade(p, SILENT_DB, fade, true)


func _fade(player: AudioStreamPlayer, to_db: float, dur: float, stop_after: bool) -> void:
	if _fade_tweens.has(player):
		var old_tw: Tween = _fade_tweens[player]
		if old_tw != null and old_tw.is_valid():
			old_tw.kill()
	var tw := create_tween()
	_fade_tweens[player] = tw
	tw.tween_property(player, "volume_db", to_db, maxf(0.01, dur))
	if stop_after:
		tw.tween_callback(player.stop)


func _trim_music_cache(path: String) -> void:
	## Solo se guardan en memoria las 3 últimas canciones (la actual y las recientes).
	_music_cache_order.erase(path)
	_music_cache_order.append(path)
	while _music_cache_order.size() > 3:
		var drop: String = _music_cache_order.pop_front()
		_cache.erase(drop)
