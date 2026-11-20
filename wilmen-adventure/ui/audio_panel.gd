extends RefCounted
## Panel reutilizable de audio: volumen y silencio independientes para música y efectos.

const UiTheme := preload("res://ui/ui_theme.gd")


static func build(width: float = 260.0) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.add_child(_row("Música", "music", "music_vol", width, false))
	v.add_child(_row("Efectos", "sfx", "sfx_vol", width, true))
	return v


static func _row(label_text: String, enabled_key: String, vol_key: String, width: float, click_on_release: bool) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	var l := UiTheme.label(label_text, 12)
	l.custom_minimum_size = Vector2(52, 24)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(l)
	var sl := HSlider.new()
	sl.min_value = 0.0
	sl.max_value = 1.0
	sl.step = 0.05
	sl.value = float(Game.settings.get(vol_key, 1.0))
	sl.custom_minimum_size = Vector2(maxf(60.0, width - 150.0), 24)
	sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sl.value_changed.connect(func(val: float):
		Game.settings[vol_key] = val
		Game.settings_changed.emit())
	sl.drag_ended.connect(func(_changed: bool):
		Game.save_game()
		if click_on_release:
			Audio.play_sfx("coin"))
	h.add_child(sl)
	var m := Button.new()
	m.toggle_mode = true
	m.custom_minimum_size = Vector2(80, 28)
	m.button_pressed = not bool(Game.settings.get(enabled_key, true))
	var upd := func():
		m.text = "Silenciado" if m.button_pressed else "Silenciar"
	upd.call()
	m.toggled.connect(func(pressed: bool):
		Game.set_setting(enabled_key, not pressed)
		upd.call())
	h.add_child(m)
	return h
