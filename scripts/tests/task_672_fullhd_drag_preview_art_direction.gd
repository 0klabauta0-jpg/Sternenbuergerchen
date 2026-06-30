extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")

const TASK_DOC_PATH: String = "res://docs/tasks/TASK_672_fullhd_drag_preview_art_direction.md"
const WORKFLOW_CONTRACT_PATH: String = "res://docs/dev/map_editor_asset_workflow_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_672 FullHD Drag Preview Art Direction ===")
	_test_docs()
	await _test_fullhd_drag_preview_labels()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_docs() -> void:
	_assert(FileAccess.file_exists(TASK_DOC_PATH), "TASK_672 task file exists")
	_assert(_read_text(TASK_DOC_PATH).contains("FullHD Drag Preview Art Direction"), "Task documents FullHD drag preview art direction")
	_assert(_read_text(WORKFLOW_CONTRACT_PATH).contains("FullHD-Art-Direction"), "Workflow contract documents FullHD drag preview art direction")
	_assert(_read_text(STATUS_PATH).contains("TASK_672 - FullHD Drag Preview Art Direction"), "Implementation status tracks TASK_672")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_672 - FullHD Drag Preview Art Direction"), "Roadmap lists TASK_672")
	_assert(_read_text(HANDBOOK_PATH).contains("TASK_672 - FullHD Drag Preview Art Direction"), "Current handbook references TASK_672")


func _test_fullhd_drag_preview_labels() -> void:
	var editor = MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(14)
	var primary_view := editor.get_node_or_null("Primary3DView")
	_assert(primary_view != null, "Editor has a primary 3D view for FullHD preview labels")
	if primary_view == null:
		editor.queue_free()
		await _wait_frames(2)
		return

	_assert(bool(editor.call("activate_runtime_builder_tool", "pipe_line")), "Pipe line tool activates before FullHD preview")
	_assert(bool(editor.call("preview_runtime_network_path_for_authoring", "pipe", Vector2i(1, 1), Vector2i(3, 2))), "Pipe elbow preview can be built")
	await _wait_frames(2)

	var render_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(bool(render_snapshot.get("editor_network_drag_preview_active", false)), "Render snapshot marks drag preview active")
	_assert(int(render_snapshot.get("editor_network_drag_preview_handle_label_count", 0)) == 4, "Render snapshot counts one handle label per path tile")
	_assert(int(render_snapshot.get("editor_network_drag_preview_segment_label_count", 0)) == 3, "Render snapshot keeps segment label count")
	_assert(int(render_snapshot.get("editor_network_drag_preview_piece_label_count", 0)) == 4, "Render snapshot counts one piece label per path tile")
	_assert(bool(render_snapshot.get("editor_network_drag_preview_art_direction_ready", false)), "Render snapshot marks art direction ready")
	_assert(_has_label(primary_view, "NetworkDragHandleLabel_start_1_1", "S"), "Start handle label is rendered")
	_assert(_has_label(primary_view, "NetworkDragHandleLabel_target_3_2", "T"), "Target handle label is rendered")
	_assert(_has_label(primary_view, "NetworkDragSegmentLabel_0", "01"), "First segment label is rendered")
	_assert(_has_label_text_prefix(primary_view, "NetworkDragPieceLabel_3_1", "COR"), "Corner piece label is rendered")

	editor.call("clear_runtime_network_preview_for_authoring")
	await _wait_frames(2)
	render_snapshot = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(render_snapshot.get("editor_network_drag_preview_handle_label_count", 0)) == 0, "Clear removes handle labels")
	_assert(int(render_snapshot.get("editor_network_drag_preview_piece_label_count", 0)) == 0, "Clear removes piece labels")
	_assert(not bool(render_snapshot.get("editor_network_drag_preview_art_direction_ready", true)), "Clear resets art direction ready")

	editor.queue_free()
	await _wait_frames(2)


func _has_label(root_node: Node, node_name: String, expected_text: String) -> bool:
	var label := root_node.find_child(node_name, true, false) as Label3D
	return label != null and label.text == expected_text


func _has_label_text_prefix(root_node: Node, node_name: String, expected_prefix: String) -> bool:
	var label := root_node.find_child(node_name, true, false) as Label3D
	return label != null and label.text.begins_with(expected_prefix)


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
