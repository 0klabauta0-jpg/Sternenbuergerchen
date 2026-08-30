extends SceneTree

const FLANK_VULNERABILITY_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/flank_vulnerability_resolver.gd")
const FIRETEAM_SECURITY_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_security_controller.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const EVENT_ROUTER_SCRIPT: GDScript = preload("res://scripts/core/event_router.gd")

var _passed: int = 0
var _failed: int = 0


class TerrainRegistryStub:
	extends Node
	var cover_by_unit_id: Dictionary = {}

	func get_cover_at_world(world_position: Vector2) -> int:
		return int(cover_by_unit_id.get(_build_key(world_position), 0))

	func get_height_at_world(_world_position: Vector2) -> int:
		return 0

	func _build_key(world_position: Vector2) -> String:
		return "%.1f:%.1f" % [world_position.x, world_position.y]


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_113 Flank Vulnerability Verifier ===")
	_test_resolver_detects_directional_flank_and_bonuses()
	_test_resolver_ignores_360_security()
	_test_resolver_tracks_direction_and_escalates_morale()
	await _test_active_flank_state_expires_after_duration()
	await _test_simulation_root_respects_cover_override_in_flank_damage()
	await _test_scene_proxies_active_flank_state_to_tactical_controller()
	_test_event_router_exposes_flank_signal_contract()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit(1 if _failed > 0 else 0)
func _test_resolver_detects_directional_flank_and_bonuses() -> void:
	var resolver = FLANK_VULNERABILITY_RESOLVER_SCRIPT.new()
	var security_controller = FIRETEAM_SECURITY_CONTROLLER_SCRIPT.new()
	var leader = _make_unit("flank_lead", "blue", true, Vector2(0.0, 0.0), 0.45, 0.65, 0.35, ["aggressive"], "team_alpha")
	var wing = _make_unit("flank_wing", "blue", false, Vector2(10.0, 10.0), 0.52, 0.55, 0.3, [], "team_alpha")
	var suspected_contact := {
		"fireteam_id": "blue",
		"unit_id": "enemy_hint",
		"team_id": "team_bravo",
		"last_known_position": Vector2(120.0, 0.0),
		"detection_state": "suspected",
		"detected_by": ["blue"],
		"last_updated_tick": 2,
	}
	var security_state: Dictionary = security_controller.update_fireteam_state("blue", [leader, wing], leader, _build_behavior_profile("hold_position"), {}, {}, {}, [suspected_contact])
	var attacker = _make_unit("enemy_rear", "enemy", false, Vector2(-120.0, 0.0), 0.5, 0.5, 0.2, [], "team_bravo")
	var result: Dictionary = resolver.resolve_attack("blue", attacker, leader, security_state, 10)
	_assert(bool(result.get("is_flank", false)), "Directional security marks rear-angle attacks as flank hits")
	_assert(is_equal_approx(float(result.get("hit_chance_bonus", 0.0)), 0.2), "Flank hits grant the configured hit chance bonus")
	_assert(is_equal_approx(float(result.get("damage_multiplier", 0.0)), 1.3), "Flank hits grant the configured damage multiplier")
	_assert(is_equal_approx(float(result.get("target_cover_override", -1.0)), 0.0), "Flank hits override target cover down to zero")
	_assert(String(result.get("direction_label", "")) == "rear", "Rear-angle flank hits expose the relative attack direction for follow-up systems")
	_assert(String(result.get("morale_state", "")) == "shaken", "Rear-angle flank hits immediately escalate the defending fireteam into a shaken morale state")
	_cleanup_units([leader, wing, attacker])


