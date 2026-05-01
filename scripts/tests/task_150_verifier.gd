extends SceneTree

const LIVE_MISSION_SCENE: PackedScene = preload("res://scenes/tests/mission_fireteam_dev_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_150 Legacy 2D Mission Asset Retirement Verifier ===")
	var scene := LIVE_MISSION_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(16)
	var bridge = scene.get_node_or_null("Mission25DVisualBridge")
	bridge.call("sync_runtime_visuals")
	_test_primary_3d_retirement_state(scene, bridge)
	_test_legacy_2d_compare_fallback_restores_visuals(scene, bridge)
	_test_editor_and_ui_2d_assets_still_exist(scene)
	scene.queue_free()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_primary_3d_retirement_state(scene: Node, bridge: Node) -> void:
	var map_root := scene.get_node_or_null("MapRoot") as CanvasItem
	var target_visual := scene.get_node_or_null("TargetMarker/TargetVisual") as CanvasItem
	var unit_visual := scene.get_node_or_null("UnitAlpha/Visual") as CanvasItem
	var tactical_ui_panel := scene.get_node_or_null("TacticalUI/MissionIdentityPanel") as CanvasItem
	var audit: Dictionary = Dictionary(bridge.call("get_legacy_2d_mission_visual_audit")) if bridge != null else {}
	var runtime_snapshot: Dictionary = Dictionary(bridge.call("get_runtime_visual_snapshot")) if bridge != null else {}
	_assert(bridge != null and bool(bridge.call("is_primary_3d_view_active")), "Live mission starts in primary 3D mode")
	_assert(map_root != null and not map_root.visible, "Legacy 2D map is hidden in standard mission view")
	_assert(target_visual != null and not target_visual.visible, "Legacy 2D target marker is hidden in standard mission view")
	_assert(unit_visual != null and not unit_visual.visible, "Legacy 2D unit sprite is hidden in standard mission view")
	_assert(tactical_ui_panel != null and tactical_ui_panel.visible, "Tactical UI remains visible while legacy mission visuals are retired")
	_assert(bool(audit.get("hide_2d_mission_overlays_when_primary", false)), "Bridge audit records explicit legacy overlay retirement")
	_assert(int(audit.get("hidden_legacy_unit_visual_count", 0)) > 0, "Bridge audit sees hidden legacy unit visuals")
	_assert(int(audit.get("hidden_legacy_overlay_count", 0)) > 0, "Bridge audit sees hidden legacy mission overlays")
	_assert(bool(runtime_snapshot.get("valid", false)) and int(runtime_snapshot.get("legacy_2d_mission_overlay_hidden_count", 0)) > 0, "Runtime snapshot exposes legacy overlay retirement")


func _test_legacy_2d_compare_fallback_restores_visuals(scene: Node, bridge: Node) -> void:
	var map_root := scene.get_node_or_null("MapRoot") as CanvasItem
	var target_visual := scene.get_node_or_null("TargetMarker/TargetVisual") as CanvasItem
	var unit_visual := scene.get_node_or_null("UnitAlpha/Visual") as CanvasItem
	var lz_marker := scene.get_node_or_null("LZMarker") as CanvasItem
	var dropship_marker := scene.get_node_or_null("DropshipPlanMarker") as CanvasItem
	lz_marker.visible = true
	dropship_marker.visible = true
	bridge.call("sync_runtime_visuals")
	_assert(not lz_marker.visible and not dropship_marker.visible, "Primary 3D mode suppresses late-shown legacy LZ and dropship plan overlays")
	bridge.call("set_2d_fallback_visible", true)
	_assert(map_root != null and map_root.visible, "2D compare fallback restores the legacy map")
	_assert(target_visual != null and target_visual.visible, "2D compare fallback restores the legacy target marker")
	_assert(unit_visual != null and unit_visual.visible, "2D compare fallback restores legacy unit sprites")
	_assert(lz_marker.visible and dropship_marker.visible, "2D compare fallback restores late-shown legacy mission overlays")
	bridge.call("set_2d_fallback_visible", false)
	_assert(map_root != null and not map_root.visible and target_visual != null and not target_visual.visible, "Leaving 2D compare fallback re-hides legacy map and target marker")


func _test_editor_and_ui_2d_assets_still_exist(scene: Node) -> void:
	_assert(load("res://Assets/kenney_space-kit/Isometric/astronautA_SW.png") != null, "Retirement keeps 2D unit asset available for editor/UI/fallback")
	_assert(load("res://Assets/kenney_space-kit/Isometric/terrain_SW.png") != null, "Retirement keeps 2D terrain tile asset available for editor/UI/fallback")
	_assert(load("res://scenes/maps/iso_map_v2_layout.tscn") != null, "Retirement keeps legacy 2D map scene loadable for editor and compare fallback")
	_assert(scene.get_node_or_null("TacticalUI") != null, "Retirement does not remove mission UI CanvasLayer")


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
