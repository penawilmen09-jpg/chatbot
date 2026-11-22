extends CharacterBody2D
## Tronco rodante: baja rodando por el suelo (sigue las pendientes) y hace daño al tocarlo. Se salta. Lo lanza ww_chute.gd.

const A := preload("res://items/ww_atlas.gd")
const GRAVITY := 900.0

var dir: int = -1
var speed: float = 88.0
var level = null

var _sprite: Sprite2D
var _area: Area2D
var _life: float = 18.0
var _wall_t: float = 0.0
var _hit_cd: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	z_index = 4
	var cs := CollisionShape2D.new()
	var ci := CircleShape2D.new()
	ci.radius = 7.0
	cs.shape = ci
	add_child(cs)
	_sprite = Sprite2D.new()
	_sprite.texture = A.tex("log")
	add_child(_sprite)
	_area = Area2D.new()
	_area.collision_layer = 0
	_area.collision_mask = 2
	var ac := CollisionShape2D.new()
	var ar := CircleShape2D.new()
	ar.radius = 7.0
	ac.shape = ar
	_area.add_child(ac)
	add_child(_area)


func _physics_process(delta: float) -> void:
	_life -= delta
	_hit_cd = maxf(0.0, _hit_cd - delta)
	velocity.x = dir * speed
	velocity.y = minf(velocity.y + GRAVITY * delta, 360.0)
	move_and_slide()
	_sprite.rotation += dir * speed / 7.0 * delta
	if is_on_wall():
		_wall_t += delta
	else:
		_wall_t = 0.0
	if _life <= 0.0 or _wall_t > 0.15 or (level != null and position.y > level.nrows * 16 + 40):
		queue_free()
		return
	if _hit_cd <= 0.0 and level != null and level.player != null and _area.overlaps_body(level.player) and not level.player.dead:
		_hit_cd = 0.8
		level.player.hurt(1, global_position.x)
