extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_341_navigation_fallback_candidate_cap.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/navigation_fallback_candidate_cap.md"
const CONTRACT_PATH: String = "res://data/performance_budget_contract.json"
const SIMULATION_ROOT_PATH: String = "res://scripts/core/simulation_root.gd"

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
	print("=== TASK_341 Navigation Fallback Candidate Cap ===")
	_test_docs_contract_and_static_boundary()
	_test_small_disconnected_target_still_picks_nearest_reachable()
	_test_direct_component_fallback_respects_candidate_cap()
	_test_bad_target_path_reports_cap_without_extra_queries()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_docs_contract_and_static_boundary() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var simulation_text: String = _read_text(SIMULATION_ROOT_PATH)
	var navigation_budget: Dictionary = Dictionary(Dictionary(_read_json(CONTRACT_PATH).get("project_budget", {})).get("navigation", {}))
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()

	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "TASK_341 task file marks implemented")
	_assert(not task_text.contains("- [ ]"), "TASK_341 checklist is complete")
	_assert(status_text.contains("### TASK_341 - Navigation Fallback Candidate Cap") and status_text.contains("- Status: implementiert"), "Implementation status marks TASK_341 implemented")
	_assert(roadmap_text.contains("TASK_341 - Navigation Fallback Candidate Cap (implementiert"), "Roadmap marks TASK_341 implemented")
	for token in ["Kandidaten-Cap", "Ring-Suche", "Debug-Snapshot", "Performance-Budget-Contract"]:
		_assert(report_text.to_lower().contains(token.to_lower()), "Report documents %s" % token)
	_assert(int(navigation_budget.get("max_fallback_candidates_per_request", -1)) == int(simulation_root.navigation_fallback_max_candidates_per_request), "Fallback candidate cap matches contract")
	_assert(bool(navigation_budget.get("require_fallback_candidate_cap_diagnostics", false)), "Budget contract requires cap diagnostics")
	_assert(simulation_text.contains("fallback_candidate_cap_hits_this_tick"), "Navigation debug snapshot exposes cap hit counter")
	_assert(simulation_text.contains("selected_distance_to_desired"), "Fallback diagnostic exposes selected distance")
	_assert(not simulation_text.contains("graph.call(\"get_component_tiles\""), "SimulationRoot fallback no longer pulls full HPA component tile lists")
	simulation_root.free()


func _test_small_disconnected_target_still_picks_nearest_reachable() -> void:
	var context: Dictionary = _make_simulation_context([
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(4, 0),
	], {}, [])
	var simulation_root = context["simulation_root"]
	var registry = context["terrain_registry"]
	var diagnostic: Dictionary = Dictionary(simulation_root.call("_resolve_navigation_fallback_grid", Vector2i(0, 0), Vector2i(4, 0), registry))

	_assert(Vector2i(diagnostic.get("grid", Vector2i.ZERO)) == Vector2i(1, 0), "Small disconnected target still chooses the nearest reachable tile")
	_assert(int(diagnostic.get("candidate_count", 0)) == 2, "Small fallback evaluates all local candidates below the cap")
	_assert(not bool(diagnostic.get("candidate_capped", false)), "Small fallback does not report a cap hit")
	_assert(float(diagnostic.get("selected_distance_to_desired", -1.0)) == 3.0, "Small fallback reports selected distance to desired")
	_cleanup_context(context)


