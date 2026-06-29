extends SceneTree

const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_622_host_client_command_authority_live_interaction_review.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const STATUS_HANDBOOK_REPORT_PATH: String = "res://docs/reports/project_status_handbook_2026_06_29.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const TASK_607_TEST_PATH: String = "res://scripts/tests/task_607_two_instance_host_client_runtime_smoke.gd"
const TASK_621_TEST_PATH: String = "res://scripts/tests/task_621_host_client_multiplayer_feel_review_bundle.gd"
const MANIFEST_PATH: String = "res://tmp/host_client_command_authority_live_interaction_review.json"

const PEER_TEAMS: Dictionary = {
	1: "team_alpha",
	2: "team_bravo",
}
const PEER_ROLES: Dictionary = {
	1: "host",
	2: "fireteam",
}
var _passed: int = 0
var _failed: int = 0
var _peer_fireteams: Dictionary = {
	1: PackedStringArray(["blue"]),
	2: PackedStringArray(["red"]),
}


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_622 Host Client Command Authority Live Interaction Review ===")
	_test_docs_reports_and_contract()
	var manifest: Dictionary = await _run_interaction_review()
	_write_json(MANIFEST_PATH, manifest)
	_test_manifest(manifest)
	_test_written_manifest()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_622: FAILED")
		quit(1)
		return
	print("TASK_622: ALL PASSED")
	quit(0)


