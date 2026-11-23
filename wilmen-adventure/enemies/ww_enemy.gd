extends CharacterBody2D
## Enemigos de WILMEN WORLD con comportamientos propios (no son variantes de aspecto de los de WILMEN ADVENTURE):
##  - mole   (z) TOPO: invisible bajo un montículo; si te acercas tiembla (aviso), sale, se queda un momento y se esconde.
##  - guard  (D) GUARDIÁN: escudo al frente. Si te ve de frente carga contra ti; al chocar queda aturdido y SOLO entonces se
##               le puede pisar o disparar. Sobre su cabeza rebotas sin hacerte daño. Protege habitaciones secretas.
##  - bat    (Y) MURCIÉLAGO: colgado del techo; si pasas debajo bate las alas (aviso), se lanza en picado y vuelve a su sitio.
##  - lobber (0) LANZARROCAS: estático; calcula una parábola y te lanza rocas por encima de los obstáculos.
## Misma interfaz que el enemigo básico (grupo "enemies", dead, take_hit, kill) para que el jugador, la bola de fuego y el
## pulso eléctrico los traten igual.

const TEX := preload("res://assets/enemies/ww_enemies.png")
const GRAVITY := 900.0
const ROWS := {"mole": 0, "guard": 1, "bat": 2, "lobber": 3}

@export var kind: String = "mole"
var level = null
var world: int = 1
var dead: bool = false
var frozen_t: float = 0.0
var stompable: bool = true
var dir: int = -1
var state: String = "idle"

var _player = null
var _sprite: Sprite2D
var _hit: Area2D
var _body_cs: CollisionShape2D
var _hit_cs: CollisionShape2D
var _edge_ray: RayCast2D
var _t: float = 0.0
var _st: float = 0.0
var _home := Vector2.ZERO
var _cool: float = 0.0
var _start_x: float = 0.0
var _rock_t: float = 1.0


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	_home = position
	_body_cs = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(12, 12)
	_body_cs.shape = r
	_body_cs.position = Vector2(0, 2)
	add_child(_body_cs)
	_hit = Area2D.new()
	_hit.collision_layer = 0
	_hit.collision_mask = 2
	_hit_cs = CollisionShape2D.new()
	var r2 := RectangleShape2D.new()
	r2.size = Vector2(14, 14)
	_hit_cs.shape = r2
	_hit_cs.position = Vector2(0, 1)
	_hit.add_child(_hit_cs)
	add_child(_hit)
	_sprite = Sprite2D.new()
	add_child(_sprite)
	if kind == "bat":
		motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
		state = "hang"
	elif kind == "mole":
		state = "hidden"
		_set_active(false)
		remove_from_group("enemies")
	elif kind == "guard":
		stompable = false
		_edge_ray = RayCast2D.new()
		_edge_ray.target_position = Vector2(0, 14)
		_edge_ray.collision_mask = 1
		_edge_ray.enabled = true
		add_child(_edge_ray)
	dir = -1
	_frame(0)


func _frame(i: int) -> void:
	var at := AtlasTexture.new()
	at.atlas = TEX
	at.region = Rect2(i * 16, int(ROWS[kind]) * 16, 16, 16)
	_sprite.texture = at


func _set_active(on: bool) -> void:
	_hit.set_deferred("monitoring", on)
	_body_cs.set_deferred("disabled", not on)
	_sprite.visible = true


func _physics_process(delta: float) -> void:
	if dead:
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	if absf(_player.global_position.x - global_position.x) > 340.0:
		return  # lejos de la pantalla: dormido
	_t += delta
	_cool = maxf(0.0, _cool - delta)
	if frozen_t > 0.0:
		frozen_t -= delta
		if kind != "bat":
			velocity.x = 0.0
			velocity.y = minf(velocity.y + GRAVITY * delta, 300.0)
			move_and_slide()
		if frozen_t <= 0.0:
			_sprite.modulate = Color.WHITE
		_check_player()
		return
	match kind:
		"mole":
			_mole(delta)
		"guard":
			_guard(delta)
		"bat":
			_bat(delta)
		"lobber":
			_lobber(delta)
	_check_player()


