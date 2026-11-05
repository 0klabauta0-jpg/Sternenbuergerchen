extends SceneTree

const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const FOG_OF_WAR_MODE_CONTRACT_SCRIPT: GDScript = preload("res://scripts/core/fog_of_war_mode_contract.gd")

const CONTRACT_DOC_PATH: String = "res://docs/dev/flight_altitude_layer_contract.md"
const HEIGHT_STEP: float = 0.25

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	if DisplayServer.get_name() != "headless":
		root.mode = Window.MODE_FULLSCREEN
		root.content_scale_size = DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_230 Flight Altitude Layer and Air Visibility Audit ===")
	_test_contract_doc_exists()
	await _test_dropship_air_layer_above_hill_terrain()
	await _test_fow_hides_air_surface_markers_without_hiding_friendly_air()
	await _test_aircraft_visibility_changes_without_flight_payload_refresh()
	await _test_mixed_drop_tree_visibility_and_cargo_labels()
	await _test_surface_marker_modes_are_read_only()
	_test_multiplayer_snapshot_carries_read_only_air_layer()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_contract_doc_exists() -> void:
	_assert(FileAccess.file_exists(CONTRACT_DOC_PATH), "Flight altitude layer contract doc exists")
	var text: String = _read_text_file(CONTRACT_DOC_PATH)
	for required_text in ["mission_air", "height_level", "FoW", "Multiplayer", "Editor"]:
		_assert(text.contains(required_text), "Contract doc covers %s" % required_text)


func _test_dropship_air_layer_above_hill_terrain() -> void:
	var map_data = _build_air_fixture_map()
	var hill_world: Vector2 = map_data.call("get_tile_at_grid", Vector2i(1, 1)).world_position
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	primary_view.call(
		"set_mission_drop_visual_state",
		{
			"dropship_visible": true,
			"dropship_position": hill_world,
			"dropship_target_position": hill_world + Vector2(64.0, 32.0),
			"has_lz_position": true,
			"lz_position": hill_world,
			"team_id": "team_alpha",
			"flight_altitude_clearance": 1.36,
		}
	)
	await _wait_frames(8)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(bool(snapshot.get("dropship_model_visible", false)) or bool(snapshot.get("dropship_texture_visible", false)), "Dropship visual is visible on hill fixture")
	_assert(String(snapshot.get("flight_altitude_layer", "")) == "mission_air", "Dropship uses explicit mission_air layer")
	_assert(bool(snapshot.get("dropship_above_terrain", false)), "Dropship is above terrain surface")
	_assert(float(snapshot.get("dropship_surface_y", 0.0)) >= _top_y(2), "Dropship surface reference follows hill height")
	_assert(float(snapshot.get("dropship_air_y", 0.0)) > float(snapshot.get("dropship_surface_y", 0.0)), "Dropship air Y is above surface Y")
	_assert(float(snapshot.get("dropship_air_clearance", 0.0)) >= 0.72, "Dropship keeps minimum air clearance")
	_assert(int(snapshot.get("lz_tile_marker_count", 0)) == 1, "Visible LZ still renders as terrain marker")
	primary_view.queue_free()
	await _wait_frames(2)


