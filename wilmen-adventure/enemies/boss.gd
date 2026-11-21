extends CharacterBody2D
## Jefe de mundo. Un mismo script con 5 jefes distintos; cada uno combina ataques propios:
##  1 Rey Tronco        : embestida, salto aplastante con ondas, lluvia de bellotas
##  2 Golem de Cristal  : vuela y dispara cristales, aplasta desde arriba, lluvia de cristales
##  3 Rey Escarabajo    : embestida, se entierra y emerge bajo tus pies, lluvia de arena
##  4 Yeti Gélido       : aplastamiento con ondas, bolas de nieve, embestida, avalancha
##  5 Señor de las Sombras: se teletransporta y dispara en anillo, aplasta, embiste, lluvia de orbes
## Fase 2 (mitad de vida): todo va más rápido. Se le daña pisándolo (salvo cuando está protegido).

signal hp_changed(hp: int, max_hp: int)
signal defeated

const SpriteUtil := preload("res://characters/sprite_util.gd")
const ProjectileScene := preload("res://items/projectile.tscn")
const GRAVITY := 900.0

const CONFIG := {
	1: {"hp": 5, "patterns": ["charge", "slam", "rain"], "rain": "acorn", "shot": "acorn"},
	2: {"hp": 6, "patterns": ["hover", "slam", "rain"], "rain": "shard", "shot": "shard"},
	3: {"hp": 7, "patterns": ["charge", "burrow", "rain"], "rain": "sand", "shot": "sand"},
	4: {"hp": 8, "patterns": ["slam", "snow", "charge", "rain"], "rain": "snowball", "shot": "snowball"},
	5: {"hp": 10, "patterns": ["teleport", "slam", "rain", "charge"], "rain": "orb", "shot": "orb"},
	6: {"hp": 11, "patterns": ["hover", "barrage", "slam", "rain"], "rain": "feather", "shot": "feather"},
	7: {"hp": 12, "patterns": ["slam", "fan", "charge", "rain"], "rain": "fire", "shot": "fire"},
	8: {"hp": 13, "patterns": ["charge", "slam", "snow", "fan"], "rain": "thorn", "shot": "thorn"},
	9: {"hp": 14, "patterns": ["barrage", "hover", "charge", "rain"], "rain": "bolt", "shot": "gear"},
	10: {"hp": 16, "patterns": ["teleport", "fan", "slam", "barrage", "rain", "charge"], "rain": "void", "shot": "void"},
}

@export var world: int = 1
var level = null
var hp: int = 5
var max_hp: int = 5
var active: bool = false
var dead: bool = false
var mode: String = "idle"
var shielded: bool = false
var speed_mult: float = 1.0

var arena_left: float = 0.0
var arena_right: float = 0.0
var arena_top: float = 0.0

var _player = null
var _sprite: AnimatedSprite2D
var _hit: Area2D
var _home: Vector2
var _invuln_t: float = 0.0
var _stomp_grace_t: float = 0.0  # tras un pisotón, el contacto que queda no hace daño al jugador
var _deflect_t: float = 0.0  # evita repetir el sonido/efecto de impacto rechazado cada fotograma
var _charge_dir: int = 1
var _hover_target: Vector2 = Vector2.ZERO
var _gen: int = 0


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	_home = position
	max_hp = int(CONFIG[world]["hp"])
	hp = max_hp
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(40, 48)
	cs.shape = rs
	cs.position = Vector2(0, 8)
	add_child(cs)
	_hit = Area2D.new()
	_hit.collision_layer = 0
	_hit.collision_mask = 2
	var hs := CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = Vector2(46, 50)
	hs.shape = hr
	hs.position = Vector2(0, 7)
	_hit.add_child(hs)
	add_child(_hit)
	var tex: Texture2D = load("res://assets/bosses/boss_%d.png" % world)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = SpriteUtil.make_frames(tex, 64, 64, {"idle": {"frames": [0, 1], "fps": 3.0}})
	add_child(_sprite)
	_sprite.play("idle")
	# animación de respiración / flotación del jefe
	var bob := create_tween().set_loops()
	bob.tween_property(_sprite, "position:y", -2.0, 0.7).set_trans(Tween.TRANS_SINE)
	bob.tween_property(_sprite, "position:y", 1.0, 0.7).set_trans(Tween.TRANS_SINE)


