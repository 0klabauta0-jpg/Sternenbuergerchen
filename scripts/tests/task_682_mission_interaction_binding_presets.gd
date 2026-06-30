extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_682_mission_interaction_binding_presets.md"
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
	print("=== TASK_682 Mission Interaction Binding Presets ===")
	_test_docs()
	await _test_editor_binding_presets()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_682: FAILED")
		quit(1)
		return
	print("TASK_682: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_682 task file exists")
	_assert(task_text.contains("Mission Interaction Binding Presets"), "Task documents binding presets")
	_assert(contract_text.contains("Editor Binding Presets"), "Interaction contract documents binding presets")
	_assert(contract_text.contains("available_presets"), "Interaction contract names preset snapshot export")
	_assert(status_text.contains("TASK_682 - Mission Interaction Binding Presets"), "Implementation status tracks TASK_682")
	_assert(roadmap_text.contains("TASK_682 - Mission Interaction Binding Presets"), "Roadmap lists TASK_682")
	_assert(handbook_text.contains("TASK_682 - Mission Interaction Binding Presets"), "Current handbook references TASK_682")


func _test_editor_binding_presets() -> void:
	var editor = MAP_EDITOR_SCENE.instantiate()
	editor.set("map_file_path", MAP_PATH)
	root.add_child(editor)
	await _wait_frames(16)
	var scenario: Dictionary = _load_json_dict(SCENARIO_PATH)
	scenario["map_file_path"] = MAP_PATH
	editor.call("set_mission_scenario_authoring_fields", scenario)
	await _wait_frames(8)

	var preset_option := editor.get_node_or_null("UI/PropertyPanel/Margin/VBox/MarkerEditorPanel/InteractionBindingEditorPanel/InteractionBindingPresetRow/InteractionBindingPresetOption") as OptionButton
	var state_line_edit := editor.get_node_or_null("UI/PropertyPanel/Margin/VBox/MarkerEditorPanel/InteractionBindingEditorPanel/InteractionBindingStateRow/InteractionBindingStateLineEdit") as LineEdit
	var requires_line_edit := editor.get_node_or_null("UI/PropertyPanel/Margin/VBox/MarkerEditorPanel/InteractionBindingEditorPanel/InteractionBindingStateRow/InteractionBindingRequiresLineEdit") as LineEdit
	_assert(preset_option != null, "Binding editor has preset option")
	_assert(state_line_edit != null, "Binding editor has required state field")
	_assert(requires_line_edit != null, "Binding editor has requires step field")

	var catalog: Array = Array(editor.call("get_mission_interaction_binding_preset_catalog"))
	_assert(catalog.size() >= 6, "Preset catalog has core presets")
	_assert(_preset_catalog_contains(catalog, "computer_operate"), "Preset catalog contains computer preset")
	_assert(_preset_catalog_contains(catalog, "cargo_landing_hold"), "Preset catalog contains cargo preset")

	editor.call("_select_marker", "objective_point")
	await _wait_frames(4)
	var computer_applied: bool = bool(editor.call("apply_interaction_binding_preset_to_editor", "computer_operate"))
	await _wait_frames(4)
	_assert(computer_applied, "Computer preset applies to selected marker")
	var computer_snapshot: Dictionary = Dictionary(editor.call("get_mission_interaction_binding_editor_snapshot", false))
	_assert(String(computer_snapshot.get("selected_preset_id", "")) == "computer_operate", "Editor snapshot records computer preset")
	var computer_preview: Dictionary = Dictionary(computer_snapshot.get("preset_preview", {}))
	_assert(String(computer_preview.get("interaction_type", "")) == "computer", "Computer preset previews computer type")
	_assert(String(computer_preview.get("required_order", "")) == "operate", "Computer preset previews operate order")
	_assert(is_equal_approx(float(computer_preview.get("duration_seconds", 0.0)), 18.0), "Computer preset previews 18 seconds")
	_assert(is_equal_approx(float(computer_preview.get("radius_world", 0.0)), 96.0), "Computer preset previews 96 radius")

	var saved_computer: bool = bool(editor.call("apply_selected_marker_interaction_binding_from_editor"))
	await _wait_frames(4)
	_assert(saved_computer, "Computer preset can be saved through existing apply path")
	var scenario_after_computer: Dictionary = Dictionary(editor.call("get_current_mission_scenario_dict"))
	var computer_binding: Dictionary = _find_interaction_point_by_marker(scenario_after_computer, "objective_point")
	_assert(String(computer_binding.get("required_order", "")) == "operate", "Saved computer preset stores operate order")
	_assert(is_equal_approx(float(computer_binding.get("duration_seconds", 0.0)), 18.0), "Saved computer preset stores duration")
	_assert(String(computer_binding.get("required_state", "")).ends_with("_controlled"), "Saved computer preset stores controlled state")

	editor.call("_select_marker", "spawn_alpha")
	await _wait_frames(4)
	var cargo_applied: bool = bool(editor.call("apply_interaction_binding_preset_to_editor", "cargo_landing_hold"))
	await _wait_frames(4)
	_assert(cargo_applied, "Cargo preset applies to selected marker")
	var cargo_snapshot: Dictionary = Dictionary(editor.call("get_mission_interaction_binding_editor_snapshot", false))
	var cargo_preview: Dictionary = Dictionary(cargo_snapshot.get("preset_preview", {}))
	_assert(String(cargo_snapshot.get("selected_preset_id", "")) == "cargo_landing_hold", "Editor snapshot records cargo preset")
	_assert(String(cargo_preview.get("required_state", "")) == "cargo_departed", "Cargo preset previews cargo state")
	_assert(String(cargo_preview.get("requires_step_id", "")) == "disable_air_defense", "Cargo preset previews AA prerequisite")
	_assert(requires_line_edit != null and requires_line_edit.text == "disable_air_defense", "Cargo preset fills requires field")

	var saved_cargo: bool = bool(editor.call("apply_selected_marker_interaction_binding_from_editor"))
	await _wait_frames(4)
	_assert(saved_cargo, "Cargo preset can be saved through existing apply path")
	var scenario_after_cargo: Dictionary = Dictionary(editor.call("get_current_mission_scenario_dict"))
	var cargo_binding: Dictionary = _find_interaction_point(scenario_after_cargo, "cargo_landing_hold")
	_assert(String(cargo_binding.get("marker_id", "")) == "spawn_alpha", "Saved cargo preset targets selected marker")
	_assert(String(cargo_binding.get("required_order", "")) == "defend", "Saved cargo preset stores defend order")
	_assert(String(cargo_binding.get("requires_step_id", "")) == "disable_air_defense", "Saved cargo preset stores AA prerequisite")
	_assert(String(cargo_binding.get("required_state", "")) == "cargo_departed", "Saved cargo preset stores required state")

	var usability: Dictionary = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	var editor_snapshot: Dictionary = Dictionary(usability.get("interaction_binding_editor", {}))
	_assert(int(editor_snapshot.get("preset_count", 0)) >= 6, "Usability snapshot exports preset count")
	_assert(not bool(editor_snapshot.get("ui_sets_gameplay_truth", true)), "Preset snapshot does not set gameplay truth")

	editor.queue_free()
	await _wait_frames(2)


func _preset_catalog_contains(catalog: Array, preset_id: String) -> bool:
	for preset_variant in catalog:
		var preset: Dictionary = Dictionary(preset_variant)
		if String(preset.get("preset_id", "")).strip_edges() == preset_id:
			return true
	return false


func _find_interaction_point_by_marker(scenario: Dictionary, marker_id: String) -> Dictionary:
	var vertical_slice: Dictionary = Dictionary(scenario.get("vertical_slice", {}))
	for entry_variant in Array(vertical_slice.get("interaction_points", [])):
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("marker_id", "")).strip_edges() == marker_id:
			return entry
	return {}


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
