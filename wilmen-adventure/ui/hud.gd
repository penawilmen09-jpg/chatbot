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
var _timer_label: Label
var _power_label: Label
var _mode_label: Label
var _toast_box: PanelContainer = null
var _toast_tw: Tween = null
var _last_power: String = ""
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
	_build_extra_labels()
	Game.stats_changed.connect(_refresh)
	Game.settings_changed.connect(_apply_touch_visibility)
	Progress.achievement_unlocked.connect(_on_achievement)
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
	if p.power != _last_power:
		# el botón muestra el poder activo (también los temporales de fuego, hielo y electricidad)
		_last_power = p.power
		var pi: int = Game.POWERS.find(p.power)
		if pi >= 0:
			_skill_btn.icon_tex = UiTheme.icon(UiTheme.ICON_POWER_BASE + pi)
			_skill_btn.queue_redraw()
	_timer_label.text = _fmt_time(level.elapsed)
	var pl: String = p.power_label()
	if pl != "":
		_power_label.text = "%s  %ds" % [pl, int(ceil(p.power_timer()))] if p.power_timer() > 0.0 and not (p.barrier and p.temp_power == "" and p.giant_t <= 0.0) else pl
		_power_label.visible = true
	else:
		_power_label.visible = false


func _fmt_time(sec: float) -> String:
	var t: int = int(sec)
	return "%d:%02d" % [t / 60, t % 60]


func _build_extra_labels() -> void:
	## Cronómetro, poder temporal activo y nombre del modo (todo bajo la puntuación).
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	box.offset_left = -90
	box.offset_right = 90
	box.offset_top = 24
	box.add_theme_constant_override("separation", 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(box)
	_timer_label = UiTheme.label("0:00", 10, Color("#cfc6ff"))
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_timer_label)
	_power_label = UiTheme.label("", 10, Color("#8affb0"))
	_power_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_power_label.visible = false
	box.add_child(_power_label)
	_mode_label = UiTheme.label("", 10, Color("#ffd23a"))
	_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_mode_label)
	if level != null and level.mode != "story":
		_mode_label.text = str(Progress.MODE_NAMES.get(level.mode, level.mode))


func set_mode_label(text: String) -> void:
	_mode_label.text = text


func _on_achievement(id: String) -> void:
	var a: Array = Progress.ACHIEVEMENTS.get(id, [])
	if a.is_empty():
		return
	Audio.play_sfx("achievement")
	var lines: Array = ["¡Logro desbloqueado!", str(a[0])]
	var rw: Array = a[4]
	if not rw.is_empty():
		lines.append("Premio: %s" % Progress.cosmetic_name(str(rw[0]), str(rw[1])))
	_toast(lines, Color("#ffd23a"))


func show_reward(info: Dictionary) -> void:
	## Banner de botín al abrir un cofre.
	var titles := {"normal": "Cofre", "rare": "Cofre raro", "special": "Cofre especial", "secret": "¡COFRE SECRETO!"}
	var cols := {"normal": Color("#ffe97a"), "rare": Color("#9ad4ff"), "special": Color("#e08aff"), "secret": Color("#ff7a8a")}
	var kind: String = str(info.get("kind", "normal"))
	var lines: Array = [str(titles.get(kind, "Tesoro"))]
	if int(info.get("coins", 0)) > 0:
		lines.append("+%d monedas" % int(info["coins"]))
	if int(info.get("gems", 0)) > 0:
		lines.append("+%d gemas especiales" % int(info["gems"]))
	if info.has("cosmetic") and bool(info["cosmetic"].get("new", false)):
		lines.append("Nuevo: %s" % Progress.cosmetic_name(str(info["cosmetic"]["cat"]), str(info["cosmetic"]["id"])))
	if info.has("power"):
		lines.append("Poder: %s" % str(Progress.POWERUPS.get(str(info["power"]), info["power"])))
	_toast(lines, cols.get(kind, Color.WHITE))


