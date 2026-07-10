extends SceneTree

const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const MISSION_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1082 Multiplayer ROE Authority And Replication ===")
	await _test_peer_fireteam_authority_and_host_commit()
	await _test_authoritative_snapshot_replication()
	await _test_mission_controller_applies_only_newer_authority_revisions()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_peer_fireteam_authority_and_host_commit() -> void:
	var context: Dictionary = _make_context("Task1082Authority")
	var simulation_root: Node = context["simulation_root"]
	simulation_root.set("is_server_authoritative", true)
	simulation_root.call("set_peer_team", 2, "team_alpha")
	simulation_root.call("set_peer_role", 2, "fireteam")
	simulation_root.call("set_peer_fireteams", 2, PackedStringArray(["ft1"]))

	var accepted: Dictionary = Dictionary(simulation_root.call("submit_network_command_for_peer", _build_fire_rule_command("ft1", "hold"), 2))
	_assert(bool(accepted.get("accepted", false)), "Assigned Fireteam peer can submit its ROE command")
	_assert(simulation_root.command_queue.size() == 1, "Accepted ROE waits in the authoritative command queue")
	_assert(Dictionary(simulation_root.call("get_authoritative_fire_rule_state", "ft1")).is_empty(), "Submission alone does not mutate authoritative ROE state")

	var foreign: Dictionary = Dictionary(simulation_root.call("submit_network_command_for_peer", _build_fire_rule_command("ft2", "free"), 2))
	_assert(String(foreign.get("reason", "")) == "fireteam_not_assigned_to_peer", "Peer cannot change another Fireteam on the same team")
	simulation_root.call("set_peer_role", 2, "commander")
	var commander_foreign: Dictionary = Dictionary(simulation_root.call("submit_network_command_for_peer", _build_fire_rule_command("ft2", "free"), 2))
	_assert(String(commander_foreign.get("reason", "")) == "fireteam_not_assigned_to_peer", "Assigned commander peer cannot bypass ROE Fireteam ownership")
	simulation_root.call("set_peer_role", 2, "fireteam")
	var invalid: Dictionary = Dictionary(simulation_root.call("submit_network_command_for_peer", _build_fire_rule_command("ft1", "always"), 2))
	_assert(String(invalid.get("reason", "")) == "invalid_fire_rule", "Unknown ROE is rejected before commit")
	var mutation_command: Dictionary = _build_fire_rule_command("ft1", "free")
	mutation_command["runtime_state"] = "engaging"
	var mutation: Dictionary = Dictionary(simulation_root.call("submit_network_command_for_peer", mutation_command, 2))
	_assert(String(mutation.get("reason", "")).begins_with("state_mutation_key:"), "Client cannot smuggle runtime state with ROE")

	simulation_root.call("_process_commands", simulation_root.call("_drain_queue", simulation_root.command_queue), 0.016)
	var state: Dictionary = Dictionary(simulation_root.call("get_authoritative_fire_rule_state", "ft1"))
	_assert(String(state.get("fire_rule", "")) == "hold", "Host command processing commits the Fireteam ROE")
	_assert(int(state.get("revision", 0)) == 1, "First host ROE commit creates revision one")
	_assert(bool(state.get("read_only", false)), "Published authoritative ROE state is read-only")
	_cleanup_context(context)
	await process_frame


func _test_authoritative_snapshot_replication() -> void:
	var host_context: Dictionary = _make_context("Task1082Host")
	var client_context: Dictionary = _make_context("Task1082Client")
	var host: Node = host_context["simulation_root"]
	var client: Node = client_context["simulation_root"]
	host.set("is_server_authoritative", true)
	host.call("set_peer_team", 1, "team_alpha")
	host.call("set_peer_role", 1, "host")
	var submission: Dictionary = Dictionary(host.call("submit_network_command_for_peer", _build_fire_rule_command("ft1", "return"), 1))
	_assert(bool(submission.get("accepted", false)), "Host can submit an own-team ROE command")
	host.call("_process_commands", host.call("_drain_queue", host.command_queue), 0.016)
	host.set("tick_counter", 7)
	var snapshot: Dictionary = Dictionary(host.call("build_multiplayer_snapshot"))
	var rules: Array = Array(snapshot.get("tactical_rules", []))
	_assert(rules.size() == 1, "Host snapshot carries one authoritative Fireteam ROE entry")
	var rule: Dictionary = Dictionary(rules[0]) if not rules.is_empty() else {}
	_assert(String(rule.get("fire_rule", "")) == "return" and int(rule.get("revision", 0)) == 1, "Host snapshot carries ROE and revision")

	var apply_result: Dictionary = Dictionary(client.call("apply_multiplayer_snapshot", snapshot))
	var client_rules: Array = Array(Dictionary(client.call("get_last_server_state")).get("tactical_rules", []))
	_assert(bool(apply_result.get("accepted", false)), "Client accepts the authoritative ROE snapshot")
	_assert(client.command_queue.is_empty() and client.effects_queue.is_empty(), "ROE snapshot creates no client-side gameplay commands")
	_assert(client_rules.size() == 1 and String(Dictionary(client_rules[0]).get("fire_rule", "")) == "return", "Client mirrors the host ROE as read-only state")
	_cleanup_context(host_context)
	_cleanup_context(client_context)
	await process_frame


func _test_mission_controller_applies_only_newer_authority_revisions() -> void:
	var mission: Node = MISSION_SCENE.instantiate()
	root.add_child(mission)
	await process_frame
	await process_frame
	var controller := mission.get_node_or_null("TacticalController")
	var simulation_root := mission.get_node_or_null("SimulationRoot")
	_assert(controller != null and simulation_root != null, "Mission fixture exposes controller and SimulationRoot")
	if controller == null or simulation_root == null:
		mission.queue_free()
		await process_frame
		return
	var first_count: int = int(controller.call("apply_authoritative_fire_rule_snapshot", [{"fireteam_id": "ft1", "fire_rule": "return", "revision": 4}]))
	var stale_count: int = int(controller.call("apply_authoritative_fire_rule_snapshot", [{"fireteam_id": "ft1", "fire_rule": "hold", "revision": 3}]))
	var sync: Dictionary = Dictionary(controller.call("get_fire_rule_authority_sync_snapshot"))
	_assert(first_count == 1 and stale_count == 0, "Mission controller applies only a newer host ROE revision")
	_assert(String(controller.call("get_fireteam_fire_rule", "ft1")) == "return", "Stale client snapshot cannot roll back visible Fireteam ROE")
	_assert(int(Dictionary(sync.get("revisions", {})).get("ft1", 0)) == 4, "Mission controller exposes the applied authority revision")
	_assert(simulation_root.command_queue.is_empty(), "Applying replicated ROE does not enqueue a client command")
	mission.queue_free()
	await process_frame


func _build_fire_rule_command(fireteam_id: String, fire_rule: String) -> Dictionary:
	return {
		"contract_category": "tactical_rule",
		"command_type": "set_fire_rule",
		"team_id": "team_alpha",
		"fireteam_id": fireteam_id,
		"fire_rule": fire_rule,
	}


func _make_context(name: String) -> Dictionary:
	var owner := Node.new()
	owner.name = name
	root.add_child(owner)
	var registry = UNIT_REGISTRY_SCRIPT.new()
	registry.name = "UnitRegistry"
	owner.add_child(registry)
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	owner.add_child(simulation_root)
	return {"root": owner, "simulation_root": simulation_root}


func _cleanup_context(context: Dictionary) -> void:
	var owner: Node = context.get("root", null)
	if owner != null:
		owner.queue_free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
