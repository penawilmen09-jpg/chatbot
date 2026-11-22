extends Control
## Lista de niveles de WILMEN WORLD (acceso directo mientras el mapa general no está terminado: hito 3).
## Muestra los niveles que existen, con su región, límite de tiempo, dificultad, gemas y mejor tiempo, y permite jugarlos.

const UiTheme := preload("res://ui/ui_theme.gd")
const M := "res://assets/menu/"
const FONT := preload("res://assets/ui/DejaVuSans-Bold.ttf")

var _buttons: Dictionary = {}  # n -> Button
var _back: Button


func _ready() -> void:
	Game.world_leave()  # por si se llega aquí desde un nivel: la partida original ya está restaurada
	theme = UiTheme.make()
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = get_viewport_rect().size
	get_viewport().size_changed.connect(func(): size = get_viewport_rect().size)
	var sky := TextureRect.new()
	sky.texture = load(M + "sky.png")
	sky.stretch_mode = TextureRect.STRETCH_TILE
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sky)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.12, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var head := UiTheme.label("WILMEN WORLD · NIVELES", 20, Color("#ffd23a"))
	head.add_theme_font_override("font", FONT)
	head.anchor_left = 0.0
	head.anchor_right = 1.0
	head.offset_top = 6.0
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(head)
	var sub := UiTheme.label("Elige un nivel. Mira el reloj, busca las llaves y los túneles.", 8, Color("#e8f4ff"))
	sub.anchor_left = 0.0
	sub.anchor_right = 1.0
	sub.offset_top = 32.0
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)
	var scroll := ScrollContainer.new()
	scroll.anchor_left = 0.5
	scroll.anchor_right = 0.5
	scroll.anchor_top = 0.0
	scroll.anchor_bottom = 1.0
	scroll.offset_left = -215.0
	scroll.offset_right = 215.0
	scroll.offset_top = 46.0
	scroll.offset_bottom = -44.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)
	for n in WW.available_levels():
		v.add_child(_card(n))
	var keys := UiTheme.label("", 9, Color("#ffd23a"))
	keys.text = "Llaves x%d    Monedas %d    Vidas %d" % [WW.key_count(), WW.coins, WW.lives]
	keys.anchor_left = 0.0
	keys.anchor_right = 1.0
	keys.anchor_top = 1.0
	keys.anchor_bottom = 1.0
	keys.offset_top = -58.0
	keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(keys)
	_back = UiTheme.button("Volver", Vector2(130, 30))
	_back.anchor_left = 0.5
	_back.anchor_right = 0.5
	_back.anchor_top = 1.0
	_back.anchor_bottom = 1.0
	_back.offset_left = -65.0
	_back.offset_right = 65.0
	_back.offset_top = -38.0
	_back.offset_bottom = -8.0
	_back.pressed.connect(func():
		Audio.play_sfx("back")
		Transition.change_scene("res://ui/ww_hub.tscn"))
	add_child(_back)
	var first: Button = _buttons[WW.available_levels()[0]] if not WW.available_levels().is_empty() else _back
	first.grab_focus()
	Audio.play_music("map")


func _card(n: int) -> Button:
	var info: Dictionary = WW.level_info(n)
	var rec: Dictionary = WW.record(n)
	var region: int = clampi(int(info["region"]), 1, 6)
	var b := Button.new()
	b.custom_minimum_size = Vector2(420, 52)
	b.focus_mode = Control.FOCUS_ALL
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var best: String = ""
	if bool(rec["done"]):
		var t: int = int(rec["best_time"])
		best = "   ✔ mejor %d:%02d" % [t / 60, t % 60]
	var limit: int = int(info["time"])
	b.text = "  %d  %s\n  %s · Tiempo %d:%02d · Dificultad %d/5 · Gemas %d/3%s" % [n, str(info["title"]), WW.REGION_NAMES[region - 1], limit / 60, limit % 60, clampi(int(info["difficulty"]), 1, 5), WW.gems_in(n), best]
	b.add_theme_font_size_override("font_size", 10)
	b.add_theme_color_override("font_color", Color.WHITE)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.07, 0.2, 0.92)
	sb.border_color = WW.REGION_COLORS[region - 1]
	sb.set_border_width_all(2)
	sb.border_width_left = 8
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12
	b.add_theme_stylebox_override("normal", sb)
	var hv := sb.duplicate()
	hv.bg_color = Color(0.2, 0.14, 0.38, 0.95)
	b.add_theme_stylebox_override("hover", hv)
	b.add_theme_stylebox_override("focus", hv)
	b.add_theme_stylebox_override("pressed", hv)
	b.pressed.connect(func(): _play(n))
	_buttons[n] = b
	return b


func _play(n: int) -> void:
	Audio.play_sfx("select")
	if WW.start_level(n):
		Transition.change_scene("res://levels/ww_level.tscn")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Transition.change_scene("res://ui/ww_hub.tscn")
