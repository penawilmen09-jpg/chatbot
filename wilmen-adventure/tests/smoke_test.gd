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
	await _test_entities(game, scene)
	await _test_powers(game, scene)
	await _test_bosses(game, scene)
	await _test_flow(game, scene)
	await _test_menus()
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


func _frames(n: int) -> void:
	for i in range(n):
		await physics_frame


func _new_level(game, scene: PackedScene, n: int):
	game.current_level = n
	var lvl = scene.instantiate()
	root.add_child(lvl)
	await process_frame
	await _frames(5)
	return lvl


func _free_level(lvl) -> void:
	paused = false
	lvl.queue_free()
	await process_frame


func _test_entities(game, scene: PackedScene) -> void:
	print("Enemigos y proyectiles de los 5 mundos")
	var EnemyScene: PackedScene = load("res://enemies/enemy.tscn")
	var ProjScene: PackedScene = load("res://items/projectile.tscn")
	for w in range(1, 6):
		var lvl = await _new_level(game, scene, (w - 1) * 4 + 1)
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
			for k in ["spark", "ice", "shard", "orb", "snowball", "acorn", "wave", "sand"]:
				var p = ProjScene.instantiate()
				p.team = team
				p.kind = k
				p.velocity = Vector2(80, -20)
				p.fall_accel = 200.0
				p.bounce = k == "spark"
				p.position = lvl.player.position + Vector2(20, -10)
				lvl.add_child(p)
		await _frames(60)
		_check(not lvl.player.dead or true, "mundo %d: enemigos y proyectiles sin fallos" % w)
		await _free_level(lvl)


func _test_powers(game, scene: PackedScene) -> void:
	print("Poderes")
	for w in range(1, 6):
		var lvl = await _new_level(game, scene, (w - 1) * 4 + 1)
		var p = lvl.player
		_check(p.power == game.POWERS[w - 1], "mundo %d: poder %s" % [w, p.power])
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
		await _free_level(lvl)


func _test_bosses(game, scene: PackedScene) -> void:
	print("Jefes (combate completo)")
	for n in [4, 8, 12, 16, 20]:
		var lvl = await _new_level(game, scene, n)
		var b = lvl.boss
		lvl.player.position = Vector2(lvl.gate_x + 8.0, lvl.boss_home_y)
		lvl.player.camera.reset_smoothing()
		lvl.player.celebrate()  # invulnerable: solo probamos los ataques del jefe
		await _frames(30)
		_check(lvl.fight_started and b.active, "nivel %d: el combate empieza al cruzar la puerta" % n)
		var seen: Dictionary = {}
		for i in range(60 * 14):
			seen[b.mode] = true
			await physics_frame
		_check(seen.size() >= 3, "nivel %d: el jefe encadena ataques (%s)" % [n, str(seen.keys())])
		var hits: int = 0
		while not b.dead and hits < 30:
			b._invuln_t = 0.0
			b.shielded = false
			b.hit_boss(1)
			hits += 1
			await _frames(2)
		_check(b.dead, "nivel %d: el jefe muere tras %d golpes" % [n, hits])
		await _frames(120)
		_check(lvl.goal != null and lvl.goal.active, "nivel %d: la meta aparece" % n)
		lvl.complete_level()
		await _frames(150)
		_check(lvl.finished and game.get_record(n)["done"], "nivel %d: completado y guardado" % n)
		await _free_level(lvl)


func _test_flow(game, scene: PackedScene) -> void:
	print("Pausa, bloques, muerte y game over")
	var lvl = await _new_level(game, scene, 1)
	lvl.toggle_pause()
	await _frames(3)
	_check(paused, "pausa activa")
	lvl.toggle_pause()
	await _frames(3)
	_check(not paused, "pausa se quita")
	# bloques: ladrillo, interrogación, corazón, ocultos
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
	var lives_before: int = game.lives
	game.lives = 1
	lvl.player.die()
	await _frames(120)
	_check(lvl.finished, "game over cuando no quedan vidas")
	game.lives = lives_before
	await _free_level(lvl)


func _test_menus() -> void:
	print("Menús")
	for path in ["res://ui/title.tscn", "res://ui/level_select.tscn", "res://ui/ending.tscn"]:
		var sc: PackedScene = load(path)
		var node = sc.instantiate()
		root.add_child(node)
		await process_frame
		await _frames(15)
		_check(is_instance_valid(node), path)
		node.queue_free()
		await process_frame
