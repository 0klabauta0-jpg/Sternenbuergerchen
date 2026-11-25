extends SceneTree
## Handel 2a, Aufgabe 2: drei kleine Aussenposten (Muellers Farm, Shady Research Lab, Templanon) als Orte mit friedlichem Besuchsszenario.
## Echte Lader (Szenario, Karte, Landepruefung), echter Kampagnen- und Versorgungsstand. Kein Fenster, kein Flug.
## Abschlusszeile: SMALL_OUTPOSTS_LOCATIONS passed=%d failed=%d
const CAMPAIGN = preload("res://scripts/core/singleplayer_campaign_state.gd")
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const COMMAND = preload("res://scripts/mission/singleplayer_campaign_command_contract.gd")
const SCENARIO = preload("res://scripts/mission/mission_scenario_data.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const PATHFINDER = preload("res://scripts/terrain/terrain_pathfinder.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const FIELD_LANDING = preload("res://scripts/mission/field_landing_contract.gd")
const SURFACE = preload("res://scripts/mission/orbit_surface_locations.gd")
const PLACES := {
	"muellers_farm": {"name": "Müllers Farm", "map": "res://maps/trade_outpost.json", "marker": "spawn_bravo", "pad": "muellers_farm_pad_01", "orbit": "glut_1b_orbit", "body": "glut_1b", "home": 9.0, "trade": 6.0, "crash": 11.0},
	"shady_lab": {"name": "Shady Research Lab", "map": "res://maps/Ground_Mission02_128x128.json", "marker": "spawn_bravo", "pad": "gm02_pad_bravo", "orbit": "planet_orbit", "body": "planet", "home": 10.0, "trade": 9.0, "crash": 11.0},
	"templanon": {"name": "Templanon", "map": "res://maps/windbruch_outpost.json", "marker": "recon_altfeld", "pad": "windbruch_pad_03", "orbit": "planet_orbit", "body": "planet", "home": 10.0, "trade": 9.0, "crash": 11.0},
}
var passed := 0
var failed := 0
var sequence := 0
var owner: RefCounted

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print(("PASS " if value else "FAIL ") + label)

func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}

