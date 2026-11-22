extends SceneTree

const PropsData := preload("res://levels/props_data.gd")
const AmbientData := preload("res://levels/ambient_data.gd")
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
var _prog
var _audio
var _ads
var _ww


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
	_prog = root.get_node("Progress")
	_ads = root.get_node("Ads")
	_ww = root.get_node("WW")
	_ww.save_path = "user://smoke_ww_save.json"
	_game.save_path = "user://smoke_test_save.json"
	_reset_game()
	_scene = load("res://levels/level.tscn")
	_check(_scene != null, "level.tscn carga")

	if OS.get_cmdline_user_args().has("--ww"):
		await _test_ww_base()
		print("RESULTADO: %s" % ("TODO OK" if _failed == 0 else "%d fallos" % _failed))
		quit(0 if _failed == 0 else 1)
		return

	if OS.get_cmdline_user_args().has("--fireball"):
		await _test_fireball_pulse()
		print("RESULTADO: %s" % ("TODO OK" if _failed == 0 else "%d fallos" % _failed))
		quit(0 if _failed == 0 else 1)
		return

	if OS.get_cmdline_user_args().has("--ads"):
		await _test_ads()
		print("RESULTADO: %s" % ("TODO OK" if _failed == 0 else "%d fallos" % _failed))
		quit(0 if _failed == 0 else 1)
		return

	if OS.get_cmdline_user_args().has("--title"):
		await _test_title_menu()
		print("RESULTADO: %s" % ("TODO OK" if _failed == 0 else "%d fallos" % _failed))
		quit(0 if _failed == 0 else 1)
		return

	if OS.get_cmdline_user_args().has("--exp2"):
		await _test_secret_variants()
		await _test_vehicles()
		await _test_modes()
		await _test_extras_ui()
		print("RESULTADO: %s" % ("TODO OK" if _failed == 0 else "%d fallos" % _failed))
		quit(0 if _failed == 0 else 1)
		return

	if OS.get_cmdline_user_args().has("--exp"):
		# ejecución rápida solo de la expansión: godot --headless --script res://tests/smoke_test.gd -- --exp
		await _test_expansion()
		print("RESULTADO: %s" % ("TODO OK" if _failed == 0 else "%d fallos" % _failed))
		quit(0 if _failed == 0 else 1)
		return

	if OS.get_cmdline_user_args().has("--golem"):
		# ejecución rápida solo del combate contra el Golem: godot --headless --script res://tests/smoke_test.gd -- --golem
		await _test_golem_combat()
		print("RESULTADO: %s" % ("TODO OK" if _failed == 0 else "%d fallos" % _failed))
		quit(0 if _failed == 0 else 1)
		return

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
	await _test_fireball_pulse()
	await _test_bosses()
	await _test_golem_combat()
	await _test_expansion()
	await _test_secret_variants()
	await _test_vehicles()
	await _test_modes()
	await _test_extras_ui()
	await _test_title_menu()
	await _test_ads()
	await _test_ww_base()
	await _test_flow()
	await _test_touch_controls()
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
		var files: Array = ["res://assets/tiles/tiles_w%d.png" % w, "res://assets/tiles/mplatform_w%d.png" % w,
				"res://assets/decor/decor_w%d.png" % w, "res://assets/decor/props_w%d.png" % w, "res://assets/enemies/enemies_w%d.png" % w,
				"res://assets/bosses/boss_%d.png" % w]
		for z in range(4):
			for nm in ["far", "mid", "near"]:
				files.append("res://assets/backgrounds/bg_w%d_z%d_%s.png" % [w, z, nm])
		for p in files:
			if not ResourceLoader.exists(p) or load(p) == null:
				ok = false
				print("    falta: ", p)
		var tex: Texture2D = load("res://assets/tiles/tiles_w%d.png" % w)
		if tex == null or tex.get_width() < 26 * 16:
			ok = false
			print("    tiles_w%d.png no incluye líquido/cascada/pared de fondo" % w)
		var atlas: Texture2D = load("res://assets/decor/props_w%d.png" % w)
		var rects: Array = PropsData.PROPS.get(w, [])
		if rects.size() != 9:
			ok = false
			print("    props_data.gd: el mundo %d no tiene 9 elementos" % w)
		else:
			for r in rects:
				if atlas == null or int(r[0]) + int(r[2]) * int(r[4]) > atlas.get_width() or int(r[3]) > atlas.get_height():
					ok = false
					print("    atrezo fuera del atlas en el mundo %d: %s" % [w, str(r)])
		for z in range(4):
			var amb: Dictionary = AmbientData.for_level(w, z, 1 + z * 3)
			if int(amb["particle_total"]) > AmbientData.MAX_PARTICLES:
				ok = false
				print("    demasiadas partículas en mundo %d zona %d: %d" % [w, z, int(amb["particle_total"])])
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
	_check(again.contains("\"version\":3") and again.contains("\"unlocked\""), "el archivo queda guardado en el formato nuevo (v3, con niveles abiertos)")
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


# ============================ 9b. Golem de Cristal (2-10): pisotón, poder, invulnerabilidad ======
func _away(p, b) -> void:
	## Aparta al jugador del jefe (si no, el rebote lo devuelve encima y encadena otro pisotón legítimo).
	p.global_position = b.global_position + Vector2(-110.0, 8.0)
	p.velocity = Vector2.ZERO


func _stomp(p, b) -> void:
	## El jugador cae desde arriba sobre la cabeza del jefe.
	p.global_position = b.global_position + Vector2(0, -36)
	p.velocity = Vector2(0, 240)
	await _frames(5)


func _test_golem_combat() -> void:
	print("Golem de Cristal (nivel 20): un pisotón = un golpe, sin daño al jugador, poder, invulnerabilidad y derrota")
	var expected_hp: Array = [5, 6, 7, 8, 10, 11, 12, 13, 14, 16]
	var BossScript = load("res://enemies/boss.gd")
	var ProjScene: PackedScene = load("res://items/projectile.tscn")
	var hp_ok: bool = true
	for w in range(1, 11):
		if int(BossScript.CONFIG[w]["hp"]) != int(expected_hp[w - 1]):
			hp_ok = false
	_check(hp_ok, "la vida de los 10 jefes no ha cambiado (%s)" % str(expected_hp))
	_reset_game()
	var lvl = await _load_level(20)
	var b = lvl.boss
	var p = lvl.player
	p.position = Vector2(lvl.gate_x + 8.0, lvl.boss_home_y)
	p.camera.reset_smoothing()
	await _frames(30)
	_check(lvl.fight_started and b.active, "el combate empieza")
	var max_hp: int = b.max_hp
	_check(b.world == 2 and max_hp == 6, "Golem de Cristal con su vida original (%d)" % max_hp)
	# se detiene su IA para medir con precisión cada golpe
	b._gen += 1
	await _frames(5)
	b.mode = "idle"
	b.shielded = false
	b._invuln_t = 0.0
	p._invuln_t = 0.0
	var hp0: int = p.hp
	var hits: int = 0
	# 1) pisotón
	await _stomp(p, b)
	hits += 1
	_check(b.hp == max_hp - 1, "el pisotón quita exactamente 1 de %d al jefe (le quedan %d)" % [max_hp, b.hp])
	_check(p.hp == hp0, "el jugador NO pierde corazones por pisar al jefe (%d -> %d)" % [hp0, p.hp])
	_check(p.velocity.y < 0.0 or p.global_position.y < b.global_position.y - 20.0, "el jugador rebota hacia arriba")
	await _frames(40)
	_check(p.hp == hp0 and b.hp == max_hp - 1, "un solo salto cuenta como un solo golpe (sin daño posterior al jugador)")
	# 2) otro pisotón mientras el jefe aún es invulnerable: rebote sin daño para nadie
	await _stomp(p, b)
	_check(b.hp == max_hp - 1 and p.hp == hp0, "pisar con el jefe invulnerable no lo daña ni daña al jugador")
	_away(p, b)
	await _frames(70)
	# 3) pisotones repetidos: no muere con 2 ni 3 saltos
	await _stomp(p, b)
	hits += 1
	_away(p, b)
	await _frames(70)
	await _stomp(p, b)
	hits += 1
	_check(b.hp == max_hp - 3 and not b.dead, "tras 3 saltos el jefe sigue vivo con %d de %d" % [b.hp, max_hp])
	_check(p.hp == hp0, "tres pisotones sin perder vida")
	_away(p, b)
	await _frames(70)
	# 4) contacto lateral: sí quita un corazón, solo uno, y da invulnerabilidad breve
	var boss_hp_before: int = b.hp
	p.global_position = b.global_position + Vector2(-27.0, 8.0)
	p.velocity = Vector2.ZERO
	await _frames(4)
	_check(p.hp == hp0 - 1, "el contacto lateral quita un corazón (%d -> %d)" % [hp0, p.hp])
	_check(b.hp == boss_hp_before, "y no daña al jefe")
	p.global_position = b.global_position + Vector2(-27.0, 8.0)
	await _frames(10)
	_check(p.hp == hp0 - 1 and p._invuln_t > 0.0, "invulnerabilidad breve: no pierde varios corazones seguidos")
	# un ataque del jefe también daña (proyectil enemigo)
	await _frames(110)
	p.global_position = b.global_position + Vector2(-90.0, 8.0)
	p.velocity = Vector2.ZERO
	await _frames(5)
	var shot = ProjScene.instantiate()
	shot.team = "enemy"
	shot.kind = "shard"
	shot.velocity = Vector2.ZERO
	shot.position = p.position
	lvl.add_child(shot)
	await _frames(5)
	_check(p.hp == hp0 - 2, "un ataque del jefe también quita vida (%d)" % p.hp)
	_check(b.hp == boss_hp_before, "el ataque lateral tampoco daña al jefe (%d)" % b.hp)
	await _frames(110)
	_check(b.hp == boss_hp_before, "el jefe conserva su vida mientras el jugador espera (%d)" % b.hp)
	p.hp = hp0
	# 5) habilidad especial real (Impulso de Cristal) contra el jefe vulnerable
	_check(p.power == "dash", "el poder del mundo 2 es el Impulso de Cristal")
	b._invuln_t = 0.0
	boss_hp_before = b.hp
	p.global_position = b.global_position + Vector2(-70.0, 8.0)
	p.velocity = Vector2.ZERO
	p.facing = 1
	p.skill_cd = 0.0
	await _frames(3)
	Input.action_press("skill")
	await _frames(3)
	Input.action_release("skill")
	_check(p.skill_cd > 0.5, "la habilidad tiene tiempo de reutilización (%.2f s)" % p.skill_cd)
	await _frames(40)
	hits += 1
	_check(b.hp == boss_hp_before - 1, "el Impulso de Cristal daña al Golem exactamente 1 (%d -> %d)" % [boss_hp_before, b.hp])
	_away(p, b)
	await _frames(70)
	# 6) un proyectil del jugador respeta el escudo del jefe y lo daña cuando es vulnerable
	b.shielded = true
	b._invuln_t = 0.0
	var before_shield: int = b.hp
	var sp = ProjScene.instantiate()
	sp.team = "player"
	sp.kind = "spark"
	sp.velocity = Vector2(300.0, 0.0)
	sp.position = b.position + Vector2(-40.0, 4.0)
	lvl.add_child(sp)
	await _frames(25)
	_check(b.hp == before_shield, "con el escudo activo el proyectil se registra pero no daña")
	b.shielded = false
	var sp2 = ProjScene.instantiate()
	sp2.team = "player"
	sp2.kind = "spark"
	sp2.velocity = Vector2(300.0, 0.0)
	sp2.position = b.position + Vector2(-40.0, 4.0)
	lvl.add_child(sp2)
	await _frames(25)
	hits += 1
	_check(b.hp == before_shield - 1, "sin escudo el proyectil daña al Golem exactamente 1 (%d -> %d)" % [before_shield, b.hp])
	# 7) derrota con el último punto de vida
	_check(not b.dead and b.hp == 1, "el jefe llega a su último punto de vida (%d)" % b.hp)
	_away(p, b)
	await _frames(70)
	await _stomp(p, b)
	hits += 1
	_check(b.dead, "el Golem es derrotado tras %d golpes en total (su vida es %d)" % [hits, max_hp])
	_check(hits == max_hp, "hacen falta exactamente tantos golpes como puntos de vida")
	await _frames(100)
	_check(_audio.current_music == "victory_world", "suena la música de victoria")
	_check(lvl.goal != null and lvl.goal.active, "aparece la meta")
	lvl.complete_level()
	await _frames(150)
	_check(lvl.finished and _game.is_done(20), "nivel 20 completado y guardado")
	_check(_game.is_unlocked(21), "el nivel siguiente (21) queda desbloqueado")
	await _free_level(lvl)
	_reset_game()


