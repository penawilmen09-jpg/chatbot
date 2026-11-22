extends AnimatableBody2D
## Plataforma orbital: recorre un círculo de 3 celdas de radio (glifo `n`, su celda es el centro).
## Ascensor (glifo `b`): sube 6 celdas desde su celda y baja, con paradas.

const A := preload("res://items/ww_atlas.gd")

var kind: String = "orbit"  # orbit | elevator
var _origin: Vector2
var _t: float = 0.0


func _ready() -> void:
	sync_to_physics = true
	collision_layer = 1
	collision_mask = 0
	_origin = position
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(32, 8)
	cs.shape = rs
	cs.one_way_collision = true
	cs.one_way_collision_margin = 4.0
	add_child(cs)
	for i in range(2):
		var s := Sprite2D.new()
		s.texture = A.tex("orbit" if kind == "orbit" else "elevator")
		s.position = Vector2(-8 + i * 16, 0)
		add_child(s)
	if kind == "orbit":
		_t = float(int(_origin.x) % 5) * 0.9
	_place()


func _place() -> void:
	if kind == "orbit":
		var a: float = _t * 0.9
		position = _origin + Vector2(cos(a), sin(a)) * 48.0
	else:
		var cyc: float = 6.4
		var ph: float = fposmod(_t, cyc)
		var f: float = 0.0
		if ph < 1.0:
			f = 0.0
		elif ph < 3.2:
			f = smoothstep(0.0, 1.0, (ph - 1.0) / 2.2)
		elif ph < 4.2:
			f = 1.0
		else:
			f = 1.0 - smoothstep(0.0, 1.0, (ph - 4.2) / 2.2)
		position = _origin + Vector2(0.0, -96.0 * f)


func _physics_process(delta: float) -> void:
	_t += delta
	_place()
