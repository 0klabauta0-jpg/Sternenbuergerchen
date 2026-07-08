extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_873_release_first_exchange_contact_fire_readability_fix.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_task873_contact_fire_2026_07_08.html"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const META_LAYER_PATH := "res://scripts/meta/meta_layer_flow.gd"
const SCHEMA := "sternenbuergerchen.release_first_exchange_contact_fire_readability_fix.v1"
const STYLE_ID := "task_873_release_first_exchange_contact_fire_readability_fix_v1"
const NEXT_TASK := "TASK_874 - Release First Exchange CONTACT-FIRE Real Window Recapture"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_873 Release First Exchange CONTACT-FIRE Readability Fix ===")
	_test_docs_and_report()
	_test_scripts_parse()
	_test_controller_contact_fire_refresh_hook()
	_test_meta_layer_deeplink_uses_hook()
	_test_read_only_boundaries()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_873_release_first_exchange_contact_fire_readability_fix: FAILED")
		quit(1)
		return
	print("TASK_873_release_first_exchange_contact_fire_readability_fix: ALL PASSED")
	quit(0)


func _test_docs_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_873 task file exists")
	_assert(task_text.contains("Release First Exchange CONTACT-FIRE Readability Fix"), "Task file names TASK_873")
	_assert(task_text.contains("record_release_fire_exchange_visibility_evidence()"), "Task file references existing evidence seeding")
	_assert(task_text.contains("Kein Combat-Rewrite"), "Task file keeps scope narrow")
	_assert(status_text.contains("TASK_873 - Release First Exchange CONTACT-FIRE Readability Fix"), "Implementation status tracks TASK_873")
	_assert(status_text.contains(NEXT_TASK), "Implementation status names TASK_874 follow-up")
	_assert(roadmap_text.contains("TASK_873 - Release First Exchange CONTACT-FIRE Readability Fix (implementiert)"), "Roadmap marks TASK_873 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_874 as next")
	_assert(contract_text.contains("Release-First-Exchange-CONTACT-FIRE-Readability-Fix (TASK_873)"), "Contract documents TASK_873")
	_assert(contract_text.contains(SCHEMA), "Contract defines TASK_873 schema")
	_assert(contract_text.contains(STYLE_ID), "Contract defines TASK_873 style")
	_assert(report_text.contains("Task-Fokus: TASK_873"), "HTML report tracks TASK_873")
	_assert(report_text.contains("JSON exportieren"), "HTML report exposes JSON export")


func _test_scripts_parse() -> void:
	_assert(load(CONTROLLER_PATH) != null, "Mission tactical controller script parses")
	_assert(load(META_LAYER_PATH) != null, "Meta layer flow script parses")


func _test_controller_contact_fire_refresh_hook() -> void:
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var body: String = _function_body(controller_text, "apply_release_first_exchange_contact_fire_readability_fix")
	_assert(controller_text.contains("const RELEASE_FIRST_EXCHANGE_CONTACT_FIRE_READABILITY_FIX_STYLE_ID: String = \"%s\"" % STYLE_ID), "Controller defines TASK_873 style id")
	_assert(not body.is_empty(), "Controller exposes TASK_873 apply hook")
	_assert(body.contains("record_release_fire_exchange_visibility_evidence(source_snapshot)"), "Hook seeds existing visibility evidence")
	_assert(body.contains("_refresh_world_overlays()"), "Hook refreshes world overlays")
	_assert(body.contains("_update_ui()"), "Hook refreshes UI immediately")
	_assert(body.contains("_refresh_tactical_event_log_panel()"), "Hook refreshes event-log panel")
	_assert(body.contains("_apply_release_fire_exchange_real_window_primary_hud_runtime_text()"), "Hook reapplies runtime HUD text")
	_assert(body.contains("\"schema\": \"%s\"" % SCHEMA), "Hook returns stable TASK_873 schema")
	_assert(body.contains("\"selected_fireteam_contact_fire_first\""), "Hook reports #17 CONTACT FIRE-first")
	_assert(body.contains("\"mission_control_contact_fire_first\""), "Hook reports #18 CONTACT FIRE-first")
	_assert(body.contains("\"event_log_contact_fire\""), "Hook reports #19 CONTACT FIRE")
	_assert(body.contains("\"primary_lines_contain_debug_no_fire_before_contact_fire\""), "Hook reports stale NO FIRE ordering")
	_assert(body.contains("\"recommended_next_task\": \"%s\"" % NEXT_TASK), "Hook recommends TASK_874 recapture")
	_assert(controller_text.contains("func _release_first_exchange_primary_lines_contain_no_fire_before_contact_fire"), "Controller has NO-FIRE-before-CONTACT-FIRE guard")
	_assert(controller_text.contains("func _build_release_first_exchange_contact_fire_readability_issue"), "Controller has TASK_873 issue helper")


