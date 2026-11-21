class_name WorldDefs
## Constantes de escala y cálculo de recompensas del recorrido infinito.

const PX_PER_M := 24.0

## Distancia en metros a partir de píxeles.
static func to_m(px: float) -> float:
	return maxf(0.0, px / PX_PER_M)

## Dificultad según la distancia (m): 0.45 al inicio, crece gradualmente y se estabiliza.
static func difficulty_at_m(m: float) -> float:
	return 0.45 + 1.9 * clampf(m / 3500.0, 0.0, 1.0) + 0.25 * clampf((m - 3500.0) / 6000.0, 0.0, 1.0)

## Recompensas de fin de partida. info: {dist_m, coins, new_record}
static func calc_rewards(info: Dictionary) -> Dictionary:
	var lines := []
	var total := 0
	var coins: int = int(info.get("coins", 0))
	var dist_m: int = int(floor(float(info.get("dist_m", 0.0))))
	var dist_reward: int = int(floor(dist_m * 0.5))
	lines.append(["Monedas recogidas", coins])
	lines.append(["Recompensa por distancia", dist_reward])
	total += coins + dist_reward
	if info.get("new_record", false) and dist_m > 20:
		var rb: int = 50 + int(dist_m * 0.1)
		lines.append(["¡Nuevo récord!", rb])
		total += rb
	return {"lines": lines, "total": total}
