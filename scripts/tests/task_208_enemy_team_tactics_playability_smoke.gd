extends SceneTree

const MAP_PATH: String = "res://maps/enemy_tactics_smoke_32x32.json"
const MANUAL_CHECKLIST_PATH: String = "res://docs/dev/enemy_team_tactics_manual_smoke_checklist.md"
const FRIENDLY_ARCHETYPE_ID: String = "friendly_space_suit_white"
const ENEMY_ARCHETYPE_ID: String = "enemy_space_suit_orange"

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")
const MISSION_TEST_SETUP_SCRIPT: GDScript = preload("res://scripts/tests/mission_test_setup.gd")
const MISSION_COMBAT_LOOP_DRIVER_SCRIPT: GDScript = preload("res://scripts/tests/mission_combat_loop_driver.gd")
const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const OBJECTIVE_STATUS_SCRIPT: GDScript = preload("res://scripts/core/objective_status.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_snapshot_contract.gd")
const COMBAT_FIRE_DECISION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/combat_fire_decision_resolver.gd")
const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")
const LOCAL_AVOIDANCE_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/local_avoidance_resolver.gd")
const META_UNIT_PROFILE_BUILDER_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile_builder.gd")
const NPC_COMPACT_CARD_SCRIPT: GDScript = preload("res://scripts/meta/npc_compact_card.gd")

var _passed: int = 0
var _failed: int = 0


class RangeLOSStub:
	extends RefCounted

	var call_count: int = 0
	var last_range: float = 0.0

	func has_line_of_sight_between_nodes(attacker, target, range_value: float, _terrain_registry = null) -> bool:
		call_count += 1
		last_range = range_value
		if attacker is Node2D and target is Node2D:
			return (attacker as Node2D).global_position.distance_to((target as Node2D).global_position) <= range_value
		return true

	func has_line_of_sight_between_points(source_position: Vector2, target_position: Vector2, range_value: float, _terrain_registry = null) -> bool:
		call_count += 1
		last_range = range_value
		return source_position.distance_to(target_position) <= range_value


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_208 Enemy Team Tactics Playability Smoke ===")
	_test_fixture_loads_and_documents_play_space()
	await _test_editor_roundtrip_and_mission_setup_reads_same_config()
	await _test_integrated_runtime_visual_snapshot_and_badges()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_fixture_loads_and_documents_play_space() -> void:
	_assert(FileAccess.file_exists(MAP_PATH), "TASK_208 32x32 smoke map exists")
	_assert(FileAccess.file_exists(MANUAL_CHECKLIST_PATH), "Manual 2.5D smoke checklist exists")
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	_assert(map_data != null, "TASK_208 map loads through TerrainMapData")
	if map_data == null:
		return
	_assert(Vector2i(map_data.call("get_grid_size")) == Vector2i(32, 32), "Smoke map declares a 32x32 grid")
	_assert(Array(map_data.call("get_tiles")).size() >= 40, "Smoke map carries a compact tactical tile fixture")
	for marker_id in ["spawn_alpha", "spawn_enemy_hold", "spawn_enemy_push", "objective_point"]:
		_assert(bool(map_data.call("has_marker", marker_id)), "Smoke map has marker: %s" % marker_id)
	_assert(String(Dictionary(map_data.call("get_enemy_team_config", "smoke_hold")).get("profile_id", "")) == "guard_hold", "Map carries an enemy hold tactics preset")
	_assert(String(Dictionary(map_data.call("get_enemy_team_config", "smoke_push")).get("profile_id", "")) == "aggressive_push", "Map carries an enemy push tactics preset")
	_assert(_map_has_surface(map_data, "sand"), "Smoke map includes sand surface tiles")
	_assert(_map_has_height(map_data), "Smoke map includes elevated hill/slope tiles")
	_assert(_map_has_edge(map_data, "cliff"), "Smoke map includes a cliff edge marker tile")
	_assert(_map_has_cover(map_data), "Smoke map includes walkable cover tiles")


