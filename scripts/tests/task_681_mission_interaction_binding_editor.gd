extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_681_mission_interaction_binding_editor.md"
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
	print("=== TASK_681 Mission Interaction Binding Editor ===")
	_test_docs()
	await _test_editor_binding_authoring()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_681: FAILED")
		quit(1)
		return
	print("TASK_681: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_681 task file exists")
	_assert(task_text.contains("Mission Interaction Binding Editor"), "Task documents binding editor")
	_assert(contract_text.contains("Editor Binding Editor"), "Interaction contract documents editor binding editor")
	_assert(contract_text.contains("get_mission_interaction_binding_editor_snapshot"), "Interaction contract names editor snapshot")
	_assert(status_text.contains("TASK_681 - Mission Interaction Binding Editor"), "Implementation status tracks TASK_681")
	_assert(roadmap_text.contains("TASK_681 - Mission Interaction Binding Editor"), "Roadmap lists TASK_681")
	_assert(handbook_text.contains("TASK_681 - Mission Interaction Binding Editor"), "Current handbook references TASK_681")


func _test_editor_binding_authoring() -> void:
	var editor = MAP_EDITOR_SCENE.instantiate()
	editor.set("map_file_path", MAP_PATH)
	root.add_child(editor)
	await _wait_frames(16)
	var scenario: Dictionary = _load_json_dict(SCENARIO_PATH)
	scenario["map_file_path"] = MAP_PATH
	editor.call("set_mission_scenario_authoring_fields", scenario)
	await _wait_frames(8)

	var editor_panel := editor.get_node_or_null("UI/PropertyPanel/Margin/VBox/MarkerEditorPanel/InteractionBindingEditorPanel") as VBoxContainer
	_assert(editor_panel != null, "Marker panel has interaction binding editor panel")

	var snapshot: Dictionary = Dictionary(editor.call("get_mission_interaction_binding_editor_snapshot", false))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.map_editor_interaction_binding_editor.v1", "Editor snapshot schema is stable")
	_assert(not bool(snapshot.get("read_only", true)), "Editor snapshot is writable authoring UI")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Binding editor does not set gameplay truth")
	_assert(String(snapshot.get("write_scope", "")) == "MissionScenarioData.vertical_slice.interaction_points", "Binding editor writes scenario interaction points")

	editor.call("_select_marker", "objective_point")
	await _wait_frames(4)
	var selected_snapshot: Dictionary = Dictionary(editor.call("get_mission_interaction_binding_editor_snapshot", false))
	_assert(bool(selected_snapshot.get("has_selected_marker", false)), "Editor sees selected marker")
	_assert(bool(selected_snapshot.get("has_existing_binding", false)), "Editor sees existing objective binding")
	_assert(String(Dictionary(selected_snapshot.get("current_binding", {})).get("interaction_id", "")) == "station_computer", "Editor loads selected marker binding")

	var removed: bool = bool(editor.call("remove_selected_marker_interaction_binding_from_editor", "station_computer"))
	await _wait_frames(4)
	_assert(removed, "Editor removes selected marker binding")
	var after_remove: Dictionary = Dictionary(editor.call("get_mission_interaction_binding_inspector_snapshot", false))
	_assert(int(after_remove.get("binding_count", 0)) == 2, "Inspector sees one less binding after remove")
	_assert(int(after_remove.get("selected_marker_binding_count", 0)) == 0, "Removed marker has no selected binding")

	var applied: bool = bool(
		editor.call(
			"apply_selected_marker_interaction_binding_from_editor",
			{
				"interaction_id": "task_681_console",
				"display_name": "TASK 681 Console",
				"interaction_type": "computer",
				"required_order": "operate",
				"duration_seconds": 9.0,
				"radius_world": 99.0,
				"required_team": "team_alpha",
				"step_id": "task_681_step",
				"required_state": "task_681_done",
			}
		)
	)
	await _wait_frames(4)
	_assert(applied, "Editor applies marker binding")
	var after_apply: Dictionary = Dictionary(editor.call("get_mission_interaction_binding_inspector_snapshot", false))
	_assert(int(after_apply.get("binding_count", 0)) == 3, "Inspector sees restored binding count")
	_assert(_selected_bindings_contain(after_apply, "task_681_console"), "Inspector lists newly applied binding")
	var scenario_dict: Dictionary = Dictionary(editor.call("get_current_mission_scenario_dict"))
	var saved_binding: Dictionary = _find_interaction_point(scenario_dict, "task_681_console")
	_assert(not saved_binding.is_empty(), "Scenario dict contains applied interaction point")
	_assert(String(saved_binding.get("marker_id", "")) == "objective_point", "Applied binding targets selected marker")
	_assert(String(saved_binding.get("required_order", "")) == "operate", "Applied binding stores required order")
	_assert(is_equal_approx(float(saved_binding.get("duration_seconds", 0.0)), 9.0), "Applied binding stores duration")
	_assert(is_equal_approx(float(saved_binding.get("radius_world", 0.0)), 99.0), "Applied binding stores radius")

	var usability: Dictionary = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	var editor_snapshot: Dictionary = Dictionary(usability.get("interaction_binding_editor", {}))
	var inspector_snapshot: Dictionary = Dictionary(Dictionary(usability.get("inspector", {})).get("interaction_binding_editor", {}))
	_assert(String(editor_snapshot.get("schema", "")) == "sternenbuergerchen.map_editor_interaction_binding_editor.v1", "Usability snapshot exports binding editor")
	_assert(String(inspector_snapshot.get("schema", "")) == "sternenbuergerchen.map_editor_interaction_binding_editor.v1", "Inspector snapshot exports binding editor")

	editor.queue_free()
	await _wait_frames(2)


func _selected_bindings_contain(snapshot: Dictionary, interaction_id: String) -> bool:
	for entry_variant in Array(snapshot.get("selected_marker_bindings", [])):
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("interaction_id", "")).strip_edges() == interaction_id:
			return true
	return false


func _find_interaction_point(scenario: Dictionary, interaction_id: String) -> Dictionary:
	var vertical_slice: Dictionary = Dictionary(scenario.get("vertical_slice", {}))
	for entry_variant in Array(vertical_slice.get("interaction_points", [])):
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("interaction_id", "")).strip_edges() == interaction_id:
			return entry
	return {}


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
