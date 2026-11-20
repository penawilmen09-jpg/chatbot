extends SceneTree
## Batería de pruebas de WILMEN ADVENTURE dentro del motor (Godot 4.3 headless).
##
##   godot --headless --path . --import
##   godot --headless --path . --script res://tests/smoke_test.gd
##
## Devuelve código 0 si todo va bien y 1 si algo falla. Cada comprobación imprime "ok" o "FALLO".
## Usa un archivo de guardado temporal (user://smoke_test_save.json), no toca el guardado real.

var _failed: int = 0
var _scene: PackedScene
var _game
var _audio


func _initialize() -> void:
	_run.call_deferred()


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok   ", msg)
	else:
		print("  FALLO ", msg)
		_failed += 1


func _frames(n: int) -> void:
	for i in range(n):
		await physics_frame


func _reset_game() -> void:
	_game.levels = {}
	_game.unlocked = {1: true}
	_game.worlds_done = []
	_game.lives = 5
	_game.score = 0
	_game.coins = 0
	_game.settings = {"music": true, "sfx": true, "touch": "auto", "music_vol": 0.8, "sfx_vol": 1.0}


func _mark_done(i: int) -> void:
	## Simula haber completado el nivel i legítimamente (queda abierto y abre el siguiente).
	_game.levels[str(i)] = {"done": true, "gems": [false, false, false], "best": 0}
	_game.unlocked[i] = true
	_game.unlocked[i + 1] = true


func _load_level(n: int, redirect: bool = false):
	## Carga un nivel marcando antes como completados los anteriores (desbloqueo legítimo).
	for i in range(1, n):
		_mark_done(i)
	_game.current_level = n
	var lvl = _scene.instantiate()
	lvl.redirect_on_block = redirect
	root.add_child(lvl)
	await process_frame
	await _frames(5)
	return lvl


func _free_level(lvl) -> void:
	paused = false
	lvl.queue_free()
	await process_frame


func _run() -> void:
	_game = root.get_node("Game")
	_audio = root.get_node("Audio")
	_game.save_path = "user://smoke_test_save.json"
	_reset_game()
	_scene = load("res://levels/level.tscn")
	_check(_scene != null, "level.tscn carga")

	_test_resources()
	_test_offline_static()
	await _test_audio_system()
	_test_unlock_rules_pure()
	await _test_locked_levels_cannot_load()
	await _test_unlock_flow()
	_test_persistence_and_migration()
	await _test_all_levels()
	await _test_music_changes()
	await _test_mechanics()
	await _test_entities()
	await _test_powers()
	await _test_bosses()
	await _test_flow()
	await _test_menus()
	await _bot_level_one()
	print("RESULTADO: %s" % ("TODO OK" if _failed == 0 else "%d fallos" % _failed))
	quit(0 if _failed == 0 else 1)


