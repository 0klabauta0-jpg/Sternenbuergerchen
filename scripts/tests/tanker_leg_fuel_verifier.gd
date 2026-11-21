extends "res://scripts/tests/campaign_intro_loop_smoke.gd"
## Nutzt die Basisklasse der echten Kampagnen-Schleife (echte Basis, Pilot und Crew an Bord); _run ist ersetzt.
## T1 des Tanker-Auftrags (21.11.2026): Treibstoff Etappe fuer Etappe statt pauschaler Hin-und-Rueckflug-Reserve.
## Regel 8 in docs/dev/campaign_casualty_retreat_contract.md. Jede Etappe (Abheben, Sprung, Anflug, Ortsabflug,
## Landung) bucht ihren Anteil genau einmal beim Versorgungsbesitzer, wenn sie beginnt; "liegen geblieben"
## ist ein abgeleiteter Zustand (get_fuel_status), kein gespeicherter.

const SUPPLY_SCRIPT: GDScript = preload("res://scripts/core/singleplayer_supply_state.gd")
const FLOW_SCENE: String = "res://scenes/meta/meta_layer_test.tscn"
const DATA_PATH: String = "res://data/singleplayer/trade_offers.json"
const OLD_FIXTURES: Array = [
	"res://scripts/tests/fixtures/main_639a49d65_checkpoint.json",
	"res://docs/qa/review_completion_20261113/post_benit_source/checkpoint_v1.json",
	"res://docs/qa/review_completion_20261113/legacy_source_pair/checkpoint_v1.json",
]

func _data() -> Dictionary:
	return Dictionary(JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)))

func _leg_command(craft_id: String, leg: String, origin: String, destination: String, request_id: String) -> Dictionary:
	return {"contract_category": "singleplayer_supply", "operation": "consume_leg_fuel", "payload": {"craft_id": craft_id, "leg": leg, "origin_location_id": origin, "destination_location_id": destination}, "request_id": request_id}

func _run() -> void:
	if "only=jump_restart" in OS.get_cmdline_user_args():
		await _scenario_jump_restart()
		print("TANKER_LEG_FUEL passed=%d failed=%d" % [_passed, _failed])
		quit(0 if _failed == 0 else 1)
		return
	_scenario_table_and_owner()
	_scenario_save_and_load()
	await _scenario_full_tank_flight()
	await _scenario_jump_restart()
	await _scenario_launch_without_fuel()
	await _scenario_jump_without_fuel()
	await _scenario_stranded_in_orbit()
	await _scenario_outbound_only_approach()
	await _scenario_return_preflight_covered()
	print("TANKER_LEG_FUEL passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)

# --- Flow-Sitzung (echte Szene, echter Adapter, echter Versorgungsbesitzer) ----------------------------

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
	var craft_id: String = _craft_id
	_check(String(crafts[0].craft_id) == craft_id, "Sitzung: das gewaehlte Schiff ist das erste Schiff der Basis")
	var data: Dictionary = _data()
	data["initial_fuel"] = initial_fuel
	supply.configure(crafts, data)
	screen.request_operation("accept_job", {"job_id": "satellite_recovery"})
	screen.request_operation("select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery"})
	return {"flow": flow, "runtime": runtime, "supply": supply, "screen": screen, "craft_id": craft_id}

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

func _jump(session: Dictionary, target_orbit_id: String) -> Dictionary:
	return session.screen.request_operation("space_start_quantum", {"craft_id": session.craft_id, "target_orbit_id": target_orbit_id})

func _site_orbit(session: Dictionary) -> String:
	return String(Dictionary(session.runtime.get_space_travel_snapshot(session.craft_id).get("location_orbits", {})).get("satellite_crash", ""))

func _arrived(session: Dictionary, orbit_id: String) -> Callable:
	return func() -> bool: return _phase(session) == "orbit" and String(session.runtime.get_space_travel_snapshot(session.craft_id).get("orbit_id", "")) == orbit_id

# --- 1. Tabelle und Besitzer ----------------------------------------------------------------------

