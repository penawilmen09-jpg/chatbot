extends CanvasLayer
## Interfaz durante el nivel: corazones, monedas, gemas, puntos, vidas, barra del jefe,
## controles táctiles grandes (izquierda, derecha, salto, habilidad) y menús de pausa / resultados.

const UiTheme := preload("res://ui/ui_theme.gd")
const TouchButton := preload("res://ui/touch_button.gd")
const AudioPanel := preload("res://ui/audio_panel.gd")

var level = null

var _root: Control
var _hearts: Array = []
var _gem_icons: Array = []
var _coin_label: Label
var _score_label: Label
var _lives_label: Label
var _touch: Control
var _skill_btn: Control
var _boss_root: Control
var _boss_name: Label
var _boss_fill: ColorRect
var _overlay: Control = null
var _intro: Control = null
const BOSS_BAR_W := 200.0


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UiTheme.make()
	add_child(_root)
	_build_top()
	_build_boss_bar()
	_build_touch()
	Game.stats_changed.connect(_refresh)
	Game.settings_changed.connect(_apply_touch_visibility)
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and level != null:
		level.toggle_pause()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and level != null:
		level.toggle_pause()


func _process(_delta: float) -> void:
	if level == null or level.player == null:
		return
	var p = level.player
	var ratio: float = 0.0
	if p.skill_cd_max > 0.0:
		ratio = clampf(p.skill_cd / p.skill_cd_max, 0.0, 1.0)
	_skill_btn.set_cooldown(ratio)


# ----------------------------------------------------------- construcción -
func _icon_rect(index: int, px: int) -> TextureRect:
	var t := TextureRect.new()
	t.texture = UiTheme.icon(index)
	t.custom_minimum_size = Vector2(px, px)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func _build_top() -> void:
	var left := VBoxContainer.new()
	left.position = Vector2(8, 6)
	left.add_theme_constant_override("separation", 2)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(left)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 1)
	row1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(row1)
	for i in range(3):
		var h := _icon_rect(UiTheme.ICON_HEART, 22)
		row1.add_child(h)
		_hearts.append(h)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 3)
	row2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(row2)
	row2.add_child(_icon_rect(UiTheme.ICON_COIN, 14))
	_coin_label = UiTheme.label("x0", 12)
	_coin_label.custom_minimum_size.x = 34
	row2.add_child(_coin_label)
	for i in range(3):
		var g := _icon_rect(UiTheme.ICON_GEM, 14)
		row2.add_child(g)
		_gem_icons.append(g)
	row2.add_child(_icon_rect(UiTheme.ICON_LIFE, 14))
	_lives_label = UiTheme.label("x5", 12)
	row2.add_child(_lives_label)

	_score_label = UiTheme.label("0", 14, Color("#ffe97a"))
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_score_label.offset_left = -80
	_score_label.offset_right = 80
	_score_label.offset_top = 6
	_score_label.offset_bottom = 26
	_root.add_child(_score_label)

	var pause := UiTheme.button("II", Vector2(44, 36))
	pause.focus_mode = Control.FOCUS_NONE
	pause.process_mode = Node.PROCESS_MODE_PAUSABLE
	pause.anchor_left = 1.0
	pause.anchor_right = 1.0
	pause.offset_left = -54
	pause.offset_right = -10
	pause.offset_top = 8
	pause.offset_bottom = 44
	pause.pressed.connect(func(): level.toggle_pause())
	_root.add_child(pause)


func _build_boss_bar() -> void:
	_boss_root = Control.new()
	_boss_root.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_boss_root.offset_left = -BOSS_BAR_W * 0.5
	_boss_root.offset_right = BOSS_BAR_W * 0.5
	_boss_root.offset_top = 30
	_boss_root.offset_bottom = 60
	_boss_root.visible = false
	_boss_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_boss_root)
	_boss_name = UiTheme.label("", 11, Color("#ff9a8a"))
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_name.custom_minimum_size = Vector2(BOSS_BAR_W, 14)
	_boss_root.add_child(_boss_name)
	var back := ColorRect.new()
	back.color = Color("#1a1226")
	back.position = Vector2(0, 16)
	back.size = Vector2(BOSS_BAR_W, 10)
	_boss_root.add_child(back)
	_boss_fill = ColorRect.new()
	_boss_fill.color = Color("#e0402a")
	_boss_fill.position = Vector2(1, 17)
	_boss_fill.size = Vector2(BOSS_BAR_W - 2, 8)
	_boss_root.add_child(_boss_fill)


