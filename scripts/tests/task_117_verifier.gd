extends SceneTree

const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const FTL_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/ftl_registry.gd")
const RUNTIME_LEADER_SCRIPT: GDScript = preload("res://scripts/ftl/runtime_leader.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_117 Dropship Effects Verifier ===")
	await _test_embark_effect_moves_known_unregistered_unit_offmap()
	await _test_deploy_effect_activates_known_unit_authoritatively()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_embark_effect_moves_known_unregistered_unit_offmap() -> void:
	var context: Dictionary = _make_context()
	var simulation_root: Node = context["simulation_root"]
	var unit: Node2D = _make_unit("drop_embark", "team_alpha", "blue")
	context["root"].add_child(unit)
	simulation_root.call("register_known_unit", "drop_embark", unit)
	unit.global_position = Vector2(12.0, 24.0)
	unit.visible = true

	simulation_root.call(
		"enqueue_effect",
		{
			"effect_type": "dropship_embark_unit",
			"unit_id": "drop_embark",
			"position": Vector2(-400.0, -300.0),
			"visible": false,
		}
	)
	simulation_root.call("_physics_process", 0.016)

	_assert(unit.global_position == Vector2(-400.0, -300.0), "Embark effect commits the dropship staging position through SimulationRoot")
	_assert(not unit.visible, "Embark effect hides the unit through SimulationRoot")
	_assert(not bool(context["unit_registry"].call("has_unit", "drop_embark")), "Embark effect does not activate the unit registry entry")
	_cleanup_context(context)


func _test_deploy_effect_activates_known_unit_authoritatively() -> void:
	var context: Dictionary = _make_context()
	var simulation_root: Node = context["simulation_root"]
	var runtime_leader: Node = context["runtime_leader"]
	var unit_registry: Node = context["unit_registry"]
	var ftl_registry: Node = context["ftl_registry"]
	var unit: Node2D = _make_unit("drop_deploy", "team_alpha", "blue")
	context["root"].add_child(unit)
	simulation_root.call("register_known_unit", "drop_deploy", unit)
	unit.global_position = Vector2(-400.0, -300.0)
	unit.visible = false

	simulation_root.call(
		"enqueue_effect",
		{
			"effect_type": "dropship_deploy_unit",
			"unit_id": "drop_deploy",
			"position": Vector2(80.0, 96.0),
			"visible": true,
			"runtime_status": "idle",
			"runtime_active": true,
			"runtime_leader_path": NodePath("../RuntimeLeader"),
			"ftl_registry_path": NodePath("../FTLRegistry"),
			"team_id": "team_alpha",
		}
	)
	simulation_root.call("_physics_process", 0.016)

	_assert(unit.global_position == Vector2(80.0, 96.0), "Deploy effect commits the LZ position through SimulationRoot")
	_assert(unit.visible, "Deploy effect reveals the deployed unit through SimulationRoot")
	_assert(bool(unit_registry.call("has_unit", "drop_deploy")), "Deploy effect activates the UnitRegistry entry")
	_assert(int(runtime_leader.call("get_assigned_unit_count")) == 1, "Deploy effect adds the unit to RuntimeLeader")
	_assert(bool(ftl_registry.call("has_ftl", "team_alpha")), "Deploy effect registers the active FTL lookup")
	var runtime_status = unit.call("get_runtime_status")
	_assert(runtime_status != null and String(runtime_status.call("to_dict").get("status", "")) == "idle", "Deploy effect sets the unit runtime status")
	_cleanup_context(context)


func _make_context() -> Dictionary:
	var root := Node.new()
	root.name = "Task117Context"
	get_root().add_child(root)

	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	root.add_child(unit_registry)

	var ftl_registry = FTL_REGISTRY_SCRIPT.new()
	ftl_registry.name = "FTLRegistry"
	root.add_child(ftl_registry)

	var runtime_leader = RUNTIME_LEADER_SCRIPT.new()
	runtime_leader.name = "RuntimeLeader"
	root.add_child(runtime_leader)

	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	root.add_child(simulation_root)

	return {
		"root": root,
		"simulation_root": simulation_root,
		"unit_registry": unit_registry,
		"ftl_registry": ftl_registry,
		"runtime_leader": runtime_leader,
	}


func _make_unit(unit_id: String, team_id: String, fireteam_id: String) -> Node2D:
	var unit: Node2D = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.team_id = team_id
	unit.fireteam_id = fireteam_id
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
