extends SceneTree

# TASK_092 Verifier – Stealth: Reduzierte Sichtreichweite
# Tests:
# 1. TestUnit has get_stealth() returning the stealth export value
# 2. MissionCombatLoopDriver has _get_effective_range()
# 3. stealth=0.0 → full contact_range
# 4. stealth=1.0 → contact_range * 0.5
# 5. stealth=0.5 → contact_range * 0.75
# 6. Stealth is defensive (target's stealth matters, not attacker's)

const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const COMBAT_DRIVER_SCRIPT: GDScript = preload("res://scripts/tests/mission_combat_loop_driver.gd")

var _pass_count: int = 0
var _fail_count: int = 0


func _init() -> void:
	_run_tests()
	if _fail_count == 0:
		print("TASK_092 VERIFY: ALL %d TESTS PASSED" % _pass_count)
	else:
		print("TASK_092 VERIFY: %d PASSED, %d FAILED" % [_pass_count, _fail_count])
	quit()


func _assert(condition: bool, description: String) -> void:
	if condition:
		_pass_count += 1
		print("  PASS: %s" % description)
	else:
		_fail_count += 1
		print("  FAIL: %s" % description)


func _run_tests() -> void:
	print("--- TASK_092 Verifier ---")
	_test_unit_get_stealth()
	_test_effective_range_stealth_zero()
	_test_effective_range_stealth_one()
	_test_effective_range_stealth_half()
	_test_stealth_constant_exists()
	_test_effective_range_defensive()


func _test_unit_get_stealth() -> void:
	print("Test: TestUnit.get_stealth()")
	var unit: TestUnit = TestUnit.new()
	unit.stealth = 0.8
	_assert(unit.has_method("get_stealth"), "TestUnit has get_stealth()")
	_assert(absf(unit.get_stealth() - 0.8) < 0.01, "get_stealth() returns 0.8 (got %.2f)" % unit.get_stealth())

	unit.stealth = 0.0
	_assert(absf(unit.get_stealth()) < 0.01, "get_stealth() returns 0.0 after change")

	unit.stealth = 1.0
	_assert(absf(unit.get_stealth() - 1.0) < 0.01, "get_stealth() returns 1.0 after change")
	unit.queue_free()


func _test_effective_range_stealth_zero() -> void:
	print("Test: stealth=0.0 → full range")
	var driver: Node = COMBAT_DRIVER_SCRIPT.new()
	driver.contact_range = 180.0

	var target: TestUnit = TestUnit.new()
	target.stealth = 0.0
	var eff_range: float = driver.call("_get_effective_range", target)
	_assert(absf(eff_range - 180.0) < 0.01, "stealth=0.0 → effective range=180.0 (got %.1f)" % eff_range)

	target.queue_free()
	driver.queue_free()


func _test_effective_range_stealth_one() -> void:
	print("Test: stealth=1.0 → 50% range")
	var driver: Node = COMBAT_DRIVER_SCRIPT.new()
	driver.contact_range = 200.0

	var target: TestUnit = TestUnit.new()
	target.stealth = 1.0
	var eff_range: float = driver.call("_get_effective_range", target)
	var expected: float = 200.0 * (1.0 - 1.0 * COMBAT_DRIVER_SCRIPT.STEALTH_RANGE_REDUCTION_FACTOR)
	_assert(absf(eff_range - expected) < 0.01, "stealth=1.0 → effective range=%.1f (got %.1f)" % [expected, eff_range])

	target.queue_free()
	driver.queue_free()


func _test_effective_range_stealth_half() -> void:
	print("Test: stealth=0.5 → 75% range")
	var driver: Node = COMBAT_DRIVER_SCRIPT.new()
	driver.contact_range = 200.0

	var target: TestUnit = TestUnit.new()
	target.stealth = 0.5
	var eff_range: float = driver.call("_get_effective_range", target)
	var expected: float = 200.0 * (1.0 - 0.5 * COMBAT_DRIVER_SCRIPT.STEALTH_RANGE_REDUCTION_FACTOR)
	_assert(absf(eff_range - expected) < 0.01, "stealth=0.5 → effective range=%.1f (got %.1f)" % [expected, eff_range])

	target.queue_free()
	driver.queue_free()


func _test_stealth_constant_exists() -> void:
	print("Test: STEALTH_RANGE_REDUCTION_FACTOR constant exists")
	_assert(COMBAT_DRIVER_SCRIPT.STEALTH_RANGE_REDUCTION_FACTOR > 0.0, "STEALTH_RANGE_REDUCTION_FACTOR > 0 (got %.2f)" % COMBAT_DRIVER_SCRIPT.STEALTH_RANGE_REDUCTION_FACTOR)
	_assert(COMBAT_DRIVER_SCRIPT.STEALTH_RANGE_REDUCTION_FACTOR <= 1.0, "STEALTH_RANGE_REDUCTION_FACTOR <= 1.0 (got %.2f)" % COMBAT_DRIVER_SCRIPT.STEALTH_RANGE_REDUCTION_FACTOR)


func _test_effective_range_defensive() -> void:
	print("Test: stealth is defensive (target stealth matters)")
	var driver: Node = COMBAT_DRIVER_SCRIPT.new()
	driver.contact_range = 180.0

	# High stealth target → reduced range
	var stealthy_target: TestUnit = TestUnit.new()
	stealthy_target.stealth = 0.9
	var range_stealthy: float = driver.call("_get_effective_range", stealthy_target)

	# Low stealth target → near full range
	var loud_target: TestUnit = TestUnit.new()
	loud_target.stealth = 0.1
	var range_loud: float = driver.call("_get_effective_range", loud_target)

	_assert(range_loud > range_stealthy, "Low-stealth target detected at greater range (%.1f > %.1f)" % [range_loud, range_stealthy])

	var diff: float = range_loud - range_stealthy
	_assert(diff > 50.0, "Significant range difference between stealth 0.1 and 0.9 (diff=%.1f)" % diff)

	# Null target → full range fallback
	var range_null: float = driver.call("_get_effective_range", null)
	_assert(absf(range_null - 180.0) < 0.01, "null target → full contact_range (got %.1f)" % range_null)

	stealthy_target.queue_free()
	loud_target.queue_free()
	driver.queue_free()
