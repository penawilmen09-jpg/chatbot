extends SceneTree
## Recorrido del lago del 2-2 con un jugador virtual SIN invulnerabilidad: corre, espera en el borde y salta cuando hay una plataforma
## (fija o móvil) a su alcance. Cada intento empieza con un desfase distinto de las plataformas móviles.
##   godot --headless --path . --script res://tests/lake_check.gd
var bad: int = 0
const START := Vector2i(68, 21)
const END_X := 183.0 * 16.0


func _initialize() -> void:
	_run.call_deferred()


func _movers(lvl) -> Array:
	return lvl.get_children().filter(func(n): return n.get_script() != null and n.get_script().resource_path == "res://items/mover.gd")


func _solid(lvl, cx: int, cy: int) -> bool:
	return "#=B_".contains(lvl._cell(cx, cy))


func _supported(lvl, px: float, feet: float) -> bool:
	if _solid(lvl, int(px / 16.0), int((feet + 2.0) / 16.0)):
		return true
	for m in _movers(lvl):
		if absf(m.position.x - px) <= 18.0 and absf(m.position.y - 4.0 - feet) <= 8.0:
			return true
	return false


func _target(lvl, px: float, feet: float, maxdx: int = 4) -> Dictionary:
	## Superficie (fija o móvil, con su posición actual) a un salto por delante: {"top": px, "left": px} o {}.
	var cx: int = int(px / 16.0)
	var frow: int = int((feet + 2.0) / 16.0)
	for dx in range(2, maxdx + 1):
		for r in range(frow - 3, frow + 4):
			if _solid(lvl, cx + dx, r) and not _solid(lvl, cx + dx, r - 1):
				return {"top": float(r * 16), "left": float((cx + dx) * 16)}
	for m in _movers(lvl):
		var left: float = m.position.x - 16.0
		var top: float = m.position.y - 4.0
		if left >= px - 4.0 and left <= px + 40.0 and top >= feet - 24.0 and top <= feet + 12.0:
			return {"top": top, "left": left}
	return {}


func _try(lvl, game, delay: int) -> Dictionary:
	var pl = lvl.player
	pl.global_position = Vector2(START.x * 16 + 8, START.y * 16 + 6)
	pl.velocity = Vector2.ZERO
	lvl.camera.reset_smoothing()
	for i in range(delay):
		await physics_frame
	var lives0: int = game.lives
	var jt: int = -99
	var dbl: bool = false
	var idle: int = 0
	for i in range(6000):
		await physics_frame
		if pl.dead or game.lives < lives0:
			Input.action_release("move_right")
			Input.action_release("jump")
			return {"ok": false, "why": ("CAIDA" if pl.global_position.y > 28.0 * 16.0 else "ENEMIGO") + " en x=%d y=%d vy=%d hp=%s (frame %d)" % [int(pl.global_position.x / 16.0), int(pl.global_position.y / 16.0), int(pl.velocity.y), str(pl.hp), i]}
		var feet: float = pl.global_position.y + 10.0
		if OS.get_cmdline_user_args().has("trace") and delay == int(OS.get_cmdline_user_args()[OS.get_cmdline_user_args().find("trace") + 1]) and i % 6 == 0:
			print("   t=%d pos=(%.0f,%.0f) v=(%.0f,%.0f) floor=%s" % [i, pl.global_position.x, pl.global_position.y, pl.velocity.x, pl.velocity.y, str(pl.is_on_floor())])
		if pl.global_position.x >= END_X and pl.is_on_floor():
			Input.action_release("move_right")
			Input.action_release("jump")
			return {"ok": true, "frames": i}
		if pl.is_on_floor():
			dbl = false
			if absf(pl.velocity.x) > 20.0:
				idle = 0
			if i - jt > 10:
				Input.action_release("jump")
			if _supported(lvl, pl.global_position.x + 12.0, feet):
				Input.action_press("move_right")
			elif not _target(lvl, pl.global_position.x, feet).is_empty():
				Input.action_press("move_right")
				Input.action_press("jump")
				jt = i
			else:
				idle += 1
				if idle > 90:
					Input.action_press("move_right")  # sin plataforma a la vista: se deja caer (p. ej. bajar de una repisa a la isla)
				else:
					Input.action_release("move_right")
		else:
			Input.action_press("move_right")
			if i - jt > 14:
				Input.action_release("jump")
			var tg: Dictionary = _target(lvl, pl.global_position.x - 24.0, feet - 6.0, 6)
			if pl.velocity.y > 60.0 and not dbl and not tg.is_empty() and feet > float(tg["top"]) + 4.0 and float(tg["left"]) > pl.global_position.x - 8.0:
				dbl = true
				Input.action_release("jump")
				await physics_frame
				Input.action_press("jump")
				jt = i
	Input.action_release("move_right")
	Input.action_release("jump")
	return {"ok": false, "why": "no llego (x=%d)" % int(pl.global_position.x / 16.0)}


