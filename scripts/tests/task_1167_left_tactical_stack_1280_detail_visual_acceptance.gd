extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const TASK_DOC_PATH := "res://docs/tasks/TASK_1167_left_tactical_stack_1280_detail_visual_acceptance.md"

var _checks := 0
var _failures: PackedStringArray = []


func _initialize() -> void:
	print("=== TASK_1167 Left Tactical Stack 1280 Detail Visual Acceptance ===")
	root.size = Vector2i(1280, 720)
	_test_task_contract()

	var scene := MISSION_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(24)

	var controller := scene.get_node_or_null("TacticalController")
	var simulation_root := scene.get_node_or_null("SimulationRoot")
	_check(controller != null, "Mission fixture exposes TacticalController")
	_check(simulation_root != null, "Mission fixture exposes SimulationRoot")
	_check(controller != null and controller.has_method("get_left_tactical_stack_1280_detail_visual_acceptance_snapshot"), "Controller exposes TASK 1167 visual acceptance snapshot")

	if controller != null and controller.has_method("get_left_tactical_stack_1280_detail_visual_acceptance_snapshot"):
		var command_count_before := Array(simulation_root.get("command_queue")).size() if simulation_root != null else -1
		var effect_count_before := Array(simulation_root.get("effects_queue")).size() if simulation_root != null else -1
		var snapshot: Dictionary = Dictionary(controller.call("get_left_tactical_stack_1280_detail_visual_acceptance_snapshot"))
		_check(String(snapshot.get("schema", "")) == "sternenbuergerchen.left_tactical_stack_1280_detail_visual_acceptance.v1", "Snapshot schema is stable")
		_check(String(snapshot.get("task_id", "")) == "TASK_1167", "Snapshot identifies TASK 1167")
		_check(String(snapshot.get("source_task_id", "")) == "TASK_1166", "Snapshot links TASK 1166")
		_check(String(snapshot.get("status", "")) == "accepted_with_followup", "Visual acceptance is accepted with follow-up")
		_check(bool(snapshot.get("ready_for_playability_slice", false)), "Snapshot opens next playability slice")
		_check(String(snapshot.get("recommended_next_task", "")) == "TASK_1168 - Left Tactical Stack Air And Anchor Polish", "Snapshot recommends focused air/anchor follow-up")
		_check(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot declares no UI gameplay truth")
		_check(not bool(snapshot.get("creates_command", true)), "Snapshot creates no command")
		_check(not bool(snapshot.get("creates_effect", true)), "Snapshot creates no effect")
		_check(not bool(snapshot.get("creates_fire_event", true)), "Snapshot creates no fire event")
		_check(not bool(snapshot.get("creates_damage_event", true)), "Snapshot creates no damage event")
		_check(not bool(snapshot.get("sets_multiplayer_truth", true)), "Snapshot creates no multiplayer truth")
		if simulation_root != null:
			_check(Array(simulation_root.get("command_queue")).size() == command_count_before, "TASK 1167 snapshot enqueues no command")
			_check(Array(simulation_root.get("effects_queue")).size() == effect_count_before, "TASK 1167 snapshot enqueues no effect")

		var recapture: Dictionary = Dictionary(snapshot.get("recapture", {}))
		_check(bool(recapture.get("detail_recapture_ready", false)), "TASK 1166 recapture remains ready")
		var host_window: Dictionary = Dictionary(recapture.get("host_window_artifact", {}))
		var client_window: Dictionary = Dictionary(recapture.get("client_window_artifact", {}))
		_check(bool(host_window.get("exists", false)) and int(host_window.get("size_bytes", 0)) > 0, "Host window evidence exists")
		_check(bool(client_window.get("exists", false)) and int(client_window.get("size_bytes", 0)) > 0, "Client window evidence exists")
		_check(String(host_window.get("path", "")) != String(client_window.get("path", "")), "Host and client evidence stay separate")

		var accepted: Array = Array(snapshot.get("accepted_surfaces", []))
		_check(accepted.has("fireteam_mini_cards"), "Acceptance covers Fireteam mini cards")
		_check(accepted.has("primary_focus"), "Acceptance covers primary focus")
		_check(accepted.has("event_log"), "Acceptance covers event log")
		_check(accepted.has("selected_member_cards"), "Acceptance covers selected member cards")

		var positives: Array = Array(snapshot.get("positive_findings", []))
		_check(positives.size() >= 4, "Snapshot records positive visual findings")
		var followups: Array = Array(snapshot.get("followup_findings", []))
		_check(followups.size() == 1, "Snapshot keeps exactly one follow-up finding")
		var followup: Dictionary = Dictionary(followups[0]) if not followups.is_empty() else {}
		_check(String(followup.get("route_to", "")) == "TASK_1168 - Left Tactical Stack Air And Anchor Polish", "Follow-up routes to TASK 1168")
		_check(String(followup.get("severity", "")) == "minor", "Follow-up is minor, not a blocker")

	scene.queue_free()
	await _wait_frames(2)
	if _failures.is_empty():
		print("TASK_1167 PASS (%d checks)" % _checks)
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _test_task_contract() -> void:
	_check(FileAccess.file_exists(TASK_DOC_PATH), "TASK 1167 task document exists")
	var task_text := FileAccess.get_file_as_string(TASK_DOC_PATH)
	_check(task_text.contains("TASK_1166") and task_text.contains("Host-") and task_text.contains("Client-"), "Task document links TASK 1166 and separate windows")
	_check(task_text.contains("accepted") or task_text.contains("Akzeptanz"), "Task document describes acceptance")
	_check(task_text.contains("Keine neuen Commands") or task_text.contains("Keine Commands"), "Task document keeps gameplay scope out")


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
