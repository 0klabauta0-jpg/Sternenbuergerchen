extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_650_host_client_click_feedback_followup.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const PRESENTER_PATH: String = "res://scripts/mission/mission_team_chip_presenter.gd"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"

var _passed: int = 0
var _failed: int = 0


class FakeSimulationRoot:
	extends Node

	var network_snapshot: Dictionary = {}

	func get_network_command_contract_snapshot() -> Dictionary:
		return network_snapshot.duplicate(true)


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_650 Host Client Click Feedback Followup ===")
	_test_docs_and_contract()
	_test_presenter_followup_action()
	_test_controller_decorated_teamchip()
	_test_command_feedback_snapshot_exports_action()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_650: FAILED")
		quit(1)
		return
	print("TASK_650: ALL PASSED")
	quit(0)


func _test_docs_and_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var presenter_text: String = _read_text(PRESENTER_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_650 task file exists")
	_assert(task_text.contains("Host Client Click Feedback Followup"), "TASK_650 task names click feedback followup")
	_assert(status_text.contains("TASK_650 - Host Client Click Feedback Followup"), "Implementation status tracks TASK_650")
	_assert(roadmap_text.contains("TASK_650 - Host Client Click Feedback Followup (implementiert)"), "Roadmap marks TASK_650 implemented")
	_assert(contract_text.contains("Host-Client-Click-Feedback-Followup"), "Mission feedback contract documents TASK_650")
	_assert(presenter_text.contains("_build_reject_action_hint"), "Presenter builds reject action hint")
	_assert(controller_text.contains("authority_visible_action_text"), "Controller exports visible authority action text")


func _test_presenter_followup_action() -> void:
	var presenter_script: GDScript = load(PRESENTER_PATH)
	var presenter = presenter_script.new()
	var snapshot: Dictionary = Dictionary(presenter.call("build_snapshot", _build_network_snapshot()))
	var authority_visual: Dictionary = Dictionary(snapshot.get("authority_visual", {}))
	var tooltip_text: String = String(authority_visual.get("tooltip_text", ""))
	_assert(String(authority_visual.get("schema", "")) == "sternenbuergerchen.host_client_authority_visual.v1", "Authority visual schema stays stable")
	_assert(String(authority_visual.get("task_id", "")) == "TASK_625", "Authority visual base task id stays stable for regressions")
	_assert(String(authority_visual.get("action_followup_task_id", "")) == "TASK_650", "Authority visual marks TASK_650 follow-up fields")
	_assert(String(authority_visual.get("compact_text", "")) == "AUTH OK1/RJ2", "Compact AUTH text stays stable")
	_assert(String(authority_visual.get("visible_feedback_text", "")) == "BLOCK P2 wrong team", "Visible reject feedback remains stable")
	_assert(String(authority_visual.get("visible_action_text", "")) == "USE BRAVO", "Visible action tells peer to use Bravo")
	_assert(String(authority_visual.get("next_action_text", "")) == "Use BRAVO fireteam.", "Next action text is player-facing")
	_assert(String(authority_visual.get("next_action_detail", "")).contains("Peer 2 should command the BRAVO fireteam"), "Next action detail names peer and team")
	_assert(bool(authority_visual.get("next_action_ready", false)), "Next action is marked ready")
	_assert(tooltip_text.contains("Next: Peer 2 should command the BRAVO fireteam"), "Tooltip includes next action detail")
	_assert(tooltip_text.contains("Last reject: Peer 2 | peer_team_mismatch"), "Tooltip keeps raw reject reason")
	_assert(bool(authority_visual.get("read_only", false)), "Authority action remains read-only")
	_assert(not bool(authority_visual.get("ui_sets_gameplay_truth", true)), "Authority action does not set gameplay truth")


func _test_controller_decorated_teamchip() -> void:
	var presenter_script: GDScript = load(PRESENTER_PATH)
	var controller_script: GDScript = load(CONTROLLER_PATH)
	var presenter = presenter_script.new()
	var controller: Node = controller_script.new()
	var presenter_snapshot: Dictionary = Dictionary(presenter.call("build_snapshot", _build_network_snapshot()))
	var decorated: Dictionary = Dictionary(controller.call("_with_review_session_badge", presenter_snapshot))
	var display_text: String = String(decorated.get("display_text", ""))
	var tooltip_text: String = String(decorated.get("display_tooltip_text", ""))
	_assert(display_text.contains("AUTH OK1/RJ2"), "Decorated display keeps compact AUTH status")
	_assert(display_text.contains("BLOCK P2 wrong team"), "Decorated display keeps visible reject")
	_assert(display_text.contains("USE BRAVO"), "Decorated display shows next action")
	_assert(String(decorated.get("authority_visible_action_text", "")) == "USE BRAVO", "Decorated chip exports visible action")
	_assert(String(decorated.get("authority_next_action_text", "")) == "Use BRAVO fireteam.", "Decorated chip exports next action text")
	_assert(tooltip_text.contains("Next: Peer 2 should command the BRAVO fireteam"), "Decorated tooltip includes next action")
	_assert(bool(decorated.get("read_only", false)), "Decorated action remains read-only")
	_assert(not bool(decorated.get("ui_sets_gameplay_truth", true)), "Decorated action does not set gameplay truth")
	controller.free()


func _test_command_feedback_snapshot_exports_action() -> void:
	var controller_script: GDScript = load(CONTROLLER_PATH)
	var parent := Node.new()
	var fake_root := FakeSimulationRoot.new()
	fake_root.name = "SimulationRoot"
	fake_root.network_snapshot = _build_network_snapshot()
	var controller: Node = controller_script.new()
	controller.name = "MissionTacticalSandboxController"
	parent.add_child(fake_root)
	parent.add_child(controller)
	root.add_child(parent)
	var command_snapshot: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(String(command_snapshot.get("authority_visible_feedback_text", "")) == "BLOCK P2 wrong team", "Command snapshot keeps visible reject")
	_assert(String(command_snapshot.get("authority_visible_action_text", "")) == "USE BRAVO", "Command snapshot exports visible action")
	_assert(String(command_snapshot.get("authority_next_action_text", "")) == "Use BRAVO fireteam.", "Command snapshot exports next action text")
	_assert(String(command_snapshot.get("authority_next_action_detail", "")).contains("Peer 2 should command the BRAVO fireteam"), "Command snapshot exports action detail")
	var authority_visual: Dictionary = Dictionary(command_snapshot.get("authority_visual", {}))
	_assert(bool(authority_visual.get("read_only", false)), "Command snapshot authority visual remains read-only")
	_assert(not bool(authority_visual.get("ui_sets_gameplay_truth", true)), "Command snapshot authority visual does not set gameplay truth")
	parent.queue_free()


func _build_network_snapshot() -> Dictionary:
	return {
		"accepted_count": 1,
		"rejected_count": 2,
		"last_rejection": {
			"accepted": false,
			"reason": "peer_team_mismatch",
			"peer_id": 2,
			"team_id": "team_alpha",
			"fireteam_id": "blue",
			"unit_id": "task650_alpha",
		},
		"peer_teams": {
			1: "team_alpha",
			2: "team_bravo",
		},
		"peer_roles": {
			1: "host",
			2: "fireteam",
		},
		"peer_fireteams": {
			1: PackedStringArray(["blue"]),
			2: PackedStringArray(["red"]),
		},
	}


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