# ------------------------------------------------------------- control ----
func activate(left: float, right: float, top: float) -> void:
	if active or dead:
		return
	arena_left = left
	arena_right = right
	arena_top = top
	active = true
	_gen += 1
	hp_changed.emit(hp, max_hp)
	Audio.play_sfx("boss_roar")
	_run_ai(_gen)


func reset_fight() -> void:
	## Si el jugador pierde una vida, el jefe vuelve a empezar.
	if dead:
		return
	_gen += 1
	active = false
	mode = "idle"
	shielded = false
	speed_mult = 1.0
	hp = max_hp
	position = _home
	velocity = Vector2.ZERO
	collision_layer = 4
	_hit.monitoring = true
	_sprite.modulate = Color.WHITE
	_sprite.visible = true
	_sprite.position = Vector2.ZERO
	hp_changed.emit(hp, max_hp)


func _alive(g: int) -> bool:
	return active and not dead and g == _gen


func _wait(sec: float, _g: int) -> void:
	await get_tree().create_timer(sec / speed_mult, false).timeout


func _get_player():
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	return _player


func _floor_y() -> float:
	return _home.y + 32.0


# ---------------------------------------------------------------- física --
func _physics_process(delta: float) -> void:
	if dead:
		return
	_invuln_t = maxf(0.0, _invuln_t - delta)
	_stomp_grace_t = maxf(0.0, _stomp_grace_t - delta)
	_deflect_t = maxf(0.0, _deflect_t - delta)
	_sprite.visible = true if _invuln_t <= 0.0 or mode == "vanish" else int(_invuln_t * 18.0) % 2 == 0
	var grav: bool = true
	match mode:
		"charge":
			velocity.x = _charge_dir * 165.0 * speed_mult
		"hover":
			grav = false
			velocity = (_hover_target - position) * 3.0
			velocity = velocity.limit_length(150.0)
		"float", "vanish", "burrow":
			grav = false
			velocity = Vector2.ZERO
		"air":
			pass
		"drop":
			velocity.x = 0.0
			velocity.y = 430.0
			grav = false
		_:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	if grav:
		velocity.y = minf(velocity.y + GRAVITY * delta, 400.0)
	move_and_slide()
	if active:
		position.x = clampf(position.x, arena_left + 28.0, arena_right - 28.0)
	_sprite.position.x = randf_range(-1.5, 1.5) if mode == "telegraph" else 0.0
	var p = _get_player()
	if p != null:
		_sprite.flip_h = p.global_position.x > global_position.x
	if active:
		_check_player()


func _check_player() -> void:
	var p = _get_player()
	if p == null or p.dead or mode == "burrow" or mode == "vanish":
		return
	for b in _hit.get_overlapping_bodies():
		if b != p:
			continue
		var above: bool = p.global_position.y + 8.0 < global_position.y + 6.0
		if p.is_attacking():
			hit_boss(1)
		elif not shielded and p.velocity.y > 20.0 and above:
			# Pisotón desde arriba: cuenta como UN golpe al jefe, el jugador rebota y no recibe daño por este impacto.
			# (Antes el rebote dejaba al jugador solapado con el jefe sin caer: al fotograma siguiente contaba como
			# contacto lateral y le quitaba un corazón.) Si el jefe aún es invulnerable, rebota igualmente sin dañarlo.
			if _invuln_t <= 0.0:
				hit_boss(1)
			else:
				_deflect()
			p.bounce(true)
			_stomp_grace_t = 0.5
		elif _stomp_grace_t > 0.0:
			pass  # acaba de rebotar: sigue saliendo del cuerpo del jefe
		elif mode != "stun":
			p.hurt(1, global_position.x)


