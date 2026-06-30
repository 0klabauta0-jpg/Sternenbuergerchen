extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")

const TASK_DOC_PATH: String = "res://docs/tasks/TASK_670_builder_drag_preview_handles.md"
const WORKFLOW_CONTRACT_PATH: String = "res://docs/dev/map_editor_asset_workflow_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_670 Builder Drag Preview Handles ===")
	_test_docs()
	await _test_preview_handles()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_docs() -> void:
	_assert(FileAccess.file_exists(TASK_DOC_PATH), "TASK_670 task file exists")
	_assert(_read_text(TASK_DOC_PATH).contains("Builder Drag Preview Handles"), "Task documents builder drag preview handles")
	_assert(_read_text(WORKFLOW_CONTRACT_PATH).contains("Handles"), "Workflow contract documents drag preview handles")
	_assert(_read_text(STATUS_PATH).contains("TASK_670 - Builder Drag Preview Handles"), "Implementation status tracks TASK_670")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_670 - Builder Drag Preview Handles"), "Roadmap lists TASK_670")
	_assert(_read_text(HANDBOOK_PATH).contains("TASK_670 - Builder Drag Preview Handles"), "Current handbook references TASK_670")


func _test_preview_handles() -> void:
	var editor = MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(14)
	var primary_view := editor.get_node_or_null("Primary3DView")
	_assert(primary_view != null, "Editor has a primary 3D view for handle preview counters")
	if primary_view == null:
		editor.queue_free()
		await _wait_frames(2)
		return

	_assert(bool(editor.call("activate_runtime_builder_tool", "pipe_line")), "Pipe line tool activates before handle preview")
	_assert(bool(editor.call("preview_runtime_network_path_for_authoring", "pipe", Vector2i(1, 1), Vector2i(3, 2))), "Pipe preview path can be built")
	await _wait_frames(2)

	var snapshot: Dictionary = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	var builder: Dictionary = Dictionary(snapshot.get("runtime_builder_workbench", {}))
	var preview: Dictionary = Dictionary(builder.get("network_drag_preview", {}))
	var visual_preview: Dictionary = Dictionary(preview.get("visual_preview", {}))
	var handles: Array = Array(preview.get("handles", []))
	var segment_labels: Array = Array(preview.get("segment_labels", []))
	var render_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))

	_assert(int(preview.get("path_count", 0)) == 4, "Preview keeps the expected elbow path length")
	_assert(int(preview.get("handle_count", 0)) == 4, "Preview reports one handle per path tile")
	_assert(handles.size() == 4, "Preview exposes handle entries")
	_assert(int(preview.get("segment_label_count", 0)) == 3, "Preview reports one label per segment")
	_assert(segment_labels.size() == 3, "Preview exposes segment label entries")
	_assert(String(Dictionary(handles[0]).get("role", "")) == "start", "First handle is marked as start")
	_assert(String(Dictionary(handles[0]).get("label", "")) == "S", "Start handle has a compact label")
	_assert(String(Dictionary(handles[handles.size() - 1]).get("role", "")) == "target", "Last handle is marked as target")
	_assert(String(Dictionary(handles[handles.size() - 1]).get("label", "")) == "T", "Target handle has a compact label")
	_assert(String(Dictionary(segment_labels[0]).get("label", "")) == "01", "First segment label is numbered")
	_assert(int(visual_preview.get("handle_count", 0)) == 4, "Visual preview carries handle count")
	_assert(int(visual_preview.get("segment_label_count", 0)) == 3, "Visual preview carries segment label count")
	_assert(not bool(preview.get("ui_sets_gameplay_truth", true)), "Handle preview remains read-only")
	_assert(int(render_snapshot.get("editor_network_drag_preview_handle_count", 0)) == 4, "Primary3DView reports handle count")
	_assert(int(render_snapshot.get("editor_network_drag_preview_segment_label_count", 0)) == 3, "Primary3DView reports segment label count")
	_assert(int(render_snapshot.get("editor_network_drag_preview_marker_count", 0)) == 2, "Existing start and target markers remain compatible")

	editor.call("clear_runtime_network_preview_for_authoring")
	await _wait_frames(2)
	snapshot = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	builder = Dictionary(snapshot.get("runtime_builder_workbench", {}))
	preview = Dictionary(builder.get("network_drag_preview", {}))
	render_snapshot = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(preview.get("handle_count", 0)) == 0, "Clear removes editor handle preview count")
	_assert(int(render_snapshot.get("editor_network_drag_preview_handle_count", 0)) == 0, "Clear removes render handle count")
	_assert(int(render_snapshot.get("editor_network_drag_preview_segment_label_count", 0)) == 0, "Clear removes render segment label count")

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
