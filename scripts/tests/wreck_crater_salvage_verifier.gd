extends SceneTree
## Kapitel 2 / Aufgabe 1: Auftrag "Wrack am Krater bergen" (wreck_crater_salvage). Rechnerisch, nur Besitzer und Dateien.
## Szenario laedt und validiert, Marker und Benutzen-Stellen, Schrittfolge und Sperren, Beute, Gegner und Wellen,
## Kampagneneintrag, Briefing, Auftraggeber, Schrott im Schiff ueberlebt Speichern und Laden.
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const SCENARIO = preload("res://scripts/mission/mission_scenario_data.gd")
const GATES = preload("res://scripts/mission/mission_scenario_runtime_gates.gd")
const CAMPAIGN = preload("res://scripts/core/singleplayer_campaign_state.gd")
const JOBS = preload("res://scripts/mission/singleplayer_job_contract.gd")
const INVENTORY = preload("res://scripts/mission/inventory_transfer_contract.gd")
const JOB_ID := "wreck_crater_salvage"
const PATH := "res://data/mission_scenarios/wreck_crater_salvage.json"
const STEPS := ["salvage_wreck", "clear_looters", "recover_wreck_crate", "return_to_ship"]
const CRAFT := "wreck_craft"
var passed := 0
var failed := 0

func _check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print(("PASS " if value else "FAIL ") + label)

func _init() -> void: call_deferred("_run")

func _gate(entries: Array, step_id: String) -> Dictionary:
	for entry: Dictionary in entries:
		if String(entry.get("step_id", "")) == step_id: return entry
	return {}

func _fresh(scenario) -> RefCounted:
	var gates = GATES.new()
	gates.configure_from_slice(scenario.vertical_slice)
	return gates

