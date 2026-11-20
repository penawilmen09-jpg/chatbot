extends Area2D
## Meta del nivel (bandera). En los niveles de jefe aparece al derrotarlo.

const SpriteUtil := preload("res://characters/sprite_util.gd")

var level = null
var active: bool = true
var _sprite: AnimatedSprite2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(12, 44)
	cs.shape = rs
	cs.position = Vector2(0, -24)
	add_child(cs)
	var tex: Texture2D = load("res://assets/items/goal.png")
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = SpriteUtil.make_frames(tex, 16, 48, {"wave": {"frames": [0, 1], "fps": 4.0}})
	_sprite.position = Vector2(0, -24)
	add_child(_sprite)
	_sprite.play("wave")
	body_entered.connect(_on_body_entered)
	_apply_active()


func set_active(v: bool) -> void:
	active = v
	if is_inside_tree():
		_apply_active()


func _apply_active() -> void:
	visible = active
	set_deferred("monitoring", active)


func _on_body_entered(b: Node) -> void:
	if active and b.is_in_group("player") and level != null:
		level.complete_level()
