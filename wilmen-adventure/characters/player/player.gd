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
const POWER_COOLDOWN := {"spark": 0.45, "dash": 1.0, "shield": 8.0, "freeze": 0.8, "blink": 1.0,
	"gust": 0.6, "flame": 0.8, "leap": 1.0, "pulse": 1.3, "nova": 9.0}

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

# efectos del entorno: los fija el nivel en cada paso de física
var env_conveyor: float = 0.0
var env_slow: bool = false
var env_wind: bool = false

var _coyote_t: float = 0.0
var _buffer_t: float = 0.0
var _air_jumps: int = 1
var _in_jump: bool = false
var _invuln_t: float = 0.0
var _hurt_t: float = 0.0
var _cast_t: float = 0.0
var _shake: float = 0.0
var _sprite: AnimatedSprite2D
var _was_on_floor: bool = true
var _dust_t: float = 0.0
var _squash_tw: Tween = null


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
			_squash(Vector2(0.82, 1.22))
		elif jump_pressed and not on_floor and _air_jumps > 0:
			velocity.y = DOUBLE_JUMP_V
			_air_jumps -= 1
			_in_jump = true
			Audio.play_sfx("double_jump")
			_squash(Vector2(0.85, 1.18))
			if level != null:
				level.spawn_burst(global_position + Vector2(0, 10), Color("#ffffff"), 5)
		# altura de salto variable: soltar el botón corta el salto
		if _in_jump and not jump_held and velocity.y < -140.0:
			velocity.y = -140.0

	if env_wind:
		_in_jump = false
		velocity.y = maxf(velocity.y - 1500.0 * delta, -170.0)
	if on_floor and env_conveyor != 0.0:
		move_and_collide(Vector2(env_conveyor * delta, 0.0))
	last_vy = velocity.y
	move_and_slide()
	_handle_collisions()
	_update_visuals(dir, on_floor, delta)
	_juice(on_floor, delta)
	env_conveyor = 0.0
	env_slow = false
	env_wind = false


func _move_horizontal(dir: float, on_floor: bool, delta: float) -> void:
	var accel: float = ACCEL if on_floor else AIR_ACCEL
	var fric: float = FRICTION if on_floor else AIR_ACCEL * 0.5
	if level != null and level.slippery and on_floor:
		accel = ICE_ACCEL
		fric = ICE_FRICTION
	if _hurt_t > 0.0:
		return
	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * RUN_SPEED * (0.55 if env_slow else 1.0), accel * delta)
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
			_shoot("spark", Vector2(facing * 230.0, -30.0), 380.0, true)
			Audio.play_sfx("spark")
			_fx(Color("#ffd23a"), 5)
		"dash":
			dash_t = 0.22
			_invuln_t = maxf(_invuln_t, 0.3)
			Audio.play_sfx("dash")
			_fx(Color("#59e0f0"), 8)
		"shield":
			shield_t = 4.0
			Audio.play_sfx("shield")
			_fx(Color("#ffb030"), 8)
		"freeze":
			_shoot("ice", Vector2(facing * 200.0, 0.0), 0.0, false)
			Audio.play_sfx("freeze")
			_fx(Color("#8fe0ff"), 6)
		"blink":
			_blink()
			Audio.play_sfx("blink")
		"gust":
			_shoot("feather", Vector2(facing * 290.0, 0.0), 0.0, false, true)
			Audio.play_sfx("dash", 1.3)
			_fx(Color("#e8f4ff"), 7)
		"flame":
			for a in [-0.2, 0.0, 0.2]:
				_shoot("fire", Vector2(facing * 215.0, 0.0).rotated(a), 120.0, false)
			Audio.play_sfx("spark", 0.8)
			_fx(Color("#ff7a1a"), 7)
		"leap":
			velocity.y = -400.0
			_air_jumps = 1
			_in_jump = false
			Audio.play_sfx("spring")
			_squash(Vector2(0.8, 1.3))
			_fx(Color("#5adf7a"), 10)
		"pulse":
			_pulse()
		"nova":
			shield_t = 3.0
			Audio.play_sfx("shield", 0.8)
			for k in range(8):
				var ang: float = TAU * k / 8.0
				_shoot("spark", Vector2(cos(ang), sin(ang)) * 175.0, 0.0, false)
			_fx(Color("#c05aff"), 12)


func _shoot(kind: String, vel: Vector2, grav: float, bouncy: bool, pierce: bool = false) -> void:
	var p = ProjectileScene.instantiate()
	p.team = "player"
	p.kind = kind
	p.velocity = vel
	p.fall_accel = grav
	p.bounce = bouncy
	p.pierce = pierce
	p.life = 1.8 if not pierce else 1.2
	p.position = position + Vector2(facing * 12.0, -2.0)
	get_parent().add_child(p)


func _pulse() -> void:
	## Descarga eléctrica: daña a los enemigos (y al jefe) en un radio.
	Audio.play_sfx("boss_hit", 1.5)
	for k in range(10):
		var ang: float = TAU * k / 10.0
		if level != null:
			level.spawn_burst(global_position + Vector2(cos(ang), sin(ang)) * 30.0, Color("#fff06a"), 3)
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.global_position.distance_to(global_position) < 64.0:
			e.take_hit("spark")


func _fx(color: Color, n: int) -> void:
	if level != null:
		level.spawn_burst(global_position + Vector2(facing * 8.0, -2.0), color, n)


func _squash(scl: Vector2) -> void:
	## Efecto visual de estirar/aplastar el sprite; no afecta a la física.
	if _sprite == null:
		return
	if _squash_tw != null and _squash_tw.is_valid():
		_squash_tw.kill()
	_sprite.scale = scl
	_squash_tw = create_tween()
	_squash_tw.tween_property(_sprite, "scale", Vector2.ONE, 0.14)


func _juice(on_floor: bool, delta: float) -> void:
	if on_floor and not _was_on_floor and last_vy > 120.0:
		_squash(Vector2(1.2, 0.82))
		if level != null:
			level.spawn_burst(global_position + Vector2(0, 10), Color(1, 1, 1, 0.8), 3)
	_was_on_floor = on_floor
	if on_floor and absf(velocity.x) > 60.0:
		_dust_t -= delta
		if _dust_t <= 0.0:
			_dust_t = 0.16
			if level != null:
				level.spawn_burst(global_position + Vector2(-facing * 4.0, 10), Color(1, 1, 1, 0.6), 1)


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