func _test_meta_layer_deeplink_uses_hook() -> void:
	var meta_text: String = _read_text(META_LAYER_PATH)
	var deeplink_body: String = _function_body(meta_text, "_apply_release_first_go_firefight_deeplink")
	_assert(meta_text.contains("_release_first_exchange_contact_fire_readability_fix_evidence"), "MetaLayer stores TASK_873 evidence")
	_assert(deeplink_body.contains("apply_release_first_exchange_contact_fire_readability_fix"), "Deep-link calls TASK_873 hook")
	_assert(deeplink_body.contains("set_meta(\"release_first_exchange_contact_fire_readability_fix_evidence\""), "Deep-link exposes TASK_873 evidence as meta")
	_assert(deeplink_body.contains("record_release_fire_exchange_visibility_evidence"), "Deep-link keeps compatibility fallback")
	_assert(meta_text.contains("func get_release_first_exchange_contact_fire_readability_fix_snapshot"), "MetaLayer exposes TASK_873 snapshot")
	_assert(meta_text.contains("\"reason\": \"contact_fire_readability_fix_not_applied\""), "MetaLayer reports unapplied TASK_873 state")


func _test_read_only_boundaries() -> void:
	var controller_body: String = _function_body(_read_text(CONTROLLER_PATH), "apply_release_first_exchange_contact_fire_readability_fix")
	var meta_snapshot_body: String = _function_body(_read_text(META_LAYER_PATH), "get_release_first_exchange_contact_fire_readability_fix_snapshot")
	for body in [controller_body, meta_snapshot_body]:
		_assert(body.contains("\"read_only\": true"), "TASK_873 snapshot declares read-only")
		_assert(body.contains("\"ui_sets_gameplay_truth\": false"), "TASK_873 snapshot declares no gameplay truth")
		_assert(body.contains("\"creates_command\": false"), "TASK_873 snapshot declares no command creation")
		_assert(body.contains("\"creates_fire_event\": false"), "TASK_873 snapshot declares no fire-event creation")
		_assert(body.contains("\"creates_damage_event\": false"), "TASK_873 snapshot declares no damage-event creation")
		_assert(body.contains("\"creates_movement\": false"), "TASK_873 snapshot declares no movement creation")
		_assert(body.contains("\"sets_multiplayer_truth\": false"), "TASK_873 snapshot declares no multiplayer truth")
	_assert(not controller_body.contains("enqueue_command"), "TASK_873 hook does not enqueue commands")
	_assert(not controller_body.contains("enqueue_effect"), "TASK_873 hook does not enqueue effects")
	_assert(not controller_body.contains("create_fire"), "TASK_873 hook does not create fire events")


func _function_body(text: String, function_name: String) -> String:
	var marker: String = "func %s" % function_name
	var start: int = text.find(marker)
	if start < 0:
		return ""
	var next: int = text.find("\nfunc ", start + marker.length())
	if next < 0:
		next = text.length()
	return text.substr(start, next - start)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
