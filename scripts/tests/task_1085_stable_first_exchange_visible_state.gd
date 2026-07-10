extends SceneTree

const META_SCENE_PATH := "res://scenes/meta/meta_layer_test.tscn"
const DEEPLINK_ARG := "--release-singleplayer-first-go-firefight"
const CAPTURE_SCRIPT_PATH := "res://scripts/tools/capture_release_first_go_firefight_real_window.ps1"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1085 Stable First Exchange Visible State ===")
	_test_capture_waits_for_runtime_readiness()
	await _test_delayed_visible_first_exchange_state()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_capture_waits_for_runtime_readiness() -> void:
	var capture_text := FileAccess.get_file_as_string(CAPTURE_SCRIPT_PATH)
	_assert(capture_text.contains("STERNENBUERGERCHEN_RELEASE_FIRST_EXCHANGE_TRACE_PATH"), "Capture injects the existing runtime trace path")
	_assert(capture_text.contains("deeplink_final"), "Capture waits for the final deep-link stage")
	_assert(capture_text.contains("ready_observed"), "Capture manifest exports readiness evidence")
	_assert(not capture_text.contains("Start-Sleep -Seconds ([Math]::Max(1, $WaitSeconds))"), "Capture no longer sleeps a blind fixed duration")


func _test_delayed_visible_first_exchange_state() -> void:
	root.size = Vector2i(1920, 1080)
	var packed := ResourceLoader.load(META_SCENE_PATH) as PackedScene
	var scene := packed.instantiate() if packed != null else null
	_assert(scene != null, "MetaLayer release scene instantiates")
	if scene == null:
		return
	root.add_child(scene)
	await _wait_frames(10)
	scene.call("_apply_release_first_go_firefight_deeplink", PackedStringArray([DEEPLINK_ARG]))
	await _wait_frames(160)
	var active_mission := scene.get("_active_mission") as Node
	var controller := active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	_assert(controller != null, "Release mission exposes TacticalController")
	if controller == null:
		scene.queue_free()
		return
	var simulation_root := active_mission.get_node_or_null("SimulationRoot")
	var combat_driver := active_mission.get_node_or_null("CombatLoopDriver")
	var terrain_view := active_mission.get_node_or_null("Primary3DView")
	controller.call("set_mission_visible_frame_timing_debug_enabled", true)
	if simulation_root != null and simulation_root.has_method("set_runtime_tick_budget_debug_enabled"):
		simulation_root.call("set_runtime_tick_budget_debug_enabled", true)
	if combat_driver != null and combat_driver.has_method("set_combat_tick_budget_debug_enabled"):
		combat_driver.call("set_combat_tick_budget_debug_enabled", true)
	if terrain_view != null and terrain_view.has_method("set_runtime_frame_timing_debug_enabled"):
		terrain_view.call("set_runtime_frame_timing_debug_enabled", true)

	# Exercise the same repeated read/update pressure that the real capture window receives.
	for _index in range(2):
		controller.call("_update_ui")
		controller.call("_refresh_world_overlays")
		await _wait_frames(12)

	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var source: Dictionary = Dictionary(controller.call("get_release_first_exchange_visible_status_source_reconciliation_snapshot"))
	var event_log: Dictionary = Dictionary(feedback.get("release_firefight_event_log_display", {}))
	var selected_text := String(feedback.get("selected_fireteam_status_label_text", "")).strip_edges()
	var mission_text := String(feedback.get("mission_control_status_text", "")).strip_edges()
	var event_entries: Array = Array(event_log.get("entries", []))
	print("TASK_1085_TIMING controller=%s" % JSON.stringify(controller.call("get_mission_visible_frame_timing_debug_snapshot")))
	print("TASK_1085_TIMING ui_refresh=%s" % JSON.stringify(controller.call("get_mission_ui_refresh_timing_debug_snapshot")))
	print("TASK_1085_TIMING runtime_surfaces=%s" % JSON.stringify(controller.call("get_mission_runtime_surface_timing_debug_snapshot")))
	if simulation_root != null and simulation_root.has_method("get_runtime_tick_budget_debug_snapshot"):
		print("TASK_1085_TIMING simulation=%s" % JSON.stringify(simulation_root.call("get_runtime_tick_budget_debug_snapshot")))
	if combat_driver != null and combat_driver.has_method("get_combat_tick_budget_debug_snapshot"):
		print("TASK_1085_TIMING combat=%s" % JSON.stringify(combat_driver.call("get_combat_tick_budget_debug_snapshot")))
	if terrain_view != null and terrain_view.has_method("get_runtime_frame_timing_debug_snapshot"):
		print("TASK_1085_TIMING terrain=%s" % JSON.stringify(terrain_view.call("get_runtime_frame_timing_debug_snapshot")))

	_assert(bool(source.get("active", false)), "Read-only first-exchange source remains active after repeated refreshes")
	_assert(selected_text.to_upper().begins_with("CONTACT FIRE"), "Selected Fireteam still starts with CONTACT FIRE: %s" % selected_text)
	_assert(mission_text.to_upper().begins_with("CONTACT FIRE"), "Mission Control still starts with CONTACT FIRE: %s" % mission_text)
	_assert(not selected_text.contains("player_") and not selected_text.contains("ground_"), "Primary fire line hides technical runtime ids")
	_assert(selected_text.contains("FT1 ->"), "Primary fire line names the player Fireteam")
	_assert(_entries_contain_contact_fire(event_entries), "Event Log retains CONTACT FIRE after repeated refreshes")
	_assert(not bool(source.get("ui_sets_gameplay_truth", true)), "Stable status source remains read-only")
	_assert(not String(Dictionary(source.get("status_source", {})).get("fire_event_id", "")).is_empty(), "Stable status source references a real FireEvent")
	var ui_timing: Dictionary = Dictionary(controller.call("get_mission_ui_refresh_timing_debug_snapshot"))
	var ui_scopes: Dictionary = Dictionary(ui_timing.get("scopes_usec", {}))
	_assert(int(ui_scopes.get("secondary_release_sync_usec", 999999)) < 12000, "First-exchange label sync avoids the redundant full status rebuild")

	scene.queue_free()
	await _wait_frames(2)


func _entries_contain_contact_fire(entries: Array) -> bool:
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("short_text", "")).to_upper().contains("CONTACT FIRE"):
			return true
	return false


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
