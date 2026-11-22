extends Area2D
## Seta lanzadora de WILMEN WORLD: al caer sobre ella (o chocar con ella) lanza al personaje con una trayectoria fija.
##   up: impulso vertical grande · right/left: impulso en diagonal. El jugador conserva el impulso horizontal en el aire
##   (launch_lock) salvo que empuje en sentido contrario. Glifos: % arriba · { derecha · } izquierda.

const A := preload("res://items/ww_atlas.gd")
const LAUNCH := {"up": Vector2(0.0, -475.0), "right": Vector2(230.0, -440.0), "left": Vector2(-230.0, -440.0)}

var kind: String = "up"
var _sprite: Sprite2D
var _press: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(14, 8)
	cs.shape = rs
	cs.position = Vector2(0, -2)
	add_child(cs)
	_sprite = Sprite2D.new()
	add_child(_sprite)
	_sprite.texture = A.tex("mush_up" if kind == "up" else "mush_dg")
	_sprite.flip_h = kind == "left"
	body_entered.connect(_on_body)


func _on_body(b: Node) -> void:
	if not b.is_in_group("player") or b.dead or b.velocity.y < -60.0:
		return
	b.launch_vec(LAUNCH[kind])
	Audio.play_sfx("spring", 0.85)
	_press = 0.2
	_sprite.texture = A.tex("mush_up_p" if kind == "up" else "mush_dg_p")


func _physics_process(delta: float) -> void:
	if _press > 0.0:
		_press -= delta
		if _press <= 0.0:
			_sprite.texture = A.tex("mush_up" if kind == "up" else "mush_dg")
