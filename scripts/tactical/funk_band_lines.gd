class_name FunkBandLines
extends RefCounted
## Zustand der Sprechzeilen der Mitglieder im Band (Bilderstreifen der ausgewaehlten Truppkarte).
## Reine Daten und Bremse, keine Knoten: Zeiten kommen als Millisekunden von aussen (Prueflaeufe koennen sie vorgeben).
## Die Saetze selbst liefert FunkSaetze (data/comms/funk_saetze.json).

const FUNK_SAETZE_SCRIPT: GDScript = preload("res://scripts/tactical/funk_saetze.gd")

## Je Person hoechstens ein Satz in diesem Abstand (wichtige Saetze anderer Anlaesse duerfen vordraengeln).
const PER_UNIT_GAP_MSEC: int = 4000
## Im ganzen Band hoechstens so viele neue Saetze je Fenster (wichtige duerfen darueber hinaus).
const BAND_WINDOW_MSEC: int = 1000
const BAND_MAX_NEW_PER_WINDOW: int = 2
const MIN_DURATION_MSEC: int = 3000
const MAX_DURATION_MSEC: int = 5000
const FADE_MSEC: int = 700
## Gleichzeitig sichtbare Zeilen im Band.
const MAX_VISIBLE_LINES: int = 2

var _lines: Dictionary = {}          # unit_id -> aktuelle Zeile
var _last_spoken_msec: Dictionary = {}   # unit_id -> Beginn des letzten Satzes
var _last_occasion: Dictionary = {}  # unit_id -> Anlass des letzten Satzes
var _counters: Dictionary = {}       # "unit_id|anlass" -> Anzahl bisher
var _recent_starts: Array = []       # Beginn der letzten Saetze im ganzen Band (ms)
var _thoughts: Dictionary = {}       # unit_id -> Gedankentext (nur solange Taste V gehalten wird)


func reset() -> void:
	_lines.clear()
	_last_spoken_msec.clear()
	_last_occasion.clear()
	_counters.clear()
	_recent_starts.clear()
	_thoughts.clear()


## Bietet einen Satz an. Gibt die neue Zeile zurueck oder {} (gebremst, kein Satz in der Datei).
## `person`: {unit_id, fireteam_id, name, personality, clarity, is_leader}
func offer(person: Dictionary, occasion: String, context: Dictionary, now_msec: int) -> Dictionary:
	var unit_id: String = String(person.get("unit_id", "")).strip_edges()
	var normalized_occasion: String = occasion.strip_edges().to_lower()
	if unit_id.is_empty() or normalized_occasion.is_empty():
		return {}
	var important: bool = FUNK_SAETZE_SCRIPT.is_important(normalized_occasion)
	if not _may_speak(unit_id, normalized_occasion, important, now_msec):
		return {}
	var counter_key: String = "%s|%s" % [unit_id, normalized_occasion]
	var counter: int = int(_counters.get(counter_key, 0))
	var fill_context: Dictionary = context.duplicate()
	fill_context["name"] = String(person.get("name", ""))
	fill_context["team"] = String(context.get("team", person.get("team", "")))
	var text: String = String(FUNK_SAETZE_SCRIPT.pick(
		normalized_occasion,
		String(person.get("personality", "")),
		float(person.get("clarity", 0.5)),
		unit_id,
		counter,
		fill_context
	))
	if text.is_empty():
		return {}
	_counters[counter_key] = counter + 1
	var duration: int = clampi(MIN_DURATION_MSEC + text.length() * 40, MIN_DURATION_MSEC, MAX_DURATION_MSEC)
	var line: Dictionary = {
		"unit_id": unit_id,
		"fireteam_id": String(person.get("fireteam_id", "")).strip_edges().to_lower(),
		"name": String(person.get("name", "")),
		"occasion": normalized_occasion,
		"text": text,
		"important": important,
		"is_leader": bool(person.get("is_leader", false)),
		"start_msec": now_msec,
		"end_msec": now_msec + duration,
	}
	_lines[unit_id] = line
	_last_spoken_msec[unit_id] = now_msec
	_last_occasion[unit_id] = normalized_occasion
	_recent_starts.append(now_msec)
	return line.duplicate(true)


func _may_speak(unit_id: String, occasion: String, important: bool, now_msec: int) -> bool:
	if _last_spoken_msec.has(unit_id):
		var since_last: int = now_msec - int(_last_spoken_msec[unit_id])
		if since_last < PER_UNIT_GAP_MSEC:
			# Ein wichtiger Satz anderer Art (liegt nach getroffen) draengelt vor, derselbe Anlass nicht.
			if not important or String(_last_occasion.get(unit_id, "")) == occasion:
				return false
	if not important:
		_trim_recent_starts(now_msec)
		if _recent_starts.size() >= BAND_MAX_NEW_PER_WINDOW:
			return false
	return true


func _trim_recent_starts(now_msec: int) -> void:
	var kept: Array = []
	for start_variant in _recent_starts:
		if now_msec - int(start_variant) < BAND_WINDOW_MSEC:
			kept.append(start_variant)
	_recent_starts = kept


## Noch laufende Zeilen (aelteste zuerst). Abgelaufene werden dabei entfernt.
func get_active_lines(now_msec: int) -> Array:
	var result: Array = []
	var expired: Array = []
	for unit_id in _lines.keys():
		var line: Dictionary = Dictionary(_lines[unit_id])
		if now_msec >= int(line.get("end_msec", 0)):
			expired.append(unit_id)
			continue
		result.append(line.duplicate(true))
	for unit_id in expired:
		_lines.erase(unit_id)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("start_msec", 0)) == int(b.get("start_msec", 0)):
			return String(a.get("unit_id", "")) < String(b.get("unit_id", ""))
		return int(a.get("start_msec", 0)) < int(b.get("start_msec", 0))
	)
	return result


## Deckkraft einer Zeile: voll, dann in den letzten FADE_MSEC verblassend.
static func alpha_for(line: Dictionary, now_msec: int) -> float:
	var remaining: int = int(line.get("end_msec", 0)) - now_msec
	if remaining <= 0:
		return 0.0
	if remaining >= FADE_MSEC:
		return 1.0
	return clampf(float(remaining) / float(FADE_MSEC), 0.0, 1.0)


func has_active_lines(now_msec: int) -> bool:
	for unit_id in _lines.keys():
		if now_msec < int(Dictionary(_lines[unit_id]).get("end_msec", 0)):
			return true
	return false


func set_thoughts(thoughts: Dictionary) -> void:
	_thoughts = thoughts.duplicate()


func clear_thoughts() -> void:
	_thoughts.clear()


func get_thought(unit_id: String) -> String:
	return String(_thoughts.get(unit_id, ""))


func has_thoughts() -> bool:
	return not _thoughts.is_empty()
