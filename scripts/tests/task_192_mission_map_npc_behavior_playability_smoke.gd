extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const BLUE_UNIT_IDS: Array = ["unit_alpha", "unit_bravo", "unit_delta", "unit_hotel"]
const INITIAL_ACTIVE_ENEMY_IDS: Array = ["enemy_delta"]
const SECOND_WAVE_ENEMY_IDS: Array = ["enemy_echo"]
const MIN_SPACING: float = 36.0

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_192 Mission Map NPC Behavior Playability Smoke ===")
	await _test_integrated_mission_npc_behavior_smoke()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_integrated_mission_npc_behavior_smoke() -> void:
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene_for_blue_drop(scene)
	_stage_waiting_dropship(scene.get_node("TacticalController"))
	root.add_child(scene)
	await _wait_frames(24)
	await _wait_physics_frames(4)

	var context: Dictionary = _get_context(scene)
	_assert(not context.is_empty(), "Mission exposes controller, combat, registries, SimulationRoot, TerrainRegistry and Primary3DView")
	if context.is_empty():
		scene.queue_free()
		await _wait_frames(2)
		return

	_assert(_legacy_readability_overlays_are_hidden(scene), "Mission starts with legacy readability overlays suppressed behind the 2.5D primary view")
	_assert(_primary_dropship_visible(context["primary_view"]), "Waiting dropship is visible before insertion")
	await _audit_presence_phase(context, "initial enemy spawn", INITIAL_ACTIVE_ENEMY_IDS, [], SECOND_WAVE_ENEMY_IDS)

	await _deploy_blue_fireteam(context)
	_set_probe_weapon_loadouts(context)
	_sync_primary_view_units(context)
	await _wait_frames(12)
	await _audit_presence_phase(context, "after blue deploy", BLUE_UNIT_IDS + INITIAL_ACTIVE_ENEMY_IDS, BLUE_UNIT_IDS, SECOND_WAVE_ENEMY_IDS)
	_assert(bool(context["ftl_registry"].call("has_ftl", "team_alpha")), "Dropship deploy registers team_alpha in FTLRegistry")

	var enemy_wave_controller: Node = context["enemy_wave_controller"]
	enemy_wave_controller.call("_start_next_wave")
	await _wait_frames(12)
	await _wait_physics_frames(4)
	_sync_primary_view_units(context)
	await _wait_frames(8)
	_assert(int(enemy_wave_controller.call("get_current_wave_number")) == 2, "Second authored enemy wave can be activated during the smoke run")
	var active_ids: Array = BLUE_UNIT_IDS + INITIAL_ACTIVE_ENEMY_IDS + SECOND_WAVE_ENEMY_IDS
	await _audit_presence_phase(context, "after enemy wave", active_ids, BLUE_UNIT_IDS, [])
	_assert(_all_registered_units_keep_spacing(context["unit_registry"], MIN_SPACING), "Registered friendly and enemy units keep the minimum spacing before command execution")

	await _run_command_chain_and_movement(context)
	_force_contact(context)
	await _wait_frames(8)
	_assert(int(Dictionary(context["primary_view"].call("get_render_snapshot")).get("contact_count", 0)) > 0, "Contact markers reach the 2.5D mission map")

	await _run_live_medic_adjacency_case(context)
	_assert(_weapon_visual_snapshot_is_clean(context["primary_view"]), "Weapon visuals are present or fail through explicit missing-asset diagnostics")
	_assert(_multiplayer_snapshot_matches_registry(context["simulation_root"], context["unit_registry"]), "Multiplayer snapshot mirrors active registry units after the integrated run")

	scene.queue_free()
	await _wait_frames(2)