# ============================================================ 10. recursos ==
func _test_resources() -> void:
	print("Recursos: escenas, texturas, niveles y audio")
	for p in ["res://levels/level.tscn", "res://characters/player/player.tscn", "res://enemies/enemy.tscn",
			"res://enemies/boss.tscn", "res://items/block.tscn", "res://items/pickup.tscn",
			"res://items/projectile.tscn", "res://items/spring.tscn", "res://items/goal.tscn",
			"res://items/checkpoint.tscn", "res://items/mover.tscn", "res://items/crumble.tscn",
			"res://items/geyser.tscn", "res://items/crusher.tscn", "res://ui/title.tscn",
			"res://ui/level_select.tscn", "res://ui/ending.tscn"]:
		_check(ResourceLoader.exists(p) and load(p) != null, "escena %s" % p)
	for w in range(1, 11):
		var ok: bool = true
		for p in ["res://assets/tiles/tiles_w%d.png" % w, "res://assets/tiles/mplatform_w%d.png" % w,
				"res://assets/decor/decor_w%d.png" % w, "res://assets/enemies/enemies_w%d.png" % w,
				"res://assets/bosses/boss_%d.png" % w, "res://assets/backgrounds/bg_w%d_far.png" % w,
				"res://assets/backgrounds/bg_w%d_mid.png" % w, "res://assets/backgrounds/bg_w%d_near.png" % w]:
			if not ResourceLoader.exists(p) or load(p) == null:
				ok = false
				print("    falta: ", p)
		_check(ok, "arte completo del mundo %d" % w)
	var missing_levels: Array = []
	for n in range(1, 101):
		var path: String = _game.level_path(n)
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null or f.get_length() < 200:
			missing_levels.append(n)
	_check(missing_levels.is_empty(), "existen los 100 archivos de nivel (faltan: %s)" % str(missing_levels))
	var missing_music: Array = []
	for t in _game.MUSIC_TRACKS:
		if not ResourceLoader.exists("res://audio/music/%s.ogg" % t) or load("res://audio/music/%s.ogg" % t) == null:
			missing_music.append(t)
	_check(missing_music.is_empty(), "las %d canciones existen y cargan (faltan: %s)" % [_game.MUSIC_TRACKS.size(), str(missing_music)])
	var sfx_files: Array = []
	for f2 in DirAccess.get_files_at("res://audio/sfx"):
		if f2.ends_with(".wav") or f2.ends_with(".wav.import"):
			var nm: String = f2.replace(".import", "").get_basename()
			if not sfx_files.has(nm):
				sfx_files.append(nm)
	var bad_sfx: Array = []
	for nm2 in sfx_files:
		if load("res://audio/sfx/%s.wav" % nm2) == null:
			bad_sfx.append(nm2)
	_check(sfx_files.size() >= 25 and bad_sfx.is_empty(), "%d efectos de sonido cargan" % sfx_files.size())
	# todos los sfx que pide el código existen
	var used: Dictionary = {}
	for dir in ["res://autoload", "res://characters/player", "res://enemies", "res://items", "res://levels", "res://ui"]:
		for f3 in DirAccess.get_files_at(dir):
			if f3.ends_with(".gd"):
				var src: String = FileAccess.get_file_as_string(dir + "/" + f3)
				var rx := RegEx.new()
				rx.compile("play_sfx\\(\"([a-z_]+)\"")
				for m in rx.search_all(src):
					used[m.get_string(1)] = true
	var unknown: Array = []
	for k in used:
		if not sfx_files.has(k):
			unknown.append(k)
	_check(unknown.is_empty(), "todos los sfx usados por el código existen (sin archivo: %s)" % str(unknown))


# ===================================================== 12. sin Internet =====
func _test_offline_static() -> void:
	print("Sin Internet: el código no usa red")
	var banned: Array = ["HTTPRequest", "HTTPClient", "WebSocketPeer", "StreamPeerTCP", "TCPServer", "UDPServer",
		"PacketPeerUDP", "ENetMultiplayerPeer", "http://", "https://", "OS.shell_open"]
	var hits: Array = []
	for dir in ["res://autoload", "res://characters", "res://enemies", "res://items", "res://levels", "res://ui"]:
		for f in _list_gd(dir):
			var src: String = FileAccess.get_file_as_string(f)
			for b in banned:
				if src.contains(b):
					hits.append("%s -> %s" % [f, b])
	_check(hits.is_empty(), "ningún script usa red ni enlaces externos %s" % str(hits))
	var proj: String = FileAccess.get_file_as_string("res://project.godot")
	_check(not proj.contains("http"), "project.godot sin referencias a Internet")


func _list_gd(dir: String) -> Array:
	var out: Array = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_list_gd(dir + "/" + d))
	return out


# ===================================================== audio: volumen/mute ===
func _test_audio_system() -> void:
	print("Audio: volumen, silencio independiente y transición suave")
	_game.set_setting("music_vol", 0.3)
	_game.set_setting("sfx_vol", 0.9)
	_check(absf(_audio.bus_volume_linear("Music") - 0.3) < 0.02, "volumen de música 0.3")
	_check(absf(_audio.bus_volume_linear("SFX") - 0.9) < 0.02, "volumen de efectos 0.9 (independiente)")
	_game.set_setting("music", false)
	_check(_audio.bus_muted("Music") and not _audio.bus_muted("SFX"), "silenciar música no silencia efectos")
	_game.set_setting("music", true)
	_game.set_setting("sfx", false)
	_check(_audio.bus_muted("SFX") and not _audio.bus_muted("Music"), "silenciar efectos no silencia música")
	_game.set_setting("sfx", true)
	_game.set_setting("music_vol", 0.8)
	_game.set_setting("sfx_vol", 1.0)
	_check(not _audio.bus_muted("Music") and not _audio.bus_muted("SFX"), "se puede reactivar el sonido")
	_audio.play_music("world1")
	await _frames(10)
	_audio.play_music("world2")
	await _frames(12)
	var both: bool = _audio._music_players[0].playing and _audio._music_players[1].playing
	_check(both, "crossfade: durante el cambio suenan las dos canciones (fundido)")
	var v_old: float = _audio._music_players[1 - _audio._active].volume_db
	var v_new: float = _audio._music_players[_audio._active].volume_db
	_check(v_new > v_old, "crossfade: la nueva sube y la anterior baja (%.1f dB vs %.1f dB)" % [v_new, v_old])
	for i in range(120):
		await physics_frame
	var count: int = 0
	for p in _audio._music_players:
		if p.playing:
			count += 1
	_check(count == 1 and _audio.current_music == "world2", "tras el fundido solo suena la canción nueva")
	_audio.stop_music(0.1)


