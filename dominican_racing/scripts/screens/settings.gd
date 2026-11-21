extends ScreenBase
## Configuración: volumen, silencio, nombre del jugador y reinicio de progreso.

var name_edit: LineEdit

func _build() -> void:
	add_backdrop({}, 40.0)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.05, 0.14, 0.5)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	add_topbar("CONFIGURACIÓN")
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.offset_top = 80
	add_child(cc)
	var p := UIKit.panel(UIKit.NAVY, 26, 24)
	p.custom_minimum_size = Vector2(720, 0)
	cc.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	UIKit.inner(p).add_child(v)
	var st: Dictionary = SaveManager.data["settings"]
	# nombre
	var nr := HBoxContainer.new()
	nr.add_theme_constant_override("separation", 12)
	var nl := UIKit.label("Nombre del piloto", 26, Color.WHITE)
	nl.custom_minimum_size = Vector2(250, 0)
	nr.add_child(nl)
	name_edit = LineEdit.new()
	name_edit.text = SaveManager.data["profile"]["name"]
	name_edit.max_length = 14
	name_edit.custom_minimum_size = Vector2(300, 52)
	name_edit.add_theme_font_size_override("font_size", 26)
	name_edit.text_submitted.connect(func(_t): _commit_name())
	name_edit.focus_exited.connect(_commit_name)
	nr.add_child(name_edit)
	v.add_child(nr)
	v.add_child(_slider_row("Música", float(st["music"]), func(val):
		SaveManager.data["settings"]["music"] = val
		Sfx.apply_settings()))
	v.add_child(_slider_row("Efectos", float(st["sfx"]), func(val):
		SaveManager.data["settings"]["sfx"] = val
		Sfx.apply_settings()))
	var mute := CheckButton.new()
	mute.text = "Silenciar todo el sonido"
	mute.button_pressed = st["mute"]
	mute.add_theme_font_size_override("font_size", 26)
	mute.focus_mode = Control.FOCUS_NONE
	mute.toggled.connect(func(on):
		SaveManager.data["settings"]["mute"] = on
		Sfx.apply_settings()
		SaveManager.save_game())
	v.add_child(mute)
	v.add_child(HSeparator.new())
	var rec: Dictionary = SaveManager.data["records"]
	var stats := UIKit.label("Récord: %d m  ·  Mejor puntuación: %d  ·  Partidas: %d\nMonedas ganadas en total: %d  ·  Distancia total: %d m" % [
		int(rec["best_distance"]), rec["best_score"], rec["runs"], rec["coins_earned"], int(rec["total_distance"])], 20, Color(0.8, 0.9, 1.0), false)
	v.add_child(stats)
	var reset := UIKit.button("REINICIAR PROGRESO", UIKit.RED, Vector2(360, 58), 24)
	reset.pressed.connect(_confirm_reset)
	reset.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(reset)
	var ver := UIKit.label("DOMINICAN RACING  v1.0", 16, Color(1, 1, 1, 0.5), false)
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(ver)
	await get_tree().process_frame
	UIKit.pop_in(p)

func _slider_row(title: String, value: float, on_change: Callable) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var l := UIKit.label(title, 26, Color.WHITE)
	l.custom_minimum_size = Vector2(250, 0)
	h.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(340, 40)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.value_changed.connect(func(val):
		on_change.call(val)
		Sfx.click())
	s.drag_ended.connect(func(_c): SaveManager.save_game())
	h.add_child(s)
	return h

func _commit_name() -> void:
	var n := name_edit.text.strip_edges()
	if n == "":
		n = "Piloto"
		name_edit.text = n
	SaveManager.data["profile"]["name"] = n.left(14)
	SaveManager.save_game()

func _confirm_reset() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 70
	add_child(layer)
	var root := Control.new()
	layer.add_child(root)
	UIKit.fit(root)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.7)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(cc)
	var p := UIKit.panel(UIKit.NAVY, 24, 24)
	cc.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	UIKit.inner(p).add_child(v)
	v.add_child(UIKit.label("¿Borrar todo tu progreso?", 34, Color(1.0, 0.5, 0.45)))
	v.add_child(UIKit.label("Se perderán monedas, vehículos, mejoras y récords.", 22, Color.WHITE, false))
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 16)
	v.add_child(h)
	var no := UIKit.button("CANCELAR", UIKit.GRAY, Vector2(220, 58), 24)
	no.pressed.connect(layer.queue_free)
	h.add_child(no)
	var yes := UIKit.button("BORRAR", UIKit.RED, Vector2(220, 58), 24)
	yes.pressed.connect(func():
		SaveManager.reset_progress()
		Sfx.apply_settings()
		Nav.go(Nav.MENU))
	h.add_child(yes)

func on_back() -> void:
	_commit_name()
	SaveManager.save_game()
	Nav.go(Nav.MENU)
