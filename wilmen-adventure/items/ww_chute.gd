extends Node2D
## Tolva de troncos: cada pocos segundos tiembla (aviso) y suelta un tronco rodante hacia un lado. Glifos: & izquierda · ' derecha.

const A := preload("res://items/ww_atlas.gd")
const LogScript := preload("res://items/ww_log.gd")
const PERIOD := 5.2
const WARN := 1.0

var level = null
var dir: int = -1
var _sprite: Sprite2D
var _t: float = 0.0


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = A.tex("chute")
	_sprite.flip_h = dir > 0
	add_child(_sprite)
	_t = float(int(global_position.x) % 11) * 0.37


func _physics_process(delta: float) -> void:
	_t += delta
	var ph: float = fposmod(_t, PERIOD)
	var warn: bool = ph > PERIOD - WARN
	_sprite.texture = A.tex("chute_warn" if warn else "chute")
	_sprite.position.x = (randf_range(-1.0, 1.0) if warn else 0.0)
	if ph < delta and _t > delta * 2.0:
		spawn()


func spawn() -> void:
	if level == null:
		return
	var lg = LogScript.new()
	lg.dir = dir
	lg.level = level
	lg.position = position + Vector2(dir * 12.0, 1.0)
	level.add_child(lg)
	Audio.play_sfx("rock_roll", 1.1)