func _scenario_table_and_owner() -> void:
	var data: Dictionary = _data()
	var routes: Dictionary = data.route_fuel_costs
	var legs: Dictionary = data.get("leg_fuel_costs", {})
	_check(not legs.is_empty(), "1: leg_fuel_costs ist in den Versorgungsdaten vorhanden")
	var supply: Object = SUPPLY_SCRIPT.new()
	_check(bool(supply.configure([{"craft_id": "ship"}], data).get("ok", false)), "1: Versorgungsdaten mit Etappenblock werden angenommen")
	for route: String in routes:
		var sum: float = 0.0
		for value: Variant in Dictionary(legs.get(route, {})).values():
			sum += float(value)
		_check(is_equal_approx(sum, float(routes[route])), "1: Summe der Etappen == Routenwert fuer " + route)
		var parts: PackedStringArray = route.split(">")
		_check(is_equal_approx(supply.get_leg_fuel_cost(parts[0], parts[1], "whole_route"), float(routes[route])), "1: whole_route des Besitzers == Routenwert fuer " + route)
	# Eine Tabelle, die nicht aufgeht, wird abgelehnt.
	var broken: Dictionary = _data()
	broken.leg_fuel_costs["homebase>trade_outpost"]["approach"] = 4.0
	_check(not bool(SUPPLY_SCRIPT.new().configure([{"craft_id": "ship"}], broken).get("ok", true)), "1: eine Etappentabelle, die nicht aufgeht, wird abgelehnt")
	# Vorpruefung ist rein lesend.
	var revision: int = supply.get_revision()
	var gate: Dictionary = supply.preview_leg_fuel({"craft_id": "ship", "leg": "launch", "origin_location_id": "homebase", "destination_location_id": ""}, {"departure_authorized": true})
	_check(gate.get("ok", false) and supply.get_revision() == revision and supply.get_fuel("ship") == 60.0, "Vorpruefung einer Etappe aendert weder Treibstoff noch _revision")
	_check(not supply.preview_leg_fuel({"craft_id": "ship", "leg": "launch", "origin_location_id": "homebase", "destination_location_id": ""}).get("ok", true), "Vorpruefung ohne Abflugberechtigung wird abgelehnt")
	_check(String(supply.preview_leg_fuel({"craft_id": "ship", "leg": "nonsense", "origin_location_id": "homebase", "destination_location_id": "polisa", "x": 1}, {"departure_authorized": true}).get("reason", "")) == "unknown_leg", "Unbekannte Etappe wird als unknown_leg abgelehnt")
	# 6: dieselbe Etappe zweimal (gleiche Request-ID) -> eine Buchung, die zweite Antwort ist replayed.
	var context: Dictionary = {"departure_authorized": true}
	var first: Dictionary = supply.apply_command(_leg_command("ship", "launch", "homebase", "", "t1:launch"), context)
	var second: Dictionary = supply.apply_command(_leg_command("ship", "launch", "homebase", "", "t1:launch"), context)
	_check(first.get("ok", false) and not first.has("replayed") and is_equal_approx(supply.get_fuel("ship"), 58.0), "6: erste Buchung zieht genau den Etappenanteil ab (60 -> 58)")
	_check(second.get("ok", false) and bool(second.get("replayed", false)) and is_equal_approx(supply.get_fuel("ship"), 58.0), "6: zweite Antwort derselben Anfrage ist replayed und bucht nicht noch einmal")
	var conflict: Dictionary = supply.apply_command(_leg_command("ship", "jump", "homebase", "satellite_crash", "t1:launch"), context)
	_check(not conflict.get("ok", true) and String(conflict.get("reason", "")) == "request_id_conflict", "6: dieselbe Request-ID mit anderer Etappe wird abgelehnt")
	# 3: nicht gedeckt -> abgelehnt, nichts gebucht, mit Text "Benoetigt X, vorhanden Y".
	var poor: Object = SUPPLY_SCRIPT.new()
	var poor_data: Dictionary = _data()
	poor_data["initial_fuel"] = 4.0
	poor.configure([{"craft_id": "ship"}], poor_data)
	var rejected: Dictionary = poor.apply_command(_leg_command("ship", "jump", "homebase", "satellite_crash", "t1:poor-jump"), context)
	_check(not rejected.get("ok", true) and String(rejected.get("reason", "")) == "leg_fuel_insufficient", "3: nicht gedeckter Sprung wird mit leg_fuel_insufficient abgelehnt")
	_check(String(rejected.get("message", "")).contains("Treibstoff reicht nicht für diese Etappe") and String(rejected.get("message", "")).contains("Benötigt 5, vorhanden 4"), "3: Text nennt Etappe, benoetigte und vorhandene Menge: " + String(rejected.get("message", "")))
	_check(is_equal_approx(poor.get_fuel("ship"), 4.0) and not poor.has_request("t1:poor-jump"), "3: abgelehnte Etappe bucht nichts und hinterlaesst keinen Beleg")
	# 8 (Besitzerebene): Ortsabflug mit zu wenig Treibstoff behaelt den alten Satz.
	var exit_rejected: Dictionary = poor.apply_command(_leg_command("ship", "surface_exit", "satellite_crash", "homebase", "t1:poor-exit"), context)
	_check(String(exit_rejected.get("reason", "")) == "leg_fuel_insufficient" and String(exit_rejected.get("message", "")) == "Treibstoff reicht nicht für den Rückflug", "8: Ortsabflug mit zu wenig Treibstoff: alter Satz 'Treibstoff reicht nicht für den Rückflug'")
	# Die kostenlose Heimlandung ist immer bezahlbar, auch bei leerem Tank.
	var empty: Object = SUPPLY_SCRIPT.new()
	var empty_data: Dictionary = _data()
	empty_data["initial_fuel"] = 0.0
	empty.configure([{"craft_id": "ship"}], empty_data)
	_check(empty.preview_leg_fuel({"craft_id": "ship", "leg": "landing", "origin_location_id": "", "destination_location_id": "homebase"}, context).get("ok", false), "3: die Heimlandung kostet nichts und ist bei leerem Tank bezahlbar")
	# Alte Belege bleiben gueltig: consume_route_fuel wirkt wie bisher.
	var legacy: Dictionary = poor.apply_command({"contract_category": "singleplayer_supply", "operation": "consume_route_fuel", "payload": {"craft_id": "ship", "origin_location_id": "homebase", "destination_location_id": "trade_outpost"}, "request_id": "t1:old-route"}, context)
	_check(not legacy.get("ok", true) and String(legacy.get("reason", "")) == "insufficient_fuel", "4 (Entscheidung): consume_route_fuel bleibt fuer alte Belege gueltig und prueft wie bisher")
	# Rueckweg vom Ort: nach einem Hinweg ueber den Orbit nur der Ortsabflug, nach einem Direktstart (oder altem/unbekanntem Beleg) die ganze Strecke.
	var fresh: Object = SUPPLY_SCRIPT.new()
	fresh.configure([{"craft_id": "ship"}], _data())
	fresh.apply_command(_leg_command("ship", "approach", "homebase", "satellite_crash", "departure:orbit:fuel"), context)
	fresh.apply_command(_leg_command("ship", "whole_route", "homebase", "satellite_crash", "departure:direct:fuel"), context)
	fresh.apply_command({"contract_category": "singleplayer_supply", "operation": "consume_route_fuel", "payload": {"craft_id": "ship", "origin_location_id": "homebase", "destination_location_id": "trade_outpost"}, "request_id": "departure:old:fuel"}, context)
	_check(fresh.get_return_leg("departure:orbit") == "surface_exit", "8: nach einem Hinweg ueber den Orbit ist der Rueckweg vom Ort der Ortsabflug")
	_check(fresh.get_return_leg("departure:direct") == "whole_route" and fresh.get_return_leg("departure:old") == "whole_route" and fresh.get_return_leg("departure:unknown") == "whole_route", "8: nach Direktstart, altem oder unbekanntem Beleg ist der Rueckweg die ganze Strecke")

