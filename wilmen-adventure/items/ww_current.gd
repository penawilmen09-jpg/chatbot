extends Area2D
## Corriente de agua: empuja al jugador mientras está dentro. `:` hacia la derecha · `.` hacia la izquierda · `,` burbujas
## que lo elevan. Los tramos contiguos de la misma letra forman una sola zona.

const A := preload("res://items/ww_atlas.gd")
const PUSH := 80.0  # px/s de arrastre horizontal

var level = null
var dir: String = "right"
var w: int = 1
var h: int = 1
var _t: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	z_index = 2
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(w * 16, h * 16)
	cs.shape = rs
	cs.position = Vector2(w * 8 - 8, h * 8 - 8)
	add_child(cs)


func _physics_process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if level == null or level.player == null or level.player.dead:
		return
	var p = level.player
	if overlaps_body(p):
		if dir == "up":
			p.env_wind = true
		else:
			p.env_current = PUSH if dir == "right" else -PUSH


func _draw() -> void:
	var rect := Rect2(-8, -8, w * 16, h * 16)
	draw_rect(rect, Color(0.35, 0.65, 1.0, 0.16))
	var step: float = 16.0
	if dir == "up":
		for i in range(w):
			for j in range(h + 1):
				var y: float = rect.position.y + h * 16.0 - fposmod(_t * 40.0 + j * step, h * 16.0 + step)
				draw_texture(A.tex("bubble"), Vector2(rect.position.x + i * 16, y), Color(1, 1, 1, 0.8))
	else:
		var sgn: float = 1.0 if dir == "right" else -1.0
		for j in range(h):
			for i in range(w + 1):
				var x: float = rect.position.x + fposmod(sgn * _t * 36.0 + i * step, w * 16.0 + step)
				var tex := A.tex("cur_arrow")
				if sgn < 0.0:
					draw_set_transform(Vector2(x + 16, rect.position.y + j * 16), 0.0, Vector2(-1, 1))
					draw_texture(tex, Vector2.ZERO, Color(1, 1, 1, 0.9))
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				else:
					draw_texture(tex, Vector2(x, rect.position.y + j * 16), Color(1, 1, 1, 0.9))
