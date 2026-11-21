extends CharacterBody2D
## Vehículos especiales: carrito minero, barco, plataforma voladora y mecha. Wilmen sube al tocarlos y los maneja con
## los mismos botones táctiles: izquierda/derecha, SALTO (saltar o subir) y PODER (bajar del vehículo).
##  - carrito: avanza solo por la vía; izquierda frena, derecha acelera, salto = brinco.
##  - barco: navega sobre el agua; salto = brinco para esquivar rocas.
##  - plataforma voladora: salto MANTENIDO = subir, soltar = bajar.
##  - mecha: camina, salta, rompe ladrillos, aplasta enemigos y aguanta 3 golpes.

const SpriteUtil := preload("res://characters/sprite_util.gd")
const SPECS := {
	"cart": ["res://assets/items/v_cart.png", 32, 24, Vector2(26, 14), Vector2(0, -3)],
	"boat": ["res://assets/items/v_boat.png", 40, 24, Vector2(30, 12), Vector2(0, -8)],
	"flyer": ["res://assets/items/v_flyer.png", 40, 20, Vector2(30, 10), Vector2(0, -11)],
	"mech": ["res://assets/items/v_mech.png", 32, 32, Vector2(20, 26), Vector2(0, -10)],
}
const NAMES := {"cart": "Carrito minero", "boat": "Barco", "flyer": "Plataforma voladora", "mech": "Mecha"}
const HINTS := {
	"cart": "Salto: brincar · Poder: bajar",
	"boat": "Salto: brincar · Poder: bajar",
	"flyer": "Mantén salto: subir · Poder: bajar",
	"mech": "Aplasta enemigos y rompe ladrillos",
}
const GRAVITY := 900.0

var kind: String = "cart"
var level = null
var end_x: float = INF  # x (px) de la estación donde acaba el tramo
var end_y: float = 0.0
var armor: int = 1

var _rider = null
var _home: Vector2
var _base_y: float = 0.0
var _sprite: Sprite2D
var _area: Area2D
var _t: float = 0.0
var _crashed: bool = false
var _loop_t: float = 0.0
var _w: int = 32
var _h: int = 24


func _ready() -> void:
	var sp: Array = SPECS[kind]
	_w = int(sp[1])
	_h = int(sp[2])
	collision_layer = 0
	collision_mask = 1
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = sp[3]
	cs.shape = rs
	cs.position = Vector2(0, _h * 0.5 - rs.size.y * 0.5 - 2.0)
	add_child(cs)
	_sprite = Sprite2D.new()
	_sprite.texture = load(sp[0])
	_sprite.hframes = 2
	_sprite.position = Vector2(0, 0)
	add_child(_sprite)
	_area = Area2D.new()
	_area.collision_layer = 0
	_area.collision_mask = 2
	var ac := CollisionShape2D.new()
	var ar := RectangleShape2D.new()
	ar.size = Vector2(_w, _h + 8)
	ac.shape = ar
	_area.add_child(ac)
	add_child(_area)
	_area.body_entered.connect(_on_body)
	_home = position
	_base_y = position.y
	armor = 3 if kind == "mech" else 1
	floor_snap_length = 4.0


func _on_body(b: Node) -> void:
	if _rider != null or _crashed or not b.is_in_group("player") or b.dead or b.get("vehicle") != null:
		return
	board(b)


func board(p) -> void:
	_rider = p
	p.vehicle = self
	p.velocity = Vector2.ZERO
	Audio.play_sfx("vehicle_on")
	Progress.stats["vehicles"] = int(Progress.stats["vehicles"]) + 1
	Progress.check_achievements()
	if level != null:
		level.popup("¡%s! %s" % [NAMES[kind], HINTS[kind]], global_position + Vector2(0, -26))
		level.spawn_burst(global_position, Color("#ffffff"), 8)
	_area.set_deferred("monitoring", false)


func absorb_hit() -> bool:
	## El mecha aguanta golpes por el jugador; los demás vehículos no.
	if kind != "mech" or _rider == null:
		return false
	armor -= 1
	Audio.play_sfx("barrier_break")
	if level != null:
		level.spawn_burst(global_position, Color("#ffb02a"), 10)
		level.shake(3.0)
	if armor <= 0:
		call_deferred("dismount", false)
	return true


func dismount(at_station: bool) -> void:
	if _rider == null:
		return
	var p = _rider
	_rider = null
	p.vehicle = null
	p.velocity = Vector2(0, -120)
	if at_station:
		p.global_position = Vector2(end_x + 10.0, end_y - 10.0)
		p.velocity = Vector2.ZERO
		if level != null:
			level.popup("¡Tramo completado!", p.global_position + Vector2(0, -24))
			level.spawn_burst(p.global_position, Color("#8affb0"), 12)
		queue_free()
		return
	if kind == "mech" and armor <= 0:
		queue_free()
		if level != null:
			level.spawn_burst(global_position, Color("#ff8a2a"), 14)
		return
	# el jugador se baja y el vehículo vuelve a su sitio para poder usarlo otra vez
	call_deferred("_return_home")


