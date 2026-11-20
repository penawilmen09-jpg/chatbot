extends CharacterBody2D
## Wilmen, el joven aventurero: correr, saltar, doble salto y poder especial.

signal hp_changed(hp: int, max_hp: int)
signal died

const SpriteUtil := preload("res://characters/sprite_util.gd")
const ProjectileScene := preload("res://items/projectile.tscn")

const RUN_SPEED := 125.0
const ACCEL := 950.0
const AIR_ACCEL := 650.0
const FRICTION := 1000.0
const ICE_ACCEL := 260.0
const ICE_FRICTION := 120.0
const GRAVITY := 900.0
const MAX_FALL := 340.0
const JUMP_V := -310.0
const DOUBLE_JUMP_V := -285.0
const COYOTE := 0.10
const JUMP_BUFFER := 0.12
const DASH_SPEED := 300.0
const MAX_HP := 3
const POWER_COOLDOWN := {"spark": 0.45, "dash": 1.0, "shield": 8.0, "freeze": 0.8, "blink": 1.0}

var level = null  # el nivel que contiene al jugador (duck typing)
var camera: Camera2D = null
var hp: int = MAX_HP
var max_hp: int = MAX_HP
var facing: int = 1
var power: String = "spark"
var dead: bool = false
var controllable: bool = true
var last_vy: float = 0.0  # velocidad vertical antes de mover (la usan los bloques ocultos)

var skill_cd: float = 0.0
var skill_cd_max: float = 0.5
var shield_t: float = 0.0
var dash_t: float = 0.0

var _coyote_t: float = 0.0
var _buffer_t: float = 0.0
var _air_jumps: int = 1
var _in_jump: bool = false
var _invuln_t: float = 0.0
var _hurt_t: float = 0.0
var _cast_t: float = 0.0
var _shake: float = 0.0
var _sprite: AnimatedSprite2D


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 5.0
	platform_on_leave = CharacterBody2D.PLATFORM_ON_LEAVE_ADD_VELOCITY
	var cs := CollisionShape2D.new()
	var cap := CapsuleShape2D.new()
	cap.radius = 5.5
	cap.height = 20.0
	cs.shape = cap
	add_child(cs)
	_build_sprite()
	power = Game.power_of_world(Game.world_of(Game.current_level))
	skill_cd_max = float(POWER_COOLDOWN[power])


func _build_sprite() -> void:
	var tex: Texture2D = load("res://assets/player/wilmen.png")
	var frames := SpriteUtil.make_frames(tex, 24, 24, {
		"idle": {"frames": [0, 1], "fps": 2.5},
		"run": {"frames": [2, 3, 4, 5, 6, 7], "fps": 13.0},
		"jump": {"frames": [8], "fps": 1.0},
		"fall": {"frames": [9], "fps": 1.0},
		"hurt": {"frames": [10], "fps": 1.0},
		"dash": {"frames": [11], "fps": 1.0},
		"cast": {"frames": [12], "fps": 1.0},
	})
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_sprite.position = Vector2(0, -2)
	add_child(_sprite)
	_sprite.play("idle")


