extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1164_left_tactical_stack_1280_visual_findings.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const SERVICE_PATH := "res://scripts/mission/left_tactical_stack_1280_visual_findings.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/left_tactical_stack_1280_visual_findings_acceptance.json"
const SCHEMA := "sternenbuergerchen.left_tactical_stack_1280_visual_findings.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.left_tactical_stack_1280_release_recapture.v1"
const NEXT_REVIEW_TASK := "TASK_1164 - Left Tactical Stack 1280 Visual Findings"
const NEXT_POLISH_TASK := "TASK_1165 - Left Tactical Stack 1280 Detail Polish"
const NEXT_ACCEPTANCE_TASK := "TASK_1165 - Left Tactical Stack 1280 Acceptance Slice"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1164 Left Tactical Stack 1280 Visual Findings ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_review_ready_without_notes_needs_review()
	_test_issue_notes_route_to_polish()
	_test_clean_notes_accept_for_slice()
	_test_controller_exports_visual_findings()
	_test_visual_findings_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1164_left_tactical_stack_1280_visual_findings: FAILED")
		quit(1)
		return
	print("TASK_1164_left_tactical_stack_1280_visual_findings: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1164 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1164 visual findings service exists")
	_assert(task_text.contains("TASK_1164 - Left Tactical Stack 1280 Visual Findings"), "Task names TASK_1164")
	_assert(task_text.contains(NEXT_POLISH_TASK), "Task names left-stack detail polish follow-up")
	_assert(status_text.contains("TASK_1164 - Left Tactical Stack 1280 Visual Findings"), "Implementation status tracks TASK_1164")
	_assert(roadmap_text.contains("TASK_1164 - Left Tactical Stack 1280 Visual Findings (implementiert"), "Roadmap marks TASK_1164 implemented")
	_assert(command_contract_text.contains("Left Tactical Stack 1280 Visual Findings (TASK_1164)"), "Mission feedback contract documents TASK_1164")
	_assert(service_text.contains(SCHEMA), "Visual findings service exposes stable schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1164\""), "Visual findings service writes TASK_1164 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1163\""), "Visual findings service links TASK_1163")
	_assert(service_text.contains("member_strip_readable"), "Visual findings service checks mini-card member strip")
	_assert(service_text.contains("event_filter_label_readable"), "Visual findings service checks event filter label")
	_assert(service_text.contains("desktop_capture_trusted"), "Visual findings service checks desktop capture trust")
	_assert(service_text.contains("\"creates_command\": false"), "Visual findings service creates no command")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Visual findings service creates no multiplayer truth")
	_assert(controller_text.contains("LEFT_TACTICAL_STACK_1280_VISUAL_FINDINGS_SCRIPT"), "Controller preloads TASK_1164 service")
	_assert(controller_text.contains("get_left_tactical_stack_1280_visual_findings_snapshot"), "Controller exposes TASK_1164 snapshot")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_1164")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_review_ready"), "Missing source reports not review-ready")
	_assert(_snapshot_is_read_only(snapshot), "Blocked snapshot remains read-only")


func _test_review_ready_without_notes_needs_review() -> void:
	var snapshot: Dictionary = _build_snapshot(_review_ready_source(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "needs_left_stack_visual_review", "Review-ready source without notes needs left-stack review")
	_assert(issue_ids.has("left_stack_visual_review_missing"), "Missing visual review is named")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_REVIEW_TASK, "Open review loops on TASK_1164")
	_assert(_snapshot_is_read_only(snapshot), "Needs-review snapshot remains read-only")


func _test_issue_notes_route_to_polish() -> void:
	var notes: Dictionary = _clean_review_notes()
	notes["member_strip_readable"] = false
	notes["event_filter_label_readable"] = false
	notes["desktop_capture_trusted"] = false
	var snapshot: Dictionary = _build_snapshot(_review_ready_source(), notes)
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "ready_for_left_stack_visual_polish", "Issue notes route to left-stack polish")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_POLISH_TASK, "Issue notes recommend TASK_1165 detail polish")
	_assert(String(snapshot.get("primary_issue_id", "")) == "mini_card_member_strip_too_small", "Member strip is the primary issue")
	_assert(issue_ids.has("mini_card_member_strip_too_small"), "Tiny member strip is named")
	_assert(issue_ids.has("event_log_filter_label_dense"), "Dense event filter label is named")
	_assert(issue_ids.has("combined_desktop_capture_untrusted"), "Untrusted combined desktop capture is named")
	_assert(int(snapshot.get("positive_finding_count", 0)) >= 4, "Mixed review keeps positive findings")
	_assert(not bool(snapshot.get("accepted", true)), "Issue notes are not accepted")
	_assert(_snapshot_is_read_only(snapshot), "Issue snapshot remains read-only")


