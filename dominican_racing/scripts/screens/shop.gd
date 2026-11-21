extends ScreenBase
## Tienda: compra de vehículos y desbloqueo de mundos.

var content_box: Control

func _build() -> void:
	add_backdrop({}, 20.0)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.05, 0.14, 0.5)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	add_topbar("TIENDA")
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
	for d in VehicleDefs.LIST:
		row.add_child(_vehicle_card(d))
	for i in row.get_child_count():
		var c := row.get_child(i) as Control
		c.modulate.a = 0.0
		c.create_tween().tween_property(c, "modulate:a", 1.0, 0.3).set_delay(0.04 * i)

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
	elif d.has("unlock_distance") and not SaveManager.special_unlocked(id):
		btn = UIKit.button("Llega a %d m (mejor: %d m)" % [d["unlock_distance"], int(SaveManager.best_distance())], UIKit.GRAY, Vector2(250, 58), 16)
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