# ===================== EXPANSIÓN: guardado, cofres, secretos, poderes temporales, personalización ======
func _cell_nth(lvl, ch: String, nth: int = 0) -> Vector2i:
	var k: int = 0
	for y in range(lvl.nrows):
		for x in range(lvl.cols):
			if lvl._cell(x, y) == ch:
				if k == nth:
					return Vector2i(x, y)
				k += 1
	return Vector2i(-1, -1)


func _test_expansion() -> void:
	print("Expansión: guardado, cofres, habitaciones secretas, poderes temporales y personalización")
	_reset_game()
	_prog.reset_all()
	# --- guardado: la clave "ext" se escribe y se recupera; una partida anterior sin "ext" sigue intacta
	_mark_done(1)
	_mark_done(2)
	_game.total_coins = 77
	_prog.special_gems = 3
	_prog.unlock_cosmetic("hat", "corona")
	_prog.equip("hat", "corona")
	_prog.secrets["5:0"] = true
	_prog.stats["deaths"] = 4
	_game.save_game()
	var text: String = FileAccess.get_file_as_string(_game.save_path)
	var d: Dictionary = JSON.parse_string(text)
	_check(d.has("ext") and d.has("levels") and d.has("unlocked") and int(d["version"]) == 3, "el guardado añade «ext» sin cambiar la versión ni los datos anteriores")
	_prog.reset_all()
	_game.load_game()
	_check(_prog.special_gems == 3 and _prog.has_cosmetic("hat", "corona") and _prog.equipped["hat"] == "corona" and _prog.secrets.has("5:0") and int(_prog.stats["deaths"]) == 4, "tras cerrar y abrir se conservan cosméticos, secretos, gemas y estadísticas")
	_check(_game.is_done(1) and _game.is_done(2) and _game.total_coins == 77, "y lo de antes (niveles, monedas) sigue igual")
	# partida de la versión anterior (sin «ext»)
	var old: Dictionary = d.duplicate(true)
	old.erase("ext")
	var f := FileAccess.open(_game.save_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(old))
	f.close()
	_game.load_game()
	_check(_game.is_done(1) and _game.is_done(2) and _prog.special_gems == 0 and _prog.has_cosmetic("suit", "classic"), "una partida sin «ext» carga con todo lo anterior y la expansión vacía")
	_reset_game()
	_prog.reset_all()

	# --- cofres y habitaciones secretas en el nivel 1
	var lvl = await _load_level(1)
	var p = lvl.player
	var c: Vector2i = _cell_nth(lvl, "N")
	var kind_char: String = "N"
	if c.x < 0:
		c = _cell_nth(lvl, "R")
		kind_char = "R"
	_check(c.x >= 0, "el nivel 1 tiene un cofre visible")
	var coins0: int = _game.total_coins
	p.global_position = Vector2(c.x * 16 + 8, c.y * 16 + 4)
	p.velocity = Vector2.ZERO
	await _frames(8)
	_check(_prog.chest_opened(1, 0), "el jugador abre el cofre al tocarlo")
	_check(_game.total_coins > coins0, "el cofre da monedas (%d -> %d)" % [coins0, _game.total_coins])
	var coins1: int = _game.total_coins
	p.global_position = Vector2(c.x * 16 + 8, c.y * 16 + 4)
	await _frames(10)
	_check(_game.total_coins == coins1 and int(_prog.stats["chests"]) == 1, "un cofre abierto no vuelve a dar botín")
	_game.save_game()
	_check(_prog.treasures.has("1:0"), "el tesoro se guarda por nivel y número")
	# pared falsa / trampilla: se atraviesa y queda descubierta
	var y_cell: Vector2i = _cell_nth(lvl, "Y")
	_check(y_cell.x >= 0, "el nivel 1 tiene una habitación secreta (pared falsa o trampilla)")
	var before: int = int(_prog.stats["secrets"])
	p.global_position = Vector2(y_cell.x * 16 + 8, y_cell.y * 16 + 6)
	p.velocity = Vector2.ZERO
	await _frames(6)
	_check(int(_prog.stats["secrets"]) == before + 1, "al atravesar la pared falsa se descubre el secreto")
	await _frames(40)
	var kinds_ok: bool = true
	for ch in ["N", "R", "E", "Z"]:
		var cc: Vector2i = _cell_nth(lvl, ch)
		if cc.x >= 0 and (lvl.get_children().filter(func(n): return n.get_script() != null and str(n.get_script().resource_path).ends_with("chest.gd")).size() == 0):
			kinds_ok = false
	_check(kinds_ok, "los cofres del nivel se han creado")
	await _free_level(lvl)
	# recargar: el cofre sigue abierto
	lvl = await _load_level(1)
	var chests: Array = lvl.get_children().filter(func(n): return n.get_script() != null and str(n.get_script().resource_path).ends_with("chest.gd"))
	var open_count: int = 0
	for ch2 in chests:
		if ch2.opened:
			open_count += 1
	_check(open_count >= 1, "al volver a entrar el cofre ya aparece abierto")
	p = lvl.player

	# --- poderes temporales
	p.hp = p.max_hp
	p._invuln_t = 0.0
	p.grant_power("barrier")
	_check(p.barrier, "escudo protector activo")
	var hp_a: int = p.hp
	p.hurt(1, p.global_position.x + 10.0)
	_check(p.hp == hp_a and not p.barrier, "el escudo protector resiste un golpe")
	await _frames(70)
	p._invuln_t = 0.0
	p.hurt(1, p.global_position.x + 10.0)
	_check(p.hp == hp_a - 1, "tras romperse, el siguiente golpe sí quita vida")
	await _frames(110)
	p.grant_power("giant")
	_check(p.is_giant() and p.scale_mul > 1.4 and p._sprite.scale.x > 1.4, "la transformación gigante aumenta el tamaño")
	var cap := p._shape.shape as CapsuleShape2D
	_check(cap.height > 28.0, "y también su colisión (%.0f)" % cap.height)
	p.giant_t = 0.05
	await _frames(10)
	_check(not p.is_giant() and p.scale_mul == 1.0, "el gigante termina y vuelve al tamaño normal")
	p.grant_power("flame")
	_check(p.power == "flame" and p.temp_power_t > 20.0, "el poder de fuego sustituye al del botón")
	p.skill_cd = 0.0
	var n_proj: int = lvl.get_children().filter(func(n): return n is Area2D and n.get("team") == "player").size()
	Input.action_press("skill")
	await _frames(3)
	Input.action_release("skill")
	var n_proj2: int = lvl.get_children().filter(func(n): return n is Area2D and n.get("team") == "player").size()
	_check(n_proj2 > n_proj, "lanza bolas de fuego")
	p.temp_power_t = 0.05
	await _frames(8)
	_check(p.power == p.base_power, "el poder temporal termina y se recupera el original")
	p.grant_power("freeze")
	_check(p.power == "freeze", "poder de hielo")
	p.grant_power("pulse")
	_check(p.power == "pulse", "poder eléctrico")
	await _free_level(lvl)

	# --- personalización
	_prog.unlock_cosmetic("suit", "fuego")
	_prog.unlock_cosmetic("hat", "mago")
	_prog.unlock_cosmetic("armor", "oro")
	_prog.unlock_cosmetic("trail", "chispas")
	_prog.equip("suit", "fuego")
	_prog.equip("hat", "mago")
	_prog.equip("armor", "oro")
	_prog.equip("trail", "chispas")
	lvl = await _load_level(1)
	p = lvl.player
	_check(p._sprite.material != null and p._hat != null and p._armor != null and p._trail != null, "traje, sombrero, armadura y efecto se aplican a Wilmen")
	await _frames(10)
	_check(not _prog.equip("hat", "corona"), "no se puede equipar lo que no se ha desbloqueado")
	await _free_level(lvl)
	_prog.reset_all()
	_reset_game()


