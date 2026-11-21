class_name GameHUD
extends Control
## Interfaz durante la partida: velocímetro, combustible, monedas, distancia, pausa y pedales táctiles.

signal pause_pressed

class Speedo extends Control:
	var kmh := 0.0
	var max_kmh := 180.0
	func _init() -> void:
		custom_minimum_size = Vector2(170, 130)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var c := Vector2(size.x * 0.5, size.y - 12.0)
		var r := 74.0
		draw_circle(c, r + 6, Color(0, 0, 0, 0.5))
		draw_arc(c, r, PI, TAU, 40, Color(0.12, 0.16, 0.3, 0.95), 14.0, true)
		var f := clampf(kmh / max_kmh, 0.0, 1.0)
		var col := Color(0.2, 0.85, 0.4).lerp(Color(1.0, 0.25, 0.2), f)
		if f > 0.01:
			draw_arc(c, r, PI, PI + PI * f, 40, col, 14.0, true)
		for i in 9:
			var a := PI + PI * i / 8.0
			var d := Vector2(cos(a), sin(a))
			draw_line(c + d * (r - 14), c + d * (r - 24), Color(1, 1, 1, 0.8), 2.0)
		var na := PI + PI * f
		draw_line(c, c + Vector2(cos(na), sin(na)) * (r - 10), Color(1.0, 0.3, 0.25), 4.0)
		draw_circle(c, 7, Color(0.9, 0.9, 0.95))
		var font := ThemeDB.fallback_font
		draw_string_outline(font, c + Vector2(-50, -24), str(int(kmh)), HORIZONTAL_ALIGNMENT_CENTER, 100, 34, 6, Color(0, 0, 0, 0.8))
		draw_string(font, c + Vector2(-50, -24), str(int(kmh)), HORIZONTAL_ALIGNMENT_CENTER, 100, 34, Color.WHITE)
		draw_string(font, c + Vector2(-50, -4), "km/h", HORIZONTAL_ALIGNMENT_CENTER, 100, 16, Color(1, 1, 1, 0.75))

class FuelGauge extends Control:
	var ratio := 1.0
	var _t := 0.0
	func _init() -> void:
		custom_minimum_size = Vector2(260, 44)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
	func _draw() -> void:
		var bar := Rect2(Vector2(54, 8), Vector2(size.x - 60, 28))
		draw_style_box(UIKit.box(Color(0.04, 0.06, 0.16, 0.9), 14, Color(1, 1, 1, 0.5), 2), bar)
		var col := Color(0.2, 0.85, 0.35)
		if ratio < 0.5:
			col = Color(1.0, 0.8, 0.15)
		if ratio < 0.22:
			col = Color(1.0, 0.2, 0.18)
			if int(_t * 5.0) % 2 == 0:
				col = col.lightened(0.4)
		var inner := Rect2(bar.position + Vector2(3, 3), Vector2((bar.size.x - 6) * clampf(ratio, 0, 1), bar.size.y - 6))
		if inner.size.x > 1:
			draw_style_box(UIKit.box(col, 11), inner)
		# icono de bidón
		draw_rect(Rect2(8, 6, 32, 34), Color(0.88, 0.14, 0.12))
		draw_rect(Rect2(8, 6, 32, 34), Color.WHITE, false, 2.0)
		draw_rect(Rect2(14, 0, 14, 8), Color(0.2, 0.2, 0.25))
		draw_rect(Rect2(16, 16, 16, 14), Color(1.0, 0.92, 0.3))

class UpgradeRow extends Control:
	var levels: Dictionary = {}
	func _init() -> void:
		custom_minimum_size = Vector2(260, 24)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var labels := {"motor": "M", "suspension": "S", "tires": "N", "fuel": "C", "traction": "T"}
		var cols := {"motor": Color(0.9, 0.3, 0.25), "suspension": Color(0.3, 0.6, 0.95), "tires": Color(0.7, 0.7, 0.75),
			"fuel": Color(0.95, 0.75, 0.2), "traction": Color(0.4, 0.85, 0.4)}
		var f := ThemeDB.fallback_font
		var x := 0.0
		for k in VehicleDefs.UPGRADE_KEYS:
			var lv: int = int(levels.get(k, 0))
			draw_rect(Rect2(x, 0, 48, 22), Color(0, 0, 0, 0.5))
			draw_rect(Rect2(x, 0, 48, 22), cols[k] if lv > 0 else Color(1, 1, 1, 0.2), false, 2.0)
			draw_string(f, Vector2(x + 4, 17), "%s%d" % [labels[k], lv], HORIZONTAL_ALIGNMENT_LEFT, 44, 16, Color.WHITE if lv > 0 else Color(1, 1, 1, 0.5))
			x += 52.0