func _test_resolver_ignores_360_security() -> void:
	var resolver = FLANK_VULNERABILITY_RESOLVER_SCRIPT.new()
	var security_controller = FIRETEAM_SECURITY_CONTROLLER_SCRIPT.new()
	var leader = _make_unit("secure_lead", "gold", true, Vector2(0.0, 0.0), 0.45, 0.65, 0.85, ["steady"], "team_alpha")
	var wing = _make_unit("secure_wing", "gold", false, Vector2(10.0, 10.0), 0.52, 0.55, 0.3, [], "team_alpha")
	var security_state: Dictionary = security_controller.update_fireteam_state("gold", [leader, wing], leader, _build_behavior_profile("hold_position"), {}, {}, {}, [])
	var attacker = _make_unit("enemy_rear_360", "enemy", false, Vector2(-140.0, 0.0), 0.5, 0.5, 0.2, [], "team_bravo")
	var result: Dictionary = resolver.resolve_attack("gold", attacker, leader, security_state, 5)
	_assert(result.is_empty(), "360 security prevents flank vulnerability entirely")
	_cleanup_units([leader, wing, attacker])


func _test_active_flank_state_expires_after_duration() -> void:
	var resolver = FLANK_VULNERABILITY_RESOLVER_SCRIPT.new()
	var security_controller = FIRETEAM_SECURITY_CONTROLLER_SCRIPT.new()
	var leader = _make_unit("expire_lead", "blue", true, Vector2(0.0, 0.0), 0.45, 0.65, 0.35, ["aggressive"], "team_alpha")
	var wing = _make_unit("expire_wing", "blue", false, Vector2(10.0, 10.0), 0.52, 0.55, 0.3, [], "team_alpha")
	var security_state: Dictionary = security_controller.update_fireteam_state("blue", [leader, wing], leader, _build_behavior_profile("hold_position"), {}, {}, {}, [_build_confirmed_contact("blue", Vector2(120.0, 0.0))])
	var attacker = _make_unit("enemy_expire", "enemy", false, Vector2(-140.0, 0.0), 0.5, 0.5, 0.2, [], "team_bravo")
	resolver.resolve_attack("blue", attacker, leader, security_state, 12)
	var active_state: Dictionary = resolver.get_fireteam_state("blue", 12)
	var expiry_tick: int = int(active_state.get("expires_at_tick", 12))
	var morale_expiry_tick: int = int(active_state.get("morale_expires_at_tick", expiry_tick))
	var changed: bool = bool(resolver.advance(expiry_tick + 1))
	var post_flank_state: Dictionary = resolver.get_fireteam_state("blue", expiry_tick + 1)
	var cleared: bool = bool(resolver.advance(morale_expiry_tick + 1))
	var expired_state: Dictionary = resolver.get_fireteam_state("blue", morale_expiry_tick + 1)
	_assert(bool(active_state.get("is_active", false)), "Resolver stores an active vulnerability window after a flank hit")
	_assert(changed and not bool(post_flank_state.get("is_active", false)) and bool(post_flank_state.get("is_morale_active", false)), "Flank vulnerability can expire while the follow-up morale pressure remains briefly active")
	_assert(cleared and expired_state.is_empty(), "Directional morale pressure also expires cleanly after its longer follow-up window")
	_cleanup_units([leader, wing, attacker])


func _test_resolver_tracks_direction_and_escalates_morale() -> void:
	var resolver = FLANK_VULNERABILITY_RESOLVER_SCRIPT.new()
	var security_controller = FIRETEAM_SECURITY_CONTROLLER_SCRIPT.new()
	var leader = _make_unit("side_lead", "blue", true, Vector2(0.0, 0.0), 0.45, 0.65, 0.35, ["aggressive"], "team_alpha")
	var wing = _make_unit("side_wing", "blue", false, Vector2(10.0, 10.0), 0.52, 0.55, 0.3, [], "team_alpha")
	var security_state: Dictionary = security_controller.update_fireteam_state("blue", [leader, wing], leader, _build_behavior_profile("hold_position"), {}, {}, {}, [_build_confirmed_contact("blue", Vector2(120.0, 0.0))])
	var attacker = _make_unit("enemy_left_flank", "enemy", false, Vector2(-60.0, -120.0), 0.5, 0.5, 0.2, [], "team_bravo")
	var first_result: Dictionary = resolver.resolve_attack("blue", attacker, leader, security_state, 20)
	var second_result: Dictionary = resolver.resolve_attack("blue", attacker, leader, security_state, 21)
	_assert(String(first_result.get("direction_label", "")) == "left", "Off-axis flank hits keep their relative left/right direction instead of collapsing everything into rear")
	_assert(String(first_result.get("morale_state", "")) == "alerted", "A single side flank first creates a lighter alerted morale memory")
	_assert(String(second_result.get("morale_state", "")) == "shaken", "Repeated flank pressure escalates the morale state to shaken")
	_assert(bool(second_result.get("morale_triggered_now", false)), "Crossing into the shaken state is exposed as an explicit transition for UI/debug follow-up")
	_cleanup_units([leader, wing, attacker])


