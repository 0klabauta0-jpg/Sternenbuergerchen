class_name FrontierProbeHostClientHandoffContract
extends RefCounted


static func build_snapshot(data: Dictionary) -> Dictionary:
	var ownership_snapshot: Dictionary = Dictionary(data.get("ownership_snapshot", {})).duplicate(true)
	var pre_session_snapshot: Dictionary = Dictionary(data.get("pre_session_snapshot", {})).duplicate(true)
	var post_session_snapshot: Dictionary = Dictionary(data.get("post_session_snapshot", {})).duplicate(true)
	var assignments: Dictionary = Dictionary(data.get("assignments", {})).duplicate(true)
	var host_network_snapshot: Dictionary = Dictionary(data.get("host_network_snapshot", {})).duplicate(true)
	var accepted_bravo_command: Dictionary = Dictionary(data.get("accepted_bravo_command", {})).duplicate(true)
	var rejected_alpha_command: Dictionary = Dictionary(data.get("rejected_alpha_command", {})).duplicate(true)
	var rejected_state_mutation_command: Dictionary = Dictionary(data.get("rejected_state_mutation_command", {})).duplicate(true)
	var server_snapshot: Dictionary = Dictionary(data.get("server_snapshot", {})).duplicate(true)
	var client_apply_result: Dictionary = Dictionary(data.get("client_apply_result", {})).duplicate(true)
	var client_debug: Dictionary = Dictionary(data.get("client_debug", {})).duplicate(true)
	var client_last_server_state: Dictionary = Dictionary(data.get("client_last_server_state", {})).duplicate(true)
	var host_bravo_position: Vector2 = _coerce_vector2(data.get("host_bravo_position", Vector2.ZERO), Vector2.ZERO)
	var client_bravo_position: Vector2 = _coerce_vector2(data.get("client_bravo_position", Vector2.ZERO), Vector2.ZERO)
	var peer_teams: Dictionary = Dictionary(assignments.get("peer_teams", {}))
	var peer_roles: Dictionary = Dictionary(assignments.get("peer_roles", {}))
	var peer_fireteams: Dictionary = Dictionary(assignments.get("peer_fireteams", {}))
	var network_peer_teams: Dictionary = Dictionary(host_network_snapshot.get("peer_teams", {}))
	var network_peer_fireteams: Dictionary = Dictionary(host_network_snapshot.get("peer_fireteams", {}))
	var server_objective: Dictionary = Dictionary(server_snapshot.get("objective", {}))
	var server_dropship: Dictionary = Dictionary(server_snapshot.get("dropship", {}))
	var server_result: Dictionary = Dictionary(server_snapshot.get("mission_result", {}))
	var client_objective: Dictionary = Dictionary(client_last_server_state.get("objective", {}))
	var client_result: Dictionary = Dictionary(client_last_server_state.get("mission_result", {}))
	var checks: Array = [
		_build_check(
			"ownership_gate_passes",
			String(ownership_snapshot.get("gate", "")) == "pass",
			"TASK_555 ownership snapshot remains green inside the host/client handoff."
		),
		_build_check(
			"session_ready_before_start",
			bool(pre_session_snapshot.get("can_start_mission", false))
				and int(pre_session_snapshot.get("connected_count", 0)) >= 2
				and int(pre_session_snapshot.get("ready_count", 0)) >= 2,
			"Host and client are connected and ready before mission start."
		),
		_build_check(
			"mission_start_handoff_requested",
			bool(data.get("start_result", false))
				and bool(post_session_snapshot.get("mission_started", false))
				and String(post_session_snapshot.get("connection_state", "")) == "mission",
			"Host session enters mission state and emits start assignments."
		),
		_build_check(
			"assignments_include_alpha_host_and_bravo_client",
			String(peer_teams.get(1, peer_teams.get("1", ""))) == "team_alpha"
				and String(peer_teams.get(2, peer_teams.get("2", ""))) == "team_bravo"
				and String(peer_roles.get(2, peer_roles.get("2", ""))) == "commander"
				and _variant_string_array_has(peer_fireteams.get(2, peer_fireteams.get("2", [])), "red"),
			"Session assignments preserve Alpha host and Bravo client authority."
		),
		_build_check(
			"simulation_root_received_session_assignments",
			String(network_peer_teams.get(1, network_peer_teams.get("1", ""))) == "team_alpha"
				and String(network_peer_teams.get(2, network_peer_teams.get("2", ""))) == "team_bravo"
				and _variant_string_array_has(network_peer_fireteams.get(2, network_peer_fireteams.get("2", [])), "red"),
			"Host SimulationRoot received the same session assignments."
		),
		_build_check(
			"bravo_client_command_accepted",
			bool(accepted_bravo_command.get("accepted", false))
				and String(accepted_bravo_command.get("team_id", "")) == "team_bravo"
				and host_bravo_position.x > 0.0,
			"Peer 2 can command Bravo and the server applies the accepted movement."
		),
		_build_check(
			"alpha_foreign_team_command_rejected",
			not bool(rejected_alpha_command.get("accepted", true))
				and _rejection_reason_is_one_of(String(rejected_alpha_command.get("reason", "")), PackedStringArray(["peer_team_mismatch", "unit_team_mismatch"])),
			"Peer 2 cannot command Alpha units."
		),
		_build_check(
			"state_mutation_command_rejected",
			not bool(rejected_state_mutation_command.get("accepted", true))
				and String(rejected_state_mutation_command.get("reason", "")).begins_with("state_mutation_key"),
			"Forbidden client state mutation keys remain rejected."
		),
		_build_check(
			"server_snapshot_contains_frontier_objective_result",
			String(server_objective.get("owning_team_id", "")) == "team_alpha"
				and String(server_result.get("result", "")) == "victory"
				and String(server_result.get("winning_team_id", "")) == "team_alpha"
				and String(server_dropship.get("state", "")) == "departed",
			"Server snapshot carries Frontier Probe objective, victory result and departed cargo state."
		),
		_build_check(
			"client_accepts_server_snapshot",
			bool(client_apply_result.get("accepted", false))
				and int(client_debug.get("missing_unit_count", -1)) == 0
				and int(client_debug.get("last_applied_tick", -1)) == int(server_snapshot.get("tick", -2))
				and client_bravo_position.x > 0.0,
			"Client accepts the server snapshot and sees replicated Bravo movement."
		),
		_build_check(
			"client_receives_objective_and_result",
			String(client_objective.get("owning_team_id", "")) == "team_alpha"
				and String(client_result.get("result", "")) == "victory"
				and String(client_result.get("winning_team_id", "")) == "team_alpha",
			"Client last server state mirrors ObjectiveStatus and MissionResult."
		),
		_build_check(
			"read_only",
			not bool(ownership_snapshot.get("ui_sets_gameplay_truth", true))
				and not bool(data.get("contract_sets_gameplay_truth", false)),
			"Contract helper only evaluates handoff data and does not mutate gameplay truth."
		),
	]
	var failed_checks: Array = []
	for check_variant in checks:
		var check: Dictionary = Dictionary(check_variant)
		if not bool(check.get("passed", false)):
			failed_checks.append(String(check.get("id", "")))
	return {
		"task_id": "TASK_556",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"runtime_authority": "SimulationRoot",
		"handoff_contract": "FrontierProbeHostClientHandoffContract",
		"ownership_snapshot": ownership_snapshot,
		"pre_session_snapshot": pre_session_snapshot,
		"post_session_snapshot": post_session_snapshot,
		"assignments": assignments,
		"host_network_snapshot": host_network_snapshot,
		"server_snapshot": server_snapshot,
		"client_debug": client_debug,
		"client_last_server_state": client_last_server_state,
		"checks": checks,
		"failed_checks": failed_checks,
		"gate": "pass" if failed_checks.is_empty() else "review",
	}


static func _build_check(check_id: String, passed: bool, message: String) -> Dictionary:
	return {
		"id": check_id,
		"passed": passed,
		"message": message,
	}


static func _variant_string_array_has(value: Variant, expected_value: String) -> bool:
	var normalized_expected: String = expected_value.strip_edges()
	for entry_variant in Array(value):
		if String(entry_variant).strip_edges() == normalized_expected:
			return true
	return false


static func _rejection_reason_is_one_of(reason: String, allowed_reasons: PackedStringArray) -> bool:
	return allowed_reasons.has(reason.strip_edges())


static func _coerce_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if typeof(value) == TYPE_VECTOR2:
		return value
	if typeof(value) == TYPE_VECTOR3:
		var vector3: Vector3 = value
		return Vector2(vector3.x, vector3.z)
	return fallback
