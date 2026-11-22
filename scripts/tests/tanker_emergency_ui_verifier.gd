extends "res://scripts/tests/campaign_casualty_apply_verifier.gd"
## T3 des Tanker-Auftrags (22.11.2026): Nottankdienst bedienen und anzeigen. Echte Szene, echter Adapter, echter Dienst, echter Tick.
## Die Knoepfe werden gedrueckt wie von der Maus (pressed.emit() auf dem echten Button der Sternkarte bzw. der Schiffskarte des Ortes),
## nicht die Funktionen dahinter gerufen. Die Oberflaeche liest nur die Auskunft des Adapters (get_emergency_tanker_view).
## Die Dienstzeiten werden in den Daten verkuerzt (5/60/10 s waeren hier zu lang); Menge, Preis und Satz sind die der Daten (30 / 100 + 30 x 6).
## Nicht geprueft ohne Bildschirm: das Aussehen (Abstaende, Farben, Zeilenumbruch, Lage in der Seitenleiste bzw. auf der Karte).

const FLOW_SCENE: String = "res://scenes/meta/meta_layer_test.tscn"
const DATA_PATH: String = "res://data/singleplayer/trade_offers.json"
const UI_TIMES: Dictionary = {"dispatch_seconds": 0.5, "response_seconds": 1.5, "refuel_seconds": 1.0}
const TANKER_OPEN_TEXT: String = "Ein Tanker ist unterwegs - erst abwarten oder stornieren."

func _run() -> void:
	# Mit dem Argument "surface" (nach "--") laeuft nur der Teil an der Schiffskarte des Ortes; ohne Argument laeuft alles.
	var only_surface: bool = OS.get_cmdline_user_args().has("surface")
	if not only_surface:
		await _scenario_hidden_without_problem()
		await _scenario_offer_and_order()
		await _scenario_cancel_texts()
		await _scenario_too_poor()
	await _scenario_surface_card_and_gate()
	print("TANKER_EMERGENCY_UI passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)

func _data() -> Dictionary:
	return Dictionary(JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)))

# --- Sitzung (wie tanker_emergency_flow_verifier.gd, eigene Dienstzeiten) ------------------------------------------

func _ui_session(initial_fuel: float) -> Dictionary:
	_configure_entry()
	var flow: Node = load(FLOW_SCENE).instantiate()
	_flow = flow
	root.add_child(flow)
	await process_frame
	var runtime: Object = flow.get("_singleplayer_runtime")
	var screen: Node = flow.get_node("HomebaseScreen")
	_screen = screen
	_runtime = runtime
	_check(await _prepare_initial_base(), "Sitzung: echte Basis mit Pilot und Crew an Bord ist bereit")
	var supply: Object = runtime.get("_supply")
	var data: Dictionary = _data()
	data.emergency_fuel.merge(UI_TIMES, true)
	supply.configure(flow.get("_homebase_aircraft_definitions"), data)
	var tanks: Dictionary = supply.get("_fuel_by_craft_id")
	for tank_id: String in tanks.keys(): tanks[tank_id] = initial_fuel
	screen.request_operation("accept_job", {"job_id": "satellite_recovery"})
	screen.request_operation("select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery"})
	return {"flow": flow, "runtime": runtime, "supply": supply, "screen": screen, "craft_id": _craft_id}

func _ui_close(session: Dictionary) -> void:
	session.flow.queue_free()
	await process_frame
	await process_frame

func _ui_phase(session: Dictionary) -> String:
	return String(session.runtime.get_space_travel_snapshot(session.craft_id).get("phase", ""))

func _ui_wait(predicate: Callable, timeout_msec: int) -> bool:
	var deadline: int = Time.get_ticks_msec() + timeout_msec
	while not predicate.call() and Time.get_ticks_msec() < deadline:
		await process_frame
	return predicate.call()

func _ui_launch(session: Dictionary) -> bool:
	session.screen.request_operation("start", {"craft_id": session.craft_id})
	return _ui_phase(session) == "orbit"

