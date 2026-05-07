extends SceneTree

const COMMANDER_INTENT_SCRIPT: GDScript = preload("res://scripts/command/commander_intent.gd")
const FIRETEAM_EXECUTION_PLAN_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_execution_plan.gd")
const TACTICAL_BREAKOUT_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_breakout_resolver.gd")
const TACTICAL_COMMUNICATION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_communication_resolver.gd")
const MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_snapshot_contract.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_282_tactical_overhaul_playability_performance_help_gate.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/tactical_overhaul_playability_performance_help_gate.md"
const MANUAL_CHECKLIST_PATH: String = "res://docs/manual_checks/tactical_overhaul_manual_playability_checklist.md"
const HELP_CATALOG_PATH: String = "res://data/contextual_help_catalog.json"
const PERFORMANCE_BUDGET_PATH: String = "res://data/performance_budget_contract.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_282 Tactical Overhaul Playability Performance Help Gate ===")
	_test_prerequisite_chain_and_artifacts()
	_test_tactical_end_to_end_contract_payload()
	_test_help_ui_meta_multiplayer_and_performance_gate()
	_test_report_manual_and_status()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_prerequisite_chain_and_artifacts() -> void:
	var required_tasks: Array = [268, 269, 270, 271, 272, 273, 274, 275, 276, 277, 278, 279, 280, 281]
	for task_number in required_tasks:
		var task_path: String = _find_task_path(task_number)
		var task_text: String = _read_text(task_path)
		_assert(not task_text.is_empty(), "Prerequisite TASK_%03d file exists" % int(task_number))
		_assert(task_text.contains("## Status: IMPLEMENTIERT"), "Prerequisite TASK_%03d is implemented" % int(task_number))
	var required_scripts: Array = [
		"res://scripts/tests/task_279_lz_security_air_asset_tactical_playability_smoke.gd",
		"res://scripts/tests/task_280_tactical_profile_editor_scenario_authoring.gd",
		"res://scripts/tests/task_281_tactical_command_multiplayer_authority_snapshot.gd",
		"res://scripts/tests/task_268_post_help_popup_playability_regression_smoke.gd",
		"res://scripts/tests/task_222_performance_regression_gate_and_manual_profile_checklist.gd",
		"res://scripts/tests/task_249_post_audio_visual_performance_optimization_pass.gd",
	]
	for script_path in required_scripts:
		_assert(FileAccess.file_exists(script_path), "Gate references existing verifier %s" % script_path.get_file())
	for doc_path in [
		"res://docs/reports/lz_security_air_asset_playability_smoke.md",
		"res://docs/dev/tactical_multiplayer_authority_snapshot.md",
		"res://docs/reports/post_help_popup_playability_regression_report.md",
		"res://docs/performance/performance_regression_gate.md",
		"res://docs/performance/audio_visual_performance_report.md",
	]:
		_assert(FileAccess.file_exists(doc_path), "Gate references existing report/doc %s" % doc_path.get_file())


