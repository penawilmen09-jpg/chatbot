class_name WorldDefs
## Mundos, niveles y recompensas.

const PX_PER_M := 24.0

const WORLDS := [
	{
		"id": 1, "name": "Campo Dominicano", "price": 0, "diff": 0.45, "max_slope": 22.0, "grip": 1.0,
		"desc": "Montañas verdes, palmeras, caminos rurales y puentes sobre el río.",
		"theme": "campo",
		"sky_top": Color(0.20, 0.55, 0.95), "sky_bot": Color(0.78, 0.92, 1.0),
		"ground": Color(0.50, 0.33, 0.18), "grass": Color(0.25, 0.70, 0.22), "ground_dark": Color(0.36, 0.22, 0.12),
		"far1": Color(0.55, 0.76, 0.72), "far2": Color(0.36, 0.64, 0.48), "far3": Color(0.20, 0.52, 0.32),
		"dust": Color(0.75, 0.6, 0.4, 0.6), "water": Color(0.15, 0.55, 0.85),
		"weights": {"rolling": 5, "flat": 2, "bumps": 2, "ramp": 1, "bridge": 1, "steep": 0, "dune": 0},
		"names": ["Camino de Palmas", "Valle del Conuco", "Puente del Río", "Loma Alta", "Gran Carrera Campesina"],
		"rec": ["jeep_dom", "jeep_clasico", "camioneta", "jeep_dom", "buggy"],
	},
	{
		"id": 2, "name": "Montañas", "price": 3000, "diff": 0.95, "max_slope": 33.0, "grip": 1.0,
		"desc": "Pendientes pronunciadas, acantilados, saltos y caminos difíciles.",
		"theme": "montana",
		"sky_top": Color(0.35, 0.45, 0.80), "sky_bot": Color(0.90, 0.80, 0.85),
		"ground": Color(0.45, 0.40, 0.38), "grass": Color(0.35, 0.55, 0.30), "ground_dark": Color(0.28, 0.25, 0.25),
		"far1": Color(0.62, 0.64, 0.85), "far2": Color(0.45, 0.48, 0.70), "far3": Color(0.30, 0.34, 0.52),
		"dust": Color(0.7, 0.7, 0.72, 0.6), "water": Color(0.2, 0.45, 0.7),
		"weights": {"rolling": 3, "flat": 1, "bumps": 2, "ramp": 2, "bridge": 1, "steep": 4, "dune": 0},
		"names": ["Sendero del Pico", "Cresta Nublada", "Acantilado Rojo", "Paso del Cóndor", "Cima Duarte"],
		"rec": ["camioneta", "buggy", "quad", "monster", "camion"],
	},
	{
		"id": 3, "name": "Desierto", "price": 8000, "diff": 1.25, "max_slope": 28.0, "grip": 0.85,
		"desc": "Dunas enormes, rocas y arena suelta que reduce el agarre.",
		"theme": "desierto",
		"sky_top": Color(0.98, 0.60, 0.25), "sky_bot": Color(1.0, 0.92, 0.65),
		"ground": Color(0.90, 0.70, 0.38), "grass": Color(0.98, 0.82, 0.50), "ground_dark": Color(0.78, 0.55, 0.28),
		"far1": Color(0.98, 0.78, 0.55), "far2": Color(0.90, 0.62, 0.40), "far3": Color(0.80, 0.50, 0.32),
		"dust": Color(0.95, 0.8, 0.5, 0.7), "water": Color(0.2, 0.6, 0.7),
		"weights": {"rolling": 1, "flat": 1, "bumps": 2, "ramp": 2, "bridge": 0, "steep": 1, "dune": 5},
		"names": ["Dunas Doradas", "Tormenta de Arena", "Oasis Perdido", "Cañón Seco", "Mar de Arena"],
		"rec": ["buggy", "quad", "camioneta", "monster", "especial"],
	},
	{
		"id": 4, "name": "Ciudad", "price": 15000, "diff": 1.55, "max_slope": 20.0, "grip": 1.05,
		"desc": "Carreteras, edificios, rampas y obstáculos urbanos.",
		"theme": "ciudad",
		"sky_top": Color(0.15, 0.20, 0.45), "sky_bot": Color(0.95, 0.55, 0.45),
		"ground": Color(0.30, 0.31, 0.36), "grass": Color(0.55, 0.56, 0.62), "ground_dark": Color(0.18, 0.19, 0.23),
		"far1": Color(0.45, 0.40, 0.62), "far2": Color(0.30, 0.28, 0.50), "far3": Color(0.18, 0.17, 0.34),
		"dust": Color(0.8, 0.8, 0.85, 0.5), "water": Color(0.15, 0.3, 0.55),
		"weights": {"rolling": 2, "flat": 3, "bumps": 4, "ramp": 3, "bridge": 2, "steep": 0, "dune": 0},
		"names": ["Avenida Central", "Malecón Nocturno", "Hora Pico", "Zona Colonial", "Gran Autopista"],
		"rec": ["deportivo", "jeep_dom", "buggy", "bus", "deportivo"],
	},
	{
		"id": 5, "name": "Zona Tropical", "price": 25000, "diff": 1.85, "max_slope": 26.0, "grip": 0.95,
		"desc": "Selva densa, ríos, puentes de madera y caminos selváticos.",
		"theme": "tropical",
		"sky_top": Color(0.05, 0.55, 0.60), "sky_bot": Color(0.75, 0.98, 0.80),
		"ground": Color(0.38, 0.26, 0.14), "grass": Color(0.10, 0.60, 0.25), "ground_dark": Color(0.24, 0.16, 0.09),
		"far1": Color(0.45, 0.78, 0.60), "far2": Color(0.20, 0.60, 0.40), "far3": Color(0.08, 0.40, 0.28),
		"dust": Color(0.5, 0.42, 0.28, 0.6), "water": Color(0.05, 0.62, 0.65),
		"weights": {"rolling": 3, "flat": 1, "bumps": 3, "ramp": 2, "bridge": 3, "steep": 2, "dune": 0},
		"names": ["Selva Esmeralda", "Río Yaque", "Cascada Escondida", "Manglar Profundo", "Corazón Tropical"],
		"rec": ["camioneta", "buggy", "monster", "camion", "especial"],
	},
]

