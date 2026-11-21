class_name GameHUD
extends Control
## Interfaz durante la partida: distancia, récord, monedas, combustible y velocidad arriba;
## freno, pausa y acelerador abajo (controles táctiles grandes).

signal pause_pressed

class Speedo extends Control:
	var kmh := 0.0
	var max_kmh := 120.0
	func _init() -> void:
		custom_minimum_size = Vector2(150, 84)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var c := Vector2(size.x * 0.5, size.y - 6.0)
		var r := 66.0
		draw_arc(c, r, PI, TAU, 36, Color(0, 0, 0, 0.55), 18.0, true)
		draw_arc(c, r, PI, TAU, 36, Color(0.14, 0.18, 0.34, 0.95), 13.0, true)
		var f := clampf(kmh / max_kmh, 0.0, 1.0)
		var col := Color(0.2, 0.85, 0.4).lerp(Color(1.0, 0.25, 0.2), f)
		if f > 0.01:
			draw_arc(c, r, PI, PI + PI * f, 36, col, 13.0, true)
		var na := PI + PI * f
		draw_line(c, c + Vector2(cos(na), sin(na)) * (r - 8), Color(1.0, 0.3, 0.25), 4.0)
		draw_circle(c, 6, Color(0.92, 0.92, 0.96))
		var font := ThemeDB.fallback_font
		draw_string_outline(font, c + Vector2(-50, -20), str(int(kmh)), HORIZONTAL_ALIGNMENT_CENTER, 100, 30, 6, Color(0, 0, 0, 0.8))
		draw_string(font, c + Vector2(-50, -20), str(int(kmh)), HORIZONTAL_ALIGNMENT_CENTER, 100, 30, Color.WHITE)
		draw_string(font, c + Vector2(-50, -2), "km/h", HORIZONTAL_ALIGNMENT_CENTER, 100, 14, Color(1, 1, 1, 0.75))

class FuelGauge extends Control:
	var ratio := 1.0
	var _t := 0.0
	func _init() -> void:
		custom_minimum_size = Vector2(270, 46)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
	func _draw() -> void:
		var bar := Rect2(Vector2(56, 8), Vector2(size.x - 60, 30))
		draw_style_box(UIKit.box(Color(0.04, 0.06, 0.16, 0.9), 15, Color(1, 1, 1, 0.55), 2), bar)
		var col := Color(0.2, 0.85, 0.35)
		if ratio < 0.5:
			col = Color(1.0, 0.8, 0.15)
		if ratio < 0.22:
			col = Color(1.0, 0.2, 0.18)
			if int(_t * 5.0) % 2 == 0:
				col = col.lightened(0.4)
		var inner := Rect2(bar.position + Vector2(3, 3), Vector2((bar.size.x - 6) * clampf(ratio, 0, 1), bar.size.y - 6))
		if inner.size.x > 1:
			draw_style_box(UIKit.box(col, 12), inner)
			draw_rect(Rect2(inner.position + Vector2(6, 3), Vector2(maxf(inner.size.x - 12, 0), 4)), Color(1, 1, 1, 0.3))
		draw_rect(Rect2(8, 7, 34, 36), Color(0.88, 0.14, 0.12))
		draw_rect(Rect2(8, 7, 34, 36), Color.WHITE, false, 2.0)
		draw_rect(Rect2(15, 1, 15, 8), Color(0.2, 0.2, 0.25))
		draw_rect(Rect2(17, 18, 16, 15), Color(1.0, 0.92, 0.3))
		var f := ThemeDB.fallback_font
		draw_string_outline(f, Vector2(56, 31), "%d%%" % int(ratio * 100.0), HORIZONTAL_ALIGNMENT_CENTER, size.x - 60, 20, 5, Color(0, 0, 0, 0.8))
		draw_string(f, Vector2(56, 31), "%d%%" % int(ratio * 100.0), HORIZONTAL_ALIGNMENT_CENTER, size.x - 60, 20, Color.WHITE)

