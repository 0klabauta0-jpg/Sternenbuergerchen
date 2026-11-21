extends "res://scripts/tests/campaign_intro_loop_smoke.gd"
## Nutzt die Basisklasse der echten Kampagnen-Schleife (echte Basis, Pilot und Crew an Bord); _run ist ersetzt.
## T2 des Tanker-Auftrags (21.11.2026): Nottankdienst im echten Spielablauf. Echte Szene, echter Adapter, echter Versorgungsbesitzer,
## echter Dienstbesitzer, echter Tick (_physics_process -> advance_space_travel). Die Zeiten des Dienstes werden in den Daten verkuerzt
## (der Dienst liest sie aus emergency_fuel; 5/60/10 s waeren hier zu lang), alle anderen Zahlen sind die der Daten (100 / 6 / 30).
## Die Regeln im Einzelnen stehen in tanker_emergency_rules_verifier.gd.
## Bestellen und Stornieren laufen ueber runtime.request_operation (Befehlsweg); HomebaseScreen.request_operation leitet sie
## noch nicht weiter (T3, offener Punkt im Bericht).

const FLOW_SCENE: String = "res://scenes/meta/meta_layer_test.tscn"
const DATA_PATH: String = "res://data/singleplayer/trade_offers.json"
const FAST_TIMES: Dictionary = {"dispatch_seconds": 0.2, "response_seconds": 0.5, "refuel_seconds": 0.3}

func _data() -> Dictionary:
	return Dictionary(JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)))

func _run() -> void:
	await _scenario_call_and_deliver()
	await _scenario_rejections()
	await _scenario_cancel()
	await _scenario_expire()
	await _scenario_save_and_load()
	print("TANKER_EMERGENCY_FLOW passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)

# --- Flow-Sitzung (wie tanker_leg_fuel_verifier.gd, dazu kurze Dienstzeiten) -------------------------------

func _session(initial_fuel: float) -> Dictionary:
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
	var crafts: Array = flow.get("_homebase_aircraft_definitions")
	var data: Dictionary = _data()
	# Die Definitionen bleiben die der Datei bis auf die Dienstzeiten (der Block emergency_fuel wird beim Laden nicht verglichen);
	# sonst wuerde restore_state den eigenen Stand als veraltet ablehnen. Nur der Tank wird gesetzt.
	data.emergency_fuel.merge(FAST_TIMES, true)
	supply.configure(crafts, data)
	var tanks: Dictionary = supply.get("_fuel_by_craft_id")
	for tank_id: String in tanks.keys(): tanks[tank_id] = initial_fuel
	screen.request_operation("accept_job", {"job_id": "satellite_recovery"})
	screen.request_operation("select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery"})
	return {"flow": flow, "runtime": runtime, "supply": supply, "screen": screen, "craft_id": _craft_id}

func _close(session: Dictionary) -> void:
	var flow: Node = session.flow
	flow.queue_free()
	await process_frame
	await process_frame

func _phase(session: Dictionary) -> String:
	return String(session.runtime.get_space_travel_snapshot(session.craft_id).get("phase", ""))

func _wait_for(session: Dictionary, predicate: Callable, timeout_msec: int) -> bool:
	var deadline: int = Time.get_ticks_msec() + timeout_msec
	while not predicate.call() and Time.get_ticks_msec() < deadline:
		await process_frame
	return predicate.call()

func _launch(session: Dictionary) -> Dictionary:
	if session.screen.has_meta("singleplayer_departure_error"):
		session.screen.remove_meta("singleplayer_departure_error")
	session.screen.request_operation("start", {"craft_id": session.craft_id})
	var error: Dictionary = Dictionary(session.screen.get_meta("singleplayer_departure_error", {}))
	return error if _phase(session) == "grounded" else {"ok": true}

func _site_orbit(session: Dictionary) -> String:
	return String(Dictionary(session.runtime.get_space_travel_snapshot(session.craft_id).get("location_orbits", {})).get("satellite_crash", ""))

