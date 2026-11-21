class_name VehicleView
extends Node2D
## Dibuja el vehículo físico y genera partículas de polvo.

var vehicle: Vehicle
var t := 0.0
var dust_color := Color(0.7, 0.55, 0.35, 0.6)
var _dust: Array = []

func _ready() -> void:
	for i in 2:
		var p := CPUParticles2D.new()
		p.amount = 14
		p.lifetime = 0.55
		p.emitting = false
		p.local_coords = false
		p.direction = Vector2(-1, -1)
		p.spread = 35.0
		p.gravity = Vector2(0, -60)
		p.initial_velocity_min = 40.0
		p.initial_velocity_max = 130.0
		p.scale_amount_min = 3.0
		p.scale_amount_max = 7.0
		p.color = dust_color
		var grad := Gradient.new()
		grad.set_color(0, Color(1, 1, 1, 0.8))
		grad.set_color(1, Color(1, 1, 1, 0.0))
		p.color_ramp = grad
		add_child(p)
		_dust.append(p)

func _process(delta: float) -> void:
	t += delta
	if vehicle == null:
		return
	for i in 2:
		var w: Dictionary = vehicle.wheels[i]
		var p: CPUParticles2D = _dust[i]
		p.color = dust_color
		var on: bool = w["grounded"] and absf(float(w["vt"])) > 140.0 and vehicle.alive
		p.emitting = on
		p.position = vehicle.wheel_local_pos(i) + Vector2(0, vehicle.def["r"] * 0.8)
	queue_redraw()

func _draw() -> void:
	if vehicle == null:
		return
	var wp := []
	var ws := []
	for i in 2:
		wp.append(vehicle.wheel_local_pos(i))
		ws.append(vehicle.wheels[i]["spin"])
	# sombras de contacto bajo cada rueda apoyada
	for i in 2:
		var w: Dictionary = vehicle.wheels[i]
		if w["grounded"]:
			var gp: Vector2 = wp[i] + Vector2(0, vehicle.def["r"] * 0.95)
			var pts := PackedVector2Array()
			for k in 12:
				var a := TAU * k / 12.0
				pts.append(gp + Vector2(cos(a) * vehicle.def["r"] * 1.1, sin(a) * 5.0))
			draw_colored_polygon(pts, Color(0, 0, 0, 0.2))
	VehicleArt.draw(self, vehicle.def, wp, ws, t, vehicle.gas if vehicle.engine_on else 0.0)

## Explosión de chispas/polvo al chocar.
func burst(color: Color) -> void:
	var p := CPUParticles2D.new()
	p.amount = 40
	p.lifetime = 0.9
	p.one_shot = true
	p.explosiveness = 1.0
	p.local_coords = false
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.gravity = Vector2(0, 700)
	p.initial_velocity_min = 150.0
	p.initial_velocity_max = 450.0
	p.scale_amount_min = 3.0
	p.scale_amount_max = 8.0
	p.color = color
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.5).timeout.connect(p.queue_free)