func _run() -> void:
	if not FileAccess.file_exists(PATH):
		_check(false, "Szenariodatei vorhanden: " + PATH)
		_finish()
		return
	var scenario = SCENARIO.load_from_file(PATH)
	var valid: Dictionary = scenario.validate()
	_check(bool(valid.get("valid", false)), "1: Szenario laedt und validiert (%s)" % str(valid.get("errors", [])))
	_check(String(scenario.scenario_id) == JOB_ID and String(scenario.map_file_path) == "res://maps/satellite_crash_site.json", "1: Kennung und Karte")
	_check(String(scenario.display_name) == "Wrack am Krater bergen" and String(scenario.briefing.get("title", "")) == "Wrack am Krater bergen", "1: Anzeigename und Briefing-Titel")
	_check(String(scenario.objective.get("marker_id", "")) == "objective_point" and is_equal_approx(float(scenario.objective.get("capture_radius", 0.0)), 80.0), "1: Ziel objective_point, Radius 80")
	_check(is_equal_approx(float(scenario.time_limit_seconds), 2400.0) and int(scenario.mission_slot_count_override) == 4 and String(scenario.win_condition) == "objective_capture", "1: Rahmen (Zeitlimit, Plaetze, Siegbedingung)")
	_check(bool(scenario.vertical_slice.get("finite_enemy_roster", false)) and scenario.patrol_bindings.size() == 1 and String(Dictionary(scenario.patrol_bindings[0]).get("patrol_path_id", "")) == "wreck_looter_route" and String(Dictionary(scenario.patrol_bindings[0]).get("target_id", "")) == "spawn_bravo", "1: endlicher Gegnerbestand, ein Patrouillenweg wreck_looter_route fuer spawn_bravo")
	var map = MAP.load_from_file("res://maps/satellite_crash_site.json")
	var points: Array = scenario.vertical_slice.get("interaction_points", [])
	var seen: Dictionary = {}
	var all_ok: bool = points.size() == 3
	for point: Dictionary in points:
		var marker := String(point.get("marker_id", ""))
		all_ok = all_ok and String(point.get("interaction_id", "")) == marker and not seen.has(marker) and map.get_marker_ids().has(marker)
		all_ok = all_ok and String(point.get("interaction_type", "")) == "computer" and String(point.get("required_order", "")) == "take" and is_equal_approx(float(point.get("radius_world", 0.0)), 96.0) and String(point.get("required_team", "")) == "team_alpha"
		all_ok = all_ok and String(point.get("gate_id", "")) == String(point.get("step_id", "")) and String(point.get("required_state", "")) == String(point.get("step_id", "")) + "_done"
		seen[marker] = true
	_check(all_ok, "2: drei Benutzen-Stellen, interaction_id == marker_id, paarweise verschieden, Marker auf der Karte, Rahmenwerte")
	_check(seen.has("satellite_data") and seen.has("objective_point") and seen.has("ship_return"), "2: benutzte Marker satellite_data, objective_point, ship_return")
	var empty: Dictionary = _fresh(scenario).update({"enemy_group_fit_counts": {"looters_smg": 2, "looters_pistol": 2}})
	_check(Array(empty.completed_step_ids).is_empty() and not bool(empty.all_gates_complete), "3: leerer Zustand, keine Schritte fertig")
	_check(String(_gate(empty.gates, "recover_wreck_crate").get("blocked_by_step_id", "")) == "clear_looters", "3: recover_wreck_crate blockiert durch clear_looters")
	var counts_cases := [["beide Gruppen leben", {"looters_smg": 2, "looters_pistol": 2}, false], ["Maschinenpistolen 0, Pistolen leben", {"looters_smg": 0, "looters_pistol": 2}, false], ["nur Maschinenpistolen gezaehlt", {"looters_smg": 0}, false], ["nur Pistolen 0, Maschinenpistolen leben", {"looters_smg": 2, "looters_pistol": 0}, false], ["beide 0", {"looters_smg": 0, "looters_pistol": 0}, true]]
	for case in counts_cases:
		var done: Dictionary = _fresh(scenario).update({"step_states": {"salvage_wreck": "salvage_wreck_done"}, "enemy_group_fit_counts": case[1]})
		_check(Array(done.completed_step_ids).has("clear_looters") == bool(case[2]), "4: clear_looters bei '%s' %s" % [case[0], "fertig" if bool(case[2]) else "offen"])
	var before_salvage: Dictionary = _fresh(scenario).update({"enemy_group_fit_counts": {"looters_smg": 0, "looters_pistol": 0}})
	_check(not Array(before_salvage.completed_step_ids).has("clear_looters"), "4: ohne geborgenen Schrott ist clear_looters nicht fertig")
	var states := {"salvage_wreck": "salvage_wreck_done", "clear_looters": "looters_cleared", "recover_wreck_crate": "recover_wreck_crate_done", "return_to_ship": "return_to_ship_done"}
	var all_done: Dictionary = _fresh(scenario).update({"step_states": states, "enemy_group_fit_counts": {"looters_smg": 0, "looters_pistol": 0}})
	_check(bool(all_done.all_gates_complete), "5: alle Schritte fertig, alle Schranken offen")
	var flow_ids: Array = []
	for step: Dictionary in scenario.vertical_slice.get("flow_steps", []): flow_ids.append(String(step.step_id))
	var jobs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/jobs.json"))
	_check(jobs.has(JOB_ID) and flow_ids == STEPS and Array(jobs.get(JOB_ID, {}).get("required_step_ids", [])) == STEPS, "5: Schrittfolge der flow_steps == required_step_ids aus jobs.json (%s)" % str(flow_ids))
	var salvage_grants: Array = scenario.get_interaction_grants("satellite_data")
	_check(salvage_grants.size() == 1 and String(salvage_grants[0].item_id) == "salvage" and int(salvage_grants[0].quantity) == 6, "6: satellite_data bringt 6 Schrott")
	var crate_grants: Array = scenario.get_interaction_grants("objective_point")
	_check(crate_grants.size() == 2 and String(crate_grants[0].item_id) == "salvage" and int(crate_grants[0].quantity) == 2 and String(crate_grants[1].item_id) == "armor_medium" and int(crate_grants[1].quantity) == 1, "6: objective_point bringt 2 Schrott und 1 mittlere Ruestung")
	_check(scenario.get_interaction_grants("ship_return").is_empty(), "6: ship_return bringt nichts")
	var weapons: Array = []
	var accuracy: Array = []
	var ids: Array = []
	for group: Dictionary in scenario.enemy_groups:
		_check(String(group.get("team_id", "")) == "team_bravo" and String(group.get("spawn_marker_id", "")) == "spawn_bravo" and map.get_marker_ids().has("spawn_bravo"), "7: Gruppe %s: team_bravo, Marker spawn_bravo vorhanden" % str(group.get("group_id", "")))
		_check(String(Dictionary(group.get("tactics", {})).get("profile_id", "")) == "patrol_probe" and String(Dictionary(group.get("tactics", {})).get("movement_posture_policy", "")) == "travel_until_threat", "7: Gruppe %s: Taktik Anruecken" % str(group.get("group_id", "")))
		for id in Array(group.get("enemy_ids", [])):
			ids.append(String(id))
			weapons.append(String(Dictionary(group.get("tactics", {})).get("weapon_id", "")))
			accuracy.append(snappedf(float(group.get("skill_accuracy", -1.0)), 0.001))
	_check(ids == ["wreck_looter_01", "wreck_looter_02", "wreck_looter_03", "wreck_looter_04"] and weapons == ["smg", "smg", "pistol", "pistol"] and accuracy == [0.15, 0.15, 0.12, 0.12], "7: vier Gegner, Waffen smg,smg,pistol,pistol, Genauigkeit 0.15/0.12 (%s %s)" % [str(weapons), str(accuracy)])
	var waves: Dictionary = scenario.wave_config
	_check(int(waves.get("wave_count", 0)) == 2 and int(waves.get("units_per_wave", 0)) == 2 and is_equal_approx(float(waves.get("first_wave_delay_seconds", 0.0)), 75.0) and is_equal_approx(float(waves.get("wave_delay_seconds", 0.0)), 60.0), "7: Wellen 2 x 2, erste bei 75 s, weitere nach 60 s")
	var owner: RefCounted = CAMPAIGN.new()
	_check(bool(owner.configure().get("ok", false)), "8: Kampagnenbesitzer konfiguriert")
	var job: Dictionary = Dictionary(owner.get_campaign_snapshot().get("jobs", {})).get(JOB_ID, {})
	_check(String(job.get("location_id", "")) == "satellite_crash" and String(job.get("prerequisite_job_id", "")) == "buccaneer_rescue" and not bool(job.get("home_upload", true)), "8: Ort satellite_crash, Vorgaenger buccaneer_rescue, keine Heim-Hochladung")
	_check(int(Dictionary(job.get("reward", {})).get("credits", -1)) == 200 and String(Dictionary(job.get("reward", {})).get("blueprint_id", "x")).is_empty(), "8: Belohnung genau 200 Credits ohne Bauplan")
	_check(not String(job.get("locked_hint", "")).is_empty(), "8: locked_hint gesetzt")
	_check(String(job.get("status", "")) == "offered", "8: Status offered")
	var briefing: Dictionary = JOBS.get_briefing(JOB_ID)
	_check(Array(briefing.get("objectives", [])).size() == 3, "8: Briefing mit drei Zielen vorhanden")
	_check(not JOBS.get_issuer_for_job(JOB_ID).is_empty(), "8: Auftraggeber vorhanden")
	var on_map := 0
	var locations: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/locations.json"))
	for id in jobs:
		var location: Dictionary = Dictionary(locations.get(String(Dictionary(jobs[id]).get("location_id", "")), {}))
		if String(location.get("map_file_path", "")) == "res://maps/satellite_crash_site.json": on_map += 1
	_check(on_map <= 4, "8: Auftraege auf satellite_crash_site.json: %d (hoechstens 4)" % on_map)
	_case_patrol_waypoints_clear(map)
	_case_cargo_roundtrip()
	_finish()

