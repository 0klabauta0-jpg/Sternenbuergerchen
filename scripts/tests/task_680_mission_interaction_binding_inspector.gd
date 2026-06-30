extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")
const INTERACTION_BINDING_SCRIPT: GDScript = preload("res://scripts/mission/mission_interaction_point_binding.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_680_mission_interaction_binding_inspector.md"
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
	print("=== TASK_680 Mission Interaction Binding Inspector ===")
	_test_docs()
	await _test_editor_binding_inspector()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_680: FAILED")
		quit(1)
		return
	print("TASK_680: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_680 task file exists")
	_assert(task_text.contains("Mission Interaction Binding Inspector"), "Task documents binding inspector")
	_assert(contract_text.contains("Editor Binding Inspector"), "Interaction contract documents editor binding inspector")
	_assert(contract_text.contains("get_mission_interaction_binding_inspector_snapshot"), "Interaction contract names editor inspector snapshot")
	_assert(status_text.contains("TASK_680 - Mission Interaction Binding Inspector"), "Implementation status tracks TASK_680")
	_assert(roadmap_text.contains("TASK_680 - Mission Interaction Binding Inspector"), "Roadmap lists TASK_680")
	_assert(handbook_text.contains("TASK_680 - Mission Interaction Binding Inspector"), "Current handbook references TASK_680")


func _test_editor_binding_inspector() -> void:
	var editor = MAP_EDITOR_SCENE.instantiate()
	editor.set("map_file_path", MAP_PATH)
	root.add_child(editor)
	await _wait_frames(16)
	var scenario: Dictionary = _load_json_dict(SCENARIO_PATH)
	scenario["map_file_path"] = MAP_PATH
	editor.call("set_mission_scenario_authoring_fields", scenario)
	await _wait_frames(8)

	var label := editor.get_node_or_null("UI/PropertyPanel/Margin/VBox/MarkerEditorPanel/InteractionBindingInspectorLabel") as Label
	_assert(label != null, "Marker panel has interaction binding inspector label")

	var snapshot: Dictionary = Dictionary(editor.call("get_mission_interaction_binding_inspector_snapshot", false))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.map_editor_interaction_binding_inspector.v1", "Inspector snapshot schema is stable")
	_assert(String(snapshot.get("source_schema", "")) == INTERACTION_BINDING_SCRIPT.SNAPSHOT_SCHEMA, "Inspector reads binding source schema")
	_assert(bool(snapshot.get("read_only", false)), "Inspector snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Inspector does not set gameplay truth")
	_assert(bool(snapshot.get("valid", false)), "Inspector binding snapshot validates")
	_assert(int(snapshot.get("binding_count", 0)) == 3, "Inspector sees three Frontier Probe bindings")
	_assert(PackedStringArray(snapshot.get("bound_marker_ids", PackedStringArray())).has("objective_point"), "Inspector lists objective marker as bound")
	_assert(PackedStringArray(snapshot.get("bound_marker_ids", PackedStringArray())).has("spawn_alpha"), "Inspector lists cargo marker as bound")
	_assert(PackedStringArray(snapshot.get("missing_marker_ids", PackedStringArray())).is_empty(), "Inspector has no missing markers on Frontier Probe map")
	_assert(String(snapshot.get("label_text", "")).contains("Bindings: 3"), "Inspector summary label mentions binding count")

	editor.call("_select_marker", "objective_point")
	await _wait_frames(4)
	var objective_snapshot: Dictionary = Dictionary(editor.call("get_mission_interaction_binding_inspector_snapshot", false))
	_assert(int(objective_snapshot.get("selected_marker_binding_count", 0)) >= 1, "Objective marker reports selected binding")
	_assert(_selected_bindings_contain(objective_snapshot, "station_computer"), "Objective marker is bound to station computer")
	_assert(String(objective_snapshot.get("label_text", "")).contains("station_computer"), "Objective marker label names station computer")
	_assert(label != null and label.text.contains("station_computer"), "Visible label updates for station computer")

	editor.call("_select_marker", "spawn_alpha")
	await _wait_frames(4)
	var cargo_snapshot: Dictionary = Dictionary(editor.call("get_mission_interaction_binding_inspector_snapshot", false))
	_assert(_selected_bindings_contain(cargo_snapshot, "cargo_landing_hold"), "Spawn alpha marker is bound to cargo hold")
	_assert(String(cargo_snapshot.get("label_text", "")).contains("cargo_landing_hold"), "Cargo marker label names cargo hold")
	_assert(bool(cargo_snapshot.get("line_within_limit", false)), "Cargo marker inspector line stays within budget")

	var usability: Dictionary = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	var inspector: Dictionary = Dictionary(usability.get("interaction_binding_inspector", {}))
	var right_panel: Dictionary = Dictionary(Dictionary(usability.get("inspector", {})).get("interaction_binding_inspector", {}))
	_assert(int(inspector.get("binding_count", 0)) == 3, "Usability snapshot exports interaction binding inspector")
	_assert(int(right_panel.get("binding_count", 0)) == 3, "Inspector snapshot exports interaction binding inspector")

	editor.queue_free()
	await _wait_frames(2)


func _selected_bindings_contain(snapshot: Dictionary, interaction_id: String) -> bool:
	for entry_variant in Array(snapshot.get("selected_marker_bindings", [])):
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("interaction_id", "")).strip_edges() == interaction_id:
			return true
	return false


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
