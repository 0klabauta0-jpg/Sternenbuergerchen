extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const TASK_DOC_PATH := "res://docs/tasks/TASK_1169_left_stack_air_anchor_release_acceptance.md"

var _checks := 0
var _failures: PackedStringArray = []


func _initialize() -> void:
	print("=== TASK_1169 Left Stack Air Anchor Release Acceptance ===")
	root.size = Vector2i(1280, 720)
	_test_task_contract()

	var scene := MISSION_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(24)

	var controller := scene.get_node_or_null("TacticalController")
	var simulation_root := scene.get_node_or_null("SimulationRoot")
	_check(controller != null, "Mission fixture exposes TacticalController")
	_check(simulation_root != null, "Mission fixture exposes SimulationRoot")
	_check(controller != null and controller.has_method("get_left_tactical_stack_1280_air_anchor_release_acceptance_snapshot"), "Controller exposes TASK 1169 release-acceptance snapshot")

	if controller != null and controller.has_method("get_left_tactical_stack_1280_air_anchor_release_acceptance_snapshot"):
		var command_count_before := Array(simulation_root.get("command_queue")).size() if simulation_root != null else -1
		var effect_count_before := Array(simulation_root.get("effects_queue")).size() if simulation_root != null else -1
		var snapshot: Dictionary = Dictionary(controller.call("get_left_tactical_stack_1280_air_anchor_release_acceptance_snapshot"))
		_check(String(snapshot.get("schema", "")) == "sternenbuergerchen.left_tactical_stack_1280_air_anchor_release_acceptance.v1", "Snapshot schema is stable")
		_check(String(snapshot.get("task_id", "")) == "TASK_1169", "Snapshot identifies TASK 1169")
		_check(String(snapshot.get("source_task_id", "")) == "TASK_1168", "Snapshot links TASK 1168")
		_check(String(snapshot.get("status", "")) == "accepted", "Release acceptance is accepted")
		_check(bool(snapshot.get("ready_for_next_playability_step", false)), "Snapshot opens next playability step")
		_check(String(snapshot.get("recommended_next_task", "")).begins_with("TASK_1170"), "Snapshot recommends TASK 1170")
		_check(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot declares no UI gameplay truth")
		_check(not bool(snapshot.get("creates_command", true)), "Snapshot creates no command")
		_check(not bool(snapshot.get("creates_effect", true)), "Snapshot creates no effect")
		_check(not bool(snapshot.get("creates_fire_event", true)), "Snapshot creates no fire event")
		_check(not bool(snapshot.get("creates_damage_event", true)), "Snapshot creates no damage event")
		_check(not bool(snapshot.get("sets_multiplayer_truth", true)), "Snapshot creates no multiplayer truth")
		if simulation_root != null:
			_check(Array(simulation_root.get("command_queue")).size() == command_count_before, "TASK 1169 snapshot enqueues no command")
			_check(Array(simulation_root.get("effects_queue")).size() == effect_count_before, "TASK 1169 snapshot enqueues no effect")

		var source: Dictionary = Dictionary(snapshot.get("source_air_anchor", {}))
		_check(bool(source.get("left_stack_air_anchor_ready", false)), "TASK 1168 source remains ready")
		var release: Dictionary = Dictionary(snapshot.get("release_provenance", {}))
		_check(bool(release.get("valid", false)), "Release provenance is valid")
		_check(bool(release.get("matches_git_head", false)), "Release provenance matches Git HEAD")
		var capture: Dictionary = Dictionary(snapshot.get("capture_manifest", {}))
		_check(bool(capture.get("gate_passed", false)), "FirstContact capture gate passed")
		_check(bool(capture.get("release_gate_passed", false)), "Release start gate passed")
		_check(bool(capture.get("deployment_converged", false)), "Deployment converged")
		_check(bool(capture.get("first_fire_converged", false)), "First fire converged")
		var host_window: Dictionary = Dictionary(snapshot.get("host_window_artifact", {}))
		var client_window: Dictionary = Dictionary(snapshot.get("client_window_artifact", {}))
		_check(bool(host_window.get("exists", false)) and int(host_window.get("size_bytes", 0)) > 0, "Host window evidence exists")
		_check(bool(client_window.get("exists", false)) and int(client_window.get("size_bytes", 0)) > 0, "Client window evidence exists")
		_check(String(host_window.get("path", "")) != String(client_window.get("path", "")), "Host and client evidence stay separate")
		var accepted: Array = Array(snapshot.get("accepted_surfaces", []))
		_check(accepted.has("host_left_stack"), "Acceptance covers host left stack")
		_check(accepted.has("client_left_stack"), "Acceptance covers client left stack")
		_check(accepted.has("event_log_air_gap"), "Acceptance covers eventlog air gap")
		_check(accepted.has("multiplayer_consistency"), "Acceptance covers multiplayer consistency")
		_check(Array(snapshot.get("positive_findings", [])).size() >= 4, "Snapshot records positive visual findings")

	scene.queue_free()
	await _wait_frames(2)
	if _failures.is_empty():
		print("TASK_1169 PASS (%d checks)" % _checks)
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _test_task_contract() -> void:
	_check(FileAccess.file_exists(TASK_DOC_PATH), "TASK 1169 task document exists")
	var task_text := FileAccess.get_file_as_string(TASK_DOC_PATH)
	_check(task_text.contains("TASK_1168") and task_text.contains("Release"), "Task document links TASK 1168 and release acceptance")
	_check(task_text.contains("get_left_tactical_stack_1280_air_anchor_release_acceptance_snapshot"), "Task document names snapshot contract")
	_check(task_text.contains("Keine neuen Commands") or task_text.contains("Keine Commands"), "Task document keeps gameplay scope out")


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
