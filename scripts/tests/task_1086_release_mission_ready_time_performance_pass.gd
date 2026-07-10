extends SceneTree

const META_SCENE_PATH := "res://scenes/meta/meta_layer_test.tscn"
const META_SCRIPT_PATH := "res://scripts/meta/meta_layer_flow.gd"
const DEEPLINK_ARG := "--release-singleplayer-first-go-firefight"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1086 Release Mission Ready-Time Performance Pass ===")
	_test_condition_based_wait_contract()
	await _test_integrated_ready_time_and_authority()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_condition_based_wait_contract() -> void:
	var meta_text := FileAccess.get_file_as_string(META_SCRIPT_PATH)
	_assert(meta_text.contains("_wait_release_first_go_runtime_ready"), "GO wait uses a bounded runtime-ready predicate")
	_assert(meta_text.contains("_wait_release_first_exchange_visible_ready"), "Final wait uses a bounded visible-state predicate")
	_assert(meta_text.contains('"first_exchange_visible_not_ready"'), "Visible-state timeout has an explicit blocker reason")
	_assert(meta_text.contains('"elapsed_msec"'), "Trace samples export elapsed milliseconds")
	_assert(meta_text.contains('"delta_msec"'), "Trace samples export delta milliseconds")
	_assert(not meta_text.contains("await _wait_release_deeplink_frames(45)"), "First-GO flow no longer waits 45 blind frames")
	var final_wait_pattern := "after_immediate_exchange_applied_gate\", controller, {\"immediate_exchange_applied\": immediate_exchange_applied}, args)\n\tawait _wait_release_deeplink_frames(10)"
	_assert(not meta_text.contains(final_wait_pattern), "Final first-exchange wait is no longer a blind ten-frame delay")


func _test_integrated_ready_time_and_authority() -> void:
	root.size = Vector2i(1920, 1080)
	var packed := ResourceLoader.load(META_SCENE_PATH) as PackedScene
	var scene := packed.instantiate() if packed != null else null
	_assert(scene != null, "MetaLayer release scene instantiates")
	if scene == null:
		return
	root.add_child(scene)
	await _wait_frames(10)
	var started_msec := Time.get_ticks_msec()
	await scene.call("_apply_release_first_go_firefight_deeplink", PackedStringArray([DEEPLINK_ARG]))
	var elapsed_msec := Time.get_ticks_msec() - started_msec
	var snapshot: Dictionary = Dictionary(scene.call("get_release_first_go_firefight_deeplink_snapshot", PackedStringArray([DEEPLINK_ARG])))
	var active_mission := scene.get("_active_mission") as Node
	var controller := active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var simulation_root := active_mission.get_node_or_null("SimulationRoot") if active_mission != null else null
	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot")) if controller != null else {}
	var source: Dictionary = Dictionary(controller.call("get_release_first_exchange_visible_status_source_reconciliation_snapshot")) if controller != null else {}
	var fire_event: Dictionary = Dictionary(Dictionary(source.get("status_source", {})).get("fire_event", {}))
	print("TASK_1086_READY elapsed_msec=%d status=%s reason=%s fire_event=%s" % [elapsed_msec, String(snapshot.get("status", "")), String(snapshot.get("reason", "")), String(fire_event.get("event_id", fire_event.get("fire_event_id", "")))])

	_assert(String(snapshot.get("status", "")) == "applied", "Condition-based path reaches applied deeplink state")
	_assert(bool(snapshot.get("go_executed", false)), "GO remains visibly executed")
	_assert(controller != null and simulation_root != null, "Mission keeps controller and SimulationRoot authority nodes")
	_assert(String(feedback.get("selected_fireteam_status_label_text", "")).to_upper().begins_with("CONTACT FIRE"), "Selected Fireteam keeps visible CONTACT FIRE")
	_assert(String(feedback.get("mission_control_status_text", "")).to_upper().begins_with("CONTACT FIRE"), "Mission Control keeps visible CONTACT FIRE")
	_assert(bool(source.get("active", false)) and not fire_event.is_empty(), "Visible state keeps real FireEvent evidence")
	_assert(not bool(source.get("ui_sets_gameplay_truth", true)), "Ready-state source stays read-only")
	_assert(elapsed_msec < 45000, "Integrated first exchange stays below the conservative 45-second headless regression budget")

	scene.queue_free()
	await _wait_frames(2)


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
