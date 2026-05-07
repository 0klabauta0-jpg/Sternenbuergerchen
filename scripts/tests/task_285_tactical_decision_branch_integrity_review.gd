extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_285_tactical_decision_branch_integrity_review.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reviews/tactical_decision_branch_integrity_review.md"
const MATRIX_PATH: String = "res://docs/dev/tactical_decision_priority_matrix.md"

const COMMANDER_INTENT_SCRIPT: GDScript = preload("res://scripts/command/commander_intent.gd")
const TACTICAL_RULES_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_command_rules.gd")
const EXECUTION_PLAN_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_execution_plan.gd")
const MULTI_PLAN_SCRIPT: GDScript = preload("res://scripts/tactical/multi_fireteam_plan_resolver.gd")
const BREAKOUT_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_breakout_resolver.gd")
const AIR_ASSET_STATUS_SCRIPT: GDScript = preload("res://scripts/mission/air_asset_status.gd")
const AIR_ASSET_THREAT_RESOLVER_SCRIPT: GDScript = preload("res://scripts/combat/air_asset_threat_resolver.gd")
const ENEMY_TACTICS_PROFILE_SCRIPT: GDScript = preload("res://scripts/tactical/enemy_team_tactics_profile.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_285 Tactical Decision Branch Integrity Review ===")
	_test_docs_report_and_status()
	_test_commander_intent_aliases_and_reported_smells()
	_test_tactical_rules_conflict_matrix()
	_test_execution_plan_branch_matrix()
	_test_multi_fireteam_role_and_status_priority()
	_test_breakout_trigger_and_allowed_class_priority()
	_test_air_asset_threat_gate_and_state_priority()
	_test_enemy_profile_unknowns_emit_diagnostics()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_docs_report_and_status() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var matrix_text: String = _read_text(MATRIX_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "Task file marks TASK_285 implemented")
	_assert(not task_text.contains("- [ ]"), "Task checklist is complete")
	_assert(status_text.contains("### TASK_285 - Tactical Decision Branch Integrity Review") and status_text.contains("- Status: implementiert"), "Implementation status marks TASK_285 implemented")
	_assert(roadmap_text.contains("TASK_285 - Tactical Decision Branch Integrity Review (implementiert)"), "Roadmap marks TASK_285 implemented")
	for token in ["## Findings", "Blocker", "Important", "Cleanup", "branch", "duplicate", "diagnostics", "unreachable"]:
		_assert(report_text.to_lower().contains(token.to_lower()), "Review report contains %s" % token)
	for token in ["CommanderIntent", "TacticalRules", "FireteamExecutionPlan", "MultiFireteamPlan", "Breakout Priority", "TacticalCommunicationEvent", "Enemy Profile", "AirAssetThreat", "Conflict Priority Summary", "Regression Fixtures"]:
		_assert(matrix_text.contains(token), "Decision matrix contains %s" % token)


func _test_commander_intent_aliases_and_reported_smells() -> void:
	var legacy = COMMANDER_INTENT_SCRIPT.call("from_legacy_command_dict", {
		"command_id": "legacy_attack",
		"command_type": "attack_area",
		"unit_id": "blue_ignored",
		"team_id": "team_alpha",
		"target_position": Vector2(80.0, 96.0),
	})
	var snapshot: Dictionary = Dictionary(legacy.call("get_snapshot"))
	_assert(String(snapshot.get("verb", "")) == "engage", "Legacy attack_area normalizes to CommanderIntent engage")
	var legacy_metadata: Dictionary = Dictionary(snapshot.get("metadata", {}))
	_assert(String(legacy_metadata.get("legacy_unit_id_ignored", "")) == "blue_ignored", "Legacy unit_id is explicitly preserved only as ignored metadata")

	var unknown = COMMANDER_INTENT_SCRIPT.call("from_dict", {
		"command_id": "unknown_intent",
		"verb": "teleport",
		"fireteam_id": "blue",
		"team_id": "team_alpha",
		"target_position": Vector2(80.0, 96.0),
	})
	var unknown_snapshot: Dictionary = Dictionary(unknown.call("get_snapshot"))
	_assert(String(unknown_snapshot.get("verb", "")) == "move", "Unknown CommanderIntent verb falls back to safe move")
	var report_text: String = _read_text(REPORT_PATH)
	_assert(report_text.contains("normalization_warnings") and report_text.contains("cover_priority") and report_text.contains("security_mode") and report_text.contains("unreachable"), "Report records CommanderIntent diagnostic and default-field branch smells")


