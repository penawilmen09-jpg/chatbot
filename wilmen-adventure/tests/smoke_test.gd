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

	if OS.get_cmdline_user_args().has("--mech"):
		await _test_ww_mechanics()
		print("RESULTADO: %s" % ("TODO OK" if _failed == 0 else "%d fallos" % _failed))
		quit(0 if _failed == 0 else 1)
		return

	if OS.get_cmdline_user_args().has("--ww3"):
		await _test_ww_content()
		await _test_ww_map()
		print("RESULTADO: %s" % ("TODO OK" if _failed == 0 else "%d fallos" % _failed))
		quit(0 if _failed == 0 else 1)
		return

	if OS.get_cmdline_user_args().has("--ww2"):
		await _test_ww_levels()
		print("RESULTADO: %s" % ("TODO OK" if _failed == 0 else "%d fallos" % _failed))
		quit(0 if _failed == 0 else 1)
		return

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
	await _test_ww_content()
	await _test_ww_map()
	await _test_ww_levels()
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


# ============================================== WILMEN WORLD: modo independiente ===
const ORIGINAL_LEVELS_SHA := "8607279216819a4d2cc872bec1073e6bd604923d10ae3d37b1d940f27bd0db52"


func _wipe_ww_files() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(_ww.save_path + suffix)


func _sha(path: String) -> String:
	return FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "(sin archivo)"


func _ww_done(n: int, gem_flags: Array = [false, false, false], secret: bool = false) -> void:
	## Completa un nivel de WILMEN WORLD por la vía legítima (la misma que usa la meta).
	_ww.register_complete(n, gem_flags, 100.0, 50.0, secret)


func _test_ww_base() -> void:
	print("WILMEN WORLD: guardado independiente, protección del modo original, migración y menú")
	var story_path: String = _game.save_path
	var ww_path: String = _ww.save_path
	_check(ww_path != story_path and ww_path.get_file() != "wilmen_save.json", "la partida de WILMEN WORLD usa otro archivo")
	var default_ww: String = load("res://autoload/ww.gd").new().save_path
	_check(default_ww == "user://wilmen_world_save.json", "archivo real del modo: user://wilmen_world_save.json")
	_check(_ww.REGION_COUNT * _ww.LEVELS_PER_REGION == 120 and _ww.LEVEL_COUNT == 120 and _ww.REGION_NAMES.size() == 6, "6 regiones x 20 niveles = 120")
	_check(_ww.SAVE_VERSION == 2, "guardado de WILMEN WORLD v2")
	_check(_game.LEVEL_COUNT == 100 and _game.LEVELS_PER_WORLD == 10 and _game.SAVE_VERSION == 3, "WILMEN ADVENTURE: 100 niveles, 10 mundos y guardado v3")
	_check(_game.KNOWN_KEYS == ["version", "lives", "score", "coins", "total_coins", "levels", "worlds_done", "unlocked", "settings", "ext"], "las claves del guardado original no cambian")
	var hs: String = ""
	for n in range(1, 101):
		hs += FileAccess.get_sha256("res://levels/data/level_%02d.txt" % n)
	_check(hs.sha256_text() == ORIGINAL_LEVELS_SHA, "los 100 niveles originales siguen idénticos (huella de sus archivos)")
	_reset_game()
	_wipe_ww_files()
	_game.coins = 777
	_game.score = 4321
	_game.levels["1"] = {"done": true, "gems": [true, false, false], "best": 900}
	_game.unlocked[2] = true
	_game.save_game()
	var story_hash: String = _sha(story_path)
	_ww.reset()
	_ww.coins = 55
	_ww.gems = 4
	_ww.lives = 7
	_ww.score = 900
	_ww.keys = {"bronce": 2}
	_ww.map_node = 3
	_ww_done(3, [true, true, false], true)
	_check(_ww.save_game(), "WILMEN WORLD guarda su partida")
	_check(FileAccess.file_exists(ww_path) and _sha(story_path) == story_hash, "guardar WILMEN WORLD NO toca la partida de WILMEN ADVENTURE")
	var ww_hash: String = _sha(ww_path)
	_game.coins += 10
	_game.save_game()
	_check(_sha(ww_path) == ww_hash and _sha(story_path) != story_hash, "guardar WILMEN ADVENTURE NO toca la partida de WILMEN WORLD")
	_check(_game.coins == 787 and _ww.coins == 55, "monedas independientes (Adventure %d, World %d)" % [_game.coins, _ww.coins])
	_game.save_game()
	story_hash = _sha(story_path)
	_ww.reset()
	_check(_ww.coins == 0 and _ww.levels.is_empty() and _ww.map_node == 1, "reset() vuelve al estado inicial del modo")
	_check(_sha(story_path) == story_hash and _game.coins == 787, "reiniciar WILMEN WORLD NO toca WILMEN ADVENTURE")
	_ww.load_game()
	_check(_ww.coins == 55 and _ww.gems == 4 and _ww.lives == 7 and _ww.score == 900 and _ww.keys == {"bronce": 2}, "al cargar se recuperan monedas, gemas, vidas, puntos y llaves")
	_check(_ww.is_done(3) and _ww.secret_done(3) and _ww.gems_in(3) == 2 and _ww.map_node == 3, "se recupera el nivel completado, su salida secreta, las gemas y la posición en el mapa")
	# migración v1 (hito 2): ningún nivel se marca como completado automáticamente
	var f := FileAccess.open(ww_path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 1, "lives": 6, "coins": 33, "keys": {"bronce": 3}, "levels": {"1": {"done": true, "gems": [true, true, true]}, "2": {"done": true}, "3": {"done": true}}}))
	f.close()
	_ww.load_game()
	_check(_ww.completed_count() == 0 and not _ww.is_done(1) and _ww.key_count() == 0, "migración v1 -> v2: no se arrastra ningún nivel completado ni llave")
	_check(_ww.coins == 33 and _ww.lives == 6, "pero se conservan monedas y vidas")
	# robustez
	_ww.reset()
	_ww.coins = 55
	_check(_ww.save_game() and _ww.save_game() and FileAccess.file_exists(ww_path + ".bak"), "se crea la copia .bak")
	f = FileAccess.open(ww_path, FileAccess.WRITE)
	f.store_string("{esto no es json")
	f.close()
	_ww.reset()
	_ww.load_game()
	_check(_ww.coins == 55, "archivo dañado: se recupera la copia .bak")
	f = FileAccess.open(ww_path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 2, "lives": "x", "coins": -5, "levels": {"999": {"done": true}, "2": {"done": true, "gems": [true]}, "abc": 1}, "futuro": {"a": 1}}))
	f.close()
	_ww.load_game()
	_check(_ww.lives >= 1 and _ww.coins == 0 and not _ww.levels.has("999") and _ww.is_done(2), "valores absurdos se corrigen y los niveles fuera de rango se ignoran")
	_check(_ww.save_game() and JSON.parse_string(FileAccess.get_file_as_string(ww_path)).has("futuro"), "las claves desconocidas se conservan")
	var keep_path: String = _ww.save_path
	_ww.save_path = story_path
	_check(not _ww.save_game() and _sha(story_path) == story_hash, "WILMEN WORLD se niega a guardar sobre el archivo de WILMEN ADVENTURE")
	_ww.save_path = "user://wilmen_save.json"
	var real_before: String = _sha("user://wilmen_save.json")
	_check(not _ww.save_game() and _sha("user://wilmen_save.json") == real_before, "ni siquiera con la ruta real wilmen_save.json")
	_ww.save_path = keep_path
	# menú principal
	_reset_game()
	var title = load("res://ui/title.tscn").instantiate()
	root.add_child(title)
	await _frames(8)
	var btns: Array = title._menu.get_children()
	var wbtn = btns[2]
	_check(wbtn.text == "WILMEN WORLD" and wbtn.icon != null and wbtn.pressed.get_connections().size() > 0 and not wbtn.disabled, "el menú tiene el botón real «WILMEN WORLD» con icono y acción")
	_check(btns[btns.size() - 1].get_global_rect().end.y <= title.size.y - 4.0, "los 6 botones caben en pantalla")
	title.queue_free()
	await _frames(3)
	_check(_sha(story_path) == story_hash, "WILMEN ADVENTURE sigue sin tocarse")
	_wipe_ww_files()
	_ww.reset()
	_reset_game()


# ============================ WILMEN WORLD: contenido de la región 1 (20 niveles) ===
func _test_ww_content() -> void:
	print("WILMEN WORLD: región 1 completa (20 niveles reales de 700 a 1000 columnas) y mapa de 120 niveles")
	var avail: Array = _ww.available_levels()
	_check(avail == range(1, 21), "existen exactamente los 20 niveles de la región 1 (ww_001..020): %s" % str(avail.size()))
	_check(not _ww.has_level(21) and not _ww.has_level(120), "los niveles de las regiones 2 a 6 NO existen todavía (no se muestran como jugables)")
	var kinds: Dictionary = {}
	var titles: Dictionary = {}
	var shas: Dictionary = {}
	var bad: Array = []
	for n in avail:
		var d: Dictionary = _ww.parse_level(FileAccess.get_file_as_string(_ww.level_path(n)))
		var meta: Dictionary = d["meta"]
		var txt: String = "".join(d["rows"])
		var cols: int = int(d["cols"])
		var run: float = float(cols) * 16.0 / 125.0
		var t: int = int(meta["time"])
		if cols < 700 or cols > 1000 or d["rows"].size() != 20:
			bad.append("%d: columnas %d" % [n, cols])
		if t < int(run * 2.6) or t > int(run * 4.2):
			bad.append("%d: tiempo %d" % [n, t])
		if txt.count("P") != 1 or txt.count("F") != 1 or txt.count("*") != 3 or txt.count("C") < 3:
			bad.append("%d: P/F/gemas/puntos de control" % n)
		if d["warps"].size() < 1 or txt.count("U") + int(str(meta["kind"]) == "castle") < 1:
			bad.append("%d: sin túneles/llaves" % n)
		var secret_expected: bool = [5, 9, 13, 19].has(n)
		if (txt.count("O") == 1) != secret_expected:
			bad.append("%d: salida secreta" % n)
		var boss_expected: bool = n == 20
		if (txt.count("X") == 1 and txt.count("G") == 1) != boss_expected or (not boss_expected and (txt.count("X") > 0 or txt.count("G") > 0)):
			bad.append("%d: jefe" % n)
		kinds[str(meta["kind"])] = int(kinds.get(str(meta["kind"]), 0)) + 1
		titles[str(meta["title"])] = true
		shas[FileAccess.get_sha256(_ww.level_path(n))] = true
	_check(bad.is_empty(), "los 20 niveles cumplen longitud, tiempo, meta, gemas, puntos de control, túneles/llaves, salida secreta y jefe %s" % str(bad))
	_check(kinds == {"normal": 14, "cave": 2, "house": 1, "fortress": 1, "secret": 1, "castle": 1}, "distribución: 14 normales, 2 cuevas, 1 casa, 1 fortaleza, 1 ruta secreta y 1 castillo %s" % str(kinds))
	_check(titles.size() == 20 and shas.size() == 20, "los 20 niveles tienen nombre propio y contenido distinto")
	# ---- datos del mapa ----
	var data: Dictionary = _ww.map_data()
	var by_region: Dictionary = {}
	var node_kinds: Dictionary = {}
	for n in data["nodes"]:
		if int(n["id"]) < 900:
			by_region[int(n["region"])] = int(by_region.get(int(n["region"]), 0)) + 1
			node_kinds[str(n["kind"])] = int(node_kinds.get(str(n["kind"]), 0)) + 1
	_check(by_region == {1: 20, 2: 20, 3: 20, 4: 20, 5: 20, 6: 20}, "el mapa tiene los 120 niveles, 20 por región")
	_check(node_kinds == {"dot": 90, "cave": 12, "house": 6, "fortress": 6, "castle": 6}, "entradas del mapa: puntos, cuevas, casas, fortalezas y castillos %s" % str(node_kinds))
	var statuses: Array = []
	for r in data["regions"]:
		statuses.append(str(r["status"]))
	_check(statuses == ["playable", "construction", "construction", "construction", "construction", "construction"], "región 1 jugable; las otras cinco visibles y en construcción")
	_check(data["bridges"].size() >= 8 and data["rivers"].size() >= 4 and data["mountains"].size() >= 8, "el mapa tiene puentes, ríos y montañas")
	var tunnels: int = 0
	for e in data["edges"]:
		if str(e["kind"]) == "tunnel":
			tunnels += 1
	_check(tunnels >= 12, "y túneles entre niveles (%d)" % tunnels)


