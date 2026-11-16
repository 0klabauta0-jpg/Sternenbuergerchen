extends SceneTree

const START_ROSTER_GENERATOR_SCRIPT: GDScript = preload("res://scripts/meta/start_roster_generator.gd")
const MISSION_PROGRESSION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/mission_progression_resolver.gd")
const PLAYER_ROSTER_STORE_SCRIPT: GDScript = preload("res://scripts/meta/player_roster_store.gd")
const ROSTER_RELATIONSHIP_MODEL_SCRIPT: GDScript = preload("res://scripts/meta/roster_relationship_model.gd")
const DEBRIEF_TEST_SCENE: PackedScene = preload("res://scenes/meta/debrief_test_screen.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_237 Mission Progression XP Morale Frustration ===")
	_test_successful_mission_progression_updates_units()
	_test_bad_teamfit_and_downed_unit_create_bounded_penalties()
	_test_progression_save_roundtrip()
	await _test_debrief_renders_character_updates()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_successful_mission_progression_updates_units() -> void:
	var roster: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", "task237_success", 24))
	var units: Array = Array(roster.get("units", []))
	var first: Dictionary = Dictionary(units[0])
	var second: Dictionary = Dictionary(units[1])
	var selected_ids: PackedStringArray = PackedStringArray([String(first.get("unit_id", "")), String(second.get("unit_id", ""))])
	var fireteam_id: String = String(first.get("fireteam_id", "blue")).strip_edges().to_lower()
	var before_affinity: float = float(Dictionary(ROSTER_RELATIONSHIP_MODEL_SCRIPT.call("get_affinity_between", units, selected_ids[0], selected_ids[1], true)).get("affinity", 0.0))
	var mission_result: Dictionary = _build_mission_result(selected_ids, PackedStringArray([fireteam_id, fireteam_id]), true)
	mission_result["unit_events"] = {
		selected_ids[0]: {"unit_id": selected_ids[0], "objective_participation": true, "fired_weapon": true},
		selected_ids[1]: {"unit_id": selected_ids[1], "medic_action": true, "healed": true},
	}
	var result: Dictionary = Dictionary(MISSION_PROGRESSION_RESOLVER_SCRIPT.call("apply_mission_result", roster, mission_result))
	var updated_roster: Dictionary = Dictionary(result.get("updated_roster", {}))
	var updated_first: Dictionary = _find_unit(Array(updated_roster.get("units", [])), selected_ids[0])
	var updated_second: Dictionary = _find_unit(Array(updated_roster.get("units", [])), selected_ids[1])
	_assert(int(Dictionary(updated_first.get("progression", {})).get("xp", 0)) > int(Dictionary(first.get("progression", {})).get("xp", 0)), "Objective participant gains XP")
	_assert(int(Dictionary(updated_second.get("progression", {})).get("missions_completed", 0)) == 1, "Deployed medic records mission completion")
	_assert(float(Dictionary(updated_first.get("skill_values", {})).get("accuracy", 0.0)) > float(Dictionary(first.get("skill_values", {})).get("accuracy", 0.0)), "Fired weapon slowly improves accuracy")
	_assert(float(Dictionary(updated_first.get("progression", {})).get("morale", 0.0)) > 0.50, "Successful mission can raise morale")
	var after_affinity: float = float(Dictionary(ROSTER_RELATIONSHIP_MODEL_SCRIPT.call("get_affinity_between", Array(updated_roster.get("units", [])), selected_ids[0], selected_ids[1], true)).get("affinity", 0.0))
	_assert(after_affinity >= before_affinity, "Successful shared mission does not reduce known team affinity")
	_assert(Array(result.get("character_events", [])).size() >= 2 and Array(result.get("character_events", [])).size() <= 5, "Debrief emits 2 to 5 character events")