func _test_simulation_root_respects_cover_override_in_flank_damage() -> void:
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	var terrain_registry = TerrainRegistryStub.new()
	unit_registry.name = "UnitRegistry"
	terrain_registry.name = "TerrainRegistry"
	simulation_root.add_child(unit_registry)
	simulation_root.add_child(terrain_registry)
	simulation_root.unit_registry_path = NodePath("UnitRegistry")
	simulation_root.terrain_registry_path = NodePath("TerrainRegistry")
	root.add_child(simulation_root)
	var attacker = _make_unit("sim_attacker", "enemy", false, Vector2(0.0, 0.0), 0.5, 0.5, 0.2, [], "team_bravo")
	var target = _make_unit("sim_target", "blue", true, Vector2(30.0, 0.0), 0.5, 0.5, 0.6, [], "team_alpha")
	target.call("set_runtime_status", "holding", "hold_position", 0, "fire_at_will", "defend", 1.0, 32.0, 0.0, 1, target.global_position)
	unit_registry.register_unit("sim_attacker", attacker)
	unit_registry.register_unit("sim_target", target)
	terrain_registry.cover_by_unit_id[terrain_registry._build_key(target.global_position)] = 24
	simulation_root.call(
		"_apply_damage_effect",
		{
			"effect_type": "damage",
			"unit_id": "sim_target",
			"attacker_unit_id": "sim_attacker",
			"attacker_team_id": "team_bravo",
			"damage": 10,
			"hit_chance": 1.0,
			"damage_multiplier": 1.0,
			"roll_override": 0.0,
			"target_cover_override": 0.0,
			"is_flank": true,
			"flank_fireteam_id": "blue",
			"flank_source_angle": PI,
			"flank_direction_label": "rear",
			"flank_morale_state": "shaken",
		}
	)
	var hit_context: Dictionary = target.call("get_last_damage_context")
	_assert(is_equal_approx(float(hit_context.get("target_cover_score", -1.0)), 0.0), "SimulationRoot applies flank cover override through the authoritative damage path")
	_assert(bool(hit_context.get("is_flank", false)), "Flank hits are annotated in the damage hit context for downstream systems")
	_assert(String(hit_context.get("flank_direction_label", "")) == "rear", "SimulationRoot preserves flank direction labels in the authoritative hit context")
	_assert(String(hit_context.get("flank_morale_state", "")) == "shaken", "SimulationRoot preserves flank morale state in the authoritative hit context")
	simulation_root.queue_free()
	_cleanup_units([attacker, target])
	await process_frame


