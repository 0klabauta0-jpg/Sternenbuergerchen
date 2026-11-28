class_name FunkSaetze
extends RefCounted
## Lader und Auswaehler fuer die Funksaetze (data/comms/funk_saetze.json).
## Aufbau der Datei: Anlass -> Persoenlichkeit -> {"kurz": [...], "genau": [...]}.
## Rein rechnend: dieselben Eingaben ergeben im Mehrspieler auf jedem Rechner denselben Satz
## (kein globaler Zufall; die Wahl folgt aus einem Hash von Einheit, Anlass und Zaehler).

const CATALOG_PATH: String = "res://data/comms/funk_saetze.json"
const DEFAULT_PERSONALITY: String = "profi"
const PERSONALITIES: PackedStringArray = ["profi", "draufgaenger", "vorsichtig", "spassvogel", "brummbaer"]
const TIER_KURZ: String = "kurz"
const TIER_GENAU: String = "genau"
## Unter dieser Funkguete (0 bis 1) spricht die Person kurz; sonst genauer (gleiche Grenze wie die Truppfuehrer-Saetze).
const KURZ_BELOW_CLARITY: float = 0.42
## Anlaesse, die vorrangig laufen und zusaetzlich im Meldungsfenster stehen.
const IMPORTANT_OCCASIONS: PackedStringArray = ["liegt", "kamerad_faellt"]
## Ersatzwerte, damit nie ein Platzhalter im Satz stehen bleibt.
const PLACEHOLDER_FALLBACKS: Dictionary = {
	"name": "Soldat",
	"team": "Trupp",
	"richtung": "vorn",
	"ziel": "dem Ziel",
	"kamerad": "Kamerad",
}
const COMPASS_LABELS: PackedStringArray = ["Nord", "Nordost", "Ost", "Südost", "Süd", "Südwest", "West", "Nordwest"]

static var _catalog_cache: Dictionary = {}
static var _catalog_loaded: bool = false


static func load_catalog() -> Dictionary:
	if _catalog_loaded:
		return _catalog_cache
	_catalog_loaded = true
	if not FileAccess.file_exists(CATALOG_PATH):
		return _catalog_cache
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		return _catalog_cache
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	_catalog_cache = Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}
	return _catalog_cache


static func clear_cache() -> void:
	_catalog_cache = {}
	_catalog_loaded = false


static func occasions() -> PackedStringArray:
	var result := PackedStringArray()
	for key in load_catalog().keys():
		result.append(String(key))
	return result


static func is_important(occasion: String) -> bool:
	return IMPORTANT_OCCASIONS.has(occasion.strip_edges().to_lower())


static func normalize_personality(personality: String) -> String:
	var normalized: String = personality.strip_edges().to_lower()
	return normalized if PERSONALITIES.has(normalized) else DEFAULT_PERSONALITY


## "kurz" bei schlechter Funkguete, sonst "genau".
static func tier_for_clarity(clarity: float) -> String:
	return TIER_KURZ if clarity < KURZ_BELOW_CLARITY else TIER_GENAU


## Alle Fassungen eines Anlasses fuer Persoenlichkeit und Stufe (ungefuellt, mit Platzhaltern).
static func variants(occasion: String, personality: String, tier: String) -> Array:
	var entry: Dictionary = Dictionary(load_catalog().get(occasion.strip_edges().to_lower(), {}))
	if entry.is_empty():
		return []
	var by_personality: Dictionary = Dictionary(entry.get(normalize_personality(personality), entry.get(DEFAULT_PERSONALITY, {})))
	var normalized_tier: String = TIER_KURZ if tier == TIER_KURZ else TIER_GENAU
	var list: Variant = by_personality.get(normalized_tier, [])
	return Array(list) if typeof(list) == TYPE_ARRAY else []


## Platz der Fassung, die bei diesem Zaehlerstand gewaehlt wird (ohne die Fassung des vorigen Zaehlerstands zu wiederholen).
static func variant_index(count: int, seed_key: String, occasion: String, counter: int) -> int:
	if count <= 0:
		return -1
	if count == 1:
		return 0
	# Startplatz und Schrittweite (1 bis count-1) folgen aus dem Hash; jeder Zaehlerschritt rueckt um die Schrittweite weiter,
	# daher ist eine direkte Wiederholung ausgeschlossen.
	var base_hash: int = ("%s|%s" % [seed_key, occasion]).hash()
	var start: int = posmod(base_hash, count)
	var step: int = 1 + posmod(base_hash >> 8, count - 1)
	return posmod(start + maxi(counter, 0) * step, count)


## Satz fuer Anlass, Persoenlichkeit und Funkguete. `counter` zaehlt, wie oft diese Einheit diesen Anlass schon gesprochen hat.
static func pick(occasion: String, personality: String, clarity: float, seed_key: String, counter: int, context: Dictionary = {}) -> String:
	var list: Array = variants(occasion, personality, tier_for_clarity(clarity))
	if list.is_empty():
		return ""
	var index: int = variant_index(list.size(), seed_key, occasion.strip_edges().to_lower(), counter)
	if index < 0:
		return ""
	return fill(String(list[index]), context)


## Ersetzt {name} {team} {richtung} {ziel} {kamerad}; fehlende Werte bekommen deutsche Ersatzwerte.
static func fill(template: String, context: Dictionary = {}) -> String:
	var text: String = template
	for key in PLACEHOLDER_FALLBACKS.keys():
		var value: String = String(context.get(key, "")).strip_edges()
		if value.is_empty():
			value = String(PLACEHOLDER_FALLBACKS[key])
		text = text.replace("{%s}" % String(key), value)
	return text.strip_edges()


## Himmelsrichtung (deutsch) von `from` nach `to`; Norden ist oben (y nimmt nach unten zu).
static func compass_label(from: Vector2, to: Vector2) -> String:
	var delta: Vector2 = to - from
	if delta.length_squared() < 0.0001:
		return String(PLACEHOLDER_FALLBACKS["richtung"])
	var angle: float = atan2(delta.x, -delta.y)
	var sector: int = int(round(angle / (PI / 4.0)))
	return COMPASS_LABELS[posmod(sector, 8)]