func _test_tactical_rules_conflict_matrix() -> void:
	var avoid_free: Dictionary = _rules_dict({"contact_response": "avoid", "fire_rule": "free"})
	_assert(String(avoid_free.get("fire_rule", "")) == "hold", "Avoid contact wins over free fire")
	_assert(_has_warning(avoid_free, "conflict:avoid_contact_fire_rule:fire_rule_hold"), "Avoid/free conflict emits warning")

	var withdraw_suppress: Dictionary = _rules_dict({"contact_response": "withdraw", "fire_rule": "suppress"})
	_assert(String(withdraw_suppress.get("fire_rule", "")) == "return", "Withdraw wins by downgrading suppress to return")
	_assert(_has_warning(withdraw_suppress, "conflict:withdraw_suppress:fire_rule_return"), "Withdraw/suppress conflict emits warning")

	var rapid_360: Dictionary = _rules_dict({"tempo": "rapid", "security_mode": "360"})
	_assert(String(rapid_360.get("security_mode", "")) == "facing", "Rapid tempo wins over 360 security")
	_assert(_has_warning(rapid_360, "conflict:rapid_360_security:security_facing"), "Rapid/360 conflict emits warning")

	var assault_hold: Dictionary = _rules_dict({"contact_response": "assault", "fire_rule": "hold"})
	_assert(String(assault_hold.get("contact_response", "")) == "fix", "Assault with hold fire downgrades contact response to fix")
	_assert(_has_warning(assault_hold, "conflict:assault_hold_fire:contact_fix"), "Assault/hold conflict emits warning")


func _test_execution_plan_branch_matrix() -> void:
	var default_take_plan = EXECUTION_PLAN_SCRIPT.call("from_intent", _intent("take", {"cover_priority": "high"}), _skill(0.84), {})
	_assert(String(default_take_plan.get("security_mode")) == "facing", "Current CommanderIntent default security overrides take fallback; report marks this branch smell")
	var take_plan = EXECUTION_PLAN_SCRIPT.call("from_intent", _intent("take", {"cover_priority": "high", "security_mode": "sector"}), _skill(0.84), {})
	_assert(String(take_plan.get("movement_style")) == "bounding", "Take intent maps to bounding movement")
	_assert(String(take_plan.get("security_mode")) == "sector", "Explicit sector security reaches execution plan")
	_assert(float(take_plan.get("cover_priority")) > 0.70, "Explicit high cover priority wins in execution plan")
	var take_action: Dictionary = Dictionary(take_plan.call("build_unit_action", "blue_1"))
	_assert(String(take_action.get("action_type", "")) == "engage_area", "Take plan builds engage-area UnitAction")
	_assert(not Dictionary(take_plan.call("unit_action_to_runtime_command", take_action)).is_empty(), "UnitAction converts to runtime command through existing contract")

	var cautious_move = EXECUTION_PLAN_SCRIPT.call("from_intent", _intent("move", {"tempo": "cautious", "cover_priority": ""}), _skill(0.55), {})
	_assert(String(cautious_move.get("movement_style")) == "caterpillar", "Cautious move maps to caterpillar")
	var hold_plan = EXECUTION_PLAN_SCRIPT.call("from_intent", _intent("hold", {"target_position": null, "target_area_id": "", "security_mode": "360"}), _skill(0.55), {})
	_assert(String(hold_plan.get("movement_style")) == "hold", "Hold intent maps to hold movement")
	_assert(String(hold_plan.get("security_mode")) == "all_round", "Explicit 360 hold intent maps to all-round security")


func _test_multi_fireteam_role_and_status_priority() -> void:
	var plan: Dictionary = Dictionary(MULTI_PLAN_SCRIPT.call("resolve_area_plan", _intent("take", {"coordinated_fireteam_ids": PackedStringArray(["blue", "gold", "med"])}), _multi_contexts(), {
		"plan_id": "task285_multi",
		"phase": 1,
		"min_spacing": 96.0,
		"area_context": {"center_position": Vector2(512.0, 512.0)},
	}))
	_assert(bool(MULTI_PLAN_SCRIPT.call("is_valid_plan", plan)), "Multi-fireteam plan validates")
	var assignments: Array = Array(plan.get("role_assignments", []))
	_assert(_role_for(assignments, "blue") == "lead", "Lead role goes to strongest assault context")
	_assert(_role_for(assignments, "gold") == "support", "Support role goes to ranged/disciplined context")
	_assert(_role_for(assignments, "med") == "reserve", "Medic-heavy context becomes reserve")

	var pressured_contexts: Array = _multi_contexts()
	Dictionary(pressured_contexts[0])["blocked_path"] = true
	Dictionary(pressured_contexts[1])["contact_pressure"] = 0.9
	var pressured_plan: Dictionary = Dictionary(MULTI_PLAN_SCRIPT.call("resolve_area_plan", _intent("take", {"coordinated_fireteam_ids": PackedStringArray(["blue", "gold", "med"])}), pressured_contexts, {
		"plan_id": "task285_pressure",
		"phase": 1,
		"min_spacing": 96.0,
		"area_context": {"center_position": Vector2(512.0, 512.0)},
	}))
	_assert(String(pressured_plan.get("status", "")) == "blocked_path", "Blocked path wins over contact for multi-plan status")
	_assert(PackedStringArray(pressured_plan.get("warnings", PackedStringArray())).has("blocked_path:blue"), "Blocked warning names fireteam")
	_assert(PackedStringArray(pressured_plan.get("warnings", PackedStringArray())).has("contact_stable:gold"), "Contact warning names fireteam")