## Sitzung mit knappem Tank im Mondorbit (nach dem Abheben 5): der Sprung zum Ziel (10) ist nicht gedeckt.
func _ui_orbit_session(initial_fuel: float = 6.0) -> Dictionary:
	var s: Dictionary = await _ui_session(initial_fuel)
	_check(_ui_launch(s), "Sitzung: Abheben angenommen, Schiff im Mondorbit")
	return s

# --- Knoten und Anzeige --------------------------------------------------------------------------------------------

func _star(s: Dictionary) -> Control:
	return s.flow.get("_star_map_screen")

func _panel(s: Dictionary) -> Node:
	return _star(s).get("_tanker_panel")

## Die Sternkarte liest neu (refresh), das Feld liest die Auskunft (poll): wie der Takt der echten Anzeige.
func _sync(s: Dictionary) -> Dictionary:
	_star(s).call("refresh")
	var panel: Node = _panel(s)
	panel.call("poll")
	return panel.call("get_ui_snapshot")

func _button(panel: Node, node_name: String) -> Button:
	return panel.find_child(node_name, true, false) as Button

func _press(panel: Node, node_name: String) -> void:
	var button: Button = _button(panel, node_name)
	if button == null:
		_check(false, "Knopf %s fehlt" % node_name)
		return
	button.pressed.emit()

func _order_state(s: Dictionary) -> String:
	return String(Dictionary(Dictionary(s.runtime.get_emergency_tanker_snapshot().get("orders", {})).get(s.craft_id, {})).get("state", ""))

func _orders_count(s: Dictionary) -> int:
	return Dictionary(s.runtime.get_emergency_tanker_snapshot().get("orders", {})).size()

# --- a) ohne Treibstoffproblem kein Knopf -------------------------------------------------------------------------------

func _scenario_hidden_without_problem() -> void:
	var s: Dictionary = await _ui_session(50.0)
	var at_home: Dictionary = _sync(s)
	_check(not bool(at_home.visible) and not bool(at_home.call_visible), "a: daheim am Boden ist kein Knopf und kein Feld da: " + str(at_home))
	_check(_ui_launch(s), "a: Abheben angenommen")
	var covered: Dictionary = _sync(s)
	_check(not bool(covered.visible) and not bool(covered.call_visible) and not bool(covered.offer_visible), "a: im Orbit mit gedeckter Etappe (49 Treibstoff) ist kein Knopf da: " + str(covered))
	await _ui_close(s)

# --- b, c, d, i) Angebot, Bestellung, Zustandszeilen, Mondorbit-Hinweis -----------------------------------------------

