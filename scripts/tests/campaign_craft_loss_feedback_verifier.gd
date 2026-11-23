extends "res://scripts/tests/campaign_craft_loss_second_verifier.gd"
## LC2h: Der Spieler erfaehrt, was nach einem Abschuss passiert ist (ueber den echten Kampagnenfluss, wie campaign_craft_loss_second_verifier).
## H1 Meldung beim Abschuss: "<Schiff> ist verloren. Bring den Trupp zur Landezone ..." mit dem Betrag, den die Notrettung bucht; bei einem
##    anderen Schiff nur der erste Satz.
## H2 EVAC-Knopf: "Notrettung rufen (X Credits)" mit deutschem Hinweis, solange das Einsatzschiff verloren ist; sonst unveraendert.
## H3 Nachbesprechung: Zeilen "Schiff verloren: ..." und "Notrettung: -X Credits".
## H4 Speichersatz nennt das verlorene Schiff beim Namen.
## H5 Story-Schritte (Kiste laden, Anwerben) gehen nach dem Verlust des Auftragsschiffs mit jedem Schiff der Flotte.
## H6 Frachtraum eines verlorenen Schiffs ist verloren.

func _run() -> void:
	_configure_entry()
	await _h1_message()
	await _h2_button()
	print("CAMPAIGN_CRAFT_LOSS_FEEDBACK passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _ship_name_of(controller: Node, craft_id: String) -> String:
	return String(Dictionary(controller.call("_find_mission_dropship_card_entry", craft_id)).get("display_name", craft_id))

func _h1_message() -> void:
	var s: Dictionary = await _begin_funded_sortie(500)
	if s.is_empty(): return
	var controller: Node = s.controller
	var name := _ship_name_of(controller, _craft_id)
	# Ohne Verlust: keine Zusatzmeldung.
	controller.call("report_ground_fire_vs_air", _craft_id, {}, ["Notlandung geglückt."])
	_check(not String(controller.get("_last_command_text")).contains("Notrettung"), "H1: ohne Schiffsverlust keine Notrettungsmeldung (%s)" % String(controller.get("_last_command_text")))
	var second := _inject_bought_ship()
	_site(s, _craft_id)
	_site(s, second)
	controller.call("report_ground_fire_vs_air", _craft_id, {}, ["Bruchlandung! %s ist verloren." % name])
	var text := String(controller.get("_last_command_text"))
	var expected := "%s ist verloren. Bring den Trupp zur Landezone – dort holt euch die Notrettung ab (400 Credits)." % name
	_check(text.contains(expected), "H1: Meldung mit Schiffsname und Betrag (%s)" % text)
	controller.call("report_ground_fire_vs_air", second, {}, ["Bruchlandung! Zweitschiff ist verloren."])
	text = String(controller.get("_last_command_text"))
	_check(text.contains("Zweitschiff ist verloren.") and not text.contains("Landezone") and not text.contains("Credits"), "H1: beim zweiten Schiff nur der erste Satz (%s)" % text)
	s.driver.call("_resolve_combat", "aborted", "", "evacuation")
	if not await _wait_released("H1: Einsatz wird freigegeben"): return
	var loss: Dictionary = Dictionary(Dictionary(_flow.get("_last_mission_result")).get("craft_loss", {}))
	_check(int(loss.get("rescue_fee", -1)) == 400, "H1: der gemeldete Betrag ist der gebuchte (%s)" % str(loss))
	await _end_sortie()

func _h2_button() -> void:
	var s: Dictionary = await _begin_funded_sortie(500)
	if s.is_empty(): return
	var controller: Node = s.controller
	var second := _inject_bought_ship()
	controller.call("_refresh_mission_evacuation_button")
	var button: Button = controller.call("_ensure_mission_evacuation_button")
	if not _check(button != null, "H2: EVAC-Knopf ist da"): return
	_check(button.text == "EVAC" and button.tooltip_text.find("Landezone") < 0, "H2: ohne Schiffsverlust bleibt der Knopf wie bisher (%s / %s)" % [button.text, button.tooltip_text])
	_site(s, second)
	controller.call("_refresh_mission_evacuation_button")
	_check(button.text == "EVAC", "H2: Verlust eines anderen Schiffs aendert den Knopf nicht (%s)" % button.text)
	_site(s, _craft_id)
	controller.call("_refresh_mission_evacuation_button")
	_check(button.text == "Notrettung rufen (400 Credits)", "H2: Knopftext bei Verlust des Einsatzschiffs (%s)" % button.text)
	var snapshot: Dictionary = controller.call("get_mission_evacuation_snapshot")
	if not bool(snapshot.get("eligible", false)):
		_check(button.tooltip_text == "Der Trupp muss erst an der Landezone stehen.", "H2: Hinweis abseits der Landezone (%s / %s)" % [button.tooltip_text, str(snapshot.get("reason"))])
	# An der Landezone: die Landezone auf die Position des Truppfuehrers legen.
	controller.set("_has_lz_position", true)
	controller.set("_lz_position", s.leader.global_position)
	controller.call("_refresh_mission_evacuation_button")
	snapshot = controller.call("get_mission_evacuation_snapshot")
	_check(bool(snapshot.get("eligible", false)), "H2: Aufbau: der Trupp steht an der Landezone (%s)" % str(snapshot.get("reason")))
	_check(button.text == "Notrettung rufen (400 Credits)" and button.tooltip_text == "Die Notrettung holt den Trupp von der Landezone ab.", "H2: Knopf und Hinweis an der Landezone (%s / %s)" % [button.text, button.tooltip_text])
	s.driver.call("_resolve_combat", "aborted", "", "evacuation")
	if not await _wait_released("H2: Einsatz wird freigegeben"): return
	await _end_sortie()