func _test_bad_teamfit_and_downed_unit_create_bounded_penalties() -> void:
	var roster: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", "task237_penalty", 24))
	var units: Array = Array(roster.get("units", [])).duplicate(true)
	var first: Dictionary = Dictionary(units[0]).duplicate(true)
	var second: Dictionary = Dictionary(units[1]).duplicate(true)
	first["progression"] = {"xp": 0, "missions_completed": 0, "morale": 0.02, "frustration": 0.98}
	second["progression"] = {"xp": 0, "missions_completed": 0, "morale": 0.50, "frustration": 0.00}
	units[0] = first
	units[1] = second
	var tension_pair: Dictionary = Dictionary(ROSTER_RELATIONSHIP_MODEL_SCRIPT.call("make_pair", String(first.get("unit_id", "")), String(second.get("unit_id", "")), -0.65, ["tension"], "task237_penalty", true))
	units = ROSTER_RELATIONSHIP_MODEL_SCRIPT.call("apply_relationships_to_units", units, [tension_pair], false)
	roster["units"] = units
	var selected_ids: PackedStringArray = PackedStringArray([String(first.get("unit_id", "")), String(second.get("unit_id", ""))])
	var fireteam_id: String = "task237_badfit"
	var mission_result: Dictionary = _build_mission_result(selected_ids, PackedStringArray([fireteam_id, fireteam_id]), false)
	mission_result["team_states"][0]["vital_state"] = "downed"
	mission_result["team_states"][0]["health_points"] = 0
	mission_result["unit_events"] = {
		selected_ids[0]: {"unit_id": selected_ids[0], "downed": true, "role_mismatch": true},
		selected_ids[1]: {"unit_id": selected_ids[1], "role_mismatch": true},
	}
	var result: Dictionary = Dictionary(MISSION_PROGRESSION_RESOLVER_SCRIPT.call("apply_mission_result", roster, mission_result))
	var updated_first: Dictionary = _find_unit(Array(Dictionary(result.get("updated_roster", {})).get("units", [])), selected_ids[0])
	var progression: Dictionary = Dictionary(updated_first.get("progression", {}))
	_assert(float(progression.get("morale", 0.0)) >= 0.0, "Morale is clamped at lower bound")
	_assert(float(progression.get("frustration", 0.0)) <= 1.0, "Frustration is clamped at upper bound")
	_assert(String(updated_first.get("availability_status", "")) == "recovering", "Downed unit enters recovery")
	_assert(not Dictionary(updated_first.get("recovery_state", {})).is_empty(), "Downed unit stores recovery state")
	_assert(_events_contain(Array(result.get("character_events", [])), "recovery"), "Debrief includes recovery event for downed unit")


func _test_progression_save_roundtrip() -> void:
	var profile_id: String = "task237_progression_roundtrip"
	var save_path: String = "user://profiles/%s/roster_v1.json" % profile_id
	PLAYER_ROSTER_STORE_SCRIPT.call("delete_roster_for_tests", profile_id, save_path)
	var roster: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", "task237_save", 24, profile_id))
	var units: Array = Array(roster.get("units", []))
	var selected_ids: PackedStringArray = PackedStringArray([String(Dictionary(units[0]).get("unit_id", "")), String(Dictionary(units[1]).get("unit_id", ""))])
	var fireteam_id: String = String(Dictionary(units[0]).get("fireteam_id", "blue")).strip_edges().to_lower()
	var mission_result: Dictionary = _build_mission_result(selected_ids, PackedStringArray([fireteam_id, fireteam_id]), true)
	mission_result["unit_events"] = {selected_ids[0]: {"unit_id": selected_ids[0], "objective_participation": true, "fired_weapon": true}}
	var progression_result: Dictionary = Dictionary(MISSION_PROGRESSION_RESOLVER_SCRIPT.call("apply_mission_result", roster, mission_result))
	var updated_roster: Dictionary = Dictionary(progression_result.get("updated_roster", {}))
	var save_result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("save_roster", updated_roster, profile_id, save_path))
	_assert(bool(save_result.get("ok", false)), "Player roster store saves progression roster")
	var load_result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("load_roster", profile_id, save_path))
	_assert(bool(load_result.get("ok", false)), "Player roster store loads progression roster")
	var loaded_roster: Dictionary = Dictionary(load_result.get("roster", {}))
	_assert(int(loaded_roster.get("progression_schema_version", 0)) == 1, "Progression schema version roundtrips")
	var loaded_unit: Dictionary = _find_unit(Array(loaded_roster.get("units", [])), selected_ids[0])
	_assert(int(Dictionary(loaded_unit.get("progression", {})).get("xp", 0)) > 0, "Saved roster roundtrips XP")
	_assert(not Array(loaded_unit.get("mission_history", [])).is_empty(), "Saved roster roundtrips mission history")
	PLAYER_ROSTER_STORE_SCRIPT.call("delete_roster_for_tests", profile_id, save_path)


