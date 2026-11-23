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
	await _h3_debrief()
	await _h4_save_sentence()
	await _h5_story_steps()
	await _h6_cargo()
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
	_inject_bought_ship("2", "Drittschiff") # LC2i: bleibt als Reserve, damit beide Verluste nicht das letzte Schiff treffen
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
	_inject_bought_ship("2", "Drittschiff") # LC2i: Reserve, damit der Verlust nicht das letzte Schiff trifft
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

const DEBRIEF_SCRIPT = preload("res://scripts/meta/debrief_screen.gd")

func _h3_debrief() -> void:
	_check(DEBRIEF_SCRIPT.build_craft_loss_text({"result": "victory"}) == "", "H3: ohne Schiffsverlust keine Zeile")
	var s: Dictionary = await _begin_funded_sortie(500)
	if s.is_empty(): return
	var second := _inject_bought_ship()
	_inject_bought_ship("2", "Drittschiff") # LC2i: Reserve, damit der Verlust nicht das letzte Schiff trifft
	var first_name := _ship_name_of(s.controller, _craft_id)
	_site(s, _craft_id)
	_site(s, second, "explosion")
	s.driver.call("_resolve_combat", "aborted", "", "evacuation")
	if not await _wait_released("H3: Einsatz wird freigegeben"): return
	var result: Dictionary = Dictionary(_flow.get("_last_mission_result"))
	var text: String = DEBRIEF_SCRIPT.build_craft_loss_text(result)
	_check(text.contains("Schiff verloren: %s" % first_name) and text.contains("Notrettung: −400 Credits") and text.contains("Schiff verloren: Zweitschiff"), "H3: Zeilen je verlorenem Schiff und die gebuchte Gebuehr (%s)" % text.replace("\n", " | "))
	_check(text.count("Notrettung") == 1, "H3: die Gebuehr steht einmal (nur das Einsatzschiff)")
	var screen: Node = _flow.call("_get_debrief_screen")
	var shown: String = String(screen.get("_native_review_confirmation").text) if screen != null and screen.get("_native_review_confirmation") != null else ""
	_check(shown.contains("Schiff verloren: %s" % first_name) and shown.contains("Notrettung: −400 Credits"), "H3: die Zeilen stehen in der Nachbesprechung (%s)" % shown.replace("\n", " | "))
	await _end_sortie()

## H5: Kiste laden und Anwerben sind an das Auftragsschiff gebunden; ist es verloren (Verlustbeleg), erfuellt jedes Schiff der Flotte den Schritt.
func _h5_story_steps() -> void:
	START.request_start(self, "campaign", "new")
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	current_scene = _flow
	await process_frame
	_runtime = _flow.get("_singleplayer_runtime")
	if not _check(_runtime != null, "H5: Aufbau: Meta-Szene und Laufzeit"): return
	var second := _inject_bought_ship()
	# Aufbau: Auftrag 2 ist abgeschlossen und hat das Einsatzschiff als Auftragsschiff.
	var jobs: Dictionary = _runtime.get("_campaign").get("_jobs")
	jobs["outpost_recovery"]["status"] = "completed"
	jobs["outpost_recovery"]["craft_id"] = _craft_id
	var control: Dictionary = _runtime.call("request_operation", "campaign_recruit", {"craft_id": second})
	_check(not bool(control.get("ok", false)) and String(control.get("reason", "")) == "recruit_craft_required", "H5: ohne Verlust verlangt Anwerben das Auftragsschiff (%s)" % str(control))
	var crate_control: Dictionary = _runtime.call("request_operation", "campaign_load_crate", {"craft_id": second})
	_check(not bool(crate_control.get("ok", false)) and String(crate_control.get("reason", "")) == "crate_not_here", "H5: ohne Verlust verlangt Kiste laden das Auftragsschiff (%s)" % str(crate_control))
	_flow.call("_retire_lost_craft", {"craft_id": _craft_id, "ship_name": "Auftragsschiff", "outcome": "crash", "rescue_fee": 0})
	_check(_fleet_ids() == [second], "H5: Aufbau: nur das zweite Schiff ist in der Flotte (%s)" % str(_fleet_ids()))
	var recruit: Dictionary = _runtime.call("request_operation", "campaign_recruit", {"craft_id": second})
	_check(String(recruit.get("reason", "")) != "recruit_craft_required", "H5: nach dem Verlust zaehlt fuers Anwerben jedes Schiff der Flotte (%s)" % str(recruit))
	var crate: Dictionary = _runtime.call("request_operation", "campaign_load_crate", {"craft_id": second})
	_check(bool(crate.get("ok", false)) and bool(Dictionary(Dictionary(_runtime.get("_campaign").call("get_campaign_snapshot")).get("progress", {})).get("crate_loaded", false)), "H5: nach dem Verlust laesst sich die Kiste mit dem zweiten Schiff laden (%s)" % str(crate))
	var home_services: Dictionary = Dictionary(Dictionary(_flow.call("get_singleplayer_snapshot")).get("home_services", {}))
	_check(Array(home_services.get("lost_craft_ids", [])).has(_craft_id), "H5: die Anzeige weiss vom Verlust des Auftragsschiffs (%s)" % str(home_services.get("lost_craft_ids")))
	await _close()