# ======================================= WILMEN WORLD: el mapa explorable =====
func _test_ww_map() -> void:
	print("WILMEN WORLD: mapa explorable, caminos, desbloqueo y secretos")
	var story_path: String = _game.save_path
	_wipe_ww_files()
	_ww.reset()
	_reset_game()
	_game.save_game()
	var story_hash: String = _sha(story_path)
	# ---- estados iniciales: nada está completado ----
	_check(_ww.completed_count() == 0, "al empezar no hay ningún nivel completado")
	_check(_ww.node_state(1) == "available", "solo el nivel 1-1 está disponible")
	var avail_n: int = 0
	var states: Dictionary = {}
	for n in _ww.map_data()["nodes"]:
		var s: String = _ww.node_state(int(n["id"]))
		states[s] = int(states.get(s, 0)) + 1
		if s == "available":
			avail_n += 1
	_check(avail_n == 1, "un único nivel disponible al empezar")
	_check(_ww.node_state(2) == "locked" and _ww.node_state(20) == "locked", "el resto de la región 1 está bloqueado (pero visible)")
	_check(_ww.node_state(7) == "hidden" and _ww.node_state(901) == "hidden", "la casa 1-7 y el túnel sellado están ocultos hasta descubrirlos")
	_check(_ww.node_state(21) == "construction" and _ww.node_state(120) == "construction", "las regiones 2 a 6 aparecen «en construcción»")
	_check(not _ww.can_enter(2) and not _ww.can_enter(21) and _ww.can_enter(1), "solo se puede entrar en el nivel disponible")
	# ---- desbloqueos legítimos ----
	_check(_ww.route(1, 2).is_empty(), "no hay camino hasta el 1-2 antes de completar el 1-1")
	_ww_done(1)
	_check(_ww.node_state(1) == "done" and _ww.node_state(2) == "available", "completar el 1-1 abre el camino al 1-2")
	_check(not _ww.route(1, 2).is_empty() and _ww.route(1, 3).is_empty(), "y solo ese: el 1-3 sigue sin camino")
	_check(_ww.node_state(4) == "locked" and _ww.node_state(5) == "locked", "el 1-4 y el 1-5 siguen bloqueados")
	_ww_done(2)
	_ww_done(3)
	_check(_ww.node_state(4) == "available" and _ww.node_state(5) == "available", "tras el 1-3 hay dos caminos alternativos: cueva (1-4) y copas (1-5)")
	_check(_ww.node_state(6) == "locked", "el 1-6 aún no")
	_ww_done(5)
	_check(_ww.node_state(6) == "available" and _ww.node_state(7) == "hidden", "completar el 1-5 por la salida normal abre el 1-6 pero NO descubre la casa")
	_ww_done(5, [false, false, false], true)
	_check(_ww.node_state(7) == "available", "la salida SECRETA del 1-5 descubre la casa 1-7 (ruta secreta)")
	_check(not _ww.route(5, 7).is_empty(), "y abre su camino")
	_ww_done(6)
	_ww_done(8)
	_ww_done(9, [false, false, false], true)
	var edge_secret: Dictionary = {}
	for e in _ww.map_data()["edges"]:
		if int(e["a"]) == 9 and int(e["b"]) == 15:
			edge_secret = e
	_check(not edge_secret.is_empty() and _ww.edge_unlocked(edge_secret), "la salida secreta del 1-9 abre un túnel bajo la montaña hasta el 1-15")
	_check(_ww.node_state(20) == "locked" and _ww.node_state(21) == "construction", "el castillo sigue bloqueado y la región 2 sin construir")
	# la región siguiente no se puede pisar aunque se complete el castillo
	_ww_done(19)
	_ww_done(20)
	_check(_ww.node_state(21) == "construction" and not _ww.can_enter(21), "aunque se supere el castillo, la región 2 sigue en construcción y no jugable")
	_wipe_ww_files()
	_ww.reset()
	# ---- escena del mapa ----
	var map = load("res://ui/ww_map.tscn").instantiate()
	root.add_child(map)
	await _frames(10)
	var vis: int = 0
	for id in map.node_views:
		if map.node_views[id].visible:
			vis += 1
	_check(vis == 114, "el mapa muestra 114 entradas (los 120 niveles menos las 6 casas ocultas): %d" % vis)
	_check(map.at_node == 1 and map.hero.position.distance_to(map._pos_of(1)) < 1.0, "el héroe empieza en el nivel 1-1")
	_check(map.hero_sprite.animation == "idle" and not map.walking, "y está quieto (animación de reposo)")
	_check(map._enter_btn.text == "ENTRAR" and not map._enter_btn.disabled, "el botón ENTRAR está activo en el 1-1")
	_check(map.get_child_count() > 5 and map.camera != null, "hay mapa, caminos, niveles, héroe y cámara")
	# tocar un nivel bloqueado: no se mueve
	var p0: Vector2 = map.hero.position
	_check(not map._walk_to(2), "tocar un nivel bloqueado no mueve al héroe")
	await _frames(10)
	_check(map.hero.position == p0 and map.at_node == 1, "el héroe sigue en su sitio")
	_check(not map._walk_to(21), "tampoco hacia una región en construcción")
	_check(map._enter_btn.disabled == false, "ENTRAR sigue disponible solo para el nivel actual")
	# completar el 1-1 y caminar hasta el 1-2
	_ww_done(1)
	map._refresh_all()
	map.paths.queue_redraw()
	_check(map._walk_to(2) and map.walking, "tras completar el 1-1 el héroe puede ir al 1-2")
	_check(map.hero_sprite.animation == "run", "y camina con la animación de correr")
	var moved: bool = false
	var max_off: float = 0.0
	var path: Array = []
	for e in _ww.map_data()["edges"]:
		if int(e["a"]) == 1 and int(e["b"]) == 2:
			path = e["path"]
	for i in range(240):
		await physics_frame
		if map.hero.position.distance_to(p0) > 20.0:
			moved = true
		# siempre cerca del camino (camina POR el camino)
		var dmin: float = 1e9
		for q in path:
			dmin = minf(dmin, map.hero.position.distance_to(Vector2(float(q[0]), float(q[1]))))
		max_off = maxf(max_off, dmin)
		if not map.walking:
			break
	_check(moved and not map.walking and map.at_node == 2, "el héroe camina físicamente y llega al 1-2")
	_check(map.hero.position.distance_to(map._pos_of(2)) < 2.0 and max_off < 14.0, "siguiendo el camino (se alejó como máximo %.1f px de él)" % max_off)
	_check(map.hero_sprite.animation == "idle" and _ww.map_node == 2, "se detiene y la posición queda guardada")
	# flechas: hacia atrás por el camino abierto
	map._press_dir(Vector2.LEFT)
	map._press_dir(Vector2.UP)
	map._press_dir(Vector2.RIGHT)
	map._press_dir(Vector2.DOWN)
	await _until(func(): return not map.walking, 400)
	_check(_ww.is_walkable(map.at_node), "las flechas llevan a un nivel contiguo con camino abierto")
	_check(map._info.text != "" and map._stats.text.begins_with("Vidas"), "el panel muestra el nivel actual y el estado del jugador")
	_check(_ww.completed_count() == 1, "moverse por el mapa no completa ningún nivel")
	# marcas visuales
	var done_badge: Sprite2D = map.node_views[1].get_node("badge")
	_check(map.node_views[1].get_node("stars").visible and done_badge.texture != null, "el nivel completado lleva su marca (bandera y estrellas)")
	_check(not map.node_views[3].get_node("stars").visible, "los niveles sin completar no")
	# menú del mapa
	map._toggle_menu()
	await _frames(3)
	_check(map._menu_panel != null, "el botón Menú abre el menú del mapa")
	map._toggle_menu()
	await _frames(3)
	map.queue_free()
	await _frames(3)
	_check(_sha(story_path) == story_hash, "jugar con el mapa no toca la partida de WILMEN ADVENTURE")
	_wipe_ww_files()
	_ww.reset()
	_reset_game()


# ================ WILMEN WORLD: reloj, túneles, puertas, llaves, secretos y jefe ===
func _ww_level(n: int):
	_ww.start_level(n)
	var lvl = load("res://levels/ww_level.tscn").instantiate()
	root.add_child(lvl)
	await process_frame
	await _frames(6)
	if is_instance_valid(lvl.hud._intro):
		lvl.hud._intro.queue_free()
		lvl.hud._intro = null
	return lvl


func _stand_at(lvl, cell: Vector2i) -> void:
	lvl.player.global_position = Vector2(cell.x * 16 + 8, cell.y * 16 + 6)
	lvl.player.velocity = Vector2.ZERO
	lvl.camera.reset_smoothing()


func _cell_of(node) -> Vector2i:
	return Vector2i(int((node.position.x - 8) / 16), int((node.position.y - 16) / 16))


func _scripts_of(lvl, path: String) -> Array:
	return lvl.get_children().filter(func(n): return n.get_script() != null and n.get_script().resource_path == path)


