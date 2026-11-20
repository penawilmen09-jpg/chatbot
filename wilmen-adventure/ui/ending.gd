extends Control
## Final del juego.

const UiTheme := preload("res://ui/ui_theme.gd")
const MenuBg := preload("res://ui/menu_background.gd")


func _ready() -> void:
	theme = UiTheme.make()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg = MenuBg.new()
	bg.world = 10
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	center.add_child(v)
	var t := UiTheme.label("¡FELICIDADES!", 32, Color("#ffd23a"))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	for line in [
		"Wilmen derrotó al Emperador del Vacío",
		"y devolvió la luz a los diez mundos.",
		"",
		"Niveles: %d / 100" % Game.completed_count(),
		"Gemas: %d / 300" % Game.total_gems(),
		"Monedas: %d" % Game.total_coins,
		"Puntos: %d" % Game.score,
	]:
		var l := UiTheme.label(line, 13)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	var b := UiTheme.button("Volver al menú", Vector2(220, 38))
	b.pressed.connect(func():
		Audio.play_sfx("select")
		Transition.change_scene("res://ui/title.tscn"))
	v.add_child(b)
	b.grab_focus()
	Audio.play_music("victory_world", false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Transition.change_scene("res://ui/title.tscn")
