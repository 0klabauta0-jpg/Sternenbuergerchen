extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1127 Tactical Communication HUD Bubble Event Mini-Card Anchor Repair ===")
	root.size = Vector2i(1920, 1080)
	var mission: Node = MISSION_SCENE.instantiate()
	root.add_child(mission)
	for _frame in range(12):
		await process_frame
	var controller: Node = mission.get_node("TacticalController")
	var primary_view: Node = mission.get_node("Primary3DView")
	controller.call("create_area_order_for_fireteams_from_world_rect", PackedStringArray(["blue", "gold"]), Vector2(880.0, 880.0), Vector2(1020.0, 1000.0), "take")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue", "gold"]), false)
	controller.call("_refresh_order_visuals")
	for _frame in range(10):
		await process_frame
	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var events: Array = Array(feedback.get("tactical_communication_events", []))
	var bubbles: Array = Array(feedback.get("fireteamleader_feedback_bubbles", []))
	var render_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var entries: Array = Array(render_snapshot.get("feedback_bubble_entries", []))
	var bubble_settings: Dictionary = Dictionary(controller.call("get_fireteamleader_feedback_bubble_settings"))
	_assert(_has_event_bound_bubble(bubbles, events), "Current FTL bubbles retain a known Tactical Communication event ID")
	_assert(_event_bound_bubbles_have_mini_card_anchors(bubbles), "Event-bound FTL bubbles resolve to Fireteam mini-card HUD anchors")
	_assert(_event_bound_bubbles_have_mini_card_anchors(entries), "Primary3D renders event-bound bubbles at Fireteam mini-card HUD anchors")
	_assert(_has_fireteam_bubble(bubbles, "blue") and _has_fireteam_bubble(bubbles, "gold"), "BLUE and GOLD retain independent current FTL bubbles")
	_assert(bubbles.size() <= int(bubble_settings.get("max_active_bubbles_total", 4)), "Current FTL bubble count respects the configured total limit")
	mission.queue_free()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _has_event_bound_bubble(bubbles: Array, events: Array) -> bool:
	var event_ids: Dictionary = {}
	for event_variant in events:
		event_ids[String(Dictionary(event_variant).get("event_id", "")).strip_edges()] = true
	for bubble_variant in bubbles:
		var event_id: String = String(Dictionary(bubble_variant).get("tactical_communication_event_id", "")).strip_edges()
		if not event_id.is_empty() and event_ids.has(event_id):
			return true
	return false


func _event_bound_bubbles_have_mini_card_anchors(bubbles: Array) -> bool:
	var checked: int = 0
	for bubble_variant in bubbles:
		var bubble: Dictionary = Dictionary(bubble_variant)
		if String(bubble.get("tactical_communication_event_id", "")).strip_edges().is_empty():
			continue
		checked += 1
		if String(bubble.get("anchor_space", "")) != "hud" or String(bubble.get("hud_anchor_source", "")) != "fireteam_mini_card" or typeof(bubble.get("hud_anchor_position", null)) != TYPE_VECTOR2:
			return false
	return checked > 0


func _has_fireteam_bubble(bubbles: Array, fireteam_id: String) -> bool:
	for bubble_variant in bubbles:
		if String(Dictionary(bubble_variant).get("fireteam_id", "")).strip_edges().to_lower() == fireteam_id:
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
