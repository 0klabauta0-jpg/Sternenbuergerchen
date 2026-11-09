extends SceneTree

const START_ROSTER_GENERATOR_SCRIPT: GDScript = preload("res://scripts/meta/start_roster_generator.gd")
const META_UNIT_PROFILE_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile.gd")
const NPC_RANK_BADGE_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/npc_rank_badge_resolver.gd")
const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")
const CONTRACT_DOC_PATH: String = "res://docs/dev/character_roster_generation_contract.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_232 Start Roster Generation Contract ===")
	_test_contract_doc()
	_test_generator_size_seed_and_validation()
	_test_profile_validity_roles_skills_and_badges()
	_test_fireteam_suggestions_and_multiplayer_boundary()
	await _test_main_menu_first_start_and_new_team_boundary()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_contract_doc() -> void:
	var text: String = _read_text(CONTRACT_DOC_PATH)
	_assert(not text.is_empty(), "Roster generation contract doc exists")
	for required_text in ["24", "20", "30", "Seed", "leader", "medic", "pilot", "heavy_support", "scout_sniper", "Multiplayer", "player_profile_local", "TASK_234"]:
		_assert(text.contains(required_text), "Contract doc covers %s" % required_text)


func _test_generator_size_seed_and_validation() -> void:
	var roster_a: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", "task232_alpha", 24, "player_a"))
	var roster_b: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", "task232_alpha", 24, "player_a"))
	var roster_c: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", "task232_beta", 24, "player_a"))
	_assert(bool(roster_a.get("valid", false)), "Default seeded roster is valid")
	_assert(int(roster_a.get("roster_size", 0)) == 24, "Default roster size is 24")
	_assert(_roster_fingerprint(roster_a) == _roster_fingerprint(roster_b), "Same seed produces reproducible roster")
	_assert(_roster_fingerprint(roster_a) != _roster_fingerprint(roster_c), "Different seed changes generated roster identity")
	var small_roster: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", "task232_small", 8))
	var large_roster: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", "task232_large", 48))
	_assert(int(small_roster.get("roster_size", 0)) == START_ROSTER_GENERATOR_SCRIPT.MIN_ROSTER_SIZE, "Generator clamps small roster to minimum")
	_assert(int(large_roster.get("roster_size", 0)) == START_ROSTER_GENERATOR_SCRIPT.MAX_ROSTER_SIZE, "Generator clamps large roster to maximum")
	var first_start_existing: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("build_first_start_snapshot", roster_a, "ignored_seed"))
	_assert(not bool(first_start_existing.get("created", true)) and String(first_start_existing.get("reason", "")) == "existing_roster", "First-start helper keeps existing valid roster")
	var first_start_missing: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("build_first_start_snapshot", {}, "task232_missing"))
	_assert(bool(first_start_missing.get("created", false)) and bool(Dictionary(first_start_missing.get("summary", {})).get("valid", false)), "First-start helper generates missing roster")


func _test_profile_validity_roles_skills_and_badges() -> void:
	var roster: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", "task232_profiles", 24))
	var units: Array = Array(roster.get("units", []))
	var role_mix: Dictionary = Dictionary(roster.get("role_mix", {}))
	for category in START_ROSTER_GENERATOR_SCRIPT.VALID_ROLE_CATEGORIES:
		_assert(int(role_mix.get(category, 0)) >= 1, "Role mix contains %s" % category)
	var weak_gap_count: int = 0
	var strong_count: int = 0
	var unit_ids: Dictionary = {}
	var callsigns: Dictionary = {}
	for unit_variant in units:
		var unit: Dictionary = Dictionary(unit_variant)
		var profile = META_UNIT_PROFILE_SCRIPT.new(unit)
		var unit_id: String = String(unit.get("unit_id", ""))
		var callsign: String = String(unit.get("callsign", ""))
		_assert(bool(profile.call("is_valid")), "Generated unit is a valid MetaUnitProfile: %s" % unit_id)
		_assert(not unit_ids.has(unit_id), "Generated unit id is unique: %s" % unit_id)
		_assert(not callsigns.has(callsign), "Generated callsign is unique: %s" % callsign)
		unit_ids[unit_id] = true
		callsigns[callsign] = true
		_assert(not String(unit.get("display_name", "")).is_empty(), "Generated unit has display name")
		_assert(not callsign.is_empty(), "Generated unit has callsign")
		var skill_values: Dictionary = Dictionary(unit.get("skill_values", {}))
		for skill_key in ["accuracy", "speed", "leadership", "toughness"]:
			var value: float = float(skill_values.get(skill_key, -1.0))
			_assert(is_finite(value) and value >= 0.0 and value <= 1.0, "Generated effective skill follows the trait/profile 0..1 contract: %s/%s" % [unit_id, skill_key])
			if value < 0.45:
				weak_gap_count += 1
			if value > 0.70:
				strong_count += 1
		var badges: Array = Array(NPC_RANK_BADGE_RESOLVER_SCRIPT.call("get_badges_for_profile", profile))
		_assert(badges.size() > 0 and badges.size() <= 1, "Generated profile starts with at most one rank badge")
	_assert(weak_gap_count >= 6, "Roster keeps visible weak spots instead of perfect balance")
	_assert(strong_count >= 6, "Roster has visible strengths for player choices")


