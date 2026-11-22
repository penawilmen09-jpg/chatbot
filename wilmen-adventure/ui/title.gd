extends Control
## Pantalla de inicio de WILMEN ADVENTURE. Todo son componentes reales (botones, etiquetas, barra de estadísticas,
## animaciones): las imágenes de assets/menu/ son solo el arte (fondo, logo, marcos de botón e iconos), nunca el menú.
## Los elementos se anclan a los bordes para adaptarse a cualquier pantalla apaisada (16:9 hasta 21:9).

const UiTheme := preload("res://ui/ui_theme.gd")
const AudioPanel := preload("res://ui/audio_panel.gd")
const HeroPreview := preload("res://ui/hero_preview.gd")
const M := "res://assets/menu/"
const FONT := preload("res://assets/ui/DejaVuSans-Bold.ttf")

var _options: Control = null
var _menu: VBoxContainer
var _first: Button
var _falls: Sprite2D
var _falls_t: float = 0.0
var _clouds: Array = []
var _cloud_layer: Control
var _coins: Array = []
var _logo: TextureRect


func _ready() -> void:
	theme = UiTheme.make()
	Ads.set_banner(true)  # el banner (si hay anuncios activos) vive solo en el menú principal
	# el nodo raíz ocupa siempre toda la vista lógica (se actualiza al girar o redimensionar la ventana)
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = get_viewport_rect().size
	get_viewport().size_changed.connect(func(): size = get_viewport_rect().size)
	_build_scenery()
	_build_hero()
	_build_logo()
	_build_buttons()
	_build_round_buttons()
	_build_stats_bar()
	_build_notices()
	Audio.play_music("title")


func _process(delta: float) -> void:
	# cascadas (2 fotogramas), nubes a la deriva y moneda que gira
	_falls_t += delta
	if _falls != null:
		_falls.region_rect.position.x = (int(_falls_t * 5.0) % 2) * 250.0
	var w: float = size.x
	for c in _clouds:
		var sp: Sprite2D = c["node"]
		sp.position.x += float(c["speed"]) * delta
		if sp.position.x > w + 40.0:
			sp.position.x = -120.0
	for co in _coins:
		var sp2: Sprite2D = co["node"]
		sp2.texture = co["tex"][int(_falls_t * 4.0 + float(co["phase"])) % 2]


# ---------------------------------------------------------------- escena ---
func _tex(name: String) -> Texture2D:
	return load(M + name + ".png")


func _rect(name: String, pos: Vector2, anchors: String = "tl", scale_: float = 1.0) -> TextureRect:
	## Imagen decorativa con tamaño final = tamaño * escala (así los anclajes de la derecha/abajo no se descuadran).
	var tr := TextureRect.new()
	tr.texture = _tex(name)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.size = tr.texture.get_size() * scale_
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(tr)
	_place(tr, pos, anchors)
	return tr


func _place(c: Control, pos: Vector2, anchors: String) -> void:
	## "tl" arriba-izquierda, "bl" abajo-izquierda, "br" abajo-derecha, "tr" arriba-derecha (pos es el desplazamiento desde esa esquina).
	var sz: Vector2 = c.size
	var ax: float = 1.0 if anchors.ends_with("r") else 0.0
	var ay: float = 1.0 if anchors.begins_with("b") else 0.0
	c.anchor_left = ax
	c.anchor_right = ax
	c.anchor_top = ay
	c.anchor_bottom = ay
	c.offset_left = pos.x
	c.offset_top = pos.y
	c.offset_right = pos.x + sz.x
	c.offset_bottom = pos.y + sz.y


