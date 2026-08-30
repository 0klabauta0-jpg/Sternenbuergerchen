extends SceneTree

const FOW_SYSTEM_SCRIPT: GDScript = preload("res://scripts/core/fog_of_war_system.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_225 Fog of War 2.5D Visual Overlay and Contacts ===")
	await _test_fow_modes_overlay_and_dynamic_filtering()
	_test_fog_of_war_system_visual_counters()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_fow_modes_overlay_and_dynamic_filtering() -> void:
	var map_data = _build_visual_fixture_map()
	var visible_world: Vector2 = map_data.call("get_tile_at_grid", Vector2i(0, 0)).world_position
	var explored_world: Vector2 = map_data.call("get_tile_at_grid", Vector2i(1, 0)).world_position
	var hidden_world: Vector2 = map_data.call("get_tile_at_grid", Vector2i(4, 4)).world_position
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	await _wait_frames(8)

	primary_view.call("set_fog_of_war_state", {"mode": "off", "team_id": "team_alpha"})
	await _wait_frames(3)
	var off_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(String(off_snapshot.get("fog_of_war_mode", "")) == "off", "FoW off mode is exposed in the 2.5D snapshot")
	_assert(int(off_snapshot.get("fow_overlay_tile_count", -1)) == 0, "FoW off mode creates no overlay")
	_assert(int(off_snapshot.get("fow_visible_tile_count", 0)) == 25, "FoW off mode treats every fixture tile as visible")

	var known_state: Dictionary = {
		"mode": "known_terrain",
		"team_id": "team_alpha",
		"terrain_knowledge": {
			"visible_tile_ids": PackedStringArray(["tile_0_0"]),
			"explored_tile_ids": PackedStringArray(["tile_0_0"]),
		},
		"current_visibility": {
			"visible_target_ids": PackedStringArray(["enemy_visible"]),
			"visible_event_ids": PackedStringArray(["fire_visible"]),
		},
		"last_known_contacts": [
			{"target_id": "enemy_hidden", "team_id": "team_bravo", "last_known_position": hidden_world, "last_seen_tick": 7},
		],
	}
	primary_view.call("set_fog_of_war_state", known_state)
	primary_view.call("set_order_visual_payload", _build_order_payload(visible_world, hidden_world))
	primary_view.call("set_contact_entries", [
		{"unit_id": "enemy_visible", "target_id": "enemy_visible", "team_id": "team_bravo", "last_known_position": visible_world, "detection_state": "confirmed"},
	])
	await _wait_frames(8)
	var known_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(String(known_snapshot.get("fog_of_war_mode", "")) == "known_terrain", "Known terrain mode reaches the 2.5D snapshot")
	_assert(int(known_snapshot.get("fow_visible_tile_count", 0)) == 1, "Known terrain tracks the current visible tile count")
	_assert(int(known_snapshot.get("fow_known_dim_tile_count", 0)) == 24, "Known terrain dims unseen known tiles instead of blacking them out")
	_assert(int(known_snapshot.get("fow_unknown_tile_count", -1)) == 0, "Known terrain mode has no unknown blackout tiles")
	_assert(int(known_snapshot.get("surface_tint_count", 0)) >= 1 and int(known_snapshot.get("height_edge_model_count", 0)) >= 1, "Known terrain keeps surface and height readability counters")
	_assert(int(known_snapshot.get("enemy_security_visual_count", 0)) == 1, "Visible enemy security sector remains rendered")
	_assert(_entry_array_has_id(Array(known_snapshot.get("enemy_security_entries", [])), "security_group_id", "visible_sec"), "Hidden enemy security sector is not exposed")
	_assert(_entry_array_has_id(Array(known_snapshot.get("weapon_fire_vfx_entries", [])), "event_id", "fire_visible"), "Visible muzzle event remains rendered")
	_assert(not _entry_array_has_id(Array(known_snapshot.get("weapon_fire_vfx_entries", [])), "event_id", "fire_hidden"), "Hidden muzzle event is filtered")
	_assert(int(known_snapshot.get("feedback_bubble_visual_count", 0)) == 1, "Visible comic bubble remains rendered")
	_assert(not _entry_array_has_id(Array(known_snapshot.get("feedback_bubble_entries", [])), "bubble_id", "bubble_hidden"), "Hidden comic bubble is filtered")
	_assert(int(known_snapshot.get("contact_count", 0)) == 2, "FoW adds a separate last-known contact marker")
	_assert(int(known_snapshot.get("fow_allowed_contact_count", 0)) == 1, "FoW counts last-known contact markers separately")
	_assert(int(known_snapshot.get("fow_dynamic_hidden_count", 0)) >= 3, "FoW counts hidden dynamic markers without exposing their current state")

	var rebuild_before_repeat: int = int(known_snapshot.get("fow_overlay_rebuild_count", 0))
	primary_view.call("set_fog_of_war_state", known_state)
	await _wait_frames(3)
	var repeat_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(repeat_snapshot.get("fow_overlay_rebuild_count", -1)) == rebuild_before_repeat, "FoW overlay does not rebuild when state is unchanged")

	var blackout_state: Dictionary = {
		"mode": "unexplored_blackout",
		"team_id": "team_alpha",
		"terrain_knowledge": {
			"visible_tile_ids": PackedStringArray(["tile_0_0"]),
			"explored_tile_ids": PackedStringArray(["tile_0_0", "tile_1_0"]),
		},
		"current_visibility": {
			"visible_target_ids": PackedStringArray(["enemy_visible"]),
			"visible_event_ids": PackedStringArray(["fire_visible"]),
		},
		"last_known_contacts": [
			{"target_id": "enemy_hidden", "team_id": "team_bravo", "last_known_position": hidden_world, "last_seen_tick": 7},
		],
	}
	primary_view.call("set_fog_of_war_state", blackout_state)
	await _wait_frames(6)
	var blackout_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var unknown_overlay := _find_scene_node(primary_view, "FoWUnknownBlackoutOverlay") as MultiMeshInstance3D
	_assert(String(blackout_snapshot.get("fog_of_war_mode", "")) == "unexplored_blackout", "Blackout mode reaches the 2.5D snapshot")
	_assert(int(blackout_snapshot.get("fow_visible_tile_count", 0)) == 1, "Blackout keeps current sight normal")
	_assert(int(blackout_snapshot.get("fow_explored_tile_count", 0)) == 1, "Blackout keeps explored memory dimmed")
	_assert(int(blackout_snapshot.get("fow_unknown_tile_count", 0)) == 23, "Blackout marks never-seen tiles unknown")
	_assert(unknown_overlay != null and unknown_overlay.multimesh != null and unknown_overlay.multimesh.instance_count == 25, "FoW overlay reserves one batched slot per fixture tile")
	_assert(_overlay_uses_instance_colors(unknown_overlay), "FoW overlay applies blackout and explored states through instance colors")
	_assert(_overlay_has_instance_color(unknown_overlay, Color(0.0, 0.0, 0.0, 1.0)), "Unknown blackout instances are really black")

	var moved_state: Dictionary = blackout_state.duplicate(true)
	moved_state["terrain_knowledge"] = {
		"visible_tile_ids": PackedStringArray(["tile_4_4"]),
		"explored_tile_ids": PackedStringArray(["tile_0_0", "tile_1_0", "tile_4_4"]),
	}
	moved_state["current_visibility"] = {
		"visible_target_ids": PackedStringArray(["enemy_hidden"]),
		"visible_event_ids": PackedStringArray(["fire_hidden"]),
	}
	moved_state["visibility_revision"] = 1
	moved_state["visibility_delta"] = {
		"visibility_revision": 1,
		"changed_tiles": [
			{"tile_id": "tile_0_0", "visible": false, "explored": true},
			{"tile_id": "tile_1_0", "visible": false, "explored": true},
			{"tile_id": "tile_4_4", "visible": true, "explored": true},
		],
	}
	primary_view.call("set_fog_of_war_state", moved_state)
	await _wait_frames(6)
	var moved_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(moved_snapshot.get("fow_overlay_full_rebuild_count", 0)) == int(blackout_snapshot.get("fow_overlay_full_rebuild_count", -1)), "FoW delta changes do not rebuild the full overlay")
	_assert(int(moved_snapshot.get("fow_overlay_delta_apply_count", 0)) == int(blackout_snapshot.get("fow_overlay_delta_apply_count", 0)) + 1, "FoW delta updates one batched overlay in place")
	_assert(int(moved_snapshot.get("fow_explored_tile_count", 0)) == 2, "Moved sight leaves previous tiles as explored memory")
	_assert(_entry_array_has_id(Array(moved_snapshot.get("enemy_security_entries", [])), "security_group_id", "hidden_sec"), "Enemy sector appears when its tile becomes visible")
	_assert(not primary_view.has_method("submit_command") and not primary_view.has_method("enqueue_effect"), "2.5D FoW view exposes no gameplay mutation API")

	primary_view.queue_free()
	await _wait_frames(2)