func _test_breakout_trigger_and_allowed_class_priority() -> void:
	var plan: Dictionary = _base_breakout_plan()
	var mixed: Dictionary = Dictionary(BREAKOUT_RESOLVER_SCRIPT.call("evaluate_breakout", plan, {
		"contact": true,
		"blocked_path": true,
		"air_asset_destroyed": true,
		"fireteam_id": "blue",
		"sequence": "mixed",
	}))
	_assert(String(mixed.get("trigger", "")) == "air_asset_destroyed", "Air asset destroyed wins over blocked/contact breakout triggers")
	_assert(String(mixed.get("breakout_class", "")) == "abort_to_safe", "Air asset destroyed prefers abort_to_safe when allowed")

	var limited_plan: Dictionary = _base_breakout_plan()
	limited_plan["allowed_breakout_classes"] = PackedStringArray(["hold_and_report", "request_orders"])
	var limited_air: Dictionary = Dictionary(BREAKOUT_RESOLVER_SCRIPT.call("evaluate_breakout", limited_plan, {
		"trigger": "air_asset_destroyed",
		"fireteam_id": "blue",
		"sequence": "limited_air",
	}))
	_assert(String(limited_air.get("breakout_class", "")) == "request_orders", "Disallowed abort downgrades to request_orders")
	var blocked_high: Dictionary = Dictionary(BREAKOUT_RESOLVER_SCRIPT.call("evaluate_breakout", plan, {
		"trigger": "blocked_route",
		"fireteam_id": "blue",
		"breakout_judgement": 0.86,
		"sequence": "blocked_high",
	}))
	_assert(String(blocked_high.get("breakout_class", "")) == "auto_adapt", "High FTL blocked route auto-adapts")
	var contact_low: Dictionary = Dictionary(BREAKOUT_RESOLVER_SCRIPT.call("evaluate_breakout", plan, {
		"trigger": "contact",
		"fireteam_id": "blue",
		"breakout_judgement": 0.2,
		"sequence": "contact_low",
	}))
	_assert(String(contact_low.get("breakout_class", "")) == "request_orders", "Low FTL contact asks for orders")
	_assert(Dictionary(BREAKOUT_RESOLVER_SCRIPT.call("evaluate_breakout", plan, {"trigger": "unknown", "fireteam_id": "blue"})).is_empty(), "Unknown breakout trigger does not fabricate a state")


func _test_air_asset_threat_gate_and_state_priority() -> void:
	var resolver = AIR_ASSET_THREAT_RESOLVER_SCRIPT.new()
	var rifle: Dictionary = Dictionary(resolver.call("evaluate_threat", {}, {"weapon_id": "rifle", "range_tiles": 1.0}))
	_assert(not bool(rifle.get("eligible", true)) and String(rifle.get("blocked_reason", "")) == "weapon_not_anti_armor", "Non anti-armor threat is blocked with reason")
	var out_of_range: Dictionary = Dictionary(resolver.call("evaluate_threat", {}, {"weapon_id": "rocket_launcher", "range_tiles": 999.0}))
	_assert(not bool(out_of_range.get("eligible", true)) and String(out_of_range.get("blocked_reason", "")) == "out_of_range", "Out-of-range air threat is blocked with reason")
	var first_lock: Dictionary = Dictionary(resolver.call("evaluate_threat", {}, {
		"weapon_id": "rocket_launcher",
		"range_tiles": 1.0,
		"has_line_of_sight": true,
		"visible_in_fow": true,
		"altitude_layer": "low",
		"enemy_at_pressure": 0.9,
		"damage": 55,
		"sequence": "first",
	}))
	_assert(bool(first_lock.get("eligible", false)) and bool(first_lock.get("warning_required", false)), "First eligible air threat warns before damage")
	_assert(not bool(first_lock.get("hit_allowed", true)), "First air threat does not hit before warning")
	var second_hit: Dictionary = Dictionary(resolver.call("evaluate_threat", first_lock.get("next_status", {}), {
		"weapon_id": "rocket_launcher",
		"range_tiles": 1.0,
		"has_line_of_sight": true,
		"visible_in_fow": true,
		"altitude_layer": "low",
		"warning_seen": true,
		"damage": 999,
		"allow_destroy": true,
		"sequence": "second",
	}))
	_assert(bool(second_hit.get("destroy_allowed", false)), "Warned air threat may destroy when damage is terminal")
	_assert(String(second_hit.get("tactical_breakout_trigger", "")) == "air_asset_destroyed", "Terminal air threat emits air_asset_destroyed breakout trigger")
	var terminal: Dictionary = Dictionary(resolver.call("evaluate_threat", AIR_ASSET_STATUS_SCRIPT.call("from_dict", {"state": "crashed"}), {"weapon_id": "rocket_launcher", "range_tiles": 1.0}))
	_assert(not bool(terminal.get("eligible", true)) and String(terminal.get("blocked_reason", "")) == "air_asset_terminal_state", "Terminal air asset cannot be damaged again")


