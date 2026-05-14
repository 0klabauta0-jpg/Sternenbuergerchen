extends SceneTree

const DEBUG_SCENE: PackedScene = preload("res://scenes/tests/facing_sightline_debug_map.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")

const MAP_PATH: String = "res://maps/facing_sightline_debug_12x12.json"
const SCENARIO_PATH: String = "res://data/mission_scenarios/facing_sightline_debug_12x12.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_401 Facing Sightline Debug Map ===")
	_test_map_and_scenario_authoring()
	await _test_scene_uses_existing_facing_and_fireline_visuals()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_map_and_scenario_authoring() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	_assert(map_data != null, "Facing debug map loads from data file")
	if map_data == null:
		return
	_assert(Vector2i(map_data.call("get_grid_size")) == Vector2i(12, 12), "Facing debug map is exactly 12x12")
	_assert(Array(map_data.call("get_tiles")).size() == 144, "Facing debug map contains 144 authored tiles")
	_assert(int(map_data.call("get_mission_slot_count")) == 2, "Facing debug map keeps two mission slots for the two NPC fixture")
	_assert(String(Dictionary(map_data.call("get_marker_record", "corner_north")).get("name", "")) == "Nord", "North compass marker is authored as Nord")
	_assert(String(Dictionary(map_data.call("get_marker_record", "corner_east")).get("name", "")) == "Ost", "East compass marker is authored as Ost")
	_assert(String(Dictionary(map_data.call("get_marker_record", "corner_south")).get("name", "")) == "Sued", "South compass marker is authored as Sued")
	_assert(String(Dictionary(map_data.call("get_marker_record", "corner_west")).get("name", "")) == "West", "West compass marker is authored as West")

	var scenario = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", SCENARIO_PATH)
	_assert(scenario != null, "Facing debug scenario loads from data file")
	if scenario == null:
		return
	var validation: Dictionary = Dictionary(scenario.call("validate"))
	_assert(bool(validation.get("valid", false)), "Facing debug scenario validates without authoring errors")
	_assert(String(scenario.get("map_file_path")) == MAP_PATH, "Facing debug scenario points at the 12x12 map")


