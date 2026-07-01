extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/drop_light_layout_contract.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_722_station_route_hud_visual_polish.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const TERRAIN_VIEW_PATH: String = "res://scripts/terrain/terrain_map_3d_view.gd"
const CARD_PATH: String = "res://scripts/meta/fob_fireteam_card.gd"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_route_hud_visual_polish.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_722 Station Route HUD Visual Polish ===")
	_test_docs_and_sources()
	await _test_runtime_hud_polish_snapshot()
	_test_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_722: FAILED")
		quit(1)
		return
	print("TASK_722: ALL PASSED")
	quit(0)


func _test_docs_and_sources() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var terrain_text: String = _read_text(TERRAIN_VIEW_PATH)
	var card_text: String = _read_text(CARD_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_722 task file exists")
	_assert(task_text.contains("Station Route HUD Visual Polish"), "Task names Station Route HUD Visual Polish")
	_assert(contract_text.contains("Station Route HUD Visual Polish"), "Interaction contract documents TASK_722")
	_assert(status_text.contains("TASK_722 - Station Route HUD Visual Polish"), "Implementation status tracks TASK_722")
	_assert(roadmap_text.contains("TASK_722 - Station Route HUD Visual Polish (implementiert)"), "Roadmap marks TASK_722 implemented")
	_assert(report_text.contains("TASK_722 - Station Route HUD Visual Polish"), "Current report references TASK_722")
	_assert(controller_text.contains("get_station_route_hud_visual_polish_snapshot"), "Mission controller exposes TASK_722 polish snapshot")
	_assert(terrain_text.contains("MISSION_INTERACTION_VISUAL_STATE_LABEL_BACKPLATE_STYLE_ID"), "Terrain view has station label backplate contract")
	_assert(terrain_text.contains("ROUTE_CALLOUT_LABEL_BACKPLATE_STYLE_ID"), "Terrain view has route callout backplate contract")
	_assert(card_text.contains("mission_mini_density"), "Fireteam card exposes compact mission mini density")


func _test_runtime_hud_polish_snapshot() -> void:
	root.size = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("TARGET_VIEWPORT")
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(8)
	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null and controller.has_method("get_station_route_hud_visual_polish_snapshot"), "Mission controller has TASK_722 snapshot API")
	if controller == null or not controller.has_method("get_station_route_hud_visual_polish_snapshot"):
		scene.queue_free()
		await _wait_frames(2)
		return
	var snapshot: Dictionary = Dictionary(controller.call("get_station_route_hud_visual_polish_snapshot"))
	_assert(_snapshot_is_read_only(snapshot), "TASK_722 snapshot is read-only")
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_route_hud_visual_polish.v1", "TASK_722 schema is stable")
	_assert(String(snapshot.get("gate", "")) == "ready_for_recapture", "TASK_722 gate asks for recapture instead of acceptance")
	_assert(bool(snapshot.get("fireteam_mini_map_safe_margin_enabled", false)), "Fireteam mini panel uses map-safe margin")
	_assert(bool(snapshot.get("fireteam_mini_scroll_preserved", false)), "Fireteam mini scroll remains available")
	_assert(bool(snapshot.get("station_label_readable", false)), "Station labels expose readable style")
	_assert(bool(snapshot.get("route_labels_uncrowded", false)), "Route labels expose uncrowded style")
	_assert(bool(snapshot.get("nav_placeholder_removed", false)), "Top nav placeholder is removed or hidden")
	_assert(Array(snapshot.get("failed_checks", [])).is_empty(), "TASK_722 snapshot has no failed checks")

	var layout: Dictionary = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_mission_hud_layout")
	var mini_rect: Rect2i = layout.get("fireteam_mini")
	var event_rect: Rect2i = layout.get("event_log")
	_assert(mini_rect.size.x <= 240 and mini_rect.size.y <= 288, "Fireteam mini contract is compact")
	_assert(event_rect.position.y >= mini_rect.end.y + 16, "Event log remains below compact Fireteam mini panel")
	_assert(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("is_rect_inside_viewport", mini_rect), "Fireteam mini rect stays inside viewport")
	_assert(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("is_rect_on_base_grid", mini_rect), "Fireteam mini rect stays on base grid")

	scene.queue_free()
	await _wait_frames(2)


func _test_manifest_write() -> void:
	_ensure_output_dir()
	var manifest: Dictionary = {
		"schema": "sternenbuergerchen.station_route_hud_visual_polish.v1",
		"task_id": "TASK_722",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"gate": "ready_for_recapture",
		"recommended_next_task": "TASK_723 - Station Route Host/Client Recapture Review",
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
	}
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_722 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_722", "TASK_722 manifest records task id")
	_assert(String(parsed.get("gate", "")) == "ready_for_recapture", "TASK_722 manifest records recapture gate")
	_assert(_snapshot_is_read_only(parsed), "TASK_722 manifest remains read-only")


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
