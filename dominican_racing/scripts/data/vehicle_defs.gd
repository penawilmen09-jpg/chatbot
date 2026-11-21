class_name VehicleDefs
## Definiciones de vehículos, estadísticas efectivas y costes de mejoras.

const UPGRADE_KEYS := ["motor", "suspension", "tires", "fuel", "traction"]
const UPGRADE_NAMES := {
	"motor": "MOTOR", "suspension": "SUSPENSIÓN", "tires": "NEUMÁTICOS",
	"fuel": "COMBUSTIBLE", "traction": "TRACCIÓN",
}
const UPGRADE_DESC := {
	"motor": "+10% potencia y +4% velocidad máx.",
	"suspension": "Más estabilidad y mejores aterrizajes.",
	"tires": "+ adherencia en cualquier terreno.",
	"fuel": "+20% capacidad del depósito.",
	"traction": "Más tracción delantera y agarre en pendientes.",
}
const MAX_UPG := 5
const UPG_FACTOR := {"motor": 1.2, "suspension": 0.8, "tires": 0.9, "fuel": 0.7, "traction": 1.1}

const LIST := [
	{
		"id": "jeep_dom", "name": "Jeep Dominicano", "kind": "jeep", "price": 0,
		"desc": "El todoterreno de la casa. Equilibrado y fiable.",
		"c1": Color(0.10, 0.32, 0.80), "c2": Color(0.85, 0.12, 0.18),
		"mass": 14.0, "L": 150.0, "H": 38.0, "wb": 104.0, "r": 25.0, "ay": 12.0, "travel": 30.0,
		"accel_g": 0.62, "vmax": 562.0, "mu": 1.25, "zeta": 0.50, "sag": 0.40,
		"fuel_cap": 100.0, "fuel_use": 1.0, "tilt": 5.0, "front": 0.35,
		"roof": Vector2(-10, -30), "roof_r": 14.0, "hull": Vector2(130, 38), "top": 56.0,
	},
	{
		"id": "jeep_clasico", "name": "Jeep Clásico", "kind": "classic", "price": 1200,
		"desc": "Estilo retro con motor de cuatro cilindros. Muy estable.",
		"c1": Color(0.45, 0.55, 0.25), "c2": Color(0.95, 0.85, 0.55),
		"mass": 13.0, "L": 146.0, "H": 38.0, "wb": 100.0, "r": 25.0, "ay": 12.0, "travel": 30.0,
		"accel_g": 0.55, "vmax": 546.0, "mu": 1.30, "zeta": 0.55, "sag": 0.40,
		"fuel_cap": 100.0, "fuel_use": 0.95, "tilt": 5.0, "front": 0.30,
		"roof": Vector2(-8, -30), "roof_r": 14.0, "hull": Vector2(126, 38), "top": 56.0,
	},
	{
		"id": "moto", "name": "Motocicleta", "kind": "moto", "price": 2500,
		"desc": "Ligera y veloz. Gran control en el aire pero fácil de volcar.",
		"c1": Color(0.95, 0.45, 0.05), "c2": Color(0.15, 0.15, 0.18),
		"mass": 6.0, "L": 104.0, "H": 20.0, "wb": 82.0, "r": 22.0, "ay": 8.0, "travel": 26.0,
		"accel_g": 0.80, "vmax": 671.0, "mu": 1.15, "zeta": 0.45, "sag": 0.40,
		"fuel_cap": 80.0, "fuel_use": 0.7, "tilt": 8.0, "front": 0.0,
		"roof": Vector2(-8, -42), "roof_r": 11.0, "hull": Vector2(56, 16), "top": 60.0,
	},
	{
		"id": "camioneta", "name": "Camioneta 4x4", "kind": "pickup", "price": 5000,
		"desc": "Tracción total y depósito grande. Sube casi todo.",
		"c1": Color(0.75, 0.10, 0.12), "c2": Color(0.92, 0.92, 0.95),
		"mass": 20.0, "L": 180.0, "H": 42.0, "wb": 124.0, "r": 28.0, "ay": 12.0, "travel": 32.0,
		"accel_g": 0.60, "vmax": 577.0, "mu": 1.40, "zeta": 0.50, "sag": 0.40,
		"fuel_cap": 130.0, "fuel_use": 1.25, "tilt": 4.2, "front": 0.80,
		"roof": Vector2(20, -34), "roof_r": 14.0, "hull": Vector2(160, 42), "top": 62.0,
	},
	{
		"id": "buggy", "name": "Buggy", "kind": "buggy", "price": 8000,
		"desc": "Suspensión larga para saltos largos y terreno roto.",
		"c1": Color(0.98, 0.78, 0.05), "c2": Color(0.10, 0.10, 0.12),
		"mass": 10.0, "L": 140.0, "H": 30.0, "wb": 100.0, "r": 27.0, "ay": 8.0, "travel": 40.0,
		"accel_g": 0.75, "vmax": 624.0, "mu": 1.20, "zeta": 0.60, "sag": 0.38,
		"fuel_cap": 90.0, "fuel_use": 0.9, "tilt": 6.0, "front": 0.20,
		"roof": Vector2(-6, -34), "roof_r": 13.0, "hull": Vector2(110, 30), "top": 54.0,
	},
	{
		"id": "quad", "name": "Quad ATV", "kind": "quad", "price": 12000,
		"desc": "Cuatro ruedas anchas con agarre excepcional.",
		"c1": Color(0.10, 0.70, 0.35), "c2": Color(0.12, 0.12, 0.14),
		"mass": 7.0, "L": 100.0, "H": 26.0, "wb": 76.0, "r": 21.0, "ay": 8.0, "travel": 26.0,
		"accel_g": 0.70, "vmax": 546.0, "mu": 1.50, "zeta": 0.50, "sag": 0.40,
		"fuel_cap": 70.0, "fuel_use": 0.7, "tilt": 6.5, "front": 0.60,
		"roof": Vector2(-6, -40), "roof_r": 11.0, "hull": Vector2(70, 24), "top": 58.0,
	},
	{
		"id": "monster", "name": "Monster Truck", "kind": "monster", "price": 20000,
		"desc": "Ruedas gigantes que aplastan cualquier obstáculo.",
		"c1": Color(0.55, 0.12, 0.70), "c2": Color(1.0, 0.85, 0.1),
		"mass": 30.0, "L": 190.0, "H": 50.0, "wb": 140.0, "r": 44.0, "ay": 4.0, "travel": 44.0,
		"accel_g": 0.65, "vmax": 499.0, "mu": 1.45, "zeta": 0.45, "sag": 0.40,
		"fuel_cap": 160.0, "fuel_use": 1.6, "tilt": 3.8, "front": 1.0,
		"roof": Vector2(10, -38), "roof_r": 15.0, "hull": Vector2(160, 46), "top": 66.0,
	},
	{
		"id": "deportivo", "name": "Deportivo", "kind": "sport", "price": 30000,
		"desc": "Aceleración brutal. Exige manos suaves en terreno roto.",
		"c1": Color(0.95, 0.10, 0.10), "c2": Color(0.10, 0.10, 0.12),
		"mass": 12.0, "L": 160.0, "H": 28.0, "wb": 112.0, "r": 22.0, "ay": 8.0, "travel": 22.0,
		"accel_g": 1.00, "vmax": 780.0, "mu": 1.10, "zeta": 0.60, "sag": 0.40,
		"fuel_cap": 90.0, "fuel_use": 1.2, "tilt": 5.0, "front": 0.0,
		"roof": Vector2(-6, -20), "roof_r": 11.0, "hull": Vector2(136, 26), "top": 42.0,
	},
	{
		"id": "camion", "name": "Camión Todoterreno", "kind": "truck", "price": 45000,
		"desc": "Pesado como una roca, nada lo detiene. Consume mucho.",
		"c1": Color(0.95, 0.55, 0.10), "c2": Color(0.20, 0.22, 0.28),
		"mass": 34.0, "L": 220.0, "H": 56.0, "wb": 150.0, "r": 34.0, "ay": 8.0, "travel": 36.0,
		"accel_g": 0.50, "vmax": 468.0, "mu": 1.50, "zeta": 0.55, "sag": 0.40,
		"fuel_cap": 200.0, "fuel_use": 1.7, "tilt": 3.0, "front": 0.70,
		"roof": Vector2(50, -42), "roof_r": 16.0, "hull": Vector2(190, 52), "top": 74.0,
	},
	{
		"id": "bus", "name": "Autobús Dominicano", "kind": "bus", "price": 65000,
		"desc": "La guagua más valiente del país. Enorme y sorprendentemente ágil.",
		"c1": Color(0.98, 0.80, 0.10), "c2": Color(0.80, 0.10, 0.15),
		"mass": 40.0, "L": 260.0, "H": 70.0, "wb": 180.0, "r": 30.0, "ay": 14.0, "travel": 34.0,
		"accel_g": 0.42, "vmax": 437.0, "mu": 1.40, "zeta": 0.60, "sag": 0.40,
		"fuel_cap": 220.0, "fuel_use": 1.9, "tilt": 2.6, "front": 0.30,
		"roof": Vector2(0, -50), "roof_r": 20.0, "hull": Vector2(230, 66), "top": 86.0,
	},
	{
		"id": "especial", "name": "Relámpago Caribeño", "kind": "special", "price": 0,
		"unlock_distance": 2500,
		"desc": "Prototipo especial. Se desbloquea al superar los 2500 m de distancia.",
		"c1": Color(0.10, 0.85, 0.95), "c2": Color(1.0, 0.25, 0.65),
		"mass": 12.0, "L": 160.0, "H": 30.0, "wb": 110.0, "r": 24.0, "ay": 8.0, "travel": 30.0,
		"accel_g": 1.05, "vmax": 858.0, "mu": 1.50, "zeta": 0.60, "sag": 0.40,
		"fuel_cap": 120.0, "fuel_use": 1.0, "tilt": 7.0, "front": 1.0,
		"roof": Vector2(-8, -24), "roof_r": 12.0, "hull": Vector2(136, 28), "top": 46.0,
	},
]

