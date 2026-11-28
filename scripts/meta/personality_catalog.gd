class_name PersonalityCatalog
extends RefCounted
## Persoenlichkeiten der Personen (data/comms/persoenlichkeiten.json): Schluessel, deutscher Name, Beschreibung, Startleute.
## Rein rechnend, kein globaler Zufall. Fehlt das Feld "personality" bei einer Person, gilt der Standard (profi).

const CATALOG_PATH: String = "res://data/comms/persoenlichkeiten.json"
const FALLBACK_DEFAULT: String = "profi"
const FALLBACK_TYPES: PackedStringArray = ["profi", "draufgaenger", "vorsichtig", "spassvogel", "brummbaer"]

static var _cache: Dictionary = {}
static var _loaded: bool = false


static func load_catalog() -> Dictionary:
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
	_cache = Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}
	return _cache


static func clear_cache() -> void:
	_cache = {}
	_loaded = false


## Alle Typschluessel in der Reihenfolge der Datei.
static func type_ids() -> PackedStringArray:
	var result := PackedStringArray()
	for key in Dictionary(load_catalog().get("typen", {})).keys():
		result.append(String(key))
	return result if not result.is_empty() else FALLBACK_TYPES


static func default_type() -> String:
	var value: String = String(load_catalog().get("standard", FALLBACK_DEFAULT)).strip_edges().to_lower()
	return value if type_ids().has(value) else FALLBACK_DEFAULT


## Gueltiger Schluessel; leer oder unbekannt ergibt den Standard (profi).
static func normalize(personality: Variant) -> String:
	var value: String = String(personality if personality != null else "").strip_edges().to_lower()
	return value if type_ids().has(value) else default_type()


static func display_name(personality: Variant) -> String:
	var key: String = normalize(personality)
	return String(Dictionary(Dictionary(load_catalog().get("typen", {})).get(key, {})).get("name", key.capitalize()))


static func description(personality: Variant) -> String:
	var key: String = normalize(personality)
	return String(Dictionary(Dictionary(load_catalog().get("typen", {})).get(key, {})).get("beschreibung", ""))


## Fester Startwert einer Startperson (z. B. "campaign_leader"); leer, wenn die Kennung kein Startmensch ist.
static func start_value(unit_id: String) -> String:
	var table: Dictionary = Dictionary(load_catalog().get("startleute", {}))
	var key: String = unit_id.strip_edges()
	return normalize(table.get(key, "")) if table.has(key) else ""


## Typ aus einer Zufallszahl 0..1 des vorhandenen Zufallswegs (gleich verteilt).
static func from_roll(roll: float) -> String:
	var ids: PackedStringArray = type_ids()
	return ids[clampi(int(floor(clampf(roll, 0.0, 0.999999) * float(ids.size()))), 0, ids.size() - 1)]


## Typ deterministisch aus einer Kennung (Gegner, neutrale NPCs): gleiche Kennung ergibt auf jedem Rechner denselben Typ.
static func from_id(id: String) -> String:
	var ids: PackedStringArray = type_ids()
	var hash_value: int = 2166136261
	for index in range(id.length()):
		hash_value = int((hash_value ^ id.unicode_at(index)) * 16777619) & 0x7fffffff
	return ids[posmod(hash_value, ids.size())]
