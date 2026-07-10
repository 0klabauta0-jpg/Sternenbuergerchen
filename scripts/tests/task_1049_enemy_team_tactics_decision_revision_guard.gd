extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const COMBAT_SOURCE_PATH: String = "res://scripts/tests/mission_combat_loop_driver.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1049 Enemy Team Tactics Decision Revision Guard ===")
	_test_guard_contract_is_present()
	await _test_identical_inputs_skip_and_visible_change_rebuilds()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_guard_contract_is_present() -> void:
	var source: String = FileAccess.get_file_as_string(COMBAT_SOURCE_PATH)
	_assert(source.contains("func get_enemy_team_tactics_runtime_guard_snapshot() -> Dictionary:"), "Combat driver exposes tactics revision guard diagnostics")
	_assert(source.contains("_build_enemy_team_tactics_input_signature"), "Tactics guard fingerprints decision inputs")


func _test_identical_inputs_skip_and_visible_change_rebuilds() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var combat: Node = scene.get_node_or_null("CombatLoopDriver")
	var friendly_units: Array = Array(combat.call("_get_friendly_combat_units")) if combat != null else []
	var friendly: Node2D = friendly_units[0] as Node2D if not friendly_units.is_empty() else null
	_assert(combat != null and friendly != null, "Mission fixture exposes combat driver and friendly decision input")
	if combat == null or friendly == null:
		scene.queue_free()
		return
	combat.call("_update_enemy_team_tactics_state")
	var before: Dictionary = Dictionary(combat.call("get_enemy_team_tactics_runtime_guard_snapshot"))
	combat.call("_update_enemy_team_tactics_state")
	var unchanged: Dictionary = Dictionary(combat.call("get_enemy_team_tactics_runtime_guard_snapshot"))
	_assert(int(unchanged.get("skip_count", 0)) > int(before.get("skip_count", 0)), "Identical enemy tactics inputs skip repeated cover and LOS decisions")
	var original_position: Vector2 = friendly.global_position
	friendly.global_position += Vector2(48.0, 0.0)
	combat.call("_update_enemy_team_tactics_state")
	var changed: Dictionary = Dictionary(combat.call("get_enemy_team_tactics_runtime_guard_snapshot"))
	_assert(int(changed.get("rebuild_count", 0)) > int(unchanged.get("rebuild_count", 0)), "Friendly movement rebuilds enemy tactics immediately")
	_assert(bool(changed.get("read_only_diagnostics", false)) and not bool(changed.get("sets_gameplay_truth", true)), "Tactics guard diagnostics do not own gameplay truth")
	friendly.global_position = original_position
	scene.queue_free()
	await _wait_frames(2)


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