func _test_fow_hides_air_surface_markers_without_hiding_friendly_air() -> void:
	var map_data = _build_air_fixture_map()
	var hidden_world: Vector2 = map_data.call("get_tile_at_grid", Vector2i(3, 3)).world_position
	var visible_world: Vector2 = map_data.call("get_tile_at_grid", Vector2i(0, 0)).world_position
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	primary_view.call(
		"set_fog_of_war_state",
		{
			"mode": FOG_OF_WAR_MODE_CONTRACT_SCRIPT.get("MODE_UNEXPLORED_BLACKOUT"),
			"team_id": "team_alpha",
			"terrain_knowledge": {
				"visible_tile_ids": PackedStringArray(["tile_0_0"]),
				"explored_tile_ids": PackedStringArray(["tile_0_0"]),
			},
			"current_visibility": {
				"visible_target_ids": PackedStringArray(),
				"visible_event_ids": PackedStringArray(),
			},
		}
	)
	primary_view.call(
		"set_mission_drop_visual_state",
		{
			"dropship_visible": true,
			"dropship_position": hidden_world,
			"has_lz_position": true,
			"lz_position": hidden_world,
			"team_id": "team_alpha",
		}
	)
	primary_view.call(
		"set_contact_entries",
		[
			{
				"target_id": "enemy_air_contact",
				"unit_id": "enemy_air_contact",
				"team_id": "team_bravo",
				"detection_state": "air_contact",
				"last_known_position": hidden_world,
			}
		]
	)
	await _wait_frames(8)
	var hidden_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(bool(hidden_snapshot.get("dropship_model_visible", false)) or bool(hidden_snapshot.get("dropship_texture_visible", false)), "Friendly dropship remains visible under FoW")
	_assert(int(hidden_snapshot.get("lz_tile_marker_count", 0)) == 0, "Hidden LZ marker does not reveal unknown terrain")
	_assert(int(hidden_snapshot.get("air_unknown_terrain_reveal_block_count", 0)) >= 1, "Air layer records blocked unknown-terrain reveal")
	_assert(int(hidden_snapshot.get("fow_hidden_contact_count", 0)) == 1, "Enemy air/contact visual is hidden by FoW")

	primary_view.call(
		"set_fog_of_war_state",
		{
			"mode": FOG_OF_WAR_MODE_CONTRACT_SCRIPT.get("MODE_UNEXPLORED_BLACKOUT"),
			"team_id": "team_alpha",
			"terrain_knowledge": {
				"visible_tile_ids": PackedStringArray(["tile_0_0", "tile_3_3"]),
				"explored_tile_ids": PackedStringArray(["tile_0_0", "tile_3_3"]),
			},
			"current_visibility": {
				"visible_target_ids": PackedStringArray(["enemy_air_contact"]),
				"visible_event_ids": PackedStringArray(),
			},
		}
	)
	await _wait_frames(4)
	var visible_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(visible_snapshot.get("lz_tile_marker_count", 0)) == 1, "Visible LZ marker returns when its tile is FoW-visible")
	_assert(int(visible_snapshot.get("contact_count", 0)) == 1, "Enemy air/contact visual appears when FoW contact rule allows it")
	var contact_entries: Array = Array(visible_snapshot.get("contact_entries", []))
	var visible_contact: Dictionary = Dictionary(contact_entries[0]) if not contact_entries.is_empty() else {}
	_assert(Vector2(visible_contact.get("last_known_position", visible_world)) == hidden_world, "Visible contact keeps authored position")
	var visible_fog: Dictionary = Dictionary(primary_view.get("_fog_of_war_state")).duplicate(true)
	var unrelated_fog: Dictionary = visible_fog.duplicate(true)
	unrelated_fog["terrain_knowledge"]["visible_tile_ids"] = PackedStringArray(["tile_0_0", "tile_3_3", "tile_2_3"])
	unrelated_fog["terrain_knowledge"]["explored_tile_ids"] = PackedStringArray(["tile_0_0", "tile_3_3", "tile_2_3"])
	var drop_children_before: Array = _drop_child_instance_ids(primary_view)
	var drop_skips_before: int = int(visible_snapshot.get("fow_drop_rebuild_skip_count", 0))
	primary_view.call("set_fog_of_war_state", unrelated_fog)
	await _wait_frames(4)
	var unrelated_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(_drop_child_instance_ids(primary_view) == drop_children_before, "Unrelated tile visibility preserves actual drop nodes without a rebuild")
	_assert(int(unrelated_snapshot.get("fow_drop_rebuild_skip_count", 0)) == drop_skips_before + 1, "Unrelated tile visibility retains the bounded drop-rebuild skip")
	var lost_fog: Dictionary = visible_fog.duplicate(true)
	lost_fog["terrain_knowledge"]["visible_tile_ids"] = PackedStringArray(["tile_0_0"])
	primary_view.call("set_fog_of_war_state", lost_fog)
	await _wait_frames(4)
	var lost_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(lost_snapshot.get("lz_tile_marker_count", -1)) == 0, "Losing current tile visibility removes the previously constructed LZ despite explored memory")
	_assert(bool(lost_snapshot.get("dropship_model_visible", false)) or bool(lost_snapshot.get("dropship_texture_visible", false)), "Tile visibility loss preserves the independent friendly aircraft")
	primary_view.call("set_fog_of_war_state", visible_fog)
	await _wait_frames(4)
	_assert(int(Dictionary(primary_view.call("get_render_snapshot")).get("lz_tile_marker_count", 0)) == 1, "A pure FoW visibility regain reconstructs the LZ without resending flight state")
	primary_view.queue_free()
	await _wait_frames(2)