func _test_debrief_renders_character_updates() -> void:
	var debrief: Control = DEBRIEF_TEST_SCENE.instantiate()
	root.add_child(debrief)
	await process_frame
	debrief.call("set_mission_result", {
		"mission_outcome": "success",
		"result": "success",
		"winning_team_id": "team_alpha",
		"objective_captured": true,
		"duration_seconds": 12.0,
		"team_states": [],
		"character_events": [
			{"summary_text": "Anja helped the objective. +5 XP | morale +0.03"},
			{"summary_text": "Milo gained confidence. morale +0.02 | +4 XP"},
		],
	})
	await process_frame
	var labels: PackedStringArray = _collect_label_texts(debrief)
	# Seit 5500bcbe2 zeigt der Bericht nur die Anzahl; der Einzeltext steht im Originalbericht (TextEdit).
	_assert(_labels_contain(labels, "2 Personenmeldungen"), "Debrief renders character update section")
	debrief.call("open_debrief_details")
	var original: TextEdit = debrief.find_child("DebriefOriginalText", true, false) as TextEdit
	_assert(original != null and original.text.contains("Anja helped the objective"), "Debrief original report holds concise character event")
	debrief.queue_free()
	await process_frame


func _build_mission_result(selected_ids: PackedStringArray, selected_fireteam_ids: PackedStringArray, success: bool) -> Dictionary:
	var team_states: Array = []
	for index in range(selected_ids.size()):
		team_states.append({
			"unit_id": selected_ids[index],
			"display_name": selected_ids[index],
			"fireteam_id": selected_fireteam_ids[index] if index < selected_fireteam_ids.size() else "",
			"vital_state": "alive",
			"health_points": 10,
		})
	return {
		"mission_id": "task237_mission",
		"mission_outcome": "success" if success else "failed",
		"result": "success" if success else "failed",
		"objective_captured": success,
		"selected_unit_ids": selected_ids,
		"selected_fireteam_ids": selected_fireteam_ids,
		"team_states": team_states,
	}


func _find_unit(units: Array, unit_id: String) -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges()
	for unit_variant in units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = Dictionary(unit_variant)
		if String(unit.get("unit_id", "")).strip_edges() == normalized_unit_id:
			return unit
	return {}


func _events_contain(events: Array, event_type: String) -> bool:
	for event_variant in events:
		if typeof(event_variant) == TYPE_DICTIONARY and String(Dictionary(event_variant).get("event_type", "")) == event_type:
			return true
	return false


func _collect_label_texts(root_node: Node) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for node in _collect_nodes(root_node):
		var label := node as Label
		if label != null:
			result.append(label.text)
	return result


func _collect_nodes(root_node: Node) -> Array:
	var nodes: Array = []
	if root_node == null:
		return nodes
	nodes.append(root_node)
	for child in root_node.get_children():
		nodes.append_array(_collect_nodes(child))
	return nodes


func _labels_contain(labels: PackedStringArray, fragment: String) -> bool:
	for text in labels:
		if String(text).contains(fragment):
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
