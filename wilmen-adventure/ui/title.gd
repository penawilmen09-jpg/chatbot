extends Control
## Pantalla de inicio de WILMEN ADVENTURE.

const UiTheme := preload("res://ui/ui_theme.gd")
const MenuBg := preload("res://ui/menu_background.gd")
const SpriteUtil := preload("res://characters/sprite_util.gd")
const AudioPanel := preload("res://ui/audio_panel.gd")

var _options: Control = null
var _menu: VBoxContainer
var _hero: AnimatedSprite2D


func _ready() -> void:
	theme = UiTheme.make()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg = MenuBg.new()
	bg.world = 1
	bg.with_ground = true
	add_child(bg)

	# héroe corriendo sobre el suelo
	var tex: Texture2D = load("res://assets/player/wilmen.png")
	_hero = AnimatedSprite2D.new()
	_hero.sprite_frames = SpriteUtil.make_frames(tex, 24, 24, {"run": {"frames": [2, 3, 4, 5, 6, 7], "fps": 12.0}})
	_hero.scale = Vector2(4, 4)
	_hero.position = Vector2(110, 214.0 - 48.0)
	add_child(_hero)
	_hero.play("run")

	var title1 := UiTheme.label("WILMEN", 44, Color("#ffd23a"))
	var title2 := UiTheme.label("ADVENTURE", 30, Color("#ffffff"))
	for l in [title1, title2]:
		l.add_theme_constant_override("outline_size", 8)
	var tbox := VBoxContainer.new()
	tbox.position = Vector2(200, 20)
	tbox.add_theme_constant_override("separation", -8)
	tbox.add_child(title1)
	tbox.add_child(title2)
	add_child(tbox)
	var tw := create_tween().set_loops()
	tw.tween_property(tbox, "position:y", 26.0, 1.1).set_trans(Tween.TRANS_SINE)
	tw.tween_property(tbox, "position:y", 18.0, 1.1).set_trans(Tween.TRANS_SINE)

	_menu = VBoxContainer.new()
	_menu.position = Vector2(250, 92)
	_menu.add_theme_constant_override("separation", 3)
	add_child(_menu)
	var has_progress: bool = Game.continue_level() > 1 or Game.levels.size() > 0
	var first := _add_button("Continuar" if has_progress else "Jugar", _on_play)
	_add_button("Mapa de niveles", func(): Transition.change_scene("res://ui/level_select.tscn"))
	_add_button("Extras", func(): Transition.change_scene("res://ui/extras.tscn"))
	_add_button("Opciones", _show_options)
	_add_button("Salir", func(): get_tree().quit())
	first.grab_focus()

	var info := UiTheme.label("Niveles %d/100   Gemas %d/300   Puntos %d" % [Game.completed_count(), Game.total_gems(), Game.score], 10, Color("#ffffff"))
	info.position = Vector2(8, 250)
	add_child(info)
	var ver := UiTheme.label("v2.1 - 100 niveles, tesoros y vehículos - sin anuncios", 9, Color("#cfc6ff"))
	ver.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ver.offset_left = -190
	ver.offset_top = -18
	ver.offset_right = -6
	ver.offset_bottom = -4
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(ver)
	if Game.migrated_from_v1:
		var mig := UiTheme.label("Progreso de la versión anterior migrado a los 100 niveles", 9, Color("#8affb0"))
		mig.position = Vector2(8, 236)
		add_child(mig)
	Audio.play_music("title")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _options != null:
			_close_options()
		else:
			get_tree().quit()


func _add_button(text: String, cb: Callable) -> Button:
	var b := UiTheme.button(text, Vector2(200, 30))
	b.add_theme_font_size_override("font_size", 14)
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb: StyleBoxFlat = theme.get_stylebox(st, "Button").duplicate()
		sb.content_margin_top = 3
		sb.content_margin_bottom = 3
		b.add_theme_stylebox_override(st, sb)
	b.pressed.connect(func():
		Audio.play_sfx("select")
		cb.call())
	_menu.add_child(b)
	return b


func _on_play() -> void:
	if Game.start_level(Game.continue_level()):
		Transition.change_scene("res://levels/level.tscn")


# ------------------------------------------------------------- opciones ---
func _show_options() -> void:
	if _options != null:
		return
	var o := Control.new()
	o.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.01, 0.08, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	o.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	o.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	panel.add_child(outer)
	var t := UiTheme.label("OPCIONES", 20)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(t)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 16)
	outer.add_child(cols)

	# --- columna izquierda: audio y controles
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	cols.add_child(left)
	left.add_child(AudioPanel.build(250.0))
	var touch := UiTheme.button("", Vector2(250, 34))
	left.add_child(touch)
	var names := {"auto": "Auto", "on": "Sí", "off": "No"}
	var upd := func():
		touch.text = "Controles táctiles: %s" % names[str(Game.settings.get("touch", "auto"))]
	upd.call()
	touch.pressed.connect(func():
		Audio.play_sfx("click")
		var order := ["auto", "on", "off"]
		var cur: int = order.find(str(Game.settings.get("touch", "auto")))
		Game.set_setting("touch", order[(cur + 1) % 3])
		upd.call())
	var status := UiTheme.label("", 10, Color("#8affb0"))
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size = Vector2(250, 28)
	left.add_child(status)

	# --- columna derecha: copia de seguridad, borrar, volver
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	cols.add_child(right)
	var copy := UiTheme.button("Copiar mi partida", Vector2(170, 34))
	right.add_child(copy)
	copy.pressed.connect(func():
		Audio.play_sfx("click")
		DisplayServer.clipboard_set(Game.export_save_string())
		status.text = "Partida copiada al portapapeles. Pégala en una nota para guardarla.")
	var restore := UiTheme.button("Restaurar partida", Vector2(170, 34))
	right.add_child(restore)
	restore.pressed.connect(func():
		Audio.play_sfx("click")
		if Game.import_save_string(DisplayServer.clipboard_get()):
			status.text = "Partida restaurada (la anterior se guardó aparte)."
			get_tree().create_timer(0.8).timeout.connect(func(): get_tree().reload_current_scene())
		else:
			status.text = "El portapapeles no contiene una partida válida.")
	var reset := UiTheme.button("Borrar progreso", Vector2(170, 34))
	right.add_child(reset)
	reset.pressed.connect(func():
		if reset.text == "Borrar progreso":
			reset.text = "¿Seguro? Otra vez"
			status.text = "Se guardará una copia antes de borrar."
		else:
			Game.reset_progress()
			Audio.play_sfx("back")
			_close_options()
			get_tree().reload_current_scene())
	var back := UiTheme.button("Volver", Vector2(170, 34))
	back.pressed.connect(func():
		Audio.play_sfx("back")
		_close_options())
	right.add_child(back)
	add_child(o)
	_options = o
	back.grab_focus()


func _close_options() -> void:
	if _options != null:
		_options.queue_free()
		_options = null