func _test_clean_notes_accept_for_slice() -> void:
	var snapshot: Dictionary = _build_snapshot(_review_ready_source(), _clean_review_notes())
	var summary_line: String = String(snapshot.get("left_stack_visual_findings_summary_line", ""))
	_assert(String(snapshot.get("status", "")) == "accepted_for_left_stack_acceptance_slice", "Clean notes accept TASK_1164")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_ACCEPTANCE_TASK, "Clean notes recommend acceptance slice")
	_assert(bool(snapshot.get("accepted", false)), "Clean notes set accepted")
	_assert(int(snapshot.get("issue_count", -1)) == 0, "Clean notes have no issues")
	_assert(int(snapshot.get("positive_finding_count", 0)) >= 8, "Clean notes produce positive findings")
	_assert(summary_line.contains("MINI") and summary_line.contains("EVENT") and summary_line.contains("FOCUS"), "Accepted summary names left-stack surfaces")
	_assert(_snapshot_is_read_only(snapshot), "Accepted snapshot remains read-only")


func _test_controller_exports_visual_findings() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_left_tactical_stack_1280_visual_findings_snapshot"):
		_assert(false, "Controller exposes TASK_1164 snapshot")
		controller.queue_free()
		return
	var snapshot: Dictionary = controller.get_left_tactical_stack_1280_visual_findings_snapshot(_review_ready_source(), _clean_review_notes())
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1164 schema matches")
	_assert(String(snapshot.get("status", "")) == "accepted_for_left_stack_acceptance_slice", "Controller TASK_1164 accepts clean notes")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1164 snapshot remains read-only")
	controller.queue_free()


func _test_visual_findings_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_review_ready_source(), _clean_review_notes())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1164 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1164", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1163", "Roundtrip keeps TASK_1163 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_ACCEPTANCE_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_snapshot: Dictionary, review_notes: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1164 service is loadable")
		return _read_only_fallback()
	var service_script: GDScript = load(SERVICE_PATH)
	if service_script == null:
		_assert(false, "TASK_1164 service script loads")
		return _read_only_fallback()
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_snapshot, review_notes)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1164 service returns dictionary")
	return _read_only_fallback()


func _review_ready_source() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1163",
		"source_task_id": "TASK_1162",
		"source_readability": {
			"readability_ready": true,
			"visible_card_count": 2,
			"focused_card_count": 1,
			"event_log_readability_ready": true,
			"mini_event_no_overlap": true,
		},
		"release_capture": {
			"expected_resolution": "1280x720",
			"manual_visual_review_required": true,
			"host_window_artifact": "tmp/release_host_client_first_contact_host_window.png",
			"client_window_artifact": "tmp/release_host_client_first_contact_client_window.png",
			"manifest": "tmp/release_host_client_first_contact_playtest.json",
		},
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_effect": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
	}


func _clean_review_notes() -> Dictionary:
	return {
		"review_available": true,
		"mini_cards_readable": true,
		"primary_focus_clear": true,
		"event_log_readable": true,
		"event_log_not_blocking_cards": true,
		"host_client_consistent": true,
		"member_strip_readable": true,
		"event_filter_label_readable": true,
		"desktop_capture_trusted": true,
	}


func _read_only_fallback() -> Dictionary:
	return {
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_effect": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_effect", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true)) \
		and not bool(snapshot.get("sets_multiplayer_truth", true))


func _issue_ids(issues: Array) -> Array:
	var result: Array = []
	for issue_variant in issues:
		if typeof(issue_variant) != TYPE_DICTIONARY:
			continue
		result.append(String(Dictionary(issue_variant).get("id", "")))
	return result


func _read_json_dict(path: String) -> Dictionary:
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
		return
	_failed += 1
	push_error(message)
