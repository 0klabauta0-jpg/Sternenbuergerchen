extends SceneTree

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1200 Dynamic Overlay Stability ===")
	await _test_relevant_index_and_dirty_refresh()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_relevant_index_and_dirty_refresh() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task1200_dynamic_overlay", Vector2i(16, 16), Vector2.ZERO, 64.0, 32.0, 2)
	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	var units: Array = []
	for index in range(28):
		var fireteam_id: String = "alpha" if index < 2 else ("bravo" if index < 4 else "irrelevant_%02d" % index)
		var unit = _make_unit("task1200_unit_%02d" % index, fireteam_id, Vector2(96.0 + float(index % 7) * 56.0, 96.0 + float(index / 7) * 56.0))
		if index == 2:
			unit.set_meta("facing_angle", 0.0)
		root.add_child(unit)
		units.append(unit)
	view.call("set_unit_nodes", units)
	view.call("set_contact_entries", [{
		"fireteam_id": "alpha",
		"unit_id": "task1200_contact",
		"team_id": "team_bravo",
		"last_known_position": Vector2(640.0, 320.0),
		"detection_state": "confirmed",
	}], PackedStringArray(["alpha"]))
	view.call("set_order_visual_payload", {
		"selected_fireteam_ids": PackedStringArray(["alpha"]),
		"fireteam_anchors": [{
			"fireteam_id": "bravo",
			"position": Vector2(264.0, 96.0),
			"heading_direction": Vector2.RIGHT,
		}],
		"fire_sector_overlay_enabled": true,
		"fire_sector_visual_mode": "tile_aligned_los",
		"los_debug_overlay_enabled": true,
		"phase_index": 1,
	})
	await _wait_frames(8)

	var initial: Dictionary = _snapshot(view)
	_assert(_has_dynamic_diagnostics(initial), "Render snapshot exposes dynamic overlay diagnostics")
	_assert(initial.has("dynamic_signature_unit_scan_count") and int(initial.get("dynamic_signature_unit_scan_count", -1)) == 4, "Initial dynamic signature scans exactly four relevant units")
	_assert(initial.has("dynamic_signature_build_count") and int(initial.get("dynamic_signature_build_count", -1)) >= 1, "Initial dynamic signature is built")
	_assert(initial.has("dynamic_order_rebuild_count") and int(initial.get("dynamic_order_rebuild_count", -1)) >= 1, "Initial dynamic order visuals rebuild")
	_assert(initial.has("dynamic_relevant_unit_ids") and Array(initial.get("dynamic_relevant_unit_ids", [])).size() == 4, "Dynamic relevant index contains four units")
	_assert(initial.has("dynamic_relevant_unit_ids") and Array(initial.get("dynamic_relevant_unit_ids", [])).duplicate() == ["task1200_unit_00", "task1200_unit_01", "task1200_unit_02", "task1200_unit_03"], "Dynamic relevant IDs are sorted selected/orientation union")
	_assert(Array(initial.get("order_selected_fireteam_ids", [])).has("alpha"), "Selected fireteam ID remains a dynamic visual input")
	_assert(bool(initial.get("friendly_fire_sector_overlay_enabled", false)), "Fire-sector mode remains a dynamic signature input")
	_assert(bool(initial.get("mission_los_debug_overlay_enabled", false)), "LOS debug mode remains a dynamic visual input")
	var initial_signature: String = String(initial.get("dynamic_signature", ""))
	_assert(initial.has("dynamic_signature") and initial_signature.contains("selected:alpha"), "Dynamic signature contains selected fireteam input")
	_assert(initial.has("dynamic_signature") and initial_signature.contains("fire:true:tile_aligned_los"), "Dynamic signature contains fire-sector input")
	_assert(initial.has("dynamic_signature") and initial_signature.contains("los_debug:true:"), "Dynamic signature contains LOS/contact input")
	_assert(initial.has("dynamic_signature") and initial_signature.contains("orientation:bravo:236.0,96.0:0.0000"), "Initial live orientation signature carries bravo centroid and heading")
	_assert(bool(initial.get("read_only", false)) and not bool(initial.get("creates_command", true)) and not bool(initial.get("creates_fire_event", true)) and not bool(initial.get("creates_damage_event", true)) and not bool(initial.get("creates_movement", true)) and not bool(initial.get("sets_multiplayer_truth", true)), "Dynamic overlay remains read-only visual state")

	var stable_before: Dictionary = initial.duplicate(true)
	for _index in range(120):
		view.set("_last_dynamic_order_visual_refresh_msec", 0)
		view.call("_refresh_dynamic_order_visuals_if_needed")
	var stable: Dictionary = _snapshot(view)
	_assert(stable.has("dynamic_signature_build_count") and stable_before.has("dynamic_signature_build_count") and int(stable.get("dynamic_signature_build_count", -1)) == int(stable_before.get("dynamic_signature_build_count", -2)), "120 forced stable refreshes build no new signature")
	_assert(stable.has("dynamic_order_rebuild_count") and stable_before.has("dynamic_order_rebuild_count") and int(stable.get("dynamic_order_rebuild_count", -1)) == int(stable_before.get("dynamic_order_rebuild_count", -2)), "120 forced stable refreshes rebuild no order visuals")
	_assert(stable.has("dynamic_order_skip_count") and stable_before.has("dynamic_order_skip_count") and int(stable.get("dynamic_order_skip_count", -1)) >= int(stable_before.get("dynamic_order_skip_count", -2)) + 120, "120 stable refreshes increment dynamic skips")

	var relevant_unit: Node2D = units[2] as Node2D
	relevant_unit.global_position += Vector2(32.0, 0.0)
	await _wait_frames(3)
	view.set("_last_dynamic_order_visual_refresh_msec", 0)
	view.call("_refresh_dynamic_order_visuals_if_needed")
	var relevant_moved: Dictionary = _snapshot(view)
	_assert(relevant_moved.has("dynamic_signature_build_count") and stable.has("dynamic_signature_build_count") and int(relevant_moved.get("dynamic_signature_build_count", -1)) == int(stable.get("dynamic_signature_build_count", -2)) + 1, "Relevant movement builds exactly one new signature")
	_assert(relevant_moved.has("dynamic_signature_unit_scan_count") and stable.has("dynamic_signature_unit_scan_count") and int(relevant_moved.get("dynamic_signature_unit_scan_count", -1)) == int(stable.get("dynamic_signature_unit_scan_count", -2)) + 4, "Relevant movement scans exactly four indexed units")
	_assert(relevant_moved.has("dynamic_order_rebuild_count") and stable.has("dynamic_order_rebuild_count") and int(relevant_moved.get("dynamic_order_rebuild_count", -1)) == int(stable.get("dynamic_order_rebuild_count", -2)) + 1, "Relevant movement rebuilds exactly once")
	_assert(relevant_moved.has("dynamic_signature") and stable.has("dynamic_signature") and String(relevant_moved.get("dynamic_signature", "")) != String(stable.get("dynamic_signature", "")), "Relevant movement changes the dynamic signature")
	_assert(relevant_moved.has("dynamic_signature") and String(relevant_moved.get("dynamic_signature", "")).contains("task1200_unit_02:bravo:"), "Orientation-only movement exposes unit position in signature")
	_assert(relevant_moved.has("dynamic_signature") and String(relevant_moved.get("dynamic_signature", "")).contains("orientation:bravo"), "Orientation anchor membership remains in signature")
	_assert(relevant_moved.has("dynamic_signature") and String(relevant_moved.get("dynamic_signature", "")).contains("orientation:bravo:252.0,96.0:0.0000"), "Moved bravo unit updates the live orientation centroid")
	view.set("_last_dynamic_order_visual_refresh_msec", 0)
	view.call("_refresh_dynamic_order_visuals_if_needed")
	var relevant_settled: Dictionary = _snapshot(view)
	_assert(relevant_settled.has("dynamic_signature_build_count") and relevant_moved.has("dynamic_signature_build_count") and int(relevant_settled.get("dynamic_signature_build_count", -1)) == int(relevant_moved.get("dynamic_signature_build_count", -2)), "Relevant movement settles without a second signature build")
	_assert(relevant_settled.has("dynamic_order_rebuild_count") and relevant_moved.has("dynamic_order_rebuild_count") and int(relevant_settled.get("dynamic_order_rebuild_count", -1)) == int(relevant_moved.get("dynamic_order_rebuild_count", -2)), "Relevant movement settles without a second rebuild")

	var rotation_before: Dictionary = relevant_settled.duplicate(true)
	var orientation_unit: Node2D = units[2] as Node2D
	orientation_unit.set_meta("facing_angle", PI / 2.0)
	await _wait_frames(3)
	view.set("_last_dynamic_order_visual_refresh_msec", 0)
	view.call("_refresh_dynamic_order_visuals_if_needed")
	var rotated: Dictionary = _snapshot(view)
	_assert(rotated.has("dynamic_signature_build_count") and rotation_before.has("dynamic_signature_build_count") and int(rotated.get("dynamic_signature_build_count", -1)) == int(rotation_before.get("dynamic_signature_build_count", -2)) + 1, "Pure orientation change builds exactly one new signature")
	_assert(rotated.has("dynamic_signature_unit_scan_count") and rotation_before.has("dynamic_signature_unit_scan_count") and int(rotated.get("dynamic_signature_unit_scan_count", -1)) == int(rotation_before.get("dynamic_signature_unit_scan_count", -2)) + 4, "Pure orientation change scans exactly four indexed units")
	_assert(rotated.has("dynamic_order_rebuild_count") and rotation_before.has("dynamic_order_rebuild_count") and int(rotated.get("dynamic_order_rebuild_count", -1)) == int(rotation_before.get("dynamic_order_rebuild_count", -2)) + 1, "Pure orientation change rebuilds exactly once")
	_assert(rotated.has("dynamic_signature") and rotation_before.has("dynamic_signature") and String(rotated.get("dynamic_signature", "")) != String(rotation_before.get("dynamic_signature", "")), "Pure orientation change changes the dynamic signature")
	_assert(rotated.has("dynamic_signature") and String(rotated.get("dynamic_signature", "")).contains("orientation:bravo"), "Pure orientation change retains orientation anchor signature")
	_assert(rotated.has("dynamic_signature") and String(rotated.get("dynamic_signature", "")).contains("orientation:bravo:252.0,96.0:1.5708"), "Facing change updates the live orientation heading")
	view.set("_last_dynamic_order_visual_refresh_msec", 0)
	view.call("_refresh_dynamic_order_visuals_if_needed")
	var rotation_settled: Dictionary = _snapshot(view)
	_assert(rotation_settled.has("dynamic_signature_build_count") and rotated.has("dynamic_signature_build_count") and int(rotation_settled.get("dynamic_signature_build_count", -1)) == int(rotated.get("dynamic_signature_build_count", -2)), "Pure orientation change settles without a second signature build")
	_assert(rotation_settled.has("dynamic_order_rebuild_count") and rotated.has("dynamic_order_rebuild_count") and int(rotation_settled.get("dynamic_order_rebuild_count", -1)) == int(rotated.get("dynamic_order_rebuild_count", -2)), "Pure orientation change settles without a second rebuild")

	var contact_before: Dictionary = rotation_settled.duplicate(true)
	view.call("set_contact_entries", [{
		"fireteam_id": "alpha",
		"unit_id": "task1200_contact",
		"team_id": "team_bravo",
		"last_known_position": Vector2(640.0, 320.0),
		"detection_state": "confirmed",
	}], PackedStringArray(["alpha"]))
	view.set("_last_dynamic_order_visual_refresh_msec", 0)
	view.call("_refresh_dynamic_order_visuals_if_needed")
	var contact_applied: Dictionary = _snapshot(view)
	_assert(contact_applied.has("dynamic_signature_build_count") and contact_before.has("dynamic_signature_build_count") and int(contact_applied.get("dynamic_signature_build_count", -1)) == int(contact_before.get("dynamic_signature_build_count", -2)) + 1, "Contact apply revision builds exactly one new signature")
	_assert(contact_applied.has("dynamic_signature_unit_scan_count") and contact_before.has("dynamic_signature_unit_scan_count") and int(contact_applied.get("dynamic_signature_unit_scan_count", -1)) == int(contact_before.get("dynamic_signature_unit_scan_count", -2)) + 4, "Contact apply revision scans exactly four indexed units")
	_assert(contact_applied.has("dynamic_order_rebuild_count") and contact_before.has("dynamic_order_rebuild_count") and int(contact_applied.get("dynamic_order_rebuild_count", -1)) == int(contact_before.get("dynamic_order_rebuild_count", -2)) + 1, "Contact apply revision rebuilds exactly once")
	_assert(contact_applied.has("dynamic_signature") and contact_before.has("dynamic_signature") and String(contact_applied.get("dynamic_signature", "")) != String(contact_before.get("dynamic_signature", "")), "Contact apply revision changes the dynamic signature")
	_assert(contact_applied.has("dynamic_signature") and String(contact_applied.get("dynamic_signature", "")).contains("los_debug:true:2"), "Contact apply revision advances LOS/contact signature token")
	view.set("_last_dynamic_order_visual_refresh_msec", 0)
	view.call("_refresh_dynamic_order_visuals_if_needed")
	var contact_settled: Dictionary = _snapshot(view)
	_assert(contact_settled.has("dynamic_signature_build_count") and contact_applied.has("dynamic_signature_build_count") and int(contact_settled.get("dynamic_signature_build_count", -1)) == int(contact_applied.get("dynamic_signature_build_count", -2)), "Contact apply revision settles without a second signature build")
	_assert(contact_settled.has("dynamic_order_rebuild_count") and contact_applied.has("dynamic_order_rebuild_count") and int(contact_settled.get("dynamic_order_rebuild_count", -1)) == int(contact_applied.get("dynamic_order_rebuild_count", -2)), "Contact apply revision settles without a second rebuild")

	var irrelevant_unit: Node2D = units[27] as Node2D
	var irrelevant_before: Dictionary = contact_settled.duplicate(true)
	irrelevant_unit.global_position += Vector2(32.0, 0.0)
	await _wait_frames(3)
	view.set("_last_dynamic_order_visual_refresh_msec", 0)
	view.call("_refresh_dynamic_order_visuals_if_needed")
	var irrelevant_moved: Dictionary = _snapshot(view)
	_assert(irrelevant_moved.has("dynamic_signature_build_count") and irrelevant_before.has("dynamic_signature_build_count") and int(irrelevant_moved.get("dynamic_signature_build_count", -1)) == int(irrelevant_before.get("dynamic_signature_build_count", -2)), "Irrelevant movement builds no signature")
	_assert(irrelevant_moved.has("dynamic_order_rebuild_count") and irrelevant_before.has("dynamic_order_rebuild_count") and int(irrelevant_moved.get("dynamic_order_rebuild_count", -1)) == int(irrelevant_before.get("dynamic_order_rebuild_count", -2)), "Irrelevant movement rebuilds no order visuals")
	_assert(irrelevant_moved.has("dynamic_signature") and irrelevant_before.has("dynamic_signature") and String(irrelevant_moved.get("dynamic_signature", "")) == String(irrelevant_before.get("dynamic_signature", "")), "Irrelevant movement does not change dynamic signature")

	view.queue_free()
	for unit in units:
		if unit != null and is_instance_valid(unit):
			unit.queue_free()
	await _wait_frames(2)


func _make_unit(unit_id: String, fireteam_id: String, position_value: Vector2) -> Node2D:
	var unit: Node2D = TEST_UNIT_SCRIPT.new()
	unit.name = unit_id
	unit.set("unit_id", unit_id)
	unit.set("team_id", "team_alpha")
	unit.set("fireteam_id", fireteam_id)
	unit.set("display_name", unit_id)
	unit.set("weapon_1_id", "rifle")
	unit.global_position = position_value
	return unit


func _snapshot(view: Node) -> Dictionary:
	return Dictionary(view.call("get_render_snapshot"))


func _has_dynamic_diagnostics(snapshot: Dictionary) -> bool:
	for key in ["dynamic_signature_build_count", "dynamic_signature_unit_scan_count", "dynamic_order_rebuild_count", "dynamic_order_skip_count", "dynamic_signature", "dynamic_relevant_unit_ids"]:
		if not snapshot.has(key):
			return false
	return true


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
