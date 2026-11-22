extends Node2D
## Mapa general de WILMEN WORLD: un continente 2D con 6 regiones y 120 niveles. El héroe CAMINA por los caminos (con su
## animación) de nivel en nivel; los caminos se abren al completar niveles o al encontrar salidas secretas.
## Controles: tocar un nivel (el héroe va por el camino más corto), flechas en pantalla (nivel contiguo), arrastrar para mirar
## el mapa y «ENTRAR». Los datos del mapa están en levels/world/map.json (tools/ww_map.py).

const UiTheme := preload("res://ui/ui_theme.gd")
const AudioPanel := preload("res://ui/audio_panel.gd")
const HeroPreview := preload("res://ui/hero_preview.gd")
const ICONS := preload("res://assets/ww_map/icons.png")
const TERRAIN := preload("res://assets/ww_map/terrain.png")
const FONT := preload("res://assets/ui/DejaVuSans-Bold.ttf")
const KIND_ICON := {"dot": 0, "house": 1, "cave": 2, "fortress": 3, "castle": 4, "sealed": 5}
const BADGE := {"lock": 6, "flag": 7, "sign": 8, "spark": 9, "star": 10}
const ICON_BRIDGE := 11
const ICON_TUNNEL := 12
const WALK_SPEED := 96.0

var node_views: Dictionary = {}  # id -> Node2D
var hero: Node2D
var hero_sprite: AnimatedSprite2D
var camera: Camera2D
var paths: Node2D
var at_node: int = 1
var walking: bool = false
var pending_target: int = -1
var grow: Dictionary = {}  # índice de camino -> 0..1 mientras se anima su aparición

var _path_pts: Array = []  # polilínea que se recorre
var _path_i: int = 0
var _path_nodes: Array = []  # [{"to": id, "end_index": int}]
var _steps: Array = []
var _step_i: int = 0
var _foot_t: float = 0.0
var _free_cam: Vector2 = Vector2.ZERO
var _dragging: bool = false
var _drag_moved: float = 0.0
var _t: float = 0.0
var _hud: CanvasLayer
var _info: Label
var _info2: Label
var _enter_btn: Button
var _stats: Label
var _prog: Label
var _banner: Label
var _menu_panel: Control = null
var _last_region: int = 0
var _reset_armed: bool = false
var _dpad: Dictionary = {}
var _snapshot_before: Dictionary = {}


func _ready() -> void:
	Game.world_leave()  # por si se vuelve de un nivel: la partida original ya está restaurada
	if not FileAccess.file_exists(WW.save_path):
		WW.save_game()
	var data: Dictionary = WW.map_data()
	at_node = WW.map_node
	if not WW.is_walkable(at_node):
		at_node = int(data["start"])
	var terrain := Sprite2D.new()
	terrain.texture = TERRAIN
	terrain.centered = false
	terrain.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(terrain)
	paths = Node2D.new()
	paths.set_script(preload("res://ui/ww_map_paths.gd"))
	paths.map = self
	add_child(paths)
	_build_region_labels(data)
	var layer := Node2D.new()
	layer.y_sort_enabled = true
	add_child(layer)
	for n in data["nodes"]:
		_make_node_view(layer, n)
	hero = Node2D.new()
	hero.scale = Vector2(0.95, 0.95)
	hero.z_index = 20
	layer.add_child(hero)
	hero_sprite = HeroPreview.build(hero, "idle")
	hero.position = _pos_of(at_node)
	camera = Camera2D.new()
	camera.zoom = Vector2(0.85, 0.85)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(data["world"][0])
	camera.limit_bottom = int(data["world"][1])
	add_child(camera)
	camera.make_current()
	camera.position = hero.position
	camera.reset_smoothing()
	_build_hud()
	_refresh_all()
	_announce_region(true)
	_reveal_new()
	Audio.play_music("map")
	paths.queue_redraw()


func _pos_of(id: int) -> Vector2:
	var n: Dictionary = WW.map_node_data(id)
	return Vector2(float(n["pos"][0]), float(n["pos"][1]))


