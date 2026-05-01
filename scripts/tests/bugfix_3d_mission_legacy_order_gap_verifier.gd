extends SceneTree

const LIVE_MISSION_SCENE: PackedScene = preload("res://scenes/tests/mission_fireteam_dev_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== 3D Mission Legacy Order Gap Verifier ===")
	await _test_primary_3d_supports_old_area_order_flow()
	await _test_primary_3d_supports_old_selection_and_waypoint_hits()
	await _test_primary_3d_bridges_legacy_tactical_overlays()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_primary_3d_supports_old_area_order_flow() -> void:
	var scene := LIVE_MISSION_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var bridge = scene.get_node_or_null("Mission25DVisualBridge")
	var controller = scene.get_node_or_null("TacticalController")
	var viewport_rect: Rect2 = root.get_viewport().get_visible_rect()
	var area_rect := Rect2(viewport_rect.position + viewport_rect.size * 0.25, viewport_rect.size * 0.5)
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	var payload: Dictionary = Dictionary(bridge.call("build_area_order_payload_from_screen_rect", area_rect)) if bridge != null else {}
	var area_targets: Array = Array(controller.call("_create_area_orders_for_selected_fireteams_from_screen_rect", area_rect, "engage")) if controller != null else []
	var visualized_area_orders: Array = Array(controller.call("get_visualized_area_orders_snapshot")) if controller != null else []
	var area_order: Dictionary = Dictionary(visualized_area_orders[0]) if not visualized_area_orders.is_empty() else {}
	var snapshot: Dictionary = Dictionary(bridge.call("sync_runtime_visuals")) if bridge != null else {}
	var path_preview: Dictionary = Dictionary(snapshot.get("path_preview", {}))
	var center_screen: Dictionary = Dictionary(bridge.call("project_world_position_to_screen", Vector2(area_order.get("center_position", Vector2.ZERO)), false)) if bridge != null and typeof(area_order.get("center_position", null)) == TYPE_VECTOR2 else {}
	var area_hit: Dictionary = Dictionary(bridge.call("get_area_order_hit", Vector2(center_screen.get("screen_position", Vector2.ZERO)))) if bridge != null and bool(center_screen.get("valid", false)) else {}
	var area_visual := bridge.get_node_or_null("RuntimeVisual3D/PathPreviewVisuals3D/AreaTile_area_0_tile_0") as MeshInstance3D if bridge != null else null
	var area_anchor_line := bridge.get_node_or_null("RuntimeVisual3D/PathPreviewVisuals3D/AreaLine_area_0_anchor_line") as MeshInstance3D if bridge != null else null
	_assert(not payload.is_empty() and Array(payload.get("tile_positions", [])).size() > 0, "Primary 3D bridge can derive Area Order tiles from a screen drag")
	_assert(area_targets.size() == 1, "Tactical controller can create an Engage/Attack Area from primary 3D drag input")
	_assert(String(area_order.get("command_type", "")) == "engage", "Created 3D Area Order keeps the requested attack command type")
	_assert(int(path_preview.get("area_order_count", 0)) >= 1 and int(path_preview.get("area_tile_count", 0)) > 0, "3D bridge renders old Area Orders as visible 3D area tiles")
	_assert(area_visual != null and area_visual.visible, "Attack Area has a visible 3D tile overlay")
	_assert(area_anchor_line != null and area_anchor_line.visible, "Attack Area keeps the old fireteam-to-area route line in 3D")
	_assert(String(area_hit.get("area_order_id", "")) == String(area_order.get("area_order_id", "")), "Primary 3D hit-test can pick an existing Area Order for edit/delete")
	scene.queue_free()
	await process_frame


