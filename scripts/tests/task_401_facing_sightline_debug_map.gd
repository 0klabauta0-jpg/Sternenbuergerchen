extends SceneTree

const DEBUG_SCENE: PackedScene = preload("res://scenes/tests/facing_sightline_debug_map.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")

const MAP_PATH: String = "res://maps/facing_sightline_debug_12x12.json"
const SCENARIO_PATH: String = "res://data/mission_scenarios/facing_sightline_debug_12x12.json"
const MINI_CARDS_PATH: String = "TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox"

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

	var selected_marker_entry: Dictionary = _find_entry(Array(snapshot.get("selected_unit_marker_entries", [])), "unit_id", "unit_alpha")
	_assert(not selected_marker_entry.is_empty() and float(selected_marker_entry.get("surface_offset", 999.0)) <= 0.02, "Selected NPC marker sits at foot/ground height")

	primary_view.call("pan_camera", Vector2(1.0, 0.0), 1.0)
	await _wait_frames(2)
	var focus_after_manual_pan: Vector2 = Vector2(primary_view.call("get_camera_focus_grid_position"))
	controller.call("_apply_unit_click_selection", unit_bravo, false)
	await _wait_frames(4)
	var focus_after_map_unit_select: Vector2 = Vector2(primary_view.call("get_camera_focus_grid_position"))
	_assert(focus_after_map_unit_select.distance_to(focus_after_manual_pan) <= 0.001, "Map NPC selection keeps the 3D camera focus unchanged")
	var mini_panel := scene.get_node_or_null("TacticalUI/FireteamMiniPanel") as Control
	var event_log_panel := scene.get_node_or_null("TacticalUI/TacticalEventLogPanel") as Control
	var look_mini_card := scene.get_node_or_null("%s/FireteamMiniCard_Look" % MINI_CARDS_PATH) as Control
	_assert(look_mini_card != null and look_mini_card.mouse_filter == Control.MOUSE_FILTER_STOP, "Lower Fireteam mini card keeps a direct click target")
	_assert(mini_panel != null and event_log_panel != null and mini_panel.z_index > event_log_panel.z_index, "Fireteam mini cards stay above the read-only event-log window")
	if look_mini_card != null:
		var card_click := InputEventMouseButton.new()
		card_click.button_index = MOUSE_BUTTON_LEFT
		card_click.pressed = false
		look_mini_card.call("_gui_input", card_click)
		await _wait_frames(4)
		var focus_after_card_click: Vector2 = Vector2(primary_view.call("get_camera_focus_grid_position"))
		_assert(focus_after_card_click.distance_to(focus_after_map_unit_select) > 0.01, "Left Fireteam card click is the path that recenters the 3D camera")
		_assert(Array(controller.call("get_selected_fireteam_ids")).has("look"), "Left Fireteam card click keeps the lower NPC Fireteam selected")
	controller.call("_set_selected_fireteams", PackedStringArray(["aim"]), false)
	controller.call("_refresh_order_visuals")
	await _wait_frames(4)
	snapshot = Dictionary(primary_view.call("get_render_snapshot"))

	var visible_unit_ids: Array = Array(snapshot.get("visible_unit_proxy_ids", []))
	_assert(visible_unit_ids.has("unit_alpha") and visible_unit_ids.has("unit_bravo"), "Primary3DView renders both fixture NPC proxies")
	var proxy_state_by_id: Dictionary = Dictionary(snapshot.get("unit_proxy_state_by_id", {}))
	var alpha_proxy: Dictionary = Dictionary(proxy_state_by_id.get("unit_alpha", {}))
	var bravo_proxy: Dictionary = Dictionary(proxy_state_by_id.get("unit_bravo", {}))
	_assert(String(alpha_proxy.get("unit_weapon_posture", "")) == "aimed", "Rendered weapon NPC exposes aimed proxy posture")
	_assert(String(bravo_proxy.get("unit_weapon_posture", "")) == "lowered", "Rendered looking NPC exposes lowered proxy posture")
	_assert(absf(float(alpha_proxy.get("unit_model_root_rotation_y_degrees", 0.0)) - 270.0) < 0.1, "Aimed NPC model root corrects the imported character forward axis")
	_assert(absf(float(bravo_proxy.get("unit_model_root_rotation_y_degrees", 0.0)) - 270.0) < 0.1, "Lowered NPC model root corrects the imported character forward axis")
	_assert(int(snapshot.get("unit_animation_heading_sanitized_track_count", 0)) >= 2, "Walk animations strip imported heading-control rotation tracks for live NPC proxies")
	var alpha_proxy_node := _find_proxy_node_by_unit_id(primary_view, "unit_alpha") as Node3D
	var alpha_animation_player := _find_unit_visual_animation_player(alpha_proxy_node)
	var alpha_walk_animation: Animation = alpha_animation_player.get_animation("walk") if alpha_animation_player != null and alpha_animation_player.has_animation("walk") else null
	_assert(alpha_walk_animation != null and not _animation_has_rotation_track_suffix(alpha_walk_animation, ":HipsCtrl"), "Walk animation leaves proxy/model-root facing as the only heading owner")
	_assert(alpha_walk_animation != null and not _animation_has_rotation_track_suffix(alpha_walk_animation, ":Hips"), "Walk animation strips the body-root Hips rotation that can turn the model's back into facing")
	await _assert_unit_model_forward_matches_runtime_facing(primary_view, unit_alpha as Node2D, "unit_alpha")
	await _assert_unit_model_forward_matches_runtime_facing(primary_view, unit_bravo as Node2D, "unit_bravo")

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
	_assert(weapon_direction.dot(Vector2.UP) > 0.90, "Weapon/shot line follows the north-facing sightline instead of the authored target")
	_assert(bool(alpha_proxy.get("unit_aim_pose_weapon_node_available", false)), "Weapon-ready NPC exposes an attached weapon visual")
	_assert(bool(alpha_proxy.get("unit_aim_pose_yaw_active", false)), "Weapon-ready NPC applies the existing aim direction to the weapon pose")
	_assert(absf(float(alpha_proxy.get("unit_aim_pose_yaw_delta_degrees", 0.0))) <= 1.0, "Weapon-ready NPC binds weapon yaw to the same facing direction as the sightline")
	var alpha_weapon_anchor_distance: float = float(alpha_proxy.get("unit_weapon_anchor_distance_3d", 999.0))
	_assert(alpha_weapon_anchor_distance >= 0.0 and alpha_weapon_anchor_distance <= 0.52, "Weapon-ready NPC keeps the weapon root on the hand anchor (distance %.3f)" % alpha_weapon_anchor_distance)
	_assert(_find_entry(Array(snapshot.get("friendly_aim_entries", [])), "unit_id", "unit_bravo").is_empty(), "Lowered looking NPC has no selected weapon/shot line in the fixture")
	await _assert_live_facing_updates_primary_view_visuals(controller, primary_view, unit_alpha as Node2D)

	controller.call("_set_selected_fireteams", PackedStringArray(["look"]), false)
	controller.call("_refresh_order_visuals")
	await _wait_frames(6)
	var look_selected_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var look_fire_entry: Dictionary = _find_entry(Array(look_selected_snapshot.get("friendly_aim_entries", [])), "unit_id", "unit_bravo")
	_assert(not look_fire_entry.is_empty(), "Selecting the lowered NPC uses the existing fire-sector path")
	var look_weapon_direction: Vector2 = (Vector2(look_fire_entry.get("tip_position", Vector2.ZERO)) - Vector2(look_fire_entry.get("origin_position", Vector2.ZERO))).normalized()
	_assert(look_weapon_direction.dot(Vector2.DOWN) > 0.90, "Selected lowered NPC weapon/target line overlaps its south-facing sightline")
	_assert(_find_entry(Array(look_selected_snapshot.get("friendly_aim_entries", [])), "unit_id", "unit_alpha").is_empty(), "Switching selection removes the upper NPC weapon/shot line")
	await _assert_moving_units_keep_model_forward_on_live_lines(simulation_root, controller, primary_view, unit_alpha as Node2D, unit_bravo as Node2D)

	var command_count_before: int = simulation_root.command_queue.size()
	var effect_count_before: int = simulation_root.effects_queue.size()
	controller.call("_refresh_order_visuals")
	await _wait_frames(6)
	_assert(simulation_root.command_queue.size() == command_count_before, "Visual refresh enqueues no SimulationRoot commands")
	_assert(simulation_root.effects_queue.size() == effect_count_before, "Visual refresh enqueues no SimulationRoot effects")

	scene.queue_free()
	await _wait_frames(2)