func _test_editor_roundtrip_and_mission_setup_reads_same_config() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	var scenario_path: String = "user://task_208_enemy_tactics_smoke_scenario.json"
	var scenario = _build_smoke_scenario()
	var save_error: Error = scenario.call("save_to_file", scenario_path)
	_assert(save_error == OK, "Smoke mission scenario saves for editor/setup roundtrip")
	var loaded_scenario = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", scenario_path)
	var validation: Dictionary = Dictionary(loaded_scenario.call("validate"))
	_assert(bool(validation.get("valid", false)), "Smoke mission scenario validates against the 32x32 fixture")
	_assert(String(Dictionary(loaded_scenario.call("get_enemy_tactics_for_unit", "task_208_hold_a", map_data)).get("profile_id", "")) == "guard_hold", "Scenario exposes hold profile by enemy unit")
	_assert(String(Dictionary(loaded_scenario.call("get_enemy_tactics_for_unit", "task_208_push_a", map_data)).get("profile_id", "")) == "aggressive_push", "Scenario exposes push profile by enemy unit")

	var setup: Node = MISSION_TEST_SETUP_SCRIPT.new()
	setup.set("_mission_scenario", loaded_scenario)
	setup.set("_loaded_terrain_map_data", map_data)
	var hold_probe = _make_unit("task_208_hold_a", "team_bravo", "rifle", Vector2.ZERO)
	var push_probe = _make_unit("task_208_push_a", "team_bravo", "smg", Vector2.ZERO)
	var setup_tactics: Dictionary = Dictionary(setup.call("_build_enemy_tactics_by_unit_id", [hold_probe, push_probe]))
	_assert(String(Dictionary(setup_tactics.get("task_208_hold_a", {})).get("profile_id", "")) == "guard_hold", "MissionTestSetup reads hold tactics from the same scenario config")
	_assert(String(Dictionary(setup_tactics.get("task_208_push_a", {})).get("profile_id", "")) == "aggressive_push", "MissionTestSetup reads push tactics from the same scenario config")
	hold_probe.free()
	push_probe.free()
	setup.free()

	var editor := MAP_EDITOR_SCENE.instantiate()
	_assert(editor != null, "Map editor scene instantiates for TASK_208 roundtrip")
	if editor == null:
		return
	root.add_child(editor)
	await _wait_frames(3)
	_assert(bool(editor.call("load_mission_scenario_for_editor", scenario_path)), "Editor loads the TASK_208 smoke scenario")
	await _wait_frames(3)
	editor.call(
		"set_enemy_tactics_authoring_fields",
		{
			"profile_id": "defensive_cover",
			"security_mode": "cover_arc",
			"facing": "north_west",
		}
	)
	var editor_snapshot: Dictionary = Dictionary(editor.call("get_enemy_tactics_authoring_snapshot"))
	_assert(String(editor_snapshot.get("profile_id", "")) == "defensive_cover", "Editor authoring snapshot keeps changed tactic profile")
	_assert(String(editor_snapshot.get("facing", "")) == "north_west", "Editor authoring snapshot keeps changed facing")
	var editor_save_path: String = "user://task_208_editor_roundtrip_scenario.json"
	_assert(editor.call("save_mission_scenario_from_editor", editor_save_path) == OK, "Editor saves the TASK_208 tactic roundtrip scenario")
	var reloaded_scenario = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", editor_save_path)
	var reloaded_group: Dictionary = Dictionary(Array(reloaded_scenario.get("enemy_groups"))[0])
	var reloaded_tactics: Dictionary = Dictionary(reloaded_group.get("tactics", {}))
	_assert(String(reloaded_tactics.get("profile_id", "")) == "defensive_cover", "Editor save/load preserves changed tactic profile")
	_assert(String(reloaded_tactics.get("facing", "")) == "north_west", "Editor save/load preserves changed facing")
	editor.queue_free()
	await process_frame


