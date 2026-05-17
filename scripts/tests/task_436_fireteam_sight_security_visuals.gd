extends SceneTree

const DRILL_SCENE: PackedScene = preload("res://scenes/tests/fireteam_command_drill_map.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const FIRETEAM_SECURITY_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_security_controller.gd")
const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

const MAP_PATH: String = "res://maps/fireteam_command_drill_24x24.json"
const SCENARIO_PATH: String = "res://data/mission_scenarios/fireteam_command_drill_24x24.json"
const TASK_PATH: String = "res://docs/tasks/TASK_436_fireteam_sight_security_visuals.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

var _passed: int = 0
var _failed: int = 0


class DummyUnit extends Node2D:
	var unit_id: String = ""
	var is_fireteam_lead: bool = false
	var leadership: float = 0.8
	var accuracy: float = 0.55

	func _init(next_unit_id: String, next_position: Vector2, next_is_lead: bool = false) -> void:
		unit_id = next_unit_id
		global_position = next_position
		is_fireteam_lead = next_is_lead

	func get_unit_id() -> String:
		return unit_id

	func get_vital_state() -> String:
		return "fit"

	func get_accuracy_skill() -> float:
		return accuracy

	func get_leadership_skill() -> float:
		return leadership

	func get_trait_ids() -> PackedStringArray:
		return PackedStringArray()


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_436 Fireteam Sight Security Visuals ===")
	_test_security_assignments_split_front_and_flanks()
	await _test_terrain_sightline_bubble_and_muzzle_visuals()
	_test_drill_map_shrubs_and_patrol_bindings()
	await _test_drill_scene_enemy_spacing_and_security_card()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_security_assignments_split_front_and_flanks() -> void:
	var controller = FIRETEAM_SECURITY_CONTROLLER_SCRIPT.new()
	var units: Array = [
		DummyUnit.new("alpha", Vector2(0, 0), true),
		DummyUnit.new("bravo", Vector2(32, 0)),
		DummyUnit.new("charlie", Vector2(0, 32)),
		DummyUnit.new("delta", Vector2(32, 32)),
	]
	var directional_state: Dictionary = Dictionary(controller.call(
		"update_fireteam_state",
		"drill",
		units,
		units[0],
		{"metadata": {"origin_command_type": "defend", "security_mode_override": "directional", "security_direction_angle": 0.0}},
		{},
		{},
		{},
		[],
		{"command_type": "defend", "security_mode": "directional", "security_direction_angle": 0.0}
	))
	var directional_assignments: Array = Array(directional_state.get("member_assignments", []))
	_assert(directional_assignments.size() == 4, "Directional defense assigns all four members")
	_assert(_assignment_roles_include(directional_assignments, ["front_left", "front_right", "left_flank", "right_flank"]), "Directional defense splits into two front guards plus left/right flank")
	_assert(_role_angle_close(directional_assignments, "front_left", -deg_to_rad(8.0)), "Front-left guard is only slightly left of march direction")
	_assert(_role_angle_close(directional_assignments, "front_right", deg_to_rad(8.0)), "Front-right guard is only slightly right of march direction")
	_assert(_role_angle_close(directional_assignments, "left_flank", -deg_to_rad(60.0)), "Left flank guard covers the left shoulder")
	_assert(_role_angle_close(directional_assignments, "right_flank", deg_to_rad(60.0)), "Right flank guard covers the right shoulder")

	var omni_state: Dictionary = Dictionary(controller.call(
		"update_fireteam_state",
		"drill",
		units,
		units[0],
		{"metadata": {"origin_command_type": "defend", "security_mode_override": "360"}},
		{},
		{},
		{},
		[],
		{"command_type": "defend", "security_mode": "360"}
	))
	var omni_assignments: Array = Array(omni_state.get("member_assignments", []))
	_assert(_assignment_roles_include(omni_assignments, ["north", "east", "south", "west"]), "360 defense uses cardinal coverage roles")


