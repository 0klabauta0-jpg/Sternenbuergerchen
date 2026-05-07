extends SceneTree

const FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const FIRETEAM_BEHAVIOR_PROFILE_SCRIPT: GDScript = preload("res://scripts/command/fireteam_behavior_profile.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


class SimulationStub:
	extends RefCounted
	var commands: Array = []

	func enqueue_command(command_dict: Dictionary) -> void:
		var command_token: String = String(command_dict.get("command_token", "")).strip_edges()
		if not command_token.is_empty():
			for index in range(commands.size()):
				if String(Dictionary(commands[index]).get("command_token", "")).strip_edges() == command_token:
					commands[index] = command_dict.duplicate(true)
					return
		commands.append(command_dict.duplicate(true))


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_188 Fireteam Advance Styles Map Readability ===")
	_test_controller_snapshots_distinguish_all_advance_styles()
	await _test_primary_map_snapshot_mirrors_advance_styles()
	await _test_scene_selected_fireteam_status_matches_map_phase()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_controller_snapshots_distinguish_all_advance_styles() -> void:
	var rush_context: Dictionary = _start_style_context("rush_case", "rush")
	var rush_state: Dictionary = Dictionary(rush_context.get("state", {}))
	_assert(String(rush_state.get("style_code", "")) == "RSH", "Rush snapshot exposes a distinct RSH style code")
	_assert(PackedStringArray(rush_state.get("moving_unit_ids", PackedStringArray())).size() == 4, "Rush snapshot marks all fit members as moving")
	_assert(PackedStringArray(rush_state.get("covering_unit_ids", PackedStringArray())).is_empty(), "Rush snapshot has no covering group")
	_assert(String(rush_state.get("readability_status_line", "")).begins_with("RSH"), "Rush #17 status line starts with the same style code")
	_cleanup_units(Array(rush_context.get("units", [])))

	var bounding_context: Dictionary = _start_style_context("bound_case", "bounding")
	var bounding_state: Dictionary = Dictionary(bounding_context.get("state", {}))
	_assert(String(bounding_state.get("style_code", "")) == "BND", "Bounding snapshot exposes a distinct BND style code")
	_assert(PackedStringArray(bounding_state.get("moving_unit_ids", PackedStringArray())).size() > 0, "Bounding snapshot marks a movement group")
	_assert(PackedStringArray(bounding_state.get("covering_unit_ids", PackedStringArray())).size() > 0, "Bounding snapshot marks a covering group")
	_assert(int(bounding_state.get("group_count", 0)) >= 2, "Bounding snapshot exposes movement/cover group progress")
	_assert(int(bounding_state.get("bound_count", 0)) >= 2, "Bounding snapshot exposes a multi-bound route")
	_assert(bool(bounding_state.get("multi_tile_bound", false)), "Bounding current bound target spans multiple tiles")
	_cleanup_units(Array(bounding_context.get("units", [])))

	var caterpillar_context: Dictionary = _start_style_context("cat_case", "creep")
	var caterpillar_state: Dictionary = Dictionary(caterpillar_context.get("state", {}))
	_assert(String(caterpillar_state.get("style_code", "")) == "CAT", "Caterpillar snapshot exposes a distinct CAT style code")
	_assert(String(caterpillar_state.get("effective_style", "")) == "caterpillar", "Creep profiles normalize to the caterpillar execution style")
	_assert(PackedStringArray(caterpillar_state.get("moving_unit_ids", PackedStringArray())).size() == 1, "Caterpillar snapshot marks exactly one moving member")
	_assert(PackedStringArray(caterpillar_state.get("covering_unit_ids", PackedStringArray())).size() == 3, "Caterpillar snapshot marks the rest as covering")
	_assert(PackedStringArray(caterpillar_state.get("movement_sequence", PackedStringArray())).size() == 4, "Caterpillar snapshot exposes the full member sequence")
	_assert(int(caterpillar_state.get("bound_count", 0)) >= 2, "Caterpillar snapshot exposes a multi-bound route")
	_assert(bool(caterpillar_state.get("multi_tile_bound", false)), "Caterpillar current bound target spans multiple tiles")
	_cleanup_units(Array(caterpillar_context.get("units", [])))


func _test_primary_map_snapshot_mirrors_advance_styles() -> void:
	var contexts: Array = [
		_start_style_context("map_rush", "rush"),
		_start_style_context("map_bound", "bounding"),
		_start_style_context("map_cat", "creep"),
	]
	var movement_states: Array = []
	for context_variant in contexts:
		movement_states.append(Dictionary(Dictionary(context_variant).get("state", {})))

	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task188_readability", Vector2i(9, 9), Vector2.ZERO, 64.0, 32.0, 3)
	var center_tile = map_data.call("get_tile_at_grid", Vector2i(4, 4))
	var center_position: Vector2 = Vector2(center_tile.world_position) if center_tile != null else Vector2(0.0, 256.0)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	primary_view.call("set_order_visual_payload", {
		"phase_index": 1,
		"movement_state_dicts": movement_states,
		"area_order_dicts": [{
			"area_order_id": "task188_area",
			"command_type": "defend",
			"center_position": center_position,
			"tile_world_positions": [center_position],
		}],
	})
	await _wait_frames(8)

	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var entries: Array = Array(snapshot.get("movement_style_entries", []))
	_assert(int(snapshot.get("movement_style_visual_count", 0)) == 3, "Mission map snapshot distinguishes all three active movement styles")
	_assert(int(snapshot.get("movement_bound_marker_count", 0)) >= 3, "Mission map snapshot exposes bound target markers")
	_assert(int(snapshot.get("movement_group_marker_count", 0)) >= 8, "Mission map snapshot exposes moving and covering group markers")
	_assert(_has_style_entry(entries, "RSH"), "Mission map snapshot includes rush readability entry")
	_assert(_has_style_entry(entries, "BND"), "Mission map snapshot includes bounding readability entry")
	_assert(_has_style_entry(entries, "CAT"), "Mission map snapshot includes caterpillar readability entry")
	_assert(_style_entry_has_multitile_bound(entries, "BND"), "Bounding map entry marks a multi-tile bound")
	_assert(_style_entry_has_single_mover(entries, "CAT"), "Caterpillar map entry keeps exactly one moving member")
	_assert(int(snapshot.get("area_order_tile_marker_count", 0)) == 1, "Movement readability does not suppress Area Order tile markers")
	_assert(_all_map_labels_compact(entries, 18), "Mission map movement labels stay compact instead of using long #17 text")

	primary_view.queue_free()
	await _wait_frames(2)
	for context_variant in contexts:
		_cleanup_units(Array(Dictionary(context_variant).get("units", [])))


func _test_scene_selected_fireteam_status_matches_map_phase() -> void:
	var scene = load("res://scenes/tests/mission_reactivity_test.tscn").instantiate()
	root.add_child(scene)
	await _wait_frames(10)
	var controller: Node = scene.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("_create_waypoints_for_selected_fireteams", Vector2(0.0, 384.0))
	var started: bool = bool(controller.call("advance_to_next_phase"))
	await _wait_frames(2)
	var movement_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", "blue"))
	var status_line: String = String(controller.call("_format_movement_state_text", movement_state))
	controller.call("_refresh_order_visuals")
	await _wait_frames(6)
	var primary_view: Node = scene.get_node_or_null("Primary3DView")
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot")) if primary_view != null and primary_view.has_method("get_render_snapshot") else {}
	var entries: Array = Array(snapshot.get("movement_style_entries", []))
	var style_code: String = String(movement_state.get("style_code", ""))
	_assert(started, "Scene starts planned movement execution for selected fireteam")
	_assert(not movement_state.is_empty() and not style_code.is_empty(), "Scene exposes movement readability state")
	_assert(status_line == String(movement_state.get("readability_status_line", "")), "#17 Selected Fireteam uses the controller readability status line")
	_assert(_has_style_entry(entries, style_code), "Primary mission map snapshot mirrors the same movement style code as #17")
	scene.queue_free()
	await _wait_frames(2)


func _start_style_context(prefix: String, advance_style: String) -> Dictionary:
	var controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var simulation = SimulationStub.new()
	var units: Array = _make_fireteam_units(prefix)
	var leader = units[0]
	var result: Dictionary = Dictionary(controller.call(
		"start_execution",
		prefix,
		"move",
		1,
		Vector2(0.0, 384.0),
		_make_profile(prefix, advance_style),
		units,
		leader,
		simulation
	))
	_assert(bool(result.get("started", false)), "%s movement execution starts" % String(advance_style).to_upper())
	return {
		"controller": controller,
		"simulation": simulation,
		"units": units,
		"state": Dictionary(result.get("movement_state", {})),
	}


func _make_profile(fireteam_id: String, advance_style: String):
	var profile = FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.new()
	profile.fireteam_id = fireteam_id
	profile.advance_style = advance_style
	profile.cover_priority = 0.45
	profile.fire_discipline = "hold_fire"
	profile.cohesion_threshold = 96.0
	profile.order_fidelity = 1.0
	profile.execution_cohesion = 0.8
	profile.initiative = 0.62
	return profile


func _make_fireteam_units(prefix: String) -> Array:
	return [
		_make_unit("%s_lead" % prefix, prefix, true, Vector2(0.0, 64.0), 0.58, 0.66, 0.72, ["steady"]),
		_make_unit("%s_scout" % prefix, prefix, false, Vector2(-24.0, 74.0), 0.94, 0.42, 0.35, []),
		_make_unit("%s_marksman" % prefix, prefix, false, Vector2(22.0, 78.0), 0.48, 0.96, 0.32, []),
		_make_unit("%s_rifle" % prefix, prefix, false, Vector2(8.0, 98.0), 0.62, 0.58, 0.34, []),
	]


func _make_unit(unit_id: String, fireteam_id: String, is_lead: bool, position_value: Vector2, speed: float, accuracy: float, leadership: float, traits: Array) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.display_name = unit_id
	unit.team_id = "team_alpha"
	unit.fireteam_id = fireteam_id
	unit.is_fireteam_lead = is_lead
	unit.skill_speed = speed
	unit.skill_accuracy = accuracy
	unit.skill_leadership = leadership
	unit.skill_toughness = 0.55
	unit.trait_ids = PackedStringArray(traits)
	unit.position = position_value
	unit._ready()
	return unit


func _has_style_entry(entries: Array, style_code: String) -> bool:
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("style_code", "")) == style_code:
			return true
	return false


func _style_entry_has_multitile_bound(entries: Array, style_code: String) -> bool:
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("style_code", "")) == style_code:
			return bool(entry.get("multi_tile_bound", false)) and float(entry.get("bound_distance", 0.0)) >= 48.0
	return false


func _style_entry_has_single_mover(entries: Array, style_code: String) -> bool:
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("style_code", "")) == style_code:
			return PackedStringArray(entry.get("moving_unit_ids", PackedStringArray())).size() == 1
	return false


func _all_map_labels_compact(entries: Array, max_length: int) -> bool:
	for entry_variant in entries:
		var label_text: String = String(Dictionary(entry_variant).get("map_label_text", ""))
		if label_text.is_empty() or label_text.length() > max_length:
			return false
	return true


func _cleanup_units(units: Array) -> void:
	for unit in units:
		if unit == null:
			continue
		if unit is Node and (unit as Node).is_inside_tree():
			(unit as Node).queue_free()
		else:
			unit.free()


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
