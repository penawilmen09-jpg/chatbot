extends Control
## Extras: vestuario (trajes, sombreros, armaduras, efectos y apariencias), logros, estadísticas y modos de juego.
## Todo se desbloquea jugando; no hay compras.

const UiTheme := preload("res://ui/ui_theme.gd")
const MenuBg := preload("res://ui/menu_background.gd")
const SpriteUtil := preload("res://characters/sprite_util.gd")
const HeroPreview := preload("res://ui/hero_preview.gd")

var _tab: String = "wardrobe"
var _content: Control
var _tab_buttons: Dictionary = {}
var _cat: String = "suit"
var _preview_holder: Control
var _grid: GridContainer
var _hint: Label
var _mode: String = "time"
var _mode_world: int = 1
var _mode_panel: Control
var _extras_msg: Label


func _ready() -> void:
	theme = UiTheme.make()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg = MenuBg.new()
	bg.world = clampi(Game.world_of(Game.continue_level()), 1, 10)
	add_child(bg)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.01, 0.08, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 6)
	add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	margin.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	v.add_child(top)
	var names := {"wardrobe": "Vestuario", "achievements": "Logros", "stats": "Estadísticas", "modes": "Modos"}
	for key in names:
		var b := UiTheme.button(names[key], Vector2(96, 30))
		b.toggle_mode = false
		b.pressed.connect(func():
			Audio.play_sfx("select")
			_show_tab(key))
		top.add_child(b)
		_tab_buttons[key] = b
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	var back := UiTheme.button("Atrás", Vector2(70, 30))
	back.pressed.connect(_go_back)
	top.add_child(back)
	_content = Control.new()
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.clip_contents = true
	v.add_child(_content)
	var start_tab: String = "wardrobe"
	if Engine.has_meta("extras_tab"):
		start_tab = str(Engine.get_meta("extras_tab"))
		Engine.remove_meta("extras_tab")
	_show_tab(start_tab)
	Audio.play_music("title")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back()


func _go_back() -> void:
	Audio.play_sfx("back")
	Game.save_game()
	Game.mode = "story"
	Transition.change_scene("res://ui/title.tscn")


func _clear() -> void:
	for c in _content.get_children():
		c.queue_free()


func _show_tab(t: String) -> void:
	_tab = t
	_clear()
	for k in _tab_buttons:
		_tab_buttons[k].modulate = Color(1, 1, 1) if k == t else Color(0.75, 0.75, 0.85)
	var holder := MarginContainer.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content.add_child(holder)
	match t:
		"wardrobe":
			_build_wardrobe(holder)
		"achievements":
			_build_achievements(holder)
		"stats":
			_build_stats(holder)
		"modes":
			_build_modes(holder)


# ------------------------------------------------------------- vestuario ---
func _build_wardrobe(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	# vista previa
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 130
	row.add_child(left)
	var pv := PanelContainer.new()
	pv.custom_minimum_size = Vector2(130, 150)
	left.add_child(pv)
	_preview_holder = Control.new()
	_preview_holder.custom_minimum_size = Vector2(120, 140)
	pv.add_child(_preview_holder)
	var count := UiTheme.label("Colección %d/%d" % [Progress.cosmetics_owned(), Progress.cosmetics_total()], 10, Color("#ffe97a"))
	left.add_child(count)
	_hint = UiTheme.label("Se consiguen jugando: cofres, logros y mundos completados.", 9, Color("#cfc6ff"))
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.custom_minimum_size.x = 125
	left.add_child(_hint)
	# categorías y piezas
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 4)
	row.add_child(right)
	var cats := HFlowContainer.new()
	cats.add_theme_constant_override("h_separation", 4)
	right.add_child(cats)
	for c in Progress.COSMETICS:
		var b := UiTheme.button(str(Progress.CATEGORY_NAMES[c]), Vector2(84, 26))
		b.modulate = Color(1, 1, 1) if c == _cat else Color(0.75, 0.75, 0.85)
		b.pressed.connect(func():
			Audio.play_sfx("click")
			_cat = c
			_show_tab("wardrobe"))
		cats.add_child(b)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(sc)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 5)
	_grid.add_theme_constant_override("v_separation", 5)
	sc.add_child(_grid)
	if _cat != "suit":
		_add_option("", "Ninguno")
	for id in Progress.COSMETICS[_cat]:
		_add_option(str(id), str(Progress.COSMETICS[_cat][id]))
	_refresh_preview()


