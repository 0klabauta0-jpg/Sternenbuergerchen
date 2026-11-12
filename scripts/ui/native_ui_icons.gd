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

# Small functional symbols share the native palette and are rasterized only once.
# Existing illustrated action icons keep their original resources and crop regions.
const ORDER_GLYPHS: Dictionary = {
	"order_target": '<circle cx="24" cy="24" r="13"/><path d="M24 4v12m0 16v12M4 24h12m16 0h12"/><circle cx="24" cy="24" r="3" fill="#eee3c4" stroke="none"/>',
	"order_clear": '<path d="m9 28 17-17 13 13-17 17H16L9 34zM19 18l13 13M22 41h18"/>',
	"order_delete": '<path d="M10 13h28M19 7h10l2 6M14 13l2 28h16l2-28M21 20v14m6-14v14"/>',
	"order_sort": '<path d="M12 8v32m-6-7 6 7 6-7M25 12h15M25 24h11M25 36h7"/>',
	"order_go": '<path d="m15 7 25 17-25 17z" fill="#163335" stroke="#163335"/>',
	"nav_home": '<path d="M6 22 24 8l18 14M10 20v20h28V20M19 40V27h10v13"/>',
	"nav_person": '<circle cx="24" cy="15" r="7"/><path d="M10 39c0-9 6-14 14-14s14 5 14 14z"/>',
	"nav_team": '<circle cx="17" cy="16" r="6"/><circle cx="33" cy="16" r="6"/><path d="M5 38c0-8 5-13 12-13s12 5 12 13M27 26c8-3 16 3 16 12"/>',
	"nav_planet": '<circle cx="24" cy="24" r="13"/><path d="M10 31C3 35 3 40 8 40c6 1 18-4 27-11s12-13 9-15c-2-2-6-1-10 0"/>',
	"nav_mobile": '<rect x="14" y="5" width="20" height="38" rx="3"/><path d="M20 10h8M21 37h6"/>',
}

static func get_icon(icon_id: String) -> Texture2D:
	if _cache.has(icon_id):
		return _cache[icon_id] as Texture2D
	if ORDER_GLYPHS.has(icon_id):
		var glyph := Image.new()
		var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48"><g fill="none" stroke="#eee3c4" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">%s</g></svg>' % ORDER_GLYPHS[icon_id]
		if glyph.load_svg_from_string(svg) != OK:
			return null
		var glyph_texture := ImageTexture.create_from_image(glyph)
		_cache[icon_id] = glyph_texture
		return glyph_texture
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
