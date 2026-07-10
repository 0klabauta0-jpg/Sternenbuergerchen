extends SceneTree

const META_SCENE_PATH := "res://scenes/meta/meta_layer_test.tscn"
const META_SCRIPT_PATH := "res://scripts/meta/meta_layer_flow.gd"
const LZ_DEEPLINK_ARG := "--release-singleplayer-lz-drop-preview"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1087 Release Mission/LZ Setup Readiness Pass ===")
	_test_setup_trace_and_wait_contract()
	await _test_integrated_lz_handoff_and_preview()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_setup_trace_and_wait_contract() -> void:
	var meta_text := FileAccess.get_file_as_string(META_SCRIPT_PATH)
	for stage in [
		"lz_setup_begin",
		"lz_mission_started",
		"lz_transfer_ready",
		"lz_placement_ready",
		"lz_deboard_ready",
		"lz_preview_ready",
	]:
		_assert(meta_text.contains('"%s"' % stage), "Setup trace contains %s" % stage)
	_assert(meta_text.contains("_wait_release_lz_setup_condition"), "LZ setup uses a bounded condition helper")
	var function_start := meta_text.find("func _apply_release_lz_drop_preview_deeplink")
	var function_end := meta_text.find("\nfunc _request_release_start_mission_from_homebase_for_deeplink", function_start)
	var function_text := meta_text.substr(function_start, function_end - function_start)
	_assert(not function_text.contains("_wait_release_deeplink_frames"), "LZ setup path contains no blind frame waits")
	var request_start := function_end + 1
	var request_end := meta_text.find("\nfunc _complete_release_lz_drop_preview_craft_arrival", request_start)
	var request_text := meta_text.substr(request_start, request_end - request_start)
	_assert(not request_text.contains("_wait_release_deeplink_frames"), "Release mission request contains no blind frame waits")
	var lz_to_go_blind_wait := "await _apply_release_lz_drop_preview_deeplink(PackedStringArray([RELEASE_SINGLEPLAYER_LZ_DROP_PREVIEW_DEEPLINK_ARG]))\n\tawait _wait_release_deeplink_frames(8)"
	_assert(not meta_text.contains(lz_to_go_blind_wait), "First-GO path does not add a blind wait after completed LZ setup")


func _test_integrated_lz_handoff_and_preview() -> void:
	root.size = Vector2i(1920, 1080)
	var packed := ResourceLoader.load(META_SCENE_PATH) as PackedScene
	var scene := packed.instantiate() if packed != null else null
	_assert(scene != null, "MetaLayer release scene instantiates")
	if scene == null:
		return
	root.add_child(scene)
	await _wait_frames(10)
	var started_msec := Time.get_ticks_msec()
	await scene.call("_apply_release_lz_drop_preview_deeplink", PackedStringArray([LZ_DEEPLINK_ARG]))
	var elapsed_msec := Time.get_ticks_msec() - started_msec
	var snapshot: Dictionary = Dictionary(scene.call("get_release_lz_drop_preview_deeplink_snapshot", PackedStringArray([LZ_DEEPLINK_ARG])))
	var handoff: Dictionary = Dictionary(scene.call("get_homebase_to_mission_handoff_snapshot"))
	var planning: Dictionary = Dictionary(handoff.get("planning", {}))
	print("TASK_1087_LZ elapsed_msec=%d status=%s reason=%s deployed=%d waypoints=%d" % [
		elapsed_msec,
		String(snapshot.get("status", "")),
		String(snapshot.get("reason", "")),
		int(snapshot.get("deployed_selected_unit_count", 0)),
		int(snapshot.get("planned_waypoint_count", 0)),
	])

	_assert(String(snapshot.get("status", "")) == "applied", "LZ deep-link reaches applied state")
	_assert(bool(snapshot.get("active_mission_exists", false)), "Homebase route keeps an active mission")
	_assert(not String(planning.get("mission_drop_craft_id", "")).is_empty(), "Dropship identity remains in planning state")
	_assert(int(snapshot.get("deployed_selected_unit_count", 0)) > 0, "Selected Fireteam is deboarded into mission runtime")
	_assert(int(snapshot.get("planned_waypoint_count", 0)) > 0, "Move preview remains planned")
	_assert(bool(snapshot.get("go_ready", false)), "Preview remains ready for explicit GO")
	_assert(bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true)), "LZ evidence snapshot stays read-only")
	_assert(elapsed_msec < 30000, "LZ setup remains below broad 30-second headless guard")

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