func _test_enemy_profile_unknowns_emit_diagnostics() -> void:
	var config: Dictionary = Dictionary(ENEMY_TACTICS_PROFILE_SCRIPT.call("normalize_config", {
		"profile_id": "missing_profile",
		"security_mode": "sideways",
		"facing": "up",
		"heavy_weapon_role": "anti_armor",
		"weapon_id": "rifle",
	}, Vector2i(32, 32)))
	var diagnostics: PackedStringArray = PackedStringArray(config.get("diagnostics", PackedStringArray()))
	_assert(diagnostics.has("unknown_profile_id:missing_profile"), "Unknown enemy profile emits diagnostic")
	_assert(diagnostics.has("unknown_security_mode:sideways"), "Unknown security mode emits diagnostic")
	_assert(diagnostics.has("unknown_facing:up"), "Unknown facing emits diagnostic")
	_assert(diagnostics.has("weapon_not_anti_armor:rifle"), "Anti-armor mismatch emits diagnostic")


func _rules_dict(data: Dictionary) -> Dictionary:
	var rules = TACTICAL_RULES_SCRIPT.call("from_dict", data)
	return Dictionary(rules.call("to_dict"))


func _intent(verb: String, overrides: Dictionary = {}):
	var data: Dictionary = {
		"command_id": "task285_%s" % verb,
		"verb": verb,
		"fireteam_id": "blue",
		"team_id": "team_alpha",
		"target_position": Vector2(512.0, 512.0),
		"target_area_id": "objective_a",
		"tempo": "normal",
		"risk": "normal",
	}
	for key in overrides.keys():
		data[key] = overrides[key]
	return COMMANDER_INTENT_SCRIPT.call("from_dict", data)


func _skill(value: float) -> Dictionary:
	return {
		"leadership": value,
		"discipline": value,
		"cohesion": value,
		"communication": value,
		"initiative": value,
		"breakout_judgement": value,
	}


func _multi_contexts() -> Array:
	return [
		{
			"fireteam_id": "blue",
			"display_label": "BLUE",
			"position": Vector2(240.0, 460.0),
			"leadership": 0.93,
			"discipline": 0.72,
			"cohesion": 0.82,
			"speed": 0.86,
			"readiness": 1.0,
			"weapon_range": 0.55,
			"accuracy": 0.62,
			"medic_count": 0,
		},
		{
			"fireteam_id": "gold",
			"display_label": "GOLD",
			"position": Vector2(120.0, 520.0),
			"leadership": 0.62,
			"discipline": 0.91,
			"cohesion": 0.72,
			"speed": 0.48,
			"readiness": 1.0,
			"weapon_range": 0.95,
			"accuracy": 0.90,
			"medic_count": 0,
			"cover_quality": 0.86,
		},
		{
			"fireteam_id": "med",
			"display_label": "MED",
			"position": Vector2(160.0, 600.0),
			"leadership": 0.50,
			"discipline": 0.60,
			"cohesion": 0.80,
			"speed": 0.54,
			"readiness": 1.0,
			"weapon_range": 0.45,
			"accuracy": 0.50,
			"communication": 0.82,
			"medic_count": 2,
		},
	]


func _base_breakout_plan() -> Dictionary:
	return {
		"plan_id": "task285_breakout",
		"command_id": "task285_command",
		"fireteam_id": "blue",
		"phase": 1,
		"target_position": Vector2(512.0, 512.0),
		"allowed_breakout_classes": PackedStringArray(["auto_adapt", "hold_and_report", "request_orders", "abort_to_safe"]),
		"ftl_skill_factors": {
			"breakout_judgement": 0.82,
			"communication_clarity": 0.78,
			"planning_quality": 0.8,
		},
	}


func _role_for(assignments: Array, fireteam_id: String) -> String:
	for assignment_variant in assignments:
		var assignment: Dictionary = Dictionary(assignment_variant)
		if String(assignment.get("fireteam_id", "")).strip_edges().to_lower() == fireteam_id:
			return String(assignment.get("role", ""))
	return ""


func _has_warning(dict: Dictionary, warning_id: String) -> bool:
	return PackedStringArray(dict.get("warnings", PackedStringArray())).has(warning_id)


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
