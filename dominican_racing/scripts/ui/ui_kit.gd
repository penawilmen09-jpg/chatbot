class_name UIKit
## Utilidades de interfaz: botones, paneles, barras, etiquetas y animaciones comunes.

const NAVY := Color(0.07, 0.12, 0.27, 0.94)
const NAVY2 := Color(0.11, 0.18, 0.36, 0.96)
const GOLD := Color(1.0, 0.80, 0.15)
const GREEN := Color(0.16, 0.72, 0.34)
const RED := Color(0.86, 0.16, 0.2)
const BLUE := Color(0.14, 0.42, 0.88)
const ORANGE := Color(0.96, 0.52, 0.10)
const GRAY := Color(0.38, 0.42, 0.52)
const WHITE := Color(1, 1, 1)

## Ajusta un Control raíz (hijo de un CanvasLayer) al tamaño visible del viewport.
static func fit(c: Control) -> void:
	var vp := c.get_viewport()
	var apply := func():
		if is_instance_valid(c):
			c.position = Vector2.ZERO
			c.size = vp.get_visible_rect().size
	apply.call()
	vp.size_changed.connect(apply)

static func box(bg: Color, radius := 18, border := Color(0, 0, 0, 0), bw := 0, shadow := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.border_color = border
	s.set_border_width_all(bw)
	if shadow > 0:
		s.shadow_color = Color(0, 0, 0, 0.35)
		s.shadow_size = shadow
		s.shadow_offset = Vector2(0, 4)
	return s

static func button(text: String, color := BLUE, min_size := Vector2(240, 64), font_size := 26) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 0.9))
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.45))
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	b.add_theme_constant_override("outline_size", 4)
	restyle(b, color)
	b.pressed.connect(func(): Sfx.click())
	b.pivot_offset = min_size * 0.5
	return b

static func restyle(b: Button, color: Color) -> void:
	b.add_theme_stylebox_override("normal", box(color, 18, color.lightened(0.35), 3, 6))
	b.add_theme_stylebox_override("hover", box(color.lightened(0.12), 18, color.lightened(0.5), 3, 6))
	b.add_theme_stylebox_override("pressed", box(color.darkened(0.2), 18, color.lightened(0.2), 3, 0))
	b.add_theme_stylebox_override("disabled", box(color.darkened(0.45).lerp(GRAY, 0.5), 18, Color(1, 1, 1, 0.15), 2, 0))

static func label(text: String, size := 24, color := Color.WHITE, outline := true) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline:
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.65))
		l.add_theme_constant_override("outline_size", maxi(3, size / 8))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func panel(color := NAVY, radius := 22, margin := 16) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(color, radius, Color(1, 1, 1, 0.14), 2, 10))
	var m := MarginContainer.new()
	m.name = "M"
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, margin)
	p.add_child(m)
	return p

## Contenedor interior de un panel creado con panel().
static func inner(p: PanelContainer) -> MarginContainer:
	return p.get_node("M") as MarginContainer

static func pop_in(node: Control, delay := 0.0) -> void:
	node.modulate.a = 0.0
	node.scale = Vector2(0.85, 0.85)
	node.pivot_offset = node.size * 0.5
	var t := node.create_tween().set_parallel(true)
	t.tween_property(node, "modulate:a", 1.0, 0.25).set_delay(delay)
	t.tween_property(node, "scale", Vector2.ONE, 0.3).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

static func slide_in(node: Control, from := Vector2(0, 60), delay := 0.0) -> void:
	var target := node.position
	node.modulate.a = 0.0
	node.position = target + from
	var t := node.create_tween().set_parallel(true)
	t.tween_property(node, "modulate:a", 1.0, 0.3).set_delay(delay)
	t.tween_property(node, "position", target, 0.35).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

static func toast(parent: Node, text: String, color := RED) -> void:
	var l := label(text, 26, Color.WHITE)
	l.add_theme_stylebox_override("normal", box(color.darkened(0.1), 16, Color(1, 1, 1, 0.3), 2, 8))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(380, 56)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var layer := CanvasLayer.new()
	layer.layer = 90
	parent.add_child(layer)
	layer.add_child(l)
	var apply := func():
		if is_instance_valid(l):
			l.position = Vector2((l.get_viewport().get_visible_rect().size.x - 380.0) * 0.5, 30.0)
	l.size = Vector2(380, 56)
	apply.call()
	l.modulate.a = 0.0
	var t := l.create_tween()
	t.tween_property(l, "modulate:a", 1.0, 0.15)
	t.tween_interval(1.4)
	t.tween_property(l, "modulate:a", 0.0, 0.3)
	t.tween_callback(layer.queue_free)