func _assert_live_facing_updates_primary_view_visuals(controller: Node, primary_view: Node, unit_alpha: Node2D) -> void:
	if controller == null or primary_view == null or unit_alpha == null:
		_assert(false, "Primary3DView live facing verifier receives controller, view and unit")
		return
	var original_position: Vector2 = unit_alpha.global_position
	var original_facing: float = float(unit_alpha.get_meta("facing_angle", 0.0)) if unit_alpha.has_meta("facing_angle") else 0.0
	var had_original_facing: bool = unit_alpha.has_meta("facing_angle")
	var original_map_facing: float = float(unit_alpha.get_meta("map_facing_angle", 0.0)) if unit_alpha.has_meta("map_facing_angle") else 0.0
	var had_original_map_facing: bool = unit_alpha.has_meta("map_facing_angle")
	var original_target: Variant = unit_alpha.call("get_target_position") if unit_alpha.has_method("get_target_position") else null

	unit_alpha.global_position = original_position + Vector2(96.0, 0.0)
	unit_alpha.set_meta("facing_angle", Vector2.RIGHT.angle())
	if unit_alpha.has_method("set_target_position"):
		unit_alpha.call("set_target_position", unit_alpha.global_position)
	primary_view.call("_sync_unit_proxies", true)
	await create_timer(0.14).timeout
	await _wait_frames(4)

	var live_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var live_orientation: Dictionary = _find_entry(Array(live_snapshot.get("fireteam_orientation_entries", [])), "fireteam_id", "aim")
	_assert(
		not live_orientation.is_empty() and Vector2(live_orientation.get("heading_direction", Vector2.ZERO)).dot(Vector2.RIGHT) > 0.98,
		"Primary3DView orientation visual uses current live unit facing while order payload is stale"
	)
	_assert(
		String(live_orientation.get("heading_source", "")) == "unit_facing_live",
		"Primary3DView render snapshot marks live unit facing as orientation source"
	)
	var live_fire_entry: Dictionary = _find_entry(Array(live_snapshot.get("friendly_aim_entries", [])), "unit_id", "unit_alpha")
	var live_weapon_direction: Vector2 = (Vector2(live_fire_entry.get("tip_position", Vector2.ZERO)) - Vector2(live_fire_entry.get("origin_position", Vector2.ZERO))).normalized()
	_assert(
		not live_fire_entry.is_empty() and live_weapon_direction.dot(Vector2.RIGHT) > 0.90,
		"Weapon/shot line follows live facing during movement instead of stale anchor payload"
	)

	unit_alpha.global_position = original_position
	if had_original_facing:
		unit_alpha.set_meta("facing_angle", original_facing)
	elif unit_alpha.has_meta("facing_angle"):
		unit_alpha.remove_meta("facing_angle")
	if had_original_map_facing:
		unit_alpha.set_meta("map_facing_angle", original_map_facing)
	elif unit_alpha.has_meta("map_facing_angle"):
		unit_alpha.remove_meta("map_facing_angle")
	if unit_alpha.has_method("set_target_position"):
		unit_alpha.call("set_target_position", original_target)
	primary_view.call("_sync_unit_proxies", true)
	controller.call("_refresh_order_visuals")
	await _wait_frames(4)