# ============== EXPANSIÓN 2: vehículos, persecuciones, modos de juego y pantallas de extras ==========
func _level_having(ch: String, world_pred: Callable = Callable()) -> int:
	for n in range(1, 101):
		if world_pred.is_valid() and not world_pred.call(_game.world_of(n)):
			continue
		var f := FileAccess.open(_game.level_path(n), FileAccess.READ)
		var txt: String = f.get_as_text()
		f.close()
		var body: String = ""
		for line in txt.split("\n"):
			if not String(line).begins_with(";"):
				body += line
		if body.contains(ch):
			return n
	return -1


func _vehicles_of(lvl) -> Array:
	return lvl.get_children().filter(func(n): return n.get_script() != null and str(n.get_script().resource_path).ends_with("vehicle.gd"))


func _test_vehicles() -> void:
	print("Vehículos y persecuciones")
	for kind in ["cart", "boat", "flyer", "mech"]:
		_reset_game()
		_prog.reset_all()
		var n: int = _level_having("V", func(w): return _prog.WORLD_VEHICLES[w] == kind)
		_check(n > 0, "hay un nivel con %s (nivel %d)" % [kind, n])
		if n < 0:
			continue
		var lvl = await _load_level(n)
		var p = lvl.player
		var vs: Array = _vehicles_of(lvl)
		_check(vs.size() >= 1 and vs[0].kind == kind, "%s: el vehículo se crea" % kind)
		var v = vs[0]
		_check(v.end_x < INF, "%s: tiene estación de llegada (x=%d)" % [kind, int(v.end_x)])
		p.global_position = v.global_position + Vector2(0, -6)
		p.velocity = Vector2.ZERO
		await _frames(8)
		_check(p.vehicle == v, "%s: Wilmen sube al tocarlo" % kind)
		var x0: float = v.global_position.x
		var y0: float = v.global_position.y
		if kind == "flyer":
			Input.action_press("jump")
			await _frames(30)
			Input.action_release("jump")
			_check(v.global_position.y < y0 - 8.0, "flyer: manteniendo salto sube (%.0f px)" % (y0 - v.global_position.y))
			var y1: float = v.global_position.y
			var ymin: float = y1
			for k in range(7):
				await _frames(10)
				ymin = minf(ymin, v.global_position.y)
			_check(v.global_position.y > ymin + 6.0, "flyer: al soltar baja (%.0f px bajo su punto más alto)" % (v.global_position.y - ymin))
		elif kind == "mech":
			Input.action_press("move_right")
			await _frames(30)
			Input.action_release("move_right")
			_check(v.global_position.x > x0 + 20.0, "mech: camina (%.0f px)" % (v.global_position.x - x0))
		else:
			await _frames(40)
			_check(v.global_position.x > x0 + 30.0, "%s: avanza solo (%.0f px)" % [kind, v.global_position.x - x0])
			Input.action_press("jump")
			await _frames(6)
			Input.action_release("jump")
			_check(v.global_position.y < y0 - 2.0 or p.global_position.y < y0, "%s: el salto brinca" % kind)
		_check(p.global_position.distance_to(v.global_position) < 40.0, "%s: Wilmen va sentado en el vehículo" % kind)
		if kind == "mech":
			var hp0: int = p.hp
			p._invuln_t = 0.0
			var r1: bool = p.hurt(1, p.global_position.x + 5.0)
			_check(not r1 and p.hp == hp0 and v.armor == 2, "mech: aguanta golpes por Wilmen (armadura %d)" % v.armor)
		# bajar con el botón de poder
		await _frames(20)
		Input.action_press("skill")
		await _frames(3)
		Input.action_release("skill")
		await _frames(4)
		_check(p.vehicle == null, "%s: el botón de poder baja del vehículo" % kind)
		await _free_level(lvl)
		# llegar a la estación baja solo
		lvl = await _load_level(n)
		p = lvl.player
		v = _vehicles_of(lvl)[0]
		var end_px: float = v.end_x
		p.global_position = v.global_position + Vector2(0, -6)
		await _frames(8)
		_check(p.vehicle == v, "%s: sube otra vez" % kind)
		v.global_position.x = end_px + 1.0
		await _frames(10)
		_check(p.vehicle == null and p.global_position.x >= end_px - 2.0, "%s: al llegar a la estación baja y sigue a pie" % kind)
		await _free_level(lvl)
	# persecución
	_reset_game()
	var nc: int = _level_having("r")
	_check(nc > 0, "hay un nivel con persecución (nivel %d)" % nc)
	var lc = await _load_level(nc)
	var pc = lc.player
	var rc: Vector2i = _find_cell(lc, "r")
	pc.global_position = Vector2(rc.x * 16 + 8, rc.y * 16 + 4)
	await _frames(10)
	var chasers: Array = lc.get_children().filter(func(n2): return n2.get_script() != null and str(n2.get_script().resource_path).ends_with("chaser.gd"))
	_check(chasers.size() == 1, "al pasar por el inicio aparece el perseguidor")
	var hpc: int = pc.hp
	pc._invuln_t = 0.0
	chasers[0].global_position = pc.global_position
	await _frames(6)
	_check(pc.hp == hpc - 1, "si te alcanza pierdes un corazón (%d -> %d)" % [hpc, pc.hp])
	var xa: float = chasers[0].global_position.x
	await _frames(60)
	_check(chasers[0].global_position.x > xa - 60.0, "el perseguidor sigue avanzando")
	await _free_level(lc)
	_reset_game()