func _test_integrated_runtime_visual_snapshot_and_badges() -> void:
	var context: Dictionary = _make_integrated_context()
	var driver: Node = context["driver"]
	var simulation_root: Node = context["simulation_root"]
	var terrain_registry: Node = context["terrain_registry"]
	driver.set("_current_tick", 44)
	driver.call("_update_enemy_security_state")
	driver.call("_update_enemy_team_tactics_state")
	driver.call("_advance_enemy_units", simulation_root)
	_record_smoke_fire_events(driver, context)

	var security_snapshot: Array = Array(driver.call("get_enemy_security_snapshot"))
	var tactics_snapshot: Array = Array(driver.call("get_enemy_team_tactics_snapshot"))
	var fire_events: Array = Array(driver.call("get_fire_event_snapshot"))
	var hold_state: Dictionary = _find_state_by_group_id(tactics_snapshot, "red_hold")
	var cover_state: Dictionary = _find_state_by_group_id(tactics_snapshot, "red_cover")
	var push_state: Dictionary = _find_state_by_group_id(tactics_snapshot, "red_push")
	_assert(security_snapshot.size() >= 3, "Integrated smoke exposes enemy security for hold, cover and push groups")
	_assert(tactics_snapshot.size() >= 3, "Integrated smoke starts a mission with at least two enemy profiles")
	_assert(String(hold_state.get("advance_style", "")) == "hold", "Guard-hold team stays in hold tactic")
	_assert(String(cover_state.get("advance_style", "")) == "bounding", "Defensive-cover team resolves to bounding cover movement")
	_assert(String(push_state.get("advance_style", "")) == "push", "Aggressive-push team resolves to push movement")
	_assert(PackedStringArray(push_state.get("moving_unit_ids", PackedStringArray())).size() >= 2, "Push team marks multiple enemy units as moving")
	_assert(simulation_root.command_queue.size() >= 2, "Enemy tactics enqueue movement commands on the authority path")
	_assert(_security_snapshot_has_watched_targets(security_snapshot), "Enemy facing/security snapshot shows watched friendly units")
	_assert(_position_values_keep_spacing(Dictionary(push_state.get("target_positions_by_unit_id", {})).values()), "Enemy push targets respect TASK_187 minimum spacing")
	_assert(_unit_positions_keep_spacing([context["blue_lead"], context["blue_support"], context["red_hold_a"], context["red_hold_b"], context["red_cover_a"], context["red_cover_b"], context["red_push_a"], context["red_push_b"]]), "Friendly and enemy unit placements start with minimum spacing")
	_assert(_range_limit_blocks_standard_overreach(terrain_registry), "Weapon ranges prevent an SMG from firing at rifle-only distance")
	_assert(fire_events.size() == 2, "Friendly and enemy fire events are available for VFX")

	driver.call("_publish_multiplayer_snapshot_context", simulation_root)
	simulation_root.set("tick_counter", 44)
	var server_snapshot: Dictionary = Dictionary(simulation_root.call("build_multiplayer_snapshot"))
	_assert(Array(server_snapshot.get("enemy_security", [])).size() >= 3, "Server snapshot mirrors enemy security overlay data")
	_assert(Array(server_snapshot.get("enemy_team_tactics", [])).size() >= 3, "Server snapshot mirrors enemy tactics overlay data")
	_assert(Array(server_snapshot.get("fire_events", [])).size() == 2, "Server snapshot mirrors authority fire events")
	_assert(_snapshot_has_enemy_visual(server_snapshot, "task_208_push_a"), "Enemy unit snapshot carries orange archetype display data")
	_assert(_snapshot_target_positions_keep_spacing(server_snapshot), "Snapshot tactic positions keep minimum spacing")

	var client_harness := Node.new()
	client_harness.name = "Task208ClientSnapshotHarness"
	root.add_child(client_harness)
	var client_registry = UNIT_REGISTRY_SCRIPT.new()
	client_registry.name = "UnitRegistry"
	client_harness.add_child(client_registry)
	var client_simulation: Node = SIMULATION_ROOT_SCRIPT.new()
	client_simulation.name = "SimulationRoot"
	client_simulation.unit_registry_path = NodePath("../UnitRegistry")
	client_harness.add_child(client_simulation)
	var apply_result: Dictionary = Dictionary(client_simulation.call("apply_multiplayer_snapshot", server_snapshot))
	var client_state: Dictionary = Dictionary(client_simulation.call("get_last_server_state"))
	_assert(bool(apply_result.get("accepted", false)), "Client/viewer accepts TASK_208 server snapshot")
	_assert(client_simulation.command_queue.is_empty(), "Client snapshot apply does not enqueue enemy commands")
	_assert(client_simulation.effects_queue.is_empty(), "Client snapshot apply does not enqueue damage or combat effects")
	_assert(Array(client_state.get("fire_events", [])).size() == 2, "Client/viewer keeps fire events as mirrored display data")

	var normalized_snapshot: Dictionary = Dictionary(MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT.new().call("build_state_snapshot", server_snapshot))
	_assert(Array(normalized_snapshot.get("enemy_team_tactics", [])).size() == Array(server_snapshot.get("enemy_team_tactics", [])).size(), "Snapshot contract keeps enemy tactics through normalization")

	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", context["map_data"])
	primary_view.call("set_unit_nodes", context["units"])
	primary_view.call(
		"set_order_visual_payload",
		{
			"phase_index": 1,
			"enemy_security_dicts": security_snapshot,
			"enemy_tactics_dicts": tactics_snapshot,
			"fire_event_dicts": fire_events,
		}
	)
	await _wait_frames(12)
	var render_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(render_snapshot.get("enemy_security_visual_count", 0)) >= 3, "2.5D primary map renders enemy facing/security visuals")
	_assert(int(render_snapshot.get("enemy_tactics_visual_count", 0)) >= 3, "2.5D primary map renders enemy tactic labels")
	_assert(int(render_snapshot.get("weapon_fire_vfx_visual_count", 0)) == 2, "2.5D primary map renders one muzzle flash token per fire event")
	_assert(_proxy_has_archetype(render_snapshot, "task_208_blue_lead", FRIENDLY_ARCHETYPE_ID), "Friendly 2.5D proxy resolves to the white friendly archetype")
	_assert(_proxy_has_archetype(render_snapshot, "task_208_push_a", ENEMY_ARCHETYPE_ID), "Enemy 2.5D proxy resolves to the orange enemy archetype")
	_assert(_weapon_vfx_has_attacker(render_snapshot, "task_208_blue_lead") and _weapon_vfx_has_attacker(render_snapshot, "task_208_push_a"), "Friendly and enemy shots both produce VFX entries")

	await _test_rank_badges_visible_in_mission_card()
	primary_view.queue_free()
	client_harness.queue_free()
	_cleanup_context(context)
	await process_frame


