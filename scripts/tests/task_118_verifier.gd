extends SceneTree

const MEDIC_SUPPORT_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/medic_support_resolver.gd")
const COMBAT_FIRE_DECISION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/combat_fire_decision_resolver.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0
var _contact_state_by_key: Dictionary = {}
var _discipline_break_checks: int = 0


class LosAlways:
	extends RefCounted

	func has_line_of_sight_between_nodes(_attacker, _target, _range: float, _terrain_registry = null) -> bool:
		return true


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_118 Combat Resolver Verifier ===")
	_test_medic_resolver_returns_heal_and_move_actions()
	_test_discipline_break_waits_for_attackable_target()
	_test_fire_resolver_requires_contact_gate_for_friendlies()
	_test_fire_resolver_builds_damage_effect_with_modifiers()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit(1 if _failed > 0 else 0)
func _test_medic_resolver_returns_heal_and_move_actions() -> void:
	var medic := _make_unit("medic_resolver", "team_alpha", "blue", Vector2.ZERO, "Combat Medic")
	medic.weapon_2_id = "medictool"
	var patient_near := _make_unit("patient_near", "team_alpha", "blue", Vector2(24.0, 0.0), "Operator")
	patient_near.apply_damage(patient_near.get_max_health_points())
	var actions: Array = Array(
		MEDIC_SUPPORT_RESOLVER_SCRIPT.call(
			"build_support_actions",
			[medic],
			[medic, patient_near],
			{},
			{},
			{},
			null,
			1,
			{"range_fallback_world": 144.0, "move_max_distance_fallback_world": 216.0}
		)
	)
	_assert(actions.size() == 1 and String(Dictionary(actions[0]).get("action_type", "")) == "heal", "Medic resolver emits a heal action for nearby downed allies")
	_assert(String(Dictionary(actions[0]).get("target_id", "")) == "patient_near", "Medic resolver chooses the downed patient as heal target")

	var patient_far := _make_unit("patient_far", "team_alpha", "blue", Vector2(190.0, 0.0), "Operator")
	patient_far.apply_damage(patient_far.get_max_health_points())
	actions = Array(
		MEDIC_SUPPORT_RESOLVER_SCRIPT.call(
			"build_support_actions",
			[medic],
			[medic, patient_far],
			{},
			{},
			{},
			null,
			1,
			{"range_fallback_world": 144.0, "move_max_distance_fallback_world": 216.0}
		)
	)
	_assert(actions.size() == 1 and String(Dictionary(actions[0]).get("action_type", "")) == "move", "Medic resolver emits a move action for urgent out-of-range allies")
	medic.free()
	patient_near.free()
	patient_far.free()


func _test_discipline_break_waits_for_attackable_target() -> void:
	var friendly := _make_unit("friendly_holdfire", "team_alpha", "blue", Vector2.ZERO, "Operator")
	friendly.call("set_runtime_status", "engaging", "", 0, "hold_fire")
	_discipline_break_checks = 0
	var context: Dictionary = _build_fire_context([friendly], [])
	context["check_discipline_break"] = Callable(self, "_count_discipline_break")
	var contact_pair: Dictionary = Dictionary(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("find_first_contact_pair", context))
	_assert(contact_pair.is_empty() and _discipline_break_checks == 0, "Hold-fire discipline break is not checked without an attackable target")
	friendly.free()


func _test_fire_resolver_requires_contact_gate_for_friendlies() -> void:
	var friendly := _make_unit("friendly_firegate", "team_alpha", "blue", Vector2.ZERO, "Operator")
	var enemy := _make_unit("enemy_firegate", "team_bravo", "red", Vector2(32.0, 0.0), "Operator")
	enemy.weapon_1_id = "medictool"
	enemy.weapon_2_id = "medictool"
	friendly.call("set_runtime_status", "engaging")
	_contact_state_by_key = {"blue:enemy_firegate": {"detection_state": "suspected"}}
	var contact_pair: Dictionary = Dictionary(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("find_first_contact_pair", _build_fire_context([friendly], [enemy])))
	_assert(contact_pair.is_empty(), "Fire resolver blocks friendly attacks until contact is spotted or confirmed")
	_contact_state_by_key = {"blue:enemy_firegate": {"detection_state": "spotted"}}
	contact_pair = Dictionary(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("find_first_contact_pair", _build_fire_context([friendly], [enemy])))
	_assert(String(contact_pair.get("attacker_id", "")) == "friendly_firegate", "Fire resolver allows spotted contacts through the friendly fire gate")
	friendly.free()
	enemy.free()


