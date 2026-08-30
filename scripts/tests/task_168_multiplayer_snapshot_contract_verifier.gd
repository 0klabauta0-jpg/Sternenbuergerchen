extends SceneTree

const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const OBJECTIVE_STATUS_SCRIPT: GDScript = preload("res://scripts/core/objective_status.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_168 Multiplayer Snapshot Contract Verifier ===")
	await _test_snapshot_schema_contains_v1_fields()
	await _test_client_applies_newer_snapshots_and_ignores_old_ones()
	await _test_snapshot_apply_does_not_enqueue_commands()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit(1 if _failed > 0 else 0)
func _test_snapshot_schema_contains_v1_fields() -> void:
	var context: Dictionary = _make_context()
	var simulation_root: Node = context["simulation_root"]
	_register_unit(context, "unit_alpha", "team_alpha", "blue", Vector2(24.0, 32.0))
	simulation_root.set("tick_counter", 12)
	var objective_status = OBJECTIVE_STATUS_SCRIPT.new()
	objective_status.objective_id = "obj_alpha"
	objective_status.position = Vector2(128.0, 64.0)
	objective_status.capture_radius = 72.0
	objective_status.owning_team_id = "team_alpha"
	objective_status.capturing_team_id = "team_alpha"
	objective_status.capture_progress = 0.5
	objective_status.set_contested(false)
	simulation_root.call("set_objective_status", objective_status)
	simulation_root.call(
		"set_multiplayer_snapshot_context",
		{
			"dropship": {
				"visible": true,
				"state": "inbound",
				"has_lz": true,
				"lz_position": Vector2(80.0, 96.0),
				"position": Vector2(40.0, 40.0),
				"target_position": Vector2(80.0, 96.0),
				"progress": 0.35,
			},
			"contacts": [
				{
					"fireteam_id": "blue",
					"unit_id": "enemy_1",
					"team_id": "team_bravo",
					"detection_state": "spotted",
					"last_known_position": Vector2(180.0, 120.0),
					"last_seen_tick": 11,
				},
			],
			"mission_result": {
				"result": "victory",
				"winning_team_id": "team_alpha",
				"win_condition_type": "objective_capture",
				"duration_seconds": 42.0,
			},
		}
	)
	var snapshot: Dictionary = simulation_root.call("build_multiplayer_snapshot")
	_assert(int(snapshot.get("schema_version", 0)) == 1, "Snapshot carries schema version")
	_assert(String(snapshot.get("transfer_mode", "")) == "unreliable", "State snapshot declares unordered unreliable chunk transfer")
	_assert(int(snapshot.get("tick", 0)) == 12, "Snapshot carries the authoritative tick")
	_assert(Array(snapshot.get("units", [])).size() == 1, "Snapshot includes unit state")
	_assert(String(Dictionary(Array(snapshot.get("units", []))[0]).get("team_id", "")) == "team_alpha", "Snapshot includes unit team identity")
	_assert(Array(snapshot.get("vital_updates", [])).size() == 1, "Snapshot includes vital state entries")
	_assert(not Dictionary(snapshot.get("objective", {})).is_empty(), "Snapshot includes objective state")
	_assert(String(Dictionary(snapshot.get("dropship", {})).get("state", "")) == "inbound", "Snapshot includes dropship display state")
	_assert(Array(snapshot.get("contacts", [])).size() == 1, "Snapshot includes contact display entries")
	_assert(String(Dictionary(snapshot.get("mission_result", {})).get("result", "")) == "victory", "Snapshot includes mission result state")
	_cleanup_context(context)


