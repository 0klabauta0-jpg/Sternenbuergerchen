extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")

const MAP_PATH: String = "res://maps/fireteam_command_drill_24x24.json"
const SCENARIO_PATH: String = "res://data/mission_scenarios/fireteam_command_drill_24x24.json"
const TASK_PATH: String = "res://docs/tasks/TASK_441_fireteam_map_tool_drill_rebuild.md"
const REPORT_PATH: String = "res://docs/reports/fireteam_map_tool_drill_rebuild_status.html"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_441 Fireteam Map Tool Drill Rebuild ===")
	_test_drill_map_data_stays_authorable()
	await _test_map_editor_loads_drill_map_and_all_patrol_routes()
	_test_docs_capture_task_and_behavior_status()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_drill_map_data_stays_authorable() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	_assert(map_data != null, "Drill map loads through TerrainMapData")
	if map_data == null:
		return
	_assert(Vector2i(map_data.call("get_grid_size")) == Vector2i(24, 24), "Drill map remains the 24x24 playtest fixture")
	_assert(int(map_data.call("get_mission_slot_count")) == 4, "Drill map keeps four mission slots")
	_assert(_all_tiles_flat_ground_height(map_data), "Map-tool rebuild keeps ground tiles flat unless a later height task changes them")
	_assert(_all_bushes_are_object_layer_cover(map_data), "Bushes are object-layer cover on ground tiles, not replacement terrain")
	var patrol_paths: Dictionary = Dictionary(map_data.call("get_patrol_paths"))
	for route_id in ["enemy_drill_watch_route", "enemy_drill_echo_route", "enemy_drill_foxtrot_route", "enemy_drill_golf_route"]:
		_assert(Array(patrol_paths.get(route_id, [])).size() >= 3, "Drill map exposes patrol route %s" % route_id)
	var scenario = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", SCENARIO_PATH)
	_assert(scenario != null, "Drill scenario loads through MissionScenarioData")
	if scenario != null:
		var validation: Dictionary = Dictionary(scenario.call("validate"))
		_assert(bool(validation.get("valid", false)), "Drill scenario validates against current map data")
		_assert(PackedStringArray(scenario.call("get_enemy_ids")).size() == 4, "Scenario still has four enemy NPC ids")


func _test_map_editor_loads_drill_map_and_all_patrol_routes() -> void:
	var editor := MAP_EDITOR_SCENE.instantiate()
	editor.set("map_file_path", MAP_PATH)
	root.add_child(editor)
	await _wait_frames(36)
	_assert(bool(editor.call("load_mission_scenario_for_editor", SCENARIO_PATH)), "MapEditor loads the drill scenario and referenced map")
	await _wait_frames(12)
	_assert(bool(editor.call("set_authoring_tool", "patrol")), "MapEditor can switch into patrol authoring for the drill fixture")
	_assert(bool(editor.call("set_patrol_authoring_reference", "enemy_foxtrot")), "MapEditor can select the third drill enemy as a patrol reference")
	await _wait_frames(8)

	var reference_ids: PackedStringArray = PackedStringArray(editor.call("get_patrol_authoring_reference_ids"))
	for reference_id in ["enemy_delta", "enemy_echo", "enemy_foxtrot", "enemy_golf"]:
		_assert(reference_ids.has(reference_id), "Patrol selector contains %s from scenario enemy ids" % reference_id)
	_assert(reference_ids.has("enemy_drill_foxtrot_route"), "Patrol selector also exposes concrete route ids for direct map editing")

	var snapshot: Dictionary = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	var validation: Dictionary = Dictionary(snapshot.get("validation", {}))
	var sections: Dictionary = Dictionary(validation.get("sections", {}))
	var map_section: Dictionary = Dictionary(sections.get("map", {}))
	var scenario_section: Dictionary = Dictionary(sections.get("scenario", {}))
	var patrol_section: Dictionary = Dictionary(sections.get("patrols", {}))
	var patrol_tool: Dictionary = Dictionary(snapshot.get("patrol_tool", {}))
	var preview: Dictionary = Dictionary(snapshot.get("patrol_route_preview", {}))
	_assert(bool(validation.get("valid", false)), "MapEditor authoring validation is green for the rebuilt drill map")
	_assert(Vector2i(map_section.get("grid_size", Vector2i.ZERO)) == Vector2i(24, 24), "MapEditor sees the 24x24 drill grid")
	_assert(int(scenario_section.get("enemy_count", 0)) == 4, "MapEditor scenario panel sees four enemy ids")
	_assert(int(patrol_section.get("path_count", 0)) >= 4, "MapEditor authoring validation sees all drill patrol paths")
	_assert(String(patrol_tool.get("spawn_id", "")) == "enemy_foxtrot", "Patrol tool keeps enemy_foxtrot as the selected authoring reference")
	_assert(int(patrol_tool.get("waypoint_count", 0)) >= 3, "Patrol tool resolves enemy_foxtrot to its bound route for waypoint editing")
	_assert(bool(preview.get("active", false)), "Patrol preview is active for the selected third enemy")
	_assert(String(preview.get("patrol_path_id", "")) == "enemy_drill_foxtrot_route", "Patrol preview resolves target id to the correct route id")
	_assert(int(preview.get("waypoint_count", 0)) >= 3, "Patrol preview has visible waypoints")

	editor.queue_free()
	await _wait_frames(3)


func _test_docs_capture_task_and_behavior_status() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("TASK_441 - Fireteam Map Tool Drill Rebuild"), "TASK_441 task file exists")
	for token in ["Engage", "Take", "Defend", "staerker kontrolliert"]:
		_assert(report_text.contains(token), "Map-tool report documents %s status" % token)
	_assert(status_text.contains("TASK_441 - Fireteam Map Tool Drill Rebuild"), "Implementation status documents TASK_441")
	_assert(roadmap_text.contains("TASK_441 - Fireteam Map Tool Drill Rebuild"), "Roadmap lists TASK_441")


func _all_tiles_flat_ground_height(map_data) -> bool:
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data == null:
			continue
		if int(tile_data.height_level) != 0:
			return false
		if String(tile_data.edge_type) != "none":
			return false
	return true


func _all_bushes_are_object_layer_cover(map_data) -> bool:
	var bush_count: int = 0
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data == null or String(tile_data.object_type_id) != "nature_bush_cover":
			continue
		bush_count += 1
		if String(tile_data.type_id) != "ground_flat":
			return false
		if int(tile_data.cover_value) < 20:
			return false
		if not bool(tile_data.walkable):
			return false
	return bush_count >= 6


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _wait_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
