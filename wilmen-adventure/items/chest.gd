extends Area2D
## Cofre del tesoro: normal, raro, especial o secreto. Se abre al tocarlo; el botín (monedas, gemas especiales,
## poderes y cosméticos) se guarda para siempre en Progress. Un cofre ya abierto aparece vacío.

const SHEET := preload("res://assets/items/chests.png")
const KINDS := ["normal", "rare", "special", "secret"]
const COLORS := {"normal": Color("#ffd23a"), "rare": Color("#9ad4ff"), "special": Color("#e08aff"), "secret": Color("#ff5a6a")}

var kind: String = "normal"
var idx: int = 0
var level = null
var opened: bool = false

var _sprite: Sprite2D
var _glow: CPUParticles2D = null


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(14, 12)
	cs.shape = sh
	cs.position = Vector2(0, 2)
	add_child(cs)
	_sprite = Sprite2D.new()
	_sprite.position = Vector2(0, 0)
	add_child(_sprite)
	var n: int = level.number if level != null else 0
	opened = Progress.chest_opened(n, idx)
	_set_frame(opened)
	if opened:
		_sprite.modulate = Color(0.75, 0.75, 0.85)
		monitoring = false
	else:
		body_entered.connect(_on_body_entered)
		_sparkle()


func _set_frame(open_: bool) -> void:
	var k: int = maxi(0, KINDS.find(kind))
	var at := AtlasTexture.new()
	at.atlas = SHEET
	at.region = Rect2((k * 2 + (1 if open_ else 0)) * 16, 0, 16, 16)
	_sprite.texture = at


func _sparkle() -> void:
	## Destellos suaves: los cofres raros, especiales y secretos llaman más la atención.
	if kind == "normal":
		return
	_glow = CPUParticles2D.new()
	_glow.amount = 4 if kind == "rare" else 7
	_glow.lifetime = 1.2
	_glow.preprocess = 1.2
	_glow.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_glow.emission_rect_extents = Vector2(7, 4)
	_glow.direction = Vector2(0, -1)
	_glow.spread = 20.0
	_glow.initial_velocity_min = 6.0
	_glow.initial_velocity_max = 14.0
	_glow.gravity = Vector2.ZERO
	_glow.scale_amount_min = 1.0
	_glow.scale_amount_max = 1.8
	_glow.color = COLORS[kind]
	_glow.position = Vector2(0, -4)
	add_child(_glow)


func _on_body_entered(b: Node) -> void:
	if opened or not b.is_in_group("player"):
		return
	open()


func open() -> void:
	if opened:
		return
	opened = true
	set_deferred("monitoring", false)
	var n: int = level.number if level != null else 0
	var info: Dictionary = Progress.open_chest(n, idx, kind)
	_set_frame(true)
	Audio.play_sfx("chest_" + kind if kind != "normal" else "chest_open")
	var tw := create_tween()
	tw.tween_property(_sprite, "scale", Vector2(1.3, 0.75), 0.08)
	tw.tween_property(_sprite, "scale", Vector2(0.9, 1.25), 0.1)
	tw.tween_property(_sprite, "scale", Vector2.ONE, 0.1)
	if _glow != null:
		_glow.queue_free()
	if level != null:
		level.spawn_burst(global_position + Vector2(0, -4), COLORS[kind], 14 if kind != "normal" else 8)
		level.shake(2.0 if kind == "normal" else 4.0)
		if not info.is_empty():
			level.show_reward(info, global_position)
		if info.has("power") and level.player != null:
			level.player.grant_power(str(info["power"]))
