extends Node
## Escena principal: conecta nivel, jugador y cámara.

@onready var level: Node3D = $Level
@onready var player: Player = $Player
@onready var camera: SideCamera = $SideCamera


func _ready() -> void:
	player.set_bounds(level.bounds_left, level.bounds_right)
	camera.set_bounds(level.bounds_left, level.bounds_right)
	player.set_spawn(level.spawn_point)
	player.respawned.connect(camera.snap_to_target)
	camera.snap_to_target()