func _run_command_chain_and_movement(context: Dictionary) -> void:
	var controller: Node = context["controller"]
	var primary_view: Node = context["primary_view"]
	var simulation_root: Node = context["simulation_root"]
	var objective_position: Vector2 = _get_objective_position(simulation_root, Vector2(448.0, 285.0))

	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	_assert(bool(controller.call("set_selected_fireteams_tactical_stance", "cautious")), "Selected blue fireteam accepts a cautious stance for bounding/caterpillar readability")

	var move_refs: Array = Array(controller.call("_create_waypoints_for_selected_fireteams", objective_position + Vector2(-160.0, -96.0)))
	controller.call("_set_waypoint_command_for_targets", move_refs, "move")
	var defend_refs: Array = Array(controller.call("_create_waypoints_for_selected_fireteams", objective_position + Vector2(-96.0, -48.0)))
	controller.call("_set_waypoint_command_for_targets", defend_refs, "defend")
	var take_refs: Array = Array(controller.call("_create_waypoints_for_selected_fireteams", objective_position))
	controller.call("_set_waypoint_command_for_targets", take_refs, "take")
	var engage_refs: Array = Array(controller.call("create_area_order_for_selected_fireteams_from_world_rect", objective_position + Vector2(-128.0, -128.0), objective_position + Vector2(128.0, -32.0), "engage"))
	var defend_area_refs: Array = Array(controller.call("create_area_order_for_selected_fireteams_from_world_rect", objective_position + Vector2(-96.0, -16.0), objective_position + Vector2(96.0, 96.0), "defend"))
	await _wait_frames(6)

	var planned_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var planned_map: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(move_refs.size() == 1 and defend_refs.size() == 1 and take_refs.size() == 1, "Move, Defend and Take waypoints are authored in one command chain")
	_assert(engage_refs.size() == 1 and defend_area_refs.size() == 1, "Engage and Defend Area orders are authored beside the waypoint chain")
	_assert(int(planned_feedback.get("planned_waypoint_count", 0)) >= 3, "#17/#18 feedback counts the planned waypoint chain")
	_assert(int(planned_feedback.get("planned_area_order_count", 0)) >= 2, "#17/#18 feedback counts the planned Area Orders")
	_assert(int(planned_map.get("waypoint_visual_count", 0)) >= 3, "2.5D map visualizes Move/Defend/Take waypoints")
	_assert(int(planned_map.get("area_order_count", 0)) >= 2, "2.5D map visualizes Engage/Defend Area Orders")
	_assert(Array(planned_map.get("order_selected_fireteam_ids", [])).has("blue"), "2.5D map mirrors selected fireteam ownership")

	var executed: bool = bool(controller.call("execute_selected_fireteam_orders"))
	await _wait_physics_frames(8)
	await _wait_frames(12)
	controller.call("_refresh_order_visuals")
	await _wait_frames(6)
	var movement_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", "blue"))
	var active_map: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var movement_entries: Array = Array(active_map.get("movement_style_entries", []))
	_assert(executed, "GO executes the selected waypoint chain")
	_assert(_movement_state_is_bounding_or_caterpillar(movement_state), "Executed movement uses bounding or caterpillar readability over multiple tiles")
	_assert(_map_has_bounding_or_caterpillar_entry(movement_entries), "2.5D map exposes the same compact movement style entry")
	_assert(int(active_map.get("movement_bound_marker_count", 0)) > 0, "2.5D map exposes bound target markers during movement")
	_assert(_all_map_labels_compact(movement_entries, 18), "Movement labels remain compact on the world overlay")

	var area_attack_started: bool = bool(controller.call("_activate_next_attack_area_order", "blue", 1))
	var area_defend_started: bool = bool(controller.call("_activate_next_defend_area_order", "blue", 1))
	await _wait_frames(6)
	var active_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(area_attack_started or area_defend_started, "At least one Area Order can be activated after the waypoint execution path")
	_assert(int(Array(active_feedback.get("active_area_attack", [])).size() + Array(active_feedback.get("active_area_defense", [])).size()) > 0, "#17/#18 feedback exposes active Area execution state")
	_assert(_command_feedback_is_consistent(active_feedback), "#16/#17/#18 feedback stays short and non-contradictory")


