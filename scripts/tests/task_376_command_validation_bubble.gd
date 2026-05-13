extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const FEEDBACK_RESOLVER_SCRIPT: GDScript = preload("res://scripts/ui/fireteamleader_feedback_bubble_resolver.gd")
const COMIC_BUBBLE_RUNTIME_GATE_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_runtime_gate.gd")
const COMIC_BUBBLE_SETTINGS_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_settings.gd")
const TACTICAL_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_376_command_validation_bubble.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

var _passed: int = 0
var _failed: int = 0


class UnitRegistryStub:
	extends Node
	var active_unit_ids: Dictionary = {}

	func has_unit(unit_id: String) -> bool:
		return active_unit_ids.has(unit_id)


class FlowDriverStub:
	extends Node
	var unit_id: String = ""
	var accept_next: bool = true
	var issued_commands: Array = []

	func issue_command(command_type: String, phase_index: int) -> bool:
		issued_commands.append({
			"command_type": command_type,
			"phase": phase_index,
			"accepted": accept_next,
		})
		return accept_next


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_376 Command Validation Bubble ===")
	_test_resolver_uses_validation_key_text()
	_test_runtime_gate_deduplicates_and_prioritizes_validation()
	await _test_select_tile_first_creates_validation_bubble()
	await _test_failed_command_creates_second_validation_bubble()
	_test_docs()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_resolver_uses_validation_key_text() -> void:
	var leader: Node2D = _make_unit("blue_lead", "blue", true, Vector2(128.0, 192.0), 0.86)
	var payload: Dictionary = Dictionary(FEEDBACK_RESOLVER_SCRIPT.call("build_command_feedback", "move", "blocked", leader, leader.global_position, {}, {
		"fireteam_id": "blue",
		"detail": "no_tile",
	}))
	var validation: Dictionary = Dictionary(FEEDBACK_RESOLVER_SCRIPT.call("resolve_validation_feedback", "move", "blocked", {"detail": "no_tile"}))
	_assert(bool(payload.get("ok", false)), "Resolver builds a visual payload for command validation")
	_assert(String(payload.get("validation_key", "")) == "select_tile_first", "Resolver maps no_tile to select_tile_first")
	_assert(String(validation.get("validation_key", "")) == "select_tile_first", "Public validation helper exposes the same key")
	_assert(String(payload.get("text", "")).contains("Select"), "Validation bubble shows the concrete missing-tile reason")
	_assert(String(payload.get("text_source", "")) == "command_validation", "Validation bubble uses command-validation text source")
	_assert(int(payload.get("priority", 0)) >= 120, "Validation bubble has blocked-priority metadata")
	_assert(_is_visual_only_payload(payload), "Validation bubble remains visual-only")
	leader.free()


func _test_runtime_gate_deduplicates_and_prioritizes_validation() -> void:
	var gate = COMIC_BUBBLE_RUNTIME_GATE_SCRIPT.new()
	gate.call("set_settings", {
		"mode": COMIC_BUBBLE_SETTINGS_SCRIPT.MODE_NORMAL,
		"max_active_bubbles_total": 4,
		"command_feedback_cooldown_msec": 1000,
	})
	var first: Dictionary = _bubble_payload("select_tile_first", "blocked", 120)
	var duplicate: Dictionary = _bubble_payload("select_tile_first", "blocked", 120)
	var other_blocker: Dictionary = _bubble_payload("blocked_route", "blocked", 120)
	_assert(bool(gate.call("should_emit_payload", first, COMIC_BUBBLE_SETTINGS_SCRIPT.CATEGORY_FTL_COMMAND_FEEDBACK, 1000)), "Gate emits first validation bubble")
	_assert(not bool(gate.call("should_emit_payload", duplicate, COMIC_BUBBLE_SETTINGS_SCRIPT.CATEGORY_FTL_COMMAND_FEEDBACK, 1200)), "Gate deduplicates repeated validation bubble by cooldown")
	_assert(bool(gate.call("should_emit_payload", other_blocker, COMIC_BUBBLE_SETTINGS_SCRIPT.CATEGORY_FTL_COMMAND_FEEDBACK, 1200)), "Gate allows a different validation blocker")

	var priority_gate = COMIC_BUBBLE_RUNTIME_GATE_SCRIPT.new()
	priority_gate.call("set_settings", {
		"mode": COMIC_BUBBLE_SETTINGS_SCRIPT.MODE_NORMAL,
		"max_active_bubbles_total": 1,
		"command_feedback_cooldown_msec": 0,
	})
	var accepted: Dictionary = _bubble_payload("", "accepted", 20)
	var filtered: Array = Array(priority_gate.call("filter_payloads", [accepted, first], COMIC_BUBBLE_SETTINGS_SCRIPT.CATEGORY_FTL_COMMAND_FEEDBACK, 2000))
	_assert(filtered.size() == 1 and String(Dictionary(filtered[0]).get("validation_key", "")) == "select_tile_first", "Validation bubble wins over normal command flavor at the gate")