# ================================================= 3,4,5. reglas de desbloqueo
func _test_unlock_rules_pure() -> void:
	print("Desbloqueo: reglas (partida nueva)")
	_reset_game()
	_check(_game.is_unlocked(1), "el nivel 1 está desbloqueado")
	var locked: int = 0
	for n in range(2, 101):
		if not _game.is_unlocked(n):
			locked += 1
	_check(locked == 99, "los 99 niveles 2-100 están bloqueados (%d)" % locked)
	var refused: int = 0
	for n in range(2, 101):
		if not _game.start_level(n):
			refused += 1
	_check(refused == 99, "start_level() rechaza los 99 niveles bloqueados (%d)" % refused)
	_check(_game.start_level(1), "start_level(1) funciona")
	_check(not _game.is_unlocked(0) and not _game.is_unlocked(101), "niveles fuera de rango no existen")
	# saltarse niveles: un nivel bloqueado no se puede completar ni abre el siguiente
	var res: Dictionary = _game.register_complete(5, [false, false, false], 100)
	_check(res.is_empty() and not _game.is_done(5) and _game.highest_unlocked() == 1 and not _game.is_unlocked(6) and not _game.is_unlocked(5), "completar el nivel 5 sin los anteriores no lo salta ni abre el 6")
	_reset_game()


func _test_locked_levels_cannot_load() -> void:
	print("Desbloqueo: cargar la escena de un nivel bloqueado directamente")
	_reset_game()
	var rejected: int = 0
	var players: int = 0
	for n in range(2, 101):
		_game.current_level = n
		var lvl = _scene.instantiate()
		lvl.redirect_on_block = false
		root.add_child(lvl)
		await process_frame
		if lvl.blocked:
			rejected += 1
		if lvl.player != null:
			players += 1
		lvl.queue_free()
		await process_frame
	_check(rejected == 99, "la escena rechaza los 99 niveles bloqueados (%d)" % rejected)
	_check(players == 0, "ningún nivel bloqueado llega a crear jugador (%d)" % players)
	_game.current_level = 1


func _test_unlock_flow() -> void:
	print("Desbloqueo: completar un nivel abre únicamente el siguiente")
	_reset_game()
	var lvl = await _load_level(1)
	_check(not lvl.blocked and lvl.player != null, "nivel 1 jugable en partida nueva")
	lvl.complete_level()
	await _frames(150)
	_check(_game.is_done(1) and _game.highest_unlocked() == 2, "al completar el 1 se desbloquea el 2")
	_check(not _game.is_unlocked(3) and not _game.is_unlocked(4), "el 3 y el 4 siguen bloqueados")
	_check(not _game.start_level(3), "no se puede saltar al nivel 3")
	await _free_level(lvl)
	# perder no desbloquea
	var lvl2 = await _load_level(2)
	_check(not lvl2.blocked, "nivel 2 jugable tras completar el 1")
	_game.lives = 1
	lvl2.player.die()
	await _frames(120)
	_check(lvl2.finished and not _game.is_done(2) and _game.highest_unlocked() == 2, "perder (game over) no desbloquea el siguiente")
	_game.fail_level()
	await _free_level(lvl2)
	# completar el 2 abre el 3
	var lvl3 = await _load_level(2)
	lvl3.complete_level()
	await _frames(150)
	_check(_game.highest_unlocked() == 3 and not _game.is_unlocked(4), "completar el 2 abre solo el 3")
	await _free_level(lvl3)
	# el botón "siguiente nivel" también respeta el desbloqueo
	_reset_game()
	_check(not _game.start_level(2), "tras reiniciar el progreso el 2 vuelve a bloquearse")