func _build_smoke_scenario():
	return MISSION_SCENARIO_DATA_SCRIPT.new(
		{
			"version": 1,
			"scenario_id": "task_208_enemy_tactics_smoke",
			"display_name": "TASK 208 Enemy Tactics Smoke",
			"map_file_path": MAP_PATH,
			"time_limit_seconds": 180.0,
			"mission_slot_count_override": 8,
			"objective": {
				"marker_id": "objective_point",
				"capture_radius": 72.0,
			},
			"enemy_groups": [
				{
					"group_id": "red_hold",
					"display_name": "Red Hold",
					"team_id": "team_bravo",
					"enemy_ids": ["task_208_hold_a", "task_208_hold_b"],
					"spawn_marker_id": "spawn_enemy_hold",
					"tactics": {
						"profile_id": "guard_hold",
						"security_mode": "360",
						"facing": "west",
					},
				},
				{
					"group_id": "red_cover",
					"display_name": "Red Cover",
					"team_id": "team_bravo",
					"enemy_ids": ["task_208_cover_a", "task_208_cover_b"],
					"spawn_marker_id": "spawn_enemy_hold",
					"tactics": {
						"profile_id": "defensive_cover",
						"security_mode": "cover_arc",
						"facing": "west",
					},
				},
				{
					"group_id": "red_push",
					"display_name": "Red Push",
					"team_id": "team_bravo",
					"enemy_ids": ["task_208_push_a", "task_208_push_b"],
					"spawn_marker_id": "spawn_enemy_push",
					"tactics": {
						"profile_id": "aggressive_push",
						"security_mode": "directional",
						"facing": "west",
					},
				},
			],
			"wave_config": {
				"wave_count": 1,
				"units_per_wave": 6,
				"first_wave_delay_seconds": 0.0,
				"wave_delay_seconds": 60.0,
			},
			"notes": [
				"TASK_208 integrated Enemy-Team-Tactics smoke fixture.",
				"LZ remains player/controller-owned and is intentionally not stored here.",
			],
		}
	)