func _test_docs_reports_and_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var handbook_text: String = _read_text(STATUS_HANDBOOK_REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_622 task file exists")
	_assert(task_text.contains("Host Client Command Authority Live Interaction Review"), "TASK_622 task names command authority review")
	_assert(status_text.contains("TASK_622 - Host Client Command Authority Live Interaction Review"), "Implementation status tracks TASK_622")
	_assert(roadmap_text.contains("TASK_622 - Host Client Command Authority Live Interaction Review (implementiert)"), "Roadmap marks TASK_622 implemented")
	_assert(contract_text.contains("Host-Client-Command-Authority-Live-Interaction-Review"), "Mission feedback contract documents TASK_622")
	_assert(report_text.contains("TASK_622 Host Client Command Authority Live Interaction Review"), "Rolling report tracks TASK_622")
	_assert(report_text.contains('latest_completed_task: "TASK_624 - Host Client Live Input Feedback Review"'), "Rolling report advances latest completed beyond TASK_622")
	_assert(handbook_text.contains("TASK_622 Authority-Review technisch belegt"), "Status handbook tracks TASK_622")
	_assert(handbook_text.contains('current_task: "TASK_624 - Host Client Live Input Feedback Review"'), "Status handbook current task advances beyond TASK_622")
	_assert(FileAccess.file_exists(TASK_607_TEST_PATH), "TASK_607 runtime smoke remains available")
	_assert(FileAccess.file_exists(TASK_621_TEST_PATH), "TASK_621 review bundle remains available")
	_test_report_export_fields(report_text, handbook_text)


func _test_report_export_fields(report_text: String, handbook_text: String) -> void:
	var required_export_keys: Array[String] = [
		"host_client_command_authority.task_id",
		"host_client_command_authority.manifest_path",
		"host_client_command_authority.peer2_bravo_command_accepted",
		"host_client_command_authority.peer2_alpha_command_rejected",
		"host_client_command_authority.alpha_reject_reason",
		"host_client_command_authority.state_mutation_rejected",
		"host_client_command_authority.state_mutation_reject_reason",
		"host_client_command_authority.client_snapshot_apply_accepted",
		"host_client_command_authority.client_received_bravo_unit",
		"host_client_command_authority.read_only",
		"host_client_command_authority.recommended_next_task",
		"host_client_command_authority.notes",
	]
	for export_key in required_export_keys:
		_assert(report_text.contains('data-export-key="%s"' % export_key), "Rolling report exports %s" % export_key)
	_assert(report_text.contains('data-note-key="notes.host_client_command_authority"'), "Rolling report exports TASK_622 free note")
	_assert(handbook_text.contains('data-export-key="status.task_622_done"'), "Status handbook exports TASK_622 checkbox")


func _run_interaction_review() -> Dictionary:
	var host_root: Node = Node.new()
	host_root.name = "Task622HostRoot"
	var client_root: Node = Node.new()
	client_root.name = "Task622ClientRoot"
	var host_unit_registry: Node = UNIT_REGISTRY_SCRIPT.new()
	host_unit_registry.name = "UnitRegistry"
	var client_unit_registry: Node = UNIT_REGISTRY_SCRIPT.new()
	client_unit_registry.name = "UnitRegistry"
	var host_simulation: Node = SIMULATION_ROOT_SCRIPT.new()
	host_simulation.name = "HostSimulationRoot"
	host_simulation.set("is_server_authoritative", true)
	host_simulation.set("unit_registry_path", NodePath("../UnitRegistry"))
	var client_simulation: Node = SIMULATION_ROOT_SCRIPT.new()
	client_simulation.name = "ClientSimulationRoot"
	client_simulation.set("is_server_authoritative", false)
	client_simulation.set("unit_registry_path", NodePath("../UnitRegistry"))
	host_root.add_child(host_unit_registry)
	host_root.add_child(host_simulation)
	client_root.add_child(client_unit_registry)
	client_root.add_child(client_simulation)
	root.add_child(host_root)
	root.add_child(client_root)
	await process_frame

	_apply_peer_assignments(host_simulation)
	var host_alpha_unit: Node2D = _register_probe_unit(host_root, host_unit_registry, host_simulation, "task622_host_alpha", "team_alpha", "blue", Vector2(-64.0, 0.0))
	var host_bravo_unit: Node2D = _register_probe_unit(host_root, host_unit_registry, host_simulation, "task622_host_bravo", "team_bravo", "red", Vector2(0.0, 0.0))
	_register_probe_unit(client_root, client_unit_registry, client_simulation, "task622_host_alpha", "team_alpha", "blue", Vector2(-180.0, 0.0))
	_register_probe_unit(client_root, client_unit_registry, client_simulation, "task622_host_bravo", "team_bravo", "red", Vector2(-120.0, 0.0))

	var accepted_bravo_command: Dictionary = Dictionary(host_simulation.call("submit_network_command_for_peer", _build_probe_move_command(host_bravo_unit, Vector2(96.0, 0.0)), 2))
	var queue_after_accept: int = _get_queue_count(host_simulation)
	var rejected_alpha_command: Dictionary = Dictionary(host_simulation.call("submit_network_command_for_peer", _build_probe_move_command(host_alpha_unit, Vector2(24.0, 0.0)), 2))
	var forbidden_state_command: Dictionary = _build_probe_move_command(host_bravo_unit, Vector2(128.0, 0.0))
	forbidden_state_command["damage"] = 99
	var rejected_state_command: Dictionary = Dictionary(host_simulation.call("submit_network_command_for_peer", forbidden_state_command, 2))
	host_simulation.call("_physics_process", 0.35)
	var queue_after_process: int = _get_queue_count(host_simulation)

	host_simulation.call(
		"set_multiplayer_snapshot_context",
		{
			"mission_result": {
				"result": "in_progress",
				"friendly_team_id": "team_alpha",
				"winning_team_id": "",
				"win_condition_type": "task622_authority_review",
				"objective_captured": false,
				"duration_seconds": 22.0,
			},
		}
	)
	var server_snapshot: Dictionary = Dictionary(host_simulation.call("build_multiplayer_snapshot"))
	var client_apply_result: Dictionary = Dictionary(client_simulation.call("apply_multiplayer_snapshot", server_snapshot))
	var client_last_server_state: Dictionary = Dictionary(client_simulation.call("get_last_server_state"))
	var network_snapshot: Dictionary = Dictionary(host_simulation.call("get_network_command_contract_snapshot"))
	var client_debug_snapshot: Dictionary = Dictionary(client_simulation.call("get_multiplayer_snapshot_debug_snapshot"))
	var manifest: Dictionary = {
		"schema": "sternenbuergerchen.host_client_command_authority_live_interaction_review.v1",
		"task_id": "TASK_622",
		"interaction_mode": "headless_authority_review",
		"source_bundle_path": "tmp/host_client_multiplayer_feel_review.json",
		"peer_assignments": {
			"peer_1": {
				"role": "host",
				"team": "team_alpha",
				"fireteams": ["blue"],
			},
			"peer_2": {
				"role": "fireteam",
				"team": "team_bravo",
				"fireteams": ["red"],
			},
		},
		"peer2_bravo_command_accepted": bool(accepted_bravo_command.get("accepted", false)),
		"peer2_bravo_command_reason": String(accepted_bravo_command.get("reason", "")),
		"peer2_alpha_command_rejected": not bool(rejected_alpha_command.get("accepted", true)),
		"alpha_reject_reason": String(rejected_alpha_command.get("reason", "")),
		"state_mutation_rejected": not bool(rejected_state_command.get("accepted", true)),
		"state_mutation_reject_reason": String(rejected_state_command.get("reason", "")),
		"host_queue_after_accept": queue_after_accept,
		"host_queue_after_process": queue_after_process,
		"host_queue_did_not_grow_after_process": queue_after_process <= queue_after_accept,
		"host_network_accept_count": int(network_snapshot.get("accepted_count", 0)),
		"host_network_reject_count": int(network_snapshot.get("rejected_count", 0)),
		"server_snapshot_built": String(server_snapshot.get("snapshot_type", "")) == "state",
		"server_snapshot_tick": int(server_snapshot.get("tick", -1)),
		"server_snapshot_has_bravo_unit": _snapshot_has_unit(server_snapshot, "task622_host_bravo"),
		"client_snapshot_apply_accepted": bool(client_apply_result.get("accepted", false)),
		"client_snapshot_apply_missing_unit_count": int(client_apply_result.get("missing_unit_count", -1)),
		"client_received_bravo_unit": _snapshot_has_unit(client_last_server_state, "task622_host_bravo"),
		"client_snapshot_apply_count": int(client_debug_snapshot.get("apply_count", 0)),
		"manual_review_required": true,
		"manual_review_done": false,
		"manual_window_checks": {
			"both_windows_visible": false,
			"peer2_bravo_button_path_checked": false,
			"peer2_alpha_reject_feedback_visible": false,
			"snapshot_sync_visible": false,
			"input_latency_notes": "",
			"performance_notes": "",
		},
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"recommended_next_task": "TASK_623 - Host Client Authority Visual Findings",
	}
	host_root.queue_free()
	client_root.queue_free()
	await process_frame
	return manifest


func _apply_peer_assignments(simulation_root: Node) -> void:
	simulation_root.call("set_peer_team_assignments", PEER_TEAMS)
	for peer_id_variant in PEER_ROLES.keys():
		simulation_root.call("set_peer_role", int(peer_id_variant), String(PEER_ROLES[peer_id_variant]))
	simulation_root.call("set_peer_fireteam_assignments", _peer_fireteams)


func _register_probe_unit(parent: Node, unit_registry: Node, simulation_root: Node, unit_id: String, team_id: String, fireteam_id: String, position: Vector2) -> Node2D:
	var unit: Node2D = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.team_id = team_id
	unit.fireteam_id = fireteam_id
	unit.global_position = position
	parent.add_child(unit)
	if unit_registry != null and unit_registry.has_method("register_unit"):
		unit_registry.call("register_unit", unit_id, unit)
	if simulation_root != null and simulation_root.has_method("register_known_unit"):
		simulation_root.call("register_known_unit", unit_id, unit)
	return unit


func _build_probe_move_command(unit: Node2D, target_position: Vector2) -> Dictionary:
	return {
		"command_type": UNIT_COMMAND_SCRIPT.TYPE_MOVE_TO_POSITION,
		"unit_id": unit.call("get_unit_id"),
		"team_id": unit.call("get_team_id"),
		"fireteam_id": unit.call("get_fireteam_id"),
		"target_position": target_position,
		"movement_posture": UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_TACTICAL,
		"weapon_posture": UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_READY,
		"priority": 5,
	}


func _test_manifest(manifest: Dictionary) -> void:
	_assert(String(manifest.get("schema", "")) == "sternenbuergerchen.host_client_command_authority_live_interaction_review.v1", "Manifest schema is stable")
	_assert(String(manifest.get("task_id", "")) == "TASK_622", "Manifest task id is TASK_622")
	_assert(bool(manifest.get("peer2_bravo_command_accepted", false)), "Peer 2 Bravo command is accepted")
	_assert(bool(manifest.get("peer2_alpha_command_rejected", false)), "Peer 2 Alpha command is rejected")
	_assert(String(manifest.get("alpha_reject_reason", "")) == "peer_team_mismatch", "Alpha reject reason is peer_team_mismatch")
	_assert(bool(manifest.get("state_mutation_rejected", false)), "State mutation command is rejected")
	_assert(String(manifest.get("state_mutation_reject_reason", "")).begins_with("state_mutation_key:damage"), "State mutation reject names damage key")
	_assert(int(manifest.get("host_queue_after_accept", 0)) >= 1, "Accepted command reached host queue")
	_assert(bool(manifest.get("host_queue_did_not_grow_after_process", false)), "Host queue did not grow after processing")
	_assert(int(manifest.get("host_network_accept_count", 0)) >= 1, "Host network snapshot records accepted command")
	_assert(int(manifest.get("host_network_reject_count", 0)) >= 2, "Host network snapshot records rejected commands")
	_assert(bool(manifest.get("server_snapshot_built", false)), "Server snapshot was built")
	_assert(bool(manifest.get("server_snapshot_has_bravo_unit", false)), "Server snapshot contains Bravo unit")
	_assert(bool(manifest.get("client_snapshot_apply_accepted", false)), "Client accepted server snapshot")
	_assert(int(manifest.get("client_snapshot_apply_missing_unit_count", -1)) == 0, "Client snapshot apply found all probe units")
	_assert(bool(manifest.get("client_received_bravo_unit", false)), "Client received Bravo unit state")
	_assert(bool(manifest.get("manual_review_required", false)), "Manifest keeps manual window review required")
	_assert(not bool(manifest.get("manual_review_done", true)), "Manifest does not mark manual review done")
	_assert(bool(manifest.get("read_only", false)), "Manifest remains read-only")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "Manifest does not set gameplay truth")
	_assert(String(manifest.get("recommended_next_task", "")) == "TASK_623 - Host Client Authority Visual Findings", "Manifest recommends TASK_623")


