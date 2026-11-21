extends SceneTree
## Auftrag 2: Der Wachmann von outpost_recovery trifft schlecht (skill_accuracy 0.0 an der Gegnergruppe).
## (a) echter Weg: mission_test_setup._apply_authored_enemy_loadout mit der echten Szenariodatei,
## (b) Gegenprobe: Wachen von outpost_chip_recovery und ein Szenario ohne das Feld bleiben unberuehrt,
## (c) echte Trefferrechnung (SimulationRoot._apply_damage_effect, deterministisch),
## (d) Validierung der neuen Felder skill_accuracy und completion_loot.

const SCENARIO_GUARD := "res://data/mission_scenarios/outpost_recovery.json"
const SCENARIO_CHIP := "res://data/mission_scenarios/outpost_chip_recovery.json"
const SCENARIO_NO_FIELD := "res://data/mission_scenarios/satellite_recovery.json"
const DATA_SCRIPT := preload("res://scripts/mission/mission_scenario_data.gd")
const SETUP_SCRIPT := preload("res://scripts/tests/mission_test_setup.gd")
const TEST_UNIT_SCRIPT := preload("res://scripts/npc/test_unit.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const EPS := 0.0001
const INPUT := 0.4
const TILE := 72.0

var _passed := 0
var _failed := 0
var _root: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_root = Node.new()
	get_root().add_child(_root)
	_test_guard_identity()
	_test_other_enemies_untouched()
	_test_hit_chance()
	_test_validation()
	_root.free()
	print("OUTPOST_RECOVERY_GUARD passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		print("FAIL: %s" % message)


func _applied_unit(scenario_path: String, enemy_id: String, sentinel_accuracy: float) -> Node:
	var setup = SETUP_SCRIPT.new()
	setup.set("_mission_scenario", DATA_SCRIPT.load_from_file(scenario_path))
	var unit: Node = TEST_UNIT_SCRIPT.new()
	unit.set("unit_id", enemy_id)
	unit.set("team_id", "team_bravo")
	_root.add_child(unit)
	unit.call("apply_identity_config", {"skill_accuracy": sentinel_accuracy})
	setup.call("_apply_authored_enemy_loadout", unit, enemy_id, "team_bravo")
	setup.free()
	return unit


func _test_guard_identity() -> void:
	var unit := _applied_unit(SCENARIO_GUARD, "outpost_recovery_guard_01", 0.3)
	_assert(is_equal_approx(float(unit.call("get_accuracy_skill")), 0.0), "Wachmann von outpost_recovery hat Genauigkeit 0.0")
	_assert(int(unit.call("get_max_health_points")) == 100 and int(unit.call("get_health")) == 100, "Trefferpunkte wie bisher (100)")
	_assert(String(unit.call("get_weapon_1_id")) == "pistol", "Waffe wie bisher (Pistole)")
	_assert(is_equal_approx(float(unit.call("get_toughness_skill")), 0.5), "Zaehigkeit unveraendert (nur Genauigkeit wird gesetzt)")
	unit.free()


func _test_other_enemies_untouched() -> void:
	for enemy_id in ["outpost_chip_recovery_guard_01", "outpost_chip_recovery_guard_02"]:
		var unit := _applied_unit(SCENARIO_CHIP, enemy_id, 0.45)
		_assert(is_equal_approx(float(unit.call("get_accuracy_skill")), 0.45), "%s behaelt seine Genauigkeit" % enemy_id)
		unit.free()
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SCENARIO_NO_FIELD))
	var groups: Array = Array(raw.get("enemy_groups", []))
	if groups.is_empty() or Array(Dictionary(groups[0]).get("enemy_ids", [])).is_empty():
		_assert(true, "Szenario ohne Gegnergruppe (nichts zu pruefen)")
	else:
		var enemy_id := String(Array(Dictionary(groups[0]).get("enemy_ids", []))[0])
		var no_field_unit := _applied_unit(SCENARIO_NO_FIELD, enemy_id, 0.45)
		_assert(is_equal_approx(float(no_field_unit.call("get_accuracy_skill")), 0.45), "Gegner eines Szenarios ohne das Feld behaelt seine Genauigkeit")
		no_field_unit.free()
	for path in [SCENARIO_CHIP, SCENARIO_NO_FIELD]:
		_assert(not FileAccess.get_file_as_string(path).contains("skill_accuracy"), "%s traegt das Feld nicht" % path.get_file())


func _shot_chance(attacker: Node2D, target: Node2D, simulation: Node, captured: Array) -> float:
	captured.clear()
	simulation.call("_apply_damage_effect", {
		"effect_type": "damage",
		"unit_id": target.get_unit_id(),
		"attacker_unit_id": attacker.get_unit_id(),
		"attacker_team_id": attacker.get_team_id(),
		"weapon_id": "pistol",
		"damage": 1,
		"hit_chance": INPUT,
		"damage_multiplier": 1.0,
		"target_cover_override": 0.0,
		"roll_override": 0.0,
	})
	return float(Dictionary(captured[0]).get("hit_chance_resolved", -1.0)) if not captured.is_empty() else -1.0


