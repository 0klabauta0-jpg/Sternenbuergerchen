extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const TASK_DOC_PATH := "res://docs/tasks/TASK_1168_left_tactical_stack_air_anchor_polish.md"

var _checks := 0
var _failures: PackedStringArray = []


func _initialize() -> void:
	print("=== TASK_1168 Left Tactical Stack Air And Anchor Polish ===")
	root.size = Vector2i(1280, 720)
	_test_task_contract()

	var scene := MISSION_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(24)

	var controller := scene.get_node_or_null("TacticalController")
	var simulation_root := scene.get_node_or_null("SimulationRoot")
	_check(controller != null, "Mission fixture exposes TacticalController")
	_check(simulation_root != null, "Mission fixture exposes SimulationRoot")
	_check(controller != null and controller.has_method("get_left_tactical_stack_1280_air_anchor_polish_snapshot"), "Controller exposes TASK 1168 air/anchor snapshot")

	if controller != null and controller.has_method("get_left_tactical_stack_1280_air_anchor_polish_snapshot"):
		var command_count_before := Array(simulation_root.get("command_queue")).size() if simulation_root != null else -1
		var effect_count_before := Array(simulation_root.get("effects_queue")).size() if simulation_root != null else -1
		var snapshot: Dictionary = Dictionary(controller.call("get_left_tactical_stack_1280_air_anchor_polish_snapshot"))
		_check(String(snapshot.get("schema", "")) == "sternenbuergerchen.left_tactical_stack_1280_air_anchor_polish.v1", "Snapshot schema is stable")
		_check(String(snapshot.get("task_id", "")) == "TASK_1168", "Snapshot identifies TASK 1168")
		_check(String(snapshot.get("source_task_id", "")) == "TASK_1167", "Snapshot links TASK 1167")
		_check(String(snapshot.get("style_id", "")) == "task_1168_left_tactical_stack_air_anchor_v1", "Snapshot style id is stable")
		_check(String(snapshot.get("status", "")) == "air_anchor_polished", "Snapshot marks polish complete")
		_check(bool(snapshot.get("left_stack_air_anchor_ready", false)), "Left stack air/anchor polish is ready")
		_check(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot declares no UI gameplay truth")
		_check(not bool(snapshot.get("creates_command", true)), "Snapshot creates no command")
		_check(not bool(snapshot.get("creates_effect", true)), "Snapshot creates no effect")
		_check(not bool(snapshot.get("creates_fire_event", true)), "Snapshot creates no fire event")
		_check(not bool(snapshot.get("creates_damage_event", true)), "Snapshot creates no damage event")
		_check(not bool(snapshot.get("sets_multiplayer_truth", true)), "Snapshot creates no multiplayer truth")
		if simulation_root != null:
			_check(Array(simulation_root.get("command_queue")).size() == command_count_before, "TASK 1168 snapshot enqueues no command")
			_check(Array(simulation_root.get("effects_queue")).size() == effect_count_before, "TASK 1168 snapshot enqueues no effect")

		var source: Dictionary = Dictionary(snapshot.get("source_visual_acceptance", {}))
		_check(String(source.get("status", "")) == "accepted_with_followup", "TASK 1167 source remains accepted")
		_check(bool(source.get("ready_for_playability_slice", false)), "TASK 1167 source remains playability-ready")

		var surface: Dictionary = Dictionary(snapshot.get("air_anchor_surface", {}))
		_check(bool(surface.get("air_anchor_ready", false)), "Air/anchor surface is ready")
		_check(float(surface.get("left_anchor_px", 0.0)) >= 32.0, "Left anchor has breathing room")
		_check(bool(surface.get("shared_left_anchor", false)), "Fireteam mini and eventlog share the left anchor")
		_check(float(surface.get("mini_event_gap_px", 0.0)) >= 24.0, "Eventlog has vertical air below mini cards")
		_check(float(surface.get("card_host_separation_px", 0.0)) >= 8.0, "Mini cards have stable card separation")
		_check(bool(surface.get("event_log_below_fireteam_mini", false)), "Eventlog is below Fireteam mini panel")
		_check(bool(surface.get("event_log_above_bottom_dock", false)), "Eventlog remains above bottom dock")
		_check(bool(surface.get("layout_contract_grid_aligned", false)), "Adjusted layout remains on base grid")

	scene.queue_free()
	await _wait_frames(2)
	if _failures.is_empty():
		print("TASK_1168 PASS (%d checks)" % _checks)
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _test_task_contract() -> void:
	_check(FileAccess.file_exists(TASK_DOC_PATH), "TASK 1168 task document exists")
	var task_text := FileAccess.get_file_as_string(TASK_DOC_PATH)
	_check(task_text.contains("TASK_1167") and task_text.contains("luftiger"), "Task document links TASK 1167 and the air/anchor finding")
	_check(task_text.contains("get_left_tactical_stack_1280_air_anchor_polish_snapshot"), "Task document names snapshot contract")
	_check(task_text.contains("Keine neuen Commands") or task_text.contains("Keine Commands"), "Task document keeps gameplay scope out")


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