func _assert_moving_units_keep_model_forward_on_live_lines(simulation_root: Node, controller: Node, primary_view: Node, unit_alpha: Node2D, unit_bravo: Node2D) -> void:
	if simulation_root == null or controller == null or primary_view == null or unit_alpha == null or unit_bravo == null:
		_assert(false, "Movement-facing verifier receives simulation, controller, view and units")
		return
	controller.call("_set_selected_fireteams", PackedStringArray(["aim", "look"]), false)
	controller.call("_refresh_order_visuals")
	await _wait_frames(4)
	_enqueue_debug_move_command(simulation_root, unit_alpha, unit_alpha.global_position + Vector2(96.0, -192.0))
	_enqueue_debug_move_command(simulation_root, unit_bravo, unit_bravo.global_position + Vector2(192.0, -96.0))
	for frame_index in range(92):
		await physics_frame
		await process_frame
		if frame_index in [4, 24, 64]:
			controller.call("_refresh_order_visuals")
			await _wait_frames(2)
			var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
			_assert_moving_unit_forward_sample(primary_view, snapshot, unit_alpha, "unit_alpha", frame_index)
			_assert_moving_unit_forward_sample(primary_view, snapshot, unit_bravo, "unit_bravo", frame_index)


func _enqueue_debug_move_command(simulation_root: Node, unit: Node2D, target_position: Vector2) -> void:
	var command = UNIT_COMMAND_SCRIPT.new()
	command.command_type = UNIT_COMMAND_SCRIPT.TYPE_MOVE_TO_POSITION
	command.unit_id = String(unit.call("get_unit_id"))
	command.team_id = String(unit.call("get_team_id"))
	command.target_position = target_position
	command.move_speed_factor = 1.0
	command.priority = 99
	command.source_command_type = "task_401_movement_facing_verifier"
	command.phase = 1
	unit.call("assign_unit_command", command)
	simulation_root.call("enqueue_command", command.to_dict())


