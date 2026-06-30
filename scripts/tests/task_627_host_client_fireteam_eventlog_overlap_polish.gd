extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/drop_light_layout_contract.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_627_host_client_fireteam_eventlog_overlap_polish.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const HANDBOOK_PATH: String = "res://docs/reports/project_status_handbook_2026_06_29.html"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const SCENE_PATH: String = "res://scenes/tests/mission_reactivity_test.tscn"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_627 Host Client Fireteam Eventlog Overlap Polish ===")
	_test_docs_reports_and_contract()
	await _test_mission_left_hud_regions_do_not_overlap()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_627: FAILED")
		quit(1)
		return
	print("TASK_627: ALL PASSED")
	quit(0)


func _test_docs_reports_and_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var scene_text: String = _read_text(SCENE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_627 task file exists")
	_assert(task_text.contains("Host Client Fireteam Eventlog Overlap Polish"), "TASK_627 task names overlap polish")
	_assert(status_text.contains("TASK_627 - Host Client Fireteam Eventlog Overlap Polish"), "Implementation status tracks TASK_627")
	_assert(roadmap_text.contains("TASK_627 - Host Client Fireteam Eventlog Overlap Polish (implementiert)"), "Roadmap marks TASK_627 implemented")
	_assert(contract_text.contains("Host-Client-Fireteam-Eventlog-Overlap-Polish"), "Mission feedback contract documents TASK_627")
	_assert(report_text.contains("TASK_627 Host Client Fireteam Eventlog Overlap Polish"), "Rolling report tracks TASK_627")
	_assert(report_text.contains('latest_completed_task: "TASK_633 - Frontier Probe Callout Layout Polish"'), "Rolling report advances latest completed beyond TASK_627")
	_assert(handbook_text.contains('current_task: "TASK_633 - Frontier Probe Callout Layout Polish"'), "Status handbook current task advances beyond TASK_627")
	_assert(controller_text.contains("_apply_fixed_hud_window_contract(TACTICAL_EVENT_LOG_PANEL_PATH, layout.get(\"event_log\"))"), "Controller applies event log from layout contract")
	_assert(scene_text.contains("offset_top = 504.0") and scene_text.contains("offset_bottom = 688.0"), "Mission scene default event log is below mini cards")


func _test_mission_left_hud_regions_do_not_overlap() -> void:
	root.size = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("TARGET_VIEWPORT")
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(8)

	var layout: Dictionary = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_mission_hud_layout")
	var mini_rect: Rect2i = layout.get("fireteam_mini")
	var event_rect: Rect2i = layout.get("event_log")
	_assert(not _rects_intersect(mini_rect, event_rect), "Layout contract keeps event log outside fireteam mini region")
	_assert(event_rect.position.y >= mini_rect.end.y + 16, "Layout contract gives event log a readable gap below mini cards")
	_assert(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("is_rect_inside_viewport", event_rect), "Event log contract rect stays inside viewport")
	_assert(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("is_rect_on_base_grid", event_rect), "Event log contract rect stays on base grid")

	var mini_panel := scene.get_node_or_null("TacticalUI/FireteamMiniPanel") as Control
	var event_panel := scene.get_node_or_null("TacticalUI/TacticalEventLogPanel") as Control
	_assert(mini_panel != null and event_panel != null, "Mission scene exposes mini panel and event log panel")
	if mini_panel == null or event_panel == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var mini_global: Rect2 = mini_panel.get_global_rect()
	var event_global: Rect2 = event_panel.get_global_rect()
	_assert(_rect2_matches_rect2i(mini_global, mini_rect), "Runtime mini panel matches layout contract")
	_assert(_rect2_matches_rect2i(event_global, event_rect), "Runtime event log matches layout contract")
	_assert(not mini_global.intersects(event_global), "Runtime mini panel and event log no longer overlap")
	_assert(event_global.position.y > mini_global.end.y, "Runtime event log renders below mini cards")
	_assert(bool(mini_panel.get_meta("mission_fireteam_mini_backgroundless", false)), "Mini cards keep backgroundless style")
	_assert(bool(event_panel.get_meta("drop_light_fixed_fullhd_layout", false)), "Event log is managed by fixed HUD layout")

	scene.queue_free()
	await _wait_frames(2)


func _rects_intersect(a: Rect2i, b: Rect2i) -> bool:
	return a.position.x < b.end.x \
		and a.end.x > b.position.x \
		and a.position.y < b.end.y \
		and a.end.y > b.position.y


func _rect2_matches_rect2i(actual: Rect2, expected: Rect2i) -> bool:
	var expected_position := Vector2(float(expected.position.x), float(expected.position.y))
	var expected_size := Vector2(float(expected.size.x), float(expected.size.y))
	return actual.position.distance_to(expected_position) <= 1.0 and actual.size.distance_to(expected_size) <= 1.0


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
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