func _build_scenery() -> void:
	var sky := TextureRect.new()
	sky.texture = _tex("sky")
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)
	# nubes (sprites reales que se desplazan)
	_cloud_layer = Control.new()
	_cloud_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cloud_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cloud_layer.clip_contents = true
	add_child(_cloud_layer)
	var ct: Texture2D = load("res://assets/fx/clouds.png")
	var rects := [Rect2(0, 0, 64, 32), Rect2(64, 0, 48, 32), Rect2(112, 0, 80, 32)]
	for i in range(5):
		var sp := Sprite2D.new()
		sp.texture = ct
		sp.region_enabled = true
		sp.region_rect = rects[i % 3]
		sp.centered = false
		var s: float = 1.4 + 0.5 * float(i % 3)
		sp.scale = Vector2(s, s)
		sp.position = Vector2(float(i) * 140.0 - 30.0, 18.0 + float((i * 37) % 70))
		sp.modulate = Color(1, 1, 1, 0.92)
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_cloud_layer.add_child(sp)
		_clouds.append({"node": sp, "speed": 4.0 + 2.0 * float(i % 3)})
	# montañas (se repiten a lo ancho)
	var mt := TextureRect.new()
	mt.texture = _tex("mountains")
	mt.stretch_mode = TextureRect.STRETCH_TILE
	mt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mt.anchor_left = 0.0
	mt.anchor_right = 1.0
	mt.anchor_top = 1.0
	mt.anchor_bottom = 1.0
	mt.offset_top = -168.0
	mt.offset_bottom = -38.0
	add_child(mt)
	# acantilado con castillo y cascadas (a la derecha); el castillo queda sobre los botones
	var cs: float = 0.72
	_rect("cliff", Vector2(-190, -256), "br", cs)
	var fc := Control.new()
	fc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fc.size = Vector2(250, 250) * cs
	add_child(fc)
	_place(fc, Vector2(-190, -256), "br")
	_falls = Sprite2D.new()
	_falls.texture = _tex("falls")
	_falls.region_enabled = true
	_falls.region_rect = Rect2(0, 0, 250, 250)
	_falls.centered = false
	_falls.scale = Vector2(cs, cs)
	_falls.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	fc.add_child(_falls)
	# suelo en pendiente (dibujado con la paleta del mundo 1)
	var ground := Control.new()
	ground.set_anchors_preset(Control.PRESET_FULL_RECT)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ground.draw.connect(func(): _draw_ground(ground))
	ground.resized.connect(func(): ground.queue_redraw())
	add_child(ground)
	# puente de cuerda, árbol con cartel y tesoro
	_rect("bridge", Vector2(-292, -90), "br", 0.62)
	_rect("tree", Vector2(-8, -6), "tl", 0.62)
	_rect("sign", Vector2(22, 70), "tl", 0.62)
	_rect("chest", Vector2(6, -74), "bl", 0.8)
	for g in [[Vector2(58, -42), 0.9], [Vector2(74, -36), 0.7], [Vector2(2, -34), 0.6]]:
		_rect("gem", g[0], "bl", g[1])


func _surface_y(x: float, h: float) -> float:
	## Altura del suelo en x: baja en pendiente desde la izquierda y luego sigue llana hasta el puente.
	var t: float = clampf(x / 300.0, 0.0, 1.0)
	return h - 98.0 + 62.0 * t * (2.0 - t) * 0.5 + 6.0 * sin(x * 0.04) * (1.0 - t)


func _draw_ground(c: Control) -> void:
	var w: float = c.size.x
	var h: float = c.size.y
	var step: float = 4.0
	var top: PackedVector2Array = PackedVector2Array()
	var x: float = 0.0
	while x <= w + step:
		top.append(Vector2(x, _surface_y(x, h)))
		x += step
	# tierra
	var soil: PackedVector2Array = top.duplicate()
	soil.append(Vector2(w + step, h + 4.0))
	soil.append(Vector2(0.0, h + 4.0))
	c.draw_colored_polygon(soil, Color("#8a5a2e"))
	# estratos y piedrecitas
	for i in range(0, int(w), 22):
		var yy: float = _surface_y(float(i), h) + 14.0 + float((i * 7) % 11)
		c.draw_line(Vector2(i, yy), Vector2(i + 12, yy + 2), Color("#6a4020"), 2.0)
		c.draw_circle(Vector2(i + 5, yy + 9), 1.6, Color("#a87444"))
	# hierba: banda gruesa con flequillo y brillo
	var band: PackedVector2Array = PackedVector2Array()
	for p in top:
		band.append(p)
	for i in range(top.size() - 1, -1, -1):
		band.append(top[i] + Vector2(0, 9.0 + float((i * 5) % 3)))
	c.draw_colored_polygon(band, Color("#58c84a"))
	for p in top:
		c.draw_rect(Rect2(p.x, p.y - 1.0, step, 2.0), Color("#a6f070"))
	for i in range(0, int(w), 9):
		var py: float = _surface_y(float(i), h)
		c.draw_line(Vector2(i, py + 1), Vector2(i - 2, py - 5), Color("#3a9a3a"), 1.5)
		c.draw_line(Vector2(i + 3, py + 1), Vector2(i + 4, py - 4), Color("#8ae860"), 1.5)
	# flores
	for i in range(14, int(w), 53):
		var fy: float = _surface_y(float(i), h) - 3.0
		c.draw_circle(Vector2(i, fy), 2.0, Color("#ff7ab0") if (i / 53) % 2 == 0 else Color("#ffe05a"))