func _test_scene_uses_existing_facing_and_fireline_visuals() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := DEBUG_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(28)

	var controller := scene.get_node_or_null("TacticalController")
	var primary_view := await _wait_for_node(scene, NodePath("Primary3DView"), 24)
	var simulation_root := scene.get_node_or_null("SimulationRoot")
	var unit_alpha := scene.get_node_or_null("UnitAlpha")
	var unit_bravo := scene.get_node_or_null("UnitBravo")
	_assert(controller != null and primary_view != null and simulation_root != null, "Debug scene exposes controller, Primary3DView and SimulationRoot")
	_assert(unit_alpha != null and unit_bravo != null, "Debug scene keeps the two fixture NPC nodes")
	if controller == null or primary_view == null or simulation_root == null or unit_alpha == null or unit_bravo == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var alpha_status: Dictionary = Dictionary(unit_alpha.call("get_runtime_status").call("to_dict"))
	var bravo_status: Dictionary = Dictionary(unit_bravo.call("get_runtime_status").call("to_dict"))
	_assert(String(unit_alpha.call("get_fireteam_id")) == "aim" and String(unit_bravo.call("get_fireteam_id")) == "look", "NPCs use the fixture fireteam IDs")
	_assert(String(alpha_status.get("weapon_posture", "")) == "aimed", "Weapon-ready NPC uses existing runtime weapon_posture=aimed")
	_assert(String(bravo_status.get("weapon_posture", "")) == "lowered", "Looking NPC uses existing runtime weapon_posture=lowered")
	_assert(String(alpha_status.get("movement_posture", "")) == "engage", "Weapon-ready NPC uses engage posture")
	_assert(String(bravo_status.get("movement_posture", "")) == "idle", "Looking NPC stays idle with weapon lowered")
	_assert((unit_alpha as Node2D).global_position.distance_to((unit_bravo as Node2D).global_position) >= 200.0, "Fixture NPCs stand far enough apart for manual sightline checks")

	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(snapshot.get("tile_count", 0)) == 144, "Primary3DView renders the 12x12 map tiles")
	_assert(int(snapshot.get("compass_marker_count", 0)) == 4, "Primary3DView renders all four compass markers without clicks")
	_assert(_compass_label_text(primary_view, "corner_north") == "Nord", "North compass label renders as Nord")
	_assert(_compass_label_text(primary_view, "corner_east") == "Ost", "East compass label renders as Ost")
	_assert(_compass_label_text(primary_view, "corner_south") == "Sued", "South compass label renders as Sued")
	_assert(_compass_label_text(primary_view, "corner_west") == "West", "West compass label renders as West")

	var visible_unit_ids: Array = Array(snapshot.get("visible_unit_proxy_ids", []))
	_assert(visible_unit_ids.has("unit_alpha") and visible_unit_ids.has("unit_bravo"), "Primary3DView renders both fixture NPC proxies")
	var proxy_state_by_id: Dictionary = Dictionary(snapshot.get("unit_proxy_state_by_id", {}))
	var alpha_proxy: Dictionary = Dictionary(proxy_state_by_id.get("unit_alpha", {}))
	var bravo_proxy: Dictionary = Dictionary(proxy_state_by_id.get("unit_bravo", {}))
	_assert(String(alpha_proxy.get("unit_weapon_posture", "")) == "aimed", "Rendered weapon NPC exposes aimed proxy posture")
	_assert(String(bravo_proxy.get("unit_weapon_posture", "")) == "lowered", "Rendered looking NPC exposes lowered proxy posture")
	_assert(absf(float(alpha_proxy.get("unit_model_root_rotation_y_degrees", 0.0)) - 90.0) < 0.1, "Aimed NPC model root corrects the imported character forward axis")
	_assert(absf(float(bravo_proxy.get("unit_model_root_rotation_y_degrees", 0.0)) - 90.0) < 0.1, "Lowered NPC model root corrects the imported character forward axis")

	var orientation_entries: Array = Array(snapshot.get("fireteam_orientation_entries", []))
	var aim_orientation: Dictionary = _find_entry(orientation_entries, "fireteam_id", "aim")
	var look_orientation: Dictionary = _find_entry(orientation_entries, "fireteam_id", "look")
	_assert(int(snapshot.get("fireteam_orientation_visual_count", 0)) >= 2, "Existing orientation overlay draws Facing/Sichtlinie arrows for both NPCs")
	_assert(not aim_orientation.is_empty() and Vector2(aim_orientation.get("heading_direction", Vector2.ZERO)).dot(Vector2.UP) > 0.98, "Aimed NPC facing/sightline arrow points north from facing metadata")
	_assert(not look_orientation.is_empty() and Vector2(look_orientation.get("heading_direction", Vector2.ZERO)).dot(Vector2.DOWN) > 0.98, "Lowered NPC facing/sightline arrow points south from facing metadata")

	var fire_sector: Dictionary = Dictionary(controller.call("get_fire_sector_overlay_snapshot"))
	_assert(bool(fire_sector.get("enabled", false)), "Fixture enables the existing fire-sector overlay automatically")
	_assert(Array(fire_sector.get("selected_fireteam_ids", [])).has("aim"), "Fixture selects the aimed fireteam for the weapon/shot line")
	_assert(bool(snapshot.get("friendly_fire_sector_overlay_enabled", false)), "Primary3DView receives the fire-sector overlay toggle")
	_assert(int(snapshot.get("friendly_fire_sector_los_line_count", 0)) >= 1, "Existing fire-sector LOS path draws the visible weapon/shot line")
	var aim_fire_entry: Dictionary = _find_entry(Array(snapshot.get("friendly_aim_entries", [])), "unit_id", "unit_alpha")
	_assert(not aim_fire_entry.is_empty(), "Weapon-ready NPC owns the visible weapon/shot line entry")
	_assert(String(aim_fire_entry.get("visual_shape", "")) == "los_line", "Weapon/shot line uses the existing LOS-line visual shape")
	_assert(String(aim_fire_entry.get("line_origin_anchor", "")) == "weapon_visual", "Weapon/shot line starts at the raised weapon visual anchor")
	var weapon_direction: Vector2 = (Vector2(aim_fire_entry.get("tip_position", Vector2.ZERO)) - Vector2(aim_fire_entry.get("origin_position", Vector2.ZERO))).normalized()
	_assert(weapon_direction.dot(Vector2.RIGHT) > 0.90, "Weapon/shot line points east toward the authored target")
	_assert(bool(alpha_proxy.get("unit_aim_pose_weapon_node_available", false)), "Weapon-ready NPC exposes an attached weapon visual")
	_assert(bool(alpha_proxy.get("unit_aim_pose_yaw_active", false)), "Weapon-ready NPC applies the existing aim direction to the weapon pose")
	_assert(absf(float(alpha_proxy.get("unit_aim_pose_yaw_delta_degrees", 0.0))) >= 20.0, "Weapon-ready NPC visibly offsets the raised weapon toward the shot line")
	_assert(_find_entry(Array(snapshot.get("friendly_aim_entries", [])), "unit_id", "unit_bravo").is_empty(), "Lowered looking NPC has no selected weapon/shot line in the fixture")

	controller.call("_set_selected_fireteams", PackedStringArray(["look"]), false)
	controller.call("_refresh_order_visuals")
	await _wait_frames(6)
	var look_selected_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var look_fire_entry: Dictionary = _find_entry(Array(look_selected_snapshot.get("friendly_aim_entries", [])), "unit_id", "unit_bravo")
	_assert(not look_fire_entry.is_empty(), "Selecting the lowered NPC uses the existing fire-sector path")
	var look_weapon_direction: Vector2 = (Vector2(look_fire_entry.get("tip_position", Vector2.ZERO)) - Vector2(look_fire_entry.get("origin_position", Vector2.ZERO))).normalized()
	_assert(look_weapon_direction.dot(Vector2.DOWN) > 0.90, "Selected lowered NPC weapon/target line overlaps its south-facing sightline")
	_assert(_find_entry(Array(look_selected_snapshot.get("friendly_aim_entries", [])), "unit_id", "unit_alpha").is_empty(), "Switching selection removes the upper NPC weapon/shot line")

	var command_count_before: int = simulation_root.command_queue.size()
	var effect_count_before: int = simulation_root.effects_queue.size()
	controller.call("_refresh_order_visuals")
	await _wait_frames(6)
	_assert(simulation_root.command_queue.size() == command_count_before, "Visual refresh enqueues no SimulationRoot commands")
	_assert(simulation_root.effects_queue.size() == effect_count_before, "Visual refresh enqueues no SimulationRoot effects")

	scene.queue_free()
	await _wait_frames(2)


func _compass_label_text(primary_view: Node, marker_id: String) -> String:
	if primary_view == null:
		return ""
	var label := primary_view.find_child("CompassMarker_%s" % marker_id, true, false) as Label3D
	if label == null:
		return ""
	return String(label.text)


func _find_entry(entries: Array, key: String, value: String) -> Dictionary:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get(key, "")).strip_edges().to_lower() == value.strip_edges().to_lower():
			return entry
	return {}


func _wait_for_node(parent: Node, path: NodePath, frame_limit: int) -> Node:
	for _index in range(maxi(frame_limit, 1)):
		var node := parent.get_node_or_null(path)
		if node != null:
			return node
		await process_frame
	return null


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