func _test_aircraft_visibility_changes_without_flight_payload_refresh() -> void:
	var map_data = _build_air_fixture_map()
	var hidden_world: Vector2 = map_data.call("get_tile_at_grid", Vector2i(3, 3)).world_position
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	var fog_state: Dictionary = {
		"mode": "unexplored_blackout",
		"team_id": "team_alpha",
		"terrain_knowledge": {"visible_tile_ids": PackedStringArray(["tile_0_0"]), "explored_tile_ids": PackedStringArray(["tile_0_0", "tile_3_3"])},
	}
	primary_view.call("set_fog_of_war_state", fog_state)
	primary_view.call("set_mission_drop_visual_state", {
		"team_id": "team_alpha",
		"dropship_visuals": [{
			"craft_id": "task230_own_body",
			"team_id": "team_alpha",
			"dropship_visible": true,
			"dropship_position": hidden_world,
			"show_lz_marker": false,
			"show_approach_vector": false,
		}, {
			"craft_id": "task230_foreign_body",
			"team_id": "team_bravo",
			"dropship_visible": true,
			"dropship_position": hidden_world,
			"show_lz_marker": false,
			"show_approach_vector": false,
		}],
	})
	await _wait_frames(4)
	_assert(int(Dictionary(primary_view.call("get_render_snapshot")).get("air_visual_count", 0)) == 1, "Blackout admits the own aircraft body while filtering the foreign aircraft at the same hidden position")
	fog_state["terrain_knowledge"]["visible_tile_ids"] = PackedStringArray(["tile_0_0", "tile_3_3"])
	primary_view.call("set_fog_of_war_state", fog_state)
	await _wait_frames(4)
	_assert(int(Dictionary(primary_view.call("get_render_snapshot")).get("air_visual_count", 0)) == 2, "A pure FoW gain creates the newly visible foreign aircraft body")
	fog_state["terrain_knowledge"]["visible_tile_ids"] = PackedStringArray(["tile_0_0"])
	primary_view.call("set_fog_of_war_state", fog_state)
	await _wait_frames(4)
	_assert(int(Dictionary(primary_view.call("get_render_snapshot")).get("air_visual_count", 0)) == 1, "A pure FoW loss removes the foreign aircraft while preserving the own aircraft")
	primary_view.queue_free()
	await _wait_frames(2)