func _test_tactical_end_to_end_contract_payload() -> void:
	var blue_intent = COMMANDER_INTENT_SCRIPT.call("from_dict", {
		"command_id": "intent_blue_take_lz",
		"verb": "take",
		"team_id": "team_alpha",
		"fireteam_id": "blue",
		"target_position": Vector2(320.0, 240.0),
		"tempo": "rapid",
		"fire_rule": "return",
		"contact_response": "report",
		"risk": "normal",
		"security_mode": "sector",
		"sync_group_id": "lz_take_1",
	})
	var gold_intent = COMMANDER_INTENT_SCRIPT.call("from_dict", {
		"command_id": "intent_gold_secure_lz",
		"verb": "secure",
		"team_id": "team_alpha",
		"fireteam_id": "gold",
		"target_position": Vector2(360.0, 240.0),
		"tempo": "normal",
		"fire_rule": "return",
		"contact_response": "fix",
		"risk": "low",
		"security_mode": "360",
		"sync_group_id": "lz_take_1",
	})
	var blue_plan = FIRETEAM_EXECUTION_PLAN_SCRIPT.call("from_intent", blue_intent, {
		"leadership": 0.76,
		"discipline": 0.66,
		"cohesion": 0.72,
		"communication": 0.8,
	}, {"coordination_plan_id": "coord_lz_take", "coordination_role": "assault"})
	var gold_plan = FIRETEAM_EXECUTION_PLAN_SCRIPT.call("from_intent", gold_intent, {
		"leadership": 0.82,
		"discipline": 0.7,
		"cohesion": 0.78,
		"communication": 0.84,
	}, {"coordination_plan_id": "coord_lz_take", "coordination_role": "security"})
	var blue_plan_snapshot: Dictionary = Dictionary(blue_plan.call("to_snapshot"))
	var gold_plan_snapshot: Dictionary = Dictionary(gold_plan.call("to_snapshot"))
	var role_event: Dictionary = Dictionary(TACTICAL_COMMUNICATION_RESOLVER_SCRIPT.call("build_event", "plan_role_assigned", {
		"event_id": "task282_role_blue",
		"fireteam_id": "blue",
		"team_id": "team_alpha",
		"plan_id": String(blue_plan_snapshot.get("plan_id", "")),
		"phase": 1,
		"anchor_position": Vector2(320.0, 240.0),
	}, {"sequence": 1}))
	var breakout: Dictionary = Dictionary(TACTICAL_BREAKOUT_RESOLVER_SCRIPT.call("evaluate_breakout", gold_plan_snapshot, {
		"trigger": "air_asset_threatened",
		"fireteam_id": "gold",
		"phase": 1,
		"sequence": "task282_air_warn",
		"anchor_position": Vector2(360.0, 240.0),
		"cause_label": "Enemy AT near unsecured LZ",
	}, {}))
	var threat_event: Dictionary = Dictionary(TACTICAL_BREAKOUT_RESOLVER_SCRIPT.call("build_communication_event", breakout, {"sequence": 2}))
	var contract = MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT.new()
	var snapshot: Dictionary = Dictionary(contract.call("build_state_snapshot", {
		"tick": 282,
		"commander_intents": [blue_intent.call("get_snapshot"), gold_intent.call("get_snapshot")],
		"fireteam_plan_status": [blue_plan_snapshot, gold_plan_snapshot],
		"communication_events": [role_event, threat_event, threat_event],
		"tactical_rules": {
			"blue": Dictionary(blue_plan_snapshot.get("tactical_rules", {})),
			"gold": Dictionary(gold_plan_snapshot.get("tactical_rules", {})),
		},
		"breakout_states": [breakout, breakout],
		"air_asset_status": [
			{
				"asset_id": "mission_dropship",
				"asset_type": "dropship",
				"state": "threatened",
				"integrity": 100,
				"max_integrity": 100,
				"risk": 0.74,
				"lz_secure_level": 0.35,
				"enemy_at_pressure": 0.85,
				"last_event_id": "task282_air_warn",
				"warning_visible": true,
			},
		],
	}))
	_assert(Array(snapshot.get("commander_intents", [])).size() == 2, "E2E gate carries two Commander intents")
	_assert(Array(snapshot.get("fireteam_plan_status", [])).size() == 2, "E2E gate carries two Fireteam plan statuses")
	_assert(Array(snapshot.get("communication_events", [])).size() == 2, "E2E gate deduplicates tactical communication events")
	_assert(Array(snapshot.get("breakout_states", [])).size() == 1, "E2E gate carries one deduplicated AirAsset breakout")
	_assert(Array(snapshot.get("air_asset_status", [])).size() == 1, "E2E gate carries one AirAssetStatus")
	for intent_variant in Array(snapshot.get("commander_intents", [])):
		var intent_snapshot: Dictionary = Dictionary(intent_variant)
		_assert(not intent_snapshot.has("unit_id"), "Commander controls FTL intent, not direct unit payload")
	for plan_variant in Array(snapshot.get("fireteam_plan_status", [])):
		var plan_snapshot: Dictionary = Dictionary(plan_variant)
		_assert(String(plan_snapshot.get("runtime_authority", "")) == "SimulationRoot", "Plan status stays SimulationRoot-authoritative")
		_assert(not plan_snapshot.has("ftl_skill_factors"), "Plan status exposes public skill effect, not raw skill data")
	var budget: Dictionary = _load_json(PERFORMANCE_BUDGET_PATH)
	var snapshot_budget: Dictionary = Dictionary(Dictionary(budget.get("project_budget", {})).get("snapshot", {}))
	var metrics: Dictionary = Dictionary(contract.call("build_serialization_metrics", snapshot))
	_assert(int(metrics.get("json_bytes", 9999999)) < int(snapshot_budget.get("max_large_json_p99_bytes", 1)), "Tactical E2E snapshot stays below snapshot byte budget")
	_assert(Array(metrics.get("large_payload_offenders", [])).is_empty(), "Tactical E2E snapshot stays ID-only")


