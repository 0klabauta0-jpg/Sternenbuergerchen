extends SceneTree

const GENERATOR := preload("res://scripts/meta/start_roster_generator.gd")
const STORE := preload("res://scripts/meta/player_roster_store.gd")
var _passed := 0
var _failed := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	# Fixed R1 reproductions: no neutralized skills or changed traits.
	for profile_id in ["native_shell_1280_720_3799609", "ui_native_shell_fixture"]:
		var roster: Dictionary = GENERATOR.generate_start_roster("native_shell_fixture", 24, profile_id)
		_check(bool(roster.valid), "Real generated roster validates: " + profile_id)
		var low_values := 0
		for unit: Dictionary in roster.units:
			if float(unit.skill_values.toughness) < GENERATOR.MIN_SKILL_VALUE:
				low_values += 1
		_check(low_values > 0, "Reproduction retains effective trait values below the base-roll floor")
		var save_path := "user://ui_native_r2_verifier/%s/roster.json" % profile_id
		var saved: Dictionary = STORE.save_roster(roster, profile_id, save_path)
		_check(bool(saved.get("ok", false)), "Actual Store saves the unmodified generated roster")
		var loaded: Dictionary = STORE.load_roster(profile_id, save_path)
		_check(bool(loaded.get("ok", false)), "Actual Store reloads generated roster")
		if bool(loaded.get("ok", false)):
			var units: Array = loaded.roster.units
			_check(units.size() == roster.units.size(), "Roundtrip retains all people")
			for index in range(units.size()):
				var expected: Dictionary = roster.units[index].skill_values
				var actual: Dictionary = units[index].skill_values
				var equivalent := actual.size() == expected.size()
				for key in expected:
					equivalent = equivalent and actual.has(key) and is_equal_approx(float(actual.get(key, -1)), float(expected[key]))
				_check(equivalent, "JSON roundtrip retains every effective skill within float precision, person %d" % index)
		var repeat: Dictionary = GENERATOR.generate_start_roster("native_shell_fixture", 24, profile_id)
		_check(roster.units == repeat.units, "Generation remains deterministic and unmodified")
	var fixture: Dictionary = GENERATOR.generate_start_roster("r2_value_bounds", 24, "r2_value_bounds")
	var first: Dictionary = fixture.units[0]
	for key in ["accuracy", "speed", "leadership", "toughness", "awareness", "discipline"]:
		for value in [0.0, 0.10, 1.0]:
			var candidate := fixture.duplicate(true)
			candidate.units[0].skill_values[key] = value
			_check(bool(GENERATOR.validate_roster(candidate).valid), "%s effective %s is valid" % [key, value])
		for value in [-0.01, 1.01, NAN, INF]:
			var candidate := fixture.duplicate(true)
			candidate.units[0].skill_values[key] = value
			_check(not bool(GENERATOR.validate_roster(candidate).valid), "%s invalid/nonfinite %s is rejected" % [key, value])
	var missing := fixture.duplicate(true)
	missing.units[0].skill_values.erase("toughness")
	_check(not bool(GENERATOR.validate_roster(missing).valid), "Missing required skill remains invalid")
	_check(first == fixture.units[0], "Validation never mutates source profiles")
	print("RESULTS: %d passed, %d failed" % [_passed, _failed])
	if _failed == 0:
		print("PASS: R2 roster save workflow")
	quit(1 if _failed > 0 else 0)

func _check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		print("PASS: " + label)
	else:
		_failed += 1
		print("FAIL: " + label)
