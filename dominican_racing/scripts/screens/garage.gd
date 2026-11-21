extends ScreenBase
## Garaje: selección de vehículo, estadísticas y mejoras independientes por vehículo.

var view_id := "jeep_dom"
var list_box: VBoxContainer
var center_box: VBoxContainer
var right_box: VBoxContainer
var preview: VehiclePreview

func _build() -> void:
	view_id = SaveManager.data["selected"]
	add_backdrop({}, 20.0)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.05, 0.14, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	add_topbar("GARAJE")
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_top = 92
	row.offset_left = 16
	row.offset_right = -16
	row.offset_bottom = -14
	row.add_theme_constant_override("separation", 12)
	add_child(row)
	# lista
	var lp := UIKit.panel(UIKit.NAVY, 20, 8)
	lp.custom_minimum_size = Vector2(290, 0)
	row.add_child(lp)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UIKit.inner(lp).add_child(sc)
	list_box = VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 8)
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list_box)
	# centro
	var cp := UIKit.panel(UIKit.NAVY, 20, 14)
	cp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(cp)
	center_box = VBoxContainer.new()
	center_box.add_theme_constant_override("separation", 6)
	UIKit.inner(cp).add_child(center_box)
	# derecha
	var rp := UIKit.panel(UIKit.NAVY, 20, 14)
	rp.custom_minimum_size = Vector2(420, 0)
	row.add_child(rp)
	right_box = VBoxContainer.new()
	right_box.add_theme_constant_override("separation", 8)
	UIKit.inner(rp).add_child(right_box)
	SaveManager.coins_changed.connect(func(_c): _refresh_right())
	_refresh_all()
	await get_tree().process_frame
	UIKit.slide_in(lp, Vector2(-60, 0))
	UIKit.slide_in(cp, Vector2(0, 40), 0.08)
	UIKit.slide_in(rp, Vector2(60, 0), 0.12)

func _clear(n: Node) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()

func _refresh_all() -> void:
	_refresh_list()
	_refresh_center()
	_refresh_right()

func _refresh_list() -> void:
	_clear(list_box)
	for d in VehicleDefs.LIST:
		var id: String = d["id"]
		var owned := SaveManager.owns(id)
		var b := Button.new()
		b.custom_minimum_size = Vector2(250, 86)
		b.focus_mode = Control.FOCUS_NONE
		var sel := id == view_id
		var col := Color(0.18, 0.28, 0.55) if owned else Color(0.14, 0.16, 0.24)
		b.add_theme_stylebox_override("normal", UIKit.box(col, 16, UIKit.GOLD if sel else Color(1, 1, 1, 0.15), 4 if sel else 2))
		b.add_theme_stylebox_override("hover", UIKit.box(col.lightened(0.1), 16, UIKit.GOLD if sel else Color(1, 1, 1, 0.3), 4 if sel else 2))
		b.add_theme_stylebox_override("pressed", UIKit.box(col.darkened(0.2), 16, UIKit.GOLD, 4))
		b.pressed.connect(func():
			Sfx.click()
			view_id = id
			_refresh_all())
		var pv := VehiclePreview.new()
		pv.position = Vector2(6, 8)
		pv.size = Vector2(112, 70)
		pv.set_def(d)
		pv.locked = not owned
		pv.bob = false
		pv.spin_speed = 0.0
		pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(pv)
		var nm := UIKit.label(d["name"], 20, Color.WHITE if owned else Color(0.7, 0.72, 0.8))
		nm.position = Vector2(124, 10)
		nm.custom_minimum_size = Vector2(120, 0)
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nm.size = Vector2(124, 50)
		b.add_child(nm)
		var st := UIKit.label("SELECCIONADO" if id == SaveManager.data["selected"] else ("En propiedad" if owned else "BLOQUEADO"), 15,
			UIKit.GOLD if id == SaveManager.data["selected"] else (Color(0.6, 1.0, 0.7) if owned else Color(1.0, 0.5, 0.45)))
		st.position = Vector2(124, 60)
		b.add_child(st)
		if not owned:
			var lk := UIKit.LockIcon.new(30.0)
			lk.position = Vector2(86, 48)
			b.add_child(lk)
		list_box.add_child(b)

