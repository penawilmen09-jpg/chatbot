class_name ResultsPanel
extends Control
## Pantalla de resultados al terminar una partida.

signal retry
signal garage
signal menu
signal next_level

func build(d: Dictionary) -> void:
	UIKit.fit(self)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.04, 0.12, 0.72)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var p := UIKit.panel(UIKit.NAVY, 28, 22)
	p.custom_minimum_size = Vector2(760, 0)
	center.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	UIKit.inner(p).add_child(v)
	var completed: bool = d["completed"]
	var title := UIKit.label("¡NIVEL COMPLETADO!" if completed else _reason_text(d["reason"]), 46, UIKit.GOLD if completed else Color(1.0, 0.45, 0.4))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	if completed or d["new_record"]:
		var sub := UIKit.label("¡NUEVO RÉCORD DE DISTANCIA!" if d["new_record"] else "", 28, Color(0.5, 1.0, 0.6))
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(sub)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 4)
	v.add_child(grid)
	_row(grid, "Distancia recorrida", "%d m" % int(d["dist_m"]), Color.WHITE)
	_row(grid, "Monedas recogidas", str(d["coins"]), UIKit.GOLD)
	_row(grid, "Récord anterior", "%d m" % int(d["prev_best"]), Color(0.75, 0.82, 1.0))
	_row(grid, "Puntuación", str(d["score"]), Color.WHITE)
	v.add_child(HSeparator.new())
	var lines: Array = d["lines"]
	var g2 := GridContainer.new()
	g2.columns = 2
	g2.add_theme_constant_override("h_separation", 40)
	v.add_child(g2)
	for ln in lines:
		_row(g2, ln[0], "+%d" % ln[1], Color(0.7, 1.0, 0.7))
	var tot := HBoxContainer.new()
	tot.alignment = BoxContainer.ALIGNMENT_CENTER
	tot.add_theme_constant_override("separation", 10)
	tot.add_child(UIKit.label("RECOMPENSA FINAL:", 32, Color.WHITE))
	tot.add_child(UIKit.CoinIcon.new(40.0))
	tot.add_child(UIKit.label("+%d" % d["total"], 40, UIKit.GOLD))
	v.add_child(tot)
	var br := HBoxContainer.new()
	br.alignment = BoxContainer.ALIGNMENT_CENTER
	br.add_theme_constant_override("separation", 14)
	v.add_child(br)
	var again := UIKit.button("VOLVER A JUGAR", UIKit.GREEN, Vector2(210, 62), 22)
	again.pressed.connect(func(): retry.emit())
	br.add_child(again)
	if completed and d["has_next"]:
		var nx := UIKit.button("SIGUIENTE NIVEL", UIKit.ORANGE, Vector2(210, 62), 22)
		nx.pressed.connect(func(): next_level.emit())
		br.add_child(nx)
	var gar := UIKit.button("GARAJE", UIKit.BLUE, Vector2(150, 62), 22)
	gar.pressed.connect(func(): garage.emit())
	br.add_child(gar)
	var mn := UIKit.button("MENÚ PRINCIPAL", UIKit.GRAY, Vector2(200, 62), 22)
	mn.pressed.connect(func(): menu.emit())
	br.add_child(mn)
	await get_tree().process_frame
	UIKit.pop_in(p)

func _reason_text(r: String) -> String:
	match r:
		"fuel": return "SIN COMBUSTIBLE"
		"flip": return "¡VOLCADO!"
		"stuck": return "ATASCADO"
	return "FIN DE LA PARTIDA"

func _row(grid: GridContainer, a: String, b: String, col: Color) -> void:
	var la := UIKit.label(a, 24, Color(0.85, 0.9, 1.0), false)
	la.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(la)
	var lb := UIKit.label(b, 26, col)
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grid.add_child(lb)
