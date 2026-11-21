class_name BiomeDefs
## Biomas del recorrido infinito. Cada partida los encadena en orden aleatorio con transiciones suaves.

const LIST := [
	{
		"id": "campo", "name": "Campo Dominicano", "slope": 22.0, "grip": 1.0,
		"sky_top": Color(0.16, 0.52, 0.96), "sky_bot": Color(0.80, 0.94, 1.0),
		"ground": Color(0.55, 0.36, 0.20), "ground_dark": Color(0.34, 0.20, 0.11), "grass": Color(0.30, 0.74, 0.20),
		"far1": Color(0.62, 0.80, 0.84), "far2": Color(0.40, 0.68, 0.52), "far3": Color(0.22, 0.54, 0.30),
		"dust": Color(0.78, 0.62, 0.42, 0.65), "water": Color(0.16, 0.56, 0.86),
		"shape": Vector3(1.0, 0.0, 0.0),
		"weights": {"rolling": 5, "flat": 2, "bumps": 2, "ramp": 1, "bridge": 1, "steep": 0, "dune": 0, "valley": 1, "longslope": 2},
		"decor": {"palm": 4.0, "house": 1.3, "bush": 3.0, "banana": 1.0, "rock": 0.6, "flowers": 2.0, "tree": 1.0},
	},
	{
		"id": "tropical", "name": "Montañas Tropicales", "slope": 28.0, "grip": 0.95,
		"sky_top": Color(0.05, 0.56, 0.62), "sky_bot": Color(0.76, 0.98, 0.82),
		"ground": Color(0.40, 0.27, 0.15), "ground_dark": Color(0.24, 0.16, 0.09), "grass": Color(0.08, 0.62, 0.28),
		"far1": Color(0.50, 0.80, 0.66), "far2": Color(0.20, 0.62, 0.42), "far3": Color(0.07, 0.40, 0.28),
		"dust": Color(0.50, 0.42, 0.28, 0.6), "water": Color(0.05, 0.64, 0.68),
		"shape": Vector3(0.45, 0.55, 0.0),
		"weights": {"rolling": 3, "flat": 1, "bumps": 3, "ramp": 2, "bridge": 3, "steep": 3, "dune": 0, "valley": 2, "longslope": 2},
		"decor": {"palm": 4.0, "banana": 3.0, "fern": 3.0, "bush": 1.5, "rock": 1.0, "tree": 1.5},
	},
	{
		"id": "rural", "name": "Zona Rural", "slope": 18.0, "grip": 1.0,
		"sky_top": Color(0.42, 0.66, 0.96), "sky_bot": Color(1.0, 0.94, 0.78),
		"ground": Color(0.60, 0.42, 0.22), "ground_dark": Color(0.38, 0.25, 0.12), "grass": Color(0.62, 0.78, 0.22),
		"far1": Color(0.78, 0.82, 0.78), "far2": Color(0.62, 0.74, 0.50), "far3": Color(0.46, 0.62, 0.32),
		"dust": Color(0.82, 0.68, 0.44, 0.65), "water": Color(0.22, 0.56, 0.78),
		"shape": Vector3(1.0, 0.0, 0.0),
		"weights": {"rolling": 4, "flat": 3, "bumps": 3, "ramp": 1, "bridge": 1, "steep": 0, "dune": 0, "valley": 1, "longslope": 3},
		"decor": {"house": 2.2, "fence": 3.0, "hay": 2.0, "bush": 2.0, "tree": 1.5, "flowers": 2.0, "palm": 0.6},
	},
	{
		"id": "desierto", "name": "Desierto", "slope": 27.0, "grip": 0.86,
		"sky_top": Color(0.96, 0.58, 0.24), "sky_bot": Color(1.0, 0.92, 0.66),
		"ground": Color(0.92, 0.72, 0.40), "ground_dark": Color(0.76, 0.52, 0.26), "grass": Color(0.99, 0.84, 0.52),
		"far1": Color(0.99, 0.80, 0.58), "far2": Color(0.92, 0.64, 0.42), "far3": Color(0.82, 0.52, 0.32),
		"dust": Color(0.96, 0.82, 0.52, 0.7), "water": Color(0.2, 0.62, 0.72),
		"shape": Vector3(0.0, 0.1, 0.9),
		"weights": {"rolling": 1, "flat": 1, "bumps": 2, "ramp": 2, "bridge": 0, "steep": 1, "dune": 5, "valley": 1, "longslope": 2},
		"decor": {"cactus": 3.0, "rock": 3.0, "palm": 0.3, "skull": 0.5, "dry": 1.5},
	},
	{
		"id": "bosque", "name": "Bosque", "slope": 26.0, "grip": 0.98,
		"sky_top": Color(0.28, 0.50, 0.78), "sky_bot": Color(0.84, 0.94, 0.90),
		"ground": Color(0.40, 0.30, 0.20), "ground_dark": Color(0.24, 0.17, 0.11), "grass": Color(0.20, 0.52, 0.24),
		"far1": Color(0.52, 0.70, 0.70), "far2": Color(0.28, 0.52, 0.44), "far3": Color(0.12, 0.34, 0.28),
		"dust": Color(0.55, 0.46, 0.34, 0.6), "water": Color(0.14, 0.46, 0.68),
		"shape": Vector3(0.3, 0.7, 0.0),
		"weights": {"rolling": 3, "flat": 1, "bumps": 3, "ramp": 2, "bridge": 2, "steep": 3, "dune": 0, "valley": 2, "longslope": 2},
		"decor": {"pine": 5.0, "tree": 3.0, "rock": 2.0, "bush": 2.0, "fern": 1.5, "log": 1.0},
	},
	{
		"id": "carretera", "name": "Carretera de Montaña", "slope": 24.0, "grip": 1.05,
		"sky_top": Color(0.30, 0.42, 0.80), "sky_bot": Color(0.98, 0.78, 0.66),
		"ground": Color(0.34, 0.34, 0.38), "ground_dark": Color(0.20, 0.20, 0.25), "grass": Color(0.56, 0.57, 0.62),
		"far1": Color(0.70, 0.66, 0.86), "far2": Color(0.50, 0.50, 0.72), "far3": Color(0.32, 0.34, 0.54),
		"dust": Color(0.82, 0.82, 0.86, 0.5), "water": Color(0.18, 0.40, 0.66),
		"shape": Vector3(0.1, 0.9, 0.0),
		"weights": {"rolling": 3, "flat": 2, "bumps": 1, "ramp": 2, "bridge": 2, "steep": 3, "dune": 0, "valley": 1, "longslope": 3},
		"decor": {"rail": 5.0, "lamp": 1.5, "cone": 1.0, "rock": 1.5, "pine": 1.5, "sign": 1.2, "bush": 0.8},
		"road": true,
	},
]

static func get_biome(i: int) -> Dictionary:
	return LIST[posmod(i, LIST.size())]