func _test_mixed_drop_tree_visibility_and_cargo_labels() -> void:
	var map_data = _build_air_fixture_map()
	var hidden_world: Vector2 = map_data.call("get_tile_at_grid", Vector2i(3, 3)).world_position
	var visible_world: Vector2 = map_data.call("get_tile_at_grid", Vector2i(0, 0)).world_position
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	var fog_state: Dictionary = {
		"mode": "known_terrain",
		"team_id": "team_alpha",
		"terrain_knowledge": {"visible_tile_ids": PackedStringArray(["tile_0_0"]), "explored_tile_ids": PackedStringArray(["tile_0_0"])},
	}
	var payload: Dictionary = {
		"team_id": "team_alpha",
		"dropship_visuals": [{
			"craft_id": "task230_tree_own",
			"team_id": "team_alpha",
			"dropship_visible": true,
			"dropship_position": hidden_world,
			"has_lz_position": true,
			"lz_position": hidden_world,
			"show_approach_vector": false,
		}, {
			"craft_id": "task230_tree_foreign_visible",
			"team_id": "team_bravo",
			"dropship_visible": true,
			"dropship_position": visible_world,
			"show_lz_marker": false,
			"show_approach_vector": false,
		}, {
			"craft_id": "task230_tree_foreign_air_cargo",
			"team_id": "team_bravo",
			"dropship_visible": true,
			"dropship_position": hidden_world,
			"show_lz_marker": false,
			"show_approach_vector": false,
			"cargo_visual": true,
			"cargo_state": "inbound",
		}, {
			"craft_id": "task230_tree_foreign_surface_cargo",
			"team_id": "team_bravo",
			"dropship_visible": false,
			"dropship_position": hidden_world,
			"has_lz_position": true,
			"lz_position": hidden_world,
			"show_lz_marker": false,
			"show_approach_vector": false,
			"cargo_visual": true,
			"cargo_state": "landed",
		}, {
			"craft_id": "task230_tree_surface_fallback",
			"team_id": "team_bravo",
			"dropship_visible": false,
			"dropship_position": hidden_world,
			"dropship_target_position": visible_world,
			"show_lz_marker": false,
			"show_approach_vector": false,
			"cargo_visual": true,
			"cargo_state": "landed",
		}],
	}
	primary_view.call("set_fog_of_war_state", fog_state)
	primary_view.call("set_mission_drop_visual_state", payload)
	await _wait_frames(2)
	_assert_mixed_drop_tree(primary_view, false, "own_parent_initial")
	fog_state["terrain_knowledge"]["visible_tile_ids"] = PackedStringArray(["tile_0_0", "tile_1_0"])
	primary_view.call("set_fog_of_war_state", fog_state)
	await _wait_frames(2)
	_assert_mixed_drop_tree(primary_view, false, "unrelated_tile_delta")
	payload["team_id"] = "team_bravo"
	primary_view.call("set_mission_drop_visual_state", payload)
	await _wait_frames(2)
	_assert_mixed_drop_tree(primary_view, false, "foreign_parent_payload")
	fog_state["terrain_knowledge"]["visible_tile_ids"] = PackedStringArray(["tile_0_0", "tile_3_3"])
	primary_view.call("set_fog_of_war_state", fog_state)
	await _wait_frames(2)
	_assert_mixed_drop_tree(primary_view, true, "foreign_parent_visibility_gain")
	fog_state["terrain_knowledge"]["visible_tile_ids"] = PackedStringArray(["tile_0_0"])
	primary_view.call("set_fog_of_war_state", fog_state)
	await _wait_frames(2)
	_assert_mixed_drop_tree(primary_view, false, "foreign_parent_visibility_loss")
	payload["team_id"] = ""
	primary_view.call("set_mission_drop_visual_state", payload)
	await _wait_frames(2)
	_assert_mixed_drop_tree(primary_view, false, "neutral_parent_payload")
	payload["team_id"] = "team_alpha"
	primary_view.call("set_mission_drop_visual_state", payload)
	await _wait_frames(2)
	_assert_mixed_drop_tree(primary_view, false, "restored_own_parent_payload")
	primary_view.queue_free()
	await _wait_frames(2)


