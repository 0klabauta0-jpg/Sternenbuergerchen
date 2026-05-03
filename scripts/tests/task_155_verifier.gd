extends SceneTree

const MISSION_SCENE_PATH: String = "res://scenes/tests/mission_reactivity_test.tscn"
const PRESET_LOADER_SCRIPT: GDScript = preload("res://scripts/tests/mission_preset_loader.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_155 Tactical Mission Test Presets Verifier ===")
	_test_required_presets_parse_and_validate()
	await _test_live_mission_presets()
	await _test_attack_area_preset_is_reproducible()
	await _test_patrol_preset_transitions_on_contact()
	await _test_dropship_preset_has_no_lz()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_required_presets_parse_and_validate() -> void:
	var required_ids: PackedStringArray = PRESET_LOADER_SCRIPT.get_required_preset_ids()
	_assert(required_ids.size() == 5, "Preset library exposes all five TASK_155 preset ids")
	for preset_id in required_ids:
		var preset: Dictionary = PRESET_LOADER_SCRIPT.load_preset(String(preset_id))
		var validation: Dictionary = PRESET_LOADER_SCRIPT.validate_preset(preset)
		_assert(bool(validation.get("valid", false)), "Preset %s parses, validates and references an existing map" % String(preset_id))


func _test_live_mission_presets() -> void:
	var loaded_count: int = 0
	for preset_id in PRESET_LOADER_SCRIPT.get_required_preset_ids():
		var context: Dictionary = await _load_scene_for_preset(String(preset_id))
		var scene: Node = context.get("scene", null)
		var preset: Dictionary = Dictionary(context.get("preset", {}))
		if scene == null:
			continue

		var mission_setup := scene.get_node_or_null("MissionSetup")
		_assert(mission_setup != null and String(mission_setup.get("map_file_path")) == String(preset.get("map_file_path", "")), "%s applies its map to MissionTestSetup" % String(preset_id))
		_assert(_objective_is_visible(scene, Dictionary(preset.get("objective", {}))), "%s exposes the referenced objective in the live mission" % String(preset_id))
		_assert(_enemy_setup_is_visible(scene, Array(preset.get("enemy_setup", []))), "%s exposes configured enemy setup in the live mission" % String(preset_id))
		_assert(_patrol_paths_are_loaded(scene, Dictionary(preset.get("patrol_paths", {}))), "%s injects deterministic patrol paths" % String(preset_id))
		_assert(_scene_has_no_player_lz(scene), "%s starts without automatic player LZ" % String(preset_id))
		loaded_count += 1
		scene.queue_free()
		await process_frame

	_assert(loaded_count >= 3, "At least three tactical presets load through the live mission scene")


func _test_attack_area_preset_is_reproducible() -> void:
	var context: Dictionary = await _load_scene_for_preset("attack_area_two_contacts")
	var scene: Node = context.get("scene", null)
	var preset: Dictionary = Dictionary(context.get("preset", {}))
	if scene == null:
		_assert(false, "Attack Area preset scene loads")
		return

	var controller = scene.get_node_or_null("TacticalController")
	var area_test: Dictionary = Dictionary(preset.get("area_order_test", {}))
	var start_position: Vector2 = _coerce_vector2(area_test.get("start_world_position", {}), Vector2.ZERO)
	var end_position: Vector2 = _coerce_vector2(area_test.get("end_world_position", {}), Vector2.ZERO)
	var command_type: String = String(area_test.get("command_type", "engage"))
	if controller != null:
		controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
		var area_refs: Array = controller.call("create_area_order_for_selected_fireteams_from_world_rect", start_position, end_position, command_type)
		var visualized_area_orders: Array = controller.call("get_visualized_area_orders_snapshot")
		_assert(area_refs.size() == 1 and visualized_area_orders.size() == 1, "Attack Area preset creates a reproducible live Area Order")
	else:
		_assert(false, "Attack Area preset has TacticalController")
	_assert(_count_enemies_inside_rect(scene, Array(preset.get("enemy_setup", [])), start_position, end_position) >= 2, "Attack Area preset places two contacts inside the target area")
	scene.queue_free()
	await process_frame


func _test_patrol_preset_transitions_on_contact() -> void:
	var context: Dictionary = await _load_scene_for_preset("patrol_contact_transition")
	var scene: Node = context.get("scene", null)
	if scene == null:
		_assert(false, "Patrol preset scene loads")
		return

	var simulation_root := scene.get_node_or_null("SimulationRoot")
	var combat_loop := scene.get_node_or_null("CombatLoopDriver")
	var enemy := scene.get_node_or_null("EnemyDelta") as Node2D
	var friendly := scene.get_node_or_null("UnitAlpha") as Node2D
	if combat_loop != null and combat_loop.has_method("_initialize_enemy_patrol_paths"):
		combat_loop.call("_initialize_enemy_patrol_paths")
	if simulation_root != null and combat_loop != null and enemy != null and friendly != null and combat_loop.has_method("_try_enqueue_enemy_patrol_move"):
		friendly.global_position = enemy.global_position + Vector2(-600.0, 480.0)
		var patrol_started: bool = bool(combat_loop.call("_try_enqueue_enemy_patrol_move", simulation_root, enemy))
		friendly.global_position = enemy.global_position + Vector2(8.0, 0.0)
		var patrol_after_contact: bool = bool(combat_loop.call("_try_enqueue_enemy_patrol_move", simulation_root, enemy))
		_assert(patrol_started and not patrol_after_contact, "Patrol preset advances before contact and stops when contact conditions are present")
	else:
		_assert(false, "Patrol preset has combat loop, simulation root and test units")
	scene.queue_free()
	await process_frame


