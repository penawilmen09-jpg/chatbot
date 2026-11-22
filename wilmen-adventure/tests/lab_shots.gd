extends SceneTree
## Capturas del Taller de mecánicas (ww_950) con Xvfb, una por estación, en pantalla de móvil apaisada:
##   xvfb-run -a godot --path . --resolution 1170x540 --rendering-driver opengl3 --audio-driver Dummy --script res://tests/lab_shots.gd -- /tmp/shots
const STATIONS := [["1_setas", 33, 24], ["2_lianas", 80, 24], ["3_troncos", 143, 24], ["4_desaparecen", 165, 24],
	["5_puente", 215, 24], ["6_interruptores", 255, 24], ["7_corrientes", 322, 24], ["7b_burbujas", 358, 24],
	["8_dardos_pendulo", 392, 24], ["9_orbital", 403, 24], ["9b_ascensor", 427, 24]]


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
	ww.save_path = "user://lab_shots_save.json"
	ww.start_level(ww.LAB)
	var lvl = load("res://levels/ww_level.tscn").instantiate()
	root.add_child(lvl)
	await process_frame
	await _frames(10)
	if is_instance_valid(lvl.hud._intro):
		lvl.hud._intro.queue_free()
		lvl.hud._intro = null
	for s in STATIONS:
		lvl.player.global_position = Vector2(float(s[1]) * 16.0 + 8.0, float(s[2]) * 16.0)
		lvl.player.velocity = Vector2.ZERO
		lvl.camera.reset_smoothing()
		await _frames(50)
		var img: Image = root.get_viewport().get_texture().get_image()
		img.save_png("%s/lab_%s.png" % [dir, s[0]])
		print("captura ", s[0], " ", img.get_size())
	quit(0)
