extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_372 Mission LOS Debug Overlay Toggle ===")
	await _test_primary_view_los_debug_toggle_clear_blocked_and_bounded()
	await _test_primary_view_los_debug_respects_fow_contacts()
	await _test_controller_los_debug_feedback_and_truth_boundary()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_primary_view_los_debug_toggle_clear_blocked_and_bounded() -> void:
	var fixture: Dictionary = _build_los_fixture()
	var map_data = fixture["map_data"]
	var blue_unit: Node2D = _make_unit("blue_los_debug_a", "team_alpha", "blue", Vector2(fixture["source_world"]))
	root.add_child(blue_unit)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	primary_view.call("set_unit_nodes", [blue_unit])
	primary_view.call("set_contact_entries", [
		_contact("clear_contact", "blue", Vector2(fixture["clear_world"]), "confirmed"),
		_contact("blocked_contact", "blue", Vector2(fixture["blocked_world"]), "confirmed"),
	], PackedStringArray(["blue"]))
	primary_view.call("set_order_visual_payload", _order_payload(false, 24))
	await _wait_frames(6)
	var disabled: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(not bool(disabled.get("mission_los_debug_overlay_enabled", true)), "LOS debug overlay defaults off through the order payload")
	_assert(int(disabled.get("mission_los_debug_line_count", -1)) == 0, "Disabled LOS debug overlay draws no lines")

	primary_view.call("set_order_visual_payload", _order_payload(true, 24))
	await _wait_frames(8)
	var enabled: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(bool(enabled.get("mission_los_debug_overlay_enabled", false)), "LOS debug overlay toggles on")
	_assert(int(enabled.get("mission_los_debug_line_count", 0)) == 2, "LOS debug samples the selected unit against known contacts")
	_assert(int(enabled.get("mission_los_debug_clear_line_count", 0)) == 1, "LOS debug counts a clear contact line")
	_assert(int(enabled.get("mission_los_debug_blocked_line_count", 0)) == 1, "LOS debug counts a blocked contact line")
	_assert(int(enabled.get("mission_los_debug_blocker_marker_count", 0)) >= 1, "LOS debug marks blocking tiles separately")
	_assert(_entries_have_states(Array(enabled.get("mission_los_debug_entries", [])), PackedStringArray(["clear", "blocked"])), "LOS debug entries distinguish clear and blocked lines")

	primary_view.call("set_order_visual_payload", _order_payload(true, 1))
	await _wait_frames(6)
	var bounded: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(bounded.get("mission_los_debug_line_count", 0)) == 1, "LOS debug obeys its sample limit")
	_assert(int(bounded.get("mission_los_debug_bounded_skipped_count", 0)) == 1, "LOS debug reports bounded skipped pairs")
	_assert(String(bounded.get("mission_los_debug_contact_visibility_policy", "")).contains("known_contacts"), "LOS debug documents the contact/FoW policy")
	primary_view.queue_free()
	blue_unit.queue_free()
	await _wait_frames(2)


func _test_primary_view_los_debug_respects_fow_contacts() -> void:
	var fixture: Dictionary = _build_los_fixture()
	var map_data = fixture["map_data"]
	var blue_unit: Node2D = _make_unit("blue_los_fow_a", "team_alpha", "blue", Vector2(fixture["source_world"]))
	root.add_child(blue_unit)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	primary_view.call("set_unit_nodes", [blue_unit])
	primary_view.call("set_fog_of_war_state", {
		"mode": "unexplored_blackout",
		"team_id": "team_alpha",
		"terrain_knowledge": {
			"visible_tile_ids": PackedStringArray(["tile_1_1", "tile_1_3"]),
			"explored_tile_ids": PackedStringArray(["tile_1_1", "tile_1_3", "tile_4_1"]),
		},
		"current_visibility": {
			"visible_target_ids": PackedStringArray(["clear_contact"]),
			"visible_event_ids": PackedStringArray(),
		},
	})
	primary_view.call("set_contact_entries", [
		_contact("clear_contact", "blue", Vector2(fixture["clear_world"]), "confirmed"),
		_contact("hidden_contact", "blue", Vector2(fixture["blocked_world"]), "confirmed"),
	], PackedStringArray(["blue"]))
	primary_view.call("set_order_visual_payload", _order_payload(true, 24))
	await _wait_frames(8)
	var filtered: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(filtered.get("mission_los_debug_line_count", 0)) == 1, "LOS debug does not draw hidden current contacts through FoW")
	_assert(int(filtered.get("mission_los_debug_fow_hidden_contact_count", 0)) == 1, "LOS debug counts FoW-hidden contacts without exposing them")
	_assert(not _entries_have_target(Array(filtered.get("mission_los_debug_entries", [])), "hidden_contact"), "LOS debug entries do not expose hidden contact IDs")

	primary_view.call("set_contact_entries", [
		_contact("clear_contact", "blue", Vector2(fixture["clear_world"]), "confirmed"),
		_contact("lost_contact", "blue", Vector2(fixture["blocked_world"]), "lost", true),
	], PackedStringArray(["blue"]))
	await _wait_frames(8)
	var last_known: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(last_known.get("mission_los_debug_line_count", 0)) == 2, "LOS debug may draw explicit last-known contacts")
	_assert(_entries_have_last_known(Array(last_known.get("mission_los_debug_entries", [])), "lost_contact"), "LOS debug tags last-known contact entries")
	primary_view.queue_free()
	blue_unit.queue_free()
	await _wait_frames(2)


