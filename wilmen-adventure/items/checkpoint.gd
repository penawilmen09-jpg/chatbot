extends Area2D
## Punto de control: al tocarlo, reapareces aquí si pierdes una vida.

const SpriteUtil := preload("res://characters/sprite_util.gd")

var level = null
var reached: bool = false
var _sprite: AnimatedSprite2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(14, 28)
	cs.shape = rs
	cs.position = Vector2(0, -16)
	add_child(cs)
	var tex: Texture2D = load("res://assets/items/checkpoint.png")
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = SpriteUtil.make_frames(tex, 16, 32, {
		"off": {"frames": [0], "fps": 1.0},
		"on": {"frames": [1], "fps": 1.0},
	})
	_sprite.position = Vector2(0, -16)
	add_child(_sprite)
	_sprite.play("off")
	body_entered.connect(_on_body_entered)


func activate(silent: bool = false) -> void:
	if reached:
		return
	reached = true
	_sprite.play("on")
	if not silent:
		Audio.play_sfx("checkpoint")


func _on_body_entered(b: Node) -> void:
	if reached or not b.is_in_group("player") or level == null:
		return
	activate()
	level.set_checkpoint(global_position + Vector2(0, -10))
