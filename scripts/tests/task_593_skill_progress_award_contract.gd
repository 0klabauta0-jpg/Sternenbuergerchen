extends SceneTree

const START_ROSTER_GENERATOR_SCRIPT: GDScript = preload("res://scripts/meta/start_roster_generator.gd")
const MISSION_PROGRESSION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/mission_progression_resolver.gd")
const DEBRIEF_SCENE: PackedScene = preload("res://scenes/meta/debrief_test_screen.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_593_skill_progress_award_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const FTL_CONTRACT_PATH: String = "res://docs/dev/fireteam_leader_tactical_progression.md"
const RESOLVER_PATH: String = "res://scripts/meta/mission_progression_resolver.gd"
const META_FLOW_PATH: String = "res://scripts/meta/meta_layer_flow.gd"
const DEBRIEF_SCREEN_PATH: String = "res://scripts/meta/debrief_screen.gd"
const TASK_592_TEST_PATH: String = "res://scripts/tests/task_592_debrief_skill_progress_preview_shell.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_593 Skill Progress Award Contract ===")
	_test_docs_and_wiring()
	await _test_resolver_award_summary_and_debrief_contract()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_593: FAILED")
		quit(1)
		return
	print("TASK_593: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var ftl_contract_text: String = _read_text(FTL_CONTRACT_PATH)
	var resolver_text: String = _read_text(RESOLVER_PATH)
	var meta_flow_text: String = _read_text(META_FLOW_PATH)
	var debrief_text: String = _read_text(DEBRIEF_SCREEN_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_593 task file exists")
	_assert(task_text.contains("Skill Progress Award Contract"), "TASK_593 task file names the task")
	_assert(status_text.contains("TASK_593 - Skill Progress Award Contract"), "Implementation status tracks TASK_593")
	_assert(status_text.contains("TASK_594 - Post Mission Skill Delta Homebase Bridge"), "Implementation status names TASK_594 follow-up")
	_assert(roadmap_text.contains("TASK_593 - Skill Progress Award Contract (implementiert)"), "Roadmap marks TASK_593 implemented")
	_assert(roadmap_text.contains("TASK_594 - Post Mission Skill Delta Homebase Bridge"), "Roadmap names TASK_594 follow-up")
	_assert(report_text.contains("TASK_593 - Skill Progress Award Contract"), "Review workbench tracks TASK_593")
	_assert(report_text.contains("TASK_594 - Post Mission Skill Delta Homebase Bridge"), "Review workbench names TASK_594 follow-up")
	_assert(contract_text.contains("Skill-Progress-Award-Contract"), "Mission feedback contract documents TASK_593")
	_assert(ftl_contract_text.contains("MissionProgressionResolver"), "FTL progression contract remains authoritative")
	_assert(resolver_text.contains("build_award_summary"), "MissionProgressionResolver builds award summary")
	_assert(resolver_text.contains("sternenbuergerchen.skill_progress_award_summary.v1"), "Resolver exposes award summary schema")
	_assert(meta_flow_text.contains("progression_award_summary"), "MetaLayerFlow forwards award summary")
	_assert(debrief_text.contains("get_debrief_skill_award_contract_snapshot"), "Debrief exposes TASK_593 snapshot")
	_assert(debrief_text.contains("SkillAwardSummaryLabel"), "Debrief owns skill award label")
	_assert(FileAccess.file_exists(TASK_592_TEST_PATH), "TASK_592 preview verifier remains available")


func _test_resolver_award_summary_and_debrief_contract() -> void:
	root.size = Vector2i(1920, 1080)
	var roster: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", "task593_awards", 24))
	var units: Array = Array(roster.get("units", [])).duplicate(true)
	var leader: Dictionary = Dictionary(units[0]).duplicate(true)
	var member: Dictionary = Dictionary(units[1]).duplicate(true)
	leader["is_fireteam_lead"] = true
	leader["display_name"] = "Lead Alpha"
	member["display_name"] = "Rifle Alpha"
	units[0] = leader
	units[1] = member
	roster["units"] = units
	var leader_id: String = String(leader.get("unit_id", "lead_alpha"))
	var member_id: String = String(member.get("unit_id", "rifle_alpha"))
	var fireteam_id: String = String(leader.get("fireteam_id", "ft_alpha")).strip_edges().to_lower()
	if fireteam_id.is_empty():
		fireteam_id = "ft_alpha"
	var mission_result: Dictionary = _build_mission_result(leader_id, member_id, fireteam_id)
	var progression_result: Dictionary = Dictionary(MISSION_PROGRESSION_RESOLVER_SCRIPT.call("apply_mission_result", roster, mission_result))
	var award_summary: Dictionary = Dictionary(progression_result.get("award_summary", {}))
	var unit_updates: Array = Array(progression_result.get("unit_updates", []))
	_assert(String(award_summary.get("schema", "")) == "sternenbuergerchen.skill_progress_award_summary.v1", "Award summary reports stable schema")
	_assert(String(award_summary.get("authority", "")) == "MissionProgressionResolver", "Award authority stays in resolver")
	_assert(String(award_summary.get("source", "")) == "progression_unit_updates", "Award source is unit updates")
	_assert(bool(award_summary.get("award_applied", false)), "Award summary describes applied progression")
	_assert(bool(award_summary.get("read_only", false)), "Award summary is read-only")
	_assert(not bool(award_summary.get("ui_sets_gameplay_truth", true)), "Award summary does not set UI truth")
	_assert(int(award_summary.get("unit_award_count", 0)) == unit_updates.size(), "Award summary counts unit updates")
	_assert(int(award_summary.get("total_xp_delta", 0)) > 0, "Award summary totals XP")
	_assert(int(award_summary.get("skill_gain_count", 0)) >= 2, "Award summary totals skill gains")
	_assert(int(award_summary.get("ftl_tactical_gain_count", 0)) >= 1, "Award summary counts FTL tactical gains")
	_assert(float(award_summary.get("max_skill_gain_per_mission", 0.0)) <= 0.018, "Award summary exposes skill cap")
	_assert(_all_awards_read_only(Array(award_summary.get("listed_awards", []))), "Listed awards are read-only")

	var debrief: Node = DEBRIEF_SCENE.instantiate()
	root.add_child(debrief)
	debrief.set("visible", true)
	await _wait_frames(8)
	var debrief_result: Dictionary = mission_result.duplicate(true)
	debrief_result["progression_award_summary"] = award_summary
	debrief_result["progression_unit_updates"] = unit_updates
	debrief_result["progression_summary"] = Dictionary(progression_result.get("summary", {}))
	debrief_result["character_events"] = Array(progression_result.get("character_events", []))
	debrief_result["mini_aar_debrief"] = _build_mini_aar_debrief_payload()
	debrief_result["fireteam_tactical_debrief"] = [
		{"fireteam_id": fireteam_id, "reaction_delay_seconds": 0.42, "plan_quality": 0.76, "tempo_modifier": 1.08, "contact_report_count": 3, "contact_report_quality": 0.72, "morale": 0.68, "frustration": 0.22},
	]
	debrief.call("set_mission_result", debrief_result)
	await _wait_frames(12)
	var preview_snapshot: Dictionary = Dictionary(debrief.call("get_debrief_skill_progress_preview_snapshot"))
	var award_snapshot: Dictionary = Dictionary(debrief.call("get_debrief_skill_award_contract_snapshot"))
	var award_text: String = String(award_snapshot.get("award_text", ""))
	_assert(String(preview_snapshot.get("gate", "")) == "pass", "TASK_592 preview stays green")
	_assert(String(award_snapshot.get("schema", "")) == "sternenbuergerchen.debrief_skill_award_contract.v1", "Debrief award snapshot reports stable schema")
	_assert(String(award_snapshot.get("task_id", "")) == "TASK_593", "Debrief award snapshot reports task id")
	_assert(String(award_snapshot.get("gate", "")) == "pass", "Debrief award contract gate passes")
	_assert(String(award_snapshot.get("award_authority", "")) == "MissionProgressionResolver", "Debrief reads resolver authority")
	_assert(String(award_snapshot.get("award_source", "")) == "progression_unit_updates", "Debrief reads unit update source")
	_assert(award_text.begins_with("Skill Awards:"), "Debrief separates awards from preview")
	_assert(award_text.contains("XP +"), "Debrief award line includes XP")
	_assert(int(award_snapshot.get("total_xp_delta", 0)) == int(award_summary.get("total_xp_delta", 0)), "Debrief award XP matches summary")
	_assert(int(award_snapshot.get("skill_gain_count", 0)) == int(award_summary.get("skill_gain_count", 0)), "Debrief award skill count matches summary")
	_assert(int(award_snapshot.get("ftl_tactical_gain_count", 0)) == int(award_summary.get("ftl_tactical_gain_count", 0)), "Debrief award FTL count matches summary")
	_assert(String(award_snapshot.get("style_id", "")) == "debrief_skill_award_contract_v1", "Debrief award style id is applied")
	_assert(_check_passed(award_snapshot, "award_authority_resolver"), "Authority check passes")
	_assert(_check_passed(award_snapshot, "award_label_named"), "Named award check passes")
	_assert(_check_passed(award_snapshot, "preview_still_green"), "Preview gate check passes")
	_assert(_check_passed(award_snapshot, "read_only"), "Read-only check passes")
	debrief.queue_free()
	await _wait_frames(2)


func _build_mission_result(leader_id: String, member_id: String, fireteam_id: String) -> Dictionary:
	return {
		"mission_id": "task593_award_contract",
		"mission_outcome": "success",
		"result": "success",
		"winning_team_id": "team_alpha",
		"objective_captured": true,
		"win_condition_type": "objective_capture",
		"duration_seconds": 185.0,
		"selected_unit_ids": PackedStringArray([leader_id, member_id]),
		"selected_fireteam_ids": PackedStringArray([fireteam_id, fireteam_id]),
		"team_states": [
			{"unit_id": leader_id, "display_name": "Lead Alpha", "fireteam_id": fireteam_id, "vital_state": "fit", "health_points": 100},
			{"unit_id": member_id, "display_name": "Rifle Alpha", "fireteam_id": fireteam_id, "vital_state": "fit", "health_points": 88},
		],
		"unit_events": {
			leader_id: {"unit_id": leader_id, "objective_participation": true, "issued_orders": true, "coordinated_plan": true, "contact_report": true, "breakout_decision": true},
			member_id: {"unit_id": member_id, "fired_weapon": true},
		},
	}


func _build_mini_aar_debrief_payload() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.mini_aar_debrief_screen_stub.v1",
		"task_id": "TASK_585",
		"source_schema": "sternenbuergerchen.mini_aar_combat_metrics.v1",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"summary_text": "AAR | FIRE 12 | HIT 7 | FF 1/2 | SUP 3 | WOUND 1 | EXT 2",
		"rows": [
			{"id": "fire", "label": "Fire", "value_text": "FIRE 12 | HIT 7", "read_only": true},
			{"id": "friendly_fire", "label": "Friendly Fire", "value_text": "FF 1 / Risk 2", "read_only": true},
			{"id": "suppress", "label": "Suppress", "value_text": "SUP x3", "read_only": true},
			{"id": "status", "label": "Status", "value_text": "WOUND 1 | DOWN 0 | EXT 2", "read_only": true},
		],
		"chips": [
			{"id": "shots", "label": "FIRE", "value_text": "12", "style_key": "neutral", "read_only": true},
			{"id": "hits", "label": "HIT", "value_text": "7", "style_key": "good", "read_only": true},
			{"id": "ff", "label": "FF", "value_text": "1/2", "style_key": "warn", "read_only": true},
			{"id": "sup", "label": "SUP", "value_text": "3", "style_key": "accent", "read_only": true},
			{"id": "wounded", "label": "WOUND", "value_text": "1", "style_key": "warn", "read_only": true},
			{"id": "extracted", "label": "EXT", "value_text": "2", "style_key": "neutral", "read_only": true},
		],
		"limit_text": "Keine XP, keine Ammo, keine echte Suppression - nur Debrief-Vorschau aus vorhandenen Metriken.",
		"gate": "pass",
	}


func _all_awards_read_only(awards: Array) -> bool:
	if awards.is_empty():
		return false
	for award_variant in awards:
		var award: Dictionary = Dictionary(award_variant)
		if not bool(award.get("read_only", false)):
			return false
	return true


func _check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
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


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame
