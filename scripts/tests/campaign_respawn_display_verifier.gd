extends "res://scripts/tests/campaign_casualty_recovery_flow_verifier.gd"
## R5 Respawn (Anzeige): Die Texte der Spec (Abschnitt "Texte") stehen woertlich an den echten Erzeugern.
## Keine Regel, nur Anzeige. Geprueft wird an: Personenkarte der Basis (Restzeit laeuft mit, Uebergang, nach dem Abholen leer),
## Sperre beim Aufstellen, Charakterblatt (Zeile "Respawns"), Einsatzende (Debrief), Skirmish ohne Zeile, alter Spielstand, geaenderte Einstellung.
## Schreibt die Einstellung "Respawns je Person": darum nur mit Wegwerfprofil (SB_REVIEW2_USER_DIR).
## Abschlusszeile: CAMPAIGN_RESPAWN_DISPLAY passed=%d failed=%d

const R5_GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const R5_SETTINGS = preload("res://scripts/ui/game_settings_contract.gd")
const R5_FORMATTER = preload("res://scripts/meta/character_sheet_formatter.gd")
const R5_PROFILE = preload("res://scripts/meta/meta_unit_profile.gd")
const R5_AUTHORITY = preload("res://scripts/mission/mission_combat_authority_contract.gd")
const R5_DEBRIEF = preload("res://scenes/meta/debrief_test_screen.tscn")

