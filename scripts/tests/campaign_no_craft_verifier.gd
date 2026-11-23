extends "res://scripts/tests/campaign_craft_loss_second_verifier.gd"
## LC2g Punkt 3 / LC2i I1: Leere Flotte ist keine stumme Sackgasse (Regel: campaign_bankruptcy_rules.gd, Grund "no_craft"; Bildschirm:
## campaign_bankruptcy_screen.gd). Seit LC2i entsteht sie nicht mehr durch einen Abschuss: das letzte Schiff im Einsatz zu verlieren ist ein
## Totalverlust (Stand vor dem Einsatz, Strafe, kein Pleite-Bildschirm). "no_craft" greift nur noch, wenn ein Stand mit leerer Flotte geladen wird.
## N1 (Fluss): ein Schiff, Abschuss -> Meldung und Knopf nennen den Totalverlust, Knopf beendet den Einsatz, Totalverlust-Weg, kein Pleite-Bildschirm.
## N2 (Gegenprobe): bleibt ein Schiff, gilt alles wie bisher (Schiff verloren, Notrettung).
## N3: ein Stand mit leerer Flotte zeigt weiter den Pleite-Bildschirm mit dem Satz "Kein Schiff mehr ...".
const RULES: GDScript = preload("res://scripts/core/campaign_bankruptcy_rules.gd")
const DEBRIEF: GDScript = preload("res://scripts/meta/debrief_screen.gd")
const SCREEN_NAME: String = "CampaignBankruptcyScreen"
const TEXT_NO_CRAFT: String = "Kein Schiff mehr: Ohne Schiff kommst du nicht mehr von der Basis weg."

