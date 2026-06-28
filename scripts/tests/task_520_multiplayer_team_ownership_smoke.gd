extends SceneTree

const VERTICAL_SLICE_CONTRACT_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_vertical_slice_contract.gd")
const TEAM_OWNERSHIP_CONTRACT_SCRIPT: GDScript = preload("res://scripts/mission/mission_multiplayer_team_ownership_contract.gd")
const MULTIPLAYER_SESSION_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_session.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const TASK_PATH: String = "res://docs/tasks/TASK_520_multiplayer_team_ownership_smoke.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const TEAM_OWNERSHIP_PATH: String = "res://scripts/mission/mission_multiplayer_team_ownership_contract.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_520 Multiplayer Team Ownership Smoke ===")
	_test_docs_and_wiring()
	_test_vertical_slice_team_assignability()
	_test_singleplayer_keeps_bravo_npc()
	await _test_pvp_session_assigns_alpha_and_bravo_peers()
	_test_invalid_npc_assignment_is_flagged()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_520: FAILED")
		quit(1)
		return
	print("TASK_520: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_520 task file exists")
	_assert(_read_text(TASK_PATH).contains("## Status: IMPLEMENTIERT"), "TASK_520 task file marks implementation")
	_assert(_read_text(STATUS_PATH).contains("TASK_520 - Multiplayer Team Ownership Smoke"), "Implementation status tracks TASK_520")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_520 - Multiplayer Team Ownership Smoke"), "Roadmap lists TASK_520")
	_assert(_read_text(REPORT_PATH).contains("TASK_520 - Multiplayer Team Ownership Smoke"), "Review workbench tracks TASK_520")
	_assert(FileAccess.file_exists(TEAM_OWNERSHIP_PATH), "Mission multiplayer team ownership contract exists")
	var source: String = _read_text(TEAM_OWNERSHIP_PATH)
	_assert(source.contains("build_team_ownership_snapshot"), "Team ownership contract exposes snapshot builder")
	_assert(source.contains("ui_sets_gameplay_truth"), "Team ownership snapshot marks UI as read-only")


func _test_vertical_slice_team_assignability() -> void:
	var slice: Dictionary = _load_slice()
	var alpha: Dictionary = _team_slot(slice, "team_alpha")
	var bravo: Dictionary = _team_slot(slice, "team_bravo")
	_assert(not alpha.is_empty(), "Vertical slice keeps team_alpha slot")
	_assert(not bravo.is_empty(), "Vertical slice keeps team_bravo slot")
	_assert(not bool(alpha.get("npc_owned", true)), "Alpha is player-owned by default")
	_assert(bool(bravo.get("npc_owned", false)), "Bravo remains NPC-owned by default")
	_assert(PackedStringArray(alpha.get("player_assignable_modes", PackedStringArray())).has("multiplayer_pvp"), "Alpha is assignable in PvP")
	_assert(PackedStringArray(bravo.get("player_assignable_modes", PackedStringArray())).has("multiplayer_pvp"), "Bravo is explicitly assignable in PvP")
	_assert(not PackedStringArray(bravo.get("player_assignable_modes", PackedStringArray())).has("singleplayer"), "Bravo is not player-assignable in singleplayer")


func _test_singleplayer_keeps_bravo_npc() -> void:
	var snapshot: Dictionary = Dictionary(TEAM_OWNERSHIP_CONTRACT_SCRIPT.call("build_team_ownership_snapshot", _load_slice(), {}, "singleplayer"))
	var alpha: Dictionary = Dictionary(TEAM_OWNERSHIP_CONTRACT_SCRIPT.call("get_team_entry", snapshot, "team_alpha"))
	var bravo: Dictionary = Dictionary(TEAM_OWNERSHIP_CONTRACT_SCRIPT.call("get_team_entry", snapshot, "team_bravo"))
	_assert(bool(snapshot.get("valid", false)), "Singleplayer ownership snapshot is valid")
	_assert(not bool(alpha.get("npc_controlled", true)), "Singleplayer Alpha is controlled by host/player")
	_assert(int(alpha.get("owner_peer_id", 0)) == 1, "Singleplayer Alpha defaults to host peer")
	_assert(bool(bravo.get("npc_controlled", false)), "Singleplayer Bravo stays NPC controlled")
	_assert(int(bravo.get("owner_peer_id", -1)) == 0, "NPC Bravo is scenario-owned")
	_assert(PackedStringArray(snapshot.get("npc_team_ids", PackedStringArray())).has("team_bravo"), "Snapshot lists Bravo as NPC team")


