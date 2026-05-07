extends SceneTree

const FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_behavior_resolver.gd")
const COMMANDER_INTENT_SCRIPT: GDScript = preload("res://scripts/command/commander_intent.gd")
const MULTI_PLAN_SCRIPT: GDScript = preload("res://scripts/tactical/multi_fireteam_plan_resolver.gd")
const MISSION_PROGRESSION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/mission_progression_resolver.gd")
const META_UNIT_PROFILE_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile.gd")
const CHARACTER_SHEET_FORMATTER_SCRIPT: GDScript = preload("res://scripts/meta/character_sheet_formatter.gd")
const MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_snapshot_contract.gd")

const CONTRACT_PATH: String = "res://docs/dev/fireteam_leader_tactical_progression.md"
const TASK_PATH: String = "res://docs/tasks/TASK_273_fireteam_leader_skill_tactical_progression.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const HELP_PATH: String = "res://data/contextual_help_catalog.json"

var _passed: int = 0
var _failed: int = 0


class UnitStub:
	extends RefCounted

	var unit_id: String = ""
	var fireteam_id: String = ""
	var is_fireteam_lead: bool = false
	var skill_values: Dictionary = {}
	var communication_values: Dictionary = {}
	var behavior_axes: Dictionary = {}
	var progression: Dictionary = {}
	var trait_ids: PackedStringArray = PackedStringArray()
	var vital_state: String = "fit"

	func _init(data: Dictionary = {}) -> void:
		unit_id = String(data.get("unit_id", "")).strip_edges()
		fireteam_id = String(data.get("fireteam_id", "")).strip_edges().to_lower()
		is_fireteam_lead = bool(data.get("is_fireteam_lead", false))
		skill_values = Dictionary(data.get("skill_values", {})).duplicate(true)
		communication_values = Dictionary(data.get("communication_values", {})).duplicate(true)
		behavior_axes = Dictionary(data.get("behavior_axes", {})).duplicate(true)
		progression = Dictionary(data.get("progression", {})).duplicate(true)
		trait_ids = PackedStringArray(data.get("trait_ids", PackedStringArray()))
		vital_state = String(data.get("vital_state", "fit")).strip_edges().to_lower()

	func get_unit_id() -> String:
		return unit_id

	func get_fireteam_id() -> String:
		return fireteam_id

	func get_vital_state() -> String:
		return vital_state

	func get_leadership_skill() -> float:
		return float(skill_values.get("leadership", 0.5))

	func get_toughness_skill() -> float:
		return float(skill_values.get("toughness", 0.5))

	func get_accuracy_skill() -> float:
		return float(skill_values.get("accuracy", 0.5))

	func get_speed_skill() -> float:
		return float(skill_values.get("speed", 0.5))

	func get_discipline() -> float:
		return float(skill_values.get("discipline", behavior_axes.get("order_fidelity", 0.5)))

	func get_recognition() -> float:
		return float(skill_values.get("recognition", 0.5))

	func get_trait_ids() -> PackedStringArray:
		return trait_ids

	func get_character_profile_bundle() -> Dictionary:
		return {
			"core_values": skill_values.duplicate(true),
			"communication_values": communication_values.duplicate(true),
			"behavior_axes": behavior_axes.duplicate(true),
		}


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_273 Fireteam Leader Skill Tactical Progression ===")
	_test_contract_doc()
	_test_low_mid_high_ftl_behavior()
	_test_multi_fireteam_role_quality_uses_ftl_skill()
	_test_mission_progression_debrief_and_sheet()
	_test_multiplayer_public_snapshot_privacy()
	_test_no_ui_truth_mutation()
	_test_task_status()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_contract_doc() -> void:
	var text: String = _read_text(CONTRACT_PATH)
	_assert(not text.is_empty(), "FTL tactical progression contract exists")
	for section in ["Purpose", "Authority Boundary", "Data Contract", "Competencies", "Runtime Effects", "Progression", "Character Sheet and Debrief", "Multiplayer Snapshot", "Non Goals", "Follow-Up Tasks"]:
		_assert(text.contains("## %s" % section), "Contract documents %s" % section)
	for token in ["`plan_quality`", "`communication_clarity`", "`breakout_judgement`", "`spacing_quality`", "MAX_FTL_TACTICAL_GAIN_PER_MISSION", "UI panels may show `FTL Impact`, but they may not set"]:
		_assert(text.contains(token), "Contract contains token %s" % token)