var speedo: Speedo
var fuel_gauge: FuelGauge
var coin_label: Label
var dist_label: Label
var record_label: Label
var toast_label: Label
var gas: Pedal
var brake: Pedal
var banner: Label
var _banner_tween: Tween
var _toast_tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.fit(self)
	# --- arriba izquierda: monedas ---
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", UIKit.box(Color(0.05, 0.08, 0.2, 0.78), 26, Color(1.0, 0.8, 0.15, 0.85), 3, 6))
	chip.position = Vector2(18, 14)
	var m := MarginContainer.new()
	for sd in ["left", "right"]:
		m.add_theme_constant_override("margin_" + sd, 12)
	for sd in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + sd, 6)
	chip.add_child(m)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	m.add_child(h)
	h.add_child(UIKit.CoinIcon.new(38.0))
	coin_label = UIKit.label("0", 36, UIKit.GOLD)
	coin_label.custom_minimum_size = Vector2(70, 0)
	h.add_child(coin_label)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(chip)
	# --- arriba centro: distancia y récord ---
	var center := VBoxContainer.new()
	center.anchor_left = 0.5
	center.anchor_right = 0.5
	center.offset_left = -170
	center.offset_right = 170
	center.offset_top = 6
	center.add_theme_constant_override("separation", -4)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	dist_label = UIKit.label("0 m", 62, Color.WHITE)
	dist_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dist_label.add_theme_constant_override("outline_size", 12)
	center.add_child(dist_label)
	record_label = UIKit.label("RÉCORD 0 m", 22, Color(1.0, 0.86, 0.35))
	record_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(record_label)
	toast_label = UIKit.label("", 28, Color(0.7, 1.0, 0.85))
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.modulate.a = 0.0
	center.add_child(toast_label)
	# --- arriba derecha: combustible y velocidad ---
	var right := VBoxContainer.new()
	right.anchor_left = 1.0
	right.anchor_right = 1.0
	right.offset_left = -300
	right.offset_right = -18
	right.offset_top = 12
	right.add_theme_constant_override("separation", 2)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(right)
	fuel_gauge = FuelGauge.new()
	right.add_child(fuel_gauge)
	speedo = Speedo.new()
	speedo.size_flags_horizontal = Control.SIZE_SHRINK_END
	right.add_child(speedo)
	# --- abajo: freno (izq), pausa (centro), acelerador (der) ---
	brake = Pedal.new("brake")
	brake.anchor_top = 1.0
	brake.anchor_bottom = 1.0
	brake.offset_left = 22
	brake.offset_right = 232
	brake.offset_top = -176
	brake.offset_bottom = -20
	add_child(brake)
	gas = Pedal.new("gas")
	gas.anchor_left = 1.0
	gas.anchor_right = 1.0
	gas.anchor_top = 1.0
	gas.anchor_bottom = 1.0
	gas.offset_left = -260
	gas.offset_right = -22
	gas.offset_top = -196
	gas.offset_bottom = -20
	add_child(gas)
	var pause := UIKit.button("II", UIKit.BLUE, Vector2(84, 84), 34)
	pause.anchor_left = 0.5
	pause.anchor_right = 0.5
	pause.anchor_top = 1.0
	pause.anchor_bottom = 1.0
	pause.offset_left = -42
	pause.offset_right = 42
	pause.offset_top = -104
	pause.offset_bottom = -20
	pause.pressed.connect(func(): pause_pressed.emit())
	add_child(pause)
	banner = UIKit.label("", 120, Color(1.0, 0.9, 0.2))
	banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.add_theme_constant_override("outline_size", 16)
	banner.modulate.a = 0.0
	add_child(banner)

func show_banner(text: String, color := Color(1.0, 0.9, 0.2), size := 120) -> void:
	banner.text = text
	banner.add_theme_font_size_override("font_size", size)
	banner.add_theme_color_override("font_color", color)
	banner.modulate.a = 1.0
	banner.scale = Vector2(1.5, 1.5)
	banner.pivot_offset = banner.size * 0.5
	if _banner_tween:
		_banner_tween.kill()
	_banner_tween = create_tween().set_parallel(true)
	_banner_tween.tween_property(banner, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.tween_property(banner, "modulate:a", 0.0, 0.5).set_delay(1.1)

func show_toast(text: String) -> void:
	toast_label.text = text
	toast_label.modulate.a = 1.0
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.6)
	_toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.8)

func update_values(kmh: float, fuel_ratio: float, coins: int, dist_m: float, record_m: float, is_record: bool) -> void:
	speedo.kmh = kmh
	speedo.max_kmh = 120.0
	speedo.queue_redraw()
	fuel_gauge.ratio = fuel_ratio
	coin_label.text = str(coins)
	dist_label.text = "%d m" % int(dist_m)
	record_label.text = ("¡RÉCORD! %d m" if is_record else "RÉCORD %d m") % int(record_m)
	record_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6) if is_record else Color(1.0, 0.86, 0.35))
