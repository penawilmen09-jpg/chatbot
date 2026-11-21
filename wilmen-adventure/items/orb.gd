extends Area2D
## Orbe de poder temporal: Fuego, Hielo, Electricidad, Escudo protector o Gigante. Se consigue jugando.

const SHEET := preload("res://assets/items/orbs.png")
const ORDER := ["flame", "freeze", "pulse", "barrier", "giant"]

var kind: String = "flame"
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
	_set_frame(0)
	body_entered.connect(_on_body_entered)
	var tw := create_tween().set_loops()
	tw.tween_property(_sprite, "position:y", -3.0, 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_sprite, "position:y", 2.0, 0.7).set_trans(Tween.TRANS_SINE)


func _set_frame(f: int) -> void:
	var at := AtlasTexture.new()
	at.atlas = SHEET
	at.region = Rect2((maxi(0, ORDER.find(kind)) * 2 + f) * 16, 0, 16, 16)
	_sprite.texture = at


func _process(delta: float) -> void:
	_t += delta
	_set_frame(int(_t * 4.0) % 2)


func _on_body_entered(b: Node) -> void:
	if _taken or not b.is_in_group("player"):
		return
	_taken = true
	set_deferred("monitoring", false)
	if b.has_method("grant_power"):
		b.grant_power(kind)
	if level != null:
		level.spawn_burst(global_position, _color(), 12)
		level.popup("¡%s!" % Progress.POWERUPS.get(kind, kind), global_position + Vector2(0, -14))
	queue_free()


func _color() -> Color:
	match kind:
		"flame":
			return Color("#ff8a2a")
		"freeze":
			return Color("#8fe0ff")
		"pulse":
			return Color("#fff06a")
		"barrier":
			return Color("#ffb030")
	return Color("#5adf7a")