## 10: Kein Punkt des Patrouillenwegs liegt auf einer unbegehbaren oder sichtsperrenden Zelle (Fels, Wrackteil).
func _case_patrol_waypoints_clear(map) -> void:
	var registry = TERRAIN_REGISTRY.new()
	registry.configure_iso_grid(map.get_grid_origin(), 64, 32, map.get_grid_topology())
	for tile in map.get_tiles(): registry.register_tile(tile)
	var path: Array = map.get_patrol_path("wreck_looter_route")
	var bad: Array = []
	for waypoint in path:
		var cell: Vector2i = registry.world_to_grid(Vector2(waypoint))
		if not registry.is_walkable(cell) or registry.blocks_los_at_grid(cell): bad.append(cell)
	print("INFO Wegpunkte (Zellen): ", path.map(func(waypoint): return registry.world_to_grid(Vector2(waypoint))))
	_check(path.size() >= 2 and bad.is_empty(), "10: alle %d Wegpunkte von wreck_looter_route sind begehbar und nicht sichtsperrend (schlecht: %s)" % [path.size(), str(bad)])
	registry.free()

func _supply_for_craft() -> RefCounted:
	var supply = load("res://scripts/core/singleplayer_supply_state.gd").new()
	supply.configure([{"craft_id": CRAFT}])
	supply.configure_inventory([], [CRAFT], true)
	return supply

