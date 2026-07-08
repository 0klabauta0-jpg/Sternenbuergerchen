extends SceneTree

const Polish := preload("res://scripts/mission/release_first_exchange_fire_direction_impact_clarity_polish.gd")

const TASK_PATH := "res://docs/tasks/TASK_892_release_first_exchange_fire_direction_impact_clarity_polish.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_2026_07_09.html"
const SERVICE_PATH := "res://scripts/mission/release_first_exchange_fire_direction_impact_clarity_polish.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const TERRAIN_VIEW_PATH := "res://scripts/terrain/terrain_map_3d_view.gd"
const META_LAYER_SCENE_PATH := "res://scenes/meta/meta_layer_test.tscn"
const FIRST_GO_FIREFIGHT_ARG := "--release-singleplayer-first-go-firefight"
const SCHEMA := "sternenbuergerchen.release_first_exchange_fire_direction_impact_clarity_polish.v1"
const STYLE_ID := "task_892_release_first_exchange_fire_direction_impact_clarity_v1"
const SOURCE_STYLE_ID := "task_889_release_first_exchange_hud_density_fire_visual_polish_v1"
const NEXT_TASK := "TASK_893 - Release First Exchange Fire Direction Impact Real Window Recapture"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_892 Release First Exchange Fire Direction And Impact Clarity Polish ===")
	_test_docs_and_static_hooks()
	_test_helper_snapshot_passes()
	await _test_meta_layer_task_892_runtime_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_892_release_first_exchange_fire_direction_impact_clarity_polish: FAILED")
		quit(1)
		return
	print("TASK_892_release_first_exchange_fire_direction_impact_clarity_polish: ALL PASSED")
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
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_892 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_892 helper exists")
	_assert(task_text.contains("Release First Exchange Fire Direction And Impact Clarity Polish"), "Task names TASK_892")
	_assert(task_text.contains(NEXT_TASK), "Task names TASK_893 follow-up")
	_assert(status_text.contains("TASK_892 - Release First Exchange Fire Direction And Impact Clarity Polish"), "Implementation status tracks TASK_892")
	_assert(roadmap_text.contains("TASK_892 - Release First Exchange Fire Direction And Impact Clarity Polish (implementiert)"), "Roadmap marks TASK_892 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_893 follow-up")
	_assert(contract_text.contains("Release-First-Exchange-Fire-Direction-Impact-Clarity-Polish (TASK_892)"), "Contract documents TASK_892")
	_assert(report_text.contains("TASK_892") and report_text.contains("TASK_893"), "HTML report tracks TASK_892 and TASK_893")
	_assert(service_text.contains(SCHEMA), "Helper exposes TASK_892 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_892\""), "Helper writes TASK_892 id")
	_assert(service_text.contains("SOURCE_HUD_DENSITY_TASK_ID: String = \"TASK_889\""), "Helper links TASK_889")
	_assert(service_text.contains("\"creates_command\": false"), "Helper creates no commands")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Helper creates no fire events")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Helper creates no damage events")
	_assert(service_text.contains("\"creates_movement\": false"), "Helper creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Helper sets no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_EXCHANGE_FIRE_DIRECTION_IMPACT_CLARITY_POLISH_SCRIPT"), "Controller preloads TASK_892 helper")
	_assert(controller_text.contains("get_release_first_exchange_fire_direction_impact_clarity_polish_snapshot"), "Controller exposes TASK_892 snapshot")
	_assert(controller_text.contains("release_first_exchange_fire_direction_impact_clarity_polish"), "Controller sends TASK_892 payload")
	_assert(terrain_text.contains("RELEASE_FIRST_EXCHANGE_FIRE_DIRECTION_IMPACT_CLARITY_STYLE_ID"), "Terrain view declares TASK_892 style")
	_assert(terrain_text.contains("_is_release_first_exchange_fire_direction_impact_clarity_polish_active"), "Terrain view detects TASK_892 payload")
	_assert(terrain_text.contains("WeaponFireDirectionArrowLeft"), "Terrain view renders TASK_892 direction arrow")
	_assert(terrain_text.contains("WeaponFireImpactRelationshipAnchor"), "Terrain view renders TASK_892 impact relationship anchor")


