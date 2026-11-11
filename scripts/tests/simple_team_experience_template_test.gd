extends SceneTree
const CONFIG = preload("res://scripts/meta/skirmish_start_configuration.gd")
const POINTS = preload("res://scripts/meta/skirmish_points_catalog.gd")
var passed := 0
var failed := 0
func _init() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	passed += int(ok)
	failed += int(not ok)
	if not ok: push_error(label)
func run() -> void:
	var config := CONFIG.new()
	for category: String in ["operator", "pilot", "medic"]:
		for level: String in POINTS.EXPERIENCE:
			var unit := {"unit_id": "old_person", "display_name": "Existing name", "portrait_id": "portrait",
				"role_id": "combat_medic" if category == "medic" else "dropship_pilot" if category == "pilot" else "security_guard",
				"roster_role_category": category, "is_fireteam_lead": category == "operator", "fireteam_id": "ft7",
				"armor_id": "heavy", "weapon_1_id": "sniper", "trait_ids": ["calm"], "progression": {"mission_count": 9}}
			var original := unit.duplicate(true)
			var result: Dictionary = config.build_experience_patch(unit, level)
			check(result.ok and unit == original, "Pure proposal never changes the old profile")
			var reference := unit.duplicate(true)
			config._apply_points_profile(reference, {"role": category, "experience": level, "armor": "suit", "weapon": "pistol"}, category == "pilot", category == "operator")
			for group: String in ["skill_values", "communication_values", "behavior_axes", "platform_values"]:
				check(result.patch[group] == reference[group], "Template reuses existing points profile " + group)
			var edited := unit.duplicate(true)
			edited.merge(result.patch, true)
			for key: String in original:
				check(edited[key] == original[key], "Identity, role, assignment, loadout and history survive: " + key)
			check(is_equal_approx(edited.skill_values.accuracy, POINTS.EXPERIENCE[level].value), "Three existing experience levels remain canonical")
			check(edited.skill_accuracy == edited.skill_values.accuracy and edited.accuracy == edited.skill_accuracy, "Compatibility aliases equal canonical values")
	check(not config.build_experience_patch({}, "missing").ok, "Unknown experience is rejected")
	print("SIMPLE_TEAM_EXPERIENCE ", passed, " passed, ", failed, " failed")
	quit(0 if failed == 0 else 1)