func _test_pvp_session_assigns_alpha_and_bravo_peers() -> void:
	var session: Node = MULTIPLAYER_SESSION_SCRIPT.new()
	root.add_child(session)
	session.call("configure_host_state_for_test", [2])
	var assignments: Dictionary = Dictionary(session.call("build_session_assignments"))
	var snapshot: Dictionary = Dictionary(TEAM_OWNERSHIP_CONTRACT_SCRIPT.call("build_team_ownership_snapshot", _load_slice(), assignments, "multiplayer_pvp"))
	var alpha: Dictionary = Dictionary(TEAM_OWNERSHIP_CONTRACT_SCRIPT.call("get_team_entry", snapshot, "team_alpha"))
	var bravo: Dictionary = Dictionary(TEAM_OWNERSHIP_CONTRACT_SCRIPT.call("get_team_entry", snapshot, "team_bravo"))
	_assert(bool(snapshot.get("valid", false)), "PvP ownership snapshot accepts session assignments")
	_assert(int(alpha.get("owner_peer_id", 0)) == 1, "PvP Alpha belongs to host peer")
	_assert(int(bravo.get("owner_peer_id", 0)) == 2, "PvP Bravo belongs to joined peer")
	_assert(not bool(bravo.get("npc_controlled", true)), "PvP Bravo is no longer NPC controlled when assigned")
	_assert(String(bravo.get("character_gameplay_authority", "")) == "host_server", "PvP Bravo gameplay remains host-authoritative")
	_assert(PackedStringArray(snapshot.get("player_team_ids", PackedStringArray())).has("team_alpha"), "PvP snapshot lists Alpha as player team")
	_assert(PackedStringArray(snapshot.get("player_team_ids", PackedStringArray())).has("team_bravo"), "PvP snapshot lists Bravo as player team")

	var simulation_root: Node = SIMULATION_ROOT_SCRIPT.new()
	var peer_teams: Dictionary = Dictionary(assignments.get("peer_teams", {}))
	simulation_root.call("set_peer_team_assignments", peer_teams)
	var command_contract: Dictionary = Dictionary(simulation_root.call("get_network_command_contract_snapshot"))
	_assert(String(Dictionary(command_contract.get("peer_teams", {})).get(2, "")) == "team_bravo", "SimulationRoot still accepts Peer2 Bravo assignment")
	simulation_root.free()
	session.queue_free()
	await process_frame


func _test_invalid_npc_assignment_is_flagged() -> void:
	var bad_assignments: Dictionary = {
		"peer_teams": {
			2: "team_bravo",
		},
	}
	var snapshot: Dictionary = Dictionary(TEAM_OWNERSHIP_CONTRACT_SCRIPT.call("build_team_ownership_snapshot", _load_slice(), bad_assignments, "singleplayer"))
	var errors: PackedStringArray = PackedStringArray(snapshot.get("errors", PackedStringArray()))
	_assert(not bool(snapshot.get("valid", true)), "Invalid singleplayer peer assignment is rejected")
	_assert(errors.has("team_team_bravo_not_player_assignable_in_singleplayer"), "Invalid assignment names the blocked NPC team")


func _load_slice() -> Dictionary:
	return Dictionary(VERTICAL_SLICE_CONTRACT_SCRIPT.call("load_slice_from_file", SCENARIO_PATH))


func _team_slot(slice: Dictionary, team_id: String) -> Dictionary:
	for slot_variant in Array(slice.get("team_slots", [])):
		var slot: Dictionary = Dictionary(slot_variant)
		if String(slot.get("team_id", "")) == team_id:
			return slot
	return {}


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