func _run() -> void:
	var verdict: Dictionary = R5_GUARD.verdict_from_environment()
	if not bool(verdict.get("ok", false)):
		print("CAMPAIGN_RESPAWN_DISPLAY refused: needs a throwaway profile (SB_REVIEW2_USER_DIR), nothing written. Reason: %s" % str(verdict.get("reason", "")))
		quit(2)
		return
	_configure_entry()
	_formatter_part()
	await _card_and_lock_part()
	await _sheet_part()
	await _skirmish_part()
	await _debrief_part()
	print("CAMPAIGN_RESPAWN_DISPLAY passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

# ---------- Hilfen ----------

func _respawner(seconds: float, death_number: int = 1) -> Dictionary:
	return {"availability_status": "respawning", "status_text": "respawning", "recovery_state": {"state": "respawning", "death_number": death_number, "seconds_total": 3600.0, "seconds_remaining": seconds, "pickup_location_id": "polisa", "source": "left_behind"}}

func _waiting() -> Dictionary:
	return {"availability_status": "awaiting_pickup", "status_text": "awaiting_pickup", "recovery_state": {"state": "awaiting_pickup", "pickup_location_id": "polisa"}}

func _active() -> Dictionary:
	return {"availability_status": "active", "status_text": "", "recovery_state": {}}

## Setzt Felder einer Kaderperson ueber den Weg des Spiels (Kader ersetzen, Ansicht auffrischen).
func _put(unit_id: String, fields: Dictionary, erase_keys: Array = []) -> void:
	var units: Array = Array(_flow.get("_all_team_units")).duplicate(true)
	for unit: Dictionary in units:
		if String(unit.get("unit_id", "")) == unit_id:
			unit.merge(fields, true)
			for key in erase_keys:
				unit.erase(key)
	_flow.call("_replace_roster_units", units)
	_feed()
	_flow.call("_refresh_homebase_screen")

func _set_limit(limit: int) -> void:
	var settings: Dictionary = R5_SETTINGS.load_settings()
	settings[R5_SETTINGS.KEY_CAMPAIGN_RESPAWN_LIMIT] = limit
	R5_SETTINGS.save_settings(settings)

func _sheet_value(unit_id: String, label_name: String) -> String:
	var profile = Dictionary(_screen.get("_profiles_by_id")).get(unit_id, null)
	if profile == null:
		return "<kein Profil>"
	_screen.call("_on_compact_card_open_requested", unit_id, profile, "roster")
	var host: Node = _screen.call("_get_character_sheet_content_host")
	var label: Label = host.find_child("ValueText_" + label_name.to_lower(), true, false) as Label if host != null else null
	return label.text if label != null else "<keine Zeile>"

func _sheet_label(_unit_id: String, label_name: String) -> String:
	var host: Node = _screen.call("_get_character_sheet_content_host")
	var label: Label = host.find_child("ValueLabel_" + label_name.to_lower(), true, false) as Label if host != null else null
	return label.text if label != null else "<keine Beschriftung>"

# ---------- Formatter (rein) ----------

func _formatter_part() -> void:
	var profile = R5_PROFILE.new({"unit_id": "r5_a", "display_name": "Anna", "respawns_used": 2})
	var model: Dictionary = R5_FORMATTER.build_sheet_view_model(profile, {"respawn_limit": 3})
	_check(_row(model, "Respawns") == "2 von 3", "Formatter: 2 von 3 (%s)" % _row(model, "Respawns"))
	_check(_row(R5_FORMATTER.build_sheet_view_model(profile), "Respawns") == "<keine Zeile>", "Formatter: ohne respawn_limit (Skirmish) keine Zeile")
	var old_profile = R5_PROFILE.new({"unit_id": "r5_old", "display_name": "Alt"})
	_check(_row(R5_FORMATTER.build_sheet_view_model(old_profile, {"respawn_limit": 3}), "Respawns") == "0 von 3", "Formatter: Profil ohne respawns_used zeigt 0 von 3")

func _row(model: Dictionary, label_name: String) -> String:
	for row in Array(model.get("status_rows", [])):
		if String(Dictionary(row).get("label", "")) == label_name:
			return String(Dictionary(row).get("value_text", ""))
	return "<keine Zeile>"

# ---------- Personenkarte und Sperre ----------

func _card_and_lock_part() -> void:
	if not await _open("campaign", "new"): return
	_put(LEADER, _respawner(3599.0))
	_check(_card_status(LEADER).begins_with("Gestorben · Respawn in 59:59 | "), "Karte: 3599 s -> 'Gestorben · Respawn in 59:59' (%s)" % _card_status(LEADER))
	_put(LEADER, _respawner(3600.0))
	_check(_card_status(LEADER).begins_with("Gestorben · Respawn in 1:00:00 | "), "Karte: 3600 s -> 'Gestorben · Respawn in 1:00:00' (%s)" % _card_status(LEADER))
	_put(LEADER, _respawner(5400.0))
	_check(_card_status(LEADER).begins_with("Gestorben · Respawn in 1:30:00 | "), "Karte: 5400 s -> 'Gestorben · Respawn in 1:30:00' (%s)" % _card_status(LEADER))
	_check(String(_lock().get(LEADER, "")) == _name(LEADER) + ": gestorben, Respawn in 1:30:00", "Sperre: 'Name: gestorben, Respawn in 1:30:00' (%s)" % _lock())
	# Die Restzeit laeuft auf der offenen Basisansicht weiter (derselbe Weg wie die Uhr der Verwundeten).
	_put(LEADER, _respawner(125.0))
	var card: Node = _card_for(LEADER)
	if not _check(card != null, "Karte: Fixture: Karte der Gestorbenen ist da"): return
	var card_id: int = card.get_instance_id()
	_screen.set("_team_feedback_text", "r5-marker")
	_tick_seconds(2)
	_check(_card_status(LEADER).begins_with("Gestorben · Respawn in 2:03 | "), "Karte: nach zwei Sekunden 2:03 (%s)" % _card_status(LEADER))
	_check(_card_for(LEADER) != null and _card_for(LEADER).get_instance_id() == card_id and String(_screen.get("_team_feedback_text")) == "r5-marker", "Karte: dieselbe Karte, kein Neuaufbau")
	# Uebergang: Ablauf -> "Wartet auf Polisa · abholen".
	_put(LEADER, _respawner(1.0))
	_tick_seconds(1)
	_check(String(_roster_unit(LEADER).get("availability_status", "")) == "awaiting_pickup", "Karte: Fixture: Ablauf macht awaiting_pickup")
	_check(_card_status(LEADER).begins_with("Wartet auf Polisa · abholen | "), "Karte: danach 'Wartet auf Polisa · abholen' (%s)" % _card_status(LEADER))
	_check(String(_lock().get(LEADER, "")) == _name(LEADER) + ": wartet auf Polisa", "Sperre: 'Name: wartet auf Polisa' (%s)" % _lock())
	# Nach dem Abholen: keine Respawn-Zeile mehr.
	_put(LEADER, _active())
	var after: String = _card_status(LEADER)
	_check(not after.contains("Respawn") and not after.contains("Gestorben") and not after.contains("Wartet auf") and not after.contains("abholen"), "Karte: nach dem Abholen keine Respawn-Zeile (%s)" % after)
	_check(not _lock().has(LEADER), "Sperre: nach dem Abholen keine Sperre")

# ---------- Charakterblatt ----------

func _sheet_part() -> void:
	if not await _open("campaign", "new"): return
	var cases := [
		["0 von 3", 0, 3, "0 von 3"],
		["2 von 3", 2, 3, "2 von 3"],
		["3 von 3 mit Zusatz", 3, 3, "3 von 3 · nächster Tod endgültig"],
		["Grenze 0", 0, 0, "0 von 0 · nächster Tod endgültig"],
		["Grenze 9", 4, 9, "4 von 9"],
		["Einstellung 3 -> 1 bei 2 verbrauchten", 2, 1, "2 von 1 · nächster Tod endgültig"],
	]
	for entry in cases:
		_set_limit(int(entry[2]))
		_put(LEADER, {"respawns_used": int(entry[1])})
		var shown: String = _sheet_value(LEADER, "Respawns")
		_check(shown == String(entry[3]), "Blatt (%s): 'Respawns: %s' (ist '%s')" % [entry[0], entry[3], shown])
	_check(_sheet_label(LEADER, "Respawns") == "Respawns:", "Blatt: Beschriftung 'Respawns:' (%s)" % _sheet_label(LEADER, "Respawns"))
	# Jede Kaderperson der Kampagne, nicht nur Gestorbene.
	_set_limit(3)
	_put(PILOT, {"respawns_used": 1})
	_check(_sheet_value(PILOT, "Respawns") == "1 von 3", "Blatt: auch bei einer aktiven Person (Pilot, 1 von 3): '%s'" % _sheet_value(PILOT, "Respawns"))
	# Alter Spielstand ohne respawns_used.
	_put(LEADER, {}, ["respawns_used"])
	_check(_sheet_value(LEADER, "Respawns") == "0 von 3", "Blatt: alter Stand ohne respawns_used zeigt '0 von 3' (%s)" % _sheet_value(LEADER, "Respawns"))
	# Gestorbene Person: Status und Respawn-Zeile stehen zugleich im Blatt.
	_put(LEADER, _respawner(90.0, 2))
	_check(_sheet_value(LEADER, "status") == "Gestorben · Respawn in 1:30", "Blatt: Statuszeile 'Gestorben · Respawn in 1:30' (%s)" % _sheet_value(LEADER, "status"))
	_put(LEADER, _waiting())
	_check(_sheet_value(LEADER, "status") == "Wartet auf Polisa · abholen", "Blatt: Statuszeile 'Wartet auf Polisa · abholen' (%s)" % _sheet_value(LEADER, "status"))
	await _close()

func _skirmish_part() -> void:
	if not await _open("skirmish", "new"): return
	var roster: Array = Array(_flow.get("_all_team_units"))
	if not _check(not roster.is_empty(), "Skirmish: Fixture: Kader ist nicht leer"): return
	var unit_id: String = String(Dictionary(roster[0]).get("unit_id", ""))
	_flow.call("_refresh_homebase_screen")
	_check(_sheet_value(unit_id, "Respawns") == "<keine Zeile>", "Skirmish: Blatt ohne Respawn-Zeile (%s)" % _sheet_value(unit_id, "Respawns"))
	await _close()

# ---------- Einsatzende ----------

func _member(unit_id: String, name: String, vital: String) -> Dictionary:
	return {"unit_id": unit_id, "display_name": name, "vital_state": vital, "health_points": 0 if vital == "dead" else 40, "fireteam_id": "alpha"}

func _death_report(final: bool, death_number: int, limit: int, seconds_total: float) -> Dictionary:
	var report: Dictionary = R5_AUTHORITY.build_mission_result("victory", "", "team_alpha", "objective_capture", false, 42.0, [])
	report["casualty_total_loss"] = false
	report["team_states"] = [_member("u_ok", "Ida", "fit"), _member("u_dead", "Karl", "dead")]
	var entry := {"unit_id": "u_dead", "outcome": "dead", "severity": "", "display_name": "Karl", "final": final, "death_number": death_number}
	if not final:
		entry["respawn_state"] = {"state": "respawning", "death_number": death_number, "seconds_total": seconds_total, "seconds_remaining": seconds_total, "pickup_location_id": "polisa", "source": "left_behind"}
	report["casualties"] = [entry]
	report["fatality_unit_ids"] = PackedStringArray(["u_dead"] if final else [])
	report["respawn_unit_ids"] = PackedStringArray([] if final else ["u_dead"])
	report["respawn_limit"] = limit
	return report

func _open_debrief(report: Dictionary) -> Control:
	var holder := SubViewport.new()
	holder.size = Vector2i(1920, 1080)
	holder.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(holder)
	var screen := R5_DEBRIEF.instantiate() as Control
	screen.visible = true
	holder.add_child(screen)
	screen.call("set_mission_result", report)
	for _i in range(6):
		await process_frame
	return screen

func _debrief_status(screen: Control, unit_id: String) -> String:
	for card in screen.find_children("PersonCard_*", "PanelContainer", true, false):
		if String(card.get_meta("debrief_member_id", "")) == unit_id:
			var label := card.find_child("StatusLabel", true, false) as Label
			return label.text if label != null else "<ohne StatusLabel>"
	return "<keine Karte>"

func _debrief_counts(screen: Control) -> String:
	var label := screen.find_child("TeamStateLabel", true, false) as Label
	return label.text if label != null else "<fehlt>"

func _debrief_part() -> void:
	var original: Dictionary = _death_report(false, 2, 3, 5400.0)
	var report: Dictionary = original.duplicate(true)
	var screen: Control = await _open_debrief(report)
	var text: String = _debrief_status(screen, "u_dead")
	_check(text == "Gestorben · zurückgelassen · Respawn 2 von 3 · Ausfall 90:00, dann auf Polisa · ALPHA", "Debrief: Tod mit Respawn (zweiter Tod, Grenze 3): '%s'" % text)
	_check(_debrief_counts(screen).contains("1 gestorben") and not _debrief_counts(screen).contains("gefallen"), "Debrief: Zählzeile sagt 'gestorben', nicht 'gefallen' (%s)" % _debrief_counts(screen))
	_check(Dictionary(screen.call("get_mission_result")) == original, "Debrief liest nur: Ergebnis unverändert")
	screen.get_parent().queue_free()
	await process_frame
	var first: Control = await _open_debrief(_death_report(false, 1, 3, 3600.0))
	var first_text: String = _debrief_status(first, "u_dead")
	_check(first_text.begins_with("Gestorben · zurückgelassen · Respawn 1 von 3 · Ausfall 60:00, dann auf Polisa"), "Debrief: erster Tod: '%s'" % first_text)
	first.get_parent().queue_free()
	await process_frame
	var final_screen: Control = await _open_debrief(_death_report(true, 4, 3, 0.0))
	var final_text: String = _debrief_status(final_screen, "u_dead")
	_check(final_text == "Gefallen · Respawn-Grenze erreicht (3 von 3) · ALPHA", "Debrief: endgültiger Tod: '%s'" % final_text)
	_check(_debrief_counts(final_screen).contains("1 gefallen") and not _debrief_counts(final_screen).contains("gestorben"), "Debrief: Zählzeile sagt bei endgültigem Tod 'gefallen' (%s)" % _debrief_counts(final_screen))
	final_screen.get_parent().queue_free()
	await process_frame
	# Grenze 0 (Verhalten von Paket 3a): der alte Text bleibt.
	var legacy: Control = await _open_debrief(_death_report(true, 1, 0, 0.0))
	_check(_debrief_status(legacy, "u_dead") == "Gefallen · zurückgelassen · ALPHA", "Debrief: Grenze 0 zeigt den alten Text (%s)" % _debrief_status(legacy, "u_dead"))
	legacy.get_parent().queue_free()
	await process_frame