# ------------------------------------------------------------ construcción --
func _atlas(i: int) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = ICONS
	at.region = Rect2(i * 32, 0, 32, 32)
	return at


func _make_node_view(layer: Node2D, n: Dictionary) -> void:
	var id: int = int(n["id"])
	var v := Node2D.new()
	v.position = Vector2(float(n["pos"][0]), float(n["pos"][1]))
	layer.add_child(v)
	var icon := Sprite2D.new()
	icon.name = "icon"
	icon.texture = _atlas(int(KIND_ICON[str(n["kind"])]))
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.position = Vector2(0, -8)
	v.add_child(icon)
	var badge := Sprite2D.new()
	badge.name = "badge"
	badge.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	badge.position = Vector2(13, -22)
	badge.scale = Vector2(0.6, 0.6)
	v.add_child(badge)
	var lbl := UiTheme.label("", 8, Color.WHITE)
	lbl.name = "label"
	lbl.add_theme_font_override("font", FONT)
	lbl.size = Vector2(40, 12)
	lbl.position = Vector2(-20, 6)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(lbl)
	var stars := Node2D.new()
	stars.name = "stars"
	v.add_child(stars)
	for i in range(3):
		var s := Sprite2D.new()
		s.texture = _atlas(BADGE["star"])
		s.scale = Vector2(0.4, 0.4)
		s.position = Vector2(-8 + i * 8, 22)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		stars.add_child(s)
	node_views[id] = v


func _build_region_labels(data: Dictionary) -> void:
	for r in data["regions"]:
		var b: Array = r["box"]
		var l := UiTheme.label(str(r["name"]).to_upper(), 14, Color("#ffffff"))
		l.add_theme_font_override("font", FONT)
		l.add_theme_constant_override("outline_size", 5)
		l.position = Vector2(float(b[0]) + 14.0, float(b[1]) - 4.0)
		l.z_index = 5
		add_child(l)
		if str(r["status"]) != "playable":
			var c := UiTheme.label("región en construcción", 9, Color("#ffd27a"))
			c.position = Vector2(float(b[0]) + 16.0, float(b[1]) + 14.0)
			c.z_index = 5
			add_child(c)


class DirButton extends Button:
	var dir: Vector2 = Vector2.RIGHT

	func _draw() -> void:
		var c: Vector2 = size * 0.5
		var d: Vector2 = dir
		var p: Vector2 = Vector2(-d.y, d.x)
		var pts := PackedVector2Array([c + d * 9.0, c - d * 7.0 + p * 8.0, c - d * 7.0 - p * 8.0])
		draw_colored_polygon(pts, Color("#ffd23a"))
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), Color("#1a1226"), 2.0)


