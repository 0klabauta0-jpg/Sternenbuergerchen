extends SceneTree

const RULES_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_command_rules.gd")
const COMMANDER_INTENT_SCRIPT: GDScript = preload("res://scripts/command/commander_intent.gd")
const FIRETEAM_EXECUTION_PLAN_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_execution_plan.gd")

const CONTRACT_PATH: String = "res://docs/dev/tactical_command_rules_contract.md"
const CATALOG_PATH: String = "res://data/contextual_help_catalog.json"
const TASK_PATH: String = "res://docs/tasks/TASK_271_tactical_command_modes_roe_fire_rules.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"

const REQUIRED_DOC_SECTIONS: PackedStringArray = [
	"Purpose",
	"Rule Groups",
	"Data Structure",
	"UI Contract",
	"Runtime Contract",
	"Conflict Rules",
	"Feedback Contract",
	"Help IDs",
	"Non Goals",
	"Follow-Up Tasks",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_271 Tactical Command Modes ROE Fire Rules ===")
	_test_contract_doc()
	_test_rule_catalog_and_defaults()
	_test_conflict_normalization()
	_test_intent_and_execution_plan_integration()
	_test_feedback_and_help_catalog()
	_test_no_ui_unit_mutation()
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
	_assert(not text.is_empty(), "Tactical command rules contract exists")
	for section in REQUIRED_DOC_SECTIONS:
		_assert(text.contains("## %s" % section), "Contract has %s section" % section)
	for token in ["cautious", "normal", "rapid", "hold", "return", "free", "suppress", "avoid", "report", "fix", "assault", "withdraw", "none_in_transit"]:
		_assert(text.contains("`%s`" % token), "Contract documents rule value %s" % token)
	_assert(text.contains("not a real ROE simulation"), "Contract rejects real ROE simulation")
	_assert(text.contains("UI may not build `UnitAction`"), "Contract blocks UI UnitAction ownership")


func _test_rule_catalog_and_defaults() -> void:
	var catalog: Dictionary = Dictionary(RULES_SCRIPT.call("get_rule_catalog"))
	_assert(PackedStringArray(catalog.get("tempo", PackedStringArray())).size() == 3, "Rule catalog exposes three tempo values")
	_assert(PackedStringArray(catalog.get("fire_rule", PackedStringArray())).has("suppress"), "Rule catalog exposes suppress fire rule")
	_assert(PackedStringArray(catalog.get("contact_response", PackedStringArray())).has("withdraw"), "Rule catalog exposes withdraw contact response")
	_assert(PackedStringArray(catalog.get("cover_priority", PackedStringArray())).has("high"), "Rule catalog exposes high cover priority")
	_assert(PackedStringArray(catalog.get("security_mode", PackedStringArray())).has("none_in_transit"), "Rule catalog exposes none_in_transit security")
	var rules = RULES_SCRIPT.new()
	_assert(bool(rules.call("is_valid")), "Default tactical command rules validate")
	var defaults: Dictionary = Dictionary(rules.call("to_dict"))
	_assert(String(defaults.get("tempo", "")) == "normal", "Default tempo is normal")
	_assert(String(defaults.get("fire_rule", "")) == "return", "Default fire rule is return")
	_assert(not bool(defaults.get("normalized_from_conflict", true)), "Default rules are not conflict-normalized")


func _test_conflict_normalization() -> void:
	var avoid_free = RULES_SCRIPT.new({
		"tempo": "cautious",
		"fire_rule": "free",
		"contact_response": "avoid",
		"cover_priority": "high",
		"security_mode": "sector",
	})
	var avoid_dict: Dictionary = Dictionary(avoid_free.call("to_dict"))
	_assert(String(avoid_dict.get("fire_rule", "")) == "hold", "Avoid contact plus free fire normalizes to hold fire")
	_assert(bool(avoid_dict.get("normalized_from_conflict", false)), "Avoid/free conflict is visibly normalized")
	_assert(PackedStringArray(avoid_dict.get("warnings", PackedStringArray())).has("conflict:avoid_contact_fire_rule:fire_rule_hold"), "Avoid/free conflict records warning ID")
	var rapid_360 = RULES_SCRIPT.new({
		"tempo": "rapid",
		"fire_rule": "return",
		"contact_response": "report",
		"cover_priority": "normal",
		"security_mode": "360",
	})
	var rapid_dict: Dictionary = Dictionary(rapid_360.call("to_dict"))
	_assert(String(rapid_dict.get("security_mode", "")) == "facing", "Rapid tempo plus 360 security normalizes to facing")
	_assert(PackedStringArray(rapid_dict.get("warnings", PackedStringArray())).has("conflict:rapid_360_security:security_facing"), "Rapid/360 conflict records warning ID")
	var assault_hold = RULES_SCRIPT.new({"fire_rule": "hold", "contact_response": "assault"})
	_assert(String(Dictionary(assault_hold.call("to_dict")).get("contact_response", "")) == "fix", "Assault plus hold fire normalizes to fix")


func _test_intent_and_execution_plan_integration() -> void:
	var rules = RULES_SCRIPT.new({
		"tempo": "cautious",
		"fire_rule": "suppress",
		"contact_response": "fix",
		"cover_priority": "high",
		"security_mode": "sector",
	})
	var payload: Dictionary = Dictionary(rules.call("to_intent_payload", {
		"verb": "take",
		"fireteam_id": "blue",
		"team_id": "team_alpha",
		"target_area_id": "objective_a",
		"phase": 1,
	}))
	var intent = COMMANDER_INTENT_SCRIPT.new(payload)
	_assert(bool(intent.call("is_valid")), "CommanderIntent accepts tactical command rules")
	var intent_dict: Dictionary = Dictionary(intent.call("to_dict"))
	_assert(String(intent_dict.get("tempo", "")) == "cautious", "Intent carries tempo rule")
	_assert(String(intent_dict.get("fire_rule", "")) == "suppress", "Intent carries fire rule")
	_assert(String(intent_dict.get("cover_priority", "")) == "high", "Intent carries cover priority")
	_assert(String(intent_dict.get("security_mode", "")) == "sector", "Intent carries security mode")
	var plan = FIRETEAM_EXECUTION_PLAN_SCRIPT.call("from_intent", intent, {"leadership": 0.72, "discipline": 0.68, "cohesion": 0.66})
	_assert(bool(plan.call("is_valid")), "FireteamExecutionPlan reads rule-bearing intent")
	var snapshot: Dictionary = Dictionary(plan.call("to_snapshot"))
	var tactical_rules: Dictionary = Dictionary(snapshot.get("tactical_rules", {}))
	_assert(String(tactical_rules.get("fire_rule", "")) == "suppress", "Plan snapshot carries fire rule")
	_assert(String(tactical_rules.get("contact_response", "")) == "fix", "Plan snapshot carries contact response")
	_assert(String(snapshot.get("security_mode", "")) == "sector", "Plan maps sector security")
	_assert(float(snapshot.get("cover_priority", 0.0)) > 0.70, "Plan maps high cover priority to numeric value")


func _test_feedback_and_help_catalog() -> void:
	var rules = RULES_SCRIPT.new({"fire_rule": "suppress", "contact_response": "fix", "cover_priority": "high", "security_mode": "sector"})
	var feedback: Dictionary = Dictionary(rules.call("get_feedback_snapshot"))
	_assert(String(feedback.get("selected_fireteam_text", "")).contains("FIRE SUPPRESS"), "#17 feedback summarizes fire rule")
	_assert(String(feedback.get("map_status", "")) == "SUPPRESS", "Map feedback only exposes strong status changes")
	_assert(String(feedback.get("bubble_status", "")) == "suppress ready", "Bubble feedback is compact")
	_assert(not bool(feedback.get("ui_sets_unit_truth", true)), "Rules feedback is not gameplay truth")
	var help_ids: PackedStringArray = PackedStringArray(feedback.get("help_ids", PackedStringArray()))
	_assert(help_ids.size() >= 12, "Rules expose help IDs for command help")
	var catalog_entries: Dictionary = _load_catalog_entries()
	for help_id in help_ids:
		_assert(catalog_entries.has(String(help_id)), "Catalog contains help entry %s" % String(help_id))
		var entry: Dictionary = Dictionary(catalog_entries.get(String(help_id), {}))
		_assert(String(entry.get("status", "")) == "ready", "%s is ready help copy" % String(help_id))
		_assert(not bool(entry.get("manual_review", true)), "%s no longer needs manual review" % String(help_id))


func _test_no_ui_unit_mutation() -> void:
	var text: String = _read_text("res://scripts/tactical/tactical_command_rules.gd")
	_assert(not text.contains("extends Control"), "TacticalCommandRules is not UI code")
	_assert(not text.contains("get_node("), "TacticalCommandRules does not read SceneTree")
	_assert(not text.contains("assign_unit_command"), "TacticalCommandRules does not assign UnitCommand")
	_assert(not text.contains("enqueue_command"), "TacticalCommandRules does not enqueue SimulationRoot commands")


func _test_task_status() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "TASK_271 is marked implemented")
	_assert(not task_text.contains("- [ ]"), "TASK_271 checklist is complete")
	_assert(status_text.contains("### TASK_271 - Tactical Command Modes ROE Fire Rules"), "Implementation status has TASK_271 section")
	_assert(status_text.contains("tactical_command_rules_contract.md"), "Implementation status references rules contract")
	_assert(status_text.contains("tactical_command_rules.gd"), "Implementation status references rules script")


func _load_catalog_entries() -> Dictionary:
	var text: String = _read_text(CATALOG_PATH)
	var parsed = JSON.parse_string(text)
	var result: Dictionary = {}
	if not (parsed is Dictionary):
		return result
	for entry_variant in Array(Dictionary(parsed).get("entries", [])):
		var entry: Dictionary = Dictionary(entry_variant)
		var help_id: String = String(entry.get("help_id", "")).strip_edges()
		if not help_id.is_empty():
			result[help_id] = entry
	return result


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
