extends SceneTree

const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const STORE = preload("res://scripts/meta/player_roster_store.gd")
const GENERATOR = preload("res://scripts/meta/start_roster_generator.gd")
const PROFILE_BUILDER = preload("res://scripts/meta/meta_unit_profile_builder.gd")
const UNIT_SKILLS = preload("res://scripts/npc/unit_skills.gd")

var _passed: int = 0
var _failed: int = 0
var _fixture_root: String = ""


func _init() -> void:
	if not GUARD.require_isolated_user_data():
		return
	call_deferred("_run")


func _run() -> void:
	_fixture_root = "user://review46_effective_roster_skills_%d" % Time.get_ticks_usec()
	_test_trait_adjusted_effective_domain()
	_test_real_generated_rosters_are_persistable()
	_test_invalid_effective_values_remain_rejected()
	print("REVIEW46_EFFECTIVE_ROSTER_SKILLS_RESULT passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _test_trait_adjusted_effective_domain() -> void:
	var profile = PROFILE_BUILDER.build_from_identity_config({
		"unit_id": "review46_trait_pilot",
		"display_name": "Synthetic Pilot",
		"role_id": "dropship_pilot",
		"skill_accuracy": 0.38,
		"skill_speed": 0.66,
		"skill_leadership": 0.48,
		"skill_toughness": 0.36,
		"trait_ids": PackedStringArray(["calm", "reckless"]),
	})
	var profile_data: Dictionary = profile.to_dict()
	var effective: Dictionary = Dictionary(profile_data.get("skill_values", {}))
	var toughness: float = float(effective.get("toughness", -1.0))
	print("REVIEW46_HAND_DERIVED_TOUGHNESS value=%.17f base=0.36 modifier=-0.15" % toughness)
	_check(is_equal_approx(toughness, 0.21), "Real builder applies reckless toughness modifier after the pilot's base skill")
	_check(toughness >= 0.0 and toughness < GENERATOR.MIN_SKILL_VALUE, "Trait-adjusted pilot toughness is inside the runtime domain and below the base-generation floor")
	_check(UNIT_SKILLS.new(effective).is_valid(), "Existing UnitSkills accepts the actual trait-adjusted effective values")
	var roster: Dictionary = GENERATOR.generate_start_roster("review46_blocked_original", 20, "review46_blocked")
	var units: Array = Array(roster.get("units", [])).duplicate(true)
	var original_unit: Dictionary = Dictionary(units[0]).duplicate(true)
	var original_values: Dictionary = Dictionary(original_unit.get("skill_values", {})).duplicate(true)
	original_values["toughness"] = toughness
	original_unit["skill_values"] = original_values
	units[0] = original_unit
	roster["units"] = units
	var validation: Dictionary = GENERATOR.validate_roster(roster)
	_check(bool(validation.get("valid", false)), "Roster validator accepts the real builder's valid trait-adjusted effective toughness")


func _test_real_generated_rosters_are_persistable() -> void:
	var fixtures: Array = [
		{"seed": "review46_success_replacement", "profile": "review46_success"},
		{"seed": "review46_missing_created", "profile": "review46_missing"},
		{"seed": "review46_menu_original", "profile": "review46_menu"},
		{"seed": "review46_menu_original_reset_01", "profile": "review46_menu"},
	]
	for index in range(fixtures.size()):
		var fixture: Dictionary = Dictionary(fixtures[index])
		var seed: String = String(fixture["seed"])
		var profile_id: String = String(fixture["profile"])
		var roster: Dictionary = GENERATOR.generate_start_roster(seed, 20, profile_id)
		_print_low_effective_values(seed, roster)
		_check(bool(roster.get("valid", false)), "Real generated roster validates without replacing its seed: " + seed)
		var validation: Dictionary = GENERATOR.validate_roster(roster)
		_check(bool(validation.get("valid", false)), "Fresh validation accepts the generated effective skills: " + seed)
		var path: String = "%s/case_%d/roster_v1.json" % [_fixture_root, index]
		var saved: Dictionary = STORE.save_roster(roster, profile_id, path)
		_check(bool(saved.get("ok", false)), "Store persists the generated roster with its original trait-adjusted skills: " + seed)
		var loaded: Dictionary = STORE.load_roster(profile_id, path)
		_check(bool(loaded.get("ok", false)), "Store reloads the generated roster with its original effective skills: " + seed)
		if bool(loaded.get("ok", false)):
			var loaded_roster: Dictionary = Dictionary(loaded.get("roster", {}))
			_check(String(loaded_roster.get("seed", "")) == seed, "Roundtrip preserves the original failing generator seed: " + seed)
			var original_units: Array = Array(roster.get("units", []))
			var loaded_units: Array = Array(loaded_roster.get("units", []))
			_check(_same_skill_values(original_units, loaded_units), "Roundtrip preserves every effective skill rather than clamping valid low traits: " + seed)


func _test_invalid_effective_values_remain_rejected() -> void:
	var roster: Dictionary = GENERATOR.generate_start_roster("review46_blocked_original", 20, "review46_blocked")
	var units: Array = Array(roster.get("units", [])).duplicate(true)
	var first: Dictionary = Dictionary(units[0]).duplicate(true)
	var unit_id: String = String(first.get("unit_id", ""))
	for invalid_value in [-0.01, 1.01]:
		var invalid: Dictionary = roster.duplicate(true)
		var invalid_units: Array = units.duplicate(true)
		var invalid_unit: Dictionary = first.duplicate(true)
		var invalid_skills: Dictionary = Dictionary(first.get("skill_values", {})).duplicate(true)
		invalid_skills["accuracy"] = invalid_value
		invalid_unit["skill_values"] = invalid_skills
		invalid_units[0] = invalid_unit
		invalid["units"] = invalid_units
		var validation: Dictionary = GENERATOR.validate_roster(invalid)
		_check(not bool(validation.get("valid", true)), "Roster still rejects effective skill outside runtime domain: %s" % invalid_value)
		_check(PackedStringArray(validation.get("errors", [])).has("skill_out_of_range:%s:accuracy" % unit_id), "Invalid effective accuracy retains its exact range diagnostic: %s" % invalid_value)
	var missing: Dictionary = roster.duplicate(true)
	var missing_unit: Dictionary = first.duplicate(true)
	var missing_skills: Dictionary = Dictionary(first.get("skill_values", {})).duplicate(true)
	missing_skills.erase("accuracy")
	missing_unit["skill_values"] = missing_skills
	units[0] = missing_unit
	missing["units"] = units
	var missing_validation: Dictionary = GENERATOR.validate_roster(missing)
	_check(not bool(missing_validation.get("valid", true)), "Roster still rejects a missing required effective skill")
	_check(PackedStringArray(missing_validation.get("errors", [])).has("skill_missing:%s:accuracy" % unit_id), "Missing effective accuracy retains its exact diagnostic")


func _same_skill_values(original_units: Array, loaded_units: Array) -> bool:
	if original_units.size() != loaded_units.size():
		return false
	for index in range(original_units.size()):
		var original: Dictionary = Dictionary(original_units[index])
		var loaded: Dictionary = Dictionary(loaded_units[index])
		if String(original.get("unit_id", "")) != String(loaded.get("unit_id", "")):
			return false
		var original_skills: Dictionary = Dictionary(original.get("skill_values", {}))
		var loaded_skills: Dictionary = Dictionary(loaded.get("skill_values", {}))
		if original_skills.size() != loaded_skills.size():
			return false
		for key in original_skills:
			if not loaded_skills.has(key) or not is_equal_approx(float(original_skills[key]), float(loaded_skills[key])):
				return false
	return true


func _print_low_effective_values(seed: String, roster: Dictionary) -> void:
	for unit_variant in Array(roster.get("units", [])):
		var unit: Dictionary = Dictionary(unit_variant)
		var skills: Dictionary = Dictionary(unit.get("skill_values", {}))
		for key in ["accuracy", "speed", "leadership", "toughness", "awareness", "discipline"]:
			var value: float = float(skills.get(key, -1.0))
			if value < GENERATOR.MIN_SKILL_VALUE:
				print("REVIEW46_GENERATED_LOW_EFFECTIVE_SKILL seed=%s unit=%s key=%s value=%.17f traits=%s" % [seed, String(unit.get("unit_id", "")), key, value, str(unit.get("trait_ids", []))])
	print("REVIEW46_GENERATED_VALIDATION seed=%s errors=%s" % [seed, str(Dictionary(roster.get("validation", {})).get("errors", []))])


func _check(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: " + message)
	else:
		_failed += 1
		print("FAIL: " + message)
