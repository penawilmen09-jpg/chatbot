extends Node
## Captura de pantalla de una escena (requiere render real, p. ej. xvfb-run).
## Uso: xvfb-run godot --path . res://tests/shot.tscn -- <escena> <salida.png> [frames] [mundo] [nivel]
func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var path: String = a[0]
	var out: String = a[1]
	var frames := int(a[2]) if a.size() > 2 else 60
	if a.size() > 3:
		Nav.run_world = int(a[3])
	if a.size() > 4:
		Nav.run_level = int(a[4])
	SaveManager.save_path = "user://shot_save.json"
	var s: Node = (load(path) as PackedScene).instantiate()
	add_child(s)
	var hold := a.size() > 5
	for i in frames:
		await get_tree().physics_frame
		if hold and "hud" in s and s.hud and i == 200:
			var t := InputEventScreenTouch.new()
			t.pressed = true
			s.hud.gas._gui_input(t)
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out)
	get_tree().quit()