func _return_home() -> void:
	position = _home
	velocity = Vector2.ZERO
	_crashed = false
	armor = 3 if kind == "mech" else 1
	await get_tree().create_timer(0.8, false).timeout
	if is_instance_valid(self):
		_area.set_deferred("monitoring", true)


func release_rider() -> void:
	## El jugador ha muerto: se suelta y el vehículo vuelve a su sitio.
	if _rider != null:
		_rider.vehicle = null
		_rider = null
	call_deferred("_return_home")


func _crash() -> void:
	if _crashed or _rider == null:
		return
	_crashed = true
	var p = _rider
	_rider = null
	p.vehicle = null
	Audio.play_sfx("stomp")
	if level != null:
		level.spawn_burst(global_position, Color("#c8c8d8"), 14)
		level.shake(4.0)
	p.hurt(1, global_position.x + 8.0)
	p.velocity = Vector2(-130, -220)
	call_deferred("_return_home")


func _physics_process(delta: float) -> void:
	_t += delta
	_sprite.frame = int(_t * (8.0 if _rider != null else 2.0)) % 2
	if _rider == null:
		if kind == "flyer":
			_sprite.position.y = sin(_t * 2.5) * 2.0
		elif kind == "boat":
			position.y = _base_y + sin(_t * 2.0) * 1.0
		else:
			velocity.y = minf(velocity.y + GRAVITY * delta, 300.0)
			velocity.x = 0.0
			move_and_slide()
		return
	var p = _rider
	if not is_instance_valid(p) or p.dead:
		release_rider()
		return
	var dir: float = Input.get_axis("move_left", "move_right")
	var jump_p: bool = Input.is_action_just_pressed("jump")
	var jump_h: bool = Input.is_action_pressed("jump")
	if Input.is_action_just_pressed("skill"):
		dismount(false)
		return
	_loop_t -= delta
	match kind:
		"cart":
			velocity.x = 110.0 + dir * 40.0
			velocity.y = minf(velocity.y + GRAVITY * delta, 340.0)
			if jump_p and is_on_floor():
				velocity.y = -285.0
				Audio.play_sfx("jump")
			var vx_before: float = velocity.x
			move_and_slide()
			if is_on_wall() and vx_before > 0.0 and absf(get_position_delta().x) < 0.4:
				_crash()
				return
			if _loop_t <= 0.0 and is_on_floor():
				_loop_t = 0.35
				Audio.play_sfx("cart_rumble")
		"boat":
			velocity.x = 90.0 + dir * 30.0
			var on_water: bool = position.y >= _base_y - 0.5 and velocity.y >= 0.0
			if on_water:
				position.y = _base_y
				velocity.y = 0.0
				if jump_p:
					velocity.y = -270.0
					Audio.play_sfx("splash")
			else:
				velocity.y += GRAVITY * delta
			var px_before: float = position.x
			position += velocity * delta
			if test_move(global_transform, Vector2(velocity.x * delta, 0.0)):
				_crash()
				return
			if _loop_t <= 0.0 and on_water:
				_loop_t = 0.5
				Audio.play_sfx("splash", 0.7)
			px_before = 0.0
		"flyer":
			velocity.x = 70.0 + dir * 35.0
			if jump_h:
				velocity.y = move_toward(velocity.y, -120.0, 520.0 * delta)
			else:
				velocity.y = move_toward(velocity.y, 90.0, 360.0 * delta)
			move_and_slide()
			position.y = clampf(position.y, 22.0, float(level.nrows * 16 - 24) if level != null else 300.0)
			if _loop_t <= 0.0:
				_loop_t = 0.3
				Audio.play_sfx("engine")
		"mech":
			velocity.x = move_toward(velocity.x, dir * 85.0, 900.0 * delta)
			velocity.y = minf(velocity.y + GRAVITY * delta, 340.0)
			if jump_p and is_on_floor():
				velocity.y = -250.0
				Audio.play_sfx("jump", 0.7)
			move_and_slide()
			for i in range(get_slide_collision_count()):
				var col := get_slide_collision(i)
				var other = col.get_collider()
				if other != null and absf(col.get_normal().x) > 0.7 and other.has_method("smash"):
					other.smash()
			if absf(velocity.x) > 20.0 and _loop_t <= 0.0 and is_on_floor():
				_loop_t = 0.3
				Audio.play_sfx("giant_stomp", 1.4)
			if dir != 0.0:
				_sprite.flip_h = dir < 0.0
				p.facing = 1 if dir > 0.0 else -1
	# el jugador va sentado en el vehículo
	var seat: Vector2 = SPECS[kind][4]
	p.global_position = global_position + seat
	p.velocity = Vector2.ZERO
	if kind != "mech":
		p.facing = 1
	if global_position.x >= end_x:
		dismount(true)
