extends SceneTree

const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_166 Multiplayer Authority Command Contract Verifier ===")
	await _test_valid_move_is_enqueued_server_side()
	await _test_foreign_team_command_is_rejected()
	await _test_state_mutation_command_is_rejected()
	await _test_fireteam_peer_assignment_limits_commands()
	await _test_area_ad_hoc_and_dropship_whitelist()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_valid_move_is_enqueued_server_side() -> void:
	var context: Dictionary = _make_context()
	var simulation_root: Node = context["simulation_root"]
	_register_unit(context, "unit_alpha", "team_alpha", "blue")
	simulation_root.call("set_peer_team", 1, "team_alpha")

	simulation_root.call(
		"request_command",
		{
			"command_type": "move_to_position",
			"unit_id": "unit_alpha",
			"team_id": "team_alpha",
			"fireteam_id": "blue",
			"target_position": Vector2(96.0, 32.0),
			"priority": 4,
		}
	)
	var snapshot: Dictionary = simulation_root.call("get_network_command_contract_snapshot")
	_assert(simulation_root.command_queue.size() == 1, "Allowed move command is enqueued on the authority")
	_assert(int(snapshot.get("accepted_count", 0)) == 1, "Accepted command increments the network accept counter")
	_assert(int(snapshot.get("rejected_count", 0)) == 0, "Allowed move command does not create a rejection")
	_cleanup_context(context)


func _test_foreign_team_command_is_rejected() -> void:
	var context: Dictionary = _make_context()
	var simulation_root: Node = context["simulation_root"]
	_register_unit(context, "unit_alpha", "team_alpha", "blue")
	simulation_root.call("set_peer_team", 1, "team_alpha")

	simulation_root.call(
		"request_command",
		{
			"command_type": "move_to_position",
			"unit_id": "unit_alpha",
			"team_id": "team_bravo",
			"fireteam_id": "blue",
			"target_position": Vector2(16.0, 16.0),
		}
	)
	var snapshot: Dictionary = simulation_root.call("get_network_command_contract_snapshot")
	var last_rejection: Dictionary = Dictionary(snapshot.get("last_rejection", {}))
	_assert(simulation_root.command_queue.is_empty(), "Foreign-team move is not enqueued")
	_assert(int(snapshot.get("rejected_count", 0)) == 1, "Foreign-team move increments the rejection counter")
	_assert(String(last_rejection.get("reason", "")) == "peer_team_mismatch", "Foreign-team move records a peer-team mismatch")
	_cleanup_context(context)


func _test_state_mutation_command_is_rejected() -> void:
	var context: Dictionary = _make_context()
	var simulation_root: Node = context["simulation_root"]
	_register_unit(context, "unit_alpha", "team_alpha", "blue")
	simulation_root.call("set_peer_team", 1, "team_alpha")

	simulation_root.call(
		"request_command",
		{
			"command_type": "move_to_position",
			"unit_id": "unit_alpha",
			"team_id": "team_alpha",
			"target_position": Vector2(32.0, 32.0),
			"damage": 50,
		}
	)
	var snapshot: Dictionary = simulation_root.call("get_network_command_contract_snapshot")
	var last_rejection: Dictionary = Dictionary(snapshot.get("last_rejection", {}))
	_assert(simulation_root.command_queue.is_empty(), "State-mutation payload is not enqueued")
	_assert(String(last_rejection.get("reason", "")).begins_with("state_mutation_key:damage"), "State-mutation payload records the forbidden key")
	_cleanup_context(context)


