extends CharacterBody2D
## Enemigo básico con 5 comportamientos: walker, spiky, jumper, flyer, shooter.
##  - walker : patrulla, da la vuelta en paredes y bordes y persigue si te ve cerca.
##  - spiky  : patrulla con pinchos (no se puede pisar).
##  - jumper : salta hacia ti a intervalos.
##  - flyer  : vuela en onda y te persigue si te acercas.
##  - shooter: estático, te dispara si estás a tiro.

const SpriteUtil := preload("res://characters/sprite_util.gd")
const ProjectileScene := preload("res://items/projectile.tscn")

const GRAVITY := 900.0
const ROWS := {"walker": 0, "spiky": 1, "jumper": 2, "flyer": 3, "shooter": 4}
const SHOT_KINDS := ["acorn", "shard", "sand", "snowball", "orb"]

@export var kind: String = "walker"
@export var world: int = 1
var level = null

var dead: bool = false
var frozen_t: float = 0.0
var dir: int = -1
var stompable: bool = true

var _player = null
var _sprite: AnimatedSprite2D
var _hit: Area2D
var _edge_ray: RayCast2D
var _t: float = 0.0
var _speed: float = 28.0
var _hop_t: float = 1.0
var _shoot_t: float = 1.2
var _turn_t: float = 0.0
var _home_x: float = 0.0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	_home_x = position.x
	stompable = kind != "spiky"
	_speed = 26.0 + 4.0 * world
	if kind == "spiky":
		_speed = 34.0 + 3.0 * world
	dir = -1 if randf() < 0.5 else 1

	var cs := CollisionShape2D.new()
	var hs := CollisionShape2D.new()
	_hit = Area2D.new()
	_hit.collision_layer = 0
	_hit.collision_mask = 2
	if kind == "flyer":
		motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
		var c := CircleShape2D.new()
		c.radius = 6.0
		cs.shape = c
		var c2 := CircleShape2D.new()
		c2.radius = 7.5
		hs.shape = c2
	else:
		var r := RectangleShape2D.new()
		r.size = Vector2(12, 14) if kind == "shooter" else Vector2(12, 12)
		cs.shape = r
		cs.position = Vector2(0, 1 if kind == "shooter" else 2)
		var r2 := RectangleShape2D.new()
		r2.size = Vector2(14, 14)
		hs.shape = r2
		hs.position = Vector2(0, 1)
	add_child(cs)
	_hit.add_child(hs)
	add_child(_hit)

	var tex: Texture2D = load("res://assets/enemies/enemies_w%d.png" % world)
	var row: int = int(ROWS[kind])
	var anims := {}
	match kind:
		"walker":
			anims = {"idle": {"frames": [0, 1, 0, 1], "fps": 6.0, "row": row}}
		"spiky":
			anims = {"idle": {"frames": [0, 1, 2, 3], "fps": 10.0, "row": row}}
		"jumper":
			anims = {
				"idle": {"frames": [0], "fps": 1.0, "row": row},
				"jump": {"frames": [1], "fps": 1.0, "row": row},
			}
		"flyer":
			anims = {"idle": {"frames": [0, 1, 2, 1], "fps": 10.0, "row": row}}
		"shooter":
			anims = {
				"idle": {"frames": [0, 1], "fps": 2.0, "row": row},
				"fire": {"frames": [2], "fps": 1.0, "row": row},
			}
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = SpriteUtil.make_frames(tex, 16, 16, anims)
	add_child(_sprite)
	_sprite.play("idle")

	if kind == "walker" or kind == "spiky":
		_edge_ray = RayCast2D.new()
		_edge_ray.target_position = Vector2(0, 14)
		_edge_ray.position = Vector2(dir * 8, 4)
		_edge_ray.collision_mask = 1
		_edge_ray.enabled = true
		add_child(_edge_ray)


func _physics_process(delta: float) -> void:
	if dead:
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	var dx: float = _player.global_position.x - global_position.x
	if absf(dx) > 340.0:
		return  # lejos de la pantalla: dormido (ahorra CPU en Android)
	_t += delta
	if frozen_t > 0.0:
		frozen_t -= delta
		velocity.x = 0.0
		if kind == "flyer":
			velocity.y = 0.0
		else:
			velocity.y = minf(velocity.y + GRAVITY * delta, 300.0)
		move_and_slide()
		if frozen_t <= 0.0:
			_sprite.modulate = Color.WHITE
		_check_player()
		return
	match kind:
		"walker", "spiky":
			_walk(delta, dx)
		"jumper":
			_jump(delta, dx)
		"flyer":
			_fly(delta)
		"shooter":
			_shooter(delta, dx)
	_check_player()