func _run() -> void:
	_case_files()
	_case_scenarios()
	_case_map_facts()
	_case_unlock()
	_case_supply()
	_case_surface()
	_case_orbit_resolution()
	print("SMALL_OUTPOSTS_LOCATIONS passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _marker_grid(map, id: String) -> Vector2i:
	var position: Vector2 = map.get_marker_position(id)
	var nearest := Vector2i.ZERO
	var distance := INF
	for tile in map.get_tiles():
		var candidate: float = tile.world_position.distance_squared_to(position)
		if candidate < distance:
			distance = candidate
			nearest = tile.grid_position
	return nearest

func _registry(map) -> Node:
	var registry = REGISTRY.new()
	registry.configure_iso_grid(map.get_grid_origin(), 64, 32, map.get_grid_topology())
	for tile in map.get_tiles(): registry.register_tile(tile)
	return registry

func _reachable(map, registry, start: Vector2i) -> Dictionary:
	var pathfinder = PATHFINDER.new()
	var visited := {start: true}
	var queue: Array[Vector2i] = [start]
	var index := 0
	while index < queue.size():
		var current := queue[index]
		index += 1
		for adjacent in HEX.neighbors(current):
			if visited.has(adjacent): continue
			if map.get_tile_at_grid(adjacent) == null or not pathfinder.can_traverse_step(current, adjacent, registry): continue
			visited[adjacent] = true
			queue.append(adjacent)
	return visited

func _case_files() -> void:
	var locations: Dictionary = _json("res://data/singleplayer/locations.json")
	var outposts: Dictionary = _json("res://data/singleplayer/small_outposts.json")
	var orbits: Dictionary = Dictionary(_json("res://data/singleplayer/star_system.json").get("location_orbits", {}))
	var offers: Dictionary = _json("res://data/singleplayer/trade_offers.json")
	var small: Dictionary = Dictionary(outposts.get("locations", {}))
	for id: String in PLACES:
		var want: Dictionary = PLACES[id]
		var loc: Dictionary = Dictionary(locations.get(id, {}))
		_check(String(loc.get("name", "")) == String(want.name) and String(loc.get("map_file_path", "")) == String(want.map) and Array(loc.get("landing_pad_ids", [])) == [want.pad] and Array(loc.get("services", [])) == ["trade"], "Ort %s: Name, Karte, Landepad und Dienst trade" % id)
		_check(String(loc.get("scenario_file_path", "")) == "res://data/mission_scenarios/%s_visit.json" % id and not loc.has("free_visit"), "Ort %s: Besuchsszenario eingetragen, kein free_visit" % id)
		_check(String(orbits.get(id, "")) == String(want.orbit), "Ort %s: Umlaufbahn %s" % [id, want.orbit])
		var entry: Dictionary = Dictionary(small.get(id, {}))
		_check(String(entry.get("service_marker_id", "")) == String(want.marker) and is_equal_approx(float(entry.get("service_radius_world", 0.0)), 256.0) and not entry.has("unlock_after_job_id") and not entry.has("locked_hint"), "Ort %s: small_outposts.json (Marker, Radius 256, keine Freischaltung, kein Sperrtext - Freigabe 25.11.2026)" % id)
		_check(Array(Dictionary(offers.get("service_locations", {})).get(id, [])) == ["trade"], "Ort %s: service_locations trade" % id)
	var farm: Dictionary = Dictionary(locations.get("muellers_farm", {}))
	_check(farm.get("region_position") == [0.86, 0.86] and Dictionary(locations.get("shady_lab", {})).get("region_position") == [0.66, 0.66] and Dictionary(locations.get("templanon", {})).get("region_position") == [0.40, 0.90], "Orte: Lage auf der Sternkarte wie im Plan")

func _case_scenarios() -> void:
	for id: String in PLACES:
		var want: Dictionary = PLACES[id]
		var path := "res://data/mission_scenarios/%s_visit.json" % id
		_check(FileAccess.file_exists(path), "Szenario %s_visit.json existiert" % id)
		if not FileAccess.file_exists(path): continue
		var scenario = SCENARIO.load_from_file(path)
		var verdict: Dictionary = Dictionary(scenario.validate())
		_check(bool(verdict.get("valid", false)), "Szenario %s: gueltig (%s)" % [id, str(verdict.get("errors", []))])
		_check(String(scenario.map_file_path) == String(want.map), "Szenario %s: Karte gleich der Karte des Ortes" % id)
		var map = MAP.load_from_file(String(want.map))
		_check(map.get_load_issue_message().is_empty(), "Karte %s laedt" % id)
		var ids: Array = map.get_marker_ids()
		_check(ids.has(String(want.marker)) and ids.has("spawn_alpha") and ids.has("objective_point"), "Karte %s: Haendler-Marker %s, spawn_alpha und objective_point vorhanden" % [id, want.marker])
		var raw: Dictionary = _json(path)
		var slice: Dictionary = Dictionary(raw.get("vertical_slice", {}))
		var points: Array = Array(slice.get("interaction_points", []))
		_check(points.size() == 1 and String(points[0].interaction_id) == String(want.marker) and String(points[0].marker_id) == String(want.marker) and String(points[0].display_name) == "Händler: " + String(want.name), "Szenario %s: Benutzen-Stelle ist der Haendler-Marker, interaction_id gleich marker_id" % id)
		var steps: Array = Array(slice.get("flow_steps", []))
		_check(steps.size() == 2 and String(steps[0].target_marker_id) == String(want.marker) and String(steps[1].target_marker_id) == "ship_return" and String(steps[1].objective_type) == "location_return", "Szenario %s: Ablauf Haendler, dann Rueckflug" % id)
		_check(Array(raw.get("enemy_groups", [1])).is_empty() and int(Dictionary(raw.get("wave_config", {})).get("wave_count", 1)) == 0 and Array(raw.get("patrol_bindings", [1])).is_empty() and float(raw.get("time_limit_seconds", 1.0)) == 0.0, "Szenario %s: friedlich, keine Gegner, kein Zeitlimit" % id)
		_check(String(slice.get("scenario_kind", "")) == "singleplayer_visit" and String(Dictionary(raw.get("objective", {})).get("marker_id", "")) == "objective_point", "Szenario %s: scenario_kind singleplayer_visit, Ziel objective_point" % id)
		_check(String(Dictionary(raw.get("briefing", {})).get("title", "")) == String(want.name) and String(raw.get("display_name", "")) == String(want.name) and String(raw.get("scenario_id", "")) == id + "_visit", "Szenario %s: Name und Kennung" % id)

func _case_map_facts() -> void:
	for id: String in PLACES:
		var want: Dictionary = PLACES[id]
		var map = MAP.load_from_file(String(want.map))
		if not map.get_marker_ids().has(String(want.marker)): continue
		var start: Vector2i = _marker_grid(map, "spawn_alpha")
		var trader: Vector2i = _marker_grid(map, String(want.marker))
		var registry := _registry(map)
		var visited := _reachable(map, registry, start)
		_check(visited.has(trader), "Karte %s: der Haendler-Marker ist vom Start aus erreichbar" % id)
		var landable := false
		var trader_world: Vector2 = map.get_marker_position(String(want.marker))
		for tile in map.get_tiles():
			if tile.world_position.distance_to(trader_world) > 250.0: continue
			if bool(FIELD_LANDING.validate(registry, tile.grid_position, []).get("ok", false)):
				landable = true
				break
		_check(landable, "Karte %s: im Umkreis von 250 Einheiten um den Haendler gibt es ein gueltiges Landefeld" % id)
		var from_alpha := HEX.distance(start, trader)
		if id == "shady_lab":
			_check(from_alpha >= 40, "Karte shady_lab: Haendler (BRAVO) mindestens 40 Felder von ALPHA (%d)" % from_alpha)
		if id == "templanon":
			var objective: Vector2i = _marker_grid(map, "objective_point")
			_check(from_alpha >= 25 and HEX.distance(objective, trader) >= 25, "Karte templanon: Haendler weit von spawn_alpha (%d) und objective_point (%d)" % [from_alpha, HEX.distance(objective, trader)])
		registry.free()

func _command(operation: String, payload: Dictionary, context: Dictionary = {}) -> Dictionary:
	sequence += 1
	return owner.apply_command(COMMAND.build_command(operation, payload, "small-outposts:%d" % sequence), context)

func _finish_job(id: String) -> void:
	var job: Dictionary = owner.get_campaign_snapshot().jobs[id]
	var ok := String(job.status) == "accepted" or bool(_command("accept_job", {"job_id": id}).get("ok", false))
	ok = ok and bool(_command("bind_departure", {"craft_id": "ship", "origin_location_id": "homebase", "destination_location_id": job.location_id, "landing_pad_id": "homebase_pad_01", "job_id": id}, {"departure_authorized": true}).get("ok", false))
	ok = ok and bool(_command("activate_job", {"craft_id": "ship", "job_id": id}, {"departure_authorized": true}).get("ok", false))
	ok = ok and bool(_command("complete_job", {"craft_id": "ship", "job_id": id}, {"runtime_evidence": {"scenario_id": job.scenario_id, "result": "victory", "mission_scenario_runtime_gates": {"all_gates_complete": true, "completed_step_ids": job.required_step_ids}}}).get("ok", false))
	if bool(job.home_upload): ok = ok and bool(_command("upload_job", {"job_id": id}, {"at_home": true}).get("ok", false))
	_check(ok, "echter Abschluss " + id)

func _case_unlock() -> void:
	owner = CAMPAIGN.new()
	owner.configure()
	for id: String in PLACES:
		var open_at_start: Dictionary = owner.validate_location_visit(id)
		_check(bool(open_at_start.get("ok", false)), "Freigabe %s: direkt nach der Einfuehrung anfliegbar, vor outpost_recovery (%s)" % [id, str(open_at_start)])
		_check(String(owner.open_visit_scenario_id(id)) == "" and String(Dictionary(Dictionary(owner.get_campaign_snapshot().locations).get(id, {})).get("scenario_file_path", "")).get_file().get_basename() == id + "_visit", "Ziel-Szenario %s: ohne Auftrag das Ortsszenario %s_visit" % [id, id])
	_finish_job("satellite_recovery")
	_check(bool(owner.validate_location_visit("templanon").get("ok", false)), "Freigabe: nach satellite_recovery allein ist templanon anfliegbar")
	# Kampagnenauftrag angenommen (outpost_recovery, noch nicht erledigt): die drei Orte bleiben anfliegbar.
	_check(bool(_command("accept_job", {"job_id": "outpost_recovery"}).get("ok", false)) and String(owner.get_campaign_snapshot().jobs.outpost_recovery.status) == "accepted", "Freigabe: outpost_recovery ist angenommen (Fixture)")
	for id: String in PLACES:
		_check(bool(owner.validate_location_visit(id).get("ok", false)), "Freigabe %s: auch mit angenommenem Kampagnenauftrag anfliegbar" % id)
	_finish_job("outpost_recovery")
	for id: String in PLACES:
		_check(bool(owner.validate_location_visit(id).get("ok", false)), "Freigabe %s: nach outpost_recovery weiter anfliegbar" % id)
	# Freigabe 25.11.2026: der Relaisgrat hat jetzt einen freien Besuch (relay_ridge_visit) und ist ohne Auftrag anfliegbar; mit Handel am Marker spawn_bravo.
	var fresh: RefCounted = CAMPAIGN.new()
	fresh.configure()
	_check(bool(fresh.validate_location_visit("relay_ridge").get("ok", false)) and String(fresh.free_visit_scenario_id("relay_ridge")) == "relay_ridge_visit", "Freigabe: relay_ridge ist direkt nach Spielstart anfliegbar (freier Besuch relay_ridge_visit)")
	var relay_trade: Dictionary = fresh.trade_marker_entry("relay_ridge")
	_check(String(relay_trade.get("service_marker_id", "")) == "spawn_bravo" and is_equal_approx(float(relay_trade.get("service_radius_world", 0.0)), 256.0), "Freigabe: relay_ridge hat im freien Besuch den Haendler-Marker spawn_bravo (Radius 256) (%s)" % str(relay_trade))
	_check(fresh.trade_marker_entry("satellite_crash").is_empty() and fresh.trade_marker_entry("distress_orbit").is_empty() and not fresh.trade_marker_entry("templanon").is_empty(), "Freigabe: Handels-Marker nur fuer die drei Posten und den Relaisgrat")
	var chain: Array = []
	var availability: Dictionary = fresh.get_job_availability(true)
	for job_id: String in availability:
		if bool(Dictionary(availability[job_id]).get("can_accept", false)): chain.append(job_id)
	_check(chain == ["satellite_recovery"], "Kette unveraendert: am Start ist nur satellite_recovery annehmbar (%s)" % str(chain))
	_check(String(fresh.validate_location_visit("distress_orbit").get("reason", "")) == "tutorial_locked", "Freigabe: distress_orbit bleibt gesperrt (kein Besuchsszenario, Orbit-Ort ohne Bodenkarte)")
	var relay_scenario := String(Dictionary(_json("res://data/singleplayer/locations.json").get("relay_ridge", {})).get("scenario_file_path", ""))
	_check(relay_scenario.ends_with("flak_silence.json") and String(Dictionary(fresh.get_campaign_snapshot().jobs).get("flak_silence", {}).get("scenario_id", "flak_silence")) == "flak_silence", "Freigabe: das Auftragsszenario flak_silence des Relaisgrats bleibt unveraendert")
	var free: RefCounted = CAMPAIGN.new()
	free.configure({}, {}, false)
	for id: String in PLACES:
		_check(bool(free.validate_location_visit(id).get("ok", false)), "Freies Spiel %s: ohne Reihenfolge-Zwang offen" % id)
	var free_relay: Dictionary = free.validate_location_visit("relay_ridge")
	_check(not bool(free_relay.get("ok", true)) and String(free_relay.get("reason", "")) == "tutorial_locked", "Freies Spiel: relay_ridge bleibt gesperrt, obwohl die drei kleinen Posten offen sind (%s)" % str(free_relay))

func _case_supply() -> void:
	var supply: RefCounted = SUPPLY.new()
	var configured: Dictionary = Dictionary(supply.configure([{"craft_id": "ship"}]))
	_check(bool(configured.get("ok", true)), "Versorgung: configure ok mit den neuen Strecken (%s)" % str(configured))
	var routes: Dictionary = Dictionary(supply.get_supply_snapshot().get("route_fuel_costs", {}))
	for id: String in PLACES:
		var want: Dictionary = PLACES[id]
		_check(is_equal_approx(float(routes.get("homebase>" + id, -1.0)), float(want.home)) and is_equal_approx(float(routes.get(id + ">homebase", -1.0)), float(want.home)), "Versorgung %s: Heimat<->Ort %s" % [id, str(want.home)])
		_check(is_equal_approx(float(routes.get("trade_outpost>" + id, -1.0)), float(want.trade)) and is_equal_approx(float(routes.get(id + ">trade_outpost", -1.0)), float(want.trade)), "Versorgung %s: Handelsposten<->Ort %s" % [id, str(want.trade)])
		_check(is_equal_approx(float(routes.get("satellite_crash>" + id, -1.0)), float(want.crash)) and is_equal_approx(float(routes.get(id + ">satellite_crash", -1.0)), float(want.crash)), "Versorgung %s: Absturzstelle<->Ort %s" % [id, str(want.crash)])
		_check(is_equal_approx(supply.get_leg_fuel_cost("homebase", id, "jump"), float(want.home) - 2.0) and is_equal_approx(supply.get_leg_fuel_cost(id, "homebase", "surface_exit"), 2.0), "Versorgung %s: Etappen Heimat<->Ort eingetragen" % id)

func _case_surface() -> void:
	var glut: Dictionary = {"id": "glut_1b", "kind": "moon"}
	var planet: Dictionary = {"id": "planet", "kind": "planet"}
	_check(SURFACE.contains(glut, "trade_outpost") and SURFACE.contains(glut, "muellers_farm"), "Landung: Muellers Farm und Handelsposten am Mond glut_1b")
	_check(SURFACE.contains(planet, "shady_lab") and SURFACE.contains(planet, "templanon") and SURFACE.contains(planet, "relay_ridge") and SURFACE.contains(planet, "fortified_outpost"), "Landung: Shady Lab, Templanon, Relaisgrat, Gesicherter Aussenposten am Planeten")


## Nachbesserung 1 (K1): Orte, die sich einen Orbit teilen. Wer aus einem Orbit auf EINEN Ort schliesst (SimulationRoot._location_at_orbit
## fuer Sprungkosten, SingleplayerRuntimeAdapter._location_for_orbit fuer Reichweite und Nottanker), muss ohne passende Vorwahl denselben Ort
## liefern wie VOR den neuen Orten (Stand 78910d8dd). Die Liste unten ist fest; die Vorwahl (selected_location_id) gilt weiter nur im eigenen Orbit.
func _case_orbit_resolution() -> void:
	var location_orbits: Dictionary = Dictionary(_json("res://data/singleplayer/star_system.json").get("location_orbits", {}))
	var before := {"moon_orbit": "homebase", "glut_1a_orbit": "satellite_crash", "glut_1b_orbit": "trade_outpost", "planet_orbit": "distress_orbit", "polisa_orbit": "polisa"}
	var distinct := {}
	for place in location_orbits: distinct[String(location_orbits[place])] = true
	_check(distinct.size() == before.size(), "Orbit-Aufloesung: die feste Liste deckt alle %d Orbits der Sternkarte ab" % distinct.size())
	var simulation = load("res://scripts/core/simulation_root.gd")
	var adapter = load("res://scripts/meta/singleplayer_runtime_adapter.gd")
	for orbit: String in before:
		var from_simulation := String(simulation.call("_location_at_orbit", location_orbits, orbit, ""))
		var from_adapter := String(adapter.call("_location_for_orbit", location_orbits, orbit, ""))
		_check(from_simulation == String(before[orbit]), "Orbit-Aufloesung %s ohne Vorwahl (Sprungkosten): %s, wie vor den neuen Orten (%s)" % [orbit, before[orbit], from_simulation])
		_check(from_adapter == String(before[orbit]), "Orbit-Aufloesung %s ohne Vorwahl (Reichweite, Nottanker): %s, wie vor den neuen Orten (%s)" % [orbit, before[orbit], from_adapter])
	# Der Spielweg: Sprung Absturzstelle -> Orbit des Handelspostens, ohne Vorwahl (die Sternkarte bietet fremde Orbits gar nicht zur Wahl an).
	var supply: RefCounted = SUPPLY.new()
	supply.configure([{"craft_id": "ship"}])
	var origin := String(simulation.call("_location_at_orbit", location_orbits, "glut_1a_orbit", ""))
	var target := String(simulation.call("_location_at_orbit", location_orbits, "glut_1b_orbit", ""))
	_check(origin == "satellite_crash" and target == "trade_outpost", "Sprung Absturzstelle -> Handelsposten ohne Vorwahl: Ziel ist trade_outpost (%s > %s)" % [origin, target])
	_check(is_equal_approx(supply.get_leg_fuel_cost(origin, target, "jump"), 7.0), "Sprung Absturzstelle -> Handelsposten ohne Vorwahl kostet 7 (Wert vor den neuen Orten, %s)" % str(supply.get_leg_fuel_cost(origin, target, "jump")))
	# Die Vorwahl im eigenen Orbit gilt weiter: die Farm ist ueber ihren Weg erreichbar und kostet, was die Daten sagen.
	var chosen := String(simulation.call("_location_at_orbit", location_orbits, "glut_1b_orbit", "muellers_farm"))
	_check(chosen == "muellers_farm", "Vorwahl Muellers Farm im Orbit glut_1b_orbit: Ziel ist die Farm (%s)" % chosen)
	_check(String(adapter.call("_location_for_orbit", location_orbits, "glut_1b_orbit", "muellers_farm")) == "muellers_farm", "Vorwahl Muellers Farm (Adapter): Ziel ist die Farm")
	_check(is_equal_approx(supply.get_leg_fuel_cost("satellite_crash", chosen, "jump"), 8.0) and is_equal_approx(supply.get_leg_fuel_cost("homebase", chosen, "jump"), 7.0), "Muellers Farm ueber die Vorwahl: Sprung ab Absturzstelle 8, ab Heimat 7 (Daten)")
	_check(String(simulation.call("_location_at_orbit", location_orbits, "glut_1b_orbit", "shady_lab")) == "trade_outpost", "Vorwahl eines Ortes aus einem anderen Orbit (shady_lab) aendert den Orbit glut_1b_orbit nicht")
	for place: String in ["shady_lab", "templanon"]:
		_check(String(simulation.call("_location_at_orbit", location_orbits, "planet_orbit", place)) == place and String(adapter.call("_location_for_orbit", location_orbits, "planet_orbit", place)) == place, "Vorwahl %s im Planetenorbit: Ziel ist der gewaehlte Ort" % place)
	# Nachbesserung 2 (W1): Kurzweg Farm <-> Handelsposten (derselbe Orbit) kostet 3 (Ortsabflug 2 + Anflug 1), ohne Sprungetappe.
	var runtime: Object = adapter.new()
	var travel := {"phase": "surface", "location_id": "muellers_farm", "orbit_id": "", "location_orbits": location_orbits}
	var short_legs: Array = runtime.call("_remaining_outbound_legs", travel, "trade_outpost")
	var short_cost := 0.0
	for entry: Dictionary in short_legs: short_cost += supply.get_leg_fuel_cost(String(entry.origin), String(entry.destination), String(entry.leg))
	_check(short_legs.size() == 2 and String(short_legs[0].leg) == "surface_exit" and String(short_legs[1].leg) == "approach" and is_equal_approx(short_cost, 3.0), "Kurzweg Farm -> Handelsposten (derselbe Orbit): Reichweite verlangt 3 ohne Sprung (%d Etappen, %s)" % [short_legs.size(), str(short_cost)])
	var long_legs: Array = runtime.call("_remaining_outbound_legs", {"phase": "surface", "location_id": "muellers_farm", "orbit_id": "", "location_orbits": location_orbits}, "satellite_crash")
	_check(long_legs.size() == 3 and String(long_legs[1].leg) == "jump", "Weg Farm -> Absturzstelle (anderer Orbit) behaelt die Sprungetappe")
	# Planetenorbit (shady_lab, templanon, relay_ridge, Gesicherter Aussenposten teilen einen Orbit): auch hier kein Sprung zwischen Orten.
	for pair: Array in [["shady_lab", "templanon"], ["templanon", "shady_lab"]]:
		var pair_legs: Array = runtime.call("_remaining_outbound_legs", {"phase": "surface", "location_id": pair[0], "orbit_id": "", "location_orbits": location_orbits}, pair[1])
		var pair_names: Array = []
		for pair_leg: Dictionary in pair_legs: pair_names.append(String(pair_leg.leg))
		_check(pair_names == ["surface_exit", "approach"], "Kurzweg %s -> %s (Planetenorbit): Reichweite ohne Sprung (%s)" % [pair[0], pair[1], str(pair_names)])
	(runtime as Node).free()