# --- 9. Speichern, Laden, Altstaende --------------------------------------------------------------

func _scenario_save_and_load() -> void:
	var supply: Object = SUPPLY_SCRIPT.new()
	supply.configure([{"craft_id": "ship"}], _data())
	var context: Dictionary = {"departure_authorized": true}
	supply.apply_command(_leg_command("ship", "launch", "homebase", "", "t1:save:launch"), context)
	supply.apply_command(_leg_command("ship", "jump", "homebase", "satellite_crash", "t1:save:jump"), context)
	var exported: Dictionary = supply.export_state()
	var from_disk: Dictionary = Dictionary(JSON.parse_string(JSON.stringify(exported)))
	var loaded: Object = SUPPLY_SCRIPT.new()
	loaded.configure([{"craft_id": "ship"}], _data())
	var result: Dictionary = loaded.restore_state(from_disk)
	_check(result.get("ok", false), "9: ein frisch gespeicherter Stand mit Etappenbelegen laedt: " + str(result))
	_check(is_equal_approx(loaded.get_fuel("ship"), 53.0) and loaded.has_request("t1:save:launch") and loaded.has_request("t1:save:jump"), "9: Treibstoff und Belege sind nach dem Laden gleich")
	var replay: Dictionary = loaded.apply_command(_leg_command("ship", "jump", "homebase", "satellite_crash", "t1:save:jump"), context)
	_check(bool(replay.get("replayed", false)) and is_equal_approx(loaded.get_fuel("ship"), 53.0), "9: ein geladener Etappenbeleg bucht beim Wiederholen nicht noch einmal")
	# Stand, wie er vor T1 gespeichert wurde (ohne Etappenblock): muss weiter laden.
	var legacy_state: Dictionary = from_disk.duplicate(true)
	legacy_state.definitions.erase("leg_fuel_costs")
	var legacy_target: Object = SUPPLY_SCRIPT.new()
	legacy_target.configure([{"craft_id": "ship"}], _data())
	var legacy_result: Dictionary = legacy_target.restore_state(legacy_state)
	_check(legacy_result.get("ok", false), "9/5: ein Stand ohne leg_fuel_costs (vor T1 gespeichert) laedt weiter: " + str(legacy_result))
	_check(not Dictionary(legacy_target.get_supply_snapshot().get("leg_fuel_costs", {})).is_empty(), "9/5: nach dem Laden eines Altstands gelten die aktuellen Etappenkosten")
	# Ein gespeicherter Block, der vom aktuellen abweicht, bleibt streng abgelehnt.
	var tampered: Dictionary = from_disk.duplicate(true)
	tampered.definitions.leg_fuel_costs["homebase>trade_outpost"]["approach"] = 99.0
	var tamper_target: Object = SUPPLY_SCRIPT.new()
	tamper_target.configure([{"craft_id": "ship"}], _data())
	_check(String(tamper_target.restore_state(tampered).get("reason", "")) == "stale_supply_definitions", "9/5: ein gespeicherter Etappenblock, der vom aktuellen abweicht, wird weiter streng abgelehnt")
	# Echte Altstaende aus dem Repository (Main 639a49d65 und Staende vom 13.11.).
	for path: String in OLD_FIXTURES:
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not parsed is Dictionary or not Dictionary(parsed).has("supply"):
			_check(false, "9/5: Altstand lesbar: " + path)
			continue
		var old_state: Dictionary = Dictionary(Dictionary(parsed).supply)
		_check(not Dictionary(old_state.definitions).has("leg_fuel_costs"), "9/5: Altstand kennt keinen Etappenblock: " + path)
		var target: Object = SUPPLY_SCRIPT.new()
		target.configure([{"craft_id": "ship"}], _data())
		var old_result: Dictionary = target.restore_state(old_state)
		_check(old_result.get("ok", false), "9/5: Altstand laedt weiter: " + path + " -> " + str(old_result))