func _toast(lines: Array, color: Color, seconds: float = 2.6) -> void:
	if _toast_box != null:
		_toast_box.queue_free()
	if _toast_tw != null and _toast_tw.is_valid():
		_toast_tw.kill()
	var pc := PanelContainer.new()
	pc.process_mode = Node.PROCESS_MODE_ALWAYS
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	pc.add_child(v)
	for i in range(lines.size()):
		var l := UiTheme.label(str(lines[i]), 12 if i == 0 else 10, color if i == 0 else Color.WHITE)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	pc.set_anchors_preset(Control.PRESET_CENTER_TOP)
	pc.position = Vector2(0, 64)
	_root.add_child(pc)
	_toast_box = pc
	await get_tree().process_frame
	if not is_instance_valid(pc):
		return
	pc.position.x = (_root.size.x - pc.size.x) * 0.5
	pc.position.y = 40
	pc.modulate.a = 0.0
	_toast_tw = create_tween()
	_toast_tw.tween_property(pc, "modulate:a", 1.0, 0.18)
	_toast_tw.tween_interval(seconds)
	_toast_tw.tween_property(pc, "modulate:a", 0.0, 0.4)
	_toast_tw.tween_callback(pc.queue_free)


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
	var ms: Dictionary = info.get("missions", {})
	var mrow := HBoxContainer.new()
	mrow.alignment = BoxContainer.ALIGNMENT_CENTER
	mrow.add_theme_constant_override("separation", 6)
	for pair in [["nohit", "Sin daño"], ["gems", "3 gemas"], ["time", "Rápido"]]:
		var done_m: bool = bool(ms.get(pair[0], false))
		var ml := UiTheme.label(("✔ " if done_m else "· ") + str(pair[1]), 9, Color("#8affb0") if done_m else Color("#8a84a8"))
		mrow.add_child(ml)
	left.add_child(mrow)
	var tsec: int = int(info.get("time", 0.0))
	var medal_names := {"gold": "oro", "silver": "plata", "bronze": "bronce"}
	var tline: String = "Tiempo %d:%02d" % [tsec / 60, tsec % 60]
	if str(info.get("medal", "")) != "":
		tline += " (%s)" % medal_names.get(str(info["medal"]), "")
	if int(info.get("secrets", 0)) > 0:
		tline += "  Secretos: %d" % int(info["secrets"])
	var lines: Array = [
		"Monedas %d   Bonus +%d" % [int(info["coins"]), int(info["bonus"])],
		"Puntos %d  (total %d)" % [int(info["score"]), Game.score],
		tline,
	]
	if not reward.is_empty():
		lines.append("Recompensa: +%d vidas, +%d puntos" % [int(reward["lives"]), int(reward["score"])])
		var cr: Dictionary = reward.get("cosmetic", {})
		if bool(cr.get("new", false)):
			lines.append("¡Nuevo: %s!" % Progress.cosmetic_name(str(cr["cat"]), str(cr["id"])))
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


func show_mode_result(info: Dictionary) -> void:
	var m: String = str(info.get("mode", ""))
	var v := _make_overlay("¡%s SUPERADO!" % str(Progress.MODE_NAMES.get(m, "MODO")).to_upper(), Color("#ffe97a"))
	var tsec: int = int(info.get("time", 0.0))
	var l1 := UiTheme.label("Tiempo %d:%02d" % [tsec / 60, tsec % 60], 12)
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l1)
	if m == "time":
		var medal_names := {"gold": "ORO", "silver": "PLATA", "bronze": "BRONCE", "": "sin medalla"}
		var l2 := UiTheme.label("Medalla: %s   Mejor: %.1f s%s" % [medal_names.get(str(info.get("medal", "")), ""), float(info.get("best", 0.0)), "  ¡Nuevo récord!" if bool(info.get("better", false)) else ""], 11, Color("#8affb0"))
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l2)
	elif bool(info.get("first", false)):
		var l3 := UiTheme.label("¡Recompensa conseguida! (monedas, gemas y más)", 11, Color("#8affb0"))
		l3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l3)
	var first := _menu_button(v, "Repetir", func(): level.restart_level())
	_menu_button(v, "Volver a Extras", func(): level.go_menu())
	first.grab_focus()


func show_mode_fail(m: String, info: Dictionary) -> void:
	var v := _make_overlay("FIN DEL INTENTO", Color("#ff8a8a"))
	var text := "No se pierden vidas de la historia. ¡Inténtalo de nuevo!"
	if m == "survival":
		text = "Oleadas superadas: %d   Récord del mundo: %d%s" % [int(info.get("waves", 0)), int(info.get("best", 0)), "  ¡NUEVO!" if bool(info.get("new_best", false)) else ""]
	var l := UiTheme.label(text, 11)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var first := _menu_button(v, "Reintentar", func(): level.restart_level())
	_menu_button(v, "Volver a Extras", func(): level.go_menu())
	first.grab_focus()


func show_game_over() -> void:
	var v := _make_overlay("SIN VIDAS", Color("#ff8a8a"))
	var l := UiTheme.label("No se desbloquea el siguiente nivel hasta completar este.", 11)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	# Anuncio recompensado VOLUNTARIO: solo aparece si hay un proveedor de anuncios activo y listo.
	var ad_btn: Button = null
	var ad_msg: Label = null
	if Ads.can_offer_reward():
		ad_btn = _menu_button(v, "Ver anuncio y obtener +1 vida", func(): pass)
		ad_msg = UiTheme.label("", 10, Color("#ffd27a"))
		ad_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(ad_msg)
		ad_btn.pressed.connect(func(): _watch_ad(ad_btn, ad_msg))
	var first := _menu_button(v, "Reintentar", func():
		Game.fail_level()
		level.restart_level())
	_menu_button(v, "Mapa de niveles", func():
		Game.fail_level()
		Game.save_game()
		level.go_menu())
	first.grab_focus()


func _watch_ad(btn: Button, msg: Label) -> void:
	btn.disabled = true  # un toque = una petición
	var started: bool = Ads.request_reward(func(result: String):
		if result == "rewarded":
			level.continue_after_ad()
			return
		if not is_instance_valid(btn):
			return
		msg.text = "El anuncio no se completó: no se ha dado la vida." if result == "closed" else "No se pudo mostrar el anuncio."
		btn.disabled = not Ads.can_offer_reward())
	if not started:
		msg.text = "No hay anuncio disponible ahora."
		btn.disabled = true
