extends SceneTree
## Handel-Nachbesserung W2, Schritt 1 (Pruefung ohne Flug): Gibt es an der Absturzstelle innerhalb von 256 Einheiten um den Haendler (Marker trade_service)
## ein Feld, auf dem ein Schiff WIRKLICH landen darf? Es gilt die echte Landepruefung des Spiels: field_landing_contract.validate (Zelle) und die
## Rumpffaechenpruefung (_check_ground_ship_landing_site: ganze Rumpffaeche frei, erreichbarer Ausstieg), wie _hull_fits in
## playtest_20261109_campaign_landed_craft_verifier. Geprueft werden Entermesser (cutlass) und, wenn es ein kleineres Schiff gibt, buccaneer.
## Ausgabe: PROBE-Zeilen mit Zahl der gueltigen Felder und dem naechsten Feld zum Haendler; Abschlusszeile SAT_LANDING_PROBE ...
const MISSION = preload("res://scenes/tests/mission_reactivity_test.tscn")
const MAP_PATH := "res://maps/satellite_crash_site.json"
const SCENARIO := "res://data/mission_scenarios/satellite_crash_visit.json"
const RADIUS := 256.0
var _found := {}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var mission: Node = MISSION.instantiate()
	var setup: Node = mission.get_node("MissionSetup")
	setup.set("map_file_path", MAP_PATH)
	setup.set("scenario_file_path", SCENARIO)
	setup.set("selected_team_unit_ids", PackedStringArray(["unit_alpha", "unit_bravo"]))
	setup.set("selected_team_fireteam_ids", PackedStringArray(["ft1", "ft2"]))
	setup.set("defer_friendly_runtime_activation", true)
	root.add_child(mission)
	await process_frame
	var controller: Node = mission.get_node("TacticalController")
	controller.set_process(false)
	print("PROBE: hex_owner_required=", controller.call("_requires_hex_deployment_owner"))
	var map = load("res://scripts/terrain/terrain_map_data.gd").load_from_file(MAP_PATH)
	var trader: Vector2 = map.get_marker_position("trade_service")
	var pad: Vector2 = map.get_marker_position("spawn_alpha")
	print("PROBE: trade_service=", trader, " spawn_alpha=", pad, " distance=", trader.distance_to(pad))
	var shown := 0
	for tile in map.get_tiles():
		if tile.world_position.distance_to(trader) <= 130.0 and shown < 40:
			shown += 1
			var props := {}
			for p in tile.get_property_list():
				if int(p.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE: props[p.name] = tile.get(p.name)
			print("TILE: offset=", tile.world_position - trader, " ", props)
	for model in ["cutlass", "buccaneer"]:
		_scan(controller, map, trader, model)
	mission.queue_free()
	await process_frame
	print("SAT_LANDING_PROBE cutlass_cells=%d buccaneer_cells=%d" % [int(_found.get("cutlass", 0)), int(_found.get("buccaneer", 0))])
	quit(0)

func _hull_fits(controller: Node, position: Vector2, model: String) -> bool:
	var card: Dictionary = {"craft_id": "craft_a", "model_id": model, "display_name": model, "payload_source": "homebase_direct", "state": "waiting", "progress": 0.0, "passenger_count": 0, "embarked_unit_ids": [], "boarded_fireteam_ids": [], "has_lz_position": true, "lz_position": position, "approach_angle": "NW"}
	var projection: Dictionary = controller.call("_read_ground_ship_landing_projection", card, position, "NW")
	var profile: Dictionary = load("res://scripts/mission/polisa_ground_body_profile.gd").from_projection(card, projection)
	if not bool(profile.get("ok", false)): return false
	return bool(controller.call("_check_ground_ship_landing_site", card, position, profile.profile).get("ok", false))

func _scan(controller: Node, map, trader: Vector2, model: String) -> void:
	var registry: Node = controller.call("_get_terrain_registry")
	var contract = load("res://scripts/mission/field_landing_contract.gd")
	var in_range := 0
	var cell_ok := 0
	var hull_ok := 0
	var best: Vector2 = Vector2.INF
	var best_wide: Vector2 = Vector2.INF
	for tile in map.get_tiles():
		var d: float = tile.world_position.distance_to(trader)
		if d > 1024.0: continue
		var cell: bool = bool(contract.validate(registry, tile.grid_position, []).ok)
		var hull: bool = cell and _hull_fits(controller, tile.world_position, model)
		if hull and (not best_wide.is_finite() or d < best_wide.distance_to(trader)): best_wide = tile.world_position
		if d > RADIUS: continue
		in_range += 1
		if cell: cell_ok += 1
		if hull:
			hull_ok += 1
			_found[model] = int(_found.get(model, 0)) + 1
			if model == "cutlass": print("PROBE: cutlass valid cell %s distance=%s offset=%s" % [str(tile.world_position), str(snappedf(d, 0.1)), str(tile.world_position - trader)])
			if not best.is_finite() or d < best.distance_to(trader): best = tile.world_position
	print("PROBE: %s tiles_in_256=%d cell_ok=%d hull_ok=%d nearest_valid=%s (%s) nearest_valid_within_1024=%s (%s)" % [model, in_range, cell_ok, hull_ok, str(best), str(snappedf(best.distance_to(trader), 0.1)) if best.is_finite() else "-", str(best_wide), str(snappedf(best_wide.distance_to(trader), 0.1)) if best_wide.is_finite() else "-"])