func _scenario_offer_and_order() -> void:
	var s: Dictionary = await _ui_orbit_session()
	var supply: Object = s.supply
	var craft_id: String = s.craft_id
	var data: Dictionary = _data().emergency_fuel
	data.merge(UI_TIMES, true)
	var panel: Node = _panel(s)
	var shown: Dictionary = _sync(s)
	_check(bool(shown.visible) and bool(shown.call_visible) and not bool(shown.call_disabled) and not bool(shown.offer_visible), "b: das Schiff bleibt im Orbit liegen -> der Knopf 'Tanker rufen' ist da, nicht grau, noch kein Angebot: " + str(shown))
	_check(_button(panel, "TankerCall").text == "Tanker rufen", "b: der Knopf heisst 'Tanker rufen'")
	var credits: int = supply.get_credits()
	var revision: int = supply.get_revision()
	_press(panel, "TankerCall")
	var offer_view: Dictionary = _sync(s)
	var first_request: String = String(offer_view.request_id)
	var quantity: int = int(data.quantity)
	var price: int = int(data.callout_fee) + int(ceil(float(quantity) * float(data.price_per_unit)))
	var wait: int = int(ceil(float(data.dispatch_seconds) + float(data.response_seconds)))
	_check(bool(offer_view.offer_visible), "b: ein Klick klappt das Angebot an Ort und Stelle auf")
	_check(String(offer_view.offer).contains("Lieferung: %d Einheiten" % quantity), "b: das Angebot nennt die Liefermenge (30 aus den Daten): " + String(offer_view.offer))
	_check(String(offer_view.offer).contains("Anfahrt %d Cr + %d × 6 Cr = %d Cr" % [int(data.callout_fee), quantity, price]) and price == 280, "b: der Preis ist ausgeschrieben: Anfahrt 100 Cr + 30 × 6 Cr = 280 Cr")
	_check(String(offer_view.offer).contains("Wartezeit: etwa %d s" % wait), "b: die Wartezeit steht im Angebot (aus den Daten, %d s)" % wait)
	_check(String(offer_view.offer).contains("Danach: Treibstoff 35 von 100") and String(offer_view.offer).contains("Sprung (10 ✓)"), "b: das Angebot sagt, wie weit die Menge reicht (35 von 100, der Sprung 10 ist dann gedeckt): " + String(offer_view.offer))
	_check(String(offer_view.offer).contains("Die Heimlandung kostet keinen Treibstoff."), "i: im Mondorbit der Heimat steht der Hinweis auf die kostenlose Heimlandung")
	_check(supply.get_credits() == credits and supply.get_revision() == revision and _orders_count(s) == 0, "b: das Angebot bucht nichts und legt keinen Auftrag an")
	_press(panel, "TankerOfferDismiss")
	var dismissed: Dictionary = _sync(s)
	_check(not bool(dismissed.offer_visible) and bool(dismissed.call_visible), "b: 'Abbrechen' schliesst das Angebot, der Knopf bleibt")
	_check(supply.get_credits() == credits and supply.get_revision() == revision and _orders_count(s) == 0, "b: 'Abbrechen' bucht nichts")
	# c) Bestellen: genau einmal, auch bei Doppelklick; jeder Ruf bildet eine neue Anfrage-ID.
	_press(panel, "TankerCall")
	var second_open: Dictionary = _sync(s)
	_check(String(second_open.request_id) != first_request and not String(second_open.request_id).is_empty(), "c: jeder Ruf bildet eine neue Anfrage-ID (%s != %s)" % [second_open.request_id, first_request])
	_press(panel, "TankerOrderConfirm")
	_press(panel, "TankerOrderConfirm")
	var ordered: Dictionary = _sync(s)
	_check(supply.get_credits() == credits - price and _orders_count(s) == 1 and _order_state(s) == "requested", "c: 'Verbindlich bestellen' bucht einmal (280 Cr), auch bei Doppelklick: Guthaben %d, Auftraege %d" % [supply.get_credits(), _orders_count(s)])
	_check(supply.get_credits() == credits - price, "c: das Guthaben sank genau einmal")
	_check(not bool(ordered.call_visible) and not bool(ordered.offer_visible) and String(ordered.state) == "Tanker angefordert", "c/d: danach zeigt dieselbe Stelle 'Tanker angefordert': " + str(ordered))
	_check(bool(ordered.cancel_visible) and String(ordered.cancel_note) == "gibt alles zurück (%d Cr)" % price, "c/e: 'Stornieren' mit dem Zusatz, was es zurueckgibt (alles): " + str(ordered.cancel_note))
	# g) Ansichtswechsel: ein zweites Feld an anderer Stelle (wie an der Schiffskarte des Ortes) liest dieselbe Wahrheit.
	var other: Node = load("res://scripts/ui/emergency_tanker_panel.gd").new()
	s.flow.add_child(other)
	other.call("configure", Callable(s.runtime, "get_emergency_tanker_view").bind(craft_id), Callable(s.runtime, "request_operation"), 9)
	# d) Zustandszeilen laufen mit dem echten Tick bis zum Ergebnis.
	var seen_route := false
	var seen_refuel := false
	var same_view := true
	var deadline: int = Time.get_ticks_msec() + 15000
	while Time.get_ticks_msec() < deadline:
		var now: Dictionary = _sync(s)
		other.call("poll")
		var there: Dictionary = other.call("get_ui_snapshot")
		if String(now.state).begins_with("Tanker unterwegs - noch "): seen_route = true
		if String(now.state).begins_with("Betankung läuft - noch "): seen_refuel = true
		if String(now.state) != String(there.state): same_view = false
		if _order_state(s) == "" and not String(now.result).is_empty(): break
		await process_frame
	_check(seen_route, "d: die Zeile 'Tanker unterwegs - noch m:ss' lief mit dem echten Tick")
	_check(seen_refuel, "d: die Zeile 'Betankung läuft - noch s' lief mit dem echten Tick")
	_check(same_view, "g: ein zweites Feld (andere Ansicht) zeigte in jedem Takt denselben Zustand mit derselben Restzeit")
	var done: Dictionary = _sync(s)
	_check(String(done.result) == "Betankt: 30 Einheiten", "d: am Ende steht 'Betankt: 30 Einheiten' (kein Erstattungssatz bei voller Menge): " + String(done.result))
	_check(is_equal_approx(supply.get_fuel(craft_id), 35.0) and supply.get_credits() == credits - price, "d: Tank 35, Guthaben genau einmal gebucht")
	var jump: Dictionary = s.screen.request_operation("space_start_quantum", {"craft_id": craft_id, "target_orbit_id": String(Dictionary(s.runtime.get_space_travel_snapshot(craft_id).get("location_orbits", {})).get("satellite_crash", ""))})
	_check(bool(jump.get("ok", false)) and is_equal_approx(supply.get_fuel(craft_id), 25.0), "d: danach startet die Etappe (35 -> 25): " + str(jump))
	await _ui_close(s)

