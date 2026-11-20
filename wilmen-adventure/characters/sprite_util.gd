extends RefCounted
## Utilidades para crear SpriteFrames desde una hoja de sprites (sin editor).


static func make_frames(tex: Texture2D, fw: int, fh: int, anims: Dictionary) -> SpriteFrames:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	for anim_name in anims:
		var a: Dictionary = anims[anim_name]
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, float(a.get("fps", 8.0)))
		sf.set_animation_loop(anim_name, bool(a.get("loop", true)))
		var row: int = int(a.get("row", 0))
		for i in a["frames"]:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(int(i) * fw, row * fh, fw, fh)
			sf.add_frame(anim_name, at)
	return sf
