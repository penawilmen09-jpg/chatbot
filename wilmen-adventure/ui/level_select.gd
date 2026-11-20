extends Control
## Selección de nivel: 5 mundos x 4 niveles, con candados, gemas y jefes.

const UiTheme := preload("res://ui/ui_theme.gd")
const MenuBg := preload("res://ui/menu_background.gd")

var _world: int = 1
var _bg_holder: Control
var _grid: HBoxContainer
var _world_label: Label
var _stats_label: Label
var _dots: Array = []


func _ready() -> void:
	theme = UiTheme.make()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_world = clampi(Game.world_of(Game.highest_unlocked), 1, 5)
	_bg_holder = Control.new()
	_bg_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg_holder)

	var title := UiTheme.label("SELECCIONA NIVEL", 20)
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.offset_left = -150
	title.offset_right = 150
	title.offset_top = 8
	title.offset_bottom = 34
	add_child(title)

	_stats_label = UiTheme.label("", 10, Color("#ffe97a"))
	_stats_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.offset_left = -150
	_stats_label.offset_right = 150
	_stats_label.offset_top = 34
	_stats_label.offset_bottom = 50
	add_child(_stats_label)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_top = 46
	center.offset_bottom = -46
	add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	center.add_child(v)

	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 12)
	v.add_child(nav)
	var prev := UiTheme.button("<", Vector2(48, 40))
	prev.pressed.connect(func(): _change_world(-1))
	nav.add_child(prev)
	_world_label = UiTheme.label("", 16)
	_world_label.custom_minimum_size = Vector2(250, 30)
	_world_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_world_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nav.add_child(_world_label)
	var nxt := UiTheme.button(">", Vector2(48, 40))
	nxt.pressed.connect(func(): _change_world(1))
	nav.add_child(nxt)

	_grid = HBoxContainer.new()
	_grid.add_theme_constant_override("separation", 8)
	_grid.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(_grid)

	var dots := HBoxContainer.new()
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	dots.add_theme_constant_override("separation", 6)
	v.add_child(dots)
	for i in range(5):
		var d := ColorRect.new()
		d.custom_minimum_size = Vector2(10, 10)
		dots.add_child(d)
		_dots.append(d)

	var back := UiTheme.button("Atrás", Vector2(110, 36))
	back.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	back.offset_left = 10
	back.offset_top = -46
	back.offset_right = 120
	back.offset_bottom = -10
	back.pressed.connect(_go_back)
	add_child(back)
	_refresh()
	Audio.play_music("title")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back()


func _go_back() -> void:
	Audio.play_sfx("back")
	Transition.change_scene("res://ui/title.tscn")


func _change_world(d: int) -> void:
	_world = clampi(_world + d, 1, 5)
	Audio.play_sfx("click")
	_refresh()


func _refresh() -> void:
	for c in _bg_holder.get_children():
		c.queue_free()
	var bg = MenuBg.new()
	bg.world = _world
	bg.speed = 10.0
	_bg_holder.add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.01, 0.08, 0.35)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_holder.add_child(shade)

	_world_label.text = "Mundo %d: %s" % [_world, Game.WORLD_NAMES[_world - 1]]
	_world_label.add_theme_color_override("font_color", Game.WORLD_COLORS[_world - 1])
	_stats_label.text = "Gemas %d/60    Puntos %d" % [Game.total_gems(), Game.score]
	for i in range(_dots.size()):
		_dots[i].color = Game.WORLD_COLORS[i] if i == _world - 1 else Color(1, 1, 1, 0.3)

	for c in _grid.get_children():
		c.queue_free()
	var first_button: Button = null
	for k in range(1, 5):
		var n: int = (_world - 1) * 4 + k
		var b := _level_button(n)
		_grid.add_child(b)
		if first_button == null and Game.is_unlocked(n):
			first_button = b
	if first_button != null:
		first_button.grab_focus()


func _level_button(n: int) -> Button:
	var unlocked: bool = Game.is_unlocked(n)
	var b := Button.new()
	b.custom_minimum_size = Vector2(104, 112)
	b.focus_mode = Control.FOCUS_ALL
	var boss: bool = Game.is_boss_level(n)
	var rec: Dictionary = Game.get_record(n)
	var num := UiTheme.label("%d-%d" % [Game.world_of(n), Game.index_in_world(n)], 18)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.set_anchors_preset(Control.PRESET_TOP_WIDE)
	num.offset_top = 6
	num.offset_bottom = 30
	b.add_child(num)
	if boss:
		var tag := UiTheme.label("JEFE", 10, Color("#ff9a8a"))
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.set_anchors_preset(Control.PRESET_TOP_WIDE)
		tag.offset_top = 30
		tag.offset_bottom = 44
		b.add_child(tag)
	var name_lbl := UiTheme.label(Game.LEVEL_NAMES[n - 1] if unlocked else "Bloqueado", 9, Color("#cfc6ff") if unlocked else Color("#8a82a8"))
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	name_lbl.offset_top = 46
	name_lbl.offset_bottom = -24
	name_lbl.offset_left = 4
	name_lbl.offset_right = -4
	b.add_child(name_lbl)
	var gems := HBoxContainer.new()
	gems.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	gems.alignment = BoxContainer.ALIGNMENT_CENTER
	gems.offset_top = -22
	gems.offset_bottom = -4
	gems.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(3):
		var g := TextureRect.new()
		g.texture = UiTheme.icon(UiTheme.ICON_GEM)
		g.custom_minimum_size = Vector2(16, 16)
		g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		g.mouse_filter = Control.MOUSE_FILTER_IGNORE
		g.modulate = Color.WHITE if bool(rec["gems"][i]) else Color(0.25, 0.25, 0.3, 0.8)
		gems.add_child(g)
	b.add_child(gems)
	if unlocked:
		b.pressed.connect(func():
			Audio.play_sfx("select")
			Game.current_level = n
			Transition.change_scene("res://levels/level.tscn"))
	else:
		b.disabled = true
	return b