func _assert_mixed_drop_tree(primary_view: Node, foreign_hidden_visible: bool, case_name: String) -> void:
	var craft_nodes: Dictionary = Dictionary(primary_view.get("_dropship_visual_nodes_by_id"))
	var drop_root: Node = primary_view.get("_drop_root")
	_assert(_drop_node_is_visible(craft_nodes.get("task230_tree_own", null)), "%s: actual own aircraft stays visible in the mixed drop tree" % case_name)
	_assert(_drop_node_is_visible(craft_nodes.get("task230_tree_foreign_visible", null)), "%s: actual foreign aircraft on a visible tile stays visible in the mixed drop tree" % case_name)
	_assert(_drop_node_is_visible(drop_root.get_node_or_null("DropshipLZ_task230_tree_own_3_3")), "%s: actual own known-terrain planned LZ stays visible" % case_name)
	_assert(_drop_node_is_visible(craft_nodes.get("task230_tree_foreign_air_cargo", null)) == foreign_hidden_visible, "%s: actual foreign cargo aircraft follows its own tile visibility" % case_name)
	_assert(_drop_node_is_visible(drop_root.get_node_or_null("CargoTouchdownLabel_task230_tree_foreign_air_cargo")) == foreign_hidden_visible, "%s: actual foreign airborne cargo label follows its aircraft admission" % case_name)
	_assert(_drop_node_is_visible(drop_root.get_node_or_null("CargoTouchdownLabel_task230_tree_foreign_surface_cargo")) == foreign_hidden_visible, "%s: actual foreign surface cargo label follows its surface admission" % case_name)
	_assert(_drop_node_is_visible(drop_root.get_node_or_null("CargoTouchdownLabel_task230_tree_surface_fallback")) == foreign_hidden_visible, "%s: cargo without LZ follows its actual ship anchor, independently from the visible target" % case_name)


func _drop_node_is_visible(node_variant: Variant) -> bool:
	return is_instance_valid(node_variant) and node_variant is Node3D and (node_variant as Node3D).is_visible_in_tree()