func _test_help_ui_meta_multiplayer_and_performance_gate() -> void:
	var help_text: String = _read_text(HELP_CATALOG_PATH)
	for help_id in [
		"mission.command_matrix",
		"mission.command.group.rule",
		"mission.command.group.plan",
		"mission.command.group.air_lz",
		"mission.command.group.breakout",
		"mission.command.roe_fire_rules",
		"mission.rule.tempo",
		"mission.rule.fire_rule",
		"mission.rule.contact_response",
		"mission.rule.security_mode",
		"map_editor.tactical_profile",
		"character_sheet.ftl_tactical_impact",
	]:
		_assert(help_text.contains("\"%s\"" % help_id), "Help catalog covers %s" % help_id)
	var lz_report: String = _read_text("res://docs/reports/lz_security_air_asset_playability_smoke.md")
	for token in ["success path", "threat path", "loss path", "MetaLayerFlow", "air_asset_explosion", "softlock_guard"]:
		_assert(lz_report.contains(token), "LZ/AirAsset report covers %s" % token)
	var multiplayer_doc: String = _read_text("res://docs/dev/tactical_multiplayer_authority_snapshot.md")
	for token in ["commander_intents", "breakout_states", "air_asset_status", "host_required", "ui_sets_gameplay_truth = false"]:
		_assert(multiplayer_doc.contains(token), "Multiplayer authority doc covers %s" % token)
	var perf_report: String = _read_text("res://docs/performance/performance_regression_gate.md")
	var audio_visual_report: String = _read_text("res://docs/performance/audio_visual_performance_report.md")
	_assert(perf_report.contains("snapshot") and perf_report.contains("side-effect-freies Apply"), "Performance gate covers snapshot side-effect safety")
	_assert(audio_visual_report.contains("Audio polyphony") and audio_visual_report.contains("VFX") and audio_visual_report.contains("Budgets unchanged"), "Audio/visual performance gate covers spam and VFX")


func _test_report_manual_and_status() -> void:
	var report: String = _read_text(REPORT_PATH)
	var manual: String = _read_text(MANUAL_CHECKLIST_PATH)
	for token in ["Automated", "Manual", "Balance", "Air-Asset", "Multiplayer", "Performance", "Help"]:
		_assert(report.contains(token), "TASK_282 report documents %s" % token)
	for token in ["Full-HD", "LZ", "Air-Asset", "Breakout", "Communication", "FOB", "Homebase", "Performance"]:
		_assert(manual.contains(token), "TASK_282 manual checklist covers %s" % token)
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "Task file marks TASK_282 implemented")
	_assert(not task_text.contains("- [ ]"), "Task checklist is complete")
	_assert(status_text.contains("### TASK_282 - Tactical Overhaul Playability Performance Help Gate") and status_text.contains("- Status: implementiert"), "Implementation status marks TASK_282 implemented")
	_assert(roadmap_text.contains("TASK_282 - Tactical Overhaul Playability Performance Help Gate (implementiert)"), "Roadmap marks TASK_282 implemented")


func _find_task_path(task_number: int) -> String:
	var prefix: String = "TASK_%03d_" % task_number
	var directory := DirAccess.open("res://docs/tasks")
	if directory == null:
		return ""
	directory.list_dir_begin()
	var file_name: String = directory.get_next()
	while not file_name.is_empty():
		if not directory.current_is_dir() and file_name.begins_with(prefix) and file_name.ends_with(".md"):
			directory.list_dir_end()
			return "res://docs/tasks/%s" % file_name
		file_name = directory.get_next()
	directory.list_dir_end()
	return ""


func _load_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	if text.is_empty():
		return {}
	var parsed = JSON.parse_string(text)
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _read_text(path: String) -> String:
	if path.is_empty() or not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
