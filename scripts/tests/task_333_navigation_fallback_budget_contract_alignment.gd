extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_333_navigation_fallback_budget_contract_alignment.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/navigation_fallback_budget_contract_alignment.md"
const CONTRACT_PATH: String = "res://data/performance_budget_contract.json"
const SIMULATION_ROOT_PATH: String = "res://scripts/core/simulation_root.gd"
const SCENE_ROOT_PATH: String = "res://scenes"

const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_333 Navigation Fallback Budget Contract Alignment ===")
	_test_docs_status_and_report()
	_test_budget_contract_matches_export_defaults()
	_test_static_fallback_boundary()
	_test_bad_target_fallback_uses_component_diagnostic()
	_test_large_component_fallback_warns_without_multi_path_spike()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_docs_status_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "TASK_333 task file marks implemented")
	_assert(not task_text.contains("- [ ]"), "TASK_333 checklist is complete")
	_assert(status_text.contains("### TASK_333 - Navigation Fallback Budget Contract Alignment") and status_text.contains("- Status: implementiert"), "Implementation status marks TASK_333 implemented")
	_assert(roadmap_text.contains("TASK_333 - Navigation Fallback Budget Contract Alignment (implementiert"), "Roadmap marks TASK_333 implemented")
	for token in ["Fallback-Diagnose", "Budget-Contract", "Export-Default", "keine Terrain-Semantik"]:
		_assert(report_text.to_lower().contains(token.to_lower()), "Report documents %s" % token)


func _test_budget_contract_matches_export_defaults() -> void:
	var contract: Dictionary = _read_json(CONTRACT_PATH)
	var navigation_budget: Dictionary = Dictionary(Dictionary(contract.get("project_budget", {})).get("navigation", {}))
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	_assert(int(navigation_budget.get("max_path_query_budget_per_tick", -1)) == int(simulation_root.navigation_max_new_path_queries_per_tick), "Navigation export default matches contract query budget")
	_assert(int(navigation_budget.get("max_fallback_path_attempts_per_request", -1)) == int(simulation_root.navigation_fallback_max_path_attempts_per_request), "Fallback path-attempt default matches contract")
	_assert(int(navigation_budget.get("max_fallback_candidates_per_request", -1)) == int(simulation_root.navigation_fallback_max_candidates_per_request), "Fallback candidate cap default matches contract")
	_assert(int(navigation_budget.get("max_fallback_candidate_warning_threshold", -1)) == int(simulation_root.navigation_fallback_candidate_warning_threshold), "Fallback candidate warning threshold matches contract")
	_assert(bool(navigation_budget.get("require_fallback_diagnostics", false)), "Budget contract requires fallback diagnostics")
	simulation_root.free()

	var override_files: Array = _find_scene_navigation_budget_overrides(SCENE_ROOT_PATH)
	_assert(override_files.is_empty(), "Scenes do not silently override navigation query budget defaults")


func _test_static_fallback_boundary() -> void:
	var simulation_text: String = _read_text(SIMULATION_ROOT_PATH)
	_assert(simulation_text.contains("NAVIGATION_DEFAULT_MAX_NEW_PATH_QUERIES_PER_TICK: int = 1"), "SimulationRoot declares the contract-aligned navigation default")
	_assert(simulation_text.contains("navigation_fallback_max_path_attempts_per_request"), "SimulationRoot exposes fallback path-attempt budget")
	_assert(simulation_text.contains("navigation_fallback_max_candidates_per_request"), "SimulationRoot exposes fallback candidate cap")
	_assert(simulation_text.contains("last_fallback_diagnostic"), "Navigation debug snapshot exposes last fallback diagnostic")
	_assert(not simulation_text.contains("_terrain_pathfinder.find_path(from_grid, candidate_grid"), "Fallback candidate search has no hidden per-candidate A* loop")