func _build_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.layer = 10
	add_child(_hud)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UiTheme.make()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(root)
	_stats = UiTheme.label("", 9)
	_stats.position = Vector2(8, 6)
	root.add_child(_stats)
	_prog = UiTheme.label("", 9, Color("#ffe97a"))
	_prog.position = Vector2(8, 19)
	root.add_child(_prog)
	var menu := UiTheme.button("Menú", Vector2(54, 24))
	menu.anchor_left = 1.0
	menu.anchor_right = 1.0
	menu.offset_left = -62
	menu.offset_right = -8
	menu.offset_top = 6
	menu.offset_bottom = 30
	menu.add_theme_font_size_override("font_size", 11)
	menu.pressed.connect(_toggle_menu)
	root.add_child(menu)
	_banner = UiTheme.label("", 16, Color("#ffffff"))
	_banner.add_theme_font_override("font", FONT)
	_banner.add_theme_constant_override("outline_size", 6)
	_banner.anchor_left = 0.0
	_banner.anchor_right = 1.0
	_banner.offset_top = 46
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.modulate.a = 0.0
	root.add_child(_banner)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -110
	panel.offset_right = 110
	panel.offset_top = -52
	panel.offset_bottom = -6
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	panel.add_child(v)
	_info = UiTheme.label("", 11, Color("#ffffff"))
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_info)
	_info2 = UiTheme.label("", 8, Color("#cfc6ff"))
	_info2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_info2)
	_enter_btn = UiTheme.button("ENTRAR", Vector2(96, 40))
	_enter_btn.anchor_left = 1.0
	_enter_btn.anchor_right = 1.0
	_enter_btn.anchor_top = 1.0
	_enter_btn.anchor_bottom = 1.0
	_enter_btn.offset_left = -108
	_enter_btn.offset_right = -10
	_enter_btn.offset_top = -50
	_enter_btn.offset_bottom = -10
	_enter_btn.add_theme_font_size_override("font_size", 15)
	_enter_btn.pressed.connect(_enter_current)
	root.add_child(_enter_btn)
	var dirs := {"up": Vector2.UP, "down": Vector2.DOWN, "left": Vector2.LEFT, "right": Vector2.RIGHT}
	var cell := 34.0
	var base := Vector2(10, -4)  # esquina inferior izquierda
	var offs := {"up": Vector2(cell, -2 * cell), "down": Vector2(cell, 0), "left": Vector2(0, -cell), "right": Vector2(2 * cell, -cell)}
	for k in dirs:
		var b := DirButton.new()
		b.dir = dirs[k]
		b.custom_minimum_size = Vector2(cell - 2, cell - 2)
		b.size = Vector2(cell - 2, cell - 2)
		b.anchor_top = 1.0
		b.anchor_bottom = 1.0
		b.offset_left = base.x + offs[k].x
		b.offset_top = base.y + offs[k].y - cell
		b.offset_right = b.offset_left + cell - 2
		b.offset_bottom = b.offset_top + cell - 2
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func(): _press_dir(dirs[k]))
		root.add_child(b)
		_dpad[k] = b


# ------------------------------------------------------------ actualización --
func _refresh_all() -> void:
	var data: Dictionary = WW.map_data()
	for n in data["nodes"]:
		_refresh_node(int(n["id"]))
	_stats.text = "Vidas %d   Monedas %d   Gemas %d   Llaves %d" % [WW.lives, WW.coins, _total_gems(), WW.key_count()]
	_prog.text = "Niveles completados %d/%d" % [WW.completed_count(), WW.LEVEL_COUNT]
	_update_info()


func _total_gems() -> int:
	var g: int = 0
	for k in WW.levels:
		g += WW.gems_in(int(k))
	return g


func _local_name(id: int) -> String:
	var n: Dictionary = WW.map_node_data(id)
	if int(n.get("idx", 0)) == 0:
		return "Túnel sellado"
	return "%d-%d" % [int(n["region"]), int(n["idx"])]


func _refresh_node(id: int) -> void:
	var v: Node2D = node_views[id]
	var st: String = WW.node_state(id)
	v.visible = st != "hidden"
	if st == "hidden":
		return
	var icon: Sprite2D = v.get_node("icon")
	var badge: Sprite2D = v.get_node("badge")
	var stars: Node2D = v.get_node("stars")
	var lbl: Label = v.get_node("label")
	lbl.text = _local_name(id) if st != "sealed" else ""
	icon.modulate = Color.WHITE
	badge.visible = true
	stars.visible = false
	match st:
		"locked":
			icon.modulate = Color(0.45, 0.45, 0.55)
			badge.texture = _atlas(BADGE["lock"])
		"construction":
			icon.modulate = Color(0.55, 0.55, 0.6)
			badge.texture = _atlas(BADGE["sign"])
		"available":
			badge.texture = _atlas(BADGE["spark"])
		"done":
			badge.texture = _atlas(BADGE["flag"])
			stars.visible = true
			var gm: Array = WW.record(id)["gems"]
			for i in range(3):
				stars.get_child(i).modulate = Color.WHITE if bool(gm[i]) else Color(0.2, 0.2, 0.3, 0.7)
		"sealed":
			badge.visible = false


