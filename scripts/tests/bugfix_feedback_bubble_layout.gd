extends SceneTree

const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== Feedback Bubble Layout Bugfix ===")
	await _test_hud_bubbles_are_compact_left_tailed_and_deduplicated()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_hud_bubbles_are_compact_left_tailed_and_deduplicated() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "bugfix_bubble_layout", Vector2i(6, 6), Vector2.ZERO, 64.0, 32.0, 3)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)

	var thought_bubble: Dictionary = _build_hud_bubble("thought_cloud", "Hold", "npc_thought", "npc_thought", 10)
	var command_bubble: Dictionary = _build_hud_bubble("command_rect", "Go", "fireteamleader_command_feedback", "command_feedback", 30)
	primary_view.call("set_order_visual_payload", {
		"phase_index": 1,
		"feedback_bubble_dicts": [thought_bubble, command_bubble],
	})
	await _wait_frames(8)

	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var entries: Array = Array(snapshot.get("feedback_bubble_entries", []))
	_assert(entries.size() == 1, "Overlapping cloud/command bubbles collapse to one readable HUD bubble")
	if entries.size() == 1:
		var entry: Dictionary = Dictionary(entries[0])
		var bubble_size: Vector2 = Vector2(entry.get("hud_bubble_size", Vector2.ZERO))
		_assert(String(entry.get("bubble_id", "")) == "command_rect", "Command bubble wins over thought bubble at the same fireteam anchor")
		_assert(String(entry.get("hud_tail_side", "")) == "left" and bool(entry.get("hud_tail_points_to_anchor", false)), "HUD bubble tail points left back to the fireteam card")
		_assert(bubble_size.x <= 110.0 and bubble_size.y <= 40.0, "Short HUD bubble text uses compact dimensions")

	primary_view.queue_free()
	await _wait_frames(2)


func _build_hud_bubble(bubble_id: String, text: String, source: String, purpose: String, priority: int) -> Dictionary:
	return {
		"display_type": "comic_bubble",
		"bubble_id": bubble_id,
		"text": text,
		"anchor_position": Vector2(128.0, 128.0),
		"anchor_space": "hud",
		"hud_anchor_source": "fireteam_mini_card",
		"hud_anchor_position": Vector2(280.0, 180.0),
		"max_size": Vector2i(148, 52),
		"visual_only": true,
		"source": source,
		"purpose": purpose,
		"category": source,
		"fireteam_id": "ft1",
		"unit_id": "unit_alpha",
		"priority": priority,
	}


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
