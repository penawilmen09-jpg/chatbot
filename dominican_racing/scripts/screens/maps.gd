extends ScreenBase
## Mapas: selección de mundo y nivel (o distancia infinita).

var sel_world := 1
var worlds_box: VBoxContainer
var levels_box: Control

func _build() -> void:
	var last: Dictionary = SaveManager.data["last"]
	sel_world = Nav.run_world if SaveManager.world_unlocked(Nav.run_world) else int(last["world"])
	add_backdrop(sel_world, {}, 30.0)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.05, 0.14, 0.35)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	add_topbar("MAPAS")
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_top = 92
	row.offset_left = 14
	row.offset_right = -14
	row.offset_bottom = -12
	row.add_theme_constant_override("separation", 12)
	add_child(row)
	var lp := UIKit.panel(UIKit.NAVY, 20, 8)
	lp.custom_minimum_size = Vector2(300, 0)
	row.add_child(lp)
	worlds_box = VBoxContainer.new()
	worlds_box.add_theme_constant_override("separation", 8)
	UIKit.inner(lp).add_child(worlds_box)
	var rp := UIKit.panel(Color(0.07, 0.12, 0.27, 0.78), 20, 12)
	rp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(rp)
	levels_box = Control.new()
	levels_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	levels_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UIKit.inner(rp).add_child(levels_box)
	_refresh()

func _refresh() -> void:
	for c in worlds_box.get_children():
		worlds_box.remove_child(c)
		c.queue_free()
	for w in WorldDefs.WORLDS:
		var wid: int = w["id"]
		var unlocked := SaveManager.world_unlocked(wid)
		var b := Button.new()
		b.custom_minimum_size = Vector2(270, 100)
		b.focus_mode = Control.FOCUS_NONE
		var sel := wid == sel_world
		var col: Color = (w["far3"] as Color).darkened(0.1) if unlocked else Color(0.14, 0.16, 0.24)
		b.add_theme_stylebox_override("normal", UIKit.box(col, 16, UIKit.GOLD if sel else Color(1, 1, 1, 0.2), 4 if sel else 2))
		b.add_theme_stylebox_override("hover", UIKit.box(col.lightened(0.1), 16, UIKit.GOLD, 3))
		b.add_theme_stylebox_override("pressed", UIKit.box(col.darkened(0.2), 16, UIKit.GOLD, 4))
		b.pressed.connect(func():
			Sfx.click()
			sel_world = wid
			Nav.run_world = wid
			add_backdrop(wid, {}, 30.0)
			_refresh())
		var nm := UIKit.label("%d. %s" % [wid, w["name"]], 24, Color.WHITE if unlocked else Color(0.7, 0.72, 0.8))
		nm.position = Vector2(12, 8)
		b.add_child(nm)
		var info: String
		if unlocked:
			info = "Niveles: %d/%d  ·  Récord %d m" % [_done(wid), WorldDefs.LEVELS_PER_WORLD, int(SaveManager.data["records"]["best_by_world"].get(str(wid), 0.0))]
		else:
			info = "BLOQUEADO · %d monedas" % w["price"]
		var inf := UIKit.label(info, 16, UIKit.GOLD if unlocked else Color(1.0, 0.55, 0.5))
		inf.position = Vector2(12, 52)
		b.add_child(inf)
		if not unlocked:
			var lk := UIKit.LockIcon.new(32.0)
			lk.position = Vector2(230, 6)
			b.add_child(lk)
		worlds_box.add_child(b)
	_refresh_levels()

func _done(wid: int) -> int:
	var n := 0
	for l in range(1, WorldDefs.LEVELS_PER_WORLD + 1):
		if SaveManager.level_done(wid, l):
			n += 1
	return n

