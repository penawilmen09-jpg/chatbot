extends AnimatableBody2D
## Plataforma móvil (horizontal o vertical). Se puede atravesar desde abajo.

@export var horizontal: bool = true
@export var world: int = 1
var amplitude: float = 40.0
var speed: float = 1.3

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
	var sp := Sprite2D.new()
	if Game.world_active() and world == 3:
		# WILMEN WORLD (desierto): bloque de arenisca tallada, algo más grueso que la colisión (la superficie queda a la misma altura)
		sp.texture = load("res://assets/tiles/mplatform_stone.png")
		sp.offset = Vector2(0, 4)
	else:
		sp.texture = load("res://assets/tiles/mplatform_w%d.png" % world)
	add_child(sp)


func _physics_process(delta: float) -> void:
	_t += delta
	var off: float = sin(_t * speed) * amplitude
	position = _origin + (Vector2(off, 0.0) if horizontal else Vector2(0.0, off))
