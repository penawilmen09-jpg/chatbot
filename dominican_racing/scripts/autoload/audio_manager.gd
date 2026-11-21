extends Node
## Audio: efectos, motor y música (recursos PCM originales generados en tools/gen_audio.gd).

const RATE := 22050
var _streams: Dictionary = {}
var _pool: Array = []
var _pool_idx := 0
var _engine: AudioStreamPlayer
var _music: AudioStreamPlayer
var _brake_cd := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus("Music")
	_ensure_bus("SFX")
	for n in ["coin", "fuel", "jump", "land", "crash", "click", "deny", "win", "buy", "brake"]:
		_streams[n] = _load_pcm(n, false)
	for i in 10:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	_engine = AudioStreamPlayer.new()
	_engine.bus = "SFX"
	_engine.stream = _load_pcm("engine", true)
	_engine.volume_db = -80.0
	add_child(_engine)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.stream = _load_pcm("music", true)
	add_child(_music)
	apply_settings()

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, bus_name)
		AudioServer.set_bus_send(i, "Master")

func _load_pcm(n: String, loop: bool) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	var path := "res://assets/audio/%s.pcm" % n
	var bytes := FileAccess.get_file_as_bytes(path)
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = bytes
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = bytes.size() / 2
	return s

func apply_settings() -> void:
	var st: Dictionary = SaveManager.data["settings"]
	var mute: bool = st["mute"]
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), mute)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(float(st["music"]) * 0.7, 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(maxf(float(st["sfx"]), 0.0001)))

func play(n: String, volume_db := 0.0, pitch := 1.0) -> void:
	if not _streams.has(n):
		return
	var p: AudioStreamPlayer = _pool[_pool_idx]
	_pool_idx = (_pool_idx + 1) % _pool.size()
	p.stream = _streams[n]
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()

func click() -> void:
	play("click", -6.0)

func play_music() -> void:
	if not _music.playing:
		_music.play()

func stop_music() -> void:
	_music.stop()

func engine_start() -> void:
	if not _engine.playing:
		_engine.play()

func engine_stop() -> void:
	_engine.volume_db = -80.0
	_engine.stop()

## rpm01: 0..1, load01: acelerador 0..1
func engine_update(rpm01: float, load01: float) -> void:
	if not _engine.playing:
		return
	_engine.pitch_scale = lerpf(0.6, 2.2, clampf(rpm01, 0.0, 1.0))
	_engine.volume_db = lerpf(-22.0, -9.0, clampf(load01, 0.0, 1.0))

func brake_hiss() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _brake_cd > 0.35:
		_brake_cd = now
		play("brake", -10.0)
