extends "res://items/goal.gd"
## Salida secreta de un nivel de WILMEN WORLD (glifo `O`): termina el nivel y abre un camino oculto en el mapa.


func _ready() -> void:
	super()
	modulate = Color(0.85, 0.55, 1.0)


func _on_body_entered(b: Node) -> void:
	if active and b.is_in_group("player") and level != null:
		level.complete_secret()