func _test_select_tile_first_creates_validation_bubble() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(24)

	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Mission scene exposes TacticalController")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	controller.call("set_comic_bubble_settings", _normal_bubble_settings())
	var fireteam_id: String = _get_alpha_driver_fireteam_id(scene, controller)
	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	planning_state["selected_fireteams"] = [fireteam_id]
	planning_state["embarked_unit_ids"] = []
	planning_state["deployed_unit_ids"] = _get_all_friendly_unit_ids(controller)
	planning_state["has_selected_tile"] = false
	controller.call("set_planning_state", planning_state)
	controller.call("_set_selected_fireteams", PackedStringArray([fireteam_id]), false)
	await _wait_frames(5)

	_assert(not bool(controller.call("issue_move")), "Move remains blocked without a selected tile")
	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var bubbles: Array = Array(feedback.get("fireteamleader_feedback_bubbles", []))
	_assert(bubbles.size() == 1, "Blocked tile-required command creates one validation bubble")
	if not bubbles.is_empty():
		var bubble: Dictionary = Dictionary(bubbles[0])
		_assert(String(bubble.get("validation_key", "")) == "select_tile_first", "Bubble references the select_tile_first validation key")
		_assert(String(bubble.get("validation_detail", "")) == "no_tile", "Bubble preserves the controller reject detail")
		_assert(String(bubble.get("feedback_state", "")) == "blocked", "Bubble remains a blocked command-feedback bubble")
		_assert(String(bubble.get("text", "")).contains("Select"), "Visible bubble text asks for tile selection")
	_assert(not bool(controller.call("issue_move")), "Repeated missing-tile click remains blocked")
	var repeated: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(int(repeated.get("fireteamleader_feedback_bubble_count", 0)) == 1, "Repeated click does not create a bubble flood")

	scene.queue_free()
	await _wait_frames(2)


func _test_failed_command_creates_second_validation_bubble() -> void:
	var mission_root := Node.new()
	mission_root.name = "MissionRoot"
	root.add_child(mission_root)

	var unit: Node2D = _make_unit("blue_lead", "blue", true, Vector2(96.0, 160.0), 0.82)
	var registry := UnitRegistryStub.new()
	registry.name = "UnitRegistry"
	registry.active_unit_ids["blue_lead"] = true
	var driver := FlowDriverStub.new()
	driver.name = "AlphaFlowDriver"
	driver.unit_id = "blue_lead"
	driver.accept_next = false
	var controller: Node = TACTICAL_CONTROLLER_SCRIPT.new()
	controller.name = "TacticalController"
	controller.alpha_flow_driver_path = NodePath("../AlphaFlowDriver")

	mission_root.add_child(registry)
	mission_root.add_child(unit)
	mission_root.add_child(driver)
	mission_root.add_child(controller)
	await _wait_frames(4)
	controller.call("set_comic_bubble_settings", _normal_bubble_settings())
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)

	_assert(not bool(controller.call("issue_defend")), "Rejected flow-driver command stays blocked")
	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var bubbles: Array = Array(feedback.get("fireteamleader_feedback_bubbles", []))
	_assert(bubbles.size() == 1, "Rejected command creates one validation bubble")
	if not bubbles.is_empty():
		var bubble: Dictionary = Dictionary(bubbles[0])
		_assert(String(bubble.get("validation_key", "")) == "blocked_route", "Failed flow-driver command maps to blocked_route validation")
		_assert(String(bubble.get("validation_detail", "")) == "failed", "Failed command preserves the reject detail")
		_assert(String(bubble.get("text", "")).contains("Blocked"), "Rejected command bubble shows blocked-route text")

	mission_root.queue_free()
	await _wait_frames(2)


