extends SceneTree

const SERVICE_PATH := "res://scripts/mission/mission_release_recapture_service.gd"
const TASK_PATH := "res://docs/tasks/TASK_1174_mission_release_recapture_extraction.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1174 Mission Release Recapture Extraction ===")
	_test_docs_and_service_contract()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1174: FAILED")
		quit(1)
		return
	print("TASK_1174: ALL PASSED")
	quit(0)


func _test_docs_and_service_contract() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK 1174 task document exists")
	_assert(_read_text(TASK_PATH).contains("Mission Release Recapture Extraction"), "Task document names TASK 1174")
	_assert(_read_text(STATUS_PATH).contains("TASK_1174 - Mission Release Recapture Extraction"), "Implementation status tracks TASK 1174")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_1174 - Mission Release Recapture Extraction"), "Roadmap tracks TASK 1174")
	_assert(_read_text(CONTRACT_PATH).contains("MissionReleaseRecaptureService"), "Mission feedback contract documents the extraction service")
	_assert(_read_text(CONTROLLER_PATH).contains("MISSION_RELEASE_RECAPTURE_SERVICE_SCRIPT"), "Controller delegates release recaptures to mission service")
	_assert(FileAccess.file_exists(SERVICE_PATH), "Mission release recapture service exists")
	if not FileAccess.file_exists(SERVICE_PATH):
		return
	var service_script: GDScript = load(SERVICE_PATH) as GDScript
	_assert(service_script != null, "Mission release recapture service loads")
	if service_script == null:
		return
	var contact_snapshot: Dictionary = Dictionary(service_script.call("build_first_contact_recapture", _execution_fixture(), _contact_fixture(), _release_fixture(), _capture_fixture(), _window_fixture("host"), _window_fixture("client")))
	_assert(String(contact_snapshot.get("schema", "")) == "sternenbuergerchen.mission_first_contact_readability_release_recapture.v1", "Service preserves TASK 1172 schema")
	_assert(String(contact_snapshot.get("task_id", "")) == "TASK_1172", "Service preserves TASK 1172 identity")
	_assert(bool(contact_snapshot.get("ready_for_first_engagement_recapture", false)), "Service preserves first-engagement handoff")
	_assert(_read_only(contact_snapshot), "TASK 1172 service output stays read-only")

	var engagement_snapshot: Dictionary = Dictionary(service_script.call("build_first_engagement_recapture", contact_snapshot, _engagement_fixture(), _release_fixture(), _capture_fixture(), _window_fixture("host"), _window_fixture("client")))
	_assert(String(engagement_snapshot.get("schema", "")) == "sternenbuergerchen.mission_first_engagement_feedback_release_recapture.v1", "Service preserves TASK 1173 schema")
	_assert(String(engagement_snapshot.get("task_id", "")) == "TASK_1173", "Service preserves TASK 1173 identity")
	_assert(bool(engagement_snapshot.get("ready_for_first_fire_visual_recapture", false)), "Service preserves first-fire visual handoff")
	_assert(bool(engagement_snapshot.get("engagement_decision_visible", false)), "Service preserves engagement decision visibility")
	_assert(_read_only(engagement_snapshot), "TASK 1173 service output stays read-only")


func _execution_fixture() -> Dictionary:
	return {"task_id": "TASK_1171", "ready_for_first_contact_recapture": true, "ui_sets_gameplay_truth": false}


func _contact_fixture() -> Dictionary:
	var contact := {"report_text": "1 Kontakt, zuletzt vor 2s gesehen"}
	return {
		"task_id": "TASK_542", "gate": "pass", "selected_contact_count": 1, "first_contact": contact,
		"contact_overlay_visible_count": 1, "tactical_communication_event_count": 1,
		"checks": [{"id": "threat_or_cover_context_visible", "passed": true}], "ui_sets_gameplay_truth": false,
	}


func _engagement_fixture() -> Dictionary:
	return {
		"task_id": "TASK_543", "gate": "pass", "engagement_status": "fired", "engagement_reason": "clear_los",
		"first_fire_event": {"event_id": "fixture_fire", "attacker_unit_id": "unit_alpha", "target_unit_id": "enemy_01"},
		"contact_decision_diagnostics": {"status": "fired", "reason": "clear_los"},
		"checks": [
			{"id": "engagement_decision_visible", "passed": true}, {"id": "target_or_block_reason_visible", "passed": true},
			{"id": "fire_event_or_block_visible", "passed": true}, {"id": "cover_range_los_context_visible", "passed": true},
			{"id": "feedback_text_visible", "passed": true},
		],
		"ui_sets_gameplay_truth": false,
	}


func _release_fixture() -> Dictionary:
	return {"valid": true, "matches_git_head": true}


func _capture_fixture() -> Dictionary:
	return {"gate_passed": true, "release_gate_passed": true, "deployment_converged": true, "first_fire_converged": true}


func _window_fixture(label: String) -> Dictionary:
	return {"path": "tmp/%s.png" % label, "exists": true, "size_bytes": 128}


func _read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_effect", true)) \
		and not bool(snapshot.get("creates_contact", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true)) \
		and not bool(snapshot.get("sets_multiplayer_truth", true))


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