# ============================================ 6. persistencia y migración ====
func _test_persistence_and_migration() -> void:
	print("Persistencia y migración del guardado antiguo")
	_reset_game()
	_game.save_path = "user://smoke_persist.json"
	for i in range(1, 13):
		_mark_done(i)
	_game.levels["3"] = {"done": true, "gems": [true, false, true], "best": 4321}
	_game.worlds_done = [1]
	_game.settings["music_vol"] = 0.35
	_game.lives = 7
	_game.save_game()
	_game.levels = {}
	_game.unlocked = {1: true}
	_game.worlds_done = []
	_game.lives = 5
	_game.settings["music_vol"] = 0.8
	_game.load_game()
	_check(_game.highest_unlocked() == 13, "tras recargar siguen desbloqueados hasta el 13")
	_check(_game.get_record(3)["gems"] == [true, false, true] and int(_game.get_record(3)["best"]) == 4321, "se conservan gemas y mejor puntuación")
	_check(_game.worlds_done == [1] and _game.lives == 7, "se conservan mundos completados y vidas")
	_check(absf(float(_game.settings["music_vol"]) - 0.35) < 0.001, "se conservan los ajustes")
	# migración de un guardado v1 (20 niveles)
	var old := {
		"version": 1, "lives": 4, "score": 9000, "coins": 12, "total_coins": 300, "highest_unlocked": 9,
		"levels": {
			"1": {"done": true, "gems": [true, true, false], "best": 1500},
			"2": {"done": true, "gems": [false, false, false], "best": 1100},
			"3": {"done": true, "gems": [true, false, false], "best": 1200},
			"4": {"done": true, "gems": [false, true, false], "best": 3000},
			"5": {"done": true, "gems": [false, false, true], "best": 1300},
			"8": {"done": true, "gems": [false, false, false], "best": 2500},
		},
		"settings": {"music": false, "sfx": true, "touch": "on"},
	}
	_game.save_path = "user://smoke_migrate.json"
	var f := FileAccess.open(_game.save_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(old))
	f.close()
	_reset_game()
	_game.load_game()
	_check(_game.migrated_from_v1, "se detecta el guardado antiguo")
	_check(_game.is_done(1) and _game.is_done(2) and _game.is_done(3), "migrados los niveles 1-3 del mundo 1")
	_check(_game.is_done(10) and int(_game.get_record(10)["best"]) == 3000, "el jefe antiguo (nivel 4) pasa a ser el nivel 10")
	_check(_game.is_done(11) and _game.get_record(11)["gems"] == [false, false, true], "el nivel antiguo 5 pasa a ser el 11 con sus gemas")
	_check(_game.is_done(20) and _game.worlds_done.has(1) and _game.worlds_done.has(2), "jefes antiguos 4 y 8 -> mundos 1 y 2 completados")
	_check(_game.score == 9000 and _game.total_coins == 300, "puntuación y monedas se conservan")
	_check(_game.is_unlocked(4) and _game.is_unlocked(10) and _game.is_unlocked(11) and _game.is_unlocked(20) and _game.is_unlocked(21), "se conservan abiertos los niveles que ya tenías (1-4, 10-13, 20-21)")
	_check(_game.highest_unlocked() == 21, "el nivel abierto más alto del guardado antiguo (9 -> 21) sigue abierto (%d)" % _game.highest_unlocked())
	_check(not _game.is_unlocked(5) and not _game.is_unlocked(22), "los niveles nuevos que no habías alcanzado siguen bloqueados")
	_check(not bool(_game.settings["music"]) and str(_game.settings["touch"]) == "on", "se conservan los ajustes antiguos")
	_check(FileAccess.file_exists("user://smoke_migrate_v1_backup.json"), "se crea copia de seguridad del guardado antiguo")
	var again := FileAccess.get_file_as_string(_game.save_path)
	_check(again.contains("\"version\":2"), "el archivo queda guardado en el formato nuevo")
	_game.save_path = "user://smoke_test_save.json"
	_reset_game()


