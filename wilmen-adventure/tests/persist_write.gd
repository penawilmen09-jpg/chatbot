extends SceneTree
## Primera ejecución del juego: crea progreso REAL en el guardado por defecto (user://wilmen_save.json).
## Se complementa con persist_check.gd, que se ejecuta en un proceso nuevo (el juego "cerrado y reabierto").

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var game = root.get_node("Game")
	var path: String = ProjectSettings.globalize_path(game.save_path)
	if FileAccess.file_exists(game.save_path):
		DirAccess.remove_absolute(path)
	game.reset_progress()
	game.register_complete(1, [true, false, true], 3210)
	game.register_complete(2, [false, false, false], 1500)
	game.register_complete(3, [false, true, false], 1800)
	game.set_setting("music_vol", 0.42)
	game.set_setting("sfx", false)
	game.save_game()
	print("persist_write: guardado en ", path, " (desbloqueado hasta el nivel ", game.highest_unlocked(), ")")
	quit(0 if game.highest_unlocked() == 4 else 1)
