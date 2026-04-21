extends SceneTree

const LOADOUT_MODIFIER_RESOLVER_SCRIPT: GDScript = preload("res://scripts/command/loadout_modifier_resolver.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_107 Loadout Modifier Verifier ===")
	_test_resolver_builds_modifier_dict()
	_test_resolver_supports_special_aliases()
	_test_testunit_applies_modifiers_to_combat_effects()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_resolver_builds_modifier_dict() -> void:
	var resolver = LOADOUT_MODIFIER_RESOLVER_SCRIPT.new()
	var modifiers_by_unit: Dictionary = resolver.resolve_for_member_loadouts(
		{
			"unit_alpha": {"weapon_1": "smg", "weapon_2": "rifle", "armor": "light"},
		}
	)
	_assert(modifiers_by_unit.has("unit_alpha"), "resolver builds modifiers for staged unit")
	var unit_mods: Dictionary = Dictionary(modifiers_by_unit.get("unit_alpha", {}))
	_assert(String(unit_mods.get("range_class", "")) == "short", "primary weapon defines range_class")
	_assert(float(unit_mods.get("speed_mod", 0.0)) > 0.0, "light+smg loadout increases speed")


func _test_resolver_supports_special_aliases() -> void:
	var resolver = LOADOUT_MODIFIER_RESOLVER_SCRIPT.new()
	var mods = resolver.resolve_for_unit("unit_bravo", {"weapon_1": "rail_gun", "weapon_2": "rifle", "armor": "heavy"})
	_assert(mods != null and mods.is_valid(), "resolver normalizes rail_gun as valid special formula")
	if mods != null:
		_assert(String(mods.weapon_1_id) == "special", "weapon_1 normalized to special")
		_assert(float(mods.toughness_mod) > 0.0, "heavy+special stack produces positive toughness modifier")


func _test_testunit_applies_modifiers_to_combat_effects() -> void:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.apply_identity_config({"unit_id": "unit_charlie", "team_id": "team_alpha"})
	unit.apply_loadout_modifiers({"accuracy_mod": 0.08, "speed_mod": 0.12, "toughness_mod": 0.10, "cover_mod": 0.05})
	var effects: Dictionary = unit.get_combat_effects()
	_assert(float(effects.get("hit_modifier", 0.0)) >= 0.08, "loadout modifiers add accuracy via hit_modifier")
	_assert(float(effects.get("speed_multiplier", 1.0)) > 1.0, "loadout modifiers increase speed multiplier")
	_assert(float(effects.get("damage_taken_multiplier", 1.0)) < 1.0, "loadout modifiers reduce damage taken with toughness")
	_assert(unit.get_effective_cover_score() >= 5, "loadout cover modifier contributes to effective cover score")


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
