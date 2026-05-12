extends SceneTree

const BREAKOUT_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_breakout_resolver.gd")
const EXECUTION_PLAN_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_execution_plan.gd")
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const CATALOG_PATH: String = "res://data/tactical_breakout_catalog.json"
const DOC_PATH: String = "res://docs/dev/tactical_breakout_exception_contract.md"
const TASK_PATH: String = "res://docs/tasks/TASK_276_tactical_breakout_and_exception_behavior.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_276 Tactical Breakout and Exception Behavior ===")
	_test_catalog_and_doc_contract()
	_test_core_trigger_resolution()
	_test_commander_rule_gating()
	_test_communication_and_return_to_plan()
	_test_execution_plan_breakout_context()
	await _test_mission_controller_feedback()
	_test_task_status()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_catalog_and_doc_contract() -> void:
	_assert(FileAccess.file_exists(CATALOG_PATH), "Breakout catalog exists")
	_assert(FileAccess.file_exists("res://scripts/tactical/tactical_breakout_resolver.gd"), "Breakout resolver exists")
	_assert(FileAccess.file_exists(DOC_PATH), "Breakout contract doc exists")
	var catalog: Dictionary = _read_json(CATALOG_PATH)
	var triggers: Dictionary = Dictionary(catalog.get("triggers", {}))
	for trigger in [
		"contact",
		"suppressed_pinned",
		"casualty_medic_needed",
		"blocked_route",
		"out_of_weapon_range",
		"low_ammo_no_weapon",
		"leader_down",
		"air_asset_threatened",
		"air_asset_destroyed",
		"rule_conflict",
	]:
		_assert(triggers.has(trigger), "Catalog defines trigger %s" % trigger)
	var classes: Dictionary = Dictionary(catalog.get("breakout_classes", {}))
	for breakout_class in ["auto_adapt", "hold_and_report", "request_orders", "abort_to_safe"]:
		_assert(classes.has(breakout_class), "Catalog defines class %s" % breakout_class)
	var doc_text: String = _read_text(DOC_PATH)
	for token in ["auto_adapt", "hold_and_report", "request_orders", "abort_to_safe", "event_id", "ui_sets_gameplay_truth = false", "Return-To-Plan"]:
		_assert(doc_text.contains(token), "Contract doc contains %s" % token)


func _test_core_trigger_resolution() -> void:
	var plan: Dictionary = _base_plan()
	var expectations: Dictionary = {
		"contact": "hold_and_report",
		"suppressed_pinned": "hold_and_report",
		"casualty_medic_needed": "hold_and_report",
		"blocked_route": "auto_adapt",
		"out_of_weapon_range": "request_orders",
		"low_ammo_no_weapon": "request_orders",
		"leader_down": "hold_and_report",
		"air_asset_threatened": "request_orders",
		"air_asset_destroyed": "abort_to_safe",
		"rule_conflict": "request_orders",
	}
	for trigger in expectations.keys():
		var breakout: Dictionary = Dictionary(BREAKOUT_RESOLVER_SCRIPT.call("evaluate_breakout", plan, {
			"trigger": trigger,
			"fireteam_id": "blue",
			"breakout_judgement": 0.86,
			"communication_clarity": 0.8,
			"sequence": trigger,
		}))
		_assert(str(breakout.get("trigger", "")) == trigger, "%s trigger is preserved" % trigger)
		_assert(str(breakout.get("breakout_class", "")) == str(expectations[trigger]), "%s resolves to %s" % [trigger, expectations[trigger]])
		_assert(not str(breakout.get("event_id", "")).is_empty(), "%s breakout has event ID" % trigger)
		_assert(bool(breakout.get("visual_only", false)) and not bool(breakout.get("ui_sets_gameplay_truth", true)), "%s breakout stays visual-only" % trigger)
	var low_contact: Dictionary = Dictionary(BREAKOUT_RESOLVER_SCRIPT.call("evaluate_breakout", plan, {
		"trigger": "contact",
		"fireteam_id": "blue",
		"breakout_judgement": 0.2,
		"communication_clarity": 0.3,
		"sequence": "low_contact",
	}))
	_assert(str(low_contact.get("breakout_class", "")) == "request_orders", "Low FTL judgement asks for orders on uncertain contact")
	_assert(float(low_contact.get("detection_delay_seconds", 0.0)) > 1.0, "Low FTL judgement produces slower detection")


func _test_commander_rule_gating() -> void:
	var limited_plan: Dictionary = _base_plan()
	limited_plan["allowed_breakout_classes"] = PackedStringArray(["hold_and_report", "request_orders"])
	var blocked: Dictionary = Dictionary(BREAKOUT_RESOLVER_SCRIPT.call("evaluate_breakout", limited_plan, {
		"trigger": "blocked_route",
		"fireteam_id": "blue",
		"breakout_judgement": 0.9,
		"sequence": "limited_blocked",
	}))
	_assert(str(blocked.get("breakout_class", "")) == "hold_and_report", "Blocked auto-adapt downgrades to allowed hold/report")
	_assert(bool(blocked.get("within_commander_rules", false)), "Adjusted breakout remains within commander rules")
	_assert(str(blocked.get("commander_rule_resolution", "")).contains("adjusted"), "Adjusted breakout marks rule resolution")
	var air_lost: Dictionary = Dictionary(BREAKOUT_RESOLVER_SCRIPT.call("evaluate_breakout", limited_plan, {
		"trigger": "air_asset_destroyed",
		"fireteam_id": "blue",
		"breakout_judgement": 0.9,
		"sequence": "limited_air",
	}))
	_assert(str(air_lost.get("breakout_class", "")) == "request_orders", "Air loss asks orders when abort is not allowed")


