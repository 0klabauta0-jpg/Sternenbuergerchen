extends SceneTree
## Kapitel 2, Aufgabe 0b Nachbesserung: Einsatz-Zwischenstaende von VOR neuen Orten (Pruefsumme der Sternsystem-Daten) laden weiter.
## Geprueft wird die Vergleichsfunktion direkt am Raumfahrt-Besitzer (prepare_checkpoint_restore) mit rechnerisch erzeugten Pruefsummen;
## ein voller Einsatzstand waere hier zu teuer (die Einsatzlaeufe campaign_active_mission_continue_verifier u. a. decken den Gesamtweg).
const TRAVEL = preload("res://scripts/core/singleplayer_space_travel_state.gd")
const CAMPAIGN = preload("res://scripts/core/singleplayer_campaign_state.gd")
const SYSTEM_PATH := "res://data/singleplayer/star_system.json"
const PLACE := "relay_ridge"
## Pruefsumme der Sternsystem-Daten im Stand VOR der Vorarbeit (811e26125); wird unten gegen die Datei jenes Standes gegengeprueft, wenn sie vorliegt.
const KNOWN_PREDECESSOR := "b0daa3304db1ff1d09be8d30947519bf20a9b6651827d002cc0fa8f79a9bdbfb"
var passed := 0
var failed := 0

func _check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print(("PASS " if value else "FAIL ") + label)

func _init() -> void:
	call_deferred("_run")

func _sum(data: Dictionary) -> String:
	return JSON.stringify(data, "", true).sha256_text()

func _system() -> Dictionary:
	return Dictionary(JSON.parse_string(FileAccess.get_file_as_string(SYSTEM_PATH)))

func _verdict(fingerprint: String) -> Dictionary:
	var owner: RefCounted = TRAVEL.new()
	owner.configure("craft")
	var state: Dictionary = owner.export_checkpoint_state()
	if state.get("schema") != "space_travel_checkpoint.v1": return {"ok": false, "reason": "fixture_export_failed"}
	state["system_fingerprint"] = fingerprint
	return owner.prepare_checkpoint_restore(state)

func _run() -> void:
	var today: Dictionary = _system()
	_check(today.location_orbits.has(PLACE), "Fixture: heutige Daten enthalten den Ort %s" % PLACE)
	# "Vorher" = heutige Daten ohne ALLE additiven Orte (Handel 2a-2 haengt Muellers Farm, Shady Lab und Templanon an dieselbe Liste an;
	# die Vorgaenger-Pruefsumme kennt keinen von ihnen). Siehe SingleplayerSpaceTravelState._system_fingerprint_accepted (alle Teilmengen).
	var before: Dictionary = today.duplicate(true)
	for place: String in CAMPAIGN.ADDITIVE_LOCATION_IDS: before.location_orbits.erase(place)
	var before_posts: Dictionary = today.duplicate(true)
	for place: String in ["muellers_farm", "shady_lab", "templanon"]: before_posts.location_orbits.erase(place)
	_check(before_posts.location_orbits.has(PLACE) and not before_posts.location_orbits.has("shady_lab"), "Fixture: ein Stand mit relay_ridge, aber ohne die drei kleinen Posten")
	_check(bool(_verdict(_sum(before_posts)).get("ok", false)), "Fall a5: Zwischenstand von VOR den drei kleinen Posten (mit relay_ridge) wird angenommen")
	var verdict_today: Dictionary = _verdict(_sum(today))
	_check(bool(verdict_today.get("ok", false)), "Fall b: Zwischenstand mit der heutigen Pruefsumme wird angenommen (%s)" % str(verdict_today.get("reason", "")))
	var verdict_before: Dictionary = _verdict(_sum(before))
	_check(bool(verdict_before.get("ok", false)), "Fall a: Zwischenstand mit der Pruefsumme VOR dem Ort %s wird angenommen (%s)" % [PLACE, str(verdict_before.get("reason", ""))])
	var changed_old: Dictionary = today.duplicate(true)
	changed_old.location_orbits.trade_outpost = "planet_orbit"
	_check(not bool(_verdict(_sum(changed_old)).get("ok", true)), "Fall c: Pruefsumme mit geaendertem alten Ort (trade_outpost) wird abgelehnt")
	var changed_before: Dictionary = before.duplicate(true)
	changed_before.location_orbits.trade_outpost = "planet_orbit"
	_check(not bool(_verdict(_sum(changed_before)).get("ok", true)), "Fall c2: Vorher-Daten mit geaendertem alten Ort werden abgelehnt")
	var changed_orbit: Dictionary = before.duplicate(true)
	var orbit_id: String = String(today.location_orbits.trade_outpost)
	changed_orbit.orbits[orbit_id].erase("body_id")
	_check(not bool(_verdict(_sum(changed_orbit)).get("ok", true)), "Fall c3: Vorher-Daten mit geaenderter alter Umlaufbahn werden abgelehnt")
	var changed_key: Dictionary = before.duplicate(true)
	changed_key["version"] = int(today.get("version", 1)) + 1
	_check(not bool(_verdict(_sum(changed_key)).get("ok", true)), "Fall c4: Vorher-Daten mit geaendertem anderen Schluessel (version) werden abgelehnt")
	var other_orbit: Dictionary = today.duplicate(true)
	other_orbit.location_orbits[PLACE] = "glut_1b_orbit"
	_check(not bool(_verdict(_sum(other_orbit)).get("ok", true)), "Fall c5: neuer Ort mit anderer Umlaufbahn als heute wird abgelehnt")
	var extra: Dictionary = before.duplicate(true)
	extra.location_orbits["not_in_list"] = "planet_orbit"
	_check(not bool(_verdict(_sum(extra)).get("ok", true)), "Fall c6: zusaetzlicher Ort, der nicht in der Liste additiver Orte steht, wird abgelehnt")
	_check(not bool(_verdict("0".repeat(64)).get("ok", true)), "Fall c7: beliebige Pruefsumme wird abgelehnt")
	_case_known_predecessor(before)
	_check(CAMPAIGN.ADDITIVE_LOCATION_IDS.has(PLACE), "Fixture: %s steht in der Liste additiver Orte" % PLACE)
	print("CAMPAIGN_ADDITIVE_CHECKPOINT passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _case_known_predecessor(before: Dictionary) -> void:
	if not KNOWN_PREDECESSOR.is_empty():
		_check(_sum(before) == KNOWN_PREDECESSOR, "Fall a2: heutige Daten ohne den Ort ergeben genau die bekannte Vorgaenger-Pruefsumme")
		_check(bool(_verdict(KNOWN_PREDECESSOR).get("ok", false)), "Fall a3: die bekannte Vorgaenger-Pruefsumme wird angenommen")
	var path := OS.get_environment("TEMP") + "/sb_star_old.json"
	if not FileAccess.file_exists(path):
		print("SKIPPED Fall a4: keine Datei des Vorgaenger-Standes unter %TEMP% (sb_star_old.json)")
		return
	var old: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	_check(typeof(old) == TYPE_DICTIONARY, "Fall a4: Datei des Vorgaenger-Standes lesbar")
	if typeof(old) != TYPE_DICTIONARY: return
	print("OLD_FILE_HASH ", _sum(old))
	_check(_sum(old) == _sum(before), "Fall a4: Pruefsumme der echten alten Datei = heutige Daten ohne den Ort (exakt nachgebildet)")
	_check(bool(_verdict(_sum(old)).get("ok", false)), "Fall a4: Pruefsumme der echten alten Datei wird angenommen")