func _test_surface_marker_modes_are_read_only() -> void:
	# Fixture evidence for the existing flight/FoW contract, not a physical
	# mission/deployment proof. A friendly-air exemption must not expose LZs.
	var map_data = _build_air_fixture_map()
	var hidden_world: Vector2 = map_data.call("get_tile_at_grid", Vector2i(3, 3)).world_position
	var origin_world: Vector2 = map_data.call("get_tile_at_grid", Vector2i(0, 0)).world_position
	var terrain_before: Array = []
	for tile in Array(map_data.call("get_tiles")):
		terrain_before.append(tile.call("to_dict"))
	var payload: Dictionary = {
		"dropship_visible": true,
		"dropship_position": hidden_world,
		"team_id": "team_alpha",
		"has_lz_position": true,
		"lz_position": hidden_world,
		"requested_lz_position": hidden_world,
		"resolved_lz_position": hidden_world,
		"dropship_visuals": [{
			"craft_id": "task230_friendly_air",
			"team_id": "team_alpha",
			"dropship_visible": true,
			"dropship_position": origin_world,
			"has_lz_position": true,
			"lz_position": hidden_world,
			"show_approach_vector": true,
			"approach_vector_origin_position": origin_world,
			"approach_vector_target_position": hidden_world,
		}, {
			"craft_id": "task230_foreign_air",
			"team_id": "team_bravo",
			"dropship_visible": true,
			"dropship_position": origin_world,
			"has_lz_position": true,
			"lz_position": hidden_world,
			"show_approach_vector": true,
			"approach_vector_origin_position": origin_world,
			"approach_vector_target_position": hidden_world,
		}, {
			"craft_id": "task230_neutral_air",
			"team_id": "",
			"dropship_visible": true,
			"dropship_position": origin_world,
			"has_lz_position": true,
			"lz_position": hidden_world,
			"show_approach_vector": true,
			"approach_vector_origin_position": origin_world,
			"approach_vector_target_position": hidden_world,
		}],
	}
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	for spec in [
		# Exact expected primary/requested/resolved/approach counts are derived
		# from one primary marker and the three explicitly owned craft entries.
		["blackout_unknown", "unexplored_blackout", false, false, "team_alpha", 0, 0, 0, 0],
		["blackout_explored", "unexplored_blackout", false, true, "team_alpha", 0, 0, 0, 0],
		["known_own_plan", "known_terrain", false, true, "team_alpha", 1, 2, 1, 1],
		["known_foreign_plan", "known_terrain", false, true, "team_bravo", 0, 1, 0, 1],
		["known_neutral_plan", "known_terrain", false, true, "", 0, 1, 0, 1],
		["blackout_visible", "unexplored_blackout", true, true, "team_alpha", 1, 4, 1, 3],
		["off", "off", false, false, "", 1, 4, 1, 3],
	]:
		var case_name: String = String(spec[0])
		payload["team_id"] = String(spec[4])
		var payload_before: Dictionary = payload.duplicate(true)
		var visible_ids := PackedStringArray(["tile_0_0"])
		var explored_ids := PackedStringArray(["tile_0_0"])
		if bool(spec[2]):
			visible_ids.append("tile_3_3")
		if bool(spec[3]):
			explored_ids.append("tile_3_3")
		var fog_state: Dictionary = {
			"mode": String(spec[1]),
			"team_id": "team_alpha",
			"terrain_knowledge": {"visible_tile_ids": visible_ids, "explored_tile_ids": explored_ids},
			"current_visibility": {"visible_target_ids": PackedStringArray(), "visible_event_ids": PackedStringArray()},
		}
		var fog_before: Dictionary = fog_state.duplicate(true)
		primary_view.call("set_fog_of_war_state", fog_state)
		primary_view.call("set_mission_drop_visual_state", payload)
		await _wait_frames(8)
		var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
		_assert(int(snapshot.get("lz_tile_marker_count", -1)) == int(spec[5]), "%s: primary terrain LZ follows mode, owner and current tile visibility" % case_name)
		_assert(int(snapshot.get("requested_lz_marker_count", -1)) == int(spec[6]), "%s: requested and mixed-owner craft LZs use their own surface visibility gate" % case_name)
		_assert(int(snapshot.get("resolved_lz_marker_count", -1)) == int(spec[7]), "%s: resolved landing position shares the primary surface visibility gate" % case_name)
		_assert(int(snapshot.get("dropship_approach_line_count", -1)) == int(spec[8]), "%s: mixed-owner approach lines follow each craft's target visibility" % case_name)
		_assert(int(snapshot.get("air_visual_count", 0)) == 3, "%s: aircraft proxy construction stays separate from surface-marker admission" % case_name)
		_assert(fog_state == fog_before and payload == payload_before, "%s: visual filtering does not mutate FoW knowledge or source flight payload" % case_name)
		await _capture_air_fow_fixture(case_name)
	var terrain_after: Array = []
	for tile in Array(map_data.call("get_tiles")):
		terrain_after.append(tile.call("to_dict"))
	_assert(terrain_after == terrain_before, "Air/FoW surface filtering leaves terrain heights, objects, walkability and LOS unchanged")
	primary_view.queue_free()
	await _wait_frames(2)


func _drop_child_instance_ids(primary_view: Node) -> Array:
	var result: Array = []
	var drop_root: Node = primary_view.get("_drop_root")
	if drop_root != null:
		for child in drop_root.get_children():
			result.append(child.get_instance_id())
	return result


