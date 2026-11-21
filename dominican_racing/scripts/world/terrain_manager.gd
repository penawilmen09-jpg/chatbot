class_name TerrainManager
extends Node2D
## Crea y libera tramos de terreno alrededor del jugador (terreno infinito).

signal chunk_created(idx: int)

const AHEAD := 4200.0
const BEHIND := 2200.0

var gen: TerrainGen
var track: BiomeTrack
var seed_value := 1
var chunks: Dictionary = {}

func setup(seed_val: int) -> void:
	seed_value = seed_val
	track = BiomeTrack.new(seed_val)
	gen = TerrainGen.new(track, seed_val)

func update_for(x: float) -> void:
	var lo := maxi(int(floor((x - BEHIND) / TerrainChunk.CHUNK_W)), 0)
	var hi := int(floor((x + AHEAD) / TerrainChunk.CHUNK_W))
	for i in range(lo, hi + 1):
		if not chunks.has(i):
			var c := TerrainChunk.new()
			c.build(gen, track, i, seed_value)
			add_child(c)
			chunks[i] = c
			chunk_created.emit(i)
	for k in chunks.keys():
		if k < lo:
			chunks[k].queue_free()
			chunks.erase(k)
	gen.trim(x - BEHIND - 3000.0)
