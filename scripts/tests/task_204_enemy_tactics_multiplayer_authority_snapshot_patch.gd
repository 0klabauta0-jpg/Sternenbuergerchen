extends SceneTree

const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_snapshot_contract.gd")
const MISSION_COMBAT_LOOP_DRIVER_SCRIPT: GDScript = preload("res://scripts/tests/mission_combat_loop_driver.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_204 Enemy Tactics Multiplayer Authority Snapshot Patch ===")
	_test_contract_normalizes_enemy_tactics_fields()
	_test_authority_snapshot_carries_enemy_tactics_security_and_fire_events()
	_test_client_apply_mirrors_without_enemy_decisions()
	_test_enemy_tactics_snapshot_is_deterministic_by_unit_id()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_contract_normalizes_enemy_tactics_fields() -> void:
	var contract = MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT.new()
	var snapshot: Dictionary = Dictionary(contract.call("build_state_snapshot", _build_enemy_snapshot_payload(4)))
	var unit_snapshot: Dictionary = Dictionary(Array(snapshot.get("units", []))[0])
	var security: Dictionary = Dictionary(Array(snapshot.get("enemy_security", []))[0])
	var tactics: Dictionary = Dictionary(Array(snapshot.get("enemy_team_tactics", []))[0])
	var fire_event: Dictionary = Dictionary(Array(snapshot.get("fire_events", []))[0])
	_assert(String(unit_snapshot.get("enemy_security_mode", "")) == "directional", "Unit snapshot carries enemy security mode as display data")
	_assert(is_equal_approx(float(unit_snapshot.get("enemy_facing_angle", 99.0)), 0.25), "Unit snapshot carries enemy facing angle")
	_assert(String(security.get("watch_label", "")) == "EN SEC DIR W1", "Snapshot carries enemy security display label")
	_assert(PackedStringArray(security.get("watched_unit_ids", PackedStringArray())).has("blue_a"), "Snapshot carries enemy watched units")
	_assert(String(tactics.get("advance_style", "")) == "push", "Snapshot carries current enemy tactic style")
	_assert(Vector2(Dictionary(tactics.get("target_positions_by_unit_id", {})).get("red_a", Vector2.ZERO)).x > 0.0, "Snapshot carries enemy tactic target positions")
	_assert(String(fire_event.get("event_id", "")) == "fire_test_1", "Snapshot carries fire event ID for client VFX")
	_assert(not fire_event.has("client_should_apply_damage"), "Snapshot contract rejects client-side combat decisions")


func _test_authority_snapshot_carries_enemy_tactics_security_and_fire_events() -> void:
	var context: Dictionary = _make_authority_context("authority")
	var driver: Node = context["driver"]
	var simulation_root: Node = context["simulation_root"]
	var enemy: Node2D = context["enemy"]
	var friendly: Node2D = context["friendly"]
	driver.set("_current_tick", 9)
	driver.call("_update_enemy_security_state")
	driver.call("_update_enemy_team_tactics_state")
	driver.call(
		"_record_fire_event_from_effect",
		{
			"attacker_unit_id": enemy.call("get_unit_id"),
			"attacker_team_id": enemy.call("get_team_id"),
			"unit_id": friendly.call("get_unit_id"),
			"weapon_id": "rifle",
			"weapon_tile_range": 25,
			"weapon_range_world": 1800.0,
		},
		enemy,
		friendly,
		"standard"
	)
	driver.call("_publish_multiplayer_snapshot_context", simulation_root)
	simulation_root.set("tick_counter", 9)
	var snapshot: Dictionary = Dictionary(simulation_root.call("build_multiplayer_snapshot"))
	var enemy_unit_snapshot: Dictionary = _find_unit_snapshot(snapshot, "authority_enemy")
	_assert(Array(snapshot.get("enemy_security", [])).size() == 1, "Authority snapshot includes enemy security states")
	_assert(Array(snapshot.get("enemy_team_tactics", [])).size() == 1, "Authority snapshot includes enemy team tactics states")
	_assert(Array(snapshot.get("fire_events", [])).size() == 1, "Authority snapshot includes one mirrored fire event")
	_assert(String(enemy_unit_snapshot.get("enemy_tactic_profile_id", "")) == "aggressive_push", "Unit snapshot mirrors enemy tactic profile from authority metadata")
	_assert(String(enemy_unit_snapshot.get("active_weapon_id", "")) == "rifle", "Enemy unit snapshot keeps active weapon display data")
	_assert(int(enemy_unit_snapshot.get("weapon_tile_range", 0)) == 25, "Enemy unit snapshot keeps weapon tile range display data")
	_cleanup_context(context)