func _test_ww_levels() -> void:
	print("WILMEN WORLD: reloj, túneles, puertas con llave, verjas, salida secreta, jefe y guardado")
	var story_path: String = _game.save_path
	_wipe_ww_files()
	_ww.reset()
	_reset_game()
	_game.coins = 42
	_game.score = 999
	_game.lives = 6
	_game.save_game()
	var story_hash: String = _sha(story_path)
	var game_before: Dictionary = {"coins": _game.coins, "score": _game.score, "lives": _game.lives, "levels": JSON.stringify(_game.levels)}
	# ---- los 20 niveles se cargan en el motor ----
	var load_bad: Array = []
	for n in range(1, 21):
		var l0 = await _ww_level(n)
		if l0.player == null or l0.goal == null or l0.cols < 700 or int(l0.time_total) != int(l0.meta["time"]) or l0.warps.size() < 2 and n != 20:
			load_bad.append(n)
		if n == 20 and (l0.boss == null or l0.boss.get_script().resource_path != "res://enemies/ww_boss.gd"):
			load_bad.append(n)
		await _free_level(l0)
	_check(load_bad.is_empty(), "los 20 niveles se cargan y se pueden jugar en el motor %s" % str(load_bad))
	# ---- entrar en el nivel 1: sesión aislada, reloj y HUD ----
	var lvl = await _ww_level(1)
	_check(_game.world_active() and _game.mode == "world", "al entrar se abre la sesión de WILMEN WORLD")
	_check(lvl.warps.size() == 6 and lvl.time_total == float(lvl.meta["time"]) and lvl.number == 1, "nivel 1 cargado con sus 3 conexiones y su reloj (%d s)" % int(lvl.time_total))
	var t0: float = lvl.time_left
	await _frames(60)
	_check(lvl.time_left < t0 - 0.8 and lvl.time_left > t0 - 1.6, "el reloj cuenta atrás en tiempo real (%.2f -> %.2f)" % [t0, lvl.time_left])
	_check(lvl.hud._timer_label.text == "%d:%02d" % [int(ceil(lvl.time_left)) / 60, int(ceil(lvl.time_left)) % 60], "el reloj se ve en pantalla (%s)" % lvl.hud._timer_label.text)
	var ClockS = load("res://items/ww_clock.gd")
	var ck = ClockS.new()
	ck.seconds = 15
	ck.level = lvl
	ck.global_position = lvl.player.global_position
	lvl.add_child(ck)
	var tl: float = lvl.time_left
	await _frames(8)
	_check(lvl.time_left > tl + 13.0, "un reloj suma +15 s (%.1f -> %.1f)" % [tl, lvl.time_left])
	_game.save_game()
	_game.add_coin()
	_check(_sha(story_path) == story_hash, "mientras se juega WILMEN WORLD, la partida de WILMEN ADVENTURE no se escribe")
	var lives0: int = _game.lives
	lvl.time_left = 0.03
	await _frames(6)
	_check(lvl.player.dead and lvl.timed_out, "al llegar el reloj a cero el personaje muere")
	_check(_game.lives == lives0 - 1, "y pierde una vida (%d -> %d)" % [lives0, _game.lives])
	await _until(func(): return not lvl.player.dead, 400)
	_check(not lvl.player.dead and lvl.time_left >= 60.0, "reaparece con tiempo suficiente (%.0f s)" % lvl.time_left)
	# ---- túnel real ----
	var wa = lvl.warps[0]
	var wb = lvl.warps[1]
	_check(wa.kind == "tunnel" and wa.partner == wb and wb.partner == wa, "el túnel A está conectado con la bodega")
	_stand_at(lvl, _cell_of(wa))
	var from_x: float = lvl.player.global_position.x
	await _frames(10)
	Input.action_press("jump")
	await _frames(2)
	Input.action_release("jump")
	await _until(func(): return absf(lvl.player.global_position.x - from_x) > 200.0, 120)
	await _frames(20)
	_check(lvl.player.global_position.distance_to(wb.arrive) < 40.0 and absf(lvl.player.global_position.x - from_x) > 3000.0, "saltar sobre el túnel te lleva a otra zona lejana (%.0f px)" % absf(lvl.player.global_position.x - from_x))
	await _frames(60)
	_check(lvl.player.global_position.distance_to(wb.arrive) < 60.0, "no vuelve solo al origen")
	var wc = lvl.warps[2]
	_stand_at(lvl, _cell_of(wc))
	var cave_x: float = lvl.player.global_position.x
	await _frames(120)
	_check(absf(lvl.player.global_position.x - cave_x) < 30.0, "permanecer 2 s sobre la boca NO entra solo")
	Input.action_press("jump")
	await _frames(2)
	Input.action_release("jump")
	await _until(func(): return absf(lvl.player.global_position.x - cave_x) > 200.0, 120)
	await _frames(20)
	_check(lvl.player.global_position.distance_to(lvl.warps[3].arrive) < 40.0, "pulsar SALTO sobre la boca entra (atajo hacia el tramo final)")
	# ---- puerta con llave ----
	var door = lvl.warps[4]
	_check(door.kind == "door" and door.need_key == 1 and door.is_locked(), "la puerta del nivel 1 está cerrada con cerradura")
	_ww.keys = {}
	_stand_at(lvl, _cell_of(door))
	var door_x: float = lvl.player.global_position.x
	await _frames(40)
	_check(absf(lvl.player.global_position.x - door_x) < 30.0 and door.is_locked(), "junto a la puerta no se entra solo")
	Input.action_press("jump")
	await _frames(2)
	Input.action_release("jump")
	await _frames(40)
	_check(absf(lvl.player.global_position.x - door_x) < 30.0 and _ww.key_count() == 0 and door.is_locked(), "sin llave, SALTO no abre la puerta")
	_ww.keys = {"bronce": 1}
	_stand_at(lvl, _cell_of(door))
	await _frames(30)
	_check(absf(lvl.player.global_position.x - door_x) < 60.0 and _ww.key_count() == 1, "con llave pero sin pulsar SALTO tampoco entra ni gasta la llave")
	_stand_at(lvl, _cell_of(door))
	await _frames(4)
	Input.action_press("jump")
	await _frames(2)
	Input.action_release("jump")
	await _until(func(): return absf(lvl.player.global_position.x - door_x) > 200.0, 120)
	await _frames(20)
	_check(absf(lvl.player.global_position.x - door_x) > 1500.0, "con llave la puerta se abre y entras en la cámara")
	_check(_ww.key_count() == 0 and _ww.is_open(1, door.warp_id), "la puerta consumió la llave y queda abierta")
	var vault_arrive: Vector2 = lvl.player.global_position
	await _frames(60)
	var back_door = door.partner
	_stand_at(lvl, _cell_of(back_door))
	await _frames(20)
	Input.action_press("jump")
	await _frames(2)
	Input.action_release("jump")
	await _until(func(): return absf(lvl.player.global_position.x - vault_arrive.x) > 200.0, 120)
	await _frames(20)
	_check(lvl.player.global_position.distance_to(door.arrive) < 50.0, "la puerta abierta sirve de ida y vuelta (sin gastar más llaves)")
	# ---- llave: recogida única ----
	var keys_nodes: Array = _scripts_of(lvl, "res://items/ww_key.gd")
	_check(keys_nodes.size() == 1, "hay una llave en la bodega del nivel 1")
	var kn = keys_nodes[0]
	var kid: String = kn.key_id
	lvl.player.global_position = kn.global_position
	await _frames(6)
	_check(_ww.key_count() == 1 and _ww.key_taken(1, kid), "recoger la llave la añade al inventario (y queda anotada)")
	await _free_level(lvl)
	_check(not _game.world_active() and _game.mode == "story", "al salir se cierra la sesión y vuelve el modo original")
	_check(_game.coins == game_before["coins"] and _game.score == game_before["score"] and _game.lives == game_before["lives"], "monedas, puntos y vidas de WILMEN ADVENTURE se restauran")
	_check(_sha(story_path) == story_hash and JSON.stringify(_game.levels) == game_before["levels"], "la partida de WILMEN ADVENTURE sigue idéntica")
	lvl = await _ww_level(1)
	_check(_scripts_of(lvl, "res://items/ww_key.gd").is_empty(), "la llave ya recogida no reaparece al repetir el nivel")
	_check(not lvl.warps[4].is_locked(), "la puerta abierta sigue abierta")
	# ---- completar el nivel: progreso y desbloqueo en el mapa ----
	_check(_ww.node_state(2) == "locked" and not _ww.is_done(1), "antes de la meta el 1-2 está bloqueado y el 1-1 sin completar")
	var coins_before: int = _ww.coins
	for g in range(3):
		lvl.gems[g] = g != 2
	lvl.hud.set_gems(lvl.gems)
	lvl.time_left = 200.0
	_game.add_coin()
	lvl.player.global_position = lvl.goal.global_position
	await _until(func(): return lvl.finished, 120)
	_check(lvl.finished, "tocar la meta completa el nivel")
	await _until(func(): return lvl.hud._overlay != null, 400)
	_check(lvl.hud._overlay != null and lvl.final_info.get("first", false) and not lvl.final_info.get("secret", true), "aparece la pantalla de resultados (primera vez, salida normal)")
	_check(_ww.is_done(1) and _ww.gems_in(1) == 2 and not _ww.secret_done(1), "el progreso queda anotado: nivel 1 completado con 2 gemas")
	_check(_ww.node_state(2) == "available" and _ww.route(1, 2).size() == 1, "y el mapa abre el camino al 1-2")
	_check(_ww.coins == coins_before + 1 and _ww.score > 0, "monedas y puntos del nivel pasan a la partida de WILMEN WORLD")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(_ww.save_path))
	_check(saved["levels"]["1"]["done"] == true and saved["coins"] == coins_before + 1, "y se guardan en wilmen_world_save")
	var btn_texts: Array = []
	for b in lvl.hud._overlay.find_children("*", "Button", true, false):
		btn_texts.append(b.text)
	_check(btn_texts.has("Continuar en el mapa") and btn_texts.has("Repetir nivel"), "botones de resultado: %s" % str(btn_texts))
	await _free_level(lvl)
	_ww.reset()
	_ww.load_game()
	_check(_ww.is_done(1) and _ww.gems_in(1) == 2 and _ww.record(1)["best_time"] > 0.0, "tras cerrar y abrir el juego, el progreso sigue")
	_check(_sha(story_path) == story_hash, "WILMEN ADVENTURE sigue sin tocarse tras completar un nivel")
	# ---- salida secreta (1-5) ----
	_ww_done(1)
	_ww_done(2)
	_ww_done(3)
	lvl = await _ww_level(5)
	var sg: Array = _scripts_of(lvl, "res://items/ww_secret_goal.gd")
	_check(sg.size() == 1 and _ww.node_state(7) == "hidden", "el 1-5 tiene una bandera secreta y la casa 1-7 sigue oculta")
	lvl.player.global_position = sg[0].global_position
	await _until(func(): return lvl.finished, 120)
	await _until(func(): return lvl.hud._overlay != null, 400)
	_check(_ww.secret_done(5) and lvl.final_info.get("secret", false), "tocar la bandera secreta registra la salida secreta")
	_check(_ww.node_state(7) == "available" and int(lvl.final_info.get("opened", 0)) >= 1, "y descubre un camino nuevo en el mapa (la casa 1-7)")
	await _free_level(lvl)
	# ---- verja con candado (1-4) ----
	_ww.keys = {}
	lvl = await _ww_level(4)
	var gates: Array = _scripts_of(lvl, "res://items/ww_gate.gd")
	_check(gates.size() == 1 and gates[0].cells == 3, "el 1-4 tiene una verja de 3 celdas")
	var gate = gates[0]
	var gate_id: String = gate.gate_id
	var gcell := Vector2i(int((gate.position.x - 8) / 16), int((gate.position.y - 8) / 16))
	_stand_at(lvl, Vector2i(gcell.x - 2, 14))
	Input.action_press("move_right")
	await _frames(90)
	Input.action_release("move_right")
	var gate_x: float = gate.position.x
	_check(lvl.player.global_position.x < gate_x and is_instance_valid(gate) and _ww.key_count() == 0, "sin llave la verja bloquea el paso")
	_ww.keys = {"bronce": 1}
	Input.action_press("move_right")
	await _frames(120)
	Input.action_release("move_right")
	_check(_ww.key_count() == 0 and _ww.is_open(4, gate_id), "con llave la verja se abre, gasta la llave y queda abierta")
	_check(lvl.player.global_position.x > gate_x + 8, "y el jugador la atraviesa")
	await _free_level(lvl)
	# ---- jefe del castillo (1-20): tres fases ----
	lvl = await _ww_level(20)
	var b = lvl.boss
	_check(b != null and b.max_hp == 16 and b.phase == 1, "el castillo tiene al Guardián de la Espesura (16 de vida, fase 1)")
	_check(lvl.goal != null and not lvl.goal.visible, "la meta no aparece hasta vencer al jefe")
	b.activate(lvl.gate_x + 16.0, (lvl.cols - 2) * 16.0, 0.0)
	var p = lvl.player
	p.position = Vector2(lvl.gate_x + 40.0, b.position.y)
	p._invuln_t = 999.0
	# la IA del jefe se ejecuta de verdad (fase 3, la más exigente): lanza ataques sin errores y sin perder vida sola
	var shots: Array = [0]
	lvl.child_entered_tree.connect(func(n): shots[0] += int(str(n.get("team")) == "enemy"))
	b.phase = 3
	b.speed_mult = 1.44
	await _frames(1500)
	_check(shots[0] >= 8 and not b.dead and b.hp == 16, "la IA del jefe en fase 3 ataca durante 25 s (%d proyectiles) sin errores" % shots[0])
	b._gen += 1
	b.phase = 1
	b.speed_mult = 1.0
	b.mode = "idle"
	b.hp = b.max_hp
	await _frames(5)
	b._gen += 1
	b.mode = "idle"
	var phases: Array = [b.phase]
	for i in range(15):
		b._invuln_t = 0.0
		b.shielded = false
		b.hit_boss(1)
		if phases[phases.size() - 1] != b.phase:
			phases.append(b.phase)
	_check(phases == [1, 2, 3] and b.speed_mult > 1.3, "pierde vida y pasa por las fases 1, 2 y 3 (más rápido cada vez) %s" % str(phases))
	b._invuln_t = 0.0
	b.hit_boss(1)
	_check(b.hp == 0 and b.dead, "con 16 golpes cae derrotado")
	await _until(func(): return lvl.goal.visible, 200)
	_check(lvl.goal.visible, "y entonces aparece la meta")
	await _free_level(lvl)
	# ---- sin vidas ----
	_wipe_ww_files()
	_ww.reset()
	_ww.lives = 1
	lvl = await _ww_level(3)
	_game.lives = 1
	lvl.player.die()
	await _until(func(): return lvl.finished, 400)
	_check(lvl.finished and _game.lives == 0, "sin vidas: fin del intento")
	await _frames(4)
	var go_btns: Array = []
	for bt in lvl.hud._overlay.find_children("*", "Button", true, false):
		go_btns.append(bt.text)
	_check(go_btns == ["Reintentar", "Volver al mapa"], "pantalla «Sin vidas» de WILMEN WORLD: %s" % str(go_btns))
	await _free_level(lvl)
	_check(_ww.lives >= 1, "la partida de WILMEN WORLD conserva al menos una vida")
	_check(_sha(story_path) == story_hash, "al final, la partida de WILMEN ADVENTURE sigue idéntica")
	_wipe_ww_files()
	_ww.reset()
	_reset_game()


