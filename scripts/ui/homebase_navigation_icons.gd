extends RefCounted
## Existing project illustrations, cropped by AtlasTexture without editing pixels.
const SOURCE := "res://art/homebase_ui_study_20261112/icon_study.png"
const EQUIPMENT = preload("res://scripts/ui/menu_equipment_icons.gd")
const REGIONS := {
	"base":Rect2(34,184,326,336),
	"personnel":Rect2(381,184,323,336),
	"squad":Rect2(726,184,323,336),
	"mission":Rect2(1072,184,323,336),
	"map":Rect2(1417,184,324,336)
}
static var _cache: Dictionary = {}

static func get_icon(id: String) -> Texture2D:
	if id == "jobs": return EQUIPMENT.get_icon("satellite_chip")
	if not REGIONS.has(id): return null
	if not _cache.has(id):
		var texture := AtlasTexture.new()
		texture.atlas = load(SOURCE)
		texture.region = REGIONS[id]
		texture.filter_clip = true
		_cache[id] = texture
	return _cache[id]
