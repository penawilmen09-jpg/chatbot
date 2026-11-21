extends SceneTree
## Genera los sonidos originales del juego (PCM 16 bit mono 22050 Hz) en assets/audio/*.pcm
## Uso: godot --headless --path . -s tools/gen_audio.gd

const SR := 22050
var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.seed = 7
	_save("coin", _coin())
	_save("fuel", _fuel())
	_save("jump", _jump())
	_save("land", _land())
	_save("crash", _crash())
	_save("click", _click())
	_save("deny", _deny())
	_save("win", _win())
	_save("buy", _buy())
	_save("brake", _brake())
	_save("engine", _engine())
	_save("music", _music())
	print("Audio generado.")
	quit()

func _buf(sec: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(sec * SR))
	return b

func _save(name: String, b: PackedFloat32Array) -> void:
	var bytes := PackedByteArray()
	bytes.resize(b.size() * 2)
	for i in b.size():
		bytes.encode_s16(i * 2, int(clampf(b[i], -1.0, 1.0) * 32000.0))
	var f := FileAccess.open("res://assets/audio/%s.pcm" % name, FileAccess.WRITE)
	f.store_buffer(bytes)
	f.close()

func _env(t: float, dur: float, attack := 0.005) -> float:
	var a := minf(t / attack, 1.0)
	var d := pow(maxf(1.0 - t / dur, 0.0), 2.0)
	return a * d

func _add_tone(b: PackedFloat32Array, start: float, dur: float, f0: float, f1: float, vol: float, harm := 0.3) -> void:
	var s0 := int(start * SR)
	var n := int(dur * SR)
	var ph := 0.0
	for i in n:
		if s0 + i >= b.size():
			break
		var t := float(i) / SR
		var f := lerpf(f0, f1, float(i) / n)
		ph += TAU * f / SR
		var v := sin(ph) + harm * sin(2.0 * ph) + harm * 0.5 * sin(3.0 * ph)
		b[s0 + i] += v * _env(t, dur) * vol

func _add_noise(b: PackedFloat32Array, start: float, dur: float, vol: float, lp := 0.3, decay := 2.0) -> void:
	var s0 := int(start * SR)
	var n := int(dur * SR)
	var y := 0.0
	for i in n:
		if s0 + i >= b.size():
			break
		y += (rng.randf_range(-1.0, 1.0) - y) * lp
		b[s0 + i] += y * pow(maxf(1.0 - float(i) / n, 0.0), decay) * vol

func _coin() -> PackedFloat32Array:
	var b := _buf(0.32)
	_add_tone(b, 0.0, 0.10, 988.0, 988.0, 0.45, 0.25)
	_add_tone(b, 0.07, 0.25, 1319.0, 1319.0, 0.45, 0.25)
	return b

func _fuel() -> PackedFloat32Array:
	var b := _buf(0.5)
	_add_tone(b, 0.0, 0.18, 300.0, 520.0, 0.5)
	_add_tone(b, 0.15, 0.2, 380.0, 640.0, 0.5)
	_add_tone(b, 0.3, 0.2, 520.0, 880.0, 0.5)
	return b

func _jump() -> PackedFloat32Array:
	var b := _buf(0.22)
	_add_tone(b, 0.0, 0.2, 180.0, 460.0, 0.5, 0.1)
	_add_noise(b, 0.0, 0.12, 0.15)
	return b

func _land() -> PackedFloat32Array:
	var b := _buf(0.3)
	_add_tone(b, 0.0, 0.28, 110.0, 50.0, 0.9, 0.2)
	_add_noise(b, 0.0, 0.2, 0.5, 0.15, 3.0)
	return b

func _crash() -> PackedFloat32Array:
	var b := _buf(0.9)
	_add_noise(b, 0.0, 0.85, 0.9, 0.5, 1.5)
	_add_tone(b, 0.0, 0.6, 140.0, 40.0, 0.7, 0.4)
	_add_tone(b, 0.12, 0.3, 700.0, 300.0, 0.25, 0.8)
	return b

func _click() -> PackedFloat32Array:
	var b := _buf(0.07)
	_add_tone(b, 0.0, 0.06, 1100.0, 800.0, 0.5, 0.2)
	return b

func _deny() -> PackedFloat32Array:
	var b := _buf(0.3)
	_add_tone(b, 0.0, 0.12, 170.0, 150.0, 0.5, 0.9)
	_add_tone(b, 0.14, 0.14, 150.0, 120.0, 0.5, 0.9)
	return b

