extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const CONTROLLER_SOURCE_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const SELECTED_CARD_ROW_PATH: String = "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll/FireteamCardsBody/FireteamCardsRow"
const MINI_CARD_HOST_PATH: String = "TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1044 Mission HUD Runtime Surface Guard ===")
	_test_guard_contract_is_present()
	await _test_identical_refreshes_reuse_runtime_surface_nodes()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_guard_contract_is_present() -> void:
	var source_text: String = FileAccess.get_file_as_string(CONTROLLER_SOURCE_PATH)
	_assert(source_text.contains("func get_mission_hud_runtime_surface_guard_snapshot() -> Dictionary:"), "Controller exposes a read-only mission HUD surface guard snapshot")
	_assert(source_text.contains("_build_selected_fireteam_cards_runtime_signature"), "Selected member cards use a runtime-state signature")
	_assert(source_text.contains("_build_fireteam_mini_cards_runtime_signature"), "Fireteam mini cards use a runtime-state signature")
	_assert(source_text.contains("_build_release_firefight_command_matrix_visual_signature"), "Command matrix polish uses a visual-state signature")


func _test_identical_refreshes_reuse_runtime_surface_nodes() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var controller: Node = scene.get_node_or_null("TacticalController")
	var selected_card_row: Control = scene.get_node_or_null(SELECTED_CARD_ROW_PATH) as Control
	var mini_card_host: Control = scene.get_node_or_null(MINI_CARD_HOST_PATH) as Control
	_assert(controller != null and selected_card_row != null and mini_card_host != null, "Mission fixture exposes controller and card surfaces")
	if controller == null or selected_card_row == null or mini_card_host == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	_assert(controller.has_method("get_mission_hud_runtime_surface_guard_snapshot"), "Runtime controller exposes guard diagnostics")
	if not controller.has_method("get_mission_hud_runtime_surface_guard_snapshot"):
		scene.queue_free()
		await _wait_frames(2)
		return
	controller.call("_refresh_selected_fireteam_cards")
	controller.call("_refresh_fireteam_mini_cards")
	controller.call("_apply_release_firefight_command_matrix_visual_polish")
	await _wait_frames(2)
	var selected_before: PackedInt64Array = _child_instance_ids(selected_card_row)
	var mini_before: PackedInt64Array = _child_instance_ids(mini_card_host)
	var before: Dictionary = Dictionary(controller.call("get_mission_hud_runtime_surface_guard_snapshot"))
	controller.call("_refresh_selected_fireteam_cards")
	controller.call("_refresh_fireteam_mini_cards")
	controller.call("_apply_release_firefight_command_matrix_visual_polish")
	await _wait_frames(2)
	var selected_after: PackedInt64Array = _child_instance_ids(selected_card_row)
	var mini_after: PackedInt64Array = _child_instance_ids(mini_card_host)
	var after: Dictionary = Dictionary(controller.call("get_mission_hud_runtime_surface_guard_snapshot"))
	_assert(selected_before == selected_after, "Unchanged selected member cards keep their node instances")
	_assert(mini_before == mini_after, "Unchanged fireteam mini cards keep their node instances")
	_assert(int(after.get("selected_cards_skip_count", 0)) > int(before.get("selected_cards_skip_count", 0)), "Selected member card guard records unchanged-state skip")
	_assert(int(after.get("mini_cards_skip_count", 0)) > int(before.get("mini_cards_skip_count", 0)), "Mini card guard records unchanged-state skip")
	_assert(int(after.get("command_matrix_skip_count", 0)) > int(before.get("command_matrix_skip_count", 0)), "Command matrix guard records unchanged-state skip")
	controller.set("preview_mode", not bool(controller.get("preview_mode")))
	controller.call("_apply_release_firefight_command_matrix_visual_polish")
	var changed: Dictionary = Dictionary(controller.call("get_mission_hud_runtime_surface_guard_snapshot"))
	_assert(int(changed.get("command_matrix_apply_count", 0)) > int(after.get("command_matrix_apply_count", 0)), "Changed command visual state reapplies matrix polish immediately")
	_assert(bool(changed.get("read_only", false)), "Guard diagnostics are read-only")
	_assert(not bool(changed.get("ui_sets_gameplay_truth", true)), "Guard diagnostics do not own gameplay truth")
	_assert(not bool(changed.get("creates_command", true)), "Guard diagnostics create no commands")
	scene.queue_free()
	await _wait_frames(2)


func _child_instance_ids(parent: Control) -> PackedInt64Array:
	var ids: PackedInt64Array = PackedInt64Array()
	for child in parent.get_children():
		ids.append(child.get_instance_id())
	return ids


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