func _make_touch_button(action: String, kind: String, l: float, r: float, t: float, b: float, from_right: bool) -> Control:
	var btn = TouchButton.new()
	btn.action = action
	btn.kind = kind
	btn.anchor_top = 1.0
	btn.anchor_bottom = 1.0
	if from_right:
		btn.anchor_left = 1.0
		btn.anchor_right = 1.0
	btn.offset_left = l
	btn.offset_right = r
	btn.offset_top = t
	btn.offset_bottom = b
	_touch.add_child(btn)
	return btn


func _build_touch() -> void:
	_touch = Control.new()
	_touch.set_anchors_preset(Control.PRESET_FULL_RECT)
	_touch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_touch.process_mode = Node.PROCESS_MODE_PAUSABLE
	_root.add_child(_touch)
	_make_touch_button("move_left", "left", 14, 90, -90, -14, false)
	_make_touch_button("move_right", "right", 102, 178, -90, -14, false)
	_make_touch_button("jump", "jump", -100, -14, -100, -14, true)
	_skill_btn = _make_touch_button("skill", "skill", -196, -118, -92, -14, true)
	var power: String = Game.power_of_world(Game.world_of(Game.current_level))
	_skill_btn.icon_tex = UiTheme.icon(UiTheme.ICON_POWER_BASE + Game.POWERS.find(power))
	_apply_touch_visibility()


func _apply_touch_visibility() -> void:
	_touch.visible = Game.touch_enabled()


# --------------------------------------------------------- actualización --
func set_hp(hp: int, max_hp: int) -> void:
	for i in range(_hearts.size()):
		_hearts[i].texture = UiTheme.icon(UiTheme.ICON_HEART if i < hp else UiTheme.ICON_HEART_EMPTY)
		_hearts[i].visible = i < max_hp


func set_gems(gems: Array) -> void:
	for i in range(_gem_icons.size()):
		_gem_icons[i].modulate = Color.WHITE if gems[i] else Color(0.25, 0.25, 0.3, 0.8)


func _refresh() -> void:
	_coin_label.text = "x%d" % Game.coins
	_lives_label.text = "x%d" % Game.lives
	_score_label.text = "%d" % Game.score


func show_boss(boss_name: String) -> void:
	_boss_name.text = boss_name
	_boss_fill.size.x = BOSS_BAR_W - 2
	_boss_root.visible = true


func hide_boss() -> void:
	_boss_root.visible = false


func set_boss_hp(hp: int, max_hp: int) -> void:
	var w: float = (BOSS_BAR_W - 2.0) * float(hp) / float(maxi(1, max_hp))
	var tw := create_tween()
	tw.tween_property(_boss_fill, "size:x", w, 0.2)


func show_intro(title: String, world_name: String) -> void:
	var power: String = Game.power_of_world(Game.world_of(Game.current_level))
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -200
	box.offset_right = 200
	box.offset_top = -60
	box.offset_bottom = 20
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l1 := UiTheme.label(title, 20, Color("#ffffff"))
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var l2 := UiTheme.label(world_name, 13, Game.WORLD_COLORS[Game.world_of(Game.current_level) - 1])
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var l3 := UiTheme.label("Poder: %s" % Game.POWER_NAMES[power], 11, Color("#ffe97a"))
	l3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(l1)
	box.add_child(l2)
	box.add_child(l3)
	_root.add_child(box)
	_intro = box
	box.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(box, "modulate:a", 1.0, 0.3)
	tw.tween_interval(1.8)
	tw.tween_property(box, "modulate:a", 0.0, 0.5)
	tw.tween_callback(box.queue_free)


# -------------------------------------------------------------- menús -----
func _clear_overlay() -> void:
	if _overlay != null:
		_overlay.queue_free()
		_overlay = null


func _make_overlay(title: String, title_color: Color = Color.WHITE) -> VBoxContainer:
	_clear_overlay()
	var o := Control.new()
	o.set_anchors_preset(Control.PRESET_FULL_RECT)
	o.process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.01, 0.08, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	o.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	o.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)
	var t := UiTheme.label(title, 20, title_color)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	_root.add_child(o)
	_overlay = o
	return v