var speedo: Speedo
var fuel_gauge: FuelGauge
var coin_label: Label
var dist_label: Label
var goal_bar: UIKit.StatBar
var goal_label: Label
var info_label: Label
var gas: Pedal
var brake: Pedal
var banner: Label
var upgrade_row: UpgradeRow
var _banner_tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.fit(self)
	# --- arriba izquierda: pausa + monedas + distancia ---
	var pause := UIKit.button("II", UIKit.BLUE, Vector2(68, 68), 30)
	pause.position = Vector2(16, 14)
	pause.pressed.connect(func(): pause_pressed.emit())
	add_child(pause)
	var box := VBoxContainer.new()
	box.position = Vector2(96, 10)
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	var coin_row := HBoxContainer.new()
	coin_row.add_theme_constant_override("separation", 6)
	coin_row.add_child(UIKit.CoinIcon.new(32.0))
	coin_label = UIKit.label("0", 32, UIKit.GOLD)
	coin_row.add_child(coin_label)
	box.add_child(coin_row)
	dist_label = UIKit.label("0 m", 34, Color.WHITE)
	box.add_child(dist_label)
	goal_bar = UIKit.StatBar.new(Vector2(200, 12))
	goal_bar.color = Color(0.3, 0.8, 1.0)
	box.add_child(goal_bar)
	goal_label = UIKit.label("", 18, Color(1, 1, 1, 0.9))
	box.add_child(goal_label)
	# --- arriba derecha: combustible + mejoras ---
	var right := VBoxContainer.new()
	right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right.anchor_left = 1.0
	right.anchor_right = 1.0
	right.offset_left = -290
	right.offset_right = -18
	right.offset_top = 14
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(right)
	fuel_gauge = FuelGauge.new()
	right.add_child(fuel_gauge)
	upgrade_row = UpgradeRow.new()
	right.add_child(upgrade_row)
	info_label = UIKit.label("", 17, Color(1, 1, 1, 0.9))
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.custom_minimum_size = Vector2(270, 0)
	right.add_child(info_label)
	# --- abajo: pedales y velocímetro ---
	brake = Pedal.new("brake")
	brake.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	brake.anchor_top = 1.0
	brake.anchor_bottom = 1.0
	brake.offset_left = 22
	brake.offset_right = 22 + 200
	brake.offset_top = -170
	brake.offset_bottom = -20
	add_child(brake)
	gas = Pedal.new("gas")
	gas.anchor_left = 1.0
	gas.anchor_right = 1.0
	gas.anchor_top = 1.0
	gas.anchor_bottom = 1.0
	gas.offset_left = -240
	gas.offset_right = -22
	gas.offset_top = -190
	gas.offset_bottom = -20
	add_child(gas)
	speedo = Speedo.new()
	speedo.anchor_left = 0.5
	speedo.anchor_right = 0.5
	speedo.anchor_top = 1.0
	speedo.anchor_bottom = 1.0
	speedo.offset_left = -85
	speedo.offset_right = 85
	speedo.offset_top = -140
	speedo.offset_bottom = -10
	add_child(speedo)
	banner = UIKit.label("", 120, Color(1.0, 0.9, 0.2))
	banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.add_theme_constant_override("outline_size", 16)
	banner.pivot_offset = Vector2(640, 300)
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
	_banner_tween.tween_property(banner, "modulate:a", 0.0, 0.5).set_delay(0.5)

func set_upgrades(levels: Dictionary) -> void:
	upgrade_row.levels = levels
	upgrade_row.queue_redraw()

func update_values(kmh: float, fuel_ratio: float, coins: int, dist_m: float, goal_m: float, vmax_kmh: float) -> void:
	speedo.kmh = kmh
	speedo.max_kmh = maxf(120.0, vmax_kmh * 1.1)
	speedo.queue_redraw()
	fuel_gauge.ratio = fuel_ratio
	coin_label.text = str(coins)
	dist_label.text = "%d m" % int(dist_m)
	if goal_m > 0.0:
		goal_bar.visible = true
		goal_bar.value = clampf(dist_m / goal_m, 0.0, 1.0)
		goal_bar.queue_redraw()
		goal_label.text = "Meta: %d m" % int(goal_m)
	else:
		goal_bar.visible = false
		goal_label.text = "Modo infinito"