func _test_dropship_preset_has_no_lz() -> void:
	var context: Dictionary = await _load_scene_for_preset("dropship_insertion_first_contact")
	var scene: Node = context.get("scene", null)
	var preset: Dictionary = Dictionary(context.get("preset", {}))
	if scene == null:
		_assert(false, "Dropship preset scene loads")
		return

	var validation: Dictionary = PRESET_LOADER_SCRIPT.validate_preset(preset)
	var planning_state: Dictionary = _get_planning_state(scene)
	_assert(bool(validation.get("valid", false)) and not bool(planning_state.get("has_lz_position", false)), "Dropship preset is valid and has no stored player LZ")
	_assert(not bool(planning_state.get("drop_ship_requested", false)), "Dropship preset does not auto-call the dropship")
	scene.queue_free()
	await process_frame


func _load_scene_for_preset(preset_id: String) -> Dictionary:
	var preset: Dictionary = PRESET_LOADER_SCRIPT.load_preset(preset_id)
	var scene: Node = load(MISSION_SCENE_PATH).instantiate()
	var prepare_result: Dictionary = PRESET_LOADER_SCRIPT.prepare_scene(scene, preset)
	_assert(bool(prepare_result.get("valid", false)), "Preset %s prepares the mission scene" % preset_id)
	root.add_child(scene)
	for _index in range(10):
		await process_frame
	var apply_result: Dictionary = PRESET_LOADER_SCRIPT.apply_runtime(scene, preset)
	_assert(bool(apply_result.get("valid", false)), "Preset %s applies runtime enemy and patrol setup" % preset_id)
	return {
		"preset": preset,
		"scene": scene,
	}


func _objective_is_visible(scene: Node, objective: Dictionary) -> bool:
	var marker_id: String = String(objective.get("marker_id", "")).strip_edges()
	if marker_id.is_empty():
		return false
	var objective_marker := scene.get_node_or_null(NodePath("MapRoot/%s" % marker_id)) as Node2D
	var target_marker := scene.get_node_or_null("TargetMarker") as Node2D
	return objective_marker != null and target_marker != null and target_marker.global_position.distance_to(objective_marker.global_position) <= 0.5


func _enemy_setup_is_visible(scene: Node, enemy_setup: Array) -> bool:
	if enemy_setup.is_empty():
		return false
	for enemy_variant in enemy_setup:
		var enemy_entry: Dictionary = Dictionary(enemy_variant)
		var enemy_node := scene.get_node_or_null(NodePath(String(enemy_entry.get("node_path", ""))))
		if enemy_node == null or not (enemy_node is Node2D):
			return false
		if enemy_node is CanvasItem and not (enemy_node as CanvasItem).visible:
			return false
		if enemy_entry.has("world_position"):
			var expected_position: Vector2 = _coerce_vector2(enemy_entry.get("world_position", {}), Vector2.ZERO)
			if (enemy_node as Node2D).global_position.distance_to(expected_position) > 0.5:
				return false
	return true


func _patrol_paths_are_loaded(scene: Node, patrol_paths: Dictionary) -> bool:
	var wave_controller := scene.get_node_or_null("EnemyWaveController")
	if wave_controller == null or not wave_controller.has_method("get_patrol_path_for_unit"):
		return false
	for unit_id_variant in patrol_paths.keys():
		var unit_id: String = String(unit_id_variant).strip_edges()
		var expected_points: Array = Array(patrol_paths.get(unit_id_variant, []))
		var loaded_points: Array = Array(wave_controller.call("get_patrol_path_for_unit", unit_id))
		if loaded_points.size() != expected_points.size():
			return false
		if not loaded_points.is_empty():
			var expected_first: Vector2 = _coerce_vector2(expected_points[0], Vector2.ZERO)
			var loaded_first: Vector2 = _coerce_vector2(loaded_points[0], Vector2.ZERO)
			if loaded_first.distance_to(expected_first) > 0.5:
				return false
	return true


func _scene_has_no_player_lz(scene: Node) -> bool:
	var lz_marker := scene.get_node_or_null("LZMarker") as CanvasItem
	var dropship_marker := scene.get_node_or_null("DropshipPlanMarker") as CanvasItem
	var planning_state: Dictionary = _get_planning_state(scene)
	if bool(planning_state.get("has_lz_position", false)):
		return false
	if lz_marker != null and lz_marker.visible:
		return false
	if dropship_marker != null and dropship_marker.visible:
		return false
	return true


func _get_planning_state(scene: Node) -> Dictionary:
	var controller := scene.get_node_or_null("TacticalController")
	if controller == null or not controller.has_method("get_planning_state"):
		return {}
	return Dictionary(controller.call("get_planning_state"))


func _count_enemies_inside_rect(scene: Node, enemy_setup: Array, start_position: Vector2, end_position: Vector2) -> int:
	var rect := Rect2(
		Vector2(minf(start_position.x, end_position.x), minf(start_position.y, end_position.y)),
		Vector2(absf(end_position.x - start_position.x), absf(end_position.y - start_position.y))
	)
	var count: int = 0
	for enemy_variant in enemy_setup:
		var enemy_entry: Dictionary = Dictionary(enemy_variant)
		var enemy_node := scene.get_node_or_null(NodePath(String(enemy_entry.get("node_path", "")))) as Node2D
		if enemy_node != null and rect.has_point(enemy_node.global_position):
			count += 1
	return count


func _coerce_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Vector2i:
		return Vector2(value.x, value.y)
	if typeof(value) == TYPE_DICTIONARY:
		var value_dict: Dictionary = value
		return Vector2(float(value_dict.get("x", fallback.x)), float(value_dict.get("y", fallback.y)))
	return fallback


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
