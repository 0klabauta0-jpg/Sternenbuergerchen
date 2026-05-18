extends SceneTree

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const MISSION_COMBAT_LOOP_DRIVER_SCRIPT: GDScript = preload("res://scripts/tests/mission_combat_loop_driver.gd")
const NPC_COMPACT_CARD_SCENE: PackedScene = preload("res://scenes/meta/components/npc_compact_card.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_472_fireteam_contact_perf_bubble_card_readability.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_472 Fireteam Contact Perf Bubble Card Readability ===")
	await _test_hud_bubble_and_tactical_event_visuals_are_capped()
	await _test_selected_member_card_wraps_downward_without_widening()
	_test_flank_vulnerability_is_disabled_for_drill_baseline()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_hud_bubble_and_tactical_event_visuals_are_capped() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task472_bubbles", Vector2i(6, 6), Vector2.ZERO, 64.0, 32.0, 2)
	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	view.call("set_order_visual_payload", {
		"feedback_bubble_dicts": [_make_hud_bubble("task472_b1", "MOVE Nord 8 Felder\nC Aim")],
	})
	await _wait_frames(6)
	view.call("set_order_visual_payload", {
		"feedback_bubble_dicts": [_make_hud_bubble("task472_b2", "ENGAGE Suedost 12\nFeuer frei")],
		"tactical_communication_event_dicts": _make_tactical_events(8),
	})
	await _wait_frames(6)
	var hud_root := view.get_node_or_null("FeedbackBubbleHudRoot") as Control
	var snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	_assert(hud_root != null and hud_root.get_child_count() == 1, "Dynamic refresh keeps exactly one HUD leader bubble")
	_assert(int(snapshot.get("feedback_bubble_visual_count", 0)) == 1, "Feedback bubble snapshot remains singular")
	_assert(int(snapshot.get("tactical_communication_event_visual_count", 0)) == 4, "Tactical communication markers render only the newest capped entries")
	view.queue_free()
	await _wait_frames(2)


func _test_selected_member_card_wraps_downward_without_widening() -> void:
	var card = NPC_COMPACT_CARD_SCENE.instantiate()
	root.add_child(card)
	card.custom_minimum_size = Vector2(156.0, 118.0)
	card.call(
		"setup_from_profile",
		{
			"unit_id": "task472_alpha",
			"display_name": "Task Alpha",
			"role_name": "Engage | Feuer frei | vorsichtig | COV 18",
			"secondary_text": "Aim up | Bewegung: Kampf | Aim 75%\nZiel enemy_01 | gesehen\nA:0.7 S:0.5 L:0.8 T:C",
		},
		{
			"source_context": "mission_selected_fireteam_member",
			"compact_mode": true,
			"drag_enabled": false,
			"show_lead_indicator": true,
			"is_lead": true,
			"selected": true,
			"fixed_size": true,
			"fixed_card_size": Vector2(156.0, 118.0),
			"compact_wrap_text": true,
			"compact_data_a_max_lines": 2,
			"compact_data_b_max_lines": 4,
			"compact_text_min_width": 76.0,
		}
	)
	await _wait_frames(4)
	var data_a_label := card.get_node_or_null("Margin/HBox/TextVBox/DataALabel") as Label
	var data_b_label := card.get_node_or_null("Margin/HBox/TextVBox/DataBLabel") as Label
	_assert(card.custom_minimum_size.x == 156.0 and card.custom_minimum_size.y == 118.0, "Selected member card keeps width and grows downward")
	_assert(data_a_label != null and data_a_label.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART and data_a_label.max_lines_visible == 2, "Runtime line wraps within the compact card")
	_assert(data_b_label != null and data_b_label.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART and data_b_label.max_lines_visible == 4 and data_b_label.text.contains("Ziel enemy_01"), "Detail line shows wrapped contact explanation")
	card.queue_free()
	await _wait_frames(2)


func _test_flank_vulnerability_is_disabled_for_drill_baseline() -> void:
	var driver: Node = MISSION_COMBAT_LOOP_DRIVER_SCRIPT.new()
	_assert(not bool(driver.get("flank_vulnerability_enabled")), "Flank vulnerability is disabled by default for the current drill baseline")
	_assert(Array(driver.call("get_flank_vulnerability_snapshot")).is_empty(), "Disabled flank vulnerability exposes no visual state")
	_assert(Dictionary(driver.call("get_fireteam_flank_vulnerability_state", "drill")).is_empty(), "Disabled flank vulnerability exposes no fireteam flank status")
	_assert(Dictionary(driver.call("resolve_flank_attack_preview", null, null)).is_empty(), "Disabled flank vulnerability contributes no attack preview")
	driver.free()


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("TASK 472") and task_text.contains("Bubble Cleanup"), "TASK_472 task file exists")
	_assert(status_text.contains("TASK_472 - Fireteam Contact Performance Bubble Card Readability"), "Implementation status documents TASK_472")
	_assert(roadmap_text.contains("TASK_472 - Fireteam Contact Performance Bubble Card Readability"), "Roadmap lists TASK_472")


func _make_hud_bubble(bubble_id: String, text: String) -> Dictionary:
	return {
		"bubble_id": bubble_id,
		"display_type": "comic_bubble",
		"visual_only": true,
		"anchor_space": "hud",
		"hud_anchor_position": Vector2(320.0, 220.0),
		"anchor_position": Vector2(128.0, 128.0),
		"text": text,
		"max_size": Vector2i(150, 58),
	}


func _make_tactical_events(count: int) -> Array:
	var events: Array = []
	for index in range(count):
		events.append({
			"event_id": "task472_tac_%02d" % index,
			"event_type": "contact_fire",
			"channels": PackedStringArray(["map_marker"]),
			"anchor_position": Vector2(64.0 + float(index) * 8.0, 128.0),
			"short_text": "PIN %02d" % index,
			"visual_only": true,
		})
	return events


func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
