extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const TASK_DOC_PATH := "res://docs/tasks/TASK_1165_left_tactical_stack_1280_detail_polish.md"

var _checks := 0
var _failures: PackedStringArray = []


func _initialize() -> void:
	print("=== TASK_1165 Left Tactical Stack 1280 Detail Polish ===")
	root.size = Vector2i(1280, 720)
	_test_task_contract()

	var scene := MISSION_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(24)

	var controller := scene.get_node_or_null("TacticalController")
	var simulation_root := scene.get_node_or_null("SimulationRoot")
	_check(controller != null, "Mission fixture exposes TacticalController")
	_check(simulation_root != null, "Mission fixture exposes SimulationRoot")
	_check(controller != null and controller.has_method("get_left_tactical_stack_1280_detail_polish_snapshot"), "Controller exposes TASK 1165 detail-polish snapshot")

	if controller != null and controller.has_method("get_left_tactical_stack_1280_detail_polish_snapshot"):
		var command_count_before := Array(simulation_root.get("command_queue")).size() if simulation_root != null else -1
		var effect_count_before := Array(simulation_root.get("effects_queue")).size() if simulation_root != null else -1
		var snapshot: Dictionary = Dictionary(controller.call("get_left_tactical_stack_1280_detail_polish_snapshot"))
		_check(String(snapshot.get("schema", "")) == "sternenbuergerchen.left_tactical_stack_1280_detail_polish.v1", "Snapshot schema is stable")
		_check(String(snapshot.get("task_id", "")) == "TASK_1165", "Snapshot identifies TASK 1165")
		_check(String(snapshot.get("source_task_id", "")) == "TASK_1164", "Snapshot links TASK 1164 findings")
		_check(String(snapshot.get("style_id", "")) == "task_1165_left_tactical_stack_1280_detail_polish_v1", "Snapshot style id is stable")
		_check(bool(snapshot.get("left_stack_detail_polish_ready", false)), "Left-stack detail polish is ready")
		_check(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot declares no UI gameplay truth")
		_check(not bool(snapshot.get("creates_command", true)), "Snapshot creates no command")
		_check(not bool(snapshot.get("creates_effect", true)), "Snapshot creates no effect")
		_check(not bool(snapshot.get("creates_fire_event", true)), "Snapshot creates no fire event")
		_check(not bool(snapshot.get("creates_damage_event", true)), "Snapshot creates no damage event")
		_check(not bool(snapshot.get("sets_multiplayer_truth", true)), "Snapshot creates no multiplayer truth")
		if simulation_root != null:
			_check(Array(simulation_root.get("command_queue")).size() == command_count_before, "TASK 1165 snapshot enqueues no command")
			_check(Array(simulation_root.get("effects_queue")).size() == effect_count_before, "TASK 1165 snapshot enqueues no effect")

		var source: Dictionary = Dictionary(snapshot.get("source_findings", {}))
		_check(String(source.get("status", "")) != "ready_for_left_stack_visual_polish", "TASK 1164 default findings no longer route to detail polish")
		_check(bool(source.get("accepted", false)), "TASK 1164 default findings are accepted after detail polish")

		var mini: Dictionary = Dictionary(snapshot.get("fireteam_mini_detail", {}))
		_check(bool(mini.get("detail_ready", false)), "Mini-card detail surface is ready")
		_check(int(mini.get("visible_card_count", 0)) >= 2, "At least two mini-cards are inspected")
		_check(int(mini.get("detail_ready_card_count", 0)) >= 2, "Two mini-cards satisfy detail polish")
		for card_variant in Array(mini.get("cards", [])):
			var card: Dictionary = Dictionary(card_variant)
			var card_id := String(card.get("fireteam_id", ""))
			_check(float(card.get("card_min_height", 0.0)) >= 120.0, "%s card height gives detail strip room" % card_id)
			_check(int(card.get("lead_font_size", 0)) >= 12, "%s lead/detail font is readable" % card_id)
			_check(int(card.get("member_strip_font_size", 0)) >= 11, "%s member strip font is readable" % card_id)
			_check(int(card.get("portrait_strip_count", 0)) >= 3, "%s keeps visible member portraits" % card_id)
			_check(bool(card.get("detail_polish_style_applied", false)), "%s has TASK 1165 detail style" % card_id)

		var event_log: Dictionary = Dictionary(snapshot.get("event_log_filter_detail", {}))
		_check(bool(event_log.get("filter_ready", false)), "Eventlog filter surface is ready")
		_check(int(event_log.get("filter_font_size", 0)) >= 13, "Eventlog filter label uses readable font")
		_check(float(event_log.get("filter_min_width", 0.0)) >= 96.0, "Eventlog filter has stable hit width")
		_check(int(event_log.get("count_font_size", 0)) >= 12, "Eventlog count remains readable")
		_check(bool(event_log.get("count_separated_from_filter", false)), "Eventlog count is separate from filter control")

	scene.queue_free()
	await _wait_frames(2)
	if _failures.is_empty():
		print("TASK_1165 PASS (%d checks)" % _checks)
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _test_task_contract() -> void:
	_check(FileAccess.file_exists(TASK_DOC_PATH), "TASK 1165 task document exists")
	var task_text := FileAccess.get_file_as_string(TASK_DOC_PATH)
	_check(task_text.contains("Mini-Cards") and task_text.contains("Eventlog"), "Task document names both detail surfaces")
	_check(task_text.contains("get_left_tactical_stack_1280_detail_polish_snapshot"), "Task document names snapshot contract")
	_check(task_text.contains("Keine Aenderung") and task_text.contains("Multiplayer"), "Task document keeps gameplay and multiplayer scope out")


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
