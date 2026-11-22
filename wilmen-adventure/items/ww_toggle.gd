extends StaticBody2D
## Bloque conmutable: sólido o fantasma según el estado de un interruptor. Un tramo horizontal de la misma letra es un bloque.
## Nunca se vuelve sólido encima del jugador (espera a que salga).

const A := preload("res://items/ww_atlas.gd")

var level = null
var group: int = 1
var solid_when_on: bool = false
var cells: int = 1
var _cs: CollisionShape2D
var _area: Area2D
var _tiles: Array = []
var _solid: bool = true


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_cs = CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(cells * 16, 16)
	_cs.shape = rs
	_cs.position = Vector2(cells * 8 - 8, 0)
	add_child(_cs)
	_area = Area2D.new()
	_area.collision_layer = 0
	_area.collision_mask = 2
	var ac := CollisionShape2D.new()
	var ar := RectangleShape2D.new()
	ar.size = Vector2(cells * 16 + 2, 18)
	ac.shape = ar
	ac.position = _cs.position
	_area.add_child(ac)
	add_child(_area)
	for i in range(cells):
		var s := Sprite2D.new()
		s.position = Vector2(i * 16, 0)
		add_child(s)
		_tiles.append(s)
	_solid = _want()
	_cs.disabled = not _solid
	_paint()
	if level != null:
		level.switch_changed.connect(func(_g): pass)
		add_to_group("ww_reset")


func _want() -> bool:
	if level == null:
		return true
	var on: bool = bool(level.sw[group - 1])
	return on == solid_when_on


func _paint() -> void:
	for s in _tiles:
		s.texture = A.tex("blk%d%s" % [group, "" if _solid else "_ghost"])


func reset_state() -> void:
	pass


func _physics_process(_delta: float) -> void:
	var want: bool = _want()
	if want == _solid:
		return
	if want and level != null and level.player != null and _area.overlaps_body(level.player):
		return  # no se cierra encima del jugador
	_solid = want
	_cs.set_deferred("disabled", not want)
	_paint()
