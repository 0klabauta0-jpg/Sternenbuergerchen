extends SceneTree
const CONFIG = preload("res://scripts/meta/skirmish_start_configuration.gd")
const FORMAT = preload("res://scripts/meta/character_sheet_formatter.gd")
const PROFILE = preload("res://scripts/meta/meta_unit_profile.gd")
const MATH = preload("res://scripts/npc/unit_profile_math.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	checks += 1
	failures += int(not value)
	print("PROFILE_READOUT ",label,"=",value)
func unit(tier: String, role: String = "operator", lead: bool = false) -> Dictionary:
	var result := {"unit_id":"private_person","display_name":"Private Person","role_id":"dropship_pilot" if role == "pilot" else "security_guard","roster_role_category":role,"is_fireteam_lead":lead,"trait_ids":[],"mission_history":[{"id":"kept"}],"armor_id":"heavy"}
	result.merge(CONFIG.new().build_experience_patch(result,tier).patch,true)
	return result
func run() -> void:
	for tier: String in ["junior","trained","veteran"]:
		for context: Array in [["operator",false],["pilot",false],["operator",true]]:
			var raw := unit(tier,context[0],context[1])
			var matched: Dictionary = CONFIG.new().match_experience_template(raw)
			var readout: Dictionary = FORMAT.build_experience_readout(PROFILE.new(raw))
			check(matched.matches_template and matched.experience_id == tier and String(readout.label).begins_with("Entspricht Vorlage:"),tier+"_"+context[0]+"_lead"+str(context[1]))
	var custom := unit("veteran")
	var built = load("res://scripts/meta/meta_unit_profile_builder.gd").build_from_identity_config(unit("trained","medic",true))
	check(FORMAT.get_experience_label(built) == "Entspricht Vorlage: Mittelerfahren","existing_profile_builder_preserves_paid_template_equivalence")
	for group: String in ["skill_values","communication_values","behavior_axes","platform_values"]:
		var altered := custom.duplicate(true)
		var key: String = altered[group].keys()[0]
		altered[group][key] = .123
		var result: Dictionary = FORMAT.build_experience_readout(PROFILE.new(altered))
		check(result.label == "Individuelles Profil", "custom_"+group+"_not_a_tier")
	var mixed := custom.duplicate(true)
	mixed.skill_values.accuracy = 1.0
	mixed.skill_values.speed = .44 # Same old three-skill average as veteran.
	check(FORMAT.get_experience_label(PROFILE.new(mixed)) == "Individuelles Profil","same_average_does_not_invent_veteran")
	var before := JSON.stringify(mixed)
	var profile = PROFILE.new(mixed)
	var profile_before := JSON.stringify(profile.to_dict())
	var readout: Dictionary = FORMAT.build_experience_readout(profile)
	var canonical := mixed.duplicate(true)
	for group: String in ["skill_values","communication_values","behavior_axes","platform_values"]:
		for key: String in canonical[group]: canonical[key] = canonical[group][key]
	var expected: Dictionary = MATH.build_character_bundle(canonical).combat_effects
	check(readout.profile_effects == expected,"effects_use_actual_canonical_groups_not_stale_flat_aliases")
	var with_trait := mixed.duplicate(true)
	with_trait.trait_ids = ["reckless"]
	check(FORMAT.build_experience_readout(PROFILE.new(with_trait)).profile_effects == expected,"already_effective_profile_values_do_not_receive_traits_twice")
	check(String(readout.effects_text).begins_with("Profilanteil:") and String(readout.effects_detail).contains("Ausrüstung"),"profile_contribution_is_not_final_runtime_speed")
	check(JSON.stringify(mixed) == before and JSON.stringify(profile.to_dict()) == profile_before,"input_profile_identity_loadout_history_unchanged")
	readout.profile_effects.speed_multiplier = 999.0
	check(FORMAT.build_experience_readout(profile).profile_effects == expected,"readout_results_are_independent")
	var invalid := custom.duplicate(true)
	invalid.behavior_axes.initiative = NAN
	check(not CONFIG.new().match_experience_template(invalid).matches_template and FORMAT.build_experience_readout(PROFILE.new(invalid)).effects_text.is_empty(),"nan_not_a_template_or_effect")
	invalid = custom.duplicate(true)
	invalid.communication_values.speech_quality = "0.72"
	check(not CONFIG.new().match_experience_template(invalid).matches_template and FORMAT.build_experience_readout(PROFILE.new(invalid)).effects_text.is_empty(),"text_number_not_a_template_or_effect")
	invalid = custom.duplicate(true)
	invalid.platform_values.erase("fighter_piloting")
	check(not CONFIG.new().match_experience_template(invalid).matches_template,"incomplete_group_not_a_template")
	check(FORMAT.get_experience_label(null) == "Keine Einschätzung","null_is_unavailable")
	print("PROFILE_READOUT_RESULT checks=",checks," failures=",failures)
	quit(0 if failures == 0 else 1)
