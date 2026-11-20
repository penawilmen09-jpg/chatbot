extends Area2D
## Resorte: lanza al jugador hacia arriba.

const SpriteUtil := preload("res://characters/sprite_util.gd")

var _sprite: AnimatedSprite2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(14, 6)
	cs.shape = rs
	cs.position = Vector2(0, 5)
	add_child(cs)
	var tex: Texture2D = load("res://assets/items/spring.png")
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = SpriteUtil.make_frames(tex, 16, 16, {
		"idle": {"frames": [0], "fps": 1.0},
		"press": {"frames": [1], "fps": 1.0},
	})
	add_child(_sprite)
	_sprite.play("idle")
	body_entered.connect(_on_body_entered)


func _on_body_entered(b: Node) -> void:
	if not b.is_in_group("player") or b.dead:
		return
	if b.velocity.y < -50.0:
		return
	b.launch(-430.0)
	Audio.play_sfx("spring")
	_sprite.play("press")
	get_tree().create_timer(0.2, false).timeout.connect(func():
		if is_instance_valid(_sprite):
			_sprite.play("idle"))