func _test_direct_component_fallback_respects_candidate_cap() -> void:
	var grid_positions: Array = _make_rect_positions(Vector2i(0, 0), Vector2i(15, 15))
	grid_positions.append(Vector2i(40, 0))
	var context: Dictionary = _make_simulation_context(grid_positions, {}, [])
	var simulation_root = context["simulation_root"]
	var registry = context["terrain_registry"]
	simulation_root.call("set_navigation_fallback_max_candidates_per_request", 12)
	simulation_root.call("set_navigation_fallback_candidate_warning_threshold", 8)

	var diagnostic: Dictionary = Dictionary(simulation_root.call("_resolve_navigation_fallback_grid", Vector2i(0, 0), Vector2i(40, 0), registry))
	_assert(Vector2i(diagnostic.get("grid", Vector2i.ZERO)) == Vector2i(15, 0), "Large fallback still selects the nearest reachable edge candidate")
	_assert(int(diagnostic.get("candidate_count", 0)) == 12, "Large fallback evaluates only the configured candidate cap")
	_assert(int(diagnostic.get("candidate_considered_count", 0)) == 12, "Diagnostic records the considered candidate count")
	_assert(int(diagnostic.get("candidate_limit", 0)) == 12, "Diagnostic records the candidate limit")
	_assert(bool(diagnostic.get("candidate_capped", false)), "Diagnostic marks capped candidate search")
	_assert(String(diagnostic.get("candidate_search_reason", "")) == "candidate_limit_reached", "Diagnostic records the cap reason")
	_assert(String(diagnostic.get("warning", "")) == "fallback_candidate_cap_reached", "Diagnostic warning names the cap")
	_assert(float(diagnostic.get("selected_distance_to_desired", -1.0)) == 25.0, "Diagnostic records selected distance to desired")
	_cleanup_context(context)


func _test_bad_target_path_reports_cap_without_extra_queries() -> void:
	var grid_positions: Array = _make_rect_positions(Vector2i(0, 0), Vector2i(15, 15))
	grid_positions.append(Vector2i(40, 0))
	var context: Dictionary = _make_simulation_context(grid_positions, {}, [])
	var simulation_root = context["simulation_root"]
	var registry = context["terrain_registry"]
	var unit = _add_unit(context, "task341_large_component", Vector2i(0, 0))
	simulation_root.call("set_navigation_debug_enabled", true)
	simulation_root.call("set_navigation_fallback_max_candidates_per_request", 10)
	simulation_root.call("set_navigation_fallback_candidate_warning_threshold", 8)

	var target_position: Vector2 = registry.call("grid_to_world", Vector2i(40, 0))
	var cmd: Dictionary = _build_move_command(unit.get_unit_id(), target_position)
	var path: Array = simulation_root.call("_extract_or_build_path_world_points", cmd, unit, unit.global_position, target_position, registry)
	var snapshot: Dictionary = Dictionary(simulation_root.call("get_navigation_debug_snapshot"))
	var diagnostic: Dictionary = Dictionary(snapshot.get("last_fallback_diagnostic", {}))

	_assert(not path.is_empty(), "Bad target path still resolves to a reachable fallback")
	_assert(int(snapshot.get("fallback_path_attempts_this_tick", 0)) == 1, "Fallback performs one budgeted path attempt")
	_assert(int(snapshot.get("path_queries_this_tick", 0)) <= 2, "Fallback has no hidden multi-query spike")
	_assert(int(snapshot.get("fallback_candidate_cap_hits_this_tick", 0)) == 1, "Debug snapshot records one cap hit")
	_assert(int(diagnostic.get("candidate_count", 0)) == 10, "Path diagnostic stays at the requested cap")
	_assert(bool(diagnostic.get("candidate_capped", false)), "Path diagnostic records capping")
	_assert(_last_fallback_query_has_cap(Array(snapshot.get("last_queries", [])), 10), "Fallback query record carries cap diagnostics")
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


func _last_fallback_query_has_cap(queries: Array, expected_limit: int) -> bool:
	for query in queries:
		if typeof(query) != TYPE_DICTIONARY:
			continue
		var query_dict: Dictionary = Dictionary(query)
		if String(query_dict.get("query_kind", "")) != "fallback":
			continue
		return (
			int(query_dict.get("fallback_candidate_limit", 0)) == expected_limit
			and int(query_dict.get("fallback_candidate_count", 0)) == expected_limit
			and bool(query_dict.get("fallback_candidate_capped", false))
			and String(query_dict.get("fallback_candidate_search_reason", "")) == "candidate_limit_reached"
		)
	return false


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
