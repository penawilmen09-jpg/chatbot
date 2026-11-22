extends RefCounted
## Wilmen con su vestuario (traje, sombrero, armadura y efecto) para menús: título y pantalla de vestuario.
## Usa las mismas piezas y constantes que el jugador del juego (characters/player/player.gd).

const SpriteUtil := preload("res://characters/sprite_util.gd")
const PlayerScript := preload("res://characters/player/player.gd")


static func build(root: Node2D, anim: String = "idle") -> AnimatedSprite2D:
	var tex: Texture2D = load("res://assets/player/wilmen.png")
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = SpriteUtil.make_frames(tex, 24, 24, {
		"idle": {"frames": [0, 1], "fps": 2.5},
		"run": {"frames": [2, 3, 4, 5, 6, 7], "fps": 12.0},
	})
	spr.position = Vector2(0, -2)
	root.add_child(spr)
	spr.play(anim)
	var suit: String = Progress.effective("suit")
	if suit != "" and suit != "classic" and PlayerScript.SUITS.has(suit):
		var mat := ShaderMaterial.new()
		mat.shader = load("res://assets/player/suit.gdshader")
		var v: Array = PlayerScript.SUITS[suit]
		mat.set_shader_parameter("hue_shift", v[0])
		mat.set_shader_parameter("sat_mul", v[1])
		mat.set_shader_parameter("val_mul", v[2])
		spr.material = mat
	var hat: String = Progress.effective("hat")
	if hat != "" and PlayerScript.HAT_ORDER.has(hat):
		root.add_child(_piece("res://assets/player/hats.png", PlayerScript.HAT_ORDER.find(hat), Vector2(0.5, PlayerScript.HAT_Y)))
	var armor: String = Progress.effective("armor")
	if armor != "" and PlayerScript.ARMOR_ORDER.has(armor):
		root.add_child(_piece("res://assets/player/armors.png", PlayerScript.ARMOR_ORDER.find(armor), Vector2(0, PlayerScript.ARMOR_Y)))
	var trail: String = Progress.effective("trail")
	if trail != "":
		var p := CPUParticles2D.new()
		p.amount = 10
		p.lifetime = 0.9
		p.preprocess = 0.9
		p.position = Vector2(-4, 6)
		p.direction = Vector2(-1, -0.5)
		p.spread = 40.0
		p.initial_velocity_min = 4.0
		p.initial_velocity_max = 12.0
		p.gravity = Vector2.ZERO
		p.scale_amount_min = 0.5
		p.scale_amount_max = 1.0
		p.color = {"chispas": Color("#ffe05a"), "llamas": Color("#ff7a1a"), "nieve": Color.WHITE, "corazones": Color("#ff6a9a"),
			"estrellas": Color("#fff08a"), "burbujas": Color(0.7, 0.9, 1.0, 0.8)}.get(trail, Color.WHITE)
		root.add_child(p)
	return spr


static func _piece(path: String, index: int, pos: Vector2) -> Sprite2D:
	var sp := Sprite2D.new()
	var at := AtlasTexture.new()
	at.atlas = load(path)
	at.region = Rect2(index * 16, 0, 16, 16)
	sp.texture = at
	sp.position = pos
	return sp