# ================================ 1,2,7,11. los 100 niveles se cargan ========
func _test_all_levels() -> void:
	print("Los 100 niveles: carga, inicio, meta, gemas, jefe y música")
	var bad: Array = []
	var no_start: Array = []
	var no_goal: Array = []
	var bad_gems: Array = []
	var bad_boss: Array = []
	var bad_music: Array = []
	var gems_total: int = 0
	for n in range(1, 101):
		var lvl = await _load_level(n)
		if lvl.blocked or lvl.player == null:
			bad.append(n)
		else:
			if lvl.spawn_pos == Vector2.ZERO:
				no_start.append(n)
			if lvl.goal == null:
				no_goal.append(n)
			if lvl._gem_counter != 3:
				bad_gems.append(n)
			gems_total += lvl._gem_counter
			var is_boss: bool = n % 10 == 0
			if is_boss != (lvl.boss != null and lvl.gate_x > 0.0):
				bad_boss.append(n)
			if lvl.player.dead or lvl.player.position.y > lvl.nrows * 16:
				bad.append(n)
			if _audio.current_music != _game.music_for_level(n):
				bad_music.append(n)
		_reset_game()
		await _free_level(lvl)
	_check(bad.is_empty(), "los 100 niveles cargan con jugador vivo (fallan: %s)" % str(bad))
	_check(no_start.is_empty(), "los 100 niveles tienen inicio (sin inicio: %s)" % str(no_start))
	_check(no_goal.is_empty(), "los 100 niveles tienen meta (sin meta: %s)" % str(no_goal))
	_check(bad_gems.is_empty() and gems_total == 300, "cada nivel tiene 3 gemas (300 en total; mal: %s)" % str(bad_gems))
	_check(bad_boss.is_empty(), "jefe y puerta solo en los niveles x0 (mal: %s)" % str(bad_boss))
	_check(bad_music.is_empty(), "cada nivel arranca con su música (mal: %s)" % str(bad_music))


# ============================================ 8. la música cambia por mundo ==
func _test_music_changes() -> void:
	print("Música por mundos, niveles alternativos, secretos y castillos")
	_audio.music_log.clear()
	var seen: Dictionary = {}
	var order: Array = []
	for n in [1, 11, 21, 31, 41, 51, 61, 71, 81, 91]:
		var lvl = await _load_level(n)
		seen[_audio.current_music] = true
		order.append(_audio.current_music)
		_reset_game()
		await _free_level(lvl)
	_check(order == ["world1", "world2", "world3", "world4", "world5", "world6", "world7", "world8", "world9", "world10"],
		"los 10 mundos tienen su canción principal distinta (%s)" % str(order))
	var alt: Array = []
	for n in [5, 15, 25, 35, 45, 55, 65, 75, 85, 95]:
		alt.append(_game.music_for_level(n))
	_check(alt == ["world1_alt", "world2_alt", "world3_alt", "world4_alt", "world5_alt", "world6_alt", "world7_alt", "world8_alt", "world9_alt", "world10_alt"],
		"los niveles 5-9 de cada mundo usan canción alternativa")
	_check(_game.music_for_level(7) == "secret" and _game.music_for_level(57) == "secret", "los niveles secretos (x7) usan música secreta")
	_check(_game.music_for_level(46) == "castle" and _game.music_for_level(49) == "castle" and _game.music_for_level(96) == "castle" and _game.music_for_level(98) == "castle", "los castillos (mundo 5 y fortaleza final) usan música de castillo")
	var distinct: Dictionary = {}
	for n in range(1, 101):
		distinct[_game.music_for_level(n)] = true
	_check(distinct.size() >= 22, "el juego usa %d canciones distintas en sus niveles" % distinct.size())
	# cambio automático al entrar en otro mundo sin recargar el juego
	_audio.play_music("world3")
	_audio.play_music(_game.music_for_level(31))
	_check(_audio.current_music == "world4", "la música cambia al pedir otro mundo")
	_game.worlds_done = []
	_game.last_reward = {}
	_check(_game.boss_music(1) == "boss" and _game.boss_music(5) == "boss_b" and _game.boss_music(8) == "boss_c" and _game.boss_music(10) == "boss_final", "cada tramo de mundos tiene su música de jefe")


# =============================================== mecánicas nuevas (6-10) ====
func _find_cell(lvl, ch: String) -> Vector2i:
	for y in range(lvl.nrows):
		var idx: int = String(lvl.rows[y]).find(ch)
		if idx != -1:
			return Vector2i(idx, y)
	return Vector2i(-1, -1)


