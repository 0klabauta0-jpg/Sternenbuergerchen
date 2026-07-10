extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_1084_release_deeplink_runtime_authority_repair.md"
const META_LAYER_PATH := "res://scripts/meta/meta_layer_flow.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const META_SCENE_PATH := "res://scenes/meta/meta_layer_test.tscn"
const DEEPLINK_ARG := "--release-singleplayer-first-go-firefight"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1084 Release Deep-Link Runtime Authority Repair ===")
	_test_static_authority_boundary()
	await _test_release_deeplink_regression()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_static_authority_boundary() -> void:
	var task_text := _read_text(TASK_PATH)
	var meta_text := _read_text(META_LAYER_PATH)
	var controller_text := _read_text(CONTROLLER_PATH)
	_assert(task_text.contains("Release Deep-Link Runtime Authority Repair"), "TASK_1084 contract exists")
	_assert(not meta_text.contains("set_runtime_status"), "MetaLayer contains no direct runtime-status mutation")
	_assert(not meta_text.contains("assign_unit_command"), "MetaLayer contains no direct unit-command assignment")
	_assert(meta_text.contains("queue_release_first_exchange_hold_command"), "MetaLayer delegates release setup to mission runtime gateway")
	_assert(meta_text.contains("await get_tree().physics_frame"), "Deep-link waits for authoritative command tick")
	_assert(controller_text.contains("func queue_release_first_exchange_hold_command"), "Mission controller exposes bounded release setup gateway")
	_assert(controller_text.contains("simulation_root.call(\"enqueue_command\", command.to_dict())"), "Mission runtime gateway enqueues through SimulationRoot")


func _test_release_deeplink_regression() -> void:
	root.size = Vector2i(1920, 1080)
	var packed := ResourceLoader.load(META_SCENE_PATH) as PackedScene
	var scene := packed.instantiate() if packed != null else null
	_assert(scene != null, "MetaLayer release scene instantiates")
	if scene == null:
		return
	root.add_child(scene)
	await _wait_frames(10)
	await scene.call("_apply_release_first_go_firefight_deeplink", PackedStringArray([DEEPLINK_ARG]))
	var snapshot: Dictionary = Dictionary(scene.call("get_release_first_go_firefight_deeplink_snapshot", PackedStringArray([DEEPLINK_ARG])))
	_assert(bool(snapshot.get("applied", false)), "First GO/firefight deep-link still applies")
	_assert(String(snapshot.get("firefight_status", "")) == "pass", "First firefight remains actionable")
	_assert(String(snapshot.get("execution_gate", "")) == "pass", "Execution gate remains green")
	_assert(String(snapshot.get("engagement_gate", "")) == "pass", "Engagement gate remains green")
	scene.queue_free()
	await _wait_frames(2)


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _read_text(path: String) -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
