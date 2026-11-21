extends Area2D
## Persecución: una roca con pinchos rueda detrás de Wilmen y acelera poco a poco. Si lo alcanza le quita un corazón
## y se frena un momento. Desaparece al llegar a la estación. Mantén el ritmo, salta los obstáculos y corre.

const SHEET := preload("res://assets/items/chaser.png")

var level = null
var end_x: float = INF
var speed: float = 62.0
var max_speed: float = 112.0

var _sprite: Sprite2D
var _pause_t: float = 0.0
var _t: float = 0.0
var _loop_t: float = 0.0
var _gone: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	z_index = 3
	var cs := CollisionShape2D.new()
	var ci := CircleShape2D.new()
	ci.radius = 15.0
	cs.shape = ci
	add_child(cs)
	_sprite = Sprite2D.new()
	_sprite.texture = SHEET
	_sprite.hframes = 2
	add_child(_sprite)
	body_entered.connect(_on_body)


func _physics_process(delta: float) -> void:
	if _gone:
		return
	_t += delta
	_sprite.frame = int(_t * 6.0) % 2
	_sprite.rotation += delta * 5.0 * (speed / 80.0)
	if _pause_t > 0.0:
		_pause_t -= delta
	else:
		speed = minf(max_speed, speed + 3.0 * delta)
		position.x += speed * delta
	_loop_t -= delta
	if _loop_t <= 0.0:
		_loop_t = 0.4
		Audio.play_sfx("rock_roll")
	if level != null and level.player != null:
		# si el jugador va muy por delante la roca se acerca un poco (nunca se queda atrás del todo)
		var gap: float = level.player.global_position.x - global_position.x
		if gap > 380.0:
			position.x = level.player.global_position.x - 380.0
	if global_position.x >= end_x:
		_vanish()
	for b in get_overlapping_bodies():
		_on_body(b)


func _on_body(b: Node) -> void:
	if _gone or _pause_t > 0.0 or not b.is_in_group("player"):
		return
	if b.hurt(1, global_position.x):
		_pause_t = 1.4
		position.x -= 40.0
		speed = 62.0
		Audio.play_sfx("slam")
		if level != null:
			level.shake(4.0)


func _vanish() -> void:
	_gone = true
	if level != null:
		level.spawn_burst(global_position, Color("#c8c8d8"), 14)
		level.popup("¡Escapaste!", global_position + Vector2(0, -26))
	queue_free()