# --- 2. und 7. Voller Tank: jede Etappe bucht ihren Anteil ----------------------------------------

func _scenario_full_tank_flight() -> void:
	var s: Dictionary = await _session(60.0)
	var supply: Object = s.supply
	var craft_id: String = s.craft_id
	_check(is_equal_approx(supply.get_fuel(craft_id), 60.0), "2: Ausgangsstand 60 Treibstoff")
	var launch: Dictionary = _launch(s)
	_check(launch.get("ok", false) and _phase(s) == "orbit", "2: Abheben angenommen, Schiff im Mondorbit: " + str(launch))
	_check(is_equal_approx(supply.get_fuel(craft_id), 58.0), "2: Abheben bucht genau seinen Anteil (60 -> 58), ist %s" % supply.get_fuel(craft_id))
	var site_orbit: String = _site_orbit(s)
	var jump: Dictionary = _jump(s, site_orbit)
	_check(jump.get("ok", false), "2: Quantensprung angenommen: " + str(jump))
	_check(is_equal_approx(supply.get_fuel(craft_id), 53.0), "2: der Sprung bucht genau seinen Anteil (58 -> 53), ist %s" % supply.get_fuel(craft_id))
	var arrived: bool = await _wait_for(s, _arrived(s, site_orbit), 20000)
	_check(arrived, "2: Schiff erreicht den Zielorbit")
	_check(is_equal_approx(supply.get_fuel(craft_id), 53.0), "2: das Ankommen bucht nichts")
	var approach: Dictionary = s.screen.request_operation("space_begin_approach", {"craft_id": craft_id, "location_id": "satellite_crash"})
	_check(approach.get("ok", false), "2: Anflug angenommen: " + str(approach))
	_check(is_equal_approx(supply.get_fuel(craft_id), 48.0), "2: der Anflug bucht genau seinen Anteil (53 -> 48), ist %s" % supply.get_fuel(craft_id))
	_check(is_equal_approx(60.0 - supply.get_fuel(craft_id), 12.0), "2: Summe der gebuchten Etappen == Strecke Heimat -> Satelliten-Absturzstelle (12)")
	await _close(s)

