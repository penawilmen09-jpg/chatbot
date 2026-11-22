extends Node2D
## Lanzadardos de pared: parpadea (aviso) y lanza un dardo recto cada pocos segundos. Glifos: " hacia la izquierda · ` derecha.
## El dardo hace daño y se rompe contra el terreno.

const A := preload("res://items/ww_atlas.gd")
const PERIOD := 2.7
const WARN := 0.55
const SPEED := 150.0

var level = null
var dir: int = -1
var _t: float = 0.0
var _sprite: Sprite2D


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = A.tex("dart_shooter")
	_sprite.flip_h = dir > 0
	add_child(_sprite)
	_t = float(int(global_position.x) % 13) * 0.29


func _physics_process(delta: float) -> void:
	_t += delta
	var ph: float = fposmod(_t, PERIOD)
	_sprite.modulate = Color(1.6, 0.7, 0.7) if ph > PERIOD - WARN and int(ph * 16.0) % 2 == 0 else Color.WHITE
	if ph < delta and _t > delta * 2.0:
		fire()


func fire() -> void:
	if level == null:
		return
	var d := Dart.new()
	d.dir = dir
	d.level = level
	d.position = position + Vector2(dir * 10.0, 0.0)
	level.add_child(d)
	Audio.play_sfx("enemy_shoot", 0.9)


class Dart extends Area2D:
	var dir: int = -1
	var level = null
	var _life: float = 4.0

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 2
		z_index = 5
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(12, 4)
		cs.shape = rs
		add_child(cs)
		var s := Sprite2D.new()
		s.texture = A.tex("dart")
		s.flip_h = dir > 0
		add_child(s)

	func _physics_process(delta: float) -> void:
		_life -= delta
		var step: Vector2 = Vector2(dir * SPEED * delta, 0.0)
		var q := PhysicsRayQueryParameters2D.create(global_position, global_position + step + Vector2(dir * 6.0, 0.0), 1)
		if _life <= 0.0 or not get_world_2d().direct_space_state.intersect_ray(q).is_empty():
			queue_free()
			return
		position += step
		if level != null and level.player != null and not level.player.dead and overlaps_body(level.player):
			level.player.hurt(1, global_position.x)
			queue_free()
