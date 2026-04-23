extends SceneTree

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const PHASE_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tests/phase_controller.gd")
const TACTICAL_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")
const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_114 Legacy Guard Verifier ===")
	_test_legacy_wall_map_is_rejected()
	await _test_map_editor_shows_visible_old_file_warning()
	_test_phase_controller_rejects_selected_phase_only_state()
	_test_tactical_controller_rejects_legacy_planning_state()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_legacy_wall_map_is_rejected() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", "res://maps/legacy_wall_type_unsupported.json")
	_assert(map_data != null, "Legacy wall fixture returns a TerrainMapData instance")
	_assert(map_data != null and map_data.has_method("has_load_issue") and bool(map_data.call("has_load_issue")), "Legacy wall map is flagged as unsupported")
	_assert(map_data != null and String(map_data.call("get_load_issue_message")).contains("Old map file detected"), "Legacy wall map reports a clear old-file message")
	_assert(map_data != null and Array(map_data.call("get_tiles")).is_empty(), "Legacy wall map does not load any tiles")


func _test_map_editor_shows_visible_old_file_warning() -> void:
	var editor = MAP_EDITOR_SCENE.instantiate()
	editor.set("map_file_path", "res://maps/legacy_wall_type_unsupported.json")
	root.add_child(editor)
	for _index in range(5):
		await process_frame
	var dialog := editor.get_node("UI/LoadIssueDialog") as AcceptDialog
	_assert(dialog != null and dialog.visible, "MapEditor shows a visible old-file dialog for legacy wall maps")
	_assert(dialog != null and String(dialog.dialog_text).contains("Das ist eine alte Datei"), "MapEditor dialog uses a clear old-file explanation")
	_assert(String(editor.get("_current_map_path")) == "res://maps/new_map.json", "MapEditor falls back to a fresh new-map target after rejecting the old file")
	editor.queue_free()
	await process_frame


func _test_phase_controller_rejects_selected_phase_only_state() -> void:
	var phase_controller = PHASE_CONTROLLER_SCRIPT.new()
	var legacy_state: Dictionary = _load_json_dictionary("res://tests/fixtures/legacy_selected_phase_planning_state.json")
	phase_controller.call("load_from_planning_state", legacy_state, -1, true)
	_assert(String(phase_controller.call("get_last_load_issue_message")).contains("Old planning data detected"), "PhaseController reports old selected_phase data")
	_assert(int(phase_controller.call("get_selected_phase_index")) == 1, "PhaseController keeps the default selected phase instead of guessing")
	_assert(int(phase_controller.call("get_active_phase_index")) == 0, "PhaseController keeps the default active phase for rejected legacy data")
	phase_controller.free()


func _test_tactical_controller_rejects_legacy_planning_state() -> void:
	var controller = TACTICAL_CONTROLLER_SCRIPT.new()
	var legacy_state: Dictionary = _load_json_dictionary("res://tests/fixtures/legacy_selected_phase_planning_state.json")
	controller.call("set_planning_state", legacy_state)
	_assert(String(controller.call("get_last_planning_state_issue")).contains("Old planning data detected"), "Tactical controller exposes a clear old-planning warning")
	_assert(Array(controller.call("get_order_plans_snapshot")).is_empty(), "Legacy order plans are not migrated into the new phase space")
	_assert(not controller.has_method("get_phase_state_snapshot") or Dictionary(controller.call("get_phase_state_snapshot")).is_empty(), "Scene-free tactical verifier does not need to hydrate the live phase scene to reject legacy data")
	_assert(String(controller.call("_build_strategic_status_text")).contains("Alte Planungsdaten erkannt"), "Tactical strategic status shows a visible old-planning warning")
	controller.free()


func _load_json_dictionary(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return Dictionary(parsed)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
