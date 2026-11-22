extends Area2D
## Llave de WILMEN WORLD. Cada llave del nivel se puede recoger una sola vez en toda la partida (queda anotada en el
## guardado del modo) y se gasta al abrir una puerta o una verja con candado.

const SHEET := preload("res://assets/items/ww_items.png")

var level = null
var key_id: String = ""

var _sprite: Sprite2D
var _t: float = 0.0
var _taken: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 8.0
	cs.shape = sh
	add_child(cs)
	_sprite = Sprite2D.new()
	add_child(_sprite)
	_set_frame(0)
	body_entered.connect(_on_body_entered)
	var tw := create_tween().set_loops()
	tw.tween_property(_sprite, "position:y", -3.0, 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_sprite, "position:y", 2.0, 0.7).set_trans(Tween.TRANS_SINE)


func _set_frame(f: int) -> void:
	var at := AtlasTexture.new()
	at.atlas = SHEET
	at.region = Rect2((4 + f) * 16, 0, 16, 16)
	_sprite.texture = at


func _process(delta: float) -> void:
	_t += delta
	_set_frame(int(_t * 3.0) % 2)


func _on_body_entered(b: Node) -> void:
	if _taken or not b.is_in_group("player") or level == null:
		return
	_taken = true
	set_deferred("monitoring", false)
	if WW.take_key(level.number, key_id):
		WW.save_game()
		level.popup("¡Llave! (%d)" % WW.key_count(), global_position + Vector2(0, -14))
		level.spawn_burst(global_position, Color("#ffd23a"), 10)
		Audio.play_sfx("gem", 1.2)
	queue_free()