# --- 7. Sprung abbrechen und neu starten: eine Buchung ---------------------------------------------

func _scenario_jump_restart() -> void:
	var s: Dictionary = await _session(60.0)
	var supply: Object = s.supply
	var craft_id: String = s.craft_id
	_launch(s)
	var site_orbit: String = _site_orbit(s)
	var jump: Dictionary = _jump(s, site_orbit)
	_check(jump.get("ok", false) and is_equal_approx(supply.get_fuel(craft_id), 53.0), "7: der Sprung ist angenommen und gebucht (53)")
	# Wie im echten Spielablauf: erst ein Stueck fliegen lassen, dann abbrechen.
	await _wait_for(s, func() -> bool: return float(s.runtime.get_space_travel_snapshot(craft_id).get("progress", 0.0)) > 0.05, 3000)
	var aborted: Dictionary = s.screen.request_operation("space_abort_quantum", {"craft_id": craft_id})
	_check(aborted.get("ok", false) and _phase(s) == "stopped", "7: Abbruch haelt das Schiff mitten im All an: " + str(aborted) + " Phase " + _phase(s))
	_check(is_equal_approx(supply.get_fuel(craft_id), 53.0), "7: der Abbruch erstattet nichts zurueck")
	var restart: Dictionary = _jump(s, site_orbit)
	_check(restart.get("ok", false), "7: der Neustart aus stopped ist angenommen: " + str(restart))
	_check(is_equal_approx(supply.get_fuel(craft_id), 53.0), "7: der Neustart kostet die Sprungetappe nicht noch einmal, ist %s" % supply.get_fuel(craft_id))
	var status: Dictionary = s.runtime.get_fuel_status(craft_id)
	_check(not bool(status.get("stranded", true)), "7: ein Schiff mit bezahltem, unvollendetem Sprung ist nicht liegen geblieben")
	var arrived: bool = await _wait_for(s, _arrived(s, site_orbit), 20000)
	_check(arrived and is_equal_approx(supply.get_fuel(craft_id), 53.0), "7: nach der Ankunft bleibt es bei einer Sprungbuchung (53)")
	await _close(s)

# --- 4. Tank 0 an der Basis: Abheben wird abgelehnt -------------------------------------------------

func _scenario_launch_without_fuel() -> void:
	var s: Dictionary = await _session(0.0)
	var supply: Object = s.supply
	var craft_id: String = s.craft_id
	var status_home: Dictionary = s.runtime.get_fuel_status(craft_id)
	_check(not bool(status_home.get("stranded", true)) and bool(status_home.get("refuel_here", false)), "4: an der Heimatbasis ist man nie liegen geblieben (Tankservice vorhanden)")
	var launch: Dictionary = _launch(s)
	_check(not launch.get("ok", true) and String(launch.get("reason", "")) == "leg_fuel_insufficient", "4: Abheben mit leerem Tank wird abgelehnt (leg_fuel_insufficient): " + str(launch))
	_check(_phase(s) == "grounded" and is_equal_approx(supply.get_fuel(craft_id), 0.0), "4: das Schiff bleibt am Boden, nichts gebucht")
	await _close(s)

