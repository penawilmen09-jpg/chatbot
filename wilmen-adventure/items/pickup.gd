extends Area2D
## Objetos coleccionables: moneda, gema (3 por nivel), corazón y vida extra.

const SpriteUtil := preload("res://characters/sprite_util.gd")

@export var kind: String = "coin"  # coin | gem | heart | life
var gem_id: int = -1
var level = null

var _sprite: AnimatedSprite2D
var _taken: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 7.0 if kind == "coin" else 8.0
	cs.shape = shape
	add_child(cs)
	var file: String = kind
	var count: int = 1
	var fps: float = 1.0
	match kind:
		"coin":
			count = 4
			fps = 8.0
		"gem":
			count = 2
			fps = 4.0
	var tex: Texture2D = load("res://assets/items/%s.png" % file)
	var idx: Array = []
	for i in range(count):
		idx.append(i)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = SpriteUtil.make_frames(tex, 16, 16, {"idle": {"frames": idx, "fps": fps}})
	add_child(_sprite)
	_sprite.play("idle")
	_sprite.frame = randi() % count
	if kind != "coin":
		var tw := create_tween().set_loops()
		tw.tween_property(_sprite, "position:y", -2.0, 0.6).set_trans(Tween.TRANS_SINE)
		tw.tween_property(_sprite, "position:y", 2.0, 0.6).set_trans(Tween.TRANS_SINE)
	body_entered.connect(_on_body_entered)


func _on_body_entered(b: Node) -> void:
	if _taken or not b.is_in_group("player"):
		return
	_collect()


func _collect() -> void:
	if _taken:
		return
	_taken = true
	set_deferred("monitoring", false)
	if level != null:
		level.on_pickup(kind, gem_id, global_position)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_sprite, "position:y", _sprite.position.y - 14.0, 0.18)
	tw.tween_property(_sprite, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(queue_free)


func pop_out(from: Vector2, auto_collect: bool) -> void:
	## Aparece desde un bloque. Las monedas se recogen solas.
	global_position = from
	if auto_collect:
		_taken = true
		set_deferred("monitoring", false)
		var tw := create_tween()
		tw.tween_property(self, "position:y", position.y - 30.0, 0.22).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func():
			if level != null:
				level.on_pickup(kind, gem_id, global_position)
			queue_free())
	else:
		var tw2 := create_tween()
		tw2.tween_property(self, "position:y", position.y - 16.0, 0.25).set_ease(Tween.EASE_OUT)
