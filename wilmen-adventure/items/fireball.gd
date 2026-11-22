extends Node2D
## Bola de fuego del Pulso Eléctrico (poder base del Mundo 9). Sustituye a los pequeños rayos de esa habilidad:
## sale del jugador, vuela hacia un enemigo cercano (o, si no hay ninguno, hacia delante hasta el alcance del poder)
## y al llegar estalla en una pequeña explosión de fuego. El daño sigue siendo el de siempre (`take_hit("spark")`).

const TEX := preload("res://assets/items/fireball.png")
const BOOM := preload("res://assets/items/fireball_boom.png")
const SPEED := 340.0  # antes 260
const RANGE := 192.0  # alcance máximo (antes 64: 3 veces más)
const LIFE_MARGIN := 0.6  # segundos extra sobre el vuelo máximo; evita bolas perdidas, no recorta el alcance
const FLAME := Color("#ff7a1a")

var target = null  # enemigo al que se dirige (puede ser null)
var dir: Vector2 = Vector2.RIGHT
var travel: float = RANGE  # distancia que le queda por recorrer sin objetivo
var exploded: bool = false

var _ball: Sprite2D
var _glow: Sprite2D
var _trail: CPUParticles2D
var _boom: Sprite2D
var _t: float = 0.0
var _life: float = RANGE / SPEED + LIFE_MARGIN


func _ready() -> void:
	z_index = 9
	_glow = Sprite2D.new()
	var gt := GradientTexture2D.new()
	gt.width = 48
	gt.height = 48
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1.0, 0.75, 0.25, 0.55), Color(1.0, 0.35, 0.08, 0.22), Color(1.0, 0.2, 0.0, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	gt.gradient = g
	_glow.texture = gt
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = mat
	add_child(_glow)
	_trail = CPUParticles2D.new()
	_trail.amount = 14
	_trail.lifetime = 0.4
	_trail.local_coords = false
	_trail.direction = Vector2(0, -1)
	_trail.spread = 60.0
	_trail.initial_velocity_min = 6.0
	_trail.initial_velocity_max = 22.0
	_trail.gravity = Vector2(0, -40)
	_trail.scale_amount_min = 1.0
	_trail.scale_amount_max = 2.2
	_trail.color = Color("#ffb040")
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color(1.0, 0.9, 0.4, 0.95), Color(1.0, 0.35, 0.1, 0.7), Color(0.4, 0.1, 0.05, 0.0)])
	ramp.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	_trail.color_ramp = ramp
	add_child(_trail)
	_ball = Sprite2D.new()
	_ball.texture = TEX
	_ball.hframes = 4
	add_child(_ball)
	_face()


func _face() -> void:
	## La cola del dibujo apunta a la izquierda: hacia la derecha se gira, hacia la izquierda se voltea.
	if dir.x >= 0.0:
		_ball.flip_h = false
		_ball.rotation = dir.angle()
	else:
		_ball.flip_h = true
		_ball.rotation = (-dir).angle()


func _physics_process(delta: float) -> void:
	if exploded:
		return
	_t += delta
	_life -= delta
	if _life <= 0.0 and not exploded:
		_explode(false)  # seguridad: un objetivo que huye no la mantiene volando eternamente
		return
	_ball.frame = int(_t * 16.0) % 4
	var pulse: float = 1.0 + 0.15 * sin(_t * 22.0)
	_glow.scale = Vector2(pulse, pulse)
	var step: float = SPEED * delta
	if target != null and is_instance_valid(target) and not bool(target.get("dead")):
		var to: Vector2 = target.global_position - global_position
		if to.length() <= step + 3.0:
			global_position = target.global_position
			_explode(true)
			return
		dir = to.normalized()
		_face()
		var q2 := PhysicsRayQueryParameters2D.create(global_position, global_position + dir * (step + 3.0), 1)
		if not get_world_2d().direct_space_state.intersect_ray(q2).is_empty():
			_explode(false)  # un muro en medio: no atraviesa el terreno para llegar hasta enemigos lejanos
			return
		position += dir * step
		return
	if target != null:
		target = null  # el enemigo desapareció por el camino: se sigue recto hasta el alcance
	var motion: Vector2 = dir * step
	var q := PhysicsRayQueryParameters2D.create(global_position, global_position + motion + dir * 3.0, 1)
	if not get_world_2d().direct_space_state.intersect_ray(q).is_empty():
		_explode(false)
		return
	position += motion
	travel -= step
	if travel <= 0.0:
		_explode(false)


func _explode(hit: bool) -> void:
	if exploded:
		return
	exploded = true
	if hit and target != null and is_instance_valid(target) and target.has_method("take_hit"):
		target.take_hit("spark")  # mismo daño que el Pulso Eléctrico de siempre
	_ball.visible = false
	_trail.emitting = false
	Audio.play_sfx("fire", 0.75)
	var lvl = get_parent()
	if lvl != null and lvl.has_method("spawn_burst"):
		lvl.spawn_burst(global_position, FLAME, 8)
		lvl.spawn_burst(global_position, Color("#ffe27a"), 4)
		if lvl.has_method("shake"):
			lvl.shake(1.5)
	_boom = Sprite2D.new()
	_boom.texture = BOOM
	_boom.hframes = 6
	add_child(_boom)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_method(func(v: float): _boom.frame = clampi(int(v), 0, 5), 0.0, 5.99, 0.36)
	tw.tween_property(_glow, "scale", Vector2(2.6, 2.6), 0.36)
	tw.tween_property(_glow, "modulate:a", 0.0, 0.36)
	tw.chain().tween_callback(queue_free)
