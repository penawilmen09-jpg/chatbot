extends SceneTree
## Prueba de FLUJO REAL: recorre el juego como un jugador, con cambios de escena de verdad (Transition),
## botones de verdad y una partida guardada "como la tuya" (14 niveles, 26 gemas, 63.470 puntos).
##
##   godot --headless --path . --script res://tests/flow_test.gd
##
## Detecta pantallas congeladas (una transición que no termina), botones que dejan de responder,
## pérdida de progreso al rejugar niveles anteriores y fotogramas anormalmente largos.
## Los errores del motor en el log (p. ej. tweens en bucle sobre objetos liberados) los vigila el CI.

var _failed: int = 0
var _game
var _tr
var _max_gap_ms: int = 0
var _last_ms: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _check(cond: bool, msg: String) -> void:
	print("  ", "ok   " if cond else "FALLO ", msg)
	if not cond:
		_failed += 1


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame
		var now: int = Time.get_ticks_msec()
		if _last_ms > 0:
			_max_gap_ms = maxi(_max_gap_ms, now - _last_ms)
		_last_ms = now


func _wait_idle(timeout_ms: int = 9000) -> bool:
	## Espera a que no haya transición en curso y exista una escena actual. Falso = "congelado".
	var t0: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < timeout_ms:
		if not _tr.is_busy() and current_scene != null:
			await _frames(3)
			return true
		await _frames(1)
	return false


func _find_button(node: Node, text: String):
	if node is Button and (node as Button).text == text:
		return node
	for c in node.get_children():
		var r = _find_button(c, text)
		if r != null:
			return r
	return null


func _press(btn) -> void:
	btn.pressed.emit()
	await _frames(2)


func _snapshot() -> Dictionary:
	return {"done": _game.completed_count(), "gems": _game.total_gems(), "unlocked": _game.unlocked.size(),
		"score": _game.score, "worlds": _game.worlds_done.size()}


func _go(path: String) -> bool:
	_tr.change_scene(path)
	return await _wait_idle()


func _make_user_like_save() -> void:
	# Guardado ANTIGUO (v1, 20 niveles) con los valores de la partida de ejemplo
	var levels := {}
	for k in range(1, 15):
		levels[str(k)] = {"done": true, "gems": [true, true, false] if k <= 13 else [false, false, false], "best": 4000 + k * 37}
	var old := {
		"version": 1, "lives": 4, "score": 63470, "coins": 57, "total_coins": 840, "highest_unlocked": 15,
		"levels": levels, "settings": {"music": true, "sfx": true, "touch": "auto"},
		"play_time_s": 12345, "stats": {"deaths": 31, "enemies": 402},
	}
	var f := FileAccess.open(_game.save_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(old))
	f.close()