func _refresh_center() -> void:
	_clear(center_box)
	var id := view_id
	var d := VehicleDefs.get_def(id)
	var owned := SaveManager.owns(id)
	var upg: Dictionary = SaveManager.get_upgrades(id) if owned else VehicleDefs.default_upgrades()
	var eff := VehicleDefs.effective(id, upg)
	var base := VehicleDefs.effective(id, VehicleDefs.default_upgrades())
	var title := UIKit.label(d["name"], 38, UIKit.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_box.add_child(title)
	preview = VehiclePreview.new()
	preview.custom_minimum_size = Vector2(0, 230)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.set_def(d)
	preview.locked = not owned
	center_box.add_child(preview)
	var desc := UIKit.label(d["desc"], 19, Color(0.85, 0.92, 1.0), false)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_box.add_child(desc)
	var bars := VehicleDefs.bars(eff)
	var bars_base := VehicleDefs.bars(base)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 4)
	center_box.add_child(grid)
	for k in bars:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		var l := UIKit.label(k, 18, Color.WHITE)
		l.custom_minimum_size = Vector2(104, 0)
		h.add_child(l)
		var sb := UIKit.StatBar.new(Vector2(150, 16))
		sb.value = bars[k]
		sb.extra = maxf(0.0, bars[k] - bars_base[k])
		h.add_child(sb)
		grid.add_child(h)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_box.add_child(spacer)
	var btn: Button
	if id == SaveManager.data["selected"]:
		btn = UIKit.button("✔ SELECCIONADO", UIKit.GRAY, Vector2(320, 62), 26)
		btn.disabled = true
	elif owned:
		btn = UIKit.button("SELECCIONAR", UIKit.GREEN, Vector2(320, 62), 26)
		btn.pressed.connect(func():
			if SaveManager.select_vehicle(id):
				Sfx.play("buy", -4.0)
				_refresh_all())
	else:
		btn = UIKit.button("IR A LA TIENDA", UIKit.ORANGE, Vector2(320, 62), 26)
		btn.pressed.connect(func():
			Nav.go(Nav.SHOP))
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center_box.add_child(btn)

func _refresh_right() -> void:
	if right_box == null:
		return
	_clear(right_box)
	var id := view_id
	var owned := SaveManager.owns(id)
	var t := UIKit.label("MEJORAS", 34, UIKit.GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_box.add_child(t)
	if not owned:
		var l := UIKit.label("Compra este vehículo en la tienda para poder mejorarlo.", 22, Color(1.0, 0.7, 0.6), false)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		right_box.add_child(l)
		return
	var upg: Dictionary = SaveManager.get_upgrades(id)
	for k in VehicleDefs.UPGRADE_KEYS:
		var lvl: int = int(upg[k])
		var p := UIKit.panel(Color(0.16, 0.24, 0.46, 0.95), 14, 8)
		right_box.add_child(p)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		UIKit.inner(p).add_child(h)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UIKit.label(VehicleDefs.UPGRADE_NAMES[k], 22, Color.WHITE))
		var ds := UIKit.label(VehicleDefs.UPGRADE_DESC[k], 14, Color(0.8, 0.88, 1.0), false)
		ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ds.custom_minimum_size = Vector2(210, 0)
		v.add_child(ds)
		var pips := UIKit.Pips.new()
		pips.level = lvl
		v.add_child(pips)
		var key: String = k
		if lvl >= VehicleDefs.MAX_UPG:
			var mx := UIKit.button("MÁX", UIKit.GRAY, Vector2(130, 58), 22)
			mx.disabled = true
			h.add_child(mx)
		else:
			var cost := VehicleDefs.upgrade_cost(id, key, lvl)
			var can := SaveManager.can_afford(cost)
			var bb := UIKit.button("%d" % cost, UIKit.GREEN if can else UIKit.RED, Vector2(130, 58), 24)
			bb.pressed.connect(func():
				if SaveManager.buy_upgrade(id, key):
					Sfx.play("buy")
					_refresh_center()
					_refresh_right()
				else:
					Sfx.play("deny")
					toast("Monedas insuficientes"))
			h.add_child(bb)