func _update_info() -> void:
	var id: int = at_node
	var n: Dictionary = WW.map_node_data(id)
	var st: String = WW.node_state(id)
	var title: String = ""
	var detail: String = ""
	if int(n.get("idx", 0)) == 0:
		title = "Túnel sellado"
		detail = "Lleva al Océano Perdido, región en construcción"
	else:
		title = _local_name(id)
		if WW.has_level(id):
			var info: Dictionary = WW.level_info(id)
			title += "  " + str(info["title"])
			var kinds := {"normal": "", "cave": "Cueva", "house": "Casa de bonificación", "fortress": "Fortaleza", "castle": "Castillo", "secret": "Ruta secreta"}
			var tm: int = int(info["time"])
			detail = "%s Tiempo %d:%02d · Dificultad %d/5 · Gemas %d/3%s" % [str(kinds.get(str(info.get("kind", "normal")), "")) + (" ·" if str(info.get("kind", "normal")) != "normal" else ""), tm / 60, tm % 60, int(info["difficulty"]), WW.gems_in(id), "  ✔" if WW.is_done(id) else ""]
		else:
			detail = "En construcción: este nivel todavía no se puede jugar"
	_info.text = title
	_info2.text = detail
	var can: bool = WW.can_enter(id) and not walking
	_enter_btn.disabled = not can and st != "sealed"
	_enter_btn.text = "ENTRAR" if st != "sealed" else "VER"
	if st == "construction":
		_enter_btn.text = "EN OBRAS"
	elif st == "locked":
		_enter_btn.text = "BLOQUEADO"


func _announce_region(first: bool = false) -> void:
	var rg: int = int(WW.map_node_data(at_node).get("region", 1))
	if rg == _last_region:
		return
	_last_region = rg
	var nm: String = ""
	var status: String = ""
	for r in WW.map_data()["regions"]:
		if int(r["id"]) == rg:
			nm = str(r["name"])
			status = str(r["status"])
	_banner.text = nm if status == "playable" else "%s\n(región en construcción)" % nm
	var tw := create_tween()
	tw.tween_property(_banner, "modulate:a", 1.0, 0.3)
	tw.tween_interval(1.6)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.6)


# ------------------------------------------------------------- desbloqueos --
func _reveal_new() -> void:
	## Anima lo que se acaba de abrir desde la última vez que se vio el mapa y lo anota como visto.
	var seen_n: Array = WW.nodes.get("seen_n", [])
	var seen_e: Array = WW.nodes.get("seen_e", [])
	var snap: Dictionary = WW.map_snapshot()
	var first_visit: bool = seen_n.is_empty() and seen_e.is_empty()
	var new_edges: Array = []
	for e in snap["edges"]:
		if not seen_e.has(e):
			new_edges.append(e)
	var new_nodes: Array = []
	for n in snap["nodes"]:
		if not seen_n.has(n):
			new_nodes.append(n)
	WW.nodes["seen_n"] = snap["nodes"]
	WW.nodes["seen_e"] = snap["edges"]
	WW.save_game()
	if first_visit or (new_edges.is_empty() and new_nodes.is_empty()):
		return
	Audio.play_sfx("checkpoint")
	var focus: int = at_node
	for ei in new_edges:
		grow[ei] = 0.0
	for nid in new_nodes:
		if node_views.has(nid):
			var v: Node2D = node_views[nid]
			v.scale = Vector2(0.01, 0.01)
			var tw := create_tween()
			tw.tween_interval(0.6)
			tw.tween_property(v, "scale", Vector2(1.2, 1.2), 0.25)
			tw.tween_property(v, "scale", Vector2(1, 1), 0.15)
			focus = nid
	if focus != at_node:
		_free_cam = _pos_of(focus) - hero.position
		var tw2 := create_tween()
		tw2.tween_interval(2.4)
		tw2.tween_callback(func(): _free_cam = Vector2.ZERO)


