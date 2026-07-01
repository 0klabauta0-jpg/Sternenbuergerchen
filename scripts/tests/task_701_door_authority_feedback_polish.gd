extends SceneTree

const MISSION_INTERACTION_DOOR_MULTIPLAYER_AUTHORITY_SCRIPT: GDScript = preload("res://scripts/mission/mission_interaction_door_multiplayer_authority.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_701_door_authority_feedback_polish.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/door_authority_feedback_polish.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_701 Door Authority Feedback Polish ===")
	_test_docs()
	_test_readout_polish_fields()
	_test_controller_exports()
	_test_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_701: FAILED")
		quit(1)
		return
	print("TASK_701: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_701 task file exists")
	_assert(task_text.contains("Door Authority Feedback Polish"), "Task documents door authority feedback polish")
	_assert(contract_text.contains("Door Authority Feedback Polish"), "Interaction contract documents door authority feedback polish")
	_assert(status_text.contains("TASK_701 - Door Authority Feedback Polish"), "Implementation status tracks TASK_701")
	_assert(roadmap_text.contains("TASK_701 - Door Authority Feedback Polish (implementiert)"), "Roadmap marks TASK_701 implemented")
	_assert(handbook_text.contains("TASK_701 - Door Authority Feedback Polish"), "Current handbook references TASK_701")
	_assert(handbook_text.contains('data-export-key="mission_interaction_door_authority_feedback_polish.manifest_path"'), "Current handbook exports TASK_701 manifest path")


func _test_readout_polish_fields() -> void:
	var ready: Dictionary = _ui_feedback(_authority_snapshot({}), _button_context())
	_assert(String(ready.get("status", "")) == "ready", "Ready status remains stable")
	_assert(String(ready.get("compact_line", "")) == "DOOR B->GO", "Ready compact line is short")
	_assert(String(ready.get("next_action", "")).contains("GO"), "Ready next action mentions GO")
	_assert(String(ready.get("player_hint", "")).contains("vorbereitet"), "Ready player hint explains preview state")
	_assert(String(ready.get("severity", "")) == "action", "Ready severity is action")
	_assert(String(ready.get("tooltip_text", "")).contains("Naechster Schritt"), "Tooltip prioritizes next action")
	_assert(bool(ready.get("read_only", false)), "Ready polish readout is read-only")
	_assert(not bool(ready.get("ui_sets_gameplay_truth", true)), "Ready polish readout does not set gameplay truth")

	var blocked_team: Dictionary = _ui_feedback(_authority_snapshot({
		"foreign_team_rejected": true,
		"foreign_team_reject_reason": "peer_team_mismatch",
	}), _button_context())
	_assert(String(blocked_team.get("status", "")) == "blocked", "Wrong-team reject remains blocked")
	_assert(String(blocked_team.get("reject_reason_label", "")).contains("falsches Team"), "Wrong-team reject is normalized for players")
	_assert(String(blocked_team.get("detail_line", "")).contains("falsches Team"), "Blocked detail uses player-facing reason")
	_assert(String(blocked_team.get("severity", "")) == "warning", "Blocked severity is warning")

	var blocked_state: Dictionary = _ui_feedback(_authority_snapshot({
		"state_mutation_rejected": true,
		"state_mutation_reject_reason": "state_mutation_key:runtime_state",
	}), _button_context())
	_assert(String(blocked_state.get("reject_reason_label", "")).contains("Client darf Runtime-State"), "State mutation reject is normalized")
	_assert(String(blocked_state.get("player_hint", "")).contains("Runtime-State"), "State mutation hint names runtime-state blocker")

	var accepted: Dictionary = _ui_feedback(_authority_snapshot({"host_command_accepted": true}), _button_context())
	_assert(String(accepted.get("status", "")) == "accepted", "Accepted status remains stable")
	_assert(String(accepted.get("compact_line", "")) == "DOOR HOST OK", "Accepted compact line names host")
	_assert(String(accepted.get("next_action", "")).contains("Runtime-Progress"), "Accepted next action waits for runtime progress")

	var open: Dictionary = _ui_feedback(_authority_snapshot({"door_runtime_open_override": true}), _button_context())
	_assert(String(open.get("status", "")) == "open", "Open status remains stable")
	_assert(String(open.get("compact_line", "")) == "DOOR OPEN", "Open compact line names open state")
	_assert(String(open.get("player_hint", "")).contains("Runtime-Overrides"), "Open hint names runtime overrides")
	_assert(String(open.get("severity", "")) == "success", "Open severity is success")


func _test_controller_exports() -> void:
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(controller_text.contains("door_authority_ui_compact_line"), "Controller exports compact line")
	_assert(controller_text.contains("door_authority_ui_player_hint"), "Controller exports player hint")
	_assert(controller_text.contains("door_authority_ui_next_action"), "Controller exports next action")
	_assert(controller_text.contains("door_authority_ui_severity"), "Controller exports severity")
	_assert(controller_text.contains("door_authority_ui_reject_reason_label"), "Controller exports reject reason label")


func _test_manifest_write() -> void:
	_ensure_output_dir()
	var ready: Dictionary = _ui_feedback(_authority_snapshot({}), _button_context())
	var blocked: Dictionary = _ui_feedback(_authority_snapshot({"foreign_team_rejected": true, "foreign_team_reject_reason": "peer_team_mismatch"}), _button_context())
	var manifest: Dictionary = {
		"schema": "sternenbuergerchen.door_authority_feedback_polish_manifest.v1",
		"task_id": "TASK_701",
		"ready_compact_line": String(ready.get("compact_line", "")),
		"blocked_reject_reason_label": String(blocked.get("reject_reason_label", "")),
		"read_only": bool(ready.get("read_only", false)) and bool(blocked.get("read_only", false)),
		"ui_sets_gameplay_truth": false,
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
	}
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_701 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_701", "Manifest records TASK_701")
	_assert(String(parsed.get("blocked_reject_reason_label", "")).contains("falsches Team"), "Manifest records normalized reject reason")


func _authority_snapshot(overrides: Dictionary) -> Dictionary:
	var snapshot: Dictionary = {
		"schema": "test.authority",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"hook_accepted": true,
		"requires_go": true,
		"gate": "review",
		"summary": "",
		"host_command_accepted": false,
		"foreign_team_rejected": false,
		"state_mutation_rejected": false,
		"door_runtime_open_override": false,
		"foreign_team_reject_reason": "",
		"state_mutation_reject_reason": "",
	}
	snapshot.merge(overrides, true)
	return snapshot


func _button_context() -> Dictionary:
	return {
		"button_enabled": true,
		"has_usable_door": true,
		"display_token": "DOOR",
		"shortcut": "B",
	}


func _ui_feedback(authority_snapshot: Dictionary, button_context: Dictionary) -> Dictionary:
	return Dictionary(MISSION_INTERACTION_DOOR_MULTIPLAYER_AUTHORITY_SCRIPT.call("build_ui_feedback", authority_snapshot, button_context))


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_701 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
