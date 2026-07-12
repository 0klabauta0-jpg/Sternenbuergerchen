extends SceneTree

const Polish := preload("res://scripts/mission/release_first_exchange_hud_density_and_fire_visual_polish.gd")

const TASK_PATH := "res://docs/tasks/TASK_889_release_first_exchange_hud_density_and_fire_visual_polish.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_2026_07_08.html"
const SERVICE_PATH := "res://scripts/mission/release_first_exchange_hud_density_and_fire_visual_polish.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const TERRAIN_VIEW_PATH := "res://scripts/terrain/terrain_map_3d_view.gd"
const EVENT_LOG_PANEL_PATH := "res://scripts/ui/tactical_event_log_panel.gd"
const META_LAYER_SCENE_PATH := "res://scenes/meta/meta_layer_test.tscn"
const FIRST_GO_FIREFIGHT_ARG := "--release-singleplayer-first-go-firefight"
const SCHEMA := "sternenbuergerchen.release_first_exchange_hud_density_fire_visual_polish.v1"
const STYLE_ID := "task_889_release_first_exchange_hud_density_fire_visual_polish_v1"
const NEXT_TASK := "TASK_890 - Release First Exchange HUD Density Real Window Recapture"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_889 Release First Exchange HUD Density And Fire Visual Polish ===")
	_test_docs_and_static_hooks()
	_test_helper_snapshot_passes()
	await _test_meta_layer_task_889_runtime_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_889_release_first_exchange_hud_density_and_fire_visual_polish: FAILED")
		quit(1)
		return
	print("TASK_889_release_first_exchange_hud_density_and_fire_visual_polish: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var terrain_text: String = _read_text(TERRAIN_VIEW_PATH)
	var panel_text: String = _read_text(EVENT_LOG_PANEL_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_889 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_889 helper exists")
	_assert(task_text.contains("Release First Exchange HUD Density And Fire Visual Polish"), "Task names TASK_889")
	_assert(task_text.contains(NEXT_TASK), "Task names TASK_890 follow-up")
	_assert(status_text.contains("TASK_889 - Release First Exchange HUD Density And Fire Visual Polish"), "Implementation status tracks TASK_889")
	_assert(roadmap_text.contains("TASK_889 - Release First Exchange HUD Density And Fire Visual Polish (implementiert)"), "Roadmap marks TASK_889 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_890 follow-up")
	_assert(contract_text.contains("Release-First-Exchange-HUD-Density-And-Fire-Visual-Polish (TASK_889)"), "Contract documents TASK_889")
	_assert(report_text.contains("TASK_889") and report_text.contains("TASK_890"), "HTML report tracks TASK_889 and TASK_890")
	_assert(service_text.contains(SCHEMA), "Helper exposes TASK_889 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_889\""), "Helper writes TASK_889 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_888\""), "Helper links TASK_888")
	_assert(service_text.contains("SOURCE_HUD_SYNC_TASK_ID: String = \"TASK_883\""), "Helper links TASK_883")
	_assert(service_text.contains("SOURCE_VISIBLE_STATUS_TASK_ID: String = \"TASK_876\""), "Helper links TASK_876")
	_assert(service_text.contains("SOURCE_FIRE_VISUAL_TASK_ID: String = \"TASK_880\""), "Helper links TASK_880")
	_assert(service_text.contains("\"creates_command\": false"), "Helper creates no commands")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Helper creates no fire events")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Helper creates no damage events")
	_assert(service_text.contains("\"creates_movement\": false"), "Helper creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Helper sets no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_EXCHANGE_HUD_DENSITY_FIRE_VISUAL_POLISH_SCRIPT"), "Controller preloads TASK_889 helper")
	_assert(controller_text.contains("get_release_first_exchange_hud_density_fire_visual_polish_snapshot"), "Controller exposes TASK_889 snapshot")
	_assert(controller_text.contains("release_first_exchange_hud_density_fire_visual_polish"), "Controller sends TASK_889 payload")
	_assert(panel_text.contains("apply_release_first_exchange_hud_density_fire_visual_polish"), "Event log panel exposes TASK_889 style hook")
	_assert(panel_text.contains("RELEASE_FIRST_EXCHANGE_EVENT_LOG_MAX_VISIBLE_EVENTS: int = 4"), "Event log uses the TASK 1159 readable density cap")
	_assert(terrain_text.contains("RELEASE_FIRST_EXCHANGE_HUD_DENSITY_FIRE_VISUAL_POLISH_STYLE_ID"), "Terrain view declares TASK_889 style")
	_assert(terrain_text.contains("_is_release_first_exchange_hud_density_fire_visual_polish_active"), "Terrain view detects TASK_889 payload")
	_assert(terrain_text.contains("RELEASE_FIRST_EXCHANGE_HUD_DENSITY_FIRE_VISUAL_TRACE_WIDTH: float = 0.07"), "Terrain view raises trace width")