# --- 3. Abheben gedeckt, Sprung nicht gedeckt ----------------------------------------------------

func _scenario_jump_without_fuel() -> void:
	var s: Dictionary = await _session(6.0)
	var supply: Object = s.supply
	var craft_id: String = s.craft_id
	var launch: Dictionary = _launch(s)
	_check(launch.get("ok", false) and _phase(s) == "orbit" and is_equal_approx(supply.get_fuel(craft_id), 4.0), "3: Abheben wird angenommen und bucht seinen Anteil (6 -> 4)")
	var jump: Dictionary = _jump(s, _site_orbit(s))
	_check(not jump.get("ok", true) and String(jump.get("reason", "")) == "leg_fuel_insufficient", "3: der Sprung wird mit leg_fuel_insufficient abgelehnt: " + str(jump))
	_check(String(jump.get("message", "")).contains("Benötigt 5, vorhanden 4"), "3: die Ablehnung nennt benoetigt/vorhanden: " + String(jump.get("message", "")))
	_check(_phase(s) == "orbit" and is_equal_approx(supply.get_fuel(craft_id), 4.0), "3: abgelehnter Sprung bucht nichts, das Schiff bleibt im Mondorbit")
	var status: Dictionary = s.runtime.get_fuel_status(craft_id)
	_check(not bool(status.get("stranded", true)), "3: im Mondorbit ist die kostenlose Heimlandung eine bezahlbare Folgeetappe, also nicht liegen geblieben")
	var landing_affordable: bool = false
	for leg: Dictionary in Array(status.get("next_legs", [])):
		if String(leg.get("leg", "")) == "landing" and bool(leg.get("affordable", false)): landing_affordable = true
	_check(landing_affordable, "3: get_fuel_status fuehrt die Heimlandung als bezahlbare Folgeetappe")
	await _close(s)

# --- 3. Liegen geblieben im Orbit des Ziels ------------------------------------------------------

func _scenario_stranded_in_orbit() -> void:
	var s: Dictionary = await _session(11.0)
	var supply: Object = s.supply
	var craft_id: String = s.craft_id
	_launch(s)
	var site_orbit: String = _site_orbit(s)
	_jump(s, site_orbit)
	var arrived: bool = await _wait_for(s, _arrived(s, site_orbit), 20000)
	_check(arrived and is_equal_approx(supply.get_fuel(craft_id), 4.0), "3: im Zielorbit bleiben 4 Treibstoff (11 - 2 - 5)")
	var status: Dictionary = s.runtime.get_fuel_status(craft_id)
	_check(bool(status.get("stranded", false)) and String(status.get("strand_place", "")) == "orbit" and not bool(status.get("refuel_here", true)), "3: weder Anflug (5) noch Rueckflugsprung (5) sind bezahlbar, hier ist kein Tankservice: liegen geblieben im Orbit: " + str(status))
	var approach: Dictionary = s.screen.request_operation("space_begin_approach", {"craft_id": craft_id, "location_id": "satellite_crash"})
	_check(not approach.get("ok", true) and String(approach.get("reason", "")) == "leg_fuel_insufficient", "3: der Anflug wird abgelehnt: " + str(approach))
	_check(is_equal_approx(supply.get_fuel(craft_id), 4.0) and _phase(s) == "orbit", "3: abgelehnter Anflug bucht nichts")
	await _close(s)

# --- 5. Anflug ohne Reserve --------------------------------------------------------------------