# --- e) Stornieren in requested und in en_route ------------------------------------------------------------------------

func _scenario_cancel_texts() -> void:
	var s: Dictionary = await _ui_orbit_session()
	var supply: Object = s.supply
	var panel: Node = _panel(s)
	_sync(s)
	_press(panel, "TankerCall")
	_press(panel, "TankerOrderConfirm")
	var requested: Dictionary = _sync(s)
	_check(supply.get_credits() == 220 and String(requested.cancel_note) == "gibt alles zurück (280 Cr)", "e: in requested gibt Stornieren alles zurueck (Text und Guthaben 220): " + str(requested.cancel_note))
	_press(panel, "TankerCancelOrder")
	var cancelled: Dictionary = _sync(s)
	_check(supply.get_credits() == 500 and _orders_count(s) == 0, "e: Storno in requested erstattet 280, Guthaben 500, kein Auftrag")
	_check(String(cancelled.result) == "Tankerruf storniert - 280 Credits erstattet", "e: der Text nennt die Erstattung: " + String(cancelled.result))
	_check(bool(cancelled.call_visible), "e: nach dem Storno ist der Knopf wieder da")
	_press(panel, "TankerCancelOrder")
	_sync(s)
	_check(supply.get_credits() == 500, "e: ein zweiter Klick auf Stornieren erstattet nicht noch einmal")
	_press(panel, "TankerCall")
	_press(panel, "TankerOrderConfirm")
	_check(supply.get_credits() == 220, "e: ein neuer Ruf nach dem Storno ist moeglich (500 -> 220)")
	_check(await _ui_wait(func() -> bool: return _order_state(s) == "en_route", 8000), "e: der Auftrag ist unterwegs (en_route)")
	var en_route: Dictionary = _sync(s)
	_check(String(en_route.cancel_note) == "gibt den Mengenpreis zurück (180 Cr), die Anfahrt (100 Cr) ist verloren", "e: in en_route nennt der Zusatz Mengenpreis zurueck, Anfahrt verloren: " + String(en_route.cancel_note))
	_check(String(en_route.state).begins_with("Tanker unterwegs - noch "), "e/d: Zustand in Worten mit Restzeit: " + String(en_route.state))
	_press(panel, "TankerCancelOrder")
	var partial: Dictionary = _sync(s)
	_check(supply.get_credits() == 400 and _orders_count(s) == 0, "e: Storno in en_route erstattet 180, Guthaben 400")
	_check(String(partial.result) == "Tankerruf storniert - 180 Credits erstattet", "e: der Text nennt 180 erstattet: " + String(partial.result))
	await _ui_close(s)

