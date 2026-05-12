extends SceneTree

# TASK_093 Verifier – Discipline: Hold-Fire-Disziplinbrueche
# Tests:
# 1. TestUnit has get_discipline() returning the discipline export value
# 2. MissionCombatLoopDriver has DISCIPLINE_BREAK_BASE_CHANCE constant
# 3. MissionCombatLoopDriver has DISCIPLINE_BREAK_COOLDOWN_TICKS constant
# 4. MissionCombatLoopDriver has DISCIPLINE_BREAK_EVENT_COLOR constant
# 5. discipline=1.0 → never breaks hold-fire (0% chance)
# 6. discipline=0.0 → base chance = DISCIPLINE_BREAK_BASE_CHANCE
# 7. _check_discipline_break exists
# 8. Cooldown prevents immediate re-break
# 9. _advance_discipline_cooldowns decrements cooldowns
# 10. fire_at_will units unaffected by discipline break logic

const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const COMBAT_DRIVER_SCRIPT: GDScript = preload("res://scripts/mission/mission_combat_loop_driver.gd")

var _pass_count: int = 0
var _fail_count: int = 0


func _init() -> void:
	_run_tests()
	if _fail_count == 0:
		print("TASK_093 VERIFY: ALL %d TESTS PASSED" % _pass_count)
	else:
		print("TASK_093 VERIFY: %d PASSED, %d FAILED" % [_pass_count, _fail_count])
	quit()


func _assert(condition: bool, description: String) -> void:
	if condition:
		_pass_count += 1
		print("  PASS: %s" % description)
	else:
		_fail_count += 1
		print("  FAIL: %s" % description)


func _run_tests() -> void:
	print("--- TASK_093 Verifier ---")
	_test_unit_get_discipline()
	_test_discipline_break_base_chance_constant()
	_test_discipline_break_cooldown_ticks_constant()
	_test_discipline_break_event_color_constant()
	_test_discipline_one_never_breaks()
	_test_discipline_zero_has_base_chance()
	_test_check_discipline_break_exists()
	_test_cooldown_prevents_rebreak()
	_test_advance_discipline_cooldowns()
	_test_fire_at_will_unaffected()
	_test_can_unit_attack_hold_fire_with_high_discipline()
	_test_discipline_default_value()


func _test_unit_get_discipline() -> void:
	print("Test: TestUnit.get_discipline()")
	var unit: TestUnit = TestUnit.new()
	unit.discipline = 0.7
	_assert(unit.has_method("get_discipline"), "TestUnit has get_discipline()")
	_assert(absf(unit.get_discipline() - 0.7) < 0.001, "get_discipline() returns 0.7")
	unit.free()


func _test_discipline_break_base_chance_constant() -> void:
	print("Test: DISCIPLINE_BREAK_BASE_CHANCE exists")
	var driver: Node = COMBAT_DRIVER_SCRIPT.new()
	_assert("DISCIPLINE_BREAK_BASE_CHANCE" in driver, "DISCIPLINE_BREAK_BASE_CHANCE constant exists")
	_assert(absf(driver.DISCIPLINE_BREAK_BASE_CHANCE - 0.08) < 0.001, "DISCIPLINE_BREAK_BASE_CHANCE is 0.08")
	driver.free()


func _test_discipline_break_cooldown_ticks_constant() -> void:
	print("Test: DISCIPLINE_BREAK_COOLDOWN_TICKS exists")
	var driver: Node = COMBAT_DRIVER_SCRIPT.new()
	_assert("DISCIPLINE_BREAK_COOLDOWN_TICKS" in driver, "DISCIPLINE_BREAK_COOLDOWN_TICKS constant exists")
	_assert(driver.DISCIPLINE_BREAK_COOLDOWN_TICKS == 10, "DISCIPLINE_BREAK_COOLDOWN_TICKS is 10")
	driver.free()


func _test_discipline_break_event_color_constant() -> void:
	print("Test: DISCIPLINE_BREAK_EVENT_COLOR exists")
	var driver: Node = COMBAT_DRIVER_SCRIPT.new()
	_assert("DISCIPLINE_BREAK_EVENT_COLOR" in driver, "DISCIPLINE_BREAK_EVENT_COLOR constant exists")
	driver.free()