# ------------------------------------------------------------------ topo ---
func _mole(delta: float) -> void:
	var dx: float = _player.global_position.x - global_position.x
	var dy: float = _player.global_position.y - global_position.y
	_st -= delta
	match state:
		"hidden":
			_frame(0)
			_sprite.position.x = 0.0
			if _cool <= 0.0 and absf(dx) < 56.0 and absf(dy) < 40.0 and not _player.dead:
				state = "warn"
				_st = 0.6
		"warn":
			_frame(1)
			_sprite.position.x = randf_range(-1.0, 1.0)
			if _st <= 0.0:
				state = "up"
				_st = 1.7
				_sprite.position.x = 0.0
				_frame(2)
				_set_active(true)
				add_to_group("enemies")
				Audio.play_sfx("stomp", 1.4)
		"up":
			if _st <= 0.0:
				state = "hidden"
				_cool = 1.6
				_set_active(false)
				remove_from_group("enemies")
				_frame(0)


# -------------------------------------------------------------- guardián ---
func _guard(delta: float) -> void:
	var dx: float = _player.global_position.x - global_position.x
	var dy: float = _player.global_position.y - global_position.y
	velocity.y = minf(velocity.y + GRAVITY * delta, 300.0)
	_st -= delta
	_sprite.flip_h = dir > 0
	match state:
		"idle":
			velocity.x = 0.0
			_frame(0)
			var front: bool = (dx > 0.0 and dir > 0) or (dx < 0.0 and dir < 0)
			if not front and absf(dx) < 40.0 and absf(dy) < 24.0:
				dir = 1 if dx > 0.0 else -1  # se gira si te colocas a su espalda muy cerca
			if front and absf(dx) < 110.0 and absf(dy) < 26.0 and _cool <= 0.0 and not _player.dead:
				state = "wind"
				_st = 0.55
		"wind":
			velocity.x = 0.0
			_frame(1)
			_sprite.position.x = randf_range(-0.8, 0.8)
			if _st <= 0.0:
				_sprite.position.x = 0.0
				state = "charge"
				_start_x = position.x
		"charge":
			velocity.x = dir * 150.0
			_edge_ray.position.x = dir * 9
			_edge_ray.force_raycast_update()
			if is_on_wall() or (is_on_floor() and not _edge_ray.is_colliding()) or absf(position.x - _start_x) > 96.0:
				velocity.x = 0.0
				state = "stun"
				_st = 1.7
				stompable = true
				Audio.play_sfx("bump")
		"stun":
			velocity.x = 0.0
			_frame(2)
			if _st <= 0.0:
				state = "return"
				stompable = false
		"return":
			_frame(0)
			var back: float = _home.x - position.x
			if absf(back) < 3.0:
				velocity.x = 0.0
				state = "idle"
				dir = -dir if randf() < 0.0 else dir
				_cool = 1.2
			else:
				dir = 1 if back > 0.0 else -1
				_edge_ray.position.x = dir * 9
				_edge_ray.force_raycast_update()
				velocity.x = dir * 34.0 if _edge_ray.is_colliding() else 0.0
				if is_on_wall():
					state = "idle"
					_cool = 1.2
	move_and_slide()


# ----------------------------------------------------------- murciélago ---
func _bat(delta: float) -> void:
	var to_p: Vector2 = _player.global_position - global_position
	_st -= delta
	match state:
		"hang":
			velocity = Vector2.ZERO
			_frame(0)
			if _cool <= 0.0 and absf(to_p.x) < 90.0 and to_p.y > 12.0 and to_p.y < 150.0 and not _player.dead:
				state = "warn"
				_st = 0.55
		"warn":
			velocity = Vector2.ZERO
			_frame(1 + int(_t * 14.0) % 2)
			if _st <= 0.0:
				state = "dive"
				_st = 1.3
				_start_x = position.y
				var tgt: Vector2 = _player.global_position + Vector2(0, -4)
				velocity = (tgt - global_position).normalized() * 175.0
				_frame(3)
				Audio.play_sfx("jump", 1.5)
		"dive":
			move_and_slide()
			_sprite.flip_h = velocity.x > 0.0
			if get_slide_collision_count() > 0 or _st <= 0.0 or absf(position.y - _start_x) > 170.0:
				state = "rise"
				_st = 3.0
		"rise":
			var back: Vector2 = _home - position
			if back.length() < 4.0:
				position = _home
				velocity = Vector2.ZERO
				state = "hang"
				_cool = 1.8
			else:
				velocity = velocity.lerp(back.normalized() * 70.0, minf(1.0, 5.0 * delta))
				_frame(1 + int(_t * 12.0) % 2)
				move_and_slide()