func _test_modes() -> void:
	print("Modos: contrarreloj, desafío, bonus, supervivencia y desafío de jefes")
	_reset_game()
	_prog.reset_all()
	_check(not _game.mode_allowed("time", 1) and not _game.mode_allowed("bonus", 1) and not _game.mode_allowed("survival", 1), "en una partida nueva los modos extra están bloqueados")
	_check(_game.mode_allowed("story", 1) and not _game.mode_allowed("story", 2), "la historia sigue bloqueada nivel a nivel")
	_check(not _game.start_mode("bonus", 1), "no se puede entrar a un modo bloqueado")
	# progreso normal: completar el mundo 1
	for i in range(1, 11):
		_mark_done(i)
	_game.worlds_done = [1]
	_check(_game.mode_allowed("time", 3) and _game.mode_allowed("bonus", 1) and _game.mode_allowed("bossrush", 10), "al completar el mundo 1 se abren contrarreloj, bonus y desafío de jefe")
	_check(not _game.mode_allowed("time", 11) and not _game.mode_allowed("survival", 11), "pero no los niveles aún no jugados")
	_check(not _game.mode_allowed("challenge", 3), "el modo desafío pide completar 2 mundos")
	var unlocked_before: int = _game.unlocked.size()
	# --- contrarreloj
	_check(_game.start_mode("time", 3), "contrarreloj: se puede empezar en el nivel 3")
	var lvl = await _load_level_mode(3)
	_check(lvl.mode == "time" and not lvl.blocked, "contrarreloj: el nivel carga en su modo")
	lvl.elapsed = 5.0
	lvl.complete_level()
	await _frames(150)
	_check(_prog.best_time(3) > 0.0, "contrarreloj: se guarda el mejor tiempo (%.2f s)" % _prog.best_time(3))
	_check(_game.unlocked.size() == unlocked_before, "contrarreloj no altera los niveles desbloqueados")
	await _free_level(lvl)
	# --- bonus
	_check(_game.start_mode("bonus", 1), "bonus: se abre al derrotar al jefe del mundo")
	lvl = await _load_level_mode(1)
	_check(lvl.mode == "bonus" and lvl.goal != null and _find_cell(lvl, "N").x >= 0, "bonus: nivel con meta y cofres")
	var chest_c: Vector2i = _find_cell(lvl, "N")
	var coins_b: int = _game.total_coins
	lvl.player.global_position = Vector2(chest_c.x * 16 + 8, chest_c.y * 16 + 4)
	await _frames(8)
	_check(_game.total_coins > coins_b, "bonus: los cofres dan botín")
	lvl.complete_level()
	await _frames(160)
	_check(_prog.is_done("bonus", 1), "bonus: se guarda como completado")
	_check(_game.unlocked.size() == unlocked_before and not _game.is_done(11), "bonus no toca el progreso de la historia")
	await _free_level(lvl)
	# --- desafío (pide 2 mundos)
	_game.worlds_done = [1, 2]
	for i in range(11, 21):
		_mark_done(i)
	_check(_game.start_mode("challenge", 3), "desafío: disponible con 2 mundos")
	lvl = await _load_level_mode(3)
	_check(lvl.player.hp == 1, "desafío: un solo corazón")
	lvl.player.hurt(1, lvl.player.global_position.x + 5.0)
	await _frames(100)
	_check(lvl.finished, "desafío: un solo intento (al perder el corazón termina)")
	_check(_game.lives >= 3, "desafío: no gasta vidas de la historia")
	await _free_level(lvl)
	# --- supervivencia
	_game.worlds_done = [1, 2, 3]
	for i in range(21, 31):
		_mark_done(i)
	_check(_game.start_mode("survival", 1), "supervivencia: disponible con 3 mundos")
	lvl = await _load_level_mode(1)
	await _frames(240)
	_check(lvl.survival != null and lvl.survival.wave >= 1 and lvl.survival._alive.size() >= 3, "supervivencia: aparece la primera oleada (%d enemigos)" % lvl.survival._alive.size())
	for e in lvl.survival._alive:
		if is_instance_valid(e):
			e.kill()
	await _frames(240)
	_check(lvl.survival.wave >= 2, "supervivencia: al vencer la oleada llega la siguiente (oleada %d)" % lvl.survival.wave)
	lvl.player.hp = 1
	lvl.player._invuln_t = 0.0
	lvl.player.hurt(1, lvl.player.global_position.x + 5.0)
	await _frames(110)
	_check(lvl.finished and int(_prog.records.get("survival:1", 0)) >= 1, "supervivencia: se guarda el récord de oleadas (%d)" % int(_prog.records.get("survival:1", 0)))
	await _free_level(lvl)
	# --- desafío de jefes
	_check(_game.start_mode("bossrush", 10), "desafío de jefes: disponible tras derrotar al jefe")
	lvl = await _load_level_mode(10)
	await _frames(40)
	_check(lvl.player.hp == 2 and lvl.boss != null and lvl.boss.max_hp == 5, "desafío de jefes: 2 corazones y el jefe con su vida original (%d)" % lvl.boss.max_hp)
	_check(lvl.fight_started, "desafío de jefes: el combate empieza en la arena")
	lvl.boss._invuln_t = 0.0
	lvl.boss.shielded = false
	var hits_b: int = 0
	while not lvl.boss.dead and hits_b < 20:
		lvl.boss._invuln_t = 0.0
		lvl.boss.hit_boss(1)
		hits_b += 1
		await _frames(2)
	_check(lvl.boss.dead and hits_b == 5, "desafío de jefes: el jefe sigue necesitando %d golpes" % hits_b)
	await _frames(100)
	lvl.complete_level()
	await _frames(160)
	_check(_prog.is_done("boss", 1), "desafío de jefes: recompensa registrada")
	await _free_level(lvl)
	_check(_game.unlocked.size() == unlocked_before + 0 or _game.unlocked.size() >= unlocked_before, "los modos no han quitado nada del progreso")
	_game.mode = "story"
	_reset_game()
	_prog.reset_all()


func _load_level_mode(n: int):
	## Como _load_level, pero sin tocar el modo ya fijado con Game.start_mode.
	var lvl = _scene.instantiate()
	lvl.redirect_on_block = false
	root.add_child(lvl)
	await process_frame
	await _frames(5)
	return lvl


func _test_extras_ui() -> void:
	print("Pantallas de extras: vestuario, logros, estadísticas y modos")
	_reset_game()
	_prog.reset_all()
	_game.mode = "story"
	# logros: se desbloquean con el progreso y dan cosméticos
	_check(not _prog.achievements.has("first_chest"), "al empezar no hay logros")
	_prog.open_chest(1, 99, "normal")
	_check(_prog.achievements.has("first_chest") and _prog.has_cosmetic("hat", "gorra"), "el primer cofre desbloquea un logro y su sombrero")
	_prog.stats["secrets"] = 1
	_prog.check_achievements()
	_check(_prog.achievements.has("secrets_1"), "descubrir un secreto da su logro")
	var prev: int = _prog.cosmetics_owned()
	for i in range(0, 12):
		_prog.open_chest(5, 100 + i, "special")
	_check(_prog.cosmetics_owned() > prev and _prog.special_gems >= 20, "los cofres especiales dan cosméticos y gemas (%d cosméticos)" % _prog.cosmetics_owned())
	_check(_prog.achievements.has("chests_10"), "10 cofres abiertos dan el logro «Cazatesoros»")
	# recompensa por mundo completado
	var info: Dictionary = _prog.world_completed(2)
	_check(_prog.has_cosmetic("hat", "minero"), "completar el mundo 2 da el casco de minero")
	# pantalla de extras
	var scene: PackedScene = load("res://ui/extras.tscn")
	var ex = scene.instantiate()
	root.add_child(ex)
	await _frames(5)
	for t in ["wardrobe", "achievements", "stats", "modes", "wardrobe"]:
		ex._show_tab(t)
		await _frames(4)
	ex._cat = "hat"
	ex._show_tab("wardrobe")
	await _frames(4)
	_check(ex._grid != null and ex._grid.get_child_count() >= 3, "el vestuario lista las piezas")
	ex.queue_free()
	await process_frame
	# apariencia especial por logro
	_check(not _prog.equip("skin", "dorado"), "la apariencia especial sigue bloqueada")
	_prog.unlock_cosmetic("skin", "dorado")
	_check(_prog.equip("skin", "dorado") and _prog.effective("hat") == "corona" and _prog.effective("suit") == "dorado", "la apariencia especial aporta sus piezas")
	_prog.reset_all()
	_reset_game()


func _test_secret_variants() -> void:
	print("Habitaciones secretas: puerta secreta y bóveda de ladrillos con orbe gigante")
	_reset_game()
	_prog.reset_all()
	# puerta secreta
	var nd: int = _level_having("D")
	_check(nd > 0, "hay un nivel con puerta secreta (nivel %d)" % nd)
	if nd > 0:
		var l1 = await _load_level(nd)
		var dc: Vector2i = _find_cell(l1, "D")
		var s0: int = int(_prog.stats["secrets"])
		l1.player.global_position = Vector2(dc.x * 16 + 8, dc.y * 16 + 8)
		l1.player.velocity = Vector2.ZERO
		await _frames(6)
		_check(int(_prog.stats["secrets"]) == s0 + 1, "la puerta secreta se atraviesa y cuenta como secreto")
		await _free_level(l1)
	# bóveda: ladrillos que solo rompe el gigante (o el impulso) y marcador dentro
	var nv: int = _level_having("x")
	_check(nv > 0, "hay un nivel con bóveda sellada (nivel %d)" % nv)
	if nv > 0:
		_reset_game()
		var l2 = await _load_level(nv)
		var p = l2.player
		var xc: Vector2i = _find_cell(l2, "x")
		# el orbe gigante está cerca de la pared de ladrillos
		var orbs: Array = l2.get_children().filter(func(n): return n.get_script() != null and str(n.get_script().resource_path).ends_with("orb.gd"))
		_check(orbs.size() >= 1, "hay un orbe cerca de la bóveda")
		var bricks: Array = l2.get_children().filter(func(n): return n is StaticBody2D and n.get("kind") == "brick" and absf(n.position.x - float(xc.x * 16)) < 110.0 and absf(n.position.y - float(xc.y * 16)) < 40.0)
		_check(bricks.size() >= 2, "la entrada de la bóveda son ladrillos (%d)" % bricks.size())
		var side: float = -1.0 if bricks[0].position.x > float(xc.x * 16) else 1.0
		p.global_position = Vector2(bricks[0].position.x + side * 40.0, bricks[0].position.y)
		p.velocity = Vector2.ZERO
		p.grant_power("giant")
		await _frames(4)
		Input.action_press("move_left" if side > 0.0 else "move_right")
		await _frames(70)
		Input.action_release("move_left")
		Input.action_release("move_right")
		var left_b: int = bricks.filter(func(b): return is_instance_valid(b) and not b.is_queued_for_deletion()).size()
		_check(left_b < bricks.size(), "el gigante rompe los ladrillos de la bóveda (%d -> %d)" % [bricks.size(), left_b])
		await _free_level(l2)
	_reset_game()


