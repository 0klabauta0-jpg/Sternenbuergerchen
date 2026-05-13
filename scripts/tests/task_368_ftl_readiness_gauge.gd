extends SceneTree

const GAUGE_SCRIPT: GDScript = preload("res://scripts/ui/ftl_readiness_gauge.gd")
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_368 FTL Readiness Gauge ===")
	await _test_gauge_high_medium_low_and_unavailable()
	await _test_mission_fireteam_card_embedding()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_gauge_high_medium_low_and_unavailable() -> void:
	var gauge: Control = GAUGE_SCRIPT.new()
	root.add_child(gauge)
	await _wait_frames(2)
	gauge.call("set_snapshot", _snapshot("blue", "High FTL", 0.12, 0.84, 0.86))
	await _wait_frames(2)
	var high: Dictionary = Dictionary(gauge.call("get_gauge_snapshot"))
	_assert(String(high.get("display_state", "")) == "high", "High readiness snapshot renders as high")
	_assert(float(high.get("reaction_ratio", 0.0)) > 0.80, "Fast reaction fills reaction bars")
	gauge.call("set_snapshot", _snapshot("gold", "Mid FTL", 0.40, 0.54, 0.52))
	await _wait_frames(2)
	var medium: Dictionary = Dictionary(gauge.call("get_gauge_snapshot"))
	_assert(String(medium.get("display_state", "")) == "medium", "Medium readiness snapshot renders as medium")
	gauge.call("set_snapshot", _snapshot("red", "Low FTL", 0.78, 0.24, 0.22))
	await _wait_frames(2)
	var low: Dictionary = Dictionary(gauge.call("get_gauge_snapshot"))
	_assert(String(low.get("display_state", "")) == "low", "Low readiness snapshot renders as low")
	gauge.call("set_snapshot", {
		"fireteam_id": "ghost",
		"leader_name": "UNKNOWN FTL",
		"reaction_delay_seconds_available": false,
		"morale_available": false,
		"plan_quality_available": false,
	})
	await _wait_frames(2)
	var unavailable: Dictionary = Dictionary(gauge.call("get_gauge_snapshot"))
	_assert(String(unavailable.get("display_state", "")) == "unavailable", "Unavailable readiness renders neutral state")
	_assert(unavailable.get("reaction_delay_seconds", 1.0) == null, "Unavailable reaction stays null in diagnostics")
	_assert(Vector2(unavailable.get("fixed_size", Vector2.ZERO)) == GAUGE_SCRIPT.DEFAULT_SIZE, "Gauge reports fixed compact dimensions")
	_assert(gauge.custom_minimum_size.y <= 38.0, "Gauge fixed height stays compact")
	gauge.queue_free()
	await _wait_frames(2)


func _test_mission_fireteam_card_embedding() -> void:
	root.size = Vector2i(1920, 1080)
	var scene = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var controller: Node = scene.get_node_or_null("TacticalController")
	var card_list: Node = scene.get_node_or_null("TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox")
	_assert(controller != null and card_list != null, "Mission scene exposes controller and fireteam mini cards")
	if controller == null or card_list == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	controller.call("_set_selected_fireteams", PackedStringArray(["blue", "gold"]), false)
	controller.call("create_area_order_for_fireteams_from_world_rect", PackedStringArray(["blue", "gold"]), Vector2(880.0, 860.0), Vector2(1040.0, 980.0), "take")
	controller.call("_update_ui")
	await _wait_frames(8)
	var gauges: Array = _find_nodes_by_name(card_list, "FTLReadinessGauge")
	_assert(gauges.size() >= 2, "Fireteam mini cards embed readiness gauges")
	var first_gauge := gauges[0] as Control
	var gauge_snapshot: Dictionary = Dictionary(first_gauge.call("get_gauge_snapshot")) if first_gauge != null else {}
	_assert(not gauge_snapshot.is_empty() and String(gauge_snapshot.get("display_state", "")).strip_edges() != "unavailable", "Embedded gauge receives available readiness data")
	_assert(first_gauge != null and first_gauge.custom_minimum_size == GAUGE_SCRIPT.DEFAULT_SIZE, "Embedded gauge keeps fixed dimensions")
	_assert(_mini_cards_stay_compact(card_list), "Gauge embedding does not grow mini cards beyond compact height")
	scene.queue_free()
	await _wait_frames(2)


func _snapshot(fireteam_id: String, leader_name: String, reaction_delay: float, morale: float, plan_quality: float) -> Dictionary:
	return {
		"fireteam_id": fireteam_id,
		"leader_name": leader_name,
		"reaction_delay_seconds": reaction_delay,
		"reaction_delay_seconds_available": true,
		"morale": morale,
		"morale_available": true,
		"plan_quality": plan_quality,
		"plan_quality_available": true,
		"read_only": true,
	}


func _find_nodes_by_name(root_node: Node, node_name: String) -> Array:
	var result: Array = []
	if root_node == null:
		return result
	if root_node.name == node_name:
		result.append(root_node)
	for child in root_node.get_children():
		result.append_array(_find_nodes_by_name(child, node_name))
	return result


func _mini_cards_stay_compact(card_list: Node) -> bool:
	for child in card_list.get_children():
		var control := child as Control
		if control == null or not control.visible:
			continue
		if control.size.y > 92.0:
			return false
	return true


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
