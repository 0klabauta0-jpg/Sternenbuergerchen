extends RefCounted
## Existing project illustrations, cropped by AtlasTexture without editing pixels.
## Bauen, Werkstatt, Lager, Datenterminal und RRR-Service haben keine Illustration im Atlas: Sie bekommen eigene, einfache
## einfarbige Linien-Icons (24 x 24, Petrol-/Amber-Palette wie Assets/curated/smart_mobile_icons). Der SVG-Text steht hier im
## Skript und wird zur Laufzeit gerastert, damit kein Import-Schritt (.import) noetig ist und kopflose Laeufe wie die EXE dasselbe sehen.
const SOURCE := "res://art/homebase_ui_study_20261112/icon_study.png"
const EQUIPMENT = preload("res://scripts/ui/menu_equipment_icons.gd")
const REGIONS := {
	"base":Rect2(34,184,326,336),
	"personnel":Rect2(381,184,323,336),
	"squad":Rect2(726,184,323,336),
	"mission":Rect2(1072,184,323,336),
	"map":Rect2(1417,184,324,336)
}
const SVG_HEAD := '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#f4f2e9" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">'
const SVG_BODIES := {
	# Kran
	"build": '<path d="M5 21V4h13M5 9l6-5M18 4v6"/><path d="M3 21h8"/><rect x="15.5" y="10" width="5" height="4" stroke="#edbb6c"/>',
	# Schraubenschluessel
	"workshop": '<path d="M14.5 5.2a4.2 4.2 0 0 0-5.3 5.3L4 15.7 8.3 20l5.2-5.2a4.2 4.2 0 0 0 5.3-5.3l-2.7 2.7-2.6-.7-.7-2.6z"/><circle cx="7.2" cy="16.8" r=".9" stroke="#edbb6c"/>',
	# Kiste
	"inventory": '<path d="M3 8l9-4 9 4v9l-9 4-9-4z"/><path d="M3 8l9 4 9-4" stroke="#edbb6c"/><path d="M12 12v9"/>',
	# Datenterminal
	"data": '<rect x="3" y="4" width="18" height="12" rx="1.5"/><path d="M8 20h8M12 16v4"/><path d="M7 8.5l3 2-3 2M12 12.5h4" stroke="#edbb6c"/>',
	# Zapfsaeule mit Schluessel (Tanken, Reparieren, Aufmunitionieren)
	"service": '<rect x="5" y="4" width="9" height="16" rx="1.5"/><path d="M5 20h9M7.5 8h4"/><path d="M14 9h2.5a1.5 1.5 0 0 1 1.5 1.5V16a1.5 1.5 0 0 0 3 0V9l-2-2" stroke="#edbb6c"/>',
}
static var _cache: Dictionary = {}

static func get_icon(id: String) -> Texture2D:
	if id == "jobs": return EQUIPMENT.get_icon("satellite_chip")
	if SVG_BODIES.has(id): return _svg_icon(id)
	if not REGIONS.has(id): return null
	if not _cache.has(id):
		var texture := AtlasTexture.new()
		texture.atlas = load(SOURCE)
		texture.region = REGIONS[id]
		texture.filter_clip = true
		_cache[id] = texture
	return _cache[id]

static func _svg_icon(id: String) -> Texture2D:
	if not _cache.has(id):
		var image := Image.new()
		if image.load_svg_from_string(SVG_HEAD + String(SVG_BODIES[id]) + "</svg>", 2.0) != OK:
			return null
		_cache[id] = ImageTexture.create_from_image(image)
	return _cache[id]