func _test_terrain_sightline_bubble_and_muzzle_visuals() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task436_visual_map", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 2)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	var unit: Node2D = _make_unit("task436_alpha", Vector2(160.0, 160.0), "team_alpha", "drill")
	root.add_child(unit)
	unit.set_meta("facing_angle", Vector2.RIGHT.angle())
	unit.call("set_runtime_status", "assigned", "move_to_position", 10, "fire_at_will", "task436", 1.0, 0.0, 0.0, -1, unit.global_position, "engage", "aimed", "task436_aim")
	primary_view.call("set_unit_nodes", [unit])
	await _wait_frames(12)
	primary_view.call(
		"set_order_visual_payload",
		{
			"selected_fireteam_ids": PackedStringArray(["drill"]),
			"fire_sector_overlay_enabled": true,
			"fire_sector_visual_mode": "los_line_only",
			"fire_event_dicts": [
				{
					"event_id": "task436_fire",
					"event_type": "weapon_fire",
					"attacker_unit_id": "task436_alpha",
					"target_unit_id": "task436_target",
					"weapon_id": "rifle",
					"attacker_position": unit.global_position,
					"target_position": unit.global_position + Vector2(240.0, 0.0),
				},
			],
			"feedback_bubble_dicts": [
				{
					"bubble_id": "task436_bubble",
					"display_type": "comic_bubble",
					"visual_only": true,
					"fireteam_id": "drill",
					"unit_id": "task436_alpha",
					"text": "MOVE Nord Ost vierzehn Felder C Aim",
					"anchor_space": "hud",
					"hud_anchor_position": Vector2(240.0, 132.0),
					"max_size": Vector2i(148, 52),
				},
			],
		}
	)
	await _wait_frames(8)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var aim_entry: Dictionary = _find_entry(Array(snapshot.get("friendly_aim_entries", [])), "unit_id", "task436_alpha")
	_assert(not aim_entry.is_empty(), "Selected fireteam emits one friendly sight/fire entry")
	_assert(_is_head_sight_anchor(String(aim_entry.get("line_origin_anchor", ""))), "Sight/fire entry is anchored at the head sight point")
	_assert(int(aim_entry.get("range_tiles", 0)) == int(aim_entry.get("weapon_range_tiles", -1)), "Friendly sight/fire line uses actual weapon range instead of going infinite")
	_assert(absf(float(aim_entry.get("range_world", 0.0)) - float(aim_entry.get("weapon_range_world", -1.0))) < 0.01, "Friendly sight/fire line stores weapon world range as visual range")
	var vfx_entry: Dictionary = _find_entry(Array(snapshot.get("weapon_fire_vfx_entries", [])), "event_id", "task436_fire")
	_assert(bool(vfx_entry.get("muzzle_flash_visible", false)) and bool(vfx_entry.get("muzzle_bloom_visible", false)), "Muzzle flash and bloom are present")
	_assert(float(vfx_entry.get("muzzle_flash_pixel_size", 0.0)) >= 0.044, "Muzzle flash uses the larger readable clamp")
	_assert(bool(vfx_entry.get("trace_visible", false)) and float(vfx_entry.get("trace_width", 0.0)) >= 0.06, "Fire trace is widened for readability")
	var bubble_entry: Dictionary = _find_entry(Array(snapshot.get("feedback_bubble_entries", [])), "bubble_id", "task436_bubble")
	_assert(String(bubble_entry.get("hud_text_alignment", "")) == "top_left", "HUD feedback bubble text is top-left aligned")
	_assert(String(bubble_entry.get("wrapped_text", "")).contains("\n"), "HUD feedback bubble wraps long command text into shorter lines")
	_assert(Vector2(bubble_entry.get("hud_bubble_size", Vector2.ZERO)).y <= 72.0, "HUD feedback bubble stays moderately sized")
	primary_view.queue_free()
	unit.queue_free()
	await _wait_frames(2)


func _test_drill_map_shrubs_and_patrol_bindings() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	_assert(map_data != null, "Drill map loads for TASK_436")
	if map_data == null:
		return
	var shrub_object_tiles: int = 0
	for tile in Array(map_data.call("get_tiles")):
		if tile == null:
			continue
		if String(tile.object_type_id) == "nature_bush_cover":
			shrub_object_tiles += 1
			_assert(String(tile.type_id) == "ground_flat", "Bush object keeps a ground tile under it")
			_assert(String(tile.surface_type) == "ground" and bool(tile.walkable), "Bush object tile remains walkable ground")
	_assert(shrub_object_tiles >= 6, "Drill map has several bush objects on floor tiles")
	var patrol_paths: Dictionary = Dictionary(map_data.call("get_patrol_paths"))
	for patrol_id in ["enemy_drill_watch_route", "enemy_drill_echo_route", "enemy_drill_foxtrot_route", "enemy_drill_golf_route"]:
		_assert(Array(patrol_paths.get(patrol_id, [])).size() >= 3, "Drill map contains patrol route %s" % patrol_id)
	var scenario = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", SCENARIO_PATH)
	_assert(scenario != null, "Drill scenario loads for TASK_436")
	if scenario != null:
		_assert(Array(scenario.get("patrol_bindings")).size() >= 4, "Drill scenario binds all four enemies to patrol routes")


