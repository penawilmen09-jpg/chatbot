extends Control
## Iconos dibujados por código: candado, marca de completado, estrella y corona.

@export var kind: String = "lock"  # lock | check | star | crown
@export var filled: bool = true
@export var tint: Color = Color.WHITE


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(14, 14)


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	var dim := Color(0.28, 0.26, 0.38, 0.9)
	match kind:
		"lock":
			var gold := Color("#e8c050") if filled else dim
			draw_arc(Vector2(w * 0.5, h * 0.42), w * 0.22, PI, TAU, 14, gold.darkened(0.2), maxf(1.5, w * 0.09))
			draw_rect(Rect2(w * 0.2, h * 0.42, w * 0.6, h * 0.5), gold)
			draw_rect(Rect2(w * 0.2, h * 0.42, w * 0.6, h * 0.5), Color("#1a1226"), false, 1.0)
			draw_circle(Vector2(w * 0.5, h * 0.64), w * 0.07, Color("#1a1226"))
		"check":
			var c := Color("#5adf7a") if filled else dim
			draw_circle(Vector2(w * 0.5, h * 0.5), minf(w, h) * 0.48, Color("#1a1226"))
			draw_polyline(PackedVector2Array([Vector2(w * 0.24, h * 0.52), Vector2(w * 0.43, h * 0.7), Vector2(w * 0.78, h * 0.3)]), c, maxf(1.8, w * 0.14))
		"star":
			var pts := PackedVector2Array()
			for i in range(10):
				var r: float = minf(w, h) * (0.5 if i % 2 == 0 else 0.22)
				var a: float = -PI * 0.5 + i * PI / 5.0
				pts.append(Vector2(w * 0.5 + cos(a) * r, h * 0.52 + sin(a) * r))
			draw_colored_polygon(pts, Color("#ffd23a") if filled else dim)
		"crown":
			var g := Color("#ffd23a") if filled else dim
			draw_colored_polygon(PackedVector2Array([
				Vector2(w * 0.08, h * 0.85), Vector2(w * 0.04, h * 0.25), Vector2(w * 0.3, h * 0.55),
				Vector2(w * 0.5, h * 0.12), Vector2(w * 0.7, h * 0.55), Vector2(w * 0.96, h * 0.25),
				Vector2(w * 0.92, h * 0.85)]), g)
			draw_rect(Rect2(w * 0.08, h * 0.85, w * 0.84, h * 0.1), g.darkened(0.25))
