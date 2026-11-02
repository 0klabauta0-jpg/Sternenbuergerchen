extends SceneTree

const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const SIMULATION = preload("res://scripts/core/simulation_root.gd")
const REGISTRY = preload("res://scripts/registries/unit_registry.gd")
const UNIT = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	if not GUARD.require_isolated_user_data():
		return
	call_deferred("_run")


func _run() -> void:
	_test_foreign_unit_cannot_borrow_assigned_fireteam()
	_test_known_unit_cannot_be_relabelled_between_assigned_fireteams()
	_test_assigned_unit_with_and_without_fireteam_hint()
	_test_commander_and_legacy_metadata_compatibility()
	print("REVIEW_CYCLES_FIRETEAM_AUTHORITY_RESULT passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _test_foreign_unit_cannot_borrow_assigned_fireteam() -> void:
	var fixture: Dictionary = _fixture()
	var simulation: Node = fixture.simulation
	var foreign: Node2D = fixture.foreign
	var before: Vector2 = foreign.position
	var forged: Dictionary = _move(foreign, "blue")
	var validation: Dictionary = simulation.validate_network_command_for_peer(forged, 2)
	_check(not bool(validation.get("accepted", false)), "Known foreign Unit cannot borrow the caller's assigned fireteam hint")
	var result: Dictionary = simulation.submit_network_command_for_peer(forged, 2)
	_check(not bool(result.get("accepted", false)), "Real authority submission rejects forged Unit ownership")
	_check(simulation.command_queue.is_empty(), "Rejected forged command never enters the authority queue")
	simulation._physics_process(0.1)
	_check(foreign.position == before, "Processing the real queue cannot move the foreign Unit")
	_check(foreign.get_current_unit_command() == null, "Forged command cannot commit foreign Unit runtime state")
	var truthful: Dictionary = simulation.validate_network_command_for_peer(_move(foreign, "gold"), 2)
	_check(not bool(truthful.get("accepted", false)), "Truthful foreign fireteam hint is also rejected")
	var omitted: Dictionary = _move(foreign)
	_check(not bool(simulation.validate_network_command_for_peer(omitted, 2).get("accepted", false)), "Omitting the hint cannot bypass known foreign ownership")
	fixture.scene.free()


func _test_known_unit_cannot_be_relabelled_between_assigned_fireteams() -> void:
	var fixture: Dictionary = _fixture()
	var simulation: Node = fixture.simulation
	simulation.set_peer_fireteams(2, PackedStringArray(["blue", "gold"]))
	var own: Node2D = fixture.own
	var before: Vector2 = own.position
	var command: Dictionary = _move(own, "gold")
	_check(not bool(simulation.validate_network_command_for_peer(command, 2).get("accepted", false)), "Known Unit's Fireteam cannot be relabelled even between two assigned groups")
	_check(not bool(simulation.submit_network_command_for_peer(command, 2).get("accepted", false)), "Authority submission rejects a contradictory known Unit hint")
	_check(simulation.command_queue.is_empty(), "Contradictory known Unit hint is never enqueued")
	simulation._physics_process(0.1)
	_check(own.position == before, "Contradictory known Unit hint cannot change the Unit through queue processing")
	fixture.scene.free()


func _test_assigned_unit_with_and_without_fireteam_hint() -> void:
	for include_hint in [true, false]:
		var fixture: Dictionary = _fixture()
		var simulation: Node = fixture.simulation
		var own: Node2D = fixture.own
		var command: Dictionary = _move(own, "blue" if include_hint else "")
		var accepted: Dictionary = simulation.submit_network_command_for_peer(command, 2)
		_check(bool(accepted.get("accepted", false)), "Assigned Unit remains commandable with hint=%s" % include_hint)
		_check(simulation.command_queue.size() == 1, "Valid assigned Unit command is enqueued once with hint=%s" % include_hint)
		simulation._physics_process(0.1)
		_check(own.position.x > 0.0, "Valid assigned Unit moves through the real queue with hint=%s" % include_hint)
		_check(fixture.foreign.position == Vector2(0.0, 128.0), "Assigned command leaves foreign Unit unchanged with hint=%s" % include_hint)
		fixture.scene.free()


func _test_commander_and_legacy_metadata_compatibility() -> void:
	var fixture: Dictionary = _fixture()
	var simulation: Node = fixture.simulation
	simulation.set_peer_role(2, "commander")
	var accepted: Dictionary = simulation.submit_network_command_for_peer(_move(fixture.foreign, "gold"), 2)
	_check(bool(accepted.get("accepted", false)), "Commander keeps authority over its own team's other Fireteam")
	simulation._physics_process(0.1)
	_check(fixture.foreign.position.x > 0.0, "Legitimate commander command still executes")
	simulation.clear_queues()
	simulation.set_peer_role(2, "fireteam")
	fixture.own.fireteam_id = ""
	var legacy: Dictionary = simulation.submit_network_command_for_peer(_move(fixture.own, "blue"), 2)
	_check(bool(legacy.get("accepted", false)), "Legacy Unit without authoritative Fireteam metadata may use its explicit assigned hint")
	fixture.scene.free()


func _fixture() -> Dictionary:
	var scene := Node.new()
	root.add_child(scene)
	var registry = REGISTRY.new()
	registry.name = "Units"
	scene.add_child(registry)
	var simulation = SIMULATION.new()
	simulation.name = "SimulationRoot"
	simulation.is_server_authoritative = true
	simulation.unit_registry_path = NodePath("../Units")
	simulation.unit_minimum_spacing_enabled = false
	scene.add_child(simulation)
	simulation.set_physics_process(false)
	simulation.set_peer_team(2, "team_alpha")
	simulation.set_peer_role(2, "fireteam")
	simulation.set_peer_fireteams(2, PackedStringArray(["blue"]))
	var own = UNIT.new()
	own.unit_id = "owned_blue"
	own.team_id = "team_alpha"
	own.fireteam_id = "blue"
	scene.add_child(own)
	registry.register_unit(own.unit_id, own)
	var foreign = UNIT.new()
	foreign.unit_id = "foreign_gold"
	foreign.team_id = "team_alpha"
	foreign.fireteam_id = "gold"
	foreign.position = Vector2(0.0, 128.0)
	scene.add_child(foreign)
	registry.register_unit(foreign.unit_id, foreign)
	return {"scene": scene, "simulation": simulation, "own": own, "foreign": foreign}


func _move(unit: Node2D, fireteam_hint: String = "") -> Dictionary:
	var command: Dictionary = {
		"contract_category": "unit_command",
		"command_type": "move_to_position",
		"unit_id": unit.unit_id,
		"team_id": "team_alpha",
		"target_position": unit.position + Vector2(96.0, 0.0),
		"command_token": "authority_test",
	}
	if not fireteam_hint.is_empty():
		command["fireteam_id"] = fireteam_hint
	return command


func _check(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: " + message)
	else:
		_failed += 1
		print("FAIL: " + message)
