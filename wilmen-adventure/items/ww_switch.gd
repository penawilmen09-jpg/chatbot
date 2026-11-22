extends Area2D
## Interruptor de WILMEN WORLD: al tocarlo cambia el estado de su grupo y con él los bloques de color del escenario
## (los `(` / `[` están sólidos con el interruptor apagado; los `)` / `]` con él encendido). Glifos: / grupo 1 · \ grupo 2.

const A := preload("res://items/ww_atlas.gd")

var level = null
var group: int = 1
var _sprite: Sprite2D
var _cool: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(12, 12)
	cs.shape = rs
	cs.position = Vector2(0, 2)
	add_child(cs)
	_sprite = Sprite2D.new()
	add_child(_sprite)
	_refresh()
	if level != null:
		level.switch_changed.connect(_refresh)


func _refresh(_g: int = 0) -> void:
	var on: bool = level != null and bool(level.sw[group - 1])
	_sprite.texture = A.tex("sw%d_%s" % [group, "on" if on else "off"])


func _physics_process(delta: float) -> void:
	_cool = maxf(0.0, _cool - delta)
	if _cool > 0.0 or level == null or level.player == null or level.player.dead:
		return
	if overlaps_body(level.player):
		_cool = 0.7
		level.toggle_switch(group)
		Audio.play_sfx("click", 0.7)
