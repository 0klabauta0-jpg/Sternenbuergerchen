extends SceneTree
## Real localhost RPC -> contract -> production SimulationRoot/Driver/TestUnit.
## Synthetic authored scenario and private profile; no external connections.
const SIM = preload("res://scripts/core/simulation_root.gd")
const DRIVER = preload("res://scripts/tests/mission_combat_loop_driver.gd")
const UNIT = preload("res://scripts/npc/test_unit.gd")
const REGISTRY = preload("res://scripts/registries/unit_registry.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const CONTRACT = preload("res://scripts/multiplayer/multiplayer_command_contract.gd")
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const MARKER := Vector2(1000, 1000)

class Setup extends Node:
	var _loaded_terrain_map_data: RefCounted
	var _mission_scenario: RefCounted

class ResourceGate extends Node:
	var allow_completion := false
	var completions := 0
	func accept_progress(_payload: Dictionary, complete: bool) -> Dictionary:
		if complete and not allow_completion:
			return {"accepted": false, "reason": "resources_not_ready"}
		if complete:
			completions += 1
		return {"accepted": true}

var passed := 0
var failed := 0
var accepts: Array = []
var responses: Array = []

func _init() -> void:
	if GUARD.require_isolated_user_data():
		call_deferred("_run")

func check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print("PASS " if value else "FAIL ", label)

func scenario() -> Dictionary:
	return {
		"flow_steps": [
			{"step_id":"enable", "objective_type":"computer_hold", "operator_team_id":"team_alpha", "required_state":"enabled", "min_hold_seconds":0.0, "target_marker_id":"terminal"},
			{"step_id":"upload", "objective_type":"computer_hold", "operator_team_id":"team_alpha", "required_state":"uploaded", "min_hold_seconds":30.0, "requires_step_id":"enable", "target_marker_id":"terminal"},
		],
		"interaction_points": [
			binding("enable_terminal", "enable", 0.0, "enabled"),
			binding("upload_terminal", "upload", 30.0, "uploaded"),
			binding("aux_terminal", "", 2.0, "operated"),
			binding("zero_terminal", "", 0.0, "operated"),
			binding("binding_locked", "", 1.0, "operated", "enable"),
		]
	}

func binding(id: String, step: String, duration: float, state: String, prerequisite: String = "") -> Dictionary:
	return {"interaction_id":id, "interaction_type":"computer", "marker_id":"terminal", "duration_seconds":duration, "radius_world":48.0, "step_id":step, "gate_id":step, "required_state":state, "required_order":"take", "required_team":"team_alpha", "requires_step_id":prerequisite}

func fixture(label: String, api: SceneMultiplayer, authority: bool) -> Dictionary:
	var scope := Node.new()
	scope.name = label
	root.add_child(scope)
	set_multiplayer(api, scope.get_path())
	var registry = REGISTRY.new()
	registry.name = "UnitRegistry"
	scope.add_child(registry)
	var setup := Setup.new()
	setup.name = "MissionSetup"
	setup._loaded_terrain_map_data = MAP.new()
	setup._loaded_terrain_map_data.call("set_marker_position", "terminal", MARKER)
	scope.add_child(setup)
	var sim = SIM.new()
	sim.name = "SimulationRoot"
	sim.unit_registry_path = NodePath("../UnitRegistry")
	sim.is_server_authoritative = true
	scope.add_child(sim)
	sim.set_process(false)
	sim.set_physics_process(false)
	var unit = UNIT.new()
	unit.name = "Own"
	unit.unit_id = "review_own"
	unit.team_id = "team_alpha"
	unit.fireteam_id = "blue"
	unit.position = Vector2(32, 32)
	scope.add_child(unit)
	unit.set_process(false)
	unit.set_physics_process(false)
	registry.register_unit(unit.unit_id, unit)
	sim.register_known_unit(unit.unit_id, unit)
	var driver = DRIVER.new()
	driver.name = "CombatLoopDriver"
	driver.preview_mode = true
	driver.simulation_root_path = NodePath("../SimulationRoot")
	driver.friendly_unit_paths.assign([NodePath("../Own")])
	scope.add_child(driver)
	driver.set_process(false)
	driver.set_physics_process(false)
	if authority:
		driver.configure_scenario_runtime_gates(scenario())
	return {"scope":scope, "sim":sim, "unit":unit, "driver":driver, "registry":registry, "setup":setup}

func intent(id: String) -> Dictionary:
	return {"contract_category":"commander_command", "command_type":"take", "unit_id":"review_own", "team_id":"team_alpha", "fireteam_id":"blue", "target_position":Vector2(32,32), "source_context":"mission_interaction_use_intent_command", "interaction_id":id}

func send(client: Dictionary, command: Dictionary) -> Dictionary:
	var before := responses.size()
	client.sim.submit_multiplayer_command(command)
	var deadline := Time.get_ticks_msec() + 3000
	while responses.size() == before and Time.get_ticks_msec() < deadline:
		await create_timer(0.01).timeout
	check(responses.size() == before + 1, "RPC result arrives exactly once")
	return Dictionary(responses.back()) if responses.size() > before else {}

func apply_queued(host: Dictionary) -> void:
	var commands: Array = host.sim.command_queue.duplicate(true)
	host.sim.command_queue.clear()
	host.sim._process_commands(commands, 0.1)

func pending(host: Dictionary, id: String) -> Dictionary:
	return Dictionary(host.driver.get_pending_network_mission_interaction_snapshot().entries.get(id, {}))

func complete(host: Dictionary, id: String) -> bool:
	return bool(host.driver.get_mission_interaction_runtime_states().get(id, {}).get("complete", false))

func _run() -> void:
	var server := ENetMultiplayerPeer.new()
	check(server.create_server(0, 1) == OK, "localhost host starts")
	var host_api := SceneMultiplayer.new()
	host_api.multiplayer_peer = server
	var peer := ENetMultiplayerPeer.new()
	check(peer.create_client("127.0.0.1", server.host.get_local_port()) == OK, "localhost client starts")
	var client_api := SceneMultiplayer.new()
	client_api.multiplayer_peer = peer
	var host := fixture("Host", host_api, true)
	var client := fixture("Client", client_api, false)
	var deadline := Time.get_ticks_msec() + 5000
	while (peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED or host_api.get_peers().is_empty()) and Time.get_ticks_msec() < deadline:
		await create_timer(0.01).timeout
	check(peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED and host_api.get_peers().size() == 1, "actual ENet handshake")
	var peer_id := client_api.get_unique_id()
	host.sim.set_peer_team(peer_id, "team_alpha")
	host.sim.set_peer_role(peer_id, "fireteam")
	host.sim.set_peer_fireteams(peer_id, PackedStringArray(["blue"]))
	var context := {"schema":"multiplayer.runtime_context.v1", "runtime_token":"ab".repeat(16), "map_id":"astra_network_fixes", "map_hash":"a".repeat(64)}
	check(host.sim.bind_multiplayer_runtime_context(context, "team_alpha").ok and client.sim.bind_multiplayer_runtime_context(context, "team_alpha").ok, "same verified runtime context bound")
	host.sim.network_command_accepted.connect(func(command: Dictionary, sender: int): accepts.append({"command":command, "sender":sender}))
	client.sim.network_command_result_received.connect(func(result: Dictionary): responses.append(result))
	await test_unit_intent(host, client, peer_id)
	await test_authored_interactions(host, client)
	await test_parallel_interactions(host, client, peer_id)
	await test_lifecycle(host, client)
	server.close()
	peer.close()
	host.scope.free()
	client.scope.free()
	await process_frame
	print("ASTRA_NETWORK_FIXES passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)

func test_unit_intent(host: Dictionary, client: Dictionary, peer_id: int) -> void:
	var hold := {"command_type":"hold_position", "unit_id":"review_own", "team_id":"team_alpha", "fireteam_id":"blue"}
	for field in CONTRACT.HOST_UNIT_POLICY_FIELDS:
		hold[field] = 1000.0
	var result := await send(client, hold)
	check(result.get("accepted", false) and accepts.back().sender == peer_id, "own fireteam Hold remains accepted through real RPC")
	var canonical: Dictionary = accepts.back().command
	var absent := true
	for field in CONTRACT.HOST_UNIT_POLICY_FIELDS:
		absent = absent and not canonical.has(field)
	check(absent, "all derived unit policy fields are absent from committed network intent")
	apply_queued(host)
	var status = host.unit.get_runtime_status()
	check(host.unit.get_move_speed_factor() == 1.0 and host.unit.get_sight_range_factor() == 1.0 and host.unit.get_attack_bonus() == 0.0 and status.cover_score == 0.0 and status.aim_readiness_percent == 0.0, "actual TestUnit cannot acquire client combat or movement modifiers")
	var applied_command = host.unit.get_current_unit_command()
	check(applied_command.team_target_support_percent == 0.0 and applied_command.contact_initiative_seconds == 0.0 and applied_command.engagement_range_factor == 1.0 and applied_command.engagement_range_policy.is_empty() and applied_command.posture_policy_id.is_empty(), "committed UnitCommand retains host defaults for remaining derived policy fields")
	var internal := {"command_type":"hold_position", "unit_id":"review_own", "team_id":"team_alpha", "move_speed_factor":0.75, "attack_bonus":2.0, "cover_score":3.0}
	host.sim.enqueue_command(internal)
	apply_queued(host)
	check(host.unit.get_move_speed_factor() == 0.75 and host.unit.get_attack_bonus() == 2.0 and host.unit.get_runtime_status().cover_score == 3.0, "trusted internal policy commands preserve derived modifiers")
	var move := {"command_type":"move_to_position", "unit_id":"review_own", "team_id":"team_alpha", "fireteam_id":"blue", "target_position":Vector2(200,32)}
	result = await send(client, move)
	var before: Vector2 = host.unit.global_position
	apply_queued(host)
	check(result.get("accepted", false) and host.unit.global_position != before, "legitimate remote Move reaches production movement")
	host.sim.command_queue.clear()
	move["target_position"] = Vector2(INF, 0)
	result = await send(client, move)
	check(not result.get("accepted", true), "non-finite network movement target is rejected")

func test_authored_interactions(host: Dictionary, client: Dictionary) -> void:
	var result := await send(client, intent("unknown_terminal"))
	check(result.get("reason", "") == "interaction_unknown", "unknown interaction cannot create host progress")
	result = await send(client, intent("upload_terminal"))
	check(result.get("reason", "") == "interaction_prerequisite_incomplete", "gate prerequisite is enforced even when binding omits it")
	result = await send(client, intent("binding_locked"))
	check(result.get("reason", "") == "interaction_prerequisite_incomplete", "binding prerequisite is enforced without a matching gate")
	var forged := intent("enable_terminal")
	forged.merge({"target_position":host.unit.global_position, "interaction_radius_world":100000.0, "duration_seconds":0.0, "step_id":"upload", "gate_id":"upload", "required_state":"uploaded", "interaction_type":"hold_zone"}, true)
	result = await send(client, forged)
	check(result.get("accepted", false), "valid interaction intent can approach from outside its radius")
	var first: Dictionary = accepts.back().command
	check(first.target_position == MARKER and first.interaction_radius_world == 48.0 and first.step_id == "enable" and first.gate_id == "enable" and first.required_state == "enabled" and first.interaction_type == "computer", "host replaces target radius step gate state and type from authored binding")
	host.driver._advance_pending_network_mission_interactions(60.0)
	check(not complete(host, "enable_terminal") and pending(host, "enable_terminal").hold_seconds == 0.0, "forged radius and local target cannot complete distant zero-duration interaction")
	host.unit.global_position = MARKER
	host.driver._advance_pending_network_mission_interactions(0.01)
	check(complete(host, "enable_terminal") and not host.driver.get_mission_scenario_runtime_gate_snapshot().all_gates_complete, "authored zero-duration interaction completes only its own gate at actual marker")
	forged = intent("upload_terminal")
	forged.merge({"duration_seconds":0.0, "interaction_radius_world":100000.0, "required_state":"enabled", "step_id":"enable"}, true)
	result = await send(client, forged)
	check(result.get("accepted", false) and pending(host, "upload_terminal").duration_seconds == 30.0, "host duration defeats immediate-completion payload after prerequisite")
	host.driver._advance_pending_network_mission_interactions(10.0)
	check(not complete(host, "upload_terminal") and pending(host, "upload_terminal").hold_seconds == 10.0, "real host hold advances without early completion")
	result = await send(client, forged)
	check(result.get("accepted", false) and pending(host, "upload_terminal").hold_seconds == 10.0, "same operator retry preserves earned host progress")
	host.unit.global_position = MARKER + Vector2(49, 0)
	host.driver._advance_pending_network_mission_interactions(25.0)
	check(not complete(host, "upload_terminal") and pending(host, "upload_terminal").hold_seconds == 0.0, "leaving authored radius resets uninterrupted hold")
	host.unit.global_position = MARKER
	host.driver._advance_pending_network_mission_interactions(29.0)
	check(not complete(host, "upload_terminal"), "duration remains required after re-entry")
	host.driver._advance_pending_network_mission_interactions(1.0)
	check(complete(host, "upload_terminal") and host.driver.get_mission_scenario_runtime_gate_snapshot().all_gates_complete, "valid full host hold completes objective")
	result = await send(client, intent("upload_terminal"))
	check(result.get("reason", "") == "interaction_already_complete" and pending(host, "upload_terminal").is_empty(), "completed interaction cannot be replayed")

func test_parallel_interactions(host: Dictionary, client: Dictionary, peer_id: int) -> void:
	var other = UNIT.new()
	other.name = "Other"
	other.unit_id = "review_other"
	other.team_id = "team_alpha"
	other.fireteam_id = "red"
	other.position = MARKER
	host.scope.add_child(other)
	other.set_process(false)
	other.set_physics_process(false)
	host.registry.register_unit(other.unit_id, other)
	host.sim.register_known_unit(other.unit_id, other)
	host.sim.set_peer_fireteams(peer_id, PackedStringArray(["blue", "red"]))
	var result := await send(client, intent("aux_terminal"))
	check(result.get("accepted", false), "Blue starts its authored interaction")
	var red := intent("binding_locked")
	red["unit_id"] = "review_other"
	red["fireteam_id"] = "red"
	result = await send(client, red)
	check(result.get("accepted", false) and host.driver.get_pending_network_mission_interaction_snapshot().pending_count == 2, "two real Fireteams own distinct host-authored interactions concurrently")
	var conflict: Dictionary = red.duplicate(true)
	conflict["interaction_id"] = "aux_terminal"
	conflict["duration_seconds"] = 0.0
	conflict["interaction_radius_world"] = 100000.0
	result = await send(client, conflict)
	check(result.get("reason", "") == "interaction_reserved_by_other_fireteam" and pending(host, "aux_terminal").fireteam_id == "blue" and pending(host, "binding_locked").fireteam_id == "red", "assigned but competing Fireteam cannot steal reservation or alter either owner")
	host.driver._advance_pending_network_mission_interactions(0.5)
	check(pending(host, "aux_terminal").hold_seconds == 0.5 and pending(host, "binding_locked").hold_seconds == 0.5, "both legitimate host-owned timers advance independently")
	# Rebinding a peer preserves ownership by Fireteam and actual operator.
	host.sim.set_peer_team(peer_id + 1, "team_alpha")
	host.sim.set_peer_role(peer_id + 1, "fireteam")
	host.sim.set_peer_fireteams(peer_id + 1, PackedStringArray(["blue"]))
	result = host.sim.submit_network_command_for_peer(intent("aux_terminal"), peer_id + 1)
	check(result.get("accepted", false) and pending(host, "aux_terminal").hold_seconds == 0.5 and pending(host, "aux_terminal").duration_seconds == 2.0, "peer rebind preserves valid Fireteam hold and authored duration")
	host.driver.configure_scenario_runtime_gates(scenario())
	host.sim.command_queue.clear()
	host.registry.unregister_unit(other.unit_id)
	other.free()
	host.sim.set_peer_fireteams(peer_id, PackedStringArray(["blue"]))

func test_lifecycle(host: Dictionary, client: Dictionary) -> void:
	var result := await send(client, intent("aux_terminal"))
	check(result.get("accepted", false), "independent authored interaction accepts")
	host.sim.command_queue.clear()
	host.sim.enqueue_command({"command_type":"hold_position", "unit_id":"review_own", "team_id":"team_alpha", "source_command_type":"take", "target_position":MARKER})
	apply_queued(host)
	host.driver._advance_pending_network_mission_interactions(0.5)
	check(pending(host, "aux_terminal").get("hold_seconds", 0.0) == 0.5, "host realization of the same Use keeps pending hold")
	host.sim.enqueue_command({"command_type":"hold_position", "unit_id":"review_own", "team_id":"team_alpha"})
	apply_queued(host)
	host.driver._advance_pending_network_mission_interactions(5.0)
	check(not complete(host, "aux_terminal") and pending(host, "aux_terminal").is_empty(), "actual internal order replacement cancels hold while still in radius")
	result = await send(client, intent("aux_terminal"))
	host.driver._advance_pending_network_mission_interactions(0.5)
	result = await send(client, {"command_type":"hold_position", "unit_id":"review_own", "team_id":"team_alpha", "fireteam_id":"blue"})
	check(result.get("accepted", false) and pending(host, "aux_terminal").is_empty() and not complete(host, "aux_terminal"), "accepted remote Stop cancels prior interaction immediately")
	host.sim.command_queue.clear()
	result = await send(client, intent("aux_terminal"))
	host.driver._advance_pending_network_mission_interactions(1.0)
	host.unit._set_vital_status("down", 0, 0)
	host.driver._advance_pending_network_mission_interactions(5.0)
	check(not complete(host, "aux_terminal") and pending(host, "aux_terminal").is_empty(), "downed operator cancels progress and releases reservation")
	result = await send(client, intent("aux_terminal"))
	check(result.get("reason", "") == "interaction_unit_unavailable", "downed operator cannot restart interaction")
	host.unit._set_vital_status("fit", 100, 0)
	result = await send(client, intent("aux_terminal"))
	host.registry.unregister_unit("review_own")
	host.driver._advance_pending_network_mission_interactions(5.0)
	check(result.get("accepted", false) and not complete(host, "aux_terminal") and pending(host, "aux_terminal").is_empty(), "unregistered unit cannot continue through known-unit fallback")
	host.registry.register_unit("review_own", host.unit)
	result = await send(client, intent("zero_terminal"))
	host.unit._set_vital_status("down", 0, 0)
	host.driver._advance_pending_network_mission_interactions(1.0)
	check(result.get("accepted", false) and not complete(host, "zero_terminal"), "cancelling zero-duration interaction never publishes completion")
	host.unit._set_vital_status("fit", 100, 0)
	host.unit.set_meta("dropship_embarked", true)
	result = await send(client, intent("aux_terminal"))
	check(result.get("reason", "") == "interaction_unit_unavailable", "fit but embarked operator cannot start a ground interaction")
	host.unit.set_meta("dropship_embarked", false)
	result = await send(client, intent("aux_terminal"))
	host.driver._advance_pending_network_mission_interactions(1.0)
	host.unit.set_meta("dropship_embarked", true)
	host.driver._advance_pending_network_mission_interactions(2.0)
	check(result.get("accepted", false) and not complete(host, "aux_terminal") and pending(host, "aux_terminal").is_empty(), "embarking mid-hold cancels progress even while registry and position remain valid")
	host.unit.set_meta("dropship_embarked", false)
	result = await send(client, intent("aux_terminal"))
	host.driver.configure_scenario_runtime_gates(scenario())
	check(result.get("accepted", false) and host.driver.get_pending_network_mission_interaction_snapshot().pending_count == 0, "scenario replacement clears old reservations and progress")
	host.setup._loaded_terrain_map_data.remove_marker("terminal")
	result = await send(client, intent("aux_terminal"))
	check(result.get("reason", "") == "interaction_marker_unavailable", "missing host marker fails closed")
	host.setup._loaded_terrain_map_data.set_marker_position("terminal", MARKER)
	host.driver._combat_finished = true
	result = await send(client, intent("aux_terminal"))
	check(result.get("reason", "") == "interaction_mission_inactive", "resolved mission rejects further interaction")
	host.driver._combat_finished = false
	var gate := ResourceGate.new()
	gate.name = "LocationResources"
	host.scope.add_child(gate)
	result = await send(client, intent("aux_terminal"))
	host.driver._advance_pending_network_mission_interactions(2.0)
	check(result.get("accepted", false) and not complete(host, "aux_terminal") and not pending(host, "aux_terminal").is_empty(), "resource owner rejection cannot be converted into completion or lost pending work")
	gate.allow_completion = true
	host.driver._advance_pending_network_mission_interactions(0.1)
	host.driver._advance_pending_network_mission_interactions(0.1)
	check(complete(host, "aux_terminal") and pending(host, "aux_terminal").is_empty() and gate.completions == 1, "resource owner allows one completion once ready")