func _run() -> void:
	var ww = root.get_node("WW")
	var game = root.get_node("Game")
	ww.save_path = "user://lake_check_save.json"
	ww.test_text = ""
	ww.reset()
	ww.start_level(22)
	var lvl = load("res://levels/ww_level.tscn").instantiate()
	root.add_child(lvl)
	await process_frame
	for i in range(10):
		await physics_frame
	if is_instance_valid(lvl.hud._intro):
		lvl.hud._intro.queue_free()
		lvl.hud._intro = null
	game.lives = 99
	# estar quieto encima de cada plataforma movil: sin resbalar, sin empujes y sin perder vida
	for m in _movers(lvl):
		var pl0 = lvl.player
		await physics_frame
		pl0.global_position = Vector2(m.position.x, m.position.y - 14.0)
		pl0.velocity = Vector2.ZERO
		pl0._invuln_t = 100000.0  # solo en esta comprobacion de fisica de apoyo (los recorridos NO usan invulnerabilidad)
		for i in range(30):
			await physics_frame
		var off0: float = pl0.global_position.x - m.position.x
		var drift: float = 0.0
		var on_it: int = 0
		for i in range(300):
			await physics_frame
			drift = maxf(drift, absf((pl0.global_position.x - m.position.x) - off0))
			if OS.get_cmdline_user_args().has("ride") and i % 20 == 0 and int(m.position.x / 16.0) in range(115, 125):
				print("   i=%d pl=(%.1f,%.1f) m=(%.1f,%.1f) vel=%.0f hp=%s lives=%d" % [i, pl0.global_position.x, pl0.global_position.y, m.position.x, m.position.y, pl0.velocity.x, str(pl0.hp), game.lives])
			if pl0.is_on_floor():
				on_it += 1
		var good: bool = drift < 4.0 and on_it >= 290 and not pl0.dead
		print("  %s plataforma movil en (%d,%d): deriva maxima respecto a ella %.1f px, apoyado %d/300 fotogramas" % ["ok  " if good else "FALLO", int(m.position.x / 16.0), int(m.position.y / 16.0), drift, on_it])
		if not good:
			bad += 1
	lvl.player._invuln_t = 0.0
	var ok: int = 0
	var falls: int = 0
	var delays: Array = [0, 40, 90, 150, 210, 270, 330, 400]
	for d in delays:
		if game.lives < 90:
			game.lives = 99
		var r: Dictionary = await _try(lvl, game, d)
		print("  intento (desfase %3d): %s" % [d, ("OK en %.1f s" % (float(r["frames"]) / 60.0)) if r["ok"] else ("FALLO " + str(r["why"]))])
		if r["ok"]:
			ok += 1
		else:
			if str(r["why"]).begins_with("CAIDA"):
				falls += 1
			await _wait_alive(lvl)
	print("RESULTADO: %d/%d intentos completan el lago sin invulnerabilidad (%d caidas)" % [ok, delays.size(), falls])
	quit(0 if falls == 0 and bad == 0 else 1)


func _wait_alive(lvl) -> void:
	for i in range(400):
		await physics_frame
		if not lvl.player.dead:
			break
	for i in range(30):
		await physics_frame
