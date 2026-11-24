extends RefCounted
## Verbluten in Stufen (Regel 24.11.2026): Wer ausgefallen ist und liegt, wird zu festen Zeiten seit dem Ausfall
## EINMAL je Stufe ausgewuerfelt; die letzte Stufe trifft sicher. Zahlen: data/combat/bleedout_stages.json
## ({"version":1,"stages":[{"at_seconds":..,"chance":..}, ..]}, Sekunden in Spielzeit, 60 Ticks je Sekunde).
## Reine statische Hilfen ohne Zustand und ohne Szene. Der Wurf ist zustandslos und wiederholbar: er kommt nicht
## aus dem Gefechts-Zufallsstrom (der Trefferwuerfe), sondern aus einem festen Text-Seed (Einsatz-Seed,
## Einheitenkennung, Ausfall-Tick, Stufennummer) - nach dem Muster der Einmal-Generatoren in air_defense_engagement.gd.
const DATA_PATH := "res://data/combat/bleedout_stages.json"
const TICKS_PER_SECOND := 60
const FALLBACK_AT_SECONDS := 390.0

static var _cached_stages: Array = []


## Die Stufen aus der Datei, geprueft; bei unbrauchbarer Datei einmal push_warning und EINE Stufe {390 s, 1.0}.
static func stages() -> Array:
	if _cached_stages.is_empty():
		_cached_stages = load_stages(DATA_PATH)
	return _cached_stages


static func load_stages(path: String) -> Array:
	var parsed: Array = []
	if FileAccess.file_exists(path):
		parsed = parse_stages(JSON.parse_string(FileAccess.get_file_as_string(path)))
	if parsed.is_empty():
		push_warning("bleedout_stages: %s unbrauchbar, Rueckfall auf eine Stufe bei %d s" % [path, int(FALLBACK_AT_SECONDS)])
		return fallback_stages()
	return parsed


static func fallback_stages() -> Array:
	return [{"at_seconds": FALLBACK_AT_SECONDS, "chance": 1.0}]


## Geprueft wie campaign_casualty_rules.rules_are_valid: Version 1, aufsteigende Zeiten (> 0), Chancen 0..1,
## letzte Stufe 1.0. Gibt die Stufen (at_seconds, chance als float) oder [] bei jeder Fehlform zurueck.
static func parse_stages(data: Variant) -> Array:
	if typeof(data) != TYPE_DICTIONARY or not data.has("version") or not data.has("stages"):
		return []
	if not _is_number(data["version"]) or float(data["version"]) != 1.0 or typeof(data["stages"]) != TYPE_ARRAY or data["stages"].is_empty():
		return []
	var result: Array = []
	var last_seconds: float = 0.0
	for entry in data["stages"]:
		if typeof(entry) != TYPE_DICTIONARY or not entry.has("at_seconds") or not entry.has("chance"):
			return []
		if not _is_number(entry["at_seconds"]) or not _is_number(entry["chance"]):
			return []
		var at_seconds: float = float(entry["at_seconds"])
		var chance: float = float(entry["chance"])
		if is_nan(at_seconds) or is_nan(chance) or is_inf(at_seconds) or at_seconds <= last_seconds or chance < 0.0 or chance > 1.0:
			return []
		last_seconds = at_seconds
		result.append({"at_seconds": at_seconds, "chance": chance})
	if float(result[result.size() - 1]["chance"]) != 1.0:
		return []
	return result


static func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


## Tick seit dem Ausfall, ab dem die Stufe gilt (aufgerundet: nie vor Ablauf der Sekunden).
static func stage_ticks(stage: Dictionary) -> int:
	return int(ceil(float(stage.get("at_seconds", FALLBACK_AT_SECONDS)) * float(TICKS_PER_SECOND) - 0.000001))


## Zustandsloser Wurf 0..1 aus Einsatz-Seed, Einheitenkennung, Ausfall-Tick und Stufennummer (0 = erste Stufe).
## Der Ausfall-Tick gehoert dazu, weil der Einsatz-Seed im Spiel konstant ist: so wuerfelt dieselbe Kennung in jedem
## Einsatz und bei jedem erneuten Ausfall neu. Der Tick steht im Spielstand, der Wurf bleibt wiederholbar.
static func roll(mission_seed: int, unit_id: String, started_tick: int, stage_index: int) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed_to_int("%d:%s:%d:%d:bleedout_stage" % [mission_seed, unit_id, started_tick, stage_index])
	return rng.randf()


## Trifft die Stufe? Wurf < Chance; Chance 1.0 trifft immer.
static func stage_hits(stage_list: Array, stage_index: int, mission_seed: int, unit_id: String, started_tick: int) -> bool:
	if stage_index < 0 or stage_index >= stage_list.size():
		return true
	var chance: float = float(Dictionary(stage_list[stage_index]).get("chance", 1.0))
	if chance >= 1.0:
		return true
	return roll(mission_seed, unit_id, started_tick, stage_index) < chance


static func _seed_to_int(value: String) -> int:
	var hash_value: int = 216613626
	for index in range(value.length()):
		hash_value = int((hash_value ^ value.unicode_at(index)) * 16777619) & 0x7fffffff
	return maxi(hash_value, 1)
