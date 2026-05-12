extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")

const UI_REFRESH_SCENARIO_FLAG: int = 16

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_359 MapEditor Dirty UI Refresh Batching ===")
	await _test_selection_property_and_tool_refresh_coalescing()
	await _test_hover_refresh_and_scenario_flag_coalescing()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("TASK_359: ALL PASSED")
		quit(0)


func _test_selection_property_and_tool_refresh_coalescing() -> void:
	var editor = await _make_editor()
	if editor == null:
		return
	var base_debug: Dictionary = Dictionary(editor.call("get_editor_ui_refresh_debug_snapshot"))
	var base_flush_count: int = int(base_debug.get("flush_count", 0))
	var base_request_count: int = int(base_debug.get("request_count", 0))

	_assert(bool(editor.call("_select_grid_with_selection_tool", Vector2i(1, 1), false)), "Selection helper accepts first grid")
	_assert(bool(editor.call("_select_grid_with_selection_tool", Vector2i(2, 2), false)), "Selection helper accepts second grid")
	_assert(bool(editor.call("_select_grid_with_selection_tool", Vector2i(3, 3), false)), "Selection helper accepts third grid")

	var queued_debug: Dictionary = Dictionary(editor.call("get_editor_ui_refresh_debug_snapshot"))
	var pending_names: PackedStringArray = PackedStringArray(queued_debug.get("pending_flag_names", PackedStringArray()))
	_assert(bool(queued_debug.get("queued", false)), "Selection refresh is queued before the next frame")
	_assert(int(queued_debug.get("flush_count", -1)) == base_flush_count, "Multiple selection requests do not flush synchronously")
	_assert(int(queued_debug.get("request_count", 0)) >= base_request_count + 3, "Selection requests are counted individually")
	_assert(pending_names.has("selection"), "Queued flags include selection")
	_assert(pending_names.has("properties"), "Queued flags include properties")
	_assert(pending_names.has("tool_state"), "Queued flags include tool_state")

	await _wait_frames(1)
	var flushed_debug: Dictionary = Dictionary(editor.call("get_editor_ui_refresh_debug_snapshot"))
	var flushed_names: PackedStringArray = PackedStringArray(flushed_debug.get("last_flushed_flag_names", PackedStringArray()))
	_assert(not bool(flushed_debug.get("queued", true)), "Queued selection refresh flushes on the next frame")
	_assert(int(flushed_debug.get("flush_count", 0)) == base_flush_count + 1, "Three selection requests coalesce into one UI flush")
	_assert(flushed_names.has("selection") and flushed_names.has("properties") and flushed_names.has("tool_state"), "Selection flush keeps all required dirty flags")

	var tile_label := editor.get_node_or_null("UI/PropertyPanel/Margin/VBox/TileLabel") as Label
	var snapshot: Dictionary = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	_assert(Vector2i(snapshot.get("selected_grid", Vector2i.ZERO)) == Vector2i(3, 3), "Selection state uses the latest queued grid")
	_assert(tile_label != null and tile_label.text.contains("(3, 3)"), "Property panel flush displays the latest selected tile")

	var ui_request_count_before_3d: int = int(flushed_debug.get("request_count", 0))
	editor.call("_queue_3d_map_refresh")
	editor.call("_queue_3d_map_refresh")
	var after_3d_debug: Dictionary = Dictionary(editor.call("get_editor_ui_refresh_debug_snapshot"))
	_assert(int(after_3d_debug.get("request_count", -1)) == ui_request_count_before_3d, "3D refresh queue remains separate from UI dirty batching")
	_assert(bool(editor.get("_3d_refresh_queued")), "3D refresh still coalesces through its existing queue")

	editor.queue_free()
	await _wait_frames(2)


func _test_hover_refresh_and_scenario_flag_coalescing() -> void:
	var editor = await _make_editor()
	if editor == null:
		return
	var primary_view: Node = editor.get_node_or_null("Primary3DView")
	if primary_view != null:
		primary_view.queue_free()
		await _wait_frames(2)

	var map_data = editor.get("_terrain_map_data")
	var hover_tile = map_data.call("get_tile_at_grid", Vector2i(1, 1)) if map_data != null else null
	_assert(hover_tile != null, "Hover fixture tile exists")
	if hover_tile == null:
		editor.queue_free()
		await _wait_frames(2)
		return

	var hover_base_debug: Dictionary = Dictionary(editor.call("get_editor_ui_refresh_debug_snapshot"))
	var hover_base_flush_count: int = int(hover_base_debug.get("flush_count", 0))
	editor.call("_queue_hover_preview_update", Vector2(hover_tile.world_position))
	editor.call("_queue_hover_preview_update", Vector2(hover_tile.world_position))
	var hover_queued_debug: Dictionary = Dictionary(editor.call("get_editor_ui_refresh_debug_snapshot"))
	_assert(PackedStringArray(hover_queued_debug.get("pending_flag_names", PackedStringArray())).has("hover"), "Hover refresh is queued as its own dirty flag")
	await _wait_frames(1)
	var hover_snapshot: Dictionary = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	var hover_flushed_debug: Dictionary = Dictionary(editor.call("get_editor_ui_refresh_debug_snapshot"))
	_assert(int(hover_flushed_debug.get("flush_count", 0)) == hover_base_flush_count + 1, "Two hover updates coalesce into one UI flush")
	_assert(Vector2i(hover_snapshot.get("hover_grid", Vector2i.ZERO)) == Vector2i(1, 1), "Hover preview uses the latest queued hover tile")

	editor.call("_queue_hover_preview_hide")
	await _wait_frames(1)
	var hidden_snapshot: Dictionary = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	_assert(Vector2i(hidden_snapshot.get("hover_grid", Vector2i.ZERO)) == Vector2i(-1, -1), "Queued hover hide clears stale hover state")

	var scenario_base_debug: Dictionary = Dictionary(editor.call("get_editor_ui_refresh_debug_snapshot"))
	var scenario_base_flush_count: int = int(scenario_base_debug.get("flush_count", 0))
	editor.call("_queue_editor_ui_refresh", UI_REFRESH_SCENARIO_FLAG)
	var scenario_queued_debug: Dictionary = Dictionary(editor.call("get_editor_ui_refresh_debug_snapshot"))
	_assert(PackedStringArray(scenario_queued_debug.get("pending_flag_names", PackedStringArray())).has("scenario"), "Scenario panel has a distinct dirty flag")
	await _wait_frames(1)
	var scenario_flushed_debug: Dictionary = Dictionary(editor.call("get_editor_ui_refresh_debug_snapshot"))
	_assert(int(scenario_flushed_debug.get("flush_count", 0)) == scenario_base_flush_count + 1, "Scenario dirty flag flushes through the shared UI queue")
	_assert(PackedStringArray(scenario_flushed_debug.get("last_flushed_flag_names", PackedStringArray())).has("scenario"), "Scenario flush reports the scenario flag")

	var action_contract: Dictionary = Dictionary(editor.call("get_authoring_action_contract_snapshot"))
	var contract_flags: PackedStringArray = PackedStringArray(action_contract.get("editor_ui_refresh_flags", PackedStringArray()))
	_assert(bool(action_contract.get("editor_ui_refresh_batched", false)), "Action contract documents batched editor UI refreshes")
	_assert(contract_flags.has("selection") and contract_flags.has("properties") and contract_flags.has("tool_state") and contract_flags.has("hover") and contract_flags.has("scenario"), "Action contract documents all editor UI dirty flags")

	editor.queue_free()
	await _wait_frames(2)


func _make_editor():
	var editor = MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(14)
	return editor


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