func _test_communication_and_return_to_plan() -> void:
	var breakout: Dictionary = Dictionary(BREAKOUT_RESOLVER_SCRIPT.call("evaluate_breakout", _base_plan(), {
		"trigger": "blocked_route",
		"fireteam_id": "gold",
		"breakout_judgement": 0.88,
		"communication_clarity": 0.78,
		"sequence": "comm",
	}))
	var event: Dictionary = Dictionary(BREAKOUT_RESOLVER_SCRIPT.call("build_communication_event", breakout, {"now_msec": 1200}))
	_assert(str(event.get("event_id", "")) == str(breakout.get("event_id", "")), "Communication event keeps breakout event ID")
	_assert(str(event.get("event_type", "")) == "cannot_execute", "Blocked route produces cannot_execute communication")
	_assert(str(event.get("fireteam_id", "")) == "gold", "Communication event carries fireteam")
	var returned: Dictionary = Dictionary(BREAKOUT_RESOLVER_SCRIPT.call("mark_return_to_plan", breakout, {"reason": "route_clear", "now_msec": 1500}))
	_assert(str(returned.get("status", "")) == "returned_to_plan", "Auto-adapt breakout can return to plan")
	_assert(bool(returned.get("resolved", false)), "Returned breakout is resolved")
	var request_breakout: Dictionary = Dictionary(BREAKOUT_RESOLVER_SCRIPT.call("evaluate_breakout", _base_plan(), {
		"trigger": "low_ammo_no_weapon",
		"fireteam_id": "gold",
		"sequence": "ammo",
	}))
	var request_event: Dictionary = Dictionary(BREAKOUT_RESOLVER_SCRIPT.call("build_communication_event", request_breakout, {"now_msec": 1300}))
	_assert(str(request_event.get("event_type", "")) == "needs_orders", "Request-orders breakout emits a needs-orders communication type")
	_assert(PackedStringArray(request_event.get("channels", PackedStringArray())).has("map_marker"), "Needs-orders communication reaches the persistent map marker channel")
	var denied: Dictionary = Dictionary(BREAKOUT_RESOLVER_SCRIPT.call("mark_return_to_plan", request_breakout, {"reason": "ignored"}))
	_assert(not bool(denied.get("resolved", false)) and str(denied.get("return_to_plan_denied_reason", "")).contains("commander"), "Request-orders breakout denies automatic return")


func _test_execution_plan_breakout_context() -> void:
	var plan = EXECUTION_PLAN_SCRIPT.call("from_dict", _base_plan())
	_assert(plan != null and bool(plan.call("allows_breakout_class", "auto_adapt")), "Execution plan exposes allowed breakout check")
	var context: Dictionary = Dictionary(plan.call("build_breakout_plan_context", "blocked_route", {"blocked_path": true}))
	_assert(str(context.get("breakout_trigger", "")) == "blocked_route", "Execution plan builds breakout context")
	_assert(not bool(context.get("ui_sets_gameplay_truth", true)), "Execution plan breakout context does not set UI truth")


func _test_mission_controller_feedback() -> void:
	var scene := MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var controller: Node = scene.get_node("TacticalController")
	_assert(controller != null and controller.has_method("record_tactical_breakout"), "Controller exposes breakout recording")
	if controller == null:
		return
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	var breakout: Dictionary = Dictionary(controller.call("record_tactical_breakout", "blocked_route", "blue", {
		"blocked_path": true,
		"breakout_judgement": 0.9,
		"communication_clarity": 0.8,
		"allowed_breakout_classes": PackedStringArray(["auto_adapt", "hold_and_report", "request_orders"]),
		"sequence": "mission",
	}, {"now_msec": 2000}))
	_assert(str(breakout.get("breakout_class", "")) == "auto_adapt", "Mission controller records auto-adapt breakout")
	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(int(feedback.get("tactical_breakout_count", 0)) >= 1, "Command feedback includes breakout count")
	_assert(Array(feedback.get("tactical_breakouts", [])).size() >= 1, "Command feedback includes breakout records")
	_assert(int(feedback.get("tactical_communication_event_count", 0)) >= 1, "Breakout emits tactical communication event")
	var returned: Dictionary = Dictionary(controller.call("resolve_tactical_breakout_return_to_plan", str(breakout.get("breakout_id", "")), {"reason": "route_clear", "now_msec": 2500}))
	_assert(str(returned.get("status", "")) == "returned_to_plan", "Mission controller marks breakout returned to plan")
	scene.queue_free()
	await _wait_frames(2)


func _test_task_status() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "Task file marks TASK_276 implemented")
	_assert(not task_text.contains("- [ ]"), "Task checklist is complete")
	_assert(status_text.contains("TASK_276") and status_text.to_lower().contains("implementiert"), "Implementation status mentions TASK_276 implemented")
	_assert(roadmap_text.contains("TASK_276") and roadmap_text.to_lower().contains("implementiert"), "Roadmap mentions TASK_276 implemented")


func _base_plan() -> Dictionary:
	return {
		"plan_id": "task276_plan",
		"command_id": "task276_command",
		"fireteam_id": "blue",
		"phase": 1,
		"target_position": Vector2(640.0, 640.0),
		"allowed_breakout_classes": PackedStringArray(["auto_adapt", "hold_and_report", "request_orders", "abort_to_safe"]),
		"ftl_skill_factors": {
			"breakout_judgement": 0.82,
			"communication_clarity": 0.78,
			"planning_quality": 0.8,
		},
	}


func _read_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	var parsed = JSON.parse_string(text)
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