func _capture_air_fow_fixture(case_name: String) -> void:
	var capture_directory: String = ""
	for argument in OS.get_cmdline_user_args():
		if String(argument).begins_with("--air-fow-capture-dir="):
			capture_directory = String(argument).trim_prefix("--air-fow-capture-dir=")
	if capture_directory.is_empty():
		return
	_assert(DisplayServer.get_name() != "headless", "Air/FoW fixture captures require a native renderer")
	if DisplayServer.get_name() == "headless":
		return
	_assert(root.mode == Window.MODE_FULLSCREEN and DisplayServer.window_get_size() == DisplayServer.screen_get_size(DisplayServer.window_get_current_screen()), "Air fixture uses actual active-display fullscreen")
	await RenderingServer.frame_post_draw
	var directory_result: Error = DirAccess.make_dir_recursive_absolute(capture_directory)
	_assert(directory_result == OK or directory_result == ERR_ALREADY_EXISTS, "Native fixture capture directory is available")
	var capture_path: String = capture_directory.path_join("task230_%s.png" % case_name)
	_assert(root.get_texture().get_image().save_png(capture_path) == OK, "Native air/FoW fixture PNG saved: %s" % case_name)
	print("TASK230_NATIVE_FIXTURE_CAPTURE ", capture_path)


func _test_multiplayer_snapshot_carries_read_only_air_layer() -> void:
	var simulation_root: Node = SIMULATION_ROOT_SCRIPT.new()
	root.add_child(simulation_root)
	simulation_root.set("tick_counter", 17)
	simulation_root.call(
		"set_multiplayer_snapshot_context",
		{
			"dropship": {
				"visible": true,
				"state": "inbound",
				"has_lz": true,
				"position": Vector2(64.0, 64.0),
				"target_position": Vector2(128.0, 96.0),
				"lz_position": Vector2(128.0, 96.0),
				"team_id": "team_alpha",
				"air_layer": "mission_air",
				"flight_altitude_clearance": 1.62,
				"terrain_height_independent": false,
				"reveals_unknown_terrain": true,
			},
		}
	)
	var snapshot: Dictionary = Dictionary(simulation_root.call("build_multiplayer_snapshot"))
	var dropship: Dictionary = Dictionary(snapshot.get("dropship", {}))
	_assert(String(dropship.get("air_layer", "")) == "mission_air", "Snapshot carries air layer")
	_assert(float(dropship.get("flight_altitude_clearance", 0.0)) >= 1.62, "Snapshot carries flight altitude clearance")
	_assert(bool(dropship.get("terrain_height_independent", false)), "Snapshot forces terrain-height-independent display flag")
	_assert(not bool(dropship.get("reveals_unknown_terrain", true)), "Snapshot forbids unknown-terrain reveal flag")
	var client_root: Node = SIMULATION_ROOT_SCRIPT.new()
	root.add_child(client_root)
	var apply_result: Dictionary = Dictionary(client_root.call("apply_multiplayer_snapshot", snapshot))
	var client_state: Dictionary = Dictionary(client_root.call("get_last_server_state"))
	_assert(bool(apply_result.get("accepted", false)), "Client accepts air-layer dropship snapshot")
	_assert(Dictionary(client_state.get("dropship", {})).get("air_layer", "") == "mission_air", "Client stores dropship air state read-only")
	_assert(Array(client_root.get("command_queue")).is_empty(), "Applying air-layer snapshot does not enqueue commands")
	simulation_root.queue_free()
	client_root.queue_free()


func _build_air_fixture_map():
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_230_air_fixture", Vector2i(4, 4), Vector2.ZERO)
	var hill_tile = map_data.call("get_tile_at_grid", Vector2i(1, 1))
	hill_tile.height_level = 2
	hill_tile.edge_type = TERRAIN_TILE_DATA_SCRIPT.get("EDGE_CLIFF")
	hill_tile.surface_type = TERRAIN_TILE_DATA_SCRIPT.get("SURFACE_SAND")
	hill_tile.object_type_id = "wall_straight_se"
	hill_tile.object_height = 2
	hill_tile.blocks_los = true
	hill_tile.walkable = false
	return map_data


func _top_y(height_level: int) -> float:
	return float(height_level) * HEIGHT_STEP


func _read_text_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


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
