extends RefCounted
## Proveedor FALSO de anuncios: simula un anuncio recompensado y un banner sin SDK, sin red y sin anuncios reales.
## - interactive = true: muestra un cuadro de prueba con botones (completar / cerrar antes / fallar).
## - interactive = false: responde solo, según `behavior`; lo usan las pruebas automáticas.
##     "complete" recompensa y cierra · "close" cierra sin recompensa · "fail" error · "double" recompensa 2 veces
##     "late" recompensa y vuelve a recompensar tarde · "silent" no responde nunca

const UiTheme := preload("res://ui/ui_theme.gd")

var interactive: bool = false
var behavior: String = "complete"
var ready: bool = true
var shown_count: int = 0
var banner_shown: bool = false
var last_id: int = -1
var _dialog: CanvasLayer = null
var _banner: CanvasLayer = null


func _init(interactive_: bool = false) -> void:
	interactive = interactive_


func is_rewarded_ready() -> bool:
	return ready


func banner_height() -> float:
	return 18.0


func show_rewarded(ads, id: int) -> void:
	shown_count += 1
	last_id = id
	if interactive:
		_show_dialog(ads, id)
		return
	# respuesta asíncrona, como un SDK real
	ads.get_tree().process_frame.connect(func(): _auto(ads, id), CONNECT_ONE_SHOT)


func _auto(ads, id: int) -> void:
	match behavior:
		"complete":
			ads.on_ad_event(id, "rewarded")
			ads.on_ad_event(id, "closed")
		"close":
			ads.on_ad_event(id, "closed")
		"fail":
			ads.on_ad_event(id, "failed")
		"double":
			ads.on_ad_event(id, "rewarded")
			ads.on_ad_event(id, "rewarded")
			ads.on_ad_event(id, "closed")
		"late":
			ads.on_ad_event(id, "rewarded")
			ads.on_ad_event(id, "closed")
			ads.on_ad_event(id, "rewarded")
		_:
			pass  # "silent"


func replay(ads, event: String) -> void:
	## Para pruebas: reenvía un evento con el identificador de la última petición.
	ads.on_ad_event(last_id, event)


# ------------------------------------------------------ interfaz de prueba ---
func _show_dialog(ads, id: int) -> void:
	_close_dialog()
	_dialog = CanvasLayer.new()
	_dialog.layer = 100
	_dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	var o := Control.new()
	o.set_anchors_preset(Control.PRESET_FULL_RECT)
	o.theme = UiTheme.make()
	_dialog.add_child(o)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	o.add_child(dim)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	o.add_child(c)
	var p := PanelContainer.new()
	c.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	var t := UiTheme.label("ANUNCIO DE PRUEBA", 16, Color("#ffe97a"))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var l := UiTheme.label("(simulado: no es un anuncio real)", 10, Color("#cfc6ff"))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var choices := [["Ver completo (da la vida)", "rewarded"], ["Cerrar antes de terminar", "closed"], ["Simular fallo", "failed"]]
	for ch in choices:
		var b := UiTheme.button(str(ch[0]), Vector2(220, 32))
		var ev: String = str(ch[1])
		b.pressed.connect(func():
			_close_dialog()
			ads.on_ad_event(id, ev)
			if ev == "rewarded":
				ads.on_ad_event(id, "closed"))
		v.add_child(b)
	ads.get_tree().root.add_child.call_deferred(_dialog)


func _close_dialog() -> void:
	if _dialog != null and is_instance_valid(_dialog):
		_dialog.queue_free()
	_dialog = null


# ----------------------------------------------------------------- banner ---
func set_banner(ads, on: bool) -> void:
	banner_shown = on
	if _banner != null and is_instance_valid(_banner):
		_banner.queue_free()
	_banner = null
	if not on:
		return
	_banner = CanvasLayer.new()
	_banner.layer = 90
	var r := ColorRect.new()
	r.color = Color(0.1, 0.1, 0.16, 0.92)
	r.anchor_left = 0.0
	r.anchor_right = 1.0
	r.anchor_top = 1.0
	r.anchor_bottom = 1.0
	r.offset_top = -banner_height()
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.add_child(r)
	var l := UiTheme.label("BANNER DE PRUEBA (simulado)", 8, Color("#ffe97a"))
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	r.add_child(l)
	ads.get_tree().root.add_child.call_deferred(_banner)
