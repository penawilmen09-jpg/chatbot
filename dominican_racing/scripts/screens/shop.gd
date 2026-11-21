extends ScreenBase
## Tienda: compra de vehículos y desbloqueo de mundos.

var tab := 0
var content_box: Control
var tab_btns: Array = []

func _build() -> void:
	tab = Nav.shop_tab
	add_backdrop(1, {}, 20.0)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.05, 0.14, 0.5)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	add_topbar("TIENDA")
	var tabs := HBoxContainer.new()
	tabs.position = Vector2(220, 14)
	tabs.add_theme_constant_override("separation", 10)
	add_child(tabs)
	var names := ["VEHÍCULOS", "MUNDOS"]
	for i in 2:
		var b := UIKit.button(names[i], UIKit.BLUE, Vector2(200, 52), 22)
		var idx := i
		b.pressed.connect(func():
			tab = idx
			Nav.shop_tab = idx
			_refresh())
		tabs.add_child(b)
		tab_btns.append(b)
	content_box = Control.new()
	content_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_box.offset_top = 96
	content_box.offset_bottom = -12
	content_box.offset_left = 14
	content_box.offset_right = -14
	content_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content_box)
	_refresh()

func _refresh() -> void:
	for i in tab_btns.size():
		UIKit.restyle(tab_btns[i], UIKit.ORANGE if i == tab else UIKit.GRAY)
	for c in content_box.get_children():
		content_box.remove_child(c)
		c.queue_free()
	var sc := ScrollContainer.new()
	sc.set_anchors_preset(Control.PRESET_FULL_RECT)
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_box.add_child(sc)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	sc.add_child(row)
	if tab == 0:
		for d in VehicleDefs.LIST:
			row.add_child(_vehicle_card(d))
	else:
		for w in WorldDefs.WORLDS:
			row.add_child(_world_card(w))
	for i in row.get_child_count():
		UIKit.slide_in(row.get_child(i) as Control, Vector2(60, 0), 0.04 * i)

func _vehicle_card(d: Dictionary) -> Control:
	var id: String = d["id"]
	var owned := SaveManager.owns(id)
	var p := UIKit.panel(UIKit.NAVY, 22, 10)
	p.custom_minimum_size = Vector2(290, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	UIKit.inner(p).add_child(v)
	var nm := UIKit.label(d["name"], 26, UIKit.GOLD)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nm)
	var pv := VehiclePreview.new()
	pv.custom_minimum_size = Vector2(0, 150)
	pv.set_def(d)
	pv.locked = false
	v.add_child(pv)
	var bars := VehicleDefs.bars(VehicleDefs.effective(id, VehicleDefs.default_upgrades()))
	for k in ["Potencia", "Velocidad", "Tracción", "Combustible", "Peso"]:
		var h := HBoxContainer.new()
		var l := UIKit.label(k, 16, Color.WHITE)
		l.custom_minimum_size = Vector2(100, 0)
		h.add_child(l)
		var sb := UIKit.StatBar.new(Vector2(140, 13))
		sb.value = bars[k]
		sb.color = Color(0.3, 0.75, 1.0)
		h.add_child(sb)
		v.add_child(h)
	var ds := UIKit.label(d["desc"], 15, Color(0.82, 0.9, 1.0), false)
	ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ds.custom_minimum_size = Vector2(250, 62)
	v.add_child(ds)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	var btn: Button
	if owned:
		btn = UIKit.button("EN PROPIEDAD", UIKit.GRAY, Vector2(250, 58), 22)
		btn.disabled = true
	elif d.has("unlock_levels") and not SaveManager.special_unlocked(id):
		btn = UIKit.button("Completa %d niveles (%d/%d)" % [d["unlock_levels"], SaveManager.completed_levels(), d["unlock_levels"]], UIKit.GRAY, Vector2(250, 58), 16)
		btn.disabled = true
	else:
		var price: int = d["price"]
		var can := SaveManager.can_afford(price)
		var label := "RECLAMAR GRATIS" if price == 0 else "COMPRAR  %d" % price
		btn = UIKit.button(label, UIKit.GREEN if can else UIKit.RED, Vector2(250, 58), 22)
		btn.pressed.connect(func():
			if SaveManager.buy_vehicle(id):
				Sfx.play("buy")
				toast("¡%s comprado!" % d["name"], UIKit.GREEN)
				_refresh()
			else:
				Sfx.play("deny")
				toast("Monedas insuficientes"))
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(btn)
	return p