func _test_docs() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_376 task file exists")
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "TASK_376 is marked implemented")
	_assert(status_text.contains("TASK_376") and status_text.to_lower().contains("implementiert"), "Implementation status mentions TASK_376")
	_assert(roadmap_text.contains("TASK_376") and roadmap_text.to_lower().contains("implementiert"), "Roadmap mentions TASK_376")


func _normal_bubble_settings() -> Dictionary:
	return {
		"mode": COMIC_BUBBLE_SETTINGS_SCRIPT.MODE_NORMAL,
		"ftl_command_feedback_enabled": true,
		"max_active_bubbles_total": 4,
		"command_feedback_cooldown_msec": 650,
	}


func _bubble_payload(validation_key: String, feedback_state: String, priority: int) -> Dictionary:
	return {
		"display_type": "comic_bubble",
		"bubble_id": "bubble_ftl_warning" if feedback_state == "blocked" else "bubble_ftl_ack",
		"source": "fireteamleader_command_feedback",
		"purpose": "command_feedback",
		"feedback_action": "move",
		"feedback_state": feedback_state,
		"validation_key": validation_key,
		"unit_id": "blue_lead",
		"fireteam_id": "blue",
		"anchor_position": Vector2(64.0, 96.0),
		"text": "Blocked route" if feedback_state == "blocked" else "Okay",
		"visual_only": true,
		"priority": priority,
	}


func _make_unit(unit_id: String, fireteam_id: String, is_lead: bool, world_position: Vector2, leadership: float) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.display_name = unit_id
	unit.team_id = "team_alpha"
	unit.fireteam_id = fireteam_id
	unit.is_fireteam_lead = is_lead
	unit.skill_leadership = leadership
	unit.discipline = leadership
	unit.awareness = leadership
	unit.speech_quality = leadership
	unit.position = world_position
	unit._ready()
	return unit


func _get_alpha_driver_fireteam_id(scene: Node, controller: Node) -> String:
	var alpha_driver := scene.get_node_or_null("AlphaFlowDriver")
	if alpha_driver != null:
		var fireteam_id: String = String(controller.call("_get_fireteam_id_for_flow_driver", alpha_driver)).strip_edges().to_lower()
		if not fireteam_id.is_empty():
			return fireteam_id
	var fireteams: PackedStringArray = PackedStringArray(controller.call("_get_available_fireteam_ids"))
	return String(fireteams[0]).strip_edges().to_lower() if fireteams.size() > 0 else ""


func _get_all_friendly_unit_ids(controller: Node) -> Array:
	var result: Array = []
	for unit in Array(controller.call("_get_all_friendly_units", true)):
		if unit != null and unit.has_method("get_unit_id"):
			result.append(String(unit.call("get_unit_id")).strip_edges())
	return result


func _is_visual_only_payload(payload: Dictionary) -> bool:
	if not bool(payload.get("visual_only", false)):
		return false
	for forbidden_key in ["command_type", "effect_type", "unit_command", "simulation_effect", "damage", "heal"]:
		if payload.has(forbidden_key):
			return false
	return true


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


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