func take_hit(_shot: String) -> void:
	## Proyectiles y poderes del jugador: se registran siempre (daño si es vulnerable; si no, rebotan con efecto).
	if dead or not active:
		return
	hit_boss(1)


func _deflect() -> void:
	## El impacto se registra pero no hace daño (escudo activo o jefe aún invulnerable tras el golpe anterior).
	if _deflect_t > 0.0:
		return
	_deflect_t = 0.25
	Audio.play_sfx("shield", 1.3)
	if level != null:
		level.spawn_burst(global_position + Vector2(0, -6), Color("#9ad4ff"), 4)


func hit_boss(dmg: int) -> void:
	if dead or not active:
		return
	if shielded or _invuln_t > 0.0:
		_deflect()
		return
	hp = maxi(0, hp - dmg)
	_invuln_t = 1.0
	Audio.play_sfx("boss_hit")
	if level != null:
		level.shake(4.0)
		level.spawn_burst(global_position, Color("#ffffff"), 8)
	hp_changed.emit(hp, max_hp)
	if hp <= 0:
		_die()
	elif hp * 2 <= max_hp and speed_mult == 1.0:
		speed_mult = 1.3
		Audio.play_sfx("boss_roar")


func _die() -> void:
	dead = true
	_gen += 1
	mode = "dead"
	velocity = Vector2.ZERO
	set_deferred("collision_layer", 0)
	_hit.set_deferred("monitoring", false)
	Audio.play_sfx("boss_die")
	if level != null:
		level.shake(8.0)
	defeated.emit()
	var tw := create_tween()
	for i in range(10):
		tw.tween_callback(func():
			if level != null and is_instance_valid(self):
				level.spawn_burst(global_position + Vector2(randf_range(-20, 20), randf_range(-24, 24)), Color("#ffd23a"), 8))
		tw.tween_property(_sprite, "modulate", Color(1, 1, 1, 0.3) if i % 2 == 0 else Color.WHITE, 0.12)
	tw.tween_callback(queue_free)


# -------------------------------------------------------------- ataques ---
func _run_ai(g: int) -> void:
	await _wait(1.2, g)
	var i: int = 0
	while _alive(g):
		var patterns: Array = CONFIG[world]["patterns"]
		var p: String = patterns[i % patterns.size()]
		i += 1
		match p:
			"charge":
				await _p_charge(g)
			"slam":
				await _p_slam(g)
			"rain":
				await _p_rain(g)
			"hover":
				await _p_hover(g)
			"burrow":
				await _p_burrow(g)
			"snow":
				await _p_snow(g)
			"teleport":
				await _p_teleport(g)
			"fan":
				await _p_fan(g)
			"barrage":
				await _p_barrage(g)
		if not _alive(g):
			return
		mode = "idle"
		await _wait(0.7, g)


func _shoot(kind: String, from: Vector2, vel: Vector2, grav: float = 0.0, scl: float = 1.5) -> void:
	var s = ProjectileScene.instantiate()
	s.team = "enemy"
	s.kind = kind
	s.velocity = vel
	s.fall_accel = grav
	s.life = 4.0
	s.sprite_scale = scl
	s.position = from
	get_parent().add_child(s)


func _shockwave() -> void:
	Audio.play_sfx("slam")
	if level != null:
		level.shake(5.0)
	var y: float = _floor_y() - 5.0
	for d in [-1.0, 1.0]:
		_shoot("wave", Vector2(position.x + d * 26.0, y), Vector2(d * 120.0 * speed_mult, 0.0), 0.0, 1.4)


func _wait_floor(g: int, max_time: float = 2.5) -> void:
	var t: float = 0.0
	while _alive(g) and not is_on_floor() and t < max_time:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()


