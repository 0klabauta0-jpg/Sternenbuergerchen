extends SceneTree

const FTL_READINESS_CONTRACT_SCRIPT: GDScript = preload("res://scripts/tactical/ftl_readiness_snapshot_contract.gd")
const FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_behavior_resolver.gd")
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_367 FTL Public Readiness Snapshot Contract ===")
	_test_contract_normalizes_public_snapshot()
	_test_missing_data_is_explicitly_unavailable()
	await _test_mission_controller_readiness_snapshot_is_read_only()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_contract_normalizes_public_snapshot() -> void:
	var tactical_snapshot: Dictionary = Dictionary(FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call("build_leader_tactical_skill_snapshot", {
		"unit_id": "unit_alpha",
		"display_name": "Mara Voss",
		"fireteam_id": "blue",
		"skill_values": {"leadership": 0.82, "discipline": 0.78, "awareness": 0.74, "recognition": 0.70},
		"communication_values": {"speech_quality": 0.80},
		"behavior_axes": {"initiative": 0.76, "contact_stability": 0.72},
		"progression": {"morale": 0.68, "frustration": 0.10, "ftl_tactical": {"missions_led": 5}},
	}, {"fireteam_id": "blue", "team_cohesion": 0.72}))
	var public_snapshot: Dictionary = Dictionary(FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call("build_public_leader_tactical_snapshot", tactical_snapshot))
	public_snapshot["reaction_delay_seconds"] = -5.0
	public_snapshot["plan_quality"] = 5.0
	public_snapshot["morale"] = 2.0
	var snapshot: Dictionary = Dictionary(FTL_READINESS_CONTRACT_SCRIPT.call("build_snapshot", "blue", {
		"unit_id": "unit_alpha",
		"display_name": "Mara Voss",
	}, {
		"execution_label": "CLEAN EXEC",
		"metadata": {"ftl_public_snapshot": public_snapshot},
	}))
	_assert(String(snapshot.get("fireteam_id", "")) == "blue", "Snapshot carries normalized fireteam id")
	_assert(String(snapshot.get("leader_name", "")) == "Mara Voss", "Snapshot carries leader display name")
	_assert(float(snapshot.get("reaction_delay_seconds", 0.0)) == FTL_READINESS_CONTRACT_SCRIPT.MIN_REACTION_DELAY_SECONDS, "Reaction delay clamps to documented lower bound")
	_assert(float(snapshot.get("plan_quality", 0.0)) == 1.0, "Plan quality clamps to 0..1")
	_assert(float(snapshot.get("morale", 0.0)) == 1.0, "Morale clamps to 0..1")
	_assert(String(snapshot.get("execution_label", "")) == "CLEAN EXEC", "Snapshot exposes execution label")
	_assert(bool(snapshot.get("read_only", false)), "Snapshot is marked read-only")
	_assert(not _contains_object_reference(snapshot), "Snapshot contains no Node/Object references")
	var ranges: Dictionary = Dictionary(FTL_READINESS_CONTRACT_SCRIPT.call("get_value_ranges"))
	_assert(Dictionary(ranges.get("reaction_delay_seconds", {})).has("lower_is_better"), "Reaction range documents lower-is-better")


func _test_missing_data_is_explicitly_unavailable() -> void:
	var snapshot: Dictionary = Dictionary(FTL_READINESS_CONTRACT_SCRIPT.call("build_snapshot", "ghost", null, {}, {}))
	_assert(String(snapshot.get("leader_name", "")) == "UNKNOWN FTL", "Missing leader gets explicit fallback label")
	_assert(not bool(snapshot.get("leader_available", true)), "Missing leader is marked unavailable")
	_assert(not bool(snapshot.get("ftl_data_available", true)), "Missing FTL data is marked unavailable")
	_assert(not bool(snapshot.get("reaction_delay_seconds_available", true)), "Missing reaction is marked unavailable")
	_assert(snapshot.get("reaction_delay_seconds", 0.0) == null, "Missing reaction does not become a fake midpoint")
	_assert(String(snapshot.get("unavailable_reason", "")).contains("missing_"), "Unavailable reason is explicit")
	_assert(not _contains_object_reference(snapshot), "Unavailable snapshot contains no Node/Object references")


func _test_mission_controller_readiness_snapshot_is_read_only() -> void:
	var scene = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var controller: Node = scene.get_node_or_null("TacticalController")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and simulation_root != null, "Mission scene exposes controller and SimulationRoot")
	if controller == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	controller.call("_set_selected_fireteams", PackedStringArray(["blue", "gold"]), false)
	controller.call("create_area_order_for_fireteams_from_world_rect", PackedStringArray(["blue", "gold"]), Vector2(880.0, 860.0), Vector2(1040.0, 980.0), "take")
	await _wait_frames(8)
	var command_count_before: int = simulation_root.command_queue.size()
	var effect_count_before: int = simulation_root.effects_queue.size()
	var entries: Array = Array(controller.call("get_ftl_readiness_snapshot"))
	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(entries.size() >= 2, "Mission controller exposes readiness snapshots for at least two fireteams")
	_assert(int(feedback.get("ftl_readiness_count", 0)) >= 2, "Command feedback mirrors readiness snapshot count")
	_assert(_has_available_readiness(entries, "blue"), "Blue readiness exposes available FTL values")
	_assert(_has_available_readiness(entries, "gold"), "Gold readiness exposes available FTL values")
	_assert(not _contains_object_reference(entries), "Mission readiness snapshots contain no Node/Object references")
	_assert(simulation_root.command_queue.size() == command_count_before, "Readiness snapshot enqueues no SimulationRoot commands")
	_assert(simulation_root.effects_queue.size() == effect_count_before, "Readiness snapshot enqueues no SimulationRoot effects")
	scene.queue_free()
	await _wait_frames(2)


func _has_available_readiness(entries: Array, fireteam_id: String) -> bool:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("fireteam_id", "")) != normalized_fireteam_id:
			continue
		return bool(entry.get("leader_available", false)) \
			and bool(entry.get("reaction_delay_seconds_available", false)) \
			and bool(entry.get("morale_available", false)) \
			and bool(entry.get("plan_quality_available", false))
	return false


func _contains_object_reference(value) -> bool:
	if value is Object:
		return true
	if typeof(value) == TYPE_DICTIONARY:
		for item in Dictionary(value).values():
			if _contains_object_reference(item):
				return true
	elif typeof(value) == TYPE_ARRAY:
		for item in Array(value):
			if _contains_object_reference(item):
				return true
	return false


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