func _count(supply: RefCounted, item: String) -> int:
	return int(Dictionary(Dictionary(Dictionary(supply.get_supply_snapshot().inventory).get("craft:" + CRAFT, {})).get("items", {})).get(item, 0))

func _case_cargo_roundtrip() -> void:
	_check(INVENTORY.known("salvage") and INVENTORY.known("armor_medium"), "9: salvage und armor_medium sind bekannte Waren")
	var supply = _supply_for_craft()
	supply.configure_start_inventory("campaign")
	var before_salvage := _count(supply, "salvage")
	var booked := 0
	for piece in range(8):
		if bool(supply.apply_command({"contract_category": "singleplayer_supply", "operation": "campaign_cargo", "payload": {"container_id": "craft:" + CRAFT, "item_id": "salvage", "amount": 1}, "request_id": "wreck-salvage-%d" % piece}, {"campaign_authorized": true}).get("ok", false)): booked += 1
	var armor: Dictionary = supply.apply_command({"contract_category": "singleplayer_supply", "operation": "campaign_cargo", "payload": {"container_id": "craft:" + CRAFT, "item_id": "armor_medium", "amount": 1}, "request_id": "wreck-armor"}, {"campaign_authorized": true})
	_check(booked == 8 and bool(armor.get("ok", false)), "9: 8 Schrott und 1 mittlere Ruestung passen in den Frachtraum (gebucht %d, %s)" % [booked, str(armor.get("reason", "ok"))])
	_check(_count(supply, "salvage") == before_salvage + booked, "9: Schrott liegt im Schiff")
	var armor_count := _count(supply, "armor_medium")
	var loaded = _supply_for_craft()
	var restored: Dictionary = loaded.restore_state(supply.export_state())
	_check(bool(restored.get("ok", false)), "9: Stand mit Schrott im Schiff laedt (%s)" % str(restored.get("reason", "ok")))
	_check(_count(loaded, "salvage") == before_salvage + booked and _count(loaded, "armor_medium") == armor_count, "9: nach Speichern und Laden bleiben Schrott und Ruestung im Schiff")

func _finish() -> void:
	print("WRECK_CRATER_SALVAGE passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)