func _menu_button(parent: Control, text: String, cb: Callable, width: float = 220.0) -> Button:
	var b := UiTheme.button(text, Vector2(width, 34))
	b.pressed.connect(func():
		Audio.play_sfx("click")
		cb.call())
	parent.add_child(b)
	return b


func show_pause() -> void:
	var v := _make_overlay("PAUSA")
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 16)
	v.add_child(cols)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	cols.add_child(left)
	var first := _menu_button(left, "Continuar", func(): level.toggle_pause(), 150.0)
	_menu_button(left, "Reiniciar nivel", func():
		Game.save_game()
		level.restart_level(), 150.0)
	var touch := _menu_button(left, "", func(): pass, 150.0)
	_wire_touch(touch)
	_menu_button(left, "Salir al mapa", func(): level.go_menu(), 150.0)
	var right := VBoxContainer.new()
	right.add_child(AudioPanel.build(260.0))
	var help := UiTheme.label("Poder: %s" % Game.POWER_NAMES[Game.power_of_world(level.world)], 10, Color("#ffe97a"))
	right.add_child(help)
	var help2 := UiTheme.label(Game.POWER_HELP[Game.power_of_world(level.world)], 9, Color("#cfc6ff"))
	help2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help2.custom_minimum_size.x = 250
	right.add_child(help2)
	cols.add_child(right)
	first.grab_focus()


func hide_pause() -> void:
	_clear_overlay()


func _wire_touch(btn: Button) -> void:
	var names := {"auto": "Auto", "on": "Sí", "off": "No"}
	var upd := func():
		btn.text = "Táctil: %s" % names[str(Game.settings.get("touch", "auto"))]
	upd.call()
	for c in btn.pressed.get_connections():
		btn.pressed.disconnect(c["callable"])
	btn.pressed.connect(func():
		Audio.play_sfx("click")
		var order := ["auto", "on", "off"]
		var cur: int = order.find(str(Game.settings.get("touch", "auto")))
		Game.set_setting("touch", order[(cur + 1) % 3])
		upd.call())


func show_result(info: Dictionary) -> void:
	var n: int = level.number
	var reward: Dictionary = info.get("reward", {})
	var v := _make_overlay("¡MUNDO COMPLETADO!" if not reward.is_empty() else "¡NIVEL COMPLETADO!", Color("#ffe97a"))
	var sub := UiTheme.label(Game.level_title(n), 12, Color("#cfc6ff"))
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
	var lines: Array = [
		"Monedas: %d" % int(info["coins"]),
		"Bonus: +%d" % int(info["bonus"]),
		"Puntos del nivel: %d" % int(info["score"]),
		"Puntos totales: %d" % Game.score,
	]
	if not reward.is_empty():
		lines.append("Recompensa: +%d vidas, +%d puntos" % [int(reward["lives"]), int(reward["score"])])
	if Game.last_unlocked_level > 0:
		lines.append("¡Nivel %d desbloqueado!" % Game.last_unlocked_level)
	for line in lines:
		var l := UiTheme.label(str(line), 11, Color("#8affb0") if str(line).begins_with("¡") or str(line).begins_with("Recompensa") else Color.WHITE)
		left.add_child(l)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	cols.add_child(right)
	var first := _menu_button(right, "Siguiente nivel" if n < Game.LEVEL_COUNT else "¡Final!", func(): level.next_level(), 150.0)
	_menu_button(right, "Repetir nivel", func(): level.restart_level(), 150.0)
	_menu_button(right, "Mapa de niveles", func(): level.go_menu(), 150.0)
	first.grab_focus()


func show_game_over() -> void:
	var v := _make_overlay("SIN VIDAS", Color("#ff8a8a"))
	var l := UiTheme.label("No se desbloquea el siguiente nivel hasta completar este.", 11)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var first := _menu_button(v, "Reintentar", func():
		Game.fail_level()
		level.restart_level())
	_menu_button(v, "Mapa de niveles", func():
		Game.fail_level()
		Game.save_game()
		level.go_menu())
	first.grab_focus()