func _test_helper_snapshot_passes() -> void:
	var snapshot: Dictionary = Polish.build_snapshot(_helper_source(), {})
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Helper snapshot schema matches TASK_889")
	_assert(String(snapshot.get("task_id", "")) == "TASK_889", "Helper snapshot task id is TASK_889")
	_assert(String(snapshot.get("style_id", "")) == STYLE_ID, "Helper snapshot style id is stable")
	_assert(bool(snapshot.get("active", false)), "Helper snapshot is active")
	_assert(String(snapshot.get("gate", "")) == "pass", "Helper snapshot passes")
	_assert(int(snapshot.get("selected_fireteam_line_count", 0)) <= 3, "#17 line budget passes")
	_assert(int(snapshot.get("mission_control_line_count", 0)) <= 4, "#18 line budget passes")
	_assert(float(snapshot.get("trace_width", 0.0)) > 0.052, "Trace width is stronger than TASK_880")
	_assert(float(snapshot.get("impact_radius", 0.0)) > 0.28, "Impact radius is stronger than TASK_880")
	_assert(float(snapshot.get("target_focus_radius", 0.0)) > 0.48, "Target focus radius is stronger than TASK_880")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Helper recommends TASK_890")
	_assert(bool(snapshot.get("read_only", false)), "Helper snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Helper sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_command", true)), "Helper creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Helper creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Helper creates no damage events")
	_assert(not bool(snapshot.get("creates_movement", true)), "Helper creates no movement")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Helper sets no multiplayer truth")


