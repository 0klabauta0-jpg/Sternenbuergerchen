class_name NativeUIIcons
extends RefCounted

# Byte-identical generated candidates; only display regions normalize transparent padding.
static var _cache: Dictionary = {}

const ITEMS: Dictionary = {
    "move": ["res://Assets/curated/ui_native_r1/icon_move.png", Rect2i(92, 177, 1091, 943)],
    "defend": ["res://Assets/curated/ui_native_r1/icon_defend.png", Rect2i(207, 141, 840, 971)],
    "take": ["res://Assets/curated/ui_native_r1/icon_take.png", Rect2i(166, 72, 905, 1146)],
    "flank": ["res://Assets/curated/ui_native_r1/icon_flank_v2.png", Rect2i(49, 232, 1157, 831)],
    "dropship": ["res://Assets/curated/ui_native_r1/icon_dropship_v2.png", Rect2i(76, 144, 1102, 952)],
    "loadout": ["res://Assets/curated/ui_native_r1/icon_loadout.png", Rect2i(125, 125, 1004, 979)],
}

static func get_icon(icon_id: String) -> Texture2D:
	if _cache.has(icon_id):
		return _cache[icon_id] as Texture2D
	if not ITEMS.has(icon_id):
		return null
	var entry: Array = ITEMS[icon_id]
	var source := load(String(entry[0])) as Texture2D
	if source == null:
		return null
	var texture := AtlasTexture.new()
	texture.atlas = source
	texture.region = Rect2(entry[1])
	texture.filter_clip = true
	_cache[icon_id] = texture
	return texture
