extends SceneTree

const FOW_SYSTEM_SCRIPT: GDScript = preload("res://scripts/core/fog_of_war_system.gd")
const LOS_SYSTEM_SCRIPT: GDScript = preload("res://scripts/core/los_system.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

const BROAD_FOW_UPDATE_BUDGET_USEC: float = 2000000.0

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_224 Fog of War Tile Visibility Height Cover Runtime ===")
	_test_known_terrain_keeps_terrain_readable_without_dynamic_visibility()
	_test_unexplored_blackout_visible_explored_unknown()
	_test_walls_hills_cliffs_and_height_los()
	_test_64x64_visibility_budget()
	_test_fow_safe_dynamic_snapshot_filter()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_known_terrain_keeps_terrain_readable_without_dynamic_visibility() -> void:
	var registry: Node = _make_registry(Vector2i(32, 32), {
		Vector2i(12, 12): {"cover_value": 80, "height_level": 1, "surface_type": "sand"},
	})
	var fow = FOW_SYSTEM_SCRIPT.new()
	var los = LOS_SYSTEM_SCRIPT.new()
	var observer := _make_observer(registry, Vector2i(0, 0))
	fow.call("set_mode_for_team", "team_alpha", "known_terrain")
	var update: Dictionary = Dictionary(fow.call("update_tile_visibility_for_team", "team_alpha", [observer], registry, los, 96.0))
	_assert(int(update.get("tile_count", 0)) == 1024, "Known-terrain update scans 32x32 tiles")
	_assert(int(update.get("visible_tile_count", 0)) > 0, "Known-terrain update marks current visible tiles")
	_assert(String(fow.call("get_terrain_visibility_state", "team_alpha", "tile_31_31")) == "known", "Known-terrain mode keeps far unseen terrain readable")
	var cover_info: Dictionary = Dictionary(fow.call("get_known_tile_info", "team_alpha", "tile_12_12", registry))
	_assert(bool(cover_info.get("known", false)), "Known-terrain exposes terrain info for unseen known tile")
	_assert(int(cover_info.get("cover_value", 0)) == 80, "Known-terrain keeps cover value readable")
	_assert(int(cover_info.get("height_level", 0)) == 1, "Known-terrain keeps height readable")
	_assert(not bool(fow.call("should_show_dynamic_target", "team_alpha", "enemy_hidden")), "Known-terrain does not reveal hidden dynamic targets")
	observer.free()
	registry.free()


func _test_unexplored_blackout_visible_explored_unknown() -> void:
	var registry: Node = _make_registry(Vector2i(32, 32), {})
	var fow = FOW_SYSTEM_SCRIPT.new()
	var los = LOS_SYSTEM_SCRIPT.new()
	var observer := _make_observer(registry, Vector2i(0, 0))
	fow.call("set_mode_for_team", "team_alpha", "unexplored_blackout")
	_assert(String(fow.call("get_terrain_visibility_state", "team_alpha", "tile_20_20")) == "unknown", "Blackout starts never-seen tiles as unknown")
	fow.call("update_tile_visibility_for_team", "team_alpha", [observer], registry, los, 96.0)
	_assert(String(fow.call("get_terrain_visibility_state", "team_alpha", "tile_0_0")) == "visible", "Blackout marks observer tile visible")
	fow.call("mark_tile_visible", "team_alpha", "tile_0_0", false)
	_assert(String(fow.call("get_terrain_visibility_state", "team_alpha", "tile_0_0")) == "explored", "Blackout keeps previously visible tile explored")
	var unknown_info: Dictionary = Dictionary(fow.call("get_known_tile_info", "team_alpha", "tile_20_20", registry))
	_assert(not bool(unknown_info.get("known", true)), "Blackout hides unknown tile cover/height info")
	observer.free()
	registry.free()


func _test_walls_hills_cliffs_and_height_los() -> void:
	var blocking_registry: Node = _make_registry(Vector2i(8, 4), {
		Vector2i(2, 0): {"blocks_los": true, "object_height": 1, "cover_value": 100, "edge_type": "none"},
		Vector2i(3, 1): {"blocks_los": true, "height_level": 2, "object_height": 1, "edge_type": "cliff"},
	})
	var fow = FOW_SYSTEM_SCRIPT.new()
	var los = LOS_SYSTEM_SCRIPT.new()
	var observer := _make_observer(blocking_registry, Vector2i(0, 0))
	fow.call("set_mode_for_team", "team_alpha", "unexplored_blackout")
	fow.call("update_tile_visibility_for_team", "team_alpha", [observer], blocking_registry, los, 512.0)
	_assert(String(fow.call("get_terrain_visibility_state", "team_alpha", "tile_1_0")) == "visible", "FoW sees tile before wall blocker")
	_assert(String(fow.call("get_terrain_visibility_state", "team_alpha", "tile_4_0")) != "visible", "Wall/object blocker prevents FoW visibility behind it")
	var cliff_info: Dictionary = Dictionary(fow.call("get_known_tile_info", "team_alpha", "tile_3_1", blocking_registry))
	fow.call("mark_tile_explored", "team_alpha", "tile_3_1")
	cliff_info = Dictionary(fow.call("get_known_tile_info", "team_alpha", "tile_3_1", blocking_registry))
	_assert(String(cliff_info.get("edge_type", "")) == "cliff", "FoW known tile info preserves cliff edge type")
	_assert(bool(cliff_info.get("blocks_los", false)), "FoW known tile info preserves LOS blocker flag")
	observer.free()
	blocking_registry.free()

	var overlook_registry: Node = _make_registry(Vector2i(5, 1), {
		Vector2i(0, 0): {"height_level": 2},
		Vector2i(1, 0): {"blocks_los": true, "height_level": 0, "object_height": 1},
		Vector2i(2, 0): {"height_level": 2},
	})
	var high_observer := _make_observer(overlook_registry, Vector2i(0, 0))
	var high_fow = FOW_SYSTEM_SCRIPT.new()
	high_fow.call("set_mode_for_team", "team_alpha", "unexplored_blackout")
	high_fow.call("update_tile_visibility_for_team", "team_alpha", [high_observer], overlook_registry, los, 512.0)
	_assert(String(high_fow.call("get_terrain_visibility_state", "team_alpha", "tile_2_0")) == "visible", "Higher observer sees over lower object blocker")
	high_observer.free()
	overlook_registry.free()


func _test_64x64_visibility_budget() -> void:
	var registry: Node = _make_registry(Vector2i(64, 64), {
		Vector2i(8, 8): {"cover_value": 60},
		Vector2i(16, 16): {"height_level": 1, "surface_type": "sand"},
	})
	var fow = FOW_SYSTEM_SCRIPT.new()
	var los = LOS_SYSTEM_SCRIPT.new()
	var observer := _make_observer(registry, Vector2i(8, 8))
	fow.call("set_mode_for_team", "team_alpha", "unexplored_blackout")
	var update: Dictionary = Dictionary(fow.call("update_tile_visibility_for_team", "team_alpha", [observer], registry, los, 192.0))
	_assert(int(update.get("tile_count", 0)) == 4096, "FoW update supports 64x64 tile maps")
	_assert(int(update.get("visible_tile_count", 0)) > 0, "FoW 64x64 update marks visible tiles")
	_assert(float(update.get("duration_usec", BROAD_FOW_UPDATE_BUDGET_USEC + 1.0)) < BROAD_FOW_UPDATE_BUDGET_USEC, "FoW 64x64 update stays under broad local budget")
	_assert(String(update.get("update_policy", "")).contains("tick_budget"), "FoW update documents movement/tick-budget policy")
	observer.free()
	registry.free()


func _test_fow_safe_dynamic_snapshot_filter() -> void:
	var fow = FOW_SYSTEM_SCRIPT.new()
	fow.call("set_mode_for_team", "team_alpha", "known_terrain")
	fow.call("set_visible", "team_alpha", "enemy_visible", true)
	fow.call("record_last_known_contact", "team_alpha", {"target_id": "enemy_hidden", "last_known_position": Vector2(32.0, 32.0), "last_seen_tick": 5})
	var filtered: Dictionary = Dictionary(fow.call(
		"filter_dynamic_entries_for_team",
		"team_alpha",
		[
			{"unit_id": "enemy_visible", "position": Vector2(12.0, 12.0), "team_id": "team_bravo"},
			{"unit_id": "enemy_hidden", "position": Vector2(64.0, 64.0), "team_id": "team_bravo"},
		]
	))
	_assert(int(filtered.get("visible_count", 0)) == 1, "FoW-safe filter keeps only currently visible enemy entries")
	_assert(int(filtered.get("hidden_count", 0)) == 1, "FoW-safe filter counts hidden entries without exposing them")
	_assert(not bool(filtered.get("hidden_ids_included", true)), "FoW-safe filter does not include hidden enemy IDs as current entries")
	_assert(Array(filtered.get("last_known_contacts", [])).size() >= 1, "FoW-safe filter can include separate last known contacts")
	fow.call("set_peer_team", 3, "team_alpha")
	var peer_snapshot: Dictionary = Dictionary(fow.call("build_peer_state_snapshot", 3))
	_assert(String(peer_snapshot.get("team_id", "")) == "team_alpha" and int(peer_snapshot.get("peer_id", 0)) == 3, "FoW-safe multiplayer snapshot remains peer/team scoped")


func _make_registry(size: Vector2i, overrides: Dictionary) -> Node:
	var registry: Node = TERRAIN_REGISTRY_SCRIPT.new()
	registry.call("configure_iso_grid", Vector2.ZERO, 16.0, 8.0)
	for x in range(size.x):
		for y in range(size.y):
			var grid := Vector2i(x, y)
			var override: Dictionary = Dictionary(overrides.get(grid, {}))
			registry.call("register_tile", TERRAIN_TILE_DATA_SCRIPT.call("from_dict", {
				"tile_id": "tile_%d_%d" % [x, y],
				"type_id": "ground_flat",
				"grid_position": grid,
				"world_position": registry.call("grid_to_world", grid),
				"walkable": bool(override.get("walkable", true)),
				"blocks_los": bool(override.get("blocks_los", false)),
				"cover_value": int(override.get("cover_value", 0)),
				"height_level": int(override.get("height_level", 0)),
				"object_height": int(override.get("object_height", 0)),
				"surface_type": String(override.get("surface_type", "ground")),
				"edge_type": String(override.get("edge_type", "none")),
			}))
	return registry


func _make_observer(registry: Node, grid_position: Vector2i) -> Node2D:
	var observer := Node2D.new()
	observer.global_position = registry.call("grid_to_world", grid_position)
	return observer


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