func _test_low_mid_high_ftl_behavior() -> void:
	var low_leader: UnitStub = _make_unit("low_ftl", "blue", 0.24, true)
	var mid_leader: UnitStub = _make_unit("mid_ftl", "blue", 0.55, true)
	var high_leader: UnitStub = _make_unit("high_ftl", "blue", 0.86, true)
	var member_a: UnitStub = _make_unit("member_a", "blue", 0.52, false)
	var member_b: UnitStub = _make_unit("member_b", "blue", 0.58, false)
	var low_profile = FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call("resolve_profile", "blue", [low_leader, member_a, member_b], low_leader, "take", Vector2(512.0, 512.0), null, "normal")
	var mid_profile = FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call("resolve_profile", "blue", [mid_leader, member_a, member_b], mid_leader, "take", Vector2(512.0, 512.0), null, "normal")
	var high_profile = FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call("resolve_profile", "blue", [high_leader, member_a, member_b], high_leader, "take", Vector2(512.0, 512.0), null, "normal")
	var low_snapshot: Dictionary = Dictionary(Dictionary(low_profile.metadata).get("ftl_tactical_skill", {}))
	var high_snapshot: Dictionary = Dictionary(Dictionary(high_profile.metadata).get("ftl_tactical_skill", {}))
	_assert(float(high_profile.order_fidelity) > float(low_profile.order_fidelity) + 0.08, "High FTL has better order fidelity than low FTL")
	_assert(float(mid_profile.order_fidelity) > float(low_profile.order_fidelity), "Mid FTL sits above low FTL")
	_assert(float(high_profile.reaction_delay_seconds) < float(low_profile.reaction_delay_seconds), "High FTL reacts faster than low FTL")
	_assert(float(high_snapshot.get("plan_quality", 0.0)) > float(low_snapshot.get("plan_quality", 0.0)) + 0.18, "High FTL plan quality is meaningfully higher")
	_assert(float(high_snapshot.get("plan_quality", 0.0)) <= 0.88 and float(low_snapshot.get("plan_quality", 0.0)) >= 0.22, "FTL plan quality stays inside fair bounds")


func _test_multi_fireteam_role_quality_uses_ftl_skill() -> void:
	var target_position: Vector2 = Vector2(640.0, 512.0)
	var intent = COMMANDER_INTENT_SCRIPT.new({
		"verb": "take",
		"coordinated_fireteam_ids": PackedStringArray(["raw", "veteran"]),
		"target_position": target_position,
		"target_area_id": "objective_273",
		"sync_group_id": "task273",
		"phase": 1,
	})
	var contexts: Array = [
		{
			"fireteam_id": "raw",
			"display_label": "RAW",
			"position": Vector2(220.0, 512.0),
			"leader_profile": _leader_data("raw_lead", "raw", 0.26),
			"leadership": 0.34,
			"discipline": 0.46,
			"cohesion": 0.42,
			"speed": 0.80,
			"accuracy": 0.55,
			"readiness": 1.0,
			"member_count": 4,
		},
		{
			"fireteam_id": "veteran",
			"display_label": "VET",
			"position": Vector2(260.0, 540.0),
			"leader_profile": _leader_data("vet_lead", "veteran", 0.86),
			"leadership": 0.78,
			"discipline": 0.76,
			"cohesion": 0.78,
			"speed": 0.62,
			"accuracy": 0.60,
			"readiness": 1.0,
			"member_count": 4,
		},
	]
	var plan: Dictionary = Dictionary(MULTI_PLAN_SCRIPT.call("resolve_area_plan", intent, contexts, {
		"plan_id": "task273_multi",
		"phase": 1,
		"min_spacing": 96.0,
		"area_context": {"center_position": target_position},
	}))
	var assignments: Array = Array(plan.get("role_assignments", []))
	var vet_assignment: Dictionary = _assignment_for(assignments, "veteran")
	var raw_assignment: Dictionary = _assignment_for(assignments, "raw")
	_assert(String(vet_assignment.get("role", "")) == "lead", "Better FTL is proposed as lead role")
	_assert(float(vet_assignment.get("plan_quality", 0.0)) > float(raw_assignment.get("plan_quality", 0.0)), "Role assignments expose higher plan quality")
	_assert(float(Dictionary(vet_assignment.get("execution_plan", {})).get("planning_quality", 0.0)) > float(Dictionary(raw_assignment.get("execution_plan", {})).get("planning_quality", 0.0)), "Execution plans receive FTL quality factors")
	_assert(String(plan.get("mission_control_text", "")).contains("PLAN"), "Plan feedback remains available for #18")


