extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")

const TASK_DOC_PATH: String = "res://docs/tasks/TASK_521_builder_drag_preview_visual_polish.md"
const WORKFLOW_CONTRACT_PATH: String = "res://docs/dev/map_editor_asset_workflow_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_521 Builder Drag Preview Visual Polish ===")
	_test_docs()
	await _test_network_drag_preview_visuals()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_docs() -> void:
	_assert(FileAccess.file_exists(TASK_DOC_PATH), "TASK_521 task file exists")
	_assert(_read_text(TASK_DOC_PATH).contains("Builder Drag Preview Visual Polish"), "Task documents builder drag preview polish")
	_assert(_read_text(WORKFLOW_CONTRACT_PATH).contains("Sichtbare Drag-Preview"), "Workflow contract documents visible drag preview")
	_assert(_read_text(STATUS_PATH).contains("TASK_521 - Builder Drag Preview Visual Polish"), "Implementation status tracks TASK_521")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_521 - Builder Drag Preview Visual Polish"), "Roadmap lists TASK_521")
	_assert(_read_text(REPORT_PATH).contains("TASK_521 - Builder Drag Preview Visual Polish"), "Review report references TASK_521")


func _test_network_drag_preview_visuals() -> void:
	var editor = MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(14)
	var map_data = editor.get("_terrain_map_data")
	_assert(map_data != null, "Editor exposes terrain map data for preview verification")
	var primary_view := editor.get_node_or_null("Primary3DView")
	_assert(primary_view != null, "Editor has a primary 3D view for network preview visuals")
	if map_data == null or primary_view == null:
		editor.queue_free()
		await _wait_frames(2)
		return

	_assert(bool(editor.call("activate_runtime_builder_tool", "pipe_line")), "Pipe line tool activates before preview")
	var untouched_before: String = _tile_object_type_id(map_data, Vector2i(2, 1))
	_assert(bool(editor.call("preview_runtime_network_path_for_authoring", "pipe", Vector2i(1, 1), Vector2i(3, 2))), "Pipe preview path can be built without applying")
	await _wait_frames(2)
	var snapshot: Dictionary = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	var builder: Dictionary = Dictionary(snapshot.get("runtime_builder_workbench", {}))
	var preview: Dictionary = Dictionary(builder.get("network_drag_preview", {}))
	var visual_preview: Dictionary = Dictionary(preview.get("visual_preview", {}))
	_assert(bool(preview.get("visual_active", false)), "Builder snapshot marks network visual preview active")
	_assert(String(preview.get("kind", "")) == "pipe", "Builder preview keeps network kind")
	_assert(int(preview.get("path_count", 0)) == 4, "Builder preview path has the expected elbow length")
	_assert(int(preview.get("visual_segment_count", 0)) == 3, "Builder preview reports visible segment count")
	_assert(not bool(preview.get("ui_sets_gameplay_truth", true)), "Builder preview is read-only against gameplay truth")
	_assert(int(visual_preview.get("segment_count", 0)) == 3, "Visual preview contains renderable segments")
	_assert(_tile_object_type_id(map_data, Vector2i(2, 1)) == untouched_before, "Preview does not mutate tile object truth")

	var render_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(bool(render_snapshot.get("editor_network_drag_preview_active", false)), "Primary3DView marks network preview active")
	_assert(String(render_snapshot.get("editor_network_drag_preview_kind", "")) == "pipe", "Primary3DView keeps network preview kind")
	_assert(int(render_snapshot.get("editor_network_drag_preview_path_count", 0)) == 4, "Primary3DView reports preview path count")
	_assert(int(render_snapshot.get("editor_network_drag_preview_segment_count", 0)) == 3, "Primary3DView renders preview segments")
	_assert(int(render_snapshot.get("editor_network_drag_preview_marker_count", 0)) == 2, "Primary3DView renders start and target markers")

	_assert(bool(editor.call("apply_runtime_network_path_for_authoring", "pipe", Vector2i(1, 1), Vector2i(3, 2))), "Applying the path still commits network tiles")
	await _wait_frames(2)
	snapshot = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	builder = Dictionary(snapshot.get("runtime_builder_workbench", {}))
	preview = Dictionary(builder.get("network_drag_preview", {}))
	render_snapshot = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(not bool(preview.get("dragging", true)), "Apply clears the editor dragging state")
	_assert(int(preview.get("visual_segment_count", 0)) == 0, "Apply clears editor visual preview segments")
	_assert(int(render_snapshot.get("editor_network_drag_preview_segment_count", 0)) == 0, "Apply clears Primary3DView preview segments")
	_assert(_tile_object_type_id(map_data, Vector2i(2, 1)) == "spacekit_pipe_straight", "Apply writes the pipe object truth")

	_assert(bool(editor.call("preview_runtime_network_path_for_authoring", "wall", Vector2i(4, 1), Vector2i(4, 3))), "Wall preview path can be built")
	editor.call("clear_runtime_network_preview_for_authoring")
	await _wait_frames(2)
	render_snapshot = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(render_snapshot.get("editor_network_drag_preview_segment_count", 0)) == 0, "Explicit clear removes Primary3DView preview segments")
	editor.queue_free()
	await _wait_frames(2)


func _tile_at(map_data, grid_position: Vector2i):
	return map_data.call("get_tile_at_grid", grid_position) if map_data != null else null


func _tile_object_type_id(map_data, grid_position: Vector2i) -> String:
	var tile_data = _tile_at(map_data, grid_position)
	return String(tile_data.object_type_id).strip_edges().to_lower() if tile_data != null else ""


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
