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
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_230 Flight Altitude Layer and Air Visibility Audit ===")
	_test_contract_doc_exists()
	await _test_dropship_air_layer_above_hill_terrain()
	await _test_fow_hides_air_surface_markers_without_hiding_friendly_air()
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
	primary_view.queue_free()
	await _wait_frames(2)


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
