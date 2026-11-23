extends CharacterBody2D
## Wilmen, el joven aventurero: correr, saltar, doble salto y poder especial.

signal hp_changed(hp: int, max_hp: int)
signal died

const SpriteUtil := preload("res://characters/sprite_util.gd")
const ProjectileScene := preload("res://items/projectile.tscn")
const FireballScript := preload("res://items/fireball.gd")
const LongFireballScript := preload("res://items/fireball_long.gd")

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
const POWER_COOLDOWN := {"spark": 0.45, "dash": 1.0, "shield": 8.0, "freeze": 0.8, "fireball": 0.7,
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
# poderes temporales de la expansión (orbes y cofres): fuego, hielo, electricidad, escudo protector y gigante
var base_power: String = "spark"
var temp_power: String = ""
var temp_power_t: float = 0.0
var barrier: bool = false
var barrier_t: float = 0.0
var giant_t: float = 0.0
var giant_hit_used: bool = false  # el gigante daña al jefe una sola vez por transformación (no lo derrota de golpe)
var scale_mul: float = 1.0
var launch_lock: float = 0.0  # tras un impulso (seta, liana) se conserva la velocidad horizontal (WILMEN WORLD)
var env_current: float = 0.0  # corriente de agua horizontal (px/s) que arrastra al jugador (WILMEN WORLD)
var vehicle = null  # vehículo que está conduciendo (carrito, barco, plataforma voladora o mecha)

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
var _cam_x: float = 0.0
var _shape: CollisionShape2D
var _aura: CPUParticles2D = null
var _hat: Sprite2D = null
var _armor: Sprite2D = null
var _trail: CPUParticles2D = null
const CAM_Y := -14.0


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
	_shape = cs
	_build_sprite()
	power = Game.power_of_world(Game.world_of(Game.current_level))
	base_power = power
	skill_cd_max = float(POWER_COOLDOWN[power])
	_apply_cosmetics()


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
	launch_lock = maxf(0.0, launch_lock - delta)
	_tick_powers(delta)
	if vehicle != null:
		# conduciendo: el vehículo mueve al jugador; aquí solo se animan sus efectos
		velocity = Vector2.ZERO
		_update_visuals(0.0, true, delta)
		_update_cosmetics()
		return

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
	if env_current != 0.0:
		move_and_collide(Vector2(env_current * delta, 0.0))
	move_and_slide()
	_handle_collisions()
	_update_visuals(dir, on_floor, delta)
	_update_cosmetics()
	_juice(on_floor, delta)
	env_conveyor = 0.0
	env_current = 0.0
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
	if launch_lock > 0.0 and not on_floor and (dir == 0.0 or signf(dir) == signf(velocity.x)):
		return  # impulso en el aire: se conserva la velocidad horizontal
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
		elif (dash_t > 0.0 or giant_t > 0.0) and absf(col.get_normal().x) > 0.7 and other.has_method("smash"):
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
	if shield_t > 0.0 or dash_t > 0.0 or barrier:
		queue_redraw()
	if camera != null:
		# Anticipación y temblor se aplican a la POSICIÓN de la cámara (hija del jugador) y no a
		# Camera2D.offset: el offset se suma DESPUÉS de los límites y dejaba ver fuera del nivel.
		var target_x: float = facing * 26.0
		_cam_x = lerpf(_cam_x, target_x, minf(1.0, 3.0 * delta))
		_shake = maxf(0.0, _shake - 30.0 * delta)
		var shake_v := Vector2.ZERO
		if _shake > 0.0:
			shake_v = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
		camera.position = Vector2(_cam_x, CAM_Y) + shake_v


func _draw() -> void:
	if barrier:
		var pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 160.0)
		draw_circle(Vector2(0, -1), 14.0 * scale_mul, Color(1.0, 0.75, 0.25, 0.14 + 0.1 * pulse))
		draw_arc(Vector2(0, -1), 14.0 * scale_mul, 0.0, TAU, 28, Color(1.0, 0.9, 0.5, 0.55 + 0.3 * pulse), 1.2)
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
		"fireball":
			_long_fireball()
		"gust":
			_shoot("feather", Vector2(facing * 290.0, 0.0), 0.0, false, true)
			Audio.play_sfx("dash", 1.3)
			_fx(Color("#e8f4ff"), 7)
		"flame":
			for a in [-0.2, 0.0, 0.2]:
				_shoot("fire", Vector2(facing * 215.0, 0.0).rotated(a), 120.0, false)
			Audio.play_sfx("fire")
			_fx(Color("#ff7a1a"), 7)
		"leap":
			velocity.y = -400.0
			_air_jumps = 1
			_in_jump = false
			Audio.play_sfx("spring")
			_squash(Vector2(0.8, 1.3))
			_fx(Color("#5adf7a"), 10)
		"pulse":
			if temp_power == "pulse":
				_pulse()  # poder temporal «Electricidad»: sin cambios (rayos)
			else:
				_fireball_pulse()  # Pulso Eléctrico del Mundo 9: bolas de fuego
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