func _walk(delta: float, dx: float) -> void:
	var sp: float = _speed
	var moving: bool = true
	_turn_t = maxf(0.0, _turn_t - delta)
	var dy: float = _player.global_position.y - global_position.y
	if kind == "walker" and absf(dx) < 110.0 and absf(dy) < 28.0 and not _player.dead:
		# inteligencia básica: te persigue, pero no se tira por los bordes
		var want: int = 1 if dx > 0.0 else -1
		_edge_ray.position.x = want * 8
		_edge_ray.force_raycast_update()
		if _edge_ray.is_colliding():
			dir = want
			sp = _speed * 1.7
		else:
			moving = false
	velocity.x = dir * sp if moving else 0.0
	velocity.y = minf(velocity.y + GRAVITY * delta, 300.0)
	move_and_slide()
	if is_on_floor() and _turn_t <= 0.0:
		_edge_ray.position.x = dir * 8
		_edge_ray.force_raycast_update()
		if is_on_wall() or not _edge_ray.is_colliding():
			dir = -dir
			_turn_t = 0.35
	elif not is_on_floor() and is_on_wall() and _turn_t <= 0.0:
		dir = -dir
		_turn_t = 0.35
	_edge_ray.position.x = dir * 8
	_sprite.flip_h = dir > 0


func _jump(delta: float, dx: float) -> void:
	velocity.y = minf(velocity.y + GRAVITY * delta, 320.0)
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
		_sprite.play("idle")
		_hop_t -= delta
		if _hop_t <= 0.0:
			dir = (1 if dx > 0.0 else -1) if absf(dx) < 220.0 else dir
			velocity = Vector2(dir * 62.0, -235.0)
			_hop_t = randf_range(0.9, 1.6)
			_sprite.play("jump")
	move_and_slide()
	if is_on_wall():
		dir = -dir
		velocity.x = -velocity.x * 0.5
	_sprite.flip_h = dir > 0


func _fly(delta: float) -> void:
	var to_player: Vector2 = _player.global_position - global_position
	var target := Vector2.ZERO
	if to_player.length() < 120.0 and not _player.dead:
		target = to_player.normalized() * 50.0
		target.y += sin(_t * 6.0) * 18.0
	else:
		if absf(position.x - _home_x) > 70.0:
			dir = -1 if position.x > _home_x else 1
		target = Vector2(dir * 32.0, sin(_t * 3.0) * 26.0)
	velocity = velocity.lerp(target, minf(1.0, 4.0 * delta))
	move_and_slide()
	if is_on_wall():
		dir = -dir
	_sprite.flip_h = velocity.x > 0.0


func _shooter(delta: float, dx: float) -> void:
	velocity.x = 0.0
	velocity.y = minf(velocity.y + GRAVITY * delta, 300.0)
	move_and_slide()
	_sprite.flip_h = dx < 0.0
	_shoot_t -= delta
	var dy: float = _player.global_position.y - global_position.y
	if _shoot_t <= 0.0 and absf(dx) < 170.0 and absf(dy) < 90.0 and not _player.dead:
		_shoot_t = maxf(1.2, 2.4 - 0.15 * world)
		_fire(dx, dy)


func _fire(dx: float, dy: float) -> void:
	_sprite.play("fire")
	Audio.play_sfx("enemy_shoot")
	var p = ProjectileScene.instantiate()
	p.team = "enemy"
	p.kind = SHOT_KINDS[clampi(world, 1, 5) - 1]
	var aim := Vector2(dx, dy - 4.0).normalized()
	p.velocity = aim * 105.0
	p.life = 3.0
	p.position = position + Vector2(signf(dx) * 8.0, -2.0)
	get_parent().add_child(p)
	await get_tree().create_timer(0.3, false).timeout
	if not dead and is_instance_valid(_sprite):
		_sprite.play("idle")


func _check_player() -> void:
	if _player == null or _player.dead or dead:
		return
	for b in _hit.get_overlapping_bodies():
		if b != _player:
			continue
		if frozen_t > 0.0 or _player.is_attacking():
			kill()
			return
		var above: bool = _player.global_position.y + 8.0 < global_position.y + 4.0
		if stompable and _player.velocity.y > 20.0 and above:
			kill()
			_player.bounce()
			return
		_player.hurt(1, global_position.x)


func take_hit(shot: String) -> void:
	if dead:
		return
	if shot == "ice":
		frozen_t = 5.0
		_sprite.modulate = Color(0.6, 0.85, 1.0)
		Audio.play_sfx("freeze")
		return
	kill()


func kill() -> void:
	if dead:
		return
	dead = true
	set_deferred("collision_layer", 0)
	_hit.set_deferred("monitoring", false)
	Audio.play_sfx("stomp")
	Game.add_score(100)
	if level != null:
		level.popup("+100", global_position + Vector2(0, -8))
		level.spawn_burst(global_position, Color("#ffffff"), 6)
	_sprite.modulate = Color.WHITE
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_sprite, "scale", Vector2(1.3, 0.2), 0.12)
	tw.tween_property(_sprite, "modulate:a", 0.0, 0.25)
	tw.chain().tween_callback(queue_free)
