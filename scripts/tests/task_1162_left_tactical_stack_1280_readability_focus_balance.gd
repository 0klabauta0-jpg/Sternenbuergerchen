extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const TASK_DOC_PATH := "res://docs/tasks/TASK_1162_left_tactical_stack_1280_readability_focus_balance.md"

var _checks := 0
var _failures: PackedStringArray = []


func _initialize() -> void:
	print("=== TASK_1162 Left Tactical Stack 1280 Readability Focus Balance ===")
	root.size = Vector2i(1280, 720)
	_test_task_contract()

	var scene := MISSION_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(24)

	var controller := scene.get_node_or_null("TacticalController")
	var simulation_root := scene.get_node_or_null("SimulationRoot")
	_check(controller != null, "Mission fixture exposes TacticalController")
	_check(simulation_root != null, "Mission fixture exposes SimulationRoot")
	_check(controller != null and controller.has_method("get_left_tactical_stack_1280_readability_snapshot"), "Controller exposes TASK 1162 left-stack snapshot")

	if controller != null and controller.has_method("get_left_tactical_stack_1280_readability_snapshot"):
		var command_count_before := Array(simulation_root.get("command_queue")).size() if simulation_root != null else -1
		var effect_count_before := Array(simulation_root.get("effects_queue")).size() if simulation_root != null else -1
		var snapshot: Dictionary = Dictionary(controller.call("get_left_tactical_stack_1280_readability_snapshot"))
		_check(String(snapshot.get("schema", "")) == "sternenbuergerchen.left_tactical_stack_1280_readability.v1", "Snapshot schema is stable")
		_check(String(snapshot.get("task_id", "")) == "TASK_1162", "Snapshot identifies TASK 1162")
		_check(String(snapshot.get("style_id", "")) == "task_1162_left_tactical_stack_1280_readability_v1", "Snapshot style id is stable")
		_check(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot declares no UI gameplay truth")
		_check(not bool(snapshot.get("creates_command", true)), "Snapshot creates no command")
		_check(not bool(snapshot.get("creates_effect", true)), "Snapshot creates no effect")
		if simulation_root != null:
			_check(Array(simulation_root.get("command_queue")).size() == command_count_before, "Left-stack snapshot enqueues no command")
			_check(Array(simulation_root.get("effects_queue")).size() == effect_count_before, "Left-stack snapshot enqueues no effect")

		var stack: Dictionary = Dictionary(snapshot.get("stack", {}))
		_check(String(stack.get("expected_resolution", "")) == "1280x720", "Stack anchors the release resolution")
		_check(bool(stack.get("mini_event_no_overlap", false)), "Mini-card panel and Event Log do not overlap")
		_check(bool(stack.get("left_stack_readability_ready", false)), "Combined left stack is readability-ready")

		var mini: Dictionary = Dictionary(snapshot.get("fireteam_mini", {}))
		_check(bool(mini.get("readability_ready", false)), "Fireteam mini surface is readable")
		_check(int(mini.get("visible_card_count", 0)) >= 2, "At least two Fireteam mini-cards are visible")
		_check(int(mini.get("focused_card_count", 0)) == 1, "Exactly one Fireteam mini-card owns focus")
		_check(int(mini.get("readable_card_count", 0)) >= 2, "Two mini-cards satisfy the 1280 font floors")
		_check(int(mini.get("stance_ready_card_count", 0)) >= 2, "Mini-cards keep stance controls")
		for card_variant in Array(mini.get("cards", [])):
			var card: Dictionary = Dictionary(card_variant)
			_check(int(card.get("title_font_size", 0)) >= 13, "%s title meets the 1280 floor" % String(card.get("fireteam_id", "")))
			_check(int(card.get("status_font_size", 0)) >= 11, "%s status meets the 1280 floor" % String(card.get("fireteam_id", "")))
			_check(int(card.get("lead_font_size", 0)) >= 11, "%s lead line meets the 1280 floor" % String(card.get("fireteam_id", "")))
			_check(bool(card.get("focus_style_applied", false)) == bool(card.get("primary_focus", false)), "%s focus style follows the primary focus" % String(card.get("fireteam_id", "")))

		var event_log: Dictionary = Dictionary(snapshot.get("event_log", {}))
		_check(bool(event_log.get("readability_ready", false)), "Event Log keeps its TASK 1159 readability contract")
		_check(String(event_log.get("source_task_id", "")) == "TASK_1159", "Event Log references TASK 1159 as source")
		_check(float(event_log.get("background_alpha", 0.0)) >= 0.94, "Event Log keeps the readable tactical background")

	scene.queue_free()
	await _wait_frames(2)
	if _failures.is_empty():
		print("TASK_1162 PASS (%d checks)" % _checks)
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _test_task_contract() -> void:
	_check(FileAccess.file_exists(TASK_DOC_PATH), "TASK 1162 task document exists")
	var task_text := FileAccess.get_file_as_string(TASK_DOC_PATH)
	_check(task_text.contains("Fireteam-Mini-Cards") and task_text.contains("Tactical Event Log"), "Task document names both left-stack surfaces")
	_check(task_text.contains("get_left_tactical_stack_1280_readability_snapshot"), "Task document names the snapshot contract")
	_check(task_text.contains("Keine neuen Fireteam") or task_text.contains("Keine neuen"), "Task document keeps gameplay scope out")


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