# ---------------------------------------------------------------- bucle ----
func _process(delta: float) -> void:
	_t += delta
	var growing: bool = false
	for k in grow.keys():
		grow[k] = minf(1.0, float(grow[k]) + delta * 0.8)
		growing = true
		if float(grow[k]) >= 1.0:
			grow.erase(k)
	if growing:
		paths.queue_redraw()
	# los niveles disponibles laten
	for id in node_views:
		var v: Node2D = node_views[id]
		if v.visible and WW.node_state(int(id)) == "available" and v.scale.x >= 0.99:
			var s: float = 1.0 + 0.06 * sin(_t * 4.0 + float(id))
			v.get_node("icon").scale = Vector2(s, s)
	if walking:
		_walk(delta)
	camera.position = hero.position + _free_cam


func _walk(delta: float) -> void:
	var left: float = WALK_SPEED * delta
	while left > 0.0 and _path_i < _path_pts.size():
		var target: Vector2 = _path_pts[_path_i]
		var d: float = hero.position.distance_to(target)
		if d <= left:
			hero.position = target
			left -= d
			_path_i += 1
		else:
			var dir: Vector2 = (target - hero.position) / d
			hero.position += dir * left
			hero_sprite.flip_h = dir.x < 0.0
			left = 0.0
	_foot_t -= delta
	if _foot_t <= 0.0:
		_foot_t = 0.28
		Audio.play_sfx("click", 0.7)
	# ¿llegó al final de un tramo?
	while _step_i < _steps.size() and _path_i >= int(_steps[_step_i]["end_index"]):
		at_node = int(_steps[_step_i]["to"])
		WW.map_node = at_node
		_step_i += 1
		_announce_region()
		_update_info()
	if _path_i >= _path_pts.size():
		_stop_walk()


func _stop_walk() -> void:
	walking = false
	hero_sprite.play("idle")
	WW.save_game()
	_update_info()
	if pending_target >= 0:
		var t: int = pending_target
		pending_target = -1
		_walk_to(t)


func _walk_to(target: int) -> bool:
	if walking:
		pending_target = target
		return true
	if target == at_node:
		_update_info()
		return false
	if not WW.is_walkable(target):
		_msg_for(target)
		return false
	var rt: Array = WW.route(at_node, target)
	if rt.is_empty():
		_msg_for(target)
		return false
	_path_pts = []
	_steps = []
	_step_i = 0
	_path_i = 0
	for st in rt:
		var e: Dictionary = st["edge"]
		var pts: Array = e["path"]
		var ordered: Array = pts.duplicate() if int(e["a"]) == int(st["from"]) else _reversed(pts)
		for p in ordered:
			_path_pts.append(Vector2(float(p[0]), float(p[1])))
		_steps.append({"to": int(st["to"]), "end_index": _path_pts.size()})
	walking = true
	hero_sprite.play("run")
	_update_info()
	return true


func _reversed(a: Array) -> Array:
	var r: Array = a.duplicate()
	r.reverse()
	return r


func _msg_for(target: int) -> void:
	var st: String = WW.node_state(target)
	var t: String = "Aún no hay camino hasta ahí: completa niveles para abrirlo"
	if st == "construction":
		t = "Región en construcción: llegará en una próxima etapa"
	elif st == "locked":
		t = "Nivel bloqueado: completa el nivel anterior"
	_info2.text = t
	Audio.play_sfx("shield", 0.6)


func _press_dir(dir: Vector2) -> void:
	if walking:
		return
	var best: int = -1
	var best_dot: float = 0.35
	for nb in WW.neighbors(at_node):
		var e: Dictionary = nb["edge"]
		var pts: Array = e["path"]
		var p0: Vector2 = Vector2(float(pts[0][0]), float(pts[0][1]))
		var p1: Vector2 = Vector2(float(pts[pts.size() - 1][0]), float(pts[pts.size() - 1][1]))
		if int(e["a"]) != at_node:
			var tmp: Vector2 = p0
			p0 = p1
			p1 = tmp
		var to: Vector2 = (_pos_of(int(nb["to"])) - hero.position).normalized()
		var d: float = to.dot(dir)
		if d > best_dot:
			best_dot = d
			best = int(nb["to"])
	if best >= 0:
		_walk_to(best)
	else:
		Audio.play_sfx("shield", 0.6)


