extends Control
## HUD mínimo: título, ayuda de teclado (solo PC) y FPS.

@onready var hint: Label = $Hint
@onready var fps: Label = $Fps


func _ready() -> void:
	var touch := DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	hint.visible = not touch
	hint.text = "A/D o ←/→ mover   Espacio/W saltar   Shift correr   R reiniciar posición"


func _process(_delta: float) -> void:
	fps.text = "%d FPS" % Engine.get_frames_per_second()