class WorldThumb extends Control:
	var w: Dictionary
	func _draw() -> void:
		var sz := size
		var top: Color = w["sky_top"]
		var bot: Color = w["sky_bot"]
		draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(sz.x, 0), sz, Vector2(0, sz.y)]), PackedColorArray([top, top, bot, bot]))
		var pts := PackedVector2Array()
		for i in 21:
			pts.append(Vector2(sz.x * i / 20.0, sz.y * 0.62 - 26.0 * absf(sin(i * 0.7)) - 8.0 * sin(i * 1.9)))
		var far := pts.duplicate()
		far.append(Vector2(sz.x, sz.y))
		far.append(Vector2(0, sz.y))
		draw_colored_polygon(far, w["far2"])
		var pts2 := PackedVector2Array()
		for i in 21:
			pts2.append(Vector2(sz.x * i / 20.0, sz.y * 0.78 - 14.0 * sin(i * 0.9 + 1.0)))
		var gp := pts2.duplicate()
		gp.append(Vector2(sz.x, sz.y))
		gp.append(Vector2(0, sz.y))
		draw_colored_polygon(gp, w["ground"])
		draw_polyline(pts2, w["grass"], 6.0)
		draw_rect(Rect2(Vector2.ZERO, sz), Color(1, 1, 1, 0.35), false, 2.0)

func _world_card(w: Dictionary) -> Control:
	var wid: int = w["id"]
	var unlocked := SaveManager.world_unlocked(wid)
	var p := UIKit.panel(UIKit.NAVY, 22, 10)
	p.custom_minimum_size = Vector2(300, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	UIKit.inner(p).add_child(v)
	var nm := UIKit.label(w["name"], 28, UIKit.GOLD)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nm)
	var th := WorldThumb.new()
	th.w = w
	th.custom_minimum_size = Vector2(0, 170)
	v.add_child(th)
	var ds := UIKit.label(w["desc"], 17, Color(0.85, 0.92, 1.0), false)
	ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ds.custom_minimum_size = Vector2(260, 84)
	v.add_child(ds)
	var dif := UIKit.label("Dificultad: " + "★".repeat(wid) + "☆".repeat(5 - wid), 18, UIKit.GOLD)
	v.add_child(dif)
	var rc := UIKit.label("Niveles completados: %d/%d" % [_done_in_world(wid), WorldDefs.LEVELS_PER_WORLD], 17, Color.WHITE)
	v.add_child(rc)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	var btn: Button
	if unlocked:
		btn = UIKit.button("DESBLOQUEADO", UIKit.GRAY, Vector2(260, 58), 22)
		btn.disabled = true
	else:
		var price: int = w["price"]
		var can := SaveManager.can_afford(price)
		btn = UIKit.button("DESBLOQUEAR  %d" % price, UIKit.GREEN if can else UIKit.RED, Vector2(260, 58), 22)
		btn.pressed.connect(func():
			if SaveManager.buy_world(wid):
				Sfx.play("buy")
				toast("¡%s desbloqueado!" % w["name"], UIKit.GREEN)
				_refresh()
			else:
				Sfx.play("deny")
				toast("Monedas insuficientes"))
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(btn)
	return p

func _done_in_world(wid: int) -> int:
	var n := 0
	for l in range(1, WorldDefs.LEVELS_PER_WORLD + 1):
		if SaveManager.level_done(wid, l):
			n += 1
	return n
