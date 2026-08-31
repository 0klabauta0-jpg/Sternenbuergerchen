extends SceneTree

const TACTICAL_FRAME_HARNESS_SCRIPT: GDScript = preload("res://scripts/tests/tactical_map_frame_budget_harness.gd")
const COMBAT_FIRE_DECISION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/combat_fire_decision_resolver.gd")

var _passed: int = 0
var _failed: int = 0


class RangeCountingLos:
	extends RefCounted

	func has_line_of_sight_between_nodes(_source: Node2D, _target: Node2D, _max_range: float = -1.0, _terrain_registry = null) -> bool:
		return true


class RangeCounter:
	extends RefCounted

	var invocation_count: int = 0

	func get_weapon_attack_range(_attacker, _target) -> float:
		invocation_count += 1
		return 1024.0


class DetectionComplete:
	extends RefCounted

	func start_detection(_attacker, _attacker_id: String, _target_id: String) -> void:
		pass

	func is_complete(_attacker_id: String, _target_id: String) -> bool:
		return true

	func get_contact_state(_fireteam_id: String, _target_id: String) -> Dictionary:
		return {"detection_state": "confirmed"}


class CombatCommandStub:
	extends RefCounted

	var command_type: String = "hold_position"


class CombatUnitStub:
	extends Node2D

	var unit_id: String = ""
	var team_id: String = ""

	func _init(next_unit_id: String, next_team_id: String, next_position: Vector2) -> void:
		unit_id = next_unit_id
		team_id = next_team_id
		global_position = next_position

	func get_unit_id() -> String:
		return unit_id

	func get_team_id() -> String:
		return team_id

	func get_vital_state() -> String:
		return "fit"

	func get_active_weapon_id() -> String:
		return "rifle"

	func get_current_unit_command() -> CombatCommandStub:
		return CombatCommandStub.new()

	func get_fireteam_id() -> String:
		return "alpha"


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1194 Tactical Performance Budget Reduction ===")
	_test_fire_pair_search_resolves_weapon_range_once_per_attacker()
	await _test_report_exposes_real_combat_and_simulation_subscopes()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_report_exposes_real_combat_and_simulation_subscopes() -> void:
	var report: Dictionary = await TACTICAL_FRAME_HARNESS_SCRIPT.new().run(self, {
		"warmup_ticks": 0,
		"physics_ticks": 4,
		"minimum_process_frames": 1,
		"minimum_process_duration_msec": 0,
		"combat_fixture_repetitions": 1,
	})
	var scopes: Dictionary = Dictionary(report.get("scopes", {}))
	var combat_fire_decision: Dictionary = Dictionary(scopes.get("combat_scope.combat_fire_decision_usec", {}))
	var combat_fire_pair_search: Dictionary = Dictionary(scopes.get("combat_scope.fire_find_contact_pair_usec", {}))
	var simulation_tick_signal: Dictionary = Dictionary(scopes.get("simulation_scope.tick_signal_emit_usec", {}))
	var lz_ui_refresh_count: Dictionary = Dictionary(scopes.get("interaction.lz_input_ui_refresh_count", {}))
	var lz_ui_refresh_p99: int = int(lz_ui_refresh_count.get("p99", -1))
	_assert(int(combat_fire_decision.get("invocation_count", 0)) > 0, "Report exposes real combat fire-decision samples")
	_assert(int(combat_fire_pair_search.get("invocation_count", 0)) > 0, "Report exposes real combat fire pair-search samples")
	_assert(int(simulation_tick_signal.get("invocation_count", 0)) > 0, "Report exposes real SimulationRoot tick-signal samples")
	_assert(lz_ui_refresh_p99 == 1, "Arming a Dropship LZ performs exactly one UI refresh (observed: %d)" % lz_ui_refresh_p99)


func _test_fire_pair_search_resolves_weapon_range_once_per_attacker() -> void:
	var attacker := CombatUnitStub.new("friendly_alpha", "team_alpha", Vector2.ZERO)
	var targets: Array = [
		CombatUnitStub.new("enemy_near", "team_bravo", Vector2(100.0, 0.0)),
		CombatUnitStub.new("enemy_mid", "team_bravo", Vector2(200.0, 0.0)),
		CombatUnitStub.new("enemy_far", "team_bravo", Vector2(300.0, 0.0)),
	]
	var range_counter := RangeCounter.new()
	var detection := DetectionComplete.new()
	var pair: Dictionary = Dictionary(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("find_first_contact_pair", {
		"friendly_units": [attacker],
		"enemy_units": targets,
		"friendly_team_id": "team_alpha",
		"cache_effective_attack_range_by_attacker": true,
		"los_system": RangeCountingLos.new(),
		"get_weapon_attack_range": Callable(range_counter, "get_weapon_attack_range"),
		"start_detection": Callable(detection, "start_detection"),
		"is_detection_complete": Callable(detection, "is_complete"),
		"get_contact_state": Callable(detection, "get_contact_state"),
	}))
	attacker.free()
	for target_variant in targets:
		(target_variant as Node).free()
	_assert(String(pair.get("target_id", "")) == "enemy_near", "Fire pair search keeps the highest-ranked target after range caching")
	_assert(range_counter.invocation_count == 1, "Fire pair search resolves each attacker's weapon range once (observed: %d)" % range_counter.invocation_count)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