# ================= WILMEN WORLD (tanda 0): pruebas individuales de cada mecánica nueva =================
class Grid:
	var g: Array = []
	var w: int = 0

	func _init(w_: int, h_: int) -> void:
		w = w_
		for y in range(h_):
			var row: Array = []
			for x in range(w_):
				row.append(" ")
			g.append(row)

	func put(x: int, y: int, ch: String) -> void:
		if y >= 0 and y < g.size() and x >= 0 and x < w:
			g[y][x] = ch

	func fill(x0: int, y0: int, x1: int, y1: int, ch: String) -> void:
		for y in range(y0, y1):
			for x in range(x0, x1):
				put(x, y, ch)

	func ground(x0: int, x1: int, top: int) -> void:
		fill(x0, top, x1, g.size(), "#")

	func text(extra: String = "") -> String:
		var lines: Array = []
		for r in g:
			lines.append("".join(r))
		return "@title Prueba\n@region 1\n@theme 1\n@time 900\n@difficulty 1\n" + extra + "\n".join(lines) + "\n"


func _mini(gr, extra: String = ""):
	## Crea un nivel de prueba (en memoria) con la rejilla dada y lo carga como nivel 1 de WILMEN WORLD.
	_ww.test_text = gr.text(extra)
	_ww.start_level(1)
	var lvl = load("res://levels/ww_level.tscn").instantiate()
	root.add_child(lvl)
	await process_frame
	await _frames(4)
	if is_instance_valid(lvl.hud._intro):
		lvl.hud._intro.queue_free()
		lvl.hud._intro = null
	lvl.player._invuln_t = 0.0
	return lvl


func _end_mini(lvl) -> void:
	_ww.test_text = ""
	await _free_level(lvl)


func _launch_vel(p) -> Vector2:
	## Velocidad del jugador en el primer fotograma en que sale lanzado (o la última si no se lanza).
	var v: Vector2 = p.velocity
	for i in range(30):
		await physics_frame
		v = p.velocity
		if v.y < -300.0:
			break
	return v


func _test_ww_mech_shrooms() -> void:
	print("Mecánica: setas lanzadoras (impulso vertical y diagonal con física)")
	var g := Grid.new(120, 20)
	g.ground(0, 120, 15)
	g.put(3, 14, "P")
	g.put(10, 14, "%")
	g.fill(8, 8, 13, 9, "=")
	g.put(30, 14, "{")
	g.fill(44, 14, 50, 15, "#")  # plataforma de aterrizaje de la seta diagonal (a la misma altura que el suelo: se comprueba por distancia)
	g.put(70, 14, "}")
	var lvl = await _mini(g)
	var p = lvl.player
	# --- vertical
	p.global_position = Vector2(10 * 16 + 8, 13 * 16 + 4)
	p.velocity = Vector2(0, 80)
	var lv: Vector2 = await _launch_vel(p)
	_check(lv.y < -380.0, "la seta vertical lanza hacia arriba con fuerza (vy=%.0f)" % lv.y)
	var y0: float = p.global_position.y
	var top: float = y0
	for i in range(70):
		await physics_frame
		top = minf(top, p.global_position.y)
	_check(y0 - top > 95.0, "la trayectoria sube más de 95 px (subió %.0f)" % (y0 - top))
	await _frames(60)
	_check(p.is_on_floor() and p.global_position.y < 8 * 16 + 4, "y aterriza sobre la plataforma alta que está a su alcance (y=%.0f)" % p.global_position.y)
	# --- diagonal derecha
	p.global_position = Vector2(30 * 16 + 8, 13 * 16 + 4)
	p.velocity = Vector2(0, 80)
	var x0: float = p.global_position.x
	lv = await _launch_vel(p)
	_check(lv.x > 200.0 and lv.y < -380.0, "la seta diagonal da un impulso (%.0f, %.0f)" % [lv.x, lv.y])
	await _until(func(): return p.is_on_floor(), 200)
	var dx: float = p.global_position.x - x0
	_check(dx > 190.0 and dx < 260.0, "sin tocar nada recorre unos 14 celdas hacia delante (%.0f px) y aterriza" % dx)
	# --- el jugador puede frenar el impulso empujando en sentido contrario
	p.global_position = Vector2(30 * 16 + 8, 13 * 16 + 4)
	p.velocity = Vector2(0, 80)
	x0 = p.global_position.x
	lv = await _launch_vel(p)
	Input.action_press("move_left")
	await _until(func(): return p.is_on_floor(), 200)
	Input.action_release("move_left")
	_check(p.global_position.x - x0 < dx - 60.0, "empujar al contrario recorta el salto (%.0f < %.0f)" % [p.global_position.x - x0, dx])
	# --- diagonal izquierda
	p.global_position = Vector2(70 * 16 + 8, 13 * 16 + 4)
	p.velocity = Vector2(0, 80)
	lv = await _launch_vel(p)
	_check(lv.x < -200.0, "la seta izquierda lanza hacia la izquierda (vx=%.0f)" % lv.x)
	# --- no lanza si el jugador sube a través de ella
	p.global_position = Vector2(10 * 16 + 8, 14 * 16 + 4)
	p.velocity = Vector2(0, -300)
	await _frames(2)
	_check(p.velocity.y > -320.0 and p.velocity.y < -250.0, "no se activa mientras el jugador la atraviesa subiendo")
	await _end_mini(lvl)


func _test_ww_mech_vine() -> void:
	print("Mecánica: liana (balanceo real: agarrar, ir con ella y soltar con velocidad)")
	var g := Grid.new(80, 20)
	g.ground(0, 14, 15)
	g.ground(36, 80, 15)
	g.put(5, 14, "P")
	for k in range(7):
		g.put(25, 3 + k, "$")  # liana de 7 celdas: anclaje en la fila 3
	var lvl = await _mini(g)
	var p = lvl.player
	var vines: Array = _scripts_of(lvl, "res://items/ww_vine.gd")
	_check(vines.size() == 1 and vines[0].length_px == 112.0, "se crea una liana de 7 celdas (112 px)")
	var v = vines[0]
	# el asa oscila de verdad
	var minx: float = 1e9
	var maxx: float = -1e9
	for i in range(160):
		await physics_frame
		minx = minf(minx, v.handle_pos.x)
		maxx = maxf(maxx, v.handle_pos.x)
	_check(minx < -80.0 and maxx > 80.0, "el asa se balancea de %.0f a %.0f px" % [minx, maxx])
	# agarrar: el jugador cae en el aire junto al asa
	p.global_position = v.to_global(v.handle_pos) + Vector2(0, -4)
	p.velocity = Vector2(0, 60)
	await _frames(3)
	_check(p.vehicle == v and v.rider == p, "al tocar el asa en el aire el jugador se agarra")
	var d0: float = p.global_position.distance_to(v.to_global(v.handle_pos))
	await _frames(40)
	var d1: float = p.global_position.distance_to(v.to_global(v.handle_pos))
	_check(absf(d1 - d0) < 3.0 and p.velocity == Vector2.ZERO, "y va con ella (se mueve con el asa)")
	# soltar en el momento en que la trayectoria balística cae sobre la plataforma de la derecha
	var released: bool = false
	var landed_x: float = 0.0
	for i in range(400):
		await physics_frame
		if not released:
			var vel: Vector2 = v.handle_vel * 1.08 + Vector2(0, -150.0)
			var pos: Vector2 = p.global_position
			var t: float = 0.0
			var x: float = pos.x
			var y: float = pos.y
			var vy: float = vel.y
			var hit_x: float = -1.0
			while t < 2.0:
				vy = minf(vy + 900.0 * 0.01, 340.0)
				x += vel.x * 0.01
				y += vy * 0.01
				t += 0.01
				if y > 15 * 16 - 8 and vy > 0.0:
					hit_x = x
					break
			if hit_x > 38 * 16 and hit_x < 44 * 16 and vel.x > 150.0:
				Input.action_press("jump")
				await physics_frame
				Input.action_release("jump")
				released = true
		elif p.is_on_floor():
			landed_x = p.global_position.x
			break
	_check(released and p.vehicle == null, "SALTO suelta la liana")
	_check(landed_x > 36 * 16, "y la velocidad del balanceo lleva al jugador al otro lado del hueco (aterriza en x=%.0f, hueco de 14 a 36)" % landed_x)
	await _end_mini(lvl)


func _test_ww_mech_logs() -> void:
	print("Mecánica: troncos rodantes (aviso, rodar por el suelo, daño y desaparición)")
	var g := Grid.new(90, 20)
	g.ground(0, 90, 15)
	g.put(60, 14, "&")
	g.put(70, 14, "#")
	g.fill(6, 10, 7, 15, "#")
	g.put(40, 14, "P")
	var lvl = await _mini(g)
	var p = lvl.player
	var chute = lvl.get_children().filter(func(n): return n.get_script() != null and n.get_script().resource_path == "res://items/ww_chute.gd")[0]
	var seen_warn: bool = false
	var log_node = null
	for i in range(520):
		await physics_frame
		seen_warn = seen_warn or chute._sprite.texture == load("res://items/ww_atlas.gd").tex("chute_warn")
		var logs: Array = lvl.get_children().filter(func(n): return n.get_script() != null and n.get_script().resource_path == "res://items/ww_log.gd")
		if not logs.is_empty():
			log_node = logs[0]
			break
	_check(seen_warn, "la tolva avisa (tiembla) antes de soltar el tronco")
	_check(log_node != null, "suelta un tronco")
	var x0: float = log_node.position.x
	await _frames(30)
	_check(log_node.position.x < x0 - 30.0 and is_equal_approx(log_node.velocity.x, -log_node.speed), "el tronco rueda hacia la izquierda a su velocidad (%.0f px/s)" % absf(log_node.velocity.x))
	_check(log_node.is_on_floor(), "y sigue el suelo")
	# daño si el jugador se queda en su camino
	var hp0: int = p.hp
	p.global_position = Vector2(log_node.position.x - 70, 14 * 16 + 4)
	p._invuln_t = 0.0
	await _until(func(): return p.hp < hp0 or not is_instance_valid(log_node), 240)
	_check(p.hp < hp0, "un tronco que alcanza al jugador le quita un corazón")
	await _end_mini(lvl)
	# el tronco desaparece al chocar con un muro
	g = Grid.new(60, 20)
	g.ground(0, 60, 15)
	g.put(30, 14, "&")
	g.fill(10, 9, 11, 15, "#")
	g.put(20, 14, "P")
	lvl = await _mini(g)
	var gone: bool = false
	var had: bool = false
	for i in range(900):
		await physics_frame
		var l3: Array = lvl.get_children().filter(func(n): return n.get_script() != null and n.get_script().resource_path == "res://items/ww_log.gd")
		if not l3.is_empty():
			had = true
		elif had:
			gone = true
			break
		lvl.player.global_position = Vector2(20 * 16 + 8, 8 * 16)  # fuera del camino
		lvl.player.velocity = Vector2.ZERO
	_check(had and gone, "el tronco rueda hasta el muro y desaparece")
	await _end_mini(lvl)


func _nodes_of(lvl, script: String) -> Array:
	return lvl.get_children().filter(func(n): return n.get_script() != null and n.get_script().resource_path == script)


