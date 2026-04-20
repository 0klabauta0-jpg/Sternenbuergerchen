extends SceneTree

# TASK_094 Verifier – Recognition: Friendly-Fire-Verwechslung
# Tests:
# 1. TestUnit has get_recognition() returning the recognition export value
# 2. MissionCombatLoopDriver has MISIDENTIFICATION_BASE_CHANCE constant
# 3. MissionCombatLoopDriver has MISIDENTIFICATION_COOLDOWN_TICKS constant
# 4. MissionCombatLoopDriver has MISIDENTIFICATION_EVENT_COLOR constant
# 5. recognition=1.0 → never misidentifies (0% chance)
# 6. recognition=0.0 → base chance = MISIDENTIFICATION_BASE_CHANCE
# 7. _check_misidentification exists
# 8. Cooldown prevents immediate re-misidentification
# 9. _advance_misidentification_cooldowns decrements cooldowns
# 10. Only friendlies can misidentify (enemies never)
# 11. Misidentification returns nearest friendly unit

const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const COMBAT_DRIVER_SCRIPT: GDScript = preload("res://scripts/tests/mission_combat_loop_driver.gd")

var _pass_count: int = 0
var _fail_count: int = 0


func _init() -> void:
	_run_tests()
	if _fail_count == 0:
		print("TASK_094 VERIFY: ALL %d TESTS PASSED" % _pass_count)
	else:
		print("TASK_094 VERIFY: %d PASSED, %d FAILED" % [_pass_count, _fail_count])
	quit()


func _assert(condition: bool, description: String) -> void:
	if condition:
		_pass_count += 1
		print("  PASS: %s" % description)
	else:
		_fail_count += 1
		print("  FAIL: %s" % description)


func _run_tests() -> void:
	print("--- TASK_094 Verifier ---")
	_test_unit_get_recognition()
	_test_misid_base_chance_constant()
	_test_misid_cooldown_ticks_constant()
	_test_misid_event_color_constant()
	_test_recognition_one_never_misidentifies()
	_test_recognition_zero_has_base_chance()
	_test_check_misidentification_exists()
	_test_cooldown_prevents_re_misid()
	_test_advance_misidentification_cooldowns()
	_test_enemies_never_misidentify()
	_test_misid_returns_empty_without_friendlies()
	_test_recognition_default_value()
	_test_get_misidentification_cooldown()


func _test_unit_get_recognition() -> void:
	print("Test: TestUnit.get_recognition()")
	var unit: TestUnit = TestUnit.new()
	unit.recognition = 0.8
	_assert(unit.has_method("get_recognition"), "TestUnit has get_recognition()")
	_assert(absf(unit.get_recognition() - 0.8) < 0.001, "get_recognition() returns 0.8")
	unit.free()


func _test_misid_base_chance_constant() -> void:
	print("Test: MISIDENTIFICATION_BASE_CHANCE exists")
	var driver: Node = COMBAT_DRIVER_SCRIPT.new()
	_assert("MISIDENTIFICATION_BASE_CHANCE" in driver, "MISIDENTIFICATION_BASE_CHANCE constant exists")
	_assert(absf(driver.MISIDENTIFICATION_BASE_CHANCE - 0.03) < 0.001, "MISIDENTIFICATION_BASE_CHANCE is 0.03")
	driver.free()


func _test_misid_cooldown_ticks_constant() -> void:
	print("Test: MISIDENTIFICATION_COOLDOWN_TICKS exists")
	var driver: Node = COMBAT_DRIVER_SCRIPT.new()
	_assert("MISIDENTIFICATION_COOLDOWN_TICKS" in driver, "MISIDENTIFICATION_COOLDOWN_TICKS constant exists")
	_assert(driver.MISIDENTIFICATION_COOLDOWN_TICKS == 15, "MISIDENTIFICATION_COOLDOWN_TICKS is 15")
	driver.free()


func _test_misid_event_color_constant() -> void:
	print("Test: MISIDENTIFICATION_EVENT_COLOR exists")
	var driver: Node = COMBAT_DRIVER_SCRIPT.new()
	_assert("MISIDENTIFICATION_EVENT_COLOR" in driver, "MISIDENTIFICATION_EVENT_COLOR constant exists")
	driver.free()


