extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/drop_light_layout_contract.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_724_station_route_recapture_visual_followup.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const TERRAIN_VIEW_PATH: String = "res://scripts/terrain/terrain_map_3d_view.gd"
const LAYOUT_CONTRACT_PATH: String = "res://scripts/meta/drop_light_layout_contract.gd"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_route_recapture_visual_followup.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_724 Station Route Recapture Visual Followup ===")
	_test_docs_and_sources()
	await _test_runtime_followup_snapshot()
	_test_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_724: FAILED")
		quit(1)
		return
	print("TASK_724: ALL PASSED")
	quit(0)


func _test_docs_and_sources() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var terrain_text: String = _read_text(TERRAIN_VIEW_PATH)
	var layout_text: String = _read_text(LAYOUT_CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_724 task file exists")
	_assert(task_text.contains("Station Route Recapture Visual Followup"), "Task documents recapture visual followup")
	_assert(contract_text.contains("Station Route Recapture Visual Followup"), "Interaction contract documents TASK_724")
	_assert(status_text.contains("TASK_724 - Station Route Recapture Visual Followup"), "Implementation status tracks TASK_724")
	_assert(roadmap_text.contains("TASK_724 - Station Route Recapture Visual Followup (implementiert)"), "Roadmap marks TASK_724 implemented")
	_assert(report_text.contains("TASK_724 - Station Route Recapture Visual Followup"), "Current report references TASK_724")
	_assert(report_text.contains('data-export-key="station_route_recapture_visual_followup.manifest_path"'), "Current report exports TASK_724 manifest path")
	_assert(controller_text.contains("get_station_route_recapture_visual_followup_snapshot"), "Mission controller exposes TASK_724 snapshot")
	_assert(layout_text.contains('"top_nav": Rect2i(768, 24, 384, 56)'), "Mission layout records narrower top nav")
	_assert(layout_text.contains('"fireteam_mini": Rect2i(24, 128, 240, 248)'), "Mission layout records lower fireteam mini panel")
	_assert(terrain_text.contains("mission_interaction_visual_state_label_height_step"), "Terrain render snapshot exports station label spacing")
	_assert(terrain_text.contains("route_callout_label_height_step"), "Terrain render snapshot exports route label spacing")


func _test_runtime_followup_snapshot() -> void:
	root.size = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("TARGET_VIEWPORT")
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(8)
	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null and controller.has_method("get_station_route_recapture_visual_followup_snapshot"), "Mission controller has TASK_724 snapshot API")
	if controller == null or not controller.has_method("get_station_route_recapture_visual_followup_snapshot"):
		scene.queue_free()
		await _wait_frames(2)
		return
	var snapshot: Dictionary = Dictionary(controller.call("get_station_route_recapture_visual_followup_snapshot"))
	_assert(_snapshot_is_read_only(snapshot), "TASK_724 snapshot is read-only")
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_route_recapture_visual_followup.v1", "TASK_724 schema is stable")
	_assert(String(snapshot.get("gate", "")) == "ready_for_recapture", "TASK_724 gate asks for recapture instead of acceptance")
	_assert(bool(snapshot.get("top_nav_tighter", false)), "Top nav is tighter than TASK_723 recapture")
	_assert(bool(snapshot.get("fireteam_mini_tighter", false)), "Fireteam mini panel is tighter than TASK_723 recapture")
	_assert(bool(snapshot.get("eventlog_tracks_mini", false)), "Event log follows the tighter fireteam mini panel")
	_assert(bool(snapshot.get("station_labels_more_spaced", false)), "Station labels expose larger spacing")
	_assert(bool(snapshot.get("route_labels_more_spaced", false)), "Route labels expose larger spacing")
	_assert(int(snapshot.get("top_nav_width_delta_vs_task722", 0)) < 0, "Top nav width delta is negative")
	_assert(int(snapshot.get("fireteam_mini_height_delta_vs_task722", 0)) < 0, "Fireteam mini height delta is negative")
	_assert(Array(snapshot.get("failed_checks", [])).is_empty(), "TASK_724 snapshot has no failed checks")

	var layout: Dictionary = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_mission_hud_layout")
	var top_nav_rect: Rect2i = layout.get("top_nav")
	var mini_rect: Rect2i = layout.get("fireteam_mini")
	var event_rect: Rect2i = layout.get("event_log")
	_assert(top_nav_rect.size == Vector2i(384, 56), "Top nav contract is narrower")
	_assert(mini_rect.size == Vector2i(240, 248), "Fireteam mini contract is lower")
	_assert(event_rect.position.y >= mini_rect.end.y + 16, "Event log remains below fireteam mini panel")
	_assert(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("is_rect_inside_viewport", top_nav_rect), "Top nav rect stays inside viewport")
	_assert(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("is_rect_inside_viewport", mini_rect), "Fireteam mini rect stays inside viewport")
	_assert(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("is_rect_on_base_grid", top_nav_rect), "Top nav rect stays on base grid")
	_assert(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("is_rect_on_base_grid", mini_rect), "Fireteam mini rect stays on base grid")

	scene.queue_free()
	await _wait_frames(2)


func _test_manifest_write() -> void:
	_ensure_output_dir()
	var manifest: Dictionary = {
		"schema": "sternenbuergerchen.station_route_recapture_visual_followup.v1",
		"task_id": "TASK_724",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"gate": "ready_for_recapture",
		"recommended_next_task": "TASK_725 - Station Route Host/Client Recapture Acceptance Review",
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
	}
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_724 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_724", "TASK_724 manifest records task id")
	_assert(String(parsed.get("gate", "")) == "ready_for_recapture", "TASK_724 manifest records recapture gate")
	_assert(_snapshot_is_read_only(parsed), "TASK_724 manifest remains read-only")


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true))


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