func _jump(session: Dictionary) -> Dictionary:
	return session.screen.request_operation("space_start_quantum", {"craft_id": session.craft_id, "target_orbit_id": _site_orbit(session)})

func _order_request(session: Dictionary, request_id: String) -> Dictionary:
	return session.runtime.request_operation("emergency_tanker_order", {"craft_id": session.craft_id, "request_id": request_id})

func _cancel_request(session: Dictionary) -> Dictionary:
	return session.runtime.request_operation("emergency_tanker_cancel", {"craft_id": session.craft_id})

func _order_state(session: Dictionary) -> String:
	return String(Dictionary(Dictionary(session.runtime.get_emergency_tanker_snapshot().get("orders", {})).get(session.craft_id, {})).get("state", ""))

func _finished_state(session: Dictionary) -> String:
	return String(Dictionary(Dictionary(session.runtime.get_emergency_tanker_snapshot().get("finished", {})).get(session.craft_id, {})).get("state", ""))

func _wait_order_state(session: Dictionary, states: Array) -> bool:
	return await _wait_for(session, func() -> bool: return _order_state(session) in states, 8000)

func _wait_finished(session: Dictionary, state: String) -> bool:
	return await _wait_for(session, func() -> bool: return _finished_state(session) == state, 15000)

func _frames(count: int) -> void:
	for index in range(count): await process_frame

## Sitzung mit knappem Tank im Mondorbit: der Sprung zum Ziel (10) ist nicht gedeckt.
func _orbit_session(initial_fuel: float = 6.0) -> Dictionary:
	var s: Dictionary = await _session(initial_fuel)
	var launch: Dictionary = _launch(s)
	_check(launch.get("ok", false) and _phase(s) == "orbit", "Sitzung: Abheben angenommen, Schiff im Mondorbit: " + str(launch))
	return s

# --- 1. Rufen und Liefern --------------------------------------------------------------------------------------

