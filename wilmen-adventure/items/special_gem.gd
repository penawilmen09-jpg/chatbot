extends Area2D
## Gema especial escondida (morada): se guarda para siempre y cuenta para logros y la colección.

const SHEET := preload("res://assets/items/sgem.png")

var idx: int = 0
var level = null

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
	_frame(0)
	body_entered.connect(_on_body_entered)


func _frame(f: int) -> void:
	var at := AtlasTexture.new()
	at.atlas = SHEET
	at.region = Rect2(f * 16, 0, 16, 16)
	_sprite.texture = at


func _process(delta: float) -> void:
	_t += delta
	_frame(int(_t * 3.0) % 2)
	_sprite.position.y = sin(_t * 3.0) * 2.0


func _on_body_entered(b: Node) -> void:
	if _taken or not b.is_in_group("player"):
		return
	_taken = true
	set_deferred("monitoring", false)
	var n: int = level.number if level != null else 0
	if Progress.collect_special_gem(n, idx) and level != null:
		level.popup("+1 gema especial", global_position + Vector2(0, -14))
	Audio.play_sfx("gem", 1.3)
	if level != null:
		level.spawn_burst(global_position, Color("#c04aff"), 10)
	queue_free()