func _add_option(id: String, text: String) -> void:
	var owned: bool = id == "" or Progress.has_cosmetic(_cat, id)
	var equipped: bool = str(Progress.equipped.get(_cat, "")) == id
	var b := UiTheme.button(("✔ " if equipped else "") + (text if owned else "???"), Vector2(112, 28))
	b.disabled = not owned
	b.add_theme_font_size_override("font_size", 11)
	b.pressed.connect(func():
		Audio.play_sfx("select")
		Progress.equip(_cat, id)
		_show_tab("wardrobe"))
	_grid.add_child(b)


func _refresh_preview() -> void:
	for c in _preview_holder.get_children():
		c.queue_free()
	var root := Node2D.new()
	root.position = Vector2(60, 76)
	root.scale = Vector2(4, 4)
	_preview_holder.add_child(root)
	HeroPreview.build(root, "idle")


# ----------------------------------------------------------------- logros ---
func _build_achievements(parent: Control) -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	parent.add_child(v)
	var done: int = Progress.achievements.size()
	v.add_child(UiTheme.label("Logros: %d/%d" % [done, Progress.ACHIEVEMENTS.size()], 13, Color("#ffe97a")))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 3)
	sc.add_child(list)
	var ids: Array = Progress.ACHIEVEMENTS.keys()
	ids.sort_custom(func(a, b): return int(Progress.achievements.has(a)) > int(Progress.achievements.has(b)))
	for id in ids:
		var a: Array = Progress.ACHIEVEMENTS[id]
		var got: bool = Progress.achievements.has(id)
		var pr: Vector2i = Progress.achievement_progress(id)
		var pc := PanelContainer.new()
		pc.modulate = Color(1, 1, 1) if got else Color(0.8, 0.8, 0.9)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		pc.add_child(h)
		var mark := UiTheme.label("★" if got else "☆", 16, Color("#ffd23a") if got else Color("#6a6488"))
		mark.custom_minimum_size.x = 20
		h.add_child(mark)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 0)
		h.add_child(col)
		col.add_child(UiTheme.label(str(a[0]), 11, Color("#ffffff") if got else Color("#d8d2f0")))
		var desc := UiTheme.label("%s (%d/%d)" % [a[1], pr.x, pr.y], 9, Color("#a9a2cc"))
		col.add_child(desc)
		var rw: Array = a[4]
		if not rw.is_empty():
			h.add_child(UiTheme.label("Premio: %s" % Progress.cosmetic_name(str(rw[0]), str(rw[1])), 9, Color("#8affb0") if got else Color("#7a7298")))
		list.add_child(pc)


# ------------------------------------------------------------ estadísticas --
func _build_stats(parent: Control) -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	parent.add_child(v)
	v.add_child(UiTheme.label("Estadísticas", 14, Color("#ffe97a")))
	var secs: int = int(Progress.stats.get("play_time", 0.0))
	var rows: Array = [
		["Tiempo de juego", "%dh %02dm" % [secs / 3600, (secs / 60) % 60]],
		["Niveles completados", "%d/100" % Game.completed_count()],
		["Mundos completados", "%d/10" % Game.worlds_done.size()],
		["Jefes derrotados", "%d" % Progress.stat_value("bosses")],
		["Gemas", "%d/300" % Game.total_gems()],
		["Gemas especiales", "%d" % Progress.special_gems],
		["Monedas reunidas", "%d" % Game.total_coins],
		["Puntos", "%d" % Game.score],
		["Cofres abiertos", "%d" % int(Progress.stats["chests"])],
		["Habitaciones secretas", "%d" % int(Progress.stats["secrets"])],
		["Enemigos derrotados", "%d" % int(Progress.stats["enemies"])],
		["Veces derrotado", "%d" % int(Progress.stats["deaths"])],
		["Niveles sin daño", "%d" % int(Progress.stats["nohit"])],
		["Niveles con 3 gemas", "%d" % int(Progress.stats["allgems"])],
		["Medallas de oro", "%d" % int(Progress.stats["gold"])],
		["Cosméticos", "%d/%d" % [Progress.cosmetics_owned(), Progress.cosmetics_total()]],
		["Récord de supervivencia", "%d oleadas" % int(Progress.stats["survival"])],
		["Logros", "%d/%d" % [Progress.achievements.size(), Progress.ACHIEVEMENTS.size()]],
	]
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 2)
	sc.add_child(grid)
	for r in rows:
		var l1 := UiTheme.label(str(r[0]), 11, Color("#cfc6ff"))
		l1.custom_minimum_size.x = 170
		grid.add_child(l1)
		grid.add_child(UiTheme.label(str(r[1]), 11, Color.WHITE))


