extends SceneTree

const COMMANDER_INTENT_SCRIPT: GDScript = preload("res://scripts/command/commander_intent.gd")
const FIRETEAM_EXECUTION_PLAN_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_execution_plan.gd")

const CONTRACT_PATH: String = "res://docs/dev/commander_fireteam_delegation_contract.md"
const TASK_PATH: String = "res://docs/tasks/TASK_270_commander_to_fireteam_leader_delegation_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"

const REQUIRED_DOC_SECTIONS: PackedStringArray = [
	"Purpose",
	"Authority Boundary",
	"CommanderIntent",
	"FireteamExecutionPlan",
	"UnitAction",
	"Existing Command Mapping",
	"FTL Skill Influence",
	"Snapshot and Feedback",
	"Breakout Boundary",
	"Non Goals",
	"Follow-Up Tasks",
]

const LEGACY_COMMANDS: PackedStringArray = [
	"move",
	"defend",
	"take",
	"engage",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_270 Commander to Fireteam Leader Delegation Contract ===")
	_test_contract_doc()
	_test_commander_intent_contract()
	_test_existing_command_mapping()
	_test_fireteam_execution_plan_and_skill()
	_test_unit_action_boundary()
	_test_no_direct_ui_unit_mutation_in_new_contract()
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
	_assert(not text.is_empty(), "Delegation contract doc exists")
	for section in REQUIRED_DOC_SECTIONS:
		_assert(text.contains("## %s" % section), "Contract doc has %s section" % section)
	for token in [
		"CommanderIntent -> FireteamExecutionPlan -> UnitAction -> UnitCommand/SimulationRoot",
		"`command_id`",
		"`plan_id`",
		"`status_response`",
		"`copy`",
		"`cannot`",
		"`adapting`",
		"`complete`",
		"`needs_orders`",
		"UI must not write individual NPC truth",
		"TASK_271",
		"TASK_281",
	]:
		_assert(text.contains(token), "Contract doc documents %s" % token)


func _test_commander_intent_contract() -> void:
	var intent = COMMANDER_INTENT_SCRIPT.new({
		"verb": "move",
		"fireteam_id": "Blue",
		"target_position": Vector2(320.0, 240.0),
		"tempo": "rapid",
		"fire_rule": "return",
		"contact_response": "report",
		"risk": "normal",
		"phase": 1,
	})
	_assert(bool(intent.call("is_valid")), "CommanderIntent validates fireteam-scoped move intent")
	var intent_dict: Dictionary = Dictionary(intent.call("to_dict"))
	_assert(not String(intent_dict.get("command_id", "")).is_empty(), "CommanderIntent carries command_id")
	_assert(String(intent_dict.get("fireteam_id", "")) == "blue", "CommanderIntent normalizes fireteam_id")
	_assert(not intent_dict.has("unit_id"), "CommanderIntent does not serialize direct unit_id")
	var snapshot: Dictionary = Dictionary(intent.call("get_snapshot"))
	_assert(not bool(snapshot.get("ui_sets_unit_truth", true)), "CommanderIntent snapshot marks UI as non-authoritative")
	_assert(String(snapshot.get("gameplay_truth_owner", "")) == "SimulationRoot", "CommanderIntent points to SimulationRoot authority")

	var bad_intent = COMMANDER_INTENT_SCRIPT.new({
		"verb": "move",
		"unit_id": "unit_alpha",
		"target_position": Vector2(64.0, 64.0),
	})
	_assert(not bool(bad_intent.call("is_valid")), "Direct unit-only intent is rejected")


func _test_existing_command_mapping() -> void:
	for command_type in LEGACY_COMMANDS:
		var intent = COMMANDER_INTENT_SCRIPT.call("from_legacy_command_dict", {
			"type": command_type,
			"team_id": "blue",
			"unit_id": "unit_alpha",
			"priority": 7,
			"target_position": Vector2(400.0, 300.0),
			"phase": 2,
		})
		_assert(bool(intent.call("is_valid")), "%s legacy command maps to a valid CommanderIntent" % command_type)
		var intent_dict: Dictionary = Dictionary(intent.call("to_dict"))
		_assert(String(intent_dict.get("verb", "")) == command_type, "%s legacy command keeps game verb" % command_type)
		_assert(not intent_dict.has("unit_id"), "%s legacy unit_id is not serialized by intent" % command_type)
		var legacy_dict: Dictionary = Dictionary(intent.call("to_legacy_command_dict"))
		_assert(String(legacy_dict.get("type", "")) == command_type, "%s intent can roundtrip to legacy command type" % command_type)
		_assert(String(legacy_dict.get("intent_command_id", "")).begins_with("intent_"), "%s legacy roundtrip keeps intent_command_id" % command_type)


func _test_fireteam_execution_plan_and_skill() -> void:
	var low_skill_intent = COMMANDER_INTENT_SCRIPT.new({
		"verb": "take",
		"fireteam_id": "blue",
		"team_id": "team_alpha",
		"target_area_id": "objective_a",
		"tempo": "normal",
		"fire_rule": "free",
		"contact_response": "fix",
		"risk": "high",
		"phase": 0,
	})
	var low_plan = FIRETEAM_EXECUTION_PLAN_SCRIPT.call("from_intent", low_skill_intent, {
		"leadership": 0.2,
		"discipline": 0.25,
		"cohesion": 0.3,
		"communication": 0.2,
		"initiative": 0.25,
	})
	var high_plan = FIRETEAM_EXECUTION_PLAN_SCRIPT.call("from_intent", low_skill_intent, {
		"leadership": 0.9,
		"discipline": 0.85,
		"cohesion": 0.82,
		"communication": 0.88,
		"initiative": 0.84,
	})
	_assert(bool(low_plan.call("is_valid")), "Low-skill FireteamExecutionPlan validates")
	_assert(bool(high_plan.call("is_valid")), "High-skill FireteamExecutionPlan validates")
	var low_snapshot: Dictionary = Dictionary(low_plan.call("to_snapshot"))
	var high_snapshot: Dictionary = Dictionary(high_plan.call("to_snapshot"))
	_assert(String(low_snapshot.get("movement_style", "")) == "bounding", "Take intent maps to bounding plan")
	_assert(String(low_snapshot.get("security_mode", "")) == "sector", "Take intent maps to sector security")
	_assert(PackedStringArray(low_snapshot.get("allowed_breakout_classes", PackedStringArray())).has("abort_to_safe"), "High-risk plan allows abort_to_safe breakout")
	_assert(float(high_snapshot.get("planning_quality", 0.0)) > float(low_snapshot.get("planning_quality", 1.0)), "FTL skill improves planning quality")
	_assert(float(high_snapshot.get("reaction_delay_seconds", 1.0)) < float(low_snapshot.get("reaction_delay_seconds", 0.0)), "FTL skill lowers reaction delay")
	_assert(String(high_snapshot.get("communication_state", "")) == "clear", "High communication skill yields clear communication state")
	_assert(not bool(high_snapshot.get("ui_sets_unit_truth", true)), "Plan snapshot is not UI truth")


func _test_unit_action_boundary() -> void:
	var intent = COMMANDER_INTENT_SCRIPT.new({
		"verb": "engage",
		"fireteam_id": "gold",
		"team_id": "team_alpha",
		"target_position": Vector2(512.0, 256.0),
		"phase": 3,
	})
	var plan = FIRETEAM_EXECUTION_PLAN_SCRIPT.call("from_intent", intent, {"leadership": 0.7, "discipline": 0.8, "cohesion": 0.6})
	var actions: Array = Array(plan.call("build_unit_actions", PackedStringArray(["unit_alpha", "unit_bravo"])))
	_assert(actions.size() == 2, "Plan builds one UnitAction per requested unit")
	for action_variant in actions:
		var action: Dictionary = Dictionary(action_variant)
		_assert(FIRETEAM_EXECUTION_PLAN_SCRIPT.call("validate_unit_action", action), "UnitAction validates")
		_assert(String(action.get("plan_id", "")) == String(plan.get("plan_id")), "UnitAction carries plan_id")
		_assert(String(action.get("command_id", "")) == String(plan.get("command_id")), "UnitAction carries command_id")
		_assert(String(action.get("ui_control_path", "")) == "", "UnitAction has no UI control path")
		var runtime_command: Dictionary = Dictionary(plan.call("unit_action_to_runtime_command", action))
		_assert(not runtime_command.is_empty(), "UnitAction converts to valid runtime command dictionary")
		_assert(String(runtime_command.get("command_token", "")).begins_with(String(plan.get("plan_id"))), "Runtime command token remains plan-scoped")


func _test_no_direct_ui_unit_mutation_in_new_contract() -> void:
	for path in [
		"res://scripts/command/commander_intent.gd",
		"res://scripts/tactical/fireteam_execution_plan.gd",
	]:
		var text: String = _read_text(path)
		_assert(not text.contains("extends Control"), "%s is not UI code" % path)
		_assert(not text.contains("get_node("), "%s does not resolve scene nodes" % path)
		_assert(not text.contains("assign_unit_command"), "%s does not assign unit commands directly" % path)
		_assert(not text.contains("enqueue_command"), "%s does not enqueue SimulationRoot commands" % path)


func _test_task_status() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "TASK_270 is marked implemented")
	_assert(not task_text.contains("- [ ]"), "TASK_270 checklist is complete")
	_assert(status_text.contains("### TASK_270 - Commander to Fireteam Leader Delegation Contract"), "Implementation status has TASK_270 section")
	_assert(status_text.contains("commander_fireteam_delegation_contract.md"), "Implementation status references delegation contract")
	_assert(status_text.contains("commander_intent.gd"), "Implementation status references CommanderIntent")
	_assert(status_text.contains("fireteam_execution_plan.gd"), "Implementation status references FireteamExecutionPlan")


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