func _make_integrated_context() -> Dictionary:
	var harness := Node.new()
	harness.name = "Task208IntegratedHarness"
	root.add_child(harness)

	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	var terrain_registry: Node = TERRAIN_REGISTRY_SCRIPT.new()
	terrain_registry.name = "TerrainRegistry"
	_configure_registry_from_map(terrain_registry, map_data)
	harness.add_child(terrain_registry)

	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	harness.add_child(unit_registry)

	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	simulation_root.terrain_registry_path = NodePath("../TerrainRegistry")
	harness.add_child(simulation_root)

	var objective_status = OBJECTIVE_STATUS_SCRIPT.new()
	objective_status.objective_id = "objective_point"
	objective_status.position = map_data.call("get_marker_position", "objective_point", Vector2.ZERO)
	objective_status.capture_radius = 72.0
	simulation_root.call("set_objective_status", objective_status)

	var blue_lead = _make_unit("task_208_blue_lead", "team_alpha", "rifle", _grid_world(map_data, Vector2i(13, 18)), {
		"role_id": "rifleman",
		"role_name": "Fireteam Lead",
		"is_fireteam_lead": true,
	})
	var blue_support = _make_unit("task_208_blue_support", "team_alpha", "smg", _grid_world(map_data, Vector2i(13, 19)), {"role_id": "scout", "role_name": "Scout"})
	var red_hold_a = _make_unit("task_208_hold_a", "team_bravo", "rifle", _grid_world(map_data, Vector2i(16, 16)), {"role_id": "security_guard"})
	var red_hold_b = _make_unit("task_208_hold_b", "team_bravo", "rifle", _grid_world(map_data, Vector2i(16, 17)), {"role_id": "security_guard"})
	var red_cover_a = _make_unit("task_208_cover_a", "team_bravo", "rail_gun", _grid_world(map_data, Vector2i(19, 17)), {"role_id": "support"})
	var red_cover_b = _make_unit("task_208_cover_b", "team_bravo", "rifle", _grid_world(map_data, Vector2i(19, 18)), {"role_id": "rifleman"})
	var red_push_a = _make_unit("task_208_push_a", "team_bravo", "smg", _grid_world(map_data, Vector2i(23, 18)), {"role_id": "assault"})
	var red_push_b = _make_unit("task_208_push_b", "team_bravo", "rifle", _grid_world(map_data, Vector2i(23, 19)), {"role_id": "assault"})
	var units: Array = [blue_lead, blue_support, red_hold_a, red_hold_b, red_cover_a, red_cover_b, red_push_a, red_push_b]
	for unit in units:
		harness.add_child(unit)
		unit_registry.call("register_unit", String(unit.call("get_unit_id")), unit)
		simulation_root.call("register_known_unit", String(unit.call("get_unit_id")), unit)

	_apply_enemy_tactics(red_hold_a, "red_hold", "guard_hold", "360", "west")
	_apply_enemy_tactics(red_hold_b, "red_hold", "guard_hold", "360", "west")
	_apply_enemy_tactics(red_cover_a, "red_cover", "defensive_cover", "cover_arc", "west")
	_apply_enemy_tactics(red_cover_b, "red_cover", "defensive_cover", "cover_arc", "west")
	_apply_enemy_tactics(red_push_a, "red_push", "aggressive_push", "directional", "west")
	_apply_enemy_tactics(red_push_b, "red_push", "aggressive_push", "directional", "west")

	var driver: Node = MISSION_COMBAT_LOOP_DRIVER_SCRIPT.new()
	driver.name = "CombatLoopDriver"
	driver.friendly_team_id = "team_alpha"
	driver.preview_mode = true
	driver.enemy_advance_enabled = true
	driver.contact_range = 9999.0
	driver.simulation_root_path = NodePath("../SimulationRoot")
	driver.terrain_registry_path = NodePath("../TerrainRegistry")
	var friendly_paths: Array[NodePath] = [NodePath("../task_208_blue_lead"), NodePath("../task_208_blue_support")]
	var enemy_paths: Array[NodePath] = [
		NodePath("../task_208_hold_a"),
		NodePath("../task_208_hold_b"),
		NodePath("../task_208_cover_a"),
		NodePath("../task_208_cover_b"),
		NodePath("../task_208_push_a"),
		NodePath("../task_208_push_b"),
	]
	driver.friendly_unit_paths = friendly_paths
	driver.enemy_unit_paths = enemy_paths
	harness.add_child(driver)

	return {
		"harness": harness,
		"map_data": map_data,
		"terrain_registry": terrain_registry,
		"unit_registry": unit_registry,
		"simulation_root": simulation_root,
		"driver": driver,
		"units": units,
		"blue_lead": blue_lead,
		"blue_support": blue_support,
		"red_hold_a": red_hold_a,
		"red_hold_b": red_hold_b,
		"red_cover_a": red_cover_a,
		"red_cover_b": red_cover_b,
		"red_push_a": red_push_a,
		"red_push_b": red_push_b,
	}


