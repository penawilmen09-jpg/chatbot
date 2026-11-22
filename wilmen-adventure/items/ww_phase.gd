extends StaticBody2D
## Plataforma que desaparece: ciclo fijo (visible, parpadeo de aviso, oculta). Un tramo de `-` contiguas es UNA plataforma.
## Cada una tiene su fase según su posición para que las cadenas se puedan cruzar con el ritmo adecuado.

const A := preload("res://items/ww_atlas.gd")
const VISIBLE := 2.0
const WARN := 0.55
const HIDDEN := 1.05

var cells: int = 3
var offset: float = 0.0
var _cs: CollisionShape2D
var _tiles: Array = []
var _t: float = 0.0
var solid: bool = true


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_cs = CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(cells * 16, 6)
	_cs.shape = rs
	_cs.position = Vector2(cells * 8 - 8, -5)
	_cs.one_way_collision = true
	_cs.one_way_collision_margin = 5.0
	add_child(_cs)
	for i in range(cells):
		var s := Sprite2D.new()
		s.texture = A.tex("phase")
		s.position = Vector2(i * 16, 0)
		add_child(s)
		_tiles.append(s)
	_t = offset
	_apply()


func is_solid_at(time_s: float) -> bool:
	return fposmod(time_s, VISIBLE + HIDDEN) < VISIBLE + WARN * 0.0


func _physics_process(delta: float) -> void:
	_t += delta
	_apply()


func _apply() -> void:
	var ph: float = fposmod(_t, VISIBLE + WARN + HIDDEN)
	var want: bool = ph < VISIBLE + WARN
	var blink: bool = ph >= VISIBLE and int(ph * 14.0) % 2 == 0
	for s in _tiles:
		s.texture = A.tex("phase" if want else "phase_ghost")
		s.modulate.a = 0.35 if blink else 1.0
	if want != solid:
		solid = want
		_cs.set_deferred("disabled", not want)
