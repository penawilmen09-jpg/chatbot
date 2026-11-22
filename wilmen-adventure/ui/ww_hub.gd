extends Control
## Pantalla de inicio de WILMEN WORLD (hito 1). Muestra el progreso propio del modo (su partida es independiente de la de
## WILMEN ADVENTURE) y permite volver al menú o reiniciar SOLO este modo. El mapa de regiones llega en el hito 2.

const UiTheme := preload("res://ui/ui_theme.gd")
const HeroPreview := preload("res://ui/hero_preview.gd")
const M := "res://assets/menu/"
const FONT := preload("res://assets/ui/DejaVuSans-Bold.ttf")

var _stats_labels: Dictionary = {}
var _region_labels: Array = []
var _reset_btn: Button
var _reset_armed: bool = false
var _back: Button


func _ready() -> void:
	theme = UiTheme.make()
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = get_viewport_rect().size
	get_viewport().size_changed.connect(func(): size = get_viewport_rect().size)
	if not FileAccess.file_exists(WW.save_path):
		WW.save_game()  # la partida de WILMEN WORLD nace aquí, en su propio archivo
	_build_background()
	_build_header()
	_build_hero()
	_build_regions()
	_build_stats()
	_build_buttons()
	_refresh()
	WW.changed.connect(_refresh)
	Audio.play_music("map")


func _tex(name: String) -> Texture2D:
	return load(M + name + ".png")


func _build_background() -> void:
	var sky := TextureRect.new()
	sky.texture = _tex("sky")
	sky.stretch_mode = TextureRect.STRETCH_TILE
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sky)
	var mt := TextureRect.new()
	mt.texture = _tex("mountains")
	mt.stretch_mode = TextureRect.STRETCH_TILE
	mt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mt.anchor_left = 0.0
	mt.anchor_right = 1.0
	mt.anchor_top = 1.0
	mt.anchor_bottom = 1.0
	mt.offset_top = -130.0
	add_child(mt)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.12, 0.42)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)


func _build_header() -> void:
	var box := VBoxContainer.new()
	box.anchor_left = 0.0
	box.anchor_right = 1.0
	box.offset_top = 8.0
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	var t := UiTheme.label("WILMEN WORLD", 28, Color("#ffd23a"))
	t.add_theme_font_override("font", FONT)
	t.add_theme_constant_override("outline_size", 6)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	var s := UiTheme.label("Una aventura por seis regiones · partida propia, independiente de WILMEN ADVENTURE", 8, Color("#e8f4ff"))
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(s)


func _build_hero() -> void:
	# solo se comparte el aspecto del héroe (traje, sombrero, armadura...): se LEE de la personalización, no se escribe
	var holder := Node2D.new()
	holder.scale = Vector2(3.0, 3.0)
	add_child(holder)
	holder.position = Vector2(62.0, 190.0)
	HeroPreview.build(holder, "idle")


func _build_regions() -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.offset_left = -92.0
	panel.offset_right = 92.0
	panel.offset_top = 68.0
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	panel.add_child(v)
	var h := UiTheme.label("REGIONES", 10, Color("#cfc6ff"))
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)
	for i in range(WW.REGION_COUNT):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 5)
		v.add_child(row)
		var dot := ColorRect.new()
		dot.color = WW.REGION_COLORS[i]
		dot.custom_minimum_size = Vector2(8, 8)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(dot)
		var name_l := UiTheme.label(WW.REGION_NAMES[i], 9)
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_l)
		var cnt := UiTheme.label("", 9, Color("#ffe97a"))
		row.add_child(cnt)
		_region_labels.append(cnt)
	var note := UiTheme.label("El mapa llega en el siguiente hito", 8, Color("#8affb0"))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(note)


func _build_stats() -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -118.0
	panel.offset_right = -10.0
	panel.offset_top = 68.0
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	panel.add_child(v)
	var h := UiTheme.label("TU PARTIDA", 10, Color("#cfc6ff"))
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)
	for k in ["levels", "coins", "gems", "keys", "lives", "score"]:
		var l := UiTheme.label("", 9)
		v.add_child(l)
		_stats_labels[k] = l


func _build_buttons() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.anchor_left = 0.0
	row.anchor_right = 1.0
	row.anchor_top = 1.0
	row.anchor_bottom = 1.0
	row.offset_top = -44.0
	row.offset_bottom = -8.0
	add_child(row)
	_back = UiTheme.button("Volver al menú", Vector2(150, 32))
	_back.pressed.connect(func():
		Audio.play_sfx("back")
		Transition.change_scene("res://ui/title.tscn"))
	row.add_child(_back)
	_reset_btn = UiTheme.button("Reiniciar WILMEN WORLD", Vector2(170, 32))
	_reset_btn.pressed.connect(_on_reset)
	row.add_child(_reset_btn)
	_back.grab_focus()


func _on_reset() -> void:
	## Dos pasos para evitar toques accidentales. Solo reinicia la partida de WILMEN WORLD.
	if not _reset_armed:
		_reset_armed = true
		_reset_btn.text = "¿Seguro? Pulsa otra vez"
		get_tree().create_timer(3.0).timeout.connect(func():
			if is_instance_valid(_reset_btn) and _reset_armed:
				_reset_armed = false
				_reset_btn.text = "Reiniciar WILMEN WORLD")
		return
	_reset_armed = false
	_reset_btn.text = "Reiniciar WILMEN WORLD"
	WW.reset()
	WW.save_game()


func _refresh() -> void:
	for i in range(WW.REGION_COUNT):
		_region_labels[i].text = "%d/%d" % [WW.completed_in_region(i + 1), WW.LEVELS_PER_REGION]
	_stats_labels["levels"].text = "Niveles  %d/%d" % [WW.completed_count(), WW.LEVEL_COUNT]
	_stats_labels["coins"].text = "Monedas  %d" % WW.coins
	_stats_labels["gems"].text = "Gemas  %d" % WW.gems
	_stats_labels["keys"].text = "Llaves  %d" % WW.total_keys()
	_stats_labels["lives"].text = "Vidas  %d" % WW.lives
	_stats_labels["score"].text = "Puntos  %d" % WW.score


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Transition.change_scene("res://ui/title.tscn")
