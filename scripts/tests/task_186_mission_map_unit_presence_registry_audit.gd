extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const BLUE_UNIT_IDS: Array = ["unit_alpha", "unit_bravo", "unit_delta", "unit_hotel"]
const INITIAL_ACTIVE_ENEMY_IDS: Array = ["enemy_delta"]
const SECOND_WAVE_ENEMY_IDS: Array = ["enemy_echo"]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_186 Mission Map Unit Presence Registry Audit ===")
	await _test_spawn_deploy_enemy_wave_and_proxy_presence()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_spawn_deploy_enemy_wave_and_proxy_presence() -> void:
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene_for_blue_drop(scene)
	_stage_waiting_dropship(scene.get_node("TacticalController"))
	root.add_child(scene)
	await _wait_frames(24)
	await _wait_physics_frames(4)

	var context: Dictionary = _get_context(scene)
	_assert(not context.is_empty(), "Mission exposes setup, controller, combat, registry, SimulationRoot, FTLRegistry and Primary3DView")
	if context.is_empty():
		scene.queue_free()
		await _wait_frames(2)
		return

	var mission_setup: Node = context["mission_setup"]
	var setup_snapshot: Dictionary = Dictionary(mission_setup.call("get_expected_unit_presence_snapshot"))
	_assert(_arrays_equal(Array(setup_snapshot.get("friendly_unit_ids", [])), BLUE_UNIT_IDS), "Mission setup exposes the selected blue friendly IDs as expected units")
	_assert(_arrays_equal(Array(setup_snapshot.get("enemy_unit_ids", [])), INITIAL_ACTIVE_ENEMY_IDS + SECOND_WAVE_ENEMY_IDS), "Mission setup exposes both authored enemy IDs")

	await _audit_presence_phase(scene, "initial spawn", INITIAL_ACTIVE_ENEMY_IDS, [], SECOND_WAVE_ENEMY_IDS)

	await _deploy_blue_fireteam(context)
	var active_after_drop: Array = BLUE_UNIT_IDS + INITIAL_ACTIVE_ENEMY_IDS
	await _audit_presence_phase(scene, "after dropship deploy", active_after_drop, BLUE_UNIT_IDS, SECOND_WAVE_ENEMY_IDS)
	var ftl_registry: Node = context["ftl_registry"]
	_assert(bool(ftl_registry.call("has_ftl", "team_alpha")), "Dropship deploy registers team_alpha in FTLRegistry")

	var enemy_wave_controller: Node = context["enemy_wave_controller"]
	enemy_wave_controller.call("_start_next_wave")
	await _wait_frames(12)
	await _wait_physics_frames(4)
	_assert(int(enemy_wave_controller.call("get_current_wave_number")) == 2, "Enemy wave controller can start the second authored wave")
	await _audit_presence_phase(scene, "after enemy wave start", active_after_drop + SECOND_WAVE_ENEMY_IDS, BLUE_UNIT_IDS, [])

	scene.queue_free()
	await _wait_frames(2)


func _audit_presence_phase(scene: Node, phase_name: String, expected_active_ids: Array, expected_active_friendly_ids: Array, expected_inactive_enemy_ids: Array) -> void:
	await _wait_frames(8)
	var context: Dictionary = _get_context(scene)
	if context.is_empty():
		_assert(false, "%s audit has mission context" % phase_name)
		return
	var unit_registry: Node = context["unit_registry"]
	var controller: Node = context["controller"]
	var combat_driver: Node = context["combat_driver"]
	var simulation_root: Node = context["simulation_root"]
	var primary_view: Node = context["primary_view"]

	var expected_active: Array = _sorted_strings(expected_active_ids)
	var registry_ids: Array = _get_registry_unit_ids(unit_registry)
	_assert(_arrays_equal(registry_ids, expected_active), "%s: UnitRegistry contains exactly the active units" % phase_name)

	var tactical_snapshot: Dictionary = Dictionary(controller.call("get_unit_presence_audit_snapshot"))
	_assert(_arrays_equal(Array(tactical_snapshot.get("active_unit_ids", [])), expected_active), "%s: tactical audit snapshot mirrors active registry IDs" % phase_name)
	_assert(Array(tactical_snapshot.get("hidden_registered_unit_ids", [])).is_empty(), "%s: no registered unit is hidden on the mission map" % phase_name)
	_assert(_arrays_equal(Array(tactical_snapshot.get("inactive_enemy_unit_ids", [])), expected_inactive_enemy_ids), "%s: inactive enemy waves stay separate from active units" % phase_name)

	var combat_snapshot: Dictionary = Dictionary(combat_driver.call("get_unit_presence_audit_snapshot"))
	_assert(_arrays_equal(Array(combat_snapshot.get("active_enemy_unit_ids", [])), _filter_enemy_ids(expected_active)), "%s: combat driver active enemy IDs match active enemy registry IDs" % phase_name)
	_assert(_arrays_equal(Array(combat_snapshot.get("active_friendly_unit_ids", [])), expected_active_friendly_ids), "%s: combat driver active friendly IDs match deployed friendlies" % phase_name)
	_assert(_arrays_equal(Array(combat_snapshot.get("inactive_enemy_unit_ids", [])), expected_inactive_enemy_ids), "%s: combat driver does not count inactive enemy waves" % phase_name)

	var primary_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(_unit_proxy_ids_are_unique(primary_snapshot), "%s: 2.5D unit proxy IDs are unique" % phase_name)
	_assert(int(primary_snapshot.get("unit_proxy_count", 0)) == Array(primary_snapshot.get("unit_proxy_ids", [])).size(), "%s: 2.5D proxy count matches proxy ID diagnostics" % phase_name)
	_assert(_arrays_equal(_active_visual_ids(primary_snapshot, expected_active), expected_active), "%s: every active unit has a visible 2.5D proxy or missing-visual diagnostic" % phase_name)
	_assert(_array_intersection(Array(primary_snapshot.get("visible_unit_proxy_ids", [])), expected_inactive_enemy_ids).is_empty(), "%s: inactive enemy waves have no visible 2.5D proxy" % phase_name)

	var multiplayer_snapshot: Dictionary = Dictionary(simulation_root.call("build_multiplayer_snapshot"))
	var multiplayer_units: Array = Array(multiplayer_snapshot.get("units", []))
	_assert(_arrays_equal(_extract_snapshot_unit_ids(multiplayer_units), expected_active), "%s: multiplayer snapshot mirrors active UnitRegistry IDs" % phase_name)
	_assert(_multiplayer_snapshot_matches_local_state(multiplayer_units, tactical_snapshot, expected_active), "%s: multiplayer snapshot matches local team and vital state" % phase_name)


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
	var enemy_wave_controller := scene.get_node_or_null("EnemyWaveController")
	if enemy_wave_controller != null:
		enemy_wave_controller.set("wave_count", 2)
		enemy_wave_controller.set("units_per_wave", 1)
		enemy_wave_controller.set("first_wave_delay_seconds", 0.0)
		enemy_wave_controller.set("wave_delay_seconds", 999.0)


