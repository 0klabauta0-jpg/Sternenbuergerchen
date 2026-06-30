extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")

const TASK_DOC_PATH: String = "res://docs/tasks/TASK_671_builder_chain_auto_snapping.md"
const WORKFLOW_CONTRACT_PATH: String = "res://docs/dev/map_editor_asset_workflow_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_671 Builder Chain Auto Snapping ===")
	_test_docs()
	await _test_preview_auto_snapping()
	await _test_apply_auto_snapping()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_docs() -> void:
	_assert(FileAccess.file_exists(TASK_DOC_PATH), "TASK_671 task file exists")
	_assert(_read_text(TASK_DOC_PATH).contains("Builder Chain Auto Snapping"), "Task documents chain auto snapping")
	_assert(_read_text(WORKFLOW_CONTRACT_PATH).contains("Auto-Snapping"), "Workflow contract documents Auto-Snapping")
	_assert(_read_text(STATUS_PATH).contains("TASK_671 - Builder Chain Auto Snapping"), "Implementation status tracks TASK_671")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_671 - Builder Chain Auto Snapping"), "Roadmap lists TASK_671")
	_assert(_read_text(HANDBOOK_PATH).contains("TASK_671 - Builder Chain Auto Snapping"), "Current handbook references TASK_671")


func _test_preview_auto_snapping() -> void:
	var editor = MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(14)

	_assert(bool(editor.call("activate_runtime_builder_tool", "wall_line")), "Wall line tool activates before auto-snap preview")
	_assert(bool(editor.call("preview_runtime_network_path_for_authoring", "wall", Vector2i(1, 1), Vector2i(3, 2))), "Wall elbow preview can be built")
	await _wait_frames(2)

	var preview: Dictionary = _get_network_preview(editor)
	var auto_snapping: Dictionary = Dictionary(preview.get("auto_snapping", {}))
	var pieces: Array = Array(auto_snapping.get("path_pieces", []))
	_assert(bool(auto_snapping.get("enabled", false)), "Preview auto-snapping is enabled")
	_assert(not bool(auto_snapping.get("ui_sets_gameplay_truth", true)), "Preview auto-snapping is read-only")
	_assert(pieces.size() == int(preview.get("path_count", 0)), "Preview exposes one auto-snap piece per path tile")
	_assert(_has_piece_key(pieces, "straight"), "Preview includes a straight piece")
	_assert(_has_piece_key(pieces, "corner"), "Preview includes a corner piece")
	_assert(_has_piece_key(pieces, "end") or _has_piece_key(pieces, "straight"), "Preview includes an endpoint-compatible piece")
	var corner: Dictionary = _first_piece_key(pieces, "corner")
	_assert(not corner.is_empty() and String(corner.get("type_id", "")).contains("corner"), "Corner preview resolves a corner type")
	_assert(not corner.is_empty() and fposmod(float(corner.get("rotation_degrees", -1.0)), 90.0) <= 0.001, "Corner preview rotation snaps to 90 degree steps")

	editor.call("clear_runtime_network_preview_for_authoring")
	await _wait_frames(2)
	editor.queue_free()
	await _wait_frames(2)


func _test_apply_auto_snapping() -> void:
	var editor = MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(14)

	_assert(bool(editor.call("activate_runtime_builder_tool", "pipe_line")), "Pipe line tool activates before apply auto-snapping")
	_assert(bool(editor.call("apply_runtime_network_path_for_authoring", "pipe", Vector2i(4, 4), Vector2i(6, 4))), "First pipe stroke applies")
	_assert(bool(editor.call("apply_runtime_network_path_for_authoring", "pipe", Vector2i(5, 3), Vector2i(5, 5))), "Second pipe stroke applies across existing pipe")
	await _wait_frames(2)

	var snapshot: Dictionary = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	var builder: Dictionary = Dictionary(snapshot.get("runtime_builder_workbench", {}))
	var network: Dictionary = Dictionary(builder.get("network", {}))
	var last_apply: Dictionary = Dictionary(network.get("last_apply", {}))
	var candidate_pieces: Array = Array(last_apply.get("candidate_pieces", []))
	var changed_pieces: Array = Array(last_apply.get("changed_pieces", []))
	var auto_snapping: Dictionary = Dictionary(last_apply.get("auto_snapping", {}))
	var center_piece: Dictionary = _piece_at_grid(candidate_pieces, Vector2i(5, 4))

	_assert(bool(auto_snapping.get("enabled", false)), "Apply snapshot reports auto-snapping")
	_assert(not bool(auto_snapping.get("ui_sets_gameplay_truth", true)), "Apply auto-snapping snapshot is read-only")
	_assert(candidate_pieces.size() >= 5, "Apply snapshot exposes candidate pieces including neighbors")
	_assert(changed_pieces.size() >= 1, "Apply snapshot exposes changed pieces")
	_assert(not center_piece.is_empty(), "Apply snapshot includes the existing crossing tile")
	_assert(String(center_piece.get("piece_key", "")) == "cross", "Crossing pipe auto-snaps to cross")
	_assert(String(center_piece.get("type_id", "")) == "spacekit_pipe_cross", "Crossing pipe resolves the cross asset")
	_assert(fposmod(float(center_piece.get("rotation_degrees", -1.0)), 90.0) <= 0.001, "Apply rotation remains snapped to 90 degree steps")

	editor.queue_free()
	await _wait_frames(2)


func _get_network_preview(editor: Node) -> Dictionary:
	var snapshot: Dictionary = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	var builder: Dictionary = Dictionary(snapshot.get("runtime_builder_workbench", {}))
	return Dictionary(builder.get("network_drag_preview", {}))


func _has_piece_key(pieces: Array, piece_key: String) -> bool:
	return not _first_piece_key(pieces, piece_key).is_empty()


func _first_piece_key(pieces: Array, piece_key: String) -> Dictionary:
	for piece_variant in pieces:
		var piece: Dictionary = Dictionary(piece_variant)
		if String(piece.get("piece_key", "")) == piece_key:
			return piece
	return {}


func _piece_at_grid(pieces: Array, grid_position: Vector2i) -> Dictionary:
	for piece_variant in pieces:
		var piece: Dictionary = Dictionary(piece_variant)
		if Vector2i(piece.get("grid", Vector2i(-1, -1))) == grid_position:
			return piece
	return {}


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
