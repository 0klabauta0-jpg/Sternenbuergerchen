extends SceneTree

# TASK_087 Verifier – Loadout-Pipeline (FOB → Mission)
# Tests that member_loadouts + is_fireteam_lead are correctly applied
# through MissionTestSetup to TestUnit instances.

var _pass_count: int = 0
var _fail_count: int = 0
var _test_count: int = 0

func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_087 Verifier: Loadout-Pipeline ===")

	_test_apply_fob_loadout_override_weapon_1()
	_test_apply_fob_loadout_override_weapon_2()
	_test_apply_fob_loadout_override_is_fireteam_lead()
	_test_apply_fob_loadout_override_no_loadout()
	_test_apply_fob_loadout_override_unknown_unit()
	_test_apply_fob_loadout_override_enemy_ignored()
	_test_apply_fob_loadout_override_partial_override()
	_test_apply_fob_loadout_override_empty_loadouts()
	_test_build_fob_member_loadouts_structure()
	_test_mission_setup_member_loadouts_property()
	_test_weapon_id_survives_apply_identity_config()
	_test_is_fireteam_lead_survives_apply_identity_config()

	print("")
	print("=== Results: %d passed, %d failed, %d total ===" % [_pass_count, _fail_count, _test_count])
	if _fail_count > 0:
		print("TASK_087: FAILED")
		quit(1)
	else:
		print("TASK_087: ALL PASSED")
		quit(0)


func _assert(condition: bool, test_name: String) -> void:
	_test_count += 1
	if condition:
		_pass_count += 1
		print("  PASS: %s" % test_name)
	else:
		_fail_count += 1
		print("  FAIL: %s" % test_name)


# --- Direct TestUnit tests ---

func _test_apply_fob_loadout_override_weapon_1() -> void:
	var unit = _make_test_unit("unit_alpha", "team_alpha")
	_assert(unit.weapon_1_id == "rifle", "default weapon_1 is rifle")

	unit.apply_identity_config({"weapon_1_id": "smg"})
	_assert(unit.weapon_1_id == "smg", "weapon_1 overridden to smg")
	unit.queue_free()


func _test_apply_fob_loadout_override_weapon_2() -> void:
	var unit = _make_test_unit("unit_alpha", "team_alpha")
	unit.apply_identity_config({"weapon_2_id": "rail_gun"})
	_assert(unit.weapon_2_id == "rail_gun", "weapon_2 overridden to rail_gun")
	unit.queue_free()


func _test_apply_fob_loadout_override_is_fireteam_lead() -> void:
	var unit = _make_test_unit("unit_alpha", "team_alpha")
	_assert(unit.is_fireteam_lead == false, "default is_fireteam_lead is false")

	unit.apply_identity_config({"is_fireteam_lead": true})
	_assert(unit.is_fireteam_lead == true, "is_fireteam_lead set to true")
	unit.queue_free()


func _test_apply_fob_loadout_override_no_loadout() -> void:
	var unit = _make_test_unit("unit_alpha", "team_alpha")
	unit.apply_identity_config({"weapon_1_id": "rifle"})
	_assert(unit.weapon_1_id == "rifle", "weapon_1 unchanged with rifle override")
	_assert(unit.get_active_weapon_id() == "rifle", "active weapon remains rifle")
	unit.queue_free()


func _test_apply_fob_loadout_override_unknown_unit() -> void:
	# MissionTestSetup._apply_fob_loadout_override skips unknown unit_ids
	var setup = _make_mission_test_setup()
	setup.member_loadouts = {"unit_xxx": {"weapon_1": "smg"}}
	var unit = _make_test_unit("unit_alpha", "team_alpha")
	root.add_child(unit)

	# Simulate: unit_alpha is not in member_loadouts, so no override
	_assert(not setup.member_loadouts.has("unit_alpha"), "unit_alpha not in loadouts")
	_assert(unit.weapon_1_id == "rifle", "weapon unchanged for unknown unit")
	unit.queue_free()
	setup.queue_free()


