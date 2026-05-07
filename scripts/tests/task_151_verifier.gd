extends SceneTree

const BOTTLENECK_RESERVATION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/bottleneck_reservation_resolver.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_151 Bottleneck Reservation MAPF-Light Verifier ===")
	_test_corridor_pair_gets_deterministic_order()
	_test_opposite_edge_conflict_creates_wait_window()
	_test_deadlock_command_receives_reservation_metadata()
	_test_non_walkable_bottleneck_candidate_is_rejected()
	_test_portal_candidates_and_debug_snapshot()
	_test_docs_status()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_corridor_pair_gets_deterministic_order() -> void:
	var resolver = BOTTLENECK_RESERVATION_RESOLVER_SCRIPT.new()
	var candidate: Dictionary = Dictionary(resolver.call("build_candidate_from_cells", "corridor:center", [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)], "manual"))
	var plan: Dictionary = Dictionary(resolver.call("build_reservation_plan", [
		_make_request("bravo", "blue", 2, [Vector2i(1, 2), Vector2i(1, 1), Vector2i(1, 0)]),
		_make_request("alpha", "blue", 2, [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)]),
	], [candidate], {"start_tick": 10, "horizon_ticks": 8}))
	var decisions: Dictionary = Dictionary(plan.get("decisions_by_unit_id", {}))
	var alpha: Dictionary = Dictionary(decisions.get("alpha", {}))
	var bravo: Dictionary = Dictionary(decisions.get("bravo", {}))
	_assert(String(alpha.get("decision", "")) == "pass", "Earlier deterministic unit passes the bottleneck first")
	_assert(int(alpha.get("wait_ticks", -1)) == 0, "First unit gets no wait window")
	_assert(int(bravo.get("wait_ticks", 0)) > 0, "Second opposing unit gets a wait window")
	_assert(Array(plan.get("waiting_unit_ids", [])).has("bravo"), "Debug plan lists waiting unit")


func _test_opposite_edge_conflict_creates_wait_window() -> void:
	var resolver = BOTTLENECK_RESERVATION_RESOLVER_SCRIPT.new()
	var candidate: Dictionary = Dictionary(resolver.call("build_candidate_from_cells", "portal:door", [Vector2i(4, 4), Vector2i(4, 5)], "manual"))
	var plan: Dictionary = Dictionary(resolver.call("build_reservation_plan", [
		_make_request("atlas", "red", 1, [Vector2i(4, 4), Vector2i(4, 5)]),
		_make_request("boreal", "red", 1, [Vector2i(4, 5), Vector2i(4, 4)]),
	], [candidate], {"start_tick": 4, "horizon_ticks": 6}))
	var conflicts: Array = Array(plan.get("conflicts", []))
	_assert(not conflicts.is_empty(), "Opposing units produce a reservation conflict")
	_assert(String(Dictionary(conflicts[0]).get("reason", "")) == "same_cell_time" or String(Dictionary(conflicts[0]).get("reason", "")) == "opposite_edge_time", "Conflict reason names cell or edge contention")
	var decisions: Dictionary = Dictionary(plan.get("decisions_by_unit_id", {}))
	_assert(int(Dictionary(decisions.get("boreal", {})).get("wait_ticks", 0)) > 0, "Opposite traversal is delayed instead of overlapping")


func _test_deadlock_command_receives_reservation_metadata() -> void:
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.bottleneck_reservation_enabled = true
	simulation_root.bottleneck_reservation_debug_enabled = true
	var command: Dictionary = {
		"command_type": "move_to_position",
		"unit_id": "deadlock_alpha",
		"fireteam_id": "blue",
		"command_priority": 3,
		"local_avoidance_repath_requested": true,
		"path_grid_points": [Vector2i(2, 1), Vector2i(2, 2)],
	}
	var decision: Dictionary = Dictionary(simulation_root.call("resolve_bottleneck_reservation_for_command", command, [Vector2i(2, 1), Vector2i(2, 2)], 151))
	_assert(String(decision.get("bottleneck_id", "")) == "command_bottleneck", "SimulationRoot resolves command bottleneck reservation")
	_assert(bool(decision.get("deadlock_escalated", false)), "Deadlock/repath marker is carried into reservation decision")
	_assert(command.has("bottleneck_reservation") and int(command.get("bottleneck_wait_ticks", -1)) >= 0, "Command receives reservation metadata")
	_assert(not Dictionary(simulation_root.call("get_bottleneck_reservation_debug_snapshot")).is_empty(), "SimulationRoot exposes bottleneck reservation debug snapshot")
	simulation_root.queue_free()