func _test_fireteam_peer_assignment_limits_commands() -> void:
	var context: Dictionary = _make_context()
	var simulation_root: Node = context["simulation_root"]
	_register_unit(context, "unit_blue", "team_alpha", "blue")
	_register_unit(context, "unit_red", "team_alpha", "red")
	simulation_root.call("set_peer_team", 2, "team_alpha")
	simulation_root.call("set_peer_role", 2, "fireteam")
	simulation_root.call("set_peer_fireteams", 2, PackedStringArray(["blue"]))

	var accepted: Dictionary = simulation_root.call(
		"validate_network_command_for_peer",
		{
			"command_type": "move_to_position",
			"unit_id": "unit_blue",
			"team_id": "team_alpha",
			"fireteam_id": "blue",
			"target_position": Vector2(48.0, 48.0),
		},
		2
	)
	var rejected: Dictionary = simulation_root.call(
		"validate_network_command_for_peer",
		{
			"command_type": "move_to_position",
			"unit_id": "unit_red",
			"team_id": "team_alpha",
			"fireteam_id": "red",
			"target_position": Vector2(64.0, 64.0),
		},
		2
	)
	_assert(bool(accepted.get("accepted", false)), "Assigned fireteam peer may command its fireteam")
	_assert(not bool(rejected.get("accepted", false)), "Fireteam peer cannot command another fireteam")
	_assert(String(rejected.get("reason", "")) == "fireteam_not_assigned_to_peer", "Foreign fireteam rejection is explicit")
	_cleanup_context(context)


func _test_area_ad_hoc_and_dropship_whitelist() -> void:
	var context: Dictionary = _make_context()
	var simulation_root: Node = context["simulation_root"]
	simulation_root.call("set_peer_team", 1, "team_alpha")

	var allowed_area: Dictionary = simulation_root.call(
		"validate_network_command_for_peer",
		{
			"area_order_id": "area_blue_1",
			"fireteam_id": "blue",
			"command_type": "engage",
			"center_position": Vector2(120.0, 96.0),
			"tile_positions": [Vector2i(2, 3)],
			"created_at_order_index": 0,
			"status": "pending",
		},
		1
	)
	var rejected_area: Dictionary = simulation_root.call(
		"validate_network_command_for_peer",
		{
			"area_order_id": "area_blue_2",
			"fireteam_id": "blue",
			"command_type": "take",
			"center_position": Vector2(120.0, 96.0),
			"tile_positions": [Vector2i(2, 3)],
			"created_at_order_index": 0,
			"status": "pending",
		},
		1
	)
	var allowed_ad_hoc: Dictionary = simulation_root.call(
		"validate_network_command_for_peer",
		{
			"fireteam_id": "blue",
			"order_type": "hold_till_last_man",
			"status": "pending",
			"resume_plan_after": false,
		},
		1
	)
	var rejected_lz: Dictionary = simulation_root.call(
		"validate_network_command_for_peer",
		{
			"command_type": "set_lz",
			"team_id": "team_alpha",
			"lz_position": Vector2(320.0, 160.0),
			"source_context": "scenario",
		},
		1
	)
	_assert(bool(allowed_area.get("accepted", false)), "Engage area order is whitelisted")
	_assert(String(rejected_area.get("reason", "")) == "area_order_not_whitelisted", "Take area order is rejected by the multiplayer contract")
	_assert(bool(allowed_ad_hoc.get("accepted", false)), "Ad-hoc hold order is whitelisted")
	_assert(String(rejected_lz.get("reason", "")) == "lz_from_forbidden_source", "Scenario/editor LZ payload is rejected")
	_cleanup_context(context)


func _make_context() -> Dictionary:
	var root := Node.new()
	root.name = "Task166Context"
	get_root().add_child(root)

	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	root.add_child(unit_registry)

	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	simulation_root.is_server_authoritative = true
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	root.add_child(simulation_root)

	return {
		"root": root,
		"unit_registry": unit_registry,
		"simulation_root": simulation_root,
	}


func _register_unit(context: Dictionary, unit_id: String, team_id: String, fireteam_id: String) -> Node2D:
	var root: Node = context["root"]
	var unit_registry: Node = context["unit_registry"]
	var simulation_root: Node = context["simulation_root"]
	var unit: Node2D = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.team_id = team_id
	unit.fireteam_id = fireteam_id
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