func _level_with(world: int, ch: String) -> int:
	for i in range(1, 10):
		var n: int = (world - 1) * 10 + i
		var text: String = FileAccess.get_file_as_string(_game.level_path(n))
		for line in text.split("\n"):
			if not line.begins_with(";") and line.contains(ch):
				return n
	return -1


func _test_mechanics() -> void:
	print("Mecánicas nuevas: viento, plataformas frágiles, géiseres, barro, cintas y prensas")
	# viento
	var n: int = _level_with(6, "W")
	_check(n > 0, "el mundo 6 tiene corrientes de viento (nivel %d)" % n)
	var lvl = await _load_level(n)
	var c: Vector2i = _find_cell(lvl, "W")
	lvl.player.position = Vector2(c.x * 16 + 24, c.y * 16 + 150)
	lvl.player.velocity = Vector2.ZERO
	var y0: float = lvl.player.position.y
	await _frames(40)
	_check(lvl.player.position.y < y0 - 20.0 or lvl.player.velocity.y < 0.0, "el viento empuja al jugador hacia arriba")
	_reset_game()
	await _free_level(lvl)
	# plataforma frágil
	n = _level_with(6, "c")
	lvl = await _load_level(n)
	c = _find_cell(lvl, "c")
	var crumble = null
	for ch in lvl.get_children():
		if ch.get_script() != null and str(ch.get_script().resource_path).ends_with("crumble.gd") and absf(ch.position.x - (c.x * 16 + 8)) < 1.0 and absf(ch.position.y - (c.y * 16 + 8)) < 1.0:
			crumble = ch
	_check(crumble != null, "se crea la plataforma frágil del mapa")
	lvl.player.position = Vector2(c.x * 16 + 8, c.y * 16 - 14)
	lvl.player.velocity = Vector2.ZERO
	await _frames(90)
	_check(crumble != null and crumble._state == "fallen", "la plataforma frágil cae tras pisarla (estado: %s)" % (crumble._state if crumble != null else "-"))
	await _frames(200)
	_check(crumble != null and crumble._state == "idle", "la plataforma frágil reaparece")
	_reset_game()
	await _free_level(lvl)
	# géiser
	n = _level_with(7, "g")
	lvl = await _load_level(n)
	c = _find_cell(lvl, "g")
	var gey = null
	for ch2 in lvl.get_children():
		if ch2.get_script() != null and str(ch2.get_script().resource_path).ends_with("geyser.gd") and absf(ch2.position.x - (c.x * 16 + 8)) < 1.0:
			gey = ch2
	_check(gey != null, "se crea el géiser")
	lvl.player.position = Vector2(c.x * 16 + 8, c.y * 16 - 40)
	lvl.player.celebrate()
	var erupted: bool = false
	var idle: bool = false
	for i in range(60 * 5):
		await physics_frame
		if gey != null:
			if gey._state == "erupt" and not gey._shape.disabled:
				erupted = true
			if gey._state == "idle" and gey._shape.disabled:
				idle = true
	_check(erupted and idle, "el géiser alterna reposo y erupción")
	_reset_game()
	await _free_level(lvl)
	# barro, cintas y prensas (mundo 8, 9)
	n = _level_with(8, "~")
	lvl = await _load_level(n)
	c = _find_cell(lvl, "~")
	lvl.player.position = Vector2(c.x * 16 + 8, c.y * 16 - 12)
	lvl.player.velocity = Vector2.ZERO
	var slow_seen: bool = false
	for i in range(30):
		await physics_frame
		if lvl._mud_area.get_overlapping_bodies().has(lvl.player):
			slow_seen = true
	_check(slow_seen, "el barro detecta al jugador (le frena)")
	_reset_game()
	await _free_level(lvl)
	n = _level_with(9, ">")
	lvl = await _load_level(n)
	c = _find_cell(lvl, ">")
	lvl.player.position = Vector2(c.x * 16 + 24, c.y * 16 - 12)
	lvl.player.velocity = Vector2.ZERO
	await _frames(10)
	var x0: float = lvl.player.position.x
	await _frames(40)
	_check(lvl.player.position.x > x0 + 15.0, "la cinta transportadora '>' arrastra al jugador (%.1f px)" % (lvl.player.position.x - x0))
	_reset_game()
	await _free_level(lvl)
	n = _level_with(9, "p")
	lvl = await _load_level(n)
	c = _find_cell(lvl, "p")
	var cru = null
	for ch3 in lvl.get_children():
		if ch3.get_script() != null and str(ch3.get_script().resource_path).ends_with("crusher.gd") and absf(ch3.position.x - (c.x * 16 + 8)) < 1.0:
			cru = ch3
	_check(cru != null, "se crea la prensa")
	lvl.player.position = Vector2(c.x * 16 + 8, c.y * 16 + 40)
	lvl.player.celebrate()
	var max_drop: float = 0.0
	for i in range(60 * 4):
		await physics_frame
		if cru != null:
			max_drop = maxf(max_drop, cru._drop)
	_check(max_drop > 30.0, "la prensa baja y sube (caída máxima %.0f px)" % max_drop)
	_reset_game()
	await _free_level(lvl)