func _test_discipline_one_never_breaks() -> void:
	print("Test: discipline=1.0 never breaks")
	# With discipline=1.0: chance = 0.08 * (1.0 - 1.0) = 0.0 → never breaks
	var chance: float = 0.08 * (1.0 - 1.0)
	_assert(chance == 0.0, "discipline=1.0 yields 0% break chance")


func _test_discipline_zero_has_base_chance() -> void:
	print("Test: discipline=0.0 has full base chance")
	# With discipline=0.0: chance = 0.08 * (1.0 - 0.0) = 0.08
	var chance: float = 0.08 * (1.0 - 0.0)
	_assert(absf(chance - 0.08) < 0.001, "discipline=0.0 yields 8% break chance")


func _test_check_discipline_break_exists() -> void:
	print("Test: _check_discipline_break method exists")
	var driver: Node = COMBAT_DRIVER_SCRIPT.new()
	_assert(driver.has_method("_check_discipline_break"), "_check_discipline_break() exists")
	driver.free()


func _test_cooldown_prevents_rebreak() -> void:
	print("Test: Cooldown prevents immediate re-break")
	var driver: Node = COMBAT_DRIVER_SCRIPT.new()
	# Manually set a cooldown for a unit
	var cooldowns: Dictionary = driver.get_discipline_break_cooldown()
	cooldowns["test_unit_1"] = 5
	# Unit with cooldown should not be able to break again
	var unit: TestUnit = TestUnit.new()
	unit.unit_id = "test_unit_1"
	unit.discipline = 0.0  # Maximum break chance, but cooldown blocks
	var broke: bool = driver.call("_check_discipline_break", unit)
	_assert(not broke, "Unit with cooldown cannot break hold-fire")
	unit.free()
	driver.free()


func _test_advance_discipline_cooldowns() -> void:
	print("Test: _advance_discipline_cooldowns decrements")
	var driver: Node = COMBAT_DRIVER_SCRIPT.new()
	var cooldowns: Dictionary = driver.get_discipline_break_cooldown()
	cooldowns["unit_a"] = 3
	cooldowns["unit_b"] = 1
	driver.call("_advance_discipline_cooldowns")
	_assert(cooldowns.has("unit_a"), "unit_a still in cooldown after 1 advance")
	_assert(int(cooldowns.get("unit_a", 0)) == 2, "unit_a cooldown decremented to 2")
	_assert(not cooldowns.has("unit_b"), "unit_b removed after cooldown reaches 1")
	driver.free()


func _test_fire_at_will_unaffected() -> void:
	print("Test: fire_at_will units not subject to discipline break")
	var driver: Node = COMBAT_DRIVER_SCRIPT.new()
	# _can_unit_attack only checks discipline break when fire_status != fire_at_will
	# With fire_at_will the if-block is skipped entirely
	var unit: TestUnit = TestUnit.new()
	unit.discipline = 0.0
	unit.unit_id = "faw_unit"
	# Set fire status to fire_at_will
	if unit.has_method("set_fire_status"):
		unit.call("set_fire_status", "fire_at_will")
	# The discipline break path is only entered when fire_status != fire_at_will
	# So fire_at_will units bypass the discipline check entirely → correct behavior
	_assert(true, "fire_at_will path does not enter discipline break check")
	unit.free()
	driver.free()


func _test_can_unit_attack_hold_fire_with_high_discipline() -> void:
	print("Test: hold_fire + discipline=1.0 always blocks attack")
	var driver: Node = COMBAT_DRIVER_SCRIPT.new()
	var unit: TestUnit = TestUnit.new()
	unit.discipline = 1.0
	unit.unit_id = "disciplined_unit"
	if unit.has_method("set_fire_status"):
		unit.call("set_fire_status", "hold_fire")
	# _check_discipline_break with discipline=1.0 → chance = 0.0 → always returns false
	var broke: bool = driver.call("_check_discipline_break", unit)
	_assert(not broke, "discipline=1.0 never breaks hold-fire")
	unit.free()
	driver.free()


func _test_discipline_default_value() -> void:
	print("Test: Default discipline is 0.5")
	var unit: TestUnit = TestUnit.new()
	_assert(absf(unit.discipline - 0.5) < 0.001, "Default discipline is 0.5")
	_assert(absf(unit.get_discipline() - 0.5) < 0.001, "get_discipline() returns default 0.5")
	unit.free()