func _p_charge(g: int) -> void:
	mode = "telegraph"
	Audio.play_sfx("boss_roar")
	await _wait(0.7, g)
	if not _alive(g):
		return
	var p = _get_player()
	_charge_dir = 1 if (p != null and p.global_position.x > global_position.x) else -1
	mode = "charge"
	var t: float = 0.0
	while _alive(g) and t < 3.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if t > 0.2 and is_on_wall():
			break
	if not _alive(g):
		return
	mode = "stun"
	Audio.play_sfx("slam")
	if level != null:
		level.shake(4.0)
	await _wait(1.7, g)


func _p_slam(g: int) -> void:
	mode = "telegraph"
	await _wait(0.5, g)
	if not _alive(g):
		return
	var p = _get_player()
	var d: float = 1.0 if (p != null and p.global_position.x > global_position.x) else -1.0
	velocity = Vector2(d * 85.0, -330.0)
	mode = "air"
	await _wait(0.2, g)
	await _wait_floor(g)
	if not _alive(g):
		return
	_shockwave()
	mode = "stun"
	await _wait(1.3, g)


func _p_rain(g: int) -> void:
	mode = "roar"
	Audio.play_sfx("boss_roar")
	await _wait(0.6, g)
	var kind: String = CONFIG[world]["rain"]
	var n: int = 5 if speed_mult == 1.0 else 8
	for i in range(n):
		if not _alive(g):
			return
		var px: float = position.x
		var p = _get_player()
		if p != null:
			px = p.global_position.x + randf_range(-70.0, 70.0)
		px = clampf(px, arena_left + 24.0, arena_right - 24.0)
		_shoot(kind, Vector2(px, arena_top), Vector2(0.0, 30.0), 420.0, 1.5)
		await _wait(0.45, g)
	await _wait(0.8, g)


func _p_hover(g: int) -> void:
	shielded = true
	mode = "hover"
	_hover_target = Vector2(position.x, _floor_y() - 32.0 - 72.0)
	await _wait(0.7, g)
	for i in range(3):
		if not _alive(g):
			shielded = false
			return
		var p = _get_player()
		if p != null:
			_hover_target.x = clampf(p.global_position.x, arena_left + 40.0, arena_right - 40.0)
		await _wait(0.5, g)
		if not _alive(g):
			shielded = false
			return
		if p != null:
			var aim: Vector2 = (p.global_position - global_position).normalized()
			for a in [-0.35, 0.0, 0.35]:
				_shoot(str(CONFIG[world]["shot"]), global_position + Vector2(0, 8), aim.rotated(a) * 110.0, 0.0, 1.3)
			Audio.play_sfx("enemy_shoot")
		await _wait(0.4, g)
	shielded = false
	if not _alive(g):
		return
	mode = "drop"
	await get_tree().physics_frame
	await _wait_floor(g, 2.0)
	if not _alive(g):
		return
	_shockwave()
	mode = "stun"
	await _wait(1.5, g)


func _p_burrow(g: int) -> void:
	mode = "burrow"
	shielded = true
	_hit.monitoring = false
	collision_layer = 0
	_sprite.modulate.a = 0.0
	Audio.play_sfx("slam")
	await _wait(0.5, g)
	if not _alive(g):
		_unburrow()
		return
	var p = _get_player()
	var tx: float = position.x
	if p != null:
		tx = clampf(p.global_position.x, arena_left + 36.0, arena_right - 36.0)
	for i in range(4):
		if level != null:
			level.spawn_burst(Vector2(tx, _floor_y()), Color("#e0b050"), 6)
		await _wait(0.22, g)
		if not _alive(g):
			_unburrow()
			return
	position = Vector2(tx, _floor_y() - 32.0 + 6.0)
	_unburrow()
	velocity = Vector2(0.0, -300.0)
	mode = "air"
	await _wait(0.2, g)
	await _wait_floor(g)
	if not _alive(g):
		return
	_shockwave()
	mode = "stun"
	await _wait(1.4, g)