func _test_ww_mech_phase_bridge() -> void:
	print("Mecánica: plataformas que desaparecen y puente que se derrumba")
	var g := Grid.new(60, 20)
	g.ground(0, 8, 15)
	g.ground(52, 60, 15)
	g.fill(12, 12, 15, 13, "-")
	g.put(5, 14, "P")
	var lvl = await _mini(g)
	var ph = _nodes_of(lvl, "res://items/ww_phase.gd")[0]
	_check(ph.cells == 3, "un tramo de '-' es una sola plataforma (%d celdas)" % ph.cells)
	var seen_solid := false
	var seen_ghost := false
	var warned := false
	for i in range(400):
		await physics_frame
		seen_solid = seen_solid or not ph._cs.disabled
		seen_ghost = seen_ghost or ph._cs.disabled
		warned = warned or (ph.solid and ph._t > 0 and fposmod(ph._t, 4.8) > 2.0)
	_check(seen_solid and seen_ghost and warned, "alterna: sólida, parpadeo de aviso y oculta (sin colisión)")
	# el jugador de pie sobre ella cae cuando desaparece
	ph._t = 0.0
	ph._apply()
	lvl.player.global_position = Vector2(13 * 16 + 8, 12 * 16 - 10)
	lvl.player.velocity = Vector2.ZERO
	await _frames(20)
	_check(lvl.player.is_on_floor() and lvl.player.global_position.y < 12 * 16, "se puede pisar mientras está sólida")
	await _until(func(): return not lvl.player.is_on_floor(), 400)
	_check(not lvl.player.is_on_floor() and ph._cs.disabled, "al desaparecer el jugador deja de estar apoyado y cae")
	await _end_mini(lvl)
	# puente
	g = Grid.new(60, 22)
	g.ground(0, 8, 15)
	g.ground(40, 60, 15)
	g.fill(8, 15, 40, 16, "_")
	g.put(5, 14, "P")
	lvl = await _mini(g)
	var br = _nodes_of(lvl, "res://items/ww_bridge.gd")[0]
	_check(br.cells == 32, "el puente tiene 32 tablas (%d)" % br.cells)
	lvl.player.global_position = Vector2(9 * 16 + 8, 15 * 16 - 12)
	lvl.player.velocity = Vector2.ZERO
	await _frames(15)
	_check(br.collapsed_count() == 0, "al principio todas las tablas están")
	await _frames(70)
	_check(br.collapsed_count() > 0, "al pisarlo se derrumba en cadena (%d caídas)" % br.collapsed_count())
	# cruzar corriendo lo logra; quedarse quieto no
	await _until(func(): return lvl.player.dead, 300)
	await _until(func(): return not lvl.player.dead, 600)
	await _frames(10)
	_check(_nodes_of(lvl, "res://items/ww_bridge.gd")[0].collapsed_count() == 0, "al reaparecer el puente se reconstruye entero")
	br = _nodes_of(lvl, "res://items/ww_bridge.gd")
	br = br[br.size() - 1]
	lvl.player.global_position = Vector2(9 * 16 + 8, 15 * 16 - 12)
	lvl.player.velocity = Vector2.ZERO
	await _frames(10)
	var pl = lvl.player
	var crossed := false
	for i in range(400):
		Input.action_press("move_right")
		await physics_frame
		if pl.global_position.x > 41 * 16 and pl.is_on_floor():
			crossed = true
			break
		if pl.dead:
			break
	Input.action_release("move_right")
	print("    (x=%.0f y=%.0f muerto=%s caídas=%d)" % [pl.global_position.x, pl.global_position.y, pl.dead, br.collapsed_count()])
	_check(crossed, "corriendo sin parar se cruza antes de que caiga")
	await _end_mini(lvl)


func _test_ww_mech_switch() -> void:
	print("Mecánica: interruptores que cambian el escenario de verdad")
	var g := Grid.new(50, 20)
	g.ground(0, 50, 15)
	g.put(5, 14, "P")
	g.put(10, 14, "/")
	g.fill(20, 11, 21, 15, "(")
	g.fill(30, 11, 31, 15, ")")
	var lvl = await _mini(g)
	var pl = lvl.player
	var blks: Array = lvl.get_children().filter(func(n): return n.get_script() != null and n.get_script().resource_path == "res://items/ww_toggle.gd")
	_check(blks.size() >= 2, "hay bloques conmutables (%d)" % blks.size())
	var a = blks.filter(func(b): return b.global_position.x < 25 * 16)[0]
	var b2 = blks.filter(func(b): return b.global_position.x > 25 * 16)[0]
	_check(a._solid and not b2._solid, "con el interruptor apagado '(' es sólido y ')' fantasma")
	_check(not a._cs.disabled and b2._cs.disabled, "colisión coherente con el estado")
	pl.global_position = Vector2(10 * 16 + 8, 14 * 16)
	await _frames(12)
	_check(lvl.sw[0] == true, "tocar el interruptor lo enciende")
	await _frames(3)
	_check(not a._solid and b2._solid and a._cs.disabled and not b2._cs.disabled, "los bloques se invierten (escenario modificado)")
	# el muro ')' ahora detiene al jugador; '(' ya no
	pl.global_position = Vector2(26 * 16, 14 * 16)
	pl.velocity = Vector2.ZERO
	await _frames(10)
	for i in range(80):
		Input.action_press("move_right")
		await physics_frame
	Input.action_release("move_right")
	_check(pl.global_position.x < 30 * 16, "el bloque activo detiene al jugador (x=%.0f)" % pl.global_position.x)
	pl.global_position = Vector2(14 * 16, 14 * 16)
	pl.velocity = Vector2.ZERO
	await _frames(8)
	for i in range(100):
		Input.action_press("move_right")
		await physics_frame
	Input.action_release("move_right")
	_check(pl.global_position.x > 22 * 16, "el bloque apagado se atraviesa (x=%.0f)" % pl.global_position.x)
	# no se cierra encima del jugador
	pl.global_position = Vector2(a.global_position.x, a.global_position.y)
	pl.velocity = Vector2.ZERO
	await _frames(2)
	lvl.toggle_switch(1)
	await _frames(6)
	print("    (sw=%s a.solid=%s overlap=%s)" % [lvl.sw[0], a._solid, a._area.overlaps_body(pl)])
	_check(not a._solid, "un bloque no se solidifica sobre el jugador")
	await _end_mini(lvl)


func _test_ww_mech_water_hazards() -> void:
	print("Mecánica: corrientes de agua, dardos, péndulo, plataforma orbital y ascensor")
	var g := Grid.new(80, 24)
	g.ground(0, 80, 20)
	g.fill(10, 17, 30, 20, ":")
	g.fill(40, 17, 60, 20, ".")
	g.fill(66, 10, 70, 20, ",")
	g.put(8, 19, "P")
	var lvl = await _mini(g)
	var pl = lvl.player
	# sin pulsar nada, la corriente a la derecha arrastra
	pl.global_position = Vector2(11 * 16, 19 * 16)
	pl.velocity = Vector2.ZERO
	await _frames(6)
	var x0: float = pl.global_position.x
	await _frames(60)
	var dx: float = pl.global_position.x - x0
	_check(dx > 50.0, "la corriente derecha arrastra al jugador parado (%.0f px en 1 s)" % dx)
	# contra la corriente avanza más despacio que sin corriente
	pl.global_position = Vector2(28 * 16, 19 * 16)
	await _frames(6)
	x0 = pl.global_position.x
	for i in range(40):
		Input.action_press("move_left")
		await physics_frame
	Input.action_release("move_left")
	var against: float = x0 - pl.global_position.x
	pl.global_position = Vector2(4 * 16, 19 * 16)
	await _frames(6)
	x0 = pl.global_position.x
	for i in range(40):
		Input.action_press("move_right")
		await physics_frame
	Input.action_release("move_right")
	var free: float = pl.global_position.x - x0
	_check(against < free * 0.75, "ir contra la corriente cuesta (%.0f contra %.0f libre)" % [against, free])
	# corriente izquierda
	pl.global_position = Vector2(55 * 16, 19 * 16)
	await _frames(6)
	x0 = pl.global_position.x
	await _frames(60)
	_check(pl.global_position.x < x0 - 50.0, "la corriente izquierda arrastra hacia atrás (%.0f px)" % (pl.global_position.x - x0))
	# burbujas: elevan
	pl.global_position = Vector2(68 * 16, 19 * 16)
	pl.velocity = Vector2.ZERO
	await _frames(6)
	var y0: float = pl.global_position.y
	await _frames(50)
	_check(pl.global_position.y < y0 - 40.0, "las burbujas elevan al jugador (%.0f px)" % (y0 - pl.global_position.y))
	await _end_mini(lvl)
	# dardos
	g = Grid.new(60, 20)
	g.ground(0, 60, 15)
	g.put(50, 14, "\"")
	g.put(10, 14, "P")
	lvl = await _mini(g)
	pl = lvl.player
	var da = _nodes_of(lvl, "res://items/ww_dart.gd")
	_check(da.size() == 1 and da[0].dir == -1, "el lanzadardos '\"' mira a la izquierda")
	da[0]._t = da[0].PERIOD - 0.05
	var dart = null
	for i in range(30):
		await physics_frame
		var ds: Array = lvl.get_children().filter(func(n): return n is Area2D and n.get_script() != null and "dir" in n and "_life" in n)
		if not ds.is_empty():
			dart = ds[0]
			break
	_check(dart != null, "lanza un dardo")
	var hp0: int = pl.hp
	pl.global_position = Vector2(30 * 16, 14 * 16)
	pl.velocity = Vector2.ZERO
	pl._invuln_t = 0.0
	await _until(func(): return pl.hp < hp0, 200)
	_check(pl.hp < hp0, "el dardo hace daño")
	await _end_mini(lvl)
	# péndulo
	g = Grid.new(60, 24)
	g.ground(0, 60, 20)
	g.fill(30, 12, 31, 16, "!")
	g.put(5, 19, "P")
	lvl = await _mini(g)
	pl = lvl.player
	var pe = _nodes_of(lvl, "res://items/ww_pendulum.gd")
	_check(pe.size() == 1 and absf(pe[0].length_px - 64.0) < 1.0, "péndulo de 4 celdas")
	pe = pe[0]
	var minx := 1e9
	var maxx := -1e9
	for i in range(160):
		await physics_frame
		minx = minf(minx, pe.blade_pos.x)
		maxx = maxf(maxx, pe.blade_pos.x)
	_check(minx < -40.0 and maxx > 40.0, "oscila a ambos lados (%.0f..%.0f px)" % [minx, maxx])
	hp0 = pl.hp
	pl._invuln_t = 0.0
	for i in range(200):
		pl.global_position = pe.to_global(pe.blade_pos)
		pl.velocity = Vector2.ZERO
		await physics_frame
		if pl.hp < hp0:
			break
	_check(pl.hp < hp0, "la cuchilla hace daño")
	await _end_mini(lvl)
	# plataforma orbital y ascensor: el jugador va con ellas
	g = Grid.new(60, 30)
	g.ground(0, 6, 26)
	g.put(3, 25, "P")
	g.put(30, 20, "n")
	g.ground(40, 60, 26)
	g.put(50, 25, "b")
	lvl = await _mini(g)
	pl = lvl.player
	var obs = _nodes_of(lvl, "res://items/ww_orbit.gd")
	var orb = obs.filter(func(o): return o.kind == "orbit")[0]
	var elev = obs.filter(func(o): return o.kind == "elevator")[0]
	var rmin := 1e9
	var rmax := -1e9
	for i in range(300):
		await physics_frame
		var d: float = (orb.position - orb._origin).length()
		rmin = minf(rmin, d)
		rmax = maxf(rmax, d)
	_check(rmin > 47.0 and rmax < 49.0, "la orbital describe un círculo de radio 48 (%.1f..%.1f)" % [rmin, rmax])
	# subir al ascensor: el jugador se mueve con él
	elev._t = 0.0
	elev._place()
	await _frames(2)
	pl.global_position = Vector2(elev.position.x, elev.position.y - 14)
	pl.velocity = Vector2.ZERO
	await _frames(20)
	var ey0: float = elev.position.y
	var py0: float = pl.global_position.y
	await _frames(150)
	var edy: float = elev.position.y - ey0
	var pdy: float = pl.global_position.y - py0
	_check(edy < -30.0 and absf(edy - pdy) < 6.0, "el ascensor sube y lleva al jugador (ascensor %.0f, jugador %.0f)" % [edy, pdy])
	# sobre la orbital
	var op0: Vector2 = orb.position
	pl.global_position = Vector2(orb.position.x, orb.position.y - 14)
	pl.velocity = Vector2.ZERO
	await _frames(15)
	var od0: Vector2 = orb.position
	var pd0: Vector2 = pl.global_position
	await _frames(90)
	var o2: Vector2 = orb.position - od0
	var p2: Vector2 = pl.global_position - pd0
	_check(o2.length() > 30.0 and (o2 - p2).length() < 14.0, "la orbital arrastra al jugador (%.0f px, diferencia %.0f)" % [o2.length(), (o2 - p2).length()])
	await _end_mini(lvl)


