extends "res://scripts/tests/campaign_intro_loop_smoke.gd"
## Handel 2a-2, Nachbesserung 3: Kurzweg Muellers Farm -> Handelsposten (beide im Orbit glut_1b_orbit) ueber den ECHTEN Buchungsweg.
## Echte Szene, echter Adapter, echter Versorgungsbesitzer: Abheben, Sprung, Anflug zur Farm (bucht), Ortsabflug (authorize_return bucht
## surface_exit, enter_space_orbit), dann Anflug zum Handelsposten OHNE Sprung. Belegt: die Reichweitenanzeige vorher (needed_total) ist 3,
## abgebucht werden zwischen Farm und Handelsposten genau 3 (Ortsabflug 2 + Anflug 1), und das Schiff war dazwischen nie im Sprung (quantum).

const FLOW_SCENE: String = "res://scenes/meta/meta_layer_test.tscn"
const DATA_PATH: String = "res://data/singleplayer/trade_offers.json"
const FARM: String = "muellers_farm"
const TRADE: String = "trade_outpost"

func _run() -> void:
	await _scenario_short_leg()
	print("SMALL_OUTPOSTS_SHORT_LEG passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)

func _phase(runtime: Object, craft_id: String) -> String:
	return String(runtime.get_space_travel_snapshot(craft_id).get("phase", ""))

func _wait_for(predicate: Callable, timeout_msec: int) -> bool:
	var deadline: int = Time.get_ticks_msec() + timeout_msec
	while not predicate.call() and Time.get_ticks_msec() < deadline:
		await process_frame
	return predicate.call()

func _scenario_short_leg() -> void:
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
	var craft_id: String = _craft_id
	var data: Dictionary = Dictionary(JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)))
	data["initial_fuel"] = 40.0
	supply.configure(crafts, data)
	# Testvorbereitung wie small_outposts_visit_flight_verifier: die Freischaltung ist nicht der Gegenstand (outpost_recovery abgeschlossen).
	var live: RefCounted = runtime.get("_campaign")
	Dictionary(live.get("_jobs"))["outpost_recovery"].status = "completed"
	_check(bool(live.validate_location_visit(FARM).get("ok", false)), "Vorbereitung: Muellers Farm ist anfliegbar")
	screen.request_operation("accept_job", {"job_id": "satellite_recovery"})
	screen.request_operation("select_destination", {"location_id": FARM, "job_id": ""})
	screen.request_operation("start", {"craft_id": craft_id})
	_check(_phase(runtime, craft_id) == "orbit", "Abheben: Schiff im Mondorbit (%s)" % _phase(runtime, craft_id))
	var orbit: String = String(Dictionary(runtime.get_space_travel_snapshot(craft_id).get("location_orbits", {})).get(FARM, ""))
	_check(orbit == String(Dictionary(runtime.get_space_travel_snapshot(craft_id).get("location_orbits", {})).get(TRADE, "?")) and not orbit.is_empty(), "Farm und Handelsposten teilen den Orbit %s" % orbit)
	var jump: Dictionary = screen.request_operation("space_start_quantum", {"craft_id": craft_id, "target_orbit_id": orbit})
	_check(bool(jump.get("ok", false)), "Sprung zum Orbit der Farm angenommen: " + str(jump))
	var arrived: bool = await _wait_for(func() -> bool: return _phase(runtime, craft_id) == "orbit" and String(runtime.get_space_travel_snapshot(craft_id).get("orbit_id", "")) == orbit, 25000)
	_check(arrived, "Sprung: Schiff im Orbit %s" % orbit)
	var approach: Dictionary = screen.request_operation("space_begin_approach", {"craft_id": craft_id, "location_id": FARM})
	_check(bool(approach.get("ok", false)), "Anflug zur Farm angenommen: " + str(approach))
	var on_farm: bool = await _wait_for(func() -> bool: return _phase(runtime, craft_id) == "surface", 90000)
	_check(on_farm and String(runtime.get_space_travel_snapshot(craft_id).get("location_id", "")) == FARM, "Das Schiff steht auf der Farm (%s)" % _phase(runtime, craft_id))
	var fuel_on_farm: float = supply.get_fuel(craft_id)
	# Anzeige vorher: die Reichweite Farm -> Handelsposten (dieselbe Funktion, die get_fuel_status/Reichweite nutzt).
	var check: Dictionary = runtime.call("_outbound_fuel_check", craft_id, TRADE, runtime.get_space_travel_snapshot(craft_id))
	_check(is_equal_approx(float(check.get("needed_total", -1.0)), 3.0) and bool(check.get("ok", false)), "Anzeige: Farm -> Handelsposten verlangt 3 und ist gedeckt: " + str(check))
	# Buchung: Ortsabflug (surface_exit) ueber den Weg der Schiffskarte, danach Anflug zum Handelsposten.
	# Die zwei Aufrufe, die der Knopf "Abheben" der Schiffskarte in meta_layer_flow._begin_mission_craft_transfer(to_homebase) absetzt:
	# authorize_return (bucht surface_exit) und enter_space_orbit. Ohne geladene Mission fehlt dem Flow der Rest (Szenenabbau); die offene
	# Landungsmeldung des Schiffs raeumt der Flow dort ebenfalls ab, hier von Hand (sonst sperrt sie den Zielwechsel).
	var gate: Dictionary = runtime.call("authorize_return", craft_id)
	_check(bool(gate.get("ok", false)) and String(gate.get("leg", "")) == "surface_exit", "Ortsabflug: authorize_return bucht surface_exit: " + str(gate))
	_check(is_equal_approx(supply.get_fuel(craft_id), fuel_on_farm - 2.0), "Ortsabflug bucht 2 (%s -> %s)" % [str(fuel_on_farm), str(supply.get_fuel(craft_id))])
	var exited: Dictionary = runtime.call("enter_space_orbit", craft_id)
	_check(bool(exited.get("ok", false)) and _phase(runtime, craft_id) == "orbit" and String(runtime.get_space_travel_snapshot(craft_id).get("orbit_id", "")) == orbit, "Nach dem Ortsabflug: Orbit %s, kein Sprung noetig (%s)" % [orbit, str(exited)])
	var pending: Array = Array(flow.get("_pending_mission_craft_transfers")).filter(func(entry: Dictionary) -> bool: return String(entry.get("craft_id", "")) != craft_id)
	flow.set("_pending_mission_craft_transfers", pending)
	var chosen: Dictionary = screen.request_operation("select_destination", {"location_id": TRADE, "job_id": ""})
	_check(bool(chosen.get("ok", false)), "Der Handelsposten laesst sich im Orbit als neues Ziel waehlen: " + str(chosen))
	var second: Dictionary = screen.request_operation("space_begin_approach", {"craft_id": craft_id, "location_id": TRADE})
	_check(bool(second.get("ok", false)), "Anflug zum Handelsposten ohne Sprung angenommen: " + str(second))
	_check(is_equal_approx(fuel_on_farm - supply.get_fuel(craft_id), 3.0), "Gebucht ist Farm -> Handelsposten insgesamt genau 3 (%s -> %s)" % [str(fuel_on_farm), str(supply.get_fuel(craft_id))])
	var on_trade: bool = await _wait_for(func() -> bool: return _phase(runtime, craft_id) == "surface", 90000)
	_check(on_trade and String(runtime.get_space_travel_snapshot(craft_id).get("location_id", "")) == TRADE, "Das Schiff steht am Handelsposten (%s)" % _phase(runtime, craft_id))
	_check(is_equal_approx(fuel_on_farm - supply.get_fuel(craft_id), 3.0), "Nach der Landung ist weiter nur 3 gebucht, kein Sprung (%s)" % str(supply.get_fuel(craft_id)))
	flow.queue_free()
	await process_frame
	await process_frame
