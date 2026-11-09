extends RefCounted
## German display vocabulary only. Stored IDs, values and scoring stay intact.
const STOCK_PRESETS: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")
const LABELS := {
	"accuracy": "Treffsicherheit", "speed": "Tempo", "toughness": "Belastbarkeit",
	"awareness": "Wahrnehmung", "recognition": "Erkennen", "stealth": "Tarnung",
	"discipline": "Disziplin", "leadership": "Führung", "speech_quality": "Meldequalität",
	"speech_quantity": "Sprechhäufigkeit", "initiative": "Initiative", "order_fidelity": "Befehlstreue",
	"signature_control": "Unauffälligkeit", "contact_stability": "Ruhe im Kontakt", "autonomy": "Selbstständigkeit",
	"ground_vehicle_handling": "Bodenfahrzeuge", "dropship_piloting": "Landefähre steuern",
	"freighter_piloting": "Frachter steuern", "fighter_piloting": "Jäger steuern", "best_platform": "Bester Fahrzeugwert",
	"medic": "Sanität", "leader": "Führung", "heavy": "Schwere Waffen", "pilot": "Pilot",
	"engineer": "Technik", "shooter": "Schütze", "enemy": "Gegner", "operator": "Operator",
	"heavy_support": "Schwere Unterstützung", "scout_sniper": "Aufklärer / Scharfschütze",
	"silent": "Leise", "rapid": "Schnell", "steady": "Beständig", "watchful": "Wachsam", "command": "Führend",
	"pathfinder": "Wegfindung", "scout": "Aufklärung", "overwatch": "Feuersicherung", "sentinel": "Sicherung",
	"coordinator": "Koordination", "infiltrator": "Infiltration", "insertion_pilot": "Anflug",
	"transport_pilot": "Personentransport", "cargo_runner": "Frachttransport", "route_master": "Routenführung",
	"interceptor": "Abfangen", "strike_pilot": "Luftangriff", "escort_pilot": "Geleitschutz",
}
const TEXT := {
	"Fireteam Leader": "Truppführer", "Field Captain": "Truppführer", "Combat Medic": "Sanitäter",
	"Combat Engineer": "Techniker", "Dropship Pilot": "Landefährenpilot", "Rover Pilot": "Fahrzeugführer",
	"Recon Scout": "Aufklärer", "Scout Sniper": "Aufklärer / Scharfschütze", "Rifle Operator": "Schütze",
	"Heavy Support": "Schwere Unterstützung", "Heavy Gunner": "Schwerer Schütze", "Marksman": "Präzisionsschütze",
	"Comms Specialist": "Funker", "Drone Handler": "Drohnenführer", "Quartermaster": "Versorger",
	"Signals Analyst": "Fernmeldeaufklärer", "Breacher": "Zugriffsspezialist",
	"Generalist": "Allrounder", "Roadscouting": "Routenaufklärung", "Silent Routefinding": "Leise Wegfindung",
	"Silent Overwatch": "Verdeckte Feuersicherung", "Precision Overwatch": "Präzise Feuersicherung",
	"Advance Recon": "Vorausaufklärung", "Line Sentinel": "Stellungssicherung", "Field Coordinator": "Einsatzkoordination",
	"Silent Infiltration": "Verdecktes Eindringen", "Hot Drop Pilot": "Schneller Anflug", "Low-Signature Drop": "Verdeckter Anflug",
	"Stable Lift Pilot": "Ruhiger Personentransport", "Blockade Runner": "Blockadedurchbruch", "Route Master": "Routenführung",
	"Interceptor": "Abfangen", "Precision Strike Pilot": "Präziser Luftangriff", "Flight Lead": "Flugführung",
	"active": "Einsatzbereit", "recovering": "In Erholung", "injured": "Verletzt", "unavailable": "Nicht verfügbar",
	"none": "Keine", "none yet": "Noch keine", "n/a": "—", "UNASSIGNED": "Nicht zugewiesen",
	"victory": "Erfolg", "defeat": "Niederlage", "aborted": "Abgebrochen", "suggested": "Vorschlag",
	"MISSION GAIN": "EINSATZGEWINN", "Not leading": "Keine Truppführung", "No FTL impact recorded": "Keine Führungswirkung erfasst",
}

static func label(key: String) -> String:
	return String(LABELS.get(key, TEXT.get(key, key)))

static func text(value: String) -> String:
	return String(TEXT.get(value, value))

static func decimal(value: float) -> String:
	return ("%.2f" % value).replace(".", ",")

static func armor(armor_id: String) -> String:
	return String({"light": "Leichte Rüstung", "medium": "Mittlere Rüstung", "heavy": "Schwere Rüstung"}.get(armor_id, armor_id))

static func tactical_text(value: String) -> String:
	if value.begins_with("Plan ") and value.contains(" | Comms "):
		return value.replace(" | Comms ", " | Kommunikation ").replace(" | Breakout ", " | Ausbruch ")
	return text(value)

static func award_text(value: String) -> String:
	return value.replace("Skills +", "Werte +").replace("FTL +", "Führung +").replace("no delta", "Kein Zuwachs")

## Replace recognized shipped prose with saved facts only. Unknown custom prose
## is returned exactly, including whitespace; the profile is never rewritten.
static func stock_biography(value: String, profile) -> String:
	if profile == null or not _is_stock_biography(value):
		return value
	var role: String = String(profile.roster_role_category)
	role = label(role) if not role.is_empty() else text(String(profile.role_name))
	if role.is_empty():
		role = "Nicht dokumentiert"
	var facts: String = "Startrolle: %s." % role
	var callsign: String = String(profile.callsign)
	if not callsign.is_empty():
		facts += " Rufname: %s." % callsign
	return facts + " Eine weitere Berufslaufbahn ist nicht dokumentiert."

static func _is_stock_biography(value: String) -> bool:
	if value == "No biography recorded.":
		return true
	for preset: Dictionary in STOCK_PRESETS.FRIENDLY_ROSTER:
		var biography: String = String(preset.get("biography_text", ""))
		if value == biography or value == biography.get_slice(".", 0) + ".":
			return true
	var generator_template := RegEx.new()
	generator_template.compile("^.+, callsign .+, joins the starting roster as (medic|shooter|leader|engineer|pilot|heavy support|scout sniper) with useful strengths and visible gaps\\.$")
	return generator_template.search(value) != null
