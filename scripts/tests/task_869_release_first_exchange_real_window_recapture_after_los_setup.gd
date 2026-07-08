extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_869_release_first_exchange_real_window_recapture_after_los_setup.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const TOOL_PATH := "res://scripts/tools/capture_release_first_exchange_los_setup_real_window_recapture.ps1"
const MANIFEST_PATH := "res://tmp/release_first_exchange_los_setup_real_window_recapture.json"
const OUTPUT_PATH := "res://tmp/release_first_exchange_los_setup_real_window_recapture_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_exchange_los_setup_real_window_recapture.v1"
const LOS_SCHEMA := "sternenbuergerchen.release_first_exchange_los_setup_polish.v1"
const LOS_STYLE_ID := "task_868_release_first_exchange_los_setup_polish_v1"
const EXCHANGE_SCHEMA := "sternenbuergerchen.release_first_exchange_tension_tuning.v1"
const EXCHANGE_STYLE_ID := "task_844_release_first_exchange_tension_tuning_v1"
const RUNTIME_STATUS_SCHEMA := "sternenbuergerchen.release_fire_exchange_runtime_text_status_recapture.v1"
const FIRST_GO_ARG := "--release-singleplayer-first-go-firefight"
const NEXT_TASK := "TASK_870 - Release First Exchange Post-LOS Visual Findings"