# ------------------------------------------------------------------ modos ---
func _build_modes(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 4)
	left.custom_minimum_size.x = 150
	row.add_child(left)
	for m in ["time", "challenge", "bonus", "survival", "bossrush"]:
		var open: bool = Progress.mode_unlocked(m)
		var b := UiTheme.button(str(Progress.MODE_NAMES[m]) if open else "🔒 " + str(Progress.MODE_NAMES[m]), Vector2(150, 34))
		b.disabled = not open
		b.modulate = Color(1, 1, 1) if m == _mode else Color(0.78, 0.78, 0.88)
		b.pressed.connect(func():
			Audio.play_sfx("click")
			_mode = m
			_show_tab("modes"))
		left.add_child(b)
	if not Progress.mode_unlocked(_mode):
		_mode = "time"
	_mode_panel = VBoxContainer.new()
	_mode_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_mode_panel)
	_extras_msg = UiTheme.label("", 10, Color("#ff9a9a"))
	_build_mode_panel()


func _mode_description(m: String) -> String:
	match m:
		"time":
			return "Rejuega un nivel completado a contrarreloj. Medallas de bronce, plata y oro según tu tiempo."
		"challenge":
			return "Un nivel completado con UN solo corazón y sin puntos de control. Premio la primera vez."
		"bonus":
			return "Un nivel bonus por mundo (se abre al derrotar a su jefe): monedas dobles, cofres y un orbe gigante."
		"survival":
			return "Resiste oleadas de enemigos del mundo elegido. Cofres a las 5, 10 y 20 oleadas."
		"bossrush":
			return "Vuelve a enfrentarte al jefe del mundo con solo 2 corazones. Su vida y ataques no cambian."
	return ""


func _build_mode_panel() -> void:
	for c in _mode_panel.get_children():
		c.queue_free()
	var m: String = _mode
	var t := UiTheme.label(str(Progress.MODE_NAMES[m]), 14, Color("#ffe97a"))
	_mode_panel.add_child(t)
	var d := UiTheme.label(_mode_description(m), 10, Color("#cfc6ff"))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size.x = 280
	_mode_panel.add_child(d)
	if m == "time" or m == "challenge":
		var chips := HFlowContainer.new()
		chips.add_theme_constant_override("h_separation", 3)
		_mode_panel.add_child(chips)
		for w in range(1, 11):
			var cb := UiTheme.button(str(w), Vector2(30, 24))
			cb.modulate = Color(1, 1, 1) if w == _mode_world else Color(0.75, 0.75, 0.85)
			cb.pressed.connect(func():
				_mode_world = w
				_build_mode_panel())
			chips.add_child(cb)
		var grid := GridContainer.new()
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 4)
		grid.add_theme_constant_override("v_separation", 4)
		_mode_panel.add_child(grid)
		for i in range(1, 11):
			var n: int = Game.level_number(_mode_world, i)
			var ok: bool = Game.mode_allowed(m, n)
			var label: String = "%d" % i
			if ok and m == "time" and Progress.best_time(n) > 0.0:
				label += "\n%.0fs" % Progress.best_time(n)
			if ok and m == "challenge" and Progress.is_done("challenge", n):
				label += " ✔"
			var b := UiTheme.button(label if ok else "🔒", Vector2(52, 38))
			b.disabled = not ok
			b.add_theme_font_size_override("font_size", 11)
			b.pressed.connect(func(): _launch(m, n))
			grid.add_child(b)
	else:
		var grid2 := GridContainer.new()
		grid2.columns = 5
		grid2.add_theme_constant_override("h_separation", 4)
		grid2.add_theme_constant_override("v_separation", 4)
		_mode_panel.add_child(grid2)
		for w in range(1, 11):
			var n2: int = Game.level_number(w, 10 if m == "bossrush" else 1)
			var ok2: bool = Game.mode_allowed(m, n2)
			var label2: String = "Mundo %d" % w
			if m == "bonus" and Progress.is_done("bonus", w):
				label2 += " ✔"
			elif m == "bossrush" and Progress.is_done("boss", w):
				label2 += " ✔"
			elif m == "survival" and int(Progress.records.get("survival:%d" % w, 0)) > 0:
				label2 += "\n%d ol." % int(Progress.records["survival:%d" % w])
			var b2 := UiTheme.button(label2 if ok2 else "🔒", Vector2(66, 40))
			b2.disabled = not ok2
			b2.add_theme_font_size_override("font_size", 10)
			b2.pressed.connect(func(): _launch(m, n2))
			grid2.add_child(b2)
	if not Progress.mode_unlocked(m):
		_mode_panel.add_child(UiTheme.label(Progress.mode_requirement_text(m), 10, Color("#ff9a9a")))


func _launch(m: String, n: int) -> void:
	Audio.play_sfx("select")
	if Game.start_mode(m, n):
		Transition.change_scene("res://levels/level.tscn")