func _test_mission_progression_debrief_and_sheet() -> void:
	var leader: Dictionary = _leader_data("anja", "blue", 0.62)
	leader["display_name"] = "Anja"
	leader["is_fireteam_lead"] = true
	var member: Dictionary = _leader_data("talia", "blue", 0.50)
	member["display_name"] = "Talia"
	member["is_fireteam_lead"] = false
	var roster: Dictionary = {
		"units": [leader, member],
		"relationship_pairs": [],
	}
	var mission_result: Dictionary = {
		"mission_id": "task273_progression",
		"mission_outcome": "success",
		"result": "success",
		"objective_captured": true,
		"selected_unit_ids": PackedStringArray(["anja", "talia"]),
		"selected_fireteam_ids": PackedStringArray(["blue", "blue"]),
		"team_states": [
			{"unit_id": "anja", "display_name": "Anja", "fireteam_id": "blue", "vital_state": "alive", "health_points": 10},
			{"unit_id": "talia", "display_name": "Talia", "fireteam_id": "blue", "vital_state": "alive", "health_points": 10},
		],
		"unit_events": {
			"anja": {"unit_id": "anja", "objective_participation": true, "issued_orders": true, "coordinated_plan": true, "contact_report": true, "breakout_decision": true},
			"talia": {"unit_id": "talia", "fired_weapon": true},
		},
	}
	var result: Dictionary = Dictionary(MISSION_PROGRESSION_RESOLVER_SCRIPT.call("apply_mission_result", roster, mission_result))
	var updated_leader: Dictionary = _find_unit(Array(Dictionary(result.get("updated_roster", {})).get("units", [])), "anja")
	var ftl_progression: Dictionary = Dictionary(Dictionary(updated_leader.get("progression", {})).get("ftl_tactical", {}))
	var ftl_snapshot: Dictionary = Dictionary(updated_leader.get("ftl_tactical_progression", {}))
	var previous_missions_led: int = int(Dictionary(Dictionary(leader.get("progression", {})).get("ftl_tactical", {})).get("missions_led", 0))
	_assert(int(ftl_progression.get("missions_led", 0)) == previous_missions_led + 1, "FTL mission count progresses")
	_assert(float(ftl_progression.get("last_gain", 0.0)) > 0.0 and float(ftl_progression.get("last_gain", 0.0)) <= 0.014, "FTL progression gain is positive and capped")
	_assert(not ftl_snapshot.is_empty() and String(updated_leader.get("ftl_tactical_effect_text", "")).contains("Plan"), "Updated leader stores compact FTL effect text")
	_assert(_events_contain(Array(result.get("all_character_events", [])), "ftl_tactical_progression"), "Debrief event list includes FTL tactical progression")
	var profile = META_UNIT_PROFILE_SCRIPT.new(updated_leader)
	var view_model: Dictionary = Dictionary(CHARACTER_SHEET_FORMATTER_SCRIPT.call("build_sheet_view_model", profile))
	var row: Dictionary = _row_for_label(Array(view_model.get("progress_rows", [])), "FTL Impact")
	_assert(String(row.get("help_id", "")) == "character_sheet.ftl_tactical_impact", "Character Sheet exposes FTL Impact help id")
	_assert(String(row.get("value_text", "")).contains("Plan"), "Character Sheet summarizes tactical impact")
	_assert(_help_catalog_has("character_sheet.ftl_tactical_impact"), "Help catalog contains FTL Impact entry")


func _test_multiplayer_public_snapshot_privacy() -> void:
	var contract = MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT.new()
	var snapshot: Dictionary = Dictionary(contract.call("build_state_snapshot", {
		"tick": 7,
		"fireteam_tactical": [
			{
				"fireteam_id": "blue",
				"unit_id": "anja",
				"plan_quality": 0.81,
				"communication_clarity": 0.77,
				"breakout_judgement": 0.73,
				"spacing_quality": 0.70,
				"contact_report_quality": 0.76,
				"reaction_delay_seconds": 0.18,
				"tempo_modifier": 1.08,
				"effect_label": "seasoned_ftl",
				"mission_history": [{"mission_id": "private"}],
				"relationship_links": [{"target_unit_id": "private"}],
				"leader_profile": {"biography_text": "private"},
				"effect_text": "private text",
			},
		],
	}))
	var entries: Array = Array(snapshot.get("fireteam_tactical", []))
	_assert(entries.size() == 1, "Snapshot keeps public fireteam tactical entry")
	var entry: Dictionary = Dictionary(entries[0])
	_assert(float(entry.get("plan_quality", 0.0)) == 0.81, "Snapshot keeps tactical display quality")
	for forbidden_key in ["mission_history", "relationship_links", "leader_profile", "biography_text", "effect_text"]:
		_assert(not entry.has(forbidden_key), "Snapshot strips private key %s" % forbidden_key)


func _test_no_ui_truth_mutation() -> void:
	for path in [
		"res://scripts/tactical/fireteam_behavior_resolver.gd",
		"res://scripts/tactical/multi_fireteam_plan_resolver.gd",
		"res://docs/dev/fireteam_leader_tactical_progression.md",
	]:
		var text: String = _read_text(path)
		_assert(not text.contains("extends Control"), "%s is not UI code" % path)
		_assert(not text.contains("assign_unit_command"), "%s does not assign UnitCommands" % path)
		_assert(not text.contains("enqueue_command"), "%s does not enqueue SimulationRoot commands" % path)