func _test_fireteam_suggestions_and_multiplayer_boundary() -> void:
	var roster: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", "task232_fireteams", 24))
	var validation: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("validate_roster", roster))
	_assert(bool(validation.get("valid", false)), "Roster validator accepts generated fireteams")
	var seen_units: Dictionary = {}
	for suggestion_variant in Array(roster.get("fireteam_suggestions", [])):
		var suggestion: Dictionary = Dictionary(suggestion_variant)
		var member_ids: PackedStringArray = PackedStringArray(suggestion.get("unit_ids", PackedStringArray()))
		_assert(not String(suggestion.get("fireteam_id", "")).is_empty(), "Fireteam suggestion has id")
		_assert(member_ids.has(String(suggestion.get("leader_unit_id", ""))), "Fireteam suggestion leader is a member")
		_assert(String(suggestion.get("suggestion_policy", "")) == "balanced_not_optimal", "Fireteam suggestion documents non-perfect policy")
		for unit_id in member_ids:
			_assert(not seen_units.has(unit_id), "Fireteam suggestions do not duplicate unit %s" % unit_id)
			seen_units[unit_id] = true
	_assert(seen_units.size() == int(roster.get("roster_size", 0)), "Fireteam suggestions cover every generated unit")
	var boundary: Dictionary = Dictionary(roster.get("multiplayer_boundary", {}))
	_assert(String(boundary.get("ownership_scope", "")) == "player_profile_local", "Roster multiplayer boundary is per player profile")
	_assert(String(boundary.get("snapshot_policy", "")).contains("do_not_publish_full_private_roster"), "Roster snapshot policy avoids leaking private full roster")


func _test_main_menu_first_start_and_new_team_boundary() -> void:
	var main_menu := MAIN_MENU_SCENE.instantiate()
	main_menu.set("_start_roster_profile_id", "task_232_menu")
	main_menu.set("_start_roster_save_path", "user://ui_native_r2_verifier/task232/roster.json")
	main_menu.set("_settings_config_path", "user://ui_native_r2_verifier/task232/settings.cfg")
	root.add_child(main_menu)
	await _wait_frames(3)
	main_menu.call("set_start_roster_seed_for_tests", "task232_menu", 24)
	var snapshot: Dictionary = Dictionary(main_menu.call("get_start_roster_snapshot"))
	_assert(bool(snapshot.get("valid", false)) and bool(snapshot.get("has_roster", false)), "Main menu creates first-start roster in memory")
	_assert(int(snapshot.get("roster_size", 0)) == 24, "Main menu first-start roster uses default size")
	_assert(bool(snapshot.get("new_roster_button_visible", false)), "Main menu exposes New Team button")
	_assert(String(snapshot.get("new_roster_button_text", "")).contains("Neues Skirmish-Team"), "New Team button identifies its existing Skirmish generation scope")
	var prompt: Dictionary = Dictionary(main_menu.call("request_new_start_roster"))
	snapshot = Dictionary(main_menu.call("get_start_roster_snapshot"))
	_assert(bool(prompt.get("requires_confirmation", false)), "New Team request requires confirmation when roster exists")
	_assert(bool(snapshot.get("reset_confirmation_pending", false)), "Main menu records pending roster reset confirmation")
	_assert(String(snapshot.get("seed", "")) == "task232_menu", "Request alone does not replace existing roster")
	var confirmed: Dictionary = Dictionary(main_menu.call("confirm_new_start_roster"))
	var confirmed_summary: Dictionary = Dictionary(confirmed.get("summary", {}))
	_assert(bool(confirmed.get("created", false)) and bool(confirmed_summary.get("valid", false)), "Confirmed New Team generates a replacement roster")
	snapshot = Dictionary(main_menu.call("get_start_roster_snapshot"))
	_assert(not bool(snapshot.get("reset_confirmation_pending", true)), "Confirmation clears reset boundary")
	_assert(String(snapshot.get("seed", "")).contains("reset"), "Confirmed roster uses an explicit reset seed")
	_assert(main_menu.find_child("SimulationRoot", true, false) == null, "Roster generation from main menu does not create gameplay SimulationRoot")
	main_menu.queue_free()
	await _wait_frames(2)


func _roster_fingerprint(roster: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray([
		String(roster.get("seed", "")),
		str(int(roster.get("roster_size", 0))),
	])
	for unit_variant in Array(roster.get("units", [])):
		var unit: Dictionary = Dictionary(unit_variant)
		var skills: Dictionary = Dictionary(unit.get("skill_values", {}))
		parts.append("%s|%s|%s|%s|%.3f|%.3f|%.3f|%.3f|%s" % [
			String(unit.get("unit_id", "")),
			String(unit.get("display_name", "")),
			String(unit.get("callsign", "")),
			String(unit.get("roster_role_category", "")),
			float(skills.get("accuracy", 0.0)),
			float(skills.get("speed", 0.0)),
			float(skills.get("leadership", 0.0)),
			float(skills.get("toughness", 0.0)),
			",".join(PackedStringArray(unit.get("trait_ids", PackedStringArray()))),
		])
	return "\n".join(parts)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