# ================================================= enemigos y proyectiles ====
func _test_entities() -> void:
	print("Enemigos y proyectiles de los 10 mundos")
	var EnemyScene: PackedScene = load("res://enemies/enemy.tscn")
	var ProjScene: PackedScene = load("res://items/projectile.tscn")
	for w in range(1, 11):
		var lvl = await _load_level((w - 1) * 10 + 1)
		for kind in ["walker", "spiky", "jumper", "flyer", "shooter"]:
			var e = EnemyScene.instantiate()
			e.kind = kind
			e.world = w
			e.level = lvl
			e.position = lvl.player.position + Vector2(60, 0)
			lvl.add_child(e)
			await _frames(40)
			e.take_hit("ice")
			await _frames(5)
			e.take_hit("spark")
			await _frames(20)
		for team in ["player", "enemy"]:
			for k in ["spark", "ice", "shard", "orb", "snowball", "acorn", "wave", "sand", "fire", "bolt", "thorn", "gear", "void", "feather"]:
				var p = ProjScene.instantiate()
				p.team = team
				p.kind = k
				p.velocity = Vector2(80, -20)
				p.fall_accel = 200.0
				p.bounce = k == "spark"
				p.position = lvl.player.position + Vector2(20, -10)
				lvl.add_child(p)
		await _frames(60)
		_check(is_instance_valid(lvl.player), "mundo %d: 5 enemigos y 14 proyectiles sin fallos" % w)
		_reset_game()
		await _free_level(lvl)


func _test_powers() -> void:
	print("Poderes (uno por mundo)")
	for w in range(1, 11):
		var lvl = await _load_level((w - 1) * 10 + 1)
		var p = lvl.player
		_check(p.power == _game.POWERS[w - 1], "mundo %d: poder %s" % [w, p.power])
		p.skill_cd = 0.0
		Input.action_press("skill")
		await _frames(3)
		Input.action_release("skill")
		_check(p.skill_cd > 0.0 or p.shield_t > 0.0, "mundo %d: el poder se activó" % w)
		await _frames(30)
		Input.action_press("jump")
		await _frames(4)
		Input.action_release("jump")
		await _frames(6)
		Input.action_press("jump")
		await _frames(3)
		Input.action_release("jump")
		await _frames(40)
		_reset_game()
		await _free_level(lvl)


# ===================================================== 9. los 10 jefes ======
func _test_bosses() -> void:
	print("Los 10 jefes (combate completo, música y recompensa)")
	for w in range(1, 11):
		var n: int = w * 10
		_reset_game()
		var lvl = await _load_level(n)
		var b = lvl.boss
		_check(b != null and b.world == w, "nivel %d: jefe del mundo %d (%s)" % [n, w, _game.BOSS_NAMES[w - 1]])
		lvl.player.position = Vector2(lvl.gate_x + 8.0, lvl.boss_home_y)
		lvl.player.camera.reset_smoothing()
		lvl.player.celebrate()  # invulnerable: solo probamos los ataques del jefe
		await _frames(30)
		_check(lvl.fight_started and b.active, "nivel %d: el combate empieza al cruzar la puerta" % n)
		_check(_audio.current_music == _game.boss_music(w), "nivel %d: suena la música de jefe (%s)" % [n, _audio.current_music])
		var seen: Dictionary = {}
		for i in range(60 * 10):
			seen[b.mode] = true
			await physics_frame
		_check(seen.size() >= 3, "nivel %d: el jefe encadena ataques (%s)" % [n, str(seen.keys())])
		var hits: int = 0
		while not b.dead and hits < 40:
			b._invuln_t = 0.0
			b.shielded = false
			b.hit_boss(1)
			hits += 1
			await _frames(2)
		_check(b.dead, "nivel %d: el jefe muere tras %d golpes" % [n, hits])
		await _frames(100)
		_check(_audio.current_music == "victory_world", "nivel %d: suena la música de victoria de mundo" % n)
		_check(lvl.goal != null and lvl.goal.active, "nivel %d: la meta aparece" % n)
		var lives_before: int = _game.lives
		lvl.complete_level()
		await _frames(150)
		_check(lvl.finished and _game.is_done(n), "nivel %d: completado y guardado" % n)
		_check(_game.worlds_done.has(w) and _game.lives == lives_before + _game.WORLD_REWARD_LIVES, "mundo %d completado: recompensa entregada una vez" % w)
		await _free_level(lvl)
	_reset_game()