func _test_title_menu() -> void:
	print("Menú principal: botones reales, estadísticas, opciones y accesos")
	_reset_game()
	_mark_done(1)
	_mark_done(2)
	_game.score = 12345
	var node = load("res://ui/title.tscn").instantiate()
	root.add_child(node)
	await _frames(10)
	var texts: Array = []
	for b in node._menu.get_children():
		texts.append(b.text)
		_check(b is Button and not b.disabled and b.pressed.get_connections().size() > 0 and b.icon != null, "botón «%s»: real, activo, con icono y acción" % b.text)
	_check(texts == ["CONTINUAR", "MAPA DE NIVELES", "WILMEN WORLD", "EXTRAS", "OPCIONES", "SALIR"], "los 6 botones del diseño (con WILMEN WORLD): %s" % str(texts))
	_check(node._menu.get_child(0).has_focus(), "el primer botón recibe el foco")
	var found: Array = []
	for l in node.find_children("*", "Label", true, false):
		found.append(l.text)
	_check(found.has("Niveles 2/100") and found.has("Gemas 0/300") and found.has("Puntos 12345"), "la barra inferior muestra los datos reales (%s)" % str(found.filter(func(t): return t.begins_with("Niveles") or t.begins_with("Gemas") or t.begins_with("Puntos"))))
	_check(node.get_children().filter(func(c): return c is TextureButton).size() == 2, "botones redondos de logros y música")
	node._menu.get_child(4).pressed.emit()
	await _frames(3)
	_check(node._options != null, "OPCIONES abre el panel de opciones")
	node._close_options()
	await _frames(3)
	_check(node._options == null, "y se cierra")
	node._show_audio()
	await _frames(3)
	_check(node._options != null, "el botón de música abre el control de volumen")
	node._close_options()
	node.queue_free()
	await process_frame
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


# ============================================ 13. controles táctiles ========
func _to_window(pos: Vector2) -> Vector2:
	## Los toques reales llegan en coordenadas de ventana; el motor los pasa a lógicas con la transformación de estiramiento.
	return root.get_final_transform() * pos


