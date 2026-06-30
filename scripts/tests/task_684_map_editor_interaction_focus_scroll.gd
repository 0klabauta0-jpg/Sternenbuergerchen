extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_684_map_editor_interaction_focus_scroll.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const MAP_PATH: String = "res://maps/station_outpost_64x64.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_684 Map Editor Interaction Focus Scroll ===")
	_test_docs()
	await _test_interaction_binding_focus_scroll()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_684: FAILED")
		quit(1)
		return
	print("TASK_684: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_684 task file exists")
	_assert(task_text.contains("Map Editor Interaction Focus Scroll"), "Task documents focus scroll")
	_assert(contract_text.contains("Editor Binding Focus Scroll"), "Interaction contract documents focus scroll")
	_assert(status_text.contains("TASK_684 - Map Editor Interaction Focus Scroll"), "Implementation status tracks TASK_684")
	_assert(roadmap_text.contains("TASK_684 - Map Editor Interaction Focus Scroll"), "Roadmap lists TASK_684")
	_assert(handbook_text.contains("TASK_684 - Map Editor Interaction Focus Scroll"), "Current handbook references TASK_684")
	_assert(handbook_text.contains('data-export-key="map_editor_interaction_focus_scroll.marker_select"'), "Current handbook exports TASK_684 marker-select status")


func _test_interaction_binding_focus_scroll() -> void:
	root.size = Vector2i(1920, 1080)
	var editor = MAP_EDITOR_SCENE.instantiate()
	editor.set("map_file_path", MAP_PATH)
	root.add_child(editor)
	await _wait_frames(20)
	var scenario: Dictionary = _load_json_dict(SCENARIO_PATH)
	scenario["map_file_path"] = MAP_PATH
	editor.call("set_mission_scenario_authoring_fields", scenario)
	await _wait_frames(8)

	_reset_property_scroll(editor)
	editor.call("_select_marker", "objective_point")
	await _wait_frames(8)
	_assert(_focus_scroll_is_ready(editor), "Marker selection focuses the interaction binding editor")

	_reset_property_scroll(editor)
	var preset_applied: bool = bool(editor.call("apply_interaction_binding_preset_to_editor", "computer_operate"))
	await _wait_frames(8)
	_assert(preset_applied, "Computer preset applies before focus check")
	_assert(_focus_scroll_is_ready(editor), "Preset apply keeps the binding editor visible")

	_reset_property_scroll(editor)
	var saved: bool = bool(editor.call("apply_selected_marker_interaction_binding_from_editor"))
	await _wait_frames(8)
	_assert(saved, "Binding apply succeeds before focus check")
	_assert(_focus_scroll_is_ready(editor), "Binding apply keeps the binding editor visible")

	_reset_property_scroll(editor)
	var removed: bool = bool(editor.call("remove_selected_marker_interaction_binding_from_editor"))
	await _wait_frames(8)
	_assert(removed, "Binding remove succeeds before focus check")
	_assert(_focus_scroll_is_ready(editor), "Binding remove keeps the binding editor visible")

	var snapshot: Dictionary = Dictionary(editor.call("get_mission_interaction_binding_editor_snapshot", false))
	var focus_scroll: Dictionary = Dictionary(snapshot.get("focus_scroll", {}))
	_assert(String(focus_scroll.get("schema", "")) == "sternenbuergerchen.map_editor_interaction_binding_focus_scroll.v1", "Focus scroll snapshot schema is stable")
	_assert(not bool(focus_scroll.get("ui_sets_gameplay_truth", true)), "Focus scroll does not set gameplay truth")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Binding editor still does not set gameplay truth")

	editor.queue_free()
	await _wait_frames(2)


func _focus_scroll_is_ready(editor: Node) -> bool:
	var snapshot: Dictionary = Dictionary(editor.call("get_mission_interaction_binding_editor_snapshot", false))
	var focus_scroll: Dictionary = Dictionary(snapshot.get("focus_scroll", {}))
	return bool(focus_scroll.get("property_panel_scrollable", false)) \
		and bool(focus_scroll.get("editor_visible_footprint", false)) \
		and int(focus_scroll.get("scroll_vertical", 0)) > 0 \
		and not bool(focus_scroll.get("ui_sets_gameplay_truth", true))


func _reset_property_scroll(editor: Node) -> void:
	var property_scroll := editor.get_node_or_null("UI/PropertyPanel/Margin") as ScrollContainer
	if property_scroll != null:
		property_scroll.scroll_vertical = 0


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _load_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