func _physics_process(delta: float) -> void:
	if dead:
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL * 1.3)
		move_and_slide()
		return

	_invuln_t = maxf(0.0, _invuln_t - delta)
	_hurt_t = maxf(0.0, _hurt_t - delta)
	_cast_t = maxf(0.0, _cast_t - delta)
	_buffer_t = maxf(0.0, _buffer_t - delta)
	skill_cd = maxf(0.0, skill_cd - delta)
	shield_t = maxf(0.0, shield_t - delta)
	dash_t = maxf(0.0, dash_t - delta)

	var dir: float = 0.0
	var jump_pressed: bool = false
	var jump_held: bool = false
	if controllable and _hurt_t <= 0.0:
		dir = Input.get_axis("move_left", "move_right")
		jump_pressed = Input.is_action_just_pressed("jump")
		jump_held = Input.is_action_pressed("jump")
		if Input.is_action_just_pressed("skill"):
			_use_skill()
	if jump_pressed:
		_buffer_t = JUMP_BUFFER

	var on_floor: bool = is_on_floor()
	if on_floor:
		_coyote_t = COYOTE
		_air_jumps = 1
		_in_jump = false
	else:
		_coyote_t = maxf(0.0, _coyote_t - delta)

	if dash_t > 0.0:
		velocity.x = facing * DASH_SPEED
		velocity.y = 0.0
	else:
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
		_move_horizontal(dir, on_floor, delta)
		# salto normal (con coyote time y buffer) y doble salto
		if _buffer_t > 0.0 and _coyote_t > 0.0:
			velocity.y = JUMP_V
			_buffer_t = 0.0
			_coyote_t = 0.0
			_in_jump = true
			Audio.play_sfx("jump")
		elif jump_pressed and not on_floor and _air_jumps > 0:
			velocity.y = DOUBLE_JUMP_V
			_air_jumps -= 1
			_in_jump = true
			Audio.play_sfx("double_jump")
			if level != null:
				level.spawn_burst(global_position + Vector2(0, 10), Color("#ffffff"), 5)
		# altura de salto variable: soltar el botón corta el salto
		if _in_jump and not jump_held and velocity.y < -140.0:
			velocity.y = -140.0

	last_vy = velocity.y
	move_and_slide()
	_handle_collisions()
	_update_visuals(dir, on_floor, delta)


func _move_horizontal(dir: float, on_floor: bool, delta: float) -> void:
	var accel: float = ACCEL if on_floor else AIR_ACCEL
	var fric: float = FRICTION if on_floor else AIR_ACCEL * 0.5
	if level != null and level.slippery and on_floor:
		accel = ICE_ACCEL
		fric = ICE_FRICTION
	if _hurt_t > 0.0:
		return
	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * RUN_SPEED, accel * delta)
		facing = 1 if dir > 0.0 else -1
	else:
		velocity.x = move_toward(velocity.x, 0.0, fric * delta)


func _handle_collisions() -> void:
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		var other = col.get_collider()
		if other == null:
			continue
		if col.get_normal().y > 0.7 and other.has_method("bump"):
			other.bump(self)
		elif dash_t > 0.0 and absf(col.get_normal().x) > 0.7 and other.has_method("smash"):
			other.smash()


func _update_visuals(dir: float, on_floor: bool, delta: float) -> void:
	var anim: String = "idle"
	if _hurt_t > 0.0:
		anim = "hurt"
	elif dash_t > 0.0:
		anim = "dash"
	elif _cast_t > 0.0:
		anim = "cast"
	elif not on_floor:
		anim = "jump" if velocity.y < 0.0 else "fall"
	elif absf(velocity.x) > 12.0:
		anim = "run"
	if _sprite.animation != anim:
		_sprite.play(anim)
	_sprite.flip_h = facing < 0
	if _invuln_t > 0.0 and shield_t <= 0.0:
		_sprite.visible = int(_invuln_t * 20.0) % 2 == 0
	else:
		_sprite.visible = true
	if shield_t > 0.0 or dash_t > 0.0:
		queue_redraw()
	if camera != null:
		var target_x: float = facing * 26.0
		var cur: Vector2 = camera.offset
		cur.x = lerpf(cur.x, target_x, minf(1.0, 3.0 * delta))
		_shake = maxf(0.0, _shake - 30.0 * delta)
		if _shake > 0.0:
			camera.offset = cur + Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
		else:
			camera.offset = Vector2(cur.x, 0.0)


func _draw() -> void:
	if shield_t > 0.0:
		var a: float = 0.35 if shield_t > 1.0 else 0.2 + 0.15 * sin(shield_t * 30.0)
		draw_circle(Vector2(0, -1), 15.0, Color(1.0, 0.8, 0.3, a))
		draw_arc(Vector2(0, -1), 15.0, 0.0, TAU, 32, Color(1.0, 0.95, 0.6, 0.9), 1.5)


