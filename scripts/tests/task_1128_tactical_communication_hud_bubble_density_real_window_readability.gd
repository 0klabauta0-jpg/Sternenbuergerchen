extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const CAPTURE_PATH := "res://tmp/task_1128_tactical_communication_hud_bubble_density.png"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1128 Tactical Communication HUD Bubble Density Real-Window Readability ===")
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
	var entries: Array = _event_bound_hud_entries(Array(Dictionary(primary_view.call("get_render_snapshot")).get("feedback_bubble_entries", [])))
	var by_fireteam: Dictionary = _entries_by_fireteam(entries)
	_assert(entries.size() == 2, "FullHD mission renders exactly two event-bound Fireteam HUD bubbles")
	_assert(by_fireteam.has("blue") and by_fireteam.has("gold"), "BLUE and GOLD each retain one visible HUD bubble")
	_assert(_entries_reference_distinct_known_events(entries, events), "Visible bubbles retain distinct known Tactical Communication event IDs")
	_assert(_entries_stay_inside_viewport(entries, Rect2(Vector2.ZERO, Vector2(root.size))), "Every Fireteam bubble stays fully inside the FullHD viewport")
	_assert(_entries_have_clear_spacing(entries, 6.0), "Simultaneous Fireteam bubbles keep a visible safety gap")
	_assert(_entries_stay_nearest_their_own_anchor(by_fireteam), "Each bubble remains nearest its own Fireteam mini-card anchor")
	_assert(_entries_keep_left_tail_contract(entries), "Every Bubble tail points left toward its Fireteam mini-card")

	if OS.get_environment("STERNEN_TASK1128_CAPTURE") == "1":
		RenderingServer.force_draw(true)
		await process_frame
		var image: Image = root.get_texture().get_image()
		var error: Error = image.save_png(CAPTURE_PATH) if image != null else ERR_CANT_CREATE
		_assert(image != null and image.get_width() == 1920 and image.get_height() == 1080 and error == OK, "Real-window run writes a valid FullHD HUD bubble capture")

	mission.queue_free()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _event_bound_hud_entries(entries: Array) -> Array:
	var result: Array = []
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("anchor_space", "")) != "hud":
			continue
		if String(entry.get("hud_anchor_source", "")) != "fireteam_mini_card":
			continue
		if String(entry.get("tactical_communication_event_id", "")).strip_edges().is_empty():
			continue
		result.append(entry)
	return result


func _entries_by_fireteam(entries: Array) -> Dictionary:
	var result: Dictionary = {}
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		result[String(entry.get("fireteam_id", "")).strip_edges().to_lower()] = entry
	return result


func _entries_reference_distinct_known_events(entries: Array, events: Array) -> bool:
	var known_ids: Dictionary = {}
	for event_variant in events:
		known_ids[String(Dictionary(event_variant).get("event_id", "")).strip_edges()] = true
	var visible_ids: Dictionary = {}
	for entry_variant in entries:
		var event_id: String = String(Dictionary(entry_variant).get("tactical_communication_event_id", "")).strip_edges()
		if not known_ids.has(event_id):
			return false
		visible_ids[event_id] = true
	return visible_ids.size() == entries.size()


func _entries_stay_inside_viewport(entries: Array, viewport_rect: Rect2) -> bool:
	for entry_variant in entries:
		if not viewport_rect.encloses(_entry_rect(Dictionary(entry_variant))):
			return false
	return not entries.is_empty()


func _entries_have_clear_spacing(entries: Array, gap: float) -> bool:
	for first_index in range(entries.size()):
		for second_index in range(first_index + 1, entries.size()):
			if _entry_rect(Dictionary(entries[first_index])).grow(gap * 0.5).intersects(_entry_rect(Dictionary(entries[second_index])).grow(gap * 0.5)):
				return false
	return entries.size() > 1


func _entries_stay_nearest_their_own_anchor(by_fireteam: Dictionary) -> bool:
	if not by_fireteam.has("blue") or not by_fireteam.has("gold"):
		return false
	var blue: Dictionary = Dictionary(by_fireteam["blue"])
	var gold: Dictionary = Dictionary(by_fireteam["gold"])
	return _entry_center(blue).distance_to(Vector2(blue.get("hud_anchor_position", Vector2.ZERO))) < _entry_center(blue).distance_to(Vector2(gold.get("hud_anchor_position", Vector2.ZERO))) \
		and _entry_center(gold).distance_to(Vector2(gold.get("hud_anchor_position", Vector2.ZERO))) < _entry_center(gold).distance_to(Vector2(blue.get("hud_anchor_position", Vector2.ZERO)))


func _entries_keep_left_tail_contract(entries: Array) -> bool:
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("hud_tail_side", "")) != "left" or not bool(entry.get("hud_tail_points_to_anchor", false)):
			return false
		if float(Vector2(entry.get("hud_bubble_position", Vector2.ZERO)).x) < float(Vector2(entry.get("hud_anchor_position", Vector2.ZERO)).x):
			return false
	return not entries.is_empty()


func _entry_rect(entry: Dictionary) -> Rect2:
	return Rect2(Vector2(entry.get("hud_bubble_position", Vector2.ZERO)), Vector2(entry.get("hud_bubble_size", Vector2.ZERO)))


func _entry_center(entry: Dictionary) -> Vector2:
	return _entry_rect(entry).get_center()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