func _test_meta_layer_task_889_runtime_snapshot() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := _instantiate_scene(META_LAYER_SCENE_PATH)
	_assert(scene != null, "MetaLayer scene instantiates")
	if scene == null:
		return
	await _wait_frames(10)
	_assert(scene.has_method("_apply_release_first_go_firefight_deeplink"), "MetaLayer exposes first GO/firefight apply hook")
	if not scene.has_method("_apply_release_first_go_firefight_deeplink"):
		scene.queue_free()
		await _wait_frames(1)
		return
	scene.call("_apply_release_first_go_firefight_deeplink", PackedStringArray([FIRST_GO_FIREFIGHT_ARG]))
	await _wait_frames(190)
	var active_mission = scene.call("get_active_mission") if scene.has_method("get_active_mission") else null
	_assert(active_mission != null, "Deep-link keeps active mission alive")
	if active_mission == null:
		scene.queue_free()
		await _wait_frames(1)
		return
	var controller: Node = active_mission.get_node_or_null("TacticalController")
	_assert(controller != null, "Active mission exposes TacticalController")
	if controller == null:
		scene.queue_free()
		await _wait_frames(1)
		return
	_assert(controller.has_method("get_release_first_exchange_hud_density_fire_visual_polish_snapshot"), "Controller exposes TASK_889 runtime snapshot")
	if not controller.has_method("get_release_first_exchange_hud_density_fire_visual_polish_snapshot"):
		scene.queue_free()
		await _wait_frames(1)
		return
	var snapshot: Dictionary = Dictionary(controller.call("get_release_first_exchange_hud_density_fire_visual_polish_snapshot"))
	if String(snapshot.get("gate", "")) != "pass":
		print("TASK_889_DIAGNOSTIC %s" % JSON.stringify({
			"failed_checks": snapshot.get("failed_checks", []),
			"selected": snapshot.get("selected_fireteam_status_text", ""),
			"mission": snapshot.get("mission_control_status_text", ""),
			"event_log_panel": snapshot.get("event_log_panel", {}),
			"trace_width": snapshot.get("trace_width", 0.0),
			"impact_radius": snapshot.get("impact_radius", 0.0),
			"target_focus_radius": snapshot.get("target_focus_radius", 0.0),
		}))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Runtime snapshot schema is stable")
	_assert(String(snapshot.get("task_id", "")) == "TASK_889", "Runtime snapshot task id is TASK_889")
	_assert(String(snapshot.get("style_id", "")) == STYLE_ID, "Runtime snapshot style id is TASK_889")
	_assert(String(snapshot.get("gate", "")) == "pass", "TASK_889 runtime snapshot passes")
	_assert(bool(snapshot.get("active", false)), "TASK_889 runtime polish is active")
	_assert(String(snapshot.get("selected_fireteam_status_text", "")).begins_with("CONTACT FIRE"), "#17 starts CONTACT FIRE")
	_assert(String(snapshot.get("mission_control_status_text", "")).begins_with("CONTACT FIRE"), "#18 starts CONTACT FIRE")
	_assert(int(snapshot.get("selected_fireteam_line_count", 99)) <= 3, "#17 remains compact")
	_assert(int(snapshot.get("mission_control_line_count", 99)) <= 4, "#18 remains compact")
	var event_panel: Dictionary = Dictionary(snapshot.get("event_log_panel", {}))
	_assert(bool(event_panel.get("release_first_exchange_hud_density_fire_visual_polish_active", false)), "#19 applies TASK_889 panel style")
	_assert(int(event_panel.get("max_visible_events", 99)) <= 5, "#19 event cap is reduced")
	_assert(float(event_panel.get("custom_minimum_size_x", 0.0)) >= 360.0, "#19 minimum width grows")
	_assert(float(event_panel.get("custom_minimum_size_y", 0.0)) >= 220.0, "#19 minimum height grows")
	_assert(float(snapshot.get("trace_width", 0.0)) > 0.052, "Runtime trace width beats TASK_880")
	_assert(float(snapshot.get("impact_radius", 0.0)) > 0.28, "Runtime impact radius beats TASK_880")
	_assert(float(snapshot.get("target_focus_radius", 0.0)) > 0.48, "Runtime target focus radius beats TASK_880")
	_assert(bool(snapshot.get("read_only", false)), "Runtime snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Runtime snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_command", true)), "Runtime snapshot creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Runtime snapshot creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Runtime snapshot creates no damage events")
	_assert(not bool(snapshot.get("creates_movement", true)), "Runtime snapshot creates no movement")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Runtime snapshot sets no multiplayer truth")
	scene.queue_free()
	await _wait_frames(2)


func _helper_source() -> Dictionary:
	return {
		"active": true,
		"selected_fireteam_status_text": "CONTACT FIRE | FIRE ft1->enemy_a | HIT\nNEXT DEFEND | WHY FEUER",
		"mission_control_status_text": "CONTACT FIRE | FIRE ft1->enemy_a | HIT\nNEXT DEFEND | WHY FEUER",
		"hud_sync": {
			"active": true,
			"task_id": "TASK_883",
		},
		"event_log_panel": {
			"release_first_exchange_hud_density_fire_visual_polish_active": true,
			"max_visible_events": 5,
			"custom_minimum_size_x": 360.0,
			"custom_minimum_size_y": 220.0,
		},
		"primary_render_snapshot": {
			"release_first_exchange_hud_density_fire_visual_polish_active": true,
			"release_first_exchange_hud_density_fire_visual_trace_width": 0.07,
			"release_first_exchange_hud_density_fire_visual_impact_radius": 0.36,
			"release_first_exchange_hud_density_fire_visual_target_focus_radius": 0.62,
			"release_first_exchange_hud_density_fire_visual_status_label_font_size": 18,
		},
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _instantiate_scene(path: String) -> Node:
	var packed_scene := ResourceLoader.load(path) as PackedScene
	if packed_scene == null:
		return null
	var node := packed_scene.instantiate()
	root.add_child(node)
	return node


func _wait_frames(count: int) -> void:
	for _index in range(count):
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
