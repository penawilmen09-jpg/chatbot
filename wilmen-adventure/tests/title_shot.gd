extends SceneTree
## Captura del menú principal con Xvfb: xvfb-run godot --path . --script res://tests/title_shot.gd -- salida.png
func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var g = root.get_node("Game")
	g.save_path = "user://title_shot_save.json"
	g.levels = {}
	for i in range(1, 80):
		g.levels[str(i)] = {"done": true, "gems": [true, i % 2 == 0, false], "best": 5000}
		g.unlocked[i] = true
	g.score = 408180
	var scene: PackedScene = load("res://ui/title.tscn")
	var node = scene.instantiate()
	root.add_child(node)
	for i in range(40):
		await process_frame
	await create_timer(1.0).timeout
	print("title size=", node.size, " visible=", root.get_visible_rect().size, " menu=", node._menu.global_position, node._menu.size, " logo=", node._logo.global_position, node._logo.size)
	var out: String = "/tmp/title.png"
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var img: Image = root.get_viewport().get_texture().get_image()
	img.save_png(out)
	print("captura: ", out, " ", img.get_size())
	quit(0)