func _touch(idx: int, pos: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = idx
	ev.position = _to_window(pos)
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _drag(idx: int, pos: Vector2) -> void:
	var ev := InputEventScreenDrag.new()
	ev.index = idx
	ev.position = _to_window(pos)
	Input.parse_input_event(ev)


func _test_touch_controls() -> void:
	print("Controles táctiles: multitáctil, arrastre, botón de pausa")
	_game.settings["touch"] = "on"
	var lvl = await _load_level(1)
	var hud = lvl.hud
	var btn: Dictionary = {}
	for c in hud._touch.get_children():
		btn[c.action] = c
	_check(btn.size() == 4 and btn.has("move_left") and btn.has("move_right") and btn.has("jump") and btn.has("skill"), "hay 4 botones táctiles: izquierda, derecha, salto y poder")
	var small: Array = []
	for k in btn:
		var r: Rect2 = btn[k].get_global_rect()
		if r.size.x < 60.0 or r.size.y < 60.0:
			small.append(k)
	_check(small.is_empty(), "los botones son grandes (>= 60 px lógicos de lado; pequeños: %s)" % str(small))
	var pj: Vector2 = btn["jump"].get_global_rect().get_center()
	var pr: Vector2 = btn["move_right"].get_global_rect().get_center()
	var pl: Vector2 = btn["move_left"].get_global_rect().get_center()
	var ps: Vector2 = btn["skill"].get_global_rect().get_center()
	_touch(0, pj, true)
	await _frames(2)
	_check(Input.is_action_pressed("jump"), "un dedo en SALTO pulsa la acción")
	_touch(1, pr, true)
	await _frames(2)
	_check(Input.is_action_pressed("jump") and Input.is_action_pressed("move_right"), "dos dedos a la vez: salto + derecha (multitáctil)")
	_touch(2, ps, true)
	await _frames(2)
	_check(Input.is_action_pressed("skill"), "tres dedos: también el poder")
	_touch(0, pj, false)
	await _frames(2)
	_check(not Input.is_action_pressed("jump") and Input.is_action_pressed("move_right") and Input.is_action_pressed("skill"), "soltar un dedo solo suelta su botón")
	_touch(2, ps, false)
	_drag(1, pl)  # arrastrar el dedo de derecha a izquierda
	await _frames(2)
	_check(Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"), "arrastrar el dedo cambia de derecha a izquierda")
	_touch(1, pl, false)
	await _frames(2)
	_check(not Input.is_action_pressed("move_left"), "al soltar todo no queda ninguna acción atascada")
	# el personaje responde de verdad a los botones táctiles
	var x0: float = lvl.player.position.x
	_touch(3, pr, true)
	await _frames(40)
	var moved: float = lvl.player.position.x - x0
	_touch(3, pr, false)
	await _frames(2)
	_check(moved > 25.0, "mantener DERECHA mueve a Wilmen (%.0f px)" % moved)
	var y0: float = lvl.player.position.y
	_touch(4, pj, true)
	await _frames(12)
	var rose: float = y0 - lvl.player.position.y
	_touch(4, pj, false)
	await _frames(2)
	_check(rose > 8.0, "pulsar SALTO hace saltar a Wilmen (%.0f px)" % rose)
	# botón de pausa de la interfaz
	var pause_btn = null
	for c2 in hud._root.get_children():
		if c2 is Button and (c2 as Button).text == "II":
			pause_btn = c2
	_check(pause_btn != null, "existe el botón de pausa")
	if pause_btn != null:
		pause_btn.pressed.emit()
		await _frames(3)
		_check(paused, "el botón de pausa pausa el juego")
		lvl.toggle_pause()
		await _frames(3)
		_check(not paused, "y se reanuda")
	_game.settings["touch"] = "auto"
	await _free_level(lvl)


# ===================================================== anuncios (proveedor falso) ===
const MockAds := preload("res://ads/mock_provider.gd")


func _pf(n: int) -> void:
	for i in range(n):
		await process_frame


func _until(cond: Callable, max_frames: int = 900) -> void:
	## Espera (fotogramas de proceso, como los temporizadores y las señales del juego) hasta que se cumpla la condición.
	var n: int = 0
	while not cond.call() and n < max_frames:
		await process_frame
		n += 1
	await process_frame


func _save_without_lives() -> String:
	var d: Dictionary = _game._save_dict().duplicate(true)
	d.erase("lives")
	if d.has("ext") and typeof(d["ext"]) == TYPE_DICTIONARY and d["ext"].has("stats"):
		d["ext"]["stats"].erase("play_time")  # el tiempo de juego avanza solo mientras se juega
	return JSON.stringify(d)


func _overlay_buttons(lvl) -> Array:
	var out: Array = []
	if lvl.hud._overlay != null:
		for b in lvl.hud._overlay.find_children("*", "Button", true, false):
			out.append(b)
	return out


func _button_with(lvl, text: String):
	for b in _overlay_buttons(lvl):
		if b.text == text:
			return b
	return null


func _test_ads() -> void:
	print("Anuncios recompensados (proveedor FALSO): recompensa, seguridad, interfaz y guardado intacto")
	var AdsScript = load("res://autoload/ads.gd")
	_check(AdsScript.ADS_ENABLED == false, "ADS_ENABLED es false por defecto")
	_check(_ads.provider == null and not _ads.can_offer_reward() and not _ads.active(), "sin proveedor: anuncios desactivados")
	_check(not _ads.request_reward(func(_r): pass), "desactivado: no se puede pedir un anuncio")
	_check(_ads.banner_reserved() == 0.0 and not _ads.banner_visible(), "desactivado: sin banner")
	var src: String = FileAccess.get_file_as_string("res://autoload/ads.gd") + FileAccess.get_file_as_string("res://ads/mock_provider.gd")
	_check(not src.to_lower().contains("interstitial") and not src.contains("intersticial"), "no existe ningún intersticial en el código")

	# ---- lógica de recompensa (sin nivel) ----
	_reset_game()
	var results: Array = []
	var cb := func(r): results.append(r)
	var cases := [["complete", 1, "rewarded"], ["close", 0, "closed"], ["fail", 0, "failed"], ["double", 1, "rewarded"], ["late", 1, "rewarded"]]
	for c in cases:
		_game.lives = 3
		results.clear()
		var m := MockAds.new(false)
		m.behavior = c[0]
		_ads.use_provider(m)
		var snap: String = _save_without_lives()
		_check(_ads.can_offer_reward(), "[%s] el anuncio está disponible" % c[0])
		_check(_ads.request_reward(cb), "[%s] se pide el anuncio" % c[0])
		_check(not _ads.can_offer_reward() and not _ads.request_reward(cb), "[%s] mientras hay uno en curso no se puede pedir otro" % c[0])
		await _pf(4)
		_check(_game.lives == 3 + int(c[1]), "[%s] vidas 3 -> %d (esperado +%d)" % [c[0], _game.lives, int(c[1])])
		_check(results == [c[2]], "[%s] el resultado entregado es una sola vez: %s" % [c[0], str(results)])
		if c[0] == "late":
			m.replay(_ads, "rewarded")
			m.replay(_ads, "rewarded")
			_check(_game.lives == 4, "[late] eventos repetidos posteriores no dan más vidas")
		_check(_save_without_lives() == snap, "[%s] el resto de la partida no cambia" % c[0])
		_check(not _ads.busy(), "[%s] la petición queda cerrada" % c[0])
	# anuncio sin respuesta: caduca sin recompensa
	_game.lives = 3
	results.clear()
	var ms := MockAds.new(false)
	ms.behavior = "silent"
	_ads.use_provider(ms)
	_ads.request_reward(cb)
	await _pf(3)
	_check(_ads.busy() and _game.lives == 3, "anuncio sin respuesta: sigue pendiente, sin vida")
	_ads._started_ms -= AdsScript.REQUEST_TIMEOUT_MS + 1000
	await _pf(3)
	_check(not _ads.busy() and results == ["failed"] and _game.lives == 3, "anuncio sin respuesta: caduca sin dar vida")
	ms.replay(_ads, "rewarded")
	_check(_game.lives == 3, "una recompensa tardía de una petición caducada se ignora")
	# anuncio no cargado
	var mn := MockAds.new(false)
	mn.ready = false
	_ads.use_provider(mn)
	_check(not _ads.can_offer_reward(), "anuncio no cargado: no se ofrece")
	# evento sin petición activa
	var mx := MockAds.new(false)
	_ads.use_provider(mx)
	_ads.on_ad_event(1, "rewarded")
	_ads.on_ad_event(-1, "rewarded")
	_check(_game.lives == 3, "evento de recompensa sin petición activa: se ignora")
	# el que pidió el anuncio ya no existe: la vida solo se da si el anuncio se completó
	_ads.use_provider(null)

	# ---- interfaz «Sin vidas» desactivada: no hay botón ----
	_reset_game()
	var lvl = await _load_level(1)
	_game.lives = 1
	lvl.player.die()
	await _until(func(): return lvl.finished)
	_check(lvl.finished and _game.lives == 0, "sin vidas: aparece la pantalla «Sin vidas»")
	_check(_button_with(lvl, "Ver anuncio y obtener +1 vida") == null, "anuncios desactivados: NO hay botón de anuncio")
	_check(_button_with(lvl, "Reintentar") != null and _button_with(lvl, "Mapa de niveles") != null, "se mantienen Reintentar y Mapa de niveles")
	await _free_level(lvl)

	# ---- opción A con el proveedor falso ----
	_reset_game()
	_game.lives = 1
	_game.coins = 7
	_game.score = 1234
	var mock := MockAds.new(false)
	_ads.use_provider(mock)
	lvl = await _load_level(1)
	_game.lives = 1
	_check(not _ads.banner_visible() and _ads.banner_reserved() == 0.0, "durante un nivel no hay banner")
	lvl.respawn_pos = lvl.player.position + Vector2(48, 0)  # simula un punto de control
	var cp: Vector2 = lvl.respawn_pos
	lvl.player.die()
	await _until(func(): return lvl.finished)
	_check(lvl.finished and _game.lives == 0, "opción A: sin vidas")
	var btn = _button_with(lvl, "Ver anuncio y obtener +1 vida")
	_check(btn != null and not btn.disabled, "con anuncios activos aparece «Ver anuncio y obtener +1 vida»")
	var before: String = _save_without_lives()
	var lvls_before: String = JSON.stringify(_game.levels)
	mock.behavior = "close"
	btn.pressed.emit()
	await _pf(6)
	_check(_game.lives == 0 and lvl.finished, "cerrar el anuncio antes de completarlo: 0 vidas y sigue «Sin vidas»")
	btn = _button_with(lvl, "Ver anuncio y obtener +1 vida")
	_check(btn != null and not btn.disabled, "tras cerrarlo el botón vuelve a estar disponible (voluntario, sin límite)")
	mock.behavior = "fail"
	btn.pressed.emit()
	await _pf(6)
	_check(_game.lives == 0 and lvl.finished, "anuncio que falla: 0 vidas")
	btn = _button_with(lvl, "Ver anuncio y obtener +1 vida")
	mock.behavior = "double"
	btn.pressed.emit()
	btn.pressed.emit()  # doble toque: una sola petición
	await _pf(8)
	_check(mock.shown_count == 3, "un doble toque no pide dos anuncios (anuncios mostrados: %d)" % mock.shown_count)
	_check(_game.lives == 1, "anuncio completo con callbacks repetidos: exactamente +1 vida (vidas=%d)" % _game.lives)
	_check(not lvl.finished and not lvl.player.dead, "el nivel continúa: el jugador está vivo")
	_check(lvl.player.position.distance_to(cp) < 4.0, "continúa desde el último punto de control")
	_check(_overlay_buttons(lvl).is_empty(), "la pantalla «Sin vidas» se cierra")
	_check(_game.coins == 7 and _game.score == 1234, "monedas y puntos intactos")
	_check(JSON.stringify(_game.levels) == lvls_before and _save_without_lives() == before, "progreso, gemas, estadísticas y guardado intactos (solo cambia 'lives')")
	# se puede volver a morir y ver otro anuncio: sin límite
	lvl.player.die()
	await _until(func(): return lvl.finished)
	_check(lvl.finished and _game.lives == 0 and _button_with(lvl, "Ver anuncio y obtener +1 vida") != null, "puede volver a ofrecerse el anuncio (sin límite)")
	mock.behavior = "complete"
	_button_with(lvl, "Ver anuncio y obtener +1 vida").pressed.emit()
	await _pf(8)
	_check(_game.lives == 1 and not lvl.finished, "segundo anuncio: +1 vida y continúa")
	# continue_after_ad no puede usarse fuera de «Sin vidas»
	var l0: int = _game.lives
	lvl.continue_after_ad()
	_check(_game.lives == l0 and not lvl.finished, "continue_after_ad fuera de «Sin vidas» no hace nada")
	# Reintentar sigue funcionando como siempre (vuelve a 3 vidas)
	lvl.player.die()
	await _until(func(): return lvl.finished)
	_check(lvl.finished and _button_with(lvl, "Reintentar") != null, "Reintentar sigue ahí")
	_game.fail_level()
	_check(_game.lives == 3, "Reintentar mantiene su comportamiento (3 vidas)")
	await _free_level(lvl)
	# no se reparte la recompensa si el jugador sale de la escena con el anuncio abierto
	_reset_game()
	_game.lives = 1
	var msil := MockAds.new(false)
	msil.behavior = "silent"
	_ads.use_provider(msil)
	lvl = await _load_level(1)
	_game.lives = 1
	lvl.player.die()
	await _until(func(): return lvl.finished)
	_button_with(lvl, "Ver anuncio y obtener +1 vida").pressed.emit()
	await _pf(3)
	await _free_level(lvl)
	msil.replay(_ads, "closed")
	_check(_game.lives == 0 and not _ads.busy(), "salir con el anuncio abierto y cerrarlo sin completar: sin vida y sin errores")

	# ---- banner solo en el menú ----
	_reset_game()
	var mb := MockAds.new(false)
	_ads.use_provider(mb)
	var title = load("res://ui/title.tscn").instantiate()
	root.add_child(title)
	await _pf(6)
	_check(_ads.banner_visible() and mb.banner_shown and _ads.banner_reserved() > 0.0, "menú principal: banner visible")
	var txts: Array = []
	for l in title.find_children("*", "Label", true, false):
		txts.append(l.text)
	_check(not txts.has("v2.1 - 100 niveles - sin anuncios"), "con anuncios activos el menú ya no dice «sin anuncios»")
	title.queue_free()
	await _pf(4)
	_check(not _ads.banner_visible() and not mb.banner_shown, "al salir del menú el banner se oculta")
	_ads.use_provider(null)
	title = load("res://ui/title.tscn").instantiate()
	root.add_child(title)
	await _pf(6)
	txts.clear()
	for l in title.find_children("*", "Label", true, false):
		txts.append(l.text)
	_check(not _ads.banner_visible() and txts.has("v2.1 - 100 niveles - sin anuncios"), "desactivado: sin banner y el menú sigue igual")
	title.queue_free()
	await _pf(3)
	_reset_game()


# ============================================ Pulso Eléctrico (Mundo 9): bola de fuego ===
class FakeEnemy extends Node2D:
	var dead: bool = false
	var hits: Array = []

	func take_hit(shot: String) -> void:
		hits.append(shot)


func _fireballs(lvl) -> Array:
	return lvl.get_children().filter(func(n): return n.get_script() != null and n.get_script().resource_path == "res://items/fireball.gd")


func _bolt_lines(lvl) -> int:
	return lvl.get_children().filter(func(n): return n is Line2D).size()


func _player_shots(lvl) -> int:
	return lvl.get_children().filter(func(n): return n is Area2D and n.get("team") == "player").size()


func _test_fireball_pulse() -> void:
	print("Pulso Eléctrico (Mundo 9): bola de fuego en vez de rayos; Electricidad y Fuego no cambian")
	_reset_game()
	var lvl = await _load_level(81)
	var p = lvl.player
	_check(p.base_power == "pulse" and p.power == "pulse" and p.temp_power == "", "Mundo 9: el poder base es el Pulso Eléctrico")
	_check(p.POWER_COOLDOWN["pulse"] == 1.3, "el enfriamiento sigue siendo 1.3 s")
	var tex: Texture2D = load("res://assets/items/fireball.png")
	var boom: Texture2D = load("res://assets/items/fireball_boom.png")
	_check(tex != null and tex.get_width() == 64 and boom != null and boom.get_width() == 192, "arte de la bola de fuego y la explosión cargado")
	for dir in [1, -1]:
		var label: String = "derecha" if dir == 1 else "izquierda"
		p.facing = dir
		p.skill_cd = 0.0
		p._invuln_t = 99.0
		var enemy := FakeEnemy.new()
		enemy.position = p.position + Vector2(40.0 * dir, 0.0)
		enemy.add_to_group("enemies")
		lvl.add_child(enemy)
		var before_bolts: int = _bolt_lines(lvl)
		var before_shots: int = _player_shots(lvl)
		p._use_skill()
		await process_frame
		var fbs: Array = _fireballs(lvl)
		_check(fbs.size() == 1, "[%s] sale una bola de fuego por el enemigo cercano" % label)
		_check(_bolt_lines(lvl) == before_bolts, "[%s] ya no se dibujan los rayos" % label)
		_check(_player_shots(lvl) == before_shots, "[%s] no usa los proyectiles de chispa" % label)
		_check(p.skill_cd > 1.0, "[%s] arranca el enfriamiento (%.2f s)" % [label, p.skill_cd])
		var fb = fbs[0]
		var fb_ref: WeakRef = weakref(fb)
		var start_x: float = fb.global_position.x
		_check(signf(start_x - p.global_position.x) == float(dir) or absf(start_x - p.global_position.x) < 20.0, "[%s] sale del lado del personaje que mira (x=%.1f)" % [label, start_x - p.global_position.x])
		_check(fb._ball.flip_h == (dir < 0), "[%s] la bola mira en la dirección del disparo" % label)
		await _until(func(): return enemy.hits.size() > 0 or fb_ref.get_ref() == null, 120)
		_check(enemy.hits == ["spark"], "[%s] impacta una vez con el daño de siempre %s" % [label, str(enemy.hits)])
		var fb_now = fb_ref.get_ref()
		_check(fb_now != null and fb_now.exploded and fb_now._boom != null, "[%s] se produce la explosión de fuego" % label)
		fb_now = null
		fb = null
		await _until(func(): return fb_ref.get_ref() == null, 120)
		_check(fb_ref.get_ref() == null, "[%s] la explosión termina y se limpia" % label)
		enemy.queue_free()
		# sin enemigos: sale hacia delante y estalla al llegar al alcance, sin dañar a nadie
		p.skill_cd = 0.0
		p._use_skill()
		await process_frame
		fbs = _fireballs(lvl)
		_check(fbs.size() == 1, "[%s] sin enemigos también sale una bola hacia delante" % label)
		var f2_ref: WeakRef = weakref(fbs[0])
		var x0: float = fbs[0].global_position.x
		await _frames(6)
		var f2 = f2_ref.get_ref()
		if f2 != null:
			_check(signf(f2.global_position.x - x0) == float(dir), "[%s] avanza hacia donde mira el personaje" % label)
		f2 = null
		fbs = []
		await _until(func(): return f2_ref.get_ref() == null, 180)
		_check(f2_ref.get_ref() == null, "[%s] estalla al llegar a su alcance y desaparece" % label)
	# alcance ampliado (3 veces): llega a enemigos lejanos delante, no a los que están detrás ni fuera de alcance
	var FB = load("res://items/fireball.gd")
	_check(FB.RANGE == 192.0 and FB.SPEED == 340.0 and FB.LIFE_MARGIN > 0.0, "alcance 192 px (3 x 64), velocidad 340 (antes 260) y vida suficiente para todo el vuelo")
	for real in get_nodes_in_group("enemies"):
		if not (real is FakeEnemy):
			real.queue_free()  # solo en esta prueba: los enemigos reales del nivel no deben mezclarse con las medidas
	await process_frame
	# se busca un tramo del nivel despejado a ambos lados (sin muros en 240 px) para medir el alcance en las dos direcciones
	var space: PhysicsDirectSpaceState2D = lvl.get_world_2d().direct_space_state
	var found: bool = false
	var base_y: float = p.position.y
	for sx in range(120, int(lvl.cols) * 16 - 120, 8):
		var pos := Vector2(float(sx), base_y)
		var qa := PhysicsRayQueryParameters2D.create(pos, pos + Vector2(240.0, 0.0), 1)
		var qb := PhysicsRayQueryParameters2D.create(pos, pos - Vector2(240.0, 0.0), 1)
		var qd := PhysicsRayQueryParameters2D.create(pos, pos + Vector2(0.0, 24.0), 1)
		var qu := PhysicsRayQueryParameters2D.create(pos, pos - Vector2(0.0, 24.0), 1)
		if space.intersect_ray(qa).is_empty() and space.intersect_ray(qb).is_empty() and not space.intersect_ray(qd).is_empty() and space.intersect_ray(qu).is_empty():
			p.position = pos
			found = true
			break
	_check(found, "hay un tramo despejado en el nivel para medir el alcance")
	p.velocity = Vector2.ZERO
	await _until(func(): return _fireballs(lvl).is_empty(), 300)
	await _frames(3)
	for dir in [1, -1]:
		var label2: String = "derecha" if dir == 1 else "izquierda"
		p.facing = dir
		p._invuln_t = 99.0
		var far := FakeEnemy.new()
		far.position = p.position + Vector2(170.0 * dir, 0.0)
		far.add_to_group("enemies")
		var behind := FakeEnemy.new()
		behind.position = p.position + Vector2(-150.0 * dir, 0.0)
		behind.add_to_group("enemies")
		var too_far := FakeEnemy.new()
		too_far.position = p.position + Vector2(230.0 * dir, -20.0)
		too_far.add_to_group("enemies")
		lvl.add_child(far)
		lvl.add_child(behind)
		lvl.add_child(too_far)
		p.skill_cd = 0.0
		p._use_skill()
		await process_frame
		_check(_fireballs(lvl).size() == 1, "[%s] solo se lanza hacia el enemigo lejano de delante (no al de atrás ni al que queda fuera de alcance)" % label2)
		var t0: int = Time.get_ticks_msec()
		await _until(func(): return far.hits.size() > 0 or _fireballs(lvl).is_empty(), 240)
		_check(far.hits == ["spark"], "[%s] alcanza a un enemigo a 170 px con el daño de siempre" % label2)
		_check(behind.hits.is_empty() and too_far.hits.is_empty(), "[%s] los de atrás y los fuera de alcance no reciben daño" % label2)
		await _until(func(): return _fireballs(lvl).is_empty(), 120)
		# sin objetivo: recorre ~192 px antes de estallar
		far.queue_free()
		behind.queue_free()
		too_far.queue_free()
		await process_frame
		p.skill_cd = 0.0
		p._use_skill()
		await process_frame
		var ff = _fireballs(lvl)[0]
		var ff_ref: WeakRef = weakref(ff)
		var sx: float = ff.global_position.x
		var maxd: float = 0.0
		while ff_ref.get_ref() != null and not ff_ref.get_ref().exploded:
			maxd = maxf(maxd, absf(ff_ref.get_ref().global_position.x - sx))
			await physics_frame
		ff = null
		_check(maxd > 150.0 and maxd < 200.0, "[%s] sin enemigos recorre ~%.0f px (3 veces los 64 de antes) antes de estallar" % [label2, maxd])
		await _until(func(): return _fireballs(lvl).is_empty(), 120)
		p.skill_cd = 0.0
	# enfriamiento: no se puede lanzar otra mientras dura
	p.facing = 1
	p.skill_cd = 0.0
	p._use_skill()
	p._use_skill()
	await process_frame
	_check(_fireballs(lvl).size() == 1, "durante el enfriamiento no salen más bolas")
	await _until(func(): return _fireballs(lvl).is_empty(), 180)
	# Electricidad (poder temporal): conserva los rayos, sin bola de fuego
	p.grant_power("pulse")
	p.skill_cd = 0.0
	var e2 := FakeEnemy.new()
	e2.position = p.position + Vector2(30.0, 0.0)
	e2.add_to_group("enemies")
	lvl.add_child(e2)
	var b0: int = _bolt_lines(lvl)
	p._use_skill()
	await process_frame
	_check(_bolt_lines(lvl) > b0 and _fireballs(lvl).is_empty(), "Electricidad (temporal) sigue con sus rayos y sin bola de fuego")
	_check(e2.hits == ["spark"], "Electricidad conserva su daño instantáneo")
	e2.queue_free()
	# Fuego (poder temporal): sigue con sus tres llamas
	p.grant_power("flame")
	p.skill_cd = 0.0
	var s0: int = _player_shots(lvl)
	p._use_skill()
	await process_frame
	_check(_player_shots(lvl) == s0 + 3 and _fireballs(lvl).is_empty(), "Fuego (temporal) sigue lanzando sus 3 llamas y no la bola")
	await _free_level(lvl)
	# otros mundos: su poder base no cambia
	_reset_game()
	lvl = await _load_level(1)
	p = lvl.player
	p.skill_cd = 0.0
	var s1: int = _player_shots(lvl)
	p._use_skill()
	await process_frame
	_check(p.power == "spark" and _player_shots(lvl) == s1 + 1 and _fireballs(lvl).is_empty(), "Mundo 1: la Chispa Esmeralda no cambia")
	await _free_level(lvl)
	_reset_game()


# ============================================== WILMEN WORLD (hito 1): modo independiente ===
const ORIGINAL_LEVELS_SHA := "8607279216819a4d2cc872bec1073e6bd604923d10ae3d37b1d940f27bd0db52"


func _wipe_ww_files() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(_ww.save_path + suffix)


func _sha(path: String) -> String:
	return FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "(sin archivo)"


func _test_ww_base() -> void:
	print("WILMEN WORLD (hito 1): guardado independiente, protección del modo original, menú y pantalla de inicio")
	var story_path: String = _game.save_path
	var ww_path: String = _ww.save_path
	_check(ww_path != story_path and ww_path.get_file() != "wilmen_save.json", "la partida de WILMEN WORLD usa otro archivo")
	var default_ww: String = load("res://autoload/ww.gd").new().save_path
	_check(default_ww == "user://wilmen_world_save.json", "archivo real del modo: user://wilmen_world_save.json")
	_check(_ww.REGION_COUNT * _ww.LEVELS_PER_REGION == 120 and _ww.LEVEL_COUNT == 120 and _ww.REGION_NAMES.size() == 6, "6 regiones x 20 niveles = 120")
	_check(_ww.REGION_NAMES == ["Bosque Esmeralda", "Desierto Dorado", "Reino Volcánico", "Reino Congelado", "Océano Perdido", "Reino de las Sombras"], "las 6 regiones elegidas")
	# ---- el modo original no cambia ----
	_check(_game.LEVEL_COUNT == 100 and _game.LEVELS_PER_WORLD == 10 and _game.SAVE_VERSION == 3, "WILMEN ADVENTURE: 100 niveles, 10 mundos y guardado v3")
	_check(_game.KNOWN_KEYS == ["version", "lives", "score", "coins", "total_coins", "levels", "worlds_done", "unlocked", "settings", "ext"], "las claves del guardado original no cambian")
	var hs: String = ""
	for n in range(1, 101):
		hs += FileAccess.get_sha256("res://levels/data/level_%02d.txt" % n)
	_check(hs.sha256_text() == ORIGINAL_LEVELS_SHA, "los 100 niveles originales siguen idénticos (huella de sus archivos)")
	# ---- guardados independientes ----
	_reset_game()
	_wipe_ww_files()
	_game.coins = 777
	_game.score = 4321
	_game.levels["1"] = {"done": true, "gems": [true, false, false], "best": 900}
	_game.unlocked[2] = true
	_game.save_game()
	var story_hash: String = _sha(story_path)
	_check(story_hash != "(sin archivo)", "se guardó la partida de WILMEN ADVENTURE (huella de referencia)")
	_ww.reset()
	_ww.coins = 55
	_ww.gems = 4
	_ww.lives = 7
	_ww.score = 900
	_ww.keys = {"bronce": 2, "plata": 1}
	_ww.levels["3"] = {"done": true, "gems": [true, true, false], "best_time": 61.5}
	_ww.nodes = {"r1_start": true}
	_check(_ww.save_game(), "WILMEN WORLD guarda su partida")
	_check(FileAccess.file_exists(ww_path) and _sha(story_path) == story_hash, "guardar WILMEN WORLD NO toca la partida de WILMEN ADVENTURE")
	var ww_hash: String = _sha(ww_path)
	_game.coins += 10
	_game.save_game()
	_check(_sha(ww_path) == ww_hash and _sha(story_path) != story_hash, "guardar WILMEN ADVENTURE NO toca la partida de WILMEN WORLD")
	_check(_game.coins == 787 and _ww.coins == 55, "monedas independientes (Adventure %d, World %d)" % [_game.coins, _ww.coins])
	_game.save_game()
	story_hash = _sha(story_path)
	# ---- ida y vuelta ----
	_ww.reset()
	_check(_ww.coins == 0 and _ww.lives == _ww.START_LIVES and _ww.levels.is_empty() and _ww.keys.is_empty(), "reset() vuelve al estado inicial del modo")
	_check(_sha(story_path) == story_hash and _game.coins == 787, "reiniciar WILMEN WORLD NO toca WILMEN ADVENTURE")
	_ww.load_game()
	_check(_ww.coins == 55 and _ww.gems == 4 and _ww.lives == 7 and _ww.score == 900, "al cargar se recuperan monedas, gemas, vidas y puntos")
	_check(_ww.keys == {"bronce": 2, "plata": 1} and _ww.total_keys() == 3, "se recuperan las llaves")
	_check(_ww.is_done(3) and not _ww.is_done(4) and _ww.completed_count() == 1 and _ww.completed_in_region(1) == 1, "se recupera el progreso de niveles")
	_check(_ww.nodes.has("r1_start"), "se recuperan los nodos del mapa")
	# ---- robustez ----
	_check(_ww.save_game(), "segundo guardado (crea la copia .bak del anterior)")
	_check(FileAccess.file_exists(ww_path + ".bak"), "existe la copia .bak")
	var f := FileAccess.open(ww_path, FileAccess.WRITE)
	f.store_string("{esto no es json")
	f.close()
	_ww.reset()
	_ww.load_game()
	_check(_ww.coins == 55, "archivo dañado: se recupera la copia .bak")
	f = FileAccess.open(ww_path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 1, "lives": "x", "coins": -5, "levels": {"999": {"done": true}, "2": {"done": true, "gems": [true]}, "abc": 1}, "futuro": {"a": 1}}))
	f.close()
	_ww.load_game()
	_check(_ww.lives >= 1 and _ww.coins == 0 and not _ww.levels.has("999") and _ww.is_done(2), "valores absurdos se corrigen y los niveles fuera de rango se ignoran")
	_check(_ww.save_game(), "se vuelve a guardar")
	var back: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ww_path))
	_check(back.has("futuro") and back["version"] == 1, "las claves desconocidas (versiones futuras) se conservan")
	# ---- salvaguarda: nunca escribir sobre la partida original ----
	var keep_path: String = _ww.save_path
	_ww.save_path = story_path
	_check(not _ww.save_game() and _sha(story_path) == story_hash, "WILMEN WORLD se niega a guardar sobre el archivo de WILMEN ADVENTURE")
	_ww.save_path = "user://wilmen_save.json"
	var real_before: String = _sha("user://wilmen_save.json")
	_check(not _ww.save_game() and _sha("user://wilmen_save.json") == real_before, "ni siquiera con la ruta real wilmen_save.json")
	_ww.save_path = keep_path
	# ---- menú principal ----
	_reset_game()
	var title = load("res://ui/title.tscn").instantiate()
	root.add_child(title)
	await _frames(8)
	var btns: Array = title._menu.get_children()
	var wbtn = btns[2]
	_check(wbtn.text == "WILMEN WORLD" and wbtn.icon != null and wbtn.pressed.get_connections().size() > 0 and not wbtn.disabled, "el menú tiene el botón real «WILMEN WORLD» con icono y acción")
	var last_y: float = btns[btns.size() - 1].get_global_rect().end.y
	_check(last_y <= title.size.y - 4.0, "los 6 botones caben en pantalla (último termina en y=%.0f de %.0f)" % [last_y, title.size.y])
	var overlap: bool = false
	for i in range(btns.size() - 1):
		if btns[i].get_global_rect().end.y > btns[i + 1].get_global_rect().position.y + 0.5:
			overlap = true
	_check(not overlap, "los botones del menú no se solapan")
	title.queue_free()
	await _frames(3)
	# ---- pantalla de inicio de WILMEN WORLD ----
	_wipe_ww_files()
	_ww.reset()
	_ww.coins = 7
	_ww.gems = 2
	_ww.keys = {"bronce": 1}
	_ww.levels["1"] = {"done": true, "gems": [false, false, false], "best_time": 0.0}
	_ww.levels["21"] = {"done": true, "gems": [false, false, false], "best_time": 0.0}
	story_hash = _sha(story_path)
	var hub = load("res://ui/ww_hub.tscn").instantiate()
	root.add_child(hub)
	await _frames(8)
	var texts: Array = []
	for l in hub.find_children("*", "Label", true, false):
		texts.append(l.text)
	_check(texts.has("WILMEN WORLD"), "la pantalla del modo muestra su título")
	_check(texts.has("Niveles  2/120") and texts.has("Monedas  7") and texts.has("Gemas  2") and texts.has("Llaves  1"), "muestra el progreso PROPIO del modo")
	_check(texts.has("Bosque Esmeralda") and texts.has("Reino de las Sombras"), "lista las regiones")
	_check(texts.has("1/20"), "progreso por región (1/20 en las dos primeras)")
	_check(FileAccess.file_exists(ww_path), "entrar crea la partida propia del modo")
	_check(_sha(story_path) == story_hash, "entrar en WILMEN WORLD no toca la partida de WILMEN ADVENTURE")
	_check(hub.find_children("*", "AnimatedSprite2D", true, false).size() > 0, "se muestra el héroe con su apariencia")
	# reiniciar: dos pasos y solo afecta al modo
	hub._reset_btn.pressed.emit()
	_check(_ww.coins == 7 and hub._reset_btn.text.begins_with("¿Seguro"), "reiniciar pide confirmación y no borra a la primera")
	hub._reset_btn.pressed.emit()
	await _frames(2)
	_check(_ww.coins == 0 and _ww.completed_count() == 0 and _ww.lives == _ww.START_LIVES, "tras confirmar, WILMEN WORLD vuelve a empezar")
	_check(JSON.parse_string(FileAccess.get_file_as_string(ww_path))["coins"] == 0, "y su archivo queda reiniciado")
	_check(_sha(story_path) == story_hash, "reiniciar WILMEN WORLD no toca la partida original")
	_check(hub._back != null and hub._back.pressed.get_connections().size() > 0, "hay un botón para volver al menú")
	hub.queue_free()
	await _frames(3)
	_wipe_ww_files()
	_ww.reset()
	_reset_game()