func _configure_registry_from_map(terrain_registry: Node, map_data) -> void:
	var tile_size: Dictionary = Dictionary(map_data.call("get_tile_size"))
	terrain_registry.call("clear_tiles")
	terrain_registry.call("configure_iso_grid", map_data.call("get_grid_origin"), float(tile_size.get("half_width", 64.0)), float(tile_size.get("half_height", 32.0)))
	for tile_data in Array(map_data.call("get_tiles")):
		terrain_registry.call("register_tile", tile_data)


func _grid_world(map_data, grid_position: Vector2i) -> Vector2:
	var tile = map_data.call("get_tile_at_grid", grid_position)
	if tile != null:
		return Vector2(tile.world_position)
	return Vector2.ZERO


func _make_unit(unit_id: String, team_id: String, weapon_id: String, position_value: Vector2, overrides: Dictionary = {}) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.name = unit_id
	unit.unit_id = unit_id
	unit.display_name = String(overrides.get("display_name", unit_id))
	unit.team_id = team_id
	unit.fireteam_id = "blue" if team_id == "team_alpha" else "red"
	unit.weapon_1_id = weapon_id
	unit.weapon_2_id = weapon_id
	unit.role_id = String(overrides.get("role_id", "rifleman"))
	unit.role_name = String(overrides.get("role_name", unit.role_id.capitalize()))
	unit.skill_accuracy = float(overrides.get("skill_accuracy", 0.72))
	unit.skill_speed = float(overrides.get("skill_speed", 0.58))
	unit.skill_leadership = float(overrides.get("skill_leadership", 0.82 if bool(overrides.get("is_fireteam_lead", false)) else 0.42))
	unit.skill_toughness = float(overrides.get("skill_toughness", 0.52))
	unit.is_fireteam_lead = bool(overrides.get("is_fireteam_lead", false))
	unit.global_position = position_value
	unit._ready()
	return unit