func _fireball_pulse() -> void:
	## Pulso Eléctrico del Mundo 9 (poder base): en vez de rayos, una bola de fuego por cada enemigo al alcance. Se mantiene
	## el radio de siempre alrededor del personaje (64 px, por cualquier lado) y, además, la bola llega a enemigos más
	## lejanos DELANTE del personaje hasta FireballScript.RANGE (192 px). Mismo daño que la descarga original.
	## Si no hay ninguno, sale una hacia delante hasta ese alcance.
	Audio.play_sfx("fire", 0.9)
	_fx(Color("#ff7a1a"), 6)
	var count: int = 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or bool(e.get("dead")):
			continue
		var d: float = e.global_position.distance_to(global_position)
		var in_front: bool = (e.global_position.x - global_position.x) * float(facing) > 0.0
		if d < 64.0 or (in_front and d < FireballScript.RANGE):
			_spawn_fireball(e)
			count += 1
	if count == 0:
		_spawn_fireball(null)


func _spawn_fireball(tgt) -> void:
	var f = FireballScript.new()
	f.target = tgt
	f.dir = Vector2(float(facing), 0.0)
	f.position = position + Vector2(facing * 12.0, -2.0)
	get_parent().add_child(f)


func _pulse() -> void:
	## Descarga eléctrica: daña a los enemigos (y al jefe) en un radio.
	Audio.play_sfx("thunder")
	for k in range(10):
		var ang: float = TAU * k / 10.0
		if level != null:
			level.spawn_burst(global_position + Vector2(cos(ang), sin(ang)) * 30.0, Color("#fff06a"), 3)
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.global_position.distance_to(global_position) < 64.0:
			_bolt(e.global_position)
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
	_sprite.scale = scl * scale_mul
	_squash_tw = create_tween()
	_squash_tw.tween_property(_sprite, "scale", Vector2.ONE * scale_mul, 0.14)


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


func _long_fireball() -> void:
	## Bola de fuego de largo alcance (~1.000 px) en horizontal hacia donde mira el personaje. No mueve al personaje.
	var f = LongFireballScript.new()
	f.dir = Vector2(float(facing), 0.0)
	f.position = position + Vector2(facing * 12.0, -2.0)
	get_parent().add_child(f)
	Audio.play_sfx("fire", 1.1)
	_fx(Color("#ff7a1a"), 6)
	_squash(Vector2(1.15, 0.9))


func is_attacking() -> bool:
	return dash_t > 0.0 or shield_t > 0.0 or giant_t > 0.0 or (vehicle != null and vehicle.kind == "mech")


# --------------------------------------------------------- daño y estado --
func hurt(dmg: int = 1, from_x: float = 0.0) -> bool:
	if dead or _invuln_t > 0.0 or shield_t > 0.0 or dash_t > 0.0:
		return false
	if not controllable:
		return false
	if vehicle != null and vehicle.absorb_hit():
		_invuln_t = 0.8  # el mecha recibe el golpe por Wilmen
		return false
	if barrier:
		# Escudo protector: resiste UN golpe
		barrier = false
		barrier_t = 0.0
		_invuln_t = 1.0
		Audio.play_sfx("barrier_break")
		add_shake(2.0)
		if level != null:
			level.spawn_burst(global_position, Color("#ffd070"), 12)
		_refresh_aura()
		queue_redraw()
		return false
	if level != null:
		level.hit_taken = true
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
	if vehicle != null:
		vehicle.release_rider()
		vehicle = null
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
	# los poderes temporales se pierden al caer
	temp_power = ""
	temp_power_t = 0.0
	power = base_power
	skill_cd_max = float(POWER_COOLDOWN[power])
	barrier = false
	if giant_t > 0.0 or scale_mul != 1.0:
		giant_t = 0.0
		_set_scale(1.0)
	_refresh_aura()
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


func launch_vec(v: Vector2) -> void:
	## Setas lanzadoras de WILMEN WORLD: impulso con trayectoria (vertical o en diagonal).
	velocity = v
	launch_lock = 1.2 if absf(v.x) > 1.0 else 0.0
	_air_jumps = 1
	_in_jump = false


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


