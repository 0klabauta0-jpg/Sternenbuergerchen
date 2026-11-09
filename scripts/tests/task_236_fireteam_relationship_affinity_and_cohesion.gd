extends SceneTree

const START_ROSTER_GENERATOR_SCRIPT: GDScript = preload("res://scripts/meta/start_roster_generator.gd")
const ROSTER_RELATIONSHIP_MODEL_SCRIPT: GDScript = preload("res://scripts/meta/roster_relationship_model.gd")
const FIRETEAM_COHESION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/fireteam_cohesion_resolver.gd")
const PLAYER_ROSTER_STORE_SCRIPT: GDScript = preload("res://scripts/meta/player_roster_store.gd")
const META_UNIT_PROFILE_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile.gd")
const CHARACTER_SHEET_FORMATTER_SCRIPT: GDScript = preload("res://scripts/meta/character_sheet_formatter.gd")
const FOB_FIRETEAM_CARD_SCRIPT: GDScript = preload("res://scripts/meta/fob_fireteam_card.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_236 Fireteam Relationship Affinity and Cohesion ===")
	_test_start_roster_relationship_generation()
	_test_relationship_roundtrip_in_player_roster_save()
	_test_cohesion_is_deterministic_and_small_modifiers()
	_test_wrong_teamfit_creates_small_penalties()
	_test_character_sheet_relationship_rows()
	await _test_fob_fireteam_card_teamfit_label()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_start_roster_relationship_generation() -> void:
	var roster: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", "task236_generator", 24))
	var validation: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("validate_roster", roster))
	_assert(bool(validation.get("valid", false)), "Start roster validator accepts generated relationships")
	var relationship_pairs: Array = Array(roster.get("relationship_pairs", []))
	var units: Array = Array(roster.get("units", []))
	_assert(not relationship_pairs.is_empty(), "Generator emits relationship pairs")
	_assert(_count_units_with_relationships(units) >= 8, "Several start roster NPCs know someone")
	_assert(_count_relationship_links(units) < units.size() * (units.size() - 1), "Generator does not make every NPC know every other NPC")
	_assert(_max_abs_affinity(units) <= 0.40, "Start roster affinities stay mild")
	var first_fireteam: Dictionary = Dictionary(Array(roster.get("fireteam_suggestions", []))[0])
	var cohesion_snapshot: Dictionary = Dictionary(first_fireteam.get("cohesion_snapshot", {}))
	_assert(float(cohesion_snapshot.get("cohesion", 0.0)) > 0.0, "Fireteam suggestions include cohesion snapshots")


func _test_relationship_roundtrip_in_player_roster_save() -> void:
	var profile_id: String = "task236_relationship_roundtrip"
	var save_path: String = "user://profiles/%s/roster_v1.json" % profile_id
	PLAYER_ROSTER_STORE_SCRIPT.call("delete_roster_for_tests", profile_id, save_path)
	var roster: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", "task236_save", 24, profile_id))
	var save_result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("save_roster", roster, profile_id, save_path))
	_assert(bool(save_result.get("ok", false)), "Player roster store saves relationship roster")
	var load_result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("load_roster", profile_id, save_path))
	_assert(bool(load_result.get("ok", false)), "Player roster store loads relationship roster")
	var loaded_roster: Dictionary = Dictionary(load_result.get("roster", {}))
	_assert(not Array(loaded_roster.get("relationship_pairs", [])).is_empty(), "Roster save roundtrips relationship pairs")
	_assert(_count_units_with_relationships(Array(loaded_roster.get("units", []))) > 0, "Roster save roundtrips unit relationship links")
	PLAYER_ROSTER_STORE_SCRIPT.call("delete_roster_for_tests", profile_id, save_path)


func _test_cohesion_is_deterministic_and_small_modifiers() -> void:
	var units: Array = _build_related_units(0.30, "blue", "task236_positive")
	var snapshot_a: Dictionary = Dictionary(FIRETEAM_COHESION_RESOLVER_SCRIPT.call("build_fireteam_snapshot", "blue", units, "task236_positive_a"))
	var snapshot_b: Dictionary = Dictionary(FIRETEAM_COHESION_RESOLVER_SCRIPT.call("build_fireteam_snapshot", "blue", units, "task236_positive_a"))
	_assert(absf(float(snapshot_a.get("cohesion", 0.0)) - float(snapshot_b.get("cohesion", 0.0))) < 0.0001, "Cohesion is deterministic")
	_assert(float(snapshot_a.get("cohesion", 0.0)) > 0.55, "Positive relationships and history lift cohesion")
	var modifiers: Dictionary = Dictionary(snapshot_a.get("gameplay_modifiers", {}))
	for key in ["morale_delta", "communication_modifier", "coordination_modifier", "advance_readability_modifier"]:
		_assert(absf(float(modifiers.get(key, 0.0))) <= 0.05, "Gameplay modifier %s remains small" % key)