func _run() -> void:
	_configure_entry()
	_bankruptcy_off = false # hier soll die Pleite-Pruefung laufen
	_rules_part()
	await _n1_last_craft_lost()
	await _n2_other_craft_remains()
	await _n3_empty_fleet_state()
	paused = false
	print("CAMPAIGN_NO_CRAFT passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _rules_part() -> void:
	var empty: Dictionary = RULES.is_bankrupt(-100, 1500, [])
	_check(bool(empty.get("bankrupt", false)) and String(empty.get("cause", "")) == "no_craft", "Regel: leere Flotte ist pleite mit Grund no_craft (%s)" % str(empty))
	_check(bool(RULES.is_bankrupt(500, 0, []).get("bankrupt", false)), "Regel: leere Flotte ist auch ohne Kreditrahmen und mit Guthaben ein Ende")
	_check(not bool(RULES.is_bankrupt(-2000, 1500, [null, "x", 3]).get("bankrupt", true)), "Regel: nur ungueltige Eintraege sind keine leere Flotte (nicht pleite, kein Absturz)")
	_check(not bool(RULES.is_bankrupt(-1500, 1500, [{"craft_id": "f", "phase": "grounded", "next_legs": [{"leg": "launch", "cost": 12.0, "affordable": true}], "refuel_affordable": false}]).get("bankrupt", true)), "Regel: ein flugfaehiges Schiff: nicht pleite")

func _pleite_screen() -> Node:
	return _flow.get_node_or_null(SCREEN_NAME) if _flow != null and is_instance_valid(_flow) else null

func _message() -> String:
	var screen: Node = _pleite_screen()
	var label: Label = screen.find_child("BankruptMessage", true, false) as Label if screen != null else null
	return label.text if label != null else "(kein Bildschirm)"

func _name_of(controller: Node, craft_id: String) -> String:
	return String(Dictionary(controller.call("_find_mission_dropship_card_entry", craft_id)).get("display_name", craft_id))

func _n1_last_craft_lost() -> void:
	var s: Dictionary = await _begin_funded_sortie(500)
	if s.is_empty(): return
	var controller: Node = s.controller
	var ship_name := _name_of(controller, _craft_id)
	_check(_fleet_ids() == [_craft_id], "N1: Aufbau: ein einziges Schiff (%s)" % str(_fleet_ids()))
	_lose_craft(s, "crash", false)
	controller.call("report_ground_fire_vs_air", _craft_id, {}, ["Bruchlandung! %s ist verloren." % ship_name])
	var text := String(controller.get("_last_command_text"))
	_check(text.contains("%s ist verloren – es war euer letztes Schiff. Der Einsatz gilt als Totalverlust." % ship_name) and not text.contains("Notrettung") and not text.contains("Credits"), "N1: die Meldung nennt den Totalverlust, keine Notrettung (%s)" % text)
	var button: Button = controller.call("_ensure_mission_evacuation_button")
	_check(button != null and button.visible and not button.disabled and button.text == "Einsatz abbrechen (Totalverlust)", "N1: Knopf 'Einsatz abbrechen (Totalverlust)', sofort nutzbar (%s)" % (button.text if button != null else "-"))
	_check(button != null and button.tooltip_text == "Ohne Schiff ist der Einsatz verloren. Ihr kehrt zum Stand vor dem Einsatz zurück.", "N1: Hinweis zum Knopf (%s)" % (button.tooltip_text if button != null else "-"))
	if button == null: return
	button.pressed.emit()
	if not await _wait_released("N1: der Knopf beendet den Einsatz"): return
	var result: Dictionary = Dictionary(_flow.get("_last_mission_result"))
	_check(bool(result.get("casualty_total_loss", false)) and bool(result.get("campaign_checkpoint_retry_required", false)) and String(result.get("total_loss_reason", "")) == "last_craft_lost", "N1: Totalverlust mit Ruecksprung, Grund last_craft_lost (%s)" % str(result.get("total_loss_reason")))
	_check(not result.has("craft_loss") and not result.has("other_craft_losses"), "N1: kein Schiffsverlust und keine Notrettungsgebuehr gebucht")
	_check(_fleet_ids() == [_craft_id] and _lost_ids().is_empty(), "N1: die Flotte ist unveraendert, kein Verlustbeleg (%s / %s)" % [str(_fleet_ids()), str(_lost_ids())])
	var screen: Node = _flow.call("_get_debrief_screen")
	var shown: String = String(screen.get("_native_review_confirmation").text) if screen != null and screen.get("_native_review_confirmation") != null else ""
	_check(shown.contains("Das letzte Schiff ist verloren. Der Einsatz gilt als Totalverlust."), "N1: die Nachbesprechung nennt den Grund (%s)" % shown.replace("\n", " | "))
	_flow.call("_check_bankruptcy")
	await process_frame
	_check(_pleite_screen() == null and not bool(_flow.call("is_campaign_bankrupt")), "N1: kein Pleite-Bildschirm")
	if not await _press_continue(): return
	_check(_fleet_ids() == [_craft_id] and _credits() == 100, "N1: nach dem Ruecksprung: Schiff da, Strafe wie beim Totalverlust, 500 -> 100 (%s / %d)" % [str(_fleet_ids()), _credits()])
	_flow.call("_check_bankruptcy")
	await process_frame
	_check(_pleite_screen() == null, "N1: auch danach kein Pleite-Bildschirm")
	var saved: Dictionary = {}
	await _wait(func():
		saved.clear()
		saved.merge(Dictionary(_flow.call("request_campaign_save")))
		return bool(saved.get("ok", false)), 60000, "N1: Speichern nach dem Ruecksprung gelingt")
	await _close()
	if not await _open_scene("campaign", "continue_home"): return
	_check(_fleet_ids() == [_craft_id] and _credits() == 100, "N1: Laden: Schiff da, 100 Credits (%s / %d)" % [str(_fleet_ids()), _credits()])
	paused = false
	await _close()

func _n2_other_craft_remains() -> void:
	var s: Dictionary = await _begin_funded_sortie(500)
	if s.is_empty(): return
	var second := _inject_bought_ship()
	_lose_craft(s)
	var controller: Node = s.controller
	controller.call("report_ground_fire_vs_air", _craft_id, {}, ["Bruchlandung! X ist verloren."])
	_check(not String(controller.get("_last_command_text")).contains("letztes Schiff") and String(controller.get("_last_command_text")).contains("Notrettung"), "N2: bleibt ein Schiff, meldet der Einsatz die Notrettung, nicht den Totalverlust")
	s.driver.call("_resolve_combat", "aborted", "", "evacuation")
	if not await _wait_released("N2: Einsatz wird freigegeben"): return
	_check(_fleet_ids() == [second], "N2: das Einsatzschiff ist verloren, das zweite bleibt (%s)" % str(_fleet_ids()))
	var result: Dictionary = Dictionary(_flow.get("_last_mission_result"))
	_check(not bool(result.get("casualty_total_loss", false)) and int(Dictionary(result.get("craft_loss", {})).get("rescue_fee", -1)) == 400 and _credits() == 100, "N2: Notrettung 400 gebucht, kein Totalverlust (%d)" % _credits())
	var verdict: Dictionary = _runtime.call("get_bankruptcy_check")
	_check(String(verdict.get("cause", "")) != "no_craft", "N2: mit einem verbliebenen Schiff gilt nicht no_craft (%s)" % str(verdict))
	_flow.call("_check_bankruptcy")
	await process_frame
	_check(_message() != TEXT_NO_CRAFT, "N2: der Satz 'Kein Schiff mehr' erscheint nicht (%s)" % _message())
	paused = false
	await _close()

## N3: Ein geladener Stand mit leerer Flotte (aus einem Stand vor LC2i) zeigt weiter den Pleite-Bildschirm mit dem Satz "Kein Schiff mehr ...".
func _n3_empty_fleet_state() -> void:
	var s: Dictionary = await _begin_funded_sortie(500)
	if s.is_empty(): return
	s.driver.call("_resolve_combat", "aborted", "", "evacuation")
	if not await _wait_released("N3: Einsatz wird freigegeben"): return
	_flow.call("_retire_lost_craft", {"craft_id": _craft_id, "ship_name": "Altschiff", "outcome": "crash", "rescue_fee": 0})
	_check(_fleet_ids().is_empty(), "N3: Aufbau: die Flotte ist leer (%s)" % str(_fleet_ids()))
	_flow.call("_check_bankruptcy")
	await process_frame
	_check(_pleite_screen() != null and bool(_flow.call("is_campaign_bankrupt")) and _message() == TEXT_NO_CRAFT, "N3: Pleite-Bildschirm mit dem Satz 'Kein Schiff mehr' (%s)" % _message())
	var screen: Node = _pleite_screen()
	for button_name in ["BankruptLoad", "BankruptNewCampaign", "BankruptMainMenu"]:
		_check(screen != null and screen.find_child(button_name, true, false) is Button, "N3: Knopf %s ist da" % button_name)
	_check(not bool(Dictionary(_flow.call("request_campaign_save")).get("ok", true)), "N3: Speichern ist gesperrt wie bei der Pleite")
	paused = false
	await _close()
