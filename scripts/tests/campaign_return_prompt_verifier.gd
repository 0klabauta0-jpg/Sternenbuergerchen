extends SceneTree
## Rueckfrage vor dem Rueckzug (Rueckflug-Knopf, Nachbesserung 1): lesbare Schrittnamen (W3), nur das Schiff des Auftrags setzt den
## Rueckkehr-Schritt (W4), Rueckfrage beginnt neu, wenn sich die offenen Schritte aendern (K5). Gerechnet wird mit den ECHTEN
## Szenariodateien der Kampagnenauftraege; die Entscheidungen stecken in scripts/mission/campaign_return_prompt.gd, das der
## Missions-Controller benutzt. Schlusszeile: RETURN_PROMPT passed=N failed=M
const HELPER_PATH := "res://scripts/mission/campaign_return_prompt.gd"
const CAMPAIGN_SCENARIOS: Array = ["satellite_recovery", "outpost_recovery", "benit_delivery", "outpost_chip_recovery", "buccaneer_rescue"]

var passed := 0
var failed := 0
var _ran := false
var _helper: Variant = null


func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("FAIL ", label)


func _process(_delta: float) -> bool:
	if _ran:
		return true
	_ran = true
	if ResourceLoader.exists(HELPER_PATH):
		_helper = load(HELPER_PATH)
	_check(_helper != null, "Hilfsskript %s ist vorhanden" % HELPER_PATH)
	if _helper != null:
		_case_scenario_step_names()
		_case_fallbacks()
		_case_job_craft()
		_case_open_signature()
	print("RETURN_PROMPT passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)
	return true


func _scenario(id: String) -> Dictionary:
	var text: String = FileAccess.get_file_as_string("res://data/mission_scenarios/%s.json" % id)
	var parsed: Variant = JSON.parse_string(text)
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _binding_name(scenario: Dictionary, step_id: String) -> String:
	for point in Array(Dictionary(scenario.get("vertical_slice", {})).get("interaction_points", [])):
		if String(Dictionary(point).get("step_id", "")) == step_id:
			return String(Dictionary(point).get("display_name", ""))
	return ""


## Jeder Schritt jedes Kampagnenauftrags hat einen lesbaren deutschen Namen, nie eine rohe Kennung mit Unterstrich.
func _case_scenario_step_names() -> void:
	var seen := 0
	for id in CAMPAIGN_SCENARIOS:
		var scenario: Dictionary = _scenario(String(id))
		_check(not scenario.is_empty(), "%s: Szenariodatei lesbar" % id)
		for step in Array(Dictionary(scenario.get("vertical_slice", {})).get("flow_steps", [])):
			var step_id: String = String(Dictionary(step).get("step_id", ""))
			var name: String = String(_helper.call("step_display_name", step_id, _binding_name(scenario, step_id), scenario))
			seen += 1
			print("RETURN_PROMPT_NAME ", id, " ", step_id, " -> ", name)
			_check(not name.is_empty() and not name.contains("_") and name != step_id, "%s/%s: lesbarer Name statt Kennung (Name: '%s')" % [id, step_id, name])
	_check(seen >= 10, "Es wurden Schritte der Kampagnenauftraege geprueft (%d)" % seen)
	# Der Aussenposten-Schritt ohne Benutzen-Stelle: clear_outpost bekommt den Namen der Wache, nicht die Kennung.
	var outpost: Dictionary = _scenario("outpost_recovery")
	var clear_name: String = String(_helper.call("step_display_name", "clear_outpost", "", outpost))
	_check(clear_name.contains("Außenpostenwache") and not clear_name.contains("clear_outpost"), "outpost_recovery/clear_outpost nennt die Wache (Name: '%s')" % clear_name)
	# Freiwillige Ziele des Briefings stehen nie fuer einen Pflichtschritt.
	_check(not clear_name.begins_with("Freiwillig"), "Der freiwillige Briefing-Eintrag der Wache steht nicht fuer den Pflichtschritt")


func _case_fallbacks() -> void:
	var fallback: String = String(_helper.call("step_display_name", "unbekannter_schritt_x", "", {}))
	_check(fallback == "ein weiterer Auftragsschritt", "Ohne Namen im Szenario: deutscher Ersatztext (Text: '%s')" % fallback)
	var raw_binding: String = String(_helper.call("step_display_name", "clear_outpost", "clear_outpost", {}))
	_check(raw_binding == "ein weiterer Auftragsschritt", "Ein Anzeigename, der nur die Kennung wiederholt, zaehlt nicht (Text: '%s')" % raw_binding)
	var named: String = String(_helper.call("step_display_name", "secure_satellite", "Satellitendaten sichern", {}))
	_check(named == "Satellitendaten sichern", "Ein lesbarer Anzeigename der Benutzen-Stelle bleibt (Text: '%s')" % named)


## W4: nur das Schiff des Auftrags (identity.craft_id) darf den Rueckkehr-Schritt setzen.
func _case_job_craft() -> void:
	var identity := {"job_id": "satellite_recovery", "craft_id": "dropship_1"}
	_check(bool(_helper.call("is_job_craft", identity, "dropship_1")), "W4: das Schiff des Auftrags gilt als Auftragsschiff")
	_check(not bool(_helper.call("is_job_craft", identity, "campaign_buccaneer_01")), "W4: ein anderes Schiff gilt nicht als Auftragsschiff")
	_check(bool(_helper.call("is_job_craft", {"job_id": "satellite_recovery"}, "dropship_1")), "W4: ohne Schiffskennung im Auftrag bleibt das alte Verhalten (jedes Schiff)")
	_check(not bool(_helper.call("is_job_craft", identity, "")), "W4: ohne gedrueckte Schiffskennung kein Auftragsschiff")


## K5: Aendern sich die offenen Schritte, ist es eine neue Rueckfrage.
func _case_open_signature() -> void:
	var two: String = String(_helper.call("open_signature", ["a", "b"]))
	var one: String = String(_helper.call("open_signature", ["a"]))
	_check(two != one and two == String(_helper.call("open_signature", ["a", "b"])), "K5: gleiche offene Schritte gleiche Signatur, andere eine andere")