func _apply_enemy_tactics(unit: Node, group_id: String, profile_id: String, security_mode: String, facing: String) -> void:
	unit.set_meta(
		"enemy_tactics_config",
		{
			"group_id": group_id,
			"profile_id": profile_id,
			"security_mode": security_mode,
			"facing": facing,
			"team_id": "team_bravo",
		}
	)


func _record_smoke_fire_events(driver: Node, context: Dictionary) -> void:
	var terrain_registry: Node = context["terrain_registry"]
	var blue = context["blue_lead"]
	var red = context["red_push_a"]
	driver.call(
		"_record_fire_event_from_effect",
		{
			"attacker_unit_id": String(blue.call("get_unit_id")),
			"attacker_team_id": String(blue.call("get_team_id")),
			"unit_id": String(red.call("get_unit_id")),
			"weapon_id": "rifle",
			"weapon_tile_range": int(WEAPON_DATA_SCRIPT.call("get_effective_tile_range", "rifle")),
			"weapon_range_world": float(WEAPON_DATA_SCRIPT.call("get_effective_world_range", "rifle", terrain_registry)),
		},
		blue,
		red,
		"standard"
	)
	driver.call(
		"_record_fire_event_from_effect",
		{
			"attacker_unit_id": String(red.call("get_unit_id")),
			"attacker_team_id": String(red.call("get_team_id")),
			"unit_id": String(blue.call("get_unit_id")),
			"weapon_id": "smg",
			"weapon_tile_range": int(WEAPON_DATA_SCRIPT.call("get_effective_tile_range", "smg")),
			"weapon_range_world": float(WEAPON_DATA_SCRIPT.call("get_effective_world_range", "smg", terrain_registry)),
		},
		red,
		blue,
		"standard"
	)


func _range_limit_blocks_standard_overreach(terrain_registry: Node) -> bool:
	var los := RangeLOSStub.new()
	var smg_attacker = _make_unit("task_208_range_smg", "team_alpha", "smg", Vector2.ZERO)
	var rifle_attacker = _make_unit("task_208_range_rifle", "team_alpha", "rifle", Vector2.ZERO)
	var target = _make_unit("task_208_range_target", "team_bravo", "rifle", Vector2(1000.0, 0.0))
	var context: Dictionary = {
		"friendly_team_id": "team_alpha",
		"contact_range": 9999.0,
		"los_system": los,
		"terrain_registry": terrain_registry,
	}
	var smg_can_fire: bool = bool(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("is_target_attackable", smg_attacker, target, context))
	var rifle_can_fire: bool = bool(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("is_target_attackable", rifle_attacker, target, context))
	smg_attacker.free()
	rifle_attacker.free()
	target.free()
	return not smg_can_fire and rifle_can_fire and los.call_count >= 2


func _test_rank_badges_visible_in_mission_card() -> void:
	var profile = META_UNIT_PROFILE_BUILDER_SCRIPT.call(
		"build_from_identity_config",
		{
			"unit_id": "task_208_badge_lead",
			"display_name": "Badge Lead",
			"team_id": "team_alpha",
			"role_id": "combat_medic",
			"role_name": "Combat Medic",
			"weapon_1": "medictool",
			"weapon_2": "rifle",
			"is_fireteam_lead": true,
		}
	)
	var card := NPC_COMPACT_CARD_SCRIPT.new() as Control
	root.add_child(card)
	card.call("setup_from_profile", profile, {"compact_mode": true, "drag_enabled": false})
	await process_frame
	_assert(_count_nodes_with_prefix(card, "RankBadge_") > 0, "Mission/FOB compact card renders derived rank-skill badges")
	card.queue_free()
	await process_frame


func _find_state_by_group_id(states: Array, group_id: String) -> Dictionary:
	for state_variant in states:
		if typeof(state_variant) != TYPE_DICTIONARY:
			continue
		var state: Dictionary = Dictionary(state_variant)
		if String(state.get("security_group_id", "")).strip_edges() == group_id:
			return state
	return {}