func _test_bad_target_fallback_uses_component_diagnostic() -> void:
	var grid_positions: Array = [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(4, 0),
	]
	var context: Dictionary = _make_simulation_context(grid_positions, {}, [])
	var simulation_root = context["simulation_root"]
	var registry = context["terrain_registry"]
	var unit = _add_unit(context, "task333_alpha", Vector2i(0, 0))
	simulation_root.call("set_navigation_debug_enabled", true)

	var target_position: Vector2 = registry.call("grid_to_world", Vector2i(4, 0))
	var cmd: Dictionary = _build_move_command(unit.get_unit_id(), target_position)
	var path: Array = simulation_root.call("_extract_or_build_path_world_points", cmd, unit, unit.global_position, target_position, registry)
	var snapshot: Dictionary = Dictionary(simulation_root.call("get_navigation_debug_snapshot"))
	var diagnostic: Dictionary = Dictionary(snapshot.get("last_fallback_diagnostic", {}))

	_assert(not path.is_empty(), "Disconnected target falls back to a reachable local component point")
	_assert(registry.call("world_to_grid", Vector2(path[-1])) == Vector2i(1, 0), "Fallback target is the nearest reachable component tile")
	_assert(int(snapshot.get("fallback_resolutions_this_tick", 0)) == 1, "Fallback resolution is counted")
	_assert(int(snapshot.get("fallback_path_attempts_this_tick", 0)) == 1, "Fallback performs only one budgeted path attempt")
	_assert(int(snapshot.get("path_queries_this_tick", 0)) <= 2, "Bad target pathing records primary plus one fallback query only")
	_assert(bool(diagnostic.get("used_hpa_component", false)), "Fallback diagnostic uses HPA component data")
	_assert(bool(diagnostic.get("reachability_verified", false)), "Fallback diagnostic marks component reachability verified")
	_assert(int(diagnostic.get("candidate_count", 0)) == 2, "Fallback diagnostic records component candidate count")
	_assert(_last_fallback_query_has_candidate_count(Array(snapshot.get("last_queries", [])), 2), "Fallback query record carries candidate count")
	_cleanup_context(context)


func _test_large_component_fallback_warns_without_multi_path_spike() -> void:
	var grid_positions: Array = _make_rect_positions(Vector2i(0, 0), Vector2i(11, 11))
	grid_positions.append(Vector2i(30, 0))
	var context: Dictionary = _make_simulation_context(grid_positions, {}, [])
	var simulation_root = context["simulation_root"]
	var registry = context["terrain_registry"]
	var unit = _add_unit(context, "task333_large_component", Vector2i(0, 0))
	simulation_root.call("set_navigation_debug_enabled", true)
	simulation_root.call("set_navigation_fallback_candidate_warning_threshold", 8)

	var target_position: Vector2 = registry.call("grid_to_world", Vector2i(30, 0))
	var cmd: Dictionary = _build_move_command(unit.get_unit_id(), target_position)
	var path: Array = simulation_root.call("_extract_or_build_path_world_points", cmd, unit, unit.global_position, target_position, registry)
	var snapshot: Dictionary = Dictionary(simulation_root.call("get_navigation_debug_snapshot"))
	var diagnostic: Dictionary = Dictionary(snapshot.get("last_fallback_diagnostic", {}))

	_assert(not path.is_empty(), "Large-component bad target still resolves to a reachable fallback")
	_assert(int(snapshot.get("fallback_path_attempts_this_tick", 0)) == 1, "Large-component fallback still performs one path attempt")
	_assert(int(snapshot.get("fallback_candidate_budget_exceeded_this_tick", 0)) == 1, "Large-component fallback surfaces a candidate budget warning")
	_assert(int(snapshot.get("fallback_candidate_cap_hits_this_tick", 0)) == 1, "Large-component fallback surfaces a candidate cap hit")
	_assert(bool(diagnostic.get("candidate_budget_exceeded", false)), "Fallback diagnostic marks candidate budget exceeded")
	_assert(String(diagnostic.get("warning", "")) == "fallback_candidate_cap_reached", "Fallback diagnostic names the candidate cap warning")
	_assert(int(diagnostic.get("candidate_count", 0)) <= int(diagnostic.get("candidate_limit", 0)), "Fallback diagnostic stays within the candidate cap")
	_assert(int(diagnostic.get("candidate_count", 0)) == int(diagnostic.get("candidate_limit", -1)), "Large component fills the candidate cap")
	_assert(bool(diagnostic.get("candidate_capped", false)), "Fallback diagnostic records candidate capping")
	_assert(float(diagnostic.get("selected_distance_to_desired", -1.0)) >= 0.0, "Fallback diagnostic records selected distance")
	_assert(int(snapshot.get("path_queries_this_tick", 0)) <= 2, "Large-component fallback has no hidden multi-query spike")
	print("TASK_333 fallback sample: %s" % JSON.stringify({
		"candidate_count": int(diagnostic.get("candidate_count", 0)),
		"candidate_limit": int(diagnostic.get("candidate_limit", 0)),
		"candidate_capped": bool(diagnostic.get("candidate_capped", false)),
		"path_attempts": int(snapshot.get("fallback_path_attempts_this_tick", 0)),
		"path_queries": int(snapshot.get("path_queries_this_tick", 0)),
		"warning": String(diagnostic.get("warning", "")),
	}))
	_cleanup_context(context)