# ------------------------------------------------------------------ héroe ---
func _build_hero() -> void:
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size = Vector2(160, 160)
	add_child(holder)
	_place(holder, Vector2(30, -196), "bl")
	var root := Node2D.new()
	root.position = Vector2(66, 82)
	root.scale = Vector2(3.6, 3.6)
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	holder.add_child(root)
	HeroPreview.build(root, "run")
	# vaivén suave de carrera
	var tw := create_tween().set_loops()
	tw.tween_property(root, "position:y", 79.0, 0.28).set_trans(Tween.TRANS_SINE)
	tw.tween_property(root, "position:y", 84.0, 0.28).set_trans(Tween.TRANS_SINE)
	# monedas alrededor (sprites reales que giran y flotan)
	var t0: Texture2D = _tex("coin0")
	var t1: Texture2D = _tex("coin1")
	var spots := [[Vector2(10, 110), 0], [Vector2(112, 52), 1], [Vector2(14, 36), 2], [Vector2(116, 104), 3]]
	for i in range(spots.size()):
		var sp := Sprite2D.new()
		sp.texture = t0
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sp.scale = Vector2(1.0, 1.0)
		sp.position = spots[i][0]
		holder.add_child(sp)
		_coins.append({"node": sp, "tex": [t0, t1], "phase": float(spots[i][1])})
		var bob := create_tween().set_loops()
		bob.tween_property(sp, "position:y", sp.position.y - 5.0, 0.7 + 0.1 * float(i)).set_trans(Tween.TRANS_SINE)
		bob.tween_property(sp, "position:y", sp.position.y + 4.0, 0.7 + 0.1 * float(i)).set_trans(Tween.TRANS_SINE)


# ------------------------------------------------------------------- logo ---
func _build_logo() -> void:
	_logo = TextureRect.new()
	_logo.texture = _tex("logo")
	_logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_logo.stretch_mode = TextureRect.STRETCH_SCALE
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.size = Vector2(212, 99)
	_logo.pivot_offset = _logo.size * 0.5
	add_child(_logo)
	_logo.anchor_left = 0.41
	_logo.anchor_right = 0.41
	_logo.anchor_top = 0.0
	_logo.anchor_bottom = 0.0
	_logo.offset_left = -106.0
	_logo.offset_right = 106.0
	_logo.offset_top = 0.0
	_logo.offset_bottom = 99.0
	var tw := create_tween().set_loops()
	tw.tween_property(_logo, "position:y", 5.0, 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_logo, "position:y", -1.0, 1.2).set_trans(Tween.TRANS_SINE)


# ---------------------------------------------------------------- botones ---
func _btn_style(color: String, tint: Color) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = _tex("btn_" + color)
	sb.texture_margin_left = 15
	sb.texture_margin_right = 15
	sb.texture_margin_top = 13
	sb.texture_margin_bottom = 13
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 1
	sb.content_margin_bottom = 3
	sb.modulate_color = tint
	return sb


func _big_button(text: String, color: String, icon_name: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(166, 26)
	b.focus_mode = Control.FOCUS_ALL
	b.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	b.add_theme_stylebox_override("normal", _btn_style(color, Color(1, 1, 1)))
	b.add_theme_stylebox_override("hover", _btn_style(color, Color(1.14, 1.14, 1.14)))
	b.add_theme_stylebox_override("focus", _btn_style(color, Color(1.14, 1.14, 1.14)))
	b.add_theme_stylebox_override("pressed", _btn_style(color, Color(0.78, 0.78, 0.78)))
	b.add_theme_font_override("font", FONT)
	b.add_theme_font_size_override("font_size", 13)
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(k, Color.WHITE)
	b.add_theme_color_override("font_outline_color", Color("#1a1226"))
	b.add_theme_constant_override("outline_size", 4)
	b.icon = _tex("icon_" + icon_name)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.expand_icon = false
	b.add_theme_constant_override("h_separation", 2)
	b.pressed.connect(func():
		Audio.play_sfx("select")
		cb.call())
	return b


func _build_buttons() -> void:
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 3)
	_menu.size = Vector2(166, 171)
	add_child(_menu)
	_menu.anchor_left = 1.0
	_menu.anchor_right = 1.0
	_menu.anchor_top = 0.0
	_menu.anchor_bottom = 0.0
	_menu.offset_left = -176.0
	_menu.offset_right = -10.0
	_menu.offset_top = 76.0
	_menu.offset_bottom = 247.0
	var has_progress: bool = Game.continue_level() > 1 or Game.levels.size() > 0
	_first = _big_button("CONTINUAR" if has_progress else "JUGAR", "green", "play", _on_play)
	_menu.add_child(_first)
	_menu.add_child(_big_button("MAPA DE NIVELES", "blue", "map", func(): Transition.change_scene("res://ui/level_select.tscn")))
	_menu.add_child(_big_button("WILMEN WORLD", "teal", "world", func(): Transition.change_scene("res://ui/ww_map.tscn")))
	_menu.add_child(_big_button("EXTRAS", "purple", "star", func(): Transition.change_scene("res://ui/extras.tscn")))
	_menu.add_child(_big_button("OPCIONES", "orange", "gear", _show_options))
	_menu.add_child(_big_button("SALIR", "red", "door", func(): get_tree().quit()))
	_first.grab_focus()
	# entrada: los botones se deslizan desde la derecha
	var i: int = 0
	for b in _menu.get_children():
		b.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_interval(0.06 * float(i))
		tw.tween_property(b, "modulate:a", 1.0, 0.25)
		i += 1