# ------------------------------------------------------------------ componentes
class CoinIcon extends Control:
	func _init(sz := 34.0) -> void:
		custom_minimum_size = Vector2(sz, sz)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - 1.0
		draw_circle(c, r, Color(0.78, 0.5, 0.05))
		draw_circle(c, r * 0.82, Color(1.0, 0.8, 0.15))
		draw_circle(c, r * 0.58, Color(1.0, 0.9, 0.4))
		draw_line(c + Vector2(0, -r * 0.4), c + Vector2(0, r * 0.4), Color(0.8, 0.52, 0.05), r * 0.2)

class CoinChip extends PanelContainer:
	var lbl: Label
	var _shown := 0.0
	var _target := 0
	func _init() -> void:
		add_theme_stylebox_override("panel", UIKit.box(Color(0.05, 0.08, 0.2, 0.85), 24, Color(1.0, 0.8, 0.15, 0.8), 2, 6))
		var m := MarginContainer.new()
		for s in ["left", "right"]:
			m.add_theme_constant_override("margin_" + s, 12)
		for s in ["top", "bottom"]:
			m.add_theme_constant_override("margin_" + s, 5)
		add_child(m)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		m.add_child(h)
		h.add_child(UIKit.CoinIcon.new(34.0))
		lbl = UIKit.label("0", 28, UIKit.GOLD)
		lbl.custom_minimum_size = Vector2(96, 0)
		h.add_child(lbl)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _ready() -> void:
		_target = SaveManager.get_coins()
		_shown = _target
		lbl.text = _fmt(_target)
		SaveManager.coins_changed.connect(func(t): _target = t)
	func _process(delta: float) -> void:
		if int(round(_shown)) != _target:
			_shown = move_toward(_shown, _target, maxf(1.0, absf(_target - _shown) * 6.0 * delta))
			lbl.text = _fmt(int(round(_shown)))
	static func _fmt(n: int) -> String:
		var s := str(n)
		var out := ""
		for i in s.length():
			if i > 0 and (s.length() - i) % 3 == 0:
				out += "."
			out += s[i]
		return out

class StatBar extends Control:
	var value := 0.0
	var extra := 0.0       # parte añadida por mejoras
	var color := Color(0.2, 0.8, 0.4)
	func _init(sz := Vector2(160, 14)) -> void:
		custom_minimum_size = sz
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(0, 0, 0, 0.45))
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * clampf(value, 0, 1), size.y)), color)
		if extra > 0.0:
			draw_rect(Rect2(Vector2(size.x * clampf(value - extra, 0, 1), 0), Vector2(size.x * clampf(extra, 0, 1), size.y)), Color(1.0, 0.85, 0.2))
		draw_rect(r, Color(1, 1, 1, 0.3), false, 1.5)

class Pips extends Control:
	var level := 0
	var maximum := 5
	func _init() -> void:
		custom_minimum_size = Vector2(maximum * 22.0, 18)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		for i in maximum:
			var c := Rect2(i * 22.0, 2, 18, 14)
			draw_rect(c, Color(1.0, 0.8, 0.15) if i < level else Color(0, 0, 0, 0.45))
			draw_rect(c, Color(1, 1, 1, 0.35), false, 1.5)

class LockIcon extends Control:
	func _init(sz := 46.0) -> void:
		custom_minimum_size = Vector2(sz, sz)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var w := size.x
		draw_arc(Vector2(w * 0.5, w * 0.36), w * 0.24, PI, TAU, 12, Color(0.85, 0.85, 0.9), w * 0.1)
		draw_line(Vector2(w * 0.26, w * 0.36), Vector2(w * 0.26, w * 0.5), Color(0.85, 0.85, 0.9), w * 0.1)
		draw_line(Vector2(w * 0.74, w * 0.36), Vector2(w * 0.74, w * 0.5), Color(0.85, 0.85, 0.9), w * 0.1)
		draw_rect(Rect2(w * 0.16, w * 0.48, w * 0.68, w * 0.42), Color(0.95, 0.75, 0.15))
		draw_circle(Vector2(w * 0.5, w * 0.66), w * 0.07, Color(0.3, 0.2, 0.05))

class StarRow extends Control:
	var count := 0
	var total := 2
	func _init() -> void:
		custom_minimum_size = Vector2(total * 28.0, 26)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		for i in total:
			var c := Vector2(14 + i * 28.0, 13)
			var pts := PackedVector2Array()
			for k in 10:
				var r := 12.0 if k % 2 == 0 else 5.0
				var a := -PI / 2 + TAU * k / 10.0
				pts.append(c + Vector2(cos(a), sin(a)) * r)
			draw_colored_polygon(pts, Color(1.0, 0.82, 0.15) if i < count else Color(0, 0, 0, 0.5))