func _test_client_apply_mirrors_without_enemy_decisions() -> void:
	var context: Dictionary = _make_authority_context("client")
	var simulation_root: Node = context["simulation_root"]
	simulation_root.set("tick_counter", 11)
	var snapshot: Dictionary = Dictionary(MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT.new().call("build_state_snapshot", _build_enemy_snapshot_payload(11)))
	var apply_result: Dictionary = Dictionary(simulation_root.call("apply_multiplayer_snapshot", snapshot))
	var last_state: Dictionary = Dictionary(simulation_root.call("get_last_server_state"))
	_assert(bool(apply_result.get("accepted", false)), "Client accepts enemy tactics snapshot")
	_assert(simulation_root.command_queue.is_empty(), "Applying enemy tactics snapshot enqueues no commands")
	_assert(simulation_root.effects_queue.is_empty(), "Applying enemy fire-event snapshot enqueues no effects")
	_assert(Array(last_state.get("fire_events", [])).size() == 1, "Client mirrors fire event exactly once as snapshot data")
	_assert(String(Dictionary(Array(last_state.get("fire_events", []))[0]).get("event_id", "")) == "fire_test_1", "Client keeps authority fire event ID")
	_cleanup_context(context)


func _test_enemy_tactics_snapshot_is_deterministic_by_unit_id() -> void:
	var first_context: Dictionary = _make_authority_context("determinism_a", true)
	var second_context: Dictionary = _make_authority_context("determinism_b", true)
	var first_driver: Node = first_context["driver"]
	var second_driver: Node = second_context["driver"]
	first_driver.call("_update_enemy_team_tactics_state")
	second_driver.call("_update_enemy_team_tactics_state")
	var first_snapshot: Array = Array(first_driver.call("get_enemy_team_tactics_snapshot"))
	var second_snapshot: Array = Array(second_driver.call("get_enemy_team_tactics_snapshot"))
	_assert(JSON.stringify(first_snapshot) == JSON.stringify(second_snapshot), "Enemy tactics snapshots are deterministic when unit IDs and positions match")
	_cleanup_context(first_context)
	_cleanup_context(second_context)


func _build_enemy_snapshot_payload(tick: int) -> Dictionary:
	return {
		"tick": tick,
		"units": [
			{
				"unit_id": "red_a",
				"team_id": "team_bravo",
				"visible": true,
				"position": Vector2(10.0, 20.0),
				"active_weapon_id": "rifle",
				"weapon_tile_range": 25,
				"weapon_range_world": 1800.0,
				"enemy_security_group_id": "red",
				"enemy_security_mode": "directional",
				"enemy_facing_angle": 0.25,
				"enemy_tactics_group_id": "red",
				"enemy_tactic_profile_id": "aggressive_push",
				"enemy_advance_style": "push",
				"enemy_role": "point",
				"enemy_tactic_label": "PUSH M2",
				"client_recomputed_enemy_ai": true,
			}
		],
		"enemy_security": [
			{
				"security_group_id": "red",
				"team_id": "team_bravo",
				"profile_id": "aggressive_push",
				"security_mode": "directional",
				"facing_angle": 0.25,
				"sector_width": 2.2,
				"watch_label": "EN SEC DIR W1",
				"unit_ids": PackedStringArray(["red_a"]),
				"watched_unit_ids": PackedStringArray(["blue_a"]),
				"member_assignments": [{"unit_id": "red_a", "weapon_id": "rifle", "weapon_tile_range": 25, "weapon_range_world": 1800.0}],
			}
		],
		"enemy_team_tactics": [
			{
				"security_group_id": "red",
				"team_id": "team_bravo",
				"profile_id": "aggressive_push",
				"advance_style": "push",
				"cover_behavior": "cover_between_bounds",
				"tactic_label": "PUSH M2",
				"unit_ids": PackedStringArray(["red_a", "red_b"]),
				"moving_unit_ids": PackedStringArray(["red_a", "red_b"]),
				"covering_unit_ids": PackedStringArray(),
				"role_by_unit_id": {"red_a": "point", "red_b": "cover"},
				"target_positions_by_unit_id": {"red_a": Vector2(144.0, 0.0), "red_b": Vector2(144.0, 40.0)},
				"client_target_recalc": Vector2(999.0, 999.0),
			}
		],
		"fire_events": [
			{
				"event_id": "fire_test_1",
				"event_type": "weapon_fire",
				"source": "standard",
				"tick": tick,
				"sequence": 1,
				"attacker_unit_id": "red_a",
				"attacker_team_id": "team_bravo",
				"target_unit_id": "blue_a",
				"target_team_id": "team_alpha",
				"weapon_id": "rifle",
				"weapon_tile_range": 25,
				"weapon_range_world": 1800.0,
				"attacker_position": Vector2(10.0, 20.0),
				"target_position": Vector2(80.0, 20.0),
				"client_should_apply_damage": true,
			}
		],
	}