const LEVELS_PER_WORLD := 5

static func world(id: int) -> Dictionary:
	return WORLDS[clampi(id, 1, WORLDS.size()) - 1]

static func level(world_id: int, index: int) -> Dictionary:
	var w: Dictionary = world(world_id)
	var li: int = clampi(index, 1, LEVELS_PER_WORLD)
	var goal_m: int = int(round((500.0 + 300.0 * (li - 1) + 120.0 * (li - 1) * (li - 1)) * (1.0 + 0.18 * (world_id - 1)) / 50.0) * 50.0)
	var reward: int = int(round(goal_m * 0.5 * (1.0 + 0.35 * (world_id - 1)) / 10.0) * 10.0)
	return {
		"world": world_id, "index": li, "key": key(world_id, li),
		"name": w["names"][li - 1],
		"goal_m": goal_m,
		"coin_goal": 15 + 10 * li + 8 * (world_id - 1),
		"reward": reward,
		"bonus": int(round(reward * 0.3 / 10.0) * 10.0),
		"difficulty": float(w["diff"]) + 0.14 * (li - 1),
		"rec": w["rec"][li - 1],
		"seed": 1000 * world_id + 37 * li + 11,
	}

static func key(world_id: int, index: int) -> String:
	return "w%d_l%d" % [world_id, index]

## Distancia en metros a partir de píxeles.
static func to_m(px: float) -> float:
	return maxf(0.0, px / PX_PER_M)

## Cálculo único de recompensas de fin de partida.
## info: {dist_m, coins, completed, level (Dictionary o vacío), first_time, coins_goal_met, new_record, infinite}
static func calc_rewards(info: Dictionary) -> Dictionary:
	var lines := []
	var total := 0
	var coins: int = int(info.get("coins", 0))
	var dist_m: int = int(floor(float(info.get("dist_m", 0.0))))
	var dist_reward: int = int(floor(dist_m * 0.5))
	lines.append(["Monedas recogidas", coins])
	lines.append(["Recompensa por distancia", dist_reward])
	total += coins + dist_reward
	var lvl: Dictionary = info.get("level", {})
	if info.get("completed", false) and not lvl.is_empty():
		var r: int = int(lvl["reward"])
		if not info.get("first_time", false):
			r = int(r * 0.25)
		lines.append(["Nivel completado" if info.get("first_time", false) else "Nivel repetido (25%)", r])
		total += r
		if info.get("coins_goal_met", false) and info.get("coin_bonus_new", false):
			lines.append(["Objetivo de monedas", int(lvl["bonus"])])
			total += int(lvl["bonus"])
	if info.get("new_record", false) and dist_m > 20:
		var rb: int = 50 + int(dist_m * 0.1)
		lines.append(["¡Nuevo récord!", rb])
		total += rb
	return {"lines": lines, "total": total}
