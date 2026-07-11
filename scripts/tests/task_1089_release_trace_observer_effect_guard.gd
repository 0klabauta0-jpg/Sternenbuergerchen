extends SceneTree

const META_SCENE_PATH := "res://scenes/meta/meta_layer_test.tscn"
const DEEPLINK_ARG := "--release-singleplayer-first-go-firefight"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1089 Release Trace Observer-Effect Guard ===")
	await _test_integrated_compact_release_trace()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_integrated_compact_release_trace() -> void:
	root.size = Vector2i(1920, 1080)
	var packed := ResourceLoader.load(META_SCENE_PATH) as PackedScene
	var scene := packed.instantiate() if packed != null else null
	_assert(scene != null, "MetaLayer release scene instantiates")
	if scene == null:
		return
	root.add_child(scene)
	await _wait_frames(10)
	var env_name := "STERNENBUERGERCHEN_RELEASE_FIRST_EXCHANGE_TRACE_PATH"
	var previous_path := OS.get_environment(env_name)
	OS.set_environment(env_name, "user://task1089_release_trace.json")
	await scene.call("_apply_release_first_go_firefight_deeplink", PackedStringArray([DEEPLINK_ARG]))
	if previous_path.is_empty():
		OS.unset_environment(env_name)
	else:
		OS.set_environment(env_name, previous_path)
	var samples: Array = Array(scene.get("_release_first_exchange_exported_status_trace_samples"))
	var final_sample := _find_stage(samples, "deeplink_final")
	var controller_snapshot_count := 0
	for sample_variant in samples:
		if bool(Dictionary(sample_variant).get("controller_present", false)):
			controller_snapshot_count += 1
	var active_mission := scene.get("_active_mission") as Node
	var controller := active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var source: Dictionary = Dictionary(controller.call("get_release_first_exchange_visible_status_source_reconciliation_snapshot")) if controller != null else {}
	var status_source: Dictionary = Dictionary(source.get("status_source", {}))

	_assert(String(final_sample.get("deeplink_status", "")) == "applied", "Final trace remains applied")
	_assert(controller_snapshot_count <= 1, "Successful trace reads at most one full controller snapshot")
	_assert(bool(final_sample.get("selected_starts_contact_fire", false)), "Final selected Fireteam starts with CONTACT FIRE")
	_assert(bool(final_sample.get("mission_starts_contact_fire", false)), "Final Mission Control starts with CONTACT FIRE")
	_assert(bool(final_sample.get("event_log_contains_contact_fire", false)), "Final Event Log contains CONTACT FIRE")
	_assert(not String(status_source.get("fire_event_id", "")).is_empty(), "Final source references a real FireEvent")
	_assert(not bool(source.get("ui_sets_gameplay_truth", true)), "Trace path remains read-only")

	scene.queue_free()
	await _wait_frames(2)


func _find_stage(samples: Array, stage_name: String) -> Dictionary:
	for sample_variant in samples:
		var sample: Dictionary = Dictionary(sample_variant)
		if String(sample.get("stage", "")) == stage_name:
			return sample
	return {}


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
