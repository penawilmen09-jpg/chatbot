extends SceneTree
## Prueba de humo dentro del motor. Carga los 20 niveles, comprueba su contenido y deja
## jugar a un "bot" sencillo en el nivel 1.
##
## Uso (con Godot 4.3 instalado):
##   godot --headless --path . --import
##   godot --headless --path . --script res://tests/smoke_test.gd
## Termina con código 0 si todo está bien y 1 si algo falla.

var _failed: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok   ", msg)
	else:
		print("  FALLO ", msg)
		_failed += 1


func _run() -> void:
	var game = root.get_node("Game")
	var scene: PackedScene = load("res://levels/level.tscn")
	_check(scene != null, "level.tscn carga")
	for n in range(1, 21):
		print("Nivel %d" % n)
		game.current_level = n
		var lvl = scene.instantiate()
		root.add_child(lvl)
		await process_frame
		for i in range(20):
			await physics_frame
		_check(lvl.player != null, "jugador creado")
		_check(lvl.goal != null, "meta presente")
		_check(lvl._gem_counter == 3, "3 gemas (hay %d)" % lvl._gem_counter)
		_check(lvl.cols > 100, "mapa ancho (%d columnas)" % lvl.cols)
		_check(not lvl.player.dead, "el jugador sigue vivo al arrancar")
		if n % 4 == 0:
			_check(lvl.boss != null, "jefe presente")
			_check(lvl.gate_x > 0.0, "puerta de arena presente")
		lvl.queue_free()
		await process_frame
	await _bot_level_one(game, scene)
	print("RESULTADO: %s" % ("TODO OK" if _failed == 0 else "%d fallos" % _failed))
	quit(0 if _failed == 0 else 1)


func _bot_level_one(game, scene: PackedScene) -> void:
	print("Bot en el nivel 1 (8 s)")
	game.current_level = 1
	var lvl = scene.instantiate()
	root.add_child(lvl)
	await process_frame
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
	lvl.queue_free()
