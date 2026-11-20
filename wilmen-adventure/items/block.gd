extends StaticBody2D
## Bloques: ladrillo rompible, bloque con moneda, bloque con corazón y bloques ocultos (secretos).

const PickupScene := preload("res://items/pickup.tscn")

@export var kind: String = "brick"  # brick | question | heart | hidden_life | hidden_coins
var tileset: Texture2D = null
var level = null

var _used: bool = false
var _sprite: Sprite2D
var _shape: CollisionShape2D
var _sensor: Area2D = null
var _busy: bool = false


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_shape = CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(16, 16)
	_shape.shape = rs
	add_child(_shape)
	_sprite = Sprite2D.new()
	add_child(_sprite)
	var hidden: bool = kind.begins_with("hidden")
	match kind:
		"brick":
			_set_tile(4)
		"question", "heart":
			_set_tile(5)
		_:
			_set_tile(6)
	if hidden:
		_shape.disabled = true
		_sprite.visible = false
		_sensor = Area2D.new()
		_sensor.collision_layer = 0
		_sensor.collision_mask = 2
		var sc := CollisionShape2D.new()
		var sr := RectangleShape2D.new()
		sr.size = Vector2(12, 6)
		sc.shape = sr
		sc.position = Vector2(0, 10)
		_sensor.add_child(sc)
		add_child(_sensor)
	else:
		set_physics_process(false)


func _set_tile(idx: int) -> void:
	var at := AtlasTexture.new()
	at.atlas = tileset
	at.region = Rect2(idx * 16, 0, 16, 16)
	_sprite.texture = at


func _physics_process(_delta: float) -> void:
	# Bloque oculto: se revela al golpearlo desde abajo
	if _sensor == null or _used:
		return
	for b in _sensor.get_overlapping_bodies():
		if b.is_in_group("player") and b.last_vy < -20.0:
			_reveal(b)
			return


func _reveal(player) -> void:
	_used = true
	_shape.set_deferred("disabled", false)
	_sprite.visible = true
	_sensor.set_deferred("monitoring", false)
	set_physics_process(false)
	player.velocity.y = maxf(player.velocity.y, 40.0)
	_bump_anim()
	Audio.play_sfx("bump")
	if kind == "hidden_life":
		_spawn_pickup("life", false)
		Audio.play_sfx("item")
	else:
		_coin_burst(5)


func bump(_player) -> void:
	match kind:
		"brick":
			_break()
		"question":
			if not _used:
				_used = true
				_set_tile(6)
				_spawn_pickup("coin", true)
			_bump_anim()
		"heart":
			if not _used:
				_used = true
				_set_tile(6)
				_spawn_pickup("heart", false)
				Audio.play_sfx("item")
			_bump_anim()
		_:
			_bump_anim()


func smash() -> void:
	## Golpe lateral (Impulso de Cristal).
	if kind == "brick":
		_break()
	elif not _used and not kind.begins_with("hidden"):
		bump(null)


func _break() -> void:
	if _busy:
		return
	_busy = true
	Audio.play_sfx("break")
	Game.add_score(50)
	if level != null:
		level.spawn_burst(global_position, Color("#c0693a"), 10)
		level.shake(2.0)
	queue_free()


func _bump_anim() -> void:
	if _busy:
		return
	_busy = true
	var tw := create_tween()
	tw.tween_property(_sprite, "position:y", -5.0, 0.07)
	tw.tween_property(_sprite, "position:y", 0.0, 0.09)
	tw.tween_callback(func(): _busy = false)
	if not _used:
		Audio.play_sfx("bump")


func _spawn_pickup(k: String, auto_collect: bool) -> void:
	var p = PickupScene.instantiate()
	p.kind = k
	p.level = level
	get_parent().add_child(p)
	p.pop_out(global_position + Vector2(0, -16), auto_collect)


func _coin_burst(n: int) -> void:
	for i in range(n):
		get_tree().create_timer(0.09 * i, false).timeout.connect(func():
			if is_inside_tree():
				_spawn_pickup("coin", true))
