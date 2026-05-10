extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const FIRETEAM_INFO_VBOX_PATH: String = "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamInfoScroll/FireteamInfoVBox"
const GO_BUTTON_PATH: String = "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/GoCommandMatrixButton"
const PLAN_BUTTON_PATH: String = "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/PlanCommandMatrixButton"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== Bugfix Mission Fire Sector Overlay ===")
	await _test_fire_sector_overlay_is_explicit_and_sector_based()
	await _test_direct_mode_hides_legacy_phase_controls()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_fire_sector_overlay_is_explicit_and_sector_based() -> void:
	var scene := MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var controller := scene.get_node_or_null("TacticalController")
	var primary_view := scene.get_node_or_null("Primary3DView")
	_assert(controller != null and primary_view != null, "Mission scene exposes controller and Primary3DView")
	if controller == null or primary_view == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("set_fire_sector_overlay_enabled", false)
	await _wait_frames(4)
	var disabled_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(not bool(disabled_snapshot.get("friendly_fire_sector_overlay_enabled", true)), "Friendly fire sector overlay defaults to explicit off-state")
	_assert(int(disabled_snapshot.get("friendly_aim_visual_count", -1)) == 0, "No friendly fire range visuals are drawn while the overlay is off")

	controller.call("set_fire_sector_overlay_enabled", true)
	await _wait_frames(6)
	var enabled_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var first_entry: Dictionary = _first_dictionary(Array(enabled_snapshot.get("friendly_aim_entries", [])))
	_assert(bool(enabled_snapshot.get("friendly_fire_sector_overlay_enabled", false)), "Friendly fire sector overlay can be toggled on")
	_assert(String(enabled_snapshot.get("friendly_fire_sector_visual_mode", "")) == "tile_aligned_los", "Friendly fire sectors use tile-aligned LOS visualization")
	_assert(int(enabled_snapshot.get("friendly_aim_visual_count", 0)) > 0, "Selected fireteam exposes fire sector visuals when enabled")
	_assert(int(enabled_snapshot.get("friendly_fire_sector_tile_marker_count", 0)) > 0, "Friendly fire sector marks reachable tiles instead of drawing a free overlay")
	_assert(String(enabled_snapshot.get("friendly_fire_sector_scan_mode", "")) == "range_bounded_los_cache", "Friendly fire sector scans only the weapon-radius tile window and reuses LOS blocker checks")
	_assert(int(enabled_snapshot.get("friendly_fire_sector_los_line_count", 0)) <= int(enabled_snapshot.get("friendly_fire_sector_blocker_line_limit", 99)) * maxi(int(enabled_snapshot.get("friendly_aim_visual_count", 1)), 1), "Friendly fire sector keeps LOS blocker line sampling bounded")
	_assert(String(first_entry.get("visual_shape", "")) == "tile_sector", "Friendly range readout is represented as a tile sector, not a full-screen command-like line")
	_assert(bool(first_entry.get("tile_aligned", false)), "Friendly range entry records that the visualization is snapped to tiles")
	_assert(float(first_entry.get("sector_angle_degrees", 0.0)) > 45.0 and float(first_entry.get("sector_angle_degrees", 180.0)) < 90.0, "Fire sector uses a narrow arc below ninety degrees")
	_assert(first_entry.has("facing_tip_position"), "Friendly sector entries include a short facing tip for direction readability")
	var unit_id: String = String(first_entry.get("unit_id", "")).strip_edges()
	var proxy_state_by_id: Dictionary = Dictionary(enabled_snapshot.get("unit_proxy_state_by_id", {}))
	var proxy_state: Dictionary = Dictionary(proxy_state_by_id.get(unit_id, {}))
	var origin_position: Vector2 = Vector2(first_entry.get("origin_position", Vector2.ZERO))
	var facing_tip_position: Vector2 = Vector2(first_entry.get("facing_tip_position", Vector2.ZERO))
	var facing_direction: Vector2 = (facing_tip_position - origin_position).normalized()
	var proxy_direction: Vector2 = Vector2(primary_view.call("_get_world_direction_from_proxy_yaw", origin_position, float(proxy_state.get("rotation_y_degrees", 0.0))))
	_assert(not proxy_state.is_empty() and facing_direction.dot(proxy_direction.normalized()) > 0.98, "Friendly sight sector follows the rendered NPC proxy rotation instead of drifting to the left")

	controller.call("set_fire_sector_overlay_enabled", false)
	await _wait_frames(4)
	var disabled_again_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(disabled_again_snapshot.get("friendly_aim_visual_count", -1)) == 0, "Friendly fire sector visuals clear again after toggling off")
	scene.queue_free()
	await _wait_frames(2)


func _test_direct_mode_hides_legacy_phase_controls() -> void:
	var scene := MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Mission scene exposes controller for direct-mode UI checks")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	controller.call("_set_selected_fireteams", PackedStringArray(), false)
	controller.call("_refresh_fireteam_phase_panel")
	controller.call("_refresh_fireteam_status_panel")
	controller.call("_refresh_button_state")
	var phase_panel := scene.get_node_or_null("%s/FireteamPhasePanel" % FIRETEAM_INFO_VBOX_PATH) as Control
	var return_button := scene.get_node_or_null("%s/FireteamStatusPanel/MarginContainer/HBoxContainer/ReturnToPlanButton" % FIRETEAM_INFO_VBOX_PATH) as Button
	var suppression_progress := scene.get_node_or_null("%s/FireteamStatusPanel/MarginContainer/HBoxContainer/SuppressionProgressLine" % FIRETEAM_INFO_VBOX_PATH) as Control
	var go_button := scene.get_node_or_null(GO_BUTTON_PATH) as Button
	var plan_button := scene.get_node_or_null(PLAN_BUTTON_PATH) as Button
	_assert(phase_panel != null and not phase_panel.visible, "#17 hides the parked legacy phase panel in direct order mode")
	_assert(return_button != null and not return_button.visible, "#17 hides the inert Plan return button until it can actually return to a plan")
	_assert(suppression_progress != null and suppression_progress.tooltip_text.contains("SUPP"), "Suppression readout explains the SUPP abbreviation")
	_assert(go_button != null and go_button.disabled, "GO in #16 is disabled when no selected fireteam order can execute")
	_assert(plan_button != null and plan_button.disabled, "Plan in #16 is disabled when no return-to-plan action is available")
	scene.queue_free()
	await _wait_frames(2)


func _first_dictionary(values: Array) -> Dictionary:
	for value in values:
		if typeof(value) == TYPE_DICTIONARY:
			return Dictionary(value)
	return {}


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	print("FAIL: %s" % message)