func _test_task_status() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "TASK_273 is marked implemented")
	_assert(not task_text.contains("- [ ]"), "TASK_273 checklist is complete")
	_assert(status_text.contains("### TASK_273 - Fireteam Leader Skill Tactical Progression"), "Implementation status has TASK_273 section")
	_assert(status_text.contains("fireteam_leader_tactical_progression.md"), "Implementation status references FTL contract")


func _make_unit(unit_id: String, fireteam_id: String, quality: float, is_lead: bool) -> UnitStub:
	return UnitStub.new(_leader_data(unit_id, fireteam_id, quality, is_lead))


func _leader_data(unit_id: String, fireteam_id: String, quality: float, is_lead: bool = true) -> Dictionary:
	var q: float = clampf(quality, 0.0, 1.0)
	return {
		"unit_id": unit_id,
		"display_name": unit_id.capitalize(),
		"fireteam_id": fireteam_id,
		"team_id": "team_alpha",
		"is_fireteam_lead": is_lead,
		"skill_values": {
			"leadership": q,
			"discipline": clampf(q * 0.86 + 0.08, 0.0, 1.0),
			"awareness": clampf(q * 0.76 + 0.12, 0.0, 1.0),
			"recognition": clampf(q * 0.80 + 0.10, 0.0, 1.0),
			"speed": clampf(q * 0.60 + 0.20, 0.0, 1.0),
			"accuracy": clampf(q * 0.55 + 0.25, 0.0, 1.0),
			"toughness": clampf(q * 0.60 + 0.20, 0.0, 1.0),
		},
		"communication_values": {
			"speech_quality": clampf(q * 0.88 + 0.06, 0.0, 1.0),
			"speech_quantity": 0.50,
		},
		"behavior_axes": {
			"initiative": clampf(q * 0.82 + 0.08, 0.0, 1.0),
			"order_fidelity": clampf(q * 0.86 + 0.08, 0.0, 1.0),
			"contact_stability": clampf(q * 0.78 + 0.10, 0.0, 1.0),
			"autonomy": clampf(q * 0.74 + 0.12, 0.0, 1.0),
		},
		"progression": {
			"xp": int(round(q * 12.0)),
			"missions_completed": int(round(q * 5.0)),
			"morale": clampf(0.40 + q * 0.32, 0.0, 1.0),
			"frustration": clampf(0.30 - q * 0.18, 0.0, 1.0),
			"fireteam_cohesion_by_id": {fireteam_id: clampf(0.35 + q * 0.46, 0.0, 1.0)},
			"ftl_tactical": {
				"tactical_sense": clampf(q * 0.82 + 0.08, 0.0, 1.0),
				"communication": clampf(q * 0.84 + 0.08, 0.0, 1.0),
				"discipline": clampf(q * 0.78 + 0.10, 0.0, 1.0),
				"initiative": clampf(q * 0.76 + 0.12, 0.0, 1.0),
				"team_cohesion": clampf(0.34 + q * 0.48, 0.0, 1.0),
				"missions_led": int(round(q * 5.0)),
			},
		},
		"relationship_links": [],
		"mission_history": [],
		"fireteam_history": [],
		"availability_status": "active",
	}


func _assignment_for(assignments: Array, fireteam_id: String) -> Dictionary:
	for assignment_variant in assignments:
		var assignment: Dictionary = Dictionary(assignment_variant)
		if String(assignment.get("fireteam_id", "")).strip_edges().to_lower() == fireteam_id:
			return assignment
	return {}


func _find_unit(units: Array, unit_id: String) -> Dictionary:
	for unit_variant in units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = Dictionary(unit_variant)
		if String(unit.get("unit_id", "")).strip_edges() == unit_id:
			return unit
	return {}


func _events_contain(events: Array, event_type: String) -> bool:
	for event_variant in events:
		if typeof(event_variant) == TYPE_DICTIONARY and String(Dictionary(event_variant).get("event_type", "")) == event_type:
			return true
	return false


func _row_for_label(rows: Array, label: String) -> Dictionary:
	for row_variant in rows:
		if typeof(row_variant) == TYPE_DICTIONARY and String(Dictionary(row_variant).get("label", "")) == label:
			return Dictionary(row_variant)
	return {}


func _help_catalog_has(help_id: String) -> bool:
	var text: String = _read_text(HELP_PATH)
	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return false
	for entry_variant in Array(Dictionary(parsed).get("entries", [])):
		if typeof(entry_variant) == TYPE_DICTIONARY and String(Dictionary(entry_variant).get("help_id", "")) == help_id:
			return true
	return false


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
