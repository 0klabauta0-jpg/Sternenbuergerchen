extends SceneTree
## Kapitel 2, Aufgabe 0b: neuer Ort "relay_ridge" (Relaisgrat auf Ground Mission 02) ist additiv - Staende ohne den Ort laden weiter.
## Nur Besitzer, kein Fenster. Die Staende "von vorher" werden rechnerisch aus den heutigen Definitionen ohne die neuen Eintraege gebaut.
const CAMPAIGN = preload("res://scripts/core/singleplayer_campaign_state.gd")
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const SCENARIO = preload("res://scripts/mission/mission_scenario_data.gd")
const SURFACE = preload("res://scripts/mission/orbit_surface_locations.gd")
const PLACE := "relay_ridge"
const MAP := "res://maps/Ground_Mission02_128x128.json"
const SCENARIO_PATH := "res://data/mission_scenarios/flak_silence.json"
const NEXT_STAGE: Array = ["relay_ridge", "asteroid_belt", "muellers_farm", "shady_lab", "templanon"]
var passed := 0
var failed := 0

func _check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print(("PASS " if value else "FAIL ") + label)

func _init() -> void:
	call_deferred("_run")

func _campaign() -> RefCounted:
	var owner: RefCounted = CAMPAIGN.new()
	owner.configure()
	return owner

func _supply() -> RefCounted:
	var owner: RefCounted = SUPPLY.new()
	owner.configure([{"craft_id": "ship"}])
	return owner

func _json(value: Variant) -> Dictionary:
	return Dictionary(JSON.parse_string(JSON.stringify(value)))

