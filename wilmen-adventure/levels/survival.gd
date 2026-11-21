extends Node
## Modo supervivencia: oleadas de enemigos del mundo elegido en una arena. Termina al perder los corazones;
## se guarda el récord de oleadas por mundo y se entregan cofres por alcanzar 5, 10 y 20 oleadas.

const EnemyScene := preload("res://enemies/enemy.tscn")
const PickupScene := preload("res://items/pickup.tscn")
const MILESTONES := [[5, "rare"], [10, "special"], [20, "secret"]]

var level = null
var wave: int = 0
var _alive: Array = []
var _cool: float = 2.0
var _rewarded: Array = []


func _process(delta: float) -> void:
	if level == null or level.player == null or level.finished or level.player.dead:
		return
	_alive = _alive.filter(func(e): return is_instance_valid(e) and not e.dead)
	if _alive.is_empty():
		_cool -= delta
		if _cool <= 0.0:
			_next_wave()


func _pool() -> Array:
	var w: int = level.world
	var pool: Array = ["walker", "jumper"]
	if wave >= 2:
		pool.append("flyer")
	if wave >= 3:
		pool.append("spiky")
	if wave >= 5 or w >= 4:
		pool.append("shooter")
	return pool


func _next_wave() -> void:
	if wave > 0:
		Audio.play_sfx("wave")
		level.popup("Oleada %d superada" % wave, level.player.global_position + Vector2(0, -30))
		_milestone(wave)
		if wave % 2 == 0:  # ayuda entre oleadas: un corazón
			var h = PickupScene.instantiate()
			h.kind = "heart"
			h.level = level
			h.position = Vector2(level.cols * 8.0, 160.0)
			level.add_child(h)
	wave += 1
	_cool = 3.0
	if level.hud != null:
		level.hud.set_mode_label("Oleada %d" % wave)
	var count: int = mini(2 + wave, 12)
	var pool: Array = _pool()
	var left_x: float = 48.0
	var right_x: float = level.cols * 16.0 - 48.0
	for i in range(count):
		var e = EnemyScene.instantiate()
		e.kind = pool[(i + wave) % pool.size()]
		e.world = level.world
		e.level = level
		e.position = Vector2(left_x if i % 2 == 0 else right_x, 120.0 - float(i % 3) * 24.0)
		level.add_child(e)
		_alive.append(e)


func _milestone(done_wave: int) -> void:
	for i in range(MILESTONES.size()):
		if done_wave >= int(MILESTONES[i][0]) and not _rewarded.has(i):
			_rewarded.append(i)
			var r: Dictionary = Progress.claim_chest(4000 + level.world * 10 + i, 0, str(MILESTONES[i][1]))
			if not r.is_empty():
				level.show_reward(r, level.player.global_position)


func finish() -> Dictionary:
	## Al terminar: guarda el récord y devuelve el resumen para la pantalla final.
	var reached: int = maxi(0, wave - 1)
	var new_best: bool = Progress.record_survival(level.world, reached)
	return {"waves": reached, "best": int(Progress.records.get("survival:%d" % level.world, reached)), "new_best": new_best, "rewards": []}
