extends RefCounted
## Casillas de assets/items/ww_mech.png (ver tools/gen_ww_mech.py).
const SHEET := preload("res://assets/items/ww_mech.png")
const IDX := ["mush_up", "mush_up_p", "mush_dg", "mush_dg_p", "vine_handle", "vine_anchor", "log", "chute", "chute_warn", "phase", "phase_ghost",
	"plank", "sw1_off", "sw1_on", "sw2_off", "sw2_on", "blk1", "blk1_ghost", "blk2", "blk2_ghost", "dart_shooter", "dart",
	"pend_anchor", "pend_blade", "orbit", "elevator", "cur_arrow", "bubble"]
static var _cache: Dictionary = {}


static func tex(name: String) -> AtlasTexture:
	if not _cache.has(name):
		var at := AtlasTexture.new()
		at.atlas = SHEET
		at.region = Rect2(IDX.find(name) * 16, 0, 16, 16)
		_cache[name] = at
	return _cache[name]