func _run_live_medic_adjacency_case(context: Dictionary) -> void:
	var controller: Node = context["controller"]
	var combat_driver: Node = context["combat_driver"]
	var simulation_root: Node = context["simulation_root"]
	var terrain_registry: Node = context["terrain_registry"]
	var medic = _find_friendly_unit(controller, "unit_bravo")
	var patient = _find_friendly_unit(controller, "unit_hotel")
	_assert(medic != null and patient != null and terrain_registry != null, "Live mission exposes medic and patient candidates for the adjacency case")
	if medic == null or patient == null or terrain_registry == null:
		return

	medic.set("role_name", "Combat Medic")
	medic.set("weapon_1_id", "rifle")
	medic.set("weapon_2_id", "medictool")
	patient.set("weapon_1_id", "smg")
	patient.set("weapon_2_id", "smg")

	var base_grid: Vector2i = _find_walkable_grid_near(terrain_registry, _world_to_grid(terrain_registry, _get_objective_position(simulation_root, (medic as Node2D).global_position)), 6)
	var adjacent_grid: Vector2i = _find_walkable_neighbor_grid(terrain_registry, base_grid)
	var distant_grid: Vector2i = _find_walkable_two_tile_grid(terrain_registry, base_grid)
	_assert(adjacent_grid != base_grid and distant_grid != base_grid, "Medic smoke finds adjacent and two-tile walkable positions")
	if adjacent_grid == base_grid or distant_grid == base_grid:
		return

	_clear_simulation_queues(simulation_root)
	(medic as Node2D).global_position = _grid_to_world(terrain_registry, base_grid)
	(patient as Node2D).global_position = _grid_to_world(terrain_registry, adjacent_grid)
	if patient.has_method("apply_damage") and patient.has_method("get_max_health_points"):
		patient.call("apply_damage", int(patient.call("get_max_health_points")), {"source": "task_192_adjacent"})
	combat_driver.call("_try_enqueue_medic_support_for_units", simulation_root, [medic], [medic, patient], {})
	_assert(_has_heal_effect_for(simulation_root, String(patient.call("get_unit_id"))), "Adjacent wounded ally receives a direct medic heal")
	_assert(_move_command_count_for(simulation_root, String(medic.call("get_unit_id"))) == 0, "Adjacent medic heal does not enqueue a move")

	_clear_simulation_queues(simulation_root)
	for _index in range(16):
		combat_driver.call("_advance_medic_support_cooldowns")
	(patient as Node2D).global_position = _grid_to_world(terrain_registry, distant_grid)
	combat_driver.call("_try_enqueue_medic_support_for_units", simulation_root, [medic], [medic, patient], {})
	_assert(not _has_heal_effect_for(simulation_root, String(patient.call("get_unit_id"))), "Two-tile wounded ally does not receive an instant heal")
	_assert(_move_command_count_for(simulation_root, String(medic.call("get_unit_id"))) == 1, "Two-tile wounded ally triggers a medic move instead")
	if not simulation_root.command_queue.is_empty():
		var command: Dictionary = Dictionary(simulation_root.command_queue[0])
		var target_grid: Vector2i = _world_to_grid(terrain_registry, Vector2(command.get("target_position", Vector2.ZERO)))
		_assert(_grid_distance(target_grid, distant_grid) == 1, "Medic move target is a neighbor tile of the patient")
		_assert(bool(terrain_registry.call("is_walkable", target_grid)), "Medic move target is walkable")
	_clear_simulation_queues(simulation_root)