func _unburrow() -> void:
	shielded = false
	_hit.monitoring = true
	collision_layer = 4
	_sprite.modulate.a = 1.0


func _p_snow(g: int) -> void:
	mode = "roar"
	Audio.play_sfx("boss_roar")
	await _wait(0.5, g)
	for i in range(3):
		if not _alive(g):
			return
		var p = _get_player()
		var tx: float = position.x - 90.0
		if p != null:
			tx = p.global_position.x
		var vx: float = clampf((tx - position.x) / 0.9, -170.0, 170.0)
		_shoot(str(CONFIG[world]["shot"]), position + Vector2(0, -16), Vector2(vx, -240.0), 420.0, 1.6)
		Audio.play_sfx("enemy_shoot")
		await _wait(0.55, g)
	await _wait(0.6, g)


func _p_teleport(g: int) -> void:
	shielded = true
	mode = "vanish"
	_hit.monitoring = false
	collision_layer = 0
	_sprite.modulate.a = 0.0
	Audio.play_sfx("blink")
	if level != null:
		level.spawn_burst(global_position, Color("#8a2ad0"), 10)
	await _wait(0.6, g)
	if not _alive(g):
		_unvanish()
		return
	position = Vector2(randf_range(arena_left + 60.0, arena_right - 60.0), _floor_y() - 32.0 - randf_range(10.0, 80.0))
	_unvanish()
	mode = "float"
	if level != null:
		level.spawn_burst(global_position, Color("#ff5aff"), 10)
	await _wait(0.5, g)
	if not _alive(g):
		return
	Audio.play_sfx("enemy_shoot")
	for k in range(8):
		var ang: float = TAU * k / 8.0
		_shoot(str(CONFIG[world]["shot"]), global_position, Vector2(cos(ang), sin(ang)) * 95.0, 0.0, 1.3)
	await _wait(0.7, g)
	if not _alive(g):
		return
	var p = _get_player()
	if p != null:
		var aim: Vector2 = (p.global_position - global_position).normalized()
		for a in [-0.25, 0.0, 0.25]:
			_shoot(str(CONFIG[world]["shot"]), global_position, aim.rotated(a) * 120.0, 0.0, 1.3)
	await _wait(0.6, g)
	if not _alive(g):
		return
	mode = "idle"
	await _wait_floor(g)
	if not _alive(g):
		return
	mode = "stun"
	await _wait(1.2, g)


func _unvanish() -> void:
	shielded = false
	_hit.monitoring = true
	collision_layer = 4
	_sprite.modulate.a = 1.0


func _p_fan(g: int) -> void:
	## Abanico de proyectiles hacia abajo y a los lados (se esquiva saltando o entre huecos).
	mode = "telegraph"
	Audio.play_sfx("boss_roar")
	await _wait(0.6, g)
	for volley in range(2 if speed_mult == 1.0 else 3):
		if not _alive(g):
			return
		Audio.play_sfx("enemy_shoot")
		var n: int = 7
		for k in range(n):
			var ang: float = deg_to_rad(20.0 + 140.0 * k / float(n - 1)) + (0.12 if volley % 2 == 1 else 0.0)
			_shoot(str(CONFIG[world]["shot"]), global_position + Vector2(0, 6), Vector2(cos(ang), sin(ang)) * 105.0, 0.0, 1.4)
		await _wait(0.8, g)
	mode = "idle"
	await _wait(0.5, g)


func _p_barrage(g: int) -> void:
	## Ráfaga de disparos dirigidos al jugador.
	mode = "telegraph"
	await _wait(0.5, g)
	for i in range(5):
		if not _alive(g):
			return
		var p = _get_player()
		if p != null:
			var aim: Vector2 = (p.global_position - global_position).normalized()
			_shoot(str(CONFIG[world]["shot"]), global_position + Vector2(0, 4), aim * 135.0, 0.0, 1.3)
			Audio.play_sfx("enemy_shoot")
		await _wait(0.26, g)
	mode = "idle"
	await _wait(0.6, g)
