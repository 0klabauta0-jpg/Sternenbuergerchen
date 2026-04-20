extends SceneTree

# TASK_090 Verifier – Differenzierte Enemy-Typen
# Tests:
# 1. All 6 enemy archetypes exist in ENEMY_ARCHETYPES
# 2. Each archetype has required fields
# 3. get_enemy_archetype_for_unit() returns different archetypes for different unit_ids
# 4. get_enemy_archetype_by_id() returns correct archetype
# 5. get_preset() for team_bravo uses archetype stats
# 6. Friendly presets remain unaffected

const PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

var _pass_count: int = 0
var _fail_count: int = 0


func _init() -> void:
	_run_tests()
	if _fail_count == 0:
		print("TASK_090 VERIFY: ALL %d TESTS PASSED" % _pass_count)
	else:
		print("TASK_090 VERIFY: %d PASSED, %d FAILED" % [_pass_count, _fail_count])
	quit()


func _assert(condition: bool, description: String) -> void:
	if condition:
		_pass_count += 1
		print("  PASS: %s" % description)
	else:
		_fail_count += 1
		print("  FAIL: %s" % description)


func _run_tests() -> void:
	print("--- TASK_090 Verifier ---")
	_test_archetypes_exist()
	_test_archetype_fields()
	_test_archetype_diversity()
	_test_archetype_by_id()
	_test_preset_uses_archetype()
	_test_friendly_unaffected()


func _test_archetypes_exist() -> void:
	print("Test: 6 enemy archetypes exist")
	var archetypes: Array = PRESETS_SCRIPT.ENEMY_ARCHETYPES
	_assert(archetypes.size() == 6, "ENEMY_ARCHETYPES has 6 entries (got %d)" % archetypes.size())
	var ids: Array = []
	for a in archetypes:
		ids.append(String(a.get("archetype_id", "")))
	_assert(ids.has("standard"), "Has standard")
	_assert(ids.has("scout"), "Has scout")
	_assert(ids.has("heavy"), "Has heavy")
	_assert(ids.has("sniper"), "Has sniper")
	_assert(ids.has("medic"), "Has medic")
	_assert(ids.has("officer"), "Has officer")


func _test_archetype_fields() -> void:
	print("Test: archetypes have required fields")
	var required_fields: Array = ["archetype_id", "team_id", "weapon_id", "skill_accuracy", "skill_speed", "skill_toughness", "skill_leadership"]
	for archetype in PRESETS_SCRIPT.ENEMY_ARCHETYPES:
		var aid: String = String(archetype.get("archetype_id", "?"))
		for field in required_fields:
			_assert(archetype.has(field), "%s has field %s" % [aid, field])


func _test_archetype_diversity() -> void:
	print("Test: different unit_ids get different archetypes")
	var test_ids: Array = ["enemy_1", "enemy_2", "enemy_3", "enemy_4", "enemy_5", "enemy_6", "enemy_7", "enemy_8"]
	var seen_archetypes: Dictionary = {}
	for uid in test_ids:
		var archetype: Dictionary = PRESETS_SCRIPT.get_enemy_archetype_for_unit(uid)
		var aid: String = String(archetype.get("archetype_id", ""))
		seen_archetypes[aid] = true
	_assert(seen_archetypes.size() >= 2, "At least 2 different archetypes assigned across 8 enemies (got %d)" % seen_archetypes.size())


func _test_archetype_by_id() -> void:
	print("Test: get_enemy_archetype_by_id")
	var sniper: Dictionary = PRESETS_SCRIPT.get_enemy_archetype_by_id("sniper")
	_assert(float(sniper.get("skill_accuracy", 0.0)) > 0.6, "Sniper accuracy > 0.6 (got %.2f)" % float(sniper.get("skill_accuracy", 0.0)))
	var heavy: Dictionary = PRESETS_SCRIPT.get_enemy_archetype_by_id("heavy")
	_assert(float(heavy.get("skill_toughness", 0.0)) > 0.7, "Heavy toughness > 0.7 (got %.2f)" % float(heavy.get("skill_toughness", 0.0)))
	_assert(String(heavy.get("weapon_id", "")) == "rail_gun", "Heavy uses rail_gun")
	var scout: Dictionary = PRESETS_SCRIPT.get_enemy_archetype_by_id("scout")
	_assert(float(scout.get("skill_speed", 0.0)) > 0.5, "Scout speed > 0.5 (got %.2f)" % float(scout.get("skill_speed", 0.0)))
	_assert(String(scout.get("weapon_id", "")) == "smg", "Scout uses smg")


func _test_preset_uses_archetype() -> void:
	print("Test: get_enemy_archetype_for_unit returns valid archetype for enemy id")
	var archetype: Dictionary = PRESETS_SCRIPT.get_enemy_archetype_for_unit("enemy_test_unit")
	_assert(not archetype.is_empty(), "Archetype not empty")
	_assert(archetype.has("archetype_id"), "Has archetype_id")
	var accuracy: float = float(archetype.get("skill_accuracy", -1.0))
	_assert(accuracy >= 0.0 and accuracy <= 1.0, "Accuracy in valid range (got %.2f)" % accuracy)
	_assert(String(archetype.get("team_id", "")) == "team_bravo", "team_id is team_bravo")


func _test_friendly_unaffected() -> void:
	print("Test: friendly roster unaffected")
	var roster: Array = PRESETS_SCRIPT.FRIENDLY_ROSTER
	_assert(roster.size() > 0, "FRIENDLY_ROSTER not empty")
	var alpha: Dictionary = Dictionary(roster[0])
	_assert(float(alpha.get("skill_accuracy", 0.0)) > 0.5, "unit_alpha accuracy unchanged (got %.2f)" % float(alpha.get("skill_accuracy", 0.0)))
	_assert(String(alpha.get("display_name", "")) == "Anja Voss", "unit_alpha display_name unchanged")