func _configure_scene_for_blue_drop(scene: Node) -> void:
	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("defer_friendly_runtime_activation", true)
		mission_setup.set("allow_full_roster_when_selection_empty", false)
		mission_setup.set("selected_team_unit_ids", PackedStringArray(BLUE_UNIT_IDS))
		mission_setup.set("selected_team_fireteam_ids", PackedStringArray(["blue", "blue", "blue", "blue"]))
		mission_setup.set(
			"selected_fireteam_definitions",
			[
				{
					"id": "blue",
					"label": "BLUE",
					"lead_unit_id": "unit_alpha",
					"respawn_enabled": false,
					"loadout": "medium",
				}
			]
		)
	var combat_driver := scene.get_node_or_null("CombatLoopDriver")
	if combat_driver != null:
		combat_driver.set("enemy_advance_enabled", false)
		combat_driver.set("enemy_reposition_enabled", false)
		combat_driver.set("base_hit_chance", 0.0)
		combat_driver.set("damage_per_hit", 0)
	var simulation_root := scene.get_node_or_null("SimulationRoot")
	if simulation_root != null:
		simulation_root.set("unit_minimum_spacing_debug_enabled", true)
	var enemy_wave_controller := scene.get_node_or_null("EnemyWaveController")
	if enemy_wave_controller != null:
		enemy_wave_controller.set("wave_count", 2)
		enemy_wave_controller.set("units_per_wave", 1)
		enemy_wave_controller.set("first_wave_delay_seconds", 0.0)
		enemy_wave_controller.set("wave_delay_seconds", 999.0)


func _stage_waiting_dropship(controller: Node) -> void:
	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	planning_state["mission_drop_state"] = "waiting"
	planning_state["mission_drop_craft_id"] = "task_192_dropship"
	planning_state["mission_drop_display_name"] = "TASK 192 Dropship"
	planning_state["mission_drop_title_text"] = "TASK 192 Dropship"
	planning_state["mission_drop_texture_path"] = "res://Assets/kenney_space-kit/Side/craft_speederB.png"
	planning_state["mission_drop_status_line"] = "Holding on mission map"
	planning_state["mission_drop_progress"] = 100.0
	planning_state["mission_drop_passenger_count"] = BLUE_UNIT_IDS.size()
	planning_state["selected_fireteam"] = "BLUE"
	planning_state["selected_fireteams"] = ["blue"]
	planning_state["embarked_unit_ids"] = BLUE_UNIT_IDS
	planning_state["deployed_unit_ids"] = []
	planning_state["drop_ship_requested"] = false
	planning_state["drop_ship_staged"] = false
	planning_state["has_lz_position"] = false
	controller.call("set_planning_state", planning_state)


func _deploy_blue_fireteam(context: Dictionary) -> void:
	var controller: Node = context["controller"]
	var primary_view: Node = context["primary_view"]
	var simulation_root: Node = context["simulation_root"]
	var objective_position: Vector2 = _get_objective_position(simulation_root, Vector2(448.0, 285.0))
	_assert(_place_lz_via_player_path(controller, primary_view, objective_position), "Player LZ path places the smoke LZ through 2.5D picking")
	controller.call("_on_call_dropship_pressed")
	await _wait_frames(2)
	await _drive_drop_until_outbound(controller)
	await _wait_physics_frames(8)
	await _wait_frames(8)
	_assert(String(controller.get("_drop_sequence_phase")) == "outbound", "Dropship deploy reaches outbound phase")


func _place_lz_via_player_path(controller: Node, primary_view: Node, world_position: Vector2) -> bool:
	controller.call("_on_set_lz_pressed")
	var screen_position: Vector2 = primary_view.call("world_to_screen_position", world_position) if primary_view != null and primary_view.has_method("world_to_screen_position") else controller.get_viewport().get_canvas_transform() * world_position
	return bool(controller.call("_place_lz_from_screen_position", screen_position))


func _drive_drop_until_outbound(controller: Node) -> void:
	for _step in range(96):
		controller.call("_update_drop_sequence", 0.25)
		await physics_frame
		await process_frame
		if String(controller.get("_drop_sequence_phase")) == "outbound":
			return


