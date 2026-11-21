extends ScreenBase
## Menú principal.

class Logo extends Control:
	var t := 0.0
	func _init() -> void:
		custom_minimum_size = Vector2(760, 250)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var f := ThemeDB.fallback_font
		draw_set_transform(Vector2(0, 0), -0.03, Vector2.ONE)
		var w := size.x
		draw_string_outline(f, Vector2(0, 108), "DOMINICAN", HORIZONTAL_ALIGNMENT_CENTER, w, 104, 22, Color(0.0, 0.12, 0.45))
		draw_string(f, Vector2(0, 108), "DOMINICAN", HORIZONTAL_ALIGNMENT_CENTER, w, 104, Color(1, 1, 1))
		draw_string_outline(f, Vector2(0, 224), "RACING", HORIZONTAL_ALIGNMENT_CENTER, w, 126, 24, Color(0.45, 0.02, 0.08))
		draw_string(f, Vector2(0, 224), "RACING", HORIZONTAL_ALIGNMENT_CENTER, w, 126, Color(1.0, 0.82 + 0.1 * sin(t * 3.0), 0.15))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# franjas de la bandera
		draw_rect(Rect2(w * 0.5 - 220, 236, 146, 8), Color(0.0, 0.17, 0.62))
		draw_rect(Rect2(w * 0.5 - 74, 236, 148, 8), Color.WHITE)
		draw_rect(Rect2(w * 0.5 + 74, 236, 146, 8), Color(0.81, 0.07, 0.17))

class Avatar extends Control:
	var initial := "P"
	func _init() -> void:
		custom_minimum_size = Vector2(64, 64)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var c := size * 0.5
		draw_circle(c, 31, Color(1, 1, 1))
		draw_circle(c, 27, Color(0.14, 0.42, 0.88))
		draw_arc(c, 31, 0, TAU, 28, Color(0.81, 0.07, 0.17), 4.0)
		var f := ThemeDB.fallback_font
		draw_string(f, Vector2(0, c.y + 12), initial, HORIZONTAL_ALIGNMENT_CENTER, size.x, 34, Color.WHITE)

func _build() -> void:
	var def := VehicleDefs.get_def(SaveManager.data["selected"])
	add_backdrop(def, 230.0)
	# ---- perfil ----
	var prof := UIKit.panel(Color(0.05, 0.09, 0.22, 0.88), 22, 10)
	prof.position = Vector2(20, 16)
	add_child(prof)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	UIKit.inner(prof).add_child(h)
	var av := Avatar.new()
	av.initial = String(SaveManager.data["profile"]["name"]).left(1).to_upper()
	h.add_child(av)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	h.add_child(v)
	v.add_child(UIKit.label(String(SaveManager.data["profile"]["name"]), 28, Color.WHITE))
	v.add_child(UIKit.label("Nivel %d  ·  Récord: %d m" % [SaveManager.player_level(), int(SaveManager.best_distance())], 20, Color(0.8, 0.9, 1.0)))
	var pbtn := Button.new()
	pbtn.flat = true
	pbtn.focus_mode = Control.FOCUS_NONE
	pbtn.set_anchors_preset(Control.PRESET_FULL_RECT)
	pbtn.pressed.connect(func(): Nav.go(Nav.SETTINGS))
	prof.add_child(pbtn)
	# ---- monedas ----
	coin_chip = UIKit.CoinChip.new()
	coin_chip.anchor_left = 1.0
	coin_chip.anchor_right = 1.0
	coin_chip.offset_left = -220
	coin_chip.offset_right = -20
	coin_chip.offset_top = 20
	add_child(coin_chip)
	# ---- logo ----
	var logo := Logo.new()
	logo.anchor_left = 0.5
	logo.anchor_right = 0.5
	logo.offset_left = -470
	logo.offset_right = 290
	logo.offset_top = 96
	logo.offset_bottom = 346
	add_child(logo)
	# ---- botones ----
	var col := VBoxContainer.new()
	col.anchor_left = 1.0
	col.anchor_right = 1.0
	col.offset_left = -360
	col.offset_right = -30
	col.offset_top = 250
	col.add_theme_constant_override("separation", 10)
	add_child(col)
	var play := UIKit.button("JUGAR", UIKit.GREEN, Vector2(330, 92), 48)
	play.pressed.connect(func(): Nav.start_run())
	col.add_child(play)
	var items := [["GARAJE", UIKit.BLUE, Nav.GARAGE], ["TIENDA", UIKit.ORANGE, Nav.SHOP], ["CONFIGURACIÓN", UIKit.GRAY, Nav.SETTINGS]]
	for it in items:
		var b := UIKit.button(it[0], it[1], Vector2(330, 64), 28)
		var path: String = it[2]
		b.pressed.connect(func(): Nav.go(path))
		col.add_child(b)
	# récord destacado
	var rec := UIKit.label("MEJOR DISTANCIA: %d m" % int(SaveManager.best_distance()), 24, Color(1.0, 0.9, 0.4))
	rec.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(rec)
	# animaciones de entrada
	await get_tree().process_frame
	for i in col.get_child_count():
		var c := col.get_child(i) as Control
		if c:
			UIKit.slide_in(c, Vector2(120, 0), 0.05 * i)
	UIKit.slide_in(logo, Vector2(0, -80), 0.0)
	UIKit.slide_in(prof, Vector2(-80, 0), 0.1)

func on_back() -> void:
	SaveManager.save_game()
	get_tree().quit()