# --- f) zu wenig Geld -----------------------------------------------------------------------------------------------------

func _scenario_too_poor() -> void:
	# Abschnitt K (22.11.2026): zu wenig Credits sperrt den Knopf nicht mehr; das Angebot kommt mit der Zusatzzeile "Auf Kredit".
	var credit_session: Dictionary = await _ui_orbit_session()
	var credit_supply: Object = credit_session.supply
	credit_supply.charge_credits_capped(credit_supply.get_credits() - 100)
	var credit_panel: Node = _panel(credit_session)
	var credit_before: Dictionary = _sync(credit_session)
	_check(bool(credit_before.call_visible) and not bool(credit_before.call_disabled), "f: mit 100 Cr (Preis 280) ist der Knopf nicht grau (Kredit): " + str(credit_before))
	_press(credit_panel, "TankerCall")
	var credit_offer: Dictionary = _sync(credit_session)
	_check(bool(credit_offer.offer_visible) and String(credit_offer.offer).contains("Auf Kredit: Kontostand danach -180 Cr. Zinsen 5 % alle 10 Minuten."), "f: das Angebot zeigt die Zusatzzeile 'Auf Kredit: Kontostand danach -180 Cr. Zinsen 5 % alle 10 Minuten.': " + String(credit_offer.offer))
	_check(credit_supply.get_credits() == 100 and _orders_count(credit_session) == 0, "f: das Angebot allein bucht nichts")
	await _ui_close(credit_session)
	# Der Kreditrahmen ist ausgeschoepft: der Knopf ist grau mit dem Satz aus E3.
	var s: Dictionary = await _ui_orbit_session()
	var supply: Object = s.supply
	supply.charge_rescue_fee(supply.get_credits() + 1221)
	var revision: int = supply.get_revision()
	var panel: Node = _panel(s)
	var poor: Dictionary = _sync(s)
	_check(bool(poor.call_visible) and bool(poor.call_disabled), "f: bei ausgeschoepftem Kreditrahmen ist der Knopf sichtbar, aber ausgegraut: " + str(poor))
	_check(String(poor.reason).contains("Kreditrahmen ausgeschöpft: Der Nottankdienst liefert nicht mehr."), "f: der Satz nennt den Kreditrahmen: " + String(poor.reason))
	_press(panel, "TankerCall")
	var after: Dictionary = _sync(s)
	_check(not bool(after.offer_visible) and supply.get_credits() == -1221 and supply.get_revision() == revision and _orders_count(s) == 0, "f: ein Klick auf den grauen Knopf oeffnet nichts und bucht nichts")
	await _ui_close(s)

# --- g, h) an der Schiffskarte des Ortes: dieselbe Wahrheit, Abflug bei offenem Auftrag -----------------------------

