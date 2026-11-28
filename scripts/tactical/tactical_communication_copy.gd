class_name TacticalCommunicationCopy
extends RefCounted
## Einzige Satzquelle fuer die Truppfuehrer-Blase (data/tactical_communication_copy.json).
## Nur Text und Anzeigedauer; keine Spiellogik. Die uebrigen Wege (Befehlskontext,
## comms_lines, comic_bubble_text_catalog) liefern fuer die Blase keinen Satz mehr.

const CATALOG_PATH: String = "res://data/tactical_communication_copy.json"
const TEXT_SOURCE_ID: String = "tactical_communication_copy"
const TIER_LOW: String = "low"
const TIER_NEUTRAL: String = "neutral"
const TIER_HIGH: String = "high"
const IMPORTANT_PRIORITY: int = 80

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


static func tier_for_clarity(clarity: float) -> String:
	if clarity >= 0.70:
		return TIER_HIGH
	if clarity < 0.42:
		return TIER_LOW
	return TIER_NEUTRAL


static func normalize_tier(tier: String) -> String:
	var normalized: String = tier.strip_edges().to_lower()
	if normalized == TIER_HIGH or normalized == TIER_LOW:
		return normalized
	return TIER_NEUTRAL


## Satz fuer Befehlsrueckmeldungen (Aktion + Zustand). Schlechte Funkguete = kurz, gute = genauer.
static func command_text(action: String, state: String, tier: String, context: Dictionary = {}) -> Dictionary:
	var table: Dictionary = Dictionary(load_catalog().get("command_feedback", {}))
	var key: String = "%s.%s" % [action, state]
	if not table.has(key):
		key = "default.%s" % state
	if not table.has(key):
		key = "default.accepted"
	var entry: Dictionary = Dictionary(table.get(key, {}))
	if entry.is_empty():
		return {}
	var normalized_tier: String = normalize_tier(tier)
	var template: String = String(entry.get(normalized_tier, entry.get(TIER_NEUTRAL, ""))).strip_edges()
	var text: String = format_text(template, context)
	if text.is_empty():
		return {}
	return {"text": text, "text_source": TEXT_SOURCE_ID, "text_key": "command_feedback.%s.%s" % [key, normalized_tier]}


## Verstaendliche Fehlermeldung der Befehlspruefung.
static func validation_text(validation_key: String) -> String:
	var table: Dictionary = Dictionary(load_catalog().get("validation", {}))
	var key: String = validation_key.strip_edges().to_lower()
	var text: String = String(table.get(key, table.get("default", ""))).strip_edges()
	return text


static func event_entry(event_type: String) -> Dictionary:
	return Dictionary(Dictionary(load_catalog().get("events", {})).get(event_type, {}))


## Satz zu einem Ausbruchs-Anlass (z. B. Verwundeten-Hilfe, Munition), falls vorhanden.
static func trigger_entry(trigger: String) -> Dictionary:
	var key: String = trigger.strip_edges().to_lower()
	if key.is_empty():
		return {}
	return Dictionary(Dictionary(load_catalog().get("triggers", {})).get(key, {}))


## Anzeigedauer der Blase: 2 bis 4 Sekunden je nach Textlaenge, wichtige Meldungen etwas laenger.
static func duration_for_text(text: String, important: bool = false) -> float:
	var timing: Dictionary = Dictionary(load_catalog().get("timing", {}))
	var min_seconds: float = float(timing.get("min_seconds", 2.0))
	var max_seconds: float = float(timing.get("max_seconds", 4.0))
	var base_chars: int = int(timing.get("base_chars", 16))
	var per_char: float = float(timing.get("seconds_per_char", 0.06))
	var bonus: float = float(timing.get("important_bonus", 0.3)) if important else 0.0
	var length: int = text.replace("\n", " ").strip_edges().length()
	var seconds: float = min_seconds + float(maxi(length - base_chars, 0)) * per_char + bonus
	return clampf(seconds, min_seconds, max_seconds)


static func is_important(priority: int, feedback_state: String = "") -> bool:
	if priority >= IMPORTANT_PRIORITY:
		return true
	var state: String = feedback_state.strip_edges().to_lower()
	return state == "blocked" or state == "contact"


## Himmelsrichtung auf Deutsch; leer, wenn keine sinnvolle Richtung vorliegt.
static func format_direction(raw: String) -> String:
	var value: String = raw.strip_edges()
	if value.is_empty():
		return ""
	var words: Dictionary = Dictionary(load_catalog().get("direction_words", {}))
	var lookup: String = value.to_lower()
	if words.has(lookup):
		return String(words.get(lookup, ""))
	lookup = lookup.replace("ue", "ü")
	if words.has(lookup):
		return String(words.get(lookup, ""))
	return lookup.capitalize() if lookup.length() > 1 else ""


## Ersetzt Platzhalter; Teile in [eckigen Klammern] entfallen, wenn ein Platzhalter darin leer ist.
static func format_text(template: String, context: Dictionary) -> String:
	var team_text: String = str(context.get("team", context.get("display_label", context.get("fireteam_label", context.get("fireteam_id", ""))))).strip_edges()
	var replacements: Dictionary = {
		"{team}": team_text.to_upper(),
		"{fireteam}": str(context.get("fireteam_id", "")).strip_edges().to_upper(),
		"{role_label}": str(context.get("role_label", context.get("role", ""))).strip_edges(),
		"{direction}": format_direction(str(context.get("direction_label", context.get("direction", "")))),
		"{objective}": str(context.get("objective_label", "")).strip_edges(),
		"{phase}": str(context.get("phase", context.get("plan_phase_index", ""))).strip_edges(),
	}
	var result: String = ""
	var index: int = 0
	while index < template.length():
		var open_index: int = template.find("[", index)
		if open_index < 0:
			result += _replace_all(template.substr(index), replacements)
			break
		var close_index: int = template.find("]", open_index)
		if close_index < 0:
			result += _replace_all(template.substr(index), replacements)
			break
		result += _replace_all(template.substr(index, open_index - index), replacements)
		var segment: String = template.substr(open_index + 1, close_index - open_index - 1)
		var skip_segment: bool = false
		for key in replacements.keys():
			if segment.contains(String(key)) and String(replacements[key]).is_empty():
				skip_segment = true
				break
		if not skip_segment:
			result += _replace_all(segment, replacements)
		index = close_index + 1
	for key in replacements.keys():
		result = result.replace(String(key), "")
	while result.contains("  "):
		result = result.replace("  ", " ")
	result = result.replace(" !", "!").replace(" ,", ",").replace(" .", ".").replace(" ?", "?")
	return result.strip_edges()


static func _replace_all(text: String, replacements: Dictionary) -> String:
	var result: String = text
	for key in replacements.keys():
		result = result.replace(String(key), String(replacements[key]))
	return result
