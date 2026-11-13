extends RefCounted
## Presentation only. Never write names into owner definitions or checkpoint hashes.
const SYSTEM_NAME := "Börner"
const BODY_NAMES := {"sun":"Börner", "planet":"Mare Nostrum", "glut_1a":"Neralis", "glut_1b":"Vesper", "moon":"Asterholm", "glut_2":"Eidolon"}
const BODY_LEGACY := {"sun":"Börner", "planet":"Mare Nostrum", "glut_1a":"Mare Nostrum A", "glut_1b":"Mare Nostrum B", "moon":"Mare Nostrum C · Heimatbasis", "glut_2":"Börner II"}
const LOCATION_NAMES := {"homebase":"Heimathafen", "satellite_crash":"Aschental", "trade_outpost":"Kestrel", "fortified_outpost":"Bastion Silex", "distress_orbit":"Fernwacht", "polisa":"Polisa"}
const LOCATION_LEGACY := {"homebase":"Heimatbasis", "satellite_crash":"Satelliten-Absturzstelle", "trade_outpost":"Handelsaussenposten", "fortified_outpost":"Gesicherter Außenposten", "distress_orbit":"Notruf im Planetenorbit", "polisa":"Polisa / Freie Raumstation"}
const STATUS := {"offered":"Verfügbar", "accepted":"Angenommen", "active":"Im Einsatz", "completed":"Abgeschlossen", "failed":"Erneut verfügbar", "pending_upload":"Chip geborgen · zuhause hochladen"}

static func body_name(id: String, record: Dictionary = {}) -> String:
	if id == "sun" and String(record.get("name","")) in ["", "Glut", "Börner"]: return SYSTEM_NAME
	return _name(id, record, BODY_NAMES, BODY_LEGACY)

static func location_name(id: String, record: Dictionary = {}) -> String:
	return _name(id, record, LOCATION_NAMES, LOCATION_LEGACY)

static func _name(id: String, record: Dictionary, names: Dictionary, legacy: Dictionary) -> String:
	if id.is_empty(): return ""
	var authored := String(record.get("name", ""))
	# Explicit custom content remains authoritative, including an overridden ID.
	if not authored.is_empty() and authored != String(legacy.get(id, "")): return authored
	return String(names.get(id, authored if not authored.is_empty() else id))

static func orbit_name(id: String, travel: Dictionary) -> String:
	var orbit: Dictionary = Dictionary(travel.get("orbits", {})).get(id, {})
	var body_id := String(orbit.get("body_id", ""))
	return body_name(body_id, Dictionary(travel.get("bodies", {})).get(body_id, {})) + " · Orbit" if not body_id.is_empty() else String(orbit.get("name", id))