func _test_ww_tall_level() -> void:
	print("Altura variable: nivel de 450x32 (cámara, límites, caída, fondo y controles)")
	var old_size: Vector2i = root.size
	root.size = Vector2i(1170, 540)  # pantalla de móvil apaisada (2,17:1)
	await _frames(3)
	var g := Grid.new(450, 32)
	g.ground(0, 450, 29)
	g.put(4, 28, "P")
	for i in range(5):
		g.fill(10 + i * 4, 25 - i * 4, 13 + i * 4, 26 - i * 4, "#")
	g.fill(0, 0, 450, 1, "#")
	g.fill(100, 20, 104, 29, " ")
	g.fill(100, 29, 104, 32, " ")
	var lvl = await _mini(g)
	var pl = lvl.player
	var cam: Camera2D = lvl.camera
	_check(lvl.nrows == 32 and lvl.cols == 450, "el nivel mide 450x32 (%dx%d)" % [lvl.cols, lvl.nrows])
	_check(cam.limit_bottom == 32 * 16 and cam.limit_right == 450 * 16, "los límites de cámara cubren el mapa alto (%d, %d)" % [cam.limit_bottom, cam.limit_right])
	# la vista nunca sale del mapa, ni abajo ni arriba, en distintas alturas del jugador
	var vs: Vector2 = lvl.get_viewport_rect().size
	var ok_view := true
	for yy in [29 * 16, 20 * 16, 10 * 16, 2 * 16]:
		pl.global_position = Vector2(30 * 16, yy)
		pl.velocity = Vector2.ZERO
		cam.reset_smoothing()
		await _frames(10)
		var c: Vector2 = cam.get_screen_center_position()
		if c.y - vs.y * 0.5 < -0.5 or c.y + vs.y * 0.5 > 32 * 16 + 0.5:
			ok_view = false
		if absf(c.y - pl.global_position.y) > vs.y * 0.5 - 20.0:
			ok_view = false  # el jugador siempre dentro de la pantalla
	_check(ok_view, "la cámara sigue al jugador en vertical y nunca muestra fuera del mapa")
	# la cámara sube de verdad al escalar
	pl.global_position = Vector2(4 * 16, 28 * 16)
	cam.reset_smoothing()
	await _frames(10)
	var cy0: float = cam.get_screen_center_position().y
	pl.global_position = Vector2(27 * 16 + 8, 8 * 16)
	pl.velocity = Vector2.ZERO
	await _frames(90)
	_check(cam.get_screen_center_position().y < cy0 - 100.0, "al subir, la cámara sube con el jugador (%.0f -> %.0f)" % [cy0, cam.get_screen_center_position().y])
	# caída libre: sin morir mientras hay suelo debajo; se muere sólo bajo el mapa
	var hp0: int = pl.hp
	pl.global_position = Vector2(60 * 16, 2 * 16)
	pl.velocity = Vector2.ZERO
	await _frames(200)
	_check(not pl.dead and pl.global_position.y > 27 * 16, "una caída larga acaba en el suelo, sin morir")
	# foso: morir bajo el mapa (32*16+48)
	pl.global_position = Vector2(102 * 16, 28 * 16)
	pl.velocity = Vector2.ZERO
	await _until(func(): return pl.dead, 400)
	_check(pl.dead, "caer por el foso mata sólo bajo el mapa alto")
	await _until(func(): return not pl.dead, 600)
	# controles: salto y movimiento siguen igual
	await _frames(20)
	pl.global_position = Vector2(20 * 16, 28 * 16)
	pl.velocity = Vector2.ZERO
	await _frames(10)
	var y1: float = pl.global_position.y
	var top: float = y1
	Input.action_press("jump")
	for i in range(30):
		await physics_frame
		top = minf(top, pl.global_position.y)
	Input.action_release("jump")
	_check(y1 - top > 40.0, "el salto funciona en un nivel alto (%.0f px)" % (y1 - top))
	# fondo con desplazamiento vertical
	var bgs: Array = lvl.get_children().filter(func(n): return n is CanvasLayer and "tall" in n)
	_check(bgs.size() == 1 and bgs[0].tall, "el fondo del nivel alto se desplaza en vertical")
	await _end_mini(lvl)
	root.size = old_size
	await _frames(3)


func _lab_open():
	_ww.test_text = ""
	_ww.start_level(_ww.LAB)
	var lvl = load("res://levels/ww_level.tscn").instantiate()
	root.add_child(lvl)
	await process_frame
	await _frames(4)
	if is_instance_valid(lvl.hud._intro):
		lvl.hud._intro.queue_free()
		lvl.hud._intro = null
	lvl.player._invuln_t = 0.0
	return lvl


func _lab_put(lvl, cx: float, cy: int) -> void:
	## Coloca al jugador de pie sobre la celda (columna cx, fila cy) y espera a que se pose.
	lvl.player.global_position = Vector2(cx * 16.0 + 8.0, cy * 16.0)
	lvl.player.velocity = Vector2.ZERO
	lvl.player.vehicle = null
	await _frames(6)


func _hold(action: String, frames: int, stop: Callable = Callable()) -> bool:
	## Mantiene una acción pulsada durante `frames` fotogramas de física (o hasta que `stop` devuelva true).
	for i in range(frames):
		Input.action_press(action)
		await physics_frame
		if stop.is_valid() and stop.call():
			Input.action_release(action)
			return true
	Input.action_release(action)
	return false


func _vine_cross(lvl, vine, from_col: int, land_lo: float, land_hi: float, floor_y: float) -> bool:
	## Jugador virtual: espera en el borde, salta hacia el asa cuando pasa cerca, se agarra y suelta cuando la trayectoria cae
	## en la zona de aterrizaje. Devuelve true si aterriza (apoyado) dentro de [land_lo, land_hi].
	var pl = lvl.player
	await _until(func(): return not pl.dead, 600)
	await _lab_put(lvl, from_col, 24)
	var state: String = "wait"
	var jump_frames: int = 0
	for i in range(1500):
		if pl.dead:
			print("    [liana] murió en estado %s x=%.0f y=%.0f" % [state, pl.global_position.x, pl.global_position.y])
			return false
		if state == "wait":
			var a_f: float = vine.AMP * sin(TAU * (vine._t + 0.30) / vine.PERIOD)
			var hp: Vector2 = vine.to_global(Vector2(sin(a_f), cos(a_f)) * vine.length_px)
			if pl.is_on_floor() and absf(hp.x - (pl.global_position.x + 32.0)) < 14.0 and absf(hp.y - (pl.global_position.y - 54.0)) < 22.0:
				Input.action_press("move_right")
				Input.action_press("jump")
				state = "jump"
		elif state == "jump":
			jump_frames += 1
			if jump_frames > 22:
				Input.action_release("jump")
			if pl.vehicle == vine:
				Input.action_release("move_right")
				state = "ride"
			elif pl.is_on_floor() and i > 0:
				pass
		elif state == "ride":
			var vel: Vector2 = vine.handle_vel * 1.08 + Vector2(0, -150.0)
			var x: float = pl.global_position.x
			var y: float = pl.global_position.y
			var vy: float = vel.y
			var hit_x: float = -1.0
			var t: float = 0.0
			while t < 3.0:
				vy = minf(vy + 900.0 * 0.01, 340.0)
				x += vel.x * 0.01
				y += vy * 0.01
				t += 0.01
				if y > floor_y and vy > 0.0:
					hit_x = x
					break
			if pl.global_position.y < floor_y - 22.0 and hit_x > land_lo + 12.0 and hit_x < land_hi - 12.0:
				print("    [liana] suelto en x=%.0f y=%.0f vel=%s" % [pl.global_position.x, pl.global_position.y, vine.handle_vel])
				Input.action_press("jump")
				await physics_frame
				Input.action_release("jump")
				state = "fly"
		elif state == "fly":
			if pl.vehicle == vine:
				state = "ride"  # se ha vuelto a agarrar: sigue intentándolo
			if pl.is_on_floor():
				Input.action_release("move_right")
				return pl.global_position.x >= land_lo and pl.global_position.x <= land_hi
		await physics_frame
	Input.action_release("move_right")
	Input.action_release("jump")
	print("    [liana] sin resultado, estado=%s x=%.0f y=%.0f vehicle=%s rider=%s vel=%s" % [state, pl.global_position.x, pl.global_position.y, pl.vehicle.get_script().resource_path if pl.vehicle != null else "-", vine.rider, pl.velocity])
	return false


func _bot_run(lvl, target_x: float, max_frames: int, hop_over: Callable = Callable(), start_frame_stuck: int = 14) -> bool:
	## Jugador virtual que corre a la derecha y salta cuando se atasca (escalones) o cuando `hop_over` lo pide.
	var pl = lvl.player
	var stuck: int = 0
	var last_x: float = pl.global_position.x
	var jumping: int = 0
	for i in range(max_frames):
		if pl.dead:
			Input.action_release("move_right")
			Input.action_release("jump")
			return false
		if pl.global_position.x >= target_x and pl.is_on_floor():
			Input.action_release("move_right")
			Input.action_release("jump")
			return true
		Input.action_press("move_right")
		if jumping > 0:
			jumping -= 1
			if jumping == 0:
				Input.action_release("jump")
		elif pl.is_on_floor():
			if absf(pl.global_position.x - last_x) < 0.4:
				stuck += 1
			else:
				stuck = 0
			if stuck >= start_frame_stuck or (hop_over.is_valid() and hop_over.call()):
				Input.action_press("jump")
				jumping = 20
				stuck = 0
		last_x = pl.global_position.x
		await physics_frame
	Input.action_release("move_right")
	Input.action_release("jump")
	return false


func _lab_alive(lvl) -> void:
	await _until(func(): return not lvl.player.dead, 600)
	await _frames(4)


func _phase_left(ph) -> float:
	## Segundos que le quedan sólida a una plataforma que desaparece (0 si ya está oculta).
	var cyc: float = ph.VISIBLE + ph.WARN + ph.HIDDEN
	var f: float = fposmod(ph._t, cyc)
	return maxf(0.0, ph.VISIBLE + ph.WARN * 0.0 - f)