func _test_controller_los_debug_feedback_and_truth_boundary() -> void:
	root.size = Vector2i(1920, 1080)
	var scene = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var controller: Node = scene.get_node_or_null("TacticalController")
	var primary_view: Node = scene.get_node_or_null("Primary3DView")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and primary_view != null and simulation_root != null, "Mission scene exposes controller, Primary3DView and SimulationRoot")
	if controller == null or primary_view == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	var command_count_before: int = simulation_root.command_queue.size()
	var effect_count_before: int = simulation_root.effects_queue.size()
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("set_los_debug_overlay_enabled", false)
	await _wait_frames(4)
	var disabled_feedback: Dictionary = Dictionary(controller.call("get_los_debug_overlay_snapshot"))
	var disabled_primary: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(not bool(disabled_feedback.get("enabled", true)), "Controller feedback reports LOS debug off")
	_assert(not bool(disabled_primary.get("mission_los_debug_overlay_enabled", true)), "Primary render snapshot reports LOS debug off")

	controller.call("set_los_debug_overlay_enabled", true)
	await _wait_frames(6)
	var enabled_feedback: Dictionary = Dictionary(controller.call("get_los_debug_overlay_snapshot"))
	var enabled_primary: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var feedback_primary: Dictionary = Dictionary(enabled_feedback.get("primary_3d", {}))
	_assert(bool(enabled_feedback.get("enabled", false)), "Controller feedback reports LOS debug on")
	_assert(bool(enabled_primary.get("mission_los_debug_overlay_enabled", false)), "Primary render snapshot reports LOS debug on")
	_assert(String(feedback_primary.get("contact_visibility_policy", "")).contains("known_contacts"), "Controller feedback mirrors LOS debug contact policy")
	_assert(simulation_root.command_queue.size() == command_count_before, "LOS debug toggle enqueues no SimulationRoot commands")
	_assert(simulation_root.effects_queue.size() == effect_count_before, "LOS debug toggle enqueues no SimulationRoot effects")
	scene.queue_free()
	await _wait_frames(2)


func _build_los_fixture() -> Dictionary:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_372_los_debug_fixture", Vector2i(5, 5), Vector2.ZERO, 64.0, 32.0, 3)
	var blocker_tile = map_data.call("get_tile_at_grid", Vector2i(2, 1))
	blocker_tile.blocks_los = true
	blocker_tile.object_height = 2
	blocker_tile.walkable = false
	return {
		"map_data": map_data,
		"source_world": Vector2(map_data.call("get_tile_at_grid", Vector2i(1, 1)).world_position),
		"clear_world": Vector2(map_data.call("get_tile_at_grid", Vector2i(1, 3)).world_position),
		"blocked_world": Vector2(map_data.call("get_tile_at_grid", Vector2i(4, 1)).world_position),
	}


func _order_payload(enabled: bool, sample_limit: int) -> Dictionary:
	return {
		"phase_index": 1,
		"selected_fireteam_ids": PackedStringArray(["blue"]),
		"los_debug_overlay_enabled": enabled,
		"los_debug_sample_limit": sample_limit,
	}


func _contact(target_id: String, fireteam_id: String, position: Vector2, detection_state: String, fow_last_known: bool = false) -> Dictionary:
	return {
		"unit_id": target_id,
		"target_id": target_id,
		"team_id": "team_bravo",
		"fireteam_id": fireteam_id,
		"last_known_position": position,
		"detection_state": detection_state,
		"fow_last_known": fow_last_known,
	}


func _make_unit(unit_id: String, team_id: String, fireteam_id: String, world_position: Vector2) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.display_name = unit_id
	unit.team_id = team_id
	unit.fireteam_id = fireteam_id
	unit.weapon_1_id = "rifle"
	unit.weapon_2_id = "rifle"
	unit.global_position = world_position
	unit._ready()
	return unit


func _entries_have_states(entries: Array, states: PackedStringArray) -> bool:
	for state in states:
		var found: bool = false
		for entry_variant in entries:
			if typeof(entry_variant) != TYPE_DICTIONARY:
				continue
			if String(Dictionary(entry_variant).get("line_state", "")) == String(state):
				found = true
				break
		if not found:
			return false
	return true


func _entries_have_target(entries: Array, target_id: String) -> bool:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		if String(Dictionary(entry_variant).get("target_id", "")) == target_id:
			return true
	return false


func _entries_have_last_known(entries: Array, target_id: String) -> bool:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("target_id", "")) == target_id and bool(entry.get("fow_last_known", false)):
			return true
	return false


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
