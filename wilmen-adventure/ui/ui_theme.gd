extends RefCounted
## Tema visual compartido (estilo 16 bits) creado por código.

const ICONS := preload("res://assets/ui/icons.png")

# índices en icons.png (celdas de 16x16)
const ICON_HEART := 0
const ICON_HEART_EMPTY := 1
const ICON_COIN := 2
const ICON_GEM := 3
const ICON_LIFE := 4
const ICON_POWER_BASE := 5  # spark, dash, shield, freeze, blink


static func icon(index: int) -> AtlasTexture:
	var t := AtlasTexture.new()
	t.atlas = ICONS
	t.region = Rect2(index * 16, 0, 16, 16)
	return t


static func _box(bg: Color, border: Color, radius: int = 6) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb


static func make() -> Theme:
	var t := Theme.new()
	t.set_default_font_size(14)
	t.set_stylebox("normal", "Button", _box(Color("#2b2050"), Color("#8a78d8")))
	t.set_stylebox("hover", "Button", _box(Color("#3d2f72"), Color("#b8a8ff")))
	t.set_stylebox("pressed", "Button", _box(Color("#6a50c0"), Color("#ffffff")))
	t.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), Color("#ffd23a")))
	t.set_stylebox("disabled", "Button", _box(Color("#1c1632"), Color("#4a4268")))
	t.set_color("font_color", "Button", Color("#ffffff"))
	t.set_color("font_hover_color", "Button", Color("#ffffff"))
	t.set_color("font_pressed_color", "Button", Color("#ffffff"))
	t.set_color("font_disabled_color", "Button", Color("#7a7298"))
	t.set_font_size("font_size", "Button", 16)
	t.set_stylebox("panel", "PanelContainer", _box(Color(0.08, 0.05, 0.16, 0.94), Color("#8a78d8"), 8))
	t.set_stylebox("panel", "Panel", _box(Color(0.08, 0.05, 0.16, 0.94), Color("#8a78d8"), 8))
	t.set_color("font_color", "Label", Color("#ffffff"))
	t.set_constant("outline_size", "Label", 3)
	t.set_color("font_outline_color", "Label", Color("#1a1226"))
	t.set_color("font_color", "CheckButton", Color("#ffffff"))
	return t


static func label(text: String, size: int = 14, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color("#1a1226"))
	l.add_theme_constant_override("outline_size", maxi(2, size / 5))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func button(text: String, min_size: Vector2 = Vector2(150, 40)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_ALL
	return b
