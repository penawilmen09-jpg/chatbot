extends SceneTree
## Capturas de la bola de fuego en vuelo y al estallar contra un enemigo (Xvfb):
##   xvfb-run -a godot --path . --resolution 1170x540 --rendering-driver opengl3 --audio-driver Dummy --script res://tests/fire_shot.gd -- /tmp/shots


func _initialize() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in range(n):
		await physics_frame


func _run() -> void:
	var dir: String = "/tmp/shots"
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		dir = args[0]
	DirAccess.make_dir_recursive_absolute(dir)
	var ww = root.get_node("WW")
	ww.save_path = "user://fire_shot_save.json"
	ww.test_text = ""
	ww.start_level(ww.LAB)
	var lvl = load("res://levels/ww_level.tscn").instantiate()
	root.add_child(lvl)
	await process_frame
	await _frames(10)
	if is_instance_valid(lvl.hud._intro):
		lvl.hud._intro.queue_free()
		lvl.hud._intro = null
	var pl = lvl.player
	pl._invuln_t = 1000000.0
	pl.power = "fireball"
	pl.skill_cd_max = 0.7
	pl.global_position = Vector2(8.0 * 16.0, 24.0 * 16.0)
	pl.velocity = Vector2.ZERO
	pl.facing = 1
	lvl.camera.reset_smoothing()
	await _frames(30)
	var E = load("res://enemies/enemy.tscn")
	var en = E.instantiate()
	en.kind = "walker"
	en.world = 1
	en.level = lvl
	en.position = Vector2(52.0 * 16.0, 24.0 * 16.0 + 8.0)
	lvl.add_child(en)
	await _frames(4)
	pl.skill_cd = 0.0
	pl._use_skill()
	await _frames(8)
	root.get_viewport().get_texture().get_image().save_png(dir + "/bola_en_vuelo.png")
	await _frames(40)
	root.get_viewport().get_texture().get_image().save_png(dir + "/bola_cerca.png")
	await _frames(14)
	root.get_viewport().get_texture().get_image().save_png(dir + "/bola_explosion.png")
	print("enemigo derrotado: ", en.dead)
	quit(0)