## H6: Der Frachtraum eines verlorenen Schiffs ist verloren (das Wrack wird spaeter geborgen - eigener Auftrag). Auftragsfracht (die C-Benit-Kiste)
## geht damit auch verloren; BEFUND (siehe Bericht): die Kampagne merkt es nicht, crate_loaded bleibt wahr.
func _h6_cargo() -> void:
	START.request_start(self, "campaign", "new")
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	current_scene = _flow
	await process_frame
	_runtime = _flow.get("_singleplayer_runtime")
	if not _check(_runtime != null, "H6: Aufbau: Meta-Szene und Laufzeit"): return
	var second := _inject_bought_ship()
	var inventory: Dictionary = _runtime.get("_supply").get("_inventory")
	var key := "craft:" + second
	if not _check(inventory.has(key), "H6: Aufbau: das zweite Schiff hat einen Frachtraum (%s)" % str(inventory.keys())): return
	_runtime.get("_campaign").get("_progress")["crate_loaded"] = true
	Dictionary(inventory[key].items)["c_benit_crate"] = 1
	Dictionary(inventory[key].items)["fuel_can"] = 1
	_flow.call("_retire_lost_craft", {"craft_id": second, "ship_name": "Zweitschiff", "outcome": "crash", "rescue_fee": 0})
	inventory = _runtime.get("_supply").get("_inventory")
	var crate_anywhere := false
	for id in inventory:
		if int(Dictionary(Dictionary(inventory[id]).get("items", {})).get("c_benit_crate", 0)) > 0: crate_anywhere = true
	_check(not inventory.has(key) and not crate_anywhere, "H6: der Frachtraum des verlorenen Schiffs ist weg, samt Inhalt (Lager da: %s, Kiste irgendwo: %s)" % [str(inventory.has(key)), str(crate_anywhere)])
	print("H6_BEFUND crate_loaded=", Dictionary(Dictionary(_runtime.get("_campaign").call("get_campaign_snapshot")).get("progress", {})).get("crate_loaded"), " (bleibt wahr, obwohl die Kiste mit dem Schiff verloren ist)")
	await _close()

## H4: Im Einsatz nach dem Abschuss lehnt das Speichern ab (LC2b); der Satz nennt das Schiff beim Namen (Speichern von Hand und Menue-Projektion).
func _h4_save_sentence() -> void:
	var s: Dictionary = await _begin_funded_sortie(500)
	if s.is_empty(): return
	var name := _ship_name_of(s.controller, _craft_id)
	var before: Dictionary = _flow.call("request_campaign_save")
	_check(not String(before.get("message", "")).contains("abgestürzt"), "H4: ohne Absturz kein Absturzsatz (%s)" % str(before.get("message", "")))
	_site(s, _craft_id)
	# Der Grund mission_lifecycle_unsupported kommt erst, wenn die Befehlswarteschlange leer ist (davor "wartet auf laufende Befehle", in diesem
	# Aufbau ohne Takt nie); deshalb: Detail und Satz getrennt pruefen, und sobald die echte Ablehnung der Absturzgrund ist, muss sie den Namen tragen.
	_check(String(_flow.call("crash_save_detail")) == "lost:" + name, "H4: Detail fuer den Speichersatz nennt das Schiff (%s)" % String(_flow.call("crash_save_detail")))
	var projection_script = load("res://scripts/meta/campaign_save_projection.gd")
	var sentence: String = projection_script.blocked_text("mission_lifecycle_unsupported", "lost:" + name)
	_check(sentence.contains("%s ist abgestürzt" % name) and not sentence.contains("ein abgestürztes Schiff"), "H4: der Speichersatz nennt das Schiff (%s)" % sentence)
	_check(String(projection_script.blocked_text("mission_lifecycle_unsupported", "")).contains("ein abgestürztes Schiff"), "H4: ohne Namen bleibt der bisherige Satz")
	var refused: Dictionary = _flow.call("request_campaign_save")
	if String(refused.get("reason", "")) == "mission_lifecycle_unsupported":
		_check(String(refused.get("message", "")).contains("%s ist abgestürzt" % name), "H4: die echte Ablehnung nennt das Schiff (%s)" % String(refused.get("message", "")))
	var projection: Dictionary = Dictionary(_flow.get("_campaign_start").call("get_save_projection", _flow, _runtime))
	if String(projection.get("save_blocked_reason", "")) == "mission_lifecycle_unsupported":
		_check(String(projection.get("save_blocked_text", "")).contains("%s ist abgestürzt" % name), "H4: die Projektion fuer das Menue nennt das Schiff (%s)" % String(projection.get("save_blocked_text", "")))
	print("H4_REAL reason=", refused.get("reason"), " projection_reason=", projection.get("save_blocked_reason"))
	s.driver.call("_resolve_combat", "aborted", "", "evacuation")
	if not await _wait_released("H4: Einsatz wird freigegeben"): return
	await _end_sortie()
