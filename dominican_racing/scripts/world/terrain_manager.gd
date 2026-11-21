class_name TerrainManager
extends Node2D
## Crea y libera tramos de terreno alrededor del jugador y dibuja la meta.

signal chunk_created(idx: int)

const AHEAD := 3600.0
const BEHIND := 2000.0

var gen: TerrainGen
var world: Dictionary
var seed_value := 1
var chunks: Dictionary = {}
var goal_x := -1.0
var _t := 0.0

func setup(w: Dictionary, difficulty: float, seed_val: int, growth := 0.0) -> void:
	world = w
	seed_value = seed_val
	gen = TerrainGen.new(w, difficulty, seed_val, growth)

func update_for(x: float) -> void:
	var lo := int(floor((x - BEHIND) / TerrainChunk.CHUNK_W))
	var hi := int(floor((x + AHEAD) / TerrainChunk.CHUNK_W))
	lo = maxi(lo, 0)
	for i in range(lo, hi + 1):
		if not chunks.has(i):
			var c := TerrainChunk.new()
			c.build(gen, world, i, seed_value)
			add_child(c)
			chunks[i] = c
			chunk_created.emit(i)
	for k in chunks.keys():
		if k < lo or k > hi + 2:
			chunks[k].queue_free()
			chunks.erase(k)

func set_goal(x: float) -> void:
	goal_x = x
	queue_redraw()

func _process(delta: float) -> void:
	if goal_x > 0.0:
		_t += delta
		queue_redraw()

func _draw() -> void:
	if goal_x <= 0.0:
		return
	var y := gen.y_at(goal_x)
	var pole := Color(0.9, 0.9, 0.92)
	draw_line(Vector2(goal_x - 150, y), Vector2(goal_x - 150, y - 260), pole, 10.0)
	draw_line(Vector2(goal_x + 150, y), Vector2(goal_x + 150, y - 260), pole, 10.0)
	for i in 20:
		for j in 2:
			var c := Color.WHITE if (i + j) % 2 == 0 else Color(0.08, 0.08, 0.1)
			draw_rect(Rect2(goal_x - 150 + i * 15.0, y - 260 + j * 15.0, 15, 15), c)
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(goal_x - 70, y - 190), "META", HORIZONTAL_ALIGNMENT_CENTER, 140, 44, Color(1, 0.9, 0.2))
	# tela de bandera ondeando
	for k in 8:
		var wy := sin(_t * 5.0 + k * 0.6) * 4.0
		draw_rect(Rect2(goal_x - 150 + k * 37.5, y - 150 + wy, 37.5, 24), Color(0.0, 0.17, 0.62) if k % 2 == 0 else Color(0.81, 0.07, 0.17))