func _scenario_outbound_only_approach() -> void:
	var s: Dictionary = await _session(12.0)
	var supply: Object = s.supply
	var craft_id: String = s.craft_id
	var reach: Dictionary = s.runtime.call("_fuel_reachability", craft_id, {"homebase": {}, "satellite_crash": {}, "trade_outpost": {}})
	_check(Dictionary(reach.get("satellite_crash", {})).get("ok", false) and Dictionary(reach.get("satellite_crash", {})).get("route_ok", false), "5: Reichweite zeigt den ganzen Hinweg (12 von 12) als gedeckt, ohne Rueckflugreserve")
	_check(Dictionary(reach.get("trade_outpost", {})).get("route_ok", false), "5: Reichweite Handelsposten (8 von 12) gedeckt")
	_launch(s)
	var site_orbit: String = _site_orbit(s)
	_jump(s, site_orbit)
	var arrived: bool = await _wait_for(s, _arrived(s, site_orbit), 20000)
	_check(arrived and is_equal_approx(supply.get_fuel(craft_id), 5.0), "5: im Zielorbit bleiben genau 5 Treibstoff (12 - 2 - 5)")
	var approach: Dictionary = s.screen.request_operation("space_begin_approach", {"craft_id": craft_id, "location_id": "satellite_crash"})
	_check(approach.get("ok", false), "5: der Anflug wird angenommen, wenn nur der Hinweg bezahlbar ist (keine Rueckflugreserve): " + str(approach))
	_check(is_equal_approx(supply.get_fuel(craft_id), 0.0), "5: nach dem Anflug ist der Tank leer")
	var on_ground: bool = await _wait_for(s, func() -> bool: return _phase(s) == "surface", 90000)
	_check(on_ground, "5: das Schiff setzt am Ort auf (Phase surface), Phase ist " + _phase(s))
	var status: Dictionary = s.runtime.get_fuel_status(craft_id)
	var exit_affordable: bool = true
	for leg: Dictionary in Array(status.get("next_legs", [])):
		if String(leg.get("leg", "")) == "surface_exit": exit_affordable = bool(leg.get("affordable", true))
	_check(on_ground and not exit_affordable, "5: am Ort meldet get_fuel_status den Rueckweg (Ortsabflug) als nicht bezahlbar: " + str(status))
	# 8 und 10 (Flow-Ebene): der Rueckzug ("Abheben" am HUD) nutzt dieselbe Vorpruefung, bleibt lesend und lehnt mit dem Treibstoffgrund ab.
	var before_fuel: float = supply.get_fuel(craft_id)
	var revision: int = supply.get_revision()
	var preflight: Dictionary = s.flow.call("_departure_return_preflight", craft_id)
	_check(not bool(preflight.get("ok", true)) and String(preflight.get("reason", "")) in ["leg_fuel_insufficient", "insufficient_fuel", "insufficient_return_fuel"], "10: die Vorpruefung des HUD-Rueckzugs lehnt ohne Treibstoff fuer den Ortsabflug ab: " + str(preflight))
	_check(is_equal_approx(supply.get_fuel(craft_id), before_fuel) and supply.get_revision() == revision, "10: die Vorpruefung bucht nichts und aendert _revision nicht")
	_check(_phase(s) == "surface", "8: nach der Ablehnung bleibt das Schiff am Ort (Phase surface)")
	await _close(s)

# --- 10. Rueckzug mit gedecktem Ortsabflug ---------------------------------------------------------

func _scenario_return_preflight_covered() -> void:
	var s: Dictionary = await _session(19.0)
	var supply: Object = s.supply
	var craft_id: String = s.craft_id
	_launch(s)
	var site_orbit: String = _site_orbit(s)
	_jump(s, site_orbit)
	await _wait_for(s, _arrived(s, site_orbit), 20000)
	s.screen.request_operation("space_begin_approach", {"craft_id": craft_id, "location_id": "satellite_crash"})
	var on_ground: bool = await _wait_for(s, func() -> bool: return _phase(s) == "surface", 90000)
	_check(on_ground and is_equal_approx(supply.get_fuel(craft_id), 7.0), "10: 19 - 2 - 5 - 5 = 7 Treibstoff am Ort, der Ortsabflug kostet 7")
	var revision: int = supply.get_revision()
	var preflight: Dictionary = s.flow.call("_departure_return_preflight", craft_id)
	_check(bool(preflight.get("ok", false)), "10: die Vorpruefung des HUD-Rueckzugs laesst zu, wenn der Ortsabflug gedeckt ist: " + str(preflight))
	_check(is_equal_approx(supply.get_fuel(craft_id), 7.0) and supply.get_revision() == revision, "10: die Vorpruefung bleibt lesend (Treibstoff und _revision gleich)")
	await _close(s)