func _test_hit_chance() -> void:
	var registry = UNIT_REGISTRY_SCRIPT.new()
	registry.name = "UnitRegistry"
	_root.add_child(registry)
	var simulation = SIMULATION_ROOT_SCRIPT.new()
	simulation.name = "SimulationRoot"
	simulation.unit_registry_path = NodePath("../UnitRegistry")
	_root.add_child(simulation)
	simulation.set_combat_rng_seed(7)
	var guard := _applied_unit(SCENARIO_GUARD, "outpost_recovery_guard_01", 0.3) as Node2D
	var reference := _applied_unit(SCENARIO_CHIP, "outpost_chip_recovery_guard_01", 0.3) as Node2D
	reference.set("unit_id", "reference_scout")
	reference.call("apply_identity_config", {"weapon_1_id": "pistol", "weapon_2_id": "none"})
	var target: Node2D = TEST_UNIT_SCRIPT.new()
	target.set("unit_id", "fixed_target")
	target.set("team_id", "team_alpha")
	_root.add_child(target)
	target.global_position = Vector2(4.0 * TILE, 0.0)
	guard.global_position = Vector2.ZERO
	reference.global_position = Vector2.ZERO
	for unit in [guard, reference, target]:
		registry.call("register_unit", unit.get_unit_id(), unit)
	var captured: Array = []
	simulation.damage_effect_resolved.connect(func(result: Dictionary) -> void: captured.append(result))
	var guard_chance := _shot_chance(guard, target, simulation, captured)
	var reference_chance := _shot_chance(reference, target, simulation, captured)
	_assert(guard_chance > 0.0 and reference_chance > 0.0, "beide Schuesse ueber die echte Trefferrechnung aufgeloest")
	_assert(guard_chance < reference_chance, "Wachmann trifft schlechter als ein Gegner mit Genauigkeit 0.3 (%.3f < %.3f)" % [guard_chance, reference_chance])
	var mult_guard := float(guard.call("get_combat_hit_chance_multiplier"))
	var mult_reference := float(reference.call("get_combat_hit_chance_multiplier"))
	_assert(absf(mult_guard - 0.5) < EPS, "Fertigkeitsmultiplikator des Wachmanns ist 0.5 (0.5 + 0.0), ist %.3f" % mult_guard)
	var expected_delta := INPUT * (mult_guard - mult_reference)
	_assert(absf((guard_chance - reference_chance) - expected_delta) < EPS, "Unterschied entspricht der Formel Eingang x Multiplikator-Differenz (%.4f, erwartet %.4f)" % [guard_chance - reference_chance, expected_delta])
	for unit in [guard, reference, target]:
		unit.free()


func _scenario_dict() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(SCENARIO_GUARD))


func _errors_for(data: Dictionary) -> PackedStringArray:
	var scenario = DATA_SCRIPT.from_dict(data)
	return PackedStringArray(Dictionary(scenario.call("validate")).get("errors", PackedStringArray()))


func _with_accuracy(value: Variant) -> Dictionary:
	var data := _scenario_dict()
	var groups: Array = data.enemy_groups
	Dictionary(groups[0])["skill_accuracy"] = value
	return data


func _with_loot(value: Variant) -> Dictionary:
	var data := _scenario_dict()
	data["completion_loot"] = value
	return data


func _has_error(errors: PackedStringArray, needle: String) -> bool:
	for error in errors:
		if String(error).contains(needle):
			return true
	return false


func _test_validation() -> void:
	_assert(_errors_for(_scenario_dict()).is_empty(), "echte Szenariodatei validiert ohne Fehler")
	for bad in [-0.1, 1.5, "x"]:
		_assert(_has_error(_errors_for(_with_accuracy(bad)), "skill_accuracy"), "skill_accuracy %s wird abgelehnt" % str(bad))
	for good in [0.0, 0.5, 1.0]:
		_assert(not _has_error(_errors_for(_with_accuracy(good)), "skill_accuracy"), "skill_accuracy %s wird angenommen" % str(good))
	var round_trip = DATA_SCRIPT.from_dict(_scenario_dict())
	var out_groups: Array = round_trip.call("to_dict").enemy_groups
	_assert(is_equal_approx(float(Dictionary(out_groups[0]).get("skill_accuracy", -1.0)), 0.0), "skill_accuracy ueberlebt Laden und Speichern")
	var ok_loot := [{"item_id": "armor_light", "quantity": 1}, {"item_id": "smg", "quantity": 1}]
	_assert(not _has_error(_errors_for(_with_loot(ok_loot)), "completion_loot"), "gueltige completion_loot wird angenommen")
	_assert(_has_error(_errors_for(_with_loot([{"item_id": "gibt_es_nicht", "quantity": 1}])), "completion_loot"), "unbekannte item_id wird abgelehnt")
	_assert(_has_error(_errors_for(_with_loot([{"item_id": "smg", "quantity": 0}])), "completion_loot"), "Menge 0 wird abgelehnt")
	_assert(_has_error(_errors_for(_with_loot([{"item_id": "smg", "quantity": 1.5}])), "completion_loot"), "gebrochene Menge wird abgelehnt")
	_assert(_has_error(_errors_for(_with_loot("armor_light")), "completion_loot"), "Nicht-Liste wird abgelehnt")
	_assert(_has_error(_errors_for(_with_loot([5])), "completion_loot"), "Eintrag ohne Objekt wird abgelehnt")
	var loot_round = DATA_SCRIPT.from_dict(_with_loot(ok_loot))
	_assert(Array(loot_round.call("to_dict").get("completion_loot", [])).size() == 2, "completion_loot ueberlebt Laden und Speichern")