func _stage_waiting_dropship(controller: Node) -> void:
	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	planning_state["mission_drop_state"] = "waiting"
	planning_state["mission_drop_craft_id"] = "task_186_dropship"
	planning_state["mission_drop_display_name"] = "TASK 186 Dropship"
	planning_state["mission_drop_title_text"] = "TASK 186 Dropship"
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
	_assert(_place_lz_via_player_path(controller, primary_view, objective_position), "Player LZ path places the audit LZ through 2.5D picking")
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


func _get_context(scene: Node) -> Dictionary:
	var context: Dictionary = {
		"mission_setup": scene.get_node_or_null("MissionSetup"),
		"controller": scene.get_node_or_null("TacticalController"),
		"combat_driver": scene.get_node_or_null("CombatLoopDriver"),
		"simulation_root": scene.get_node_or_null("SimulationRoot"),
		"unit_registry": scene.get_node_or_null("UnitRegistry"),
		"ftl_registry": scene.get_node_or_null("FTLRegistry"),
		"primary_view": scene.get_node_or_null("Primary3DView"),
		"enemy_wave_controller": scene.get_node_or_null("EnemyWaveController"),
	}
	for value in context.values():
		if value == null:
			return {}
	return context


func _get_registry_unit_ids(unit_registry: Node) -> Array:
	var unit_ids: Array = []
	if unit_registry == null or not unit_registry.has_method("get_all_units"):
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


func _multiplayer_snapshot_matches_local_state(multiplayer_units: Array, tactical_snapshot: Dictionary, expected_active: Array) -> bool:
	var multiplayer_by_id: Dictionary = _entry_by_unit_id(multiplayer_units)
	var local_entries: Array = Array(tactical_snapshot.get("friendly_units", [])) + Array(tactical_snapshot.get("enemy_units", []))
	var local_by_id: Dictionary = _entry_by_unit_id(local_entries)
	for unit_id_variant in expected_active:
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty() or not multiplayer_by_id.has(unit_id) or not local_by_id.has(unit_id):
			return false
		var multiplayer_entry: Dictionary = Dictionary(multiplayer_by_id[unit_id])
		var local_entry: Dictionary = Dictionary(local_by_id[unit_id])
		if String(multiplayer_entry.get("team_id", "")) != String(local_entry.get("team_id", "")):
			return false
		if String(multiplayer_entry.get("vital_state", "")) != String(local_entry.get("vital_state", "")):
			return false
	return true


func _entry_by_unit_id(entries: Array) -> Dictionary:
	var result: Dictionary = {}
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var unit_id: String = String(entry.get("unit_id", "")).strip_edges()
		if not unit_id.is_empty():
			result[unit_id] = entry
	return result


func _filter_enemy_ids(unit_ids: Array) -> Array:
	var result: Array = []
	for unit_id_variant in unit_ids:
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.begins_with("enemy_"):
			result.append(unit_id)
	result.sort()
	return result


func _get_objective_position(simulation_root: Node, fallback: Vector2) -> Vector2:
	if simulation_root == null or not simulation_root.has_method("get_objective_status"):
		return fallback
	var objective_status = simulation_root.call("get_objective_status")
	if objective_status == null:
		return fallback
	return Vector2(objective_status.position)


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
	for _index in range(count):
		await process_frame


func _wait_physics_frames(count: int) -> void:
	for _index in range(count):
		await physics_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