func _assert_moving_unit_forward_sample(primary_view: Node, snapshot: Dictionary, unit: Node2D, unit_id: String, frame_index: int) -> void:
	var proxy := _find_proxy_node_by_unit_id(primary_view, unit_id) as Node3D
	var model_forward: Vector2 = _get_unit_model_forward_xz(proxy)
	var fireteam_id: String = String(unit.call("get_fireteam_id"))
	var orientation: Dictionary = _find_entry(Array(snapshot.get("fireteam_orientation_entries", [])), "fireteam_id", fireteam_id)
	var heading_direction: Vector2 = Vector2(orientation.get("heading_direction", Vector2.ZERO))
	var expected_forward: Vector2 = _world_direction_to_3d_xz(primary_view, unit.global_position, heading_direction)
	var forward_dot: float = model_forward.dot(expected_forward) if model_forward.length_squared() > 0.0001 and expected_forward.length_squared() > 0.0001 else -1.0
	_assert(
		forward_dot > 0.92,
		"%s moving model forward follows live Facing/Sichtlinie at frame %d (dot %.3f)" % [unit_id, frame_index, forward_dot]
	)
	var aim_entry: Dictionary = _find_entry(Array(snapshot.get("friendly_aim_entries", [])), "unit_id", unit_id)
	if not aim_entry.is_empty():
		var aim_direction: Vector2 = (Vector2(aim_entry.get("tip_position", Vector2.ZERO)) - Vector2(aim_entry.get("origin_position", Vector2.ZERO))).normalized()
		_assert(
			aim_direction.dot(heading_direction.normalized()) > 0.90,
			"%s moving weapon/shot line follows the same live heading at frame %d" % [unit_id, frame_index]
		)


