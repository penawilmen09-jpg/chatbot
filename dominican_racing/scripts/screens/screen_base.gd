class_name ScreenBase
extends Control
## Base común de pantallas de menú: fondo animado, barra superior con volver/título/monedas.

var backdrop: Backdrop
var content: Control
var coin_chip: UIKit.CoinChip

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Sfx.play_music()
	_build()

func _build() -> void:
	pass

func add_backdrop(world_id := 1, vehicle: Dictionary = {}, speed := 60.0) -> void:
	if backdrop:
		backdrop.queue_free()
	backdrop = Backdrop.new()
	backdrop.setup(world_id, vehicle, speed)
	add_child(backdrop)
	move_child(backdrop, 0)

func add_topbar(title: String, show_back := true) -> void:
	var bar := Control.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = 84
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	if show_back:
		var back := UIKit.button("◀  MENÚ", UIKit.BLUE, Vector2(170, 60), 24)
		back.position = Vector2(20, 12)
		back.pressed.connect(on_back)
		bar.add_child(back)
	var t := UIKit.label(title, 46, UIKit.GOLD)
	t.set_anchors_preset(Control.PRESET_CENTER_TOP)
	t.anchor_left = 0.5
	t.anchor_right = 0.5
	t.offset_left = -260
	t.offset_right = 260
	t.offset_top = 8
	t.offset_bottom = 74
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bar.add_child(t)
	coin_chip = UIKit.CoinChip.new()
	coin_chip.anchor_left = 1.0
	coin_chip.anchor_right = 1.0
	coin_chip.offset_left = -220
	coin_chip.offset_right = -20
	coin_chip.offset_top = 16
	bar.add_child(coin_chip)

func on_back() -> void:
	Nav.go(Nav.MENU)

func toast(text: String, color := UIKit.RED) -> void:
	UIKit.toast(self, text, color)