func _make_simulation_context(grid_positions: Array, blocked_by_grid: Dictionary, units: Array) -> Dictionary:
	var scene = Node.new()
	root.add_child(scene)
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	scene.add_child(unit_registry)
	var terrain_registry = _make_registry(grid_positions, blocked_by_grid)
	terrain_registry.name = "TerrainRegistry"
	scene.add_child(terrain_registry)
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	simulation_root.terrain_registry_path = NodePath("../TerrainRegistry")
	scene.add_child(simulation_root)
	var context: Dictionary = {
		"scene": scene,
		"unit_registry": unit_registry,
		"terrain_registry": terrain_registry,
		"simulation_root": simulation_root,
		"units": {},
	}
	for unit_config in units:
		_add_unit(context, String(unit_config.get("unit_id", "")), Vector2i(unit_config.get("grid", Vector2i.ZERO)))
	return context


func _add_unit(context: Dictionary, unit_id: String, unit_grid: Vector2i):
	var scene = context["scene"]
	var unit_registry = context["unit_registry"]
	var terrain_registry = context["terrain_registry"]
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.team_id = "team_alpha"
	unit.fireteam_id = "blue"
	unit.global_position = terrain_registry.call("grid_to_world", unit_grid)
	scene.add_child(unit)
	unit_registry.call("register_unit", unit.get_unit_id(), unit)
	Dictionary(context["units"])[unit_id] = unit
	return unit


func _make_rect_positions(min_grid: Vector2i, max_grid: Vector2i) -> Array:
	var result: Array = []
	for x in range(min_grid.x, max_grid.x + 1):
		for y in range(min_grid.y, max_grid.y + 1):
			result.append(Vector2i(x, y))
	return result


func _make_registry(grid_positions: Array, blocked_by_grid: Dictionary):
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for grid_variant in grid_positions:
		var grid_position: Vector2i = Vector2i(grid_variant)
		var walkable: bool = bool(blocked_by_grid.get(grid_position, true))
		registry.register_tile(TERRAIN_TILE_DATA_SCRIPT.new({
			"tile_id": "%d_%d" % [grid_position.x, grid_position.y],
			"type_id": "ground_flat" if walkable else "rock_large",
			"grid_position": grid_position,
			"world_position": registry.grid_to_world(grid_position),
			"walkable": walkable,
			"surface_type": "ground" if walkable else "rock",
		}))
	return registry


func _build_move_command(unit_id: String, target_position: Vector2, priority: int = 0) -> Dictionary:
	return {
		"command_type": "move_to_position",
		"unit_id": unit_id,
		"team_id": "team_alpha",
		"target_position": target_position,
		"move_speed_factor": 1.0,
		"requeue_until_target": true,
		"priority": priority,
	}


func _last_fallback_query_has_candidate_count(queries: Array, expected_count: int) -> bool:
	for query in queries:
		if typeof(query) != TYPE_DICTIONARY:
			continue
		var query_dict: Dictionary = Dictionary(query)
		if String(query_dict.get("query_kind", "")) == "fallback" and int(query_dict.get("fallback_candidate_count", -1)) == expected_count:
			return int(query_dict.get("fallback_path_attempts", 0)) == 1
	return false


func _find_scene_navigation_budget_overrides(path: String) -> Array:
	var result: Array = []
	var dir := DirAccess.open(path)
	if dir == null:
		return result
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while not entry.is_empty():
		if entry.begins_with("."):
			entry = dir.get_next()
			continue
		var child_path: String = "%s/%s" % [path, entry]
		if dir.current_is_dir():
			result.append_array(_find_scene_navigation_budget_overrides(child_path))
		elif entry.ends_with(".tscn"):
			var text: String = _read_text(child_path)
			if text.contains("navigation_max_new_path_queries_per_tick") or text.contains("navigation_fallback_max_path_attempts_per_request") or text.contains("navigation_fallback_max_candidates_per_request") or text.contains("navigation_fallback_candidate_warning_threshold"):
				result.append(child_path)
		entry = dir.get_next()
	dir.list_dir_end()
	return result


func _read_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	if text.is_empty():
		return {}
	var parsed = JSON.parse_string(text)
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _cleanup_context(context: Dictionary) -> void:
	var scene = context.get("scene", null)
	if scene != null:
		scene.queue_free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