const REQUIRED_CHECKS := [
	"release_exe_started_with_first_go_firefight_arg",
	"task_868_los_setup_expected",
	"task_844_first_exchange_expected",
	"task_866_runtime_text_status_expected",
	"validated_target_pair_context_visible",
	"selected_fireteam_contact_fire_visible",
	"mission_control_contact_fire_visible",
	"event_log_contact_fire_or_exchange_detail_visible",
	"fire_trace_or_impact_target_focus_visible",
	"source_window_crop_trusted",
	"no_stale_no_los_or_contact_pressure_only_message",
	"command_surfaces_still_usable",
	"manual_visual_review_done",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_869 Release First Exchange Real Window Recapture After LOS Setup ===")
	_test_docs_and_tool_contract()
	_test_synthetic_manifest_contract()
	_test_optional_actual_manifest()
	_test_manifest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_869_release_first_exchange_real_window_recapture_after_los_setup: FAILED")
		quit(1)
		return
	print("TASK_869_release_first_exchange_real_window_recapture_after_los_setup: ALL PASSED")
	quit(0)


func _test_docs_and_tool_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var tool_text: String = _read_text(TOOL_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_869 task file exists")
	_assert(FileAccess.file_exists(TOOL_PATH), "TASK_869 capture tool exists")
	_assert(task_text.contains("Release First Exchange Real Window Recapture After LOS Setup"), "Task names TASK_869 recapture")
	_assert(status_text.contains("TASK_869 - Release First Exchange Real Window Recapture After LOS Setup"), "Implementation status tracks TASK_869")
	_assert(roadmap_text.contains("TASK_869 - Release First Exchange Real Window Recapture (implementiert)"), "Roadmap marks TASK_869 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_870 follow-up")
	_assert(contract_text.contains("Release-First-Exchange-Real-Window-Recapture-After-LOS-Setup"), "Contract documents TASK_869")
	_assert(tool_text.contains(SCHEMA), "Tool writes stable TASK_869 schema")
	_assert(tool_text.contains("task_id = \"TASK_869\""), "Tool writes TASK_869 id")
	_assert(tool_text.contains("source_task_id = \"TASK_868\""), "Tool links TASK_868 source")
	_assert(tool_text.contains("source_status_recapture_task_id = \"TASK_866\""), "Tool links TASK_866 source capture")
	_assert(tool_text.contains("source_exchange_task_id = \"TASK_844\""), "Tool links TASK_844 exchange source")
	_assert(tool_text.contains("capture_release_fire_exchange_runtime_text_status_recapture.ps1"), "Tool reuses TASK_866 capture path")
	_assert(tool_text.contains(FIRST_GO_ARG), "Tool uses first GO/firefight deep-link")
	_assert(tool_text.contains(LOS_SCHEMA), "Tool records TASK_868 LOS setup schema")
	_assert(tool_text.contains(LOS_STYLE_ID), "Tool records TASK_868 LOS setup style")
	_assert(tool_text.contains(EXCHANGE_SCHEMA), "Tool records TASK_844 exchange schema")
	_assert(tool_text.contains(RUNTIME_STATUS_SCHEMA), "Tool records TASK_866 runtime status schema")
	_assert(tool_text.contains("release_first_exchange_los_setup_real_window_recapture.json"), "Tool writes TASK_869 manifest")
	_assert(tool_text.contains("release_first_exchange_los_setup_real_window_recapture.png"), "Tool writes task-specific screenshot")
	_assert(tool_text.contains("validated_target_pair_context_visible"), "Tool requires validated pair context")
	_assert(tool_text.contains("source_window_crop_trusted"), "Tool requires trusted source window crop")
	_assert(tool_text.contains("window_crop_trusted"), "Tool propagates source window crop trust")
	_assert(tool_text.contains("visible_window_gate"), "Tool records generic visible-window capture gate")
	_assert(tool_text.contains("no_stale_no_los_or_contact_pressure_only_message"), "Tool requires no stale pressure-only/no-los first reading")
	_assert(tool_text.contains("manual_review_done = $false"), "Tool keeps manual review open")
	_assert(tool_text.contains("ui_sets_gameplay_truth = $false"), "Tool declares no gameplay truth mutation")
	_assert(tool_text.contains("creates_command = $false"), "Tool declares no command creation")
	_assert(tool_text.contains("creates_fire_event = $false"), "Tool declares no fire-event creation")
	_assert(tool_text.contains("creates_damage_event = $false"), "Tool declares no damage-event creation")
	_assert(tool_text.contains("sets_multiplayer_truth = $false"), "Tool declares no multiplayer truth mutation")
	_assert(tool_text.contains("updates_shortcuts = $false"), "Tool declares no shortcut updates")
	_assert(tool_text.contains("starts_processes = [bool]$Launch"), "Tool starts processes only when requested")
	_assert(tool_text.contains("kills_processes = [bool]$StopRunningReleaseProcess"), "Tool kills processes only when requested")


func _test_synthetic_manifest_contract() -> void:
	var manifest := _good_manifest()
	_assert(_manifest_core_contract_ok(manifest), "Synthetic manifest satisfies TASK_869 core contract")
	_assert(_required_checks_present(manifest), "Synthetic manifest contains all required checks")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "Synthetic manifest sets no gameplay truth")
	_assert(not bool(manifest.get("creates_command", true)), "Synthetic manifest creates no commands")
	_assert(not bool(manifest.get("creates_fire_event", true)), "Synthetic manifest creates no fire events")
	_assert(not bool(manifest.get("creates_damage_event", true)), "Synthetic manifest creates no damage events")
	_assert(not bool(manifest.get("sets_multiplayer_truth", true)), "Synthetic manifest sets no multiplayer truth")
	_assert(not bool(manifest.get("updates_shortcuts", true)), "Synthetic manifest updates no shortcuts")


func _test_optional_actual_manifest() -> void:
	if not FileAccess.file_exists(MANIFEST_PATH):
		_assert(true, "TASK_869 manifest is optional before local capture")
		return
	var manifest: Dictionary = _read_json_dict(MANIFEST_PATH)
	_assert(_manifest_core_contract_ok(manifest), "Actual manifest satisfies TASK_869 core contract")
	_assert(_required_checks_present(manifest), "Actual manifest contains all required checks")
	_assert(String(manifest.get("gate", "")) == "review_ready" or String(manifest.get("gate", "")) == "manual_open", "Actual capture is reviewable")
	_assert(bool(manifest.get("desktop_screenshot_written", false)) or bool(manifest.get("window_screenshot_written", false)), "Actual capture writes at least one screenshot")
	_assert(not bool(manifest.get("manual_review_done", true)), "Actual manifest keeps manual review open")


func _test_manifest_roundtrip() -> void:
	var manifest: Dictionary = _read_json_dict(MANIFEST_PATH) if FileAccess.file_exists(MANIFEST_PATH) else _good_manifest()
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_869 output manifest")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_869", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_868", "Roundtrip keeps TASK_868 link")
	_assert(String(roundtrip.get("expected_los_setup_style_id", "")) == LOS_STYLE_ID, "Roundtrip keeps TASK_868 style")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps TASK_870 recommendation")
	_assert(bool(roundtrip.get("read_only_capture", false)), "Roundtrip keeps read-only capture boundary")


func _manifest_core_contract_ok(manifest: Dictionary) -> bool:
	return String(manifest.get("schema", "")) == SCHEMA \
		and String(manifest.get("task_id", "")) == "TASK_869" \
		and String(manifest.get("source_task_id", "")) == "TASK_868" \
		and String(manifest.get("source_status_findings_task_id", "")) == "TASK_867" \
		and String(manifest.get("source_status_recapture_task_id", "")) == "TASK_866" \
		and String(manifest.get("source_exchange_task_id", "")) == "TASK_844" \
		and String(manifest.get("source_capture_task_id", "")) == "TASK_837" \
		and String(manifest.get("launch_argument", "")) == FIRST_GO_ARG \
		and String(manifest.get("expected_los_setup_schema", "")) == LOS_SCHEMA \
		and String(manifest.get("expected_los_setup_style_id", "")) == LOS_STYLE_ID \
		and String(manifest.get("expected_exchange_schema", "")) == EXCHANGE_SCHEMA \
		and String(manifest.get("expected_exchange_style_id", "")) == EXCHANGE_STYLE_ID \
		and String(manifest.get("expected_runtime_status_schema", "")) == RUNTIME_STATUS_SCHEMA \
		and bool(manifest.get("manual_review_required", false)) \
		and bool(manifest.get("read_only_capture", false))


func _required_checks_present(manifest: Dictionary) -> bool:
	var checks: Array = Array(manifest.get("required_checks", []))
	for check_id in REQUIRED_CHECKS:
		if not checks.has(String(check_id)):
			return false
	return true


func _good_manifest() -> Dictionary:
	return {
		"schema": SCHEMA,
		"task_id": "TASK_869",
		"source_task_id": "TASK_868",
		"source_status_findings_task_id": "TASK_867",
		"source_status_recapture_task_id": "TASK_866",
		"source_exchange_task_id": "TASK_844",
		"source_capture_task_id": "TASK_837",
		"gate": "review_ready",
		"branch": "task/release-first-exchange-real-window-recapture-after-los-setup",
		"git_head": "test",
		"launch_argument": FIRST_GO_ARG,
		"wait_seconds": 38,
		"expected_los_setup_schema": LOS_SCHEMA,
		"expected_los_setup_style_id": LOS_STYLE_ID,
		"expected_exchange_schema": EXCHANGE_SCHEMA,
		"expected_exchange_style_id": EXCHANGE_STYLE_ID,
		"expected_runtime_status_schema": RUNTIME_STATUS_SCHEMA,
		"window_screenshot_written": true,
		"desktop_screenshot_written": true,
		"window_crop_trusted": true,
		"visible_window_gate": "review_ready",
		"window_screenshot_path": "tmp/release_first_exchange_los_setup_real_window_recapture.png",
		"desktop_screenshot_path": "tmp/release_first_exchange_los_setup_real_window_recapture_desktop.png",
		"required_checks": REQUIRED_CHECKS,
		"manual_review_required": true,
		"manual_review_done": false,
		"read_only_capture": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
		"recommended_next_task": NEXT_TASK,
	}


func _read_json_dict(path: String) -> Dictionary:
	var text: String = _read_text(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		return Dictionary(parsed)
	return {}


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
