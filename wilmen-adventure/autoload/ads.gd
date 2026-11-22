extends Node
## Capa de anuncios recompensados y banner de WILMEN ADVENTURE (etapas 1-2: SOLO proveedor falso).
##
## - Está DESACTIVADA por defecto: sin proveedor, `can_offer_reward()` es falso y la interfaz no muestra ningún botón.
## - No hay SDK, ni red, ni anuncios reales. El único proveedor es `ads/mock_provider.gd` (pruebas).
## - No toca el guardado: lo único que puede cambiar es `Game.lives` (con `Game.add_life()`, la función de siempre).
## - Un anuncio = una petición con identificador. Solo el PRIMER evento «recompensa» de la petición activa da la vida;
##   los eventos repetidos, tardíos o sin petición se ignoran.

const MockProvider := preload("res://ads/mock_provider.gd")

## Interruptor general de anuncios reales. Sigue en false hasta que exista cuenta de AdMob y proveedor real.
const ADS_ENABLED := false
## Si un anuncio no responde en este tiempo, la petición se cancela SIN recompensa.
const REQUEST_TIMEOUT_MS := 180000

signal banner_changed

var provider = null  # objeto con is_rewarded_ready(), show_rewarded(ads, id), set_banner(host, on), banner_height()
var _next_id: int = 0
var _active_id: int = -1
var _active_cb: Callable = Callable()
var _started_ms: int = 0
var _banner_on: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Modo de pruebas (escritorio): godot --path . -- --ads-mock    (o variable de entorno WILMEN_ADS_MOCK=1)
	if OS.get_cmdline_user_args().has("--ads-mock") or OS.get_environment("WILMEN_ADS_MOCK") == "1":
		use_provider(MockProvider.new(true))
	elif ADS_ENABLED:
		push_warning("ADS_ENABLED=true pero todavía no hay proveedor real: los anuncios siguen desactivados.")


func use_provider(p) -> void:
	## Cambia el proveedor (nulo = anuncios desactivados). Cancela cualquier petición en curso sin recompensa.
	if _active_id != -1:
		_finish("failed")
	set_banner(false)
	provider = p
	banner_changed.emit()


func active() -> bool:
	return provider != null


func busy() -> bool:
	return _active_id != -1


func can_offer_reward() -> bool:
	return provider != null and _active_id == -1 and bool(provider.is_rewarded_ready())


func request_reward(on_done: Callable) -> bool:
	## Pide un anuncio recompensado. `on_done` recibe "rewarded" | "closed" | "failed". Devuelve false si no se pudo pedir.
	if not can_offer_reward():
		return false
	_next_id += 1
	_active_id = _next_id
	_active_cb = on_done
	_started_ms = Time.get_ticks_msec()
	provider.show_rewarded(self, _active_id)
	return true


func on_ad_event(id: int, event: String) -> void:
	## Los proveedores avisan aquí: "rewarded" (anuncio completado), "closed" (cerrado) o "failed" (error).
	if id != _active_id or _active_id == -1:
		return  # duplicado, tardío o de otra petición: se ignora
	match event:
		"rewarded":
			_finish("rewarded")
		"closed", "failed":
			_finish(event)
		_:
			pass


func _finish(result: String) -> void:
	var cb: Callable = _active_cb
	_active_id = -1  # se consume ANTES de entregar nada: un segundo evento ya no coincide
	_active_cb = Callable()
	if result == "rewarded":
		Game.add_life()  # +1 vida exactamente; add_life ya avisa al HUD (stats_changed)
	if cb.is_valid():
		cb.call(result)


func _process(_delta: float) -> void:
	if _active_id != -1 and Time.get_ticks_msec() - _started_ms > REQUEST_TIMEOUT_MS:
		_finish("failed")


# -------------------------------------------------------------- banner ----
func set_banner(on: bool) -> void:
	## El banner solo existe en el menú principal (title.gd lo enciende al entrar y lo apaga al salir).
	if provider == null:
		on = false
	if on == _banner_on:
		return
	_banner_on = on
	provider.set_banner(self, on)
	banner_changed.emit()


func banner_visible() -> bool:
	return _banner_on


func banner_reserved() -> float:
	## Alto (en unidades lógicas) que el menú debe dejar libre abajo mientras el banner está visible.
	if provider == null or not _banner_on:
		return 0.0
	return float(provider.banner_height())