func _run() -> void:
	_case_lists()
	_case_campaign_load()
	_case_supply_load()
	_case_data()
	_case_scenario()
	print("CAMPAIGN_ADDITIVE_LOCATION passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _case_lists() -> void:
	_check(CAMPAIGN.ADDITIVE_LOCATION_IDS == NEXT_STAGE, "Liste: Kampagnenstand kennt die fuenf Kennungen")
	_check(SUPPLY.ADDITIVE_LOCATION_IDS == NEXT_STAGE, "Liste: Versorgungsstand kennt dieselben fuenf Kennungen")

func _case_campaign_load() -> void:
	var state: Dictionary = _json(_campaign().export_state())
	_check(state.locations.has(PLACE), "Fixture: heutiger Stand enthaelt den Ort %s" % PLACE)
	var before: Dictionary = state.duplicate(true)
	before.locations.erase(PLACE)
	var relocated: Array = CAMPAIGN.adopt_current_location_definitions(before)
	_check(relocated.is_empty(), "Fall 1: relocated_location_ids leer (%s)" % str(relocated))
	var verdict: Dictionary = _campaign().restore_state(before)
	_check(bool(verdict.get("ok", false)), "Fall 1: Stand ohne %s laedt (beobachtet %s)" % [PLACE, str(verdict)])
	var wrong_pad: Dictionary = state.duplicate(true)
	wrong_pad.locations[PLACE].landing_pad_ids = ["x"]
	_check(String(_campaign().restore_state(wrong_pad).get("reason", "")) == "stale_campaign_definitions", "Fall 2: gespeicherter Ort mit anderem Landeplatz -> stale_campaign_definitions")
	var no_trade: Dictionary = state.duplicate(true)
	no_trade.locations.erase("trade_outpost")
	_check(String(_campaign().restore_state(no_trade).get("reason", "")) == "stale_campaign_definitions", "Fall 3: Stand ohne trade_outpost -> abgelehnt")
	var extra: Dictionary = before.duplicate(true)
	extra.locations["asteroid_belt"] = state.locations[PLACE].duplicate(true)
	extra.locations.asteroid_belt.id = "asteroid_belt"
	_check(String(_campaign().restore_state(extra).get("reason", "")) == "stale_campaign_definitions", "Fall 3b: gespeicherter Ort, den es heute nicht gibt (Kennung der Liste), -> abgelehnt")
	var full: Dictionary = _campaign().restore_state(state.duplicate(true))
	_check(bool(full.get("ok", false)), "Fall 3c: heutiger Stand mit Ort laedt (beobachtet %s)" % str(full))
	_check(not _campaign().get_campaign_snapshot().locations.has("asteroid_belt"), "Fall 3d: Kennung der Liste ohne Daten stoert nicht, es entsteht kein Ort")

func _supply_before(state: Dictionary, strip_services: bool, strip_routes: bool, strip_legs: bool) -> Dictionary:
	var before: Dictionary = state.duplicate(true)
	if strip_services: before.definitions.service_locations.erase(PLACE)
	for route in Dictionary(before.definitions.route_fuel_costs).keys():
		if strip_routes and String(route).contains(PLACE): before.definitions.route_fuel_costs.erase(route)
	for route in Dictionary(before.definitions.get("leg_fuel_costs", {})).keys():
		if strip_legs and String(route).contains(PLACE): before.definitions.leg_fuel_costs.erase(route)
	return before

func _supply_restore(state: Dictionary) -> Dictionary:
	var target: RefCounted = _supply()
	return target.restore_state(state)

func _case_supply_load() -> void:
	var state: Dictionary = _json(_supply().export_state())
	_check(state.definitions.service_locations.has(PLACE) and state.definitions.route_fuel_costs.has("homebase>" + PLACE), "Fixture: heutiger Versorgungsstand enthaelt Dienste und Strecken des Ortes")
	var today: Dictionary = _supply_restore(state.duplicate(true))
	_check(bool(today.get("ok", false)), "Fall 4a: heutiger Stand laedt (beobachtet %s)" % str(today))
	var before: Dictionary = _supply_before(state, true, true, true)
	_check(not JSON.stringify(before.definitions).contains(PLACE), "Fixture: Vorher-Stand enthaelt nichts vom neuen Ort")
	var old_result: Dictionary = _supply_restore(before)
	_check(bool(old_result.get("ok", false)), "Fall 4: Versorgungsstand ohne Dienste, Strecken und Etappen des Ortes laedt (beobachtet %s)" % str(old_result))
	var legs_only: Dictionary = _supply_before(state, true, true, true)
	var no_legs: Dictionary = _supply_before(state, true, true, true)
	no_legs.definitions.erase("leg_fuel_costs")
	_check(bool(_supply_restore(no_legs).get("ok", false)), "Fall 4b: Stand ganz ohne Etappenblock (aelter) laedt weiter")
	var routes_no_legs: Dictionary = _supply_before(state, true, false, true)
	var tampered: Dictionary = state.duplicate(true)
	tampered.definitions.leg_fuel_costs["homebase>" + PLACE]["jump"] = 9.0
	_check(String(_supply_restore(tampered).get("reason", "")) == "stale_supply_definitions", "Fall 5: gespeicherte Etappe des Ortes mit jump 9.0 -> stale_supply_definitions")
	var tampered_route: Dictionary = state.duplicate(true)
	tampered_route.definitions.route_fuel_costs["homebase>" + PLACE] = 11.0
	_check(String(_supply_restore(tampered_route).get("reason", "")) == "stale_supply_definitions", "Fall 5b: gespeicherte Strecke des Ortes mit anderem Preis -> stale_supply_definitions")
	var polisa_gone: Dictionary = before.duplicate(true)
	polisa_gone.definitions.route_fuel_costs.erase("homebase>trade_outpost")
	_check(String(_supply_restore(polisa_gone).get("reason", "")) == "stale_supply_definitions", "Fall 5c: fehlende alte Strecke bleibt abgelehnt")
	var other: Dictionary = before.duplicate(true)
	other.definitions.route_fuel_costs["homebase>asteroid_belt"] = 10.0
	_check(String(_supply_restore(other).get("reason", "")) == "stale_supply_definitions", "Fall 5d: gespeicherte Strecke zu einem Ort, den es heute nicht gibt, bleibt abgelehnt")
	if legs_only.is_empty() or routes_no_legs.is_empty(): _check(false, "Fixture: Vorher-Staende")

func _case_data() -> void:
	var owner: RefCounted = _campaign()
	var snapshot: Dictionary = owner.get_campaign_snapshot()
	_check(snapshot.locations.has(PLACE) and String(snapshot.locations[PLACE].map_file_path) == MAP, "Fall 6: Ort hat die Karte Ground Mission 02")
	var visit: Dictionary = owner.validate_location_visit(PLACE)
	_check(not bool(visit.get("ok", true)) and String(visit.get("reason", "")) == "tutorial_locked", "Fall 6: ohne freigegebenen Auftrag nicht anfliegbar (%s)" % str(visit))
	var supply: RefCounted = _supply()
	var routes: Dictionary = Dictionary(supply.get_supply_snapshot().get("route_fuel_costs", {}))
	_check(is_equal_approx(float(routes.get("homebase>" + PLACE, -1.0)), 10.0) and is_equal_approx(float(routes.get(PLACE + ">homebase", -1.0)), 10.0), "Fall 7: Strecke homebase>relay_ridge und zurueck kosten 10.0 (%s)" % str(routes))
	_check(is_equal_approx(supply.get_leg_fuel_cost("homebase", PLACE, "jump"), 8.0) and is_equal_approx(supply.get_leg_fuel_cost(PLACE, "homebase", "surface_exit"), 2.0), "Fall 7: Etappen des Ortes sind eingetragen")

func _case_scenario() -> void:
	var scenario = SCENARIO.load_from_file(SCENARIO_PATH)
	var verdict: Dictionary = Dictionary(scenario.validate())
	_check(bool(verdict.get("valid", false)), "Fall 8: flak_silence.json laedt ueber den echten Lader ohne Fehler (%s)" % str(verdict.get("errors", [])))
	_check(String(scenario.map_file_path) == MAP, "Fall 8: Szenariokarte gleich der Karte des Ortes")
	var locations: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/locations.json"))
	_check(typeof(locations) == TYPE_DICTIONARY and String(Dictionary(locations).get(PLACE, {}).get("scenario_file_path", "")) == SCENARIO_PATH and String(Dictionary(locations)[PLACE].map_file_path) == String(scenario.map_file_path), "Fall 8: Ort verweist auf flak_silence.json mit gleicher Karte")
	var planet: Dictionary = {"id": "planet", "kind": "planet"}
	_check(SURFACE.contains(planet, "fortified_outpost"), "Fall 9: fortified_outpost am Planeten ist weiter landbar")
	_check(SURFACE.contains(planet, PLACE), "Fall 9: relay_ridge am Planeten ist landbar")