# ------------------------------------------- poderes temporales (expansión) -
func grant_power(kind: String) -> void:
	## Fuego, hielo y electricidad sustituyen al poder del botón durante un rato; el escudo protector resiste un golpe;
	## la transformación gigante aumenta tamaño y fuerza. Se consiguen jugando (orbes y cofres), sin compras.
	Progress.stats["powerups"] = int(Progress.stats["powerups"]) + 1
	Progress.check_achievements()
	Audio.play_sfx("powerup")
	match kind:
		"barrier":
			barrier = true
			barrier_t = 45.0
			_fx(Color("#ffb030"), 10)
		"giant":
			giant_t = 12.0
			giant_hit_used = false
			Audio.play_sfx("giant")
			_set_scale(1.5)
			_fx(Color("#5adf7a"), 14)
			if level != null:
				level.shake(5.0)
		_:
			temp_power = kind
			temp_power_t = 25.0
			power = kind
			skill_cd_max = float(POWER_COOLDOWN.get(kind, 0.8))
			skill_cd = 0.0
			_fx(Color("#ffffff"), 10)
	_refresh_aura()
	queue_redraw()


func is_giant() -> bool:
	return giant_t > 0.0


func power_timer() -> float:
	## Segundos que quedan del poder temporal activo (0 = ninguno) y su nombre, para la interfaz.
	return maxf(temp_power_t, maxf(giant_t, barrier_t if barrier else 0.0))


func power_label() -> String:
	if giant_t > 0.0:
		return "Gigante"
	if temp_power != "":
		return str(Progress.POWERUPS.get(temp_power, temp_power))
	if barrier:
		return "Escudo protector"
	return ""


func _tick_powers(delta: float) -> void:
	if temp_power_t > 0.0:
		temp_power_t -= delta
		if temp_power_t <= 0.0:
			temp_power = ""
			power = base_power
			skill_cd_max = float(POWER_COOLDOWN[power])
			_refresh_aura()
	if giant_t > 0.0:
		giant_t -= delta
		if giant_t <= 0.0:
			_set_scale(1.0)
			_refresh_aura()
	if barrier and barrier_t > 0.0:
		barrier_t -= delta
		if barrier_t <= 0.0:
			barrier = false
			_refresh_aura()
	if giant_t > 0.0 and is_on_floor() and last_vy > 200.0:
		Audio.play_sfx("giant_stomp")
		add_shake(4.0)
		if level != null:
			level.spawn_burst(global_position + Vector2(0, 14), Color(1, 1, 1, 0.9), 8)


func _set_scale(mul: float) -> void:
	scale_mul = mul
	if _shape != null:
		var cap := _shape.shape as CapsuleShape2D
		cap.radius = 5.5 * mul
		cap.height = 20.0 * mul
	if mul > 1.0:
		position.y -= 5.0  # evita hundirse en el suelo al crecer
	_sprite.scale = Vector2.ONE * mul


func _refresh_aura() -> void:
	var col: Color = Color(0, 0, 0, 0)
	if giant_t > 0.0:
		col = Color("#7aff9a")
	elif temp_power == "flame":
		col = Color("#ff8a2a")
	elif temp_power == "freeze":
		col = Color("#8fe0ff")
	elif temp_power == "pulse":
		col = Color("#fff06a")
	elif barrier:
		col = Color("#ffcf70")
	if col.a == 0.0:
		if _aura != null:
			_aura.emitting = false
		return
	if _aura == null:
		_aura = CPUParticles2D.new()
		_aura.amount = 10
		_aura.lifetime = 0.7
		_aura.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		_aura.emission_rect_extents = Vector2(7, 10)
		_aura.direction = Vector2(0, -1)
		_aura.spread = 25.0
		_aura.initial_velocity_min = 8.0
		_aura.initial_velocity_max = 22.0
		_aura.gravity = Vector2.ZERO
		_aura.scale_amount_min = 1.0
		_aura.scale_amount_max = 2.2
		_aura.z_index = -1
		add_child(_aura)
	_aura.color = col
	_aura.emission_rect_extents = Vector2(7, 10) * scale_mul
	_aura.emitting = true


func _bolt(target: Vector2) -> void:
	## Relámpago visual entre el jugador y un enemigo alcanzado por la descarga eléctrica.
	if level == null:
		return
	var ln := Line2D.new()
	ln.width = 1.6
	ln.default_color = Color("#fff8a0")
	var a: Vector2 = global_position
	var seg: int = 5
	for i in range(seg + 1):
		var t: float = float(i) / float(seg)
		var p: Vector2 = a.lerp(target, t)
		if i > 0 and i < seg:
			p += Vector2(randf_range(-5, 5), randf_range(-5, 5))
		ln.add_point(p)
	ln.z_index = 8
	level.add_child(ln)
	var tw := ln.create_tween()
	tw.tween_property(ln, "modulate:a", 0.0, 0.22)
	tw.tween_callback(ln.queue_free)


