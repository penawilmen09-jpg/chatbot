extends SceneTree
## Captura imágenes del juego en varias posiciones (requiere render, no headless).
## xvfb-run -a godot --path . --rendering-driver opengl3 -s res://scripts/tests/screenshot.gd -- <carpeta>

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "/tmp"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var player: Player = main.get_node("Player")
	var spots := [
		["start", Vector3(-8, 0.5, 0), 0.0, false],
		["run", Vector3(10, 0.5, 0), 10.0, false],
		["jump", Vector3(31.0, 0.5, 0), 6.0, true],
		["floating", Vector3(64, 5.5, 0), 0.0, false],
		["end", Vector3(128, 7.5, 0), 0.0, false],
	]
	for s in spots:
		player.global_position = s[1]
		player.velocity = Vector3(s[2], 0, 0)
		player.model.facing = 1.0
		player.reset_physics_interpolation()
		main.get_node("SideCamera").snap_to_target()
		if s[2] > 0.0:
			Input.action_press(InputSetup.ACTION_RIGHT)
			Input.action_press(InputSetup.ACTION_RUN)
		for i in 40:
			await physics_frame
		if s[3]:
			Input.action_press(InputSetup.ACTION_JUMP)
			for i in 14:
				await physics_frame
		Input.action_release(InputSetup.ACTION_RIGHT)
		Input.action_release(InputSetup.ACTION_RUN)
		Input.action_release(InputSetup.ACTION_JUMP)
		await process_frame
		await process_frame
		var img := root.get_viewport().get_texture().get_image()
		img.save_png("%s/shot_%s.png" % [out, s[0]])
		print("saved ", s[0], " ", img.get_size())
	quit()
