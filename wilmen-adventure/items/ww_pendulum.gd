extends Node2D
## Péndulo de cuchilla: una hoja que oscila; hay que calcular el momento de pasar. Glifo: columna de `!` (arriba el anclaje;
## el largo es el número de celdas).

const A := preload("res://items/ww_atlas.gd")
const AMP := 1.0
const PERIOD := 2.4

var level = null
var length_px: float = 64.0
var _t: float = 0.0
var _blade: Sprite2D
var _area: Area2D
var _hit_cd: float = 0.0
var blade_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	z_index = 4
	_t = float(int(global_position.x) % 9) * 0.27
	var anchor := Sprite2D.new()
	anchor.texture = A.tex("pend_anchor")
	anchor.position = Vector2(0, -4)
	add_child(anchor)
	_blade = Sprite2D.new()
	_blade.texture = A.tex("pend_blade")
	add_child(_blade)
	_area = Area2D.new()
	_area.collision_layer = 0
	_area.collision_mask = 2
	var cs := CollisionShape2D.new()
	var ci := CircleShape2D.new()
	ci.radius = 7.0
	cs.shape = ci
	_area.add_child(cs)
	add_child(_area)
	_step()


func _step() -> void:
	var a: float = AMP * sin(TAU * _t / PERIOD)
	blade_pos = Vector2(sin(a), cos(a)) * length_px
	_blade.position = blade_pos
	_area.position = blade_pos
	_blade.rotation = a
	queue_redraw()


func _draw() -> void:
	draw_line(Vector2.ZERO, blade_pos, Color("#1a1226"), 3.0)
	draw_line(Vector2.ZERO, blade_pos, Color("#aeb4c4"), 1.0)


func _physics_process(delta: float) -> void:
	_t += delta
	_hit_cd = maxf(0.0, _hit_cd - delta)
	_step()
	if _hit_cd <= 0.0 and level != null and level.player != null and not level.player.dead and _area.overlaps_body(level.player):
		_hit_cd = 0.9
		level.player.hurt(1, to_global(blade_pos).x)
