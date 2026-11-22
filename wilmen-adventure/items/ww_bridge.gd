extends Node2D
## Puente que se derrumba: al pisar una tabla, las demás caen en cadena (más tarde cuanto más lejos). Hay que cruzarlo sin
## detenerse. Un tramo de `_` contiguas es un puente. Se reconstruye al reaparecer el jugador (reset_state).

const A := preload("res://items/ww_atlas.gd")
const FIRST := 0.32
const STEP := 0.17

var level = null
var cells: int = 8
var _planks: Array = []  # {"body","sprite","alive","fall_at"}
var _t: float = 0.0
var _armed: bool = false


func _ready() -> void:
	add_to_group("ww_reset")
	_build()


func _build() -> void:
	for p in _planks:
		if is_instance_valid(p["body"]):
			p["body"].queue_free()
	_planks = []
	_armed = false
	_t = 0.0
	for i in range(cells):
		var b := StaticBody2D.new()
		b.collision_layer = 1
		b.collision_mask = 0
		b.position = Vector2(i * 16, 0)
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(16, 6)
		cs.shape = rs
		cs.position = Vector2(0, -5)
		cs.one_way_collision = true
		cs.one_way_collision_margin = 5.0
		b.add_child(cs)
		var s := Sprite2D.new()
		s.texture = A.tex("plank")
		b.add_child(s)
		add_child(b)
		_planks.append({"body": b, "sprite": s, "alive": true, "fall_at": -1.0, "cs": cs})


func reset_state() -> void:
	_build()


func _physics_process(delta: float) -> void:
	_t += delta
	if level != null and level.player != null and not level.player.dead and level.player.is_on_floor():
		var p = level.player
		for i in range(_planks.size()):
			var pl: Dictionary = _planks[i]
			if not bool(pl["alive"]) or float(pl["fall_at"]) >= 0.0:
				continue
			var b: StaticBody2D = pl["body"]
			if absf(p.global_position.x - b.global_position.x) < 10.0 and absf((p.global_position.y + 9.0) - (b.global_position.y - 8.0)) < 7.0:
				_trigger(i)
				break
	for i in range(_planks.size()):
		var pl2: Dictionary = _planks[i]
		var fa: float = float(pl2["fall_at"])
		if bool(pl2["alive"]) and fa >= 0.0:
			var left: float = fa - _t
			var b2: StaticBody2D = pl2["body"]
			if left > 0.0:
				pl2["sprite"].position.x = randf_range(-1.2, 1.2) if left < 0.5 else 0.0
			else:
				pl2["alive"] = false
				pl2["cs"].set_deferred("disabled", true)
				var tw := create_tween()
				tw.set_parallel(true)
				tw.tween_property(b2, "position:y", b2.position.y + 220.0, 0.9).set_ease(Tween.EASE_IN)
				tw.tween_property(b2, "modulate:a", 0.0, 0.9)


func _trigger(idx: int) -> void:
	if _armed:
		return
	_armed = true
	Audio.play_sfx("break", 0.8)
	for i in range(_planks.size()):
		_planks[i]["fall_at"] = _t + FIRST + absf(float(i - idx)) * STEP


func collapsed_count() -> int:
	var n: int = 0
	for pl in _planks:
		if not bool(pl["alive"]):
			n += 1
	return n