func _test_wrong_teamfit_creates_small_penalties() -> void:
	var units: Array = _build_related_units(-0.45, "mixed", "task236_tense")
	for index in range(units.size()):
		var unit: Dictionary = Dictionary(units[index]).duplicate(true)
		unit["fireteam_history"] = []
		units[index] = unit
	var snapshot: Dictionary = Dictionary(FIRETEAM_COHESION_RESOLVER_SCRIPT.call("build_fireteam_snapshot", "mixed", units, "task236_tense_a"))
	var modifiers: Dictionary = Dictionary(snapshot.get("gameplay_modifiers", {}))
	_assert(float(snapshot.get("average_affinity", 0.0)) < 0.0, "Tense pair carries negative average affinity")
	_assert(float(modifiers.get("coordination_modifier", 0.0)) < 0.0, "Bad teamfit creates a small coordination penalty")
	_assert(float(modifiers.get("coordination_modifier", 0.0)) >= -0.05, "Bad teamfit penalty is bounded")


func _test_character_sheet_relationship_rows() -> void:
	var units: Array = _build_related_units(0.28, "blue", "task236_sheet")
	var tense_pair: Dictionary = Dictionary(ROSTER_RELATIONSHIP_MODEL_SCRIPT.call("make_pair", "task236_sheet_a", "task236_sheet_c", -0.18, ["tension"], "test_tension", true))
	units.append(_build_unit("task236_sheet_c", "Rival", "blue", 0.42, false))
	units = ROSTER_RELATIONSHIP_MODEL_SCRIPT.call("apply_relationships_to_units", units, [tense_pair], false)
	var profile = META_UNIT_PROFILE_SCRIPT.new(Dictionary(units[0]))
	var model: Dictionary = Dictionary(CHARACTER_SHEET_FORMATTER_SCRIPT.call("build_sheet_view_model", profile))
	_assert(_rows_contain(Array(model.get("relationship_rows", [])), "Gute Zusammenarbeit", "Partner"), "Character sheet shows best relationship")
	_assert(_rows_contain(Array(model.get("relationship_rows", [])), "Spannungen", "Rival"), "Character sheet shows worst relationship")


func _test_fob_fireteam_card_teamfit_label() -> void:
	var card: FOBFireteamCard = FOB_FIRETEAM_CARD_SCRIPT.new()
	root.add_child(card)
	card.setup_card("blue", "Blue Team", true, true, "medium", "Lead: A | Members: A, B", "fireteam_list", "Teamfit 63% | steady | affinity +0.22")
	await process_frame
	var teamfit_label := card.get_node("Margin/VBox/TeamfitLabel") as Label
	_assert(teamfit_label != null and teamfit_label.visible, "FOB fireteam card exposes teamfit label")
	_assert(teamfit_label.text.contains("Teamfit 63%"), "FOB fireteam card renders cohesion summary")
	card.queue_free()
	await process_frame


func _build_related_units(affinity: float, fireteam_id: String, prefix: String) -> Array:
	var units: Array = [
		_build_unit("%s_a" % prefix, "Lead", fireteam_id, 0.72, true),
		_build_unit("%s_b" % prefix, "Partner", fireteam_id, 0.44, false),
	]
	var pair: Dictionary = Dictionary(ROSTER_RELATIONSHIP_MODEL_SCRIPT.call("make_pair", "%s_a" % prefix, "%s_b" % prefix, affinity, ["trusts"] if affinity >= 0.0 else ["tension"], "task236_fixture", true))
	return ROSTER_RELATIONSHIP_MODEL_SCRIPT.call("apply_relationships_to_units", units, [pair], true)


func _build_unit(unit_id: String, display_name: String, fireteam_id: String, leadership: float, is_lead: bool) -> Dictionary:
	return {
		"unit_id": unit_id,
		"display_name": display_name,
		"fireteam_id": fireteam_id,
		"is_fireteam_lead": is_lead,
		"skill_values": {
			"accuracy": 0.50,
			"speed": 0.50,
			"leadership": leadership,
			"toughness": 0.50,
		},
		"relationship_links": [],
		"relationship_summary_text": "",
		"fireteam_history": [{"fireteam_id": fireteam_id, "mission_id": "task236_fixture", "result": "stable"}],
		"progression": {"morale": 0.50, "frustration": 0.0},
	}


func _count_units_with_relationships(units: Array) -> int:
	var count: int = 0
	for unit_variant in units:
		if typeof(unit_variant) == TYPE_DICTIONARY and not Array(Dictionary(unit_variant).get("relationship_links", [])).is_empty():
			count += 1
	return count


func _count_relationship_links(units: Array) -> int:
	var count: int = 0
	for unit_variant in units:
		if typeof(unit_variant) == TYPE_DICTIONARY:
			count += Array(Dictionary(unit_variant).get("relationship_links", [])).size()
	return count


func _max_abs_affinity(units: Array) -> float:
	var max_value: float = 0.0
	for unit_variant in units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		for link_variant in Array(Dictionary(unit_variant).get("relationship_links", [])):
			if typeof(link_variant) != TYPE_DICTIONARY:
				continue
			max_value = maxf(max_value, absf(float(Dictionary(link_variant).get("affinity", 0.0))))
	return max_value


func _rows_contain(rows: Array, label_fragment: String, value_fragment: String) -> bool:
	for row_variant in rows:
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = Dictionary(row_variant)
		if String(row.get("label", "")).contains(label_fragment) and String(row.get("value_text", "")).contains(value_fragment):
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