func _make_authority_context(prefix: String, deterministic_ids: bool = false) -> Dictionary:
	var root_node := Node.new()
	root_node.name = "Task204_%s" % prefix
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	root_node.add_child(unit_registry)
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	root_node.add_child(simulation_root)
	var driver: Node = MISSION_COMBAT_LOOP_DRIVER_SCRIPT.new()
	driver.name = "CombatLoopDriver"
	driver.friendly_team_id = "team_alpha"
	driver.preview_mode = true
	var friendly_id: String = "blue_a" if deterministic_ids else "%s_friendly" % prefix
	var enemy_id: String = "red_a" if deterministic_ids else "%s_enemy" % prefix
	var friendly = _make_unit(friendly_id, "team_alpha", "rifle", Vector2(500.0, 0.0))
	var enemy = _make_unit(enemy_id, "team_bravo", "rifle", Vector2.ZERO)
	enemy.set_meta("enemy_tactics_config", {
		"group_id": "red",
		"profile_id": "aggressive_push",
		"security_mode": "directional",
		"facing": "east",
		"team_id": "team_bravo",
	})
	root_node.add_child(friendly)
	root_node.add_child(enemy)
	var friendly_paths: Array[NodePath] = [NodePath("../%s" % friendly_id)]
	var enemy_paths: Array[NodePath] = [NodePath("../%s" % enemy_id)]
	driver.friendly_unit_paths = friendly_paths
	driver.enemy_unit_paths = enemy_paths
	root_node.add_child(driver)
	unit_registry.call("register_unit", friendly_id, friendly)
	unit_registry.call("register_unit", enemy_id, enemy)
	simulation_root.call("register_known_unit", friendly_id, friendly)
	simulation_root.call("register_known_unit", enemy_id, enemy)
	return {
		"root": root_node,
		"simulation_root": simulation_root,
		"driver": driver,
		"friendly": friendly,
		"enemy": enemy,
	}


func _make_unit(unit_id: String, team_id: String, weapon_id: String, position_value: Vector2) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.name = unit_id
	unit.unit_id = unit_id
	unit.display_name = unit_id
	unit.team_id = team_id
	unit.fireteam_id = "blue" if team_id == "team_alpha" else "red"
	unit.weapon_1_id = weapon_id
	unit.weapon_2_id = weapon_id
	unit.position = position_value
	unit._ready()
	return unit


func _find_unit_snapshot(snapshot: Dictionary, unit_id: String) -> Dictionary:
	for unit_variant in Array(snapshot.get("units", [])):
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit_snapshot: Dictionary = Dictionary(unit_variant)
		if String(unit_snapshot.get("unit_id", "")) == unit_id:
			return unit_snapshot
	return {}


func _cleanup_context(context: Dictionary) -> void:
	var root_node: Node = context.get("root", null)
	if root_node != null:
		root_node.free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