func _map_has_surface(map_data, surface_type: String) -> bool:
	for tile in Array(map_data.call("get_tiles")):
		if String(tile.surface_type) == surface_type:
			return true
	return false


func _map_has_height(map_data) -> bool:
	for tile in Array(map_data.call("get_tiles")):
		if int(tile.height_level) > 0:
			return true
	return false


func _map_has_edge(map_data, edge_type: String) -> bool:
	for tile in Array(map_data.call("get_tiles")):
		if String(tile.edge_type) == edge_type:
			return true
	return false


func _map_has_cover(map_data) -> bool:
	for tile in Array(map_data.call("get_tiles")):
		if bool(tile.walkable) and int(tile.cover_value) > 0:
			return true
	return false


func _security_snapshot_has_watched_targets(security_snapshot: Array) -> bool:
	for state_variant in security_snapshot:
		if typeof(state_variant) != TYPE_DICTIONARY:
			continue
		var state: Dictionary = Dictionary(state_variant)
		if PackedStringArray(state.get("watched_unit_ids", PackedStringArray())).size() > 0:
			return true
	return false


func _position_values_keep_spacing(positions: Array) -> bool:
	var vector_positions: Array = []
	for position_variant in positions:
		if typeof(position_variant) == TYPE_VECTOR2:
			vector_positions.append(Vector2(position_variant))
	return _positions_keep_spacing(vector_positions)


func _unit_positions_keep_spacing(units: Array) -> bool:
	var positions: Array = []
	for unit in units:
		if unit is Node2D:
			positions.append((unit as Node2D).global_position)
	return _positions_keep_spacing(positions)


func _positions_keep_spacing(positions: Array) -> bool:
	for index_a in range(positions.size()):
		for index_b in range(index_a + 1, positions.size()):
			if Vector2(positions[index_a]).distance_to(Vector2(positions[index_b])) < LOCAL_AVOIDANCE_RESOLVER_SCRIPT.DEFAULT_MINIMUM_SPACING - 0.001:
				return false
	return true


func _snapshot_target_positions_keep_spacing(snapshot: Dictionary) -> bool:
	for state_variant in Array(snapshot.get("enemy_team_tactics", [])):
		if typeof(state_variant) != TYPE_DICTIONARY:
			continue
		var state: Dictionary = Dictionary(state_variant)
		if not _position_values_keep_spacing(Dictionary(state.get("target_positions_by_unit_id", {})).values()):
			return false
	return true


func _snapshot_has_enemy_visual(snapshot: Dictionary, unit_id: String) -> bool:
	for unit_variant in Array(snapshot.get("units", [])):
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit_snapshot: Dictionary = Dictionary(unit_variant)
		if String(unit_snapshot.get("unit_id", "")) == unit_id:
			return String(unit_snapshot.get("enemy_visual_archetype_id", "")) == ENEMY_ARCHETYPE_ID
	return false


func _proxy_has_archetype(render_snapshot: Dictionary, unit_id: String, archetype_id: String) -> bool:
	var states: Dictionary = Dictionary(render_snapshot.get("unit_proxy_state_by_id", {}))
	var state: Dictionary = Dictionary(states.get(unit_id, {}))
	return String(state.get("unit_visual_archetype_id", "")) == archetype_id


func _weapon_vfx_has_attacker(render_snapshot: Dictionary, attacker_unit_id: String) -> bool:
	for entry_variant in Array(render_snapshot.get("weapon_fire_vfx_entries", [])):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("attacker_unit_id", "")) == attacker_unit_id:
			return true
	return false


func _count_nodes_with_prefix(node: Node, prefix: String) -> int:
	var count: int = 1 if String(node.name).begins_with(prefix) else 0
	for child in node.get_children():
		count += _count_nodes_with_prefix(child, prefix)
	return count


func _cleanup_context(context: Dictionary) -> void:
	var harness: Node = context.get("harness", null)
	if harness != null:
		harness.queue_free()


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
