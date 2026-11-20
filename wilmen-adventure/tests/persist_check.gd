extends SceneTree
## Segunda ejecución (proceso nuevo): comprueba que el progreso se conservó al cerrar y abrir el juego.

var _failed: int = 0


func _check(cond: bool, msg: String) -> void:
	print("  ", "ok   " if cond else "FALLO ", msg)
	if not cond:
		_failed += 1


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var game = root.get_node("Game")
	_check(game.highest_unlocked() == 4, "tras reabrir, el nivel 4 sigue siendo el disponible (%d)" % game.highest_unlocked())
	_check(game.is_unlocked(1) and game.is_unlocked(2) and game.is_unlocked(3) and game.is_unlocked(4), "niveles 1-4 desbloqueados")
	_check(not game.is_unlocked(5), "el nivel 5 sigue bloqueado")
	_check(game.get_record(1)["gems"] == [true, false, true] and int(game.get_record(1)["best"]) == 3210, "se conservan gemas y puntuación del nivel 1")
	_check(game.completed_count() == 3, "3 niveles completados")
	_check(absf(float(game.settings["music_vol"]) - 0.42) < 0.001 and not bool(game.settings["sfx"]), "se conservan los ajustes de audio")
	_check(not game.start_level(5) and game.start_level(4), "start_level respeta el progreso guardado")
	print("persist_check: ", "TODO OK" if _failed == 0 else "%d fallos" % _failed)
	quit(0 if _failed == 0 else 1)