static func ids() -> Array:
	var out := []
	for d in LIST:
		out.append(d["id"])
	return out

static func get_def(id: String) -> Dictionary:
	for d in LIST:
		if d["id"] == id:
			return d
	return LIST[0]

static func default_upgrades() -> Dictionary:
	var u := {}
	for k in UPGRADE_KEYS:
		u[k] = 0
	return u

## Estadísticas físicas efectivas: definición base + mejoras.
static func effective(id: String, upg: Dictionary) -> Dictionary:
	var d: Dictionary = get_def(id).duplicate()
	var m: int = int(upg.get("motor", 0))
	var s: int = int(upg.get("suspension", 0))
	var t: int = int(upg.get("tires", 0))
	var f: int = int(upg.get("fuel", 0))
	var x: int = int(upg.get("traction", 0))
	d["accel_g"] = d["accel_g"] * (1.0 + 0.10 * m)
	d["vmax"] = d["vmax"] * (1.0 + 0.04 * m)
	d["sag"] = d["sag"] * (1.0 - 0.05 * s)
	d["zeta"] = d["zeta"] + 0.05 * s
	d["travel"] = d["travel"] * (1.0 + 0.03 * s)
	d["landing"] = 1.0 + 0.12 * s
	d["mu"] = d["mu"] + 0.09 * t + 0.03 * x
	d["fuel_cap"] = d["fuel_cap"] * (1.0 + 0.20 * f)
	d["front"] = minf(1.0, d["front"] + 0.15 * x)
	d["slope_assist"] = 1.0 + 0.08 * x
	return d

## Barras de estadísticas normalizadas 0..1 para la interfaz.
static func bars(st: Dictionary) -> Dictionary:
	return {
		"Potencia": clampf(st["accel_g"] / 1.5, 0.0, 1.0),
		"Velocidad": clampf(st["vmax"] / 1400.0, 0.0, 1.0),
		"Suspensión": clampf((st["travel"] / 60.0) * 0.6 + st["zeta"] * 0.5, 0.0, 1.0),
		"Tracción": clampf(st["mu"] / 2.0 * 0.7 + st["front"] * 0.3, 0.0, 1.0),
		"Combustible": clampf(st["fuel_cap"] / 300.0, 0.0, 1.0),
		"Peso": clampf(st["mass"] / 50.0, 0.0, 1.0),
	}

static func upgrade_cost(id: String, key: String, level: int) -> int:
	var d: Dictionary = get_def(id)
	var base: float = maxf(120.0, float(d["price"]) * 0.07)
	if d["id"] == "especial":
		base = 3000.0
	var c: float = base * float(UPG_FACTOR[key]) * pow(1.65, level)
	return int(round(c / 5.0) * 5.0)
