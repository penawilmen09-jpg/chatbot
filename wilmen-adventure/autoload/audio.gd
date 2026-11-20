extends Node
## Música y efectos de sonido (todos sintetizados localmente; sin Internet).

const SFX_DIR := "res://audio/sfx/"
const MUSIC_DIR := "res://audio/music/"
const POLYPHONY := 10

var _sfx_players: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _cache: Dictionary = {}
var _current_music: String = ""
var _next_sfx: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = AudioStreamPlayer.new()
	_music.volume_db = -6.0
	add_child(_music)
	for i in range(POLYPHONY):
		var p := AudioStreamPlayer.new()
		p.volume_db = -3.0
		add_child(p)
		_sfx_players.append(p)
	Game.settings_changed.connect(apply_settings)
	apply_settings()


func apply_settings() -> void:
	var music_on: bool = bool(Game.settings.get("music", true))
	_music.volume_db = -6.0 if music_on else -80.0


func _load(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	if not ResourceLoader.exists(path):
		push_warning("Audio no encontrado: %s" % path)
		_cache[path] = null
		return null
	var s: AudioStream = load(path)
	_cache[path] = s
	return s


func play_sfx(sfx_name: String, pitch: float = 1.0) -> void:
	if not bool(Game.settings.get("sfx", true)):
		return
	var s := _load(SFX_DIR + sfx_name + ".wav")
	if s == null:
		return
	var p: AudioStreamPlayer = _sfx_players[_next_sfx]
	_next_sfx = (_next_sfx + 1) % _sfx_players.size()
	p.stream = s
	p.pitch_scale = pitch
	p.play()


func play_music(track: String, loop: bool = true) -> void:
	if _current_music == track and _music.playing:
		return
	var s := _load(MUSIC_DIR + track + ".ogg")
	if s == null:
		return
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = loop
	_current_music = track
	_music.stream = s
	_music.play()


func stop_music() -> void:
	_current_music = ""
	_music.stop()
