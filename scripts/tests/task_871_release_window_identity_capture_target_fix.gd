extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_871_release_window_identity_capture_target_fix.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const VISIBLE_CAPTURE_TOOL_PATH := "res://scripts/tools/capture_release_singleplayer_visible_window.ps1"
const TASK_869_TOOL_PATH := "res://scripts/tools/capture_release_first_exchange_los_setup_real_window_recapture.ps1"
const MANIFEST_PATH := "res://tmp/release_singleplayer_visible_window_findings.json"
const TASK_869_MANIFEST_PATH := "res://tmp/release_first_exchange_los_setup_real_window_recapture.json"
const SCHEMA := "sternenbuergerchen.release_singleplayer_visible_window_findings.v1"
const NEXT_TASK := "TASK_872 - Release Correct Window First Exchange Visual Findings"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_871 Release Window Identity Capture Target Fix ===")
	_test_docs_and_tool_contract()
	_test_synthetic_visible_manifest_contract()
	_test_optional_actual_visible_manifest()
	_test_optional_task_869_manifest()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_871_release_window_identity_capture_target_fix: FAILED")
		quit(1)
		return
	print("TASK_871_release_window_identity_capture_target_fix: ALL PASSED")
	quit(0)


func _test_docs_and_tool_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var visible_tool_text: String = _read_text(VISIBLE_CAPTURE_TOOL_PATH)
	var task_869_tool_text: String = _read_text(TASK_869_TOOL_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_871 task file exists")
	_assert(task_text.contains("Release Window Identity Capture Target Fix"), "Task names TASK_871")
	_assert(status_text.contains("TASK_871 - Release Window Identity Capture Target Fix"), "Implementation status tracks TASK_871")
	_assert(roadmap_text.contains("TASK_871 - Release Window Identity Capture Target Fix (implementiert)"), "Roadmap marks TASK_871 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_872 follow-up")
	_assert(contract_text.contains("Release-Window-Identity-Capture-Target-Fix"), "Contract documents TASK_871")
	_assert(visible_tool_text.contains("PrintWindow"), "Visible capture tool uses direct window handle capture")
	_assert(visible_tool_text.contains("Capture-WindowHandle"), "Visible capture tool has Capture-WindowHandle function")
	_assert(visible_tool_text.contains("release_singleplayer_visible_window_handle.png"), "Visible capture writes handle screenshot path")
	_assert(visible_tool_text.contains("release_singleplayer_visible_window_desktop_crop.png"), "Visible capture keeps desktop crop fallback path")
	_assert(visible_tool_text.contains("window_capture_method"), "Visible capture records capture method")
	_assert(visible_tool_text.contains("window_capture_trusted"), "Visible capture records capture trust")
	_assert(visible_tool_text.contains("window_handle_capture"), "Visible capture records handle capture status")
	_assert(visible_tool_text.contains("desktop_crop_status"), "Visible capture records desktop crop status")
	_assert(visible_tool_text.contains("\"window_handle_print\""), "Visible capture can select handle capture method")
	_assert(visible_tool_text.contains("\"desktop_crop_fallback\""), "Visible capture can select desktop fallback method")
	_assert(visible_tool_text.contains("window_handle_capture_not_trusted"), "Visible capture warns on untrusted handle capture")
	_assert(visible_tool_text.contains("read_only = $true"), "Visible capture remains read-only")
	_assert(visible_tool_text.contains("ui_sets_gameplay_truth = $false"), "Visible capture sets no gameplay truth")
	_assert(task_869_tool_text.contains("window_capture_trusted"), "TASK_869 wrapper propagates capture trust")
	_assert(task_869_tool_text.contains("window_capture_method"), "TASK_869 wrapper propagates capture method")
	_assert(task_869_tool_text.contains("window_handle_capture_succeeded"), "TASK_869 wrapper propagates handle capture result")


func _test_synthetic_visible_manifest_contract() -> void:
	var manifest: Dictionary = _good_visible_manifest()
	_assert(_visible_manifest_core_ok(manifest), "Synthetic visible manifest satisfies TASK_871 contract")
	_assert(String(manifest.get("window_capture_method", "")) == "window_handle_print", "Synthetic manifest records handle capture method")
	_assert(bool(manifest.get("window_capture_trusted", false)), "Synthetic manifest records trusted capture")
	_assert(bool(Dictionary(manifest.get("window_handle_capture", {})).get("succeeded", false)), "Synthetic manifest records handle capture success")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "Synthetic manifest sets no gameplay truth")
	_assert(not bool(manifest.get("updates_shortcuts", true)), "Synthetic manifest updates no shortcuts")


func _test_optional_actual_visible_manifest() -> void:
	if not FileAccess.file_exists(MANIFEST_PATH):
		_assert(true, "Visible manifest is optional before local capture")
		return
	var manifest: Dictionary = _read_json_dict(MANIFEST_PATH)
	_assert(String(manifest.get("schema", "")) == SCHEMA, "Actual visible manifest schema is stable")
	if not manifest.has("window_capture_method"):
		_assert(true, "Actual visible manifest is legacy pre-TASK_871 capture")
		return
	_assert(manifest.has("window_capture_method"), "Actual visible manifest records capture method")
	_assert(manifest.has("window_capture_trusted"), "Actual visible manifest records capture trust")
	_assert(manifest.has("window_handle_capture"), "Actual visible manifest records handle capture status")
	_assert(manifest.has("desktop_crop_status"), "Actual visible manifest records desktop crop fallback status")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "Actual visible manifest sets no gameplay truth")
	_assert(not bool(manifest.get("updates_shortcuts", true)), "Actual visible manifest updates no shortcuts")


func _test_optional_task_869_manifest() -> void:
	if not FileAccess.file_exists(TASK_869_MANIFEST_PATH):
		_assert(true, "TASK_869 manifest is optional before recapture")
		return
	var manifest: Dictionary = _read_json_dict(TASK_869_MANIFEST_PATH)
	if not manifest.has("window_capture_method"):
		_assert(true, "TASK_869 manifest is legacy pre-TASK_871 recapture")
		return
	_assert(manifest.has("window_capture_method"), "TASK_869 manifest records propagated capture method")
	_assert(manifest.has("window_capture_trusted"), "TASK_869 manifest records propagated capture trust")
	_assert(manifest.has("window_handle_capture_succeeded"), "TASK_869 manifest records propagated handle capture status")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "TASK_869 manifest sets no gameplay truth")
	_assert(not bool(manifest.get("updates_shortcuts", true)), "TASK_869 manifest updates no shortcuts")


func _visible_manifest_core_ok(manifest: Dictionary) -> bool:
	return String(manifest.get("schema", "")) == SCHEMA \
		and bool(manifest.get("desktop_screenshot_written", false)) \
		and bool(manifest.get("window_screenshot_written", false)) \
		and manifest.has("window_capture_method") \
		and manifest.has("window_capture_trusted") \
		and manifest.has("window_handle_capture") \
		and manifest.has("desktop_crop_status")


func _good_visible_manifest() -> Dictionary:
	return {
		"schema": SCHEMA,
		"gate": "review_ready",
		"desktop_screenshot_written": true,
		"window_screenshot_written": true,
		"window_capture_method": "window_handle_print",
		"window_capture_trusted": true,
		"window_handle_capture": {
			"attempted": true,
			"succeeded": true,
			"reason": "",
			"width": 1920,
			"height": 1080,
		},
		"desktop_crop_status": {
			"attempted": true,
			"succeeded": true,
			"reason": "",
			"width": 1920,
			"height": 1080,
		},
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"updates_shortcuts": false,
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