func _assert_unit_model_forward_matches_runtime_facing(primary_view: Node, unit: Node2D, unit_id: String) -> void:
	if primary_view == null or unit == null:
		_assert(false, "Model-forward verifier receives Primary3DView and unit")
		return
	var original_facing: float = float(unit.get_meta("facing_angle", 0.0)) if unit.has_meta("facing_angle") else 0.0
	var had_original_facing: bool = unit.has_meta("facing_angle")
	var original_map_facing: float = float(unit.get_meta("map_facing_angle", 0.0)) if unit.has_meta("map_facing_angle") else 0.0
	var had_original_map_facing: bool = unit.has_meta("map_facing_angle")
	var original_target: Variant = unit.call("get_target_position") if unit.has_method("get_target_position") else null
	var directions: Array[Vector2] = [
		Vector2.UP,
		Vector2.DOWN,
		Vector2.RIGHT,
		Vector2.LEFT,
		Vector2(0.894427, -0.447214),
		Vector2(-0.894427, -0.447214),
		Vector2(0.894427, 0.447214),
		Vector2(-0.894427, 0.447214),
	]
	for direction in directions:
		var normalized_direction: Vector2 = direction.normalized()
		unit.set_meta("facing_angle", normalized_direction.angle())
		unit.set_meta("map_facing_angle", normalized_direction.angle())
		if unit.has_method("set_target_position"):
			unit.call("set_target_position", unit.global_position)
		primary_view.call("_sync_unit_proxies", true)
		await _wait_frames(3)
		var proxy := _find_proxy_node_by_unit_id(primary_view, unit_id) as Node3D
		var model_forward: Vector2 = _get_unit_model_forward_xz(proxy)
		var expected_forward: Vector2 = _world_direction_to_3d_xz(primary_view, unit.global_position, normalized_direction)
		var forward_dot: float = model_forward.dot(expected_forward) if model_forward.length_squared() > 0.0001 and expected_forward.length_squared() > 0.0001 else -1.0
		_assert(
			forward_dot > 0.96,
			"%s model forward matches runtime facing %s (dot %.3f)" % [unit_id, str(normalized_direction), forward_dot]
		)
	if had_original_facing:
		unit.set_meta("facing_angle", original_facing)
	elif unit.has_meta("facing_angle"):
		unit.remove_meta("facing_angle")
	if had_original_map_facing:
		unit.set_meta("map_facing_angle", original_map_facing)
	elif unit.has_meta("map_facing_angle"):
		unit.remove_meta("map_facing_angle")
	if unit.has_method("set_target_position"):
		unit.call("set_target_position", original_target)
	primary_view.call("_sync_unit_proxies", true)
	await _wait_frames(3)


func _get_unit_model_forward_xz(proxy: Node3D) -> Vector2:
	if proxy == null:
		return Vector2.ZERO
	var skeleton := _find_skeleton3d(proxy)
	if skeleton == null:
		return Vector2.ZERO
	var hips_bone: int = skeleton.find_bone("Hips")
	if hips_bone < 0:
		return Vector2.ZERO
	var hips_global: Transform3D = skeleton.global_transform * skeleton.get_bone_global_pose(hips_bone)
	var forward := Vector2(hips_global.basis.z.x, hips_global.basis.z.z)
	return forward.normalized() if forward.length_squared() > 0.0001 else Vector2.ZERO


func _world_direction_to_3d_xz(primary_view: Node, origin_world: Vector2, direction: Vector2) -> Vector2:
	if primary_view == null or direction.length_squared() <= 0.0001:
		return Vector2.ZERO
	var origin_3d: Vector3 = Vector3(primary_view.call("_world_to_surface_3d_position", origin_world, 0.0))
	var tip_3d: Vector3 = Vector3(primary_view.call("_world_to_surface_3d_position", origin_world + direction.normalized(), 0.0))
	var delta: Vector3 = tip_3d - origin_3d
	var forward := Vector2(delta.x, delta.z)
	return forward.normalized() if forward.length_squared() > 0.0001 else Vector2.ZERO


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


func _find_unit_visual_animation_player(node: Node) -> AnimationPlayer:
	if node == null:
		return null
	if node is AnimationPlayer and String(node.name) == "UnitVisualAnimationPlayer":
		return node as AnimationPlayer
	for child in node.get_children():
		var found: AnimationPlayer = _find_unit_visual_animation_player(child)
		if found != null:
			return found
	return null


func _find_proxy_node_by_unit_id(node: Node, unit_id: String) -> Node:
	if node == null:
		return null
	if String(node.get_meta("unit_id", "")).strip_edges().to_lower() == unit_id.strip_edges().to_lower():
		return node
	for child in node.get_children():
		var found := _find_proxy_node_by_unit_id(child, unit_id)
		if found != null:
			return found
	return null


func _find_skeleton3d(node: Node) -> Skeleton3D:
	if node == null:
		return null
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found: Skeleton3D = _find_skeleton3d(child)
		if found != null:
			return found
	return null


func _animation_has_rotation_track_suffix(animation: Animation, suffix: String) -> bool:
	if animation == null:
		return false
	for track_index in range(animation.get_track_count()):
		if animation.track_get_type(track_index) == Animation.TYPE_ROTATION_3D and String(animation.track_get_path(track_index)).ends_with(suffix):
			return true
	return false


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
