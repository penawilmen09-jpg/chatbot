extends "res://enemies/boss.gd"
## Guardián de la Espesura: jefe del castillo del Bosque Esmeralda (WILMEN WORLD 1-20). Reutiliza la base de los jefes de
## WILMEN ADVENTURE (movimiento, pisotón, daño, barra de vida) y añade TRES FASES con patrones propios que se encadenan,
## una erupción de raíces nueva y más vida (16 frente a los 5 del primer jefe original). No modifica a los jefes originales.
##   Fase 1: embestida, salto aplastante, raíces, lluvia de bellotas
##   Fase 2 (<= 2/3 de vida): se vuelve naranja, más rápido; añade abanico de bellotas y vuelo protegido
##   Fase 3 (<= 1/3 de vida): se pone rojo, aún más rápido; teletransporte, ráfagas y raíces seguidas

const BOSS_HP := 16
const PHASES := {
	1: ["charge", "roots", "slam", "rain"],
	2: ["roots", "fan", "charge", "hover", "slam", "rain"],
	3: ["roots", "teleport", "barrage", "slam", "roots", "charge", "rain"],
}
const TINTS := {1: Color(0.8, 1.0, 0.82), 2: Color(1.0, 0.86, 0.55), 3: Color(1.0, 0.6, 0.55)}

var phase: int = 1
var _phase_pending: bool = false


func _ready() -> void:
	super()
	max_hp = BOSS_HP
	hp = max_hp
	_sprite.scale = Vector2(1.2, 1.2)
	_sprite.self_modulate = TINTS[1]


func reset_fight() -> void:
	super()
	phase = 1
	_phase_pending = false
	_sprite.self_modulate = TINTS[1]


func hit_boss(dmg: int) -> void:
	var before: int = hp
	super(dmg)
	if hp < before and not dead:
		if phase == 1 and hp * 3 <= max_hp * 2:
			_enter_phase(2)
		elif phase == 2 and hp * 3 <= max_hp:
			_enter_phase(3)


func _enter_phase(p: int) -> void:
	phase = p
	_phase_pending = true
	speed_mult = 1.0 + 0.22 * float(p - 1)
	_sprite.self_modulate = TINTS[p]
	Audio.play_sfx("boss_roar")
	if level != null:
		level.shake(7.0)
		level.popup("¡FASE %d!" % p, global_position + Vector2(0, -50))


func _run_ai(g: int) -> void:
	await _wait(1.2, g)
	var i: int = 0
	while _alive(g):
		if _phase_pending:
			_phase_pending = false
			await _phase_roar(g)
			if not _alive(g):
				return
		var patterns: Array = PHASES[phase]
		var p: String = patterns[i % patterns.size()]
		i += 1
		match p:
			"charge":
				await _p_charge(g)
			"slam":
				await _p_slam(g)
			"rain":
				await _p_rain(g)
			"hover":
				await _p_hover(g)
			"teleport":
				await _p_teleport(g)
			"fan":
				await _p_fan(g)
			"barrage":
				await _p_barrage(g)
			"roots":
				await _p_roots(g)
		if not _alive(g):
			return
		mode = "idle"
		await _wait(1.0 - 0.2 * float(phase - 1), g)


func _phase_roar(g: int) -> void:
	mode = "roar"
	shielded = true
	_invuln_t = maxf(_invuln_t, 1.6)
	await _wait(1.1, g)
	shielded = false
	if _alive(g):
		await _p_roots(g)


func _p_roots(g: int) -> void:
	## Raíces: marcas en el suelo (aviso) y, medio segundo después, brotan pinchos hacia arriba. Más columnas en fases altas.
	mode = "roar"
	Audio.play_sfx("boss_roar")
	await _wait(0.5, g)
	var p = _get_player()
	var cols: int = 3 + phase
	var xs: Array = []
	for i in range(cols):
		var x: float = arena_left + 40.0 + (arena_right - arena_left - 80.0) * float(i) / float(maxi(1, cols - 1))
		if p != null and i == cols / 2:
			x = clampf(p.global_position.x, arena_left + 30.0, arena_right - 30.0)  # una cae justo donde estás
		xs.append(x)
	var y: float = _floor_y() - 4.0
	for x in xs:
		if level != null:
			level.spawn_burst(Vector2(x, y), Color("#7a5a30"), 6)
	await _wait(0.6, g)
	if not _alive(g):
		return
	Audio.play_sfx("slam")
	for x in xs:
		_shoot("thorn", Vector2(x, y), Vector2(0.0, -300.0), 900.0, 1.4)
	await _wait(1.0, g)