func _audit_presence_phase(context: Dictionary, phase_name: String, expected_active_ids: Array, expected_active_friendly_ids: Array, expected_inactive_enemy_ids: Array) -> void:
	var controller: Node = context["controller"]
	var combat_driver: Node = context["combat_driver"]
	var unit_registry: Node = context["unit_registry"]
	var simulation_root: Node = context["simulation_root"]
	var primary_view: Node = context["primary_view"]
	var expected_active: Array = _sorted_strings(expected_active_ids)
	var registry_ids: Array = _get_registry_unit_ids(unit_registry)
	_assert(_arrays_equal(registry_ids, expected_active), "%s: UnitRegistry contains exactly the active units" % phase_name)

	var tactical_snapshot: Dictionary = Dictionary(controller.call("get_unit_presence_audit_snapshot"))
	_assert(_arrays_equal(Array(tactical_snapshot.get("active_unit_ids", [])), expected_active), "%s: tactical audit mirrors active registry IDs" % phase_name)
	_assert(Array(tactical_snapshot.get("hidden_registered_unit_ids", [])).is_empty(), "%s: no registered unit is hidden on the mission map" % phase_name)
	_assert(_arrays_equal(Array(tactical_snapshot.get("inactive_enemy_unit_ids", [])), expected_inactive_enemy_ids), "%s: inactive enemy waves stay separate" % phase_name)

	var combat_snapshot: Dictionary = Dictionary(combat_driver.call("get_unit_presence_audit_snapshot"))
	_assert(_arrays_equal(Array(combat_snapshot.get("active_friendly_unit_ids", [])), expected_active_friendly_ids), "%s: combat driver active friendlies match deployed friendlies" % phase_name)
	_assert(_arrays_equal(Array(combat_snapshot.get("inactive_enemy_unit_ids", [])), expected_inactive_enemy_ids), "%s: combat driver does not count inactive waves" % phase_name)

	var primary_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(_unit_proxy_ids_are_unique(primary_snapshot), "%s: 2.5D proxy IDs are unique" % phase_name)
	_assert(_arrays_equal(_active_visual_ids(primary_snapshot, expected_active), expected_active), "%s: every active unit has a visible 2.5D proxy or missing-visual diagnostic" % phase_name)
	_assert(_array_intersection(Array(primary_snapshot.get("visible_unit_proxy_ids", [])), expected_inactive_enemy_ids).is_empty(), "%s: inactive enemy waves have no visible proxy" % phase_name)

	var multiplayer_snapshot: Dictionary = Dictionary(simulation_root.call("build_multiplayer_snapshot"))
	_assert(_arrays_equal(_extract_snapshot_unit_ids(Array(multiplayer_snapshot.get("units", []))), expected_active), "%s: multiplayer snapshot mirrors active units" % phase_name)


func _get_context(scene: Node) -> Dictionary:
	var context: Dictionary = {
		"controller": scene.get_node_or_null("TacticalController"),
		"combat_driver": scene.get_node_or_null("CombatLoopDriver"),
		"simulation_root": scene.get_node_or_null("SimulationRoot"),
		"unit_registry": scene.get_node_or_null("UnitRegistry"),
		"ftl_registry": scene.get_node_or_null("FTLRegistry"),
		"terrain_registry": scene.get_node_or_null("TerrainRegistry"),
		"primary_view": scene.get_node_or_null("Primary3DView"),
		"enemy_wave_controller": scene.get_node_or_null("EnemyWaveController"),
	}
	for value in context.values():
		if value == null:
			return {}
	return context


func _set_probe_weapon_loadouts(context: Dictionary) -> void:
	var controller: Node = context["controller"]
	var sniper = _find_friendly_unit(controller, "unit_alpha")
	var rocket = _find_friendly_unit(controller, "unit_delta")
	if sniper != null:
		sniper.set("weapon_1_id", "sniper")
		sniper.set("weapon_2_id", "smg")
	if rocket != null:
		rocket.set("weapon_1_id", "rocket_launcher")
		rocket.set("weapon_2_id", "smg")