func _test_primary_3d_supports_old_selection_and_waypoint_hits() -> void:
	var scene := LIVE_MISSION_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var bridge = scene.get_node_or_null("Mission25DVisualBridge")
	var controller = scene.get_node_or_null("TacticalController")
	var unit := scene.get_node_or_null("UnitAlpha") as Node2D
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	var unit_screen: Dictionary = Dictionary(bridge.call("project_world_position_to_screen", unit.global_position, false)) if bridge != null and unit != null else {}
	var selected_unit = controller.call("_find_selectable_unit_at_screen_position", Vector2(unit_screen.get("screen_position", Vector2.ZERO))) if controller != null and bool(unit_screen.get("valid", false)) else null
	var lasso_rect := Rect2(Vector2(unit_screen.get("screen_position", Vector2.ZERO)) - Vector2(28.0, 28.0), Vector2(56.0, 56.0))
	controller.call("_apply_lasso_selection", lasso_rect, false)
	var selected_fireteams: PackedStringArray = PackedStringArray(controller.get("_selected_fireteam_ids"))
	var waypoint_position := unit.global_position + Vector2(128.0, 64.0)
	var waypoint_refs: Array = Array(controller.call("_create_waypoints_for_selected_fireteams", waypoint_position))
	var visualized_waypoints: Array = Array(controller.call("get_visualized_waypoints_snapshot"))
	var waypoint: Dictionary = Dictionary(visualized_waypoints[0]) if not visualized_waypoints.is_empty() else {}
	var waypoint_screen: Dictionary = Dictionary(bridge.call("project_world_position_to_screen", Vector2(waypoint.get("position", Vector2.ZERO)), false)) if bridge != null and typeof(waypoint.get("position", null)) == TYPE_VECTOR2 else {}
	var waypoint_hit: Dictionary = Dictionary(bridge.call("get_waypoint_hit", Vector2(waypoint_screen.get("screen_position", Vector2.ZERO)))) if bridge != null and bool(waypoint_screen.get("valid", false)) else {}
	var controller_waypoint_hit: Dictionary = Dictionary(controller.call("_find_waypoint_target_at_screen_position", Vector2(waypoint_screen.get("screen_position", Vector2.ZERO)))) if controller != null and bool(waypoint_screen.get("valid", false)) else {}
	if bridge != null:
		bridge.call("sync_runtime_visuals")
	var waypoint_line := bridge.get_node_or_null("RuntimeVisual3D/PathPreviewVisuals3D/PreviewLine_waypoint_line_blue_0") as MeshInstance3D if bridge != null else null
	_assert(selected_unit == unit, "Primary 3D click hit-test can select the old friendly unit anchor")
	_assert(selected_fireteams.has("blue"), "Primary 3D lasso selection maps projected units back to fireteams")
	_assert(waypoint_refs.size() >= 1, "Old waypoint creation still works before 3D hit testing")
	_assert(String(waypoint_hit.get("waypoint_id", "")) == String(waypoint.get("waypoint_id", "")), "Primary 3D bridge can pick visible waypoints")
	_assert(String(controller_waypoint_hit.get("waypoint_id", "")) == String(waypoint.get("waypoint_id", "")), "Tactical controller uses primary 3D waypoint hits before hidden 2D overlay hits")
	_assert(waypoint_line != null and waypoint_line.visible, "Primary 3D bridge keeps the old fireteam-to-waypoint route line")
	scene.queue_free()
	await process_frame


func _test_primary_3d_bridges_legacy_tactical_overlays() -> void:
	var scene := LIVE_MISSION_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var bridge = scene.get_node_or_null("Mission25DVisualBridge")
	var visualizer = scene.get_node_or_null("FireteamOrderVisualizer")
	var contact_overlay = scene.get_node_or_null("ContactMapOverlay")
	if visualizer != null:
		visualizer.call("set_selected_fireteam_ids", PackedStringArray(["blue"]))
		visualizer.call("set_ad_hoc_order_dicts", [{
			"fireteam_id": "blue",
			"anchor_position": Vector2(160.0, 160.0),
			"target_position": Vector2(260.0, 210.0),
			"label": "TARGET",
		}])
		visualizer.call("set_security_dicts", [{
			"fireteam_id": "blue",
			"is_active": true,
			"anchor_position": Vector2(180.0, 180.0),
			"overwatch_ready": true,
			"member_assignments": [{
				"center_angle": 0.0,
				"arc_width": PI * 0.5,
			}],
		}])
	if contact_overlay != null:
		contact_overlay.call("set_selected_fireteam_ids", PackedStringArray(["blue"]))
		contact_overlay.call("set_contact_entries", [{
			"fireteam_id": "blue",
			"unit_id": "enemy_contact",
			"detection_state": "suspected",
			"last_known_position": Vector2(320.0, 220.0),
			"last_updated_tick": 4,
		}])
	var snapshot: Dictionary = Dictionary(bridge.call("sync_runtime_visuals")) if bridge != null else {}
	var tactical_overlays: Dictionary = Dictionary(snapshot.get("tactical_overlays", {}))
	var ad_hoc_target := bridge.get_node_or_null("RuntimeVisual3D/TacticalOverlayVisuals3D/AdHoc_ad_hoc_0_target") as MeshInstance3D if bridge != null else null
	var security_sector := bridge.get_node_or_null("RuntimeVisual3D/TacticalOverlayVisuals3D/SecuritySector_security_0_sector_0") as MeshInstance3D if bridge != null else null
	var contact_marker := bridge.get_node_or_null("RuntimeVisual3D/TacticalOverlayVisuals3D/Contact_contact_0") as MeshInstance3D if bridge != null else null
	_assert(int(tactical_overlays.get("ad_hoc_count", 0)) == 1, "Primary 3D bridge mirrors old ad-hoc order visuals")
	_assert(int(tactical_overlays.get("security_sector_count", 0)) == 1, "Primary 3D bridge mirrors old security sector visuals")
	_assert(int(tactical_overlays.get("contact_count", 0)) == 1, "Primary 3D bridge mirrors old contact map visuals")
	_assert(ad_hoc_target != null and ad_hoc_target.visible, "Ad-hoc order target has a visible 3D marker")
	_assert(security_sector != null and security_sector.visible, "Security sector has a visible 3D overlay")
	_assert(contact_marker != null and contact_marker.visible, "Contact map entry has a visible 3D marker")
	scene.queue_free()
	await process_frame


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