func _test_ww_lab() -> void:
	print("Taller de mecánicas (nivel real ww_950): cada estación se supera jugando")
	var lvl = await _lab_open()
	var pl = lvl.player
	_check(lvl.nrows == 30 and lvl.cols == 540, "el taller mide 540x30 (%dx%d)" % [lvl.cols, lvl.nrows])
	# 1a) seta vertical: andando hacia ella se llega a la repisa alta
	await _lab_put(lvl, 31, 24)
	var ok1: bool = await _hold("move_right", 240, func(): return pl.is_on_floor() and pl.global_position.y < 19 * 16 and pl.global_position.x > 37 * 16)
	_check(ok1, "estación 1: la seta vertical sube a la repisa (x=%.0f y=%.0f)" % [pl.global_position.x, pl.global_position.y])
	# 1b) seta diagonal: salva el foso 57..66
	await _lab_put(lvl, 52, 24)
	var ok2: bool = await _hold("move_right", 300, func(): return pl.is_on_floor() and pl.global_position.x > 68 * 16)
	_check(ok2 and not pl.dead, "estación 1: la seta diagonal salva el foso (x=%.0f)" % pl.global_position.x)
	# 2) lianas: cruzar los dos fosos agarrándose y soltando
	var vines: Array = _nodes_of(lvl, "res://items/ww_vine.gd")
	vines.sort_custom(func(a, b): return a.position.x < b.position.x)
	_check(vines.size() == 2, "estación 2: dos lianas (%d)" % vines.size())
	var c1: bool = await _vine_cross(lvl, vines[0], 80, 91 * 16.0, 100 * 16.0, 25 * 16.0 - 10.0)
	_check(c1, "estación 2: la primera liana lleva a la isla (x=%.0f)" % pl.global_position.x)
	var c2: bool = await _vine_cross(lvl, vines[1], 98, 109 * 16.0, 164 * 16.0, 25 * 16.0 - 10.0)
	_check(c2, "estación 2: la segunda liana lleva a tierra firme (x=%.0f)" % pl.global_position.x)
	# 3) troncos: cruzar la zona de la tolva saltando los troncos que ruedan
	await _lab_alive(lvl)
	await _lab_put(lvl, 118, 24)
	var hp0: int = pl.hp
	var logs_seen: int = 0
	var hop_logs := func():
		for n in _nodes_of(lvl, "res://items/ww_log.gd"):
			var d: float = n.position.x - pl.global_position.x
			if d > 6.0 and d < 46.0 and absf(n.position.y - pl.global_position.y) < 30.0:
				return true
		return false
	var c3: bool = await _bot_run(lvl, 158 * 16.0, 1800, hop_logs)
	_check(c3 and pl.hp == hp0, "estación 3: se cruza la zona de troncos saltándolos (x=%.0f, corazones %d/%d)" % [pl.global_position.x, pl.hp, hp0])
	# 4) plataformas que desaparecen: salta a la siguiente cuando le quede tiempo sólida de sobra
	await _lab_alive(lvl)
	var phs: Array = _nodes_of(lvl, "res://items/ww_phase.gd")
	phs.sort_custom(func(a, b): return a.position.x < b.position.x)
	_check(phs.size() == 5, "estación 4: cinco plataformas que desaparecen (%d)" % phs.size())
	await _lab_put(lvl, 163, 24)
	var idx: int = 0
	var done4: bool = false
	var jump_hold: int = 0
	for i in range(2400):
		if pl.dead:
			break
		if pl.global_position.x > 197 * 16 and pl.is_on_floor():
			done4 = true
			break
		if jump_hold > 0:
			jump_hold -= 1
			Input.action_press("move_right")
			if jump_hold == 0:
				Input.action_release("jump")
				Input.action_release("move_right")
		elif pl.is_on_floor():
			var nxt = phs[idx] if idx < phs.size() else null
			if nxt == null:
				var last_edge: float = phs[phs.size() - 1].position.x + phs[phs.size() - 1].cells * 16.0 - 14.0
				if pl.global_position.x < last_edge:
					Input.action_press("move_right")
				else:
					Input.action_press("jump")
					Input.action_press("move_right")
					jump_hold = 26
			else:
				var tx: float = nxt.position.x
				# ¿estoy ya sobre ella?
				if pl.global_position.x > tx - 14.0 and pl.global_position.x < tx + nxt.cells * 16.0 - 2.0 and absf(pl.global_position.y - (nxt.position.y - 18.0)) < 8.0:
					idx += 1
				else:
					var edge_x: float = 164.0 * 16.0 - 6.0 if idx == 0 else phs[idx - 1].position.x + phs[idx - 1].cells * 16.0 - 14.0
					if pl.global_position.x < edge_x:
						Input.action_press("move_right")
					elif _phase_left(nxt) > 0.8 and nxt.solid:
						Input.action_release("move_right")
						Input.action_press("jump")
						Input.action_press("move_right")
						jump_hold = 26
					else:
						Input.action_release("move_right")
		await physics_frame
	Input.action_release("jump")
	Input.action_release("move_right")
	_check(done4, "estación 4: la cadena se cruza con buen ritmo (x=%.0f, plataforma %d)" % [pl.global_position.x, idx])
	# 5) puente que se derrumba: se cruza corriendo sin parar
	await _lab_alive(lvl)
	await _lab_put(lvl, 200, 24)
	var c5: bool = await _bot_run(lvl, 238 * 16.0, 900)
	_check(c5, "estación 5: el puente se cruza sin detenerse (x=%.0f)" % pl.global_position.x)
	# 6) interruptores: pisar el interruptor abre el muro y crea el camino; el segundo interruptor levanta la escalera
	await _lab_alive(lvl)
	await _lab_put(lvl, 240, 24)
	var c6: bool = await _bot_run(lvl, 298 * 16.0, 2400)
	_check(c6 and lvl.sw[0] and lvl.sw[1], "estación 6: los interruptores abren el muro, el puente de bloques y la escalera (x=%.0f)" % pl.global_position.x)
	# 7) corrientes: a favor, a contracorriente y columna de burbujas hasta la repisa alta
	await _lab_alive(lvl)
	await _lab_put(lvl, 311, 24)
	var c7a: bool = await _bot_run(lvl, 357 * 16.0, 1800)
	_check(c7a, "estación 7: se cruza el río y el tramo a contracorriente (x=%.0f)" % pl.global_position.x)
	var in_col: bool = false
	for i in range(400):
		if pl.dead:
			break
		var px: float = pl.global_position.x
		if px < 360 * 16.0 + 6.0 and pl.global_position.y > 12 * 16.0 and not in_col:
			Input.action_press("move_right")
		else:
			in_col = true
			Input.action_release("move_right")
			if pl.global_position.y < 12 * 16.0 + 6.0:
				Input.action_press("move_right")
				Input.action_press("jump")
		if pl.global_position.x > 365 * 16.0 and pl.is_on_floor() and pl.global_position.y < 13 * 16.0:
			break
		await physics_frame
	Input.action_release("move_right")
	Input.action_release("jump")
	_check(pl.global_position.x > 364 * 16.0 and pl.is_on_floor() and pl.global_position.y < 13 * 16.0, "estación 7: las burbujas elevan hasta la repisa alta (x=%.0f y=%.0f)" % [pl.global_position.x, pl.global_position.y])
	# 8) dardos y péndulo
	await _lab_alive(lvl)
	await _lab_put(lvl, 381, 24)
	var hp8: int = pl.hp
	var pend = _nodes_of(lvl, "res://items/ww_pendulum.gd")[0]
	var hop_hazard := func():
		for n in lvl.get_children():
			if n is Area2D and n.get_script() != null and "_life" in n and "dir" in n:
				var d: float = pl.global_position.x - n.global_position.x
				if d > -50.0 and d < -6.0 and n.dir == 1:
					return true
				if n.dir == -1 and n.global_position.x - pl.global_position.x > 6.0 and n.global_position.x - pl.global_position.x < 50.0:
					return true
		var bx: float = pend.to_global(pend.blade_pos).x - pl.global_position.x
		return bx > -30.0 and bx < 56.0 and pend.blade_pos.y > 80.0
	var c8: bool = await _bot_run(lvl, 404 * 16.0, 1800, hop_hazard)
	_check(c8, "estación 8: se pasa entre los dardos y el péndulo (x=%.0f, corazones %d/%d)" % [pl.global_position.x, pl.hp, hp8])
	# 9) plataforma orbital y ascensor
	await _lab_alive(lvl)
	var obs: Array = _nodes_of(lvl, "res://items/ww_orbit.gd")
	var orb = obs.filter(func(o): return o.kind == "orbit")[0]
	var elev = obs.filter(func(o): return o.kind == "elevator")[0]
	await _lab_put(lvl, 403, 24)
	var on_orb: bool = false
	for i in range(1200):
		if pl.dead:
			break
		if not on_orb:
			var fa: float = (orb._t + 0.38) * 0.9
			var fp: Vector2 = orb._origin + Vector2(cos(fa), sin(fa)) * 48.0
			if pl.is_on_floor() and pl.global_position.y > 23 * 16.0 and pl.global_position.x < 404 * 16.0 - 6.0:
				Input.action_press("move_right")
			elif pl.is_on_floor() and absf(fp.x - (pl.global_position.x + 40.0)) < 22.0 and fp.y < 395.0 and fp.y > 340.0:
				Input.action_press("move_right")
				Input.action_press("jump")
			elif pl.is_on_floor() and pl.global_position.y < 23 * 16.0 and absf(pl.global_position.x - orb.position.x) < 14.0:
				on_orb = true
				Input.action_release("move_right")
				Input.action_release("jump")
			elif pl.is_on_floor():
				Input.action_release("move_right")
				Input.action_release("jump")
		else:
			if orb.position.x > 6568.0 + 38.0 and pl.is_on_floor():
				Input.action_press("move_right")
				Input.action_press("jump")
			if pl.global_position.x > 416 * 16.0 and pl.is_on_floor() and pl.global_position.y > 23 * 16.0:
				break
		await physics_frame
	Input.action_release("move_right")
	Input.action_release("jump")
	_check(on_orb and pl.global_position.x > 416 * 16.0 and pl.is_on_floor(), "estación 9: la orbital lleva de una orilla a la otra (x=%.0f)" % pl.global_position.x)
	await _lab_alive(lvl)
	await _lab_put(lvl, 428, 24)
	var on_el: bool = false
	var top: bool = false
	for i in range(900):
		if pl.dead:
			break
		if not on_el:
			if pl.is_on_floor() and pl.global_position.y > 23 * 16.0 and elev.position.y > 25 * 16.0 + 10.0 and absf(elev.position.x - pl.global_position.x) < 80.0:
				Input.action_press("move_right")
			if pl.is_on_floor() and absf(pl.global_position.x - elev.position.x) < 12.0 and absf(pl.global_position.y - (elev.position.y - 14.0)) < 10.0:
				on_el = true
				Input.action_release("move_right")
		else:
			if elev.position.y < 20 * 16.0 and pl.is_on_floor():
				Input.action_press("move_right")
				Input.action_press("jump")
			if pl.global_position.x > 433 * 16.0 and pl.is_on_floor() and pl.global_position.y < 20 * 16.0:
				top = true
				break
		await physics_frame
	Input.action_release("move_right")
	Input.action_release("jump")
	_check(on_el and top, "estación 9: el ascensor sube hasta la repisa de la meta (x=%.0f y=%.0f)" % [pl.global_position.x, pl.global_position.y])
	await _end_lab(lvl)


func _end_lab(lvl) -> void:
	await _free_level(lvl)


func _warp_moved(lvl, x0: float) -> bool:
	return absf(lvl.player.global_position.x - x0) > 200.0


func _tap_jump() -> void:
	Input.action_press("jump")
	await _frames(2)
	Input.action_release("jump")


