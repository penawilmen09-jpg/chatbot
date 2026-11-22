extends "res://ui/hud.gd"
## Interfaz de un nivel de WILMEN WORLD: la de WILMEN ADVENTURE más el reloj con cuenta atrás (arriba al centro), las
## llaves y el resultado propio del modo. El reloj se pone ámbar, naranja y rojo (parpadea) al acercarse a cero.

var _key_label: Label


func _ready() -> void:
	super()
	_timer_label.add_theme_font_size_override("font_size", 16)
	_timer_label.add_theme_constant_override("outline_size", 4)
	_mode_label.text = "WILMEN WORLD"
	_key_label = UiTheme.label("", 10, Color("#ffd23a"))
	_key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.get_parent().add_child(_key_label)
	_timer_label.get_parent().move_child(_key_label, 1)
	WW.changed.connect(_refresh_keys)
	_refresh_keys()


func _refresh_keys() -> void:
	if _key_label != null:
		_key_label.text = "Llaves x%d" % WW.key_count()


func _process(delta: float) -> void:
	super(delta)
	if level == null or not ("time_left" in level):
		return
	var left: float = level.time_left
	_timer_label.text = _fmt_time(ceil(left))
	var col: Color = Color("#ffffff")
	if left <= 10.0:
		col = Color("#ff4a4a") if int(left * 3.0) % 2 == 0 else Color("#ffffff")
	elif left <= 30.0:
		col = Color("#ff9a3a")
	elif left <= 100.0:
		col = Color("#ffe97a")
	_timer_label.add_theme_color_override("font_color", col)


func show_game_over() -> void:
	var v := _make_overlay("SIN VIDAS", Color("#ff8a8a"))
	var l := UiTheme.label("Pierdes lo ganado en este intento. Tu progreso de WILMEN WORLD se conserva.", 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 300
	v.add_child(l)
	var first := _menu_button(v, "Reintentar", func():
		Game.fail_level()
		WW.harvest()
		level.restart_level())
	_menu_button(v, "Volver al mapa", func():
		Game.fail_level()
		level.go_menu())
	first.grab_focus()


func show_world_result(info: Dictionary) -> void:
	var n: int = level.number
	var v := _make_overlay("¡SALIDA SECRETA!" if bool(info.get("secret", false)) else "¡NIVEL COMPLETADO!", Color("#c08aff") if bool(info.get("secret", false)) else Color("#ffe97a"))
	var sub := UiTheme.label("%d  %s" % [n, str(level.meta["title"])], 12, Color("#cfc6ff"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 18)
	v.add_child(cols)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 3)
	cols.add_child(left)
	var gem_row := HBoxContainer.new()
	gem_row.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in range(3):
		var g := _icon_rect(UiTheme.ICON_GEM, 26)
		g.modulate = Color.WHITE if info["gems"][i] else Color(0.25, 0.25, 0.3, 0.8)
		gem_row.add_child(g)
	left.add_child(gem_row)
	var used: int = int(info["time_used"])
	var rest: int = int(info["time_left"])
	var lines: Array = [
		"Tiempo usado %d:%02d   Sobrante %d:%02d" % [used / 60, used % 60, rest / 60, rest % 60],
		"Monedas %d   Bonus +%d" % [int(info["coins"]), int(info["bonus"])],
		"Puntos %d  (total %d)" % [int(info["score"]), Game.score],
		"Llaves %d" % int(info["keys"]),
	]
	if int(info.get("opened", 0)) > 0:
		lines.append("¡Se ha abierto un camino nuevo en el mapa!")
	if bool(info["first"]):
		lines.append("¡Primera vez completado!")
	elif bool(info["new_best"]):
		lines.append("¡Nuevo mejor tiempo!")
	for line in lines:
		left.add_child(UiTheme.label(str(line), 11, Color("#8affb0") if str(line).begins_with("¡") else Color.WHITE))
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	cols.add_child(right)
	var back := _menu_button(right, "Continuar en el mapa", func(): level.go_menu(), 150.0)
	_menu_button(right, "Repetir nivel", func(): level.restart_level(), 150.0)
	back.grab_focus()