func _test_fog_of_war_system_visual_counters() -> void:
	var map_data = _build_visual_fixture_map()
	var fow = FOW_SYSTEM_SCRIPT.new()
	fow.call("set_mode_for_team", "team_alpha", "unexplored_blackout")
	fow.call("mark_tile_visible", "team_alpha", "tile_0_0", true)
	fow.call("mark_tile_explored", "team_alpha", "tile_1_0")
	var snapshot: Dictionary = Dictionary(fow.call("build_team_visual_state_snapshot", "team_alpha", map_data, 0))
	var counters: Dictionary = Dictionary(snapshot.get("terrain_visibility_counters", {}))
	_assert(int(counters.get("tile_count", 0)) == 25, "FoW system visual snapshot counts fixture tiles")
	_assert(int(counters.get("visible_tile_count", 0)) == 1, "FoW system visual snapshot counts visible tiles")
	_assert(int(counters.get("explored_tile_count", 0)) == 1, "FoW system visual snapshot counts explored tiles")
	_assert(int(counters.get("unknown_tile_count", 0)) == 23, "FoW system visual snapshot counts unknown tiles")


func _build_visual_fixture_map():
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_225_fow_2_5d_fixture", Vector2i(5, 5), Vector2(256.0, 128.0), 64.0, 32.0, 3)
	var sand_tile = map_data.call("get_tile_at_grid", Vector2i(1, 0))
	sand_tile.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND
	sand_tile.height_level = 1
	sand_tile.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE
	var hill_tile = map_data.call("get_tile_at_grid", Vector2i(2, 1))
	hill_tile.height_level = 2
	hill_tile.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF
	hill_tile.cover_value = 80
	var wall_tile = map_data.call("get_tile_at_grid", Vector2i(4, 4))
	wall_tile.object_type_id = "wall_straight_se"
	wall_tile.object_height = 2
	wall_tile.blocks_los = true
	wall_tile.walkable = false
	return map_data


