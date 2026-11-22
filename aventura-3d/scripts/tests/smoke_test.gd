extends SceneTree
## Prueba automática de movimiento y colisiones.
## Ejecutar:  godot --headless --fixed-fps 60 --path . -s res://scripts/tests/smoke_test.gd

var failures := 0
var player: Player
var main: Node


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func check(cond: bool, msg: String) -> void:
	if cond:
		print("  OK   ", msg)
	else:
		failures += 1
		print("  FAIL ", msg)


func frames(n: int) -> void:
	for i in n:
		await physics_frame


func hold(action: StringName, down: bool) -> void:
	if down:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _run() -> void:
	player = main.get_node("Player")
	var cam: Camera3D = main.get_node("SideCamera")

	print("[1] Aterrizaje en el suelo")
	await frames(90)
	check(player.is_on_floor(), "el jugador está sobre el suelo")
	check(absf(player.global_position.y) < 0.05, "altura de pies ≈ 0 (y=%.3f)" % player.global_position.y)
	check(is_zero_approx(player.global_position.z), "plano de juego z = 0")

	print("[2] Caminar a la derecha")
	var x0 := player.global_position.x
	hold(InputSetup.ACTION_RIGHT, true)
	await frames(60)
	var walked := player.global_position.x - x0
	check(walked > 4.0 and walked < 7.5, "camina ~6 u/s (%.2f en 1 s)" % walked)
	check(absf(player.velocity.x - player.walk_speed) < 0.2, "velocidad = walk_speed")

	print("[3] Correr")
	hold(InputSetup.ACTION_RUN, true)
	await frames(30)
	check(absf(player.velocity.x - player.run_speed) < 0.3, "velocidad = run_speed (%.2f)" % player.velocity.x)
	hold(InputSetup.ACTION_RUN, false)
	hold(InputSetup.ACTION_RIGHT, false)
	await frames(30)
	check(absf(player.velocity.x) < 0.1, "frena al soltar")

	print("[4] Salto (altura)")
	var y_peak := 0.0
	hold(InputSetup.ACTION_JUMP, true)
	for i in 80:
		await physics_frame
		y_peak = maxf(y_peak, player.global_position.y)
		if i == 2:
			hold(InputSetup.ACTION_JUMP, true)
	hold(InputSetup.ACTION_JUMP, false)
	check(y_peak > 2.5 and y_peak < 3.6, "altura de salto %.2f" % y_peak)
	await frames(60)
	check(player.is_on_floor(), "vuelve a aterrizar")

	print("[5] Salto corto (soltar el botón)")
	y_peak = 0.0
	hold(InputSetup.ACTION_JUMP, true)
	await frames(3)
	hold(InputSetup.ACTION_JUMP, false)
	for i in 60:
		await physics_frame
		y_peak = maxf(y_peak, player.global_position.y)
	check(y_peak > 0.4 and y_peak < 2.3, "salto corto %.2f < salto completo" % y_peak)
	await frames(30)

	print("[6] Doble salto desactivado / activado")
	hold(InputSetup.ACTION_JUMP, true)
	await frames(2)
	hold(InputSetup.ACTION_JUMP, false)
	await frames(20)
	var vy_before := player.velocity.y
	hold(InputSetup.ACTION_JUMP, true)
	await frames(2)
	hold(InputSetup.ACTION_JUMP, false)
	check(player.velocity.y < vy_before + 1.0, "sin doble salto: no hay impulso extra")
	await frames(90)
	player.double_jump_enabled = true
	hold(InputSetup.ACTION_JUMP, true)
	await frames(2)
	hold(InputSetup.ACTION_JUMP, false)
	await frames(20)
	var vy2 := player.velocity.y
	hold(InputSetup.ACTION_JUMP, true)
	await frames(2)
	hold(InputSetup.ACTION_JUMP, false)
	check(player.velocity.y > vy2 + 3.0, "con doble salto: impulso extra (%.1f → %.1f)" % [vy2, player.velocity.y])
	player.double_jump_enabled = false
	await frames(90)

	print("[7] Límite izquierdo")
	hold(InputSetup.ACTION_LEFT, true)
	hold(InputSetup.ACTION_RUN, true)
	await frames(240)
	hold(InputSetup.ACTION_LEFT, false)
	hold(InputSetup.ACTION_RUN, false)
	check(player.global_position.x >= player.min_x - 0.01, "no sale del nivel por la izquierda (x=%.2f)" % player.global_position.x)

	print("[8] Recorrido completo con un bot (corre y salta huecos, muros y plataformas)")
	player.set_spawn(Vector3(-8, 0.5, 0))
	await frames(10)
	var stats := {"respawns": 0, "max_x": -99.0}
	player.respawned.connect(func(): stats.respawns += 1)
	hold(InputSetup.ACTION_RIGHT, true)
	hold(InputSetup.ACTION_RUN, true)
	var space := player.get_world_3d().direct_space_state
	for i in 3600:
		var p := player.global_position
		if player.is_on_floor():
			var ahead_gap := space.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3(1.0, 1.0, 0), p + Vector3(1.0, -2.5, 0), 1))
			var wall := space.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3(0, 0.4, 0), p + Vector3(1.6, 0.4, 0), 1))
			var wall_hi := space.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3(0, 0.4, 0), p + Vector3(3.0, 0.4, 0), 1))
			if ahead_gap.is_empty() or not wall.is_empty() or (not wall_hi.is_empty() and i % 2 == 0):
				hold(InputSetup.ACTION_JUMP, true)
			else:
				hold(InputSetup.ACTION_JUMP, false)
		elif player.velocity.y < 0.0 and not player.is_on_floor():
			hold(InputSetup.ACTION_JUMP, false)
		await physics_frame
		stats.max_x = maxf(stats.max_x, player.global_position.x)
		if stats.max_x > 132.0:
			break
	hold(InputSetup.ACTION_JUMP, false)
	hold(InputSetup.ACTION_RIGHT, false)
	hold(InputSetup.ACTION_RUN, false)
	print("  info x=%.1f max_x=%.1f respawns=%d" % [player.global_position.x, stats.max_x, stats.respawns])
	check(stats.max_x > 130.0, "el bot llega al final del nivel (bandera)")
	await frames(30)

	print("[9] Caída al agua → reaparece")
	player.global_position = Vector3(24.0, 1.0, 0.0)
	player.velocity = Vector3.ZERO
	var r0: int = stats.respawns
	await frames(120)
	check(stats.respawns > r0, "respawn al caer al hueco")
	check(player.global_position.distance_to(player.spawn_position) < 0.5 or player.global_position.x < 0.0, "vuelve al punto de inicio")

	print("[10] Cámara sigue al jugador")
	player.global_position = Vector3(60.0, 3.0, 0.0)
	await frames(120)
	check(absf(cam.global_position.x - player.global_position.x) < 4.0, "cámara cerca del jugador en X (cam %.1f, jugador %.1f)" % [cam.global_position.x, player.global_position.x])

	print("")
	print("RESULTADO: ", "TODO CORRECTO" if failures == 0 else "%d FALLOS" % failures)
	quit(failures)