func _scenario_call_and_deliver() -> void:
	var s: Dictionary = await _orbit_session()
	var supply: Object = s.supply
	var craft_id: String = s.craft_id
	_check(is_equal_approx(supply.get_fuel(craft_id), 5.0), "1: nach dem Abheben 5 Treibstoff (6 - 1)")
	var blocked: Dictionary = _jump(s)
	_check(not blocked.get("ok", true) and String(blocked.get("reason", "")) == "leg_fuel_insufficient", "1: der Sprung wird mit leg_fuel_insufficient abgelehnt: " + str(blocked))
	var status: Dictionary = s.runtime.get_fuel_status(craft_id)
	_check(bool(status.get("fuel_problem", false)) and not bool(status.get("refuel_here", true)), "1: get_fuel_status meldet das Treibstoffproblem, ohne Tankservice im Orbit: " + str(status))
	var credits: int = supply.get_credits()
	var revision: int = supply.get_revision()
	var offer: Dictionary = s.runtime.preview_emergency_tanker(craft_id)
	_check(bool(offer.get("ok", false)) and int(offer.get("quantity", 0)) == 30 and int(offer.get("price", 0)) == 280, "1: das Angebot: 30 Einheiten fuer 280 Cr (Zahlen aus den Daten): " + str(offer))
	_check(supply.get_credits() == credits and supply.get_revision() == revision and _order_state(s) == "", "1: das Angebot bucht nichts und legt keinen Auftrag an")
	var ordered: Dictionary = _order_request(s, "flow:order:1")
	_check(bool(ordered.get("ok", false)) and not bool(ordered.get("replayed", false)) and String(ordered.get("order_id", "")) == "flow:order:1", "1: der Ruf ueber request_operation ist angenommen: " + str(ordered))
	_check(supply.get_credits() == credits - 280 and is_equal_approx(supply.get_fuel(craft_id), 5.0), "1: gebucht sind genau 280 Cr, der Tank ist noch unveraendert")
	_check(_order_state(s) == "requested", "1: der Auftrag steht im Zustand requested, ist " + _order_state(s))
	var replay: Dictionary = _order_request(s, "flow:order:1")
	_check(bool(replay.get("replayed", false)) and supply.get_credits() == credits - 280 and s.runtime.get_emergency_tanker_snapshot().orders.size() == 1, "1: derselbe Ruf noch einmal -> replayed: true, nichts doppelt gebucht, ein Auftrag")
	var second: Dictionary = _order_request(s, "flow:order:2")
	_check(not second.get("ok", true) and String(second.get("reason", "")) == "tanker_order_open" and supply.get_credits() == credits - 280, "1: ein zweiter Ruf fuer dasselbe Schiff -> tanker_order_open, nichts gebucht: " + str(second.get("reason", "")))
	var held: Dictionary = _jump(s)
	_check(not held.get("ok", true) and String(held.get("reason", "")) == "tanker_order_open", "1: mit offenem Auftrag startet das Schiff keine Etappe (tanker_order_open statt leg_fuel_insufficient): " + str(held))
	_check(_phase(s) == "orbit" and is_equal_approx(supply.get_fuel(craft_id), 5.0) and supply.get_credits() == credits - 280, "1: die abgelehnte Etappe bucht nichts, das Schiff bleibt im Orbit")
	var booked_revision: int = supply.get_revision()
	_check(await _wait_order_state(s, ["en_route", "at_ship", "refuelling"]), "1: der echte Tick bringt den Auftrag nach en_route, Zustand " + _order_state(s))
	_check(supply.get_revision() == booked_revision and is_equal_approx(supply.get_fuel(craft_id), 5.0), "1: der Zeitablauf allein aendert die Revision des Versorgungsstands und den Tank nicht")
	_check(await _wait_finished(s, "completed"), "1: der Auftrag wird abgeschlossen (completed), Zustand " + _finished_state(s) + " / " + _order_state(s))
	_check(is_equal_approx(supply.get_fuel(craft_id), 35.0), "1: Tank +30 (5 -> 35), ist %s" % supply.get_fuel(craft_id))
	_check(supply.get_credits() == credits - 280, "1: Guthaben -280 (genau einmal), ist %d" % supply.get_credits())
	_check(supply.get_revision() == booked_revision + 1, "1: erst die Lieferung hebt die Revision (genau um 1)")
	await _frames(40)
	_check(is_equal_approx(supply.get_fuel(craft_id), 35.0) and supply.get_credits() == credits - 280 and _order_state(s) == "", "1: weitere Ticks liefern nicht noch einmal")
	var after: Dictionary = s.runtime.get_fuel_status(craft_id)
	_check(not bool(after.get("fuel_problem", true)), "1: nach der Lieferung ist das Treibstoffproblem behoben")
	var jump: Dictionary = _jump(s)
	_check(jump.get("ok", false) and is_equal_approx(supply.get_fuel(craft_id), 25.0), "1: der Sprung startet und bucht 10 (35 -> 25): " + str(jump))
	await _close(s)

# --- 2. Ablehnungen im echten Spiel -----------------------------------------------------------------------------