func _refresh_levels() -> void:
	for c in levels_box.get_children():
		levels_box.remove_child(c)
		c.queue_free()
	var w := WorldDefs.world(sel_world)
	var unlocked := SaveManager.world_unlocked(sel_world)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 8)
	levels_box.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	var t := UIKit.label(w["name"], 38, UIKit.GOLD)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	if not unlocked:
		var price: int = w["price"]
		var can := SaveManager.can_afford(price)
		var ub := UIKit.button("DESBLOQUEAR  %d" % price, UIKit.GREEN if can else UIKit.RED, Vector2(300, 56), 22)
		ub.pressed.connect(func():
			if SaveManager.buy_world(sel_world):
				Sfx.play("buy")
				toast("¡Mundo desbloqueado!", UIKit.GREEN)
				_refresh()
			else:
				Sfx.play("deny")
				toast("Monedas insuficientes"))
		head.add_child(ub)
	var ds := UIKit.label(w["desc"], 18, Color(0.85, 0.92, 1.0), false)
	v.add_child(ds)
	var sc := ScrollContainer.new()
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sc)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	sc.add_child(row)
	for l in range(1, WorldDefs.LEVELS_PER_WORLD + 1):
		row.add_child(_level_card(sel_world, l))
	row.add_child(_infinite_card(sel_world))
	for i in row.get_child_count():
		UIKit.slide_in(row.get_child(i) as Control, Vector2(40, 0), 0.04 * i)

func _level_card(wid: int, l: int) -> Control:
	var lv := WorldDefs.level(wid, l)
	var unlocked := SaveManager.level_unlocked(wid, l)
	var info := SaveManager.level_info(wid, l)
	var p := UIKit.panel(Color(0.12, 0.2, 0.42, 0.97) if unlocked else Color(0.1, 0.12, 0.2, 0.97), 18, 8)
	p.custom_minimum_size = Vector2(196, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	UIKit.inner(p).add_child(v)
	var n := UIKit.label("NIVEL %d" % l, 26, UIKit.GOLD if unlocked else Color(0.6, 0.62, 0.7))
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(n)
	var nm := UIKit.label(lv["name"], 17, Color.WHITE)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.custom_minimum_size = Vector2(170, 44)
	v.add_child(nm)
	var stars := UIKit.StarRow.new()
	stars.count = SaveManager.stars(wid, l)
	stars.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(stars)
	var rec_def := VehicleDefs.get_def(lv["rec"])
	var own_rec := SaveManager.owns(lv["rec"])
	for line in [["Meta", "%d m" % lv["goal_m"]], ["Monedas", "%d" % lv["coin_goal"]], ["Premio", "%d" % lv["reward"]], ["Mejor", "%d m" % int(info["best_m"])]]:
		var h := HBoxContainer.new()
		var a := UIKit.label(line[0], 16, Color(0.8, 0.88, 1.0), false)
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(a)
		h.add_child(UIKit.label(line[1], 17, Color.WHITE))
		v.add_child(h)
	var rv := UIKit.label("Recom.: " + rec_def["name"], 14, Color(0.6, 1.0, 0.7) if own_rec else Color(0.95, 0.75, 0.5), false)
	rv.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rv.custom_minimum_size = Vector2(170, 36)
	v.add_child(rv)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	var btn: Button
	if unlocked:
		btn = UIKit.button("JUGAR", UIKit.GREEN, Vector2(170, 54), 24)
		btn.pressed.connect(func(): Nav.start_run(wid, l))
	else:
		var reason := "Mundo bloqueado" if not SaveManager.world_unlocked(wid) else "Completa el nivel %d" % (l - 1)
		btn = UIKit.button(reason, UIKit.GRAY, Vector2(170, 54), 15)
		btn.disabled = true
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(btn)
	return p

func _infinite_card(wid: int) -> Control:
	var unlocked := SaveManager.world_unlocked(wid)
	var p := UIKit.panel(Color(0.30, 0.14, 0.40, 0.97) if unlocked else Color(0.1, 0.12, 0.2, 0.97), 18, 8)
	p.custom_minimum_size = Vector2(210, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	UIKit.inner(p).add_child(v)
	var n := UIKit.label("INFINITO", 28, UIKit.GOLD)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(n)
	var d := UIKit.label("Recorre tanto como puedas. La dificultad aumenta con la distancia.", 16, Color(0.9, 0.85, 1.0), false)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(180, 96)
	v.add_child(d)
	v.add_child(UIKit.label("Récord mundo:", 17, Color(0.8, 0.88, 1.0), false))
	v.add_child(UIKit.label("%d m" % int(SaveManager.data["records"]["best_by_world"].get(str(wid), 0.0)), 28, Color.WHITE))
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	var btn: Button
	if unlocked:
		btn = UIKit.button("JUGAR", UIKit.GREEN, Vector2(180, 54), 24)
		btn.pressed.connect(func(): Nav.start_run(wid, 0))
	else:
		btn = UIKit.button("Bloqueado", UIKit.GRAY, Vector2(180, 54), 20)
		btn.disabled = true
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(btn)
	return p