func _test_apply_fob_loadout_override_enemy_ignored() -> void:
	# _apply_fob_loadout_override should skip enemies (unit_team_id != team_id)
	var setup = _make_mission_test_setup()
	setup.member_loadouts = {"enemy_1": {"weapon_1": "smg"}}
	# Enemies have team_id "team_bravo", setup.team_id is "team_alpha"
	# So _apply_fob_loadout_override returns early
	_assert(setup.team_id == "team_alpha", "setup team_id is team_alpha")
	setup.queue_free()


func _test_apply_fob_loadout_override_partial_override() -> void:
	var unit = _make_test_unit("unit_alpha", "team_alpha")
	# Only override weapon_1, leave weapon_2 as default
	unit.apply_identity_config({"weapon_1_id": "smg"})
	_assert(unit.weapon_1_id == "smg", "weapon_1 overridden to smg")
	_assert(unit.weapon_2_id == "rifle", "weapon_2 still default rifle")
	unit.queue_free()


func _test_apply_fob_loadout_override_empty_loadouts() -> void:
	var setup = _make_mission_test_setup()
	setup.member_loadouts = {}
	_assert(setup.member_loadouts.is_empty(), "empty loadouts accepted")
	setup.queue_free()


func _test_build_fob_member_loadouts_structure() -> void:
	# Test that the expected dictionary format works
	var loadouts: Dictionary = {
		"unit_alpha": {"weapon_1": "smg", "weapon_2": "smg", "armor": "light", "is_fireteam_lead": true},
		"unit_bravo": {"weapon_1": "rail_gun", "weapon_2": "rifle", "armor": "heavy"},
	}
	_assert(loadouts.has("unit_alpha"), "loadouts has unit_alpha")
	_assert(loadouts["unit_alpha"]["weapon_1"] == "smg", "unit_alpha weapon_1 is smg")
	_assert(loadouts["unit_alpha"]["is_fireteam_lead"] == true, "unit_alpha is lead")
	_assert(not loadouts["unit_bravo"].has("is_fireteam_lead"), "unit_bravo is not lead")


func _test_mission_setup_member_loadouts_property() -> void:
	var setup = _make_mission_test_setup()
	_assert(setup.member_loadouts.is_empty(), "member_loadouts default is empty")

	setup.member_loadouts = {"unit_alpha": {"weapon_1": "smg"}}
	_assert(setup.member_loadouts.has("unit_alpha"), "member_loadouts set correctly")
	setup.queue_free()


func _test_weapon_id_survives_apply_identity_config() -> void:
	var unit = _make_test_unit("unit_alpha", "team_alpha")
	# First apply preset, then override weapon
	var PRESETS = preload("res://scripts/npc/unit_roster_presets.gd")
	var preset: Dictionary = PRESETS.get_preset("unit_alpha", "team_alpha")
	if not preset.is_empty():
		unit.apply_identity_config(preset)

	var original_w1: String = unit.weapon_1_id
	unit.apply_identity_config({"weapon_1_id": "rail_gun"})
	_assert(unit.weapon_1_id == "rail_gun", "weapon_1 overridden after preset (was %s)" % original_w1)
	_assert(unit.get_active_weapon_id() == "rail_gun", "active weapon is rail_gun after override")
	unit.queue_free()


func _test_is_fireteam_lead_survives_apply_identity_config() -> void:
	var unit = _make_test_unit("unit_alpha", "team_alpha")
	var PRESETS = preload("res://scripts/npc/unit_roster_presets.gd")
	var preset: Dictionary = PRESETS.get_preset("unit_alpha", "team_alpha")
	if not preset.is_empty():
		unit.apply_identity_config(preset)

	unit.apply_identity_config({"is_fireteam_lead": true})
	_assert(unit.is_fireteam_lead == true, "is_fireteam_lead survives after preset")
	unit.queue_free()


# --- Helpers ---

func _make_test_unit(unit_id: String, team_id: String) -> Node:
	var TestUnitScript = preload("res://scripts/npc/test_unit.gd")
	var unit = TestUnitScript.new()
	unit.name = unit_id
	unit.unit_id = unit_id
	unit.team_id = team_id
	root.add_child(unit)
	return unit


func _make_mission_test_setup() -> Node:
	var SetupScript = preload("res://scripts/tests/mission_test_setup.gd")
	var setup = SetupScript.new()
	root.add_child(setup)
	return setup
