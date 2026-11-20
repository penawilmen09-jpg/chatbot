extends Control
## Mapa de selección: 10 mundos x 10 niveles. Candados, marcas de completado, estrellas (gemas),
## progreso por mundo, jefes derrotados y destaque del nivel disponible.
## El desbloqueo se valida SIEMPRE con Game.start_level(), no solo ocultando botones.

const UiTheme := preload("res://ui/ui_theme.gd")
const MenuBg := preload("res://ui/menu_background.gd")
const Glyph := preload("res://ui/glyph.gd")

var _world: int = 1
var _bg_holder: Control
var _chips: HBoxContainer
var _grid: GridContainer
var _header_name: Label
var _header_info: Label
var _bar_fill: ColorRect
var _boss_glyph: Control
var _stats_label: Label
var _toast_label: Label
var _toast_tw: Tween = null
var _current_btn: Button = null

const BAR_W := 120.0


func _ready() -> void:
	theme = UiTheme.make()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_world = clampi(Game.world_of(Game.continue_level()), 1, Game.WORLD_COUNT)
	_bg_holder = Control.new()
	_bg_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_holder)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	margin.add_child(v)

	# --- barra superior
	var top := HBoxContainer.new()
	top.custom_minimum_size.y = 22
	v.add_child(top)
	var title := UiTheme.label("MAPA DE MUNDOS", 16)
	top.add_child(title)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	_stats_label = UiTheme.label("", 10, Color("#ffe97a"))
	_stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(_stats_label)

	# --- fichas de mundo
	_chips = HBoxContainer.new()
	_chips.alignment = BoxContainer.ALIGNMENT_CENTER
	_chips.add_theme_constant_override("separation", 4)
	v.add_child(_chips)

	# --- cabecera del mundo
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.custom_minimum_size.y = 22
	v.add_child(head)
	_header_name = UiTheme.label("", 13)
	_header_name.custom_minimum_size.x = 210
	_header_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(_header_name)
	var bar_holder := Control.new()
	bar_holder.custom_minimum_size = Vector2(BAR_W, 14)
	bar_holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(bar_holder)
	var bar_bg := ColorRect.new()
	bar_bg.color = Color("#1a1226")
	bar_bg.size = Vector2(BAR_W, 12)
	bar_holder.add_child(bar_bg)
	_bar_fill = ColorRect.new()
	_bar_fill.position = Vector2(1, 1)
	_bar_fill.size = Vector2(0, 10)
	bar_holder.add_child(_bar_fill)
	_header_info = UiTheme.label("", 10)
	_header_info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(_header_info)
	_boss_glyph = Glyph.new()
	_boss_glyph.kind = "crown"
	_boss_glyph.custom_minimum_size = Vector2(18, 16)
	_boss_glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_boss_glyph)

	# --- cuadrícula de niveles (5 x 2)
	_grid = GridContainer.new()
	_grid.columns = 5
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 6)
	var gc := CenterContainer.new()
	gc.add_child(_grid)
	v.add_child(gc)

	# --- pie
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 8)
	v.add_child(foot)
	var back := UiTheme.button("Atrás", Vector2(100, 32))
	back.pressed.connect(_go_back)
	foot.add_child(back)
	_toast_label = UiTheme.label("", 10, Color("#ffb0a0"))
	_toast_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	foot.add_child(_toast_label)
	var cont := UiTheme.button("Continuar", Vector2(120, 32))
	cont.pressed.connect(_on_continue)
	foot.add_child(cont)

	_refresh()
	Audio.play_music("map")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back()


func _go_back() -> void:
	Audio.play_sfx("back")
	Transition.change_scene("res://ui/title.tscn")


func _on_continue() -> void:
	_start(Game.continue_level())


func _start(n: int) -> void:
	if not Game.start_level(n):
		Audio.play_sfx("hurt")
		if n > 1:
			_toast("Completa antes el nivel %d (%s)." % [n - 1, Game.LEVEL_NAMES[n - 2]])
		return
	Audio.play_sfx("select")
	Transition.change_scene("res://levels/level.tscn")