# ----------------------------------------------- personalización (trajes...) -
const HAT_ORDER := ["gorra", "corona", "mago", "explorador", "orejas", "lazo", "halo", "antena", "minero", "flor"]
const ARMOR_ORDER := ["bronce", "plata", "oro", "cristal", "obsidiana"]
const SUITS := {
	"classic": [0.0, 1.0, 1.0], "esmeralda": [0.0, 1.35, 1.2], "fuego": [-0.30, 1.3, 1.15], "hielo": [0.18, 1.0, 1.25],
	"sombra": [0.0, 0.25, 0.45], "dorado": [-0.22, 1.1, 1.4], "cristal": [0.34, 1.0, 1.25], "jungla": [0.02, 0.9, 0.7],
}
const HAT_Y := -14.0
const ARMOR_Y := 0.0


func _apply_cosmetics() -> void:
	## Traje (tinte de la camiseta), sombrero, armadura y efecto de partículas elegidos en el vestuario.
	var suit: String = Progress.effective("suit")
	if suit != "" and suit != "classic" and SUITS.has(suit):
		var mat := ShaderMaterial.new()
		mat.shader = load("res://assets/player/suit.gdshader")
		var v: Array = SUITS[suit]
		mat.set_shader_parameter("hue_shift", v[0])
		mat.set_shader_parameter("sat_mul", v[1])
		mat.set_shader_parameter("val_mul", v[2])
		_sprite.material = mat
	var hat: String = Progress.effective("hat")
	if hat != "" and HAT_ORDER.has(hat):
		_hat = _cosmetic_sprite("res://assets/player/hats.png", HAT_ORDER.find(hat))
	var armor: String = Progress.effective("armor")
	if armor != "" and ARMOR_ORDER.has(armor):
		_armor = _cosmetic_sprite("res://assets/player/armors.png", ARMOR_ORDER.find(armor))
	var trail: String = Progress.effective("trail")
	if trail != "":
		_make_trail(trail)


func _cosmetic_sprite(path: String, index: int) -> Sprite2D:
	var sp := Sprite2D.new()
	var at := AtlasTexture.new()
	at.atlas = load(path)
	at.region = Rect2(index * 16, 0, 16, 16)
	sp.texture = at
	sp.z_index = 1
	add_child(sp)
	return sp


func _make_trail(kind: String) -> void:
	_trail = CPUParticles2D.new()
	_trail.amount = 8
	_trail.lifetime = 0.55
	_trail.local_coords = false
	_trail.direction = Vector2(0, -1)
	_trail.spread = 40.0
	_trail.initial_velocity_min = 4.0
	_trail.initial_velocity_max = 16.0
	_trail.gravity = Vector2.ZERO
	_trail.scale_amount_min = 1.2
	_trail.scale_amount_max = 2.6
	_trail.position = Vector2(0, 6)
	_trail.z_index = -1
	match kind:
		"chispas":
			_trail.color = Color("#ffe05a")
		"llamas":
			_trail.color = Color("#ff7a1a")
			_trail.gravity = Vector2(0, -30)
		"nieve":
			_trail.color = Color("#ffffff")
			_trail.gravity = Vector2(0, 30)
		"corazones":
			_trail.color = Color("#ff6a9a")
			_trail.gravity = Vector2(0, -20)
		"estrellas":
			_trail.color = Color("#fff08a")
		"burbujas":
			_trail.color = Color(0.7, 0.9, 1.0, 0.8)
			_trail.gravity = Vector2(0, -25)
	_trail.emitting = false
	add_child(_trail)


func _update_cosmetics() -> void:
	var f: float = -1.0 if _sprite.flip_h else 1.0
	if _hat != null:
		_hat.visible = _sprite.visible
		_hat.flip_h = _sprite.flip_h
		_hat.scale = Vector2.ONE * scale_mul
		_hat.position = Vector2(f * 0.5, HAT_Y * scale_mul)
	if _armor != null:
		_armor.visible = _sprite.visible
		_armor.flip_h = _sprite.flip_h
		_armor.scale = Vector2.ONE * scale_mul
		_armor.position = Vector2(0, ARMOR_Y * scale_mul)
	if _trail != null:
		_trail.emitting = absf(velocity.x) > 40.0 or not is_on_floor()
