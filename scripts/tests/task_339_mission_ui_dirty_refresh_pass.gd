extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_339_mission_ui_dirty_refresh_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTROLLER_PATH: String = "res://scripts/mission/mission_tactical_sandbox_controller.gd"
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const SELECTED_CARDS_ROW_PATH: String = "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll/FireteamCardsBody/FireteamCardsRow"
const MINI_CARDS_HOST_PATH: String = "TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox"
const MISSION_DROPSHIP_PANEL_PATH: String = "TacticalUI/MissionDropshipPanel"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_339 Mission UI Dirty Refresh Pass ===")
	_test_docs_and_static_contract()
	await _test_mission_ui_idle_skips_and_state_changes()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_docs_and_static_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "TASK_339 task file marks implemented")
	_assert(not task_text.contains("- [ ]"), "TASK_339 checklist has no unchecked item")
	_assert(status_text.contains("### TASK_339 - Mission UI Dirty Refresh Pass") and status_text.contains("- Status: implementiert"), "Implementation status marks TASK_339 implemented")
	_assert(roadmap_text.contains("TASK_339 - Mission UI Dirty Refresh Pass (implementiert"), "Roadmap marks TASK_339 implemented")
	for token in [
		"get_mission_ui_dirty_refresh_snapshot",
		"_build_selected_fireteam_cards_signature",
		"_build_fireteam_mini_cards_signature",
		"_build_mission_dropship_panel_signature",
		"_record_mission_ui_dirty_skip",
		"_record_mission_ui_dirty_rebuild",
		"MISSION_UI_DIRTY_BUCKET_DROPSHIP_PANEL",
	]:
		_assert(controller_text.contains(token), "Controller dirty-refresh contract contains %s" % token)