func _sync_primary_view_units(context: Dictionary) -> void:
	var primary_view: Node = context["primary_view"]
	var unit_registry: Node = context["unit_registry"]
	if primary_view == null or unit_registry == null or not primary_view.has_method("set_unit_nodes"):
		return
	primary_view.call("set_unit_nodes", Array(unit_registry.call("get_all_units")))


func _find_friendly_unit(controller: Node, unit_id: String):
	for unit in Array(controller.call("_get_all_friendly_units", false)):
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		if String(unit.call("get_unit_id")) == unit_id:
			return unit
	return null


func _force_contact(context: Dictionary) -> void:
	var controller: Node = context["controller"]
	var combat_driver: Node = context["combat_driver"]
	var friendly_units: Array = Array(controller.call("_get_all_friendly_units", false))
	var enemy_units: Array = Array(controller.call("_get_all_enemy_units", false))
	if friendly_units.is_empty() or enemy_units.is_empty():
		return
	var friendly = friendly_units[0]
	var enemy = enemy_units[0]
	if friendly is Node2D and enemy is Node2D:
		(enemy as Node2D).visible = true
		(enemy as Node2D).global_position = (friendly as Node2D).global_position + Vector2(54.0, 0.0)
	combat_driver.call("_update_contact_tracking")
	combat_driver.call("_advance_detection_timers")
	combat_driver.call("_update_contact_tracking")
	controller.call("refresh_contact_overlay")


func _get_objective_position(simulation_root: Node, fallback: Vector2) -> Vector2:
	if simulation_root == null or not simulation_root.has_method("get_objective_status"):
		return fallback
	var objective_status = simulation_root.call("get_objective_status")
	if objective_status == null:
		return fallback
	if typeof(objective_status.get("position")) == TYPE_VECTOR2:
		return Vector2(objective_status.get("position"))
	return fallback


func _weapon_visual_snapshot_is_clean(primary_view: Node) -> bool:
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot")) if primary_view != null else {}
	if int(snapshot.get("unit_visual_loadout_error_count", 0)) > 0:
		return false
	if int(snapshot.get("unit_blaster_error_count", 0)) > 0:
		return false
	return int(snapshot.get("unit_visual_loadout_count", 0)) > 0 and int(snapshot.get("unit_blaster_attachment_count", 0)) > 0


func _movement_state_is_bounding_or_caterpillar(movement_state: Dictionary) -> bool:
	var style_code: String = String(movement_state.get("style_code", "")).strip_edges().to_upper()
	if not ["BND", "CAT"].has(style_code):
		return false
	return bool(movement_state.get("multi_tile_bound", false)) and int(movement_state.get("bound_count", 0)) >= 2


func _map_has_bounding_or_caterpillar_entry(entries: Array) -> bool:
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var style_code: String = String(entry.get("style_code", "")).strip_edges().to_upper()
		if ["BND", "CAT"].has(style_code) and bool(entry.get("multi_tile_bound", false)):
			return true
	return false


func _all_map_labels_compact(entries: Array, max_length: int) -> bool:
	for entry_variant in entries:
		var label_text: String = String(Dictionary(entry_variant).get("map_label_text", "")).strip_edges()
		if label_text.is_empty() or label_text.length() > max_length:
			return false
	return not entries.is_empty()


func _command_feedback_is_consistent(feedback: Dictionary) -> bool:
	var selected_order_text: String = String(feedback.get("selected_order_text", ""))
	var selected_status_text: String = String(feedback.get("selected_status_text", ""))
	var mission_control_text: String = String(feedback.get("mission_control_status_text", ""))
	var buttons: Dictionary = Dictionary(feedback.get("command_buttons", {}))
	for command_id in ["move", "defend", "take"]:
		if not bool(Dictionary(buttons.get(command_id, {})).get("exists", false)):
			return false
	if selected_order_text.contains("Debug") or selected_status_text.contains("Debug") or mission_control_text.contains("Debug"):
		return false
	return selected_order_text.length() <= 180 and selected_status_text.length() <= 260 and mission_control_text.length() <= 260