func _toast(text: String) -> void:
	_toast_label.text = text
	_toast_label.modulate.a = 1.0
	if _toast_tw != null and _toast_tw.is_valid():
		_toast_tw.kill()
	_toast_tw = create_tween()
	_toast_tw.tween_interval(2.2)
	_toast_tw.tween_property(_toast_label, "modulate:a", 0.0, 0.5)


func _select_world(w: int) -> void:
	if not Game.is_world_unlocked(w):
		Audio.play_sfx("hurt")
		_toast("Mundo bloqueado: completa antes el mundo %d." % (w - 1))
		return
	_world = w
	Audio.play_sfx("click")
	_refresh()


func _box(bg: Color, border: Color, width: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(5)
	return sb


func _style_button(b: Button, bg: Color, border: Color, width: int = 2) -> void:
	b.add_theme_stylebox_override("normal", _box(bg, border, width))
	b.add_theme_stylebox_override("hover", _box(bg.lightened(0.15), border.lightened(0.2), width))
	b.add_theme_stylebox_override("pressed", _box(bg.lightened(0.3), Color.WHITE, width))
	b.add_theme_stylebox_override("disabled", _box(bg, border, width))
	b.add_theme_stylebox_override("focus", _box(Color(0, 0, 0, 0), Color("#ffffff"), 2))


func _refresh() -> void:
	for c in _bg_holder.get_children():
		c.queue_free()
	var bg = MenuBg.new()
	bg.world = _world
	bg.speed = 10.0
	_bg_holder.add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.01, 0.08, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_holder.add_child(shade)

	_stats_label.text = "Niveles %d/100   Gemas %d/300   Puntos %d" % [Game.completed_count(), Game.total_gems(), Game.score]
	_build_chips()
	_build_header()
	_build_grid()


func _build_chips() -> void:
	for c in _chips.get_children():
		c.queue_free()
	for w in range(1, Game.WORLD_COUNT + 1):
		var unlocked: bool = Game.is_world_unlocked(w)
		var done: bool = Game.worlds_done.has(w)
		var b := Button.new()
		b.custom_minimum_size = Vector2(40, 28)
		b.focus_mode = Control.FOCUS_NONE
		var col: Color = Game.WORLD_COLORS[w - 1]
		if unlocked:
			_style_button(b, col.darkened(0.55), col if w != _world else Color.WHITE, 3 if w == _world else 2)
		else:
			_style_button(b, Color("#1c1632"), Color("#4a4268"), 2)
		var lbl := UiTheme.label(str(w), 13, Color.WHITE if unlocked else Color("#7a7298"))
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if not unlocked:
			lbl.position.y = -4
		b.add_child(lbl)
		if not unlocked:
			var lk = Glyph.new()
			lk.kind = "lock"
			lk.size = Vector2(12, 12)
			lk.position = Vector2(14, 15)
			b.add_child(lk)
		elif done:
			var ck = Glyph.new()
			ck.kind = "check"
			ck.size = Vector2(12, 12)
			ck.position = Vector2(26, 0)
			b.add_child(ck)
		var wi: int = w
		b.pressed.connect(func(): _select_world(wi))
		_chips.add_child(b)


func _build_header() -> void:
	var col: Color = Game.WORLD_COLORS[_world - 1]
	_header_name.text = "Mundo %d: %s" % [_world, Game.WORLD_NAMES[_world - 1]]
	_header_name.add_theme_color_override("font_color", col)
	var prog: int = Game.world_progress(_world)
	_bar_fill.color = col
	_bar_fill.size.x = (BAR_W - 2.0) * float(prog) / float(Game.LEVELS_PER_WORLD)
	var gems: int = 0
	for i in range(1, Game.LEVELS_PER_WORLD + 1):
		gems += Game.gems_in_level(Game.level_number(_world, i))
	_header_info.text = "%d/10   Gemas %d/30" % [prog, gems]
	var boss_done: bool = Game.worlds_done.has(_world)
	_boss_glyph.filled = boss_done
	_boss_glyph.queue_redraw()
	_boss_glyph.tooltip_text = "Jefe: %s%s" % [Game.BOSS_NAMES[_world - 1], " (derrotado)" if boss_done else ""]


func _build_grid() -> void:
	for c in _grid.get_children():
		c.queue_free()
	_current_btn = null
	var highest: int = Game.continue_level()
	var focus_btn: Button = null
	for i in range(1, Game.LEVELS_PER_WORLD + 1):
		var n: int = Game.level_number(_world, i)
		var b := _level_button(n, highest)
		_grid.add_child(b)
		if n == highest:
			focus_btn = b
	if focus_btn != null:
		focus_btn.grab_focus()


func _level_button(n: int, highest: int) -> Button:
	var unlocked: bool = Game.is_unlocked(n)
	var done: bool = Game.is_done(n)
	var boss: bool = Game.is_boss_level(n)
	var secret: bool = Game.is_secret_level(n)
	var current: bool = n == highest and not done
	var rec: Dictionary = Game.get_record(n)
	var col: Color = Game.WORLD_COLORS[_world - 1]
	var b := Button.new()
	b.custom_minimum_size = Vector2(84, 62)
	b.focus_mode = Control.FOCUS_ALL
	if not unlocked:
		_style_button(b, Color("#171229"), Color("#3a3458"), 2)
	elif current:
		_style_button(b, col.darkened(0.5), Color("#ffe05a"), 4)
	elif boss:
		_style_button(b, Color("#3a1620"), Color("#ff6a5a"), 2)
	elif secret:
		_style_button(b, Color("#2a1640"), Color("#e07aff"), 2)
	elif done:
		_style_button(b, col.darkened(0.6), Color("#5adf7a"), 2)
	else:
		_style_button(b, col.darkened(0.55), col, 2)

	var num := UiTheme.label(str(Game.index_in_world(n)), 15, Color.WHITE if unlocked else Color("#6a6288"))
	num.position = Vector2(7, 1)
	b.add_child(num)
	var name_lbl := UiTheme.label(Game.LEVEL_NAMES[n - 1] if unlocked else "Bloqueado", 8, Color("#d8d0ff") if unlocked else Color("#6a6288"))
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	name_lbl.offset_left = 3
	name_lbl.offset_right = -3
	name_lbl.offset_top = 20
	name_lbl.offset_bottom = -17
	b.add_child(name_lbl)

	if not unlocked:
		var lk = Glyph.new()
		lk.kind = "lock"
		lk.size = Vector2(22, 22)
		lk.position = Vector2(31, 18)
		b.add_child(lk)
	else:
		# estrellas = gemas conseguidas (3 por nivel)
		for k in range(3):
			var st = Glyph.new()
			st.kind = "star"
			st.filled = bool(rec["gems"][k])
			st.size = Vector2(11, 11)
			st.position = Vector2(5 + k * 12, 48)
			b.add_child(st)
		if done:
			var sc := UiTheme.label(str(int(rec["best"])), 8, Color("#ffe97a"))
			sc.position = Vector2(42, 47)
			sc.custom_minimum_size = Vector2(38, 12)
			sc.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			b.add_child(sc)
		if done:
			var ck = Glyph.new()
			ck.kind = "check"
			ck.size = Vector2(15, 15)
			ck.position = Vector2(66, 2)
			b.add_child(ck)
		elif boss:
			var cr = Glyph.new()
			cr.kind = "crown"
			cr.size = Vector2(17, 14)
			cr.position = Vector2(63, 3)
			b.add_child(cr)
		elif secret:
			var q := UiTheme.label("?", 13, Color("#e07aff"))
			q.position = Vector2(68, 1)
			b.add_child(q)
		if done and boss:
			var cr2 = Glyph.new()
			cr2.kind = "crown"
			cr2.size = Vector2(14, 11)
			cr2.position = Vector2(50, 3)
			b.add_child(cr2)

	if current:
		_current_btn = b
		var tw := create_tween().set_loops()
		tw.tween_property(b, "modulate", Color(1.25, 1.25, 1.0), 0.6).set_trans(Tween.TRANS_SINE)
		tw.tween_property(b, "modulate", Color.WHITE, 0.6).set_trans(Tween.TRANS_SINE)

	var level_n: int = n
	b.pressed.connect(func(): _start(level_n))
	return b