func _scenario_rejections() -> void:
	var home: Dictionary = await _session(6.0)
	var at_home: Dictionary = home.runtime.preview_emergency_tanker(home.craft_id)
	_check(not at_home.get("ok", true) and String(at_home.get("reason", "")) == "at_service_point" and String(at_home.get("message", "")) == "Hier kann normal getankt werden.", "2: an der Heimatbasis wird nicht gerufen (at_service_point): " + str(at_home))
	var unknown: Dictionary = home.runtime.preview_emergency_tanker("kein_schiff")
	_check(not unknown.get("ok", true) and String(unknown.get("reason", "")) == "craft_unavailable" and String(unknown.get("message", "")) == "Schiff nicht erreichbar.", "2: ein unbekanntes Schiff -> craft_unavailable: " + str(unknown))
	var home_order: Dictionary = _order_request(home, "flow:rej:home")
	_check(not home_order.get("ok", true) and String(home_order.get("reason", "")) == "at_service_point", "2: der Ruf an der Basis wird abgelehnt: " + str(home_order.get("reason", "")))
	_check(home.supply.get_credits() == 500 and home.runtime.get_emergency_tanker_snapshot().orders.is_empty(), "2: der abgelehnte Ruf an der Basis bucht nichts")
	await _close(home)
	var covered: Dictionary = await _orbit_session(50.0)
	var covered_preview: Dictionary = covered.runtime.preview_emergency_tanker(covered.craft_id)
	_check(not covered_preview.get("ok", true) and String(covered_preview.get("reason", "")) == "no_fuel_problem" and String(covered_preview.get("message", "")) == "Der Treibstoff reicht für die nächste Etappe.", "2: mit gedeckter Etappe wird nicht gerufen (no_fuel_problem): " + str(covered_preview))
	var covered_order: Dictionary = _order_request(covered, "flow:rej:covered")
	_check(not covered_order.get("ok", true) and String(covered_order.get("reason", "")) == "no_fuel_problem" and covered.supply.get_credits() == 500 and is_equal_approx(covered.supply.get_fuel(covered.craft_id), 49.0), "2: der Ruf mit gedeckter Etappe bucht nichts, Tank und Guthaben unveraendert")
	await _close(covered)
	var poor: Dictionary = await _orbit_session()
	poor.supply.charge_credits_capped(poor.supply.get_credits() - 100)
	var revision: int = poor.supply.get_revision()
	var poor_order: Dictionary = _order_request(poor, "flow:rej:poor")
	_check(not poor_order.get("ok", true) and String(poor_order.get("reason", "")) == "insufficient_credits" and int(poor_order.get("price", -1)) == 280 and int(poor_order.get("credits", -1)) == 100, "2: zu wenig Credits (100 von 280) -> insufficient_credits mit price und credits: " + str(poor_order))
	_check(poor.supply.get_credits() == 100 and is_equal_approx(poor.supply.get_fuel(poor.craft_id), 5.0) and poor.supply.get_revision() == revision and poor.runtime.get_emergency_tanker_snapshot().orders.is_empty(), "2: nichts gebucht, keine Teilmenge, keine Schulden, kein Auftrag")
	await _frames(30)
	_check(is_equal_approx(poor.supply.get_fuel(poor.craft_id), 5.0) and poor.supply.get_credits() == 100, "2: auch spaeter kommt kein kostenloser Tanker")
	await _close(poor)

# --- 3. Stornieren ------------------------------------------------------------------------------------------------

func _scenario_cancel() -> void:
	var s: Dictionary = await _orbit_session()
	var supply: Object = s.supply
	var craft_id: String = s.craft_id
	_check(_order_request(s, "flow:cancel:1").get("ok", false) and _order_state(s) == "requested", "3: Ruf angenommen (requested)")
	var refunded: Dictionary = _cancel_request(s)
	_check(bool(refunded.get("ok", false)) and int(refunded.get("refund", -1)) == 280 and supply.get_credits() == 500, "3: Storno in requested erstattet alles (280): " + str(refunded))
	_check(_order_state(s) == "" and _finished_state(s) == "cancelled", "3: der Auftrag steht danach als cancelled")
	var again: Dictionary = _cancel_request(s)
	_check(bool(again.get("replayed", false)) and supply.get_credits() == 500, "3: ein zweiter Storno-Klick erstattet nicht noch einmal (replayed)")
	await _frames(40)
	_check(is_equal_approx(supply.get_fuel(craft_id), 5.0) and supply.get_credits() == 500, "3: nach dem Storno liefert der Tick nichts")
	var after: Dictionary = _jump(s)
	_check(not after.get("ok", true) and String(after.get("reason", "")) == "leg_fuel_insufficient", "3: nach dem Storno gilt wieder leg_fuel_insufficient statt tanker_order_open: " + str(after.get("reason", "")))
	_check(_order_request(s, "flow:cancel:2").get("ok", false) and supply.get_credits() == 220, "3: ein neuer Ruf nach dem Storno ist moeglich (500 -> 220)")
	_check(await _wait_order_state(s, ["en_route"]), "3: der Auftrag ist unterwegs (en_route)")
	var partial: Dictionary = _cancel_request(s)
	_check(bool(partial.get("ok", false)) and int(partial.get("refund", -1)) == 180 and int(partial.get("kept", -1)) == 100 and supply.get_credits() == 400, "3: Storno in en_route erstattet nur den Mengenpreis (180), die Anfahrt (100) ist verloren: " + str(partial))
	_check(_order_request(s, "flow:cancel:3").get("ok", false) and supply.get_credits() == 120, "3: dritter Ruf (400 -> 120)")
	_check(await _wait_order_state(s, ["at_ship", "refuelling"]), "3: der Tanker ist am Schiff, Zustand " + _order_state(s))
	var credits: int = supply.get_credits()
	var late: Dictionary = _cancel_request(s)
	_check(not late.get("ok", true) and String(late.get("reason", "")) == "tanker_already_arrived" and String(late.get("message", "")) == "Der Tanker ist schon am Schiff." and supply.get_credits() == credits, "3: ab at_ship gibt es keinen Storno (tanker_already_arrived), nichts erstattet: " + str(late))
	_check(await _wait_finished(s, "completed") and is_equal_approx(supply.get_fuel(craft_id), 35.0) and supply.get_credits() == credits, "3: der Auftrag wird trotzdem geliefert (Tank 35), Guthaben unveraendert")
	await _close(s)

