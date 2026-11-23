extends "res://items/fireball.gd"
## Bola de fuego de largo alcance (poder del personaje, antes «Paso Sombrío»): sale hacia donde mira, vuela recta en horizontal
## a gran velocidad y recorre ~1.000 px (más de dos pantallas). Estalla contra el primer enemigo que toca (le hace el daño de
## siempre: `take_hit("spark")`) o contra la primera pared sólida; no atraviesa el terreno. Reutiliza el dibujo, el brillo, la estela
## de llamas y la explosión de la bola de fuego del Pulso Eléctrico.

const LONG_SPEED := 560.0  # px/s
const LONG_RANGE := 1000.0  # px (ajustable entre 800 y 1.200 según el equilibrio)
const SAFE_START := 0.0

var flown: float = 0.0


func _ready() -> void:
	super()
	travel = LONG_RANGE
	_life = LONG_RANGE / LONG_SPEED + 1.0


func _enemy_radius(e) -> float:
	var sc: String = ""
	if e.get_script() != null:
		sc = str(e.get_script().resource_path)
	return 26.0 if sc.ends_with("boss.gd") or sc.ends_with("ww_boss.gd") else 13.0


func _physics_process(delta: float) -> void:
	if exploded:
		return
	_t += delta
	_life -= delta
	if _life <= 0.0:
		_explode(false)
		return
	_ball.frame = int(_t * 18.0) % 4
	var pulse: float = 1.0 + 0.18 * sin(_t * 26.0)
	_glow.scale = Vector2(pulse * 1.15, pulse * 1.15)
	var step: float = LONG_SPEED * delta
	var from: Vector2 = global_position
	var to: Vector2 = from + dir * step
	# pared sólida en el camino: se estrella (no atraviesa el terreno)
	var q := PhysicsRayQueryParameters2D.create(from, to + dir * 4.0, 1)
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(q)
	var wall_x: float = INF
	if not hit.is_empty():
		wall_x = (hit["position"] as Vector2).x
	# primer enemigo cuyo cuerpo cruza el tramo recorrido este fotograma (si está antes que la pared)
	var best = null
	var best_d: float = INF
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or bool(e.get("dead")):
			continue
		var r: float = _enemy_radius(e)
		var ep: Vector2 = e.global_position
		var along: float = (ep.x - from.x) * dir.x
		if along < -r or along > step + r:
			continue
		if absf(ep.y - from.y) > r + 4.0:
			continue
		var d: float = maxf(along, 0.0)
		if d < best_d:
			best_d = d
			best = e
	if best != null and (wall_x == INF or best_d <= absf(wall_x - from.x) + 6.0):
		global_position = Vector2(from.x + dir.x * minf(best_d, step), from.y)
		target = best
		_explode(true)
		return
	if wall_x != INF:
		global_position = Vector2(wall_x - dir.x * 2.0, from.y)
		_explode(false)
		return
	position = to
	flown += step
	if flown >= LONG_RANGE:
		_explode(false)
