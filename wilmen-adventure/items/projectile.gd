extends Area2D
## Proyectil genérico: chispas y hielo del jugador; frutos, cristales, bolas y olas de enemigos y jefes.

const SHEET := preload("res://assets/items/projectiles.png")
const KINDS := {"spark": 0, "ice": 1, "shard": 2, "orb": 3, "snowball": 4, "acorn": 5, "wave": 6, "sand": 7,
	"fire": 8, "bolt": 9, "thorn": 10, "gear": 11, "void": 12, "feather": 13}
const SPINNERS := ["shard", "acorn", "sand", "thorn", "gear", "bolt"]

var team: String = "enemy"  # "player" | "enemy"
var kind: String = "orb"
var velocity: Vector2 = Vector2.ZERO
var fall_accel: float = 0.0
var bounce: bool = false
var life: float = 3.0
var damage: int = 1
var sprite_scale: float = 1.0
var pierce: bool = false  # atraviesa enemigos (ráfaga)

var _bounces: int = 0
var _sprite: Sprite2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 4 if team == "player" else 2
	monitoring = true
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0 * sprite_scale
	cs.shape = circle
	add_child(cs)
	var tex := AtlasTexture.new()
	tex.atlas = SHEET
	tex.region = Rect2(int(KINDS.get(kind, 0)) * 8, 0, 8, 8)
	_sprite = Sprite2D.new()
	_sprite.texture = tex
	_sprite.scale = Vector2(sprite_scale, sprite_scale)
	add_child(_sprite)
	z_index = 5
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		_pop()
		return
	velocity.y += fall_accel * delta
	var motion: Vector2 = velocity * delta
	var space := get_world_2d().direct_space_state
	var ahead: Vector2 = global_position + motion + motion.normalized() * 3.0
	var q := PhysicsRayQueryParameters2D.create(global_position, ahead, 1)
	var hit: Dictionary = space.intersect_ray(q)
	if hit.is_empty():
		position += motion
	elif bounce and _bounces < 8:
		var n: Vector2 = hit["normal"]
		velocity = velocity.bounce(n) * 0.92
		if n.y < -0.5:
			velocity.y = -170.0
		global_position = hit["position"] + n * 3.0
		_bounces += 1
	else:
		_pop()
		return
	if kind == "wave" or kind == "spark" or kind == "ice" or kind == "feather" or kind == "fire":
		_sprite.flip_h = velocity.x < 0.0
	elif SPINNERS.has(kind):
		_sprite.rotation += 8.0 * delta


func _on_body_entered(b: Node) -> void:
	if team == "player":
		if b.has_method("take_hit"):
			b.take_hit(kind)
			if not pierce:
				_pop()
	elif b.has_method("hurt"):
		b.hurt(damage, global_position.x)
		_pop()


func _pop() -> void:
	set_physics_process(false)
	var lvl = get_parent()
	if lvl != null and lvl.has_method("spawn_burst"):
		lvl.spawn_burst(global_position, Color("#ffffff") if team == "player" else Color("#ffb04a"), 4)
	queue_free()