func _test_helper_snapshot_passes() -> void:
	var snapshot: Dictionary = Polish.build_snapshot(_helper_source(), {})
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Helper snapshot schema matches TASK_892")
	_assert(String(snapshot.get("task_id", "")) == "TASK_892", "Helper snapshot task id is TASK_892")
	_assert(String(snapshot.get("style_id", "")) == STYLE_ID, "Helper snapshot style id is stable")
	_assert(String(snapshot.get("source_style_id", "")) == SOURCE_STYLE_ID, "Helper snapshot links TASK_889 style")
	_assert(String(snapshot.get("gate", "")) == "pass", "Helper snapshot passes")
	_assert(bool(snapshot.get("active", false)), "Helper snapshot active")
	_assert(float(snapshot.get("trace_width", 0.0)) > 0.07, "Trace width beats TASK_889")
	_assert(float(snapshot.get("impact_radius", 0.0)) > 0.36, "Impact radius beats TASK_889")
	_assert(float(snapshot.get("target_focus_radius", 0.0)) > 0.62, "Target focus beats TASK_889")
	_assert(bool(snapshot.get("direction_arrow_visible", false)), "Direction arrow visible")
	_assert(bool(snapshot.get("impact_relationship_anchor_visible", false)), "Impact relationship anchor visible")
	_assert(bool(snapshot.get("target_endcap_visible", false)), "Target endcap visible")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Helper recommends TASK_893")
	_assert(bool(snapshot.get("read_only", false)), "Helper snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Helper sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_command", true)), "Helper creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Helper creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Helper creates no damage events")
	_assert(not bool(snapshot.get("creates_movement", true)), "Helper creates no movement")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Helper sets no multiplayer truth")


func _test_meta_layer_task_892_runtime_snapshot() -> void:
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
	_assert(controller.has_method("get_release_first_exchange_fire_direction_impact_clarity_polish_snapshot"), "Controller exposes TASK_892 runtime snapshot")
	if not controller.has_method("get_release_first_exchange_fire_direction_impact_clarity_polish_snapshot"):
		scene.queue_free()
		await _wait_frames(1)
		return
	var snapshot: Dictionary = Dictionary(controller.call("get_release_first_exchange_fire_direction_impact_clarity_polish_snapshot"))
	if String(snapshot.get("gate", "")) != "pass":
		print("TASK_892_DIAGNOSTIC %s" % JSON.stringify({
			"failed_checks": snapshot.get("failed_checks", []),
			"trace_width": snapshot.get("trace_width", 0.0),
			"impact_radius": snapshot.get("impact_radius", 0.0),
			"target_focus_radius": snapshot.get("target_focus_radius", 0.0),
			"entries": snapshot.get("weapon_fire_vfx_entries", []),
		}))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Runtime snapshot schema is stable")
	_assert(String(snapshot.get("task_id", "")) == "TASK_892", "Runtime snapshot task id is TASK_892")
	_assert(String(snapshot.get("style_id", "")) == STYLE_ID, "Runtime snapshot style id is TASK_892")
	_assert(String(snapshot.get("gate", "")) == "pass", "TASK_892 runtime snapshot passes")
	_assert(bool(snapshot.get("active", false)), "TASK_892 runtime polish is active")
	_assert(float(snapshot.get("trace_width", 0.0)) > 0.07, "Runtime trace width beats TASK_889")
	_assert(float(snapshot.get("impact_radius", 0.0)) > 0.36, "Runtime impact radius beats TASK_889")
	_assert(float(snapshot.get("target_focus_radius", 0.0)) > 0.62, "Runtime target focus beats TASK_889")
	_assert(bool(snapshot.get("direction_arrow_visible", false)), "Runtime direction arrow visible")
	_assert(bool(snapshot.get("impact_relationship_anchor_visible", false)), "Runtime impact relationship anchor visible")
	_assert(bool(snapshot.get("target_endcap_visible", false)), "Runtime target endcap visible")
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
		"hud_density": {
			"task_id": "TASK_889",
			"gate": "pass",
			"active": true,
			"read_only": true,
		},
		"primary_render_snapshot": {
			"release_first_exchange_fire_direction_impact_clarity_polish_active": true,
			"release_first_exchange_fire_direction_impact_clarity_polish_style_id": STYLE_ID,
			"release_first_exchange_fire_direction_impact_trace_width": 0.092,
			"release_first_exchange_fire_direction_impact_radius": 0.46,
			"release_first_exchange_fire_direction_target_focus_radius": 0.78,
			"weapon_fire_vfx_visual_count": 1,
			"weapon_fire_vfx_entries": [
				{
					"trace_width": 0.092,
					"impact_radius": 0.46,
					"target_focus_radius": 0.78,
					"fire_direction_arrow_visible": true,
					"impact_relationship_anchor_visible": true,
					"target_endcap_visible": true,
					"fire_direction_arrow_world": 30.0,
					"fire_direction_arrow_width": 0.095,
					"fire_status_label_visible": true,
					"fire_status_label_font_size": 20,
				}
			],
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