func _test_fire_resolver_builds_damage_effect_with_modifiers() -> void:
	var attacker := _make_unit("attacker_mod", "team_alpha", "blue", Vector2.ZERO, "Operator")
	var target := _make_unit("target_mod", "team_bravo", "red", Vector2(32.0, 0.0), "Operator")
	attacker.call("set_runtime_status", "engaging")
	var contact_pair := {
		"attacker": attacker,
		"target": target,
		"attacker_id": "attacker_mod",
		"target_id": "target_mod",
		"contact_state": "spotted",
	}
	var context: Dictionary = _build_fire_context([attacker], [target])
	context["resolve_flank_attack"] = Callable(self, "_resolve_test_flank")
	context["spotted_contact_hit_chance_malus"] = -0.15
	var decision: Dictionary = Dictionary(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("build_damage_effect", contact_pair, context))
	var effect: Dictionary = Dictionary(decision.get("effect", {}))
	_assert(String(effect.get("effect_type", "")) == "damage", "Fire resolver returns an authoritative damage effect payload")
	_assert(String(effect.get("unit_id", "")) == "target_mod", "Fire resolver addresses the selected target in the damage effect")
	_assert(bool(effect.get("is_flank", false)), "Fire resolver preserves flank modifier state in the damage effect")
	_assert(effect.get("target_cover_override", null) == 0.0, "Fire resolver carries flank cover override into the effect payload")
	attacker.free()
	target.free()


func _build_fire_context(friendly_units: Array, enemy_units: Array) -> Dictionary:
	return {
		"friendly_team_id": "team_alpha",
		"friendly_units": friendly_units,
		"enemy_units": enemy_units,
		"los_system": LosAlways.new(),
		"terrain_registry": null,
		"contact_range": 180.0,
		"base_damage_multiplier": 1.0,
		"check_discipline_break": Callable(self, "_return_false"),
		"start_detection": Callable(self, "_noop_detection"),
		"is_detection_complete": Callable(self, "_return_true_ids"),
		"get_contact_state": Callable(self, "_get_test_contact_state"),
		"check_misidentification": Callable(self, "_empty_misidentification"),
		"resolve_flank_attack": Callable(self, "_empty_flank"),
		"get_effective_range": Callable(self, "_test_effective_range"),
	}


func _make_unit(unit_id: String, team_id: String, fireteam_id: String, position: Vector2, role_name: String) -> Node2D:
	var unit: Node2D = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.team_id = team_id
	unit.fireteam_id = fireteam_id
	unit.role_name = role_name
	unit.global_position = position
	return unit


func _get_test_contact_state(fireteam_id: String, enemy_unit_id: String) -> Dictionary:
	return Dictionary(_contact_state_by_key.get("%s:%s" % [fireteam_id, enemy_unit_id], {}))


func _resolve_test_flank(_attacker, _target) -> Dictionary:
	return {
		"is_flank": true,
		"hit_chance_bonus": 0.2,
		"damage_multiplier": 1.3,
		"target_cover_override": 0.0,
		"fireteam_id": "red",
		"source_angle": 1.0,
		"direction_label": "rear",
		"morale_state": "shaken",
	}


func _empty_flank(_attacker, _target) -> Dictionary:
	return {}


func _empty_misidentification(_attacker, _attacker_id: String) -> Dictionary:
	return {}


func _noop_detection(_attacker, _attacker_id: String, _target_id: String) -> void:
	pass


func _return_true_ids(_attacker_id: String, _target_id: String) -> bool:
	return true


func _return_false(_unit) -> bool:
	return false


func _count_discipline_break(_unit) -> bool:
	_discipline_break_checks += 1
	return true


func _test_effective_range(_target) -> float:
	return 180.0


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
