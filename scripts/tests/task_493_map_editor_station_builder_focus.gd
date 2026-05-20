extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")

const TASK_DOC_PATH: String = "res://docs/tasks/TASK_493_map_editor_station_builder_focus.md"
const WORKFLOW_CONTRACT_PATH: String = "res://docs/dev/map_editor_asset_workflow_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_493 Map Editor Station Builder Focus ===")
	_test_docs()
	await _test_station_builder_toolbar_focus()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_docs() -> void:
	_assert(FileAccess.file_exists(TASK_DOC_PATH), "TASK_493 task file exists")
	_assert(_read_text(TASK_DOC_PATH).contains("Station/Outpost"), "Task documents the station/outpost focus")
	_assert(_read_text(WORKFLOW_CONTRACT_PATH).contains("Station Doors"), "Workflow contract documents Station Doors")
	_assert(_read_text(STATUS_PATH).contains("TASK_493 - Map Editor Station Builder Focus"), "Implementation status tracks TASK_493")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_493 - Map Editor Station Builder Focus"), "Roadmap lists TASK_493")


func _test_station_builder_toolbar_focus() -> void:
	var editor = MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(14)
	var snapshot: Dictionary = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	var builder: Dictionary = Dictionary(snapshot.get("runtime_builder_workbench", {}))
	var tool_ids: PackedStringArray = PackedStringArray(builder.get("tool_ids", PackedStringArray()))
	for hidden_tool in ["road_line", "rail_line"]:
		_assert(not tool_ids.has(hidden_tool), "Runtime builder hides %s from station-focused toolbar" % hidden_tool)
	for visible_tool in ["pipe_line", "wall_line", "cliff_line", "door_wall", "door_closed", "door_half", "door_open"]:
		_assert(tool_ids.has(visible_tool), "Runtime builder exposes %s" % visible_tool)

	_assert(bool(editor.call("activate_runtime_builder_tool", "door_wall")), "Door wall quick tool activates")
	snapshot = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	_assert(String(snapshot.get("selected_type_id", "")) == "station_wall_door", "Door wall quick tool selects station_wall_door")
	_assert(bool(editor.call("activate_runtime_builder_tool", "door_closed")), "Door closed quick tool activates")
	snapshot = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	_assert(String(snapshot.get("selected_type_id", "")) == "station_set_door_single_closed", "Door closed quick tool selects the closed door asset")
	_assert(bool(editor.call("activate_runtime_builder_tool", "door_half")), "Door half quick tool activates")
	snapshot = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	_assert(String(snapshot.get("selected_type_id", "")) == "station_set_door_single_half", "Door half quick tool selects the half-open door asset")
	_assert(bool(editor.call("activate_runtime_builder_tool", "door_open")), "Door open quick tool activates")
	snapshot = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	_assert(String(snapshot.get("selected_type_id", "")) == "station_set_door_single", "Door open quick tool selects the open door asset")

	var station_doors: Dictionary = Dictionary(snapshot.get("station_door_authoring", {}))
	_assert(not bool(station_doors.get("ui_sets_gameplay_truth", true)), "Door authoring snapshot is not gameplay truth")
	_assert(not bool(station_doors.get("runtime_animation_truth", true)), "Door authoring snapshot does not claim runtime animation")
	var single: Dictionary = Dictionary(station_doors.get("single", {}))
	var double: Dictionary = Dictionary(station_doors.get("double", {}))
	_assert(bool(single.get("available", false)), "Single-door closed/half/open states are available")
	_assert(bool(double.get("available", false)), "Double-door closed/half/open states are available")
	var single_states: Dictionary = Dictionary(single.get("states", {}))
	_assert(String(single_states.get("closed", "")) == "station_set_door_single_closed", "Single-door closed state maps to the closed asset")
	_assert(String(single_states.get("half", "")) == "station_set_door_single_half", "Single-door half state maps to the half-open asset")
	_assert(String(single_states.get("open", "")) == "station_set_door_single", "Single-door open state maps to the open asset")
	editor.queue_free()
	await _wait_frames(2)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