func _scenario_surface_card_and_gate() -> void:
	_configure_entry()
	var s: Dictionary = await _begin_sortie()
	if s.is_empty(): return
	var runtime: Object = _runtime
	var supply: Object = runtime.get("_supply")
	var tanks: Dictionary = supply.get("_fuel_by_craft_id")
	_identity_before = _identity(_screen.call("get_operations_snapshot"))
	if not _place_at(s.simulation, s.access, "campaign_leader", Vector2.ZERO): return
	if not _place_at(s.simulation, s.access, "campaign_pilot", Vector2.ZERO): return
	var controller: Node = s.controller
	var craft_id: String = _craft_id
	var star_panel: Node = _flow.get("_star_map_screen").get("_tanker_panel")
	# Die Schiffskarten stehen im Detailfenster der Transportanzeige: der Spieler oeffnet es mit dem Knopf "Details".
	var details_button: Button = s.mission.get_node_or_null("TacticalUI/MissionDropshipPanel/CompactCard/Contents/Header/DetailsButton") as Button
	_check(details_button != null, "g: der Detailknopf der Transportanzeige ist da")
	if details_button != null: details_button.pressed.emit()
	for i in 6: await process_frame
	controller.call("_refresh_mission_dropship_panel")
	await process_frame
	var card_panel: Node = s.mission.find_child("EmergencyTankerPanel", true, false)
	_check(card_panel != null, "g: an der Schiffskarte des Ortes sitzt das Tankerfeld (Kartenzeilen im Einsatz: %d)" % [s.mission.find_children("MissionDropshipCardCommandRow", "", true, false).size()])
	if card_panel == null:
		await _end_sortie()
		return
	# Genug da: kein Knopf an der Karte.
	card_panel.call("poll")
	_check(not bool(card_panel.call("get_ui_snapshot").visible), "g: mit gedecktem Tank ist an der Schiffskarte kein Feld sichtbar")
	# Der Tank reicht nicht fuer den Ortsabflug.
	tanks[craft_id] = 1.0
	var credits: int = supply.get_credits()
	card_panel.call("poll")
	var shown: Dictionary = card_panel.call("get_ui_snapshot")
	_check(bool(shown.visible) and bool(shown.call_visible) and not bool(shown.call_disabled), "g: bei zu knappem Tank erscheint der Knopf an der Schiffskarte: " + str(shown))
	var card_button: Button = card_panel.find_child("TankerCall", true, false) as Button
	card_button.pressed.emit()
	(card_panel.find_child("TankerOrderConfirm", true, false) as Button).pressed.emit()
	card_panel.call("poll")
	var ordered: Dictionary = card_panel.call("get_ui_snapshot")
	_check(supply.get_credits() == credits - 280 and String(ordered.state) == "Tanker angefordert", "g: Bestellen an der Schiffskarte bucht 280 Cr, Zustand 'Tanker angefordert': " + str(ordered))
	star_panel.call("poll")
	var on_map: Dictionary = star_panel.call("get_ui_snapshot")
	_check(String(on_map.state) == String(ordered.state) and bool(on_map.cancel_visible), "g: die Sternkarte zeigt denselben Zustand wie die Schiffskarte: Karte '%s', Schiff '%s'" % [on_map.state, ordered.state])
	# h) Abflug ueber die Schiffsanzeige bei offenem Auftrag: sofort abgelehnt, nichts gestartet.
	var gate: Callable = controller.get("_campaign_departure_gate")
	_check(gate.is_valid(), "h: der Abflug der Schiffsanzeige laeuft ueber das Tor des Ablaufs")
	# Wie der echte Abflug zuerst das Einschiffen verlangt (_request_singleplayer_return): der Pilot ist an Bord, dann folgt das Tor.
	var boarding: Dictionary = Dictionary(controller.call("request_campaign_crew_boarding", craft_id))
	await _ui_wait(func() -> bool: return String(Dictionary(_flow.call("_departure_return_preflight", craft_id)).get("reason", "")) != "pilot_not_aboard", 15000)
	_check(String(Dictionary(_flow.call("_departure_return_preflight", craft_id)).get("reason", "")) != "pilot_not_aboard", "h: der Pilot ist an Bord (Einschiffen: %s)" % [boarding])
	var fuel_before: float = supply.get_fuel(craft_id)
	var blocked: Dictionary = Dictionary(gate.call(craft_id))
	_check(bool(blocked.get("handled", false)) and not bool(blocked.get("ok", true)) and String(blocked.get("reason", "")) == "tanker_order_open", "h: Abflug bei offenem Auftrag wird frueh abgelehnt (tanker_order_open): " + str(blocked) + " Vorpruefung: " + str(_flow.call("_departure_return_preflight", craft_id)))
	_check(String(blocked.get("message", "")) == TANKER_OPEN_TEXT, "h: der Satz lautet 'Ein Tanker ist unterwegs - erst abwarten oder stornieren.': " + String(blocked.get("message", "")))
	_check(_flow.get("_active_mission") == s.mission and is_equal_approx(supply.get_fuel(craft_id), fuel_before) and supply.get_credits() == credits - 280, "h: nichts gestartet, nichts abgebucht, das Schiff bleibt am Ort")
	# h) Ein feststehendes Einsatzergebnis ist trotzdem gebucht.
	_flow.call("_remember_location", s.mission)
	var chip: Dictionary = _runtime.call("_campaign_cargo", craft_id, "satellite_chip", 1, "chip:satellite_recovery")
	_check(bool(chip.get("ok", false)), "h: Chip ist an Bord")
	var job_before: Dictionary = Dictionary(_campaign().jobs.satellite_recovery)
	_check(String(job_before.get("status", "")) == "active", "h: Auftrag ist aktiv")
	_resolve_with_gates(s.driver, Array(job_before.get("required_step_ids", [])))
	for i in 30: await process_frame
	var job_after: Dictionary = Dictionary(_campaign().jobs.satellite_recovery)
	var error: Variant = _screen.get_meta("singleplayer_departure_error", {})
	_check(String(job_after.get("status", "")) in ["pending_upload", "completed"] and int(job_after.get("retreat_count", 0)) == 0, "h: das Ergebnis ist sofort gebucht (Auftrag %s), obwohl ein Tanker offen ist" % job_after.get("status"))
	_check(error is Dictionary and String(Dictionary(error).get("reason", "")) == "tanker_order_open", "h: gesperrt ist nur der Abflug, Grund tanker_order_open: " + str(error))
	_check(_flow.get("_active_mission") == s.mission, "h: der Einsatz bleibt stehen, das Schiff wird nicht freigegeben")
	# Stornieren an der Schiffskarte gibt frei (requested: alles zurueck).
	(card_panel.find_child("TankerCancelOrder", true, false) as Button).pressed.emit()
	card_panel.call("poll")
	_check(supply.get_credits() == credits and not bool(card_panel.call("get_ui_snapshot").cancel_visible), "g/e: Stornieren an der Schiffskarte erstattet alles (Guthaben %d == %d)" % [supply.get_credits(), credits])
	var open_again: Dictionary = Dictionary(gate.call(craft_id))
	_check(String(open_again.get("reason", "")) != "tanker_order_open", "h: nach dem Storno gilt das Tor wieder ohne tanker_order_open: " + str(open_again.get("reason", "")))
	await _end_sortie()

## Wie tanker_result_fuel_verifier.gd: Sieg ueber den Fahrer ausloesen, Auftragsschritte ins Ergebnis legen, an die echten Empfaenger zustellen.
func _resolve_with_gates(driver: Node, step_ids: Array) -> void:
	var receivers: Array = driver.combat_resolved.get_connections()
	for connection: Dictionary in receivers:
		driver.combat_resolved.disconnect(connection.callable)
	var captured: Array = []
	var capture: Callable = func(result: Dictionary) -> void: captured.append(result)
	driver.combat_resolved.connect(capture)
	driver.call("_resolve_combat", "victory", String(driver.get("friendly_team_id")))
	driver.combat_resolved.disconnect(capture)
	for connection: Dictionary in receivers:
		driver.combat_resolved.connect(connection.callable)
	if captured.is_empty():
		_check(false, "h: der Fahrer hat kein Ergebnis gemeldet")
		return
	var delivered: Dictionary = Dictionary(captured[0]).duplicate(true)
	delivered["mission_scenario_runtime_gates"] = {"all_gates_complete": true, "completed_step_ids": step_ids}
	for connection: Dictionary in receivers:
		(connection.callable as Callable).call(delivered)