func _test_written_manifest() -> void:
	_assert(FileAccess.file_exists(MANIFEST_PATH), "TASK_622 manifest was written")
	var written: Dictionary = _read_json(MANIFEST_PATH)
	_assert(String(written.get("schema", "")) == "sternenbuergerchen.host_client_command_authority_live_interaction_review.v1", "Written manifest schema is stable")
	_assert(bool(written.get("peer2_bravo_command_accepted", false)), "Written manifest records Bravo acceptance")
	_assert(bool(written.get("client_snapshot_apply_accepted", false)), "Written manifest records client snapshot apply")


func _get_queue_count(simulation_root: Node) -> int:
	if simulation_root == null:
		return 0
	var queue_variant: Variant = simulation_root.get("command_queue")
	if typeof(queue_variant) != TYPE_ARRAY:
		return 0
	return Array(queue_variant).size()


func _snapshot_has_unit(snapshot: Dictionary, unit_id: String) -> bool:
	for unit_variant in Array(snapshot.get("units", [])):
		var unit_snapshot: Dictionary = Dictionary(unit_variant)
		if String(unit_snapshot.get("unit_id", "")).strip_edges() == unit_id:
			return true
	return false


func _write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_assert(false, "Could not open TASK_622 manifest path for writing")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func _read_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return Dictionary(parsed)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