func _test_mission_ui_idle_skips_and_state_changes() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(16)

	var controller := scene.get_node_or_null("TacticalController")
	var simulation_root := scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and simulation_root != null, "Mission scene exposes controller and SimulationRoot")
	if controller == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	await _wait_frames(4)
	var selected_row := scene.get_node_or_null(SELECTED_CARDS_ROW_PATH) as Control
	var mini_host := scene.get_node_or_null(MINI_CARDS_HOST_PATH) as Control
	_assert(selected_row != null and selected_row.get_child_count() > 0, "Selected fireteam cards build initial content")
	_assert(mini_host != null and mini_host.get_child_count() > 0, "Fireteam mini cards build initial content")
	var first_selected_card: Node = selected_row.get_child(0) if selected_row != null and selected_row.get_child_count() > 0 else null
	var first_mini_card: Node = mini_host.get_child(0) if mini_host != null and mini_host.get_child_count() > 0 else null

	var command_count_before: int = simulation_root.command_queue.size()
	var effect_count_before: int = simulation_root.effects_queue.size()
	var initial_snapshot: Dictionary = Dictionary(controller.call("get_mission_ui_dirty_refresh_snapshot"))
	_assert(not String(initial_snapshot.get("selected_fireteam_cards_signature", "")).is_empty(), "Selected fireteam cards expose a dirty signature")
	_assert(not String(initial_snapshot.get("fireteam_mini_cards_signature", "")).is_empty(), "Fireteam mini cards expose a dirty signature")
	_assert(not String(initial_snapshot.get("mission_dropship_panel_signature", "")).is_empty(), "Dropship panel exposes a dirty signature even while hidden")

	for _index in range(3):
		controller.call("_update_ui")
	var idle_snapshot: Dictionary = Dictionary(controller.call("get_mission_ui_dirty_refresh_snapshot"))
	_assert(_counter(idle_snapshot, "selected_fireteam_cards_rebuild_count") == _counter(initial_snapshot, "selected_fireteam_cards_rebuild_count"), "Selected card rebuild counter stays stable during idle refresh")
	_assert(_counter(idle_snapshot, "fireteam_mini_cards_rebuild_count") == _counter(initial_snapshot, "fireteam_mini_cards_rebuild_count"), "Mini-card rebuild counter stays stable during idle refresh")
	_assert(_counter(idle_snapshot, "mission_dropship_panel_rebuild_count") == _counter(initial_snapshot, "mission_dropship_panel_rebuild_count"), "Dropship panel rebuild counter stays stable during hidden idle refresh")
	_assert(_counter(idle_snapshot, "selected_fireteam_cards_skip_count") >= _counter(initial_snapshot, "selected_fireteam_cards_skip_count") + 3, "Selected cards count idle skips")
	_assert(_counter(idle_snapshot, "fireteam_mini_cards_skip_count") >= _counter(initial_snapshot, "fireteam_mini_cards_skip_count") + 3, "Mini cards count idle skips")
	_assert(_counter(idle_snapshot, "mission_dropship_panel_skip_count") >= _counter(initial_snapshot, "mission_dropship_panel_skip_count") + 3, "Dropship panel counts idle skips")
	_assert(first_selected_card != null and selected_row.get_child(0) == first_selected_card, "Selected card node is reused when the signature stays unchanged")
	_assert(first_mini_card != null and mini_host.get_child(0) == first_mini_card, "Mini-card node is reused when the signature stays unchanged")
	_assert(simulation_root.command_queue.size() == command_count_before, "Idle UI refresh enqueues no SimulationRoot commands")
	_assert(simulation_root.effects_queue.size() == effect_count_before, "Idle UI refresh enqueues no SimulationRoot effects")

	var selected_signature_before: String = String(idle_snapshot.get("selected_fireteam_cards_signature", ""))
	controller.call("_set_selected_fireteams", PackedStringArray(["gold"]), false)
	await _wait_frames(3)
	var selection_snapshot: Dictionary = Dictionary(controller.call("get_mission_ui_dirty_refresh_snapshot"))
	_assert(String(selection_snapshot.get("selected_fireteam_cards_signature", "")) != selected_signature_before, "Changing selected fireteam changes selected-card signature")
	_assert(_counter(selection_snapshot, "selected_fireteam_cards_rebuild_count") > _counter(idle_snapshot, "selected_fireteam_cards_rebuild_count"), "Changing selection rebuilds selected cards once")
	_assert(_counter(selection_snapshot, "fireteam_mini_cards_rebuild_count") > _counter(idle_snapshot, "fireteam_mini_cards_rebuild_count"), "Changing selection rebuilds mini cards for selected state")

	var after_selection_rebuilds: Dictionary = selection_snapshot.duplicate(true)
	for _index in range(2):
		controller.call("_update_ui")
	var after_selection_idle: Dictionary = Dictionary(controller.call("get_mission_ui_dirty_refresh_snapshot"))
	_assert(_counter(after_selection_idle, "selected_fireteam_cards_rebuild_count") == _counter(after_selection_rebuilds, "selected_fireteam_cards_rebuild_count"), "Selection state idles without repeated selected-card rebuilds")
	_assert(_counter(after_selection_idle, "fireteam_mini_cards_rebuild_count") == _counter(after_selection_rebuilds, "fireteam_mini_cards_rebuild_count"), "Selection state idles without repeated mini-card rebuilds")

	var dropship_before: Dictionary = Dictionary(controller.call("get_mission_ui_dirty_refresh_snapshot"))
	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	planning_state["mission_drop_craft_id"] = "dropship_339"
	planning_state["mission_drop_display_name"] = "Dropship 339"
	planning_state["mission_drop_title_text"] = "#19 Dropship 339"
	planning_state["mission_drop_state"] = "waiting"
	planning_state["mission_drop_pilot_display_name"] = "Ari Vale"
	planning_state["mission_drop_passenger_count"] = 2
	planning_state["has_lz_position"] = true
	planning_state["lz_position"] = Vector2(224.0, 144.0)
	planning_state["approach_angle"] = "NW"
	planning_state["mission_drop_cards"] = [
		{
			"craft_id": "dropship_339",
			"display_name": "Dropship 339",
			"title_text": "#19 Dropship 339",
			"state": "waiting",
			"pilot_display_name": "Ari Vale",
			"passenger_count": 2,
			"embarked_unit_ids": ["unit_alpha", "unit_bravo"],
			"boarded_fireteam_ids": ["blue"],
			"has_lz_position": true,
			"lz_position": Vector2(224.0, 144.0),
			"approach_angle": "NW",
		},
	]
	controller.call("set_planning_state", planning_state)
	await _wait_frames(4)
	var dropship_panel := scene.get_node_or_null(MISSION_DROPSHIP_PANEL_PATH) as Control
	var dropship_ready: Dictionary = Dictionary(controller.call("get_mission_ui_dirty_refresh_snapshot"))
	_assert(dropship_panel != null and dropship_panel.visible and dropship_panel.get_child_count() == 1, "Dropship panel renders a visible card for mission_drop_cards")
	_assert(_counter(dropship_ready, "mission_dropship_panel_rebuild_count") > _counter(dropship_before, "mission_dropship_panel_rebuild_count"), "Dropship card setup changes signature and rebuilds panel")

	var first_dropship_card: Node = dropship_panel.get_child(0) if dropship_panel != null and dropship_panel.get_child_count() > 0 else null
	for _index in range(2):
		controller.call("_update_ui")
	var dropship_idle: Dictionary = Dictionary(controller.call("get_mission_ui_dirty_refresh_snapshot"))
	_assert(_counter(dropship_idle, "mission_dropship_panel_rebuild_count") == _counter(dropship_ready, "mission_dropship_panel_rebuild_count"), "Visible dropship panel idles without repeated rebuilds")
	_assert(_counter(dropship_idle, "mission_dropship_panel_skip_count") >= _counter(dropship_ready, "mission_dropship_panel_skip_count") + 2, "Visible dropship panel counts idle skips")
	_assert(first_dropship_card != null and dropship_panel.get_child(0) == first_dropship_card, "Dropship card node is reused while its signature stays unchanged")

	var dropship_signature_before: String = String(dropship_idle.get("mission_dropship_panel_signature", ""))
	var changed_planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	var changed_cards: Array = Array(changed_planning_state.get("mission_drop_cards", []))
	if not changed_cards.is_empty():
		var changed_card: Dictionary = Dictionary(changed_cards[0]).duplicate(true)
		changed_card["passenger_count"] = 3
		changed_card["embarked_unit_ids"] = ["unit_alpha", "unit_bravo", "unit_charlie"]
		changed_card["lz_position"] = Vector2(640.0, 320.0)
		changed_card["approach_angle"] = "SE"
		changed_cards[0] = changed_card
	changed_planning_state["mission_drop_cards"] = changed_cards
	changed_planning_state["mission_drop_passenger_count"] = 3
	changed_planning_state["has_lz_position"] = true
	changed_planning_state["lz_position"] = Vector2(640.0, 320.0)
	changed_planning_state["approach_angle"] = "SE"
	controller.call("set_planning_state", changed_planning_state)
	await _wait_frames(4)
	var dropship_changed: Dictionary = Dictionary(controller.call("get_mission_ui_dirty_refresh_snapshot"))
	_assert(String(dropship_changed.get("mission_dropship_panel_signature", "")) != dropship_signature_before, "LZ, approach and payload changes alter the dropship signature")
	_assert(_counter(dropship_changed, "mission_dropship_panel_rebuild_count") > _counter(dropship_idle, "mission_dropship_panel_rebuild_count"), "Dropship LZ/payload change rebuilds the visible panel")
	_assert(dropship_panel != null and dropship_panel.visible and dropship_panel.get_child_count() == 1, "Dropship panel remains visible after LZ/payload update")

	scene.queue_free()
	await _wait_frames(2)


func _counter(snapshot: Dictionary, key: String) -> int:
	return int(snapshot.get(key, 0))


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("  FAIL: %s" % message)
