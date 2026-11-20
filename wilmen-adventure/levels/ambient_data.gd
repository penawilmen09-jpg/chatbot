extends RefCounted
## Efectos ambientales por mundo y zona (nieve, hojas, brasas, vapor, nubes, engranajes...).
## Pocas partículas a propósito: la prueba de rendimiento limita el total por nivel (ver tests/smoke_test.gd).

const MAX_PARTICLES := 220


static func _fall(amount: int, color: Color, life: float, vmin: float, vmax: float, smin: float = 1.0, smax: float = 2.0, sway: float = 14.0, wind: float = 0.0) -> Dictionary:
	return {"amount": amount, "color": color, "life": life, "dir": Vector2(0, 1), "spread": 12.0, "vmin": vmin, "vmax": vmax,
		"grav": Vector2(wind, 0), "smin": smin, "smax": smax, "where": "top", "tangent": sway}


static func _rise(amount: int, color: Color, life: float, vmin: float, vmax: float, smin: float = 1.0, smax: float = 2.0, sway: float = 10.0) -> Dictionary:
	return {"amount": amount, "color": color, "life": life, "dir": Vector2(0, -1), "spread": 18.0, "vmin": vmin, "vmax": vmax,
		"smin": smin, "smax": smax, "where": "bottom", "tangent": sway}


static func _blow(amount: int, color: Color, life: float, vmin: float, vmax: float, smin: float = 1.0, smax: float = 2.5) -> Dictionary:
	return {"amount": amount, "color": color, "life": life, "dir": Vector2(1, 0.08), "spread": 6.0, "vmin": vmin, "vmax": vmax,
		"smin": smin, "smax": smax, "where": "left"}


static func _float(amount: int, color: Color, life: float, speed: float, smin: float = 1.0, smax: float = 2.0) -> Dictionary:
	return {"amount": amount, "color": color, "life": life, "dir": Vector2(0, -1), "spread": 180.0, "vmin": speed * 0.3, "vmax": speed,
		"smin": smin, "smax": smax, "where": "area", "tangent": 6.0, "damping": 0.5}


static func for_level(world: int, zone: int, idx: int) -> Dictionary:
	var c: Dictionary = {}
	var p: Array = []
	match world:
		1:
			c["clouds"] = 4 if zone < 2 else 2
			p.append(_fall(14, Color(0.45, 0.8, 0.3, 0.9), 7.0, 14.0, 26.0, 1.5, 3.0, 18.0, 6.0))  # hojas
			if zone >= 2:
				p.append(_float(18, Color(1, 0.95, 0.5, 0.85), 4.0, 8.0))  # luciérnagas al atardecer
		2:
			p.append(_float(26, Color(0.6, 0.95, 1.0, 0.8), 4.5, 10.0, 1.0, 2.0))  # destellos de cristal
			c["tint"] = Color(0.05, 0.0, 0.2, 0.10)
		3:
			c["clouds"] = 2
			c["cloud_color"] = Color(1, 0.92, 0.75, 0.55)
			p.append(_blow(30, Color(0.95, 0.82, 0.5, 0.55), 3.0, 70.0, 110.0, 1.0, 2.0))  # arena al viento
			if idx == 8:  # tormenta de arena
				p.append(_blow(110, Color(0.9, 0.72, 0.4, 0.6), 1.6, 150.0, 240.0, 1.0, 3.0))
				c["tint"] = Color(0.85, 0.6, 0.25, 0.22)
		4:
			p.append(_fall(50, Color(1, 1, 1, 0.9), 6.0, 16.0, 30.0, 1.0, 2.5, 20.0, 4.0))  # nieve
			if idx == 6 or idx == 9:  # ventisca
				p.append(_blow(70, Color(1, 1, 1, 0.75), 1.4, 130.0, 210.0, 1.0, 2.5))
				c["tint"] = Color(0.85, 0.92, 1.0, 0.16)
			if zone == 2:
				c["clouds"] = 3
		5:
			c["clouds"] = 2
			c["cloud_color"] = Color(0.35, 0.25, 0.5, 0.55)
			p.append(_float(10, Color(0.7, 1.0, 0.85, 0.5), 5.0, 8.0, 1.5, 3.0))  # fuegos fatuos
			p.append(_blow(8, Color(0.75, 0.7, 0.9, 0.18), 7.0, 14.0, 26.0, 6.0, 11.0))  # niebla
			c["tint"] = Color(0.1, 0.0, 0.15, 0.12)
		6:
			c["clouds"] = 7
			p.append(_blow(16, Color(1, 1, 1, 0.5), 2.2, 80.0, 130.0, 1.0, 2.0))  # viento
		7:
			p.append(_rise(46, Color(1, 0.55, 0.15, 0.95), 4.0, 22.0, 48.0, 1.0, 2.5, 14.0))  # brasas
			p.append(_fall(14, Color(0.6, 0.55, 0.55, 0.6), 6.0, 8.0, 16.0, 1.0, 2.0, 12.0, 4.0))  # ceniza
			c["tint"] = Color(0.5, 0.1, 0.0, 0.08)
		8:
			p.append(_float(22, Color(0.85, 1.0, 0.4, 0.85), 4.0, 8.0))  # luciérnagas
			p.append(_fall(9, Color(0.3, 0.7, 0.25, 0.9), 7.0, 12.0, 22.0, 1.5, 3.0, 16.0, 4.0))  # hojas
			if idx == 2 or zone == 1:
				c["tint"] = Color(0.3, 0.5, 0.25, 0.14)  # bruma del pantano
		9:
			c["gears"] = 4
			p.append(_rise(14, Color(0.85, 0.88, 0.9, 0.5), 4.5, 12.0, 22.0, 3.0, 6.0, 8.0))  # vapor
			p.append(_rise(12, Color(1, 0.7, 0.2, 0.95), 1.6, 40.0, 80.0, 1.0, 1.5, 6.0))  # chispas
		10:
			p.append(_float(34, Color(0.85, 0.6, 1.0, 0.8), 6.0, 8.0, 1.0, 2.5))  # polvo estelar
			p.append(_float(10, Color(1, 0.85, 0.3, 0.9), 5.0, 6.0, 1.5, 2.5))
	var total: int = 0
	for e in p:
		total += int(e["amount"])
	c["particles"] = p
	c["particle_total"] = total
	return c
