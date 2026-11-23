extends SceneTree
## Comprueba el spawn de los niveles de WILMEN WORLD: pies apoyados, sin quedar dentro del terreno, reaparición en el mismo punto
## y una sola vida perdida por muerte.  godot --headless --path . --script res://tests/spawn_check.gd -- 21 22 23 24 25
var bad: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in range(n):
		await physics_frame


func _chk(ok: bool, msg: String) -> void:
	print(("  ok   " if ok else "  FALLO ") + msg)
	if not ok:
		bad += 1


func _run() -> void:
	var ww = root.get_node("WW")
	var game = root.get_node("Game")
	ww.save_path = "user://spawn_check_save.json"
	var levels: Array = []
	for a in OS.get_cmdline_user_args():
		levels.append(int(a))
	for n in levels:
		print("nivel ", n)
		ww.test_text = ""
		ww.reset()
		ww.start_level(n)
		var lvl = load("res://levels/ww_level.tscn").instantiate()
		root.add_child(lvl)
		await process_frame
		await _frames(10)
		if is_instance_valid(lvl.hud._intro):
			lvl.hud._intro.queue_free()
			lvl.hud._intro = null
		var p = lvl.player
		await _frames(60)
		var sp: Vector2 = lvl.spawn_pos
		print("   spawn_pos=", sp, " jugador=", p.global_position, " suelo=", p.is_on_floor())
		_chk(p.is_on_floor(), "%d: aparece con los pies apoyados (en el suelo)" % n)
		_chk(absf(p.global_position.x - sp.x) < 2.0 and absf(p.global_position.y - sp.y) < 3.0, "%d: no se desplaza al asentarse (spawn %s, tras 1 s %s)" % [n, str(sp), str(p.global_position)])
		var lives0: int = game.lives
		for k in range(4):
			p.die()
			await _frames(150)
			_chk(game.lives == lives0 - (k + 1), "%d: muerte %d: pierde exactamente 1 vida (vidas %d)" % [n, k + 1, game.lives])
			await _frames(60)
			var back: bool = p.global_position.distance_to(lvl.respawn_pos) < 3.0 and p.is_on_floor()
			_chk(back, "%d: muerte %d: reaparece en su punto, apoyado (pos %s, respawn %s)" % [n, k + 1, str(p.global_position), str(lvl.respawn_pos)])
			_chk(lvl.respawn_pos.distance_to(sp) < 1.0, "%d: y ese punto es el spawn inicial" % n)
		# cada punto de control: reaparecer ahí apoyado y perdiendo solo una vida
		var rows: Array = ww.parse_level(FileAccess.get_file_as_string(ww.level_path(n)))["rows"]
		for y in range(rows.size()):
			for x in range(rows[y].length()):
				if rows[y][x] != "C":
					continue
				if game.lives < 2:
					game.lives = 5
				var l1: int = game.lives
				lvl.set_checkpoint(Vector2(x * 16 + 8, y * 16 + 6))
				p.die()
				await _frames(20)
				for k in range(600):  # esperar a que reaparezca
					await physics_frame
					if not p.dead and game.lives < l1 and k > 60:
						break
				await _frames(8)
				var here: bool = p.is_on_floor() and p.global_position.distance_to(lvl.respawn_pos) < 3.0
				await _frames(120)
				_chk(here and game.lives == l1 - 1,
					"%d: punto de control (%d,%d): reaparece apoyado en su sitio y pierde solo 1 vida (vidas %d->%d)" % [n, x, y, l1, game.lives])
		lives0 = game.lives
		await _frames(240)
		_chk(game.lives == lives0, "%d: tras 4 s sin tocar nada no pierde más vidas (vidas %d)" % [n, game.lives])
		lvl.queue_free()
		await process_frame
	print("RESULTADO: ", "TODO OK" if bad == 0 else "%d fallos" % bad)
	quit(0 if bad == 0 else 1)
