extends Node
## Captura de pantalla de una escena (requiere render real, p. ej. xvfb-run).
## Uso: xvfb-run godot --path . res://tests/shot.tscn -- <escena> <salida.png> [frames] [x_metros_teletransporte] [hold]
func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var path: String = a[0]
	var out: String = a[1]
	var frames := int(a[2]) if a.size() > 2 else 60
	var tp := float(a[3]) if a.size() > 3 else 0.0
	var hold := a.size() > 4
	SaveManager.save_path = "user://shot_save.json"
	var s: Node = (load(path) as PackedScene).instantiate()
	add_child(s)
	for i in frames:
		await get_tree().physics_frame
		if "vehicle" in s and s.vehicle:
			if tp > 0.0 and i == 20:
				var x := 220.0 + tp * WorldDefs.PX_PER_M
				s.terrain.update_for(x)
				s.vehicle.global_position = Vector2(x, s.terrain.gen.y_at(x) - 90.0)
				s.vehicle.linear_velocity = Vector2(300, 0)
				s.cam.global_position = s.vehicle.global_position
			if hold and i == 40:
				var t := InputEventScreenTouch.new()
				t.pressed = true
				s.hud.gas._gui_input(t)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	get_tree().quit()