func _test_scene_proxies_active_flank_state_to_tactical_controller() -> void:
	var scene = await _load_scene()
	var tactical_controller = scene.get_node("TacticalController")
	var combat_driver = scene.get_node("CombatLoopDriver")
	var started: bool = tactical_controller.call("advance_to_next_phase")
	for _index in range(6):
		await process_frame
	tactical_controller.call("refresh_fireteam_security_state")
	var security_snapshot: Array = Array(tactical_controller.call("get_fireteam_security_snapshot"))
	var selected_state: Dictionary = {}
	var selected_fireteam_id: String = ""
	for state_variant in security_snapshot:
		var state: Dictionary = Dictionary(state_variant)
		if not state.is_empty():
			selected_state = state
			selected_fireteam_id = String(state.get("fireteam_id", ""))
			break
	var friendlies: Array = Array(tactical_controller.call("_get_fireteam_units", selected_fireteam_id, false))
	var enemies: Array = Array(tactical_controller.call("_get_all_enemy_units", false))
	var result: Dictionary = {}
	if not selected_state.is_empty() and not friendlies.is_empty() and not enemies.is_empty():
		var anchor_position: Vector2 = Vector2(selected_state.get("anchor_position", Vector2.ZERO))
		var direction_angle: float = ((enemies[0] as Node2D).global_position - anchor_position).angle()
		var forced_directional_state: Dictionary = selected_state.duplicate(true)
		forced_directional_state["security_mode"] = "directional"
		forced_directional_state["direction_angle"] = direction_angle
		var assignments: Array = []
		for friendly_variant in friendlies:
			if friendly_variant == null or not friendly_variant.has_method("get_unit_id"):
				continue
			assignments.append(
				{
					"unit_id": String(friendly_variant.call("get_unit_id")),
					"center_angle": direction_angle,
					"arc_width": PI * 0.7,
				}
			)
		forced_directional_state["member_assignments"] = assignments
		var attacker_position: Vector2 = anchor_position + Vector2.RIGHT.rotated(direction_angle + PI) * 120.0
		(enemies[0] as Node2D).global_position = attacker_position
		result = Dictionary(combat_driver.call("resolve_flank_attack_with_state", selected_fireteam_id, enemies[0], friendlies[0], forced_directional_state))
	var tactical_snapshot: Array = Array(tactical_controller.call("get_flank_vulnerability_snapshot"))
	var combat_snapshot: Array = Array(combat_driver.call("get_flank_vulnerability_snapshot"))
	var proxied_state: Dictionary = Dictionary(tactical_controller.call("get_fireteam_flank_vulnerability_state", selected_fireteam_id))
	_assert(started, "Mission scene starts successfully for flank integration")
	_assert(not selected_state.is_empty(), "Mission scene exposes active security state for flank integration")
	_assert(bool(result.get("is_flank", false)), "Combat loop can trigger flank vulnerability from a rear directional attack in scene context")
	_assert(not tactical_snapshot.is_empty(), "Tactical controller proxies active flank vulnerability snapshots")
	_assert(JSON.stringify(tactical_snapshot) == JSON.stringify(combat_snapshot), "Tactical controller flank snapshot matches the combat-loop source")
	_assert(String(proxied_state.get("direction_label", "")) == "rear", "Tactical controller proxies the relative flank direction into the mission status layer")
	_assert(String(proxied_state.get("morale_state", "")) == "shaken", "Tactical controller proxies the follow-up morale state into the mission status layer")
	scene.queue_free()
	await process_frame


func _test_event_router_exposes_flank_signal_contract() -> void:
	var event_router = EVENT_ROUTER_SCRIPT.new()
	_assert(event_router.has_signal("flank_vulnerability_triggered"), "EventRouter exposes a flank_vulnerability_triggered signal contract")
	event_router.free()


func _build_behavior_profile(command_type: String) -> Dictionary:
	return {
		"fireteam_id": "blue",
		"metadata": {
			"origin_command_type": command_type,
			"origin": "standard_behavior",
		},
	}


func _build_confirmed_contact(fireteam_id: String, position_value: Vector2) -> Dictionary:
	return {
		"fireteam_id": fireteam_id,
		"unit_id": "enemy_contact",
		"team_id": "team_bravo",
		"last_known_position": position_value,
		"detection_state": "confirmed",
		"detected_by": [fireteam_id],
		"last_updated_tick": 4,
	}


func _make_unit(unit_id: String, fireteam_id: String, is_lead: bool, position_value: Vector2, speed: float, accuracy: float, leadership: float, traits: Array, team_id: String) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.display_name = unit_id
	unit.team_id = team_id
	unit.fireteam_id = fireteam_id
	unit.is_fireteam_lead = is_lead
	unit.skill_speed = speed
	unit.skill_accuracy = accuracy
	unit.skill_leadership = leadership
	unit.skill_toughness = 0.55
	unit.trait_ids = PackedStringArray(traits)
	unit.position = position_value
	unit._ready()
	root.add_child(unit)
	return unit


func _cleanup_units(units: Array) -> void:
	for unit in units:
		if unit != null:
			unit.queue_free()


func _load_scene() -> Node:
	var scene = load("res://scenes/tests/mission_reactivity_test.tscn").instantiate()
	root.add_child(scene)
	for _index in range(10):
		await process_frame
	return scene


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