# -------------------------------------------------------------- lanzarrocas
func _lobber(delta: float) -> void:
	var dx: float = _player.global_position.x - global_position.x
	var dy: float = _player.global_position.y - global_position.y
	velocity.x = 0.0
	velocity.y = minf(velocity.y + GRAVITY * delta, 300.0)
	move_and_slide()
	_sprite.flip_h = dx > 0.0
	_rock_t -= delta
	if state == "idle":
		_frame(0)
		if _rock_t <= 0.0 and absf(dx) < 220.0 and absf(dx) > 28.0 and absf(dy) < 130.0 and not _player.dead:
			state = "wind"
			_st = 0.5
			_frame(1)
	elif state == "wind":
		_st -= delta
		if _st <= 0.0:
			_throw(dx, dy)
			state = "idle"
			_rock_t = 2.5
			_frame(2)
			await get_tree().create_timer(0.25, false).timeout
			if not dead and is_instance_valid(_sprite):
				_frame(0)


func _throw(dx: float, dy: float) -> void:
	Audio.play_sfx("enemy_shoot", 0.8)
	var rock := Rock.new()
	rock.level = level
	var t: float = clampf(absf(dx) / 110.0, 0.55, 1.35)
	var lead: float = _player.velocity.x * t * 0.4
	rock.velocity = Vector2((dx + lead) / t, (dy - 0.5 * Rock.G * t * t) / t)
	rock.position = position + Vector2(signf(dx) * 6.0, -8.0)
	get_parent().add_child(rock)


class Rock extends Area2D:
	const G := 520.0
	var velocity := Vector2.ZERO
	var level = null
	var _life: float = 4.0
	var _spr: Sprite2D

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 2
		z_index = 5
		var cs := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = 4.0
		cs.shape = c
		add_child(cs)
		_spr = Sprite2D.new()
		var at := AtlasTexture.new()
		at.atlas = TEX
		at.region = Rect2(0, 64, 16, 16)
		_spr.texture = at
		add_child(_spr)

	func _physics_process(delta: float) -> void:
		_life -= delta
		velocity.y += G * delta
		var step: Vector2 = velocity * delta
		var q := PhysicsRayQueryParameters2D.create(global_position, global_position + step, 1)
		if _life <= 0.0 or not get_world_2d().direct_space_state.intersect_ray(q).is_empty():
			queue_free()
			return
		position += step
		_spr.rotation += 9.0 * delta
		var p = get_tree().get_first_node_in_group("player")
		if p != null and not p.dead and overlaps_body(p):
			p.hurt(1, global_position.x)
			queue_free()


# --------------------------------------------------------------- contacto ---
func _check_player() -> void:
	if _player == null or _player.dead or dead or not _hit.monitoring:
		return
	for b in _hit.get_overlapping_bodies():
		if b != _player:
			continue
		if frozen_t > 0.0 or _player.is_attacking():
			if kind == "guard" and state != "stun" and frozen_t <= 0.0:
				return  # el escudo aguanta los golpes
			kill()
			return
		var above: bool = _player.global_position.y + 8.0 < global_position.y + 4.0
		if _player.velocity.y > 20.0 and above:
			if stompable or frozen_t > 0.0:
				kill()
				_player.bounce()
			elif kind == "guard":
				_player.bounce()  # sobre su cabeza rebotas sin daño
			else:
				_player.hurt(1, global_position.x)
			return
		if kind == "guard" and state == "stun":
			return  # aturdido: no hace daño
		_player.hurt(1, global_position.x)


func take_hit(shot: String) -> void:
	if dead:
		return
	if shot == "ice":
		frozen_t = 5.0
		_sprite.modulate = Color(0.6, 0.85, 1.0)
		Audio.play_sfx("freeze")
		return
	if kind == "guard" and state != "stun":
		Audio.play_sfx("shield", 0.8)  # el escudo detiene el disparo
		return
	if kind == "mole" and state != "up":
		return
	kill()


func kill() -> void:
	if dead:
		return
	dead = true
	Progress.stats["enemies"] = int(Progress.stats["enemies"]) + 1
	set_deferred("collision_layer", 0)
	_hit.set_deferred("monitoring", false)
	Audio.play_sfx("stomp")
	Game.add_score(150 if kind == "guard" else 100)
	if level != null:
		level.popup("+%d" % (150 if kind == "guard" else 100), global_position + Vector2(0, -8))
		level.spawn_burst(global_position, Color("#ffffff"), 6)
	_sprite.modulate = Color.WHITE
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_sprite, "scale", Vector2(1.3, 0.2), 0.12)
	tw.tween_property(_sprite, "modulate:a", 0.0, 0.25)
	tw.chain().tween_callback(queue_free)