func _test_non_walkable_bottleneck_candidate_is_rejected() -> void:
	var registry: Node = _make_registry_with_walkability({Vector2i(1, 1): false, Vector2i(1, 2): true})
	var resolver = BOTTLENECK_RESERVATION_RESOLVER_SCRIPT.new()
	var rejected: Dictionary = Dictionary(resolver.call("build_candidate_from_cells", "corridor:blocked", [Vector2i(1, 1), Vector2i(1, 2)], "manual", registry))
	var plan: Dictionary = Dictionary(resolver.call("build_reservation_plan", [
		_make_request("alpha", "blue", 1, [Vector2i(1, 1), Vector2i(1, 2)]),
	], [rejected], {"start_tick": 0}))
	var decisions: Dictionary = Dictionary(plan.get("decisions_by_unit_id", {}))
	var decision: Dictionary = Dictionary(decisions.get("alpha", {}))
	_assert(not bool(rejected.get("valid", true)) and String(rejected.get("reject_reason", "")) == "non_walkable_bottleneck_cell", "Resolver rejects non-walkable bottleneck candidate")
	_assert(String(decision.get("conflict_reason", "")) == "no_bottleneck_match", "Rejected candidate is not used for movement reservation")
	registry.queue_free()


func _test_portal_candidates_and_debug_snapshot() -> void:
	var resolver = BOTTLENECK_RESERVATION_RESOLVER_SCRIPT.new()
	var candidates: Array = Array(resolver.call("build_candidates_from_portals", [{
		"portal_id": "p_a",
		"from_grid": Vector2i(8, 3),
		"to_grid": Vector2i(9, 3),
		"from_component": "a",
		"to_component": "b",
	}]))
	var plan: Dictionary = Dictionary(resolver.call("build_reservation_plan", [
		_make_request("unit_a", "gold", 1, [Vector2i(8, 3), Vector2i(9, 3)]),
	], candidates, {"start_tick": 3}))
	var snapshot: Dictionary = Dictionary(resolver.call("get_debug_snapshot"))
	_assert(candidates.size() == 1 and String(Dictionary(candidates[0]).get("source", "")) == "hpa_portal", "Resolver builds candidates from HPA portal snapshots")
	_assert(String(Dictionary(candidates[0]).get("bottleneck_id", "")) == "portal:p_a", "Portal candidate gets stable bottleneck id")
	_assert(int(plan.get("reservation_count", 0)) == 2, "Plan reserves portal cells for request")
	_assert(int(snapshot.get("requests_count", 0)) == 1 and int(snapshot.get("candidate_count", 0)) == 1, "Debug snapshot exposes request and candidate counts")


func _test_docs_status() -> void:
	var task_text: String = _read_text("res://docs/tasks/TASK_151_engpass_reservierung_mapf_light.md")
	var status_text: String = _read_text("res://docs/IMPLEMENTATION_STATUS.md")
	var roadmap_text: String = _read_text("res://docs/TASK_ROADMAP.md")
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "Task file marks TASK_151 implemented")
	_assert(not task_text.contains("- [ ]"), "Task checklist is complete")
	_assert(status_text.contains("### TASK_151 - Engpass-Reservierung und MAPF-Light") and status_text.contains("- Status: implementiert"), "Implementation status marks TASK_151 implemented")
	_assert(roadmap_text.contains("TASK_151 - Engpass-Reservierung und MAPF-Light (implementiert)"), "Roadmap marks TASK_151 implemented")


func _make_request(unit_id: String, fireteam_id: String, priority: int, path: Array) -> Dictionary:
	return {
		"unit_id": unit_id,
		"fireteam_id": fireteam_id,
		"command_priority": priority,
		"path_grid_points": path,
		"queue_index": 0,
	}


func _make_registry_with_walkability(walkability: Dictionary) -> Node:
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for grid_variant in walkability.keys():
		var grid: Vector2i = Vector2i(grid_variant)
		var walkable: bool = bool(walkability.get(grid, true))
		registry.register_tile(TERRAIN_TILE_DATA_SCRIPT.new({
			"tile_id": "%d_%d" % [grid.x, grid.y],
			"type_id": "ground_flat" if walkable else "rock_large",
			"grid_position": grid,
			"world_position": registry.grid_to_world(grid),
			"walkable": walkable,
			"surface_type": "ground" if walkable else "rock",
		}))
	root.add_child(registry)
	return registry


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