func _win() -> PackedFloat32Array:
	var b := _buf(0.9)
	var notes := [523.25, 659.25, 783.99, 1046.5]
	for i in notes.size():
		_add_tone(b, i * 0.15, 0.45, notes[i], notes[i], 0.4, 0.3)
	return b

func _buy() -> PackedFloat32Array:
	var b := _buf(0.6)
	_add_tone(b, 0.0, 0.5, 1568.0, 1568.0, 0.35, 0.15)
	_add_tone(b, 0.08, 0.5, 2093.0, 2093.0, 0.35, 0.15)
	_add_noise(b, 0.0, 0.06, 0.2, 0.7, 2.0)
	return b

func _brake() -> PackedFloat32Array:
	var b := _buf(0.3)
	_add_noise(b, 0.0, 0.3, 0.35, 0.12, 1.0)
	return b

func _engine() -> PackedFloat32Array:
	# Bucle de 1 s: fundamental 55 Hz (55 ciclos exactos) + armónicos y pulsos de combustión.
	var b := _buf(1.0)
	var n := b.size()
	for i in n:
		var t := float(i) / n
		var v := 0.0
		for h in range(1, 11):
			v += sin(TAU * 55.0 * h * t) * (0.7 / h)
		var pulse := 0.6 + 0.4 * sin(TAU * 27.0 * t)
		v *= pulse
		v += sin(TAU * 110.0 * t + 1.2 * sin(TAU * 4.0 * t)) * 0.25
		b[i] = v * 0.45
	return b

# ---------- Música: merengue instrumental sintético ----------
func _music() -> PackedFloat32Array:
	var bpm := 132.0
	var beat := 60.0 / bpm
	var bars := 8
	var total := bars * 4 * beat
	# ajustar para que el bucle sea de longitud exacta
	var b := _buf(total)
	# progresión: Am | Dm | E7 | Am | Am | Dm | E7 | Am
	var roots := [220.0, 146.83, 164.81, 220.0, 220.0, 146.83, 164.81, 220.0]
	var chords := [
		[220.0, 261.63, 329.63], [220.0, 293.66, 349.23], [207.65, 246.94, 329.63], [220.0, 261.63, 329.63],
		[220.0, 261.63, 329.63], [220.0, 293.66, 349.23], [207.65, 246.94, 329.63], [220.0, 261.63, 329.63]]
	var penta := [440.0, 523.25, 587.33, 659.25, 783.99, 880.0]
	var mel_rng := RandomNumberGenerator.new()
	mel_rng.seed = 99
	for bar in bars:
		var t0 := bar * 4 * beat
		for q in 8:  # corcheas
			var t := t0 + q * beat * 0.5
			# güira: ruido agudo en cada corchea
			_add_noise(b, t, 0.05, 0.10 if q % 2 == 0 else 0.07, 0.9, 2.0)
			# tambora: golpe grave en negras
			if q % 2 == 0:
				_add_tone(b, t, 0.16, 120.0, 70.0, 0.32, 0.2)
			else:
				_add_noise(b, t, 0.05, 0.18, 0.35, 2.0)
			# bajo: raíz / quinta
			var bf: float = roots[bar] * 0.5 * (1.5 if q % 4 == 2 else 1.0)
			if q % 2 == 0:
				_add_tone(b, t, beat * 0.55, bf, bf, 0.30, 0.5)
		# acordes sincopados (acentos en contratiempo)
		for q: int in [1, 3, 5, 7]:
			var t2: float = t0 + q * beat * 0.5
			for fq in chords[bar]:
				_add_tone(b, t2, 0.18, fq, fq, 0.09, 0.4)
		# melodía
		var q2 := 0
		while q2 < 8:
			var len := 1 if mel_rng.randf() < 0.6 else 2
			if mel_rng.randf() < 0.8:
				var nf: float = penta[mel_rng.randi() % penta.size()]
				_add_tone(b, t0 + q2 * beat * 0.5, beat * 0.5 * len * 0.9, nf, nf, 0.13, 0.35)
			q2 += len
	# normalizar
	var mx := 0.001
	for i in b.size():
		mx = maxf(mx, absf(b[i]))
	for i in b.size():
		b[i] = b[i] / mx * 0.8
	return b