func _test_ww_doors() -> void:
	print("Puertas y túneles: solo se entra pulsando SALTO junto a ellos (jamás automáticamente)")
	var g := Grid.new(90, 20)
	g.ground(0, 90, 15)
	g.put(5, 14, "P")
	g.put(20, 14, "A")
	g.put(60, 14, "A")
	g.put(30, 14, "T")
	g.put(70, 14, "T")
	g.put(40, 14, "A")
	g.put(80, 14, "A")
	var lvl = await _mini(g, "@warp 20,14 -> 60,14 door\n@warp 30,14 -> 70,14 tunnel\n@warp 40,14 -> 80,14 door key=1\n")
	var pl = lvl.player
	_ww.keys = {}
	# 1) caminar atravesando la puerta y el túnel no entra
	pl.global_position = Vector2(15 * 16, 14 * 16)
	await _frames(8)
	for i in range(160):
		Input.action_press("move_right")
		await physics_frame
	Input.action_release("move_right")
	_check(pl.global_position.x > 32 * 16 and pl.global_position.x < 40 * 16 - 8 and not lvl.warping, "caminar atravesando una puerta y un túnel no entra (x=%.0f)" % pl.global_position.x)
	# 2) quedarse junto a la puerta no entra aunque pasen los segundos
	pl.global_position = Vector2(20 * 16 + 8, 14 * 16)
	pl.velocity = Vector2.ZERO
	await _frames(150)
	_check(not _warp_moved(lvl, 20 * 16.0) and not lvl.warping, "permanecer junto a la puerta 2,5 s no entra")
	# 3) caer sobre la puerta no entra
	pl.global_position = Vector2(20 * 16 + 8, 8 * 16)
	pl.velocity = Vector2.ZERO
	await _frames(70)
	_check(not _warp_moved(lvl, 20 * 16.0), "caer sobre la puerta no entra")
	# 4) SALTO en el aire cerca de la puerta (doble salto) no entra
	pl.global_position = Vector2(20 * 16 + 8, 11 * 16)
	pl.velocity = Vector2(0, -40)
	await _frames(4)
	await _tap_jump()
	await _frames(30)
	_check(not _warp_moved(lvl, 20 * 16.0), "pulsar SALTO en el aire junto a la puerta no entra")
	# 5) lejos de cualquier entrada, SALTO es un salto normal
	pl.global_position = Vector2(50 * 16, 14 * 16)
	pl.velocity = Vector2.ZERO
	await _frames(20)
	var y0: float = pl.global_position.y
	var top: float = y0
	Input.action_press("jump")
	for i in range(20):
		await physics_frame
		top = minf(top, pl.global_position.y)
	Input.action_release("jump")
	_check(y0 - top > 25.0, "lejos de las puertas SALTO sigue saltando (%.0f px)" % (y0 - top))
	# 6) junto a la puerta y en el suelo: SALTO entra
	pl.global_position = Vector2(20 * 16 + 8, 14 * 16)
	pl.velocity = Vector2.ZERO
	await _frames(30)
	await _tap_jump()
	await _until(func(): return _warp_moved(lvl, 20 * 16.0), 120)
	await _frames(20)
	_check(pl.global_position.distance_to(lvl.warps[1].arrive) < 40.0 or _warp_moved(lvl, 20 * 16.0), "junto a la puerta, SALTO entra (x=%.0f)" % pl.global_position.x)
	await _frames(60)
	# 7) túnel: igual
	pl.global_position = Vector2(30 * 16 + 8, 14 * 16)
	pl.velocity = Vector2.ZERO
	await _frames(100)
	_check(not _warp_moved(lvl, 30 * 16.0), "permanecer sobre la boca del túnel no entra")
	await _tap_jump()
	await _until(func(): return _warp_moved(lvl, 30 * 16.0), 120)
	await _frames(20)
	_check(_warp_moved(lvl, 30 * 16.0), "SALTO sobre la boca del túnel entra (x=%.0f)" % pl.global_position.x)
	await _frames(60)
	# 8) puerta con llave: sin llave se queda fuera; con llave entra
	pl.global_position = Vector2(40 * 16 + 8, 14 * 16)
	pl.velocity = Vector2.ZERO
	await _frames(30)
	await _tap_jump()
	await _frames(40)
	_check(not _warp_moved(lvl, 40 * 16.0), "sin llave, SALTO no abre la puerta cerrada")
	_ww.keys = {"bronce": 1}
	await _frames(30)
	_check(not _warp_moved(lvl, 40 * 16.0) and _ww.key_count() == 1, "con llave, sin SALTO no entra ni gasta la llave")
	await _tap_jump()
	await _until(func(): return _warp_moved(lvl, 40 * 16.0), 120)
	await _frames(20)
	_check(_warp_moved(lvl, 40 * 16.0) and _ww.key_count() == 0, "con llave y SALTO entra y gasta la llave")
	_ww.keys = {}
	await _end_mini(lvl)


func _enemy_of(lvl, kind: String):
	for n in lvl.get_children():
		if n.get_script() != null and n.get_script().resource_path == "res://enemies/ww_enemy.gd" and n.kind == kind:
			return n
	return null


func _test_ww_enemies() -> void:
	print("Enemigos nuevos: topo, guardián, murciélago y lanzarrocas (comportamientos propios)")
	# ---- topo ----
	var g := Grid.new(60, 20)
	g.ground(0, 60, 15)
	g.put(30, 14, "z")
	g.put(5, 14, "P")
	var lvl = await _mini(g)
	var pl = lvl.player
	var mole = _enemy_of(lvl, "mole")
	_check(mole != null and mole.state == "hidden" and not mole.is_in_group("enemies"), "el topo empieza escondido e inofensivo")
	pl.global_position = Vector2(26 * 16, 14 * 16)  # lejos: sigue escondido
	await _frames(40)
	_check(mole.state == "hidden", "si estás lejos el topo no sale")
	pl.global_position = Vector2(30 * 16 + 8 - 40, 14 * 16)
	var hp0: int = pl.hp
	await _until(func(): return mole.state == "warn", 60)
	_check(mole.state == "warn" and pl.hp == hp0, "al acercarte tiembla (aviso) sin hacerte daño")
	await _until(func(): return mole.state == "up", 60)
	_check(mole.state == "up" and mole.is_in_group("enemies"), "después sale del suelo")
	pl.global_position = Vector2(30 * 16 + 8, 15 * 16 - 10)
	pl.velocity = Vector2.ZERO
	pl._invuln_t = 0.0
	await _frames(6)
	_check(pl.hp < hp0, "si te quedas encima cuando sale te hace daño")
	pl.global_position = Vector2(22 * 16, 15 * 16 - 10)
	pl.velocity = Vector2.ZERO
	await _until(func(): return mole.state == "hidden", 260)
	_check(mole.state == "hidden", "y se vuelve a esconder (%s)" % mole.state)
	# pisarlo cuando está fuera lo derrota
	pl.global_position = Vector2(30 * 16 + 8 - 44, 14 * 16)
	await _until(func(): return mole.state == "up", 160)
	pl.global_position = Vector2(30 * 16 + 8, 15 * 16 - 10 - 14)
	pl.velocity = Vector2(0, 80)
	pl._invuln_t = 0.0
	await _frames(8)
	_check(mole.dead, "el topo que está fuera se derrota pisándolo")
	await _end_mini(lvl)
	# ---- guardián ----
	g = Grid.new(80, 20)
	g.ground(0, 80, 15)
	g.fill(50, 10, 51, 15, "#")
	g.put(40, 14, "D")
	g.put(5, 14, "P")
	lvl = await _mini(g)
	pl = lvl.player
	var gd = _enemy_of(lvl, "guard")
	_check(gd != null and not gd.stompable, "el guardián no se puede pisar mientras está en guardia")
	pl.global_position = Vector2(40 * 16 - 60, 14 * 16)
	pl.velocity = Vector2.ZERO
	await _frames(4)
	await _until(func(): return gd.state == "wind", 90)
	_check(gd.state == "wind", "si le miras de frente se prepara (aviso)")
	await _until(func(): return gd.state == "charge", 60)
	_check(gd.state == "charge", "y carga contra ti")
	var x_at: float = gd.position.x
	await _until(func(): return gd.state == "stun", 120)
	_check(gd.state == "stun" and gd.stompable, "al terminar la carga queda aturdido y entonces sí es vulnerable")
	var hpg: int = pl.hp
	gd.take_hit("spark")
	_check(gd.dead, "aturdido, un disparo lo derrota")
	await _end_mini(lvl)
	g = Grid.new(80, 20)
	g.ground(0, 80, 15)
	g.put(40, 14, "D")
	g.put(5, 14, "P")
	lvl = await _mini(g)
	pl = lvl.player
	gd = _enemy_of(lvl, "guard")
	gd.take_hit("spark")
	_check(not gd.dead, "con el escudo en guardia el disparo no le hace nada")
	pl.global_position = Vector2(gd.position.x, gd.position.y - 30)
	pl.velocity = Vector2(0, 120)
	pl._invuln_t = 0.0
	var hp1: int = pl.hp
	await _frames(8)
	_check(not gd.dead and pl.hp == hp1 and pl.velocity.y < 0.0, "caer sobre su cabeza te hace rebotar sin daño ni derrotarlo")
	await _end_mini(lvl)
	# ---- murciélago ----
	g = Grid.new(60, 20)
	g.ground(0, 60, 15)
	g.fill(25, 4, 36, 5, "#")
	g.put(30, 5, "Y")
	g.put(5, 14, "P")
	lvl = await _mini(g)
	pl = lvl.player
	var bat = _enemy_of(lvl, "bat")
	var home: Vector2 = bat.position
	_check(bat.state == "hang", "el murciélago cuelga del techo")
	pl.global_position = Vector2(30 * 16 + 8, 14 * 16)
	pl.velocity = Vector2.ZERO
	await _until(func(): return bat.state == "warn", 120)
	_check(bat.state == "warn", "al pasar debajo bate las alas (aviso)")
	await _until(func(): return bat.state == "dive", 60)
	_check(bat.state == "dive" and bat.velocity.length() > 150.0 and bat.velocity.y > 0.0, "y se lanza en picado hacia ti (%.0f px/s)" % bat.velocity.length())
	pl.global_position = Vector2(16 * 16, 14 * 16)  # nos apartamos
	await _until(func(): return bat.state == "rise", 120)
	await _until(func(): return bat.state == "hang", 400)
	_check(bat.state == "hang" and bat.position.distance_to(home) < 5.0, "después vuelve a su sitio del techo")
	await _end_mini(lvl)
	# ---- lanzarrocas ----
	g = Grid.new(80, 20)
	g.ground(0, 80, 15)
	g.put(50, 14, "0")
	g.put(5, 14, "P")
	lvl = await _mini(g)
	pl = lvl.player
	var lob = _enemy_of(lvl, "lobber")
	pl.global_position = Vector2(50 * 16 - 120, 14 * 16)
	pl.velocity = Vector2.ZERO
	var rock = null
	for i in range(400):
		await physics_frame
		pl.global_position.x = 50 * 16 - 120
		var rs: Array = lvl.get_children().filter(func(n): return n is Area2D and n.get_script() != null and "G" in n and "_life" in n)
		if not rs.is_empty():
			rock = rs[0]
			break
	_check(rock != null, "el lanzarrocas lanza una roca cuando estás a tiro")
	var peak: float = rock.position.y
	var hp2: int = pl.hp
	pl._invuln_t = 0.0
	var apex_ok := false
	for i in range(240):
		await physics_frame
		pl.velocity = Vector2.ZERO
		pl.global_position.x = 50 * 16 - 120
		if is_instance_valid(rock):
			peak = minf(peak, rock.position.y)
		else:
			break
	_check(peak < rock.position.y - 0.0 if is_instance_valid(rock) else peak < 14 * 16 - 10.0, "la roca describe una parábola (sube y baja; cima en y=%.0f)" % peak)
	_check(pl.hp < hp2, "y si no te mueves te alcanza")
	_check(lob.stompable, "el lanzarrocas se puede pisar")
	await _end_mini(lvl)
	# ---- prensa ----
	g = Grid.new(60, 20)
	g.ground(0, 60, 15)
	g.fill(28, 2, 32, 3, "#")
	g.put(5, 14, "P")
	lvl = await _mini(g, "@press 29,4,2\n")
	pl = lvl.player
	var pr = lvl.get_children().filter(func(n): return n.get_script() != null and n.get_script().resource_path == "res://items/ww_press.gd")
	_check(pr.size() == 1 and pr[0].cells == 2 and pr[0].drop_px > 100.0, "la prensa de 2 celdas llega hasta el suelo (%.0f px)" % (pr[0].drop_px if pr.size() > 0 else 0.0))
	pr = pr[0]
	var seen := {}
	for i in range(260):
		await physics_frame
		seen[pr.phase_name] = true
		pl.global_position = Vector2(20 * 16, 14 * 16)  # a salvo, fuera de su zona
	_check(seen.has("up") and seen.has("warn") and seen.has("fall") and seen.has("down") and seen.has("rise"), "ciclo completo: reposo, aviso, caída, abajo y subida")
	pr._t = 0.0
	var hp3: int = pl.hp
	pl.global_position = Vector2(30 * 16 - 8 + 8, 14 * 16)
	pl._invuln_t = 0.0
	await _frames(40)
	_check(pl.hp == hp3, "debajo de la prensa elevada no hay peligro")
	await _until(func(): return pl.hp < hp3, 120)
	_check(pl.hp < hp3, "la prensa que cae te hace daño")
	pr._t = 0.0
	pl.global_position = Vector2(24 * 16, 14 * 16)
	pl._invuln_t = 0.0
	var hp4: int = pl.hp
	await _frames(200)
	_check(pl.hp == hp4, "a un lado de la prensa estás a salvo")
	await _end_mini(lvl)


func _test_ww_mechanics() -> void:
	_wipe_ww_files()
	_ww.reset()
	await _test_ww_doors()
	await _test_ww_enemies()
	await _test_ww_mech_shrooms()
	await _test_ww_mech_vine()
	await _test_ww_mech_logs()
	await _test_ww_mech_phase_bridge()
	await _test_ww_mech_switch()
	await _test_ww_mech_water_hazards()
	await _test_ww_tall_level()
	await _test_ww_lab()
	_ww.reset()
	_wipe_ww_files()