# --- 4. Zerstoert oder entfernt: expired mit voller Erstattung ---------------------------------------------------

func _scenario_expire() -> void:
	var s: Dictionary = await _orbit_session()
	var supply: Object = s.supply
	var craft_id: String = s.craft_id
	_check(_order_request(s, "flow:expire:1").get("ok", false) and supply.get_credits() == 220, "4: Ruf angenommen (500 -> 220)")
	_check(await _wait_order_state(s, ["en_route"]), "4: der Auftrag ist unterwegs")
	# Wie die echte Rueckgabe eines Schiffs (singleplayer_runtime_adapter.gd, Punkteaktion): aus Flotte, Treibstoffkonto und Reisebesitzer entfernen.
	s.flow.call("remove_skirmish_craft", craft_id)
	supply.remove_skirmish_craft(craft_id)
	s.runtime.get("_travel").unregister_craft(craft_id)
	_check(await _wait_finished(s, "expired"), "4: der Auftrag verfaellt (expired), Zustand " + _finished_state(s) + " / " + _order_state(s))
	_check(supply.get_credits() == 500, "4: volle Erstattung (280), Guthaben 500, ist %d" % supply.get_credits())
	_check(supply.get_open_tanker_orders().is_empty() and s.runtime.get_emergency_tanker_snapshot().orders.is_empty(), "4: kein Auftrag bleibt offen")
	await _frames(40)
	_check(supply.get_credits() == 500, "4: weitere Ticks erstatten nicht noch einmal")
	var gone: Dictionary = s.runtime.preview_emergency_tanker(craft_id)
	_check(not gone.get("ok", true) and String(gone.get("reason", "")) == "craft_unavailable", "4: fuer das entfernte Schiff gibt es kein Angebot mehr (craft_unavailable)")
	await _close(s)

# --- 5. Speichern und Laden ----------------------------------------------------------------------------------------

func _json(value: Dictionary) -> Dictionary:
	return Dictionary(JSON.parse_string(JSON.stringify(value)))

