class_name TruppFarben
extends RefCounted
## Anzeigenamen der Trupps als deutsche Farbnamen (data/comms/trupp_farben.json). Nur Anzeige, die Kennungen bleiben unveraendert.

const CATALOG_PATH: String = "res://data/comms/trupp_farben.json"

static var _cache: Dictionary = {}
static var _loaded: bool = false


static func colors() -> Dictionary:
	if _loaded:
		return _cache
	_loaded = true
	if not FileAccess.file_exists(CATALOG_PATH):
		return _cache
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		return _cache
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_cache = Dictionary(Dictionary(parsed).get("farben", {}))
	return _cache


static func clear_cache() -> void:
	_cache = {}
	_loaded = false


## Farbname zur Kennung (auch "BLUE" oder "Blue"); ohne Zuordnung `fallback`, ist der leer, die Kennung in Grossbuchstaben wie bisher.
static func display_name(fireteam_id: String, fallback: String = "") -> String:
	var key: String = fireteam_id.strip_edges().to_lower()
	var table: Dictionary = colors()
	if table.has(key):
		return String(table[key])
	if not fallback.strip_edges().is_empty():
		return fallback
	return fireteam_id.strip_edges().to_upper()