func _run() -> void:
	_game = root.get_node("Game")
	_tr = root.get_node("Transition")
	_game.save_path = "user://flow_test_save.json"
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_game.save_path + suffix))
	for nm in ["_v1_backup", "_v2_backup", "_before_reset", "_before_restore"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://flow_test_save%s.json" % nm))

	print("== Partida de ejemplo (formato antiguo) ==")
	_make_user_like_save()
	_game.load_game()
	var base: Dictionary = _snapshot()
	_check(base["done"] == 14 and base["gems"] == 26 and base["score"] == 63470, "partida cargada: 14 niveles, 26 gemas, 63470 puntos (%s)" % str(base))
	_check(_game.is_unlocked(33), "el nivel abierto más alto del guardado antiguo (15 -> 33) sigue abierto")
	var snap0: Dictionary = _snapshot()

	print("== Título -> mapa ==")
	_check(await _go("res://ui/title.tscn"), "se abre el título")
	_check(await _go("res://ui/level_select.tscn"), "se abre el mapa")
	var map = current_scene
	_check(map != null and map.get("_grid") != null, "la escena actual es el mapa")

	print("== Continuar: último nivel abierto ==")
	var cont = _find_button(map, "Continuar")
	_check(cont != null, "existe el botón Continuar")
	await _press(cont)
	_check(await _wait_idle(), "Continuar entra al nivel sin congelarse")
	var lvl = current_scene
	_check(lvl != null and lvl.get("number") == _game.continue_level() and lvl.player != null, "se cargó el nivel %d con jugador" % _game.continue_level())
	lvl.go_menu()
	_check(await _wait_idle(), "volver al mapa desde el nivel")

	print("== Repetir niveles anteriores, cambiar de mundo y volver (16 ciclos) ==")
	var plan: Array = [3, 2, 1, 10, 11, 13, 20, 21, 23, 30, 31, 32, 12, 22, 3, 33]
	for n in plan:
		map = current_scene
		if map.get("_grid") == null:
			_check(false, "se esperaba el mapa antes de elegir el nivel %d" % n)
			break
		var w: int = _game.world_of(n)
		# cambiar de mundo con la ficha (como un toque real)
		var chip = map._chips.get_child(w - 1)
		await _press(chip)
		_check(map._world == w, "ficha del mundo %d -> el mapa muestra ese mundo" % w)
		var idx: int = _game.index_in_world(n) - 1
		var btn = map._grid.get_child(idx)
		await _press(btn)
		var ok: bool = await _wait_idle()
		lvl = current_scene
		var loaded: bool = ok and lvl != null and lvl.get("number") == n and lvl.player != null
		_check(loaded, "nivel %d (anterior) carga y se puede jugar" % n)
		if not loaded:
			break
		# jugar un poco y terminarlo
		await _frames(20)
		lvl.complete_level()
		var t0: int = Time.get_ticks_msec()
		while lvl.hud != null and lvl.hud._overlay == null and Time.get_ticks_msec() - t0 < 6000:
			await _frames(5)
		var back = null
		if lvl.hud != null and lvl.hud._overlay != null:
			back = _find_button(lvl.hud._overlay, "Mapa de niveles")
		_check(back != null, "pantalla de resultados del nivel %d con botón Mapa" % n)
		if back == null:
			break
		await _press(back)
		_check(await _wait_idle(), "tras terminar el nivel %d se vuelve al mapa" % n)
		var snap: Dictionary = _snapshot()
		_check(snap["done"] >= snap0["done"] and snap["gems"] >= snap0["gems"] and snap["unlocked"] >= snap0["unlocked"] and snap["score"] >= snap0["score"],
			"rejugar el nivel %d no pierde progreso (%s)" % [n, str(snap)])
		snap0 = snap

	print("== Salir con el menú de pausa ==")
	map = current_scene
	if map.get("_grid") != null:
		await _press(map._chips.get_child(0))
		await _press(map._grid.get_child(0))
		_check(await _wait_idle(), "entrar al nivel 1 otra vez")
		lvl = current_scene
		lvl.toggle_pause()
		await _frames(3)
		var salir = _find_button(lvl.hud._overlay, "Salir al mapa")
		_check(salir != null, "el menú de pausa tiene Salir al mapa")
		await _press(salir)
		_check(await _wait_idle(), "Salir al mapa desde la pausa")
		_check(not paused, "el juego no queda en pausa tras salir")

	print("== Toques repetidos y simultáneos ==")
	map = current_scene
	if map.get("_grid") != null:
		await _press(map._chips.get_child(0))
		# dos botones distintos y el mismo otra vez en el mismo fotograma
		map._grid.get_child(1).pressed.emit()
		map._grid.get_child(2).pressed.emit()
		map._grid.get_child(1).pressed.emit()
		var ok2: bool = await _wait_idle()
		_check(ok2, "toques repetidos: la transición termina (no se congela)")
		lvl = current_scene
		_check(lvl != null and lvl.get("player") != null and not _tr.is_busy(), "toques repetidos: queda un único nivel jugable")
		lvl.go_menu()
		_check(await _wait_idle(), "y se puede volver al mapa")

	print("== Cambios de mundo seguidos en el mapa (50 pulsaciones) ==")
	map = current_scene
	if map.get("_grid") != null:
		for i in range(50):
			var w2: int = 1 + (i * 3) % 5
			if _game.is_world_unlocked(w2):
				await _press(map._chips.get_child(w2 - 1))
		await _frames(30)
		_check(map._grid.get_child_count() >= 10, "el mapa sigue respondiendo tras 50 cambios de mundo")
		_check(await _go("res://ui/title.tscn"), "se puede volver al título")

	print("== Progreso final ==")
	var fin: Dictionary = _snapshot()
	_check(fin["done"] >= 14 and fin["gems"] >= 26 and fin["score"] >= 63470, "no se perdió nada de la partida de ejemplo (%s)" % str(fin))
	print("  (mayor pausa entre fotogramas: %d ms; transiciones: %d)" % [_max_gap_ms, _tr.scenes_changed])
	_check(_max_gap_ms < 4000, "ninguna pausa de más de 4 s entre fotogramas")
	print("RESULTADO: %s" % ("TODO OK" if _failed == 0 else "%d fallos" % _failed))
	quit(0 if _failed == 0 else 1)