func _scenario_save_and_load() -> void:
	var s: Dictionary = await _session(6.0)
	var runtime: Object = s.runtime
	var supply: Object = s.supply
	var craft_id: String = s.craft_id
	# Ohne Auftrag: der echte Heimspeicherpunkt traegt den Schluessel nicht (alter Stand == kein Auftrag) und laedt weiter.
	var home_state: Dictionary = runtime.export_campaign_checkpoint()
	_check(not home_state.is_empty() and not home_state.has("emergency_tanker"), "5: der Heim-Speicherstand ohne Auftrag hat keinen Schluessel emergency_tanker")
	_check(bool(runtime.restore_emergency_tanker(home_state).get("ok", false)) and runtime.get_emergency_tanker_snapshot().orders.is_empty(), "5: ein Stand ohne den Schluessel laedt als 'kein Auftrag'")
	_check(bool(runtime.get_world_checkpoint_guard().get("ok", false)) or String(runtime.get_world_checkpoint_guard().get("reason", "")) != "emergency_tanker_open", "5: ohne Auftrag sperrt der Tanker das Speichern nicht")
	var launch: Dictionary = _launch(s)
	_check(launch.get("ok", false) and _phase(s) == "orbit", "5: Abheben angenommen")
	_check(_order_request(s, "flow:save:1").get("ok", false) and supply.get_credits() == 220, "5: Ruf angenommen")
	# Ein Dienststand ohne Beleg-Gegenstueck und ein Beleg ohne Dienststand werden abgelehnt, nie stillschweigend repariert.
	var no_key: Dictionary = runtime.restore_emergency_tanker({})
	_check(not no_key.get("ok", true) and String(no_key.get("reason", "")) == "tanker_receipt_without_order" and _order_state(s) == "requested", "5: offener Beleg, aber kein Dienstzustand im Stand -> abgelehnt, der Auftrag bleibt unveraendert: " + str(no_key))
	var guard: Dictionary = runtime.get_world_checkpoint_guard()
	_check(not guard.get("ok", true), "5: mit offenem Auftrag und Schiff unterwegs gibt es keinen Speicherpunkt (Wache sperrt): " + str(guard))
	_check(await _wait_order_state(s, ["en_route"]), "5: der Auftrag ist unterwegs (en_route)")
	var service_image: Dictionary = _json(runtime.get("_tanker").export_state())
	var supply_image: Dictionary = _json(supply.export_state())
	var saved_order: Dictionary = Dictionary(Array(service_image.get("orders", []))[0]) if Array(service_image.get("orders", [])).size() == 1 else {}
	_check(String(saved_order.get("state", "")) == "en_route" and String(saved_order.get("order_id", "")) == "flow:save:1" and String(saved_order.get("craft_id", "")) == craft_id, "5: das Dienstabbild haelt den offenen Auftrag im Zustand en_route: " + str(saved_order))
	_check(supply_image.requests.has("flow:save:1"), "5: der Versorgungsstand haelt den Bestellbeleg")
	# Laden in die echten Besitzer: Versorgungsstand zuerst, dann der Dienst (so macht es configure im Adapter).
	var loaded: Dictionary = supply.restore_state(supply_image)
	_check(loaded.get("ok", false), "5: der Versorgungsstand mit offenem Beleg laedt: " + str(loaded))
	var restored: Dictionary = runtime.restore_emergency_tanker({"emergency_tanker": service_image})
	_check(restored.get("ok", false), "5: der Dienststand passt zu den Belegen und laedt: " + str(restored))
	_check(_order_state(s) in ["en_route", "at_ship", "refuelling"] and supply.get_open_tanker_orders().has("flow:save:1"), "5: nach dem Laden ist der Auftrag wieder offen, Zustand " + _order_state(s))
	_check(await _wait_finished(s, "completed"), "5: der geladene Auftrag wird abgeschlossen")
	_check(is_equal_approx(supply.get_fuel(craft_id), 35.0) and supply.get_credits() == 220, "5: nach dem Laden wird genau einmal geliefert (Tank 35, Guthaben 220)")
	# Der Dienststand eines Auftrags, dessen Beleg schon geliefert ist, passt nicht mehr: abgelehnt.
	var stale: Dictionary = runtime.restore_emergency_tanker({"emergency_tanker": service_image})
	_check(not stale.get("ok", true) and String(stale.get("reason", "")) == "tanker_order_without_receipt" and runtime.get_emergency_tanker_snapshot().orders.is_empty(), "5: Dienstauftrag ohne offenen Beleg -> abgelehnt, nichts wird wieder eroeffnet: " + str(stale))
	var after: Dictionary = _json(supply.export_state())
	_check(Dictionary(after.requests).has("flow:save:1:deliver") and not Dictionary(after.requests).has("flow:save:1:cancel"), "5: genau ein Lieferbeleg zum Auftrag im gespeicherten Versorgungsstand")
	await _close(s)