func _multiplayer_snapshot_matches_registry(simulation_root: Node, unit_registry: Node) -> bool:
	if simulation_root == null or unit_registry == null:
		return false
	var snapshot: Dictionary = Dictionary(simulation_root.call("build_multiplayer_snapshot"))
	return _arrays_equal(_extract_snapshot_unit_ids(Array(snapshot.get("units", []))), _get_registry_unit_ids(unit_registry))


func _legacy_readability_overlays_are_hidden(scene: Node) -> bool:
	for node_path in ["StatusLabel", "CombatContactLine", "CombatEventLabel", "CombatWinnerLabel", "WaveStatusLabel"]:
		var node := scene.get_node_or_null(node_path)
		if node is CanvasItem and (node as CanvasItem).visible:
			return false
	var objective_label := scene.get_node_or_null("ObjectiveStatusView/ObjectiveStatusLabel") as CanvasItem
	return objective_label == null or not objective_label.visible


func _primary_dropship_visible(primary_view: Node) -> bool:
	if primary_view == null or not primary_view.has_method("get_render_snapshot"):
		return false
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	return bool(snapshot.get("dropship_model_visible", false)) or bool(snapshot.get("dropship_texture_visible", false))


func _clear_simulation_queues(simulation_root: Node) -> void:
	if simulation_root == null:
		return
	if simulation_root.command_queue is Array:
		simulation_root.command_queue.clear()
	if simulation_root.effects_queue is Array:
		simulation_root.effects_queue.clear()


func _has_heal_effect_for(simulation_root: Node, unit_id: String) -> bool:
	for effect_variant in simulation_root.effects_queue:
		var effect: Dictionary = Dictionary(effect_variant)
		if String(effect.get("effect_type", "")) == "heal" and String(effect.get("unit_id", "")) == unit_id:
			return true
	return false


func _move_command_count_for(simulation_root: Node, unit_id: String) -> int:
	var count: int = 0
	for command_variant in simulation_root.command_queue:
		var command: Dictionary = Dictionary(command_variant)
		if String(command.get("command_type", "")) == "move_to_position" and String(command.get("unit_id", "")) == unit_id:
			count += 1
	return count


func _find_walkable_grid_near(terrain_registry: Node, origin_grid: Vector2i, max_radius: int) -> Vector2i:
	for radius in range(0, maxi(max_radius, 0) + 1):
		for x in range(origin_grid.x - radius, origin_grid.x + radius + 1):
			for y in range(origin_grid.y - radius, origin_grid.y + radius + 1):
				var grid := Vector2i(x, y)
				if bool(terrain_registry.call("is_walkable", grid)):
					return grid
	return origin_grid


func _find_walkable_neighbor_grid(terrain_registry: Node, base_grid: Vector2i) -> Vector2i:
	for direction in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var grid: Vector2i = base_grid + direction
		if bool(terrain_registry.call("is_walkable", grid)):
			return grid
	return base_grid


func _find_walkable_two_tile_grid(terrain_registry: Node, base_grid: Vector2i) -> Vector2i:
	for direction in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var neighbor_grid: Vector2i = base_grid + direction
		var distant_grid: Vector2i = base_grid + direction * 2
		if bool(terrain_registry.call("is_walkable", neighbor_grid)) and bool(terrain_registry.call("is_walkable", distant_grid)):
			return distant_grid
	return base_grid


func _grid_to_world(terrain_registry: Node, grid_position: Vector2i) -> Vector2:
	if terrain_registry == null or not terrain_registry.has_method("grid_to_world"):
		return Vector2.ZERO
	return Vector2(terrain_registry.call("grid_to_world", grid_position))