func _test_client_applies_newer_snapshots_and_ignores_old_ones() -> void:
	var context: Dictionary = _make_context()
	var simulation_root: Node = context["simulation_root"]
	var unit: Node2D = _register_unit(context, "unit_alpha", "team_alpha", "blue", Vector2.ZERO)
	var accepted: Dictionary = simulation_root.call(
		"apply_multiplayer_snapshot",
		{
			"schema_version": 1,
			"tick": 3,
			"units": [
				{
					"unit_id": "unit_alpha",
					"position": Vector2(100.0, 0.0),
					"visible": true,
				},
			],
		}
	)
	var rejected: Dictionary = simulation_root.call(
		"apply_multiplayer_snapshot",
		{
			"schema_version": 1,
			"tick": 2,
			"units": [
				{
					"unit_id": "unit_alpha",
					"position": Vector2(200.0, 0.0),
					"visible": true,
				},
			],
		}
	)
	var missing_result: Dictionary = simulation_root.call(
		"apply_multiplayer_snapshot",
		{
			"schema_version": 1,
			"tick": 4,
			"units": [
				{
					"unit_id": "unit_missing",
					"position": Vector2(5.0, 5.0),
					"visible": true,
				},
			],
		}
	)
	var debug_snapshot: Dictionary = simulation_root.call("get_multiplayer_snapshot_debug_snapshot")
	_assert(bool(accepted.get("accepted", false)), "Client accepts a newer snapshot")
	_assert(unit.global_position.x > 0.0 and unit.global_position.x < 100.0, "Client applies snapshot through render interpolation")
	_assert(not bool(rejected.get("accepted", true)), "Client rejects an older snapshot")
	_assert(String(rejected.get("reason", "")) == "out_of_order_snapshot", "Out-of-order rejection reason is explicit")
	_assert(int(debug_snapshot.get("last_applied_tick", 0)) == 4, "Debug tracks the latest applied tick")
	_assert(int(debug_snapshot.get("out_of_order_count", 0)) == 1, "Debug counts out-of-order snapshots")
	_assert(int(missing_result.get("missing_unit_count", 0)) == 1, "Apply result reports missing units")
	_assert(int(debug_snapshot.get("missing_unit_count", 0)) == 1, "Debug accumulates missing-unit count")
	_cleanup_context(context)


func _test_snapshot_apply_does_not_enqueue_commands() -> void:
	var context: Dictionary = _make_context()
	var simulation_root: Node = context["simulation_root"]
	_register_unit(context, "unit_alpha", "team_alpha", "blue", Vector2.ZERO)
	simulation_root.call(
		"apply_multiplayer_snapshot",
		{
			"schema_version": 1,
			"tick": 7,
			"units": [
				{
					"unit_id": "unit_alpha",
					"position": Vector2(48.0, 0.0),
					"runtime_state": "pending_move",
				},
			],
			"mission_result": {
				"result": "defeat",
				"winning_team_id": "team_bravo",
			},
		}
	)
	_assert(simulation_root.command_queue.is_empty(), "Applying a snapshot never enqueues authoritative commands")
	_assert(simulation_root.effects_queue.is_empty(), "Applying a snapshot never enqueues authoritative effects")
	_cleanup_context(context)


func _make_context() -> Dictionary:
	var root := Node.new()
	root.name = "Task168Context"
	get_root().add_child(root)

	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	root.add_child(unit_registry)

	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	root.add_child(simulation_root)

	return {
		"root": root,
		"unit_registry": unit_registry,
		"simulation_root": simulation_root,
	}


func _register_unit(context: Dictionary, unit_id: String, team_id: String, fireteam_id: String, position: Vector2) -> Node2D:
	var root: Node = context["root"]
	var unit_registry: Node = context["unit_registry"]
	var simulation_root: Node = context["simulation_root"]
	var unit: Node2D = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.team_id = team_id
	unit.fireteam_id = fireteam_id
	unit.global_position = position
	root.add_child(unit)
	unit_registry.call("register_unit", unit_id, unit)
	simulation_root.call("register_known_unit", unit_id, unit)
	return unit


func _cleanup_context(context: Dictionary) -> void:
	var root: Node = context.get("root", null)
	if root != null:
		root.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