# ---------------------------------------------------------------- poderes -
func _use_skill() -> void:
	if skill_cd > 0.0 or dead:
		return
	skill_cd = skill_cd_max
	_cast_t = 0.16
	match power:
		"spark":
			_shoot("spark", 230.0, 380.0, true)
			Audio.play_sfx("spark")
		"dash":
			dash_t = 0.22
			_invuln_t = maxf(_invuln_t, 0.3)
			Audio.play_sfx("dash")
		"shield":
			shield_t = 4.0
			Audio.play_sfx("shield")
		"freeze":
			_shoot("ice", 200.0, 0.0, false)
			Audio.play_sfx("freeze")
		"blink":
			_blink()
			Audio.play_sfx("blink")


func _shoot(kind: String, speed: float, grav: float, bouncy: bool) -> void:
	var p = ProjectileScene.instantiate()
	p.team = "player"
	p.kind = kind
	p.velocity = Vector2(facing * speed, -30.0 if bouncy else 0.0)
	p.fall_accel = grav
	p.bounce = bouncy
	p.life = 1.8
	p.position = position + Vector2(facing * 12.0, -2.0)
	get_parent().add_child(p)


func _blink() -> void:
	var step := Vector2(facing * 4.0, 0.0)
	var t: Transform2D = global_transform
	var moved: float = 0.0
	while moved < 64.0:
		if test_move(t, step):
			break
		t.origin += step
		moved += 4.0
	if level != null:
		level.spawn_burst(global_position, Color("#b080ff"), 8)
	global_position = t.origin
	_invuln_t = maxf(_invuln_t, 0.45)
	if camera != null:
		camera.reset_smoothing()
	if level != null:
		level.spawn_burst(global_position, Color("#ffe05a"), 8)


func is_attacking() -> bool:
	return dash_t > 0.0 or shield_t > 0.0


# --------------------------------------------------------- daño y estado --
func hurt(dmg: int = 1, from_x: float = 0.0) -> bool:
	if dead or _invuln_t > 0.0 or shield_t > 0.0 or dash_t > 0.0:
		return false
	if not controllable:
		return false
	hp = maxi(0, hp - dmg)
	hp_changed.emit(hp, MAX_HP)
	if hp <= 0:
		die()
		return true
	_invuln_t = 1.6
	_hurt_t = 0.3
	var side: float = signf(position.x - from_x)
	if side == 0.0:
		side = -float(facing)
	velocity = Vector2(side * 150.0, -190.0)
	Audio.play_sfx("hurt")
	add_shake(3.0)
	return true


func hazard_hit(kind: String) -> void:
	if dead:
		return
	if kind == "lava":
		hurt(1, position.x)
		if not dead and shield_t <= 0.0:
			velocity = Vector2(velocity.x * 0.3, -330.0)
	else:
		hurt(1, position.x - facing * 8.0)


func die() -> void:
	if dead:
		return
	dead = true
	hp = 0
	hp_changed.emit(hp, MAX_HP)
	Audio.play_sfx("die")
	velocity = Vector2(0.0, -260.0)
	collision_layer = 0
	collision_mask = 0
	_sprite.visible = true
	_sprite.play("hurt")
	died.emit()


func respawn(pos: Vector2) -> void:
	dead = false
	controllable = true
	hp = MAX_HP
	position = pos
	velocity = Vector2.ZERO
	collision_layer = 2
	collision_mask = 1
	_invuln_t = 2.0
	_hurt_t = 0.0
	shield_t = 0.0
	dash_t = 0.0
	skill_cd = 0.0
	_sprite.visible = true
	hp_changed.emit(hp, MAX_HP)
	if camera != null:
		camera.reset_smoothing()


func heal(amount: int = 1) -> void:
	hp = mini(MAX_HP, hp + amount)
	hp_changed.emit(hp, MAX_HP)


func bounce(strong: bool = false) -> void:
	var v: float = -330.0 if (Input.is_action_pressed("jump") or strong) else -230.0
	velocity.y = v
	_air_jumps = 1
	_in_jump = false
	_buffer_t = 0.0


func launch(v: float) -> void:
	## Resortes: impulso vertical fuerte.
	velocity.y = v
	_air_jumps = 1
	_in_jump = false


func add_shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func celebrate() -> void:
	controllable = false
	_invuln_t = 99.0