func _world_to_grid(terrain_registry: Node, world_position: Vector2) -> Vector2i:
	if terrain_registry == null or not terrain_registry.has_method("world_to_grid"):
		return Vector2i.ZERO
	return Vector2i(terrain_registry.call("world_to_grid", world_position))


func _grid_distance(a: Vector2i, b: Vector2i) -> int:
	var delta: Vector2i = a - b
	return absi(delta.x) + absi(delta.y)


func _all_registered_units_keep_spacing(unit_registry: Node, minimum_distance: float) -> bool:
	for pair in _registered_unit_pairs(unit_registry):
		var unit_a := pair[0] as Node2D
		var unit_b := pair[1] as Node2D
		if unit_a == null or unit_b == null:
			continue
		if unit_a.global_position.distance_to(unit_b.global_position) < minimum_distance - 0.01:
			return false
	return true


func _registered_unit_pairs(unit_registry: Node) -> Array:
	var pairs: Array = []
	if unit_registry == null:
		return pairs
	var units: Array = Array(unit_registry.call("get_all_units"))
	for index_a in range(units.size()):
		for index_b in range(index_a + 1, units.size()):
			pairs.append([units[index_a], units[index_b]])
	return pairs


func _get_registry_unit_ids(unit_registry: Node) -> Array:
	var unit_ids: Array = []
	if unit_registry == null:
		return unit_ids
	for unit in Array(unit_registry.call("get_all_units")):
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
		if not unit_id.is_empty():
			unit_ids.append(unit_id)
	unit_ids.sort()
	return unit_ids


func _active_visual_ids(primary_snapshot: Dictionary, expected_active: Array) -> Array:
	var visual_ids: Array = _array_union(Array(primary_snapshot.get("visible_unit_proxy_ids", [])), Array(primary_snapshot.get("missing_unit_model_ids", [])))
	return _array_intersection(visual_ids, expected_active)


func _unit_proxy_ids_are_unique(primary_snapshot: Dictionary) -> bool:
	var proxy_ids: Array = Array(primary_snapshot.get("unit_proxy_ids", []))
	return proxy_ids.size() == _unique_strings(proxy_ids).size()


func _extract_snapshot_unit_ids(entries: Array) -> Array:
	var unit_ids: Array = []
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var unit_id: String = String(Dictionary(entry_variant).get("unit_id", "")).strip_edges()
		if not unit_id.is_empty():
			unit_ids.append(unit_id)
	unit_ids.sort()
	return unit_ids


func _array_union(a: Array, b: Array) -> Array:
	var result: Array = _sorted_strings(a)
	for value in b:
		var item: String = String(value).strip_edges()
		if not item.is_empty() and not result.has(item):
			result.append(item)
	result.sort()
	return result


func _array_intersection(a: Array, b: Array) -> Array:
	var b_lookup: Dictionary = {}
	for value in b:
		var item: String = String(value).strip_edges()
		if not item.is_empty():
			b_lookup[item] = true
	var result: Array = []
	for value in a:
		var item: String = String(value).strip_edges()
		if not item.is_empty() and b_lookup.has(item):
			result.append(item)
	result.sort()
	return result


func _unique_strings(values: Array) -> Array:
	var lookup: Dictionary = {}
	for value in values:
		var item: String = String(value).strip_edges()
		if not item.is_empty():
			lookup[item] = true
	var result: Array = lookup.keys()
	result.sort()
	return result


func _sorted_strings(values: Array) -> Array:
	var result: Array = []
	for value in values:
		var item: String = String(value).strip_edges()
		if not item.is_empty():
			result.append(item)
	result.sort()
	return result


func _arrays_equal(a: Array, b: Array) -> bool:
	var left: Array = _sorted_strings(a)
	var right: Array = _sorted_strings(b)
	if left.size() != right.size():
		return false
	for index in range(left.size()):
		if String(left[index]) != String(right[index]):
			return false
	return true


func _wait_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await process_frame


func _wait_physics_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await physics_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
