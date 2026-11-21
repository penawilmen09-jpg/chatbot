class_name BackdropUtil
## Utilidades deterministas para los fondos de menú.

static func h(i: float) -> float:
	var v := sin(i * 12.9898) * 43758.5453
	return v - floorf(v)