# ================================================ pausa, bloques, muerte =====
func _test_flow() -> void:
	print("Pausa, bloques, muerte, game over y música de derrota")
	var lvl = await _load_level(1)
	lvl.toggle_pause()
	await _frames(3)
	_check(paused, "pausa activa")
	lvl.toggle_pause()
	await _frames(3)
	_check(not paused, "pausa se quita")
	var BlockScene: PackedScene = load("res://items/block.tscn")
	for kind in ["brick", "question", "heart", "hidden_life", "hidden_coins"]:
		var b = BlockScene.instantiate()
		b.kind = kind
		b.tileset = lvl._tileset
		b.level = lvl
		b.position = lvl.player.position + Vector2(0, -60)
		lvl.add_child(b)
		await _frames(3)
		b.bump(lvl.player)
		await _frames(20)
	lvl.player.die()
	await _frames(120)
	_check(not lvl.player.dead, "reaparece tras morir")
	_game.lives = 1
	lvl.player.die()
	await _frames(120)
	_check(lvl.finished, "game over cuando no quedan vidas")
	_check(_audio.current_music == "defeat", "suena la música de derrota")
	await _free_level(lvl)
	_reset_game()


func _test_menus() -> void:
	print("Menús: título, mapa de 100 niveles con distintos estados y final")
	for path in ["res://ui/title.tscn", "res://ui/level_select.tscn", "res://ui/ending.tscn"]:
		for state in ["nuevo", "avanzado"]:
			_reset_game()
			if state == "avanzado":
				for i in range(1, 36):
					_mark_done(i)
					_game.levels[str(i)] = {"done": true, "gems": [true, false, i % 2 == 0], "best": 1000 + i}
				_game.worlds_done = [1, 2, 3]
			var sc: PackedScene = load(path)
			var node = sc.instantiate()
			root.add_child(node)
			await process_frame
			await _frames(15)
			_check(is_instance_valid(node), "%s (%s)" % [path, state])
			if path == "res://ui/level_select.tscn":
				var expected_world: int = _game.world_of(_game.highest_unlocked())
				_check(node._world == expected_world, "el mapa abre en el mundo del nivel disponible (%d)" % expected_world)
				_check(node._grid.get_child_count() == 10, "el mapa muestra los 10 niveles del mundo")
				_check(node._chips.get_child_count() == 10, "el mapa muestra las 10 fichas de mundo")
				# pulsar un nivel bloqueado no entra
				var before: int = _game.current_level
				node._start(_game.highest_unlocked() + 1)
				_check(_game.current_level == before, "pulsar un nivel bloqueado no lo abre")
			node.queue_free()
			await process_frame
	_reset_game()


func _bot_level_one() -> void:
	print("Bot en el nivel 1 (8 s)")
	var lvl = await _load_level(1)
	var start_x: float = lvl.player.position.x
	Input.action_press("move_right")
	for frame in range(60 * 8):
		if frame % 40 == 0:
			Input.action_press("jump")
		elif frame % 40 == 6:
			Input.action_release("jump")
		await physics_frame
	Input.action_release("move_right")
	Input.action_release("jump")
	_check(lvl.player.position.x > start_x + 60.0 or lvl.player.dead, "el jugador avanza o muere (x: %d -> %d)" % [start_x, lvl.player.position.x])
	await _free_level(lvl)
