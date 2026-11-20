extends StaticBody2D
## Plataforma frágil: tiembla al pisarla, cae y reaparece unos segundos después.

var tileset: Texture2D = null

var _shape: CollisionShape2D
var _sprite: Sprite2D
var _sensor: Area2D
var _state: String = "idle"  # idle | shaking | fallen
var _t: float = 0.0
var _player = null


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_shape = CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(16, 6)
	_shape.shape = rs
	_shape.position = Vector2(0, -5)
	_shape.one_way_collision = true
	_shape.one_way_collision_margin = 4.0
	add_child(_shape)
	_sprite = Sprite2D.new()
	var at := AtlasTexture.new()
	at.atlas = tileset
	at.region = Rect2(16 * 16, 0, 16, 16)
	_sprite.texture = at
	add_child(_sprite)
	_sensor = Area2D.new()
	_sensor.collision_layer = 0
	_sensor.collision_mask = 2
	var sc := CollisionShape2D.new()
	var sr := RectangleShape2D.new()
	sr.size = Vector2(14, 5)
	sc.shape = sr
	sc.position = Vector2(0, -10)
	_sensor.add_child(sc)
	add_child(_sensor)


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	if absf(_player.global_position.x - global_position.x) > 200.0 and _state == "idle":
		return
	match _state:
		"idle":
			for b in _sensor.get_overlapping_bodies():
				if b == _player and not _player.dead and _player.velocity.y >= -5.0:
					_state = "shaking"
					_t = 0.45
		"shaking":
			_t -= delta
			_sprite.position.x = randf_range(-1.2, 1.2)
			if _t <= 0.0:
				_state = "fallen"
				_t = 2.6
				_shape.disabled = true
				_sprite.position.x = 0.0
				var tw := create_tween()
				tw.set_parallel(true)
				tw.tween_property(_sprite, "position:y", 48.0, 0.5)
				tw.tween_property(_sprite, "modulate:a", 0.0, 0.5)
		"fallen":
			_t -= delta
			if _t <= 0.0:
				_state = "idle"
				_shape.disabled = false
				_sprite.position = Vector2.ZERO
				_sprite.modulate.a = 1.0