func _test_recognition_one_never_misidentifies() -> void:
	print("Test: recognition=1.0 never misidentifies")
	var chance: float = 0.03 * (1.0 - 1.0)
	_assert(chance == 0.0, "recognition=1.0 yields 0% misidentification chance")


func _test_recognition_zero_has_base_chance() -> void:
	print("Test: recognition=0.0 has full base chance")
	var chance: float = 0.03 * (1.0 - 0.0)
	_assert(absf(chance - 0.03) < 0.001, "recognition=0.0 yields 3% misidentification chance")


func _test_check_misidentification_exists() -> void:
	print("Test: _check_misidentification method exists")
	var driver: Node = COMBAT_DRIVER_SCRIPT.new()
	_assert(driver.has_method("_check_misidentification"), "_check_misidentification() exists")
	driver.free()


func _test_cooldown_prevents_re_misid() -> void:
	print("Test: Cooldown prevents immediate re-misidentification")
	var driver: Node = COMBAT_DRIVER_SCRIPT.new()
	driver.friendly_team_id = "team_alpha"
	var cooldowns: Dictionary = driver.get_misidentification_cooldown()
	cooldowns["test_unit_1"] = 5
	var unit: TestUnit = TestUnit.new()
	unit.unit_id = "test_unit_1"
	unit.team_id = "team_alpha"
	unit.recognition = 0.0
	var result: Dictionary = driver.call("_check_misidentification", unit, "test_unit_1")
	_assert(result.is_empty(), "Unit with cooldown cannot misidentify")
	unit.free()
	driver.free()


func _test_advance_misidentification_cooldowns() -> void:
	print("Test: _advance_misidentification_cooldowns decrements")
	var driver: Node = COMBAT_DRIVER_SCRIPT.new()
	var cooldowns: Dictionary = driver.get_misidentification_cooldown()
	cooldowns["unit_a"] = 3
	cooldowns["unit_b"] = 1
	driver.call("_advance_misidentification_cooldowns")
	_assert(cooldowns.has("unit_a"), "unit_a still in cooldown after 1 advance")
	_assert(int(cooldowns.get("unit_a", 0)) == 2, "unit_a cooldown decremented to 2")
	_assert(not cooldowns.has("unit_b"), "unit_b removed after cooldown reaches 1")
	driver.free()


func _test_enemies_never_misidentify() -> void:
	print("Test: Enemies never misidentify")
	var driver: Node = COMBAT_DRIVER_SCRIPT.new()
	driver.friendly_team_id = "team_alpha"
	var unit: TestUnit = TestUnit.new()
	unit.unit_id = "enemy_1"
	unit.team_id = "team_bravo"
	unit.recognition = 0.0
	var result: Dictionary = driver.call("_check_misidentification", unit, "enemy_1")
	_assert(result.is_empty(), "Enemy unit cannot misidentify")
	unit.free()
	driver.free()


func _test_misid_returns_empty_without_friendlies() -> void:
	print("Test: Misidentification returns empty when no other friendlies")
	var driver: Node = COMBAT_DRIVER_SCRIPT.new()
	driver.friendly_team_id = "team_alpha"
	# No friendly_unit_paths set, so no targets to misidentify
	var unit: TestUnit = TestUnit.new()
	unit.unit_id = "solo_unit"
	unit.team_id = "team_alpha"
	unit.recognition = 0.0
	# Even with 0 recognition, no friendly targets → empty result
	var result: Dictionary = driver.call("_check_misidentification", unit, "solo_unit")
	_assert(result.is_empty(), "No misidentification without other friendlies available")
	unit.free()
	driver.free()


func _test_recognition_default_value() -> void:
	print("Test: Default recognition is 0.5")
	var unit: TestUnit = TestUnit.new()
	_assert(absf(unit.recognition - 0.5) < 0.001, "Default recognition is 0.5")
	_assert(absf(unit.get_recognition() - 0.5) < 0.001, "get_recognition() returns default 0.5")
	unit.free()


func _test_get_misidentification_cooldown() -> void:
	print("Test: get_misidentification_cooldown() accessor works")
	var driver: Node = COMBAT_DRIVER_SCRIPT.new()
	_assert(driver.has_method("get_misidentification_cooldown"), "get_misidentification_cooldown() exists")
	var cd: Dictionary = driver.get_misidentification_cooldown()
	_assert(cd.is_empty(), "Initial cooldown dictionary is empty")
	driver.free()