func _round_button(name: String, tip: String, cb: Callable) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = _tex("round_" + name)
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.custom_minimum_size = Vector2(36, 36)
	b.size = Vector2(36, 36)
	b.pivot_offset = Vector2(18, 18)
	b.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	b.tooltip_text = tip
	b.focus_mode = Control.FOCUS_ALL
	b.button_down.connect(func(): b.scale = Vector2(0.9, 0.9))
	b.button_up.connect(func(): b.scale = Vector2.ONE)
	b.pressed.connect(func():
		Audio.play_sfx("select")
		cb.call())
	return b


func _build_round_buttons() -> void:
	var trophy := _round_button("trophy", "Logros", func():
		Engine.set_meta("extras_tab", "achievements")
		Transition.change_scene("res://ui/extras.tscn"))
	add_child(trophy)
	_place(trophy, Vector2(-92, 8), "tr")
	var music := _round_button("music", "Música y sonido", _show_audio)
	add_child(music)
	_place(music, Vector2(-50, 8), "tr")


func _build_stats_bar() -> void:
	var bar := NinePatchRect.new()
	bar.texture = _tex("bar")
	bar.patch_margin_left = 12
	bar.patch_margin_right = 12
	bar.patch_margin_top = 12
	bar.patch_margin_bottom = 12
	bar.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	bar.size = Vector2(298, 24)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	_place(bar, Vector2(4, -30 - Ads.banner_reserved()), "bl")
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 10
	row.offset_right = -10
	row.add_theme_constant_override("separation", 3)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_child(row)
	var items := [
		["star", "Niveles %d/%d" % [Game.completed_count(), Game.LEVEL_COUNT]],
		["diamond", "Gemas %d/%d" % [Game.total_gems(), Game.LEVEL_COUNT * 3]],
		["trophy", "Puntos %d" % Game.score],
	]
	for i in range(items.size()):
		if i > 0:
			var sep := ColorRect.new()
			sep.color = Color("#5a3418")
			sep.custom_minimum_size = Vector2(2, 16)
			sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(sep)
		var ic := TextureRect.new()
		ic.texture = _tex("icon_" + str(items[i][0]))
		ic.custom_minimum_size = Vector2(13, 13)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(ic)
		var l := UiTheme.label(str(items[i][1]), 8, Color.WHITE)
		l.add_theme_font_override("font", FONT)
		l.add_theme_constant_override("outline_size", 3)
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(l)


func _build_notices() -> void:
	if Ads.banner_reserved() <= 0.0:  # con banner visible la franja inferior es suya y no hay sitio para la versión
		var ver := UiTheme.label("v2.1 - 100 niveles" + ("" if Ads.active() else " - sin anuncios"), 8, Color("#ffffff"))
		add_child(ver)
		ver.size = Vector2(170, 12)
		ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_place(ver, Vector2(-180, -14), "br")
	if Game.migrated_from_v1:
		var mig := UiTheme.label("Progreso de la versión anterior migrado a los 100 niveles", 9, Color("#8affb0"))
		add_child(mig)
		mig.size = Vector2(300, 12)
		_place(mig, Vector2(10, -46 - Ads.banner_reserved()), "bl")


func _exit_tree() -> void:
	Ads.set_banner(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _options != null:
			_close_options()
		else:
			get_tree().quit()


func _on_play() -> void:
	if Game.start_level(Game.continue_level()):
		Transition.change_scene("res://levels/level.tscn")


func _show_audio() -> void:
	## Ventana de música y sonido (volumen y silencio independientes).
	if _options != null:
		return
	var o := Control.new()
	o.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.01, 0.08, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	o.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	o.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	var t := UiTheme.label("MÚSICA Y SONIDO", 18)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	v.add_child(AudioPanel.build(260.0))
	var back := UiTheme.button("Volver", Vector2(140, 34))
	back.pressed.connect(func():
		Audio.play_sfx("back")
		_close_options())
	v.add_child(back)
	add_child(o)
	_options = o
	back.grab_focus()


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