func _test_drill_scene_enemy_spacing_and_security_card() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(36)
	var setup := scene.get_node_or_null("MissionSetup")
	var controller := scene.get_node_or_null("TacticalController")
	_assert(setup != null and controller != null, "Drill scene exposes setup and controller")
	if setup == null or controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	if setup.has_method("set_fog_of_war_mode"):
		setup.call("set_fog_of_war_mode", "off")
	var enemies: Array = Array(controller.call("_get_all_enemy_units", true))
	_assert(enemies.size() == 4, "Drill scene has four enemy runtime NPCs")
	_assert(_minimum_node2d_distance(enemies) >= 55.0, "Enemy NPC spawn offsets keep four separate visible bodies")

	controller.call("_set_selected_fireteams", PackedStringArray(["drill"]), false)
	controller.call("_ensure_fireteam_security_controller")
	var units: Array = Array(controller.call("_get_fireteam_units", "drill", true))
	var leader = controller.call("_resolve_fireteam_leader_for_behavior", "drill")
	var security_controller = controller.get("_fireteam_security_controller")
	_assert(units.size() == 4 and leader != null and security_controller != null, "Security card test has four friendly members and controller")
	if units.size() == 4 and leader != null and security_controller != null:
		security_controller.call(
			"update_fireteam_state",
			"drill",
			units,
			leader,
			{"metadata": {"origin_command_type": "defend", "security_mode_override": "directional", "security_direction_angle": 0.0}},
			{},
			{},
			{},
			[],
			{"command_type": "defend", "security_mode": "directional", "security_direction_angle": 0.0}
		)
		controller.call("_apply_fireteam_security_facing_from_state", Dictionary(security_controller.call("get_fireteam_state", "drill")))
		controller.call("_refresh_fireteam_mini_cards")
		var card: Control = _find_fireteam_mini_card(scene, "drill")
		var coverage_bar: Control = null
		if card != null:
			coverage_bar = card.find_child("MiniSecurityCoverageBar", true, false) as Control
		var coverage_snapshot: Dictionary = Dictionary(coverage_bar.get_meta("mission_fireteam_mini_security_coverage_snapshot", {})) if coverage_bar != null else {}
		_assert(coverage_bar != null and coverage_bar.visible, "Fireteam mini-card shows the security coverage bar")
		_assert(String(coverage_snapshot.get("coverage_shape", "")) == "front_both_flanks", "Mini-card coverage bar reports front plus both flanks")
		for unit in units:
			_assert(unit is Node and (unit as Node).has_meta("security_facing_angle"), "Security assignments write visible facing meta to %s" % String(unit.call("get_unit_id")))
	scene.queue_free()
	await _wait_frames(2)


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("TASK_436 - Fireteam Sight Security Visuals"), "TASK_436 task file exists")
	_assert(status_text.contains("TASK_436 - Fireteam Sight Security Visuals"), "Implementation status documents TASK_436")
	_assert(roadmap_text.contains("TASK_436 - Fireteam Sight Security Visuals"), "Roadmap lists TASK_436")


func _make_unit(unit_id: String, position_value: Vector2, team_id: String, fireteam_id: String) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.name = unit_id
	unit.unit_id = unit_id
	unit.display_name = unit_id
	unit.team_id = team_id
	unit.fireteam_id = fireteam_id
	unit.weapon_1_id = "rifle"
	unit.weapon_2_id = "rifle"
	unit.global_position = position_value
	unit._ready()
	return unit


func _assignment_roles_include(assignments: Array, expected_roles: Array) -> bool:
	var roles := PackedStringArray()
	for assignment_variant in assignments:
		if typeof(assignment_variant) == TYPE_DICTIONARY:
			roles.append(String(Dictionary(assignment_variant).get("coverage_role", "")))
	for role_variant in expected_roles:
		if not roles.has(String(role_variant)):
			return false
	return true


func _role_angle_close(assignments: Array, role: String, expected_angle: float) -> bool:
	for assignment_variant in assignments:
		if typeof(assignment_variant) != TYPE_DICTIONARY:
			continue
		var assignment: Dictionary = Dictionary(assignment_variant)
		if String(assignment.get("coverage_role", "")) != role:
			continue
		return absf(wrapf(float(assignment.get("base_angle", 99.0)) - expected_angle, -PI, PI)) < 0.04
	return false


func _is_head_sight_anchor(anchor_name: String) -> bool:
	var normalized_anchor: String = anchor_name.strip_edges().to_lower()
	return normalized_anchor == "head_visual" or normalized_anchor == "unit_head_fallback"


func _minimum_node2d_distance(nodes: Array) -> float:
	var minimum_distance: float = INF
	for left_index in range(nodes.size()):
		var left := nodes[left_index] as Node2D
		if left == null:
			continue
		for right_index in range(left_index + 1, nodes.size()):
			var right := nodes[right_index] as Node2D
			if right == null:
				continue
			minimum_distance = minf(minimum_distance, left.global_position.distance_to(right.global_position))
	return minimum_distance if minimum_distance < INF else 0.0


func _find_fireteam_mini_card(scene: Node, fireteam_id: String) -> Control:
	if scene == null:
		return null
	var card_list := scene.get_node_or_null("TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox")
	if card_list == null:
		return null
	for child in card_list.get_children():
		if child is Control and String(child.get_meta("fireteam_id", "")).strip_edges().to_lower() == fireteam_id.strip_edges().to_lower():
			return child as Control
	return null


func _find_entry(entries: Array, key: String, value: String) -> Dictionary:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get(key, "")).strip_edges().to_lower() == value.strip_edges().to_lower():
			return entry
	return {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _wait_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