func _enter_current() -> void:
	if walking:
		return
	var st: String = WW.node_state(at_node)
	if st == "sealed":
		_info2.text = "El túnel está sellado: lleva al Océano Perdido, que llegará en una próxima etapa"
		return
	if not WW.can_enter(at_node):
		return
	enter_level(at_node)


func enter_level(id: int) -> void:
	if WW.start_level(id):
		if id != WW.LAB:
			WW.map_node = id
		WW.save_game()
		Audio.play_sfx("select")
		Transition.change_scene("res://levels/ww_level.tscn")


# --------------------------------------------------------------- entrada ----
func _unhandled_input(event: InputEvent) -> void:
	if _menu_panel != null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_moved = 0.0
		else:
			if _dragging and _drag_moved < 12.0:
				_tap(get_global_mouse_position())
			_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		_drag_moved += event.relative.length()
		if _drag_moved > 12.0:
			_free_cam -= event.relative / camera.zoom
			_free_cam = _free_cam.limit_length(520.0)


func _tap(world_pos: Vector2) -> void:
	var best: int = -1
	var best_d: float = 26.0
	for id in node_views:
		var v: Node2D = node_views[id]
		if not v.visible:
			continue
		var d: float = v.position.distance_to(world_pos + Vector2(0, 8))
		if d < best_d:
			best_d = d
			best = int(id)
	if best >= 0:
		_free_cam = Vector2.ZERO
		if best == at_node:
			_enter_current()
		else:
			_walk_to(best)


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_UP:
			_press_dir(Vector2.UP)
		KEY_DOWN:
			_press_dir(Vector2.DOWN)
		KEY_LEFT:
			_press_dir(Vector2.LEFT)
		KEY_RIGHT:
			_press_dir(Vector2.RIGHT)
		KEY_ENTER, KEY_SPACE:
			_enter_current()


# ------------------------------------------------------------------ menú ----
func _toggle_menu() -> void:
	if _menu_panel != null:
		_menu_panel.queue_free()
		_menu_panel = null
		return
	var o := Control.new()
	o.set_anchors_preset(Control.PRESET_FULL_RECT)
	o.theme = UiTheme.make()
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.01, 0.08, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	o.add_child(dim)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	o.add_child(c)
	var p := PanelContainer.new()
	c.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	var t := UiTheme.label("WILMEN WORLD", 18, Color("#ffd23a"))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	v.add_child(AudioPanel.build(240.0))
	var b1 := UiTheme.button("Continuar", Vector2(200, 30))
	b1.pressed.connect(_toggle_menu)
	v.add_child(b1)
	var bl := UiTheme.button("Taller de mecánicas (pruebas)", Vector2(200, 30))
	bl.pressed.connect(func():
		_toggle_menu()
		enter_level(WW.LAB))
	v.add_child(bl)
	var b2 := UiTheme.button("Volver al menú principal", Vector2(200, 30))
	b2.pressed.connect(func():
		WW.save_game()
		Transition.change_scene("res://ui/title.tscn"))
	v.add_child(b2)
	var b3 := UiTheme.button("Reiniciar WILMEN WORLD", Vector2(200, 30))
	b3.pressed.connect(func():
		if not _reset_armed:
			_reset_armed = true
			b3.text = "¿Seguro? Pulsa otra vez"
			return
		_reset_armed = false
		WW.reset()
		WW.save_game()
		Transition.change_scene("res://ui/ww_map.tscn"))
	v.add_child(b3)
	_hud.add_child(o)
	_menu_panel = o
	b1.grab_focus()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _menu_panel != null:
			_toggle_menu()
		else:
			_toggle_menu()