func _build_order_payload(visible_world: Vector2, hidden_world: Vector2) -> Dictionary:
	return {
		"phase_index": 1,
		"enemy_security_dicts": [
			{
				"security_group_id": "visible_sec",
				"anchor_position": visible_world,
				"security_mode": "directional",
				"direction_angle": 0.0,
				"member_assignments": [{"unit_id": "enemy_visible", "weapon_range_world": 1800.0}],
			},
			{
				"security_group_id": "hidden_sec",
				"anchor_position": hidden_world,
				"security_mode": "directional",
				"direction_angle": 0.0,
				"member_assignments": [{"unit_id": "enemy_hidden", "weapon_range_world": 1800.0}],
			},
		],
		"fire_event_dicts": [
			{
				"event_id": "fire_visible",
				"weapon_id": "rifle",
				"attacker_unit_id": "enemy_visible",
				"target_unit_id": "friendly_a",
				"attacker_position": visible_world,
				"target_position": visible_world + Vector2(64.0, 0.0),
				"source": "task225",
			},
			{
				"event_id": "fire_hidden",
				"weapon_id": "rifle",
				"attacker_unit_id": "enemy_hidden",
				"target_unit_id": "friendly_a",
				"attacker_position": hidden_world,
				"target_position": hidden_world + Vector2(64.0, 0.0),
				"source": "task225",
			},
		],
		"feedback_bubble_dicts": [
			{
				"bubble_id": "bubble_visible",
				"display_type": "comic_bubble",
				"visual_only": true,
				"unit_id": "enemy_visible",
				"text": "CONTACT",
				"anchor_position": visible_world,
				"source": "task225",
			},
			{
				"bubble_id": "bubble_hidden",
				"display_type": "comic_bubble",
				"visual_only": true,
				"unit_id": "enemy_hidden",
				"text": "HIDDEN",
				"anchor_position": hidden_world,
				"source": "task225",
			},
		],
	}


func _entry_array_has_id(entries: Array, key: String, expected_value: String) -> bool:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		if String(Dictionary(entry_variant).get(key, "")) == expected_value:
			return true
	return false


func _overlay_uses_instance_colors(overlay: MultiMeshInstance3D) -> bool:
	if overlay == null:
		return false
	var material := overlay.material_override as StandardMaterial3D
	return material != null and material.vertex_color_use_as_albedo


func _overlay_has_instance_color(overlay: MultiMeshInstance3D, expected_color: Color) -> bool:
	if overlay == null or overlay.multimesh == null:
		return false
	for index in range(overlay.multimesh.instance_count):
		var color: Color = overlay.multimesh.get_instance_color(index)
		if is_equal_approx(color.r, expected_color.r) and is_equal_approx(color.g, expected_color.g) and is_equal_approx(color.b, expected_color.b) and is_equal_approx(color.a, expected_color.a):
			return true
	return false


func _find_scene_node(root_node: Node, node_name: String) -> Node:
	if root_node == null:
		return null
	if root_node.name == node_name:
		return root_node
	for child in root_node.get_children():
		var found := _find_scene_node(child, node_name)
		if found != null:
			return found
	return null


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
