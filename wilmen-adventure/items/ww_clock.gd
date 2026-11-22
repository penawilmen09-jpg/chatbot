extends Area2D
## Reloj de WILMEN WORLD: al recogerlo suma segundos al tiempo del nivel (pequeño +15 s, grande +30 s).

const SHEET := preload("res://assets/items/ww_items.png")

var seconds: int = 15
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
	tw.tween_property(_sprite, "position:y", -2.0, 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_sprite, "position:y", 2.0, 0.6).set_trans(Tween.TRANS_SINE)


func _set_frame(f: int) -> void:
	var at := AtlasTexture.new()
	at.atlas = SHEET
	at.region = Rect2(((2 if seconds >= 30 else 0) + f) * 16, 0, 16, 16)
	_sprite.texture = at


func _process(delta: float) -> void:
	_t += delta
	_set_frame(int(_t * 3.0) % 2)


func _on_body_entered(b: Node) -> void:
	if _taken or not b.is_in_group("player"):
		return
	_taken = true
	set_deferred("monitoring", false)
	if level != null:
		level.add_time(float(seconds))
		level.spawn_burst(global_position, Color("#8fe0ff") if seconds < 30 else Color("#ffd23a"), 8)
		level.popup("+%d s" % seconds, global_position + Vector2(0, -14))
	Audio.play_sfx("powerup", 1.3)
	queue_free()
