extends CanvasLayer
## Navegación entre pantallas con transición suave, entradas y datos de la partida en curso.

const MENU := "res://scenes/main_menu.tscn"
const GARAGE := "res://scenes/garage.tscn"
const SHOP := "res://scenes/shop.tscn"
const SETTINGS := "res://scenes/settings.tscn"
const GAME := "res://scenes/gameplay.tscn"


var _fade: ColorRect
var _busy := false

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade = ColorRect.new()
	_fade.color = Color(0.03, 0.06, 0.14, 1.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	add_child(_fade)
	UIKit.fit(_fade)
	_setup_inputs()
	get_tree().set_auto_accept_quit(false)

func _setup_inputs() -> void:
	_add_action("gas", [KEY_RIGHT, KEY_D, KEY_UP, KEY_W])
	_add_action("brake", [KEY_LEFT, KEY_A, KEY_DOWN, KEY_S])

func _add_action(name: String, keys: Array) -> void:
	if not InputMap.has_action(name):
		InputMap.add_action(name)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(name, ev)

func go(path: String) -> void:
	if _busy:
		return
	_busy = true
	get_tree().paused = false
	var t := create_tween()
	t.tween_property(_fade, "modulate:a", 1.0, 0.18)
	await t.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	var t2 := create_tween()
	t2.tween_property(_fade, "modulate:a", 0.0, 0.22)
	await t2.finished
	_busy = false

func start_run() -> void:
	go(GAME)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST or what == NOTIFICATION_WM_CLOSE_REQUEST:
		var cur := get_tree().current_scene
		if cur and cur.has_method("on_back"):
			cur.call("on_back")
		elif what == NOTIFICATION_WM_CLOSE_REQUEST:
			SaveManager.save_game()
			get_tree().quit()
